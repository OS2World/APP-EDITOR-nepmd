/****************************** Module Header *******************************
*
* Module Name: queryfullname.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: queryfullname.e,v 1.11 2002-09-07 13:19:45 cla Exp $
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
@@NepmdQueryFullname@PROTOTYPE
Fullname = NepmdQueryFullname( Filename);

@@NepmdQueryFullname@CATEGORY@FILE

@@NepmdQueryFullname@SYNTAX
This function queries the fullname of the specified filename. It 
does not check, wether a file or directory really exists, for that use
the functions [.IDPNL_EFUNC_NEPMDFILEEXISTS] or [.IDPNL_EFUNC_NEPMDDIREXISTS].

@@NepmdQueryFullname@PARM@Filename
This parameter specifies the file or directory name. it may include
.ul compact
- absolute or relative pathname specifications
- wildcards, but only within the filename part,
  they are returned within the result.

It is not necessary to specify a name of a file, which exists
or of which all directories of the path specification exist.
The only requirement ist that the resulting file or directory entry
#could# exist in the resulting directory, that means it must be valid.

@@NepmdQueryFullname@RETURNS
*NepmdQueryFullname* returns either
.ul compact
- the full qualified filename  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryFullname@REMARKS
This function calls the OS/2 API *DosQueryPathInfo* and will
return the full name of any directory or filename, even if it does
not exist. It is especially useful where relative path specifications
are to be translated into absolute pathnames or to prove that they are
valid.

@@NepmdQueryFullname@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryFullname* [.IDPNL_EFUNC_NEPMDQUERYFULLNAME_PARM_FILENAME filename] 
  - or
- *QueryFullname* [.IDPNL_EFUNC_NEPMDQUERYFULLNAME_PARM_FILENAME filename]

Executing this command will
return the fully qualified pathname specification for the given filename
and display the result within the status area.

_*Examples:*_
.fo off
 QueryFullname myscript.txt
 QueryFullname ..\*.cmd
.fo on

@@
*/


/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryFullname, QueryFullname =

 Filename = arg( 1);
 Fullname = NepmdQueryFullname( Filename);

 parse value Fullname with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'fullname of "'Filename'" could not be retrieved, rc='rc;
    return;
 endif

 sayerror 'fullname of "'Filename'" is:' Fullname;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryFullname                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdQueryFullname( filename);                  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryFullname( PSZ pszFilename,         */
/*                                      PSZ pszBuffer,           */
/*                                      ULONG ulBuflen)          */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdQueryFullname( Filename) =

 BufLen   = 260;
 FullName = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryFullname",
                  address( Filename)            ||
                  address( Fullname)            ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( FullName);

