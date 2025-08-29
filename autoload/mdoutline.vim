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
  
  " Mark this as an outline buffer
  let b:mdoutline_buffer = 1
  
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
  " Skip if we're in the outline buffer itself
  if exists('b:mdoutline_buffer') && b:mdoutline_buffer
    return
  endif
  
  if &filetype == 'markdown' && !s:is_outline_open() && s:can_open_outline()
    call mdoutline#open()
  endif
endfunction

function! mdoutline#buffer_cleanup()
  let current_buf = bufnr('%')
  
  " Only clean up if:
  " 1. The current buffer is the markdown source buffer
  " 2. The current buffer is not the outline buffer itself
  " 3. The outline buffer actually exists and is open
  if current_buf == s:source_buffer && 
     \ current_buf != s:outline_buffer && 
     \ s:is_outline_open()
    let s:recently_closed = localtime()
    call mdoutline#close()
  endif
endfunction

function! mdoutline#check_last_buffer()
  " Skip if outline is not open
  if !s:is_outline_open()
    return
  endif
  
  " Skip if the buffer being closed is the outline buffer itself
  if bufnr('%') == s:outline_buffer
    return
  endif
  
  " Check if any main buffers remain (excluding special buffers)
  if !s:has_main_buffers()
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

function! s:has_main_buffers()
  " Check if there are any buffers that are considered "main" buffers
  " (i.e., not special buffers like outline, help, quickfix, etc.)
  for bufnr in range(1, bufnr('$'))
    if !buflisted(bufnr) || !bufexists(bufnr)
      continue
    endif
    
    " Skip the outline buffer itself
    if bufnr == s:outline_buffer
      continue
    endif
    
    " Get buffer info
    let buftype = getbufvar(bufnr, '&buftype', '')
    let filetype = getbufvar(bufnr, '&filetype', '')
    
    " Skip special buffer types
    if buftype == 'nofile' || buftype == 'quickfix' || buftype == 'help'
      continue
    endif
    
    " Skip certain special filetypes
    if filetype == 'qf' || filetype == 'help' || filetype == 'netrw'
      continue
    endif
    
    " Skip buffers marked as outline buffers
    if getbufvar(bufnr, 'mdoutline_buffer', 0)
      continue
    endif
    
    " Found a main buffer
    return 1
  endfor
  
  " No main buffers found
  return 0
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
  " Only reset if this is actually our outline buffer
  if bufnr('%') == s:outline_buffer
    let s:outline_buffer = -1
    let s:outline_window = -1
    let s:show_help = 0
    let s:recently_closed = localtime()
  endif
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
  let help_lines = []
  call add(help_lines, '" ====== MDOutline Help ======')
  call add(help_lines, '" ? : toggle this help')
  call add(help_lines, '" <enter> : jump to header')
  call add(help_lines, '" <2-click> : jump to header')
  call add(help_lines, '" r : refresh outline')
  call add(help_lines, '" q : close outline window')
  call add(help_lines, '" ============================')
  call add(help_lines, '')
  return help_lines
endfunction

function! s:get_help_line_count()
  return len(s:get_help_text())
endfunction