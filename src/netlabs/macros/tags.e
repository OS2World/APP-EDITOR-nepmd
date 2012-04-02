/****************************** Module Header *******************************
*
* Module Name: tags.e
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

;def s_f6 'FindTag'     -- Find procedure under cursor via tags file
;def s_f7 'FindTag *'   -- Open entrybox to enter a procedure to find via tags file
;def s_f8 'TagsFile'    -- Open entrybox to select a tags file
;def s_f9 'MakeTags *'  -- Open entrybox to enter list of files to scan for to create a tags file
; 'TagScan'    is executed by menuitem 'Scan current file...'
; 'maketags =' is executed by the Tags dialog, when the Refresh button is pressed.

; This module is a general purpose engine for providing searching and
; completion for tagged function names.
;
; To add support for another language, update tag_case() if it's a case-sensitive
; language, update tags_supported to indicate what file modes are supported
; and update proc_search to call the procedure search routine for that language.
;           tag_case()        Returns 'e' for case sensitive languages and
;                            'c' for case insensitive languages.
;
;     xxxxx_proc_search( var proc_name, find_first)
;                             If proc_name is null, this function searches
;                             for a valid procedure in the current buffer. If
;                             successful, proc_name is set to the procedure
;                             name and 0 is returned.  The find_first parameter
;                             when non-zero indicates that the first search
;                             is being performed.
;
;                             If proc_name is NOT null, this function searches
;                             for the definition of the procedure proc_name in
;                             the current buffer.  If successful, cursor is
;                             placed on procedure definition and 0 is returned.
;                             See one of the procedures C_PROC_SEARCH,
;                             PAS_PROC_SEARCH, or ASM_PROC_SEARCH for an
;                             example.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'TAGS.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

include 'stdconst.e'

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
compile endif

define
compile if not defined(CPP_EXTENSIONS)  -- Keep in sync with CKEYS.E
   CPP_EXTENSIONS = 'CC CPP HPP CXX HXX SQX'
compile endif

/****  The following is all that needs to be modified for adding other languages. *****/


defproc tag_case( filename)
   universal nepmd_hini

   Mode = NepmdGetMode()
   KeyPath = '\NEPMD\User\Mode\'Mode'\CaseSensitive'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   if on then
      searchopt = 'e'  -- case-sensitive
   else
      searchopt = 'c'  -- case-insensitive
   endif
   return searchopt

defproc tags_supported( mode)
   return wordpos( mode, 'C JAVA E ASM REXX PASCAL MODULA REXX CMD HTEXT IPF TEX JAVASCRIPT')

defproc proc_search( var proc_name, first_flag, mode, ext)
   if mode = 'C' then
      return c_proc_search( proc_name, first_flag, ext)
   elseif mode = 'JAVA' then
      return c_proc_search( proc_name, first_flag, ext)
   elseif mode = 'ASM' then
      return asm_proc_search( proc_name, first_flag)
   elseif mode = 'PASCAL' then
      return pas_proc_search( proc_name, first_flag)
   elseif mode = 'MODULA' then
      return pas_proc_search( proc_name, first_flag, 'e')
   elseif mode = 'E' then
      return e_proc_search( proc_name, first_flag)
   elseif mode = 'REXX' then
      return rexx_proc_search( proc_name, first_flag)
   elseif mode = 'CMD' then
      return cmd_proc_search( proc_name, first_flag)
   elseif mode = 'HTEXT' then
      return htext_proc_search( proc_name, first_flag)
   elseif mode = 'IPF' then
      return ipf_proc_search( proc_name, first_flag)
   elseif mode = 'TEX' then
      return tex_proc_search( proc_name, first_flag)
   elseif mode = 'JAVASCRIPT' then
      return javascript_proc_search( proc_name, first_flag)
   else
      return 1
   endif

/****   The above is all that needs to be modified for adding other languages. *****/

const
compile if not defined(TAGS_ANYWHERE)
   TAGS_ANYWHERE = 1          -- Set to 0 if all your procedure definitions start in col. 1
compile endif
compile if not defined(C_TAGS_ANYWHERE)
   C_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(E_TAGS_ANYWHERE)
   E_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(ASM_TAGS_ANYWHERE)
   ASM_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(KEEP_TAGS_FILE_LOADED)
   KEEP_TAGS_FILE_LOADED = 1  -- If you do a lot with tags, you might want to keep the file loaded.
compile endif
   IDENTIFIER_STARTER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_$'


defc tagsfile
   universal tags_file
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'TAGSFILE: arg(1) = 'arg(1))

   orig_name = tags_file
   if arg(1)='' then
      parse value entrybox( TAGSNAME__MSG,
                            '/'SET__MSG'/'SETP__MSG'/'Cancel__MSG'/'Help__MSG'/',
                            tags_filename(),
                            '',
                            200,
                            atoi(1) || atoi(6070) || gethwndc(APP_HANDLE) ||
                            TAGSNAME_PROMPT__MSG) with button 2 newname \0
      if button=\1 | button=\2 then
         tags_file = newname
         if button=\2 & tags_file<>'' then
            call setini('TAGSFILE', tags_file)
         endif
      endif
   else
      tags_file = arg(1)
   endif
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid <> '' & orig_name <> tags_file then  -- New name; drop tags file
      getfileid startfid
      rc = 0
      activatefile tags_fileid
      if rc=0 then 'xcom quit'; endif
      activatefile startfid
   endif
compile endif

defc tagsfile_perm
   universal tags_file
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'TAGSFILE_PERM')
   orig_name = tags_file
   if arg(1) <>'' then
      tags_file = arg(1)
      call setini('TAGSFILE', tags_file)
   endif
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid <> '' & orig_name <> tags_file then  -- New name; drop tags file
      getfileid startfid
      rc = 0
      activatefile tags_fileid
      if rc=0 then 'xcom quit'; endif
      activatefile startfid
   endif
compile endif


