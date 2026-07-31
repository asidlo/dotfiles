@echo off
:: doskey ls=exa $*
:: doskey ll=exa -l $*
doskey ls=ls --color $*
doskey ll=ls -a -l --color $*
doskey rm=del $*
doskey cp=copy $*
doskey cat=bat --style plain --color never $*
doskey ps=pslist.exe $*
doskey kill=pskill.exe $*
doskey which=where.exe $*
doskey jq=jq -C $*
doskey pwd=echo %cd%
doskey k=kubectl $*

set FZF_DEFAULT_COMMAND=fd --type f --type l %FD_OPTS%
set FZF_CTRL_T_COMMAND=%FZF_DEFAULT_COMMAND%

:: NOTE: FZF_DEFAULT_OPTS (fzf colors/layout) is set in fzf.lua via os.setenv,
:: because env changes from this script don't always propagate reliably.
