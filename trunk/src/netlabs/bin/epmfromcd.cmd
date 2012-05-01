/****************************** Module Header *******************************
*
* Module Name: epmfromcd.cmd
*
* Syntax: epmfromcd [args]
*
* This CMD can be executed from an eCS boot CD. It tries to find an existing
* EPM installation for the binaries and determines the NEPMD setting from the
* directory of this file.
*
* If EPM was found, EPM is started with the specified args.
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

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

DO 1
   PARSE SOURCE . . ThisFile
   lp = LASTPOS( '\', ThisFile)
   ThisDir = LEFT( ThisFile, lp - 1)

   PARSE ARG Args

   /* Check if environment is already extened */
   next = VALUE( 'NEPMD_NAME',, env)
   IF next = '' THEN
   DO

      /* Find EPM executables */
      DrivesList = SysDriveMap()

      EpmDir = ''
      Rest = DrivesList
      DO WHILE Rest <> ''
         PARSE VAR Rest NextDrive Rest
         NextDir = NextDrive'\os2\apps'

         /* Find epm.exe */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\epm.exe', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         /* Find epmmri.dll */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\dll\epmmri.dll', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         /* Find etkc603.dll */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\dll\etkc603.dll', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         /* Find etke603.dll */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\dll\etke603.dll', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         /* Find etkr603.dll */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\dll\etkr603.dll', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         /* Find etkucms.dll */
         Found. = ''
         Found.0 = 0
         rcx = SysFileTree( NextDir'\dll\etkucms.dll', 'Found', 'O')
         IF Found.0 = 0 THEN
            ITERATE

         EpmDir = NextDir
         SAY 'EPM executables found in:' EpmDir
         LEAVE
      END

      IF EpmDir = '' THEN
      DO
         ErrorMessage = 'The EPM executables cannot be found on any drive in \OS2\APPS.'
         LEAVE
      END

      /* Extend the environment for EPM */
      EpmDllDir = EpmDir'\dll'

      /* Extend PATH */
      Path = VALUE( 'PATH',, env)
      NewPath = STRIP( Path, 'T', ';')';'EpmDir';'
      rc = VALUE( 'PATH', NewPath, env)

      /* Extend BeginLIBPATH */
      /* Check for newer REXXUTIL.DLL */
      fFunctionFound = 0
      IF \RxFuncQuery( 'SYSQUERYEXTLIBPATH') THEN
         fFunctionFound = 1

      /* Query BeginLIBPATH */
      IF fFunctionFound = 1 THEN
         BeginLibpathDirs = SysQueryExtLIBPATH( 'B')
      ELSE
      DO
         'CALL RXQUEUE /CLEAR'
         'SET BEGINLIBPATH|RXQUEUE /FIFO'
         PARSE PULL BeginLibpathDirs
         PARSE VALUE BeginLibpathDirs WITH . '=' BeginLibpathDirs
      END
      IF BeginLibpathDirs = '(null)' THEN
         BeginLibpathDirs = ''

      /* Cleanup */
      IF \(fFunctionFound = 1) THEN
         'CALL RXQUEUE /CLEAR'

      BeginLibPath = BeginLibpathDirs
      /* Prepend EpmDllDir if not already present */
      IF POS( EpmDllDir, BeginLibpathDirs) = 0 THEN
         BeginLibpath = STRIP( STRIP( EpmDllDir, 'T', ';')';'BeginLibpathDirs, 'L', ';')

      /* Extend libpath. This persists even when SETLOCAL was used. */
      IF fFunctionFound = 1 THEN
      DO
         CALL SysSetExtLIBPATH BeginLibPath, 'B'
      END
      ELSE
      DO
         'SET BEGINLIBPATH='BeginLibpath
      END

      /* Extend the environment for NEPMD */
      'CALL' ThisDir'\..\..\netlabs\install\INSTENV'
      'CALL' ThisDir'\..\..\netlabs\bin\EPMENV'

   END
   ELSE
   DO
      SAY 'Environment already extended.'
   END

   /* Call the EPM loader */
   NepmdRootDir = VALUE( 'NEPMD_ROOTDIR',, env)
   'START' NepmdRootDir'\netlabs\bin\epm.exe' Args

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

