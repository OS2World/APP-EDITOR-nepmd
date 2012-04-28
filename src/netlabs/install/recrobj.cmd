/****************************** Module Header *******************************
*
* Module Name: recrobj.cmd
*
* Syntax: recrobj [NEPMD]
*
* If NEPMD is not specified, the user will be asked before further execution.
*
* This CMD is able to recreate objects and ini entries, if the export file
* was created before. Even when the recommended way to recreate them is to
* repeat the WarpIN installation, this CMD could be useful if the WPI file
* is not available, but the files are present.
*
* The WarpIN database entries will not be recreated.
*
* This Cmd is not called by POSTWPI2.CMD. It can be called directly.
*
* Copyright (c) Netlabs EPM Distribution Project 2008
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
/* Some header lines are used as help text */
HelpStartLine =  9
HelpEndLine   = 14

'@ECHO OFF'
CALL SETLOCAL

/* ----------------- Standard CMD initialization follows ----------------- */
SIGNAL ON HALT NAME Halt

env   = 'OS2ENVIRONMENT'
TRUE  = (1 = 1)
FALSE = (0 = 1)
CrLf  = '0d0a'x
Redirection = '>NUL 2>&1'
PARSE SOURCE . . ThisFile
GlobalVars = 'env TRUE FALSE Redirection ERROR. ThisFile'

/* Some OS/2 Error codes */
ERROR.NO_ERROR           =   0
ERROR.INVALID_FUNCTION   =   1
ERROR.FILE_NOT_FOUND     =   2
ERROR.PATH_NOT_FOUND     =   3
ERROR.ACCESS_DENIED      =   5
ERROR.NOT_ENOUGH_MEMORY  =   8
ERROR.INVALID_FORMAT     =  11
ERROR.INVALID_DATA       =  13
ERROR.NO_MORE_FILES      =  18
ERROR.WRITE_FAULT        =  29
ERROR.READ_FAULT         =  30
ERROR.SHARING_VIOLATION  =  32
ERROR.GEN_FAILURE        =  31
ERROR.INVALID_PARAMETER  =  87
ERROR.ENVVAR_NOT_FOUND   = 204

rc = ERROR.NO_ERROR

CALL RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
CALL SysLoadFuncs
/* ----------------- Standard CMD initialization ends -------------------- */

/* ------------- Configuration ---------------- */
/* ExportFilename will be searched in the same dir as this file. Better */
/* use the netlabs tree to find that file easily, even when the user    */
/* tree was created elsewhere out of the NEPMD rootdir, e.g. in %HOME%. */
ExportFilename = 'recrobj.dat'
/* -------------------------------------------- */

/* Make sure CMD is called on purpose */
ARG Parm .
IF Parm = 'NEPMD' THEN
   fQuiet = TRUE
ELSE
   fQuiet = FALSE

IF \fQuiet THEN
DO
   SAY
   DO l = HelpStartLine TO HelpEndLine
      SAY SUBSTR( SOURCELINE( l), 3)
   END
   SAY
   SAY 'Do you want to continue? (Y/N)'
   PULL Answer
   Answer = STRIP( Answer)
   IF (Answer <> 'Y') THEN
      SIGNAL Halt
END

