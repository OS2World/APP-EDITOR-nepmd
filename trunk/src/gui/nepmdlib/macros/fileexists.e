/****************************** Module Header *******************************
*
* Module Name: fileexists.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: fileexists.e,v 1.7 2002-09-19 11:43:50 cla Exp $
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
@@NepmdFileExists@PROTOTYPE
fResult = NepmdFileExists( Filename);

@@NepmdFileExists@CATEGORY@FILE

@@NepmdFileExists@SYNTAX
This function queries wether a file exists

@@NepmdFileExists@PARM@Filename
This parameter specifies the name of the file to be checked.

@@NepmdFileExists@RETURNS
*NepmdFileExists* returns either
.ul compact
- *0* (zero), if the file does not exist  or
- *1* , if the file exists

@@NepmdFileExists@REMARKS
*NepmdFileExists* replaces the function *Exist* of *dosutil.e*.

For downwards compatibility the old function is still provided,
but calls *NepmdFileExists*.

@@NepmdFileExists@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdFileExists* [.IDPNL_EFUNC_NEPMDFILEEXISTS_PARM_FILENAME filename]
  - or
- *FileExists* [.IDPNL_EFUNC_NEPMDFILEEXISTS_PARM_FILENAME filename]

Executing this command will
check, wether the specified file exists or not,
and display the result within the status area.

_*Example:*_
.fo off
  FileExists c:\os2\cmd.exe
.fo on

@@
*/


/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdFileExists, FileExists =

 Filename = arg( 1);
 if (Filename = '') then
    sayerror 'error: no filename specified.';
    return;
 endif

 fResult = NepmdFileExists( Filename);
 if (fResult) then
    StrResult = 'does';
 else
    StrResult = 'does not';
 endif

 sayerror 'file "'Filename'"' StrResult 'exist';

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdFileExists                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    fResult = NepmdFileExists( filename);                      */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  BOOL EXPENTRY NepmdFileExists( PSZ pszFilename);             */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdFileExists( Filename) =

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 fResult = dynalink32( LibFile,
                       "NepmdFileExists",
                        address( Filename));

 helperNepmdCheckliberror( LibFile, fResult);

 return fResult;

