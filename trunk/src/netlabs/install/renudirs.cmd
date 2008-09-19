/****************************** Module Header *******************************
*
* Module Name: renudirs.cmd
*
* Syntax: renudirs [NEPMD]
*
* Helper batch for to rename some user's subdirectories
*
* These directories are named according to following scheme:
*
*    ex    -> ex_yyyy-mm-dd        (yyyy = year, mm = month, dd = day)
*    mode  -> mode_yyyy-mm-dd      (long filename support required)
*    bin   -> bin_yyyy-mm-dd
*
* If a directory name already exists, a counter is added:
*
*    ex_yyyy-mm-dd
*    ex_yyyy-mm-dd_1
*    ex_yyyy-mm-dd_2
*
* New empty directories were created on success and NEPMD.INI will be copied.
*
* This is executed by the installer to ensure that a newly installed NEPMD
* uses its own macros at first. Otherwise incompatibities may happen, because
* EPM's behavior depends not only on the macros, but also on the library and
* the configuration files. In the worst case, one would end up with a not
* starting EPM, so renaming the files automatically is the best solution.
*
* After installation, merge your previous changes/additions with the newly
* installed files of the netlabs tree.
*
* When no incompatibilies exist, the .ex files can be recreated by a
* RecompileNew command, because the user's macro sources were not renamed.
* For other files, and alternatively for the .ex files, the old user files
* may be copied to the new empty directories.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: renudirs.cmd,v 1.3 2008-09-19 19:51:41 aschn Exp $
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
 GlobalVars = 'env TRUE FALSE Redirection RootDir UserDir SubDirs' ||,
              ' fQuiet ERROR.';

 /* ###################### Configurable part starts ################### */
 /* User subdirs to process */
 SubDirs = 'ex mode bin'
 /* ###################### Configurable part ends ##################### */

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
 Help1StartLine  = 7
 Help1EndLine    = 26
 Help2StartLine  = 28
 Help2EndLine    = 34
 fQuiet = TRUE;
 rc = ERROR.NO_ERROR;
 ErrorQueueName = VALUE( 'NEPMD_RXQUEUE',, env);
 ErrorMessage   = '';
 RenamedDirs = ''

 /* make sure we are called on purpose */
 ARG Parm .;
 IF Parm = 'NEPMD' THEN
    fQuiet = TRUE;
 ELSE
    fQuiet = FALSE;

 IF \fQuiet THEN
 DO
    SAY;
    DO l = Help1StartLine TO Help1EndLine
       SAY SUBSTR( SOURCELINE( l), 3);
    END;
    SAY;
    SAY 'Do you want to continue? (Y/N)';
    PULL Answer;
    Answer = STRIP( Answer);
    IF (ANSWER <> 'Y') THEN
       SIGNAL Halt;
 END;

 /* get default dir values, depending on the path of this file */
 PARSE Source . . CallName;
 CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1);
 NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1);
 RootDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1);
 UserDir    = RootDir'\'UserDirName;

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
             rcx = SysFileTree Home, 'Found.', 'DO', '*+--*'  /* ADHRS */
             IF (rcx = 0) THEN
                IF (Found.0 > 0) THEN
                DO
                   UserDir = Home'\'UserDirName
                   LEAVE
                END
          END
       END

    END

    /* get date string */
    IsoDate = GetIsoDate();

    /* process dirs */
    DO i = 1 to WORDS( SubDirs)
       SubDir.i = WORD( SubDirs, i);
       OldDir = UserDir'\'SubDir.i;

       /* check for existing dir */
       IF \DirExist( OldDir) THEN
          ITERATE;

       /* check for contained files */
       IF \TreeContainsFiles( OldDir) THEN
          ITERATE;

       /* check for contained NEPMD.INI */
       fContainsNepmdIni = FALSE;
       IF FileExist( OldDir'\NEPMD.INI') THEN
          fContainsNepmdIni = TRUE;

       NewDirName = SubDir.i'_'IsoDate;
       NewDir     = UserDir'\'NewDirName;

       /* check for already existing dir name */
       c = 0
       DO WHILE DirExist( NewDir)
          /* append counter to dir name */
          c = c + 1
          NewDirName = SubDir.i'_'IsoDate'_'c;
          NewDir     = UserDir'\'NewDirName;
       END;

       /* rename dir */
       IF \fQuiet THEN
          SAY 'Renaming 'OldDir' -> 'NewDirName;
       rc = RenameDir( OldDir, NewDirName);

       /* recreate empty dirs on success */
       IF (rc = 0) THEN
       DO
          rcx = SysMkDir( OldDir);
          RenamedDirs = STRIP( RenamedDirs SubDir.i);

          /* Copy old NEPMD.INI back */
          IF ((rcx = 0) & fContainsNepmdIni) THEN
          DO
             /* Reset file attributes and copy */
             rcx = SysFileTree( NewDir'\NEPMD.INI', 'Found.', 'FO', '*****', '-----')
             IF \fQuiet THEN
                SAY 'Copying 'NewDir'\NEPMD.INI -> 'OldDir'\NEPMD.INI';
             rcx = SysCopyObject( NewDir'\NEPMD.INI', OldDir)
             /*'copy 'NewDir'\NEPMD.INI 'OldDir'\NEPMD.INI'*/
          END
       END;

       /* check for error */
       IF (rc <> 0) THEN
          LEAVE;
    END;

 END;

 /* report error (or success) message */
 SELECT
    /* no error here */
    WHEN (rc = 0) THEN
    DO
       IF \fQuiet THEN
       DO
          IF (RenamedDirs = '') THEN
          DO
             SAY;
             SAY 'No file contained, no directory renamed.';
          END;
          ELSE
          DO
             /* show rest of help text on success */
             SAY;
             DO l = Help2StartLine TO Help2EndLine
                SAY SUBSTR( SOURCELINE( l), 3);
             END;
          END;
       END;
    END;

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
       'PAUSE';
    END;
 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
RenameDir: PROCEDURE
 PARSE ARG OldDir, NewDirName;
 rc = ERROR.NO_ERROR;

 fSuccess = SysSetObjectData( OldDir, 'TITLE='NewDirName';');
 IF fSuccess THEN
    rc = 0;
 ELSE
    /* try the OS/2 command to get a useful rc */
    'ren' OldDir NewDirName;

 RETURN( rc);

/* ------------------------------------------------------------------------- */
GetIsoDate: PROCEDURE
 PARSE VALUE DATE( 'S') WITH yyyy +4 mm +2 dd;

 RETURN( yyyy'-'mm'-'dd);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName;

 /*RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') <> '');*/

 /* Find also hidden files */
 Found.0 = 0;
 rcx = SysFileTree( FileName, 'Found.', 'FO');

 RETURN( Found.0 > 0);

/* ------------------------------------------------------------------------- */
DirExist: PROCEDURE
 PARSE ARG DirName;

 Found.0 = 0;
 rcx = SysFileTree( DirName, 'Found.', 'DO');

 RETURN( Found.0 > 0);

/* ------------------------------------------------------------------------- */
TreeContainsFiles: PROCEDURE
 PARSE ARG DirName;

 Found.0 = 0;
 rcx = SysFileTree( DirName'\*', 'Found.', 'FOS');

 RETURN( Found.0 > 0);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

