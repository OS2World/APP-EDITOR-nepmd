/****************************** Module Header *******************************
*
* Module Name: libreg.h
*
* Header for generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: libreg.h,v 1.2 2002-09-12 22:25:29 cla Exp $
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

APIRET WriteConfigValue( PSZ pszValuePath, PSZ pszValue);
APIRET QueryConfigValue( PSZ pszValuePath, PSZ pszBuffer, ULONG ulBuflen);
APIRET DeleteConfigValue( PSZ pszValuePath);

#endif // LIBREG_H

