/****************************** Module Header *******************************
*
* Module Name: test.c
*
* little test app to test selected functions of common.lib
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: test.c,v 1.10 2002-09-12 22:26:18 cla Exp $
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
#include "libreg.h"

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
         rc = QueryInstValue( NEPMD_INSTVALUE_MESSAGE, szMessageFile, sizeof( szMessageFile));
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

      GETVALUE( NEPMD_INSTVALUE_ROOTDIR);
      GETVALUE( NEPMD_INSTVALUE_LANGUAGE);

      GETVALUE( NEPMD_INSTVALUE_INIT); 
      GETVALUE( NEPMD_INSTVALUE_MESSAGE);
   
      } // testcase INSTVAL

   // =========================================================================
   // testcase for WriteConfigValue
   // =========================================================================


   if (!(strcmp( pszTestcase, "CONFIGVALUE")))

      {

            PSZ               pszPath;
            PSZ               pszValue;
            CHAR              szValue[ _MAX_PATH];
            PSZ               pszFormat = "%s  ->  \"%s\"\n";

#define PROCESSVALUE(p,v)                                         \
      pszPath  = p;                                               \
      pszValue = v;                                               \
      rc = WriteConfigValue(p,v);                                 \
      if (rc)                                                     \
         break;                                                   \
      rc = QueryConfigValue( pszPath, szValue, sizeof( szValue)); \
      if (rc)                                                     \
         break;                                                   \
      printf( pszFormat, pszPath, szValue);

      // write and read all keys
      do
         { // write complete new ekyes
         PROCESSVALUE( "\\NEPMD\\Testcases\\MyContainer\\MyKey",       "My first value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases\\My2ndContainer\\MyKey",    "My second value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases\\My3rdContainer\\My3rdKey", "My third value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases2\\2ndcase",                 "this is a different case");

         // write a ney key to all existant path
         PROCESSVALUE( "\\NEPMD\\Testcases\\MyContainer\\AdditionalKey",  "Additional value");

         // write a new key in the middle of an existand path
         PROCESSVALUE( "\\NEPMD\\Testcases\\AdditionalCase",  "Additional value 2");

         // write a new key to be deleted
         pszPath = "\\NEPMD\\Testcases\\KeyToDelete";
         PROCESSVALUE( pszPath, "Value to be deleted");
         rc = DeleteConfigValue( pszPath);
         printf( "Key deleted, rc=%u\n", rc);

         } while (FALSE);

      if (rc)
         printf( "\n\nerror: cannot write value for: %s\n", pszPath);

      } // testcase CONFIGVALUE



   } while (FALSE);



return rc;

}

