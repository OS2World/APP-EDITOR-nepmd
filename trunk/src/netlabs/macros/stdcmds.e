/****************************** Module Header *******************************
*
* Module Name: stdcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdcmds.e,v 1.21 2005-11-16 16:47:05 aschn Exp $
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

;
; STDCMDS.E            Alphabetized by command name.
;

defc alter =
   parse value upcase(arg(1)) with c1 c2 cnt .
   if length(c1)<>1 then
      if length(c1)<>2 | verify(c1, HEXCHARS) then
         sayerror -328 -- 'Invalid first parameter.'
      endif
      c1 = chr((pos(leftstr(c1,1), HEXCHARS) - 1) * 16 + pos(rightstr(c1,1), HEXCHARS) - 1)
   endif
   if length(c2)<>1 then
      if length(c2)<>2 | verify(c2, HEXCHARS) then
         sayerror -329  -- 'Invalid second parameter.'
      endif
      c2 = chr((pos(leftstr(c2,1), HEXCHARS) - 1) * 16 + pos(rightstr(c2,1), HEXCHARS) - 1)
   endif
   delim = substr(HEXCHARS, verify(HEXCHARS, c1||c2), 1)  -- Pick first char. not in c1 || c2
   change_cmd = 'c' delim || c1 || delim || c2 || delim
   if cnt='' then
      change_cmd
   elseif cnt='*' | cnt='M*' | cnt='*M' then
      change_cmd cnt
   elseif isnum(cnt) then
      do i=1 to cnt
         change_cmd
      enddo
   else
      sayerror -330 -- 'Invalid third parameter'
   endif

; Moved file defs to FILE.E

defc app, append =            -- With linking, PUT can be an external module.
   'put' arg(1)               -- Collect the names; the module is named PUT.EX.

defc asc=
   parse arg i '=' .
   if i='' then
      getline line
      i=substr(line,.col,1)
   endif
   sayerror 'asc 'i'='asc(i)''

;   autoshell off/on/0/1
;
; specifies whether E should automatically pass internally-unresolved commands
; to DOS.  Autoshell is an internal command; this DEFC is a simple front end
; to allow the user to type off/on/0/1.  It calls the internal command via
; 'xcom autoshell'.
;
; Users who have very long path-search times might prefer to execute
; "autoshell 0" somewhere in their start-up sequence.

defc autoshell=
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      .autoshell = 1
   elseif uparg=OFF__MSG or uparg='0' then
      .autoshell = 0
   else
      sayerror 'AUTOSHELL =' .AUTOSHELL
   endif

defc bottom,bot=
   bottom

; Moved defc c,change to LOCATE.E

defc center=
   call pcenter_mark()

defc chr=
   parse arg i '=' .
   sayerror 'chr 'i'='chr(i)''

defc close=
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       41,                 -- WM_CLOSE
                       0,
                       0)

compile if DYNAMIC_CURSOR_STYLE
defc cursor_style
   universal cursordimensions
   if arg(1)=1 then  -- Vertical bar
      cursordimensions = '-128.-128 2.-128'
   elseif arg(1)=2 then  -- Underline cursor
      cursordimensions = '-128.3 -128.-64'
   else
      parse value arg(1) with w1 '.' w2 w3 '.' w4 junk
      if isnum(w1) & isnum(w2) & isnum(w3) & isnum(w4) & junk='' then
         cursordimensions = arg(1)
      else
         sayerror -263 -- "Invalid argument"
      endif
   endif
   call fixup_cursor()
compile endif

;  This command is the same function that has been attached to
;  the key Alt-equal.  Moved here as a separate command to make key
;  binding more flexible.  And to allow execution without a key binding.
;  In EPM, no getkey() prompt.  Cancel at first error.
defc dolines=
   if marktype()='LINE' then
      getmark firstline,lastline,i,i,fileid
      if firstline<>lastline | firstline<>.line then
         k=substr('0000'YES_CHAR || NO_CHAR, winmessagebox( 'Dolines',
                                                            EX_ALL__MSG,
                                                            16389) - 1, 1)  -- YESNOCANCEL + MOVEABLE
         if not k then return ''; endif  -- 'Y'=Yes; 'N'=No; '0'=Cancel
      else  -- If only current line is marked, no need to ask...
         k=NO_CHAR
      endif
      if k=YES_CHAR then
         for i=firstline to lastline
            getline line,i,fileid
            line
         endfor
         sayerror 0
         return ''
      endif
   endif
   if .line then
      getline line
      line
   endif

; Moved defc e,ed,edit,epm to EDIT.E
; Moved defc ep, epath to EDIT.E
; Moved defc op, opath, openpath to EDIT.E

; jbl 1/12/89:  The syntax of ECHO is revised to be like browse().  It's
; a function so a macro can test its current value.
defc echo =
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      call echo(1)
   elseif uparg=OFF__MSG or uparg='0' then
      call echo(0)
   elseif isnum(uparg) then
      call echo(uparg)
   else
      if echo()<2 then
         sayerror ECHO_IS__MSG word(OFF__MSG ON__MSG, echo()+1)
      else
         sayerror ECHO_IS__MSG echo()
      endif
   endif

compile if TOGGLE_ESCAPE
defc ESCAPEKEY
   universal ESCAPE_KEY
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      ESCAPE_KEY = 1
   elseif uparg=OFF__MSG or uparg=0 then
      ESCAPE_KEY = 0
   else
      sayerror 'EscapeKey' word(OFF__MSG ON__MSG, ESCAPE_KEY+1)
   endif
compile endif

; Moved defc et,etpm to LINKCMDS.E

defc expand=
   universal expand_on
   uparg=upcase(arg(1))
   if uparg=ON__MSG then
      expand_on = 1
      call select_edit_keys()
   elseif uparg=OFF__MSG then
      expand_on = 0
      call select_edit_keys()
   elseif uparg='' then
      sayerror 'EXPAND:' word(OFF__MSG ON__MSG, expand_on+1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG')'
      stop
   endif

;  EPM's replacement for Alt-F.  "FILL <character>".
defc fill=
   call checkmark()
   call pfill_mark(arg(1))


defc flow =
   parse arg l r p .
   if l='' then parse value '1 73 1' with l r p
   elseif r = '' then r=l; l=1; p=1;
   elseif p = '' then p=l;
   endif
   oldmarg = .margins
   .margins = l r p
   if .margins = l r p then
      call psave_mark(save_mark)
      call text_reflow()
      call prestore_mark(save_mark)
   else
      sayerror 'Invalid argument.'
   endif
   .margins = oldmarg

defc goto =
   parse arg line col .
   line
   if col<>'' then .col = col; endif

/* Uses findfile statement to search EPATH for the helpfile.              */
/* Its syntax: findfile destfilename,searchfilename[,envpathvar][,['P']]  */
defc help=
   helpfile = HELPFILENAME

   -- 4.02:  search EPATH/DPATH for the help file.  New 'D' option on findfile.
   findfile destfilename, helpfile, '','D'
   if rc then    /* If not there, search the HELP path. */
      findfile destfilename, helpfile, 'HELP'
   endif
   if rc then
      /* If all that fails, try the standard path. */
      findfile destfilename, helpfile, 'PATH'
      if rc then
         sayerror FILE_NOT_FOUND__MSG':' helpfile
         return ''
      endif
   endif
   'openhelp' destfilename

