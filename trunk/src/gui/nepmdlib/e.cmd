@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: e.cmd
:
: Batch file for testing purposes:
: Load selected files into EPM after having set debug environment
: NOTE:
:   - BEGINLIBPATH to NEPMDLIB.DLL is not set here (didn't work)
:   - if you execute 'relink nepmdlib',file is written to the current
:     directory. Don't check that file into the archive !
:
: This file may make sense to change by each individual developer.
: PLEASE DO NOT CHECK IN MODIFIED VERSIONS OF THIS FILE FREQUENTLY!
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: e.cmd,v 1.3 2002-08-21 14:08:08 cla Exp $
:
: ===========================================================================
:
: This file is part of the Netlabs EPM Distribution package and is free
: software.  You can redistribute it and/or modify it under the terms of the
: GNU General Public License as published by the Free Software
: Foundation, in version 2 as it comes in the "COPYING" file of the
: Netlabs EPM Distribution.  This library is distributed in the hope that it
: will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
: of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
: General Public License for more details.
:
: **************************************************************************/

 SETLOCAL
 SET EPMPATH=%EPMPATH%;macros;..\..\..\compile\base\netlabs\ex;
 SET NEPMD_TMFTESTFILE=nepmdlib.tmf

 start epm *.e *.c

