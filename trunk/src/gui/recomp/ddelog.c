/****************************** Module Header *******************************
*
* Module Name: ddelog.c
*
* Routines to load the errant file of a compile into EPM via DDE
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ddelog.c,v 1.2 2002-06-08 23:48:31 cla Exp $
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
#include "file.h"


// -----------------------------------------------------------------------------

static   PSZ            pszDdeAppname          = "EPM";
static   PSZ            pszDdeTopicEdit        = "EDIT";
static   PSZ            pszDdeTopicEditCommand = "EDIT_COMMAND";

#define ABORT_LOADING  { WinPostMsg( hwnd, WM_QUIT, 0, 0); break; }

// -----------------------------------------------------------------------------

// structure for data of object window

typedef struct _LOADLOGDATA
    {
         PSZ            pszMacroFile;                // provided by caller of ReloadFilelist for setting curpos
         PSZ            pszLogFile;                  // provided by caller
         CHAR           szCurPos[ 32];               // extracted by LoadErrantFile()
         APIRET         rc;                          // for returning a reason code to ReloadFilelist
         HWND           hwndServer;
         HWND           ahwndServer[ MAX_EPM_CLIENTS];
         ULONG          ulServerCount;

    } LOADLOGDATA, *PLOADLOGDATA;

// ---------------------------------------------------------------------

static BOOL _logConnectedToEPM( HWND hwnd)
{
         PLOADLOGDATA    plld = (PLOADLOGDATA) WinQueryWindowULong( hwnd, QWL_USER);

return (plld->ulServerCount > 0);
}

// ---------------------------------------------------------------------

static BOOL _logConnectToEPM( HWND hwnd)
{
         BOOL           fResult = FALSE;
         CONVCONTEXT    cc;

do
   {
   // send initiate
#if DEBUG_DDE_MESSAGES
   DPRINTF(( "DDELOG: initiate to %s - %s\n", pszDdeAppname, pszDdeTopicEdit));
#endif

   memset( &cc, 0, sizeof( CONVCONTEXT));
   cc.cb = sizeof( CONVCONTEXT);
   fResult = WinDdeInitiate( hwnd, pszDdeAppname, pszDdeTopicEdit, &cc);
   DPRINTF(( "DDELOG: initiate complete, result: %u\n", fResult));
   if (!fResult)
      break;

   // check if connected
   fResult = _logConnectedToEPM( hwnd);

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------

static BOOL _logExecuteEPMCommand( HWND hwnd, HWND hwndServer, PSZ pszCommand)
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
   DPRINTF(( "DDELOG: execute command on server %08x: %s\n", hwndServer, pszCommand));
#endif
   fResult = WinDdePostMsg( hwndServer, hwnd, WM_DDE_EXECUTE, pDdeStruct, TRUE);

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------

static MRESULT EXPENTRY DdeLogWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
         PLOADLOGDATA   plld = (PLOADLOGDATA) WinQueryWindowULong( hwnd, QWL_USER);

         BOOL           fResult;
         ULONG          i;
         ULONG          ulTries;

         CHAR           szCommand[ _MAX_PATH + 64];

switch (msg)
   {

   case WM_CREATE:

      // store pointer to reloaddata
      plld = (PLOADLOGDATA) PVOIDFROMMP( mp1);
      if (!WinSetWindowPtr( hwnd, QWL_USER, plld))
         {
         plld->rc = LASTERROR;
         ABORT_LOADING;
         break;
         }

      // set error code anyway - will be reset if files can be loaded
      plld->rc = ERROR_INVALID_FUNCTION;

      // load EPM with the log file, but call macro separately
      // (otherwise it will not work if only one file loaded)
      sprintf( szCommand, "start /F EPM \"%s\"", plld->pszLogFile);
      DPRINTF(( "DDELOG: start EPM with: %s\n", szCommand));

      // connect to that instance
      for (ulTries = 0; ulTries < RELOAD_MAXTRIES; ulTries++)
         {

                  BOOL           fConnected = FALSE;

         // start EPM
         DPRINTF(( "DDELOG: starting EPM instance - %u of %u tries\n", ulTries + 1, RELOAD_MAXTRIES));
         system( szCommand);
         DosSleep( RELOAD_WAITPERIOD);

         // connect to it
         for (i = 0; i < RELOAD_MAXTWAITPERTRY; i++)
            {
            // is EPM there ?
            fConnected = _logConnectToEPM( hwnd);
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
      if (!_logConnectedToEPM( hwnd))
         {
         // no EPM connected, bail out
         ABORT_LOADING;
         break;
         }

      // execute macro separately. This triggers also end of processing
      sprintf( szCommand, "MC ;link %s;recomp SETPOS %s;", plld->pszMacroFile, plld->szCurPos);
      if (!_logExecuteEPMCommand( hwnd, plld->hwndServer, szCommand))
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

         // save server handle - first connected is the one we need
         plld->hwndServer = plld->ahwndServer[ 0];

         // also save list for later cleanup
         plld->ahwndServer[ plld->ulServerCount] = hwndServer;
         plld->ulServerCount++;

#if DEBUG_DDE_MESSAGES
         DPRINTF(( "DDELOG: INITIATE acknowledged by %08x\n", hwndServer));
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
      DPRINTF(( "DDELOG: ACK from server %08x, status is: 0x%04x\n", hwndServer,  pdde->fsStatus));
#endif
      DosFreeMem( pdde);

      // we are done
      ABORT_LOADING;

      return (MRESULT) TRUE;
      }

   } // end switch (msg)

return WinDefWindowProc( hwnd, msg, mp1, mp2);
}

// -----------------------------------------------------------------------------

APIRET LoadErrantFileFromLog( HWND hwnd, PSZ pszLogFile, PSZ pszMacroFile)
{
         APIRET         rc = NO_ERROR;
         ULONG          i,s;

         HAB            hab = CURRENTHAB;
         QMSG           qmsg;

         LOADLOGDATA    lld;

         PSZ            pszObjectWindowClass = "RECOMP_LOADLOG";
         HWND           hwndObject = NULLHANDLE;

         ULONG          ulCurX = 2;
         ULONG          ulCury = 4;

do
   {
   // init structure here for proper cleanup
   memset( &lld, 0, sizeof( lld));

   // check parms
   if ((!hwnd)         ||
       (!pszLogFile)   ||
       (!*pszLogFile)  ||
       (!pszMacroFile) ||
       (!*pszMacroFile ))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // now create object window for handling the start of EPM instance
   // hand over a copy of the filelist string getting tokenized
   lld.pszMacroFile = pszMacroFile;
   lld.pszLogFile   = pszLogFile;
   strcpy( lld.szCurPos, "2 2 2 3");
// sprintf( lld.szCurPos, "%u %u %u %u", ulCurX, ulCurX, ulCurX, ulCurX + 1);

   // create object window to send request here
   if (!WinRegisterClass( CURRENTHAB, pszObjectWindowClass,
                          DdeLogWindowProc, 0, sizeof( ULONG)))
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
                                 &lld,
                                 NULL);

   if (hwndObject == NULLHANDLE)
      {
      rc = LASTERROR;
      break;
      }

   // process object window
   while (WinGetMsg( hab, &qmsg, NULLHANDLE, 0, 0))
        WinDispatchMsg ( hab, &qmsg);

   // disconnect from any server connected before
   for (s = 0; s < lld.ulServerCount; s++)
      {
#if DEBUG_DDE_MESSAGES
      DPRINTF(( "DDELOG: terminate connection to server %08x\n", lld.ahwndServer[ s]));
#endif
      WinDdePostMsg( lld.ahwndServer[ s], hwndObject, WM_DDE_TERMINATE, NULL, 0);
      }

   // destroy window
   WinDestroyWindow( hwndObject);

   // return rc value determined by window code
   rc = lld.rc;

   } while (FALSE);

return rc;

}

