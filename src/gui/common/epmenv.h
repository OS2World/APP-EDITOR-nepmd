/****************************** Module Header *******************************
*
* Module Name: epmenv.h
*
* Header for generic routine to load the NEPMD environment file for
* EPM and NEPDM utilities
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmenv.h,v 1.3 2002-08-24 17:50:47 cla Exp $
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

#ifndef EPMENV_H
#define EPMENV_H

// pszBuffer is optional and receives the name
// of the original EPM executable
APIRET GetExtendedEPMEnvironment( PSZ envv[], PSZ *ppszNewEnv,
                                  PSZ pszBuffer, ULONG ulBuflen);

#endif // EPMENV_H

