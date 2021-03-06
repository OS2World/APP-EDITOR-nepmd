/*
 *      ESRCSCAN.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      This program scans source documentation out of .e files and creates
 *      HyperText/2 compatible output.
 *
 *      Syntax: srcscan source_list source_dir outputpath
 *                      limit_path exclude_list
 *                      [/V[erbose]] [/L[azy]] [/?|/??|/???]
 *
 *      /?    - shows syntax help
 *      /??   - shows source comment syntax help
 *      /???  - shows help about (external) datatypes
 *
 */
/*
 *      header_list      - top level include file(s) (semicolon separated)
 *      base_header_list - headers of the toolkit to be included
 *      source_dir       - source base directory. .c files containing the
 *                         document comments must have the same name like the .h
 *                         files containing the prototypes
 *      outputpath       - outputpath for functions.ipf & datatypes.ipf
 *      limit_path       - path list to limit includes to
 *      exlude_list      - list of filenames (without path!) of files to ignore
 *      /V[erbose]       - verbose output, showing included files
 *      /L[azy]          - do not fail on missing comments
 */
/*
 *      The .c files must
 *      - have the same name as the header file
 *      - contain sections beginning with the following eyecatchers for each
 *        function
 *           @@<funcname>@PROTOTYPE
 *           @@<funcname>@CATEGORY@categoryname
 *           @@<funcname>@SYNTAX
 *           @@<funcname>@PARM@<parm_name>
 *           @@<funcname>@RETURNS
 *           @@<funcname>@REMARKS
 *           @@<funcname>@TESTCASE
 *
 *        Each section is started with the keyword at column one in a line and
 *        ended by the next section or a simple @@ at column 1 in a following line.
 */
