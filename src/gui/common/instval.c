/****************************** Module Header *******************************
*
* Module Name: epmenv.c
*
* Generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: instval.c,v 1.1 2002-08-22 15:02:28 cla Exp $
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

APIRET GetInstValue( PSZ pszFileTag, PSZ pszBuffer, ULONG ulBuflen) 

{
         APIRET         rc = NO_ERROR;
         BOOL           fNepmdInstalled = FALSE;

         CHAR           szNepmdPath[ _MAX_PATH];
         CHAR           szModulePath[ _MAX_PATH];
         CHAR           szFilename[ _MAX_PATH];


static   PSZ            pszUserBinDir = NEPMD_SUBPATH_MYBINDIR;
static   PSZ            pszUserIniFile = NEPMD_FILENAME_INIFILE;

static   PSZ            pszInstPathMask = "%s\\%s\\%s";
static   PSZ            pszFreePathMask = "%s\\%s\\%s";

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszFileTag) ||
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


   // --------------------------------------

   if (!stricmp( pszFileTag, NEPMD_VALUETAG_INIT))
      {
      // determine name of initialization file
      if (fNepmdInstalled)
         sprintf( szFilename, pszInstPathMask, szNepmdPath, pszUserBinDir, pszUserIniFile);
      else
         sprintf( szFilename, pszFreePathMask, pszUserIniFile);
      }

   else if (!stricmp( pszFileTag, NEPMD_VALUETAG_MESSAGES))
      {
      // determine name of message file
      if (fNepmdInstalled)
         sprintf( szFilename, pszInstPathMask, szNepmdPath, pszUserBinDir, pszUserIniFile);
      else
         sprintf( szFilename, pszFreePathMask, pszUserIniFile);
      }

   } while (FALSE);

return rc;

}

