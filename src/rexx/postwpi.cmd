/****************************** Module Header *******************************
*
* Module Name: postwpi.cmd
*
* Syntax: postwpi [NEPMD <option>]
*
* Calls postwpi2.cmd which contains the relevant code.
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


/* Make sure we are called on purpose */
/* Parse parameters */
fNepmd = FALSE
PARSE ARG Args
UpArgs = TRANSLATE( Args)
IF WORDPOS( 'NEPMD', UpArgs) > 0 THEN
   fNepmd = TRUE
IF (\fNepmd) THEN
   CALL ShowError ErrorTitle, 'Error: Not called by WarpIN package.'

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

/* Call postwpi2.cmd */
'CALL POSTWPI2' Args

IF ((rc \= 0) & (QUEUED() > 0)) THEN
DO
   PARSE PULL ErrorMessage
   CALL ShowError ErrorTitle, ErrorMessage, rc
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

