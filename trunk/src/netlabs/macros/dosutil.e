/****************************** Module Header *******************************
*
* Module Name: dosutil.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dosutil.e,v 1.4 2002-09-02 22:13:30 aschn Exp $
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
compile if not small

defc qd,qdate=
   parse value getdate(1) with today';' .  /* Discard MonthNum. */
   sayerror TODAY_IS__MSG today'.'


defc qt,qtime=
   parse value gettime(1) with now';' .    /* Discard Hour24. */
   sayerror THE_TIME_IS__MSG now'.'


defproc getdatetime
   datetime=substr('',1,20)
   call dynalink32( 'DOSCALLS',          -- dynamic link library name
                    '#230',               -- ordinal value for Dos32GetDateTime
                    address(datetime), 2 )
   return dec_to_string(datetime)
   --> Hour24 Minutes Seconds Hund Day MonthNum Year0 Year1 TZ0 TZ1 WeekdayNum


defproc getdate
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with . . . . Day MonthNum Year0 Year1 . . WeekdayNum .
   Year = Year0 + 256*Year1
   Month=strip(substr(MONTH_LIST, MonthNum*MONTH_SIZE-MONTH_SIZE+1, MONTH_SIZE))
   Weekday = strip(substr(WEEKDAY_LIST, (WeekdayNum//256)*WEEKDAY_SIZE+1, WEEKDAY_SIZE))
compile if WANT_DBCS_SUPPORT
   if arg(1) & substr(countryinfo,9,1)=\1 then  -- 0=mm/dd/yy, 1=dd/mm/yy, 2=yy/mm/dd
      return WeekDay Day Month Year';'MonthNum
   endif
compile endif
   return WeekDay Month Day',' Year';'MonthNum



defproc gettime
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with Hour24 Minutes Seconds Hund .
   AmPm=AM__MSG; Hour=Hour24
   if Hour>=12 then
      Hour=Hour-12; AmPm=PM__MSG
   endif
   if not Hour then Hour=12 endif
   Hund=rightstr(Hund,2,'0')
   Minutes=rightstr(Minutes,2,'0')
   Seconds=rightstr(Seconds,2,'0')
compile if WANT_DBCS_SUPPORT
   if arg(1) then
      time_sep = substr(countryinfo,24,1)
      return Hour || time_sep || Minutes || time_sep || Seconds AmPm';'Hour24':'Hund
   endif
compile endif
   return Hour':'Minutes':'Seconds AmPm';'Hour24':'Hund

compile endif
-------------------------------------------------------------------------------

;  Ver. 3.10:  Tells if a file exists.  DOS part from Ken Kahn.
;  Ver. 3.11a:  Use a temporary DTA for the FindFirst call.
DefProc Exist(FileName)
   cflag=qfilemode(filename, attrib)
   Return Cflag=0  -- if Carry flag=0, file exists; return 1.

defproc qfilemode(filename, var attrib)
   if leftstr(filename,1)='"' & rightstr(filename,1)='"' then
      filename=substr(filename,2,length(filename)-2)
   endif
   FileName = FileName\0
   attrib=copies(\0, 24)  -- allocate 24 bytes for a FileStatus3 structure
   res = dynalink32('DOSCALLS',            -- dynamic link library name
                   '#223',                -- ordinal value for Dos32QueryPathInfo
                   address(filename)  ||  -- Pointer to path name
                   atol(1)            ||  -- PathInfoLevel 1
                   address(attrib)    ||  -- Pointer to info buffer
                   atol(24), 2)           -- Buffer Size
   attrib = ltoa(rightstr(attrib,4),10)
   return res

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
   return search_path_ptr(Get_Env('DPATH',1), FileName)  -- If OS/2 protect mode, then use DPATH
compile endif  -- USE_APPEND

compile if USE_APPEND | WANT_SEARCH_PATH
; Ver. 3.12 - split off from Append_Path so can be called by other routines.
defproc search_path(AppendPath, FileName)
   do while AppendPath<>''
      parse value AppendPath with TryDir ';' AppendPath
      if check_path_piece(trydir, filename) then
         return trydir
      endif
   enddo
;  return ''

defproc search_path_ptr(AppendPathPtr, FileName)
   parse value AppendPathPtr with env_seg env_ofs .
   if env_ofs = '' then return; endif
   trydir = ''
   do forever
      ch = peek(env_seg,env_ofs,1)
      env_ofs = env_ofs + 1
      if ch=';' | ch = \0 then
         if check_path_piece(trydir, filename) then
            return trydir
         endif
         if ch = \0 then return; endif
         trydir = ''
      else
         trydir = trydir || ch
      endif
   enddo

defproc check_path_piece(var trydir, filename)
   if trydir='' then return; endif
   lastch=rightstr(TryDir,1)
   if lastch<>'\' & lastch<>':' then
      TryDir = TryDir||'\'
   endif
   if exist(TryDir||FileName) then
      return TryDir
   endif
compile endif  -- USE_APPEND

compile if USE_APPEND | WANT_GET_ENV
defproc get_env(varname)=  -- Optional arg(2) is flag to return pointer to value instead of the value itself.
   varname = upcase(varname)\0
   result_ptr = 1234                -- 4-byte place to put a far pointer
   rc = dynalink32('DOSCALLS',        -- rc 0 (false) if found
                  '#227',             -- Ordinal for DOS32ScanEnv
                  address(varname)    ||
                  address(result_ptr),2)
   if not rc then
      if arg(2) then
         return itoa(rightstr(result_ptr,2),10) itoa(leftstr(result_ptr,2),10)
      endif
      return peekz(result_ptr)
   endif
compile endif  -- USE_APPEND

/***
defc testap=                     /* for testing:  testap <filename> */
   res = append_path(arg(1))
   if res then sayerror res else sayerror 'none' endif
***/

defproc dosmove(oldfile, newfile)
   oldfile = oldfile\0
   newfile = newfile\0
   return dynalink32('DOSCALLS',          /* dynamic link library name */
                     '#271',              /* Dos32Move - move a file   */
                     address(oldfile)||
                     address(newfile), 2)
-------------------------------------------------------------------------------
compile if not small

/* Useful if you want the cursor keys to act differently with ScrollLock on. */
defproc scroll_lock
   /* fix this later -- odd means toggled */
   ks = getkeystate(VK_SCRLLOCK)
   return (ks==KS_DOWNTOGGLE or ks==KS_UPTOGGLE)   -- any toggled

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
   call dynalink32( 'DOSCALLS',       -- dynamic link library name
                    '#286',            -- ordinal value for Dos32Beep
                    atol(pitch) ||     -- Hertz (25H-7FFFH)
                    atol(duration),2)  -- Length of sound  in ms
   return

/*** demo command:
defc testbeep=
   parse value arg(1) with pitch duration
   call beep(pitch,duration)
***/

-- New for EPM ----------------------------------------------------------------
;  jbl 12/30/88:  Provide DIR and other DOS-style query commands by redirecting
;  output to a file.
defc dir =
   parse arg fspec
   call parse_filename(fspec,.filename)
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
   command=arg(1)
   if command='' then    -- prompt user for command
      command=entrybox(ENTER_CMD__MSG)
      if command='' then return; endif
   endif
   'start /win 'command
   if rc=1 then
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
; Used to always do:  arg(1) '>'
; but "set foo" is different than "set foo " (trailing space), so now we
; only insert the space if the argument ends with a number and so could
; be confused with redirection of a file handle.
      if pos(rightstr(arg(1), 1), '0123456789') then
         quietshell 'dos' arg(1) '>'vTEMP_FILENAME '2>&1'
      else
         quietshell 'dos' arg(1)'>'vTEMP_FILENAME '2>&1'
      endif

   'e' argsep'D' argsep'Q' vTEMP_FILENAME
   if not rc then .filename = '.DOS' arg(1); endif
   call erasetemp(vTEMP_FILENAME)

defc del, erase =
   earg = arg(1)
   if parse_filename(earg, .filename) then
      sayerror -263  --  'Invalid argument'
      return 1
   endif
   If verify(earg,'*?','M') then  -- Contains wildcards
      quietshell 'del' earg          -- must shell out
   else                           -- No wildcards?
      rc = erasetemp(earg)           -- erase via direct DOS call; less overhead.
   endif
   if rc then
      sayerror 'RC =' rc
   endif
compile endif          -- Not SMALL
