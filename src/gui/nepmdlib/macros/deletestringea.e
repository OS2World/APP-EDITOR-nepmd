/****************************** Module Header *******************************
*
* Module Name: deletestringea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: deletestringea.e,v 1.12 2003-08-30 16:00:59 aschn Exp $
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
@@NepmdDeleteStringEa@PROTOTYPE
rc = NepmdDeleteStringEa( Filename, EaName);

@@NepmdDeleteStringEa@CATEGORY@EAS

@@NepmdDeleteStringEa@SYNTAX
This function deletes the specified extended attribute
from the specified file.

@@NepmdDeleteStringEa@PARM@Filename
This parameter specifies the name of the file, from which
the specified REXX EAs is to be deleted.

@@NepmdDeleteStringEa@PARM@EaName
This parameter specifies the name of the extended
attribute to be deleted.

@@NepmdDeleteStringEa@REMARKS
[=NOTE]
.ul compact
- using this function will have an effect only if the specified
  file has the specified extended attribute.
- no error is returned if the specified file exists, but does not have
  the specified extended attribute
.at fc=red
- the specified extended attribute is always deleted from the specified file,
  even if it is *not* holding an extended attribute being of type string!
.at

@@NepmdDeleteStringEa@RETURNS
*NepmdDeleteStringEa* returns an OS/2 error code or zero for no error.

@@NepmdDeleteStringEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDeleteStringEa* [.IDPNL_EFUNC_NEPMDDELETESTRINGEA_PARM_FILENAME filename]
  - or
- *DeleteStringEa* [.IDPNL_EFUNC_NEPMDDELETESTRINGEA_PARM_FILENAME filename]


Executing this command will
remove the specified extended attribute
with the name
.sl compact
- *NEPMD.__TestStringEa*
.el
from the specified file
and display the result within the status area.

_*Example:*_
.fo off
  DeleteStringEa d:\myscript.txt
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdDeleteStringEa, DeleteStringEa =

 Filename = arg( 1);
 if (Filename = '') then
    sayerror 'error: no filename specified.';
    return;
 endif

 rc = NepmdWriteStringEa( Filename, NEPMD_TEST_EANAME, '');
 if (rc > 0) then
    sayerror 'Extended attribute not deleted, rc='rc;
    return;
 endif

 sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" deleted from:' Filename;

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdDeleteStringEa                                */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = NepmdDeleteStringEa( Filename, EaName);         */
/* ------------------------------------------------------------- */

defproc NepmdDeleteStringEa( Filename, EaName ) =

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);
 EaName     = EaName''atoi( 0);
 EaValue    = atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdWriteStringEa",
                  address( Filename)            ||
                  address( EaName)              ||
                  address( EaValue));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

