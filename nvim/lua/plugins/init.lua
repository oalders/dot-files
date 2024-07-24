require('conf/lazy')

require('other-nvim').setup({
    mappings = { 'golang' },
})

-- require('project_nvim').setup({
--     detection_methods = { 'pattern', 'lsp'},
--     manual_mode = false,
--     patterns = { 'playwright.config.ts', '.git', 'Makefile' },
--     silent_chdir = true, -- enable for debugging
--     -- ignore_lsp = { 'null-ls' },
--     scope_chdir = 'global',
-- })

local null_ls = require('null-ls')
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.stylua,
    },
})

require('bufferline').setup({
    options = {
        diagnostics = 'nvim_lsp',
        numbers = 'ordinal',
    },
})

require('conf/cmp')
require('conf/mason') -- This needs to happen before lspconfig
require('conf/lspconfig')

require('conf/fzf')
require('conf/lualine')
require('conf/neotest')
require('conf/nvim-lint')
require('conf/telescope')
require('conf/treesitter')
require('conf/ufo')
require('conf/open-this') -- needs to happen before which-key
require('conf/which-key')
require('yankbank').setup()
