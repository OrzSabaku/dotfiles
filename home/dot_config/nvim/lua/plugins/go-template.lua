return {
  {
    "dpezto/chezmoi-template.nvim",
    lazy = false,
    -- 判定はoptions.luaに集約し、整形機能だけをConformから使う。
    -- プラグイン既定の保存時applyやテンプレート実行は有効にしない。
    init = function()
      vim.g.loaded_chezmoi_template = 1
    end,
    config = function()
      local ct = require("chezmoi-template")
      ct.config.inject.enabled = false
      ct.config.format.indent_directives = false
      require("chezmoi-template.inject").register_directive()
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters.chezmoi = require("chezmoi-template.format").formatter
      opts.formatters_by_ft.template = { "chezmoi" }
      -- LSPの付かない整形用バッファでも、既存のCLIを使用できるようにする。
      opts.formatters_by_ft.toml = opts.formatters_by_ft.toml or { "taplo" }
      opts.formatters_by_ft.json = opts.formatters_by_ft.json or {}
      table.insert(opts.formatters_by_ft.json, "biome")
      opts.formatters_by_ft.json.stop_after_first = true
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "gotmpl" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          filetypes = { "go", "gomod", "gowork", "gotmpl", "template" },
          -- chezmoiの拡張子なしの断片も、Goソースではなくテンプレートとして通知する。
          get_language_id = function(_, filetype)
            return filetype == "template" and "gotmpl" or filetype
          end,
          settings = { gopls = { templateExtensions = { "tmpl", "gotmpl" } } },
        },
      },
    },
  },
}
