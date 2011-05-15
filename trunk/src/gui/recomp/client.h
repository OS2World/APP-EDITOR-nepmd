/****************************** Module Header *******************************
*
* Module Name: client.h
*
* Header for PM client related routines and structures.
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

#ifndef CLIENT_H
#define CLIENT_H

typedef struct _CONFIGDATA
   {
         ULONG          ulSig;
         ULONG          ulVersion;
         SWP            swp;
         BOOL           fDiscardUnsaved;
         BOOL           fReloadFiles;
         BOOL           fShowCompileLog;

   } CONFIGDATA, *PCONFIGDATA;

typedef struct _WINDOWDATA
   {
         CONFIGDATA     cd;
         APIRET         rc;

         // extended enviroment
         PSZ            pszEpmEnv;

         // main program control data
         BOOL           fAutoStart;
         BOOL           fSkipLog;
         HMODULE        hmodResource;
         BOOL           fLastConnected;

         // thread control
         TID            tidCompile;
         TID            tidReload;
         TID            tidLog;

         // EPM compile related
         CHAR           szCompilerExecutable[ _MAX_PATH];
         CHAR           szSourceFile[ _MAX_PATH];
         CHAR           szTargetDir[ _MAX_PATH];
         CHAR           szTargetFile[ _MAX_PATH];
         CHAR           szLogFile[ _MAX_PATH];
         BOOL           fCompileSuccessful;


         HWND           ahwndServer[ MAX_EPM_CLIENTS];
         ULONG          ulServerCount;
         ULONG          ulConnectCount;

         // job machine control
         ULONG          ulJobStatus;
         ULONG          ulStatusCount;
         ULONG          ulLastStatus;

         // vars used during job machine processing
         HWND           hwndFailedServer;
         BOOL           fExitProcessing;
         BOOL           fCompiled;
         CHAR           szMacroFile[ _MAX_PATH];

         PSZ           *appszFiles[ MAX_EPM_CLIENTS];
         ULONG          aulFileCount[ MAX_EPM_CLIENTS];
         ULONG          ulFileListIndex;

         // cars used for testing purposes only
         BOOL           fTestUseErrorSource;

   } WINDOWDATA, *PWINDOWDATA;

// private PM messages
#define WM_USER_ACTIVATE        (WM_USER + 0x1000)
#define WM_USER_UPDATE_STATS    (WM_USER + 0x1001)
#define WM_USER_JOBDONE         (WM_USER + 0x1002)
#define WM_USER_RESETITEMFONT   (WM_USER + 0x1003)

#define UPDATE_STATS WinSendMsg( hwnd, WM_USER_UPDATE_STATS, 0, 0)


MRESULT EXPENTRY ClientWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);

#endif // CLIENT_H

