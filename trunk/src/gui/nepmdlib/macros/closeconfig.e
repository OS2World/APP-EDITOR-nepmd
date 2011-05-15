/****************************** Module Header *******************************
*
* Module Name: closeconfig.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
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
@@NepmdCloseConfig@PROTOTYPE
rc = NepmdCloseConfig( Handle);

@@NepmdCloseConfig@CATEGORY@CONFIG

@@NepmdCloseConfig@SYNTAX
This function closes a handle to the configuration repository
of the [=TITLE] installation previously opened by a call to
[.IDPNL_EFUNC_NEPMDOPENCONFIG].

@@NepmdCloseConfig@PARM@Handle
This parameter specifies the handle to be closed. It
must have been returned by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

@@NepmdCloseConfig@RETURNS
*NepmdCloseConfig* returns an OS/2 error code or zero for no error.

@@NepmdCloseConfig@REMARKS
If you want to perform only only a single operation on the
configuration repository, it is recommended to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open] the configuration
repository.

If multiple operations are to be processed in a row,
[.IDPNL_REGISTRY_EXPLICITOPEN explicitely opening and closing]
the repository before and after the access will save you from
additional disk I/O.

@@NepmdCloseConfig@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdCloseConfig*
  - or
- *CloseConfig*

This is identical to the testcase of the [.IDPNL_EFUNC_NEPMDOPENCONFIG] API.


Executing this command will a execute a testcase, which performs
the access to the configuration repository of the [=TITLE]
[.IDPNL_REGISTRY_EXPLICITOPEN explicitely opening and closing]
the repository before / after accessing it.

The testcase performs the following calls
.ul compact
- [.IDPNL_EFUNC_NEPMDOPENCONFIG],
- [.IDPNL_EFUNC_NEPMDWRITECONFIGVALUE],
- [.IDPNL_EFUNC_NEPMDQUERYCONFIGVALUE],
- [.IDPNL_EFUNC_NEPMDDELETECONFIGVALUE] and
- [.IDPNL_EFUNC_NEPMDCLOSECONFIG],
.el
and opens up a virtual file, writing the testcase result into it.

If an error occurrs, the error message will be displayed
result within the status area.

@@
*/
/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdCloseConfig, CloseConfig =
 'NepmdOpenConfig'

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdCloseConfig                                   */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdCloseConfig( Handle);                            */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdCloseConfig( HCONFIG hconfig);          */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdCloseConfig( Handle) =

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdCloseConfig",
                  atol( Handle));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

