/****************************** Module Header *******************************
*
* Module Name: libversion.e
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
@@NepmdLibVersion@PROTOTYPE
Version = NepmdLibVersion()

@@NepmdLibVersion@CATEGORY@INSTALL

@@NepmdLibVersion@SYNTAX
This function queries the version of the installed runtime library
of the [=TITLE].

@@NepmdLibVersion@RETURNS
*NepmdLibVersion* returns the version number of the runtime library
of the [=TITLE]. In case of an error an empty string is returned.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdLibVersion@TESTCASE
You can test this function from the *EPM* commandline by executing:
.sl
- *NepmdLibVersion*

Executing this command will display the version number of the runtime
library of the [=TITLE] within the status area.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
; This command is executed from the menu and should be available from cammand
; line.

defc NepmdLibVersion

   sayerror 'NEPMDLIB Version' NepmdLibVersion()

; ---------------------------------------------------------------------------
; Procedure: NepmdLibVersion
; ---------------------------------------------------------------------------
; E syntax:
;    Version = NepmdLibVersion()
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdLibVersion( PSZ pszBuffer,
;                                     ULONG ulBuflen)
; ---------------------------------------------------------------------------

defproc NepmdLibVersion()

   BufLen     = 20
   LibVersion = copies( \0, BufLen)

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdLibVersion",
                    address( LibVersion) ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( LibVersion)
   endif

