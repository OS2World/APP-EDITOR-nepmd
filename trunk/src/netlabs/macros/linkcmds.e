/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: linkcmds.e,v 1.11 2005-03-05 21:15:16 aschn Exp $
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
define INCLUDING_FILE = 'LINKCMDS.E'
const
   tryinclude 'MYCNF.E'

 compile if not defined(SITE_CONFIG)
const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(WANT_ET_COMMAND)
   WANT_ET_COMMAND = 1
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
compile endif

; ---------------------------------------------------------------------------
; Syntax: link [<path>]<modulename>[.ex]          Example:  link draw
; A simple front end to the link statement to allow command-line invocation.
defc link
   waslinkedrc = linked(arg(1))
   display -2  -- Turn non-critical messages off, we give our own message.
   link arg(1)
   linkrc = rc
   display 2
   if linkrc >= 0 then
      if waslinkedrc > 0 then
         sayerror 'Module "'arg(1)'" already linked as module #'waslinkedrc'.'
      else
         --sayerror LINK_COMPLETED__MSG RC
         sayerror LINK_COMPLETED__MSG''linkrc' "'arg(1)'"'
      endif
   elseif linkrc = -307 then
      sayerror 'Module "'arg(1)'" not linked, file not found'
   elseif linkrc < 0 then
      -- Sometimes is linkrc = empty, therefore check it again
      linkedrc = linked(arg(1))
      if linkedrc < 0 then
         sayerror 'Module "'arg(1)'" not linked, rc = 'linkrc', linkedrc = 'linkedrc
      elseif waslinkedrc < 0 then
         sayerror LINK_COMPLETED__MSG''linkedrc' "'arg(1)'"'
      else
         sayerror 'Module "'arg(1)'": linkedrc = 'linkedrc
      endif
   endif

