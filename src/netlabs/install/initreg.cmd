/****************************** Module Header *******************************
*
* Module Name: initreg.cmd
*
* Syntax: initreg
*
* Helper batch for to delete the RegDefaults application of NEPMD.INI.
* This application contains all NEPMD's default values. It will be rebuilt
* by the E procedure NepmdInitConfig on the next EPM start from the file
* DEFAULTS.DAT.
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: initreg.cmd,v 1.1 2004-05-09 12:53:20 aschn Exp $
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
 CrLf  = '0d0a'x
 Redirection = '>NUL 2>&1';
 GlobalVars = 'env TRUE FALSE Redirection';

 /* initialize */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;

 /* defaults */
 rc = 0;
 ErrorQueueName  = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage    = '';
 NepmdIniName    = 'nepmd.ini';
 NepmdIniSubPath = '\myepm\bin\';
 NepmdIniAppl    = 'RegDefaults';

 DO UNTIL (TRUE)

    /* get the base directory of the NEPMD installation */
    PARSE VALUE SysIni(, 'NEPMD', 'Path') WITH InstallPath'00'x;
    IF (InstallPath = 'ERROR:') THEN
    DO
       ErrorMessage = 'Error: NEPMD configuration not found.';
       rc = 3; /* ERROR_PATH_NOT_FOUND */
       LEAVE;
    END;
   
    /* full pathname of NEPMD.INI */
    NepmdIni = InstallPath''NepmdIniSubPath''NepmdIniName
    
    /* check if NEPMD.INI exists */
    rc = SysFileTree( NepmdIni, 'Found.', 'FO', '*-***');
    IF Found.0 = 0 THEN
    DO
       rc = 0; /* no reset of default values required */
       LEAVE;
    END;
   
    /* check if application in NEPMD.INI exists */
    rc = SysIni( NepmdIni, NepmdIniAppl);
    IF rc = 'ERROR:' THEN
    DO
       rc = 0; /* no reset of default values required */
       LEAVE;
    END;
    
    /* delete application in NEPMD.INI */
    rc = SysIni( NepmdIni, NepmdIniAppl, 'DELETE:');
    IF rc <> '' then
    DO
       ErrorMessage = 'Error: default NEPMD.INI values not deleted.';
       rc = 1; /* ERROR */
       LEAVE;
    END;
 END;

 /* report error message */
 SELECT
    /* no error here */
    WHEN (rc = 0) THEN NOP;

    /* called by frame program: insert error */
    /* message into standard REXX queue     */
    WHEN (ErrorQueueName \= '') THEN
    DO
       rcx = RXQUEUE( 'SET', ErrorQueueName);
       PUSH ErrorMessage;
    END;

    /* called directly, method */
    OTHERWISE
    DO
       SAY ErrorMessage;
       'PAUSE';
    END;
 END;

 EXIT( rc);

