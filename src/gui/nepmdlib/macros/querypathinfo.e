/****************************** Module Header *******************************
*
* Module Name: querypathinfo.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: querypathinfo.e,v 1.2 2002-09-04 10:16:22 cla Exp $
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
InstValue = NepmdQueryPathInfo( Pathname, ValueTag);

@@NepmdQueryPathInfo@CATEGORY@FILE

@@NepmdQueryPathInfo@SYNTAX
This function queries installation related values
from the [=TITLE].

@@NepmdQueryPathInfo@PARM@Pathname
This parameter specifies the pathname of the file or directory, of
which a path information value is requested.

@@NepmdQueryPathInfo@PARM@InfoTag
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

 parse value arg( 1) with Filename InfoTag;

 if (InfoTag = '') then
    sayerror 'error: no info tag specified !';
    return;
 endif

 InstValue = NepmdQueryPathInfo( Filename, InfoTag);
 parse value InstValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'error: could not retrieve value for "'InfoTag'", rc='rc;
    return;
 endif

 sayerror 'value for "'InfoTag'" of "'Filename'" is: "'InstValue'"';

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryPathInfo                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    InfoValue = NepmdQueryPathInfo( PathName, InfoTag);        */
/*                                                               */
/*  See valig tags in src\gui\common\nepmd.h : NEPMD_PATHINFO_*  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryPathInfo( PSZ pszPathname,         */
/*                                      PSZ pszTagName,          */
/*                                      PSZ pszBuffer,           */
/*                                      ULONG ulBuflen)          */
/* ------------------------------------------------------------- */

defproc NepmdQueryPathInfo( Pathname, InfoTag) =

 BufLen    = 260;
 InfoValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Pathname = Pathname''atoi( 0);
 InfoTag  = InfoTag''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryPathInfo",
                  address( Pathname)         ||
                  address( InfoTag)          ||
                  address( InfoValue)        ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( InfoValue);

