/****************************** Module Header *******************************
*
* Module Name: querywindowpos.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: querywindowpos.e,v 1.1 2002-09-05 16:08:55 cla Exp $
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
@@NepmdQueryWindowPos@PROTOTYPE
WindowPos = NepmdQueryWindowPos( WindowId);

@@NepmdQueryWindowPos@CATEGORY@EPMWINDOW

@@NepmdQueryWindowPos@SYNTAX
This function queries the window position of the EPM
window or one its controls.

@@NepmdQueryWindowPos@PARM@WindowId
This parameter specifies one of the following values
defined in *stdconst.e*:
.ul compact
- EPMINFO__OWNERCLIENT
- EPMINFO__OWNERFRAME
- EPMINFO__PARENTCLIENT
- EPMINFO__PARENTFRAME
- EPMINFO__EDITCLIENT
- EPMINFO__EDITFRAME
- EPMINFO__EDITORVSCROLL
- EPMINFO__EDITORHSCROLL
- EPMINFO__EDITMENUHWND

[=NOTE]
.ul compact
- Do not specify other values than these, otherwise the internal function
  gethwndc() may generate an error message with sayerror

@@NepmdQueryWindowPos@RETURNS
NepmdQueryWindowPos returns either
.ul compact
- the windowposition in pixels as a string like *x y cx cy*  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryWindowPos, QueryWindowPos

 WindowId = arg( 1);
 if (WindowId = '') then
    WindowId = EPMINFO_EDITCLIENT;
 endif

 WindowPos = NepmdQueryWindowPos( WindowId);

 parse value WindowPos with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'window pos of window with id' WindowId 'cannot be determined, rc='rc;
    return
 endif

 sayerror 'window pos of window with id' WindowId 'is:' WindowPos;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryWindowPos                                */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    WindowPos = NepmdQueryWindowPos( WindowId);                */
/*                                                               */
/*   windowId is one of the EPMINFO_* values of stdconst.e       */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryWindowPos( HWND hwnd,              */
/*                                       PSZ pszBuffer,          */
/*                                       ULONG ulBuflen)         */
/* ------------------------------------------------------------- */

defproc NepmdQueryWindowPos( WindowId) =

 BufLen    = 260;
 WindowPos = copies( atoi( 0), BufLen);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryWindowPos",
                  gethwndc( WindowId)         ||
                  address( WindowPos)         ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( WindowPos);

