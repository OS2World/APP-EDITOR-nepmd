@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: prepare.cmd logfile baseurl zip_srcdir unzipped_dir
:
: Script for to
:    - download the EPM packages from www.leo.org
:    - and to create the package source directories
:
: Copyright (c) Netlabs EPM Distribution 2002
:
: $Id: prepare.cmd,v 1.3 2002-06-12 14:18:04 cla Exp $
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
 GOTO end


: ---------- unpack files and apply update
:unpack

: --- exit with errors

 SET CHECKERROR=IF ERRORLEVEL 2 GOTO end

: --- cleanup directory and logfile

 ECHO - cleanup directory %UNZIPPEDDIR%
 IF EXIST %UNZIPPEDDIR% CALL KD %UNZIPPEDDIR%                                  >NUL 2>&1
 MD %UNZIPPEDDIR% >NUL 2>&1

 IF EXIST %LOGFILE%  DEL %LOGFILE%                                             >NUL 2>&1

: --- unpack package zip files
 ECHO - unpack EPM 6.03 packages
 %UNZ% %ZIPSRCDIR%\epm603               %UNZIPPEDDIR%                          >>%LOGFILE% 2>&1
 %CHECKERROR%

: --- unpack main application package and distribute to subdirectories
 SET TARGET=%UNZIPPEDDIR%\EPMAPP
 %UNZ% %UNZIPPEDDIR%\epmapp             %UNZIPPEDDIR%\EPMAPP\BIN               >>%LOGFILE% 2>&1
 %CHECKERROR%

 DEL %TARGET%\BIN\README.EPM                                                   >>%LOGFILE% 2>&1
 %CHECKERROR%
 DEL %TARGET%\BIN\TTITALIC.BMP                                                 >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\BMP                                                           >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                     >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\KEYWORDS                                                      >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\EPMKWDS.* %TARGET%\BIN\KEYWORDS                            >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\EX                                                            >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.EX        %TARGET%\BIN\EX                                >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\ACTIONS.LST %TARGET%\BIN\EX                                >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\BAR                                                           >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.BAR %TARGET%\BIN\BAR                                     >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\NDX                                                           >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.NDX %TARGET%\BIN\NDX                                     >>%LOGFILE% 2>&1
 %CHECKERROR%

: --- unpack further main application package components

 %UNZ% %UNZIPPEDDIR%\epmdll  %UNZIPPEDDIR%\EPMDLL\DLL                          >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmhlp  %UNZIPPEDDIR%\EPMHLP\HELP                         >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmbk   %UNZIPPEDDIR%\EPMBK\BOOK                          >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmbmps %UNZIPPEDDIR%\EPMBMPS\BIN\BMP                     >>%LOGFILE% 2>&1
 %CHECKERROR%

: --- unpack speech support package and distribute to subdirectories

 SET TARGET=%UNZIPPEDDIR%\EPMSPCH
 %UNZ% %UNZIPPEDDIR%\epmspch   %TARGET%\BIN                                    >>%LOGFILE% 2>&1
 %CHECKERROR%
 DEL %TARGET%\BIN\README.TXT                                                   >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\DLL                                                               >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.DLL %TARGET%\DLL                                         >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\MACROS                                                        >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.E   %TARGET%\BIN\MACROS                                  >>%LOGFILE% 2>&1
 %CHECKERROR%

 DEL %TARGET%\BIN\*.551                                                        >>%LOGFILE% 2>&1
 %CHECKERROR%
 MD %TARGET%\BIN\EX                                                            >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.603 %TARGET%\BIN\EX\*.EX                                 >>%LOGFILE% 2>&1
 %CHECKERROR%

 MD %TARGET%\BIN\BMP                                                           >>%LOGFILE% 2>&1
 %CHECKERROR%
 %MOV% %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                     >>%LOGFILE% 2>&1
 %CHECKERROR%

: --- unpack macro packages and distribute to subdirectories

 %UNZ% %UNZIPPEDDIR%\epmmac  %UNZIPPEDDIR%\EPMMAC\BIN\MACROS                   >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmmac2 %UNZIPPEDDIR%\EPMMAC2\BIN\MACROS                  >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmsmp  %UNZIPPEDDIR%\EPMSMP\BIN\MACROS\SAMPLES           >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmatr   %UNZIPPEDDIR%\EPMATR\BIN\MACROS\ATTR             >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmasi  %UNZIPPEDDIR%\EPMASI\BIN\MACROS\MYASSIST          >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\lampdq  %UNZIPPEDDIR%\LAMPDQ\BIN\MACROS\LAMPDQ            >>%LOGFILE% 2>&1
 %CHECKERROR%

 %UNZ% %UNZIPPEDDIR%\ebooke  %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE            >>%LOGFILE% 2>&1
 %CHECKERROR%
 DEL %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE\READ.ME
 %CHECKERROR%

: --- unpack sample packages and distribute to subdirectories

 %UNZ% %UNZIPPEDDIR%\epmdde   %UNZIPPEDDIR%\EPMDDE\SAMPLES\DDE                 >>%LOGFILE% 2>&1
 %CHECKERROR%
 %UNZ% %UNZIPPEDDIR%\epmrex   %UNZIPPEDDIR%\EPMREX\SAMPLES\REXX                >>%LOGFILE% 2>&1
 %CHECKERROR%

 %UNZ% %UNZIPPEDDIR%\epmcsamp %UNZIPPEDDIR%\EPMCSAMP\SAMPLES                   >>%LOGFILE% 2>&1
 %CHECKERROR%

 REN %UNZIPPEDDIR%\EPMCSAMP\SAMPLES\EPMCSAMP C                                 >>%LOGFILE% 2>&1
 %CHECKERROR%

: --- cleanup here

 DEL %UNZIPPEDDIR%\*.ZIP /N                                                    >>%LOGFILE% 2>&1

: --- apply update

 ECHO - unpack EPM 6.03b update files
 unzip -o  %ZIPSRCDIR%\epm603b -d %UNZIPPEDDIR%\update                         >>%LOGFILE% 2>&1
 %CHECKERROR%

 ECHO - apply update
 replace %UNZIPPEDDIR%\update\* %UNZIPPEDDIR% /U /S                            >%UNZIPPEDDIR%\update.log 2>&1

: --- remove R/O atttributes on all files

 ECHO - remove R/O attributes
 ATTRIB -r %UNZIPPEDDIR%\* /S

: --- make all files lowercase names

 ECHO - lowercase names od directories files
 LT %UNZIPPEDDIR%

:end
