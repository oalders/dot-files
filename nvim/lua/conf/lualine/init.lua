-- 0: filename only
-- 1: relative path
-- 2: absolute path
-- 3: absolute path with tilde
local function path_option()
    if vim.o.columns > 78 then
        return 1
    else
        return 0
    end
end

vim.api.nvim_set_hl(0, 'LspClientsFg', { fg = '#bb9af7' })
vim.api.nvim_set_hl(0, 'ModifiedFileBg', { bg = '#ffc777', fg = '#1a1b26' })

-- LSP clients attached to buffer
local clients_lsp = function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if next(clients) == nil then
        return ''
    end

    local c = {}
    for _, client in pairs(clients) do
        local name = client.name
        if name == 'copilot' then
            name = '🤖'
        elseif name == 'perlnavigator' then
            name =
                require('nvim-web-devicons').get_icon_by_filetype('perl', {})
        elseif name == 'eslint' then
            name = ''
        end
        table.insert(c, name)
    end
    table.sort(c)
    return '%#LspClientsFg#' .. table.concat(c, '  ') .. '%*'
end

require('lualine').setup({
    options = {
        icons_enabled = true,
        section_separators = { left = '', right = '' },
        component_separators = { left = '󰿟', right = '' },
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = false,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        },
        theme = 'tokyonight',
    },
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = function(str)
                    return str:sub(1, 1)
                end,
                separator = { left = '', right = '' },
                right_padding = 2,
            },
        },
        lualine_b = { 'diff', 'diagnostics' },
        lualine_c = {
            {
                'filename',
                symbols = {
                    modified = ' 󰠠 ',
                    readonly = '🔒',
                },
                path = path_option(),
                color = function()
                    return vim.bo.modified and 'ModifiedFileBg' or nil
                end,
            },
        },
        lualine_x = { clients_lsp, 'encoding', 'filetype' },
        lualine_y = { 'searchcount' },
        lualine_z = { 'location', 'progress' },
    },
    inactive_sections = {
        -- lualine_a = {},
        -- lualine_b = {},
        -- lualine_c = { 'filename' },
        -- lualine_x = { 'location' },
        -- lualine_y = {},
        -- lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = { 'mason', 'trouble' },
})
