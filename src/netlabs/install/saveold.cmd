/****************************** Module Header *******************************
*
* Module Name: saveold.cmd
*
* Syntax: saveold
*
* Helper batch for to backup and delete an existing EPM of ?:\OS2\APPS
*
* This program is intended to be called by NLSETUP.EXE only during
* installation of the Netlabs EPM Distribution. It can also be used
* separately.
*
* Either a zip file (if ZIP.EXE found in PATH) or an xcopied tree is created
* in NEPMD\backup. The name of the zip file is EPM_old.zip.
*
* After the backup (as a minimum: the binaries) proceeded successful, the
* old files will be deleted.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: saveold.cmd,v 1.2 2005-03-06 09:24:37 aschn Exp $
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
 TRUE  = (1 = 1);
 FALSE = (0 = 1);
 Redirection = '>NUL 2>&1';
 fDelete = 1;
 fDeleteList = 1;
 fRecoursive = 0;  /* recoursive not required */
 fUseZip = 1;

 PARSE VALUE TRANSLATE( VALUE('PATH',,env)) WITH '\OS2;' -2 BootDrive +2;

 /* get the base directory of the NEPMD installation */
 PARSE Source . . CallName;
 CallDir   = LEFT( CallName, LASTPOS( '\', CallName) - 1);
 NepmdDir  = LEFT( CallDir,  LASTPOS( '\', CallDir) - 1);
 BaseDir   = LEFT( NepmdDir, LASTPOS( '\', NepmdDir) - 1);
 BackupDir = BaseDir'\backup';

 GlobalVars = 'env TRUE FALSE Redirection BackupDir fUseZip fDelete fDeleteList fRecoursive';

 DO UNTIL (TRUE)
    /* check for old EPM */
    IF (\FileExist( BootDrive'\OS2\APPS\EPM.EXE')) THEN
       LEAVE;

    /* get a list file */
    ListFile = SysTempFilename( VALUE( 'TMP',,'OS2ENVIRONMENT')'\nepmd.???');

    /* get EPM.INI */
    next = SysIni( 'USER', 'EPM', 'EPMIniPath');
    IF next = 'ERROR:' THEN
       EpmIni = BootDrive'OS2\EPM.INI';
    ELSE
       EpmIni = STRIP( next, 'T', '00'x);
    /* remove attribs, except A */
    rc = SysFileTree( EpmIni, 'EpmIni.', 'FO',,'*----');

    /* Check if ZIP.EXE is in PATH */
    IF fUseZip = 1 THEN
    DO
       next = SysSearchPath( 'PATH', 'ZIP.EXE');
       fUseZip = (next > '');
    END;

    /* create backup path */
    rest = BackupDir;
    last = '';
    i = 0;
    /* strip \\machine\resource for UNC filename */
    IF LEFT( BackupDir, 2) = '\\' THEN
    DO
       p1 = POS( '\', BackupDir, 3);
       p2 = POS( '\', BackupDir, p1 + 1);
       last = LEFT( BackupDir, MAX( p2 - 1, 0));  /* last: without trailing \ */
       rest = SUBSTR( BackupDir, p2 + 1);         /* rest: without leading \ */
    END;
    /* strip drive for full filename */
    IF SUBSTR( BackupDir, 2, 2) = ':\' THEN
       PARSE VAR BackupDir last'\'rest;  /* last: without trailing \, rest: without leading \ */
    /* create entire tree to ensure it exists */
    DO WHILE rest <> ''
       PARSE VAR rest next'\'rest;
       last = last'\'next;
       CALL SysMkDir( last);
    END;

    /* now backup and remove */
    SAY 'Backing up old EPM files to directory' BackupDir;

    IF EPMIni \= '' THEN
       rc = BackupFiles( EPMIni,                         BackupDir'\OS2',          ListFile);
    rc = BackupFiles( BootDrive'\OS2\APPS\EPM*',         BackupDir'\OS2\APPS',     ListFile);
    IF (rc \= 0) THEN fDelete = 0;
    rc = BackupFiles( BootDrive'\OS2\APPS\DLL\ETK*.DLL', BackupDir'\OS2\APPS\DLL', ListFile);
    IF (rc \= 0) THEN fDelete = 0;
    rc = BackupFiles( BootDrive'\OS2\APPS\DLL\EPM*.DLL', BackupDir'\OS2\APPS\DLL', ListFile);
    rc = BackupFiles( BootDrive'\OS2\APPS\*.EX',         BackupDir'\OS2\APPS',     ListFile);
    IF (rc \= 0) THEN fDelete = 0;
    rc = BackupFiles( BootDrive'\OS2\APPS\*.E',          BackupDir'\OS2\APPS',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\APPS\*.ERX',        BackupDir'\OS2\APPS',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\APPS\ACTIONS.LST',  BackupDir'\OS2\APPS',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\APPS\*.BMP',        BackupDir'\OS2\APPS',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\HELP\EPM*.HLP',     BackupDir'\OS2\HELP',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\HELP\ETK*.HLP',     BackupDir'\OS2\HELP',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\HELP\TREE.HLP',     BackupDir'\OS2\HELP',     ListFile);
    rc = BackupFiles( BootDrive'\OS2\HELP\REFLOW.HLP',   BackupDir'\OS2\HELP',     ListFile);
    /* Note: \OS2\EPM* would process files in \OS2\ARCHIVES */

    IF fDelete = 1 THEN
    DO
       /* now delete files, ignore errors here */
       SAY 'Removing old EPM files';
       DO WHILE (LINES( ListFile))
          ThisFile = STRIP( LINEIN( ListFile));
          IF (ThisFile = '') THEN ITERATE;
          /* don't remove EPM.INI */
          IF TRANSLATE( filespec( 'N', THISFILE)) = 'EPM.INI' THEN ITERATE;
          rcx = SysFileTree( ThisFile, 'File.', 'F',,'-----');
          rcx = SysFileDelete( ThisFile);
       END;
       CALL STREAM ListFile, 'C', 'CLOSE';
       IF fDeleteList = 1 THEN
          rcx = SysFileDelete( ListFile);
       rc = 0;
    END
    ELSE
       rc = 1;
 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName;

 RETURN(STREAM( Filename, 'C', 'QUERY EXISTS') > '');

/* ------------------------------------------------------------------------- */
BackupFiles: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG FileName, DestDir, ListFile;

 IF fRecoursive THEN      /* recoursive not required */
 DO
   DirOptions   = '/S /F /A-D';
   XcopyOptions = '/H/O/T/S/R';
   ZipOptions   = '-rSD';
 END
 ELSE
 DO
   DirOptions   = '/F /A-D';
   XcopyOptions = '/H/O/T/R';
   ZipOptions   = '-SD';
 END;

 DO UNTIL (TRUE)

    /* check if filespec exists to avoid xcopy beeps */
    IF \FileExist( FileName) THEN
       LEAVE;

    /* append filenames to listfile */
    '@DIR' FileName DirOptions '>>' ListFile '2>NUL';

    /* copy the files */
    IF fUseZip = 0 THEN
       '@XCOPY' FileName DestDir'\' XcopyOptions Redirection;
    ELSE
    DO
       SavedDir = DIRECTORY();
       CALL DIRECTORY BackUpDir;
       '@ZIP' ZipOptions BackupDir'\EPM_old' FileName Redirection;
       CALL DIRECTORY SavedDir;
    END;

 END;

 RETURN( rc);

