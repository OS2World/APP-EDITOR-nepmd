/****************************** Module Header *******************************
*
* Module Name: sortepm.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: sortepm.e,v 1.6 2005-05-16 20:53:03 aschn Exp $
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
defproc sort( firstline, lastline, firstcol, lastcol, fileid)
   flags = (not verify( 'R', upcase( arg(6)))) bitor    -- Reverse
           (not verify( 'D', upcase( arg(6)))) bitor    -- Descending
        (2*(not verify( 'I', upcase( arg(6))))) bitor   -- case Insensitive
        (4*(not verify( 'C', upcase( arg(6)))))         -- Collating order
   return dynalink32( E_DLL, 'EtkSort',
                      gethwndc(5)     || atol(fileid)   ||
                      atol(firstline) || atol(lastline) ||
                      atol(firstcol)  || atol(lastcol)  ||
                      atol(flags),
                      2)

; ---------------------------------------------------------------------------
defc sort =
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   TypeMark = marktype()
   if TypeMark = '' then  -- if no mark, default to entire file
      getfileid fileid
      firstline = 1 ; lastline = .last ; firstcol = 1; lastcol = 40
   else
      getmark firstline, lastline, firstcol, lastcol, fileid
      if TypeMark = 'CHAR' then
         call pset_mark( firstline, lastline, firstcol, lastcol, 'LINE', fileid)
      endif
      if TypeMark = 'LINE' then
         -- If it was a line mark, the LastCol value can be 1599.  Can't
         -- imagine anyone needing a key longer than 40.
         lastcol = 40
      endif
   endif
   if fileid.readonly then
      sayerror READ_ONLY__MSG
      return
   endif

   -- Bug in EtkSort?
   -- Undo to previous states doesn't work after defproc sort.
   -- defc treesort uses defproc sort as well and it correctly creates a new
   -- undo state, after the file was sorted once.
;   undotime = 2            -- 2 = when moving the cursor from a modified line
;   undoaction 4, undotime  -- Disable state recording at specified time

   sayerror SORTING__MSG lastline-firstline+1 LINES__MSG'...'

   -- Pass the sort switches "rc", if any, as a sixth argument to sort().
   result = sort( firstline, lastline, firstcol, lastcol, fileid, arg(1))

;   undoaction 5, undotime  -- Enable state recording at specified time
;   undoaction 1, junk      -- Create a new state

   if result then
      sayerror 'SORT' ERROR_NUMBER__MSG result
   else
      sayerror 0
   endif

; ---------------------------------------------------------------------------
; To sort a new-format directory listing by date & time, enter the command:
;    sortcols 11 15 16 16 1 5   7 8
;             hh:mm  a/p  mm/dd  yy
; For an old-format directory listing, enter:
;    sortcols 34 38 39 39 23 28 30 31
;             hh:mm  a/p  mm/dd  yy
defc sortcols =
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   TypeMark = marktype()
   if TypeMark = '' then  -- if no mark, default to entire file
      getfileid fileid
      firstline = 1 ; lastline = .last
   else
      getmark firstline, lastline, firstcol, lastcol, fileid
   endif
   if fileid.readonly then
      sayerror READ_ONLY__MSG
      return
   endif

   cols = arg(1)
   sort_flags = ''
   do while cols <> ''
      if not isnum(word(cols,1)) then
         parse value cols with sort_flags c1 c2 cols
      else
         parse value cols with c1 c2 cols
      endif
      if not isnum(c1) or not isnum(c2) then
         sayerror -336
         stop
      endif

      sayerror SORTING__MSG lastline-firstline+1 LINES__MSG '('c1 '-' c2') ...'

      -- Pass the sort switches "rc", if any, as a sixth argument to sort().
      result = sort( firstline, lastline, c1, c2, fileid, sort_flags)
      if result then
         sayerror 'SORT' ERROR_NUMBER__MSG result
         stop
      endif

   enddo
   sayerror 0