defproc tags_filename()
   universal tags_file
   dprintf( 'TAGS', 'TAGS_FILENAME')
   if tags_file='' then
      tags_file=checkini(0, 'TAGSFILE', '')
   endif
   if tags_file='' then
      tags_file=get_env('TAGS.EPM')
   endif
   if tags_file='' then
      tags_file='tags.epm'
   endif
   return(tags_file)

defc find_tag, findtag
   universal CurEditCmd
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'FIND_TAG: arg(1) = 'arg(1))
   button = ''
   file_type = filetype()
   file_mode = NepmdGetMode()

   if arg(1)='' then
      /* Try to find the procedure at the cursor. */
      if substr(textline(.line), .col, 1)='(' then left; endif  -- If on paren, shift

      if file_mode = "REXX" then
         token_separators = ' ~`$%^&*()-+=][{}|\:;/><,''"'\t  -- Rexx accepts '!' & '?' as part of the proc name.
      else
         token_separators = ''  -- Use the default defined in find_token()
      endif
      if not find_token(startcol, endcol, token_separators) then
         return 1
      endif

      -- We cannot avoid to use file extensions in the case of C++, since we do not have a seperate mode for it.
      if (wordpos(file_type, CPP_EXTENSIONS) > 0) | (file_mode = "JAVA" ) then
         if substr(textline(.line), endcol+1, 2)='::' & pos(upcase(substr(textline(.line), endcol+3, 1)), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ$_') then
            savecol = .col
            .col = endcol+3
            if find_token(startcol2, endcol2) then
               endcol = endcol2
            endif
            .col = savecol
         elseif .col>3 then
            if substr(textline(.line), startcol-2, 2)='::' & pos(upcase(substr(textline(.line), startcol-3, 1)), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ$_') then
               savecol = .col
               .col = startcol-3
               if find_token(startcol2, endcol2) then
                  startcol = startcol2
               endif
               .col = savecol
            endif
         endif
      endif

      proc_name = substr(textline(.line), startcol, (endcol-startcol)+1)
      if pos('.', proc_name) then
         proc_name = substr(proc_name, lastpos('.', proc_name)+1)
      endif
   elseif arg(1)='*' then
      parse value entrybox( FINDTAG__MSG,
                            '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/'Help__MSG'/',
                            checkini(0, 'FINDTAG_ARG', ''),
                            '',
                            200,
                            atoi(1) || atoi(6010) || gethwndc(APP_HANDLE) ||
                            FINDTAG_PROMPT__MSG) with button 2 proc_name \0
      if button<>\1 & button<>\2 then return; endif
      if button=\1 then
         call setini('FINDTAG_ARG', proc_name)
      endif
   else
      proc_name = arg(1)
   endif
   getfileid startfid
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid<>'' then
      rc = 0
      display -2
      activatefile tags_fileid
      display 2
      if rc then
         tags_fileid = ''
      else
         0              -- Go to top of file
      endif
   endif
   if tags_fileid='' then
compile endif
      'xcom e /d ' tags_filename()
      if rc then
         if rc=-282 then  -- -282 = sayerror("New file")
            'xcom quit'
            sayerror "Tag file '"tags_filename()"' not found"
         else
            sayerror "Error loading tag file '"tags_filename()"' -" sayerrortext(rc)
         endif
         return 1
      endif
      getfileid tags_fileid
      .visible = 0  -- made it unvisible even if not KEEP_TAGS_FILE_LOADED
compile if KEEP_TAGS_FILE_LOADED
   endif
compile endif
   if button=\2 then  -- List (delayed until tags_file was loaded)
      sayerror BUILDING_LIST__MSG
      'xcom e /c .tagslist'
      if rc<>-282 then  -- -282 = sayerror("New file")
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      getfileid lb_fid
      browse_mode = browse()     -- query current state
      if browse_mode then call browse(0); endif
      .autosave = 0
      .visible = 0
      display -2
      do i=1 to tags_fileid.last
         getline line, i, tags_fileid
         parse value line with tag .
         if tag<>'' & tag<>'*' then
            insertline tag, .last+1
         endif
      enddo
      if browse_mode then call browse(1); endif  -- restore browse state
      display 2
      if not .modify then  -- Nothing added?
         'xcom quit'
compile if KEEP_TAGS_FILE_LOADED
         activatefile startfid
compile else
         'xcom quit'
compile endif
         sayerror NO_TAGS__MSG
         return
      endif
      if listbox_buffer_from_file(tags_fileid, bufhndl, noflines, usedsize) then return; endif
      parse value listbox( LIST_TAGS__MSG,
                           \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                           '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                           0, 0,  --1, 5,
                           min( noflines, 12), 0,
                           gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6012)) with button 2 proc_name \0
      call buffer(FREEBUF, bufhndl)
      if button<>\1 then
compile if KEEP_TAGS_FILE_LOADED
         activatefile startfid
compile else
         'xcom quit'
compile endif
         return
      endif
   endif
   name = proc_name  -- Preserve original name.
compile if 1
   if pos(':', proc_name) then
      grep = 'g'  -- Use the older one, because extended GREP treats colons specially
   else
      grep = 'x'  -- Use the faster one!
   endif
compile else
   tc = pos(':', proc_name)
   if tc then
      temp = ''
      do while tc
         temp = temp || leftstr(proc_name, tc-1) || '\:'
         proc_name = substr(proc_name, tc+1)
         tc = pos(':', proc_name)
      enddo
      proc_name = temp || proc_name
   endif
   grep = 'x'  -- Always use the faster one!
compile endif
   display -2
   tc = tag_case(startfid.filename)
   do i=1 to 2
      'xcom l ^'proc_name' 'grep || tc
      if not rc then leave; endif
      proc_name = '_'proc_name  /* Handle case where C call to assembler function needs '_' */
   enddo
   display 2
   long_msg='.  You may want to rebuild the tag file.'
   if rc then
compile if KEEP_TAGS_FILE_LOADED
      activatefile startfid
compile else
      'xcom quit'
compile endif
      sayerror 'Tag for function "'name'" not found in 'tags_filename()long_msg
      return 1
   endif
   parse_tagline(name, filename, fileline, filedate)
   /* Check if there is more than one */
   if .line < .last then
      found_line = .line
      '+1'
      parse_tagline(next_name, next_filename, next_fileline, next_filedate)
      if upcase(name)=upcase(next_name) then
         getfileid tags_fid
         'xcom e /c .temp'
         if rc<>-282 then  -- -282 = sayerror("New file")
            'xcom quit'
            return 1
         endif
         getfileid temp_fid
         browse_mode = browse()     -- query current state
         if browse_mode then call browse(0); endif
         .autosave = 0
         .visible = 0
         insertline '1. 'filename, 2
         activatefile tags_fid
         i = 2
         loop
            if upcase(next_filename) <> upcase(filename) then
               insertline i'. 'next_filename, temp_fid.last+1, temp_fid
               i = i + 1
            endif
            if .line = .last then
               leave
            endif
            '+1'
            parse_tagline(next_name, next_filename, next_fileline, next_filedate)
            if upcase(name)/==upcase(next_name) then
               leave
            endif
         endloop
         activatefile temp_fid
         .modify = 0
         if browse_mode then call browse(1); endif  -- restore browse state
         if .last>2 then
            if listbox_buffer_from_file(tags_fid, bufhndl, noflines, usedsize) then return; endif
            parse value listbox( 'Select a file',
                                 \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                                 '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                                 0, 0,
                                 min( noflines, 12), 60,
                                 gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6015) ||
;;                               "'"name"' appears in multiple files.") with button 2 filename \0
                                 "'"name"' appears in multiple files.") with button 2 i '.' \0
            call buffer(FREEBUF, bufhndl)
            if button<>\1 then  -- Didn't select OK
               filename = ''
            else
               --fileline = ''; filedate = ''  -- For now, don't try to keep track.
               found_line+i-1     -- Go to the corresponding line, & parse the correct info.
               parse_tagline(name, filename, fileline, filedate)
            endif
         else
            'xcom quit'
         endif
         if filename='' then
