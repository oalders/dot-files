set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim

nnoremap <silent>]b :BufferLineCycleNext<CR>
nnoremap <silent>[b :BufferLineCyclePrev<CR>

lua <<EOF
require('conf')
require('plugins')
EOF

colorscheme iceberg