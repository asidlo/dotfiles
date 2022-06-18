" " If you want to do a global replace, you need to search for the term to add it
" " to the ferret quickfix, then all instances in the quickfix will be subject to
" " the replacement matching when using FerretAcks
" let g:FerretMap = 0
"
" " Searches whole project, even through ignored files
" nnoremap \ :Ack<space>
"
" " Search for current word
" nmap <F6> <Plug>(FerretAckWord)
"
" " Need to use <C-U> to escape visual mode and not enter search
" vmap <F6> :<C-U>call <SID>ferret_vack()<CR>
"
" function! s:ferret_vack() abort
" 	let l:selection = s:get_visual_selection()
" 	for l:char in [' ', '(', ')']
" 		let l:selection = escape(l:selection, l:char)
" 	endfor
" 	execute ':Ack ' . l:selection
" endfunction
"
" " https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript
" function! s:get_visual_selection() abort
" 	let [line_start, column_start] = getpos("'<")[1:2]
" 	let [line_end, column_end] = getpos("'>")[1:2]
" 	let lines = getline(line_start, line_end)
" 	if len(lines) == 0
" 		return ''
" 	endif
" 	let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
" 	let lines[0] = lines[0][column_start - 1:]
" 	return join(lines, "\n")
" endfunction
"
" " Replace instances matching term in quickfix 'F19 == S-F7'
" nmap <S-F6> <Plug>(FerretAcks)
"
