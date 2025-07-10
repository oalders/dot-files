--- vim.g throws a lot of diagnostic warnings
---@diagnostic disable: inject-field
vim.opt.swapfile = false

-- allow undo even after exiting and re-opening a file
vim.opt.undofile = true

-- :vertical terminal now opens on the right 😅
vim.opt.splitright = true

-- keep 10 lines under the cursor when scrolling
vim.opt.scrolloff = 10

-- mode info is displayed in the statusline
vim.opt.showmode = false

vim.opt.number = true

vim.opt.encoding = 'utf-8'
-- vim.cmd('scriptencoding utf-8')

vim.g.mapleader = ','

vim.cmd('syntax enable')
vim.opt.background = 'dark'
vim.cmd('highlight clear LineNr')
vim.cmd('highlight clear SignColumn')

-- disable vim's intro screen
vim.opt.shortmess:append('I')

-- S: skip messages about writing a file
vim.opt.shortmess:remove('S')

vim.opt.backspace = '2'

vim.api.nvim_exec(
    [[
  augroup fileops
    autocmd CursorHold * checktime
  augroup END
]],
    false
)
-- paste and keep clipboard content - allows pasting the same text multiple
-- times over different selections
vim.api.nvim_set_keymap('x', 'p', 'pgvy', {})

vim.g.auto_save = 1
vim.g.auto_save_no_updatetime = 1

vim.cmd('highlight Normal ctermbg=none')

vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 1000

vim.opt.autoread = true
vim.opt.synmaxcol = 2000

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.cmd('hi Search ctermbg=LightYellow')
vim.cmd('hi Search ctermfg=Red')

vim.cmd('filetype plugin indent on')
vim.opt.autoindent = true

-- tabs
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.listchars = 'tab:→  '

-- https://stackoverflow.com/a/69099888/406224
function UseTabs()
    vim.opt.expandtab = false
    vim.opt.copyindent = true
    vim.opt.preserveindent = true
    vim.opt.softtabstop = 0
    vim.opt.shiftwidth = 4
    vim.opt.tabstop = 4
    vim.opt.list = true
end

vim.opt.list = true

vim.api.nvim_set_keymap('v', '<tab>', '>gv', {})
vim.api.nvim_set_keymap('v', '<s-tab>', '<gv', {})

vim.api.nvim_set_keymap('n', '<tab>', 'I<tab><esc>', {})
vim.api.nvim_set_keymap('n', '<s-tab>', '^i<bs><esc>', {})

-- define a group `vimrc` and initialize.
vim.api.nvim_exec(
    [[
  augroup vimrc
    autocmd!
    autocmd BufEnter .vim-plug-vimrc  setlocal filetype=vim
    autocmd BufEnter ansible/hosts setlocal filetype=dosini
    autocmd BufEnter *Dockerfile setlocal filetype=dockerfile
    autocmd BufEnter dataprinter     setlocal filetype=dosini
    autocmd BufEnter .dataprinter     setlocal filetype=dosini
    autocmd BufEnter perlcriticrc    setlocal filetype=dosini
    autocmd BufEnter .perlcriticrc    setlocal filetype=dosini
    autocmd BufEnter .prettierrc      setlocal filetype=json
    autocmd BufEnter .tidyallrc       setlocal filetype=dosini
    autocmd BufEnter .yath.rc         setlocal filetype=dosini
    autocmd BufEnter .yath.user.rc    setlocal filetype=dosini
    autocmd BufRead,BufNewFile *.gohtml   set filetype=gohtmltmpl
    autocmd BufRead,BufNewFile *.html.ep  set filetype=html
    autocmd BufRead,BufNewFile *.html.epl set filetype=html
    autocmd BufRead,BufNewFile *.tmpl     set filetype=html
    autocmd BufRead,BufNewFile *.yml set filetype=yaml
    autocmd FileType yaml setlocal sw=2 ts=2 sts=2
    autocmd BufRead,BufNewFile local_bashrc set filetype=sh
    autocmd BufRead,BufNewFile Changes      set filetype=txt
    autocmd FileType dashboard setlocal nobackup noundofile noswapfile
  augroup END
]],
    false
)

-- prevent left and right arrows from being disabled in insert mode when
-- editing SQL files
vim.g.omni_sql_no_default_maps = 1

