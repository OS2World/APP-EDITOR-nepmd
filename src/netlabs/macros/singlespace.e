/****************************** Module Header *******************************
*
* Module Name: singlespace.e
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

defmain

   'singlespace'



; Remove every 2nd line, if it's a blank line.

; Stop if a 2nd line is not blank. Start at the forelast line, which

; must be blank.

defc singlespace

   do i = .last - 1 to 1 by -2

      if textline(i) <> '' then

         sayerror 'Line' i 'is not blank!'

         return

      endif

      deleteline i

   enddo


