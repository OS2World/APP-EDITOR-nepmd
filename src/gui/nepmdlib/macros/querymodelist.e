/****************************** Module Header *******************************
*
* Module Name: querymodelist.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: querymodelist.e,v 1.1 2002-10-14 17:50:02 cla Exp $
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
@@NepmdQueryModeList@PROTOTYPE
ModeList = NepmdQueryModeList( );

@@NepmdQueryModeList@CATEGORY@MODE

@@NepmdQueryModeList@SYNTAX
This function determines the list of available *EPM* modes.

@@NepmdQueryModeList@RETURNS
*NepmdQueryModeList* returns either
.ul compact
- the spcce separated list of available *EPM* modes  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryModeList@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryModeList*
  - or
- *QueryModeList*


Executing this command will
display the list of all available *EPM* modes in the statusline.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryModeList, QueryModeList =

 ModeList = NepmdQueryModeList( );
 parse value ModeList with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'list of EPM modes could not be determined, rc='rc;
    return;
 endif

 sayerror 'EPM modes:' ModeList;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryModeList                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    ModeList = NepmdQueryModeList( );                          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryModeList( PSZ pszBuffer,           */
/*                                      ULONG ulBuflen)          */
/* ------------------------------------------------------------- */

defproc NepmdQueryModeList( ) =

 BufLen      = NEPMD_MAXLEN_ESTRING;
 ModeList    = copies( atoi( 0), BufLen);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryModeList",
                  address( ModeList) ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( ModeList);

