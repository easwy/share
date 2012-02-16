" selectbuf.vim: Please see plugin/selectbuf.vim

" Make sure line-continuations won't cause any problem. This will be restored
"   at the end
let s:save_cpo = &cpo
set cpo&vim

" Initializations {{{
function! selectbuf#Initialize() " {{{ [-2s]

" For WinManager integration.
let g:SelectBuf_title = s:windowName


" This default mappings are just for the reverse lookup (maparg()) to work
" always.
function! s:DefDefMap(mapType, mapKeyName, defaultKey)
  if maparg('<Plug>SelBuf' . a:mapKeyName) == ''
    exec a:mapType . "noremap <script> <silent> <Plug>SelBuf" . a:mapKeyName
	  \ a:defaultKey
  endif
endfunction
call s:DefDefMap('n', 'SelectKey', "<CR>")
call s:DefDefMap('n', 'MSelectKey', "<2-LeftMouse>")
call s:DefDefMap('n', 'WSelectKey', "<C-W><CR>")
call s:DefDefMap('n', 'OpenKey', "O")
call s:DefDefMap('n', 'DeleteKey', "d")
call s:DefDefMap('n', 'WipeOutKey', "D")
call s:DefDefMap('v', 'DeleteKey', "d")
call s:DefDefMap('v', 'WipeOutKey', "D")
call s:DefDefMap('n', 'TDetailsKey', "i")
call s:DefDefMap('n', 'THiddenKey', "u")
call s:DefDefMap('n', 'TBufNumsKey', "p")
call s:DefDefMap('n', 'THidePathsKey', "P")
call s:DefDefMap('n', 'RefreshKey', "R")
call s:DefDefMap('n', 'SortSelectFKey', "s")
call s:DefDefMap('n', 'SortSelectBKey', "S")
call s:DefDefMap('n', 'SortRevKey', "r")
call s:DefDefMap('n', 'QuitKey', "q")
call s:DefDefMap('n', 'THelpKey', "?")
call s:DefDefMap('n', 'ShowSummaryKey', "<C-G>")
call s:DefDefMap('n', 'LaunchKey', "A")
delfunction s:DefDefMap

endfunction " -- Initialize }}}

" One-time initialization of some script variables {{{
" These are typically those that save the state are those which are not
"   impacted directly by user.
if !exists('s:myBufNum') 
  let s:windowName = '[Select Buf]'
  " This is the current buffer when the browser is invoked ('%').
  let s:originalCurBuffer = 1
  " This is the alternate buffer when the browser is invoked ('#').
  let s:originalAltBuffer = 1
  " The size of the current header. Used for mapping file names to buffer
  "   numbers when buffer numbers are hidden.
  let s:headerSize = 0
  let s:myBufNum = -1
  let s:savedSearchString = ''
  let s:savedSBSearchString = ''
  let s:bufNameFieldWidth = 9 " Buffer name length used currently, start with min.
  " The operating mode for the current session. This is reset after the browser
  "   is closed. Ideally, we assume that the browser is open in only one window.
  let s:opMode = ""

  let s:pendingUpdAxns = []
  let s:wipedBufs = {} " Temporary hold to know their names.
  let s:auSuspended = 1 " Disable until we are ready.
  let s:bufList = []
  let s:indList = ""
  let s:quiteWinEnter = 0
  let s:originatingWinNr = 1
  let s:baseDir = '' " Base directory for relative paths.
endif

let s:sortByNumber=0
let s:sortByName=1
let s:sortByPath=2
let s:sortByType=3
let s:sortByIndicators=4
let s:sortByMRU=5
let s:sortByMaxVal=5

let s:sortdirlabel  = ""

let s:settings = split('AlwaysHideBufNums,AlwaysShowDetails,AlwaysShowHelp,' .
      \ 'AlwaysShowHidden,AlwaysShowPaths,BrowserMode,DefaultSortDirection,' .
      \ 'DefaultSortOrder,DelayedDynUpdate,DisableMRUlisting,DisableSummary,' .
      \ 'EnableDynUpdate,IgnoreCaseInSort,IgnoreNonFileBufs,' .
      \ 'RestoreWindowSizes,SplitType,UseVerticalSplit,DoFileOnClose,' .
      \ 'DisplayMaxPath,Launcher,RestoreSearchString,ShowRelativePath', ',')
let s:settingsCompStr = ''
" Map of global variable name to the local variable that are different than
"   their global counterparts.
let s:settingsMap{'DefaultSortOrder'} = 'sorttype'
let s:settingsMap{'DefaultSortDirection'} = 'sortdirection'
let s:settingsMap{'AlwaysShowHelp'} = 'showHelp'
let s:settingsMap{'AlwaysShowHidden'} = 'showHidden'
let s:settingsMap{'AlwaysShowDetails'} = 'showDetails'
let s:settingsMap{'AlwaysShowPaths'} = 'showPaths'
let s:settingsMap{'AlwaysHideBufNums'} = 'hideBufNums'

"let g:SB_MESSAGES = ''

let s:optMRUfullUpdate = 1
" One-time initialization of some script variables }}}
" Initializations }}}


"
" Functions start from here.
"

" ListBufs: Main User entry function. {{{

function! selectbuf#ListBufs()
  " First check if the browser window is already visible.
  let browserWinNo = bufwinnr(s:myBufNum)

  " We need to update these before we switch to the browser window.
  if browserWinNo != winnr()
    let s:originalCurBuffer = bufnr("%")
    let s:originalAltBuffer = bufnr("#")
  endif

  call s:SuspendAutoUpdates('ListBufs')
  try
    call s:GoToBrowserWindow(browserWinNo)
    call s:UpdateBuffers(0) " It will do a full refresh if required.
    if s:opMode ==# 'WinManager'
      call WinManagerForceReSize('SelectBuf')
    else
      call s:AdjustWindowSize()
    endif
  finally
    call s:ResumeAutoUpdates()
  endtry

  " When browser window is opened for the first time, if it was invoked by the
  " user (instead of accidentally switching to the browser buffer), and the
  " browser mode is not to keep the window open.
  if s:opMode ==# 'user' && g:selBufBrowserMode !=# 'keep' && browserWinNo == -1
    " Arrange a notification of the window close on this window.
    call genutils#AddNotifyWindowClose(s:windowName, s:SNR() .
          \ "RestoreWindows")
  endif
endfunction " ListBufs


function! s:AutoListBufs()
  if s:AUSuspended()
    return
  endif
  " If opMode is empty, it means the browser window entered through backdoor
  " (by e#<browserBufNumber> e.g.)
  if s:opMode == ""
    let s:opMode = 'auto'
  endif
  let s:quiteWinEnter = 0
  call selectbuf#ListBufs()
endfunction

" ListBufs }}}


" Buffer Update {{{
" Header {{{
function! s:UpdateHeader()
  let _modifiable = &l:modifiable
  setlocal modifiable
  " Remember the position.
  call genutils#SaveSoftPosition("UpdateHeader")
  try
    if search('^"= ', 'w')
      silent! keepjumps 1,.delete _
    endif

    call s:AddHeader()
    call search('^"= ', "w")
    let s:headerSize = line('.')

    if s:opMode ==# 'WinManager'
      call WinManagerForceReSize('SelectBuf')
    else
      call s:AdjustWindowSize()
    endif
  finally
    " Return to the original position.
    call genutils#RestoreSoftPosition("UpdateHeader")
    call genutils#ResetSoftPosition("UpdateHeader")
    let &l:modifiable = _modifiable
  endtry
endfunction " UpdateHeader

function! s:MapArg(key)
  return maparg('<Plug>SelBuf' . a:key)
endfunction

function! s:AddHeader()
  let helpMsg=""
  let helpKey = maparg("<Plug>SelBufTHelpKey")
  if g:selBufAlwaysShowHelp
    let helpMsg = helpMsg
      \ . "\" " . s:MapArg("SelectKey") . " or " . s:MapArg("MSelectKey") .
      \	    " : open current buffer\n"
      \ . "\" " . s:MapArg("WSelectKey") . "/" . s:MapArg("OpenKey") .
      \	    " : open buffer in a new/previous window\n"
      \ . "\" " . s:MapArg("DeleteKey") . " : delete/undelete current buffer\t"
      \	    . s:MapArg("WipeOutKey") . " : wipeout current buffer\n"
      \ . "\" " . s:MapArg("TDetailsKey") . " : toggle additional details\t\t" .
      \	    s:MapArg("TBufNumsKey") . " : toggle show buffer numbers\n"
      \ . "\" " . s:MapArg("THidePathsKey") . " : toggle show paths\t\t\t" .
      \	    s:MapArg("THiddenKey") . " : toggle hidden buffers\n"
      \ . "\" " . s:MapArg("RefreshKey") . " : refresh browser\t\t\t" .
      \	    s:MapArg("QuitKey") . " : close browser\n"
      \ . "\" " . s:MapArg("SortSelectFKey") . "/" . s:MapArg("SortSelectBKey")
      \	    . " : select sort field for/backward\t" . s:MapArg("SortRevKey") .
      \	    " : reverse sort\n"
      \ . "\" Next, Previous & Current buffers are marked 'a', 'b' & 'c' "
	\ . "respectively\n"
  endif
  let helpMsg = helpMsg
    \ . "\" Press " . helpKey . " to show help"
  if g:selBufShowRelativePath
    let helpMsg = helpMsg
      \ . " (baseDir=".s:baseDir.")"
  endif
  let helpMsg = helpMsg ."\n"
  let helpMsg = helpMsg . "\"=" . " Sorting=" . s:sortdirlabel .
              \ s:GetSortNameByType(g:selBufDefaultSortOrder) .
              \ ",showDetails=" . g:selBufAlwaysShowDetails .
              \ ",showHidden=" . g:selBufAlwaysShowHidden . ",showPaths=" .
	      \ g:selBufAlwaysShowPaths . ",hideBufNums=" .
              \ g:selBufAlwaysHideBufNums . "\n"
  0
  " Silence a vim internal error about undo buffer. There seems to be no other
  "   side effects.
  silent! put! =helpMsg
endfunction " AddHeader
" Header }}}

