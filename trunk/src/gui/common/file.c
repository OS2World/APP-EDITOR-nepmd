/****************************** Module Header *******************************
*
* Module Name: file.c
*
* Generic routines for accessing files and directories.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: file.c,v 1.1 2002-06-03 22:19:57 cla Exp $
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
#define INCL_ERRORS
#include <os2.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "file.h"

// -----------------------------------------------------------------------------
ULONG _swapTimestamp( ULONG ulTimeStamp)
{

swab( (PSZ)&ulTimeStamp,
      (PSZ)&ulTimeStamp,
      sizeof( ulTimeStamp));

swab( (PSZ)&ulTimeStamp,
      (PSZ)&ulTimeStamp,
      sizeof( ulTimeStamp) / 2);

swab( (PSZ)&ulTimeStamp + (sizeof( ulTimeStamp) / 2),
      (PSZ)&ulTimeStamp + (sizeof( ulTimeStamp) / 2),
      sizeof( ulTimeStamp) / 2);

return ulTimeStamp;
}

// -----------------------------------------------------------------------------

APIRET GetTempFilename( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszTmpFile = NULL;

do
   {
   // check parms
   if (!pszBuffer)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get temporary file
   pszTmpFile = _tempnam( NULL, "ST"); 

   // hand over result
   if (strlen( pszTmpFile) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszBuffer, pszTmpFile);

   } while (FALSE);


// cleanup
if (pszTmpFile) free( pszTmpFile);
return rc;

}

// -----------------------------------------------------------------------------

static BOOL _entryExists( PSZ pszName, BOOL fSearchDirectory)
{
         APIRET         rc = NO_ERROR;
         BOOL           fResult = FALSE;
         FILESTATUS3    fs3;
         BOOL           fIsDirectory = FALSE;


do
   {
   // check parameters
   if ((pszName  == NULL) ||
       (*pszName == 0))
      break;

   // search entry
   rc = DosQueryPathInfo( pszName,
                          FIL_STANDARD,
                          &fs3,
                          sizeof( fs3));
   if (rc != NO_ERROR)
      break;

   // check for directory or file
   fIsDirectory = ((fs3.attrFile & FILE_DIRECTORY) > 0);
   fResult = (fIsDirectory == fSearchDirectory);

   } while (FALSE);

return fResult;
}

// -----------------------------------------------------------------------------

BOOL FileExists( PSZ pszName)
{
return _entryExists( pszName, FALSE);
}

BOOL DirExists( PSZ pszName)
{
return _entryExists( pszName, TRUE);
}

// -----------------------------------------------------------------------------

ULONG FileDate( PSZ pszName)
{
         ULONG          ulTimeStamp = (ULONG) -1;
         APIRET         rc = NO_ERROR;
         FILESTATUS3    fs3;

do
   {
   // check parameters
   if ((pszName  == NULL) ||
       (*pszName == 0))
      break;

   // search entry
   rc = DosQueryPathInfo( pszName,
                          FIL_STANDARD,
                          &fs3,
                          sizeof( fs3));
   if (rc != NO_ERROR)
      break;

   // copy timestamp
   memcpy( (PBYTE) &ulTimeStamp,     &fs3.ftimeLastWrite, sizeof( FTIME));
   memcpy( (PBYTE) &ulTimeStamp + 2, &fs3.fdateLastWrite, sizeof( FDATE));
   ulTimeStamp = _swapTimestamp( ulTimeStamp);

   } while (FALSE);

return ulTimeStamp;
}

// -----------------------------------------------------------------------------

APIRET FileInPath( PSZ pszEnvName, PSZ pszName, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         CHAR           szFullName[ _MAX_PATH];
do
   {
   // check parameters
   if ((!pszName) ||
       (!*pszName))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   if (!pszEnvName)
      pszEnvName = "PATH";

   if (!pszBuffer) 
      {
      pszBuffer = szFullName;
      ulBuflen  = sizeof( szFullName);
      }


   // check for executable
   rc = DosSearchPath( SEARCH_IGNORENETERRS  |
                       SEARCH_ENVIRONMENT    |
                       SEARCH_CUR_DIRECTORY,
                       pszEnvName,
                       pszName,
                       pszBuffer,
                       ulBuflen);

   } while (FALSE);

return rc;
}

