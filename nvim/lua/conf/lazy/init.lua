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
    'cocopon/iceberg.vim',

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

    'ap/vim-css-color', -- show css colors inline
    'bkad/CamelCaseMotion', -- provide CamelCase motion through words
    'gregsexton/MatchTag', -- highlight matchihng HTML tags
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

    'kburdett/vim-nuuid', -- <leader>u to insert a new UUID
    'luochen1990/rainbow', -- Rainbow Parentheses Improved
    'mannih/vim-perl-variable-highlighter', -- highlight other instances of selected var
    'motemen/xslate-vim', -- https://metacpan.org/pod/Text::Xslate
    'mzlogin/vim-markdown-toc', -- :GenTocGFM to generate table of contents
    'ntpeters/vim-better-whitespace', -- highlight trailing whitespace
    -- 'oalders/prettysql' -- ,fs to format visually selected SQL
    -- 'oalders/vim-perl', { 'branch': 'dev   ', 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' },
    'othree/html5.vim',
    'rhysd/git-messenger.vim', -- ,gm to open window
    'rodjek/vim-puppet', -- { 'for': 'puppet' }, -- Formatting, syntax highlighting etc
    'rust-lang/rust.vim',
    'preservim/nerdcommenter',
    'tpope/vim-abolish',

    -- :Delete :SudoWrite
    'tpope/vim-eunuch',

    'tpope/vim-fugitive',
    'vim-ruby/vim-ruby', -- Vim/Ruby configuration files
    'yko/mojo.vim', -- syntax highlighting for mojo epl templates
    'ahmedkhalf/project.nvim', -- auto-detect project root
    'akinsho/bufferline.nvim', -- display tabs for open buffers
    'darfink/vim-plist', -- read macOS plist files
    'ellisonleao/glow.nvim', -- render markdown via :Glow
    'folke/trouble.nvim', --  <leader>td (doc) <leader>tw (workspace)
    'folke/which-key.nvim', -- better organization of keybindings
    'Hubro/nvim-splitrun', -- :Splitrun some command
    'ibhagwan/fzf-lua', --  replace fzf.vim
    'kevinhwang91/nvim-bqf', -- improve quickfix window
    'kyazdani42/nvim-web-devicons', -- recommended for bufferlin.nvim (coloured icons)
    'lewis6991/gitsigns.nvim', -- git signs in the gutter
    'mfussenegger/nvim-lint', -- linter harness
    'nvim-lualine/lualine.nvim', -- status line
    'nvim-lua/plenary.nvim', -- required by other plugins
    { 'nvim-telescope/telescope.nvim', tag = '0.1.5' }, -- fuzzy finder
    'nvimtools/none-ls.nvim', -- null-ls replacement
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' }, -- recommend updating parsers on update
    'olimorris/persisted.nvim', -- session management
    'ptdewey/yankbank-nvim', -- easy access to yanks and deletes
    'rgroli/other.nvim', -- :Other to toggle between test and implementation files
    'windwp/nvim-autopairs', --

    -- display lines for indentation
    -- <leader>ll (start) leader<lh> (stop)
    {
        'shellRaining/hlchunk.nvim',
        event = { 'UIEnter' },
        config = function()
            require('hlchunk').setup({})
        end,
    },

    'sindrets/diffview.nvim', -- File explorer for git diffs
    'Wansmer/treesj', -- SplitJoin replacement
    'windwp/nvim-autopairs', --
    'zbirenbaum/copilot.lua', -- GitHub Copilot

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
    'kevinhwang91/promise-async',
    'kevinhwang91/nvim-ufo',

    -- nvim-cmp -- completion + completion sources
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'hrsh7th/nvim-cmp',
    'zbirenbaum/copilot-cmp', -- include copilot suggestions in completion
    -- Plug 'hrsh7th/cmp-vsnip'
    -- Plug 'hrsh7th/vim-vsnip'
    -- Plug 'L3MON4D3/LuaSnip', {'tag': 'v2.*', 'do': 'make install_jsregexp'}
    -- Plug 'saadparwaiz1/cmp_luasnip'

    -- LSP
    'lvimuser/lsp-inlayhints.nvim', -- Partial implementation of LSP inlay hints
    'neovim/nvim-lspconfig',
    'nvimdev/lspsaga.nvim',

    -- neotest
    'nvim-neotest/neotest',
    'nvim-neotest/neotest-go',
    'nvim-neotest/nvim-nio',

    'onsails/lspkind.nvim', -- add pictograms to completion sources
    'williamboman/mason-lspconfig.nvim', --  bridge mason.nvim with the lspconfig plugin
    'williamboman/mason.nvim', -- install and manage LSP servers, linters and tidiers

    -- noice
    'folke/noice.nvim',
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',

    'tpope/vim-sensible', -- Defaults everyone can agree on
})
