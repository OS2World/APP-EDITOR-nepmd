/****************************** Module Header *******************************
*
* Module Name: setenv2.cmd
*
* Set the environment for the making of NEPMD
* Derived from Christian Langanke's TOOLENV package
* Change to REXX and enhanced by John Small
*
* Usage: This file is intended to be called by setenv.cmd in the main project
*        directory. If there is no such file then running this program or
*        bin\setenv.cmd will prompt you to create and configure his own
*        annotated setenv.cmd in the main project directory.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setenv2.cmd,v 1.6 2006-11-09 03:25:34 jbs Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING" file of the
* Netlabs EPM Distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
****************************************************************************/
/*
 * To do
 *    - Improve support for GCC, OpenWatcom and CSET2
 *    - Implement a default NULL value for TOUCH?
 *    - Check w/ Christian about TZ. Needed for ???
 *    - Research SOM settings and correct code, if necessary
 *    - If this file is newer than user's setenv (..\setenv.cmd), then
 *      prompt for replacement of user's setenv?
 */
'@ECHO OFF'
call RxFuncAdd 'SysLoadFuncs', 'REXXUTIL', 'SysLoadFuncs'
call SysLoadFuncs
retval = 0
globals = 'envvar. cfg. compiler. user_directory dir_compiler dir_toolkit tracevar used_compiler'

cfg.env = 'OS2ENVIRONMENT'
tracevar = value('setenvtrc',,cfg.env)
if tracevar == "" then
   tracevar = 'n'
trace value tracevar
call Init
all_required_are_set = GetSettingsFromEnv()
if all_required_are_set == 0 then
   call GetSettingsFromUser

   select
      when envvar.used_compiler.value == 'VAC308' then
         do         /* VAC308 */
            say 'Setting environment for 'compiler.used_compiler.desc' in 'envvar.dir_compiler.value

/*          CONFIG.SYS settings which this code can't handle
            DEVICE=%envvar.dir_compiler.value%\SYS\CPPOPA3.SYS
            SET THREADS=512
*/
            call set 'SET IWFOPT='envvar.dir_compiler.value
/*          LIBPATH=%DIR_COMPILER%\DLL;%DIR_COMPILER%\DLL;%DIR_COMPILER%\SAMPLES\TOOLKIT\DLL; */
/*          SET BEGINLIBPATH=%DIR_COMPILER%\DLL;%BEGINLIBPATH%        */
            call add2env 'BEGINLIBPATH', envvar.dir_compiler.value || '\DLL;' || envvar.dir_compiler.value || '\SAMPLES\TOOLKIT\DLL;'
            call set 'SET ICC_INCLUDE=' || envvar.dir_compiler.value || '\INCLUDE'    /* JBSQ: I don't have this set */
/*          SET PATH=%DIR_COMPILER%\BIN;%DIR_COMPILER%\SMARTS\SCRIPTS;%DIR_COMPILER%\HELP;%PATH%; */
            call add2env 'PATH', envvar.dir_compiler.value || '\BIN;' || envvar.dir_compiler.value || '\SMARTS\SCRIPTS;' || envvar.dir_compiler.value || '\HELP;', 'B'
/*          SET DPATH=%DIR_COMPILER%\HELP;%DIR_COMPILER%;%DIR_COMPILER%\LOCALE;%DIR_COMPILER%\MACROS;%DIR_COMPILER%\BND;%DPATH%; */
            call add2env 'DPATH',  envvar.dir_compiler.value || '\HELP;' || envvar.dir_compiler.value || ';' || envvar.dir_compiler.value || '\LOCALE;' || envvar.dir_compiler.value || '\MACROS;' || envvar.dir_compiler.value || '\BND;', 'B'
/*          SET HELP=%DIR_COMPILER%\HELP;%DIR_COMPILER%\SAMPLES\TOOLKIT\HELP;%HELP%;  */
            call add2env 'HELP',  envvar.dir_compiler.value || '\HELP;' || envvar.dir_compiler.value || '\SAMPLES\TOOLKIT\HELP;', 'B'
/*          SET BOOKSHELF=%DIR_COMPILER%\HELP;%BOOKSHELF%;     */
            call add2env 'BOOKSHELF', envvar.dir_compiler.value || '\HELP;', 'B'
/*          SET CPPHELP_INI=C:\OS2\SYSTEM     JBSQ: 'C:" ??                 */
            call set '@SET CPPHELP_INI=' || cfg.boot_drive || '\OS2\SYSTEM'
/*          SET LOCPATH=%DIR_COMPILER%\LOCALE;%LOCPATH%;       */
            /* JBSQ: Is LOCPATH needed?
               1) eCS install seems to choose to leave it out
               2) According to CONFIGTOOL, it does not seem to be programming related (TCP/IP & WarpServer) */
            /* call add2env 'LOCPATH', envvar.dir_compiler.value || '\LOCALE;', 'B'       */
/*          SET INCLUDE=%DIR_COMPILER%\IDATAINC;%DIR_COMPILER%\INCLUDE;%DIR_COMPILER%\INCLUDE\OS2;%DIR_COMPILER%\INC;%INCLUDE%  */
            call add2env 'INCLUDE', /* envvar.dir_compiler.value || '\IDATAINC;' JBSQ: IDATAINC doesn't exist? || */ envvar.dir_compiler.value || '\INCLUDE;' || envvar.dir_compiler.value || '\INCLUDE\OS2;' || envvar.dir_compiler.value || '\INC;', 'B'
/*          SET VBPATH=.;%DIR_COMPILER%\DDE4VB;%VBPATH%;          */
            call add2env 'VBPATH', '.;' || envvar.dir_compiler.value || '\DDE4VB;', 'B'
/*          'SET LXEVFREF=EVFELREF.INF+LPXCREF.INF'         */
            call add2env 'LXEVFREF', 'EVFELREF.INF+LPXCREF.INF', 'B', '+'
