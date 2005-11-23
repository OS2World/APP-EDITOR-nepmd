/****************************** Module Header *******************************
*
* Module Name: select.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: select.e,v 1.12 2005-11-23 23:49:51 aschn Exp $
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
const
compile if not defined(LOCAL_MOUSE_SUPPORT)
   LOCAL_MOUSE_SUPPORT = 0
compile endif
   TransparentMouseHandler = "TransparentMouseHandler"
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_SELECT)
   NEPMD_DEBUG_SELECT = 0
compile endif

;  SELECT.E                                                 Bryan Lewis 1/2/89
;
;  This replaces the clumsy old select_edit_keys() procedure, which had to
;  be explicitly called after any action that might change the current file.
;  This DEFSELECT event is automatically triggered whenever the current file
;  after an action is different from the one before the action.  It never
;  needs to be (and can't be) explicitly called.
;
;  This is triggered after all command processing is done, if the then-current
;  file is different from the one before the command.  If a command switches
;  to a temporary file but switches back to the original file before ending,
;  this event will not be triggered.
;
;  Because of other improvements -- keyset, tabs and margins are bound to
;  the file now, and are selected at load time in a DEFLOAD event -- there's
;  not much work to be done here.
;
defproc select_edit_keys()
   /* Dummy proc for compatibility.  Select_edit_keys() isn't used any more.*/

; ---------------------------------------------------------------------------
defselect
   universal lastselectedfid
   universal loadstate
   universal vEPM_POINTER
   getfileid fid
   dprintf('SELECT', 'DEFSELECT for '.filename', loadstate = 'loadstate)

   JustLoaded = 0
   if loadstate = 1 then  -- if a defload was processed before
      loadstate = 2
      JustLoaded = 1
      'AfterLoad'  -- executes multiple ring commands that sometimes leave the wrong file on top
      'postme activatefile' fid  -- postme required, but doesn't work in some rare cases
      loadstate = 0
   endif

   if fid = lastselectedfid then
      -- nop, ProcessSelect was already executed for this file
   else
      'ProcessSelect'
      lastselectedfid = fid
   endif

;  Change EPM pointer from standard arrow to text pointer -------------------
;     bug fix (hopefully): even standard EPM doesn't show everytime the
;                          correct pointer after a new edit window was opened
;     defined in defc initconfig, STDCTRL.E
   if JustLoaded then
compile if EPM_POINTER = 'SWITCH'
      'postme setmousepointer 'vEPM_POINTER
compile else
      'postme setmousepointer 'EPM_POINTER
compile endif
   endif

; ---------------------------------------------------------------------------
; This cmd is called once after all files were loaded by defselect.
defc AfterLoad
   universal CurEditCmd
   universal filestoloadmax   -- set in NepmdLoadFile, only used for RingAddToHistory('LOAD')

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
   if wordpos( CurEditCmd, 'SETPOS LOADGROUP RESTORERING') = 0 then
      -- see FILELIST.E
      -- must not execute 'postme activatefile' at this point
      call RingAutoWriteFilePosition()
   endif

;  Process hooks ------------------------------------------------------------
   'HookExecute afterload'          -- no need for 'postme' here?
   'HookExecuteOnce afterloadonce'  -- no need for 'postme' here?
   dprintf( 'AFTERLOAD', 'HookExecute afterload, afterloadonce')

; ---------------------------------------------------------------------------
; Executed by defselect
defc ProcessSelect
   universal nepmd_hini
compile if LOCAL_MOUSE_SUPPORT
   universal LMousePrefix
   universal EPM_utility_array_ID
compile endif
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif

   dprintf( 'SELECT', 'PROCESSSELECT for '.filename)

   -- moved the SetMenuAttribute stuff for command shell windows to STDCTRL.E, defc menuinit_0

compile if LOCAL_MOUSE_SUPPORT
   -- LOCAL_MOUSE_SUPPORT = 1 enables separate mouse definitions for every file in the ring.
   -- Additional changes per register_mousehandler will then be local (for every file) only.
   -- Because of this feature is not built-in as field var (starting with a '.' and belonging
   -- to each file separately), it must be achieved by the use of an array var and must be
   -- switched on every defselect.
   getfileid fid
   OldRC = Rc
   rc = get_array_value(EPM_utility_array_ID, 'LocalMausSet.'fid, NewMSName)
   if RC then
      if rc=-330 then
         -- no mouseset bound to file yet, assume blank.
         LMousePrefix = TransparentMouseHandler'.'
      else
         call messagenwait('RC='RC)
      endif
      RC = OldRC
   else
      LMousePrefix = NewMSName'.'
   endif
compile endif  -- LOCAL_MOUSE_SUPPORT

compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
   if bkm_avail <> '' then
 compile endif
      call bkm_defselect()
 compile if WANT_EBOOKIE = 'DYNALINK'
   endif
 compile endif
compile endif  -- WANT_EBOOKIE

;  Change to dir of current file --------------------------------------------
   KeyPath = '\NEPMD\User\ChangeWorkDir'
   ChangeWorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if ChangeWorkDir = 2 then
      Filename = .filename
      if substr( Filename, 2, 2) = ':\' then
         call directory( '\')
         call directory( Filename'\..')
      endif
   endif

;  Process hooks ------------------------------------------------------------
   -- Use the 'select' hook for settings, you want to change on every
   -- defselect event. That should be only stuff, that don't stick with the
   -- file. If your stuff sticks, better use the 'load' hook to avoid loss
   -- of performance and stability.
   'HookExecute select'          -- usually contains ProcessSelectSettings,
                                 -- to be used for user additions as well
   'HookExecuteOnce selectonce'  -- user additions, deleted after execution
   'HookExecute afterselect'     -- usually contains ProcessRefreshInfoLine


