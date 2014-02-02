/****************************** Module Header *******************************
*
* Module Name: querystringea.e
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
@@NepmdQueryStringEa@PROTOTYPE
EaValue = NepmdQueryStringEa( Filename, EaName)

@@NepmdQueryStringEa@CATEGORY@EAS

@@NepmdQueryStringEa@SYNTAX
This function reads the specified string extended attribute
from the specified file. Please note that this function can
only retrieve string EAs properly, retrieving any other type
of extended attributes may lead to unpredictable results.

@@NepmdQueryStringEa@PARM@Filename
This parameter specifies the name of the file, from which
the specified REXX EAs is to be read.

@@NepmdQueryStringEa@PARM@EaName
This parameter specifies the name of the extended
attribute to be read.

@@NepmdQueryStringEa@RETURNS
*NepmdQueryStringEa* returns the value of the requested extended attribute.
In case of an error an empty string is returned.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdQueryStringEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryStringEa*
   [.IDPNL_EFUNC_NEPMDQUERYSTRINGEA_PARM_FILENAME filename]
  - or
- *QueryStringEa*
   [.IDPNL_EFUNC_NEPMDQUERYSTRINGEA_PARM_FILENAME filename]


Executing this command will
read the extended string attribute with the name
.sl compact
- *NEPMD.__TestStringEa*
.el
from the specified file
and display the result within the status area.

*Example:*
.fo text
 QueryStringEa d:\myscript.txt
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdQueryStringEa, QueryStringEa

   do i = 1 to 1

      Filename = arg( 1)
      if (Filename = '') then
         sayerror 'Error: no filename specified.'
         leave
      endif

      EaValue = NepmdQueryStringEa( Filename, NEPMD_TEST_EANAME)
      if rc then
         sayerror 'Extended attribute could not be retrieved, rc = 'rc'.'
      else
         sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" contains:' EaValue
      endif

   enddo

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryStringEa
; ---------------------------------------------------------------------------
; E syntax:
;    Fullname = NepmdQueryStringEa( Filename, EaName, EaValue)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryStringEa( PSZ pszFilename,
;                                        PSZ pszEaName,
;                                        PSZ pszBuffer,
;                                        ULONG ulBuflen);
; ---------------------------------------------------------------------------

defproc NepmdQueryStringEa( Filename, EaName)

    BufLen  = NEPMD_MAXLEN_ESTRING
    EaValue = copies( \0, BufLen)

    -- Prepare parameters for C routine
    Filename = Filename\0
    EaName   = EaName\0

    -- Call C routine
    LibFile = helperNepmdGetlibfile()
    rc = dynalink32( LibFile,
                     "NepmdQueryStringEa",
                     address( Filename)        ||
                     address( EaName)          ||
                     address( EaValue)         ||
                     atol( Buflen))

    helperNepmdCheckliberror( LibFile, rc)

    if rc then
       return ''
    else
       return makerexxstring( EaValue)
    endif

