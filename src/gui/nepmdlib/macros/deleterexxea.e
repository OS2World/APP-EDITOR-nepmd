/****************************** Module Header *******************************
*
* Module Name: deleterexxea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: deleterexxea.e,v 1.10 2002-09-07 13:19:43 cla Exp $
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
@@NepmdDeleteRexxEa@PROTOTYPE
rc = NepmdDeleteRexxEa( Filename);

@@NepmdDeleteRexxEa@CATEGORY@EAS

@@NepmdDeleteRexxEa@SYNTAX
This function deletes REXX related extended attributes
from the specified file.

@@NepmdDeleteRexxEa@PARM@Filename
This parameter specifies the name of the file, from which
the REXX EAs are to be deleted.

@@NepmdDeleteRexxEa@RETURNS
*NepmdDeleteRexxEa* returns an OS/2 error code or zero for no error.

@@NepmdDeleteRexxEa@REMARKS
[=NOTE]
.ul compact
- using this function will have an effect only if the specified
  file is a REXX .cmd file and has previously been executed.
- no error is returned if the specified file exists, but does not have
  the REXX extended attributes

@@NepmdDeleteRexxEa@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDeleteRexxEa* [.IDPNL_EFUNC_NEPMDDELETEREXXEA_PARM_FILENAME filename]
  - or
- *DeleteRexxEa* [.IDPNL_EFUNC_NEPMDDELETEREXXEA_PARM_FILENAME filename]

Executing this command will
remove the REXX extended attributes from the specified file
and display the result within the status area.

_*Example:*_
.fo off
  DeleteRexxEa d:\myscript.cmd
.fo on

@@
*/


/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdDeleteRexxEa, DeleteRexxEa =

 /* error handling for first EA only */
 rc = NepmdWriteStringEa( arg( 1), 'REXX.METACONTROL', '');

 if (rc > 0) then
    sayerror 'REXX Eas not deleted, rc='rc;
    return;
 endif

 /* delete all others as well, discard result codes here */
 rcx = NepmdWriteStringEa( arg( 1), 'REXX.PROGRAMDATA', '');
 rcx = NepmdWriteStringEa( arg( 1), 'REXX.LITERALPOOL', '');
 rcx = NepmdWriteStringEa( arg( 1), 'REXX.TOKENSIMAGE', '');
 rcx = NepmdWriteStringEa( arg( 1), 'REXX.VARIABLEBUF', '');

 sayerror 'REXX Eas deleted';

 return;

