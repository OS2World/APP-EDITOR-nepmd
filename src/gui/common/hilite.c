/****************************** Module Header *******************************
*
* Module Name: hilite.c
*
* Generic routines to support extended keyword hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.c,v 1.34 2006-11-16 20:50:01 jbs Exp $
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
#include "libreg.h"
#include "hilite.h"
#include "init.h"
#include "instval.h"
#include "file.h"
#include "mmf.h"
#include "eas.h"

// --- define to allow color value names in HIL files
#define ALLOW_COLOR_VALUES 1

// --- defines for detailed debug messages

#define DEBUG_DUMPARRAYDETAILS 0

// debug output on func entry and exit
#define DEBUG_NOMESSAGE_ENTEREXIT 1

#if DEBUG_NOMESSAGE_ENTEREXIT
#undef FUNCENTER
#undef FUNCEXIT
#undef FUNCEXITRC
#define FUNCENTER
#define FUNCEXIT
#define FUNCEXITRC
#endif

// ----- values for control files for creating hilite files -------------

// definitions for file format for *.hil
#define CHAR_HILCOMMENT      ';'
#define CHAR_SECTION_START   '['
#define CHAR_SECTION_END     ']'

// default values
#define STR_KWDSCOMMENT      "þ"
#define STR_CASESENSITIVE    "0"

// global string vars
static   PSZ            pszEnvnameEpmModepath = "EPMMODEPATH";
static   PSZ            pszEnvnameEpmPath     = "EPMPATH";

static   PSZ            pszGlobalSection  = "GLOBAL";
static   PSZ            pszColorsSection  = "COLORS";
static   PSZ            pszSymbolsSection = "SYMBOLS";

static   PSZ            pszFileInfoListEaName = "NEPMD.FileListInfo";

static   PSZ            pszKeywordNone    = "NONE:";

// defines for strings used only once
#define SEARCHMASK_HILITEFILES "%s\\%s\\*.hil"
#define SEARCHMASK_TARGETFILES "%s.???"
#define SEARCHMASK_MODEDIR     "%s\\nepmd\\mode"
#define SEARCHMASK_GLOBALINI   "global.ini"
#define SEARCHMASK_DEFAULTINI  "%s\\default.ini"
#define SEARCHMASK_CUSTOMINI   "%s\\custom.ini"
#define SEARCHMASK_EPMKWDS     "epmkwds.%s"

// --- keyword strings for the GLOBAL section of DEFAULT.INI and CUSTOM.INI

// comment char for .hil files (undocumented)
#define KEY_HILCOMMENTCHAR        "HILCOMMENTCHAR"
// used for mode determination and for building EPM highlighting files
#define KEY_CHARSET               "CHARSET"
#define KEY_ADD_CHARSET           "ADD_CHARSET"
#define KEY_CASESENSITIVE         "CASESENSITIVE"
#define KEY_DEFEXTENSIONS         "DEFEXTENSIONS"
#define KEY_ADD_DEFEXTENSIONS     "ADD_DEFEXTENSIONS"
#define KEY_DEFNAMES              "DEFNAMES"
#define KEY_ADD_DEFNAMES          "ADD_DEFNAMES"
// the following keys can hold word list, not only single words
#define KEY_LINECOMMENT               "LINECOMMENT"
#define KEY_LINECOMMENTPOS            "LINECOMMENTPOS"
#define KEY_LINECOMMENTNEEDSPACE      "LINECOMMENTNEEDSPACE"
#define KEY_LINECOMMENTOVERRIDEMULTI  "LINECOMMENTOVERRIDEMULTI"
#define KEY_MULTILINECOMMENTSTART     "MULTILINECOMMENTSTART"
#define KEY_MULTILINECOMMENTEND       "MULTILINECOMMENTEND"
#define KEY_MULTILINECOMMENTNESTED    "MULTILINECOMMENTNESTED"
// additional keys to support COMMENT.E
#define KEY_LINECOMMENTADDSPACE       "LINECOMMENTADDSPACE"       // for defc comment
// #define KEY_LINECOMMENTPREFERRED      "LINECOMMENTPREFERRED"      // for defc comment
#define KEY_PREFERREDCOMMENT          "PREFERREDCOMMENT"          // for defc comment

// --- keyword strings for NEPMD.INI (these settings are written to NEPMD.INI)

// also used for mode determination and for building EPM highlighting files
#define REGKEY_CHARSET               "CharSet"
#define REGKEY_CASESENSITIVE         "CaseSensitive"
#define REGKEY_DEFEXTENSIONS         "DefExtensions"
#define REGKEY_DEFNAMES              "DefNames"
// the following keys can hold word list, not only single words
#define REGKEY_LINECOMMENT               "LineComment"
#define REGKEY_LINECOMMENTPOS            "LineCommentPos"
#define REGKEY_LINECOMMENTNEEDSPACE      "LineCommentNeedSpace"
#define REGKEY_LINECOMMENTOVERRIDEMULTI  "LineCommentOverrideMulti"
#define REGKEY_MULTILINECOMMENTSTART     "MultiLineCommentStart"
#define REGKEY_MULTILINECOMMENTEND       "MultiLineCommentEnd"
#define REGKEY_MULTILINECOMMENTNESTED    "MultiLineCommentNested"
// additional keys to support COMMENT.E
#define REGKEY_LINECOMMENTADDSPACE       "LineCommentAddSpace"       // Word list
// #define REGKEY_LINECOMMENTPREFERRED      "LineCommentPreferred"
#define REGKEY_PREFERREDCOMMENT          "PreferredComment"          // single "word"

// ----------------------------------------------------------------------

// some useful macros
#define ALLOCATEMEMORYFILE(p,s)                            \
rc = MmfAlloc( hmmf, (PVOID*)&p, MMF_FILE_INMEMORY, 0, s); \
if (rc != NO_ERROR)                                        \
   break;

#define FREEMEMORYFILE(p)   MmfFree( hmmf, p)

#define QUERYOPTINITVALUE(h,s,k,t,d) \
InitQueryProfileString( h, s, k, d, t, sizeof( t));

#define QUERYINITVALUE(h,s,k,t)                             \
if (!InitQueryProfileString( h, s, k, NULL, t, sizeof( t))) \
   {                                                        \
   rc = ERROR_INVALID_DATA;                                 \
   break;                                                   \
   }
#define QUERYINITVALUESIZE(h,s,k) _queryInitValueSize( h, s, k)

// ----------------------------------------------------------------------

#ifdef DEBUG
#if DEBUG_DUMPARRAYDETAILS
#define DUMPINITVALUEARRAY(p) _dumpInitValueArray(p)
#define DPRINTF_ARRAY(p) DPRINTF(p)
#else
#define DUMPINITVALUEARRAY(p)
#define DPRINTF_ARRAY(p)
#endif
#else
#define DUMPINITVALUEARRAY(p)
#define DPRINTF_ARRAY(p)
#endif

// structure for an array of values
// used by _maintainInitValueArray and _dumpInitValueArray
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

    p = string;
    if (*p != 0)
       {
       p += strlen(p) - 1;
       while ((*p <= 32) && (p >= string))
          {
          *p = 0;
          p--;
          }
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

static APIRET _openInitFile( PHINIT phinit, PSZ pszSearchPathName, PSZ pszSearchMask, PSZ pszEpmMode,
                             PSZ pszBuffer, ULONG ulBuflen)
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

   // hand over filename
   if (pszBuffer)
      {
      if (strlen( szFile) + 1 > ulBuflen)
         {
         rc = ERROR_BUFFER_OVERFLOW;
         break;
         }
      strcpy( pszBuffer, szFile);
      strlwr( pszBuffer);
      }

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static APIRET _queryInitValueSize( HINIT hinit, PSZ pszSection, PSZ pszKey)
{
         ULONG          ulDataLen = 0;

InitQueryProfileSize( hinit, pszSection, pszKey, &ulDataLen);
return ulDataLen;
}

// -----------------------------------------------------------------------------

int _compareFilename( const void *pszKeyElement, const void *pszEntry)
{
pszKeyElement = (PVOID) Filespec( (PSZ) pszKeyElement, FILESPEC_NAME);
pszEntry      = (PVOID) Filespec( (PSZ) pszEntry, FILESPEC_NAME);
return stricmp( pszKeyElement, pszEntry);
}

static APIRET _getDefFileList( HMMF hmmf, PSZ pszEpmMode, ULONG ulKeywordFileDate, PSZ *ppszFileList,
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
   pszKeywordPath = getenv( pszEnvnameEpmModepath);
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

   // allocate dynamic memory from file list
   ALLOCATEMEMORYFILE( pszFileList, 16384);

   // go through all keyword directories
   pszKeywordDir = strtok( pszKeywordPath, ";");
   while (pszKeywordDir)
      {
      // seatch all hilite files in that directory
      sprintf( szSearchMask, SEARCHMASK_HILITEFILES, pszKeywordDir, pszEpmMode);

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
         strlwr( pszEntry );
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

   if (pva)
      DPRINTF_ARRAY(( "\nmaintaining symbols array at 0x%08x:\n", pva));

   // count items and its size
   ulBuflen = sizeof( VALUEARRAY);
   ulKeyCount = 0;
   pszKey = szKeyList;
   while (*pszKey)
      {
      // does entry exist in the old array? then skip
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
         // can entry be found in old array? if yes, mark it as deleted
         ppszOldAnchor = (PVOID)lfind( (PSZ)&pszKey, (PSZ)pva->apszValue, (PUINT)&pva->ulCount, sizeof( PSZ), _compareValue);
         if (ppszOldAnchor)
            {
            DPRINTF_ARRAY(( "HILITE: delete entry %s\n", *ppszOldAnchor));
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

         DPRINTF_ARRAY(( "HILITE: transfer entry 0x%08x / 0x%08x: %s - %s\n",
                         pszOldEntry, NEXTSTR( pszOldEntry),
                         pszOldEntry, NEXTSTR( pszOldEntry)));

         *ppszAnchor = pszEntry;
         strcpy( pszEntry, pszOldEntry);

         DPRINTF_ARRAY(( "HILITE:      new entry 0x%08x / 0x%08x: %s - ",
                         pszEntry, NEXTSTR( pszEntry), pszEntry));

         pszEntry = NEXTSTR( pszEntry);
         pszOldEntry = NEXTSTR( pszOldEntry);

         strcpy( pszEntry, pszOldEntry);
         DPRINTF_ARRAY(( "%s\n", pszEntry));

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
      DPRINTF_ARRAY(( "HILITE: add entry %s - %s\n", pszEntry, szKeyValue));
      pszEntry = NEXTSTR( pszEntry);

      strcpy( pszEntry, szKeyValue);
      pszEntry = NEXTSTR( pszEntry);

      DPRINTF_ARRAY(( "HILITE: array: store %s=%s\n", pszKey, szKeyValue));

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
// Determine the filename for a tmp EPM kwds file. Compare EA of the existing
// EPM kwds file with the mode's INI and HIL file data. If outdated, rebuild it
// using these files. The EPM kwds file is created in a tmp dir. Therefore
// following env vars are queried, while one must exist: EPMKWDSTMP, TMP, TEMP.
// A subdir "nepmd" is created in the tmp dir, holding the kwds files with the
// filename = mode.
//
// Reads:
//    pszEpmMode  mode
//    ulOptions   1 if checking for outdated files should be suppressed; also
//                used to control the 1st word of the parm for toggle_parse
// Returns/alters via call by reference:
//    pfReload    1 if tmp EPM kwds file was rebuilt; used to determine the
//                1st word of the parm for toggle_parse
//    pszBuffer   fully qualified tmp EPM kwds filename
// Returns:
//    rc          0 if no error
//
// Called by NepmdActivateHighlight (E proc):
//    NepmdQueryHighlightArgs         (NEPMDLIB.C)
//       QueryHilightFile             (HILITE.C)
//          _assembleKeywordFile      (HILITE.C)
//
// E calls:
//    a_togl_hilit                    (SAMPACTN.E)
//       ActivateHighlighting         (STDCMDS.E)
//          NepmdActivateHighlight    (ACTIVATEHIGHLIGHT.E)
//    toggle_highlight, toggle_default_highlight  (NEWMENU.E)
//       SetHighlight                 (MODEEXECUTE.E)
//          NepmdActivateHighlight    (ACTIVATEHIGHLIGHT.E)
//    ProcessLoadSettings             (MODEEXECUTE.E)
//       NepmdActivateHighlight       (ACTIVATEHIGHLIGHT.E)
//
// NepmdActivateHighlight uses the toggle_parse command (STDCTRL.E) to execute
// the highlighting. toggle_parse accepts 0, 1 or 2 as the first word of its
// parm:
//    0   unhighlight
//    1   highlight, load the kwds file if not already loaded
//    2   highlight and force reloading of the kwds file to reparse it

static APIRET _assembleKeywordFile( PSZ pszEpmMode, ULONG ulOptions, PBOOL pfReload,
                                    HCONFIG hconfig,
                                    PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         HMMF           hmmf = NULLHANDLE;

         PSZ            p;
         PSZ            pszTmpDir;

         PSZ           *ppszEntry;
         PSZ            pszEntry;
         PSZ            pszSymbol;
         PSZ           *ppszSymbolValue;
         CHAR           szValue[ _MAX_PATH];
         CHAR           szCustomValue[ _MAX_PATH];

         // ----------------------------------

         HINIT          hinitGlobals = NULLHANDLE;
         CHAR           szInitGlobalFilename[ _MAX_PATH];
         HINIT          hinitDefault = NULLHANDLE;
         CHAR           szInitDefaultFilename[ _MAX_PATH];

         // ----------------------------------

         HINIT          hinitCustom = NULLHANDLE;
         CHAR           szInitCustomFilename[ _MAX_PATH];
         BOOL           fCustomLoaded = FALSE;

         CHAR           szCustomCharset[ _MAX_PATH];
         CHAR           szCustomAddCharset[ _MAX_PATH];

         // ----------------------------------

         ULONG          ulCaseSensitive;
         ULONG          ulInfoSize;
         BOOL           fCaseSensitive = FALSE;

         // ----------------------------------

         PVALUEARRAY    pvaColors = NULL;
         PVALUEARRAY    pvaSymbols = NULL;

         // ----------------------------------

         CHAR           szHilCommentChar[ 20];

         // ----------------------------------

static   PSZ            pszRegPathTemplate = "\\NEPMD\\User\\Mode\\%s\\%s";
         CHAR           szRegPath[ _MAX_PATH];
         BOOL           fImplicitOpen = FALSE;

         // ----------------------------------

         CHAR           szKeywordFile[ _MAX_PATH];
         ULONG          ulKeywordFileDate;
         BOOL           fOutdated = FALSE;

         // ----------------------------------

         PSZ            pszFileList = NULL;
         ULONG          ulFileCount;
         ULONG          ulTotalSize;

         PSZ            pszOldFileInfoList = NULL;

static   PSZ            pszFileInfoMask = "%s %s %u %u\r\n";
         PSZ            pszFileInfoList = NULL;
         ULONG          ulInfoListSize  = 0;

         // ----------------------------------

         PSZ            pszSectionDelimiter = NULL;
         PSZ            pszSectionDelimiteri = NULL;
         PSZ            pszSectionKeywords  = NULL;
         PSZ            pszSectionSpecial   = NULL;
         PSZ            pszSectionBreakChar = NULL;
         PSZ            pszSectionEndChar   = NULL;

         PSZ            pszCurrentDelimiter;
         PSZ            pszCurrentDelimiteri;
         PSZ            pszCurrentKeywords;
         PSZ            pszCurrentSpecial;
         PSZ            pszCurrentBreakChar;
         PSZ            pszCurrentEndChar;

static   PSZ            pszHeaderMask = "\r\n%s%s\r\n";

         // ----------------------------------
         ULONG          ulCurrentFile;
         PSZ            pszSourceFile;
         FILE          *pfile = NULL;
         ULONG          ulLineCount;
         CHAR           szLine[ 1024];
         BOOL           fSectionStart;
         PSZ            pszLine;
         CHAR           szCurrentSection[ 64];
         PSZ            pszCurrentSectionColors;
         CHAR           szEntryColors[32];
         BOOL           fEntryColors;

// keep these definitions in sync!!!
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
         PSZ            pszStartPos;
         PSZ            pszSymbolValue;
         PSZ            pszColorValue1;
         PSZ            pszColorValue2;
         PSZ            pszInvalid;
         ULONG          ulSelectIndex;

         ULONG          ulThisSectionIndex;

         // ----------------------------------

         PSZ            pszHiliteContents = NULL;
         ULONG          ulHiliteContentsLen;
         PSZ            pszCurrent;

         CHAR           szCharset[ _MAX_PATH];
         CHAR           szFileBuffer[ 2* _MAX_PATH + 1];
         CHAR           szAddFileBuffer[ _MAX_PATH];

         PSZ   apszKeys[] =
         {
    // used for mode determination and for building EPM highlighting files
    // Each line is a set of 3 related keys:
    //       File key                        Registry key                     "ADD_" file key
             KEY_CHARSET,                    REGKEY_CHARSET,                  KEY_ADD_CHARSET,
             KEY_DEFEXTENSIONS,              REGKEY_DEFEXTENSIONS,            KEY_ADD_DEFEXTENSIONS,
             KEY_DEFNAMES,                   REGKEY_DEFNAMES,                 KEY_ADD_DEFNAMES,
             KEY_CASESENSITIVE,              REGKEY_CASESENSITIVE,            "",
             // the following keys can hold word list, not only single words
             KEY_LINECOMMENT,                REGKEY_LINECOMMENT,              "",
             KEY_LINECOMMENTPOS,             REGKEY_LINECOMMENTPOS,           "",
             KEY_LINECOMMENTNEEDSPACE,       REGKEY_LINECOMMENTNEEDSPACE,     "",
             KEY_LINECOMMENTOVERRIDEMULTI,   REGKEY_LINECOMMENTOVERRIDEMULTI, "",
             KEY_MULTILINECOMMENTSTART,      REGKEY_MULTILINECOMMENTSTART,    "",
             KEY_MULTILINECOMMENTEND,        REGKEY_MULTILINECOMMENTEND,      "",
             KEY_MULTILINECOMMENTNESTED,     REGKEY_MULTILINECOMMENTNESTED,   "",
             // additional keys to support COMMENT.E
             KEY_LINECOMMENTADDSPACE,        REGKEY_LINECOMMENTADDSPACE,      "",
             KEY_PREFERREDCOMMENT,           REGKEY_PREFERREDCOMMENT,         ""
         };

#define NUM_KEYS     (sizeof(apszKeys)/sizeof(PSZ))

FUNCENTER;

do
   {
   // check parms
   if ((!pszEpmMode)  ||
       (!*pszEpmMode) ||
       (!pfReload)    ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check env
   do
      {
      pszTmpDir = getenv( "EPMKWDSTMP");
      if (pszTmpDir)
         break;

      pszTmpDir = getenv( "TMP");
      if (pszTmpDir)
         break;

      pszTmpDir = getenv( "TEMP");

      } while (FALSE);

   if (!pszTmpDir)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }

   // init target vars
   *pfReload = TRUE;
   memset( pszBuffer, 0, ulBuflen);

   // -----------------------------------------------

   // get the name and date of the temporary file

   // get keywordfile
   strupr( pszEpmMode);

   // no keyword file yet, create a new one
   // for that create subdirectory below TMP
   sprintf( szKeywordFile, SEARCHMASK_MODEDIR,  pszTmpDir);
   rc = CreatePath( szKeywordFile);
   if ((rc != NO_ERROR) && (rc != ERROR_ACCESS_DENIED))
      break;
   sprintf( _EOS( szKeywordFile), "\\%s", pszEpmMode);
   strlwr( szKeywordFile);

   // -----------------------------------------------

   // --- hand over filename already here

   // check result buffer
   if (strlen( szKeywordFile) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szKeywordFile);

   // if no update check, return filename if file exists
   if ((ulOptions && HILITE_NOOUTDATECHECK) &&
       (FileExists( szKeywordFile)))
      {
      rc = NO_ERROR;
      break;
      }

   // -----------------------------------------------

   // initialize support for memory mapped files

   rc = MmfInitialize( &hmmf, 16);
   if (rc != NO_ERROR)
      break;

   // -----------------------------------------------

   // search and load values from INI files

   // - read global values
   rc = _openInitFile( &hinitGlobals, pszEnvnameEpmModepath, SEARCHMASK_GLOBALINI, NULL,
                       szInitGlobalFilename, sizeof( szInitGlobalFilename));
   if (rc != NO_ERROR)
      break;

   DPRINTF(("Global Filename: '%s'\n", szInitGlobalFilename));
   pvaColors  = _maintainInitValueArray( hinitGlobals, pszColorsSection, NULL);
   pvaSymbols = _maintainInitValueArray( hinitGlobals, pszSymbolsSection, NULL);


   // - read defaults of the mode
   rc = _openInitFile( &hinitDefault, pszEnvnameEpmModepath, SEARCHMASK_DEFAULTINI, pszEpmMode,
                       szInitDefaultFilename, sizeof( szInitDefaultFilename));
   if (rc != NO_ERROR)
      break;

   DPRINTF(("Default Filename: '%s'\n", szInitDefaultFilename));
   // - read customs of the mode - optional - so ignore errors here
   rc = _openInitFile( &hinitCustom, pszEnvnameEpmModepath, SEARCHMASK_CUSTOMINI, pszEpmMode,
                       szInitCustomFilename, sizeof( szInitCustomFilename));
   if (rc == NO_ERROR)
   {
      // note that we found the custom ini
      fCustomLoaded = TRUE;
      DPRINTF(( "CustomLoaded == TRUE\n"));
   }
   else
   {
      rc = NO_ERROR;
   }
   DPRINTF(("Custom Filename: '%s'\n", szInitCustomFilename));
   for ( i = 0; i < NUM_KEYS; i += 3)
   {
      PSZ pszDefaultValue;
      szFileBuffer[0] = '\0';
      if (fCustomLoaded)
      {
         QUERYOPTINITVALUE( hinitCustom, pszGlobalSection, apszKeys[i], szFileBuffer,    "");
         DPRINTF(( "Custom. Key '%s' Value '%s'\n", apszKeys, szFileBuffer));
         if (*(apszKeys[i+2]))
         {
            szAddFileBuffer[0] = '\0';
            QUERYOPTINITVALUE( hinitCustom, pszGlobalSection, apszKeys[i+2], szAddFileBuffer, "");
            DPRINTF(( "Custom addl. Key '%s' Value '%s'\n", apszKeys[i+2], szFileBuffer));
            if (szAddFileBuffer[0])
            {
               if (apszKeys[i] == KEY_CHARSET)
               {
                  strcat( szFileBuffer, szAddFileBuffer);
               }
               else // if not charset, must be "word" list
               {
                  strcat( szFileBuffer, " ");
                  strcat( szFileBuffer, szAddFileBuffer);
                  strupr( szFileBuffer);
               }
            }
         }
      }
      if (!szFileBuffer[0]) // If not set from custom, read from default.ini
      {
         DPRINTF(("Addr1 Addr2 string %08x %08x %s\n", apszKeys[i], KEY_CHARSET, apszKeys[i]));
         if (!strcmp( apszKeys[i], KEY_CHARSET))
         {
            QUERYINITVALUE( hinitDefault, pszGlobalSection, apszKeys[i], szFileBuffer);
            pszDefaultValue = STR_CASESENSITIVE;
            DPRINTF(( "Default charset. Key '%s' Value '%s'\n", apszKeys[i], szFileBuffer));
         }
         else
         {
            if (!strcmp( apszKeys[i], KEY_CASESENSITIVE))
            {
               pszDefaultValue = STR_CASESENSITIVE;
            }
            else
            {
               pszDefaultValue = "";
            }
            QUERYOPTINITVALUE( hinitDefault, pszGlobalSection, apszKeys[i], szFileBuffer, pszDefaultValue);
            DPRINTF(( "Default. Key '%s' Value '%s'\n", apszKeys[i], szFileBuffer));
         }
      }
      sprintf( szRegPath, pszRegPathTemplate, pszEpmMode, apszKeys[i+1]);
      DPRINTF(( "Regpath. Key '%s' Full path '%s'\n", apszKeys[i+1], szRegPath));
      rc = WriteConfigValue( hconfig, szRegPath, szFileBuffer);
      DPRINTF(( "Regupd rc %d Value '%s'\n", rc, szFileBuffer));
      if (!strcmp( apszKeys[i],  KEY_CASESENSITIVE))
      {
         fCaseSensitive = atol( szFileBuffer);
         DPRINTF(( "Case sensitive: %d\n", fCaseSensitive));

      }
      else
      {
         if (!strcmp( apszKeys[i], KEY_CHARSET))
         {
            strcpy(szCharset, szFileBuffer);
            DPRINTF(( "Charset: %s\n", szCharset));
         }
      }
   }

   // -----------------------------------------------

   DUMPINITVALUEARRAY( pvaSymbols);

   // add/replace with symbols from <mode>\default.ini
   pvaSymbols = _maintainInitValueArray( hinitDefault, pszSymbolsSection, pvaSymbols);

   DUMPINITVALUEARRAY( pvaSymbols);

   // add/replace with symbols from <mode>\custom.ini
   pvaSymbols = _maintainInitValueArray( hinitDefault, pszSymbolsSection, pvaSymbols);

   DUMPINITVALUEARRAY( pvaSymbols);

   if (fCustomLoaded)
      pvaSymbols = _maintainInitValueArray( hinitCustom, pszSymbolsSection, pvaSymbols);

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

   // check for the file date - if not exists, will return -1,
   // then reset to zero to force a rebuild
   ulKeywordFileDate = FileDate( szKeywordFile);
   if (ulKeywordFileDate == - 1)
      ulKeywordFileDate  = 0;

   // get the list of files
   ulFileCount = 0;
   rc = _getDefFileList( hmmf, pszEpmMode, ulKeywordFileDate, &pszFileList, &ulFileCount, &ulTotalSize, &fOutdated);
   if (rc != NO_ERROR)
      break;

   // if result file is not outdated, check the file list
   if (!fOutdated)
      {
      // check if file has an EA containing the old filelist
      rc = QueryStringEa( szKeywordFile, pszFileInfoListEaName, NULL, &ulInfoListSize);
      if (rc == ERROR_BUFFER_OVERFLOW)
         {
         pszOldFileInfoList = malloc( ulInfoListSize);
         if (!pszOldFileInfoList)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         rc = QueryStringEa( szKeywordFile, pszFileInfoListEaName, pszOldFileInfoList, &ulInfoListSize);
         if (rc != NO_ERROR)
            break;
         }
      else
         // EA not found, just proceed!
         rc = NO_ERROR;
      }

   // generate info list
   ulInfoListSize = ulFileCount * (_MAX_PATH + 32);
   ALLOCATEMEMORYFILE( pszFileInfoList, ulInfoListSize);

   QUERYOPTINITVALUE( hinitDefault, pszGlobalSection, KEY_HILCOMMENTCHAR, szHilCommentChar, STR_KWDSCOMMENT);   // first of all add info of init files to file list
   pszSourceFile = szInitGlobalFilename;
   sprintf( _EOS( pszFileInfoList), pszFileInfoMask, szHilCommentChar, pszSourceFile, QueryFileSize( pszSourceFile), FileDate( pszSourceFile));
   pszSourceFile = szInitDefaultFilename;
   sprintf( _EOS( pszFileInfoList), pszFileInfoMask, szHilCommentChar, pszSourceFile, QueryFileSize( pszSourceFile), FileDate( pszSourceFile));
   if (fCustomLoaded)
      {
      pszSourceFile = szInitCustomFilename;
      sprintf( _EOS( pszFileInfoList), pszFileInfoMask, szHilCommentChar, pszSourceFile, QueryFileSize( pszSourceFile), FileDate( pszSourceFile));
      }

   // loop thru all files
   for (ulCurrentFile = 0, pszSourceFile = pszFileList;
           ulCurrentFile < ulFileCount;
           ulCurrentFile++, pszSourceFile += _MAX_PATH)
      {
      // add file to the info list
      sprintf( _EOS( pszFileInfoList), pszFileInfoMask, szHilCommentChar, pszSourceFile, QueryFileSize( pszSourceFile), FileDate( pszSourceFile));
      }

   // now check the file list, if old one is present
   // if it is equal (including timestamps!)
   // break with no error
   if (pszOldFileInfoList)
      {
      if (!strcmp( pszOldFileInfoList, pszFileInfoList))
         {
//       DPRINTF(( "HILITE: file has not changed!\n"
//                 "files used for last generation\n"
//                 "------------------------------\n"
//                 "%s\n", pszOldFileInfoList));

         *pfReload = FALSE;
         break;
         }
      }

   // -----------------------------------------------

   // open up in-memory files for the six sections
   ALLOCATEMEMORYFILE( pszSectionDelimiter, ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionDelimiteri, ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionKeywords,  ulTotalSize * 2);
   ALLOCATEMEMORYFILE( pszSectionSpecial,   ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionBreakChar, ulTotalSize);
   ALLOCATEMEMORYFILE( pszSectionEndChar,   ulTotalSize);

   pszCurrentDelimiter = pszSectionDelimiter;
   pszCurrentDelimiteri = pszSectionDelimiteri;
   pszCurrentKeywords  = pszSectionKeywords;
   pszCurrentSpecial   = pszSectionSpecial;
   pszCurrentBreakChar = pszSectionBreakChar;
   pszCurrentEndChar   = pszSectionEndChar;

   // -----------------------------------------------

   // loop thru all files
   for (ulCurrentFile = 0, pszSourceFile = pszFileList;
           ulCurrentFile < ulFileCount;
           ulCurrentFile++, pszSourceFile += _MAX_PATH)
      {

      do
         {
         // open the file
//       DPRINTF(( "HILITE: process file %s\n", pszSourceFile));
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
            pszLine = szLine;
            ulLineCount++;

            // skip comments - the comment char must be on the first column!
            if ((*pszLine == CHAR_HILCOMMENT) ||
                (*pszLine == 0))
               continue;

            // check for section start before stipping blanks!
            fSectionStart = (*pszLine == CHAR_SECTION_START);

            // skip leading blanks anyway (also trailing newline)
            _stripblanks( pszLine);

            // skip empty lines
            if (*pszLine == 0)
               continue;

            // handle new section
            if (fSectionStart)
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
            pszStartStr    = NULL;
            pszStopStr     = NULL;
            pszBreakStr    = NULL;
            pszStartPos    = NULL;

            pszSymbolValue = NULL;
            pszColorValue1 = NULL;
            pszColorValue2 = NULL;
            pszInvalid     = NULL;

            pszStartStr = strtok( pszLine, " ");
            pszLine     = strtok( NULL, " ");
            while (pszLine)
               {
               do
                  {

                  // ------------------------------------
                  // check if keyword is a symbol
                  p = _queryInitValue( pvaSymbols, pszLine);
                  if (p)
                     {
                     if ((!pszSymbolValue) &&
                         (!pszColorValue1) &&
                         (!pszColorValue2))
                        pszSymbolValue = p;
                     else
                        pszInvalid = pszLine;

                     break;
                     }

                  // ------------------------------------

                  // check if keyword is a color
                  p = _queryInitValue( pvaColors, pszLine);
                  if (p)
                     {
#if ALLOW_COLOR_VALUES
                     if ((!pszColorValue1) && (!pszSymbolValue))
                        pszColorValue1 = p;
                     else if ((!pszColorValue2)  && (!pszSymbolValue))
                        pszColorValue2 = p;
                     else
                        pszInvalid = pszLine;
#else
                     pszInvalid = pszLine;
#endif
                     break;
                     }

                  // ------------------------------------

                  // use comment char if special keyword is specified
                  if (!strcmp( pszKeywordNone, pszLine))
                     pszLine = szHilCommentChar;

                  // store all other values
                  if (!pszStopStr)
                     pszStopStr = pszLine;
                  else if (!pszBreakStr)
                     pszBreakStr = pszLine;
                  else if (!pszStartPos)
                     pszStartPos = pszLine;
                  else
                     pszInvalid = pszLine;

                  } while (FALSE);

               if (pszInvalid)
                  break;

               // next one
               pszLine = strtok( NULL, " ");
               }

            // still linvalid line?
            if (pszInvalid)
               {
               DPRINTF(( "HILITE: error: skipping invalid line %u, invalid token %s\n", ulLineCount, pszInvalid));
               continue;
               }


            // check for color to be used
            fEntryColors = FALSE;
            if (pszSymbolValue)
               {
               strcpy( szEntryColors, pszSymbolValue);
               fEntryColors = TRUE;
               }
            else if ((pszColorValue1) && (pszColorValue2))
               {
               sprintf( szEntryColors, "%s %s", pszColorValue1, pszColorValue2);
               fEntryColors = TRUE;
               }
            else
               strcpy( szEntryColors, pszCurrentSectionColors);

            // if a stop character is still available, make it a DELIM/DELIMI entry
            ulSelectIndex = ulSectionIndex;
            if (pszStopStr)
               ulSelectIndex = SECTION_COMMENT;

            // handle different sections
            switch (ulSelectIndex)
               {
               case SECTION_DEFAULT:
                  sprintf( pszCurrentKeywords, "%s %s\r\n", pszStartStr, szEntryColors);
                  pszCurrentKeywords = _EOS( pszCurrentKeywords);
                  break;

               case SECTION_COMMENT:
               case SECTION_LITERAL:
                  p = (fCaseSensitive) ?
                         pszCurrentDelimiter : pszCurrentDelimiteri;

                  sprintf( p, "%s %s",
                           pszStartStr, szEntryColors);
                  if (pszStopStr)
                     sprintf( _EOS( p), " %s", pszStopStr);
                  if (pszBreakStr)
                     sprintf( _EOS( p), " %s", pszBreakStr);
                  if (pszStartPos)
                     sprintf( _EOS( p), " %s", pszStartPos);
                  strcat( p, "\r\n");

                  if (fCaseSensitive)
                     pszCurrentDelimiter = _EOS( pszCurrentDelimiter);
                  else
                     pszCurrentDelimiteri = _EOS( pszCurrentDelimiteri);
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


   // determine the length
   ulHiliteContentsLen = (pszCurrentDelimiter  - pszSectionDelimiter)  +
                         (pszCurrentDelimiteri - pszSectionDelimiteri) +
                         (pszCurrentKeywords   - pszSectionKeywords)   +
                         (pszCurrentSpecial    - pszSectionSpecial)    +
                         (pszCurrentBreakChar  - pszSectionBreakChar)  +
                         (pszCurrentEndChar    - pszSectionEndChar)    +
                         (strlen(szCharset) + 32);

// DPRINTF(( "HILITE: assembling %u bytes to hilite file: %s\n", ulHiliteContentsLen, szKeywordFile));

   rc = MmfAlloc( hmmf,
                  (PVOID*)&pszHiliteContents,
                  szKeywordFile,
                  MMF_ACCESS_READWRITE |
                  MMF_OPENMODE_RESETFILE,
                  ulHiliteContentsLen + 4096);
   if (rc != NO_ERROR)
      break;

// DPRINTF(( "- allocated buffer at 0x%08x, len %u, end address 0x%08x\n",
//           pszHiliteContents, ulHiliteContentsLen, pszHiliteContents + ulHiliteContentsLen));

   // write one line with the comment char only, followed by header and FileInfoList
   pszCurrent = pszHiliteContents;
   sprintf( pszCurrent, "%s\r\n"
                        "%s NEPMD keyword highlighting definition - Files used\r\n"
                        "%s ==================================================\r\n",
                        szHilCommentChar, szHilCommentChar, szHilCommentChar);
   pszCurrent = _EOS( pszCurrent);
   strcat( pszCurrent, pszFileInfoList);
   pszCurrent = _EOS( pszCurrent);

   // first of all write CHARSET
   sprintf( pszCurrent, pszHeaderMask, szHilCommentChar, "CHARSET");
// DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
   pszCurrent = _EOS( pszCurrent);
   sprintf( pszCurrent, "%s\r\n", szCharset);
   pszCurrent = _EOS( pszCurrent);

   // add all sections, if something in it
   if (pszCurrentDelimiter - pszSectionDelimiter)
      {
      sprintf( pszCurrent, pszHeaderMask, szHilCommentChar, "DELIM");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionDelimiter);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentDelimiteri - pszSectionDelimiteri)
      {
      sprintf( pszCurrent, pszHeaderMask, szHilCommentChar, "DELIMI");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionDelimiteri);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentKeywords  - pszSectionKeywords)
      {
      sprintf( pszCurrent, pszHeaderMask, szHilCommentChar, (fCaseSensitive) ? "KEYWORDS" : "INSENSITIVE");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionKeywords);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentSpecial   - pszSectionSpecial)
      {
      sprintf( pszCurrent,  pszHeaderMask, szHilCommentChar, (fCaseSensitive) ? "SPECIAL"  : "SPECIALI");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionSpecial);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentBreakChar - pszSectionBreakChar)
      {
      sprintf( pszCurrent,  pszHeaderMask, szHilCommentChar, "BREAK");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionBreakChar);
      pszCurrent = _EOS( pszCurrent);
      }

   if (pszCurrentEndChar   - pszSectionEndChar)
      {
      sprintf( pszCurrent,  pszHeaderMask, szHilCommentChar, "ENDCHAR");
//    DPRINTF(( "-  at 0x%08x adding header for %s\n", pszCurrent, pszCurrent));
      pszCurrent = _EOS( pszCurrent);
      strcpy( pszCurrent, pszSectionEndChar);
      pszCurrent = _EOS( pszCurrent);
      }

   // set filesize
   ulHiliteContentsLen = strlen( pszHiliteContents);
   rc = MmfSetSize( hmmf, pszHiliteContents, ulHiliteContentsLen);
// DPRINTF(( "-  setting filesize to size of %u bytes, rc=%u\n", ulHiliteContentsLen, rc));

   // write temporary file
   rc = MmfUpdate( hmmf, pszHiliteContents);
// DPRINTF(( "-  update file, rc=%u\n", rc));


   // close target file first so that we can write the EA
   FREEMEMORYFILE( pszHiliteContents);
   pszHiliteContents = NULL;

   // add file infolist as extended attribute
   rc = WriteStringEa( szKeywordFile, pszFileInfoListEaName, pszFileInfoList);
// DPRINTF(( "\n"
//           "HILITE: used files for generation\n"
//           "---------------------------------\n"
//           "%s\n", pszFileInfoList));

   } while (FALSE);

// cleanup

if (pvaColors)           free( pvaColors);
if (pvaSymbols)          free( pvaSymbols);
if (pszOldFileInfoList)  free( pszOldFileInfoList);

if (pszFileList)          FREEMEMORYFILE( pszFileList);
if (pszFileInfoList)      FREEMEMORYFILE( pszFileInfoList);
if (pszSectionDelimiter)  FREEMEMORYFILE( pszSectionDelimiter);
if (pszSectionDelimiteri) FREEMEMORYFILE( pszSectionDelimiteri);
if (pszSectionKeywords)   FREEMEMORYFILE( pszSectionKeywords);
if (pszSectionSpecial)    FREEMEMORYFILE( pszSectionSpecial);
if (pszSectionBreakChar)  FREEMEMORYFILE( pszSectionBreakChar);
if (pszSectionEndChar)    FREEMEMORYFILE( pszSectionEndChar);
if (pszHiliteContents)    FREEMEMORYFILE( pszHiliteContents);

if (hinitCustom)  InitCloseProfile( hinitCustom, FALSE);
if (hinitDefault) InitCloseProfile( hinitDefault, FALSE);
if (hinitGlobals) InitCloseProfile( hinitGlobals, FALSE);
if (hmmf)         MmfTerminate( hmmf);

FUNCEXITRC;
return rc;
}

// #############################################################################

APIRET QueryHilightFile( PSZ pszEpmMode, ULONG ulOptions, PBOOL pfReload,
                         HCONFIG hconfig,
                         PSZ pszBuffer, ULONG ulBuflen)
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
       (!pfReload)     ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

// DPRINTF(( "### HILITE: %s: options: %08x\n", pszEpmMode, ulOptions));

   // search mode files
   rc = _assembleKeywordFile( pszEpmMode, ulOptions, pfReload, hconfig, szValue, sizeof( szValue));
   if (rc == NO_ERROR)
      {
      // disable reload if HighlightFlag <> 0
      if (ulOptions)
         *pfReload = FALSE;
      }
   else
      {
      // if no mode infos available; conventional search
      rc = _searchFile( pszEnvnameEpmPath, szValue, sizeof( szValue), SEARCHMASK_EPMKWDS, pszEpmMode);
      if (rc != NO_ERROR)
         break;
      // always do not reload this one (default EPM behaviour)
      *pfReload = FALSE;
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

