/****************************** Module Header *******************************
*
* Module Name: e3emul.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: e3emul.e,v 1.5 2002-09-16 16:55:27 aschn Exp $
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
/**************************************************************************/
/*  E3EMUL             Version  ==>    3.12/4.13/5.18         90/09/14    */
/**************************************************************************/

; Note:  The following constants should not be changed here.  Instead, anything
; you want different should be copied to your MYCNF.E and modified there.  That
; way, there's no need to merge in your changes when this file is updated.

/* Recommended for OS/2 Comm. Manager:  Copy next 3 or 4 lines to your MYCNF.E:
const                  -- Configuration for E3EMUL:
   HOST_SUPPORT = 'EMUL'  -- Tell E to include E3EMUL for host support.
   USING = 'CM'           -- This enables multiple logical terminal support.
   my_HOSTCOPY = 'AC'     -- Or whatever, *if* you renamed ALMCOS2 to something else.
*/

compile if not defined(SMALL)  -- Now, can be compiled stand-alone and linked in!
   include 'STDCONST.E'
 define INCLUDING_FILE = 'E3EMUL.E'
   tryinclude 'MYCNF.E'

 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif
 compile if not defined(HOST_SUPPORT)
*** Error:  E3EMUL being compiled, but HOST_SUPPORT was not set in MYCNF.E.
 compile endif
const
 compile if not defined(BACKUP_PATH)
   BACKUP_PATH = ''
 compile endif
;compile if not defined(AUTOSAVE_PATH)  -- now use vAUTOSAVE_PATH
;  AUTOSAVE_PATH=''
;compile endif
 compile if not defined(SMARTQUIT)
   SMARTQUIT = 0
 compile endif
 compile if not defined(FILEKEY)
   FILEKEY   = 'F4'  -- Note:  Must be a string (in quotes).
 compile endif
 compile if not defined(WANT_DBCS_SUPPORT)
   WANT_DBCS_SUPPORT = 0
 compile endif
 compile if not defined(DELAY_SAVEPATH_CHECK)
   DELAY_SAVEPATH_CHECK = 0
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
include NLS_LANGUAGE'.e'
compile endif  -- not defined(SMALL)

compile if HOST_SUPPORT<>'EMUL'
*** Error:  E3EMUL being compiled, but HOST_SUPPORT is other than 'EMUL'.
compile endif

const              -- Constants are value 0/No, 1/Yes

      -- to include VM file support
compile if not defined(VM)
   VM  = 1
compile endif
      -- to include MVS file support
compile if not defined(MVS)
   MVS = 0
compile endif
      -- to include KENKAHN's MVS routines
compile if not defined(E3MVS)
   E3MVS = 0
compile endif
      -- RUNTIME governs whether one can configure E3EMUL when editing
compile if not defined(RUNTIME)
   RUNTIME = 0
compile endif
      -- USING could be: MYTE, BOND, E78, CP78, IBM, CM, CM+IBM, or CM+CP78
      -- IBM => SEND/RECEIVE protocol, e.g.
      --        OS/2 EE Communications Manager
      --        3270 Control Program
      --        3270 Emulation Program
      --        3278/79 Emulation Program
      --        INPCS(X)
      --        apparently, FTTERM
      -- CM  => OS/2 EE Communications Manager, using ALMCOPY instead of SEND/RECEIVE
      -- CM+IBM => Multiple protocols; like CM for VM files, IBM for MVS.
      -- CM+CP78 => Multiple adapters; use CM for H:xxx and CP78 for 2:xxx
compile if not defined(USING)
   USING = 'IBM'
compile endif
      -- CM Send & Receive don't work from inside a PM program, so we call them
      -- via EHLLAPI if we're using EPM.  The FTTERM and PMFTERM versions do
      -- work (and EHLLAPI does not), so we let the user override the default.
compile if not defined(USE_EHLLAPI)
   USE_EHLLAPI = 1
compile endif
      -- if you want to be allowed duplicate copies (not views) of files
compile if not defined(DUPLICATES_ALLOWED)
   DUPLICATES_ALLOWED = 1
compile endif
      -- for debug purposes, not normally changed
compile if not defined(DEBUG)
   DEBUG = 0
compile endif
      -- The following is for if you are affected by the ALMCOPY bug that leaves
      -- the cursor the wrong shape:
compile if not defined(FIX_CURSOR)
   FIX_CURSOR = 0
compile endif
      -- Default file mode, if not specified, is 'A'.  Some users might prefer
      -- '*'.  Caution - do not change unless you know what this will do to your
      -- file transfer program.
compile if not defined(DEFAULT_FILEMODE)
   DEFAULT_FILEMODE = 'A'
compile endif
      -- This is the drive letter used on the HOSTCOPY command.
      -- Distinct from HOSTDRIVE, for users who have a real H: drive on the PC.
compile if not defined(HOSTCOPYDRIVE)
   HOSTCOPYDRIVE= 'H'
compile endif
      -- If you want a USER_FTO routine to get called when files are being saved.
      -- This lets you change the default FTO for special cases
      -- (e.g., files that must be RECFM F LRECL 80).
compile if not defined(CALL_USER_FTO)
   CALL_USER_FTO = 0
compile endif

/* A sample user_FTO might be:
   defproc user_FTO(hostfile, var fto, verb)
      universal emulator, hostcopy
      universal hname, htype, hmode
      if verb='SAVE' & htype='ASSEMBLE' then
         if emulator = 'IBM' or emulator = 'CP78' then
            fto = 'LRECL 80 RECFM V ASCII CRLF'     -- For SEND command.
         elseif upcase(substr(hostcopy,1,3))='ALM' then
            fto = '/f=80 /ascii /q'                 -- For ALMCOPY command.
         elseif emulator = 'MYTE' then
            fto = '/f=80 /ascii'                    -- For MYTECOPY command.
         endif  -- (You only need support the HOSTCOPY method(s) you use.)
      endif
*/
compile if    E3MVS
 *** Error - E3MVS should only be specified for E3, not EOS2 or EPM.
compile endif
      -- The default is implicit host support.  If you want:  Edit TEMP FILE A
      -- to load 3 PC files instead of a host file, set the following to 1.
compile if not defined(HOSTDRIVE_REQUIRED)
   HOSTDRIVE_REQUIRED = 0
compile endif
      -- Users who are used to H: as the host drive, but have a real H: drive,
      -- might want to use HA:, HB:, etc. to refer to the host, while just H:
      -- will refer to the workstation.  (This is an alternative to setting
      -- HOSTDRIVE to 'V' or something like that.)  This implies HOSTDRIVE_REQUIRED.
compile if not defined(HOST_LT_REQUIRED)
   HOST_LT_REQUIRED = 0
compile endif
      -- ELEP78 users will want to change the commands used for SEND and RECEIVE.
      -- This isn't used for USING='CP78'
compile if not defined(RECEIVE_CMD)
   RECEIVE_CMD = 'receive'
compile endif
compile if not defined(SEND_CMD)
   SEND_CMD = 'send'
compile endif

definit
  universal emulator, hostcopy, hostcmd, LT, hostdrive, savepath, ftoptions
  universal keep_temp_files, binoptions, vAUTOSAVE_PATH

  emulator = upcase(USING)

compile if defined(my_LT)
   LT = my_LT
compile else
   LT = 'A'
