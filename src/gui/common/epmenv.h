/****************************** Module Header *******************************
*
* Module Name: epmenv.h
*
* Header for generic routine to load the NEPMD environment file for
* EPM and NEPDM utilities
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

#ifndef EPMENV_H
#define EPMENV_H

// define filename extensions
#define NEPMD_FILENAMEEXT_ENV          ".env"

// define external env vars available in epm.env
#define ENV_NEPMD_LANGUAGE         "NEPMD_LANGUAGE"
#define ENV_NEPMD_ROOTDIR          "NEPMD_ROOTDIR"
#define ENV_NEPMD_USERDIR          "NEPMD_USERDIR"
#define ENV_NEPMD_MAINENVFILE      "NEPMD_MAINENVFILE"
#define ENV_NEPMD_ADDENVFILE       "NEPMD_ADDENVFILE"
#define ENV_NEPMD_EPMEXECUTABLE    "NEPMD_EPMEXECUTABLE"
#define ENV_NEPMD_LOADEREXECUTABLE "NEPMD_LOADEREXECUTABLE"

// pszBuffer is optional and receives the name
// of the original EPM executable
APIRET GetExtendedEPMEnvironment( PSZ envv[], PSZ *ppszNewEnv,
                                  PSZ pszBuffer, ULONG ulBuflen);
PSZ ExpandEnvVar( PSZ pszStr);
PSZ ExpandEnvVarAndRootDir( PSZ pszStr, PSZ pszRootDirValue);

#endif // EPMENV_H

