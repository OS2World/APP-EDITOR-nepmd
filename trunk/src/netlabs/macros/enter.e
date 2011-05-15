/****************************** Module Header *******************************
*
* Module Name: enter.e
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

; ---------------------------------------------------------------------
; This procedure corrrects a bug in standard EPM stream mode if stream
; mode is activated and if WANT_STREAM_INDENTED = 1: Placing the cursor
; before the first word in a line has gobbled the space from the cursor
; to the first word after processing the Enter.
; Additionally, the chars from the line above are copied instead of
; filling the space in the new line with spaces, so it works with Tabs
; too.
defproc SplitIndentLine
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

; ---------------------------------------------------------------------------
defc Enter
   universal cua_marking_switch
   universal curkey
   universal prevkey

   action = strip( arg(1))

   if prevkey = curkey then
      call DisableUndoRec()
   endif

   -- .DOS dir files: Make dir mask after "Directory of" editable and create
   -- a new dir listing on Enter
   fn = upcase( .filename)
   if word( fn, 1) = '.DOS' & word( fn, 2) = 'DIR' then
      rcx = DirProcessDirOfLine()
      if rcx = 0 then
         return
      endif
   endif

   is_lastline = (.line = .last)

   -- Definition for stream mode or type 6 in line mode
   if action = '' | action = 6 then
                    -- 'STREAM'
      if .line then
         if cua_marking_switch then
            if not process_mark_like_cua() and   -- There was no mark
               not insert_state() then           -- & we're in replace mode
               delete_char    -- Delete the character, to emulate replacing the
            endif             -- marked character with a newline.
         endif
;compile if WANT_STREAM_INDENTED
         call SplitIndentLine()
;compile else
;         split
;         .col = 1
;         down
;compile endif -- WANT_STREAM_INDENTED
      else
         insert
         .col = 1
      endif

   -- Definition for line mode
   -- 1 = 'ADDLINE'   Add a new line after cursor, preserving indentation
   -- 2 = 'NEXTLINE'  Move to beginning of next line
   -- 3 = 'ADDATEND'  Like (2), but add a line if at end of file
   -- 4 = 'DEPENDS'   Add a line if in insert mode, else move to next
   -- 5 = 'DEPENDS+'  Like (4), but always add a line if on last line.
   -- 6 = 'STREAM'    Split line at cursor
   -- 7               Add a new line, move to left or paragraph margin
   -- 8               Add a new line, move to paragraph margin
   -- 9               Add a new line, move to column 1
   elseif is_lastline  & (action = 3 | action = 5) then
      --                  'ADDATEND' | 'DEPENDS+'
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
   elseif action = 2 | action = 3 | (not insert_state() & (action = 4 | action = 5)) then
      --  'NEXTLINE' | 'ADDATEND'                          'DEPENDS'  | 'DEPENDS+'
      down                          -- go to next line
      begin_line
/*
   -- Better use stream mode def from above here
   elseif action = 6 then
      --  'STREAM'
      call splitlines()
      call pfirst_nonblank()
      down
*/
   elseif action = 7 | action = 8 then
      insert
      parse value pmargins() with leftcol . paracol .
      if textline(.line - 1) = '' or .line = 1 or action = 8 then
         .col = paracol
      else
         .col = leftcol
      endif
      if is_lastline then  -- This keeps the === Bottom === line visible.
         down
      endif
   elseif action = 9 then
      insert
      begin_line
      if is_lastline then  -- This keeps the === Bottom === line visible.
         down
      endif
   else
      call einsert_line()           -- insert a line
      if is_lastline then  -- This keeps the === Bottom === line visible.
         down
      endif
   endif

   if prevkey <> curkey then
      call NewUndoRec()
   endif

