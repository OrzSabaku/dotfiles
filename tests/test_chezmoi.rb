# frozen_string_literal: true

require_relative "test_helper"

class ChezmoiTest < RepositoryTest
  def setup
    super
    skip "chezmoi is required" unless CHEZMOI
    @config = @root / "chezmoi.toml"
    # Omarchyの外部一覧は固定データで検証し、ホストOSには依存しない。
    tool("cat", 'puts %w[bat eza fd fzf ripgrep starship zoxide ruby nvim]')
    tool("expac", 'puts "neovim nvim=0.12.6 vim-plugin-runtime"')
    tool("dconf", 'File.write(File.join(ENV.fetch("HOME"), "gnome-import"), STDIN.read)')
  end

  def chezmoi(*arguments, check: true, source: REPO)
    command = [CHEZMOI, "--source", source.to_s, "--destination", @home.to_s,
      "--config", @config.to_s, "--persistent-state", (@root / "state.boltdb").to_s,
      "--cache", (@root / "cache").to_s, "--no-tty", *arguments]
    check ? checked_command(*command) : Open3.capture3(@env, *command, chdir: REPO)
  end

  def initialize_profile(profile, apps: true)
    chezmoi("init", "--promptDefaults", "--promptChoice", "Environment=#{profile}")
    @config.write(@config.read.gsub("= true", "= false")) unless apps
  end

  def reset_home
    # OS切り替えではなく、それぞれ新規のホームへの導入を検証する。
    FileUtils.remove_entry(@home)
    @home.mkdir
    @config.unlink
    (@root / "state.boltdb").unlink
  end

  def test_both_profiles_apply_idempotently_without_installing_tools
    marker = @root / "unexpected-command"
    %w[mise sudo chsh omarchy].each do |name|
      tool(name, "File.write(#{marker.to_s.inspect}, [$PROGRAM_NAME, *ARGV].inspect); exit 99")
    end
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply", "--dry-run")

      assert_empty @home.children
      chezmoi("apply")

      assert_empty chezmoi("diff")
      chezmoi("apply")
      chezmoi("verify")

      refute_predicate marker, :exist?, marker.exist? ? marker.read : ""
      refute_predicate (@home / ".config/nvim-experiment"), :exist?
      reset_home
    end
  end

  def test_desktop_integration_is_omarchy_only_and_sensitive_files_are_private
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply")

      %w[.config/nvim/lua/omarchy .config/hypr .zshenv].each do |name|
        assert_equal profile == "omarchy", (@home / name).exist?, name
      end
      if profile == "omarchy"
        assert_equal 0o600, (@home / ".config/omarchy/shell.json").stat.mode & 0o777
        assert_equal 0o755, (@home / ".config/omarchy/hooks/post-update.d/setup-agent.hook").stat.mode & 0o777
      end

      assert_equal profile == "omarchy", (@home / ".config/systemd/user/voxtype.service").exist?
      assert_equal profile == "omarchy", (@home / ".config/hyprland-mimeapps.list").exist?
      assert_equal 0o700, (@home / ".config/gh").stat.mode & 0o777
      reset_home
    end
  end

  def parse_toml(content)
    JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromToml | toJson }}", input: content))
  end

  def test_mise_routes_only_standard_cli_tools_to_os_packages
    # 現在のツール一覧とは独立した入力で、変換規則だけを検証する。
    source = @root / "mise-source"
    write(source / ".chezmoitemplates/common/config/mise/config.toml", <<~TOML)
      [tools]
      standard = "1.2"
      optional = { version = "3.4", rename_exe = "custom" }
      editor = "5.6"
      [runtimes]
      runtime = "7.8"
      [settings]
      experimental = true
    TOML
    tool("cat", 'puts "standard\nvirtual-editor # default editor\nruntime\n"')
    tool("expac", 'puts "editor virtual-editor=5.6"')
    template = (REPO / "home/dot_config/mise/config.toml.tmpl").read
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      config = parse_toml(chezmoi("execute-template", template, source: source))
      if profile == "omarchy"
        assert_equal({ "optional" => { "version" => "3.4", "rename_exe" => "custom" },
          "runtime" => "7.8" }, config.fetch("tools"))
        assert_equal({ "pacman:standard" => "latest", "pacman:virtual-editor" => "latest" },
          config.dig("bootstrap", "packages"))
        # 標準一覧から外れたCLIは、ハードコードした除外一覧に残らない。
        tool("cat", 'puts "runtime"')
        changed = parse_toml(chezmoi("execute-template", template, source: source))

        assert_equal "1.2", changed.dig("tools", "standard")
        assert_equal "5.6", changed.dig("tools", "editor")
        refute changed.key?("bootstrap")
      else
        assert_equal({ "standard" => "1.2", "optional" => { "version" => "3.4", "rename_exe" => "custom" },
          "editor" => "5.6", "runtime" => "7.8" }, config.fetch("tools"))
        refute config.key?("bootstrap")
      end

      assert_equal({ "experimental" => true }, config.fetch("settings"))
      reset_home
    end
  end

  def test_unselected_apps_are_not_created
    initialize_profile("omarchy", apps: false)
    local = write(@home / ".config/opencode/cli.json", "local app data\n", mode: 0o600)
    chezmoi("apply")

    assert_equal "local app data\n", local.read
    assert_equal 0o600, local.stat.mode & 0o777
    %w[.zshrc .zshenv .config/sheldon .config/dotfiles/zsh.zsh .config/nvim .config/ghostty .config/fcitx5
      .config/autostart/org.fcitx.Fcitx5.desktop .local/share/dbus-1/services/org.fcitx.Fcitx5.service
      .config/xdg-terminals.list .config/mise/conf.d/nvim-experiment.toml
      .config/dotfiles/opencode .config/mise/conf.d/opencode.toml
      .codex .config/amp .pi].each do |name|
      refute_predicate (@home / name), :exist?, name
    end
    assert_predicate (@home / ".config/dotfiles/env.sh"), :file?
    assert_predicate (@home / ".config/git/config"), :file?
  end

  def test_app_selection_does_not_disable_other_apps
    initialize_profile("omarchy")
    original = @config.read
    targets = { "zsh" => ".zshrc", "nvim" => ".config/nvim/init.lua",
      "ghostty" => ".config/ghostty/config", "fcitx5" => ".config/fcitx5/config",
      "ai" => ".codex/config.toml" }
    targets.each_key do |disabled|
      @config.write(original.sub("#{disabled} = true", "#{disabled} = false"))
      managed = chezmoi("managed", "--include", "files").lines(chomp: true)

      targets.each do |app, target|
        assert_equal app != disabled, managed.include?(target), "#{disabled} disabled: #{target}"
      end
    end
  end

  def test_neovim_task_preserves_environment_arguments_directory_and_exit_code
    skip "mise is required" unless MISE
    initialize_profile("omarchy")
    # タスクだけを配置し、テスト中に[tools]の導入を発生させない。
    (@home / ".config/mise/conf.d").mkpath
    chezmoi("apply", (@home / ".config/mise/conf.d/nvim-experiment.toml").to_s)
    tool("nvim", <<~'STUB')
      require "json"
      puts JSON.generate(config: ENV.fetch("XDG_CONFIG_HOME"), app: ENV.fetch("NVIM_APPNAME", "nvim"),
        args: ARGV, directory: Dir.pwd)
      exit 17
    STUB
    @env["MISE_AUTO_INSTALL"] = "0"
    @env["MISE_OFFLINE"] = "1"
    arguments = ["file with spaces.txt", "$(touch should-not-exist)", "--help", "--", "-literal"]
    stdout, stderr, status = Open3.capture3(@env, MISE, "run", "--skip-tools", "nvim-experiment", "--",
      *arguments, chdir: @root)

    assert_equal 17, status.exitstatus, stderr
    data = JSON.parse(stdout)

    assert_equal arguments, data.fetch("args")
    assert_equal (REPO / "experiments").to_s, data.fetch("config")
    assert_equal "nvim-experiment", data.fetch("app")
    assert_equal @root.to_s, data.fetch("directory")
    refute_predicate (@root / "should-not-exist"), :exist?
  end

  def test_private_and_unmanaged_app_data_survive
    initialize_profile("omarchy")
    names = %w[.config/git/config.private .config/mozc/user_dictionary.db
      .config/fcitx5/conf/cached_layouts .config/fcitx5/config.bak
      .local/share/fcitx5/clipboard/data .config/omarchy/plugins/custom/data]
    names.each { |name| write(@home / name, "local data\n") }
    chezmoi("apply")

    names.each { |name| assert_equal "local data\n", (@home / name).binread }
    %w[.config/fcitx5/config .config/fcitx5/profile .config/fcitx5/conf/xcb.conf].each do |name|
      assert_equal 0o600, (@home / name).stat.mode & 0o777
    end
  end

  def test_partial_preferences_preserve_credentials_trust_and_generated_integrations
    initialize_profile("omarchy")
    codex = @home / ".codex/config.toml"
    write(codex, <<~TOML)
      model = "local-model"
      [projects."/private/work"]
      trust_level = "trusted"
      [mcp_servers.generated.env]
      TOKEN = "local-secret"
      [hooks.state.local]
      trusted_hash = "local-hash"
      [plugins.local]
      enabled = true
    TOML
    write(@home / ".config/amp/settings.json", JSON.generate("apiKey" => "local-secret"))
    write(@home / ".config/opencode/cli.json", JSON.generate("plugins" => ["./generated-plugin"]))
    write(@home / ".config/discord/settings.json", JSON.generate("WINDOW_BOUNDS" => { "x" => 123 }))
    chezmoi("apply")
    config = JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromToml | toJson }}", input: codex.read))

    assert_equal "trusted", config.dig("projects", "/private/work", "trust_level")
    assert_equal "local-secret", config.dig("mcp_servers", "generated", "env", "TOKEN")
    assert_equal "local-hash", config.dig("hooks", "state", "local", "trusted_hash")
    assert_equal({ "enabled" => true }, config.dig("plugins", "local"))
    assert_equal (@home / ".atuin/bin/atuin").to_s, config.dig("mcp_servers", "atuin", "command")
    assert_equal "local-secret", JSON.parse((@home / ".config/amp/settings.json").read).fetch("apiKey")
    assert_equal ["./generated-plugin"], JSON.parse((@home / ".config/opencode/cli.json").read).fetch("plugins")
    assert_equal({ "x" => 123 }, JSON.parse((@home / ".config/discord/settings.json").read).fetch("WINDOW_BOUNDS"))
    first_content = codex.binread
    chezmoi("apply")

    assert_equal first_content, codex.binread
    assert_equal 0o600, codex.stat.mode & 0o777
    assert_empty chezmoi("diff")
  end

  def test_opencode_overlays_preserve_local_files_and_resolve_from_mise
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      originals = {
        "opencode.json" => "{\n// local model\n\"model\": \"local/model\",\n}\n",
        "tui.json" => '{"theme":"local-theme","keybinds":{"leader":"ctrl+x"}}',
        "cli.json" => '{"plugins":["./generated-plugin"]}',
        "auth.json" => '{"token":"private-token"}',
        "opencode.jsonc" => '{invalid local JSONC'
      }
      originals.each { |name, content| write(@home / ".config/opencode" / name, content, mode: 0o600) }
      chezmoi("apply")
      chezmoi("apply")

      originals.each do |name, content|
        file = @home / ".config/opencode" / name

        assert_equal content, file.read
        assert_equal 0o600, file.stat.mode & 0o777
      end
      env = parse_toml((@home / ".config/mise/conf.d/opencode.toml").read).fetch("env")
      %w[OPENCODE_CONFIG OPENCODE_TUI_CONFIG].each do |key|
        file = Pathname.new(env.fetch(key))

        assert file.to_s.start_with?((@home / ".config/dotfiles/opencode/").to_s)
        assert_kind_of Hash, JSON.parse(file.read)
      end
      assert_empty chezmoi("diff")
      reset_home
    end
  end

  def test_xcompose_requires_an_active_include_and_preserves_local_macros
    initialize_profile("omarchy")
    target = @home / ".XCompose"
    directive = 'include "/usr/share/omarchy/default/xcompose"'
    macro = '<Multi_key> <a> <b> : "private-text"'
    write(target, "# #{directive}\n#{macro}\n")
    chezmoi("apply", target.to_s)

    assert_equal "#{directive}\n# #{directive}\n#{macro}\n", target.read
    active = "\tinclude  \"/usr/share/omarchy/default/xcompose\" # active\n#{macro}\n"
    target.write(active)
    chezmoi("apply", target.to_s)

    assert_equal active, target.read
    chezmoi("apply", target.to_s)

    assert_equal active, target.read
  end

  def test_gnome_preferences_only_run_on_fedora_and_when_changed
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply")
      imported = @home / "gnome-import"

      assert_equal profile == "fedora", imported.exist?
      if profile == "fedora"
        refute_includes imported.read, "preferred-monitor"
        refute_includes imported.read, "mru-sources"
        imported.unlink
        chezmoi("apply")

        refute_predicate imported, :exist?, "unchanged preferences should not be loaded again"
      end
      reset_home
    end
  end

  def test_fedora_package_template_previews_and_checks_keys_before_changes
    initialize_profile("fedora")
    template = (REPO / "home/.chezmoitemplates/fedora/setup-packages.rb.tmpl").read
    rendered = chezmoi("execute-template", template)
    # The test must not depend on signing keys installed on the CI host.
    rendered = rendered.gsub(%r{file://[^"\s]+}, "file:///missing-dotfiles-test-key")
    script = write(@root / "setup-packages.rb", rendered)
    tool("rpm", 'puts "44"')
    tool("dnf", 'puts "repo id  repo name"')
    tool("sudo", 'File.write(File.join(ENV.fetch("HOME"), "sudo-called"), ARGV.inspect)')

    preview = checked_command(RUBY, script.to_s)

    assert_includes preview, "rpmfusion-free-release-44.noarch.rpm"
    refute_predicate (@home / "sudo-called"), :exist?

    _, stderr, status = Open3.capture3(@env, RUBY, script.to_s, "--apply")

    refute_predicate status, :success?
    assert_includes stderr, "signing keys are incomplete"
    refute_predicate (@home / "sudo-called"), :exist?
  end

  def test_neovim_detects_chezmoi_sources_before_target_filetypes
    nvim = resolve_command("nvim")
    skip "Neovim is required" unless nvim

    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply")
      plain = write(@root / "modify_plain.toml", "enabled = true\n")
      external = write(@root / ".chezmoiexternal.toml", "{{ if true }}\n{{ end }}\n")
      externals = write(@root / ".chezmoiexternals/tools.yaml", "{{ if true }}\n{{ end }}\n")
      remove = write(@root / ".chezmoiremove", "{{ if true }}\n{{ end }}\n")
      symlink = write(@root / "symlink_settings.json", "/tmp/settings.json\n")
      symlink_template = write(@root / "symlink_settings.json.tmpl", "{{ .chezmoi.homeDir }}/settings.json\n")
      cases = [
        [REPO / "home/dot_codex/modify_private_config.toml", "template"],
        [REPO / "home/dot_config/private_amp/modify_private_settings.json", "template"],
        [REPO / "home/dot_config/discord/modify_settings.json", "template"],
        [REPO / "home/dot_config/dotfiles/opencode/opencode.json.tmpl", "template"],
        [REPO / "home/.chezmoiignore", "template"],
        [REPO / "home/.chezmoitemplates/common/config/mise/config.toml", "template"],
        [external, "template"],
        [externals, "template"],
        [remove, "template"],
        [symlink, "text"],
        [symlink_template, "template"],
        [@home / ".codex/config.toml", "toml"],
        [@home / ".config/amp/settings.json", "json"],
        [plain, "toml"]
      ].map { |path, type| "{ #{path.to_s.to_json}, #{type.to_json} }" }.join(",\n")
      script = write(@root / "filetypes.lua", <<~LUA)
        vim.opt.rtp:prepend(#{(@home / ".config/nvim").to_s.to_json})
        dofile(#{(@home / ".config/nvim/lua/config/options.lua").to_s.to_json})
        local events = {}
        vim.api.nvim_create_autocmd("FileType", {
          callback = function(event) table.insert(events, event.match) end,
        })
        for _, case in ipairs({ #{cases} }) do
          events = {}
          vim.cmd("edit " .. vim.fn.fnameescape(case[1]))
          assert(vim.bo.filetype == case[2], vim.inspect({ case, vim.bo.filetype }))
          assert(vim.deep_equal(events, { case[2] }), vim.inspect(events))
        end
        vim.cmd("qa!")
      LUA
      checked_command(nvim, "--clean", "--headless", "-i", "NONE", "-l", script.to_s)
      reset_home
    end
  end

  def test_invalid_profile_is_rejected
    initialize_profile("omarchy")
    @config.write(@config.read.sub('profile = "omarchy"', 'profile = "other"'))
    _, stderr, status = chezmoi("apply", check: false)

    refute_predicate status, :success?, stderr
    assert_empty @home.children
  end
end
