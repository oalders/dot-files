---@diagnostic disable: undefined-global
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        lazyrepo,
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out, 'WarningMsg' },
            { '\nPress any key to exit...' },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
-- vim.g.mapleader = ' '
-- vim.g.maplocalleader = '\\'

require('lazy').setup({
    spec = {
        -- Colour schemes
        -- Plug 'arcticicestudio/nord-vim'
        -- 'cocopon/iceberg.vim',
        {
            'folke/tokyonight.nvim',
            lazy = false,
            priority = 1000,
            config = function()
                -- load the colorscheme here
                vim.cmd([[colorscheme tokyonight-moon]])
            end,
            opts = {
                on_highlights = function(highlights, colors)
                    highlights['@markup.raw.pod'] = {
                        italic = true,
                        fg = colors.green,
                    }
                end,
                plugins = {
                    auto = true,
                },
            },
        },
        {
            -- Toggle via :ZenMode
            'folke/zen-mode.nvim',
            opts = {},
        },
        {
            'folke/snacks.nvim',
            enabled = true,
            priority = 1000,
            lazy = false,
            opts = {
                dashboard = {
                    sections = {
                        -- {
                        --     section = 'terminal',
                        --     cmd = 'chafa ~/dot-files/wall.png --format symbols --symbols vhalf --size 60x17 --stretch; sleep .1',
                        --     height = 17,
                        --     padding = 1,
                        -- },
                        {
                            pane = 1,
                            { section = 'keys', gap = 1, padding = 1 },
                            { section = 'startup' },
                        },
                    },
                },
                image = {},
                input = { enabled = true, style = 'fancy' },
                notifier = {
                    enabled = true,
                    timeout = 3000,
                    height = { min = 2, max = 0.8 },
                    width = { min = 40, max = 0.8 },
                },
                terminal = { enabled = true },
                toggle = {},
            },
        },
        {
            -- fade inactive buffers and preserve syntax highlighting
            'TaDaa/vimade',
            enabled = false,
        },
        -- Smooth cursor movement.
        {
            'sphamba/smear-cursor.nvim',
            enabled = true,
            opts = {},
        },

        -- Smooth scrolling.
        {
            'karb94/neoscroll.nvim',
            enabled = false,
            config = function()
                require('neoscroll').setup({})
            end,
        },

        -- git
        {
            'akinsho/git-conflict.nvim',
            version = '2.0.0',
            config = true,
            event = 'VeryLazy',
        },

        -- git signs in the gutter
        {
            'lewis6991/gitsigns.nvim',
            event = 'VeryLazy',
            opts = {
                linehl = true,
                numhl = true,
                word_diff = false,
                on_attach = function(bufnr)
                    local gitsigns = require('gitsigns')
                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    map('n', ']c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ ']c', bang = true })
                        else
                            gitsigns.nav_hunk('next')
                        end
                    end)

                    map('n', '[c', function()
                        if vim.wo.diff then
                            vim.cmd.normal({ '[c', bang = true })
                        else
                            gitsigns.nav_hunk('prev')
                        end
                    end)

                    -- reset hunk
                    map('n', '<leader>rh', gitsigns.reset_hunk)
                    map('v', '<leader>rh', function()
                        gitsigns.reset_hunk({
                            vim.fn.line('.'),
                            vim.fn.line('v'),
                        })
                    end)

                    -- stage hunk
                    map('v', '<leader>sh', function()
                        gitsigns.stage_hunk({
                            vim.fn.line('.'),
                            vim.fn.line('v'),
                        })
                    end)

                    map('n', '<leader>sh', function()
                        gitsigns.stage_hunk({
                            vim.fn.line('.'),
                            vim.fn.line('v'),
                        })
                    end)
                end,
            },
        },
        { 'rhysd/git-messenger.vim', event = 'VeryLazy' }, -- ,gm to open window

        -- DiffviewOpen
        -- DiffviewOpen origin/main
        -- DiffviewFileHistory %
        { 'sindrets/diffview.nvim', event = 'VeryLazy' }, -- File explorer for git diffs
        { 'tpope/vim-fugitive', event = 'VeryLazy' }, --  :GRemove, :Git diff, etc

        { 'ap/vim-css-color', event = 'VeryLazy' }, -- show css colors inline
        { 'gregsexton/MatchTag', ft = 'html' }, -- highlight matching HTML tags
        'haya14busa/vim-auto-mkdir', -- create directory path on save
        'itchyny/vim-cursorword', -- underline the word under the cursor
        {
            'junegunn/fzf',
            enabled = false,
            dir = '~/.fzf',
            build = './install --all',
        },
        -- Plug 'junegunn/fzf.vim' -- disabled while testing fzf-lua
        -- Plug 'junegunn/vader.vim' -- run Vader tests from inside vim

        -- automatically clear search highlight when cursor is moved
        -- zz after search places the current match at the center of the window
        'junegunn/vim-slash',

        'kburdett/vim-nuuid', -- <leader>ui to insert a new UUID
        'luochen1990/rainbow', -- Rainbow Parentheses Improved
        {
            'mannih/vim-perl-variable-highlighter', -- highlight other instances of selected var
            ft = 'perl',
        },
        { 'motemen/xslate-vim', ft = 'xslate' }, -- https://metacpan.org/pod/Text::Xslate
        { 'mzlogin/vim-markdown-toc', ft = 'markdown' }, -- :GenTocGFM to generate table of contents
        {
            'MeanderingProgrammer/render-markdown.nvim',
            opts = {},
            dependencies = {
                'nvim-treesitter/nvim-treesitter',
            },
            ft = 'markdown',
        },
        -- 'oalders/prettysql' -- ,fs to format visually selected SQL
        { 'othree/html5.vim', ft = 'html' },
        -- 'rodjek/vim-puppet', -- { 'for': 'puppet' }, -- Formatting, syntax highlighting etc
        {
            'rust-lang/rust.vim',
            ft = 'rust',
        },
        'tpope/vim-abolish',

        -- :Delete :SudoWrite
        'tpope/vim-eunuch',

        {
            'vim-ruby/vim-ruby', -- Vim/Ruby configuration files
            ft = 'ruby',
        },

        { 'yko/mojo.vim', ft = 'html.epl' }, -- syntax highlighting for mojo epl templates

        -- {
        --     'ahmedkhalf/project.nvim',
        --     ft = 'typescript',
        -- }, -- auto-detect project root
        {
            'akinsho/bufferline.nvim',
            enabled = false,
            version = '*',
            dependencies = 'nvim-tree/nvim-web-devicons',
            config = function()
                require('other-nvim').setup({
                    mappings = { 'golang' },
                    diagnostics = 'nvim_lsp', -- Move this key to the correct place
                    numbers = 'ordinal', -- Move this key to the correct place
                })
            end,
        },
        {
            'EL-MASTOR/bufferlist.nvim',
            enabled = false,
            lazy = true,
            keys = {
                { '<Leader>b', ':BufferList<CR>', desc = 'Open bufferlist' },
            },
            dependencies = 'nvim-tree/nvim-web-devicons',
            cmd = 'BufferList',
            opts = {},
        },
        {
            'ellisonleao/glow.nvim',
            enabled = false,
            ft = 'markdown',
            config = true,
            cmd = 'Glow',
            opts = {
                width_ratio = 0.9, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
                height_ratio = 0.9,
            },
        }, -- render markdown via :Glow

        --  <leader>td (doc) <leader>tw (workspace)
        {
            'folke/trouble.nvim',
            event = 'LspAttach',
            opts = {}, -- for default options, refer to the configuration section for custom setup.
            cmd = 'Trouble',
            keys = {
                {
                    '<leader>td',
                    '<cmd>Trouble diagnostics toggle<cr>',
                    desc = 'Workspace Diagnostics (Trouble)',
                },
                {
                    '<leader>tb',
                    '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
                    desc = 'Buffer Diagnostics (Trouble)',
                },
                {
                    '<leader>cs',
                    '<cmd>Trouble symbols toggle focus=false<cr>',
                    desc = 'Symbols (Trouble)',
                },
                {
                    '<leader>cl',
                    '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
                    desc = 'LSP Definitions / references / ... (Trouble)',
                },
                {
                    '<leader>xL',
                    '<cmd>Trouble loclist toggle<cr>',
                    desc = 'Location List (Trouble)',
                },
                {
                    '<leader>xQ',
                    '<cmd>Trouble qflist toggle<cr>',
                    desc = 'Quickfix List (Trouble)',
                },
            },
        },

        -- better organization of keybindings
        {
            'folke/which-key.nvim',
            event = 'VeryLazy',
            init = function()
                vim.o.timeout = true
                vim.o.timeoutlen = 300
            end,
        },
        -- :Splitrun some command
        { 'Hubro/nvim-splitrun', opts = {} },

        --  replace fzf.vim
        {
            'ibhagwan/fzf-lua',
            dependencies = { 'nvim-tree/nvim-web-devicons' },
        },

        { 'kevinhwang91/nvim-bqf', ft = 'qf' }, -- add previews to quickfix window
        {
            'mfussenegger/nvim-lint',
            event = 'VeryLazy',
            config = function()
                local l = require('lint')

                vim.api.nvim_create_autocmd(
                    { 'BufWritePost', 'VimEnter', 'BufEnter' },
                    {
                        pattern = { '*' },
                        callback = function()
                            l.try_lint()
                        end,
                    }
                )

                l.linters_by_ft = {
                    gitcommit = {},
                    go = { 'golangcilint' },
                    lua = { 'selene' },
                    markdown = { 'markdownlint' },
                    -- perl = { 'perlimports' },
                    -- sh = { 'shellcheck' },
                    sql = { 'sqlfluff' },
                    typescript = { 'eslint' },
                    vim = { 'vint' },
                    yaml = { 'yamllint' },
                }

                for ft, _ in pairs(l.linters_by_ft) do
                    table.insert(l.linters_by_ft[ft], 'typos')
                end
                local e2e_dir = 'web/e2e'
                if vim.fn.isdirectory(e2e_dir) == 1 then
                    l.linters_by_ft.typescript = nil
                end
            end,
            ft = {
                'gitcommit',
                'go',
                'lua',
                'markdown',
                'sql',
                'typescript',
                'vim',
                'yaml',
            },
        },
        {
            'nvim-lualine/lualine.nvim',
            dependencies = { 'nvim-tree/nvim-web-devicons' },
            event = 'VeryLazy',
        },
        {
            'nvim-telescope/telescope.nvim',
            event = 'VeryLazy',
            tag = '0.1.5',
            opts = {
                defaults = {
                    -- Default configuration for telescope goes here:
                    -- config_key = value,
                    mappings = {
                        i = {
                            -- map actions.which_key to <C-h> (default: <C-/>)
                            -- actions.which_key shows the mappings for your picker,
                            -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                            ['<C-h>'] = 'which_key',
                        },
                    },
                },
                pickers = {
                    -- Default configuration for builtin pickers goes here:
                    -- picker_name = {
                    --   picker_config_key = value,
                    --   ...
                    -- }
                    -- Now the picker_config_key will be applied every time you call this
                    -- builtin picker
                },
                extensions = {
                    -- Your extension configuration goes here:
                    -- extension_name = {
                    --   extension_config_key = value,
                    -- }
                    -- please take a look at the readme of the extension you want to configure
                },
            },
        }, -- fuzzy finder
        {
            'nvimtools/none-ls.nvim', -- null-ls replacement
            ft = { 'go', 'javascript', 'typescript', 'bash', 'sh', 'lua' },
            config = function()
                local null_ls = require('null-ls')
                null_ls.setup({
                    sources = {
                        null_ls.builtins.formatting.goimports,
                        null_ls.builtins.formatting.prettier,
                        null_ls.builtins.formatting.shfmt,
                        null_ls.builtins.formatting.stylua,
                    },
                })
            end,
        },
        {
            'nvim-treesitter/nvim-treesitter',
            build = ':TSUpdate | :TSInstall diff',
        }, -- recommend updating parsers on update
        -- { 'olimorris/persisted.nvim',        opts = {} },           -- session management
        -- session management
        {
            'folke/persistence.nvim',
            event = 'BufReadPre', -- this will only start session saving when an actual file was opened
            opts = {
                -- add any custom options here
            },
        },

        -- easy access to yanks and deletes
        {
            'ptdewey/yankbank-nvim',
            dependencies = 'kkharji/sqlite.lua',
            config = function()
                require('yankbank').setup({
                    max_entries = 200,
                    persist_type = 'sqlite',
                    sep = '〰️〰️〰️〰️〰️〰️〰️〰️',
                })
            end,
            event = 'VeryLazy',
        },
        {
            'rgroli/other.nvim',
            ft = 'go',
            config = function()
                require('other-nvim').setup({
                    mappings = { 'golang' },
                })
            end,
        }, -- :Other to toggle between test and implementation files
        'windwp/nvim-autopairs', --

        -- display lines for indentation
        {
            'shellRaining/hlchunk.nvim',
            event = { 'BufReadPre', 'BufNewFile' },
            config = function()
                require('hlchunk').setup({})
            end,
            keys = {
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
                    '<leader>lx',
                    ':DisableHLChunk<cr>:DisableHLIndent<cr>',
                    desc = 'Disable hlchunk and hlindent',
                },
            },
        },

        {
            'Wansmer/treesj',
            opts = { use_default_keymaps = false, max_join_length = 400 },
            event = 'VeryLazy',
        },
        {
            'windwp/nvim-autopairs',
            config = true,
            event = 'InsertEnter',
            opts = {
                disable_filetype = { 'markdown' }, -- ``` completion is bonkers
            },
        },
        {
            'CopilotC-Nvim/CopilotChat.nvim',
            dependencies = {
                { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
                { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
                { 'https://github.com/gptlang/lua-tiktoken' },
            },
            opts = {
                auto_follow_cursor = false,
                chat_autocomplete = true,
                debug = false, -- Enable debugging
                -- > #buffer
                -- > #buffer:2
                -- > #files:\*.lua
                -- > #git:staged
                -- > #url:https://example.com
                context = 'buffer',
                mcp = {
                    enabled = true,
                    servers = { 'github' },
                },
                model = 'claude-3.5-sonnet', -- default to my personal account limits
                prompts = {
                    GoTest = '> /COPILOT_GENERATE\n\n'
                        .. 'Write tests for the selected Go.\n'
                        .. '* Use `map[string]struct{}{}` when creating a hash '
                        .. 'which is only there to track if keys exist\n'
                        .. '* avoid deprecated libraries and constructs\n'
                        .. '* for error assertions in tests, use require\n'
                        .. '* prefer netip.ParseAddr over net.ParseIP\n'
                        .. '* do not use database mocks\n'
                        .. '* follow existing patterns in the corresponding test file or in adjacent tests\n'
                        .. '* do not create database fixtures. Use existing ones. Check for .toml files\n'
                        .. '* create test contexts via t.Context()\n'
                        .. '* import assert from github.com/stretchr/testify/assert\n'
                        .. '* import require from github.com/stretchr/testify/require\n',

                    Perl2Go = '> /COPILOT_GENERATE\n\n'
                        .. 'Convert the selected code from Perl to Go.\n'
                        .. '* Use `map[string]struct{}{}` when converting a hash '
                        .. 'which is only there to track if keys exist\n'
                        .. '* avoid deprecated libraries and constructs\n'
                        .. '* for error assertions in tests, use require\n'
                        .. '* prefer netip.ParseAddr over net.ParseIP\n',

                    QuickFix = '> /COPILOT_GENERATE\n\n'
                        .. 'There is a problem with the selected code.\n'
                        .. ' * explain the error in the selected text\n'
                        .. ' * rewrite the code with the bug fixed.\n'
                        .. ' * show only the changed lines.',

                    ToPlaywright = '> /COPILOT_GENERATE\n\n'
                        .. "This is a git diff which contains test which have been ported from Perl to Typescript's Playwright testing framework.\n"
                        .. '* Enumerate the tests which have been deleted in the Perl files\n'
                        .. '* Enumerate the tests which have been added on the Go side\n'
                        .. '* Have any tests been deleted in Perl but not ported to Go?\n'
                        .. '* Are there any differences between the old and the new tests?\n'
                        .. "* If there's a chance of some loss of test coverage, where is a good place to start looking?\n",

                    ReviewPR = {
                        prompt = '/COPILOT_GENERATE Please review the current pull request using the GitHub MCP server. Focus on code quality, security, and best practices.',
                        -- mapping = '<leader>ccr',
                        description = 'Review current PR with Copilot',
                    },
                    ExplainPR = {
                        prompt = '/COPILOT_GENERATE Use the GitHub MCP server to get PR details and explain what changes were made and why.',
                        -- mapping = '<leader>cce',
                        description = 'Explain PR changes',
                    },
                    SecurityCheck = {
                        prompt = '/COPILOT_GENERATE Check this repository for security alerts and vulnerabilities using the GitHub MCP server.',
                        -- mapping = '<leader>ccs',
                        description = 'Security check with Copilot',
                    },
                },
                -- or select model via $ in chat
                sticky = {
                    -- '@models Using Claude 3.7 Sonnet',
                    '#buffer',
                },
                -- See Configuration section for rest
            },
            build = 'make tiktoken',
            event = 'VeryLazy',
            -- See Commands section for default commands if you want to lazy load on them
        },
        {
            'zbirenbaum/copilot.lua',
            cmd = 'Copilot',
            event = 'InsertEnter',
            config = function()
                require('copilot').setup({})
            end,
            enabled = false, -- enable this to do auth
        },

        -- folding
        {
            'kevinhwang91/nvim-ufo',
            dependencies = { 'kevinhwang91/promise-async' },
            config = function()
                vim.o.foldcolumn = '0' -- hide column by default
                vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
                vim.o.foldlevelstart = 99
                vim.o.foldenable = true

                -- Using ufo provider need remap `zR` and `zM`
                vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
                vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

                require('ufo').setup({
                    provider_selector = function()
                        return { 'treesitter', 'indent' }
                    end,
                })
            end,
            event = 'VeryLazy',
        },

        -- completion + completion sources
        -- Plug 'hrsh7th/cmp-vsnip'
        -- Plug 'hrsh7th/vim-vsnip'
        -- Plug 'L3MON4D3/LuaSnip', {'tag': 'v2.*', 'do': 'make install_jsregexp'}
        -- Plug 'saadparwaiz1/cmp_luasnip'
        {
            'hrsh7th/nvim-cmp',
            dependencies = {
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-cmdline',
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-path',
                'onsails/lspkind.nvim', -- add pictograms to completion sources
                -- 'zbirenbaum/copilot-cmp', -- include copilot suggestions in completion
            },
            enabled = true,
            config = function()
                local cmp = require('cmp')
                local cmp_autopairs = require('nvim-autopairs.completion.cmp')

                cmp.setup({
                    experimental = {
                        ghost_text = true,
                    },
                    window = {
                        completion = cmp.config.window.bordered({
                            col_offset = 20,
                            row_offset = -10, -- Adjust this value to set the number of lines above the code
                        }),
                        documentation = cmp.config.window.bordered(),
                    },
                    formatting = {
                        format = function(entry, item)
                            item =
                                require('lspkind').cmp_format()(entry, item)
                            local alias = {
                                buffer = 'bfr',
                                path = 'path',
                                calc = 'calc',
                                emoji = 'emoji',
                                nvim_lsp = 'LSP',
                                nvim_lua = 'lua',
                                nvim_lsp_signature_help = 'LSP Signature',
                                -- Copilot = '',
                            }

                            if entry.source.name == 'nvim_lsp' then
                                item.menu = entry.source.source.client.name
                            else
                                item.menu = alias[entry.source.name]
                                    or entry.source.name
                            end

                            local win_width = vim.api.nvim_win_get_width(0)
                                or 50
                            local fixed_width = math.floor(win_width * 0.5)
                            if fixed_width then
                                vim.o.pumwidth = fixed_width or 50
                            end
                            local max_content_width = fixed_width
                                    and fixed_width - 10
                                or math.floor(win_width * 0.1)
                            local content = item.abbr
                            if #content > max_content_width then
                                item.abbr = vim.fn.strcharpart(
                                    content,
                                    0,
                                    max_content_width - 3
                                ) .. '...'
                            else
                                item.abbr = content
                                    .. (' '):rep(max_content_width - #content)
                            end
                            return item
                        end,
                    },
                    mapping = cmp.mapping.preset.insert({
                        ['<C-Space>'] = cmp.mapping.complete(),
                        ['<C-e>'] = cmp.mapping.abort(),
                        ['<CR>'] = cmp.mapping.confirm({
                            behavior = cmp.ConfirmBehavior.Replace,
                            select = true,
                        }),
                        ['<Tab>'] = cmp.mapping(function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                fallback()
                            end
                        end, { 'i', 's' }),
                        ['<C-k>'] = cmp.mapping.scroll_docs(-4),
                    }),
                    preselect = cmp.PreselectMode.None,
                    sources = cmp.config.sources({
                        -- { name = 'copilot', group_index = 1 },
                        { name = 'nvim_lsp', priority = 1 },
                        { name = 'path', priority = 3 },
                        { name = 'nvim_lua', priority = 4 },
                        {
                            name = 'buffer',
                            priority = 10,
                            keyword_length = 4,
                            option = {
                                get_bufnrs = function()
                                    return vim.api.nvim_list_bufs()
                                end,
                            },
                        },
                    }),
                })

                cmp.setup.filetype('gitcommit', {
                    sources = cmp.config.sources({
                        { name = 'cmp_git' },
                    }, {
                        { name = 'buffer' },
                    }),
                })

                cmp.setup.cmdline({ '/', '?' }, {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = {
                        { name = 'buffer' },
                    },
                })

                cmp.setup.cmdline(':', {
                    mapping = cmp.mapping.preset.cmdline(),
                    sources = cmp.config.sources({
                        { name = 'cmdline', keyword_length = 2 },
                        { name = 'nvim_lua' },
                        { name = 'path' },
                    }),
                })

                cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

                -- cmp.event:on('menu_opened', function()
                --     vim.b.copilot_suggestion_hidden = true
                -- end)
                --
                -- cmp.event:on('menu_closed', function()
                --     vim.b.copilot_suggestion_hidden = false
                -- end)
            end,
        },

        {
            'saghen/blink.cmp',
            enabled = false,
            lazy = false, -- lazy loading handled internally
            -- optional: provides snippets for the snippet source
            dependencies = 'rafamadriz/friendly-snippets',

            -- use a release tag to download pre-built binaries
            version = 'v0.*',
            -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
            -- build = 'cargo build --release',

            opts = {
                highlight = {
                    -- sets the fallback highlight groups to nvim-cmp's highlight groups
                    -- useful for when your theme doesn't support blink.cmp
                    -- will be removed in a future release, assuming themes add support
                    use_nvim_cmp_as_default = true,
                },
                -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'normal',

                -- experimental auto-brackets support
                -- accept = { auto_brackets = { enabled = true } }

                -- experimental signature help support
                -- trigger = { signature_help = { enabled = true } }
            },
        },

        -- LSP
        {
            'nvimdev/lspsaga.nvim',
            enabled = true,
            event = 'VeryLazy',
            opts = {
                code_action = {
                    extend_gitsigns = true,
                    show_server_name = true,
                },
                lightbulb = {
                    enable = true,
                    enable_in_insert = false,
                    sign = false,
                },
            },
            config = function(_, opts)
                require('lspsaga').setup(opts)

                -- Function to toggle winbar
                local function toggle_winbar()
                    if vim.wo.winbar == '' then
                        -- Re-enable lspsaga winbar
                        vim.wo.winbar = nil
                        -- Force lspsaga to refresh the winbar
                        local ok, saga =
                            pcall(require, 'lspsaga.symbol.winbar')
                        if ok then
                            saga.get_bar()
                        end
                    else
                        -- Disable winbar
                        vim.wo.winbar = ''
                    end
                end

                -- Create user command
                vim.api.nvim_create_user_command(
                    'ToggleWinbar',
                    toggle_winbar,
                    {}
                )

                -- Optional: Create a keymap
                vim.keymap.set(
                    'n',
                    '<leader>tw',
                    toggle_winbar,
                    { desc = 'Toggle winbar' }
                )
            end,
        },

        -- Display LSP inlay hints at the end of the line, rather than within the line.
        {
            'chrisgrieser/nvim-lsp-endhints',
            event = 'LspAttach',
            opts = {}, -- required, even if empty
        },

        -- Auto-close quickfix based on a timer
        -- :QFC [enable|disable|toggle]
        {
            'mei28/qfc.nvim',
            config = function()
                require('qfc').setup({
                    timeout = 3000, -- Timeout setting in milliseconds
                    autoclose = true, -- Enable/disable autoclose feature
                })
            end,
            ft = 'qf', -- for lazy load
        },

        {
            'mvllow/modes.nvim',
            tag = 'v0.2.1',
            opts = {
                colors = {
                    bg = '', -- Optional bg param, defaults to Normal hl group
                    copy = '#f5c359',
                    delete = '#c75c6a',
                    insert = '#78ccc5',
                    visual = '#9745be',
                },

                -- Set opacity for cursorline and number background
                line_opacity = 0.15,

                -- Enable cursor highlights
                set_cursor = true,

                -- Enable cursorline initially, and disable cursorline for inactive windows
                -- or ignored filetypes
                set_cursorline = true,

                -- Enable line number highlights to match cursorline
                set_number = true,

                -- Disable modes highlights in specified filetypes
                -- Please PR commonly ignored filetypes
                ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
            },
        },

        -- {
        --     'Isrothy/neominimap.nvim',
        --     enabled = false,
        --     ft = { 'go', 'perl', 'typescript' },
        --     init = function()
        --         vim.opt.wrap = false -- Recommended
        --         vim.opt.sidescrolloff = 36 -- It's recommended to set a large value
        --         vim.g.neominimap = {
        --             auto_enable = true,
        --             exclude_filetypes = {
        --                 'dashboard',
        --                 'gitcommit',
        --                 'gitrebase',
        --                 'help',
        --             },
        --             exclude_buftypes = {
        --                 'nofile',
        --                 'nowrite',
        --                 'prompt',
        --                 'quickfix',
        --                 'terminal',
        --             },
        --             -- When false is returned, the minimap will not be created for this buffer
        --             buf_filter = function(bufnr)
        --                 local bufname = vim.api.nvim_buf_get_name(bufnr)
        --                 if
        --                     string.sub(bufname, 1, 4) == '/tmp'
        --                     or string.sub(bufname, 1, 8) == '/private' -- macOS
        --                 then
        --                     return false
        --                 end
        --                 return true
        --             end,
        --         }
        --     end,
        -- },
        -- neotest
        {
            'nvim-neotest/neotest',
            dependencies = {
                'nvim-neotest/neotest-go',
                'nvim-neotest/nvim-nio',
                'nvim-lua/plenary.nvim',
                'antoinemadec/FixCursorHold.nvim',
                'nvim-treesitter/nvim-treesitter',
            },
            ft = 'go',
            config = function()
                local neotest = require('neotest')
                local neotest_ns = vim.api.nvim_create_namespace('neotest')
                vim.diagnostic.config({
                    virtual_text = {
                        format = function(diagnostic)
                            local message = diagnostic.message
                                :gsub('\n', ' ')
                                :gsub('\t', ' ')
                                :gsub('%s+', ' ')
                                :gsub('^%s+', '')
                            return message
                        end,
                    },
                }, neotest_ns)

                ---@diagnostic disable-next-line:missing-fields
                neotest.setup({
                    adapters = {
                        require('neotest-go'),
                    },
                    output_panel = {
                        enabled = true,
                        open = 'vertical rightbelow 120vnew',
                    },
                    output = {
                        enabled = false,
                        open_on_run = true,
                    },
                })

                local function cmd(name, f, opts)
                    vim.api.nvim_buf_create_user_command(
                        0,
                        name,
                        f,
                        opts or {}
                    )
                end
                local function key(mode, lhs, f, opts)
                    vim.keymap.set(
                        mode,
                        lhs,
                        f,
                        vim.tbl_extend('keep', { buffer = 0 }, opts or {})
                    )
                end
                local run = function(opts)
                    return function()
                        neotest.run.run(opts)
                    end
                end
                local bufname = function(flags)
                    return vim.fn.fnameescape(
                        vim.fn.fnamemodify(
                            vim.api.nvim_buf_get_name(0),
                            flags
                        )
                    )
                end

                -- TODO: look for ways to complete test names
                cmd('GoTestNearest', run())
                cmd('GoTestRun', run(bufname(':p')))
                cmd('GoTestPkg', run(bufname(':p:h')))
                cmd('GoTestSuite', run(vim.fn.getcwd()))
                cmd('GoTestClear', neotest.output_panel.clear)
                cmd('GoTestPanel', neotest.output_panel.open)

                key('n', '<leader>tp', function()
                    neotest.output_panel.toggle()
                end)
                key('n', '<leader>ts', function()
                    neotest.summary.toggle()
                end)
            end,
        },

        -- install and manage LSP servers, linters and tidiers
        {
            'williamboman/mason.nvim',
            opts = { log_level = vim.log.levels.INFO },
        },

        {
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            opts = {

                -- a list of all tools you want to ensure are installed upon
                -- start
                ensure_installed = {
                    -- you can turn off/on auto_update per tool
                    { 'bash-language-server', auto_update = true },

                    'ansible-language-server',
                    'bash-language-server',
                    'docker-compose-language-service',
                    'editorconfig-checker',
                    'eslint-lsp',
                    -- 'json-to-struct',
                    -- 'luacheck',
                    -- 'luaformatter',
                    'lua-language-server',
                    'markdownlint',
                    -- 'misspell',
                    'perlnavigator',
                    -- 'rust_analyzer',
                    'selene',
                    'shellcheck',
                    'shfmt',
                    'sqlfluff',
                    'stylua',
                    'typescript-language-server',
                    'vim-language-server',
                    'vint',
                    'yamllint',
                    'yaml-language-server',

                    -- golang
                    'gofumpt',
                    'goimports',
                    'golangci-lint',
                    'golangci-lint-langserver',
                    'golines',
                    'gomodifytags',
                    'gopls',
                    'gotests',
                    'impl',
                    'revive',
                    'staticcheck',
                },

                -- if set to true this will check each tool for updates. If updates
                -- are available the tool will be updated. This setting does not
                -- affect :MasonToolsUpdate or :MasonToolsInstall.
                -- Default: false
                auto_update = false,

                -- automatically install / update on startup. If set to false nothing
                -- will happen on startup. You can use :MasonToolsInstall or
                -- :MasonToolsUpdate to install tools and check for updates.
                -- Default: true
                run_on_start = true,

                -- set a delay (in ms) before the installation starts. This is only
                -- effective if run_on_start is set to true.
                -- e.g.: 5000 = 5 second delay, 10000 = 10 second delay, etc...
                -- Default: 0
                start_delay = 3000, -- 3 second delay

                -- Only attempt to install if 'debounce_hours' number of hours has
                -- elapsed since the last time Neovim was started. This stores a
                -- timestamp in a file named stdpath('data')/mason-tool-installer-debounce.
                -- This is only relevant when you are using 'run_on_start'. It has no
                -- effect when running manually via ':MasonToolsInstall' etc....
                -- Default: nil
                -- debounce_hours = 5, -- at least 5 hours between attempts to install/update

                -- Disable integration with other Mason plugins. This removes
                -- the ability to to use the alternative names of packages provided
                -- by these plugins but disables them from immediately becoming loaded
                integrations = {
                    ['mason-null-ls'] = true,
                    ['mason-nvim-dap'] = true,
                },
            },
        },

        {
            'akinsho/toggleterm.nvim',
            version = '*',
            config = true,
        },
        {
            'nvchad/showkeys',
            cmd = 'ShowkeysToggle',
            enabled = false,
        },
        {
            'mcauley-penney/visual-whitespace.nvim',
            config = true,
            -- keys = { 'v', 'V', '<C-v>' }, -- optionally, lazy load on visual mode keys
        },
        {
            'echasnovski/mini.trailspace',
            version = false,
            ft = {
                'go',
                'markdown',
                'perl',
                'typescript',
            },
        },

        {
            'ravitemer/mcphub.nvim',
            dependencies = {
                'nvim-lua/plenary.nvim',
            },
            config = function()
                require('mcphub').setup({
                    -- GitHub MCP Server configuration
                    servers = {
                        github = {
                            name = 'github',
                            description = 'GitHub API integration for code reviews and repository management',
                            command = 'podman',
                            args = {
                                'run',
                                '-i',
                                '--rm',
                                '-e',
                                'GITHUB_TOKEN',
                                'ghcr.io/github/github-mcp-server',
                            },
                            env = {
                                GITHUB_TOKEN = vim.fn.getenv(
                                    'GH_ENTERPRISE_TOKEN'
                                ) or '',
                                -- For GitHub Enterprise, uncomment and set your host:
                                -- GITHUB_HOST = "github.your-company.com",
                                GITHUB_TOOLSETS = 'repos,issues,pull_requests,code_security',
                            },
                            -- Specific toolsets for code review workflows
                            toolsets = {
                                'pull_requests', -- Essential for PR reviews
                                'repos', -- Repository operations
                                'code_security', -- Security scanning alerts
                                'issues', -- Issue management
                            },
                        },
                    },
                    -- Auto-start the GitHub MCP server when needed
                    auto_start = true,
                    -- Log level for debugging
                    log_level = 'info',
                })
            end,
        },

        -- {
        --     'tris203/precognition.nvim',
        --     event = 'VeryLazy',
        --     config = {
        --         startVisible = false,
        --         showBlankVirtLine = true,
        --         highlightColor = { link = 'Comment' },
        --         hints = {
        --             Caret = { text = '^', prio = 2 },
        --             Dollar = { text = '$', prio = 1 },
        --             MatchingPair = { text = '%', prio = 5 },
        --             Zero = { text = '0', prio = 1 },
        --             w = { text = 'w', prio = 10 },
        --             b = { text = 'b', prio = 9 },
        --             e = { text = 'e', prio = 8 },
        --             W = { text = 'W', prio = 7 },
        --             B = { text = 'B', prio = 6 },
        --             E = { text = 'E', prio = 5 },
        --         },
        --         gutterHints = {
        --             G = { text = 'G', prio = 10 },
        --             gg = { text = 'gg', prio = 9 },
        --             PrevParagraph = { text = '{', prio = 8 },
        --             NextParagraph = { text = '}', prio = 8 },
        --         },
        --     },
        -- },

        'tpope/vim-sensible', -- Defaults everyone can agree on
    },
})
