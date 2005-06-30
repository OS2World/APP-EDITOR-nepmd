/****************************** Module Header *******************************
*
* Module Name: applyico.cmd
*
* Helper batch for to attach
*  - operating system dependant icons to the folders of the Netlabs EPM
*    Distribution, as WarpIn can currently not determine the operatin system
*    version (Warp3 / Warp 4 / eComStation) during installation.
*  - disabled: a new icon to all EPM icons in the system
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: applyico.cmd,v 1.7 2005-06-30 21:35:58 aschn Exp $
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

 /* ##############   Maintainer: modify object id list here ######################## */

 FolderObjectIdList = '<NEPMD_FOLDER> <NEPMD_SAMPLES_FOLDER>';

 /* ################################################################################# */


 /* initialize */
 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 CALL SysLoadFuncs;
 GlobalVars = 'Sep'
 env = 'OS2ENVIRONMENT';
 Sep = '01'x
 EcsFlag = 1  /* default, if syslevel.os2 not found, is to use eCS icons */

 /* Get BootDrive */
 IF \RxFuncQuery( 'SysBootDrive') THEN
    BootDrive = SysBootDrive()
 ELSE
    PARSE UPPER VALUE VALUE( 'PATH', env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

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

 /* get the base directory of the NEPMD installation */
 PARSE SOURCE . . CallName;
 CallDir  = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NepmdDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir  = LEFT( NepmdDir,   LASTPOS( '\', NepmdDir) - 1);
 IconDir  = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);

 /* determine operating system version */
 SELECT
    WHEN (SysOs2Ver() < '2.40')    THEN Type = '3';
    WHEN (EcsFlag = 1)             THEN Type = 'e';
    OTHERWISE                           Type = '4';
 END;

 /* set icon for folders */
 FolderIconSetup = 'ICONFILE='CallDir'\ico\folder'Type'.ico;' ||,
                   'ICONNFILE=1,'CallDir'\ico\folder'Type'o.ico;';
 DO WHILE (FolderObjectIdList \= '')
    PARSE VAR FolderObjectIdList ThisObject FolderObjectIdList;
    rc = SysSetObjectData( ThisObject, FolderIconSetup);
 END;

 /* set icon for myepm folder */
 rc = SysSetObjectData( BaseDir'\myepm', FolderIconSetup);


 /* set  EPM program objects */

/* Disabled, because the icon is not used here (already added as resource to the loader).
 * rc = SysSetObjectData( '<NEPMD_EXECUTE>', 'ICONFILE='CallDir'\ico\nepmd.ico;');
 */

/* Disabled, better don't touch the standard EPM object.
 * rc = SysSetObjectData( '<WP_EPM>',,
 *                        'ICONFILE='CallDir'\ico\epm4.ico;');
 */

 EXIT( 0);

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