; ---------------------------------------------------------------------------
; Syntax: unlink [<path>]<modulename>[.ex]        Example:  unlink draw
; A simple front end to the unlink statement to allow command-line invocation.
; The standard unlink statement doesn't search in EPMPATH and DPATH like the
; link statement does. This is added here. ExFile is searched in
; .;%EPMPATH%;%DPATH% until the linked file is found.
defc unlink
   FullPathName = ''
   unlinkrc     = ''
   ExFile = arg(1)
   p1 = lastpos( '\', ExFile)
   ExFileName = substr( ExFile, p1 + 1)
   p2 = lastpos( '.', ExFileName)
   if p2 = 0 then
      ExFile = ExFile'.ex'
   endif
   if substr( ExFile, 2, 2) =  ':\' or substr( ExFile, 1, 2) =  '\\' then
      FullPathName = ExFile
   endif

   if FullPathName = '' then
      -- search ExFile in whole PathList, until linkedrc > 0
      PathList = '.;'Get_Env('EPMPATH')';'Get_Env('DPATH')';'
      rest = PathList
      do while rest <> ''
         parse value rest with Path';'rest
         if Path = '' then
            iterate
         endif
         if rightstr( Path, 2, 2) = ':\' then  -- if root dir
            Path = strip( Path, 'T', '\')
         endif
         next = Path'\'ExFile
         if Exist( next) then
            -- Bug in linked: strips path forever, checks name only
            linkedrc = linked( next)
            --sayerror 'linked: rc = 'linkedrc' for 'next
            if linkedrc >= 0 then
               display -2  -- Turn non-critical messages off, we give our own message.
               unlink next
               display 2
               if rc = 0 then
                  unlinkrc = rc
                  FullPathName = next
                  leave
               endif
            endif
         endif
      enddo
   endif

   if FullPathName = '' then
      FullPathName = arg(1)  -- try to unlink arg(1) if not found until here
   endif

   if unlinkrc = '' then  -- if not already tried to unlink
      display -2  -- Turn non-critical messages off, we give our own message.
      unlink FullPathName
      unlinkrc = rc
      display 2
   endif
   if unlinkrc then
      if unlinkrc = -310 then
         sayerror 'Module "'arg(1)'" not unlinked, unknown module'
      elseif unlinkrc = -302 then
         sayerror 'Module "'arg(1)'" not unlinked, defined keyset in use (better restart EPM)'
      else
         sayerror 'Module "'arg(1)'" not unlinked, rc = 'unlinkrc
      endif
   endif

; ---------------------------------------------------------------------------
; Syntax: relink [[<path>]<modulename>[.e]]
;
; Compiles the module, unlinks it and links it again.  A fast way to
; recompile/reload a macro under development without leaving the editor.
; Note that the unlink is necessary in case the module is already linked,
; else the link will merely reinitialize the previous version.
;
; If modulename is omitted, the current filename is assumed.
;
; New: Link it only if it was linked before.
; New: Path and extension for modulename are not required.
defc relink
   modulename=arg(1)  -- new: path and ext optional
   if modulename='' then                           -- If no name given,
      p = lastpos( '.', .filename)
      if upcase(substr( .filename, p)) <> '.E' then
         sayerror 'Not an .E file'
         return
      endif
      modulename = substr( .filename, 1, p - 1)    -- use current file.
      if .modify then
         's'                                       -- Save it if changed.
         if rc then return; endif
      endif
   endif

   -- check if basename of module was linked before
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
      if rc = 0 then
         'link' basename
         -- refresh menu if module is linked and defines a menu
         if rc >= 0 & upcase( rightstr( basename, 4)) = 'MENU' &
            length( basename) > 4 then
            'ChangeMenu' basename
         endif
      endif
   endif

; ---------------------------------------------------------------------------
; Syntax: etpm [[<path>]<e_file> [[<path>]<ex_file>]
;
; etpm         compiles EPM.E to EPM.EX in myepm\ex
; etpm tree.e  compiles TREE.E to TREE.EX in myepm\ex
; etpm tree    compiles TREE.E to TREE.EX in myepm\ex
; etpm =       compiles current file to an .ex file in myepm\ex
; etpm = =     compiles current file to an .ex file in the same dir
;
; Doesn't use the /v option.
; Doesn't respect options from the commandline, like /v or /e <logfile>.
defc et,etpm=
   universal vTEMP_PATH
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
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   AutolinkDir  = NepmdRootDir'\myepm\autolink'  -- search in myepm\autolink first
   ProjectDir   = NepmdRootDir'\myepm\project'   -- search in myepm\project second
   if exist( AutolinkDir'\'BaseName'.ex') then
      DestDir = AutolinkDir
   elseif exist( ProjectDir'\'BaseName'.ex') then
      DestDir = ProjectDir
   else
      DestDir = NepmdRootDir'\myepm\ex'     -- myepm\ex
   endif
   If ExFile = '' then
      ExFile = DestDir'\'BaseName'.ex'
   endif

   TempFile = vTEMP_PATH'ETPM'substr( ltoa( gethwnd(EPMINFO_EDITCLIENT), 16), 1, 4)'.TMP'

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
   call erasetemp(TempFile) -- 4.11:  added to erase the temp file.

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
; Because of defc Etpm is used, EPM.EX is created in myepm\ex.
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
   "postme Open '"cmd"'"
   'postme Close'

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
          -- ignore
      else
        if .modify then
           rc = 1
           -- let this file on top
           activatefile fid
           sayerror 'Current file is modified. Save it or discard changes first.'
           stop  -- Stops further processing of current and calling command or
                 -- procedure. Advantage: no check for rc required.
        endif
      endif
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo

; ---------------------------------------------------------------------------
; Recompile all files, whose names found in .lst files in EPMEXPATH.
;
; Maybe to be changed: compile only those files, whose (.EX files exist) names
; are listed in ex\*.lst and whose E files found in myepm\macros.
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
; files, whose E sources are newer then their EX files.
; Could be a problem: the ini entry for epm\EFileTimes has currently 1341
; byte. Apparently in ETK every string is limitted to 1599 byte.
defc RecompileNew
   universal nepmd_hini

   parse value getdate(1) with today';' .  -- Discard MonthNum
   parse value gettime(1) with now';' .    -- Discard Hour24

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

   AppendEpm = 0
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
            AppendEpm = 1
         -- Append ExFile to list
         elseif pos( upcase(BaseName)';', upcase(BaseNames)';') = 0 then
            BaseNames = BaseNames''BaseName';'
         endif
      enddo  -- l
      -- Quit ListFile
      activatefile fid
      .modify = 0
      'xcom q'
   enddo
   -- Append 'epm;' ('epm' must be the last entry, if present, because it will restart EPM)
   if AppendEpm = 1 then
      BaseNames = BaseNames'epm;'  -- ';'-separated list with basenames
   endif
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   AutolinkDir  = NepmdRootDir'\myepm\autolink'  -- search in myepm\autolink first
   ProjectDir   = NepmdRootDir'\myepm\project'   -- search in myepm\project second
   CompileDir   = NepmdRootDir'\myepm\ex\tmp'
   LogFile      = NepmdRootDir'\myepm\ex\recompilenew.log'
   if Exist( LogFile) then
      call EraseTemp( LogFile)
   endif
   -- Writing ListFiles to LogFile in the part above would make EPM crash.
   WriteLog( LogFile, 'RecompileNew started at' now 'on' today'.')
   WriteLog( LogFile, 'Checking base names listed in 'ListFiles)

   fRestartEpm  = 0
   fFoundMd5    = '?'
   cWarning     = 0
   cRecompile   = 0
   cDelete      = 0
   cRelink      = 0
   -- Find new source files
   rest = BaseNames
   BaseNames = ''
   do while rest <> ''
      -- For every ExFile...
      parse value rest with BaseName';'rest
      fCompExFile    = 0
      fReplaceExFile = 0
      fDeleteExFile  = 0
      OldEFiles         = ''
      OldEFileTimes     = ''
      OldExFileTime     = ''
      NewEFiles         = ''
      NewEFileTimes     = ''
      NewExFileTime     = ''
      NetlabsExFileTime = ''
      LastCheckTime     = ''
      KeyPath1 = '\NEPMD\User\ExFiles\'lowcase(BaseName)'\LastCheckTime'
      KeyPath2 = '\NEPMD\User\ExFiles\'lowcase(BaseName)'\EFiles'     -- EFiles     = base.ext;...
      KeyPath3 = '\NEPMD\User\ExFiles\'lowcase(BaseName)'\EFileTimes' -- EFileTimes = date time;...

      if upcase( arg(1)) = 'RESET' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath1)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath3)
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
      OldExFile = FindExFile( BaseName)
      if OldExFile > '' then
         -- Get time of ExFile
         next = NepmdQueryPathInfo( OldExFile, 'MTIME')
         parse value next with 'ERROR:'rc
         if rc = '' then
            OldExFileTime = next

            if OldExFileTime > LastCheckTime then
               LastCheckTime = OldExFileTime
            endif

            -- Compare (maybe myepm) ExFile with netlabs ExFile to give a warning if older
            NetlabsExFile = NepmdRootDir'\netlabs\ex\'BaseName'.ex'
            next = NepmdQueryPathInfo( NetlabsExFile, 'MTIME')
            parse value next with 'ERROR:'rc
            if rc = '' then
               NetlabsExFileTime = next
               if OldExFileTime < NetlabsExFileTime then
                  WriteLog( LogFile, 'WARNING: 'BaseName' - .EX file "'OldExFile'" older then Netlabs .EX file')
                  cWarning = cWarning + 1
               endif
            endif  -- rc = ''
         endif

      else
         fReplaceExFile = 1
      endif

      -- Check E files, if not ETPM should be called already
      if fReplaceExFile <> 1 then

         -- Get list of EFiles from NEPMD.INI
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath2)
         parse value next with 'ERROR:'rc
         if rc = '' & next > '' then
            OldEFiles = next
         else
         endif
         -- Get list of times for EFiles from NEPMD.INI
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath3)
         parse value next with 'ERROR:'rc
         if rc = '' & next > '' then
            OldEFileTimes = next
         endif

         if OldEFiles = '' then
            fCompExFile = 1
         else

            erest = OldEFiles
            trest = OldEFileTimes
            do while erest <> ''
               -- For every EFile...
               parse value erest with EFile';'erest
               parse value trest with OldEFileTime';'trest
               EFileTime        = ''
               NetlabsEFileTime = ''
               -- Get full pathname (if not in current path)
               findfile FullEFile, EFile, 'EPMMACROPATH'
               -- Get time of EFile
               next = NepmdQueryPathInfo( FullEFile, 'MTIME')
               parse value next with 'ERROR:'rc
               if rc = '' then
                  EFileTime = next
                  -- Compare time of EFile with LastCheckTime
                  if EFileTime > LastCheckTime then
                     fCompExFile = 1
                     WriteLog( LogFile, '         'BaseName' - .E file "'FullEFile'" newer then last check')
                     --leave  -- don't leave to enable further warnings
                  elseif EFileTime <> OldEFileTime then
                     fCompExFile = 1
                     WriteLog( LogFile, '         'BaseName' - .E file "'FullEFile'" newer or older compared to last check of this .E file')
                     --leave  -- don't leave to enable further warnings
                  endif
                  -- Compare time of (maybe myepm) EFile with netlabs EFile to give a warning if older
                  NetlabsEFile = NepmdRootDir'\netlabs\macros\'EFile
                  next = NepmdQueryPathInfo( NetlabsEFile, 'MTIME')
                  parse value next with 'ERROR:'rc
                  if rc = '' then
                     NetlabsEFileTime = next
                     if EFileTime < NetlabsEFileTime then
                        WriteLog( LogFile, 'WARNING: 'BaseName' - .E file "'FullEFile'" older then Netlabs .E file')
                        cWarning = cWarning + 1
                     endif
                  endif
               endif  -- rc = ''
            enddo  -- while erest <> ''

         endif
      endif

      if fReplaceExFile = 1 | fCompExFile = 1 then
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
               -- Get full pathname (if not in current path)
               findfile FullEFile, EFile, 'EPMMACROPATH'
               -- Get time of EFile
               next = NepmdQueryPathInfo( FullEFile, 'MTIME')
               parse value next with 'ERROR:'rc
               if rc = '' then
                  EFileTime = next

               endif
               NewEFileTimes = NewEFileTimes''EFileTime';'
            enddo
         else
            rc = etpmrc
            return
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
            next = Md5Comp( ExFile, OldExFile)
            if next = 1 then
               fReplaceExFile = 1
               next2 = Md5Comp( ExFile, NetlabsExFile)
               if next2 = 0 then
                  if upcase( OldExFile) <> upcase( NetlabsExFile) then
                     fDeleteExFile = 1
                     WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" different to old but equal to Netlabs .EX file')
                  endif
               else
                  WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" different to old and Netlabs .EX file')
               endif
            elseif next = 0 then
               WriteLog( LogFile, '         'BaseName' - .EX file "'ExFile'" equal to old .EX file')
            else
               WriteLog( LogFile, 'ERROR:   'BaseName' - MD5Comp returned rc = 'next)
            endif
         endif
      endif

      if fReplaceExFile = 1 then
         DestDir = GetExFileDestDir( ExFile)
         if fDeleteExFile = 1 then
            rc = EraseTemp( OldExFile)
            if rc then
               cWarning = cWarning + 1
               WriteLog( LogFile, 'WARNING: 'BaseName' - can''t delete .EX file "'OldExFile'", rc = 'rc)
            else
               WriteLog( LogFile, '         'BaseName' - deleted .EX file "'OldExFile'"')
            endif
            cDelete = cDelete + 1
         else
            quietshell 'copy' ExFile DestDir
            if rc then
               cWarning = cWarning + 1
               WriteLog( LogFile, 'WARNING: 'BaseName' - can''t copy .EX file to "'DestDir'", rc = 'rc)
            else
               WriteLog( LogFile, '         'BaseName' - copied .EX file to "'DestDir'"')
            endif
            quietshell 'copy' EtpmLogFile DestDir
            cRecompile = cRecompile + 1
         endif
         if upcase( BaseName) = 'EPM' then
            fRestartEpm = 1
         elseif linked( BaseName) then
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

      if NewExFileTime > '' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath1)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath1, NewExFileTime)
      endif
      if NewEFiles > '' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath3)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath2, NewEFiles)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath3, NewEFileTimes)
      endif

   enddo
   Text = cRecompile 'files recompiled and' cDelete 'files deleted, therefrom' cRelink' files relinked,' cWarning 'warnings'
   sayerror Text' - see "'LogFile'"'
   if fRestartEpm = 1 then
      WriteLog( LogFile, '         'BaseName' - restarted')
   endif
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
      'e 'LogFile
   endif
   quietshell 'del' CompileDir'\* /n & rmdir' CompileDir  -- must come before restart
   if fRestartEpm = 1 then
      'postme Restart'
   endif

