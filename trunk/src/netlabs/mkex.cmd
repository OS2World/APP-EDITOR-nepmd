/****************************** Module Header *******************************
*
* Module Name: mkex.cmd
*
* Syntax: mkex target_dir
*
* Script for to create the NEPMD version of EPM.EX
*
* As a precaution EPMPATH is set to the macros directory only in order not
* to use any of source files from other directories
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mkex.cmd,v 1.2 2002-07-23 11:54:27 cla Exp $
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

 '@ECHO OFF';
 rcx = SETLOCAL();

 /* set include path for macro compiler */
 'SET EPMPATH=macros';

 /* get parms */
 PARSE ARG TargetDir;
 TargetDir = STRIP( TargetDir);
 IF (TargetDir = '') THEN
 DO
    SAY 'mkex: error: target directory not specified.';
    EXIT( 87); /* ERROR.INVALID_PARAMETER */
 END;

 /* call compiler */
 'etpm epm.e' TargetDir'\epm.ex';

 EXIT (rc);
