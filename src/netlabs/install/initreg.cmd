/****************************** Module Header *******************************
*
* Module Name: initreg.cmd
*
* Syntax: initreg
*
* Helper batch for to delete the RegDefaults application of NEPMD.INI.
* This application contains all NEPMD's default values. It will be rebuilt
* by the E procedure NepmdInitConfig on the next EPM start from the file
* DEFAULTS.DAT.
*
* This program is intended to be called only by NLSETUP.EXE during NEPMD
* installation.
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
ErrorQueueName = VALUE( 'NEPMD_RXQUEUE',, env)
ErrorMessage   = ''

/* Some INI app names and keys of NEPMD project from OS2.INI, defined in nepmd.h */
NEPMD_INI_KEYNAME_ROOTDIR     = "RootDir"
NEPMD_INI_KEYNAME_USERDIR     = "UserDir"

NepmdIniName    = 'nepmd.ini'
NepmdIniSubPath = 'bin'
NepmdIniAppl    = 'RegDefaults'

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

/* Check if the env is already extended */
next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IF next = '' THEN
   'CALL INSTENV'

UserDir  = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_USERDIR)'_INST',, env)

DO 1

   /* Full pathname of NEPMD.INI */
   NepmdIni = UserDir'\'NepmdIniSubPath'\'NepmdIniName

   /* Check if NEPMD.INI exists */
   rcx = SysFileTree( NepmdIni, 'Found.', 'FO', '*-***');
   IF rcx = 0 & Found.0 = 0 THEN
   DO
      rc = 0 /* no reset of default values required */
      LEAVE
   END

   /* Check if application in NEPMD.INI exists */
   rcx = SysIni( NepmdIni, NepmdIniAppl)
   IF rcx = 'ERROR:' THEN
   DO
      rc = 0 /* no reset of default values required */
      LEAVE
   END

   /* Delete application in NEPMD.INI */
   rcx = SysIni( NepmdIni, NepmdIniAppl, 'DELETE:')
   IF rcx = 'ERROR:' THEN
   DO
      ErrorMessage = 'Error: default NEPMD.INI values not deleted.'
      rc = 1 /* ERROR */
      LEAVE
   END

END

/* Report error message */
IF ErrorMessage <> '' THEN
   CALL SayErrorText

EXIT( rc)

/* ----------------------------------------------------------------------- */
SayErrorText: PROCEDURE EXPOSE (GlobalVars)
   SELECT
      WHEN (ErrorMessage = '') THEN NOP

      /* Called by frame program: insert error */
      /* message into private queue            */
      WHEN (ErrorQueueName <> '') THEN
      DO
         rcx = RXQUEUE( 'SET', ErrorQueueName)
         PUSH ErrorMessage
      END

      /* Called directly */
      OTHERWISE
      DO
         SAY ErrorMessage
         'PAUSE'
      END
   END

   RETURN( '')

/* ----------------------------------------------------------------------- */
Halt:
   ErrorMessage = 'Interrupted by user.'
   CALL SayErrorText
   EXIT( 99)

