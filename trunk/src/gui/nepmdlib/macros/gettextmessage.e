/****************************** Module Header *******************************
*
* Module Name: gettextmessage.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: gettextmessage.e,v 1.1 2002-08-20 20:03:19 cla Exp $
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

defc NepmdGetTextMessage, GetTextMessage

  Envvar = 'NEPMD_TMFTESTFILE';

  Testfile = get_env( Envvar);
  if (length( Testfile) = 0) then
     sayerror 'error: cannot test NepmdGetTextMessage, envvar' Envvar 'not set!';
  else
     sayerror NepmdGetTextMessage( Testfile, 'TESTMESSAGE');
  endif

/* ------------------------------------------------------------- */
/* procedure: NepmdGetTextMessage                                */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    message = NepmdGetTextMessage( Filename, Messagename       */
/*                                   [, parm1, parm2 ... parm8]);*/
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdGetTextMessage( PSZ pszFilename,        */
/*                                       PSZ pszMessageName,     */
/*                                       PSZ pszBuffer,          */
/*                                       ULONG ulBuflen,         */
/*                                       PSZ pszParm1,           */
/*                                       PSZ pszParm2,           */
/*                                       PSZ pszParm3,           */
/*                                       PSZ pszParm4,           */
/*                                       PSZ pszParm5,           */
/*                                       PSZ pszParm6,           */
/*                                       PSZ pszParm7,           */
/*                                       PSZ pszParm8);          */
/* NOTE: unlike DosGetMessage, this function returns an ASCIIZ ! */
/* ------------------------------------------------------------- */

defproc NepmdGetTextMessage( Filename, Messagename) =

 BufLen      = 512;
 TextMessage = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename    = Filename''atoi( 0);
 Messagename = Messagename''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetTextMessage",
                  address( Filename)            ||
                  address( Messagename)         ||
                  address( TextMessage)         ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return TextMessage;

