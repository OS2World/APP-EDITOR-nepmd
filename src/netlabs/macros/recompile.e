/****************************** Module Header *******************************
*
* Module Name: recompile.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
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

const
compile if not defined( RECOMPILE_RESTART_NAMES)
   -- These basenames require restart of EPM:
   --    EPM: obviously
   --    RECOMPILE: as tests showed
   RECOMPILE_RESTART_NAMES = 'EPM RECOMPILE'
compile endif

; ---------------------------------------------------------------------------
defc PostRelink
   parse arg BaseName

   -- Refresh menu if module is linked and defines a menu
   if upcase( rightstr( BaseName, 4)) = 'MENU' & length( BaseName) > 4 then
      'RefreshMenu'
   endif

   -- Refresh keyset if module is linked and defines keys
   if upcase( rightstr( BaseName, 4)) = 'KEYS' & length( BaseName) > 4 then
      'ReloadKeyset'
   endif

   -- Refresh coding style definitions if modecnf.ex is linked
   if upcase( BaseName) = 'MODECNF' then
      'InitModeCnf'
   endif

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
defc Relink
   args = arg(1)
   wp = wordpos( 'IFLINKED', upcase( args))
   fIfLinked = (wp > 0)
   if wp then
      args = delword( args, wp, 1)  -- remove 'IFLINKED' from args
   endif
   Modulename = args  -- new: path and ext optional
   call parse_filename( Modulename)

   if Modulename = '' then                           -- If no name given,
      p = lastpos( '.', .filename)
      if upcase( substr( .filename, p)) <> '.E' then
         sayerror '"'.filename'" is not an .E file'
         return
      endif
      Modulename = substr( .filename, 1, p - 1)    -- use current file.
      if .modify then
         's'                                       -- Save it if changed.
         if rc then return; endif
      endif
   endif

   -- Check if basename of module was linked before
   lp1 = lastpos( '\', Modulename)
   Name = substr( Modulename, lp1 + 1)
   lp2 = lastpos( '.', Name)
   if lp2 > 1 then
      Basename = substr( Name, 1, lp2 - 1)
   else
      Basename = name
   endif

   UnlinkName = Basename
   linkedrc = linked( Basename)
   if linkedrc < 0 then
      Next = Get_Env( 'NEPMD_ROOTDIR')'\netlabs\ex\'Basename'.ex'
      rc2 = linked( Next)
      if rc2 < 0 then
         Next = Get_Env( 'NEPMD_ROOTDIR')'\epmbbs\ex\'Basename'.ex'
         rc3 = linked( Next)
         if rc3 < 0 then
         else
            linkedrc = rc3
            UnlinkName = Next
         endif
      else
         linkedrc = rc2
         UnlinkName = Next
      endif
   endif

   'etpm' Modulename  -- This is the macro ETPM command
   if rc then return; endif

   -- Unlink and link module if linked
   if linkedrc >= 0 then  -- if linked
      'unlink' UnlinkName   -- 'unlink' gets full pathname now
      if rc < 0 then
         return
      endif
   endif
   if linkedrc >= 0 | fIfLinked = 0 then
      'link' Basename

      if rc >= 0 then
         'PostRelink' Basename
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
defc et, etpm

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
   else
      call parse_filename( InFile, .filename)
   endif
   call parse_filename( ExFile, .filename)
   lp = lastpos( '.', ExFile)
   if lp > 0 then
      if translate( substr( ExFile, lp + 1)) = 'E' then
         ExFile = substr( ExFile, 1, lp - 1)'.ex'
      else
         ExFile = ExFile'.ex'
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

compile if defined(ETPM_CMD)  -- let user specify fully-qualified name
   EtpmCmd = ETPM_CMD
compile else
   EtpmCmd = 'etpm'
compile endif

;   TempFile = vTEMP_PATH'ETPM'substr( ltoa( gethwnd(EPMINFO_EDITCLIENT), 16), 1, 4)'.TMP'
   TempFile = DestDir'\'strip( leftstr( BaseName, 16))'.log'

   Params = '/v 'InFile ExFile' /e 'TempFile

   Os2Cmd = EtpmCmd Params

   -- Must check length here!
   deltalen = length( Os2Cmd) - 224
   if deltalen > 0 then
      sayerror 'Command: 'Os2Cmd
      sayerror 'Error: command is 'deltalen' chars too long. Shorten filename or use an OS/2 or EPM shell window.'
      return
   endif

;   CurDir = directory()
;   call directory('\')
;   call directory(DestDir)  -- change to DestDir first to avoid loading macro files from CurDir

   sayerror COMPILING__MSG infile
   quietshell 'xcom' Os2Cmd
   etpmrc = rc

;   call directory('\')
;   call directory(CurDir)
   rc = etpmrc
   if rc = 0 then
      refresh
      sayerror COMP_COMPLETED__MSG': 'BaseName
   elseif rc = -2 then
      sayerror CANT_FIND_PROG__MSG EtpmCmd
      stop
   elseif rc = 41 then
      sayerror 'ETPM.EXE:' CANT_OPEN_TEMP__MSG '"'TempFile'"'
      stop
   elseif exist( TempFile) then
      call ec_position_on_error(TempFile)
      rc = etpmrc
   else
      sayerror 'ETPM.EXE returned rc = 'etpmrc' for "'Os2Cmd'"'
      rc = etpmrc
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
      'Restart closeother'
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
   ListFiles = ''
   rest = Path
   do while rest <> ''
      parse value rest with next';'rest
      -- Search in every piece of Path for .lst files
      FileMask = next'\*.lst'
      Handle   = ''    -- always create a new handle!
      ListFile = ''
      do while NepmdGetNextFile( FileMask, Handle, ListFile)
         -- Append if not already in list
         if pos( upcase(ListFile)';', upcase(ListFiles)';') = 0 then
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
; Could become a problem: the ini entry for epm\EFileTimes has currently
; 1101 byte. In ETK every string is limited to 1599 byte.
;
; Syntax: RecompileNew [RESET] | [CHECKONLY] [NOMSG] [NOMSGBOX]
;
; Minor bug:
;    o  User macros are never deleted, even if they are equal.
defc RecompileNew
   universal nepmd_hini
   universal vepm_pointer

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

   mouse_setpointer WAIT_POINTER
   NepmdRootDir = Get_Env('NEPMD_ROOTDIR')
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   UserDirName = substr( NepmdUserDir, lastpos( '\', NepmdUserDir) + 1)
   call MakeTree( NepmdUserDir)
   call MakeTree( NepmdUserDir'\ex')
   CompileDir   = NepmdUserDir'\ex\tmp'
   LogFile      = NepmdUserDir'\ex\recompilenew.log'
   if Exist( LogFile) then
      call EraseTemp( LogFile)
   endif

   if not fReset then
      if fCheckOnly then
         WriteLog( LogFile, '"RecompileNew CheckOnly" started at' Date Time', no .EX file will be replaced.')
      else
         WriteLog( LogFile, '"RecompileNew" started at' Date Time'.')
      endif
   endif

   Path = Get_Env('EPMEXPATH')
   ListFiles = ''
   BaseNames = ReadMacroLstFiles( Path, ListFiles)
   -- Auto-add currently linked files to MYEXFILES.LST, if not already added
   AddBaseNames = AutoAddToMacroLstFile()
   if AddBaseNames <> '' then
      WriteLog( LogFile, '')
      WriteLog( LogFile, 'Added the following basenames to 'NepmdUserDir'\ex\myexfiles.lst:')
      Rest = AddBaseNames
      do while Rest <> ''
         parse value Rest with Next';'Rest
         WriteLog( LogFile, '   'Next)
      enddo
   endif

   BaseNames = BaseNames''AddBaseNames

   if not fReset then
      WriteLog( LogFile, '')
      WriteLog( LogFile, 'Checking existing user .EX files and included .E files...')
      WriteLog( LogFile, 'W = warning')
      WriteLog( LogFile, 'R = relinked/recompiled/new')
      WriteLog( LogFile, 'D = deleted')
      WriteLog( LogFile, 'E = error')
   endif
   fRestartEpm  = 0
   fFoundMd5Exe = '?'
   Md5Exe       = ''
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
      fCompCurExFile = 0
      fCompExFile    = 0
      fReplaceExFile = 0
      fDeleteExFile  = 0
      fCopiedExFile  = 0
      fHeaderWritten = 0
      CurEFiles         = ''
      CurEFileTimes     = ''
      CurExFileTime     = ''
      AddEFiles         = ''
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
      LastCheckTime = NepmdQueryConfigValue( nepmd_hini, KeyPath1)

      NetlabsExFile = NepmdRootDir'\netlabs\ex\'BaseName'.ex'
      -- Get full pathname, also used for linked() and unlink
      CurExFile = FindExFile( BaseName)
      if CurExFile = '' then
         CurExFile = BaseName
         fReplaceExFile = 1
      else
         -- Get time of ExFile
         CurExFileTime = NepmdQueryPathInfo( CurExFile, 'MTIME')
         if not rc then
            next = NepmdQueryConfigValue( nepmd_hini, KeyPath2)
            if next <> CurExFileTime then
               fCompExFile = 1
            else

               -- Compare (maybe user's) ExFile with netlabs ExFile to delete it or to give a warning if older
               NetlabsExFile = NepmdRootDir'\netlabs\ex\'BaseName'.ex'
               NetlabsExFileTime = NepmdQueryPathInfo( NetlabsExFile, 'MTIME')
               if not rc then
                  if upcase(CurExFile) <> upcase(NetlabsExFile) then  -- if different pathnames
                     fCompCurExFile = 1
                  endif

                  if fCompCurExFile = 1 then
                     if fFoundMd5Exe = '?' then
                        -- Search for MD5.EXE only once to give an error message
                        findfile next, 'md5.exe', 'PATH'
                        if rc then
                           findfile next, 'md5sum.exe', 'PATH'
                        endif
                        if rc then
                           fFoundMd5Exe = 0
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'E  MD5.EXE or MD5SUM.EXE not found in PATH')
                        else
                           fFoundMd5Exe = 1
                           Md5Exe = next
                        endif
                     endif
                     if fFoundMd5Exe = 1 then
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   comparing current .EX file "'CurExFile'"')
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   with Netlabs .EX file')
                        comprc = Md5Comp( CurExFile, NetlabsExFile, Md5Exe)
                        delrc = ''
                        if comprc = 0 then
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   current .EX file "'CurExFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is equal to Netlabs .EX file')
                           if not fCheckOnly then
                              delrc = EraseTemp( CurExFile)
                              if delrc then
                                 cWarning = cWarning + 1
                                 WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  cannot delete current .EX file "'CurExFile'", rc = 'delrc)
                              else
                                 WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'D  deleted current .EX file "'CurExFile'"')
                                 cDelete = cDelete + 1
                              endif
                           endif
                        endif
                        if comprc <> 0 | (comprc = 0 & delrc) then
                           if LastCheckTime < max( CurExFileTime, NetlabsExFileTime) then
                              fCompExFile = 1
                           endif
                           if CurExFileTime < NetlabsExFileTime then
                              WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  current .EX file "'CurExFile'"')
                              WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is older than Netlabs .EX file')
                              cWarning = cWarning + 1
                           endif
                        endif
                     endif  -- fFoundMd5Exe = 1
                  endif  -- fCompCurExFile = 1

               endif  -- rc = ''

            endif
         endif

      endif

      -- Check E files, if ETPM should not be called already
      if fReplaceExFile <> 1 then

         -- Get list of EFiles from NEPMD.INI
         CurEFiles = NepmdQueryConfigValue( nepmd_hini, KeyPath3)
         -- Get list of times for EFiles from NEPMD.INI
         CurEFileTimes = NepmdQueryConfigValue( nepmd_hini, KeyPath4)

         if CurEFiles = '' then
            fCompExFile = 1
         else

            -- Append optional E files (user may have added them since last check)
            orest = OptEFiles
            do while orest <> ''
               parse value orest with next';'orest
               if pos( ';'upcase( next)';', ';'upcase( CurEFiles''AddEFiles)) = 0 then
                  AddEFiles = AddEFiles''next';'
               endif
            enddo
            if upcase( BaseName) = 'EPM' then
               orest = OptEpmEFiles
               do while orest <> ''
                  parse value orest with next';'orest
                  if pos( ';'upcase( next)';', ';'upcase( CurEFiles''AddEFiles)) = 0 then
                     AddEFiles = AddEFiles''next';'
                  endif
               enddo
            endif

            erest = CurEFiles''AddEFiles
            trest = CurEFileTimes
            do while erest <> ''
               -- For every EFile...
               parse value erest with EFile';'erest
               parse value trest with CurEFileTime';'trest
               EFileTime        = ''
               NetlabsEFileTime = ''
               -- Get full pathname
               FullEFile = FindFileInList( EFile, Get_Env( 'EPMMACROPATH'))

               if FullEFile = '' then
                  -- EFile doesn't exist
                  if pos( ';'upcase( EFile)';', ';'upcase( CurEFiles)) > 0 then
                     -- EFile was deleted and previously added to EFiles
                     fCompExFile = 1
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .E file "'EFile'"')
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   was deleted since last check')
                  endif
               else
                  -- Get time of EFile
                  EFileTime = NepmdQueryPathInfo( FullEFile, 'MTIME')
                  if not rc then
                     -- Compare time of EFile with LastCheckTime and CurExFileTime
                     if not fCheckOnly then
                        if EFileTime > max( LastCheckTime, CurExFileTime) then
                           fCompExFile = 1
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .E file "'FullEFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is newer than last check')
                           --leave  -- don't leave to enable further warnings
                        elseif (CurEFileTime = '') & (pos( ';'upcase( EFile)';', ';'upcase( OptEFiles)) > 0) then
                           --WriteBasenameLog( LogFile, Basename, fHeaderWritten, '         'BaseName' - .E file "'FullEFile'" is an optional file and probably not included')
                        elseif EFileTime <> CurEFileTime then
                           fCompExFile = 1
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .E file "'FullEFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is newer or older compared to last check of this .E file')
                           --leave  -- don't leave to enable further warnings
                        endif
                     endif
                     -- Compare time of (maybe user's) EFile with netlabs EFile to give a warning if older
                     NetlabsEFile = NepmdRootDir'\netlabs\macros\'EFile
                     NetlabsEFileTime = NepmdQueryPathInfo( NetlabsEFile, 'MTIME')
                     if not rc then
                        if EFileTime < NetlabsEFileTime then
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  .E file "'FullEFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is older than Netlabs .E file')
                           cWarning = cWarning + 1
                        endif
                     endif
                  endif  -- ret = ''
               endif  -- FullEFile = ''
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
               EFileTime = NepmdQueryPathInfo( FullEFile, 'MTIME')
               NewEFileTimes = NewEFileTimes''EFileTime';'
               -- Check E files here (after etpm) if not already done above
               if CurEFiles = '' then
                  -- Compare time of (maybe user's) EFile with netlabs EFile to give a warning if older
                  NetlabsEFile = NepmdRootDir'\netlabs\macros\'EFile
                  if upcase( NetlabsEFile) <> upcase( EFile) then
                     NetlabsEFileTime = NepmdQueryPathInfo( NetlabsEFile, 'MTIME')
                     if not rc then
                        if EFileTime < NetlabsEFileTime then
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  .E file "'FullEFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is older than Netlabs .E file')
                           cWarning = cWarning + 1
                        endif
                     endif
                  endif
               endif
            enddo
         else
            rc = etpmrc
            WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'E  ETPM returned rc =' rc)
            mouse_setpointer vepm_pointer
            return rc
         endif
         -- Get time of new ExFile
         NewExFileTime = NepmdQueryPathInfo( ExFile, 'MTIME')
      endif

      if fCompExFile = 1 then
         if fFoundMd5Exe = '?' then
            -- Search for MD5.EXE only once to give an error message
            findfile next, 'md5.exe', 'PATH'
            if rc then
               findfile next, 'md5sum.exe', 'PATH'
            endif
            if rc then
               fFoundMd5Exe = 0
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'E  MD5.EXE or MD5SUM.EXE not found in PATH')
            else
               fFoundMd5Exe = 1
               Md5Exe = next
            endif
         endif
         if fFoundMd5Exe = 1 then
            next = Md5Comp( ExFile, CurExFile, Md5Exe)
            if next = 1 then
               fReplaceExFile = 1
               if NetlabsExFileTime > '' then
                  next2 = Md5Comp( ExFile, NetlabsExFile, Md5Exe)
                  if next2 = 0 then
                     if upcase( CurExFile) <> upcase( NetlabsExFile) then
                        if not fCheckOnly then
                           fDeleteExFile = 1
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .EX file "'ExFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current but equal to Netlabs .EX file')
                        else
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  .EX file "'ExFile'"')
                           WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current but equal to Netlabs .EX file')
                           cWarning = cWarning + 1
                        endif
                     endif
                  else
                     if not fCheckOnly then
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .EX file "'ExFile'"')
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current and Netlabs .EX file')
                     else
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  .EX file "'ExFile'"')
                        WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current and Netlabs .EX file')
                        cWarning = cWarning + 1
                     endif
                  endif
               else
                  if not fCheckOnly then
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .EX file "'ExFile'"')
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current .EX file')
                  else
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  .EX file "'ExFile'"')
                     WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is different from current .EX file')
                     cWarning = cWarning + 1
                  endif
               endif
            elseif next = 0 then
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   .EX file "'ExFile'"')
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   is equal to current .EX file')
            else
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'E  MD5Comp returned rc = 'next)
            endif
         endif
      endif

      -- Don't unlink, delete or copy if Checkonly is active
      if fReplaceExFile = 1 & not fCheckOnly then
         DestDir = GetExFileDestDir( ExFile)
         fRelinkDeleted = 0
         if fDeleteExFile = 1 then
            -- Unlink works only for an existing .ex file. Therefore unlink
            -- must come before delete.
            if fRestartEpm = 0 then
               if linked( CurExFile) then
                  -- unlink works only if EX file exists
                  'unlink' CurExFile
                  fRelinkDeleted = 1
               endif
            endif
            -- After unlinking file.ex, EraseTemp is not available at this time
            if isadefproc( 'EraseTemp') then
               rc = EraseTemp( CurExFile)
            else
               quietshell 'del' CurExFile
            endif
            if rc then
               cWarning = cWarning + 1
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  can''t delete .EX file "'CurExFile'", rc = 'rc)
            else
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'D  deleted .EX file "'CurExFile'"')
               cDelete = cDelete + 1
            endif
         else
            quietshell 'copy' ExFile DestDir
            if rc then
               cWarning = cWarning + 1
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'W  can''t copy .EX file to "'DestDir'", rc = 'rc)
            else
               WriteBasenameLog( LogFile, Basename, fHeaderWritten, 'R  copied .EX file to "'DestDir'"')
               fCopiedExFile = 1
            endif
            quietshell 'copy' EtpmLogFile DestDir
            cRecompile = cRecompile + 1
         endif
         if wordpos( upcase( BaseName), RECOMPILE_RESTART_NAMES) then
            -- These EX files are in use, they can't be unlinked,
            -- therefore EPM must be restarted
            fRestartEpm = 1
         elseif fRestartEpm = 0 then
            -- Check if old file is linked. Using BaseName here would check
            -- for the wrong file when it didn't exist before
            if linked( CurExFile) >= 0 | fRelinkDeleted then  -- <0 means error or not linked
               if not fRelinkDeleted  then  -- maybe already unlinked
                  'unlink' CurExFile
               endif
               'link' BaseName
               if rc >= 0 then
                  WriteBasenameLog( LogFile, Basename, fHeaderWritten, '   relinked .EX file')
                  cRelink = cRelink + 1
                  'PostRelink' BaseName
               endif
            endif
         endif
      endif

      -- Don't write new times and files if ExFile needs to be replaced,
      -- but Checkonly is active
      if not fCheckOnly | not fReplaceExFile then
         if NewExFileTime <> '' then
            NepmdDeleteConfigValue( nepmd_hini, KeyPath1)
            NepmdWriteConfigValue( nepmd_hini, KeyPath1, NewExFileTime)
            if fCopiedExFile = 1 then
               NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
               NepmdWriteConfigValue( nepmd_hini, KeyPath2, NewExFileTime)
            elseif fCompExFile = 1 & not fCheckOnly then
               NepmdDeleteConfigValue( nepmd_hini, KeyPath2)
               NepmdWriteConfigValue( nepmd_hini, KeyPath2, CurExFileTime)
            endif
         endif
         if NewEFiles <> '' then
            NepmdDeleteConfigValue( nepmd_hini, KeyPath3)
            NepmdDeleteConfigValue( nepmd_hini, KeyPath4)
            NepmdWriteConfigValue( nepmd_hini, KeyPath3, NewEFiles)
            NepmdWriteConfigValue( nepmd_hini, KeyPath4, NewEFileTimes)
         endif
      endif

   enddo  -- while rest <> ''

   WriteLog( LogFile, copies( '-', 71))

   if fReset then
      if not fNoMsg then
         sayerror 'All RecompileNew entries deleted from NEPMD.INI'
      endif
      mouse_setpointer vepm_pointer
      return 0
   endif

   WriteLog( LogFile, 'SUMMARY:')
   WriteLog( LogFile, '   'cRecompile' file(s) recompiled')
   WriteLog( LogFile, '   'cDelete' file(s) deleted')
   WriteLog( LogFile, '   therefrom')
   WriteLog( LogFile, '   'cRelink' file(s) relinked')
   WriteLog( LogFile, '   'cWarning' warning(s)')
   if fRestartEpm = 1 then
      WriteLog( LogFile, '   restart')
   endif
   WriteLog( LogFile, '')

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

   WriteLog( LogFile, '.LST FILES:')
   WriteLog( LogFile, '   .E/.EX files from the following .LST files were checked:')
   rest = ListFiles
   do while rest <> ''
      parse value rest with next';'rest
      WriteLog( LogFile, '      'next)
   enddo
   WriteLog( LogFile, '')

   WriteLog( LogFile, 'OTHER .E/.EX FILES:')
/*
   WriteLog( LogFile, '   The folowing .EX files were found:')
   WriteLog( LogFile, '      -> Todo: list other EX files here.')
*/
   WriteLog( LogFile, '   To include them here, append the .EX file basenames to')
   WriteLog( LogFile, '   'upcase(UserDirName)'\EX\MYEXFILES.LST. See also the (re)link documentation.')
   WriteLog( LogFile, '')

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
      Cmd = 'postme postme Restart closeother'
   else
      Cmd = ''
   endif
   if not fNoMsgBox then
      args = cWarning cRecompile cDelete cRelink fRestartEpm fCheckOnly
      Cmd = Cmd 'RecompileNewMsgBox' args
   endif
   Cmd = strip( Cmd)
   Cmd
   mouse_setpointer vepm_pointer

   rc = ret

