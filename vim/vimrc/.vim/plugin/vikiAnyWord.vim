" vikiAnyWord.vim
" @Author:      Thomas Link (mailto:samul@web.de?subject=vim-vikiAnyWord)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     04-Apr-2005.
" @Last Change: 16-Feb-2006.
" @Revision:    0.14

if &cp || exists("loaded_vikianyword")
    finish
endif
let loaded_vikianyword = 1

"""" Any Word {{{1
fun! VikiMinorModeAnyWord (state) "{{{3
    let b:vikiFamily = 'AnyWord'
    call VikiMinorMode(a:state)
endfun
command! VikiMinorModeAnyWord call VikiMinorModeAnyWord(1)
command! VikiMinorModeMaybeAnyWord call VikiMinorModeAnyWord(-1)

fun! VikiSetupBufferAnyWord(state, ...) "{{{3
    echom "DBG VikiSetupBufferAnyWord"
    let dontSetup = a:0 > 0 ? a:1 : ''
    call VikiSetupBuffer(a:state, dontSetup)
    if b:vikiNameTypes =~? "s" && !(dontSetup =~? "s")
        if b:vikiNameTypes =~# "S" && !(dontSetup =~# "S")
            let simpleWikiName = b:vikiSimpleNameQuoteBeg
                        \ .'['. b:vikiSimpleNameQuoteChars .']'
                        \ .'\{-}'. b:vikiSimpleNameQuoteEnd
        else
            let simpleWikiName = ""
        endif
        if b:vikiNameTypes =~# "s" && !(dontSetup =~# "s")
            let simple = '\<['. g:vikiUpperCharacters .']['. g:vikiLowerCharacters
                        \ .']\+\(['. g:vikiUpperCharacters.']['.g:vikiLowerCharacters
                        \ .'0-9]\+\)\+\>'
            if simpleWikiName != ""
                let simpleWikiName = simpleWikiName .'\|'. simple
            else
                let simpleWikiName = simple
            endif
        endif
        let anyword = '\<['. b:vikiSimpleNameQuoteChars .' ]\+\>'
        if simpleWikiName != ""
            let simpleWikiName = simpleWikiName .'\|'. anyword
        else
            let simpleWikiName = anyword
        endif
        let b:vikiSimpleNameRx = '\C\(\(\<['. g:vikiUpperCharacters .']\+::\)\?'
                    \ .'\('. simpleWikiName .'\)\)'
                    \ .'\(#\('. b:vikiAnchorNameRx .'\)\>\)\?'
        let b:vikiSimpleNameSimpleRx = '\C\(\<['.g:vikiUpperCharacters.']\+::\)\?'
                    \ .'\('. simpleWikiName .'\)'
                    \ .'\(#'. b:vikiAnchorNameRx .'\>\)\?'
        let b:vikiSimpleNameNameIdx   = 1
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 6
        let b:vikiSimpleNameCompound = 'let erx="'. escape(b:vikiSimpleNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiSimpleNameNameIdx
                    \ .' | let destIdx='. b:vikiSimpleNameDestIdx
                    \ .' | let anchorIdx='. b:vikiSimpleNameAnchorIdx
    endif
    let b:vikiInexistentHighlight = "vikiAnyWordInexistentLink"
    let b:vikiMarkInexistent = 2
endf

fun! VikiDefineMarkupAnyWord(state) "{{{3
    if b:vikiNameTypes =~? "s" && b:vikiSimpleNameRx != ""
        exe "syn match vikiRevLink /" . b:vikiSimpleNameRx . "/"
    endif
    if b:vikiNameTypes =~# "e" && b:vikiExtendedNameRx != ""
        exe "syn match vikiRevExtendedLink '" . b:vikiExtendedNameRx . "'"
    endif
    if b:vikiNameTypes =~# "u" && b:vikiUrlRx != ""
        exe "syn match vikiURL /" . b:vikiUrlRx . "/"
    endif
endfun

fun! VikiDefineHighlightingAnyWord(state, ...) "{{{3
    let dontSetup = a:0 > 0 ? a:1 : ''
    call VikiDefineHighlighting(a:state)
    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif
    exec 'VikiHiLink '. b:vikiInexistentHighlight .' Normal'
    delcommand VikiHiLink
endf

fun! VikiFindAnyWord(flag, ...) "{{{3
    let rx = VikiRxFromCollection(b:vikiNamesOk)
    let i  = a:0 >= 1 ? a:1 : 0
    call VikiFind(a:flag, i, rx)
endfun


