/****************************** Module Header *******************************
*
* Module Name: eas.h
*
* Header for generic routines for accessing simple string extended attributes
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

#ifndef EAS_H
#define EAS_H

typedef struct _EAMVMT
   {
         USHORT         usType;
         USHORT         usCodepage;
         USHORT         usEntries;
         USHORT         usEntryType;
         USHORT         usEntryLen;
         CHAR           chEntry[1];
   } EAMVMT, *PEAMVMT;

typedef struct _EASVST
   {
         USHORT         usType;
         USHORT         usEntryLen;
         CHAR           chEntry[1];
   } EASVST, *PEASVST;

// prototypes
APIRET WriteStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszEaValue);
APIRET QueryStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszBuffer, PULONG ulBuflen);

#endif // EAS_H

