/****************************** Module Header *******************************
*
* Module Name: getnextfile.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: getnextfile.e,v 1.2 2002-08-22 12:20:01 cla Exp $
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

defc NepmdGetNextFile, GetNextFile =

  Handle   = 0;  /* always create a new handle ! */
  Filemask = arg( 1);

  /* with the following call we would pass over full  */
  /* path, so that would get returned a full path !   */
  /* FileMask = NepmdQueryFullName( FileMask); */

  /* search all files */
  do while (1)
     Fullname = NepmdGetNextFile(  FileMask, address( Handle));
     if (length( Fullname) > 0) then
        messagenwait( 'File found:' Fullname);
     else
        leave;
     endif
  end;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryFullname                                 */
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