compile endif
                          -- for MYTE with multiple logical terminals
                          -- or IBM (3270CP, OS/2 EE) to indicate a
                          -- default LT or window...

compile if defined(my_hostdrive)
   hostdrive = my_HOSTDRIVE
compile else
   hostdrive = 'H'
compile endif
                          -- should be 'h' for myte, e38 and bond -
                          -- you may attempt to use others for IBM
                          -- emulators, or your own purposes...


compile if defined(my_hostcopy)
   hostcopy= my_hostcopy
compile else
 compile if USING = 'IBM' | USING = 'CP78'  -- 89/10/19 - CP78 now has its own Send/Receive
   hostcopy = ''
 compile elseif USING = 'CM' | USING = 'CM+IBM' | USING = 'CM+CP78'
   hostcopy = 'almcopy'
 compile else
   hostcopy = USING||'copy'
 compile endif
compile endif

                          -- could be mytecopy, e78copy, bondcopy or
                          -- any other command with a similar command
                          -- line syntax, such as almcopy.
                          -- (almcopy multi file capability not yet
                          -- supported)
                          -- Not necessary to specify for emulator =
                          -- 'IBM'

compile if defined(my_hostcmd)
   hostcmd= my_hostcmd
compile else
 compile if USING = 'IBM' | USING = 'CP78'
  compile if USE_EHLLAPI
      hostcmd = 'EHLLAPI'
  compile else
      hostcmd = 'HOSTSYS'
  compile endif
 compile elseif USING = 'CM' | USING = 'CM+IBM' | USING = 'CM+CP78'
   hostcmd = 'OS2CMD'
 compile elseif USING = 'BOND'
   hostcmd = 'VM'
 compile else
   hostcmd = USING||'cmd'
 compile endif
compile endif
                          -- could be MYTECMD, E78CMD, VM (pcvmbond)
                          -- or HOSTSYS.
                          -- If emulator = 'IBM', then must be
                          -- 'HOSTSYS', and the hostsys device driver
                          -- must be installed for applications like
                          -- E3NOTE to work

compile if defined(my_FTOPTIONS)
   ftoptions = my_FTOPTIONS
compile else
 compile if USING = 'IBM'
  compile if USE_EHLLAPI
   ftoptions = 'ASCII CRLF'            -- Omit redirection if EPM (uses EHLLAPI)
  compile else
   ftoptions = 'ASCII CRLF >nul'       -- The minimum for IBM emulators
  compile endif
;  ftoptions = '(ASCII CRLF)'       -- The noisy minimum for IBM emulators
 compile elseif USING = 'MYTE'
   ftoptions = '/ascii'                  -- The minimum for MYTE
 compile elseif USING = 'E78' or USING = 'BOND'
   ftoptions = '/q'
 compile elseif USING = 'CM'  | USING = 'CM+IBM' | USING = 'CM+CP78'
   ftoptions = '/q /ascii'
 compile elseif USING = 'CP78'
   ftoptions = 'ASC Q'
 compile else
   ftoptions = ''
 compile endif
compile endif
                          -- Should you desire to add any options to
                          -- the invocation of your hostcopy command,
                          -- you may add a default set here, and/or
                          -- change them with the FTO command   --
                          -- Use the proper syntax; add slashes as
                          -- necessary - E3EMUL does absolutely NO
                          -- syntax checking on this one!

compile if defined(my_BINOPTIONS)
   binoptions = my_BINOPTIONS
compile else
 compile if USING = 'IBM'
  compile if USE_EHLLAPI
   binoptions = ''                     -- Omit redirection if EPM (uses EHLLAPI)
  compile else
   binoptions = '() >nul'
  compile endif
 compile elseif USING = 'MYTE'
   binoptions = '/b'
 compile elseif USING = 'E78' or USING = 'BOND' or USING = 'CM'  | USING = 'CM+IBM' | USING = 'CM+CP78'
   binoptions = '/b /q'
 compile elseif USING = 'CP78'
   binoptions = 'BIN Q'
 compile else
   binoptions = ''
 compile endif
compile endif
                          -- These options will be used if E3EMUL
                          -- detects the suffix BIN on a VM host file
                          -- This should make it unnecessary for you
                          -- to add /fto to edit most of 'our' VM
                          -- binary files.

compile if defined(my_SAVEPATH)
   SAVEPATH = my_SAVEPATH
compile else
   SAVEPATH = vAUTOSAVE_PATH     -- Default is user's AUTOSAVE path.
compile endif
                          -- If you wish temporary files to be saved
                          -- to a specific subdirectory, name it here
                          -- NOTE: this is different from the
                          -- Temp_Path used in Autosave!  This is for
                          -- the files created in up/downloading your
                          -- host files.
                          -- The syntax is: d:\path\
                          -- DON'T FORGET THE TRAILING BACKSLASH

compile if defined(my_KEEP_TEMP_FILES)
   KEEP_TEMP_FILES = MY_KEEP_TEMP_FILES
compile else
   KEEP_TEMP_FILES = 0
compile endif
                          -- If you wish temporary files to be saved
                          -- even after the editing session is done,
                          -- this should be set to 1.  This is good
                          -- for those of us with recurring file
                          -- transfer problems, or just paranoia :-)

/* definit code */

compile if defined(my_SAVEPATH) and not DELAY_SAVEPATH_CHECK
   call check_savepath()                 -- EPM does it in MAIN.E if no savepath defined, to pick up autosave path saved from Settings dialog.
compile endif
   LT = strip(LT,'b',':')


/**************************************************************************/
/*                                                                        */
/*   PROCS - procedures for host file support                             */
/*                                                                        */
/**************************************************************************/


defproc loadfile(file,options)

   universal hostdrive, savepath, fto

;  Sneaky use of fto here - Larry made it universal, so the EDIT command could
;  pass fto outside the argument list.  From here on in, fto is passed via
;  argument list, and is not global.

   file=strip(file,'B')
   fto=strip(fto,'B')
   hostfileid=''

                          -- sets hostfile, tempfile, thisLT, bin
   hosttype = ishost(file, 'EDIT', hostfile, tempfile, thisLT, bin)
   if hosttype then
      hostfilename = hostdrive||thisLT||hostfile
      create_flag = isoption(options,'C')
      if isoption(options,'N') | create_flag then
         if already_in_ring(file, hostfileid) and not create_flag then
            activatefile hostfileid
         else
            'xcom e /c' options tempfile    -- 'E /C' forces creation of a new file
           .filename=hostfilename
            getfileid hostfileid
            rc = -282  -- sayerror('New file')
         endif
compile if not DUPLICATES_ALLOWED
      elseif already_in_ring(hostfilename, hostfileid) then
         activatefile hostfileid
compile endif
      else
         set_FTO(hostfilename, bin, fto)
         call load_host_file(hostfile, hostfileid,
                                tempfile, thisLT, fto, bin, options)
         if rc then
            activatefile hostfileid     -- make hidden ring active if hidden
         endif
      endif
      call hidden_info(hostfileid, .filename, tempfile, fto, 'EDIT', bin, hosttype)
   else
      'xcom e 'options file             -- vanilla PC file - complex, eh?
   endif


defproc load_host_file(hostfile, var hostfileid, tempfile,
                               thisLT, fto, bin, options)

   universal hostcopy, hostdrive
   universal emulator, keep_temp_files
