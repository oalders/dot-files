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
            'nvimdev/dashboard-nvim',
            event = 'VimEnter',
            config = function()
                require('dashboard').setup({
                    theme = 'hyper',
                    config = {
                        week_header = {
                            enable = true,
                        },
                        shortcut = {
                            {
                                icon = '🚀 ',
                                desc = ' Last Session',
                                group = '@property',
                                action = ':LastSession',
                                key = 'l',
                            },
                            {
                                icon = '♻️',
                                desc = ' Update',
                                group = '@property',
                                action = 'Lazy update',
                                key = 'u',
                            },
                            {
                                icon = '📂',
                                desc = 'Git Changed Files',
                                group = 'Label',
                                action = ':GDomo',
                                key = 'g',
                            },
                            {
                                icon = '🤖',
                                desc = 'Chat',
                                group = 'Number',
                                action = ':CopilotChatOpen',
                                key = 'c',
                            },
                        },
                    },
                })
            end,
            dependencies = { { 'nvim-tree/nvim-web-devicons' } },
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
            event = 'VeryLazy',
        },
        'ntpeters/vim-better-whitespace', -- highlight trailing whitespace
        -- 'oalders/prettysql' -- ,fs to format visually selected SQL
        { 'othree/html5.vim', ft = 'html', event = 'VeryLazy' },
        -- 'rodjek/vim-puppet', -- { 'for': 'puppet' }, -- Formatting, syntax highlighting etc
        {
            'rust-lang/rust.vim',
            ft = 'rust',
            event = 'VeryLazy',
        },
        'tpope/vim-abolish',

        -- :Delete :SudoWrite
        'tpope/vim-eunuch',

        {
            'vim-ruby/vim-ruby', -- Vim/Ruby configuration files
            ft = 'ruby',
        },

        { 'yko/mojo.vim', ft = 'html.epl', lazy = true }, -- syntax highlighting for mojo epl templates

        -- {
        --     'ahmedkhalf/project.nvim',
        --     ft = 'typescript',
        -- }, -- auto-detect project root
        {
            'akinsho/bufferline.nvim',
            version = '*',
            dependencies = 'nvim-tree/nvim-web-devicons',
        },
        {
            'ellisonleao/glow.nvim',
            event = 'VeryLazy',
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
            end,
            filetype = {
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
        { 'nvimtools/none-ls.nvim', event = 'VeryLazy' }, -- null-ls replacement
        { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' }, -- recommend updating parsers on update
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
                    max_entries = 20,
                    persist_type = 'sqlite',
                    sep = '〰️〰️〰️〰️〰️〰️〰️〰️',
                })
            end,
            event = 'VeryLazy',
        },
        'rgroli/other.nvim', -- :Other to toggle between test and implementation files
        'windwp/nvim-autopairs', --

        -- display lines for indentation
        -- <leader>ll (start) leader<lh> (stop)
        { 'shellRaining/hlchunk.nvim' },

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
            branch = 'canary',
            dependencies = {
                { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
                { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
                { 'https://github.com/gptlang/lua-tiktoken' },
            },
            opts = {
                auto_follow_cursor = false,
                debug = false, -- Enable debugging
                context = 'buffers',
                -- See Configuration section for rest
            },
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
                    provider_selector = function(bufnr, filetype, buftype)
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
                'zbirenbaum/copilot-cmp', -- include copilot suggestions in completion
            },
            enabled = true,
            config = function()
                local cmp = require('cmp')
                local cmp_autopairs = require('nvim-autopairs.completion.cmp')

                cmp.setup({
                    experimental = {
                        ghost_text = true,
                    },
                    formatting = {
                        format = function(entry, item)
                            item =
                                require('lspkind').cmp_format()(entry, item)
                            local alias = {
                                buffer = 'buffer',
                                path = 'path',
                                calc = 'calc',
                                emoji = 'emoji',
                                nvim_lsp = 'LSP',
                                nvim_lua = 'lua',
                                nvim_lsp_signature_help = 'LSP Signature',
                                Copilot = '',
                            }

                            if entry.source.name == 'nvim_lsp' then
                                item.menu = entry.source.source.client.name
                            else
                                item.menu = alias[entry.source.name]
                                    or entry.source.name
                            end

                            local fixed_width = false
                            if fixed_width then
                                vim.o.pumwidth = fixed_width
                            end
                            local win_width = vim.api.nvim_win_get_width(0)
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
                        { name = 'copilot', group_index = 1 },
                        { name = 'nvim_lsp', priority = 2 },
                        { name = 'path', priority = 3 },
                        {
                            name = 'buffer',
                            priority = 4,
                            keyword_length = 4,
                            option = {
                                get_bufnrs = function()
                                    return vim.api.nvim_list_bufs()
                                end,
                            },
                        },
                        { name = 'nvim_lua', priority = 5 },
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

                cmp.event:on('menu_opened', function()
                    vim.b.copilot_suggestion_hidden = true
                end)

                cmp.event:on('menu_closed', function()
                    vim.b.copilot_suggestion_hidden = false
                end)
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
        'neovim/nvim-lspconfig',
        {
            'nvimdev/lspsaga.nvim',
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

        {
            'Isrothy/neominimap.nvim',
            enabled = true,
            lazy = false, -- WARN: NO NEED to Lazy load
            filetype = { 'go', 'perl', 'typescript' },
            init = function()
                vim.opt.wrap = false -- Recommended
                vim.opt.sidescrolloff = 36 -- It's recommended to set a large value
                vim.g.neominimap = {
                    auto_enable = true,
                    exclude_filetypes = {
                        'dashboard',
                        'gitcommit',
                        'gitrebase',
                        'help',
                    },
                    exclude_buftypes = {
                        'nofile',
                        'nowrite',
                        'prompt',
                        'quickfix',
                        'terminal',
                    },
                    -- When false is returned, the minimap will not be created for this buffer
                    buf_filter = function(bufnr)
                        local bufname = vim.api.nvim_buf_get_name(bufnr)
                        if
                            string.sub(bufname, 1, 4) == '/tmp'
                            or string.sub(bufname, 1, 8) == '/private' -- macOS
                        then
                            return false
                        end
                        return true
                    end,
                }
            end,
        },

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
        },

        --  bridge mason.nvim with the lspconfig plugin
        { 'williamboman/mason-lspconfig.nvim', opts = {} },

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

                    'ansiblels',
                    'bashls',
                    'docker_compose_language_service',
                    'editorconfig-checker',
                    'eslint',
                    -- 'json-to-struct',
                    -- 'luacheck',
                    -- 'luaformatter',
                    'lua-language-server',
                    -- 'misspell',
                    'perlnavigator',
                    -- 'rust_analyzer',
                    'selene',
                    'shellcheck',
                    'shfmt',
                    'sqlfluff',
                    'stylua',
                    'ts_ls',
                    'vim-language-server',
                    'vint',
                    'yamllint',
                    'yamlls',

                    -- golang
                    -- 'gofumpt',
                    'golangci-lint',
                    -- 'golangci_lint_ls',
                    -- 'golines',
                    -- 'gomodifytags',
                    -- 'gopls',
                    -- 'gotests',
                    -- 'impl',
                    -- 'revive',
                    -- 'staticcheck',
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
                    ['mason-lspconfig'] = true,
                    ['mason-null-ls'] = true,
                    ['mason-nvim-dap'] = true,
                },
            },
        },

        -- noice
        {
            'folke/noice.nvim',
            event = 'VeryLazy',
            opts = {
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                        ['vim.lsp.util.stylize_markdown'] = true,
                        ['cmp.entry.get_documentation'] = true,
                    },
                    progress = {
                        enabled = true,
                        format = 'lsp_progress',
                        format_done = 'lsp_progress_done',
                        view = 'mini',
                    },
                },
                messages = {
                    enabled = false,
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = false, -- use a classic bottom cmdline for search
                    command_palette = true, -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false, -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = true, -- add a border to hover docs and signature help
                },
            },
            dependencies = {
                -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
                'MunifTanjim/nui.nvim',
                -- OPTIONAL:
                --   `nvim-notify` is only needed, if you want to use the notification view.
                --   If not available, we use `mini` as the fallback
                'rcarriga/nvim-notify',
            },
        },
        { 'akinsho/toggleterm.nvim', version = '*', config = true },

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