compile if KEEP_TAGS_FILE_LOADED
            activatefile startfid
compile else
            'xcom quit'  -- quit tags file
compile endif
            return 1
         endif
      endif  -- duplicate names
   endif  -- not on last line
compile if KEEP_TAGS_FILE_LOADED
   activatefile startfid
compile else
   'xcom quit'  -- quit tags file
compile endif

   -- Get fileid if filename is already in ring  (filename = filename with proc definition)
   getfileid already_loaded, filename
   -- Load file; load new view if already in ring
   CurEditCmd = 'SETPOS'  -- disable RestorePosFromEa
   'e /v' filename
   if rc then
      if rc=-282 then  -- -282 = sayerror("New file")
         'q'
         sayerror "'"filename"' not found"long_msg
      else
         sayerror "Error loading '"filename"' -" sayerrortext(rc)
      endif
      return 1
   endif
   if already_loaded <> '' then
      new_view = .currentview_of_file
   endif
   if tc='e' then  -- case-sensitive
      p = pos(proc_name, textline(fileline))
      lp = lastpos(proc_name, textline(fileline))
   else            -- not case-sensitive
      p = pos(upcase(proc_name), upcase(textline(fileline)))
      lp = lastpos(upcase(proc_name), upcase(textline(fileline)))
   endif
   -- dprintf( 'TAGS', 'FINDTAG: .filename = '.filename', already_loaded = 'already_loaded', p = 'p', lp = 'lp', fileline = 'fileline)
   if fileline & p & (p=lp) then
      -- If found once in fileline
      if already_loaded <> '' then
         sayerror 'File already loaded, starting new view.'
      endif
      .cursory=.windowheight%2  -- vcenter line
      'postme goto 'fileline p
      --fileline
      --.col = p
      if already_loaded <> '' then
         'postme postme activatefile' new_view  -- added; 2x postme required in most cases
      endif
      return
   endif
compile if 0  -- We already checked if the line # was good; the date no longer matters here.
   if filedate<>''  then  -- Line number and file write date preserved
      if filedate=get_file_date(filename) then  -- Same date means file has not been changed,
         'SayHint Jumping straight to line.'
         fileline                               -- so we can jump right to the line.
         .col = 1
         call proc_search(proc_name, 1, file_mode, file_type)
         call prune_assist_array()
         return
      endif
   endif
compile endif
   -- If not found in fileline (file may have been changed) or found multiple times in fileline
   0
   'SayHint Searching for routine.'
   searchrc = proc_search( proc_name, 1, file_mode, file_type)
   call prune_assist_array()
   --sayerror 'Using proc_search for 'proc_name', filename = '.filename
   if searchrc then
      if already_loaded = '' then 'quit' endif
      sayerror proc_name" not found in '"filename"'"long_msg
      return 1
   endif
   if already_loaded <> '' then
      sayerror 'File already loaded, starting new view.'
      'postme postme activatefile' new_view  -- added; 2x postme required in most cases
   endif

defproc parse_tagline(var name, var filename, var fileline, var filedate)
   parse value textline(.line) with name filename fileline filedate .
   if leftstr(filename,1)='"' & (rightstr(filename,1)<>'"' | length(filename)=1) then
      parse value textline(.line) with name ' "'filename'"' fileline filedate .
      filename = '"'filename'"'
   endif

const
   IGNORE_C_KEYWORDS = 'if while switch for case else return ='
compile if not defined(LOG_TAG_MATCHES)
   LOG_TAG_MATCHES = 0
compile endif

defproc c_proc_search( var proc_name, find_first, ext)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif

   fSearchIdentifier = (proc_name == '')
   proc_len = length( proc_name)

   if wordpos( ext, CPP_EXTENSIONS) then  -- Presumably C++,
      colon = ':'                         -- allow colons.
      cpp_decl = '&'                      -- Can have a reference in a declarator
   else                       -- Plain old C, colons are illegal in procedure names.
      colon = ''
      cpp_decl = ''
   endif

   display -2

   if find_first then
      -- Removed the opening paren from the search string
      -- to allow it as first char on the following line.
      if proc_name=='' then
