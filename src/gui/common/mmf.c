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
* $Id: mmf.c,v 1.2 2002-09-24 21:38:17 cla Exp $
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

// Internal structures and constants
#define PAG_SIZE    4096
#define PAG_MASK    0xFFFFF000

typedef struct _MMFENTRY
  {
         ULONG          ulFlags;
         HFILE          hfile;
         PVOID          pvData;
         ULONG          ulSize;
         ULONG          ulCurrentSize;
#ifdef DEBUG
         CHAR           szFile[ _MAX_PATH];
#endif
  } MMFENTRY, *PMMFENTRY;

#define MMF_MAX         256
#define MMF_USEDENTRY   0x10000000  /* internal flag to mark a used entry */

// global data
static   EXCEPTIONREGISTRATIONRECORD errh;
static   MMFENTRY       ammfentry[ MMF_MAX];
static   BOOL           fInitialized = FALSE;

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

#define EXCEPTION_NUM   p1->ExceptionNum
#define EXCEPTION_TYPE  p1->ExceptionInfo[ 0]

static ULONG APIENTRY _pageFaultHandler( PEXCEPTIONREPORTRECORD p1,
                                         PEXCEPTIONREGISTRATIONRECORD p2,
                                         PCONTEXTRECORD p3, PVOID  pv)
{
if ((EXCEPTION_NUM == XCPT_ACCESS_VIOLATION)      &&
    ((EXCEPTION_TYPE == XCPT_WRITE_ACCESS) ||
     (EXCEPTION_TYPE == XCPT_READ_ACCESS)))
   {
            PMMFENTRY      pmmfe  = 0;
            PVOID          pvPage  = 0;
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

   // determine page adress
   pvPage = (PVOID)(p1->ExceptionInfo[ 1] & PAG_MASK);

   // query flags of affected page
   rc = DosQueryMem( pvPage, &ulSize, &ulFlag);
   if (rc != NO_ERROR)
      {
      DPRINTF(( "MMF: HANDLER: cannot query memory flags for file: %s, rc=%u\n", pmmfe->szFile, rc));
      return XCPT_CONTINUE_SEARCH;
      }

   // determine position in memory regarded to the base pointer
   ulMemPos = (PSZ) pvPage - (PSZ) pmmfe->pvData;

   // There can be three cases:
   //
   //  1. We trying to read page              - always OK, commit it
   //  2. We trying to write committed page   - OK if READ/WRITE mode
   //  3. We trying to write uncommitted page - OK if READ/WRITE mode
   //                                           but we need to commit it.

   // ------------------------------------------------------

   // filter out case 2

   // we don't care for readonly access here, since if the allocated memory is opened
   // with MMF_ACCESS_READONLY, it cannot be modified anyway. So there is no need to
   // cause an exception violation here

// if ((p1->ExceptionInfo[ 0] == XCPT_WRITE_ACCESS) &&
//     ((pmmfe->ulFlags & ~MMF_USEDENTRY) == MMF_ACCESS_READONLY))
//    {
//    DPRINTF(( "MMF: HANDLER: denied write access according to allocation flags for file: %s\n", pmmfe->szFile));
//    return XCPT_CONTINUE_SEARCH;
//    }

   // if page is not committed, commit it and mark as readonly
   if (!(ulFlag & PAG_COMMIT))
      {
      // set commit status for this page temporarily
      rc = DosSetMem( pvPage, PAG_SIZE, PAG_COMMIT | PAG_READ | PAG_WRITE);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: HANDLER: cannot commit memory for file: %s, rc=%u\n", pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }

      // read data from file if it is a file area
      if (pmmfe->hfile)
         {
         // if memory is not beyond current file size, read from file
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
                          pvPage,
                          PAG_SIZE,
                          &ulFilePtr);
            if (rc != NO_ERROR)
               {
               DPRINTF(( "MMF: HANDLER: cannot read file position 0x%08x from file: %s, rc=%u\n", ulFilePtr, pmmfe->szFile, rc));
               return XCPT_CONTINUE_SEARCH;
               }

            } // if (ulMemPos < pmmfe->ulCurrentSize)

         } // if (pmmfe->hfile)

      // set page to read access (PAG_COMMIT already set at this point !)
      DosSetMem( pvPage, PAG_SIZE, PAG_READ);


      } // if (!(ulFlag & PAG_COMMIT))

   // if we had a violation on write access
   //  -> mark the page writable, so that we will update that
   //     part of the file later
   //  -> PAG_COMMIT already set at this point !
   if (EXCEPTION_TYPE == XCPT_WRITE_ACCESS)
      {
      ulMemPos = (PSZ) pvPage - (PSZ) pmmfe->pvData;
      rc = DosSetMem( pvPage, PAG_SIZE, PAG_READ | PAG_WRITE);
      if (rc != NO_ERROR)
         {
         DPRINTF(( "MMF: HANDLER: cannot set memory at 0x%08x to readwrite for file: %s, rc=%u\n", ulMemPos, pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }
      } // if (EXCEPTION_TYPE == XCPT_WRITE_ACCESS)

   // if necessary, extend current file size to end of new page
   if (ulMemPos > pmmfe->ulCurrentSize)
      pmmfe->ulCurrentSize = ulMemPos + PAG_SIZE;

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
       (ulOpenFlags > MMF_ACCESS_READWRITE))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init if necessary
   CHECKINIT;

   // locate free entry in table
   pmmfe = _locateFree();
   if(!pmmfe)
      {
      rc = ERROR_TOO_MANY_OPEN_FILES;
      break;
      }


   // use a link to a file
   if ((pszFilename) && (*pszFilename))
      {
      // check file size first, it may not be larger than requested memory
      ulCurrentSize = QueryFileSize( pszFilename);
      if (ulMaxSize  < ulCurrentSize)
         {
         rc = ERROR_BUFFER_OVERFLOW;
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


      } // if ((pszFilename) && (*pszFilename))


   // allocate memory for the file
   rc = DosAllocMem( &pvData, ulMaxSize, PAG_READ | PAG_WRITE);
   if (rc != NO_ERROR)
      break;

   // setup handle data
   pmmfe->ulFlags       = ulOpenFlags | MMF_USEDENTRY;
   pmmfe->hfile         = hfile;
   pmmfe->pvData        = pvData;
   pmmfe->ulSize        = ulMaxSize;
   pmmfe->ulCurrentSize = ulCurrentSize;

   *ppvdata = pvData;

#ifdef DEBUG
   if (pszFilename)
      DosQueryPathInfo( pszFilename, FIL_QUERYFULLNAME, pmmfe->szFile, sizeof( pmmfe->szFile));
#endif


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

   // don't allow update if it is not a file area at all
   if (!(pmmfe->hfile))
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

