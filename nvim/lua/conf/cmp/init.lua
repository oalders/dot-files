require('cmp_nvim_lsp')

-- If you want insert `(` after select function or method item
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require('cmp')

---@diagnostic disable-next-line:redundant-parameter
cmp.setup({
    experimental = {
        ghost_text = true,
    },
    formatting = {
        format = function(entry, item)
            item = require('lspkind').cmp_format()(entry, item)
            local alias = {
                buffer = 'buffer',
                path = 'path',
                calc = 'calc',
                emoji = 'emoji',
                nvim_lsp = 'LSP',
                -- luasnip = 'luasnip',
                -- vsnip = 'vsnip',
                nvim_lua = 'lua',
                nvim_lsp_signature_help = 'LSP Signature',
                Copilot = '',
            }

            if entry.source.name == 'nvim_lsp' then
                item.menu = entry.source.source.client.name
            else
                item.menu = alias[entry.source.name] or entry.source.name
            end

            -- width logic taken from https://github.com/hrsh7th/nvim-cmp/discussions/609
            local fixed_width = false
            if fixed_width then
                vim.o.pumwidth = fixed_width
            end
            local win_width = vim.api.nvim_win_get_width(0)
            local max_content_width = fixed_width and fixed_width - 10
                or math.floor(win_width * 0.1)
            local content = item.abbr
            if #content > max_content_width then
                item.abbr = vim.fn.strcharpart(
                    content,
                    0,
                    max_content_width - 3
                ) .. '...'
            else
                item.abbr = content .. (' '):rep(max_content_width - #content)
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
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
                -- elseif luasnip.expand_or_jumpable() then
                -- luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),

        -- https://www.reddit.com/r/neovim/comments/svtw2u/scrolling_lsp_floating_window/
        ['<C-k>'] = cmp.mapping.scroll_docs(-4), -- <C-k><C-k> now bounces me into the floating window
    }),
    preselect = cmp.PreselectMode.None,
    view = {
        -- entries = 'native',
    },
    -- snippet = {
    -- -- REQUIRED - you must specify a snippet engine
    -- expand = function(args)
    -- -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
    -- -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
    -- -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    -- end,
    -- },
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
        -- { name = 'emoji',    priority = 3 },
        -- { name = 'calc',     priority = 5 },
        { name = 'nvim_lua', priority = 5 },
        -- { name = 'luasnip',  priority = 8 },
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
    }),
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' },
    },
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
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
