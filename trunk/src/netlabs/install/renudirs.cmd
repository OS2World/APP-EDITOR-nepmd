/****************************** Module Header *******************************
*
* Module Name: renudirs.cmd
*
* Syntax: renudirs [NEPMD]
*
* Helper batch for to rename some user's subdirectories.
*
* These directories are named according to following scheme:
*
*    ex    -> ex_yyyy-mm-dd        (yyyy = year, mm = month, dd = day)
*    mode  -> mode_yyyy-mm-dd      (long filename support required)
*    bin   -> bin_yyyy-mm-dd
*
* If a directory name already exists, a counter is added:
*
*    ex_yyyy-mm-dd
*    ex_yyyy-mm-dd_1
*    ex_yyyy-mm-dd_2
*
* New empty directories were created on success and NEPMD.INI will be copied.
*
* This is executed by the installer to ensure that a newly installed NEPMD
* uses its own macros at first. Otherwise incompatibities may happen, because
* EPM's behavior depends not only on the macros, but also on the library and
* the configuration files. In the worst case, one would end up with a not
* starting EPM, so renaming the files automatically is the best solution.
*
* After installation, merge your previous changes/additions with the newly
* installed files of the netlabs tree.
*
* When no incompatibilies exist, the .ex files can be recreated by a
* RecompileNew command, because the user's macro sources were not renamed.
* For other files, and alternatively for the .ex files, the old user files
* may be copied to the new empty directories.
*
* This program is intended to be called only by POSTWPI2.CMD during NEPMD
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
/* Some header lines are used as help text */
Help1StartLine  = 7
Help1EndLine    = 27
Help2StartLine  = 29
Help2EndLine    = 35

/* ###################### Configurable part starts ################### */
/* User subdirs to process */
SubDirs = 'ex mode bin'
/* ###################### Configurable part ends ##################### */

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

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

/* Check if the env is already extended */
next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IF next = '' THEN
   'CALL INSTENV'

UserDir = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_USERDIR)'_INST',, env)

DO 1

   /* Make sure we are called on purpose */
   ARG Parm .
   IF Parm = 'NEPMD' THEN
      fQuiet = TRUE
   ELSE
      fQuiet = FALSE

   IF \fQuiet THEN
   DO
      SAY
      DO l = Help1StartLine TO Help1EndLine
         SAY SUBSTR( SOURCELINE( l), 3)
      END
      SAY
      SAY 'Do you want to continue? (Y/N)'
      PULL Answer
      Answer = STRIP( Answer)
      IF (ANSWER <> 'Y') THEN
         SIGNAL Halt
   END

   /* Get date string */
   IsoDate = GetIsoDate()

   /* Process dirs */
   DO i = 1 to WORDS( SubDirs)
      SubDir.i = WORD( SubDirs, i)
      OldDir = UserDir'\'SubDir.i

      /* Check for existing dir */
      IF \DirExist( OldDir) THEN
         ITERATE

      /* Check for contained files */
      IF \TreeContainsFiles( OldDir) THEN
         ITERATE

      /* Check for contained NEPMD.INI */
      fContainsNepmdIni     = FALSE
      fContainsOnlyNepmdIni = FALSE
      DO 1
         IF \FileExist( OldDir'\NEPMD.INI') THEN
            LEAVE
         fContainsNepmdIni = TRUE
         IF NumberOfExistingFiles( OldDir'\*') = 1 THEN
            fContainsOnlyNepmdIni = TRUE
      END
      /* No need to xcopy just NEPMD.INI, it will be reused */
      IF fContainsOnlyNepmdIni THEN
         LEAVE

      NewDirName = SubDir.i'_'IsoDate
      NewDir     = UserDir'\'NewDirName

      /* Check for already existing dir name */
      c = 0
      DO WHILE DirExist( NewDir)
         /* Append counter to dir name */
         c = c + 1
         NewDirName = SubDir.i'_'IsoDate'_'c
         NewDir     = UserDir'\'NewDirName
      END

      /* Rename dir: copy file objects from OldDir to NewDir */
      IF \fQuiet THEN
         SAY 'Copying 'OldDir' -> 'NewDirName
      OldDirSpec = OldDir'\*'
      IF POS( ' ', OldDirSpec) > 0 then
         OldDirSpec = '"'OldDirSpec'"'
      NewDirSpec = NewDir'\'
      IF POS( ' ', NewDirSpec) > 0 then
         NewDirSpec = '"'NewDirSpec'"'
      XcopyOptions = '/H/O/T/S/R'
      'XCOPY' OldDirSpec NewDirSpec XcopyOptions Redirection

      /* Rename dir: remove .LONGNAME from NewDir, ignore error */
      rcx = SysPutEa( NewDir, '.LONGNAME', '')

      /* Rename dir: delete file objects from OldDir */
      ExcludeList = OldDir'\nepmd.ini'
      rc = RmDirContent( OldDir, ExcludeList)

      /* Check for error */
      IF (rc <> 0) THEN
         LEAVE
   END

   /* Show next help text on success when in non-quiet mode */
   IF (rc = 0) & \fQuiet THEN
   DO
      SAY
      DO l = Help2StartLine TO Help2EndLine
         SAY SUBSTR( SOURCELINE( l), 3)
      END
   END