; In EPM we don't do a getkey() to ask you for the key.  You must supply it
; as part of the command, as in "key 80 =".
defc key=
   parse value arg(1) with number k .
   if upcase(number) = 'RC' then
      til_rc = 1
   else
      til_rc = 0
      if not isnum(number) then sayerror INVALID_NUMBER__MSG;stop endif
   endif
   -- jbl:  Allow the user to specify the key in the command, so he can
   -- say "key 80 =" and avoid the prompt.
   if k == '' then
      sayerror KEY_PROMPT2__MSG '"key 'number' =", "key 'number' S+F3".'
      return
   else
      k=resolve_key(k)
      if til_rc then
         do forever
            executekey k
            if rc then leave; endif
         end
      else
         for i=1 to number
            executekey k
         endfor
      endif
   endif
   sayerror 0

; Moved defc l, locate to LOCATE.E
; Moved defc list, findfile, filefind to DOSUTIL.E

compile if WANT_LONGNAMES='SWITCH'
defc longnames
   universal SHOW_LONGNAMES
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      SHOW_LONGNAMES = 1
   elseif uparg=OFF__MSG or uparg=0 then
      SHOW_LONGNAMES = 0
   else
      sayerror LONGNAMES_IS__MSG word(OFF__MSG ON__MSG, SHOW_LONGNAMES+1)
   endif
compile endif

