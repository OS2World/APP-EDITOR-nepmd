/****************************** Module Header *******************************
*
* Module Name: remex.cmd
*
* Syntax: remex [NEPMD]
*
* Helper batch for to backup and delete old user *.ex files
*
* Either a zip file (if ZIP.EXE found in PATH) or an xcopied tree is created
* in NEPMD\backup. The name of the zip file is ex_old.zip.
*
* After the backup proceeded successful, the old files will be deleted.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: remex.cmd,v 1.2 2006-11-04 16:29:46 aschn Exp $
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
/* Some header lines are used as help text */

 /* initialize */
 '@ECHO OFF';
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;
 env = 'OS2ENVIRONMENT';
 TRUE  = (1 = 1);
 FALSE = (0 = 1);
 Redirection = '>NUL 2>&1';
 SIGNAL ON HALT NAME HALT
 GlobalVars = 'env TRUE FALSE Redirection BackupDir fUseZip fDelete' ||,
              ' fDeleteList fRecoursive ERROR.';

 /* some OS/2 Error codes */
 ERROR.NO_ERROR           =   0;
 ERROR.INVALID_FUNCTION   =   1;
 ERROR.FILE_NOT_FOUND     =   2;
 ERROR.PATH_NOT_FOUND     =   3;
 ERROR.ACCESS_DENIED      =   5;
 ERROR.NOT_ENOUGH_MEMORY  =   8;
 ERROR.INVALID_FORMAT     =  11;
 ERROR.INVALID_DATA       =  13;
 ERROR.NO_MORE_FILES      =  18;
 ERROR.WRITE_FAULT        =  29;
 ERROR.READ_FAULT         =  30;
 ERROR.SHARING_VIOLATION  =  32;
 ERROR.GEN_FAILURE        =  31;
 ERROR.INVALID_PARAMETER  =  87;
 ERROR.ENVVAR_NOT_FOUND   = 204;

 /* INI app names and keys of NEPMD project from OS2.INI, defined in nepmd.h */
 NEPMD_INI_APPNAME             = "NEPMD"
 NEPMD_INI_KEYNAME_LANGUAGE    = "Language"
 NEPMD_INI_KEYNAME_ROOTDIR     = "RootDir"
 NEPMD_INI_KEYNAME_USERDIR     = "UserDir"
 NEPMD_INI_KEYNAME_USERDIRNAME = "UserDirName"
 NEPMD_INI_KEYNAME_USEHOME     = "UseHomeForUserDir"

 /* default values of NEPMD installation */
 UserDirName = 'myepm'
 fUseHome    = FALSE;

 /* defaults and further consts */
 HelpStartLine  = 7
 HelpEndLine    = 12
 fDelete = TRUE;
