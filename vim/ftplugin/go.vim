" vim-go: For some reason when autocompleting code, a preview pane opens, but
" does not close automatically after the code has been completed.  It seems
" like a handy feature, but let's disable it for now.  Would be great to
" re-enable it if there's a way to get the pane to close automaticall.
" See https://github.com/fatih/vim-go/issues/1106
set completeopt-=preview

" Much like the version in .vimrc, but without the :set list, which causes
" tabs to have visual markers
fun! ShowGutter()
    :GitGutterEnable
    :set number
endfun
