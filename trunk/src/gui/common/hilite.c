/****************************** Module Header *******************************
*
* Module Name: hilite.c
*
* Generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.c,v 1.4 2002-09-23 19:28:40 cla Exp $
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


#define QUERYINITVALUE(h,s,k,t)                             \
if (!InitQueryProfileString( h, s, k, NULL, t, sizeof( t))) \
   {                                                        \
   rc = ERROR_INVALID_DATA;                                 \
   break;                                                   \
   }
#define QUERYINITVALUESIZE(h,s,k) _queryInitValueSize( h, s, k)


typedef struct _VALUEARRAY
     {
         ULONG          ulCount;
         PSZ            apszValue[ 1];

     } VALUEARRAY, *PVALUEARRAY;

// -----------------------------------------------------------------------------

static APIRET _openInitFile( PHINIT phinit, PSZ pszSearchPathName, PSZ pszSearchMask, PSZ pszEpmMode)
{
         APIRET         rc = NO_ERROR;
         CHAR           szSourceName[ _MAX_PATH];
         CHAR           szFile[ _MAX_PATH];

do
   {
   // read defaults file first - this must exist and includ emandantory values
   sprintf( szSourceName, pszSearchMask, pszEpmMode);
   rc = DosSearchPath( SEARCH_IGNORENETERRS  |
                          SEARCH_ENVIRONMENT |
                          SEARCH_CUR_DIRECTORY,
                      pszSearchPathName,
                      szSourceName,
                      szFile,
                      sizeof( szFile));
   if (rc != NO_ERROR)
      break;

   rc = InitOpenProfile( szFile, phinit, INIT_OPEN_READONLY, 0, NULL);
   if (rc != NO_ERROR)
      break;

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static APIRET _openConfig( PHCONFIG phconfig)
{
         APIRET         rc = NO_ERROR;
         CHAR           szInifile[ _MAX_PATH];
         HCONFIG        hconfig;

do
   {
   // check parm
   if (!phconfig)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // determine name of INI
   rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szInifile, sizeof( szInifile));
   if (rc != NO_ERROR)
      break;

   // open profile
   rc = OpenConfig( &hconfig, szInifile);
   if (rc != NO_ERROR)
      break;

   // hand over result
   *phconfig = hconfig;

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static APIRET _queryInitValueSize( HCONFIG hconfig, PSZ pszSection, PSZ pszKey)
{
         ULONG          ulDataLen = 0;

InitQueryProfileSize( hconfig, pszSection, pszKey, &ulDataLen);
return ulDataLen;
}

// -----------------------------------------------------------------------------

int _compareValue( const void *ppszKeyElement, const void *ppszEntry)
{

#ifdef DEBUG
// for view in debugger only:
         PSZ            pszKey   = *(PSZ*)ppszKeyElement;
         PSZ            pszEntry = *(PSZ*)ppszEntry;
#endif
return stricmp( *(PSZ*)ppszKeyElement, *(PSZ*)ppszEntry);
}


static PVALUEARRAY _createInitValueArray( HCONFIG hinit, PSZ pszSection)
{
         PVALUEARRAY    pvaResult = NULL;
         APIRET         rc = NO_ERROR;

         PSZ            pszKey;
         ULONG          ulKeyCount;
         PVALUEARRAY    pva = NULL;
         ULONG          ulBuflen;
         CHAR           szKeyList[ 1024];
         CHAR           szKeyValue[ 128];

         PSZ           *ppszAnchor;
         PSZ           pszEntry;

do
   {
   // read the key list
   QUERYINITVALUE( hinit, pszSection, NULL, szKeyList);

   // count items and its size
   ulBuflen = sizeof( VALUEARRAY);
   ulKeyCount = 0;
   pszKey = szKeyList;
   while (*pszKey)
      {
      // add appropriate space and cout up 
      ulKeyCount++;
      ulBuflen += sizeof( PSZ) +
                  strlen( pszKey) + 1 + 
                  QUERYINITVALUESIZE( hinit, pszSection, pszKey) + 1;

      // next key
      pszKey = NEXTSTR( pszKey);
      }

   // allocate memory
   pva = malloc( ulBuflen);
   if (!pva)
      break;
   memset( pva, 0, ulBuflen);
   pvaResult = pva;


   // create array
   pva->ulCount = ulKeyCount;
   ppszAnchor   = pva->apszValue;
   pszEntry     = (PSZ) pva->apszValue + (ulKeyCount * sizeof( PSZ));
   pszKey = szKeyList;
   while (*pszKey)
      {
      // store entry
      *ppszAnchor = pszEntry;
      strcpy( pszEntry, pszKey);
      pszEntry = NEXTSTR( pszEntry);
      QUERYINITVALUE( hinit, pszSection, pszKey, szKeyValue);
      strcpy( pszEntry, szKeyValue);
      pszEntry = NEXTSTR( pszEntry);

      // next key
      ppszAnchor++;
      pszKey = NEXTSTR( pszKey);
      }

   // sort the entries
   qsort( pva->apszValue, pva->ulCount, sizeof( PSZ), _compareValue);


   } while (FALSE);

return pvaResult;

}

// #############################################################################

static APIRET _assembleKeywordFile(  PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

         PSZ           *ppszEntry;
         PSZ            pszEntry;
         PSZ            pszSymbol;
         PSZ           *ppszSymbolValue;
         CHAR           szValue[ _MAX_PATH];
         PSZ            pszModeCopy = NULL;
         PSZ            pszKeywordPath = getenv( "EPMKEYWORDPATH");

         // ----------------------------------

         HINIT          hinitGlobals = NULLHANDLE;

static   PSZ            pszColorsSection = "COLORS";
static   PSZ            pszSymbolsSection = "SYMBOLS";
         PVALUEARRAY    pvaColors = NULL;
         PVALUEARRAY    pvaSymbols = NULL;

         // ----------------------------------

         HINIT          hinitDefault = NULLHANDLE;
static   PSZ            pszGlobalSection = "GLOBAL";
         CHAR           szCharset[ _MAX_PATH];
         CHAR           szDefExtensions[ _MAX_PATH];
         BOOL           fCaseSensitive = FALSE;

         // ----------------------------------

         HCONFIG        hconfig = NULLHANDLE;


         BOOL           fCreateKeywordFile = FALSE;
static   PSZ            pszKeywordPathMask = "\\NEPMD\\Hilite\\%s\\TempFile";
         CHAR           szKeywordPath[ _MAX_PATH];
         CHAR           szKeywordFile[ _MAX_PATH]; 
         ULONG          ulKeywordFileDate = -1;


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

   // search and load values from INI files

   // - read global values
   rc = _openInitFile( &hinitGlobals, "EPMKEYWORDPATH", "global.ini", NULL);
   if (rc != NO_ERROR)
      break;

   pvaColors = _createInitValueArray( hinitGlobals, pszColorsSection);
   pvaSymbols = _createInitValueArray( hinitGlobals, pszSymbolsSection);

   // replace color values in symbol defs
   ppszEntry = pvaSymbols->apszValue;
   for (i = 0; i < pvaSymbols->ulCount; i++)
      {

               PSZ            pszValueBuf;
               ULONG          ulValueLen;

      // loop through all symbols
      pszEntry =  *ppszEntry;
      szValue[ 0] = 0;

      // replace color names with color values
      pszValueBuf = NEXTSTR( *ppszEntry);
      ulValueLen  = strlen( pszValueBuf);

      pszSymbol = strtok( pszValueBuf, " ");
      while (pszSymbol)
         {
         ppszSymbolValue = bsearch( &pszSymbol,
                                    pvaColors->apszValue,
                                    pvaColors->ulCount,
                                    sizeof( PSZ),
                                    _compareValue);
         if (ppszSymbolValue)
            {
            strcat( szValue, " ");
            strcat( szValue, NEXTSTR( *ppszSymbolValue));
            }

         // next symbol
         pszSymbol = strtok( NULL, " ");
         }

      // check buffer
      if (strlen( szValue) <= ulValueLen)
         strcpy( pszValueBuf, szValue);

      // next entry
      ppszEntry++;
      }

// #######
#ifdef DEBUG   
   {
   PSZ *ppszEntry = pvaSymbols->apszValue;
   PSZ pszEntry;
   ULONG i;
   
   printf( "Symbols:\n");
   for (i = 0; i < pvaSymbols->ulCount; i++)
      {
      pszEntry =  *ppszEntry;
      printf( "-> %s %s\n", *ppszEntry, NEXTSTR( *ppszEntry));
      ppszEntry++;
      }
   }
#endif
// #######

   // - read defaults of the mode 
   rc = _openInitFile( &hinitDefault, "EPMKEYWORDPATH", "%s\\default.ini", pszEpmMode);
   if (rc != NO_ERROR)
      break;

   QUERYINITVALUE( hinitDefault, pszGlobalSection, "CHARSET",       szCharset);
   QUERYINITVALUE( hinitDefault, pszGlobalSection, "DEFEXTENSIONS", szDefExtensions);
   QUERYINITVALUE( hinitDefault, pszGlobalSection, "CASESENSITIVE", szValue);
   fCaseSensitive = atol( szValue);

   // -----------------------------------------------

   // get the name and date of the temporary file

   // init some vars
   pszModeCopy = strdup( pszEpmMode);
   strupr( pszModeCopy);

   // open up repository
   rc = _openConfig( &hconfig);
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
if (pvaColors)  free( pvaColors);
if (pvaSymbols) free( pvaSymbols);
if (pszModeCopy) free( pszModeCopy);

if (hconfig) CloseConfig( hconfig);
if (hinitDefault) InitCloseProfile( hinitDefault, FALSE);
if (hinitGlobals) InitCloseProfile( hinitGlobals, FALSE);
return rc;
}

// -----------------------------------------------------------------------------
static APIRET _searchOldKeywordFile(  PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{

         APIRET         rc = NO_ERROR;
         CHAR           szSourceName[ 32];

// old way: search the epmkwds file on EPMPATH
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

