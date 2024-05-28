require('conf/lazy')

require('nvim-autopairs').setup({})

require('other-nvim').setup({
    mappings = { 'golang' },
})

require('project_nvim').setup({
    detection_methods = { 'pattern', 'lsp' },
    patterns = { '.git', 'Makefile' },
    silent_chdir = false,
    -- ignore_lsp = { 'null-ls' },
    scope_chdir = 'global',
})

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

local tsj = require('treesj')
tsj.setup({ max_join_length = 400 })

require('bufferline').setup({
    options = {
        diagnostics = 'nvim_lsp',
        numbers = 'ordinal',
    },
})
require('glow').setup({
    width_ratio = 0.9, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
    height_ratio = 0.9,
})
require('nvim-splitrun').setup()

require('conf/cmp')
require('conf/mason') -- This needs to happen before lspconfig
require('conf/lspconfig')

require('conf/fzf')
require('conf/lualine')
require('conf/neotest')
require('conf/noice')
require('conf/nvim-lint')
require('conf/telescope')
require('conf/treesitter')
require('conf/ufo')
require('conf/open-this') -- needs to happen before which-key
require('conf/which-key')

require('gitsigns').setup({ numhl = true })
require('persisted').setup({})
require('yankbank').setup()
