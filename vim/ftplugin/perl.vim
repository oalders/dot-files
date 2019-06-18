set expandtab
set number
set showmatch " matching brackets

vnoremap <silent> = :!perltidy -q<CR>
nnoremap <Leader>p <Esc>:!prove -It/lib -lv %<CR>

let g:ale_perl_syntax_check_executable = 'perl'

" https://github.com/skaji/syntax-check-perl#integrate-with-vim-plug-and-ale
let g:ale_perl_syntax_check_config = expand('~/dot-files/syntax-check-perl/config.pl')

" show Perl::Critic rules which have been violated
let g:ale_perl_perlcritic_showrules = 1

" show matching brackets
RainbowParentheses

" https://stackoverflow.com/questions/2345519/how-can-i-script-vim-to-run-perltidy-on-a-buffer

"define :Tidy command to run perltidy on visual selection || entire buffer"
command -range=% -nargs=* PTidy <line1>,<line2>!perltidy -q

"run :PTidy on entire buffer and return cursor to (approximate) original position"
fun DoPerlTidy()
    let l:line = line(".")
    let l:column = col(".")
    :PTidy
    call cursor(l:line, l:column)
endfun

vnoremap <silent> = :!perltidy -q<CR>

"shortcut for normal mode to run on entire buffer then return to current line"
nnoremap = :call DoPerlTidy()<CR>

set keywordprg=perldoc\ -f

map ,mmi o__PACKAGE__->meta->make_immutable;<CR>1;<ESC>
map ,ddp ouse DDP;<CR>p( );<ESC>
map ,perl :set paste<CR>O#!/usr/bin/env perl;<CR><CR>use strict;<CR>use warnings;<CR>use feature qw( say );<CR><ESC>
map ,moose Opackage Foo::Bar;<CR><CR>use Moose;<CR><CR>use MooseX::StrictConstructor;<CR><CR>__PACKAGE__->meta->make_immutable;<CR>1;<ESC>
map ,se :set paste<CR>i    my $self = shift;<CR>

" convert a file path to a Perl module name
" ie Foo/Bar/Baz.pm => Foo::Bar::Baz
map ,2mod :s/\.pm//<CR>gv:s/\//::/g<CR>

" Try to install missing Perl modules
nnoremap <leader>l :!perl -Mlazy -c %:p

