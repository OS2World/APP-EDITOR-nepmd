/****************************** Module Header *******************************
*
* Module Name: put.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: put.e,v 1.3 2002-08-19 23:33:00 aschn Exp $
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
;  For linking version, PUT can be an external module.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'PUT.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

 compile if not defined(NLS_LANGUAGE)
const NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   EA_comment 'This defines the PUT command; it can be linked, or executed directly.'
compile endif

defmain     -- External modules always start execution at DEFMAIN.
   'put' arg(1)

defc app, append, put =
   universal last_append_file

   -- Put and append work the same, and the same as XEdit's PUT.
   -- If the file already exists, append to it.
   -- If no file is specified, use same file as last specified.
   -- If no mark, use append the entire file.
   name = arg(1)
   call parse_leading_options(name,options)
   if name = '' then
      app_file=last_append_file
   else
      app_file=parse_file_n_opts(name)
      last_append_file=app_file
   endif
   if app_file='' then
      sayerror NO_FILENAME__MSG 'PUT'
      stop
   endif
   is_console = upcase(app_file)='CON' | upcase(app_file)='CON:'
   if is_console then
      sayerror NO_CONSOLE__MSG
      return
   endif
   getfileid fileid
   if marktype() then
      had_mark = 1
      call psave_mark(save_mark)
      call prestore_mark(save_mark)
   elseif .last = 0 then sayerror FILE_IS_EMPTY__MSG; stop
   else
      had_mark = 0
      call pset_mark(1,.last,1,1,'LINE',fileid)
   endif
   /* If file is already in memory, we'll leave it there for speed. */
   parse value 1 check_for_printer(app_file) with already_in_ring is_printer .
   if is_printer | is_console then
      'e /q /c' app_file   /* force creation of a new file */
   else
      'e /q /n' app_file   /* look for file already in ring */
      if rc=-282 then  -- -282 = sayerror("New file")
         already_in_ring = 0
         'q'
         'e /q' app_file  /* not 'xcom e', so we can append to host files */
      endif
   endif
   if is_printer or is_console or not already_in_ring then
      if rc=-282 then
         deleteline
      elseif rc then
         stop
      endif
   endif
   getfileid tempofid
   if marktype()<>'LINE' then
      insertline '',tempofid.last+1
   endif
   bottom
   copyrc=pcopy_mark()
   if copyrc then /* Check memory full, invalid path, etc. */
      .modify=0; 'q'
      sayerror copyrc
      stop
   endif
   error_saving=0
   /* If the app_file was already in memory, don't file it. */
   if is_printer or is_console or not already_in_ring then
      'save' options
      error_saving=rc
      activatefile tempofid; tempofid.modify=0; 'q'
   endif
   activatefile fileid
   if had_mark then
      call prestore_mark(save_mark)
   else
      unmark
   endif
   refresh
   -- call settitletext(.filename) /* done internally */
   call repaint_window()
