require('conf/lazy')

-- require('project_nvim').setup({
--     detection_methods = { 'pattern', 'lsp'},
--     manual_mode = false,
--     patterns = { 'playwright.config.ts', '.git', 'Makefile' },
--     silent_chdir = true, -- enable for debugging
--     -- ignore_lsp = { 'null-ls' },
--     scope_chdir = 'global',
-- })

require('conf/lspconfig')

require('conf/fzf')
require('conf/lualine')
require('conf/treesitter')
require('conf/open-this') -- needs to happen before which-key
require('conf/which-key')
