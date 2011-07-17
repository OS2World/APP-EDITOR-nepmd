/****************************** Module Header *******************************
*
* Module Name: epmlast.cmd
*
* Syntax: epmlast [<epm_exe> [<epm_args>]]
*
* <epm_exe> and/or <epm_args> both can be enclosed with " chars.
*
* Helper batch for to open a new EPM window with the last saved ring.
*
* This program is called by EPM's Restart command in order to close the
* EPM window properly before a new one is restarted. Therefore the new EPM
* window is started delayed.
*
* If called without parameters, the delay will be deactivated. Therefore
* this program can be used by a user as well to start EPM with the last
* saved ring, whenever he doubleclicks the .cmd file.
*
* Copyright (c) Netlabs EPM Distribution Project 2005
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

env   = 'OS2ENVIRONMENT'
Delay = 1  /* in s, time to wait before a new window is opened */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

parse arg args
args = strip( args)
rest = args
if left( rest, 1) = '"' then
   parse var rest '"'EpmExe'"' rest
else
   parse var rest EpmExe rest
if left( rest, 1) = '"' then
   parse var rest '"'rest'"'
EpmArgs = rest

if EpmExe = '' then
do
    /* Get BootDrive */
   if \RxFuncQuery( 'SysBootDrive') then
      BootDrive = SysBootDrive()
   else
      parse upper value value( 'PATH', , env) with ':\OS2\SYSTEM' -1 BootDrive +2
   EpmExe = BootDrive'\os2\epm.exe'
end

if EpmArgs = '' then
   EpmArgs = "'RestoreRing'"

if args > '' then
   call SysSleep Delay


/* Use /i to inherit from system environment instead of from */
/* the previous EPM. This makes EPM reload its environment.  */
'start /i' EpmExe EpmArgs

exit

