" Vim syntax file
" Language:	gdb syntax file
" Maintainer:	<xdegaye at users dot sourceforge dot net>
" Last Change:	Apr 3 2004

if exists("b:current_syntax")
    finish
endif

setlocal iskeyword=a-z,A-Z,48-57,-

syn keyword Cmd contained
	\ ac[tions] add-sh[ared-symbol-files] add-sy[mbol-file] adv[ance] app[end]
	\ apr[opos] at[tach] aw[atch] ba[cktrace] b[reak] bt cal[l] cat[ch] cd
	\ cl[ear] col[lect] comm[ands] compa[re-sections] compl[ete] cond[ition]
	\ c cont[inue] cor[e-file] cr[eatevar] def[ine] d del[ete] det[ach] dir[ectory]
	\ disab[le] disas[semble] disp[lay] dl[l-symbols] doc[ument] don[t-repeat]
	\ down down-[silently] du[mp] ec[ho] ed[it] ena[ble] end ex[ec-file]
	\ fil[e] fin[ish] fl[ushregs] fo[rward-search] f[rame] g[enerate-core-file]
	\ ha[ndle] hb[reak] he[lp] if ig[nore] i inf[o] ins[pect] interp[reter-exec]
	\ interr[upt] j[ump] k[ill] l[ist] lo[ad] mac[ro] mai[ntenance] mak[e]
	\ me[m] mo[nitor] n next nexti ni no[sharedlibrary] ou[tput] ov[erlay]
	\ pas[scount] pat[h] p print printf pt[ype] pw[d] Quit q[uit] rb[reak]
	\ rem[ote] res[tore] ret[urn] rev[erse-search] r[un] rw[atch]
	\ sa[ve-tracepoints] sea[rch] sec[tion] sel[ect-frame] set sha[redlibrary]
	\ sho[w] si sig[nal] so[urce] s step stepi stepp[ing] sto[p] sy[mbol-file]
	\ ta[rget] tb[reak] tc[atch] td[ump] tf[ind] thb[reak] t thr[ead] tp
	\ tr[ace] tstar[t] tstat[us] tsto[p] tt[y] u und[isplay] uns[et] unt[il] up
	\ up-[silently] wa[tch] wha[tis] whe[re] while while-[stepping] ws x

syn keyword Info contained
	\ ad[dress] al[l-registers] ar[gs] b[reakpoints] ca[tch] com[mon]
	\ cop[ying] dc[ache] di[splay] dl[l] e[xtensions] fi[les] fl[oat]
	\ fr[ame] fu[nctions] h[andle] li[ne] lo[cals] ma[cro] me[m] proc
	\ prog[ram] reg[isters] rem[ote-process] sc[ope] se[t] sh[aredlibrary]
	\ si[gnals] source sources st[ack] sy[mbol] ta[rget] te[rminal]
	\ th[reads] tr[acepoints] ty[pes] u[dot] va[riables] ve[ctor] w3[2]
	\ war[ranty] wat[chpoints]

syn keyword ShwSet contained
	\ an[notate] archd[ebug] archi[tecture] arg[s] au[to-solib-add]
	\ b[acktrace-below-main] can[-use-hw-watchpoints] cas[e-sensitive]
	\ cha[rset] che[ck] coe[rce-float-to-double] comp[laints]
	\ conf[irm] debug debugexc[eptions] debugexe[c]
	\ debugev[ents] debugm[emory] debugv[arobj] debug-[file-directory]
	\ dem[angle-style] dis[assembly-flavor] do[wnload-write-size]
	\ ed[iting] end[ian] env[ironment] ev[entdebug] exe[c-done-display]
	\ f[ollow-fork-mode] g[nutarget] he[ight] hi[story] i[nput-radix]
	\ la[nguage] li[stsize] m[ax-user-call-depth] new-c[onsole] new-g[roup]
	\ op[aque-type-resolution] os osa[bi] ou[tput-radix] ov[erload-resolution]
	\ pag[ination] pri[nt] prompt prompt-[escape-char] ra[dix]
	\ remote remotea[ddresssize] remoteba[ud] remotebr[eak] remotec[ache]
	\ remotedeb[ug] remotedev[ice] remotelogb[ase] remotelogf[ile]
	\ remotet[imeout] remotew[ritesize] sc[heduler-locking] se[rial]
	\ solib-a[bsolute-prefix] solib-s[earch-path] ste[p-mode]
	\ sto[p-on-solib-events] sy[mbol-reloading] str[uct-convention]
	\ t[rust-readonly-sections] un[windonsignal]
	\ verb[ose] wat[chdog] wi[dth] wr[ite]

syn keyword Shw contained
	\ comm[ands] conv[enience] cop[ying] dir[ectories] pat[hs] us[er] va[lues]
	\ vers[ion] war[ranty]

syn keyword St contained ext[ension-language] va[riable]

if ! exists("b:current_syntax") || b:current_syntax != "gdbvim"
    syn match Command display "^\s*\k\+"
	\ contains=Cmd

    syn match Help display "^\s*he\%[lp]\s*\k\+"
	\ contains=Cmd

    syn match Information display "\(^\s*inf\%[o]\s*\)\@<=\k\+"
	\ contains=Info

    syn match Show display "\(^\s*sho\%[w]\s*\)\@<=\k\+"
	\ contains=ShwSet,Shw

    syn match Set display "\(^\s*set\s*\)\@<=\k\+"
	\ contains=ShwSet,St
endif

syn match gdbChar display "'[^`']\+'"
syn match gdbVar display "\$\d\+\>"
syn match gdbStr display /""\|".\{-}[^\\]"/

syn case ignore
syn match cNumbers display transparent "\<\d\|\.\d\|[+-] *\d\|[+-] *\.\d" contains=cNumber,cFloat

syn match cNumber display contained "[ +-]*\x\+\>"

syn match cFloat display contained "[ +-]*\d\+f\>"
syn match cFloat display contained "[ +-]*\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\=\>"
syn match cFloat display contained "[ +-]*\.\d\+\(e[-+]\=\d\+\)\=[fl]\=\>"
syn match cFloat display contained "[ +-]*\d\+e[-+]\=\d\+[fl]\=\>"
syn case match

high def link Cmd	    Statement
high def link Info	    Type
high def link ShwSet	    Type
high def link Shw	    Type
high def link St	    Type
high def link gdbStr	    String
high def link gdbChar	    Character
high def link gdbVar	    Identifier
high def link cNumber	    Number
high def link cFloat	    Float

let b:current_syntax = "gdb"

