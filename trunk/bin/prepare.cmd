@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: prepare.cmd logfile baseurl zip_srcdir unzipped_dir
:
: Script for to
:    - download the EPM packages from www.leo.org
:    - and to create the package source directories
:
: Call from makefile either with
:   make all          or
:   make prepare
:
: See readme.txt for requirements !
:
: Copyright (c) Netlabs EPM Distribution 2002
:
: $Id: prepare.cmd,v 1.7 2002-04-16 21:22:23 cla Exp $
:
: ===========================================================================
:
: This file is part of the Netlabs EPM Distribution package and is free
: software.  You can redistribute it and/or modify it under the terms of the
: GNU Library General Public License as published by the Free Software
: Foundation, in version 2 as it comes in the "COPYING.LIB" file of the WPS
: Toolkit main distribution.  This library is distributed in the hope that it
: will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
: of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
: Library General Public License for more details.
:
: **************************************************************************/

 SETLOCAL
 SET PATH=bin;%PATH%
 SET UNZ=CALL _UNPACK
 SET MOV=CALL _MOVE

 SET LOGFILE=%1
 SET BASEURL=%2
 SET ZIPSRCDIR=%3
 SET UNZIPPEDDIR=%4
 IF NOT .%4 == . GOTO parmok
 ECHO.
 ECHO call this batch from within makefile only !
 ECHO.
 PAUSE
 GOTO end

:parmok
: ---------- check for package files from LEO

 MD %ZIPSRCDIR%   >NUL 2>&1
 MD %UNZIPPEDDIR% >NUL 2>&1

 SET CHECK=epm603.zip
 IF NOT EXIST %ZIPSRCDIR%\%CHECK% wget -P %ZIPSRCDIR% %WGETOPTS% %BASEURL%/%CHECK%
 IF ERRORLEVEL 1 GOTO geterror

 SET CHECK=epm603b.zip
 IF NOT EXIST %ZIPSRCDIR%\%CHECK% wget -P %ZIPSRCDIR% %WGETOPTS% %BASEURL%/%CHECK%
 IF ERRORLEVEL 1 GOTO geterror

 GOTO unpack

:geterror
 ECHO.
 ECHO Error: could not wget %CHECK%...
 PAUSE
 GOTO end


: ---------- unpack files and apply update
:unpack

 IF EXIST %LOGFILE%  DEL %LOGFILE%                                             >NUL 2>&1

: --- unpack package zip files
 ECHO - unpack EPM 6.03 packages
 %UNZ% %ZIPSRCDIR%\epm603               %UNZIPPEDDIR%                          >>%LOGFILE% 2>&1

: --- unpack main application package and distribute to subdirectories
 SET TARGET=%UNZIPPEDDIR%\EPMAPP
 %UNZ% %UNZIPPEDDIR%\epmapp             %UNZIPPEDDIR%\EPMAPP\BIN               >>%LOGFILE% 2>&1

 DEL %TARGET%\BIN\README.EPM                                                   >>%LOGFILE% 2>&1
 DEL %TARGET%\BIN\TTITALIC.BMP                                                 >>%LOGFILE% 2>&1
 DEL %TARGET%\BIN\EPMHELP.QHL                                                  >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\BMP                                                           >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                     >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\KEYWORDS                                                      >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\EPMKWDS.* %TARGET%\BIN\KEYWORDS                            >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\EX                                                            >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.EX        %TARGET%\BIN\EX                                >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\ACTIONS.LST %TARGET%\BIN\EX                                >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\BAR                                                           >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.BAR %TARGET%\BIN\BAR                                     >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\NDX                                                           >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.NDX %TARGET%\BIN\NDX                                     >>%LOGFILE% 2>&1