" UpdateBuffers {{{
function! s:UpdateBuffers(fullUpdate)
  call s:SetupBuf()

  " If this is the first time we are updating the buffer, we need to do
  " everything from scratch.
  if getline(1) == "" || a:fullUpdate || ! g:selBufEnableDynUpdate
    call s:FullUpdate()
  else
    call s:IncrementalUpdate()
  endif
endfunction " UpdateBuffers

function! s:AutoUpdateBuffers(fullUpdate)
  if s:AUSuspended()
    return
  endif

  call s:UpdateBuffers(a:fullUpdate)
endfunction
" }}}

function! s:ShouldShowBuffer(bufNum) " {{{
  let showBuffer = 1
  if bufexists(a:bufNum)
    " If user wants to hide hidden buffers.
    if s:IgnoreBuf(a:bufNum)
      let showBuffer = 0
    elseif ! g:selBufAlwaysShowHidden && ! buflisted(a:bufNum)
      let showBuffer = 0
    endif
  else
    let showBuffer = 0
  endif
  return showBuffer
endfunction " }}}

function! s:FullUpdate() " {{{
  setlocal modifiable

  call genutils#OptClearBuffer()

  let s:baseDir = getcwd()

  call s:AddHeader()
  silent! keepjumps $delete _ " Delete one empty extra line at the end.
  let s:headerSize = line("$")
  let s:bufNameFieldWidth = s:CalcMaxBufNameLen(-1, !g:selBufAlwaysShowHidden)
  call s:SetupSyntax()

  $
  " Loop over all the buffers.
  let nBuffers = 0
  let nBuffersShown = 0
  let newLine = ""
  let showBuffer = 0
  let s:bufList = []
  let lastBufNr = bufnr('$')
  call s:InitializeMRU()
  if s:optMRUfullUpdate &&
        \ s:GetSortNameByType(g:selBufDefaultSortOrder) ==# 'mru'
    let i = s:NextBufInMRU()
  else
    let i = 1
  endif
  while i <= lastBufNr
    let newLine = ""
    if s:ShouldShowBuffer(i)
      call add(s:bufList, i)
      let newLine = s:GetBufLine(i)
      silent! keepjumps call append(line("$"), newLine)
      let nBuffersShown = nBuffersShown + 1
    endif
    let nBuffers = nBuffers + 1
    if s:optMRUfullUpdate &&
          \ s:GetSortNameByType(g:selBufDefaultSortOrder) ==# 'mru'
      let i = s:NextBufInMRU()
    else
      let i = i + 1
    endif
  endwhile

  if line("$") != s:headerSize
    " Finally sort the listing based on the current settings.
    if (!s:optMRUfullUpdate ||
          \ s:GetSortNameByType(g:selBufDefaultSortOrder) !=# 'mru') &&
	  \ s:GetSortNameByType(g:selBufDefaultSortOrder) !=# 'number'
      call s:SortBuffers(0)
    endif

    if g:selBufAlwaysHideBufNums
      call s:RemoveBufNumbers()
    endif
  endif

  call s:MarkBuffers()

  " Since we did a full refresh, we shouldn't need them.
  let s:pendingUpdAxns = []

  if search('^"= ', "w")
    +
  endif

  if ! g:selBufDisableSummary
    redraw | echohl SelBufSummary |
	  \ echo "Total buffers: " . nBuffers . " Showing: " . nBuffersShown |
	  \ echohl None
  endif
  setlocal nomodifiable
endfunction " FullUpdate " }}}

" Incremental update support {{{
"let g:selbufDebug='' 
function! s:IncrementalUpdate() " {{{
  " If there are no pending updates, then we don't have to do anything.
  if len(s:pendingUpdAxns) == 0
    return
  endif

  call genutils#SaveSoftPosition("IncrementalUpdate")

  if search('^"= ', 'w') != 0
    let s:headerSize = line('.')
  endif

  if g:selBufAlwaysHideBufNums
    call s:AddBufNumbers()
  endif

  setlocal modifiable

  " First save the selection state.
  let selectedBuffers = s:MSGetSelectedBuffers()
  if s:MultiSelectionExists()
    MSClear
  endif

  let prevBufNameFieldWidth = s:bufNameFieldWidth
  for nextAxn in s:pendingUpdAxns
    let bufNo = nextAxn + 0
    let action = nextAxn[strlen(nextAxn) - 1] " Last char.

    if g:selBufAlwaysShowPaths == 2 && (action == 'c' || action == 'w' ||
          \ (!g:selBufAlwaysShowHidden && action == 'd'))
      let len = strlen((action == 'w' ? remove(s:wipedBufs, bufNo) :
            \ s:FileName(bufNo)))
      if (action == 'c' && len > s:bufNameFieldWidth)
        " Insert enough extra spacer for all the existing buffers.
        let addSpacer = genutils#GetSpacer(len - s:bufNameFieldWidth)
        let colToIns = (g:selBufAlwaysShowDetails ? 11 : 5) +
              \ s:bufNameFieldWidth + 1 " Col index starts with 1.
        call genutils#SilentSubstitute('\%'.colToIns.'c',
              \ 'keepjumps '.(s:headerSize+1).',$s//'.addSpacer.'/')
        let s:bufNameFieldWidth = len
      elseif (action != 'c' && len == s:bufNameFieldWidth)
        " If all other buffers are shorter, then we need to reduce the spacing.
        let newLen = s:CalcMaxBufNameLen(bufNo, !g:selBufAlwaysShowHidden)
        if newLen < s:bufNameFieldWidth
          let remSpacer = ' \{'.(s:bufNameFieldWidth - newLen).'}'
          let colToDel = (g:selBufAlwaysShowDetails ? 11 : 5) + newLen
                \ + 1 " Col index starts with 1.
          call genutils#SilentSubstitute('\%'.colToDel.'c'.remSpacer,
                \ 'keepjumps '.(s:headerSize+1).',$s///')
          let s:bufNameFieldWidth = newLen
        endif
      endif
    endif

    " For delete, skip when we are showing hidden buffers but not details.
    if action ==# 'd' && g:selBufAlwaysShowHidden && ! g:selBufAlwaysShowDetails
      continue

    " For 'm' or 'u', skip when the buffer is hidden and we don't show [-2s]
    "   hidden buffers (we would like to add 'c' also here but a buffer can
    "   never be unlisted by the time it is created).
    elseif action =~ '[um]' && ! g:selBufAlwaysShowHidden && ! buflisted(bufNo)
      continue
    endif

    let bufferSelected = 0
    if search('^' . bufNo . '\>', 'w') > 0
      if action ==# 'u' || (action ==# 'd' && g:selBufAlwaysShowHidden)
	silent! keepjumps call setline('.', s:GetBufLine(bufNo))
	continue
      else
	silent! keepjumps .delete _
        " Mark the current position so that user can go back.
        mark d
      endif
    endif
    if action ==# 'c' || action ==# 'm'
      let bufLine = s:GetBufLine(bufNo)
      " We don't use direction argument.
      let lineNoToInsert = genutils#BinSearchForInsert(s:headerSize + 1,
	    \ line("$"), bufLine, s:SNR().'CompareBufLines', 0)
      silent! keepjumps call append(lineNoToInsert, bufLine)
    endif
  endfor

  if prevBufNameFieldWidth != s:bufNameFieldWidth
    call s:SetupSyntax()
  endif

  call s:MSSelectBuffers(selectedBuffers)

  let s:pendingUpdAxns = []

  call s:MarkBuffers()

  setlocal nomodifiable

  if g:selBufAlwaysHideBufNums
    call s:RemoveBufNumbers()
  endif

  call genutils#RestoreSoftPosition("IncrementalUpdate")
  call genutils#ResetSoftPosition("IncrementalUpdate")
  normal! zb
endfunction " IncrementalUpdate }}}

