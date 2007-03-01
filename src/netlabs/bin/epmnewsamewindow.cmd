/****************************** Module Header *******************************
*
* Module Name: epmnewsamewindow.cmd
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmnewsamewindow.cmd,v 1.4 2007-03-01 21:37:16 aschn Exp $
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
 * Beside the original NEPMD objects, find all objects in
 * <NEPMD_FOLDER> and change all EPM objects, except those
 * starting with 'EPM - ' and except those who belong to
 * an exclude list.
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

 GlobalVars = GlobalVars 'Title.';

/* ------------- Configuration ---------------- */
 Title.EPM_NEW_WINDOW  = 'EPM new window';
 Title.EPM_SAME_WINDOW = 'EPM same window';
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

 PARSE ARG Args;
 Args = TRANSLATE( STRIP( Args));
 SELECT
    WHEN (POS( Args, 'ON') = 1 | POS( Args, 'YES') = 1 | Args = 1) THEN
    DO
       Action = 'on';
       fPrompt = 0;
    END;
    WHEN (POS( Args, 'OFF') = 1 | POS( Args, 'NO') = 1 | Args = 0) THEN
    DO
       Action = 'off';
       fPrompt = 0;
    END
    WHEN (POS( Args, 'TOGGLE') = 1) THEN
    DO
       Action = 'toggle';
       fPrompt = 0;
    END;
 OTHERWISE
    Action = '';
    fPrompt = 1;
 END;

 SAY;
 IF (fPrompt) THEN
 DO
    SAY ThisName;
    SAY;
    SAY ' This script toggles the "concurrent view" behavior of several NEPMD';
    SAY ' program objects: With parameter "/r", associated files are loaded into';
    SAY ' the same window. Without it, those files are opened in a new window.';
    SAY;
    SAY ' It does the following:';
    SAY;
    SAY '    o  removes or sets parameter "/r" for EPM objects,';
    SAY '    o  changes the title for the "EPM new/same window" program object.';
    SAY
 END;

 DO 1
    Obj = Obj.2;
    rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
    IF (rcx = 1) THEN
    DO
       fOldR =CheckR( Setup);
       LEAVE;
    END;

    Obj = Obj.1;
    rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
    IF (rcx = 1) THEN
    DO
       fOldR =CheckNew( Setup);
       LEAVE;
    END;

    SAY 'Error: Setup string couldn''t be queried from 'Obj.2' or 'Obj.1'.';
    EXIT( ERROR.FILE_NOT_FOUND);
 END;

 OldState = WORD( 'off on', fOldR + 1);
 SAY 'Current state of parameter "/r" is: 'OldState;
 IF Action = OldState THEN
 DO
    SAY 'No changes.';
    EXIT( rc);
 END;

 fNewR = \fOldR;

 IF (fPrompt) THEN
 DO
    NewState = WORD( 'off on', fNewR + 1);
    SAY;
    SAY 'Do you want to set the state to 'NewState'? (Press Y <RETURN> to continue.)';
    Key = LineIn();
    Key = TRANSLATE( STRIP( Key));
    IF Key <> 'Y'  THEN
       EXIT( ERROR.GEN_FAILURE);
 END;

 i = 0;
 DO n = 2 to Obj.0
    rcx = ToggleR( Obj.n, fNewR);
    IF (rcx = 1) THEN
       i = i + 1;
 END;
 rcx = ToggleTitle( Obj.1, fNewR);
 IF (rcx = 1) THEN
    i = i + 1;

 SAY 'Changed 'i' Object(s).';

 EXIT( rc);

/* ------------------------------------------------------------------------- */

CheckR: PROCEDURE
 PARSE ARG Setup;

 PARSE VAR Setup First'PARAMETERS='Params';'Rest;
 wp = WORDPOS( '/R', TRANSLATE( Params));

 RETURN( wp > 0);

/* ------------------------------------------------------------------------- */

CheckNew: PROCEDURE
 PARSE ARG Setup;

 PARSE VAR Setup First'TITLE='Title';'Rest;
 wp = WORDPOS( 'NEW', TRANSLATE( Title));

 RETURN( wp > 0);

/* ------------------------------------------------------------------------- */

ToggleR: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Obj, fAddR;

 rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
 IF (rcx = 1) THEN
 DO
    PARSE VAR Setup First'PARAMETERS='Params';'Rest;

    wp = WORDPOS( '/R', TRANSLATE( Params));
    SELECT
       WHEN (fAddR & wp = 0) THEN
          Params = '/r 'Params;
       WHEN (\fAddR & wp > 0) THEN
          Params = DELWORD( Params, wp, 1);
    OTHERWISE
       NOP;
    END;

    /* Setting an empty parameter doesn't work */
    /* The doublequotes are required for filanames with spaces */
    IF Params = '' THEN
       Params = '"%*"';
    Setup = First'PARAMETERS='Params';'Rest;
    SAY Obj 'PARAMETERS='Params';';

    rcx = SysSetObjectData( Obj, Setup);
 END;
 RETURN( rcx);

/* ------------------------------------------------------------------------- */

ToggleTitle: PROCEDURE EXPOSE (GlobalVars)
 PARSE ARG Obj, fNewWindow;

 rcx = WPToolsQueryObject( Obj, 'Class', 'Title', 'Setup', 'Location');
 IF (rcx = 1) THEN
 DO
    PARSE VAR Setup First'TITLE='Title';'Rest;

    wp = WORDPOS( 'NEW', TRANSLATE( Title));
    IF (fNewWindow) THEN
       Title = Title.EPM_NEW_WINDOW;
    ELSE
       Title = Title.EPM_SAME_WINDOW;

    Setup = First'TITLE='Title';'Rest;
    SAY Obj 'TITLE='Title';';

    rcx = SysSetObjectData( Obj, Setup);
 END;
 RETURN( rcx);

/* ------------------------------------------------------------------------- */

HALT:
 SAY;
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

