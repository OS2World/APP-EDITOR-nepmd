/****************************** Module Header *******************************
*
* Module Name: tc.cmd
*
* Batch file for testing purposes:
* This program loads the files of the testcase subdirectory
* in order to ease testing of the reload function. Moreover,
* the cursor is set to a specific position for each file, so that
* the repositioning of the cursor can be tested easily.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: tc.cmd,v 1.2 2002-06-04 22:46:27 cla Exp $
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

 '@ECHO OFF'
 MacroName = STREAM( '..\..\..\compile\tc.ex', 'C', 'QUERY EXISTS');
 EpmCommand = 'MC ;link' MacroName';tc_setpos;'

 'call q';
 'call make testcase'
 "start EPM testcase\* '"EpmCommand"'"

