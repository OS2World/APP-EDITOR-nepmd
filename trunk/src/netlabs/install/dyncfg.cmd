/****************************** Module Header *******************************
*
* Module Name: dyncfg.cmd
*
* Syntax: dyncfg [UNINSTALL]
*
* Helper batch for to copy netlabs\bin\epm.exe to a directory along
* the PATH. Preferred is ?:\OS2, as this comes before ?:\OS2\APPS,
* where the original EPM is mostly installed.
*
* netlabs\bin\epm.exe is a dummy loader exe, which loads the true EPM.EXE
* after having setup the environment according to the environment file
* netlabs\bin\epm.env. It must be the first EPM.EXE along the PATH.
* See netlabs\book\nepmd.inf for more information about this executable.
*
* This program is intended to be called only by NLSETUP.EXE during NEPMD
* installation or by RECROBJ.CMD.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dyncfg.cmd,v 1.13 2008-10-07 01:38:04 aschn Exp $
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

LoaderEaName   = 'NEPMD.Loader'

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

/* Check if the env is already extended */
next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IF next <> '' THEN
   'CALL INSTENV'

RootDir = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)

DO 1

   /* Get BootDrive */
   BootDrive = GetBootDrive()

   /* Get OS2 directory name */
   OS2Dir = TRANSLATE( BootDrive'\OS2')
   CheckFile = OS2Dir'\EPM.EXE'
   fCheckFileExists = FileExist( CheckFile)

   /* Check parm */
   ARG Parm .
   IF (Parm = 'UNINSTALL') THEN
   DO
      /* delete EPM.EXE in ?:\os2 if it is ours */
      IF ((fCheckFileExists) & (IsNepmdExecutable( CheckFile, LoaderEaName))) THEN
      DO
         rc = SysFileDelete( CheckFile)
         LEAVE
      END
      LEAVE
   END

   /* Determine name of loader executable */
   LoaderExe = RootDir'\netlabs\bin\epm.exe'
   IF (\FileExist( LoaderExe)) THEN
   DO
      ErrorMessage = 'Error:' LoaderExe 'not found, NEPMD installation is not complete.'
      rc = ERROR.FILE_NOT_FOUND
      LEAVE
   END

   /* Don't touch any EPM.EXE not being ours here */
   IF ((fCheckFileExists) & (\IsNepmdExecutable( CheckFile, LoaderEaName))) THEN
   DO
      ErrorMessage = 'Error:' CheckFile 'is not of NEPMD, cannot continue.',
                     'Dynamic EPM configuration and with it the NEPMD extensions will not work properly.'CrLf''CrLf||,
                     'Remove this file from this directory (usually it',
                     'should rather be installed in' BootDrive'\OS2\APPS) and repeat the installation.'
      rc = ERROR.ACCESS_DENIED
      LEAVE
   END

   /* Determine original EPM.EXE along the path */
   PathList = VALUE( 'PATH', , env)
   fOs2DirPassed = FALSE
   fEpmFound     = FALSE
   DO WHILE (PathList \= '')
      PARSE VAR PathList ThisDir';'PathList
      IF (ThisDir = '') THEN ITERATE

      /* Is it the OS/2 directory? */
      IF (TRANSLATE( ThisDir) = OS2Dir) THEN
      DO
         fOs2DirPassed = TRUE
         ITERATE
      END

      /* Now check for EPM */
      IF (RIGHT( ThisDir, 1) \= '\') THEN
         ThisDir = ThisDir'\'
      EpmExecutable = ThisDir'epm.exe'
      IF (FileExist( EpmExecutable)) THEN
         fEpmFound = TRUE
   END

   IF (fEpmFound) THEN
   DO
      /* If os2 directory was not placed before, our loader will not be used */
      IF (\fOs2DirPassed) THEN
      DO
         ErrorMessage = 'Error: EPM.EXE found in directory prior to' OS2Dir', cannot proceed.'
         rc = ERROR.ACCESS_DENIED
         LEAVE
      END
   END

   /* Copy EPM.EXE of NEPMD */
   'COPY' LoaderExe OS2Dir Redirection
   IF (rc \= 0) THEN
   DO
      ErrorMessage = 'Error: cannot write' CheckFile'.'
      rc = ERROR.ACCESS_DENIED
      LEAVE
   END

   /* Mark EXE with special attribute (EAT_STRING) */
   LoaderInfo = '1'
   EaLen = REVERSE( RIGHT( D2C( LENGTH( LoaderInfo)), 2, D2C(0)))
   EaValue = 'FDFF'x''EaLen''LoaderInfo
   rcx = SysPutEa( CheckFile, LoaderEaName, EaValue)

END

/* Report error message */
IF ErrorMessage <> '' THEN
   CALL SayErrorText

EXIT( rc)

/* ------------------------------------------------------------------------- */
GetBootDrive: PROCEDURE EXPOSE (GlobalVars)
   IF \RxFuncQuery( 'SysBootDrive') THEN
      BootDrive = SysBootDrive()
   ELSE
      PARSE UPPER VALUE VALUE( 'PATH',, env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

   RETURN( BootDrive)

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
   PARSE ARG FileName

   RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '')

/* ------------------------------------------------------------------------- */
FindInPath: PROCEDURE
   PARSE ARG FileName, PathName
   IF (PathName = '') THEN
      PathName = 'PATH'
   RETURN( SysSearchPath( PathName, FileName))

/* ------------------------------------------------------------------------- */
IsNepmdExecutable: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG CheckFile, EaName

   fFound = FALSE

   DO 1

      /* If standard EPM.EXE resides in this directory, we may have a problem */
      IF \(FileExist( CheckFile)) THEN
         LEAVE

      /* Is it our executable ? */
      IF (FindInPath( 'bldlevel.exe') <> '') THEN
      DO
         /* Flush queue */
         DO i = 1 TO QUEUED()
            PARSE PULL next
         END
         /* Get description */
         'bldlevel.exe 'CheckFile' | rxqueue /fifo'
         /* Parse and flush queue */
         DO i = 1 TO QUEUED()
            PARSE PULL next
            IF \(fFound) THEN
            DO
               w1 = WORD( next, 1)
               w2 = WORD( next, 2)
               IF ((w1 = 'Description:') & (w2 = 'EPMCALL')) THEN
                  fFound = TRUE
            END
         END
      END
      IF (fFound) THEN
         LEAVE

      /* No build level found, get EA from previous NEPMD install */
      rc = SysGetEa( CheckFile, EaName, LoaderTag)
      IF ((rc = 0) & (LoaderTag \= '')) THEN
         fFound = TRUE
   END

   RETURN( fFound)

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

