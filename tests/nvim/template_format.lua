local root = vim.env.NVIM_TEST_ROOT
vim.opt.rtp:prepend(vim.env.NVIM_TEST_REPO .. "/home/dot_config/nvim")
vim.opt.rtp:prepend(vim.env.NVIM_TEST_PLUGINS .. "/chezmoi-template.nvim")
vim.opt.rtp:prepend(vim.env.NVIM_TEST_PLUGINS .. "/conform.nvim")
local spec = dofile(vim.env.NVIM_TEST_REPO .. "/home/dot_config/nvim/lua/plugins/go-template.lua")
spec[1].init()
spec[1].config()
local opts = { formatters = { taplo = { command = vim.env.NVIM_TEST_TAPLO } }, formatters_by_ft = {} }
spec[2].opts(nil, opts)
local conform = require("conform")
conform.setup(opts)

local function buffer(name, lines)
  vim.fn.mkdir(vim.fs.dirname(name), "p")
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, name)
  vim.bo.filetype = "template"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  return vim.api.nvim_get_current_buf()
end

local function format(buf)
  local done, failure = false, nil
  conform.format({ bufnr = buf, async = true, timeout_ms = 5000 }, function(err)
    failure, done = err, true
  end)
  assert(
    vim.wait(10000, function()
      return done
    end),
    "formatter callback timed out"
  )
  return failure
end

local input = { "{{ if true }}", "[section]", "answer=42", 'value={{ "hi" | quote }}', "{{ end }}" }
for _, name in ipairs({
  root .. "/dot_settings.toml.tmpl",
  root .. "/.chezmoitemplates/common/config/mise/config.toml",
  root .. "/modify_settings.toml",
}) do
  -- .tmplを除いた名前のバッファが開かれていても整形できること．
  local target = name:gsub("%.tmpl$", "")
  local other = target ~= name and buffer(target, { "local data" }) or nil
  local source = buffer(name, input)
  local count = #vim.api.nvim_list_bufs()
  local failure = format(source)
  assert(not failure, vim.inspect(failure))
  local output = vim.api.nvim_buf_get_lines(source, 0, -1, false)
  assert(not vim.deep_equal(input, output), "formatter did not run: " .. name)
  local text = table.concat(output, "\n")
  assert(text:match("answer%s*=%s*(%d+)") == "42", text)
  assert(text:find('{{ "hi" | quote }}', 1, true), "template action lost")
  assert(text:find("{{ if true }}", 1, true) and text:find("{{ end }}", 1, true), "control flow lost")
  assert(vim.api.nvim_buf_get_name(source) == name, "source buffer was renamed")
  assert(#vim.api.nvim_list_bufs() == count, "scratch buffer leaked")
  if other then
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(other, 0, -1, false), { "local data" }))
  end
  print("formatted: " .. name)
end

local invalid = { "[invalid", 'value={{ "hi" | quote }}' }
local broken = buffer(root .. "/broken.toml", invalid)
local count = #vim.api.nvim_list_bufs()
assert(format(broken), "invalid TOML must fail")
assert(vim.deep_equal(invalid, vim.api.nvim_buf_get_lines(broken, 0, -1, false)), "failed format changed source")
assert(#vim.api.nvim_list_bufs() == count, "failed format leaked a buffer")

-- 形式を判定できない場合も，CLIへフォールバックしない．
local unknown = buffer(root .. "/unknown-format.tmpl", { "{{ if true }}text{{ end }}" })
assert(not format(unknown))
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(unknown, 0, -1, false), { "{{ if true }}text{{ end }}" }))
