/****************************** Module Header *******************************
*
* Module Name: edit.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edit.e,v 1.11 2002-11-04 14:44:09 aschn Exp $
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
; Resolves environment variables in a string
; Returns converted string
defproc NepmdResolveEnvVars( Spec )
   startp = 1
   do forever
      p1 = pos( '%', Spec, startp )
      if p1 = 0 then
         leave
      endif
      startp = p1 + 1
      p2 = pos( '%', Spec, startp )
      if p2 = 0 then
         leave
      else
         startp = p2 + 1
         Spec = substr( Spec, 1, p1 - 1 ) ||
                Get_Env( substr( Spec, p1 + 1, p2 - p1 - 1 ) ) ||
                substr( Spec, p2 + 1 )
      endif
      --sayerror 'arg(1) = 'arg(1)', p1 = 'p1', p2 = 'p2', resolved spec = 'Spec
   enddo  -- forever
   return Spec

; ---------------------------------------------------------------------------
; Load files from a filespec, remove REXX EA's before loading

defproc NepmdLoadFile( Spec, Options )
   RexxEaExtensions = 'CMD ERX'

   Spec = strip( Spec, 'B', '"' )
   ContainsWildcard = (pos( '*', Spec ) + pos( '?', Spec ) > 0);

   -- Resolve wildcards in Spec to delete REXX EA's for every REXX file
   SpecProcessed = 0
   Handle = 0
   do forever

      if SpecProcessed = 1 then
         leave
      endif

      if (ContainsWildcard) then
         -- if Spec contains wildcards then find FileNames
         FileName = NepmdGetNextFile( Spec, address( Handle) )
         parse value Filename with 'ERROR:'rc
         if rc <> '' then
            leave
         endif
      else
         -- if Spec doesn't contain wildcards then set Filename to enable the
         -- edit command adding a not existing file to the edit ring
         Filename = Spec
         SpecProcessed = 1  -- Set a flag to process the loop only once
      endif

      --sayerror 'Spec = 'Spec', Filename = 'Filename

      -- Remove REXX EA's if extension is found in RexxEaExtensions.
      -- Use the extension here instead of the mode to avoid determining the
      -- mode twice: here and at defload.
      p1 = lastpos( '.', Filename )
      if p1 > 1 then
         ext = translate( substr( Filename, p1 + 1 ) )
         if wordpos( ext, RexxEaExtensions ) then
            --sayerror 'Removing REXX EAs with NepmdLib from 'Filename
            call NepmdDeleteRexxEa( FileName )
         endif
      endif

   enddo  -- forever

   -- load the file
   -- add "..." here to enable loading file names with spaces and
   -- use Spec instead of FileName to keep the loading of host files unchanged
   loadrc = loadfile( '"'Spec'"', Options )

   return loadrc

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
/* This DEFC EDIT eventually calls the built-in edit command, by calling      */
/* loadfile(), but does additional processing for messy-desk windowing (moves */
/* each file to its own window), and ends by calling select_edit_keys().      */
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

defc e,ed,edit,epm=
   universal default_edit_options
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') & not SMALL
   universal fto                -- Need this passed to loadfile...
compile endif
   universal nepmd_hini

   call NepmdResetHiliteModeList()

   rest=strip(arg(1))

   if rest='' then   /* 'edit' by itself goes to next file */
;      nextfile  -- removed to have 'epm /r' only bring an EPM window to the foreground
                 -- instead of switching to the next file in the ring.
      return 0
   endif

   options=default_edit_options
   parse value '0 0' with files_loaded new_files_loaded new_files not_found bad_paths truncated access_denied invalid_drive error_reading error_opening first_file_loaded
