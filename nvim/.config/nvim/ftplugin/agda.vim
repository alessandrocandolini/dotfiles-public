" Agda-specific settings (buffer-local by default in ftplugin files)
"setlocal laststatus=2
packadd vim-textobj-user
packadd nvim-hs.vim
packadd cornelis
let g:cornelis_split_location = 'bottom'

nnoremap <buffer> <leader>l :CornelisLoad<CR>
nnoremap <buffer> <leader>r :CornelisRefine<CR>
nnoremap <buffer> <leader>d :CornelisMakeCase<CR>
nnoremap <buffer> <leader>, :CornelisTypeContext<CR>
nnoremap <buffer> <leader>. :CornelisTypeContextInfer<CR>
nnoremap <buffer> <leader>s :CornelisSolve<CR>
nnoremap <buffer> <leader>n :CornelisNormalize<CR>
nnoremap <buffer> <leader>a :CornelisAuto<CR>
nnoremap <buffer> gd        :CornelisGoToDefinition<CR>
nnoremap <buffer> [/        :CornelisPrevGoal<CR>
nnoremap <buffer> ]/        :CornelisNextGoal<CR>
nnoremap <buffer> <C-A>     :CornelisInc<CR>
nnoremap <buffer> <C-X>     :CornelisDec<CR>
