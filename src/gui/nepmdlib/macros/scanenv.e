/****************************** Module Header *******************************
*
* Module Name: scanenv.e
*
* .e wrapper routine to access the NEPMD library DLL.
* include of nepmdlib.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: scanenv.e,v 1.2 2002-09-06 10:01:16 cla Exp $
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
@@NepmdScanEnv@PROTOTYPE
EnvValue = NepmdScanEnv( EnvName);

@@NepmdScanEnv@CATEGORY@PROCESS

@@NepmdScanEnv@SYNTAX
This function retrieves the value of the specified environment variable.

@@NepmdScanEnv@PARM@EnvName
This parameter specifies the name of the environment variable
of which the value is to be retrieved.

@@NepmdScanEnv@RETURNS
NepmdScanEnv returns either
.ul compact
- the value of the requested extended attribute  or
- the string *ERROR:xxx*, where *xxx* is an OS/2 error code.

@@
*/

/* ------------------------------------------------------------- */
/*   allow editor command to call function                       */
/* ------------------------------------------------------------- */

defc NepmdScanEnv, ScanEnv =

 EnvName  =  arg( 1);
 EnvValue = NepmdScanEnv( EnvName);
 parse value EnvValue with 'ERROR:'rc;
 if (rc > '') then
    sayerror 'Environment variable "'EnvName'" is not defined, rc='rc;
    return;
 endif

 sayerror 'Value of "'EnvName'" is:' EnvValue;

/* ------------------------------------------------------------- */
/* procedure: NepmdScanEnv                                       */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    EnvValue = NepmdScanEnv( EnvName);                         */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdScanEnv( PSZ pszEnvName,                */
/*                                PSZ pszBuffer,                 */
/*                                ULONG ulBuflen)                */
/* ------------------------------------------------------------- */

defproc NepmdScanEnv( EnvName ) =

 BufLen   = NEPMD_MAXLEN_ESTRING;
 EnvValue = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 EnvName  = EnvName''atoi( 0);

 /* make env name uppercase */
 EnvName = TRANSLATE( EnvName);

 /* call C routine */
 LibFile = helperNepmdGetlibfile();
 rc = dynalink32( LibFile,
                  "NepmdScanEnv",
                  address( EnvName)         ||
                  address( EnvValue)        ||
                  atol( Buflen));

 helperNepmdCheckliberror( LibFile, rc);

 return makerexxstring( EnvValue);

