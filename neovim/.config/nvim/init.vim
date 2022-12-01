" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Enable file detection, plugin and indentation
filetype plugin indent on

" Switch syntax highlighting on (requires filetype detection on)
syntax on

" Use UTF-8 without BOM
set encoding=utf-8 nobomb

" Show invisible characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list
set expandtab ts=2 sw=2 ai

" Optimize for fast terminal connections
set ttyfast

" Recursive search in path (useful for file search)
set path+=**

" show encoding in statusbar, if/when statusbar is enabled
if has("statusline")
 set statusline=%<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P
endif

" no statusbar by default (0 = never, 2 = always)
set laststatus=0

" Don’t add empty newlines at the end of files
set noeol

"disable unsafe commands
set secure

" Don't show the cursor position
set noruler

" Don't show line number. If you turn it on, consider relative numbers:
" set number
" set number relativenumber
set nonumber

" Disable error bells
set noerrorbells
set belloff=all

" milliseconds after stop typing before processing plugins (default 4000)
set updatetime=300

" do not keep a backup file (some LSP don't work well in coc with backup files)
set nobackup
set nowritebackup

" display incomplete commands (partial command as it’s being typed)
set showcmd

" Fix the asymmetry between Ctrl-W n and Ctrl-W v for opening a window
nnoremap <C-w>v :vnew<CR>

" Do not highlight search results (default in vim but not in neovim)
set nohlsearch

" Do not change cursor shape in insert mode (to fix neovim standard behaviour)
set guicursor=

" ==========================
" Vim-Plug
" ==========================
" https://github.com/junegunn/vim-plug
" Installation of vim-plug is described in the readme (curl command)
" curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" Restart and run :PlugInstall to install plugins.
" To uninstall, remove it from this file and run :PlugClean

call plug#begin('~/.config/nvim/plugged')
Plug 'nanotech/jellybeans.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'scalameta/nvim-metals'

Plug 'junegunn/fzf', {'dir': '~/.fzf','do': './install --all'}
Plug 'junegunn/fzf.vim' " needed for previews

"Plug 'tpope/vim-surround'
"Plug 'tpope/vim-repeat'

Plug 'preservim/nerdcommenter'

"more advanced (not sure i wanna keep them)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-telescope/telescope.nvim'
Plug 'glepnir/lspsaga.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'MrcJkb/haskell-tools.nvim'

call plug#end()


" Default colorscheme (has to be installed, see vim-plug above)
" Either place this code AFTER the vim-plug section, or you might need to generate symb links in the .vim/colors folder
" ln -s ~/.vim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.vim/colors/jellybeans.vim
" ln -s ~/.config/nvim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.config/nvim/colors/jellybeans.vim
" This seems necessary if you use "set termguicolors".
" let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
" let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
" fixes glitch? in colors when using vim with tmux
set background=dark
set t_Co=256
set termguicolors     " enable true colors support
try
  colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
endtry

" Setup fuzzy finder fzf bridge (requires fzf installed)
set rtp+=/usr/local/opt/fzf

" Help Vim recognize *.sbt and *.sc as Scala files
au BufRead,BufNewFile *.sbt,*.sc,*.scala set filetype=scala

" Remove trailing spaces on save
fun s:StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    keepp %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd FileType sh,scala,kotlin,json,haskell,yaml autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()
command! StripTrailingWhitespaces call s:StripTrailingWhitespaces()

""
command! -bang -nargs=* Rg2 call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>), 1, {'options': '--delimiter : --nth 4..'}, <bang>0)

nnoremap <Leader>ff :GFiles --cached --others --exclude-standard<CR>
nnoremap <Leader>fg :Rg<CR>
nnoremap <Leader>fb :Buffers<CR>

" Persist undo
if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
    call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
set undodir=~/.vim/undo-dir
set undofile

let g:NERDCreateDefaultMappings = 0
nmap <silent> <Leader>cc <Plug>NERDCommenterToggle
vmap <silent> <Leader>cc <Plug>NERDCommenterToggle

lua require('setup')
