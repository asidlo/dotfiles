let s:is_win = has('win32') || has('win64')

if s:is_win
  set runtimepath^=~/vimfiles runtimepath+=~/vimfiles/after
  let &packpath = &runtimepath
  let $MYVIMRC = expand('~/_vimrc')
else
  set runtimepath^=~/.vim runtimepath+=~/.vim/after
  let &packpath = &runtimepath
  let $MYVIMRC = expand('~/.vimrc')
endif

source $MYVIMRC 
