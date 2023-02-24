set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim
source ~/.vimrc

" The branch of treesitter I'm using doesn't yet support Perl
" See :TSInstall perl
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { 'bash', 'dockerfile', 'go', 'html', 'javascript', 'lua', 'markdown', 'markdown_inline', 'python', 'regex', 'ruby', 'rust', 'sql', 'typescript', 'vim', 'yaml' },
    -- ensure_installed = 'all',
  highlight = {
    enable = true,              -- false will disable the whole extension
    disable = { "perl" },  -- list of language that will be disabled
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
    files = { 'src/parser.c', 'src/scanner.cc' },
    generate_requires_npm = true,
  },
  maintainers = { '@leonerd' },
  filetype = 'perl',
}

vim.opt.termguicolors = true
vim.opt.mouse = "v"
require('bufferline').setup{}

require('virt-column').setup()
require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true,
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
})

EOF

" https://github.com/mhartington/oceanic-next#installation
if (has('termguicolors'))
  set termguicolors
endif

nnoremap <silent>]b :BufferLineCycleNext<CR>
nnoremap <silent>[b :BufferLineCyclePrev<CR>
