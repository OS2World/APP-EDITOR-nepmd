/****************************** Module Header *******************************
*
* Module Name: epmchangestartupdir.cmd
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmchangestartupdir.cmd,v 1.2 2006-12-09 18:01:07 aschn Exp $
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

/* REXX */

/*
 * Todo:
 *
 * Process all NEPMD objects.
 *
 */

 SIGNAL ON HALT NAME HALT

 '@ECHO OFF';
 env   = 'OS2ENVIRONMENT';
 TRUE  = (1 = 1);
 FALSE = (0 = 1);
 CrLf  = '0d0a'x;
 Redirection = '>NUL 2>&1';
 GlobalVars = 'env TRUE FALSE Redirection ERROR.';

 /* some OS/2 Error codes */
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
 ERROR.SHARING_VIOLATION  =  32;
 ERROR.GEN_FAILURE        =  31;
 ERROR.INVALID_PARAMETER  =  87;
 ERROR.ENVVAR_NOT_FOUND   = 204;

/* ------------- Configuration ---------------- */
/*
 * For Obj.i, specify either an object id or a full pathname.
 */
 i = 0
 i = i + 1; Obj.i = '<NEPMD_EPM_NEW_SAME_WINDOW>';
 i = i + 1; Obj.i = '<NEPMD_EPM>';
 i = i + 1; Obj.i = '<NEPMD_EPM_E>';
 i = i + 1; Obj.i = '<NEPMD_EPM_ERX>';
 i = i + 1; Obj.i = '<NEPMD_EPM_TEX>';
 i = i + 1; Obj.i = '<NEPMD_EPM_EDIT_MACROFILE>';
 i = i + 1; Obj.i = '<NEPMD_EPM_TURBO>';
 Obj.0 = i;
/* -------------------------------------------- */

 rc = ERROR.NO_ERROR;

 /* initialize */
 CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 CALL SysLoadFuncs;

 CALL RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs';
 CALL WPToolsLoadFuncs;

 PARSE SOURCE . . ThisFile;
 ThisName = FILESPEC( 'N', ThisFile);

 PARSE ARG NewDir;
 NewDir = STRIP( NewDir);
 IF NewDIr = '' THEN
    fPrompt = 1;
 ELSE
    fPrompt = 0;

 SAY;
 IF (fPrompt) THEN
 DO
    SAY ThisName;
    SAY
    SAY ' This script lets you configure the working directory of your NEPMD'
    SAY ' program objects.'
    SAY
 END

 DO 1
    Obj = Obj.2;
    rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
    IF (rcx = 1) THEN
    DO
       OldDir = GetStartupDir( Setup);
       LEAVE;
    END;

    SAY 'Error: Setup string couldn''t be queried from 'Obj.2'.'
    EXIT( ERROR.FILE_NOT_FOUND);
 END;

 SAY 'Current working directory is: 'OldDir

 IF (fPrompt) THEN
 DO
    SAY
    SAY 'Typein the new working directory: (Leave it empty to cancel.)'
    NewDir = LineIn()
    NewDir = STRIP( NewDir);
    IF NewDir = ''  THEN
       EXIT( ERROR.GEN_FAILURE);
 END

 i = 0;
 DO n = 1 to Obj.0
    rcx = ToggleStartupDir( Obj.n, NewDir)
    IF (rcx = 1) THEN
       i = i + 1;
 END

 SAY 'Changed 'i' Object(s).'

 EXIT( rc);


/* ------------------------------------------------------------------------- */

GetStartupDir: PROCEDURE
 PARSE ARG Setup;

 PARSE VAR Setup First'STARTUPDIR='OldDir';'Rest;
 RETURN( OldDir);


/* ------------------------------------------------------------------------- */

ToggleStartupDir: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Obj, NewDir;

 rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
 IF (rcx = 1) THEN
 DO
    PARSE VAR Setup First'STARTUPDIR='OldDir';'Rest;

    Setup = First'STARTUPDIR='NewDir';'Rest;
    SAY Obj 'STARTUPDIR='NewDir';',

    rcx = SysSetObjectData( Obj, Setup);
 END
 RETURN( rcx);


/* ------------------------------------------------------------------------- */

HALT:
 SAY;
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

