-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = true
vim.g.autoformat = true

-- Rubyの補完・型推論はSolargraphを使用。整形はRuby Extra既定のRuboCopに任せる。
vim.g.lazyvim_ruby_lsp = "solargraph"
