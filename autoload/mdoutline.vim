" mdoutline.vim - Autoload functions for markdown outline viewer
" Maintainer: Christan Grant <https://github.com/cegme>

let s:outline_buffer = -1
let s:outline_window = -1
let s:source_buffer = -1

function! mdoutline#toggle()
  if s:is_outline_open()
    call mdoutline#close()
  else
    call mdoutline#open()
  endif
endfunction

function! mdoutline#open()
  if s:is_outline_open()
    return
  endif
  
  if &filetype != 'markdown'
    echo "MDOutline: Not a markdown file"
    return
  endif
  
  let s:source_buffer = bufnr('%')
  
  let position = g:mdoutline_position == 'right' ? 'botright' : 'topleft'
  execute position . ' ' . g:mdoutline_width . 'vnew'
  
  let s:outline_buffer = bufnr('%')
  let s:outline_window = winnr()
  
  setlocal filetype=mdoutline
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal norelativenumber
  setlocal nocursorline
  setlocal nocursorcolumn
  setlocal winfixwidth
  
  call s:populate_outline()
  call s:setup_mappings()
  
  execute "file MDOutline"
endfunction

function! mdoutline#close()
  if !s:is_outline_open()
    return
  endif
  
  let outline_win = bufwinnr(s:outline_buffer)
  if outline_win != -1
    execute outline_win . 'wincmd w'
    close
  endif
  
  let s:outline_buffer = -1
  let s:outline_window = -1
endfunction

function! mdoutline#refresh()
  if !s:is_outline_open()
    return
  endif
  
  let current_win = winnr()
  let outline_win = bufwinnr(s:outline_buffer)
  
  if outline_win != -1
    execute outline_win . 'wincmd w'
    call s:populate_outline()
    execute current_win . 'wincmd w'
  endif
endfunction

function! mdoutline#auto_open()
  if &filetype == 'markdown' && !s:is_outline_open()
    call mdoutline#open()
  endif
endfunction

function! s:is_outline_open()
  return s:outline_buffer != -1 && bufexists(s:outline_buffer)
endfunction

function! s:populate_outline()
  if !bufexists(s:source_buffer)
    return
  endif
  
  setlocal modifiable
  %delete _
  
  let headers = s:get_headers()
  
  if empty(headers)
    call setline(1, "No headers found")
    setlocal nomodifiable
    return
  endif
  
  let lines = []
  for header in headers
    let indent = repeat('  ', header.level - 1)
    let line = indent . header.text
    call add(lines, line)
  endfor
  
  call setline(1, lines)
  setlocal nomodifiable
  
  call s:store_headers(headers)
endfunction

function! s:get_headers()
  let headers = []
  let source_lines = getbufline(s:source_buffer, 1, '$')
  
  for i in range(len(source_lines))
    let line = source_lines[i]
    let match = matchlist(line, '^\(#\+\)\s*\(.*\)$')
    
    if !empty(match)
      let level = len(match[1])
      let text = match[2]
      let line_nr = i + 1
      
      call add(headers, {
        \ 'level': level,
        \ 'text': text,
        \ 'line_nr': line_nr
      \ })
    endif
  endfor
  
  return headers
endfunction

function! s:store_headers(headers)
  let b:mdoutline_headers = a:headers
endfunction

function! s:setup_mappings()
  nnoremap <buffer> <silent> <CR> :call <SID>jump_to_header()<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>jump_to_header()<CR>
  nnoremap <buffer> <silent> q :call mdoutline#close()<CR>
  nnoremap <buffer> <silent> r :call mdoutline#refresh()<CR>
endfunction

function! s:jump_to_header()
  if !exists('b:mdoutline_headers')
    return
  endif
  
  let current_line = line('.')
  if current_line > len(b:mdoutline_headers)
    return
  endif
  
  let header = b:mdoutline_headers[current_line - 1]
  let source_win = bufwinnr(s:source_buffer)
  
  if source_win != -1
    execute source_win . 'wincmd w'
    execute header.line_nr
    normal! zz
  endif
endfunction