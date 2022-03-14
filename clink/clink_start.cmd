@echo off
doskey ls=exa $*
doskey ll=exa -l $*
doskey cat=bat --style plain --color never $*
doskey jq=jq -C $*
doskey pwd=echo %cd%
doskey k=kubectl $*

set FZF_DEFAULT_COMMAND="git ls-files --cached --others --exclude-standard 2>nul | fd --type f --type l %FD_OPTS%"
set FZF_CTRL_T_COMMAND=%FZF_DEFAULT_COMMAND%