" Actions:
"   'c' - buffer added (add line).
"   'd' - buffer deleted (remove only if !showHidden and update otherwise).
"   'w' - buffer wipedout (remove in any case).
"   'u' - needs an update.
"   'm' - needs to be moved (remove and add back).
function! s:DynUpdate(action, bufNum, ovrrdDelayDynUpdate) " {{{
  let bufNo = a:bufNum
  if bufNo == -1 || bufNo == s:myBufNum || s:AUSuspended()
    return
  endif
  " This means that only 'd', 'w' and most of the 'c' events get through. If
  "   the buffer is ignored by its name, the 'c' events will not get through,
  "   so their corresponding 'd' or 'w' event is redundant, but there is no
  "   way to avoid it.
  if s:IgnoreBuf(a:bufNum) && (a:action !=# 'd' && a:action !=# 'w')
    return
  endif

  let ignore = 0
  if (a:action ==# 'u' || a:action ==# 'm') &&
	\ index(s:pendingUpdAxns, bufNo . 'c') != -1
    let ignore = 1
  elseif a:action ==# 'w' || (a:action ==# 'd' && !g:selBufAlwaysShowHidden)
    " Remove all pending actions for this buffer.
    " The delete case helps cases when new unlisted buffers, with names longer
    " than the current are created.
    call filter(s:pendingUpdAxns, 'v:val !~ bufNo."\\a"')
  elseif index(s:pendingUpdAxns, bufNo . a:action) != -1
    let ignore = 1
  endif
  if ! ignore
    call add(s:pendingUpdAxns, bufNo . a:action)
  endif

  " Update the previous alternative buffer.
  let s:originalCurBuffer = bufnr("%")
  let saveAltBuf = s:originalAltBuffer
  let s:originalAltBuffer = bufnr("#")
  if g:selBufAlwaysShowDetails && saveAltBuf != s:originalAltBuffer
    call add(s:pendingUpdAxns, saveAltBuf . 'u')
  endif

  let browserWinNo = bufwinnr(s:myBufNum)
  if ! g:selBufDelayedDynUpdate && browserWinNo != -1 && ! s:AUSuspended() &&
	\ len(s:pendingUpdAxns) != 0 && !a:ovrrdDelayDynUpdate
    if s:opMode !=# 'WinManager' || !WinManagerAUSuspended()
      " CAUTION: Using bufnr('%') is not reliable in the case of ":split new".
      "	  By the time the BufAdd event is fired, the window is already created,
      "	  but the bufnr() still gives the old buffer number. Using winnr()
      "	  alone seems to work well.
      "let prevFile = bufnr('%')
      let prevWin = winnr() " Backup.
      call selectbuf#ListBufs()
      "let win = bufwinnr(prevFile)
      "if win == -1
	let win = prevWin
      "endif
      call s:GoToWindow(win)
    endif
  endif
endfunction " }}}
" Incremental update support }}}

" Event handlers {{{
function! selectbuf#BufWinEnter()
  if g:selBufEnableDynUpdate
    " Optimization: Pass 1 for updImm only when the next call is not going to be
    "   effective.
    call selectbuf#PushToFrontInMRU(expand("<abuf>") + 0,
          \ (! s:IgnoreBuf(bufnr('#') + 0) && ! g:selBufAlwaysShowDetails) ? 1 :
          \ 0)
    " FIXME: In case of :e#, the alternate buffer must have got updated because
    "   of a BufWinLeave event, but it looks like this buffer still appears as
    "   the current and active buffer at that time, so details will show
    "   incorrect information. As a workaround, update this buffer again.
    if g:selBufAlwaysShowDetails
      call s:DynUpdate('u', bufnr('#') + 0, 0)
    endif
  endif
endfunction

function! selectbuf#BufWinLeave()
  if g:selBufEnableDynUpdate
    call s:DynUpdate('u', expand("<abuf>") + 0, 1)
  endif
endfunction

function! selectbuf#BufWipeout()
  let bufNr = expand("<abuf>") + 0
  if ! g:selBufDisableMRUlisting
    call s:DelFromMRU(bufNr)
  endif
  let s:wipedBufs[bufNr] = s:FileName(bufNr)
  call s:BufDeleteImpl(bufNr, 0, 'w')
endfunction

function! selectbuf#BufDelete()
  call s:BufDeleteImpl(expand("<abuf>")+0, 0, 'd')
endfunction

function! s:BufDeleteImpl(bufNr, delayedUpdate, event)
  if g:selBufEnableDynUpdate
    call s:DynUpdate(a:event, a:bufNr, a:delayedUpdate)
  endif
endfunction

function! selectbuf#BufNew()
  if ! g:selBufDisableMRUlisting
    call s:AddToMRU(expand("<abuf>") + 0)
  endif
endfunction

function! selectbuf#BufAdd()
  if g:selBufEnableDynUpdate
    let bufNr = expand("<abuf>") + 0
    " Ignore non-file buffers.
    if !s:IgnoreBuf(bufNr)
      call s:BufAddImpl(bufNr, 0)
    endif
  endif
endfunction

" Actual event generator.
function! s:BufAddImpl(bufNr, delayedUpdate)
  call s:DynUpdate('c', a:bufNr, a:delayedUpdate)
endfunction
" Event handlers }}}
" Buffer Update }}}


" Buffer line operations {{{

" Add/Remove buffer/indicators numbers {{{
function! s:RemoveBufNumbers()
  let s:bufList = split(s:RemoveColumn(1, 5, 1), "\n")
endfunction " RemoveBufNumbers


function! s:AddBufNumbers()
  call s:AddColumn(0, join(s:bufList, "\n"))
endfunction " AddBufNumbers

"function! s:RemoveIndicators()
"  let s:indList = s:RemoveColumn(2)
"endfunction " RemoveIndicators
"
"
"function! s:AddIndicators()
"  call s:AddColumn(2, s:indList)
"endfunction " AddIndicators

" Pass -1 for colWidth to include till the end of line.
function! s:RemoveColumn(colPos, colWidth, collect)
  if line("$") == s:headerSize
    return
  endif
  call search('^"= ', "w")
  +
  if a:collect
    let _unnamed = @"
    let _z = @z
  endif
  let block = ''
  let _sol = &startofline
  let _modifiable = &l:modifiable
  try
    setlocal modifiable
    set nostartofline
    exec "normal! ".a:colPos."|" | " Position correctly.
    silent! keepjumps exec "normal! \<C-V>G".
          \ ((a:colWidth > 0) ? (a:colWidth-1).'l' : '$').
          \ '"'.(a:collect?'z':'_').'d'
  finally
    let &l:modifiable = _modifiable
    let  &startofline = _sol
    if a:collect
      let block = @z
      let @z = _z
      let @" = _unnamed
    endif
  endtry
  return block
endfunction " RemoveColumn

function! s:AddColumn(colPos, block)
  if line("$") == s:headerSize || a:block == ""
    return
  endif
  let _z = @z
  let _modifiable = &l:modifiable
  try
    setlocal modifiable
    call setreg('z', a:block, "\<C-V>")
    call search('^"= ', "w")
    +
    exec "normal!" (a:colPos ? a:colPos : 1)."|" | " Position correctly.
    if a:colPos == 0
      normal! "zP
    else
      normal! "zp
    endif
  finally
    let &l:modifiable = _modifiable
    let @z = _z
  endtry
endfunction " AddColumn
" Add/Remove buffer/indicators numbers }}}

" GetBufLine {{{
function! s:GetBufLine(bufNum)
  if a:bufNum == -1
    return ""
  endif
  let newLine = ""
  let newLine = newLine . strpart(a:bufNum."    ", 0, 5)
  " If user wants to see more details.
  if g:selBufAlwaysShowDetails
    let newLine = newLine . s:GetBufIndicators(a:bufNum)
  endif
  let newLine = newLine . s:GetBufName(a:bufNum)
  return newLine
endfunction

" Width: 6
function! s:GetBufIndicators(bufNum)
  let bufInd = ''
  if !buflisted(a:bufNum)
    let bufInd = bufInd . "u"
  else
    let bufInd = bufInd . " "
  endif

  " Alternate buffer is more reliable than current when switching windows
  " (BufWinLeave comes first and the # buffer is already changed by then,
  " not the % buffer).
  if s:originalAltBuffer == a:bufNum
    let bufInd = bufInd . "#"
  elseif s:originalCurBuffer == a:bufNum
    let bufInd = bufInd . "%"
  else
    let bufInd = bufInd . " "
  endif

  if bufloaded(a:bufNum)
    if bufwinnr(a:bufNum) != -1
      " Active buffer.
      let bufInd = bufInd . "a"
    else
      let bufInd = bufInd . "h"
    endif
  else
    let bufInd = bufInd . " "
  endif

  " Special case for "my" buffer as I am finally going to be
  "  non-modifiable, anyway.
  if getbufvar(a:bufNum, "&modifiable") == 0 || s:myBufNum == a:bufNum
    let bufInd = bufInd . "-"
  elseif getbufvar(a:bufNum, "&readonly") == 1
    let bufInd = bufInd . "="
  else
    let bufInd = bufInd . " "
  endif

  " Special case for "my" buffer as I am finally going to be
  "  non-modified, anyway.
  if getbufvar(a:bufNum, "&modified") == 1 && a:bufNum != s:myBufNum
    let bufInd = bufInd . "+"
  else
    let bufInd = bufInd . " "
  endif
  let bufInd = bufInd . " "

  return bufInd
endfunction

function! s:GetBufName(bufNum)
  if g:selBufAlwaysShowPaths
    if g:selBufAlwaysShowPaths == 2
      let bufName = s:FileName(a:bufNum)
      let path = expand('#'.a:bufNum.':p:h')
      if g:selBufShowRelativePath
        let path = genutils#RelPathFromDir(s:baseDir, path)
      endif
      let bufName = bufName . genutils#GetSpacer(s:bufNameFieldWidth -
            \ strlen(bufName) + 1) . s:TrimPath(path)
    else
      let bufName = s:TrimPath(s:BufName(a:bufNum))
    endif
  else
    let bufName = s:FileName(a:bufNum)
  endif
  return bufName
endfunction

function! s:TrimPath(path)
  let path = a:path
  if g:selBufDisplayMaxPath > 0 && strlen(path) > g:selBufDisplayMaxPath
    let path = '...'.strpart(path, strlen(path) - g:selBufDisplayMaxPath + 3)
  endif
  return path
endfunction
" GetBufLine }}}

function! s:SelectCurrentBuffer(openMode) " {{{
  if search('^"= ', "W") != 0
    +
    return
  endif

  let selBufNum = SBCurBufNumber()
  if selBufNum == -1
    +
    return
  endif

  " If running under WinManager, let it open the file.
  if s:opMode ==# 'WinManager'
    call WinManagerFileEdit(selBufNum, a:openMode)
    return
  endif

  let didQuit = 0
  if a:openMode == 2
    " Behaves temporarily like "keep"
    let prevWin = winnr()
    exec s:originatingWinNr 'wincmd w'
    if prevWin == winnr() " No previous window.
      split
    endif
  elseif a:openMode == 1
    " We will just skip calling Quit() here, because we will change to the
    " selected buffer anyway soon.
    let s:opMode = 'auto'
  else
    let didQuit = s:Quit(1)
  endif

  " If we are not quitting the window, then there is no point trying to restore
  "   the window settings.
  if ! didQuit && g:selBufBrowserMode ==# "split"
    call genutils#RemoveNotifyWindowClose(s:windowName)
    call genutils#ResetWindowSettings2('SelectBuf')
  endif

  let v:errmsg = ""
  silent! exec "buffer" selBufNum

  " E325 is the error message that you see when the file is curerntly open in
  "   another vim instance.
  if v:errmsg != "" && v:errmsg !~ '^E325: ATTENTION'
    split
    exec "buffer" selBufNum
    redraw | echohl Error |
       \ echo "Couldn't open buffer " . selBufNum .
       \   " in window " . winnr() ", creating a new window." |
       \ echo "Error Message: " . v:errmsg |
       \ echohl None
  endif
endfunction " SelectCurrentBuffer }}}

