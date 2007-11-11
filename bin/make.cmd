/****************************** Module Header *******************************
*
* Module Name: make.cmd
*
* Shortcut for nmake /nologo
*
* Copyright (c) Netlabs EPM Distribution Project 2007
*
* $Id: make.cmd,v 1.1 2007-11-11 02:53:44 aschn Exp $
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

PARSE ARG Parms
'@CALL NMAKE /NOLOGO' Parms
RETURN(rc);

