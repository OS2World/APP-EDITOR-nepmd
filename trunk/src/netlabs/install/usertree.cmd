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
* $Id: usertree.cmd,v 1.7 2002-11-04 20:57:44 cla Exp $
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

 UserDirName = 'myepm';
 UserDirList = 'bar bin bmp ex mode macros ndx autolink';

 /* ################################################################################# */


 /* initialize */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;

 FolderId      = '<NEPMD_FOLDER>';
 ObjectIdStart = '<NEPMD_';
 ObjectIdEnd   = '_SHADOW>';


 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1);

 /* create MYEPM shadow in NEPMD folder */
 FullPath = BaseDir'\'UserDirName;
 rcx = SysMkDir( FullPath);
 ObjectId = ObjectIdStart''TRANSLATE( UserDirName)''ObjectIdEnd;
 rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='FullPath';OBJECTID='ObjectId';', 'U');
 rcx = SysSetObjectData( FullPath, 'DEFAULTVIEW=TREE;');

 /* create directories here - ignore errors */
 DO WHILE (UserDirList \= '')
    PARSE VAR UserDirList ThisDir UserDirList;
    FullPath = BaseDir'\'UserDirName'\'ThisDir;
    rcx = SysMkDir( FullPath);
    rcx = SysSetObjectData( FullPath, 'DEFAULTVIEW=ICON;');
 END;

 EXIT( 0);

