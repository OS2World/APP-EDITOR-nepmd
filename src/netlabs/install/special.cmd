/****************************** Module Header *******************************
*
* Module Name: special.cmd
*
* Helper batch for to
*  - apply settings that depend on the UserDir.
*  - remove obsolete objects.
*  - set Parameters for program objects that contains double quotes (WarpIN
*    can not use double quotes).
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: special.cmd,v 1.2 2007-07-08 18:55:53 aschn Exp $
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

 /* initialize */
 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 CALL SysLoadFuncs;
 GlobalVars = 'Sep CallDir NetlabsDir RootDir UserDir EcsFlag BootDrive'
 env = 'OS2ENVIRONMENT';
 Sep = '01'x

 /* INI app names and keys of NEPMD project from OS2.INI, defined in nepmd.h */
 NEPMD_INI_APPNAME             = "NEPMD"
 NEPMD_INI_KEYNAME_LANGUAGE    = "Language"
 NEPMD_INI_KEYNAME_ROOTDIR     = "RootDir"
 NEPMD_INI_KEYNAME_USERDIR     = "UserDir"
 NEPMD_INI_KEYNAME_USERDIRNAME = "UserDirName"
 NEPMD_INI_KEYNAME_USEHOME     = "UseHomeForUserDir"

 /* default values */
 fUseHome = 0
 UserDirName = 'myepm'
 EcsFlag = 1  /* default, if syslevel.os2 not found, is to use eCS icons */

 /* set global vars */
 CALL GetBootDrive
 CALL GetEcsFlag
 CALL GetNepmdDirs

 /* ##############   Maintainer: modify object id list here ######################## */

 FolderObjectIdList = '<NEPMD_FOLDER> <NEPMD_SAMPLES_FOLDER>' ||,
                      ' <NEPMD_MORE_OBJECTS_FOLDER>';

 /* ################################################################################# */

 /* Additional objects to be created with SysCreateObject                             */

 i = 0
 CreateClass. = ''
 CreateTitle. = ''
 CreateDest.  = ''
 CreateSetup. = ''

 /* Left in as an example */