/* First three comments are being used as online helptext */
/****************************** Module Header *******************************
*
* Module Name: esrcscan.cmd
*
* Batch for to generate HyperText/2 source out of documentation comments
* in .e source files for the online help.
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


 SIGNAL ON HALT;

 TitleLine = STRIP(SUBSTR(SourceLine(2), 3));
 PARSE VAR TitleLine CmdName'.CMD 'Info
 Title     = CmdName Info

 env          = 'OS2ENVIRONMENT';
 TRUE         = (1 = 1);
 FALSE        = (0 = 1);
 Redirection  = '> NUL 2>&1';
 '@ECHO OFF'

 /* OS/2 errorcodes */
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

 GlobalVars = 'Title CmdName env TRUE FALSE Redirection ERROR.';

 /* show help */
 ARG Parm .
 IF ((Parm = '') | (POS('/?', Parm)) > 0) THEN
 DO
    SELECT
       WHEN (POS('/???', Parm) > 0) THEN Section = 2;
       WHEN (POS('/??', Parm) > 0)  THEN Section = 1;
       OTHERWISE                         Section = 0;
    END;
    rc = ShowHelp( Section);
    EXIT( rc);
 END;

 /* load RexxUtil */
 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 CALL SysLoadFuncs

 /* default values */
 GlobalVars = GlobalVars 'Function. DataType. DocComment. MissingComment. Related. DefineList fVerbose fDebug fCommentError';
 rc         = ERROR.NO_ERROR;

 fCommentError  = TRUE;
 fVerbose       = FALSE;
 fDebug         = FALSE;
 SourceList     = '';
 SourceDir      = '';
 OutDir         = '';
 LimitPath      = '';
 ExcludeList    = '';

 /* init global stems */
 Function.0         = 0;
 Function._List     = '';
 DataType.0         = 0;
 DataType._List     = '';

 DocComment.        = '';
 DocComment._ValidKeys = 'PROTOTYPE CATEGORY SYNTAX PARM EXAMPLE RETURNS REMARKS TESTCASE';
 DocComment._FunctionList = '';

 MissingComment.    = ''
 MissingComment.0   = 0;

 Related.           = '';
 Related._List      = '';

 DO UNTIL (TRUE)

    /* get parms */
    PARSE ARG Parms;
    DO i = 1 TO WORDS(Parms);
       ThisParm = WORD(Parms, i);
       PARSE VAR ThisParm ThisTag':'ThisValue
       ThisTag = TRANSLATE(ThisTag);
       SELECT

          WHEN (POS(ThisTag, '/VERBOSE') = 1) THEN
             fVerbose = TRUE;

          WHEN (POS(ThisTag, '/DEBUG') = 1) THEN
             fDebug = TRUE;

          WHEN (POS(ThisTag, '/LAZY') = 1) THEN
             fCommentError = FALSE;

          OTHERWISE
          DO
             /* handle unix style path names */
             ThisParm = TRANSLATE( ThisParm, '\', '/');
             SELECT
                WHEN (SourceList     = '') THEN SourceList     = ThisParm;
                WHEN (SourceDir      = '') THEN SourceDir      = ThisParm;
                WHEN (OutDir         = '') THEN OutDir         = ThisParm;
                WHEN (LimitPath      = '') THEN LimitPath      = ThisParm;
                WHEN (ExcludeList    = '') THEN ExcludeList    = ThisParm;
                OTHERWISE

                DO
                   SAY CmdName': error: invalid parameters.'
                   rc = ERROR.INVALID_PARAMETER;
                   LEAVE;
                END;
             END;
          END;
       END;
    END;

    /* enough parms specified ? */
    IF (OutDir = '') THEN
    DO
       rc = ShowHelp();
      LEAVE;
    END;

    /* source file there ? */
    FileList = SourceList;
    DO WHILE (FileList \= '')
       PARSE VAR FileList HeaderFile';'FileList;
       IF (\FileExist( HeaderFile)) THEN
       DO
          SAY CmdName': error: file' HeaderFile 'not found.';
          rc = ERROR.FILE_NOT_FOUND;
          LEAVE;
       END;
    END;

    /* get full name of all directories of limitpath */
    NewLimitPath = '';
    DO WHILE (LimitPath \= '')
       PARSE VAR LimitPath ThisPath';'LimitPath;
       IF (ThisPath \= '') THEN
       DO
          /* does directory exist ? */
          NewPath = GetDirName( ThisPath);
          IF (NewPath \= '') THEN
             NewLimitPath = NewLimitPath';'NewPath;
          ELSE
          DO
             SAY CmdName': error: directory' ThisPath 'not found.';
             rc = ERROR.PATH_NOT_FOUND;
             LEAVE;
          END;
       END;
    END;
    IF (rc \= ERROR.NO_ERROR) THEN
       LEAVE;
    LimitPath = NewLimitPath';'

    /* prepare excludelist */
    ExcludeList = TRANSLATE( TRANSLATE( ExcludeList, ' ', ';'));

    /* read source files */
    FileList = SourceList;
    DO WHILE (FileList \= '')
       PARSE VAR FileList HeaderFile';'FileList;
       IF (fVerbose) THEN
          SAY 'Reading' HeaderFile;
       rc = ReadSourceFile( HeaderFile, LimitPath, SourceDir, ExcludeList);
       if (rc \= ERROR.NO_ERROR) THEN
          LEAVE;
    END;
    IF (rc \= ERROR.NO_ERROR) THEN
       LEAVE;

    /* write output file */
    rc = WriteHtextFiles( OutDir);
    if (rc \= ERROR.NO_ERROR) THEN
       LEAVE;

    /* write EPM index file */
    /*
    rc = WriteEPMFiles( OutDir, 'wtkref', 'WPS Toolkit for OS/2');
    if (rc \= ERROR.NO_ERROR) THEN
       LEAVE;
    */


 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
  SAY 'Interrupted by user.';
  EXIT(ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)
 ARG Section;

 SAY;
 SAY Title
 SAY;

 /* read this file directly -> quicker than SOURCELINE() ! */
 PARSE SOURCE . . ThisFile;

 /* skip header */
 DO 3
    rc = LINEIN(ThisFile);
 END;

 /* show main part */
 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 /* now skip n blocks */
 IF (Section = '') THEN Section = 0;
 DO i = 1 TO Section
    ThisLine = LINEIN(Thisfile);
    DO WHILE (ThisLine \= ' */')
       ThisLine = LINEIN(Thisfile);
    END;
 END;

 /* show desired help block */
 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 /* Datei wieder schlie�en */
 rc = LINEOUT(Thisfile);

 RETURN( ERROR.INVALID_PARAMETER);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '');

/* ------------------------------------------------------------------------- */
GetDrivePath: PROCEDURE
 PARSE ARG FileName

 FullPath = FILESPEC('D', FileName)||FILESPEC('P', FileName);
 IF (FullPath \= '') THEN
    RETURN( LEFT( FullPath, LENGTH(FullPath) - 1));
 ELSE
    RETURN( '');

