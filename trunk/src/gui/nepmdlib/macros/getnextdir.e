/****************************** Module Header *******************************
*
* Module Name: getnextdir.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextdir.e,v 1.7 2002-09-05 21:57:25 cla Exp $
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
NepmdGetNextDir returns either
.ul compact
- the next directory returned by the directory seach  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextDir, GetNextDir =

 Handle   = 0;  /* always create a new handle ! */
 AddressOfHandle = address( Handle);
 DirMask = arg( 1);

 /* with the following call we would pass over full  */
 /* path, so that would get returned a full path !   */
 /* DirMask = NepmdQueryFullName( DirMask); */

 /* search all files */
 do while (1)
    Dirname = NepmdGetNextDir(  DirMask, AddressOfHandle);
    parse value Dirname with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    messagenwait( 'Dir found:' Dirname);
 end;

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
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextDir",
                  address( DirMask)             ||
                  PtrToHandle                   ||
                  address( Filename)            ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( FileName);