/* Read ExportFile */
lp = LASTPOS( '\', ThisFile)
ExportFile = SUBSTR( ThisFile, 1, lp)ExportFilename
IF (STREAM( ExportFile, 'c', 'query exists') = '') THEN
DO
   SAY 'Error: ExportFile "'ExportFile'" doesn''t exist.'
   EXIT( ERROR.FILE_NOT_FOUND)
END
ExportLine.  = ''
ExportLine.0 = 0
l = 0
rcx = STREAM( ExportFile, 'c', 'open read')
DO WHILE LINES( ExportFile) > 0
   l = l + 1
   ExportLine.l = LINEIN( ExportFile)
END
ExportLine.0 = l
rcx = STREAM( ExportFile, 'c', 'close')

/* Get BootDrive */
IF \RxFuncQuery( 'SysBootDrive') THEN
   BootDrive = SysBootDrive()
ELSE
   PARSE UPPER VALUE VALUE( 'PATH',, env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

/* Get TargetPath. Supports one common TargetPath for all packages only. */
TargetPath = ''
DO l = 1 TO ExportLine.0
   PARSE VAR ExportLine.l num 'TARGETPATH='next
   IF (next <> '') THEN
   DO
      TargetPath = next
      LEAVE
   END
END
IF (TargetPath = '') THEN
DO
   SAY 'Error: "TARGETPATH=" not found in "'ExportFile'".'
   EXIT( ERROR.INVALID_DATA)
END

/* Replace ?:\ and $(1) in ExportLines */
DO l = 1 TO ExportLine.0
   ThisLine = ExportLine.l

   OldString = '?:\'
   NewString = BootDrive'\'
   ThisLine = ReplaceString( OldString, ThisLine, NewString)

   OldString = '$(1)'
   NewString = TargetPath
   ThisLine = ReplaceString( OldString, ThisLine, NewString)

   IF ExportLine.l <> ThisLine THEN
   DO
      /*
      SAY 'Old: 'ExportLine.l
      SAY 'New: 'ThisLine
      */
      ExportLine.l = ThisLine
   END

END

/* Add ini entries */
DO l = 1 TO ExportLine.0
   PARSE VAR ExportLine.l num 'PROFILE='next
   IF (next = '') THEN ITERATE

   /* With the syntax how WarpIN saves the line, */
   /* a filename can't be specified as Ini:      */
   PARSE VAR next Ini'\'Appl'\'Key'|'Val
   /*
   SAY "next = SysIni( "Ini", "Appl", "Key", "Val"'00'x)"
   */
   next = SysIni( Ini, Appl, Key, Val'00'x)
   IF (next = 'ERROR:') THEN
   DO
      SAY 'Error: "'Key'" not written to ini "'Ini'", appl = "'Appl'", val = "'Val'.'
      EXIT( ERROR.WRITE_FAULT)
   END
END

/* Create objects */
DO l = 1 TO ExportLine.0
   PARSE VAR ExportLine.l num 'OBJECT='next
   IF (next = '') THEN ITERATE

   PARSE VAR next Class'|'Title'|'Dest'|'Setup
   UpdateReplaceFail = 'U'
   /*
   SAY "rcx = SysCreateObject( "Class", "Title", "Dest", "Setup", "UpdateReplaceFail")"
   */
   rcx = SysCreateObject( Class, Title, Dest, Setup, UpdateReplaceFail)
   IF (rcx <> 1) THEN
   DO
      IF Class = 'WPShadow' THEN
         SAY 'Error: Shadow object with setup "'Setup'" not created.'
      ELSE
         SAY 'Error: Object "'Title'" not created.'
      EXIT( ERROR.WRITE_FAULT)
   END
END

/* Execute postinstall calls */
DO l = 1 TO ExportLine.0
   PARSE VAR ExportLine.l num 'EXECUTE='next
   IF (next = '') THEN ITERATE

   SearchString = 'postwpi.exe NEPMD'
   IF (TRANSLATE( RIGHT( next, LENGTH( SearchString))) = TRANSLATE( SearchString)) THEN
   DO 1
      /* Make work dir the current directory */
      WorkDir = LEFT( ThisFile, LASTPOS( '\', ThisFile) - 1)
      rcx = DIRECTORY( WorkDir)
      /* Change also drive */
      IF SUBSTR( WorkDir, 2, 1) = ':' THEN
        rcx = DIRECTORY( SUBSTR( WorkDir, 1, 2))

      /* Keep in sync with POSTWPI2.CMD */
      'CALL INSTENV';           IF (rc \= 0) THEN LEAVE
      'CALL USERTREE';          IF (rc \= 0) THEN LEAVE
      'CALL CLEANUP';           IF (rc \= 0) THEN LEAVE
      'CALL DYNCFG';            IF (rc \= 0) THEN LEAVE
      /* Don't call RENUDIRS, EXPOBJ and INITREG here */
   END
   ELSE
      /*
      SAY 'CALL' next
      */
      'CALL' next
END

EXIT( rc)

/* ----------------------------------------------------------------------- */
/* Like CHANGESTR */
ReplaceString: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG OldString, SourceString, NewString

   Startp = 1
   DO FOREVER
      p1 = POS( OldString, SourceString, Startp)
      IF (p1 = 0) THEN
         LEAVE
      SourceString = INSERT( NewString,,
                             DELSTR( SourceString, p1, LENGTH( OldString)),,
                             p1 - 1)
      Startp = p1 + LENGTH( NewString)
   END

   RETURN( SourceString)

/* ----------------------------------------------------------------------- */
Halt:
   SAY 'Interrupted by user.'
   EXIT( 99)

