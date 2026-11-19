# frozen_string_literal: true

require_relative "test_helper"

class ChezmoiTest < RepositoryTest
  def setup
    super
    skip "chezmoi is required" unless CHEZMOI
    @config = @root / "chezmoi.toml"
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
    { "omarchy" => 77, "fedora" => 43 }.each do |profile, count|
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
      refute (@home / ".local").exist?
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
      reset_home
    end
  end

  def test_unselected_apps_are_not_created
    initialize_profile("omarchy", apps: false)
    chezmoi("apply")
    %w[.zshrc .zshenv .config/sheldon .config/dotfiles/zsh.zsh .config/nvim .config/ghostty .config/fcitx5].each do |name|
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

  def test_invalid_profile_is_rejected
    initialize_profile("omarchy")
    @config.write(@config.read.sub('profile = "omarchy"', 'profile = "other"'))
    refute_equal 0, chezmoi("apply", check: false).exit_code
    assert_empty @home.children
  end

  def test_private_runtime_files_are_git_ignored
    names = %w[home/dot_config/mozc/user_dictionary.db home/dot_config/fcitx5/config.bak
      home/dot_config/fcitx5/conf/cached_layouts home/dot_config/git/private_config.private
      home/dot_ssh/private_id_ed25519]
    result = checked_command("git", "check-ignore", "--no-index", "--stdin", input: names.join("\n") + "\n")
    assert_equal names.sort, result.stdout.lines(chomp: true).sort
    (REPO / "home").glob("**/*", File::FNM_DOTMATCH).select(&:file?).each do |path|
      result = run_command("git", "check-ignore", "--no-index", path.to_s)
      assert_equal 1, result.exit_code, path.to_s
    end
  end
end
