/****************************** Module Header *******************************
*
* Module Name: _srccopy action flagfile basedir targetdir
*
*   action    - CHECK: check all files in source dir for being newer
*                      if outdated, delete flagfile
*               COPY:  copy all files to target dir and write flagfile
*   flagfile  - zero byte file being written on copy
*   basedir   - a directory within the CVS tree part
*   targetdir - a directory below subdirectory compile
*
* Helper batch for to copy sources to compile directory without CVS
* directories in order to prevent then from being packed
*
* NOTE: targetdir must exist !
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: _srccopy.cmd,v 1.3 2002-09-19 18:09:19 cla Exp $
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

 /* init */
 '@ECHO OFF';
 NUMERIC DIGITS 20;
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 call SysLoadFuncs;

 DO UNTIL (1)

    /* get parm */
    PARSE ARG Action .;
    SELECT
       WHEN (Action = 'CHECK') THEN
       DO
          PARSE ARG . FlagFile SourceDir
          FlagStamp = FileStamp( FlagFile);
       END;

       WHEN (Action = 'COPY')  THEN
       DO
          PARSE ARG . FlagFile SourceDir TargetDir;
          'TYPE NUL >' FlagFile;
       END;

       OTHERWISE
       DO
          SAY 'error: invalid action specified for srccopy';
          rc = 87;
          LEAVE;
       END;
    END;

    /* check directories */
    CheckDir = GetDirName( SourceDir);
    IF (CheckDir = '') THEN
    DO
       SAY 'source directory' SourceDir 'not found.';
       EXIT( 3);
    END;
    SourceDir = CheckDir;

    /* get all source subdirectories */
    rc = SysFileTree( SourceDir'\*', 'Dir.', 'DOS');
    IF (rc \= 0) THEN
    DO
       SAY 'error in SysFileTree, rc='rc;
       EXIT(rc);
    END;

    /* copy these */
    SourceDirLen = LENGTH( SourceDir);
    DO d = 1 TO Dir.0

       /* don't copy CVS dirs */
       IF (FILESPEC( 'N', Dir.d) = 'CVS') THEN ITERATE;

       rc = SysFileTree( Dir.d'\*', 'File.', 'FO');
       DO f = 1 TO File.0
          SELECT
             WHEN (Action = 'CHECK') THEN
             DO
                /* delete flagfile */
                ThisFileStamp = FileStamp( File.f);
                IF (ThisFileStamp > FlagStamp) THEN
                   rcx = SysFileDelete( FlagFile)
             END;

             WHEN (Action = 'COPY')  THEN
             DO
                /* copy file */
                ThisTargetFile = TargetDir''SUBSTR( File.f, SourceDirLen + 1);
                ThisTargetDir  = LEFT( ThisTargetFile,   LASTPOS( '\', ThisTargetFile) - 1);
                rc = XcopyFile( File.f, ThisTargetDir);
             END;

             OTHERWISE NOP;
          END;
       END;
    END;

 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
XcopyFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG SourceFile, TargetDir;
 Redirection = '>NUL 2>&1';

 rcx = SysMkDir( TargetDir);
 'COPY' SourceFile TargetDir Redirection;

 RETURN( '');

/* -------------------------------------------------------------------------- */
GetDirName: PROCEDURE
 PARSE ARG Name

 /* save environment */
 CurrentDrive   = FILESPEC( 'D', DIRECTORY());
 SpecifiedDrive = FILESPEC( 'D', Name);
 IF (SpecifiedDrive = '') THEN
    SpecifiedDrive = CurrentDrive;
 CurrentDir     = DIRECTORY( SpecifiedDrive);

 /* try directory */
 DirFound  = DIRECTORY(Name);

 /* reset environment */
 rc = DIRECTORY(CurrentDir);
 rc = DIRECTORY(CurrentDrive);

 RETURN(DirFound);

/* -------------------------------------------------------------------------- */
FileStamp: PROCEDURE
PARSE ARG File;

 FileStamp = '';

 IF (File \= '') THEN
   FileStamp = TRANSLATE( 'abcdefghijklmn', STREAM( File, 'C', 'QUERY TIMESTAMP'), 'abcd-ef-gh  ij:kl:mn');

 RETURN( FileStamp);
