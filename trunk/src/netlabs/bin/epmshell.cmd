/****************************** Module Header *******************************
*
* Module Name: epmshell.cmd
*
* Syntax: epmshell [directory]
*
* Helper batch for to open a new EPM window with an EPM command shell
* window. The path of the shell is changed to the submitted directory, if
* any.
*
* To use this as an extension for XWorkplace's "Configuration folder" ->
* "Command prompts" folder, place a reference object (or a copy) of the
* "EPM Shell" program object in the "Command prompts" folder.
*
*    EXENAME     <path>epmshell.cmd
*    PARAMETERS  (none)
*    STARTUPDIR  (none)
*
* Also activate MINIMIZED=YES for it.
*
* This script is required because the parameter resolution of XWP for %*
* is buggy: A WPS program object with the parameters '%*' (including the
* quotes) is not recognized as a % parameter. XWP would append the directory
* instead of inserting it where the %* stands. Otherwise a program object
* with the following parameters would work:
*
*    EXENAME     epm.exe
*    PARAMETERS  'shell cdd {%*}'
*    STARTUPDIR  (none)
*
* Copyright (c) Netlabs EPM Distribution Project 2006
*
* $Id: epmshell.cmd,v 1.2 2006-12-17 21:40:44 aschn Exp $
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

parse arg args
args = strip( args)

EpmCmd = 'shell'
if length( strip( args, , '"')) > 0 then
   EpmCmd = EpmCmd 'cdd {'args'}'

"@start epm '"EpmCmd"'"

exit

