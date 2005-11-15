/****************************** Module Header *******************************
*
* Module Name: indentblock.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: indentblock.e,v 1.7 2005-11-15 17:14:25 aschn Exp $
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

compile if not defined(SMALL) then
define INCLUDING_FILE = 'INDENTBLOCK.E'

defmain
   'indentblock 'arg(1)
compile endif


defc indentblock
   universal indent  -- current syntaxindent

   call DisableUndoRec()
   parse arg direction
   if abbrev( upcase(direction), 'U') then
      IndentMode = 'UNDENT'
   else
      IndentMode = 'INDENT'
   endif

   SyntaxIndent = indent
   if SyntaxIndent = '' then
      SyntaxIndent = word( .tabs, 1)
   endif

   call psave_pos(savedpos)
   fWasMarked = 0
   getmark firstline, lastline, firstcol, lastcol, fid
   getfileid curfid
   mt = marktype()
   --getmark firstLine, lastLine, firstCol, lastCol, fId
   --sayerror firstLine',' lastLine',' firstCol',' lastCol',' mt
   if mt = '' then  -- check if any file is marked
      fWasMarked = 0
   elseif mt <> '' & curfid <> fid then  -- check if another file in ring is marked
      fWasMarked = 0
      unmark
   elseif mt = 'LINE' or mt = 'BLOCK' then
      fWasMarked = 1
   elseif mt = 'CHAR' then
      if lastCol = 0 then
         lastLine = lastLine - 1
      endif
      --sayerror 'Line or block mark required. Or unmark text to indent block at cursor.'
      --return
      -- Better change to line mark
      fWasMarked = 1
      unmark
      call pset_mark( firstLine, lastLine, 1, 1599, 'LINE', fid)
   endif

   if fWasMarked = 0 then
      -- Get indent of current line
      call pfirst_nonblank()
      StartIndent = .col - 1
      StartL      = .line
      mark_line  -- mark first line
      -- Find next line with same indent, try down
      fSearchUp = 0
      NextIndent = ''
      EndL = StartL
      l = StartL
      do forever
         l = l + 1
         if l = .last + 1 then
            leave
         endif
         getline line, l
         -- Ignore blank lines
         if verify( textline(.line), ' '\t) = 0 then
            iterate
         endif
         .line = l
         call pfirst_nonblank()
         CurIndent = .col - 1
         if CurIndent >= StartIndent then
            if NextIndent = '' then
               NextIndent = CurIndent
            endif
            mark_line  -- extend mark
         else
            if NextIndent = '' then
               -- Reverse search direction if indent of first line >= StartIndent
               fSearchUp = 1
               leave
            else
               -- NextIndent was already set ==> current line is 1 line after EndL
               --EndL = .line - 1
               leave
            endif
         endif
      enddo

      -- Find next line with same indent, try up
      l = StartL
      if fSearchUp then
         do forever
            l = l - 1
            if l = 0 then
               leave
            endif
            getline line, l
            -- Ignore blank lines
            if strip(line) = '' then
               iterate
            endif
            .line = l
            call pfirst_nonblank()
            CurIndent = .col - 1
            if CurIndent >= StartIndent then
               mark_line  -- extend mark
            else
               -- Current line is 1 line before EndL
               --EndL = .line + 1
               leave
            endif
         enddo
      endif
   endif

   do i = 1 to SyntaxIndent
      if IndentMode = 'UNDENT' then
         if fWasMarked = 0 then
            if i > StartIndent then
               leave
            endif
         endif
         shift_left
      else
         shift_right
      endif
   enddo

   call prestore_pos(savedpos)
/*
   if fWasMarked = 1 then
      call pset_mark( firstLine, lastLine, firstCol, lastCol, mt, fid)
   endif
*/

