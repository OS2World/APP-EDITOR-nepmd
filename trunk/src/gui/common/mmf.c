/****************************** Module Header *******************************
*
* Module Name: mmf.c
*
* Generic routines to support memory mapped files
*
* This code bases on the MMF library by Sergey I. Yevtushenko
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mmf.c,v 1.1 2002-09-24 16:47:57 cla Exp $
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
/*
todo: encapsulate init
*/


#define INCL_DOS
#define INCL_ERRORS
#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "macros.h"
#include "mmf.h"
#include "file.h"

#define DEBUG_PRINTF_ALL_ACTIONS 1

// Internal structures and constants
#define PAG_SIZE    4096
#define PAG_MASK    0xFFFFF000

typedef struct _MMFENTRY
  {
         ULONG          ulFlags;
         CHAR           szFile[ _MAX_PATH];
         HFILE          hfile;
         PVOID          pvData;
         ULONG          ulSize;
         ULONG          ulFileSize;
         ULONG          ulCurrentSize;
  } MMFENTRY, *PMMFENTRY;

#define MMF_MAX         32
#define MMF_USEDENTRY   0x10000000  /* internal flag to mark a used entry */

// global data
static   MMFENTRY       ammfentry[ MMF_MAX];
static   BOOL           fInitialized = FALSE;
static   EXCEPTIONREGISTRATIONRECORD errh;

// some macros to ensure initialization
#define CHECKINIT                 \
if (!_initialized())              \
   {                              \
   rc = ERROR_INVALID_FUNCTION;   \
   break;                         \
   }

// -----------------------------------------------------------------------------

// Local functions implementation

static PMMFENTRY _locate( PVOID addr)
{
         ULONG          i;

for (i = 0; i < MMF_MAX; i++)
   {
   if(ammfentry[ i].ulFlags & MMF_USEDENTRY)
      {
      if (((ULONG) ammfentry[ i].pvData <= (ULONG) addr) &&
          (((ULONG) ammfentry[ i].pvData + ammfentry[ i].ulSize) >= (ULONG) addr))
         return &ammfentry[ i];
      }
   }

return 0;
}

// -----------------------------------------------------------------------------

static PMMFENTRY _locateFree( VOID)
{
         ULONG          i;

   for(i = 0; i < MMF_MAX; i++)
      {
      if (!(ammfentry[ i].ulFlags & MMF_USEDENTRY))
         return &ammfentry[ i];
      }
return 0;
}

// -----------------------------------------------------------------------------

#define TRACE {printf("%s(%d) - %d\n", __FILE__,__LINE__,rc);}


