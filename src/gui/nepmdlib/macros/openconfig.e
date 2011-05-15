/****************************** Module Header *******************************
*
* Module Name: openconfig.e
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
@@NepmdOpenConfig@PROTOTYPE
Handle = NepmdOpenConfig();

@@NepmdOpenConfig@CATEGORY@CONFIG

@@NepmdOpenConfig@SYNTAX
This function opens the configuration repository of the [=TITLE]
installation.

@@NepmdOpenConfig@REMARKS
If you want to perform only only a single operation on the
configuration repository, it is recommended to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open] the configuration
repository.

If multiple operations are to be processed in a row,
[.IDPNL_REGISTRY_EXPLICITOPEN explicitely opening and closing]
the repository before and after the access will save you from
additional disk I/O.

@@NepmdOpenConfig@RETURNS
*NepmdOpenConfig* returns either
.ul compact
- the handle to the opened configuration repository  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdOpenConfig@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdOpenConfig*
  - or
- *OpenConfig*

This is identical to the testcase of the [.IDPNL_EFUNC_NEPMDCLOSECONFIG] API.


Executing this command will a execute a testcase, which performs
the access to the configuration repository of the [=TITLE]
[.IDPNL_REGISTRY_EXPLICITOPEN explicitely opening and closing]
the repository before / after accessing it.

The testcase performs the following calls
.ul compact
- [.IDPNL_EFUNC_NEPMDOPENCONFIG],
- [.IDPNL_EFUNC_NEPMDWRITECONFIGVALUE],
- [.IDPNL_EFUNC_NEPMDQUERYCONFIGVALUE],
- [.IDPNL_EFUNC_NEPMDDELETECONFIGVALUE] and
- [.IDPNL_EFUNC_NEPMDCLOSECONFIG],
.el
and opens up a virtual file, writing the testcase result into it.

If an error occurrs, the error message will be displayed
result within the status area.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST

defc NepmdOpenConfig, OpenConfig =

 TestPath  = '\NEPMD\NepmdLib\Testcase';
 TestValue = 'This is a testvalue';
 Handle    = 0;

 Handle = NepmdOpenConfig();
 parse value Handle with 'ERROR:'rc;
 if (rc > 0) then
    sayerror 'Configuration repository could not be opened, rc = 'rc'.';
    return;
 endif

 rc = NepmdWriteConfigValue( Handle, TestPath, TestValue);
 if (rc > 0) then
    sayerror 'Config value "'TestPath'" cout not be written, rc = 'rc'.';
 else
    QueriedValue  = NepmdQueryConfigValue( Handle, TestPath);
    if (rc > 0) then
       sayerror 'Value of "'TestPath'" could not be read.';
    else
       rc = NepmdDeleteConfigValue( Handle, TestPath);
       if (rc > 0) then
          sayerror 'Config value "'TestPath'" could not be deleted.';
       endif
    endif
    rc2 = NepmdCloseConfig( Handle);
 endif

 if (rc = 0) then
    helperNepmdCreateDumpfile( 'NepmdOpenConfig/NepmdCloseConfig', '');

    insertline '       handle:' Handle;
    insertline '      keypath:' TestPath;
    insertline '     keyvalue:' TestValue;
    insertline '';
    insertline 'queried value:' QueriedValue;
    insertline '';
    .modify = 0;
 endif

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdOpenConfig                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle = NepmdOpenConfig( );                               */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdOpenConfig( PSZ pszBuffer,              */
/*                                   ULONG ulBuflen)             */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdOpenConfig( ) =

 BufLen = 20;
 Handle = copies( \0, BufLen);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdOpenConfig",
                  address( Handle)     ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( Handle);

