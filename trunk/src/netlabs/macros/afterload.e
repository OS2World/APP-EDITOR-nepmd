/****************************** Module Header *******************************
*
* Module Name: afterload.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: afterload.e,v 1.8 2004-07-02 10:46:43 aschn Exp $
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

; This file is included after LOAD.E and MYLOAD.E.

defload
   universal filestoload       -- amount of files from the last edit cmd
   universal firstloadedfid    -- first loaded file from the last edit cmd
   universal defmainprocessed  -- the first defmain sets this to 1
   universal defloadprocessed  -- the first defload sets this to 1
   universal enableafterload   -- set by defload, reset by afterloadcheck
   universal fileslastloaded   -- amount of files since last AfterLoadActivate
;  Call AfterLoad -----------------------------------------------------------
   -- filestoload is set by edit -> NepmdLoadFile
   if filestoload = '' then
      -- This happens, if a new empty file is loaded with 'xcom e'. Then no
      -- 'edit' cmd is called.
      filestoload = 0
   endif

   if firstloadedfid = '' & .visible then
      -- This happens, if a file is loaded with 'xcom e'. Then no 'edit' cmd
      -- is called.
      -- Ensure that afterload activates the new file, because the Ring*
      -- macros, called by afterload, sometimes leave the wrong file on top.
      getfileid firstloadedfid
   endif

   if fileslastloaded = '' then
      fileslastloaded = 0
   endif
   fileslastloaded = fileslastloaded + 1
/*
   getfileid fid
   if fid = firstloadedfid then
      call WriteFileNumber()
   endif
*/
   filestoload = filestoload - 1
   -- Call NepmdAfterLoad only if this loaded file is the last or the only
   -- file to load and if DEFMAIN is already processed. (Sometimes DEFLOAD
   -- is triggered before all DEFMAIN stuff is processed. DEFMAIN itself
   -- calls NepmdAfterLoad if not already called by DEFLOAD.)
   if (filestoload < 1) then
      -- all DEFLOADs of the current edit cmd are processed
      defloadprocessed = 1  -- used in defmain
   endif
   dprintf( 'AFTERLOAD', 'DEFLOAD: filestoload = 'filestoload', firstloaded = 'firstloadedfid' = 'firstloadedfid.filename)
   if (filestoload < 1) & (defmainprocessed = 1) then
      dprintf( 'AFTERLOAD', 'DEFLOAD: Calling AfterLoadCheck...')
      enableafterload = 1
      'postme AfterLoadCheck'  -- delayed, to not interfere with file loading
   else
      dprintf( 'AFTERLOAD', 'DEFLOAD: AfterLoadCheck not called, filestoload = 'filestoload', defmainprocessed = 'defmainprocessed)
   endif

; ---------------------------------------------------------------------------
; Called by defload, not by defmain.
; Check if a new defload occured after the last AfterLoad was executed.
;
; This decreases the executed AfterLoads quite much. In almost every
; cases AfterLoad is executed only once now. Otherwise AfterLoad was called
; for every defload.
;
; Note: Recompile causes AfterLoad to get executed two times or more for
; multiple files, because EPM is opened with the first file before loading
; the rest with a delay. A large amount of PmPrintf outputs can delay file
; loading as well.
defc AfterLoadCheck
   universal enableafterload  -- set by defload, reset by afterloadcheck
   if enableafterload then
      dprintf( 'AFTERLOAD', 'AFTERLOADCHECK: '.filename', AfterLoad executed')
      'AfterLoad'
      enableafterload = 0
   else
      dprintf( 'AFTERLOAD', 'AFTERLOADCHECK: '.filename', this file was loaded before the last AfterLoad was executed')
   endif

; ---------------------------------------------------------------------------
; This cmd is called once after all files were loaded.
defc AfterLoad
   universal CurEditCmd
   universal firstloadedfid   -- first loaded file from the last edit cmd
   universal filestoloadmax   -- set in NepmdLoadFile, only used for 'xcom e' and for RingAddToHistory
   universal activatefid      -- used in AfterLoad and AfterLoadActivateFile
   universal defloadactive    -- set by defload, reset by AfterLoad
   universal lastselectedfid  -- set by AfterLoad and defselect
   universal fileslastloaded  -- since last AfterLoadActivate
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif

   dprintf( 'AFTERLOAD', .filename', CurEditCmd = 'CurEditCmd', filestoloadmax = 'filestoloadmax)

;  Write number for all files in the ring to an array var -------------------
   -- see FILELIST.E
   -- must not execute 'postme activatefile' at this point
   call RingWriteFileNumber()

;  Write name of all files in the ring to NEPMD.INI -------------------------
   -- We want do this only for single files, not for wildcards in filespec
   if filestoloadmax <= 1 then
      call RingAddToHistory('LOAD')
   endif

;  Write position and name of all files in the ring to NEPMD.INI ------------
   -- Don't process if files loaded by Recompile or 'groups loadgroup'
   if wordpos( CurEditCmd, 'SETPOS LOADGROUP') = 0 then
      -- see FILELIST.E
      -- must not execute 'postme activatefile' at this point
      call RingAutoWriteFilePosition()
   endif

   activatefid = firstloadedfid
   'postme AfterloadActivateFile' activatefid  -- 'postme' required in some rare cases

;  Process hooks ------------------------------------------------------------
   'HookExecute afterload'          -- no need for 'postme' here?
   'HookExecuteOnce afterloadonce'  -- no need for 'postme' here?
   dprintf( 'AFTERLOAD', 'HookExecute afterload, afterloadonce')

