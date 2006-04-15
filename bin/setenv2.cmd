@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: setenv2.cmd
:
: Set the environment for the making of NEPMD
: Derived from Christian Langanke's TOOLENV package
:
: Usage: This file is intended to be called by setenv.cmd only.
:        setenv.cmd has to be copied to the main project dir and configured
:        first.
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: setenv2.cmd,v 1.1 2006-04-15 18:28:40 aschn Exp $
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
: ---- Check presence of env vars and validate dirs
IF .%USED_COMPILER%==. ECHO Error: This file should be called by setenv.cmd only&GOTO :END
IF NOT EXIST %DIR_COMPILER% ECHO Error: directory %DIR_COMPILER% doesn't exist&GOTO :END
IF NOT EXIST %DIR_TOOLKIT% ECHO Error: directory %DIR_TOOLKIT% doesn't exist&GOTO :END
GOTO :%USED_COMPILER%
GOTO :END


:VAC308
: ---------------------------------------------------------------------------
 IF '%FLAG_COMPILER%'=='1' GOTO :COMPILERALREADYSET
 SET FLAG_COMPILER=1
 ECHO Setting environment for VAC308 in %DIR_COMPILER%
:
: DEVICE=%DIR_COMPILER%\SYS\CPPOPA3.SYS
: LIBPATH=%DIR_COMPILER%\DLL;%DIR_COMPILER%\DLL;%DIR_COMPILER%\SAMPLES\TOOLKIT\DLL;
: SET THREADS=512
: SET IWFOPT=%DIR_COMPILER%
 SET BEGINLIBPATH=%DIR_COMPILER%\DLL;%BEGINLIBPATH%
 SET ICC_INCLUDE=%DIR_COMPILER%\INCLUDE
:
 SET PATH=%DIR_COMPILER%\BIN;%DIR_COMPILER%\SMARTS\SCRIPTS;%DIR_COMPILER%\HELP;%PATH%;
 SET DPATH=%DIR_COMPILER%\HELP;%DIR_COMPILER%;%DIR_COMPILER%\LOCALE;%DIR_COMPILER%\MACROS;%DIR_COMPILER%\BND;%DPATH%;
 SET HELP=%DIR_COMPILER%\HELP;%DIR_COMPILER%\SAMPLES\TOOLKIT\HELP;%HELP%;
 SET BOOKSHELF=%DIR_COMPILER%\HELP;%BOOKSHELF%;
: SET SOMIR=%DIR_COMPILER%\ETC\SOM.IR;%SOMIR%;
 SET CPPHELP_INI=C:\OS2\SYSTEM
 SET LOCPATH=%DIR_COMPILER%\LOCALE;%LOCPATH%;
 SET INCLUDE=%DIR_COMPILER%\IDATAINC;%DIR_COMPILER%\INCLUDE;%DIR_COMPILER%\INCLUDE\OS2;%DIR_COMPILER%\INC;%INCLUDE%
: SET SMINCLUDE=%DIR_COMPILER%\IDATAINC;%DIR_COMPILER%\INCLUDE\OS2;%DIR_COMPILER%\INCLUDE;%SMINCLUDE%;
 SET VBPATH=.;%DIR_COMPILER%\DDE4VB;%VBPATH%;
 SET TMPDIR=%TMP%
 SET LXEVFREF=EVFELREF.INF+LPXCREF.INF
 SET LXEVFHDI=EVFELHDI.INF+LPEXHDI.INF
 SET LPATH=%DIR_COMPILER%\MACROS;%LPATH%;
 SET CODELPATH=%DIR_COMPILER%\CODE\MACROS;%DIR_COMPILER%\MACROS;%LPATH%;
 SET CLREF=CPPCLRF.INF+CPPDAT.INF+CPPAPP.INF+CPPWIN.INF+CPPCTL.INF+CPPADV.INF+CPP2DG.INF+CPPDDE.INF+CPPDM.INF+CPPMM.INF+CPPCLRB.INF
: SET IPFC=%DIR_COMPILER%\IPFC
 SET LIB=%DIR_COMPILER%\LIB;%DIR_COMPILER%\DLL;%LIB%
: SET SOMRUNTIME=%DIR_COMPILER%\DLL
 SET CPREF=CP1.INF+CP2.INF+CP3.INF
 SET GPIREF=GPI1.INF+GPI2.INF+GPI3.INF
 SET PMREF=PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF
 SET WPSREF=WPS1.INF+WPS2.INF+WPS3.INF
 SET MMREF=MMREF1.INF+MMREF2.INF+MMREF3.INF
: SET SMADDSTAR=1
: SET SMEMIT=h;ih;c
: SET SOMBASE=%DIR_COMPILER%
: SET SMTMP=%TMP%
: SET SMCLASSES=WPTYPES.IDL
 SET HELPNDX=EPMKWHLP.NDX+CPP.NDX+CPPBRS.NDX+%HELPNDX%
 SET CPPLOCAL=C:\IBMCPP
 SET CPPMAIN=%DIR_COMPILER%
 SET CPPWORK=%DIR_COMPILER%
 SET IWF.DEFAULT_PRJ=CPPDFTPRJ
 SET IWF.SOLUTION_LANG_SUPPORT=CPPIBS30;ENG
 SET IPF_KEYS=SHOWNAV+%IPF_KEYS%
 SET VACPP_SHARED=FALSE
 SET IWFHELP=IWFHDI.INF
 SET PMDEXCEPT=1
