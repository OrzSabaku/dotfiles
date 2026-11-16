# frozen_string_literal: true

require_relative "test_scripts"

# CIでのみ明示的に実行する。通常のテストにビルドや実行モード切り替えは加えない。
class NativeScriptsTest < ScriptsTest
  def setup
    super
    %w[setup-zsh update-zsh-plugins nvim-experiment].each do |name|
      assert (REPO / "dist/bin" / name).executable?, "Missing native binary: #{name}"
    end
  end

  def run_script(name, *arguments, **options)
    run_command((REPO / "dist/bin" / name).to_s, *arguments, **options)
  end

  def test_setup_stops_before_configuration_when_packages_fail_or_os_is_unsupported
    marker = @root / "chsh-called"
    tool("omarchy", "exit 23\n")
    tool("chsh", "File.write(#{marker.to_s.inspect}, 'called')\n")
    result = run_script("setup-zsh")
    omarchy = File.readlines("/etc/os-release", chomp: true).include?("ID=omarchy")
    assert_equal omarchy && !Process.euid.zero? ? 23 : 1, result.exit_code, result.stderr
    refute marker.exist?
    assert_empty @home.children
  end

  def test_launcher_uses_runtime_checkout_after_binary_is_moved
    checkout = @root / "checkout with spaces"
    tool("chezmoi", "puts #{checkout.to_s.inspect}\n")
    tool("nvim", 'puts ENV.fetch("XDG_CONFIG_HOME")')
    # 実行ファイルもビルド時のディレクトリから移して検証する。
    binary = @root / "downloaded-launcher"
    FileUtils.cp(REPO / "dist/bin/nvim-experiment", binary)
    result = checked_command(binary.to_s, directory: @root)
    assert_equal (checkout / "experiments").to_s, result.stdout.strip
  end
end
