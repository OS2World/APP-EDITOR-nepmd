/****************************** Module Header *******************************
*
* Module Name: ddelog.c
*
* Routines to load the errant file of a compile into EPM via DDE
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ddelog.c,v 1.4 2002-06-09 17:08:03 cla Exp $
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

// struct for error info

typedef struct _ERRORINFO
   {
         CHAR           szErrorFile[ _MAX_PATH];
         ULONG          ulLine;
         ULONG          ulCol;
         CHAR           szErrorMsg[ 128];
   } ERRORINFO, *PERRORINFO;

// structure for data of object window

typedef struct _LOADLOGDATA
    {
         PSZ            pszLogFile;                  // provided by caller
         PSZ            pszMacroFile;                // provided by caller
         ERRORINFO      ei;                          // extraced by _extractErrorInfo()
         BOOL           fSecondTry;
         APIRET         rc;                          // for returning a reason code to ReloadFilelist
         HWND           hwndServer;
         HWND           ahwndServer[ MAX_EPM_CLIENTS];
         ULONG          ulServerCount;

    } LOADLOGDATA, *PLOADLOGDATA;

// ----------------------------------------------------------------------

static PSZ _stripblanks( PSZ string)
{
 PSZ p = string;
 if (p != NULL)
    {
    while ((*p != 0) && (*p <= 32))
       { p++;}
    strcpy( string, p);
    }
 if (*p != 0)
    {
    p += strlen(p) - 1;
    while ((*p <= 32) && (p >= string))
       {
       *p = 0;
       p--;
       }
    }

return string;
}

// ---------------------------------------------------------------------

static BOOL _logConnectedToEPM( HWND hwnd)
{
         PLOADLOGDATA    plld = (PLOADLOGDATA) WinQueryWindowULong( hwnd, QWL_USER);

#if DEBUG_DDE_MESSAGES
   DPRINTF(( "DDELOG: check connected server: %u\n", plld->ulServerCount));
#endif
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
#else
   DPRINTF(( "DDELOG: execute command: %s\n", pszCommand));
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
      sprintf( szCommand, "start /F EPM \"%s\"", plld->ei.szErrorFile);
      sprintf( &szCommand[ strlen( szCommand)] ,
               " 'MC ;link %s;recomp SETPOS %u %u %u %u;'",
               plld->pszMacroFile,
               plld->ei.ulLine,
               plld->ei.ulCol,
               plld->ei.ulCol,
               plld->ei.ulCol + 1);
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
         WinAlarm( HWND_DESKTOP, WA_ERROR);
         ABORT_LOADING;
         break;
         }

      // execute macro to set error message separately, so that we can
      // use all kinds of quotes !
      sprintf( szCommand, "sayerror %s", plld->ei.szErrorMsg);
      if (!_logExecuteEPMCommand( hwnd, plld->hwndServer, szCommand))
         {
         WinAlarm( HWND_DESKTOP, WA_ERROR);
         ABORT_LOADING;
         }

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
         // also save list for later cleanup
         plld->ahwndServer[ plld->ulServerCount] = hwndServer;
         plld->ulServerCount++;

#if DEBUG_DDE_MESSAGES
         DPRINTF(( "DDELOG: INITIATE acknowledged by %08x\n", hwndServer));
#endif

         // save server handle - first connected is the one we need
         plld->hwndServer = plld->ahwndServer[ 0];
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

      if (!plld->fSecondTry)
         {
         // send command a second time after waiting a while
         DosSleep( RELOAD_WAITPERIOD);
         sprintf( szCommand, "sayerror %s", plld->ei.szErrorMsg);
         if (!_logExecuteEPMCommand( hwnd, plld->hwndServer, szCommand))
            {
            WinAlarm( HWND_DESKTOP, WA_ERROR);
            ABORT_LOADING;
            }
         else
            plld->fSecondTry = TRUE;
         }

      // we are done
      ABORT_LOADING;

      return (MRESULT) TRUE;
      }

   } // end switch (msg)

return WinDefWindowProc( hwnd, msg, mp1, mp2);
}

// -----------------------------------------------------------------------------

static APIRET _extractErrorInfo( PSZ pszLogFile, PERRORINFO pei)
{
         APIRET         rc = NO_ERROR;
         FILE          *pfile = NULL;
         ULONG          i;

         CHAR           szLine[ 128];

         BOOL           fErrorOccurred = FALSE;
         BOOL           fErrorMsgMessageRead = FALSE;
         BOOL           fDataComplete = FALSE;

static   PSZ            pszValidLineToken = ETPMLOG_VALIDLINETOKEN;
         ULONG          ulValidLineTokenLen = strlen( pszValidLineToken);
static   PSZ            pszFilenameToken = ETPMLOG_FILENAMETOKEN;
         ULONG          ulFilenameTokenLen = strlen( pszFilenameToken);
static   PSZ            pszLineToken = ETPMLOG_LINETOKEN;
         ULONG          ulLineTokenLen = strlen( pszLineToken);
static   PSZ            pszColToken = ETPMLOG_COLTOKEN;
         ULONG          ulColTokenLen = strlen( pszColToken);

do
   {
   // check parms
   if ((!pszLogFile)   ||
       (!*pszLogFile)  ||
       (!pei))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // init values
   memset( pei, 0, sizeof( ERRORINFO));

   // open logfile for read
   pfile = fopen( pszLogFile, "r");
   if (!pfile)
      {
      rc = ERROR_OPEN_FAILED;
      break;
      }

   // read first three lines - no further content checking
   for (i = 0; i < ETPMLOG_HEADERLINECOUNT; i++)
      {
      // header lines must be readable
      if (!fgets( szLine, sizeof( szLine), pfile))
         {
         fErrorOccurred = TRUE;
         break;
         }
      }

   // header lines not there ? error !
   if (fErrorOccurred)
      {
      rc = ERROR_INVALID_DATA;
      break;
      }

   while (fgets( szLine, sizeof( szLine), pfile))
      {
      // remoe nerline char
      szLine[ strlen( szLine) - 1] = 0;

      // skip empty lines
      if (szLine[ 0] == 0)
         continue;

      // proceed to error message here
      if (!fErrorMsgMessageRead)
         {
         // skip valid lines reporting included files
         if (!strncmp( szLine, pszValidLineToken, ulValidLineTokenLen))
            continue;
         else
            {
            // take first non-valid line as error message
            sprintf( pei->szErrorMsg, "%s: %s", __APPNAME__, szLine);
            fErrorMsgMessageRead = TRUE;
            }
         }

      // check for error information here
      if (!strncmp( szLine, pszFilenameToken, ulFilenameTokenLen))
         {
         // copy filename and remove trailing blanks
         strcpy( pei->szErrorFile, &szLine[ ulFilenameTokenLen]);
         _stripblanks( pei->szErrorFile);
         }
      else if (!strncmp( szLine, pszLineToken, ulLineTokenLen))
         // store errant line
         pei->ulLine = atol( &szLine[ ulLineTokenLen]);
      else if (!strncmp( szLine, pszColToken, ulColTokenLen))
         {
         // store column of error and break here - everything complete
         pei->ulCol = atol( &szLine[ ulColTokenLen]);
         fDataComplete = TRUE;
         break;
         }

      }  // while (fgets( szLine, sizeof( szLine), pfile))

   // all info received ? if not, load logfile itsef
   // because compile was successful
   if (!fDataComplete)
      {
      strcpy( pei->szErrorFile, pszLogFile);
      pei->ulLine = 1;
      pei->ulCol = 1;
      sprintf( pei->szErrorMsg, "%s: compile successful", __APPNAME__);
      break;
      }

   } while (FALSE);

// cleaunp
if (pfile) fclose( pfile);
return rc;
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
       (!*pszLogFile))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // setup required information
   lld.pszLogFile   = pszLogFile;
   lld.pszMacroFile = pszMacroFile;
   rc = _extractErrorInfo( pszLogFile, &lld.ei);
   if (rc != NO_ERROR)
      break;

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

