/****************************** Module Header *******************************
*
* Module Name: getnextclose.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextclose.e,v 1.5 2002-09-07 13:19:44 cla Exp $
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
@@NepmdGetNextClose@PROTOTYPE
rc = NepmdGetNextClose( Handle);

@@NepmdGetNextClose@CATEGORY@FILE

@@NepmdGetNextClose@SYNTAX
This function closes open search handles possibly left open
by the functions [.IDPNL_EFUNC_NEPMDGETNEXTFILE] or
[.IDPNL_EFUNC_NEPMDGETNEXTDIR].

@@NepmdGetNextClose@PARM@Handle
This parameter specifies the handle to be closed, where the value
has been set by a previous call to [.IDPNL_EFUNC_NEPMDGETNEXTFILE]
or [.IDPNL_EFUNC_NEPMDGETNEXTDIR].

@@NepmdGetNextClose@REMARKS
Calling this function is normally not necessary, as the functions
[.IDPNL_EFUNC_NEPMDGETNEXTFILE] and [.IDPNL_EFUNC_NEPMDGETNEXTDIR]
are mostly called in a loop and search all entries unless no more
is available - if so, these functions automatically will close the
open search handle.

Only when the routine exits that loop for any reason before the last entry
has been reported by the *NepmdGetNext* functions,
.at fc=red
the cleanup code must close the open handle by a call to *NepmdGetNextClose*.
.at

@@NepmdGetNextClose@RETURNS
*NepmdGetNextClose* returns an OS/2 error code or zero for no error.

@@NepmdGetNextClose@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextClose* [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE_PARM_HANDLE handle]
  - or
- *GetNextClose* [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE_PARM_HANDLE handle]

Executing this command will
delete the specified handle
and display the result within the status area.

Because of that only a previous call to the functions [.IDPNL_EFUNC_NEPMDGETNEXTFILE] 
or [.IDPNL_EFUNC_NEPMDGETNEXTDIR] can leave an open handle for you to test, and
the related testcases will not do so, you will not truly be able to test a successful
call to this function by this testcase.

_*Example:*_
.fo off
  GetNextClose 5
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextClose, GetNextClose =

 Handle = arg( 1);
 rc = NepmdGetNextClose( Handle);

 if (rc > 0) then
    sayerror 'Invalid handle' Handle', could not be closed,  rc='rc;
    return;
 endif

 sayerror 'Handle'  Handle '  was closed successfully.';

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextClose                                  */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdGetNextClose( Handle);                           */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetNextClose( ULONG Handle);            */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdGetNextClose( Handle) =

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextClose",
                  atol( Handle));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

