/****************************** Module Header *******************************
*
* Module Name: cleanup.cmd
*
* Helper batch for to remove obsolete objects.
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
   rcx = SysDestroyObject( '<NEPMD_EXECUTABLE>')

   /* Delete obsolete objects from before v1.14 if present */
   rcx = SysDestroyObject( '<NEPMD_RECOMP>')
   rcx = SysDestroyObject( '<NEPMD_RECOMPILE_NEW>')
   rcx = SysDestroyObject( '<NEPMD_CHECK_USER_MACROS>')
   rcx = SysDestroyObject( '<NEPMD_TOGGLE_DEFASSOCS>')
   rcx = SysDestroyObject( '<NEPMD_CHANGE_STARTUPDIR>')
   rcx = SysDestroyObject( '<NEPMD_TOGGLE_CCVIEW>')
   rcx = SysDestroyObject( '<NEPMD_TOGGLE_FILEDLG>')
   /*
   /* These objects exist too, but should not be deleted */
   rcx = SysDestroyObject( '<NEPMD_VIEW_NEUSR>')
   rcx = SysDestroyObject( '<NEPMD_VIEW_NEPRG>')
   rcx = SysDestroyObject( '<NEPMD_VIEW_EPMTECH>')
   rcx = SysDestroyObject( '<NEPMD_VIEW_EPMUSERS>')
   rcx = SysDestroyObject( '<NEPMD_VIEW_EPMHELP>')
   */

   /* Delete obsolete files and dirs from prior versions if present */
   rcx = SysDestroyObject( NetlabsDir'\mode\fortran')
   rcx = SysDestroyObject( NetlabsDir'\install\saveold.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\epminit.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\remex.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\nldeinst.exe')
   rcx = SysDestroyObject( NetlabsDir'\install\chgstartupdir.erx')
   rcx = SysDestroyObject( NetlabsDir'\install\epmchgstartupdir.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\epmdefassocs.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\epmnewsamewindow.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\special.cmd')
   rcx = SysDestroyObject( NetlabsDir'\install\nlsetup.exe')
   rcx = SysDestroyObject( NetlabsDir'\macros\drawkey.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\menuacel.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\setconfig.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\small.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\statline.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\titletext.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\xchgline.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\mozkeys.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\balance.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\next_win.e')
   rcx = SysDestroyObject( NetlabsDir'\macros\next_win.ex')
   rcx = SysDestroyObject( NetlabsDir'\bin\epmchangestartupdir.cmd')
   rcx = SysDestroyObject( NetlabsDir'\bin\epmchgpal.cmd')
   rcx = SysDestroyObject( NetlabsDir'\bin\epmcolor.ini')

   /* Remove obsolete ini key from v1.00 if present */
   rcx = SysIni( 'USER', 'NEPMD', 'Path', 'DELETE:')
   rcx = SysIni( 'USER', 'recomp', 'CONFIGDATA', 'DELETE:')

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

