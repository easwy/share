" Author: Gergely Kontra <kgergely@mcl.hu>
" Version: 0.32
" Description:
"   Use your tab key to do all your completion in insert mode!
"   The script remembers the last completion type, and applies that.
"   Eg.: You want to enter /usr/local/lib/povray3/
"   You type (in insert mode):
"   /u<C-x><C-f>/l<Tab><Tab><Tab>/p<Tab>/i<Tab>
"   You can also manipulate the completion type used by changing g:complType
"   variable.
"   You can cycle forward and backward with the <Tab> and <S-Tab> keys
"   (<S-Tab> will not work in the console version)
"   Note: you must press <Tab> once to be able to cycle back
" History:
"   0.3  Back to the roots. Autocompletion is another story...
"        Now the prompt appears, when showmode is on
"   0.31 Added <S-Tab> for backward cycling. (req by: Peter Chun)
"   0.32 Corrected tab-insertion/completing decidion (thx to: Lorenz Wegener)

if !exists('complType') "Integration with other copmletion functions...
  let complType="\<C-p>"
  im <C-X> <C-r>=CtrlXPP()<CR>

  fu! CtrlXPP()
    if &smd
      ec''|ec '-- ^X++ mode (/^E/^Y/^L/^]/^F/^I/^K/^D/^V/^N/^P/n/p)'
    en
    let complType=nr2char(getchar())
    if stridx(
	  \"\<C-E>\<C-Y>\<C-L>\<C-]>\<C-F>\<C-I>\<C-K>\<C-D>\<C-V>\<C-N>\<C-P>np",
	  \complType)!=-1
      if stridx("\<C-E>\<C-Y>",complType)!=-1 " no memory, just scroll...
	retu "\<C-x>".complType
      elsei stridx('np',complType)!=-1
	let g:complType=nr2char(char2nr(complType)-96)  " char2nr('n')-char2nr("\<C-n")
      el
	let g:complType="\<C-x>".complType
      en
      iun <Tab>
      iun <S-Tab>
      if g:complType=="\<C-p>" || g:complType=='p'
	im <Tab> <C-p>
	ino <S-Tab> <C-n>
      el
	im <Tab> <C-n>
	ino <S-Tab> <C-p>
      en
      retu g:complType
    el
      echohl "Unknown mode"
      retu complType
    en
  endf

  " From the doc |insert.txt| improved
  im <Tab> <C-p>
  inore <S-Tab> <C-n>
  " This way after hitting <Tab>, hitting it once more will go to next match
  " (because in XIM mode <C-n> and <C-p> mappings are ignored)
  " and wont start a brand new completion
  " The side effect, that in the beginning of line <C-n> and <C-p> inserts a
  " <Tab>, but I hope it may not be a problem...
  ino <C-n> <C-R>=<SID>SuperTab()<CR>
  ino <C-p> <C-R>=<SID>SuperTab()<CR>

  fu! <SID>SuperTab()
    if (strpart(getline('.'),col('.')-2,1)=~'^\s\?$')
      return "\<Tab>"
    el
      return g:complType
    en
  endf
en
