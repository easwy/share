" Vim indent file
" Language:		Scala
" Maintainer:		Easwy Yang <easwy.mail@gmail.com>
" Original Author:	David Bustos <bustos@caltech.edu>
" Last Change:		Thu May 13 11:51:34 CST 2010 

" This indent file is based on the python indent file in Vim 7.2,
" which original written by David Bustos <bustos@caltech.edu> and
" maintained by Bram Moolenaar <Bram@vim.org>.

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Some preliminary settings
setlocal nolisp		" Make sure lisp indenting doesn't supersede us
setlocal autoindent	" indentexpr isn't much help otherwise
setlocal shiftwidth=2   " Scala recommend 2 spaces

setlocal indentexpr=GetScalaIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,<>>,<CR>,=*/,=extends,=with
setlocal debug="msg,throw"

" Only define the function once.
"if exists("*GetScalaIndent")
"  finish
"endif

" Come here when loading the script the first time.

let s:maxoff = 50	" maximum number of lines to look backwards for ()

function! CountParens(line)
  let line = substitute(a:line, '"\(.\|\\"\)*"', '', 'g')
  let open = substitute(line, '[^[(]', '', 'g')
  let close = substitute(line, '[^])]', '', 'g')
  return strlen(open) - strlen(close)
endfunction

" Count the open parensis numbers on the current line (before cursor)
function! OpenParensBeforeCursor()
  let stopline = line(".")
  let num = 0
  while searchpair('(\|\[', '', ')\|\]', 'bW',
          \ " synIDattr(synID(line('.'), col('.'), 1), 'name')"
          \ . " =~ '\\(Comment\\|String\\)$'", stopline) > 0
    let num = num + 1
  endwhile

  return num
endfunction

" Find the line number of the first open parensis at
function! FirstOpenParensBeforeLine(lnum)
  let flnum = a:lnum
  call cursor(a:lnum, 1)
  let openlnum = searchpair('(\|\[', '', ')\|\]', 'bW',
	  \ "line('.') < " . (a:lnum - s:maxoff) . " ? 0 :"
          \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
          \ . " =~ '\\(Comment\\|String\\)$'")
  while openlnum > 0
    let flnum = openlnum
    let openlnum = searchpair('(\|\[', '', ')\|\]', 'bW',
	  \ "line('.') < " . (a:lnum - s:maxoff) . " ? 0 :"
	  \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
	  \ . " =~ '\\(Comment\\|String\\)$'")
  endwhile

  return flnum
endfunction

" Get the line and remove a trailing comment.
function! GetLineWithoutTailingComments(lnum)
  let pline = getline(a:lnum)
  let pline_len = strlen(pline)
  " If the last character in the line is a comment, do a binary search for
  " the start of the comment.  synID() is slow, a linear search would take
  " too long on a long line.
  if synIDattr(synID(plnum, pline_len, 1), "name") =~ "Comment$"
    let min = 1
    let max = pline_len
    while min < max
      let col = (min + max) / 2
      if synIDattr(synID(plnum, col, 1), "name") =~ "Comment$"
        let max = col
      else
        let min = col + 1
      endif
    endwhile
    let pline = strpart(pline, 0, min - 1)
  endif

  return pline
endfunction

