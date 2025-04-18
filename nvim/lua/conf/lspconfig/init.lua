-- vim.lsp.set_log_level("debug")

-- reduce left-right jitter when signcolumn appears and disappears while
-- scrolling vertically.
vim.opt.signcolumn = 'yes'

local lspconfig = require('lspconfig')
lspconfig.ansiblels.setup({})
lspconfig.bashls.setup({
    filetypes = { 'sh' },
    settings = {
        diagnostics = {
            enable = true,
            shellcheck = {
                enable = true,
                executable = 'shellcheck',
                extraArgs = { '-x' },
            },
        },
    },
})
lspconfig.docker_compose_language_service.setup({})
lspconfig.eslint.setup({
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            command = 'EslintFixAll',
        })
    end,
})

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#lua_ls
lspconfig.lua_ls.setup({
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { 'hs', 'vim' },
            },
            workspace = {
                checkThirdParty = false,
                -- Make the server aware of Neovim runtime files
                library = {
                    vim.env.VIMRUNTIME,
                    -- Depending on the usage, you might want to add additional paths here.
                    -- "${3rd}/luv/library",
                    -- "${3rd}/busted/library",
                },
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
})
lspconfig.ts_ls.setup({
    settings = {
        typescript = {
            inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,

                -- enabling this makes Playwright test() almost unreadable
                -- includeInlayFunctionParameterTypeHints = true,
            },
        },
        javascript = {
            inlayHints = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
            },
        },
    },
})
lspconfig.yamlls.setup({})

-- Set up lspconfig.
-- Mappings.

-- copied from https://github.com/neovim/nvim-lspconfig
-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

local no_inlay_hints = { '' }

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(args)
        local bufnr = args.buf
        local client_id = args.data.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        -- vim.notify(client.name .. ' (attached)', vim.log.levels.INFO)
        if
            client.server_capabilities.inlayHintProvider
            and not vim.tbl_contains(no_inlay_hints, client.name)
        then
            vim.notify(
                client.name .. ' (inlay hints enabled)',
                vim.log.levels.INFO
            )
            vim.lsp.inlay_hint.enable(true)
        end
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[args.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = args.buf }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set(
            'n',
            '<space>wa',
            vim.lsp.buf.add_workspace_folder,
            opts
        )
        vim.keymap.set(
            'n',
            '<space>wr',
            vim.lsp.buf.remove_workspace_folder,
            opts
        )
        vim.keymap.set('n', '<space>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set(
            { 'n', 'v' },
            '<space>ca',
            vim.lsp.buf.code_action,
            opts
        )
        vim.keymap.set('n', 'gr', '<cmd>FzfLua lsp_references<CR>', opts)
        vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format({ async = true })
        end, opts)
    end,
})
-- end copied from https://github.com/neovim/nvim-lspconfig

lspconfig.gopls.setup({
    settings = {
        gopls = {
            analyses = {
                shadow = true,
                useany = true,
                unusedparams = true,
                unusedvariable = true,
            },
            staticcheck = true,
            gofumpt = true,
            usePlaceholders = true,
            hints = { functionTypeParameters = true },
            -- root_dir = root_pattern("go.mod", ".git"),
        },
    },
    flags = {
        debounce_text_changes = 3000,
    },
    -- on_attach = function(client, bufnr)
    --     print(vim.inspect(client.server_capabilities))
    -- end,
})

-- After setting up mason-lspconfig you may set up servers via lspconfig
-- See server/src/server.ts in PerlNavigator for a list of available settings
lspconfig.perlnavigator.setup({
    settings = {
        perlnavigator = {
            -- perltidyProfile = '',
            -- perlcriticProfile = '',
            enableWarnings = true,
            includePaths = { 'lib', 'dev/lib', 't/lib' },
            logging = false,
            perlcriticEnabled = true,
            perlimportsLintEnabled = true,
            perlimportsTidyEnabled = true,
            perlPath = 'perl',
        },
    },
    on_new_config = function(new_config, new_root)
        local f = new_root .. '/.teamcity/pom.xml'
        local nav = new_config.settings.perlnavigator
        if vim.fn.filereadable(f) == 1 then
            nav.perlPath = 'mm-perl'
            nav.perlcriticProfile =
                table.concat({ new_root, '.perlcriticrc' }, '/')
            nav.perltidyProfile =
                table.concat({ new_root, '.perltidyallrc' }, '/')
        end
    end,
})

lspconfig.rust_analyzer.setup({
    settings = {
        ['rust-analyzer'] = {
            imports = {
                granularity = {
                    group = 'module',
                },
                prefix = 'self',
            },
            cargo = {
                buildScripts = {
                    enable = true,
                },
            },
            procMacro = {
                enable = true,
            },
        },
    },
})

lspconfig.pylsp.setup({
    settings = {
        pylsp = {
            plugins = {
                pycodestyle = {
                    ignore = { 'W391' },
                    maxLineLength = 100,
                },
            },
        },
    },
})

-- begin
-- https://github.com/neovim/neovim/issues/20745#issuecomment-1983998972
-- local function filter_diagnostics(diagnostic)
--     if diagnostic.source == 'tsserver' then
--         return false
--     end
--     return true
-- end
--
-- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
--     function(_, result, ctx, config)
--         result.diagnostics =
--             vim.tbl_filter(filter_diagnostics, result.diagnostics)
--         vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
--     end,
--     {}
-- )
-- end
