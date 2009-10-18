/****************************** Module Header *******************************
*
* Module Name: instenv.cmd
*
* Syntax: instenv [UNINSTALL]
*
* Helper batch for to be called by all install command files in order to
* init the install environment. It sets env vars that can be read by a
* calling batch file. When called, it checks for the required user ini keys
* first and tries to recreate them if missing. (Another repair CMD is
* RECROBJ.CMD, that will also recreate the objects.)
*
* The following env vars are set:
*
*    Env var                   Sample value
*    ------------------------  ----------------------------------------------
*    NEPMD_ROOTDIR_INST        F:\Apps\NEPMD
*    NEPMD_LANGUAGE_INST       eng
*    NEPMD_USERDIR_INST        F:\Apps\NEPMD\myepm
*    NEPMD_UPDATE_FLAG         1 (0 if RootDir ini key wasn't found)
*    ECS_FLAG                  1
*    OS2_VERSION               4.52
*    ECS_VERSION               2.00
*
* These env vars contain fully resolved values, while the queried ini key
* values for the NEPMD install may contain env vars names or ?: to be
* replaced by the boot drive. Examples:
*
*    Ini key                   Sample value 1          Sample value 2
*    ------------------------  ----------------------  ----------------------
*    RootDir                   F:\Apps\NEPMD           F:\Apps\NEPMD
*    Language                  eng                     eng
*    UserDir                                           %HOME%\myepm
*
*    Corresponding env var     Resulting value 1       Resulting value 2
*    ------------------------  ----------------------  ----------------------
*    NEPMD_ROOTDIR_INST        F:\Apps\NEPMD           F:\Apps\NEPMD
*    NEPMD_LANGUAGE_INST       eng                     eng
*    NEPMD_USERDIR_INST        F:\Apps\NEPMD\myepm     D:\HOME\DEFAULT\myepm
*
* The following env vars can be set before calling this CMD to overwrite
* existing ini key values:
*
*    Env var                   Sample value
*    ------------------------  ----------------------------------------------
*    NEPMD_ROOTDIR_NEW
*    NEPMD_LANGUAGE_NEW        eng
*    NEPMD_USERDIR_NEW         %HOME%\myepm
*
*    These vars support env var resolution. ?: is replaced by the boot drive.
*    Empty values will cause no change.
*
* This CMD handles the case when the user ini (e.g. OS2.INI) keys don't
* exist, e.g. they got lost by applying a WPS backup. Then the RootDir is
* determined from the current filename. An export file, that holds data from
* the previous install, is read and the required ini keys were added to the
* user ini. If UNINSTALL was specified, no ini key will be written.
*
* The versions were determined from syslevel files or OS-specific
* significant files etc.
*
* The env vars were not newly determined if NEPMD_ROOTDIR_INST was already
* set (from a previous call). That allows for calling this CMD without
* checking for existing env vars before.
*
* Copyright (c) netlabs.org EPM Distribution Project 2008
*
* $Id: instenv.cmd,v 1.7 2009-10-18 23:03:26 aschn Exp $
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

'@ECHO OFF'
/*
/* For testing: */
CALL SETLOCAL
*/

/* ----------------- Standard CMD initialization follows ----------------- */
SIGNAL ON HALT NAME Halt

env   = 'OS2ENVIRONMENT'
TRUE  = (1 = 1)
FALSE = (0 = 1)
CrLf  = '0d0a'x
Redirection = '>NUL 2>&1'
PARSE SOURCE . . ThisFile
GlobalVars = 'env TRUE FALSE Redirection ERROR. ThisFile'

/* Some OS/2 Error codes */
ERROR.NO_ERROR           =   0
ERROR.INVALID_FUNCTION   =   1
ERROR.FILE_NOT_FOUND     =   2
ERROR.PATH_NOT_FOUND     =   3
ERROR.ACCESS_DENIED      =   5
ERROR.NOT_ENOUGH_MEMORY  =   8
ERROR.INVALID_FORMAT     =  11
ERROR.INVALID_DATA       =  13
ERROR.NO_MORE_FILES      =  18
ERROR.WRITE_FAULT        =  29
ERROR.READ_FAULT         =  30
ERROR.SHARING_VIOLATION  =  32
ERROR.GEN_FAILURE        =  31
ERROR.INVALID_PARAMETER  =  87
ERROR.ENVVAR_NOT_FOUND   = 204

rc = ERROR.NO_ERROR

CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
CALL SysLoadFuncs
/* ----------------- Standard CMD initialization ends -------------------- */

