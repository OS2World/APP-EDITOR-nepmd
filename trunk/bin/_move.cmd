/****************************** Module Header *******************************
*
* Module Name: _move.cmd
*
* Helper batch for to move a file.
*
* Unlike the OS/2 command MOVE this batch allows to specify a path WITH
* drive for the target.
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

 PARSE ARG Source Target;

 /* remove drive from target specification */
 /* and execute move command               */
 IF (POS( ':', Target) > 0) THEN
    PARSE VAR Target .':'Target;

 '@MOVE' Source Target;
 EXIT( rc);

