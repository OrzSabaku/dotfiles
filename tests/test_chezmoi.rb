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

  def chezmoi(*arguments, check: true)
    command = [CHEZMOI, "--source", REPO.to_s, "--destination", @home.to_s,
      "--config", @config.to_s, "--persistent-state", (@root / "state.boltdb").to_s,
      "--cache", (@root / "cache").to_s, "--no-tty", *arguments]
    check ? checked_command(*command) : run_command(*command)
  end

  def initialize_profile(profile, apps: true)
    chezmoi("init", "--promptDefaults", "--promptChoice", "Environment=#{profile}")
    refute_match(/^sourceDir\s*=/, @config.read)
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
    { "omarchy" => 116, "fedora" => 65 }.each do |profile, count|
      initialize_profile(profile)
      chezmoi("apply", "--dry-run")
      assert_empty @home.children
      chezmoi("apply")
      managed = chezmoi("managed", "--include", "files").stdout.lines(chomp: true)
      assert_equal count, managed.length
      managed.each do |name|
        assert (@home / name).file?, name
        refute (@home / name).symlink?, name
      end
      assert_empty chezmoi("diff").stdout
      chezmoi("apply")
      chezmoi("verify")
      refute (@home / ".local/bin").exist?
      refute (@home / ".config/nvim-experiment").exist?
      reset_home
    end
  end

  def test_os_variants_and_optional_neovim_integrations
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply")
      { ".zshrc" => "zshrc", ".bashrc" => "bashrc",
       ".config/ghostty/config" => "config/ghostty/config" }.each do |target, fragment|
        expected = REPO / "home/.chezmoitemplates" / profile / fragment
        assert_equal expected.binread, (@home / target).binread
      end
      %w[.config/nvim/lua/omarchy .config/hypr .zshenv].each do |name|
        assert_equal profile == "omarchy", (@home / name).exist?, name
      end
      if profile == "omarchy"
        assert_equal 0o600, (@home / ".config/omarchy/shell.json").stat.mode & 0o777
        assert_empty (@home / ".config/lazygit/config.yml").binread
        assert_equal 0o755, (@home / ".config/omarchy/hooks/post-update.d/setup-agent.hook").stat.mode & 0o777
      end
      assert_equal profile == "omarchy", (@home / ".config/systemd/user/voxtype.service").exist?
      assert_equal profile == "omarchy", (@home / ".config/hyprland-mimeapps.list").exist?
      refute (@home / ".config/systemd/user/graphical-session.target.wants").exist?
      assert_equal 0o700, (@home / ".config/gh").stat.mode & 0o777
      assert_includes (@home / ".config/mimeapps.list").read, "mailto=dotfiles-thunderbird.desktop"
      assert_includes (@home / ".local/share/applications/dotfiles-thunderbird.desktop").read, "Exec=thunderbird %u"
      reset_home
    end
  end

  def parse_toml(content)
    JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromToml | toJson }}", input: content).stdout)
  end

  def test_mise_common_tools_and_settings_on_both_profiles
    common = parse_toml((REPO / "home/.chezmoitemplates/common/config/mise/config.toml").read)
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      content = chezmoi("cat", (@home / ".config/mise/config.toml").to_s).stdout
      config = parse_toml(content)
      expected = common.fetch("tools").merge(common.fetch("runtimes"))
      expected = expected.reject { |name, _| %w[bat eza fd fzf ripgrep starship zoxide neovim].include?(name) } if profile == "omarchy"
      assert_equal expected, config.fetch("tools")
      if profile == "omarchy"
        packages = %w[bat eza fd fzf ripgrep starship zoxide nvim].to_h { |name| ["pacman:#{name}", "latest"] }
        assert_equal packages, config.dig("bootstrap", "packages")
        refute config.dig("bootstrap", "packages").key?("pacman:ruby")
      else
        refute config.key?("bootstrap")
      end
      assert_equal common.fetch("settings"), config.fetch("settings")
      assert_equal({ "version" => "latest", "rename_exe" => "yt-dlp" }, config.dig("tools", "yt-dlp"))
      assert_equal "latest", config.dig("tools", "github:anomalyco/opencode")
      assert_equal "latest", config.dig("tools", "ruby")
      assert_equal profile == "fedora", config.fetch("tools").key?("neovim")
      reset_home
    end
  end

  def test_mise_keeps_tools_missing_from_omarchy_defaults
    tool("cat", 'puts %w[bat eza fzf ripgrep starship zoxide]')
    initialize_profile("omarchy")
    content = chezmoi("cat", (@home / ".config/mise/config.toml").to_s).stdout
    tools = parse_toml(content).fetch("tools")
    assert_equal "latest", tools.fetch("fd")
    refute tools.key?("bat")
    packages = parse_toml(content).dig("bootstrap", "packages")
    assert_equal "latest", packages.fetch("pacman:bat")
    refute packages.key?("pacman:fd")
  end

  def test_unselected_apps_are_not_created
    initialize_profile("omarchy", apps: false)
    chezmoi("apply")
    %w[.zshrc .zshenv .config/sheldon .config/dotfiles/zsh.zsh .config/nvim .config/ghostty .config/fcitx5
      .config/autostart/org.fcitx.Fcitx5.desktop .local/share/dbus-1/services/org.fcitx.Fcitx5.service
      .config/xdg-terminals.list .config/mise/conf.d/nvim-experiment.toml
      .codex .config/amp .config/opencode .pi].each do |name|
      refute (@home / name).exist?, name
    end
    assert (@home / ".config/dotfiles/env.sh").file?
    assert (@home / ".config/git/config").file?
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
    result = run_command(MISE, "run", "--skip-tools", "nvim-experiment", "--", *arguments, directory: @root)
    assert_equal 17, result.exit_code, result.stderr
    data = JSON.parse(result.stdout)
    assert_equal arguments, data.fetch("args")
    assert_equal (REPO / "experiments").to_s, data.fetch("config")
    assert_equal "nvim-experiment", data.fetch("app")
    assert_equal @root.to_s, data.fetch("directory")
    refute (@root / "should-not-exist").exist?
    normal = run_command("nvim", directory: @root)
    normal_data = JSON.parse(normal.stdout)
    assert_equal (@home / ".config").to_s, normal_data.fetch("config")
    refute_equal "nvim-experiment", normal_data.fetch("app")
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

  def test_existing_links_become_files_without_changing_old_sources
    initialize_profile("omarchy")
    data = (REPO / "home/dot_config/starship.toml").binread
    source = write(@root / "old-starship.toml", data)
    target = @home / ".config/starship.toml"
    target.dirname.mkpath
    target.make_symlink(source)
    chezmoi("apply")
    refute target.symlink?
    assert_equal data, target.binread
    assert_equal data, source.binread
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
    write(@home / ".XCompose", "# local macros\n<Multi_key> <a> <b> : \"private-text\"\n")
    chezmoi("apply")
    config = JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromToml | toJson }}", input: codex.read).stdout)
    assert_equal "gpt-6.1-sol", config.fetch("model")
    assert_equal "trusted", config.dig("projects", "/private/work", "trust_level")
    assert_equal "local-secret", config.dig("mcp_servers", "generated", "env", "TOKEN")
    assert_equal "local-hash", config.dig("hooks", "state", "local", "trusted_hash")
    assert_equal true, config.dig("plugins", "local", "enabled")
    assert_equal (@home / ".atuin/bin/atuin").to_s, config.dig("mcp_servers", "atuin", "command")
    assert_equal "local-secret", JSON.parse((@home / ".config/amp/settings.json").read).fetch("apiKey")
    assert_equal ["./generated-plugin"], JSON.parse((@home / ".config/opencode/cli.json").read).fetch("plugins")
    assert_equal({ "x" => 123 }, JSON.parse((@home / ".config/discord/settings.json").read).fetch("WINDOW_BOUNDS"))
    assert_includes (@home / ".XCompose").read, "private-text"
    assert_includes (@home / ".XCompose").read, '/usr/share/omarchy/default/xcompose'
    first_content = codex.binread
    chezmoi("apply")
    assert_equal first_content, codex.binread
    assert_equal 0o600, codex.stat.mode & 0o777
    assert_empty chezmoi("diff").stdout
  end

  def test_opencode_updates_jsonc_without_losing_comments
    initialize_profile("omarchy")
    server = write(@home / ".config/opencode/opencode.json", <<~JSONC)
      {
        // server preference
        "model": "local/model",
        "mcp": { "atuin": { "command": ["old", /* keep command note */ "mcp"], }, },
      }
    JSONC
    chezmoi("apply")
    assert_includes server.read, "// server preference"
    assert_includes server.read, "/* keep command note */"
    data = JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromJsonc | toJson }}", input: server.read).stdout)
    assert_equal "local/model", data.fetch("model")
    assert_equal "system", data.fetch("theme")
    assert_equal false, data.fetch("autoupdate")
    assert_equal [(@home / ".atuin/bin/atuin").to_s, "mcp"], data.dig("mcp", "atuin", "command")
    first_server = server.binread
    chezmoi("apply")
    assert_equal first_server, server.binread
    assert_empty chezmoi("diff").stdout
  end

  def mise_dotfiles(*arguments, check: true)
    skip "mise is required" unless MISE
    # 実機のシステム設定・ネットワーク・ツール導入から切り離して検証する。
    env = @env.merge("MISE_SYSTEM_CONFIG_FILE" => (@root / "absent.toml").to_s,
      "MISE_SYSTEM_CONFIG_DIR" => (@root / "absent").to_s,
      "MISE_OFFLINE" => "1", "MISE_AUTO_INSTALL" => "0")
    command = [MISE, "dotfiles", *arguments]
    check ? checked_command(*command, env: env, directory: @root) : run_command(*command, env: env, directory: @root)
  end

  def test_mise_merges_opencode_cli_without_changing_comments_or_unmanaged_settings
    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      content = <<~JSONC
        {
          // "plugins": ["disabled-plugin"],
          "plugins": ["./generated-plugin",],
          "theme": { /* theme note */ "name": "dark", "mode": "light", },
          "credential": "local-secret",
        }
      JSONC
      cli = write(@home / ".config/opencode/cli.json", content, mode: 0o600)
      chezmoi("apply")
      assert_equal content, cli.read, "chezmoi must leave the mise-managed target alone"
      refute_includes chezmoi("managed", "--include", "files").stdout.lines(chomp: true), ".config/opencode/cli.json"
      mise_dotfiles("apply", "--dry-run")
      assert_equal content, cli.read
      mise_dotfiles("apply")
      expected = content.sub('"name": "dark"', '"name": "system"')
      assert_equal expected, cli.read
      assert_equal 0o600, cli.stat.mode & 0o777
      mise_dotfiles("apply")
      assert_equal expected, cli.read
      refute_includes mise_dotfiles("diff").stdout, "edit differs:"
      reset_home
    end
  end

  def test_mise_creates_private_opencode_cli_and_adds_missing_nested_theme
    initialize_profile("omarchy")
    chezmoi("apply")
    cli = @home / ".config/opencode/cli.json"
    refute cli.exist?
    mise_dotfiles("apply")
    assert_equal({ "theme" => { "name" => "system" } }, JSON.parse(cli.read))
    assert_equal 0o600, cli.stat.mode & 0o777
    cli.write("{\"plugins\": [\"local\"] // keep plugin comment\n}\n")
    mise_dotfiles("apply")
    assert_includes cli.read, '// keep plugin comment'
    data = JSON.parse(checked_command(CHEZMOI, "execute-template", "--with-stdin",
      "{{ .chezmoi.stdin | fromJsonc | toJson }}", input: cli.read).stdout)
    assert_equal ["local"], data.fetch("plugins")
    assert_equal "system", data.dig("theme", "name")
  end

  def test_mise_refuses_invalid_opencode_cli_without_changing_it
    initialize_profile("omarchy")
    chezmoi("apply")
    cli = @home / ".config/opencode/cli.json"
    ['{"theme":', '{"theme": invalid}', '{"theme": {"name": "dark"}} trailing'].each do |content|
      write(cli, content, mode: 0o600)
      refute_equal 0, mise_dotfiles("apply", check: false).exit_code
      assert_equal content, cli.read
      assert_equal 0o600, cli.stat.mode & 0o777
    end
  end

  def test_mise_stops_managing_opencode_cli_when_ai_is_unselected
    initialize_profile("omarchy")
    chezmoi("apply")
    mise_dotfiles("apply")
    cli = @home / ".config/opencode/cli.json"
    content = '{"theme":{"name":"local"},"plugins":["local"]}'
    cli.write(content)
    @config.write(@config.read.sub("ai = true", "ai = false"))
    chezmoi("apply")
    mise_dotfiles("apply")
    assert_equal content, cli.read
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
        assert_includes imported.read, "color-scheme='prefer-dark'"
        refute_includes imported.read, "preferred-monitor"
        refute_includes imported.read, "mru-sources"
        imported.unlink
        chezmoi("apply")
        refute imported.exist?, "unchanged preferences should not be loaded again"
      end
      reset_home
    end
  end

  def test_fedora_package_template_previews_and_checks_keys_before_changes
    initialize_profile("fedora")
    template = (REPO / "home/.chezmoitemplates/fedora/setup-packages.rb.tmpl").read
    rendered = chezmoi("execute-template", template).stdout
    # The test must not depend on signing keys installed on the CI host.
    rendered = rendered.gsub(%r{file://[^"\s]+}, "file:///missing-dotfiles-test-key")
    script = write(@root / "setup-packages.rb", rendered)
    tool("rpm", 'puts "44"')
    tool("dnf", 'puts "repo id  repo name"')
    tool("sudo", 'File.write(File.join(ENV.fetch("HOME"), "sudo-called"), ARGV.inspect)')

    preview = run_command(RUBY, script.to_s)
    assert_equal 0, preview.exit_code, preview.stderr
    assert_includes preview.stdout, "rpmfusion-free-release-44.noarch.rpm"
    assert_includes preview.stdout, "dnf copr enable scottames/ghostty"
    assert_includes preview.stdout, "Preview only"
    refute (@home / "sudo-called").exist?

    result = run_command(RUBY, script.to_s, "--apply")
    refute_equal 0, result.exit_code
    assert_includes result.stderr, "signing keys are incomplete"
    refute (@home / "sudo-called").exist?
  end

  def test_neovim_detects_modify_templates_before_json_and_toml
    nvim = resolve_command("nvim")
    skip "Neovim is required" unless nvim

    %w[omarchy fedora].each do |profile|
      initialize_profile(profile)
      chezmoi("apply")
      plain = write(@root / "modify_plain.toml", "enabled = true\n")
      cases = [
        [REPO / "home/dot_codex/modify_private_config.toml", "template"],
        [REPO / "home/dot_config/private_amp/modify_private_settings.json", "template"],
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
    refute_equal 0, chezmoi("apply", check: false).exit_code
    assert_empty @home.children
  end

  def test_private_runtime_files_are_git_ignored
    names = %w[home/dot_config/mozc/user_dictionary.db home/dot_config/fcitx5/config.bak
      home/dot_config/fcitx5/conf/cached_layouts home/dot_config/git/private_config.private
      home/dot_ssh/private_id_ed25519 home/dot_codex/private_auth.json
      home/dot_config/private_amp/private_secrets.json home/dot_config/private_gh/private_hosts.yml
      home/dot_config/opencode/private_auth.json home/dot_pi/agent/private_auth.json]
    result = checked_command("git", "check-ignore", "--no-index", "--stdin", input: names.join("\n") + "\n")
    assert_equal names.sort, result.stdout.lines(chomp: true).sort
    (REPO / "home").glob("**/*", File::FNM_DOTMATCH).select(&:file?).each do |path|
      result = run_command("git", "check-ignore", "--no-index", path.to_s)
      assert_equal 1, result.exit_code, path.to_s
    end
  end
end
