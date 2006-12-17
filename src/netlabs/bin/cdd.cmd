/****************************** Module Header *******************************
*
* Module Name: cdd.cmd
*
* Change drive and directory
*
* Syntax: cdd [filespec]
*
* If filespec contains a drive, then the drive is changed as well.
*
* If filespec is a file, then the path is changed to the parent directory
* of it.
*
* If filespec is not specified, then the current path is shown.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: cdd.cmd,v 1.2 2006-12-17 21:38:47 aschn Exp $
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

/* Initialize */
call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

FSpec = arg(1)

/* Strip optional doublequotes */
if left( FSpec, 1) = '"' then
   parse value FSpec with '"'FSpec'"'

if FSpec > '' then
do
   /* Change drive */
   if substr( FSpec, 2, 1) = ':' then
      call directory substr( FSpec, 1, 2)

   /* Check if directory exists */
   Found.0 = 0
   rc = SysFileTree( FSpec, 'Found.', 'DO')
   if Found.0 > 0 then
      Dir = Found.1
   else
      Dir = strip( FSpec, 't', '\')'\..'

   /* Change directory */
   call directory Dir
end
else
   say directory()

return

