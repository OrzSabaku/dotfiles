# frozen_string_literal: true

require_relative "test_helper"

class ScriptsTest < RepositoryTest
  def setup
    super
    tool("chezmoi", "puts #{REPO.to_s.inspect}\n")
  end

  def plugin_fixture(validation_status: 0)
    tool("sheldon", <<~'STUB')
      location = ARGV.fetch(ARGV.index("--data-dir") + 1)
      File.write(File.join(location, "downloaded"), "plugin repositories")
      puts "# validated plugins from #{location}"
    STUB
    tool("zsh", <<~STUB)
      if ARGV.include?("-i")
        abort "ZDOTDIR was not isolated" unless ENV.fetch("ZDOTDIR") == ARGV.last
        exit #{validation_status}
      end
    STUB
    @cache = write(@root / "cache/dotfiles/sheldon.zsh", "# previous plugins\n", mode: 0o600)
  end

  def test_successful_plugin_update_keeps_generation_and_private_backup
    plugin_fixture
    _, stderr, status = run_script("update-zsh-plugins")
    assert_equal 0, status.exitstatus, stderr
    generations = (@root / "data/dotfiles/sheldon").children
    assert_equal 1, generations.length
    assert_includes @cache.read, generations.first.to_s
    assert (generations.first / "downloaded").exist?
    backups = (@home / ".local/state/dotfiles/backups").children
    assert_equal 1, backups.length
    assert_equal 0o700, backups.first.stat.mode & 0o777
    assert_equal "# previous plugins\n", (backups.first / "sheldon.zsh").read
    assert_equal 0o600, @cache.stat.mode & 0o777
    assert_empty @cache.dirname.glob(".sheldon.*")
  end

  def test_plugin_validation_failure_removes_only_failed_generation
    plugin_fixture(validation_status: 29)
    _, stderr, status = run_script("update-zsh-plugins")
    assert_equal 29, status.exitstatus, stderr
    assert_equal "# previous plugins\n", @cache.read
    assert_empty (@root / "data/dotfiles/sheldon").children
    refute (@home / ".local/state/dotfiles/backups").exist?
  end

  def test_plugin_commands_preserve_literal_paths
    directory = @root / 'data with spaces $(touch should-not-exist); literal'
    @env["XDG_DATA_HOME"] = directory.to_s
    plugin_fixture
    _, stderr, status = run_script("update-zsh-plugins", directory: @root)
    assert_equal 0, status.exitstatus, stderr
    generations = (directory / "dotfiles/sheldon").children
    assert_equal 1, generations.length
    assert_includes @cache.read, generations.first.to_s
    refute (@root / "should-not-exist").exist?
  end
end
