/****************************** Module Header *******************************
*
* Module Name: locate.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: locate.e,v 1.1 2002-10-06 23:22:35 aschn Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING" file of the
* Netlabs EPM Distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
****************************************************************************/

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc l, locate =  /* Note:  this DEFC also gets executed by the slash ('/') command. */
   universal default_search_options
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif
   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   args=strip(arg(1),'L')
compile if not defined(HIGHLIGHT_COLOR)
   if default_search_options<>'' then
compile endif
      delim=substr(args,1,1)
      p=pos(delim,args,2)
      user_options=''
      if p then
         user_options=substr(args,p+1)
         args=substr(args,1,p-1)
      endif
      if marktype() then
         all=''
      else           -- No mark, so override if default is M.
         all='A'
      endif
compile if defined(HIGHLIGHT_COLOR)
      search_len=length(args)-1   /***** added for hilite *****/
compile endif
      args=args|| delim || default_search_options || all || user_options
compile if not defined(HIGHLIGHT_COLOR)
   endif
compile endif
   --display -4
   'xcom l 'args
   --display 4
compile if defined(HIGHLIGHT_COLOR)
   call highlight_match(search_len)
compile endif
   return

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc c,change=
   universal lastchangeargs, default_search_options
compile if SETSTAY='?'
   universal stay
compile endif
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif

compile if SETSTAY
   call psave_pos(savepos)
compile endif
   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   args=strip(arg(1),'L')  /* Delimiter = 1st char, ignoring leading spaces. */
   user_options=''
   if args<>'' then        /* If args blank, use lastchangeargs. */
      if default_search_options='' then
         lastchangeargs=args
      else
         delim=substr(args,1,1)
         p=pos(delim,args,2)   /* find last delimiter of 2 or 3 */
         if p then
compile if defined(HIGHLIGHT_COLOR)
            search_len=p-2
compile endif
            p=pos(delim,args,p+1)   /* find last delimiter of 2 or 3 */
            if p>0 then
               user_options=substr(args,p+1)
               args=substr(args,1,p-1)
            endif
         else
            sayerror NO_REP__MSG
         endif
         if marktype() then
            all=''
         else           -- No mark, so override if default is M.
            all='A'
         endif
         lastchangeargs=args || delim || default_search_options || all || user_options
      endif
   endif
   if verify(upcase(user_options),'M','M') then
      call checkmark()
      /* Put this line back in if you want the M choice to force */
      /* the cursor to the start of the mark.                    */
;;;   call pbegin_mark()  /* mark specified - make sure at top of mark */
   endif
   --display -4
   'xcom c 'lastchangeargs
   --display 4

compile if SETSTAY='?'
   if stay then
compile endif
compile if SETSTAY
      call prestore_pos(savepos)
compile endif
compile if SETSTAY='?'
   endif
compile endif
   return

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E
; Highlight a "hit" after a Locate command or Repeat_find operation
compile if defined(HIGHLIGHT_COLOR)
defproc highlight_match(search_len)
   if not rc then
      col = getpminfo(EPMINFO_SEARCHPOS)
      circleit LOCATE_CIRCLE_STYLE, .line, col,
         col+getpminfo(EPMINFO_LSLENGTH)-1,
         LOCATE_CIRCLE_COLOR1, LOCATE_CIRCLE_COLOR2
;     refresh
   endif
   return
compile endif

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: searchdlg       syntax:   searchdlg [next]               ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal search & replace dlg. ³
³                   This is done by posting a EPM_POPCHANGEDLG message to the³
³                   EPM Book window.                                         ³
³                   if the [next] param = 'F'  a find next will take place   ³
³                   if the [next] param = 'C'  a change next will take place ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc searchdlg
   universal default_search_options, search_len

   parse value upcase(arg(1)) with uparg .

   if uparg='C' then
      'c'                             /* repeat last change */
   elseif uparg='F' then
      repeat_find
compile if defined(HIGHLIGHT_COLOR)
      call highlight_match(search_len)
compile endif
   else  -- The application will free the buffer allocated by this macro !!!
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5128,               -- EPM_POPCHANGEDLG
                         0,
                         put_in_buffer(default_search_options))
   endif
   return

