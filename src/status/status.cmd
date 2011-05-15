/*
 *      STATUS.CMD - C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      This program launches the web interface for update of the
 *      status db entries.
 *      Therefore the apache server instance and the Warpzilla
 *      bworser are started.
 *
 *      Syntax: status
 */
/* First three comments are being used as online helptext */
/****************************** Module Header *******************************
*
* Module Name: status.cmd
*
* Batch for to start the web interface for update of the status db entries.
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
 IF (POS('/?', Parm) > 0) THEN
 DO
    rc = ShowHelp( );
    EXIT( rc);
 END;

 /* load RexxUtil */
 CALL RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 CALL SysLoadFuncs

 /* default values */
 GlobalVars = GlobalVars '';
 rc         = ERROR.NO_ERROR;

 DO UNTIL (TRUE)

    /* read anvironment */
    'CALL statusenv'
    Apache._Port       = VALUE( 'APACHE_PORT',,env);
    Apache._Servername = VALUE( 'APACHE_SERVERNAME',,env);

    /* determine warpzilla directory */
    SAY '- retrieving Mozilla home';
    PARSE VALUE SysIni(, 'Mozilla', 'Home') WITH MozillaDir'0'x;
    IF (MozillaDir = 'ERROR:') THEN
    DO
       SAY CmdName': error: Warpzilla installation not found.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;

    /* launch apache */
    SAY '- launch web server'
    'call startapache';
    IF (rc \= ERROR.NO_ERROR) THEN
    DO
       SAY 'error: web browser could bot be launched.';
       LEAVE;
    END;
    rc = SysSleep( 1);

    /* launch warpzilla */
    SAY '- launch web browser'
    rc = SETLOCAL();
    rcx = DIRECTORY( MozillaDir);
    'start /F mozilla.exe http://'Apache._Servername':'Apache._Port;

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

 DO 3
    rc = LINEIN(ThisFile);
 END;

 ThisLine = LINEIN(Thisfile);
 DO WHILE (ThisLine \= ' */')
    SAY SUBSTR(ThisLine, 7);
    ThisLine = LINEIN(Thisfile);
 END;

 rc = LINEOUT(Thisfile);

 RETURN( ERROR.INVALID_PARAMETER);

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
 PARSE ARG FileName

 RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '');

