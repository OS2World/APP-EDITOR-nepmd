/****************************** Module Header ******************************\
:
: Module Name: d.cmd
:
: Batch file for loading EPM to debug nepmdlib.dll.
: NOTE:
;   - set load occurrence do "nepmdlib" after EPM.EXE has been loaded.
;     When the DLL is loaded, set the deired breakpoints and remove
;     the "load on occurrence" breakpoint
;   - the EPM(CALL) loder executable may not be within the path,
:     instead the true EPM.EXE must be first in path, otherwise
:     the debugger is not able to detect load occurrence of
:     NEPMDLIB.DLL
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id: d.cmd,v 1.1 2002-08-21 21:37:13 cla Exp $
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

 rc = SETLOCAL();
 env = 'OS2ENVIRONMENT';

 /* select debugger */
 Debugger = 'icsdebug';
 IF (VALUE( 'CPPLOCAL',,env) = '') THEN
    Debugger = 'ipmd';

 /* set more environment */
 rcx = VALUE( 'EPMPATH', 'macros;..\..\..\compile\base\netlabs\ex;', env);
 rcx = VALUE( 'NEPMD_TMFTESTFILE', 'nepmdlib.tmf',env);

 /* search epm.exe */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs
 EpmExe = SysSearchPath( 'PATH', 'EPM.EXE');
 IF (EpmExe = '') THEN
 DO
    SAY 'error: EPM.EXE not found'.
    EXIT( 2); /* ERROR_FILE_NOT_FOUND */
 END;

 /* extend PMDPATH to common.lib sources */
 rcx = VALUE( 'PMDPATH', '..\common;'VALUE( 'PMDPATH',,env), env);

 /* start debugger */
 'call make'
 IF (rc = 0) THEN
   'start' Debugger EpmExe;

