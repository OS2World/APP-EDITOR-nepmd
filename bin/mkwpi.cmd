/*
 *      MKWPI.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: mkwpi mkwpi-script logfile wis-script wpi-file [VAR=value [...]]
 *
 *    This program creates a WPI package.
 *    It can be used as an external command processor.
 *
 *    Within the mkwpi-script file the following definitions can
 *    be specified in every line by one of the following definitions
 *       <name>   <id> <directory> <filemask>
 *       <name>   <id>, <directory>, <filemask>
 *
 *    Comment lines start with a colon.
 *
 *    Note:
 *      - files are always packed recursively
 *      - if a definition does not use commas, the directory name and the
 *        filemask may not contain blanks !
 *      - The name value is ignored (may not be unique). It is recommended
 *        though to use a meaningful name in order to logically separate
 *        different filesets from each other.
 *      - the package id must be numeric and must match the corresponding
 *        package id in the WarpIn script file
 *      - directory names and filemasks may contain blanks
 *      - The symbols defined as parameters are exported as environment
 *        variables
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: mkwpi.cmd
*
* Batch for to create a WPI file.
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

 fVerbose        = FALSE;
 fPackageMissing = FALSE;
 fSyntaxError    = FALSE;
 ErrorLst        = '';

 Pkg._List = ''

 DO UNTIL (TRUE)

    /* determine listfile name */
    PARSE ARG ListFile LogFile WisScript WpiFile VarList;
    ListFile  = STRIP( ListFile);
    WisScript = STRIP( WisScript);
    WpiFile   = STRIP( WpiFile);

    IF (WpiFile = '') THEN
    DO
       SAY 'error: no WPI target file specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;

    /* file not there: nothing to check */
    IF (\FileExist( ListFile)) THEN
    DO
       /* handle EXTPROC bug in CMD.EXE */
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

    /* put all symbols to environment */
    DO WHILE (VarList \= '')
       PARSE VAR VarList ThisParm VarList;

       PARSE VAR ThisParm ThisVar'='ThisValue;
       ThisVar   = STRIP( ThisVar);
       ThisValue = STRIP( ThisValue);

       IF (ThisValue \= '') THEN
       DO
          /* pass symbols to environment */
          rcx = VALUE( ThisVar, ThisValue, env);
          ITERATE;
       END;
       ELSE
       DO
          SAY 'error: invalid parameter' ThisParm'.';
          rc = ERROR.INVALID_PARAMETER;
          LEAVE;
       END;
    END;

    /* read and process all commands */
    rcx = STREAM( ListFile, 'C', 'OPEN READ');
    LineNo = 0;
    DO WHILE (LINES( ListFile) > 0)

       ThisLine = LINEIN( ListFile);
       LineNo = LineNo + 1;

       /* skip comments and empty lines */
       FirstWord = TRANSLATE( WORD( ThisLine, 1));
       IF (FirstWord = '') THEN ITERATE;
       IF (WORDPOS( FirstWord, 'EXTPROC') > 0) THEN ITERATE;
       IF (LEFT( FirstWord, 1) = ':') THEN ITERATE;

       /* check package information */
       ThisLine = ParseLine( ThisLine);
       IF (POS( ',', ThisLine) > 0) THEN
          PARSE VAR ThisLine ThisName ThisId','ThisDirectory','ThisFileMask;
       ELSE
          PARSE VAR ThisLine ThisName ThisId ThisDirectory ThisFileMask;

       ThisId        = STRIP( ThisId);
       ThisFileMask  = STRIP( ThisFileMask);
       ThisDirectory = STRIP( ThisDirectory);

       IF (DATATYPE( ThisId) \= 'NUM') THEN
       DO
          SAY ListFile'('LineNo') : error : package id not numeric.';
          rc = ERROR.INVALID_DATA;
          LEAVE;
       END;
       IF (WORDS( ThisFileMask) \= 1) THEN
       DO
          SAY ListFile'('LineNo') : error : invalid or empty filemask specified.';
          rc = ERROR.INVALID_DATA;
          LEAVE;
       END;

       /* store package info */
       IF (WORDPOS( ThisId, Pkg._List) = 0) THEN
       DO
          Pkg._List    = Pkg._List ThisId;
          Pkg.ThisId.0 = 0;
       END;

       p                       = Pkg.ThisId.0 + 1;
       Pkg.ThisId.p._FileMask  = ThisFileMask;
       Pkg.ThisId.p._Directory = ThisDirectory;
       Pkg.ThisId.0            = p;

    END;

    rcx = STREAM( ListFile, 'C', 'OPEN READ');
    IF (rc != ERROR.NO_ERROR) THEN
       LEAVE;

    /* --- extend environment */
    'CALL WARPIN.ENV';

    /* start writing parameters to a temporary response file */
    ResponseFile = SysTempFilename( VALUE( 'TMP',,env)'\mkwpi.???');
    rcx = SysFileDelete( ResponseFile);
    rcx = LINEOUT( ResponseFile, '-s' WisScript);
    rcx = LINEOUT( ResponseFile, '-a');

    /* - collecting parameters */
    DO WHILE (Pkg._List \= '')
       PARSE VAR Pkg._List ThisId Pkg._List;
       DO p = 1 TO Pkg.ThisId.0
          ThisParms = ThisId '-r -c'Pkg.ThisId.p._Directory Pkg.ThisId.p._FileMask;
          IF (fVerbose) THEN
             SAY ThisParms;
          rc = LINEOUT( ResponseFile, ThisParms);
       END;
    END;
    rcx = STREAM( ResponseFile, 'C', 'CLOSE');

    /* calling wpi compiler */
    rcx = SysFileDelete( WpiFile);
    rcx = SysFileDelete( LogFile);
    WicCommand = 'wic' WpiFile '@'ResponseFile '>>' LogFile '2>&1';
    rc = LINEOUT( LogFile, WicCommand);
    rc = LINEOUT( LogFile);
    'CALL' WicCommand;
    rcx = SysFileDelete( ResponseFile);

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

/* ------------------------------------------------------------------------- */
ParseLine: PROCEDURE EXPOSE env
 PARSE ARG ThisLine

 Delimiter = '%';

 ThisLineCopy = '';
 CurrentPos   = 1;

 VarStart = POS(Delimiter, ThisLine);
 DO WHILE (VarStart > 0)

    VarEnd       = Pos(Delimiter, ThisLine, VarStart + 1);
    ThisVar      = SUBSTR(ThisLine, VarStart + 1, VarEnd - VarStart - 1);
    ThisVarValue = VALUE(ThisVar,,env);

    ThisLineCopy = ThisLineCopy||,
                   SUBSTR(ThisLine, CurrentPos, VarStart - CurrentPos)||,
                   ThisVarValue;
    CurrentPos   = VarEnd + 1;

    VarStart = POS(Delimiter, ThisLine, CurrentPos);
 END;

 ThisLineCopy = ThisLineCopy||SUBSTR(ThisLine, CurrentPos);

 RETURN(ThisLineCopy);

