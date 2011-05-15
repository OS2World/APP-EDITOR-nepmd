/****************************** Module Header *******************************
*
* Module Name: queryconfigvalue.e
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
@@NepmdQueryConfigValue@PROTOTYPE
ConfValue = NepmdQueryConfigValue( Handle, ConfPath);

@@NepmdQueryConfigValue@CATEGORY@CONFIG

@@NepmdQueryConfigValue@SYNTAX
This function reads a value from the configuration repository of the
[=TITLE] installation.

@@NepmdQueryConfigValue@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdQueryConfigValue@PARM@ConfPath
This parameter specifies the [.IDPNL_REGISTRY_NAMESPACE path] under which the
configuration is to be read.

@@NepmdQueryConfigValue@RETURNS
*NepmdQueryConfigValue* returns either
.ul compact
- the configuration value  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryConfigValue@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryConfigValue*
  - or
- *QueryConfigValue*


Executing this command will
read the configuration value with the pathname
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
; We want this command also if included in EPM.E to call it from
; the command line or from an menu item.

defc NepmdQueryConfigValue, QueryConfigValue =

 ConfigValue = NepmdQueryConfigValue( 0, NEPMD_TEST_CONFIGPATH);
 parse value ConfigValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'config value could not be retrieved, rc='rc;
    return;
 endif

 sayerror 'config value "'NEPMD_TEST_CONFIGPATH'" contains:' ConfigValue;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryConfigValue                              */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    ConfValue = NepmdQueryConfigValue( Handle, ConfPath);      */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryConfigValue( HCONFIG hconfig,      */
/*                                         PSZ pszRegPath,       */
/*                                         PSZ pszBuffer,        */
/*                                         ULONG ulBuflen);      */
/* ------------------------------------------------------------- */

defproc NepmdQueryConfigValue( Handle, ConfPath) =

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 BufLen      = NEPMD_MAXLEN_ESTRING;
 ConfValue   = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 ConfPath  = ConfPath''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryConfigValue",
                  atol( Handle)       ||
                  address( ConfPath)  ||
                  address( ConfValue) ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( ConfValue);

