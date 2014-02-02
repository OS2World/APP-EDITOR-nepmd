/****************************** Module Header *******************************
*
* Module Name: file.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
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

; File commands and procedures.
; Moved from STDCMDS.E, STDPROCS.E.
; See also: SLNOHOST.E/SAVELOAD.E/E3EMUL.E.

; ---------------------------------------------------------------------------

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'FILE.E'

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

   EA_comment 'This defines macros for file operations.'
compile endif

const
-- Include support for calling user exits in DEFMAIN, SAVE, NAME, and QUIT.
-- (EPM 5.51+ only; requires isadefproc() ).
compile if not defined(SUPPORT_USER_EXITS)
   --SUPPORT_USER_EXITS = 0  -- changed by aschn
; #### Todo: obsolete since hooks exist #####################################
   SUPPORT_USER_EXITS = 1
compile endif

compile if not defined(INCLUDE_BMS_SUPPORT)
   INCLUDE_BMS_SUPPORT = 0
compile endif

-- Lets you quit temporary files regardless of the state of the .modify bit.
-- Temporary files are assumed to be any file where the first character of the
-- .filename is a period.  If set to 1, you won't get the "Throw away changes?"
-- prompt when trying to quit one of these files.
compile if not defined(TRASH_TEMP_FILES)
   TRASH_TEMP_FILES = 0
compile endif

; ---------------------------------------------------------------------------
; Called after MB2 dclick on titlebar and Enter.
; Fixed to work with enhanced titletext.
; ProcessName triggers a defselect event.
defc ProcessName
   -- Find (old) .filename in (old) .titletext
   sep = GetFieldSep()
   rest = upcase(.titletext) sep
   filename = upcase(.filename)
   s = 0   -- amount of Seps
   do while rest <> ''
      parse value rest with next (sep) rest
      if strip(next) = strip(filename) then
         leave
      endif
      s = s + 1
   enddo
   -- Remove the other fields from arg(1), parsed at Sep
   rest = arg(1) sep
   do n = 1 to s + 1
      parse value rest with next (sep) rest
      next = strip(next)
      rest = strip(rest)
      if rest = '' then
         leave
      endif
   enddo
   newname = strip(next)
   if newname = '' then
      newname = arg(1)
   endif
   --sayerror 'Filename = ['next']'
   if newname <> '' & newname <> .filename then
compile if defined(PROCESSNAME_CMD)  -- Let the user override this, if desired.
      PROCESSNAME_CMD newname
compile else
      'name' newname
compile endif
   endif

; ---------------------------------------------------------------------------
defc n, name
   -- Name with no args supplies current name.
   if arg(1) = '' then
      'commandline Name '.filename
   else
      if .lockhandle then
         'unlock'
      endif
      oldname = .filename
      autosave_name = MakeTempName()
      call namefile(arg(1))
      if oldname <> .filename then .modify = .modify + 1 endif
      if get_EAT_ASCII_value('.LONGNAME') <> '' then
         call delete_ea('.LONGNAME')
      endif  -- .LONGNAME EA exists
      -- Remove .readonly field if original file was .readonly and new file doesn't exist
      -- (If file exists, then the attrib is re-determined correctly.)
      if .readonly then
         if not Exist(.filename) then
            .readonly = 0
         endif
      endif
      call dosmove(autosave_name, MakeTempName())  -- Rename the autosave file
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
   endif  -- arg(1)=''

; ---------------------------------------------------------------------------
defc rename
   name = .filename
   if name = GetUnnamedFilename() then name = ''; endif
   parse value entrybox( RENAME__MSG,
                         '',
                         name,
                         0,
                         240,
                         -- atoi(1) || atoi(0) || gethwndc(APP_HANDLE) ||
                         atoi(1) || atoi(0) || atol(0) ||
                         RENAME_PROMPT__MSG '<' directory() '>') with button 2 name \0
   if button = \1 & name <> '' then
      'name' name
   endif

; ---------------------------------------------------------------------------
; Handle special NEPMD dirs: don't overwrite files of the NETLABS or EPMBBS
; tree
defproc SaveProcessNetlabsFile( var Name, var SpecifiedName, var fNameChanged)
   rc = 0
   do i = 1 to 1

      RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
      if RootDir = '' then
         sayerror 'Environment var NEPMD_ROOTDIR not set'
         leave
      endif
      UserDir = NepmdScanEnv( 'NEPMD_USERDIR')
      if UserDir = '' then
         sayerror 'Environment var NEPMD_USERDIR not set'
         leave
      endif

      -- RootDir contained in Name?
      if not abbrev( upcase( Name), upcase( RootDir)) then
         leave
      endif

      -- Check the following subdir after RootDir in Name
      p1 = length( RootDir)
      p2 = pos( '\', Name, p1 + 2)
      SubDir = substr( Name, p1 + 2, max( p2 - p1 - 2, 0))
      if not wordpos( upcase( SubDir), 'NETLABS EPMBBS') then
         leave
      endif

      refresh
      Title = 'Save: change to user tree'
      Text = Name\n\n                                              ||
             'You''re about to overwrite a file of the NETLABS or' ||
             ' EPMBBS tree. Better use the user tree for your own' ||
             ' files.'\n\n                                         ||
             'Do you want to save it to the user tree?'
      rcx = winmessagebox( Title, Text,
                           MB_YESNOCANCEL + MB_QUERY + MB_DEFBUTTON1 + MB_MOVEABLE)

      if rcx = MBID_NO then
         return 0
      elseif rcx = MBID_YES then
         NewName = UserDir''substr( Name, p2)
         SpecifiedName = NewName
         lp = lastpos( '\', NewName)
         Newdir = leftstr( NewName, lp - 1)
         -- Create tree, if not existing
         rcx = MakeTree( NewDir)

         rcx = SaveAsCheckExist( NewName)
         if rcx then
            return rcx
         endif

         -- First disable most load and select processing for the current
         -- file. Always ensure that they were reenabled after that
         -- command to be ready for processing the next file!
         'DisableLoad'
         'DisableSelect'
         'name' NewName
         if not rc then  -- on success
            Name = .filename
            fNameChanged = 1
            -- The following commands enable all load and select
            -- processing for the current file, because they are
            -- executed before defload and defselect.
            'EnableLoad'
            'EnableSelect'
         else
            -- 'postme' makes the following commands be processed after
            -- defload and defselect are processed. That disables most
            -- load and select processing for the current file.
            'postme EnableLoad'
            'postme EnableSelect'
         endif

         return 0
      else
         return -5  -- sayerror('Access denied')
      endif

   enddo
   return rc

; ---------------------------------------------------------------------------
; Save                               save
; Save (for a tempfile)              open Save-as dialog
; Save <filename>                    save, keep old filename loaded
; Name <filename> followed by Save   save, change to new filename
; call Save( <filename>, 1)          used by SaveAs
defc s, save
   rc = Save( arg(1))

defproc Save
   universal save_with_tabs
   universal default_save_options
   universal nepmd_hini
   universal unnamedfilename
   fNameChanged = 0
   SpecifiedName = arg(1)
   Name = SpecifiedName
   call parse_leading_options( Name, Options)  -- gets and sets Name and Options
   Options = default_save_options Options
   fCalledBySaveAs = (arg(2) = 1)  -- optional 2nd arg to handle call specially

   -- Open file dialog (Save as) if filename starts with a dot, e.g. .Untitled
   fIsTempFile = (leftstr( .filename, 1) = '.')
   if (SpecifiedName = '' | SpecifiedName = unnamedfilename) & fIsTempFile then
      Name = .filename
      if fIsTempFile then
         result = saveas_dlg( Name, Type)  -- gets and sets Name (and sets Type)
         if result <> 0 then
            return result
         endif
         SpecifiedName = Name
         'name' Name
         if not rc then
            Name = .filename
            fNameChanged = 1
         endif
      endif
   endif

   refresh

   -- Set name if not already or resolve it if specified
   if Name = '' then
      Name = .filename
   else
      call parse_filename( Name, .filename)  -- gets .filename and sets Name
   endif

   -- Don't overwrite files of the NETLABS or EPMBBS tree
   if not fIsTempFile & not fCalledBySaveAs then
      rcx = SaveProcessNetlabsFile( Name, SpecifiedName, fNameChanged)
      if rcx then
         return rcx
      endif
   endif

   -- Check for .readonly field
   if SpecifiedName = '' & (browse() | .readonly) then
      if .readonly then
         sayerror READ_ONLY__MSG
      else
         sayerror BROWSE_IS__MSG ON__MSG
      endif
      rc = -5  -- Access denied
      return -5
   endif
   -- Check if readonly file attrib is set although .readonly field is not
   Attr = QueryPathInfo('ATTR')  -- show 'ADSHR' or '-----'
   if substr( Attr, 5, 1) = 'R' then
      sayerror READ_ONLY__MSG
      rc = -5  -- Access denied
      return -5
   endif

   -- Try to unlock file if it is locked (only successful if locked by the current EPM window)
   if .lockhandle then
      'unlock'
   endif

   -- Get mode before saving
   OldMode = GetMode()

   -- Execute pre-save hooks
compile if SUPPORT_USER_EXITS
   if isadefproc('presave_exit') then
      call presave_exit( Name, options, fNameChanged)
   endif
compile endif
compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_presave_exit') then
      call BMS_presave_exit( Name, options, fNameChanged)
   endif
compile endif
   'HookExecute save'
   'HookExecuteOnce saveonce'

   -- Handle EAs
   if .levelofattributesupport bitand 8 then
      'saveattributes'
   endif
   KeyPath = '\NEPMD\User\AutoRestore\CursorPos'
   RestorePos = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if RestorePos = 1 then
      -- Write EPM.POS EA on save
      call psave_pos(save_pos)   -- get current value
      call delete_ea('EPM.POS')  -- that affects only .eaarea, EA is written on file writing
      'add_ea EPM.POS' save_pos  -- that affects only .eaarea, EA is written on file writing
   endif

   -- 4.10:  Saving with tab compression is built in now.  No need for
   -- the make-do proc savefilewithtabs().
   -- 4.10 new feature:  if save_with_tabs is true, always specify /t.
   if save_with_tabs then
      options = '/t' options
   endif

   -- Remove e.g. lineend options that can cause file damage after operations
   -- with removal of lineends like WordProc, SoftWrap, BinEdit.
   options = ProcessAvoidSaveOptions( options)

   -- Do the save
   display -2  -- suppress non-critical errors
   src = savefile( Name, Options)
   rc = src
   display 2

   -- Save failed: Handle filenames on FAT drives or give a better error msg.
   fatsrc = ''
   if src = -285 then  -- ERROR_WRITING_FILE_RC  (E Toolkit)
      -- Why are standard rc values not supported?
      -- 206 ERROR_FILENAME_EXCED_RANGE  File name or extension is greater than 8.3 characters.
      -- 285 ERROR_DUPLICATE_NAME        The name already exists.
      -- save longname to A: gives src = -285
      --sayerror 0  -- suppress first error message from savefile above

      if substr( Name, 2, 1) = ':' then
         FSys = QueryFileSys( substr( Name, 1, 2))
         if FSys = 'FAT' then
            fatsrc = SaveFat( Name, Options)
            src = fatsrc
         endif
      endif

      -- If standard Save failed (and for FAT drives: SaveFat failed as well)
      if fatsrc <> 0 then
         -- Compared to the 'save' cmd, which returns only -285 or 0,
         -- defproc lock returns the (more usable) rc from DosOpen.
         dosopenrc = lock('W')
         if dosopenrc = 0 then
            'unlock'
         elseif dosopenrc = 206 then  -- 206 = ERROR_FILENAME_EXCED_RANGE
            call message( 'Filename exceeds range')
            if fatsrc = '' then    -- UNC name?
               fatsrc = SaveFat( Name, Options)
               src = fatsrc
            endif
            return -5
         elseif dosopenrc = 32 then
            call message( ACCESS_DENIED__MSG '-' MAYBE_LOCKED__MSG) -- Maybe someone locked it.
            return -5
         elseif dosopenrc = 3 then
            call message( 'Path not found')
            return -5
         elseif dosopenrc = 15 then
            call message( 'Drive is not valid')
            return -5
         elseif dosopenrc = 123 then
            call message( 'Illegal character')
            return -5
         elseif dosopenrc = 26 then
            call message( 'Unknown media type')
            return -5
         elseif dosopenrc = 108 then
            call message( 'Drive locked')
            return -5
         else
            call message( 'DosOpen returned rc = 'dosopenrc)
            return -5
         endif  -- dosopenrc
      endif  -- fatsrc

   endif  -- src = -285

   -- Call postsave_exit hooks
compile if SUPPORT_USER_EXITS
   if isadefproc('postsave_exit') then
      call postsave_exit(name, options, fNameChanged, src)
   endif
compile endif
compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_postsave_exit') then
      call BMS_postsave_exit(name, options, fNameChanged, src)
   endif
compile endif

   -- Give success or error message
   if not src & not isoption( Options, 'q') then
      -- Give success msg
      -- Don't overwrite message from FatSave
      if fatsrc = '' then
         call message(SAVED_TO__MSG Name)
      endif
   elseif src=-5 | src=-285 then  --  -5 = 'Access denied'; -285 = 'Error writing file'
      -- Give an improved error msg
      if qfilemode( Name, Attrib) then      -- Error from DosQFileMode
         call message(src)    -- ? Don't know why got Access denied.
      else                    -- File exists:
         -- why not parse all attribs at once to give a usable message?
         if Attrib bitand 16 then
            call message(ACCESS_DENIED__MSG '-' IS_A_SUBDIR__MSG)  -- It's a subdirectory
         elseif Attrib // 2 then                    -- x'01' is on
            call message(ACCESS_DENIED__MSG '-' READ_ONLY__MSG)    -- It's read/only
         elseif Attrib bitand 4 then
            call message(ACCESS_DENIED__MSG '-' IS_SYSTEM__MSG)    -- It's a system file
         elseif Attrib bitand 2 then
            call message(ACCESS_DENIED__MSG '-' IS_HIDDEN__MSG)    -- It's a hidden file
         else                                -- None of the above?
            call message(ACCESS_DENIED__MSG '-' MAYBE_LOCKED__MSG) -- Maybe someone locked it.
         endif
      endif
      rc = src  -- reset, since qfilemode() changed the RC.
   elseif src < 0 then        -- If RC > 0 assume from host save; and
      call message(src)       -- assume host routine gave error msg.
   endif

   -- Revert to .Unnamed if no success and if Name comes from a Save-as dialog
   if src & fNameChanged then
      .filename = GetUnnamedFileName()
   endif

   -- On successs: refresh InfoLines, re-determine mode and add to Save history
   rc = src
   -- The following hasn't happened anymore since some months here:
   --    EPM crashes sometimes on save, after the file is saved. The culprit
   --    has to be searched in the following, preferably on code that cause
   --    many files loaded, like 'ResetMode' or on code that loops through
   --    the ring, like 'AddToHistory SAVE'. Maybe using an extra command
   --    and/or posting the commands may help.
   if src = 0 then

      if fatsrc <> 0 then  -- this is not required if file was reloaded by SaveFat
         'ResetDateTimeModified'
         'RefreshInfoLine MODIFIED FILE'
      endif

      -- Maybe redetermine mode. Better do this mainly only when the name has changed.
compile if 0
      -- No reset required if a value is already present in the EPM EA area
      -- (then the user has already selected that mode)
      ModeEa = get_EAT_ASCII_value( 'EPM.MODE')
      if (fCalledBySaveAs | fNameChanged) & (ModeEa = '') then
         'ResetMode 'OldMode
      endif
compile else
      -- This variant resets the mode always for CMD files without mode EA
      --ContentExtList = '.INI .CMD'
      -- .INI is not required: saved INI files are text ini types
      ContentExtList = '.CMD'
      fContentSetsMode = (wordpos( upcase( rightstr( .filename, 4)), ContentExtList) > 0)
      -- No reset required if a value is already present in the EPM EA area
      -- (then the user has already selected that mode)
      ModeEa = get_EAT_ASCII_value( 'EPM.MODE')
      if (fCalledBySaveAs | fNameChanged | fContentSetsMode) & (ModeEa = '') then
         'ResetMode 'OldMode
      endif
compile endif

      'postme AddToHistory SAVE' .filename

      'HookExecute aftersave'
      'HookExecuteOnce aftersaveonce'

      if upcase( Name) = upcase( Get_Env( 'NEPMD_USERDIR')'\bin\alias.cfg') then
         'postme ShellReadAliasFile'
      endif
   endif

   -- A refresh is required here. Otherwise an ETK MessageBox pops up
   -- with the message 'Error on file saving'. But the file was saved.
   -- This can be reproduced on closing of the EPM window while an unsaved
   -- file (not the current) is in the ring. Then a first ETK MessageBox
   -- lets one save the unsaved file, but the 2nd ETK MessageBox comes
   -- then with the wrong error message.
   -- The refresh statement doesn't suffice. The refresh command does,
   -- while the postme'd version doesn't.
   'refresh'

   -- A defc must use "return myrc" or use "rc = myrc" to set the
   -- global var rc. When "return" is used only, rc would be set to empty.
   -- A defproc may return its own rcx, without overriding the global rc.
   -- BTW: This was turned into a defproc. Therefore the next line is not
   --      required anymore, but the overnext:
   rc = src
   return src

; ---------------------------------------------------------------------------
; Specify a list of save options, that won't get executed on save,
; undependent of the current save options. The command can be executed
; several times, because new options are appended. This feature is
; file-specific, because an array var, containing the file id is used.
defc AvoidSaveOptions
   new = strip( arg(1))
   getfileid fid
   AvoidOptions = GetAVar( 'avoidsaveoptions.'fid)
   do n = 1 to words( new)
      next = word( new, n)
      if wordpos( next, AvoidOptions) = 0 then
         AvoidOptions = AvoidOptions' 'next
      endif
   enddo
   call SetAVar( 'avoidsaveoptions.'fid, strip( AvoidOptions))

; ---------------------------------------------------------------------------
; Remove e.g. /o, /l and /u if array var is set to keep file working after save
defproc ProcessAvoidSaveOptions( options)
   getfileid fid
   AvoidOptions = lowcase( GetAVar( 'avoidsaveoptions.'fid))
   if AvoidOptions > '' then
      options = lowcase(options)
      -- Replace option /u with /l /ne in AvoidOptions
      if wordpos( '/u', AvoidOptions) then
         if not wordpos( '/l', AvoidOptions) then
            AvoidOptions = AvoidOptions' /l'
         endif
         if not wordpos( '/ne', AvoidOptions) then
            AvoidOptions = AvoidOptions' /ne'
         endif
      endif
      -- Replace option /u with /l /ne in Options
      wp = ''
      do while wp <> 0
         wp = wordpos( '/u', options)
         if wp > 0 then
            options = subword( options, 1, wp - 1)' /l /ne 'subword( options, wp + 1)
         endif
      enddo
      -- Process AvoidOptions
      do w = 1 to words( AvoidOptions)
         next = word( AvoidOptions, w)
         wp = ''
         do while wp <> 0
            wp = wordpos( next, options)
            if wp > 0 then
               options = delword( options, wp, 1)
            endif
         enddo
      enddo
   endif
   return options

; ---------------------------------------------------------------------------
defproc ConvertToFatName
   LongName = arg(1)

   InvalidChars = '.+,"/\[]:|<>=;*?'
   InvalidChars = InvalidChars\0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15
   InvalidChars = InvalidChars\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31\32
   ReplaceChars = copies( '_', length( InvalidChars))

   -- Parse into Base and Ext (Ext excludes the dot)
   lp = lastpos( '.', LongName)
   if lp > 1 then
      Base = substr( LongName, 1, lp - 1)  -- at least 1 char
      Ext  = substr( LongName, lp + 1)     -- extension without leading '.'
   else
      Base = LongName
      Ext  = ''
   endif

   -- Maybe shorten Base and Ext to 8.3
   if length( Base) > 8 then
      Base = leftstr( Base, 8)
   endif
   if length( Ext) > 3 then
      Ext  = leftstr( Ext, 3)
   endif

   -- Convert InvalidChars of Base and Ext separately
   Base = translate( Base, ReplaceChars, InvalidChars)
   Ext  = translate( Ext,  ReplaceChars, InvalidChars)

   if Ext > '' then
      ShortName = Base'.'Ext
   else
      ShortName = Base
   endif

   return ShortName

; ---------------------------------------------------------------------------
; Change the submitted long (maybe full) filename into a FAT name and save
; current file. Write .LONGNAME EA.
defproc SaveFat( FullName, Options)

   -- Strip double quotes
   len = length( FullName)
   if substr( FullName, 1, 1) = '"' & substr( Fullname, len, 1) = '"' then
      FullName = substr( FullName, 2, len - 2)
   endif

   -- Parse into PathBsl and LongName
   lp = lastpos( '\', FullName)
   if lp then
      PathBsl = substr( FullName, 1, lp)   -- path with trailing '\'
   else
      PathBsl = ''
   endif
   LongName = substr( FullName, lp + 1)    -- long name without pathbsl

   -- Convert
   ShortName = PathBsl''ConvertToFatName( LongName)
   -- Try again to write the file
   src = savefile( ShortName, Options)
   if not src then
      sayerror 0  -- delete message
      call delete_ea('.LONGNAME')
      'add_ea .LONGNAME' LongName
      NepmdWriteStringEa( ShortName, '.LONGNAME', LongName)
      if rc then
         sayerror 'EA ".LONGNAME" not written to file "'ShortName'"'
      else
         .filename = ShortName

         -- Rewrite .fileinfo to avoid msg "File was altered by another"
         PathName = ShortName\0
         ResultBuf = copies( \0, 30)
         xrc = dynalink32( 'DOSCALLS',      -- dynamic link library name
                           '#223',          -- ordinal value for DOS32QueryPathInfo
                           address( PathName)         ||  -- pathname to be queried
                           atol(1)                    ||  -- PathInfoLevel
                           address( ResultBuf)        ||  -- buffer where info is to be returned
                           atol( length( ResultBuf)))     -- size of buffer
         if not xrc then
            .fileinfo = ResultBuf
            sayerror SAVED_TO__MSG '"'ShortName'". EA ".LONGNAME" set to "'LongName'".'
         else
            src = xrc
            sayerror 'File saved to "'ShortName'", but DosQueryPathInfo returned rc = 'xrc'.'
         endif
      endif
   endif
   return src

; ---------------------------------------------------------------------------
; Syntax: SaveAll
; Save all files of the ring. Discard non-modified and temp files. Reset
; .modify for temp files. Bring unnamed files to the top.
defc SaveAll
   --display -3
   getfileid startfid
   f = 0
   m = 0
   dprintf( 'RINGCMD', 'SaveAll')
   do i = 1 to filesinring()  -- omit hidden files
      Filename = .filename
      IsATempFile = (substr( Filename, 1, 1) = '.')
      IsUnnamed   = (Filename = GetUnnamedFilename())
      if .modify then
         if IsATempFile & not IsUnnamed then
            .modify = 0
         else
            if IsUnnamed then
               refresh
            endif
            m = m + 1
            'save'
            if rc = 0 then
               f = f + 1
            endif
         endif
      endif
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo
   'postme activatefile' startfid
   --'postme display' 3
   if m > 0 then
      sayerror f' file(s) saved'
   else
      sayerror 'No file modified or just temp files in the ring'
   endif
   return

; ---------------------------------------------------------------------------
defc q, quit
   universal firstloadedfid
   universal LoadDisabledFid

   if not .visible then
      'xcom quit'
      return
   endif

   fTempFile = (substr( .filename, 1, 1) = '.')
   fShell    = IsAShell()
   getfileid quitfileid

compile if TRASH_TEMP_FILES
   if fTempFile then  -- a temporary file
      .modify = 0     -- so no "Are you sure?"
   endif
compile endif

   if .keyset = 'SPELL_KEYS' then  -- Dynamic spell-checking is on for this file;
      'dynaspell'                  -- toggle it off.
   endif

   -- Execute user macros
   'HookExecute quit'
   'HookExecuteOnce quitonce'
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

   if fShell then
      'shell_kill'
   else
      call quitfile()
   endif

   if firstloadedfid = quitfileid
      then firstloadedfid = ''
   endif

   -- Don't process ring commands now when Load commands are disabled
   if LoadDisabledFid < 1 then
      call RingSetFileNumber()
      if not fTempFile then
         call RingAutoSavePos()
      endif
   endif

; ---------------------------------------------------------------------------
; Used by defproc quit_file in E3EMUL.E and by defc shell_kill.
defc xcom_quit
   'xcom q'

; ---------------------------------------------------------------------------
; Save and quit.
defc f, file
   universal InfolineRefresh
compile if SUPPORT_USER_EXITS
   universal isa_file_cmd
   isa_file_cmd = 1         -- So user's presave / postsave exits can differentiate...
compile endif
   InfolineRefresh = 0
   's 'arg(1)
compile if SUPPORT_USER_EXITS
   isa_file_cmd = ''
compile endif
   if not rc then
      .modify=0            -- If saved to a different file, turn modify off
      'q'
   endif
   InfolineRefresh = 1

; ---------------------------------------------------------------------------
defproc SaveAsCheckExist( Name)
   rc = 0
   if Exist( Name) then
      Title = SAVE_AS__MSG
      Text = Name\n\n ||
             EXISTS_OVERLAY__MSG
      rcx = WinMessageBox( Title, Text,
                           MB_OKCANCEL + MB_WARNING + MB_MOVEABLE)
      if rcx <> MBID_OK then
         return -5  -- sayerror('Access denied')
      endif
   endif
   return rc

; ---------------------------------------------------------------------------
/*
����������������������������������������������������������������������������Ŀ
� what's it called: saveas_dlg      syntax:   saveas_dlg                     �
�                                                                            �
� what does it do : ask EPM.EXE to pop up its "Save as" dialog box control.  �
�                   This is done by posting a EPM_POPOPENDLG message to the  �
�                   EPM Book window.                                         �
�                                                                            �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Larry M.   6/12/91                                       �
������������������������������������������������������������������������������
*/
defc saveas_dlg
   universal show_longnames
   if .lockhandle then
      'unlock'
   endif
   fAskIfExists = (arg(1) <> 0)-- new optional arg, 0 => no EXIST_OVERLAY__MSG, used by def f2 if SMARTSAVE
   rcx = saveas_dlg( Name, Type, fAskIfExists)
   if rcx = 0 then
      AutosaveName = MakeTempName()
      OldName = .filename
      .filename = Name
      if get_EAT_ASCII_value( '.LONGNAME') <> '' & upcase( OldName) <> upcase( Name) then
         call delete_ea( '.LONGNAME')
      endif
