/****************************** Module Header *******************************
*
* Module Name: deleterexxea.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: deleterexxea.e,v 1.4 2002-08-23 08:30:05 cla Exp $
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

defc NepmdDeleteRexxEa, DeleteRexxEa =

  /* error handling for first EA only */
  rc = NepmdWriteStringEa( arg( 1), 'REXX.METACONTROL', '');

  if (rc > 0) then
     sayerror 'REXX Eas not deleted, rc='rc;
     return;
  endif

  /* delete all others as well, discard result codes here */
  rcx = NepmdWriteStringEa( arg( 1), 'REXX.PROGRAMDATA', '');
  rcx = NepmdWriteStringEa( arg( 1), 'REXX.LITERALPOOL', '');
  rcx = NepmdWriteStringEa( arg( 1), 'REXX.TOKENSIMAGE', '');
  rcx = NepmdWriteStringEa( arg( 1), 'REXX.VARIABLEBUF', '');

  sayerror 'REXX Eas deleted';

