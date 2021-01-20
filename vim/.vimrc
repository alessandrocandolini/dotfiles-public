" ~/.vimrc

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
" set number relativenumber
set nonumber

" Disable error bells
set noerrorbells
set belloff=all

" milliseconds after stop typing before processing plugins (default 4000)
set updatetime=300

" allow backspacing over everything in insert mode
" set backspace=indent,eol,start

" do not keep a backup file (some LSP don't work well in coc with backup files)
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

" Do not highlight search results (default in vim but not in neovim)
set nohlsearch

" Do not change cursor shape in insert mode (to fix neovim standard behaviour)
set guicursor=

" Default colorscheme (has to be installed, see vim-plug below)
" You need ot generate a symb link in .vim/colors folder
" ln -s ~/.vim/bundle/jellybeans.vim/colors/jellybeans.vim ~/.vim/colors/jellybeans.vim
set termguicolors     " enable true colors support
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
" Haskell formatter on save (assuming ormolu is installed in the system)
Plug 'sdiehl/vim-ormolu'

Plug 'junegunn/fzf', {'dir': '~/.fzf','do': './install --all'}
Plug 'junegunn/fzf.vim' " needed for previews

Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'

Plug 'honza/vim-snippets'
call plug#end()

" Setup fuzzy finder fzf bridge (requires fzf installed)
set rtp+=/usr/local/opt/fzf

" Comments highlighting when using jsonc as configuration file format
autocmd FileType json syntax match Comment +\/\/.\+$+

" Help Vim recognize *.sbt and *.sc as Scala files
au BufRead,BufNewFile *.sbt,*.sc,*.scala set filetype=scala

" ===== Load plugin specific configuration ====
if filereadable(expand("~/.vim/plugins/coc-mappings.vim"))
   source ~/.vim/plugins/coc-mappings.vim
endif

" Remove trailing spaces on save
fun s:StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    keepp %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd FileType sh,scala,kotlin,json autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()
command! StripTrailingWhitespaces call s:StripTrailingWhitespaces()

" If fzf with ripgrep is setup, this is a useful alias
nnoremap <silent> <Leader>f :Rg<CR>
nnoremap <silent> <Leader>g :GFiles<CR>

" Persist undo
if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
    call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
set undodir=~/.vim/undo-dir
set undofile

" Mapping to comment lines
" source: https://stackoverflow.com/questions/1676632/whats-a-quick-way-to-comment-uncomment-lines-in-vim
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,scala let b:comment_leader = '// '
  autocmd FileType sh,ruby,python   let b:comment_leader = '# '
  autocmd FileType conf,fstab,yaml  let b:comment_leader = '# '
  autocmd FileType tex              let b:comment_leader = '% '
  autocmd FileType mail             let b:comment_leader = '> '
  autocmd FileType vim              let b:comment_leader = '" '
augroup END
noremap <silent> <Leader>cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> <Leader>cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>
