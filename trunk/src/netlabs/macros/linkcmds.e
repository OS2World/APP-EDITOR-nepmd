/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: linkcmds.e,v 1.7 2004-07-02 09:07:57 aschn Exp $
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
; link statement does. This is added here.
defc unlink
   ExFile = arg(1)
   p1 = lastpos( '\', ExFile)
   ExFileName = substr( ExFile, p1 + 1)
   p2 = lastpos( '.', ExFileName)
   if p2 = 0 then
      ExFile = ExFile'.ex'
   endif
   findfile FullPathName, ExFile, '', 'D'  -- search in .;%EPMPATH;%DPATH%
   if rc then                -- if not found
      FullPathName = arg(1)  -- try to unlink arg(1)
   endif
   unlink FullPathName
   if rc then
      if rc = -310 then
         sayerror 'Module "'arg(1)'" not unlinked, unknown module'
      else
         sayerror 'Module "'arg(1)'" not unlinked, rc = 'rc
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

   'etpm' modulename  -- This is the macro ETPM command.
   if rc then return; endif

   lp1 = lastpos( '\', modulename)
   name = substr( modulename, lp1 + 1)
   lp2 = lastpos( '.', name)
   if lp2 > 1 then
      basename = substr( name, 1, lp2 - 1)
   else
      basename = name
   endif

   -- Unlink and link module if linked
   waslinkedrc = linked(basename)
   if waslinkedrc >= 0 then  -- if linked
      'unlink' basename   -- 'unlink' gets full pathname now
      'link' basename
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

   Params = InFile ExFile' /e 'TempFile

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
; This can't handle the /v output of etpm yet.
defproc ec_position_on_error(tempfile)
   'xcom e 'tempfile
   if rc then    -- Unexpected error.
      sayerror ERROR_LOADING__MSG tempfile
      if rc = -282 then 'xcom q'; endif  -- sayerror('New file')
      return
   endif
   if .last <= 4 then
      getline msg, .last
      'xcom q'
   else
      getline msg, 2
      if leftstr( msg, 3) = '(C)' then  -- 5.20 changed output
         getline msg, 4
      endif
      getline temp, .last
      parse value temp with 'col= ' col
      getline temp, .last - 1
      parse value temp with 'line= ' line
      getline temp, .last - 2
      parse value temp with 'filename=' filename
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
   'RingCheckModify'
   'SaveRing'
   "postme Open 'RestoreRing'"
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
      activatefile ListFile
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

