/****************************** Module Header *******************************
*
* Module Name: warpin.env.cmd
*
* TOOLENV batchfile to setup the environment for usage of the
* WarpIn WPI compiler and WarpIn installer.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: warpin.env.cmd,v 1.1 2002-04-21 13:15:24 cla Exp $
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


 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 rc = 0;

 DO UNTIL (1)

    /* search Warpin executable */
    PARSE VALUE SysIni( , 'WarpIN', 'Path') WITH WarpInPath'0'x;
    IF (WarpInPath = '') THEN
    DO
       SAY 'error: WarpIn is not installed.';
       rc = ERROR.PATH_NOT_FOUND;
       LEAVE;
    END;

    /* extend environment */
    '@SET PATH='WarpInPath';';
    '@SET BEGINLIBPATH='WarpInPath';';

 END;

 EXIT( rc);

