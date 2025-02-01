" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Enable file detection, plugin, and indentation
filetype plugin indent on

" Switch syntax highlighting on (requires filetype detection on)
syntax on

" Use UTF-8 without BOM
set encoding=utf-8 nobomb

" Show invisible characters
set list
set lcs=tab:▸\ ,trail:·,nbsp:_
set expandtab ts=2 sw=2 ai

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

" Disable unsafe commands
set secure

" Don't show the cursor position
set noruler

" Show line numbers with relative numbers
set number relativenumber

" Disable mouse by default in recent Neovim
set mouse=

" Disable error bells
set noerrorbells
set belloff=all

" Milliseconds after stop typing before processing plugins (default 4000)
set updatetime=100
set lazyredraw
set scrolloff=3
set sidescrolloff=5
set sidescroll=1

" Do not keep a backup file (some LSP don't work well with backup files)
set nobackup
set nowritebackup

" Display incomplete commands (partial command as it’s being typed)
set showcmd

" Fix the asymmetry between Ctrl-W n and Ctrl-W v for opening a window
nnoremap <C-w>v :vnew<CR>

" Do not highlight search results (default in Vim but not in Neovim)
set nohlsearch

" Do not change cursor shape in insert mode (to fix Neovim standard behaviour)
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

" Essential plugins
Plug 'nanotech/jellybeans.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'scalameta/nvim-metals'
Plug 'junegunn/fzf', {'dir': '~/.fzf','do': './install --all'}
Plug 'junegunn/fzf.vim' " needed for previews
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-telescope/telescope.nvim'
Plug 'hrsh7th/nvim-cmp'              " Core completion framework
Plug 'hrsh7th/cmp-nvim-lsp'          " LSP completion source
Plug 'L3MON4D3/LuaSnip'              " Lua-based snippet engine
Plug 'saadparwaiz1/cmp_luasnip'      " LuaSnip completion source
Plug 'MrcJkb/haskell-tools.nvim'
Plug 'kana/vim-textobj-user' " Required by cornelis
Plug 'neovimhaskell/nvim-hs.vim' " Required by cornelis
Plug 'agda/cornelis', { 'do': 'stack build' }
Plug 'j-hui/fidget.nvim'
Plug 'ray-x/lsp_signature.nvim'
call plug#end()

" Default colorscheme (has to be installed, see vim-plug above)
" Either place this code AFTER the vim-plug section, or you might need to generate symb links in the .vim/colors folder
" ln -s ~/.vim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.vim/colors/jellybeans.vim
" ln -s ~/.config/nvim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.config/nvim/colors/jellybeans.vim
set termguicolors     " enable true colors support
try
  colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
endtry

" Set background to transparent
autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
autocmd ColorScheme * highlight LineNr guibg=NONE ctermbg=NONE
highlight Normal guibg=NONE ctermbg=NONE
highlight LineNr guibg=NONE ctermbg=NONE

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

" Custom mappings for fzf
nnoremap <Leader>ff :Files<CR>
nnoremap <Leader>fg :Rg<CR>

" Persist undo
if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
    call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
set undodir=~/.vim/undo-dir
set undofile

" Load Lua setup
lua require('setup1')