/*          'SET LXEVFHDI=EVFELHDI.INF+LPEXHDI.INF'      */
            call add2env 'LXEVFHDI', 'EVFELHDI.INF+LPEXHDI.INF', 'B', '+'
/*          SET LPATH=%DIR_COMPILER%\MACROS;%LPATH%;        */
            call add2env 'LPATH', envvar.dir_compiler.value || '\MACROS;', 'B'
/*          SET CODELPATH=%DIR_COMPILER%\CODE\MACROS;%DIR_COMPILER%\MACROS;%LPATH%;  JBSQ: I think the first part should be MACROS\CODE */
            call add2env 'CODELPATH', envvar.dir_compiler.value || '\MACROS\CODE;' || envvar.dir_compiler.value || '\MACROS;', 'B'
/*          'SET CLREF=CPPCLRF.INF+CPPDAT.INF+CPPAPP.INF+CPPWIN.INF+CPPCTL.INF+CPPADV.INF+CPP2DG.INF+CPPDDE.INF+CPPDM.INF+CPPMM.INF+CPPCLRB.INF'  */
            call add2env 'CLREF', 'CPPCLRF.INF+CPPDAT.INF+CPPAPP.INF+CPPWIN.INF+CPPCTL.INF+CPPADV.INF+CPP2DG.INF+CPPDDE.INF+CPPDM.INF+CPPMM.INF+CPPCLRB.INF', 'B', '+'
/*          SET LIB=%DIR_COMPILER%\LIB;%DIR_COMPILER%\DLL;%LIB%        */
            call add2env 'LIB', envvar.dir_compiler.value || '\LIB;' || envvar.dir_compiler.value || '\DLL;', 'B'
/*          'SET CPREF=CP1.INF+CP2.INF+CP3.INF'            */
            call add2env 'CPREF', 'CP1.INF+CP2.INF+CP3.INF', 'B', '+'
/*          'SET GPIREF=GPI1.INF+GPI2.INF+GPI3.INF'               */
            call add2env 'GPIREF', 'GPI1.INF+GPI2.INF+GPI3.INF', 'B', '+'
/*          'SET PMREF=PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF'       */
            call add2env 'PMREF', 'PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF', 'B', '+'
/*          'SET WPSREF=WPS1.INF+WPS2.INF+WPS3.INF'      */
            call add2env 'WPSREF', 'WPS1.INF+WPS2.INF+WPS3.INF', 'B', '+'
/*          'SET MMREF=MMREF1.INF+MMREF2.INF+MMREF3.INF'       */
            call add2env 'MMREF', 'MMREF1.INF+MMREF2.INF+MMREF3.INF', 'B', '+'
/*          'SET HELPNDX=EPMKWHLP.NDX+CPP.NDX+CPPBRS.NDX+%HELPNDX%     */
            call add2env 'HELPNDX', 'EPMKWHLP.NDX+CPP.NDX+CPPBRS.NDX', 'B', '+'
/*          SET CPPLOCAL=C:\IBMCPP       JBSQ: 'C:' ??         */
            call set 'SET CPPLOCAL='envvar.dir_compiler.value
            call set 'SET CPPMAIN='envvar.dir_compiler.value
            call set 'SET CPPWORK='envvar.dir_compiler.value
            call set 'SET IWF.DEFAULT_PRJ=CPPDFTPRJ'
            call set 'SET IWF.SOLUTION_LANG_SUPPORT=CPPIBS30;ENG'
/*          SET IPF_KEYS=SHOWNAV+%IPF_KEYS%                 */
            call add2env 'IPF_KEYS', 'SHOWNAV', 'B', '+'
            call set 'SET VACPP_SHARED=FALSE'
            call set 'SET IWFHELP=IWFHDI.INF'
            call set 'SET PMDEXCEPT=1'
/* : SET SMINCLUDE=%DIR_COMPILER%\IDATAINC;%DIR_COMPILER%\INCLUDE\OS2;%DIR_COMPILER%\INCLUDE;%SMINCLUDE%; */
/*          SET SOMIR=%DIR_COMPILER%\ETC\SOM.IR;%SOMIR%;       */
            call add2env 'SOMIR', envvar.dir_compiler.value || '\ETC\SOM.IR', 'B'
         end
      when envvar.used_compiler.value == 'CSET2' then
         do
            /* CSET2 */
/*          ECHO Setting environment for CSET2 in %DIR_COMPILER%     */
            say 'Setting environment for 'compiler.used_compiler.desc' in 'envvar.dir_compiler.value

/*          CONFIG.SYS settings which this code can't handle
            DEVICE=%DIR_COMPILER%\DDE4XTRA.SYS
*/
/*          : LIBPATH=%DIR_COMPILER%\DLL;
            SET BEGINLIBPATH=%DIR_COMPILER%\DLL;%BEGINLIBPATH%      */
            call add2env 'BEGINLIBPATH', envvar.dir_compiler.value || '\DLL;'
/*          SET PATH=%DIR_COMPILER%\BIN;%PATH%                   */
            call add2env 'PATH', envvar.dir_compiler.value || '\BIN;', 'B'
/*          SET DPATH=X:\;%DIR_COMPILER%\LOCALE;%DIR_COMPILER%\HELP;%DIR_COMPILER%\SYS;%DPATH%  */
            call add2env 'DPATH', /* X:\;  JBSQ: 'X:' ??? */ envvar.dir_compiler.value || '\LOCALE;' || envvar.dir_compiler.value || '\HELP;' || envvar.dir_compiler.value || '\SYS;', 'B'
/*          SET LIB=%DIR_COMPILER%\LIB;%LIB%             */
            call add2env 'LIB', envvar.dir_compiler.value || '\LIB;'
