# frozen_string_literal: true

require_relative "test_helper"

class ZshSetupTest < RepositoryTest
  def setup
    super
    skip "Setup intentionally refuses root" if Process.euid.zero?
    skip "Setup is Omarchy-only" unless File.readlines("/etc/os-release", chomp: true).include?("ID=omarchy")
  end

  def test_package_failure_does_not_install_configs_or_change_login_shell
    marker = @root / "chsh-called"
    tool("omarchy", "exit 23\n")
    tool("chsh", "File.write(#{marker.to_s.inspect}, 'called')\n")
    result = run_script("setup-zsh")
    assert_equal 23, result.exit_code, result.stderr
    refute marker.exist?
    assert_empty @home.children
  end

  def test_shell_change_waits_for_configuration_plugins_and_startup
    # この検証はクラスの依存確認だけを差し替える。AOTの公開コマンドは別テストで実行する。
    %w[none init syntax apply plugins startup].each do |failure|
      Dir.mktmpdir("setup-case.", @root) do |directory|
        case_home = Pathname.new(directory)
        fixture_repo = case_home / "fixture-repo"
        scripts = fixture_repo / "scripts"
        FileUtils.mkdir_p(scripts)
        %w[id getent omarchy chezmoi zsh chsh update-zsh-plugins].each do |name|
          tool(name, setup_stub, directory: name == "update-zsh-plugins" ? scripts : @tools)
        end
        current_shell = write(case_home / "current-shell", "/bin/bash")
        env = @env.merge("HOME" => case_home.to_s, "FAIL_STAGE" => failure)
        result = run_command(RUBY, "-e", setup_runner, (REPO / "scripts/setup-zsh").to_s,
          fixture_repo.to_s, env: env)
        log = case_home / "calls.jsonl"
        assert log.exist?, result.stderr
        calls = log.readlines.map { |line| JSON.parse(line) }
        if failure == "none"
          assert_successful_setup(result, calls, case_home)
        else
          assert_equal 23, result.exit_code, "#{failure}: #{result.stderr}"
          assert_empty calls.select { |call| call.first == "chsh" }
          assert_equal "/bin/bash", current_shell.read
          refute (case_home / ".local/state/dotfiles").exist?
        end
      end
    end
  end

  private

  def assert_successful_setup(result, calls, home)
    assert_equal 0, result.exit_code, result.stderr
    apply_at = calls.index { |call| call.first == "chezmoi" && call[3] == "apply" }
    plugins_at = calls.index { |call| call.first == "update-zsh-plugins" }
    startup_at = calls.index { |call| call.take(2) == ["zsh", "-lic"] }
    chsh_at = calls.index { |call| call.first == "chsh" }
    assert_operator apply_at, :<, plugins_at
    assert_operator plugins_at, :<, startup_at
    assert_operator startup_at, :<, chsh_at
    audit = (home / ".local/state/dotfiles").children.fetch(0)
    assert_equal "/bin/bash\n", audit.read
    assert_equal 0o600, audit.stat.mode & 0o777
  end

  def setup_runner
    <<~'CODE'
      load ARGV.shift
      ZshSetup.send(:remove_const, :REPO)
      ZshSetup.const_set(:REPO, ARGV.shift)
      class ZshSetup
        def check_dependencies
          "/usr/bin/zsh"
        end
      end
      ScriptCommands.main { ZshSetup.new.run }
    CODE
  end

  def setup_stub
    <<~'STUB'
      require "json"
      home = ENV.fetch("HOME")
      name = File.basename($PROGRAM_NAME)
      File.open(File.join(home, "calls.jsonl"), "a") { |log| log.puts(JSON.generate([name, *ARGV])) }
      failure = ENV.fetch("FAIL_STAGE")
      case name
      when "id"
        puts "test-user"
      when "getent"
        puts "test-user:x:1000:1000::/home/test:#{File.read(File.join(home, 'current-shell'))}"
      when "chezmoi"
        action = ARGV.fetch(2)
        exit 23 if action == failure
        if action == "execute-template"
          puts ARGV.last.include?(".profile") ? "omarchy" : "true"
        elsif action == "cat"
          puts "export EDITOR=nvim"
        end
      when "zsh"
        exit 23 if (ARGV.first == "-n" && failure == "syntax") || (ARGV.first == "-lic" && failure == "startup")
      when "update-zsh-plugins"
        exit 23 if failure == "plugins"
      when "chsh"
        File.write(File.join(home, "current-shell"), ARGV.last)
      end
    STUB
  end
end