:
 GOTO :TOOLKIT
: ---------------------------------------------------------------------------


:CSET2
: ---------------------------------------------------------------------------
 IF '%FLAG_COMPILER%'=='1' GOTO :COMPILERALREADYSET
 SET FLAG_COMPILER=1
 ECHO Setting environment for CSET2 in %DIR_COMPILER%
:
: DEVICE=%DIR_COMPILER%\DDE4XTRA.SYS
: LIBPATH=%DIR_COMPILER%\DLL;
 SET BEGINLIBPATH=%DIR_COMPILER%\DLL;%BEGINLIBPATH%
:
 SET PATH=%DIR_COMPILER%\BIN;%PATH%
 SET DPATH=X:\;%DIR_COMPILER%\LOCALE;%DIR_COMPILER%\HELP;%DIR_COMPILER%\SYS;%DPATH%
 SET LIB=%DIR_COMPILER%\LIB;%LIB%
 SET INCLUDE=%DIR_COMPILER%\INCLUDE;%DIR_COMPILER%\IBMCLASS;%INCLUDE%
 SET HELP=%DIR_COMPILER%\HELP;%HELP%
 SET BOOKSHELF=%DIR_COMPILER%\HELP;%BOOKSHELF%
 SET HELPNDX=DDE4LRM.NDX+DDE4SCL.NDX+DDE4CLIB.NDX+DDE4CCL.NDX+DDE4UIL.NDX+%HELPNDX%
 SET ICC_INCLUDE=%DIR_COMPILER%\INCLUDE
 SET PMDEXCEPT=1
:
 GOTO :TOOLKIT
: ---------------------------------------------------------------------------


:COMPILERALREADYSET
: ---------------------------------------------------------------------------
 ECHO Environment for C compiler already set
 GOTO :TOOLKIT
: ---------------------------------------------------------------------------


:TOOLKIT
: ---------------------------------------------------------------------------
: Extend the environment for the toolkit after the compiler because in most
: cases toolkit files are more recent.
 IF '%FLAG_TOOLKIT%'=='1' GOTO :TOOLKITALREADYSET
 SET FLAG_TOOLKIT=1
 ECHO Setting environment for IBM Developer's Toolkit in %DIR_TOOLKIT%
:
: LIBPATH=%LIBPATH%%DIR_TOOLKIT%\DLL;
 SET PATH=%DIR_TOOLKIT%\BIN;%PATH%
 SET DPATH=%DIR_TOOLKIT%\MSG;%DIR_TOOLKIT%\BOOK;%DPATH%
 SET HELP=%DIR_TOOLKIT%\HELP;%HELP%
 SET BOOKSHELF=%BOOKSHELF%;%DIR_TOOLKIT%\BOOK;
:
 SET PROGREF=CP1.INF+CP2.INF+CP3.INF
 SET CPREF=%PROGREF%
 SET GPIREF=GPI1.INF+GPI2.INF+GPI3.INF
 SET PMREF=PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF
 SET WPSREF=WPS1.INF+WPS2.INF+WPS3.INF
 SET TCPREF=TCPPR
 SET HELPNDX=EPMKWHLP.NDX+DTYPES.NDX+%HELPNDX%
 SET IPFC=%DIR_TOOLKIT%\IPFC;
:
 SET INCLUDE=%DIR_TOOLKIT%\H;%INCLUDE%;%DIR_TOOLKIT%\IDL;
 SET LIB=%DIR_TOOLKIT%\LIB;%LIB%
:
: -- some GNU definitions
 SET C_INCLUDE_PATH=%C_INCLUDE_PATH%;%DIR_TOOLKIT%\H;%DIR_TOOLKIT45%\IDL;
 SET LIBRARY_PATH=%LIBRARY_PATH%;%DIR_TOOLKIT%\LIB;
:
: -- set SOM definitions
 SET SOMBASE=%DIR_TOOLKIT%\SOM
 SET SOMIR=%SOMBASE%\COMMON\SOM.IR;SOM.IR
 SET SMINCLUDE=.;%SOMBASE%\INCLUDE;
 SET SMTMP=%TMP%
 SET INCLUDE=.;%SOMBASE%\INCLUDE;%INCLUDE%
 SET PATH=%SOMBASE%\BIN;%PATH%
 SET DPATH=%SOMBASE%\MSG;%DPATH%
 SET LIB=.;%SOMBASE%\LIB;%LIB%
 SET BEGINLIBPATH=%SOMBASE%\LIB;%BEGINLIBPATH%
:
 GOTO :END
: ---------------------------------------------------------------------------


:TOOLKITALREADYSET
: ---------------------------------------------------------------------------
 ECHO Environment for IBM Developer's Toolkit already set
 GOTO :END
: ---------------------------------------------------------------------------


:END
