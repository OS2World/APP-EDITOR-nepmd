/****************************** Module Header *******************************
*
* Module Name: makedep.cmd
*
* Batch for to create a dependency file using FASTDEP.EXE
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: makedep.cmd,v 1.3 2002-06-04 22:29:46 cla Exp $
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

 PARSE ARG OutDir DepFileName;

 '@fastdep -o' OutDir '-d' DepFileName '-a- *.c *.rc'