/* ------------------------------------------------------------------------- */
LOWER: PROCEDURE

 Lower = 'abcdefghijklmnopqrstuvwxyz���';
 Upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ���';

 PARSE ARG String
 RETURN( TRANSLATE( String, Lower, Upper));

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
 DirFound  = DIRECTORY( Name);

 /* reset environment */
 rc = DIRECTORY(CurrentDir);
 rc = DIRECTORY(CurrentDrive);

 RETURN( DirFound);

/* ========================================================================= */
IsInList: PROCEDURE
 PARSE ARG String, List;
 RETURN( WORDPOS( string, List) > 0);

/* ========================================================================= */
/* simple string sort */
SortWordsInString: PROCEDURE
 PARSE ARG SortWordsInString;

 NewString = '';
 DO WHILE (SortWordsInString \= '')
    PARSE VAR SortWordsInString ThisString SortWordsInString;

    NewWordPos = LENGTH( NewString);
    DO i = 1 TO WORDS( NewString)
       IF (ThisString < WORD( NewString, i)) THEN
       DO
          NewWordPos = WORDINDEX( NewString, i) - 1;
          LEAVE;
       END;
    END;

    NewString = INSERT( ThisString' ', NewString, NewWordPos);

 END;

 RETURN( NewString);

/* ========================================================================= */
/* read a line and increase line counter */
_READLINE: PROCEDURE EXPOSE LineCount;
 PARSE ARG File;
 LineCount = LineCount + 1;
 RETURN( LINEIN( File));

/* ========================================================================= */
/* read top source file with recursive inclusions while        */
/* not including files not residing in LimitPath or with a name */
/* of the exclude list                                         */

ReadSourceFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File, LimitPath, SourceDir, ExludeList;

 /* default values */
 rc             = ERROR.NO_ERROR;
 LineCount      = 0;
 fCommentActive = FALSE;
 IncludedTag    = '';
 CrLf           = "0d0a"x;

 /* read source file */
 DO WHILE (LINES( File) > 0)

    /* read line */
    ThisLine = _READLINE( File);

    /* is there an open comment ? */
    IF (fCommentActive) THEN
    DO
       CommentEnd = POS( '*/', ThisLine);
       IF (CommentEnd > 0) THEN
       DO
          /* close comment */
          ThisLine = SUBSTR( ThisLine, CommentEnd + 2);
          fCommentActive = FALSE;
       END;
       ELSE
          ITERATE;
    END;

    /* --------------------------------------------------------------------- */

    /* is it a slash/star comment ? */
    CommentStart = POS( '/*', ThisLine);
    DO WHILE (CommentStart > 0)
       /* does the comment not end on this line ? */
       CommentEnd = POS( '*/', ThisLine, CommentStart + 2);
       IF (CommentEnd = 0) THEN
       DO
          fCommentActive = TRUE;
          ThisLine = LEFT( ThisLine, CommentStart - 1);
       END;
       ELSE
          ThisLine = DELSTR( ThisLine, CommentStart, CommentEnd - CommentStart + 2);

       /* search next comment */
       CommentStart = POS( '/*', ThisLine);

    END;

    /* --------------------------------------------------------------------- */

    /* is it a double minus comment line ? */
    CommentPos = POS( '--', ThisLine);
    IF (CommentPos > 0) THEN
       ThisLine = LEFT( ThisLine, CommentPos - 1);


    /* skip empty lines */
    ThisLine = STRIP( ThisLine);
    IF (ThisLine = '') THEN
       ITERATE;

    /* --------------------------------------------------------------------- */
    /* check for include command */
    PARSE VAR ThisLine Command CommandOption;

    IF (Command = 'include') THEN
    DO
       /* check for include file */
       CommandOption = STRIP( CommandOption);
       IncludeChar = LEFT( CommandOption, 1);
       PARSE VAR CommandOption (IncludeChar)IncludeFile(IncludeChar);
       IncludeFileName = SysSearchPath( 'EPMPATH', IncludeFile);

       /* check filename and include path */
       IF (IncludeFileName = '') THEN ITERATE;
       IF (LimitPath \= '') THEN
       DO
          needle = ';'GetDrivePath( IncludeFileName)';';
          haystack = ';'LimitPath';';
          IF (POS( needle, haystack) = 0) THEN
             ITERATE;
       END;

       /* check filename and exclude list */
       IF (ExludeList \= '') THEN
          IF (WORDPOS( TRANSLATE( FILESPEC( 'N', IncludeFileName)), ExludeList) > 0) THEN
          ITERATE;

       /* include the file */
       IF (fVerbose) THEN
          SAY '- including' IncludeFile;
       rc = ReadSourceFile( IncludeFileName, LimitPath, SourceDir, ExcludeList);

       ITERATE;
    END;

    /* --------------------------------------------------------------------- */

 END;

 /* close file */
 rcx = STREAM( File, 'C', 'CLOSE');

 /* now read the docs out of the file */
 rcx = ReadCommentDocs( File);

 RETURN( rc);