END

/* Report error message */
IF ErrorMessage <> '' THEN
   CALL SayErrorText

EXIT( rc)

/* ------------------------------------------------------------------------- */
RmDirContent: PROCEDURE EXPOSE (GlobalVars)
   PARSE ARG Dir, ExcludeList
   ExcludeList = TRANSLATE( ExcludeList)

   /* Remove files */
   Found. = 0
   rc = SysFileTree( Dir'\*', 'Found.', 'FOS')
   IF rc <> 0 THEN
     RETURN( rc)
   DO i = 1 TO Found.0
      ThisFile = Found.i
      IF POS( TRANSLATE( ThisFile), ExcludeList) > 0 THEN
         ITERATE
      rcx = SysFileTree( ThisFile, 'File.', 'FO',,'-----')
      rcx = SysFileDelete( ThisFile)
      /*say rcx' - 'ThisFile*/
   END

   /* Remove dirs */
   Found. = 0
   rc = SysFileTree( Dir'\*', 'Found.', 'DOS')
   IF rc <> 0 THEN
     RETURN( rc)
   DO i = Found.0 TO 1 BY -1
      ThisDir = Found.i
      /*say '  - 'ThisDir*/
      rcx = SysFileTree( ThisDir, 'Dir.', 'DO',,'-*---')
      rcx = SysRmDir( ThisDir)
      /*say i'/'Found.0': 'rcx' - 'ThisDir*/
   END

   rc = ERROR.NO_ERROR
   RETURN( rc)

/* ------------------------------------------------------------------------- */
GetIsoDate: PROCEDURE
   PARSE VALUE DATE( 'S') WITH yyyy +4 mm +2 dd

   RETURN( yyyy'-'mm'-'dd)

/* ------------------------------------------------------------------------- */
/* Find also hidden files */
FileExist: PROCEDURE
   PARSE ARG Filename

   Found.0 = 0
   rcx = SysFileTree( Filename, 'Found.', 'FO')

   RETURN( Found.0 > 0)

/* ------------------------------------------------------------------------- */
/* Find also hidden files */
NumberOfExistingFiles: PROCEDURE
   PARSE ARG Filename

   Found.0 = 0
   rcx = SysFileTree( Filename, 'Found.', 'FO')

   RETURN( Found.0)

/* ------------------------------------------------------------------------- */
DirExist: PROCEDURE
   PARSE ARG Dirname

   Found.0 = 0
   rcx = SysFileTree( Dirname, 'Found.', 'DO')

   RETURN( Found.0 > 0)

/* ------------------------------------------------------------------------- */
TreeContainsFiles: PROCEDURE
   PARSE ARG DirName

   Found.0 = 0
   rcx = SysFileTree( DirName'\*', 'Found.', 'FOS')

   RETURN( Found.0 > 0)

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