defc loopkey=
   parse value arg(1) with finish k .
   if upcase(finish)='ALL' then
      finish= .last-.line+1
   endif
   if not isnum(finish) then sayerror INVALID_NUMBER__MSG;stop endif
   if k == '' then
      sayerror KEY_PROMPT2__MSG '"loopkey 'finish' =", "loopkey 'finish' S+F3".'
   else
      k=resolve_key(k)
      oldcol=.col
      for i=1 to finish
         executekey k;down;.col=oldcol
      endfor
   endif
   sayerror 0

defc lowercase=
   call plowercase()

; In EOS2 you could query the margins by typing "margins" with no argument.
; It typed them into the command line.  In EPM have to do this in the macros.
; Changed: made rightmargin and/or parmargin values optional.
; Syntax:
;
;    ma [[<leftmargin>] <rightmargin> [<parmargin>]] [noea] [reflow]
;
;    Added the optional arg 'noea' anywhere in the arg list to avoid setting
;    EPM.MARGINS.
;    Added the optional arg 'reflow' anywhere in the arg list to enable
;    the maybe reflow MsgBox.
defc margins, ma
   universal app_hini
   arg1 = strip( arg(1))
   arg1 = upcase(arg1)
   -- if executed without arg
   if arg1 = '' then
      'commandline margins' .margins  -- Open commandline with current values
      return
   endif

   -- else set margins for current file
   SetEa = 1
   DeleteEaOnly = 0
   wp = wordpos( 'NOEA', arg1)
   if wp > 0 then
      arg1 = delword( arg1, wp, 1)
      SetEa = 0
   endif
   if SetEa then
      if (.readonly | not exist(.filename) | leftstr( .filename, 1) = '.') then
         SetEa = 0
      endif
   endif

   AskReflow = 0
   wp = wordpos( 'REFLOW', arg1)
   if wp > 0 then
      arg1 = delword( arg1, wp, 1)
      AskReflow = 1
   endif

   if wordpos( arg1, '0 OFF DEFAULT' ) > 0 then
      DefaultMargins = queryprofile( app_hini, 'EPM', 'MARGINS')
      if DefaultMargins = '' then
         DefaultMargins = '1 1599 1'
      endif
      NewMargins = DefaultMargins
      DeleteEaOnly = 1
   else
      parse value arg1 with leftm rightm parm
      if rightm = '' then  -- if only 1 arg specified
         rightm = arg1
         leftm  = 1
      endif
      if parm = '' then    -- if parmargin not specified
         parm = leftm
      endif
      NewMargins = leftm rightm parm
   endif
   'xcom margins' NewMargins  -- pass it to the old internal margins command.
   'refreshinfoline MARGINS'  -- Update statusline if margins displayed

   if SetEa then
      -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value
      -- This will write the EA on save-as if the source file was readonly.
      call delete_ea('EPM.MARGINS')
      if DeleteEaOnly then
         -- Delete the EA 'EPM.MARGINS' immediately
         rc = NepmdDeleteStringEa( .filename, 'EPM.MARGINS')
         if (rc > 0) then
            sayerror 'EA "EPM.MARGINS" not deleted, rc = 'rc
         endif
      else
         -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value
         -- This will write the EA on save-as if the source file was readonly.
         'add_ea EPM.MARGINS' NewMargins
         -- Set the EA 'EPM.MARGINS' immediately
         rc = NepmdWriteStringEa( .filename, 'EPM.MARGINS', NewMargins)
         if (rc > 0) then
            sayerror 'EA "EPM.MARGINS" not set, rc = 'rc
         endif
      endif  -- DeleteEaOnly
   endif -- SetEa

   if AskReflow then
      'postme maybe_reflow_all'
   endif

