/****************************** Module Header *******************************
*
* Module Name: writestringea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: writestringea.e,v 1.5 2002-08-25 19:58:17 cla Exp $
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
@@NepmdWriteStringEa@PROTOTYPE
EaValue = NepmdWriteStringEa( Filename, EaName, EaValue);

@@NepmdWriteStringEa@SYNTAX
This function writes the specified string as value for the specified
extended attribute to the specified file.

@@NepmdWriteStringEa@PARM@Filename
This parameter specifies the name of the file, to which
the specified REXX EAs is to be written.

@@NepmdWriteStringEa@PARM@EaName
This parameter specifies the name of the extended 
attribute to be written.

@@NepmdWriteStringEa@PARM@EaValue
This parameter specifies the string to be written as
the value of the specified extended attribute.

@@NepmdWriteStringEa@RETURNS
NepmdWriteStringEa returns an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdWriteStringEa, WriteStringEa =

 Filename =  arg( 1);
 rc = NepmdWriteStringEa( Filename, NEPMD_TEST_EANAME, NEPMD_TEST_EAVALUE);
 if (rc > 0) then
    sayerror 'Extended attribute not written, rc='rc;
    return;
 endif

 sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" written to:' Filename;

/* ------------------------------------------------------------- */
/* procedure: NepmdWriteStringEa                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdWriteStringEa( Filename, EaName, EaValue); */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdWriteStringEa( PSZ pszFilename,         */
/*                                      PSZ pszEaName,           */
/*                                      PSZ pszEaValue)          */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdWriteStringEa( Filename, EaName, EaValue) =

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);
 EaName     = EaName''atoi( 0);
 EaValue    = EaValue''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdWriteStringEa",
                  address( Filename)            ||
                  address( EaName)              ||
                  address( EaValue));

 checkliberror( LibFile, rc);

 return rc;

