set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim

lua <<EOF
require('conf')
require('plugins')
EOF

:tnoremap <C-^> <C-\><C-n>
