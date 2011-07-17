/****************************** Module Header *******************************
*
* Module Name: tc.e
*
* Macro file for testing purposes:
* This macro is used for the testcase scenario in order to position
* the cursor to a different cursor position for each file of the
* testcase subdirectory.
*
* See tc.cmd for more details.
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

defc tc_setpos

do i = 1 to filesinring( 3)
   if (.filename = '.Untitled') then
      'QUIT'
   else
      curpos = substr( .filename, length( .filename))
      call prestore_pos( curpos curpos curpos curpos+1)
   endif;

   next_file;
enddo

sayerror 'filepositions set'