" Buffer Deletions {{{
let s:deleteMsg = ''
function! s:DeleteSelBuffers(wipeout) range
  if s:opMode ==# 'WinManager'
    " Otherwise, WinManager would try to refresh us multiple times, once for
    "   each buffer deleted.
    call WinManagerSuspendAUs()
  endif

  call genutils#SaveHardPosition('DeleteSelBuffers')

  if g:selBufAlwaysHideBufNums
    call s:AddBufNumbers()
  endif
  let _delayedDynUpdate = g:selBufDelayedDynUpdate
  " Temporarily delay dynamic update until we call UpdateBuffers()
  let g:selBufDelayedDynUpdate = 1
  try
    if s:MultiSelectionExists()
      exec 'MSExecCmd call '.s:SNR().'DeleteBuffers("'.a:wipeout.'")'
      MSClear
    else
      exec a:firstline.','.a:lastline.'call s:DeleteBuffers(a:wipeout)'
    endif
  finally
    if g:selBufAlwaysHideBufNums
      call s:RemoveBufNumbers()
    endif
    let g:selBufDelayedDynUpdate = _delayedDynUpdate
    if s:deleteMsg != ''
      call s:UpdateBuffers(0)
    endif
    redraw | echo s:deleteMsg
    "call input(s:deleteMsg)
    let s:deleteMsg = ''
  endtry

  call genutils#RestoreHardPosition('DeleteSelBuffers')
  call genutils#ResetHardPosition('DeleteSelBuffers')

  if s:opMode ==# 'WinManager'
    call WinManagerResumeAUs()
  endif
endfunction

function! s:DeleteBuffers(wipeout) range
  let nDeleted = 0
  let nUndeleted = 0
  let nWipedout = 0
  let deletedMsg = ""
  let undeletedMsg = ""
  let wipedoutMsg = ""
  let line = a:firstline
  silent! execute line
  while line <= a:lastline
    let selectedBufNum = SBCurBufNumber()
    if selectedBufNum != -1
      try
        if a:wipeout
          exec "bwipeout" selectedBufNum
          let nWipedout = nWipedout + 1
          let wipedoutMsg = wipedoutMsg . " " . selectedBufNum
        elseif buflisted(selectedBufNum)
          exec "bdelete" selectedBufNum
          let nDeleted = nDeleted + 1
          let deletedMsg = deletedMsg . " " . selectedBufNum
        else
          " Undelete buffer.
          call setbufvar(selectedBufNum, "&buflisted", "1")
          let nUndeleted = nUndeleted + 1
          let undeletedMsg = undeletedMsg . " " . selectedBufNum
        endif
      catch
        echohl ErrorMsg | echo substitute(v:exception, '^[^:]\+:', '', '')
              \ | echohl NONE
      endtry
    endif
    silent! +
    let line = line + 1
  endwhile

  if nWipedout > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nWipedout, wipedoutMsg)
    let s:deleteMsg = s:deleteMsg . " wiped out.\n"
  endif
  if nDeleted > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nDeleted, deletedMsg)
    let s:deleteMsg = s:deleteMsg . " deleted (unlisted).\n"
  endif
  if nUndeleted > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nUndeleted, undeletedMsg)
    let s:deleteMsg = s:deleteMsg . " undeleted (listed).\n"
  endif
endfunction " DeleteBuffers

function! s:GetDeleteMsg(nBufs, msg)
  let msg = a:nBufs . ((a:nBufs > 1) ? " buffers: " : " buffer: ") .
          \ a:msg
  return msg
endfunction
" Buffer Deletions }}}

function! s:ExecFileCmdOnSelection(cmd) range " {{{
  let ind = match(a:cmd, '%\@<!\%(%%\)*\zs%[sn]')
  if ind != -1
    let cmdPre = strpart(a:cmd, 0, ind)
    let cmdPost = strpart(a:cmd, ind+2)
  else
    let cmdPre = a:cmd.' '
    let cmdPost = ''
  endif
  let cmdPre = substitute(cmdPre, '%%', '%', 'g')
  let cmdPost = substitute(cmdPost, '%%', '%', 'g')

  if g:selBufAlwaysHideBufNums
    call s:AddBufNumbers()
  endif
  try
    if ind != -1 && a:cmd[ind+1] == 'n'
      let bufList = SBSelectedBufNums(a:firstline, a:lastline)
    else
      let bufList = SBSelectedBuffers(a:firstline, a:lastline)
    endif
  finally
    if g:selBufAlwaysHideBufNums
      call s:RemoveBufNumbers()
    endif
  endtry

  if len(bufList) > 0
    let cmd = escape(cmdPre.join(bufList, ' ').cmdPost, '%')
    redraw | echo cmd
    exec cmd
    if s:MultiSelectionExists()
      MSClear
    endif
  endif
endfunction " }}}

" Buffer line operations }}}


" Buffer Setup/Cleanup {{{

function! s:SetupBuf() " {{{
  call genutils#SetupScratchBuffer()
  setlocal nowrap
  setlocal tabstop=8
  if g:selBufEnableDynUpdate
    setlocal bufhidden=hide
  else
    setlocal bufhidden=delete
  endif

  " Add autocommands for automatically updating the buffer when the browser
  " buffer is made visible by other means.
  aug SelectBufAutoUpdate
    au!
    au BufWinEnter <buffer> :call <SID>AutoListBufs()
    au BufWinLeave <buffer> :call <SID>Done() | call <SID>RestoreSearchString()
    au WinEnter <buffer> :call <SID>AutoUpdateBuffers(0)
    au WinLeave <buffer> :call <SID>RestoreSearchString()
  aug END

  call s:SetupSyntax()

  " Maps {{{
  if (! exists("no_plugin_maps") || ! no_plugin_maps) &&
        \ (! exists("no_selectbuf_maps") || ! no_selectbuf_maps)
    let noMaps = 0
  else
    let noMaps = 1
  endif

  if !noMaps
    call s:DefMap("n", "SelectKey", "<CR>", ":SBSelect<CR>")
    call s:DefMap("n", "MSelectKey", "<2-LeftMouse>", ":SBSelect<CR>")
    call s:DefMap("n", "WSelectKey", "<C-W><CR>", ":SBWSelect<CR>")
    call s:DefMap("n", "OpenKey", "O", ":SBOpen<CR>")
    call s:DefMap("n", "DeleteKey", "d", ":SBDelete<CR>")
    call s:DefMap("n", "WipeOutKey", "D", ":SBWipeout<CR>")
    call s:DefMap("v", "DeleteKey", "d", ":SBDelete<CR>")
    call s:DefMap("v", "WipeOutKey", "D", ":SBWipeout<CR>")
    call s:DefMap("n", "RefreshKey", "R", ":SBRefresh<CR>")
    call s:DefMap("n", "SortSelectFKey", "s", ":SBFSort<cr>")
    call s:DefMap("n", "SortSelectBKey", "S", ":SBBSort<cr>")
    call s:DefMap("n", "SortRevKey", "r", ":SBRSort<cr>")
    call s:DefMap("n", "QuitKey", "q", ":SBQuit<CR>")
    call s:DefMap("n", "ShowSummaryKey", "<C-G>", ":SBSummary<CR>")
    call s:DefMap("n", "LaunchKey", "A", ":SBLaunch<CR>")
    call s:DefMap("n", "TDetailsKey", "i", ":SBTDetails<CR>")
    call s:DefMap("n", "THiddenKey", "u", ":SBTHidden<CR>")
    call s:DefMap("n", "TBufNumsKey", "p", ":SBTBufNums<CR>")
    call s:DefMap("n", "THidePathsKey", "P", ":SBTPaths<CR>")
    call s:DefMap("n", "THelpKey", "?", ":SBTHelp<CR>")

    cnoremap <buffer> <C-R><C-F> <C-R>=expand('#'.SBCurBufNumber().':p')<CR>

    nnoremap <buffer> 0 gg0:silent! call search('^"= ')<CR>

    " From Thomas Link (t dot link02a at gmx at net)
    " When user types numbers in the browser window start a search for the
    " buffer by its number.
    let chars = "123456789"
    let i = 0
    let max = strlen(chars)
    while i < max
      exec 'noremap <buffer>' chars[i] ':call <SID>InputBufNumber()<CR>'.
            \ chars[i]
      let i = i + 1
    endwhile

    if s:MSExists()
      nnoremap <buffer> <silent> <Space> :.MSInvert<CR>
      vnoremap <buffer> <silent> <Space> :MSInvert<CR>
    endif
  endif

  aug SelectBufCursorMove
    au!
    if !g:selBufDisableSummary
      au CursorMoved <buffer> :call <SID>EchoBufSummary(0)
    aug END
  endif
  " Maps }}}

  " Commands {{{ 
  " Toggle the same key to mean "Close".
  nnoremap <buffer> <silent> <Plug>SelectBuf :call <SID>Quit(0)<CR>

  command! -nargs=1 -buffer -complete=command -range SBExec
        \ :<line1>,<line2>call <SID>ExecFileCmdOnSelection(<q-args>)

  " Define some local command too for the ease of debugging.
  command! -nargs=0 -buffer SBS :SBSettings
  command! -nargs=0 -buffer SBSelect :call <SID>SelectCurrentBuffer(0)
  command! -nargs=0 -buffer SBOpen :call <SID>SelectCurrentBuffer(2)
  command! -nargs=0 -buffer SBWSelect :call <SID>SelectCurrentBuffer(1)
  command! -nargs=0 -buffer SBQuit :call <SID>Quit(0)
  command! -nargs=0 -buffer -range SBDelete
        \ :<line1>,<line2>call <SID>DeleteSelBuffers(0)
  command! -nargs=0 -buffer -range SBWipeout
        \ :<line1>,<line2>call <SID>DeleteSelBuffers(1)
  command! -nargs=0 -buffer SBRefresh :call <SID>UpdateBuffers(1)
  command! -nargs=0 -buffer SBSummary :call s:EchoBufSummary(1)
  command! -nargs=0 -buffer SBFSort :call <SID>SortSelect(1)
  command! -nargs=0 -buffer SBBSort :call <SID>SortSelect(-1)
  command! -nargs=0 -buffer SBRSort :call <SID>SortReverse()
  command! -nargs=0 -buffer SBTBufNums :call <SID>ToggleHideBufNums()
  command! -nargs=0 -buffer SBTDetails :call <SID>ToggleDetails()
  command! -nargs=0 -buffer SBTHelp :call <SID>ToggleHelpHeader()
  command! -nargs=0 -buffer SBTHidden :call <SID>ToggleHidden()
  command! -nargs=0 -buffer SBTPaths :call <SID>ToggleHidePaths()
  command! -nargs=? -buffer SBBufToTail :call <SID>LocalSBBufTo('SBBufToTail',
        \ '<q-args>')
  command! -nargs=? -buffer SBBufToHead :call <SID>LocalSBBufTo('SBBufToHead',
        \ '<q-args>')
  " Commands }}} 
