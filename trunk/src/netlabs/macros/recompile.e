/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: recompile.e,v 1.3 2006-03-30 11:34:30 aschn Exp $
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

compile if not defined(SMALL)  -- If being externally compiled...
   include 'STDCONST.E'
define INCLUDING_FILE = 'RECOMPILE.E'
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
 -- Set main file for the ET compilation command
 compile if not defined(MAINFILE)
   MAINFILE= 'epm.e'
 compile endif

   EA_comment 'Linkable commands for macro compilation'

compile endif

; ---------------------------------------------------------------------------
; Syntax: relink [IFLINKED] [[<path>]<modulename>[.e]]
;
; Compiles the module, unlinks it and links it again.  A fast way to
; recompile/reload a macro under development without leaving the editor.
; Note that the unlink is necessary in case the module is already linked,
; else the link will merely reinitialize the previous version.
;
; standard: link module, even if it was not linked before
; IFLINKED: link module only, if it was linked before
;
; If modulename is omitted, the current filename is assumed.
; New: Path and extension for modulename are not required.
defc relink
   args = arg(1)
   wp = wordpos( 'IFLINKED', upcase( args))
   fIfLinked = (wp > 0)
   if wp then
      args = delword( args, wp, 1)  -- remove 'IFLINKED' from args
   endif
   modulename = args  -- new: path and ext optional
   if modulename = '' then                           -- If no name given,
      p = lastpos( '.', .filename)
      if upcase( substr( .filename, p)) <> '.E' then
         sayerror '"'.filename'" is not an .E file'
         return
      endif
      modulename = substr( .filename, 1, p - 1)    -- use current file.
      if .modify then
         's'                                       -- Save it if changed.
         if rc then return; endif
      endif
   endif

   -- Check if basename of module was linked before
   lp1 = lastpos( '\', modulename)
   name = substr( modulename, lp1 + 1)
   lp2 = lastpos( '.', name)
   if lp2 > 1 then
      basename = substr( name, 1, lp2 - 1)
   else
      basename = name
   endif
   linkedrc = linked(basename)

   'etpm' modulename  -- This is the macro ETPM command.
   if rc then return; endif

   -- Unlink and link module if linked
   if linkedrc >= 0 then  -- if linked
      'unlink' basename   -- 'unlink' gets full pathname now
      if rc < 0 then
         return
      endif
   endif
   if linkedrc >= 0 | fIfLinked = 0 then
      'link' basename
      -- Refresh menu if module is linked and defines a menu
      if rc >= 0 & upcase( rightstr( basename, 4)) = 'MENU' &
         length( basename) > 4 then
         'ChangeMenu' basename
      endif
   endif

; ---------------------------------------------------------------------------
; Syntax: etpm [[<path>]<e_file> [[<path>]<ex_file>]
;
; etpm         compiles EPM.E to EPM.EX in <UserDir>\ex
; etpm tree.e  compiles TREE.E to TREE.EX in <UserDir>\ex
; etpm tree    compiles TREE.E to TREE.EX in <UserDir>\ex
; etpm =       compiles current file to an .ex file in <UserDir>\ex
; etpm = =     compiles current file to an .ex file in the same dir
;
; Does use the /v option now.
; Doesn't respect options from the commandline, like /v or /e <logfile>.
defc et,etpm=
;   universal vTEMP_PATH
   --universal vTEMP_FILENAME

   rest = strip( arg(1))
   if leftstr( rest, 1) = '"' then
      parse value rest with '"'InFile'"' rest
   else
      parse value rest with InFile rest
   endif
   if leftstr( rest, 1) = '"' then
      parse value rest with '"'ExFile'"' .
   else
      parse value rest with ExFile .
   endif
   if InFile = '' then
      InFile = MAINFILE
   elseif pos( '=', InFile) > 0 then
      call parse_filename( InFile, .filename)
   endif
   if pos( '=', ExFile) > 0 then
      call parse_filename( ExFile, .filename)
      lp = lastpos( '.', ExFile)
      if lp > 0 then
         if translate( substr( ExFile, lp + 1)) = 'E' then
            ExFile = substr( ExFile, 1, lp - 1)'.ex'
         else
            ExFile = ExFile'.ex'
         endif
      endif
   endif

   lp1 = lastpos( '\', InFile)
   Name = substr( InFile, lp1 + 1)
   lp2 = lastpos( '.', Name)
   if lp2 > 1 then
      BaseName = substr( Name, 1, lp2 - 1)
   else
      BaseName = Name
   endif
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   AutolinkDir  = NepmdUserDir'\autolink'  -- search in <UserDir>\autolink first
   ProjectDir   = NepmdUserDir'\project'   -- search in <UserDir>\project second
   if exist( AutolinkDir'\'BaseName'.ex') then
      DestDir = AutolinkDir
   elseif exist( ProjectDir'\'BaseName'.ex') then
      DestDir = ProjectDir
   else
      DestDir = NepmdUserDir'\ex'
   endif
   If ExFile = '' then
      ExFile = DestDir'\'BaseName'.ex'
   endif

;   TempFile = vTEMP_PATH'ETPM'substr( ltoa( gethwnd(EPMINFO_EDITCLIENT), 16), 1, 4)'.TMP'
   TempFile = DestDir'\'BaseName'.log'

   Params = '/v 'InFile ExFile' /e 'TempFile

 compile if defined(ETPM_CMD)  -- let user specify fully-qualified name
   EtpmCmd = ETPM_CMD
 compile else
   EtpmCmd = 'etpm'
 compile endif

;   CurDir = directory()
;   call directory('\')
;   call directory(DestDir)  -- change to DestDir first to avoid loading macro files from CurDir

   sayerror COMPILING__MSG infile
   quietshell 'xcom' EtpmCmd Params

;   call directory('\')
;   call directory(CurDir)
   if rc = -2 then
      sayerror CANT_FIND_PROG__MSG EtpmCmd
      stop
   endif
   if rc = 41 then
      sayerror 'ETPM.EXE' CANT_OPEN_TEMP__MSG '"'TempFile'"'
      stop
   endif
   if rc then
      saverc = rc
      call ec_position_on_error(TempFile)
      rc = saverc
   else
      refresh
      sayerror COMP_COMPLETED__MSG
   endif
;   call erasetemp(TempFile) -- 4.11:  added to erase the temp file.

; ---------------------------------------------------------------------------
; Load file containing error, called by etpm.
; This handles the /v output of etpm as well.
defproc ec_position_on_error(tempfile)
   'xcom e 'tempfile
   if rc then    -- Unexpected error.
      sayerror ERROR_LOADING__MSG tempfile
      if rc = -282 then 'xcom q'; endif  -- sayerror('New file')
      return
   endif
   msgl = 4
   do l = 4 to .last
      next = textline(l)
      if substr( next, 1, 10) = 'compiling ' then
         -- ignore
      else
         msg = next
         msgl = l
         leave
      endif
   enddo
   if msgl < .last then
      parse value textline( .last) with 'col= ' col
      parse value textline( .last - 1) with 'line= ' line
      parse value textline( .last - 2) with 'filename=' filename
      'xcom q'
      'e 'filename               -- not xcom here, respect user's window style
      if line <> '' and col <> '' then
         .cursory = min( .windowheight%2, .last)
         if col > 0 then
            'postme goto' line col
         else
            line = line - 1
            col = length( textline(line))
            'postme goto' line col
         endif
      endif
   endif
   sayerror msg

; ---------------------------------------------------------------------------
; Check for a modified file in ring. If not, compile EPM.E, position cursor
; on errorline or restart on success. Quite fast!
; Will only restart topmost EPM window.
; Because of defc Etpm is used, EPM.EX is created in <UserDir>\ex.
; Because of defc Restart is used, current directory will be kept.
defc RecompileEpm
   'RingCheckModify'
   'Etpm epm'
   if rc = 0 then
      'Restart'
   endif

; ---------------------------------------------------------------------------
; Check for a modified file in ring. If not, restart current EPM window.
; Keep current directory.
defc Restart
   if arg(1) = '' then
      cmd = 'RestoreRing'
   else
      cmd = 'mc ;Restorering;postme 'arg(1)
   endif
   'RingCheckModify'
   'SaveRing'
   EpmArgs = "'"cmd"'"
compile if 0
   -- Doesn't work really reliable everytime (but even though useful):
   -- o  Sometimes EPM.EX is not reloaded.
   -- o  Sometimes EPM crashes on 'SaveRing' or on executing arg(1).
   'postme Open' EpmArgs
compile else
   -- Using external .cmd now:
   EpmExe = Get_Env( 'NEPMD_LOADEREXECUTABLE')
   'postme start /c /min epmlast' EpmExe EpmArgs
   'postme Close'
compile endif

; ---------------------------------------------------------------------------
; When a non-temporary file (except .Untitled) in ring is modified, then
; -  make this file topmost
; -  give a message
; -  set rc = 1 (but not required, because stop is used)
; -  stop processing of calling command or procedure.
; Otherwise set rc = 0.
defc RingCheckModify
   rc = 0
   getfileid fid
   startfid = fid
   do i = 1 to filesinring()  -- omit hidden files
      if (substr( .filename, 1, 1) = '.') & (.filename <> GetUnnamedFilename()) then
         .modify = 0
      else
         'CheckModify'
      endif
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo

; ---------------------------------------------------------------------------
defc CheckModify
   parse arg
   if .modify then
      rc = 1
      -- let this file on top
      sayerror 'Current file is modified. Save it or discard changes first.'
      stop  -- Stops further processing of current and calling command or
            -- procedure. Advantage: no check for rc required.
   endif

; ---------------------------------------------------------------------------
; Recompile all files, whose names found in .lst files in EPMEXPATH.
;
; Maybe to be changed: compile only those files, whose (.EX files exist) names
; are listed in ex\*.lst and whose E files found in <UserDir>\macros.
; Define a new command RecompileReallyAll to replace the current RecompileAll.
;
; Maybe another command: RecompileNew, checks filestamps and compiles
; everything, for that the E source files have changed.
defc RecompileAll

   'RingCheckModify'

   Path = NepmdScanEnv('EPMEXPATH')
   parse value Path with 'ERROR'rc
   if (rc > '') then
      return
   endif

   ListFiles = ''
   rest = Path
   do while rest <> ''
      parse value rest with next';'rest
      -- Search in every piece of Path for .lst files
      FileMask = next'\*.lst'
      Handle = 0
      do forever
         ListFile = NepmdGetNextFile( FileMask, address(Handle))
         parse value ListFile with 'ERROR:'rc
         if (rc > '') then
            leave
         -- Append if not already in list
         elseif pos( upcase(ListFile)';', upcase(ListFiles)';') = 0 then
            ListFiles = ListFiles''ListFile';'
         endif
      enddo
   enddo

   ExFiles = ''
   rest = ListFiles
   do while rest <> ''
      parse value rest with ListFile';'rest
      -- Load ListFile
      'xcom e /d' ListFile
      if rc <> 0 then
         iterate
      endif
      getfileid fid
      .visible = 0
      -- Read lines
      do l = 1 to .last
         Line = textline(l)
         StrippedLine = strip(Line)

         -- Ignore comments, lines starting with ';' at column 1 are comments
         if substr( Line, 1, 1) = ';' then
            iterate
         -- Ignore empty lines
         elseif StrippedLine = '' then
            iterate
         endif

         ExFile = StrippedLine
         -- Strip extension
         if rightstr( upcase(ExFile), 3) = '.EX' then
            ExFile = substr( ExFile, 1, length(ExFile) - 3)
         endif
         -- Ignore epm (this time)
         if upcase(ExFile) = 'EPM' then
            -- nop
         -- Append ExFile to list
         elseif pos( upcase(ExFile)';', upcase(ExFiles)';') = 0 then
            ExFiles = ExFiles''ExFile';'
         endif
      enddo  -- l
      -- Quit ListFile
      activatefile fid
      .modify = 0
      'xcom q'
   enddo

   rest = ExFiles
   do while rest <> ''
      parse value rest with ExFile';'rest
      -- Compile ExFile and position cursor on errorline
      'etpm' ExFile
      -- Return if error
      if rc <> 0 then
         return
      endif
   enddo

   -- Compile epm and restart (if no error)
   'RecompileEpm'

; ---------------------------------------------------------------------------
; Walk through all files in .LST files (like RecompileAll). Recompile all
; files, whose E sources are newer than their EX files.
; Could be a problem: the ini entry for epm\EFileTimes has currently 1341
; byte. Apparently in ETK every string is limited to 1599 byte.
; Syntax: RecompileNew [RESET] | [CHECKONLY] [NOMSG] [NOMSGBOX]
defc RecompileNew
   universal nepmd_hini

   -- Following E files are tryincluded. When the user has added one of these
   -- since last check, that one is not listed in
   -- \NEPMD\User\ExFiles\<basename>\EFiles. Therefore it has to be checked
   -- additionally.
   -- Optional E files for every E file listed in a .LST file:
   OptEFiles    = 'mycnf.e;'SITE_CONFIG';'
   -- Optional E files tryincluded in EPM.E only:
   OptEpmEFiles =  'mymain.e;myload.e;myselect.e;mykeys.e;mystuff.e;mykeyset.e;'

   -- Determine CheckOnly or Reset mode: disable file operations then
   fCheckOnly = (wordpos( 'CHECKONLY', upcase( arg(1))) > 0)
   fReset     = (wordpos( 'RESET'    , upcase( arg(1))) > 0)
   fNoMsgBox  = (wordpos( 'NOMSGBOX' , upcase( arg(1))) > 0)
   fNoMsg     = (wordpos( 'NOMSG'    , upcase( arg(1))) > 0)
   if fNoMsgBox = 0 & fReset = 0 then
      fNoMsg = 1  -- no output on the MsgLine, if MsgBox will pop up
   endif

   parse value DateTime() with Date Time

   if not fCheckOnly & not fReset then
      'RingCheckModify'
   endif

   Path = NepmdScanEnv('EPMEXPATH')
   parse value Path with 'ERROR:'rc
   if (rc > '') then
      return rc
   endif

   ListFiles = ''
   rest = Path
   do while rest <> ''
      parse value rest with next';'rest
      -- Search in every piece of Path for .lst files
      FileMask = next'\*.lst'
      Handle = 0
      do forever
         ListFile = NepmdGetNextFile( FileMask, address( Handle))
         parse value ListFile with 'ERROR:'rc
         if (rc > '') then
            leave
         -- Append if not already in list
         else
            -- Ignore if filename (without path) exists in list
            lp = lastpos( '\', ListFile)
            Name = substr( ListFile, lp + 1)
            if pos( upcase( Name)';', upcase( ListFiles)) = 0 then
               ListFiles = ListFiles''ListFile';'
            endif
         endif
      enddo
   enddo

   fPrependEpm = 0
   BaseNames = ''  -- ';'-separated list with basenames
   rest = ListFiles
   do while rest <> ''
      parse value rest with ListFile';'rest
      -- Load ListFile
      'xcom e /d' ListFile
      if rc <> 0 then
         iterate
      endif
      getfileid fid
      .visible = 0
      -- Read lines
      do l = 1 to .last
         Line = textline(l)
         StrippedLine = strip(Line)

         -- Ignore comments, lines starting with ';' at column 1 are comments
         if substr( Line, 1, 1) = ';' then
            iterate
         -- Ignore empty lines
         elseif StrippedLine = '' then
            iterate
         endif

         BaseName = StrippedLine
         -- Strip extension
         if rightstr( upcase( BaseName), 3) = '.EX' then
            BaseName = substr( BaseName, 1, length( BaseName) - 3)
         endif
         -- Ignore epm (this time)
         if upcase( BaseName) = 'EPM' then
            fPrependEpm = 1
         -- Append ExFile to list
         elseif pos( ';'upcase(BaseName)';', ';'upcase(BaseNames)';') = 0 then
            BaseNames = BaseNames''BaseName';'
         endif
      enddo  -- l
      -- Quit ListFile
      activatefile fid
      .modify = 0
      'xcom q'
   enddo
   -- Prepend 'epm;'
   -- 'epm;' should be the first entry, because it will restart EPM and
   -- unlinking/linking of other .EX files can be avoided then.
   if fPrependEpm = 1 then
      BaseNames = 'epm;'BaseNames  -- ';'-separated list with basenames
   endif
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   UserDirName = substr( NepmdUserDir, lastpos( '\', NepmdUserDir) + 1)
   call EnsureDirExists( NepmdUserDir)
   call EnsureDirExists( NepmdUserDir'\ex')
   CompileDir   = NepmdUserDir'\ex\tmp'
   LogFile      = NepmdUserDir'\ex\recompilenew.log'
   if Exist( LogFile) then
      call EraseTemp( LogFile)
   endif
   -- Writing ListFiles to LogFile in the part above would make EPM crash.
   if fCheckOnly then
      WriteLog( LogFile, '"RecompileNew CheckOnly" started at' Date Time'.')
      WriteLog( LogFile, 'Because of CheckOnly mode, no .EX file will be replaced.')
      WriteLog( LogFile, 'When warnings occur:')
      WriteLog( LogFile, '   Rename your 'upcase(UserDirName)'\MACROS and 'upcase(UserDirName)'\EX directories')
      WriteLog( LogFile, '   before the next EPM start.')
      WriteLog( LogFile, '   Then either discard your own macro files or merge it with')
      WriteLog( LogFile, '   Netlabs'' newly installed files from NETLABS\MACROS.')
      WriteLog( LogFile, 'Only when you really know what you are doing:')
      WriteLog( LogFile, '   Execute "RecompileNew" without args in order to replace .EX files.')
   else
      WriteLog( LogFile, '"RecompileNew" started at' Date Time'.')
   endif
   WriteLog( LogFile, '')
   WriteLog( LogFile, 'Checking base names listed in')
   rest = ListFiles
   do while rest <> ''
      parse value rest with next';'rest
      WriteLog( LogFile, '   'next)
   enddo
   WriteLog( LogFile, 'Note: Other not-listed .E/.EX files are not checked here.')
   WriteLog( LogFile, '      In order to recompile them')
   WriteLog( LogFile, '         o  create your own .LST list file in the 'upcase(UserDirName)'\EX directory,')
   WriteLog( LogFile, '            name it maybe MYEXFILES.LST or')
   WriteLog( LogFile, '         o  use the RELINK [IFLINKED] command instead.')
   fRestartEpm  = 0
   fFoundMd5    = '?'
   cWarning     = 0
   cRecompile   = 0
   cDelete      = 0
   cRelink      = 0
   fCheckOnlyNotCopied = 0
   -- Find new source files
   rest = BaseNames
   BaseNames = ''
   WriteLog( LogFile, '')
   WriteLog( LogFile, 'Checking old (existing) user .EX files and included .E files...')
   do while rest <> ''
      -- For every ExFile...
      parse value rest with BaseName';'rest
      fCompCurExFile = 0
      fCompExFile    = 0
      fReplaceExFile = 0
      fDeleteExFile  = 0
      fCopiedExFile  = 0
      CurEFiles         = ''
      CurEFileTimes     = ''
      CurExFileTime     = ''
      NewEFiles         = ''
      NewEFileTimes     = ''
      NewExFileTime     = ''
      NetlabsExFileTime = ''
      LastCheckTime     = ''
      KeyPath  = '\NEPMD\System\ExFiles\'lowcase(BaseName)
      KeyPath1 = KeyPath'\LastCheckTime'
      KeyPath2 = KeyPath'\Time'
      KeyPath3 = KeyPath'\EFiles'     -- EFiles     = base.ext;...
      KeyPath4 = KeyPath'\EFileTimes' -- EFileTimes = date time;...

      if fReset then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath1)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath3)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath4)
         iterate
      endif

      -- Get ExFileTime of last check from NEPMD.INI
      -- (Saving LastCheckTime avoids a possible ETPM call, if nothing has changed)
      next = NepmdQueryConfigValue( nepmd_hini, KeyPath1)
      parse value next with 'ERROR:'rc
      if rc = '' then
         LastCheckTime = next
      endif

      NetlabsExFile = NepmdRootDir'\netlabs\ex\'BaseName'.ex'
      -- Get full pathname
      CurExFile = FindExFile( BaseName)
      if CurExFile > '' then
         -- Get time of ExFile
         next = NepmdQueryPathInfo( CurExFile, 'MTIME')
         parse value next with 'ERROR:'rc
         if rc = '' then
            CurExFileTime = next
            next = NepmdQueryConfigValue( nepmd_hini, KeyPath2)
            if next <> CurExFileTime then
               fCompExFile = 1
            else

               -- Compare (maybe user's) ExFile with netlabs ExFile to delete it or to give a warning if older
               NetlabsExFile = NepmdRootDir'\netlabs\ex\'BaseName'.ex'
               next = NepmdQueryPathInfo( NetlabsExFile, 'MTIME')
               parse value next with 'ERROR:'rc
               if rc = '' then
                  NetlabsExFileTime = next
                  if upcase(CurExFile) <> upcase(NetlabsExFile) then  -- if different pathnames
                     fCompCurExFile = 1
                  endif

                  if fCompCurExFile = 1 then
                     if fFoundMd5 = '?' then
                        -- Search for MD5.EXE only once to give an error message
                        findfile next, 'md5.exe', 'PATH'
                        if rc then
                           findfile next, 'md5sum.exe', 'PATH'
                        endif
                        if rc then
                           fFoundMd5 = 0
                           WriteLog( LogFile, 'ERROR:   MD5.EXE or MD5SUM.EXE not found in PATH')
                        else
                           fFoundMd5 = 1
                        endif
                     endif
                     if fFoundMd5 = 1 then
                        WriteLog( LogFile, '         'BaseName' - comparing current .EX file "'CurExFile'" with Netlabs .EX file')
                        comprc = Md5Comp( CurExFile, NetlabsExFile)
                        delrc = ''
                        if comprc = 0 then
                           WriteLog( LogFile, '         'BaseName' - current .EX file "'CurExFile'" equal to Netlabs .EX file')
                           if not fCheckOnly then
                              delrc = EraseTemp( CurExFile)
                              if delrc then
                                 cWarning = cWarning + 1
                                 WriteLog( LogFile, 'WARNING: 'BaseName' - cannot delete current .EX file "'CurExFile'", rc = 'rc)
                              else
                                 WriteLog( LogFile, '    DEL: 'BaseName' - deleted current .EX file "'CurExFile'"')
                                 cDelete = cDelete + 1
                              endif
                           endif
                        endif
                        if comprc <> 0 | (comprc = 0 & delrc) then
                           if LastCheckTime < max( CurExFileTime, NetlabsExFileTime) then
                              fCompExFile = 1
                           endif
                           if CurExFileTime < NetlabsExFileTime then
                              WriteLog( LogFile, 'WARNING: 'BaseName' - current .EX file "'CurExFile'" older than Netlabs .EX file')
                              cWarning = cWarning + 1
                           endif
                        endif
                     endif  -- fFoundMd5 = 1
                  endif  -- fCompCurExFile = 1

               endif  -- rc = ''

            endif
         endif  -- CurExFile > ''

      else
         fReplaceExFile = 1
      endif

      -- Check E files, if not ETPM should be called already
      if fReplaceExFile <> 1 then

         -- Get list of EFiles from NEPMD.INI
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath3)
         parse value next with 'ERROR:'rc
         if rc = '' & next > '' then
            CurEFiles = next
         else
         endif
         -- Get list of times for EFiles from NEPMD.INI
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath4)
         parse value next with 'ERROR:'rc
         if rc = '' & next > '' then
            CurEFileTimes = next
         endif

         if CurEFiles = '' then
            fCompExFile = 1
         else

            -- Append optional E files (user may have added them since last check)
            orest = OptEFiles
            do while orest <> ''
               parse value orest with next';'orest
               if pos( ';'upcase( next)';', ';'upcase( CurEFiles)) = 0 then
                  CurEFiles = CurEFiles''next';'
               endif
            enddo
            if upcase( BaseName) = 'EPM' then
               orest = OptEpmEFiles
               do while orest <> ''
                  parse value orest with next';'orest
                  if pos( ';'upcase( next)';', ';'upcase( CurEFiles)) = 0 then
                     CurEFiles = CurEFiles''next';'
                  endif
               enddo
            endif

            erest = CurEFiles
            trest = CurEFileTimes
            do while erest <> ''
               -- For every EFile...
               parse value erest with EFile';'erest
               parse value trest with CurEFileTime';'trest
               EFileTime        = ''
               NetlabsEFileTime = ''
               -- Get full pathname
               FullEFile = FindFileInList( EFile, Get_Env( 'EPMMACROPATH'))
               -- Get time of EFile
               next = NepmdQueryPathInfo( FullEFile, 'MTIME')
               parse value next with 'ERROR:'rc
               if rc = '' then
                  EFileTime = next
                  -- Compare time of EFile with LastCheckTime and CurExFileTime
                  if not fCheckOnly then
                     if EFileTime > max( LastCheckTime, CurExFileTime) then
                        fCompExFile = 1
                        WriteLog( LogFile, '         'BaseName' - .E file "'FullEFile'" newer than last check')
                        --leave  -- don't leave to enable further warnings
                     elseif (CurEFileTime = '') & (pos( ';'upcase( EFile)';', ';'upcase( OptEFiles)) > 0) then
                        --WriteLog( LogFile, '         'BaseName' - .E file "'FullEFile'" is an optional file and probably not included')
                     elseif EFileTime <> CurEFileTime then
                        fCompExFile = 1
                        WriteLog( LogFile, '         'BaseName' - .E file "'FullEFile'" newer or older compared to last check of this .E file')
                        --leave  -- don't leave to enable further warnings
                     endif
                  endif
                  -- Compare time of (maybe user's) EFile with netlabs EFile to give a warning if older
                  NetlabsEFile = NepmdRootDir'\netlabs\macros\'EFile
                  next = NepmdQueryPathInfo( NetlabsEFile, 'MTIME')
                  parse value next with 'ERROR:'rc
                  if rc = '' then
                     NetlabsEFileTime = next
                     if EFileTime < NetlabsEFileTime then
                        WriteLog( LogFile, 'WARNING: 'BaseName' - .E file "'FullEFile'" older than Netlabs .E file')
                        cWarning = cWarning + 1
                     endif
                  endif
               endif  -- rc = ''
            enddo  -- while erest <> ''

         endif
      endif

      if (fReplaceExFile = 1 | fCompExFile = 1) then
         -- Run Etpm
         ExFile      = ''  -- init for CallEtpm
         EtpmLogFile = ''  -- init for CallEtpm
         etpmrc = CallEtpm( BaseName, CompileDir, ExFile, EtpmLogFile)
         if etpmrc = 0 then
            NewEFiles = GetEtpmFilesFromLog( EtpmLogFile)
            erest = NewEFiles
            NewEFileTimes = ''
            do while erest <> ''
               -- For every EFile...
               parse value erest with EFile';'erest
               EFileTime = ''
               -- Get full pathname
               FullEFile = FindFileInList( EFile, Get_Env( 'EPMMACROPATH'))
               -- Get time of EFile
               next = NepmdQueryPathInfo( FullEFile, 'MTIME')
               parse value next with 'ERROR:'rc
               if rc = '' then
                  EFileTime = next
               endif
               NewEFileTimes = NewEFileTimes''EFileTime';'
               -- Check E files here (after etpm) if not already done above
               if CurEFiles = '' then
                  -- Compare time of (maybe user's) EFile with netlabs EFile to give a warning if older
                  NetlabsEFile = NepmdRootDir'\netlabs\macros\'EFile
                  if upcase( NetlabsEFile) <> upcase( EFile) then
                     next = NepmdQueryPathInfo( NetlabsEFile, 'MTIME')
                     parse value next with 'ERROR:'rc
                     if rc = '' then
                        NetlabsEFileTime = next
                        if EFileTime < NetlabsEFileTime then
                           WriteLog( LogFile, 'WARNING: 'BaseName' - .E file "'FullEFile'" older than Netlabs .E file')
                           cWarning = cWarning + 1
                        endif
                     endif
                  endif
               endif
            enddo
         else
            rc = etpmrc
            WriteLog( LogFile, 'ERROR:   'BaseName' - ETPM returned rc =' rc)
            return rc
         endif
         -- Get time of new ExFile
         next = NepmdQueryPathInfo( ExFile, 'MTIME')
         parse value next with 'ERROR:'rc
         if rc = '' then
            NewExFileTime = next
         endif
      endif

      if fCompExFile = 1 then
         if fFoundMd5 = '?' then
            -- Search for MD5.EXE only once to give an error message
            findfile next, 'md5.exe', 'PATH'
            if rc then
               findfile next, 'md5sum.exe', 'PATH'
            endif
            if rc then
               fFoundMd5 = 0
               WriteLog( LogFile, 'ERROR:   MD5.EXE or MD5SUM.EXE not found in PATH')
            else
               fFoundMd5 = 1
            endif
         endif
         if fFoundMd5 = 1 then
            next = Md5Comp( ExFile, CurExFile)
            if next = 1 then
               fReplaceExFile = 1
               if NetlabsExFileTime > '' then
                  next2 = Md5Comp( ExFile, NetlabsExFile)
                  if next2 = 0 then
                     if upcase( CurExFile) <> upcase( NetlabsExFile) then
                        if not fCheckOnly then
                           fDeleteExFile = 1
                           WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" different to current but equal to Netlabs .EX file')
                        else
                           WriteLog( LogFile, 'WARNING: 'BaseName' - .EX file "'ExFile'" different to current but equal to Netlabs .EX file')
                           cWarning = cWarning + 1
                           fCheckOnlyNotCopied = 1
                        endif
                     endif
                  else
                     if not fCheckOnly then
                        WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" different to current and Netlabs .EX file')
                     else
                        WriteLog( LogFile, 'WARNING: 'BaseName' - .EX file "'ExFile'" different to current and Netlabs .EX file')
                        cWarning = cWarning + 1
                        fCheckOnlyNotCopied = 1
                     endif
                  endif
               else
                  if not fCheckOnly then
                     WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" different to current .EX file')
                  else
                     WriteLog( LogFile, 'WARNING: 'BaseName' - .EX file "'ExFile'" different to current .EX file')
                     cWarning = cWarning + 1
                     fCheckOnlyNotCopied = 1
                  endif
               endif
            elseif next = 0 then
               WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" equal to current .EX file')
            else
               WriteLog( LogFile, 'ERROR:   'BaseName' - MD5Comp returned rc = 'next)
            endif
         endif
      endif

      if fReplaceExFile = 1 & not fCheckOnly then
         DestDir = GetExFileDestDir( ExFile)
         if fDeleteExFile = 1 then
            rc = EraseTemp( CurExFile)
            if rc then
               cWarning = cWarning + 1
               WriteLog( LogFile, 'WARNING: 'BaseName' - can''t delete .EX file "'CurExFile'", rc = 'rc)
            else
               WriteLog( LogFile, '    DEL: 'BaseName' - deleted .EX file "'CurExFile'"')
            endif
            cDelete = cDelete + 1
         else
            quietshell 'copy' ExFile DestDir
            if rc then
               cWarning = cWarning + 1
               WriteLog( LogFile, 'WARNING: 'BaseName' - can''t copy .EX file to "'DestDir'", rc = 'rc)
            else
               WriteLog( LogFile, '    NEW: 'BaseName' - copied .EX file to "'DestDir'"')
               fCopiedExFile = 1
            endif
            quietshell 'copy' EtpmLogFile DestDir
            cRecompile = cRecompile + 1
         endif
         if upcase( BaseName) = 'EPM' then
            fRestartEpm = 1
         elseif fRestartEpm = 0 then
            if linked( BaseName) >= 0 then  -- <0 means error or not linked
               'unlink' BaseName
               'link' BaseName
               WriteLog( LogFile, '         'BaseName' - relinked .EX file')
               cRelink = cRelink + 1
               if upcase( rightstr( BaseName, 4)) = 'MENU' & length( BaseName) > 4 then
                  'ChangeMenu' BaseName
                  WriteLog( LogFile, '         'BaseName' - reloaded menu')
               endif
            endif
         endif
      endif

      if NewExFileTime > '' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath1)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath1, NewExFileTime)
         if fCopiedExFile = 1 then
            call NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
            call NepmdWriteConfigValue( nepmd_hini, KeyPath2, NewExFileTime)
         elseif fCompExFile = 1 then
            call NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
            call NepmdWriteConfigValue( nepmd_hini, KeyPath2, CurExFileTime)
         endif
      endif
      if NewEFiles > '' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath3)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath4)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath3, NewEFiles)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath4, NewEFileTimes)
      endif

   enddo  -- while rest <> ''
   if fReset then
      if not fNoMsg then
         sayerror 'All RecompileNew entries deleted from NEPMD.INI'
      endif
      return 0
   endif
   if fCheckOnly then
      if cWarning > 0 then
         Text = cWarning 'warning(s), no file replaced. Correct that before the next EPM start!'
      else
         Text = 'No warnings, everything looks ok.'
      endif
   else
      if fRestartEpm = 1 then
         Text = cRecompile 'file(s) recompiled and' cDelete 'file(s) deleted,' cWarning 'warning(s), restart'
      else
         Text = cRecompile 'file(s) recompiled and' cDelete 'file(s) deleted, therefrom' cRelink' file(s) relinked,' cWarning 'warning(s)'
      endif
   endif
   if not fNoMsg then
      sayerror Text' - see "'LogFile'"'
   endif
   if fRestartEpm = 1 then
      WriteLog( LogFile, '         epm - restart')
   endif
   WriteLog( LogFile, '')
   WriteLog( LogFile, Text)
   if cWarning > 0 then
      -- Check if LogFile already loaded
      getfileid logfid, LogFile
      if logfid <> '' then
         -- Quit LogFile
         getfileid fid
         activatefile logfid
         .modify = 0
         'xcom q'
         if fid <> logfid then
            activatefile fid
         endif
      endif
   endif
   if cWarning > 0 then
      ret = 1
   else
      ret = 0
   endif
   quietshell 'del' CompileDir'\* /n & rmdir' CompileDir  -- must come before restart

   if (not fCheckOnly) & (fRestartEpm = 1) then
      Cmd = 'postme postme Restart'
   else
      Cmd = ''
   endif
   if not fNoMsgBox then
      args = cWarning cRecompile cDelete cRelink fRestartEpm fCheckOnly
      if fRestartEpm then
         Cmd = Cmd 'postme postme RecompileNewMsgBox' args
      else
         Cmd = Cmd 'RecompileNewMsgBox' args
      endif
   endif
   Cmd = strip( Cmd)
   Cmd

   rc = ret

; ---------------------------------------------------------------------------
; Check if Dir exists. If not, create it. Note: The parent dir must exist.
defproc EnsureDirExists
   Dir = arg(1)
   if not NepmdDirExists( Dir) then
      quietshell 'md' Dir
   endif
   return

; ---------------------------------------------------------------------------
; Returns rc of the ETPM.EXE call and sets ExFile, EtpmLogFile.
; MacroFile may be specified without .e extension.
; Uses 'md' to create a maybe non-existing CompileDir, therefore its parent
; must exist.
defproc CallEtpm( MacroFile, CompileDir, var ExFile, var EtpmLogFile)
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   etpmrc = -1
   CompileDir = NepmdUserDir'\ex\tmp'
   if not exist( CompileDir) then
      call EnsureDirExists( CompileDir)
      if not exist( CompileDir) then
         sayerror 'CallEtpm: Cannot find or create CompileDir "'CompileDir'"'
         stop
      endif
   endif
   lp1 = lastpos( '\', MacroFile)
   next = substr( MacroFile, lp1 + 1)
   lp2 = lastpos( '.E', upcase( next))
   if rightstr( upcase( next), 2) = '.E' then
      BaseName = substr( next, 1, length( next) - 2)
   else
      BaseName = next
   endif
   ExFile      = CompileDir'\'BaseName'.ex'
   EtpmLogFile = CompileDir'\'BaseName'.log'

   Params = '/v 'MacroFile '/e 'EtpmLogFile
   --dprintf( '', '  compiling 'ExFileBaseName)
   CurDir = directory()
   call directory( CompileDir)
   quietshell 'xcom etpm' Params
   etpmrc = rc
   call directory( CurDir)

   if etpmrc = -2 then
      sayerror CANT_FIND_PROG__MSG 'ETPM.EXE'
   elseif etpmrc = 41 then
      sayerror 'ETPM.EXE:' CANT_OPEN_TEMP__MSG '"'
   elseif etpmrc then
      call ec_position_on_error( EtpmLogFile)
   else
      dprintf( '', '  'BaseName' compiled successfully')
   endif
   return etpmrc

; ---------------------------------------------------------------------------
; Returns a ';'-separated list of all used macro files from an ETPM /v log.
; Each macro file is appended by a ';' for easy parsing.
; ETPM won't list a macro file's path, when it founds that file in the
; current path. Therefore macro files are maybe listed without path.
defproc GetEtpmFilesFromLog( EtpmLogFile)
   EFiles = ''
   'xcom e 'EtpmLogFile
   if rc then  -- Unexpected error or new .Untitled file
      sayerror ERROR_LOADING__MSG EtpmLogFile
   else
      do l = 4 to .last  -- start at line 4 to omit the ' compiling ...' line
         parse value textline(l) with 'compiling 'EFile
         if EFile > '' then
            -- strip path
            lp = lastpos( '\', EFile)
            EFile = substr( EFile, lp + 1)
            EFiles = EFiles''EFile';'
         endif
      enddo
   endif
   'xcom q'
   return EFiles

; ---------------------------------------------------------------------------
; Returns FullName of ExFile when found, else nothing.
; Sets rc in NEPMD style.
; Doesn't search in current dir. The path of ExFile is stripped to get its
; name.
defproc FindExFile( ExFile)
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   AutolinkDir  = NepmdUserDir'\autolink'  -- search in <UserDir>\autolink first
   ProjectDir   = NepmdUserDir'\project'   -- search in <UserDir>\project second
   FullExFile = ''
   -- strip path
   lp = lastpos( '\', ExFile)
   ExFile = substr( ExFile, lp + 1)
   if rightstr( upcase( ExFile), 3) <> '.EX' then
      ExFile = ExFile'.ex'
   endif
   if exist( AutolinkDir'\'ExFile) then
      FullExFile = AutolinkDir'\'ExFile
   elseif exist( ProjectDir'\'ExFile) then
      FullExFile = ProjectDir'\'ExFile
   else
      FullExFile = FindFileInList( ExFile, Get_Env( 'EPMEXPATH'))
   endif
   next = NepmdQueryFullName( FullExFile)
   parse value next with 'ERROR:'rc
   if rc = '' then
      FullExFile = next
   endif
   return FullExFile

; ---------------------------------------------------------------------------
; Determine destination dir for an ExFile recompilation.
; Doesn't search in current dir. The path of ExFile is stripped to get its
; name.
defproc GetExFileDestDir( ExFile)
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   AutolinkDir  = NepmdUserDir'\autolink'  -- search in <UserDir>\autolink first
   ProjectDir   = NepmdUserDir'\project'   -- search in <UserDir>\project second
   DestDir = ''
   -- strip path
   lp = lastpos( '\', ExFile)
   ExFile = substr( ExFile, lp + 1)
   if rightstr( upcase( ExFile), 3) <> '.EX' then
      ExFile = ExFile'.ex'
   endif
   if exist( AutolinkDir'\'ExFile) then
      DestDir = AutolinkDir
   elseif exist( ProjectDir'\'ExFile) then
      DestDir = ProjectDir
   else
      DestDir = NepmdUserDir'\ex'
   endif
   return DestDir

; ---------------------------------------------------------------------------
; Compare 2 files using MD5.EXE or MD5SUM.EXE. Returns:
;  0 if equal
;  1 if different
; -1 on error
defproc Md5Comp( File1, File2)
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
   findfile next, 'md5.exe', 'PATH'
   if rc then
      findfile next, 'md5sum.exe', 'PATH'
   endif
   if rc then
      sayerror 'ERROR: MD5.EXE or MD5SUM.EXE not found in PATH'
   else
      Md5Exe = next
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

; ---------------------------------------------------------------------------
compile if not defined( EPM_EDIT_LOGAPPEND)
const
   EPM_EDIT_LOGAPPEND = 5496
compile endif

defproc WriteLog( LogFile, Msg)
   LogFile = LogFile\0
   Msg     = Msg\13\10\0
   call windowmessage( 1, getpminfo(EPMINFO_EDITFRAME),
                       EPM_EDIT_LOGAPPEND,
                       ltoa( offset( LogFile)''selector( LogFile), 10),
                       ltoa( offset( Msg)''selector( Msg), 10))

; ---------------------------------------------------------------------------
; Compare .EX and .E macro files from <UserDir> with those from the NETLABS
; tree.
defc CheckEpmMacros
   universal nepmd_hini

   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   call EnsureDirExists( NepmdUserDir)
   call EnsureDirExists( NepmdUserDir'\ex')
   call EnsureDirExists( NepmdUserDir'\macros')
   call EnsureDirExists( NepmdUserDir'\autolink')

   'RecompileNew CheckOnly'

; ---------------------------------------------------------------------------
; Show a MsgBox with the result of RecompileNew, submitted as arg(1).
; Syntax: RecompileNewMsgBox cWarning cRecompile cDelete cRelink fRestart fCheckOnly
; Todo: use different text for fCheckOnly = 1, cRecompile > 0, cRelink > 0
defc RecompileNewMsgBox
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   UserDirName = substr( NepmdUserDir, lastpos( '\', NepmdUserDir) + 1)
   LogFile = NepmdUserDir'\ex\recompilenew.log'
   parse arg cWarning cRecompile cDelete cRelink fRestart fCheckOnly
   Bul = \7
   Text = ''
   if fCheckOnly then
      Text = Text || 'RecompileNew CHECKONLY:'\n\n
   else
      Text = Text || 'RecompileNew:'\n\n
      Text = Text || '       'Bul\9''cRecompile'  file(s) recompiled'\n
      Text = Text || '       'Bul\9''cDelete'  file(s) deleted'\n
      if fRestart then
         Text = Text || '       'Bul\9'EPM restarted because'\n
         Text = Text ||             \9'recompilation of EPM.EX'\n\n
      else
         -- EPM/PM? bug: the doubled \n at the end adds 1 additional space after cRelink:
         Text = Text || '       'Bul\9''cRelink' file(s) relinked'\n\n
      endif
   endif
   if cWarning > 0 then
      Text = Text || 'Warning(s) occurred during comparison of 'upcase(UserDirName)' files'
      Text = Text || ' with NETLABS files. See log file'
      Text = Text || ' 'upcase(UserDirName)'\EX\RECOMPILENEW.LOG'\n\n
      Text = Text || 'In order to use all the newly installed NETLABS files,'
      Text = Text || ' delete or rename the listed 'upcase(UserDirName)' files, that produced'
      Text = Text || ' a warning. A good idea would be to rename'
      Text = Text || ' your 'upcase(UserDirName)'\MACROS and 'upcase(UserDirName)'\EX'
      Text = Text || ' directories before the next EPM start.'\n\n
      Text = Text || 'Only when you have added your own macros:'\n
      Text = Text || 'After that, merge your own additions with the new'
      Text = Text || ' versions of the macros in NETLABS\MACROS.'
      Text = Text || ' (They can be left in your 'upcase(UserDirName)'\MACROS dir, if there''s'
      Text = Text || ' no name clash.) Then Recompile your macros. This can be'
      Text = Text || ' done easily with NEPMD''s RecompileNew command.'\n\n
      Text = Text || 'Do you want to load the log file now?'
      Style = MB_YESNO+MB_WARNING+MB_DEFBUTTON1+MB_MOVEABLE
   else
      Text = Text || 'No warning(s) occurred during comparison of 'upcase(UserDirName)' files'
      Text = Text || ' with NETLABS files.'\n\n
      Text = Text || 'If you have added own macro files to your MYEPM tree,'
      Text = Text || ' then they are newer than the files in the NETLABS tree.'
      Text = Text || ' Apparently no old MYEPM files are used.'\n\n
      Text = Text || 'Do you want to load the log file now?'
      Style = MB_YESNO+MB_INFORMATION+MB_DEFBUTTON1+MB_MOVEABLE
   endif

   Title = 'Checked .E and .EX files from 'upcase(UserDirName)' tree'
   ret = winmessagebox( Title,
                        Text,
                        Style)
   if ret = 6 then  -- Yes
      -- check if old LogFile already in ring
      getfileid logfid, LogFile
      if logfid <> '' then
         -- discard previously loaded LogFile from ring
         getfileid curfid
         if curfid = logfid then
            -- quit current file
            'xcom quit'
         else
            -- temporarily switch to old LogFile and quit it
            activatefile logfid
            'xcom quit'
            activatefile curfid
         endif
      endif
      'e 'LogFile
   elseif ret = 7 then  -- No
   endif

   return

; ---------------------------------------------------------------------------
defc StartRecompile
   NepmdRootDir = NepmdScanEnv('NEPMD_ROOTDIR')
   NepmdUserDir = NepmdScanEnv('NEPMD_USERDIR')
   parse value NepmdRootDir with 'ERROR:'rc1
   parse value NepmdUserDir with 'ERROR:'rc2
   if rc1 = '' & rc2 = '' then
      UserExDir = NepmdUserDir'\ex'
      -- Workaround:
      -- Change to root dir first to avoid erroneously loading of .e files from current dir.
      -- Better let Recompile.exe do this, because the restarted EPM will open with the
      -- same directory as Recompile.
      -- And additionally: make Recompile change save/restore EPM's directory.
      CurDir = directory()
      call directory('\')
      rc = directory(UserExDir)
      'start 'NepmdRootDir'\netlabs\bin\recomp.exe 'UserExDir
      call directory('\')
      call directory(CurDir)
   else
      sayerror 'Environment var NEPMD_ROOTDIR not set'
   endif
   return

