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
 *    The XML Tag <cinclude name="filename"/> includes a C-headerfile and
 *    loads defined symbols. Note that
 *        - the filename may include envvars to distinct between different
 *          files for e.g. different languages
 *        - only #defines from within these files are interpreted.
 *        - #ifdef #else #endif are not supported, but ignored
 *        - no C style comments are supported like: /* comment */
 *        - C++ style comments are supported like: // comment
 *          but are not skipped when being used within strings (should be)
 *        - no symbols can be used within the #define values yet
 *        - strings may include \r \n and \t.
 *
 *    The XML Tag <tinclude name="filename"/> includes textfiles as part of
 *    the wis script. Note that
 *        - the filename may include envvars to distinct between different
 *          files for e.g. different languages.
 *
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
 GlobalVars = GlobalVars 'fDebug fVerbose';
 fDebug     = FALSE;
 fVerbose   = FALSE;
 rc         = ERROR.NO_ERROR;

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
             SAY CmdName': Error: Invalid parameter' ThisParm 'specified.';
             rc = ERROR.INVALID_PARAMETER;
             LEAVE;
          END;
       END;
    END;
    IF (rc \= ERROR.NO_ERROR) THEN
       LEAVE;

    /* source file specified? */
    IF (SourceFile = '') THEN
    DO
       SAY CmdName': Error: No source file specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;

    /* does it exist? */
    IF (\FileExist( SourceFile)) THEN
    DO
       SAY CmdName': Error: Source file' SourceFile 'cannot be found.';
       rc = ERROR.FILE_NOT_FOUND;
       LEAVE;
    END;

    /* target file not specified? */
    IF (TargetFile = '') THEN
    DO
       SAY CmdName': Error: No target file specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;
    rcx = SysFileDelete( TargetFile);

    /* open files */
    IF (STREAM( SourceFile, 'C', 'OPEN READ') \= 'READY:') THEN
    DO
       SAY CmdName': Error: Cannot open source file' SourceFile 'for read.';
       rc = ERROR.OPEN_FAILED;
       LEAVE;
    END;

    IF (STREAM( TargetFile, 'C', 'OPEN WRITE') \= 'READY:') THEN
    DO
       SAY CmdName': Error: Cannot open target file' TargetFile 'for write.';
       rc = ERROR.OPEN_FAILED;
       LEAVE;
    END;

    /* now copy contents */
    Linecount = 0;
    fInComment = FALSE;
    DO WHILE (LINES( SourceFile))
       ThisLine = LINEIN( SourceFile);
       Linecount = Linecount + 1;

       /* check for include files */
       CheckLine = TRANSLATE( ThisLine);
       CommentCheckLine = CheckLine;

       /* Filter out comments in CommentCheckLine, set fInComment flag */
       DO FOREVER
          commentStartPos = POS( '<!--', CommentCheckLine);
          commentEndPos   = POS( '-->', CommentCheckLine);
          SELECT
             WHEN (fInComment & (commentEndPos > 0)) THEN
             DO
                /* Use part after comment */
                CommentCheckLine = SUBSTR( CommentCheckLine, commentEndPos + 3);
                fInComment = FALSE;
             END;
             WHEN (\fInComment & (commentStartPos > 0) & (commentEndPos > 0)) THEN
             DO
                /* Remove oneline comment */
                CommentCheckLine = LEFT( CommentCheckLine, commentStartPos - 1) ||,
                                   SUBSTR( CommentCheckLine, commentEndPos + 3);
             END;
             WHEN (\fInComment & (commentStartPos > 0)) THEN
             DO
                /* Use part before comment */
                CommentCheckLine = LEFT( CommentCheckLine, commentStartPos - 1);
                fInComment = TRUE;
             END;
             OTHERWISE LEAVE;
          END;
       END;

       SELECT
          WHEN fInComment THEN Tag = '';
          WHEN (POS( '<CINCLUDE', CommentCheckLine) > 0) THEN Tag = 'CINCLUDE';
          WHEN (POS( '<TINCLUDE', CommentCheckLine) > 0) THEN Tag = 'TINCLUDE';
          OTHERWISE Tag = '';
       END;

       IF (Tag \= '') THEN
       DO
          tPos = POS( '<'Tag, CheckLine);
          NewLineStart = LEFT( ThisLine, tPos - 1);
          NewLineEnd   = '';
          TagLine = SUBSTR( ThisLine, tPos);

          /* search end of tag */
          ePos = POS( '>', ThisLine, tPos);
          IF (ePos > 0) THEN
          DO
             NewLineEnd = SUBSTR( ThisLine, ePos + 1);
             TagLine = TagLine LEFT( ThisLine, ePos);
          END;

          DO WHILE (ePos = 0)
             ThisLine = LINEIN( SourceFile);
             Linecount = Linecount + 1;

             ePos = POS( '>', ThisLine, tPos);
             IF (ePos > 0) THEN
             DO
                NewLineEnd = SUBSTR( ThisLine, ePos + 1);
                TagLine = TagLine LEFT( ThisLine, ePos);
             END;
             ELSE
                TagLine = ThisLine;
          END;

          PARSE VAR TagLine '"'IncludeFile'"';
          IncludeFile = ParseLine( IncludeFile);
          IF (STREAM( IncludeFile, 'C', 'OPEN READ') \= 'READY:') THEN
          DO
             SAY SourceFile'('Linecount') : Error: Cannot open include file 'IncludeFile
             rc = ERROR.INVALID_DATA;
             LEAVE;
          END;

          SELECT
             WHEN (Tag = 'CINCLUDE') THEN
             DO
                rcx = ProcessCIncludeFile( IncludeFile);
                ThisLine = NewLineStart''NewLineEnd;
             END;

             WHEN (Tag = 'TINCLUDE') THEN
             DO
                Content = ProcessScriptIncludeFile( IncludeFile);
                ThisLine = NewLineStart''Content''NewLineEnd;
             END;

             OTHERWISE NOP;
          END;

       END;

       NewLine = ParseLine( ThisLine);
       rcx = LINEOUT( TargetFile, NewLine);
    END;
    rcx = STREAM( SourceFile, 'C', 'CLOSE');
    rcx = STREAM( TargetFile, 'C', 'CLOSE');

 END;

 /* cleanup target file on error */
 IF ((rc \= ERROR.NO_ERROR) & (TargetFile \= '')) THEN
    rcx = SysFileDelete( TargetFile);

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)

 /* show title */
 SAY;
 SAY Title;
 SAY;

 PARSE SOURCE . . ThisFile

 /* skip header */
 DO i = 1 TO 3
    rc = LINEIN( ThisFile);
 END;

 /* show help text */
 ThisLine = LINEIN( Thisfile);
 DO WHILE ( ThisLine \= ' */')
    SAY SUBSTR( ThisLine, 7);
    ThisLine = LINEIN( Thisfile);
 END;

 /* close file */
 rc = LINEOUT( Thisfile);

 RETURN( '');

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '');