--  bad_paths     --> Non-existing path specified.
--  truncated     --> File contained lines longer than 255 characters.
--  access_denied --> If user tried to edit a subdirectory.
--  invalid_drive --> No such drive letter
--  error_reading --> Bad disk(ette).
--  error_opening --> Path contained invalid name.

   do while rest<>''
      rest=strip(rest,'L')
      if substr(rest,1,1)=',' then rest=strip(substr(rest,2),'L'); endif
      ch=substr(rest,1,1)
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') & not SMALL
 compile if (MVS or E3MVS) and not HOST_LT_REQUIRED  -- (MVS filespecs can start with '.)
      if 0 then                         -- No-op
 compile else
      if ch="'" then                    -- Command
 compile endif
compile else
      if ch="'" then                    -- Command
compile endif
         parse value rest with (ch) cmd (ch) rest
         do while substr(rest,1,1)=ch & pos(ch,rest,2)
            parse value rest with (ch) p (ch) rest
            cmd = cmd || ch || p
         enddo
         cmd
      elseif ch='/' then       -- Option
         parse value rest with opt rest
         options=options upcase(opt)
      else
         files_loaded=files_loaded+1  -- Number of files we tried to load
      if ch='"' then
         p=pos('"',rest,2)
         if p then
            filespec = substr(rest, 1, p)
            rest = substr(rest, p+1)
         else
            sayerror INVALID_FILENAME__MSG
            return
         endif
      else
compile if HOST_SUPPORT & not SMALL
         p=length(rest)+1  -- If no delimiters, take to the end.
         p1=pos(',',rest); if not p1 then p1=p; endif
         p2=pos('/',rest); if not p2 then p2=p; endif
         p3=pos('"',rest); if not p3 then p3=p; endif
         p4=pos("'",rest); if not p4 then p4=p; endif
 compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
  compile if MVS or E3MVS
         p4=p     -- Can't use single quote for commands if allowing MVS files
  compile endif
         p5=pos('[',rest); if not p5 then p5=p; endif  -- Allow for [FTO]
         p=min(p1,p2,p3,p4,p5)
 compile else
         p=min(p1,p2,p3,p4)
 compile endif
         filespec=substr(rest,1,p-1)
         if VMfile(filespec,more) then    -- tricky - VMfile modifies file
            if p=p1 then p=p+1; endif     -- Keep any except comma in string
            rest=more substr(rest,p)
         else
compile endif
            parse value rest with filespec rest2
            if pos(',',filespec) then parse value rest with filespec ',' rest
            else rest=rest2; endif
compile if HOST_SUPPORT & not SMALL
            endif
  compile if HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL'
            if substr(strip(rest,'L'),1,1)='[' then
               parse value rest with '[' fto ']' rest
            else
               fto = ''                           --  reset for each file!
            endif
  compile endif
compile endif
         endif  -- VMfile(file,more)

         if pos('=', filespec) & not pos('"', filespec) then
            call parse_filename(filespec,.filename)
            if pos(' ', filespec) then
               filespec = '"'filespec'"'
            endif
         endif

         -- resolve environment variables
         if pos( '%', filespec ) then
            filespec = NepmdResolveEnvVars( filespec )
         endif

         --sayerror 'EDIT.E before call loadfile(filespec,options): filespec = 'filespec


compile if USE_APPEND  -- Support for DOS 3.3's APPEND, thanks to Ken Kahn.
         if not(verify(filespec,'\:','M')) then
            if not exist(filespec) then
               Filespec = Append_Path(Filespec)||Filespec  -- LAM todo: fixup
            endif
        endif
compile endif

         call NepmdLoadFile(filespec, options)

         if rc=-3 then        -- sayerror('Path not found')
            bad_paths=bad_paths', 'filespec
         elseif rc=-2 then    -- sayerror('File not found')
            not_found=not_found', 'filespec
         elseif rc=-282 then  -- sayerror('New file')
            new_files=new_files', 'filespec
            new_files_loaded=new_files_loaded+1
         elseif rc=-278 then  --sayerror('Lines truncated')
            getfileid truncid
            do i=1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
               if .modify then leave; endif  -- Need to do this if wildcards were specified.
               nextfile
            enddo
            truncated=truncated', '.filename
            .modify = 0
         elseif rc=-5 then  -- sayerror('Access denied')
            access_denied=access_denied', 'filespec
         elseif rc=-15 then  -- sayerror('Invalid drive')
            invalid_drive=invalid_drive', 'filespec
         elseif rc=-286 then  -- sayerror('Error reading file')
            error_reading=error_reading', 'filespec
         elseif rc=-284 then  -- sayerror('Error opening file')
            error_opening=error_opening', 'filespec
         endif  -- rc=-3
         if first_file_loaded='' then
            if rc<>-3   &  -- sayerror('Path not found')
               rc<>-2   &  -- sayerror('File not found')
               rc<>-5   &  -- sayerror('Access denied')
               rc<>-15     -- sayerror('Invalid drive')
               then
               getfileid first_file_loaded
            endif
         endif  -- first_file_loaded=''
      endif  -- ch=... (not "cmd")
   enddo  -- while rest<>''
   if files_loaded>1 then  -- If only one file, leave E3's message
      if new_files_loaded>1 then p='New files:'; else p='New file:'; endif
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
   if error_reading then $SAYERR ERROR_OPENING__MSG':' substr(error_reading,2); endif
   if error_opening then $SAYERR ERROR_READING__MSG':' substr(error_opening,2); endif
   if multiple_errors then
      messageNwait(MULTIPLE_ERRORS__MSG)
   endif
   if first_file_loaded<>'' then activatefile first_file_loaded; endif


; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
;  New in EPM.  Edits a file in a different PM window.  This means invoking
;  a completely new instance of E.DLL, with its own window and data.  We do it
;  by posting a message to the executive, the top-level E application.
defc o,open=
compile if WPS_SUPPORT
   universal wpshell_handle
compile endif
   fname=strip(arg(1))                    -- Remove excess spaces
   call parse_filename(fname,.filename)   -- Resolve '=', if any

compile if WPS_SUPPORT
   if wpshell_handle then
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5159,                   -- EPM_WPS_OPENNEWFILE
                         getpminfo(EPMINFO_EDITCLIENT),
                         put_in_buffer(fname))
   else
compile endif
      call windowmessage(0,  getpminfo(APP_HANDLE),
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
   if pathname='' | pathname='.' then
      if filetype(filename)='CMD' then
         pathname='PATH'
      else
         pathname=EPATH
      endif
   endif
 compile if 0  -- Old way required the optional search_path & get_env routines
   if not exist(filename) then
      filename = search_path_ptr(Get_Env(pathname,1),filename)filename
   endif
   'e 'filename
 compile else  -- New way uses the built-in Findfile.
   if pos('=', filename) & leftstr(filename, 1)<>'"' then
      call parse_filename( filename, substr(.filename, lastpos('\', .filename)+1))
   endif
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


