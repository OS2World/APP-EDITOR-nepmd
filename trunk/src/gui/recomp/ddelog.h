/****************************** Module Header *******************************
*
* Module Name: ddelog.h
*
* Header for routines to load the errant file of a compile into EPM via DDE
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ddelog.h,v 1.2 2002-06-09 17:31:40 cla Exp $
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

#ifndef DDELOG_H
#define DDELOG_H

// prototypes
APIRET LoadErrantFileFromLog( HWND hwnd,  HMODULE hmodResource,
                              PSZ pszLogFile, PSZ pszMacroFile);

#endif // DDELOG_H

