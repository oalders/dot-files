set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim
source ~/.vimrc

" https://github.com/mhartington/oceanic-next#installation
if (has('termguicolors'))
  set termguicolors
endif

nnoremap <silent>]b :BufferLineCycleNext<CR>
nnoremap <silent>[b :BufferLineCyclePrev<CR>

lua <<EOF
require('conf')
require('plugins')
EOF
