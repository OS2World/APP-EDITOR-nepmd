/****************************** Module Header *******************************
*
* Module Name: epmdefassocs.cmd
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmdefassocs.cmd,v 1.1 2006-12-20 20:44:00 aschn Exp $
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

/* Not ready, actually lists only settings, but doesn't change anything */
/* It can be run without risk!                                          */

/*

The selections may be submitted to this script as:
   "/I:<NEPMD_ /E:epm.exe /D /A"

UI ideas:

------------------------------------------------------------------------------
Change object associations (1/4)
(Skip this section if I, E or T params were submitted, then just show
the filter values)

Select program object filters:

   I  Object id filter : <NEPMD_
   E  Executable filter: epm.exe
   T  Title filter     :

   An abbreviation matches, e.g. "<NEPMD_" for the object id or "epm"
   for the executable. You can use multiple filters simultaneously,
   where filters were AND-combined.

   Press I, E or T and <Return> to change a filter's value,
   press <Return> to accept the current filters or
   press C <Return> to cancel:

------------------------------------------------------------------------------
Change object associations (2/4)

With the given filters, the following program objects were found.

Select program objects to process:

      Object id       Executable    Title
   1  <NEPMD_EPM>
   2  ...

   Type a space- or comma-separated list of numbers, (e.g. 1,3)
   and press <Return> to specify some of the listed objects,
   press <Return> to accept all listed objects,
   press B <Return> to go back to the start of the selection or
   press C <Return> to cancel:

Following objects were selected:
   <NEPMD_EPM>         epm.exe        EPM

------------------------------------------------------------------------------
Change object associations (3/4)
(Skip this section if R, D, L or W params were submitted, then just show
the filter values)

Select an action for these objects:

   R  remove the object's associations
   D  make the object the default associated object
   L  make the object the last associated object
   Y  specify new .FILETYPE associations for the object
   N  specify new filename associations for the object
   W  open WPS properties of the object

   Type R, D, L or W and <Return> to select an action,
   press B <Return> to go back to the start of the selection or
   press C <Return> to cancel:

------------------------------------------------------------------------------
Change object associations (4/4)
(Skip this section if P or A params were submitted, then just show
the filter values)

Select how to procede:

   P  pause before changing every association
   A  process all objects and associations without pause

   Type P or A and <Return> to start the action,
   press B <Return> to go back to the start of the selection or
   press C <Return> to cancel:

*/


/* REXX */

INIT:
 SIGNAL ON HALT NAME HALT

 '@ECHO OFF';
 env   = 'OS2ENVIRONMENT';
 TRUE  = (1 = 1);
 FALSE = (0 = 1);
 CrLf  = '0d0a'x;
 Redirection = '>NUL 2>&1';
 GlobalVars = 'env TRUE FALSE Redirection ERROR';

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

 rc = ERROR.NO_ERROR;

 /* initialize */
 CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs';
 CALL SysLoadFuncs;

 CALL RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs';
 CALL WPToolsLoadFuncs;


 /* query all abstract objects */
 rcx = SysIni( 'USER', 'PM_Abstract:Objects', 'All:', 'Keyw.')
 IF (rcx = 'ERROR:') THEN
    EXIT( ERROR.PATH_NOT_FOUND);

 SAY 'Found 'Keyw.0' abstract objects'

 ObjectIdFilter = '<NEPMD_'
 ExeNameFilter  = 'epm.exe'
 TitleFilter    = ''
 Action = 'D'

RESTART:
 DO k = 1 TO Keyw.0
    Keyw = Keyw.k;
    Entry = SysIni( 'USER', 'PM_Abstract:Objects', Keyw);
    IF (Entry = 'ERROR:') THEN
       ITERATE;

    /* get class from entry */
    PARSE VAR Entry +4 Class'00'x rest;

    /* get hex handle from Keyw */
    IF (Class = 'WPProgram') THEN
       hObjHex = 2''RIGHT( Keyw, 4, 0);
    ELSE
       hObjHex = 3''RIGHT( Keyw, 4, 0);

    /* convert to decimal as well for later use */
    hObjDec = X2D( hObjHex)

    /* process program objects only */
    IF (Class <> 'WPProgram') THEN
       ITERATE;
