/****************************** Module Header *******************************
*
* Module Name: epmenv.c
*
* Generic routine to load the NEPMD environment file for
* EPM and NEPDM utilities
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmenv.c,v 1.17 2003-12-30 21:24:10 cla Exp $
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
#include "instval.h"

#include "epmenv.h"

// -----------------------------------------------------------------------------

static APIRET _searchEpmExecutable( PSZ pszEpmExecutable, ULONG ulBuflen,
                                    PSZ pszLoaderExecutable, ULONG ulLoaderBuflen)
{
         APIRET         rc  = NO_ERROR;
         PPIB           ppib;
         PTIB           ptib;
         ULONG          ulBootDrive;


         BOOL           fFound = FALSE;
         PSZ            pszPath = getenv( "PATH");
         PSZ            pszCopy = NULL;
         PSZ            pszDir;
         CHAR           szExecutable[ _MAX_PATH];

         CHAR           szThisModule[ _MAX_PATH];
         CHAR           szNepmdModule[ _MAX_PATH];
         CHAR           szInstalledModule[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszEpmExecutable) ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check env
   if (!pszPath)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }

   // get name of own module
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szThisModule), szThisModule);

   // get name of epm.exe in OS/2 directory
   // this is used by installed NEPMD
   DosQuerySysInfo( QSV_BOOT_DRIVE, QSV_BOOT_DRIVE, &ulBootDrive, sizeof( ULONG));
   sprintf( szInstalledModule, "%c:\\OS2\\EPM.EXE", (CHAR) ulBootDrive + 'A' - 1);

   // get name of EPM.EXE in NEPMD path
   memset( szNepmdModule, 0, sizeof( szNepmdModule));
   rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, szNepmdModule, sizeof( szNepmdModule));
   if (rc == NO_ERROR)
      {
      strcat( szNepmdModule, "\\"NEPMD_SUBPATH_BINBINDIR"\\epm.exe");
      strupr( szNepmdModule);
      }
   else
      {
      // don't report error from here
      rc = NO_ERROR;

      // copy pathname of installed EPM fullname here in order
      // not to break the filename comparison scheme below
      strcpy( szNepmdModule, szInstalledModule);

      }

   // create copy to allow modification
   pszCopy = strdup( pszPath);
   if (!pszCopy)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   pszDir = strtok( pszCopy, ";");
   while (pszDir)
      {
      // create fullname for entry to check
      strcpy( szExecutable, pszDir);
      if (*(pszDir + strlen( pszDir) - 1) != '\\')
         strcat( szExecutable, "\\");
      strcat( szExecutable, "epm.exe");
      rc = DosQueryPathInfo( szExecutable, FIL_QUERYFULLNAME, szExecutable, sizeof( szExecutable));
      strupr( szExecutable);
      if (rc == NO_ERROR)
         {
         // file must exist
         if (FileExists( szExecutable))
            {
            // process only modules not being the current one or of NEPMD bin directory
            if ((strcmp( szExecutable, szThisModule)) &&
                (strcmp( szExecutable, szNepmdModule)) &&
                (strcmp( szExecutable, szInstalledModule)))
               {
               // executable found
               fFound = TRUE;
               break;
               }
            }
         }
      else
         rc = NO_ERROR;

      // next please
      pszDir = strtok( NULL, ";");
      }
   if (!fFound)
      {
      rc = ERROR_FILE_NOT_FOUND;
      break;
      }

   // hand over results
   if (strlen( szExecutable) + 1 > ulBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszEpmExecutable, szExecutable);

   if (strlen( szThisModule) + 1 > ulBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszLoaderExecutable, szThisModule);

   } while (FALSE);

// cleanup
if (pszCopy) free( pszCopy);
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _searchNepmdEnvironmentFiles( PSZ pszMainEnvFile, ULONG ulMainBuflen,
                                            PSZ pszUserEnvFile, ULONG ulUserBuflen)
{
         APIRET         rc  = NO_ERROR;
         BOOL           fFound = FALSE;
         PPIB           ppib;
         PTIB           ptib;

         CHAR           szExecutablePath[ _MAX_PATH];
         CHAR           szBasename[ _MAX_PATH];
         CHAR           szNepmdPath[ _MAX_PATH];
         ULONG          ulDataLen;
         BOOL           fNepmdPathFound = FALSE;
         CHAR           szCurrentPath[ _MAX_PATH];

         CHAR           szMainEnvFile[ _MAX_PATH];
         CHAR           szUserEnvFile[ _MAX_PATH];

static  PSZ            pszNepmdExecDirMask = "%s\\"NEPMD_SUBPATH_BINBINDIR"\\%s"NEPMD_FILENAMEEXT_ENV;
static  PSZ            pszMyEpmExecDirMask = "%s\\"NEPMD_SUBPATH_MYBINDIR"\\%s"NEPMD_FILENAMEEXT_ENV;

do
   {
   // check parms
   if ((!pszMainEnvFile) ||
       (!pszUserEnvFile) ||
       (!ulMainBuflen)   ||
       (!ulUserBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init vars
   memset( pszMainEnvFile, 0, ulMainBuflen);
   memset( pszUserEnvFile, 0, ulUserBuflen);

   // get own filename to isolate basename of executable
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szExecutablePath), szExecutablePath);
   strcpy( szBasename, strrchr( szExecutablePath, '\\')  + 1);
   strcpy( strrchr( szBasename, '.'), "");

   // isolate path of executabe
   strcpy( strrchr( szExecutablePath, '\\'), "");

   // get NEPMD install directory
   rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, szNepmdPath, sizeof( szNepmdPath));
   fNepmdPathFound =  (rc == NO_ERROR);

   // ----- check for main env file loaded

   do
      {
      // <executable_path>\<exename>.env
      sprintf( szMainEnvFile, "%s\\%s"NEPMD_FILENAMEEXT_ENV, szExecutablePath, szBasename);
      DPRINTF(( "EPMENV: search main envfile: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;

      if (fNepmdPathFound)
         {
         // <nepmd_rootdir>\netlabs\<exename>.env
         sprintf( szMainEnvFile, pszNepmdExecDirMask, szNepmdPath, szBasename);
         DPRINTF(( "EPMENV: search main envfile: %s\n", szMainEnvFile));
         if (fFound = FileExists( szMainEnvFile))
            break;

         // <nepmd_rootdir>\netlabs\epm.env
         sprintf( szMainEnvFile, pszNepmdExecDirMask, szNepmdPath, "epm");
         DPRINTF(( "EPMENV: search main envfile: %s\n", szMainEnvFile));
         if (fFound = FileExists( szMainEnvFile))
            break;
         }
      else
         DPRINTF(( "EPMENV: NEPMD not installed, skip main env file\n"));

      } while (FALSE);

   // delete filename if not found
   if (!fFound)
      szMainEnvFile[ 0] = 0;

   // ----- check for user env file loaded

   do
      {
      // <currentdir>\<exename>.env
      sprintf( szUserEnvFile, "%s"NEPMD_FILENAMEEXT_ENV, szBasename);
      DPRINTF(( "EPMENV: search user envfile: %s\n", szUserEnvFile));
      if (fFound = FileExists( szUserEnvFile))
         break;

      if (fNepmdPathFound)
         {
         // <nepmd_rootdir>\myepm\<exename>.env
         sprintf( szUserEnvFile, pszMyEpmExecDirMask, szNepmdPath, szBasename);
         DPRINTF(( "EPMENV: search user envfile: %s\n", szUserEnvFile));
         if (fFound = FileExists( szUserEnvFile))
            break;

         // <nepmd_rootdir>\myepm\epm.env
         sprintf( szUserEnvFile, pszMyEpmExecDirMask, szNepmdPath, "epm");
         DPRINTF(( "EPMENV: search user envfile: %s\n", szUserEnvFile));
         if (fFound = FileExists( szUserEnvFile))
            break;
         }
      else
         DPRINTF(( "EPMENV: NEPMD not installed, skip user env file\n"));

      } while (FALSE);


   // delete filename if not found
   if (!fFound)
      szUserEnvFile[ 0] = 0;

   // error if not found
   if ((!strlen( szMainEnvFile)) && (!strlen( szUserEnvFile)))
      {
      rc = ERROR_FILE_NOT_FOUND;
      break;
      }

   // hand over result
   if (strlen( szMainEnvFile) + 1 > ulMainBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }
   if (strlen( szUserEnvFile) + 1 > ulUserBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }


   strcpy( pszMainEnvFile, szMainEnvFile);
   strcpy( pszUserEnvFile, szUserEnvFile);
   DPRINTF(( "EPMENV: main envfile is: %s\n", strlen( pszMainEnvFile) ? pszMainEnvFile : "<none>"));
   DPRINTF(( "EPMENV: user envfile is: %s\n", strlen( pszUserEnvFile) ? pszUserEnvFile : "<none>"));

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

static PSZ _copyname( PSZ pszBuffer, PSZ pszCurrent, PSZ pszEntry)
{
         BOOL           fFound = FALSE;
         PSZ            p;
         ULONG          ulNameLen;
         CHAR           szName[ 128];

if (!pszEntry)
   return pszCurrent;

// copy name to allow proper check with strcmp
// (strncmp does not work properly here, finds LIB in LIBPATH etc)
p = strchr( pszEntry, '=');
if (!p)
   return pszCurrent;

ulNameLen = p - pszEntry;
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
// DPRINTF(( "EPMENV: var moved: %s ", pszEntry));
   memcpy( p, p + ulNameLen + 1, pszCurrent - p);
   pszCurrent -= ulNameLen + 1;
   }
else
   {
// DPRINTF(( "EPMENV: var added: %s ", pszEntry));
   }

// copy current name to the end
strcpy( pszCurrent, szName);
return NEXTSTR( pszCurrent);
}

//      #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

#define ADDVAR(e) {ulEnvSize += strlen( e) + 1; \
                   pszName = _copyname( pszEnvNameList, pszName, e); \
                   putenv( e);}
#define ADDVARX(e) {*pulEnvSize += strlen( e) + 1; \
                   *ppszName = _copyname( pszEnvNameList, *ppszName, e); \
                   putenv( e);}


static APIRET _readEnvFile( PSZ szEnvFile, PULONG pulEnvSize, PSZ *ppszName, PSZ pszEnvNameList)
{
         APIRET         rc  = NO_ERROR;
         ULONG          i;

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
            DPRINTF(( "EPMENV: added: %s\n", pszNewLine));
            ADDVARX( pszNewLine);
            }
         else
            DPRINTF(( "EPMENV: ERROR: cannot expand \"%s\"\n", pszLine));

         } while (FALSE);


      // next please
      pszLine = strtok( NULL, pszDelimiters);
      }

   } while (FALSE);


// cleanup
if (hfile) DosClose( hfile);
if (pszData) free( pszData);
return rc;
}

//      #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #

APIRET GetExtendedEPMEnvironment( PSZ envv[], PSZ *ppszNewEnv, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         ULONG          i;

         CHAR           szMainEnvFile[ _MAX_PATH];
         CHAR           szUserEnvFile[ _MAX_PATH];

         CHAR           szEpmExecutable[ _MAX_PATH];
         CHAR           szLoaderExecutable[ _MAX_PATH];

         CHAR           szInstallVar[ _MAX_PATH + 30];
         PSZ            apszVar[ 6]; // increase size of array of more vars required !!!

         PSZ           *ppszEnv;
         PSZ            pszVar;
         PSZ            pszName;
         PSZ            pszValue;

         ULONG          ulEnvSize;
         PSZ            pszEnvNameList = NULL;
         PSZ            pszEnv = NULL;


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

   // search loader executable and EPM executable
   szEpmExecutable[ 0] = 0;
   szLoaderExecutable[ 0] = 0;
   rc = _searchEpmExecutable( szEpmExecutable,    sizeof( szEpmExecutable),
                              szLoaderExecutable, sizeof(  szLoaderExecutable));

   // hand over name of executable, if buffer supplied
   if (pszBuffer)
      {
      // if executable is requested, react on error
      if (rc != NO_ERROR)
         break;

      if (strlen( szEpmExecutable) + 1 > ulBuflen)
         {
         rc = ERROR_BUFFER_OVERFLOW;
         break;
         }
      DPRINTF(( "found executable: %s\n", szEpmExecutable));
      strcpy( pszBuffer, szEpmExecutable);
      }

   // check if extended environment is already set
   pszValue = getenv( ENV_NEPMD_USERENVFILE);
   if ((!pszValue) || (!*pszValue))
      pszValue = getenv( ENV_NEPMD_MAINENVFILE);
   if ((pszValue) && (*pszValue))
      {
      DPRINTF(( "EPMENV: skip environment extension, already set with: %s\n", pszValue));
      break;
      }

   // ------- ------------------------------------------

   // search environment file - ignore errors !
   _searchNepmdEnvironmentFiles( szMainEnvFile, sizeof( szMainEnvFile),
                                 szUserEnvFile,  sizeof( szUserEnvFile));

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
   rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, _EOS( szInstallVar), _EOSSIZE( szInstallVar));
   if (rc == NO_ERROR)
      {
      apszVar[ 0] = strdup( szInstallVar);
      ADDVAR( apszVar[ 0]);
      }
   else
      // don't report error from here
      rc = NO_ERROR;

   // --- > set environment variable for NEPMD language
   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=", ENV_NEPMD_LANGUAGE);
   QueryInstValue( NEPMD_INSTVALUE_LANGUAGE, _EOS( szInstallVar), _EOSSIZE( szInstallVar));
   apszVar[ 1] = strdup( szInstallVar);
   ADDVAR( apszVar[ 1]);

   // --- > set environment variables  for env files
   if (strlen( szMainEnvFile))
      {
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=%s", ENV_NEPMD_MAINENVFILE, szMainEnvFile);
      apszVar[ 2] = strdup( szInstallVar);
      ADDVAR( apszVar[ 2]);
      }

   if (strlen( szMainEnvFile))
      {
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=%s", ENV_NEPMD_USERENVFILE, szUserEnvFile);
      apszVar[ 3] = strdup( szInstallVar);
      ADDVAR( apszVar[ 3]);
      }

   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=%s", ENV_NEPMD_EPMEXECUTABLE, szEpmExecutable);
   apszVar[ 4] = strdup( szInstallVar);
   ADDVAR( apszVar[ 4]);

   memset( szInstallVar, 0, sizeof( szInstallVar));
   sprintf( szInstallVar, "%s=%s", ENV_NEPMD_LOADEREXECUTABLE, szLoaderExecutable);
   apszVar[ 5] = strdup( szInstallVar);
   ADDVAR( apszVar[ 5]);

   // ------- ------------------------------------------

   // read env files
   if (strlen( szMainEnvFile)) _readEnvFile( szMainEnvFile, &ulEnvSize, &pszName, pszEnvNameList);
   if (strlen( szUserEnvFile)) _readEnvFile( szUserEnvFile, &ulEnvSize, &pszName, pszEnvNameList);

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

      // copy next var
      pszVar = NEXTSTR( pszVar);
      pszName = NEXTSTR( pszName);
      }
   *pszVar = 0;

   // hand over result
   *ppszNewEnv = pszEnv;

   } while (FALSE);


// cleanup on error
if (rc)
   if (pszEnv) free( pszEnv);
if (pszEnvNameList) free( pszEnvNameList);
// cleanup
for (i = 0; i < (sizeof( apszVar) / sizeof( PSZ)); i++)
   {
   if (apszVar[ i]) free( apszVar[ i]);
   }
return rc;
}

