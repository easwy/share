" vikiLatex.vim -- viki add-on for LaTeX
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     28-Jän-2004.
" @Last Change: 04-Mrz-2006.
" @Revision:    0.164

if &cp || exists("s:loaded_vikiLatex")
    finish
endif
let s:loaded_vikiLatex = 1

fun! VikiSetupBufferLaTeX(state, ...)
    let noMatch = ""
    let b:vikiNameSuffix = '.tex'
    call VikiSetupBuffer(a:state, "sSic")
    let b:vikiAnchorRx   = '\\label{%{ANCHOR}}'
    let b:vikiNameTypes  = substitute(b:vikiNameTypes, '\C[Sicx]', "", "g")
    let b:vikiLaTeXCommands = 'viki\|include\|input\|usepackage\|psfig\|includegraphics\|bibliography\|ref'
    if exists("g:vikiLaTeXUserCommands")
        let b:vikiLaTeXCommands = b:vikiLaTeXCommands .'\|'. g:vikiLaTeXUserCommands
    endif
    if b:vikiNameTypes =~# "s"
        let b:vikiSimpleNameRx         = '\(\\\('. b:vikiLaTeXCommands .'\)\(\[\(.\{-}\)\]\)\?{\(.\{-}\)}\)'
        let b:vikiSimpleNameSimpleRx   = '\\\('. b:vikiLaTeXCommands .'\)\(\[.\{-}\]\)\?{.\{-}}'
        let b:vikiSimpleNameNameIdx    = 2
        let b:vikiSimpleNameDestIdx    = 5
        let b:vikiSimpleNameAnchorIdx  = 4
        let b:vikiSimpleNameCompound = 'let erx="'. escape(b:vikiSimpleNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiSimpleNameNameIdx
                    \ .' | let destIdx='. b:vikiSimpleNameDestIdx
                    \ .' | let anchorIdx='. b:vikiSimpleNameAnchorIdx
    else
        let b:vikiSimpleNameRx        = noMatch
        let b:vikiSimpleNameSimpleRx  = noMatch
        let b:vikiSimpleNameNameIdx   = 0
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 0
    endif
endf

fun! VikiLatexCheckFilename(filename, ...)
    if a:filename != ""
        """ search in the current directory
        let i = 1
        while i <= a:0
            exe "let fn = '".a:filename."'.a:". i
            if filereadable(fn)
                return fn
            endif
            let i = i + 1
        endwh

        """ use kpsewhich
        let i = 1
        while i <= a:0
            exe "let fn = '".a:filename."'.a:". i
            exe "let rv = system('kpsewhich ". fn ."')"
            if rv != ""
                return substitute(rv, "\n", "", "g")
            endif
            let i = i + 1
        endwh
    endif
    return ""
endfun


fun! VikiCompleteSimpleNameDefLaTeX(def)
    let cmd = MvElementAt(a:def, g:vikiDefSep, 0)
    if cmd == g:vikiDefNil
        throw "Viki: Malformed command (no name): ".a:def
    endif
    let dest = MvElementAt(a:def, g:vikiDefSep, 1)
    let opts = MvElementAt(a:def, g:vikiDefSep, 2)
    let part = MvElementAt(a:def, g:vikiDefSep, 3)
    let anchor    = g:vikiDefNil
    let useSuffix = g:vikiDefSep

    if cmd == "input"
        let dest = VikiLatexCheckFilename(dest, "", ".tex", ".sty")
    elseif cmd == "usepackage"
        let dest = VikiLatexCheckFilename(dest, ".sty")
    elseif cmd == "include"
        let dest = VikiLatexCheckFilename(dest, ".tex")
    elseif cmd == "viki"
        let dest = VikiLatexCheckFilename(dest, ".tex")
        let anchor = opts
    elseif cmd == "psfig"
        let f == matchstr(dest, "figure=\zs.\{-}\ze[,}]")
        let dest = VikiLatexCheckFilename(dest, "")
    elseif cmd == "includegraphics"
        let dest = VikiLatexCheckFilename(dest, "", 
                    \ ".eps", ".ps", ".pdf", ".png", ".jpeg", ".jpg", ".gif", ".wmf")
    elseif cmd == "bibliography"
        let n = VikiSelect(dest, ",", "Select Bibliography")
        if n >= 0
            let f    = MvElementAt(dest, ",", n)
            let dest = VikiLatexCheckFilename(f, ".bib")
        else
            let dest = ""
        endif
    elseif cmd == "ref"
        let anchor = dest
        let dest   = g:vikiSelfRef
    elseif exists("*VikiLaTeX_".cmd)
        exe VikiLaTeX_{cmd}(dest, opts)
    else
        throw "Viki LaTeX: unsupported command: ". cmd
    endif
    
    if dest == ""
        throw "Viki LaTeX: can't find: ". cmd ." ". a:def
    else
        return VikiMakeDef(cmd, dest, anchor, part, 'simple')
    endif
endfun

fun! VikiMinorModeLaTeX(state)
    let b:vikiFamily = "LaTeX"
    call VikiMinorMode(a:state)
endf

command! VikiMinorModeLaTeX call VikiMinorModeLaTeX(1)
" au FileType tex let b:vikiFamily="LaTeX"

" vim: ff=unix
