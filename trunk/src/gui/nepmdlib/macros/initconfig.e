/****************************** Module Header *******************************
*
* Module Name: initconfigvalue.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: initconfig.e,v 1.3 2003-08-30 16:01:01 aschn Exp $
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
rc = NepmdInitConfig( Handle);

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
*NepmdInitConfig* returns an OS/2 error code or zero for no error.

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

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdInitConfig

 rc = NepmdInitConfig( 0);

 if (rc > 0) then
    sayerror 'configuration repository could not be initialized, rc='rc;
    return;
 endif

 sayerror 'config value repository initialized successfully';

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdInitConfig                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdInitConfig( Handle);                             */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdInitConfig( HCONFIG hconfig);           */
/* ------------------------------------------------------------- */

defproc NepmdInitConfig( Handle) =

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdInitConfig",
                  atol( Handle));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

