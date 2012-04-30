/****************************** Module Header *******************************
*
* Module Name: rmepm.cmd
*
* Syntax: rmepm [NEPMD]
*
* Helper batch for to backup and delete an existing EPM of ?:\OS2\APPS.
*
* Either a zip file (if ZIP.EXE found in PATH) or an xcopied tree is created
* in NEPMD\backup. The name of the zip file is EPM_old.zip.
*
* After the backup (as a minimum: the binaries) proceeded successful, the
* old files will be deleted.
*
* This Cmd is not called by POSTWPI2.CMD. It can be called directly. It was
* left in here, because one would like to uninstall all EPM 5 files of
* Warp 3. Note that this is not required. NEPMD can be used with the EPMBBS
* bins on Warp 3 without uninstalling EPM 5.
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
/* Some header lines are used as help text */
HelpStartLine  = 7
HelpEndLine    = 13

'@ECHO OFF'
CALL SETLOCAL

/* Initialize */
call RxFuncAdd    'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs
env = 'OS2ENVIRONMENT'
TRUE  = (1 = 1)
FALSE = (0 = 1)
Redirection = '>NUL 2>&1'

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

/* Defaults and further consts */
fDelete        = TRUE
fDeleteList    = TRUE
fRecoursive    = FALSE;  /* recoursive not required */
fUseZip        = TRUE
rc             = ERROR.NO_ERROR
ErrorQueueName = VALUE( 'NEPMD_RXQUEUE', , env)
ErrorMessage   = ''
BackupDirSubPath = 'backup'  /* relative to RootDir */
BackupName       = 'EPM_old'

/* Make sure we are called on purpose */
ARG Parm .
IF (Parm \= 'NEPMD') THEN
DO
   SAY
   DO l = HelpStartLine TO HelpEndLine
      SAY SUBSTR( SOURCELINE( l), 3)
   END
END
SAY
SAY 'Do you want to continue? (Y/N)'
PULL Answer
Answer = STRIP( Answer)
IF (ANSWER <> 'Y') THEN
   EXIT( ERROR.GEN_FAILURE)

/* Get BootDrive */
IF \RxFuncQuery( 'SysBootDrive') THEN
   BootDrive = SysBootDrive()
ELSE
   PARSE UPPER VALUE VALUE( 'PATH', , env) WITH ':\OS2\SYSTEM' -1 BootDrive +2

