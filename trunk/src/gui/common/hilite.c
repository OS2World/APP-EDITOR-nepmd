/****************************** Module Header *******************************
*
* Module Name: hilite.c
*
* Generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.c,v 1.2 2002-09-22 22:24:28 cla Exp $
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
         CHAR           szSourceName[ _MAX_PATH];
         CHAR           szDefaultFile[ _MAX_PATH];

do
   {
   // search default path first
   CHECKENV( "EPMKEYWORDPATH");
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

rc = 1;
   } while (FALSE);

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

