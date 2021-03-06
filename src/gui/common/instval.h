/****************************** Module Header *******************************
*
* Module Name: instval.h
*
* Header for generic routine to determine installation values
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

#ifndef INSTVAL_H
#define INSTVAL_H

// tag definitions for QueryInstValue
#define NEPMD_INSTVALUE_ROOTDIR         "ROOTDIR"
#define NEPMD_INSTVALUE_USERDIR         "USERDIR"
#define NEPMD_INSTVALUE_LANGUAGE        "LANGUAGE"
#define NEPMD_INSTVALUE_INIT            "INIT"
#define NEPMD_INSTVALUE_MESSAGE         "MESSAGE"
#define NEPMD_INSTVALUE_HELP            "HELP"
#define NEPMD_INSTVALUE_USRGUIDE        "USRGUIDE"
#define NEPMD_INSTVALUE_PRGGUIDE        "PRGGUIDE"

// define external env variable for testing of
// NEPMD utilities in working directory tree
#define ENV_NEPMD_DEVPATH          "NEPMD_DEVROOTDIR"

// prototypes
APIRET QueryInstValue( PSZ pszValueTagTag, PSZ pszBuffer, ULONG ulBuflen);
APIRET GetMessage( PCHAR *pTable, ULONG cTable, PBYTE pbBuffer, ULONG cbBuffer,
                   PSZ pszMessageName, PULONG pcbMsg);

#endif // INSTVAL_H

