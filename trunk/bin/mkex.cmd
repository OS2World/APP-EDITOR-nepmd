/****************************** Module Header *******************************
*
* Module Name: mkex.cmd
*
* Syntax: mkex sourcepath target_dir sourcefile
*
* Script for to create the NEPMD version of EPM.EX
* Sources are taken only from the specified source directory
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

 '@ECHO OFF';
 env = 'OS2ENVIRONMENT';
 rcx = SETLOCAL();
 call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs

 /* get parms */
 PARSE ARG SourcePath TargetDir SourceFile;
 TargetDir = STRIP( TargetDir);
 IF (TargetDir = '') THEN
 DO
    SAY 'mkex: error: target directory not specified.';
    EXIT( 87); /* ERROR.INVALID_PARAMETER */
 END;

 IF (SourceFile = '') THEN
    SourceFile = 'epm.e';

 TargetFile = SourceFile'x';

 /* set sourcepath as EPMPATH */
 rcx = VALUE( 'EPMPATH', SourcePath, env);

 /* create tempfile */
 TmpFile = SysTempFilename( VALUE('TMP',,env)'\mkex.???');

 /* call compiler */
 'etpm' SourceFile TargetDir'\'TargetFile '>' TmpFile;

 IF (rc \= 0) THEN
    rcx = ShowEtpmError( TmpFile);

 /* cleanup */
 rcx = SysFileDelete( TmpFile);

 EXIT (rc);

/* ========================================================================= */
/* This routine is applicable only for non-verbose output !!! */
ShowEtpmError: PROCEDURE
 PARSE ARG Filename;

 /* skip header */
 DO WHILE (LINES( FileName) > 0)
    ThisLine = LINEIN( FileName);
    IF (ThisLine = ' compiling ...') THEN
       LEAVE;
 END;

 /* read error info */
 ErrorMessage = LINEIN( FileName);
 Dummy        = LINEIN( FileName);
 Dummy        = LINEIN( FileName);
 FileInfo     = LINEIN( FileName);
 LineInfo     = LINEIN( FileName);
 ColInfo      = LINEIN( FileName);

 /* close and remove file */
 rcx = STREAM( Filename, 'C', 'CLOSE');
 rcx = SysFileDelete( Filename);

 /* display error information */
 PARSE VAR FileInfo .'='File' ';
 PARSE VAR LineInfo .'= 'Line' ';
 PARSE VAR ColInfo  .'= 'Col;
 SAY File'('Line':'Col'):' ErrorMessage;

 RETURN( 0);

