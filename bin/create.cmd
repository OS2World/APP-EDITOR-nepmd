@ECHO OFF
: ***************************** Module Header *******************************
:
: Module Name: create.cmd logfile scriptfile wpifile unzippeddir
:
: Script for to create the WarpIn package.
: This script
:    - downloads the EPM packages from www.leo.org
:    - creates the package source directories
:
: Call from makefile either with
:   make all          or
:   make create
:
: See readme.txt for requirements !
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: create.cmd,v 1.4 2002-04-19 09:57:35 cla Exp $
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
: ***************************************************************************

 SETLOCAL

 SET FILES=*

 SET LOGFILE=%1
 SET SCRIPTFILE=%2
 SET WPIFILE=%3
 SET UNZIPPEDDIR=%4
 IF NOT .%4 == . GOTO parmok
 ECHO.
 ECHO call this batch from within makefile only !
 ECHO.
 PAUSE
 GOTO end

:parmok
: delete old one, modifying an existing archive is not yet supported by WarpIn
 IF EXIST %WPIFILE% DEL %WPIFILE%

: defining packages - package IDs must comply to the WarpIn Script !

: --- package 1: application

 SET BASE=1 -r -c%UNZIPPEDDIR%\epmapp * 1 -r -c%UNZIPPEDDIR%\epmdll * 1 -r -c%UNZIPPEDDIR%\epmhlp * 1 -r -c%UNZIPPEDDIR%\epmbk *
 SET BMP=1 -r -c%UNZIPPEDDIR%\epmbmps *
 SET NEPMD_BOOK=1 book\nepmd.inf

: --- package 2: macros

 SET MACROS=2 -r -c%UNZIPPEDDIR%\epmmac * 2 -r -c%UNZIPPEDDIR%\epmmac2 * 2 -r -c%UNZIPPEDDIR%\epmsmp *
 SET EBOOKE=2 -r -c%UNZIPPEDDIR%\ebooke *
 SET MYASSIST=2 -r -c%UNZIPPEDDIR%\epmasi *
 SET VMEXEC=2 -r -c%UNZIPPEDDIR%\lampdq *

: --- package 3: Programming Samples

 SET SAMPLES=3 -r -c%UNZIPPEDDIR%\epmdde * 3 -r -c%UNZIPPEDDIR%\epmrex *  3 -r -c%UNZIPPEDDIR%\epmcsamp *
 SET ATTR=3 -r -c%UNZIPPEDDIR%\epmatr *

: --- package 4: Netlabs distribution extensions

 SET NEPMD=4 compile\netlabs\* src\netlabs\*

: --- package 5: Speech Support

 SET SPEECH=5 -r -c%UNZIPPEDDIR%\epmspch *

: --- build and start WPI

 ECHO - creating %WPIFILE%
 wic %WPIFILE% -a %BASE% %NEPMD% %SPEECH% %EBOOKE% %ATTR% %BMP% %MYASSIST% %MACROS%  %SAMPLES% %VMEXEC% -s %SCRIPTFILE% >%LOGFILE% 2>&1
 IF ERRORLEVEL 1 (DEL %WPIFILE% & TYPE %LOGFILE%)

:end

