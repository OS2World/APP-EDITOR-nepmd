/****************************** Module Header *******************************
*
* Module Name: errormsgbox.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: errormsgbox.e,v 1.2 2002-08-20 14:55:54 cla Exp $
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

defc NepmdErrorMsgBox, ErrorMsgBox =

  rcx = NepmdErrorMsgBox( arg( 1), 'Netlabs EPM Distribution');

/* ------------------------------------------------------------- */
/* procedure: NepmdErrorMsgBox                                   */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = ErrorMsgBox( message, title);                         */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdErrorMsgBox( HWND hwndClient,           */
/*                                    PSZ pszMessage,            */
/*                                    PSZ pszTitle)              */
/* ------------------------------------------------------------- */

defproc NepmdErrorMsgBox( BoxMessage, Boxtitle) =

 /* prepare parameters for C routine */
 BoxMessage = BoxMessage''atoi( 0);
 BoxTitle   = Boxtitle''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdErrorMsgBox",
                  gethwndc( EPMINFO_EDITCLIENT) ||
                  address( BoxMessage)          ||
                  address( BoxTitle));

 checkliberror( LibFile, rc);

 return rc;

