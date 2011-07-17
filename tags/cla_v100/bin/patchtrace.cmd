/*
 *      PATCHTRACE.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: patchtrace.cmd
 *
 *    This program adds trace statements to all source files of
 *    an installed nepmd installation.
 *    For that copies of all netlabs\macros\*.e are created in myepm\macro.
 *
 *    All existing myepm\macro\*.e with the same name are overwritten.
 *    To activate the trace, recompile EPM
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: patchtrace.cmd
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
 IF (POS('?', Parm) > 0) THEN
 DO
    rc = ShowHelp();
    EXIT(ERROR.INVALID_PARAMETER);
 END;

 /* default values */
 GlobalVars = GlobalVars 'TraceDefs ValidDefs';
 rc = ERROR.NO_ERROR;

 ValidDefs = 'DEF DEFC DEFEXIT DEFINIT DEFKEYS DEFLOAD DEFMAIN DEFMODIFY DEFPROC DEFSELECT'
 TraceDefs = 'DEFPROC';


 DO UNTIL (TRUE)
    /* determine install path of NEPMD */
    PARSE VALUE SysIni(, 'NEPMD', 'Path') WITH InstallPath'0'x;
    IF (InstallPath = '') THEN
    DO
       SAY 'error: NEPMD not installed! Cannot ship file' SourceFile;
       rc = ERROR.PATH_NOT_FOUND;
    END;

    SourcePath = InstallPath'\netlabs\macros';
    TargetPath = InstallPath'\myepm\macros';

    /* target files may not exist */
    IF (FileExist( TargetPath'\*.e')) THEN
    DO
       SAY CmdName': error: E language files found in directory' TargetPath'!';
       SAY 'Cannot continue, please move files out of the way.';
       rc = ERROR.ACCESS_DENIED;
       LEAVE;
    END;

    /* process sourcefiles */
    rc = SysFileTree( SourcePath'\*.e', 'SourceFile.', 'FO')
    IF (rc \= ERROR.NO_ERROR) THEN
    DO
       SAY CmdName': error in SysFileTree.';
       LEAVE;
    END;
    IF (SourceFile.0 = 0) THEN
    DO
       SAY CmdName': error: no sourcefiles found in' SourcePath;
       LEAVE;
    END;

    CALL CHAROUT, 'processing' SourceFile.0 'files ';
    DO i = 1 TO SourceFile.0
       CALL CHAROUT, '.';
       rc = ProcessFile( SourceFile.i, TargetPath'\'FILESPEC( 'N', SourceFile.i));
    END;
    SAY '  Ok.';

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

/* ========================================================================= */
ProcessFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG SourceFile, TargetFile;

 SourceFileStat = '';
 TargetFileStat = '';

 CurrentSymbol  = '';

 DO UNTIL (1)
    /* delete file, ignore errors */
    rcx = SysFileDelete( TargetFile);

    /* open files */
    SourceFileStat = STREAM( SourceFile, 'C', 'OPEN READ');
    TargetFileStat = STREAM( TargetFile, 'C', 'OPEN');
    IF ((SourceFileStat \= 'READY:') | (TargetFileStat \= 'READY:')) THEN
       LEAVE;

    /* search defines */

    DO WHILE (LINES( SourceFile) > 0)

       /* read line */
       ThisLine = LINEIN( SourceFile);

       /* check line for a definition */
       DO UNTIL (1)

          /* skip empty lines */
          IF (ThisLine = '') THEN
             LEAVE;

          /* check for a def tag */
          CheckTag = TRANSLATE( WORD( ThisLine, 1));

          /* write end trace statement, if any open */
          IF (WORDPOS( CheckTag, ValidDefs 'RETURN CONST') > 0) THEN
          DO
             IF (CurrentSymbol \= '') THEN
             DO
                TraceLine = 'if isadefproc("NepmdPmPrintf") then call NepmdPmPrintf( "'CurrentSymbol' <-"); endif';
                rcx = LINEOUT( TargetFile, TraceLine);
                CurrentSymbol = '';
             END;
          END;

          /* write a start statement for certain tags only */
          IF (WORDPOS( CheckTag, TraceDefs) > 0) THEN
          DO
             CurrentSymbol = WORD( ThisLine, 2);
             /* process up to first line not specifying universal */
             DO WHILE (1)
                rcx = LINEOUT( TargetFile, ThisLine);
                ThisLine = LINEIN( SourceFile);
                CheckTag = TRANSLATE( WORD( ThisLine, 1));

                IF (ThisLine = '') THEN ITERATE;
                IF (WORDPOS( CheckTag,'; -- UNIVERSAL COMPILE') > 0) THEN ITERATE;
                LEAVE;
             END;

             TraceLine = 'if isadefproc("NepmdPmPrintf") then call NepmdPmPrintf( "'CurrentSymbol' ->"); endif';
             rcx = LINEOUT( TargetFile, TraceLine);
          END;

       END;

       /* write all normal lines here */
       rcx = LINEOUT( TargetFile, ThisLine);

    END;

    /* close unfinished trace */
    IF (CurrentSymbol \= '') THEN
    DO
       TraceLine = 'if isadefproc("NepmdPmPrintf") then call NepmdPmPrintf( "'CurrentSymbol' <-"); endif';
       rcx = LINEOUT( TargetFile, TraceLine);
       CurrentSymbol = '';
    END;

 END;

 /* close files */
 IF (SourceFileStat = 'READY:') THEN
    rcx = STREAM( SourceFile, 'C', 'CLOSE');
 IF (TargetFileStat = 'READY:') THEN
    rcx = STREAM( TargetFile, 'C', 'CLOSE');

 RETURN( 0);

