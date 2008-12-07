/****************************** Module Header *******************************
*
* Module Name: epmshell.cmd
*
* Syntax: epmshell [directory] | [file] | [shell_command]
*
* Helper batch for to open a new EPM window with an EPM command shell
* window. If parameters are submitted, these parameters were executed in
* the shell. For a submitted directory, the path of the shell is changed to
* it. For a submitted file, the path is changed to the directory of that
* file.
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
* In XWorkplace's Extended Associations, the parameter resolution for %*
* parameters is buggy: The resolved string for % parameters is always
* appended, preceded by a space, even when it was not specified otherwise.
* This occurs with extended associations (turbo folders) activated in XWP
* v1.0.7. When the bug will be fixed, a program object with the following
* settings would be equivalent for submitted dirs or files, but not for
* commands:
*
*    EXENAME     <path>epm.exe
*    PARAMETERS  'shell cdd "%*"'
*    STARTUPDIR  (none)
*
* Copyright (c) Netlabs EPM Distribution Project 2006
*
* $Id: epmshell.cmd,v 1.5 2008-12-07 22:10:39 aschn Exp $
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

'@echo off'

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

parse arg Args
Args = strip( Args)

EpmCmd     = 'shell'
EpmCmdProc = ''
/* Optionally specify a command processor, that can be loaded by CMD.EXE.  */
/* Disadvantage: If you close the EPM shell, before you left that command  */
/* processor, 2 processes won't be closed: CMD.EXE and the external EXE.   */
/* You have to use a process killer to kill them.                          */
/* To give an example: If you load 4os2 in an EPM shell window, type exit  */
/* to close 4os2 before you close the EPM shell.                           */
/*EpmCmdProc = '4os2'*/

/* Check Args */
EpmOptions = ''
EpmCmdArgs = ''
Dir = ''
do 1
   RestArgs = Args

   /* Parse leading EPM options */
   do forever
      RestArgs = strip( RestArgs)
      if left( RestArgs, 1) <> '/' then
         leave
      if substr( RestArgs, 3, 1) = '"' then
      do
         parse var RestArgs opt'"'optarg'"' RestArgs
         nextopt = opt'"'optarg'"'
      end
      else
         parse var RestArgs nextopt RestArgs
      EpmOptions = EpmOptions nextopt
   end
   EpmOptions = strip( EpmOptions)
   RestArgs = strip( RestArgs)

   CheckArgs = RestArgs
   /* Strip double quotes */
   if left( CheckArgs, 1) = '"' & right( CheckArgs, 1) = '"' then
      CheckArgs = substr( CheckArgs, 2, length( CheckArgs) - 2)

   if length( CheckArgs) = 0 then
      /* No Args, so execute only EpmCmd */
      leave

   /* Check for a dir */
   /* Note: SysFileTree doesn't handle '\..' and '\.' correctly */
   Found.0 = 0
   rcx = SysFileTree( CheckArgs, 'Found.', 'DO', '*+***')  /* ADHRS */
   if rcx = 0 & Found.0 <> 0 then
   do
      /* Dir found, change to it */
      Dir = CheckArgs
      EpmCmdArgs = 'cdd' EscapeString( '"'Dir'"')
      leave
   end

   /* Check for a file */
   next = stream( CheckArgs, 'c', 'query exists')
   if next <> '' then
   do
      /* File found, get parent dir of it */
      lp = lastpos( '\', next)
      if lp = 0 then
         lp = lastpos( '/', next)
      if lp <> 0 then
      do
         Dir = left( next, lp - 1)
         RestArgs = substr( next, lp + 1)
         /* Change to dir and append Args */
         EpmCmdArgs = 'cdd' EscapeString( '"'Dir'" & "'RestArgs'"')
         leave
      end
   end

   /* Not a dir nor a file, so try to execute it */
   EpmCmdArgs = RestArgs
   leave
end

/* Now build the command string */
EpmCall = 'start epm'

if EpmOptions <> '' then
   EpmCall = EpmCall EpmOptions

if EpmCmdProc <> '' then
   EpmCmd = EpmCmd EpmCmdProc
if EpmCmdArgs <> '' then
   EpmCmd = EpmCmd EpmCmdArgs

/* Execute it */
EpmCall "'"EpmCmd"'"

exit


/* ----------------------------------------------------------------------- */
EscapeString: procedure
   parse arg String
   Startp = 1
   do forever
      p1 = verify( String, '^&|', 'M', Startp)
      if p1 = 0 then leave
      chr1 = substr( String, 1, 1)
      chr2 = substr( String, 2, 1)
      String = insert( '^', String, p1 - 1)
      if chr1 = chr2 & pos( chr1, '&|') > 0 then
         Startp = p1 + 3
      else
         Startp = p1 + 2
   end
   return String

