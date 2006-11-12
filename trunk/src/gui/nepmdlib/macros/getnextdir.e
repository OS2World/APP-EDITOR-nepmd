/****************************** Module Header *******************************
*
* Module Name: getnextdir.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextdir.e,v 1.14 2006-11-12 13:19:00 jbs Exp $
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
@@NepmdGetNextDir@PROTOTYPE
Filename = NepmdGetNextDir( DirMask, AddressOfHandle);

@@NepmdGetNextDir@CATEGORY@FILE

@@NepmdGetNextDir@SYNTAX
This function implements an easy directory lookup
for subdirectories with one function. For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTDIR_EXAMPLE called in a loop].

@@NepmdGetNextDir@PARM@DirMask
This parameter specifies the directories to be searched
and may contain wildcards.

@@NepmdGetNextDir@PARM@AddressOfHandle
This parameter specifies the address of a search handle,
it can be determined with the *address()* function like
.fo off
 Handle = 0;
 AddressOfHandle = address( Handle);
.fo on

Note that on the first call to NepmdGetNextDir() the value
of the variable holding the handle must be set to zero.

@@NepmdGetNextDir@EXAMPLE
The following code searches all subdirectories within the directory C:\OS2:
.fo off
 Handle  = 0;  /** always create a new handle ! **/
 AddressOfHandle = address( Handle);
 DirMask = 'C:\OS2\**';

 /** search all files **/
 do while (1)
    Dirname = NepmdGetNextDir(  DirMask, AddressOfHandle);
    parse value Dirname with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    /** process subdirectory - here as a sample we display a popup **/
    messagenwait( 'Dir found:' Dirname);
 end;
.fo on

@@NepmdGetNextDir@REMARKS
The search handle created by *NepmdGetNextDir* is automatically closed
if the search is repeated until no more entries are available.

.at fc=red
If a search for files is interrupted for any reason before receiving
the error code 18 (ERROR__NO__MORE__FILES), it is required to close
the search handle by a call to [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE].
.at

@@NepmdGetNextDir@RETURNS
*NepmdGetNextDir* returns either
.ul compact
- the next directory returned by the directory seach  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdGetNextDir@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextDir* [.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_DIRMASK dirmask]
  - or
- *GetNextDir* [.IDPNL_EFUNC_NEPMDGETNEXTDIR_PARM_DIRMASK dirmask]

Executing this command will
open up a virtual file and
write all found directories into it.

_*Example:*_
.fo off
  GetNextDir c:\os2\**
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */
compile if NEPMD_LIB_TEST
include 'STDCONST.E'

defc NepmdGetNextDir, GetNextDir =

 Handle   = GETNEXT_CREATE_NEW_HANDLE
 AddressOfHandle = address( Handle);

 DirMask = arg( 1);
 if (DirMask = '') then
    sayerror 'error: no dir mask specified !';
    return;
 endif

 DirMask = NepmdQueryFullname( arg( 1));
 parse value DirMask with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'error: invalid filemask specified !';
    return;
 endif

 /* create virtual file */
 helperNepmdCreateDumpfile( 'NepmdGetNextDir', DirMask);

 /* search all files */
 do while (1)
    Dirname = NepmdGetNextDir(  DirMask, AddressOfHandle);
    parse value Dirname with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    insertline( Dirname);
 end;
 .modify = 0;

 return;

compile endif

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextDir                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle   = 0;                                              */
/*    Filename = NepmdGetNextDir( DirMask, address(Handle));      */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetNextDir( PSZ   pszDirMask,           */
/*                                    PSZ   pszHandle,           */
/*                                    PSZ   pszBuffer,           */
/*                                    ULONG ulBuflen)            */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdGetNextDir( DirMask, PtrToHandle) =

 BufLen   = 260;
 FileName = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 /* don't touch the handle parameter, as we must report */
 /* the address of the original var of the caller !!!   */
 DirMask   = DirMask''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextDir",
                  address( DirMask)             ||
                  PtrToHandle                   ||
                  address( Filename)            ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( FileName);

