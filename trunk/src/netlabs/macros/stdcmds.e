/****************************** Module Header *******************************
*
* Module Name: stdcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdcmds.e,v 1.2 2002-07-22 19:02:07 cla Exp $
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
compile if EPM
      c1 = chr((pos(leftstr(c1,1), HEXCHARS) - 1) * 16 + pos(rightstr(c1,1), HEXCHARS) - 1)
compile else
      c1 = chr((pos(substr(c1,1,1), HEXCHARS) - 1) * 16 + pos(substr(c1,2,1), HEXCHARS) - 1)
compile endif
   endif
   if length(c2)<>1 then
      if length(c2)<>2 | verify(c2, HEXCHARS) then
         sayerror -329  -- 'Invalid second parameter.'
      endif
compile if EPM
      c2 = chr((pos(leftstr(c2,1), HEXCHARS) - 1) * 16 + pos(rightstr(c2,1), HEXCHARS) - 1)
compile else
      c2 = chr((pos(substr(c2,1,1), HEXCHARS) - 1) * 16 + pos(substr(c2,2,1), HEXCHARS) - 1)
compile endif
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

compile if EVERSION >=4

defc app, append =            -- With linking, PUT can be an external module.
   'put' arg(1)               -- Collect the names; the module is named PUT.EX.
compile else
;  Put and append work the same, and the same as XEdit's PUT.
;  If the file already exists, append to it.
;  If no file is specified, use same file as last specified.
;  If no mark, use append the entire file.
defc app, append, put =
   universal last_append_file

   if arg(1) = '' then
      app_file=last_append_file
   else
      app_file=parse_file_n_opts(arg(1))
      last_append_file=app_file
   endif
   if app_file='' then
      sayerror NO_FILENAME__MSG 'PUT'
      stop
   endif
   getfileid fileid
   if marktype() then
      had_mark = 1
      call psave_mark(save_mark)
      call prestore_mark(save_mark)
   elseif .last = 0 then sayerror FILE_IS_EMPTY__MSG; stop
   else
      had_mark = 0
      call pset_mark(1,.last,1,1,'LINE',fileid)
   endif
   /* If file is already in memory, we'll leave it there for speed. */
   parse value 1 check_for_printer(app_file) with already_in_ring is_printer .
   is_console = upcase(app_file)='CON' | upcase(app_file)='CON:'
   if is_printer | is_console then
      'e /q /n 'app_file
   else
      'e /q /n' app_file   /* look for file already in ring */
      if rc=-282 then  -- -282 = sayerror("New file")
         already_in_ring = 0
         'q'
         'e /q' app_file  /* not 'xcom e', so we can append to host files */
      endif
   endif
   if is_printer or is_console or not already_in_ring then
      if rc=-282 then
         deleteline
      elseif rc then
         stop
      endif
   endif
   getfileid tempofid
   if marktype()<>'LINE' then
      insertline '',tempofid.last+1
   endif
   bottom
   copyrc=pcopy_mark()
   if copyrc then /* Check memory full, invalid path, etc. */
      .modify=0; 'q'
      sayerror copyrc
      stop
   endif
   aborted=0
   /* If the app_file was already in memory, don't file it. */
   if is_printer or is_console or not already_in_ring then
      if is_console then say ''; endif
      'save'
      if is_console then pause; endif
      aborted=rc
      activatefile tempofid; tempofid.modify=0; 'q'
   endif
   activatefile fileid
   if had_mark then
      call prestore_mark(save_mark)
   else
      unmark
   endif
   if not aborted then
      sayerror MARK_APPENDED__MSG app_file
   endif
compile endif

defc asc=
   parse arg i '=' .
   if i='' then
      getline line
      i=substr(line,.col,1)
   endif
compile if EVERSION < 5
   setcommand 'asc 'i'='asc(i)'',5,1
   cursorcommand
compile else
   sayerror 'asc 'i'='asc(i)''
compile endif


defc autosave=
   universal vAUTOSAVE_PATH
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if E3
   universal autosave
compile endif
   uparg=upcase(arg(1))
   if uparg=ON__MSG then                  /* If only says AUTOSAVE ON,  */
compile if E3
   compile if DEFAULT_AUTOSAVE > 0
      autosave = DEFAULT_AUTOSAVE
   compile else
      autosave = 10                    /* default is every 10 lines. */
   compile endif
compile else
   compile if DEFAULT_AUTOSAVE > 0
      .autosave = DEFAULT_AUTOSAVE
   compile else
      .autosave=10                     /* default is every 10 mods. */
   compile endif
compile endif
   elseif uparg=OFF__MSG then
compile if E3
      autosave = 0
compile else
      .autosave = 0
compile endif
   elseif isnum(uparg) then            /* Check whether numeric argument. */
compile if EVERSION < '4.12'
      autosave = uparg
compile else
      .autosave = uparg
compile endif
   elseif uparg='DIR' then
      'dir' vAUTOSAVE_PATH
   elseif uparg='' then
compile if EPM
      'commandline autosave' .autosave
   elseif uparg='?' then
 compile if RING_OPTIONAL
     if ring_enabled then
 compile endif
 compile if 0
      do forever
         retvalue=winmessagebox(AUTOSAVE__MSG, CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10LIST_DIR__MSG, 24628)  -- YESNO + MB_INFORMATION + MOVEABLE + HELP
         if retvalue<>8 then leave; endif    -- MBID_HELP = 8
         'helpmenu 2045'
      enddo
      if 6=retvalue then  -- MBID_YES
 compile else
      if 6=winmessagebox(AUTOSAVE__MSG, CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10LIST_DIR__MSG, 16436)  -- YESNO + MB_INFORMATION + MOVEABLE
      then
 compile endif
         'dir' vAUTOSAVE_PATH
      endif
 compile if RING_OPTIONAL
     else
        call winmessagebox(AUTOSAVE__MSG, CURRENT_AUTOSAVE__MSG||.autosave\10||NAME_IS__MSG||MakeTempName()\10\10NO_LIST_DIR__MSG, 16432)  -- OK + MB_INFORMATION + MOVEABLE
     endif
 compile endif
      return
compile else  -- not EPM; uparg=''
      cursor_command; begin_line; eraseendline
 compile if E3
      keyin 'autosave' autosave
 compile else
      keyin 'autosave' .autosave
 compile endif
compile endif
   else
      sayerror AUTOSAVE_PROMPT__MSG
      return
   endif
compile if E3
   sayerror CURRENT_AUTOSAVE__MSG||autosave', 'NAME_IS__MSG||MakeTempName()
compile else
   sayerror CURRENT_AUTOSAVE__MSG||.autosave', 'NAME_IS__MSG||MakeTempName()
compile endif