/* ------------------------------------------------------------------------- */
/* Resolve environment vars.                                                 */
/* Don't process WPS %-params.                                               */
ParseLine: PROCEDURE EXPOSE env
 PARSE ARG ThisLine

 Delim    = '%';
 NoDelim  = '%*';

 startp = 1;
 DO WHILE 1 > 0
    p1 = pos( Delim, ThisLine, startp);
    IF p1 = 0 THEN
       LEAVE;

    IF pos( NoDelim, ThisLine, p1) = p1 THEN
    DO
       startp = startp + LENGTH( NoDelim);
       ITERATE;
    END;

    p2 = pos( Delim, ThisLine, p1 + 1);
    IF p2 = 0 THEN
       LEAVE;

    LeftPart  = SUBSTR( ThisLine, 1, p1 - 1);
    RightPart = SUBSTR( ThisLine, p2 + 1);
    ThisVar   = SUBSTR( ThisLine, p1 + 1, p2 - p1 - 1);
    Resolved  = VALUE( ThisVar, , env);
    startp    = LENGTH( LeftPart) + LENGTH( Resolved) + 1;

    ThisLine  = LeftPart''Resolved''RightPart;
 END;

 RETURN( ThisLine);

/* ========================================================================= */
StrReplace: PROCEDURE
 PARSE ARG StrSearch, StrReplace, Str;

 StrPos = POS( StrSearch, Str);
 DO WHILE (StrPos > 0)
    Str = DELSTR(  Str, StrPos, LENGTH( StrSearch));
    Str = INSERT(  StrReplace, Str, StrPos);

    StrPos = POS( StrSearch, Str);
 END;

 RETURN( Str);

/* ========================================================================= */
ReplaceSpecialChars: PROCEDURE
 PARSE ARG Str;

 Str = StrReplace( '\n', '0a'x, Str);
 Str = StrReplace( '\r', '0d'x, Str);
 Str = StrReplace( '\t', '09'x, Str);

 RETURN( Str);


