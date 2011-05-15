/****************************** Module Header *******************************
*
* Module Name: xchgline.e
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

; Define some keys for line exchanging (vertical up/down)
;                  and char exchanging (horizontal left right)
;
; Current defs:
;    Sh+Alt+Up     move line up
;    Sh+Alt+Down   move line down
;    Sh+Alt+Left   move char left
;    Sh+Alt+Right  move char right
;
; Todo:
;    Make keys configurable

; ---- From STDKEYS.E ----
; defkeys edit_keys new clear
;
; def otherkeys =
;    k = lastkey()
;    call process_key(k)
; ------------------------

; See EPMSMP\TESTKEYS.E for defining keys with defc otherkeys and
; 'togglecontrol 26 0'


; Overwrite def otherkeys from STDKEYS.E here:
def otherkeys

   k = lastkey()
   if length(k)=1 then
      ch = 'chr('asc(k)')'
   else
      ch = "x'"rightstr(itoa(leftstr(k,1)\0,16),2,0) || rightstr(itoa(substr(k,2,1)\0,16),2,0)"'"
   endif

   saved_modify = .modify
   lk = lastkey(1)
   if lk = k then
      AlterModify = 0
   else
      AlterModify = 1
   endif
   --sayerror '.modify = '.modify', AlterModify = 'AlterModify', lk = 'lk', k = 'k

   if  ch = "x'1622'" and shifted() then
--    sayerror 'Shift+Alt+Up'
      call movelineup()
      if AlterModify = 0 then
         .modify = saved_modify
      else
         .modify = saved_modify + 1
      endif

   elseif ch = "x'1822'" and shifted() then
--    sayerror 'Shift+Alt+Down'
      call movelinedown()
      if AlterModify = 0 then
         .modify = saved_modify
      else
         .modify = saved_modify + 1
      endif

   elseif ch = "x'1522'" and shifted() then
--    sayerror 'Shift+Alt+Left'
      call movecharleft()
      if AlterModify = 0 then
         .modify = saved_modify
      else
         .modify = saved_modify + 1
      endif

   elseif ch = "x'1722'" and shifted() then
--    sayerror 'Shift+Alt+Right'
      call movecharright()
      if AlterModify = 0 then
         .modify = saved_modify
      else
         .modify = saved_modify + 1
      endif

   else
      call process_key(k)
   endif

defproc movelineup
  getline line
  if .line = .last then
    deleteline
    insertline line
    up
  elseif .line < 2 then
    deleteline
    insertline line
    up
  else
    deleteline
    up
    insertline line
    up
  endif
  return

defproc movelinedown
  col = .col
  getline line
  deleteline
  if .line = .last then
    call einsert_line() -- add an empty new line after current
    insertline line
    deleteline          -- delete new line
    down                -- scroll to the buttom
  else
    down
    insertline line
    up
  endif
  .col = col
  return

defproc movecharleft
  if not insert_state() then
     -- switch to insert mode
     insert_toggle
     overwrite = 1
  else
     overwrite = 0
  endif
  getline line
  char = substr(line,.col,1)
  deletechar
  executekey left
  keyin char
  executekey left
  if overwrite then
     insert_toggle
  endif
  return

defproc movecharright
  if not insert_state() then
     -- switch to insert mode
     insert_toggle
     overwrite = 1
  else
     overwrite = 0
  endif
  getline line
  char = substr(line,.col,1)
  deletechar
  executekey right
  keyin char
  executekey left
  if overwrite then
     insert_toggle
  endif
  return


