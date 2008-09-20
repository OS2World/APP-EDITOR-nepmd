/****************************** Module Header *******************************
*
* Module Name: instval.c
*
* Generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: instval.c,v 1.17 2008-09-20 23:14:30 aschn Exp $
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
#include "module.h"
#include "tmf.h"
#include "epmenv.h"
#include "instval.h"

// -----------------------------------------------------------------------------

APIRET QueryInstValue( PSZ pszValueTag, PSZ pszBuffer, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;

         BOOL           fNepmdInstalled = FALSE;
         BOOL           fRunningInDevTree = FALSE;
         BOOL           fUserDirSet = FALSE;

         CHAR           szRootDir[ _MAX_PATH];
         CHAR           szUserDir[ _MAX_PATH];
         CHAR           szNepmdLanguage[ 20];

         CHAR           szModulePath[ _MAX_PATH];
         CHAR           szTmp[ _MAX_PATH];
         CHAR           szValue[ _MAX_PATH];

         PSZ            pszDevTreePath;
         PSZ            pszTmp;

static   PSZ            pszUserBinDir   = NEPMD_SUBPATH_USERBINDIR;
static   PSZ            pszNepmdBinDir  = NEPMD_SUBPATH_BINBINDIR;
static   PSZ            pszNepmdBookDir = NEPMD_SUBPATH_CMPINFDIR;
static   PSZ            pszNepmdHelpDir = NEPMD_SUBPATH_CMPHLPDIR;

static   PSZ            pszUserIniFile  = NEPMD_FILENAME_INIFILE;
static   PSZ            pszMessageFile  = NEPMD_FILENAME_MESSAGEFILE;
static   PSZ            pszUsrInfFile   = NEPMD_FILENAME_USRINFFILE;
static   PSZ            pszPrgInfFile   = NEPMD_FILENAME_PRGINFFILE;
static   PSZ            pszHelpFile     = NEPMD_FILENAME_HELPFILE;

static   PSZ            pszInstPathMask = "%s\\%s\\%s";
static   PSZ            pszFreePathMask = "%s\\%s";

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszValueTag) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get path of current DLL or EXE and cut off name
   rc = GetModuleName( szModulePath, sizeof( szModulePath));
   if (rc != NO_ERROR)
      break;
   strcpy( strrchr( szModulePath, '\\'), "");
   //DPRINTF(( "INSTVAL: szModulePath = %s\n", szModulePath));

   // get NEPMD root dir
   memset( szRootDir, 0, sizeof( szRootDir));
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_ROOTDIR,
                          NULL,
                          szRootDir,
                          sizeof( szRootDir));

   // Resolve env vars
   // Note: Env var resolution is not very useful here, because WarpIN
   //       doesn't expand env vars in ini values.
   pszTmp = ExpandEnvVar( szRootDir);
   //DPRINTF(( "INSTVAL: Expanded RootDir = %s\n", pszTmp));
   strcpy( szRootDir, pszTmp);

   fNepmdInstalled = (szRootDir[ 0] > 0);
   //DPRINTF(( "INSTVAL: fNepmdInstalled = %u\n", fNepmdInstalled));

   // Get user's path
   // Default is RootDir"\myepm"
   do
      {
      memset( szUserDir, 0, sizeof( szUserDir));
      PrfQueryProfileString( HINI_USER,
                             NEPMD_INI_APPNAME,
                             NEPMD_INI_KEYNAME_USERDIR,
                             NULL,
                             szUserDir,
                             sizeof( szUserDir));
      //DPRINTF(( "INSTVAL: "NEPMD_INI_KEYNAME_USERDIR" = %s\n", szUserDir));

      // Resolve env vars
      // Note: %NEPMD_ROOTDIR% is not set at this time. For something like
      //       UserDir -> %NEPMD_ROOTDIR%\myepm, this env var must be handled
      //       specially.
      pszTmp = ExpandEnvVarAndRootDir( szUserDir, szRootDir);
      //DPRINTF(( "INSTVAL: Expanded UserDir = %s\n", pszTmp));
      strcpy( szUserDir, pszTmp);

      fUserDirSet = (szUserDir[ 0] > 0);
      if (fUserDirSet == 1)
         break;

      // UserDir not set: use default value
      if (!fNepmdInstalled)
         {
         rc = ERROR_PATH_NOT_FOUND;
         break;
         }
      sprintf( szUserDir, "%s\\%s", szRootDir, NEPMD_SUBPATH_DEFAULTUSERDIR);
      //DPRINTF(( "INSTVAL: "NEPMD_INI_KEYNAME_USERDIR" (built) = %s\n", szUserDir));

      } while (FALSE);

   // get installed language - english as default
   memset( szNepmdLanguage, 0, sizeof( szNepmdLanguage));
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_LANGUAGE,
                          "eng",
                          szNepmdLanguage,
                          sizeof( szNepmdLanguage));

   // get developer tree rootdir
   pszDevTreePath = getenv( ENV_NEPMD_DEVPATH);
   fRunningInDevTree = (pszDevTreePath != NULL);


   // --------------------------------------

   if (!stricmp( pszValueTag, NEPMD_INSTVALUE_ROOTDIR))
      {
      if (!fNepmdInstalled)
         {
         rc = ERROR_PATH_NOT_FOUND;
         break;
         }

      // determine installation path
      strcpy( szValue, szRootDir);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_USERDIR))
      {
      if ( strlen( szUserDir) == 0)
         {
         rc = ERROR_PATH_NOT_FOUND;
         break;
         }

      // determine user path
      strcpy( szValue, szUserDir);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_LANGUAGE))
      // determine installation language
      strcpy( szValue, szNepmdLanguage);

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_INIT))
      {
      // determine name of initialization file
      if (fRunningInDevTree)
         sprintf( szValue, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_INIFILE, pszUserIniFile);
      else if (fNepmdInstalled)
         sprintf( szValue, pszInstPathMask, szUserDir, pszUserBinDir, pszUserIniFile);
      else
         sprintf( szValue, pszFreePathMask, szModulePath, pszUserIniFile);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_MESSAGE))
      {
      // determine name of message file
      if (fRunningInDevTree)
         sprintf( szTmp, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_MESSAGEFILE, pszMessageFile);
      else if (fNepmdInstalled)
         sprintf( szTmp, pszInstPathMask, szRootDir, pszNepmdBinDir, pszMessageFile);
      else
         sprintf( szTmp, pszFreePathMask, szModulePath, pszMessageFile);

      // pass in language identifier
      sprintf( szValue, szTmp, szNepmdLanguage);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_HELP))
      {
      // determine name of message file
      if (fRunningInDevTree)
         sprintf( szTmp, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_HELPFILE, pszHelpFile);
      else if (fNepmdInstalled)
         sprintf( szTmp, pszInstPathMask, szRootDir, pszNepmdHelpDir, pszHelpFile);
      else
         sprintf( szTmp, pszFreePathMask, szModulePath, pszHelpFile);

      // pass in language identifier
      sprintf( szValue, szTmp, szNepmdLanguage);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_USRGUIDE))
      {
      // determine name of message file
      if (fRunningInDevTree)
         sprintf( szTmp, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_INFFILE, pszUsrInfFile);
      else if (fNepmdInstalled)
         sprintf( szTmp, pszInstPathMask, szRootDir, pszNepmdBookDir, pszUsrInfFile);
      else
         sprintf( szTmp, pszFreePathMask, szModulePath, pszUsrInfFile);

      // pass in language identifier
      sprintf( szValue, szTmp, szNepmdLanguage);
      }

   else if (!stricmp( pszValueTag, NEPMD_INSTVALUE_PRGGUIDE))
      {
      // determine name of message file
      if (fRunningInDevTree)
         sprintf( szTmp, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_INFFILE, pszPrgInfFile);
      else if (fNepmdInstalled)
         sprintf( szTmp, pszInstPathMask, szRootDir, pszNepmdBookDir, pszPrgInfFile);
      else
         sprintf( szTmp, pszFreePathMask, szModulePath, pszPrgInfFile);

      // pass in language identifier
      sprintf( szValue, szTmp, szNepmdLanguage);
      }

   else

      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check result buffer
   if (strlen( szValue) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szValue);

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET GetMessage
         (
         PCHAR     *pTable,
         ULONG      cTable,
         PBYTE      pbBuffer,
         ULONG      cbBuffer,
         PSZ        pszMessageName,
         PULONG     pcbMsg
         )
{
         APIRET         rc = NO_ERROR;
static   BOOL           fInitialized = FALSE;
static   CHAR           szMessageFile[ _MAX_PATH];

do
   {
   // get name of messagefile once
   if (!fInitialized)
      {
      // query messagefile
      rc = QueryInstValue( NEPMD_INSTVALUE_MESSAGE, szMessageFile, sizeof( szMessageFile));
      if (rc != NO_ERROR)
         break;
      fInitialized = TRUE;
      }

   // make call to fetch message
   rc = TmfGetMessage( pTable, cTable, pbBuffer, cbBuffer, pszMessageName, szMessageFile, pcbMsg);

   } while (FALSE);

return rc;
}


