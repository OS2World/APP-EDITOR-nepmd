/****************************** Module Header *******************************
*
* Module Name: info.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: info.e,v 1.4 2002-08-25 18:15:13 cla Exp $
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

@@NepmdInfo@SYNTAX
This function creates a virtual file named *.NEPMD__INFO*
and writes runtime information about
.ul compact
- the *NEPMD* modules loaded and config files used
- the loaded *EPM* modules

@@NepmdInfo@RETURNS
NepmdInfo returns an OS/2 error code.

@@NepmdInfo@REMARKS
Note that any existing file in the ring named *.NEPMD__INFO*
is dscarded before the current file is being created.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdInfo =

 rc = NepmdInfo();

/* ------------------------------------------------------------- */
/* procedure: NepmdInfo                                          */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdInfo();                                          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdInfo( HWND hwndClient);                 */
/* ------------------------------------------------------------- */

defproc NepmdInfo =

 /* discard previously loaded info file from ring */
 getfileid startfid;
 MaxFiles = filesinring( 3);
 do i = 1 to MaxFiles
    if (.filename = '.NEPMD_INFO') then
       .modify = 0;
       'QUIT'
    endif;
    next_file;
 enddo;
 activatefile startfid;

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdInfo",
                  gethwndc( EPMINFO_EDITCLIENT));

 checkliberror( LibFile, rc);

 /* make id discardable */
 .modify = 0;

 return rc;

