/****************************** Module Header *******************************
*
* Module Name: tools.e
*
* Copyright (c) Netlabs EPM Distribution Project 2014
*
* $Id$
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

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
   include 'stdconst.e'
define INCLUDING_FILE = 'TOOLS.E'
const
   tryinclude 'MYCNF.E'

 compile if not defined(SITE_CONFIG)
const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
compile endif  -- not defined(SMALL)

; ---------------------------------------------------------------------------
const
compile if not defined( GREP_EXE)
   GREP_EXE = 'grep.exe'
compile endif
compile if not defined( GNU_GREP_OPTIONS)
   -- -E  extended grep
   -- -i  case insensitive
   -- -n  show line numbers
   -- -H  force print filename (path is missing, if file is located in current directory)
   GNU_GREP_OPTIONS = '-EinH'
compile endif
compile if not defined( RY_GREP_OPTIONS)
   -- /y  case insensitive
   -- /q  quiet, disable stderr
   -- /l  show line numbers
   RY_GREP_OPTIONS = '/y /q /l'
compile endif

; ---------------------------------------------------------------------------
; Determine version of grep.exe. Returns:
; 0   Ralph Yozzo's version of grep (can be found in CSTEPM package)
; 1   Gnu grep or any other version if Gnu grep version number n could not
;     be determined
; n   if Gnu grep version number n could be determined, something like 2.5a
; -1  error: file not found
defproc GetGrepVersion
   universal nepmd_hini
   fInit = upcase( arg(1)) = 'INIT'

   -- Get GrepVersion, Size, Time from ini
   KeyPath = '\NEPMD\User\GrepVersion'
   next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value next with LastGrepVersion \1 LastSize \1 LastTime \1

   -- Default values
   Size = ''
   Time = ''
   File = ''
   if (LastGrepVersion = 0 | LastGrepVersion > 1) then  -- old format only returned 0 or 1
      GrepVersion = LastGrepVersion
   else
      fInit = 1
      GrepVersion = ''
   endif

   do i = 1 to 1
      if not fInit then
         leave
      endif

      if substr( GREP_EXE, 2, 2) = ':\' | substr( GREP_EXE, 1, 2) = '\\' then
         File = GREP_EXE
         if Exist( File) then
            return -1  -- File not found
         endif
      else
         -- Find grep.exe in path
         findfile File, GREP_EXE, 'PATH', 'P'
         if File = '' then
            return -1  -- File not found
         endif
      endif

      -- Query size, time
      Size = NepmdQueryPathInfo( File, 'SIZE')
      if rc then
         return -1  -- File not found
      endif
      Time = NepmdQueryPathInfo( File, 'MTIME')  -- YYYY/MM/DD HH:MM:SS
      if rc then
         return -1  -- File not found
      endif
      --sayerror '1: 'fInit'-"'File'"-'LastGrepVersion'-'Size'-'Time

      -- Compare Size and Time
      if Size = LastSize & Time = LastTime then
         -- Force to rewrite the ini string if GrepVersion = 1, because the old
         -- format knew only 0 or 1
         if LastGrepVersion <> 1 & isnum( leftstr( LastGrepVersion, 1)) then
            leave
         endif
      endif

      -- Different. Determine GnuFlag
      TmpFile = Get_Env( 'TMP')'\gnu-ver.out'
      Cmd = GREP_EXE' -V'
      RyString = "unrecognized option: '-V'"
      quietshell Cmd arg(2) '>'TmpFile '2>&1'
      -- [H:\CSTEPM]grep -V           -- Ralph Yozzo's grep of CSTEPM
      -- unrecognized option: '-V'
      --
      -- [F:\bin]grep -V              -- Gnu grep
      -- grep (GNU grep) 2.5a
      -- grep.exe (GNU grep) 2.10
      --
      -- Copyright 1988, 1992-1999, 2000 Free Software Foundation, Inc.
      -- This is free software; see the source for copying conditions. There is NO
      -- warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
      'xcom edit' TmpFile
      e_rc = rc
      if e_rc then    -- Unexpected error.
         sayerror ERROR_LOADING__MSG TmpFile
         if e_rc = -282 then 'xcom quit'; endif  -- sayerror('New file')
         sayerror 'GetGrepVersion: rc from xcom edit = 'e_rc
         rc = e_rc
         leave
      endif
      line = textline(1)
      if line = RyString then
         GrepVersion = 0
      else
         parse value strip( lowcase( line)) with next rest
         rest = strip( rest)
         if leftstr( rest, 1) = '(' then
            parse value rest with '(' next ')' rest
         endif
         GrepVersion = word( rest, 1)
         if GrepVersion = '' then
            GrepVersion = 1
         endif
      endif
      'xcom quit'
      call EraseTemp( TmpFile)
      -- Write GrepVersion, Size, Time to ini
      KeyValue = GrepVersion\1''Size\1''Time\1
      NepmdWriteConfigValue( nepmd_hini, KeyPath, KeyValue)
      --sayerror '2: 'fInit'-"'File'"-'GrepVersion'-'Size'-'Time
   enddo
   --sayerror fInit'-'GrepVersion
   return GrepVersion

; ---------------------------------------------------------------------------
; From EPMSMP\GREP.E
; Call an external GREP utility and display the results in an EPM file.
; The modified Alt+1 definition in ALT_1.E will let you place the
; cursor on a line in the results file and press Alt+1 to load the
; corresponding source file.
;
; Syntax: grep [grepoptions] pattern filemask
;
; If no grepoptions where specified, the defaultgrepopt are submitted to grep.
; Works with Gnu grep or Ralph Yozzo's grep (contained e.g. in CSTEPM).
defc Grep
   GrepVersion = GetGrepVersion( 'INIT')
   if GrepVersion = -1 then
      sayerror 'Error: 'GREP_EXE' not found in PATH.'
      rc = 2
   else
      rc = CallGrep( GrepVersion, arg(1))
   endif
;   sayerror 'rc from defc Grep = 'rc

; ---------------------------------------------------------------------------
; For use as menu item.
defc GrepDlg
   next = arg(1)
   if next > '' then
      GrepVersion = next
   else
      GrepVersion = GetGrepVersion( 'INIT')
      if GrepVersion = -1 then
         sayerror 'Error: 'GREP_EXE' not found in PATH.'
         return 2
      endif
   endif
   -- Options:
   if GrepVersion > 0 then
      DefaultGrepOpt = GNU_GREP_OPTIONS
   else
      DefaultGrepOpt = RY_GREP_OPTIONS
   endif
   Title = 'Scan for text in files'
   Text  = 'Enter string (in quotes if it contains spaces) and file spec:'
   DefaultValue  = DefaultGrepOpt' '
   DefaultButton = 1

   parse value entrybox( Title,
                         '/~OK/Cancel/Grep ~Help',  -- max. 4 buttons
                         DefaultValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 then
      rc = CallGrep( GrepVersion, NewValue)
      return 2
   elseif Button = \2 then
      return
   elseif Button = \3 then
      -- Show help
      if GrepVersion > 0 then
         GrepArgs = '--help'
      else
         GrepArgs = ''
      endif
      --call CallGrep( GrepVersion, GrepArgs)  -- opens too late
      "Open 'Grep "GrepArgs"'"  -- use an extra window to show Grep's help
      'postme GrepDlg' GrepVersion
   endif

; ---------------------------------------------------------------------------
; Syntax: callgrep( GrepVersion[, GrepArgs[, fVerbose]])
; If GrepArgs doesnot contain options, the default options, either
; GNU_GREP_OPTIONS or RY_GREP_OPTIONS, depending on GrepVersion are prepended
; to GrepArgs.
defproc CallGrep
   universal vepm_pointer

   GrepVersion = arg(1)
   if arg(3) = '' then
      fVerbose = 1
   else
      fVerbose = (arg(3) = 1)
   endif

   -- Options:
   if GrepVersion > 0 then
      defaultgrepopt = GNU_GREP_OPTIONS
   else
      defaultgrepopt = RY_GREP_OPTIONS
   endif
   --display -8

   grepargs = arg(2)
   -- Parse options, if user specified any
   grepopt  = ''
   if GrepVersion > 0 then
      optdelim = '-'
   else
      optdelim = '-/'
   endif
   do i = 1 to words( grepargs)
      next = word( grepargs, i)
      --if substr( next, 1, 1) = '-' then
      if verify( substr( next, 1, 1), optdelim, 'M') then
         grepopt = grepopt' 'next
      endif
   enddo
   grepopt = strip(grepopt)
   -- Prepend default options, if user specified none
   if grepopt = '' then
      grepargs = defaultgrepopt grepargs
   endif

   mouse_setpointer WAIT_POINTER
   if words( grepargs) > 1 then
      if fVerbose then
         sayerror 'Scanning files...'
      endif
   elseif GrepVersion > 0 then
      -- Show Gnu help
      grepargs = '--help'
   else
      -- Show RY help
      grepargs = ''
   endif

   greprc = redirect_grep( GrepVersion, GREP_EXE, grepargs, directory())
   if words( grepargs) < 2 then
      sayerror 'Syntax: grep [options] pattern filemask  (default options = 'defaultgrepopt')'
   elseif greprc <> 0 then

   elseif fVerbose then
      'SayHint' ALT_1_LOAD__MSG
   endif
   mouse_setpointer vepm_pointer
   rc = greprc
   return rc
   --display 8

; ---------------------------------------------------------------------------
; Added directory line in Gnu grep's output for ALt_1.
defproc redirect_grep( GrepVersion, Cmd)
   universal vTEMP_PATH
   outfile = vTEMP_PATH'grep____.out'

   quietshell Cmd arg(3) '>'outfile '2>&1'
   cmdrc = rc
   -- sets rc >= 1 on application error, rc < 0 on E error, otherwise rc = 0

   if cmdrc = sayerror( 'Insufficient memory') or
      cmdrc = sayerror( 'File Not found') then
      stop
   endif

   CurDir = arg(4)
   if arg(4) = '' then
      CurDir = directory()
   endif

   'edit' outfile
   if rc = -282 then
      'xcom quit'  -- sayerror('New file')
   endif
   if rc <> 0 then
      return rc
   endif

   rc = cmdrc
   .autosave = 0
   .filename = '.Output from grep' arg(3)

   if .last > 0 then
      next = textline(1)
   else
      next = ''
   endif
   if leftstr( next, 3) = 'SYS' then
      -- Check for DLL not found errors
      -- SYS1804: Datei REGEX kann nicht gefunden werden.
      parse value next with 'SYS'rc':' .
      sayerror next
   endif

   -- If current path is searched only, Gnu grep won't output the files' pathes.
   -- Additionally, the string "Current directory = " works now as markup for
   -- the following Alt+1 command to determine the grep version easily.
   if GrepVersion > 0 then
      insertline 'Current directory = 'CurDir, 1
   endif

   .modify = 0
   call erasetemp( outfile)
   return rc

; ---------------------------------------------------------------------------
; Search all NEPMD E macros for a string
; input:  a string to search for
; output: a grep window showing all matches suitable for use with ALT+1
defc MacGrep
   RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
   UserDir = NepmdScanEnv( 'NEPMD_USERDIR')
   FileMask = UserDir'\macros\*.e' RootDir'\netlabs\macros\*.e'
   'grep' GNU_GREP_OPTIONS arg(1) FileMask
   if rc <> 0 then
      sayerror 'rc from grep = 'rc
   else
      'SayHint' ALT_1_LOAD__MSG
   endif

; ---------------------------------------------------------------------------
; Support for Graphical File Comparison
; Compares current file with another. File open dialog of GFC will open.
; If current file is located in any tree of %NEPMD_ROOTDIR%\netlabs or
; %NEPMD_USERDIR%, then the current file is compared with the
; corresponding file of the other tree.
defc GfcCurrentFile
   fn = .filename
   Params = '"'fn'"'

   RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
   rc1 = rc
   if rc then
      sayerror 'Environment var NEPMD_ROOTDIR not set.'
   endif
   NetlabsDir = RootDir'\netlabs'

   UserDir = NepmdScanEnv( 'NEPMD_USERDIR')
   rc2 = rc
   if rc then
      sayerror 'Environment var NEPMD_USERPATH not set.'
   endif

   NetlabsDir = strip( NetlabsDir, 't', '\')
   UserDir    = strip( UserDir   , 't', '\')
   if not rc1 & not rc2 then
      if abbrev( upcase(fn), upcase( NetlabsDir)'\') then
         rest = substr( fn, length( NetlabsDir) + 1)  -- including leading \
         fn2 = UserDir''rest
         if NepmdFileExists( fn2) then
            Params = Params' "'fn2'"'
         endif
      elseif abbrev( upcase( fn), upcase( UserDir)'\') then
         rest = substr( fn, length( UserDir) + 1)  -- including leading \
         fn2 = NetlabsDir''rest
         if NepmdFileExists( fn2) then
            Params = Params' "'fn2'"'
         endif
      endif
   endif

   'start /f gfc' Params

; ---------------------------------------------------------------------------
; Support for KDiff3
; Compares current file with another. File open dialog of kDiff3 will open.
; If current file is located in any tree of %NEPMD_ROOTDIR%\netlabs or
; %NEPMD_USERDIR%, then the current file is compared with the
; corresponding file of the other tree.
defc KDiff3CurrentFile
   fn = .filename
   Params = '"'fn'"'

   RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
   rc1 = rc
   if rc then
      sayerror 'Environment var NEPMD_ROOTDIR not set.'
   endif
   NetlabsDir = RootDir'\netlabs'

   UserDir = NepmdScanEnv( 'NEPMD_USERDIR')
   rc2 = rc
   if rc then
      sayerror 'Environment var NEPMD_USERPATH not set.'
   endif

   NetlabsDir = strip( NetlabsDir, 't', '\')
   UserDir    = strip( UserDir   , 't', '\')
   if not rc2 then
      if abbrev( upcase( fn), upcase( NetlabsDir)'\') then
         rest = substr( fn, length( NetlabsDir) + 1)  -- including leading \
         fn2 = UserDir''rest
         if NepmdFileExists( fn2) then
            Params = Params' "'fn2'"'
         endif
      elseif abbrev( upcase( fn), upcase( UserDir)'\') then
         rest = substr( fn, length( UserDir) + 1)  -- including leading \
         fn2 = NetlabsDir''rest
         if NepmdFileExists( fn2) then
            Params = Params' "'fn2'"'
         endif
      endif
   endif

   'start /pm kdiff3.exe' Params

; ---------------------------------------------------------------------------
defc StartBrowser
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Url\Browser"
   BrowserExecutable = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   UrlStrings = 'http:// ftp:// www. ftp. https:// mailto:'
   arg1 = arg(1)
   Url = ''
   browser_rc = 1  -- default rc; 1: browser not started or no Url

   if arg1 <> '' then  -- if Url submitted as arg(1)
      Url = strip( arg1, 'B', '"')
   else  -- if no Url submitted as arg(1) then take word under pointer

      -- Go to mouse position to ensure getting URL at mouse pointer and not at cursor
      call psave_pos(saved_pos)
      call psave_mark(saved_mark)
      'MH_gotoposition'

      -- Get word under cursor, separated by any char of SeparatorList
      StartCol = 0
      EndCol   = 0
      SeparatorList = '"'||"'"||'(){}[]<>,! '\9;
      call find_token( StartCol, EndCol, SeparatorList, '')
      getline line

      call prestore_pos(saved_pos)
      call prestore_mark(saved_mark)

      WordFound = (StartCol <> 0 & EndCol >= StartCol)
      if WordFound then  -- if word found
         Spec = substr( line, StartCol, EndCol - StartCol + 1)

         -- Strip trailing punctuation chars and '-'
         if wordpos( rightstr( Spec, 1), ', ; . ! ? -') then
            Spec = substr( Spec, 1, length(Spec) - 1)
         endif

         -- Locate URL in double-clicked word
         do u = 1 to words( UrlStrings)
            UrlString = word( UrlStrings, u)
            p1 = pos( UrlString, Spec)
            if p1 > 0 then

               -- get URL
               Url = substr( Spec, p1)

               -- add default protocol identifier
               if (pos( ':', Url) = 0) then
                  if substr( Url, 1, 4) = 'ftp.' then
                     Url = 'ftp://'Url
                  else
                     Url = 'http://'Url
                  endif
               endif

               leave
            endif
         enddo
/*
         -- If no URL found, automatically process special URLs
         if Url = '' then
            filename = .filename
            p1 = lastpos( '\', filename)
            fname = substr( filename, p1 + 1)
            if translate( leftstr( fname, 6)) = 'FILES.' then
               Url = 'ftp://ftp.dante.de/tex-archive/'Spec
               p2 = lastpos( '/', Url)
               Parent = substr( Url, 1, p2)
               Url = Parent
            endif
            if translate( leftstr( Spec, 6)) = 'DANTE:' or
               translate( leftstr( Spec, 5)) = 'CTAN:' then
               Url = substr( Spec, 7)  -- <--- ToDo
               Url = strip( Url, 'L')
               Url = strip( Url, 'L', '/')
               Url = 'ftp://ftp.dante.de/tex-archive/'Url
               p2 = lastpos( '/', Url)
               Parent = substr( Url, 1, p2)
               Url = Parent
            endif
         endif  -- Url = ''
*/
      endif  -- WordFound
   endif  -- arg1 <> ''

   -- If URL found until here, process it
   if Url <> '' then
      -- select default browser or use netscape as default
      if upcase(BrowserExecutable) = 'DEFAULT' then
         BrowserExecutable = queryprofile( HINI_USERPROFILE, 'WPURLDEFAULTSETTINGS', 'DefaultBrowserExe')
         NamePos           = lastpos( '\', BrowserExecutable) + 1
         ExtPos            = pos( '.', BrowserExecutable, NamePos)
         PathPos           = pos( '\', BrowserExecutable)

         BrowserName       = substr( BrowserExecutable, NamePos, ExtPos - NamePos)
         BrowserPath       = substr( BrowserExecutable, 1, NamePos - 2)

      elseif BrowserExecutable = '' then
         BrowserExecutable = 'firefox'
         BrowserName       = 'Firefox'
         BrowserPath       = ''
      endif

      -- Save current directory and change drive and directory
      if BrowserPath <> '' then
         CurrentDirectory  = directory()
         cdd( BrowserPath)
      endif

      --'os2 /min /c start /f' BrowserExecutable' "'Url'"'
      CmdPre  = 'start /f' BrowserExecutable' "'
      CmdPost = '"'
      CmdLen = length( CmdPre) + length( CmdPost)

      -- Truncate URL if too long to avoid EPM crashing.
      -- Max. length for a command executed by cmd.exe is 300.
      MaxLen = 239 - CmdLen  -- why 239?
      IsTruncated = 0
      if length( Url) > MaxLen then
         Url = leftstr( Url, MaxLen)
         IsTruncated = 1
         -- Try to truncate before a % char, otherwise the URL gets unvalid sometimes,
         -- but only in the last 20 chars
         lp = lastpos( '%', Url)
         if lp > MaxLen - 20 then
            Url = leftstr( Url, lp - 1)
         endif
      endif

      if IsTruncated then
         sayerror 'Invoking' BrowserName 'with (truncated):' Url
      else
         sayerror 'Invoking' BrowserName 'with:' Url
      endif

      -- Execute the command and set rc
      CmdPre''Url''CmdPost
      browser_rc = rc

      -- Teststrings here:
      -- http://www.os2.org
      -- ftp://ftp.netlabs.org,www.netlabs.org,ftp://ftp.os2.org
      -- (ftp://ftp.netlabs.org)
      -- ####ftp://ftp.netlabs.org)###)
      -- ftp://ftp.netlabs.org
      -- www.netlabs.org
      -- mailto:C.Langanke@Teamos2.de
      -- <head><title>Index of ftp://ftp.netlabs.org/</title><base href="ftp://ftp.netlabs.org/"/>
         -- Next works, but won't find anything:
      -- http://groups.google.com/groups?num=20&hl=en&scoring=d&as_drrb=b&q=epm+group%3Ade.comp.os.*+OR+group%3Acomp.os.*&btnG=Google-Suche&as_miny=2001&as_minm=1&as_mind=1
         -- Next is much too long and also doesn't work any more:
      -- http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&threadm=4ebg22%24jod%40watnews2.watson.ibm.com&rnum=3&prev=/groups%3Fq%3Dautosave%2Bgroup:comp.os.os2.apps%26hl%3Dde%26lr%3D%26ie%3DUTF-8%26group%3Dcomp.os.os2.apps%26selm%3D4ebg22%2524jod%2540watnews2.watson.ibm.com%26rnum%3D3

      -- Restore current drive and directory
      if Browserpath <> '' then
         cdd( CurrentDirectory)
      endif
   endif  -- Url <> ''
   rc = browser_rc

; ---------------------------------------------------------------------------
const
compile if not defined( VALIDATE_HTML_UPLOAD)
   VALIDATE_HTML_UPLOAD='http://validator.w3.org/#validate_by_upload+with_options'
compile endif
;compile if not defined( VALIDATE_HTML_CHECK)
;   -- file uris aren't accepted:
;   VALIDATE_HTML_CHECK='http://validator.w3.org/check?uri=file:///'
;compile endif
compile if not defined( VALIDATE_CSS_UPLOAD)
   VALIDATE_CSS_UPLOAD='http://jigsaw.w3.org/css-validator/#validate_by_upload+with_options'
compile endif

; ---------------------------------------------------------------------------
defc ValidateHtml
   'CheckModify'
   'StartBrowser' VALIDATE_HTML_UPLOAD
;   'StartBrowser' VALIDATE_HTML_CHECK''translate( .filename, '/', '\')

; ---------------------------------------------------------------------------
defc ValidateCss
   'CheckModify'
   'StartBrowser' VALIDATE_CSS_UPLOAD

; ---------------------------------------------------------------------------
; Call recode and revert current file
defc Recode
   parse arg args
   if .modify then
      if WinMessageBox( 'Recode and reload file from disk',
                        .filename' was modified.'\13 ||
                        'Throw away changes to file on disk?',
                        MB_OKCANCEL + MB_WARNING + MB_DEFBUTTON1 + MB_MOVEABLE) <> MBID_OK then
         return -293  -- sayerror("has been modified")
      else
         .modify = 0
         'unlock'
      endif
   endif
   if args = '' then
      'commandline recode latin1:cp850'  -- recursive call
      return
   endif
   if pos ( ' ', .filename) then
      filename = '"'.filename'"'
   else
      filename = .filename
   endif
   --'commandline dos recode' args .filename
   --'os2 recode' args .filename
   --    'commandline' returns only its own rc!
   --    'os2' returns only its own rc and doesn't run minimized!
   --    Only 'dos' returns the app's rc and runs minimized.
   'dos recode' args filename
   if rc = 0 then
      'revert'
   elseif rc = -274 then
      sayerror 'Error, rc = 'rc' (probably Gnu recode not found in PATH)'
   else
      sayerror 'Error from recode: rc = 'rc
   endif

; ---------------------------------------------------------------------------
; Compare 2 files using MD5.EXE or MD5SUM.EXE. Returns:
;  0 if equal
;  1 if different
; -1 on error
defproc Md5Comp( File1, File2)
   Md5Exe = arg( 3)
   ret = -1
   lp = lastpos( '.', File1)
   if lp > 1 then
      FullBaseName1 = substr( File1, 1, lp - 1)
   else
      FullBaseName1 = File1
   endif
   lp = lastpos( '.', File2)
   if lp > 1 then
      FullBaseName2 = substr( File2, 1, lp - 1)
   else
      FullBaseName2 = File2
   endif
   Md5Log1 = FullBaseName1'.md5'
   --Md5Log2 = FullBaseName2'.md5'
   Md5Log2 = FullBaseName1'.mdo'
   if Md5Exe = '' then
      findfile next, 'md5.exe', 'PATH'
      if rc then
         findfile next, 'md5sum.exe', 'PATH'
      endif
      if rc then
         sayerror 'Error: MD5.EXE or MD5SUM.EXE not found in PATH'
      else
         Md5Exe = next
      endif
   endif
   quietshell Md5Exe File1 '1>'Md5Log1
   if not rc then
      quietshell Md5Exe File2 '1>'Md5Log2
   endif
   if not rc then
      'xcom e 'Md5Log1
      next = textline(1)
      parse value next with '=' md51   -- Bob Eager's md5.exe
      if md51 = '' then
         parse value next with md51 .  -- Gnu md5.exe
      endif
      md51 = strip( md51, 'L', '\')    -- Gnu md5sum.exe
      --dprintf( '', '1: ('Md5Log1') 'md51)
      'xcom q'
      'xcom e 'Md5Log2
      next = textline(1)
      parse value next with '=' md52   -- Bob Eager's md5.exe
      if md52 = '' then
         parse value next with md52 .  -- Gnu md5.exe
      endif
      md52 = strip( md52, 'L', '\')    -- Gnu md5sum.exe
      --dprintf( '', '2: ('Md5Log2') 'md52)
      'xcom q'
      call EraseTemp( Md5Log1)
      call EraseTemp( Md5Log2)
      if md51 > '' & md52 > '' then
         if md51 <> md52 then
            ret = 1
         else
            ret = 0
         endif
      endif
   endif
   return ret

