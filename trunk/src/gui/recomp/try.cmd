@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: try.cmd
:
: Batch file for testing purposes:
: This program loads several files into one or more EPM windows (file rings)
: in order to ease testing of the reload function.
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: try.cmd,v 1.1 2002-06-03 22:30:16 cla Exp $
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

:ok
 DEL %TMP%\*.C2T          >NUL 2>&1
 DEL %TMP%\$RECOMP$.CMD   >NUL 2>&1

: load program
 call q

: load one of several testcases

 IF NOT .%1 == . GOTO %1

 start epm *.c
 DOSSLEEP 2 >NUL
 start epm *.h
 DOSSLEEP 2 >NUL
 start epm *.cmd
 DOSSLEEP 2 >NUL
 start epm *.rc*
 GOTO end

:1
 start epm todo
 DOSSLEEP 2 >NUL
 start epm done
 GOTO end

:2
 start epm client.*
 DOSSLEEP 2 >NUL
 start epm dde.*
 DOSSLEEP 2 >NUL
 start epm ddereload.*
 DOSSLEEP 2 >NUL
 start epm ddeutil.*
 DOSSLEEP 2 >NUL
 start epm file.*
 DOSSLEEP 2 >NUL
 start epm frame.*
 DOSSLEEP 2 >NUL
 start epm job.*
 DOSSLEEP 2 >NUL
 start epm pmres.*
 DOSSLEEP 2 >NUL
 start epm printf.*
 DOSSLEEP 2 >NUL
 start epm process.*
 DOSSLEEP 2 >NUL
 start epm recomp.*

:end