compile if C_TAGS_ANYWHERE
      -- 'xcom l ^:fex'
         'xcom l ^:o[A-Za-z_$].*ex'
compile else
      -- 'xcom l ^[A-Za-z_$].*\(ex'
         'xcom l ^[A-Za-z_$].*ex'
compile endif
      else
;;       'xcom l 'proc_name'e'
      -- 'xcom l 'proc_name':o\(x'
         'xcom l 'proc_name':ox'
      endif
   else
      repeat_find
   endif


   loop
      if rc then
         display 2
         return rc
      endif

      getline line
      line = translate( line, ' ', \t)
compile if LOG_TAG_MATCHES
         if TAG_LOG_FID then
            insertline '  Found line' .line '= "'line'"', TAG_LOG_FID.last+1, TAG_LOG_FID
         endif
compile endif

      -- Determine if match is a substring of something else
      if not fSearchIdentifier then

         if .col > 1 then
            if pos( upcase( substr( line, .col - 1, 1)), IDENTIFIER_STARTER'0123456789') then
               end_line
               repeat_find
               iterate
            endif
         endif
         .col = .col + proc_len
         if pos( upcase( substr( line, .col, 1)), IDENTIFIER_STARTER'0123456789') then
            end_line
            repeat_find
            iterate
         endif
      endif

      do l = 1 to 2

         -- Strip trailing comment
         i = pos( '//', line)
         if i then
            line = leftstr( line, i - 1)
         endif

         -- Strip multi-line comments
         loop
            i = pos( '/*', line)
            if not i then
               leave
            endif
            j = pos( '*/', line, i + 2)
            if j then
               -- line = delstr( line, i, j - i + 2)
               line = overlay( '', line, i, j - i + 2)  -- Keep column alignment
            else
               line = leftstr( line, i - 1)
            endif
         endloop

         if l = 1 then
            -- Save line (required if paren is on next line)
            procline = line
         endif
         --dprintf( .line': line 'l' = 'line)

         -- Go to opening paren
         p = pos( '(', line, .col)
         if p then
            .col = p
            leave
         else
            -- Search paren on next line
            l = l + 1
            if .line = .last | l > 2 then
               leave
               end_line
               repeat_find
               iterate
            endif
            .line = .line + 1
            .col = 1
            line = textline( .line)
            line = translate( line, ' ', \t)
         endif
      enddo

      line = strip( line, 'T')
      if substr( line, .col, 1) = '(' & rightstr( line, 1) <> ';' then
         --dprintf( .line': check 1 passed')

         call psave_pos( save_pos)
         if rightstr( line, 1) <> ')' | pos( '(', line, .col + 1) then
            --dprintf( .line': check 2 passed')

            -- Go to closing paren
;;          .col = pos( '(', line, .col)
            if find_matching_paren() then  -- No match found?
compile if LOG_TAG_MATCHES
               if TAG_LOG_FID then
                  insertline '  ...skipping; no matching paren found.', TAG_LOG_FID.last+1, TAG_LOG_FID
               endif
compile endif
               call prestore_pos( save_pos)
               end_line
               repeat_find
               iterate  -- Keep looking
            endif
            after_paren_ch = leftstr( strip( substr( translate( textline( .line), ' ', \t), .col + 1)), 1)
         else
            after_paren_ch = ' '
         endif
         do while after_paren_ch = ' ' & .line < .last
            '+1'
            after_paren_ch = leftstr( strip( translate( textline( .line), ' ', \t)), 1)
         enddo
         if pos( after_paren_ch, ';),([-+*.=?&|}!<>') then
compile if LOG_TAG_MATCHES
            if TAG_LOG_FID then
               insertline '  ...skipping; after_paren_ch in list.  "'after_paren_ch'"', TAG_LOG_FID.last+1, TAG_LOG_FID
            endif
compile endif
            end_line
            repeat_find
            iterate
         endif
         call prestore_pos( save_pos)

         -- Restore line (required if opening paren was on next line)
         line = procline

         parse value strip( line) with line '('
         proc_name = lastword( line)
         v = verify( upcase( proc_name), IDENTIFIER_STARTER, 'M')
         if not v then
compile if LOG_TAG_MATCHES
            if TAG_LOG_FID then
               insertline '  ...skipping; verify =' v, TAG_LOG_FID.last+1, TAG_LOG_FID
            endif
compile endif
            end_line
            repeat_find
            iterate
         endif

         proc_name = substr( proc_name, v)
         if wordpos( proc_name, IGNORE_C_KEYWORDS) then
compile if LOG_TAG_MATCHES
            if TAG_LOG_FID then
               insertline '  ...skipping; procname "'proc_name'" in ignore list', TAG_LOG_FID.last+1, TAG_LOG_FID
            endif
compile endif
            end_line
            repeat_find
            iterate
         endif

         if verify( upcase( proc_name), IDENTIFIER_STARTER'0123456789'colon) then
compile if LOG_TAG_MATCHES
            if TAG_LOG_FID then
               insertline '  ...skipping; procname "'proc_name'" contains invalid characters', TAG_LOG_FID.last+1, TAG_LOG_FID
            endif
compile endif
            end_line
            repeat_find
            iterate
         endif

         w = words( line)
         if w > 1 then
            if verify( upcase( subword( line, 1, w - 1)), IDENTIFIER_STARTER'0123456789*()[] 'colon||cpp_decl) then
compile if LOG_TAG_MATCHES
               if TAG_LOG_FID then
                  insertline '  ...skipping; character invalid in a declarator appears before "'proc_name'" in:  'line, TAG_LOG_FID.last+1, TAG_LOG_FID
               endif
compile endif
               end_line
               repeat_find
               iterate
            endif
         endif

         if inside_comment( 'C') then
            end_line
            repeat_find
            iterate
         endif

         display 2
