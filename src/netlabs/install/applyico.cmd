/****************************** Module Header *******************************
*
* Module Name: applyico.cmd
*
* Helper batch for to
*  - attach operating system dependant icons to the folders of the Netlabs
*    EPM Distribution, as WarpIn can currently not determine the operating
*    system version (Warp3 / Warp 4 / eComStation) during installation.
*  - apply settings that depend on the UserDir.
*  - remove obsolete objects.
*  - set Parameters for program objects that contains doublequotes (WarpIN
*    can not use doublequotes).
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: applyico.cmd,v 1.18 2007-02-12 01:04:31 jbs Exp $
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

 PARSE SOURCE . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);    /* NEPMD\netlabs\install */

 /* default values */
 EcsFlag = 1  /* default, if syslevel.os2 not found, is to use eCS icons */

 /* set global vars */
 CALL GetBootDrive
 CALL GetEcsFlag

 /* ##############   Maintainer: modify object id list here ######################## */

 FolderObjectIdList = '<NEPMD_FOLDER> <NEPMD_SAMPLES_FOLDER>' ||,
                      ' <NEPMD_MORE_OBJECTS_FOLDER>';

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

 /* set icons for EPM program objects */
 /* (required only for showing the icon immediately after install) */
 rc = SysSetObjectData( '<NEPMD_EPM>',,
                        'ICONFILE='CallDir'\ico\nepmd.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_NEW_SAME_WINDOW>',,
                        'ICONFILE='CallDir'\ico\nepmd.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_SHELL>',,
                        'ICONFILE='CallDir'\ico\nepmd.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_TURBO>',,
                        'ICONFILE='CallDir'\ico\nepmd.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_BIN>',,
                        'ICONFILE='CallDir'\ico\nepmd.ico;');

 /* set special icons for EPM program objects */
 rc = SysSetObjectData( '<NEPMD_EPM_E>',,
                        'ICONFILE='CallDir'\ico\nepmd_e.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_EDIT_MACROFILE>',,
                        'ICONFILE='CallDir'\ico\nepmd_ex.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_ERX>',,
                        'ICONFILE='CallDir'\ico\nepmd_erx.ico;');
 rc = SysSetObjectData( '<NEPMD_EPM_TEX>',,
                        'ICONFILE='CallDir'\ico\nepmd_tex.ico;');

 rc = SysSetObjectData( '<NEPMD_TOGGLE_CCVIEW>',,
                        'ICONFILE='CallDir'\ico\recomp.ico;');
 rc = SysSetObjectData( '<NEPMD_CHANGE_STARTUPDIR>',,
                        'ICONFILE='CallDir'\ico\recomp.ico;');
 rc = SysSetObjectData( '<NEPMD_TOGGLE_DEFASSOCS>',,
                        'ICONFILE='CallDir'\ico\recomp.ico;');

 rc = SysSetObjectData( '<NEPMD_RECOMPILE_NEW>',,
                        'ICONFILE='CallDir'\ico\recomp.ico;');
 rc = SysSetObjectData( '<NEPMD_CHECK_USER_MACROS>',,
                        'ICONFILE='CallDir'\ico\recomp.ico;');

 rc = SysSetObjectData( '<NEPMD_VIEW_NEUSR>',,
                        'ICONFILE='CallDir'\ico\help.ico;');
 rc = SysSetObjectData( '<NEPMD_VIEW_NEPRG>',,
                        'ICONFILE='CallDir'\ico\help.ico;');

 rc = SysDestroyObject( CallDir'\..\..\srccopy.txt');

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

