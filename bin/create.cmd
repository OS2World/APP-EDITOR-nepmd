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
: Called from src\wis\makefile either with
:   make all          or
:   make create
:
: See readme.txt for requirements !
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: create.cmd,v 1.9 2002-06-03 18:09:38 cla Exp $
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
 SET PATH=bin;%PATH%

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

: access WarpIn environment
 CALL WARPIN.ENV
 IF ERRORLEVEL 1 GOTO end

: check if debug level active, select tree of appropriate binaries directory
 SET BINDIR=debug
 IF .%DEBUG% == . SET BINDIR=release

: delete old one, modifying an existing archive is not yet supported by WarpIn
 IF EXIST %WPIFILE% DEL %WPIFILE%

: defining packages - package IDs must comply to the WarpIn Script !

: --- package 1: application with Netlabs distribution extensions


 SET BASE=1 -r -c%UNZIPPEDDIR%\epmapp * 1 -r -c%UNZIPPEDDIR%\epmdll * 1 -r -c%UNZIPPEDDIR%\epmhlp * 1 -r -c%UNZIPPEDDIR%\epmbk *
 SET BMP=1 -r -c%UNZIPPEDDIR%\epmbmps *
 SET NEPMD_BASE=1 -r -ccompile netlabs\install\* 1 -r -ccompile netlabs\book\* 1 -r -c%BINDIR% netlabs\bin\*

: --- package 2: macros

 SET MACROS=2 -r -c%UNZIPPEDDIR%\epmmac * 2 -r -c%UNZIPPEDDIR%\epmmac2 * 2 -r -c%UNZIPPEDDIR%\epmsmp *
 SET EBOOKE=2 -r -c%UNZIPPEDDIR%\ebooke *
 SET MYASSIST=2 -r -c%UNZIPPEDDIR%\epmasi *
 SET VMEXEC=2 -r -c%UNZIPPEDDIR%\lampdq *

: --- package 3: Programming Samples

 SET SAMPLES=3 -r -c%UNZIPPEDDIR%\epmdde * 3 -r -c%UNZIPPEDDIR%\epmrex *  3 -r -c%UNZIPPEDDIR%\epmcsamp *
 SET ATTR=3 -r -c%UNZIPPEDDIR%\epmatr *

: --- package 4: Speech Support

 SET SPEECH=4 -r -c%UNZIPPEDDIR%\epmspch *

: --- build and start WPI

 ECHO - creating %WPIFILE%
 wic %WPIFILE% -a %BASE% %BMP% %NEPMD_BASE%   %MACROS% %EBOOKE% %MYASSIST% %VMEXEC%   %SAMPLES% %ATTR%   %SPEECH% -s %SCRIPTFILE% >%LOGFILE% 2>&1
 IF ERRORLEVEL 1 (DEL %WPIFILE% & TYPE %LOGFILE%)

:end

