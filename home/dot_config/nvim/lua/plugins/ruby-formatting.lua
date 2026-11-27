return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      -- RuboCopの起動時間を含め，Rubyの整形だけは最大10秒待つ．
      -- プロジェクト固有の.rubocop.ymlがない場合は，~/.config/rubocop/config.yml（グローバル設定）が既定で読み込まれる．
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.ruby = opts.formatters_by_ft.ruby or {}
      opts.formatters_by_ft.ruby.timeout_ms = 10000
    end,
  },
}
