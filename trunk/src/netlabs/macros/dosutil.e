/****************************** Module Header *******************************
*
* Module Name: dosutil.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dosutil.e,v 1.6 2004-06-03 21:57:35 aschn Exp $
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
; DOSUTIL.E        Low-level functions using int86x(), peek(), poke, dynalink()
;

-- Date and time --------------------------------------------------------------
; Note: FileDateTime procs can be found in FILE.E.

defc qd,qdate=
   parse value getdate(1) with today';' .  /* Discard MonthNum. */
   sayerror TODAY_IS__MSG today'.'


defc qt,qtime=
   parse value gettime(1) with now';' .    /* Discard Hour24. */
   sayerror THE_TIME_IS__MSG now'.'


defproc getdatetime
   datetime = substr( '', 1, 20)
   call dynalink32( 'DOSCALLS',          -- dynamic link library name
                    '#230',              -- ordinal value for Dos32GetDateTime
                    address(datetime), 2 )
   return dec_to_string(datetime)
   --> Hour24 Minutes Seconds Hund Day MonthNum Year0 Year1 TZ0 TZ1 WeekdayNum

defproc getdate
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with . . . . Day MonthNum Year0 Year1 . . WeekdayNum .
   Year = Year0 + 256*Year1
   Month=strip(substr( MONTH_LIST, MonthNum*MONTH_SIZE - MONTH_SIZE + 1, MONTH_SIZE))
   Weekday = strip(substr( WEEKDAY_LIST, (WeekdayNum//256)*WEEKDAY_SIZE + 1, WEEKDAY_SIZE))
compile if WANT_DBCS_SUPPORT
   if arg(1) & substr( countryinfo, 9, 1) = \1 then  -- 0=mm/dd/yy, 1=dd/mm/yy, 2=yy/mm/dd
      return WeekDay Day Month Year';'MonthNum
   endif
compile endif
   return WeekDay Month Day',' Year';'MonthNum

defproc gettime
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with Hour24 Minutes Seconds Hund .
   AmPm = AM__MSG; Hour = Hour24
   if Hour >= 12 then
      Hour = Hour - 12; AmPm = PM__MSG
   endif
   if not Hour then Hour=12 endif
   Hund = rightstr(Hund,2,'0')
   Minutes = rightstr(Minutes,2,'0')
   Seconds = rightstr(Seconds,2,'0')
compile if WANT_DBCS_SUPPORT
   if arg(1) then
      time_sep = substr(countryinfo,24,1)
      return Hour || time_sep || Minutes || time_sep || Seconds AmPm';'Hour24':'Hund
   endif
compile endif
   return Hour':'Minutes':'Seconds AmPm';'Hour24':'Hund

; Ver. 3.10:  New routine by Ken Kahn.
; Ver. 3.11:  Support added for /E option of append.  This will also now work
;    for any user of DOS 3.0 or above that uses the DOS command SET APPEND,
;    whether or not they actually have the APPEND command installed.
compile if USE_APPEND
defproc Append_Path(FileName)
/**********************************************************************
 *                                                                    *
 *     Name : Append_Path                                             *
 *                                                                    *
 * Function : For files accessed via the DOS 3.3 APPEND facility      *
 *            this routine will search the APPEND search string and   *
 *            return the path name the file is found on.              *
 *                                                                    *
 *    Input : FileName = File name to search for                      *
 *                                                                    *
 *   Output : - If the APPEND facility is not installed and the       *
 *              filename cannot be found on any of the paths in the   *
 *              APPEND string a null value will be returned.          *
 *                                                                    *
 *            - Otherwise the path name (path\) will be returned.     *
 *                                                                    *
 **********************************************************************/
   return search_path_ptr( Get_Env( 'DPATH',1), FileName)  -- If OS/2 protect mode, then use DPATH
compile endif  -- USE_APPEND

compile if USE_APPEND | WANT_SEARCH_PATH
; Ver. 3.12 - split off from Append_Path so can be called by other routines.
defproc search_path( AppendPath, FileName)
   do while AppendPath <> ''
      parse value AppendPath with TryDir ';' AppendPath
      if check_path_piece( trydir, filename) then
         return trydir
      endif
   enddo
;  return ''

defproc search_path_ptr( AppendPathPtr, FileName)
   parse value AppendPathPtr with env_seg env_ofs .
   if env_ofs = '' then return; endif
   trydir = ''
   do forever
      ch = peek(env_seg, env_ofs, 1)
      env_ofs = env_ofs + 1
      if ch = ';' | ch = \0 then
         if check_path_piece( trydir, filename) then
            return trydir
         endif
         if ch = \0 then return; endif
         trydir = ''
      else
         trydir = trydir || ch
      endif
   enddo

defproc check_path_piece( var trydir, filename)
   if trydir = '' then return; endif
   lastch = rightstr( TryDir, 1)
   if lastch <> '\' & lastch <> ':' then
      TryDir = TryDir||'\'
   endif
   if exist(TryDir||FileName) then
      return TryDir
   endif
compile endif  -- USE_APPEND

; Optional arg(2) is flag to return pointer to value instead of the value itself.
defproc get_env(varname)
   varname = upcase(varname)\0
   result_ptr = 1234                -- 4-byte place to put a far pointer
   rc = dynalink32( 'DOSCALLS',        -- rc 0 (false) if found
                    '#227',            -- Ordinal for DOS32ScanEnv
                    address(varname)    ||
                    address(result_ptr), 2)
   if not rc then
      if arg(2) then
         return itoa( rightstr( result_ptr, 2), 10) itoa( leftstr( result_ptr, 2), 10)
      endif
      return peekz(result_ptr)
   endif

; ---------------------------------------------------------------------------
; Todo: resolve '=' as well
; Resolves environment variables in a string
; Returns converted string
defproc NepmdResolveEnvVars(Spec)
   startp = 1
   do forever
      -- We don't use parse here, because if only 1 % char is present, it will
      -- assign all the rest to EnvVar:
      --    parse value rest with next'%'EnvVar'%'rest
      --    if rest = '' then
      --       Spec = Spec''next''Get_Env(EnvVar)
      --       leave
      --    else
      --       Spec = Spec''next''Get_Env(EnvVar)''rest
      --    endif
      p1 = pos( '%', Spec, startp)
      if p1 = 0 then
         leave
      endif
      startp = p1 + 1
      p2 = pos( '%', Spec, startp)
      if p2 = 0 then
         leave
      else
         startp = p2 + 1
         Spec = substr( Spec, 1, p1 - 1) ||
                Get_Env( substr( Spec, p1 + 1, p2 - p1 - 1)) ||
                substr( Spec, p2 + 1)
      endif
      --sayerror 'arg(1) = 'arg(1)', p1 = 'p1', p2 = 'p2', resolved spec = 'Spec
   enddo  -- forever
   return Spec

/***
defc testap=                     /* for testing:  testap <filename> */
   res = append_path(arg(1))
   if res then sayerror res else sayerror 'none' endif
***/

-------------------------------------------------------------------------------
/* Useful if you want the cursor keys to act differently with ScrollLock on. */
defproc scroll_lock
   /* fix this later -- odd means toggled */
   ks = getkeystate(VK_SCRLLOCK)
   return (ks == KS_DOWNTOGGLE or ks == KS_UPTOGGLE)   -- any toggled

/*** Test command.
defc sltest
   sayerror 'scroll_lock='scroll_lock()'.'
***/

/*
The bits in the KB_flag are (from the BIOS listing):

INS_STATE      EQU   80H  = 128  ; Insert state is active
CAPS_STATE     EQU   40H  =  64  ; Caps lock state has been toggled
NUM_STATE      EQU   20H  =  32  ; Num lock state has been toggled
SCROLL_STATE   EQU   10H  =  16  ; Scroll lock state has been toggled
ALT_SHIFT      EQU   08H  =   8  ; Alternate shift key depressed
CTL_SHIFT      EQU   04H  =   4  ; Control shift key depressed
LEFT_SHIFT     EQU   02H  =   2  ; Left shift key depressed
RIGHT_SHIFT    EQU   01H  =   1  ; Right shift key depressed
*/
/*** Sample usage:
  def up=
     if scroll_lock() then      /* don't forget the parentheses */
        executekey s_f3         /* if scroll lock on, act like scroll down */
     else
        up
     endif
***/

-------------------------------------------------------------------------------

defproc beep   -- Version 4.02
-- Two optional arguments:  pitch, duration.
-- We make them optional by not declaring them in the DEFPROC, then retrieving
-- them with the arg() function.  We do this because DOS has no use for the
-- arguments.  (The alternative would be to declare them --
-- defproc beep(pitch, duration) -- and ignore them on DOS, but that would use
-- more p-code space.)
--
-- If the arguments are omitted on OS/2 we pick DOS-like values.
   if arg()=2 then
      pitch   = arg(1)
      duration= arg(2)
   endif
   if not isnum(pitch) or not isnum(duration) or pitch=0 or duration=0 then
      pitch   = 900  -- 900 Hz for 500 milliseconds sounds like a DOS beep.
      duration= 500
   endif
   call dynalink32( 'DOSCALLS',         -- dynamic link library name
                    '#286',             -- ordinal value for Dos32Beep
                    atol(pitch) ||      -- Hertz (25H-7FFFH)
                    atol(duration), 2)  -- Length of sound  in ms
   return

/*** demo command:
defc testbeep=
   parse value arg(1) with pitch duration
   call beep( pitch, duration)
***/

-- New for EPM ----------------------------------------------------------------
;  jbl 12/30/88:  Provide DIR and other DOS-style query commands by redirecting
;  output to a file.
defc dir =
   parse arg fspec
   call parse_filename( fspec, .filename)
   dos_command('dir' fspec)
   sayerror ALT_1_LOAD__MSG
   'postme monofont'

defc attrib =
   parse arg fspec
   call parse_filename(fspec,.filename)
   if verify(fspec, '+-', 'M') then  -- Attempt to change attributes;
      'dos' fspec
      if rc then                     --   only give message if attempt fails.
         sayerror 'RC =' rc
      endif
   else                              -- Else, attempt to query attributes -
      dos_command('attrib' fspec)    --   user wants to see results.
   endif

defc set   = dos_command('set' arg(1))
defc vol   = dos_command('vol' arg(1))
defc path  = dos_command('path')
defc dpath = dos_command('dpath')

defc os2
   -- Create a OS/2 windowed cmd prompt & execute a command in it.
   command = arg(1)
   if command = '' then    -- prompt user for command
      command = entrybox(ENTER_CMD__MSG)
      if command = '' then return; endif
   endif
   'start /win 'command
   if rc = 1 then
      sayerror sayerrortext(-274) command
   endif

defproc dos_command=
universal vTEMP_FILENAME
compile if RING_OPTIONAL
   universal ring_enabled
   if not ring_enabled then
      'ring_toggle'
   endif
compile endif
   -- Used to always do:  arg(1) '>'
/*
   -- but "set foo" is different than "set foo " (trailing space), so now we
   -- only insert the space if the argument ends with a number and so could
   -- be confused with redirection of a file handle.
   if pos( rightstr( arg(1), 1), '0123456789') then
      quietshell 'dos' arg(1) '>'vTEMP_FILENAME '2>&1'
   else
      quietshell 'dos' arg(1)'>'vTEMP_FILENAME '2>&1'
   endif
*/
   quietshell 'dos' arg(1) '1>'vTEMP_FILENAME '2>&1'

   'e' argsep'D' argsep'Q' vTEMP_FILENAME
   if not rc then .filename = '.DOS' arg(1); endif
   call erasetemp(vTEMP_FILENAME)

defc del, erase =
   earg = arg(1)
   if parse_filename( earg, .filename) then
      sayerror -263  --  'Invalid argument'
      return 1
   endif
   If verify( earg, '*?', 'M') then  -- Contains wildcards
      quietshell 'del' earg          -- must shell out
   else                           -- No wildcards?
      rc = erasetemp(earg)           -- erase via direct DOS call; less overhead.
   endif
   if rc then
      sayerror 'RC =' rc
   endif

; ---------------------------------------------------------------------------
; unused
; Get the number of the current codepage
; From: EBOOKE\BKEYS.E
defproc QueryCodepage
  codepage = '????'
  datalen = '????'
  rc = dynalink32( 'DOSCALLS',            -- dynamic link library name
                   '#291',                -- ordinal value for DOS32QueryCP
                   atol(4)            ||  -- length of code page list
                   offset(codepage)   ||  -- string offset
                   selector(codepage) ||  -- string selector
                   offset(datalen)    ||  -- string offset
                   selector(datalen) ,2)  -- string selector
   if rc then
      return 'ERROR:'rc
   else
      codepage_no = strip(ltoa( codepage, 10))
      return codepage_no
   endif

; ---------------------------------------------------------------------------
; As of EPM 5.18, this command supports use of the DOS or OS/2 ATTRIB command,
; so non-IBM users can also use the LIST command.  Note that installing SUBDIR
; (DOS) or FILEFIND (OS/2) is still preferred, since it's not necessary to
; "clean up" their output.  Also, ATTRIB before DOS 3.? doesn't support the /S
; option we need to search subdirectories.
; Moved from STDCMDS.E.
defc list, findfile, filefind=
   universal vTEMP_FILENAME
   /* If I say "list c:\util" I mean the whole util directory.  But we */
   /* have to tell SubDir that explicitly by appending "\*.*".         */
   spec = arg(1)
   call parse_filename( spec, .filename)
   src = subdir( spec' >'vTEMP_FILENAME)  -- Moved /Q option to defproc subdir

   'e' argsep'd' argsep'q' vTEMP_FILENAME
   call erasetemp(vTEMP_FILENAME)
   if .last then
      .filename = '.DIR 'spec
      if .last <= 2 & substr( textline(.last), 1, 8) = 'SYS0002:' then
         'xcom q'
         sayerror FILE_NOT_FOUND__MSG
      endif
   else
      'xcom q'
      sayerror FILE_NOT_FOUND__MSG
   endif

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E.
defproc subdir
   quietshell 'dir /b /s /a:-D' arg(1)

; ---------------------------------------------------------------------------
; Note on a speed trick:  The following routine is used to both verify that
; an external program exists, and to get its path.  After that first search,
; the exact path location of the routine is known; it can be remembered so that
; all future calls can supply the exact location to avoid the path search.
; See SUBDIR for an example of its use.
; Moved from STDPROCS.E.
defproc find_routine(utility)  -- Split from SUBDIR
   parse arg util opts         -- take first word, so can pass options too.
   findfile fully_qualified,util,'PATH','P'
   if rc then return -1 endif
   return fully_qualified opts

; ---------------------------------------------------------------------------
; Returns DOS version number, multiplied by 100 so we can treat
; it as an integer string.  That is, DOS 3.2 is reported as "320".
; Needed by DEFPROC SUBDIR.
; Moved from STDCTRLS.E
defproc dos_version()
      verbuf = copies(\0,8)
      res= dynalink32( 'DOSCALLS',          /* dynamic link library name */
                       '#348',              /* ordinal for DOS32QuerySysInfo */
                       atol(11)         ||  -- Start index (Major version number)
                       atol(12)         ||  -- End index (Minor version number)
                       address(verbuf)  ||  -- buffer
                       atol(8),2 )          -- Buffer length
;     major = ltoa(leftstr(verbuf,4),10)
;     minor = ltoa(rightstr(verbuf,4),10)
      return 100*ltoa(leftstr(verbuf,4),10) + ltoa(rightstr(verbuf,4),10)


