/****************************** Module Header *******************************
*
* Module Name: nlsetup.cmd
*
* Syntax: nlsetup [NEPMD [UNINSTALL | APPLYICO]]
*
* Frame batch for to call all required CMD files when setting up additional
* directories and files in the user directory tree.
*
* This module is called by the WarpIN package directly. In order to prevent
* a VIO window opening for this REXX script, this (and only this script) is
* compiled to a PM executable.
*
* This program is intended to be called only during installation of the
* netlabs.org EPM Distribution.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nlsetup.cmd,v 1.19 2008-10-09 19:21:40 aschn Exp $
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

/* some OS/2 Error codes */
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

/* Defaults */
ErrorTitle = 'Netlabs EPM Distribution Installation'

/* Parse parameters */
fNepmd     = FALSE
fUninstall = FALSE
fApplyIco  = FALSE
ARG Parms
DO WHILE Parms <> ''
   PARSE VAR Parms ThisParm Parms
   ThisParm = STRIP( ThisParm)

   SELECT
      WHEN ThisParm = '' THEN
         LEAVE
      WHEN ThisParm = 'NEPMD' THEN
         fNepmd = TRUE
      WHEN ThisParm = 'UNINSTALL' THEN
         fUninstall = TRUE
      WHEN ThisParm = 'APPLYICO' THEN
         fApplyIco = TRUE
   OTHERWISE
      NOP
   END
END

/* Make sure we are called on purpose */
IF (\fNepmd) THEN
   ShowError( ErrorTitle, 'Error: Not called by WarpIN package.')

/* Create private queue for error messages and set as default */
QueueName = RXQUEUE( 'CREATE')
rcx = RXQUEUE( 'SET', QueueName)
rcx = VALUE( 'NEPMD_RXQUEUE', QueueName, env)

/* Make work dir the current directory */
WorkDir = LEFT( ThisFile, LASTPOS( '\', ThisFile) - 1)
rcx = DIRECTORY( WorkDir)
/* Change also drive */
IF SUBSTR( WorkDir, 2, 1) = ':' THEN
  rcx = DIRECTORY( SUBSTR( WorkDir, 1, 2))

/* Call all required modules */
SELECT
   WHEN fUninstall THEN
   DO 1
      'CALL INSTENV UNINSTALL'; IF (rc \= 0) THEN LEAVE
      'CALL DYNCFG UNINSTALL';  IF (rc \= 0) THEN LEAVE
   END
   WHEN fApplyIco THEN
   DO 1
      'CALL INSTENV';           IF (rc \= 0) THEN LEAVE
      'CALL APPLYICO';          IF (rc \= 0) THEN LEAVE
   END
OTHERWISE
   DO 1
      'CALL INSTENV';           IF (rc \= 0) THEN LEAVE
      'CALL USERTREE';          IF (rc \= 0) THEN LEAVE
      'CALL SPECIAL';           IF (rc \= 0) THEN LEAVE
      'CALL DYNCFG';            IF (rc \= 0) THEN LEAVE
      /* The "NEPMD" param avoids the prompt */
      'CALL RENUDIRS NEPMD';    IF (rc \= 0) THEN LEAVE
      'CALL EXPOBJ';            IF (rc \= 0) THEN LEAVE
      'CALL INITREG';           IF (rc \= 0) THEN LEAVE
   END
END

IF ((rc \= 0) & (QUEUED() > 0)) THEN
DO
   PARSE PULL ErrorMessage
   ShowError( ErrorTitle, ErrorMessage, rc)
END

EXIT( rc)

/* ----------------------------------------------------------------------- */
Halt:
   ShowError( ErrorTitle, 'Interrupted by user.')
   EXIT( 99)

/* ----------------------------------------------------------------------- */
ShowError: PROCEDURE
   PARSE ARG Title, Message, rc

   /* Show message box in PM mode */
   SIGNAL ON SYNTAX NAME NoPM
   rcx = RxMessageBox( Message, Title, 'CANCEL', 'ERROR')
   EXIT( rc)

/* Print text in VIO mode */
NoPM:
   SIGNAL OFF SYNTAX
   SAY ''
   SAY Title
   SAY Message
   'PAUSE'
   EXIT( rc)

