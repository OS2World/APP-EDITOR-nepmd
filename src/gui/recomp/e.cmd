@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: e.cmd
:
: Batch file for testing purposes:
: Load selected files into EPM.
:
: This file may make sense to change by each individual developer.
: PLEASE DO NOT CHECK IN MODIFIED VERSIONS OF THIS FILE FREQUENTLY!
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id$
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

 SET FILES=client.c frame.c dde.c job.c
 SET FILES=job.c ddereload.c ddelog.c client.c recomp.e

 start epm %1 %2 %3 %4 %5 %6 %7 %8 %9 %FILES%

