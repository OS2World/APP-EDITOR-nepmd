/****************************** Module Header *******************************
*
* Module Name: openconfig.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: openconfig.e,v 1.1 2002-09-13 21:55:05 cla Exp $
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
@@NepmdOpenConfig@PROTOTYPE
Handle = NepmdOpenConfig();

@@NepmdOpenConfig@CATEGORY@CONFIG

@@NepmdOpenConfig@SYNTAX
This function opens the configuration repository of the [=TITLE]
installation.

@@NepmdOpenConfig@REMARKS
If you want to perform only only a single operation on the
configuration repository, it is recommended to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open] the configuration
repository.

If multiple operations are to be processed in a row,
[.IDPNL_REGISTRY_EXPLICITOPEN explicitely opening and closing]
the repository before and after the access will save you from
additional disk I/O.

@@NepmdOpenConfig@RETURNS
*NepmdOpenConfig* returns either
.ul compact
- the handle to the opened configuration repository  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/* procedure: NepmdOpenConfig                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle = NepmdOpenConfig( );                               */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdOpenConfig( PSZ pszBuffer,              */
/*                                   ULONG ulBuflen)             */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdOpenConfig( ) =

 BufLen = 20;
 Handle = copies( atoi( 0), BufLen);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdOpenConfig",
                  address( Handle)     ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( Handle);

