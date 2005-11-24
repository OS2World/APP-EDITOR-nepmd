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
* $Id: initreg.cmd,v 1.3 2005-11-24 02:09:03 aschn Exp $
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

 /* INI app names and keys of NEPMD project from OS2.INI, defined in nepmd.h */
 NEPMD_INI_APPNAME             = "NEPMD"
 NEPMD_INI_KEYNAME_LANGUAGE    = "Language"
 NEPMD_INI_KEYNAME_ROOTDIR     = "RootDir"
 NEPMD_INI_KEYNAME_USERDIR     = "UserDir"
 NEPMD_INI_KEYNAME_USERDIRNAME = "UserDirName"
 NEPMD_INI_KEYNAME_USEHOME     = "UseHomeForUserDir"

 /* defaults and further consts */
 rc = 0;
 ErrorQueueName  = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage    = '';
 NepmdIniName    = 'nepmd.ini';
 NepmdIniSubPath = 'bin';
 NepmdIniAppl    = 'RegDefaults';
 fUseHome        = 0
 UserDirName     = 'myepm'

 DO UNTIL (TRUE)

    /* get the base directory of the NEPMD installation */
    PARSE VALUE SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_ROOTDIR) WITH RootDir'00'x;
    IF (RootDir = 'ERROR:') THEN
    DO
       ErrorMessage = 'Error: NEPMD configuration not found.';
       rc = 3; /* ERROR_PATH_NOT_FOUND */
       LEAVE;
    END;

    /* get user directory */
    DO 1
       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USERDIR)
       IF next <> 'ERROR:' then
       DO
          next = STRIP( next, 't', '00'x)
          IF next > '' THEN
          DO
             UserDir = next
             LEAVE
          END
       END

       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USERDIRNAME)
       IF next <> 'ERROR:' then
       DO
          next = STRIP( next, 't', '00'x)
          IF next > '' THEN
             UserDirName = next
       END

       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USEHOME)
       IF next <> 'ERROR:' then
       DO
          next = STRIP( next, 't', '00'x)
          IF next > '' THEN
             fUseHome = next
       END
       IF fUseHome = 1 THEN
       DO
          Home = VALUE( 'HOME', , env)
          IF Home > '' THEN
          DO
             call SysFileTree Home, 'Found.', 'DO', '*+--*'  /* ADHRS */
             IF Found.1 > '' THEN
             DO
                UserDir = Home'\'UserDirName
                LEAVE
             END
          END
       END

       UserDir = RootDir'\'UserDirName
       LEAVE
    END

    /* full pathname of NEPMD.INI */
    NepmdIni = UserDir'\'NepmdIniSubPath'\'NepmdIniName

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

