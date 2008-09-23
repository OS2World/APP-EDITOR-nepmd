/****************************** Module Header *******************************
*
* Module Name: backup.e
*
* Copyright (c) Netlabs EPM Distribution Project 2008
*
* $Id: backup.e,v 1.2 2008-09-23 01:42:12 aschn Exp $
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
compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'BACKUP.E'

const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

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
   include 'stdconst.e'

   EA_comment 'This defines macros for backup and autosave operations.'
compile endif

; ---------------------------------------------------------------------------
defc autosave
   universal vautosave_path
   universal vdefault_autosave
   universal ring_enabled
   uparg = upcase(arg(1))
   if uparg = ON__MSG then
      .autosave = vdefault_autosave
   elseif uparg = OFF__MSG then
      .autosave = 0
   elseif isnum(uparg) then
      .autosave = uparg
   elseif uparg = 'DIR' then
      'ListBackupDir'
   elseif uparg = '' then
      'commandline autosave' .autosave
   elseif uparg = '?' then
      if ring_enabled then
         if 6 = winmessagebox( AUTOSAVE__MSG,
                               CURRENT_AUTOSAVE__MSG || .autosave\10 ||
                               NAME_IS__MSG || MakeBakName()\10\10  ||
                               LIST_DIR__MSG,
                               16436)  -- YESNO + MB_INFORMATION + MOVEABLE
            then
           'dir' vAUTOSAVE_PATH
         endif
      else
         call winmessagebox( AUTOSAVE__MSG,
                             CURRENT_AUTOSAVE__MSG || .autosave\10 ||
                             NAME_IS__MSG || MakeBakName()\10\10  ||
                             NO_LIST_DIR__MSG,
                             16432)  -- OK + MB_INFORMATION + MOVEABLE
      endif  -- ring_enabled
      return
   else
      sayerror AUTOSAVE_PROMPT__MSG
      return
   endif  -- uparg = ON__MSG
   sayerror CURRENT_AUTOSAVE__MSG || .autosave', 'NAME_IS__MSG || MakeBakName()

; ---------------------------------------------------------------------------
defc deleteautosavefile
   if .autosave then               -- Erase the tempfile if autosave is on.
      --TempName = MakeTempName()
      TempName = MakeBakName()
      getfileid tempid, TempName  -- (provided it's not in the ring.)
      if tempid = '' then
         call erasetemp(TempName)
      endif
   endif

; ---------------------------------------------------------------------------
; arg(1) = number. Opens dialog if no arg.
defc AutosaveNum
   universal nepmd_hini

   KeyPath = '\NEPMD\User\AutoSave\Number'
   Num = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   CurNum = Num
   NewNum = strip( arg(1))
   if NewNum = '' then
      if Num = '' then
         Num = 100
      endif
      Title = 'Autosave number'
      Text  = 'Number of modifications before file is saved:'
      Text  = Text''copies( ' ', max( 100 - length(Text), 0))
      Entry = Num
      parse value entrybox( Title,
                            '',
                            Entry,
                            0,
                            240,
                            atoi(1) || atoi(0) || atol(0) ||
                            Text) with button 2 NewNum \0
      NewNum = strip( NewNum)
      if button <> \1 then
         return
      endif
   endif
   if NewNum <> CurNum then
      if isnum( NewNum) then
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, NewNum)
         -- Set new .autosave value for all files
         getfileid startfid
         -- Loop through all files in ring
         do f = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
            -- Skip temp. files
            fIgnore = ((leftstr( .filename, 1) = '.') | (not .visible))
            if not fIgnore then
               .autosave = NewNum
            endif
            next_file
            getfileid fid
            if fid = startfid then leave; endif
         enddo
      else
         sayerror 'Autosave number not changed'
         'postme AutosaveNum'
      endif
   endif

; ---------------------------------------------------------------------------
; arg(1) = number. Opens dialog if no arg.
defc BackupNum
   universal nepmd_hini

   KeyPath = '\NEPMD\User\Backup\Number'
   Num = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   CurNum = Num
   NewNum = strip( arg(1))
   if NewNum = '' then
      if Num = '' then
         Num = 10
      endif
      Title = 'Backup number'
      Text  = 'Number of kept backup files:'
      Text  = Text''copies( ' ', max( 100 - length(Text), 0))
      Entry = Num
      parse value entrybox( Title,
                            '',
                            Entry,
                            0,
                            240,
                            atoi(1) || atoi(0) || atol(0) ||
                            Text) with button 2 NewNum \0
      NewNum = strip( NewNum)
      if button <> \1 then
         return
      endif
   endif
   if NewNum <> CurNum then
      if isnum( NewNum) then
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, NewNum)
      else
         sayerror 'Backup number not changed'
         'postme BackupNum'
      endif
   endif

; ---------------------------------------------------------------------------
; arg(1) = Directory. Opens dialog if no arg.
defc BackupDir
   universal nepmd_hini
   universal vtemp_path

   DefaultDir = vtemp_path'nepmd\backup'
   KeyPath = '\NEPMD\User\Backup\Directory'
   Dir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   CurDir = Dir
   NewDir = strip( arg(1))
   if NewDir = '' then
      if Dir = '' then
         Dir = DefaultDir
      endif
      Title = 'Backup directory'
      Text  = 'Enter a fully-qualified or relative directory. Use = for the file''s directory:'
      Text  = Text''copies( ' ', max( 100 - length(Text), 0))
      Buttons = '/~Set/~Reset/Cancel'
      Entry = Dir
      if rightstr( Entry, 2) <> ':\' then
         Entry = strip( Entry, 'T', '\')
      endif
      parse value entrybox( Title,
                            Buttons,
                            Entry,
                            0,
                            240,
                            atoi(1) || atoi(0) || atol(0) ||
                            Text) with button 2 NewDir \0
      NewDir = strip( NewDir)
      if button = \1 then      -- Set
         -- nop
      elseif button = \2 then  -- Reset
         NewDir = DefaultDir
      else                     -- Cancel
         return
      endif
   endif
   if NewDir = '' then
      NewDir = DefaultDir
   endif
   if NewDir <> CurDir then
      call NepmdWriteConfigValue( nepmd_hini, KeyPath, NewDir)
      if substr( NewDir, 2, 1) = ':' then
         rcx = MakeTree( NewDir)
      endif
   endif

; ---------------------------------------------------------------------------
defc ListBackupDir
   universal nepmd_hini

   KeyPath = '\NEPMD\User\Backup\Directory'
   Dir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Dir = '=' then
      if leftstr( .filename, 1) = '.' then
         Dir = directory()
      else
         lp = lastpos( '\', .filename)
         Dir = leftstr( .filename, lp - 1)
         if substr( Dir, 2, 1) = ':' then
            Dir = Dir'\'
         endif
      endif
   endif
   'tree_dir' Dir

; ---------------------------------------------------------------------------
; Procedure to pick a filename for backup purposes, like STDPROCS.E~.
defproc MakeBakName
   universal nepmd_hini
   universal vtemp_path

   FullName = arg(1)
   if FullName = '' then
      FullName = .filename
   endif

   BackupDir = GetBackupDir()

   -- Get backup dir
   if leftstr( BackupDir, 1) = '=' then
      if length( BackupDir > 1) then
         BackupDirRest = strip( substr( BackupDir, 2), 'L', '\')
      else
         BackupDirRest = ''
      endif
      lp = lastpos( '\', FullName)
      if BackupDirRest <> '' then
         BackupDir = leftstr( FullName, lp - 1)'\'BackupDirRest
      else
         BackupDir = leftstr( FullName, lp - 1)
      endif
   elseif substr( BackupDir, 2, 1) <> ':' then  -- a relative name
      lp = lastpos( '\', FullName)
      BackupDir = leftstr( FullName, lp - 1)'\'BackupDir
   endif

   -- Maybe create backup tree
   BackupDir = strip( BackupDir, 'T', '\')
   fCreateDir = 1
   if rightstr( BackupDir, 1) = ':' then
      fCreateDir = 0
   elseif leftstr( BackupDir, 2) = '\\' then
      parse value BackupDir'\' with '\\' MachineName '\' Resource '\' SubDir
      if SubDir = '' then
         fCreateDir = 0
      endif
   endif
   if fCreateDir then
      if not NepmdDirExists( BackupDir) then
         rcx = MakeTree( BackupDir)
      endif
   endif

   -- Get file sys
   FileSys = ''
   if substr( BackupDir, 1, 2) = '\\' then
      FileSys = 'LAN'  -- Assume it's not FAT
   elseif substr( BackupDir, 2, 1) = ':' then
      FileSys = QueryFileSys( leftstr( BackupDir, 2))
   elseif substr( FullName, 2, 1) = ':' then
      FileSys = QueryFileSys( leftstr( FullName, 2))
   endif

   -- Strip path
   lp = lastpos( '\', translate( FullName, '\', '/'))
   if lp > 0 then
      Name = substr( FullName, lp + 1)
   else
      Name = FullName
   endif

   -- Handle FAT names
   if FileSys = 'FAT' | FileSys = '' then
      Name = ConvertToFatName( Name)
   endif

   -- Parse Name into base and ext
   extp = lastpos( '.', Name)
   if extp > 1 then
      base = leftstr( Name, extp - 1)
      ext  = substr( Name, extp + 1)  -- extension without '.'
   else
      base = Name
      ext  = ''
   endif

   -- Append backup postfix to ext
   if FileSys = 'FAT' | FileSys = '' then
      if length( ext) > 1 then
         ext = substr( ext, 1, 1)'~'
      else
         ext = ext'~'
      endif
   elseif ext = '' then
      base = base'~'
   else
      ext = ext'~'
   endif

;   -- We still use MakeTempName() for its handling of host names.
;   bakname = MakeTempName( Name)
;   i = lastpos( '\', bakname)       -- but with a different directory
;   if i then
;      bakname = substr( bakname, i + 1)
;   endif
;   parse value bakname with base'.'.

   -- Prepend backup dir
   if ext = '' then
      NewName = base
   else
      NewName = base'.'ext
   endif
   BackupName = BackupDir'\'NewName
   return BackupName

; ---------------------------------------------------------------------------
; Renames File~(n - 1) to File~n, ..., File~0 to File~1
; and then copies File to File~0.
defproc MakeBackup
   universal nepmd_hini
   rc = 0

   KeyPath = '\NEPMD\User\Backup'
   fBackupEnabled = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   if not fBackupEnabled then
      return 0
   endif

   Name = arg(1)
   if Name = '' then
      Name = .filename
   endif

   if Name = GetUnnamedFilename() then
      -- nop
   elseif leftstr( Name, 1) = '.' then
      return 0
   elseif not Exist( Name) then
      return 0
   endif

   -- Don't backup tmp files, such as cvsa*
   UpFilename = upcase( .filename)
   TmpDirs = Get_env( 'TMP')
   TmpDirs = TmpDirs';'Get_env( 'TEMP')
   TmpDirs = strip( TmpDirs)
   TmpDirs = TmpDirs';'Get_env( 'TEMPDIR')
   TmpDirs = strip( TmpDirs)
   Rest = TmpDirs
   do while Rest <> ''
      parse value Rest with Next';'Rest
      if pos( upcase( Next), UpFilename) then
         return 0
      endif
   enddo

   BackupName = MakeBakName( Name)

   BackupNum = GetBackupNum()

   -- Keep BackupNum backups
   do n = (BackupNum - 1) to 1 by -1
      m = n - 1
      if Exist( BackupName''m) then
         rcx = Move( BackupName''m, BackupName''n)
      endif
   enddo

   rc = CopyFile( Name, BackupName''0)
   return rc

; ---------------------------------------------------------------------------
; Saves current buffer to File~.
defproc MakeAutoSave
   universal nepmd_hini
   rc = 0

   KeyPath = '\NEPMD\User\AutoSave'
   fAutoSaveEnabled = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   if not fAutoSaveEnabled then
      return 0
   endif

   Name = .filename

   if Name = GetUnnamedFilename() then
      -- nop
   elseif leftstr( Name, 1) = '.' then
      return 0
   elseif not Exist( Name) then
      return 0
   endif

   -- Don't autosave tmp files, such as cvsa*
   UpFilename = upcase( .filename)
   TmpDirs = Get_env( 'TMP')
   TmpDirs = TmpDirs';'Get_env( 'TEMP')
   TmpDirs = strip( TmpDirs)
   TmpDirs = TmpDirs';'Get_env( 'TEMPDIR')
   TmpDirs = strip( TmpDirs)
   Rest = TmpDirs
   do while Rest <> ''
      parse value Rest with Next';'Rest
      if pos( upcase( Next), UpFilename) then
         return 0
      endif
   enddo

   AutoSaveName = MakeBakName( Name)

   sayerror AUTOSAVING__MSG
   'postme xcom s' AutoSaveName

   -- Reraise the modify flag.
   .modify = 1  -- Using 1 here doesn't trigger a new modify event
   sayerror 0   -- Delete autosave message

   return rc

; ---------------------------------------------------------------------------
defproc GetAutoSaveNum
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoSave\Number'
   AutoSaveNum = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   return AutoSaveNum

; ---------------------------------------------------------------------------
defproc GetBackupNum
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Backup\Number'
   BackupNum = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   return BackupNum

; ---------------------------------------------------------------------------
defproc GetBackupDir
   universal nepmd_hini
   universal vtemp_path
   KeyPath = '\NEPMD\User\Backup\Directory'
   BackupDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   BackupDir = ResolveEnvVars( BackupDir)
   if BackupDir = '' then
      BackupDir = vtemp_path'nepmd\backup'
   endif
   return BackupDir

; ---------------------------------------------------------------------------
; Unused.
;  Procedure to pick a temporary filename like ORIGNAME.$$1.
;  First argument is the filename, 2nd is the fileid.  Both are optional,
;  default to the current filename and fileid if absent.
;  Revised by BTTUCKER to catch all cases and work with E3EMUL.
defproc MakeTempName
   universal vAUTOSAVE_PATH
   TempName  = arg(1)
   extension = arg(2)
   if TempName = '' then   /* if no arg given, default to current filename */
      TempName = .filename
   endif
   if TempName = '' then
      TempName = '$'       /* new file? o.k. then $  */
   else /* We want only PC file name, VM filename, or MVS firstname          */
        /* These next statements will strip everything else off...           */
     p = lastpos( '\',TempName)                      /* PC filename with path*/
     if p then TempName = substr( TempName, p + 1) endif
     p = pos( '.',TempName)                          /* PC or MVS filename   */
     if p then TempName = substr( TempName, 1, p - 1) endif
     p = pos( ' ', TempName)                         /* VM filename (or HPFS)*/
     if p then TempName = substr( TempName, 1, p - 1) endif
     p = pos( ':', TempName)                         /* VM or MVS filename   */
     if p then TempName = substr( TempName, p + 1) endif
     p = pos( "'", TempName)                         /* MVS filename         */
     if p then TempName = substr( TempName, p + 1) endif
     if length(tempname) > 8 then tempname = substr( tempname, 1, 8); endif  /* HPFS names */
   endif

   -- TempName might still be blank, as for '.Untitled' file.
   if TempName = '' then TempName = '$'; endif

   TempName = vAUTOSAVE_PATH || TempName
   if extension = '' then          /* default is current fileid              */
      getfileid extension
   endif
   /* In EPM we can have the same filename in multiple edit windows without
    * knowing it, because different edit windows are actually separate
    * instances of the editor.  So try to make the tempname unique by
    * combining the window handle with the fileid.  Combine two middle
    * digits of the window handle with the last digit of the fileid.
    */
   extension = substr( getpminfo(EPMINFO_EDITCLIENT), 2, 2) || extension
   if length(extension) > 3 then   /* could be >one digit, or something else */
      extension = substr( extension, 2, 3)
   endif
   return TempName'.'extension