defc matchtab=
   universal matchtab_on
   uparg=upcase(arg(1))
   if uparg=ON__MSG then
      matchtab_on = 1
   elseif uparg=OFF__MSG then
      matchtab_on = 0
   elseif uparg='' then
      sayerror 'MATCHTAB:' word(OFF__MSG ON__MSG, matchtab_on+1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG')'
      stop
   endif

; MultiCommand, or Many Commands - lets you enter many commands on a line,
; like XEDIT's SET LINEND, but you specify the delimiter as part of the
; command so there's never a conflict.  Example, using ';' as delimiter:
;   mc ; top; c /begin/{/ *; top; c/end/}/ *; top
defc mc =
   parse value strip(arg(1),'L') with delim 2 rest
   do while rest <> ''
      parse value rest with cmd (delim) rest
      cmd
   enddo

defc newtop = l=.line; .cursory=1; l

defc restorepos
   saved_pos = strip( arg(1) )
   if saved_pos <> '' then
      call prestore_pos(saved_pos)
   endif

defc nextview
   getfileid fid
   vid = .currentview_of_file
   next = .nextview_of_file
   if vid = next then
      sayerror ONLY_VIEW__MSG
   else
      activatefile next
   endif

; Moved defc o,open to EDIT.E

defc openhelp
 compile if 0
   rectangle = atol(4) || atol(75)  || atol(632) || atol(351)

   filename  = arg(1) \0
   exfile    = 'help.ex' \0
   topoffile = HELP_TOP__MSG\0
   botoffile = HELP_BOT__MSG\0
   rethwnd   = '1234'
   params =   atol(getpminfo(EPMINFO_HAB))          ||  /* application anchor block              */
              atol(getpminfo(EPMINFO_PARENTCLIENT)) ||  /* handle to parent of edit window       */
              atol(getpminfo(EPMINFO_OWNERCLIENT))  ||  /* handle to owner of edit window        */
              address(rectangle)   ||  /* positioning of edit window            */
              address(filename)    ||  /* file to be edited                     */
              atol(0)              ||  /* handle to editor pointer icon.        */
              atol(0)              ||  /* handle to mark pointer icon.          */
              atol(0)              ||  /* editor ICON.                          */
              atol(12)             ||  /* internal editor options               */
              atol(203)            ||  /* PM standard window styles (FCF_xxxx)  */
              atoi(1)              ||  /* TRUE = LARGE FONT,  FALSE = SMALL FONT*/
              address(exfile)      ||  /* pre-compiled macro code file (EPM.EX) */
              address(topoffile)   ||  /* top and bottom of file markers        */
              address(botoffile)   ||
              atoi(0)              ||  /* unique window id specified for edit window */
              atol(0)              ||  /* environment variable to search for .ex */
              atoi(0)                  /* reserved for future use.              */

   call dynalinkc( E_DLL,
                   '_EPM_EDITWINDOWCREATE',
                   address(params)    ||
                   address(rethwnd))
 compile else

   -- send EPM icon window a help message.  It will take care of
   -- the correct setting up of the help window.
   --
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5132,                   -- EPM_POPHELPBROWSER
                      put_in_buffer(arg(1)),
                      1)                      -- Tell EPM to free the buffer.
 compile endif

defc pagebreak
   -- I put a form feed character there for the dual purpose of somewhat
   -- supporting page breaks in raw mode and to allow the attributes to be
   -- placed at column 2 rather than column 1. My selection of a chr(12) may
   -- actually mean that all page breaks need to be stripped after one is done
   -- printing because they may render the file invalid.  (For example, I don't
   -- know if C allows a free FORMFEED character.)
   insertline chr(12)
   up
   -- I place the attributes at column 2 rather than column 1 below, because if
   -- they are at column 1, line mark operations will not move them with the line.
   insert_attribute 6, 0, 1, 0,  /*col:*/ 2,  .line
   insert_attribute 6, 0, 0, 0,  /*col:*/ 2,  .line
   call attribute_on(8)  -- "Save attributes" flag

compile if 0 -- EPM32      -- LAM:  Doesn't seem worth the code space...
defc prevview
   getfileid fid
   vid = .currentview_of_file
   next = .nextview_of_file
   if vid = next then
      sayerror ONLY_VIEW__MSG
   else
      do forever
         nextnext = next.nextview_of_file
         if nextnext = vid then leave; endif
         next = nextnext
      enddo
      activatefile next
   endif
compile endif