function! GetScalaIndent()

  " If the start of the line is in a string or a comment don't change the indent.
  if has('syntax_items')
        \ && synIDattr(synID(v:lnum, 1, 1), "name") =~ "\%(String\|Comment)$"
      return -1
  endif

  " Search backwards for the previous non-empty line.
  let plnum = prevnonblank(v:lnum - 1)

  if plnum == 0
    " This is the first non-empty line, use zero indent.
    return 0
  endif

  " If the previous line is inside parenthesis, use the indent of the starting
  " line if previous line doesn't insert any parenthesis.
  call cursor(plnum, 1)
  let parlnum = searchpair('(\|\[', '', ')\|\]', 'nbW',
	  \ "line('.') < " . (plnum - s:maxoff) . " ? 0 :"
	  \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
	  \ . " =~ '\\(Comment\\|String\\)$'")

  " If found, use the indent of this line
  if parlnum > 0
    let plindent = indent(parlnum)
    let plnumstart = parlnum
  else " Otherwise, use the indent of the previous line
    let plindent = indent(plnum)
    let plnumstart = plnum
  endif


  " If previous line inserts parenthesis, calculates indent based on the
  " indent of previous open parenthesis
  call cursor(v:lnum, 1)
  let p = searchpair('(\|\[', '', ')\|\]', 'bW',
	  \ "line('.') < " . (plnum - s:maxoff) . " ? 0 :"
	  \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
	  \ . " =~ '\\(Comment\\|String\\)$'")
  if p > 0
    if getline(v:lnum) =~ '^\s*\%()\|\]\)'
      let parnum = OpenParensBeforeCursor()
    else
      let parnum = OpenParensBeforeCursor() + 1
    endif
    let ind = indent(p) + (parnum * &sw)
  elseif parlnum > 0
    let flnum = FirstOpenParensBeforeLine(parlnum)
    let ind = indent(flnum)
  else
    let ind = indent(plnum)
  endif

  let pline = GetLineWithoutTailingComments(plnum)

  " If previous line is class definition, re-indent
  if pline =~ '^\s*\%(extends\|with\)\s.*{\s*$'
    let cstart = search('\<\%(class\>\|object\>\)', 'bW')
    if cstart > 0
      return indent(cstart) + &sw
    endif
  endif

  " If previous line inserts open brace, add extra indent
  call cursor(v:lnum, 1)
  let p = searchpair('{', '', '}', 'bW',
	  \ "line('.') < " . plnum . " ? 0 :"
	  \ . " synIDattr(synID(line('.'), col('.'), 1), 'name')"
	  \ . " =~ '\\(Comment\\|String\\)$'")
  if p == plnum
    let ind = ind + &sw
  else
    " If previous line contains if/else if/for/while/else and unfinished
    " var/val/def, add indent
    if  pline =~ '^\s*\%(\%(else \+\)\?if\>\|for\>\|while\>\)\s*(.*)\s*$'
          \ || pline =~ '^\s*\%(va[lr]\|def\)\>.*=\s*$'
          \ || pline =~ '^\s*else\s*$'
      let ind = ind + &sw
    endif

    " If the previous line is in a single line statement, recover the indent
    let pplnum = prevnonblank(plnum - 1)
    let ppline = GetLineWithoutTailingComments(pplnum)
    if  ppline =~ '^\s*\%(\%(else \+\)\?if\>\|for\>\|while\>\)\s*(.*)\s*$'
          \ || ppline =~ '^\s*\%(va[lr]\|def\)\>.*=\s*$'
          \ || ppline =~ '^\s*else\s*$'
      let ind = ind - &sw
    endif

    " For class definition
    if curline =~ '^\s*\%(extends\|with\)'
          \ && pline !~ '^\s*\%(extends\|with\)'
      let ind = ind + (&sw * 3)
    endif

    " If the previous line ended with some punctuations, indent this line
    "if pline =~ '[.+-*/%><=&|^~!:#@$`?]\s*$'
    "  let ind = indent(plnum) + (exists("g:scindent_continuous_line") ? eval(g:scindent_continuous_line) : (&sw * 2))
    "endif

  endif

  let curline = getline(v:lnum)
  " For close brace on the beginning of line
  if curline =~ '^\s*}'
    let ind = ind - &sw
  endif

  return ind

"  " If the previous line was a stop-execution statement...
"  if getline(plnum) =~ '^\s*\(break\|continue\|raise\|return\|pass\)\>'
"    " See if the user has already dedented
"    if indent(v:lnum) > indent(plnum) - &sw
"      " If not, recommend one dedent
"      return indent(plnum) - &sw
"    endif
"    " Otherwise, trust the user
"    return -1
"  endif

"  " If the current line begins with a keyword that lines up with "try"
"  if getline(v:lnum) =~ '^\s*\(except\|finally\)\>'
"    let lnum = v:lnum - 1
"    while lnum >= 1
"      if getline(lnum) =~ '^\s*\(try\|except\)\>'
"	let ind = indent(lnum)
"	if ind >= indent(v:lnum)
"	  return -1	" indent is already less than this
"	endif
"	return ind	" line up with previous try or except
"      endif
"      let lnum = lnum - 1
"    endwhile
"    return -1		" no matching "try"!
"  endif

"    " Or the user has already dedented
"    if indent(v:lnum) <= plindent - &sw
"      return -1
"    endif
"
"    return plindent - &sw
"  endif

  " When after a () construct we probably want to go back to the start line.
  " a = (b
  "       + c)
  " here
  "if parlnum > 0
  "  return plindent
  "endif

  return ind

endfunction

" vim:sw=2
