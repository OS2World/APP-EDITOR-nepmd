/****************************** Module Header *******************************
*
* Module Name: usertree.cmd
*
* Helper batch for to create all directories of the personal subdirectory
* tree. (A WarpIN package cannot include empty directories.)
*
* Additionally, it creates shadow objects for the user and the root folder
* and also applies help panels to make F1 show help for objects.
*
* This program is intended to be called only by POSTWPI2.CMD during NEPMD
* installation or by RECROBJ.CMD.
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

/* ##############   Maintainer: modify directory list here ######################## */

UserDirList = 'bar bin bmp dll ex mode macros ndx autolink spellchk'
/* Additionally, the UserDir is created by this script */

/* ################################################################################# */

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
NEPMD_INI_KEYNAME_LANGUAGE    = "Language"
NEPMD_INI_KEYNAME_USERDIR     = "UserDir"

FolderId      = '<NEPMD_FOLDER>'
ObjectIdStart = '<NEPMD_'
ObjectIdEnd   = '_SHADOW>'

UserDirName = 'myepm'
RootDirName = 'NEPMD'

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

/* Check if the env is already extended */
next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IF next = '' THEN
   'CALL INSTENV'

RootDir  = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
Language = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_LANGUAGE)'_INST',, env)
UserDir  = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_USERDIR)'_INST',, env)

NetlabsHelpFile = RootDir'\netlabs\help\nefld'Language'.hlp'

DO 1

   DO 1
      /* Ensure that user dir exists */
      rcx = SysMkDir( UserDir)
      IF WORDPOS( rcx, '0 5') = 0 THEN  /* rc = 5: dir already exists */
      DO
         ErrorMessage = 'Error: cannot create user directory "'UserDir'".'
         rc = rcx
         LEAVE
      END

      /* Apply help panel to UserDir folder */
      rcx = SysSetObjectData( UserDir, 'DEFAULTVIEW=TREE;HELPLIBRARY='NetlabsHelpFile';HELPPANEL=105;')

      /* Create shadow of UserDir folder in NEPMD folder */
      ObjectId = ObjectIdStart''TRANSLATE( UserDirName)''ObjectIdEnd
      rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='UserDir';OBJECTID='ObjectId';', 'U')

      /* Create directories here - ignore errors */
      DO WHILE (UserDirList \= '')
         PARSE VAR UserDirList ThisDir UserDirList
         FullPath = UserDir'\'ThisDir
         rcx = SysMkDir( FullPath)
         rcx = SysSetObjectData( FullPath, 'DEFAULTVIEW=ICON;')
      END
   END

   /* Apply help panel to RootDir folder */
   rcx = SysSetObjectData( RootDir, 'DEFAULTVIEW=TREE;HELPLIBRARY='NetlabsHelpFile';HELPPANEL=114;')

   /* Create shadow of RootDir folder in NEPMD folder */
   ObjectId = ObjectIdStart''TRANSLATE( RootDirName)''ObjectIdEnd;
   rcx = SysCreateObject( 'WPShadow', '.', FolderId, 'SHADOWID='RootDir';OBJECTID='ObjectId';', 'U')

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

