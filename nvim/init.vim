let s:is_win = has('win32') || has('win64')

if s:is_win
  set runtimepath^=~/vimfiles runtimepath+=~/vimfiles/after
  let &packpath = &runtimepath
  source ~/_vimrc
else
  set runtimepath+=~/.vim,~/.vim/after
  set packpath+=~/.vim
  source ~/.vimrc
endif
