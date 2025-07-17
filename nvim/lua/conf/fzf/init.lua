---@diagnostic disable: undefined-global
-- fzf-lua
local fzf_lua = require('fzf-lua')

fzf_lua.setup({
    'fzf-vim',
})
fzf_lua.setup({
    fzf_colors = true,
    winopts = { width = 0.98 },
    -- This section probably isn't needed when using snacks.nvim, because
    -- snacks.nvim will be detected and fzf-lua will hand off rendering to it.
    previewers = {
        builtin = {
            extensions = {
                ['jpg'] = { 'chafa', '--clear', '{file}' },
                ['png'] = { 'viu', '-b' },
                ['svg'] = { 'chafa', '--clear', '{file}' },
            },
        },
    },
})

fzf_lua.git_domo = function()
    fzf_lua.files({
        prompt = 'GitDomo>',
        cmd = '{ git diff --name-only HEAD; git domo --diff-filter=d;} | sort -u',
    })
end

vim.cmd([[
  command! -bang GDomo lua require('fzf-lua').git_domo()
]])