/* ------------- Configuration ---------------- */
/* INI app names and keys of NEPMD project from OS2.INI, defined in nepmd.h */
NEPMD_INI_APPNAME          = "NEPMD"
NEPMD_INI_KEYNAME_ROOTDIR  = "RootDir"
NEPMD_INI_KEYNAME_LANGUAGE = "Language"
NEPMD_INI_KEYNAME_USERDIR  = "UserDir"

/* Filename of export file, created on install, relative to RootDir */
ExportFileSubPathName = 'netlabs\install\recrobj.dat'

DefaultUserDirName = 'myepm'
DefaultLanguage    = 'eng'

ErrorQueueName = VALUE( 'NEPMD_RXQUEUE',, env)

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage' ||,
             ' BootDrive NEPMD_INI_APPNAME Prev.'
/* -------------------------------------------- */
Prev. = ''
ErrorMessage = ''

/* Check parm */
ARG Parm .
fUninstall = (Parm = 'UNINSTALL')

DO 1
   /* Check if the env is already extended */
   next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
   IF next <> '' THEN
      LEAVE

   /* -------------------------------------------------------------------- */
   /* Get BootDrive */
   BootDrive = GetBootDrive()

   /* -------------------------------------------------------------------- */
   /* Get optinal env vars for to overwrite current ini entries */
   RootDirNew  = QueryNewVar( NEPMD_INI_KEYNAME_ROOTDIR)
   LanguageNew = QueryNewVar( NEPMD_INI_KEYNAME_LANGUAGE)
   UserDirNew  = QueryNewVar( NEPMD_INI_KEYNAME_USERDIR)

   /* -------------------------------------------------------------------- */
   /* Get current ini entries */
   RootDirIni  = QueryIniKey( NEPMD_INI_KEYNAME_ROOTDIR)
   LanguageIni = QueryIniKey( NEPMD_INI_KEYNAME_LANGUAGE)
   UserDirIni  = QueryIniKey( NEPMD_INI_KEYNAME_USERDIR)

   /* -------------------------------------------------------------------- */
   /* It's an update or a new install? */
   UpdateFlag = (RootDirIni <> '')

   /* -------------------------------------------------------------------- */
   /* Maybe overwrite current ini entries */
   IF \fUninstall THEN
   DO
      RootDirIni  = WriteIniKey( NEPMD_INI_KEYNAME_ROOTDIR,  RootDirNew,  RootDirIni)
      LanguageIni = WriteIniKey( NEPMD_INI_KEYNAME_LANGUAGE, LanguageNew, LanguageIni)
      UserDirIni  = WriteIniKey( NEPMD_INI_KEYNAME_USERDIR,  UserDirNew,  UserDirIni)
   END

   /* -------------------------------------------------------------------- */
   /* Get resolved RootDir value */
   RootDirInst  = ResolveEnvVars( RootDirIni)

   /* Use default RootDir if not set */
   IF RootDirInst = '' THEN
      RootDirInst = GetRootDirFromThisFile()

   /* At least RootDir is required to determine the location of the DAT */
   /* file and also for the default UserDir */
   IF RootDirInst = '' THEN
   DO
      ErrorMessage = 'Error: RootDir couldn''t be determined.'
      rc = ERROR.PATH_NOT_FOUND
      LEAVE
   END

   /* -------------------------------------------------------------------- */
   /* Get resolved Language value and maybe previous values */
   LanguagePrev = ''
   UserDirPrev  = ''
   DO 1
      LanguageInst = ResolveEnvVars( LanguageIni)
      IF LanguageInst <> '' THEN LEAVE

      /* Query ini values from previous install from export file if not set. */
      /* Previous UserDir is optional and also determined here. */
      ExportFile = RootDirInst'\'ExportFileSubPathName
      /* GetPrevIniKeys writes ini keys to the global Prev. array */
      rcx = GetPrevIniKeys( ExportFile)
      LanguagePrev = Prev.Language
      UserDirPrev  = Prev.UserDir

      LanguageInst = ResolveEnvVars( LanguagePrev)
      IF LanguageInst <> '' THEN LEAVE

      LanguageInst = DefaultLanguage
   END

   /* -------------------------------------------------------------------- */
   /* Get resolved UserDir value */
   DO 1
      UserDirInst = ResolveEnvVars( UserDirIni)
      IF \ParentExist( UserDirInst) THEN
         UserDirInst = ''
      IF UserDirInst <> '' THEN LEAVE

      UserDirInst = ResolveEnvVars( UserDirPrev)
      IF \ParentExist( UserDirInst) THEN
         UserDirInst = ''
      IF UserDirInst <> '' THEN LEAVE

      UserDirInst  = ResolveEnvVars( RootDirIni'\'DefaultUserDirName)
   END

   /* -------------------------------------------------------------------- */
   /* Write new ini key values, if required */
   IF \fUninstall THEN
   DO
      IF RootDirIni  = '' THEN
         next = WriteIniKey( NEPMD_INI_KEYNAME_ROOTDIR,   RootDirInst,   RootDirIni)
      IF LanguageIni = '' THEN
         next = WriteIniKey( NEPMD_INI_KEYNAME_LANGUAGE,  LanguageInst,  LanguageIni)
      IF \ParentExist( UserDirPrev) THEN
         UserDirPrev = ''
      IF UserDirIni  = '' & UserDirPrev <> '' THEN
         next = WriteIniKey( NEPMD_INI_KEYNAME_USERDIR,   UserDirPrev,   UserDirIni)
   END

   /* -------------------------------------------------------------------- */
   /* Determine OS versions */
   OS = VALUE( 'OS',, env)
   EcsVersion = ''
   Os2Version = ''
   EcsVersionSyslevel = GetVersion( BootDrive'\os2\install\syslevel.ecs')
   Os2VersionSyslevel = GetVersion( BootDrive'\os2\install\syslevel.os2')

   DO 1
      EcsVersion = EcsVersionSyslevel
      IF EcsVersion <> '' THEN LEAVE

      IF TRANSLATE( OS) = 'ECS' THEN
         EcsVersion = '2.0'  /* correct? */
      IF EcsVersion <> '' THEN LEAVE

      IF FileExist( BootDrive'\ecs\dll\SECURIT2.DLL') THEN
         EcsVersion = '1.1'  /* correct? */
      IF EcsVersion <> '' THEN LEAVE

      /* The following is not really safe. The file is copied even */
      /* when the CD is booted only, IIRC. */
      IF FileExist( BootDrive'\wisemachine.fit') THEN
         EcsVersion = '1.0'
   END

   DO 1
      Os2Version = Os2VersionSyslevel
      IF Os2Version <> '' THEN LEAVE

      IF EcsVersion <> '' THEN
         Os2Version = '4.52'
      IF Os2Version <> '' THEN LEAVE

      PARSE VALUE SysVersion() WITH . '.' next
      Os2Version = INSERT( '.', next, 1)
   END

   IF EcsVersion <> '' THEN
      EcsFlag = 1

   /* -------------------------------------------------------------------- */
   /* Set environment */
   CALL VALUE 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',  RootDirInst, env
   CALL VALUE 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_LANGUAGE)'_INST', LanguageInst, env
   CALL VALUE 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_USERDIR)'_INST',  UserDirInst, env
   CALL VALUE 'NEPMD_UPDATE_FLAG', UpdateFlag, env
   CALL VALUE 'ECS_FLAG', EcsFlag, env
   CALL VALUE 'OS2_VERSION', Os2Version, env
   CALL VALUE 'ECS_VERSION', EcsVersion, env

