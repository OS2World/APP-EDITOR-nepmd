/****************************** Module Header *******************************
*
* Module Name: nepmdlib.h
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.h,v 1.7 2002-09-04 15:39:13 cla Exp $
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

#ifndef NEPMDLIB_H
#define NEPMDLIB_H

#define NEPMDLIB_VERSION          "1.00"

#define NEPMDLIB_STR_TITLE        "Netlabs EPM Distribution Library - Runtime Information"
#define NEPMDLIB_STR_FILENAME     "Filename: "
#define NEPMDLIB_STR_LOADEDFROM   "Directory: "
#define NEPMDLIB_STR_VERSION      "Version: "
#define NEPMDLIB_STR_LOADEDBY     "Loaded from: "

// tag definitions for NepmdAlarm
#define NEPMD_ALARMSTYLE_WARNING       "WARNING"
#define NEPMD_ALARMSTYLE_NOTE          "NOTE"
#define NEPMD_ALARMSTYLE_ERROR         "ERROR"


// tag definitons for NepmdQueryPathInfo
#define NEPMD_PATHINFO_CTIME           "CTIME"
#define NEPMD_PATHINFO_MTIME           "MTIME"
#define NEPMD_PATHINFO_ATIME           "ATIME"
#define NEPMD_PATHINFO_SIZE            "SIZE"
#define NEPMD_PATHINFO_ATTR            "ATTR"

// tag definitions for NepmdQueryProcessInfo
#define NEPMD_PROCESSINFO_PID          "PID"
#define NEPMD_PROCESSINFO_PPID         "PPID"
#define NEPMD_PROCESSINFO_PROGRAM      "PROGRAM"
#define NEPMD_PROCESSINFO_PARMS        "PARMS"

#endif // NEPMDLIB_H

