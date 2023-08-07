-- if vim.fn.has 'nvim-0.9.0' == 1 then
--  vim.loader.enable()
-- end

require 'nvim-treesitter.configs'.setup {
    ensure_installed = { 'bash', 'dockerfile', 'go', 'html', 'javascript', 'lua', 'markdown', 'markdown_inline',
        'python', 'regex', 'ruby', 'rust', 'sql', 'typescript', 'vim', 'yaml' },
    -- ensure_installed = 'all',
    highlight = {
        enable = true, -- false will disable the whole extension
        disable = {},  -- list of language that will be disabled
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },
}

local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.perl = {
    install_info = {
        url = 'https://github.com/tree-sitter-perl/tree-sitter-perl',
        revision = 'release',
        files = { 'src/parser.c', 'src/scanner.c' },
    },
    maintainers = { '@leonerd' },
    filetype = 'perl',
}

vim.opt.termguicolors = true
vim.opt.mouse = "v"
require('bufferline').setup {}

-- require('virt-column').setup()

local cmp = require 'cmp'

---@diagnostic disable-next-line:redundant-parameter
cmp.setup({
    experimental = {
        ghost_text = true,
    },
    formatting = {
        format = function(entry, vim_item)
            vim_item = require('lspkind').cmp_format()(entry, vim_item)
            local alias = {
                buffer = 'buffer',
                path = 'path',
                calc = 'calc',
                emoji = 'emoji',
                nvim_lsp = 'LSP',
                luasnip = 'luasnip',
                vsnip = 'vsnip',
                nvim_lua = 'lua',
                nvim_lsp_signature_help = 'LSP Signature',
            }

            if entry.source.name == 'nvim_lsp' then
                vim_item.menu = entry.source.source.client.name
            else
                vim_item.menu = alias[entry.source.name] or entry.source.name
            end
            return vim_item
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
                -- elseif luasnip.expand_or_jumpable() then
                -- luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    preselect = cmp.PreselectMode.None,
    view = {
        -- entries = 'native',
    },
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },
    sources = cmp.config.sources({
        { name = 'buffer',   priority = 7, keyword_length = 4 },
        { name = 'emoji',    priority = 3 },
        { name = 'path',     priority = 5 },
        { name = 'calc',     priority = 4 },
        { name = 'nvim_lua', priority = 9 },
        { name = 'nvim_lsp', priority = 9 },
        { name = 'luasnip',  priority = 8 },
    }),
    window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
    },
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
    }, {
        { name = 'buffer' },
    })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources {
        { name = 'cmdline', keyword_length = 2 },
        { name = 'nvim_lua' },
        { name = 'path' },
    },
})

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


local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = {
        "bashls",
        "docker_compose_language_service",
        "lua_ls",
        "perlnavigator",
        "rust_analyzer",
        "tsserver",
        "yamlls",
    }
}

require("lsp-format").setup {}

require 'lspconfig'.bashls.setup {}
require 'lspconfig'.docker_compose_language_service.setup {}
require 'lspconfig'.lua_ls.setup {
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
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
}
require 'lspconfig'.yamlls.setup {}

local navbuddy = require("nvim-navbuddy")
navbuddy.setup {
    lsp = {
        auto_attach = true,
        preference = nil,
    },
}

-- After setting up mason-lspconfig you may set up servers via lspconfig
-- See server/src/server.ts in PerlNavigator for a list of available settings
require("lspconfig").perlnavigator.setup {
    -- capabilities = capabilities,
    settings = {
        perlnavigator = {
            enableWarnings = true,
            -- perltidyProfile = '',
            -- perlcriticProfile = '',
            includePaths = { 'lib', 'dev/lib', 't/lib' },
            perlcriticEnabled = false,
            perlimportsLintEnabled = true,
            perlimportsTidyEnabled = true,
            perlPath = 'perl',
        }
    },
    on_new_config = function(new_config, new_root)
        local m = string.match(new_root, '^(.teamcity)')
        if m then
            new_config.settings.perlnavigator.perlPath = 'mm-perl'
            new_config.settings.perlnavigator.perlcriticProfile = table.concat({ m, 'mm_website/.perlcriticrc' }, '/')
            new_config.settings.perlnavigator.perltidyProfile = table.concat({ m, 'mm_website/.perltidyallrc' }, '/')
        end
    end,
}

require('lspconfig').rust_analyzer.setup({
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

require('lspconfig').tsserver.setup {
    on_attach = require("lsp-format").on_attach,
    filetypes = { "javascript", "typescript", "typescriptreact" },
    cmd = { "typescript-language-server", "--stdio" },
}

require('lspconfig').pylsp.setup {
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

wildchar = "<tab>"
-- require("lspconfig").rust_analyzer.setup {}

require("noice").setup({
    lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
        },
        progress = {
            enabled = true,
            format = 'lsp_progress',
            format_done = 'lsp_progress_done',
            view = 'mini',
        },
    },
    -- you can enable a preset for easier configuration
    presets = {
        bottom_search = true,         -- use a classic bottom cmdline for search
        command_palette = true,       -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false,           -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false,       -- add a border to hover docs and signature help
    },
})

require('project_nvim').setup {
    detection_methods = { 'pattern', 'lsp' },
    patterns = { '.git', 'Makefile', },
    silent_chdir = false,
    -- ignore_lsp = { 'null-ls' },
    scope_chdir = 'global',
}

local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.shfmt,
    },
})

require('NeoColumn').setup(
    {
        fg_color = "",
        bg_color = "",
        NeoColumn = "78",
        always_on = true,
        custom_NeoColumn = {},
        excluded_ft = { "text", "markdown" },
    }
)

require('glow').setup()

local wk = require("which-key")
wk.register({
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
}, { prefix = "<leader>" })

wk.setup {}

vim.keymap.set("n", "<leader>xx", function() require("trouble").open() end)
vim.keymap.set("n", "<leader>xw", function() require("trouble").open("workspace_diagnostics") end)
vim.keymap.set("n", "<leader>xd", function() require("trouble").open("document_diagnostics") end)
vim.keymap.set("n", "<leader>xq", function() require("trouble").open("quickfix") end)
vim.keymap.set("n", "<leader>xl", function() require("trouble").open("loclist") end)
vim.keymap.set("n", "gR", function() require("trouble").open("lsp_references") end)
