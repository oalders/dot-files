-- 0: filename only
-- 1: relative path
-- 2: absolute path
-- 3: absolute path with tilde
local function path_option()
    if vim.o.columns > 78 then
        return 3
    else
        return 0
    end
end

require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'nord',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
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
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'diff', 'diagnostics' },
        lualine_c = {
            {
                'filename',
                symbols = {
                    modified = '💾',
                    readonly = '🔒',
                },
                path = path_option(),
            } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'searchcount' },
        -- lualine_y = { copilot_status },
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
    extensions = {'mason','trouble'}
}
