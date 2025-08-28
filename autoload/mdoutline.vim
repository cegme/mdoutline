" mdoutline.vim - Autoload functions for markdown outline viewer
" Maintainer: Christan Grant <https://github.com/cegme>

let s:outline_buffer = -1
let s:outline_window = -1
let s:source_buffer = -1
let s:show_help = 0

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
  call s:setup_buffer_autocommands()
  
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
  
  " Reset all outline-related variables
  let s:outline_buffer = -1
  let s:outline_window = -1
  let s:show_help = 0
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
  if &filetype == 'markdown' && !s:is_outline_open() && s:can_open_outline()
    call mdoutline#open()
  endif
endfunction

function! mdoutline#buffer_cleanup()
  " Only clean up if the current buffer is the markdown source buffer,
  " not the outline buffer itself
  if s:source_buffer == bufnr('%') && s:source_buffer != s:outline_buffer
    let s:recently_closed = localtime()
    call mdoutline#close()
  endif
endfunction

function! s:is_outline_open()
  return s:outline_buffer != -1 && bufexists(s:outline_buffer)
endfunction

function! s:can_open_outline()
  " Don't open if we're in the middle of closing windows
  if exists('g:leaving') && g:leaving
    return 0
  endif
  
  " Don't open if there's only one window (likely closing the last one)
  if winnr('$') == 1 && winwidth(0) < 50
    return 0
  endif
  
  " Don't open immediately after a buffer delete/wipe event
  if exists('s:recently_closed') && (localtime() - s:recently_closed) < 1
    return 0
  endif
  
  return 1
endfunction

function! s:populate_outline()
  if !bufexists(s:source_buffer)
    return
  endif
  
  setlocal modifiable
  %delete _
  
  let lines = []
  
  " Add help text if enabled
  if s:show_help
    let help_lines = s:get_help_text()
    call extend(lines, help_lines)
  endif
  
  let headers = s:get_headers()
  
  if empty(headers)
    if !s:show_help
      call add(lines, "No headers found")
      if len(lines) == 0
        call add(lines, "Press ? for help")
      endif
    else
      call add(lines, "No headers found")
    endif
  else
    " Add header lines
    for header in headers
      let indent = repeat('  ', header.level - 1)
      let line = indent . header.text
      call add(lines, line)
    endfor
  endif
  
  " Add help hint if not showing help and there are headers
  if !s:show_help && !empty(headers)
    call insert(lines, "Press ? for help", 0)
    call insert(lines, "", 1)
  endif
  
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
  nnoremap <buffer> <silent> ? :call <SID>toggle_help()<CR>
endfunction

function! s:setup_buffer_autocommands()
  augroup MDOutlineBuffer
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call s:outline_buffer_closed()
  augroup END
endfunction

function! s:outline_buffer_closed()
  " Reset variables when outline buffer is closed directly
  let s:outline_buffer = -1
  let s:outline_window = -1
  let s:show_help = 0
endfunction

function! s:jump_to_header()
  if !exists('b:mdoutline_headers') || s:show_help
    return
  endif
  
  let current_line = line('.')
  let offset_lines = 0
  
  " Account for help hint lines when not showing full help
  if !s:show_help && !empty(b:mdoutline_headers)
    let offset_lines = 2  " "Press ? for help" + empty line
  endif
  
  let header_line = current_line - offset_lines
  
  if header_line <= 0 || header_line > len(b:mdoutline_headers)
    return
  endif
  
  let header = b:mdoutline_headers[header_line - 1]
  let source_win = bufwinnr(s:source_buffer)
  
  if source_win != -1
    execute source_win . 'wincmd w'
    execute header.line_nr
    normal! zz
  endif
endfunction

function! s:toggle_help()
  let s:show_help = !s:show_help
  call s:populate_outline()
endfunction

function! s:get_help_text()
  return [
    '" ====== MDOutline Help ======',
    '" ? : toggle this help',
    '" <enter> : jump to header',
    '" <2-click> : jump to header', 
    '" r : refresh outline',
    '" q : close outline window',
    '" ============================',
    ''
  ]
endfunction

function! s:get_help_line_count()
  return len(s:get_help_text())
endfunction