/****************************** Module Header *******************************
*
* Module Name: usertree.cmd
*
* Helper batch for to create all directories of the personal subdirectory
* tree (a WarpIn package cannot include empty directories).
*
* Additionally, it creates shadow objects for the user and the root folder.
*
* This program is intended to be called by NLSETUP.EXE during installation
* of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: usertree.cmd,v 1.13 2008-09-20 23:14:30 aschn Exp $
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

 UserDirList = 'bar bin bmp dll ex mode macros ndx autolink spellchk';
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
          UserDir = ResolveEnvVars( next)
          LEAVE
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

    /* apply help panel to UserDir folder */
    rcx = SysSetObjectData( UserDir, 'DEFAULTVIEW=TREE;HELPLIBRARY='RootDir'\netlabs\help\nefldeng.hlp;HELPPANEL=105;');
    /* create shadow of UserDir folder in NEPMD folder */
    ObjectId = ObjectIdStart''TRANSLATE( UserDirName)''ObjectIdEnd;
    rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='UserDir';OBJECTID='ObjectId';', 'U');

    /* create directories here - ignore errors */
    DO WHILE (UserDirList \= '')
       PARSE VAR UserDirList ThisDir UserDirList;
       FullPath = UserDir'\'ThisDir;
       rcx = SysMkDir( FullPath);
       rcx = SysSetObjectData( FullPath, 'DEFAULTVIEW=ICON;');
    END;
 END

 /* apply help panel to RootDir folder */
 rcx = SysSetObjectData( RootDir, 'DEFAULTVIEW=TREE;HELPLIBRARY='RootDir'\netlabs\help\nefldeng.hlp;HELPPANEL=114;');
 /* create shadow of RootDir folder in NEPMD folder */
 ObjectId = ObjectIdStart''TRANSLATE( RootDirName)''ObjectIdEnd;
 rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='RootDir';OBJECTID='ObjectId';', 'U');

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

/* ----------------------------------------------------------------------- */
ResolveEnvVars: PROCEDURE EXPOSE (GlobalVars)

   Spec = ARG( 1)
   Startp = 1
   DO FOREVER
      p1 = pos( '%', Spec, Startp)
      IF p1 = 0 THEN
         LEAVE
      startp = p1 + 1
      p2 = POS( '%', Spec, Startp)
      IF p2 = 0 THEN
         LEAVE
      ELSE
      DO
         Startp = p2 + 1
         Spec = SUBSTR( Spec, 1, p1 - 1) ||,
                VALUE( SUBSTR( Spec, p1 + 1, p2 - p1 - 1),, env) ||,
                SUBSTR( Spec, p2 + 1)
      END
   END
   RETURN( Spec)

