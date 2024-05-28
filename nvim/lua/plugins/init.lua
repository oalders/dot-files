require('conf/lazy')

vim.opt.termguicolors = true
vim.opt.mouse = 'v'

-- require('virt-column').setup()
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

require('conf/lualine')
require('conf/neotest')
require('conf/noice')
require('conf/nvim-lint')
require('conf/telescope')
require('conf/treesitter')
require('conf/ufo')
require('conf/open-this') -- needs to happen before which-key
require('conf/which-key')

-- fzf-lua
local fzf_lua = require('fzf-lua')
fzf_lua.setup({ 'fzf-vim' })

fzf_lua.setup({
    previewers = {
        builtin = {
            extensions = {
                ['jpg'] = { 'chafa', '{file}' },
                ['png'] = { 'viu', '-b' },
                ['svg'] = { 'chafa', '{file}' },
            },
        },
    },
})

fzf_lua.git_domo = function()
    fzf_lua.files({
        prompt = 'GitDomo>',
        cmd = '{ git diff --name-only HEAD; git domo;} | sort -u',
    })
end

vim.cmd([[
  command! -bang GDomo lua require('fzf-lua').git_domo()
]])

-- end

require('gitsigns').setup({ numhl = true })
require('persisted').setup({})
require('yankbank').setup()
