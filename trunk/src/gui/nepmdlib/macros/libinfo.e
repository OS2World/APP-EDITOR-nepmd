/****************************** Module Header *******************************
*
* Module Name: libinfo.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libinfo.e,v 1.3 2002-08-23 15:35:00 cla Exp $
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

defc NepmdLibInfo =

 rc = NepmdLibInfo();

/* ------------------------------------------------------------- */
/* procedure: NepmdLibInfo                                       */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdLibInfo();                                       */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdLibInfo( HWND hwndClient);              */
/* ------------------------------------------------------------- */

defproc NepmdLibInfo =

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdLibInfo",
                  gethwndc( EPMINFO_EDITCLIENT));

 checkliberror( LibFile, rc);

 return rc;