;  Print just the marked area, if there is one.  Defaults to printing on LPT1.
;  Optional argument specifies printer.
defc print=  /* Save the users current file to the printer */
   parse arg prt ':'                             -- Optional printer name
   if not prt then prt=default_printer(); endif  -- Default
   prtnum = check_for_printer(prt)
   if prtnum then
      if not printer_ready(prtnum) then
         sayerror PRINTER_NOT_READY__MSG
         stop
      endif
   elseif substr(prt,1,2)<>'\\' then      -- Assume \\hostname\prt is correct.
      sayerror BAD_PRINT_ARG__MSG
      stop
   endif
   if marktype() then
      getmark firstline,lastline,firstcol,lastcol,markfileid
      getfileid fileid
      if fileid<>markfileid then
         sayerror OTHER_FILE_MARKED__MSG UNMARK_OR_EDIT__MSG markfileid.filename
         stop
      endif
      mt=marktype()
      'xcom e /n'             /*  Create a temporary no-name file. */
      if rc=-282 then  -- sayerror("New file")
         if marktype()='LINE' then deleteline endif
      elseif rc then
         stop
      endif
      getfileid tempofid
      call pcopy_mark()
      if rc then stop endif
      call pset_mark(firstline,lastline,firstcol,lastcol,mt,markfileid)
      activatefile tempofid
      sayerror PRINTING_MARK__MSG
   else
      sayerror PRINTING__MSG .filename
   endif
   'xcom save /s /ne /q' prt  /* /NE means No EOF (for Laserjet driver) */
   if marktype() then .modify=0; 'xcom q' endif
   sayerror 0    /* clear 'printing' message */

defc processbreak  -- executed if Ctrl+Break was pressed
   universal Dictionary_loaded
   call showwindow('ON')             -- Make sure that the window is displayed.
   if dictionary_loaded then
      call drop_dictionary()
   endif
compile if WANT_EPM_SHELL
   is_shell = ( leftstr(.filename, 15) = ".command_shell_" )
   if is_shell then
      'shell_break'
   else
compile endif -- WANT_EPM_SHELL
      sayerror MACRO_HALTED__MSG
compile if WANT_EPM_SHELL
   endif
compile endif -- WANT_EPM_SHELL

compile if WANT_PROFILE='SWITCH'
defc PROFILE
   universal REXX_PROFILE
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      REXX_PROFILE = 1
   elseif uparg=OFF__MSG or uparg=0 then
      REXX_PROFILE = 0
   else
      sayerror 'Profile' word(OFF__MSG ON__MSG, REXX_PROFILE+1)
   endif
compile endif

compile if WANT_STACK_CMDS
definit
   universal mark_stack, position_stack
   mark_stack = ''
   position_stack = ''

defc popmark
   universal mark_stack
   parse value mark_stack with savemark '/' mark_stack
   call prestore_mark(savemark)

defc poppos
   universal position_stack
   parse value position_stack with fid saveposition '/' position_stack
   if fid='' then
      sayerror STACK_EMPTY__MSG
      return
   endif
   display -2
   rc = 0
   activatefile fid
   display 2
   if rc then
      sayerror FILE_GONE__MSG
      return
   endif
   call prestore_pos(saveposition)

defc pushmark
   universal mark_stack
   call checkmark()
   call psave_mark(savemark)  -- Note - this does an UNMARK
   call prestore_mark(savemark)
   if length(mark_stack) + length(savemark) >= MAXCOL then
      sayerror STACK_FULL__MSG
      return
   endif
   mark_stack = savemark'/'mark_stack

defc swapmark
   universal mark_stack
   call checkmark()
   call psave_mark(savemark)
   'popmark'
   if length(mark_stack) + length(savemark) >= MAXCOL then
      sayerror STACK_FULL__MSG
      return
   endif
   mark_stack = savemark'/'mark_stack

defc pushpos
   universal position_stack
   call psave_pos(saveposition)
   getfileid fid
   if length(position_stack) + length(saveposition fid) >= MAXCOL then
      sayerror STACK_FULL__MSG
      return
   endif
   position_stack = fid saveposition'/'position_stack

defc swappos
   universal position_stack
   call psave_pos(saveposition)
   getfileid fid
   'poppos'
   if length(position_stack) + length(saveposition fid) >= MAXCOL then
      sayerror STACK_FULL__MSG
      return
   endif
   position_stack = fid saveposition'/'position_stack
compile endif  -- WANT_STACK_CMDS

defc qs,quietshell,quiet_shell=
   quietshell arg(1)

defc rc=
   arg(1)
   sayerror 'RC='rc''

compile if SETSTAY='?'
defc stay=
   universal stay
   parse arg arg1; arg1=upcase(arg1)
   if arg1='' then sayerror 'Stay =' word(OFF__MSG ON__MSG, stay+1)
   elseif arg1='1' | arg1=ON__MSG then stay=1
   elseif arg1='0' | arg1=OFF__MSG then stay=0
   else sayerror INVALID_ARG__MSG ON_OFF__MSG')'
   endif
compile endif

