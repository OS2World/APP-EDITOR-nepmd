/****************************** Module Header *******************************
*
* Module Name: afterload.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: afterload.e,v 1.3 2004-02-29 17:12:02 aschn Exp $
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

/*
Todo:
-  Move defc activatefile
*/

; This file is included after load.e and myload.e.

const
compile if not defined(NEPMD_RESTORE_RING)  --<----------------------------------------- Todo
; switch save/restore of edit ring on/off
   NEPMD_RESTORE_RING = 1
compile endif
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_AFTERLOAD)
   NEPMD_DEBUG_AFTERLOAD = 0
compile endif


defload
   universal filestoload
   universal defmainprocessed
   universal defloadprocessed
; --- Call NepmdAfterLoad ---------------------------------------------------
   -- filestoload is set by edit -> NepmdLoadFile
   if filestoload = '' then
      -- This happens, if a new empty file is loaded with 'xcom e'. Then no
      -- 'edit' cmd is called.
      filestoload = 0
   endif
   filestoload = filestoload - 1
   -- Call NepmdAfterLoad only if this loaded file is the last or the only
   -- file to load and if DEFMAIN is already processed. (Sometimes DEFLOAD
   -- is triggered before all DEFMAIN stuff is processed. DEFMAIN itself
   -- calls NepmdAfterLoad if not already called by DEFLOAD.)
   if (filestoload < 1) then
      -- all DEFLOADs of the current edit cmd are processed
      defloadprocessed = 1  -- used in defmain
   endif
   if (filestoload < 1) & (defmainprocessed = 1) then
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFLOAD: Calling AfterLoad...')
compile endif
      'postme AfterLoad'
   else
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFLOAD: AfterLoad not called, filestoload = 'filestoload', defmainprocessed = 'defmainprocessed)
compile endif
   endif

; ---------------------------------------------------------------------------
; This cmd is called once after all files were loaded.
defc AfterLoad
   universal CurEditCmd
   universal firstloadedfid
   universal filestoloadmax  -- set in NepmdLoadFile, only used for 'xcom e'.

compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
   call NepmdPmPrintf( 'AFTERLOAD: '.filename', CurEditCmd = 'CurEditCmd', filestoloadmax = 'filestoloadmax)
compile endif

; --- Write number for all files in the ring to an array var ----------------
   -- see FILELIST.E
   -- must not execute 'postme activatefile' at this point
   call RingWriteFileNumber()

; --- Write position and name of all files in the ring to NEPMD.INI ---------
compile if NEPMD_RESTORE_RING
   -- Don't process if files loaded by Recompile or 'groups loadgroup'
   if wordpos( CurEditCmd, 'SETPOS LOADGROUP') = 0 then
      -- see FILELIST.E
      -- must not execute 'postme activatefile' at this point
      call RingWriteFilePosition()
   endif
compile endif

; --- Activate first loaded file of the current edit command ----------------
   if (.filename = GetUnnamedFileName() & filestoloadmax = '') then
      -- nop
      -- This happens, if a new empty file is loaded with 'xcom e'. Than no
      -- 'edit' cmd is called.
      call NepmdPmPrintf( "AFTERLOAD: current file is .Unnamed, filestoloadmax = ''")
   else
      -- Activate first loaded file from the current edit cmd.
      -- This works only here properly and only when action is posted.
      -- Disabled activatefile in edit.
      if firstloadedfid <> '' then
         call NepmdPmPrintf( 'AFTERLOAD: activating firstloadedfileid = 'firstloadedfid.filename)
         activatefile firstloadedfid
         --'HookAdd afterloadonce postme activatefile' firstloadedfid
      endif
   endif

; --- Process hook ----------------------------------------------------------
   if isadefc('HookExecute') then
      'HookExecute afterload'          -- no need for 'postme' here?
      'HookExecuteOnce afterloadonce'  -- no need for 'postme' here?
       call NepmdPmPrintf( 'AFTERLOAD: HookExecute afterload, afterloadonce')
   endif

; --- Change EPM pointer from standard arrow to text pointer ----------------
;     bug fix (hopefully): even standard EPM doesn't show everytime the
;                          correct pointer after a new edit window was opened
;     defined in defc initconfig, STDCTRL.E
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif

; --- Reset universal vars, set by edit and NepmdLoadFile -------------------
   filestoloadmax = ''
   firstloadedfid = ''
   return

; Todo: move
defc activatefile
   if arg(1) <> '' then
      fid = arg(1)
      activatefile fid  -- fid must be a var or a fid
   endif

