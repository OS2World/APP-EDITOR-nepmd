/****************************** Module Header *******************************
*
* Module Name: writeconfigvalue.e
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
@@NepmdWriteConfigValue@PROTOTYPE
rc = NepmdWriteConfigValue( Handle, ConfPath, ConfValue);

@@NepmdWriteConfigValue@CATEGORY@CONFIG

@@NepmdWriteConfigValue@SYNTAX
This function writes a value to the configuration repository of the
[=TITLE] installation.

@@NepmdWriteConfigValue@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdWriteConfigValue@PARM@ConfPath
This parameter specifies the [.IDPNL_REGISTRY_NAMESPACE path] under which the
configuration value is to be stored.

@@NepmdWriteConfigValue@PARM@ConfValue
This parameter specifies the value to be stored under the specified
configuration path.

@@NepmdWriteConfigValue@RETURNS
*NepmdWriteConfigValue* returns an OS/2 error code or zero for no error.

@@NepmdWriteConfigValue@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdWriteConfigValue*
  - or
- *WriteConfigValue*


Executing this command will write the string
.sl compact
- *This is a test value for the Nepmd**Config** APIs !*
.el
as the the configuration value with the pathname
.sl compact
- *\NEPMD\Test\Nepmdlib\TestKey*
.el
to the configuration repository of the [=TILE]
and display the result within the status area.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdWriteConfigValue, WriteConfigValue =

 rc = NepmdWriteConfigValue( 0, NEPMD_TEST_CONFIGPATH, NEPMD_TEST_CONFIGVALUE);
 if (rc > 0) then
    sayerror 'config value not written, rc='rc;
    return;
 endif

 sayerror 'config value "'NEPMD_TEST_CONFIGPATH'" successfully written!';

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdWriteConfigValue                              */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = NepmdWriteConfigValue( Handle, ConfPath, ConfValue);  */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdWriteConfigValue( HCONFIG hconfig,      */
/*                                         PSZ pszRegPath,       */
/*                                         PSZ pszRegValue);     */
/* ------------------------------------------------------------- */

defproc NepmdWriteConfigValue( Handle, ConfPath, ConfValue) =

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 /* prepare parameters for C routine */
 ConfPath  = ConfPath''atoi( 0);
 ConfValue = ConfValue''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdWriteConfigValue",
                  atol( Handle)      ||
                  address( ConfPath) ||
                  address( ConfValue));

 helperNepmdCheckliberror( LibFile, rc);

 return rc;

