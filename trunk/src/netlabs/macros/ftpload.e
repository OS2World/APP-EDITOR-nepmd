/****************************** Module Header *******************************
*
* Module Name: ftpload.e
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

; See comments in FTPSAVE.E
;
;                Larry Margolis

tryinclude 'MYCNF.E'  -- User can point to FTP.EXE here.  Required if not in path.

const
compile if not defined(ftp_pgm)
   ftp_pgm= 'FTP.EXE'                -- location of the FTP.EXE program - in path?
compile endif

defmain
   universal vtemp_path
;; parse arg filename machname user pass '/' opts
   parse arg filename rest
   parse value rest with stuff '/' opts
   parse value stuff with machname user pass
   opts = upcase(opts)
   mode = ''; cd = ''
   do while opts <> ''
      parse value opts with opt rest '/' opts
      if opt='A' | opt='ASC' | opt='ASCII' then
         mode = 'ascii'
      elseif opt='B' | opt='BIN' | opt='BINARY' then
         mode = 'binary'
      elseif opt='CD' then cd = rest
      else
         sayerror 'Unknown option 'opt' ignored.'
      endif
   enddo
   if not mode then
      ext = filetype(filename)
      if substr(ext,max(length(ext)-2,1)) = 'BIN' |
         pos(' 'substr(ext,1,3),' BIN RAM ARC EXE LIB DLL COM OBJ SYS FLS ICO TBH IMG GVX ZIP')
      then
         mode = 'binary'
      else
         mode = 'ascii'
      endif
   endif
   if user = '' then
      sayerror 'Required parm missing: FTPLOAD fname mach_name user [pass] [/a | /b] [/cd dir]'
      return
   endif
   if pass = '' then
      pass = entrybox('Enter password for 'user' on 'machname,
                      '',  -- Buttons
                      '',  -- Entry text
                      '',  -- Cols
                      250,  -- Max len
                      '',  -- Return buffer
                      140) -- ES_UNREADABLE + ES_AUTOSCROLL + ES_MARGIN
   endif
   if pass = '' then
      sayerror 'No password entered.  Command halted.'
      return
   endif
   wind=substr(ltoa(gethwnd(5),16),1,4)
   cmdfile = vtemp_path'cmds'wind'.ftp'
   'xcom e /c 'cmdfile
   tempfile=vtemp_path'LOAD'wind'.FTP'
   replaceline 'open 'machname, 1
   insertline 'user 'user pass, 2
   insertline mode, 3
   l = length(vTEMP_PATH)
   insertline 'lcd 'substr(vtemp_path,1,L - (L>3 & substr(vTEMP_PATH,L,1)='\')), 4
   if cd<>'' then
      insertline 'cd 'cd, 5
   endif
   insertline 'get 'filename' LOAD'wind'.FTP', .last+1
   'xcom save'; src = rc
   'xcom quit'
   if src then sayerror 'Error 'src' saving 'cmdfile'.  Command halted.'; stop; endif
   sayerror 'Attempting to get 'filename' from 'machname cd' in 'mode
   outfile = vtemp_path'outp'wind'.ftp'
   quietshell ftp_pgm '-n <'cmdfile '>'outfile
   ftp_rc = rc
   call erasetemp(cmdfile)
   If ftp_rc then
      sayerror 'RC from 'FTP_pgm' =' ftp_rc'; outfile='outfile;
      rc = ftp_rc
      return
   endif
   'xcom e /d 'tempfile
   erc = rc
;sayerror 'rc='rc '"'sayerrortext(rc)'"'
   .filename = '['machname'.'user'.'cd'] 'filename
   .autosave = 0
   .userstring = .userstring ''pass''mode''
   .autosave = 0
   call erasetemp(tempfile)
   sayerror 0
   if erc & erc<>sayerror('Lines truncated') then
      'xcom q'
      'e /d 'outfile
      if erc = sayerror('New file') then
         sayerror 'File not gotten.  FTP messages shown below.'
      else
         sayerror 'Error 'erc' loading temp file 'tempfile
      endif
   endif
   call erasetemp(outfile)

