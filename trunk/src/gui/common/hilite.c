/****************************** Module Header *******************************
*
* Module Name: hilite.c
*
* Generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.c,v 1.11 2002-09-25 21:17:15 cla Exp $
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
#include <stdarg.h>
#include <search.h>

#include "macros.h"
#include "nepmd.h"
#include "hilite.h"
#include "libreg.h"
#include "init.h"
#include "instval.h"
#include "file.h"
#include "mmf.h"

// definitions for file format for *.hil
#define CHAR_COMMENT          ';'
#define CHAR_SECTION_START   '['
#define CHAR_SECTION_END     ']'


// some useful macros
#define ALLOCATEMEMORYFILE(p,s)                      \
rc = MmfAlloc( (PVOID*)&p, MMF_FILE_INMEMORY, 0, s); \
if (rc != NO_ERROR)                                  \
   break;

#define FREEMEMORYFILE(p)   MmfFree( p)

#define QUERYINITVALUE(h,s,k,t)                             \
if (!InitQueryProfileString( h, s, k, NULL, t, sizeof( t))) \
   {                                                        \
   rc = ERROR_INVALID_DATA;                                 \
   break;                                                   \
   }
#define QUERYINITVALUESIZE(h,s,k) _queryInitValueSize( h, s, k)

// structure vor an array of values
typedef struct _VALUEARRAY
     {
         ULONG          ulCount;
         ULONG          ulArraySize;
         PSZ            apszValue[ 1];

     } VALUEARRAY, *PVALUEARRAY;

// ----------------------------------------------------------------------

static PSZ _stripblanks( PSZ string)
{
 PSZ p = string;
 if (p != NULL)
    {
    while ((*p != 0) && (*p <= 32))
       { p++;}
    strcpy( string, p);
    }
 if (*p != 0)
    {
    p += strlen(p) - 1;
    while ((*p <= 32) && (p >= string))
       {
       *p = 0;
       p--;
       }
    }

return string;
}

// ######################################################################

static APIRET _searchFile( PSZ pszSearchPathName, PSZ pszBuffer, ULONG ulBuflen, PSZ pszSearchMask, ...)
{
         APIRET         rc = NO_ERROR;
         CHAR           szSourceName[ _MAX_PATH];
         va_list        arg_ptr;

va_start (arg_ptr, pszSearchMask);
vsprintf( szSourceName, pszSearchMask, arg_ptr);
rc = DosSearchPath( SEARCH_IGNORENETERRS  |
                       SEARCH_ENVIRONMENT |
                       SEARCH_CUR_DIRECTORY,
                   pszSearchPathName,
                   szSourceName,
                   pszBuffer,
                   ulBuflen);
return rc;

}

// -----------------------------------------------------------------------------

static APIRET _openInitFile( PHINIT phinit, PSZ pszSearchPathName, PSZ pszSearchMask, PSZ pszEpmMode)
{
         APIRET         rc = NO_ERROR;
         CHAR           szFile[ _MAX_PATH];

do
   {
   // search init filefile
   rc = _searchFile(  pszSearchPathName, szFile, sizeof( szFile), pszSearchMask,  pszEpmMode);
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

static APIRET _scanFilePath( PSZ pszSearchPath, PULONG pulFileCount,  PSZ pszBuffer,PULONG pulBuflen, PSZ pszSearchMask, ...)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszPath;
do
   {

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

int _compareFilename( const void *pszKeyElement, const void *pszEntry)
{
pszKeyElement = (PVOID) Filespec( (PSZ) pszKeyElement, FILESPEC_NAME);
pszEntry      = (PVOID) Filespec( (PSZ) pszEntry, FILESPEC_NAME);
return stricmp( pszKeyElement, pszEntry);
}

static APIRET _getDefFileList( PSZ pszEpmMode, ULONG ulKeywordFileDate, PSZ *ppszFileList,
                               PULONG pulFileCount, PULONG pulTotalSize, PBOOL pfOutdated)
{

         APIRET         rc = NO_ERROR;
         PSZ            pszTmp;

         PSZ            pszFileList = NULL;
         ULONG          ulListSize;
         ULONG          ulFileCount = 0;
         ULONG          ulTotalSize = 0;
         BOOL           fOutdated   = FALSE;

         PSZ            pszKeywordPath = NULL;
         PSZ            pszKeywordDir;

         CHAR           szSearchMask[ _MAX_PATH];
         CHAR           szFile[ _MAX_PATH];
         HDIR           hdir;
         PSZ            pszEntry;

do
   {
   // check parm
   if ((!pszEpmMode)   ||
       (!*pszEpmMode)  ||
       (!ppszFileList) ||
       (!pulFileCount) ||
       (!pulTotalSize) ||
       (!pfOutdated))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // create a strdup of the path, so that we can tokenize it
   pszKeywordPath = getenv( "EPMKEYWORDPATH");
   if (!pszKeywordPath)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }

   pszKeywordPath = strdup( pszKeywordPath);
   if (!pszKeywordPath)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   // allocate dynamic memory fro file list
   ALLOCATEMEMORYFILE( pszFileList, 16384);

   // go through all keyword directories
   pszKeywordDir = strtok( pszKeywordPath, ";");
   while (pszKeywordDir)
      {
      // seatch all hilite files in that directory
      sprintf( szSearchMask, "%s\\%s\\*.hil", pszKeywordDir, pszEpmMode);

      // store a filenames
      hdir = HDIR_CREATE;

      while (rc == NO_ERROR)
         {
         // search it
         rc = GetNextFile( szSearchMask, &hdir,
                           szFile, sizeof( szFile));
         if (rc != NO_ERROR)
            break;

         // check if file is already in
         pszEntry = lfind( szFile, pszFileList, (PUINT) &ulFileCount, _MAX_PATH, _compareFilename);
         if (pszEntry)
            continue;

//       DPRINTF(( "HILITE: %u [%u] bytes (%u entries) (re)allocated for file list at 0x%08x\n",
//                ulListSize, _msize( pszTmp), ulListSize / _MAX_PATH, pszTmp));
         pszEntry = pszFileList + (ulFileCount * _MAX_PATH);
         strcpy( pszEntry, szFile);
         ulFileCount++;
         ulTotalSize += QueryFileSize( szFile);

         // check filedate
         if (FileDate( szFile) > ulKeywordFileDate)
            fOutdated = TRUE;

         }
      DosFindClose( hdir);

      // handle special errors
      if (rc == ERROR_NOT_ENOUGH_MEMORY)
         break;
      else if (rc = ERROR_NO_MORE_FILES)
         rc = NO_ERROR;

      // next please
      pszKeywordDir = strtok( NULL, ";");
      }

   if (rc != NO_ERROR)
      break;

   // hand over result
   *ppszFileList = pszFileList;
   *pulFileCount = ulFileCount;
   *pulTotalSize = ulTotalSize;
   *pfOutdated   = fOutdated;

   } while (FALSE);

// cleanup
if (rc)
   {
   if (pszFileList)  FREEMEMORYFILE( pszFileList);
   if (ppszFileList) *ppszFileList = NULL;
   if (pulFileCount) *pulFileCount = 0;
   }
if (pszKeywordPath) free( pszKeywordPath);
return rc;
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


static PVALUEARRAY _maintainInitValueArray( HCONFIG hinit, PSZ pszSection, PVALUEARRAY pva)
{
         PVALUEARRAY    pvaResult = pva;
         APIRET         rc = NO_ERROR;
         ULONG          i;
         BOOL           fSkip;

         PSZ            pszKey;
         ULONG          ulKeyCount;
         PVALUEARRAY    pvaNew = NULL;
         ULONG          ulBuflen;
         CHAR           szKeyList[ 1024];
         CHAR           szKeyValue[ 128];

         PSZ           *ppszAnchor;
         PSZ            pszEntry;

         PSZ           *ppszOldAnchor;
         PSZ            pszOldEntry;

do
   {
   // read the key list
   QUERYINITVALUE( hinit, pszSection, NULL, szKeyList);

// if (pva)
//    DPRINTF(( "\nmaintaining symbols array at 0x%08x:\n", pva));

   // count items and its size
   ulBuflen = sizeof( VALUEARRAY);
   ulKeyCount = 0;
   pszKey = szKeyList;
   while (*pszKey)
      {
      // does entry exist in the old array ? then skip
      fSkip = FALSE;
      if (pva)
         {
         ppszOldAnchor = bsearch( &pszKey, pva->apszValue, pva->ulCount, sizeof( PSZ), _compareValue);
         if (ppszOldAnchor)
            fSkip = TRUE;
         }

      if (!fSkip)
         {
         // add appropriate space and count up
         ulKeyCount++;
         ulBuflen += sizeof( PSZ) +
                     strlen( pszKey) + 1 +
                     QUERYINITVALUESIZE( hinit, pszSection, pszKey) + 1;
         }

      // next key
      pszKey = NEXTSTR( pszKey);
      }

   // add count and space of existing array
   if (pva)
      {
      ulBuflen   += pva->ulArraySize;
      ulKeyCount += pva->ulCount;
      }

   // allocate memory
   pvaNew = malloc( ulBuflen);
   if (!pvaNew)
      break;
   memset( pvaNew, 0, ulBuflen);
   pvaNew->ulArraySize = ulBuflen;
   pvaNew->ulCount = ulKeyCount;
   pvaResult = pvaNew;

   // remove values from old array, that we want to readd
   if (pva)
      {
      pszKey = szKeyList;
      while (*pszKey)
         {
         // can entry be found in old array ? if yes, mark it as deleted
         ppszOldAnchor = bsearch( &pszKey, pva->apszValue, pva->ulCount, sizeof( PSZ), _compareValue);
         if (ppszOldAnchor)
            {
//          DPRINTF(( "HILITE: delete entry %s\n", *ppszOldAnchor));
            **ppszOldAnchor = 0;
            }

         // next key
         pszKey = NEXTSTR( pszKey);
         }
      } // if (pva)

   // transfer existing entries
   ppszAnchor   = pvaNew->apszValue;
   pszEntry     = (PSZ) pvaNew->apszValue + (ulKeyCount * sizeof( PSZ));
   if (pva)
      {
      for ( i = 0, ppszOldAnchor = pva->apszValue; i < pva->ulCount; i++, ppszOldAnchor++, ppszAnchor++)
         {
         // store entry
         pszOldEntry = *ppszOldAnchor;
         if (!*pszOldEntry)
            {
            // skip this entry, it has beeen deleted
            ppszAnchor--;
            continue;
            }

//       DPRINTF(( "HILITE: transfer entry 0x%08x / 0x%08x: %s - %s\n",
//                 pszOldEntry, NEXTSTR( pszOldEntry),
//                 pszOldEntry, NEXTSTR( pszOldEntry)));

         *ppszAnchor = pszEntry;
         strcpy( pszEntry, pszOldEntry);

//       DPRINTF(( "HILITE:      new entry 0x%08x / 0x%08x: %s - ",
//                 pszEntry, NEXTSTR( pszEntry), pszEntry));

         pszEntry = NEXTSTR( pszEntry);
         pszOldEntry = NEXTSTR( pszOldEntry);

         strcpy( pszEntry, pszOldEntry);
//       DPRINTF(( "%s\n", pszEntry));

         pszEntry = NEXTSTR( pszEntry);
         }
      }

   // add new values to array
   // duplicates are now removed
   pszKey = szKeyList;
   while (*pszKey)
      {
      // store entry
      *ppszAnchor = pszEntry;

      strcpy( pszEntry, pszKey);
      QUERYINITVALUE( hinit, pszSection, pszKey, szKeyValue);
//    DPRINTF(( "HILITE: add entry %s - %s\n", pszEntry, szKeyValue));
      pszEntry = NEXTSTR( pszEntry);

      strcpy( pszEntry, szKeyValue);
      pszEntry = NEXTSTR( pszEntry);

//    DPRINTF(( "HILITE: array: store %s=%s\n", pszKey, szKeyValue));

      // next key
      ppszAnchor++;
      pszKey = NEXTSTR( pszKey);
      }

   // sort the entries
   qsort( pvaNew->apszValue, pvaNew->ulCount, sizeof( PSZ), _compareValue);

   // throw away the old array
   if (pva)
      free( pva);

   } while (FALSE);

return pvaResult;

}

// -----------------------------------------------------------------------------

static PSZ _queryInitValue( PVALUEARRAY pva, PSZ pszKey)
{
         PSZ            pszResult = NULL;
         PSZ           *ppszEntry;

do
   {
   // search the entry
   ppszEntry = bsearch( &pszKey, pva->apszValue, pva->ulCount, sizeof( PSZ), _compareValue);
   if (!ppszEntry)
   break;

   // report the value
   pszResult = NEXTSTR( *ppszEntry);

   } while (FALSE);

return pszResult;

}

// -----------------------------------------------------------------------------

static VOID _dumpInitValueArray( PVALUEARRAY pva)
{


         PSZ           *ppszEntry = pva->apszValue;
         PSZ            pszEntry;
         ULONG          i;

printf( "\nSymbols from array at 0x%08x:\n", pva);

for (i = 0; i < pva->ulCount; i++)
   {
   pszEntry =  *ppszEntry;
   printf( "-> 0x%08x / 0x%08x: %s %s\n",
           *ppszEntry, NEXTSTR( *ppszEntry),
           *ppszEntry, NEXTSTR( *ppszEntry));
   ppszEntry++;
   }
printf( "%u entries\n\n", i);
}

// #############################################################################


static APIRET _assembleKeywordFile(  PSZ pszEpmMode, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         PSZ            p;
         PSZ            pszTmpDir;

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

         CHAR           szKeywordFile[ _MAX_PATH];
         ULONG          ulKeywordFileDate;
         BOOL           fOutdated = FALSE;

         // ----------------------------------

         PSZ            pszFileList = NULL;
         ULONG          ulFileCount;
         ULONG          ulTotalSize;

         // ----------------------------------

         PSZ            pszSectionDelimiter = NULL;
         PSZ            pszSectionKeywords  = NULL;
         PSZ            pszSectionSpecial   = NULL;
         PSZ            pszSectionBreakChar = NULL;
         PSZ            pszSectionEndChar   = NULL;

         PSZ            pszCurrentDelimiter;
         PSZ            pszCurrentKeywords;
         PSZ            pszCurrentSpecial;
         PSZ            pszCurrentBreakChar;
         PSZ            pszCurrentEndChar;

static   PSZ            pszHeaderMask = "þ%s\r\n";  // take 'þ' character as comment in generated epmkwds files

         // ----------------------------------
         ULONG          ulCurrentFile;
         PSZ            pszSourceFile;
         FILE          *pfile = NULL;
         ULONG          ulLineCount;
         CHAR           szLine[ 1024];
         PSZ            pszLine;
         CHAR           szCurrentSection[ 64];
         PSZ            pszCurrentSectionColors;
         CHAR           szEntryColors[32];
         BOOL           fEntryColors;

// keep these definitions in sync !!!
         ULONG          ulSectionIndex;
         PSZ            apszSpecialSections[] = {"", "COMMENT", "LITERAL", "SPECIAL", "OPERATOR", "BREAKCHAR", "ENDCHAR"};
#define  COUNT_SPECIALSECTION (sizeof( apszSpecialSections) / sizeof( PSZ))
#define  SECTION_DEFAULT   0
#define  SECTION_COMMENT   1
#define  SECTION_LITERAL   2
#define  SECTION_SPECIAL   3
#define  SECTION_OPERATOR  4
#define  SECTION_BREAKCHAR 5
#define  SECTION_ENDCHAR   6


         PSZ            pszStartStr;
         PSZ            pszStopStr;
         PSZ            pszBreakStr;

         ULONG          ulThisSectionIndex;

         // ----------------------------------

         PSZ            pszHiliteContents = NULL;
         ULONG          ulHiliteContentsLen;
         PSZ            pszCurrent;

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

   pvaColors  = _maintainInitValueArray( hinitGlobals, pszColorsSection, NULL);
   pvaSymbols = _maintainInitValueArray( hinitGlobals, pszSymbolsSection, NULL);


   // - read defaults of the mode
   rc = _openInitFile( &hinitDefault, "EPMKEYWORDPATH", "%s\\default.ini", pszEpmMode);
   if (rc != NO_ERROR)
      break;

   QUERYINITVALUE( hinitDefault, pszGlobalSection, "CHARSET",       szCharset);
   QUERYINITVALUE( hinitDefault, pszGlobalSection, "DEFEXTENSIONS", szDefExtensions);
   QUERYINITVALUE( hinitDefault, pszGlobalSection, "CASESENSITIVE", szValue);
   fCaseSensitive = atol( szValue);

   // -----------------------------------------------

// _dumpInitValueArray( pvaSymbols);

   // add/replace with symbols from <mode>\global.ini
   pvaSymbols = _maintainInitValueArray( hinitDefault, pszSymbolsSection, pvaSymbols);

// _dumpInitValueArray( pvaSymbols);

   // -----------------------------------------------

   // replace color values in symbol defs
   ppszEntry = pvaSymbols->apszValue;
   for (i = 0; i < pvaSymbols->ulCount; i++)
      {

               PSZ            pszValueBuf;
               ULONG          ulValueLen;
               PSZ            pszValue;

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
            pszValue = NEXTSTR( *ppszSymbolValue);
            strcat( szValue, " ");
            strcat( szValue, pszValue);
//          DPRINTF(( "HILITE: %s: %s -> %s\n", pszEntry, pszSymbol, pszValue));
            }

         // next symbol
         pszSymbol = strtok( NULL, " ");
         }

      // check buffer
      _stripblanks( szValue);
      if (strlen( szValue) <= ulValueLen)
         strcpy( pszValueBuf, szValue);

      // next entry
      ppszEntry++;
      }

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
   pszTmpDir = getenv( "TMP");
   if (!pszTmpDir)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }
   // no keyword file yet, create a new one
   // for that create subdirectory below TMP
   sprintf( szKeywordFile, "%s\\nepmd\\mode",  pszTmpDir);
   rc = CreatePath( szKeywordFile);
   if ((rc != NO_ERROR) && (rc != ERROR_ACCESS_DENIED))
      break;
   sprintf( _EOS( szKeywordFile), "\\%s", pszEpmMode);
   strlwr( szKeywordFile);

   // --- hand over filename already here

   // check result buffer
   if (strlen( szKeywordFile) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szKeywordFile);


   // check for the file date - if not exists, will return -1,
   // then reset to zero to force a rebuild
   ulKeywordFileDate = FileDate( szKeywordFile);
   if (ulKeywordFileDate == - 1)
      ulKeywordFileDate  = 0;

   // -----------------------------------------------

   // get the list of files
   ulFileCount = 0;
   rc = _getDefFileList( pszEpmMode, ulKeywordFileDate, &pszFileList, &ulFileCount, &ulTotalSize, &fOutdated);
   if (rc != NO_ERROR)
      break;

   // if result file is not outdated, return with no error
   if (!fOutdated)
      break;

   // -----------------------------------------------

   // open up in-memory files for the six sections
   ALLOCATEMEMORYFILE( pszSectionDelimiter, ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionKeywords,  ulTotalSize * 2);
   ALLOCATEMEMORYFILE( pszSectionSpecial,   ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionBreakChar, ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionEndChar,   ulTotalSize);

   pszCurrentDelimiter = pszSectionDelimiter;
   pszCurrentKeywords  = pszSectionKeywords;
   pszCurrentSpecial   = pszSectionSpecial;
   pszCurrentBreakChar = pszSectionBreakChar;
   pszCurrentEndChar   = pszSectionEndChar;

   // -----------------------------------------------

   // loop thru all files
   for (ulCurrentFile = 0, pszSourceFile = pszFileList;
           ulCurrentFile < ulFileCount;
           ulCurrentFile++, pszFileList += _MAX_PATH)
      {

      do
         {
         // open the file
         DPRINTF(( "HILITE: process file %s\n", pszSourceFile));
         pfile = fopen( pszSourceFile, "r");
         szCurrentSection[ 0] = 0;
         pszCurrentSectionColors = 0;
         pszLine = szLine;
         ulLineCount = 0;

         while (!feof( pfile))
            {
            // read line
            if (!fgets( szLine, sizeof( szLine),pfile))
               break;
            ulLineCount++;

            // skip comments - the comment char must be on the first column !
            if ((*pszLine == CHAR_COMMENT) ||
                (*pszLine == 0))
               continue;

            // skip leading blanks anyway (also trailing newline)
            _stripblanks( pszLine);

            // skip empty lines
            if (*pszLine == 0)
               continue;

            // handle new section
            if (*pszLine == CHAR_SECTION_START)
               {
               strcpy( pszLine, pszLine + 1);
               p = strchr( pszLine, CHAR_SECTION_END);
               if (!p)
                  continue;
               *p = 0;

               // if there exists a symbol, store values
               strupr( pszLine);
               pszCurrentSectionColors = _queryInitValue( pvaSymbols, pszLine);
               if (pszCurrentSectionColors)
                  {
                  strcpy( szCurrentSection, strupr( pszLine));
//                DPRINTF(( "HILITE: - process section %s with colors: %s\n", szCurrentSection, pszCurrentSectionColors));
                  }
               else
                  DPRINTF(( "HILITE: - error: skipping invalid section %s from line %u on\n", pszLine, ulLineCount));

               // check if the values of the current symbol belong to a special section
               ulSectionIndex = 0;
               for (i = 1; i < COUNT_SPECIALSECTION; i++)
                  {
                  if (!strcmp( apszSpecialSections[ i], szCurrentSection))
                     {
                     ulSectionIndex = i;
//                   DPRINTF(( "HILITE: - special section recognized, index %u\n", ulSectionIndex));
                     }
                  }

               continue;
               }

            // from here, skip line if no valid section has been found
            if (!pszCurrentSectionColors)
               continue;

            // tokenize line
            pszStartStr = strtok( pszLine, " ");
            pszStopStr  = strtok( NULL,    " ");
            pszBreakStr = strtok( NULL,    " ");
            p           = strtok( NULL,    " ");
            if (p)
               {
               DPRINTF(( "HILITE: - error: skipping invalid line %u\n", ulLineCount));
               continue;
               }

            // change section index for this section to comment
            // if stopstr is given and is no color symbol
            fEntryColors = FALSE;
            strcpy( szEntryColors, pszCurrentSectionColors);
            if ((pszStopStr) &&
                (ulSectionIndex != SECTION_COMMENT) &&
                (ulSectionIndex != SECTION_LITERAL))
               {
               do
                  {
                  // replace symbol with color value
                  p = _queryInitValue( pvaSymbols, pszStopStr);
                  if (p)
                     {
                     strcpy( szEntryColors, p);
                     fEntryColors = TRUE;
                     break;
                     }

                  // replace two color names with color values
                  if (!pszBreakStr) // we need two color names
                     break;
                  p = _queryInitValue( pvaColors, pszStopStr);
                  if (p)
                     sprintf( szEntryColors, "%s ", p);
                  else
                     break;
                  p = _queryInitValue( pvaColors, pszBreakStr);
                  if (p)
                     {
                     strcat( szEntryColors, p);
                     fEntryColors = TRUE;
                     }
                  else
                     strcpy( szEntryColors, pszCurrentSectionColors); // reset here
                  } while (FALSE);
               }

            // handle different sections
            switch (ulSectionIndex)
               {
               case SECTION_DEFAULT:
                  sprintf( pszCurrentKeywords, "%s %s\r\n", pszStartStr, szEntryColors);
                  pszCurrentKeywords = _EOS( pszCurrentKeywords);
                  break;

               case SECTION_COMMENT:
               case SECTION_LITERAL:
                  sprintf( pszCurrentDelimiter, "%s %s",
                           pszStartStr, szEntryColors);
                  if (pszStopStr)
                     sprintf( _EOS( pszCurrentDelimiter), " %s", pszStopStr);
                  if (pszBreakStr)
                     sprintf( _EOS( pszCurrentDelimiter), " %s", pszBreakStr);
                  strcat( pszCurrentDelimiter, "\r\n");
                  pszCurrentDelimiter = _EOS( pszCurrentDelimiter);
                  pszCurrentKeywords = _EOS( pszCurrentKeywords);
                  break;

               case SECTION_SPECIAL:
               case SECTION_OPERATOR:
                  sprintf( pszCurrentSpecial, "%s %s\r\n", pszStartStr, szEntryColors);
                  pszCurrentSpecial = _EOS( pszCurrentSpecial);
                  break;

               case SECTION_BREAKCHAR:
                  sprintf( pszCurrentBreakChar, "%s", pszStartStr);
                  if (fEntryColors)
                     sprintf( _EOS( pszCurrentBreakChar), " %s", szEntryColors);
                  strcat( pszCurrentBreakChar, "\r\n");
                  pszCurrentBreakChar = _EOS( pszCurrentBreakChar);
                  break;

               case SECTION_ENDCHAR:
                  sprintf( pszCurrentEndChar, "%s", pszStartStr);
                  if (fEntryColors)
                     sprintf( _EOS( pszCurrentEndChar), " %s", szEntryColors);
                  strcat( pszCurrentEndChar, "\r\n");
                  pszCurrentEndChar = _EOS( pszCurrentEndChar);
                  break;

               } // switch (ulThisSectionIndex)

            } // while (!feof( pinit->pfile))


         } while (FALSE);

      // cleanup
      if (pfile) fclose( pfile);

      } // for [all files]

   // -----------------------------------------------

   DPRINTF(( "HILITE: - assembling hilite file: %s\n", szKeywordFile));

   // determine the length
   ulHiliteContentsLen = (pszCurrentDelimiter - pszSectionDelimiter) +
                         (pszCurrentKeywords  - pszSectionKeywords)  +
                         (pszCurrentSpecial   - pszSectionSpecial)   +
                         (pszCurrentBreakChar - pszSectionBreakChar) +
                         (pszCurrentEndChar   - pszSectionEndChar)   +
                         (strlen( szCharset) + 32);

   DPRINTF(( "- total len of all hilite data is: %u\n", ulHiliteContentsLen));

   rc = MmfAlloc( (PVOID*)&pszHiliteContents,
                  szKeywordFile,
                  MMF_ACCESS_READWRITE |
                  MMF_OPENMODE_RESETFILE,
                  ulHiliteContentsLen + 4096);
   if (rc != NO_ERROR)
      break;

// DPRINTF(( "- allocated buffer at 0x%08x, len %u, end address 0x%08x\n",
//           pszHiliteContents, ulHiliteContentsLen, pszHiliteContents + ulHiliteContentsLen));

   pszCurrent = pszHiliteContents;

   // first of all write CHARSET
   sprintf( pszCurrent, pszHeaderMask, "CHARSET");
// DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
   pszCurrent = _EOS( pszCurrent);
   sprintf( pszCurrent, "%s\r\n", szCharset);
   pszCurrent = _EOS( pszCurrent);

   // add all sections, if something in it
   if (pszCurrentDelimiter - pszSectionDelimiter)
      {
      sprintf( pszCurrent, pszHeaderMask, (fCaseSensitive) ? "DELIM"    : "DELIMI");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionDelimiter);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentKeywords  - pszSectionKeywords)
      {
      sprintf( pszCurrent, pszHeaderMask, (fCaseSensitive) ? "KEYWORDS" : "INSENSITIVE");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionKeywords);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentSpecial   - pszSectionSpecial)
      {
      sprintf( pszCurrent,  pszHeaderMask, (fCaseSensitive) ? "SPECIAL"  : "SPECIALI");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionSpecial);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentBreakChar - pszSectionBreakChar)
      {
      sprintf( pszCurrent,  pszHeaderMask, "BREAK");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionBreakChar);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentEndChar   - pszSectionEndChar)
      {
      sprintf( pszCurrent,  pszHeaderMask, "ENDCHAR");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionEndChar);
      pszCurrent = _EOS( pszCurrent);
      }

   // set filesize
   ulHiliteContentsLen = strlen( pszHiliteContents);
   rc = MmfSetSize( pszHiliteContents, ulHiliteContentsLen);
// DPRINTF(( "-  setting filesize to size of %u bytes, rc=%u\n", ulHiliteContentsLen, rc));

   // write temporary file
   rc = MmfUpdate( pszHiliteContents);
// DPRINTF(( "-  update file, rc=%u\n", rc));


   } while (FALSE);

// cleanup

if (pvaColors)           free( pvaColors);
if (pvaSymbols)          free( pvaSymbols);
if (pszModeCopy)         free( pszModeCopy);

if (pszFileList)         FREEMEMORYFILE( pszFileList);
if (pszSectionDelimiter) FREEMEMORYFILE( pszSectionDelimiter);
if (pszSectionKeywords)  FREEMEMORYFILE( pszSectionKeywords);
if (pszSectionSpecial)   FREEMEMORYFILE( pszSectionSpecial);
if (pszSectionBreakChar) FREEMEMORYFILE( pszSectionBreakChar);
if (pszSectionEndChar)   FREEMEMORYFILE( pszSectionEndChar);
if (pszHiliteContents)   FREEMEMORYFILE( pszHiliteContents);

if (hconfig) CloseConfig( hconfig);
if (hinitDefault) InitCloseProfile( hinitDefault, FALSE);
if (hinitGlobals) InitCloseProfile( hinitGlobals, FALSE);
return rc;
}

// #############################################################################

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
      rc = _searchFile( "EPMPATH", szValue, sizeof( szValue), "epmkwds.%s", pszEpmMode);
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