;   autoshell off/on/0/1
;
; specifies whether E should automatically pass internally-unresolved commands
; to DOS.  Autoshell is an internal command; this DEFC is a simple front end
; to allow the user to type off/on/0/1.  It calls the internal command via
; 'xcom autoshell'.
;
; Users who have very long path-search times might prefer to execute
; "autoshell 0" somewhere in their start-up sequence.

compile if EVERSION < 5
defc autoshell=
   uparg=upcase(arg(1))
   if uparg='ON' or uparg=1 then
      'xcom autoshell 1'
   elseif uparg='OFF' or uparg='0' then
      'xcom autoshell 0'
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG')'
      stop
   endif
compile elseif EVERSION >= '5.50'
defc autoshell=
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      .autoshell = 1
   elseif uparg=OFF__MSG or uparg='0' then
      .autoshell = 0
   else
      sayerror 'AUTOSHELL =' .AUTOSHELL
   endif
compile endif

defc bottom,bot=
   bottom

compile if EVERSION >='4.11'
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
 compile if EVERSION >= 5
      /* jbl 12/30/88:  move msg to this case only, avoid trivial sayerror's.*/
      sayerror BROWSE_IS__MSG word(OFF__MSG ON__MSG, cb+1)
 compile endif
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif
 compile if EVERSION < 5
   if cb then cb=ON__MSG; else cb=OFF__MSG; endif
   sayerror BROWSE_IS__MSG cb
 compile endif
compile endif

compile if EVERSION < 4       -- With linking, BOX can be an external module.
; Ver.3.11:  Don't move cursor for BOX R.
;  Script style suggested by Larry Salomon, Jr.
defc box=  /* give height width style */
   universal tempofid

   uparg=upcase(arg(1))
   msg =  BOX_ARGS__MSG
   if not length(uparg) then
      sayerror msg
      cursor_command;begin_line;erase_end_line;keyin 'Box '
      stop
   endif
   if marktype()<>'BLOCK' then
      sayerror -288  -- 'Block mark required'
      stop
   endif
   flg=0
   for ptr = 1 to length(uparg)
      if flg then
         style=substr(arg(1),ptr,1)
      else
         style=substr(uparg,ptr,1)
      endif
      if style='/' then
         flg=1; iterate
      endif
      if not flg and verify(uparg,"123456BCPAERS") then
         sayerror msg
         cursor_command;begin_line;erase_end_line;keyin 'Box '
         stop
      endif
      call psave_pos(save_pos)
      getmark firstline,lastline,firstcol,lastcol,fileid
      if style='E' then
         getline tline,firstline,fileid
         getline bline,lastline,fileid
         msg=BOX_MARK_BAD__MSG
         if firstcol=1 or firstline=1 or lastline=fileid.last then
            sayerror msg
            stop
         endif

         brc=substr(bline,lastcol+1,1)
         lside=substr(tline,firstcol-1,1)
         if lside='º' or lside='³' or lside=';' or lside='|' or lside='Û'  then
            sl=1
         elseif lside='*' and firstcol>2 and  -- MAX prevents error if firstcol <= 2
                              pos(substr(tline,max(firstcol-2,1),1),'{/.') then
               sl=2
         elseif brc=lside then
            sl=1
         else
            sayerror msg
            stop
         endif
         for i=firstline to lastline
            getline line,i,fileid
            replaceline substr(line,1,firstcol-sl-1)||substr(line,firstcol,lastcol+1-firstcol)||substr(line,lastcol+sl+1),i,fileid
         endfor
         deleteline lastline+1,fileid
         deleteline firstline-1,fileid
         call prestore_pos(save_pos)
         call pset_mark( firstline-1,lastline-1,firstcol-sl,lastcol-sl,marktype(),fileid)
      elseif style='R' then
         if not pblock_reflow(0,spc,tempofid) then
            call pblock_reflow(1,spc,tempofid)
         endif
         call prestore_pos(save_pos)
      else
         if flg then
            lside=style;rside=style;tside=style;tlc=style;trc=style;blc=style;brc=style
         else
            if style='P' then lside='{*';rside='*}';tside='*';tlc='{*';trc='*}';blc='{*';brc='*}'
            elseif style='A' then lside=';';rside=' ';tside='*';tlc=';';trc=' ';blc=';';brc=' '
            elseif style='C' then lside='/*';rside='*/';tside='*';tlc='/*';trc='*/';blc='/*';brc='*/'
            elseif style=1 then lside='³';rside='³';tside='Ä';tlc='Ú';trc='¿';blc='À';brc='Ù'
            elseif style=2 then lside='º';rside='º';tside='Í';tlc='É';trc='»';blc='È';brc='¼'
            elseif style=3 then lside='|';rside='|';tside='-';tlc='+';trc='+';blc='+';brc='+'
            elseif style=4 then lside='Û';rside='Û';tside='ß';tlc='Û';trc='Û';blc='ß';brc='ß'
            elseif style=5 then lside='³';rside='³';tside='Í';tlc='Õ';trc='¸';blc='Ô';brc='¾'
            elseif style=6 then lside='º';rside='º';tside='Ä';tlc='Ö';trc='·';blc='Ó';brc='½'
            elseif style='S' then lside='.*';rside='**';tside='*';tlc='.*';trc='**';blc='.*';brc='**'
            else   style='B';lside=' ';rside=' ';tside=' ';tlc=' ';trc=' ';blc=' ';brc=' '
            endif
         endif
         sl=length(lside)
         width=1+lastcol-firstcol   /* width of inside of box */
         side=substr('',1,width,tside)
         line = substr('',1,firstcol-1)||blc||side||brc
         insertline line,lastline+1,fileid
         insertline substr('',1,firstcol-1)||tlc||side||trc,firstline,fileid
         for i=firstline+1 to lastline+1
            getline line,i,fileid
            replaceline substr(line,1,firstcol-1)||lside||substr(line,firstcol,width)||rside||substr(line,lastcol+1),i,fileid
         endfor
         call prestore_pos(save_pos)
         call pset_mark(firstline+1,lastline+1,firstcol+sl,lastcol+sl,marktype(),fileid)
      endif
      flg=0
   endfor
compile endif

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
compile if EVERSION < 5
   setcommand 'chr 'i'='chr(i)'',5,1
   cursorcommand
compile else
   sayerror 'chr 'i'='chr(i)''
compile endif

compile if EPM
defc close=
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      41,                 -- WM_CLOSE
                      0,
                      0)
compile endif

compile if EVERSION >= '5.50'
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
compile endif

defc deleteautosavefile
compile if EVERSION < '4.12'
   universal autosave
   if autosave then               -- Erase the tempfile if autosave is on.
compile else
   if .autosave then               -- Erase the tempfile if autosave is on.
compile endif
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
compile if EVERSION < 5
         sayerror EX_ALL_YN__MSG
         loop
            k=upcase(getkey())
            if k=esc then return ''; endif
            if k=NO_CHAR or k=YES_CHAR then leave endif
         endloop
