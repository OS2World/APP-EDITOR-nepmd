/****************************** Module Header *******************************
*
* Module Name: cdd.cmd
*
* Change drive and directory
*
* Syntax: cdd [pathspec]
*
* If pathspec contains a drive, then the drive is changed as well.
*
* If pathspec is not specified, then the current path is shown.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: cdd.cmd,v 1.1 2006-03-11 20:59:12 aschn Exp $
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

dir = arg(1)

/* Strip optional doublequotes */
if left( dir, 1) = '"' then
   parse value dir with '"' dir '"'

if dir > '' then
do
   /* Change drive */
   if substr( dir, 2, 1) = ':' then
      call directory substr( dir, 1, 2)
   /* Change directory */
   call directory dir
end
else
   say directory()

return

