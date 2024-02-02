local neotest = require 'neotest'
local neotest_ns = vim.api.nvim_create_namespace 'neotest'
vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
      return message
    end,
  },
}, neotest_ns)

---@diagnostic disable-next-line:missing-fields
neotest.setup {
  adapters = {
    require 'neotest-go',
  },
  output_panel = {
    enabled = true,
    open = 'vertical rightbelow 120vnew',
  },
  output = {
    enabled = false,
    open_on_run = true,
  },
}