compile if LOG_TAG_MATCHES
         if TAG_LOG_FID then
            insertline '  ...accepted; proc_name = "'proc_name'"', TAG_LOG_FID.last+1, TAG_LOG_FID
         endif
compile endif
         return 0

compile if LOG_TAG_MATCHES
      elseif not TAG_LOG_FID then  -- do nothing
      elseif substr( line, .col, 1) <> '(' then
         insertline '  ...skipping; .col =' .col'; char = "'substr( line, .col, 1)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
      elseif rightstr(line,1)=';' then
         insertline '  ...skipping; ends in semicolon; line = "'line'"', TAG_LOG_FID.last+1, TAG_LOG_FID
      else
         insertline '  ...skipping; no idea why.', TAG_LOG_FID.last+1, TAG_LOG_FID
compile endif
      endif

      end_line
      repeat_find

   endloop
   call prune_assist_array()

defproc pas_proc_search( var proc_name, find_first)
   case = arg(3)
   if case = '' then  -- pascal search?
      case = 'c'      -- ignore case
   endif
   proc_len = length(proc_name)
   display -2
   if find_first then
      if case = 'e' then  -- Must be modula search
         Keywords = '(PROCEDURE)'
      else
         Keywords = '(overlay:w|)(pro(cedure|gram)|function)'
      endif
      if proc_name == '' then
          PasIdentifier = '[a-zA-Z_$][a-zA-Z0-9_$.]*'
          'xcom l ^:o'Keywords':w'PasIdentifier':o[\(;\:]x'case
      else
         'xcom l 'proc_name':o[\(;\:]x'case
      endif
   else
      repeat_find
   endif
   loop
      if rc then
         display 2
         return rc
      endif
      getline line
      if proc_len then  -- Determine if match is a substring of something else
         if .col > 1 then
            c = upcase( substr( line, .col-1, 1))
            if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_' then
               end_line; repeat_find; iterate
            endif
         endif
         .col = .col + proc_len
         c = upcase( substr( line, .col, 1))
         if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
            end_line; repeat_find; iterate
         endif
      else
         .col = pos( '(', line)
      endif
      line = translate( line, ' ', \t)
      -- pos function does not support allow c or e option
      if case = 'c' then
         p = pos( ' 'upcase( keywords)'[ \t]', ' 'upcase( line), 1, 'x')
      else
         p = pos( ' 'keywords'[ \t]', ' 'line, 1, 'x')
      endif
      if not p then
         end_line; repeat_find; iterate
      endif
      p = pos( '[\(;\:]', line, 1, 'x')
      if p then
         if substr( line, p, 1) == '(' then
            .col = p
            call psave_pos( save_pos)
            if find_matching_paren() then
               end_line; repeat_find; iterate
            endif
            call prestore_pos( save_pos)
         endif
         if pos( 'forward;', textline( .line)) then
            end_line; repeat_find; iterate
         endif
         if inside_comment( 'PASCAL') then
            repeat_find
            iterate
         endif
         line = substr( line, 1, p - 1)
         sline = strip( line)
         i = lastpos( ' ', sline)
         proc_name = strip( substr( sline, i + 1))
         display 2
         return 0
      endif
      end_line; repeat_find
   endloop

