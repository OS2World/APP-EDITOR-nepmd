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
: $Id: prepare.cmd,v 1.1 2002-04-15 16:37:51 ktk Exp $
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
 pkunzip2 -o %ZIPSRCDIR%\epm603               -d %UNZIPPEDDIR%                 >>%LOGFILE% 2>&1

: --- unpack main application package and distribute to subdirectories
 SET TARGET=%UNZIPPEDDIR%\EPMAPP
 pkunzip2 -o %UNZIPPEDDIR%\epmapp             -d %UNZIPPEDDIR%\EPMAPP\BIN      >>%LOGFILE% 2>&1

 DEL %TARGET%\BIN\README.EPM                                                   >NUL 2>&1
 DEL %TARGET%\BIN\TTITALIC.BMP                                                 >NUL 2>&1
 DEL %TARGET%\BIN\EPMHELP.QHL                                                  >NUL 2>&1

 MD %TARGET%\BIN\BMP                                                           >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                >NUL 2>&1

 MD %TARGET%\BIN\KEYWORDS                                                      >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\EPMKWDS.* %TARGET%\BIN\KEYWORDS                       >NUL 2>&1

 MD %TARGET%\BIN\EX                                                            >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.EX        %TARGET%\BIN\EX                           >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\ACTIONS.LST %TARGET%\BIN\EX                           >NUL 2>&1

 MD %TARGET%\BIN\BAR                                                           >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.BAR %TARGET%\BIN\BAR                                >NUL 2>&1

: --- unpack further main application package components

 pkunzip2 -o %UNZIPPEDDIR%\epmdll  -d %UNZIPPEDDIR%\EPMDLL\DLL                 >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmhlp  -d %UNZIPPEDDIR%\EPMHLP\HELP                >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmbk   -d %UNZIPPEDDIR%\EPMBK\BOOK                 >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmbmps -d %UNZIPPEDDIR%\EPMBMPS\BIN\BMP            >>%LOGFILE% 2>&1

:test

: --- unpack speech support package and distribute to subdirectories

 SET TARGET=%UNZIPPEDDIR%\EPMSPCH
 pkunzip2 -o %UNZIPPEDDIR%\epmspch -d %TARGET%\BIN                             >>%LOGFILE% 2>&1
 DEL %TARGET%\BIN\README.TXT                                                   >NUL 2>&1

 MD %TARGET%\DLL                                                               >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.DLL %TARGET%\DLL                                    >NUL 2>&1

 MD %TARGET%\BIN\MACROS                                                        >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.E   %TARGET%\BIN\MACROS                             >NUL 2>&1

 DEL %TARGET%\BIN\*.551
 MD %TARGET%\BIN\EX                                                            >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.603 %TARGET%\BIN\EX\*.EX                            >NUL 2>&1

 MD %TARGET%\BIN\BMP                                                           >NUL 2>&1
 CALL _MOVE %TARGET%\BIN\*.BMP %TARGET%\BIN\BMP                                >NUL 2>&1

: --- unpack macro packages and distribute to subdirectories

 pkunzip2 -o %UNZIPPEDDIR%\epmmac  -d %UNZIPPEDDIR%\EPMMAC\BIN\MACROS          >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmmac2 -d %UNZIPPEDDIR%\EPMMAC2\BIN\MACROS         >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmsmp  -d %UNZIPPEDDIR%\EPMSMP\MACROS\SAMPLES      >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmasi  -d %UNZIPPEDDIR%\EPMASI\BIN\MACROS\MYASSIST >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\lampdq  -d %UNZIPPEDDIR%\LAMPDQ\BIN\MACROS\LAMPDQ   >>%LOGFILE% 2>&1

 pkunzip2 -o %UNZIPPEDDIR%\ebooke  -d %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE   >>%LOGFILE% 2>&1
 DEL %UNZIPPEDDIR%\EBOOKE\BIN\MACROS\EBOOKE\READ.ME

: --- unpack sample packages and distribute to subdirectories

 pkunzip2 -o %UNZIPPEDDIR%\epmatr   -d %UNZIPPEDDIR%\EPMATR\SAMPLES\ATTR       >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmdde   -d %UNZIPPEDDIR%\EPMDDE\SAMPLES\DDE        >>%LOGFILE% 2>&1
 pkunzip2 -o %UNZIPPEDDIR%\epmrex   -d %UNZIPPEDDIR%\EPMREX\SAMPLES\REXX       >>%LOGFILE% 2>&1

 pkunzip2 -o %UNZIPPEDDIR%\epmcsamp -d %UNZIPPEDDIR%\EPMCSAMP\SAMPLES          >>%LOGFILE% 2>&1

 REN %UNZIPPEDDIR%\EPMCSAMP\SAMPLES\EPMCSAMP C                                 >>%LOGFILE% 2>&1

: --- cleanup here

 DEL %UNZIPPEDDIR%\* /N                                                        >>%LOGFILE% 2>&1

: --- apply update

 ECHO - unpack EPM 6.03b update files
 unzip -o  %ZIPSRCDIR%\epm603b   -d %UNZIPPEDDIR%\update                       >>%LOGFILE% 2>&1

 ECHO - updating package
 replace %UNZIPPEDDIR%\update\* %UNZIPPEDDIR% /U /S                            >%UNZIPPEDDIR%\update.log 2>&1


: --- save logfile and remove R/O atttributes

 COPY %LOGFILE% %UNZIPPEDDIR%                                                  >NUL 2>&1
 ATTRIB -r %UNZIPPEDDIR%\* /S

:end