; ---------------------------------------------------------------------------
; Extract basenames for compilable macro files from all LST files
defproc ReadMacroLstFiles( Path, var ListFiles)
   ListFiles = ''
   rest = Path
   do while rest <> ''
      parse value rest with next';'rest
      -- Search in every piece of Path for .lst files
      FileMask = next'\*.lst'
      Handle   = ''  -- always create a new handle!
      ListFile = ''
      do while NepmdGetNextFile( FileMask, Handle, ListFile)
         -- Append if not already in list
         -- Ignore if filename (without path) exists in list
         lp = lastpos( '\', ListFile)
         Name = substr( ListFile, lp + 1)
         if pos( '\'upcase( Name)';', upcase( ListFiles)) = 0 then
            ListFiles = ListFiles''ListFile';'
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
   return BaseNames

; ---------------------------------------------------------------------------
; Basenames can be a ;-separated list. A trailing ; is optional.
; Example: Filename1;Filename2 or Filename1
defproc AddToMacroLstFile( Basenames)
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   ListFile = NepmdUserDir'\ex\myexfiles.lst'

   'xcom e /d' ListFile
   if rc <> 0 & rc <> -282 then  -- if error, -282 = sayerror("New file")
      return
   endif
   getfileid fid
   .visible = 0
   if rc = -282 then
      deleteline
      insertline '; This file contains compilable user macro files. It is read by RecompileNew', .last + 1
      insertline '; and ensures that an EX file is compiled automatically when its E file has', .last + 1
      insertline '; changed. Add one basename per line. A semicolon in column 1 marks a comment.', .last + 1
   endif
   rc = 0
   Rest = Basenames
   do while Rest <> ''
      parse value Rest with Basename';'Rest
      Rest = strip( Rest)
      insertline Basename, .last + 1
   enddo
   -- Quit ListFile
   activatefile fid
   .modify = 0
   'xcom s'
   'xcom q'
   return

; ---------------------------------------------------------------------------
; Returns a ;-separated list of linked user .ex files.
; Adds them to myexfiles.lst.
defproc AutoAddToMacroLstFile
   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   AutolinkDir  = NepmdUserDir'\autolink'  -- search in <UserDir>\autolink first
   ProjectDir   = NepmdUserDir'\project'   -- search in <UserDir>\project second
   UserExDir    = NepmdUserDir'\ex'
   UserExDirs   = AutoLinkDir';'ProjectDir';'UserExDir

   Path = Get_Env('EPMEXPATH')
   ListFiles = ''
   BaseNames = ReadMacroLstFiles( Path, ListFiles)

   -- Search all *.ex files in UserExDirs
   NewUserBasenames = ''
   Rest = UserExDirs
   do while Rest <> ''
      parse value Rest with NextDir';'Rest

      Handle = ''  -- always create a new handle!
      next   = ''
      do while NepmdGetNextFile( NextDir'\*.ex', Handle, next)
         -- Strip path and extension
         lp1 = lastpos( '\', next)
         next = substr( next, lp1 + 1)
         lp2 = lastpos( '.', next)
         Basename = substr( next, 1, lp2 - 1)

         -- Check if module is linked
         linkedrc = linked( Basename)
         if linkedrc < 0 then
            iterate
         -- Check if module is already added to a .lst file
         elseif pos( ';'upcase( BaseName)';', ';'upcase( BaseNames)';') <> 0 then
            iterate
         endif

         -- Append Basename
         NewUserBasenames = NewUserBasenames''Basename';'
      enddo

   enddo

   -- Add it to myexfiles.lst
   if NewUserBasenames <> '' then
      call AddToMacroLstFile( NewUserBasenames)
   endif

   return NewUserBasenames

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
      call MakeTree( CompileDir)
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
   call directory( '\')
   call directory( CompileDir)

   Os2Cmd = 'etpm' Params
   quietshell 'xcom' Os2Cmd
   etpmrc = rc

   call directory( '\')
   call directory( CurDir)

   if not etpmrc then
      --dprintf( 'CallEtpm', '  'BaseName' compiled successfully to 'ExFile)
   elseif etpmrc = -2 then
      sayerror CANT_FIND_PROG__MSG 'ETPM.EXE'
   elseif etpmrc = 41 then
      sayerror 'ETPM.EXE:' CANT_OPEN_TEMP__MSG '"'
   elseif exist( EtpmLogFile) then
      call ec_position_on_error( EtpmLogFile)
   else
      sayerror 'ETPM.EXE returned rc = 'etpmrc' for "'Os2Cmd'"'
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
      DestDir = AutolinkDir
   elseif exist( ProjectDir'\'ExFile) then
      FullExFile = ProjectDir'\'ExFile
   else
      FullExFile = FindFileInList( ExFile, Get_Env( 'EPMEXPATH'))
   endif
   FullExFile = NepmdQueryFullName( FullExFile)
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
   return

; ---------------------------------------------------------------------------
defproc WriteBasenameLog( LogFile, Basename, var fHeaderWritten, Msg)
   if fHeaderWritten = 0 then
      WriteLog( LogFile, copies( '-', 71))
      WriteLog( LogFile, BaseName)
      fHeaderWritten = 1
   endif
   WriteLog( LogFile, Msg)
   return

; ---------------------------------------------------------------------------
; Compare .EX and .E macro files from <UserDir> with those from the NETLABS
; tree.
defc CheckEpmMacros

   NepmdUserDir = Get_Env('NEPMD_USERDIR')
   call MakeTree( NepmdUserDir)
   call MakeTree( NepmdUserDir'\ex')
   call MakeTree( NepmdUserDir'\macros')
   call MakeTree( NepmdUserDir'\autolink')

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

   -- Build RestartList for fRestart
   RestartList = 'EPM.EX'
   do w = 1 to words( RECOMPILE_RESTART_NAMES)
      next = upcase( word( RECOMPILE_RESTART_NAMES, w))
      parse value next with next'.'ext
      next = next'.EX'
      if wordpos( next, RestartList) > 0 then
         iterate
      endif
      if w = words( RECOMPILE_RESTART_NAMES) then
         RestartList = RestartList\n\9'or' next
      else
         RestartList = RestartList','\n\9''next
      endif
   enddo

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
         Text = Text ||             \9'recompilation of 'RestartList\n\n
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
      Style = MB_OKCANCEL + MB_WARNING + MB_DEFBUTTON1 + MB_MOVEABLE
   else
      Text = Text || 'No warning(s) occurred during comparison of 'upcase(UserDirName)' files'
      Text = Text || ' with NETLABS files.'\n\n
      Text = Text || 'If you have added own macro files to your MYEPM tree,'
      Text = Text || ' then they are newer than the files in the NETLABS tree.'
      Text = Text || ' Apparently no old MYEPM files are used.'\n\n
      Text = Text || 'Do you want to load the log file now?'
      Style = MB_OKCANCEL + MB_INFORMATION + MB_DEFBUTTON1 + MB_MOVEABLE
   endif

   Title = 'Checked .E and .EX files from 'upcase(UserDirName)' tree'
   rcx = winmessagebox( Title,
                        Text,
                        Style)
   if rcx = MBID_OK then
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
   endif

