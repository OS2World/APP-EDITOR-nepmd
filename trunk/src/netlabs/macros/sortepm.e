/****************************** Module Header *******************************
*
* Module Name: sortepm.e
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

; ---------------------------------------------------------------------------
defproc Sort( firstline, lastline, firstcol, lastcol, fileid)

   flags = (not verify( 'R', upcase( arg(6)))) bitor    -- Reverse
           (not verify( 'D', upcase( arg(6)))) bitor    -- Descending
        (2*(not verify( 'I', upcase( arg(6))))) bitor   -- case Insensitive
        (4*(not verify( 'C', upcase( arg(6)))))         -- Collating order

   rcx = dynalink32( E_DLL, 'EtkSort',
                     gethwndc(5)     || atol(fileid)   ||
                     atol(firstline) || atol(lastline) ||
                     atol(firstcol)  || atol(lastcol)  ||
                     atol(flags),
                     2)

   return rcx

; ---------------------------------------------------------------------------
defc Sort
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

   sayerror SORTING__MSG lastline-firstline+1 LINES__MSG'...'

   SortOptions = arg(1)  -- R | D | I | C
   -- PostMe required if char mark was changed to line mark
   'PostMe Sort2' firstline lastline firstcol lastcol fileid SortOptions

defc Sort2
   parse value arg(1) with firstline lastline firstcol lastcol fileid SortOptions .
   -- Bug in EtkSort?
   -- Undo to previous states doesn't work after defproc sort.
   -- defc treesort uses defproc sort as well and it correctly creates a new
   -- undo state, after the file was sorted once.
   rc = Sort( firstline, lastline, firstcol, lastcol, fileid, SortOptions)
   if rc then
      sayerror 'Error. Sort returned with rc = 'rc
   else
      call NewUndoRec()
      sayerror 0
   endif

; ---------------------------------------------------------------------------
; To sort a new-format directory listing by date & time, enter the command:
;    sortcols 11 15 16 16 1 5   7 8
;             hh:mm  a/p  mm/dd  yy
; For an old-format directory listing, enter:
;    sortcols 34 38 39 39 23 28 30 31
;             hh:mm  a/p  mm/dd  yy
defc SortCols
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
      call NextCmdAltersText()
      rc = Sort( firstline, lastline, c1, c2, fileid, sort_flags)
      if rc then
         sayerror 'Error. Sort returned with rc = 'rc
         stop
      endif

   enddo
   call NewUndoRec()
   sayerror 0

