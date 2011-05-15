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

// --- defines for detailed debug messages
#define DEBUG_DUMPHANDLERACTIONS 0
#define DEBUG_DUMPALLOCACTIONS   0

#if DEBUG_DUMPHANDLERACTIONS
#define DPRINTF_HANDLERACTION(p)  DPRINTF(p)
#else
#define DPRINTF_HANDLERACTION(p)
#endif

#if DEBUG_DUMPALLOCACTIONS
#define DPRINTF_ALLOCACTION(p)  DPRINTF(p)
#else
#define DPRINTF_ALLOCACTION(p)
#endif

// internal MMF defines
#define MMF_MAXTHREADS     128
#define MMF_USEDENTRY      0x10000000  /* internal flag to mark a used entry */

#define MMF_MASK_ACCESS    0x0000FFFF
#define MMF_MASK_OPENMODE  0xFFFF0000

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

typedef struct _MMF
   {
         EXCEPTIONREGISTRATIONRECORD errh;
         ULONG          ulEntryCount;
         PMMFENTRY      apmmfentry;
         PID            pid;
         TID            tid;
   } MMF, *PMMF;


// global data
static   PMMF           apmmf[ MMF_MAXTHREADS];
static   BOOL           fInitialized = FALSE;

// #############################################################################

// prototype used here
PMMF _locateMMFHandler( VOID);

static PMMFENTRY _locateMMFEntry( PMMF pmmf, PVOID addr)
{
         ULONG          i;
         PMMFENTRY      pmmfeResult = NULL;
         PMMFENTRY      pmmfe;

if (!pmmf)
   pmmf = _locateMMFHandler();

if (pmmf)
   for (i = 0; i < pmmf->ulEntryCount; i++)
      {
      pmmfe = pmmf->apmmfentry + i;

      if(pmmfe->ulFlags & MMF_USEDENTRY)
         {
         if (((ULONG) pmmfe->pvData <= (ULONG) addr) &&
             (((ULONG) pmmfe->pvData + pmmfe->ulSize) >= (ULONG) addr))
            {
            pmmfeResult = pmmfe;
            break;
            }
         }
      }

return pmmfeResult;
}

// -----------------------------------------------------------------------------

static PMMFENTRY _locateFreeMMFEntry( PMMF pmmf)
{
         ULONG          i;
         PMMFENTRY      pmmfeResult = NULL;
         PMMFENTRY      pmmfe;

if (pmmf)
   for(i = 0; i < pmmf->ulEntryCount; i++)
      {
      pmmfe = pmmf->apmmfentry + i;
      if (!(pmmfe->ulFlags & MMF_USEDENTRY))
         {
         pmmfeResult = pmmfe;
         break;
         }
      }
return pmmfeResult;
}

// -----------------------------------------------------------------------------

static VOID _destroyMMFEntry( PMMFENTRY pmmfe)
{
         APIRET         rc = NO_ERROR;

if ((pmmfe) && (pmmfe->ulFlags & MMF_USEDENTRY))
   {
   // cleanup all data related to the file
   if( pmmfe->hfile)  DosClose( pmmfe->hfile);
   if (pmmfe->pvData)
      {
      rc = DosFreeMem( pmmfe->pvData);
      DPRINTF_ALLOCACTION(( "MMF: FREE 0x%08p (0x%08p) rc=%u\n", pmmfe->pvData,  pmmfe->ulSize, rc));
      }
   memset( pmmfe, 0, sizeof( MMFENTRY));
   }

return;
}

// #############################################################################

static PMMF _locateMMFHandler( VOID)
{
         ULONG          i;
         PMMF           pmmfResult = NULL;

         PMMF           pmmf;
         PPIB           ppib;
         PTIB           ptib;

// get process and thread id
DosGetInfoBlocks( &ptib,&ppib);
for (i = 0; i < MMF_MAXTHREADS; i++)
   {
   pmmf = apmmf[ i];
   if ((pmmf)                         &&
       (pmmf->pid == ppib->pib_ulpid) &&
       (pmmf->tid == ptib->tib_ptib2->tib2_ultid))
      {
      pmmfResult = pmmf;
      }
   }

return pmmfResult;
}

// -----------------------------------------------------------------------------

