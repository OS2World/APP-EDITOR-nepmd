/****************************** Module Header *******************************
*
* Module Name: recode.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
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

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
   include 'stdconst.e'
define INCLUDING_FILE = 'RECODE.E'

defmain
   parse arg args
   'recode 'args
compile endif  -- not defined(SMALL)


; Call recode and revert current file
defc recode
   parse arg args
   if .modify then
      if WinMessageBox( 'Recode and reload file from disk',
                        .filename' was modified.'\13 ||
                        'Throw away changes to file on disk?',
                        MB_OKCANCEL + MB_WARNING + MB_DEFBUTTON1 + MB_MOVEABLE) <> MBID_OK then
         return -293  -- sayerror("has been modified")
      else
         .modify = 0
         'unlock'
      endif
   endif
   if args = '' then
      'commandline recode latin1:cp850'  -- recursive call
      return
   endif
   if pos ( ' ', .filename) then
      filename = '"'.filename'"'
   else
      filename = .filename
   endif
   --'commandline dos recode' args .filename
   --'os2 recode' args .filename
   --    'commandline' returns only its own rc!
   --    'os2' returns only its own rc and doesn't run minimized!
   --    Only 'dos' returns the app's rc and runs minimized.
   'dos recode' args filename
   if rc = 0 then
      'revert'
   elseif rc = -274 then
      sayerror 'Error, rc = 'rc' (probably Gnu recode not found in PATH)'
   else
      sayerror 'Error from recode: rc = 'rc
   endif

