/****************************** Module Header *******************************
*
* Module Name: locate.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: locate.e,v 1.11 2004-03-07 08:40:18 aschn Exp $
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

/*
Todo:
-  Make the use of Ralph Yozzo's grep possible
*/

; Undocumented:
; display -8 ==> messages go only to the msg line, not to the msg box.
; display 8  ==> reenables messages from a previous display -8
; The rest is documented in epmtech.inf.

const
compile if not defined(NEPMD_SCROLL_AFTER_LOCATE)  --<-------------------------------------------- Todo
   -- Amount of lines to scroll:
   -- 0   ==> try to prevent scrolling (standard)
   -- > 0 ==> scroll from top
   -- < 0 ==> scroll from bottom
   NEPMD_SCROLL_AFTER_LOCATE = 0
compile endif

definit
   universal search_len
   search_len = 5     -- Initialize to anything, to prevent possible "Invalid number argument"

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc l, locate =  /* Note:  this DEFC also gets executed by the slash ('/') command. */
   universal default_search_options
   universal search_len
   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   args = strip( arg(1), 'L' )
   delim = substr( args, 1, 1 )
   p = pos( delim, args, 2 )
   user_options = ''
   if p then
      user_options = substr( args, p + 1 )
      args = substr( args, 1, p - 1 )
   endif
   if marktype() then
      all=''
   else           -- No mark, so override if default is M.
      all='A'
   endif
   search_len = length(args) - 1   /***** added for hilite *****/
   args = args''delim''default_search_options''all''user_options
   display -8
   'xcom l 'args
   display 8
   call highlight_match(search_len)
   return

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc c, change =
   universal lastchangeargs, default_search_options  -- better use NEPMD.INI to make them global for all EPM threads
compile if SETSTAY = '?'
   universal stay
compile endif
   universal search_len

   call psave_pos(savepos)
   args = strip( arg(1), 'L')
   -- Insert default_search_options just before supplied options (if any)
   -- so the supplied options will take precedence.
   if args <> '' then         -- If args not blank, set lastchangeargs.
      delim = substr( args, 1, 1)  -- get 1st delimiter
      p2 = pos( delim, args, 2)    -- check 2nd delimiter of 2 or 3
      if p2 then
         search_len = p2 - 2       -- for highlighting = length(searchstring)
      else
         sayerror NO_REP__MSG
         return
      endif
      parse value args with (delim)searchstring(delim)replacestring(delim)user_options
      user_options = strip( user_options, 'T', delim)

      -- Build searchoptions. Just append evrything, the last option wins.
      -- The code below cleans up the options.
      searchoptions = translate(default_search_options''user_options)
      if not marktype() then                -- if no text marked
         searchoptions = searchoptions'A'   -- override a possible 'M' option
      endif

      -- Remove multiple and excluding options and spaces
      ExcludeList = '+- FR BT AM EC GXW'    -- for every word in this list: every char excludes each other
      -- Other options: '* K ^ N D'
      rest = searchoptions
      searchoptions = ''
      do while rest <> ''
         parse value rest with next 2 rest  -- parse 1 char of rest
         -- Remove all spaces
         if next = ' ' then
            iterate
         elseif pos( next, rest) = 0 then   -- if not found in rest
            -- Find excluding options
            ExcludeWrd = ''
            do w = 1 to words(ExcludeList)
               wrd = word( ExcludeList, w)
               if pos( next, wrd) then
                  ExcludeWrd = wrd          -- ExcludeWrd = word of ExcludeList where next belongs to
                  leave
               endif
            enddo
            if not verify( rest, ExcludeWrd, 'M') then  -- if rest doesn't contain chars of ExcludeWrd
               searchoptions = searchoptions''next      -- append next
            endif
         endif
      enddo
;         call NepmdPmPrintf( 'strings = |'searchstring'|'replacestring'|, options = |'searchoptions'|, delim = |'delim'|')
      lastchangeargs = delim''searchstring''delim''replacestring''delim''searchoptions
   endif

