/****************************** Module Header *******************************
*
* Module Name: pmres.h
*
* Header for generic functions to access PM resources.
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

#ifndef PMRES_H
#define PMRES_H

APIRET WriteResourceToFile( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ pszFile);
APIRET WriteResourceToTmpFile( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ pszTmpFile, ULONG ulBuflen);
APIRET GetStringResource( HMODULE hmodResource, ULONG ulResType, ULONG ulResId, PSZ *ppszBuffer);
ULONG ShowNlsError( HWND hwnd, HMODULE hmod, PSZ pszTitle, ULONG ulResId, ...);

#endif // PMRES_H

