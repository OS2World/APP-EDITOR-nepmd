/****************************** Module Header *******************************
*
* Module Name: queryprocessinfo.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: queryprocessinfo.e,v 1.4 2002-09-06 14:36:29 cla Exp $
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
@@NepmdQueryProcessInfo@PROTOTYPE
InfoValue = NepmdQueryProcessInfo( ValueTag);

@@NepmdQueryProcessInfo@CATEGORY@PROCESS

@@NepmdQueryProcessInfo@SYNTAX
This function queries values related to the current EPM process.

@@NepmdQueryProcessInfo@PARM@ValueTag
This parameter specifies a keyword determining the
process information value to be returned.

The following keywords are supported:
.pl bold
- PID
= returns the process ID of the current process
- PPID
= returns the process ID of the parent of the current process
- PROGRAM
= returns the full pathname of the process executable (so of *EPM*)
- PARMS
= returns the commandline parameters for the current process

@@NepmdQueryProcessInfo@RETURNS
NepmdQueryProcessInfo returns either
.ul compact
- the information value  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

defc NepmdQueryProcessInfo, QueryProcessInfo

 helperNepmdCreateDumpfile( 'NepmdQueryProcessInfo', '');
 insertline helperNepmdQueryProcessInfoValue( 'PID');
 insertline helperNepmdQueryProcessInfoValue( 'PPID');
 insertline helperNepmdQueryProcessInfoValue( 'PROGRAM');
 insertline helperNepmdQueryProcessInfoValue( 'PARMS');

 .modify = 0;

defproc helperNepmdQueryProcessInfoValue( ValueTag) =
  return leftstr( ValueTag, 15) ':' NepmdQueryProcessInfo( ValueTag);

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryProcessInfo                              */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    InfoValue = NepmdQueryProcessInfo( ValueTag);              */
/*                                                               */
/*  See valig tags in src\gui\nepmdlib\nepmdlib.h:               */
/*      NEPMD_PROCESSINFO_*                                      */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryProcessInfo( PSZ pszInfoTag,       */
/*                                         PSZ pszBuffer,        */
/*                                         ULONG ulBuflen)       */
/* ------------------------------------------------------------- */

defproc NepmdQueryProcessInfo( ValueTag) =

 BufLen    = 260;
 InfoValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 ValueTag  = ValueTag''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryProcessInfo",
                  address( ValueTag)         ||
                  address( InfoValue)        ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( InfoValue);

