/****************************** Module Header *******************************
*
* Module Name: dosutil.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dosutil.e,v 1.20 2008-12-07 21:51:50 aschn Exp $
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
defc qd,qdate=
   parse value getdate(1) with today';' .  -- Discard MonthNum
   sayerror TODAY_IS__MSG today'.'

; ---------------------------------------------------------------------------
defc qt,qtime=
   parse value gettime(1) with now';' .    -- Discard Hour24
   sayerror THE_TIME_IS__MSG now'.'

; ---------------------------------------------------------------------------
defproc getdatetime
   datetime = substr( '', 1, 20)
   call dynalink32( 'DOSCALLS',          -- dynamic link library name
                    '#230',              -- ordinal value for Dos32GetDateTime
                    address(datetime), 2)
   return dec_to_string(datetime)
   --> Hour24 Minutes Seconds Hund Day MonthNum Year0 Year1 TZ0 TZ1 WeekdayNum

; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
defproc gettime
compile if WANT_DBCS_SUPPORT
   universal countryinfo
compile endif
   parse value getdatetime() with Hour24 Minutes Seconds Hund .
   AmPm = AM__MSG
   Hour = Hour24
   if Hour >= 12 then
      Hour = Hour - 12
      AmPm = PM__MSG
   endif
   if not Hour then
      Hour = 12
   endif
   Hund    = rightstr( Hund, 2, '0')
   Minutes = rightstr( Minutes, 2, '0')
   Seconds = rightstr( Seconds, 2, '0')
compile if WANT_DBCS_SUPPORT
   if arg(1) then
      time_sep = substr( countryinfo, 24, 1)
      return Hour || time_sep || Minutes || time_sep || Seconds AmPm';'Hour24':'Hund
   endif
compile endif
   return Hour':'Minutes':'Seconds AmPm';'Hour24':'Hund

; ---------------------------------------------------------------------------
defproc DateTime
   parse value getdatetime() with Hour24 Minutes Seconds . Day MonthNum Year0 Year1 .
   Date = rightstr( Year0 + 256*Year1, 4, 0)'-'rightstr( monthnum, 2, 0)'-'rightstr( Day, 2, 0)
   Time = rightstr( hour24, 2)':'rightstr( Minutes, 2, '0')':'rightstr( Seconds, 2, '0')
   return Date Time

; ---------------------------------------------------------------------------
; Optional arg(2) is flag to return pointer to value instead of the value itself.
; arg(2) should be removed.
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
defproc StripPath( Spec)
   lp = lastpos( '\', Spec)
   Spec = substr( Spec, lp + 1)
   return Spec

; ---------------------------------------------------------------------------
defproc StripExt( Spec)
   lp = lastpos( '.', Spec)
   if lp > 1 then
      Spec = substr( Spec, 1, lp - 1)
   endif
   return Spec

; ---------------------------------------------------------------------------
; Resolves environment variables in a string. Keeps %...% string if env var
; isn't set. Additionally ?: is replaced with the boot drive. Returns
; converted string.
; To convert also '=', the proc parse_filename( filename) should be used.
; It calls this proc as well.
defproc ResolveEnvVars( Spec)

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
         LeftPart    = substr( Spec, 1, p1 - 1)
         EnvVarName  = substr( Spec, p1 + 1, p2 - p1 - 1)
         RightPart   = substr( Spec, p2 + 1)
         EnvVarValue = Get_Env( EnvVarName)
         -- Handle not set vars: keep %... or %...% string
         if EnvVarValue = '' then
            iterate
         endif
         -- Value exists, replace %...% string and move startp
         startp = length( LeftPart) + length( EnvVarValue) + 1
         Spec = LeftPart''EnvVarValue''RightPart
      endif
   enddo

   -- Replace ?: with bootdrive
   do while pos( '?:', Spec) > 0
      parse value Spec with LeftPart'?:'RightPart
      BootDrive = NepmdQuerySysInfo('BOOTDRIVE')
      Spec = LeftPart''BootDrive''RightPart
   enddo

   return Spec

; ---------------------------------------------------------------------------
; Useful if you want the cursor keys to act differently with ScrollLock on.
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

; ---------------------------------------------------------------------------
; Version 4.02
; Two optional arguments:  pitch, duration.
; We make them optional by not declaring them in the DEFPROC, then retrieving
; them with the arg() function.  We do this because DOS has no use for the
; arguments.  (The alternative would be to declare them --
; defproc beep(pitch, duration) -- and ignore them on DOS, but that would use
; more p-code space.)
;
; If the arguments are omitted on OS/2 we pick DOS-like values.
defproc beep
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

; ---------------------------------------------------------------------------
; jbl 12/30/88:  Provide DIR and other DOS-style query commands by redirecting
; output to a file.
defc dir
   parse arg Args
   Options = ''
   Mask    = ''
   call ParseOs2Options( Args, Options, Mask)
   next = NepmdQueryFullname( Mask)
   parse value next with 'ERROR:'rcx
   if rcx = '' then
      Mask = next
   endif

   DirArgs = strip( Options Mask)
   dos_command( 'dir' DirArgs)
   --'SayHint' ALT_1_LOAD__MSG
   'SayHint Use Alt+1 or double click to load a file or edit the "Directory of" line.'

; ---------------------------------------------------------------------------
; Parse Args into Options and Masks. Only OS/2 options are recognized. They
; start with a '/', are 1 char long and an optional arg is separated by a
; ':'. Space-separated option args are sorted into the Masks string. That
; also doesn't work when some options must appear before and some after the
; mask.
defproc ParseOs2Options( Args, var Options, var Masks)
   --defc TestP
   -- Args = '/a /b/c /d:string1 /e:"string2 with spaces" filename /f:"string3 with spaces" /g'
   -- Args = '/a /b/c /d:string1 /e:"string2 with spaces" "This is a filename" /f:"string3 with spaces" /g'
   -- dprintf( 'Args = 'Args)
   Options = ''
   Masks   = ''
   rest = Args
   do while rest <> ''
      rest = strip( rest)

      -- Find options
      if leftstr( rest, 1) = '/' then
         parse value rest with 2 ThisOption 3 rest
         Options = Options '/'ThisOption

         -- Find options with args
         ThisOptionArg = ''
         if leftstr( rest, 1) = ':' then
            parse value rest with 2 rest
            if leftstr( rest, 1) = '"' then
               parse value rest with '"'ThisOptionArg'"' rest
               ThisOptionArg = '"'ThisOptionArg'"'
            elseif leftstr( rest, 1) = ' ' then
               --nop
            else
               parse value rest with ThisOptionArg rest
            endif
         endif
         if ThisOptionArg <> '' then
            Options = Options':'ThisOptionArg
         endif

      -- Find masks
      else
         if leftstr( rest, 1) = '"' then
            parse value rest with '"'ThisMask'"' rest
            ThisMask = '"'ThisMask'"'
         else
            parse value rest with ThisMask rest
         endif
         Masks = Masks ThisMask
      endif

   enddo
   Options = strip( Options)
   Masks   = strip( Masks)
   --dprintf( 'Options = 'Options', Masks = 'Masks)
   return

; ---------------------------------------------------------------------------
; If cursor is on a "Directory of" line of a dir listing, read that dir spec
; and list that dir. That makes the "Director line" editable to change the
; the listed dir. Returns 0 on success, else 1.
defproc DirProcessDirOfLine
   rcx = 1
   do i = 1 to 1
      -- Find "Directory of" line
      fStart = 0
      fEnd   = 0
      DirOfLineNum = 0
      DirOfLine = ''
      Dirname = ''
      do l = 1 to min( 10, .last)
         getline ThisLine, l
         if ThisLine <> '' & fStart = 0 then
            fStart = 1
         elseif ThisLine = '' & fStart = 1 then
            DirOfLineNum = l - 1
            DirOfLine = strip( textline( DirOfLineNum))
            leave
         endif
      enddo

      -- Check if cursor is on this line
      if .line <> DirOfLineNum then
         leave
      endif

      -- Get the Dirname
      do i = 1 to 1
         if DirOfLine = '' then
            leave
         endif
         if rightstr( DirOfLine, 1) = ':' then
            p2 = length( DirOfLine)
         else
            p2 = pos( '\', DirOfLine)
         endif
         if p2 = 0 then
            leave
         endif
         next = leftstr( DirOfLine, p2 - 1)
         p1 = lastpos( ' ', next)
         if p1 = 0 then
            leave
         endif
         Dirname = substr( DirOfLine, p1 + 1)
         leave
      enddo

      -- Execute
      if Dirname <> '' then
         Dirname = strip( Dirname, 'B', '"')
         if verify( Dirname, ' ^&|', 'M') > 0 then
            Dirname = '"'Dirname'"'
         endif
         'dir' Dirname
         rcx = 0  -- success
      endif

   enddo
   return rcx

; ---------------------------------------------------------------------------
; Search a file spec in current dir recoursively and without dirs. List
; output to load a found file with ALT+1.
; Don't mix it up with the internally defined findfile procedure!
defc list, findfile, filefind
   fspec = arg(1)
   call parse_filename( fspec, .filename)
   'dir /b /s /a:-D' fspec
   if .last then
      --.filename = '.DIR 'spec  -- disabled, better use complete call as title
      if .last <= 2 & substr( textline(.last), 1, 8) = 'SYS0002:' then
         'xcom q'
         sayerror FILE_NOT_FOUND__MSG
      endif
   else
      'xcom q'
      sayerror FILE_NOT_FOUND__MSG
   endif

; ---------------------------------------------------------------------------
defc attrib
   parse arg fspec
   call parse_filename( fspec, .filename)
   if verify( fspec, '+-', 'M') then  -- Attempt to change attributes;
      'dos' fspec
      if rc then                     --   only give message if attempt fails.
         sayerror 'RC =' rc
      endif
   else                              -- Else, attempt to query attributes -
      dos_command('attrib' fspec)    --   user wants to see results.
   endif

; ---------------------------------------------------------------------------
defc set   = dos_command( 'set' arg(1))
defc vol   = dos_command( 'vol' arg(1))
defc path  = dos_command( 'path')
defc dpath = dos_command( 'dpath')

; ---------------------------------------------------------------------------
; Executes arg(1) by COMSPEC, redirects its output to a temp. file and loads
; it. If the current buffer stems also from a similar .DOS <cmd> output, it
; can be specified by setting the universal var ReuseCmdOutput = 1 to replace
; the current buffer instead of always creating a new one.
defproc dos_command
   universal vTEMP_FILENAME
   universal ring_enabled
   universal ReuseCmdOutput
   if not ring_enabled then
      'ring_toggle'
   endif

; Currently hard-coded. TODO: make that configurable ###############################
ReuseCmdOutput = 1

   fReuseFile = 0  -- default value, 0: create a new buffer
   getfileid curfid
   do i = 1 to 1
      -- Check universal var
      if ReuseCmdOutput <> 1 then
         leave
      endif

      -- Check current filename
      if word( .filename, 1) <> '.DOS' then
         leave
      endif
      CurCmd = strip( word( .filename, 2))
      NewCmd = strip( word( arg(1), 1))
      if upcase( CurCmd) <> upcase( NewCmd) then
         leave
      endif

      fReuseFile = 1
   enddo

   -- Used to always do:  arg(1) '>'
   -- but "set foo" is different than "set foo " (trailing space), so now we
   -- only insert the space if the argument ends with a number and so could
   -- be confused with redirection of a file handle.
   if pos( rightstr( arg(1), 1), '0123456789') then
      quietshell 'dos' arg(1) '>'vTEMP_FILENAME '2>&1'
   else
      quietshell 'dos' arg(1)'>'vTEMP_FILENAME '2>&1'
   endif

   'xcom e /D /Q' vTEMP_FILENAME

   if not rc then
      getfileid newfid
      Filename = '.DOS' arg(1)
      if fReuseFile then
         rc = ReplaceFileContent( curfid, newfid)
         if rc then
            return rc
         endif
         -- Quit temp file
         activatefile newfid
         .modify = 0
         'xcom q'
         -- Rename current file
         activatefile curfid
         .filename = Filename
      else
         .filename = Filename
         'postme monofont'
         --'mode shell'
      endif
   endif

   call erasetemp( vTEMP_FILENAME)

; ---------------------------------------------------------------------------
defproc ReplaceFileContent( fid1, fid2)
   call psave_mark(savemark)

   -- Delele all from fid1
   activatefile fid1
   if rc then
      return rc
   endif
   top
   markline
   bottom
   markline
   deletemark
   .modify = 0

   -- Copy all from fid2 to fid1
   activatefile fid2
   if rc then
      return rc
   endif
   top
   markline
   bottom
   markline
   activatefile fid1
   if rc then
      return rc
   endif
   copymark
   .modify = 0

   call prestore_mark(savemark)
   rc = 0
   return rc

; ---------------------------------------------------------------------------
; Create an OS/2 windowed cmd prompt & execute a command in it.
defc os2
   command = arg(1)
   if command = '' then    -- prompt user for command
      command = entrybox( ENTER_CMD__MSG)
      if command = '' then return; endif
   endif
   'start /win 'command
   if rc = 1 then
      sayerror sayerrortext(-274) command
   endif

; ---------------------------------------------------------------------------
defc del, erase
   earg = arg(1)
   if parse_filename( earg, .filename) then
      sayerror -263  --  'Invalid argument'
      return 1
   endif
   If verify( earg, '*?', 'M') then  -- Contains wildcards
      quietshell 'del' earg          -- must shell out
   else                              -- No wildcards?
      rc = erasetemp( earg)          -- erase via direct DOS call; less overhead.
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
      return
   else
      codepage_no = strip(ltoa( codepage, 10))
      return codepage_no
   endif

; ---------------------------------------------------------------------------
; Search file or dir in a path specification, pathes separated by ";".
; This can be used instead of findfile to avoid a search in the current dir.
; Example: FullExName = FindFileInList( 'fold.ex', Get_Env( 'EPMEXPATH'))
; Returns '' if File not found in PathList, otherwise fully qualified name.
defproc FindFileInList( File, PathList)
   FullName = ''
   rest = PathList
   do while rest <> ''
      parse value rest with Path';'rest
      if Path = '' then
         iterate
      endif
      Path = strip( Path, 'T', '\')
      next = Path'\'File
      if Exist( next) then  -- find files and dirs
         test = NepmdQueryFullname( next)
         parse value test with 'ERROR:'rcx
         if rcx > '' then
            iterate
         else
            FullName = test
            leave
         endif
      endif
   enddo
   return FullName

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

