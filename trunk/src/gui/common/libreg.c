/****************************** Module Header *******************************
*
* Module Name: libreg.c
*
* Generic routines to implement a registy alike repository
*
* Entries are stored in           "RegKeys"      <PathName>
* Container lists are stored in:  "RegContainer" <PathName>
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libreg.c,v 1.16 2002-10-01 14:23:03 cla Exp $
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
#include "libreg.h"
#include "file.h"

// global variables and macros for reading/writing entries
// and container lists
static   PSZ            pszPathSeparator   = "\\";      // only one character, although it is a string !!!
static   PSZ            pszAppRegDefaults  = "RegDefaults";
static   PSZ            pszAppRegKeys      = "RegKeys";
static   PSZ            pszAppRegContainer = "RegContainer";

#define PATHENTRYLEN(p)       _queryEntrySize( hconfig, pszAppRegContainer, p)
#define KEYENTRYLEN(p)        _queryEntrySize( hconfig, pszAppRegKeys, p)
#define DEFKEYENTRYLEN(p)     _queryEntrySize( hconfig, pszAppRegDefaults, p)

#define QUERYPATHENTRY(p,b,s)   _queryDataEntry(  hconfig, pszAppRegContainer, p, b, s)
#define QUERYKEYENTRY(p,b,s)    PrfQueryProfileString(  hconfig, pszAppRegKeys, p, NULL, b, s)
#define QUERYDEFKEYENTRY(p,b,s) PrfQueryProfileString(  hconfig, pszAppRegDefaults, p, NULL, b, s)

#define WRITEPATHENTRY(p,v,l) PrfWriteProfileData(  hconfig, pszAppRegContainer, p, v, l)
#define WRITEKEYENTRY(p,v)    PrfWriteProfileString(  hconfig, pszAppRegKeys, p, v)

#define DELETEPATH(p)         WRITEPATHENTRY( p, NULL)
#define DELETEKEY(p)          WRITEKEYENTRY(  p, NULL)

#define PATHEXISTS(p)   (PATHENTRYLEN( p) > 0)
#define KEYEXISTS(p)    (KEYENTRYLEN( p)  > 0)
#define DEFKEYEXISTS(p) (DEFKEYENTRYLEN( p)  > 0)

// global variables and macros for ensuring exclusive access across
// thread and process boundaries
static   PSZ              pszMutexSemName = "\\SEM32\\NEPMD\\CONFIGURATION\\ACCESS";
#define SEM_ACCESS_TIMEOUT_SLICE  30000
#define REQUESTACCESS(ph) _getExclusiveAccess( ph)
#define RELEASEACCESS(h)  _releaseExclusiveAccess( h)

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

// ----------------------------------------------------------------------

static PSZ _stripquotes( PSZ string)
{
PSZ p;
if (string != NULL)
   {
   p = string + strlen( string) - 1;
   if (*p == '"')
      *p = 0;

   if (*string == '"')
      strcpy( string, string + 1);
   }

return string;
}

// -----------------------------------------------------------------------------

static APIRET _getExclusiveAccess( PHMTX phmtxAccess)
{
         APIRET         rc = NO_ERROR;
do
   {
   // create semaphore
   rc = DosCreateMutexSem( pszMutexSemName, phmtxAccess, 0L, FALSE);
   if (rc != NO_ERROR)
      {
      // get handle to update sem
      rc = DosOpenMutexSem( pszMutexSemName, phmtxAccess);
      if (rc != NO_ERROR)
         break;
      }

   // get exclusive access to action profile list
   rc = DosRequestMutexSem( *phmtxAccess, SEM_ACCESS_TIMEOUT_SLICE);
   if (rc != NO_ERROR)
      break;

   } while (FALSE);

// DPRINTF(( "LIBREG: request exclusive access: %u\n", rc));
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _releaseExclusiveAccess( HMTX hmtxAccess)
{
// DPRINTF(( "LIBREG: release exclusive access\n"));
return DosCloseMutexSem( hmtxAccess);
}

// -----------------------------------------------------------------------------

static PSZ _getEndOfStrList( PSZ pszzStr)
{
         PSZ            pszResult = pszzStr;
do
   {
   // quit on empty string
   if (!pszzStr)
      break;

   // search end of zz string
   while (*pszResult)
      {
      pszResult = NEXTSTR( pszResult);
      }

   } while (FALSE);

return pszResult;
}

// -----------------------------------------------------------------------------

#define SEARCH_STRING      0
#define SEARCH_INSERTPOS   1

static PSZ _searchPosInStrList( PSZ pszzStr, PSZ pszSearch, ULONG ulInsertType)
{
         PSZ            pszResult = NULL;
         LONG           lResult;

do
   {
   // quit on empty string
   if ((!pszzStr) || (!pszSearch))
      break;

   // search string in zz string list
   pszResult = pszzStr;
   while (*pszResult)
      {
      if (ulInsertType == SEARCH_STRING)
         {
         lResult = strcmp( pszResult, pszSearch);
         // break on equal strings only
         if (!lResult)
            break;

         // break if entry is greater than search string anyway
         // since the searched entry cannot come after that
         if (lResult > 0)
            {
//          DPRINTF(( "LIBREG: skip search: %s %s: %i\n", pszResult, pszSearch, lResult));
            pszResult = pszResult + strlen( pszResult);
            break;
            }

         }
      else if (ulInsertType == SEARCH_INSERTPOS)
         {
         // compare strings case insensitive
         // Value             Meaning 
         // Less than 0       string1 less than string2 
         // 0                 string1 identical to string2 
         // Greater than 0    string1 greater than string2. 

         lResult = stricmp( pszResult, pszSearch);
//       DPRINTF(( "LIBREG: diff: %s %s: %i\n", pszResult, pszSearch, lResult));

         // only if strings are equal, compare also case sensitive
         // - this places uppercase before lowercase
         if (!lResult)
            lResult = strcmp( pszResult, pszSearch);

         // break if string in list comes after search
         // string - this is the insert position
         if (lResult > 0)
            break;
         }

      pszResult = NEXTSTR( pszResult);
      }

   } while (FALSE);

return pszResult;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static PSZ _searchStrInStrList( PSZ pszzStr, PSZ pszSearch)
{
return _searchPosInStrList( pszzStr, pszSearch, SEARCH_STRING);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

static PSZ _searchInsertPosInStrList( PSZ pszzStr, PSZ pszSearch)
{
return _searchPosInStrList( pszzStr, pszSearch, SEARCH_INSERTPOS);
}

#ifdef UNSUSED
// -----------------------------------------------------------------------------
// runtime alike helper, searching word in space delimited list
// returns a pointer to word or NULL

static char *_strword( const char *str, const char *word)
{
         char          *p = 0;
         char          *eos;

   p = strstr( str, word);
   while (p)
      {
      // make sure entry is a word, search end of word
      eos = strchr( p, ' ');

      // entry is delimited by a zero byte, adjust pointer
      if (!eos)
         eos = p + strlen( p);

      // word must be delimited by a space or zero byte
      if ((*eos == 32) || (*eos == 0))
         {
         // it is now is the first word or preceeded by a
         // space, it is truly a word, so we have a hit
         if ((p == str) || (*(p - 1) == 32))
            break;
         }

      // no word match here, search again
      p = strstr( str, p + 1);
      }

return p;
}
#endif

// -----------------------------------------------------------------------------

static ULONG _queryEntrySize( HCONFIG hconfig, PSZ pszAppName, PSZ pszValuePath)
{
         ULONG          ulDataLen = 0;

PrfQueryProfileSize( hconfig, pszAppName, pszValuePath, &ulDataLen);
return ulDataLen;
}

// -----------------------------------------------------------------------------

static ULONG _queryDataEntry( HCONFIG hconfig, PSZ pszAppName, PSZ pszValuePath, PSZ pszBuffer, ULONG ulBuflen)
{
         ULONG          ulDataLen = 0;

ulDataLen = ulBuflen;
if (PrfQueryProfileData(  hconfig, pszAppName, pszValuePath, pszBuffer, &ulDataLen))
   return ulDataLen;
else
   return 0;
}

// -----------------------------------------------------------------------------

static BOOL _isPathValid( PSZ pszValuePath)
{
return ((pszValuePath != NULL)                &&
        (strlen( pszValuePath) < _MAX_PATH)   &&
        (*pszValuePath == *pszPathSeparator));
}

// -----------------------------------------------------------------------------

static APIRET _addKeyToContainerList( HCONFIG hconfig, PSZ pszPath, PSZ pszKey)
{
         APIRET         rc = NO_ERROR;
         BOOL           fNewKey = FALSE;
         ULONG          ulDataLen;
         PSZ            pszList = NULL;

         PSZ            pszEntry;
         ULONG          ulRemainLen;

do
   {
   // check parms
   if ((!pszPath)  ||
       (!*pszPath) ||
       (!pszKey)   ||
       (!*pszKey))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }


   // check if value exists already
   ulDataLen = PATHENTRYLEN( pszPath);
   fNewKey = (ulDataLen == 0);

   // get current container list
   // apend a byte for the double zero byte - this will not be stored !
   ulDataLen += strlen( pszKey) + 1;
   pszList = malloc( ulDataLen + 1);
   if (!pszList)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszList, 0, ulDataLen + 1);

   // write new key list here
   if (fNewKey)
      {
      // copy key with appended second zero byte
      strcpy( pszList, pszKey);
      pszEntry = NEXTSTR( pszList);
      *pszEntry = 0;

      // completely new container list
      if (!WRITEPATHENTRY( pszPath, pszKey, ulDataLen))
         rc = LASTERROR;
      break;
      }


   // query existant list
   if (!QUERYPATHENTRY( pszPath, pszList, ulDataLen))
      {
      rc = LASTERROR;
      break;
      }

   // is key in there already ? then quit with no error
   pszEntry = _searchStrInStrList( pszList, pszKey);
   if (*pszEntry)
      break;

   // insert key to list and write back
   pszEntry = _searchInsertPosInStrList( pszList, pszKey);
   ulRemainLen = _getEndOfStrList( pszEntry) - pszEntry + 1;
   memmove( pszEntry + strlen( pszKey) + 1, pszEntry, ulRemainLen);
   strcpy( pszEntry, pszKey);

   if (!WRITEPATHENTRY( pszPath, pszList, ulDataLen))
      rc = LASTERROR;

   } while (FALSE);

// cleanup
if (pszList) free( pszList);
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _removeKeyFromContainerList( HCONFIG hconfig, PSZ pszPath, PSZ pszKey)
{
         APIRET         rc = NO_ERROR;
         ULONG          ulDataLen;
         PSZ            pszList = NULL;
         PSZ            pszEntry;
         PSZ            pszNextEntry;
         BOOL           fStopRemovePath = FALSE;

do
   {
   // check parms
   if ((!pszPath)  ||
       (!*pszPath) ||
       (!pszKey)   ||
       (!*pszKey))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check if value exists already
   ulDataLen = PATHENTRYLEN( pszPath);
   if (!ulDataLen)
      {
      // nothin to delete
      rc = ERROR_PATH_NOT_FOUND;
      break;
      }

   // get current container list
   // apend a byte for the double zero byte - this will not be stored !
   pszList = malloc( ulDataLen + 1);
   if (!pszList)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszList, 0, ulDataLen + 1);
   if (!QUERYPATHENTRY( pszPath, pszList, ulDataLen))
      {
      rc = LASTERROR;
      break;
      }

   // is key not in here already ?
   pszEntry = _searchStrInStrList( pszList, pszKey);
   if (!pszEntry)
      {
      rc = ERROR_PATH_NOT_FOUND;
      break;
      }

   // remove key from list
   pszNextEntry = NEXTSTR( pszEntry);
   if (*pszNextEntry)
      {
      // copy everything including the last two bytes
      ulDataLen = _getEndOfStrList( pszNextEntry) - pszNextEntry + 1;
      memcpy( pszEntry, pszNextEntry, ulDataLen);
      }
   else
      // last word: just copy two zero bytes
      memcpy( pszEntry, pszNextEntry - 1, 2);

   // is list empty ?
   ulDataLen = _getEndOfStrList( pszList) - pszList;
   if (ulDataLen)
      // no, stop deleting further
      fStopRemovePath = TRUE;
   else
      // yes: remove this container entry
      pszList = NULL;

   // wrrite back the updated list or delete it (when pszList == NULL)
   if (!WRITEPATHENTRY( pszPath, pszList, ulDataLen))
      {
      rc = LASTERROR;
      break;
      }

   // list is not empty, path may not be further removed
   if (fStopRemovePath)
      {
//    DPRINTF(( "LIBREG: abort path deletion at %s\n", pszPath));
      rc = ERROR_DIR_NOT_EMPTY;
      }

   } while (FALSE);

// cleanup
if (pszList) free( pszList);
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _createRegPath( HCONFIG hconfig, PSZ pszValuePath)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszCopy     = strdup( pszValuePath);
         PSZ            pszPath     = strdup( pszValuePath);
         PSZ            pszLastPath = strdup( pszValuePath);

         PSZ            p;

do
   {
   // everything fine ?
   if ((!pszCopy) || (!pszPath) || (!pszLastPath))
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   // go though path and create all container entries
   // if not existant
   p = strtok( pszCopy + 1, pszPathSeparator); // skip first slash
   strcpy( pszPath, p - 1);
   *pszLastPath = 0;
   while (p)
      {
      // add current basename to list of previous path
      // this will automatically create container lists if not yet existant
      if (*pszLastPath)
         rc = _addKeyToContainerList( hconfig, pszLastPath, p);
      strcpy( pszLastPath, pszPath);

      // next one
      p = strtok( NULL, pszPathSeparator);
      if (p)
         {
         strcat( pszPath, pszPathSeparator);
         strcat( pszPath, p);
         }
      }

   } while (FALSE);

// cleanup
if (pszCopy)     free( pszCopy);
if (pszPath)     free( pszPath);
if (pszLastPath) free( pszLastPath);
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _removeRegPath( HCONFIG hconfig, PSZ pszValuePath)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszCopy     = strdup( pszValuePath);
         PSZ            p;

do
   {
   // everything fine ?
   if (!pszCopy)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   // go backwards though path and create all container entries
   // if not existant
   p = strrchr( pszCopy, *pszPathSeparator);
   while ((p) && (p > pszCopy))
      {
      // cut off current key first
      *p = 0;

      // add current basename to list of previous path
      if (p != pszCopy)
         {
         rc = _removeKeyFromContainerList( hconfig, pszCopy, p + 1);
         if (rc != NO_ERROR)
            break;
         }

      // next slash
      p = strrchr( pszCopy, *pszPathSeparator);
      }

   } while (FALSE);

// cleanup
if (pszCopy)     free( pszCopy);
return rc;
}

// -----------------------------------------------------------------------------

APIRET OpenConfig( PHCONFIG phconfig, PSZ pszFilename)
{
         APIRET         rc = NO_ERROR;

do
   {
   // check parms
   if ((!phconfig)    ||
       (!pszFilename) ||
       (!*pszFilename))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // open profile
   *phconfig = PrfOpenProfile( CURRENTHAB, pszFilename);
   if (!*phconfig)
      {
      rc = LASTERROR;
      break;
      }

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET CloseConfig( HCONFIG hconfig)
{
         APIRET         rc = NO_ERROR;
if (!PrfCloseProfile( hconfig))
   rc = LASTERROR;
return rc;
}

// -----------------------------------------------------------------------------

APIRET WriteConfigValue( HCONFIG hconfig, PSZ pszValuePath, PSZ pszValue)

{
         APIRET         rc = NO_ERROR;
         HMTX           hmtxAccess = NULLHANDLE;

do
   {
   // check parms
   if ((!_isPathValid( pszValuePath)) ||
       (!pszValue))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // obtain exclusive access
   rc = REQUESTACCESS( &hmtxAccess);
   if (rc != NO_ERROR)
      break;

   // create path if not exist
// DPRINTF(( "LIBREG: create path: %s\n", pszValuePath));
   rc = _createRegPath( hconfig, pszValuePath);
   if (rc != NO_ERROR)
      {
//    DPRINTF(( "LIBREG: error: %u/0x%x\n", rc, rc));
      break;
      }

   // create key
// DPRINTF(( "LIBREG: create key: %s\n", pszValuePath));
   if (!WRITEKEYENTRY( pszValuePath, pszValue))
      {
      rc = LASTERROR;
//    DPRINTF(( "LIBREG: error: %u/0x%x\n", rc, rc));
      break;
      }


   } while (FALSE);

// cleanup
if (hmtxAccess) RELEASEACCESS( hmtxAccess);
return rc;
}

// -----------------------------------------------------------------------------

APIRET QueryConfigValue( HCONFIG hconfig, PSZ pszValuePath, PSZ pszBuffer, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;
         HMTX           hmtxAccess = NULLHANDLE;

do
   {
   // check parms
   if ((!_isPathValid( pszValuePath)) ||
       (!pszBuffer)                   ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // obtain exclusive access
   rc = REQUESTACCESS( &hmtxAccess);
   if (rc != NO_ERROR)
      break;

   // read entry
// DPRINTF(( "LIBREG: read: %s\n", pszValuePath));
   if (!QUERYKEYENTRY( pszValuePath, pszBuffer, ulBuflen))
      {
      if (!QUERYDEFKEYENTRY( pszValuePath, pszBuffer, ulBuflen))
         {
         rc = LASTERROR;
//       DPRINTF(( "LIBREG: error: %u/0x%x\n", rc, rc));
         break;
         }
      }
// DPRINTF(( "LIBREG: --> %s\n", pszBuffer));

   } while (FALSE);

// cleanup
if (hmtxAccess) RELEASEACCESS( hmtxAccess);
return rc;
}

// -----------------------------------------------------------------------------

APIRET DeleteConfigValue( HCONFIG hconfig, PSZ pszValuePath)

{
         APIRET         rc = NO_ERROR;
         HMTX           hmtxAccess = NULLHANDLE;

do
   {
   // check parms
   if (!_isPathValid( pszValuePath))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // obtain exclusive access
   rc = REQUESTACCESS( &hmtxAccess);
   if (rc != NO_ERROR)
      break;

   // if key not exist: error
// DPRINTF(( "LIBREG: delete key: %s\n", pszValuePath));
   if (!KEYEXISTS( pszValuePath))
      {
      rc = ERROR_PATH_NOT_FOUND;
//    DPRINTF(( "LIBREG: error: %u\n", rc));
      break;
      }

   // delete key
   DELETEKEY( pszValuePath);

   // remove path as far as possible - ignore errors
// DPRINTF(( "LIBREG: delete path: %s\n", pszValuePath));
   _removeRegPath( hconfig, pszValuePath);


   } while (FALSE);

// cleanup
if (hmtxAccess) RELEASEACCESS( hmtxAccess);
return rc;
}

// -----------------------------------------------------------------------------

APIRET GetNextConfigKey( HCONFIG hconfig, PSZ pszValuePath, PSZ pszPreviousKey,
                         PSZ pszOptions, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         BOOL           fFound = FALSE;
         HMTX           hmtxAccess = NULLHANDLE;

         ULONG          ulDataLen;
         PSZ            pszList = NULL;
         PSZ            pszEntry;

         // default search options
         PSZ            pszSearchOptions;
         BOOL           fSearchContainer = TRUE;
         BOOL           fSearchKeys      = TRUE;
         ULONG          ulPathEntryLen;
         ULONG          ulKeyEntryLen;
         CHAR           szTestEntry[ _MAX_PATH];

do
   {
   // check parms
   if (!_isPathValid( pszValuePath))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   if ((!pszBuffer)   ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check options
   if (pszOptions)
      {
      pszSearchOptions = strdup( pszOptions);
      if (!pszSearchOptions)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      strupr( pszSearchOptions);

      fSearchContainer = FALSE;
      fSearchKeys      = FALSE;
      if (strchr( pszSearchOptions, 'B'))
         {
         fSearchContainer = TRUE;
         fSearchKeys      = TRUE;
         }

      if (strchr( pszSearchOptions, 'K'))
         fSearchKeys      = TRUE;

      if (strchr( pszSearchOptions, 'C'))
         fSearchContainer = TRUE;

      free( pszSearchOptions);
      }

   // obtain exclusive access
   rc = REQUESTACCESS( &hmtxAccess);
   if (rc != NO_ERROR)
      break;

   // check if value exists already
   ulDataLen = PATHENTRYLEN( pszValuePath);
   if (!ulDataLen)
      {
      // nothin to delete
      rc = ERROR_PATH_NOT_FOUND;
      break;
      }

   // get current container list
   // apend a byte for the double zero byte - this will not be stored !
   pszList = malloc( ulDataLen + 1);
   if (!pszList)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszList, 0, ulDataLen + 1);
   if (!QUERYPATHENTRY( pszValuePath, pszList, ulDataLen))
      {
      rc = LASTERROR;
      break;
      }

   pszEntry = pszPreviousKey;
   while (!fFound)
      {
      if ((!pszEntry) ||
          (!*pszEntry))
         // return first entry here
         pszEntry = pszList;
      else
         {
         // search previous key
         pszEntry = _searchStrInStrList( pszList, pszEntry);
         if (!pszEntry)
            {
            // previous key not found (this may not happen...)
            rc = ERROR_PATH_NOT_FOUND;
            break;
            }
         else
            {
            // just go to next entry
            pszEntry = NEXTSTR( pszEntry);
            if (!*pszEntry)
               {
               // nothing more left
               rc = ERROR_NO_MORE_FILES;
               break;
               }
            }
         }

      // found value matching the requested type ?
      fFound = TRUE;
      sprintf( szTestEntry, "%s\\%s", pszValuePath, pszEntry);
      ulPathEntryLen = PATHENTRYLEN( szTestEntry);
      ulKeyEntryLen  = KEYENTRYLEN(  szTestEntry);
      if ((!fSearchContainer) && (ulPathEntryLen) && (!ulKeyEntryLen))
         // pure container found, but not allowed
         fFound = FALSE;
      else if ((!fSearchKeys) && (!ulPathEntryLen) && (ulKeyEntryLen))
         // pure key found, but not allowed
         fFound = FALSE;

      } // while (!fFound)

   if (rc != NO_ERROR)
      break;

   // check result buffer
   if (strlen( pszEntry) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, pszEntry);

   } while (FALSE);

// cleanup
if (pszList) free( pszList);
if (hmtxAccess) RELEASEACCESS( hmtxAccess);
return rc;
}

// -----------------------------------------------------------------------------

APIRET InitConfig( HCONFIG hconfig, PSZ pszDefaultsFilename)
{
         APIRET         rc = NO_ERROR;
         BOOL           fFound = FALSE;
         HMTX           hmtxAccess = NULLHANDLE;

         FILE          *pfile = NULL;
         CHAR          szLine[ 2048];

         PSZ           pszDelimiter;
         PSZ           pszPath;
         PSZ           pszValue;

do
   {
   if (!hconfig)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check for optional text source file
   if (pszDefaultsFilename)
      {
      if (!*pszDefaultsFilename)
         pszDefaultsFilename = NULL;
      else
      if ( (!FileExists( pszDefaultsFilename)))
         {
         rc = ERROR_FILE_NOT_FOUND;
         break;
         }
      }

   // obtain exclusive access
   rc = REQUESTACCESS( &hmtxAccess);
   if (rc != NO_ERROR)
      break;

   // ------ read in defaults if they do not yet exist

   if (pszDefaultsFilename)
      {
      if (!DEFKEYENTRYLEN( NULL))
         {
         // open file and read line by line
         pfile = fopen( pszDefaultsFilename, "r");
         if (!pfile)
            {
            rc = ERROR_OPEN_FAILED;
            break;
            }
      
         while (!feof( pfile))
            {
            // read line and skip empty lines
            fgets( szLine, sizeof( szLine), pfile);
            _stripblanks( szLine);
            if (szLine[ 0] == 0)
               continue;
            if (szLine[ 0] == ';')
               continue;
   
            // check for delimter
            pszDelimiter = strchr( szLine, '=');
            if (!pszDelimiter)
               continue;
      
            // prepare fields and write them to the ini file
            *pszDelimiter = 0;
            pszPath  = _stripquotes( _stripblanks( szLine));
            pszValue = _stripquotes( _stripblanks( pszDelimiter + 1));
      
            if (!PrfWriteProfileString( hconfig, pszAppRegDefaults, pszPath, pszValue))
               {
               rc = LASTERROR;
               break;
               }
   
            } // while (!feof( pfile))
   
         if (rc != NO_ERROR)
            break;
   
         } 

      } // if (pszDefaultsFilename)


   } while (FALSE);

// cleanup
if (pfile) fclose( pfile);
if (hmtxAccess) RELEASEACCESS( hmtxAccess);
return rc;
}