defc strip =
   parse arg firstline lastline .
   if firstline='' then firstline=1; endif
   if lastline='' then lastline=.last; endif
   do i=firstline to lastline
      getline line, i
      if length(line) & rightstr(line,1) == ' ' then
         replaceline strip(line, 'T'), i
      endif
   enddo

compile if TOGGLE_TAB
defc TABKEY
   universal TAB_KEY
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      TAB_KEY = 1
   elseif uparg=OFF__MSG or uparg=0 then
      TAB_KEY = 0
   else
      sayerror 'TabKey' word(OFF__MSG ON__MSG, TAB_KEY+1)
   endif
   'refreshinfoline TABKEY'   -- Update statusline if tabkey status displayed
compile endif

defc tabglyph =
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      call tabglyph(1)
   elseif uparg=OFF__MSG or uparg='0' then
      call tabglyph(0)
   elseif uparg='' or uparg='?' then
      cb = tabglyph()     -- query current state
      sayerror TABGLYPH_IS__MSG word(OFF__MSG ON__MSG, cb+1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
   endif

; In EOS2 you could query the tabs by typing "tabs" with no argument.
; It typed them into the command line.
defc tabs
   universal app_hini
   arg1 = strip( arg(1))
   arg1 = upcase(arg1)
   -- if executed without an arg
   if arg1 = '' then
      'commandline tabs' .tabs  -- Open commandline with current values
      return
   endif

   -- else set tabs for current file
   SetEa = 1
   DeleteEaOnly = 0
   wp = wordpos( 'NOEA', arg1)
   if wp > 0 then
      arg1 = strip( delword( arg1, wp, 1))
      SetEa = 0
   endif
   if SetEa then
      if (.readonly | not exist(.filename) | leftstr( .filename, 1) = '.') then
         SetEa = 0
      endif
   endif

   if wordpos( arg1, '0 OFF DEFAULT' ) > 0 then
      DefaultTabs = queryprofile( app_hini, 'EPM', 'TABS')
      if DefaultTabs = '' then
         DefaultTabs = '8'
      endif
      NewTabs = DefaultTabs
      DeleteEaOnly = 1
   else
      NewTabs = arg1
   endif
   'xcom tabs' NewTabs     -- pass it to the old internal tabs command.
   'refreshinfoline TABS'  -- Update statusline if tabs displayed

   if SetEa then
      -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value
      -- This will write the EA on save-as if the source file was readonly.
      call delete_ea('EPM.TABS')
      if DeleteEaOnly then
         -- Delete the EA 'EPM.TABS' immediately
         rc = NepmdDeleteStringEa( .filename, 'EPM.TABS')
         if (rc > 0) then
            sayerror 'EA "EPM.TABS" not deleted, rc = 'rc
         endif
      else
         -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value
         -- This will write the EA on save-as if the source file was readonly.
         'add_ea EPM.TABS' NewTabs
         -- Set the EA 'EPM.TABS' immediately
         rc = NepmdWriteStringEa( .filename, 'EPM.TABS', NewTabs)
         if (rc > 0) then
            sayerror 'EA "EPM.TABS" not set, rc = 'rc
         endif
      endif
   endif


defc timestamp =
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with Hour24 Minutes Seconds . Day MonthNum Year0 Year1 .
compile if WANT_DBCS_SUPPORT
   parse value countryinfo with 22 datesep 23 24 timesep 25
   keyin rightstr(Year0 + 256*Year1, 4, 0) || datesep || rightstr(monthnum, 2, 0) || datesep || rightstr(Day, 2, 0)' ' ||
         rightstr(hour24, 2) || timesep || rightstr(Minutes,2,'0') || timesep || rightstr(Seconds,2,'0')'  '
compile else  -- no DBCS
   keyin rightstr(Year0 + 256*Year1, 4, 0)'/'rightstr(monthnum, 2, 0)'/'rightstr(Day, 2, 0)' ' ||
         rightstr(hour24, 2)':'rightstr(Minutes,2,'0')':'rightstr(Seconds,2,'0')'  '
compile endif

defc top=
   top

defc uppercase=
   call puppercase()

defc ver =
   sayerror EDITOR_VER__MSG ver(0)

; ---------------------------------------------------------------------------
defc ActivateHighlighting
   call NepmdActivateHighlight(arg(1))

; ---------------------------------------------------------------------------
defc ActivateFile
   fid = arg(1)
   if fid <> '' then
      -- Check if file to be activated is still in ring and visible
      if wordpos( ValidateFileid(fid), '1 2') then
         activatefile fid
      endif
   endif


