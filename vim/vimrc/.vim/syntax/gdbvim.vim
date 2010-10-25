" Vim syntax file
" Language:	gdbvim syntax file
" Maintainer:	<xdegaye at users dot sourceforge dot net>
" Last Change:	Apr 3 2004

if exists("b:current_syntax")
    finish
endif

runtime! syntax/gdb.vim
unlet b:current_syntax

" Highlite lines starting with '(gdb prompt)' or '>'
syn match Prmpt display contained "([^)]\+)"

syn match Command display "^([^)]\+)\|^>"
	\ contains=Prmpt
	\ nextgroup=Cmd skipwhite

syn match Help display "^([^)]\+)\s*h\%[elp]\|^>\s*h\%[elp]"
	\ contains=Prmpt,Cmd
	\ nextgroup=Cmd skipwhite

syn match Info display "^([^)]\+)\s*inf\%[o]\|^([^)]\+)\s*\<i\>\|^>\s*inf\%[o]\|^>\s*\<i\>"
	\ contains=Prmpt,Cmd
	\ nextgroup=Info skipwhite

syn match Show display "^([^)]\+)\s*sho\%[w]\|^>\s*sho\%[w]"
	\ contains=Prmpt,Cmd
	\ nextgroup=ShwSet,Shw skipwhite

syn match Set display "^([^)]\+)\s*set\|^>\s*set"
	\ contains=Prmpt,Cmd
	\ nextgroup=ShwSet,St skipwhite

high def link Prmpt PreProc

let b:current_syntax = "gdbvim"