/* ========================================================================= */
/* if a comment is missing, store this information  */
StoreMissingComment: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG GivenComment, Function, CommentInfo;

 GivenComment = STRIP( GivenComment);
 CommentInfo  = STRIP( CommentInfo);

 IF (GivenComment = '') THEN
 DO
    c                = MissingComment.0 + 1;
    MissingComment.c = Function '-' CommentInfo;
    MissingComment.0 = c;
 END;

 RETURN( GivenComment);

/* ========================================================================= */
/* return the first line of a comment, where the line stops with */
/* - an epmty line                                               */
/* - a ':' at the forst pos of a line                            */
/* NOTE: the first IPF line of a comment must not include        */
/*       any IPF tags                                            */

FirstIPFLine: PROCEDURE
 PARSE ARG Comment;

 FirstLine    = Comment;
 CrLf         = "0d0a"x;
 ReplaceBytes = '  ';

 IF ((Comment \= '') & (LEFT( Comment, 2) \= CrLf)) THEN
 DO
    BreakPos = POS( CrLf':', Comment);
    IF (BreakPos = 0) THEN
       BreakPos = POS( CrLf''CrLf, Comment);

    IF (BreakPos > 0) THEN
    DO
       FirstLine = LEFT( Comment, BreakPos - 1);
       DO WHILE ( C2D(RIGHT( FirstLine, 1)) < 32)
          FirstLine = LEFT( FirstLine, LENGTH( FirstLine) - 1);
       END;
    END;
    FirstLine = SPACE( TRANSLATE( FirstLine, ReplaceBytes, CrLf));
 END;

 RETURN FirstLine;

/* ========================================================================= */
/* determines the lengh of a line exlcuding IPF tags */
IPFLength: PROCEDURE
 PARSE ARG Line;

 /* determine the length of an IPF string (without IPF tags) */
 Len      = LENGTH( Line);
 IpfLen   = 0;
 StartPos = POS( ':', Line);
 DO WHILE (StartPos > 0)
    EndPos = POS( '.', Line, StartPos);
    IF (EndPos = 0) THEN
       LEAVE;
    IpfLen = IpfLen + EndPos - StartPos + 1;
    StartPos = POS( ':', Line, EndPos);
 END;

 RETURN Len - IpfLen;

/* ========================================================================= */
WriteSection: PROCEDURE EXPOSE (GlobalVars) LogFile
 PARSE ARG FunctionsFile, ThisFunction, ThisId, ThisKey, ThisName, ThisSubtitle, Dimensions;

 CrLf = "0d0a"x;
 Separator = '..' COPIES( '.', 60);
 IF (Dimensions = '') THEN
    Dimensions = '..';
 ELSE
    Dimensions = '.di' Dimensions;

 IF (ThisName = '') THEN
 DO
    Level = 4;
    Panel = DocComment.ThisFunction.ThisKey;
    PanelId = TRANSLATE( ThisId'_'ThisKey);
 END;
 ELSE
 DO
    Level = 5;
    Panel = DocComment.ThisFunction.ThisKey.ThisName;
    PanelId = TRANSLATE( ThisId'_'ThisKey'_'ThisName);
 END;

 IF (Panel \= '') THEN
 DO
    rcx = LINEOUT( FunctionsFile, Separator''CrLf||,
                                  '.'Level ThisFunction '-' ThisSubtitle''CrLf||,
                                  Separator''CrLf||,
                                  Dimensions''CrLf||,
                                  '.an' PanelId''CrLf||,
                                  '.al' ThisSubtitle''CrLf||,
                                  '.. .hide'CrLf||,
                                  '.');
    rcx = LINEOUT( FunctionsFile, Panel);
    rcx = LINEOUT( Logfile, '[.'PanelId']');
 END;
 ELSE
    SAY '  warning:' ThisFunction '-' ThisKey ThisName 'not set';
 RETURN( 0);

/* --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- */

