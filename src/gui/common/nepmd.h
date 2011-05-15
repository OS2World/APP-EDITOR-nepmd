/****************************** Module Header *******************************
*
* Module Name: nepmd.h
*
* Header with common values used by all source files of NEPMD.
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

#ifndef NEPMD_H
#define NEPMD_H

#define __HOMEPAGE__                   "http://nepmd.netlabs.org"

// INI app names and keys of NEPMD project from OS2.INI
#define NEPMD_INI_APPNAME              "NEPMD"
#define NEPMD_INI_KEYNAME_LANGUAGE     "Language"
#define NEPMD_INI_KEYNAME_ROOTDIR      "RootDir"
#define NEPMD_INI_KEYNAME_USERDIR      "UserDir"

#define NEPMD_SUBPATH_DEFAULTUSERDIR   "myepm"

// define some filenames for EPM
#define NEPMD_FILENAME_LIBINFO         ".NEPMD_INFO"

// path definitions relative to NEPMD install dir
// NOTE: last word of symbol names are taken from the
//       names of the macros used in makefiles where applicable ;-)

#define NEPMD_SUBPATH_BINBINDIR    "netlabs\\bin"
#define NEPMD_SUBPATH_CMPINFDIR    "netlabs\\book"
#define NEPMD_SUBPATH_CMPHLPDIR    "netlabs\\help"
#define NEPMD_SUBPATH_USERBINDIR   "bin"

// file path and name definitions used by NepmdGetInstFilename

#define NEPMD_SUBPATH_INIFILE      NEPMD_SUBPATH_USERBINDIR
#define NEPMD_DEVPATH_INIFILE      "debug"
#define NEPMD_FILENAME_INIFILE     "nepmd.ini"

#define NEPMD_SUBPATH_MESSAGEFILE  NEPMD_SUBPATH_BINBINDIR
#define NEPMD_DEVPATH_MESSAGEFILE  "src\\nls\\netlabs\\bin"
#define NEPMD_FILENAME_MESSAGEFILE "nepmd%s.tmf"

#define NEPMD_SUBPATH_INFFILE      NEPMD_SUBPATH_CMPINFDIR
#define NEPMD_DEVPATH_INFFILE      "compile\\base\\"NEPMD_SUBPATH_CMPINFDIR
#define NEPMD_FILENAME_USRINFFILE  "neusr%s.inf"
#define NEPMD_FILENAME_PRGINFFILE  "neprg%s.inf"

#define NEPMD_SUBPATH_HELPFILE     NEPMD_SUBPATH_CMPINFDIR
#define NEPMD_DEVPATH_HELPFILE     "compile\\base\\"NEPMD_SUBPATH_CMPHLPDIR
#define NEPMD_FILENAME_HELPFILE    "nepmd%s.hlp"

// filename used by NepmdInitconfig
#define NEPMD_SUBPATH_DEFAULTSFILE  NEPMD_SUBPATH_BINBINDIR
#define NEPMD_FILENAME_DEFAULTSFILE "defaults.dat"
#define NEPMD_DEVPATH_DEFAULTSFILE  "src\\netlabs\\bin"

#endif // NEPMD_H

