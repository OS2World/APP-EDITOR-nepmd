/****************************** Module Header *******************************
*
* Module Name: nlsetup.cmd
*
* Frame batch for to call all required CMD files when setting up
* additional directories and files in the user directory tree.
*
* This module is called by the WarpIn package directly.
* In order to prevent a VIO windo opening for this REXX script,
* this (and only this script) is compiled to a PM executable.
*
* This program is intended to be called only during installation of the
* Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nlsetup.cmd,v 1.3 2002-08-11 00:44:02 cla Exp $
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

 /* init */
 '@ECHO OFF';

 /* make calldir the current directory */
 PARSE Source . . CallName;
 CallDir = LEFT( CallName, LASTPOS( '\', CallName) - 1);
 rcx = DIRECTORY( CallDir);

 /* call all modules required */
 'CALL USERTREE';
 'CALL APPLYICO';
 'CALL DYNCFG';

 EXIT( 0);

