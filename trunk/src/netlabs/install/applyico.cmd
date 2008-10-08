/****************************** Module Header *******************************
*
* Module Name: applyico.cmd
*
* Helper batch for to attach operating system dependant icons to the folders
* of the NEPMD, as WarpIn can currently not determine the operating system
* version (Warp 3/Warp 4/eComStation) during installation.
*
* This program is intended to be called only by NLSETUP.EXE during NEPMD
* installation or by RECROBJ.CMD.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: applyico.cmd,v 1.20 2008-10-08 00:52:18 aschn Exp $
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

/* ##############   Maintainer: modify object id list here ######################## */

FolderObjectIdList = '<NEPMD_FOLDER> <NEPMD_SAMPLES_FOLDER>' ||,
                     ' <NEPMD_MORE_OBJECTS_FOLDER>'

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

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage'
/* -------------------------------------------- */

/* Check if the env is already extended */
next = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IF next = '' THEN
   'CALL INSTENV'

RootDir = VALUE( 'NEPMD_'TRANSLATE( NEPMD_INI_KEYNAME_ROOTDIR)'_INST',, env)
IconDir = RootDir'\netlabs\install\ico'
EcsFlag = VALUE( ECS_FLAG,, env)

DO 1

   /* Determine operating system type */
   SELECT
      WHEN (SysOs2Ver() < '2.40') THEN Type = '3'
      WHEN (EcsFlag = 1)          THEN Type = 'e'
      OTHERWISE                        Type = '4'
   END

   FolderIconSetup = 'ICONFILE='IconDir'\folder'Type'.ico;' ||,
                     'ICONNFILE=1,'IconDir'\folder'Type'o.ico;'

   /* Set icon for folders of FolderObjectIdList */
   DO WHILE (FolderObjectIdList \= '')
      PARSE VAR FolderObjectIdList ThisObject FolderObjectIdList
      rcx = SysSetObjectData( ThisObject, FolderIconSetup)
   END

   /* Set icon for user folder */
   rcx = SysSetObjectData( UserDir, FolderIconSetup)

   /* Set icon for netlabs folder */
   rcx = SysSetObjectData( RootDir'\netlabs', FolderIconSetup)

   /* set icon for root folder */
   rcx = SysSetObjectData( RootDir, FolderIconSetup)

   /* Set icons for EPM program objects */
   /* (required only for showing the icon immediately after install) */
   rcx = SysSetObjectData( '<NEPMD_EPM>',,
                          'ICONFILE='IconDir'\nepmd.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_NEW_SAME_WINDOW>',,
                          'ICONFILE='IconDir'\nepmd.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_SHELL>',,
                          'ICONFILE='IconDir'\nepmd.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_TURBO>',,
                          'ICONFILE='IconDir'\nepmd.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_BIN>',,
                          'ICONFILE='IconDir'\nepmd.ico;')

   /* Set special icons for EPM program objects */
   rcx = SysSetObjectData( '<NEPMD_EPM_E>',,
                          'ICONFILE='IconDir'\nepmd_e.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_EDIT_MACROFILE>',,
                          'ICONFILE='IconDir'\nepmd_ex.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_ERX>',,
                          'ICONFILE='IconDir'\nepmd_erx.ico;')
   rcx = SysSetObjectData( '<NEPMD_EPM_TEX>',,
                          'ICONFILE='IconDir'\nepmd_tex.ico;')

   rcx = SysSetObjectData( '<NEPMD_TOGGLE_CCVIEW>',,
                          'ICONFILE='IconDir'\recomp.ico;')
   rcx = SysSetObjectData( '<NEPMD_CHANGE_STARTUPDIR>',,
                          'ICONFILE='IconDir'\recomp.ico;')
   rcx = SysSetObjectData( '<NEPMD_TOGGLE_DEFASSOCS>',,
                          'ICONFILE='IconDir'\recomp.ico;')

   rcx = SysSetObjectData( '<NEPMD_RECOMPILE_NEW>',,
                          'ICONFILE='IconDir'\recomp.ico;')
   rcx = SysSetObjectData( '<NEPMD_CHECK_USER_MACROS>',,
                          'ICONFILE='IconDir'\recomp.ico;')

   rcx = SysSetObjectData( '<NEPMD_VIEW_NEUSR>',,
                          'ICONFILE='IconDir'\help.ico;')
   rcx = SysSetObjectData( '<NEPMD_VIEW_NEPRG>',,
                          'ICONFILE='IconDir'\help.ico;')

   /* Remove dummy file. Copied as a workaround for older WarpIN versions. */
   rcx = SysDestroyObject( RootDir'\srccopy.txt')

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

