/*
 *      STRIPEVERSION.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: stripeversion sourcefile
 *
 *    This program resolves all compile ifdefs concerning EPM versions and
 *    removes code not being used for EPM V6.03b.
 *
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: stripeversion.cmd
*
* Batch for to remove compile ifdefs for EPM versions,
* restricts source code to EPM V6.03b only
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
 GlobalVars = 'fDebug File OutFile LineCount OutLineCount';
 fDebug     = FALSE;
 fVerbose   = FALSE;
 rc         = ERROR.NO_ERROR;

 StripTag   = '; #STRIP#'; /* don't touch ! */

 fDebug       = 0;  /* turn on to get detailed debug messages */
 fDelete      = 1;  /* turn off to comment out obsolete lines instead of deleting them */
 fCatchErrors = 0;  /* turn off for to let REXX display the syntax error */

 File    = '';
 OutFile = '';

 DO UNTIL (1)

    /* catch all syntax errors */
    IF (fCatchErrors) THEN
       SIGNAL ON SYNTAX;

    /* check parm */
    PARSE ARG File;
    File = STRIP( File);
    IF (File = '') THEN
    DO
       SAY 'no file specified';
       EXIT( 87); /* ERROR.INVALID_PARAMETER */
    END;

    /* load file */
    IF (STREAM( File, 'C', 'OPEN') \= 'READY:') THEN
    DO
       SAY 'cannot access file' File;
       EXIT( 5); /* ERROR.ACCESS_DENIED */
    END;

    /* open out file */
    OutFile = File'.out';
    '@DEL' OutFile '>NUL 2>&1';
    IF (STREAM( OutFile, 'C', 'OPEN') \= 'READY:') THEN
    DO
       SAY 'cannot access file' OutFile;
       EXIT( 5); /* ERROR.ACCESS_DENIED */
    END;


    /* parse lines */
    IfLevel      = 0;
    LineCount    = 0;
    OutLineCount = 0;
    StripLevel   = 0;
    fSkip        = 0;

    DO WHILE (LINES( File) > 0)
       ThisLine = LINEIN( File);
       LineCount = LineCount + 1;
       fSkipLine = 0;

       fComment       = 0;
       ReplaceComment = '';

       /* search for special test comment */
       IF (fDebug) THEN
       DO
          PARSE VAR ThisLine (StripTag) StripComment;
          IF (StripComment \= '') THEN
          DO
             SAY;
             SAY '------' ThisLine;
          END;
       END;

       /* check for compile directive */
       PARSE VAR ThisLine Tag1 Tag2 Expression;
       Tag1 = TRANSLATE( Tag1);

       IF (Tag1 = 'COMPILE') THEN
       DO
          Tag2 = TRANSLATE( Tag2);

          /* strip off comments, but preserve for later warning  */
          PARSE VAR Expression Expression'--'LineComment;
          IF (LineComment \= '') THEN
          DO
             fComment  = 1;
             cpos = POS( '--', ThisLine);
             ReplaceComment = OVERLAY( COPIES( ' ', cpos - 1), ThisLine);
          END;
          PARSE VAR Expression Expression'/*'LineComment;
          IF (LineComment \= '') THEN
          DO
             fComment  = 1;
             cpos = POS( '/*', ThisLine);
             ReplaceComment = OVERLAY( COPIES( ' ', cpos - 1), ThisLine);
          END;

          SELECT

             WHEN ((Tag2 = 'IF') | (Tag2 = 'ELSEIF')) THEN
             DO
                IF (fDebug) THEN
                DO
                   SAY;
                   SAY Tag2 'in line' LineCount', level' IfLevel;
                END;

                IF ((Tag2 = 'IF')) THEN
                   IfLevel = IfLevel + 1;
                ELSE
                DO
                   IF (StripLevel > IfLevel) THEN
                   DO
                      StripLevel = 0;
                      fSkip      = 0;
                   END;
                END;

                IF (StripLevel = 0) THEN
                DO
                   PARSE VALUE StartSkip( Expression) WITH fVersionCheck fCheckSkip fCheckSkipLine NewExpression;
                   IF (fVersionCheck) THEN
                   DO
                      IF (NewExpression = '') THEN
                      DO
                         StripLevel = IfLevel;
                         fSkip      = fCheckSkip;
                         fSkipLine  = fCheckSkipLine;
                      END;
                      ELSE
                      DO
                         IF (\fDelete) THEN
                         DO
                            rcx = LINEOUT( OutFile, StripTag ThisLine);
                            OutLineCount = OutLineCount + 1;
                         END;
                         ThisLine = SUBSTR( ThisLine, 1, WORDINDEX( ThisLine, 3) - 1) NewExpression;
                      END;
                   END;
                END;

             END;

             WHEN (Tag2 = 'ELSE') THEN
             DO
                IF (fDebug) THEN
                   SAY Tag2 'in line' LineCount', level' IfLevel;

                IF ((StripLevel > 0) & (StripLevel = IfLevel)) THEN
                DO
                   fSkip = \fSkip;
                   fSkipLine = 1;
                END;
             END;

             WHEN (Tag2 = 'ENDIF') THEN
             DO
                IF (fDebug) THEN
                   SAY Tag2 'in line' LineCount', level' IfLevel;
                IfLevel = IfLevel - 1;

                IF (StripLevel > IfLevel) THEN
                DO
                   StripLevel = 0;
                   fSkip      = 0;
                   fSkipLine  = 1;
                END;
             END;

             OTHERWISE
                SAY 'error: invalid ' Tag2 ' in line' LineCount;

          END;

       /* ITERATE; */
       END; /* IF (Tag1 = 'COMPILE') */

    IF ((fSkip) | (fSkipLine)) THEN
    DO
       IF (fDebug) THEN
          SAY '#'LineCount;
       IF (\fDelete) THEN
       DO
          rcx = LINEOUT( OutFile, StripTag ThisLine);
          OutLineCount = OutLineCount + 1;
       END;
       ELSE
       DO
       /*                                             */
       /* IF (ReplaceComment \= '') THEN              */
       /* DO                                          */
       /*    rcx = LINEOUT( OutFile, ReplaceComment); */
       /*    OutLineCount = OutLineCount + 1;         */
       /* END;                                        */
       END;
    END;
    ELSE
    DO
       rcx = LINEOUT( OutFile, ThisLine);
       OutLineCount = OutLineCount + 1;
    END;

    END;


    rcx = STREAM( File, 'C', 'CLOSE');
    rcx = STREAM( OutFile, 'C', 'CLOSE');

 END;

 EXIT(0);

