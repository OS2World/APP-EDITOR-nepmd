/****************************** Module Header *******************************
*
* Module Name: enter.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: enter.e,v 1.6 2004-11-30 21:05:47 aschn Exp $
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

; Consts concerning with enter:
; ENHANCED_ENTER_KEYS = 1
; ASSIST_TRIGGER = 'ENTER'
; WANT_STREAM_INDENTED = 1
; WANT_STREAM_MODE = 'SWITCH'
; ENTER_ACTION = 'STREAM'
; NEPMD_STREAM_INDENTED = 1

const
compile if not defined(NEPMD_STREAM_INDENTED)
   -- This activates the defs for WANT_STREAM_INDENTED too
   NEPMD_STREAM_INDENTED = 1
compile endif

compile if NEPMD_STREAM_INDENTED
; ---------------------------------------------------------------------
;    This procedure corrrects a bug in standard EPM stream mode
; if stream mode is activated and if WANT_STREAM_INDENTED = 1:
; Placing the cursor before the first word in a line has gobbled
; the space from the cursor to the first word after processing
; the Enter.
;    Additionally the chars from the line above are copied instead of
; filling the space in the new line with spaces, so it works with
; Tabs too.
; ---------------------------------------------------------------------
defproc nepmd_stream_indented_split_line
   old_col = .col
   call pfirst_nonblank()
   old_nonblank = .col
   .col = old_col
   if old_col <= old_nonblank then
      -- If cursor is in the area before the first word (tabs and spaces)
      if .line then
         split
      else
         insert
         up
      endif
 compile if 0  -- Respect standard margin/par indent:
      getline old_line  -- left part of the old line from left margin to the cursor
      parse value pmargins() with leftcol . paracol .
      if old_line = '' or not .line then
         .col = paracol
      else
         --call pfirst_nonblank()
         if .col = paracol then
            .col = leftcol
         endif
      endif
 compile else  -- Don't respect standard margin/par indent:
      .col = 1
 compile endif
      down
   else
      -- Original definition:
      call splitlines()
      call pfirst_nonblank()
      down
   endif
compile endif  -- NEPMD_STREAM_INDENTED

; ---------------------------------------------------------------------
; Following has moved from STDPROCS.E
defproc einsert_line
   insert
   up
   getline line
   parse value pmargins() with leftcol . paracol .
   if line = '' or not .line then
      .col=paracol
   else
      call pfirst_nonblank()
      if .col = paracol then
         .col = leftcol
      endif
   endif
   down

; ---------------------------------------------------------------------
defproc enter_common(action)
   universal CUA_marking_switch
   universal stream_mode

   -- Definition for stream mode
   if stream_mode then
      if .line then
         if CUA_marking_switch then
            if not process_mark_like_cua() and   -- There was no mark
               not insert_state() then           -- & we're in replace mode
               delete_char    -- Delete the character, to emulate replacing the
            endif             -- marked character with a newline.
         endif
  compile if WANT_STREAM_INDENTED or NEPMD_STREAM_INDENTED
   compile if NEPMD_STREAM_INDENTED
         call nepmd_stream_indented_split_line()
   compile else
         call splitlines()
         call pfirst_nonblank()
         down
   compile endif  -- NEPMD_STREAM_INDENT
  compile else
         split
         .col = 1
         down
  compile endif -- WANT_STREAM_INDENTED
      else
         insert
         .col = 1
      endif
      return
   endif

   -- Definition for line mode
   is_lastline = (.line = .last)
   if is_lastline  & (action = 3 | action = 5) then  -- 'ADDATEND' | 'DEPENDS+'
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
      return
   endif
;     'NEXTLINE' 'ADDATEND'                        'DEPENDS'  'DEPENDS+'
   if action = 2 | action = 3 | (not insert_state() & (action = 4 | action = 5)) then
      down                          -- go to next line
      begin_line
      return
   endif
   if action = 6 then
      call splitlines()
      call pfirst_nonblank()
      down
;;    refresh
      return
   endif
   if action = 7 | action = 8 then
      insert
      parse value pmargins() with leftcol . paracol .
      if textline(.line - 1) = '' or .line = 1 or action = 8 then
         .col = paracol
      else
         .col = leftcol
      endif
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   if action = 9 then
      insert
      begin_line
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   call einsert_line()           -- insert a line
   if is_lastline then down; endif  -- This keeps the === Bottom === line visible.

-----------------------------------------------------------------------
defc enter =
   universal enterkey
   call enter_common(enterkey)
defc a_enter =
   universal a_enterkey
   call enter_common(a_enterkey)
defc c_enter =
   universal c_enterkey
   call enter_common(c_enterkey)
defc s_enter =
   universal s_enterkey
   call enter_common(s_enterkey)
defc padenter =
   universal padenterkey
   call enter_common(padenterkey)
defc a_padenter =
   universal a_padenterkey
   call enter_common(a_padenterkey)
defc c_padenter =
   universal c_padenterkey
   call enter_common(c_padenterkey)
defc s_padenter =
   universal s_padenterkey
   call enter_common(s_padenterkey)


