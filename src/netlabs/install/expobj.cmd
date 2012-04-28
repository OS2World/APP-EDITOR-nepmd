/****************************** Module Header *******************************
*
* Module Name: expobj.cmd
*
* Export important WarpIN database entries for NEPMD in order to enable
* recreation of ini entries and object. This CMD file is called at the end
* of the installation.
*
* This program is intended to be called only by POSTWPI2.CMD during NEPMD
* installation.
*
* Copyright (c) Netlabs EPM Distribution Project 2008
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

IF ADDRESS() <> 'EPM' THEN
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

Title._PathPrefix    = 'Netlabs\Netlabs EPM Distribution\'
Title._PckKey        = 'WIPackHeader'
Title._TargetPathKey = 'TargetPath'
Title._ProfileKey    = 'WritePrfAttrs'
Title._ObjectsKey    = 'WPSObjectAttrs'
Title._ExecuteKey    = 'ExecuteAttrs'

/* ExportFilename will be created in the same dir as this file. Better  */
/* use the netlabs tree to find that file easily, even when the user    */
/* tree was created elsewhere out of the NEPMD rootdir, e.g. in %HOME%. */
ExportFilename       = 'recrobj.dat'

GlobalVars = GlobalVars 'ErrorQueueName ErrorMessage Title.'
/* -------------------------------------------- */

DO 1

   /* Get BootDrive */
   BootDrive = GetBootDrive()

   /* Find WarpIN database */
   next = STRIP( SysIni( USER, 'WarpIN', 'Path'),, '00'x)
   IF (next = 'ERROR:') THEN
   DO
      ErrorMessage = 'Error: WarpIN entry not found in user ini.'
      rc = ERROR.PATH_NOT_FOUND
      LEAVE
   END
   WarpINDir = STRIP( next,, '00'x)

   DataBase = WarpINDir'\DATBAS_'LEFT( BootDrive, 1)'.INI'

   /* Read database */
   PckNumber.    = ''
   PckNumberList = ''
   PckIndexList  = ''
   Appl.  = ''
   Appl.0 = 0
   ExportLine.  = ''
   ExportLine.0 = 0
   next = SysIni( DataBase, 'ALL:', 'Appl.')
   IF (next = 'ERROR:') THEN
   DO
      ErrorMessage = 'Error: "'DataBase'" could not be read.'
      rc = ERROR.READ_FAULT
      LEAVE
   END

   /* First loop: get package numbers and titles */
   DO i = 1 to Appl.0
      /* Check prefix */
      IF (POS( Title._PathPrefix, Appl.i) <> 1) THEN
         ITERATE

      /* Get Pck # */
      next = SysIni( DataBase, Appl.i, Title._PckKey)
      IF (next <> 'ERROR:') THEN
      DO
         p1 = POS( 'Pck', STRIP( next,, '00'x))
         IF (p1 > 0) THEN
         DO
            PckNumber.i = STRIP( SUBSTR( next, p1 + 3, 3), 'L', '0')
            PckNumberList = PckNumberList PckNumber.i
            PckIndexList  = PckIndexList i
         END
      END

      /* Get Pck title, omit project title */
      Title.i = SUBSTR( Appl.i, LENGTH( Title._PathPrefix) + 1)

      /*SAY PckNumber.i' (i = 'i') TITLE='SUBSTR( Appl.i, LENGTH( Title._PathPrefix) + 1)*/
   END
   PckNumberList = STRIP( PckNumberList)
   PckIndexList  = STRIP( PckIndexList)

   /* Second loop: process the rest and set ExportLines */
   RestNumberList = PckNumberList
   RestIndexList  = PckIndexList
   l = 0
   DO WHILE RestNumberList <> ''
      /* Find lowest PckNumber to write export file in the correct order easily */
      LowestNumber = WORD( RestNumberList, 1)
      LowestNumberWordPos = 1
      DO p = 1 TO WORDS( RestNumberList)
         ThisNumber = WORD( RestNumberList, p)
         IF (ThisNumber < LowestNumber) THEN
         DO
            LowestNumber = ThisNumber
            LowestNumberWordPos = p
         END
      END

      ThisNumber = LowestNumber
      ThisIndex  = WORD( RestIndexList, LowestNumberWordPos)
      /*SAY 'RestNumberList = 'RestNumberList', RestIndexList = 'RestIndexList', ThisNumber = 'ThisNumber', i = 'ThisIndex*/
      RestNumberList = DELWORD( RestNumberList, LowestNumberWordPos, 1)
      RestIndexList  = DELWORD( RestIndexList, LowestNumberWordPos, 1)

      i = ThisIndex
      l = l + 1
      ExportLine.l = PckNumber.i' TITLE='Title.i

      /* Get TargetPath */
      IF (PckNumber.i = 1) THEN
      DO
         next = SysIni( DataBase, Appl.i, Title._TargetPathKey)
         IF (next <> 'ERROR:') THEN
         DO
            TargetPath = STRIP( next,, '00'x)
            l = l + 1
            ExportLine.l = PckNumber.i' TARGETPATH='TargetPath
         END
      END

      /* Get ini entries */
      next = SysIni( DataBase, Appl.i, Title._ProfileKey)
      IF (next <> 'ERROR:') THEN
      DO
         rest = STRIP( next,, '00'x)
         DO WHILE rest <> ''
            PARSE VAR rest next'00'x rest
            l = l + 1
            ExportLine.l = PckNumber.i' PROFILE='next
         END
      END

      /* Get objects */
      next = SysIni( DataBase, Appl.i, Title._ObjectsKey)
      IF (next <> 'ERROR:') THEN
      DO
         rest = STRIP( next,, '00'x)
         DO WHILE rest <> ''
            PARSE VAR rest next'00'x rest
            l = l + 1
            ExportLine.l = PckNumber.i' OBJECT='next
         END
      END

      /* Get execute calls */
      next = SysIni( DataBase, Appl.i, Title._ExecuteKey)
      IF (next <> 'ERROR:') THEN
      DO
         rest = STRIP( next,, '00'x)
         DO WHILE rest <> ''
            PARSE VAR rest next'00'x rest
            l = l + 1
            ExportLine.l = PckNumber.i' EXECUTE='next
         END
      END

   END
   ExportLine.0 = l

   /* Write ExportFile */
   lp = LASTPOS( '\', ThisFile)
   ExportFile = SUBSTR( ThisFile, 1, lp)ExportFilename
   IF (ExportLine.0 > 0) THEN
   DO
      IF (STREAM( ExportFile, 'c', 'query exists') <> '') THEN
         rcx = SysFileDelete( ExportFile)
      DO l = 1 TO ExportLine.0
         rcx = LINEOUT( ExportFile, ExportLine.l)
      END
      rcx = STREAM( ExportFile, 'c', 'close')
   END

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

