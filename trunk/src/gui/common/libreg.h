/****************************** Module Header *******************************
*
* Module Name: libreg.h
*
* Header for generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libreg.h,v 1.4 2002-09-13 19:34:23 cla Exp $
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

#ifndef LIBREG_H
#define LIBREG_H

typedef LHANDLE HCONFIG;
typedef HCONFIG *PHCONFIG;

APIRET OpenConfig( PHCONFIG phconfig, PSZ pszFilename);
APIRET CloseConfig( HCONFIG hconfig);

APIRET WriteConfigValue( HCONFIG hconfig, PSZ pszValuePath, PSZ pszValue);
APIRET QueryConfigValue( HCONFIG hconfig, PSZ pszValuePath, PSZ pszBuffer, ULONG ulBuflen);
APIRET DeleteConfigValue( HCONFIG hconfig, PSZ pszValuePath);

#endif // LIBREG_H

