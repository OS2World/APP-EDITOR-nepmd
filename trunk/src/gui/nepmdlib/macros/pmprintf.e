/****************************** Module Header *******************************
*
* Module Name: pmprintf.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: pmprintf.e,v 1.2 2003-08-30 16:01:01 aschn Exp $
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
compile if NEPMD_LIB_TEST

defc NepmdPmPrintf, PmPrintf =

 Text = arg( 1);
 if (Text = '') then
    sayerror 'error: no text specified.';
    return;
 endif

 call NepmdPmPrintf( Text);

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdPmPrintf                                      */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdPmPrintf( Text);                                 */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdPmPrintf( PSZ pszText);                 */
/* ------------------------------------------------------------- */

defproc NepmdPmPrintf( Text) =

 /* prepare parameters for C routine */
 Text = Text''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdPmPrintf",
                  address( Text));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