/* Get the base directory of the NEPMD installation */
PARSE Source . . CallName
CallDir    = LEFT( CallName,   LASTPOS( '\', CallName) - 1)
NetlabsDir = LEFT( CallDir,    LASTPOS( '\', CallDir) - 1)
RootDir    = LEFT( NetlabsDir, LASTPOS( '\', NetlabsDir) - 1)
BackupDir  = RootDir'\'BackupDirSubPath

GlobalVars = 'env TRUE FALSE Redirection BackupDir BackupName fUseZip fDelete fDeleteList fRecoursive'

DO 1

   /* Check for old EPM */
   EpmExe = BootDrive'\OS2\APPS\EPM.EXE'
   IF (\FileExist( BootDrive'\OS2\APPS\EPM.EXE')) THEN
   DO
      rc = ERROR.FILE_NOT_FOUND
      ErrorMessage = 'Error: 'EpmExe' not found.'
      LEAVE
   END

   /* Get a list file */
   ListFile = SysTempFilename( VALUE( 'TMP', , 'OS2ENVIRONMENT')'\nepmd.???')
   IF (\fDeleteList) THEN
      SAY 'Using ListFile "'ListFile'".'

   /* Get EPM.INI */
   next = SysIni( 'USER', 'EPM', 'EPMIniPath')
   IF next = 'ERROR:' THEN
      EpmIni = BootDrive'OS2\EPM.INI'
   ELSE
      EpmIni = STRIP( next, 'T', '00'x)
   /* Remove attribs, except A */
   rc = SysFileTree( EpmIni, 'EpmIni.', 'FO',,'*----')

   /* Check if ZIP.EXE is in PATH */
   IF (fUseZip = TRUE) THEN
   DO
      next = SysSearchPath( 'PATH', 'ZIP.EXE')
      fUseZip = (next > '')
   END

   /* Create backup path */
   rest = BackupDir
   last = ''
   i = 0
   /* Strip \\machine\resource for UNC filename */
   IF LEFT( BackupDir, 2) = '\\' THEN
   DO
      p1 = POS( '\', BackupDir, 3)
      p2 = POS( '\', BackupDir, p1 + 1)
      last = LEFT( BackupDir, MAX( p2 - 1, 0))  /* last: without trailing \ */
      rest = SUBSTR( BackupDir, p2 + 1)         /* rest: without leading \ */
   END
   /* Strip drive for full filename */
   IF SUBSTR( BackupDir, 2, 2) = ':\' THEN
      PARSE VAR BackupDir last'\'rest  /* last: without trailing \, rest: without leading \ */
   /* Create entire tree to ensure it exists */
   DO WHILE rest <> ''
      PARSE VAR rest next'\'rest
      last = last'\'next
      CALL SysMkDir( last)
   END

   /* Now backup and remove */
   SAY 'Backing up old EPM files to directory' BackupDir

   IF EPMIni \= '' THEN
      rc = BackupFiles( EPMIni,                         BackupDir'\OS2',          ListFile)
   rc = BackupFiles( BootDrive'\OS2\APPS\EPM*',         BackupDir'\OS2\APPS',     ListFile)
   IF (rc \= 0) THEN fDelete = 0
   rc = BackupFiles( BootDrive'\OS2\APPS\DLL\ETK*.DLL', BackupDir'\OS2\APPS\DLL', ListFile)
   IF (rc \= 0) THEN fDelete = 0
   rc = BackupFiles( BootDrive'\OS2\APPS\DLL\EPM*.DLL', BackupDir'\OS2\APPS\DLL', ListFile)
   rc = BackupFiles( BootDrive'\OS2\APPS\*.EX',         BackupDir'\OS2\APPS',     ListFile)
   IF (rc \= 0) THEN fDelete = 0
   rc = BackupFiles( BootDrive'\OS2\APPS\*.E',          BackupDir'\OS2\APPS',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\APPS\*.ERX',        BackupDir'\OS2\APPS',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\APPS\ACTIONS.LST',  BackupDir'\OS2\APPS',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\APPS\*.BMP',        BackupDir'\OS2\APPS',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\HELP\EPM*.HLP',     BackupDir'\OS2\HELP',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\HELP\ETK*.HLP',     BackupDir'\OS2\HELP',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\HELP\TREE.HLP',     BackupDir'\OS2\HELP',     ListFile)
   rc = BackupFiles( BootDrive'\OS2\HELP\REFLOW.HLP',   BackupDir'\OS2\HELP',     ListFile)
   /* Note: \OS2\EPM* would process files in \OS2\ARCHIVES */

   /* Now delete files, ignore errors here */
   IF (fDelete = TRUE) THEN
      SAY 'Removing old EPM files'
   ELSE
      SAY 'Test mode: listing old EPM files'

   DO WHILE (LINES( ListFile))
      ThisFile = STRIP( LINEIN( ListFile))
      IF (ThisFile = '') THEN ITERATE

      /* Don't remove EPM.INI */
      IF TRANSLATE( filespec( 'N', THISFILE)) = 'EPM.INI' THEN ITERATE

      rcx = SysFileTree( ThisFile, 'File.', 'F',,'-----')

      SAY ThisFile
      IF (fDelete = TRUE) THEN
         rcx = SysFileDelete( ThisFile)

      rc = ERROR.NO_ERROR
   END

   CALL STREAM ListFile, 'C', 'CLOSE'
   IF (fDeleteList = TRUE) THEN
      rcx = SysFileDelete( ListFile)

END

/* Report error message */
SELECT
   /* No error here */
   WHEN (rc = 0) THEN NOP

   /* Called by frame program: insert error */
   /* message into standard REXX queue     */
   WHEN (ErrorQueueName \= '') THEN
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

EXIT( rc)

/* ------------------------------------------------------------------------- */
FileExist: PROCEDURE
   PARSE ARG FileName

   RETURN( STREAM( Filename, 'C', 'QUERY EXISTS') > '')

/* ------------------------------------------------------------------------- */
BackupFiles: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG FileName, DestDir, ListFile

   IF fRecoursive THEN      /* recoursive not required */
   DO
     DirOptions   = '/S /F /A-D'
     XcopyOptions = '/H/O/T/S/R'
     ZipOptions   = '-rSD'
   END
   ELSE
   DO
     DirOptions   = '/F /A-D'
     XcopyOptions = '/H/O/T/R'
     ZipOptions   = '-SD'
   END

   DO UNTIL (TRUE)

      /* Check if filespec exists to avoid xcopy beeps */
      IF \FileExist( FileName) THEN
         LEAVE

      /* Append filenames to listfile */
      'DIR' FileName DirOptions '>>' ListFile '2>NUL'

      /* Copy the files */
      IF fUseZip = 0 THEN
         'XCOPY' FileName DestDir'\' XcopyOptions Redirection
      ELSE
      DO
         SavedDir = DIRECTORY()
         CALL DIRECTORY BackUpDir
         'ZIP' ZipOptions BackupDir'\'BackupName FileName Redirection
         CALL DIRECTORY SavedDir
      END

   END

   RETURN( rc)

/* ------------------------------------------------------------------------- */
HALT:
   SAY
   SAY 'Interrupted by user.'
   EXIT( ERROR.GEN_FAILURE)