/*
 Language = 'eng'
 i = i + 1
 CreateClass.i = 'WPProgram'
 CreateTitle.i = 'EPM Shell'
 CreateDest.i  = '<NEPMD_FOLDER>'
 CreateSetup.i = 'PROGTYPE=PM;EXENAME=EXENAME=EPM.EXE;' ||,
                 'PARAMETERS=''shell cdd %*'';' ||,
                 'HELPLIBRARY='RootDir'\netlabs\help\nefld'Language'.hlp;HELPPANEL=101;' ||,
                 'OBJECTID=<NEPMD_EPM_SHELL>;"'
*/

 /* SysCreateObject requires a title parameter even when being useless, eg. for */
 /* shadow objects. Therefore in the following the title '.' is used.           */
 /* There exists another special behavior of shadow objects together with       */
 /* SysCreateObject: If the shadow should get an object id assigned and it      */
 /* already exists, then the object is not created. For other objects, the old  */
 /* objects looses its object id instead and the new object is created.         */

 DestDir = '<WP_PROMPTS>'
 IF (ObjectExists( DestDir)) THEN
 DO
    i = i + 1
    CreateClass.i = 'WPShadow'
    CreateTitle.i = '.'
    CreateDest.i  = DestDir
    CreateSetup.i = 'SHADOWID=<NEPMD_EPM_SHELL>;OBJECTID=<NEPMD_EPM_SHELL_SHADOW>;'
 END

 /* Get location of XWorkplace's OS/2 window object.                           */
 /* GetObjectLocation accepts a space-separated list of objects to search for. */
 /* It returns the Location for the first succesfully queried object.          */
 DestDir = GetObjectLocation( '<XWP_OS2WIN>')
 IF DestDir > '' THEN
 DO
    i = i + 1
    CreateClass.i = 'WPShadow'
    CreateTitle.i = '.'
    CreateDest.i  = DestDir
    CreateSetup.i = 'SHADOWID=<NEPMD_EPM_SHELL>;OBJECTID=<NEPMD_EPM_SHELL_SHADOW2>;'
 END

 CreateObj.0 = i  /* number of objects */

 /* ################################################################################# */

 /* Additional settings for objects that have double quotes in their parameters       */
 /* (WarpIN can not set double quotes)                                                */

 i = 0
 DataObj.   = ''
 DataSetup. = ''

 /* Left in as an example */
 /*
 i = i + 1
 DataObj.i   = '<NEPMD_EPM_SHELL>'
 DataSetup.i = 'PARAMETERS=''shell cdd "%*"'';'
 */

 DataObj.0 = i  /* number of objects */

 /* ################################################################################# */

 /* determine operating system version */
 SELECT
    WHEN (SysOs2Ver() < '2.40') THEN Type = '3';
    WHEN (EcsFlag = 1)          THEN Type = 'e';
    OTHERWISE                        Type = '4';
 END;

 /* set icon for folders */
 FolderIconSetup = 'ICONFILE='CallDir'\ico\folder'Type'.ico;' ||,
                   'ICONNFILE=1,'CallDir'\ico\folder'Type'o.ico;';
 DO WHILE (FolderObjectIdList \= '')
    PARSE VAR FolderObjectIdList ThisObject FolderObjectIdList;
    rc = SysSetObjectData( ThisObject, FolderIconSetup);
 END;

 /* set icon for user folder */
 rc = SysSetObjectData( UserDir, FolderIconSetup);

 /* set icon for root folder */
 rc = SysSetObjectData( RootDir, FolderIconSetup);

 /* set parameter for "Recompile EPM", created by WarpIN (WarpIN doesn't know UserDir) */
 rc = SysSetObjectData( '<NEPMD_RECOMP>', 'PARAMETERS='UserDir'\ex');

 /* create special objects */
 URI = 'U'  /* Update | Replace | Ignore */
 DO i = 1 TO CreateObj.0
    IF (POS( 'SHADOWID=', CreateSetup.i) > 0) THEN
       URI = 'R'
    rc = SysCreateObject( CreateClass.i, CreateTitle.i, CreateDest.i, CreateSetup.i, URI);
 END;

 /* set special object settings */
 DO i = 1 TO DataObj.0
    rc = SysSetObjectData( DataObj.i, DataSetup.i);
 END;

 /* delete obsolete object from v1.00 if present */
 rc = SysDestroyObject( '<NEPMD_EXECUTABLE>');

 /* delete obsolete files and dirs from prior versions if present */
 rc = SysDestroyObject( NetlabsDir'\mode\fortran');
 rc = SysDestroyObject( NetlabsDir'\install\saveold.cmd');
 rc = SysDestroyObject( NetlabsDir'\macros\drawkey.e');
 rc = SysDestroyObject( NetlabsDir'\macros\menuacel.e');
 rc = SysDestroyObject( NetlabsDir'\macros\setconfig.e');
 rc = SysDestroyObject( NetlabsDir'\macros\small.e');
 rc = SysDestroyObject( NetlabsDir'\macros\statline.e');
 rc = SysDestroyObject( NetlabsDir'\macros\titletext.e');
 rc = SysDestroyObject( NetlabsDir'\macros\xchgline.e');
 rc = SysDestroyObject( NetlabsDir'\bin\epmshell.cmd');

 /* remove obsolete ini key from v1.00 if present */
 rc = SysIni( 'USER', 'NEPMD', 'Path', 'DELETE:')

 EXIT( 0);

