/****************************** Module Header *******************************
*
* Module Name: ddeutil.c
*
* Generic DDE utilities.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ddeutil.c,v 1.1 2002-06-03 22:19:57 cla Exp $
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

#include "ddeutil.h"

// ---------------------------------------------------------------------

#define PAGE_ATTRIBUTES (PAG_READ | PAG_WRITE | PAG_COMMIT | OBJ_TILE | OBJ_GIVEABLE | OBJ_GETTABLE)

PDDESTRUCT MakeDDEMsg( USHORT usFormat, PSZ pszItemName, PVOID Data, USHORT usDataSize)
{
         PDDESTRUCT     pdde = NULL;
         APIRET         rc   = NO_ERROR;
         ULONG          usNameSize;
         ULONG          ulTotalSize;

do
   {
   // calculate some sizes
   usNameSize = strlen( pszItemName) + 1;
   ulTotalSize = sizeof( DDESTRUCT) + usDataSize + usNameSize;

   //  allocate  givable shared memory
   rc = DosAllocSharedMem( (PPVOID) &pdde,
                           NULL,
                           ulTotalSize,
                           PAGE_ATTRIBUTES);
   if (rc != NO_ERROR)
      break;

   // Fill in the new DDE structure
   memset((PVOID) pdde, 0, ulTotalSize);
   pdde->cbData        = ulTotalSize;
   pdde->fsStatus      = 0;
   pdde->usFormat      = usFormat;
   pdde->offszItemName = sizeof( DDESTRUCT);
   memcpy( DDES_PSZITEMNAME( pdde), pszItemName, usNameSize);
   pdde->offabData     = sizeof( DDESTRUCT) + usNameSize;
   memcpy( DDES_PABDATA(pdde), Data,usDataSize);
   } while (FALSE);

return  pdde;
}

