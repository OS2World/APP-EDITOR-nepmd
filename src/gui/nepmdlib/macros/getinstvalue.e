/****************************** Module Header *******************************
*
* Module Name: getinstfilename.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getinstvalue.e,v 1.1 2002-08-22 15:48:45 cla Exp $
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

defc NepmdGetInstValue, GetInstValue

  if (arg( 1) = '') then
     sayerror 'error: no value tag specified !';
  else
     sayerror 'value for "'arg( 1)'" is:' NepmdGetInstValue( arg( 1));
  endif

/* ------------------------------------------------------------- */
/* procedure: NepmdGetInstValue                                  */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    InstValue = NepmdGetInstValue( ValueTag);                  */
/*                                                               */
/*  See valig tags in src\gui\common\nepmd.h : NEPMD_VALUETAG_*  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetInstValue( PSZ pszTagName,           */
/*                                     PSZ pszBuffer,            */
/*                                     ULONG ulBuflen)           */
/* ------------------------------------------------------------- */

defproc NepmdGetInstValue( ValueTag) =

 BufLen    = 260;
 InstValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 ValueTag = ValueTag''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetInstValue",
                  address( ValueTag)          ||
                  address( InstValue)         ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( InstValue);

