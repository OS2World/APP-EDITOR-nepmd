/****************************** Module Header *******************************
*
* Module Name: hilite.h
*
* Header for generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: hilite.h,v 1.2 2002-10-01 14:32:47 cla Exp $
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

#ifndef HILITE_H
#define HILITE_H

// prototypes
APIRET QueryHilightFile( PSZ pszEpmMode, PBOOL pfReload, PSZ pszBuffer, ULONG ulBuflen);

#endif // HILITE_H

