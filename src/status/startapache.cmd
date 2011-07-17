/****************************** Module Header *******************************
*
* Module Name: startapache.cmd
*
* Script to start a test instance of Apache on port 55555.
* For that a copy of conf\httpd.conf-dist-os is written to
* TMP and modified.
*
* NOTE:
*  - the env var APACHE_ROOT must point to the root directory of
*    the Apache installation
*  - the Apache installation must include PHP4 support
*  - SED.EXE is required to be accessible within the PATH
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

 '@ECHO OFF'
 env = 'OS2ENVIRONMENT';
 rcx = SETLOCAL();

 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 CALL SysLoadFuncs

 /* read anvironment */
 'CALL statusenv'
 Apache._Stem       = VALUE( 'APACHE_STEM',,env);
 Apache._Dir        = VALUE( 'APACHE_ROOT',,env);
 Apache._Port       = VALUE( 'APACHE_PORT',,env);
 Apache._DocRoot    = VALUE( 'APACHE_DOCROOT',,env);
 Apache._Servername = VALUE( 'APACHE_SERVERNAME',,env);

 /* defaults */
 TmpDir          = VALUE( 'TMP',,env);
 ConfigSource    = 'conf\httpd.conf-dist-os2';
 ConfigTmp       = TmpDir'\'Apache._Stem'.conf';
 ConfigTitle     = 'Apache' Apache._Stem;

 Apache._Dir     = unixpath( Apache._Dir);
 Apache._DocRoot = unixpath( GetDirName( Apache._DocRoot));
 UsedConfig      = unixpath( ConfigTmp);

 SedExec         = SysSearchPath( 'PATH', 'SED.EXE');
 ApacheExec      = Apache._Dir'\httpd.exe';
 ConfigSource    = Apache._Dir'\'ConfigSource;

 DO UNTIL (1)

    /* check for required files */
    MissingFiles = '';
    IF (SedExec = '') THEN
       MissingFiles = MissingFiles 'SED.EXE';
    MissingFiles = MissingFiles CheckMissingFile( ConfigSource);
    MissingFiles = MissingFiles CheckMissingFile( ApacheExec);
    IF (MissingFiles \= '') THEN
    DO
       SAY;
       SAY 'error: the apache configuration cannot be determined.';
       SAY 'The following files are missing:';
       SAY '  ' MissingFiles;
       SAY;
       rc = 2;
       LEAVE;
    END;

    /* prepare configuration */
    rc = SetupConfig( ConfigSource, ConfigTmp);
    IF (rc \= 0) THEN
       LEAVE;

    /* debug with gfc */
    /* 'call gfc' ConfigSource ConfigTmp; */

    /* startup server */
    rcx = DIRECTORY( Apache._Dir);
    'start /MIN /C "'ConfigTitle '-' Apache._Port '" httpd -d . -f' UsedConfig;

 END;

 EXIT( rc);

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
 rc = DIRECTORY( CurrentDir);
 rc = DIRECTORY( CurrentDrive);

 RETURN( DirFound);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN(STREAM(Filename, 'C', 'QUERY EXISTS') > '');

/* =========================================================================== */
unixpath: PROCEDURE
 PARSE ARG Path;
 RETURN( TRANSLATE( Path, '/', '\'));

/* ========================================================================= */
CheckMissingFile: PROCEDURE
 PARSE ARG Filename;

 IF (\FileExist( Filename)) THEN
    RETURN( FILESPEC( 'N', Filename));
 ELSE
    RETURN('');

/* ========================================================================= */
SetupConfig: PROCEDURE EXPOSE Apache.;
 PARSE ARG SourceFile, TargetFile;

 /* setup replacement rules */
 Strings.1._old = '@@ServerRoot@@/htdocs'
 Strings.1._new = Apache._DocRoot;

 Strings.2._old = '@@ServerRoot@@'
 Strings.2._new = Apache._Dir;

 Strings.3._old = 'Port 80';
 Strings.3._new = 'Port' Apache._Port;

 Strings.4._old = '#ServerName new.host.name';
 Strings.4._new = 'ServerName 'Apache._Servername;

 Strings.5._old = '#AddType application/x-httpd-php .php';
 Strings.5._new = 'AddType application/x-httpd-php .php .php3 .php4';

 Strings.6._old = '#AddType application/x-httpd-php-source .phps';
 Strings.6._new = 'AddType application/x-httpd-php-source .phps';

 Strings.7._old = 'Options Indexes FollowSymLinks MultiViews';
 Strings.7._new = 'Options -Indexes FollowSymLinks MultiViews';

 Strings.8._old = 'AllowOverride None';
 Strings.8._new = 'AllowOverride All';

 Strings.0 = 8;

 Rules = '';
 DO i = 1 TO Strings.0
    Rules = Rules  '-e "s+'Strings.i._old'+'Strings.i._new'+g"';
 END;

 /* create config file from source file */
 echo 'LoadModule php4_module libexec/libphp4.dll' '>'  TargetFile;
 'sed' Rules '<' SourceFile '>>' TargetFile;

 RETURN( rc);

