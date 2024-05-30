set runtimepath^=~/.vim,~/.vim/after
set packpath^=~/.vim

lua <<EOF
require('conf')
require('plugins')
EOF

" Show comments in italics
highlight Comment cterm=italic gui=italic term=bold
