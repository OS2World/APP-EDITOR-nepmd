/****************************** Module Header *******************************
*
* Module Name: common.h
*
* Header with common values used by all source files of epmcall.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: common.h,v 1.1 2002-08-10 13:03:38 cla Exp $
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

#define __APPNAME__                    "EMP(CALL)"
#define __PROGSTEM__                   "epmcall"
#define __VERSION__                    "V1.00"
#define __YEAR__                       "2002"

#endif // COMMON_H