END

/*
SAY 'RootDir  = 'VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',,  env)
SAY 'Language = 'VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_LANGUAGE)'_INST',, env)
SAY 'UserDir  = 'VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_USERDIR)'_INST',,  env)
SAY 'UpdateFlag = 'VALUE( 'NEPMD_UPDATE_FLAG',, env)
SAY 'EcsFlag    = 'VALUE( 'ECS_FLAG',,    env)
SAY 'Os2Version = 'VALUE( 'OS2_VERSION',, env)
SAY 'EcsVersion = 'VALUE( 'ECS_VERSION',, env)
*/

/* ErrorMessage may contain data, even if rc from that is ignored. */
/* NLSETUP ignores messages if rc = 0. */
IF ErrorMessage <> '' THEN
   CALL SayErrorText

EXIT( rc)

/* ----------------------------------------------------------------------- */
/* Gets new env var value if specified, otherwise returns an empty value. */
QueryNewVar: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG IniKey

   EnvVar = VALUE( 'NEPMD_'TRANSLATE( IniKey)'_NEW')
   NewVal = VALUE( EnvVar,, env)

   /*
   SAY EnvVar' = 'NewVal
   */
   RETURN( NewVal)

/* ----------------------------------------------------------------------- */
/* Queries ini key. Returns an empty value on error. */
QueryIniKey: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG IniKey

   IniVal = ''
   IniFile = 'USER'
   IniApp = NEPMD_INI_APPNAME

   next = SysIni( IniFile, IniApp, IniKey)
   IF next <> 'ERROR:' THEN
   DO
      next = STRIP( next, 't', '00'x)
      IF next <> '' THEN
         IniVal = next
   END

   /*
   SAY IniKey'Ini = 'IniVal
   */
   RETURN( IniVal)