// prototype used here
ULONG APIENTRY _pageFaultHandler( PEXCEPTIONREPORTRECORD p1,
                                  PEXCEPTIONREGISTRATIONRECORD p2,
                                  PCONTEXTRECORD p3, PVOID  pv);

static PMMF _createNewMMFHandler( ULONG ulMaxBuffer)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         PMMF           pmmfNew = NULL;

         PPIB           ppib;
         PTIB           ptib;

// zero handles not allowed
if (!ulMaxBuffer)
   return NULL;

// get process and thread id
DosGetInfoBlocks( &ptib,&ppib);
for (i = 0; i < MMF_MAXTHREADS; i++)
   {
   if (!apmmf[ i])
      {
      // get memory for data struct
      pmmfNew = malloc( sizeof( MMF));
      if (pmmfNew)
         {
         apmmf[ i] = pmmfNew;
         memset( pmmfNew, 0, sizeof( MMF));
         pmmfNew->pid = ppib->pib_ulpid;
         pmmfNew->tid = ptib->tib_ptib2->tib2_ultid;

         // get memory for MMF entries
         pmmfNew->apmmfentry = malloc( sizeof( MMFENTRY) * ulMaxBuffer);
         if (pmmfNew->apmmfentry)
            {
            // initialize entries
            pmmfNew->ulEntryCount = ulMaxBuffer;
            memset( pmmfNew->apmmfentry, 0, sizeof( MMFENTRY) * ulMaxBuffer);

            // initialize
            memset( &pmmfNew->errh, 0, sizeof( pmmfNew->errh));
            pmmfNew->errh.ExceptionHandler = (ERR) _pageFaultHandler;
            rc = DosSetExceptionHandler( &pmmfNew->errh);
            if (rc != NO_ERROR)
               break;

            }

         // we are done
         break;
         }
      }
   }

// cleanup
if (rc != NO_ERROR)
   if (pmmfNew) free( pmmfNew);

return pmmfNew;
}

// -----------------------------------------------------------------------------

static APIRET _destroyMMFHandler( PMMF pmmf)
{
         APIRET         rc = NO_ERROR;
         ULONG          i, j;

if (pmmf)
   {
   rc = ERROR_INVALID_HANDLE;
   for (i = 0; i < MMF_MAXTHREADS; i++)
      {
      if (apmmf[ i] == pmmf)
         {
         // release all memory objects
         for (j = 0; j < pmmf->ulEntryCount; j++)
            {
            _destroyMMFEntry( pmmf->apmmfentry + j);
            }

         // release handler
         rc = DosUnsetExceptionHandler( &pmmf->errh);
         if (rc != NO_ERROR)
            break;

         // reset handler data
         memset( pmmf, 0, sizeof( MMF));
         apmmf[ i] = NULL;
         rc = NO_ERROR;
         break;
         }
      }
   } // if (pmmf)

return rc;
}
// #############################################################################

#define EXCEPTION_NUM   p1->ExceptionNum
#define EXCEPTION_TYPE  p1->ExceptionInfo[ 0]
#define EXCEPTION_ADDR  (PVOID) p1->ExceptionInfo[ 1]

static ULONG APIENTRY _pageFaultHandler( PEXCEPTIONREPORTRECORD p1,
                                         PEXCEPTIONREGISTRATIONRECORD p2,
                                         PCONTEXTRECORD p3, PVOID  pv)
{
DPRINTF_HANDLERACTION(( "MMF: HANDLER: called on address 0x%08x\n", EXCEPTION_ADDR));

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

   DPRINTF_HANDLERACTION(( "MMF: HANDLER: catching exception\n"));

   pmmfe = _locateMMFEntry( NULL, EXCEPTION_ADDR);
   DPRINTF_HANDLERACTION(( "MMF: HANDLER: examining address 0x%08x\n", EXCEPTION_ADDR));
   if(!pmmfe)
      {
      DPRINTF(( "MMF: HANDLER: exit - not my memory\n"));
      return XCPT_CONTINUE_SEARCH;
      }

   // determine page address
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
         DPRINTF(( "MMF: HANDLER: cannot commit memory at 0x%08x for file: %s, rc=%u\n", pvPage, pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }
      else
         DPRINTF_HANDLERACTION(( "MMF: HANDLER: commit memory at 0x%08x for file: %s\n", pvPage, pmmfe->szFile));

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
      rc = DosSetMem( pvPage, PAG_SIZE, PAG_READ);
      DPRINTF_HANDLERACTION(( "MMF: HANDLER: set memory at 0x%08x to read for file: %s\n", pvPage, pmmfe->szFile));


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
         DPRINTF(( "MMF: HANDLER: cannot set memory at 0x%08x to readwrite for file: %s, rc=%u\n", pvPage, pmmfe->szFile, rc));
         return XCPT_CONTINUE_SEARCH;
         }
      else
         DPRINTF_HANDLERACTION(( "MMF: HANDLER: set memory at 0x%08x to readwrite for file: %s\n", pvPage, pmmfe->szFile));
      } // if (EXCEPTION_TYPE == XCPT_WRITE_ACCESS)

   // if necessary, extend current file size to end of new page
   if (ulMemPos > pmmfe->ulCurrentSize)
      pmmfe->ulCurrentSize = ulMemPos + PAG_SIZE;

   return XCPT_CONTINUE_EXECUTION;
   }