SYNTAX:
  SAY 'syntax error when processing:' File', line' LineCount;
  EXIT(99);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Interrupted by user';
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


/* =============================================================== */
ReplaceWord: PROCEDURE
 PARSE ARG Keyword, Version, Expression;
 fKeywordFound = 0;
 fFound = 0;

 wpos = WORDPOS( Keyword, Expression);
 IF (wpos > 0) THEN
 DO
    fFound = 1;
    wposidx = WORDINDEX( Expression, wpos);
    Expression = DELWORD( Expression, wpos, 1);
    Expression = INSERT( Version, Expression, wposidx - 1);
 END;

 RETURN( fFound Expression);

/* =============================================================== */
VersionCheck: PROCEDURE EXPOSE (GlobalVars);
 PARSE ARG Expression;

 fResult       = 0;
 fCheckVersion = 0;

 PARSE VALUE ReplaceWord( 'EVERSION', "'6.03'", Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'E3',       '0'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'EOS2',     '0'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'EOS2FAM',  '0'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'EPM',      '1'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'EPM32',    '1'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 PARSE VALUE ReplaceWord( 'POWERPC',  '0'    , Expression) WITH fFound Expression;
 IF (fFound) THEN fCheckVersion = 1;

 IF (fCheckVersion) THEN
 DO
    IF (fDebug) THEN
       CALL CHAROUT, '#### version check:' Expression;

    /* replace all brackets */
    Expression = TRANSLATE( Expression, '  ', '()');

    /* replace NOT keywords for evaluation */
    PARSE VALUE ReplaceWord( 'NOT', '\', TRANSLATE( Expression)) WITH fFound Expression;

    INTERPRET( 'fResult ='Expression);
    IF (fDebug) THEN
       SAY ' result='fResult;

 END;

 fResult = \fResult;

 RETURN( fCheckVersion fResult);

/* =============================================================== */
StartSkip: PROCEDURE EXPOSE (GlobalVars);
 PARSE ARG Expression;

 fVersionCheck = 0;
 fSkip         = 0;
 fSkipLine     = 1;

 fOtherFound   = 0;
 NewExpression = '';
 Operator      = '';
 LastOperator  = '';

 IF (fDebug) THEN
   SAY '==> check:' Expression;

 ExpList = Expression;
 DO WHILE (ExpList \= '')

    AndPos     = WORDPOS( '&',   ExpList);             IF (AndPos > 0)    THEN AndPos    = WORDINDEX( ExpList, AndPos);
    OrPos      = WORDPOS( '|',   ExpList);             IF (OrPos > 0)     THEN OrPos     = WORDINDEX( ExpList, OrPos);
    LitAndPos  = WORDPOS( 'AND', TRANSLATE(ExpList));  IF (LitAndPos > 0) THEN LitAndPos = WORDINDEX( ExpList, LitAndPos);
    LitOrPos   = WORDPOS( 'OR',  TRANSLATE(ExpList));  IF (LitOrPos > 0)  THEN LitOrPos  = WORDINDEX( ExpList, LitOrPos);


    UseAndOperator = '&';
    IF (LitAndPos > 0) THEN
    DO
       IF ((AndPos = 0) | (LitAndPos < AndPos)) THEN
       DO
          UseAndOperator = 'AND';
          AndPos = LitAndPos;
          ExpList = OVERLAY( UseAndOperator, ExpList, AndPos);
       END;
    END;

    UseOrOperator = '|';
    IF (LitOrPos > 0) THEN
    DO
       IF ((OrPos = 0) | (LitOrPos < OrPos)) THEN
       DO
          UseOrOperator = 'OR';
          OrPos = LitOrPos;
          ExpList = OVERLAY( UseOrOperator, ExpList, OrPos);
       END;
    END;

    SELECT
       WHEN ((AndPos = 0) & (OrPos = 0)) THEN
       DO
          ThisExpression = ExpList;
          ExpList        = '';
       END;

       WHEN (AndPos > 0) & ((AndPos < OrPos) | (OrPos = 0)) THEN
       DO
          PARSE VAR ExpList ThisExpression(UseAndOperator)ExpList;
          Operator = UseAndOperator;
       END;

       WHEN (OrPos > 0) & ((OrPos < AndPos) | (AndPos = 0)) THEN
       DO
          PARSE VAR ExpList ThisExpression(UseOrOperator)ExpList;
          Operator = UseOrOperator;
       END;

       OTHERWISE
       DO
          SAY 'Internal error processing operators ...';
          EXIT(99);
       END;
    END;

    IF (fDebug) THEN
       SAY '>>>>>> check:' ThisExpression;

    PARSE VALUE VersionCheck( ThisExpression) WITH fTmpVersionCheck fTmpSkip;
    IF (fTmpVersionCheck) THEN
    DO
       /* it is a version check - don't pass over the expression */
       fVersionCheck = fTmpVersionCheck;
       fSkip         = fTmpSkip;

       /* preserve brackets though ! */
       CheckExpression = STRIP( SPACE( ThisExpression, 0));
       DO WHILE (LEFT( CheckExpression, 1) = '(')
          NewExpression = NewExpression'(';
          CheckExpression = SUBSTR( CheckExpression, 2);
       END;
       DO WHILE (RIGHT( CheckExpression, 1) = ')')
          NewExpression = NewExpression')';
          CheckExpression = SUBSTR( CheckExpression, 2);
       END;

    END;
    ELSE
    DO
       /* pass over expression */
       fOtherFound   = 1;
       NewExpression = NewExpression LastOperator STRIP( ThisExpression);
       LastOperator = Operator;
    END;

 END;

 /* any version check found ? */
 IF (fVersionCheck) THEN
 DO
    IF (fDebug) THEN
    DO
       CALL CHAROUT, '==> version check with:' Expression' - start with ';
       IF (fSkip) THEN
          SAY 'skip';
       ELSE
          SAY 'noskip';
    END;
 END;

 /* display warning message */
 IF ((fVersionCheck) & (fOtherFound)) THEN
    SAY File'('LineCount'):['OutLineCount']: warning: check expression: "'NewExpression'", old was "'Expression'"';


 /* if any other expression has been found, rework the line */

 RETURN( fVersionCheck fSkip fSkipLine NewExpression)