;     /* Put this lines back in if you want the M choice to force */
;     /* the cursor to the start of the mark.                    */
;    if verify( upcase(user_options), 'M', 'M' ) then
;       call checkmark()  -- ??? returns (0|1)
;       call pbegin_mark()  /* mark specified - make sure at top of mark */
;    endif

   display -8
   -- Execute the change command with args from arg(1); if empty, with args from
   -- the last change command. default_search_options are added.
   'xcom c 'lastchangeargs
   display 8

   if rc = 0 then  -- if found
      -- Restore pos after change command if (SETSTAY = '?' & stay = 1) or SETSTAY = 1
compile if SETSTAY = '?'
      if stay then
compile endif
compile if SETSTAY
         call prestore_pos(savepos)
compile endif
compile if SETSTAY = '?'
      endif
compile endif
   else            -- if not found
      call prestore_pos(savepos)
   endif

   return

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E
; Highlight a "hit" after a Locate command or Repeat_find operation
defproc highlight_match(search_len)
   if not rc then  -- if found; rc was set from last 'c'|'l'|repeat_find
      col = getpminfo(EPMINFO_SEARCHPOS)
      --------------------------------------------------------------------------------------- Todo: make that optional
compile if NEPMD_SCROLL_AFTER_LOCATE
      -- begin scroll line on window
      oldline = .line
      AmountOfLines = NEPMD_SCROLL_AFTER_LOCATE
      if AmountOfLines > 0 then
         .cursory = min( AmountOfLines, .windowheight)          -- AmountOfLines from top
      elseif AmountOfLines < 0 then
         .cursory = max( 1, .windowheight + AmountOfLines + 1)  -- AmountOfLines from bottom
      endif
      .line = oldline
      -- end scroll line on window
compile endif
      circleit LOCATE_CIRCLE_STYLE,
         .line,
         col,
         col + getpminfo(EPMINFO_LSLENGTH) - 1,
         LOCATE_CIRCLE_COLOR1,
         LOCATE_CIRCLE_COLOR2
;     refresh
   endif
   return

; ---------------------------------------------------------------------------
; Used to be called with 'postme'.
defc highlightmatch
   search_len = arg(1)
   call highlight_match(search_len)

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
      display -8
      repeat_find
      display 8
      call highlight_match(search_len)
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

-- Changed to Ctrl+V, because Ctrl+G is already used for the 'ring_more' command

def c_v = 'GlobalFind'