compile if SUPPORT_USER_EXITS
      if isadefproc( 'rename_exit') then
         call rename_exit( OldName, .filename, 1)
      endif
compile endif
compile if INCLUDE_BMS_SUPPORT
      if isadefproc( 'BMS_rename_exit') then
         call BMS_rename_exit( OldName, .filename, 1)
      endif
compile endif
      -- Use a special flag as 2nd arg to bypass the
      -- change-from-netlabs-to-user-tree feature
      call Save( '', 1)
      if rc then  -- Problem saving?
         call dosmove( AutosaveName, MakeTempName())  -- Rename the autosave file
      else
         call erasetemp( AutosaveName)
      endif
   endif

; ---------------------------------------------------------------------------
defproc saveas_dlg( var Name, var Type)
   universal nepmd_hini

   Type = copies( \0, 255)
   if .filename = GetUnnamedFilename() then
      KeyPath = '\NEPMD\User\History\Save'
      Name = Type
      -- Reuse previous dir. Trailing backslash required.
      KeyPath = '\NEPMD\User\History\Save'
      SavedHistory = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      SavedHistory = strip( SavedHistory, 't', \1)
      parse value SavedHistory with LastSavedFile \1 .
      lp = lastpos( '\', LastSavedFile)
      LastSavedPath = leftstr( LastSavedFile, lp)
      Name = leftstr( LastSavedPath, 255, \0)
   else
      FileName = GetFileName()  -- this respects .LONGNAME if activated
      Name = leftstr( FileName, 255, \0)
   endif
   fAskIfExists = (arg(3) <> 0)  -- optional 3rd arg, 0: no EXIST_OVERLAY__MSG, used by def f2 if SMARTSAVE

   rcx = dynalink32( ERES2_DLL,                -- library name
                     'ERESSaveas',              -- function name
                     gethwndc( EPMINFO_EDITCLIENT)  ||
                     gethwndc( APP_HANDLE)          ||
                     address( Name)                 ||
                     address( Type))
   -- Return codes:  0 = OK; 1 = memory problem; 2 = bad string; 3 = couldn't load control from DLL
   if rcx = 2 then      -- File dialog didn't like the .filename;
      Name = copies( \0, 255)  -- try again with no file name
      rcx =  dynalink32( ERES2_DLL,                -- library name
                         'ERESSaveas',              -- function name
                         gethwndc( EPMINFO_EDITCLIENT)  ||
                         gethwndc( APP_HANDLE)          ||
                         address( Name)                 ||
                         address( Type))
   endif
   parse value Name with Name \0
   parse value Type with Type \0
   if Name = '' then
      return -275  -- sayerror('Missing filename')
   endif
   if leftstr( Name, 1) = '"' & rightstr( Name, 1) = '"' then
      Name = substr( Name, 2, length( Name) - 2)
   endif

   FSys = QueryFileSys( substr( Name, 1, 2))
   if FSys = 'FAT' then
      -- Parse into PathBsl and LongName
      lp = lastpos( '\', Name)
      if lp then
         PathBsl = substr( Name, 1, lp)   -- path with trailing '\'
      else
         PathBsl = ''
      endif
      LongName = substr( Name, lp + 1)    -- long name without pathbsl
      -- Convert
      CheckName = PathBsl''ConvertToFatName( LongName)
   else
      CheckName = Name
   endif

   rcx = SaveAsCheckExist( CheckName)
   if rcx then
      return rcx
   endif
   if Type then
      call delete_ea('.TYPE')
      'add_ea .TYPE' Type
   endif
   if .readonly then
      .readonly = 0
   endif
   return rcx

; ---------------------------------------------------------------------------
/*
����������������������������������������������������������������������������Ŀ
� what's it called: opendlg         syntax:   opendlg [EDIT|GET]             �
�                                                                            �
� what does it do : ask EPM.EXE to pop up its internal message box control.  �
�                   This is done by posting a EPM_POPOPENDLG message to the  �
�                   EPM Book window.                                         �
�                   If a file is selected, by default, it will be presented  �
�                   in a new window.  If the 'EDIT' option is specified the  �
�                   file specified will be opened in the active edit window. �
�                                                                            �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Jerry C.   2/27/89                                       �
������������������������������������������������������������������������������
*/
defc opendlg
   universal ring_enabled
   universal app_hini
   universal nepmd_hini

   KeyPath = '\NEPMD\User\StartDir\OpenDlg\Type'
   opt = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   Filename = .filename
   new = -1
   if opt = 1 then
      new = ''
   elseif opt = 2 & pos( ':\', Filename) then
      new = Filename
   endif
   -- Keep, delete or change last selected file.
   -- The Open dialog will start with its dir.
   if new <> -1 then
      call setprofile( app_hini, 'ERESDLGS', 'LASTFILESELECTED', new)
   endif

   if upcase(arg(1)) = 'EDIT' then
      style = 1  -- EDIT
   elseif upcase(arg(1)) = 'GET' then
      style = 2  -- GET
   else
      style = 0  -- OPEN
   endif

   call windowmessage( 0, getpminfo(APP_HANDLE),
                       5126,               -- EPM_POPOPENDLG
                       ring_enabled,
                       style * 65536)  -- OPEN = 0; EDIT = 1; GET = 2

; ---------------------------------------------------------------------------
; Syntax: filedlg title[, cmd[, filemask[, flags]]]
; Open a standard WinFileDlg and execute cmd filename.
; For interaction with EPM REXX commands, the cmd can be specified as
; "SetUserstring" (not case-sensitive). Then the selected filename is set to
; the .userstring field value. It can be extracted with 'extract /userstring'
; and then processed further with userstring.1 by an EPM REXX command.
; Used by:
;    EDIT.E: defc OpenBinDlg
defc filedlg
   if getpminfo(EPMINFO_EDITFRAME) then
      handle = EPMINFO_EDITFRAME
   else                   -- If frame handle is 0, use edit client instead
      handle = EPMINFO_EDITCLIENT
   endif

   parse arg title ',' cmd ',' filemask ',' flags
   title    = strip( title)
   cmd      = strip( cmd)
   filemask = strip( filemask)
   flags    = strip( flags)

   if cmd = '' then
      cmd = 'e'
   endif
   if filemask = '' then
      filemask = '*'
   endif
   if flags = '' then
      flags = 257
   endif

   size  = 328    -- size of FILEDLG struct
   --flags = 257  -- FDS_CENTER + FDS_OPEN_DIALOG
                  -- FDS_MODELESS doesn't work
   /*
   #define FDS_CENTER            0x00000001L /*    1 Center within owner wnd   */
   #define FDS_CUSTOM            0x00000002L /*    2 Use custom user template  */
   #define FDS_FILTERUNION       0x00000004L /*    4 Use union of filters      */
   #define FDS_HELPBUTTON        0x00000008L /*    8 Display Help button       */
   #define FDS_APPLYBUTTON       0x00000010L /*   16 Display Apply button      */
   #define FDS_PRELOAD_VOLINFO   0x00000020L /*   32 Preload volume info       */
   #define FDS_MODELESS          0x00000040L /*   64 Make dialog modeless      */
   #define FDS_INCLUDE_EAS       0x00000080L /*  128 Always load EA info       */
   #define FDS_OPEN_DIALOG       0x00000100L /*  256 Select Open dialog        */
   #define FDS_SAVEAS_DIALOG     0x00000200L /*  512 Select SaveAs dialog      */
   #define FDS_MULTIPLESEL       0x00000400L /* 1024 Enable multiple selection */
   #define FDS_ENABLEFILELB      0x00000800L /* 2048 Enable SaveAs Listbox     */
   #define FDS_NATIONAL_LANGUAGE 0x80000000L /* Reserved for bidirectional     */
   */
   title = title\0
   fileDlg = atol(size) || atol(flags) || copies( \0, 12) ||
               address(title) || copies( \0, size - 24)
   fileDlg = overlay( filemask, fileDlg, 53)  -- Provide a starting path
                                              -- and a filetype filter.
   -- Owner = Desktop: replace gethwndc(handle) with atol(1)
   result = dynalink32( 'PMCTLS', 'WINFILEDLG',
                        atol(1) ||
                        gethwndc(handle) /*atol(1)*/ ||  -- Owner
                        address(fileDlg))
   if result then
      parse value substr( filedlg, 53) with filename \0
      --sayerror 'Button =' ltoa( substr( fileDlg, 13, 4), 10)'; file = "'filename'"'
      Button = ltoa( substr( fileDlg, 13, 4), 10)
      if upcase( cmd) = 'SETUSERSTRING' then
         -- For interaction with .erx files: set selected filename to .userstring
         if Button = 1 & filename <> '' then
            .userstring = filename
         else
            .userstring = ''
         endif
      else
         if Button = 1 & filename <> '' then
            cmd filename
         endif
      endif
   else
      sayerror 'Error: WinFileDlg returned rc =' ltoa( substr( fileDlg, 17, 4), 10)
   endif
   return

; ---------------------------------------------------------------------------
; Lock file only if modified, unlock if .modify = 0
; Todo: disable this if it failed once and for slow drives.
defmodify
   universal nepmd_hini
   if .visible & leftstr( .filename, 1) <> '.' then
      KeyPath = '\NEPMD\User\Lock\OnModify'
      LockOnModify = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if LockOnModify = 1 then
         if .modify > 0 & .lockhandle = 0 & .readonly = 0 then
            'lock'
         elseif .modify = 0 & .lockhandle > 0 then
            'unlock'
         endif
      endif
   endif
   --sayerror '.modify = '.modify', .lockhandle = '.lockhandle', .readonly = '.readonly

; ---------------------------------------------------------------------------
; Can be used to toggle the lock state
defc lock_on_modify
   if wordpos( upcase(arg(1)), '0 OFF') then
      on = 0
   else
      on = 1
   endif
   if .visible & leftstr( .filename, 1) <> '.' then
      if on then
         if .modify > 0 & .lockhandle = 0 & .readonly = 0 then
            'lock'
         endif
      else
         if .lockhandle <> 0 & .readonly = 0 then
            'unlock'
         endif
      endif
   endif

; ---------------------------------------------------------------------------
defc lock
   if arg(1) <> '' then
      'e 'arg(1)
      if rc & rc <> -282 then  --sayerror('New file')
         return 1
      endif
   endif
   if .readonly then
      -- We don't need a msg here
      -- sayerror '"'.filename'" is readonly -- not locked'
   else
      if exist(.filename) then  -- added check for exist to disable 0 byte files created by lock
         rc = lock('W')  -- deny Write
      endif
   endif

; ---------------------------------------------------------------------------
; Syntax: call lock([<deny_mode>])
;         <deny_mode> = 'W' or 'RW', default is 'RW'
/*
   -- from bsedos.h:
   /* DosOpen/DosSetFHandState mode flags */
   #define OPEN_ACCESS_READONLY           0x0000  /* ---- ---- ---- -000 */
   #define OPEN_ACCESS_WRITEONLY          0x0001  /* ---- ---- ---- -001 */
   #define OPEN_ACCESS_READWRITE          0x0002  /* ---- ---- ---- -010 */
   #define OPEN_SHARE_DENYREADWRITE       0x0010  /* ---- ---- -001 ---- */
   #define OPEN_SHARE_DENYWRITE           0x0020  /* ---- ---- -010 ---- */
   #define OPEN_SHARE_DENYREAD            0x0030  /* ---- ---- -011 ---- */
   #define OPEN_SHARE_DENYNONE            0x0040  /* ---- ---- -100 ---- */
   #define OPEN_FLAGS_NOINHERIT           0x0080  /* ---- ---- 1--- ---- */
   #define OPEN_FLAGS_NO_LOCALITY         0x0000  /* ---- -000 ---- ---- */
   #define OPEN_FLAGS_SEQUENTIAL          0x0100  /* ---- -001 ---- ---- */
   #define OPEN_FLAGS_RANDOM              0x0200  /* ---- -010 ---- ---- */
   #define OPEN_FLAGS_RANDOMSEQUENTIAL    0x0300  /* ---- -011 ---- ---- */
   #define OPEN_FLAGS_NO_CACHE            0x1000  /* ---1 ---- ---- ---- */
   #define OPEN_FLAGS_FAIL_ON_ERROR       0x2000  /* --1- ---- ---- ---- */
   #define OPEN_FLAGS_WRITE_THROUGH       0x4000  /* -1-- ---- ---- ---- */
   #define OPEN_FLAGS_DASD                0x8000  /* 1--- ---- ---- ---- */
   #define OPEN_FLAGS_NONSPOOLED          0x00040000
   #define OPEN_SHARE_DENYLEGACY       0x10000000   /* 2GB */
   #define OPEN_FLAGS_PROTECTED_HANDLE 0x40000000
*/
defproc lock
   DenyReadWrite = 146 -- $92 = $80 + $10 + $2 = OPEN_FLAGS_NOINHERIT + OPEN_SHARE_DENYREADWRITE + OPEN_ACCESS_READWRITE
;  DenyWrite     = 160 -- $A0 = $80 + $20 + $0 = OPEN_FLAGS_NOINHERIT + OPEN_SHARE_DENYWRITE + OPEN_ACCESS_READONLY   <-- doesn't work
;  DenyWrite     = 161 -- $A1 = $80 + $20 + $1 = OPEN_FLAGS_NOINHERIT + OPEN_SHARE_DENYWRITE + OPEN_ACCESS_WRITEONLY  <-- works
   DenyWrite     = 162 -- $A1 = $80 + $20 + $2 = OPEN_FLAGS_NOINHERIT + OPEN_SHARE_DENYWRITE + OPEN_ACCESS_READWRITE  <-- works, use this
   DenyMode = upcase(arg(1))
   If DenyMode = '' then
      Deny = DenyReadWrite  -- like in standard EPM
   elseif DenyMode = 'W' then
      Deny = DenyWrite
   elseif DenyMode = 'RW' then
      Deny = DenyReadWrite
   else
      --sayerror 'defproc lock: Unknown arg "'DenyMode'"'
      --return
      Deny = arg(1)
   endif
   file=.filename\0
   newhandle='????'
   actiontaken=atol(1)   -- file exists
   result = dynalink32( 'DOSCALLS',
                        '#273',             -- Dos32Open
                        address(file)         ||
                        address(newhandle)    ||
                        address(actiontaken)  ||
                        atol(0)    ||       -- file size
                        atol(0)    ||       -- file attribute
                        atol(17)   ||       -- open flag; open if exists, else create
                        atol(Deny) ||       -- openmode; deny Read/Write or Write
                        atol(0), 2)
   if result then
      if result = 32 then
         sayerror ACCESS_DENIED__MSG '-' MAYBE_LOCKED__MSG' rc = ERROR_SHARING_VIOLATION.'
         return result
      elseif result = 206 then  -- 206 = ERROR_FILENAME_EXCED_RANGE
         return result
      else
         --messageNwait('DOSOPEN' ERROR__MSG result NOT_LOCKED__MSG)
         return result
      endif
   endif
   if newhandle  = \0\0\0\0 then  -- Handle of 0 - bad news
      newhandle2 = \255\255\255\255
      result = dynalink32( 'DOSCALLS',
                           '#260',      -- Dos32DupHandle
                           newhandle ||
                           address(newhandle2), 2)
      call dynalink32( 'DOSCALLS',      -- free the original handle
                       '#257',          -- Dos32Close
                       newhandle, 2)
      if result then
         messageNwait('DosDupHandle' ERROR__MSG result NOT_LOCKED__MSG)
         return result
      endif
      newhandle = newhandle2
   endif
   .lockhandle=ltoa( newhandle, 10)
   return 0

; ---------------------------------------------------------------------------
defc unlock
   parse arg file
   if file = '' then
      getfileid fileid
   else
      getfileid fileid, file
      if fileid == '' then
         sayerror '"'file'"' DOES_NOT_EXIST__MSG
         return 1
      endif
   endif
   call unlock(fileid)

; ---------------------------------------------------------------------------
defproc unlock(fileid)
   if fileid.lockhandle = 0 then
      sayerror fileid.filename NOT_LOCKED__MSG
      return 1
   endif
   result = dynalink32('DOSCALLS',    -- Free the original handle
                       '#257',                    -- dos32close
                       atol(fileid.lockhandle), 2)
   if result then
      sayerror 'DOSCLOSE' ERROR_NUMBER__MSG result
   else
      fileid.lockhandle = 0
   endif
   return result

; ---------------------------------------------------------------------------
defc Readonly
   uparg = upcase(arg(1))
   if (uparg = ON__MSG or uparg = 1) then
      .readonly = 1
   elseif (uparg = OFF__MSG or uparg = '0') then
      .readonly = 0
   elseif (uparg = '' or uparg = '?') then
      sayerror READONLY_IS__MSG word( OFF__MSG ON__MSG, .readonly + 1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif

; ---------------------------------------------------------------------------
defc ReadonlyAttrib
   uparg = upcase(arg(1))
   if (uparg = ON__MSG or uparg = 1) then
      quietshell 'dos attrib +r "'.filename'"'
   elseif (uparg = OFF__MSG or uparg = '0') then
      quietshell 'dos attrib -r "'.filename'"'
   elseif (uparg = '' or uparg = '?') then
      sayerror 'Read-only file attribute is:' word( OFF__MSG ON__MSG, GetReadOnly() + 1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif

; ---------------------------------------------------------------------------
defc EnableReadonly
   if wordpos( upcase(arg(1)), '0 OFF') then
      on = 0
   else
      on = 1
   endif
   if on then
      .readonly = GetReadonly()
   else
      .readonly = 0
   endif

; ---------------------------------------------------------------------------
; Determine .readonly field from file attribute, if enabled
defc ReadonlyFromAttrib
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Readonly'
   RespectReadonly = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if RespectReadonly then
      -- Get file attributes to set the .readonly field var
      -- If .readonly is set and = 1, then the %M template pattern for the
      -- status bar will show 'Read-only' and disables any modification,
      -- until 'readonly 0' or 'readonly off' is set.
      .readonly = GetReadonly()
   else
      .readonly = 0
   endif

; ---------------------------------------------------------------------------
defproc GetReadonly
   readonly = ''
/*
   -- 1) using NepmdQueryPathInfo
   attr = NepmdQueryPathInfo( .filename, 'ATTR')
   if rc then  -- file doesn't exist
      --sayerror 'Attributes for "'Filename'" can''t be obtained, rc = 'rc
   elseif length(attr) = 5 then
      readonly = (substr( attr, 5, 1) = 'R')
   endif
*/
   -- 2) using qfilemode
   rc = qfilemode( .filename, attrib)  -- DosQFileMode
   if not rc then   -- file exists
      readonly = (attrib // 2)
   endif

   return readonly

; ---------------------------------------------------------------------------
;
; Syntax: Browse off/on/0/1
;
; specifies whether E should allow text to be altered (normal editing mode)
; or whether all text is read-only.
;
; Issuing Browse with '?' or no argument returns the current setting.
;
; The function browse() takes an optional argument 0/1.  It always returns
; the current setting.  So you can query the current setting without changing
; it by giving no argument.
defc browse =
   uparg = upcase(arg(1))
   if (uparg = ON__MSG or uparg = 1) then
      cb = browse(1)
   elseif (uparg = OFF__MSG or uparg = '0') then
      cb = browse(0)
   elseif (uparg = '' or uparg = '?') then
      cb = browse()     -- query current state
      /* jbl 12/30/88:  move msg to this case only, avoid trivial sayerror's.*/
      sayerror BROWSE_IS__MSG word( OFF__MSG ON__MSG, cb + 1)
   else
      sayerror INVALID_ARG__MSG ON_OFF__MSG'/?)'
      stop
   endif

; ---------------------------------------------------------------------------
; Restore cursor position from EPM.POS EA
; Only restore pos if doscmdline/CurEditCmd doesn't position the cursor itself.
; CurEditCmd is set by defc e,ed,edit,epm in EDIT.E or defc recomp in RECOMP.E.
; 1) PMSEEK uses the <filename> 'L <string_to_search>' syntax.
; 2) defc Recompile in src\gui\recompile\recomp.e
;    If CurEditCmd was set to 'SETPOS', then the pos will not be
;    restored from EA 'EPM.POS' at defload (LOAD.E).
;    Usually CurEditCmd is set to doscmdline (MAIN.E), but file
;    loading with DDE doesn't use the 'edit' cmd.
; 3) ACDATASEEKER uses the <filename> '<line_no>' syntax.
const
compile if not defined( NO_RESTORE_POS_WORDS)
   -- no pos restore for these cmds
   NO_RESTORE_POS_WORDS = 'L LOCATE / C CHANGE GOTO SETPOS RESTOREPOS TOP BOT BOTTOM LOADGROUP RESTORERING'
compile endif
compile if not defined( NO_RESTORE_POS_START_STRINGS)
   -- no pos restore if a cmd word starts with these strings
   -- (that handles the '/<search_string>' cmd correctly)
   NO_RESTORE_POS_START_STRINGS = '/'
compile endif

defc RestorePosFromEa
   universal nepmd_hini
   universal RestorePosDisabled
   universal CurEditCmd

   KeyPath = '\NEPMD\User\AutoRestore\CursorPos'
   RestorePos = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if RestorePos = 1 then
      if RestorePosDisabled <> 1 then

         WordList   = upcase( NO_RESTORE_POS_WORDS)
         StringList = upcase( NO_RESTORE_POS_START_STRINGS)
         CurCmd     = upcase( CurEditCmd)
         -- Todo:
         -- 1) This doesn't handle mc cmds yet.

         RestorePosFlag = 1
         do forever
            -- check number command (positions cursor on line)
            if isnum(CurEditCmd) then
               RestorePosFlag = 0
               leave
            endif
            -- check Words
            if wordpos( CurCmd, WordList) > 0 then
               RestorePosFlag = 0
               leave
            endif
            -- check StartStrings
            if RestorePosFlag = 1 then
               do w = 1 to words( StringList)
                  CurString = word( StringList, w)
                  if abbrev( CurCmd, CurString) > 0 then
                     RestorePosFlag = 0
                     leave
                  endif
               enddo
            endif
            leave
         enddo

         -- restore pos if RestorePosFlag = 1
         if RestorePosFlag = 1 then
            save_pos = get_EAT_ASCII_value('EPM.POS')
            if save_pos <> '' then
               call prestore_pos(save_pos)
            endif
         endif

      endif  -- RestorePosDisabled <> 1
   endif  -- RestorePos = 1

; ---------------------------------------------------------------------------
; This doesn't process the ChangeWorkDir case.
defproc cdd
   NewDir = arg(1)
   if NewDir <> '' then
      if substr( NewDir, 2, 1) = ':' then
         NewDrive = substr( NewDir, 1, 2)
         call directory( NewDrive)
      endif
      call directory( NewDir)
   endif

; ---------------------------------------------------------------------------
; Change drive and directory.
defc cdd
   arg1 = arg(1)
   if arg1 <> '' then
      if NepmdDirExists(arg1) = 0 then
         arg1 = leftstr(arg1, lastpos('\', arg1) - 1)
      endif
   endif
   if arg1 <> '' then
      if NepmdDirExists(arg1) = 0 then
         arg1 = ''
      endif
   endif
   if arg1 <> '' then
      if substr( arg1, 2, 1) = ':' then
         NewDrive = substr( arg1, 1, 2)
         call directory( NewDrive)
      endif
      'cd' arg1
   endif

; ---------------------------------------------------------------------------
; Change drive and directory. Release previous directory first (change to
; root dir).
; This should be used e.g. to change the directory on every defselect.
defc xcd
   arg1 = arg(1)
   if arg1 <> '' then
      if substr( arg1, 2, 1) = ':' then
         CurDrive = upcase( substr( directory(), 1, 2))
         NewDrive = upcase( substr( arg1, 1, 2))
         if NewDrive <> CurDrive then
            call directory( '\')
            call directory( NewDrive)
         endif
      endif
   endif
   'cd' arg1

; ---------------------------------------------------------------------------
; Changed: give only a message if called without arg. Remember new
; directory for restoring path, if activated.
defc cd
   universal nepmd_hini
   rc = 0
   arg1 = arg(1)
   if arg1 <> '' then
      NewDir = directory( arg1)  -- returned value is after dir change
      KeyPath = '\NEPMD\User\ChangeWorkDir'
      ChangeWorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if ChangeWorkDir = 1 then
         KeyPath = '\NEPMD\User\ChangeWorkDir\Last'
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, NewDir)
      endif
   else
      sayerror CUR_DIR_IS__MSG directory()
   endif

; ---------------------------------------------------------------------------
; Change drive and directory. Release previous directory first (change to
; root dir). Give a message.
defc CDDlg
   CurDir = directory()
   Title = 'Enter new work directory'
   Text  = CUR_DIR_IS__MSG CurDir
   Text  = Text''copies( ' ', max( 100 - length(Text), 0))
   Entry = ''
   parse value entrybox( Title,
                         '',
                         Entry,
                         0,
                         240,
                         atoi(1) || atoi(0) || atol(0) ||
                         Text) with button 2 NewDir \0
   NewDir = strip( NewDir)
   if button = \1 & NewDir <> '' & NewDir <> CurDir then
      'xcd' NewDir
      if rc then
         sayerror 'Directory not changed. rc = 'rc
      else
         'cd'         -- show current dir
      endif
   endif

; ---------------------------------------------------------------------------
; Helper to set startup dir for WPS objects.
defc StartupDirDlg
   CurStartupDir = RxResult( 'startupdir query')
   Title = 'Enter new startup directory for WPS objects'
   Text  = 'Current startup directory is 'CurStartupDir
   Text  = Text''copies( ' ', max( 100 - length(Text), 0))
   Entry = ''
   parse value entrybox( Title,
                         '',
                         Entry,
                         0,
                         240,
                         atoi(1) || atoi(0) || atol(0) ||
                         Text) with button 2 NewDir \0
   NewDir = strip( NewDir)
   if button = \1 & NewDir <> '' & NewDir <> CurStartupDir then
      'rx startupdir.erx' NewDir
   endif

; ---------------------------------------------------------------------------
; Erasetemp erases a file quietly (no "File not found" message) on both DOS
; and OS/2.  Thanks to Larry Margolis.  Returns 0 if successful erase, or
; the error code (if on DOS) which will usually be 2 for 'file not found'.
defproc erasetemp(filename)
   asciiz = filename\0
   return dynalink32( 'DOSCALLS',          -- dynamic link library name
                      '#259',              -- ordinal value for DOSDELETE
                      address(asciiz) )

; ---------------------------------------------------------------------------
defproc dosmove( oldfile, newfile)
   oldfile = oldfile\0
   newfile = newfile\0
   return dynalink32( 'DOSCALLS',          -- dynamic link library name
                      '#271',              -- Dos32Move - move a file
                      address(oldfile) ||
                      address(newfile), 2)

; ---------------------------------------------------------------------------
; Used in INFOLINE.E.
defproc GetFileDateHex( Filename)
   Filename = Filename\0
   ResultBuf = copies( \0, 30)
   FileDateHex = ''
   rc = dynalink32( 'DOSCALLS',      -- dynamic link library name
                    '#223',          -- ordinal value for DOS32QueryPathInfo
                    address( Filename)         ||  -- pathname to be queried
                    atol(1)                    ||  -- PathInfoLevel
                    address( ResultBuf)        ||  -- buffer where info is to be returned
                    atol( length( ResultBuf)))      -- size of buffer
   if rc = 0 then
      FileDateHex = ltoa( substr( ResultBuf, 9, 4), 16)
      -- The return value can be compared with ltoa( substr( .fileinfo, 9, 4), 16)
      -- to determine if the file's timestamp has changed on disk since defload.
      -- (.fileinfo is set at defload.)
   endif
   return FileDateHex

; ---------------------------------------------------------------------------
; For compatibilty
defproc get_file_date( Filename)
   return GetFileDateHex( Filename)

; ---------------------------------------------------------------------------
; Used in INFOLINE.E.
; Todo: use NLS settings from OS2.INI or USER.DAT if present.
defproc FileDateHex2DateTime( hexstr)
   -- add leading zero if length < 8
   hexstr = rightstr( hexstr, 8, 0)

   date = hex2dec( substr( hexstr, 5, 4))
   year = date%512; date = date//512
   month = date%32; day = date//32%1  -- %1 to drop fraction
;   date = year + 1980'/'rightstr( month, 2, 0)'/'rightstr( day, 2, 0)  -- english date  yyyy/mm/dd
;   date = rightstr( day, 2, 0)'.'rightstr( month, 2, 0)'.'year + 1980  -- german date   dd.mm.yyyy
   date = year + 1980'-'rightstr( month, 2, 0)'-'rightstr( day, 2, 0)  -- ISO date   yyyy-mm-dd

   time = hex2dec( substr( hexstr, 1, 4))
   hour = time%2048; time = time//2048
   min = time%32; sec = time//32*2%1  -- %1 to drop fraction
   time = hour':'rightstr( min, 2, 0)':'rightstr( sec, 2, 0)  -- german time hh:mm:ss

   return date time

; ---------------------------------------------------------------------------
; Returns 1 if file exists, otherwise 0.
defproc Exist( Filename)
   rcx = QFileMode( Filename, Attrib)
   return (rcx = 0)

; ---------------------------------------------------------------------------
; Result must be specified as arg(2), rcx is returned.
defproc QFileMode( Filename, var Attrib)
   if leftstr( Filename, 1) = '"' & rightstr( Filename, 1) = '"' then
      Filename = substr( Filename, 2, length( Filename) - 2)
   endif
   Filename = Filename\0
   Attrib = copies( \0, 24)  -- allocate 24 bytes for a FileStatus3 structure
   rcx = dynalink32( 'DOSCALLS',             -- dynamic link library name
                     '#223',                 -- ordinal value for Dos32QueryPathInfo
                     address( Filename)  ||  -- Pointer to path name
                     atol(1)             ||  -- PathInfoLevel 1
                     address( Attrib)    ||  -- Pointer to info buffer
                     atol(24), 2)            -- Buffer Size
   Attrib = ltoa( rightstr( Attrib, 4), 10)
   return rcx

; ---------------------------------------------------------------------------
; arg(1) = drive, e.g.: X:
; Returns e.g.: HPFS | CDFS | JFS | FAT | LAN | RAMFS | ISOFS | HPFS386 | FAT32 | NDFS32 | NTFS
defproc QueryFileSys( Drive)
   dev_name = Drive\0
   ordinal = 0
   infobuf = substr( '', 1, 255)
   infobuflen = atol( length(infobuf))
   FSAinfolevel = 1
   rc = dynalink32( 'DOSCALLS',              -- dynamic link library name
                    '#277',                  -- ordinal value for Dos32QueryFSAttach
                    address( dev_name)  ||   -- device name
                    atol( ordinal)      ||   --
                    atol( FSAinfolevel) ||   -- info level requested
                    address( infobuf)   ||   -- string offset
                    address( infobuflen), 2) -- length of buffer
   if rc then
      return
   else
      -- For FSAinfolevel 1:
      iType = itoa( substr( infobuf, 1, 2), 10)
           -- 1=resident char. dev.; 2=pseudochar dev.; 3=local drive; 4=remote drive
      cbName = itoa( substr( infobuf, 3, 2), 10)
      cbFSDName = itoa( substr( infobuf, 5, 2), 10)
      cbFSAData = itoa( substr( infobuf, 7, 2), 10)
      parse value substr( infobuf, 9) with szName \0 szFSDName \0 rgFSAData
      rgFSAData = leftstr( rgFSAData, cbFSAData)
      --insertline 'dev='dev_name 'iType=' iType 'cbName='cbName 'cbFSDName='cbFSDName 'cbFSAData='cbFSAData, .last+1
      --insertline '      szName="'szName'" szFSDName="'szfsdname'" rgFSAData="'rgFSAData'"', .last+1
      return szFSDName
   endif

; ---------------------------------------------------------------------------
; Accepts a relative dir name. The parent dir must exist.
defproc MakeDirectory( Dirname)
   DirName = NepmdQueryFullName( DirName)
   Dirname = Dirname\0
   peaop2 = copies( \0, 4)
   rcx = dynalink32( 'DOSCALLS',           -- dynamic link library name
                     '#270',               -- ordinal value for Dos32CreateDir
                     address( Dirname) ||  -- device name
                     peaop2)
   return rcx

; ---------------------------------------------------------------------------
; Maybe overwrites NewFileName.
defproc CopyFile( FileName, NewFileName)
   FileName    = NepmdQueryFullName( FileName)
   NewFileName = NepmdQueryFullName( NewFileName)

   FileName    = FileName\0
   NewFileName = NewFileName\0
   Option = 1  -- Overwrite if exists
   rcx = dynalink32( 'DOSCALLS',           -- dynamic link library name
                     '#258',               -- ordinal value for Dos32Copy
                     address( FileName)    ||
                     address( NewFileName) ||
                     atol( Option))
   --dprintf( 'CopyFile: rc = 'rcx', 'strip( FileName, 't', \0)' -> 'strip( NewFileName, 't', \0))
   return rcx

; ---------------------------------------------------------------------------
; Maybe overwrites NewFileName instead of returning ERROR_ACCESS_DENIED.
defproc Move( FileName, NewFileName)
   FileName    = NepmdQueryFullName( FileName)
   NewFileName = NepmdQueryFullName( NewFileName)

   if Exist( NewFileName) then
      call EraseTemp( NewFileName)
   endif

   FileName    = FileName\0
   NewFileName = NewFileName\0
   rcx = dynalink32( 'DOSCALLS',           -- dynamic link library name
                     '#271',               -- ordinal value for Dos32Move
                     address( FileName)    ||
                     address( NewFileName))
   --dprintf( 'Move: rc = 'rcx', 'strip( FileName, 't', \0)' -> 'strip( NewFileName, 't', \0))
   return rcx

; ---------------------------------------------------------------------------
; Accepts a relative tree name.
defproc MakeTree( DirName)

   -- Remove trailing backslash. Keep it for root dirs to return a better rc.
   do i = 1 to 1
      if rightstr( DirName, 1) <> '\' then
         leave
      elseif DirName = '\' then
         leave
      elseif rightstr( DirName, 2) = ':\' then
         leave
      endif
      DirName = strip( DirName, 't', '\')
   enddo

   DirName = NepmdQueryFullName( DirName)

   rcx = 0
   p = pos( '\', DirName)
   if p = 0 then
      return 13 -- ERROR_INVALID_DATA
   endif
   -- Ignore first backslash
   next = substr( DirName, 1, p - 1)
   rest = substr( DirName, p)

   -- Loop through dir segments. next is the full path
   -- without backslash and rest has a leading backslash.
   fbreak = 0
   do forever
      p = pos( '\', rest, 2)
      if p = 0 then
         next = next''rest
         rest = ''
         fbreak = 1
      else
         next = next''substr( rest, 1, p - 1)
         rest = substr( rest, p)
      endif

      SubDirname = next\0
      peaop2 = copies( \0, 4)
      rcx = dynalink32( 'DOSCALLS',             -- dynamic link library name
                        '#270',                 -- ordinal value for Dos32CreateDir
                        address( SubDirname) || -- device name
                        peaop2)

      -- rcx = 5 (ERROR_ACCESS_DENIED) is returned if dir already exists
      if not wordpos( rcx, '0 5') then
         leave
      endif
      if fbreak then
         leave
      endif
   enddo

   return rcx

; ---------------------------------------------------------------------------
; Reads beginning of a file with a submitted length. Returns it and sets rc.
; Max. length is 512 bytes.
defproc ReadFilePart( File, Len)
   FilePart = ''

   if not NepmdFileExists( File) then
      rc = 2  -- ERROR_FILE_NOT_FOUND
      return
   endif
   if not isnum( Len) | Len < 1 then
      rc = 87  -- ERROR_INVALID_PARAMETER
      return
   endif

   'xcom e /t /512 /bin /d' File

   if rc = 0 then
      .visible = 0
      next = textline(1)
      FilePart = substr( next, 1, Len)
      'xcom quit'
   else
      rc = 5  -- ERROR_ACCESS_DENIED
      return ''
   endif

   return FilePart

; ---------------------------------------------------------------------------
; Checks for signature, returns 1 if found in SigList, 0 if not, '' if error.
; Sets rc. SigList is a space-separated list of signatures.
defproc CheckSig( File, SigList)
   Result = 0
   MaxLen = 0
   do w = 1 to words( SigList)
      Sig = word( SigList, w)
      MaxLen = max( MaxLen, length( Sig))
   enddo

   FileSig = ReadFilePart( File, MaxLen)
   if rc <> 0 then
      return ''
   endif

   do w = 1 to words( SigList)
      Sig = word( SigList, w)
      if leftstr( FileSig, length( Sig)) = Sig then
         Result = 1
         leave
      endif
   enddo

   return Result

