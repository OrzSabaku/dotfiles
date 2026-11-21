# frozen_string_literal: true

require_relative "test_scripts"

# CIでのみ明示的に実行する。通常のテストにビルドや実行モード切り替えは加えない。
class NativeScriptsTest < ScriptsTest
  def setup
    super
    %w[setup-zsh update-zsh-plugins].each do |name|
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
end
