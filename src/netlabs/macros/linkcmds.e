/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: linkcmds.e,v 1.5 2003-12-14 17:30:05 aschn Exp $
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

;  Link <modulename>          Example:  link draw
;  A simple front end to the link statement to allow command-line invocation.
;
defc link
   link arg(1)
   if RC>=0 then
      sayerror LINK_COMPLETED__MSG RC
   endif


;  Unlink <modulename>        Example:  unlink draw
;  A simple front end to the unlink statement to allow command-line invocation.
;
defc unlink
   unlink arg(1)
   if RC then sayerror RC endif


compile if WANT_ET_COMMAND

;  Relink [modulename]
;
;  Compiles the module, unlinks it and links it again.  A fast way to
;  recompile/reload a macro under development without leaving the editor.
;  Note that the unlink is necessary in case the module is already linked,
;  else the link will merely reinitialize the previous version.
;
;  If modulename is omitted, the current filename is assumed.
;
defc relink
   modulename=arg(1)  -- new: path and ext optional
   if modulename='' then                           -- If no name given,
      p = lastpos('.', .filename)
      if upcase(substr(.filename,p))<>'.E' then
         sayerror 'Not an .E file'
         return
      endif
      modulename = substr(.filename, 1, p-1)       -- use current file.
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

   unlink basename
   if RC & (RC <> -310) then sayerror RC; return; endif  -- -310 = "Unlink:  unknown module"

   link basename


; Syntax: etpm e_file [ex_file]
;
; etpm = =   compiles current file to an .ex file in the same dir
defc et,etpm=
   universal vTEMP_PATH,vTEMP_FILENAME

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
   NextDir = NepmdRootDir'\myepm\autolink'  -- search in myepm\autolink first
   if exist( NextDir'\'BaseName'.ex') then
      DestDir = NextDir
   else
      DestDir = NepmdRootDir'\myepm\ex'     -- myepm\ex
   endif
   If ExFile = '' then
      ExFile = DestDir'\'BaseName'.ex'
   endif

   TempFile=vTEMP_PATH'ETPM'substr( ltoa( gethwnd(EPMINFO_EDITCLIENT), 16), 1, 4)'.TMP'

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
   if rc=-2 then
      sayerror CANT_FIND_PROG__MSG EtpmCmd
      stop
   endif
   if rc=41 then
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


defproc ec_position_on_error(tempfile)   /* load file containing error */
   'xcom e 'tempfile
   if rc then    -- Unexpected error.
      sayerror ERROR_LOADING__MSG tempfile
      if rc=-282 then 'xcom q'; endif  -- sayerror('New file')
      return
   endif
   if .last<=4 then
      getline msg,.last
      'xcom q'
   else
      getline msg,2
      if leftstr(msg,3)='(C)' then  -- 5.20 changed output
         getline msg,4
      endif
      getline temp,.last
      parse value temp with 'col= ' col
      getline temp,.last-1
      parse value temp with 'line= ' line
      getline temp,.last-2
      parse value temp with 'filename=' filename
      'xcom q'
      'e 'filename               -- not xcom here, respect user's window style
      if line<>'' and col<>'' then
         .cursory=min(.windowheight%2,.last)
         if col>0 then
            'postme goto' line col
         else
            line = line - 1
            col = length( textline(line))
            'postme goto' line col
         endif
      endif
   endif
   sayerror msg

compile endif  -- WANT_ET_COMMAND


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
;
defc qlink, qlinked, ql
   module = arg(1)
   if module='' then
      sayerror QLINK_PROMPT__MSG
   else
      result = linked(arg(1))
      if result= -307 or    -- sayerror("Link: file not found")
         result= -308 then  -- sayerror("Link: invalid filename")
         sayerror CANT_FIND1__MSG module CANT_FIND2__MSG
      elseif result<0 then    -- return of -1 means file exists but not linked
         sayerror module NOT_LINKED__MSG
      else
         sayerror module LINKED_AS__MSG result'.'
      endif
   endif

defc linkverify
   module = arg(1)
   link module
   if RC<0 then
      if RC=-290 then  -- sayerror('Invalid EX file or incorrect version')
         if filetype(module)<>'.EX' then module=module'.ex'; endif
         findfile module1, module, EPATH
         if rc then findfile module1, module, 'PATH'; endif
         if not rc then module = module1; endif
         RC=-290
      endif
      call winmessagebox(UNABLE_TO_LINK__MSG module, sayerrortext(rc), 16416)  -- OK + ICON_EXCLAMATION + MB+MOVEABLE
   endif

; Routine to link a .ex file, then execute a command in that file.
defproc link_exec(ex_file, cmd_name)
   'linkverify' ex_file
   if RC>=0 then
      cmd_name arg(3)
   else
      sayerror UNABLE_TO_EXECUTE__MSG cmd_name
   endif