/*          SET INCLUDE=%DIR_COMPILER%\INCLUDE;%DIR_COMPILER%\IBMCLASS;%INCLUDE%      */
            call add2env 'INCLUDE', envvar.dir_compiler.value || '\INCLUDE;' || envvar.dir_compiler.value || '\IBMCLASS;', 'B'
/*          SET HELP=%DIR_COMPILER%\HELP;%HELP%                */
            call add2env 'HELP', envvar.dir_compiler.value || '\HELP;', 'B'
/*          SET BOOKSHELF=%DIR_COMPILER%\HELP;%BOOKSHELF%      */
            call add2env 'BOOKSHELF', envvar.dir_compiler.value || '\HELP;', 'B'
/*          SET HELPNDX=DDE4LRM.NDX+DDE4SCL.NDX+DDE4CLIB.NDX+DDE4CCL.NDX+DDE4UIL.NDX+%HELPNDX%      */
            call add2env 'HELPNDX', 'DDE4LRM.NDX+DDE4SCL.NDX+DDE4CLIB.NDX+DDE4CCL.NDX+DDE4UIL.NDX', 'B', '+'
            call set 'SET ICC_INCLUDE=' || envvar.dir_compiler.value || '\INCLUDE'
            call set 'SET PMDEXCEPT=1'      /* JBSQ: What is this for? I don't have it */
         end
      when envvar.used_compiler.value = 'GCC' then
         do
            say 'Setting environment for 'compiler.used_compiler.desc' in 'envvar.dir_compiler.value
            /*    some GNU definitions       */