;  Process defselect definitions --------------------------------------------
   -- Sometimes defselect is not executed for the first file. To ensure,
   -- that the settings will be processed, it is executed here as well and
   -- disabled for that file this only time to not repeat it if defselect
   -- tries to do that.
   getfileid fid
   if lastselectedfid = fid then
      dprintf( 'AFTERLOAD', '(fid = lastselectedfid) not executing ProcessSelectRefreshInfoline -- '.filename)
   else
      -- Change mode or file specific settings, that don't stick with the file
      -- and refresh infolines.
      -- (No Set* defc will perform an infoline refresh here, because defloadactive = 1.)
      'ProcessSelect'
      display -2  -- avoid msg 'Invalid fileid', when lastselectedfid = ''
      dprintf( 'AFTERLOAD', 'executing ProcessSelectRefreshInfoline -- '.filename', lastselected: ('lastselectedfid') 'lastselectedfid.filename)
      display 2
      lastselectedfid = fid  -- avoid repeating this by defselect for this file
   endif

;  Change EPM pointer from standard arrow to text pointer -------------------
;     bug fix (hopefully): even standard EPM doesn't show everytime the
;                          correct pointer after a new edit window was opened
;     defined in defc initconfig, STDCTRL.E
compile if EPM_POINTER = 'SWITCH'
   'postme setmousepointer 'vEPM_POINTER
compile else
   'postme setmousepointer 'EPM_POINTER
compile endif

;  Reset universal vars, set by edit and NepmdLoadFile ----------------------
   defloadactive = 0
   --filestoloadmax = ''
   -- Must be reset here, not only by AfterloadActivateFile
   firstloadedfid = ''
   filestoloadmax = ''

   return

; ---------------------------------------------------------------------------
; Used by afterload
; Resets CurEditCmd (only set by Edit, not by xcom Edit)
defc AfterloadActivateFile
   universal filestoloadmax
   universal activatefid
   universal CurEditCmd
   universal fileslastloaded
   if fileslastloaded = '' then
      fileslastloaded = 0
   endif

   argfid = arg(1)   -- file to activate
   getfileid curfid  -- currently on top

   -- For 'xcom edit' CurEditCmd is empty.
   -- Just for debugging, before it will be reset.
   display -2
   dprintf( 'RESTORE_POS', 'AfterloadActivateFile: CureditCmd = 'CurEditCmd', curfile ('curfid') 'curfid.filename)
   display 2

   SubmittedIsNotInRing = 0  -- quit in the meantime?
   SubmittedIsHidden    = 0  -- hidden file?
   SubmittedIsNotLast   = 0  -- other file loaded in the meantime?
   OtherActivated       = 0  -- another file activated during file loading?
   AlreadyOnTop         = 0  -- already activated?

   display -2
   dprintf( 'AFTERLOAD_ACTIVATE', 'filestoloadmax  = 'filestoloadmax)
   dprintf( 'AFTERLOAD_ACTIVATE', 'fileslastloaded = 'fileslastloaded)
   dprintf( 'AFTERLOAD_ACTIVATE', 'curfid          = ('curfid') 'curfid.filename)
   dprintf( 'AFTERLOAD_ACTIVATE', 'arg(1)          = ('argfid') 'argfid.filename)
   dprintf( 'AFTERLOAD_ACTIVATE', 'activatefid     = ('activatefid') 'activatefid.filename)
   display 2

   -- Check if argfid is still valid.
   if ValidateFileid(argfid) = 0 then
      SubmittedIsNotInRing = 1
   elseif ValidateFileid(argfid) = 4 then
      SubmittedIsHidden = 1
   endif
   -- Check if argfid is the last to be activated. activatefid will be set
   -- immediately by Afterload, while this check processes in the posted part.
   if argfid <> activatefid then
      SubmittedIsNotLast = 1
   endif
   -- Check if argfid > curfid. Maybe another file was activated in the
   -- meantime. Important, when 'activatefile' is followed by 'edit' in a
   -- macro, before afterload was processed.
   -- Assume, that activatefile was only processed, when 1 new file was
   -- loaded. Therefore the amount of loaded files since last
   -- AfterloadActivateFile is counted.
   if curfid < argfid & fileslastloaded = 1 then
      OtherActivated = 1
   endif
   -- Check if argfid is already on top. No need to activate it.
   if curfid = argfid then
      AlreadyOnTop = 1
   endif

   display -2
   if SubmittedIsNotInRing = 1 then
      dprintf( 'AFTERLOAD_ACTIVATE', '1: not executed, not in ring, fid = ('argfid')')
   endif
   if SubmittedIsHidden = 1 then
      dprintf( 'AFTERLOAD_ACTIVATE', '2: not executed, hidden, fid = ('argfid')')
   endif
   if SubmittedIsNotLast = 1 then
      dprintf( 'AFTERLOAD_ACTIVATE', '3: not executed, fid = ('argfid'), last activatefid = 'activatefid)
   endif
   if OtherActivated = 1 then
      dprintf( 'AFTERLOAD_ACTIVATE', '4: not executed, other activated, curfid = 'curfid', activatefid = ('argfid')')
   endif
   display 2

   if (SubmittedIsNotInRing = 0) & (SubmittedIsHidden = 0) & (SubmittedIsNotLast = 0) &
      (OtherActivated = 0) then
      dprintf( 'AFTERLOAD_ACTIVATE', 'activating file ('argfid') 'argfid.filename)

      activatefile argfid  -- argfid must be a var or a fid

      -- Reset universal var for next Edit cmd (but Xcom Edit won't set it)
      CurEditCmd = ''
      fileslastloaded = 0

   endif


