/****************************** Module Header *******************************
*
* Module Name: readstringea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: readstringea.e,v 1.4 2002-09-06 10:01:16 cla Exp $
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
@@NepmdReadStringEa@PROTOTYPE
EaValue = NepmdReadStringEa( Filename, EaName);

@@NepmdReadStringEa@CATEGORY@EAS

@@NepmdReadStringEa@SYNTAX
This function reads the specified string extended attribute
from the specified file. Please note that this function can 
only retrieve string EAs properly, retrieving any other type
of extended attributes may lead to unpredictable results.

@@NepmdReadStringEa@PARM@Filename
This parameter specifies the name of the file, from which
the specified REXX EAs is to be read.

@@NepmdReadStringEa@PARM@EaName
This parameter specifies the name of the extended 
attribute to be read.

@@NepmdReadStringEa@RETURNS
NepmdReadStringEa returns either
.ul compact
- the value of the requested extended attribute  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdReadStringEa, ReadStringEa =

 Filename =  arg( 1);
 EaValue = NepmdReadStringEa( Filename, NEPMD_TEST_EANAME);
 parse value EaValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'Extended attribute could not be retrieved, rc='rc;
    return;
 endif

 sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" contains:' EaValue;

/* ------------------------------------------------------------- */
/* procedure: NepmdReadStringEa                                  */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdReadStringEa( Filename, EaName, EaValue);  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdReadStringEa( PSZ pszFilename,          */
/*                                     PSZ pszEaName,            */
/*                                     PSZ pszBuffer,            */
/*                                     ULONG ulBuflen)           */
/* ------------------------------------------------------------- */

defproc NepmdReadStringEa( Filename, EaName ) = 

 BufLen      = NEPMD_MAXLEN_ESTRING;
 TextMessage = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);
 EaName     = EaName''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdReadStringEa",
                  address( Filename)            ||
                  address( EaName)              ||
                  address( TextMessage)         ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( TextMessage);