/*          SET C_INCLUDE_PATH=%C_INCLUDE_PATH%;%DIR_TOOLKIT%\H;%DIR_TOOLKIT45%\IDL;   */
            call add2env 'C_INCLUDE_PATH', translate(dir_toolkit '\H;' || dir_toolkit /* 45 ?? */ || '\IDL;'. '/', '\')
/*          SET LIBRARY_PATH=%LIBRARY_PATH%;%DIR_TOOLKIT%\LIB;          */
            call add2env 'LIBRARY_PATH', translate(dir_toolkit || '\LIB;', '/', '\')
/*
 * from emxenv:
 * REM **********  GCC ***************
REM To develop programs on a drive different from the drive where emx is installed, you have to set the C_INCLUDE_PATH and LIBRARY_PATH environment variables
rem This is added in case it is needed for specific projects therefore it is shown but mostly is not needed
SET C_INCLUDE_PATH=%UNIXROOT%/emx/lib/gcc-lib/i386-pc-os2-emx/3.2.1/include;%UNIXROOT%/emx/include/cpp;%UNIXROOT%/emx/include;
SET LIBRARY_PATH=%UNIXROOT%/emx/lib;
REM To compile C++ programs, set CPLUS_INCLUDE_PATH
SET CPLUS_INCLUDE_PATH=%UNIXROOT%/emx/include/c++/3.2.1;%UNIXROOT%/emx/lib/gcc-lib/i386-pc-os2-emx/3.2.1/include;%UNIXROOT%/emx/include;
SET EMXOMFLD_LINKER=D:/IBMCPP/BIN/ILINK.EXE -NOFREE
REM To compile programs written in the Objective C language, set OBJC_INCLUDE_PATH as well:
set OBJC_INCLUDE_PATH=%UNIXROOT%/emx/include
REM Speeding up compilation
REM    To keep GCC in memory for 5 minutes, use
REM    set GCCLOAD=5
SET GCCLOAD=5
REM    To make GCC use pipes instead of temporary files under OS/2, use
REM    set GCCOPT=-pipe
SET GCCOPT=-pipe
REM SET AUTOCONF=/usr/share/autoconf
SET CONFIG_SITE=/emx/etc/unixos2/config.site
REM **********  GCC ***************

   from setgcc:
SET PATH=F:\emx\bin;%PATH%
SET BEGINLIBPATH=F:\emx\dll;%BEGINLIBPATH%
rem This is added in case it is needed for specific projects therefore it is shown but mostly is not needed
SET C_INCLUDE_PATH=F:/emx/lib/gcc-lib/i386-pc-os2-emx/3.2.1/include;F:emx/include;
SET CPLUS_INCLUDE_PATH=F:/emx/include/c++/3.2.1;F:/emx/lib/gcc-lib/i386-pc-os2-emx/3.2.1/include;F:/include;
SET LIBRARY_PATH=F:/emx/lib;
SET GCCLOAD=5
SET GCCOPT=-pipe
SET EMXOPT=-c -n -h256
SET TERMCAP=F:/emx/etc/termcap.dat
rem SET TERM=ansi-color-3
SET TERM=os2
SET INFOPATH=F:/emx/info
SET EMXBOOK=emxdev.inf+emxlib.inf+emxgnu.inf+emxbsd.inf
SET BOOKSHELF=F:\emx\book;%BOOKSHELF%
SET HELPNDX=%HELPNDX%+emxbook.ndx
SET DPATH=F:\emx\book;%DPATH%

 */
         end
      when envvar.used_compiler.value = 'OW13' then
         do
            say 'Setting environment for 'compiler.used_compiler.desc' in 'envvar.dir_compiler.value
            call set 'SET WATCOM='envvar.dir_compiler.value
            call add2env 'PATH', envvar.dir_compiler.value || '\BINP;' || envvar.dir_compiler.value || '\BINW;','B'
            call add2env 'BEGINLIBPATH', envvar.dir_compiler.value || '\BINP;'
            call set 'SET EDPATH=%WATCOM%\EDDAT'
/*    SET INCLUDE=%WATCOM%\H;%WATCOM%\H\OS2      JBSQ: Ignore previous INCLUDE??? */
            call add2env 'INCLUDE', envvar.dir_compiler.value || '\H;' || envvar.dir_compiler.value || '\H\OS2;', 'B'
            call add2env 'HELP', envvar.dir_compiler.value || '\BINP\HELP;','B'
            call add2env 'BOOKSHELF', envvar.dir_compiler.value || '\BINP\HELP;','B'
            call set 'SET FINCLUDE='envvar.dir_compiler.value'\SRC\FORTRAN'
         end

      otherwise
         do
            say
            say 'Invalid setting for USED_COMPILER: 'envvar.used_compiler.value
            say 'Exiting...'
            retval = 4
            signal exitcode
         end
   end


   do
/*    TOOLKIT
: ---------------------------------------------------------------------------
: Extend the environment for the toolkit after the compiler because in most
: cases toolkit files are more recent.
*/
/*    ECHO Setting environment for IBM Developer's Toolkit in %DIR_TOOLKIT%  */
      say 'Setting environment for IBM Developer''s Toolkit in 'envvar.dir_toolkit.value
/*    LIBPATH=%LIBPATH%%DIR_TOOLKIT%\DLL;              */
      call add2env 'BEGINLIBPATH', envvar.dir_toolkit.value || '\DLL;'
/*    SET PATH=%DIR_TOOLKIT%\BIN;%PATH%         */
      call add2env 'PATH', envvar.dir_toolkit.value || '\BIN;', 'B'
/*    SET DPATH=%DIR_TOOLKIT%\MSG;%DIR_TOOLKIT%\BOOK;%DPATH%    JBS: Why BOOK?  */
      call add2env 'DPATH', envvar.dir_toolkit.value || '\MSG;' || envvar.dir_toolkit.value || '\BOOK;'
/*    SET HELP=%DIR_TOOLKIT%\HELP;%HELP%        */
      call add2env 'HELP', envvar.dir_toolkit.value || '\HELP;', 'B'
/*    SET BOOKSHELF=%BOOKSHELF%;%DIR_TOOLKIT%\BOOK;     */
      call add2env 'BOOKSHELF', envvar.dir_toolkit.value || '\BOOK;'
/*    'SET PROGREF=CP1.INF+CP2.INF+CP3.INF'        */
      call add2env 'CPREF', 'CP1.INF+CP2.INF+CP3.INF', 'B', '+'
      call set 'SET PROGREF=%CPREF%'                          /* JBSQ: What is this? */
/*    'SET GPIREF=GPI1.INF+GPI2.INF+GPI3.INF'            */
      call add2env 'GPIREF', 'GPI1.INF+GPI2.INF+GPI3.INF', 'B', '+'
/*    'SET PMREF=PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF' */
      call add2env 'PMREF', 'PM1.INF+PM2.INF+PM3.INF+PM4.INF+PM5.INF', 'B', '+'
/*    'SET WPSREF=WPS1.INF+WPS2.INF+WPS3.INF'          */
      call add2env 'WPSREF', 'WPS1.INF+WPS2.INF+WPS3.INF', 'B', '+'
      call set 'SET TCPREF=TCPPR'                           /* JBSQ: What is this? */
/*     SET HELPNDX=EPMKWHLP.NDX+DTYPES.NDX+%HELPNDX%                 */
      call add2env 'HELPNDX', 'EPMKWHLP.NDX+DTYPES.NDX', 'B', '+'
      call set 'SET IPFC=' || envvar.dir_toolkit.value || '\IPFC;'
/*     SET INCLUDE=%DIR_TOOLKIT%\H;%INCLUDE%;%DIR_TOOLKIT%\IDL;      */
      call add2env 'INCLUDE', envvar.dir_toolkit.value || '\H;', 'B'
      call add2env 'INCLUDE', envvar.dir_toolkit.value || '\IDL;'       /* JBSQ: Why are IDL dirs being added to INCLDUE? */
/*    SET LIB=%DIR_TOOLKIT%\LIB;%LIB%        */
      call add2env 'LIB', envvar.dir_toolkit.value || '\LIB;', 'B'
   end


/*     set SOM definitions      */
/*  JBSQ: Why is SOMRUNTIME commented out?                        */
/*  JBSQ: My SOMRUNTIME is set to %DIR_TOOLKIT%\SOM\COMMON'       */
/*  JBSQ: If it should be DIR_COMPILER then will it be the same subdir for all compilers? */
/*  : SET SOMRUNTIME=%DIR_COMPILER%\DLL    JBSQ: Why was this commented out? */
/*    call set 'SET SOMRUNTIME=' || dir_compiler '\DLL'          */
/*    call set 'SET SOMRUNTIME=' || dir_toolkit '\SOM\COMMON'   */
      som_base = envvar.dir_toolkit.value || '\SOM'
      call set 'SET SOMBASE=' || som_base
/*    'SET SOMIR=%SOMBASE%\COMMON\SOM.IR;SOM.IR'   JBSQ: Should SOM.IR should be %SOMIR%?   */
      call add2env 'SOMIR', som_base || '\COMMON\SOM.IR;', 'B'
      call set 'SET SMINCLUDE=.;' || som_base || '\INCLUDE;'
      call set 'SET SMTMP='tmp

/*   JBSQ: Why are these commented out?
: SET SMADDSTAR=1
: SET SMEMIT=h;ih;c
: SET SMCLASSES=WPTYPES.IDL
*/
/*    SET INCLUDE=.;%SOMBASE%\INCLUDE;%INCLUDE%         */
      call add2env 'INCLUDE', som_base || '\INCLUDE;', 'B'
/*    SET PATH=%SOMBASE%\BIN;%PATH%        */
      call add2env 'PATH', som_base || '\BIN;', 'B'
/*    SET DPATH=%SOMBASE%\MSG;%DPATH%         */
      call add2env 'DPATH', som_base || '\MSG;', 'B'
/*    SET LIB=.;%SOMBASE%\LIB;%LIB%           */
      call add2env 'LIB', '.;' || som_base || '\LIB;', 'B'
/*    SET BEGINLIBPATH=%SOMBASE%\LIB;%BEGINLIBPATH%       */
      call add2env 'BEGINLIBPATH', som_base || '\LIB;'


/*    General definitions      */
/*    SET INCLUDE=.;%INCLUDE%  */
/*    In order to ensure that '.;' comes first it is added at the end */
      call add2env 'INCLUDE', '.;', 'B'


/* :END  */
exitcode:
call directory(cfg.curdir)
return retval

env_substitution: procedure expose (globals)
   parse arg newvalue
   newvalue = ' ' || newvalue || ' '      /* Make sure code below doesn't fail */
   p = 0
   do forever
      if p >= length(newvalue) then
         leave
      p = pos('%', newvalue, p + 1)
      if p == 0 then
         leave
      if translate(substr(newvalue, p - 1, 4)) \= '\%N;' then
         do
            p2 = pos('%', newvalue, p + 1)
            if p2 > 0 then
               do
                  varname = substr(newvalue, p + 1, p2 - p - 1)
                  varvalue = value(varname,, cfg.env)
                  if varvalue \= '' then
                     newvalue = left(newvalue, p - 1) || varvalue || substr(newvalue, p2 + 1)
               end
         end
   end
   return strip(newvalue)

add2env: procedure expose (globals)
   parse arg varname, addition
   varname = translate(varname)
   addition = env_substitution(addition)
   add_to_end = 1
   if arg(3) \= '' then
      if translate(left(arg(3), 1)) == 'B' then
         add_to_end = 0
   if arg(4) \= '' then
      separator = arg(4)
   else
      separator = ';'
   if right(addition, 1) \= separator then
      addition = addition || separator
   select
      when (varname == 'BEGINLIBPATH') then
         do
            curval = SysQueryExtLibPath('B')
            libpath = 1
            add_to_end = 0
         end
      when (varname == 'ENDLIBPATH') then
         do
            curval = SysQueryExtLibPath('E')
            libpath = 1
         end
      otherwise
         do
            curval = value(varname,, cfg.env)
            libpath = 0
         end
   end
   if add_to_end then
      do
         newval = curval
         if length(newval) >  0 then
            if right(newval, 1) \= separator then
               newval = newval || separator
      end
   else
      do
         newval = addition
         addition = curval
         if length(addition) >  0 then
            if right(addition, 1) \= separator then
               addition = addition || separator
      end
   do while length(addition) > 1
      parse var addition part1 (separator) addition
      part1 = part1 || separator
      if pos(translate(part1), translate(newval)) == 0 then
         newval = newval || part1
   end
   if separator \= ';' then
      newval = strip(newval, 'T', separator)
   if translate(curval) \= translate(newval) then
      if libpath == 1 then
         if add_to_end then
            call SysSetExtLibpath newval, 'E'
         else
            call SysSetExtLibpath newval, 'B'
      else
         call value varname, newval, cfg.env
return

set: procedure expose (globals)
   parse arg setcmd
   parse var setcmd . varname '=' varvalue
   if value(varname, , cfg.env) == '' then
      do
         varvalue = env_substitution(varvalue)
         call value varname, varvalue, cfg.env
      end
   return

Init: procedure expose (globals)

   parse source . cfg.called_as cfg.thispgm
   cfg.thispgmdir           = left(cfg.thispgm, lastpos('\', cfg.thispgm) - 1)

   cfg.user_setenv_file = stream(cfg.thispgmdir || '\..\setenv.cmd', 'c', 'query exists')
   if cfg.user_setenv_file \= '' then
      cfg.user_setenv_complete = value('USER_SETENV_COMPLETE', '', cfg.env)
   else
      cfg.user_setenv_complete = ''
   if cfg.user_setenv_file \= '' & cfg.user_setenv_complete = '' then
      do
         call SysCls
         say
         say
         say 'You have your own SETENV.CMD file and it has not been run.'
         say 'Please run it, "'cfg.user_setenv_file'", instead of this'
         say 'program: "'cfg.thispgm'"'
         say
         say 'Exiting...'
         exit
      end

   cfg.curdir     = directory()
   cfg.boot_drive = SysBootDrive()
   cfg.InvalidSettingMsg = 'Invalid value:'

   compiler.            = ''
   i                    = 0

   i                    = i + 1
   compiler.i.name      = 'VAC308'
   compiler.i.desc      = 'VisualAge C++ v3.08'

   i                    = i + 1
   compiler.i.name      = 'GCC'
   compiler.i.desc      = 'GNU Compiler v??'

   i                    = i + 1
   compiler.i.name      = 'CSET2'
   compiler.i.desc      = 'C Set/2 v2.1'

   i                    = i + 1
   compiler.i.name      = 'OW13'
   compiler.i.desc      = 'Open Watcom v1.3'

   compiler.0           = i

   compiler_list        = ''
   do i = 1 to compiler.0
      compiler_list = compiler_list compiler.i.name
   end

   envvar.              = ''
   i                    = 0

   i                    = i + 1
   envvar.i.name        = 'USED_COMPILER'
   envvar.i.required    = 1
   envvar.i.upcase      = 1
   envvar.i.list        = compiler_list
   envvar.i.desc.1      = 'This value is used to "name" the compiler you want to use.'
   envvar.i.desc.2      = ''
   envvar.i.desc.3      = 'The supported compilers are:'
   envvar.i.desc.4      = '   Name           Description'
   do j = 1 to compiler.0
      k = j + 4
      envvar.i.desc.k   = j || ') ' || left(compiler.j.name, 15) || compiler.j.desc
   end
   k                    = k + 1
   envvar.i.desc.k      = ''
   k                    = k + 1
   envvar.i.desc.k      = 'Please indicate the name or number of your compiler.'
   envvar.i.desc.0      = k
   used_compiler        = i

   i                    = i + 1
   envvar.i.name        = 'DIR_COMPILER'
   envvar.i.required    = 1
   envvar.i.desc.1      = 'This value is used to set the name of the base directory where'
   envvar.i.desc.2      = 'your compiler, ' || envvar.used_compiler.value || ', has been installed.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'For example, the base directory for VACPP v3.08 is often a'
   envvar.i.desc.5      = 'directory named IBMCPP off the root of a drive, like:'
   envvar.i.desc.6      = '  C:\IBMCPP'
   envvar.i.desc.7      = ''
   envvar.i.desc.8      = 'The base directory is NOT necessarily where the executables are'
   envvar.i.desc.9      = 'located.'
   envvar.i.desc.10     = ''
   envvar.i.desc.11     = 'Please provide the name of the compiler base directory.'
   envvar.i.desc.0      = 11
   dir_compiler         = i

   i                    = i + 1
   envvar.i.name        = 'DIR_TOOLKIT'
   envvar.i.required    = 1
   envvar.i.desc.1      = 'This value is used to set the name of the base directory where the'
   envvar.i.desc.2      = 'OS/2 toolkit files are installed.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'For example, the base directory for v4.5x of the toolkit is often'
   envvar.i.desc.5      = 'a directory named OS2TK45 off the root of a drive, like:'
   envvar.i.desc.6      = '  D:\OS2TK45'
   envvar.i.desc.7      = ''
   envvar.i.desc.8      = 'The base directory is NOT necessarily where the executables are'
   envvar.i.desc.9      = 'located.'
   envvar.i.desc.10     = ''
   envvar.i.desc.11     = 'Please provide the name of the toolkit base directory.'
   envvar.i.desc.0      = 11
   dir_toolkit          = i

   i                    = i + 1
   envvar.i.name        = 'A directory for temporary files'
   envvar.i.required    = 1
   envvar.i.alt_srcs    = 'TMP TEMP TMPDIR SMTMP'
   envvar.i.desc.1      = 'A directory for temporary files is required.'
   envvar.i.desc.2      = ''
   envvar.i.desc.3      = 'This program checked and was unable to detect an environment setting'
   envvar.i.desc.4      = 'for any of the following environment variables which are often used'
   envvar.i.desc.5      = 'for this purpose:'
   do j = 1 to words(envvar.i.alt_srcs)
      k = j + 5
      envvar.i.desc.k   = '  'word(envvar.i.alt_srcs, j)
   end
   k                    = k + 1
   envvar.i.desc.k      = ''
   k                    = k + 1
   envvar.i.desc.k      = 'Please provide the name of a directory to use for temporary files.'
   k                    = k + 1
   envvar.i.desc.k      = 'If the directory does not exist, it will be created.'
   envvar.i.desc.0      = k

   i                    = i + 1
   envvar.i.name        = 'TZ'
   envvar.i.required    = 1
   envvar.i.desc.1      = 'TZ sets the Time Zone. This setting is used by many build environments.'
   envvar.i.desc.2      = ''
   envvar.i.desc.3      = 'An example TZ for the eastern time zone of the U.S.A:'
   envvar.i.desc.4      = '  EST5EDT       or'
   envvar.i.desc.5      = '  EST5EDT,4,1,0,7200,10,-1,0,7200,3600'
   envvar.i.desc.6      = ''
   envvar.i.desc.7      = 'Please provide a valid setting for TZ.'
   envvar.i.desc.0      = 7

   i                    = i + 1
   envvar.i.name        = 'BASEURL'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'This value is used to set a URL were the EPM distribution zip files'
   envvar.i.desc.2      = 'can be downloaded, if needed.'
   envvar.i.desc.0      = 2
   envvar.i.default     = 'ftp://hobbes.nmsu.edu/pub/os2/apps/editors/epm'
   envvar.i.default_txt = 'please provide an appropriate URL for the EPM zip files.'
   envvar.i.cfgin       = 1

   i                    = i + 1
   envvar.i.name        = 'ZIPSRCDIR'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'This value is used to set the name of a locally accessible directory'
   envvar.i.desc.2      = 'where the EPM distribution zip files are or should be located.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'If the EPM distribution zip files are not available, then the NEPMD'
   envvar.i.desc.5      = 'build process will download these files and store them in this'
   envvar.i.desc.6      = 'directory.'
   envvar.i.desc.0      = 6
   envvar.i.default     = directory(thispgmdir || '\..') || '\zip'
   envvar.i.default_txt = 'please provide the name of another directory for the EPM zip files.'
   envvar.i.cfgin       = 1

   i                    = i + 1
   envvar.i.name        = 'UNZIPPEDDIR'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'This value is used to set the name of a locally accessible directory'
   envvar.i.desc.2      = 'where the EPM distribution zip files should be unzipped.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'If the EPM distribution zip files are not available, then the NEPMD'
   envvar.i.desc.5      = 'build process will download these files and store them in this'
   envvar.i.desc.6      = 'directory.'
   envvar.i.desc.7      = ''
   envvar.i.desc.0      = 7
   envvar.i.default     = directory(thispgmdir || '\..') || '\epm.packages'
   envvar.i.default_txt = 'please provide the name of another directory for extraction of zip files.'

   i                    = i + 1
   envvar.i.name        = 'DEBUG'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'The DEBUG setting determines if the build process creates a release'
   envvar.i.desc.2      = 'version or a debug version of the project.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'The acceptable settings are:'
   envvar.i.desc.5      = '   <Undefined> : Create a release version'
   envvar.i.desc.6      = '   <Defined>   : Create a debug version'
   envvar.i.desc.7      = ''
   envvar.i.desc.8      = 'Enter any non-blank (usually ''1'') to enable DEBUG builds.'
   envvar.i.desc.9      = 'Enter nothing to enable release builds.'
   envvar.i.desc.0      = 9

   i                    = i + 1
   envvar.i.name        = 'HOME'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'The HOME setting specifies a directory used by CVS and many other'
   envvar.i.desc.2      = 'tools.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'It is recommended that a HOME directory be set, especially if you'
   envvar.i.desc.5      = 'are using CVS.'
   envvar.i.desc.6      = ''
   envvar.i.desc.7      = 'Press ENTER to contimue without a HOME setting or type in a new'
   envvar.i.desc.8      = 'setting.'
   envvar.i.desc.0      = 8

   i                    = i + 1
   envvar.i.name        = 'APPEND_DATE_TO_WPIFILE'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'During the last step of a build of NEMPMD certain WPI, WPP and'
   envvar.i.desc.2      = 'LOG files are created. These files have names with the version'
   envvar.i.desc.3      = 'number and the language, like NEPMD111_ENG.WPI. Since the'
   envvar.i.desc.4      = 'version number and the language don''t change often, repeated'
   envvar.i.desc.5      = 'builds tend to overwrite these files.'
   envvar.i.desc.6      = ''
   envvar.i.desc.7      = 'Enabling APPEND_DATE_TO_WPIFILE causes these WPI, WPP and LOG'
   envvar.i.desc.8      = 'files to be copied with an additional date/time stamp in the'
   envvar.i.desc.9      = 'name, like NEPMD111_ENG_20061107.WPI'
   envvar.i.desc.10     = 'The acceptable settings are:'
   envvar.i.desc.11     = '   0 : Do not create timestamped copies of the WPI, WPP and LOG files.'
   envvar.i.desc.12     = '   1 : Create timestamped copies of the WPI, WPP and LOG files.'
   envvar.i.desc.0      = 12
   envvar.i.list        = '0 1'
   envvar.i.default     = 0
   envvar.i.default_txt = 'enter a 1 to get timestamped copies.'

   i                    = i + 1
   envvar.i.name        = 'TOUCH'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'The TOUCH setting specifies whether the build process should adjust'
   envvar.i.desc.2      = 'the timestamps of the compiled files.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'Enabling TOUCH requires that the GNU TOUCH utility is available on'
   envvar.i.desc.5      = 'the PATH'
   envvar.i.desc.6      = ''
   envvar.i.desc.7      = 'The acceptable settings are:'
   envvar.i.desc.8      = '   <Undefined> : Do NOT "Touch" the compiled files'
   envvar.i.desc.9      = '   <Defined>   : "Touch" the compiled files.'
   envvar.i.desc.10     = ''
   envvar.i.desc.11     = 'Enter any non-blank (usually ''1'') to enable "Touch".'
   envvar.i.desc.12     = 'Enter nothing to disable "Touch".'
   envvar.i.desc.0      = 12

   i                    = i + 1
   envvar.i.name        = 'CVSEDITOR'
   envvar.i.required    = 0
   envvar.i.desc.1      = 'When performing a CVS commit, CVS will launch an editor to'
   envvar.i.desc.2      = 'facilitate the creation of the log message for the commit.'
   envvar.i.desc.3      = ''
   envvar.i.desc.4      = 'The CVSEDITOR setting is used to specify a command which will'
   envvar.i.desc.5      = 'be used to launch the editor.'
   envvar.i.desc.0      = 5
   envvar.i.default     = 'EPM /M'
   envvar.i.default_txt = 'type a command that will start your preferred editor.'

   envvar.0             = i

return

GetSettingsFromEnv: procedure expose (globals)
   retval = 1  /* assume all is well */
   do i = 1 to envvar.0
      if envvar.i.alt_srcs \= '' then
         do j = 1 to words(envvar.i.alt_srcs)
            envvar.i.value = value( word(envvar.i.alt_srcs, j),, cfg.env)
            if envvar.i.value \= '' then
               leave
         end
      else
         envvar.i.value = value( envvar.i.name,, cfg.env)
      if envvar.i.value = '' then
         if envvar.i.required = 1 then
            do
               retval = 0
            end
         else
            nop
      else
         if i == used_compiler then
            if wordpos(translate(envvar.i.value), translate(envvar.used_compiler.list)) == 0 then
               do
                  retval = 0
                  envvar.i.value = cfg.InvalidSettingMsg envvar.i.value
               end
   end
return retval

GetSettingsFromUser: procedure expose (globals)

   if cfg.user_setenv_file \= '' then
      work_user_setenv_file = cfg.user_setenv_file
   else
      do
         '@copy 'cfg.thispgm cfg.thispgmdir'\..\setenv.cmd >NUL 2>NUL'
         work_user_setenv_file = stream(cfg.thispgmdir'\..\setenv.cmd', 'c', 'query exists')
         '@del 'work_user_setenv_file' >NUL 2>NUL'
      end
   call SysCls
   option = ''
   do until wordpos(option, '1 2 3') > 0
      call SysCls
      say
      say 'The following value(s) must be provided in order to continue:'
      do i = 1 to envvar.0
         if envvar.i.value == '' then
            if envvar.i.required == 1 then
               say '   'envvar.i.name
             else
               nop
         else
            if length(envvar.i.value) >= length(cfg.InvalidSettingMsg) then
               if left(envvar.i.value, length(cfg.InvalidSettingMsg)) == cfg.InvalidSettingMsg then
                  say '   'envvar.i.name
      end
      say
      say 'The value(s) can be provided in any of the following ways:'
      say '   1. Exit this program, set the value(s) manually and then restart.'
      say '   2. Exit this program, create/edit YOUR setenv program:'
      say '         'work_user_setenv_file
      say '      and then run it.'
      if cfg.user_setenv_file \= '' then
         say '   3. Recommended: Let this program prompt you for values and create'
      else
         say '   3. Recommended: Let this program prompt you for values and recreate'
      say '      YOUR setenv program.'
      say
      say 'If you choose option 2 or 3, run your SETENV in the future.'
      say
      say 'If you choose option 3, you will be given explanations of and prompted for all'
      say 'all required settings and some optional ones.'
      say
      call charout , 'Enter your choice (1, 2 or 3): '
      option = strip(linein())
   end
   if option \= 3 then
      exit
   infile = cfg.thispgmdir || '\setenv.cmd'
   '@if exist 'work_user_setenv_file' del 'work_user_setenv_file' >NUL 2>NUL'
   do while lines(infile)
      line = linein(infile)
      call lineout work_user_setenv_file, line
      if pos('Begin of user-configurable part', line) > 0 then
         leave
   end
   separator_line = linein(infile)
   call lineout work_user_setenv_file, separator_line
   call lineout work_user_setenv_file, ''
   redo = 0
   do i = 1 to envvar.0
      call SysCls
      call Write2X
      call Write2X 'Setting: 'envvar.i.name
      call Write2X
      if envvar.i.required = 1 then
         call Write2X 'This is a required setting.'
      else
         call Write2X 'This is an optional setting.'
      call Write2X
      do j = 1 to envvar.i.desc.0
         call Write2X envvar.i.desc.j
      end
      say
      if envvar.i.value \= '' then
         do
            say 'Just type the ENTER key to accept the current setting of: '
            say '   'envvar.i.value
         end
      else if envvar.i.default \= '' then
         do
            say 'If you do not want to accept the default setting of: '
            say '   'envvar.i.default
            say envvar.i.default_txt
         end
      say
      newvalue = strip(linein())
      if envvar.i.upcase == 1 then
         newvalue = translate(newvalue)
      redo = 0
      if newvalue == '' then
         if envvar.i.value == '' then
            envvar.i.value = envvar.i.default
         else
            nop
      else
         envvar.i.value = newvalue
      if envvar.i.list \= '' then
         if wordpos(envvar.i.value, envvar.i.list) == 0 then
            if datatype(envvar.i.value) == 'NUM' then
               if trunc(envvar.i.value) == envvar.i.value & envvar.i.value > 0 & envvar.i.value <= words(envvar.i.list) then
                  envvar.i.value = word(envvar.i.list, envvar.i.value)
               else
                  do
                     envvar.i.value = ''
                     redo = 1
                 end
            else
               do
                  envvar.i.value = ''
                  redo = 1
               end
      if envvar.i.required == 1 then
         if envvar.i.value == '' then
            redo = 1
      if redo == 1 then
         i = i - 1
      else
         do
            if envvar.i.alt_srcs \= '' then
               varname = word(envvar.i.alt_srcs, 1)
            else
               varname = envvar.i.name
            call value varname, envvar.i.value, cfg.env
            call lineout work_user_setenv_file, ''
            call lineout work_user_setenv_file, 'IF NOT "%'varname'%" == "" GOTO :OVER'varname
            call lineout work_user_setenv_file, "SET "varname"="envvar.i.value
            call lineout work_user_setenv_file, ":OVER"varname
            call lineout work_user_setenv_file, ''
            call lineout work_user_setenv_file, separator_line
            call lineout work_user_setenv_file, ''
        end
   end

   dimensions = '0 1'
   maxdim = 8192
   do until (newrows * newcols < 8192)
      call SysCls
      say
      say
      parse value SysTextScreenSize() with cols rows
      say 'Your current screen is 'rows' rows and 'cols' columns.'
      say
      say 'If you would like the screen dimensions to be changed automatically'
      say 'to a different size, enter the new dimensions as two numbers on the'
      say 'same line, rows first then columns.'
      say
      say 'For example:'
      say '  40 132'
      say 'would change the dimensions to 40 rows by 132 columns'
      say
      say 'Rows * Columns must be < 'maxdim
      say
      say 'If you want the current dimensions, just press the ENTER key.'
      say
      dimensions = strip(linein())
      newrows = 1000  /* fake values */
      newcols = 1000
      if dimensions == '' then
         leave
      else
         if words(dimensions) == 2 then
            do
               newrows = word(dimensions, 1)
               newcols = word(dimensions, 2)
               if datatype(newrows) \= 'NUM' | datatype(newcols) \= 'NUM' then
                  do
                     newrows = 1000
                     newcols = 1000
                  end
               else
                  if trunc(newrows) \= trunc(newrows) | trunc(newcols) \= newcols | ,
                     newrows < 1 | newcols < 1 | newrows * newcols >= maxdim then
                     do
                        newrows = 1000
                        newcols = 1000
                     end
            end
   end
   if (dimensions \= '' & (newrows \= rows | newcols \= cols)) then
      do
         '@MODE CO 1>nul 2>&1 & IF NOT ERRORLEVEL 436 MODE CO'newcols','newrows
         call lineout work_user_setenv_file, ''
         call lineout work_user_setenv_file, ''
         call lineout work_user_setenv_file, 'REM   Setting new screen size'
         call lineout work_user_setenv_file, ''
         call lineout work_user_setenv_file, '@MODE CO 1>nul 2>&1 & IF NOT ERRORLEVEL 436 MODE CO'newcols','newrows
         call lineout work_user_setenv_file, ''
         call lineout work_user_setenv_file, ''
         call lineout work_user_setenv_file, separator_line
      end
   call lineout work_user_setenv_file, ''
   write = 0
   line = ''
   do while lines(infile) > 0
      prevline = line
      line = linein(infile)
      if write == 1 then
         call lineout work_user_setenv_file, line
      else
         if pos('End of user-configurable part', line) > 0 then
            do
               write = 1
               call lineout work_user_setenv_file, prevline
               call lineout work_user_setenv_file, line
            end
   end
   call stream infile, 'c', 'close'
   call stream work_user_setenv_file, 'c', 'close'
return

Write2X: procedure expose work_user_setenv_file redo
   parse arg message
   say message
   if redo == 0 then
      call lineout work_user_setenv_file, 'REM   'message
   return
