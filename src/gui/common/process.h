/****************************** Module Header *******************************
*
* Module Name: process.h
*
* Header for generic routines to start routines (a)synchronously
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: process.h,v 1.2 2002-08-14 12:15:44 cla Exp $
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

#ifndef PROCESS_H
#define PROCESS_H

APIRET ExecPipedCommand( PSZ pszCommand, PSZ pszBuffer, ULONG ulBuflen);
APIRET ExecVioCommandSession( PSZ pszEnv, PSZ pszAppName, PSZ pszCommand, BOOL fVisible);
APIRET StartPmSession( PSZ pszProgram, PSZ pszParms, PSZ pszTitle, PSZ pszEnv,
                       BOOL fForeground, ULONG ulControlStyle);

#endif // PROCESS_H

