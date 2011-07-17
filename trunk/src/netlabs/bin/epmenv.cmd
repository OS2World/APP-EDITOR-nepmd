/*
 *      EPMENV.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: EPMENV
 *
 *      This batchfile loads the extended environment of the
 *      Netlabs EPM distribution from a main and a user environment file.
 *
 *      main environment file is loaded from:
 *         <calldir>\<cmdname>.env
 *         <nepmd_rootdir>\netlabs\bin\<cmdname>.env
 *         <nepmd_rootdir>\netlabs\bin\epm.env
 *
 *      user environment file is loaded from:
 *         <currentdir>\<cmdname>.env
 *         <nepmd_userdir>\bin\<cmdname>.env
 *         <nepmd_userdir>\bin\epm.env
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: epmenv.cmd
*
* Helper batch for load the extended environment of the
* Netlabs EPM distribution
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
 PARSE VAR TitleLine CmdName'.CMD 'Info
 Title     = CmdName Info

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
 SAY;

 CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 CALL SysLoadFuncs;

 /* eventually show help */
 ARG Parm .
 IF (POS('?', Parm) > 0) THEN
 DO
    rc = ShowHelp();
    EXIT(ERROR.INVALID_PARAMETER);
 END;

 /* default values */
 GlobalVars = GlobalVars '';
 rc = ERROR.NO_ERROR;

 CallDir          = GetCalldir();
 CallName         = GetCallName();

 IniAppName       = 'NEPMD';
 IniKeyRootDir    = 'RootDir';
 IniKeyUserDir    = 'UserDir';            /* optional */
 InKeyUseHome     = 'UseHomeForUserDir';
 InKeyUserDirName = 'UserDirName';
 IniKeyLanguage   = 'Language';

 NepmdSubdir      = 'netlabs\bin';
 UserSubdir       = 'bin';

 EpmEnvFile       = 'epm';
 EnvExt           = '.env';

 RootDir          = ''
 UserDir          = ''
 fUseHome         = 0
 UserDirName      = 'myepm'

 DO UNTIL (TRUE)

    /* get the base directory of the NEPMD installation */
    PARSE VALUE SysIni(, IniAppName, IniKeyRootDir) WITH RootDir'00'x;
    IF (RootDir = 'ERROR:') THEN
       RootDir = '';
    /* get the user directory of the NEPMD installation */
    PARSE VALUE SysIni(, IniAppName, IniKeyUserDir) WITH next'00'x;
    IF (next <> 'ERROR:') THEN
       UserDir = next;
    IF UserDir = '' THEN
    DO
       PARSE VALUE SysIni(, IniAppName, IniKeyUseHome) WITH next'00'x;
       IF (WORDPOS( next, '0 1')) THEN
          fUseHome = next;
       PARSE VALUE SysIni(, IniAppName, IniKeyUserDirName) WITH next'00'x;
       IF (next <> 'ERROR:' & next > '') THEN
          UserDirName = next;
       IF fUseHome = 1 THEN
       DO
          Home = VALUE( 'HOME', , env);
          UserDir = Home'\'UserDirName;
       END
       ELSE
          UserDir = RootDir'\'UserDirName;
    END
    /* get the language of the NEPMD installation */
    PARSE VALUE SysIni(, IniAppName, IniKeyLanguage) WITH Language'00'x;
    IF (Language = 'ERROR:') THEN
       Language = '';

    /* get currentdir with no slash */
    CurrentDir = DIRECTORY();
    IF (RIGHT( CurrentDir, 1) = '\') THEN
       PARSE VAR CurrentDir CurrentDir'\';

    /* check if extended environment was already extended */
    MainEnvFile = VALUE('NEPMD_MAINENVFILE', , env);
    UserEnvFile = VALUE('NEPMD_USERENVFILE', , env);
    IF (MainEnvFile = '' & UserEnvFile = '') THEN
    DO
       /* load main environment */
       /*fUseEpmEnv = (TRANSLATE( CallName) = TRANSLATE( EpmEnvFile));  Unused */
       MainEnvFile = SearchEnvFile( CallDir'\'CallName''EnvExt,,
                                    RootDir'\'NepmdSubdir'\'CallName''EnvExt,,
                                    RootDir'\'NepmdSubdir'\'EpmEnvFile''EnvExt);

       /* load user environment file */
       /*fUseEpmEnv = (TRANSLATE( CallName) = TRANSLATE( EpmEnvFile));  Unused */
       UserEnvFile = SearchEnvFile( CurrentDir'\'CallName''EnvExt,,
                                    UserDir'\'UserSubdir'\'CallName''EnvExt,,
                                    UserDir'\'UserSubdir'\'EpmEnvFile''EnvExt);

       /* don't load same file twice */
       IF (TRANSLATE(MainEnvFile) = TRANSLATE(UserEnvFile)) THEN
          UserEnvFile = '';

       /* set the automatic variables */
       rc = VALUE( 'NEPMD_ROOTDIR',     RootDir, env);
       rc = VALUE( 'NEPMD_USERDIR',     UserDir, env);
       rc = VALUE( 'NEPMD_LANGUAGE',    Language, env);
       rc = VALUE( 'NEPMD_MAINENVFILE', MainEnvFile, env);
       rc = VALUE( 'NEPMD_USERENVFILE', UserEnvFile, env);


       IF (MainEnvFile \= '') THEN
          rc = LoadEnvFile( 'main', MainEnvFile);
       IF (UserEnvFile \= '') THEN
          rc = LoadEnvFile( 'user', UserEnvFile);

    END
    ELSE
    DO
       /* skip environment extension if already extended */
       SAY "Skip environment extension, already set with:";
       SAY MainEnvFile", "UserEnvFile".";
    END;
 END;

 EXIT( rc);

/* ------------------------------------------------------------------------- */
HALT:
 SAY 'Interrupted by user.';
 EXIT(ERROR.GEN_FAILURE);

/* ------------------------------------------------------------------------- */
ShowHelp: PROCEDURE EXPOSE (GlobalVars)

 /* show title */
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
GetCalldir: PROCEDURE
PARSE SOURCE . . CallName
 CallDir = FILESPEC('Drive', CallName)||FILESPEC('Path', CallName);
 RETURN(LEFT(CallDir, LENGTH(CallDir) - 1));

/* ========================================================================= */
GetCallName: PROCEDURE
PARSE SOURCE . . CallName
 CallBasename = FILESPEC('N', CallName);
 RETURN( LEFT( CallBasename, POS( '.', CallBasename) - 1));

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName
 /* SAY '->' FileName */
 RETURN(STREAM(FileName, 'C', 'QUERY EXISTS') > '');

/* ========================================================================= */
SearchEnvFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG File1, File2, File3;

 EnvFile = '';
 SELECT
    WHEN (FileExist( File1)) THEN EnvFile = File1;
    WHEN (FileExist( File2)) THEN EnvFile = File2;
    WHEN (FileExist( File3)) THEN EnvFile = File3;
    OTHERWISE NOP;
 END;

 RETURN( EnvFile);

/* ========================================================================= */
LoadEnvFile: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Type, File;

 SAY type 'environment file:' File
 rcx = STREAM( File, 'C', 'OPEN READ');

 DO WHILE (LINES( File) > 0)

    /* read line and skip comments */
    ThisLine = LINEIN( File);
    IF (LEFT( ThisLine, 1) = ':') THEN ITERATE;
    IF (STRIP( ThisLine) = '') THEN ITERATE;
    IF (POS( '=', ThisLine) = 0) THEN ITERATE;

    /* get varname and value */
    PARSE VAR ThisLine EnvVar'='EnvValue;
    EnvVar = TRANSLATE( STRIP( EnvVar));

    /* replace variables in value */
    vStart = POS( '%', EnvValue);
    DO WHILE (vStart > 0)
       vEnd = POS( '%', EnvValue, vStart + 1);

       /* if no end of varname is specified, cut of string and break */
       IF (vEnd = 0) THEN
       DO
          EnvValue = LEFT( EnvValue, vStart - 1);
          LEAVE;
       END;

       /* eliminate varname and insert value */
       VarName  = SUBSTR( EnvValue, vStart + 1, vEnd - vStart - 1);
       VarValue = VALUE( VarName,,env);
       EnvValue = DELSTR( EnvValue, vStart, vEnd - vStart + 1);
       EnvValue = INSERT( VarValue, EnvValue, vStart - 1);

       /* next value */
       vStart = POS( '%', EnvValue);
    END;

    /* store value */
    rcx = VALUE( EnvVar, EnvValue, env);

 END;

 /* close file */
 rcx = STREAM( File, 'C', 'CLOSE');

 RETURN( ERROR.NO_ERROR);

