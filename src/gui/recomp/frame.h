/****************************** Module Header *******************************
*
* Module Name: frame.h
*
* Header for PM frame related routines.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: frame.h,v 1.1 2002-06-03 22:27:06 cla Exp $
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

#ifndef FRAME_H
#define FRAME_H

APIRET ExecuteFrame( HAB hab, INT argc, PSZ  argv[]);
VOID ShowHelp( HWND hwndOwner, HMODULE hmodResource);

#endif // FRAME_H

