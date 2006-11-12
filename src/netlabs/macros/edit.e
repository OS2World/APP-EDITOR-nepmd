/****************************** Module Header *******************************
*
* Module Name: edit.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edit.e,v 1.42 2006-11-12 13:13:39 jbs Exp $
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
; EPM bug during heavy processing, e.g. file loading:
;
; When too many procs are nested, esp. when changing between C and E code
; permanently, sometimes E or C code will not be executed.
;
; That was first seen when the call of NepmdActivateHighlight suppressed the
; usually following select event after all files are loaded.
; (Instead of letting the C function NepmdActivateHighlight execute the
; toggle_parse command, now NepmdQueryHighlightArgs is used to retrieve
; only the args for toggle_parse. toggle_parse is executed from E code now.)
;
; To workaround that bug, one has to change the code processing:
;
;    o  Try to avoid too many nested procs.
;
;    o  Try to avoid executing E commands from C code.
;
;    o  Split the E code before the critical point to an additional defc.
;       An additional defproc won't help here. Apparently the previous code
;       is always completed, when a new command is executed, at least most
;       of the times. To ensure that any previous code is completed, the
;       additional command must be executed with postme.

; ---------------------------------------------------------------------------
; Slow processing caused by specific code:
;
; The file load processing can easily be slowed down. It is extremely
; vulnerable to following code:
;
;    o   sayerror statement or command
;
;    o   postme command or other posted window messages.
;
; Therefore these should be avoided during file loading, if possible.

; ---------------------------------------------------------------------------
; Unreliable sayerrors:
;
; During heavy processing, sayerror statements are often gobbled, appear in
; the wrong order or even doubled in the message list. Therefore better use
; the NepmdPmPrintf proc or the dprintf proc, together with a PmPrintf
; application for debugging.

; ---------------------------------------------------------------------------
; Pre-processing before calling the LoadFile defproc. Same syntax as
; LoadFile. Calls itself LoadFile at the end. (LoadFile is defined in
; SLNOHOST.E/SAVELOAD.E/E3EMUL.E. Without HOST_SUPPORT, always SLNOHOST.E is
; included.)
; Checks a filespec, even wildcards, to remove REXX EAs before loading.
; Called by defc Edit.
defproc PreLoadFile( Spec, Options)
   universal filestoload
   universal filestoloadmax  -- still used for 'xcom e' and afterload
   if filestoload = '' then
      filestoload = 0
   endif
   if filestoloadmax = '' then
      filestoloadmax = 0
   endif

   Spec = strip( Spec, 'B', '"')

   -- Experimental URL support, configurable via URL_LOAD_TEMPLATE.
   -- Default is to use wget for downloading it.
   if pos( '://', Spec) > 0 then
      rc = LoadUrl( Spec, Options)
      return rc
   endif

   fWildcard = (pos( '*', Spec) + pos( '?', Spec) > 0);

   -- Resolve wildcards in Spec to delete REXX EAs for every REXX file
   -- and for setting universal vars
   Handle = GETNEXT_CREATE_NEW_HANDLE    -- always create a new handle!
   fStop = 0
   do while fStop <> 1
      if fWildcard then
         -- If Spec contains wildcards then find Filenames
         Filename = NepmdGetNextFile( Spec, address( Handle))
         parse value Filename with 'ERROR:'rc
         if rc > '' then
            leave
         endif
         filestoload = filestoload + 1
         filestoloadmax = filestoload
      else
         -- If Spec doesn't contain wildcards then set Filename to make the
         -- edit command add a file to the ring, even when it doesn't exist
         Filename = Spec
         filestoload = 1
         filestoloadmax = filestoload
         fStop = 1
      endif
      --sayerror 'Spec = 'Spec', Filename = 'Filename
      dprintf( 'EDIT', 'PreLoadFile: Spec = 'Spec', Filename = 'Filename)

      -- Delete REXX EAs if extension is found in RexxEaExtensions.
      call PreloadDeleteRexxEas( Filename)

      -- GetMode doesn't work here, because it tries to write the 'mode.'fid
      -- array var. At this time the file is not loaded, so the fileid is not set.
      -- But calling NepmdQueryDefaultMode(Filename) would work.
      -- We should better determine the mode here, save it in a array var with the
      -- .filename as identifier, and replace the identifier with the fileid later
      -- at defload (or replace the array var with the final one).

compile if 0
      -- Experimentell codepage support
      call PreloadProcessCodepage( Filename)
compile endif

   enddo

   -- Load the file.
   -- Add "..." here to enable loading file names with spaces and
   -- use Spec instead of Filename to keep the loading of host files unchanged
   if pos( ' ', Spec) > 0 then
      Spec = '"'Spec'"'
   endif
   call LoadFile( Spec, Options)
   return rc

; ---------------------------------------------------------------------------
const
compile if not defined( URL_LOAD_TEMPLATE)
   -- Command to execute for URL filespecs (that contain "://")
   -- %u = URL spec, %t = tempfile, %o = load options
   URL_LOAD_TEMPLATE = 'os2 /c wget "%u" -O %t^&^&start epm /r %o %t'
   --URL_LOAD_TEMPLATE = 'start epm ''shell wget "%u" -O %t&&start epm /r %o %t'''
   --URL_LOAD_TEMPLATE = 'o ''shell wget "%u" -O %t&&start epm /r %o %t'''
compile endif

; Experimental URL support using wget
; Dragging a URL from Mozilla onto an EPM program object loads the
; downloaded file into EPM, unless it contains following chars: [ ] ?
; They would cause an entrybox to popup for entering parameters.
; With DragText installed, support for dropping text onto the titlebar
; should better be disabled. EPM handles that itself:
; o  Dropping it onto the EPM edit window inserts the URL.
; o  Dropping it onto the EPM title bar adds a new file with the URL.
; o  Ctrl-dropping it onto the EPM edit window won't load the file
;    and says: 'File is empty: "<tempfile>"'
; o  Ctrl-dropping it onto the EPM title bar adds an empty <tempfile>,
;    reverting it after the download will load it.
defproc LoadUrl( Spec, Options)
   rc = 0
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
      call erasetemp( TmpFile)
   endif
   sayerror 'Downloading 'Spec

   -- Resolve the template
   rest = URL_LOAD_TEMPLATE
   Cmd = ''
   do while rest > ''
      parse value rest with next'%'rest
      if rest = '' then
         Cmd = Cmd''next
         leave
      endif
      ch = upcase( leftstr( rest, 1))
      if ch = 'U' then
         Cmd = Cmd''next''Spec
         rest = substr( rest, 2)
      elseif ch = 'T' then
         Cmd = Cmd''next''TmpFile
         rest = substr( rest, 2)
      elseif ch = 'O' then
         Cmd = Cmd''next''Options
         rest = substr( rest, 2)
      endif
   enddo

   --dprintf( 'PreLodFile', Cmd)
   Cmd
   --'os2 /c wget "'Spec'" -O 'TmpFile'^&^&start epm /r' TmpFile
   return rc

; ---------------------------------------------------------------------------
const
compile if not defined( REXX_EA_EXTENSIONS)
   -- Extensions, whose REXX EAs shall be removed before loading
   -- to workaround the EPM bug that it can't load EAs > 32KB.
   REXX_EA_EXTENSIONS = 'CMD ERX'
compile endif

; Delete REXX EAs if extension is found in RexxEaExtensions.
; Use the extension here instead of the mode to avoid determining the
; mode twice: here and at defload.
; Note: The use of array vars containing the fileid to become file-specific
; does only work properly at or after defload. Therefore the mode should be
; determined at defload.
; Syntax: rc = PreloadDeleteRexxEas( Filename)
defproc PreloadDeleteRexxEas( Filename)
   rc = 0
   p = lastpos( '\', Filename)
   Name = substr( Filename, p + 1)  -- strip path
   p = lastpos( '.', Name)
   if p > 1 then
      Ext = translate( substr( Name, p + 1))
      if wordpos( Ext, REXX_EA_EXTENSIONS) then
compile if 0
         -- Calling here another proc doesn't always work reliable.
         if GetReadOnly( Filename) = 0 then  -- if it exists and if not readonly
compile else
         -- Inserting the code here directly always works.
         fReadonly = 0
         attr = NepmdQueryPathInfo( Filename, 'ATTR')
         parse value attr with 'ERROR:'rc
         if rc > '' then  -- file doesn't exist
            --sayerror 'Attributes for "'Filename'" can''t be retrieved, rc = 'rc
            return rc
         elseif length(attr) = 5 then
            fReadonly = (substr( attr, 5, 1) = 'R')
         endif
         -- dprintf( 'PreloadDeleteRexxEas', Filename' - 'attr', fReadonly = 'fReadonly)
         if not fReadonly then
compile endif
            --sayerror 'Removing REXX EAs with NepmdLib from 'Filename
            next = NepmdDeleteRexxEa( Filename)
            parse value next with 'ERROR:'rc
            if rc = '' then
               rc = 0
            endif
         endif
      endif
   endif
   return rc

; ---------------------------------------------------------------------------
; Experimental codepage support.
; The .codepage field var exists, but is not yet used.
; Drawback: deletes every EA.
defproc PreloadProcessCodepage( Filename)
   rc = 0
   Codepage = NepmdQueryStringEa( Filename, 'EPM.CODEPAGE')
   parse value Codepage with 'ERROR:'rc
   if rc = '' then
      Codepage = upcase(Codepage)
      if Codepage = 'CP1004' then
         Codepage = 'latin-1'
      endif
      -- Note: GNU Recode deletes all EAs
      quietshell 'recode 'Codepage':cp850 'Filename
      -- Delete EA, because it will not be reset on save yet
      --call NepmdDeleteStringEa( Filename, 'EPM.CODEPAGE')
   endif
   return rc

; ---------------------------------------------------------------------------
; This DEFC EDIT eventually calls the built-in edit command (xcom edit), by
; calling PreLoadFile -> LoadFile, that does additional processing before
; the file(s) is/are loaded.
;
; The EDIT command can not only be executed from EPM's commandline, but is
; also prepended to the submitted args when EPM is started. Before that,
; EPM removes the options that it knows. The rest of the arg string is always
; submitted to the EDIT command. (Main arg processing is done in MAIN.E.)
;
; Parse off each file individually.  Files can optionally be followed by one
; or more commands, each in quotes.  The first file that follows a host file
; must be separated by a comma, an option, or a (possibly null) command.
;
; EPM doesn't give error messages from XCOM EDIT, so we have to handle that
; for it.

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
   universal firstloadedfid  -- first file for this edit cmd, set here
   universal firstinringfid  -- first file in the ring, set by defmain
                             -- Both values are set by defmain, if only
                             -- the unknown file was loaded (via xcom edit).

   getfileid startfid  -- save fid of topmost file before current edit cmd
   call ResetHiliteModeList()
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

   if CurEditCmd <> 'RESTORERING' then
; Todo:
;    Here: Write args to an array var
;    AtStartup: Write contents of array to history
      'AtStartup AddToHistory EDIT' args
   endif

   options = default_edit_options

   files_loaded      = 0  -- number of loaded files
   new_files_loaded  = 0  -- number of new files created (maybe because not found on disk)
   first_file_loaded = ''

; Todo: rewrite that horrible message stuff:
   new_files = ''
   not_found = ''
   bad_paths = ''
   truncated = ''
   access_denied = ''
   invalid_drive = ''
   error_reading = ''
   error_opening = ''
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
      -- A ',' separates multiple <filespec> '<command>' segments.
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
               -- Recogniation of ',' as segement parser is changed from ','
               -- to ', ' (at least 1 space after the comma) in order to
               -- support filenames like: "filename.ext,v", as created by CVS.
               -- Parse at next ', '. Removes ', ' from filespec (DOS and VM)
               -- A ', ' separates multiple <filespec> '<command>' segments.
               parse value rest with filespec rest2
               if pos( ', ', filespec) then
                  parse value rest with filespec ', ' rest
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

         -- Load the file
         rc = PreLoadFile( filespec, options)
         edit_rc = rc  -- restore this rc at the end

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
      multiple_errors = (new_files || bad_paths || not_found || truncated ||
                         access_denied || error_reading || error_opening ||
                         invalid_drive <>
                         invalid_drive || error_opening || error_reading ||
                         access_denied || truncated || not_found ||
                         bad_paths || new_files ) &
                        ('' <>
                         new_files || bad_paths || not_found || truncated || access_denied ||
                         error_reading || error_opening || invalid_drive)

      if new_files then sayerror NEW_FILE__MSG substr(new_files,2); endif
      if not_found then sayerror FILE_NOT_FOUND__MSG':' substr(not_found,2); endif
   else
      multiple_errors = 0
   endif
   if bad_paths then sayerror BAD_PATH__MSG':' substr(bad_paths,2); endif
   if truncated then sayerror LINES_TRUNCATED__MSG':' substr(truncated,2); endif
   if access_denied then sayerror ACCESS_DENIED__MSG':' substr(access_denied,2); endif
   if invalid_drive then sayerror INVALID_DRIVE__MSG':' substr(invalid_drive,2); endif
   if error_reading then sayerror ERROR_READING__MSG':' substr(error_reading,2); endif  -- __MSGs were
   if error_opening then sayerror ERROR_OPENING__MSG':' substr(error_opening,2); endif  -- exchanged
   if multiple_errors then
      messageNwait(MULTIPLE_ERRORS__MSG)
   endif

   dprintf( 'EDIT', 'arg(1) = ['arg(1)'], first_file_loaded = ['first_file_loaded'], ['first_file_loaded.filename']')
   -- If 1 or more files are loaded by the current edit cmd (or if loadfile has returned rc = 0):
   if first_file_loaded <> '' then

      -- activatefile is now executed in ProcessAfterLoad with postme.
      -- This finally works properly. With activatefile here the ring would get messed.
      --activatefile first_file_loaded
      -- Set fid for ProcessAfterLoad:
      firstloadedfid = first_file_loaded

      -- Initialize firstinringfid if not already set by a previous edit command:
      if firstinringfid = '' then
         firstinringfid = firstloadedfid
      endif

      if firstloadedfid = startfid then
         -- If previous topmost file should be loaded again as first loaded file,
         -- check if file was altered by another application.
         -- Note: Required, because no defselect, no defload will be triggered then.
         --       This enables a check for altered-on-disk.
         'ResetDateTimeModified'
         'RefreshInfoLine MODIFIED'
      endif

   endif
   rc = edit_rc

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
;  New in EPM.  Edits a file in a different PM window.  This means invoking
;  a completely new instance of E.DLL, with its own window and data.  We do it
;  by posting a message to the executive, the top-level E application.
defc o, open=
   fname = strip(arg(1))                    -- Remove excess spaces
   call parse_filename( fname, .filename)   -- Resolve '=', if any

      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5386,                   -- EPM_EDIT_NEWFILE
                          put_in_buffer(fname),
                          1)                      -- Tell EPM to free the buffer.

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
   parse arg Filename Pathname Rest
   if Pathname = '' | Pathname = '.' then
      if filetype( Filename) = 'CMD' then
         PathnameList = 'PATH'
      else
         PathnameList = EPATH 'PATH'
      endif
   else
      PathnameList = Pathname
   endif
   do w = 1 to words( PathnameList)
      Pathname = word( PathnameList, w)
      call parse_filename( Filename,
                           substr( .filename, lastpos( '\', .filename) + 1))
      findfile Newfile, Filename, Pathname  -- find Filename in Pathname env var
      if not rc then  -- if found
         leave
      endif
   enddo
   if rc then  -- use specified Filename if not found
      Newfile = Filename
   endif
   Cmd = strip( 'e' Newfile Rest)
   Cmd

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
; Move current file to a newly opened EPM window.
; Moved from STDCMDS.E
defc newwindow
   if leftstr(.filename, 5)='.DOS ' then
      fn = "'"substr(.filename, 6)"'"
   elseif .filename = '.tree' then
      parse value .titletext with cmd ': ' args
      fn = "'"cmd args"'"
   elseif IsAShell() then
      epmdir = directory()
      call psave_pos(save_pos)
      getsearch oldsearch
      -- search (reverse) in command shell window for the prompt and
      -- retrieve the current directory
      -- goto previous prompt line
      ret = ShellGotoNextPrompt( 'P')
      curdir = ''
      cmd = ''
      if not ret then
         call ShellParsePromptLine( curdir, cmd)
      endif
      shellcmd = 'shell'
      if curdir > '' then
         shellcmd = shellcmd 'cdd' curdir
      endif
      setsearch oldsearch
      call prestore_pos(save_pos)
      fn = "'mc +cd "epmdir"+"shellcmd"'"
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
   if GetMode() = 'BIN' then
      -- prepend 'binedit'
      fn = "'binedit "fn"'"
   endif
   if postmc > '' then
      "open" fn "'postme mc "postmc"'"
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
   filemask = '*.exe;*.dll'
   title    = 'Select a binary file'
   "o 'filedlg "title", be, "filemask"'"  -- works, but Cancel opens an empty window
   --"filedlg "title", o 'be', "filemask
   -- A command that returns the hwnd of the newly opened window is needed.

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
                        0, 0,              -- top, left,
                        Height, Width,     -- height, width,
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
defc edit_list
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
;      Duplicated '\' between path and name are avoided.
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
      wrd = ResolveEnvVars(wrd)
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
; Find a filemask, maybe relative, with a given startdir.
; Doesn't check if file exists.
; Doesn't resolve envvars.
; Doesn't resolve "=".
; Supports UNC and Unix names, including something like ftp://.
; Not tested with IBM host names.
; Syntax: GetFullName( FileMask [, StartDir])
; FileMask: any maybe relative dir or file filemask, wildcards allowed
; StartDir: parts of StartDir are appended to FileMask, if it's relative
defproc GetFullName( FileMask)
   FullName = FileMask

   -- Get current dir and drive
   CurDir = directory()
   CurDrive = leftstr( CurDir, 2)

   -- Get specified dir
   StartDir = arg(2)

   -- Translate '/' to '\' if local masks specified
   p1 = pos( ':/', FileMask)
   p2 = pos( '://', FileMask)
   p3 = pos( ':/', StartDir)
   p4 = pos( '://', StartDir)
   if (p1 > 0 & p1 <> p2) | (p3 > 0 & p3 <> p4) then
      FileMask = translate( FileMask, '\', '/')
      StartDir = translate( StartDir, '\', '/')
   endif

   -- Init
   if StartDir = '' then
      StartDir = CurDir
   endif
   StartDrive = ''
   Server = ''

   -- Determine StartDir and StartDrive or Server
   if substr( StartDir, 2, 2) = ':\' then        -- fully qualified
      StartDrive = leftstr( StartDir, 2)
   elseif leftstr( StartDir, 2, 2) <> '\\' then  -- UNC
      p1 = 3
      p2 = pos( '\', StartDir, p1)
      if p2 = 0 then
         Server = StartDir
      else
         Server = leftstr( StartDir, p2 - 1)
      endif
   elseif pos( '://', StartDir ) then            -- something like ftp:// or http://
      p1 = pos( '://', StartDir ) + 3
      p2 = pos( '/', StartDir, p1)
      if p2 = 0 then
         Server = StartDir
      else
         Server = leftstr( StartDir, p2 - 1)
      endif
   elseif leftstr( StartDir, 1) = '\' then       -- local, without drive
      StartDrive = CurDrive
      StartDir = StartDrive''StartDir
   else                                          -- relative
      StartDrive = CurDrive
      StartDir = strip( CurDir, 't', '\')'\'StartDir
   endif

   -- Determine fullname                   -- fully qualified
   if substr( FileMask, 2, 2) = ':\' then        -- local, fully qualified
      FullName = FileMask
   elseif leftstr( FileMask, 2, 2) = '\\' then   -- fully qualified UNC
      FullName = FileMask
   elseif pos( '://', FileMask ) then            -- fully qualified, starting with something like ftp:// or http://
      FullName = Server''FileMask
                                           -- only drive or server missing
   elseif leftstr( FileMask, 1) = '\' &          -- UNC mask without server
      leftstr( StartDir, 2, 2) = '\\' then
      FullName = Server''FileMask
   elseif leftstr( FileMask, 1) = '/' &          -- Unix mask without server
      pos( '://', StartDir ) then
      FullName = Server''FileMask
   elseif leftstr( FileMask, 1) = '\' then       -- without drive
      FullName = StartDrive''FileMask
                                           -- relative
   elseif leftstr( StartDir, 2, 2) = '\\' then   -- relative UNC mask
      FullName = strip( StartDir, 't', '\')'\'FileMask
   elseif pos( '://', StartDir ) then            -- relative Unix mask
      FullName = strip( StartDir, 't', '/')'/'FileMask
   else                                          -- relative
      FullName = strip( StartDir, 't', '\')'\'FileMask
   endif

   -- Resolve '.' and '..' in FullName
   if not pos( '/', FullName) then
      next = NepmdQueryFullname( FullName)
      parse value next with 'ERROR:'rc
      if rc = '' then
         FullName = next
      endif
   endif

   return FullName

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