: --- unpack further main application package components

 %UNZ% %UNZIPPEDDIR%\epmdll  %UNZIPPEDDIR%\EPMDLL\DLL                          >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmhlp  %UNZIPPEDDIR%\EPMHLP\HELP                         >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmbk   %UNZIPPEDDIR%\EPMBK\BOOK                          >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmbmps %UNZIPPEDDIR%\EPMBMPS\BIN\BMP                     >>%LOGFILE% 2>&1

: --- unpack speech support package and distribute to subdirectories

 SET TARGET=%UNZIPPEDDIR%\EPMSPCH
 %UNZ% %UNZIPPEDDIR%\epmspch   %TARGET%\BIN                                    >>%LOGFILE% 2>&1
 DEL %TARGET%\BIN\README.TXT                                                   >>%LOGFILE% 2>&1

 MD %TARGET%\DLL                                                               >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.DLL %TARGET%\DLL                                         >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\MACROS                                                        >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.E   %TARGET%\BIN\MACROS                                  >>%LOGFILE% 2>&1

 DEL %TARGET%\BIN\*.551                                                        >>%LOGFILE% 2>&1
 MD %TARGET%\BIN\EX                                                            >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.603 %TARGET%\BIN\EX\*.EX                                 >>%LOGFILE% 2>&1

 MD %TARGET%\BIN\BMP                                                           >>%LOGFILE% 2>&1
 %MOV% %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                     >>%LOGFILE% 2>&1

: --- unpack macro packages and distribute to subdirectories

 %UNZ% %UNZIPPEDDIR%\epmmac  %UNZIPPEDDIR%\EPMMAC\BIN\MACROS                   >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmmac2 %UNZIPPEDDIR%\EPMMAC2\BIN\MACROS                  >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmsmp  %UNZIPPEDDIR%\EPMSMP\BIN\MACROS\SAMPLES           >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmasi  %UNZIPPEDDIR%\EPMASI\BIN\MACROS\MYASSIST          >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\lampdq  %UNZIPPEDDIR%\LAMPDQ\BIN\MACROS\LAMPDQ            >>%LOGFILE% 2>&1

 %UNZ% %UNZIPPEDDIR%\ebooke  %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE            >>%LOGFILE% 2>&1
 DEL %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE\READ.ME

: --- unpack sample packages and distribute to subdirectories

 %UNZ% %UNZIPPEDDIR%\epmatr   %UNZIPPEDDIR%\EPMATR\SAMPLES\ATTR                >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmdde   %UNZIPPEDDIR%\EPMDDE\SAMPLES\DDE                 >>%LOGFILE% 2>&1
 %UNZ% %UNZIPPEDDIR%\epmrex   %UNZIPPEDDIR%\EPMREX\SAMPLES\REXX                >>%LOGFILE% 2>&1

 %UNZ% %UNZIPPEDDIR%\epmcsamp %UNZIPPEDDIR%\EPMCSAMP\SAMPLES                   >>%LOGFILE% 2>&1

 REN %UNZIPPEDDIR%\EPMCSAMP\SAMPLES\EPMCSAMP C                                 >>%LOGFILE% 2>&1

: --- cleanup here

 DEL %UNZIPPEDDIR%\*.ZIP /N                                                    >>%LOGFILE% 2>&1

: --- apply update

 ECHO - unpack EPM 6.03b update files
 unzip -o  %ZIPSRCDIR%\epm603b -d %UNZIPPEDDIR%\update                         >>%LOGFILE% 2>&1

 ECHO - updating package
 replace %UNZIPPEDDIR%\update\* %UNZIPPEDDIR% /U /S                            >%UNZIPPEDDIR%\update.log 2>&1


: --- remove R/O atttributes

 ATTRIB -r %UNZIPPEDDIR%\* /S

: --- now check for errors in logfile
:
:grep SYS....: %LOGFILE%
:IF ERRORLEVEL 1 GOTO end
:
:ECHO.
:ECHO errors occurred. Press Ctrl-Break to abort or any other key to continue...
:PAUSE > NUL

:end