return XCPT_CONTINUE_SEARCH;
}

// -----------------------------------------------------------------------------

#ifdef DEBUG
VOID _dumpMMF(  PMMF pmmf)
{
         ULONG          i;
         ULONG          ulCount = 0;
         PSZ            pszType;
         PPIB           ppib;
         PTIB           ptib;
         PMMFENTRY      pmmfe;

// is handle valid for this thread ?
if (pmmf != _locateMMFHandler())
   return;

// try to initialize
if (!fInitialized)
   {
   printf( "MMF: DUMP: not initialized\n");
   return;
   }

DosGetInfoBlocks( &ptib,&ppib);
printf( "MMF: DUMP entries for pid %u tid: %u:\n"
        "-------------------------------------\n",
        ppib->pib_ulpid, ptib->tib_ptib2->tib2_ultid);
for(i = 0; i < pmmf->ulEntryCount; i++)
   {
      pmmfe = pmmf->apmmfentry + i;
   if (pmmfe->ulFlags & MMF_USEDENTRY)
      {
      pszType = (pmmfe->hfile == NULLHANDLE) ? "<MEMORY>" : pmmfe->szFile;
      printf( "%u: memory at %p size %u: type: %s\n",
              i, pmmfe->pvData, pmmfe->ulSize, pszType);
      ulCount++;
      }
   }
printf( "%u entries \n\n", ulCount);
return;
}
#endif

// -----------------------------------------------------------------------------

static VOID _initialize( VOID)
{
do
   {
   if (fInitialized)
      break;

   // init handle table
   memset( apmmf, 0, sizeof( apmmf));

   // we're done
   fInitialized = TRUE;

   } while (FALSE);

return;
}

// #############################################################################