/* write target files */
WriteHtextFiles: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG OutDir;

 /* default values */
 rc = ERROR.NO_ERROR;
 CrLf = "0d0a"x;
 Separator = '..' COPIES( '-', 60);
 LineBreak = CrLf'.'CrLf;

 /* prepare result file */
 FunctionsFile = OutDir'\functions.txt';
 rcx = SysFileDelete( FunctionsFile);
 IF (LINEOUT( FunctionsFile, '')) THEN
 DO
    SAY 'error: cannot write' FunctionsFile;
    RETURN( ERROR.ACCESS_DENIED);
 END;

 /* prepare logfile */
 LogFile = OutDir'\functions.log';
 rcx = SysFileDelete( LogFile);
 rcx = LINEOUT( Logfile, '');
 IF (LINEOUT( Logfile, '')) THEN
 DO
    SAY 'error: cannot write' Logfile;
    RETURN( ERROR.ACCESS_DENIED);
 END;

 rcx = LINEOUT( Logfile, CMDNAME 'at' DATE('E') TIME());
 rcx = LINEOUT( Logfile, COPIES( '-', 70));
 rcx = LINEOUT( Logfile, '');

 /* ***** write function overview, sorted by categories ***************** */

 /* prepare sort of cateogories */
 Category.      = '';
 Category._List = '';
 WorkList = DocComment._FunctionList;
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisFunction WorkList;

    /* get category of this function */
    ThisKey      = 'CATEGORY';
    ThisCategory = WORD( DocComment.ThisFunction.ThisKey._NameList, 1);
    IF (ThisCategory = '') THEN
       ThisCategory = 'DIVERSE';
    ELSE
    DO
       IF (WORDPOS( ThisCategory, Category._List) = 0) THEN
          /* add new category */
          Category._List        = Category._List ThisCategory;
    END;

    Category.ThisCategory = Category.ThisCategory ThisFunction;
 END;

 /* sort categories (excluding DIVERSE) */
 Category._List = SortWordsInString( Category._List);

 /* sort functions in categories */
 rcx = LINEOUT( Logfile, 'Categories found:');
 rcx = LINEOUT( Logfile, '-----------------');
 WorkList = Category._List 'DIVERSE';
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisCategory WorkList;
    Category.ThisCategory = SortWordsInString( Category.ThisCategory);
    rcx = LINEOUT( Logfile, '-' ThisCategory':' Category.ThisCategory);
 END;
 rcx = LINEOUT( Logfile, '');

 /* create lists of categories to include - include DIVERSE only */
 /* if at least function is not categorized properly */
 WorkList = Category._List;
 ThisCategory = 'DIVERSE';
 IF (Category.ThisCategory \= '') THEN
    WorkList = WorkList 'DIVERSE';

 /* build up lists for each category */
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisCategory WorkList;

    rcx = LINEOUT( FunctionsFile, '');
    rcx = LINEOUT( FunctionsFile, '*[=CATEGORY_'ThisCategory']*');
    rcx = LINEOUT( FunctionsFile, '.ul compact');

    FuncList = Category.ThisCategory;
    DO WHILE (FuncList \= '')
    PARSE VAR FuncList ThisFunction FuncList;
       ThisId = 'IDPNL_EFUNC_'TRANSLATE( ThisFunction);
       rcx = LINEOUT( FunctionsFile, '- [.'ThisId']');
    END;
 END;
 rcx = LINEOUT( FunctionsFile, '');

 /* ********************** write function sub pages ********************* */



 WorkList = SortWordsInString( DocComment._FunctionList);
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisFunction WorkList;

    /* ---------------------- navigation panel ----------------------------- */

    IF (fVerbose) THEN
       SAY '- processing' ThisFunction;
    rcx = LINEOUT( Logfile, '');
    rcx = LINEOUT( Logfile, ThisFunction);
    rcx = LINEOUT( Logfile, COPIES( '-', LENGTH( ThisFunction)));

    ThisId = 'IDPNL_EFUNC_'TRANSLATE( ThisFunction);
    rcx = LINEOUT( FunctionsFile, Separator''CrLf||,
                                  '.3' ThisFunction''CrLf||,
                                  Separator''CrLf||,
                                  '.an' ThisId''CrLf||,
                                  '.'CrLf||,
                                  '[=TOPICS]'CrLf||,
                                  '.'CrLf||,
                                  '.su V30 breaks 1'CrLf||,
                                  '');

    /* ---------------------- syntax panel --------------------------------- */

    /* add prototype to syntax section */
    ThisKey = 'PROTOTYPE';
    IF (DocComment.ThisFunction.ThisKey \= '') THEN
    DO
       SyntaxKey  = 'SYNTAX';
       ParmKey    = 'PARM';
       ReturnsKey = 'RETURNS';

       /* scan prototype and insert links */
       Prototype = DocComment.ThisFunction.ThisKey;
       PARSE VAR Prototype ResultPart'='FunctionPart;
       IF FunctionPart = '' THEN
       DO
          ResultPart = ''
          FunctionPart = Prototype
       END
       PARSE VAR FunctionPart FunctionName'('FunctionParms')';

       /* insert link for function result */
       IF ((ResultPart \= '') & (DocComment.ThisFunction.ReturnsKey \= '')) THEN
          ResultPart = '[.'ThisId'_RETURNS' ResultPart']';

       /* insert links for known parameters */
       NewFunctionParms = '';
       DO WHILE (FunctionParms \= '')
          PARSE VAR FunctionParms ThisParm','FunctionParms;
          ThisParm = STRIP( Thisparm);
          ThisParmFn = Thisparm;
          IF (TRANSLATE( WORD( ThisParmFn, 1)) = 'VAR') THEN
             ThisParmFn = WORD( ThisParmFn, 2);
          ThisParmId = TRANSLATE( ThisParmFn);
          IF (DocComment.ThisFunction.ParmKey.ThisParmFn \= '') THEN
             ThisParm = '[.'ThisId'_PARM_'ThisParmId ThisParm']';
          NewFunctionParms = NewFunctionParms',' ThisParm;
       END;
       IF (LEFT( NewFunctionParms, 1) = ',') THEN
          NewFunctionParms = SUBSTR( NewFunctionParms, 2);

       /* reassemble prototype */
       IF ResultPart = '' THEN
          Prototype = FunctionName'('NewFunctionParms')';
       ELSE
          Prototype = ResultPart '='FunctionName'('NewFunctionParms')';


       /* add result to syntax section */
       DocComment.ThisFunction.SyntaxKey = DocComment.ThisFunction.SyntaxKey||,
                                        '.fo off'CrLf||,
                                        Prototype''CrLf||,
                                        '.fo on'CrLf;
    END;

    rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'SYNTAX', '', 'Syntax');

    /* ---------------------- parameters panel ----------------------------- */

    /* write parameter overview panel */
    ThisKey = 'PARM';
    IF (DocComment.ThisFunction.ThisKey._Namelist \= '') THEN
    DO
       ParmList = DocComment.ThisFunction.ThisKey._Namelist;
       DocComment.ThisFunction.ThisKey = '..'CrLf;
       DO WHILE (ParmList \= '')
          PARSE VAR ParmList ThisParm ParmList;

          /* add parameter to the parameter overview */
          ParmDoc = '*'ThisParm'*'CrLf||,
                    '.'CrLf||,
                    '.lm 4'CrLf||,
                    DocComment.ThisFunction.ThisKey.ThisParm||,
                    '.lm 1'CrLf||,
                    ''CrLf;
          DocComment.ThisFunction.ThisKey = DocComment.ThisFunction.ThisKey''ParmDoc;
       END;

       /* append returns section to the parameter overview */
       ReturnKey = 'RETURNS';
       ReturnDoc = '*return value*'CrLf||,
                    '.'CrLf||,
                    '.lm 4'CrLf||,
                    DocComment.ThisFunction.ReturnKey||,
                    '.lm 1'CrLf||,
                    ''CrLf;
       DocComment.ThisFunction.ThisKey = DocComment.ThisFunction.ThisKey''ReturnDoc;

       rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'PARM', '', 'Parameters');
    END;

    /* ---------------------- per parameter panel -------------------------- */

    /* write one subsection per parameter */
    ThisKey = 'PARM';
    IF (DocComment.ThisFunction.ThisKey._Namelist \= '') THEN
    DO
       ParmList = DocComment.ThisFunction.ThisKey._Namelist;
       DocComment.ThisFunction.ThisKey = '..'CrLf;
       DO WHILE (ParmList \= '')
          PARSE VAR ParmList ThisParm ParmList;

          rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'PARM', ThisParm, 'Parameter' ThisParm, '0 0 100 50');
       END;
    END;

    /* ---------------------- returns panel -------------------------------- */

    rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'RETURNS', '', 'Returns', '0 0 100 50');

    /* ---------------------- optional examples panel ---------------------- */

    ThisKey = 'EXAMPLE';
    IF (DocComment.ThisFunction.ThisKey \= '') THEN
       rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'EXAMPLE', '', 'Example Code');

    /* ---------------------- optional remarks panel ----------------------- */

    ThisKey = 'REMARKS';
    IF (DocComment.ThisFunction.ThisKey \= '') THEN
       rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'REMARKS', '', 'Remarks');

    /* ---------------------- optional remarks panel ----------------------- */

    ThisKey = 'TESTCASE';
    IF (DocComment.ThisFunction.ThisKey \= '') THEN
       rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'TESTCASE', '', 'Testcase');

    /* ---------------------- related panel, where appropriate ------------- */

    ThisKey      = 'CATEGORY';
    ThisCategory = WORD( DocComment.ThisFunction.ThisKey._NameList, 1);
    IF ((ThisCategory \= 'DIVERSE') & (WORDS( Category.ThisCategory) > 1)) THEN
    DO
       /* remove this function from linklist */
       wPos = WORDPOS( ThisFunction, Category.ThisCategory);
       LinkList = DELWORD( Category.ThisCategory, wPos, 1);

       /* assemble new subpanel panel */
       ThisKey = 'RELATED';
       DocComment.ThisFunction.ThisKey = '*Related Functions*'CrLf||,
                                         '.ul compact';
       DO WHILE (LinkList \= '')
          PARSE VAR LinkList ThisLink LinkList;
          LinkId = 'IDPNL_EFUNC_'TRANSLATE( ThisLink);
          DocComment.ThisFunction.ThisKey = DocComment.ThisFunction.ThisKey''CrLf||,
                                            '- [.'LinkId']';
       END;
       DocComment.ThisFunction.ThisKey = DocComment.ThisFunction.ThisKey''CrLf;

       rcx = WriteSection( FunctionsFile, ThisFunction, ThisId, 'RELATED', '', 'Related functions', '40 0 60 100');
    END;

 END;

 /* ********************* check missing comments ************************ */

 /* tell specific missing comments first */
 MissingFuncs = '';
 IF (fCommentError) THEN
    MsgType = 'Error:';
 ELSE
    MsgType = 'Warning:';

 DO i = 1 TO MissingComment.0
    PARSE VAR MissingComment.i ThisFunction ThisInfo;

    IF (DocComment.ThisFunction._Found = '') THEN
    DO
       IF (WORDPOS( ThisFunction, MissingFuncs) = 0) THEN
          MissingFuncs = MissingFuncs ThisFunction;
    END;
    ELSE
       SAY MsgType 'missing comment for:' ThisFunction ThisInfo;
 END;

 /* now tell about functions without any comment */
 DO WHILE (MissingFuncs \= '')
    PARSE VAR  MissingFuncs ThisFunction MissingFuncs ;
    SAY MsgType  'missing any comment for:' ThisFunction;
 END;

 /* close files */
 rcx = STREAM( FunctionsFile, 'C', 'CLOSE');
 rcx = STREAM( LogFile, 'C', 'CLOSE');

 /* tell about error*/
 IF ((fCommentError) & (MissingComment.0 > 0)) THEN
 DO
    rcx = SysFileDelete( FunctionsFile);
    rc = ERROR.INVALID_DATA;
 END;


 RETURN( rc);

