/****************************** Module Header *******************************
*
* Module Name: stdcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdcmds.e,v 1.8 2002-09-21 19:54:31 aschn Exp $
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

const
compile if not defined(NEPMD_SPECIAL_STATUSLINE)
   NEPMD_SPECIAL_STATUSLINE = 0
compile endif

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


defc app, append =            -- With linking, PUT can be an external module.
   'put' arg(1)               -- Collect the names; the module is named PUT.EX.

defc asc=
   parse arg i '=' .
   if i='' then
      getline line
      i=substr(line,.col,1)
   endif
   sayerror 'asc 'i'='asc(i)''


defc autosave=
   universal vAUTOSAVE_PATH
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
   uparg=upcase(arg(1))
   if uparg=ON__MSG then                  /* If only says AUTOSAVE ON,  */
compile if DEFAULT_AUTOSAVE > 0
      .autosave = DEFAULT_AUTOSAVE
compile else
      .autosave=10                     /* default is every 10 mods. */
compile endif
   elseif uparg=OFF__MSG then
      .autosave = 0
   elseif isnum(uparg) then            /* Check whether numeric argument. */
      .autosave = uparg
   elseif uparg='DIR' then
      'dir' vAUTOSAVE_PATH
   elseif uparg='' then
      'commandline autosave' .autosave
   elseif uparg='?' then
compile if RING_OPTIONAL
      if ring_enabled then
compile endif
compile if 0
         do forever
            retvalue=winmessagebox( AUTOSAVE__MSG,
                                    CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10LIST_DIR__MSG,
                                    24628)  -- YESNO + MB_INFORMATION + MOVEABLE + HELP
            if retvalue<>8 then leave; endif    -- MBID_HELP = 8
            'helpmenu 2045'
         enddo
         if 6=retvalue then  -- MBID_YES
compile else
         if 6=winmessagebox( AUTOSAVE__MSG,
                             CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10LIST_DIR__MSG,
                             16436)  -- YESNO + MB_INFORMATION + MOVEABLE
            then
compile endif
           'dir' vAUTOSAVE_PATH
         endif
 compile if RING_OPTIONAL
      else
         call winmessagebox( AUTOSAVE__MSG,
                             CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10NO_LIST_DIR__MSG,
                             16432)  -- OK + MB_INFORMATION + MOVEABLE
      endif  -- ring_enabled
 compile endif
         return
   else
      sayerror AUTOSAVE_PROMPT__MSG
      return
   endif  -- uparg=ON__MSG
   sayerror CURRENT_AUTOSAVE__MSG||.autosave', 'NAME_IS__MSG||MakeTempName()

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

