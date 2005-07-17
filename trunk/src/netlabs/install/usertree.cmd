/****************************** Module Header *******************************
*
* Module Name: usertree.cmd
*
* Helper batch for to create all directories of the personal subdirectory
* tree (a WarpIn package cannot include empty directories)
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: usertree.cmd,v 1.10 2005-07-17 15:41:56 aschn Exp $
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


 /* ##############   Maintainer: modify directory list here ######################## */

 UserDirList = 'bar bin bmp dll ex mode macros ndx autolink';
 /* Additionally, the UserDir is created by this script */

 /* ################################################################################# */

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

 FolderId      = '<NEPMD_FOLDER>';
 ObjectIdStart = '<NEPMD_';
 ObjectIdEnd   = '_SHADOW>';

 /* defaults */
 rc = 0
 ErrorQueueName = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage = '';
 fUseHome = 0
 UserDirName = 'myepm'

 /* get the base directory of the NEPMD installation */
 PARSE SOURCE . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);    /* NEPMD\netlabs\install */
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 RootDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1);  /* can be queried from Ini as well */

 /* try to delete renamed keyname (Path -> RootDir) from NEPMD 1.00 */
 next = SysIni( 'USER', NEPMD_INI_APPNAME, 'Path')
 IF next <> 'ERROR:' then
    rcx = SysIni( 'USER', NEPMD_INI_APPNAME, 'Path', 'DELETE:')

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
          call SysFileTree Home, 'Found.', 'D', '*+--*'  /* ADHRS */
          IF Found.0 > 0 THEN
          DO
             UserDir = Home'\'UserDirName
             LEAVE
          END
       END
    END

    UserDir = RootDir'\'UserDirName
    LEAVE
 END

 DO 1
    /* ensure that user dir exists */
    rc1 = SysMkDir( UserDir);
    IF WORDPOS( rc1, '0 5') = 0 THEN  /* rc = 5: dir already exists */
    DO
       ErrorMessage = 'Error: cannot create user directory "'UserDir'".';
       rc = rc1
       LEAVE;
    END

    /* create shadow of UserDir folder in NEPMD folder */
    ObjectId = ObjectIdStart''TRANSLATE( UserDirName)''ObjectIdEnd;
    rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='UserDir';OBJECTID='ObjectId';', 'U');
    rcx = SysSetObjectData( UserDir, 'DEFAULTVIEW=TREE;HELPLIBRARY='RootDir'\netlabs\help\nefldeng.hlp;HELPPANEL=105;');

    /* create directories here - ignore errors */
    DO WHILE (UserDirList \= '')
       PARSE VAR UserDirList ThisDir UserDirList;
       FullPath = UserDir'\'ThisDir;
       rcx = SysMkDir( FullPath);
       rcx = SysSetObjectData( FullPath, 'DEFAULTVIEW=ICON;');
    END;
 END

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

