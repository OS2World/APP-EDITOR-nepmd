/****************************** Module Header *******************************
*
* Module Name: afterload.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: afterload.e,v 1.7 2004-06-03 22:35:08 aschn Exp $
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

const
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_AFTERLOAD)
   NEPMD_DEBUG_AFTERLOAD = 0
compile endif

; Added for testing:
compile if not defined(NEPMD_WANT_AFTERLOAD)
   NEPMD_WANT_AFTERLOAD = 1
compile endif


defload
   universal filestoload       -- amount of files from the last edit cmd
   universal firstloadedfid    -- first loaded file from the last edit cmd
   universal defmainprocessed  -- the first defmain sets this to 1
   universal defloadprocessed  -- the first defload sets this to 1
   universal enableafterload   -- set by defload, reset by afterloadcheck
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
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
   call NepmdPmPrintf( 'DEFLOAD: filestoload = 'filestoload', firstloaded = 'firstloadedfid' = 'firstloadedfid.filename)
compile endif
compile if NEPMD_WANT_AFTERLOAD
   if (filestoload < 1) & (defmainprocessed = 1) then
 compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFLOAD: Calling AfterLoadCheck...')
 compile endif
      enableafterload = 1
      'postme AfterLoadCheck'  -- delayed, to not interfere with file loading
   else
 compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFLOAD: AfterLoadCheck not called, filestoload = 'filestoload', defmainprocessed = 'defmainprocessed)
 compile endif
   endif
compile endif

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
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'AFTERLOADCHECK: '.filename', AfterLoad executed')
compile endif
      'AfterLoad'
      enableafterload = 0
   else
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'AFTERLOADCHECK: '.filename', this file was loaded before the last AfterLoad was executed')
compile endif
   endif

; ---------------------------------------------------------------------------
; This cmd is called once after all files were loaded.
defc AfterLoad
   universal nepmd_hini
   universal CurEditCmd
   universal firstloadedfid   -- first loaded file from the last edit cmd
   universal filestoloadmax   -- set in NepmdLoadFile, only used for 'xcom e' and for RingAddToHistory
   universal activatefid      -- used in AfterLoad and AfterLoadActivateFile
   universal defloadactive    -- set by defload, reset by AfterLoad
   universal lastselectedfid  -- set by AfterLoad and defselect
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif

compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
   call NepmdPmPrintf( 'AFTERLOAD: '.filename', CurEditCmd = 'CurEditCmd', filestoloadmax = 'filestoloadmax)
compile endif
--   call NepmdPmPrintf( 'AFTERLOAD: '.filename', CurEditCmd = 'CurEditCmd', filestoloadmax = 'filestoloadmax)

   display -2  -- required, because firstloadedfid.filename activates
               -- firstloadedfid temporarily, which causes the message
               -- "Invalid fileid", if deleted from the ring.

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
   KeyPath = '\NEPMD\User\AutoRestore\Ring\SaveLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled then
      -- Don't process if files loaded by Recompile or 'groups loadgroup'
      if wordpos( CurEditCmd, 'SETPOS LOADGROUP') = 0 then
         -- see FILELIST.E
         -- must not execute 'postme activatefile' at this point
         call RingWriteFilePosition()
      endif
   endif

;  Activate first loaded file of the current edit command -------------------
   if (.filename = GetUnnamedFileName() & filestoloadmax <= 1) then
      -- nop
      -- This happens, if a new empty file is loaded with 'xcom e'. Than no
      -- 'edit' cmd is called.
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( "AFTERLOAD: current file is ".filename", filestoloadmax = "filestoloadmax)
compile endif
   elseif firstloadedfid.filename = '' then
      -- nop
      -- This happens, if the file was already quit.
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( "AFTERLOAD: firstloadedfid = "firstloadedfid" was quit")
compile endif
   elseif firstloadedfid <> '' then
      -- Activate first loaded file from the current edit cmd.
      -- This works only here properly and only when action is posted.
      -- Disabled activatefile in edit.
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'AFTERLOAD: activatefile posted, firstloadedfile = 'firstloadedfid.filename', fid = 'firstloadedfid)
compile endif
      -- Save last to activate fid in a universal var, because firstloadedfid is
      -- used by many other defs.
      activatefid = firstloadedfid
      'postme afterloadactivatefile' activatefid  -- 'postme' required in some rare cases
   endif

   display 2

;  Process hooks ------------------------------------------------------------
   'HookExecute afterload'          -- no need for 'postme' here?
   'HookExecuteOnce afterloadonce'  -- no need for 'postme' here?
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
   call NepmdPmPrintf( 'AFTERLOAD: HookExecute afterload, afterloadonce')
compile endif

;  Process defselect definitions --------------------------------------------
   -- Sometimes defselect is not executed for the first file. To ensure,
   -- that the settings will be processed, it is executed here as well.
   getfileid fid
   if lastselectedfid = fid then
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf('AFTERLOAD: (fid = lastselectedfid) not executing ProcessSelectRefreshInfoline -- '.filename)
compile endif
   else
      -- Change mode or file specific settings, that don't stick with the file
      -- and refresh infolines.
      -- (No Set* defc will perform an infoline refresh here, because defloadactive = 1.)
      'ProcessSelect'
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf('AFTERLOAD: executing ProcessSelectRefreshInfoline -- '.filename', lastselected: ('lastselectedfid') 'lastselectedfid.filename)
compile endif
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
   filestoloadmax = ''
   firstloadedfid = ''

   return

; ---------------------------------------------------------------------------
; Used by afterload
defc afterloadactivatefile
   universal activatefid
   fid = arg(1)
   -- Check if this posted activatefile is the last
   if fid <> activatefid then
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'AFTERLOADACTIVATEFILE: not called, fid = 'fid', last activatefid = 'activatefid)
compile endif
      return
   endif
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
   call NepmdPmPrintf( 'AFTERLOADACTIVATEFILE: activating firstloadedfile = 'fid.filename)
compile endif
   activatefile fid  -- fid must be a var or a fid


