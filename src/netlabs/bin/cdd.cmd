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
* $Id: cdd.cmd,v 1.4 2007-09-01 20:49:56 aschn Exp $
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

   Dir = ''
   do 1
      /* Check for drive-only FSpec */
      if substr( FSpec, 2) = ':' then
         leave

      /* Check for root dir (SysFileTree doesn't handle that correct) */
      if right( FSpec, 2) = ':\' | FSpec = '\' then
      do
         Dir = FSpec
         leave
      end

      /* Check if directory exists */
      /* SysFileTree doesn't handle "\.." and "\." correctly, */
      /* therefore use directory instead. */
      CurDir = directory()
      Found = directory( FSpec)
      if Found <> '' then
      do
         Dir = Found
         /* Change back to previous dir and drive */
         call directory CurDir
         if substr( CurDir, 2, 1) = ':' then
            call directory left( CurDir, 2)
         leave
      end

      /* Not a dir, then it may be a file, so try parent dir */
      Dir = strip( FSpec, 't', '\')'\..'
      leave

   end

   /* Change directory */
   if Dir <> '' then
      call directory Dir
end
else
   say directory()

return

