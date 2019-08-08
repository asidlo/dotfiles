" syn match gitLgLine /^[_\*|\/\\ ]\+\(\<\x\{4,40\}\>.*\)\?$/
" syn match gitLgHead /^[_\*|\/\\ ]\+\(\<\x\{4,40\}\> - ([^)]\+)\( ([^)]\+)\)\? \)\?/ contained containedin=gitLgLine
" syn match gitLgDate /(\u\l\l \u\l\l \d\=\d \d\d:\d\d:\d\d \d\d\d\d)/ contained containedin=gitLgHead nextgroup=gitLgRefs skipwhite
" syn match gitLgRefs /([^)]*)/ contained containedin=gitLgHead
" " syn match gitLgDate /([^)]*)/ contained containedin=gitLgHead nextgroup=gitLgRefs skipwhite
" syn match gitLgGraph /^[_\*|\/\\ ]\+/ contained containedin=gitLgHead,gitLgCommit nextgroup=gitHashAbbrev skipwhite
" syn match gitLgCommit /^[^-]\+- / contained containedin=gitLgHead nextgroup=gitLgDate skipwhite
" syn match gitLgIdentity /<[^>]*>$/ contained containedin=gitLgLine

" Looks for 7 digit hash at beginning of line that may or may not be prefaced
" with an '*' character
" syntax match gitLgOnelineHash /^[\* ]*[a-zA-Z0-9]\{7}/ nextgroup=gitLgOnelineDate 
syntax match gitLgOnelineHash /^[\* ]*[a-zA-Z0-9]\{7,40}/ 
hi def link gitLgOnelineHash gitReference

syntax match gitLgOnelineDate /([a-zA-Z0-9\:\- ]*)/
hi def link gitLgOnelineDate gitDate

syntax match gitLgOnelineTags /([a-zA-Z\->, \/]*)/
hi def link gitLgOnelineTags gitTag

syntax match gitLgOnelineAuthor /<[a-zA-Z ]\+>$/
hi def link gitLgOnelineAuthor gitIdentity

" hi def link gitLgGraph Comment
" hi def link gitLgDate gitDate
" hi def link gitLgRefs gitReference
" hi def link gitLgIdentity gitIdentity