/*
Hex: [2B1F2]  Dec: [176626]  Class = [WPProgram]
                             Title = [EPM]
*/

    /* query that object handle */
    Obj = '#'hObjHex;
    /* drop required, otherwise wrong objects were listed */
    DROP Class;
    DROP Title;
    DROP Setup;
    DROP Location;
    rcx = WpToolsQueryObject( Obj, Class, Title, Setup, Location);
    IF (rcx <> 1) THEN
       ITERATE;

    PARSE VAR Setup 'OBJECTID='ObjectId';'rest;
    PARSE VAR Setup 'EXENAME='ExeName';'rest;

    /* remove path from ExeName */
    ExeName = FILESPEC( 'n', ExeName);

    /* Check if object matches the filters */
    fMatch = FALSE;
    DO 1
       IF (ObjectIdFilter <> '' & ,
           POS( ObjectIdFilter, ObjectId) <> 1) THEN
          LEAVE;
       IF (ExeNameFilter <> '' & ,
           POS( TRANSLATE( ExeNameFilter), TRANSLATE( ExeName)) <> 1) THEN
          LEAVE;
       IF (TitleFilter <> '' & ,
           POS( TRANSLATE( TitleFilter), TRANSLATE( Title)) <> 1) THEN
          LEAVE;
       fMatch = TRUE;
    END;
    IF (fMatch = FALSE) THEN
       ITERATE;

    SAY ObjectId' - 'ExeName' - 'Title;
/**/
    CALL CHAROUT, '   Press <Return> to continue, B <Return> to restart or C <Return> to cancel: ';
    Answer = STRIP( LINEIN());
    IF TRANSLATE( Answer) = 'C' THEN SIGNAL HALT;
    IF TRANSLATE( Answer) = 'B' THEN SIGNAL RESTART;
    /* PAUSE or SysGetKey doesn't work in an EPM Shell: */
    /* A <RETURN> is processed doubled after PAUSE and  */
    /* SysGetKey won't wait for a key.                  */
/**/

    IF (Action = 'W') THEN
    DO
       rcx = WpToolsSetObjectData( Obj, 'OPEN=SETTINGS;');
       ITERATE;
    END;

    IF (WORDPOS( Action, 'R D L') = 0) THEN
       ITERATE;

    PARSE VAR Setup 'ASSOCFILTER='List.1';'rest
    PARSE VAR Setup 'ASSOCTYPE='List.2';'rest
    Appl.1 = 'PMWP_ASSOC_FILTER'
    Appl.2 = 'PMWP_ASSOC_TYPE'

    /* query for all association filters the zero-separated hObhDec list */
    DO a = 1 TO 2
       rest = List.a;
       DO WHILE (LENGTH( rest) > 0)
          PARSE VAR rest next','rest;
          hObjList = SysIni( 'USER', Appl.a, next);
          IF hObjList = 'ERROR:' THEN
             ITERATE;
          /* translate to space-separated list for easier processing */
          OldList = TRANSLATE( hObjList, ' ', '00'x)
          /* search handle for current program object */
          wp = WORDPOS( hObjDec, OldList)
say 'OldList = 'next': 'OldList', wp = 'wp', hObjDec = 'hObjDec', Object id = 'ObjectId
          IF (wp > 0) THEN
          DO
             NewList = DELWORD( OldList, wp, 1);
             IF (Action = 'D') THEN
                NewList = hObjDec NewList;
             ELSE IF (Action = 'L') THEN
                NewList = NewList hObjDec;
             /* reformat handle list */
             NewList = SPACE( NewList, 1, '00'x)'00'x
say 'NewList = 'next': 'TRANSLATE( NewList, '.', '00'x)
/*
**** Better don't write anything to OS2.INI as long as the UI isn't ready ****
             rcx = SysIni( 'USER', Appl.a, next, NewList);
             IF rcx = 'ERROR:' THEN
             DO
                SAY 'Error writing ini key 'Appl.a' -> 'next'.';
                SAY 'Old value was:' TRANSLATE( hObjList, '.', '00'x);
                EXIT( ERROR.WRITE_FAULT);
             END;
*/
          END;
       END;
    END;

 END

 EXIT( rc);

/* ------------------------------------------------------------------------- */

HALT:
 SAY;
 SAY 'Interrupted by user.';
 EXIT( ERROR.GEN_FAILURE);

