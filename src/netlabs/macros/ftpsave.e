/****************************** Module Header *******************************
*
* Module Name: ftpsave.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ftpsave.e,v 1.1 2004-02-22 21:22:45 aschn Exp $
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

;  FTPSAVE command, for saving a file via FTP.  Syntax is:
;     FTPLOAD file_name machine_name user [pass] [/a | /b] [/cd dir]
;  /ASCII and /BINARY set the mode for the file transfer; /CD is useful
;  when going to VM where CD is required to access a new disk.  If the
;  password is omitted, it will be prompted for * (so it's not available
;  in the command stack for others to see).  If any other arguments are
;  omitted, and the file was loaded via FTPLOAD, the corresponding parameters
;  will be used from the FTPLOAD command.  Examples:
;     FTPSAVE /tcpip/etc/sendmail.cf lamail myuserid mypass
;     FTPSAVE ftpload.ebin VM_host myuserid /cd EOS2.194
;
;  This works with the FTP program from IBM's OS/2 TCP/IP product; it has not
;  been tried with any other versions.
;
;  * Note:  The password prompting only works for EPM.
;
;  Note:  These are (or should be) brackets:  []
;
;                Larry Margolis

tryinclude 'MYCNF.E'  -- User can point to FTP.EXE here.  Required if not in path.

const
compile if not defined(ftp_pgm)
   ftp_pgm= 'FTP.EXE'                /* location of the FTP.EXE program - in path? */
compile endif

defmain
   universal vtemp_path
   parse arg filename machname user pass '/' opts
   mode = ''; cd = ''
   parse value .filename with '[' oldmachname '.' olduser '.' oldcd '] ' oldfn
   parse value .userstring with '' oldpass '' oldmode ''
   do while opts <> ''
      parse value opts with opt rest '/' opts
      opt = upcase(opt)
      if opt='A' | opt='ASC' | opt='ASCII' then
         mode = 'ascii'
      elseif opt='B' | opt='BIN' | opt='BINARY' then
         mode = 'binary'
      elseif opt='CD' then cd = rest
      else
         sayerror 'Unknown option 'opt' ignored.'
      endif
   enddo
   if olduser<> '' then
      if filename = '' then filename = oldfn; endif
      if machname = '' then machname = oldmachname; endif
      if user     = '' then user     = olduser; endif
      if cd       = '' then cd       = oldcd; endif
      if pass     = '' & machname=oldmachname & user=olduser
                       then pass     = oldpass; endif
      if not mode then mode=oldmode; endif
   endif
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
      sayerror 'Required parm missing: FTPSAVE fname mach_name user [pass] [/a | /b] [/cd dir]'
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
   tempfile = vtemp_path'SAVE'wind'.FTP'
   'xcom save 'tempfile
   If rc then
      sayerror 'Error 'rc' attempting to save temp file 'tempfile
      return
   endif
   'xcom e /c 'cmdfile
   replaceline 'open 'machname, 1
   insertline 'user 'user pass, 2
   insertline mode, 3
   l = length(vTEMP_PATH)
   insertline 'lcd 'substr(vtemp_path,1,L - (L>3 & substr(vTEMP_PATH,L,1)='\')), 4
   if cd<>'' then
      insertline 'cd 'cd, 5
   endif
   insertline 'put SAVE'wind'.FTP' filename, .last+1
   'xcom save'; src = rc
   'xcom quit'
   if src then sayerror 'Error 'src' saving 'cmdfile'.  Command halted.'; stop; endif
   sayerror 'Attempting to put 'filename' to 'machname cd' in 'mode
   outfile = vtemp_path'outp'wind'.ftp'
   quietshell ftp_pgm '-n -v <'cmdfile '>'outfile -- Need Verbose switch to see error msgs
   ftp_rc = rc
   call erasetemp(cmdfile)
   call erasetemp(tempfile)
   If ftp_rc then
      sayerror 'RC from 'FTP_pgm' =' ftp_rc'; outfile='outfile
      rc = ftp_rc
      return
   endif
   'e /d 'outfile
   sayerror 'Check FTP output for error messages, to see if file was sent.'
   call erasetemp(outfile)