endfunction " SetupBuf }}}

function! s:LocalSBBufTo(cmd, arg)
  if a:arg != ''
    exec a:cmd a:arg
  else
    if SBCurBufNumber() != -1
      exec a:cmd SBCurBufNumber()
    endif
  endif
endfunction

function! s:SetupSyntax() " {{{
  syn clear " Why do we have to do this explicitly?
  set ft=selectbuf

  " The mappings in the help header.
  syn match SelBufMapping "\s\(\i\|[ /<>-]\)\+ : " contained
  syn match SelBufHelpLine "^\" .*$" contains=SelBufMapping,SelBufKeyValuePair

  " The starting line. Summary of current settings.
  syn keyword SelBufKeyWords Sorting showDetails showHidden showDirs showPaths bufNameOnly hideBufNums baseDir contained
  " FIXME: The last character is included in the highlighting, though we are
  " excluding it.
  syn region SelBufKeyValues start=+=+ end=+[,)]+ end=+$+ skip=+ + contained
  syn match SelBufKeyValuePair +\i\+=[^,)]\++ contained contains=SelBufKeyWords,SelBufKeyValues
  syn match SelBufSummary "^\"= .*$" contains=SelBufKeyValuePair

  syn match SelBufBufLine "^[^"].*$" contains=SelBufBufNumber,SelBufBufIndicators,SelBufBufName,@SelBufLineAdd
  syn match SelBufBufNumber "^\d\+" contained
  if g:selBufAlwaysHideBufNums
    if g:selBufAlwaysShowDetails
      syn match SelBufBufIndicators "\%(^\)\@<=....." contained contains=@SelBufIndAdd
      syn match SelBufBufName "\%(^.....\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    else
      syn match SelBufBufName "^\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    endif
  else
    if g:selBufAlwaysShowDetails
      " CAUTION: Five dots because that is the width of the buf number column.
      syn match SelBufBufIndicators "\%(^.....\)\@<=....." contained contains=@SelBufIndAdd
      syn match SelBufBufName "\%(^..........\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    else
      syn match SelBufBufName "\%(^.....\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    endif
  endif
  if g:selBufAlwaysShowPaths == 2
    let pathStartCol = s:bufNameFieldWidth + 2 +
          \ (!g:selBufAlwaysHideBufNums) * 5 + (g:selBufAlwaysShowDetails>0) * 5
    exec 'syn match SelBufPath "\%'.pathStartCol.'c\(\p\| \)*$" contained contains=@SelBufPathAdd'
  endif


  hi def link SelBufHelpLine      Comment
  hi def link SelBufMapping       Special

  hi def link SelBufSummary       Statement
  hi def link SelBufKeyWords      Keyword
  hi def link SelBufKeyValues     Constant

  hi def link SelBufBufNumber     Constant
  hi def link SelBufBufIndicators Label
  hi def link SelBufBufName       Directory
  hi def link SelBufPath          Identifier

  hi def link SelBufSummary       Special
endfunction " }}}

" Routing browser quit through this function gives a chance to decide how to
"   do the exit.
" Returns 1 when the browser window could be successfully closed.
function! s:Quit(scriptOrigin) " {{{
  " When the browser should be left open, switch to the previously used window
  "   instead of quitting the window.
  " The user can still use :q commnad to force a quit.
  if s:opMode ==# 'WinManager' || g:selBufBrowserMode ==# 'keep'
    " Switch to the most recently used window.
    if s:opMode ==# 'WinManager'
      let prevWin = bufwinnr(WinManagerGetLastEditedFile())
      if prevWin != -1
	if s:quiteWinEnter " When previously entered using activation key.
	  call s:GoToWindow(prevWin)
	else
	  exec prevWin . 'wincmd w'
	endif
      endif
    else
      exec s:originatingWinNr 'wincmd w'
    endif
    return 0
  endif

  let didQuit = 0
  " If opMode is empty or 'auto', the browser might have entered through some
  "   back-door mechanism. We don't want to exit the window in this case.
  if g:selBufBrowserMode ==# "switch" || s:opMode ==# 'auto' || s:opMode == ''
    " Switch browser even when the dynamic update is on, as it will allow us
    "	preserve the contents of the browser as we want.
    if ! a:scriptOrigin || g:selBufEnableDynUpdate
      e#
    endif

  " In any case, if there is only one window, then don't quit.
  elseif genutils#NumberOfWindows() > 1
    let v:errmsg = ""
    if g:selBufEnableDynUpdate
      hide
    else
      silent! quit
    endif
    if v:errmsg == ""
      let didQuit = 1
    endif

  " Give warning only when the user wanted to quit.
  elseif ! a:scriptOrigin
    redraw | echohl WarningMsg | echo "Can't quit the last window" |
	  \ echohl NONE
  endif

  if didQuit && g:selBufDoFileOnClose
    file
  endif

  return didQuit
endfunction " Quit }}}

" This is the function that gets always called no matter how we do the exit
"   from the browser, giving us a chance to do last minute cleanup.
function! s:Done() " {{{
  if s:AUSuspended()
    return
  endif

  " Clear up such that it gets set correctly the next time.
  let s:opMode = ''

  " Never cleanup when started by WinManager or in keep mode.
  if s:opMode ==# 'WinManager' || g:selBufBrowserMode ==# 'keep'
    return
  endif
endfunction " Done }}}

function! s:RestoreWindows(dummyTitle) " {{{
  " If user wants us to restore window sizes during the exit.
  if g:selBufRestoreWindowSizes && g:selBufBrowserMode !=# "keep"
    call genutils#RestoreWindowSettings2('SelectBuf')
  endif
endfunction " }}}

" Save the general search string and restore the previous search string in {{{
" SelectBuf
function! s:SaveSearchString()
  if !g:selBufRestoreSearchString
    return
  endif

  " If a new search string has been entered outside browser, save it first so
  " we can restore it later.
  if @/ == histget('search') && @/ != s:savedSBSearchString
    let s:savedSearchString = @/
  endif
  let @/ = s:savedSBSearchString
endfunction

" CAUTION: Gets called twice while closing the window.
function! s:RestoreSearchString()
  if !g:selBufRestoreSearchString
    return
  endif

  " If a new search string has been entered in the browser, save it first so
  " we can restore it later.
  if @/ == histget('search') && @/ != s:savedSearchString
    let s:savedSBSearchString = @/
  endif
  let @/ = s:savedSearchString " This doesn't modify the history.
endfunction " }}}

function! s:DefMap(mapType, mapKeyName, defaultKey, cmdStr) " {{{
  let key = maparg('<Plug>SelBuf' . a:mapKeyName)
  " If user hasn't specified a key, use the default key passed in.
  if key == ""
    let key = a:defaultKey
  endif
  exec a:mapType . "noremap <buffer> <silent> " . key a:cmdStr
endfunction " DefMap " }}}

" Buffer Setup/Cleanup }}}


" Utility methods. {{{
"
function! s:AdjustWindowSize() " {{{
  call genutils#SaveSoftPosition('AdjustWindowSize')
  " Set the window size to one more than just required.
  0
  " For vertical split, we shouldn't adjust the number of lines.
  if ! genutils#IsOnlyVerticalWindow() && ! g:selBufUseVerticalSplit
    let size = (line("$") + 1)
    if size > (&lines / 2)
      let size = &lines/2
    endif
    exec "resize" . size
  endif
  call genutils#RestoreSoftPosition('AdjustWindowSize')
  call genutils#ResetSoftPosition('AdjustWindowSize')
endfunction " }}}

" Suspend/Resume AUs{{{
function! s:SuspendAutoUpdates(dbgTag)
  " To make it reentrant.
  if !exists("s:_lazyredraw")
    let s:auSuspended = 1
    let s:dbgSuspTag = a:dbgTag
    if s:opMode ==# 'WinManager'
      call WinManagerSuspendAUs()
    endif
    let s:_lazyredraw = &lazyredraw
    set lazyredraw
    let s:_report = &report
    set report=99999
    let s:_undolevels = &undolevels
    set undolevels=-1
  endif
endfunction

function! s:ResumeAutoUpdates()
  " To make it reentrant.
  if exists("s:_lazyredraw")
    let &report = s:_report
    let &lazyredraw = s:_lazyredraw
    unlet s:_lazyredraw
    if s:opMode ==# 'WinManager'
      call WinManagerResumeAUs()
    endif
    let s:auSuspended = 0
    let s:dbgSuspTag = ''
    let &undolevels = s:_undolevels
  endif
endfunction

function! s:AUSuspended()
  return s:auSuspended
endfunction
" }}}

function! s:GetBufNumber(line) " {{{
  let bufNumber = matchstr(a:line, '^\d\+')
  if bufNumber == ''
    return -1
  endif
  return bufNumber + 0 " Convert it to number type.
endfunction " }}}

function! s:EchoBufSummary(detailed) " {{{
  if !a:detailed && g:selBufAlwaysShowPaths == 1 " There is nothing special to display here.
    return
  endif
  let bufNumber = SBCurBufNumber()
  if bufNumber != -1
    let _showPaths = g:selBufAlwaysShowPaths | let g:selBufAlwaysShowPaths = 1
    let _showDetails = g:selBufAlwaysShowDetails | let g:selBufAlwaysShowDetails = (a:detailed?1:0)
    let _hideBufNums = g:selBufAlwaysHideBufNums | let g:selBufAlwaysHideBufNums = (a:detailed?0:1)
    let _displayMaxPath = g:selBufDisplayMaxPath | let g:selBufDisplayMaxPath = -1
    let bufLine = ''
    try
      let bufLine = s:GetBufLine(bufNumber)
      let bufLine = a:detailed ? bufLine :
	    \ substitute(bufLine, '^\d\+\s\+', '', '')
    finally
      let g:selBufAlwaysShowPaths = _showPaths
      let g:selBufAlwaysShowDetails = _showDetails
      let g:selBufAlwaysHideBufNums = _hideBufNums
      let g:selBufDisplayMaxPath = _displayMaxPath
    endtry
    echohl SelBufSummary | echo (a:detailed ? '' : "Buffer: ") . bufLine .
	  \ (a:detailed ? (' (Total: '.(line('$') - s:headerSize).')') : '') |
	  \ echohl NONE
  endif
