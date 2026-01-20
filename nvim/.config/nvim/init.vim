" Use Vim settings rather than Vi settings.
" This must be first, because it changes other options as a side effect.
set nocompatible

" Enable file detection, plugin, and indentation
filetype plugin indent on

" Switch syntax highlighting on (requires filetype detection on)
syntax on

" Set encoding to UTF-8 without BOM
set encoding=utf-8 nobomb

" Show invisible characters and set indentation preferences
set list
set lcs=tab:▸\ ,trail:␣,nbsp:¬
set expandtab ts=2 sw=2 ai

" show encoding in statusbar, if/when statusbar is enabled
if has("statusline")
 set statusline=%<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P
endif

" no statusbar by default (0 = never, 2 = always, 3 = global for all windows)
set laststatus=0

" Do not add empty newline at EOF
set noeol

" Display end of buffer lines as blank
set fillchars+=eob:\  " eob fillchar is a space; keep the escaped space before this comment

" Disable unsafe commands and the ruler display
set secure
set noruler

" Show absolute and relative line numbers
set number relativenumber

" Disable mouse support
set mouse=

" Disable error bells
set noerrorbells
set belloff=all

" Milliseconds after stop typing before processing plugins (default 4000)
set updatetime=300
set scrolloff=3
set sidescrolloff=5
set sidescroll=1

" Do not keep backup files (some LSPs are sensitive to backup files)
set nobackup
set nowritebackup

" Display incomplete commands while typing
set showcmd

" Do not change the cursor shape in insert mode
set guicursor=

" Fix the asymmetry between Ctrl-W n and Ctrl-W v to split the window
nnoremap <C-w>v :vnew<CR>

" Intentionally override the default <C-l> (redraw screen) to clear search highlights.
" Use :redraw! or another custom mapping if you need the original redraw behavior.
nnoremap <silent> <C-l> :nohlsearch<CR>

" <leader><leader> toggles between buffers
nnoremap <leader><leader> <c-^>

" Open new file adjacent to current file
nnoremap <leader>o :e <C-R>=expand('%:p:h') . '/'<CR>

" ==========================
" Vim-Plug Setup
" ==========================
" https://github.com/junegunn/vim-plug
" Installation of vim-plug is described in the readme (curl command)
" curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" Restart and run :PlugInstall to install plugins.
" To uninstall, remove it from this file and run :PlugClean

call plug#begin('~/.config/nvim/plugged')
Plug 'rktjmp/lush.nvim' " required by jellybeans-nvim
Plug 'metalelf0/jellybeans-nvim'
Plug 'axelf4/vim-strip-trailing-whitespace'
Plug 'windwp/nvim-autopairs'
Plug 'nvim-lua/plenary.nvim'
Plug 'scalameta/nvim-metals'
Plug 'junegunn/fzf', {'dir': '~/.fzf','do': './install --all'}
Plug 'junegunn/fzf.vim' " needed for previews
Plug 'hrsh7th/nvim-cmp'              " Core completion framework
Plug 'hrsh7th/cmp-nvim-lsp'          " LSP completion source
Plug 'L3MON4D3/LuaSnip'              " Lua-based snippet engine
Plug 'saadparwaiz1/cmp_luasnip'      " LuaSnip completion source
Plug 'tpope/vim-projectionist'
Plug 'Mrcjkb/haskell-tools.nvim', {'version': 6, 'for': ['haskell']}
Plug 'kana/vim-textobj-user', { 'for': ['agda'] }
Plug 'neovimhaskell/nvim-hs.vim', { 'for': ['agda'] }
Plug 'agda/cornelis', { 'for': ['agda'], 'do': 'stack build' }
Plug 'j-hui/fidget.nvim' " Neovim notifications and LSP progress messages
call plug#end()

" Persist Undo in an XDG-Compliant Location
if !isdirectory($HOME."/.local/share/nvim/undo")
    call mkdir($HOME."/.local/share/nvim/undo", "p", 0700)
endif
set undodir=~/.local/share/nvim/undo
set undofile

" Load Lua setup
lua require('setup1')
