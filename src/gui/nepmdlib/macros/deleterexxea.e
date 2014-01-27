/****************************** Module Header *******************************
*
* Module Name: deleterexxea.e
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
@@NepmdDeleteRexxEa@PROTOTYPE
NepmdDeleteRexxEa( Filename)

@@NepmdDeleteRexxEa@CATEGORY@EAS

@@NepmdDeleteRexxEa@SYNTAX
This function deletes REXX related extended attributes
from the specified file.

@@NepmdDeleteRexxEa@PARM@Filename
This parameter specifies the name of the file, from which
the REXX EAs are to be deleted.

@@NepmdDeleteRexxEa@RETURNS
*NepmdDeleteRexxEa* returns nothing.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdDeleteRexxEa@REMARKS
[=NOTE]
.ul compact
- using this function will have an effect only if the specified
  file is a REXX .cmd file and has previously been executed.
- no error is returned if the specified file exists, but does not have
  the REXX extended attributes

@@NepmdDeleteRexxEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDeleteRexxEa* [.IDPNL_EFUNC_NEPMDDELETEREXXEA_PARM_FILENAME filename]
  - or
- *DeleteRexxEa* [.IDPNL_EFUNC_NEPMDDELETEREXXEA_PARM_FILENAME filename]

Executing this command will
remove the REXX extended attributes from the specified file
and display the result within the status area.

*Example:*
.fo off
  DeleteRexxEa d:\myscript.cmd
.fo on

@@
*/


; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdDeleteRexxEa, DeleteRexxEa

   do i = 1 to 1

      Filename = arg( 1)
      if (Filename = '') then
         sayerror 'error: no filename specified.'
         leave
      endif

      -- error handling for first EA only
      call NepmdDeleteRexxEa( Filename)
      if rc then
         sayerror 'REXX Eas not deleted, rc = 'rc'.'
      else
         sayerror 'REXX Eas deleted.'
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdDeleteRexxEa
; ---------------------------------------------------------------------------
; E syntax:
;    NepmdDeleteRexxEa( Filename)
; ---------------------------------------------------------------------------

defproc NepmdDeleteRexxEa( Filename )

   -- Error handling for first EA only
   call NepmdWriteStringEa( Filename, 'REXX.METACONTROL', '')
   if rc then
      sayerror 'REXX Eas not deleted, rc = 'rc'.'
      return
   endif

   -- Delete all others as well, discard result codes here
   call NepmdWriteStringEa( Filename, 'REXX.PROGRAMDATA', '')
   call NepmdWriteStringEa( Filename, 'REXX.LITERALPOOL', '')
   call NepmdWriteStringEa( Filename, 'REXX.TOKENSIMAGE', '')
   call NepmdWriteStringEa( Filename, 'REXX.VARIABLEBUF', '')

   return