; ---------------------------------------------------------------------------
; Returns rc of the ETPM.EXE call and sets ExFile, EtpmLogFile.
; MacroFile may be specified without .e extension.
; Uses 'md' to create a maybe non-existing CompileDir, therefore its parent
; must exist.
defproc CallEtpm( MacroFile, CompileDir, var ExFile, var EtpmLogFile)
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   etpmrc = -1
   CompileDir = NepmdRootDir'\myepm\ex\tmp'
   if not exist( CompileDir) then
      quietshell 'md' CompileDir
      if not exist( CompileDir) then
         sayerror 'CallEtpm: Can''t find or create CompileDir "'CompileDir'"'
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
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   AutolinkDir  = NepmdRootDir'\myepm\autolink'  -- search in myepm\autolink first
   ProjectDir   = NepmdRootDir'\myepm\project'   -- search in myepm\project second
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
      findfile FullExFile, ExFile, 'EPMEXPATH'
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
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   AutolinkDir  = NepmdRootDir'\myepm\autolink'  -- search in myepm\autolink first
   ProjectDir   = NepmdRootDir'\myepm\project'   -- search in myepm\project second
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
      DestDir = NepmdRootDir'\myepm\ex'
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
; Compare loaded EPM.EX with Netlabs' EPM.EX. Give a Message, if Nelabs'
; EPM.EX is newer. Make that suppressable with an ini key, to reset by the
; next NEPMD installation.
defc CheckEpmExTimeStamp
   universal nepmd_hini

   App = 'RegDefaults'
   Key = '\NEPMD\System\CheckEpmEx'

   Enabled = QueryProfile( nepmd_hini, App, Key)
   if Enabled = 0 then
      return
   endif

   EpmEx = wheredefc('versioncheck')
   EpmEx = NepmdQueryFullName(EpmEx)
   TEpmEx = NepmdQueryPathInfo( EpmEx, 'MTIME')

   NepmdRoot = NepmdScanEnv( 'NEPMD_ROOTDIR')
   NEpmEx = NepmdRoot'\netlabs\ex\epm.ex'
   TNEpmEx = NepmdQueryPathInfo( NEpmEx, 'MTIME')

   if TEpmEx >= TNEpmEx then
      --sayerror 'OK! Loaded EPM.EX: 'TEpmEx', Netlabs EPM.EX: 'TNEpmEx
      return
   else
      --sayerror 'Old! Loaded EPM.EX: 'TEpmEx', Netlabs EPM.EX: 'TNEpmEx
   endif

   Style = MB_YESNO+MB_CUAWARNING+MB_DEFBUTTON1+MB_MOVEABLE

   --Bul = \16
   Bul = \7
   ret = winmessagebox( 'Old macro file',
                        EpmEx\10                                 ||
                        TEpmEx\10\10                             ||
                        'is an old file from before the last'    ||
                        ' NEPMD installation.'\10\10             ||
                        'In order to use the new EPM:'\10        ||
                        '       'Bul\9'Backup your old files in the'\10           ||
                                    \9'NEPMD\MYEPM tree, if you have'\10          ||
                                    \9'added anything.'\10                        ||
                        '       'Bul\9'Delete all files in NEPMD\MYEPM\EX'\10     ||
                                    \9'and NEPMD\MYEPM\MACROS.'\10                ||
                        '       'Bul\9'Restart EPM.'\10\10                        ||
                        'Only when you have added own macros:'\10                 ||
                        'After that, merge your own additions with the new'       ||
                        ' versions of the macros in NEPMD\NETLABS\MACROS.'        ||
                        ' (They can be let in your MYEPM\MACROS dir, if there''s' ||
                        ' no name clash.) Then Recompile your macros.'\10\10      ||
                        'Should this be checked on the next start again?'\10,
                        Style)
   if ret = 6 then  -- Yes
      -- nop
   elseif ret = 7 then  -- No
      -- Change (this time only) the default setting to reset it
      -- automatically by the next install.
      call SetProfile( nepmd_hini, App, Key, 0)
   endif
   return

