/****************************** Module Header *******************************
*
* Module Name: usertree.cmd
*
* Helper batch for to create all directories of the personal subdirectory
* tree (a WarpIn package cannot include empty directories)
*
* This program is intended to be called only during installation of the
* Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: usertree.cmd,v 1.1 2002-04-19 10:26:07 cla Exp $
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
 UserDirList = 'bmp ex keywords macros';

 /* ################################################################################# */


 /* initialize */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;

 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1);

 /* create directories here - ignore errors */
 rcx = SysMkDir( BaseDir'\'UserDirName);
 DO WHILE (UserDirList \= '')
    PARSE VAR UserDirList ThisDir UserDirList;
    rcx = SysMkDir( BaseDir'\'UserDirName'\'ThisDir);
 END;

 EXIT( 0);

