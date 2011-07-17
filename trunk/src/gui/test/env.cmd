@ECHO OFF
: ***************************** Module Header ******************************\
:
: Module Name: dd.cmd
:
: This batch sepcifies the current testcase for qq.cmd and dd.cmd
: Modify as needed, but don't check in all the time ;-)
:
: Copyright (c) Netlabs EPM Distribution Project 2002
:
: $Id$
:
: ===========================================================================
:
: This file is part of the Netlabs EPM Distribution package and is free
: software.  You can redistribute it and/or modify it under the terms of the
: GNU General Public License as published by the Free Software
: Foundation, in version 2 as it comes in the "COPYING" file of the
: Netlabs EPM Distribution.  This library is distributed in the hope that it
: will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
: of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
: General Public License for more details.
:
: **************************************************************************/

 SET EPMMODEPATH=o:\NEPMD\myepm\mode;o:\NEPMD\netlabs\mode;

 SET TESTCASE=CONFIGVALUE
 SET TESTCASE=MMF
 SET TESTCASE=QUERYMODELIST
 SET TESTCASE=QUERYMODE
 SET TESTCASE=QUERYHILIGHTFILE

