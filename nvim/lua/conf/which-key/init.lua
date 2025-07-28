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
                    { selection = require('CopilotChat.select').buffers }
                )
            end
        end,
        desc = 'CopilotChat - Buffers context',
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
    { '<leader>gd', '<cmd>GDomo<cr>', desc = 'git domo' },
    { '<leader>ge', '<cmd>Copilot enable<cr>', desc = 'enable GH copilot' },
    { '<leader>gf', '<cmd>GFiles?<cr>', desc = 'git changed files' },
    {
        '<leader>gl',
        function()
            require('fzf-lua').git({ 'git domo' })
        end,
        desc = 'git changed files',
    },
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
        -- ':Lspsaga diagnostic_jump_next<cr>',
        function()
            require('telescope.builtin').diagnostics()
        end,
        desc = 'Next diagnostic issue',
    },
    {
        '<leader>lp',
        ':Lspsaga diagnostic_jump_prev<cr>',
        desc = 'Previous diagnostic issue',
    },
    {
        '<leader>ls',
        ':FzfLua lsp_document_symbols<cr>',
        desc = 'List symbols in document',
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
            local patterns = {
                { 'test.describe.only', 'test.describe' },
                { 'test.only', 'test' },
                { 'it.only', 'it' },
                { 'test.describe', 'test.describe.only' },
                { 'test', 'test.only' },
                { 'it', 'it.only' },
            }

            for _, pattern in ipairs(patterns) do
                if string.find(line, pattern[1]) then
                    vim.api.nvim_command(
                        's/' .. pattern[1] .. '/' .. pattern[2] .. '/'
                    )
                    break
                end
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
    {
        '<leader>ca',
        '<cmd>lua vim.lsp.buf.code_action()<cr>',
        desc = 'Code Action (LSP)',
        mode = 'n',
    },
    {
        '<leader>cc',
        '<cmd>CopilotChatToggle<cr>',
        desc = 'CopilotChat toggle',
    },
    {
        '<leader>cr',
        '<cmd>CopilotChatReset<cr>',
        desc = 'CopilotChat reset',
    },
    {
        'cc',
        '<cmd>CopilotChatToggle<cr>',
        desc = 'CopilotChat toggle',
        mode = 'v',
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
        'ct',
        function()
            local input =
                vim.fn.input('Write a Go test for visual selection: ')
            if input ~= '' then
                local message = [[
Write a Golang test for the visual selection.
* Don't use database mocks.
* Prefer assert.Equal() over test.expected.
* Show me only the changed lines.
* Test for errors using require.NoError()
* Use assert.True and assert.False when testing booleans
* Use assert.InEpsilon or assert.InDelta when comparing floats
* Follow patterns in the corresponding _test.go file, if it exists
            ]]
                require('CopilotChat').ask(input .. '\n' .. message, {
                    context = { 'buffers' },
                    selection = require('CopilotChat.select').visual,
                })
            end
        end,
        desc = 'CopilotChat - Write Go test for selection',
        mode = 'v',
    },
    {
        'cg',
        function()
            local input =
                vim.fn.input('Convert the selected code from Perl to Go: ')
            if input ~= '' then
                local message = [[
Convert the selected code from Perl to Go.
* Use `map[string]struct{}{}` when converting a hash which is only there to track if keys exist
* avoid deprecated libraries and constructs
* for error assertions in tests, use require
* prefer netip.ParseAddr over net.ParseIP
            ]]
                require('CopilotChat').ask(input .. '\n' .. message, {
                    context = { 'buffers' },
                    selection = require('CopilotChat.select').visual,
                })
            end
        end,
        desc = 'CopilotChat - Write Go test for selection',
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
    {
        '<space>ww',
        function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                -- Check if the buffer is writable, not 'nofile', and has unsaved changes
                local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
                local is_readonly =
                    vim.api.nvim_buf_get_option(buf, 'readonly')
                local is_modified =
                    vim.api.nvim_buf_get_option(buf, 'modified') -- Check if the buffer is modified

                -- Only write if the buffer is writable, has changes, and is not 'nofile'
                if
                    buftype ~= 'nofile'
                    and not is_readonly
                    and is_modified
                then
                    -- Write the buffer if it has unsaved changes
                    vim.api.nvim_command('buf ' .. buf) -- Switch to the buffer
                    vim.api.nvim_command('write') -- Write the buffer
                end
            end
        end,
        desc = 'write all non-readonly buffers',
        mode = 'n',
    },
})

wk.setup({})