compile if WANT_DBCS_SUPPORT
   universal country, codepage, ondbcs
compile endif

; LAM:  Check internal flag before doing more expensive call to OS routine:
   if not keep_temp_files then          -- saving tempfiles? overwrite at will
      if exist(tempfile) then           -- Check for existence of prior PC file
         if askyesno(OVERLAY_TEMP1__MSG,1)<>YES_CHAR then
            return 0
         endif
      endif
   endif

   hostfilename = hostdrive||thisLT||hostfile
                                                     -- build download command
   if emulator = 'IBM' | emulator = 'CP78' then
compile if WANT_DBCS_SUPPORT
      p = lastpos('ASCII', fto)
      if p and lastpos(codepage, 932 942) then
         fto = substr(fto, 1, p - 1)'JI'substr(fto, p + 1)
      endif
compile endif
      if emulator<>'IBM' then
         rcv = RECEIVE_CMD
      else
         rcv = 'receive'
      endif
      if thisLT=':' then
         line = 'xcom' rcv tempfile hostfile fto
      else
         line = 'xcom' rcv tempfile thisLT||hostfile fto
      endif
   else
      line = hostcopy HOSTCOPYDRIVE||thisLT||hostfile tempfile fto
   endif
compile if DEBUG
   messagenwait(line)
compile endif

compile if USE_EHLLAPI
   if emulator = 'IBM' then
      rc = EHLLAPI_SEND_RECEIVE(91, substr(line,14))  -- RECEIVE = 91
   else
compile endif
      quiet_shell line                                -- do the download
compile if FIX_CURSOR
      insert_toggle; insert_toggle
compile endif
compile if USE_EHLLAPI        -- added aschn
   endif  -- emulator = 'IBM'
compile endif                 -- added aschn

compile if E3MVS
   rc = isa_E3mvs_filename(rc,Error_msg,'RESET',rc,rc,rc,rc)
compile endif

   getfileid startid
   if rc then                                   -- assume host file not found
      hostrc = rc
      'xcom e 'options' /n .newfile'
      if rc = -274 then  -- Unknown command
         messageNwait(FILE_TRANSFER_CMD_UNKNOWN'  'line)
      else
         if not isoption(options,'Q') then
            call message(FILE_TRANSFER_ERROR__MSG hostrc'.  'HOST_NOT_FOUND__MSG)
         endif
      endif
      rc=-282  -- sayerror('New file')
   else                                                -- good download occurred
      'xcom e /d /q 'options tempfile
      erc = rc
      if keep_temp_files then
         message(SAVED_LOCALLY_AS__MSG upcase(tempfile))
      else
         call erasetemp(tempfile)
      endif
      if erc then
         call message(rc)
      endif
   endif

   getfileid hostfileid                               -- set pertinent file data
   if hostfileid=startid then stop; endif    -- Uh oh - new file wasn't loaded.
   if thisLT then
      .filename=hostdrive||thisLT||hostfile
   else
      .filename=hostdrive':'hostfile
   endif


defproc savefile(given_name)
   universal hostdrive, LT
compile if BACKUP_PATH <> '' & BACKUP_PATH <> '='
   universal backup_path_ok
