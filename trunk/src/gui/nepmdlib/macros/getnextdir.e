/****************************** Module Header *******************************
*
* Module Name: getnextdir.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextdir.e,v 1.3 2002-08-23 15:35:00 cla Exp $
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

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdGetNextDir, GetNextDir =

 Handle   = 0;  /* always create a new handle ! */
 DirMask = arg( 1);

 /* with the following call we would pass over full  */
 /* path, so that would get returned a full path !   */
 /* DirMask = NepmdQueryFullName( DirMask); */

 /* search all files */
 do while (1)
    Fullname = NepmdGetNextDir(  DirMask, address( Handle));
    parse value Fullname with 'ERROR:'rc;
    if (rc > '') then
       leave;
    endif

    messagenwait( 'File found:' Fullname);
 end;

/* ------------------------------------------------------------- */
/* procedure: NepmdGetNextDir                                    */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Handle   = 0;                                              */
/*    Filename = NepmdGetNextDir( DirMask, adress(Handle));      */
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

