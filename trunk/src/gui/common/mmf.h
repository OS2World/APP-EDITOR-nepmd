/****************************** Module Header *******************************
*
* Module Name: mmf.h
*
* Header for generic routines for memory mapped files
*
* This code bases on the MMF library by Sergey I. Yevtushenko
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mmf.h,v 1.1 2002-09-24 16:47:57 cla Exp $
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

#ifndef  MMF_H
#define  MMF_H

/* flags for MmfAlloc parm ulOpenFlags                                       */
/* NOTE: for all except MMF_ACCESS_READWRITE, only write by others is denied */
/*       otherwise both read and write by others is denied                   */
#define MMF_ACCESS_READONLY     0x00000000
#define MMF_ACCESS_WRITEONLY    0x00000001
#define MMF_ACCESS_READWRITE    0x00000002

typedef LHANDLE HMMF, *PHMMF;

/* prototypes */
APIRET MmfAlloc( PVOID *ppvdata, PSZ pszFilename, ULONG ulOpenFlags, ULONG ulMaxSize);
APIRET MmfFree( PVOID pvData);
APIRET MmfUpdate( PVOID pvData);

APIRET MmfSetSize( PVOID pvData, ULONG ulNewSize);
APIRET MmfQuerySize( PVOID pvData, PULONG pulSize);

#endif /* MMF_H */

