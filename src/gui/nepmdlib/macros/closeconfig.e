/****************************** Module Header *******************************
*
* Module Name: closeconfig.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: closeconfig.e,v 1.1 2002-09-13 21:55:05 cla Exp $
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

@@
*/

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

