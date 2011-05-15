/****************************** Module Header *******************************
*
* Module Name: get.e
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
;  For linking version, GET can be an external module.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled.
define INCLUDING_FILE = 'GET.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 'LINK'
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'

defmain     -- External modules always start execution at DEFMAIN.
   'get' arg(1)

   EA_comment 'This defines the GET command; it can be linked, or executed directly.'
compile endif  -- not defined(SMALL)

defc get=
   universal default_edit_options
   get_file = strip(arg(1))
   if get_file = '' then
      sayerror NO_FILENAME__MSG 'GET'
      return
   endif
   if pos( argsep, get_file) then
      sayerror INVALID_OPTION__MSG
      return
   endif
   call parse_filename( get_file, .filename)
   getfileid fileid
   s_last = .last
   display -1
   'xcom e /q /d' get_file
   editrc = rc
   getfileid gfileid
   if editrc = -282 | not .last then   -- -282 = sayerror('New file')
      'xcom q'
      display 1
      if editrc = -282 then
         sayerror FILE_NOT_FOUND__MSG':  'get_file
      else
         sayerror FILE_IS_EMPTY__MSG':  'get_file
      endif
      return
   endif
   if editrc & editrc <> -278 then  -- -278  sayerror('Lines truncated') then
      display 1
      sayerror editrc
      return
   endif
   call psave_mark(save_mark)
   if not .levelofattributesupport then
      'loadattributes'
   endif
   get_file_attrib = .levelofattributesupport
   top
   mark_line
   bottom
   if rightstr( textline(.last), 1) = \26 then  -- Ends with EOF?
      getline line
      replaceline leftstr( line, length(line) - 1)
      .modify = 0
   endif
   mark_line
   activatefile fileid
   rc = 0
   copy_mark
   copy_rc = rc           -- Test for memory too full for copy_mark.
   activatefile gfileid
   'xcom q'
   parse value save_mark with s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt
   if fileid = s_mkfileid then           -- May have to move the mark.
      diff = fileid.last - s_last        -- (Adjustment for difference in size)
      if fileid.line < s_firstline then s_firstline = s_firstline + diff; endif
      if fileid.line < s_lastline  then s_lastline  = s_lastline  + diff; endif
   endif
   call prestore_mark( s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt)
   activatefile fileid
   if get_file_attrib // 2 then
      call attribute_on(1)  -- Colors flag
   endif
   if get_file_attrib bitand 4 then
      call attribute_on(4)  -- Mixed fonts flag
   endif
   if get_file_attrib bitand 8 then
      call attribute_on(8)  -- "Save attributes" flag
   endif
   display 1
   if copy_rc then
      sayerror NOT_2_COPIES__MSG get_file
   endif
;  refresh
;  call repaint_window()


