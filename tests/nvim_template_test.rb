# frozen_string_literal: true

require_relative "test_helper"

# インストール済みのプラグインを使う任意の結合テスト．テストから取得・更新しない．
# 実行: bundle exec ruby -Itests tests/nvim_template_test.rb
class NvimTemplateTest < RepositoryTest
  def test_manual_formatting_avoids_chezmoi_and_buffer_name_collisions
    nvim = resolve_command("nvim")
    data = ENV.fetch("XDG_DATA_HOME", File.join(Dir.home, ".local/share"))
    plugins = Pathname.new(data) / "nvim/lazy"
    taplo = resolve_command("taplo") || (Pathname.new(data) / "nvim/mason/bin/taplo").to_s
    skip "Neovim, chezmoi-template.nvim, conform.nvim and Taplo are required" unless
      nvim && (plugins / "chezmoi-template.nvim").directory? &&
        (plugins / "conform.nvim").directory? && File.executable?(taplo)

    marker = @root / "chezmoi-called"
    tool("chezmoi", "File.write(#{marker.to_s.inspect}, ARGV.inspect); exit 99")
    @env.merge!("NVIM_TEST_ROOT" => @root.to_s, "NVIM_TEST_PLUGINS" => plugins.to_s,
      "NVIM_TEST_TAPLO" => taplo, "NVIM_TEST_REPO" => REPO.to_s)
    checked_command(nvim, "--clean", "--headless", "-i", "NONE", "-l",
      (REPO / "tests/nvim/template_format.lua").to_s)

    refute_predicate marker, :exist?, marker.exist? ? marker.read : ""
  end
end
