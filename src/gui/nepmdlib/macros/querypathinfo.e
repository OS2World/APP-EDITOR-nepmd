/****************************** Module Header *******************************
*
* Module Name: querypathinfo.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
= returns the size of the file
- EASIZE
= returns the size of the extended attributes attached to the file
- ATTR
= returns the file attributes
.el

@@NepmdQueryPathInfo@RETURNS
*NepmdQueryPathInfo* returns either
.ul compact
- the information value  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryPathInfo@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryPathInfo* [.IDPNL_EFUNC_NEPMDQUERYPATHINFO_PARM_PATHNAME pathname]
  - or
- *QueryPathInfo* [.IDPNL_EFUNC_NEPMDQUERYPATHINFO_PARM_PATHNAME pathname]

Executing this command will
open up a virtual file and
write all [.IDPNL_EFUNC_NEPMDQUERYPATHINFO_PARM_VALUETAG supported path info values]
about the specified file or directory into it.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdQueryPathInfo, QueryPathInfo

 PathName = arg( 1);
 if (PathName = '') then
    sayerror 'error: no pathname specified !';
    return;
 endif

 /* create virtual file */
 helperNepmdCreateDumpfile( 'NepmdQueryPathInfo', NepmdQueryFullname( PathName));

 insertline helperNepmdQueryPathInfoValue( PathName, 'ATIME');
 insertline helperNepmdQueryPathInfoValue( PathName, 'MTIME');
 insertline helperNepmdQueryPathInfoValue( PathName, 'CTIME');
 insertline helperNepmdQueryPathInfoValue( PathName, 'SIZE');
 insertline helperNepmdQueryPathInfoValue( PathName, 'EASIZE');
 insertline helperNepmdQueryPathInfoValue( PathName, 'ATTR');
 .modify = 0;

 return;

defproc helperNepmdQueryPathInfoValue( Pathname, ValueTag) =
  return leftstr( ValueTag, 6) ':' NepmdQueryPathInfo( PathName, ValueTag);

compile endif

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
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryPathInfo",
                  address( Pathname)         ||
                  address( ValueTag)         ||
                  address( InfoValue)        ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( InfoValue);

