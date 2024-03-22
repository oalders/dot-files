local lspconfig = require 'lspconfig'
lspconfig.bashls.setup { filetypes = { "sh" } }
lspconfig.docker_compose_language_service.setup {}
lspconfig.eslint.setup({
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
})
-- lspconfig.lua_ls.setup {
    -- settings = {
        -- Lua = {
            -- runtime = {
                -- -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                -- version = 'LuaJIT',
            -- },
            -- diagnostics = {
                -- -- Get the language server to recognize the `vim` global
                -- globals = { 'hs', 'vim' },
            -- },
            -- workspace = {
                -- checkThirdParty = false,
                -- -- Make the server aware of Neovim runtime files
                -- library = vim.api.nvim_get_runtime_file("", true),
            -- },
            -- -- Do not send telemetry data containing a randomized but unique identifier
            -- telemetry = {
                -- enable = false,
            -- },
        -- },
    -- },
-- }
lspconfig.tsserver.setup {}
lspconfig.yamlls.setup {}

-- Set up lspconfig.
-- Mappings.
vim.api.nvim_create_augroup("LspAttach_inlayhints", {})
vim.api.nvim_create_autocmd("LspAttach", {
    group = "LspAttach_inlayhints",
    callback = function(args)
        if not (args.data and args.data.client_id) then
            return
        end

        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        require("lsp-inlayhints").on_attach(client, bufnr)
    end,
})

-- copied from https://github.com/neovim/nvim-lspconfig
-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<space>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format { async = true }
        end, opts)
    end,
})
-- end copied from https://github.com/neovim/nvim-lspconfig

lspconfig.gopls.setup({
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
            -- root_dir = root_pattern("go.mod", ".git"),
        },
    },
})

-- After setting up mason-lspconfig you may set up servers via lspconfig
-- See server/src/server.ts in PerlNavigator for a list of available settings
lspconfig.perlnavigator.setup {
    settings = {
        perlnavigator = {
            -- perltidyProfile = '',
            -- perlcriticProfile = '',
            enableWarnings = true,
            perlimportsProfile = 'perlimports.toml',
            includePaths = { 'lib', 'dev/lib', 't/lib' },
            perlcriticEnabled = true,
            perlimportsLintEnabled = true,
            perlimportsTidyEnabled = true,
            perlPath = 'perl',
        }
    },
    on_new_config = function(new_config, new_root)
        local f = new_root .. '/.teamcity/pom.xml'
        local pn = new_config.settings.perlnavigator
        if vim.fn.filereadable(f) == 1 then
            pn.perlPath = 'mm-perl'
            pn.perlcriticProfile = table.concat({ new_root, '.perlcriticrc' }, '/')
            pn.perltidyProfile = table.concat({ new_root, '.perltidyallrc' }, '/')
            pn.perlnavigator.perlimportsProfile = table.concat({ new_root, '.perlimports.toml' }, '/')
        end
    end,
}

lspconfig.rust_analyzer.setup({
    settings = {
        ["rust-analyzer"] = {
            imports = {
                granularity = {
                    group = "module",
                },
                prefix = "self",
            },
            cargo = {
                buildScripts = {
                    enable = true,
                },
            },
            procMacro = {
                enable = true
            },
        }
    }
})

lspconfig.pylsp.setup {
    settings = {
        pylsp = {
            plugins = {
                pycodestyle = {
                    ignore = { 'W391' },
                    maxLineLength = 100
                }
            }
        }
    }
}

-- begin
-- https://github.com/neovim/neovim/issues/20745#issuecomment-1983998972
local function filter_diagnostics(diagnostic)
  if diagnostic.source == 'tsserver' then
    return false
  end
  return true
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  function(_, result, ctx, config)
    result.diagnostics = vim.tbl_filter(filter_diagnostics, result.diagnostics)
    vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
  end,
  {}
)
-- end