/* ========================================================================= */
/* return the datatype with regard to the "implicit pointer type "Pxxxxx" rule */
CheckDataType: PROCEDURE
 PARSE ARG Type, Typelist;

 Type = STRIP( TRANSLATE( Type, ' ', '*')); /* strip stars */
 NewType   = Type;

 IF ((WORDPOS( Type, TypeList) = 0) & (LEFT( Type, 1) = 'P')) THEN
 DO
    /* is it a Ptype of one of our datatypes ? Then reference to this one */
    IF (WORDPOS( SUBSTR( Type, 2), Typelist) > 0) THEN
       NewType = SUBSTR( Type, 2);
 END;

 RETURN( NewType);

/* ========================================================================= */
/* relayouts variable type and variable name:                                */
/* if type has a '*' at the end, remove it from type and append it as symbol */
/* to the name                                                               */
GetIpfNameType: PROCEDURE
 PARSE ARG Type, Name
 IF (RIGHT( Type, 1) = '*') THEN
 DO
 Type = LEFT( Type, LENGTH( Type) - 1);
 Name = '&asterisk.'Name;
 END;
 RETURN( Type Name);

/* ========================================================================= */
/* read .e file and catch all online doc comments */
ReadCommentDocs: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File;

 /* defaults */
 rc   = ERROR.NO_ERROR;
 CrLf = "0d0a"x;

 /* read header file */
 ThisLine = LINEIN( File);
 DO WHILE (LINES( File) > 0)

    /* determine the tag */
    PARSE VAR ThisLine '@@'ThisFunction'@'ThisKey'@'ThisName;
    IF (ThisFunction \= '') THEN
    DO
       ThisKey = TRANSLATE( ThisKey);

       /* check key */
       IF (WORDPOS( ThisKey, DocComment._ValidKeys) = 0) THEN ITERATE;

       /* extend function list */
       IF (WORDPOS( ThisFunction, DocComment._FunctionList) = 0) THEN
          DocComment._FunctionList = DocComment._FunctionList ThisFunction;

       /* if there is a name given, maintain subsection list */
       IF (ThisName \= '') THEN
       DO
          /* add subsection name */
          IF (WORDPOS( ThisName, DocComment.ThisFunction.ThisKey._Namelist) = 0) THEN
             DocComment.ThisFunction.ThisKey._Namelist = DocComment.ThisFunction.ThisKey._Namelist ThisName;
       END;

       /* store the info */
       NextLine = LINEIN( File);
       DO WHILE ( LEFT( NextLine, 2) \= '@@')

          /* handle key values */
          IF (ThisName = '') THEN
             DocComment.ThisFunction.ThisKey = DocComment.ThisFunction.ThisKey''CrLf''NextLine;
          ELSE
          /* handle key/name values values */
             DocComment.ThisFunction.ThisKey.ThisName = DocComment.ThisFunction.ThisKey.ThisName''CrLf''NextLine;
          NextLine = LINEIN( File);
       END;

       /* extend section */
       IF (ThisName = '') THEN
          DocComment.ThisFunction.ThisKey          = SUBSTR( DocComment.ThisFunction.ThisKey, 3);
       ELSE
          DocComment.ThisFunction.ThisKey.ThisName = SUBSTR( DocComment.ThisFunction.ThisKey.ThisName, 3);

       /* state that something for this function has been found ! */
       DocComment.ThisFunction._Found = 1;

       /* go on with the line last read */
       ThisLine = NextLine;

       ITERATE;

    END;

    /* read next line */
    ThisLine = LINEIN( File);

 END;

 RETURN( rc);

