# frozen_string_literal: true

require_relative "test_helper"

class ChezmoiTest < RepositoryTest
  def setup
    super
    skip "chezmoi is required" unless CHEZMOI
    @config = @root / "chezmoi.toml"
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
    { "omarchy" => 111, "fedora" => 59 }.each do |profile, count|
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
       ".config/ghostty/config" => "config/ghostty/config",
       ".config/mise/config.toml" => "config/mise/config.toml" }.each do |target, fragment|
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

  def test_unselected_apps_are_not_created
    initialize_profile("omarchy", apps: false)
    chezmoi("apply")
    %w[.zshrc .zshenv .config/sheldon .config/dotfiles/zsh.zsh .config/nvim .config/ghostty .config/fcitx5
      .config/autostart/org.fcitx.Fcitx5.desktop .local/share/dbus-1/services/org.fcitx.Fcitx5.service
      .config/xdg-terminals.list .codex .config/amp .config/opencode .pi].each do |name|
      refute (@home / name).exist?, name
    end
    assert (@home / ".config/dotfiles/env.sh").file?
    assert (@home / ".config/git/config").file?
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
