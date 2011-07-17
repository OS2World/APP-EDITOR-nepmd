/****************************** Module Header *******************************
*
* Module Name: epmenv.c
*
* Generic routine to load the NEPMD environment file for EPM and NEPMD
* utilities
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

#define __APPNAMESHORT__ "NEPMD"

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
// Added to get the loader before the environment was extended.
static APIRET _searchLoaderExecutable( PSZ pszLoaderExecutable, ULONG ulLoaderBuflen)
{
         APIRET         rc  = NO_ERROR;
         PPIB           ppib;
         PTIB           ptib;

         CHAR           szThisModule[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszLoaderExecutable) ||
       (!ulLoaderBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get name of own module
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szThisModule), szThisModule);

   if (strlen( szThisModule) + 1 > ulLoaderBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszLoaderExecutable, szThisModule);

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static APIRET _searchNepmdEnvironmentFiles( PSZ pszMainEnvFile, ULONG ulMainBuflen,
                                            PSZ pszAddEnvFile, ULONG ulAddBuflen)
{
         APIRET         rc  = NO_ERROR;
         BOOL           fFound = FALSE;
         PPIB           ppib;
         PTIB           ptib;

         CHAR           szExecutablePath[ _MAX_PATH];
         CHAR           szBasename[ _MAX_PATH];
         CHAR           szRootDir[ _MAX_PATH];
         CHAR           szUserDir[ _MAX_PATH];
         ULONG          ulDataLen;
         BOOL           fRootDirFound = FALSE;
         BOOL           fUserDirFound = FALSE;
         CHAR           szCurrentPath[ _MAX_PATH];

         CHAR           szMainEnvFile[ _MAX_PATH];
         CHAR           szAddEnvFile[ _MAX_PATH];

         CHAR           szMessage[ 1024];

static   PSZ            pszDefaultExecBaseName   = "epm";
static   PSZ            pszMyDefaultExecBaseName = "myepm";

static   PSZ            pszNepmdExecDirMask = "%s\\"NEPMD_SUBPATH_BINBINDIR"\\%s"NEPMD_FILENAMEEXT_ENV;
static   PSZ            pszUserExecDirMask  = "%s\\"NEPMD_SUBPATH_USERBINDIR"\\%s"NEPMD_FILENAMEEXT_ENV;

do
   {
   // check parms
   if ((!pszMainEnvFile) ||
       (!pszAddEnvFile) ||
       (!ulMainBuflen)   ||
       (!ulAddBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init vars
   memset( pszMainEnvFile, 0, ulMainBuflen);
   memset( pszAddEnvFile, 0, ulAddBuflen);

   // get own filename to isolate basename of executable
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szExecutablePath), szExecutablePath);
   strcpy( szBasename, strrchr( szExecutablePath, '\\')  + 1);
   strcpy( strrchr( szBasename, '.'), "");

   // isolate path of executabe
   strcpy( strrchr( szExecutablePath, '\\'), "");

   // get NEPMD install directories
   rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, szRootDir, sizeof( szRootDir));
   fRootDirFound =  (rc == NO_ERROR);
   rc = QueryInstValue( NEPMD_INSTVALUE_USERDIR, szUserDir, sizeof( szUserDir));
   fUserDirFound =  (rc == NO_ERROR);

   // ----- check for main env file loaded

   do
      {
      // reset rc here
      rc == NO_ERROR;

      if (!fRootDirFound)
         {
         rc = ERROR_PATH_NOT_FOUND;
         sprintf( szMessage,
                  "Fatal error: RootDir could not be determined.\n\n"
                  "NEPMD is not properly installed,"
                  " repeat the installation via WarpIN!\n\n"
                  "If that problem still persists, check"
                  " NEPMD -> RootDir in OS2.INI.\n\n");
         SHOWFATALERROR( HWND_DESKTOP, szMessage);
         break;
         }

      if (!fUserDirFound)
         {
         sprintf( szMessage,
                  "Fatal error: UserDir could not be determined.\n\n"
                  "NEPMD is not properly installed,"
                  " repeat the installation via WarpIN!\n\n"
                  "If that problem still persists, check"
                  " if your UserDir (e.g. NEPMD\\myepm)"
                  " exists and is writable.\n\n");
         SHOWFATALERROR( HWND_DESKTOP, szMessage);
         break;
         }

      // <nepmd_userdir>\bin\<exename>.env
      sprintf( szMainEnvFile, pszUserExecDirMask, szUserDir, szBasename);
      //DPRINTF(( "EPMENV: search main env file: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;

      // <nepmd_userdir>\bin\epm.env
      sprintf( szMainEnvFile, pszUserExecDirMask, szUserDir, pszDefaultExecBaseName);
      //DPRINTF(( "EPMENV: search main env file: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;

      // <executable_path>\<exename>.env
      sprintf( szMainEnvFile, "%s\\%s"NEPMD_FILENAMEEXT_ENV, szExecutablePath, szBasename);
      //DPRINTF(( "EPMENV: search main env file: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;

      // <nepmd_rootdir>\netlabs\bin\<exename>.env
      sprintf( szMainEnvFile, pszNepmdExecDirMask, szRootDir, szBasename);
      //DPRINTF(( "EPMENV: search main env file: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;

      // <nepmd_rootdir>\netlabs\bin\epm.env
      sprintf( szMainEnvFile, pszNepmdExecDirMask, szRootDir, pszDefaultExecBaseName);
      //DPRINTF(( "EPMENV: search main env file: %s\n", szMainEnvFile));
      if (fFound = FileExists( szMainEnvFile))
         break;


      } while (FALSE);

   // delete filename if not found
   if (!fFound)
      szMainEnvFile[ 0] = 0;

   // ----- check for additional env file loaded

   do
      {
      // <nepmd_userdir>\bin\myepm.env
      sprintf( szAddEnvFile, pszUserExecDirMask, szUserDir, pszMyDefaultExecBaseName);
      //DPRINTF(( "EPMENV: search additional env file: %s\n", szAddEnvFile));
      if (fFound = FileExists( szAddEnvFile))
         break;
      } while (FALSE);


   // delete filename if not found
   if (!fFound)
      szAddEnvFile[ 0] = 0;

   // error if not found
   if (!strlen( szMainEnvFile))
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
   if (strlen( szAddEnvFile) + 1 > ulAddBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   strcpy( pszMainEnvFile, szMainEnvFile);
   strcpy( pszAddEnvFile, szAddEnvFile);
   DPRINTF(( "EPMENV: main envfile is: %s\n", strlen( pszMainEnvFile) ? pszMainEnvFile : "<none>"));
   DPRINTF(( "EPMENV: add. envfile is: %s\n", strlen( pszAddEnvFile) ? pszAddEnvFile : "<none>"));

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

PSZ _queryExtLIBPATH( PSZ pBuffer, ULONG ulWhichPath)
{
   APIRET  rc;
   rc = DosQueryExtLIBPATH( pBuffer, ulWhichPath);
   return ((rc == NO_ERROR) ? pBuffer : NULL);
}

// -----------------------------------------------------------------------------

PSZ ExpandEnvVar( PSZ pszStr)
{
         PSZ      pszResult = NULL;
         PSZ      pszNewValue;
         PSZ      pszStartPos;
         PSZ      pszEndPos;
         PSZ      pszLibpath = NULL;
         PSZ      pszVarValue;
         PSZ      pszNewResult;
         ULONG    ulNameLen;
         ULONG    ulNewResultLen;

         CHAR     szVarName[ 128];
         // Several sources say DosQueryExtLIBPATH will never return
         // more than 1024 bytes.
         CHAR     szLibPath[ 1025];       // +1 for safe measure
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

      // no end found, cut off to end of string
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
         if (!stricmp( szVarName, "beginlibpath"))
            pszVarValue = _queryExtLIBPATH( szLibPath, BEGIN_LIBPATH);
         else if (!stricmp( szVarName, "endlibpath"))
            pszVarValue = _queryExtLIBPATH( szLibPath, END_LIBPATH);
         else
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
// Expands env vars like _expandEnvVar, but also replaces %NEPMD_ROOTDIR% with
// its value, specified as arg2.

PSZ ExpandEnvVarAndRootDir( PSZ pszStr, PSZ pszRootDirValue)
{
         PSZ      pszResult = NULL;
         PSZ      pszNewValue;
         PSZ      pszStartPos;
         PSZ      pszEndPos;
         PSZ      pszLibpath = NULL;
         PSZ      pszVarValue;
         PSZ      pszNewResult;
         ULONG    ulNameLen;
         ULONG    ulNewResultLen;

         CHAR     szVarName[ 128];
         // Several sources say DosQueryExtLIBPATH will never return
         // more than 1024 bytes.
         CHAR     szLibPath[ 1025];       // +1 for safe measure
static   CHAR     chDelimiter = '%';

do
   {
   // check parms
   if (!pszStr)
      break;
   if (!pszRootDirValue)
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

      // no end found, cut off to end of string
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
         if (!stricmp( szVarName, "beginlibpath"))
            pszVarValue = _queryExtLIBPATH( szLibPath, BEGIN_LIBPATH);
         else if (!stricmp( szVarName, "endlibpath"))
            pszVarValue = _queryExtLIBPATH( szLibPath, END_LIBPATH);
         else if (!stricmp( szVarName, ENV_NEPMD_ROOTDIR))
            pszVarValue = pszRootDirValue;
         else
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
// DPRINTF(( "EPMENV: var moved: %s\n", pszEntry));
   memcpy( p, p + ulNameLen + 1, pszCurrent - p);
   pszCurrent -= ulNameLen + 1;
   }
else
   {
// DPRINTF(( "EPMENV: var added: %s\n", pszEntry));
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

static   PSZ            pszDelimiters = "\r\n";
         PSZ            pszLine;
         PSZ            pszCopyLine;
         PSZ            pszUpCopyLine;
         PSZ            p;
         ULONG          ulNameLen;
         PSZ            pszNewLine;

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

         // create copies to allow modification
         pszCopyLine = strdup( pszLine);
         pszUpCopyLine = strdup( pszLine);
         strupr( pszUpCopyLine);

         // make env var name uppercase, otherwise env var names
         // containing lowercase chars won't work
         p = strchr( pszLine, '=');
         if (p)
            {
            ulNameLen = p - pszLine;
            strncpy( pszCopyLine, pszUpCopyLine, ulNameLen);
            }

         // expand env vars
         pszNewLine = ExpandEnvVar( pszCopyLine);

         // cleanup copies
         if (pszCopyLine) free( pszCopyLine);
         if (pszUpCopyLine) free( pszUpCopyLine);

         // add line to env
         if (pszNewLine)
            {
            //DPRINTF(( "EPMENV: added: %s\n", pszNewLine));
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
// Extends the environment with internal NEPMD vars and parsed contents (by
// _readEnvFile) of the .env file(s). The EPM executable is searched after that
// first extension of the environment. After that, its env var is set and the
// environment is extended a second time.
// The LIBPATH is extended via EPMBEGINLIBPATH and EPMENDLIBPATH env vars,
// almost like supported by cmd.exe.
// If pszBuffer was supplied, it will be set to the value of the EPM
// executable.

APIRET GetExtendedEPMEnvironment( PSZ envv[], PSZ *ppszNewEnv, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         ULONG          i;

         BOOL           fEnvAlreadySet = 0;
         CHAR           szMainEnvFile[ _MAX_PATH];
         CHAR           szAddEnvFile[ _MAX_PATH];

         CHAR           szEpmExecutable[ _MAX_PATH];
         CHAR           szLoaderExecutable[ _MAX_PATH];
         CHAR           *pszPathVar;

         CHAR           szInstallVar[ _MAX_PATH + 30];
         PSZ            apszVar[ 26]; // increase size of array if more vars required!!!

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

   // check if extended environment is already set
   pszValue = getenv( ENV_NEPMD_ADDENVFILE);
   if ((!pszValue) || (!*pszValue))
      pszValue = getenv( ENV_NEPMD_MAINENVFILE);
   if ((pszValue) && (*pszValue))
      {
      DPRINTF(( "EPMENV: skip environment extension, already set with: %s\n", pszValue));
      fEnvAlreadySet = 1;
      // can't break here, because now pszBuffer is set to EpmExecutable later
      //break;
      }

   // **************** Part 1 ****************

   if (fEnvAlreadySet == 0)
      {

      // ------- search environment files -----------------

      // ignore errors!
      _searchNepmdEnvironmentFiles( szMainEnvFile, sizeof( szMainEnvFile),
                                    szAddEnvFile, sizeof( szAddEnvFile));

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

      // ------- set internal env vars --------------------

      // set internal var(s) first, use a different buffer for each
      // as putvar only passes a pointer to the environment list!!!

      // --- > set environment variable for NEPMD install directory (# 0)
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=", ENV_NEPMD_ROOTDIR);
      rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, _EOS( szInstallVar), _EOSSIZE( szInstallVar));
      //DPRINTF(( "QueryInstValue for NEPMD_INSTVALUE_ROOTDIR: rc = %u\n", rc ));
      if (rc == NO_ERROR)
         {
         apszVar[ 0] = strdup( szInstallVar);
         ADDVAR( apszVar[ 0]);
         }
      else
         // don't report error from here
         //rc = NO_ERROR;
         break;

      // --- > set environment variable for user directory (# 1)
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=", ENV_NEPMD_USERDIR);
      rc = QueryInstValue( NEPMD_INSTVALUE_USERDIR, _EOS( szInstallVar), _EOSSIZE( szInstallVar));
      //DPRINTF(( "QueryInstValue for NEPMD_INSTVALUE_USERDIR: rc = %u\n", rc ));
      if (rc == NO_ERROR)
         {
         apszVar[ 1] = strdup( szInstallVar);
         ADDVAR( apszVar[ 1]);
         }
      else
         break;

      // --- > set environment variable for NEPMD language (# 2)
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=", ENV_NEPMD_LANGUAGE);
      QueryInstValue( NEPMD_INSTVALUE_LANGUAGE, _EOS( szInstallVar), _EOSSIZE( szInstallVar));
      apszVar[ 2] = strdup( szInstallVar);
      ADDVAR( apszVar[ 2]);

      // --- > set environment variables for env files (# 3, 4)
      if (strlen( szMainEnvFile))
         {
         memset( szInstallVar, 0, sizeof( szInstallVar));
         sprintf( szInstallVar, "%s=%s", ENV_NEPMD_MAINENVFILE, szMainEnvFile);
         apszVar[ 3] = strdup( szInstallVar);
         ADDVAR( apszVar[ 3]);
         }

      if (strlen( szMainEnvFile))
         {
         memset( szInstallVar, 0, sizeof( szInstallVar));
         sprintf( szInstallVar, "%s=%s", ENV_NEPMD_ADDENVFILE, szAddEnvFile);
         apszVar[ 4] = strdup( szInstallVar);
         ADDVAR( apszVar[ 4]);
         }

      // search EpmExecutable after the environment is expanded (# 5)

      // ------- read env files ---------------------------

      if (strlen( szMainEnvFile)) _readEnvFile( szMainEnvFile, &ulEnvSize, &pszName, pszEnvNameList);
      if (strlen( szAddEnvFile)) _readEnvFile( szAddEnvFile, &ulEnvSize, &pszName, pszEnvNameList);

      // ------- set environment --------------------------

      // get memory with updated env size
      //DPRINTF(( "estimated new size is: %u\n", ulEnvSize));
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

      // ------- end of Part 1 ----------------------------

      }  // fEnvAlreadySet == 0

   // ------- search EPM executable and get loader -----

   // search EPM executable after PATH was extended
   // the loader executable is here not required, if it was processed already before
   szEpmExecutable[ 0] = 0;
   szLoaderExecutable[ 0] = 0;
   rc = _searchEpmExecutable( szEpmExecutable,    sizeof( szEpmExecutable),
                              szLoaderExecutable, sizeof( szLoaderExecutable));

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
      //DPRINTF(( "EPMENV: found executable: %s\n", szEpmExecutable));
      strcpy( pszBuffer, szEpmExecutable);
      }

   // **************** Part 2 ****************

   // set the next vars after _searchEPMExecutable was called
   // and after env files are processed
   if (fEnvAlreadySet == 0)
      {

      // ------- set LIBPATH ------------------------------

      // ------>  todo: fix this

      // This works here, after the first extension of the
      // environment and after env files are processed.
      // Processing BEGIN/ENDLIBPATH instead of
      // EPMBEGIN/ENDLIBPATH would make refuse any later change
      // of them in a cmd.exe child process.

      //pszPathVar = getenv( "BEGINLIBPATH");
      pszPathVar = getenv( "EPMBEGINLIBPATH");
      if (pszPathVar != NULL)
         DosSetExtLIBPATH( pszPathVar, BEGIN_LIBPATH);
      //pszPathVar = getenv( "ENDLIBPATH");
      pszPathVar = getenv( "EPMENDLIBPATH");
      if (pszPathVar != NULL)
         DosSetExtLIBPATH( pszPathVar, END_LIBPATH);

      // ------- set internal env vars --------------------

      // --- > set NEPMD_EPMEXECUTABLE (# 5)
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=%s", ENV_NEPMD_EPMEXECUTABLE, szEpmExecutable);
      apszVar[ 5] = strdup( szInstallVar);
      ADDVAR( apszVar[ 5]);

      // --- > set NEPMD_LOADEREXECUTABLE (# 6)
      // this can be set before the first evironment extension as well,
      // therefore activate #define SetLoaderAtFirstPart
      memset( szInstallVar, 0, sizeof( szInstallVar));
      sprintf( szInstallVar, "%s=%s", ENV_NEPMD_LOADEREXECUTABLE, szLoaderExecutable);
      apszVar[ 6] = strdup( szInstallVar);
      ADDVAR( apszVar[ 6]);

      // ------- set environment --------------------------

      // ------>  todo: fix this (but works somehow)

      // repeat extension of the environment, but this time with added
      // values for the executables
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

      // setting BEGIN/ENDLIBPATH would work here, but then
      // these pseudo env vars can't be changed later!?!

      // ------- end of Part 2 ---------------------------

      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 0]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 1]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 2]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 3]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 4]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 5]));
      //DPRINTF(( "EPMENV: ### %s\n", apszVar[ 6]));

      // close name list
      *pszName = 0;

      *pszVar = 0;

      // hand over result
      *ppszNewEnv = pszEnv;

      }  // fEnvAlreadySet == 0

   } while (FALSE);


// cleanup on error
if (rc)
   if (pszEnv) free( pszEnv);

// cleanup
if (pszEnvNameList) free( pszEnvNameList);
for (i = 0; i < (sizeof( apszVar) / sizeof( PSZ)); i++)
   {
   if (apszVar[ i]) free( apszVar[ i]);
   }
return rc;
}

