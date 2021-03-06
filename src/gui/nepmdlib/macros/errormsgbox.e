/****************************** Module Header *******************************
*
* Module Name: errormsgbox.e
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
@@NepmdErrorMsgBox@PROTOTYPE
NepmdErrorMsgBox( BoxMessage, BoxTitle)

@@NepmdErrorMsgBox@CATEGORY@INTERACT

@@NepmdErrorMsgBox@SYNTAX
This function pops up an error messagebox.

@@NepmdErrorMsgBox@PARM@BoxMessage
This parameter specifies the message to be
displayed in the message box.

@@NepmdErrorMsgBox@PARM@BoxTitle
This parameter specifies the title to be
displayed in the message box.

@@NepmdErrorMsgBox@RETURNS
*NepmdErrorMsgBox* returns nothing.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdErrorMsgBox@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdErrorMsgBox*
  [.IDPNL_EFUNC_NEPMDERRORMSGBOX_PARM_BOXMESSAGE message]
  - or
- *ErrorMsgBox*
  [.IDPNL_EFUNC_NEPMDERRORMSGBOX_PARM_BOXMESSAGE message]

Executing this command will
open up a message box with the title [=TITLE] and the
specified message text.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdErrorMsgBox, ErrorMsgBox

   ErrorText = arg( 1)
   if (ErrorText = '') then
      ErrorText = 'This is an error message box.'
   endif

   call NepmdErrorMsgBox( ErrorText, 'Netlabs EPM Distribution')

compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdErrorMsgBox
; ---------------------------------------------------------------------------
; E syntax:
;    NepmdErrorMsgBox( BoxMessage, BoxTitle)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdErrorMsgBox( HWND hwndClient,
;                                      PSZ pszMessage,
;                                      PSZ pszTitle);
; ---------------------------------------------------------------------------

defproc NepmdErrorMsgBox( BoxMessage, BoxTitle)

   -- Prepare parameters for C routine
   BoxMessage = BoxMessage\0
   BoxTitle   = Boxtitle\0

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdErrorMsgBox",
                    gethwndc( EPMINFO_EDITCLIENT) ||
                    address( BoxMessage)          ||
                    address( BoxTitle))

   helperNepmdCheckliberror( LibFile, rc)

   return