static ULONG APIENTRY _pageFaultHandler( PEXCEPTIONREPORTRECORD p1, PEXCEPTIONREGISTRATIONRECORD p2,
                                         PCONTEXTRECORD p3, PVOID  pv)
{

if ((p1->ExceptionNum == XCPT_ACCESS_VIOLATION)      &&
    (( p1->ExceptionInfo[ 0] == XCPT_WRITE_ACCESS) ||
     (p1->ExceptionInfo[ 0] == XCPT_READ_ACCESS)))
   {
            PMMFENTRY      pmmfe  = 0;
            PVOID          pPage  = 0;
            APIRET         rc     = NO_ERROR;
            ULONG          ulFlag = 0;
            ULONG          ulSize = PAG_SIZE;

            ULONG          ulFilePtr = 0;
            ULONG          ulMemPos;

   pmmfe = _locate( (PVOID) p1->ExceptionInfo[ 1]);
   if(!pmmfe)
      {
      DPRINTF(( "MMF: HANDLER: skipped exception, not my memory\n"));
      return XCPT_CONTINUE_SEARCH;
      }

   pPage = (PVOID)(p1->ExceptionInfo[ 1] & PAG_MASK);

   // Query affected page flags
   rc = DosQueryMem( pPage, &ulSize, &ulFlag);
   if (rc != NO_ERROR)
      {
      DPRINTF(( "MMF: HANDLER: cannot query memory flags for file: %s, rc=%u\n", pmmfe->szFile, rc));
      return XCPT_CONTINUE_SEARCH;
      }

   //
   // There can be three cases:
   //
   //  1. We trying to read page              - always OK, commit it
   //  2. We trying to write committed page   - OK if READ/WRITE mode
   //  3. We trying to write uncommitted page - OK if READ/WRITE mode
   //                                           but we need to commit it.

   // we don't care for readonly access here, sinde if the allocated memory is opened
   // with MMF_ACCESS_READONLY, it cannot be modified anyway. So there is no need to
   // cause an exception violation here
#if 0
   // filter out case 2

   if ((p1->ExceptionInfo[ 0] == XCPT_WRITE_ACCESS) &&
       ((pmmfe->ulFlags & ~MMF_USEDENTRY) == MMF_ACCESS_READONLY))
      {
      DPRINTF(( "MMF: HANDLER: denied write access according to allocation flags for file: %s\n", pmmfe->szFile));
      return XCPT_CONTINUE_SEARCH;
      }
#endif

   // if page not committed, commit it and mark as readonly
   if(!(ulFlag & PAG_COMMIT))
      {
      // set commit status for this page temporarily
      rc = DosSetMem( pPage, PAG_SIZE, PAG_COMMIT | PAG_READ | PAG_WRITE);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: HANDLER: cannot commit memory for file: %s, rc=%u\n", pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }

      // if memory is not beyond current file size, read from file
      ulMemPos = (PSZ) pPage - (PSZ) pmmfe->pvData;
      if (ulMemPos < pmmfe->ulCurrentSize)
         {
         // set file position
         rc = DosSetFilePtr( pmmfe->hfile,
                             ulMemPos,
                             FILE_BEGIN,
                             &ulFilePtr);
         if (rc != NO_ERROR)
            {
            DPRINTF(( "MMF: HANDLER: cannot set file position 0x%08x for file: %s, rc=%u\n", ulMemPos, pmmfe->szFile, rc));
            return XCPT_CONTINUE_SEARCH;
            }
   
         // read page from disk
         rc = DosRead( pmmfe->hfile,
                       pPage,
                       PAG_SIZE,
                       &ulFilePtr);
         if (rc != NO_ERROR)
            {
            DPRINTF(( "MMF: HANDLER: cannot read file position 0x%08x from file: %s, rc=%u\n", ulFilePtr, pmmfe->szFile, rc));
            return XCPT_CONTINUE_SEARCH;
            }

#if DEBUG_PRINTF_ALL_ACTIONS
         DPRINTF(( "MMF: HANDLER: read page 0x%08x from file: %s\n", ulMemPos, pmmfe->szFile));
#endif
         }
      else
         {
         // extend current file size to end of new page
         pmmfe->ulCurrentSize = ulMemPos + PAG_SIZE;
#if DEBUG_PRINTF_ALL_ACTIONS
         DPRINTF(( "MMF: HANDLER: extended file size to 0x%08x for file: %s\n", pmmfe->ulCurrentSize, pmmfe->szFile));
#endif
         }

      rc = DosSetMem( pPage, PAG_SIZE, PAG_READ);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: HANDLER: cannot reset memory at 0x%08x to readonly for file: %s, rc=%u\n", ulMemPos, pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }
      }

   // if page already committed, and accessed for writing - mark them writable
   if (p1->ExceptionInfo[ 0] == XCPT_WRITE_ACCESS)
      {
      ulMemPos = (PSZ) pPage - (PSZ) pmmfe->pvData;
      rc = DosSetMem( pPage, PAG_SIZE, PAG_READ | PAG_WRITE);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: HANDLER: cannot set memory at 0x%08x to readwrite for file: %s, rc=%u\n", ulMemPos, pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }
#if DEBUG_PRINTF_ALL_ACTIONS
      DPRINTF(( "MMF: HANDLER: set write access for page 0x%08x for file: %s\n", ulMemPos, pmmfe->szFile));
#endif
      }

   return XCPT_CONTINUE_EXECUTION;
   }

return XCPT_CONTINUE_SEARCH;
}

