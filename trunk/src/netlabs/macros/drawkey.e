/****************************** Module Header *******************************
*
* Module Name: drawkey.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: drawkey.e,v 1.4 2004-06-29 20:48:37 aschn Exp $
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
;  DRAWKEY.E
;  Taken from DRAW.E, to make it separately compilable.
;
;def F6=
defc StartDraw
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
 compile if WANT_DBCS_SUPPORT
   if ondbcs then
      sayerror DRAW_ARGS_DBCS__MSG
   else
 compile endif
      sayerror DRAW_ARGS__MSG
 compile if WANT_DBCS_SUPPORT
   endif
 compile endif
   'commandline draw '
