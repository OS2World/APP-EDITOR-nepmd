/****************************** Module Header *******************************
*
* Module Name: sortepm.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: sortepm.e,v 1.2 2002-07-22 19:02:01 cla Exp $
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
compile if EVERSION < '5.60'
 Error:  SORTEPM.E (SORT_TYPE = 'EPM') can only be used with EPM 5.60 or above.
compile endif

defproc sort(firstline, lastline, firstcol, lastcol, fileid)
compile if EVERSION >= '6.01b'  -- Using BitOr, we can accept either Reverse or Descending
   flags = (not verify('R',upcase(arg(6)))) bitor    -- Reverse
           (not verify('D',upcase(arg(6)))) bitor    -- Descending
        (2*(not verify('I',upcase(arg(6))))) bitor   -- case Insensitive
        (4*(not verify('C',upcase(arg(6)))))         -- Collating order
compile else
   flags = not verify('R',upcase(arg(6))) + 2*(not verify('I',upcase(arg(6)))) + 4*(not verify('C',upcase(arg(6))))
compile endif
compile if EPM32
   return dynalink32(E_DLL, 'EtkSort',
                     gethwndc(5)     || atol(fileid)   ||
                     atol(firstline) || atol(lastline) ||
                     atol(firstcol)  || atol(lastcol)  ||
                     atol(flags),
                     2)
compile else
   return dynalinkc( E_DLL, '_EtkSort',      /* function name                 */
                     gethwndc(5)     || atol(fileid)   ||
                     atol(firstline) || atol(lastline) ||
                     atoi(firstcol)  || atoi(lastcol)  ||
                     atol(flags),
                     2);
compile endif

defc sort =
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   TypeMark=marktype()
   if TypeMark='' then  /* if no mark, default to entire file */
      getfileid fileid
      firstline=1 ; lastline=.last ; firstcol=1; lastcol = 40
   else
      getmark firstline, lastline, firstcol, lastcol, fileid
      /* If it was a line mark, the LastCol value can be 255.  Can't */
      /* imagine anyone needing a key longer than 40.                */
      if TypeMark='LINE' then lastcol=40 endif
   endif
compile if EVERSION >= '6.03'
   if fileid.readonly then
      sayerror READ_ONLY__MSG
      return
   endif
compile endif

   sayerror SORTING__MSG lastline-firstline+1 LINES__MSG'...'

   /* Pass the sort switches "rc", if any, as a sixth argument to sort().    */
   result = sort(firstline, lastline, firstcol, lastcol, fileid, arg(1) )
   if result then
      sayerror 'SORT' ERROR_NUMBER__MSG result
   else
      sayerror 0
   endif

/* To sort a new-format directory listing by date & time, enter the command:
      sortcols 11 15 16 16 1 5   7 8
               hh:mm  a/p  mm/dd  yy
   For an old-format directory listing, enter:
      sortcols 34 38 39 39 23 28 30 31
               hh:mm  a/p  mm/dd  yy
*/
defc sortcols =
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   TypeMark=marktype()
   if TypeMark='' then  /* if no mark, default to entire file */
      getfileid fileid
      firstline=1 ; lastline=.last
   else
      getmark firstline, lastline, firstcol, lastcol, fileid
   endif
compile if EVERSION >= '6.03'
   if fileid.readonly then
      sayerror READ_ONLY__MSG
      return
   endif
compile endif

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

      /* Pass the sort switches "rc", if any, as a sixth argument to sort().    */
      result = sort(firstline, lastline, c1, c2, fileid, sort_flags )
      if result then
         sayerror 'SORT' ERROR_NUMBER__MSG result
         stop
      endif

   enddo
   sayerror 0

