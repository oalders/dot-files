-- fzf-lua
local fzf_lua = require('fzf-lua')

fzf_lua.setup({
    'fzf-vim',
})
fzf_lua.setup({
    fzf_colors = true,
    winopts = { width = 0.98 },
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
        cmd = '{ git diff --name-only HEAD; git domo --diff-filter=d;} | sort -u',
    })
end

vim.cmd([[
  command! -bang GDomo lua require('fzf-lua').git_domo()
]])
