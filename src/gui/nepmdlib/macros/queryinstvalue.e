/****************************** Module Header *******************************
*
* Module Name: queryinstvalue.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: queryinstvalue.e,v 1.1 2002-09-05 16:41:02 cla Exp $
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
@@NepmdQueryInstValue@PROTOTYPE
InstValue = NepmdQueryInstValue( ValueTag);

@@NepmdQueryInstValue@CATEGORY@CONFIG

@@NepmdQueryInstValue@SYNTAX
This function queries installation related values
from the [=TITLE].

@@NepmdQueryInstValue@PARM@ValueTag
This parameter specifies a keyword determining the
installation value to be returned.

If the installation directory cannot be determined, pathnames
of course cannot point to a subdirectory of the NEPMD directory
tree, but rather specify filenames from within the directory where
the calling executable is called from - this way all values
except for *ROOT* can be used even if not the complete [=TITLE]
is installed.

The following keywords are supported:
.pl bold
- ROOTDIR
= returns the installation directory of the [=TITLE]. If the
  installation directory cannot be determined, an error is returned.
- LANGUAGE
= returns the language selected by the installation of the [=TITLE].
.
  If the installation directory cannot be determined, *eng* for the
  english language is returned.
- INIT
= returns the fully qualified pathname of the initialization file of
  the [=TITLE].
- MESSAGE
= returns the fully qualified pathname of the message file of
  the [=TITLE].

@@NepmdQueryInstValue@RETURNS
NepmdQueryInstValue returns either
.ul compact
- the installation value  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryInstValue, QueryInstValue

 'xcom e /c .TEST_NEPMDQUERYINSTVALUE';
 insertline '';
 insertline 'NepmdQueryInstValue';
 insertline '-------------------';
 insertline '';
 insertline helperNepmdQueryInstValue( 'ROOTDIR');
 insertline helperNepmdQueryInstValue( 'LANGUAGE');
 insertline helperNepmdQueryInstValue( 'INIT');
 insertline helperNepmdQueryInstValue( 'MESSAGE');

 .modify = 0;

defproc helperNepmdQueryInstValue( ValueTag) =
  return leftstr( ValueTag, 8) ':' NepmdQueryInstValue( ValueTag);

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryInstValue                                */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    InstValue = NepmdQueryInstValue( ValueTag);                */
/*                                                               */
/*  See valig tags in src\gui\common\nepmd.h : NEPMD_INSTVALUE_* */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryInstValue( PSZ pszTagName,         */
/*                                       PSZ pszBuffer,          */
/*                                       ULONG ulBuflen)         */
/* ------------------------------------------------------------- */

defproc NepmdQueryInstValue( ValueTag) =

 BufLen    = 260;
 InstValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 ValueTag = ValueTag''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryInstValue",
                  address( ValueTag)          ||
                  address( InstValue)         ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( InstValue);

