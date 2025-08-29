---@diagnostic disable: undefined-global
-- vim.lsp.set_log_level("debug")

-- reduce left-right jitter when signcolumn appears and disappears while
-- scrolling vertically.
vim.opt.signcolumn = 'yes'

-- Configure global defaults using vim.lsp.config
vim.lsp.config('*', {
    root_markers = { '.git' },
})

-- Configure individual LSP servers using vim.lsp.config

-- Ansible Language Server
vim.lsp.config('ansiblels', {
    cmd = { 'ansible-language-server', '--stdio' },
    filetypes = { 'yaml.ansible' },
})

-- Bash Language Server
vim.lsp.config('bashls', {
    cmd = { 'bash-language-server', 'start' },
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

-- Docker Compose Language Service
vim.lsp.config('docker_compose_language_service', {
    cmd = { 'docker-compose-langserver', '--stdio' },
    filetypes = { 'yaml.docker-compose' },
    root_markers = {
        'docker-compose.yaml',
        'docker-compose.yml',
        'compose.yaml',
        'compose.yml',
    },
})

-- ESLint Language Server
vim.lsp.config('eslint', {
    cmd = { 'vscode-eslint-language-server', '--stdio' },
    filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'vue',
        'svelte',
    },
    root_markers = {
        '.eslintrc',
        '.eslintrc.js',
        '.eslintrc.json',
        'eslint.config.js',
    },
    settings = {
        codeAction = {
            disableRuleComment = {
                enable = true,
                location = 'separateLine',
            },
            showDocumentation = {
                enable = true,
            },
        },
        codeActionOnSave = {
            enable = false,
            mode = 'all',
        },
        format = true,
        nodePath = '',
        onIgnoredFiles = 'off',
        packageManager = 'npm',
        quiet = false,
        rulesCustomizations = {},
        run = 'onType',
        useESLintClass = false,
        validate = 'on',
        workingDirectory = {
            mode = 'location',
        },
    },
})

-- Lua Language Server
vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc' },
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

-- TypeScript Language Server
vim.lsp.config('ts_ls', {
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
    },
    root_markers = { 'tsconfig.json', 'package.json', 'jsconfig.json' },
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

-- YAML Language Server
vim.lsp.config('yamlls', {
    cmd = { 'yaml-language-server', '--stdio' },
    filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
    root_markers = { '.yamllint', '.yamllint.yml', '.yamllint.yaml' },
})

-- Go Language Server
vim.lsp.config('gopls', {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = { 'go.work', 'go.mod' },
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
            -- Reduce diagnostics frequency
            diagnosticsDelay = '2s',
        },
    },
    flags = {
        -- Increase debounce time to 5 seconds (5000ms)
        debounce_text_changes = 5000,
    },
})

-- Perl Navigator
vim.lsp.config('perlnavigator', {
    cmd = { 'perlnavigator', '--stdio' },
    filetypes = { 'perl' },
    root_markers = {
        'Makefile.PL',
        'Build.PL',
        'cpanfile',
        'META.json',
        'META.yml',
    },
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

-- Rust Analyzer
vim.lsp.config('rust_analyzer', {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'rust-project.json' },
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

-- Python LSP Server
vim.lsp.config('pylsp', {
    cmd = { 'pylsp' },
    filetypes = { 'python' },
    root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
    },
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

-- Enable the servers
vim.lsp.enable({
    'ansiblels',
    'bashls',
    'docker_compose_language_service',
    -- 'eslint',
    'lua_ls',
    'ts_ls',
    'yamlls',
    'gopls',
    'perlnavigator',
    'rust_analyzer',
    'pylsp',
})

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
        ---@type table?
        local client = vim.lsp.get_client_by_id(client_id)

        if not client then
            return
        end

        -- vim.notify((client.name or 'unknown') .. ' (attached)', vim.log.levels.INFO)
        if
            client.server_capabilities
            and client.server_capabilities.inlayHintProvider
            and client.name
            and not vim.tbl_contains(no_inlay_hints, client.name)
        then
            vim.notify(
                client.name .. ' (inlay hints enabled)',
                vim.log.levels.INFO
            )
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[args.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Enable auto-formatting on save for ESLint
        if client.name == 'eslint' then
            vim.api.nvim_create_autocmd('BufWritePre', {
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.code_action({
                        context = { only = { 'source.fixAll.eslint' } },
                        apply = true,
                    })
                end,
            })
        end

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
