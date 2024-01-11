local l = require 'lint'

vim.api.nvim_create_autocmd({ 'BufWritePost', 'VimEnter', 'BufEnter' }, {
    pattern = { '*' },
    callback = function()
        l.try_lint()
    end,
})

l.linters_by_ft = {
    go = { 'golangcilint' },
    lua = { 'selene' },
    markdown = { 'markdownlint' },
    perl = { 'perlimports' },
    sql = { 'sqlfluff' },
    vim = { 'vint' },
    yaml = { 'yamllint' },
}

for ft, _ in pairs(l.linters_by_ft) do
    table.insert(l.linters_by_ft[ft], 'typos')
end
