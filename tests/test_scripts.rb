# frozen_string_literal: true

require_relative "test_helper"

class ScriptsTest < RepositoryTest
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
    result = run_script("update-zsh-plugins")
    assert_equal 0, result.exit_code, result.stderr
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
    result = run_script("update-zsh-plugins")
    assert_equal 29, result.exit_code, result.stderr
    assert_equal "# previous plugins\n", @cache.read
    assert_empty (@root / "data/dotfiles/sheldon").children
    refute (@home / ".local/state/dotfiles/backups").exist?
  end

  def test_neovim_launcher_passes_environment_arguments_and_exit_code
    tool("nvim", <<~'STUB')
      require "json"
      puts JSON.generate(config: ENV.fetch("XDG_CONFIG_HOME"), app: ENV.fetch("NVIM_APPNAME"), args: ARGV)
      exit 17
    STUB
    arguments = ["file with spaces.txt", "$(touch should-not-exist)", "--", "-literal"]
    # __dir__は呼び出し元の作業ディレクトリに依存しない必要がある。
    result = run_script("nvim-experiment", *arguments, directory: @root)
    assert_equal 17, result.exit_code, result.stderr
    data = JSON.parse(result.stdout)
    assert_equal arguments, data.fetch("args")
    assert_equal (REPO / "experiments").to_s, data.fetch("config")
    assert_equal "nvim-experiment", data.fetch("app")
    refute (@root / "should-not-exist").exist?
  end

  def test_command_helper_preserves_literal_arguments_and_failure_status
    tool("record", <<~'STUB')
      require "json"
      puts JSON.generate(ARGV)
      exit 31
    STUB
    code = <<~'CODE'
      require ARGV.shift
      ScriptCommands.main { ScriptCommands.run!("record", *ARGV) }
    CODE
    arguments = ["space in argument", "$(touch should-not-exist)", "; exit 0"]
    result = run_command(RUBY, "-e", code, (REPO / "scripts/lib/commands.rb").to_s, *arguments)
    assert_equal 31, result.exit_code, result.stderr
    assert_equal arguments, JSON.parse(result.stdout)
  end
end