/* ========================================================================= */
/* write help index file and EPM keyword file */
WriteEPMFiles: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG OutDir, BookName, Description;

 /* default values */
 rc       = ERROR.NO_ERROR;
 CrLf     = "0d0a"x;
 Tab      = "09"x;
 StemList = '';

 BgColor  = '-1';
 FgColor  = '5';

 /* write index file */
 File = OutDir'\wpstk.ndx';
 rcx = SysFileDelete( File);

 rc = LINEOUT( File, 'EXTENSIONS: *');
 rc = LINEOUT( File, 'DESCRIPTION:' Description);

 /* check functions */
 WorkList = Function._List;
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisFunction WorkList;
    ThisStem = GetFuncStem( ThisFunction);
    IF (WORDPOS( ThisStem, StemList) = 0) THEN
       StemList = StemList ThisStem;
 END;
 StemList = SortWordsInString( StemList);
 DO WHILE (StemList \= '')
    PARSE VAR StemList ThisStem StemList;
 rc = LINEOUT( File, '('ThisStem'*, view' BookName '~)');
 END;

 rcx = STREAM( File, 'C', 'CLOSE');

 /* write hilighting file */
 File = OutDir'\epmkwds.c__';
 rcx = SysFileDelete( File);

 /* write lines for functions */
 rc = LINEOUT( File, '@ ------------ ' Description ' functions --------------');
 WorkList = SortWordsInString( Function._List);
 WorkList = SortWordsInString( Function._List);
 DO WHILE (WorkList \= '')
    PARSE VAR WorkList ThisFunction WorkList;
    rc = LINEOUT( File, ThisFunction''Tab''BgColor''Tab''FgColor);
 END;

 rcx = STREAM( File, 'C', 'CLOSE');

 RETURN( rc);

/* ========================================================================= */
/* return the first part of a functions name */
GetFuncStem: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Name;

 FromChars = XRANGE( 'a', 'z');
 ToChars   = COPIES( ' ', LENGTH( FromChars));
 CheckName = TRANSLATE( Name, ToChars, FromChars);
 RETURN( LEFT( Name, WORDINDEX( CheckName, 2) - 1));

