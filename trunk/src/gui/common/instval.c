/****************************** Module Header *******************************
*
* Module Name: epmenv.c
*
* Generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: instval.c,v 1.4 2002-08-23 14:08:48 cla Exp $
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
#include "module.h"

// -----------------------------------------------------------------------------

APIRET GetInstValue( PSZ pszValueTag, PSZ pszBuffer, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;

         BOOL           fNepmdInstalled = FALSE;
         BOOL           fRunningInDevTree = FALSE;

         CHAR           szNepmdPath[ _MAX_PATH];
         CHAR           szNepmdLanguage[ 20];

         CHAR           szModulePath[ _MAX_PATH];
         CHAR           szTmp[ _MAX_PATH];
         CHAR           szValue[ _MAX_PATH];

         PSZ            pszDevTreePath;

static   PSZ            pszUserBinDir = NEPMD_SUBPATH_MYBINDIR;
static   PSZ            pszNepmdBinDir = NEPMD_SUBPATH_BINBINDIR;

static   PSZ            pszUserIniFile = NEPMD_FILENAME_INIFILE;
static   PSZ            pszMessageFile = NEPMD_FILENAME_MESSAGEFILE;

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

   // get path of this DLL and cut off name
   rc = GetModuleName( szModulePath, sizeof( szModulePath));
   if (rc != NO_ERROR)
      break;
   strcpy( strrchr( szModulePath, '\\'), "");

   // get name of EPM.EXE in NEPMD path
   memset( szNepmdPath, 0, sizeof( szNepmdPath));
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_PATH,
                          NULL,
                          szNepmdPath,
                          sizeof( szNepmdPath));
   fNepmdInstalled = (szNepmdPath[ 0] > 0);

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

   if (!stricmp( pszValueTag, NEPMD_VALUETAG_ROOTDIR))
      {
      if (!fNepmdInstalled)
         {
         rc = ERROR_PATH_NOT_FOUND;
         break;
         }

      // determine installation path
      strcpy( szValue, szNepmdPath);
      }

   else if (!stricmp( pszValueTag, NEPMD_VALUETAG_LANGUAGE))
      // determine installation language
      strcpy( szValue, szNepmdLanguage);

   else if (!stricmp( pszValueTag, NEPMD_VALUETAG_INIT))
      {
      // determine name of initialization file
      if (fRunningInDevTree)
         sprintf( szValue, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_INIFILE, pszUserIniFile);
      else if (fNepmdInstalled)
         sprintf( szValue, pszInstPathMask, szNepmdPath, pszUserBinDir, pszUserIniFile);
      else
         sprintf( szValue, pszFreePathMask, szModulePath, pszUserIniFile);
      }

   else if (!stricmp( pszValueTag, NEPMD_VALUETAG_MESSAGE))
      {
      // determine name of message file
      if (fRunningInDevTree)
         sprintf( szTmp, pszInstPathMask, pszDevTreePath, NEPMD_DEVPATH_MESSAGEFILE, pszMessageFile);
      else if (fNepmdInstalled)
         sprintf( szTmp, pszInstPathMask, szNepmdPath, pszNepmdBinDir, pszMessageFile);
      else
         sprintf( szTmp, pszFreePathMask, szModulePath, pszMessageFile);

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

