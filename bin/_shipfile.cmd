/****************************** Module Header *******************************
*
* Module Name: _shipfile.cmd
*
* Helper batch for to ship a file from the developer tree to a
* local NEPMD installation for testing purposes.
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

 /* check parms */
 PARSE ARG SourceFile SubPath;
 SourceFile = STRIP( SourceFile);
 SubPath    = STRIP( SubPath);
 IF (SubPath = '') THEN
 DO
    SAY 'error: no target NEPMD subpath given! Cannot ship file' SourceFile;
    RETURN( 87); /* ERROR.INVALID_PARAMETER */
 END;

 /* determine install path of NEPMD */
 PARSE VALUE SysIni(, 'NEPMD', 'Path') WITH InstallPath'0'x;
 IF (InstallPath = '') THEN
 DO
    SAY 'error: NEPMD not installed! Cannot ship file' SourceFile;
    RETURN( 3); /* ERROR.PATH_NOT_FOUND */
 END;

 /* determine target path and replace file */
 Targetpath = InstallPath'\'SubPath;
 IF (FileExist( Targetpath'\'FILESPEC( 'N', SourceFile))) THEN
    Opt = '/U';
 ELSE
    Opt = '/A';

 '@CALL REPLACE' SourceFile Targetpath Opt;

 /* ignore error 1 (means: no update required) */
 IF (rc = 1) THEN
    rc = 0;

 EXIT( rc);


/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');

