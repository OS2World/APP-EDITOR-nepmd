@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: fmake.cmd
:
: Batch file for testing purposes:
: This batch file kills a running instance of recomp, rebuilds recomp
: and reloads it.
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

 PGMCNTRL /K /E:RECOMP.EXE >NUL 2>&1
 call make run

