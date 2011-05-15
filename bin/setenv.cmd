@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: setenv.cmd
:
: Set the environment for the making of NEPMD
:
: This file sets the user-specific vars before setenv2.cmd is called.
:
: Requirements : See makefile.inf, section "Requirements".
:
: Prerequisite : The project files must be already checked-out. (Most likely
:                you have already done that when you are reading this.)
:
: Configuration: Option 1: If there is no mysetenv.cmd in the main project
:                   directory, then run this program or setenv2.cmd. You
:                   will be prompted for settings and your sentenv.cmd
:                   file will be created for you.
:                Option 2: To change customizations in an existing
:                   mysetenv.cmd (in the main project directory.):
:                   a) Manually edit the existing file; or
:                   b1) SET USED_COMPILER=xxx
:                   b2) Run bin\setenv.cmd (or bin\setenv2.cmd) which will
:                       allow you to change your existing settings and
:                       create a new mysetenv.cmd.
:
: Note         : Using these environment files avoids the need to edit your
:                CONFIG.SYS. Because paths were altered by prepending the
:                here configured parts, it is possible to have the C compiler
:                and the Toolkit properly installed as well.
:
: Usage        : 1) Open a VIO window or an EPM shell in the main project
:                   directory.
:
:                2) Execute
:
:                      setenv
:                      nmake [/nologo] [clean] all
:
:                   Instead of "all" you can also specify "inst" to start
:                   WarpIN after compilation.
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
:
: ---------------------------------------------------------------------------
: Begin of user-configurable part
: ---------------------------------------------------------------------------
:
: While you may configure this file manually, you may find it easier to:
:   1) SET USED_COMPILER=abc
: which is invalid, and then
:   2) Run either bin\setenv.cmd or bin\setenv2.cmd
: Running either \bin\setenv*.cmd with an invalid, required setting will
: result in you being guided through a rebuild of this file.
:
: ---------------------------------------------------------------------------
: End of user-configurable part
: ---------------------------------------------------------------------------

SET USER_SETENV_COMPLETE=1

:----------------
:
: ---- Execute appropriate the environment file
:
: Normal processing
IF EXIST .\bin\setenv2.cmd CALL .\bin\setenv2.cmd & GOTO :END
:
: Must be running from bin dir, run the user-customized version
: of this file, if any
IF EXIST ..\mysetenv.cmd cd .. & CALL mysetenv.cmd & GOTO :END
:
: Must be running from bin dir and there is no user-customized version so
: run setenv2 to prompt user to create a user-customized version of this file.
IF EXIST .\setenv2.cmd CALL .\setenv2.cmd & GOTO :END
:
cls
ECHO.
ECHO Error 1: This cmd file should not be executed directly.
ECHO.
ECHO Error 2: This cmd file was unable to find its companion program: SETENV2.CMD.
ECHO    Check to make sure you have the complete 'bin' directory from the CVS
ECHO    repository.
ECHO.
:
:END
