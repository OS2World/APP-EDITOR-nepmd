/****************************** Module Header *******************************
*
* Module Name: instval.h
*
* Header for generic routine to determine installation values
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: instval.h,v 1.1 2002-08-22 15:02:29 cla Exp $
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

#ifndef INSTVAL_H
#define INSTVAL_H

APIRET GetInstValue( PSZ pszFileTag, PSZ pszBuffer, ULONG ulBuflen);

#endif // INSTVAL_H

