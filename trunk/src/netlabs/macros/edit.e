/****************************** Module Header *******************************
*
* Module Name: edit.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edit.e,v 1.23 2005-08-14 22:07:34 aschn Exp $
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

; Definitions for editing (loading) files.
; See also: SLNOHOST.E/SAVELOAD.E/E3EMUL.E and FILE.E.

/*
Todo:
-  Make disabling of RestorePosFromEa possible *before* calling 'edit'.
*/

; ---------------------------------------------------------------------------
; Load files from a filespec, remove REXX EAs before loading
defproc NepmdLoadFile( Spec, Options)
   universal filestoload
   universal filestoloadmax  -- still used for 'xcom e' and afterload
   if filestoload = '' then
      filestoload = 0
   endif
   if filestoloadmax = '' then
      filestoloadmax = 0
   endif
   RexxEaExtensions = 'CMD ERX'

   Spec = strip( Spec, 'B', '"')

   -- Experimental URL support using wget
   if pos( '://', Spec) > 0 then
      p1 = lastpos( '/', Spec)
      Name = substr( Spec, p1 + 1)
      next = Get_env( 'TMP')
      if next > '' then
         Tmp = next
      else
         next = Get_env( 'TEMP')
         if next > '' then
            Tmp = next
         else
            Tmp = leftstr( directory(), 3)
         endif
      endif
      TmpFile = strip( Tmp, 'T', '\')'\'Name
      if exist( TmpFile) then
         erasetemp( TmpFile)
      endif
      --'os2 wget "'Spec'" -O 'TmpFile'&&start epm /r' TmpFile  -- doesn't wait for fist cmd to end
      --'cmd /c wget "'Spec'" -O 'TmpFile'&&start epm /r' TmpFile
      --'shell wget "'Spec'" -O 'TmpFile'&&start epm /r' TmpFile
      'shell wget "'Spec'" -O 'TmpFile'&&start epm /r ''mc ;quit;e 'TmpFile''''
      stop
   endif

   ContainsWildcard = (pos( '*', Spec) + pos( '?', Spec) > 0);

   -- Resolve wildcards in Spec to delete REXX EAs for every REXX file
   ProcessOnce = 0
   Handle = 0
   do forever
       if not .visible then
          leave
       endif
      if (ContainsWildcard) then
         -- if Spec contains wildcards then find Filenames
         Filename = NepmdGetNextFile( Spec, address( Handle))
         parse value Filename with 'ERROR:'rc
         if rc > '' then
            leave
         endif
         filestoload = filestoload + 1
         filestoloadmax = filestoload
      else
         -- if Spec doesn't contain wildcards then set Filename to enable the
         -- edit command adding a not existing file to the edit ring
         Filename = Spec
         filestoload = 1
         filestoloadmax = filestoload
         ProcessOnce = 1
      endif

      --sayerror 'Spec = 'Spec', Filename = 'Filename
      dprintf( 'EDIT', 'NepmdLoadFile: Spec = 'Spec', Filename = 'Filename)

      -- Remove REXX EAs if extension is found in RexxEaExtensions.
      -- Use the extension here instead of the mode to avoid determining the
      -- mode twice: here and at defload.
      -- Note: The use of array vars containing the fileid to become file-specific
      -- does only work properly at or after defload. Therefore the mode should be
      -- determined at defload.
      p1 = lastpos( '\', Filename)
      p2 = lastpos( '.', Filename)
      if p2 > p1 + 1 then
         Ext = translate( substr( Filename, p2 + 1))
         if wordpos( Ext, RexxEaExtensions) then
            if exist(Filename) then
               --sayerror 'Removing REXX EAs with NepmdLib from 'Filename
               call NepmdDeleteRexxEa( Filename)
            endif
         endif
      endif

      -- NepmdGetMode doesn't work here, because it tries to write the 'mode.'fid
      -- array var. At this time the file is not loaded, so the fileid is not set.
      -- But calling NepmdQueryDefaultMode(Filename) would work.
      -- We should better determine the mode here, save it in a array var with the
      -- .filename as identifier, and replace the identifier with the fileid later
      -- at defload (or replace the array var with the final one).

      /*
      -- Experimental codepage support (the .codepage field var exists, but is not used yet)
      Codepage = NepmdQueryStringEa( Filename, 'EPM.CODEPAGE')
      parse value Codepage with 'ERROR:'rc
      if rc = '' then
         Codepage = upcase(Codepage)
         if Codepage = 'CP1004' then
            Codepage = 'latin-1'
         endif
         -- Note: GNU Recode deletes all EAs
         'dos recode 'Codepage':cp850 'Filename
         -- Delete EA, because it will not be reset on save yet
         --call NepmdDeleteStringEa( Filename, 'EPM.CODEPAGE')
      endif
      */

      if ProcessOnce = 1 then
         leave
      endif
   enddo  -- forever

   -- load the file
   -- add "..." here to enable loading file names with spaces and
   -- use Spec instead of FileName to keep the loading of host files unchanged
   if pos( ' ', Spec) > 0 then
      Spec = '"'Spec'"'
   endif
   call loadfile( Spec, Options)
   loadrc = rc
   -- Set standard rc here. Since in EPM some non-internal commands won't change
   -- the standard rc anymore, the calling 'edit' command will overtake it.
   -- Standard commands that don't change rc (are there more?):
   --    'locate', 'edit'
   -- This is fixed in NEPMD.
   -- The standard commands 'quit', 'save', 'name',... do change rc.
   -- As a result, we can check the rc for the 'edit' cmd now, without having
   -- to use 'xcom edit', which is an internal command.
   rc = loadrc
   return rc

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
; This DEFC EDIT eventually calls the built-in edit command, by calling
; loadfile(), but does additional processing for messy-desk windowing (moves
; each file to its own window), and ends by calling select_edit_keys().
; Parse off each file individually.  Files can optionally be followed by one
; or more commands, each in quotes.  The first file that follows a host file
; must be separated by a comma, an option, or a (possibly null) command.
;
; EPM doesn't give error messages from XCOM EDIT, so we have to handle that for
; it.
define SAYERR = 'sayerror'  -- EPM:  Message box shows all SAYERRORs

;compile if LINK_HOST_SUPPORT & (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL')
; compile if not defined(MVS)
;    MVS = 0
; compile endif
; compile if not defined(E3MVS)
;    E3MVS = 0
; compile endif
; compile if not defined(HOST_LT_REQUIRED)
;    HOST_LT_REQUIRED = 0
; compile endif
;compile endif

defc e, ed, edit, epm=
   universal default_edit_options
compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') & not SMALL
   universal fto                -- Need this passed to loadfile...
compile endif
   universal CurEditCmd
   universal firstloadedfid  -- first file for this edit cmd
   universal firstinringfid  -- first file in the ring

   getfileid startfid  -- save fid of topmost file before current edit cmd
   call NepmdResetHiliteModeList()
   -- Set current edit cmd to let other commands differ between several ways
   -- of file loading.
   -- Other commands, that execute 'Edit', can set this universal var before
   -- and then it will not be overwritten by 'Edit'. Afterload will reset it.
   -- This is currently used for RestorePos and RingWriteFilePosition.
   if CurEditCmd = '' then
      CurEditCmd = 'EDIT'
   endif

   args = strip(arg(1))

   if args = '' then   /* 'edit' by itself goes to next file */
      --nextfile  -- removed to make 'epm /r' only bring an EPM window to the foreground
                  -- instead of switching to the next file in the ring.
      return 0
   endif

   call AddToHistory( 'EDIT', args)

   options = default_edit_options
   parse value '0 0' with files_loaded new_files_loaded new_files not_found bad_paths truncated access_denied invalid_drive error_reading error_opening first_file_loaded
   --  bad_paths     --> Non-existing path specified.
   --  truncated     --> File contained lines longer than 255 characters.
   --  access_denied --> If user tried to edit a subdirectory.
   --  invalid_drive --> No such drive letter
   --  error_reading --> Bad disk(ette).
   --  error_opening --> Path contained invalid name.

   rest = args
   do while rest <> ''
      rest = strip( rest, 'L')
      -- Remove leading ',' from rest
      if substr( rest, 1, 1) = ',' then
         rest = strip( substr( rest, 2), 'L')
      endif
      -- Get first char
      ch = substr( rest, 1, 1)

compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') & not SMALL
 compile if MVS and not HOST_LT_REQUIRED  -- (MVS filespecs can start with '.)
      if 0 then                           -- No-op
 compile else
      if ch = "'" then                    -- Command
 compile endif
compile else
      if ch = "'" then                    -- Command
compile endif
         parse value rest with (ch) cmd (ch) rest
         do while substr( rest, 1, 1) = ch & pos( ch, rest, 2)
            parse value rest with (ch) p (ch) rest
            cmd = cmd || ch || p
         enddo
         CurEditCmd = cmd  -- set universal var to determine later in LOAD.E if pos shall be restored from EA
         cmd

      elseif ch = '/' then       -- Option
         parse value rest with opt rest
         options = options upcase(opt)

      else
         files_loaded = files_loaded + 1  -- Number of files we tried to load
         -- Remove doublequotes
         if ch = '"' then
            p = pos( '"', rest, 2)
            if p then
               filespec = substr( rest, 1, p)
               rest = substr( rest, p + 1)
            else
               sayerror INVALID_FILENAME__MSG
               return
            endif
         else
compile if HOST_SUPPORT & not SMALL
            p  = length(rest) + 1  -- If no delimiters, take to the end.
            p1 = pos( ',', rest); if not p1 then p1 = p; endif
            p2 = pos( '/', rest); if not p2 then p2 = p; endif
            p3 = pos( '"', rest); if not p3 then p3 = p; endif
            p4 = pos( "'", rest); if not p4 then p4 = p; endif
 compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
  compile if MVS
            p4 = p     -- Can't use single quote for commands if allowing MVS files
  compile endif
            p5 = pos( '[', rest); if not p5 then p5 = p; endif  -- Allow for [FTO]
            p = min( p1, p2, p3, p4, p5)
 compile else
            p = min( p1, p2, p3, p4)
 compile endif
            filespec = substr( rest, 1, p - 1)
            if VMfile( filespec, more) then    -- tricky - VMfile modifies file
               if p = p1 then p = p + 1; endif     -- Keep any except comma in string
               rest = more substr( rest, p)
            else
compile endif
               -- Remove ',' from filespec (DOS and VM)
               parse value rest with filespec rest2
               if pos( ',', filespec) then
                  parse value rest with filespec ',' rest
               else
                  rest = rest2
               endif
compile if HOST_SUPPORT & not SMALL
            endif  -- VMfile( filespec, more)
 compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
            if substr( strip( rest, 'L'), 1, 1) = '[' then
               parse value rest with '[' fto ']' rest
            else
               fto = ''                           --  reset for each file!
            endif
 compile endif
compile endif
         endif  -- ch = '"' else (Remove doublequotes)

         call parse_filename( filespec, .filename)

         if (not pos( '"', filespec)) & pos( ' ', filespec) then
            filespec = '"'filespec'"'
         endif

compile if USE_APPEND  -- Support for DOS 3.3's APPEND, thanks to Ken Kahn.
         if not verify( filespec,'\:','M') then
            if not exist(filespec) then
               Filespec = Append_Path(Filespec)||Filespec  -- LAM todo: fixup
            endif
        endif
compile endif

         rc = NepmdLoadFile( filespec, options)

; Todo: rewrite that horrible message stuff:

         if rc = -3 then        -- sayerror('Path not found')
            bad_paths = bad_paths', 'filespec
         elseif rc = -2 then    -- sayerror('File not found')
            not_found = not_found', 'filespec
         elseif rc = -282 then  -- sayerror('New file')
            new_files = new_files', 'filespec
            new_files_loaded = new_files_loaded + 1
         elseif rc = -278 then  --sayerror('Lines truncated') <-- never happens for EPM 6
            getfileid truncid
            do i = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
               if .modify then leave; endif  -- Need to do this if wildcards were specified.
               nextfile
            enddo
            truncated = truncated', '.filename
            .modify = 0
         elseif rc = -5 then  -- sayerror('Access denied')
            access_denied = access_denied', 'filespec
         elseif rc = -15 then  -- sayerror('Invalid drive')
            invalid_drive = invalid_drive', 'filespec
         elseif rc = -286 then  -- sayerror('Error reading file')
            error_reading = error_reading', 'filespec
         elseif rc = -284 then  -- sayerror('Error opening file')
            error_opening = error_opening', 'filespec
         endif  -- rc=-3
         --if first_file_loaded = '' then  -- useless: forever empty at this point
            if rc <> -3   &  -- sayerror('Path not found')
               rc <> -2   &  -- sayerror('File not found')
               rc <> -5   &  -- sayerror('Access denied')
               rc <> -15     -- sayerror('Invalid drive')
               then
               -- If rc = 0, then set first_file_loaded:
               getfileid first_file_loaded
            endif
         --endif  -- first_file_loaded=''
      endif  -- ch = ... (not "cmd")

   enddo  -- while rest <> ''

   if files_loaded > 1 then  -- If only one file, leave E3's message
      if new_files_loaded > 1 then p = 'New files:'; else p = 'New file:'; endif
      multiple_errors = (new_files || bad_paths || not_found || truncated || access_denied || error_reading || error_opening || invalid_drive <>
                         invalid_drive || error_opening || error_reading || access_denied || truncated || not_found || bad_paths || new_files ) &
                   '' <> new_files || bad_paths || not_found || truncated || access_denied || error_reading || error_opening || invalid_drive

      if new_files then $SAYERR NEW_FILE__MSG substr(new_files,2); endif
      if not_found then $SAYERR FILE_NOT_FOUND__MSG':' substr(not_found,2); endif
   else
      multiple_errors = 0
   endif
   if bad_paths then $SAYERR BAD_PATH__MSG':' substr(bad_paths,2); endif
   if truncated then $SAYERR LINES_TRUNCATED__MSG':' substr(truncated,2); endif
   if access_denied then $SAYERR ACCESS_DENIED__MSG':' substr(access_denied,2); endif
   if invalid_drive then $SAYERR INVALID_DRIVE__MSG':' substr(invalid_drive,2); endif
   if error_reading then $SAYERR ERROR_READING__MSG':' substr(error_reading,2); endif  -- __MSGs were
   if error_opening then $SAYERR ERROR_OPENING__MSG':' substr(error_opening,2); endif  -- exchanged
   if multiple_errors then
      messageNwait(MULTIPLE_ERRORS__MSG)
   endif

   dprintf( 'EDIT', 'arg(1) = ['arg(1)'], first_file_loaded = ['first_file_loaded'], ['first_file_loaded.filename']')
   -- If 1 or more files are loaded by the current edit cmd (or if loadfile has returned rc = 0):
   if first_file_loaded <> '' then

      -- activatefile is now executed in NepmdAfterLoad with postme.
      -- This finally works properly. With activatefile here the ring would get messed.
      --activatefile first_file_loaded
      -- Set fid for NepmdAfterLoad:
      firstloadedfid = first_file_loaded

      -- Initialize firstinringfid if not already set:
      if firstinringfid = '' then
         firstinringfid = firstloadedfid
      endif

      if firstloadedfid = startfid then
         -- If previous topmost file should be loaded again as first loaded file,
         -- check if file was altered by another application.
         -- Note: Required, because no defselect, no defload will be triggered than.
         --       This enables a check for altered-on-disk.
         'ResetDateTimeModified'
         'RefreshInfoLine MODIFIED'
      endif

   endif

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
;  New in EPM.  Edits a file in a different PM window.  This means invoking
;  a completely new instance of E.DLL, with its own window and data.  We do it
;  by posting a message to the executive, the top-level E application.
defc o, open=
compile if WPS_SUPPORT
   universal wpshell_handle
compile endif
   fname = strip(arg(1))                    -- Remove excess spaces
   call parse_filename( fname, .filename)   -- Resolve '=', if any

compile if WPS_SUPPORT
   if wpshell_handle then
      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5159,                   -- EPM_WPS_OPENNEWFILE
                          getpminfo(EPMINFO_EDITCLIENT),
                          put_in_buffer(fname))
   else
compile endif
      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5386,                   -- EPM_EDIT_NEWFILE
                          put_in_buffer(fname),
                          1)                      -- Tell EPM to free the buffer.
compile if WPS_SUPPORT
   endif
compile endif

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
; LAM - Edit a file along the EPATH.  This command will be included if
; the user is including the required routines.  If you've done a
;   SET EPMPATH=d:\EPM;d:\my_emacs;d:\E_macros
; and then do
;   ep stdcmds.e
; that will load this file, just as if you had entered
;   e d:\e_macros\stdcmds.e
; 1994/03/02:  Can specify '.' as the path to use the default, and can
;              include additional arguments for the E command.  E.g.,
;                 ep mycnf.e . '/spell'
defc ep, epath=
   parse arg filename pathname rest
   if pathname = '' | pathname = '.' then
      if filetype(filename) = 'CMD' then
         pathname = 'PATH'
      else
         pathname = EPATH
      endif
   endif
 compile if 0  -- Old way required the optional search_path & get_env routines
   if not exist(filename) then
      filename = search_path_ptr( Get_Env( pathname, 1), filename)filename
   endif
   'e 'filename
 compile else  -- New way uses the built-in Findfile.
   --if pos( '=', filename) & leftstr( filename, 1) <> '"' then
      call parse_filename( filename, substr( .filename, lastpos( '\', .filename) + 1))
   --endif
   findfile newfile, filename, pathname
   if rc then
      newfile = filename
   endif
   'e 'newfile rest
 compile endif

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc op, opath, openpath=
   "open 'ep "arg(1)"'"

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc new
   getfileid startfid
   'xcom e /n'
   if rc <> -282 then return; endif  -- sayerror 'New file'
   getfileid newfid
   activatefile startfid
   temp = startfid  -- temp fix for some bug
   'quit'
   getfileid curfid
   activatefile newfid
   if curfid = startfid then  -- Wasn't quit; user must have said Cancel to Quit dlg
      'xcom quit'
   endif

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc newwindow=
   if leftstr(.filename, 5)='.DOS ' then
      fn = "'"substr(.filename, 6)"'"
compile if WANT_TREE
   elseif .filename = '.tree' then
      parse value .titletext with cmd ': ' args
      fn = "'"cmd args"'"
compile endif
   elseif leftstr( .filename, 14 ) = '.command_shell' then
      shell_dir = directory()
      fn = "'mc +cd "shell_dir" +shell'"
   elseif leftstr( .filename, 1 ) = '.' then  -- other temp file
      fn = ''
   else
      if .modify then
         'save'
         if rc then
            sayerror ERROR_SAVING_HALT__MSG
            return
         endif
      endif
      fn = .filename
      if fn = GetUnnamedFileName() then
         fn = ''
      elseif pos( ' ', fn) then  -- support for spaces in filename
         fn = '"'fn'"'
      endif
      if .readonly then
         fn = '/r' fn
      endif
   endif

   postmc = ''
   if fn > '' then
      call psave_pos( saved_pos )
      -- add arg for 'mc'
      postmc = postmc';restorepos 'saved_pos
   endif
   -- Valid EPM commandline options are always regnized, even when they
   -- are enclosed in '...' to signalize the submitted command part.
   if NepmdGetMode() = 'BIN' then
      -- prepend 'binedit'
      fn = "'binedit "fn"'"
   endif
   if postmc > '' then
      cmd = "open" fn "'postme mc "postmc"'"
      sayerror cmd
      cmd
   else
      'open' fn
   endif
   'quit'

; ---------------------------------------------------------------------------
; Edit binary files in EPM.
; linebreak after 64 chars
;    Program object:
;       Name      : EPM Bin
;       Parameters: 'binedit %*'
defc be, binedit
;   universal default_save_options
   -- Change default options for save command to simply save a bin file
   -- with F2. Therefore this command should be used in a separate EPM
   -- window only.
;   default_save_options = '/ne /ns /nt'
   'HookAdd loadonce tabs 1 noea'
   'HookAdd loadonce tabkey on'
   'HookAdd loadonce matchtab off'
   'HookAdd loadonce mode bin noea'
   'e /t /64 /bin "'arg(1)'"'    -- options should go before filename                    <-- Todo: parse options and filename
                                 -- /64 doesn't work if run from a program object.
   'postme AvoidSaveOptions /e /s /t /o /l'
;   if insert_state() then
;      -- switch to overwrite mode
;      insert_toggle
;   endif

; ---------------------------------------------------------------------------
; linebreak at lineend chars
defc ble, binlineedit
;   universal default_save_options
   -- Change default options for save command to simply save a bin file
   -- with F2. Therefore this command should be used in a separate EPM
   -- window only.
;   default_save_options = '/ne /ns /nt'
   'HookAdd loadonce tabs 1 noea'
   'HookAdd loadonce tabkey on'
   'HookAdd loadonce matchtab off'
   'HookAdd loadonce mode bin noea'
   'e /t /bin "'arg(1)'"'        -- options should go before filename
   'postme AvoidSaveOptions /e /s /t /o /l'
;   if insert_state() then
;      -- switch to overwrite mode
;      insert_toggle
;   endif

; ---------------------------------------------------------------------------
; linebreak at maxmargin
defc bme, binmaxedit
;   universal default_save_options
   -- Change default options for save command to simply save a bin file
   -- with F2. Therefore this command should be used in a separate EPM
   -- window only.
;   default_save_options = '/ne /ns /nt'
   'HookAdd loadonce tabs 1 noea'
   'HookAdd loadonce tabkey on'
   'HookAdd loadonce matchtab off'
   'HookAdd loadonce mode bin noea'
   'e /t /1599 /bin "'arg(1)'"'  -- options should go before filename
   'postme AvoidSaveOptions /e /s /t /o /l'
;   if insert_state() then
;      -- switch to overwrite mode
;      insert_toggle
;   endif

; ---------------------------------------------------------------------------
; Open a file dialog to select a file for binary editing in a new edit
; window. No args.
defc OpenBinDlg
   cmd      = 'be'
   filemask = '*.exe;*.dll'
   title    = 'Select a binary file'
   title    = '"'title'"'  -- filedlg exspects title in "..."
   "o 'filedlg "title" "cmd" "filemask"'"

; ---------------------------------------------------------------------------
; Finds EPM macro files <basename>.e in Dir of arg(1) and EPMMACROPATH.
; Opens listbox to select one file if multiple found.
; <basename> is parsed from arg(1), so arg(1) may have any extension.
; For association with *.ex (type: EX file) and *.e:
;    Program object:
;       Name      : EPM Edit macro file
;       Parameters: /r 'editmacrofile %*'
; From command line:
;    start epm /r 'editmacrofile <basename>'
; Todo?: handle UNC (\\server\resource) names
defc EditMacroFile

   PathName = 'EPMMACROPATH'
   SearchInDirOfFile = 1

   File = strip(arg(1))
   if File = '' then return; endif
   -- Remove ".."
   len = length(File)
   if substr( File, 1, 1) = '"' & substr( File, len, 1) = '"' then
      File = substr( File, 2, len - 2)
   endif
   if File = '' then return; endif


   -- Get full pathname if exists
   next = NepmdQueryFullName(File)
   parse value next with 'ERROR:'rc
   if rc = '' then
       File = next
   endif

   -- Build MacroFileName
   lp1 = lastpos( '\', File)
   Name = substr( File, lp1 + 1)
   Dir = substr( File, 1, max( 0, lp1 - 1))
   lp2 = lastpos( '.', Name)
   if lp2 = 0 | lp2 = 1 then
      BaseName = Name
   else
      BaseName = substr( Name, 1, max(lp2 - 1, 0))
   endif
   MacroFileName = BaseName'.e'

   Found = 0
   FoundOnlyInDirOfFile = 0
   MacroFileList = ''
   LastMacroFile = ''
   Len = 0

   -- Search MacroFile in dir of File first
   if SearchInDirOfFile = 1 then
      MacroFile = Dir'\'MacroFileName
      if NepmdFileExists(MacroFile) then
         Found = Found + 1
         Len = max( Len, length(MacroFile))
         FoundOnlyInDirOfFile = 1
         MacroFileList = MacroFileList''\1''MacroFile
         LastMacroFile = MacroFile
      endif
   endif

   -- Get value of PathName
   Path = Get_Env(PathName)
   rest = Path
   -- Search in all parts of Path
   do while rest <> ''
      parse value rest with NextPath';'rest
      -- Search in NextPath
      MacroFile = NextPath'\'MacroFileName
      if NepmdFileExists(MacroFile) then
         if upcase(MacroFile) = upcase(LastMacroFile) then
            FoundOnlyInDirOfFile = 0
            iterate
         endif
         Found = Found + 1
         Len = max( Len, length(MacroFile))
         MacroFileList = MacroFileList''\1''MacroFile
         LastMacroFile = MacroFile
      endif
   enddo

   if Found = 0 then
      'postme sayerror "'MacroFileName'" not found in directory of "'Name'" or in 'PathName
   elseif Found = 1 then
      -- Use postme here to delay the msg until all other msgs are processed.
      -- Otherwise the last msg would be 'Link completed, module # ?' if a new window
      -- is opened. But sometimes it doesn't work though.
      if FoundOnlyInDirOfFile = 1 then
         'postme sayerror Found macro file "'MacroFileName'" only in directory of "'Name'"'
      else
         'postme sayerror Found 1 macro file "'MacroFileName'" in 'PathName
      endif
      parse value MacroFileList with \1''select
      'e' select
   else
      -- Multiple files found, open listbox
      Title = 'Select macro file 'MacroFileName
         -- Text to appear in 1 line below the title, above the list
         -- Only 1 line (no \13 or \n) allowed in Text, but \9 is recognized.
      if FoundOnlyInDirOfFile = 1 then
         Text = 'Multiple macro files found in directory of "'Name'" and 'PathName'.'
      else
         Text = 'Multiple macro files found in 'PathName'.'
      endif
      TextZ = '  'Text\0    -- add 2 spaces for proper left alignment of text and zero termination
      ItemList = MacroFileList             -- first char is separator
      ButtonList = '/~Edit/~Open/~Cancel'  -- first char is separator, first button is selected
      Selection = 1                        -- selected item of ItemList
      Height = min( Found, 12)             -- make the list max. 12 lines high
      Width  = max( Len, 50)               -- make the list min. 50 ??? wide
      refresh  -- Add everytime a refresh before opening a listbox.
               -- Otherwise sometimes only a part of it is shown.
      select = listbox( Title,
                        ItemList,
                        ButtonList,        -- buttons
                        5, 5,              -- Top, Left,
                        Height, Width,     -- Height, Width,
                        gethwnd(APP_HANDLE) || atoi(Selection) || atoi(1) || atoi(0) ||
                        TextZ )
      parse value select with button 2 select \0  -- get button and (select = selected item)
      select = strip( select, 'B', \1)  -- sometimes the returned value for Cancel is \1
      if select = '' then               -- Cancel ==> no item is returned
         return
      elseif button = \1 then           -- Button1
         'e' select
      elseif button = \2 then           -- Button2
         'o' select
      endif
   endif
   return

; ---------------------------------------------------------------------------
; unused
; Moved from STDCTRL.E
defc edit_list =
   getfileid startfid
   firstloaded = startfid
   parse arg list_sel list_ofs .
   orig_ofs = list_ofs
   do forever
      list_ptr = peek( list_sel, list_ofs, 4)
      if list_ptr == \0\0\0\0 then leave; endif
      fn = peekz(list_ptr)
      if pos( ' ', fn) then
         fn = '"'fn'"'
      endif
      'e' fn
      list_ofs = list_ofs + 4
      if startfid = firstloaded then
         getfileid firstloaded
      endif
   enddo
compile if 1  -- Now, the macros free the buffer.
   call buffer( FREEBUF, list_sel)
compile else
   call windowmessage( 1,  getpminfo(EPMINFO_OWNERCLIENT),   -- Send message to owner client
                       5486,               -- Tell it to free the buffer.
                       mpfrom2short( list_sel, orig_ofs),
                       0)
compile endif
   activatefile firstloaded

; ---------------------------------------------------------------------------
; A common routine to parse a DOS file name.  Optional second argument
; gives source for = when used for path or fileid.  RC is 0 if successful, or
; position of "=" in first arg if no second arg given but was needed.
; New: Quotes, doublequotes and spaces are handled correctly.
;      Avoid duplicated '\' between path and name.
;      Environment vars are resolved.
;      ?: is replaced with the bootdrive.
;      Works now with temp files (starting with '.') as well.
; Currently this proc is only called if filename contains '='. This check
; has to be removed in order to resolve environment vars.
defproc parse_filename( var filename)

   sourcefile = strip(arg(2))
   p = pos( '=', filename)
   if sourcefile = '' then  -- syntax error
      return p              -- strange rc!
   endif

   -- resolve every word separately
   rest = filename
   resolved = ''
   do while rest <> ''
      if leftstr( rest, 1) = "'" then
         -- resolve quoted wrd
         parse value rest with "'"wrd"'" rest
         -- parse wrd again without the quotes (wrd may contain multiple wrds)
         call parse_filename( wrd, sourcefile)
         resolved = resolved" '"wrd"'"
      elseif leftstr( rest, 1) = '"' then
         -- resolve doublequoted wrd
         parse value rest with '"'wrd'"' rest
         -- wrd is ready to resolve '='
         call parse_filename2( wrd, sourcefile)
         resolved = resolved' "'wrd'"'
      else
         -- resolve wrd
         parse value rest with wrd rest
         -- wrd is ready to resolve '='
         call parse_filename2( wrd, sourcefile)
         resolved = resolved' 'wrd
      endif
   enddo
   resolved = strip(resolved)
   filename = resolved
   return 0

; ---------------------------------------------------------------------------
; Resolve '=', '%' and ?: in a single word or word with spaces
defproc parse_filename2( var wrd, sourcefile)

   -- parse sourcefile
   lp1 = lastpos( '\', sourcefile)
   spath = substr( sourcefile, 1, lp1)
   sname = substr( sourcefile, lp1 + 1)
   lp2 = lastpos( '.', sname)
   if lp2 > 1 then
      sbase = substr( sname, 1, lp2 - 1)
   else
      sbase = sname
   endif
   sext  = substr( sname, lp2 + 1)

   -- replace environment variables
   if pos( '%', wrd) then
      wrd = NepmdResolveEnvVars(wrd)
   endif

   -- replace ?: with bootdrive
   do while pos( '?:', wrd) > 0
      parse value wrd with first '?:' rest
      BootDrive = NepmdQuerySysInfo('BOOTDRIVE')
      wrd = first''BootDrive''rest
   enddo

   --replace '='
   if pos( '=', wrd) then
      p = pos( '=', wrd)
      lwrd = substr( wrd, 1, p - 1)
      rwrd = substr( wrd, p + 1)
      -- base'.='     ==> base'.'sext
      -- '=.'ext      ==> sbase'.'ext
      -- '='          ==> sname
      -- '=\'name     ==> name
      -- '='name      ==> name
      -- path'\='     ==> path''sname
      -- path'='      ==> path''sname
      -- path'=.'ext  ==> path''sbase'.'ext
      -- path'\=.'ext ==> path''sbase'.'ext
      if rightstr( wrd, 2) = '.=' then
         wrd = lwrd''sext
      elseif leftstr( wrd, 2) = '=.' then
         wrd = sbase''rwrd
      elseif wrd = '=' then
         wrd = sname
      elseif leftstr( wrd, 2) = '=\' & rwrd <> '' then
         wrd = substr( rwrd, 2)
      elseif leftstr( wrd, 1) = '=' & rwrd <> '' then
         wrd = rwrd
      elseif rightstr( wrd, 2) = '\=' then
         wrd = strip( lwrd, 't', '\')'\'sname
      elseif rightstr( wrd, 2) = '=' then
         wrd = strip( lwrd, 't', '\')'\'sname
      elseif substr( wrd, p, 2) = '=.' & lwrd <> '' & rwrd <> '' then
         wrd = strip( lwrd, 't', '\')'\'sbase''rwrd
      elseif substr( wrd, p - 1, 3) = '\=.' & lwrd <> '' & rwrd <> '' then
         wrd = strip( lwrd, 't', '\')'\'sbase''rwrd
      endif
      -- If resolved wrd doesn't contain ':\' then prepend spath.
      if pos( ':\', wrd) = 0 & pos( '\\', wrd) = 0 then
         wrd = strip( spath, 't', '\')'\'wrd
      endif
   endif
   return

; ---------------------------------------------------------------------------
; This proc is called by defc app, append, put and defc save.
; Wrong: [Does *not* assume all options are specified before filenames.]
; Options must be specified before filename.
defproc parse_leading_options( var rest,var options)
   options = ''
   loop
      parse value rest with wrd more
      if substr( wrd, 1, 1) = '/' then
         options = options wrd
         rest = more
      else
         leave
      endif
   endloop

; ---------------------------------------------------------------------------
; This proc is called by defc app, append, put.
; A common routine to parse an argument string containing a mix of
; options and DOS file specs.  The DOS file specs can contain an "=" for the
; path or the fileid, which will be replaced by the corresponding part of the
; previous file (initially, the current filename).
defproc parse_file_n_opts(argstr)
   prev_filename = .filename
   output = ''
   do while argstr <> ''
      parse value argstr with filename rest
      if leftstr( filename, 1) = '"' then
         parse value argstr with '"' filename '"' argstr
         filename = '"'filename'"'
      else
         argstr = rest
      endif
      if substr( filename, 1, 1) <> '/' then
         call parse_filename( filename, prev_filename)
         prev_filename = filename
      endif
      output = output filename
   end
   return substr( output, 2)

; ---------------------------------------------------------------------------
; Called when the EPM file icon is dropped on another EPM window, while the
; source file is modified.
; We can just execute 'get' to achieve the same result.
; Moved from CLIPBRD.E.
defc insert_text_file
   'get 'arg(1)


