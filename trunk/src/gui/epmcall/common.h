/****************************** Module Header *******************************
*
* Module Name: common.h
*
* Header with common values used by all source files of epmcall.
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

#ifndef COMMON_H
#define COMMON_H

#ifdef DEBUG
#include <malloc.h>
#endif

#include "nepmd.h"

#define __APPNAME__                    "Netlabs EPM Distribution executable loader"
#define __APPNAMESHORT__               "NEPMD executable loader"  // for title of error msg
#define __PROGSTEM__                   "epmcall"
#define __VERSION__                    "v1.14"
#define __YEAR__                       "2009"

#endif // COMMON_H

