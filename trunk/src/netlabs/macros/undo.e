/****************************** Module Header *******************************
*
* Module Name: undo.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: undo.e,v 1.6 2005-11-16 16:29:03 aschn Exp $
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
; Moved from STDCTRL.E
defc ProcessUndo
   --undoaction 1, PresentState;
   --undoaction 2, OldestState;
   CurrentUndoState = arg(1)
   --
   --if CurrentUndoState<OldestState then
   --  return
   --endif
   --sayerror 'Undoing State ' CurrentUndoState ' old='OldestState ' new='PresentState
   undoaction 7, CurrentUndoState;
   --refresh;

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc RestoreUndo
   call EnableUndoRec()

; ---------------------------------------------------------------------------
; Restore standard undo recording. Some commands have to disable that
; in order to not clutter the record list, e.g. when a command is used
; repeatedly.
; Values for action:
;    0: at every keystroke (not default)
;    1: at every command (default)
;    2: when moving the cursor from a modified line (default, but not
;       changed by any command, so far)
; This is used by following key defcs and events, e.g.:
; Space, Return, defselect, ProcessOtherKeys
defproc EnableUndoRec
   --action = 0  -- action, the 2nd param of undoaction, must be a var
   --undoaction 4, action  -- 4: disable undo recording at action
   action = 1  -- action, the 2nd param of undoaction, must be a var
   undoaction 5, action  -- 5: enable undo recording at action
   action = 2  -- action, the 2nd param of undoaction, must be a var
   undoaction 5, action  -- 5: enable undo recording at action
   return

; ---------------------------------------------------------------------------
; Disable undo recording. This is used by several key defcs, e.g.:
; Space, Tab, TypeTab, ShiftLeft, ShiftRight, DeleteChar, BackSpace
defproc DisableUndoRec
   --action = 0  -- action, the 2nd param of undoaction, must be a var
   --undoaction 4, action  -- 4: disable undo recording at action
   action = 1  -- action, the 2nd param of undoaction, must be a var
   undoaction 4, action  -- 4: disable undo recording at action
   action = 2  -- action, the 2nd param of undoaction, must be a var
   undoaction 4, action  -- 4: disable undo recording at action
   return

; ---------------------------------------------------------------------------
; Create a new undo record and restore standard undo behaviour
defproc NewUndoRec
   if .modify then
      undoaction 1, junk  -- 1: Create a new state
      call EnableUndoRec()
   endif
   return

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc RenderUndoInfo
    undoaction 1, PresentState        -- Do to fix range, not for value.
;   undoaction 2, OldestState;
;   statestr=PresentState OldestState \0
    undoaction 6, StateRange               -- query range
    parse value staterange with oldeststate neweststate
    statestr = newestState oldeststate\0
    action = 1
    undoaction 4, action
    -- sayerror '<'statestr'>'
    call windowmessage( 1, arg(1),   -- send message back to dialog
                        32,               -- WM_COMMAND - 0x0020
                        9999,
                        ltoa( offset( statestr) || selector( statestr), 10))

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc UndoDlg
;   undoaction 1, PresentState        -- Do to fix range, not for value.
;   undoaction 6, StateRange               -- query range
;   parse value staterange with oldeststate neweststate
;   if oldeststate = neweststate  then
;      sayerror 'No other undo states recorded.'
;   else
       call windowmessage( 0,  getpminfo(APP_HANDLE),
                           5131,               -- EPM_POPUNDODLG
                           0,
                           0)
;   endif

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc Undo
   undo

; ---------------------------------------------------------------------------
; From EPMSMP\UNDOREDO.E
; Changed:
;    o  beep disabled

/* The following code defines a couple of keys that let you step backwards
and forwards through the undo states.  For the sake of example, I've
defined the Undo key as Ctrl+U and the Redo key as Ctrl+R.  You might
prefer to select other keys that don't conflict with standard EPM key
definitions.  One important note - the way that the keys determine if
you're still in an undo/redo sequence is checking if the previous key
pressed was also Ctrl+U or Ctrl+R.  Because of the way keys are handled,
you must press and hold the Ctrl key for as long as you're stepping back
and forth (by pressing U and R) - once you release the Ctrl key, the next
time you press Ctrl+U or Ctrl+R, they will see the previously-pressed key
as being the Ctrl key, not Ctrl+U or Ctrl+R.  The same is true if you
define the keys to be a Shift or Alt combination (which implies that they
both have to have the same shift state - both start with s_, both with c_,
both with a_, or both unshifted).

Note also that this assumes the user has not enabled undo-state recording
on *every* keystroke.  If you did, then you might have to add code here
to stop recording changes on keystrokes, and it's not clear how you'd
figure out when to turn it back on.
                                         by:  Larry Margolis  */

defc Undo1 =
   universal current_undo_state
   universal undo1_key
   universal redo1_key
   undo1_key = lastkey()  -- save current key
   lk = lastkey(1)
   if lk = undo1_key | lk = redo1_key then  -- last key was undo or redo
      parse value current_undo_state with presentstate oldeststate neweststate
      if presentstate > oldeststate then
         presentstate = presentstate - 1
         undoaction 7, presentstate
         current_undo_state = presentstate oldeststate neweststate
      else
         --call beep(800, 500)
      endif
      display -8
      sayerror 'Now at state' presentstate 'of' neweststate
      display 8
      return
   endif
   -- Need to get new state information
   undoaction 1, starting_state  -- Do to fix range and for value.
   undoaction 6, StateRange               -- query range
   parse value staterange with oldeststate neweststate
   presentstate = neweststate - 1
   undoaction 7, presentstate
   current_undo_state = presentstate oldeststate neweststate
   display -8
   sayerror 'Initialized:  at state' presentstate 'of' neweststate
   display 8
   return

defc Redo1 =
   universal current_undo_state
   universal undo1_key
   universal redo1_key
   redo1_key = lastkey()  -- save current key
   lk = lastkey(1)
   if lk = undo1_key | lk = redo1_key then  -- last key was undo or redo
      parse value current_undo_state with presentstate oldeststate neweststate
      if presentstate < neweststate then
         presentstate = presentstate + 1
         undoaction 7, presentstate
         current_undo_state = presentstate oldeststate neweststate
         display -8
         sayerror 'Now at state' presentstate 'of' neweststate
         display 8
         return
      endif
      display -8
      sayerror 'Already at state' presentstate 'of' neweststate
      display 8
   endif
   --call beep(800, 500)
   return

