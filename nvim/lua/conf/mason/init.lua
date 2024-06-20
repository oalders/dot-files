require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({

    -- a list of all tools you want to ensure are installed upon
    -- start
    ensure_installed = {
        -- you can turn off/on auto_update per tool
        { 'bash-language-server', auto_update = true },

        'ansiblels',
        'bashls',
        'docker_compose_language_service',
        -- 'editorconfig-checker',
        'eslint',
        -- 'json-to-struct',
        -- 'luacheck',
        -- 'luaformatter',
        -- 'lua-language-server',
        -- 'misspell',
        'perlnavigator',
        -- 'rust_analyzer',
        'selene',
        'shellcheck',
        'shfmt',
        'sqlfluff',
        'stylua',
        'tsserver',
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
    debounce_hours = 5, -- at least 5 hours between attempts to install/update

    -- Disable integration with other Mason plugins. This removes
    -- the ability to to use the alternative names of packages provided
    -- by these plugins but disables them from immediately becoming loaded
    integrations = {
        ['mason-lspconfig'] = true,
        ['mason-null-ls'] = true,
        ['mason-nvim-dap'] = true,
    },
})