; ---------------------------------------------------------------------------
; From EPMSMP\GLOBFIND.E
/* Ctrl-G = Global-find key.    Standard E3 lets you press Ctrl-F to  */
/* repeat-find in the current file.  Now Ctrl-G does the repeat-find  */
/* on ALL the files in the ring.  Very useful when I'm editing several*/
/* small program modules and I want to find where something's defined.*/

def c_g = 'GlobalFind'

defc globalfind, gfind, globallocate, glocate, gl
   universal search_len
   -- Remember our current file so we don't search forever.
   -- (Sometimes doesn't works.)
   getfileid StartFileID

   -- get current search direction
   getsearch cursearch
   parse value cursearch with . c_or_l search
   delim = leftstr(search,1)
   parse value cursearch with searchcmd (delim) searchstring (delim) searchoptions (delim)
   if searchoptions = '' then
      parse value cursearch with searchcmd (delim) searchstring (delim) searchoptions
   endif
   Minuspos = lastpos( '-', searchoptions )
   Pluspos = lastpos( '+', searchoptions )
   if Minuspos > Pluspos then
      Foreward = 0
   else
      Foreward = 1
   endif

   -- First repeat-find in current file in case we don't have to move.
   repeat_find
   call highlight_match(search_len)
   if rc=0 then
      stop
   endif
   fileid=StartFileID
   loop
      if Foreward = 1 then
         nextfile
      else
         prevfile
      endif
      getfileid fileid
      activatefile fileid
      -- Include this refresh if you like to see each file as it's
      -- searched.  Causes too much screen flashing for my taste,
      --refresh

      -- Start from top of file, save current posn in case no match.
      call psave_pos(save_pos)
      if Foreward = 1 then
         top
         .col=1
      else
         bottom
         endline
      endif
      repeat_find
      if rc = 1 then
         refresh
      endif
      call highlight_match(search_len)
      -- Flickers most of the times instead of letting the highlight circle stay
      if rc=0 then
         --display -4
         if fileid=StartFileID then
            sayerror "String only found in this file"
         else
            sayerror 0
         endif
         --display 4
         leave
      else
         -- no match in file - restore file location
         call prestore_pos(save_pos)
      endif
      if fileid=StartFileID then
         --display -4
         sayerror "String not found in any file of the ring"
         --display 4
         leave
      endif
   endloop
   activatefile fileid
   return

; ---------------------------------------------------------------------------
; From EPMSMP\REVERSE.E
; Ctrl+- toggles the search direction.
; Search options for specifying the direction:
;    F  start searching from the start of line
;    R  start searching from the end of line
;    +  start searching from the start of text
;    -  start searching from the end of text
; The relevant options are + and -, F or R is set automatically.
;
; Original by Larry Margolis:
;    Repeat the previous Locate, but in the reverse direction.
;    E.g., if you search for a string that you know exists, but
;    it's not found before the end of the file, press Ctrl+minus
;    to repeat the search for the same string looking from the
;    cursor position to the beginning of the file.
; Changed:
;    Toggles the search direction (options +F or -R) without any
;    following locate action.
def c_minus =
   getsearch oldsearch
   -- get delimiter
   parse value oldsearch with . c_or_l search
   delim = leftstr(search,1)
   -- get searchoptions
   parse value oldsearch with searchcmd (delim) searchstring (delim) searchoptions (delim)
   if searchoptions = '' then
      parse value oldsearch with searchcmd (delim) searchstring (delim) searchoptions
   endif
   --sayerror 'searchstring = <'searchstring'>, searchoptions = <'searchoptions'>'

   Minuspos = lastpos( '-', searchoptions )
   Pluspos = lastpos( '+', searchoptions )
   -- remove + and - from searchoptions
   if Minuspos > 0 then
      searchoptions = delstr( searchoptions, Minuspos, 1 )
   endif
   if Pluspos > 0 then
      searchoptions = delstr( searchoptions, Pluspos, 1 )
   endif
   -- exchange + and -
   if Minuspos > Pluspos then
      searchoptions=searchoptions'+'
      sayerror 'Changed search direction to: foreward'
   else
      searchoptions=searchoptions'-'
      sayerror 'Changed search direction to: back'
   endif

   Rpos = lastpos( 'R', translate(searchoptions) )
   Fpos = lastpos( 'F', translate(searchoptions) )
   -- remove F and R from searchoptions
   if Rpos > 0 then
      searchoptions = delstr( searchoptions, Rpos, 1 )
   endif
   if Fpos > 0 then
      searchoptions = delstr( searchoptions, Fpos, 1 )
   endif
   -- exchange R and F
   if Rpos > Fpos then
      searchoptions=searchoptions'F'
   else
      searchoptions=searchoptions'R'
   endif

   newsearch = searchcmd' 'delim''searchstring''delim''searchoptions''delim
   setsearch newsearch

   --sayerror 'OLD: <'oldsearch'> NEW: <'newsearch'> oldminuspos='minuspos' oldRpos='Rpos
   --OLD: <xcom l aCAcD> NEW: <xcom l aCAcD-R> oldminuspos=0 oldRpos=0
   return

; ---------------------------------------------------------------------------
; From EPMSMP\GLOBCHNG.E
defc globchng, globalchange, gchange, gc
   universal lastchangeargs, default_search_options
compile if SETSTAY='?'
   universal stay
compile endif

   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   user_options=''
   change_args=strip(arg(1),'L')  /* Delimiter = 1st char, ignoring leading spaces. */
   delim=substr(change_args,1,1)
   p=pos(delim, change_args, 2)   /* find last delimiter of 2 or 3 */
   if p then
      p=pos(delim, change_args, p+1)   /* find last delimiter of 2 or 3 */
      if p>0 then
         user_options=substr(change_args, p+1)
         change_args=substr(change_args,1,p-1)
      endif
   else
      sayerror NO_REP__MSG
      return
   endif
   if verify(upcase(default_search_options),'M','M') then
      user_options = 'A'user_options
   endif
   change_args=change_args || delim || default_search_options || user_options
   backwards = 0
   p1 = lastpos('-', default_search_options || user_options)
   if p1 then
      if p1 > lastpos('+', default_search_options || user_options) then
         backwards = 1
      endif
   endif
   rev = 0  -- changed to rev, because reverse is a statement
   p1 = lastpos('R', upcase(default_search_options || user_options))
   if p1 then
      if p1 > lastpos('F', upcase(default_search_options || user_options)) then
         rev = 1
      endif
   endif

   /* Remember our current file so we don't search forever.  */
   getfileid StartFileID
   change_count = 0

   loop
      /* Include this refresh if you like to see each file as it's */
      /* searched.  Causes too much screen flashing for my taste,  */
;;       refresh

      /* Start from top of file, save current posn in case no match. */
      call psave_pos(save_pos)
      if backwards then
         bottom
         if rev then
            end_line
         else
            begin_line
         endif
      else
         0
      endif
      'xcom c' change_args
      if rc=0 then
         change_count = change_count + 1
compile if SETSTAY='?'
         if stay then
compile endif
compile if SETSTAY
            call prestore_pos(save_pos)
compile endif
compile if SETSTAY='?'
         endif
compile endif
      else
         /* no match in file - restore file location */
         call prestore_pos(save_pos)
      endif
      nextfile
      getfileid fileid
      if fileid=StartFileID then
         leave
      endif
   endloop
   if change_count = 1 then
      files = 'file.'
   else
      files = 'files.'
   endif
   sayerror 'String changed in' change_count files
   return

; ---------------------------------------------------------------------------
; From EPMSMP\GREP.E
; Call an external GREP utility and display the results in an EPM file.
; The modified Alt+1 definition in ALT_1.E will let you place the
; cursor on a line in the results file and press Alt+1 to load the
; corresponding source file.

; by Larry Margolis
/*
defc scan, grep =
   sayerror 'Scanning files...'
   call redirect('grep','/y /q /l' arg(1))
   if .last=0 then
      'q'
      sayerror 'No hits.'
   endif
*/
defc scan, grep =
   sayerror 'Scanning files...'
   -- Changed to support only Gnu grep.
   -- Options:
   --    -i  case insensitive
   --    -n  show line numbers
   call redirect('grep','-in' arg(1))
   if .last=0 then
      'q'
      sayerror 'No hits.'
   else
      sayerror ''
   endif
   return

defproc redirect(cmd)
   universal vTEMP_PATH
   outfile=vTEMP_PATH || substr(cmd'_______',1,8) || '.out'
   quietshell cmd arg(2) '>'outfile '2>&1'
   if RC = sayerror('Insufficient memory') or
      RC = sayerror('File Not found')      then stop; endif
   'e' outfile
   .filename='.Output from' cmd arg(2)
   call erasetemp(outfile)
   return


