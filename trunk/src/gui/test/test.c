/****************************** Module Header *******************************
*
* Module Name: test.c
*
* little test app to test selected functions of common.lib
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: test.c,v 1.7 2002-09-05 13:31:54 cla Exp $
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
#include "nepmd.h"
#include "tmf.h"
#include "instval.h"

// -----------------------------------------------------------------------------

INT main ( INT argc, PSZ  argv[], PSZ  envv[])
{

         APIRET         rc  = NO_ERROR;
         ULONG          i;
         PSZ            pszTestcase = NULL;


do
   {
   // check the testcase
   if (argc > 1) pszTestcase = argv[ 1];
   if (!pszTestcase)
      {
      printf( "error: no testcase specified!\n");
      rc = ERROR_INVALID_PARAMETER;
      break;
      }
   strupr( pszTestcase);


   // =========================================================================
   // testcase for TMF function
   // =========================================================================

#define GETMESSAGE(m,t,c) \
           memset( szBuffer, 0, sizeof( szBuffer)); \
           rc = TmfGetMessage( t, c, szBuffer, sizeof( szBuffer), m, pszFilename, &ulMessageLen); \
           DPRINTF(( "%u - %s: ***>%s<***\n\n", rc, m, szBuffer));

   if (!(strcmp( pszTestcase, "TMF")))

      {
               CHAR           szBuffer[ 512];
               ULONG          ulMessageLen;

   
      // testcase for TMF function of nepmdlib.tmf
      do
         {
   static         PSZ            pszEnvVar = "NEPMD_TMFTESTFILE";
   static         PSZ            pszMessageName = "TESTMESSAGE";
                  PSZ            pszFilename = getenv( pszEnvVar);
   
                  PSZ            apszParms[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9"};
   
         if (!pszFilename)
            {
            printf( "testcase for TMF skipped, envvar %s not found !\n", pszEnvVar);
            rc = ERROR_ENVVAR_NOT_FOUND;
            break;
            }
         GETMESSAGE( "INSERTTEST", apszParms, 9);
         GETMESSAGE( "TESTMESSAGE", NULL, 0);
         GETMESSAGE( "TESTVAL1", NULL, 0);
         GETMESSAGE( "TESTVAL2", NULL, 0);
         GETMESSAGE( "TESTVAL3", NULL, 0);


         } while (FALSE);

      // testcase for TMF function of nepmdeng.tmf
      do
         {
                  CHAR           szMessageFile[ _MAX_PATH];
                  PSZ            pszFilename = szMessageFile; // keep macro happy
                  PSZ            apszParms[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9"};

         // determine messsage file
         rc = QueryInstValue( NEPMD_VALUETAG_MESSAGE, szMessageFile, sizeof( szMessageFile));
         if (rc != NO_ERROR)
            {
            printf( "error: cannot determine location of nepmdeng.tmf !\n"); 
            break;
            }

         GETMESSAGE( "MSG_INFO_HEADER", NULL, 0);
         GETMESSAGE( "MSG_INFO_BODY_LIB", apszParms, 9); 

         } while (FALSE);
   
      } // testcase TMF

   // =========================================================================
   // testcase for QueryInstValue
   // =========================================================================


#define GETVALUE(t) \
      rc = QueryInstValue( t, szValue, sizeof( szValue));\
      DPRINTF(( "%u: value for \"%s\" is: %s\n\n", rc, t, szValue));

   if (!(strcmp( pszTestcase, "INSTVAL")))

      {
         PSZ            pszTag;
         CHAR           szValue[ _MAX_PATH];

      GETVALUE( NEPMD_VALUETAG_ROOTDIR);
      GETVALUE( NEPMD_VALUETAG_LANGUAGE);

      GETVALUE( NEPMD_VALUETAG_INIT); 
      GETVALUE( NEPMD_VALUETAG_MESSAGE);
   
      } // testcase INSTVAL



   } while (FALSE);



return rc;

}

