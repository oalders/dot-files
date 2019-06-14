set expandtab
set number
set showmatch " matching brackets

vnoremap <silent> = :!perltidy -q<CR>
nnoremap <Leader>p <Esc>:!prove -It/lib -lv %<CR>
