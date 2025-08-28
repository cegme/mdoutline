" mdoutline.vim - Markdown outline viewer for Vim
" Maintainer: Christan Grant <https://github.com/cegme>
" Version: 1.1.2

if exists('g:loaded_mdoutline')
  finish
endif
let g:loaded_mdoutline = 1
let g:mdoutline_version = '1.1.2'

if !exists('g:mdoutline_width')
  let g:mdoutline_width = 20
endif

if !exists('g:mdoutline_position')
  let g:mdoutline_position = 'left'
endif

if !exists('g:mdoutline_auto_open')
  let g:mdoutline_auto_open = 1
endif

command! MDOutlineToggle call mdoutline#toggle()
command! MDOutlineOpen call mdoutline#open()
command! MDOutlineClose call mdoutline#close()
command! MDOutlineRefresh call mdoutline#refresh()

nnoremap <silent> <Leader>mo :MDOutlineToggle<CR>

augroup MDOutline
  autocmd!
  if g:mdoutline_auto_open
    autocmd BufEnter *.md call mdoutline#auto_open()
  endif
  autocmd BufWritePost *.md call mdoutline#refresh()
  autocmd BufDelete,BufWipeout *.md call mdoutline#buffer_cleanup()
augroup END