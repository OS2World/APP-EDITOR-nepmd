/****************************** Module Header *******************************
*
* Module Name: dyncfg.cmd
*
* Helper batch for to copy netlabs\bin\epm.exe to a directory along
* the PATH. Preferred is ?:\OS2, as this comes before ?:\OS2\APPS,
* where the original EPM is mostly installed.
*
* netlabs\bin\epm.exe is a dummy loader exe, which loads the true EPM.EXE
* after having setup the environment according to the environment file
* netlabs\bin\epm.env. It must be the first EPM.EXE along the PATH.
* See netlabs\book\nepmd.inf for more information about this executable.
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dyncfg.cmd,v 1.1 2002-08-11 00:43:16 cla Exp $
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
 env   = 'OS2ENVIRONMENT';
 TRUE  = (1 = 1);
 FALSE = (0 = 1);
 Redirection = '>NUL 2>&1';

 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;

 /* defaults */
 rc = 0;

 DO UNTIL (TRUE)

    /* get the base directory of the NEPMD installation */
    InstallPath = SysIni(, 'NEPMD', 'Path');
    PARSE VALUE SysIni(, 'NEPMD', 'Path') WITH InstallPath'00'x;
    IF (InstallPath = 'ERROR:') THEN
    DO
       SAY 'error: NEPMD configuration not found.';
       rc = 3; /* ERROR_PATH_NOT_FOUND */
       LEAVE;
    END;

   
    /* determine name of loader executable */
    LoaderExe = InstallPath'\netlabs\bin\epm.exe';
    IF (\FileExist( LoaderExe)) THEN
    DO
       SAY 'error:' LoaderExe 'not found, NEPMD installation is not complete.';
       rc = 2; /* ERROR_FILE_NOT_FOUND */
       LEAVE;
    END;
   
    /* get OS2 diretcory name */
    PARSE VALUE TRANSLATE( VALUE('PATH',,env)) WITH '\OS2;' -2 BootDrive +2;
    OS2Dir = TRANSLATE( BootDrive'\OS2');
   
    /* if EPM.EXE resides in this directory, we may have a problem */
    CheckFile = OS2Dir'\EPM.EXE';
    IF (FileExist( CheckFile)) THEN
    DO
       /* is it our executable ? */
       rc = SysGetEa( CheckFile, 'NEPMD.Loader', LoaderTag);
       IF ((rc \= 0) | (LoaderTag = '')) THEN /* NO_ERROR */
       DO
          SAY 'error: ' OS2Dir'\epm.exe is not of NEPMD, cannot continue.';
          rc = 5; /* ERROR_ACCESS_DENIED */
          LEAVE;
       END;
    END;
   
    /* determine original EPM.EXE along the path */
    PathList = VALUE( 'PATH',,env);
    fOs2DirPassed = FALSE;
    fEpmFound     = FALSE;
    DO WHILE (PathList \= '')
       PARSE VAR PathList ThisDir';'PathList;
       IF (ThisDir = '') THEN ITERATE;
   
       /* is it the OS/2 directory ? */
       IF (TRANSLATE( ThisDir) = OS2Dir) THEN
       DO
          fOs2DirPassed = TRUE;
          ITERATE;
       END;
   
       /* now check for EPM */
       IF (RIGHT( ThisDir, 1) \= '\') THEN
          ThisDir = ThisDir'\';
       EpmExecutable = ThisDir'epm.exe';
       IF (FileExist( EpmExecutable)) THEN
          fEpmFound = TRUE;
    END;
   
    IF (fEpmFound) THEN
    DO
       /* if os2 directory was not placed before, our loader will not be used */
       IF (\fOs2DirPassed) THEN
       DO
          SAY 'error: EPM.EXE found in directory prior to' OS2Dir', cannot proceed.';
          rc = 5; /* ERROR_ACCESS_DENIED */
          LEAVE;
       END;
   
       /* copy EPM.EXE of NEPMD */
       'COPY' LoaderExe OS2Dir Redirection;
       IF (rc \= 0) THEN
       DO
          SAY 'error: cannot write' CheckFile'!';
          rc = 5; /* ERROR_ACCESS_DENIED */
          LEAVE;
       END;
   
       /* mark EXE with special attribute (EAT_STRING) */
       LoaderInfo = '1';
       EaLen = REVERSE( RIGHT( D2C( LENGTH( LoaderInfo)), 2, D2C(0)));
       EaValue = 'FDFF'x''EaLen''LoaderInfo;
       rcx = SysPutEa( CheckFile, 'NEPMD.Loader', EaValue);
   
    END;
 END;

 IF (rc \= 0) THEN
    'PAUSE';

 EXIT( 0);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');

