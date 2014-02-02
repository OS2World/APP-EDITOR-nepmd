/****************************** Module Header *******************************
*
* Module Name: initconfigvalue.e
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
@@NepmdInitConfig@PROTOTYPE
NepmdInitConfig( Handle)

@@NepmdInitConfig@CATEGORY@CONFIG

@@NepmdInitConfig@SYNTAX
This function initializes the configuration repository of the
[=TITLE] installation, if that has not happened yet.

@@NepmdInitConfig@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdInitConfig@RETURNS
*NepmdInitConfig* returns nothing.

This procedure sets the implicit universal var *rc*. rc is set to an
[inf:cp2 "Errors" OS/2 error code] or to zero for no error.

@@NepmdInitConfig@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdInitConfig*
  - or
- *InitConfig*


Executing this command will initialize the configuration repository
of the [=TITLE] installation, if that has not happened yet,
and display the result within the status area.

@@
*/

; ---------------------------------------------------------------------------
; Allow editor command to call function
; ---------------------------------------------------------------------------
compile if NEPMD_LIB_TEST

defc NepmdInitConfig

   call NepmdInitConfig( 0)

   if rc then
      sayerror 'Configuration repository could not be initialized, rc = 'rc'.'
   else
      sayerror 'Configuration repository initialized successfully.'
   endif


compile endif

; ---------------------------------------------------------------------------
; Procedure: NepmdInitConfig
; ---------------------------------------------------------------------------
; E syntax:
;    NepmdInitConfig( Handle)
; ---------------------------------------------------------------------------
; C prototype:
;    APIRET EXPENTRY NepmdInitConfig( HCONFIG hconfig);
; ---------------------------------------------------------------------------

defproc NepmdInitConfig( Handle)

   -- Use zero as handle if none specified
   if (strip( Handle) = '') then
      Handle = 0
   endif

   -- Call C routine
   LibFile = helperNepmdGetlibfile()
   rc = dynalink32( LibFile,
                    "NepmdInitConfig",
                    atol( Handle))

   helperNepmdCheckliberror( LibFile, rc)

   return