endfunction " }}}

function! selectbuf#LaunchBuffer(...) " {{{
  if g:selBufLauncher == ''
    return
  endif
  let args = ''
  let commandNeedsEscaping = 1
  if genutils#OnMS() && g:selBufLauncher =~# '^\s*!\s*start\>'
    let commandNeedsEscaping = 0
  endif
  if a:0 == 0
    let args = '#'.(bufnr('%') == s:myBufNum ? SBCurBufNumber() : bufnr('%')).
          \    ':p'
  else
    let i = 1
    while i <= a:0
      let arg = a:{i}
      if filereadable(a:{i}) || a:{i} == '.'
        let arg = fnamemodify(arg, ':p')
      endif
      if genutils#OnMS() && &shellslash && filereadable(arg)
        let arg = substitute(arg, '/', '\\', 'g')
      endif
      let arg = genutils#Escape(arg, ' ')
      let args = args . arg . ((i == a:0) ? '' : ' ')
      let i = i + 1
    endwhile
  endif
  if commandNeedsEscaping
    let args = genutils#EscapeCommand('', args, '')
  else
    " Escape the existing double-quotes (by quadrapling them).
    let args = substitute(args, '"', '""""', 'g')
    " Use double quotes to protect spaces and double-quotes.
    let args = substitute(args, '\(\%([^ ]\|\\\@<=\%(\\\\\)* \)\+\)',
          \ '"\1"', 'g')
          "\ '\="\"".escape(submatch(1), "\\")."\""', 'g')
    let args = genutils#UnEscape(args, ' ')
  endif
  if args != -1 && args.'' != ''
    exec 'silent! '.g:selBufLauncher args
  endif
endfunction " }}}

" GoToBrowserWindow {{{
" Place holder function for any future manipulation of window while taking
" focus into the browser window.
function! s:GoToBrowserWindow(browserWinNo)
  if winnr() != a:browserWinNo
    if a:browserWinNo != -1
      call s:GoToWindow(a:browserWinNo)
      let s:quiteWinEnter = 1
    else
      let s:opMode = 'user'

      " If user wants us to save window sizes and restore them later.
      " But don't save unless "split" mode, as otherwise we are not creating a
      "   new window.
      if g:selBufRestoreWindowSizes && g:selBufBrowserMode ==# "split"
	call genutils#SaveWindowSettings2('SelectBuf', 1)
      endif

      " Don't split window for "switch" mode.
      let splitCommand = ""
      if g:selBufBrowserMode !=# "switch"
	" If user specified a split type, use that.
	let splitCommand = splitCommand .  g:selBufSplitType
	if g:selBufUseVerticalSplit
	  let splitCommand = splitCommand . " vert "
	endif
	let splitCommand = splitCommand . " split"
      endif
      exec splitCommand
      if g:selBufUseVerticalSplit
	25wincmd |
      endif
      " Find if there is a buffer already created.
      if s:myBufNum != -1
	" Switch to the existing buffer.
	exec "buffer " . s:myBufNum
      else
	" Create a new buffer.
	" Temporarily modify isfname to avoid treating the name as a pattern.
	let _isf = &isfname
	try
	  set isfname-=\
	  set isfname-=[
	  if exists('+shellslash')
	    exec ":e \\\\" . escape(s:windowName, ' ')
	  else
	    exec ":e \\" . escape(s:windowName, ' ')
	  endif
	finally
	  let &isfname = _isf
	endtry
	let s:myBufNum = bufnr('%')
      endif
    endif
  endif
  call s:SaveSearchString()
endfunction

function! s:GoToWindow(winNr)
  if winnr() != a:winNr
    let _eventignore = &eventignore
    try
      "set eventignore+=WinEnter,WinLeave
      set eventignore=all
      let s:originatingWinNr = winnr()
      exec a:winNr . 'wincmd w'
    catch /^Vim\%((\a\+)\)\=:E788/
      " Happens if a file is realoaded during FileChangedRO, so just ignore it.
    finally
      let &eventignore = _eventignore
    endtry
  endif
endfunction
" }}}

" {{{
function! selectbuf#SBSettings(...)
  if a:0 > 0
    let selectedSetting = a:1
  else
    let selectedSetting = genutils#PromptForElement(s:settings, -1,
          \ "Select the setting: ", -1, 0, 3)
  endif
  if selectedSetting !~# '^\s*$'
    let oldVal = g:selBuf{selectedSetting}
    if a:0 > 1
      let newVal = a:2
      echo 'Current value for' selectedSetting.': "'.oldVal.'" New value: "'.
            \ newVal.'"'
    else
      let newVal = input('Current value for ' . selectedSetting . ' is: ' .
            \ oldVal . "\nEnter new value: ", oldVal)
    endif
    if newVal != oldVal
      let g:selBuf{selectedSetting} = newVal
      call selectbuf#Initialize()
    endif
  endif
endfunction

function! selectbuf#SettingsComplete(ArgLead, CmdLine, CursorPos)
  if s:settingsCompStr == ''
    let s:settingsCompStr = join(s:settings, "\n")
  endif
  return s:settingsCompStr
endfunction
" }}}

function! s:MarkBuffers() " {{{
  " Find current, next and previous buffers.
  if search('^' . s:originalCurBuffer . '\>', "w") " If found.
    mark c
  endif
  call s:FindAndMarkNextBuffer('a', 1)
  call s:FindAndMarkNextBuffer('b', -1)
endfunction " }}}

function! s:FindAndMarkNextBuffer(marker, inc) " {{{
  let nextBuffer = s:originalCurBuffer + a:inc
  let lastBufNr = bufnr('$')
  while ! bufexists(nextBuffer) && nextBuffer < lastBufNr && nextBuffer > 0
    let nextBuffer = nextBuffer + a:inc
  endwhile
  if search('^' . nextBuffer . '\>', "w") " If found.
    exec "mark " . a:marker
  endif
endfunction " }}}

"" START: Toggle methods {{{

function! s:ToggleHelpHeader()
  let g:selBufAlwaysShowHelp = ! g:selBufAlwaysShowHelp
  " Don't save/restore position in this case, because otherwise the user may
  "   not be able to view the help if he has listing that is more than one page
  "   (after all what is he viewing the help for ?)
  call s:UpdateHeader()
  if g:selBufAlwaysShowHelp
    0 " If you turn on help, you intent to see it right?
  endif
endfunction

function! s:ToggleDetails()
  "let g:selBufAlwaysShowDetails = ! g:selBufAlwaysShowDetails
  "call s:UpdateBuffers(1)
  call genutils#SaveSoftPosition('ToggleDetails')
  if g:selBufAlwaysShowDetails
    call s:RemoveColumn((!g:selBufAlwaysHideBufNums) * 5 + 1, 6, 0)
  else
    if g:selBufAlwaysHideBufNums
      call s:AddBufNumbers()
    endif
    if search('^"= ', "w")
      let _search = @/
      setlocal modifiable
      try
        let @/ = '\%6c'
        silent! keepjumps +,$s//\=s:GetBufIndicators(SBCurBufNumber())/e
      finally
        let @/ = _search
        setlocal nomodifiable
      endtry
    endif
    if g:selBufAlwaysHideBufNums
      call s:RemoveBufNumbers()
    endif
  endif
  let g:selBufAlwaysShowDetails = ! g:selBufAlwaysShowDetails
  call s:UpdateHeader()
  call s:SetupSyntax()
  call genutils#RestoreSoftPosition('ToggleDetails')
  call genutils#ResetSoftPosition('ToggleDetails')
endfunction

function! s:ToggleHidden()
  if g:selBufEnableDynUpdate
    let i = 1
    let lastBufNr = bufnr('$')
    while i <= lastBufNr
      if bufexists(i) && ! buflisted(i) && ! s:IgnoreBuf(i)
        if g:selBufAlwaysShowHidden
          call s:BufDeleteImpl(i, 1, 'd')
        else
          call s:BufAddImpl(i, 1)
        endif
      endif
      let i = i + 1
    endwhile
    let g:selBufAlwaysShowHidden = ! g:selBufAlwaysShowHidden
    call s:UpdateHeader()
    call selectbuf#ListBufs()
  else
    let g:selBufAlwaysShowHidden = ! g:selBufAlwaysShowHidden
    call s:UpdateBuffers(1)
  endif
endfunction

function! s:ToggleHideBufNums()
  call genutils#SaveHardPosition('ToggleHideBufNums')
  if ! g:selBufAlwaysHideBufNums
    call s:RemoveBufNumbers()
  else
    call s:AddBufNumbers()
  endif
  let g:selBufAlwaysHideBufNums = ! g:selBufAlwaysHideBufNums
  call s:UpdateHeader()
  call genutils#RestoreHardPosition('ToggleHideBufNums')
  call genutils#ResetHardPosition('ToggleHideBufNums')
  call s:SetupSyntax()
endfunction

function! s:ToggleHidePaths()
  call genutils#SaveSoftPosition('ToggleHidePaths')
  call s:RemoveColumn((!g:selBufAlwaysHideBufNums) * 5 +
        \ (g:selBufAlwaysShowDetails) * 6 + (g:selBufAlwaysShowDetails ||
        \ !g:selBufAlwaysHideBufNums) + (g:selBufAlwaysShowPaths == 2) *
        \ (s:bufNameFieldWidth + 1), -1, 0)
  let g:selBufAlwaysShowPaths = (g:selBufAlwaysShowPaths == 2) ? 0 :
        \ g:selBufAlwaysShowPaths + 1
  if g:selBufAlwaysShowPaths > 0
    setlocal modifiable
    if g:selBufAlwaysHideBufNums
      call s:AddBufNumbers()
    endif
    call search('^"= ', "w")
    let _search = @/
    try
      let @/ = '$'
      keepjumps +,$s//\=escape(s:GetBufName(SBCurBufNumber()), '\')/e
    finally
      let @/ = _search
      if g:selBufAlwaysHideBufNums
        call s:RemoveBufNumbers()
      endif
      setlocal nomodifiable
    endtry
  endif
  call s:UpdateHeader()
  call genutils#RestoreSoftPosition('ToggleHidePaths')
  call genutils#ResetSoftPosition('ToggleHidePaths')
  call s:SetupSyntax()
endfunction

"" END: Toggle methods }}}

