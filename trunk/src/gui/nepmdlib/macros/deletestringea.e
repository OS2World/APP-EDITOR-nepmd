/****************************** Module Header *******************************
*
* Module Name: deletestringea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: deletestringea.e,v 1.8 2002-09-06 10:01:13 cla Exp $
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

@@NepmdDeleteStringEa@RETURNS
NepmdDeleteStringEa returns an OS/2 error code or zero for no error.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdDeleteStringEa, DeleteStringEa =

 Filename = arg( 1);
 rc = NepmdWriteStringEa( Filename, NEPMD_TEST_EANAME, '');

 if (rc > 0) then
    sayerror 'Extended attribute not deleted, rc='rc;
    return;
 endif

 sayerror 'Extended attribute "'NEPMD_TEST_EANAME'" deleted from:' Filename;

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

