/****************************** Module Header *******************************
*
* Module Name: all.e
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
/* This command will create a new file showing all occurrances of the */
/* search string given.  Syntax:  ALL /find_string[/[c]]              */
/* where / can be any delimiter, and c means ignore case.             */
/*                                                                    */
/* The key c_Q is set up so that if you press it while in the .ALL    */
/* file, it will position you on the corresponding line in the        */
/* original file.  If you are not in .ALL, you will be placed there   */
/* and the cursor will be moved down one line.  This enables you to   */
/* rapidly switch from .ALL to succeeding lines of the original.      */
/*                                                                    */
/* Set ALL_HIGHLIGHT_COLOR in your MYCNF.E to have the "hits"         */
/* highlighted in the .all file.  E.g.,                               */
/*    compile if defined(BLACK)                                       */
/*    define                                                          */
/*       ALL_HIGHLIGHT_COLOR = Magenta + Yellowb                      */
/*    compile endif                                                   */
/*                                                                    */
/* Author:  Larry Margolis, MARGOLI at YORKTOWN                       */

compile if not defined(SMALL)  -- If being externally compiled...
 define INCLUDING_FILE = 'ALL.E'
const
   tryinclude 'MYCNF.E'
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

defmain
   'All' arg(1)
compile endif

; ---------------------------------------------------------------------------
; ALL macro
defc All
   universal allorig
   universal allsrch
   universal default_search_options
   universal activeaccel

   allsrch = strip( arg(1), 'L')
   if allsrch = '' or allsrch = '/' then
      sayerror 'All: Error: search string is missing.'
      return
   endif

   call psave_pos(save_pos)
   getfileid allorig

   if GetAVar( 'prevkeyset.'allorig) = '' then
      -- Save previous keyset
      call SetAVar( 'prevkeyset.'allorig, activeaccel)
      -- Extend keyset
      'SetKeyset all' activeaccel'value' 'all'
   endif

   -- Rename previous .ALL file, if found
   getfileid prevallfile, '.ALL'
   if prevallfile <> '' then
      prevallfile.filename = '.prev_ALL'
   endif

   -- Create new .ALL file
   'e /q /n .ALL'    -- Don't use XCOM so can handle either windowing style
   .filename = '.ALL'
   getfileid allfile
   -- Extend keyset
   'PostMe SetKeyset all' activeaccel'value' 'all'  -- PostMe required
   for i = 1 to .last
      deleteline 1
   endfor

   activatefile allorig

   -- Copied from DEFC L - we only will use E or C (case) and A or M (mark)
   DSO = ''   -- DSO = subset of default_search_options
   do i = 1 to length( default_search_options)
      ch = substr( default_search_options, i, 1)
      if pos( ch, 'EeCcAaMm') > 0 then
         DSO = DSO''ch
      endif
   end
   -- Insert default_search_options just before supplied options (if any)
   -- so the supplied options will take precedence.
;   if DSO then
      ch = substr( allsrch, 1, 1)
      p  = pos( ch, allsrch, 2)
      user_options = ''
      if p > 0 then
         user_options = substr( allsrch, p + 1)
         allsrch      = substr( allsrch, 1, p - 1)
      endif
      allsrch = allsrch''ch''DSO''user_options
;   endif
   last_line = .last
   if pos( 'M', upcase(DSO''user_options)) > pos( 'A', upcase(DSO''user_options)) then
      getmark line, last_line  -- /x/m will move to start of mark if past end!
   endif

   -- Append U (new feature) to disable T or B option. Otherwise All will not work.
   allsrch = allsrch'U'

   0  -- move cursor on line 0
   display -3
   do forever
      .col = 1
      'xcom l' allsrch
      if rc = -273 then  -- sayerror("String not found")
         leave
      endif
      getline line
      -- Prepend line no
      line = rightstr( .line, 5) line
      insertline line, allfile.last + 1, allfile
      if .line = last_line then
         leave
      endif
      '+1'
   end
   display 3
   call prestore_pos( save_pos)
   if allfile.last = 0 then
      activatefile allfile
      .modify = 0
      'q'
      sayerror -273  -- sayerror("String not found")
      'AllEndSwitchFiles'
      return
   endif
   sayerror 0
   activatefile allfile
   sayerror 0
   .modify = 0
   top
   .col = 7
   'PostMe l' allsrch'A'  -- Position cursor under first hit.
                          -- Use l, not xcom l to highlight hit.
   AllKey = strip( MenuAccelString( 'AllSwitchFiles'), 'l', \9)
   'SayHint Press 'AllKey' to switch between this and the original file'

; ---------------------------------------------------------------------------
; Shows the .ALL file's current line in the original file
defc AllSwitchFiles
   universal allorig
   universal allsrch
   universal activeaccel
   if .filename <> '.ALL' then
      getfileid allfile, '.ALL'
      if allfile = '' then
         sayerror NO_ALL_FILE__MSG
         'AllEndSwitchFiles'
      else
         activatefile allfile
         -- Scroll the .ALL file a la FILEMAN.
         if .line = .last then
            top
         elseif .last <= (.windowheight - 2) then         -- no need to scroll
            .cursory = .cursory + 1
         elseif .line < (.windowheight%2) then            -- no need to scroll - yet
            .cursory = .cursory + 1
         elseif (.last - .line) < (.windowheight%2) then  -- === Bot === on screen
            .cursory = .cursory + 1
         else                                       -- Scroll!
            '+1'
            oldlinenum = .line
            .cursory = (.windowheight + 1)%2        -- Center vertically
            oldlinenum
         endif
         .col = 6  -- Skip line number for search
         'l' allsrch'A'  -- Match on first .ALL line is not highlighted, even not with PostMe
      endif
      return
   endif  -- .filename <> '.ALL'
   getline line
   parse value line with linenum .
   if not isnum( linenum) then
      sayerror BAD_ALL_LINE__MSG
      'AllEndSwitchFiles'
      return
   endif
   activatefile allorig
   'SetKeyset all' activeaccel'value' 'all'  -- ensure that orig file has 'all' keyset
   .cursory = .windowheight%2                       -- Center vertically
   linenum
   .col = 1
   'PostMe l' allsrch'A'  -- Use l, not xcom l to highlight hit, PostMe required

; ---------------------------------------------------------------------------
defc AllEndSwitchFiles
   universal allorig
   -- Restore keyset
   activatefile allorig
   PrevKeyset = GetAVar( 'prevkeyset.'allorig)
   'SetKeyset' PrevKeyset

