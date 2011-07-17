/****************************** Module Header *******************************
*
* Module Name: saveload.e
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
/*   procedures for host file support   */
/*                                      */
/****************************************/

compile if not defined(HOSTDRIVE)
const
   HOSTDRIVE= 'H:'         -- Dummy drive letter to stand for Host files.
compile endif              -- Make sure the drive letter is in upper case.

compile if not defined(HOSTCOPYDRIVE)
const
   HOSTCOPYDRIVE= 'H:'     -- This is the drive letter used on the HOSTCOPY
compile endif              -- command.  Distinct from HOSTDRIVE, for users who
                           -- have a real H: drive on the PC.

compile if not defined(HOSTCOPYOPTIONS)
const
   HOSTCOPYOPTIONS= ''     -- Any options you want appended to the HOSTCOPY
compile endif              -- command.  E.g., for CP78COPY, you might want '/Q'.

defproc loadfile(files,options)
   universal hostfileid,hostfilespec

   if check_for_host_file(files) then
      /* check if file is already in ring */
      hostall = HOSTDRIVE||hostfilespec
      getfileid hostfileid,hostall
      create_flag = isoption(options,'C')
      if hostfileid='' | isoption(options,'D') | create_flag then
         'xcom e' options '/c .'   -- 'E /C' forces creation of a new file
         if isoption(options,'N') | create_flag then
            .filename=hostall
         else
            getfileid hostfileid
            'xcom q'
            call load_host_file(options)
         endif
      else
         activatefile hostfileid
      endif
   else
      'xcom e' options files
   endif

defproc savefile(name)
   name_same = (name = .filename)
   options = check_for_printer(name)    -- Returns 0 or printer number.
   if options then                      -- If a printer (i.e., non-zero),
      if not printer_ready(options) then  -- and it's not ready,
         call messageNwait(PRINTER_NOT_READY__MSG'  'PRESS_A_KEY__MSG)
         return 1
      endif
   elseif check_for_host_file(name) then
      call save_host_file(name)
      return 0      /* Return 0, some terminal emulators do not give us */
compile if BACKUP_PATH
   else
      if pos(' ',name) & leftstr(name,1)<>'"' then
         name = '"'name'"'
      endif
       -- jbl 1/89 new feature.  Editors in the real marketplace keep at least
       -- one backup copy when a file is written.
      quietshell 'copy' name MakeBakName() '1>nul 2>nul'
compile endif
   endif            /* meaningful error codes.                          */
compile if    BACKUP_PATH = ''
   if pos(' ',name) & leftstr(name,1)<>'"' then
      name = '"'name'"'
   endif
compile endif
   options=arg(2)
   'xcom s 'options name; src=rc
   if not rc and name_same then
      .modify=0
      'deleteautosavefile'
   endif
   return src

defproc namefile()
   universal hostfileid,hostfilespec,hname,htype,hmode
   newname=arg(1)
   if check_for_host_file(newname) then
      .filename=HOSTDRIVE||hostfilespec
   elseif parse_filename(newname,.filename) then
      sayerror INVALID_FILENAME__MSG
   else
      if pos(' ',newname) & leftstr(newname,1)<>'"' then
         newname = '"'newname'"'
      endif
      'xcom n 'newname
   endif

defproc quitfile()
   universal hostfileid,hostfilespec,hname,htype,hmode

   'deleteautosavefile'
   'xcom q'

/* warning this procedure may sayerror Invalid host filename and stop */
defproc check_for_host_file
   universal hostfileid,hostfilespec,hname,htype,hmode

   hostfilespec=upcase(strip(arg(1)))
   i=pos(HOSTDRIVE,hostfilespec)
   if i<>1 then return 0 endif  -- Ver. 3.09  Don't accept garbage before H:
   hostfilespec=substr(hostfilespec,i+length(HOSTDRIVE))
   parse value hostfilespec with hname htype hmode
   if hmode='' then hmode='A';hostfilespec=hostfilespec hmode endif
   if htype='' or length(hmode)>2 then sayerror INVALID_FILENAME__MSG;stop endif
   if verify(hostfilespec,':;?*\/|><.,','M') then
      sayerror BAD_FILENAME_CHARS__MSG
      stop
   endif
   hostfilespec=hname htype hmode   /* remove extra spaces */
   return 1

defproc load_host_file(options)
   universal hostfileid,hostfilespec,hname,htype,hmode
   universal hostcopy
   universal vTEMP_PATH

   quiet_shell hostcopy HOSTCOPYDRIVE||hname htype hmode vTEMP_PATH'eeeeeeee.'hostfileid HOSTCOPYOPTIONS
   if rc then /* assume host file not found */
      'xcom e 'options '/n .newfile'
      call message(HOST_NOT_FOUND__MSG)
      rc=-282  -- sayerror('New file')
   else
      'xcom e 'options vTEMP_PATH'eeeeeeee.'hostfileid
      if rc then
         call message(rc)
         return
      endif
   endif
   call erasetemp(vTEMP_PATH'eeeeeeee.'hostfileid)
   .filename=HOSTDRIVE||hostfilespec

defproc save_host_file
   universal hostfileid,hostfilespec,hname,htype,hmode
   universal hostcopy
   universal vTEMP_PATH

   getfileid hostfileid
   'xcom save' vTEMP_PATH'eeeeeeee.'hostfileid
   if rc then stop; endif
   /* is this a binary file ? */
   if length(htype)>=3 then
      if upcase(rightstr(htype,3))=='BIN' then
         hostfilespec=hostfilespec '/b'
      endif
   endif
   quiet_shell hostcopy vTEMP_PATH'eeeeeeee.'hostfileid' 'HOSTCOPYDRIVE||hostfilespec HOSTCOPYOPTIONS
   if rc then
      sayerror HOST_ERROR__MSG rc'; 'HOST_CANCEL__MSG vTEMP_PATH'eeeeeeee.'hostfileid
      stop
   endif
   if arg(1) = .filename then .modify=0; endif
   call erasetemp(vTEMP_PATH'eeeeeeee.'hostfileid)
   call message(1)


defproc filetype()        -- Ver. 3.09 - split out from Select.E
   universal htype
   fileid=arg(1)
   if fileid='' then fileid=.filename; endif
   if substr(fileid, 1, 5)=='.DOS ' then
      return ''
   endif
   if check_for_host_file(fileid) then
      return htype
   endif
   i=lastpos('\',fileid)
   if i then
      fileid=substr(fileid,i+1)
   endif
   i=lastpos('.',fileid)
   if i then
      return upcase(substr(fileid,i+1))
   endif
;  return ''       -- added by ET; no need to duplicate.

defproc vmfile(var name, var cmdline)

  parse value name with fn ft fm cmdline

  if upcase(substr(fn,1,length(HOSTDRIVE)))<>HOSTDRIVE or pos('\',fn) or
     pos('.',fn) or length(ft)>8 or pos(':',ft) or
     pos('\',ft) or pos('.',ft) then
    return 0
  endif

  if fm='' or length(fm)>2 or verify(substr(fm,2,1),'1234567890 ') or
     pos(':',fm) or pos('\',fm) or pos('.',fm) then
    cmdline = fm cmdline
    name = fn ft
    return 1
  endif

  name = fn ft fm
  return 1                             --better be VM at this point
