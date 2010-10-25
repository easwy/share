"=============================================================================
" File: cscope_win.vim
" Author: Shivakumar T (shivatg@yahoo.co.uk)
" Last Change:	2006 Mar 10
" Version: 2.0
"-----------------------------------------------------------------------------

if exists('csWinLoaded')
    finish
endif
let csWinLoaded=1

" Option to specify whether new search results should be appended
" to the previous results
" 0 => Don't append
" 1 => Append
if !exists('csAppendResults')
    let csAppendResults = 1
endif

" Option to specify the maximum number of cscope connections
if !exists('csMaxConn')
    let csMaxConn=8
endif

" Option to specify whether search should be case sensitive
" 1  => case sensitive
" 0  => case insensitive
" -1 => decide based on 'ignorecase' option in vim
if !exists('csCaseSensitive')
    let csCaseSensitive=-1
endif

" Option to specify the cscope window height
if !exists('csWinSize')
    let csWinSize=15
endif

let s:Cscope_Tag=""
let s:bufnum=1

nmap <silent><C-\>s :call <SID>CSWin_Process_Key('0')<cr>
nmap <silent><C-\>g :call <SID>CSWin_Process_Key('1')<cr>
nmap <silent><C-\>d :call <SID>CSWin_Process_Key('2')<cr>
nmap <silent><C-\>c :call <SID>CSWin_Process_Key('3')<cr>
nmap <silent><C-\>t :call <SID>CSWin_Process_Key('4')<cr>
nmap <silent><C-\>e :call <SID>CSWin_Process_Key('6')<cr>
nmap <silent><C-\>f :call <SID>CSWin_Process_Key('7')<cr>
nmap <silent><C-\>i :call <SID>CSWin_Process_Key('8')<cr>

nmap <silent><C-\>\ :call <SID>CSWin_Toggle_Option()<cr>

autocmd BufEnter *.[ch] silent call s:Cscope_Init()
autocmd VimEnter * silent call s:CS_db_init()
autocmd VimLeave * silent! call delete(s:tmpfile_2)

function! s:Cscope_Init()
    let s:bufnum=bufnr("%")
    return
endfunction

function! s:CS_db_init()
    let i=0
    while i<g:csMaxConn
        let s:cscope_{i}_db_filename=''
        let s:cscope_{i}_db_prep_path=''
        let s:cscope_{i}_db_flags=''
        let s:cs_slot_{i}_used=0
        let i=i+1
    endwhile
    let s:tmpfile_2=tempname()
    exe 'set tags=' . s:tmpfile_2
endfunction

