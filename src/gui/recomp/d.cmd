@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: d.cmd
:
: Batch file for testing purposes:
: This batch file loads the recomp executable from the debug directory
: into the debugger.
:
: The provided command line parameter lets recomp write the resulting .ex
: file to the %TMP% directory.
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

 SET DEBUGGER=icsdebug
 SET PMDPATH=..\common;%PMDPATH%
 IF .%CPPLOCAL% == . SET DEBUGGER=ipmd

 call make
 if not errorlevel 1 start %DEBUGGER% ..\..\..\debug\recomp.exe %TMP% %1 %2 %3 %4 %5 %6 %7 %8 %9