/* ----------------------------------------------------------------------- */
/* Maybe writes a new ini value or deletes an old one. Returns either the */
/* changed value or the old value if no change was made.                  */
WriteIniKey: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG IniKey, NewVal, OldVal

   IniFile = 'USER'
   IniApp = NEPMD_INI_APPNAME
   ChangedVal = OldVal

   SELECT
      WHEN NewVal = '' THEN
         NOP
      WHEN TRANSLATE( NewVal) = 'DELETE' THEN
      DO
         next = SysIni( IniFile, IniApp, IniKey, 'DELETE:')
         IF next <> 'ERROR:' THEN
            ChangedVal = ''
      END
      WHEN UserDirNew <> UserDirIni THEN
      DO
         next = SysIni( IniFile, IniApp, IniKey, NewVal'00'x)
         IF next <> 'ERROR:' THEN
            ChangedVal = NewVal
      END
   OTHERWISE
      NOP
   END

   RETURN( ChangedVal)

/* ----------------------------------------------------------------------- */
GetRootDirFromThisFile: PROCEDURE EXPOSE (GlobalVars)
   RootDirInst = ''

   /* ThisFile is usually RootDir'\netlabs\install\instenv.cmd' */
   /* Go 3 levels up to get the RootDir */
   next = ThisFile
   DO i = 1 TO 3
      lp = LASTPOS( '\', next)
      IF lp > 0 THEN
         next = LEFT( next, lp - 1)
      ELSE
         RETURN( '')
   END
   RootDirInst = next

   RETURN( RootDirInst)

/* ------------------------------------------------------------------------- */
ResolveEnvVars: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG Spec

   /* Resolve env vars */
   startp = 1
   DO FOREVER
      p1 = POS( '%', Spec, startp)
      IF p1 = 0 THEN
         LEAVE
      startp = p1 + 1
      p2 = POS( '%', Spec, startp)
      IF p2 = 0 THEN
         LEAVE
      ELSE
      DO
         startp = p2 + 1
         Spec = SUBSTR( Spec, 1, p1 - 1) ||,
                VALUE( SUBSTR( Spec, p1 + 1, p2 - p1 - 1), , env) ||,
                SUBSTR( Spec, p2 + 1 )
      END
   END

   /* Resolve ?: */
   DO WHILE POS( '?:', Spec) <> 0
      PARSE VALUE Spec WITH first'?:'rest
      Spec = first''BootDrive''rest
   END

   RETURN( Spec)

/* ------------------------------------------------------------------------- */
GetPrevIniKeys: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG ExportFile

   /* Read ExportFile */
   IF (STREAM( ExportFile, 'c', 'query exists') = '') THEN
   DO
      ErrorMessage = 'Error: ExportFile "'ExportFile'" doesn''t exist.'
      RETURN( ERROR.FILE_NOT_FOUND)
   END
   ExportLine.  = ''
   ExportLine.0 = 0
   l = 0
   rcx = STREAM( ExportFile, 'c', 'open read')
   DO WHILE LINES( ExportFile) > 0
      l = l + 1
      ExportLine.l = LINEIN( ExportFile)
   END
   ExportLine.0 = l
   rcx = STREAM( ExportFile, 'c', 'close')

   /* Get TargetPath. Supports one common TargetPath for all packages only. */
   TargetPath = ''
   DO l = 1 TO ExportLine.0
      PARSE VAR ExportLine.l num 'TARGETPATH='next
      IF (next <> '') THEN
      DO
         TargetPath = next
         LEAVE
      END
   END
   IF (TargetPath = '') THEN
   DO
      ErrorMessage = 'Error: "TARGETPATH=" not found in "'ExportFile'".'
      RETURN( ERROR.INVALID_DATA)
   END

   /* Replace ?:\ and $(1) in ExportLines */
   DO l = 1 TO ExportLine.0
      ThisLine = ExportLine.l

      OldString = '?:\'
      NewString = BootDrive'\'
      ThisLine = ReplaceString( OldString, ThisLine, NewString)

      OldString = '$(1)'
      NewString = TargetPath
      ThisLine = ReplaceString( OldString, ThisLine, NewString)

      IF ExportLine.l <> ThisLine THEN
      DO
         /*
         SAY 'Old: 'ExportLine.l
         SAY 'New: 'ThisLine
         */
         ExportLine.l = ThisLine
      END

   END

   /* Get ini entries */
   DO l = 1 TO ExportLine.0
      PARSE VAR ExportLine.l num 'PROFILE='next
      IF (next = '') THEN
         ITERATE

      /* With the syntax how WarpIN saves the line, */
      /* a filename can't be specified as Ini:      */
      PARSE VAR next Ini'\'Appl'\'Key'|'Val
      IF TRANSLATE( Ini) <> 'USER' THEN
         ITERATE
      IF Appl <> NEPMD_INI_APPNAME THEN
         ITERATE

      CALL VALUE 'Prev.'Key, Val
      /*
      SAY 'Prev.'Key' = 'Val
      */
   END

   RETURN( ERROR.NO_ERROR)

/* ------------------------------------------------------------------------- */
/* Returns the version in the form <major>'.'<minor><modify> from a syslevel */
/* file. Returns an empty value on an error. */
GetVersion: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG SyslevelFile

   FullVersion = ''
   DO 1
      SyslevelFile = STREAM( SyslevelFile, 'c', 'query exists')
      IF SyslevelFile = '' THEN LEAVE

      CALL STREAM SyslevelFile, 'c', 'open read'
      Line = CHARIN( SyslevelFile, 1, 165)
      CALL STREAM SyslevelFile, 'c', 'close'

      Startp = C2D( REVERSE( SUBSTR( Line, 34, 4))) + 1
      SName = STRIP( SUBSTR( Line, Startp + 23, 80), 't', '00'x)
      SVersion = C2X( SUBSTR( Line, Startp + 3, 1))
      SModify  = C2X( SUBSTR( Line, Startp + 4, 1))
      SLevel = STRIP( STRIP( SUBSTR( line, Startp + 7, 8), 't', '00'x), 't', '_')

      /* Append the Modify num, insert dot after Major num */
      FullVersion = INSERT( '.', SVersion * 10 + SModify, 1)
      /*
      SAY SVersion' - 'SModify' - 'SLevel' - 'SName
      */
   END

   RETURN( FullVersion)

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
   PARSE ARG Filename

   /*RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') <> '')*/

   /* Find also hidden files */
   Found.0 = 0
   rcx = SysFileTree( Filename, 'Found.', 'FO')

   RETURN( Found.0 > 0)

/* ------------------------------------------------------------------------- */
ParentExist: PROCEDURE
   PARSE ARG Filename

   Found.0 = 0
   lp = LASTPOS( '\', Filename)
   IF lp > 0 THEN
   DO
      Dirname = SUBSTR( Filename, 1, lp - 1)
      IF RIGHT( Dirname, 1) = ':' THEN
         Dirname = Dirname'\'
      rcx = SysFileTree( Dirname, 'Found.', 'DO');
   END

   RETURN( Found.0 > 0)

/* ----------------------------------------------------------------------- */
GetBootDrive: PROCEDURE EXPOSE (GlobalVars)
  IF \RxFuncQuery( 'SysBootDrive') THEN
     BootDrive = SysBootDrive()
  ELSE
     PARSE UPPER VALUE VALUE( 'PATH',, env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

  RETURN( BootDrive)

/* ----------------------------------------------------------------------- */
/* Like CHANGESTR */
ReplaceString: PROCEDURE
   PARSE ARG OldString, SourceString, NewString

   Startp = 1
   DO FOREVER
      p1 = POS( OldString, SourceString, Startp)
      IF (p1 = 0) THEN
         LEAVE
      SourceString = INSERT( NewString,,
                             DELSTR( SourceString, p1, LENGTH( OldString)),,
                             p1 - 1)
      Startp = p1 + LENGTH( NewString)
   END

   RETURN( SourceString)

/* ----------------------------------------------------------------------- */
SayErrorText: PROCEDURE EXPOSE (GlobalVars)
   SELECT
      WHEN (ErrorMessage = '') THEN NOP

      /* Called by frame program: insert error */
      /* message into private queue            */
      WHEN (ErrorQueueName <> '') THEN
      DO
         rcx = RXQUEUE( 'SET', ErrorQueueName)
         PUSH ErrorMessage
      END

      /* Called directly */
      OTHERWISE
      DO
         SAY ErrorMessage
         'PAUSE'
      END
   END

   RETURN( '')

/* ----------------------------------------------------------------------- */
Halt:
   ErrorMessage = 'Interrupted by user.'
   CALL SayErrorText
   EXIT( 99)

