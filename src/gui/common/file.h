/****************************** Module Header *******************************
*
* Module Name: file.h
*
* Header for generic routines for accessing files and directories.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: file.h,v 1.3 2002-09-24 16:48:51 cla Exp $
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

#ifndef FILE_H
#define FILE_H

APIRET GetTempFilename( PSZ pszBuffer, ULONG ulBuflen);

BOOL FileExists( PSZ pszName);
BOOL DirExists( PSZ pszName);

ULONG FileDate( PSZ pszName);

APIRET FileInPath( PSZ pszEnvName, PSZ pszName, PSZ pszBuffer, ULONG ulBuflen);

APIRET GetNextFile( PSZ pszFileMask, PHDIR phdir,
                    PSZ pszNextFile, ULONG ulBuflen);
APIRET GetNextDir( PSZ pszFileMask, PHDIR phdir,
                   PSZ pszNextDir, ULONG ulBuflen);
                   PSZ Filespec ( PSZ pszFilename, ULONG ulPart);

PSZ Filespec ( PSZ pszFilename, ULONG ulPart);
#define FILESPEC_PATHNAME  1
#define FILESPEC_NAME      2
#define FILESPEC_EXTENSION 3

ULONG QueryFileSize( PSZ pszName);

#endif // FILE_H

