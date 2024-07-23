local tsj = require('treesj')
local wk = require('which-key')
wk.register({
    f = {
        f = { '<cmd>Files<cr>', 'open FZF file finder' },
        c = {
            function()
                require('ufo').closeAllFolds()
            end,
            'close all folds',
        },
        o = {
            function()
                require('ufo').openAllFolds()
            end,
            'open all folds',
        },
    },
    g = {
        c = {
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
            'set up and start GH copilot',
        },
        d = {
            function()
                vim.print('foo')
            end,
            'debug stuff',
        },
        e = { '<cmd>Copilot enable<cr>', 'enable GH copilot' },
        h = {
            function()
                local actions = require('CopilotChat.actions')
                require('CopilotChat.integrations.fzflua').pick(
                    actions.help_actions()
                )
            end,
            'CopilotChat - Help actions',
        },
        j = {
            function()
                tsj.join()
            end,
            'join the object under cursor',
        },
        p = {
            function()
                local actions = require('CopilotChat.actions')
                require('CopilotChat.integrations.fzflua').pick(
                    actions.prompt_actions()
                )
            end,
            'CopilotChat - Prompt actions',
        },
        s = {
            function()
                tsj.split()
            end,
            'split the object under cursor',
        },
        t = {
            function()
                if vim.opt.number:get() == false then
                    vim.fn.ShowGutter()
                else
                    vim.fn.HideGutter()
                end
            end,
            'toggle gutter',
        },
        x = { '<cmd>Copilot disable<cr>', 'stop GH copilot' },
        y = { '<cmd>CopilotChatClose<cr>', 'CopilotChatClose' },
        w = { 'Vgw<cr>', 'wrap long lines' },
    },
    l = {
        c = {
            function()
                vim.opt.colorcolumn = '78'
            end,
            'set colorcolumn to 78',
        },
        cc = {
            function()
                vim.opt.colorcolumn = ''
            end,
            'unset colorcolumn',
        },
        h = {
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
            'hlchunk',
        },
        l = { '<cmd>Lspsaga code_action<cr>', 'Lspsaga code_action' },
        n = {
            ':Lspsaga diagnostic_jump_next<cr>',
            'Next diagnostic issue',
        },
        p = {
            ':Lspsaga diagnostic_jump_prev<cr>',
            'Previous diagnostic issue',
        },
        x = { ':DisableHLChunk<cr>', 'disable hlchunk' },
    },
    o = {
        t = {
            function()
                OpenThis(vim.fn.input('ot: ', '', 'file'))
            end,
            'open files via ot',
        },
    },
    s = {
        v = { ':source $MYVIMRC<cr>', 'Source VimRC' },
    },
    t = {
        -- make isolating Playwright tests less painful
        o = {
            function()
                local line = vim.api.nvim_get_current_line()
                if string.find(line, 'test.describe.only') then
                    vim.api.nvim_command(
                        's/test.describe.only/test.describe/'
                    )
                elseif string.find(line, 'test.only') then
                    vim.api.nvim_command('s/test.only/test/')
                elseif string.find(line, 'test.describe') then
                    vim.api.nvim_command(
                        's/test.describe/test.describe.only/'
                    )
                elseif string.find(line, 'test') then
                    vim.api.nvim_command('s/test/test.only/')
                end
            end,
            'Toggle test.only',
        },
        t = {
            ':ToggleTerm<cr>',
            'toggle terminal',
        },
    },
    v = {
        t = {
            ':ToggleTerm direction=vertical size=145<cr>',
            'vertical terminal',
        },
    },
    -- t = {
    --     c = {
    --         function()
    --             require('trouble').close()
    --         end,
    --         'Close Trouble',
    --     },
    --     d = {
    --         '<cmd>Trouble diagnostics toggle<cr>',
    --         function()
    --             require('trouble').open('document_diagnostics')
    --         end,
    --         'Trouble document diagnostics',
    --     },
    --     n = {
    --         function()
    --             require('trouble').next({ skip_groups = true, jump = true })
    --         end,
    --         'Next trouble issue',
    --     },
    --     p = {
    --         function()
    --             require('trouble').previous({
    --                 skip_groups = true,
    --                 jump = true,
    --             })
    --         end,
    --         'Next trouble issue',
    --     },
    --     w = {
    --         function()
    --             require('trouble').open('workspace_diagnostics')
    --         end,
    --         'Trouble workspace diagnostics',
    --     },
    -- },
    u = {
        i = { '<Plug>Nuuid', 'Generate UUID' },
    },
}, { prefix = '<leader>' })

wk.register({
    cf = {
        ':CopilotChatFix<cr>',
        'CopilotChatFix',
    },
    ch = {
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.help_actions()
            )
        end,
        'CopilotChat - Help actions',
    },
    co = {
        '<cmd>CopilotChat<cr>',
        'CopilotChat',
    },
    cp = {
        function()
            local actions = require('CopilotChat.actions')
            require('CopilotChat.integrations.fzflua').pick(
                actions.prompt_actions()
            )
        end,
        'CopilotChat - Prompt actions',
    },
    cx = {
        '<cmd>CopilotChatExplain<cr>',
        'CopilotChatExplain',
    },
    hh = {
        ':s/_/-/g<cr>',
        'change underscores to hyphens',
    },
    jq = {
        ':!jq -S .<cr>',
        'Format selected JSON via jq',
    },
    su = {
        ':!sort -d --ignore-case -u',
        'Sort and remove duplicates',
    },
    uu = {
        ':s/-/_/g<cr>',
        'change hyphens to underscores',
    },
}, { mode = 'v', silent = false })

wk.setup({})
