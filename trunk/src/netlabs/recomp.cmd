/****************************** Module Header *******************************
*
* Module Name: recomp.cmd
*
* Syntax: recomp.cmd
*
* Script for to start the recomp utility with the correct environment.
*
* PREREQUISITES:
*   - ETPM must reside along the PATH
*   - either ..\..\debug\recomp.exe or ..\..\release\recomp.exe
*     must be built before, if no compiler setup is loaded
*     the debug version is being preferred over the release version, if both
*     are available
*   - if a compiler's environment is available, and recomp.exe cannot be
*     found, this batch will build it prior to calling it
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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

 '@ECHO OFF';
 rcx = SETLOCAL();
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 env = 'OS2ENVIRONMENT';

 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* defaults */
 ExecName = 'recomp.exe';
 fFound   = FALSE;

 /* set include path for macro compiler */
 'SET EPMPATH=macros';

 /* get either release or debug directory */
 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir    = LEFT( NetlabsDir,  LASTPOS( '\', NetlabsDir) - 1);
 DebugDir   = BaseDir'\debug';
 ReleaseDir = BaseDir'\release';
 ExDir      = BaseDir'\compile\base\netlabs\ex';

 /* select version */
 ExecRecomp = '';
 CheckFile = ReleaseDir'\'ExecName;
 IF (FileExist( CheckFile)) THEN
    ExecRecomp = CheckFile;
 CheckFile = DebugDir'\'ExecName;
 IF (FileExist( CheckFile)) THEN
    ExecRecomp = CheckFile;

  /* rebuild recomp.exe if not available */
 IF (ExecRecomp \= '') THEN
    fFound = TRUE;
 ELSE
 DO
    /* can we build ? search supported compiler */
    IF (SysSearchPath( 'PATH', 'ICC.EXE') \= '') THEN
    DO
       CurrentDir = DIRECTORY();
       rcx = DIRECTORY( BaseDir);
       'call nmake /nologo MODULE=gui\common';
       'call nmake /nologo MODULE=gui\recomp';
       IF (VALUE( 'DEBUG',,env) \= '') THEN
          ExecRecomp = DebugDir'\'ExecName;
       ELSE
          ExecRecomp = ReleaseDir'\'ExecName;
       fFound = FileExist( ExecRecomp);
    END;
 END;

 IF (\fFound) THEN
 DO
    SAY 'error: Cannot find recomp.exe !';
    'PAUSE';
    EXIT( 2); /* ERROR_FILE_NOT_FOUND */
 END;

 'START' ExecRecomp ExDir;

 EXIT (rc);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');

