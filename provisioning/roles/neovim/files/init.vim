set mouse=a
" workaround https://github.com/neovim/neovim/issues/6041
set guicursor=
"
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

set expandtab
set smartindent

set wildmode=longest,full

set autochdir

set showcmd

colorscheme torte

" permits to exit insert mode by typing with jj 
imap jj <Esc>
imap kk <Esc>

"the status bar is always displayed
set laststatus=2
if has("statusline")
    set statusline=%<%f%h%m%r%=%l,%c\ %P
elseif has("cmdline_info")
    set ruler " display cursor position
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.local/share/nvim/plugged')

" for fuzzy completion
Plug 'Shougo/denite.nvim'
Plug 'Shougo/echodoc.vim'
" to display in red extra whitespaces
Plug 'ntpeters/vim-better-whitespace'

Plug 'benekastah/neomake'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'phpactor/phpactor', {'for': 'php', 'branch': 'master', 'do': 'composer install --no-dev -o'}

Plug 'evidens/vim-twig'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'dense-analysis/ale'


" Initialize plugin system
call plug#end()

let g:ale_linters = {'php': ['php', 'langserver', 'phpstan']}
let g:ale_php_phpstan_executable = '/vagrant/vendor/bin/phpstan'
let g:ale_php_phpstan_level = 4
let g:ale_php_phpstan_configuration = '/vagrant/phpstan.neon'
let g:ale_php_langserver_use_global = 1
let g:ale_php_langserver_executable = $HOME.'/.composer/vendor/bin/php-language-server.php'

" Initialize plugin system
call plug#end()


" for language server

autocmd! BufWritePost * Neomake

" to easily switch from a split containing a terminal to an other split
" see https://medium.com/@garoth/neovim-terminal-usecases-tricks-8961e5ac19b9
func! s:mapMoveToWindowInDirection(direction)
    func! s:maybeInsertMode(direction)
        stopinsert
        execute "wincmd" a:direction

        if &buftype == 'terminal'
            startinsert!
        endif
    endfunc

    execute "tnoremap" "<silent>" "<C-" . a:direction . ">"
                \ "<C-\\><C-n>"
                \ ":call <SID>maybeInsertMode(\"" . a:direction . "\")<CR>"
    execute "nnoremap" "<silent>" "<C-" . a:direction . ">"
                \ ":call <SID>maybeInsertMode(\"" . a:direction . "\")<CR>"
endfunc
for dir in ["h", "j", "l", "k"]
    call s:mapMoveToWindowInDirection(dir)
endfor



let $FZF_DEFAULT_COMMAND='rg --files --hidden --follow --ignore-vcs'

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>).' /vagrant', 1,
  \   fzf#vim#with_preview(), <bang>0)

command! -bang PF call fzf#vim#files('/vagrant', <bang>0)
nnoremap <c-p> :PF<CR>
nnoremap <c-g> :Rg<CR>

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

autocmd FileType php set iskeyword+=$
autocmd FileType css set iskeyword+=-
autocmd FileType html set iskeyword+=-
autocmd FileType js set iskeyword+=-
autocmd FileType htmldjango.twig set iskeyword+=-
