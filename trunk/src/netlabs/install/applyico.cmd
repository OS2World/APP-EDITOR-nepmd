/****************************** Module Header *******************************
*
* Module Name: applyico.cmd
*
* Helper batch for to attach
*  - operating system dependant icons to the folders of the Netlabs EPM
*    Distribution, as WarpIn can currently not determine the operatin system
*    version (Warp3 / Warp 4 / eComStation) during installation.
*  - a new icon to all EPM icons in the system
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: applyico.cmd,v 1.6 2002-11-05 13:43:48 aschn Exp $
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
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;
 env = 'OS2ENVIRONMENT';

 PARSE VALUE TRANSLATE( VALUE('PATH',,env)) WITH '\OS2;' -2 BootDrive +2;
 EcsFlagFile = BootDrive'\wisemachine.fit';

 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir  = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NepmdDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir  = LEFT( NepmdDir,   LASTPOS( '\', NepmdDir) - 1);
 IconDir  = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);

 /* determine operating system version */
 SELECT
    WHEN (SysOs2Ver() < '2.40')    THEN Type = '3';
    WHEN (FileExist( EcsFlagFile)) THEN Type = 'e';
    OTHERWISE                           Type = '4';
 END;

 /* set icon for folders */
 FolderIconSetup = 'ICONFILE='CallDir'\ico\folder'Type'.ico;ICONNFILE=1,'CallDir'\ico\folder'Type'o.ico;';
 DO WHILE (FolderObjectIdList \= '')
    PARSE VAR FolderObjectIdList ThisObject FolderObjectIdList;
    rc = SysSetObjectData( ThisObject, FolderIconSetup);
 END;

 /* set icon for myepm folder */
 rc = SysSetObjectData( BaseDir'\myepm', FolderIconSetup);

 /* set  EPM program objects */
 rc = SysSetObjectData( '<NEPMD_EXECUTE>', 'ICONFILE='CallDir'\ico\nepmd.ico;');
 rc = SysSetObjectData( '<WP_EPM>',,
                        'ICONFILE='CallDir'\ico\epm4.ico;');

 EXIT( 0);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName
 rc = SysFileTree( FileName, 'Found', 'FO', '*-***')

 RETURN( Found.0 > 0);

