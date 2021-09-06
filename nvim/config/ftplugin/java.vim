compiler javac
command! -buffer JavaImports :call <SID>java_format_imports()
command! -buffer -range JavaFormat <line1>,<line2>call <SID>java_format_cmd()

function! s:java_format_imports() abort
  let save_cursor = getcurpos()
  let s:cmd = 'google-java-format.sh -a --fix-imports-only ' . expand('%:p')
  let s:lines = systemlist(s:cmd)
  if !v:shell_error
    call setline(1, s:lines)
  else
    call setqflist([], 'r', {'context': {'cmd': s:cmd}, 'lines': s:lines})
    if len(getqflist()) != 0
      cfirst
    endif
  endif
  call setpos('.', save_cursor)
endfunction

function! s:java_format_cmd() range abort
  let save_cursor = getcurpos()
  if a:firstline == a:lastline
    echom 'Formatting file: ' . expand('%:p')
    let s:cmd = 'google-java-format.sh -a --skip-sorting-imports --skip-removing-unused-imports ' . expand('%:p')
  else
    echom 'Formatting lines[' . a:firstline . ' - ' . a:lastline . ']' . ' from file: ' . expand('%:p')
    let s:cmd = 'google-java-format.sh -a --skip-sorting-imports --skip-removing-unused-imports --lines ' . a:firstline . ':' . a:lastline . ' ' . expand('%:p')
  endif

  let s:lines = systemlist(s:cmd)
  if !v:shell_error
    %delete " delete whole file buffer
    call setline(1, s:lines)
  else
    call setqflist([], 'r', {'context': {'cmd': s:cmd}, 'lines': s:lines})
    if len(getqflist()) != 0
      cfirst
    endif
  endif
  call setpos('.', save_cursor)
endfunction

" function! JavaFormatexpr() abort
"   call setqflist([])
"   let s:endline = v:lnum + v:count - 1
"   let s:cmd = 'google-java-format.sh -a --skip-sorting-imports --skip-removing-unused-imports --lines ' . v:lnum . ':' . s:endline . ' ' . expand('%:p')
"   let s:lines = systemlist(s:cmd)
"   if !v:shell_error
"     call setline(1, s:lines)
"   else
"     call setqflist([], 'r', {'context': {'cmd': s:cmd}, 'lines': s:lines})
"     if len(getqflist()) != 0
"       cfirst
"     endif
"   endif
" endfunction
