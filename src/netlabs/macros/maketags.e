/****************************** Module Header *******************************
*
* Module Name: maketags.e
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

; Todo for TAGS.E, MAKETAGS.E
; -  'MakeTags' doesn't remove entries for non-existing files. It only
;    updates or adds entries.
;    --> Workaround: delete tags file, maybe create a cmd and menu item.
; -  'MakeTags' for mode E lists only defproc. defc, def and defkeys are
;    missing.
;    --> Add an aditional parameter to specify the tags type.
;    --> Change the 'TagScan' listbox to show this column or create a new
;        dialog.
; -  Tags in multi-line comments are not ignored. Some *_proc_search procs
;    even don't ignore strings.
; -  Replace extension with mode.

;def s_f6 'FindTag'     -- Find procedure under cursor via tags file
;def s_f7 'FindTag *'   -- Open entrybox to enter a procedure to find via tags file
;def s_f8 'TagsFile'    -- Open entrybox to select a tags file
;def s_f9 'MakeTags *'  -- Open entrybox to enter list of files to scan for to create a tags file
; 'TagScan'    is executed by menuitem 'Scan current file...'
; 'maketags =' is executed by the Tags dialog, when the Refresh button is pressed.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'MAKETAGS.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   include 'stdconst.e'
   EA_comment 'This defines the MAKETAGS command; it is intended to be executed directly.'
compile endif

const
compile if not defined(SHOW_EACH_PROCEDURE)
   SHOW_EACH_PROCEDURE = 0
compile endif
compile if not defined(TRACE_TIMES)
   TRACE_TIMES = 0
compile endif
compile if not defined(LOG_TAG_MATCHES)
   LOG_TAG_MATCHES = 0
compile endif

defmain
   'maketags' arg(1)

; ---------------------------------------------------------------------------
; 'maketags =' is executed by the Tags dialog, when the Refresh button is pressed.
defc maketags
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   universal tags_fileid

   dprintf( 'TAGS', 'MAKETAGS: arg(1) = 'arg(1))
   -- Requires procedures from TAGS.E. Link if undefined.
   if not isadefproc('tags_filename') then
      link 'tags'
   endif

   if arg(1) = '' | arg(1) = '?' then
      sayerror 'Args:  [@]file ...   where @ specifies list file.'
      return
   endif
   params = arg(1)

   if params = '*' then  -- resolve '*'
      parse value entrybox( MAKETAGS__MSG '-' tags_filename(),             -- title
                            '/'OK__MSG'/'Cancel__MSG'/'Help__MSG'/',       -- buttons
                            checkini(0, 'MAKETAGS_PARM', ''),              -- start entry
                            '',                                            -- cols
                            200,                                           -- max length of enty
                            atoi(1) ||                                     -- default button
                            atoi(6080) ||                                  -- helpid
                            gethwndc(APP_HANDLE) ||
                            MAKETAGS_PROMPT__MSG) with button 2 params \0  -- text
      if button <> \1 then
         return
      endif
   endif

   if params <> '' & params <> '=' then      -- if tagsfilename submitted
      call setini( 'MAKETAGS_PARM', params)  -- save to ini
   endif

   prev_file = .filename

compile if LOG_TAG_MATCHES
   'xcom e /c tags.log'
   if rc <> -282 then  -- -282 = sayerror("New file")
      return
   endif
   getfileid TAG_LOG_FID
   .autosave = 0
   parse value getdate(1) with today';' .  /* Discard MonthNum. */
   parse value gettime(1) with now';' .    /* Discard Hour24. */
   replaceline 'MakeTags started at' now 'on' today':' params
   .filename = 'tags.log'
   .modify = 0
