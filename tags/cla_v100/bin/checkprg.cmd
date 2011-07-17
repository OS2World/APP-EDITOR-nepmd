/*
 *      CHECKPRG.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: checkprg listfile
 *
 *    This program checks for required executables and ini entries.
 *    It can be used as an external command processor.
 *
 *    If a file with the name of the listfile, but extension .lst exists,
 *    its contents is displayed in case of an error.
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: checkprg.cmd
*
* Batch for to check dependencies.
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

 SIGNAL ON HALT

 TitleLine = STRIP(SUBSTR(SourceLine(2), 3));
 PARSE VAR TitleLine CmdName'.CMD 'Info;
 PARSE VALUE "$Revision$" WITH . Version .;
 Title     = CmdName 'V'Version Info;

 env          = 'OS2ENVIRONMENT';
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 CrLf         = '0d0a'x;
 Redirection  = '> NUL 2>&1';
 '@ECHO OFF'

 /* OS/2 Error codes */
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
 ERROR.GEN_FAILURE        =  31;
 ERROR.INVALID_PARAMETER  =  87;
 ERROR.ENVVAR_NOT_FOUND   = 203;

 GlobalVars = 'Title CmdName CrLf env TRUE FALSE Redirection ERROR.';
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* eventually show help */
 ARG Parm .
 IF ((Parm = '') | (POS('?', Parm) > 0)) THEN
 DO
    rc = ShowHelp();
    EXIT(ERROR.INVALID_PARAMETER);
 END;

 /* default values */
 GlobalVars = GlobalVars '';
 rc = ERROR.NO_ERROR;

 fPackageMissing = FALSE;
 fSyntaxError    = FALSE;
 ErrorLst        = '';

 DO UNTIL (TRUE)

    /* determine listfile name */
    PARSE ARG ListFile;
    ListFile = STRIP( ListFile);

    IF (ListFile = '') THEN
    DO
       SAY 'error: no check listfile specified.';
       rc = ERROR.INVALID_PARAMETER;
    END;

    /* file not there: nothing to check */
    IF (\FileExist( ListFile)) THEN
    DO
       /* handle EXTPROC bug in CMD.EXDE */
       CheckFile = CheckExtProcCall( ListFile);
       IF (CheckFile \= '') THEN
          ListFile = CheckFile;
       ELSE
       DO
          SAY 'error: listfile' Listfile 'not found.';
          rc = ERROR.FILE_NOT_FOUND;
          LEAVE;
       END;
    END;

    /* read and process all check rules */
    rcx = STREAM( ListFile, 'C', 'OPEN READ');
    LineNo = 0;
    DO WHILE (LINES( ListFile) > 0)

       ThisLine = LINEIN( ListFile);
       LineNo = LineNo + 1;

       /* skip comments */
       FirstWord = TRANSLATE( WORD( ThisLine, 1));
       IF (WORDPOS( FirstWord, 'EXTPROC REM :') > 0) THEN ITERATE;

       /* process command */
       PARSE VAR ThisLine ThisCommand':'ThisParm ThisData ThisPackage;
       ThisCommand = TRANSLATE( ThisCommand);
       ThisPackage = STRIP( ThisPackage);
       IF (ThisPackage = '') THEN ITERATE;

       fPackageNotFound = FALSE;
       SELECT
          WHEN (ThisCommand = 'INI') THEN
          DO
             PARSE VAR ThisData ThisAppName':'ThisKeyName;
             fPackageNotFound = (SysIni( ThisParm, ThisAppName, ThisKeyName) = 'ERROR:');
          END;

          WHEN (ThisCommand = 'ENV') THEN
             fPackageNotFound = (SysSearchPath( ThisParm, ThisData) = '');

          OTHERWISE
          DO
             SAY ListFile'('LineNo') error: syntax error:' ThisLine;
             fSyntaxError = TRUE;
          END;

       END;

       IF (fPackageNotFound) THEN
       DO
          ErrorLst = ErrorLst''CrLf'- ' ThisPackage;
          fPackageMissing = TRUE;
       END;

    END;
    rcx = STREAM( ListFile, 'C', 'OPEN READ');

    /* report error */
    SELECT
       WHEN (fPackageMissing) THEN
       DO
          SAY;
          CALL CHAROUT, 'error: the following required packages could not be found:';
          SAY ErrorLst;
          SAY;
          rc = ERROR.FILE_NOT_FOUND;
       END;

       WHEN (fPackageMissing) THEN
          rc = ERROR.INVALID_DATA;

       OTHERWISE NOP;

    END;

 END;

 /* show contents of text file */
 IF (rc \= ERROR.NO_ERROR) THEN
 DO
    TextFile = OVERLAY( '.txt', ListFile, LASTPOS( '.', ListFile));
    IF (FileExist( TextFile)) THEN
    DO
       SaveRc = rc;
       'TYPE' TextFile;
       SAY;
       rc = SaveRc;
    END;

 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Abbruch durch Benutzer.';
 EXIT(ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)

 /* show title */
 SAY;
 SAY Title;
 SAY;

 PARSE SOURCE . . ThisFile

 /* skip header */
 DO i = 1 TO 3
    rc = LINEIN(ThisFile);
 END;

 /* show help text */
 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 /* close file */
 rc = LINEOUT(Thisfile);

 RETURN('');

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');

/* ------------------------------------------------------------------------- */
/* CheckExtProcCall examines the passed filename for only containing a       */
/* filename. In this case this program has possibly been called by EXTPROC,  */
/* which only passes the filename instead the complete pathname.             */
/* This lets the external command proccessor find the calling file only if   */
/* it resides in the current directory, and lets it not find if the calling  */
/* file has been called                                                      */
/*   - via the PATH                                                          */
/*   - with an absolute or relative path specification                       */
/*                                                                           */
/* In order to work around at least the first case we search the file within */
/* the PATH ! WARNING: This may lead to using the wrong file in the the      */
/* second of the above call cases when a copy of the calling file exists     */
/* in a directory of the PATH statement !                                    */

CheckExtProcCall: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File;

 CheckFile = '';

 DO UNTIL (TRUE)
    /* return nothing if path specification is provided */
    IF (POS( '\', File) > 0) THEN
       LEAVE;
    IF (POS( ':', File) > 0) THEN
       LEAVE;

    /* search file in path */
    CheckFile = SysSearchPath( 'PATH', File);

 END;

 RETURN( CheckFile);

