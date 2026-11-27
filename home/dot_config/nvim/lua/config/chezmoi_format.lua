-- テンプレートの保護・復元はプラグインに任せ，CLIによる判定と原本名の衝突だけを避ける．
return {
  format = function(self, ctx, lines, callback)
    local resolve = require("chezmoi-template.resolve")
    local source = vim.api.nvim_buf_get_name(ctx.buf)
    local target = resolve.resolve_path(source)
    -- .chezmoitemplates内の断片も，配置属性を除いた名前から判定する．
    local ft = vim.filetype.match({ filename = vim.fs.basename(target) }) or vim.filetype.match({ filename = target })
    if not ft or ft == "template" or ft == "gotmpl" then
      return callback(nil, lines)
    end

    local proxy = vim.api.nvim_create_buf(false, true)
    local function finish(err, formatted)
      if vim.api.nvim_buf_is_valid(proxy) then
        vim.api.nvim_buf_delete(proxy, { force = true })
      end
      callback(err, formatted)
    end

    local ok, err = pcall(function()
      -- 設定ファイルの探索場所を維持しつつ，上流が.tmplを除いた後の名前も一意にする．
      local unique = vim.fn.tempname():gsub("[/\\:]", "_")
      local name =
        vim.fs.joinpath(vim.fs.dirname(source), ".conform-" .. unique .. "-" .. vim.fs.basename(target) .. ".tmpl")
      vim.api.nvim_buf_call(proxy, function()
        vim.cmd("noautocmd keepalt file " .. vim.fn.fnameescape(name))
      end)
      -- 未設定だと上流がchezmoi managedを呼ぶため，必ず名前だけで決めた形式を渡す．
      vim.b[proxy].chezmoi_target_ft = ft
      local context = vim.tbl_extend("force", ctx, { buf = proxy })
      require("chezmoi-template.format").formatter.format(self, context, lines, finish)
    end)
    if not ok then
      finish(err)
    end
  end,
}
