@echo off
doskey ls=exa $*
doskey ll=exa -l $*
doskey cat=bat --style plain --color never $*
doskey jq=jq -C $*