/* fDelete = FALSE;*/
 fDeleteList = TRUE;
 fRecoursive = FALSE;  /* recoursive not required */
 fUseZip = TRUE;
 rc = ERROR.NO_ERROR;
 ErrorQueueName  = VALUE( 'NEPMD_RXQUEUE', , env);
 ErrorMessage    = '';

 /* make sure we are called on purpose */
 ARG Parm .;
 IF (Parm \= 'NEPMD') THEN
 DO
    SAY;
    DO l = HelpStartLine TO HelpEndLine
       SAY SUBSTR( SOURCELINE( l), 3);
    END
   SAY;
   SAY 'Do you want to continue? (Y/N)';
   PULL Answer;
   Answer = STRIP( Answer);
   IF (ANSWER <> 'Y') THEN
      EXIT( ERROR.GEN_FAILURE);
 END;

 /* Get BootDrive */
 IF \RxFuncQuery( 'SysBootDrive') THEN
    BootDrive = SysBootDrive()
 ELSE
    PARSE UPPER VALUE VALUE( 'PATH', , env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

 /* get default dir values, depending on the path of this file */
 PARSE Source . . CallName;
 CallDir   = LEFT( CallName, LASTPOS( '\', CallName) - 1);
 NepmdDir  = LEFT( CallDir,  LASTPOS( '\', CallDir) - 1);
 RootDir   = LEFT( NepmdDir, LASTPOS( '\', NepmdDir) - 1);
 BackupDir = RootDir'\backup';
 UserDir   = RootDir'\'UserDirName;

 /* get dir values from OS2.INI */
 DO UNTIL (TRUE)

    /* get the base directory of the NEPMD installation */
    PARSE VALUE SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_ROOTDIR) WITH RootDir'00'x;
    IF (RootDir = 'ERROR:') THEN
    DO
       /* don't report error from here, use default values instead */
       /*
       rc = ERROR.PATH_NOT_FOUND;
       ErrorMessage = 'Error: NEPMD configuration not found.';
       */
       LEAVE;
    END;

    /* get user directory */
    UserDir = RootDir'\'UserDirName
    DO 1
       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USERDIR)
       IF (next <> 'ERROR:') then
       DO
          next = STRIP( next, 't', '00'x)
          IF (next > '') THEN
          DO
             UserDir = next
             LEAVE
          END
       END

       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USERDIRNAME)
       IF (next <> 'ERROR:') then
       DO
          next = STRIP( next, 't', '00'x)
          IF (next > '') THEN
             UserDirName = next
       END

       next = SysIni( 'USER', NEPMD_INI_APPNAME, NEPMD_INI_KEYNAME_USEHOME)
       IF (next <> 'ERROR:') then
       DO
          next = STRIP( next, 't', '00'x)
          IF (next > '') THEN
             fUseHome = next
       END
       IF (fUseHome) THEN
       DO
          Home = VALUE( 'HOME', , env)
          IF Home > '' THEN
          DO
             call SysFileTree Home, 'Found.', 'DO', '*+--*'  /* ADHRS */
             IF (Found.0 > 0) THEN
             DO
                UserDir = Home'\'UserDirName
                LEAVE
             END
          END
       END

    END

    BackupDir = RootDir'\backup';

    /* check for user ex dir */
    UserExFiles = UserDir'\ex\*.ex'
    IF (\FileExist( UserExFiles)) THEN
    DO
       /* don't report error from here */
       ErrorMessage = 'No files found for "'UserExFiles'".'
       LEAVE;
    END;

    /* get a list file */
    ListFile = SysTempFilename( VALUE( 'TMP', , 'OS2ENVIRONMENT')'\nepmd.???');
    IF (\fDeleteList) THEN
       SAY 'Using ListFile "'ListFile'".';

    /* check if ZIP.EXE is in PATH */
    IF (fUseZip = TRUE) THEN
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
    SAY 'Backing up old user *.ex files to directory' BackupDir;

    rc = BackupFiles( UserExFiles, BackupDir'\'UserDirName'\ex', ListFile);
    IF (rc \= 0) THEN fDelete = FALSE;

    /* now delete files, ignore errors here */
    IF (fDelete = TRUE) THEN
       SAY 'Removing old user *.ex files';
    ELSE
       SAY 'Test mode: listing old user *.ex files';

    DO WHILE (LINES( ListFile))
       ThisFile = STRIP( LINEIN( ListFile));
       IF (ThisFile = '') THEN ITERATE;

       rcx = SysFileTree( ThisFile, 'File.', 'F',,'-----');

       SAY ThisFile;
       IF (fDelete = TRUE) THEN
          rcx = SysFileDelete( ThisFile);

       rc = ERROR.NO_ERROR;
    END;

    CALL STREAM ListFile, 'C', 'CLOSE';
    IF (fDeleteList = TRUE) THEN
       rcx = SysFileDelete( ListFile);

 END;

 /* report error message */
 SELECT
    /* no error here */
    WHEN (rc = 0) THEN NOP;

    /* called by frame program: insert error */
    /* message into standard REXX queue     */
    WHEN (ErrorQueueName \= '') THEN
    DO
       rcx = RXQUEUE( 'SET', ErrorQueueName);
       PUSH ErrorMessage;
    END;

    /* called directly, method */
    OTHERWISE
    DO
       SAY ErrorMessage;
       '@PAUSE';
    END;
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
    'DIR' FileName DirOptions '>>' ListFile '2>NUL';

    /* copy the files */
    IF fUseZip = 0 THEN
       'XCOPY' FileName DestDir'\' XcopyOptions Redirection;
    ELSE
    DO
       SavedDir = DIRECTORY();
       CALL DIRECTORY BackUpDir;
       'ZIP' ZipOptions BackupDir'\ex_old' FileName Redirection;
       CALL DIRECTORY SavedDir;
    END;

 END;

 RETURN( rc);

/* ------------------------------------------------------------------------- */
HALT:
 SAY;
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

