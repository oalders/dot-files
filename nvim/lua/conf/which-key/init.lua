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
        '<leader>gb',
        function()
            local input = vim.fn.input('Quick Chat about buffer: ')
            if input ~= '' then
                require('CopilotChat').ask(
                    input,
                    { selection = require('CopilotChat.select').buffer }
                )
            end
        end,
        desc = 'CopilotChat - Quick chat',
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
    { '<leader>ge', '<cmd>Copilot enable<cr>', desc = 'enable GH copilot' },
    { '<leader>gf', '<cmd>GFiles?<cr>', desc = 'git changed files' },
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
            require('treesj').join()
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
            require('treesj').split()
        end,
        desc = 'split the object under cursor',
    },
    { '<leader>gw', 'Vgw<cr>', desc = 'wrap long lines' },
    { '<leader>gx', '<cmd>Copilot disable<cr>', desc = 'stop GH copilot' },
    { '<leader>gy', '<cmd>CopilotChatClose<cr>', desc = 'CopilotChatClose' },
    {
        '<leader>lc',
        function()
            vim.opt.colorcolumn = '78'
        end,
        desc = 'set colorcolumn to 78',
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
    { '<leader>ui', '<Plug>Nuuid', desc = 'Generate UUID' },
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
        '<leader>co',
        '<cmd>CopilotChatOpen<cr>',
        desc = 'CopilotChat',
        mode = 'n',
    },
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
    {
        '<leader>qs',
        function()
            require('persistence').load()
        end,
        desc = 'load the session for the current directory',
        mode = 'n',
    },
    {
        '<leader>qS',
        function()
            require('persistence').select()
        end,
        desc = 'select a session to load',
        mode = 'n',
    },
    {
        '<leader>ql',
        function()
            require('persistence').load({ last = true })
        end,
        desc = 'load the last session',
        mode = 'n',
    },
    {
        '<leader>qd',
        function()
            require('persistence').stop()
        end,
        desc = 'do not save session on exit',
        mode = 'n',
    },
})

wk.setup({})
