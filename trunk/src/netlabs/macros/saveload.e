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
compile if EVERSION >= '4.10'
         'xcom e' options '/c .'   -- 'E /C' forces creation of a new file
compile else
         'xcom e' options '/n .'   -- Old E; must rely on using an unlikely name
compile endif
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
compile if EVERSION >= '5.50'  --@HPFS
   name_same = (name = .filename)
compile endif
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
 compile if EVERSION >= '5.50'  --@HPFS
      if pos(' ',name) & leftstr(name,1)<>'"' then
         name = '"'name'"'
      endif
 compile endif
       -- jbl 1/89 new feature.  Editors in the real marketplace keep at least
       -- one backup copy when a file is written.
 compile if EVERSION >= '4.10'    -- OS/2 - redirect STDOUT & STDERR
      quietshell 'copy' name MakeBakName() '1>nul 2>nul'
 compile else
      quietshell 'copy' name MakeBakName() '>nul'
 compile endif
compile endif
   endif            /* meaningful error codes.                          */
compile if BACKUP_PATH = '' & EVERSION >= '5.50'  --@HPFS
   if pos(' ',name) & leftstr(name,1)<>'"' then
      name = '"'name'"'
   endif
compile endif
   options=arg(2)
   'xcom s 'options name; src=rc
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
   universal hostfileid,hostfilespec,hname,htype,hmode
   newname=arg(1)
   if check_for_host_file(newname) then
      .filename=HOSTDRIVE||hostfilespec
   elseif parse_filename(newname,.filename) then
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
   universal hostfileid,hostfilespec,hname,htype,hmode

compile if EVERSION < 5
   if .windowoverlap then
      modify=(.modify and .views=1)
   else
      modify=.modify
   endif
   k='Y'
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

compile if not EPM
   call message(LOADING__MSG HOSTDRIVE||hostfilespec)
compile endif
   quiet_shell hostcopy HOSTCOPYDRIVE||hname htype hmode vTEMP_PATH'eeeeeeee.'hostfileid HOSTCOPYOPTIONS
compile if E3  -- Only E3 generates an "Insufficient memory" error.
   if rc=sayerror("Insufficient memory") then
      stop
   endif
compile endif
   if rc then /* assume host file not found */
      'xcom e 'options '/n .newfile'
      call message(HOST_NOT_FOUND__MSG)
      rc=-282  -- sayerror('New file')
   else
      'xcom e 'options vTEMP_PATH'eeeeeeee.'hostfileid
      if rc then
         call message(rc)
         return
compile if not EPM
      else
         call message(1)
compile endif
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
compile if not EPM
   call message(SAVING__MSG HOSTDRIVE||hostfilespec)
compile endif
   /* is this a binary file ? */
   if length(htype)>=3 then
compile if EVERSION >= '5.17'
      if upcase(rightstr(htype,3))=='BIN' then
compile else
      if upcase(substr(htype,length(htype)-2))=='BIN' then
compile endif
         hostfilespec=hostfilespec '/b'
      endif
   endif
   quiet_shell hostcopy vTEMP_PATH'eeeeeeee.'hostfileid' 'HOSTCOPYDRIVE||hostfilespec HOSTCOPYOPTIONS
   if rc then
compile if E3  -- Only E3 generates an "Insufficient memory" error.
      if rc=sayerror('Insufficient memory') then
         emsg = 'Insufficient memory to call' hostcopy
      else
         emsg = 'Host error 'rc'; host save cancelled'
      endif
      sayerror emsg'.  File saved in 'vTEMP_PATH'eeeeeeee.'hostfileid
compile else
      sayerror HOST_ERROR__MSG rc'; 'HOST_CANCEL__MSG vTEMP_PATH'eeeeeeee.'hostfileid
compile endif
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
