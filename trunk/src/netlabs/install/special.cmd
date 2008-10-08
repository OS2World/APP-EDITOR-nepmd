/****************************** Module Header *******************************
*
* Module Name: special.cmd
*
* Helper batch for to remove obsolete objects.
*
* This program is intended to be called only by NLSETUP.EXE during NEPMD
* installation or by RECROBJ.CMD.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: special.cmd,v 1.7 2008-10-08 00:52:18 aschn Exp $
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

'@echo off'

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
NetlabsDir = RootDir'\netlabs'

DO 1

   /* Delete obsolete object from v1.00 if present */
   rc = SysDestroyObject( '<NEPMD_EXECUTABLE>')

   /* Delete obsolete objects from before v1.14 if present */
   rc = SysDestroyObject( '<NEPMD_RECOMP>')
   rc = SysDestroyObject( '<NEPMD_RECOMPILE_NEW>')
   rc = SysDestroyObject( '<NEPMD_CHECK_USER_MACROS>')
   rc = SysDestroyObject( '<NEPMD_TOGGLE_DEFASSOCS>')
   rc = SysDestroyObject( '<NEPMD_CHANGE_STARTUPDIR>')
   rc = SysDestroyObject( '<NEPMD_TOGGLE_CCVIEW>')
   rc = SysDestroyObject( '<NEPMD_TOGGLE_FILEDLG>')
   /*
   /* These objects exist too, but should not be deleted */
   rc = SysDestroyObject( '<NEPMD_VIEW_NEUSR>')
   rc = SysDestroyObject( '<NEPMD_VIEW_NEPRG>')
   rc = SysDestroyObject( '<NEPMD_VIEW_EPMTECH>')
   rc = SysDestroyObject( '<NEPMD_VIEW_EPMUSERS>')
   rc = SysDestroyObject( '<NEPMD_VIEW_EPMHELP>')
   */

   /* Delete obsolete files and dirs from prior versions if present */
   rc = SysDestroyObject( NetlabsDir'\mode\fortran')
   rc = SysDestroyObject( NetlabsDir'\install\saveold.cmd')
   rc = SysDestroyObject( NetlabsDir'\install\epminit.cmd')
   rc = SysDestroyObject( NetlabsDir'\install\remex.cmd')
   rc = SysDestroyObject( NetlabsDir'\install\nldeinst.exe')
   rc = SysDestroyObject( NetlabsDir'\install\chgstartupdir.erx')
   rc = SysDestroyObject( NetlabsDir'\install\epmchgstartupdir.cmd')
   rc = SysDestroyObject( NetlabsDir'\install\epmdefassocs.cmd')
   rc = SysDestroyObject( NetlabsDir'\install\epmnewsamewindow.cmd')
   rc = SysDestroyObject( NetlabsDir'\macros\drawkey.e')
   rc = SysDestroyObject( NetlabsDir'\macros\menuacel.e')
   rc = SysDestroyObject( NetlabsDir'\macros\setconfig.e')
   rc = SysDestroyObject( NetlabsDir'\macros\small.e')
   rc = SysDestroyObject( NetlabsDir'\macros\statline.e')
   rc = SysDestroyObject( NetlabsDir'\macros\titletext.e')
   rc = SysDestroyObject( NetlabsDir'\macros\xchgline.e')
   rc = SysDestroyObject( NetlabsDir'\bin\epmchangestartupdir.cmd')

   /* Remove obsolete ini key from v1.00 if present */
   rc = SysIni( 'USER', 'NEPMD', 'Path', 'DELETE:')

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

