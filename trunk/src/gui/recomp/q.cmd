@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: q.cmd
:
: Batch file for testing purposes:
: This batch file executes the recomp executable from the debug directory.
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: q.cmd,v 1.1 2002-06-03 22:30:16 cla Exp $
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

 call env
 call make
 if not errorlevel 1 start ..\..\..\debug\recomp %TMP% %1 %2 %3 %4 %5 %6 %7 %8 %9

