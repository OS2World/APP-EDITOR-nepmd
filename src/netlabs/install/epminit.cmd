/****************************** Module Header *******************************
*
* Module Name: epminit.cmd
*
* Syntax: epminit
*
* Helper batch for to write default values to OS2.INI without a reinstall.
*
* This is useful when all files are being installed and
*
*    o  the OS2.INI was restored from an archive and misses the entries or
*
*    o  NEPMD should be used during an eCS install.
*
* When the EPM loader proposes to install NEPMD properly with WarpIN, this
* batch can be used instead, provided that all files are present.
*
* After that, EPM can be used from command line. In order to create program
* objects automatically, the WarpIN install has to be repeated.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epminit.cmd,v 1.1 2007-07-08 03:33:00 aschn Exp $
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
 NEPMD_INI_APPNAME          = 'NEPMD'
 NEPMD_INI_KEYNAME_LANGUAGE = 'Language'
 NEPMD_INI_KEYNAME_ROOTDIR  = 'RootDir'

 DEFAULT_LANGUAGE           = 'eng'
 RELATIVE_ROOTDIR_UPLEVELS  = 3  /* RootDir filespec relative to this file */
 SETUP_NAMES                = 'usertree.cmd dyncfg.cmd'

 /* defaults and further consts */
 rc = 0;
 ErrorQueueName  = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage    = '';

 DO UNTIL (TRUE)

    PARSE SOURCE . . ThisFile

    /* change to dir and drive of current file */
    rcx = DIRECTORY( ThisFile'\..')
    IF (SUBSTR( ThisFile, 2, 1) = ':') THEN
       rcx = DIRECTORY( SUBSTR( ThisFile, 1, 2))
    rcx = DIRECTORY( ThisFile'\..')

    /* get RootDir, relative to this filename */
    RootDir = ThisFile
    DO Levels = 1 TO RELATIVE_ROOTDIR_UPLEVELS
       lp = LASTPOS( '\', RootDir)
       IF (lp > 3) THEN
          RootDir = LEFT( RootDir, lp - 1)
    END

    /* check if RootDir exists */
    rcx = SysFileTree( RootDir, 'Found.', 'DO')
    IF (Found.0 = 0) THEN
    DO
       ErrorMessage = 'Error: NEPMD RootDir cannot be determined.';
       rc = 3; /* ERROR_PATH_NOT_FOUND */
       LEAVE;
    END;

    /* add application to OS2.INI */
    rcx = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_LANGUAGE, DEFAULT_LANGUAGE'00'x);
    IF (rcx = '') THEN
       rcx = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_ROOTDIR, RootDir'00'x);

    IF (rcx <> '') THEN
    DO
       ErrorMessage = 'Error: default OS2.INI values not written.';
       rc = 1; /* ERROR */
       LEAVE;
    END;

    /* search for SETUP_NAMES */
    SetupName.  = ''
    i           = 0
    SetupName.0 = i
    rest = SETUP_NAMES
    DO WHILE rest <> ''
       PARSE VAR rest next rest
       next = STREAM( next, 'c', 'query exist')
       IF (next <> '') THEN
       DO
          i = i + 1
          SetupName.i = next
       END
       ELSE
       DO
          ErrorMessage = 'Error: 'SETUP_EXE_NAME' cannot be found. Current dir is 'DIRECTORY();
          rc = 2; /* ERROR_FILE_NOT_FOUND */
          LEAVE;
       END;
    END;
    IF (rc = 0) THEN
       SetupName.0 = i
    ELSE
       LEAVE

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

 /* call additional Setup CMD files */
 IF (rc = 0) THEN
 DO i = 1 TO SetupName.0
    'CALL' SetupName.i
 END

 EXIT( rc);

