/****************************** Module Header *******************************
*
* Module Name: afterload.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: afterload.e,v 1.10 2004-09-12 15:10:25 aschn Exp $
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

; ---------------------------------------------------------------------------
; This cmd is called once after all files were loaded by defselect.
defc AfterLoad
   universal CurEditCmd
   universal filestoloadmax   -- set in NepmdLoadFile, only used for RingAddToHistory('LOAD')
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif

   dprintf( 'AFTERLOAD', .filename', CurEditCmd = 'CurEditCmd)

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

;  Process hooks ------------------------------------------------------------
   'HookExecute afterload'          -- no need for 'postme' here?
   'HookExecuteOnce afterloadonce'  -- no need for 'postme' here?
   dprintf( 'AFTERLOAD', 'HookExecute afterload, afterloadonce')

;  Change EPM pointer from standard arrow to text pointer -------------------
;     bug fix (hopefully): even standard EPM doesn't show everytime the
;                          correct pointer after a new edit window was opened
;     defined in defc initconfig, STDCTRL.E
compile if EPM_POINTER = 'SWITCH'
   'postme setmousepointer 'vEPM_POINTER
compile else
   'postme setmousepointer 'EPM_POINTER
compile endif

   return

