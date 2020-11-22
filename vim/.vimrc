" ~/.vimrc

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Use UTF-8 without BOM
set encoding=utf-8 nobomb

" Show invisible characters
set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list
set expandtab ts=2 sw=2 ai
" set binary " not recommended 

" Optimize for fast terminal connections
set ttyfast

" Set hidden so any buffer can be hidden (keeping its changes) without first writing the buffer to a file
set hidden

" show encoding in statusbar
if has("statusline")
 set statusline=%<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P
endif

" Don’t add empty newlines at the end of files
set noeol

"disable unsafe commands
set secure

" Highlight current line
" set cursorline

" Show the cursor position
set ruler

" Switch syntax highlighting on
syntax on
filetype plugin indent on

" Disable error bells
set noerrorbells
set belloff=all

" Don’t reset cursor to start of line when moving around.
set nostartofline

" milliseconds after stop typing before processing plugins (default 4000) 
set updatetime=300

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" do not keep a backup file
set nobackup		
set nowritebackup

" display incomplete commands (partial command as it’s being typed)
set showcmd		

" performance improvements when syntax on in vim 8+
if v:version >= 800
       	syntax sync minlines=256
endif 

" Fix the asymmetry between Ctrl-W n and Ctrl-W v for opening a window
nnoremap <C-w>v :vnew<CR>

" tab settings
set expandtab
set softtabstop=2
set shiftwidth=2
set tabstop=2
set smarttab

" Default colorscheme (has to be installed, see vim-plug below)
" You need ot generate a symb link in .vim/colors folder
" ln -s ~/.vim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.vim/colors/jellybeans.vim
try
	colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
endtry

" ==========================
" Vim-Plug 
" ==========================
" https://github.com/junegunn/vim-plug
" Installation of vim-plug is described in the readme (curl command attow):
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" Reload .vimrc and :PlugInstall to install plugins.
" To uninstall, remove it from .vimrc and run :PlugClean

call plug#begin('~/.vim/bundle')
Plug 'nanotech/jellybeans.vim'

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'udalov/kotlin-vim' 

"Plug 'neovimhaskell/haskell-vim'
"Plug 'alx741/vim-hindent' " automatic indentation using hindent.

"Plug 'junegunn/fzf', {'dir': '~/.fzf','do': './install --all'}
"Plug 'junegunn/fzf.vim' " needed for previews
"Plug 'antoinemadec/coc-fzf', {'branch': 'release'}
call plug#end()

" Setup fuzzy finder fzf bridge (requires fzf installed)
" set rtp+=/usr/local/opt/fzf

" Comments highlighting when using jsonc as configuration file format
autocmd FileType json syntax match Comment +\/\/.\+$+

" Help Vim recognize *.sbt and *.sc as Scala files
au BufRead,BufNewFile *.sbt,*.sc set filetype=scala

" ===== Load plugin specific configuration ====
if !empty(glob("$HOME/.vim/plugins/coc-config.vim"))
   source $HOME/.vim/plugins/coc-config.vim
endif