" MRU support {{{
function! selectbuf#PushToFrontInMRU(bufNum, updImm)
  " Avoid browser buffer to come in the front.
  if a:bufNum == -1 || a:bufNum == s:myBufNum || g:selBufDisableMRUlisting
      return
  endif
  if s:IgnoreBuf(a:bufNum)
    return
  endif

  call remove(g:SB_MRUlist, index(g:SB_MRUlist, a:bufNum))
  call insert(g:SB_MRUlist, a:bufNum, 0)
  if s:GetSortNameByType(g:selBufDefaultSortOrder) ==# 'mru'
    call s:DynUpdate('m', a:bufNum + 0, !a:updImm)
  else
    call s:DynUpdate('u', a:bufNum + 0, !a:updImm)
  endif
endfunction

function! selectbuf#PushToBackInMRU(bufNum, updImm)
  if a:bufNum == -1 || a:bufNum == s:myBufNum || g:selBufDisableMRUlisting
    return
  endif
  if s:IgnoreBuf(a:bufNum)
    return
  endif

  call remove(g:SB_MRUlist, index(g:SB_MRUlist, a:bufNum))
  call add(g:SB_MRUlist, a:bufNum)
  if s:GetSortNameByType(g:selBufDefaultSortOrder) ==# 'mru'
    call s:DynUpdate('m', a:bufNum + 0, !a:updImm)
  else
    call s:DynUpdate('u', a:bufNum + 0, !a:updImm)
  endif
endfunction

function! s:AddToMRU(bufNum)
  if a:bufNum == -1 || a:bufNum == s:myBufNum
    return
  endif
  call add(g:SB_MRUlist, a:bufNum)
endfunction

function! s:DelFromMRU(bufNum)
  if a:bufNum == -1 || g:selBufDisableMRUlisting
    return
  endif
  let idx = index(g:SB_MRUlist, a:bufNum)
  if idx != -1
    call remove(g:SB_MRUlist, idx)
  endif
endfunction

function! s:NextBufInMRU()
  if !exists("s:nextBufMRUIdx")
    let s:nextBufMRUIdx = 0
  endif
  if s:nextBufMRUIdx < len(g:SB_MRUlist)
    let nextBuf = g:SB_MRUlist[s:nextBufMRUIdx]
    let s:nextBufMRUIdx += 1
    return nextBuf
  else
    unlet s:nextBufMRUIdx
    return bufnr('$') + 1
  endif
endfunction
" MRU support }}}