; ---------------------------------------------------------------------------
defc StartRecompile
   NepmdRootDir = NepmdScanEnv('NEPMD_ROOTDIR')
   parse value NepmdRootDir with 'ERROR:'rc
   if rc = '' then
      MyepmExDir = NepmdRootDir'\myepm\ex'
      -- Workaround:
      -- Change to root dir first to avoid erroneously loading of .e files from current dir.
      -- Better let Recompile.exe do this, because the restarted EPM will open with the
      -- same directory as Recompile.
      -- And additionally: make Recompile change save/restore EPM's directory.
      CurDir = directory()
      call directory('\')
      rc = directory(MyepmExDir)
      'start 'NepmdRootDir'\netlabs\bin\recomp.exe 'MyepmExDir
      call directory('\')
      call directory(CurDir)
   else
      sayerror 'Environment var NEPMD_ROOTDIR not set'
   endif
   return

; ---------------------------------------------------------------------------
;  New command to query whether a module is linked.  Of course if
;  you're not sure whether a module is linked, you can always just repeat the
;  link command.  E won't reload the file from disk if it's already linked, but
;  it will rerun the module's DEFINIT which might not be desirable.
;
;  This also serves to document the new linked() function.  Linked() returns:
;     module number        (a small integer, >= 0) if linked.
;     -1                   if found on disk but not currently linked.
;     -307                 if module can't be found on disk.  This RC value
;                          is the same as sayerror("Link: file not found").
;     -308                 if bad module name, can't be expanded.  Same as
;                          sayerror("Link: invalid filename").
defc qlink, qlinked, ql
   module = arg(1)
   if module = '' then
      sayerror QLINK_PROMPT__MSG
   else
      result = linked(arg(1))
      if result = -307 or    -- sayerror("Link: file not found")
         result = -308 then  -- sayerror("Link: invalid filename")
         sayerror CANT_FIND1__MSG module CANT_FIND2__MSG
      elseif result < 0 then    -- return of -1 means file exists but not linked
         sayerror module NOT_LINKED__MSG
      else
         sayerror module LINKED_AS__MSG result'.'
      endif
   endif

; ---------------------------------------------------------------------------
defc linkverify
   module = arg(1)
   link module
   if RC < 0 then
      if RC = -290 then  -- sayerror('Invalid EX file or incorrect version')
         -- Get full pathname for a better error msg
         if filetype(module) <> '.EX' then
            module = module'.ex'              -- link does this by itself
         endif
         findfile module1, module, EPATH      -- link does this by itself
         if rc then
            findfile module1, module, 'PATH'  -- why search in PATH?
         endif
         if not rc then
            module = module1
         endif
         RC = -290
      endif
      call winmessagebox( UNABLE_TO_LINK__MSG module,
                          sayerrortext(rc),
                          16416)  -- OK + ICON_EXCLAMATION + MB+MOVEABLE
   endif

; ---------------------------------------------------------------------------
; Routine to link an .ex file, then execute a command in that file.
defproc link_exec( ex_file, cmd_name)
   'linkverify' ex_file
   if RC >= 0 then
      cmd_name arg(3)
   else
      sayerror UNABLE_TO_EXECUTE__MSG cmd_name
   endif

; ---------------------------------------------------------------------------
defc linkexec
   parse arg ex_file cmd_name
   call link_exec( ex_file, cmd_name)


