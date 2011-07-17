/****************************** Module Header *******************************
*
* Module Name: mode.h
*
* Header for generic routines to support extended syntax hilighting
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

#ifndef MODE_H
#define MODE_H

typedef struct _MODEINFO
   {
         PSZ            pszModeName;
         PSZ            pszDefExtensions;
         PSZ            pszDefNames;
         ULONG          ulModeFlags;
   } MODEINFO, *PMODEINFO;

#define MODEINFO_CASESENSITIVE     0x00000001
#define MODEINFO_EXTENSIONS        0x00000010
#define MODEINFO_NAMES             0x00000020

// prototypes
APIRET QueryFileModeInfo( PSZ pszFilename, PMODEINFO pmi, ULONG ulBuflen);
APIRET QueryFileModeList( PSZ pszBuffer, ULONG ulBuflen);

#endif // MODE_H

