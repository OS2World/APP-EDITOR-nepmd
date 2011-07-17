/****************************** Module Header *******************************
*
* Module Name: dde.h
*
* Header for routines to connect to existing EPM windows and query the loaded
* files via DDE.
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

#ifndef DDE_H
#define DDE_H

#define SERVER_DISCONNECTED  NULLHANDLE

// prototypes
BOOL ConnectToEPM( HWND hwnd);
BOOL DisconnectFromEPM( HWND hwnd);
BOOL ConnectedToEPM( HWND hwnd);
BOOL ExecuteEPMCommand( HWND hwnd, PSZ pszCommand);
ULONG GetEPMServerIndex( HWND hwnd, HWND hwndServer);

MRESULT EXPENTRY DdeWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);

#endif // DDE_H

