/****************************** Module Header *******************************
*
* Module Name: queryfullname.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: queryfullname.e,v 1.6 2002-08-23 15:35:00 cla Exp $
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

defc NepmdQueryFullname, QueryFullname =

 Filename = arg( 1);
 Fullname = NepmdQueryFullname( Filename);

 parse value Fullname with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'fullname of "'Filename'" could not be retrieved, rc='rc;
    return
 endif

 sayerror 'fullname of "'Filename'" is:' Fullname;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryFullname                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdQueryFullname( filename);                  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryFullname( PSZ pszFilename,         */
/*                                      PSZ pszBuffer,           */
/*                                      ULONG ulBuflen)          */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdQueryFullname( Filename) =

 BufLen   = 260;
 FullName = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryFullname",
                  address( Filename)            ||
                  address( Fullname)            ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( FullName);

