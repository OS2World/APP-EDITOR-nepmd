/****************************** Module Header *******************************
*
* Module Name: hilite.c
*
* Generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.c,v 1.3 2002-09-23 15:57:01 cla Exp $
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
#include "hilite.h"
#include "libreg.h"
#include "init.h"
#include "instval.h"
#include "file.h"

#ifdef DEBUG
static   PSZ            pszEnvVar = "";
static   PSZ            pszEnvValue = "";

#define CHECKENV(v)                              \
{                                                \
pszEnvVar = v;                                   \
pszEnvValue = getenv( pszEnvVar);                \
printf( "envvar %s: %s\n",                       \
        pszEnvVar,                               \
        (pszEnvValue) ? pszEnvValue : "<null>"); \
}

#else
#define CHECKENV(v)
#endif

// -----------------------------------------------------------------------------

static APIRET _assembleKeywordFile(  PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         CHAR           szValue[ _MAX_PATH];
         PSZ            pszModeCopy = NULL;
         PSZ            pszKeywordPath = getenv( "EPMKEYWORDPATH");

         CHAR           szDefaultFile[ _MAX_PATH];
         HINIT          hinit = NULLHANDLE;
         PSZ            pszGlobalSection = "GLOBAL";
         CHAR           szCharset[ _MAX_PATH];
         CHAR           szDefExtensions[ _MAX_PATH];
         BOOL           fCaseSensitive = FALSE;

         CHAR           szInitFile[ _MAX_PATH];
         HCONFIG        hconfig = NULLHANDLE;


         BOOL           fCreateKeywordFile = FALSE;
static   PSZ            pszKeywordPathMask = "\\NEPMD\\Hilite\\%s\\TempFile";
         CHAR           szKeywordPath[ _MAX_PATH];
         CHAR           szKeywordFile[ _MAX_PATH]; 
         ULONG          ulKeywordFileDate = -1;

         CHAR           szSourceName[ _MAX_PATH];

do
   {
   if (!pszKeywordPath)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }
   if ((!pszEpmMode) ||
       (!*pszEpmMode))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }
   // -----------------------------------------------

   // read defaults file first - this must exist and includ emandantory values
   sprintf( szSourceName, "%s\\default.ini", pszEpmMode);
   rc = DosSearchPath( SEARCH_IGNORENETERRS  |
                          SEARCH_ENVIRONMENT |
                          SEARCH_CUR_DIRECTORY,
                      "EPMKEYWORDPATH",
                      szSourceName,
                      szDefaultFile,
                      sizeof( szDefaultFile));
   if (rc != NO_ERROR)
      break;

   rc = InitOpenProfile( szDefaultFile, &hinit, INIT_OPEN_READONLY, 0, NULL);
   if (rc != NO_ERROR)
      break;

   if (!InitQueryProfileString( hinit, pszGlobalSection, "CHARSET", NULL, szCharset, sizeof( szCharset)))
      {
      rc = ERROR_INVALID_DATA;
      break;
      }

   if (!InitQueryProfileString( hinit, pszGlobalSection, "DEFEXTENSIONS", NULL, szDefExtensions, sizeof( szDefExtensions)))
      {
      rc = ERROR_INVALID_DATA;
      break;
      }

   if (!InitQueryProfileString( hinit, pszGlobalSection, "CASESENSITIVE", NULL, szValue, sizeof( szValue)))
      {
      rc = ERROR_INVALID_DATA;
      break;
      }
   fCaseSensitive = atol( szValue);





   // -----------------------------------------------

   // get the name and date of the temporary file

   // init some vars
   pszModeCopy = strdup( pszEpmMode);
   strupr( pszModeCopy);

   // open up repository
   rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szInitFile, sizeof( szInitFile));
   if (rc != NO_ERROR)
      break;
   rc = OpenConfig( &hconfig, szInitFile);
   if (rc != NO_ERROR)
      break;

   // get keywordfile
   strupr( pszEpmMode);
   sprintf( szKeywordPath, pszKeywordPathMask, pszModeCopy);
   rc = QueryConfigValue( hconfig, szKeywordPath, szKeywordFile, sizeof( szKeywordFile));
   if (rc != NO_ERROR)
      {
      // no keyword file yet, create a new one
      rc = GetTempFilename( szKeywordFile, sizeof( szKeywordFile));
      if (rc != NO_ERROR)
         break;
      }

   // check for the file date - if not exists, will return -1, 
   // always enforcing a rebuild
   ulKeywordFileDate = FileDate( szKeywordFile);

   // -----------------------------------------------



rc = 1;
   } while (FALSE);

// cleanup 
if (hconfig) CloseConfig( hconfig);
if (hinit) InitCloseProfile( hinit, FALSE);
if (pszModeCopy) free( pszModeCopy);
return rc;
}

// -----------------------------------------------------------------------------
static APIRET _searchOldKeywordFile(  PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{

         APIRET         rc = NO_ERROR;
         CHAR           szSourceName[ 32];

// old way: search the epmkwds file on EPMPATH
CHECKENV( "EPMPATH");
sprintf( szSourceName, "epmkwds.%s", pszEpmMode);
rc =   DosSearchPath( SEARCH_IGNORENETERRS  |
                         SEARCH_ENVIRONMENT |
                         SEARCH_CUR_DIRECTORY,
                      "EPMPATH",
                      szSourceName,
                      pszBuffer,
                      ulBuflen);
return rc;
}

// -----------------------------------------------------------------------------

APIRET QueryHilightFile( PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         CHAR           szValue[ _MAX_PATH];
         CHAR           szDefaultsFile[ _MAX_PATH];


do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszEpmMode)   ||
       (!*pszEpmMode)  ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // search mode files
   rc = _assembleKeywordFile( pszEpmMode, szValue, sizeof( szValue)); 
   if (rc != NO_ERROR)
      {
      // if no mode infos available; conventional search
      rc = _searchOldKeywordFile( pszEpmMode, szValue, sizeof( szValue));
      if (rc != NO_ERROR)
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

