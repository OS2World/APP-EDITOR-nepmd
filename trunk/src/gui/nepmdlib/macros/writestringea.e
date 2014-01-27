/****************************** Module Header *******************************
*
* Module Name: writestringea.e
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
@@NepmdWriteStringEa@PROTOTYPE
NepmdWriteStringEa( Filename, EaName, EaValue)

@@NepmdWriteStringEa@CATEGORY@EAS

@@NepmdWriteStringEa@SYNTAX
This function writes the specified string as value for the specified
extended attribute to the specified file.

@@NepmdWriteStringEa@PARM@Filename
This parameter specifies the name of the file, to which
the specified REXX EAs is to be written.

@@NepmdWriteStringEa@PARM@EaName
This parameter specifies the name of the extended
attribute to be written.

@@NepmdWriteStringEa@PARM@EaValue
This parameter specifies the string to be written as
the value of the specified extended attribute.

@@NepmdWriteStringEa@RETURNS
*NepmdWriteStringEa* returns nothing.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdWriteStringEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdWriteStringEa*
   [.IDPNL_EFUNC_NEPMDWRITESTRINGEA_PARM_FILENAME filename]
  - or
- *WriteStringEa*
   [.IDPNL_EFUNC_NEPMDWRITESTRINGEA_PARM_FILENAME filename]

Executing this command will
write the string
.sl compact
- *This is a test value for the NepmdWriteStringEa API.*
.el
as an extended string attribute with the name
.sl compact
- *NEPMD.__TestStringEa*
.el
to the specified file
and display the result within the status area.

*Example:*
.fo off
  WriteStringEa d:\myscript.txt
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdWriteStringEa, WriteStringEa

   do i = 1 to 1

      Filename = arg( 1)
      if (Filename = '') then
         sayerror 'Error: no filename specified.'
         leave
      endif

      call NepmdWriteStringEa( Filename, NEPMD_TEST_EANAME, NEPMD_TEST_EAVALUE)
      if rc then
         sayerror 'Extended attribute not written, rc = 'rc'.'
      else
         sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" written to:' Filename
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdWriteStringEa
; ---------------------------------------------------------------------------
; E syntax:
;    NepmdWriteStringEa( Filename, EaName, EaValue)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdWriteStringEa( PSZ pszFilename,
;                                        PSZ pszEaName,
;                                        PSZ pszEaValue)
; ---------------------------------------------------------------------------

defproc NepmdWriteStringEa( Filename, EaName, EaValue)

   -- Prepare parameters for C routine
   Filename   = Filename\0
   EaName     = EaName\0
   EaValue    = EaValue\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdWriteStringEa",
                    address( Filename)            ||
                    address( EaName)              ||
                    address( EaValue))

   helperNepmdCheckliberror( LibFile, rc)

   return

