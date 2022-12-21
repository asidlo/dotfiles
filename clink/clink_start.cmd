@echo off
:: doskey ls=exa $*
:: doskey ll=exa -l $*
doskey ls=dir /W $*
doskey ll=dir $*
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
