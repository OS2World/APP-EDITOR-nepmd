/****************************** Module Header *******************************
*
* Module Name: querydefaultmode.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
@@NepmdQueryDefaultMode@PROTOTYPE
DefaultMode = NepmdQueryDefaultMode( Filename);

@@NepmdQueryDefaultMode@CATEGORY@MODE

@@NepmdQueryDefaultMode@SYNTAX
This function determines the default *EPM* mode for the specified file.

@@NepmdQueryDefaultMode@PARM@Filename
This parameter specifies the name of the file, for which
the default *EPM* mode is to be determined.

@@NepmdQueryDefaultMode@RETURNS
*NepmdQueryDefaultMode* returns either
.ul compact
- the name of the default *EPM* mode  or
- *TEXT*, if no mode could be determined  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@NepmdQueryDefaultMode@TESTCASE
You can test this function from the *EPM* commandline by
executing:
.sl
- *NepmdQueryDefaultMode*
   [.IDPNL_EFUNC_NEPMDQUERYDEFAULTMODE_PARM_FILENAME filename]
  - or
- *QueryDefaultMode*
   [.IDPNL_EFUNC_NEPMDQUERYDEFAULTMODE_PARM_FILENAME filename]


Executing this command will
determine the default mode of the
the specified file.

_*Example:*_
.fo off
  QueryDefaultMode d:\test.cmd
.fo on

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdQueryDefaultMode, QueryDefaultMode =

 Filename =  arg( 1);
 if (Filename = '') then
    sayerror 'error: no filename specified.';
    return;
 endif

 DefaultMode = NepmdQueryDefaultMode( Filename);
 parse value DefaultMode with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'default EPM mode could not be determined, rc='rc;
    return;
 endif

 sayerror 'default mode for "'Filename'" is:' DefaultMode;

 return;

/* ------------------------------------------------------------- */
/* procedure: NepmdQueryDefaultMode                              */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    DefaultMode = NepmdQueryDefaultMode( Filename);            */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryDefaultMode( PSZ pszFilename,      */
/*                                         PSZ pszBuffer,        */
/*                                         ULONG ulBuflen)       */
/* ------------------------------------------------------------- */

defproc NepmdQueryDefaultMode( Filename ) =

 BufLen      = NEPMD_MAXLEN_ESTRING;
 DefaultMode = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryDefaultMode",
                  address( Filename)    ||
                  address( DefaultMode) ||
                  atol( Buflen));

 /* reserved value, if no mode found */
 if (rc == 3) then
    DefaultMode = "TEXT";
 else
    helperNepmdCheckliberror( LibFile, rc);
    DefaultMode = makerexxstring( DefaultMode);
 endif

 return DefaultMode;

