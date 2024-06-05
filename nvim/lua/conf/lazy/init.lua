local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
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
                            icon = '🚀',
                            desc = 'SessionLoad',
                            group = 'DiagnosticHint',
                            action = ':SessionLoad',
                            key = 's',
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
    'lewis6991/gitsigns.nvim', -- git signs in the gutter
    'rhysd/git-messenger.vim', -- ,gm to open window
    'sindrets/diffview.nvim', -- File explorer for git diffs
    'tpope/vim-fugitive', --  :GRemove, :Git diff, etc

    'ap/vim-css-color', -- show css colors inline
    'bkad/CamelCaseMotion', -- provide CamelCase motion through words
    'gregsexton/MatchTag', -- highlight matching HTML tags
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
    'ntpeters/vim-better-whitespace', -- highlight trailing whitespace
    -- 'oalders/prettysql' -- ,fs to format visually selected SQL
    { 'othree/html5.vim', ft = 'html' },
    'rodjek/vim-puppet', -- { 'for': 'puppet' }, -- Formatting, syntax highlighting etc
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

    { 'yko/mojo.vim', ft = 'html.epl', lazy = true }, -- syntax highlighting for mojo epl templates

    'ahmedkhalf/project.nvim', -- auto-detect project root
    {
        'akinsho/bufferline.nvim',
        version = '*',
        dependencies = 'nvim-tree/nvim-web-devicons',
    },
    { 'ellisonleao/glow.nvim', ft = 'markdown', config = true, cmd = 'Glow' }, -- render markdown via :Glow

    --  <leader>td (doc) <leader>tw (workspace)
    {
        'folke/trouble.nvim',
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = 'Trouble',
        keys = {
            {
                '<leader>td',
                '<cmd>Trouble diagnostics toggle<cr>',
                desc = 'Diagnostics (Trouble)',
            },
            {
                '<leader>xX',
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
    'Hubro/nvim-splitrun', -- :Splitrun some command

    --  replace fzf.vim
    {
        'ibhagwan/fzf-lua',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },

    { 'kevinhwang91/nvim-bqf', ft = 'qf' }, -- add previews to quickfix window
    'mfussenegger/nvim-lint', -- linter harness
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    { 'nvim-telescope/telescope.nvim', tag = '0.1.5' }, -- fuzzy finder
    'nvimtools/none-ls.nvim', -- null-ls replacement
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' }, -- recommend updating parsers on update
    'olimorris/persisted.nvim', -- session management
    'ptdewey/yankbank-nvim', -- easy access to yanks and deletes
    'rgroli/other.nvim', -- :Other to toggle between test and implementation files
    'windwp/nvim-autopairs', --

    -- display lines for indentation
    -- <leader>ll (start) leader<lh> (stop)
    'shellRaining/hlchunk.nvim',

    {
        'Wansmer/treesj',
        opts = { use_default_keymaps = false, max_join_length = 150 },
    },
    'windwp/nvim-autopairs', --

    {
        'CopilotC-Nvim/CopilotChat.nvim',
        branch = 'canary',
        dependencies = {
            { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
            { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
        },
        opts = {
            debug = true, -- Enable debugging
            -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
    },

    -- folding
    {
        'kevinhwang91/nvim-ufo',
        dependencies = { 'kevinhwang91/promise-async' },
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
    },

    -- LSP
    'lvimuser/lsp-inlayhints.nvim', -- Partial implementation of LSP inlay hints
    'neovim/nvim-lspconfig',
    'nvimdev/lspsaga.nvim',

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

    'williamboman/mason-lspconfig.nvim', --  bridge mason.nvim with the lspconfig plugin
    'williamboman/mason.nvim', -- install and manage LSP servers, linters and tidiers
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- noice
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {},
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            'MunifTanjim/nui.nvim',
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            'rcarriga/nvim-notify',
        },
    },

    'tpope/vim-sensible', -- Defaults everyone can agree on
})
