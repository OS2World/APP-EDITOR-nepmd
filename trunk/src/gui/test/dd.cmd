@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: dd.cmd
:
: This batch file starts the debugger and reads the current testcase to use
: from env.cmd
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

 call env.cmd
 d %TESTCASE% %1 %2 %3 %4 %5

