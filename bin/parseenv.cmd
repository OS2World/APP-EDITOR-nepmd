/*
 *      PARSEENV.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: PARSEENV sourcefile targetfile
 *                       [VAR=VALUE [VAR=VALUE [...]]]
 *
 *    This program writes a copy of the sourcefile replaces environment
 *    variables in a (copy of a) text file. Additional vars can be specified 
 *    as symbols as commandline parameters.
 *
 *    NOTE: 
 *       - values may not include spaces and may not be enclosed in 
 *         single/double quotes.
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: parseenv.cmd
*
* Batch for to replace environment variables in text files
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: parseenv.cmd,v 1.1 2002-06-10 13:32:53 cla Exp $
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
 Id = '$Id: parseenv.cmd,v 1.1 2002-06-10 13:32:53 cla Exp $';
 PARSE VAR Id .',v' Ver .;
 Title     = CmdName 'V'Ver Info;

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
 ERROR.OPEN_FAILED        = 110;
 ERROR.ENVVAR_NOT_FOUND   = 203;

 GlobalVars = 'Title CmdName CrLf env TRUE FALSE Redirection ERROR.';
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* eventually show help */
 ARG Parm .
 IF ((Parm = '') | (POS('?', Parm) > 0)) THEN
 DO
    rc = ShowHelp();
    EXIT( ERROR.INVALID_PARAMETER);
 END;

 /* default values */
 GlobalVars = GlobalVars '';
 rc = ERROR.NO_ERROR;

 SourceFile = '';
 TargetFile = '';

 DO UNTIL (TRUE)

    /* don't modify environment of CMD.EXE */
    rcx = SETLOCAL();

    /* determine parameters */
    PARSE ARG Parms;
    DO WHILE (Parms \= '')
       PARSE VAR Parms ThisParm Parms;

       PARSE VAR ThisParm ThisVar'='ThisValue;
       ThisVar   = STRIP( ThisVar);
       ThisValue = STRIP( ThisValue);

       IF (ThisValue \= '') THEN
       DO
          /* pass symbols to environment */
          rcx = VALUE( ThisVar, ThisValue, env);
          ITERATE;
       END;

       /* all other parms must be file or dir  specifications */
       SELECT
          WHEN (SourceFile = '') THEN
             SourceFile = ThisParm;

          WHEN (TargetFile = '') THEN
             TargetFile = ThisParm;

          OTHERWISE
          DO
             SAY CmdName': error: invalid parameter' ThisParm 'specified.';
             rc = ERROR.INVALID_PARAMETER;
             LEAVE;
          END;
       END;
    END;
    IF (rc \= ERROR.NO_ERROR) THEN
       LEAVE;

    /* source file specified ? */
    IF (SourceFile = '') THEN
    DO
       SAY CmdName': error: no sourcefile specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;

    /* does it exist ? */
    IF (\FileExist( SourceFile)) THEN
    DO
       SAY CmdName': error: sourcefile' SourceFile 'cannot be found.';
       rc = ERROR.FILE_NOT_FOUND;
       LEAVE;
    END;

    /* target file not specified ? */
    IF (TargetFile = '') THEN
    DO
       SAY CmdName': error: no targetfile specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;
    rcx = SysFileDelete( TargetFile);

    /* open files */
    IF (STREAM( SourceFile, 'C', 'OPEN READ') \= 'READY:') THEN
    DO
       SAY CmdName': error: cannot open sourcefile' SourceFile 'for read.';
       rc = ERROR.OPEN_FAILED;
       LEAVE;
    END;

    IF (STREAM( TargetFile, 'C', 'OPEN WRITE') \= 'READY:') THEN
    DO
       SAY CmdName': error: cannot open targetfile' TargetFile 'for write';
       rc = ERROR.OPEN_FAILED;
       LEAVE;
    END;

    /* now copy contents */
    DO WHILE (LINES( SourceFile))
       ThisLine = LINEIN( SourceFile);
       rcx = LINEOUT( TargetFile, ParseLine( ThisLine));
    END;
    rcx = STREAM( SourceFile, 'C', 'CLOSE');
    rcx = STREAM( TargetFile, 'C', 'CLOSE');

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