// -----------------------------------------------------------------------------

static APIRET _initialize( VOID)
{

         APIRET         rc = NO_ERROR;
do
   {
   memset( &errh, 0, sizeof( errh));
   errh.ExceptionHandler = (ERR) _pageFaultHandler;
   rc = DosSetExceptionHandler( &errh);
   if (rc != NO_ERROR)
      break;

   // init handle table
   memset( ammfentry, 0, sizeof( ammfentry));

   // were done
   fInitialized = TRUE;

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static BOOL _initialized( VOID)
{
// try to initialize
if (!fInitialized)
   _initialize();

// return current status
return fInitialized;
}

// #############################################################################


APIRET MmfAlloc( PVOID *ppvdata, PSZ pszFilename, ULONG ulOpenFlags, ULONG ulMaxSize)
{
         APIRET         rc = NO_ERROR;

         ULONG          ulAction;
         ULONG          fsOpenMode;
         
         HFILE          hfile = NULLHANDLE;
         ULONG          ulCurrentSize = 0;
         PVOID          pvData = NULL;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if ((!ppvdata)       ||
       (!pszFilename)  ||
       (!*pszFilename) ||
       (ulOpenFlags > MMF_ACCESS_READWRITE))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init if necessary
   CHECKINIT;


   // check file size first, it may not be larger than requested memory
   ulCurrentSize = QueryFileSize( pszFilename);
   if (ulMaxSize  < ulCurrentSize)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

    // locate free entry in table
    pmmfe = _locateFree();
    if(!pmmfe)
       {
       rc = ERROR_TOO_MANY_OPEN_FILES;
       break;
       }

   // adapte access flages
   switch (ulOpenFlags)
      {
      default:
      case MMF_ACCESS_READONLY:  fsOpenMode = OPEN_ACCESS_READONLY  | OPEN_SHARE_DENYWRITE;     break;
      case MMF_ACCESS_WRITEONLY: fsOpenMode = OPEN_ACCESS_WRITEONLY | OPEN_SHARE_DENYWRITE;     break;
      case MMF_ACCESS_READWRITE: fsOpenMode = OPEN_ACCESS_READWRITE | OPEN_SHARE_DENYREADWRITE; break;
      }

   // open file
   rc = DosOpen( pszFilename,
                 &hfile,
                 &ulAction,
                 0L,
                 FILE_ARCHIVED | FILE_NORMAL,
                 OPEN_ACTION_CREATE_IF_NEW | OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_FLAGS_NOINHERIT | OPEN_FLAGS_FAIL_ON_ERROR | fsOpenMode,
                 NULL);
   if (rc != NO_ERROR)
      return rc;

   // allocate memory for the file
   rc = DosAllocMem( &pvData, ulMaxSize, PAG_READ | PAG_WRITE);
   if (rc != NO_ERROR)
      break;

   // setup handle data
   pmmfe->ulFlags       = ulOpenFlags | MMF_USEDENTRY;
   pmmfe->hfile         = hfile;
   pmmfe->pvData        = pvData;
   pmmfe->ulSize        = ulMaxSize;
   pmmfe->ulFileSize    = ulCurrentSize;
   pmmfe->ulCurrentSize = ulCurrentSize;
   DosQueryPathInfo( pszFilename, FIL_QUERYFULLNAME, pmmfe->szFile, sizeof( pmmfe->szFile));
   *ppvdata = pvData;


   } while (FALSE);

// cleanup
if (rc != NO_ERROR)
   if (hfile) DosClose( hfile);

return rc;
}


// -----------------------------------------------------------------------------

APIRET MmfFree( PVOID pvData)
{
         APIRET         rc = NO_ERROR;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if (!pvData)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init if necessary
   CHECKINIT;

   // search entry
   pmmfe = _locate( pvData);
   if (!pmmfe)
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   // cleanup all data related to the file
   if( pmmfe->hfile)  DosClose( pmmfe->hfile);
   if (pmmfe->pvData) DosFreeMem( pmmfe->pvData);
   memset( pmmfe, 0, sizeof( MMFENTRY));

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET MmfUpdate( PVOID pvData)
{
         APIRET         rc = NO_ERROR;
         PMMFENTRY      pmmfe;

         PBYTE          pbArea  = 0;
         ULONG          ulPos  = 0;
         ULONG          ulFlag = 0;
         ULONG          ulSize = PAG_SIZE;

         ULONG          ulFilePtr;
         ULONG          ulBytesToWrite;
         ULONG          ulBytesWritten;
         ULONG          ulMemPos;

do
   {
   // check parms
   if (!pvData)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init if necessary
   CHECKINIT;

   // search entry
   pmmfe = _locate( pvData);
   if (!pmmfe)
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   // don't allow update if readonly access
   if ((pmmfe->ulFlags & ~MMF_USEDENTRY) == MMF_ACCESS_READONLY)
      {
      rc = ERROR_ACCESS_DENIED;
      break;
      }

   // locate all regions which needs update, and actually update them
   for (pbArea = (PBYTE) pmmfe->pvData; ulPos < pmmfe->ulCurrentSize; ulPos += PAG_SIZE, pbArea += PAG_SIZE)   
      {
      rc = DosQueryMem(pbArea, &ulSize, &ulFlag);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: UPDATE: cannot query memory flags for file: %s, rc=%u\n", pmmfe->szFile, rc));
         break;
         }

      if (ulFlag & PAG_WRITE)
         {
         // set file pointer
         ulMemPos = (PSZ) pbArea - (PSZ) pmmfe->pvData;
         rc = DosSetFilePtr( pmmfe->hfile,
                             ulMemPos,
                             FILE_BEGIN,
                             &ulFilePtr);
         if (rc != NO_ERROR)
            {
            DPRINTF(( "MMF: UPDATE: cannot set file position for file: %s, rc=%u\n", pmmfe->szFile, rc));
            break;
            }

         // write portion of memory, either a full page or
         // the remaining portion of it
         ulBytesToWrite = MIN( PAG_SIZE, ulMemPos - pmmfe->ulCurrentSize);
         rc = DosWrite( pmmfe->hfile,
                        pbArea,
                        ulBytesToWrite,
                        &ulBytesWritten);
         if (rc != NO_ERROR)
            {
            DPRINTF(( "MMF: UPDATE: cannot write to file: %s, rc=%u\n", pmmfe->szFile, rc));
            break;
            }
         if (ulBytesToWrite != ulBytesWritten)
            {
            DPRINTF(( "MMF: UPDATE: cannot write to file: %s, rc=%u\n", pmmfe->szFile, rc));
            rc = ERROR_WRITE_FAULT;
            break;
            }

        } // if (ulFlag & PAG_WRITE)

    } // for (pbArea = (PBYTE) pmmfe->pvData; ...

   // set file position
   rc = DosSetFileSize( pmmfe->hfile,
                        pmmfe->ulCurrentSize);
   if (rc != NO_ERROR)
      {
      DPRINTF(( "MMF: UPDATE: cannot set file position for file: %s, rc=%u\n", pmmfe->szFile, rc));
      break;
      }


   } while (FALSE);

return rc;
}
           
// -----------------------------------------------------------------------------

APIRET MmfSetSize( PVOID pvData, ULONG ulNewSize)
{
         APIRET         rc = NO_ERROR;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if (!pvData)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init if necessary
   CHECKINIT;

   // search entry
   pmmfe = _locate( pvData);
   if (!pmmfe)
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   pmmfe->ulCurrentSize = ulNewSize;

   } while (FALSE);

return rc;
}
           
// -----------------------------------------------------------------------------

APIRET MmfQuerySize( PVOID pvData, PULONG pulSize)
{
         APIRET         rc = NO_ERROR;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if ((!pvData) ||
       (!pulSize))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }
   *pulSize = 0;

   // init if necessary
   CHECKINIT;

   // search entry
   pmmfe = _locate( pvData);
   if (!pmmfe)
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   // hand over result
   *pulSize = pmmfe->ulCurrentSize;

   } while (FALSE);

return rc;
}