compile endif
                                             -- prepare given arguments for use
   parse value given_name with name '[' fto ']'
   options=arg(2)

                           -- sets hostfile, tempfile, thisLT, bin
   hosttype = ishost(name, 'SAVE', hostfile, tempfile, thisLT, bin)
   if hosttype then
      hostfilename = hostdrive||thisLT||hostfile
      if .filename=hostfilename then  --assume saving this copy
         getfileid hostfileid
      else
         getfileid hostfileid, hostfilename  --could be saving non-current file
      endif
      call hidden_info(hostfileid, hostfilename, tempfile, fto, 'SAVE', bin, hosttype)
      src=save_host_file(hostfile, tempfile, thisLT, fto, hostfileid, options)  --LAM
      if src then         -- if host error, offer to save on PC
         if askyesno(SAVE_LOCALLY__MSG,1) = YES_CHAR then
            dot = pos('.',tempfile,max(lastpos('\',tempfile),1))  -- Handle '.' in path
            if dot then tempfile=substr(tempfile,1,dot-1); endif
            if exist(tempfile'.TMP') then
               if winmessagebox('', FILE__MSG tempfile'.TMP' OVERLAY_TEMP3__MSG, 16449)=2 then
                  stop
               endif
            endif
            'xcom s 'tempfile'.TMP'
            if rc then return rc; endif
            messageNwait(SAVED_LOCALLY_AS__MSG tempfile'.TMP' PRESS_A_KEY__MSG)  --LAM
         endif
      endif
      call message(1)
      return src
   endif                   --LAM: Don't need ELSE since THEN does a RETURN.
   name=strip(given_name)  -- Allow for brackets in PC names
   name_same = (name = .filename)
   if pos(' ',name) & leftstr(name,1)<>'"' then
      name = '"'name'"'
   endif
compile if BACKUP_PATH
       -- jbl 1/89 new feature.  Editors in the real marketplace keep at least
       -- one backup copy when a file is written.
 compile if BACKUP_PATH <> '='
   if backup_path_ok then
 compile endif
      quietshell 'copy' name MakeBakName() '1>nul 2>nul'
 compile if BACKUP_PATH <> '='
   endif
 compile endif
compile endif
   'xcom s 'options name; src=rc    -- the save code for a vanilla PC file...
   if not rc and name_same then
      .modify=0
      'deleteautosavefile'
   endif
   return src


defproc save_host_file(hostfile, tempfile, thisLT, fto, hostfileid, options)

   universal hostcopy, hostdrive
   universal LT, emulator, keep_temp_files
compile if WANT_DBCS_SUPPORT
   universal country, codepage, ondbcs
compile endif

   getfileid hostfileid
   'xcom save /o 'tempfile   -- Save in OS/2 format.
   if rc then stop endif

   hostfilename = hostdrive||thisLT||hostfile

   if not isoption(options,'Q') then
      call message(SAVING_PROMPT__MSG hostfilename WITH__MSG fto)
   endif
                                     -- build command line
   if emulator = 'IBM' | emulator = 'CP78' then
compile if WANT_DBCS_SUPPORT
      p = lastpos('ASCII', fto)
      if p and lastpos(codepage, 932 942) then
         fto = substr(fto, 1, p - 1)'JI'substr(fto, p + 1)
      endif
compile endif
      if emulator<>'IBM' then
         send = SEND_CMD
      else
         send = 'send'
      endif
      if thisLT=':' then
         line = 'xcom' send tempfile hostfile fto
      else
         line = 'xcom' send tempfile thisLT||hostfile fto
      endif
   else
      line = hostcopy tempfile HOSTCOPYDRIVE||thisLT||hostfile fto
   endif
compile if DEBUG
   messagenwait(line)
compile endif

compile if USE_EHLLAPI
   if emulator = 'IBM' then
      rc = EHLLAPI_SEND_RECEIVE(90,substr(line,11))  -- SEND = 90
   else
compile endif
      quiet_shell line
compile if FIX_CURSOR
      insert_toggle; insert_toggle
compile endif
compile if USE_EHLLAPI        -- added aschn
   endif  -- emulator = 'IBM'
compile endif                 -- added aschn

compile if E3MVS
   rc = isa_E3mvs_filename(rc,Error_msg,'RESET',rc,rc,rc,rc)
compile endif

   if rc then
      messagenwait(HOST_ERROR__MSG rc'; 'HOST_CANCEL__MSG tempfile)
      return 1
   else
      if .filename=hostfilename then
         hostfileid.modify=0                    -- reset 'modify since saved' switch
      endif
      if keep_temp_files then
         message(SAVED_LOCALLY_AS__MSG upcase(tempfile))
      else
         call erasetemp(tempfile)
      endif
   endif
   return 0


defproc namefile(newname)
   universal hostdrive

   hostfileid=''
   parse value upcase(newname) with name '[' fto ']'

                           -- sets hostfile, tempfile, thisLT, bin
   hosttype = ishost(name, 'NAME', hostfile, tempfile, thisLT, bin)
   if hosttype then
      hostfilename = hostdrive||thisLT||hostfile
compile if DUPLICATES_ALLOWED
      getfileid hostfileid
compile else
      if already_in_ring(hostfilename, hostfileid) then -- is file being edited?
         message(ALREADY_EDITING_MSG)
         return 1                          -- then error - two files one name
      endif
compile endif
      call hidden_info(hostfileid, hostfilename, tempfile, fto, 'NAME', bin, hosttype)
      .filename=hostfilename
   elseif parse_filename(newname,.filename) then
      sayerror INVALID_FILENAME__MSG
   else
      if pos(' ',newname) & leftstr(newname,1)<>'"' then
         newname = '"'newname'"'
      endif
      'xcom n 'newname  --  for a vanilla PC name
   endif


defproc quitfile()
   universal keep_temp_files


   'deleteautosavefile'
;  if not pos('.DIR',.filename) and substr(.filename,1,1) <> '.' then
   if substr(.filename,1,1) <> '.' then
;;    if check_for_host_file(.filename) then
      hosttype = ishost(.filename, 'CHECK', hostfile, tempfile, thisLT, bin)
      if hosttype then
         getfileid quitfileid
         call hidden_info(quitfileid, .filename, tempfile, fto, 'QUIT', bin, hosttype)
         if not keep_temp_files then
            call erasetemp(tempfile)
         endif
      endif
   endif
   'xcom_quit'

/* No longer used by E3EMUL.E, but some user code may depend on it... */
defproc check_for_host_file(arg1)
   return ishost(arg1, 'CHECK', hostfile, tempfile, thisLT, bin)


defproc ishost(candidate, verb, var hostfile, var tempfile, var thisLT, var bin)

   universal hostdrive, LT, binoptions, ftoptions, emulator

 -- also returns a numeric value:
 --  0 -- PC  filename
 --  1 -- VM  filename
 --  2 -- MVS filename

compile if DEBUG
;   messagenwait('ishost sees: 'candidate verb hostfile tempfile thisLT bin)
compile endif

   cand = upcase(candidate)
   verb = upcase(verb)
   hostfile = ''
   tempfile = ''
   whynot = ''
   thisLT = ''
   bin = 0

  /* first, find out what sort of file we got here...*/

   parse value cand with '/Q' candidate                --  PRINT command does
   if not candidate then                               -- 'save /q', we strip
      candidate = cand                                  -- this when checking
   endif                                               -- for host file

   if candidate='' then  -- the null filename - PC file
      return 0
   endif
   candidate = strip(candidate)

compile if VM
   if verify(candidate,' ','m') & leftstr(candidate,1)<>'"' then
      if verb = 'CHECK' then  -- don't care about syntax, etc
         return 1
      endif      --LAM:  Don't use ELSEIF if THEN ended w/ RETURN.
      if isa_vm_filename(candidate, hostfile, tempfile, thisLT, bin, whynot) then
         setLT(thisLT)
         return 1
      endif
 compile if HOST_LT_REQUIRED
      if upcase(substr(candidate,1,1))=hostdrive & substr(candidate,3,1)=':' then
 compile elseif HOSTDRIVE_REQUIRED
      if upcase(substr(candidate,1,1))=hostdrive & pos(':', substr(candidate,2,3)) then
 compile endif
         message(candidate LOOKS_VM__MSG whynot)
 compile if HOST_LT_REQUIRED | HOSTDRIVE_REQUIRED
      endif
 compile endif
      return 0
   endif
compile endif

compile if (MVS | E3MVS)
   posp1 = pos('.',candidate)
   posl  = pos(':',candidate)
   posp2 = lastpos('.',candidate)

   test1= pos('''',candidate)   |              /* Fully qualified MVS name ?    */
          pos('(',candidate)    |              /* PDS member specified ?        */
 compile if HOST_LT_REQUIRED
          (posl=3 &                            /* If 'Hx:' then ...             */
 compile else
          (posl   &                            /* If 'H:' or 'Hx:' then ...     */
 compile endif
          substr(candidate,1,1) = hostdrive)   /*   it must be a HOST file      */


   if not pos('\',candidate)  &                /* MVS name cannot contain '\'   */
      test1 then                               /* Fully qualified MVS name ?    */
 compile if E3MVS
      if isa_E3MVS_filename(candidate, hostfile, verb, tempfile, thisLT, bin, whynot) then
 compile else
      if isa_mvs_filename(candidate, hostfile, verb, tempfile, thisLT, bin, whynot) then
 compile endif
         setLT(thisLT)
         return 2
      else
 compile if E3MVS
         call free()
 compile endif
         sayerror(MVS_Error__MSG whynot)
         stop
      endif
   endif
compile endif -- (MVS | E3MVS)

  /* assume PC filename by now... */

   if verb = 'CHECK' then
      return 0
   endif
   if verb = 'NAME' & pos('=',candidate) then
      call parse_filename(candidate,.filename)
   endif
   if isa_pc_filename(candidate, tempfile, whynot) then
      return 0
   endif
   message(candidate LOOKS_PC__MSG whynot)
   return 0


/**************************************************************************/
/*****************************************************************************/

defproc isa_pc_filename(candidate, var tempfile, var error_msg)
   if leftstr(candidate,1)='"' & rightstr(candidate,1)='"' then
      candidate=substr(candidate,2,length(candidate)-2)
   endif
   parse value upcase(candidate) with drive ':' pathfile
   if not pathfile then
      pathfile = drive
      drive = ''
   endif
   if length(drive) > 1 then
      error_msg = PC_DRIVESPEC__MSG drive LONGER_THAN_ONE__MSG
      return 0
   endif
   if length(drive) and verify(drive,'ABCDEFGHIJKLMNOPQRSTUVWXYZ') then
      error_msg = PC_DRIVESPEC__MSG drive IS_NOT_ALPHA__MSG
      return 0
   endif
   if substr(pathfile,1,2)='..' then  -- allow shortening path by '..'
      pathfile = substr(pathfile,3)    -- strip it, check the rest of path
   endif
   if lastpos('\',pathfile) > 1 and pos('\',pathfile) <> 1 then
                            -- We have a path, but it doesn't start with a \
      pathfile = '\'pathfile
   endif
   bad_chars = '"/\:|<>'            --LAM
   if substr(pathfile,1,1)='\' then
      parse value pathfile with +1 pathpiece '\' restofname
      while restofname do
         if verify(pathpiece,bad_chars,'m') then
            error_msg = INVALID_PATH__MSG candidate
            return 0
         endif
         parse value restofname with pathpiece '\' restofname
      endwhile
      name = pathpiece
   else
      name=pathfile
   endif
   parse value name with fname '.' ext
   if verify(fname,bad_chars, 'm') then
      error_msg = INVALID_FNAME__MSG fname
      return 0
   endif
   if ext then
      if verify(ext,bad_chars,'m') then
         error_msg = INVALID_EXT__MSG ext
         return 0
      endif
   endif

   tempfile=''
   return 1

compile if not defined(VALID_LTS)
 compile if USING='CM+CP78'
define VALID_LTS = 'ABCDEFGH12345'
 compile elseif USING='CP78'
define VALID_LTS = 'ABCDE12345'
 compile else
define VALID_LTS = 'ABCDEFGH'
 compile endif
compile endif

--  VM support routines  -----------------------------------------------

compile if VM
defproc isa_vm_filename(candidate,
                        var hostfile, var tempfile, var thisLT, var bin,
                        var error_msg)

   universal hostdrive, LT, savepath, emulator
   universal hname, htype, hmode

   parse value upcase(candidate) with drive ':' hname htype hmode rest

   thisLT = LT
   if not hname then
 compile if HOST_LT_REQUIRED | HOSTDRIVE_REQUIRED
      error_msg = NO_HOST_DRIVE__MSG
      return 0
 compile else
      parse value drive with hname htype hmode rest
      drive = hostdrive||LT
 compile endif
   else
      if length(drive)>2 then
         error_msg = HOST_DRIVELETTER__MSG drive IS_TOO_LONG__MSG
         return 0
      endif
      if substr(drive,1,1)<>hostdrive then
         error_msg = HOST_DRIVELETTER__MSG substr(drive,1,1) INVALID__MSG
         return 0
      endif
      if length(drive)>1 then
         thisLT = substr(drive,2)
         if verify(thisLT,VALID_LTS) then
            error_msg = HOST_LT__MSG thisLT INVALID__MSG
            return 0
         endif
 compile if HOST_LT_REQUIRED
      else
         error_msg = NO_LT__MSG
         return 0
 compile endif
      endif
   endif
compile if USING='CM+CP78'
   if isnum(thisLT) then
      emulator = 'CP78'
   else
      emulator = 'CM'
   endif
compile endif

   if not hmode then                     -- assuming host filename -
      hmode=DEFAULT_FILEMODE             -- will default to your A disk
   elseif hmode<>'*' then
      if length(hmode)>2 then
         error_msg = FM__MSG hmode IS_TOO_LONG__MSG
         return 0
      endif
      if verify(substr(hmode,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ') then
         error_msg = FM1_BAD__MSG
         return 0
      endif
      if length(hmode)>1 and verify(substr(hmode,2,1),'1234567890')  then
         error_msg = FM2_BAD__MSG
         return 0
      endif
   endif

   if not htype then
      error_msg = NO_FT__MSG
      return 0
   endif
   if length(htype)>8 then
      error_msg = FT__MSG htype IS_TOO_LONG__MSG
      return 0
   endif
   bad_chars = ':*~`!%^&()|\{[}];"<,>.?/'
   if verify(htype, bad_chars, 'm') then
      error_msg = BAD_FT__MSG htype
      return 0
   endif

;  if not hname then  -- then htype would already have been reported missing.
;     error_msg = 'fn missing'
;     return 0
;  endif
   if length(hname)>8 then
      error_msg = FN__MSG hname IS_TOO_LONG__MSG
      return 0
   endif
   if verify(hname, bad_chars, 'm') then
      error_msg = BAD_FN__MSG htype
      return 0
   endif

   binpos=lastpos('BIN',htype)

   bin = binpos and (binpos = (length(htype) - 2))

   hostfile=hname htype hmode                   -- remove extra spaces
   tempfile=savepath||pc_chars(hname)'.'pc_chars(substr(htype,1,3))

compile if USING='CM+IBM'
   emulator = 'CM'
compile endif

   return 1
compile endif

--  MVS support routines -----------------------------------------

compile if E3MVS
   include 'e3mvsisa.e'  -- include Ken Kahn's isa-E3mvs-filename routine
compile endif

compile if MVS

defproc isa_mvs_filename(candidate,
                         var hostfile, MVSfunction, var tempfile,
                         var thisLT, var bin,
                         var error_msg)

   universal hostdrive, LT, savepath, emulator

   parse value upcase(candidate) with drive ':' datasetname rest

;; MVSfunction = Upcase(MVSfunction)
   if (MVSfunction = 'QUIT') or (MVSfunction = 'CHECK') then
      return 2
   endif
   if (MVSfunction = 'RESET') then
      return candidate
   endif

   ThisLT=LT
   if datasetname='' then
 compile if HOST_LT_REQUIRED | HOSTDRIVE_REQUIRED
      error_msg = NO_HOST_DRIVE__MSG
      return 0
 compile else
      parse value drive with datasetname rest
 compile endif
   else
      if substr(drive,1,1)<>hostdrive then
         error_msg = HOST_DRIVELETTER__MSG substr(drive,1,1) INVALID__MSG
         return 0
      endif
      if length(drive)>2 then
         error_msg = HOST_DRIVELETTER__MSG drive IS_TOO_LONG__MSG
         return 0
      endif
      if length(drive)>1 then
         thisLT = substr(drive,2)
         if verify(thisLT,VALID_LTS) then
            error_msg = HOST_LT__MSG thisLT INVALID__MSG
            return 0
         endif
 compile if HOST_LT_REQUIRED
      else
         error_msg = NO_LT__MSG
         return 0
 compile endif
      endif
   endif
compile if USING='CM+CP78'
   if isnum(thisLT) then
      emulator = 'CP78'
   else
      emulator = 'CM'
   endif
compile endif

   if pos("'",datasetname) then
      datasetname = substr(datasetname,2,length(datasetname)-2)
      quotes = "'"
   else
      quotes = ''
   endif

   if (length(datasetname) > 44) then
      error_msg = DSN_TOO_LONG__MSG
      return 0
   endif

   if verify(datasetname,'(','m') and
        rightstr(datasetname,1) <> ')' then
      datasetname = datasetname')'
   endif

   parse value datasetname with DsnName '(' member ')' rest

   HostFile = ''
   Qualifiers = 0
   Qual1 = ''
   Qual2 = ''
   Qual3 = ''
   LastQualifier = ''
   Restof_Dsn = DsnName
   do forever
      parse value Restof_Dsn with Qualifier '.' Restof_Dsn
      if Qualifier = '' then leave; endif
      Qualifiers = Qualifiers + 1
      LastQualifier = Qualifier
      if length(Qualifier) > 8 then
         error_msg = QUAL_NUM__MSG Qualifiers '('Qualifier')' QUAL_TOO_LONG__MSG
         return 0
      endif
      if verify(qualifier, ':*~`!%^&()_-+=|\{[}];"<,>.?/', 'm') then
         error_msg = QUAL_NUM__MSG Qualifiers '('Qualifier')' QUAL_INVALID__MSG
         return 0
      endif
      if Qualifiers>1 then
         HostFile = HostFile||'.'||Qualifier
      else
         HostFile = Qualifier
      endif
      if     Qualifiers = 1 then
         Qual1 = Qualifier
      elseif Qualifiers = 2 then
         Qual2 = Qualifier
      elseif Qualifiers = 3 then
         Qual3 = Qualifier
      endif
   enddo

   if member <> '' then
      if substr(member,1,1) = '+' then
         if substr(member,2,1) <> '0' then
            error_msg = GENERATION_NAME__MSG member INVALID__MSG
            return 0
         endif
      elseif substr(member,1,1) = '-' then
         if verify(substr(member,2,1),'123456789') then
            error_msg = GENERATION_NAME__MSG member INVALID__MSG
            return 0
         endif
      elseif length(member) > 8 then
         error_msg = MEMBER__MSG member IS_TOO_LONG__MSG
         return 0
      elseif verify(member, ':*~`!%^&()_-+=|\{[}];"<,>.?/', 'm') then
         error_msg = INVALID_MEMBER__MSG member
         return 0
      endif
   elseif verify(datasetname,'()','m') then
      error_msg = DSN_PARENS__MSG
      return 0
   endif

   if member = '' then
      HostFile = quotes||HostFile||quotes
   else
      HostFile = quotes||HostFile'('member')'quotes
   endif

   if member = '' then
      if Qual3 = '' then
         tempFile = savepath||Qual1'.'substr(LastQualifier,1,3)
      else
         tempFile = savepath||Qual2'.'substr(LastQualifier,1,3)
      endif
   else
      tempFile = savepath||pc_chars(member)'.'substr(LastQualifier,1,3)
   endif

compile if USING='CM+IBM'
   emulator = 'IBM'
compile endif

   return (2)

compile endif


-- COMMON ROUTINES, ETC.  --

defproc pc_chars(str) -- Translate invalid PC chars to $
   do forever
      v = verify(str, '+,"/\[]:|<>=;.', 'M')
      if not v then leave; endif
      str = overlay('$',str,v)
   enddo
   return str

defproc already_in_ring(filename, var tryid)

   getfileid tryid, filename
   return tryid<>''            --LAM


defproc hidden_info(hostfileid, hostfilename, var tempfile, var fto, verb, bin, hosttype)

 /* using a hidden file, we keep track of the host files and any special  */
 /* file transfer options associated with each.                           */

 /* get the hidden file for the information we're keeping                 */

   save_rc = rc
   if verb='NAME' then
      newname=hostfilename
      hostfilename = .filename
   endif

   getfileid savefileid
   'xcom e /n fto.e'
   .visible = 0
   '0'
   getsearch search_command -- Save user's search command.
   display -2              -- disable display of nonfatal error messages
   if hostfileid then
      'xcom l ?'hostfileid' /?'
   else
      'xcom l /'hostfilename
   endif
   found = rc<> -273 -- sayerror('String not found')        --LAM
   display 2               -- reenable display of nonfatal error messages
   setsearch search_command -- Restores user's command so Ctrl-F works.
compile if DEBUG
   if found then
      getline line
      messagenwait('hidden info>>> 'line)
   endif
compile endif


 /* now see what we're supposed to do      */
 /* verbs are EDIT, NAME, QUIT, SAVE       */

   if verb='QUIT' then
      if found then
         getline line
         parse value line with . '/' . '/' tempfile .
         deleteline
      else
         tempfile = ''
      endif
   elseif verb='EDIT'  then
      if found then
         replaceline hostfileid' /'hostfilename' /'tempfile' /'hosttype' /'fto
      else
         top
         insertline  hostfileid' /'hostfilename' /'tempfile' /'hosttype' /'fto
      endif
      set_FTO(hostfilename, bin, fto)
   elseif verb='NAME' then
      if found then
         getline line                                 -- use file transfer opts
         parse value line with . '/' . '/' . '/' oldhosttype '/' hidden_fto       -- kept in entry.
         if not fto then
compile if USING='CM+IBM'
           if hosttype<>oldhosttype then  -- Old ft options no good;
              set_FTO(newname, bin, fto)    -- set to default.
           else
compile endif -- USING='CM+IBM'
              fto=hidden_fto                -- Use the FTO from the hidden file.
compile if USING='CM+IBM'
           endif
compile endif -- USING='CM+IBM'
         endif
         replaceline hostfileid' /'newname' /'tempfile' /'hosttype' /'fto
      else
         top
         insertline  hostfileid' /'newname' /'tempfile' /'hosttype' /'fto
      endif
;;    set_FTO(hostfilename, bin, fto)  -- 93/08: No reason for this when 'NAME'.
   elseif verb='SAVE' then
      if found then
         getline line                                 -- use file transfer opts
         parse value line with . '/' . '/' . '/' . '/' hidden_fto       -- kept in entry.
         if not fto then fto=hidden_fto endif
      else
         top
         insertline  hostfileid' /'hostfilename' /'tempfile' /'hosttype' /'fto
      endif
      set_FTO(hostfilename, bin, fto, savefileid)
   endif

compile if DEBUG
   messagenwait('hid says: 'hostfileid hostfilename tempfile fto hosttype verb bin)
compile endif

   activatefile savefileid
   rc = save_rc


defproc set_FTO(hostfile, bin, var fto)  -- called by hidden_info, loadfile
   universal emulator, ftoptions, binoptions
compile if WANT_DBCS_SUPPORT
   universal country, codepage, ondbcs
compile endif

   fto = strip(fto)
   if not fto then
compile if USING='CM+CP78' | USING='CM+IBM'
      if bin then
         if emulator='CM' then
            fto='/q /b'
         else
 compile if USING='CM+IBM'
  compile if USE_EHLLAPI
            fto = ''                     -- Omit redirection if EPM (uses EHLLAPI)
  compile else
            fto = '() >nul'
  compile endif
 compile else  -- else USING='CM+CP78'
            fto='BIN Q'
 compile endif
         endif
      else
         if emulator='CM' then
            fto='/q /ascii'
         else
 compile if USING='CM+IBM'
  compile if USE_EHLLAPI
           fto = 'ASCII CRLF'            -- Omit redirection if EPM (uses EHLLAPI)
  compile else
           fto = 'ASCII CRLF >nul'       -- The minimum for IBM emulators
  compile endif
 compile else  -- else USING='CM+CP78'
           fto='ASC Q'
 compile endif
         endif
      endif  -- bin
compile else
      if bin then
         fto=binoptions
      else
         fto=ftoptions
      endif
compile endif
   endif  -- not fto

compile if CALL_USER_FTO
   if arg(4) then
      call user_FTO(hostfile, fto, 'SAVE')
   endif
compile endif

   if emulator='IBM' | emulator='CP78' then
compile if MVS or E3MVS
      if not pos(')', hostfile) then  -- Only add RECFM or LRECL if not a PDS member
compile endif
         -- For ASCII upload, add LRECL 255 (avoid "Some records were segmented.").
         if arg(4) & not bin & not pos('LRECL',fto) then  -- Add iff SEND (i.e., arg(4)=1)
compile if MVS or E3MVS
            if pos('.', hostfile) then     -- MVS file
;;             fto='LRECL(255) 'strip(fto,'l','(')  -- Do nothing for MVS files.
            else
compile endif
               getfileid fto_fid
               savefileid = arg(4)
               activatefile savefileid
               if longestline() > 80 then
                  fto='LRECL 255 'strip(fto,'l','(')
               endif
               activatefile fto_fid
compile if MVS or E3MVS
            endif  -- pos('.'
compile endif
         endif
         -- For binary upload, add RECFM V (avoid padding last record so CRCs will match).
         if arg(4) & bin & not pos('RECFM',fto) then     -- Add iff SEND (i.e., arg(4)=1)
            fto='RECFM V 'strip(fto,'l','(')
         endif
compile if MVS or E3MVS
      endif  -- not pos(')'
      if not pos('.', hostfile) then     -- VM file
compile endif
         if substr(fto,1,1)<>'(' then fto='('fto; endif
compile if WANT_DBCS_SUPPORT & 0  -- @DBCS_FIX
         if pos(codepage, 932 942) & not pos('[',fto) then
            fto='['fto
         endif
compile endif
compile if MVS or E3MVS
      else
         fto = strip(strip(fto,'t',')'),'l','(')  -- remove leading '(' & trailing ')'
      endif
compile endif
   endif  -- emulator='IBM' | emulator='CP78'

compile if DEBUG
;  messagenwait('FTO will be: 'fto)
compile endif



defproc setLT(var LT_to_use)
   universal LT, emulator

   if not LT_to_use then
      LT_to_use = LT||':'
   else
      LT_to_use = LT_to_use||':'
   endif

compile if DEBUG
   messagenwait('LT set to: 'LT_to_use)
compile endif



defproc check_savepath()     -- Larry Margolis - MARGOLI at YORKTOWN
   universal savepath

compile if BACKUP_PATH <> '' & BACKUP_PATH <> '='
   universal backup_path_ok
   if rightstr(BACKUP_PATH,1)<>'\' then
      messageNwait(BACKUP_PATH_INVALID_NO_BACKSLASH__MSG'  'NO_BACKUPS__MSG)
   else
      curpath=directory()                                     -- get current disk
      if substr(BACKUP_PATH,2,1)=':' then
         relpath=directory(substr(BACKUP_PATH,1,2))
      else
         relpath=''
      endif
      rc = 0
      call directory(substr(BACKUP_PATH,1,length(BACKUP_PATH)-1))    -- set to BACKUP_PATH
      if rc=-15 then  -- sayerror('Invalid drive')
         bad=DRIVE__MSG                                            -- did we set?
      elseif rc=-3 then  -- sayerror('Path not found')
         bad=PATH__MSG
      endif
      if rc then                                 -- didn't set - BACKUP_PATH invalid
         messageNwait(BACKUP_PATH_INVALID1__MSG bad'.  'NO_BACKUPS__MSG)
      else
         backup_path_ok = 1
      endif
      if relpath then
         call directory(relpath)
      endif
      call directory(curpath)  -- Restore original directory
   endif
compile endif  -- BACKUP_PATH

   if savepath='' then
      savepath=directory()
      if length(savepath)>3 then savepath=savepath'\'; endif   -- if not 'C:\'
;     sayerror SAVEPATH_NULL__MSG
      return 0
   endif

   if rightstr(savepath,1)<>'\' then
      savepath = savepath'\'
   endif

   curpath=directory()                                     -- get current disk
   if substr(savepath,2,1)=':' then
      relpath=directory(substr(savepath,1,2))
   else
      relpath=''
   endif
   rc = 0
   call directory(substr(savepath,1,length(savepath)-1))    -- set to savepath
   if rc=-15 then  -- sayerror('Invalid drive')
      bad=DRIVE__MSG                                            -- did we set?
   elseif rc=-3 then  -- sayerror('Path not found')
      bad=PATH__MSG
   endif
   if rc then                                 -- didn't set - savepath invalid
      sayerror(SAVEPATH_INVALID1__MSG bad SAVEPATH_INVALID2__MSG)
      savepath = substr(curpath,1,3)  -- 'C:\'
   endif
   if relpath then
      call directory(relpath)
   endif
   call directory(curpath)  -- Restore original directory


; This procedure referenced only in SELECT.E - this one works with E3REXKEY
; to allow syntax directed editing for EXEC or XEDIT files.
;
; Gracias, Ken Kahn for the updated code for MVS users
;
; Also works without E3REXKEY to provide syntax directed editing for files
; that have the filetype EBIN, CBIN or PASBIN

defproc filetype()
   universal hostdrive

   filename=arg(1)
   if filename='' then filename=.filename; endif
   if substr(filename, 1, 5)=='.DOS ' then
      return ''
   endif
   filename = upcase(filename)
compile if (MVS | E3MVS)
 compile if HOST_LT_REQUIRED
   isa_host_file = substr(filename,1,1)=hostdrive & substr(filename,3,1)=':'
 compile elseif HOSTDRIVE_REQUIRED
   isa_host_file = substr(filename,1,1)=hostdrive & pos(':', substr(filename,2,3))
 compile endif
compile endif
;        -- LAM - '.' is allowed in PC path name.  Not sure how this affects
;                 MVS check.
   i=lastpos('\',filename)
   if i then
      filename=substr(filename,i+1)
   endif
;         -- LAM - end
   i=lastpos('.',filename)
   if i then                             -- PC or MVS
      PCext = substr(filename,i+1)
compile if (MVS | E3MVS)
 compile if HOST_LT_REQUIRED | HOSTDRIVE_REQUIRED
      if isa_host_file then
 compile else
      if (i>pos('.', filename)) |
         (pos('(',PCext))       |
         (pos("'",PCext))       |
         (length(PCext) > 3) then
 compile endif
         return breakout_mvs(filename,PCext)     -- MVS
      endif
compile endif
      return PCext                       -- PC
   else                                  -- PC (no ext) or VM
      return breakout_vm(filename)        -- handles both
   endif


compile if (MVS | E3MVS)
defproc breakout_mvs(filename,LastQual)
   i = pos('(',LastQual)
   if i then
      LastQual = substr(LastQual,1,i-1)
   endif

   if lastqual='PASCAL' then
      return 'PAS'
   endif
   if lastqual='C' then
      return 'C'
   endif
   if lastqual='SCRIPT' then
      return 'SCRIPT'
   endif
   if lastqual='REXX' | lastqual='EXEC' | lastqual='CLIST' then
      return 'CMD'
   endif
compile endif


defproc breakout_vm(filename)
   if verify(filename,' ','m') then
      parse value filename with . ftype .
      i = lastpos('BIN',ftype)
      if i then
         return substr(ftype,1,i-1)
      endif
      return ftype
   endif


defproc vmfile(var name, var cmdline)
compile if VM  -- procedure defined even if no VM - makes defc EDIT simpler.
   universal hostdrive

 compile if HOST_LT_REQUIRED
   if upcase(substr(name,1,1))<>hostdrive | substr(name,3,1)<>':' then return 0; endif
 compile elseif HOSTDRIVE_REQUIRED
   if upcase(substr(name,1,1))<>hostdrive | pos(':',substr(name,2,2))=0 then return 0; endif
 compile endif

   parse value name with fn ft fm cmdline
   if fn='' or ft='' or length(fn)>11 or pos('\',fn) or pos('.',fn) or
      length(ft)>8 or pos(':',ft) or pos('\',ft) or pos('.',ft) then
      return 0
   endif

   if (not fm) or length(fm)>2 or
      pos(':',fm) or pos('\',fm) or pos('.',fm) then
      cmdline = fm cmdline               -- assumption here:  VM if two
      name = fn ft
      return 1
   endif

   name = fn ft fm
   return 1                              --better be VM at this point
compile else
   return 0
compile endif

/**************************************************************************/
/*                                                                        */
/*   commands for changing variable values                                */
/*                                                                        */
/**************************************************************************/

compile if RUNTIME

defc em, emulator=
   universal hostcopy, LT, hostcmd, emulator

   uparg = upcase(arg(1))
   if uparg = 'IBM' then
      emulator = 'IBM'
      hostcopy = ''
      hostcmd = 'EHLLAPI'
      sayerror EMULATOR_SET_TO__MSG uparg LT_NOW__MSG LT')'
   elseif uparg = 'CP78' then
      emulator = 'CP78'
;     hostcopy = 'cp78copy'
;     hostcmd = 'cp78cmd'
      hostcopy = ''
      hostcmd = 'os2cmd'
      LT = ''
      sayerror EMULATOR_SET_TO__MSG uparg
   elseif uparg = 'CM' then
      emulator = 'CM'
      hostcopy = 'almcopy'
      hostcmd = 'os2cmd'
      sayerror EMULATOR_SET_TO__MSG uparg LT_NOW__MSG LT')'
   elseif not uparg then
      'commandline' EMULATOR__MSG emulator
   else
      sayerror '('uparg')' IS_INVALID_OPTS_ARE__MSG 'IBM, CM, CP78'
      stop
   endif


defc lt=
   universal LT

   uparg = upcase(arg(1))
   if verify(uparg,'ABCDEFGH','M',1) and length(uparg) = 1 then
      LT = uparg
      sayerror LT_SET_TO__MSG LT
   elseif uparg = 'NO_LT' or uparg = 'NONE' or uparg = 'NULL' then
      LT = ''
      sayerror LT_SET_NULL__MSG
   elseif not uparg then
      if not LT then   --changed for space
         'commandline LT No_LT'
      else
         'commandline LT 'LT
      endif
   else
      sayerror '('uparg')' LT_INVALID__MSG
      stop
  endif


defc hd, hostdrive=
   universal hostdrive

   uparg = upcase(arg(1))
   if verify(uparg,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','M',1) and length(uparg)=1 then
      hostdrive = uparg
      sayerror HOSTDRIVE_NOW__MSG hostdrive
   elseif not uparg then  -- changed for space
      'commandline HD 'hostdrive
   else
      sayerror '('uparg')' IS_INVALID_OPTS_ARE__MSG 'A - Z'
      stop
   endif


defc savepath =
   universal savepath

   uparg = upcase(arg(1))
   if not uparg  then  -- changed for space
      'commandline SAVEPATH 'savepath
   else
      savepath = uparg
      call check_savepath(TRY_AGAIN__MSG)
   endif

defc hostcopy =
   universal hostcopy
   if arg(1) then
      hostcopy = arg(1)
   else
      sayerror 'Hostcopy command is' hostcopy
   endif
compile endif  -- RUNTIME

defc fto=
   universal ftoptions

   uparg = upcase(arg(1))
   if not uparg then -- changed for space         -- tell 'em the default
      'commandline FTO 'ftoptions
   else
      ftoptions = uparg
      sayerror FTO_WARN__MSG
   endif

defc bin=
   universal binoptions

   uparg = upcase(arg(1))
   if uparg=='' then                             -- tell 'em the default
      'commandline BIN 'binoptions
   else
      binoptions = uparg
      sayerror BIN_WARN__MSG
   endif

-- SEND & RECEIVE don't work from a PM window, so call via EHLLAPI.
; Following is a common call for Send or Receive.  It does a Set Session Parms
; to 'QUIET', sets up the parameters the way EMUL_HLLAPI wants (VAR parameters)
; and issues the call.
defproc EHLLAPI_SEND_RECEIVE(function, parms)
   universal ondbcs                              -- @DBCS_FIX
   if ondbcs then
       parse value parms with f '(' o
       parms = f '[(' o
   endif                                      -- end DBCS_FIX
   if function=90 or function=91 then
      call EHLLAPI_SEND_RECEIVE(9, 'QUIET TIMEOUT=2')
compile if DEBUG
      messagenwait('Calling function' function' "'parms'"')
compile endif
   endif
compile if not DEBUG
   if echo() then  -- Since user wouldn't see this echoed, let's say it explicitly...
      messagenwait('EHLLAPI_SEND_RECEIVE('function', "'parms'")')
   endif
compile endif
   EHLLAPI_data_string_length = atoi(length(parms)) -- Data string length
   EHLLAPI_host_PS_position = atoi(0)
   result=HLLAPI_call(atoi(function), selector(parms), offset(parms),
                 EHLLAPI_data_string_length, EHLLAPI_host_PS_position)
   if result=3 | result=4 then return 0; endif  -- 3=File Transfer complete;
   return result                                -- 4= Complete with segmented records.

; HLLAPI_call is our general interface for calling the EHLLAPI dynalink.
; Parameters are always the same - an EHLLAPI function number, selector of
; the data string, offset of the data string, the data string length, and
; the host presentation space position.  They might not be used in all calls,
; but EHLLAPI requires that they all be present.
;
; The data string is passed via selector and offset rather than as a VAR string,
; since some calls (e.g., copying the entire host screen) require a string
; larger than 255 bytes, and so we must allocate a buffer and pass that.
; Note:  This is not taken advantage of in E3EMUL.E, but it's a small cost to
; make it available to others, instead of having to duplicate the whole function.
defproc HLLAPI_call(EHLLAPI_function_number,
                    sel_EHLLAPI_data_string, ofs_EHLLAPI_data_string,
                var EHLLAPI_data_string_length, -- Data str. len. or buffer size
                var EHLLAPI_host_PS_position)   -- Host presentation space posn.
                                                -- (on return, RC)
   rc = 0        -- Prepare for missing DLL library
   result=dynalink('ACS3EHAP',                  -- dynamic link library name
                   'HLLAPI',                    -- HLLAPI direct call
                    Thunk(address(EHLLAPI_function_number))    ||
                    Thunk(ofs_EHLLAPI_data_string              || sel_EHLLAPI_data_string)  ||
                    Thunk(address(EHLLAPI_data_string_length)) ||
                    Thunk(address(EHLLAPI_host_PS_position)) )
   if rc then sayerror ERROR__MSG rc FROM_HLLAPI__MSG '-' sayerrortext(rc); stop; endif
   return itoa(EHLLAPI_host_PS_position, 10)

; A simpler EHLLAPI interface - just pass a function number and data string.
; The third and fourth parameters are optional.  Can not be used for calls
; which return data in the data string.
defproc simple_HLLAPI_call(EHLLAPI_function_number, EHLLAPI_data_string)
   if arg(3)='' then
      EHLLAPI_data_string_length = atoi(length(EHLLAPI_data_string))
   else
      EHLLAPI_data_string_length = atoi(arg(3))
   endif
   if arg(4)='' then
      EHLLAPI_host_PS_position = atoi(0)
   else
      EHLLAPI_host_PS_position = atoi(arg(4))
   endif
   return HLLAPI_call(atoi(EHLLAPI_function_number),
                      selector(EHLLAPI_data_string), offset(EHLLAPI_data_string),
                      EHLLAPI_data_string_length, EHLLAPI_host_PS_position)
