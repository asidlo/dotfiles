"============================================================================
"
" nxlog syntax highlighter
"
" Language:	   nxlog log output
" Version:     $Id: nxlog.vim 14 2006-08-14 16:50:07Z ehaar $
" Maintainer:  Eric Haarbauer <ehaar{DOT}com{AT}grithix{DOT}dyndns{DOT}org>
" License:     This file is placed in the public domain.
"
"============================================================================
" Section:  Initialization  {{{1
"============================================================================

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'nxlog'
endif

" Don't use standard HiLink, it will not work with included syntax files
if version < 508
  command! -nargs=+ NxlogHiLink highlight link <args>
else
  command! -nargs=+ NxlogHiLink highlight default link <args>
endif

" Sync across long inline XML strings.
syntax sync minlines=128
syntax sync maxlines=256

"============================================================================
" Section:  Group Definitions  {{{1
"============================================================================

" Timestamp

" The first line often contains some binary values
syntax match nxlogDate "^\D\{-0,3}\d\{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d\d\d"
    \ nextgroup=nxlogTick skipwhite oneline

syntax match nxlogTick "[-0-9]\+" nextgroup=nxlogLevel contained
    \ oneline skipwhite

" Log Levels

syntax region nxlogLevel start="[A-Z]" end="\zs\s" contained
    \ contains=nxlogLevelError,nxlogLevelWarn,nxlogLevelNormal,nxlogLevelDebug,nxlogLevelTrace
    \ nextgroup=nxlogThread skipwhite oneline

" Include levels from both log4net and java.util.logging
syntax keyword nxlogLevelError  contained SEVERE ERROR FATAL
syntax keyword nxlogLevelWarn   contained WARN WARNING
syntax keyword nxlogLevelNormal contained NOTICE INFO CONFIG
syntax keyword nxlogLevelDebug  contained DEBUG FINE FINER
syntax keyword nxlogLevelTrace  contained TRACE FINEST

" Thread

syntax region nxlogThread start="\S" end="\zs\t"
    \ nextgroup=nxlogMessage skipwhite contained oneline

" Message and Parameters

" Some messages contain EOLs, so permit folding over them
syntax region nxlogMessage start="\S" end="\zs\t" skipwhite contained
    \ contains=nxlogKeyword,nxlogException,nxlogStackLocation
    \ nextgroup=nxlogNestedDebugContext fold

syntax keyword nxlogKeyword contained ENTRY RETURN

" Debug Context

syntax region nxlogNestedDebugContext matchgroup=nxlogNestedDebugContextMarker 
    \ start="\[" end="\]" contained nextgroup=nxlogCategory
    \ skipwhite contains=nxlogNullDebugContext,nxlogNestedBrackets

" Eclipse-generated toString() contains brackets, so don't let them confuse
" NDC parsing.
syntax region nxlogNestedBrackets start="\[" end="\]" contained

syntax match nxlogNullDebugContext "(null)" contained

" Log Category

syntax match nxlogCategory "\S\+" contained

" Exception Trace

syntax match nxlogException "^[0-9A-Za-z_.]\+Exception\ze:"
syntax match nxlogStackLocation "^   at \zs[0-9A-Za-z_.]\+"
    \ nextgroup=nxlogStackSig
syntax region nxlogStackSig start="(" end=")" skipwhite
    \ nextgroup=nxlogStackFile contains=nxlogStackParam contained
syntax match nxlogStackParam "\w\+\ze[&*]\= \w\+" contained
syntax region nxlogStackFile matchgroup=None start="in\s*" end=":line \d\+"
    \ oneline contained nextgroup=nxlogNestedDebugContext skipwhite

"============================================================================
" Section:  Group Linking  {{{1
"============================================================================

if &background == 'light'
    highlight LessImportant ctermfg=DarkGray  guifg=DarkGray
    highlight Unimportant   ctermfg=LightGray guifg=LightGray
else
    highlight LessImportant ctermfg=LightGray guifg=LightGray
    highlight Unimportant   ctermfg=DarkGray  guifg=DarkGray
endif

NxlogHiLink nxlogDate Comment
NxlogHiLink nxlogTick Number

NxlogHiLink nxlogLevelError  Error
NxlogHiLink nxlogLevelWarn   Todo
NxlogHiLink nxlogLevelNormal Keyword
NxlogHiLink nxlogLevelDebug  LessImportant
NxlogHiLink nxlogLevelTrace  Unimportant

NxlogHiLink nxlogThread  Type
NxlogHiLink nxlogKeyword Keyword

NxlogHiLink nxlogNestedDebugContextMarker Operator
NxlogHiLink nxlogNullDebugContext Unimportant
NxlogHiLink nxlogNestedBrackets LessImportant

NxlogHiLink nxlogCategory Special

NxlogHiLink nxlogException     Todo
NxlogHiLink nxlogStackLocation Identifier
NxlogHiLink nxlogStackParam    Type
NxlogHiLink nxlogStackFile     Constant

"============================================================================

" Section:  Clean Up    {{{1
"============================================================================

delcommand NxlogHiLink

let b:current_syntax = "nxlog"

if main_syntax == 'nxlog'
  unlet main_syntax
endif

" Autoconfigure vim indentation settings
" vim:ts=4:sw=4:sts=4:fdm=marker
