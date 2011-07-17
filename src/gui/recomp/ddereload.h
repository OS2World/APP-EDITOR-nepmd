/****************************** Module Header *******************************
*
* Module Name: ddereload.h
*
* Header for routines to reload files into EPM via DDE.
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

#ifndef DDERELOAD_H
#define DDERELOAD_H

// prototypes
APIRET ReloadFilelist( HWND hwnd, ULONG ulListIndex, PSZ *ppszFileList, ULONG ulFileCount,
                       PSZ pszExtMacroFile, BOOL fTerminate, PULONG pulFilesLoaded);

#endif // DDERELOAD_H

