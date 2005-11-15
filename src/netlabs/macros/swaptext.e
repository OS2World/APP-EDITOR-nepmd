/****************************** Module Header *******************************
*
* Module Name: swaptext.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: swaptext.e,v 1.3 2005-11-15 17:40:53 aschn Exp $
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

defc MoveLineUp
   if .last < 2 then
      return
   endif
   saved_autosave = .autosave
   .autosave = 0
   call DisableUndoRec()
   getline line
   l = max( .line - 1, 1)
   deleteline
   insertline line, l  -- insert above
   .lineg = l  -- go to line l without scrolling
   .line = l   -- scroll when outside of window
   .autosave = saved_autosave
   return

defc MoveLineDown
   if .last < 2 then
      return
   endif
   saved_autosave = .autosave
   .autosave = 0
   call DisableUndoRec()
   col = .col
   getline line
   deleteline
   insertline line, .line + 1  -- insert below
   down
   .col = col
   .autosave = saved_autosave
   return

defc MoveCharLeft
   saved_autosave = .autosave
   .autosave = 0
   call DisableUndoRec()
   if not insert_state() then
      -- switch to insert mode
      insert_toggle
      overwrite = 1
   else
      overwrite = 0
   endif
   getline line
   char = substr( line, .col, 1)
   deletechar
   executekey left
   keyin char
   executekey left
   if overwrite then
      insert_toggle
   endif
   .autosave = saved_autosave
   return

defc MoveCharRight
   saved_autosave = .autosave
   .autosave = 0
   call DisableUndoRec()
   if not insert_state() then
      -- switch to insert mode
      insert_toggle
      overwrite = 1
   else
      overwrite = 0
   endif
   getline line
   char = substr( line, .col, 1)
   deletechar
   executekey right
   keyin char
   executekey left
   if overwrite then
      insert_toggle
   endif
   .autosave = saved_autosave
   return

