/****************************** Module Header *******************************
*
* Module Name: libversion.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libversion.e,v 1.10 2003-08-30 16:01:01 aschn Exp $
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
Version = NepmdLibVersion();

@@NepmdLibVersion@CATEGORY@INSTALL

@@NepmdLibVersion@SYNTAX
This function queries the version of the installed runtime library
of the [=TITLE].

@@NepmdLibVersion@RETURNS
*NepmdLibVersion* returns the version number of the runtime library
of the [=TITLE].

@@NepmdLibVersion@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdLibVersion*

Executing this command will
display the version number of the runtime library of the [=TITLE]
within the status area.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
; We want this command also if included in EPM.E to call it from
; the command line or from an menu item.

defc NepmdLibVersion =

 sayerror 'NEPMDLIB Version' NepmdLibVersion();

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdLibVersion                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Version = NepmdLibVersion();                               */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdLibVersion( PSZ pszBuffer,              */
/*                                   ULONG ulBuflen)             */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdLibVersion() =

 BufLen     = 20;
 LibVersion = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Token    = Token''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdLibVersion",
                  address( LibVersion) ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( LibVersion);
