@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name:
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: readme.cmd,v 1.3 2002-06-11 11:08:24 cla Exp $
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

 SET PARMS=%1 %2 %3 %4 %5 %6 %7 %8 %9
 IF .%PARMS% == . SET PARMS=Making

 start view bin\makefile %PARMS%

