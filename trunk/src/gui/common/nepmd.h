/****************************** Module Header *******************************
*
* Module Name: nepmd.h
*
* Header with common values used by all source files of NEPMD.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmd.h,v 1.12 2002-09-02 09:36:22 cla Exp $
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

#ifndef NEPMD_H
#define NEPMD_H

#define __HOMEPAGE__                   "http://nepmd.netlabs.org"

// INI app names and keys of NEPMD project from OS2.INI
#define NEPMD_INI_APPNAME              "NEPMD"
#define NEPMD_INI_KEYNAME_LANGUAGE     "Language"
#define NEPMD_INI_KEYNAME_PATH         "Path"

// define filename extensions
#define NEPMD_FILENAMEEXT_ENV          ".env"

// tag definitions for GetInstValue
#define NEPMD_VALUETAG_ROOTDIR         "ROOTDIR"
#define NEPMD_VALUETAG_LANGUAGE        "LANGUAGE"
#define NEPMD_VALUETAG_INIT            "INIT"
#define NEPMD_VALUETAG_MESSAGE         "MESSAGE"

// define some filenames for EPM
#define NEPMD_FILENAME_LIBINFO         ".NEPMD_INFO"

// path definitions relative to NEPMD install dir
// NOTE: last word of symbol names are taken from the
//       names of the macros used in makefiles where applicable ;-)

#define NEPMD_SUBPATH_BINBINDIR    "netlabs\\bin"
#define NEPMD_SUBPATH_CMPINFDIR    "netlabs\\book"
#define NEPMD_SUBPATH_MYBINDIR     "myepm\\bin"

// file path and name definitions used by NepmdGetInstFilename

#define NEPMD_SUBPATH_INIFILE      NEPMD_SUBPATH_MYBINDIR
#define NEPMD_DEVPATH_INIFILE      "debug"
#define NEPMD_FILENAME_INIFILE     "nepmd.ini"

#define NEPMD_SUBPATH_MESSAGEFILE  NEPMD_SUBPATH_BINBINDIR
#define NEPMD_DEVPATH_MESSAGEFILE  "src\\nls\\netlabs\\bin"
#define NEPMD_FILENAME_MESSAGEFILE "nepmd%s.tmf"


// define external env vars available in epm.env

#define ENV_NEPMD_LANGUAGE         "NEPMD_LANGUAGE"
#define ENV_NEPMD_PATH             "NEPMD_ROOTDIR"
#define ENV_NEPMD_MAINENVFILE      "NEPMD_MAINENVFILE"
#define ENV_NEPMD_USERENVFILE      "NEPMD_USERENVFILE"
#define ENV_NEPMD_EPMEXECUTABLE    "NEPMD_EPMEXECUTABLE"
#define ENV_NEPMD_LOADEREXECUTABLE "NEPMD_LOADEREXECUTABLE"

// define external env variable for testing of
// NEPMD utilities in working directory tree
#define ENV_NEPMD_DEVPATH          "NEPMD_DEVROOTDIR"

#endif // NEPMD_H

