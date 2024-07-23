local tsj = require('treesj')
local wk = require('which-key')
wk.add({
    {
        '<leader>ff',
        '<cmd>Files<cr>',
        desc = 'open FZF file finder',
    },
    {
        '<leader>fc',
        function()
            require('ufo').closeAllFolds()
        end,
        desc = 'close all folds',
    },
    {
        '<leader>fo',
        function()
            require('ufo').openAllFolds()
        end,
        desc = 'open all folds',
    },
    {
        '<leader>gc',
        function()
            require('copilot').setup({
                filetypes = {
                    applescript = true,
                    cvs = false,
                    ['.'] = false,
                    gitcommit = true,
                    gitrebase = false,
                    go = true,
                    gohtmltmpl = true,
                    help = false,
                    lua = true,
                    markdown = true,
                    perl = true,
                    typescript = true,
                    yaml = true,
                },
                panel = { enabled = false },
                suggestion = {
                    enabled = false,
                    auto_trigger = true,
                    debounce = 75,
                    keymap = {
                        accept = '<M-l>',
                        accept_word = false,
                        accept_line = false,
                        next = '<M-]>',
                        prev = '<M-[>',
                        dismiss = '<C-]>',
                    },
                },
            })
            require('copilot_cmp').setup()
            require('copilot.api').register_status_notification_handler(
                function(data)
                    -- customize your message however you want
                    local msg = '?'
                    if data.status == 'Normal' then
                        msg = ' '
                    elseif data.status == 'InProgress' then
                        msg = ' '
                    else
                        msg = ' '
                    end
                    vim.print(msg)
                end
            )
            vim.opt.formatoptions:remove({ 'o' })
        end,
        desc = 'set up and start GH copilot',
    },
    { '<leader>ge', '<cmd>Copilot enable<cr>',   desc = 'enable GH copilot' },
    {
        '<leader>gh',
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.help_actions()
            )
        end,
        desc = 'CopilotChat - Help actions',
    },
    {
        '<leader>gj',
        function()
            tsj.join()
        end,
        desc = 'join the object under cursor',
    },
    {
        '<leader>gp',
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.prompt_actions()
            )
        end,
        desc = 'CopilotChat - Prompt actions',
    },
    {
        '<leader>gs',
        function()
            tsj.split()
        end,
        desc = 'split the object under cursor',
    },
    { '<leader>gw', 'Vgw<cr>',                   desc = 'wrap long lines' },
    { '<leader>gx', '<cmd>Copilot disable<cr>',  desc = 'stop GH copilot' },
    { '<leader>gy', '<cmd>CopilotChatClose<cr>', desc = 'CopilotChatClose' },
    {
        '<leader>lc',
        function()
            vim.opt.colorcolumn = '78'
        end,
        desc = 'set colorcolumn to 78',
    },
    {
        '<leader>lh',
        function()
            require('hlchunk').setup({
                blank = {
                    enable = false,
                },
                chunk = {
                    chars = {
                        horizontal_line = '─',
                        vertical_line = '│',
                        left_top = '┌',
                        left_bottom = '└',
                        right_arrow = '─',
                    },
                    style = '#00ffff',
                    enable = true,
                },
                indent = {
                    chars = { '│', '¦', '┆', '┊' }, -- more code can be found in https://unicodeplus.com/
                    enable = true,
                    style = { '#5E81AC' },
                },
            })
        end,
        desc = 'hlchunk',
    },
    {
        '<leader>ll',
        '<cmd>Lspsaga code_action<cr>',
        desc = 'Lspsaga code_action',
    },
    {
        '<leader>ln',
        ':Lspsaga diagnostic_jump_next<cr>',
        desc = 'Next diagnostic issue',
    },
    {
        '<leader>lp',
        ':Lspsaga diagnostic_jump_prev<cr>',
        desc = 'Previous diagnostic issue',
    },
    { '<leader>lx', ':DisableHLChunk<cr>',  desc = 'disable hlchunk' },
    {
        '<leader>ot',
        function()
            OpenThis(vim.fn.input('ot: ', '', 'file'))
        end,
        desc = 'open files via ot',
    },
    { '<leader>sv', ':source $MYVIMRC<cr>', desc = 'Source VimRC' },
    {
        '<leader>to',
        function()
            local line = vim.api.nvim_get_current_line()
            if string.find(line, 'test.describe.only') then
                vim.api.nvim_command('s/test.describe.only/test.describe/')
            elseif string.find(line, 'test.only') then
                vim.api.nvim_command('s/test.only/test/')
            elseif string.find(line, 'test.describe') then
                vim.api.nvim_command('s/test.describe/test.describe.only/')
            elseif string.find(line, 'test') then
                vim.api.nvim_command('s/test/test.only/')
            end
        end,
        desc = 'Toggle test.only',
    },
    { '<leader>tt', '<cmd>ToggleTerm<cr>', desc = 'toggle terminal' },
    { '<leader>ui', '<Plug>Nuuid',         desc = 'Generate UUID' },
    {
        '<leader>vt',
        ':ToggleTerm direction=vertical size=145<cr>',
        desc = 'vertical terminal',
    },
    {
        'cf',
        ':CopilotChatFix<cr>',
        desc = 'CopilotChatFix',
        mode = 'v',
    },
    {
        'ch',
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.help_actions()
            )
        end,
        desc = 'CopilotChat - Help actions',
        mode = 'v',
    },
    { 'co', '<cmd>CopilotChatOpen<cr>', desc = 'CopilotChat', mode = 'v' },
    {
        'cp',
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.prompt_actions()
            )
        end,
        desc = 'CopilotChat - Prompt actions',
        mode = 'v',
    },
    {
        'cx',
        '<cmd>CopilotChatExplain<cr>',
        desc = 'CopilotChatExplain',
        mode = 'v',
    },
    {
        'hh',
        ':s/_/-/g<cr>',
        desc = 'change underscores to hyphens',
        mode = 'v',
    },
    {
        'jq',
        ':!jq -S .<cr>',
        desc = 'Format selected JSON via jq',
        mode = 'v',
    },
    {
        'su',
        ':!sort -d --ignore-case -u',
        desc = 'Sort and remove duplicates',
        mode = 'v',
    },
    {
        'uu',
        ':s/-/_/g<cr>',
        desc = 'change hyphens to underscores',
        mode = 'v',
    },
})

wk.setup({})
