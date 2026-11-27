# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "pty"
require "rbconfig"
require "tmpdir"

REPO = Pathname.new(File.expand_path("..", __dir__))
RUBY = RbConfig.ruby

# miseのshimは仮HOMEで別の設定を探すため，HOMEを替える前に実行ファイルを解決する．
def resolve_command(name)
  path = ENV.fetch("PATH").split(File::PATH_SEPARATOR)
    .map { |directory| File.join(directory, name) }
    .find { |candidate| File.file?(candidate) && File.executable?(candidate) }
  return path unless path && File.basename(File.dirname(path)) == "shims"

  output, status = Open3.capture2("mise", "which", name)
  status.success? ? output.strip : nil
end

CHEZMOI = resolve_command("chezmoi")
SHELDON = resolve_command("sheldon")
MISE = resolve_command("mise")

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

  # 成功を前提とするコマンドだけ，診断とassertを共通化する．
  # 失敗を検証するテストではOpen3.capture3の戻り値を直接使う．
  def checked_command(*arguments, env: @env, input: "", directory: REPO)
    stdout, stderr, status = Open3.capture3(env, *arguments, stdin_data: input, chdir: directory)

    assert_predicate status, :success?, stdout + stderr
    stdout
  end

  # 制御端末が必要なコマンドだけPTYで実行し，子プロセスの失敗もassertへ伝える．
  def checked_pty_command(*arguments, env: @env, input: "", directory: REPO)
    output = +""
    status = nil
    PTY.spawn(env, *arguments, chdir: directory) do |reader, writer, pid|
      writer.write(input)
      loop { output << reader.readpartial(4096) }
    rescue EOFError, Errno::EIO
      # PTYの終端は，LinuxではEOFの代わりにEIOになる．
    ensure
      reader.close
      writer.close
      _, status = Process.wait2(pid)
    end

    assert_predicate status, :success?, output
    output
  end

  def run_script(name, *arguments, directory: REPO)
    Open3.capture3(@env, RUBY, (REPO / "scripts" / "#{name}.rb").to_s, *arguments, chdir: directory)
  end
end
