/****************************** Module Header *******************************
*
* Module Name: undo.e
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

; ---------------------------------------------------------------------------
; Disable undo recording for all events.
; Undo states were created only during execution of a command that calls
; NextCmdAltersText(), defined in keys.e.
definit
   call UndoRec( '')

; ---------------------------------------------------------------------------
defproc UndoRec
   Events = upcase( arg(1))

   Event = 0  -- upon starting each keystroke
   if pos( 'K', Events) > 0 then
      undoaction 5, Event  -- 5 = enable
   else
      undoaction 4, Event  -- 4 = disable
   endif

   Event = 1  -- upon starting each command
   if pos( 'C', Events) > 0 then
      undoaction 5, Event  -- 5 = enable
   else
      undoaction 4, Event  -- 4 = disable
   endif

   Event = 2  -- when moving the cursor from a modified line
   if pos( 'L', Events) > 0 then
      undoaction 5, Event  -- 5 = enable
   else
      undoaction 4, Event  -- 4 = disable
   endif

   return

; ---------------------------------------------------------------------------
; Command for setting undo behavior from REXX and C
defc UndoRec
   call UndoRec( strip( arg(1)))

; ---------------------------------------------------------------------------
; Create a new undo record, if the current state is not already checkpointed.
defproc NewUndoRec
   undoaction 1, junk       -- 1 = create a new state
   return

; ---------------------------------------------------------------------------
; Command for creating undo states from REXX and C
defc NewUndoRec
   call NewUndoRec()

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
defc UndoDlg
    call windowmessage( 0,  getpminfo(APP_HANDLE),
                        5131,      -- EPM_POPUNDODLG
                        0,
                        0)

; ---------------------------------------------------------------------------
; Called by undo dialog.
defc ProcessUndo
   CurrentUndoState = arg(1)
   undoaction 7, CurrentUndoState

; ---------------------------------------------------------------------------
; Called by undo dialog.
defc RenderUndoInfo
    undoaction 1, PresentState        -- do to fix range, not for value
    undoaction 6, StateRange          -- query range
    parse value StateRange with OldestState NewestState
    StateStr = NewestState OldestState\0
    --Event = 1
    --undoaction 4, Event  -- 4 = disable
    call windowmessage( 1, arg(1),    -- send message back to dialog
                        32,           -- WM_COMMAND - 0x0020
                        9999,
                        ltoa( offset( StateStr) || selector( StateStr), 10))

; ---------------------------------------------------------------------------
; Called by undo dialog.
defc RestoreUndo
   --Event = 1
   --undoaction 5, Event  -- 5 = enable

; ---------------------------------------------------------------------------
; Undo current line.
defc Undo
   undo

; ---------------------------------------------------------------------------
; The following code defines key commands that let you step backwards
; and forwards through the undo states.
;
; With the switch to accel keys, a new undo state is only created for
; commands different from Undo1 or Redo1.

; ---------------------------------------------------------------------------
defc Undo1
   universal current_undo_state
   universal curkey
   universal prevkey
   parse value( prevkey) with Key''\1''Cmd
   UndoKeys = strip( GetAVar( 'keycmd.undo1')) strip( GetAVar( 'keycmd.redo1'))
   --dprintf( 'Key = 'Key', UndoKeys = 'UndoKeys)
   if wordpos( Key, UndoKeys) > 0 then  -- last key was undo or redo
      parse value current_undo_state with PresentState OldestState NewestState
      if PresentState > OldestState then
         PresentState = PresentState - 1
         undoaction 7, PresentState
         current_undo_State = PresentState OldestState NewestState
         'SayHint Now at state' PresentState 'of' NewestState
      elseif NewestState = 1 then
         PresentState = NewestState
         current_undo_state = PresentState OldestState NewestState
         'SayHint No earlier undo states available'
      else
         --call beep(800, 500)
         'SayHint Already at state' PresentState 'of' NewestState
      endif
   else
      -- Need to get new state information
      undoaction 1, starting_state  -- Do to fix range and for value.
      undoaction 6, StateRange               -- query range
      parse value StateRange with OldestState NewestState
      if NewestState = 1 then
         PresentState = NewestState
         current_undo_state = PresentState OldestState NewestState
         'SayHint No earlier undo states available'
      else
         PresentState = NewestState - 1
         undoaction 7, PresentState
         current_undo_state = PresentState OldestState NewestState
         'SayHint Initialized at state' PresentState 'of' NewestState
      endif
   endif

; ---------------------------------------------------------------------------
defc Redo1
   universal current_undo_state
   universal curkey
   universal prevkey
   parse value( prevkey) with Key''\1''Cmd
   UndoKeys = strip( GetAVar( 'keycmd.undo1')) strip( GetAVar( 'keycmd.redo1'))
   --dprintf( 'Key = 'Key', UndoKeys = 'UndoKeys)
   if wordpos( Key, UndoKeys) > 0 then  -- last key was undo or redo
      parse value current_undo_state with PresentState OldestState NewestState
      if PresentState < NewestState then
         PresentState = PresentState + 1
         undoaction 7, PresentState
         current_undo_state = PresentState OldestState NewestState
         'SayHint Now at state' PresentState 'of' NewestState
      else
         'SayHint Already at state' PresentState 'of' NewestState
      endif
   else
      --call beep(800, 500)
      -- Need to get new state information
      undoaction 1, starting_state  -- Do to fix range and for value.
      undoaction 6, StateRange               -- query range
      parse value StateRange with OldestState NewestState
      presentState = NewestState
      current_undo_state = PresentState OldestState NewestState
      'SayHint Initialized at state' PresentState 'of' NewestState
   endif

