/****************************** Module Header *******************************
*
* Module Name: setinit.cmd
*
*   Syntax:  setinit [<dir>|DELETE:]
*
*   This program sets initialization data to NEPMD.INI, just as if
*   NEPMD was installed in the DEBUG directory. This way all programs
*   in DEBUG\NETLABS\BIN will think they are running on a true installed
*   NEPMD version
*
*   NOTE: Running this script will of course corrupt any true NEPMD
*         installation! To make a true installation work again,
*         you will have to reinstall the base NEPMD package again
*         to restore the INI vars to it.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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

 /* load REXX util */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* defaults */
 IniApp         = 'NEPMD';
 IniKeyPath     = 'RootDir';

 /* determine call directory */
 PARSE SOURCE . . CallName;
 CallDir = LEFT( CallName, LASTPOS( '\', CallName) - 1);
 BaseDir = LEFT( CallDir,  LASTPOS( '\', CallDir)  - 1);

 /* other directory specified ? */
 PARSE ARG Parm .;
 SELECT
    WHEN (POS( TRANSLATE( Parm), 'DELETE:') = 1) THEN
       InstDir = 'DELETE:';

    WHEN (Parm \= '') THEN
       InstDir = Parm;

    OTHERWISE
       InstDir = BaseDir'\debug';
 END;


 /* display the vaule just set */
 rc = SysIni(, IniApp, IniKeyPath, InstDir);
 IF (rc = 'ERROR:') THEN
    CurrentPath = '<not defined>';
 ELSE
    CurrentPath = SysIni(, IniApp, IniKeyPath);

 SAY 'Install path is set to:' CurrentPath;