defc globalfind, gfind, globallocate, glocate, gl
   universal search_len
   -- Remember our current file so we don't search forever.
   -- (Sometimes doesn't work.)
   getfileid StartFileID

   -- get current search direction
   getsearch cursearch
   parse value cursearch with . c_or_l search
   delim = leftstr( search, 1 )
   parse value cursearch with searchcmd (delim)searchstring(delim)searchoptions(delim)
   if searchoptions = '' then
      parse value cursearch with searchcmd (delim)searchstring(delim)searchoptions
   endif
   Minuspos = lastpos( '-', searchoptions )
   Pluspos  = lastpos( '+', searchoptions )
   if Minuspos > Pluspos then
      Forwards = 0
   else
      Forwards = 1
   endif

   -- First repeat-find in current file in case we don't have to move.
   display -8
   repeat_find
   display 8
   call highlight_match(search_len)
   if rc = 0 then  -- if found
      --stop  -- better use return
      return
   endif
   fileid = StartFileID
   loop
      if Forwards = 1 then
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
      if Forwards = 1 then
         top
         .col=1
      else
         bottom
         endline
      endif
      display -8
      repeat_find
      display 8
      if rc = 0 then  -- if found
         refresh
         'postme highlightmatch 'search_len  -- postme required
         display -8
         if fileid = StartFileID then
            sayerror "String only found in this file"
         else
            sayerror 0
         endif
         display 8
         leave
      else
         -- no match in file - restore file location
         call prestore_pos(save_pos)
      endif
      if fileid = StartFileID then
         display -8
         sayerror "String not found in any file of the ring"
         display 8
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
;    Doesn't produce an error msg anymore if oldsearch = empty.
def c_minus = 'ToggleSearchDirection'

defc ToggleSearchDirection

   -- Get search
   getsearch oldsearch
   -- Get delimiter
   parse value oldsearch with . c_or_l search
   if search <> '' then  -- if search is set
      delim = leftstr( search, 1)
      -- Get searchcmd, searchstring, replacestring and searchoptions
      if upcase(C_or_l) = 'C' then
         parse value oldsearch with searchcmd (delim)searchstring(delim)replacestring(delim)searchoptions
      else
         parse value oldsearch with searchcmd (delim)searchstring(delim)searchoptions
      endif
      searchcmd = strip(searchcmd)
      if searchcmd = '' then
         searchcmd = 'xcom l'
      endif
      searchoptions = strip( searchoptions, 'T', delim)
   else  -- if no search cmd was executed before, set this to make setsearch happy
      searchcmd     = 'xcom l'
      delim         = \1
      searchstring  = ''
      searchoptions = ''
   endif
         --call NepmdPmPrintf( 'cmd = |'searchcmd'|, string = |'searchstring'|, options = |'searchoptions'|, delim = |'delim'|')

   searchoptions = upcase(searchoptions)
   Minuspos = lastpos( '-', searchoptions)
   Pluspos  = lastpos( '+', searchoptions)

   -- Remove every ( |+|-|F|R) from searchoptions
   --    Note: translate doesn't allow '' as 4th parameter (pad).
   rest = searchoptions
   searchoptions = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char
      if verify( next, ' +-FR', 'N') then  -- if no match
         searchoptions = searchoptions''next
      endif
   enddo

   -- Append +F or -R
   if Minuspos > Pluspos then  -- in searchoptions: the last option wins
      searchoptions = searchoptions'+F'
      sayerror 'Changed search direction to: forwards'
   else
      searchoptions = searchoptions'-R'
      sayerror 'Changed search direction to: backwards'
   endif

   -- Set search
   if upcase(c_or_l) = 'C' then
      newsearch = searchcmd' 'delim''searchstring''delim''replacestring''delim''searchoptions
   else
      newsearch = searchcmd' 'delim''searchstring''delim''searchoptions
   endif
   setsearch newsearch  -- setsearch requires a space after searchcmd, because it prooves if searchcmd is valid

   --call NepmdPmPrintf( 'asc(delim) = 'asc(delim)', oldsearch = |'oldsearch'|, newsearch = |'newsearch'|')
   return

; ---------------------------------------------------------------------------
; From EPMSMP\GLOBCHNG.E
defc globchng, globalchange, gchange, gc
;                                --<-------------------------------  todo: rewrite
   universal lastchangeargs, default_search_options
compile if SETSTAY = '?'
   universal stay
compile endif

   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   user_options = ''
   change_args = strip( arg(1), 'L' )  /* Delimiter = 1st char, ignoring leading spaces. */
---- set args = lastchangeargs if no delim
   if strip(change_args) = '' then
      change_args = lastchangeargs
   endif
----
   delim = substr( change_args, 1, 1 )
   p = pos( delim, change_args, 2 )   /* find last delimiter of 2 or 3 */
   if p then
      p = pos( delim, change_args, p + 1 )   /* find last delimiter of 2 or 3 */
      if p > 0 then
         user_options = substr( change_args, p + 1 )
         change_args = substr(change_args, 1, p - 1 )
      endif
----
      search_len = p - 2
----
   else
----      sayerror '--test-- delim = |'delim'|, change_args = |'change_args'|, p = |'p'|'; stop
      sayerror NO_REP__MSG
      return
   endif
   if verify( upcase(default_search_options), 'M', 'M' ) then
      user_options = 'A'user_options
   endif
   change_args = change_args''delim''default_search_options''user_options
   backwards = 0
   p1 = lastpos( '-', default_search_options''user_options )
   if p1 then
      if p1 > lastpos( '+', default_search_options''user_options ) then
         backwards = 1
      endif
   endif
   rev = 0  -- changed to rev, because reverse is a statement
   p1 = lastpos( 'R', upcase(default_search_options''user_options) )
   if p1 then
      if p1 > lastpos( 'F', upcase(default_search_options''user_options) ) then
         rev = 1
      endif
   endif
----
   p1 = pos('*', default_search_options''user_options)
   if p1 = 0 then
      change_args = change_args'*'
   endif
----


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
      display -8
      'xcom c' change_args
      display 8
      if rc = 0 then
         change_count = change_count + 1
         'ResetDateTimeModified'
         'RefreshInfoLine MODIFIED'
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
      if fileid = StartFileID then
         leave
      endif
   endloop
   if change_count = 1 then
      files = 'file.'
   else
      files = 'files.'
   endif
   display -8
   sayerror 'String changed in' change_count files
   display 8
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
; Todo:
; Replace an relative filespec with a full one to make Alt+1 work than
; or save the current dir of grep somewhere in the temp file.
;
; Syntax:
;    grep [grepoptions] string filespec
;
; If no grepoptions where specified, the defaultgrepopt are submitted to grep.
;
; Requires GNU grep. Doesn't work with Ralph Yozzo's grep anymore.
;
defc scan, grep =
   -- Options:
   --    -i  case insensitive
   --    -n  show line numbers
   defaultgrepopt = '-in'
;   CurDir = directory()
;   -- change to path of current file
;   call directory( .filename'\..' )
   display -8
   arg1 = arg(1)
   -- parse options
   grepargs = arg1
   grepopt  = ''
   do i = 1 to words(arg1)
      next = word( arg1, i)
      if substr( next, 1, 1) = '-' then
         grepopt  = grepopt' 'next
         grepargs = delword( grepargs, 1, 1)
      endif
   enddo
   grepopt = strip(grepopt)
   if grepopt = '' then
      grepopt = defaultgrepopt
   endif
   sayerror 'Scanning files...'
   -- Changed to support only Gnu grep.
   call redirect('grep',grepopt grepargs)
;   call directory( CurDir )
   if .last=0 then
      'q'
      sayerror 'No hits.'
   else
      sayerror 0
   endif
   display 8
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

; ---------------------------------------------------------------------------
defc findmark
   call psave_pos(saved_pos)
   if marktype() = '' then  -- text marked?
     'markword'
   endif
   -- Get active mark coordinates and fileid
   getmark  first_line, last_line, first_col, last_col, mark_fileid
   if last_line <> first_line then
      last_line = first_line
      endline
      last_col = .col
   endif
   searchstring = substr( textline( first_line ), first_col, last_col - first_col + 1 )
   call prestore_pos(saved_pos)
   if searchstring <> '' then
      'l 'searchstring''
   endif

; ---------------------------------------------------------------------------
; Support for Graphical File Comparison
; Compares current file with another. File open box of GFC will open.
; If current file is located in any tree of %NEPMD_ROOTDIR%\netlabs
; or %NEPMD_ROOTDIR%\myepm, then the current file is compared with
; the corresponding file of the other tree.
defc GfcCurrentFile
   fn = .filename
   GfcParams = '"'fn'"'
   NepmdRootDir = NepmdScanEnv('NEPMD_ROOTDIR')
   parse value NepmdRootDir with 'ERROR:'rc
   if rc = '' then
      if abbrev( upcase(fn), upcase(NepmdRootDir)) then
         p1 = length(NepmdRootDir)
         p2 = pos( '\', fn, p1 + 2)
         next = substr( fn, p1 + 2, max( p2 - p1 - 2, 0))
         if upcase(next) = 'MYEPM' then
            fn2 = substr( fn, 1, p1)'\netlabs'substr( fn, p2)
            if NepmdFileExists(fn2) then
               GfcParams = GfcParams' "'fn2'"'
            endif
         elseif upcase(next) = 'NETLABS' then
            fn2 = substr( fn, 1, p1)'\myepm'substr( fn, p2)
            if NepmdFileExists(fn2) then
               GfcParams = GfcParams' "'fn2'"'
            endif
         endif
      endif
   else
      sayerror 'Environment var NEPMD_ROOTDIR not set'
   endif
   'start /f gfc 'GfcParams
   return

; ---------------------------------------------------------------------------
; Moved from STDKEYS.E
def c_f=
   universal search_len
   sayerror 0
   display -8
   repeat_find       /* find next */
   display 8
   call highlight_match(search_len)


