/****************************** Module Header *******************************
*
* Module Name: test.c
*
* little test app to test selected functions of common.lib
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: test.c,v 1.30 2002-10-19 14:51:27 cla Exp $
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
#include "hilite.h"
#include "mmf.h"
#include "mode.h"

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
            HCONFIG           hconfig = NULLHANDLE;
            CHAR           szInifile[ _MAX_PATH];
            PSZ               pszPath;
            PSZ               pszValue;
            CHAR              szValue[ _MAX_PATH];
            PSZ               pszFormat = "%s  ->  \"%s\"\n\n";

#define PROCESSVALUE(p,v)                                         \
      pszPath  = p;                                               \
      pszValue = v;                                               \
      rc = WriteConfigValue( hconfig, p,v);                       \
      if (rc)                                                     \
         break;                                                   \
      rc = QueryConfigValue( hconfig, pszPath, szValue, sizeof( szValue)); \
      if (rc)                                                     \
         break;                                                   \
      printf( pszFormat, pszPath, szValue);

      // write and read all keys
      do
         {
         // determine name of INI
         rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szInifile, sizeof( szInifile));
         if (rc = NO_ERROR)
            break;

         // open profile
         rc = OpenConfig( &hconfig, szInifile);
         printf( "open configurarion: rc=%u, handle=0x%x\n\n", rc, hconfig);
         if (rc != NO_ERROR)
            break;

         // initialize it
         rc = InitConfig( hconfig, "..\\..\\netlabs\\bin\\defaults.dat");
         printf( "initializing config: rc=%u\n", rc);
         if (rc != NO_ERROR)
            break;

         // write complete new kyes
         PROCESSVALUE( "\\NEPMD\\Testcases\\My2ndContainer\\MyKey",    "My second value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases\\MyContainer\\MyKey",       "My first value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases\\My3rdContainer\\My3rdKey", "My third value is this !");
         PROCESSVALUE( "\\NEPMD\\Testcases2\\2ndcase",                 "this is a different case");

         // write a ney key to all existant path
         PROCESSVALUE( "\\NEPMD\\Testcases\\MyContainer\\AdditionalKey",  "Additional value");

         // write a new key in the middle of an existant path, name includes a space
         PROCESSVALUE( "\\NEPMD\\Testcases\\Additional Case",  "Additional value 2");

         // add keys to test case sensitive handling in container lists
         PROCESSVALUE( "\\NEPMD\\CaseTest\\THISISACASE",  "value");
         PROCESSVALUE( "\\NEPMD\\CaseTest\\thisisacase",  "value");
         PROCESSVALUE( "\\NEPMD\\CaseTest\\ThisIsACase",  "value");
         PROCESSVALUE( "\\NEPMD\\CaseTest\\CaseContainer\\SubValue", "value");

         // write a new key to be deleted, name includes a space
         pszPath = "\\NEPMD\\Testcases\\ContainerToDelete\\SubContainerToDelete\\Key To Delete";
         PROCESSVALUE( pszPath, "Value to be deleted");
         rc = DeleteConfigValue( hconfig, pszPath);
         printf( "Key deleted, rc=%u\n", rc);
         if (rc != NO_ERROR)
            break;

         // make the get next call test
         pszPath = "\\NEPMD\\CaseTest";
         szValue[ 0] = 0;
         printf( "\n\nsearch container in: %s\n", pszPath);
         do {
            // loop for the next key
            rc = GetNextConfigKey( hconfig, pszPath, szValue, "C", szValue, sizeof( szValue));
            if (rc != NO_ERROR)
               break;

            printf( "- %s\n", szValue);
            } while (  TRUE);

         szValue[ 0] = 0;
         printf( "\n\nsearch keys in: %s\n", pszPath);
         do {
            // loop for the next key
            rc = GetNextConfigKey( hconfig, pszPath, szValue, "K", szValue, sizeof( szValue));
            if (rc != NO_ERROR)
               break;

            printf( "- %s\n", szValue);

            } while (TRUE);

         if (rc == ERROR_NO_MORE_FILES)
            rc = NO_ERROR;

         } while (FALSE);

      if (rc)
         printf( "\n\nerror: cannot write value for: %s\n", pszPath);

      // cleanup
      if (hconfig)
         CloseConfig( hconfig);

      } // testcase CONFIGVALUE

   // =========================================================================
   // testcase for creating a hilite file out of the new definitions
   // =========================================================================


   if (!(strcmp( pszTestcase, "QUERYHILIGHTFILE")))

      {
               CHAR           szHiliteFile[ _MAX_PATH];
               PSZ            pszEpmMode = "C";
               BOOL           fReload;

      if (argc > 2) pszEpmMode = argv[ 2];

      // a debug message in this api already displays the returned filename
      // so no printf needed here
      rc = QueryHilightFile( pszEpmMode, &fReload, szHiliteFile, sizeof( szHiliteFile));
      if (rc != NO_ERROR)
         printf( "hilite file for mode %s could not be determined, rc=%u\n", pszEpmMode, rc);
      else
         printf( "hilite file is %s needs (reload %srequired)\n", szHiliteFile, (fReload) ? "" : "not ");

      } // testcase QUERYHILIGHTFILE

   // =========================================================================
   // testcase for selecting a mode
   // =========================================================================


   if (!(strcmp( pszTestcase, "QUERYMODE")))

      {
               CHAR           szMode[ _MAX_PATH];
               PSZ            pszFilename = "test.c";
               BYTE           abData[ 500];
               PMODEINFO      pmi = (PMODEINFO) abData;


      if (argc > 2) pszFilename = argv[ 2];

      rc = QueryFileModeInfo( pszFilename, pmi, sizeof( abData));
      if (rc != NO_ERROR)
         printf( "mode for %s is UNKNOWN (rc=%u)\n", pszFilename, rc);
      else
         printf( "mode for %s is %s\n", pszFilename, pmi->pszModeName);

      } // testcase QUERYMODE

   // =========================================================================
   // testcase for retrieving the mode list
   // =========================================================================


   if (!(strcmp( pszTestcase, "QUERYMODELIST")))

      {
               CHAR           szModeList[ _MAX_PATH];


      rc = QueryFileModeList( szModeList, sizeof( szModeList));
      if (rc != NO_ERROR)
         printf( "mode list cannot be determined (rc=%u)\n", rc);
      else
         printf( "mode list is:\n%s\n", szModeList);

      } // testcase QUERYMODELIST

   // =========================================================================
   // testcase for creating a memory mapped file
   // =========================================================================

   if (!(strcmp( pszTestcase, "MMF")))

      {
               HMMF           hmmf = NULLHANDLE;
               CHAR           szFile[ _MAX_PATH];
               PSZ            pszMemory = NULL;
               PSZ            pszFileContents = NULL;
               ULONG          ulFilesize = 32 * MMF_MAXSIZE_KB;
               ULONG          ulCurrentSize;
               ULONG          ulValue;
               ULONG          ulBytesWritten;

      do
         {
         // ----------  create in-memory only file --------------

         printf( "- initialize support for memory mapped files\n");
         rc = MmfInitialize( &hmmf, 4);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot initialize MMF support, rc=%u\n", rc);
            break;
            }

         // ----------  create in-memory only file --------------

         printf( "- allocate in-memory file\n");
         rc = MmfAlloc( hmmf, (PVOID*) &pszMemory, MMF_FILE_INMEMORY, MMF_ACCESS_READWRITE, ulFilesize);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot allocate in-memory mapped file, rc=%u\n", rc);
            break;
            }

         // set memory to all hashmarks
         memset( pszMemory, '#', ulFilesize);

         // ----------  write dummy file --------------

         // allocate test file
         sprintf( szFile, "%s\\mmftest.txt", getenv( "TMP"));
         printf( "- allocate readwrite file: %s\n", szFile);
         rc = MmfAlloc( hmmf, (PVOID*) &pszFileContents, szFile,
                        MMF_ACCESS_READWRITE | MMF_OPENMODE_RESETFILE,
                        ulFilesize);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot allocate memory mapped file %s, rc=%u\n", szFile, rc);
            break;
            }

         // access memory by copying the contents of the in-memory file
         // but leave out first 64 bytes
         printf( "- write to file area\n");
         memcpy( pszFileContents + 64, pszMemory, ulFilesize - 64);

         // query size of memory area
         rc = MmfQuerySize( hmmf, pszFileContents, &ulCurrentSize);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot query size of allocated memory for memory mapped file %s, rc=%u\n", szFile, rc);
            break;
            }
         printf( "- file area size is %u\n", ulCurrentSize);

         // update the file
         printf( "- update file\n");
         rc = MmfUpdate( hmmf, pszFileContents);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot update: %s\n", szFile);
            break;
            }

         // free memory and file again
         printf( "- free file area\n");
         rc = MmfFree( hmmf, pszFileContents);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot free memory for: %s\n", szFile);
            break;
            }

         // free memory or in-memory file
         printf( "- free in-memory file area\n");
         rc = MmfFree( hmmf, pszMemory);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot free memory of in-memory file\n", szFile);
            break;
            }

         // ----------  read config sys file --------------

         // open up config.sys
         DosQuerySysInfo( QSV_BOOT_DRIVE, QSV_BOOT_DRIVE, &ulValue,  sizeof( ulValue));
         sprintf( szFile, "%c:\\config.sys", (CHAR) ulValue + 'A' - 1);
         printf( "- allocate readonly file: %s\n", szFile);
         rc = MmfAlloc( hmmf, (PVOID*) &pszFileContents, szFile, MMF_ACCESS_READONLY, 1024*1024);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot allocate memory mapped file %s, rc=%u\n", szFile, rc);
            break;
            }

         // display length of config.sys
         printf( "- contents of file is %u bytes long\n", strlen( pszFileContents));

         // free memory and file again
         rc = MmfFree( hmmf, pszFileContents);
         if (rc != NO_ERROR)
            {
            printf( " error: cannot free memory for: %s\n", szFile);
            break;
            }

         }  while (FALSE);

      // cleanup
      if (hmmf)
         MmfTerminate( hmmf);

      } // testcase MMF


   } while (FALSE);



return rc;

}

