set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim
source ~/.vimrc

" The branch of treesitter I'm using doesn't yet support Perl
" See :TSInstall perl
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  -- ignore_install = { "perl" }, -- List of parsers to ignore installing
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

vim.opt.termguicolors = true
require("bufferline").setup{}
EOF

" https://github.com/mhartington/oceanic-next#installation
if (has("termguicolors"))
  set termguicolors
endif

nnoremap <silent>]b :BufferLineCycleNext<CR>
nnoremap <silent>[b :BufferLineCyclePrev<CR>