/* ------------------------------------------------------------------------- */
GetBootDrive: PROCEDURE EXPOSE (GlobalVars)

 /* Get BootDrive */
 IF \RxFuncQuery( 'SysBootDrive') THEN
    BootDrive = SysBootDrive()
 ELSE
    PARSE UPPER VALUE VALUE( 'PATH', , env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

 RETURN

/* ------------------------------------------------------------------------- */
GetEcsFlag: PROCEDURE EXPOSE (GlobalVars)

 /* Read Syslevel file(s) */
 DO 1
    File = BootDrive'\ecs\install\syslevel.ecs'
    next = QuerySysLevel( File)
    PARSE VALUE next WITH rc (Sep) SName (Sep) SVersion (Sep) SLevel
    IF rc = 0 THEN
    DO
       EcsFlag = (TRANSLATE( SUBSTR( SName, 1, 11)) = 'ECOMSTATION')
       LEAVE
    END

    File = BootDrive'\os2\install\syslevel.ecs'
    next = QuerySysLevel( File)
    PARSE VALUE next WITH rc (Sep) SName (Sep) SVersion (Sep) SLevel
    IF rc = 0 THEN
    DO
       EcsFlag = (TRANSLATE( SUBSTR( SName, 1, 11)) = 'ECOMSTATION')
       LEAVE
    END

    File = BootDrive'\os2\install\syslevel.os2'
    next = QuerySysLevel( File)
    PARSE VALUE next WITH rc (Sep) SName (Sep) SVersion (Sep) SLevel
    IF rc = 0 THEN
    DO
       EcsFlag = (TRANSLATE( SUBSTR( SName, 1, 11)) = 'ECOMSTATION')
       LEAVE
    END
 END

 RETURN

/* ------------------------------------------------------------------------- */
GetNepmdDirs: PROCEDURE EXPOSE (GlobalVars)

 /* get the root directory of the NEPMD installation */
 PARSE SOURCE . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);    /* NEPMD\netlabs\install */
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 RootDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1);  /* can be queried from Ini as well */

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

 RETURN

/* ------------------------------------------------------------------------- */
/*
 * Syntax: String = QuerySysLevel(<syslevel_file>)
 *
 * Returns a string of 5 segments, separated by Sep, e.g.:
 *    0eComStation Basisbetriebssystem45XRGC005
 * The first segment is rc.
 */
QuerySysLevel: PROCEDURE EXPOSE (GlobalVars)
 InFile = STREAM( ARG(1), 'c', 'query exists')
 IF InFile > '' THEN
 DO
    CALL STREAM InFile, 'c', 'open read'
    line = CHARIN( InFile, 1, 165)
    CALL STREAM InFile, 'c', 'close'
    Startp = C2D( REVERSE( SUBSTR( line, 34, 4))) + 1
    SName = STRIP( SUBSTR( line, Startp + 23, 80), 't', '00'x)
    SVersion = C2X( SUBSTR( line, Startp + 3, 1))
    SLevel = STRIP( STRIP( SUBSTR( line, Startp + 7, 8), 't', '00'x), 't', '_')
    rc = 0
    RETURN rc''Sep''SName''Sep''SVersion''Sep''SLevel
 END
 ELSE
    RETURN 2''Sep''Sep''Sep

/* ------------------------------------------------------------------------- */
/* Check if object exists. Returns 1 if exists, otherwise 0 */
ObjectExists: PROCEDURE
 rc = SysSetObjectData( ARG(1), '')
 RETURN rc

/* ------------------------------------------------------------------------- */
GetObjectLocation: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG ObjList
 ObjLoc = ''

 IF RxFuncQuery( 'WPToolsQueryObject') THEN
 DO
    /* ensure that netlabs\dll is in BEGINLIBPATH */
    'SET BEGINLIBPATH='RootDir'\netlabs\dll;'
    CALL RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs';
    CALL WPToolsLoadFuncs;
 END

 IF \RxFuncQuery( 'WPToolsQueryObject') THEN
 DO
    /* get location of XWorkplace's OS/2 window object */
    /* space-separated list of objects to search */
    Rest = ObjList
    DO WHILE LENGTH( Rest) > ''
       PARSE VAR Rest Obj Rest
       Obj = STRIP( Obj)
       Rest = STRIP( Rest)
       /* drop sometimes required, otherwise wrong objects were listed */
       DROP Class;
       DROP Title;
       DROP Setup;
       DROP Location;
       rcx = WpToolsQueryObject( Obj, Class, Title, Setup, Location);
       IF (rcx <> 1 | Location = '') THEN
          ITERATE;
       ObjLoc = Location
       LEAVE
    END
 END

 RETURN ObjLoc

