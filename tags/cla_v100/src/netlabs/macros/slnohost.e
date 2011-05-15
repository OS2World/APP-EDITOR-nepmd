/****************************** Module Header *******************************
*
* Module Name: slnohost.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
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
      name_same = (name = .filename)
      if pos(' ',name) & leftstr(name,1)<>'"' then
         name = '"'name'"'
      endif
      -- jbl 1/89 new feature.  Editors in the real marketplace keep at least
      -- one backup copy when a file is written.
compile if BACKUP_PATH
      quietshell 'copy' name MakeBakName() '1>nul 2>nul'
compile endif
   endif
   'xcom s 'arg(2) name; src=rc
   if not rc and name_same then
      .modify=0
      'deleteautosavefile'
   endif
   return src

defproc namefile()
   newname=arg(1)
   if parse_filename(newname,.filename) then
      sayerror INVALID_FILENAME__MSG
   else
      if pos(' ',newname) & leftstr(newname,1)<>'"' then
         newname = '"'newname'"'
      endif
      'xcom n 'newname
   endif

defproc quitfile()

   'deleteautosavefile'
   'xcom q'

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
