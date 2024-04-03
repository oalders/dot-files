local tsj = require('treesj')
local wk = require("which-key")
_G.OpenThis = function(fname)
    local cmd = 'ot --editor vim --print ' .. vim.fn.shellescape(fname)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    if result ~= "" then
        vim.cmd('e ' .. result)  -- remove shellescape() here
    else
        print("Error: could not open file")
    end

    -- Add the command to the command history
    vim.fn.histadd(':', string.format(':lua OpenThis("%s")', vim.fn.escape(fname, '"\\')))
end

wk.register({
    f = {
        f = { '<cmd>Files<cr>', 'open FZF file finder' },
        c = { function() require('ufo').closeAllFolds() end, 'close all folds' },
        o = { function() require('ufo').openAllFolds() end, 'open all folds' },
    },
    g = {
        c = { function()
            require('copilot').setup({
                filetypes = {
                    applescript = true,
                    cvs = false,
                    ["."] = false,
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
                        accept = "<M-l>",
                        accept_word = false,
                        accept_line = false,
                        next = "<M-]>",
                        prev = "<M-[>",
                        dismiss = "<C-]>",
                    },
                },
            });
            require('copilot_cmp').setup();
            require('copilot.api').register_status_notification_handler(function(data)
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
            end)
            vim.opt.formatoptions:remove({ 'o' })
        end, 'set up and start GH copilot' },
        d = { function()
            vim.print('foo')
        end, 'debug stuff'
        },
        e = { '<cmd>Copilot enable<cr>', 'enable GH copilot' },
        t = { function()
            if vim.opt.number:get() == false then
                vim.fn.ShowGutter()
            else
                vim.fn.HideGutter()
            end
        end, 'toggle gutter' },
        j = { function() tsj.join() end, 'join the object under cursor' },
        s = { function() tsj.split() end, 'split the object under cursor' },
        x = { '<cmd>Copilot disable<cr>', 'stop GH copilot' },
        w = { 'Vgw<cr>', 'wrap long lines'},
    },
    l = {
        l = { function()
            require('hlchunk').setup({
                indent = {
                    chars = { "│", "¦", "┆", "┊", }, -- more code can be found in https://unicodeplus.com/
                    style = { "#5E81AC" },
                },
                blank = {
                    enable = false,
                }
            })
        end, "hlchunk" },
        h = { "<cmd>DisableHL<cr>", "Disable HL" }
    },
    o = {
        t = {
          function() OpenThis(vim.fn.input("ot: ", "", "file")) end,
          "open files via ot"
        },
    },
    t = {
        c = { function() require('trouble').close() end,
            'Close Trouble' },
        d = { function() require('trouble').open('document_diagnostics') end,
            'Trouble document diagnostics' },
        n = { function() require("trouble").next({skip_groups = true, jump = true}) end, 'Next trouble issue';},
        p = { function() require("trouble").previous({skip_groups = true, jump = true}) end, 'Next trouble issue';},
        w = { function() require('trouble').open('workspace_diagnostics') end,
            'Trouble workspace diagnostics' },
    }
}, { prefix = "<leader>" })

wk.setup {}