;  BROWSE -- A simple front end to Ralph Yozzo's browse() function.
;            It allows the user to type off/on/0/1/?.
;
;     BROWSE off/on/0/1
;
; specifies whether E should allow text to be altered (normal editing mode)
; or whether all text is read-only.
;
; Issuing BROWSE with '?' or no argument returns the current setting.
;
; The function browse() takes an optional argument 0/1.  It always returns
; the current setting.  So you can query the current setting without changing
; it by giving no argument.
;
defc browse =
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      cb = browse(1)
   elseif uparg=OFF__MSG or uparg='0' then
      cb = browse(0)
   elseif uparg='' or uparg='?' then
      cb = browse()     -- query current state
      /* jbl 12/30/88:  move msg to this case only, avoid trivial sayerror's.*/
      sayerror BROWSE_IS__MSG word(OFF__MSG ON__MSG, cb+1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif


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
   'xcom c 'lastchangeargs

compile if SETSTAY='?'
   if stay then
compile endif
compile if SETSTAY
      call prestore_pos(savepos)
compile endif
compile if SETSTAY='?'
   endif
compile endif

defc cd=
   rc=0
   if arg(1)='' then
      dir= directory()
   else
      dir= directory(arg(1))
   endif
   if not rc then
      sayerror CUR_DIR_IS__MSG dir
   endif

defc center=
   call pcenter_mark()

defc chr=
   parse arg i '=' .
   sayerror 'chr 'i'='chr(i)''

defc close=
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
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

defc deleteautosavefile
   if .autosave then               -- Erase the tempfile if autosave is on.
      TempName = MakeTempName()
      getfileid tempid, TempName  -- (provided it's not in the ring.)
      if tempid='' then call erasetemp(TempName); endif
   endif

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


define TEMPFILENAME = 'vTEMP_FILENAME'
compile if WANT_ET_COMMAND     -- Ver. 3.09 - Let user omit ET command.
define TEMPFILENAME = 'tempfile'
defc et,etpm=
   universal vTEMP_PATH,vTEMP_FILENAME
   infile=arg(1); if infile='' then infile=MAINFILE endif
   sayerror COMPILING__MSG infile
   tempfile=vTEMP_PATH'ETPM'substr(ltoa(gethwnd(EPMINFO_EDITCLIENT),16),1,4)'.TMP'
   -- quietshell 'xcom etpm /e 'tempfile infile
 compile if defined(ETPM_CMD)  -- let user specify fully-qualified name
   quietshell 'xcom' ETPM_CMD infile ' /e 'tempfile ' /p'upcase(EPATH)
   if rc=-2 then sayerror CANT_FIND_PROG__MSG ETPM_CMD; stop; endif
 compile else
   quietshell 'xcom etpm 'infile ' /e 'tempfile ' /p'upcase(EPATH)
   if rc=-2 then sayerror CANT_FIND_PROG__MSG 'ETPM.EXE'; stop; endif
 compile endif
   if rc=41 then sayerror 'ETPM.EXE' CANT_OPEN_TEMP__MSG '"'tempfile'"'; stop; endif
   if rc then
      saverc = rc
      call ec_position_on_error($TEMPFILENAME)
      rc = saverc
   else
      refresh
      sayerror COMP_COMPLETED__MSG
   endif
   call erasetemp($TEMPFILENAME) -- 4.11:  added to erase the temp file.
compile endif

-- No EXIT command in EPM.  Do it from the system pull-downs.


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

defc f,file=
compile if SUPPORT_USER_EXITS
   universal isa_file_cmd
   isa_file_cmd = 1         -- So user's presave / postsave exits can differentiate...
compile endif
   's 'arg(1)
compile if SUPPORT_USER_EXITS
   isa_file_cmd = ''
compile endif
   if not rc then
      .modify=0            -- If saved to a different file, turn modify off
      'q'
      call select_edit_keys()
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

-- With linking, GET can be an external module.

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
   'xcom l 'args
compile if defined(HIGHLIGHT_COLOR)
   call highlight_match(search_len)
compile endif

; As of EPM 5.18, this command supports use of the DOS or OS/2 ATTRIB command,
; so non-IBM users can also use the LIST command.  Note that installing SUBDIR
; (DOS) or FILEFIND (OS/2) is still preferred, since it's not necessary to
; "clean up" their output.  Also, ATTRIB before DOS 3.? doesn't support the /S
; option we need to search subdirectories.
defc list, findfile, filefind=
   universal vTEMP_FILENAME
   /* If I say "list c:\util" I mean the whole util directory.  But we */
   /* have to tell SubDir that explicitly by appending "\*.*".         */
   spec = arg(1)
   call parse_filename(spec,.filename)
   src = subdir(spec' >'vTEMP_FILENAME)  -- Moved /Q option to defproc subdir

   'e' argsep'd' argsep'q' vTEMP_FILENAME
   call erasetemp(vTEMP_FILENAME)
   if .last then
      .filename='.DIR 'spec
      if .last<=2 & substr(textline(.last),1,8)='SYS0002:' then
         'xcom q'
         sayerror FILE_NOT_FOUND__MSG
      endif
   else
      'xcom q'
      sayerror FILE_NOT_FOUND__MSG
   endif
   call select_edit_keys()

compile if WANT_LAN_SUPPORT
defc lock
   if arg(1)<>'' then
      'e 'arg(1)
      if rc & rc<>-282 then  --sayerror('New file')
         return 1
      endif
   endif
   call lock()
compile endif

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

;  In EOS2 you could query the margins by typing "margins" with no argument.
;  It typed them into the command line.  In EPM have to do this in the macros.
;
defc margins,ma=
   if arg(1)<>'' then         -- if user gives an argument he's setting,
      'xcom margins' arg(1)   -- pass it to the old internal margins command.
   else
      'commandline margins' .margins   -- Note the new .margins field
   endif
compile if NEPMD_SPECIAL_STATUSLINE
   'refreshstatusline'               --  Update status line text and color, see STATUSLINE.E
compile endif


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

defc n,name
compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
compile endif
   -- Name with no args supplies current name.
   if arg(1)='' then
      'commandline Name '.filename
   else
      if .lockhandle then
         sayerror LOCKED__MSG
         return
      endif
      oldname = .filename
      autosave_name = MakeTempName()
      call namefile(arg(1))
      if oldname <> .filename then .modify = .modify+1 endif
      if get_EAT_ASCII_value('.LONGNAME')<>'' then
         call delete_ea('.LONGNAME')
compile if WANT_LONGNAMES
 compile if WANT_LONGNAMES='SWITCH'
         if SHOW_LONGNAMES then
 compile endif
            .titletext = ''
 compile if WANT_LONGNAMES='SWITCH'
         endif
 compile endif
compile endif  -- WANT_LONGNAMES
      endif  -- .LONGNAME EA exists
compile if SHOW_MODIFY_METHOD = 'TITLE'
      call settitletext(.filename)
compile endif
      call dosmove(autosave_name, MakeTempName())  -- Rename the autosave file
      call select_edit_keys()
compile if SUPPORT_USER_EXITS
      if isadefproc('rename_exit') then
         call rename_exit(oldname, .filename)
      endif
compile endif
compile if INCLUDE_BMS_SUPPORT
      if isadefproc('BMS_rename_exit') then
         call BMS_rename_exit(oldname, .filename)
      endif
compile endif
   endif  -- arg(1)=''

defc newtop = l=.line; .cursory=1; l

defc newwindow=
   if leftstr(.filename, 5)='.DOS ' then
      fn = "'"substr(.filename, 6)"'"
 compile if WANT_TREE
   elseif .filename = '.tree' then
      parse value .titletext with cmd ': ' args
      fn = "'"cmd args"'"
 compile endif
   else
      if .modify then
         'save'
         if rc then
            sayerror ERROR_SAVING_HALT__MSG
            return
         endif
      endif
      fn = .filename
      if fn=UNNAMED_FILE_NAME then
         fn=''
      elseif .readonly then
         fn = '/r' fn
      endif
   endif
   'open' fn
   'quit'

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

defc processbreak
   universal Dictionary_loaded
   call showwindow('ON')             -- Make sure that the window is displayed.
   if dictionary_loaded then
      call drop_dictionary()
   endif
   sayerror MACRO_HALTED__MSG

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
compile endif

defc qs,quietshell,quiet_shell=
   quietshell arg(1)

defc q,quit=
   -- Ver. 4.11c: If we're trying to quit the shell window, kill the process.
 compile if SHELL_USAGE                                                           -- remove?
   if .filename = ".SHELL" then                                                   -- remove?
;     It's important to kill the process before we quit the window, else the
;     process will churn merrily along without output.  If we're MAKEing a
;     large C program and quit the editor, it can tie up the session.
;     Simpler tasks like DIR and FILEFIND don't tie up the session.
;
;     Doesn't hurt anything if the process has already been killed.  The
;     internal shell_kill function will merely beep at you.
      call shell_kill()                                                           -- remove?
   endif                                                                          -- remove?
 compile endif                                                                    -- remove?

compile if    SPELL_SUPPORT
   if .keyset='SPELL_KEYS' then  -- Dynamic spell-checking is on for this file;
      'dynaspell'                -- toggle it off.
   endif
compile endif

compile if    WANT_EPM_SHELL
   if leftstr(.filename, 15) = ".command_shell_" then
      'shell_kill'
      return
   endif
compile endif

compile if SUPPORT_USER_EXITS
      if isadefproc('quit_exit') then
         call quit_exit(.filename)
      endif
compile endif
compile if INCLUDE_BMS_SUPPORT
      if isadefproc('BMS_quit_exit') then
         call BMS_quit_exit(.filename)
      endif
compile endif

compile if TRASH_TEMP_FILES
   if substr(.filename,1,1) = "." then      -- a temporary file
      .modify=0                             -- so no "Are you sure?"
   endif
compile endif

   getfileid quitfileid      -- Temp workaround
;compile if EVERSION > 5
;   if marktype() then
;      getmark firstline,lastline,firstcol,lastcol,markfileid
;      if markfileid = quitfileid then
;         'ClearSharBuff'       -- Remove content of EPM shared text buffer
;      endif
;   endif
;compile endif
;compile if WANT_LAN_SUPPORT & EVERSION < '5.51'          -- remove?
;   if .lockhandle then call unlock(quitfileid); endif    -- remove?
;compile endif                                            -- remove?
   call quitfile()

defc rc=
   arg(1)
   sayerror 'RC='rc''

defc readonly =
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      .readonly = 1
   elseif uparg=OFF__MSG or uparg='0' then
      .readonly = 0
   elseif uparg='' or uparg='?' then
      sayerror READONLY_IS__MSG word(OFF__MSG ON__MSG, .readonly+1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif

defc reflow_all
   call psave_mark(savemark)
   call psave_pos(savepos)
   stopit = 0
   top
   do forever
      getline line
      do while line='' |                              -- Skip over blank lines or
               (lastpos(':',line)=1 & pos('.',line)=length(line)) |  -- lines containing only a GML tag or
               substr(line,1,1)='.'                                  -- SCRIPT commands
         if .line=.last then stopit=1; leave; endif
         down
         getline line
      enddo
      if stopit then leave; endif
      startline = .line
      unmark; mark_line
      call pfind_blank_line()
      if .line<>startline then
         up
      else
         bottom
      endif
      mark_line
      reflow
      getmark firstline,lastline
      if lastline=.last then leave; endif
      lastline+1
   enddo
   call prestore_mark(savemark)
   call prestore_pos(savepos)

defc s,save=
   universal save_with_tabs, default_save_options
   name=arg(1)
   call parse_leading_options(name,options)
   options = default_save_options options
   if name='' & (browse() | .readonly) then
      if .readonly then
         sayerror READ_ONLY__MSG
      else
         sayerror BROWSE_IS__MSG ON__MSG
      endif
      rc = -5  -- Access denied
      return
   endif
   save_as = 0
   if name='' | name=UNNAMED_FILE_NAME then
      name=.filename
      if .filename=UNNAMED_FILE_NAME then
         result = saveas_dlg(name, type)
         if result then return result; endif
         'name' name
         if not rc then
            name=.filename
            save_as = 1
         endif
      endif
   else
      call parse_filename(name,.filename)
   endif
compile if SUPPORT_USER_EXITS
   if isadefproc('presave_exit') then
      call presave_exit(name, options, save_as)
   endif
compile endif
compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_presave_exit') then
      call BMS_presave_exit(name, options, save_as)
   endif
compile endif
;compile if WANT_LAN_SUPPORT & EVERSION > '5.51'          -- remove?
;   locked = .lockhandle                                  -- remove?
;   if locked & not arg(1) then 'unlock'; endif           -- remove?
;compile endif                                            -- remove?

compile if WANT_BOOKMARKS
   if .levelofattributesupport bitand 8 then
      'saveattributes'
   endif
compile endif
   -- 4.10:  Saving with tab compression is built in now.  No need for
   -- the make-do proc savefilewithtabs().
   -- 4.10 new feature:  if save_with_tabs is true, always specify /t.
   if save_with_tabs then
      options = '/t' options
   endif
   src=savefile(name,options)
compile if SUPPORT_USER_EXITS
   if isadefproc('postsave_exit') then
      call postsave_exit(name, options, save_as, src)
   endif
compile endif
compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_postsave_exit') then
      call BMS_postsave_exit(name, options, save_as, src)
   endif
compile endif
   if not src & not isoption(options,'q') then
      call message(SAVED_TO__MSG name)
   elseif src=-5 | src=-285 then  --  -5 = 'Access denied'; -285 = 'Error writing file'
      if qfilemode(name, attrib) then      -- Error from DosQFileMode
         call message(src)    -- ? Don't know why got Access denied.
      else                    -- File exists:
         if attrib bitand 16 then
            call message(ACCESS_DENIED__MSG '-' IS_A_SUBDIR__MSG)  -- It's a subdirectory
         elseif attrib // 2 then                    -- x'01' is on
            call message(ACCESS_DENIED__MSG '-' READ_ONLY__MSG)    -- It's read/only
         elseif attrib bitand 4 then
            call message(ACCESS_DENIED__MSG '-' IS_SYSTEM__MSG)    -- It's a system file
         elseif attrib bitand 2 then
            call message(ACCESS_DENIED__MSG '-' IS_HIDDEN__MSG)    -- It's a hidden file
         else                                -- None of the above?
            call message(ACCESS_DENIED__MSG '-' MAYBE_LOCKED__MSG) -- Maybe someone locked it.
         endif
      endif
      rc = src  -- reset, since qfilemode() changed the RC.
   elseif src=-345 then
      call winmessagebox( 'Demo Version',
                          sayerrortext(-345)\10\10'File too large to be saved.' ,
                          MB_CANCEL + MB_CRITICAL + MB_MOVEABLE)
   elseif src<0 then          -- If RC > 0 assume from host save; and
      call message(src)       -- assume host routine gave error msg.
   endif
   if src & save_as then
      .filename=UNNAMED_FILE_NAME
 compile if SHOW_MODIFY_METHOD = 'TITLE'                 -- remove?
      call settitletext(.filename)                       -- remove?
 compile endif                                           -- remove?
   endif
;compile if    WANT_LAN_SUPPORT                          -- remove?
;   if locked & not arg(1) then call lock(); endif       -- remove?
;compile endif                                           -- remove?
   return src

defc select_all =
   getfileid fid
   call pset_mark(1, .last, 1, length(textline(.last)), 'CHAR' , fid)
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

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

; read a file from stdin
defc stdfile_read
   input_stream = ''
   infobuf=leftstr('', 512)
   length_read = atol(0)
   do forever
      rc = dynalink32('DOSCALLS',               -- dynamic link library name
                      '#281',                   -- ordinal value for Dos32Read
                      atol(0)               ||  -- File handle 0 = STDIN
                      address(infobuf)      ||  -- Buffer area
                      atol(length(infobuf)) ||  -- Buffer area length
                      address(length_read),2)   -- Bytes read
      if rc then
         sayerror 'DosRead' ERROR__MSG rc
         return
      endif
      len = ltoa(length_read, 10)
      if not len then
         if input_stream<>'' then
            insertline input_stream, .last+1
         endif
         leave
      endif
      fits = (length(input_stream) + len) <= MAXCOL
      if fits then
         input_stream = input_stream || leftstr(infobuf, len)
      else
         nl = pos(\n, infobuf)
         if nl & nl < len & (length(input_stream) + len) <= MAXCOL then
            insertline strip(input_stream || leftstr(infobuf, nl-1), 'T', \r), .last+1
            input_stream = substr(infobuf, nl+1, len-nl)
         else
            l2 = MAXCOL - length(input_stream)
            insertline strip(input_stream || leftstr(infobuf, l2), 'T', \r), .last+1
            input_stream = substr(infobuf, l2+1, len-l2)
         endif
      endif
      nl = pos(\n, input_stream)
      do while nl
         insertline strip(leftstr(input_stream, nl-1), 'T', \r), .last+1
         input_stream = substr(input_stream, nl+1)
         nl = pos(\n, input_stream)
      enddo
   enddo

; write a file to stdout
defc stdfile_write
   universal vTEMP_FILENAME
   .filename=vTEMP_FILENAME
   's'
   'type '.filename
   call erasetemp(.filename)
   'q'

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

;  In EOS2 you could query the tabs by typing "tabs" with no argument.
;  It typed them into the command line.
;
defc tabs=
   if arg(1)<>'' then         -- if user gives an argument to be set,
      'xcom tabs 'arg(1)      -- pass it to the old internal tabs command.
   else
      -- Note the new .tabs field; each file has its own tabs.
      'commandline Tabs' .tabs
   endif
compile if NEPMD_SPECIAL_STATUSLINE
   'refreshstatusline'               --  Update status line text and color, see STATUSLINE.E
compile endif

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

compile if WANT_LAN_SUPPORT
defc unlock
   parse arg file
   if file='' then
      getfileid fileid
   else
      getfileid fileid,file
      if fileid=='' then
         sayerror '"'file'"' DOES_NOT_EXIST__MSG
         return 1
      endif
   endif
   call unlock(fileid)
compile endif

defc uppercase=
   call puppercase()

defc ver =
   sayerror EDITOR_VER__MSG ver(0)

defc xcom_quit
   'xcom q'