compile endif

   'xcom e /d' tags_filename()
   if rc <> 0 & rc <> -282 then  -- if error, -282 = sayerror("New file")
      return
   endif
   if rc = -282 then  -- if new file
      deleteline      -- delete automatically created empty line
   endif

   -- Defer this until after tags file loaded, because TagsFileList might want
   -- to edit the tags file in order to check its EPM.TAGSARGS EA
   if arg(1) = '=' then
      -- Query list of filemasks from ini or from EA EPM.TAGSARGS
      params = TagsFileList(.filename)
      if params = '' then
         sayerror 'MakeTags parameters could not be determined.'
         return
      endif
      call setini( 'MAKETAGS_PARM', params)  -- save it to ini temporarily
   endif

   original_arg = params
   msgl_on_off = queryframecontrol(2)   -- Remember if messageline on or off
   'toggleframe 2 1'                    -- Force it on
   'setmessageline' MAKETAGS_PROCESSING__MSG

   oldfile = .last  -- will be 0 (FALSE) if new file

   .autosave = 0
   .modify = 0
   getfileid tag_fid
   list_fid = ''
   list_stack = ''
   status = 0
   filecount = 0
   skipped = 0
   deleted = 0
   path_prefix = ''
   loop
      if list_fid <> '' then  -- We're processing a file containing a list of files
         activatefile list_fid
         if .line = .last then
            'xcom quit'
            parse value list_stack with list_fid path_prefix list_stack
            iterate
         endif
         '+1'
         getline params
         activatefile tag_fid
      endif
      -- get next filemask or filename
      filename = parse_file( params, prev_file, listflag)
      if listflag then  /* specify list? */
         If not verify( filename, '\:', 'M') then
            filename = path_prefix||filename
         endif
         'xcom e /d' filename
         if rc then
            if rc = -282 then  -- -282 = sayerror("New file")
               'xcom quit'
               msg = "'"filename"' not found."
            else
               msg = sayerrortext(rc)
            endif
            sayerror "Error reading list '"filename"'.  "msg
            status = 1
            leave
         endif
         prev_file = .filename
         list_stack = list_fid path_prefix list_stack
         getfileid list_fid
         path_prefix = substr( .filename, 1, lastpos( '\', .filename))
         '0'
         iterate
      endif
      if filename = '' then
         leave
      endif
      If not verify( filename, '\:', 'M') then
         filename = path_prefix||filename
      endif
      --sayerror 'MAKETAGS: filemask = "'filename'"'
      dprintf( 'TAGS', 'MAKETAGS: filemask = "'filename'"')

      if verify( filename, '?*', 'M') then  -- If wildcards
         wildcards = 1
         wild_prefix = substr( filename, 1, lastpos( '\', filename))
         namez     = filename\0    -- ASCIIZ
         resultbuf = copies( \0, 300)
         attribute = 1         -- want to see normal & read-only file entries
         searchcnt = atol(1)   -- search count; we're only asking for 1 file at a time here
         dirhandle = \xff\xff\xff\xff  -- Ask system to assign us a handle
         result = dynalink32( 'DOSCALLS',             -- dynamic link library name
                              '#264',                 -- ordinal value for DOS32FINDFIRST
                              address( namez)           || -- filename we're looking for
                              address( dirhandle)       || -- pointer to the handle
                              atol( attribute)          || -- attribute value describing desired files
                              address( resultbuf)       || -- string address
                              atol( length( resultbuf)) ||
                              address( searchcnt)       || -- pointer to the count; system updates
                              atol( 1), 2)                 -- file info level 1 requested

         if result then
                if result = 2   then msg = 'FILE NOT FOUND'
            elseif result = 3   then msg = 'PATH NOT FOUND'
            elseif result = 6   then msg = 'INVALID HANDLE'
            elseif result = 18  then msg = 'NO MORE FILES'
            elseif result = 26  then msg = 'NOT DOS DISK'
            elseif result = 87  then msg = 'INVALID PARAMETER'
            elseif result = 108 then msg = 'DRIVE LOCKED'
            elseif result = 111 then msg = 'BUFFER OVERFLOW'
            elseif result = 113 then msg = 'NO MORE SEARCH HANDLES'
            elseif result = 206 then msg = 'FILENAME EXCED RANGE'
            endif
            sayerror 'Error' result '('msg') for "'filename'"'
            iterate  -- take next filemask
         endif
         filename = wild_prefix || substr( resultbuf, 30, asc( substr( resultbuf, 29, 1)))
         filedate = ltoa( substr( resultbuf, 13, 4), 16)
      else
         wildcards = 0
         filedate = GetFileDateHex( filename)
      endif

      loop
         if oldfile then
            getfileid tempfid
            activatefile tag_fid
            0
            display -2
            'xcom l /'filename'/c'
            if rc then  -- Filename not found in existing tags file
               verb = 'Adding'
            else
               parse_tagline( temp_proc, temp_name, temp_line, temp_date)
               if temp_date = filedate then  -- Up-to-date
                  verb = 'Skipping'
                  skipped = skipped + 1
               else
                  verb = 'Refreshing'
                  while not rc do
                     deleteline
                     begin_line
                     repeat_find
                  endwhile
               endif
            endif
            display 2
            activatefile tempfid
         else
            verb = 'Searching'
         endif

compile if TRACE_TIMES
         if verb <> 'Skipping' then
            parse value gettime(1) with now';' .    /* Discard Hour24. */
            'setmessageline' now '-' verb "'"filename"'..."
         endif
compile endif

/*
         -- output of filenames slows processing down
         'SayHint' verb '"'filename'"...'
*/

compile if LOG_TAG_MATCHES
         insertline '', TAG_LOG_FID.last+1, TAG_LOG_FID
         if verb = 'Refreshing' then
            tmp = ' (timestamp was' timestamp(temp_date)'; now' timestamp(filedate)') '
         else
            tmp = ''
         endif
         insertline verb "'"filename"'"tmp"...", TAG_LOG_FID.last+1, TAG_LOG_FID
compile endif

         if verb <> 'Skipping' then
            start_size = tag_fid.last
            if add_tags( filename, tag_fid, filedate) then
               status = 1
               leave
            endif
            filecount = filecount + 1
            if start_size = tag_fid.last then  -- No tags added?  Record date anyway.
               insertline '*' filename 0 filedate, tag_fid.last+1, tag_fid
            endif
         endif
         if not wildcards then
            leave
         endif
         result = dynalink32( 'DOSCALLS',             -- dynamic link library name
                              '#265',                 -- ordinal value for DOS32FINDNEXT
                              dirhandle           ||  -- Directory handle, returned by DosFindFirst(2)
                              address(resultbuf)  ||  -- address of result buffer
                              atol(length(resultbuf)) ||
                              address(searchcnt), 2)  -- Pointer to the count; system updates
         if result then
            call dynalink32( 'DOSCALLS',             -- dynamic link library name
                             '#263',                 -- ordinal value for DOS32FINDCLOSE
                             dirhandle)              -- Directory handle, returned by DosFindFirst(2)
            if result <> 18 then
               sayerror 'Unexpected error' result 'from DosFindNext'
               status = 1
            endif
            leave
         endif
         filename = wild_prefix || substr( resultbuf, 30, asc(substr( resultbuf, 29, 1)))
         filedate = ltoa(substr( resultbuf, 13, 4), 16)
      endloop

      -- Find entries for non-existing files and remove them
      if oldfile then
         activatefile tag_fid
         '1'
         do while .line <= .last
            call parse_tagline( keyword, filename, line, tstamp)
            if leftstr( filename, 1) = '"' & rightstr( filename, 1) = '"' then
               filename = substr( filename, 2, length( filename) - 2)
            endif
            if not Exist( filename) then
               deleteline
               deleted = deleted + 1
            elseif .line = .last then
               leave
            else
               '+1'
            endif
         enddo
      endif

      if status then
         leave
      endif
   endloop

compile if LOG_TAG_MATCHES
   insertline '', TAG_LOG_FID.last+1, TAG_LOG_FID
   insertline copies( '=', 72), TAG_LOG_FID.last + 1, TAG_LOG_FID
   parse value getdate(1) with today';' .  /* Discard MonthNum. */
   parse value gettime(1) with now';' .    /* Discard Hour24. */
   insertline 'MakeTags ended at' now 'on' today'.  Status =' status, TAG_LOG_FID.last + 1, TAG_LOG_FID
compile endif

   'setmessageline '\0
   'toggleframe 2' msgl_on_off

   if status then
      'xcom quit'
      return 1
   endif

   if not .last then
      msg = 'No tags found'
      sayerror msg
compile if LOG_TAG_MATCHES
      insertline msg, TAG_LOG_FID.last + 1, TAG_LOG_FID
      TAG_LOG_FID.modify = 0
compile endif
      return 1
   endif

   tagcount = .last
   if tag_fid.modify then
/*
      sayerror 'Sorting' .last 'tags...'
*/
      call sort( 1, .last, 1, 40, tag_fid, 'i')
      call delete_ea('EPM.TAGSARGS')
      'add_ea EPM.TAGSARGS' original_arg
      already_loaded = 0
      if tags_fileid then
         if tags_fileid.filename = tag_fid.filename then
            already_loaded = 1
         endif
      endif
      if already_loaded then
         activatefile tags_fileid
         'xcom quit'
         activatefile tag_fid
         tags_fileid = tag_fid  -- Update universal variable
         'xcom save'
         if not rc then
            .visible = 0
            prevfile
         endif
      else
         'xcom save'
         'xcom quit'
      endif
   else
      'xcom quit'  -- Must be an old tags file here, or we would have said "No tags found" above.
      msg = 'Tags file was up-to-date.  (Scanned' filecount 'files; skipped' skipped')'
      sayerror msg
compile if LOG_TAG_MATCHES
      insertline msg, TAG_LOG_FID.last + 1, TAG_LOG_FID
      TAG_LOG_FID.modify = 0
compile endif
      return rc
   endif

   if oldfile then
      msg = 'Scanned' filecount 'files; skipped' skipped'; deleted' deleted'; total number of tags now' tagcount '(was' oldfile')'
      sayerror msg
compile if LOG_TAG_MATCHES
      insertline msg, TAG_LOG_FID.last + 1, TAG_LOG_FID
      TAG_LOG_FID.modify = 0
compile endif
   else
      msg = 'Found' tagcount 'tags in' filecount 'files'
      sayerror msg
compile if LOG_TAG_MATCHES
      insertline msg, TAG_LOG_FID.last + 1, TAG_LOG_FID
      TAG_LOG_FID.modify = 0
compile endif
   endif
   return rc

; ---------------------------------------------------------------------------
defproc add_tags( filename, tag_fid, filedate)
   dprintf( 'TAGS', 'ADD_TAGS: filename = 'filename)

   'xcom e /d' filename
   if rc then
      if rc = -282 then  -- -282 = sayerror("New file")
         'xcom quit'
         msg = 'File not found.'
      else
         msg = sayerrortext(rc)
      endif
      sayerror 'Error reading file "'filename'".  'msg
      return rc
   endif

   if verify( .filename, " '[]", 'M') then
      filename = '"'.filename'"'
   else
      filename = .filename
   endif

   ext = filetype()
   mode = GetMode()
   if not tags_supported( mode) then
      sayerror "Don't know how to do tags for file of mode" mode
      'xcom quit'
      return 1
   endif
   proc_name = ''

   rc = proc_search( proc_name, 1, mode, ext)
   while not rc do
compile if SHOW_EACH_PROCEDURE  -- Display progress messages
      'SayHint ...found "'proc_name'" in' filename
compile endif
      insertline proc_name filename .line filedate, tag_fid.last + 1, tag_fid
      proc_name=''
      end_line
      rc = proc_search( proc_name, 0, mode, ext)
   endwhile
   'xcom quit'
   return 0

; ---------------------------------------------------------------------------
defproc parse_file( var string, prev_file, var list_flag)
   if leftstr( word( string, 1), 1) = '@' then
      list_flag = 1
      parse value string with '@' string
   else
      list_flag = 0
   endif
   string = strip(string)
   if leftstr( string, 1) = '"' then
      end_quote = pos( '"', string, 2)
      if not end_quote then
         end_quote = length(string)
      endif
      file = substr( string, 1, end_quote)
      string = strip(substr( string, end_quote + 1))
   else
      parse value string with file string
      call parse_filename( file, prev_file)
   endif
   return file

; ---------------------------------------------------------------------------
compile if LOG_TAG_MATCHES
defproc timestamp(ts)
   hexes = '0123456789ABCDEF'
   datetime = upcase(rightstr( ts, 8, '0'))
   date = 0; time = 0
   do i = 1 to 4
      time = 16 * time + pos(substr(datetime,     i, 1), hexes) - 1
      date = 16 * date + pos(substr(datetime, 4 + i, 1), hexes) - 1
   enddo
   year = date % 512; date = date // 512
   month = date % 32; day = date // 32 % 1     -- %1 to drop fraction.
   date = year + 80'/'rightstr( month, 2, 0)'/'rightstr( day, 2, 0)
   hour = time % 2048; time = time // 2048
   min = time % 32; sec = time // 32 * 2 % 1
   time = hour':'rightstr( min, 2, 0)':'rightstr( sec, 2, 0)
   return date time
compile endif

