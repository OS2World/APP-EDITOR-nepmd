/****************************** Module Header *******************************
*
* Module Name: ddereload.c
*
* Routines to reload files into EPM via DDE.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ddereload.c,v 1.2 2002-06-04 22:38:52 cla Exp $
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

// disable debug messages for this module
// #undef DEBUG

// specify zero to to mask of basic DDE messages
#define DEBUG_DDE_MESSAGES 0

#include "common.h"
#include "macros.h"
#include "recomp.rch"

#include "ddereload.h"
#include "ddeutil.h"
#include "client.h"
#include "pmres.h"
#include "job.h"
#include "file.h"


// -----------------------------------------------------------------------------

#define WM_USER_LOADNEXTFILE (WM_USER + 0x3000)

static   PSZ            pszDdeAppname          = "EPM";
static   PSZ            pszDdeTopicEdit        = "EDIT";
static   PSZ            pszDdeTopicEditCommand = "EDIT_COMMAND";

#define ABORT_LOADING  { WinPostMsg( hwnd, WM_QUIT, 0, 0); break; }

// -----------------------------------------------------------------------------

// structure for data of object window

typedef struct _RELOADDATA
    {
         PSZ            pszMacroFile;                // provided by caller of ReloadFilelist for setting curpos
         PSZ           *ppszFileList;                // holds an array of filelist data from recomp.e
         ULONG          ulFileCount;                 // number of files
         ULONG          ulListIndex;                 // index offile list (EPM ring)
         APIRET         rc;                          // for returning a reason code to ReloadFilelist
         HWND           hwndServer;                  // handle of server
         ULONG          ulAckCount;                  // see handling of WM_DDE_ACK below
         ULONG          ulFilesLoaded;               // file count to be reported to caller of ReloadFilelist

    } RELOADDATA, *PRELOADDATA;

// ---------------------------------------------------------------------

static BOOL _reloadConnectedToEPM( HWND hwnd)
{
         PRELOADDATA    prd = (PRELOADDATA) WinQueryWindowULong( hwnd, QWL_USER);

return (prd->hwndServer > 0);
}

// ---------------------------------------------------------------------

static BOOL _reloadConnectToEPM( HWND hwnd)
{
         BOOL           fResult = FALSE;
         CONVCONTEXT    cc;

do
   {
   // send initiate
#if DEBUG_DDE_MESSAGES
   DPRINTF(( "DDERELOAD: initiate to %s - %s\n", pszDdeAppname, pszDdeTopicEdit));
#endif

   memset( &cc, 0, sizeof(CONVCONTEXT));
   cc.cb = sizeof(CONVCONTEXT);
   fResult = WinDdeInitiate( hwnd, pszDdeAppname, pszDdeTopicEdit, &cc);
   DPRINTF(( "DDERELOAD: initiate complete, result: %u\n", fResult));
   if (!fResult)
      break;

   // check if connected
   fResult = _reloadConnectedToEPM( hwnd);

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------

static BOOL _reloadExecuteEPMCommand( HWND hwnd, HWND hwndServer, PSZ pszCommand)
{
         BOOL           fResult = FALSE;
         PDDESTRUCT     pDdeStruct = NULL;
do
   {
   // check parms
   if ((!pszCommand) ||
       (!*pszCommand))
      break;

   // create shared memory segment
   pDdeStruct = MakeDDEMsg( DDEFMT_TEXT, pszDdeTopicEditCommand,
                            pszCommand, strlen( pszCommand) + 1);

   // send command
#if DEBUG_DDE_MESSAGES
   DPRINTF(( "DDERELOAD: execute command on server %08x: %s\n", hwndServer, pszCommand));
#endif
   fResult = WinDdePostMsg( hwndServer, hwnd, WM_DDE_EXECUTE, pDdeStruct, TRUE);

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------
// in: <filename>|<curpos>

static BOOL _extractFileDescription( PSZ pszFileList, PSZ pszBufFilename, ULONG ulBuflenFilename,
                                     PSZ pszBufCurPos, ULONG ulBuflenCurPos)
{
         BOOL           fResult = FALSE;
         PSZ            pszCurPos;
         BOOL           fEndOfList = FALSE;

do
   {
   // check parms
   if ((!pszFileList)        ||
       (!*pszFileList)       ||
       (!pszBufFilename)     ||
       (!ulBuflenFilename)   ||
       (!pszBufCurPos)       ||
       (!ulBuflenCurPos))
      break;

      *pszBufFilename = 0;
      *pszBufCurPos   = 0;

      // check for next field
      pszCurPos = strchr( pszFileList, FILE_DELIMITER);
      if (!pszCurPos)
         break;
      pszCurPos++;

      // check len of buffers
      if (pszCurPos - pszFileList > ulBuflenFilename)
         break;
      if (strlen( pszCurPos) > ulBuflenCurPos)
         break;

      // copy strings
      *(pszCurPos - 1) = 0;
      strcpy( pszBufFilename, pszFileList);
      strcpy( pszBufCurPos, pszCurPos);

   // done
   fResult = TRUE;

   } while (FALSE);

return fResult;

}

// ---------------------------------------------------------------------

static MRESULT EXPENTRY DdeReloadWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
         PRELOADDATA    prd = (PRELOADDATA) WinQueryWindowULong( hwnd, QWL_USER);

         BOOL           fResult;
         ULONG          i;
         ULONG          ulTries;
         PSZ            pszFileInfo;
         CHAR           szFilename[ _MAX_PATH];
         CHAR           szCurPos[ 32];

         CHAR           szCommand[ _MAX_PATH + 64];

switch (msg)
   {

   case WM_CREATE:
      // store pointer to reloaddata
      prd = (PRELOADDATA) PVOIDFROMMP( mp1);
      if (!WinSetWindowPtr( hwnd, QWL_USER, prd))
         {
         prd->rc = LASTERROR;
         WinPostMsg( hwnd, WM_QUIT, 0, 0);
         break;
         }

      // set error code anyway - will be reset if all files could be loaded
      prd->rc = ERROR_INVALID_FUNCTION;

      // get filename of first file
      pszFileInfo = prd->ppszFileList[ prd->ulFilesLoaded];
      fResult = _extractFileDescription( pszFileInfo,
                                         szFilename, sizeof( szFilename),
                                         szCurPos, sizeof( szCurPos));
      if (!fResult)
         {
         // no valid description found
         prd->rc = ERROR_INVALID_DATA;
         WinPostMsg( hwnd, WM_QUIT, 0, 0);
         break;
         }

      // load EPM with first file, but call macro separately
      // (otherwise it will not work if only one file loaded)
      prd->ulFilesLoaded = 1;
      sprintf( szCommand, "start /F EPM \"%s\"", szFilename);
      DPRINTF(( "DDERELOAD: start EPM with: %s\n", szCommand));

      // connect to that instance
      for (ulTries = 0; ulTries < RELOAD_MAXTRIES; ulTries++)
         {

                  BOOL           fConnected = FALSE;

         // start EPM
         DPRINTF(( "DDERELOAD: starting EPM instance - %u of %u tries\n", ulTries + 1, RELOAD_MAXTRIES));
         system( szCommand);
         DosSleep( RELOAD_WAITPERIOD);

         // connect to it
         for (i = 0; i < RELOAD_MAXTWAITPERTRY; i++)
            {
            // is EPM there ?
            fConnected = _reloadConnectToEPM( hwnd);
            if (fConnected)
               break;
            else
               DosSleep( RELOAD_WAITPERIOD);
            }

         // no more tries if connected
         if (fConnected)
            break;
         }

      // not connected ? then give up here
      if (!_reloadConnectedToEPM( hwnd))
         {
         // no EPM connected, bail out
         WinPostMsg( hwnd, WM_QUIT, 0, 0);
         break;
         }

      // count started EPM as first acknowledge
      prd->ulAckCount++;

      // execute macro separately. This triggers also load of next file
      DPRINTF(( "DDERELOAD: list %u, file %u: %s (%s)\n", prd->ulListIndex + 1,
                prd->ulFilesLoaded, szFilename, szCurPos));
      sprintf( szCommand, "MC ;link %s;recomp SETPOS %s;", prd->pszMacroFile, szCurPos);
      if (!_reloadExecuteEPMCommand( hwnd, prd->hwndServer, szCommand))
         ABORT_LOADING;

      break;

   // ---------------------------------------------------------------

   case WM_USER_LOADNEXTFILE:

      // end of list ? then we are done
      if (prd->ulFilesLoaded >= prd->ulFileCount)
         {
         DPRINTF(( "DDERELOAD: no more files in list\n"));

         prd->rc = NO_ERROR;
         ABORT_LOADING;
         }

      // get filename of next file
      pszFileInfo = prd->ppszFileList[ prd->ulFilesLoaded];
      fResult = _extractFileDescription( pszFileInfo,
                                         szFilename, sizeof( szFilename),
                                         szCurPos, sizeof( szCurPos));

      // increase file counter
      prd->ulFilesLoaded++;

      // load next file and take care for position
      DPRINTF(( "DDERELOAD: list %u, file %u: %s (%s)\n", prd->ulListIndex + 1,
                prd->ulFilesLoaded, szFilename, szCurPos));
      sprintf( szCommand, "MC ;EDIT \"%s\";link %s;recomp SETPOS %s;", szFilename, prd->pszMacroFile, szCurPos);
      if (!_reloadExecuteEPMCommand( hwnd, prd->hwndServer, szCommand))
         ABORT_LOADING;

      break;

   // ---------------------------------------------------------------

   case WM_DDE_INITIATEACK:
      {
               ULONG          i;
               HWND           hwndServer = (HWND)mp1;
               PDDEINIT       pDdeInit   = (PDDEINIT)mp2;

      if ((!strcmp( pDdeInit->pszAppName, pszDdeAppname)) &&
          (!strcmp( pDdeInit->pszTopic,   pszDdeTopicEdit)))
         {

         // save server handle
         prd->hwndServer = hwndServer;

#if DEBUG_DDE_MESSAGES
         DPRINTF(( "DDERELOAD: INITIATE acknowledged by %08x\n", hwndServer));
#endif
         }
      }
      break;

   // ---------------------------------------------------------------

   case WM_DDE_ACK:
      {
               HWND           hwndServer = (HWND)mp1;
               PDDESTRUCT     pdde = (PDDESTRUCT)mp2;

#if DEBUG_DDE_MESSAGES
      DPRINTF(( "DDERELOAD: ACK from server %08x, size is: %u\n", hwndServer,  pdde->cbData));
#endif
      DosFreeMem( pdde);

      // count up acknowledge count
      prd->ulAckCount++;

      // next file
      WinPostMsg( hwnd, WM_USER_LOADNEXTFILE, 0, 0);

      return (MRESULT) TRUE;
      }


   } // end switch (msg)

return WinDefWindowProc( hwnd, msg, mp1, mp2);
}

// -----------------------------------------------------------------------------

APIRET ReloadFilelist( HWND hwnd, ULONG ulListIndex, PSZ *ppszFileList, ULONG ulFileCount,
                       PSZ pszMacroFile, BOOL fTerminate, PULONG pulFilesLoaded)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

         HAB            hab = CURRENTHAB;
         QMSG           qmsg;

         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);
         RELOADDATA     rd;

         PSZ            pszObjectWindowClass = "RECOMP_RELOADEPM";
         HWND           hwndObject = NULLHANDLE;

// This array to server handles is for to handle a BUG within the DDE support of EPM
//
//   When connections to multiple windows are opened, termination
//   of one DDE connection will cause the DDE connections to all other
//   windows to fail on subsequent posts.
//
//   As a workaround handles to all servers are stored here
//   and all terminated when the last connection is not longer
//   required. It is to be initialized when ReloadFilelist is
//   called for opening the first connection

static   HWND           ahwndServer[ MAX_EPM_CLIENTS];
static   ULONG          ulServerCount;


do
   {
   // init structure here for proper cleanup
   memset( &rd, 0, sizeof( rd));

   // check parms
   if ((!hwnd)         ||
       (!ppszFileList) ||
       (!ulFileCount))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }


   // now create object window for handling the start of EPM instance
   // hand over a copy of the filelist string getting tokenized
   rd.pszMacroFile = pszMacroFile;
   rd.ulListIndex  = ulListIndex;
   rd.ppszFileList = ppszFileList;
   rd.ulFileCount  = ulFileCount;

   // create object window to send request here
   if (!WinRegisterClass( CURRENTHAB, pszObjectWindowClass,
                          DdeReloadWindowProc, 0, sizeof( ULONG)))
      {
      rc = LASTERROR;
      break;
      }

   hwndObject = WinCreateWindow( HWND_OBJECT,
                                 pszObjectWindowClass,
                                 NULL, 0, 0, 0, 0, 0,
                                 HWND_OBJECT,
                                 HWND_BOTTOM,
                                 0,
                                 &rd,
                                 NULL);

   if (hwndObject == NULLHANDLE)
      {
      rc = LASTERROR;
      break;
      }

   // process object window
   while (WinGetMsg( hab, &qmsg, NULLHANDLE, 0, 0))
        WinDispatchMsg ( hab, &qmsg);

   // destroy window (takse care for proper disconnection)
   WinDestroyWindow( hwndObject);

   if (rd.hwndServer)
      {
      // save hwnd server here and terminate DDE connection only after
      // last connection is to be terminated, see also comment on top
      // of this file
      if (!ulListIndex)
         {
         // initialize when called for very first filelist
         memset( ahwndServer, 0, sizeof( ahwndServer));
         ulServerCount = 0;
         }
      // save handle of last connection
      ahwndServer[ ulServerCount] = rd.hwndServer;
      ulServerCount++;
      if (fTerminate)
         {
         for (i = 0; i < ulServerCount; i++)
            {
#if DEBUG_DDE_MESSAGES
            DPRINTF(( "DDERELOAD: terminate connection to server %08x\n", ahwndServer[ i]));
#endif
            WinDdePostMsg( ahwndServer[ i], hwnd, WM_DDE_TERMINATE, NULL, 0);
            }
         }
      }

   // hand over filecount
   if (pulFilesLoaded)
      *pulFilesLoaded = rd.ulFilesLoaded;

   // return rc value determined by window code
   rc = rd.rc;

   } while (FALSE);

return rc;

}

