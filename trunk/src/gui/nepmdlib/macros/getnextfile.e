/****************************** Module Header *******************************
*
* Module Name: getnextfile.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextfile.e,v 1.15 2002-09-19 11:43:50 cla Exp $
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
@@NepmdGetNextFile@PROTOTYPE
Filename = NepmdGetNextFile( FileMask, AddressOfHandle);

@@NepmdGetNextFile@CATEGORY@FILE

@@NepmdGetNextFile@SYNTAX
This function implements an easy directory lookup
for files with one function. For that it needs to be
[.IDPNL_EFUNC_NEPMDGETNEXTFILE_EXAMPLE called in a loop].

@@NepmdGetNextFile@PARM@FileMask
This parameter specifies the files to be searched
and may contain wildcards.

@@NepmdGetNextFile@PARM@AddressOfHandle
This parameter specifies the address of a search handle,
it can be determined with the *address()* function like
.fo off
 Handle  = 0;
 AddressOfHandle = address( Handle);
.fo on

Note that on the first call to NepmdGetNextFile() the value
of the variable holding the handle must be set to zero
in order initiate a new search.

@@NepmdGetNextFile@EXAMPLE
The following code searches all files within the directory C:\OS2:
.fo off
 Handle  = 0;  /** always create a new handle ! **/
 AddressOfHandle = address( Handle);
 FileMask = 'C:\OS2\**';

 /** search all files **/
 do while (1)
    Filename = NepmdGetNextFile(  FileMask, AddressOfHandle);
    parse value Filename with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    /** process subdirectory - here as a sample we display a popup **/
    messagenwait( 'File found:' Filename);
 end;

.fo on

@@NepmdGetNextFile@REMARKS
The search handle created by *NepmdGetNextFile* is automatically closed
if the search is repeated until no more entries are available.

.at fc=red
If a search for files is interrupted for any reason before receiving
the error code 18 (ERROR__NO__MORE__FILES), it is required to close
the search handle by a call to [.IDPNL_EFUNC_NEPMDGETNEXTCLOSE].
.at

@@NepmdGetNextFile@RETURNS
*NepmdGetNextFile* returns either
.ul compact
- the next directory returned by the directory seach  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdGetNextFile@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdGetNextFile* [.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_FILEMASK filemask]
  - or
- *GetNextFile* [.IDPNL_EFUNC_NEPMDGETNEXTFILE_PARM_FILEMASK filemask]

Executing this command will
open up a virtual file and
write all found files into it.

_*Example:*_
.fo off
  GetNextFile c:\os2\**
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextFile, GetNextFile =

 Handle   = 0;  /* always create a new handle ! */
 AddressOfHandle = address( Handle);

 FileMask = arg( 1);
 if (FileMask = '') then
    sayerror 'error: no filename mask specified !';
    return;
 endif

 FileMask = NepmdQueryFullname( FileMask);
 parse value FileMask with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'error: invalid file mask specified !';
    return;
 endif

 /* create virtual file */
 helperNepmdCreateDumpfile( 'NepmdGetNextFile', FileMask);

 /* search all files */
 do while (1)
    Filename = NepmdGetNextFile(  FileMask, AddressOfHandle);
    parse value Filename with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    insertline( Filename);
 end;
 .modify = 0;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextFile                                   */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle   = 0;                                              */
/*    Filename = NepmdGetNextFile( FileMask, address(Handle));   */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetNextFile( PSZ   pszFileMask,         */
/*                                    PSZ   pszHandle,           */
/*                                    PSZ   pszBuffer,           */
/*                                    ULONG ulBuflen)            */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdGetNextFile( FileMask, PtrToHandle) =

 BufLen   = 260;
 FileName = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 /* don't touch the handle parameter, as we must report */
 /* the address of the original var of the caller !!!   */
 FileMask   = FileMask''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextFile",
                  address( FileMask)            ||
                  PtrToHandle                   ||
                  address( Filename)            ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( FileName);

