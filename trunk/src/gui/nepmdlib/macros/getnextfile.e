/****************************** Module Header *******************************
*
* Module Name: getnextfile.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextfile.e,v 1.6 2002-08-25 19:58:16 cla Exp $
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
Filename = NepmdGetNextFile( FileMask, adress( Handle));

@@NepmdGetNextFile@SYNTAX
This function implements an easy directory lookup
for files with one function. For that it needs to be called in 
a loop.

@@NepmdGetNextFile@PARM@FileMask
This parameter specifies the files to be searched
and may contain wildcards.

@@NepmdGetNextFile@PARM@AddressOfHandle
This parameter specifies the address of a search handle,
it can be determined with the *adress()* function like
.fo off
   adress( handle);
.fo on

Note that on the first call to NepmdGetNextFile() the value
of the variable holding the handle must be set to zero.

@@NepmdGetNextFile@EXAMPLE
The following code searches all files within the directory C:\OS2:
.fo off
 Handle  = 0;  /** always create a new handle ! **/
 FileMask = 'C:\OS2\**';

 /** search all files **/
 do while (1)
    Filename = NepmdGetNextFile(  FileMask, address( Handle));
    parse value Filename with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    /** process subdirectory - here as a sample we display a popup **/
    messagenwait( 'File found:' Filename);
 end;
.fo on

@@NepmdGetNextFile@RETURNS
NepmdGetNextFile returns either
.ul compact
- the next directory returned by the directory seach  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextFile, GetNextFile =

 Handle   = 0;  /* always create a new handle ! */
 Filemask = arg( 1);

 /* with the following call we would pass over full  */
 /* path, so that would get returned a full path !   */
 /* FileMask = NepmdQueryFullName( FileMask); */

 /* search all files */
 do while (1)
    Filename = NepmdGetNextFile(  FileMask, address( Handle));
    parse value Filename with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    messagenwait( 'File found:' Filename);
 end;

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextFile                                   */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle   = 0;                                              */
/*    Filename = NepmdGetNextFile( Filemask, adress(Handle));    */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetNextFile( PSZ   pszFilemask,         */
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
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetNextFile",
                  address( Filemask)            ||
                  PtrToHandle                   ||
                  address( Filename)            ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return makerexxstring( FileName);

