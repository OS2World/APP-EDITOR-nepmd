/****************************** Module Header *******************************
*
* Module Name: gettextmessage.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: gettextmessage.e,v 1.3 2002-08-21 21:38:25 cla Exp $
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

  /* determine message name or use default */
  if ( words( arg( 1)) = 0) then
     Messagename = 'TESTMESSAGE';
  else
     Messagename = word( arg( 1), 1);
  endif

  /* determine TMF name  */
  Envvar = 'NEPMD_TMFTESTFILE';
  Testfile = get_env( Envvar);
  if (length( Testfile) = 0) then
     sayerror 'error: cannot test NepmdGetTextMessage, envvar' Envvar 'not set!';
     return;
  endif

  /* fetch message - support only up to three vars here */
  /* NOTE: word 1 is already message name ! */
  ParmCount = words( arg( 1));
  Parm1     = word( arg( 1), 2);
  Parm2     = word( arg( 1), 3);
  Parm3     = word( arg( 1), 4);
  if (ParmCount < 2) then
     MessageText = NepmdGetTextMessage( Testfile, Messagename);
  elseif (ParmCount = 2) then
     MessageText = NepmdGetTextMessage( Testfile, Messagename, Parm1);
  elseif (ParmCount = 3) then
     MessageText = NepmdGetTextMessage( Testfile, Messagename, Parm1, Parm2);
  elseif (ParmCount = 4) then
     MessageText = NepmdGetTextMessage( Testfile, Messagename, Parm1, Parm2, Parm3);
  endif

  if (MessageText = '') then
     sayerror 'error: message' Messagename 'could not be retrieved!';
  else
     sayerror 'message is: "'MessageText'"';
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
/*                                       PSZ pszParm8,           */
/*                                       PSZ pszParm9);          */
/* NOTE: unlike DosGetMessage, this function returns an ASCIIZ ! */
/* ------------------------------------------------------------- */

defproc NepmdGetTextMessage( Filename, Messagename) =

 BufLen      = 1024;
 TextMessage = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename    = Filename''atoi( 0);
 Messagename = Messagename''atoi( 0);

 /* assemble variable parm list */
 /* we need to sezup vars for each parm, as arg() */
 /* returns the same address for all values :-(   */
 Parm1 = arg(  3)''atoi( 0);  if (arg() >  2) then Addr1 = address( Parm1); else Addr1 = atol( 0); endif
 Parm2 = arg(  4)''atoi( 0);  if (arg() =  4) then Addr2 = address( Parm2); else Addr2 = atol( 0); endif
 Parm3 = arg(  5)''atoi( 0);  if (arg() =  5) then Addr3 = address( Parm3); else Addr3 = atol( 0); endif
 Parm4 = arg(  6)''atoi( 0);  if (arg() =  6) then Addr4 = address( Parm4); else Addr4 = atol( 0); endif
 Parm5 = arg(  7)''atoi( 0);  if (arg() =  7) then Addr5 = address( Parm5); else Addr5 = atol( 0); endif
 Parm6 = arg(  8)''atoi( 0);  if (arg() =  8) then Addr6 = address( Parm6); else Addr6 = atol( 0); endif
 Parm7 = arg(  9)''atoi( 0);  if (arg() =  9) then Addr7 = address( Parm7); else Addr7 = atol( 0); endif
 Parm8 = arg( 10)''atoi( 0);  if (arg() = 10) then Addr8 = address( Parm8); else Addr8 = atol( 0); endif
 Parm9 = arg( 11)''atoi( 0);  if (arg() = 11) then Addr9 = address( Parm9); else Addr9 = atol( 0); endif

 VarParmList = Addr1 || Addr2 || Addr3 || Addr4 || Addr5 || Addr6 || Addr7 || Addr8 || Addr9;

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdGetTextMessage",
                  address( Filename)            ||
                  address( Messagename)         ||
                  address( TextMessage)         ||
                  atol( Buflen)                 ||
                  VarParmList);

 checkliberror( LibFile, rc);

 return makerexxstring( TextMessage);