APIRET MmfInitialize( PHMMF phmmf, ULONG ulMaxBuffer)
{

         APIRET         rc = NO_ERROR;
         PMMF           pmmfCheck;
         PMMF           pmmf = NULL;
do
   {
   // check parms
   if (!phmmf)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // setup
   _initialize();

   // if a handlerr is already registered, break with error
   pmmfCheck = _locateMMFHandler();
   if (pmmfCheck)
      {
      DPRINTF_ALLOCACTION(( "MMF: initialize: handler already for pid %u tid %u\n",
                            pmmfCheck->pid, pmmfCheck->Tid));
      rc = ERROR_ACCESS_DENIED;
      break;
      }

   // --------------------------------------------------------

   // create a new entry
   pmmf = _createNewMMFHandler( ulMaxBuffer);
   if (!pmmf)
      break;

   // report pointer as handle
   *phmmf = (HMMF) pmmf;

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET MmfTerminate( HMMF hmmf)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;

do
   {
   // check parms
   if (!hmmf)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // destroy handler
   rc = _destroyMMFHandler( pmmf);
   } while (FALSE);

// cleanup
return rc;
}

// -----------------------------------------------------------------------------

APIRET MmfAlloc( HMMF hmmf, PVOID *ppvdata, PSZ pszFilename, ULONG ulOpenFlags, ULONG ulMaxSize)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;

         ULONG          ulAction;
         ULONG          fsOpenFlags;
         ULONG          fsOpenMode;

         HFILE          hfile = NULLHANDLE;
         ULONG          ulCurrentSize = 0;
         PVOID          pvData = NULL;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if ((!hmmf)    ||
       (!ppvdata) ||
       (!ulMaxSize))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // is handle valid for this thread ?
   if (pmmf != _locateMMFHandler())
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   // adapt open mode and open flags
   switch (ulOpenFlags & MMF_MASK_ACCESS)
      {
      case MMF_ACCESS_READONLY:  fsOpenMode = OPEN_ACCESS_READONLY  | OPEN_SHARE_DENYWRITE;     break;
      case MMF_ACCESS_WRITEONLY: fsOpenMode = OPEN_ACCESS_WRITEONLY | OPEN_SHARE_DENYWRITE;     break;
      case MMF_ACCESS_READWRITE: fsOpenMode = OPEN_ACCESS_READWRITE | OPEN_SHARE_DENYREADWRITE; break;
      }

   switch (ulOpenFlags & MMF_MASK_OPENMODE)
      {
      case MMF_OPENMODE_OPENFILE:  fsOpenFlags = OPEN_ACTION_OPEN_IF_EXISTS;    break;
      case MMF_OPENMODE_RESETFILE: fsOpenFlags = OPEN_ACTION_REPLACE_IF_EXISTS; break;

      default:
         rc = ERROR_INVALID_PARAMETER;
         break;
      }
   if (rc != NO_ERROR)
      break;


   // locate free entry in table
   pmmfe = _locateFreeMMFEntry( pmmf);
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

      // open file
      rc = DosOpen( pszFilename,
                    &hfile,
                    &ulAction,
                    0L,
                    FILE_ARCHIVED | FILE_NORMAL,
                    OPEN_ACTION_CREATE_IF_NEW | fsOpenFlags,
                    OPEN_FLAGS_NOINHERIT | OPEN_FLAGS_FAIL_ON_ERROR | fsOpenMode,
                    NULL);
      if (rc != NO_ERROR)
         return rc;

      } // if ((pszFilename) && (*pszFilename))


   // allocate memory for the file
   rc = DosAllocMem( &pvData, ulMaxSize, PAG_READ | PAG_WRITE);
   if (rc != NO_ERROR)
      break;
   DPRINTF_ALLOCACTION(( "MMF: ALLOCATE 0x%08p (0x%08p)\n", pvData, ulMaxSize));

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

APIRET MmfFree(  HMMF hmmf, PVOID pvData)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if (!pvData)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // is handle valid for this thread ?
   if (pmmf != _locateMMFHandler())
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }


   // search entry
   pmmfe = _locateMMFEntry( pmmf, pvData);
   if (!pmmfe)
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }

   // cleanup all data related to the file
   if( pmmfe->hfile)  DosClose( pmmfe->hfile);
   if (pmmfe->pvData)
      {
      rc = DosFreeMem( pmmfe->pvData);
      DPRINTF_ALLOCACTION(( "MMF: FREE 0x%08p (0x%08p) rc=%u\n", pmmfe->pvData,  pmmfe->ulSize, rc));
      }
   memset( pmmfe, 0, sizeof( MMFENTRY));

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET MmfUpdate(  HMMF hmmf, PVOID pvData)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;
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

   // is handle valid for this thread ?
   if (pmmf != _locateMMFHandler())
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }


   // search entry
   pmmfe = _locateMMFEntry( pmmf, pvData);
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

APIRET MmfSetSize(  HMMF hmmf, PVOID pvData, ULONG ulNewSize)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;
         PMMFENTRY      pmmfe;

do
   {
   // check parms
   if (!pvData)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // is handle valid for this thread ?
   if (pmmf != _locateMMFHandler())
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }


   // search entry
   pmmfe = _locateMMFEntry( pmmf, pvData);
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

APIRET MmfQuerySize(  HMMF hmmf, PVOID pvData, PULONG pulSize)
{
         APIRET         rc = NO_ERROR;
         PMMF           pmmf = (PMMF) hmmf;
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

   // is handle valid for this thread ?
   if (pmmf != _locateMMFHandler())
      {
      rc = ERROR_INVALID_HANDLE;
      break;
      }


   // search entry
   pmmfe = _locateMMFEntry( pmmf, pvData);
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

