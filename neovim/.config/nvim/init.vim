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
set lcs=tab:▸\ ,trail:·,nbsp:_
set expandtab ts=2 sw=2 ai

" Enable recursive search in path (useful for file searches)
set path+=**

" show encoding in statusbar, if/when statusbar is enabled
if has("statusline")
 set statusline=%<%f\ %h%m%r%=%{\"[\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"]\ \"}%k\ %-14.(%l,%c%V%)\ %P
endif

" no statusbar by default (0 = never, 2 = always)
set laststatus=0

" Do not add empty newline at EOF
set noeol

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
set lazyredraw
set scrolloff=3
set sidescrolloff=5
set sidescroll=1

" Do not keep backup files (some LSPs are sensitive to backup files)
set nobackup
set nowritebackup

" Display incomplete commands while typing
set showcmd

" Fix the asymmetry between Ctrl-W n and Ctrl-W v to split the window
nnoremap <C-w>v :vnew<CR>

" Remove search highlights when a search is completed
nnoremap <leader>h :nohlsearch<CR>

" Do not change the cursor shape in insert mode
set guicursor=

" ==========================
" Vim-Plug Setup
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
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-telescope/telescope.nvim'
Plug 'hrsh7th/nvim-cmp'              " Core completion framework
Plug 'hrsh7th/cmp-nvim-lsp'          " LSP completion source
Plug 'L3MON4D3/LuaSnip'              " Lua-based snippet engine
Plug 'saadparwaiz1/cmp_luasnip'      " LuaSnip completion source
Plug 'Mrcjkb/haskell-tools.nvim', {'version': 4}
Plug 'kana/vim-textobj-user' " Required by cornelis
Plug 'neovimhaskell/nvim-hs.vim' " Required by cornelis
Plug 'agda/cornelis', { 'do': 'stack build' }
Plug 'j-hui/fidget.nvim' " Neovim notifications and LSP progress messages
Plug 'ray-x/lsp_signature.nvim'
call plug#end()

" Default colorscheme (has to be installed, see vim-plug above)
" Place this code AFTER the vim-plug section, otherwise you need to generate symb links in the colors folder
set termguicolors     " enable true colors support
try
  colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
endtry

" Set transparent background for Normal and LineNr highlights
autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
autocmd ColorScheme * highlight LineNr guibg=NONE ctermbg=NONE
highlight Normal guibg=NONE ctermbg=NONE
highlight LineNr guibg=NONE ctermbg=NONE

" Associate Scala file extensions with the Scala filetype
au BufRead,BufNewFile *.sbt,*.sc,*.scala set filetype=scala

" Trailing Whitespace Removal
function! s:StripTrailingWhitespaces() abort
    let l = line(".")
    let c = col(".")
    keepjumps %s/\s\+$//e
    call cursor(l, c)
endfunction
autocmd FileType sh,scala,kotlin,json,haskell,yaml,markdown,nix autocmd BufWritePre <buffer> call <SID>StripTrailingWhitespaces()
command! StripTrailingWhitespaces call s:StripTrailingWhitespaces()

" Custom mappings for fzf
nnoremap <Leader>ff :Files<CR>
nnoremap <Leader>fg :Rg<CR>

" Persist Undo in an XDG-Compliant Location
if !isdirectory($HOME."/.local/share/nvim/undo")
    call mkdir($HOME."/.local/share/nvim/undo", "p", 0700)
endif
set undodir=~/.local/share/nvim/undo
set undofile

" Load Lua setup
lua require('setup1')
