/****************************** Module Header *******************************
*
* Module Name: querypathinfo.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: querypathinfo.e,v 1.4 2002-09-04 15:38:22 cla Exp $
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
@@NepmdQueryPathInfo@PROTOTYPE
InfoValue = NepmdQueryPathInfo( Pathname, ValueTag);

@@NepmdQueryPathInfo@CATEGORY@FILE

@@NepmdQueryPathInfo@SYNTAX
This function queries installation related values
from the [=TITLE].

@@NepmdQueryPathInfo@PARM@Pathname
This parameter specifies the pathname of the file or directory, of
which a path information value is requested.

@@NepmdQueryPathInfo@PARM@ValueTag
This parameter specifies a keyword determining the
path information value to be returned.

The following keywords are supported:
.pl bold
- ATIME
= returns the last access time
- MTIME
= returns the last modification time
- CTIME
= returns the creation time
- SIZE
= returns the filesize
- ATTR
= returns the file attributes

@@NepmdQueryPathInfo@RETURNS
NepmdQueryPathInfo returns either
.ul compact
- the information value  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

defc NepmdQueryPathInfo, QueryPathInfo

 parse value arg( 1) with PathName ValueTag;

 if (ValueTag = '') then
    sayerror 'error: no value tag specified !';
    return;
 endif

 InfoValue = NepmdQueryPathInfo( PathName, ValueTag);
 parse value InfoValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'error: could not retrieve value for "'ValueTag'", rc='rc;
    return;
 endif

 sayerror 'value for "'ValueTag'" of "'PathName'" is: "'InfoValue'"';

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryPathInfo                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    InfoValue = NepmdQueryPathInfo( PathName, ValueTag);       */
/*                                                               */
/*  See valig tags in src\gui\nepmdlib\nepmdlib.h:               */
/*      NEPMD_PATHINFO_*                                         */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryPathInfo( PSZ pszPathname,         */
/*                                      PSZ pszInfoTag,          */
/*                                      PSZ pszBuffer,           */
/*                                      ULONG ulBuflen)          */
/* ------------------------------------------------------------- */

defproc NepmdQueryPathInfo( Pathname, ValueTag) =

 BufLen    = 260;
 InfoValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Pathname = Pathname''atoi( 0);
 ValueTag  = ValueTag''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryPathInfo",
                  address( Pathname)         ||
                  address( ValueTag)         ||
                  address( InfoValue)        ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( InfoValue);

