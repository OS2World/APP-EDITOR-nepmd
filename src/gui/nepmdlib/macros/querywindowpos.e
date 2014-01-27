/****************************** Module Header *******************************
*
* Module Name: querywindowpos.e
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
@@NepmdQueryWindowPos@PROTOTYPE
WindowPos = NepmdQueryWindowPos( WindowId)

@@NepmdQueryWindowPos@CATEGORY@EPMWINDOW

@@NepmdQueryWindowPos@SYNTAX
This function queries the window position of the EPM
window or one its controls.

@@NepmdQueryWindowPos@PARM@WindowId
This parameter specifies one of the following values
defined in *stdconst.e*:
.ul compact
- EPMINFO__OWNERCLIENT - 1
- EPMINFO__OWNERFRAME - 2
- EPMINFO__PARENTCLIENT - 3
- EPMINFO__PARENTFRAME - 4
- EPMINFO__EDITCLIENT - 5
- EPMINFO__EDITFRAME - 6
- EPMINFO__EDITORVSCROLL - 9
- EPMINFO__EDITORHSCROLL - 10
- EPMINFO__EDITMENUHWND - 17

It is recommended to include *stdconst.e* and use the constant names
instead of using the numeric values.

@@NepmdQueryWindowPos@RETURNS
*NepmdQueryWindowPos* returns the window position in pixels as a string
like *x y cx cy*. In case of an error an empty string is returned.

This procedure sets the implicit universal var rc. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdQueryWindowPos@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryWindowPos*
  [[ [.IDPNL_EFUNC_NEPMDQUERYWINDOWPOS_PARM_WINDOWID windowid] ]]
  - or
- *QueryWindowPos*
  [[ [.IDPNL_EFUNC_NEPMDQUERYWINDOWPOS_PARM_WINDOWID windowid] ]]

Executing this command will
query the window position of the specified *EPM* window or control window
(*EPM* frame window, if no id specified)
and display the result within the status area.

*Example:*
.fo off
  QueryWindowPos
  QueryWindowPos 5
.fo on

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdQueryWindowPos, QueryWindowPos

   WindowId = arg( 1)
   if (WindowId = '') then
      WindowId = EPMINFO_EDITCLIENT
   endif

   WindowPos = NepmdQueryWindowPos( WindowId)

   if rc then
      sayerror 'Window pos of window with id' WindowId 'cannot be determined, rc = 'rc'.'
   else
      sayerror 'Window pos of window with id' WindowId 'is:' WindowPos
   endif

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdQueryWindowPos
; ---------------------------------------------------------------------------
; E syntax:
;    WindowPos = NepmdQueryWindowPos( WindowId)
;
;    WindowId is one of the EPMINFO_* values of stdconst.e.
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdQueryWindowPos( HWND hwnd,
;                                         PSZ pszBuffer,
;                                         ULONG ulBuflen);
; ---------------------------------------------------------------------------

defproc NepmdQueryWindowPos( WindowId)

   BufLen    = 260
   WindowPos = copies( \0, BufLen)

   -- Check for valid IDs
   ValidIds = '1 2 3 4 5 6 9 10 17'
   if (wordpos( WindowId, ValidIds) = 0) then
      rc = 87
      return ''
   endif

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdQueryWindowPos",
                    gethwndc( WindowId)         ||
                    address( WindowPos)         ||
                    atol( Buflen))

   helperNepmdCheckliberror( LibFile, rc)

   if rc then
      return ''
   else
      return makerexxstring( WindowPos)
   endif

