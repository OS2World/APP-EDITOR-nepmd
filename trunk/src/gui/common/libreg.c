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
* $Id: libreg.c,v 1.1 2002-09-12 15:23:36 cla Exp $
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
#include "instval.h"
#include "libreg.h"

// some globals
static   PSZ            pszPathSeparator   = "\\";      // only one character, although it is a string !!!
static   PSZ            pszAppRegKeys      = "RegKeys";
static   PSZ            pszAppRegContainer = "RegContainer";

#define  SETLASTERROR(rc) WinSetErrorInfo( MAKEERRORID( SEVERITY_ERROR, PMERR_DOS_ERROR), SEI_DOSERROR, (USHORT) rc)

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

// -----------------------------------------------------------------------------

static BOOL _isPathValid( PSZ pszValuePath)
{
return ((pszValuePath != NULL)                &&
        (strlen( pszValuePath) < _MAX_PATH)   &&
        (*pszValuePath == *pszPathSeparator));
}

// -----------------------------------------------------------------------------

static HINI _openLibProfile( VOID)
{
         HINI           hini = NULLHANDLE;
         APIRET         rc = NO_ERROR;
         CHAR           szInifile[ _MAX_PATH];
do
   {
   // determine name of INI
   rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szInifile, sizeof( szInifile));
   if (rc = NO_ERROR)
      break;

   // open profile
   hini = PrfOpenProfile( CURRENTHAB, szInifile);

   } while (FALSE);

return hini;
}
// -----------------------------------------------------------------------------

static APIRET _addKeyToContainerList( HINI hini, PSZ pszPath, PSZ pszKey)
{
         APIRET         rc = NO_ERROR;
         ULONG          ulDataLen;
         PSZ            pszList = NULL;
         PSZ            pszEntry;

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
   if ((!PrfQueryProfileSize( hini, pszAppRegContainer, pszPath, &ulDataLen)) || (!ulDataLen))
      {
      // completely new container list: just add our key
      if (!PrfWriteProfileString( hini, pszAppRegContainer, pszPath, pszKey))
         rc = LASTERROR;
      break;
      }

   // get current container list
   ulDataLen += strlen( pszKey) + 2;
   pszList = malloc( ulDataLen);
   if (!pszList)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszList, 0, ulDataLen);
   if (!PrfQueryProfileString(  hini, pszAppRegContainer, pszPath, NULL, pszList, ulDataLen))
      {
      rc = LASTERROR;
      break;
      }

   // is key in there already ? then quit with no error
   pszEntry = _strword( pszList, pszKey);
   if (pszEntry)
      break;

   // add key to list and write back
   strcat( pszList, " ");
   strcat( pszList, pszKey);
   if (!PrfWriteProfileString( hini, pszAppRegContainer, pszPath, pszList))
      rc = LASTERROR;

   } while (FALSE);

// cleanup
if (pszList) free( pszList);
return rc;
}

// -----------------------------------------------------------------------------

static APIRET _createRegPath( HINI hini, PSZ pszValuePath)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszCopy = strdup( pszValuePath);
         PSZ            pszPath = strdup( pszValuePath);
         PSZ            pszLastPath = strdup( pszValuePath);

         PSZ            p;
         ULONG          ulDataLen;

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
//    // does container def exist ?
//    ulDataLen = 0;
//    if ((!PrfQueryProfileSize( hini, pszAppRegContainer, pszPath, &ulDataLen)) || (!ulDataLen))
//       PrfWriteProfileString( hini, pszAppRegContainer, pszPath, "");

      // add current basename to list of previous path
      // this will automatically create container lists if not yet existant
      if (*pszLastPath)
         rc = _addKeyToContainerList( hini, pszLastPath, p);
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

APIRET WriteConfigValue( PSZ pszValuePath, PSZ pszValue)

{
         APIRET         rc = NO_ERROR;
         HINI           hini = NULLHANDLE;

do
   {
   // check parms
   if ((!_isPathValid( pszValuePath)) ||
       (!pszValue))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // open profile
   hini = _openLibProfile();
   if (!hini)
      {
      rc = LASTERROR;
      break;
      }

   // create path if not exist
   rc = _createRegPath( hini, pszValuePath);
   if (rc != NO_ERROR)
      break;

   // create entry
   if (!PrfWriteProfileString( hini, pszAppRegKeys, pszValuePath, pszValue))
      {
      rc = LASTERROR;
      break;
      }


   } while (FALSE);


// cleanup
if (hini) PrfCloseProfile( hini);
return rc;

}

// -----------------------------------------------------------------------------

APIRET QueryConfigValue( PSZ pszValuePath, PSZ pszBuffer, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;
         HINI           hini = NULLHANDLE;

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

   // open profile
   hini = _openLibProfile();
   if (!hini)
      {
      rc = LASTERROR;
      break;
      }

   // read entry
   if (!PrfQueryProfileString( hini, pszAppRegKeys, pszValuePath, NULL, pszBuffer, ulBuflen))
      {
      rc = LASTERROR;
      break;
      }

   } while (FALSE);


// cleanup
if (hini) PrfCloseProfile( hini);
return rc;

}
