/****************************** Module Header *******************************
*
* Module Name: queryfullname.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libinfo.e,v 1.1 2002-08-20 12:07:13 cla Exp $
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

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdVersion =

  sayerror 'NEPMDLIB Version' NepmdLibInfo( 'VERSION');

/* ------------------------------------------------------------- */
/* procedure: NepmdLibInfo                                       */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    data = NepmdLibInfo( '<token>');                           */
/*                                                               */
/*  Valid tokens are:                                            */
/*     'VERSION'  - returns version number ('1.23')              */
/*     'COMPILED' - returns compiledate ('dd mmm yyyy')          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdLibInfo( PSZ pszFilename,               */
/*                                PSZ pszBuffer,                 */
/*                                PSZ pszBuflen)                 */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdLibInfo( Token) =

 BufLen   = 260;
 LibInfo  = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Token    = Token''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdLibInfo",
                  address( Token)   ||
                  address( LibInfo) ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return LibInfo;

