/****************************** Module Header *******************************
*
* Module Name: balance.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: balance.e,v 1.3 2006-12-10 11:18:32 aschn Exp $
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

; ToDo:
;    Better use a modified passist function instead of these def's

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Character Balancing Routine (for EOS2 and EPM)             ;;
;;   by Jonathan Kaye                                           ;;
;;                                                              ;;
;;   Upon entering a closing matching character, the balance    ;;
;;   routine shows the caller the matching opening character.   ;;
;;   If it is on the screen, it highlights the character in     ;;
;;   the color of the current commandline.  If it's not on      ;;
;;   the screen at the time, it reports in the message area     ;;
;;   the line of the opening character, giving line number      ;;
;;   and text that follows the character.                       ;;
;;                                                              ;;
;;   In EOS2, it keeps the opening character highlighted until  ;;
;;   the next key is pressed.  In EPM, it only flashes the      ;;
;;   opening character a few times.                             ;;
;;                                                              ;;
;;   Basically, it does what EMACS does.  But I don't think     ;;
;;   we can mention that word around here.                      ;;
;;                                                              ;;
;;   To use: Include BALANCE.E (include 'balance.e') in one     ;;
;;           of the MY*.E files, such as MYSTUFF.E.  Since      ;;
;;           I wanted the keys to be part of the base keyset,   ;;
;;           I moved the key definitions (the def ')', etc.) to ;;
;;           MYKEYS.E, leaving the procedure included in        ;;
;;           MYSTUFF.E.                                         ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compile if not defined(SMALL)  -- Being compiled separately
include 'stdconst.e'
include 'colors.e'
const
tryinclude 'mycnf.e'
compile endif -- not defined(SMALL)  -- Being compiled separately

-- Settings for balance
const
compile if not defined(WANT_BALANCE_SHOW_SAYAT)
  WANT_BALANCE_SHOW_SAYAT = 0
  -- Highlighting method of the matching character: 1 => sayat, 0 => circleit
compile endif
compile if not defined(WANT_BALANCE_SHOW_AT_BOTTOM)
  WANT_BALANCE_SHOW_AT_BOTTOM = 0
  -- Message instead of highlighting: 1 => no highlighting, only message
compile endif
compile if not defined(WANT_BALANCE_BEEP)
  WANT_BALANCE_BEEP = 0
  -- 0 ==> no beep
compile endif


;; Define matching keys ----------------------
-- Doesn't work for environments or $...$
-- def '\begin'=
--   call balance("\begin{...}",         "\begin", "\end", 660)
;; -------------------------------------------

; ---------------------------------------------------------------------------
; Defined as defc to use it for keys.
; arg(1) = char to typein. Dropped beep.
defc balance
   parse arg char
   if char = ')' then
      type = 'parenthesis'
      matchchar = '('
   elseif char = ']' then
      type = 'square bracket'
      matchchar = '['
   elseif char = '}' then
      type = 'curly bracket'
      matchchar = '{'
   elseif char = '>' then
      type = 'angle bracket'
      matchchar = '<'
   else
      sayerror 'balance: unknown char' char
   endif
   call balance( type, matchchar, char)

; ---------------------------------------------------------------------------
defproc balance( type, open_char, close_char)

   fail_beep_Hz = arg(4)      -- Made this optional
   if fail_beep_Hz = '' then
      fail_beep_Hz = 550
   endif
   keyin close_char
   refresh                    -- Get closing character on screen to start

   getsearch user_pattern     -- Hold user's pattern to restore when done

   display 0
   display -3                 -- Don't show user cursor is jumping around
                              -- Also turn off non-critical error messages
   call psave_pos(screenpos)  -- Freeze our relative position on screen

   -- Set search keys we use to find opening and closing characters
   loc_opts = 'R-'
   open_pat = 'XCOM L /'open_char'/'loc_opts
   clos_pat = 'XCOM L /'close_char'/'loc_opts

   -- Initialize for start of search right before closing character
   close_col  = .col - 1
   close_line = .line
   call bal_minus_one(close_col, close_line)
   open_col   = .col    -- We can start here because we know there isn't
   open_line  = .line   -- an opening character past what user just typed
   found = 0

   loop
      call bal_minus_one(open_col, open_line) -- so we don't find last open again
      call bal_last_char(open_pat,  open_line,  open_col,  open_col,  open_line)
      call bal_last_char(clos_pat, close_line, close_col, close_col, close_line)

      if (open_line = -1) then leave      -- No opening character
      else
         if (bal_more_recent(open_col, open_line, close_col, close_line)) then
             -- Found our opening character
             found = 1
             leave
         else
            -- keep searching; the opening & closing we found (if we found any)
            --            cancel each other (note that the opening & closing
            --            chars don't necessarily match each other, but we
            --            don't care for our purposes)
            call bal_minus_one(close_col, close_line)
         endif
      endif
   endloop

   prestore_pos(screenpos)      -- Restore relative screen position
   -- Turn back on non-critical error messages and screen updates
   display 3
   setsearch user_pattern       -- Restore user's search pattern

   if (found = 1) then
   -- Calculate Screen Boundaries
      top_line   = .line - .cursory + 1
      left_col   = .col  - .cursorx + 1
      rite_col   = left_col + .windowwidth - 1

compile if WANT_BALANCE_SHOW_AT_BOTTOM = 1
      call bal_show_at_bottom(open_col, open_line)
compile else --WANT_BALANCE_SHOW_AT_BOTTOM = 1
      if (bal_on_screen(open_col, open_line, top_line, left_col, rite_col)) then
          -- The open character is on the screen, so highlight it
          call bal_show_char(open_char, open_col, open_line, top_line, left_col)

          -- The open character is not on the screen, so display its position
      else
         call bal_show_at_bottom(open_col, open_line)
      endif
compile endif --WANT_BALANCE_SHOW_AT_BOTTOM = 1

   else
      sayerror "No matching opening" type
compile if WANT_BALANCE_BEEP = 1
      call beep(fail_beep_Hz, 100)
compile endif --WANT_BALANCE_BEEP = 1
   endif  -- found = 1


defproc bal_minus_one( var col, var line)
-- Subtracts one from the column position.  If we hit the left column in
-- doing so, we go up to the line above us.
   col = col - 1
   if (col = 0) then
      line = line - 1
      getline x, line
      col = length(x)
   endif


defproc bal_last_char( search_pat, line_no, col_no, var new_x, var new_y)
-- Return the cursor position where the search ends, starting at given
-- position.  '-1' means that the search was unsuccessful
   if (col_no <> -1) then
      .col = col_no
      .line = line_no
      search_pat
   endif
   if (col_no = -1 or rc = sayerror('String not found')) then
      new_x = -1
      new_y = -1
   else
      new_x = .col
      new_y = .line
   endif


defproc bal_more_recent( c1_x, c1_y, c2_x, c2_y)
-- Says which set of coordinates (c1 or c2) is closer to the current pos
-- in the backwards direction.  1 means c1 is closer, 0 means c2 is.
   if (c2_y = -1)   then return 1; endif
   if (c1_y = -1)   then return 0; endif
   if (c1_y > c2_y) then return 1
   else
      if (c2_y > c1_y or c2_x > c1_x) then return 0
      else return 1
      endif
   endif


defproc bal_show_char( open_char, x_pos, y_pos, top_line, left_col)
;; -------------------------------------------------------------------- ;;
;; For EPM: flash character on the screen for a moment.                 ;;
;; -------------------------------------------------------------------- ;;
-- ***
-- *** EPM function
-- ***
-- The opening character is on the screen, so we highlight it
compile if WANT_BALANCE_SHOW_SAYAT = 1
   y_coord = y_pos-top_line+1
   x_coord = x_pos-left_col+1
--   y_coord = y_pos-top_line
--   x_coord = x_pos-left_col
--   display 1                          -- Turn off refreshing until we get a key
   do j = 1 to 5
--      sayat open_char, y_coord, x_coord, .markcolor, 1
--      refresh
      sayat open_char, y_coord, x_coord, LIGHT_BLUEB, 1
      do i = 1 to 100
      end
--      sayat open_char, y_coord, x_coord, .statuscolor, 1
--      refresh
      sayat open_char, y_coord, x_coord, LIGHT_GREYB, 1
      do i = 1 to 100
--         display 1
      end
   end
--  display 0
   refresh
compile else
   -- Better use highlighting instead of sayat, because the sayat marking is unstable
   x_endpos = x_pos + length(open_char) - 1
   'circleit 'y_pos x_pos x_endpos
compile endif -- WANT_BALANCE_SHOW_SAYAT = 1


defproc bal_on_screen( x_pos, y_pos, top_line, left_col, right_col)
   if ((y_pos < top_line) or (x_pos < left_col) or (x_pos > right_col)) then
      return 0
   else
      return 1
   endif

defproc bal_show_at_bottom( open_col, open_line)
   -- Opening character not on screen, so tell user in message area where it is
   getline line_str, open_line
   if (.line = open_line) then
      report_len = .col - open_col - 1
   else
      report_len = length(line_str) - open_col + 1
   endif
   report_line = substr(line_str, open_col, report_len)
   if (length(report_line) > 20) then
      report_line = substr(report_line, 1, 20) "..."
   endif
   sayerror "Line" open_line":" report_line