function! s:IgnoreBuf(bufNum) " {{{
  if g:selBufIgnoreNonFileBufs && (getbufvar(a:bufNum, '&buftype') != '' ||
        \ (bufname(a:bufNum)[0] ==# '[' && bufname(a:bufNum) =~# ']$'))
    return 1
  endif
  return 0
endfunction " }}}

function! s:BufName(bufNum) " {{{
  let bufName = bufname(a:bufNum)
  if bufName == ""
    let bufName = "[No File]"
  endif
  return bufName
endfunction " }}}

function! s:FileName(bufNum) " {{{
  let fileName = expand('#'.a:bufNum.':p:t')
  if fileName == ""
    let fileName = "[No File]"
  endif
  return fileName
endfunction " }}}

function! s:CalcMaxBufNameLen(skipBuf, skipHidden) " {{{
  let i = 1
  let maxBufNameLen = -1
  let lastBufNr = bufnr('$')
  while i <= lastBufNr
    try
      let fileName = s:FileName(i)
      if bufexists(i) && !s:IgnoreBuf(i) && maxBufNameLen < strlen(fileName) &&
            \ i != a:skipBuf
        if !buflisted(i) && a:skipHidden
          continue
        endif
        let maxBufNameLen = strlen(fileName)
      endif
    finally
      let i = i + 1
    endtry
  endwhile
  if maxBufNameLen < 9
    let maxBufNameLen = 9 " Min length of '[No File]'
  endif
  return maxBufNameLen
endfunction " }}}

function! s:MultiSelectionExists() " {{{
  if s:MSExists() && MSSelectionExists()
    return 1
  else
    return 0
  endif
endfunction " }}}

function! s:MSExists() " {{{
  if exists('g:loaded_multiselect') && g:loaded_multiselect >= 100 &&
        \ exists('*MSSelectionExists')
    return 1
  else
    return 0
  endif
endfunction " }}}

function! s:MSGetSelectedBuffers() " {{{
  " First save the selection state.
  let selectedBuffers = []
  if s:MultiSelectionExists()
    let selectedBuffers = SBSelectedBufNums(s:headerSize, line('$'))
  endif
  return selectedBuffers
endfunction

function! s:MSSelectBuffers(bufList)
  " First save the selection state.
  if len(a:bufList) > 0
    for bufNo in a:bufList
      if search('^' . bufNo . '\>', 'w') > 0
        .MSAdd
      endif
    endfor
  endif
endfunction " }}}


function! s:InitializeMRU() " {{{
  " Initialize with the bufers that might have been already loaded. This is
  "   required to show the buffers that are loaded by specifying them as
  "   command-line arguments (Reported by David Fishburn).
  if len(g:SB_MRUlist) == 0
    let createMode = 1
  else
    let createMode = 0 " Update mode.
  endif
  if ! g:selBufDisableMRUlisting
    let i = 1
    " Special case, while autoloading as part of opening a buffer for the
    " first time (like :next <file>), the buffer will be added as part of
    " BufAdd anyway, so just ignore it here.
    let ignoreBuf = expand('<abuf>')+0
    let lastBufNr = bufnr('$')
    while i <= lastBufNr
      if bufexists(i) && i != ignoreBuf
        if createMode
          call add(g:SB_MRUlist, i)
        else
          if index(g:SB_MRUlist, i) == -1
            call add(g:SB_MRUlist, i)
          endif
        endif
      endif
      let i = i + 1
    endwhile
  endif
endfunction " }}}

function! s:InputBufNumber() " {{{
  " Generate a line with spaces to clear the previous message.
  let i = 1
  let clearLine = "\r"
  while i < &columns
    let clearLine = clearLine . ' '
    let i = i + 1
  endwhile

  let bufNr = ''
  let abort = 0
  call s:Prompt(bufNr)
  let breakLoop = 0
  while !breakLoop
    try
      let char = getchar()
    catch /^Vim:Interrupt$/
      let char = "\<Esc>"
    endtry
    "exec BPBreakIf(cnt == 1, 2)
    if char == '^\d\+$' || type(char) == 0
      let char = nr2char(char)
    endif " It is the ascii code.
    if char == "\<BS>"
      let bufNr = strpart(bufNr, 0, strlen(bufNr) - 1)
    elseif char == "\<Esc>"
      let breakLoop = 1
      let abort = 1
    elseif char == "\<CR>"
      let breakLoop = 1
    else
      let bufNr = bufNr . char
    endif
    echon clearLine
    call s:Prompt(bufNr)
  endwhile
  if !abort && bufNr != ''
    call search('^'.bufNr.'\>', 'w')
  endif
endfunction

function! s:Prompt(bufNr)
  echon "\rEnter Buffer Number: " . a:bufNr
endfunction " }}}

let s:mySNR = ''
function! s:SNR()
  if s:mySNR == ''
    let s:mySNR = matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
  endif
  return s:mySNR
endfun
" Utility methods. }}}


""" START: Support for sorting... based on explorer.vim {{{
"""

"" START: Sort Utility methods. {{{
""
function! s:GetSortNameByType(sorttype)
  if match(a:sorttype, '\a') != -1
    return a:sorttype
  elseif a:sorttype == 0
    return "number"
  elseif a:sorttype == 1
    return "name"
  elseif a:sorttype == 2
    return "path"
  elseif a:sorttype == 3
    return "type"
  elseif a:sorttype == 4
    return "indicators"
  elseif a:sorttype == 5
    return "mru"
  else
    return ""
  endif
endfunction

function! s:GetSortTypeByName(sortname)
  if match(a:sortname, '\d') != -1
    return (a:sortname + 0)
  elseif a:sortname ==# "number"
    return 0
  elseif a:sortname ==# "name"
    return 1
  elseif a:sortname ==# "path"
    return 2
  elseif a:sortname ==# "type"
    return 3
  elseif a:sortname ==# "indicators"
    return 4
  elseif a:sortname ==# "mru"
    return 5
  else
    return -1
  endif
endfunction

function! s:GetSortCmpFnByType(sorttype)
  if a:sorttype == 0
    return "s:CmpByNumber"
  elseif a:sorttype == 1
    return "s:CmpByName"
  elseif a:sorttype == 2
    return "s:CmpByPath"
  elseif a:sorttype == 3
    return "s:CmpByType"
  elseif a:sorttype == 4
    return "s:CmpByIndicators"
  elseif a:sorttype == 5
    return "s:CmpByMRU"
  else
    return ""
  endif
endfunction

function! s:GetSortFieldExtractorByType(sorttype)
  if a:sorttype == 0
    return "s:GetBufNumber"
  elseif a:sorttype == 1
    return "s:GetBufferName"
  elseif a:sorttype == 2
    return "s:GetBufferPath"
  elseif a:sorttype == 3
    return "s:GetBufferType"
  elseif a:sorttype == 4
    return "s:GetBufferIndicators"
  elseif a:sorttype == 5
    return "s:GetBufferMruPosition"
  else
    return ""
  endif
endfunction

function! s:GetBuferNumber(line)
  return s:GetBufNumber(a:line)
endfunction

function! s:GetBufferName(line)
  return expand('#'.s:GetBufNumber(a:line).':t')
endfunction

function! s:GetBufferPath(line)
  return expand('#'.s:GetBufNumber(a:line).':p:h')
endfunction

function! s:GetBufferType(line)
  return expand('#'.s:GetBufNumber(a:line).':e')
endfunction

function! s:GetBufferIndicators(line)
  return s:GetBufIndicators(s:GetBufNumber(a:line))
endfunction

function! s:GetBufferMruPosition(line)
  let idx = index(g:SB_MRUlist, s:GetBufNumber(a:line))
  let idx = (idx == -1) ? 99999 : idx
  return idx
endfunction

""
"" END: Sort Utility methods. }}}

"" START: Compare methods. {{{
""

function! s:CompareBufs(buf1, buf2)
  return {s:sortCurCompFn}(a:buf1.field, a:buf2.field)
endfunction

function! s:CompareBufLines(line1, line2, ...)
  let sorttype = s:GetSortTypeByName(g:selBufDefaultSortOrder)
  let Extractor = function(s:GetSortFieldExtractorByType(sorttype))
  let Comparator = function(s:GetSortCmpFnByType(sorttype))
  return Comparator(Extractor(a:line1), Extractor(a:line2))
endfunction

function! s:CmpByName(name1, name2)
  if (g:selBufIgnoreCaseInSort && a:name1 <? a:name2) ||
        \ (!g:selBufIgnoreCaseInSort && a:name1 <# a:name2)
    return -g:selBufDefaultSortDirection
  elseif (g:selBufIgnoreCaseInSort && a:name1 >? a:name2) ||
        \ (!g:selBufIgnoreCaseInSort && a:name1 ># a:name2)
    return g:selBufDefaultSortDirection
  else
    return 0
  endif
endfunction

function! s:CmpByPath(path1, path2)
  if (g:selBufIgnoreCaseInSort && a:path1 <? a:path2) ||
        \ (!g:selBufIgnoreCaseInSort && a:path1 <# a:path2)
    return -g:selBufDefaultSortDirection
  elseif (g:selBufIgnoreCaseInSort && a:path1 >? a:path2) ||
        \ (!g:selBufIgnoreCaseInSort && a:path1 ># a:path2)
    return g:selBufDefaultSortDirection
  endif
  return 0
endfunction

function! s:CmpByNumber(num1, num2, ...)
  if a:num1 < a:num2
    return -g:selBufDefaultSortDirection
  elseif a:num1 > a:num2
    return g:selBufDefaultSortDirection
  else
    return 0
  endif
endfunction

function! s:CmpByType(type1, type2, ...)
  " If line1 doesn't have an extension
  if a:type1 == ""
    if a:type2 == ""
      return 0
    else
      return g:selBufDefaultSortDirection
    endif
  endif

  " If line2 doesn't have an extension
  if a:type2 == ""
    return -g:selBufDefaultSortDirection
  endif

  if a:type1 < a:type2
    return -g:selBufDefaultSortDirection
  elseif a:type1 > a:type2
    return g:selBufDefaultSortDirection
  else
    return 0
  endif
endfunction

function! s:CmpByIndicators(ind1, ind2, ...)
  return g:selBufDefaultSortDirection * s:CmpByName(a:ind1, a:ind2)
endfunction

function! s:CmpByMRU(mru1, mru2, ...)
  if g:selBufDisableMRUlisting
    return 0
  endif

  return g:selBufDefaultSortDirection * s:CmpByNumber(a:mru1, a:mru2)
endfunction

" END: Compare methods. }}}

" START: Interface to sort. {{{
"

" Reverse the current sort order
function! s:SortReverse()
  if exists("g:selBufDefaultSortDirection") &&
        \ g:selBufDefaultSortDirection == -1
    let g:selBufDefaultSortDirection = 1
    let s:sortdirlabel  = ""
  else
    let g:selBufDefaultSortDirection = -1
    let s:sortdirlabel  = "rev-"
  endif
  call s:SortBuffers(g:selBufAlwaysHideBufNums)
  let s:indList = ""
endfunction

" Toggle through the different sort orders
function! s:SortSelect(inc)
  " Select the next sort option
  let g:selBufDefaultSortOrder = s:GetSortTypeByName(g:selBufDefaultSortOrder)
  let g:selBufDefaultSortOrder = g:selBufDefaultSortOrder + a:inc

  " Wrap the sort type.
  if g:selBufDefaultSortOrder > s:sortByMaxVal
    let g:selBufDefaultSortOrder = 0
  elseif g:selBufDefaultSortOrder < 0
    let g:selBufDefaultSortOrder = s:sortByMaxVal
  endif

  call s:SortBuffers(g:selBufAlwaysHideBufNums)
  let s:indList = ""
endfunction

" Sort the file listing
function! s:SortBuffers(bufNumsHidden)
  " Save the line we start on so we can go back there when done
  " sorting
  call genutils#SaveSoftPosition('SortBuffers')

  if a:bufNumsHidden
    call s:AddBufNumbers()
  endif

  " First save the selection state.
  let selectedBuffers = s:MSGetSelectedBuffers()
  if s:MultiSelectionExists()
    MSClear
  endif

  try
    " Allow modification
    setlocal modifiable
    " Do the sort
    if search('^"= ', 'w')
      let bufs = []
      let sorttype = s:GetSortTypeByName(g:selBufDefaultSortOrder)
      let line = line('.')+1
      let enLine = line('$')
      let Extractor = function(s:GetSortFieldExtractorByType(sorttype))
      let s:sortCurCompFn = s:GetSortCmpFnByType(sorttype)
      while line <= enLine
        " FIXME: Extract name also, such that additional sorting can be done.
        call add(bufs, {'line': getline(line),
              \ 'field': Extractor(getline(line))})
        let line += 1
      endwhile
      call sort(bufs, function('s:CompareBufs'))
      let line = line('.')+1
      for buf in bufs
        call setline(line, buf.line)
        let line += 1
      endfor
    endif
  finally
    " Disallow modification
    setlocal nomodifiable
  endtry

  call s:MSSelectBuffers(selectedBuffers)

  " Update buffer-list again with the sorted list.
  if a:bufNumsHidden
    call s:RemoveBufNumbers()
  endif

  " Replace the header with updated information
  call s:UpdateHeader()

  " Return to the position we started on
  call genutils#RestoreSoftPosition('SortBuffers')
  call genutils#ResetSoftPosition('SortBuffers')
endfunction

" END: Interface to Sort. }}}

"""
""" END: Support for sorting... based on explorer.vim }}}


" Public API {{{
function! SBUpdateBuffer(bufNr)
  if bufexists(a:bufNr+0)
    call s:DynUpdate('u', a:bufNr + 0, 0)
  endif
endfunction

function! SBCurBufNumber()
  return SBBufNumber(line('.'))
endfunction

function! SBBufNumber(line)
  " Even when buffer numbers are hidden, we sometimes turn them on
  "   temporarily, so detect it and take advantage of it for faster buffer
  "   number determination.
  if g:selBufAlwaysHideBufNums && getline(a:line) !~# '^\d\+\s\+'
    if a:line <= s:headerSize
      return -1
    endif

    let bufIndex = a:line - s:headerSize - 1
    let bufNo = get(s:bufList, bufIndex) + 0
    if bufNo == ""
      return -1
    else
      return bufNo + 0
    endif
  else
    return s:GetBufNumber(getline(a:line))
  endif
endfunction

" Can't accept range as the user will not be able to use the return value then.
function! SBSelectedBuffers(fline, lline) " range 
  let bufList = map(SBSelectedBufNums(a:fline, a:lline), '"#".v:val.":p"')
  return bufList
endfunction

function! SBSelectedBufNums(fline, lline) " range 
  let bufNums = []
  if s:MultiSelectionExists()
    for sel in b:multiselRanges
      let fl = MSFL(sel)
      let ll = MSLL(sel)
      while fl <= ll
        let bufNo = s:GetBufNumber(getline(fl))
        if bufNo != -1
          call add(bufNums, bufNo)
        endif
        let fl = fl + 1
      endwhile
    endfor
  elseif a:fline > 0 && a:lline > 0
    let fl = a:fline
    while fl <= a:lline
      let bufNo = s:GetBufNumber(getline(fl))
      if bufNo != -1
        call add(bufNums, bufNo)
      endif
      let fl = fl + 1
    endwhile
  endif
  return bufNums
endfunction

""" BEGIN: Experimental API {{{

function! selectbuf#SBGet(var)
  return {a:var}
endfunction

function! selectbuf#SBSet(var, val)
  let {a:var} = a:val
endfunction

function! selectbuf#SBCall(func, ...)
  exec genutils#MakeArgumentString()
  exec "let result = {a:func}(".argumentString.")"
  return result
endfunction

function! selectbuf#SBEval(expr)
  exec "let result = ".a:expr
  return result
endfunction

""" END: Experimental API }}}
" Public API }}}
 

""" START: WinManager hooks. {{{

function! selectbuf#SelectBuf_Start()
  if s:myBufNum == -1
    if exists("g:selectbuf#userDefinedHideBufNums")
      unlet g:selectbuf#userDefinedHideBufNums
    else
      let g:selBufAlwaysHideBufNums = 1
    endif
    let s:myBufNum = bufnr('%')
  endif
  call SelectBuf_Refresh()
endfunction


" Called by WinManager for BufEnter event.
" Return invalid only when there are pending updates.
function! selectbuf#SelectBuf_IsValid()
  return g:selBufDelayedDynUpdate || (len(s:pendingUpdAxns) == 0)
endfunction


function! selectbuf#SelectBuf_Refresh()
  let s:opMode = 'WinManager'
  call selectbuf#ListBufs()
endfunction


function! selectbuf#SelectBuf_ReSize()
  call s:AdjustWindowSize()
endfunction

""" END: WinManager hooks. }}}

if g:selBufLauncher == '' && genutils#OnMS()
  "let g:selBufLauncher = '!start rundll32 url.dll,FileProtocolHandler'
  let g:selBufLauncher = '!start rundll32 SHELL32.DLL,ShellExec_RunDLL'
endif

" Do the actual initialization.
call selectbuf#Initialize()

call s:InitializeMRU()

" Restore cpo.
let &cpo = s:save_cpo
unlet s:save_cpo

" vim6:fdm=marker et sw=2
