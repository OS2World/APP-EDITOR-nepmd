/****************************** Module Header *******************************
*
* Module Name: dde.c
*
* Routines to connect to existing EPM windows and query the loaded
* files via DDE.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: dde.c,v 1.2 2002-08-16 22:18:08 cla Exp $
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
#undef DEBUG

#include "common.h"
#include "macros.h"


#include "dde.h"
#include "ddeutil.h"
#include "client.h"
#include "job.h"

// ---------------------------------------------------------------------

static   PSZ            pszDdeAppname          = "EPM";
static   PSZ            pszDdeTopicEdit        = "EDIT";
static   PSZ            pszDdeTopicEditCommand = "EDIT_COMMAND";

// ---------------------------------------------------------------------

BOOL ExecuteEPMCommand( HWND hwnd, PSZ pszCommand)
{
         BOOL           fResult = FALSE;
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);
         ULONG          i;
         PDDESTRUCT     pDdeStruct = NULL;
         HWND           hwndServer;
do
   {
   // check parms
   if ((!pszCommand) ||
       (!*pszCommand))
      break;


   // execute command
   for (i = 0; i < pwd->ulServerCount; i++)
      {
      hwndServer = pwd->ahwndServer[ i];

      // skip servers already disconnected
      if (hwndServer == SERVER_DISCONNECTED)
         continue;

      // create shared memory segment
      pDdeStruct = MakeDDEMsg( DDEFMT_TEXT, pszDdeTopicEditCommand,
                               pszCommand, strlen( pszCommand) + 1);

      // send it
      DPRINTF(( "DDE: execute command on server %08x: %s\n", hwndServer, pszCommand));
      fResult = WinDdePostMsg( hwndServer, hwnd, WM_DDE_EXECUTE, pDdeStruct, TRUE);

      }

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------

BOOL ConnectedToEPM( HWND hwnd)
{
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

return (pwd->ulConnectCount > 0);
}

// ---------------------------------------------------------------------

BOOL ConnectToEPM( HWND hwnd)
{
         BOOL           fResult = FALSE;
         CONVCONTEXT    cc;

do
   {
   // send initiate
   DPRINTF(( "DDE: initiate to %s - %s\n", pszDdeAppname, pszDdeTopicEdit));
   memset( &cc, 0, sizeof(CONVCONTEXT));
   cc.cb = sizeof(CONVCONTEXT);
   fResult = WinDdeInitiate( hwnd, pszDdeAppname, pszDdeTopicEdit, &cc);
   if (!fResult)
      break;

   // check if connected
   fResult = ConnectedToEPM( hwnd);

   } while (FALSE);

return fResult;
}

// ---------------------------------------------------------------------

BOOL DisconnectFromEPM( HWND hwnd)
{
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);
         ULONG          i;


// close connections
for (i = 0; i < pwd->ulServerCount; i++)
   {

   // skip servers already disconnected
   if (pwd->ahwndServer[ i] == SERVER_DISCONNECTED)
      continue;

   // terminate this connection
   DPRINTF(( "DDE: terminate connection to server %08x\n", pwd->ahwndServer[ i]));
   WinDdePostMsg( pwd->ahwndServer[ i], hwnd, WM_DDE_TERMINATE, NULL, 0);
   }

// reset data - do not reset file lists !!!
memset( pwd->ahwndServer, 0, sizeof( pwd->ahwndServer));
pwd->ulServerCount = 0;
pwd->ulConnectCount = 0;

return TRUE;
}

// ---------------------------------------------------------------------

ULONG GetEPMServerIndex( HWND hwnd, HWND hwndServer)
{
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);
         ULONG          ulServerIndex = -1;
         ULONG          i;


// close connections
for (i = 0; i < pwd->ulServerCount; i++)
   {

   // skip servers already disconnected
   if (pwd->ahwndServer[ i] == SERVER_DISCONNECTED)
      continue;

   if (pwd->ahwndServer[ i] == hwndServer)
      ulServerIndex = i;
   }

return ulServerIndex;
}

// ---------------------------------------------------------------------

MRESULT EXPENTRY DdeWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
         MRESULT        mr = 0;
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

switch (msg)
   {

   // ---------------------------------------------------------------

   case WM_DDE_INITIATEACK:
      {
               ULONG          i;
               HWND           hwndServer = (HWND)mp1;
               PDDEINIT       pDdeInit   = (PDDEINIT)mp2;

      if ((!strcmp( pDdeInit->pszAppName, pszDdeAppname)) &&
          (!strcmp( pDdeInit->pszTopic,   pszDdeTopicEdit)))
         {

         // save connect status
         pwd->ahwndServer[ pwd->ulServerCount] = hwndServer;
         pwd->ulServerCount++;
         pwd->ulConnectCount++;

         DPRINTF(( "DDE: INITIATE acknowledged by %08x, currently connected: %u\n", hwndServer, pwd->ulConnectCount));
         }
      }
      break;

   // ---------------------------------------------------------------

   case WM_DDE_ACK:
      {
               HWND           hwndServer = (HWND)mp1;
               PDDESTRUCT     pdde = (PDDESTRUCT)mp2;

      DPRINTF(( "DDE: ACK from server %08x, size is: %u\n", hwndServer,  pdde->cbData));

      // update status
      UPDATE_JOB_STATUS;

      DosFreeMem( pdde);

      return (MRESULT) TRUE;
      }

   // ---------------------------------------------------------------

   case WM_DDE_DATA:
      {
               HWND           hwndServer = (HWND)mp1;
               PDDESTRUCT     pdde = (PDDESTRUCT)mp2;
               PSZ            pszItemName;
               PSZ            pszItemData;

               PSZ            pszData = NULL;

      if (pdde->usFormat != DDEFMT_TEXT)
         break;

      pszItemName  = ((PSZ) pdde + pdde->offszItemName);
      pszItemData  = ((PSZ) pdde + pdde->offabData);

      // create a copy of the return value
      pszData = strdup( pszItemData);
      if (pszData)
         DPRINTF(( "DDE: DATA from server %08x, len: %u, data: \"%s\"\n", hwndServer, strlen( pszData), pszData));
      else
         DPRINTF(( "DDE: DATA : not enough memory\n"));

      if (pdde->fsStatus == DDE_FACKREQ)
         {
         DPRINTF(( "DDE: SENDING DATA ACK\n"));
         WinDdePostMsg( hwndServer, hwnd, WM_DDE_ACK, pdde,TRUE);
         }
      else
         DosFreeMem( pdde);

      // update status
      UPDATE_JOB_STATUS_DATA( hwndServer, pszData);

      return (MRESULT) TRUE;
      }


   } // end switch (msg)

return mr;
}

