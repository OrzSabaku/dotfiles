return {
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
