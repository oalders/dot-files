" vim-go: For some reason when autocompleting code, a preview pane opens, but
" does not close automatically after the code has been completed.  It seems
" like a handy feature, but let's disable it for now.  Would be great to
" re-enable it if there's a way to get the pane to close automatically.
" See https://github.com/fatih/vim-go/issues/912
set completeopt-=preview

" Much like the version in .vimrc, but without the :set list, which causes
" tabs to have visual markers
fun! ShowGutter()
    :GitGutterEnable
    :set number
endfun

" Hide tabs and show numbers for Go files
setlocal nolist
set number

" some other plugin is already highlighting matches
"let g:go_auto_sameids = 1
let g:go_auto_type_info = 0
let g:go_fmt_command="gopls"
let g:go_gopls_gofumpt=1
let g:go_highlight_extra_types = 1
let g:go_highlight_fields = 1
"let g:go_highlight_functions = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_types = 1
let g:go_fmt_fail_silently = 1 " Ale handles this already

nmap <leader>t  <Plug>(go-test)
nmap <leader>b  <Plug>(go-build)

let g:go_def_mode='gopls'
let g:go_info_mode='gopls'
let g:go_rename_command = 'gopls'

function! ShowTabs()
    :set list
    :set listchars=tab:>-
endfunction
