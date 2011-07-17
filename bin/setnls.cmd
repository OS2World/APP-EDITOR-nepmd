/****************************** Module Header *******************************
*
* Module Name: setnls.cmd
*
*   Syntax:  setnls [<languageid>]
*
*   This program sets the three character language id for the NEPMD project.
*   Specify no id in order to NEPMD delete the language information.
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

 /* load REXX util */
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* defaults */
 IniApp         = 'NEPMD';
 IniKeyLanguage = 'Language';

 /* set new value - must have zero or three characters */
 PARSE ARG LanguageId;
 LanguageId = STRIP( LanguageId);
 IF (WORDPOS( LENGTH( LanguageId), '0 3') = 0) THEN
 DO
    SAY 'error: invalid language id specified:' LanguageId;
    EXIT( 87);
 END;

 /* delete current value, if none specified */
 IF (LanguageId = '') THEN
    LanguageId = 'DELETE:';

 /* display the vaule just set */
 rc = SysIni(, IniApp, IniKeyLanguage, LanguageId);
 IF (rc = 'ERROR:') THEN
    CurrentValue = '<not defined>';
 ELSE
    CurrentValue = SysIni(, IniApp, IniKeyLanguage);

 SAY 'Language id is set to:' CurrentValue;

