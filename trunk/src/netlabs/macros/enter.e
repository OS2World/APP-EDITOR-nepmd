/****************************** Module Header *******************************
*
* Module Name: enter.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: enter.e,v 1.1 2002-09-08 16:13:49 aschn Exp $
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
; WANT_CUA_MARKING = 'SWITCH'
; ENTER_ACTION = 'STREAM'
; NEPMD_STREAM_INDENTED = 1

const
compile if not defined(NEPMD_STREAM_INDENTED)
   -- This activates the defs for WANT_STREAM_INDENTED too
   NEPMD_STREAM_INDENTED = 0
compile endif

compile if NEPMD_STREAM_INDENTED and WANT_STREAM_MODE <> 0
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

compile if ENHANCED_ENTER_KEYS
defproc enter_common(action)
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
   if stream_mode then
 compile endif
 compile if WANT_STREAM_MODE
      if .line then
  compile if WANT_CUA_MARKING
   compile if WANT_CUA_MARKING = 'SWITCH'
         if CUA_marking_switch then
   compile endif
            if not process_mark_like_cua() and   -- There was no mark
               not insert_state() then           -- & we're in replace mode
               delete_char    -- Delete the character, to emulate replacing the
            endif             -- marked character with a newline.
   compile if WANT_CUA_MARKING = 'SWITCH'
         endif
   compile endif
  compile endif  -- WANT_CUA_MARKING
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
         .col=1
         down
  compile endif -- WANT_STREAM_INDENTED
      else
         insert
         .col=1
      endif
      return
 compile endif  -- WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   endif
 compile endif
 compile if WANT_STREAM_MODE <> 1
   is_lastline = .line=.last
   if is_lastline  & (action=3 | action=5) then  -- 'ADDATEND' | 'DEPENDS+'
      call einsert_line()
      down                       -- This keeps the === Bottom === line visible.
      return
   endif
;     'NEXTLINE' 'ADDATEND'                        'DEPENDS'  'DEPENDS+'
   if action=2 | action=3 | (not insert_state() & (action=4 | action=5)) then
      down                          -- go to next line
      begin_line
      return
   endif
   if action=6 then
      call splitlines()
      call pfirst_nonblank()
      down
;;    refresh
      return
   endif
   if action=7 | action=8 then
      insert
      parse value pmargins() with leftcol . paracol .
      if textline(.line-1)='' or .line=1 or action=8 then
         .col=paracol
      else
         .col=leftcol
      endif
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   if action=9 then
      insert
      begin_line
      if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
      return
   endif
   call einsert_line()           -- insert a line
   if is_lastline then down; endif  -- This keeps the === Bottom === line visible.
 compile endif  -- WANT_STREAM_MODE <> 1
compile endif  -- ENHANCED_ENTER_KEYS


-----------------------------------------------------------------------
; Following has moved from STDKEYS.E

compile if ENHANCED_ENTER_KEYS & C_ENTER_ACTION <> ''  -- define each key separately
; Nothing - defined below along with ENTER
compile else
def c_enter, c_pad_enter=     -- 4.10:  new key for enhanced keyboard
   call my_c_enter()
 compile if    SHOW_MODIFY_METHOD
   call show_modify()
 compile endif
compile endif

compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
def enter =
   universal enterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(enterkey)
 compile else
   call enter_common(enterkey)
 compile endif
def a_enter =
   universal a_enterkey
   call enter_common(a_enterkey)
def c_enter =
   universal c_enterkey
   call enter_common(c_enterkey)
def s_enter =
   universal s_enterkey
   call enter_common(s_enterkey)
def padenter =
   universal padenterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(padenterkey)
 compile else
   call enter_common(padenterkey)
 compile endif
def a_padenter =
   universal a_padenterkey
   call enter_common(a_padenterkey)
def c_padenter =
   universal c_padenterkey
   call enter_common(c_padenterkey)
def s_padenter =
   universal s_padenterkey
   call enter_common(s_padenterkey)
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
defproc shell_enter_routine(xxx_enterkey)
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call enter_common(xxx_enterkey)
      endif
   else
      call enter_common(xxx_enterkey)
   endif
 compile endif  -- EPM_SHELL

compile else
def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter=
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call my_enter()
      endif
   else
 compile endif
      call my_enter()
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   endif
 compile endif
compile endif  -- ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''

/*
; Todo:
; -  Move following code to a new file SHELLKEYS.E, simular to CKEYS.E.
; -  Include SHELLKEYS.E in EPM.E, but undependent on ALTERNATE_KEYSETS
-----------------------------------------------------------------------
; SHELLKEYS.E

; Consts concerning with shell:
; EPM_SHELL_PROMPT = '@prompt epm: $p $g'
; WANT_EPM_SHELL = 1


defkeys shellkeys new clear

compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
def enter =
   universal enterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(enterkey)
 compile endif

def padenter =
   universal padenterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(padenterkey)
 compile endif

 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
defproc shell_enter_routine(xxx_enterkey)
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call enter_common(xxx_enterkey)
      endif
   else
      call enter_common(xxx_enterkey)
   endif
 compile endif  -- EPM_SHELL

compile else
def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter=
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call my_enter()
      endif
   endif
 compile endif
compile endif  -- ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''

*/
