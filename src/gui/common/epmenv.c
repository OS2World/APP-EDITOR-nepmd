/****************************** Module Header *******************************
*
* Module Name: epmenv.c
*
* Generic routine to load the NEPMD environment file for
* EPM and NEPDM utilities
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmenv.c,v 1.1 2002-08-13 21:04:34 cla Exp $
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
#include "file.h"
#include "nepmd.h"

// -----------------------------------------------------------------------------

static APIRET _searchNepmdEnvironmentFile( PSZ pszEnvfile, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         BOOL           fFound = FALSE;
         PPIB           ppib;
         PTIB           ptib;

         CHAR           szExecutable[ _MAX_PATH];
         CHAR           szBasename[ _MAX_PATH];

         CHAR           szFilePath[ _MAX_PATH];
         ULONG          ulDataLen;

         CHAR           szEnvfile[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszEnvfile) ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }


   // get own filename to isolate exe name
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szExecutable), szExecutable);
   strcpy( szBasename, strrchr( szExecutable, '\\')  + 1);
   strcpy( strrchr( szBasename, '.'), ".env");

   // isolate path of executabe
   strcpy( strrchr( szExecutable, '\\'), "");

   // get NEPMD install directory
   ulDataLen = PrfQueryProfileString( HINI_USER,
                                      NEPMD_INI_APPNAME,
                                      NEPMD_INI_KEYNAME_PATH,
                                      NULL,
                                      szFilePath,
                                      sizeof( szFilePath));

   if (ulDataLen)
      {
      // handle also non-zero-terminated strings
      szFilePath[ ulDataLen] = 0;

      // determine complete filename
      sprintf( szEnvfile, "%s\\"NEPMD_SUBPATH_BINBINDIR"\\%s", szFilePath, szBasename);
      fFound = (FileExists( szEnvfile));
      }

   if (!fFound)
      {
      // nothing stored or no config found in install tree - use path of executable
      sprintf( szEnvfile, "%s\\%s", szExecutable, szBasename);
      }


   // hand over result
   if (strlen( szEnvfile) + 1 > ulBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszEnvfile, szEnvfile);
   DPRINTF(( "EPMCALL: envfile is %s\n", szEnvfile));

   } while (FALSE);

return rc;
}


// -----------------------------------------------------------------------------

static PSZ _expandEnvVar( PSZ pszStr)
{
         PSZ      pszResult = NULL;

         PSZ      pszNewValue;

         PSZ      pszStartPos;
         PSZ      pszEndPos;

         CHAR     szVarName[ 128];
         ULONG    ulNameLen;
         PSZ      pszVarValue;

         PSZ      pszNewResult;
         ULONG    ulNewResultLen;

static   CHAR     chDelimiter = '%';

do
   {
   // check parms
   if (!pszStr)
      break;

   // create a copy
   pszResult = strdup( pszStr);
   if (!pszResult)
      break;

   // maintain the copy
   pszStartPos = strchr( pszResult, chDelimiter);
   while (pszStartPos)
      {
      // find end
      pszEndPos = strchr( pszStartPos + 1, chDelimiter);

      // no end found, cut of to end of string
      if (!pszEndPos)
         {
         *pszStartPos = 0;
         break;
         }
      else
         {
         // isolate name
         ulNameLen = pszEndPos - pszStartPos - 1;
         memcpy( szVarName, pszStartPos + 1, ulNameLen);
         szVarName[ ulNameLen] = 0;


         // first of all, elimintate the variable
         strcpy( pszStartPos, pszEndPos + 1);

         // get value
         pszVarValue = getenv( szVarName);
         if (pszVarValue)
            {
            // embedd new value
            pszNewResult = malloc( strlen( pszResult) + 1 + strlen( pszVarValue));
            if (pszNewResult)
               {
               strcpy( pszNewResult, pszResult);
               strcpy( pszNewResult + (pszStartPos - pszResult), pszVarValue);
               strcat( pszNewResult, pszStartPos);
               free( pszResult);
               pszResult = pszNewResult;
               }
            else
               {
               // kick any result, as we are out of memory
               free( pszResult);
               pszResult = NULL;
               break;
               }
            }
         }

      // next var please
      pszStartPos = strchr( pszResult, chDelimiter);
      }


   } while (FALSE);

return pszResult;
}

// -----------------------------------------------------------------------------

PSZ _copyname( PSZ pszBuffer, PSZ pszCurrent, PSZ pszEntry)
{
         BOOL           fFound = FALSE;
         PSZ            p;
         ULONG          ulNameLen;
         CHAR           szName[ 128];

if (!pszEntry)
   return pszCurrent;

// copy name to allow proper check with strcmp
// (strncmp does not work properly here, finds LIB in LIBPATH etc)
ulNameLen = strchr( pszEntry, '=') - pszEntry;
strncpy( szName, pszEntry, ulNameLen);
szName[ ulNameLen] = 0;


// check if name is already included
p = pszBuffer;
while (*p)
   {
   if (!strcmp( p, szName))
      {
      fFound = TRUE;
      break;
      }
   p = NEXTSTR( p);
   }

if (fFound)
   {
   // move whole block and thus eliminate old entry
// DPRINTF(( "var moved: %s ", pszEntry));
   memcpy( p, p + ulNameLen + 1, pszCurrent - p);
   pszCurrent -= ulNameLen + 1;
   }
else
   {
// DPRINTF(( "var added: %s ", pszEntry));
   }

// copy current name to the end
strcpy( pszCurrent, szName);
return NEXTSTR( pszCurrent);
}

#define ADDVAR(e) {ulEnvSize += strlen( e) + 1; \
                   pszName = _copyname( pszEnvNameList, pszName, e); \
                   putenv( e);}

//      ------------------------------------------

APIRET GetExtendedEPMEnvironment( PSZ envv[], PSZ *ppszNewEnv)
{
         APIRET         rc  = NO_ERROR;
         ULONG          i;

         CHAR           szEnvFile[ _MAX_PATH];

         CHAR           szInstallVar[ _MAX_PATH + 30];
         PSZ            apszVar[ 3]; // increase size of array of more vars required !!!

         PSZ           *ppszEnv;
         PSZ            pszVar;
         PSZ            pszName;
         PSZ            pszValue;

         ULONG          ulEnvSize;
         PSZ            pszEnvNameList = NULL;
         PSZ            pszEnv = NULL;

         FILESTATUS3    fs3;
         ULONG          ulFileSize;
         PSZ            pszData = NULL;
         HFILE          hfile = NULLHANDLE;
         ULONG          ulAction;
         ULONG          ulBytesRead;

         PSZ            pszLine;
         PSZ            pszNewLine;
static   PSZ            pszDelimiters = "\r\n";

do
   {
   // init vars
   memset( apszVar, 0, sizeof( apszVar));

   // check parms
   if ((!ppszNewEnv) ||
       (!envv))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // default to make no changes
   *ppszNewEnv = NULL;

   // if extended environment is already set, don't touch
   pszValue = getenv( ENV_NEPMD_ENVFILE);
   if (pszValue)
      {
      DPRINTF(( "skip environment extension, already set with: %s\n", pszValue));
      break;
      }

   // search environment file
  rc = _searchNepmdEnvironmentFile( szEnvFile, sizeof( szEnvFile));
   if (rc != NO_ERROR)
      break;

   // ------- get name list ----------------------------

   // get size of envnames provided
   // for simplicity use env size as we add vars anyway

   ppszEnv = envv;
   ulEnvSize = 0;
   while (*ppszEnv)
      {
      ulEnvSize += strlen( *ppszEnv) + 1;
      ppszEnv++;
      }
   ulEnvSize += 1;
// DPRINTF(( "unmodified env size is: %u\n", ulEnvSize));

   // get memory for name list
   pszEnvNameList = malloc( ulEnvSize);
   if (!pszEnvNameList)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszEnvNameList , 0x0, ulEnvSize);

   ppszEnv = envv;
   pszName = pszEnvNameList;
   while (*ppszEnv)
      {
      // copy var
      pszName = _copyname( pszEnvNameList, pszName, *ppszEnv);

      // copy next var
      ppszEnv++;
      }

   // ------- ------------------------------------------


   // -------- set internal var(s) first, use a different buffer for each
   //          as putvar only passes a pointer to the environment list !!!

   // --- > set environment variable for NEPMD install directory
   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=", ENV_NEPMD_PATH);
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_PATH,
                          NULL,
                          _EOS(szInstallVar),
                          _EOSSIZE( szInstallVar));
   apszVar[ 0] = strdup( szInstallVar);
   ADDVAR( apszVar[ 0]);


   // --- > set environment variable for NEPMD language
   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=", ENV_NEPMD_LANGUAGE);
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_LANGUAGE,
                          NULL,
                          _EOS(szInstallVar),
                          _EOSSIZE( szInstallVar));
   apszVar[ 1] = strdup( szInstallVar);
   ADDVAR( apszVar[ 1]);

   // --- > set environment variable  for env file
   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=%s", ENV_NEPMD_ENVFILE, szEnvFile);
   apszVar[ 2] = strdup( szInstallVar);
   ADDVAR( apszVar[ 2]);

   // ------- ------------------------------------------

   // check file
   if (FileExists( szEnvFile))
      {
      // get memory
      rc = DosQueryPathInfo( szEnvFile, FIL_STANDARD, &fs3, sizeof( fs3));
      if (rc != NO_ERROR)
         break;
      ulFileSize = fs3.cbFile;
      pszData = malloc( ulFileSize + 1);
      if (!pszData)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      memset( pszData, 0, ulFileSize + 1);


      // read file
      rc = DosOpen( szEnvFile, &hfile, &ulAction, 0, 0,
                    OPEN_ACTION_FAIL_IF_NEW | OPEN_ACTION_OPEN_IF_EXISTS,
                    OPEN_ACCESS_READONLY | OPEN_SHARE_DENYWRITE,
                    NULL);
      if (rc != NO_ERROR)
         break;

      rc = DosRead( hfile, pszData, ulFileSize, &ulBytesRead);
      if (rc != NO_ERROR)
         break;
      if (ulFileSize != ulBytesRead)
         {
         rc = ERROR_READ_FAULT;
         break;
         }

      // go through all lines
      pszLine = strtok( pszData, pszDelimiters);
      while (pszLine)
         {
         do
            {
            // skip line without equal sign: no env set here
            if (!strchr( pszLine, '='))
               break;

            // skip comment lines
            if (*pszLine == ':')
               break;

            // add line to env
            pszNewLine = _expandEnvVar( pszLine);
            if (pszNewLine)
               {
               DPRINTF(( "env added: %s\n", pszNewLine));
               ADDVAR( pszNewLine);
               }
            else
               DPRINTF(( "ERROR: cannot expand \"%s\"\n", pszLine));

            } while (FALSE);


         // next please
         pszLine = strtok( NULL, pszDelimiters);
         }

      }

   // close name list
   *pszName = 0;

   // get memory with updated env size
// DPRINTF(( "estimated new size is: %u\n", ulEnvSize));
   pszEnv = malloc( ulEnvSize);
   if (!pszEnv)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszEnv, 0x0, ulEnvSize);

   // read env into memory block
   pszName = pszEnvNameList;
   pszVar = pszEnv;
   while (*pszName)
      {
      // copy var
      sprintf( pszVar, "%s=%s",  pszName, getenv( pszName));
//    DPRINTF(( "copyenv (%u):%s\n", pszVar - pszEnv, pszVar));

      // copy next var
      pszVar = NEXTSTR( pszVar);
      pszName = NEXTSTR( pszName);
      }
   *pszVar = 0;
// DPRINTF(( "used env size is: %u\n", pszVar - pszEnv));

   // hand over result
   *ppszNewEnv = pszEnv;

   } while (FALSE);


// cleanup on error
if (rc)
   if (pszEnv) free( pszEnv);
if (pszEnvNameList) free( pszEnvNameList);
// cleanup
if (hfile) DosClose( hfile);
if (pszData) free( pszData);
for (i = 0; i < (sizeof( apszVar) / sizeof( PSZ)); i++)
   {
   if (apszVar[ i]) free( apszVar[ i]);
   }
return rc;
}

