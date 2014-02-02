/****************************** Module Header *******************************
*
* Module Name: querymodelist.e
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
@@NepmdQueryModeList@PROTOTYPE
ModeList = NepmdQueryModeList()

@@NepmdQueryModeList@CATEGORY@MODE

@@NepmdQueryModeList@SYNTAX
This function determines the list of available *EPM* modes.

@@NepmdQueryModeList@RETURNS
*NepmdQueryModeList* returns the space-separated list of available *EPM*
modes. In case of an error an empty string is returned.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdQueryModeList@TESTCASE
You can test this function from the *EPM* commandline by executing:
.sl
- *NepmdQueryModeList*
  - or
- *QueryModeList*

Executing this command will display the list of all available *EPM* modes
in the statusline.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdQueryModeList, QueryModeList

   ModeList = NepmdQueryModeList()
   if rc then
      sayerror 'list of EPM modes could not be determined, rc = 'rc'.'
   else
      sayerror 'EPM modes:' ModeList
   endif

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryModeList
; ---------------------------------------------------------------------------
; E syntax:
;    ModeList = NepmdQueryModeList()
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryModeList( PSZ pszBuffer,
;                                        ULONG ulBuflen);
; ---------------------------------------------------------------------------

compile if not defined( NEPMD_MAXLEN_ESTRING) then
   include 'STDCONST.E'
compile endif

defproc NepmdQueryModeList()

   BufLen   = NEPMD_MAXLEN_ESTRING
   ModeList = copies( \0, BufLen)

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdQueryModeList",
                    address( ModeList) ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( ModeList)
   endif

