/****************************** Module Header *******************************
*
* Module Name: epminit.cmd
*
* Syntax: epminit [keyword=value [keyword = value]]
*
*         Following keywords exist:
*
*            RootDir           (default = ThisFile"\..\..\..")
*            Language          (default = "eng")
*            UserDir           (optional, useful if RootDir is read-only)
*            UserDirName       (optional)
*            UseHomeForUserDir (optional)
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
* By default, this batch works in test mode only. In order to let it change
* your OS2.INI, you have to set the following environment variable first:
*
*    SET TEST_MODE=0
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epminit.cmd,v 1.4 2007-09-01 12:20:16 aschn Exp $
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

 fTestMode = VALUE( 'TEST_MODE',, env)
 IF fTestMode <> FALSE THEN
    fTestMode = TRUE

 /* defaults and further consts */
 rc = 0;
 ErrorQueueName  = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage    = '';
 SetupName.      = '';
 SetupName.0     = 0;

 KeywordList = 'RootDir Language UserDir UserDirName UseHomeForUserDir'

 DO UNTIL (TRUE)

    PARSE SOURCE . . ThisFile

    /* change to dir and drive of current file */
    IF (SUBSTR( ThisFile, 2, 1) = ':') THEN
       rcx = DIRECTORY( SUBSTR( ThisFile, 1, 2))
    rcx = DIRECTORY( ThisFile'\..')

    /* set Keyword. stem var for easier handling */
    rest = KeywordList;
    k = 0
    DO WHILE rest <> ''
       PARSE VAR rest next rest;
       k = k + 1;
       /* set keyword name */
       Keyword.k = next;
       /* init kyword value to '' */
       rcx = VALUE( Keyword.k, '');
    END;
    Keyword.0 = k;

    /* parse arg string Keyword1=Value1 Keyword2=Value2 ..., */
    /* values may be enclosed with double quotes             */
    PARSE ARG Args;

/* TODO */
    /* process /? option and give TEST_MODE hint if activated */

/* TODO */
    /* if no Args specified, switch to interactive mode */
    /* in interactive mode, fist list all existing ini keys, */
    /* then ask for each value                               */

    rest = Args;
    DO WHILE rest <> ''
       PARSE VAR rest next '=' rest;

       rest = strip( rest);
       IF (LEFT( rest, 1) = '"') THEN
          PARSE VAR rest '"'Keyvalue'"' rest;
       ELSE
          PARSE VAR rest Keyvalue rest;

       Upnext = TRANSLATE( STRIP( next));
       DO k = 1 to Keyword.0
          IF (Upnext = TRANSLATE( Keyword.k)) THEN
          DO
             rcx = VALUE( Keyword.k, Keyvalue);
             LEAVE;
          END
       END;
    END;

    /* set Language, if empty */
    IF (Language = '') THEN
       Language = DEFAULT_LANGUAGE;

    /* get RootDir, relative to this filename, if empty */
    IF (RootDir = '') THEN
    DO
       RootDir = ThisFile;
       DO Levels = 1 TO RELATIVE_ROOTDIR_UPLEVELS
          lp = LASTPOS( '\', RootDir);
          IF (lp > 3) THEN
             RootDir = LEFT( RootDir, lp - 1);
       END;
    END;

/* TODO */
    /* RootDir maybe on a CD, then standard DirExist would return 0. */
    /* Allow for a read-only RootDir, but then create the myepm tree */
    /* somewhere else. On the next install, the ini keys UserDir,    */
    /* UserDirName and UseHomeForUserDir should be deleted first.    */

    /* check if RootDir exists */
    IF (\DirExist( RootDir)) THEN
    DO
       ErrorMessage = 'Error: NEPMD RootDir cannot be determined.';
       rc = 3; /* ERROR_PATH_NOT_FOUND */
       LEAVE;
    END;

    /* determine name of loader executable before any action */
    LoaderExe = RootDir'\netlabs\bin\epm.exe';
    IF (\FileExist( LoaderExe)) THEN
    DO
       ErrorMessage = 'Error:' LoaderExe 'not found, NEPMD installation is not complete.';
       rc = 2; /* ERROR_FILE_NOT_FOUND */
       LEAVE;
    END;

/* TODO */
    /* check if RootDir is writable before creation of RootDir'\myepm' */

    /* search for SETUP_NAMES and set SetupName. stem var */
    i = 0;
    rest = SETUP_NAMES
    DO WHILE rest <> ''
       PARSE VAR rest next rest
       IF FileExist( next) THEN
       DO
          i = i + 1
          SetupName.i = next
       END
       ELSE
       DO
          ErrorMessage = 'Error: 'SETUP_NAME' cannot be found. Current dir is 'DIRECTORY();
          rc = 2; /* ERROR_FILE_NOT_FOUND */
          LEAVE;
       END;
    END;
    IF (rc = 0) THEN
       SetupName.0 = i
    ELSE
       LEAVE

    /* all checks done, now write ini keys and call further install batches */

    /* add application to OS2.INI */
    DO k = 1 to Keyword.0
       rcx = ''
       Keyword  = Keyword.k
       Keyvalue = VALUE( Keyword.k)
       IF (fTestMode) THEN
          SAY k': 'Keyword' = 'Keyvalue

       IF Keyvalue = '' THEN
       DO
          /* delete keyword if no value and if keyword exists */
          OldValue = SysIni( 'USER', NEPMD_INI_APPNAME, Keyword);
          IF OldValue <> 'ERROR:' THEN
          DO
             IF (fTestMode) THEN
                SAY "SysIni( 'USER', "NEPMD_INI_APPNAME", "Keyword", DELETE:)"
             ELSE
                rcx = SysIni( 'USER', NEPMD_INI_APPNAME, Keyword, 'DELETE:');
          END
       END
       ELSE
          /* write keyword */
          DO
             IF (fTestMode) THEN
                SAY "SysIni( 'USER', "NEPMD_INI_APPNAME", "Keyword", "Keyvalue"'00'x)"
             ELSE
                rcx = SysIni( 'USER', NEPMD_INI_APPNAME, Keyword, Keyvalue'00'x);
          END

       IF (rcx <> '') THEN
          LEAVE;
    END;

    IF (rcx <> '') THEN
    DO
       ErrorMessage = 'Error: default OS2.INI values not written.';
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

 /* call additional Setup CMD files */
 IF (rc = 0) THEN
 DO i = 1 TO SetupName.0
    IF (fTestMode) THEN
      SAY SetupName.i
    ELSE
       'CALL' SetupName.i
 END

 EXIT( rc);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName;

 RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') <> '');

/* ------------------------------------------------------------------------- */
DirExist: PROCEDURE
 PARSE ARG DirName;

 Found.0 = 0
 rcx = SysFileTree( DirName, 'Found.', 'DO');
 RETURN( Found.0 > 0);

