/****************************** Module Header *******************************
*
* Module Name: saveold.cmd
*
* Helper batch for to backup an existing EPM of C:\OS2\APPS
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: saveold.cmd,v 1.1 2002-04-22 16:47:55 cla Exp $
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
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;
 env = 'OS2ENVIRONMENT';

 PARSE VALUE TRANSLATE( VALUE('PATH',,env)) WITH '\OS2;' -2 BootDrive +2;

 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir   = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NepmdDir  = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 BaseDir   = LEFT( NepmdDir,   LASTPOS( '\', NepmdDir) - 1);
 BackupDir = BaseDir'\backup';

 DO UNTIL (1)
    /* check for old EPM */
    IF (\FileExist( BootDrive'\OS2\APPS\EPM.EXE')) THEN
       LEAVE;

    /* get a list file */
    ListFile = SysTempFilename( VALUE( 'TMP',,'OS2ENVIRONMENT')'\nepmd.???');

    /* now backup and remove */
    SAY 'Backing up old EPM files to directory' BackupDir;
    rc = BackupFiles( 'C:\OS2\EPM*',       BackupDir'\OS2',      ListFile);
    IF (rc \= 0) THEN LEAVE;
    rc = BackupFiles( 'C:\OS2\APPS\*.ex',  BackupDir'\OS2\APPS', ListFile);
    IF (rc \= 0) THEN LEAVE;
    rc = BackupFiles( 'C:\OS2\APPS\*.bmp', BackupDir'\OS2\APPS', ListFile);
    IF (rc \= 0) THEN LEAVE;
    rc = BackupFiles( 'C:\OS2\ETK*',       BackupDir'\OS2',      ListFile);
    IF (rc \= 0) THEN LEAVE;

    /* now delete files, ignore errors here */
    SAY 'Removing old EPM files';
    DO WHILE (LINES( ListFile))
       ThisFile = STRIP( LINEIN( ListFile));
       IF (ThisFile = '') THEN ITERATE;
       rcx = SysFileTree( ThisFile, 'File.', 'F',,'-----');
       rcx = SysFileDelete( ThisFile);
    END;
    rcx = SysFileDelete( ListFile);

 END;

 EXIT( 0);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');


/* ------------------------------------------------------------------------- */
BackupFiles: PROCEDURE
 PARSE ARG FileName, BackupDir, ListFile;

 DO UNTIL (1)

    /* append filenames to listfile */
    '@DIR' FileName ' /S /F >>' ListFile '2>NUL';

    /* copy the files */
    '@XCOPY' FileName BackupDir'\ /H/O/T/S/R >NUL 2>&1';

 END;

 RETURN( rc);

