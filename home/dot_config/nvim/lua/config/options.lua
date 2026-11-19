-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = true
vim.g.autoformat = true

-- Rubyの補完・型推論はSolargraphを使用。整形はRuby Extra既定のRuboCopに任せる。
vim.g.lazyvim_ruby_lsp = "solargraph"

-- chezmoiのmodify-templateは配置先と同じ拡張子でもJSON/TOMLではない。
-- 拡張子より先に判定し、設定ファイル用のLSPや整形が誤って動くのを防ぐ。
vim.filetype.add({
  pattern = {
    [".*/modify_[^/]+"] = function(_, bufnr)
      local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
      if first_line:find("chezmoi:modify-template", 1, true) then
        return "template"
      end
    end,
  },
})