/* ========================================================================= */
ProcessCIncludeFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File;

 ErrorMsg = '';
 rc = ERROR.NO_ERROR;


 Linecount = 0;
 DefinePending = FALSE;

 Linecount = 0;
 VarName   = '';
 VarValue  = '';

 IF (fVerbose) THEN
    SAY '- processing C include file' File
 DO UNTIL (TRUE)

    DO WHILE (LINES( File))
       ThisLine = LINEIN( File);
       Linecount = Linecount + 1;

       /* strip comments */
       CommentPos = POS('//', ThisLine);
       IF (CommentPos > 0) THEN
          ThisLine = LEFT( ThisLine, CommentPos - 1);


       /* search for #defines */
       Tag = TRANSLATE( WORD( ThisLine, 1));
       SELECT
          WHEN (Tag = '#DEFINE') THEN
          DO
             /* store old value first */
             IF (VarName \= '') THEN
             DO
                VarValue = ReplaceSpecialChars( VarValue);
                rcx = VALUE( VarName, VarValue, env);
                IF (fDebug) THEN
                   SAY '1 storing' VarName '->' VarValue;
             END;

             /* read new value */
             fNextLine = FALSE;
             VarValue = '';
             IF (RIGHT( STRIP( ThisLine), 1) = '\') THEN
             DO
                ThisLine = STRIP( ThisLine);
                ThisLine = LEFT( ThisLine, LENGTH( ThisLine) - 1);
                fNextLine = TRUE;
             END;

             PARSE VAR ThisLine . VarName ThisLine;
             DO WHILE (TRUE)

                /* store this value */
                VarAddValue = STRIP( ThisLine);
                VarAddValue = STRIP( VarAddValue);
                IF (LEFT( VarAddValue, 1) = '"') THEN
                   PARSE VAR VarAddValue '"'VarAddValue'"';
                VarValue = VarValue''VarAddValue;

                /* scan nextline */
                IF (fNextLine) THEN
                DO
                   ThisLine = LINEIN( File);
                   Linecount = Linecount + 1;
                   fNextLine = FALSE;
                   IF (RIGHT( STRIP( ThisLine), 1) = '\') THEN
                   DO
                      PARSE VAR ThisLine ThisLine'\'.;
                      fNextLine = TRUE;
                   END;
                END;
                ELSE
                   LEAVE;
             END;

             DefinePending = TRUE;
          END;

          WHEN ((LEFT( Tag, 1) = '#') | (Tage = '')) THEN
          DO
             IF (VarName \= '') THEN
             DO
                VarValue = ReplaceSpecialChars( VarValue);
                rcx = VALUE( VarName, VarValue, env);
                IF (fDebug) THEN
                   SAY '2 storing' VarName '->' VarValue;
             END;
             DefinePending = FALSE;
          END;


          OTHERWISE NOP;
       END;

    END;

    /* store any pending var */
    IF ((DefinePending) & (VarName \= '')) THEN
    DO
       VarValue = ReplaceSpecialChars( VarValue);
       rcx = VALUE( VarName, VarValue, env);
       IF (fDebug) THEN
          SAY 'storing' VarName '->' VarValue;
    END;

    rcx = STREAM( File, 'C', 'CLOSE');
 END;

 RETURN( STRIP( rc ErrorMsg));

/* ========================================================================= */
ProcessScriptIncludeFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File;

 ErrorMsg = '';
 rc = ERROR.NO_ERROR;

 fCommentPending = FALSE;
 CommentStart = '<!--';
 CommentEnd   = '-->';

 Content = '';

 IF (fVerbose) THEN
    SAY '- processing script includefile' File
 DO UNTIL (TRUE)

    DO WHILE (LINES( File))
       ThisLine = LINEIN( File);

       IF (fCommentPending) THEN
       DO
          /* check for end of comment */
          tPos = POS( CommentEnd, ThisLine);
          IF (tPos > 0) THEN
          DO

             fCommentPending = FALSE;
             ThisLine = SUBSTR( ThisLine, tPos + LENGTH( CommentEnd));
             IF (STRIP( ThisLine) = '') THEN
                ITERATE;
          END;
          ELSE
             /* skip lines while comment is pending */
             ITERATE;
       END;
       ELSE
       DO
          /* check for start of comment */
          tPos = POS( CommentStart, ThisLine);
          IF (tPos > 0) THEN
          DO
             fCommentPending = TRUE;
             ThisLine = LEFT( ThisLine, tPos - 1);
             IF (STRIP( ThisLine) = '') THEN
                ITERATE;
          END;
       END;

       /* save as content */
       IF (Content = '') THEN
          Content = ThisLine;
       ELSE
          Content = Content''CrLf''ThisLine;

    END;

    rcx = STREAM( File, 'C', 'CLOSE');
 END;

 RETURN( Content);