-- ########### Functions ###########
--
-- Exec current file
vim.api.nvim_set_keymap('n', '<Leader>e', '<Esc>:lua ExecFile()<CR>', {})

function ExecFile()
    vim.cmd('silent !chmod u+x %')
    vim.cmd('!"%:p"')
end

vim.cmd('command! ExecFile lua ExecFile()')

-- Set line markers to make indentation easier to follow
-- Enable via :lua ShowLines()
function ShowLines()
    vim.opt.colorcolumn = '5,9,13,17,21,25,29,78'
end

vim.cmd('command! ShowLines lua ShowLines()')

function HideGutter()
    vim.opt.number = false
    vim.opt.list = false
    vim.opt.signcolumn = 'no' -- sign column
    vim.opt.foldcolumn = '0'
    if vim.fn.exists(':Neominimap') == 2 then
        vim.cmd('Neominimap off')
    end
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    vim.diagnostic.config({ virtual_text = false })
end

vim.cmd('command! HideGutter lua HideGutter()')

function ShowGutter()
    vim.opt.number = true
    vim.opt.list = true
    vim.opt.signcolumn = 'auto'
    if vim.fn.exists(':Neominimap') == 2 then
        vim.cmd('Neominimap on')
    end
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    vim.diagnostic.config({ virtual_text = true })
end

function LastSession()
    require('persistence').load()
end

vim.cmd('command! LastSession lua LastSession()')

vim.cmd('command! ShowGutter lua ShowGutter()')

function Requote()
    for l = 1, vim.fn.line('$') do
        local line = vim.fn.getline(l)
        vim.fn.setline(l, vim.fn.substitute(line, '[“”]', '"', 'g'))
    end
end

vim.cmd('command! Requote lua Requote()')

-- nnoremap <leader>xx :call setfperm(expand('%'),"rwxrw-rw-")<cr>
vim.api.nvim_set_keymap(
    'n',
    '<leader>xx',
    ':call setfperm(expand("%"),"rwxrw-rw-")<cr>',
    {}
)

-- Change double quotes to single quotes
vim.api.nvim_set_keymap('v', "''", ':s/\\%V"/\'/g<cr>', { silent = true })

-- https://github.com/roxma/vim-hug-neovim-rpc/issues/28
vim.g.python_host_prog = '/usr/bin/python2'
vim.g.python3_host_prog = '/usr/bin/python3'

-- fzf
vim.g.fzf_preview_window = { 'down:50%', 'ctrl-/' }
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<cr>', {})

-- 'luochen1990/rainbow'
vim.g.rainbow_active = 1 --set to 0 if you want to enable it later via :RainbowToggle

vim.api.nvim_exec(
    [[
  if has('timers')
    " Blink 2 times with 50ms interval
    noremap <expr> <plug>(slash-after) slash#blink(2, 50)
  endif
]],
    false
)

-- insert a new uuid at cursor
vim.g.nuuid_no_mappings = 1

-- Prevent a mouse selection from triggering visual mode
vim.opt.mouse = 'v'

-- Use 2 spaces to indent GFM ToC
vim.g.vmt_list_indent_text = '  '
vim.g.vmt_auto_update_on_save = 1

vim.opt.cmdheight = 0

vim.opt.termguicolors = true

-- Use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Delete single character without copying to clipboard
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete character without copying' })
vim.keymap.set('n', 'X', '"_X', { desc = 'Delete character backwards without copying' })

-- Show comments in italics
vim.cmd('highlight Comment cterm=italic gui=italic term=bold')

-- Remap macro recording to 'Q' instead of 'q'
-- It's too easy to start recording accidentally
vim.keymap.set('n', 'q', '<nop>', {})
vim.keymap.set('n', 'Q', 'q', { desc = 'Record macro', noremap = true })

-- undercurl
-- https://dev.to/anurag_pramanik/how-to-enable-undercurl-in-neovim-terminal-and-tmux-setup-guide-2ld7
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

-- Enable spell check
vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }

-- Set some diff options
-- Stolen from https://www.reddit.com/r/neovim/comments/1ihpvaf/comment/maz7fmu/
vim.opt.diffopt =
    'filler,internal,closeoff,algorithm:histogram,context:5,linematch:60'
