# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "rbconfig"
require "tmpdir"

REPO = Pathname.new(File.expand_path("..", __dir__))
RUBY = RbConfig.ruby

# miseのshimは仮HOMEで別の設定を探すため、HOMEを替える前に実行ファイルを解決する。
def resolve_command(name)
  path = ENV.fetch("PATH").split(File::PATH_SEPARATOR)
    .map { |directory| File.join(directory, name) }
    .find { |candidate| File.file?(candidate) && File.executable?(candidate) }
  return path unless path && File.basename(File.dirname(path)) == "shims"

  output, status = Open3.capture2("mise", "which", name)
  status.success? ? output.strip : nil
end

CHEZMOI = resolve_command("chezmoi")
CommandResult = Struct.new(:stdout, :stderr, :status) do
  def exit_code
    status.exitstatus || 128 + status.termsig
  end
end

class RepositoryTest < Minitest::Test
  def setup
    @root = Pathname.new(Dir.mktmpdir("chezmoi-test."))
    @home = @root / "home"
    @tools = @root / "bin"
    FileUtils.mkdir_p([@home, @tools])
    @env = {
      "HOME" => @home.to_s,
      "XDG_CONFIG_HOME" => (@home / ".config").to_s,
      "XDG_DATA_HOME" => (@root / "data").to_s,
      "XDG_STATE_HOME" => (@root / "state").to_s,
      "XDG_CACHE_HOME" => (@root / "cache").to_s,
      "PATH" => "#{@tools}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH')}"
    }
  end

  def teardown
    FileUtils.remove_entry(@root) if @root&.exist?
  end

  def write(path, content, mode: nil)
    path = Pathname.new(path)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
    path.chmod(mode) if mode
    path
  end

  def tool(name, body, directory: @tools)
    write(directory / name, "#!#{RUBY}\n#{body}", mode: 0o755)
  end

  def run_command(*arguments, env: @env, input: "", directory: REPO)
    stdout, stderr, status = Open3.capture3(env, *arguments, stdin_data: input, chdir: directory)
    CommandResult.new(stdout, stderr, status)
  end

  def checked_command(*arguments, **options)
    result = run_command(*arguments, **options)
    assert_equal 0, result.exit_code, result.stdout + result.stderr
    result
  end

  def script_command(name, *arguments)
    # AOT検証も通常と同じフィクスチャで行う。通常実行は常にCRuby。
    if ENV["SCRIPT_BIN_DIR"]
      [File.join(ENV.fetch("SCRIPT_BIN_DIR"), name), *arguments]
    else
      [RUBY, (REPO / "scripts" / "#{name}.rb").to_s, *arguments]
    end
  end

  def run_script(name, *arguments, **options)
    run_command(*script_command(name, *arguments), **options)
  end
end
