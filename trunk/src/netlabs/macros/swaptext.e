/****************************** Module Header *******************************
*
* Module Name: swaptext.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: swaptext.e,v 1.1 2004-11-30 21:34:05 aschn Exp $
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
   getline line
   l = max( .line - 1, 1)
   deleteline
   insertline line, l  -- insert above
   .line = l
   down; up  -- scroll to make the line below viewable
   return

defc MoveLineDown
   col = .col
   getline line
   deleteline
   insertline line, .line + 1  -- insert below
   down
   .col = col
   return

defc MoveCharLeft
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

defc MoveCharRight
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

