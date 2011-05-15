/****************************** Module Header *******************************
*
* Module Name: deleteconfigvalue.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
@@NepmdDeleteConfigValue@PROTOTYPE
rc = NepmdDeleteConfigValue( Handle, ConfPath);

@@NepmdDeleteConfigValue@CATEGORY@CONFIG

@@NepmdDeleteConfigValue@SYNTAX
This function deletes a value from the configuration repository of the
[=TITLE] installation.

@@NepmdDeleteConfigValue@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdDeleteConfigValue@PARM@ConfPath
This parameter specifies the [.IDPNL_REGISTRY_NAMESPACE path] under which the
configuration value is to be deleted.

@@NepmdDeleteConfigValue@RETURNS
*NepmdDeleteConfigValue* returns an OS/2 error code or zero for no error.

@@NepmdDeleteConfigValue@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdDeleteConfigValue*
  - or
- *DeleteConfigValue*


Executing this command will delete
the configuration value with the pathname
.sl compact
- *\NEPMD\Test\Nepmdlib\TestKey*
.el
from the configuration repository of the [=TILE]
and display the result within the status area.

@@
*/
/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdDeleteConfigValue, DeleteConfigValue =

 rc = NepmdDeleteConfigValue( 0, NEPMD_TEST_CONFIGPATH);

 if (rc > 0) then
    sayerror 'config value not deleted, rc='rc;
    return;
 endif

 sayerror 'config value  "'NEPMD_TEST_CONFIGPATH'" successfully deleted!';

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdDeleteConfigValue                             */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdDeleteConfigValue( Handle, ConfPath);            */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdDeleteConfigValue( HCONFIG hconfig,     */
/*                                          PSZ pszRegPath);     */
/* ------------------------------------------------------------- */

defproc NepmdDeleteConfigValue( Handle, ConfPath) =

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 /* prepare parameters for C routine */
 ConfPath  = ConfPath''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdDeleteConfigValue",
                  atol( Handle)      ||
                  address( ConfPath));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

