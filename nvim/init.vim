set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim

lua <<EOF
require('plugins')
require('conf')
EOF

:tnoremap <C-^> <C-\><C-n>
