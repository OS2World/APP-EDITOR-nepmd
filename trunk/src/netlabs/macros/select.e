/****************************** Module Header *******************************
*
* Module Name: select.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: select.e,v 1.24 2008-09-05 23:09:25 aschn Exp $
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
; Suppress select processing. Used for temporary .filename changes and to
; avoid a load and select triggering, that otherwise would be executed on
; canceling the action. Even executing .filename = newname triggers a load
; and a followed select event.
;    'DisableSelect'        Disable select processing for all files (e.g.
;                           before a Name or SaveAs command).
;    'EnableSelect'         Enable select processsing for all files (e.g.
;                           after a Name or SaveAs command was successful.
;                           The load and select events are internally posted,
;                           so that the EnableSelect command will reset the
;                           flag before it's been executed.
;    'postme EnableSelect'  Enable select processsing for all files after
;                           current command (e.g. Name or SaveAs) was
;                           completely executed. That triggers defload and
;                           after that, defselect before the disable flag
;                           was reset. As a result, defselect will work
;                           normally from the next processed file on.

defc DisableSelect
   universal SelectDisabled
   SelectDisabled = 1

defc EnableSelect
   universal SelectDisabled
   SelectDisabled = 0

; ---------------------------------------------------------------------------
defselect
   universal SelectDisabled
   universal loadstate
   getfileid fid
   dprintf( 'SELECT', 'DEFSELECT for '.filename', fid = 'fid', loadstate = 'loadstate)
   if not .visible then  -- process following only if file is visible
      return
   endif
   if SelectDisabled <> 1 then
      'ProcessSelect'
   endif

; ---------------------------------------------------------------------------
defc ProcessSelect
   universal lastselectedfid
   universal loadstate
   universal SelectDisabled

   getfileid fid

compile if 1
   -- Suppress too early select events
   if loadstate = '' then
      dprintf( 'SELECT', 'suppress ProcessSelect for '.filename', fid = 'fid', loadstate = 'loadstate' (initial file)')
      return
   endif
compile endif

   SelectDisabled = 0  -- always reenable it
   dprintf( 'SELECT', 'ProcessSelect for '.filename', fid = 'fid', loadstate = 'loadstate)


   if fid = lastselectedfid then
      -- nop, ProcessSelect2 was already executed for this file
      dprintf( 'SELECT', 'suppress ProcessSelect for '.filename', fid = 'fid', loadstate = 'loadstate' (already processed)')
   else
      if loadstate = 1 then  -- if a defload was processed before
         loadstate = 2
         'ProcessAfterLoad'  -- executes multiple ring commands that sometimes
                             -- left the wrong file on top
; ### critical call ###
         'postme activatefile' fid  -- postme required, but doesn't work in some rare cases
; #####################

         'postme ProcessAfterload2' -- final processing, therefore posted
         loadstate = 0
      endif

      'ProcessSelect2'
      lastselectedfid = fid
   endif

; ---------------------------------------------------------------------------
; This cmd is called once by defselect after all files were loaded.
defc ProcessAfterLoad
   universal CurEditCmd
   universal filestoloadmax   -- set in PreLoadFile, only used for RingAddToHistory('LOAD')

   dprintf( 'AFTERLOAD', .filename', CurEditCmd = 'CurEditCmd)

   -- Write number for all files in the ring to an array var
   -- see FILELIST.E
   -- must not execute 'postme activatefile' at this point
   call RingSetFileNumber()

   -- Write name of all files in the ring to NEPMD.INI
   -- Do this only for single files, not for wildcards in filespec
   -- For RestoreRing, filestoloadmax is set to 1 and every file is loaded
   -- with an extra Edit command in a loop.
   if filestoloadmax <= 1 then
; ### critical call ###
      call RingAddToHistory('LOAD')
; #####################
   endif

   -- Write position and name of all files in the ring to NEPMD.INI
   -- Don't process if files loaded by Recompile or 'groups loadgroup'
   if wordpos( CurEditCmd, 'SETPOS LOADGROUP RESTORERING') = 0 then
      -- see FILELIST.E
      -- must not execute 'postme activatefile' at this point
; ### critical call ###
      call RingAutoSavePos()
; #####################
   endif

   -- Reset CurEditCmd to enable saving the ring list for the next 'edit'
   -- or 'quit' action
   CurEditCmd = ''

; ---------------------------------------------------------------------------
; This cmd is posted once by defselect after all files were loaded.
defc ProcessAfterLoad2
   universal vepm_pointer
   universal DisplayDisabled

   dprintf( 'AFTERLOAD', 'ProcessAfterload2 for '.filename)

   mouse_setpointer vepm_pointer

   if DisplayDisabled then
      DisplayDisabled = 0
      'trim'  -- Trim window so it's an exact multiple of the font size
              -- This should avoid scrolling caused by temp. cursor pos.
              -- changes and restore.
      display 1  -- re-enable screen updates, show the loaded files
   endif
   -- Bug to find? display 2 here would cause on defmodify the msg:
   -- Invalid third parameter, most likely coming from a do_array
   -- statement or Get/SetAVar call.

   dprintf( 'AFTERLOAD', 'HookExecute afterload: 'HookGet( 'afterload'))
   'HookExecute afterload'
   dprintf( 'AFTERLOAD', 'HookExecuteOnce afterloadonce: 'HookGet( 'afterloadonce'))
   'HookExecuteOnce afterloadonce'
   if HookIsDefined( 'afterload2once') then
      refresh
      'postme HookExecuteOnce afterload2once'
      dprintf( 'AFTERLOAD', 'HookExecuteOnce afterload2once: 'HookGet( 'afterload2once'))
   endif

; ---------------------------------------------------------------------------
; Executed by defselect
defc ProcessSelect2
   universal nepmd_hini
compile if LOCAL_MOUSE_SUPPORT
   universal LMousePrefix
   universal EPM_utility_array_ID
compile endif
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif

   dprintf( 'SELECT', 'ProcessSelect2 for '.filename)

   -- moved the SetMenuAttribute stuff for command shell windows to STDCTRL.E, defc menuinit_0

compile if LOCAL_MOUSE_SUPPORT
   -- LOCAL_MOUSE_SUPPORT = 1 enables separate mouse definitions for every file in the ring.
   -- Additional changes per register_mousehandler will then be local (for every file) only.
   -- Because of this feature is not built-in as field var (starting with a '.' and belonging
   -- to each file separately), it must be achieved by the use of an array var and must be
   -- switched on every defselect.
   getfileid fid
   OldRC = rc
   rc = get_array_value( EPM_utility_array_ID, 'LocalMausSet.'fid, NewMSName)
   if rc then
      if rc = -330 then
         -- no mouseset bound to file yet, assume blank.
         LMousePrefix = TransparentMouseHandler'.'
      else
         sayerror 'ProcessSelect2: LocalMouseSet array var not returned, rc = 'rc
      endif
      rc = OldRC
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


