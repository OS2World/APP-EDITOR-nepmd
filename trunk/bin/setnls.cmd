/****************************** Module Header *******************************
*
* Module Name: setnls.cmd
*
*   Syntax:  setnls [<languageid>]
*
*   This program sets the language id for the NEPMD project.
*   Specify no id in order to NEPMD delete the language information.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: setnls.cmd,v 1.1 2002-06-03 18:35:46 cla Exp $
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
/*
 */

 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 PARSE ARG LanguageId;
 LanguageId = STRIP( LanguageId);
 IF (LanguageId = '') THEN
    LanguageId = 'DELETE:';

 rc = SysIni(, 'NEPMD', 'Language', LanguageId);

 SAY 'Current id is:' SysIni(, 'NEPMD', 'Language');