defproc asm_proc_search(var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   display -2
   if find_first then
      if proc_name=='' then
          proc_name=':c'
      endif
compile if ASM_TAGS_ANYWHERE
      'xcom l ^:o'proc_name':wproc(:w|$)xc'
compile else
      'xcom l ^'proc_name':wproc(:w|$)xc'
compile endif
   else
      repeat_find
   endif
   display 2
   parse value translate(textline(.line), ' ', \t) with proc_name .
compile if LOG_TAG_MATCHES
   if TAG_LOG_FID and not rc then
      insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
   endif
compile endif
   return rc

defproc cmd_proc_search(var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   LeadingSpace = ':o'
   display -2
   if find_first then
      if proc_name == '' then
         identifier = '[A-Z_][A-Z0-9_]*'
         search = '^'LeadingSpace'\:'identifier
      else
         search = '^'LeadingSpace'\:'proc_name
      endif
      'xcom l 'search'cx'
   else
      repeat_find
   endif
   display 2
   parse value translate(textline(.line), ' ', \t) with ':'proc_name .
compile if LOG_TAG_MATCHES
   if TAG_LOG_FID and not rc then
      insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
   endif
compile endif
   return rc

defproc htext_proc_search( var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   Spc = ':o'
   display -2
   if find_first then
      if proc_name == '' then
         identifier = '[1-6]'
         search = '^\.'identifier''Spc
         'xcom l 'search'cx'
      endif
   else
      repeat_find
   endif
   display 2
   -- Indent line according to the section type in order to give a better
   -- overview of the structure.
   proc_name = strip( textline(.line))
   parse value word( proc_name, 1) with '.'sectiontype
   if isnum( sectiontype) then
      -- Omit section type itself
      proc_name = subword( proc_name, 2)
      -- Indent line according to the section type
      ind = copies( ' ', 8)
      proc_name = copies( ind, sectiontype - 1)''proc_name
   endif
compile if LOG_TAG_MATCHES
   if TAG_LOG_FID and not rc then
      insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
   endif
compile endif
   return rc

defproc ipf_proc_search( var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   Spc = ':o'
   display -2
   if find_first then
      if proc_name == '' then
         identifier = '[1-6]'
         search = '^\:h'identifier''Spc'.*\.'
         'xcom l 'search'cx'
      endif
   else
      repeat_find
   endif
   display 2
   -- Indent line according to the section type in order to give a better
   -- overview of the structure.
   line = strip( textline(.line))
   parse value word( line, 1) with ':h'sectiontype rest
   parse value sectiontype with sectiontype'.'
   if isnum( sectiontype) then
      proc_name = ''
      -- find trailing dot
      startl = .line
      stopl  = startl + 2
      do l = startl to stopl
         p = pos( '.', line)
         -- count quotes before '.'; if odd, then '.' must belong to a string
         if p > 0 then
            nQ = 0
            pStartQ = 1
            do while pStartQ < p
               pQ = pos( "'", line, pStartQ)
               if pQ = 0 | pQ > p then
                  leave
               endif
               nQ = nQ + 1
               pStartQ = pQ + 1
            enddo
            if (nQ // 2 = 0) then
               -- this dot must end a tag
               proc_name = substr( line, p + 1)
            else
               -- reset p
               p = 0
            endif
         endif
         if p = 0 then
            -- append next line
            line = line textline( l + 1)
            iterate
         endif
      enddo
      if p = 0 then
         return 1
      endif
      -- Indent line according to the section type
      ind = copies( ' ', 8)
      proc_name = copies( ind, sectiontype - 1)''proc_name
   endif
compile if LOG_TAG_MATCHES
   if TAG_LOG_FID and not rc then
      insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
   endif
compile endif
   return rc

defproc javascript_proc_search( var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   LeadingSpace = ':o'
   display -2
   proc_len = length( proc_name)
   if find_first then
      if proc_name == '' then
         identifier = ':c'
         search = '^'LeadingSpace'function:w'identifier
      else
         search = '^'LeadingSpace'function:w'proc_name
      endif
      'xcom l 'search'ex'
   else
      repeat_find
   endif
   loop
      if rc then
         display 2
         return rc
      endif
      parse value translate(textline(.line), ' ', \t) with . proc_name .
      if inside_comment( 'JAVASCRIPT') then
         repeat_find
         iterate
      endif
      if proc_len then
         if length(proc_name) <> proc_len then  -- a substring of something else
            end_line
            repeat_find
            iterate
         endif
      endif
compile if LOG_TAG_MATCHES
      if TAG_LOG_FID and not rc then
         insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
      endif
compile endif
      leave
   endloop
   display 2
   return rc

defproc e_proc_search( var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif

compile if E_TAGS_ANYWHERE
   LeadingSpace = ':o'
compile else
   LeadingSpace = ''
compile endif

   fSearchIdentifier = (proc_name == '')

   -- Process previously stored defc command names first, if any.
   -- This handles defc cmd1, cmd2, ...
   getfileid fid
   if fSearchIdentifier then
      NextProcs = GetAVar( 'e_tag_next_procs.'fid)
      if NextProcs <> '' then
         proc_name = word( NextProcs, 1)
         call SetAVar( 'e_tag_next_procs.'fid, subword( NextProcs, 2))
         return 0
      endif
   else
      call DelAVar( 'e_tag_next_procs.'fid)
   endif

   display -2

   if find_first then
      Identifier = '[A-Z_][A-Z0-9_]*'
      if fSearchIdentifier then
         search = 'DEF(PROC|KEYS|C):w\c'Identifier
      else
         search = 'DEF(((PROC|KEYS):w)|(C:w(|.*,:o)))\c'proc_name'~:r'
      endif
      search = '^'LeadingSpace''search
      'xcom l 'search'cx'
   else
      repeat_find
   endif

   lrc = rc
   if lrc then
      display 2
      return lrc
   endif

   Col = GetPmInfo( EPMINFO_SEARCHPOS)
   Len = GetPmInfo( EPMINFO_LSLENGTH)
   ThisLine  = translate( textline(.line), ' ', \t)
   FoundProc = substr( ThisLine, .col, Len - .col + 1)
   RestLine  = substr( ThisLine, Len - Col + 2)
   proc_name = FoundProc

   if inside_comment( 'E') then
      repeat_find
   endif

   display 2

   --dprintf( 'rc from xcom l 'search'cx =' lrc', len = 'len', col = 'col', .col = '.col', FoundProc = ['FoundProc']')
   --call highlight_match()
compile if LOG_TAG_MATCHES
   if TAG_LOG_FID
      insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
   endif
compile endif

   -- Store multiply defined command names in an array var.
   -- This handles defc cmd1, cmd2, ...
   NextProcs = ''
   if fSearchIdentifier then
      if upcase( word( ThisLine, 1)) = 'DEFC' then

         parse value RestLine with RestLine '='
         RestLine = strip( RestLine)
         --dprintf( 'RestLine = ['RestLine']')

         do while leftstr( RestLine, 1) = ','
            parse value RestLine with ',' Rest
            Rest = strip( Rest)

            if pos( ',', Rest) then
               parse value Rest with Next ',' Rest
               RestLine = ','strip( Rest)
            else
               Next = Rest
               RestLine = ''
            endif

            Next = strip( Next)
            --dprintf( 'FoundProc = ['Next']')
compile if LOG_TAG_MATCHES
            if TAG_LOG_FID
               insertline '  Found proc_name = "'proc_name'" in line' .line '= "'textline(.line)'"', TAG_LOG_FID.last+1, TAG_LOG_FID
            endif
compile endif

            NextProcs = strip( NextProcs Next)
         enddo
         call SetAVar( 'e_tag_next_procs.'fid, NextProcs)
      endif
   endif

   return lrc

compile if not defined( TAG_REXX_EXACT_SEARCH)
const
   -- TAG_REXX_EXACT_SEARCH = 1 uses the defs from ASSIST.E to find comments
   -- and strings. It's slow for large REXX files.
   TAG_REXX_EXACT_SEARCH = 0
compile endif

defproc rexx_proc_search(var proc_name, find_first)
compile if LOG_TAG_MATCHES
   universal TAG_LOG_FID
compile endif
   display -2
   if find_first then
      if proc_name=='' then
         'xcom l ^:o:r\:xe'  -- Exact case is faster, & the :r doesn't care about case.
      else
         'xcom l 'proc_name':c'  -- Must do case-insensitive search.
      endif
   else
      repeat_find
   endif
   proc_len = length(proc_name)
   loop

      if rc then
         display 2
         return rc
      endif
      getline line
--    line=translate(line, ' ', \t)
compile if LOG_TAG_MATCHES
      if TAG_LOG_FID then
         insertline '  Found line' .line '= "'line'"', TAG_LOG_FID.last+1, TAG_LOG_FID
      endif
compile endif

      colon = pos(':', line, .col)
      if proc_len then  -- Determine if match is a substring of something else
         if .col>1 then
            c = upcase(substr(line, .col-1, 1))
            if (c>='A' & c<='Z') | (c>='0' & c<='9') | c='!' | c='?' | c='_'  then
               .col = colon + 1
               repeat_find
               iterate
            endif
         endif
      endif

      i = 1
      loop
         -- Remove single-line comments & quotes
         c=pos('/*',line, i)
         a=pos("'",line, i)
         q=pos('"',line, i)
         if not c & not a & not q then leave; endif
         if c & (not a | a>c) & (not q | q>c) then  -- Open Comment appears first
            j=pos('*/', line, i+2)
            if j then
               line=overlay('', line, c, j-c+2)  -- Keep column alignment
            else
               line=leftstr(line, c-1)
            endif
         else                           -- Single or double quote appears first
            if not q then               -- Figure out which it is...
               q = a;
            elseif a then
               q = min(q, a)
            endif
            j=pos(substr(line, q, 1), line, q+1)
            if j then
               line=overlay('', line, q, j-q+1)  -- Keep column alignment
            else
               line=leftstr(line, q-1)
            endif
         endif
      endloop

      if substr(line, colon, 1)<>':' then  -- Was in a comment or quoted string
compile if LOG_TAG_MATCHES
         if TAG_LOG_FID then
            insertline "  ...skipping; ':' inside a comment or string.", TAG_LOG_FID.last+1, TAG_LOG_FID
         endif
compile endif
         .col = colon + 1
         repeat_find
         iterate
      endif

compile if TAG_REXX_EXACT_SEARCH
      if inside_comment( 'REXX') then
         --.col = colon + 1
         end_line
         repeat_find
         iterate
      endif
/*
      if inside_literal( 'REXX') then
         --.col = colon + 1
         repeat_find
         iterate
      endif
*/
compile endif

      display 2
      parse value substr(textline(.line), .col) with proc_name ':'
compile if LOG_TAG_MATCHES
      if TAG_LOG_FID then
         insertline '  ...accepted; proc_name = "'proc_name'"', TAG_LOG_FID.last+1, TAG_LOG_FID
      endif
compile endif
      return 0

   endloop

/** Additions by VK **/
defproc tex_proc_search( var proc_name, find_first)
   tc = ''
   proc_len = length( proc_name)
   display -2
   if find_first then
      keywords='\\(part|chapter|(|sub|subsub)section|(|sub)paragraph|label|caption)(|\*):o({|\[)'
      if proc_name=='' then
         'xcom l 'keywords'xc'
      else
         'xcom l 'proc_name''tc
      endif
   else
      repeat_find
   endif
   loop
      if rc then
         display 2
         return rc
      endif
      getline line
      if proc_len then  -- Determine if match is a substring of something else
         if .col > 1 then
            c = upcase( substr( line, .col - 1, 1))
            if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
               end_line
               repeat_find
               iterate
            endif
         endif
         .col = .col + proc_len
         c = upcase( substr( line, .col, 1))
         if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
            end_line
            repeat_find
            iterate
         endif
      else
         .col = pos( keywords, line, 1, 'x')
      endif
      line = translate( line, ' ', \t)
      col = .col
      if not pos( keywords, line, 1, 'x'/*||tc*/) then
         end_line
         repeat_find
         iterate
      endif
      p = pos( '{', line, col)
      if p then
         if substr( line, p, 1) == '{' then
            .col = p
         endif
         line = substr( line, col)
         i = lastpos( '}', strip( translate( line, ' ' ,\t)))
         if i then
           proc_name = substr( line, 1, i + 1)
         else
           proc_name = line
         endif
         test = substr( proc_name, 2, 5)
         if test == 'subse' then
            proc_name = '   'proc_name
         elseif test == 'subsu' then
            proc_name = '      'proc_name
         elseif (test == 'parag') | (test == 'subpa') then
            proc_name = '       'proc_name
         elseif test == 'capti' then
            proc_name = '       'proc_name
         elseif test == 'label' then
            proc_name='         'proc_name
         endif
         display 2
         return 0
      endif
      end_line
      repeat_find
   endloop

defc make_tags
   'maketags' arg(1)

defproc find_matching_paren
   n = 1
   getsearch search_command -- Save user's search command.
   display -2
   'xcom l /[\(\)]/ex+F'
   loop
      repeatfind
      if rc then
         leave
      endif
      if substr( textline(.line), .col, 1) = '(' then
         n = n + 1
      else
         n = n - 1
      endif
      if n = 0 then
         leave
      endif
   endloop
   display 2
   setsearch search_command -- Restores user's command so Ctrl-F works.
   return rc  /* 0 if found, else sayerror('String not found') */

defproc get_file_date(filename)
   pathname = filename\0
   resultbuf = copies( \0, 30)
   ca = dynalink32( 'DOSCALLS',      /* dynamic link library name       */
                    '#223',           /* ordinal value for DOS32QueryPathInfo  */
                    address(pathname)         ||  -- pathname to be queried
                    atol(1)                   ||  -- PathInfoLevel
                    address(resultbuf)        ||  -- buffer where info is to be returned
                    atol( length(resultbuf)))     -- size of buffer
   return ltoa( substr( resultbuf, 9, 4), 16)

defc QueryTagsFiles
   universal app_hini
   parse arg hwnd .
   App = INI_TAGSFILES\0
   inidata = copies( ' ', MAXCOL)
   l = dynalink32( 'PMSHAPI',
                   '#115',               -- PRF32QUERYPROFILESTRING
                   atol(app_hini)    ||  -- HINI_PROFILE
                   address(App)      ||  -- pointer to application name
                   atol(0)           ||  -- Key name is NULL; returns all keys
                   atol(0)           ||  -- Default return string is NULL
                   address(inidata)  ||  -- pointer to returned string buffer
                   atol(MAXCOL), 2)      -- max length of returned string

   if not l then  -- No tagsfiles saved
      if tags_filename() <> '' then
         maketags_parm = checkini( 0, 'MAKETAGS_PARM', '')
         if maketags_parm <> '' then
            call windowmessage( 0, hwnd,
                                32,               -- WM_COMMAND - 0x0020
                                mpfrom2short( 1, 4),  -- This is the default (and only one)
                                put_in_buffer( tags_filename()))
;           'querytagsfilelist' hwnd tags_filename()
         endif
      endif
      return
   endif
   inidata = leftstr( inidata, l)

   tagsfileU = upcase( tags_filename())  -- loop invariant
   do while inidata <> ''
      parse value inidata with tagsname \0 inidata
      call windowmessage( 0, hwnd,
                          32,               -- WM_COMMAND - 0x0020
                          mpfrom2short( (upcase( tagsname) = tagsfileU), 4),
                          put_in_buffer( tagsname))
      'querytagsfilelist' hwnd tagsname
   enddo

defc QueryTagsFileList
   parse arg hwnd tagsname
   call windowmessage( 0, hwnd,
                       32,               -- WM_COMMAND - 0x0020
                       5,
                       put_in_buffer( TagsFileList( tagsname)))

defproc TagsFileList(tagsname)
   universal app_hini
   App = INI_TAGSFILES\0
   tagsnameZ = upcase(tagsname)\0
   inifilelist = copies(' ', MAXCOL)
   l = dynalink32('PMSHAPI',
                  '#115',               -- PRF32QUERYPROFILESTRING
                  atol(app_hini)       ||  -- HINI_PROFILE
                  address(App)         ||  -- pointer to application name
                  address(tagsnameZ)   ||  -- Return value for this key
                  atol(0)              ||  -- Default return string is NULL
                  address(inifilelist) ||  -- pointer to returned string buffer
                  atol(MAXCOL), 2)         -- max length of returned string
   if not l then  -- Not found in .INI file; try the TAGS file's EA
      getfileid startfid
      getfileid fid, tagsname
      continue = 1
      if not fid then
         'xcom e' tagsname
         if rc then
            continue = 0
            if rc=sayerror('New file') then
               'xcom quit'
            endif
         endif
      else
         activatefile fid
      endif
      if continue then
         inifilelist = get_EAT_ASCII_value('EPM.TAGSARGS')
         l = length(inifilelist)
         if not fid then
            'xcom quit'
         endif
      endif
      activatefile startfid
   endif
   list = leftstr( inifilelist, l)
   list = strip( list, 'B', \0)  -- required
   return list


defc poptagsdlg
   dprintf( 'TAGS', 'POPTAGSDLG')
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5158,               -- EPM_POPCTAGSDLG
                      0,
                      0)

defc tagsdlg_make
   universal appname, app_hini
   dprintf( 'TAGS', 'TAGSDLG_MAKE: arg(1) (tagsfilename maketagsargs) = 'arg(1))
   parse arg tagsfilename maketagsargs
   if maketagsargs='' then sayerror -263; return; endif  -- "Invalid argument"
   call setprofile(app_hini, INI_TAGSFILES, upcase(tagsfilename), maketagsargs)
   'tagsfile' tagsfilename
   'maketags' maketagsargs

defc add_tags_info
   universal appname, app_hini
   parse arg tagsfilename maketagsargs
   if maketagsargs='' then sayerror -263; return; endif  -- "Invalid argument"
   call setprofile(app_hini, INI_TAGSFILES, upcase(tagsfilename), maketagsargs)

defc delete_tags_info
   universal appname, app_hini
   if arg(1)='' then sayerror -263; return; endif  -- "Invalid argument"
   call setprofile(app_hini, INI_TAGSFILES, upcase(arg(1)), '')

defc tagscan
   universal vepm_pointer
   file_type = filetype()
   file_mode = NepmdGetMode()
   if not tags_supported(file_mode) then
      sayerror "Don't know how to do tags for file of mode '"file_mode"'"
      return 1
   endif

   call psave_pos(savepos)
   0
   getfileid sourcefid
   'xcom e /c .tagslist'
   if rc<>-282 then  -- -282 = sayerror("New file")
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   getfileid lb_fid
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   .autosave = 0
   .visible = 0
   activatefile sourcefid
   proc_name=''
   mouse_setpointer WAIT_POINTER
   sayerror 'Searching for procedures...'
   rc = proc_search( proc_name, 1, file_mode, file_type)
   while not rc do
      insertline proc_name '('.line')', lb_fid.last+1, lb_fid
      proc_name=''
      end_line
      rc=proc_search(proc_name, 0, file_mode, file_type)
   endwhile
   call prune_assist_array()
   call prestore_pos(savepos)
   if browse_mode then call browse(1); endif  -- restore browse state
   activatefile lb_fid
   sayerror 0
   mouse_setpointer vepm_pointer

   if not .modify then  -- Nothing added?
      'xcom quit'
      activatefile sourcefid
      sayerror NO_TAGS__MSG
      return
   endif

   if listbox_buffer_from_file(sourcefid, bufhndl, noflines, usedsize) then return; endif
   parse value listbox( LIST_TAGS__MSG,         -- title
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),  -- buffer
                        '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,               -- buttons
                        0, 0,  -- 25, 15        -- top (0 = at cursor), left (0 = at cursor)
                        min( noflines, 20), 0,  -- height, width (0 = auto)
                        gethwndc(APP_HANDLE) ||
                        atoi(1) ||              -- default item
                        atoi(1) ||              -- default button
                        atoi(6012)) with button 2 proc_name \0  -- help panel id
   call buffer(FREEBUF, bufhndl)
   if button<>\1 then
      return
   endif
   -- Determine procname from list item, strip indent and linenum
   parse value strip( proc_name) with procname ' (' linenum ')'
   linenum; .col = 1
   -- Locate procname in line, don't use the user's search options and suppress msgs
   display -2
   'xcom l '\1''procname
   display 2

