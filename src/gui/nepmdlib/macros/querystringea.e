/****************************** Module Header *******************************
*
* Module Name: querystringea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: querystringea.e,v 1.1 2002-09-19 11:31:30 cla Exp $
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
@@NepmdQueryStringEa@PROTOTYPE
EaValue = NepmdQueryStringEa( Filename, EaName);

@@NepmdQueryStringEa@CATEGORY@EAS

@@NepmdQueryStringEa@SYNTAX
This function reads the specified string extended attribute
from the specified file. Please note that this function can
only retrieve string EAs properly, retrieving any other type
of extended attributes may lead to unpredictable results.

@@NepmdQueryStringEa@PARM@Filename
This parameter specifies the name of the file, from which
the specified REXX EAs is to be read.

@@NepmdQueryStringEa@PARM@EaName
This parameter specifies the name of the extended
attribute to be read.

@@NepmdQueryStringEa@RETURNS
*NepmdQueryStringEa* returns either
.ul compact
- the value of the requested extended attribute  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryStringEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryStringEa*
   [.IDPNL_EFUNC_NEPMDQUERYSTRINGEA_PARM_FILENAME filename]
  - or
- *QueryStringEa*
   [.IDPNL_EFUNC_NEPMDQUERYSTRINGEA_PARM_FILENAME filename]


Executing this command will
read the extended string attribute with the name
.sl compact
- *NEPMD.__TestStringEa*
.el
from the specified file
and display the result within the status area.

_*Example:*_
.fo off
  QueryStringEa d:\myscript.txt
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryStringEa, QueryStringEa =

 Filename =  arg( 1);
 EaValue = NepmdQueryStringEa( Filename, NEPMD_TEST_EANAME);
 parse value EaValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'Extended attribute could not be retrieved, rc='rc;
    return;
 endif

 sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" contains:' EaValue;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryStringEa                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdQueryStringEa( Filename, EaName, EaValue); */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryStringEa( PSZ pszFilename,         */
/*                                     PSZ pszEaName,            */
/*                                     PSZ pszBuffer,            */
/*                                     ULONG ulBuflen)           */
/* ------------------------------------------------------------- */

defproc NepmdQueryStringEa( Filename, EaName ) =

 BufLen      = NEPMD_MAXLEN_ESTRING;
 TextMessage = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);
 EaName     = EaName''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryStringEa",
                  address( Filename)            ||
                  address( EaName)              ||
                  address( TextMessage)         ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( TextMessage);

