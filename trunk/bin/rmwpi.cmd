/*
 *      RMWPI.CMD - V1.0 C.Langanke for Netlabs EPM Distribution Project 2002
 *
 *      Syntax: rmwpi wis-script
 *
 *    This program quickly removes packages matching the package ids of the 
 *    specified wis script without using the WarpIn GUI.
 *    THIS IS INTENDED FOR TESTING PURPOSES ONLY !
 *
 *    NOTE:
 *    - the revision numbers from the WarpIn Script are ignored, but
 *      the vendor name, package name and component name must match exactly
 *    - all files and WPS objects are removed
 *    - no INI entries or CONFIG.SYS entries are removed
 *    - no dependencies are checked !
 */
/* The first comment is used as online help text */
/****************************** Module Header *******************************
*
* Module Name: remove.cmd
*
* Batch for to quickly remove packages installed by WarpIn.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: rmwpi.cmd,v 1.1 2002-06-11 14:20:07 cla Exp $
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

 TitleLine = STRIP(SUBSTR(SourceLine(2), 3));
 PARSE VAR TitleLine CmdName'.CMD 'Info;
 Id = '$Id: rmwpi.cmd,v 1.1 2002-06-11 14:20:07 cla Exp $';
 PARSE VAR Id .',v' Ver .;
 Title     = CmdName 'V'Ver Info;

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
 IF ((Parm = '') | (POS('?', Parm) > 0)) THEN
 DO
    rc = ShowHelp();
    EXIT(ERROR.INVALID_PARAMETER);
 END;

 /* defaults */
 rc = ERROR.NO_ERROR;
 ZeroByte = '0'x;

 Remove.  = '';
 Remove.0 = 0;

 DO UNTIL (1)
    /* search Warpin executable */
    PARSE VALUE SysIni( , 'WarpIN', 'Path') WITH WarpInPath'0'x;
    IF (WarpInPath = '') THEN
    DO
       SAY 'error: WarpIn is not installed.';
       rc = ERROR.PATH_NOT_FOUND;
       LEAVE;
    END;

    /* search all database files */
    rc = SysFileTree( WarpInPath'\DATBAS_?.INI', 'IniFile.', 'FO');
    IF (rc \= ERROR.NO_ERROR) THEN
    DO
       SAY 'error in SysFileTree, rc='rc;
       LEAVE;
    END;
    IF (IniFile.0 = 0) THEN
    DO
       SAY 'error: WarpIn is not initialized or database could not be accessed.';
       rc = ERROR.FILE_NOT_FOUND;
       LEAVE;
    END;

    /* get parameters */
    PARSE ARG ScriptFile;
    ScriptFile = STRIP( ScriptFile);
    IF (ScriptFile = '') THEN
    DO
       SAY 'error: no scriptfile specified.';
       rc = ERROR.INVALID_PARAMETER;
       LEAVE;
    END;

    /* search for the script */
    IF (\FileExist( ScriptFile)) THEN
    DO
       SAY 'error: scriptfile' ScriptFile 'not found.';
       rc = ERROR.FILE_NOT_FOUND;
       LEAVE;
    END;

    /* get all package IDs */
    rc = SysFileSearch( "PACKAGEID", ScriptFile, 'Line.');
    IF (rc \= ERROR.NO_ERROR) THEN
    DO
       SAY 'error in SysFileSearch, rc='rc;
       LEAVE;
    END;

    IF (Line.0 = 0) THEN
    DO
       SAY 'error: invalid script file: no package IDs found in' ScriptFile;
       rc = ERROR.INVALID_DATA;
       LEAVE;
    END;

    /* process all packages */
    DO i = 1 TO Line.0
       /* isolate Id */
       PARSE VAR Line.i ThisTag'='ThisId;
       ThisTag = TRANSLATE( STRIP( ThisTag));
       IF (ThisTag \= 'PACKAGEID') THEN ITERATE;
       PARSE VAR ThisId '"'ThisId'"'
       IF (ThisId = '') THEN ITERATE;

       /* strip of dynamic version number */
       PARSE VAR ThisId ThisVendor'\'ThisPackage'\'ThisComponent'\'.
       ThisId = ThisVendor'\'ThisPackage'\'ThisComponent;

       DO n = 1 TO IniFile.0

          /* query all apps and remove matching ones */
          Apps = SysIni( 'C:\os2\install\warpin\DATBAS_C.INI', 'ALL:', 'Apps.');
          DO a = 1 TO Apps.0
             IF (POS( ThisId, Apps.a) = 1) THEN
             DO
                /* remove app */
                rc = RemoveApp( IniFile.n, Apps.a);
                LEAVE;
             END;
          END;
       END;
    END;

 END;

 EXIT( rc);

HALT:
 SAY 'Interrupted by user.';
 EXIT(99);

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
RemoveEmptyDirectories: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Dir;

 /* get all subdirectories */
 rc = SysFileTree( Dir'\*', 'Dir.', 'DOS');

 /* kill anything moving ... ;-) */
 DO d = Dir.0 TO 1 BY -1
    rc = SysRmDir( Dir.d);
 END;

 rc = SysRmDir( Dir);

 /* do not return any error */
 RETURN( 0);

/* ========================================================================= */
RemoveApp: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG IniFile, AppId;

 ZeroByte  = '00'x;

 FileCount   = 0;
 Objectcount = 0;

 DO UNTIL (1)

    PARSE VAR AppId ThisVendor'\'ThisPackage'\'ThisComponent'\'.
    SAY '- removing' ThisPackage '-' ThisComponent

    /* remove files */
    PARSE VALUE SysIni( IniFile, AppId, 'TargetPath') WITH InstallPath'00'x;
    FileList = SysIni( IniFile, AppId, 'Files');
    DO WHILE (FileList \= '')
       NameLen = POS( ZeroByte, FileList);
       ThisFile = LEFT( FileList, NameLen - 1);
       FileList = SUBSTR( FileList, NameLen + 14);
       FileCount = FileCount + 1;
       rcx = SysFileDelete( InstallPath'\'ThisFile);
    END;
    IF (FileCount > 0) THEN
       SAY '  -' FileCount 'file(s) removed'

    /* remove empty directories */
    rcx = RemoveEmptyDirectories( InstallPath);

    /* destroy WPS objects of application */
    ObjectIdList = SysIni( IniFile, AppId, 'WPSObjectDone');
    IF (ObjectIdList \= 'ERROR:') THEN
    DO WHILE (ObjectIdList \= '')
       PARSE VAR ObjectIdList ThisObjectId(ZeroByte)ObjectIdList;
       ObjectCount = ObjectCount + 1;
       rcx = SysDestroyObject( ThisObjectId);
    END;
    IF (ObjectCount > 0 ) THEN
       SAY '  -' ObjectCount 'WPS object(s) destroyed'
   
    /* delete ini entry */
    rcx = SysIni( IniFile, AppId, 'DELETE:');
 END;

 RETURN( rc);

