/****************************** Module Header *******************************
*
* Module Name: direxists.e
*
* E wrapper routine to access the NEPMD library DLL.
* Include of nepmdlib.e.
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

/*
@@NepmdDirExists@PROTOTYPE
fResult = NepmdDirExists( Dirname)

@@NepmdDirExists@CATEGORY@FILE

@@NepmdDirExists@SYNTAX
This function queries wether a directory exists

@@NepmdDirExists@PARM@Dirname
This parameter specifies the name of the directory to be checked.

@@NepmdDirExists@RETURNS
*NepmdDirExists* returns either
.ul compact
- *0* (zero), if the directory does not exist or
- *1*, if the directory exists.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdDirExists@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDirExists* [.IDPNL_EFUNC_NEPMDDIREXISTS_PARM_DIRNAME dirname]
  - or
- *DirExists* [.IDPNL_EFUNC_NEPMDDIREXISTS_PARM_DIRNAME dirname]

Executing this command will check, wether the specified directory exists
or not and display the result within the status area.

*Example:*
.fo off
  DirExists c:\os2
.fo on

@@
*/


; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdDirExists, DirExists

   do i = 1 to 1

      Dirname = arg( 1)
      if (Dirname = '') then
         sayerror 'error: no filename specified.'
         leave
      endif

      fResult = NepmdDirExists( Dirname)
      if (fResult) then
         StrResult = 'does'
      else
         StrResult = 'does not'
      endif

      sayerror 'directory "'Dirname'"' StrResult 'exist.'

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdDirExists
; ---------------------------------------------------------------------------
; E syntax:
;    fResult = NepmdDirExists( filename)
; ---------------------------------------------------------------------------
; C prototype:
;    BOOL EXPENTRY NepmdDirExists( PSZ pszDirname);
; ---------------------------------------------------------------------------

defproc NepmdDirExists( Dirname)

   -- Prepare parameters for C routine
   Dirname = Dirname\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   fResult = dynalink32( LibFile,
                         "NepmdDirExists",
                         address( Dirname))

   helperNepmdCheckliberror( LibFile, fResult)

   return fResult

