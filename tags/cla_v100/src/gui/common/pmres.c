/****************************** Module Header *******************************
*
* Module Name: pmres.c
*
* Generic functions to access PM resources.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
#include <stdarg.h>
#include <string.h>

#include "pmres.h"
#include "file.h"
#include "macros.h"

// -----------------------------------------------------------------------------

APIRET WriteResourceToFile( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ pszFile)
{
         APIRET         rc = NO_ERROR;

         PVOID          pvResource = NULL;
         ULONG          ulResourceLen;

         ULONG          ulAction;
         ULONG          ulBytesWritten;
         HFILE          hfile = NULLHANDLE;

do
   {
   // check parms
   if (!pszFile)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get resource size and data
   rc = DosQueryResourceSize( hmodResource, ulResType, ulResId, &ulResourceLen);
   if (rc != NO_ERROR)
      break;
   rc = DosGetResource( hmodResource, ulResType, ulResId, &pvResource);
   if (rc != NO_ERROR)
      break;

   // open and write file
   rc = DosOpen( pszFile,
                 &hfile,
                 &ulAction,
                 0,
                 0,
                 OPEN_ACTION_CREATE_IF_NEW | OPEN_ACTION_REPLACE_IF_EXISTS,
                 OPEN_SHARE_DENYREADWRITE | OPEN_ACCESS_WRITEONLY,
                 NULL);
   if (rc != NO_ERROR)
      break;
   rc = DosWrite( hfile, pvResource, ulResourceLen, &ulBytesWritten);

   } while ( FALSE);

// cleanup
if (hfile) DosClose( hfile);
if (pvResource) DosFreeResource( pvResource);
return rc;

}

// -----------------------------------------------------------------------------

APIRET WriteResourceToTmpFile( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ pszTmpFile, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

do
   {
   // check parms
   if (!pszTmpFile)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get temp filename
   rc = GetTempFilename( pszTmpFile, ulBuflen);
   if (rc != NO_ERROR)
      break;

   // do it
   rc = WriteResourceToFile( hmodResource, ulResType, ulResId, pszTmpFile);


   } while ( FALSE);

return rc;

}

// -----------------------------------------------------------------------------

APIRET GetStringResource( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ *ppszBuffer)
{
         APIRET         rc = NO_ERROR;
         CHAR           szFilename[ _MAX_PATH];

         PVOID          pvResource = NULL;
         ULONG          ulResourceLen;
         PSZ            pszCopy = NULL;


do
   {
   // check parms
   if (!ppszBuffer)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get resource size and data
   rc = DosQueryResourceSize( hmodResource, ulResType, ulResId, &ulResourceLen);
   if (rc != NO_ERROR)
      break;
   rc = DosGetResource( hmodResource, ulResType, ulResId, &pvResource);
   if (rc != NO_ERROR)
      break;

   // create copy
   pszCopy = malloc( ulResourceLen + 1);
   if (!pszCopy)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memcpy( pszCopy, pvResource, ulResourceLen);
   *(pszCopy + ulResourceLen) = 0;
   *ppszBuffer = pszCopy;

   } while ( FALSE);

// cleanup
if (pvResource) DosFreeResource( pvResource);
if ((rc != NO_ERROR) && (pszCopy))
   free( pszCopy);

return rc;

}

// ---------------------------------------------------------------------

ULONG ShowNlsError( HWND hwnd, HMODULE hmod, PSZ pszTitle, ULONG ulResId, ...)
{

         ULONG          ulResult = MBID_CANCEL;
         va_list        arg_ptr;
         CHAR           szString[ 2 * _MAX_PATH];
         CHAR           szMessage [ 4 * _MAX_PATH];

if (WinLoadString( CURRENTHAB, hmod, ulResId, sizeof( szString), szString))
   {
   va_start (arg_ptr, ulResId);
   vsprintf( szMessage, szString, arg_ptr);
   ulResult = WinMessageBox( HWND_DESKTOP, hwnd, szMessage, pszTitle, -1, MB_CANCEL | MB_ERROR | MB_MOVEABLE);
   }

return ulResult;
}

