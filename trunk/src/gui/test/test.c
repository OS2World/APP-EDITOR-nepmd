/****************************** Module Header *******************************
*
* Module Name: test.c
*
* little test app to test selected functions of common.lib
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: test.c,v 1.2 2002-08-21 20:28:10 cla Exp $
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

#define INCL_DOS
#define INCL_WIN
#define INCL_ERRORS
#include <os2.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "macros.h"
#include "tmf.h"

// -----------------------------------------------------------------------------

INT main ( INT argc, PSZ  argv[], PSZ  envv[])
{

         APIRET         rc  = NO_ERROR;
         ULONG          i;


do
   {
   // =========================================================================

#define GETMESSAGE(m,t,c) \
        memset( szBuffer, 0, sizeof( szBuffer)); \
        rc = TmfGetMessage( t, c, szBuffer, sizeof( szBuffer), m, pszFilename, &ulMessageLen); \
        DPRINTF(( "%u - %s: ***>%s<***\n\n", rc, m, szBuffer));

   // testcase for TMF function
   do
      {
static         PSZ            pszEnvVar = "NEPMD_TMFTESTFILE";
static         PSZ            pszMessageName = "TESTMESSAGE";
               PSZ            pszFilename = getenv( pszEnvVar);
               ULONG          ulMessageLen;

               CHAR           szBuffer[ 512];
               PSZ            apszParms[] = { "parm1", "parm2", "parm3"};

      if (!pszFilename)
         {
         printf( "testcase for TMF skipped, envvar %s not found !\n", pszEnvVar);
         rc = ERROR_ENVVAR_NOT_FOUND;
         break;
         }
      GETMESSAGE( "INSERTTEST", apszParms, 1);
      GETMESSAGE( "TESTMESSAGE", NULL, 0);
      GETMESSAGE( "TESTVAL1", NULL, 0);
      GETMESSAGE( "TESTVAL2", NULL, 0);
      GETMESSAGE( "TESTVAL3", NULL, 0);

      } while (FALSE);

   // =========================================================================



   } while (FALSE);



return rc;

}

