/****************************** Module Header *******************************
*
* Module Name: filedelete.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: filedelete.e,v 1.5 2002-09-19 11:43:50 cla Exp $
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
@@NepmdFileDelete@PROTOTYPE
rc = NepmdFileDelete( Filename);

@@NepmdFileDelete@CATEGORY@FILE

@@NepmdFileDelete@SYNTAX
This function deletes a file.

@@NepmdFileDelete@PARM@Filename
This parameter specifies the name of the file to be deleted.

@@NepmdFileDelete@RETURNS
*NepmdFileDelete* returns an OS/2 error code or zero for no error.

@@NepmdFileDelete@REMARKS
*NepmdFileDelete* replaces the function *erasetemp* of *stdprocs.e*.

For downwards compatibility the old function is still provided,
but calls *NepmdFileDelete*.

@@NepmdFileDelete@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdFileDelete* [.IDPNL_EFUNC_NEPMDFILEDELETE_PARM_FILENAME filename]
  - or
- *FileDelete* [.IDPNL_EFUNC_NEPMDFILEDELETE_PARM_FILENAME filename]

Executing this command will
delete the specified file
and display the result within the status area.

_*Example:*_
.fo off
  FileDelete d:\myscript.txt
.fo on

@@
*/


/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdFileDelete, FileDelete =

 Filename = arg( 1);
 if (Filename = '') then
    sayerror 'error: no filename specified.';
    return;
 endif

 rc = NepmdFileDelete( Filename);
 if (rc = 0) then
    StrResult = 'been deleted';
 else
    StrResult = 'not been deleted, rc='rc;
 endif

 sayerror 'file "'Filename'" has' StrResult;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdFileDelete                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdFileDelete( filename);        v                  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdFileDelete( PSZ pszFilename);           */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdFileDelete( Filename) =

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdFileDelete",
                  address( Filename));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;
