/****************************** Module Header *******************************
*
* Module Name: rkeysel.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: rkeysel.e,v 1.2 2002-07-22 19:01:39 cla Exp $
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
;      An if-block that gets included into select_edit_keys().
   if ext='BAT' | ext='CMD' | ext='EXC' | ext='EXEC' | ext='XEDIT' then
      getline line,1
      if substr(line,1,2)='/*' or (line='' & .last = 1) then
         keys   rexx_keys
         'tabs' REXX_TABS
         'ma'   REXX_MARGINS
      endif
   endif
