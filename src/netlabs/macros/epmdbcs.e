/****************************** Module Header *******************************
*
* Module Name: epmdbcs.e
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
definit
   universal country
   universal countryinfo
   universal codepage
   universal dbcsvec
   universal ondbcs

   inp=copies(\0, 8)
   countryinfo=copies(\0, 44)
   ret=\0\0\0\0
   call dynalink32('NLS', '#5',        -- DOS32QueryCountryInfo
                   atol(length(countryinfo))  ||
                   address(inp)       ||
                   address(countryinfo)       ||
                   address(ret),
                   2)
   country=ltoa(leftstr(countryinfo,4),10)

   codepage = '????'; datalen = '????'
   call dynalink32('DOSCALLS',            -- dynamic link library name
                   '#291',                -- ordinal value for DOS32QueryCP
                   atol(4)            ||  -- length of code page list
                   address(codepage)  ||
                   address(datalen),2)
   codepage = ltoa(codepage,10)

   inp=copies(\0,8)
   dbcsvec=copies(\0, 12)
   call dynalink32('NLS', '#6',
                   atol(length(dbcsvec)) ||
                   address(inp)          ||
                   address(dbcsvec),
                   2)
   ondbcs = leftstr(dbcsvec, 2) <> atoi(0)

defproc isdbcs(c)
   universal dbcsvec, ondbcs
   if not ondbcs then
      return 0
   endif
   c=leftstr(c,1)
   for i = 1 to length(dbcsvec) by 2
      if substr(dbcsvec,i,2)=atoi(0) then
         leave
      endif
      if substr(dbcsvec, i, 1) <= c and c <= substr(dbcsvec, i + 1, 1) then
         return 1
      endif
   endfor
   return 0

defproc whatisit(s, p)
   l = length(s)
   i = 1
   while i <= l do
      if i > p then
         leave
      endif
      if isdbcs(substr(s, i, 1)) then
         if i = p then
            return 1 -- DBCS 1st
         elseif i + 1 = p then
            return 2 -- DBCS 2nd
         else
            i = i + 2
         endif
      else
         i = i + 1
      endif
   endwhile
   return 0 -- SBCS
