/****************************** Module Header *******************************
*
* Module Name: tmf.h
*
* Header for text message file functions
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

#ifndef TMF_H
#define TMF_H

APIRET TmfGetMessage( PCHAR *pTable, ULONG cTable, PBYTE pbBuffer, ULONG cbBuffer,
                      PSZ pszMessageName, PSZ pszFile, PULONG pcbMsg);
#endif // TMF_H