function! s:CSWin_Process_Cmd(option,var)
    let s:Cscope_Tag = a:var

    let winnum = bufwinnr("__CSWIN__")
    let curwin = winnr()

    let old_report = &report
    set report=99999

    if winnum == -1
        exe 'silent! rightbelow ' . g:csWinSize . 'split __CSWIN__'
        setlocal nowrap
        setlocal nonu
        setlocal nobuflisted
        setlocal buftype=nofile
        setlocal bufhidden=delete
        setlocal noswapfile
        setlocal modifiable
        setlocal foldenable
        setlocal foldmethod=manual
        setlocal foldcolumn=2
        nnoremap <buffer> <silent> <enter> :call <SID>CSWin_Process_Enter()<cr>
        nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>CSWin_Process_Enter()<CR>

        if hlexists('DefCscopeTagName')
            hi link CscopeTagName DefCscopeTagName
        else
            hi link CscopeTagName Title
        endif

        if hlexists('DefCscopeFileName')
            hi link CscopeFileName DefCscopeFileName
        else
            hi link CscopeFileName Visual
        endif

        if hlexists('DefCscopeFunc')
            hi link CscopeFunc DefCscopeFunc
        else
            hi link CscopeFunc WarningMsg
        endif

        if hlexists('DefCscopeUnknown')
            hi link CscopeUnknown DefCscopeUnknown
        else
            hi link CscopeUnknown WarningMsg
        endif

        if hlexists('DefCscopeCurrLine')
            hi link CscopeCurrLine DefCscopeCurrLine
        else
            hi link CscopeCurrLine Search
        endif

        if hlexists('DefCscopeTagLineNr')
            hi link CscopeLine CscopeTagLineNr
        else
            hi link CscopeLine LineNr
        endif

        if hlexists('DefCscopeTag')
            hi link CscopeTag DefCscopeTag
        else
            hi link CscopeTag Type
        endif

        syntax region CscopeTagName start="^Cscope tag: "hs=s end="$"he=e
        syntax region CscopeFileName start="^\s*\d\+\s\+" end="$"he=e
        syntax match CscopeFunc /<.\{-}>/
        syntax match CscopeUnknown /<<.\{-}>>/
        syntax match CscopeTagLineNr /\[[0-9]\+\]/
    else
        wincmd b
        setlocal modifiable
        if g:csAppendResults==0
            silent! %delete _
        else
            silent! %foldclose
            exe "$"
            normal! o
        endif
    endif

    match none

    let currline=line(".")
    let count1=currline-1
    let count2=1
    let prev_path=""
    let app_str="Cscope tag: " . a:var
    call append(count1,app_str)
    let count1=count1+1
    let i=0

    if g:csCaseSensitive==-1
        if &ic==1
            let cs_ic_option=" -C"
        else
            let cs_ic_option=""
        endif
    else
        if g:csCaseSensitive==0
            let cs_ic_option=" -C"
        else
            let cs_ic_option=""
        endif
    endif

    while i<g:csMaxConn
        if s:cs_slot_{i}_used==1
            let cs_cmd=&csprg . cs_ic_option . " -d -L -f " . s:cscope_{i}_db_filename . " -" . a:option . a:var . " | sort -k 3,3 -g | sort -s -k 1,1"
            let output=system(cs_cmd) 

            while output != ''
                let line_pos=stridx(output,"\n")
                "entire line
                let curr_line=strpart(output, 0, line_pos)

                if match(curr_line,'\S\+\s\+\S\+\s\+\d\+\s\+.*')==-1
                    let output=strpart(output,line_pos+1)
                    continue
                endif

                "extract file complete path
                let idx=stridx(curr_line," ")
                let full_path=strpart(curr_line,0,idx)

                let file_name=fnamemodify(full_path,":t")
                let term_slash=''
                if s:cscope_{i}_db_prep_path != ''
                    let term_char=strpart(s:cscope_{i}_db_prep_path,strlen(s:cscope_{i}_db_prep_path)-1,1)
                    if (term_char!='/') && (term_char!='\')
                        let term_slash='/'
                    endif
                endif
                let file_loc=s:cscope_{i}_db_prep_path .term_slash. fnamemodify(full_path,":h")
                "shift line to next field
                let curr_line=strpart(curr_line,idx+1)

                "extract sym
                let idx=stridx(curr_line," ")
                let sym=strpart(curr_line,0,idx)

"                if match(sym,"<.*>")==-1
                    let sym="<" . sym . ">"
"                endif

                "shift line to next field
                let curr_line=strpart(curr_line,idx+1)

                "extract line number
                let idx=stridx(curr_line," ")
                let line_num=strpart(curr_line,0,idx)

                "shift line to next field
                let descr=strpart(curr_line,idx+1)
                let output=strpart(output,line_pos+1)
                if prev_path!=full_path
                    call append(count1,count2 . "\t" . file_name." (".file_loc.")")
                    let count1=count1+1
                    let count2=count2+1
                endif
                let num_str="[".line_num."]"
                let wspace_len=7-strlen(num_str)
                if wspace_len<1
                    let wspace_len=1
                endif
                let wspace_str=strpart("       ",0,wspace_len)
                let app_str=wspace_str.num_str . " " . sym
                let wspace_len=40-strlen(app_str)
                if wspace_len<1
                    let wspace_len=1
                endif
                let wspace_str=strpart("                                        ",0,wspace_len)
                call append(count1,app_str . wspace_str . descr)
                let count1=count1+1
                let prev_path=full_path
            endwhile
        endif
        let i=i+1
    endwhile

    if count2<2
        silent! $-1,$ delete _
        echohl WarningMsg | echo "Tag" a:var "not found" | echohl None
        return
    endif

    let lastline=line(".")
    let sec_lastline=lastline-1
    exe currline

    setlocal nomodifiable

    exe 'syntax match CscopeTag /' . a:var . '/'

    exe currline "," . sec_lastline . " fold"
    normal! zv
    let &report = old_report
    return
endfunction

function! s:CSWin_Process_Key(option)
    if bufname("%") == "__CSWIN__"
        return
    endif

    if((a:option=='f') || (a:option=='i'))
        let ident=expand("<cfile>:t")
    else
        let ident=expand("<cword>")
    endif

    call s:CSWin_Process_Cmd(a:option,ident)
    return
endfunction

function! s:CSWin_Process_Enter()
    if bufname("%") != "__CSWIN__"
        return
    endif

    let linenum=line(".")
    let tcount=linenum

    if (match(getline(linenum),'^\s*$')==0)
        return
    endif

    if (match(getline(linenum),'^Cscope tag: .*$')==0)
        return
    endif

    while tcount && (match(getline(tcount),'^\d\+.*')==-1)
        let tcount=tcount-1
    endwhile
    if tcount==0
        return
    endif

    let curline=getline(tcount)
    let tfile=substitute(curline,'^\d\+\s\+\([^[:space:]]\+\) (\([^)]\+\))$','\2\/\1',0)

    if tcount==linenum
        let tline=1
    else
        let tline=substitute(getline(linenum),'\s*\[\([0-9]\+\)\].*$','\1',0)
    endif

    exe 'match CscopeCurrLine /\%'.linenum.'l/'

    exe 'redir! > ' . s:tmpfile_2
    exe "silent echo \'" . s:Cscope_Tag . "\t" . tfile . "\t" . tline . "\'"
    exe 'redir END'
    exe bufwinnr(s:bufnum) . 'wincmd w'
    exe 'tj ' . s:Cscope_Tag
    normal zz
endfunction

function! s:CSWin_Toggle_Option()
    if g:csAppendResults==1
        let g:csAppendResults=0
    else
        let g:csAppendResults=1
    endif
endfunction

function! s:CS_cmd_Help()
    echo "cscope commands:"
    echo "add  : Add a new database             (Usage: add file|dir [pre-path])"
    echo "find : Query for a pattern            (Usage: find s|g|d|c|t|e|f|i name)"
    echo "       s: Find this C symbol"
    echo "       g: Find this definition"
    echo "       d: Find functions called by this function"
    echo "       c: Find functions calling this function"
    echo "       t: Find assignments to"
    echo "       e: Find this egrep pattern"
    echo "       f: Find this file"
    echo "       i: Find files #including this file"
    echo "help : Show this message              (Usage: help)"
    echo "kill : Kill a connection              (usage: kill #)"
    echo "show : Show connections               (Usage: show)"
endfunction

function! s:CS_cmd(...)
    if a:0==0
        call s:CS_cmd_Help()
        return
    endif

    let nargs=a:0
    let arg2=''
    let arg3=''
    let arg4=''

    if nargs>1
        let arg2=a:2
    endif

    if nargs>2
        let arg3=a:3
    endif

    if nargs>3
        let arg4=a:4
    endif

    if a:1=='find'
        call s:CS_handle_find(nargs, arg2, arg3)
        return
    endif

    if a:1=='add'
        call s:CS_handle_add(nargs, arg2, arg3, arg4)
        return
    endif

    if a:1=='kill'
        call s:CS_handle_kill(nargs, arg2)
        return
    endif

    if a:1=='show'
        call s:CS_handle_show(nargs)
        return
    endif
    call s:CS_cmd_Help()
    return
endfunction

function! s:CS_handle_find(nargs, cs_option,var)
    if (a:nargs!=3)
        call s:CS_cmd_Help()
        return
    endif

    if (a:cs_option=='s') || (a:cs_option=='0')
        call s:CSWin_Process_Cmd('0',a:var)
        return
    endif

    if (a:cs_option=='g') || (a:cs_option=='1')
        call s:CSWin_Process_Cmd('1',a:var)
        return
    endif

    if (a:cs_option=='d') || (a:cs_option=='2')
        call s:CSWin_Process_Cmd('2',a:var)
        return
    endif

    if (a:cs_option=='c') || (a:cs_option=='3')
        call s:CSWin_Process_Cmd('3',a:var)
        return
    endif

    if (a:cs_option=='t') || (a:cs_option=='4')
        call s:CSWin_Process_Cmd('4',a:var)
        return
    endif

    if (a:cs_option=='e') || (a:cs_option=='6')
        call s:CSWin_Process_Cmd('6',a:var)
        return
    endif

    if (a:cs_option=='f') || (a:cs_option=='7')
        call s:CSWin_Process_Cmd('7',a:var)
        return
    endif

    if (a:cs_option=='i') || (a:cs_option=='8')
        call s:CSWin_Process_Cmd('8',a:var)
        return
    endif

    call s:CS_cmd_Help()
    return
endfunction

function! s:CS_handle_add(nargs,db_filename,prep_path,flags)

    if (a:nargs<2) || (a:nargs>4)
        call s:CS_cmd_Help()
        return
    endif

    if isdirectory(a:db_filename)==1
        let db_filename=fnamemodify(a:db_filename,":p:h") . "/cscope.out"
    else
        let db_filename=a:db_filename
    endif

    if filereadable(db_filename)==0
        echo db_filename
        call s:CS_cmd_Help()
        return
    endif

    if (a:nargs>2) && (isdirectory(a:prep_path)==0)
        call s:CS_cmd_Help()
        return
    endif

    let i=0
    while i < g:csMaxConn
        if (s:cs_slot_{i}_used==1) && (s:cscope_{i}_db_filename==db_filename)
            let tmpstr="Error: " . db_filename . " already present"
            echohl ErrorMsg | echo tmpstr | echohl None
            return
        endif
        let i=i+1
    endwhile
    let i=0
    while i < g:csMaxConn
        if s:cs_slot_{i}_used==0
            break
        endif
        let i=i+1
    endwhile
    if i>=g:csMaxConn
        call s:CS_cmd_Help()
        return
    endif

    let s:cscope_{i}_db_filename=db_filename
    if a:nargs>2
        let s:cscope_{i}_db_prep_path=a:prep_path
    endif
    if a:nargs>3
        let s:cscope_{i}_db_flags=a:flags
    endif
    let s:cs_slot_{i}_used=1
    return
endfunction

function! s:CS_handle_kill(nargs,c_id)
    if a:nargs!=2
        call s:CS_cmd_Help()
        return
    endif

    if (a:c_id <-1) || (a:c_id >= g:csMaxConn)
        call s:CS_cmd_Help()
        return
    endif

    let s:cscope_{a:c_id}_db_filename=''
    let s:cscope_{a:c_id}_db_prep_path=''
    let s:cscope_{a:c_id}_db_flags=''
    let s:cs_slot_{a:c_id}_used=0
    return
endfunction

function! s:CS_handle_show(nargs)
    if a:nargs!=1
        call s:CS_cmd_Help()
        return
    endif
    let i=0
    echohl ErrorMsg | echo "cscope connections\n" | echohl None
    while i < g:csMaxConn
        if s:cs_slot_{i}_used==1
            let c_list= " " . i . "\t" . s:cscope_{i}_db_filename . "\t" . s:cscope_{i}_db_prep_path . "\n"
            echo c_list
        endif
        let i=i+1
    endwhile
    return
endfunction

command! -nargs=* -complete=file CS call s:CS_cmd(<f-args>)
