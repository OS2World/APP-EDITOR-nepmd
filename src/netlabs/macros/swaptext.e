/****************************** Module Header *******************************
*
* Module Name: swaptext.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: swaptext.e,v 1.2 2004-11-30 21:34:57 aschn Exp $
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
   saved_modify = .modify
   saved_autosave = .autosave
   .autosave = 0
   action = 1
   undoaction 4, action  -- disable undo recording
   getline line
   l = max( .line - 1, 1)
   deleteline
   insertline line, l  -- insert above
   .lineg = l  -- go to line l without scrolling
   .line = l   -- scroll when outside of window
   --sayerror 'saved_modify = 'saved_modify', .modify = '.modify', lastkey(2) = 'c2x( lastkey(2))', lastkey(3) = 'c2x( lastkey(3))
   if lastkey(2) = lastkey(3) & saved_modify > 0 then  -- reset to last .modify if key was repeated
      .modify = saved_modify
   else
      .modify = saved_modify + 1
   endif
   .autosave = saved_autosave
   return

defc MoveLineDown
   if .last < 2 then
      return
   endif
   saved_modify = .modify
   saved_autosave = .autosave
   .autosave = 0
   action = 1
   undoaction 4, action  -- disable undo recording
   col = .col
   getline line
   deleteline
   insertline line, .line + 1  -- insert below
   down
   .col = col
   --sayerror 'saved_modify = 'saved_modify', .modify = '.modify', lastkey(2) = 'c2x( lastkey(2))', lastkey(3) = 'c2x( lastkey(3))
   if lastkey(2) = lastkey(3) & saved_modify > 0 then  -- reset to last .modify if key was repeated
      .modify = saved_modify
   else
      .modify = saved_modify + 1
   endif
   .autosave = saved_autosave
   return

defc MoveCharLeft
   saved_modify = .modify
   saved_autosave = .autosave
   .autosave = 0
   action = 1
   undoaction 4, action  -- disable undo recording
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
   if lastkey(2) = lastkey(3) & saved_modify > 0 then  -- reset to last .modify if key was repeated
      .modify = saved_modify
   else
      .modify = saved_modify + 1
   endif
   .autosave = saved_autosave
   return

defc MoveCharRight
   saved_modify = .modify
   saved_autosave = .autosave
   .autosave = 0
   action = 1
   undoaction 4, action  -- disable undo recording
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
   if lastkey(2) = lastkey(3) & saved_modify > 0 then  -- reset to last .modify if key was repeated
      .modify = saved_modify
   else
      .modify = saved_modify + 1
   endif
   .autosave = saved_autosave
   return

