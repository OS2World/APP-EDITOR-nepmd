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
* $Id: startapache.cmd,v 1.2 2002-07-17 16:03:06 cla Exp $
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

 Stem = 'NEPMD-Status';
 HttpPort       = '55555';
 HttpDocRoot    = DIRECTORY();
 HttpServerName = 'localhost';

 ApacheDir      = VALUE( 'APACHE_ROOT',,env);

 TmpDir         = VALUE( 'TMP',,env);
 ConfigSource   = 'conf\httpd.conf-dist-os2';
 ConfigTmp      = TmpDir'\'Stem'.conf';
 ConfigTitle    = 'Apache' Stem;

 DO UNTIL (1)

    ConfigSource = ApacheDir'\'ConfigSource;

    ServerRoot = unixpath( ApacheDir);
    DocRoot = unixpath( HttpDocRoot);

    /* setup replacement rules */
    Strings.1._old = '@@ServerRoot@@/htdocs'
    Strings.1._new = DocRoot;

    Strings.2._old = '@@ServerRoot@@'
    Strings.2._new = ServerRoot;

    Strings.3._old = 'Port 80';
    Strings.3._new = 'Port' HttpPort;

    Strings.4._old = '#ServerName new.host.name';
    Strings.4._new = 'ServerName 'HttpServerName;

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
    echo 'LoadModule php4_module libexec/libphp4.dll' '>'  ConfigTmp;
    'sed' Rules '<' ConfigSource    '>>' ConfigTmp;
    UsedConfig = unixpath( ConfigTmp);

    'rem call gfc' ConfigSource ConfigTmp


    rcx = DIRECTORY( ApacheDir);
    'start /MIN /C "'ConfigTitle '-' HttpPort '" httpd -d . -f' UsedConfig;

 END;

 EXIT( rc);

/* =========================================================================== */
unixpath: PROCEDURE
 PARSE ARG Path;
 RETURN( TRANSLATE( Path, '/', '\'));

