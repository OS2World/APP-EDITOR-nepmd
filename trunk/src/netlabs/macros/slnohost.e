/****************************** Module Header *******************************
*
* Module Name: slnohost.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: slnohost.e,v 1.2 2002-07-22 19:01:50 cla Exp $
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
/****************************************/
/*            SLNoHost.E                */
/*  procedures for file saving/loading  */
/*                                      */
/*              WITHOUT                 */
/*         host file support            */
/*         (saves about 1K)             */
/****************************************/

defproc loadfile(files,options)
   'xcom e 'options files

defproc savefile(name)
   src = check_for_printer(name)        -- Returns 0 or printer number.
   if src then                          -- If a printer (i.e., non-zero),
      if not printer_ready(src) then    -- and it's not ready,
         call messageNwait(PRINTER_NOT_READY__MSG'  'PRESS_A_KEY__MSG)
         return 1
      endif
   else                                 -- Not a printer:
compile if EVERSION >= '5.50'  --@HPFS
      name_same = (name = .filename)
      if pos(' ',name) & leftstr(name,1)<>'"' then
         name = '"'name'"'
      endif
compile endif
      -- jbl 1/89 new feature.  Editors in the real marketplace keep at least
      -- one backup copy when a file is written.
compile if BACKUP_PATH
 compile if EVERSION >= '4.10'    -- OS/2 - redirect STDOUT & STDERR
      quietshell 'copy' name MakeBakName() '1>nul 2>nul'
 compile else
      quietshell 'copy' name MakeBakName() '>nul'
 compile endif
compile endif
   endif
   'xcom s 'arg(2) name; src=rc
compile if EVERSION >= '5.50'  --@HPFS
   if not rc and name_same then
compile else
   if not rc and name=.filename then
compile endif
      .modify=0
      'deleteautosavefile'
   endif
   return src

defproc namefile()
   newname=arg(1)
   if parse_filename(newname,.filename) then
      sayerror INVALID_FILENAME__MSG
   else
compile if EVERSION >= '5.50'  --@HPFS
      if pos(' ',newname) & leftstr(newname,1)<>'"' then
         newname = '"'newname'"'
      endif
compile endif
      'xcom n 'newname
   endif

defproc quitfile()
compile if EVERSION < 5
   k='Y'
   if .windowoverlap then
      modify=(.modify and .views=1)
   else
      modify=.modify
   endif
   if modify then
 compile if SMARTQUIT
      call message(QUIT_PROMPT1__MSG '('FILEKEY')')
 compile else
      call message(QUIT_PROMPT2__MSG)
 compile endif
      loop
         k=upcase(getkey())
 compile if SMARTQUIT
         if k=$FILEKEY then 'File'; return 1              endif
 compile endif
         if k=YES_CHAR or k=NO_CHAR or k=esc then leave            endif
      endloop
      call message(1)
   endif
   if k<>YES_CHAR then
      return 1
   endif
   if not .windowoverlap or .views=1 then
     .modify=0
   endif
compile endif

   'deleteautosavefile'
compile if EVERSION < 5
   if .windowoverlap then
      quitview
   else
      'xcom q'
   endif
compile else
   'xcom q'
compile endif

defproc filetype()
   fileid=arg(1)
   if fileid='' then fileid=.filename  endif
   if substr(fileid, 1, 5)=='.DOS ' then
      return ''
   endif
   i=lastpos('\',fileid)
   if i then
      fileid=substr(fileid,i+1)
   endif
   i=lastpos('.',fileid)
   if i then
      return upcase(substr(fileid,i+1))
   endif
