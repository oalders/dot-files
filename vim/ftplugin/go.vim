" Much like the version in .vimrc, but without the :set list, which causes
" tabs to have visual markers
fun! ShowGutter()
    :GitGutterEnable
    :set number
endfun

" Hide tabs and show numbers for Go files
setlocal nolist
set number

function! ShowTabs()
    :set list
    :set listchars=tab:>-
endfunction

fun! HideTabs()
    :setlocal nolist
    :set number
endfunction
