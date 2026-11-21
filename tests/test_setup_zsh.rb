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
    _, stderr, status = run_script("setup-zsh")
    assert_equal 23, status.exitstatus, stderr
    refute marker.exist?
    assert_empty @home.children
  end

  def test_shell_change_waits_for_configuration_plugins_and_startup
    # 実際の導入を避け、処理順だけをダミーコマンドで検証する。
    %w[none init syntax apply plugins startup].each do |failure|
      Dir.mktmpdir("setup-case.", @root) do |directory|
        case_home = Pathname.new(directory)
        fixture_repo = case_home / "fixture-repo"
        scripts = fixture_repo / "scripts"
        FileUtils.mkdir_p(scripts)
        %w[id getent omarchy chezmoi zsh chsh update-zsh-plugins.rb].each do |name|
          tool(name, setup_stub, directory: name == "update-zsh-plugins.rb" ? scripts : @tools)
        end
        current_shell = write(case_home / "current-shell", "/bin/bash")
        env = @env.merge("HOME" => case_home.to_s, "FAIL_STAGE" => failure, "TEST_REPO" => fixture_repo.to_s)
        _, stderr, status = Open3.capture3(env, RUBY, "-e", setup_runner, (REPO / "scripts/setup-zsh.rb").to_s)
        log = case_home / "calls.jsonl"
        assert log.exist?, stderr
        calls = log.readlines.map { |line| JSON.parse(line) }
        if failure == "none"
          assert_successful_setup(status, stderr, calls, case_home)
        else
          assert_equal 23, status.exitstatus, "#{failure}: #{stderr}"
          assert_empty calls.select { |call| call.first == "chsh" }
          assert_equal "/bin/bash", current_shell.read
          refute (case_home / ".local/state/dotfiles").exist?
        end
      end
    end
  end

  private

  def assert_successful_setup(status, stderr, calls, home)
    assert_equal 0, status.exitstatus, stderr
    apply_at = calls.index { |call| call.first == "chezmoi" && call[3] == "apply" }
    plugins_at = calls.index { |call| call.first == "update-zsh-plugins.rb" }
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
      class ZshSetup
        def check_dependencies
          "/usr/bin/zsh"
        end
      end
      ZshSetup.new.run
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
        if ARGV == ["execute-template", "{{ .chezmoi.workingTree }}"]
          puts ENV.fetch("TEST_REPO")
          exit
        end
        action = ARGV.fetch(2)
        exit 23 if action == failure
        if action == "execute-template"
          puts ARGV.last.include?(".profile") ? "omarchy" : "true"
        elsif action == "cat"
          puts "export EDITOR=nvim"
        end
      when "zsh"
        STDIN.read if ARGV.first == "-n"
        exit 23 if (ARGV.first == "-n" && failure == "syntax") || (ARGV.first == "-lic" && failure == "startup")
      when "update-zsh-plugins.rb"
        exit 23 if failure == "plugins"
      when "chsh"
        File.write(File.join(home, "current-shell"), ARGV.last)
      end
    STUB
  end
end
