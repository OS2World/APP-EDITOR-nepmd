@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: setenv.cmd
:
: Set the environment for the making of NEPMD

: This file sets the user-specific vars before setenv2.cmd is called.
:
: Usage: Copy this file to the main project directory and adjust the
:        environment variables below.
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: setenv.cmd,v 1.1 2006-04-15 18:28:40 aschn Exp $
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
:
: ---------------------------------------------------------------------------
: Begin of user-configurable part
: ---------------------------------------------------------------------------
:
: ---- Project env vars
: adjust timestamps of compiled files?
: (comment that out if you use 4os2 as shell)
SET TOUCH=1
: create a debug or release version?
: (comment the next line out to create a release version)
SET DEBUG=1
: default is to use <main_project_dir>\zip
: SET ZIPSRCDIR=f:\zip
: default is to use <main_project_dir>\epm.packages
: SET UNZIPPEDDIR=f:\epm.packages
:
: ---- Enlarge the VIO window
: MODE CO120,50
:
: ---- Of course we use EPM for writing cvs commit comments
SET CVSEDITOR=EPM /M
:
: ---- Visual Age C++ v3.08 and C Set/2 v2.1 are supported
SET DIR_COMPILER=e:\dev\ibmcpp308

: ---- Specify either VAC308 or CSET2
: SET USED_COMPILER=CSET2
SET USED_COMPILER=VAC308

: ---- Toolkits 3/4/4.5 are supported
SET DIR_TOOLKIT=f:\dev\toolkt45
:
: ---- Following env vars must be set
: SET TMP=...
: SET TZ=...
:
: ---------------------------------------------------------------------------
: End of user-configurable part
: ---------------------------------------------------------------------------
:
: ---- Execute the environment file

: Check if this file is executed from the main project directory
: In order to not overwrite the user's changes the user should copy it
: to the main project directory and adjust that version.
IF EXIST .\bin\setenv2.cmd CALL .\bin\setenv2.cmd&GOTO :END
:
ECHO Error: This cmd file should not be executed out of the bin directory.
ECHO.
ECHO Copy it to the main project directory and adjust the user-configurable part.
:
:END
