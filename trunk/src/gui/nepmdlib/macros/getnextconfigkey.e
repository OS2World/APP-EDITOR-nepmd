/****************************** Module Header *******************************
*
* Module Name: getnextconfigkey.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextconfigkey.e,v 1.1 2002-09-16 21:38:23 cla Exp $
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
@@NepmdGetNextConfigKey@PROTOTYPE
NextKey = NepmdGetNextConfigKey( Handle, RegPath, PreviousKey);

@@NepmdGetNextConfigKey@CATEGORY@CONFIG

@@NepmdGetNextConfigKey@SYNTAX
This function queries a container lookup for key containers
in the configuration repository of the [=TITLE].
For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTCONFIGKEY_EXAMPLE called in a loop].

@@NepmdGetNextConfigKey@PARM@Handle
This parameter determines the handle obtained by a previous call
to [.IDPNL_EFUNC_NEPMDOPENCONFIG].

You may pass a *zero* or an *empty string* to
[.IDPNL_REGISTRY_IMPLICITOPEN implicitely open and close]
the configuration repository before and after this call.

@@NepmdGetNextConfigKey@PARM@RegPath
This parameter specifies the pathname of the container.

@@NepmdGetNextConfigKey@PARM@PreviousKey
This parameter specifies either
.ul compact
- an empty string to query the first key of the container  or
- the previously returned key in order to query the next key

@@NepmdGetNextConfigKey@EXAMPLE
The following code searches all subdirectories of the container *\NEPMD*:
.fo off
--> place sample code here
.fo on

@@NepmdGetNextConfigKey@RETURNS
*NepmdGetNextConfigKey* returns either
.ul compact
- the next key returned by the container seach  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdGetNextConfigKey@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextConfigKey*
  - or
- *GetNextDir*

Executing this command will
open up a virtual file and
write all keys found for the container *\NEPMD* to it.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextConfigKey, GetNextConfigKey =

 rc = ''
 RegPath = '\NEPMD';
 CurrentKey = '';

 /* open up the configuration repository */
 Handle = NepmdOpenConfig();
 parse value Handle with 'ERROR:'rc;
 if (rc > 0) then
    sayerror 'configuration repository could not be opened, rc='rc;
    return;
 endif

 /* create virtual file */
 helperNepmdCreateDumpfile( 'NepmdGetNextConfigKey', RegPath);

 /* search all files */
 do while (1)
    CurrentKey = NepmdGetNextConfigKey( Handle, RegPath, CurrentKey);
    parse value CurrentKey with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    insertline( '-' CurrentKey);
 end;
 insertline '';
 .modify = 0;

 rcx = NepmdCloseConfig( Handle);

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextConfigKey                              */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle   = 0;                                              */
/*    NextKey = NepmdGetNextConfigKey( Handle, RegPath,          */
/*                                     PreviousKey);             */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetNextConfigKey( HCONFIG hconfig,      */
/*                                         PSZ   pszRegPath,     */
/*                                         PSZ   pszPreviousKey, */
/*                                         PSZ   pszBuffer,      */
/*                                         ULONG ulBuflen)       */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdGetNextConfigKey( Handle, RegPath, PreviousKey)

 /* use zero as handle if none specified */
 if (strip( Handle) = '') then
    Handle = 0;
 endif

 BufLen   = NEPMD_MAXLEN_ESTRING;
 NextKey  = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 /* don't touch the handle parameter, as we must report */
 /* the address of the original var of the caller !!!   */
 RegPath      = RegPath''atoi( 0);
 PreviousKey  = PreviousKey''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextConfigKey",
                  atol( Handle)                ||
                  address( RegPath)            ||
                  address( PreviousKey)        ||
                  address( NextKey)            ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( NextKey);

