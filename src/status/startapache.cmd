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
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: startapache.cmd,v 1.6 2003-09-19 10:10:54 cla Exp $
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

 ApacheExec      = Apache._Dir'\httpd.exe';
 ConfigSource    = Apache._Dir'\'ConfigSource;

 DO UNTIL (1)

    /* check for required files */
    MissingFiles = '';
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
       'call gfc' ConfigSource ConfigTmp;

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

 CrLf = '0d0a'x;

 /* setup replacement rules */
 Strings.  = '';
 Strings.1._old    = '@@ServerRoot@@/htdocs'
 Strings.1._insert = Apache._DocRoot;

 Strings.2._old    = '@@ServerRoot@@'
 Strings.2._insert = Apache._Dir;

 Strings.3._old = 'Port 80';
 Strings.3._new = 'Port' Apache._Port;

 Strings.4._old = '#ServerName new.host.name';
 Strings.4._new = 'ServerName 'Apache._Servername;

 Strings.5._old = 'AddType application/x-tar .tgz'
 Strings.5._new = Strings.5._old''CrLf||,
                  '    AddType application/x-httpd-php .php .php3 .php4'CrLf||,
                  '    AddType application/x-httpd-php-source .phps';

 Strings.6._old = 'Options Indexes FollowSymLinks MultiViews';
 Strings.6._new = 'Options -Indexes FollowSymLinks MultiViews';

 Strings.7._old = 'AllowOverride None';
 Strings.7._new = 'AllowOverride All';

 Strings.0 = 7;

 Adds.1 = 'LoadModule php4_module libexec/libphp4.dll';
 Adds.0 = 1;

 rc = 1;

 DO 1
    /* Open files */
    rcx = SysFileDelete( TargetFile);
    IF (STREAM( SourceFile, 'C', 'OPEN READ') \= 'READY:') THEN
       LEAVE;
    IF (STREAM( TargetFile, 'C', 'OPEN WRITE') \= 'READY:') THEN
       LEAVE;

    /* start with additions at the beinning */
    DO i = 1 TO Adds.0
       rcx = LINEOUT( TargetFile, Adds.i);
    END;



    /* transform content */
    DO WHILE (LINES( SourceFile) > 0)

       ThisLine = LINEIN( SourceFile);

       DO i = 1 TO Strings.0
          StrPos = POS( Strings.i._old, ThisLine);
          IF (StrPos > 0) THEN
          DO
             IF (Strings.i._new = '') THEN
             DO
                ThisLine = DELSTR( ThisLine, StrPos, LENGTH( Strings.i._old));
                ThisLine = INSERT( Strings.i._insert, ThisLine, StrPos - 1);
             END;
             ELSE
             DO
                Indent = WORDINDEX( ThisLine, 1);
                ThisLine = COPIES( ' ', Indent - 1)''Strings.i._new;
             END;
             LEAVE;
          END;
       END;

       rcx = LINEOUT( TargetFile, ThisLine);
    END;
    rcx = STREAM( SourceFile, 'C', 'CLOSE');
    rcx = STREAM( TargetFile, 'C', 'CLOSE');

    rc = 0;

 END;

 RETURN( rc);

