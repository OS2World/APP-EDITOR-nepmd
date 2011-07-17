/****************************** Module Header *******************************
*
* Module Name: module.c
*
* Generic routines for retrieving executable infos
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INCL_ERRORS
#define INCL_DOS
#define INCL_WIN
#include <os2.h>

// using undocumented function
APIRET APIENTRY DosQueryModFromEIP (HMODULE *phModule, ULONG *pulObjectNumber,
                                    ULONG ulBufferLength, PCHAR pchBuffer,
                                    ULONG *pulOffset, PVOID pvAddress);

// -----------------------------------------------------------------------------

APIRET EXPENTRY GetModuleName( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

         PPIB           ppib;
         PTIB           ptib;

         HMODULE        hmod;
         ULONG          ulObjectNumber;
         ULONG          ulOffset;
         CHAR           szModuleName[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszBuffer) ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get path and name of this executable
   rc = DosQueryModFromEIP( &hmod, &ulObjectNumber,
                            sizeof( szModuleName), szModuleName,
                            &ulOffset, (PVOID) GetModuleName);
   if (rc != NO_ERROR)
      break;

   // query also fullname for globally loaded DLLs
   DosQueryModuleName( hmod, sizeof( szModuleName), szModuleName);

   // check result buffer
   if (strlen( szModuleName) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szModuleName);


   } while (FALSE);

return rc;

}