compile else
         k=substr('0000'YES_CHAR || NO_CHAR, winmessagebox('Dolines', EX_ALL__MSG, 16389) - 1, 1)  -- YESNOCANCEL + MOVEABLE
         if not k then return ''; endif  -- 'Y'=Yes; 'N'=No; '0'=Cancel
compile endif
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
compile if EVERSION < 5
      sayerror 0
compile endif
   endif
   if .line then
      getline line
      line
   endif

/* This DEFC EDIT eventually calls the built-in edit command, by calling      */
/* loadfile(), but does additional processing for messy-desk windowing (moves */
/* each file to its own window), and ends by calling select_edit_keys().      */
; Parse off each file individually.  Files can optionally be followed by one
; or more commands, each in quotes.  The first file that follows a host file
; must be separated by a comma, an option, or a (possibly null) command.
;
; EPM doesn't give error messages from XCOM EDIT, so we have to handle that for
; it.
compile if EVERSION < 5   -- E3 & EOS2:  display multiple messages on a cleared
  define SAYERR = 'say'   -- screen, since only most recent SAYERROR can be seen.
compile else
  define SAYERR = 'sayerror'  -- EPM:  Message box shows all SAYERRORs
compile endif

compile if LINK_HOST_SUPPORT & (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL')
 compile if not defined(MVS)
    MVS = 0
 compile endif
 compile if not defined(E3MVS)
    E3MVS = 0
 compile endif
 compile if not defined(HOST_LT_REQUIRED)
    HOST_LT_REQUIRED = 0
 compile endif
compile endif

compile if not defined(WANT_TRUNCATED_WARNING)
const WANT_TRUNCATED_WARNING = 0
compile endif

compile if not EPM
defc e,ed,edit=
compile else
defc e,ed,edit,epm=
compile endif
universal default_edit_options
compile if not EPM
   universal messy
compile endif
  compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') & not SMALL
   universal fto                -- Need this passed to loadfile...
  compile endif

   rest=strip(arg(1))

   if rest='' then   /* 'edit' by itself goes to next file */
compile if EVERSION < 5
      call pnextfile()
      call select_edit_keys()
compile else
      nextfile
compile endif
      return 0
   endif

   options=default_edit_options
   parse value '0 0' with files_loaded new_files_loaded new_files not_found bad_paths truncated access_denied invalid_drive error_reading error_opening first_file_loaded
--  bad_paths     --> Non-existing path specified.
--  truncated     --> File contained lines longer than 255 characters.
--  access_denied --> If user tried to edit a subdirectory.
--  invalid_drive --> No such drive letter
--  error_reading --> Bad disk(ette).
--  error_opening --> Path contained invalid name.

   do while rest<>''
      rest=strip(rest,'L')
      if substr(rest,1,1)=',' then rest=strip(substr(rest,2),'L'); endif
      ch=substr(rest,1,1)
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') & not SMALL
 compile if (MVS or E3MVS) and not HOST_LT_REQUIRED  -- (MVS filespecs can start with '.)
  compile if EVERSION >= '5.50'      -- Now use "" to support spaces in filenames
      if 0 then                         -- No-op
  compile else
      if ch='"' then                    -- Command
  compile endif
 compile else
  compile if EVERSION >= '5.50'     -- Now use "" to support spaces in filenames
      if ch="'" then                    -- Command
  compile else
      if ch='"' | ch="'" then           -- Command
  compile endif
 compile endif
compile else
 compile if EVERSION >= '5.50'     -- Now use "" to support spaces in filenames
      if ch="'" then                    -- Command
 compile else
      if ch='"' | ch="'" then           -- Command
 compile endif
compile endif
         parse value rest with (ch) cmd (ch) rest
         do while substr(rest,1,1)=ch & pos(ch,rest,2)
            parse value rest with (ch) p (ch) rest
            cmd = cmd || ch || p
         enddo
         cmd
      elseif ch='/' then       -- Option
         parse value rest with opt rest
         options=options upcase(opt)
      else
         files_loaded=files_loaded+1  -- Number of files we tried to load
compile if EVERSION >= '5.50'     -- Now use "" to support spaces in filenames
      if ch='"' then
         p=pos('"',rest,2)
         if p then
            file = substr(rest, 1, p)
            rest = substr(rest, p+1)
         else
            sayerror INVALID_FILENAME__MSG
            return
         endif
      else
compile endif
compile if HOST_SUPPORT & not SMALL
         p=length(rest)+1  -- If no delimiters, take to the end.
         p1=pos(',',rest); if not p1 then p1=p; endif
         p2=pos('/',rest); if not p2 then p2=p; endif
         p3=pos('"',rest); if not p3 then p3=p; endif
         p4=pos("'",rest); if not p4 then p4=p; endif
  compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
    compile if MVS or E3MVS
         p4=p     -- Can't use single quote for commands if allowing MVS files
    compile endif
         p5=pos('[',rest); if not p5 then p5=p; endif  -- Allow for [FTO]
         p=min(p1,p2,p3,p4,p5)
  compile else
         p=min(p1,p2,p3,p4)
  compile endif
         file=substr(rest,1,p-1)
         if VMfile(file,more) then        -- tricky - VMfile modifies file
            if p=p1 then p=p+1; endif     -- Keep any except comma in string
            rest=more substr(rest,p)
         else
compile endif
            parse value rest with file rest2
            if pos(',',file) then parse value rest with file ',' rest
            else rest=rest2; endif
compile if HOST_SUPPORT & not SMALL
         endif
  compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
         if substr(strip(rest,'L'),1,1)='[' then
            parse value rest with '[' fto ']' rest
         else
            fto = ''                           --  reset for each file!
         endif
  compile endif
compile endif
compile if EVERSION >= '5.50'     -- Now use "" to support spaces in filenames
      endif
compile endif

compile if EVERSION >= '5.50'     -- Now use "" to support spaces in filenames
      if pos('=', file) & not pos('"', file) then
         call parse_filename(file,.filename)
         if pos(' ', file) then
            file = '"'file'"'
         endif
      endif
compile else
         call parse_filename(file,.filename)
compile endif

compile if USE_APPEND  -- Support for DOS 3.3's APPEND, thanks to Ken Kahn.
         If not(verify(file,'\:','M')) then
            if not exist(file) then
               File = Append_Path(File)||File  -- LAM todo: fixup
            Endif
         Endif
compile endif

compile if WANT_WINDOWS         -- Always 0 for EPM
         if messy then                            -- messy-desk style?
            .windowoverlap=1
            if pos('H',options) then      -- hidden option used?
               call loadfile(file,options)
            else
               if not verify(file,'?*','M') and   -- If no wildcards
                  not pos('D',options)    -- and not /D,
               then
                  if verify(file,':\','M') then   -- get fully qualified file
                     getfileid newfileid,file
                  else
                     getfileid newfileid,directory()'\'file -- (add path if necessary).
                     if newfileid='' & pos('N', options) then  -- Only match different path if /n
                        getfileid newfileid,file
                     endif
                  endif
                  if newfileid<>'' then           -- If it's already loaded,
                     .box=1
                     if newfileid.windowid=0 then   -- (in the hidden ring?)
                        newwindow 'e /w' options file -- (Yes, have to edit it.)
                     else
                        activatefile newfileid       -- then just activate it.
                     endif
                     iterate
                  endif
               endif
               newwindow 'e /w /n'  /* start a new file */
               /* Newwindow 'e' creates an empty file just like E startup. */
               getfileid emptyfileid
               if not (rc and rc<>-282) then  -- sayerror('New file')
                  if pos('Q',options) then sayerror 1; endif
                  call loadfile(file,options argsep||'w')
                  loadrc=rc
                  getfileid newfileid
                  if loadrc=-270 & newfileid=emptyfileid then  -- sayerror('Not enough memory')
                     deletewindow
                     stop
                  endif           -- Otherwise, wildcard & some were loaded.
                  call create_window_for_each_file(emptyfileid)
                  .windowoverlap=1
                  if not loadrc or loadrc=-282 or    -- sayerror('New file')
                                   loadrc=-270 or    -- sayerror('Not enough memory')
                                   loadrc=-278 then  -- sayerror('Lines truncated')
                     /* Normal results, normal cleanup:  discard empty file. */
                     activatefile emptyfileid
                     quitview
                     activatefile newfileid
                  else     /* Unexpected error! */
                     deletewindow
                  endif
               endif
               prevwindow; .box=1; nextwindow
            endif
         else      -- not messy
compile endif
            call loadfile(file,options)
compile if WANT_WINDOWS
            prevfile;.box=1;nextfile
         endif -- if messy
compile endif

         if rc=-3 then        -- sayerror('Path not found')
            bad_paths=bad_paths', 'file
         elseif rc=-2 then    -- sayerror('File not found')
            not_found=not_found', 'file
         elseif rc=-282 then  -- sayerror('New file')
            new_files=new_files', 'file
            new_files_loaded=new_files_loaded+1
         elseif rc=-278 then  --sayerror('Lines truncated')
            getfileid truncid
compile if EPM
            do i=1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
compile else
            do i=1 to 999
compile endif
               if .modify then leave; endif  -- Need to do this if wildcards were specified.
compile if EPM
               nextfile
compile else
               call pnextfile(1)
compile endif
            enddo
            truncated=truncated', '.filename
            .modify = 0
compile if WANT_TRUNCATED_WARNING
 compile if EPM
            refresh
            call winmessagebox(sayerrortext(-278), .filename\10 || LINES_TRUNCATED_WNG__MSG, 16416)  -- MB_OK + MB_WARNING + MB_MOVEABLE
 compile else
            messageNwait('Lines truncated; file may be damaged if saved.')
 compile endif
            activatefile truncid
compile endif  -- WANT_TRUNCATED_WARNING
         elseif rc=-5 then  -- sayerror('Access denied')
            access_denied=access_denied', 'file
         elseif rc=-15 then  -- sayerror('Invalid drive')
            invalid_drive=invalid_drive', 'file
         elseif rc=-286 then  -- sayerror('Error reading file')
            error_reading=error_reading', 'file
         elseif rc=-284 then  -- sayerror('Error opening file')
            error_opening=error_opening', 'file
         endif
         if first_file_loaded='' then
            if rc<>-3   &  -- sayerror('Path not found')
               rc<>-2   &  -- sayerror('File not found')
               rc<>-5   &  -- sayerror('Access denied')
               rc<>-15     -- sayerror('Invalid drive')
            then
               getfileid first_file_loaded
            endif
         endif
      endif  -- not "cmd"
   enddo  -- while rest<>''
   if files_loaded>1 then  -- If only one file, leave E3's message
      if new_files_loaded>1 then p='New files:'; else p='New file:'; endif
compile if EVERSION < 5  -- EPM doesn't give messages; have to supply in all cases.
      if new_files || bad_paths || not_found || truncated || access_denied || error_reading || error_opening || invalid_drive <>
         invalid_drive || error_opening || error_reading || access_denied || truncated || not_found || bad_paths || new_files
      then                                        -- More than one.
compile else
      multiple_errors = (new_files || bad_paths || not_found || truncated || access_denied || error_reading || error_opening || invalid_drive <>
                        invalid_drive || error_opening || error_reading || access_denied || truncated || not_found || bad_paths || new_files ) &
                  '' <> new_files || bad_paths || not_found || truncated || access_denied || error_reading || error_opening || invalid_drive

compile endif
         if new_files then $SAYERR NEW_FILE__MSG substr(new_files,2); endif
         if not_found then $SAYERR FILE_NOT_FOUND__MSG':' substr(not_found,2); endif
compile if EPM  -- If only one file, don't need "New file" msg in EPM.
   else
      multiple_errors = 0
   endif
compile endif
         if bad_paths then $SAYERR BAD_PATH__MSG':' substr(bad_paths,2); endif
         if truncated then $SAYERR LINES_TRUNCATED__MSG':' substr(truncated,2); endif
         if access_denied then $SAYERR ACCESS_DENIED__MSG':' substr(access_denied,2); endif
         if invalid_drive then $SAYERR INVALID_DRIVE__MSG':' substr(invalid_drive,2); endif
         if error_reading then $SAYERR ERROR_OPENING__MSG':' substr(error_reading,2); endif
         if error_opening then $SAYERR ERROR_READING__MSG':' substr(error_opening,2); endif
compile if EVERSION < 5
         pause
      elseif new_files then sayerror NEW_FILE__MSG':' substr(new_files,2)
      elseif bad_paths then sayerror BAD_PATH__MSG':' substr(bad_paths,2)
      elseif not_found then sayerror FILE_NOT_FOUND__MSG':' substr(not_found,2)
      elseif truncated then sayerror LINES_TRUNCATED__MSG':' substr(truncated,2)
      elseif access_denied then sayerror ACCESS_DENIED__MSG':' substr(access_denied,2)
      elseif invalid_drive then sayerror INVALID_DRIVE__MSG':' substr(invalid_drive,2)
      elseif error_reading then sayerror ERROR_OPENING__MSG':' substr(error_reading,2)
      elseif error_opening then sayerror ERROR_READING__MSG':' substr(error_opening,2)
      endif
compile else
      if multiple_errors then
         messageNwait(MULTIPLE_ERRORS__MSG)
      endif
compile endif
      if first_file_loaded<>'' then activatefile first_file_loaded; endif
compile if EVERSION < 5
   endif
compile endif

compile if not EPM
   /* Save the edit RC through select_edit_keys, since it might get reset  */
   /* by some command like 'tabs' or 'margins'.  This used to be in        */
   /* select_edit_keys, but that made configurability hard.                */
   saverc=rc
   call select_edit_keys()
   rc=saverc
   .box=2
compile elseif MENU_LIMIT
;compile if SHOW_MODIFY_METHOD = 'TITLE'
;  call settitletext(.filename) /* done internally */
;compile endif
   if .visible & files_loaded then
      call updateringmenu()
   endif
compile endif


; LAM - Edit a file along the EPATH.  This command will be included if
; the user is including the required routines.  If you've done a
;   SET EPMPATH=d:\EPM;d:\my_emacs;d:\E_macros
; and then do
;   ep stdcmds.e
; that will load this file, just as if you had entered
;   e d:\e_macros\stdcmds.e
; 1994/03/02:  Can specify '.' as the path to use the default, and can
;              include additional arguments for the E command.  E.g.,
;                 ep mycnf.e . '/spell'
compile if 1 -- USE_APPEND or (WANT_SEARCH_PATH and WANT_GET_ENV and not SMALL)
defc ep, epath=
   parse arg filename pathname rest
   if pathname='' | pathname='.' then
compile if E3
      if filetype(filename)='BAT' then
compile else
      if filetype(filename)='CMD' then
compile endif
         pathname='PATH'
      else
         pathname=EPATH
      endif
   endif
compile if 0  -- Old way required the optional search_path & get_env routines
   if not exist(filename) then
      filename = search_path_ptr(Get_Env(pathname,1),filename)filename
   endif
   'e 'filename
compile else  -- New way uses the built-in Findfile.
 compile if EVERSION >= '5.50'
   if pos('=', filename) & leftstr(filename, 1)<>'"' then
 compile else
   if pos('=', filename) then
 compile endif
      call parse_filename( filename, substr(.filename, lastpos('\', .filename)+1))
   endif
   findfile newfile, filename, pathname
   if rc then
      newfile = filename
   endif
   'e 'newfile rest
compile endif

 compile if EPM
defc op, opath, openpath=
   "open 'ep "arg(1)"'"
 compile endif
compile endif


; jbl 1/12/89:  The syntax of ECHO is revised to be like browse().  It's
; a function so a macro can test its current value.
defc echo =
compile if EVERSION >= '4.12'
   uparg=upcase(arg(1))
   if uparg=ON__MSG or uparg=1 then
      call echo(1)
   elseif uparg=OFF__MSG or uparg='0' then
      call echo(0)
 compile if EVERSION >= '5.60'
   elseif isnum(uparg) then
      call echo(uparg)
 compile endif
   else
 compile if EVERSION < 5
      if echo() then onoff = ON__MSG; else onoff = OFF__MSG; endif
      cursor_command
      setcommand 'echo' onoff,8,1
 compile elseif EVERSION < '5.60c'
      sayerror ECHO_IS__MSG word(OFF__MSG ON__MSG 2, echo()+1)
 compile else
      if echo()<2 then
         sayerror ECHO_IS__MSG word(OFF__MSG ON__MSG, echo()+1)
      else
         sayerror ECHO_IS__MSG echo()
      endif
 compile endif
   endif
compile else                         -- The old way, for E3 & EOS2FAM.
   if arg(1) = '' then
      echo 'ON'
   else
      echo arg(1)
   endif
compile endif

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
 compile if EVERSION < 5
defc et=
 compile else
 define TEMPFILENAME = 'tempfile'
defc et,etpm=
 compile endif
   universal vTEMP_PATH,vTEMP_FILENAME
   infile=arg(1); if infile='' then infile=MAINFILE endif
   sayerror COMPILING__MSG infile
 compile if EVERSION < 5
   quietshell 'xcom et /e' vTEMP_FILENAME infile
   if rc=-2 then sayerror CANT_FIND_PROG__MSG 'ET.Exe';stop endif
 compile else
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
 compile endif
   if rc then
      saverc = rc
      call ec_position_on_error($TEMPFILENAME)
      rc = saverc
   else
 compile if EPM
      refresh
 compile endif
      sayerror COMP_COMPLETED__MSG
   endif
   call erasetemp($TEMPFILENAME) -- 4.11:  added to erase the temp file.
compile endif

               -- No EXIT command in EPM.  Do it from the system pull-downs.
compile if EVERSION < 5
;  Ver. 3.11D  Optional return code as argument.  Added by Davis Foulger
defc exit=
   if askyesno(EXIT_PROMPT__MSG) = YES_CHAR then
      exit arg(1)
   endif
   sayerror 0
compile endif


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
compile if EVERSION < 5
      if expand_on then onoff = ON__MSG; else onoff = OFF__MSG; endif
      cursor_command
      setcommand 'expand' onoff,8,1
compile else
      sayerror 'EXPAND:' word(OFF__MSG ON__MSG, expand_on+1)
compile endif
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
compile if EPM
   oldmarg = .margins
   .margins = l r p
   if .margins = l r p then
compile else
   oldmarg = pmargins()
   'xcom margins' l r p
   if pmargins() = l r p then
compile endif
      call psave_mark(save_mark)
      call text_reflow()
      call prestore_mark(save_mark)
   else
      sayerror 'Invalid argument.'
   endif
compile if EPM
   .margins = oldmarg
compile else
   'xcom margins' oldmarg
compile endif


compile if EVERSION < 4       -- With linking, GET can be an external module.
defc get=
   universal default_edit_options
   get_file = strip(arg(1))
   if get_file='' then sayerror NO_FILENAME__MSG 'GET'; stop endif
   if pos(argsep,get_file) then
      sayerror INVALID_OPTION__MSG
      stop
   endif
   call parse_filename(get_file,.filename)
   getfileid fileid
   s_last=.last
   'e /q /h /d' default_edit_options get_file
   editrc=rc
   getfileid gfileid
   if editrc= -2 | .last=0 then  -- -2 = sayerror('New file')
      'q'
      if editrc=-2 then
         sayerror FILE_NOT_FOUND__MSG':  'get_file
      else
         sayerror FILE_IS_EMPTY__MSG':  'get_file
      endif
      stop
   endif
   if editrc & editrc<> -278 then  -- -278 = sayerror('Lines truncated')
      sayerror editrc
      stop
   endif
   call psave_mark(save_mark)
   top
   mark_line
   bottom
   mark_line
   activatefile fileid
   rc=0
   copy_mark
   copy_rc=rc           -- Test for memory too full for copy_mark.
   activatefile gfileid
   'q'
   parse value save_mark with s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt
   if fileid=s_mkfileid then           -- May have to move the mark.
      diff=fileid.last-s_last          -- (Adjustment for difference in size)
      if fileid.line<s_firstline then s_firstline=s_firstline+diff; endif
      if fileid.line<s_lastline then s_lastline=s_lastline+diff; endif
   endif
   call prestore_mark(s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt)
   if copy_rc then
      sayerror NOT_2_COPIES__MSG get_file
   else
      call message(1)
   endif
   activatefile fileid
   call select_edit_keys()
compile endif

defc goto =
   parse arg line col .
   line
   if col<>'' then .col = col; endif

/* Uses findfile statement to search EPATH for the helpfile.              */
/* Its syntax: findfile destfilename,searchfilename[,envpathvar][,['P']]  */
defc help=
compile if EVERSION < 5
   universal messy
compile endif
   helpfile = HELPFILENAME

compile if EVERSION > 4
   -- 4.02:  search EPATH/DPATH for the help file.  New 'D' option on findfile.
   findfile destfilename, helpfile, '','D'
   if rc then    /* If not there, search the HELP path. */
      findfile destfilename, helpfile, 'HELP'
   endif
compile else
   findfile destfilename, helpfile,EPATH
compile endif
   if rc then
      /* If all that fails, try the standard path. */
      findfile destfilename, helpfile, 'PATH'
      if rc then
         sayerror FILE_NOT_FOUND__MSG':' helpfile
         return ''
      endif
   endif
compile if EVERSION < 5
 compile if WANT_WINDOWS
   if messy then
      newwindow 'e /w 'destfilename  /* load one view only */
      call setzoomwindow(1,1,1,25,screenwidth())
      .windowoverlap=1
   else
 compile endif
      'e /w 'destfilename  /* load one view of help only */
 compile if WANT_WINDOWS
   endif
 compile endif
compile else
   'openhelp' destfilename
compile endif

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
compile if EVERSION < 5
      k=mgetkey(KEY_PROMPT1__MSG)  -- Accept key from macro.
   endif
   if k<>esc then
      cursor_data
compile else
      sayerror KEY_PROMPT2__MSG '"key 'number' =", "key 'number' S+F3".'
      return
   else
      k=resolve_key(k)
compile endif
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
compile if EVERSION < 5
      cursor_command
compile endif
   endif
   sayerror 0


defc l, locate =  /* Note:  this DEFC also gets executed by the slash ('/') command. */
   universal default_search_options
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif
compile if EVERSION < 5
   r=rc /* This little trick tells us whether we're in a macro or on command */
        /* line, so we'll know where to leave the cursor at end.             */
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
compile if EVERSION < 5
   if not rc and r then
      cursor_data
 compile if defined(HIGHLIGHT_COLOR)
      refresh
      sayat '', .windowy+.cursory-1,.windowx+.cursorx-1,
            HIGHLIGHT_COLOR, min(search_len, .windowwidth - .cursorx + 1)
      k = mgetkey(); executekey k
 compile endif
   else
      call leave_last_command(r,rc)
   endif
compile elseif defined(HIGHLIGHT_COLOR)
   call highlight_match(search_len)
compile endif

; As of EPM 5.18, this command supports use of the DOS or OS/2 ATTRIB command,
; so non-IBM users can also use the LIST command.  Note that installing SUBDIR
; (DOS) or FILEFIND (OS/2) is still preferred, since it's not necessary to
; "clean up" their output.  Also, ATTRIB before DOS 3.? doesn't support the /S
; option we need to search subdirectories.
defc list, findfile, filefind=
   universal vTEMP_FILENAME
compile if not EPM32
   universal subdir_present
compile endif
compile if EVERSION < 5
   call save_command_state(cstate)
compile endif
   /* If I say "list c:\util" I mean the whole util directory.  But we */
   /* have to tell SubDir that explicitly by appending "\*.*".         */
   spec = arg(1)
   call parse_filename(spec,.filename)
compile if not EPM32  -- If we're calling DIR rather than ATTRIB or SUBDIR, it assumes all this
   if spec='' then    /* If no argument at all, assume current directory. */
      spec="*.*"
   elseif not verify(spec,'*?','M') then      /* If no wildcards... */
 compile if EPM                                   /* assume directory.  */
      if pos(rightstr(spec,1),'\:') then         /* If ends in ':' or '\' */
 compile else
      if pos(substr(spec,length(spec),1),'\:') then
 compile endif
         spec=spec'*.*'                             /* just add '*.*'         */
      else
         spec=spec'\*.*'                            /* Otherwise, add '\*.*'  */
      endif
   endif
compile endif -- not EPM32
   src = subdir(spec' >'vTEMP_FILENAME)  -- Moved /Q option to defproc subdir

   'e' argsep'd' argsep'q' vTEMP_FILENAME
   call erasetemp(vTEMP_FILENAME)
   if .last then
      .filename='.DIR 'spec
compile if not EPM32
      if pos('ATTRIB.EXE',subdir_present) then  /* Handle differently          */
         getline line,1
         if src then                  /* Extract error message.      */
            'xcom q'
 compile if EVERSION < 5
            call restore_command_state(cstate)
 compile endif
            sayerror FILE_NOT_FOUND__MSG':  'line
         else                         /* Must delete the attributes.      */
            c=pos(':',line)           /* Delete through last space before */
            s=lastpos(' ',line,c+1)   /* the colon.  Can't use absolute   */
            if s then                 /* column position; changes with OS */
               call psave_mark(savemark)
               getfileid fid
               call pset_mark(1,.last,1,s,'BLOCK',fid)
               deletemark
               call prestore_mark(savemark)
               .modify=0
            endif
         endif
compile endif -- not EPM32
compile if not E3
 compile if not EPM32
      elseif substr(subdir_present,1,4)='dir ' then
 compile endif -- not EPM32
         if .last<=2 & substr(textline(.last),1,8)='SYS0002:' then
            'xcom q'
            sayerror FILE_NOT_FOUND__MSG
         endif
compile endif  -- not E3
compile if not EPM32
      endif
compile endif
   else
      'xcom q'
compile if EVERSION < 5
      call restore_command_state(cstate)
compile endif
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
compile if EVERSION < 5
      k=mgetkey(KEY_PROMPT1__MSG)  -- Accept key from macro.
   endif
   if k<>esc then
      cursor_data
compile else
      sayerror KEY_PROMPT2__MSG '"loopkey 'finish' =", "loopkey 'finish' S+F3".'
   else
      k=resolve_key(k)
compile endif
      oldcol=.col
      for i=1 to finish
         executekey k;down;.col=oldcol
      endfor
compile if EVERSION < 5
      cursor_command
compile endif
   endif
   sayerror 0

defc lowercase=
   call plowercase()

compile if EPM
;  In EOS2 you could query the margins by typing "margins" with no argument.
;  It typed them into the command line.  In EPM have to do this in the macros.
;
defc margins,ma=
   if arg(1)<>'' then         -- if user gives an argument he's setting,
      'xcom margins' arg(1)   -- pass it to the old internal margins command.
   else
      'commandline margins' .margins   -- Note the new .margins field
   endif
compile endif

defc matchtab=
   universal matchtab_on
   uparg=upcase(arg(1))
   if uparg=ON__MSG then
      matchtab_on = 1
   elseif uparg=OFF__MSG then
      matchtab_on = 0
   elseif uparg='' then
compile if EVERSION < 5
      if matchtab_on then onoff = ON__MSG; else onoff = OFF__MSG; endif
      cursor_command
      setcommand 'matchtab' onoff, 10, 1
compile else
      sayerror 'MATCHTAB:' word(OFF__MSG ON__MSG, matchtab_on+1)
compile endif
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
compile if EVERSION < 5
      setcommand 'Name '.filename,6
compile else
      'commandline Name '.filename
compile endif
   else
compile if WANT_LAN_SUPPORT | EVERSION >= '5.51'
      if .lockhandle then
         sayerror LOCKED__MSG
         return
      endif
compile endif
compile if SMARTFILE or EVERSION >= '5.50'
      oldname = .filename
compile endif
      autosave_name = MakeTempName()
      call namefile(arg(1))
compile if SMARTFILE or EVERSION >= '5.50'
      if oldname <> .filename then .modify = .modify+1 endif
compile endif
compile if EVERSION > 5
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
 compile if SHOW_MODIFY_METHOD = 'TITLE' | EVERSION < '5.50'
      call settitletext(.filename)
 compile endif
 compile if MENU_LIMIT
      call updateringmenu()
 compile endif
compile endif  -- EVERSION > 5
compile if E3
      if exist(autosave_name) then
         quietshell 'rename' autosave_name MakeTempName()
      endif
compile else
      call dosmove(autosave_name, MakeTempName())  -- Rename the autosave file
compile endif
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
   endif

defc newtop = l=.line; .cursory=1; l

defc newwindow=
compile if EVERSION < 5
   universal messy
   if messy then opt=' /w'; else opt=''; endif
   rest=parse_file_n_opts(arg(1))
   newwindow 'e'opt rest
   call select_edit_keys()
compile else
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
 compile if EVERSION >= '6.03'
      elseif .readonly then
         fn = '/r' fn
 compile endif
      endif
   endif
   'open' fn
   'quit'
compile endif

compile if EPM32
defc nextview
   getfileid fid
   vid = .currentview_of_file
   next = .nextview_of_file
   if vid = next then
      sayerror ONLY_VIEW__MSG
   else
      activatefile next
   endif
compile endif

compile if EPM
;  New in EPM.  Edits a file in a different PM window.  This means invoking
;  a completely new instance of E.DLL, with its own window and data.  We do it
;  by posting a message to the executive, the top-level E application.
defc o,open=
 compile if WPS_SUPPORT
   universal wpshell_handle
 compile endif
   fname=strip(arg(1))                    -- Remove excess spaces
   call parse_filename(fname,.filename)   -- Resolve '=', if any

 compile if WPS_SUPPORT
   if wpshell_handle then
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5159,                   -- EPM_WPS_OPENNEWFILE
                         getpminfo(EPMINFO_EDITCLIENT),
                         put_in_buffer(fname))
   else
 compile endif
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5386,                   -- EPM_EDIT_NEWFILE
                         put_in_buffer(fname),
                         1)                      -- Tell EPM to free the buffer.
 compile if WPS_SUPPORT
   endif
 compile endif
compile endif

compile if EVERSION > 5
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
compile endif

compile if EVERSION >= '5.60'
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
compile endif

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
compile if EVERSION < '5.51'  -- 5.50 for /NE, 5.51 for /S.  Nobody should still be on 5.50, anyway.
   'xcom save /q' prt     /* This will not set .modify to 0 */
compile else
   'xcom save /s /ne /q' prt  /* /NE means No EOF (for Laserjet driver) */
compile endif
   if marktype() then .modify=0; 'xcom q' endif
   sayerror 0    /* clear 'printing' message */

compile if EVERSION > 5
defc processbreak
   universal Dictionary_loaded
   call showwindow('ON')             -- Make sure that the window is displayed.
   if dictionary_loaded then
      call drop_dictionary()
   endif
   sayerror MACRO_HALTED__MSG
compile endif

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
compile if EPM  -- EPM has error checking; EOS2 & E3 just stop.
   display -2
   rc = 0
compile endif
   activatefile fid
compile if EPM
   display 2
   if rc then
      sayerror FILE_GONE__MSG
      return
   endif
compile endif
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
compile if EVERSION >= '4.11'
 compile if SHELL_USAGE
   if .filename = ".SHELL" then
;     It's important to kill the process before we quit the window, else the
;     process will churn merrily along without output.  If we're MAKEing a
;     large C program and quit the editor, it can tie up the session.
;     Simpler tasks like DIR and FILEFIND don't tie up the session.
;
;     Doesn't hurt anything if the process has already been killed.  The
;     internal shell_kill function will merely beep at you.
      call shell_kill()
   endif
 compile endif
compile endif

compile if EPM & SPELL_SUPPORT
   if .keyset='SPELL_KEYS' then  -- Dynamic spell-checking is on for this file;
      'dynaspell'                -- toggle it off.
   endif
compile endif

compile if EVERSION > '5.19' & WANT_EPM_SHELL
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
compile if WANT_LAN_SUPPORT & EVERSION < '5.51'
   if .lockhandle then call unlock(quitfileid); endif
compile endif
   call quitfile()
compile if EVERSION < 5
   call select_edit_keys()
   .box=2
compile elseif MENU_LIMIT
   getfileid fileid
   if fileid <> quitfileid then    -- temp workaround - fileid not null if no more files;
                                   -- breaks updateringmenu.
   call updateringmenu()
   endif
compile endif

defc rc=
   arg(1)
   sayerror 'RC='rc''

compile if EVERSION >= '6.03'
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
compile endif

defc reflow_all
   call psave_mark(savemark)
   call psave_pos(savepos)
compile if not EPM
   cursor_data
compile endif
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
compile if EVERSION >='4.11'
 compile if EVERSION >='6.03'
   if name='' & (browse() | .readonly) then
      if .readonly then
         sayerror READ_ONLY__MSG
      else
         sayerror BROWSE_IS__MSG ON__MSG
      endif
 compile else
   if name='' & browse() then
      sayerror BROWSE_IS__MSG ON__MSG
 compile endif
      rc = -5  -- Access denied
      return
   endif
compile endif
compile if EVERSION >= '5.21'
   save_as = 0
   if name='' | name=UNNAMED_FILE_NAME then
compile else
   if name='' then
compile endif
      name=.filename
compile if EVERSION >= '5.21'
      if .filename=UNNAMED_FILE_NAME then
         result = saveas_dlg(name, type)
         if result then return result; endif
         'name' name
         if not rc then
            name=.filename
            save_as = 1
         endif
      endif
compile endif
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
compile if WANT_LAN_SUPPORT & EVERSION < '5.51'
   locked = .lockhandle
   if locked & not arg(1) then 'unlock'; endif
compile endif
compile if WANT_BOOKMARKS
 compile if EVERSION >= '6.01b'
   if .levelofattributesupport bitand 8 then
 compile else
   if .levelofattributesupport%8 - 2*(.levelofattributesupport%16) then
 compile endif
      'saveattributes'
   endif
compile endif
compile if not E3
   -- 4.10:  Saving with tab compression is built in now.  No need for
   -- the make-do proc savefilewithtabs().
   -- 4.10 new feature:  if save_with_tabs is true, always specify /t.
   if save_with_tabs then
      options = '/t' options
   endif
compile elseif WANT_TABS
   if isoption(options,'t') or save_with_tabs then
      src=savefilewithtabs(name,options)
   else
compile endif
      src=savefile(name,options)
compile if (EVERSION < '4.10') & WANT_TABS
   endif
compile endif
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
compile if not E3
 compile if EPM32
   elseif src=-5 | src=-285 then  --  -5 = 'Access denied'; -285 = 'Error writing file'
 compile else
   elseif src=-5 then  -- call message('Access denied')
 compile endif
      if qfilemode(name, attrib) then      -- Error from DosQFileMode
         call message(src)    -- ? Don't know why got Access denied.
      else                    -- File exists:
 compile if EVERSION >= '6.01b'
         if attrib bitand 16 then
 compile else
         if attrib % 16 - 2 * (attrib % 32) then    -- x'10' is on
 compile endif
            call message(ACCESS_DENIED__MSG '-' IS_A_SUBDIR__MSG)  -- It's a subdirectory
         elseif attrib // 2 then                    -- x'01' is on
            call message(ACCESS_DENIED__MSG '-' READ_ONLY__MSG)    -- It's read/only
 compile if EVERSION >= '6.01b'
         elseif attrib bitand 4 then
 compile else
         elseif attrib % 4 - 2 * (attrib % 8) then  -- x'04' is on
 compile endif
            call message(ACCESS_DENIED__MSG '-' IS_SYSTEM__MSG)    -- It's a system file
 compile if EVERSION >= '6.01b'
         elseif attrib bitand 2 then
 compile else
         elseif attrib % 2 - 2 * (attrib % 4) then  -- x'02' is on
 compile endif
            call message(ACCESS_DENIED__MSG '-' IS_HIDDEN__MSG)    -- It's a hidden file
         else                                -- None of the above?
            call message(ACCESS_DENIED__MSG '-' MAYBE_LOCKED__MSG) -- Maybe someone locked it.
         endif
      endif
      rc = src  -- reset, since qfilemode() changed the RC.
compile endif
compile if EPM32
   elseif src=-345 then
      call winmessagebox('Demo Version', sayerrortext(-345)\10\10'File too large to be saved.' , MB_CANCEL + MB_CRITICAL + MB_MOVEABLE)
compile endif
   elseif src<0 then          -- If RC > 0 assume from host save; and
      call message(src)       -- assume host routine gave error msg.
   endif
compile if EVERSION >= '5.21'
   if src & save_as then
      .filename=UNNAMED_FILE_NAME
 compile if SHOW_MODIFY_METHOD = 'TITLE'
      call settitletext(.filename)
 compile endif
 compile if MENU_LIMIT
      call updateringmenu()
 compile endif
   endif
compile endif
compile if E3 and SHOW_MODIFY_METHOD
   call show_modify()
compile endif
compile if WANT_LAN_SUPPORT & EVERSION < '5.51'
   if locked & not arg(1) then call lock(); endif
compile endif
   return src

defc select_all =
   getfileid fid
   call pset_mark(1, .last, 1, length(textline(.last)), 'CHAR' , fid)
compile if EVERSION >= 5
   'Copy2SharBuff'       /* Copy mark to shared text buffer */
compile endif

compile if SETSTAY='?'
defc stay=
   universal stay
   parse arg arg1; arg1=upcase(arg1)
 compile if EPM
   if arg1='' then sayerror 'Stay =' word(OFF__MSG ON__MSG, stay+1)
 compile else
   if arg1='' then sayerror 'Stay =' stay
 compile endif
   elseif arg1='1' | arg1=ON__MSG then stay=1
   elseif arg1='0' | arg1=OFF__MSG then stay=0
   else sayerror INVALID_ARG__MSG ON_OFF__MSG')'
   endif
compile endif

compile if EVERSION >= '4.11' & EVERSION < 5
; read a file from stdin
defc stdfile_read
   while  read_stdin() > 0 do
      join
      bottom
   endwhile
compile elseif EPM32
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
compile endif

; write a file to stdout
defc stdfile_write
   universal vTEMP_FILENAME
   .filename=vTEMP_FILENAME
   's'
   'type '.filename
   call erasetemp(.filename)
   'q'

compile if EVERSION >= '5.50'  -- Earlier versions didn't retain trailing blanks anyway.
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
compile endif

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

compile if (EVERSION >= '5.60c' & EVERSION < 6) | EVERSION >= '6.00c'
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
compile endif

compile if EVERSION >= 5
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
compile endif

compile if not E3
defc timestamp =
 compile if WANT_DBCS_SUPPORT
   universal countryinfo
 compile endif
   parse value getdatetime() with Hour24 Minutes Seconds . Day MonthNum Year0 Year1 .
 compile if WANT_DBCS_SUPPORT
  compile if EPM32
   parse value countryinfo with 22 datesep 23 24 timesep 25
  compile else
   parse value countryinfo with 16 datesep 17 18 timesep 19
  compile endif
   keyin rightstr(Year0 + 256*Year1, 4, 0) || datesep || rightstr(monthnum, 2, 0) || datesep || rightstr(Day, 2, 0)' ' ||
         rightstr(hour24, 2) || timesep || rightstr(Minutes,2,'0') || timesep || rightstr(Seconds,2,'0')'  '
 compile else  -- no DBCS
   keyin rightstr(Year0 + 256*Year1, 4, 0)'/'rightstr(monthnum, 2, 0)'/'rightstr(Day, 2, 0)' ' ||
         rightstr(hour24, 2)':'rightstr(Minutes,2,'0')':'rightstr(Seconds,2,'0')'  '
 compile endif
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

compile if EPM
defc ver =
   sayerror EDITOR_VER__MSG ver(0)
compile endif

defc xcom_quit
compile if EVERSION < 5
   if .windowoverlap then
      quitview
   else
      'xcom q'
   endif
compile else
   'xcom q'
compile endif

