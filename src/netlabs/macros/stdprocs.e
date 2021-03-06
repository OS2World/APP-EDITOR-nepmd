/****************************** Module Header *******************************
*
* Module Name: stdprocs.e
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

; A useful subroutine:  asks "Are you sure (Y/N)?" (same as DOS's prompt
; after "erase *.*") and returns uppercase keystroke.
; If called with a string parameter, displays it at start of prompt, e.g.
;   usersays = askyesno("About to erase.")
;   ==>   "About to erase. Are you sure (Y/N)? "
; EPM 5.12B:  Now enabled for EPM, using entrybox().  Optional second argument
; is a flag to prevent the "Are you sure" from being appended.
; EPM 5.15:  Now uses WinMessageBox to get Yes, No buttons.  [\toolktxx\c\include\pmwin.h]
; 93/12/15:  Added optional 3rd arg for messagebox title.
defproc askyesno
   prompt = arg(1)
   if not arg(2) then
      prompt = prompt\13 || ARE_YOU_SURE__MSG
   endif
   return substr( YES_CHAR || NO_CHAR, winmessagebox( arg(3),
                                                      prompt,
                                                      16388) - 5,
                                                      1)  -- YESNO + MOVEABLE

; Common routine, save space.  from Jim Hurley.
; Check if current file is marked. If not, stop further processing of
; calling command or procedure. (Changed from any to current file.)
defproc checkmark()
   if not FileIsMarked() then
      sayerror NO_MARK_HERE__MSG
      stop
   endif

; Routine to tell if a mark is visible on the screen.  (Actually, only on the
; current window; if the window is less than full size, a mark could be visible
; in an inactive window without our being able to tell.)  Also, if a character
; mark begins above the top of the window and ends below the bottom, and the
; window contains only blank lines, then this routine will return 1 (since the
; mark spans the window) even though no sign of the mark will be visible.
defproc check_mark_on_screen =
   if not FileIsMarked() then
      return 0  -- If no mark, then not on screen.
   endif
   getmark first_mark_line, last_mark_line, first_mark_col, last_mark_col
   first_screen_line = .line - .cursory + 1
   last_screen_line = .line - .cursory + .windowheight
   if last_mark_line < first_screen_line then
      return 0
   endif
   if first_mark_line > last_screen_line then
      return 0
   endif
   no_char_overlap = marktype() <> 'CHAR' or first_mark_line=last_mark_line
   if last_mark_col < .col - .cursorx + 1 and
      (no_char_overlap or last_mark_line=first_screen_line) then
      return 0
   endif
   if first_mark_col > .col - .cursorx + .windowwidth and
      (no_char_overlap or first_mark_line=last_screen_line) then
      return 0
   endif
   return 1

; ---------------------------------------------------------------------------
; Syntax: fOnScreen = OnScreen( [line], [col])
defproc OnScreen
   y = arg(1)
   x = arg(2)
   if y = '' then
      y = .line
   endif
   if x = '' then
      x = .col
   endif
   topline  = .line - .cursory + 1
   botline  = .line - .cursory + .windowheight
   leftcol  = .col  - .cursorx + 1
   rightcol = .col  - .cursorx + .windowwidth

   fOnScreen = 0
   if     y < topline then
   elseif y > botline then
   elseif x < leftcol then
   elseif x > rightcol then
   else
      fOnScreen = 1
   endif

   return fOnScreen

; ---------------------------------------------------------------------------
; Replace all UNNAMED_FILE_NAME consts with GetUnnamedFileName()
; The universal var is set in MAIN.E.
defproc GetUnnamedFileName
   universal unnamedfilename
   return unnamedfilename

; ---------------------------------------------------------------------------
; Does an atol of its argument, then a word reversal and returns the result.
defproc atol_swap( num)
   hwnd = atol( num)
   return rightstr( hwnd, 2) || leftstr( hwnd, 2)

defproc dec_to_string( string)    -- for dynalink usage
   line = ''
   for i = 1 to length( string)
     line= line''asc( substr( string, i, 1))' '
   endfor
   return line

; Returns true if parameter given is a number.
; Leading and trailing spaces are ignored.
defproc isnum
   zzi=pos( '-',arg(1))          -- Optional minus sign?
   if zzi then                   -- If there is one,
      parse arg zz1 '-' zz zz2   --   zz1 <- before it, zz <- number, zz2 <- after
   else
      parse arg zz zz1 zz2       --   zz <- number; zz1, zz2 <- after it
   endif
   zz = strip( zz)               -- Delete leading & trailing spaces.
   if zz1''zz2 <> '' or          -- If there were more tokens on the line
      zz == '' then              -- or if the result is null
      return 0                   -- then not a number.
   endif
   if pos( DECIMAL, zz) <> lastpos( DECIMAL, zz) then
      return 0
   endif
   return not verify( zz, '0123456789'DECIMAL)  -- Max. of one decimal point.

defproc min( a, b)  -- Support as many arguments as E3 will allow.
   minimum = a
   do i = 2 to arg()
      if minimum > arg(i) then
         minimum = arg(i)
      endif
   end
   return minimum

defproc max( a, b)  -- Support as many arguments as E3 will allow.
   maximum = a
   do i = 2 to arg()
      if maximum < arg(i) then
         maximum = arg(i)
      endif
   end
   return maximum

; ---------------------------------------------------------------------------
defproc isoption( var cmdline, optionletter)
   i = pos( argsep''upcase( optionletter), upcase( cmdline))
   if i then
      cmdline = delstr( cmdline, i, 2)
      return 1
   endif

defproc joinlines()
   if .line < .last and .line then
      oldcol = .col
      down                    -- ensure one space at start of second line
      call pfirst_nonblank()
      col2 = .col
      .col = 1
      getsearch savesearch
      if col2 >= 2 then       -- Shift line left if >2, or replace possible leading tab w/ space if ==2.
         -- LAM:  Following line is wrong now that pfirst_nonblank() also skips tabs.
         --'xcom c/'copies(' ',col2-2)'//'  -- Change first n-1 blanks to null
         --'xcom c/'leftstr(textline(.line), col2-1)'/ /'  -- Change leading blanks/tabs to a single space
         'xcom c '\1''leftstr( textline( .line), col2 - 1)\1' '\1  -- Change leading blanks/tabs to a single space
      elseif col2 = 1 then    -- Shift line right
         -- 'xcom c/^/ /g'    -- insert a space at beginning of line
         i = insert_state()
         if not i then insert_toggle endif
         keyin ' '
         if not i then insert_toggle endif
      endif
      setsearch savesearch
      up                      -- ensure no spaces at end of first line
      .col = length( strip( textline( .line), 'T')) + 1
      erase_end_line
      .col = oldcol
      join
   endif

; ---------------------------------------------------------------------------
; PBEGIN_MARK: this procedure moves the cursor to the first character of the
; mark area.  If the mark area is not in the active file, the marked file is
; activated.
defproc pbegin_mark
   if marktype() = '' then
      sayerror NO_MARK_HERE__MSG
      stop
   endif
   getmark firstline, lastline, firstcol, lastcol, fileid
   activatefile fileid
   --firstline
   .lineg = firstline  -- .lineg suppresses scrolling, if cursor in window
   if marktype() <> 'LINE' then
      .col = firstcol
   endif

; PEND_MARK: moves the cursor to the end of the marked area
defproc pend_mark
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
   if marktype() = '' then
      sayerror NO_MARK_HERE__MSG
      stop
   endif
   getmark firstline, lastline, firstcol, lastcol, fileid
   activatefile fileid
   if marktype() <> 'LINE' then
      .col = lastcol
compile if WANT_DBCS_SUPPORT
      if ondbcs then
         if .col > lastcol then -- Must have been in the middle of a DBC.
            .col = lastcol - 1
         endif
      endif
compile endif
   endif
   --lastline
   .lineg = lastline  -- .lineg suppresses scrolling, if cursor is in window

; PBEGIN_WORD: moves the cursor to the beginning of the word if the cursor is on
; this word.  If it's not on a word, it's moved to the beginning of the first
; word on the left.  If there is no word on the left it's moved to the beginning
; of the word on the right.  If the line is empty the cursor doesn't move.
defproc pbegin_word
   getline line, .line
   line = translate( line, ' ', \9)  -- handle tabs correctly
   if substr( line, .col, 1) = ' ' then
      p = verify( line, ' ')     /* 1st case: the cursor on a space */
      if p >= .col then
         .col = p
      else
         if p then
            q = p
            loop
               p = verify( line, ' ', 'M', p)
               if not p or p > .col then
                  leave
               endif
               p = verify( line, ' ', '', p)
               if not p or p > .col then
                  leave
               endif
               q = p
            endloop
            .col = q
         endif
      endif
   else
      if .col <> 1 then          /* 2nd case: not on a space */
         .col = lastpos( ' ', line, .col) + 1
      endif
   endif

; PEND_WORD: moves the cursor to the end of the word if the cursor is on this
; word.  If it's not on a word, it's moved to the end of the first word on the
; right.  If there is no word on the right it's moved to the end of the word on
; the left.  If the line is empty the cursor doesn't move.
defproc pend_word
   getline line, .line
   line = translate( line, ' ', \9)  -- handle tabs correctly
   if  substr( line, .col, 1) = ' ' then
      if substr( line, .col) = ' ' then
         if  line <> ' ' then
            for i = .col to 2 by -1
               if substr( line, i - 1, 1) <> ' ' then
                  leave
               endif
            endfor
           .col = i - 1
         endif
      else
         p = verify( line,    ' ', '', .col)
         p = verify( line' ', ' ', 'M', p)
         .col = p - 1
      endif
   else
      if .col <> MAXCOL then
         i = pos( ' ', line, .col)
         if i then
            .col = i - 1
         else
            .col = length( line)
         endif
      endif
   endif

; ---------------------------------------------------------------------------
; PBLOCK_REFLOW: reflow the text in the marked area.  Then the destination block
; area must be selected and a second call to this procedure reflow the source
; block in the destination block.  The source block is fill with spaces.
;   option=0 saves the marked block in temp file
;   option=1 reflow temp file text and copies it to marked area
; Changed: Stop if not current file is marked.
defproc pblock_reflow( option, var spc, var tempofid)
   call checkmark()
   if not option then
      usedmk=marktype()
      getmark firstline1, lastline1, firstcol1, lastcol1, fileid1
      /* move the source mark to a temporary file */
      'xcom e /c .tempo'
      if rc<>sayerror('New file') then
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return rc
      endif
      .visible = 0                                  -- Make hidden
      getfileid tempofid
      activatefile tempofid
      call pcopy_mark()
      activatefile fileid1
      call pset_mark( firstline1, lastline1, firstcol1, lastcol1, usedmk, fileid1)
      if usedmk = 'LINE' then
         begin_line
      endif
      spc = usedmk firstline1 lastline1 firstcol1 lastcol1 fileid1
      return 0
   else
      getfileid startfid
      if marktype() <> 'BLOCK' then
         sayerror NEED_BLOCK_MARK__MSG
         /* release tempo */
         rc=0
         activatefile tempofid
         if rc then return rc; endif
         .modify = 0
         'xcom q'
         activatefile startfid
         return 1
      endif
      -- Make sure temp file is good before deleting current file's text.
      rc=0
      activatefile tempofid
      if rc then return rc; endif
      activatefile startfid
      parse value spc with usedmk firstline1 lastline1 firstcol1 lastcol1 fileid1
      getmark firstline2, lastline2, firstcol2, lastcol2, fileid2
      /* fill source with space */
      if usedmk = 'LINE' then
         for i = firstline1 to lastline1
            replaceline '', i, fileid2
         endfor
      else
         call pset_mark( firstline1, lastline1, firstcol1, lastcol1, usedmk, fileid1)
         call pfill_mark( ' ')
      endif
      call pset_mark( firstline2, lastline2, firstcol2, lastcol2, 'BLOCK', fileid2)
      delete_mark
      /* let's reflow in the hidden file */
      activatefile tempofid
      width = lastcol2 + 1 - firstcol2
      height = lastline2 + 1 - firstline2
      --'xcom ma 1 'width
      .margins = ' 1 'width
      unmark; mark_line; bottom; mark_line
      reflow
      nbl = .last
      /* go back to the destination */
      activatefile fileid2
      if nbl > height then
         fix = nbl - height
         getline line, lastline2
         for i = 1 to fix
            insertline line, lastline2 + 1
         endfor
      elseif nbl < height then
         fix = 0
         for i = nbl + 1 to height
            insertline '', tempofid.last + 1, tempofid
         endfor
         nbl=height
      else
         fix=0
      endif
      call pset_mark( 1, nbl, 1, width, 'BLOCK', tempofid)
      firstline2
      .col = firstcol2
      copy_mark
      unmark
      call pset_mark( firstline2, lastline2+fix, firstcol2, lastcol2, 'BLOCK', fileid2)
      /* release tempo */
      activatefile tempofid
      .modify = 0
      'xcom q'
      activatefile fileid2
      sayerror 1
    endif

; PCENTER_MARK: center the strings between the block marks
defproc pcenter_mark
   if  marktype() = 'BLOCK' then
      getmark firstline, lastline, firstcol, lastcol, fileid
   elseif marktype() = 'LINE' then
      getmark firstline,lastline, firstcol, lastcol, fileid
      parse value pmargins() with firstcol lastcol .
   elseif marktype() = '' then
      getfileid fileid
      parse value pmargins() with firstcol lastcol .
      firstline = .line; lastline = .line
   else
      sayerror CHAR_INVALID__MSG
      stop
   endif
   sz = lastcol + 1 - firstcol
   for i=firstline to lastline
      getline line, i, fileid
      inblock = strip(substr( line, firstcol, sz))
      if inblock = '' then iterate endif
      replaceline strip(overlay( center( inblock, sz), line, firstcol), 'T'), i, fileid
   endfor

compile if 0    -- The following two routines are unused; why waste space??  LAM
; PDISPLAY_MARGINS: put the margins mark on the current line
defproc pdisplay_margins()
   i = insert_state()
   if i then insert_toggle endif
   call psave_pos( save_pos)
   insert
   parse value pmargins() with lm rm pm .
   .col = lm; keyin 'L'; .col = pm; keyin 'P'; .col = rm; keyin 'R'
   begin_line
   call prestore_pos( save_pos)
   if i then insert_toggle endif
   return 0

; PDISPLAY_TABS: put the tab stops on the current line
defproc pdisplay_tabs()
   i=insert_state()
   if i then insert_toggle endif
   call psave_pos( save_pos)
   insert
   tabstops = ptabs()
   do forever
      parse value tabstops with tabx tabstops
      if tabx = '' then leave endif
      .col = tabx
      keyin 'T'
   end
   begin_line
   call prestore_pos( save_pos)
   if i then insert_toggle endif
   return 0
compile endif

; Check if file already exists in ring
defproc pfile_exists
   if substr( arg(1), 2, 1) = ':' then
      -- parse off drive specifier and try again
      getfileid zzfileid, substr( arg(1), 3)
   else
      getfileid zzfileid, arg(1)
   endif
   return zzfileid <> ''

; Find first blank line after the current one.  Make that the new current
; line.  If no such line is found before the end of file, don't change the
; current line.
defproc pfind_blank_line
   for i = .line + 1 to .last
      getline line, i
      -- Ver 3.11:  Modified to respect GML tags:  stop at first blank line
      -- or first line with a period or a colon (".:") in column 1.
      if line = '' or not verify( substr( line, 1, 1), '.:') then
         --i
         .lineg = i  -- .lineg suppresses scrolling, if cursor is in window
         leave
      endif
   endfor

; different from PE
defproc pfirst_nonblank
   if not .line then .col=1
   else
      getline line
      .col = max( 1, verify( line, ' '\t))
   endif

; Move cursor to end of line like end_line, but ignore trailing blanks
defproc pEnd_Line
   getline line
   line = translate( line, ' ', \9)  -- handle tabs correctly
   .col = length( strip( line, 't')) + 1

; ---------------------------------------------------------------------------
; PLOWERCASE: force to lowercase the marked area
defproc plowercase
   call checkmark()
   -- invoke pinit_extract, pextract_string, pput_string_back to do the job
   call psave_pos( save_pos)
   call pinit_extract()
   do forever
      code = pextract_string( string)
      if code = 1 then leave; endif
      if code = 0 then
         string = lowcase( string)
         call pput_string_back( string)
      endif
   end
   call prestore_pos( save_pos)

; PUPPERCASE: force to uppercase the marked area
defproc puppercase
   call checkmark()
   -- invoke pinit_extract, pextract_string, pput_string_back to do the job
   call psave_pos( save_pos)
   call pinit_extract()
   do forever
      code = pextract_string( string)
      if code = 1 then leave endif
      if code = 0 then
         string = upcase( string)
         call pput_string_back( string)
      endif
   end
   call prestore_pos( save_pos)

; ---------------------------------------------------------------------------
; Check if current file or a specified filename is marked. Return 1 or 0.
; marktype() returns true, if any file is marked.
defproc FileIsMarked
   file = arg(1)

   if file = '' then
      getfileid fid
   else
      -- This may fail when multiple files with the same filename exist in the ring.
      getfileid fid, file
   endif

   getmark firstline, lastline, firstcol, lastcol, markfid

   if (marktype() & fid = markfid) then  -- if file is marked
      return 1
   else
      return 0
   endif

; ---------------------------------------------------------------------------
; Syntax: fInMark = InMark( [line], [col])
defproc InMark
   y = arg(1)
   x = arg(2)
   if y = '' then
      y = .line
   endif
   if x = '' then
      x = .col
   endif
   fInMark = 0
   mt = marktype()
   if mt then
      getfileid fid
      getmark firstline, lastline, firstcol, lastcol, markfid
      if fid = markfid & y >= firstline & y <= lastline then
         -- assert:  at this point the only case where the text is outside
         --          the selected area is on a single line char mark and a
         --          block mark.  Any place else is a valid selection
         if not ((mt = 'CHAR' & (firstline = y & x < firstcol) |
                                (lastline = y & x > lastcol)) |
                 (mt = 'BLOCK' & (x < firstcol | x > lastcol))) then
            fInMark = 1
         endif
      endif
   endif
   return fInMark

; ---------------------------------------------------------------------------
; PMARK: mark at the cursor position (mark type received as argument).  Used by
; pset_mark
defproc pmark( mt)
   if mt= 'LINE' then
      mark_line
   elseif mt = 'CHAR' then
      mark_char
   else
      mark_block
   endif

; PMARK_WORD: mark the word pointed at by the cursor.  If the cursor is on a
; space, the word at the right is marked.  If there is no word on the right, the
; word on the left is marked.
defproc pmark_word
;   if marktype()<>'' then
;      sayerror -279  -- 'Text already marked'
;      stop
;   endif
   if marktype() then
      unmark
   endif
   call pend_word()
compile if WORD_MARK_TYPE = 'CHAR'
   mark_char
compile else
   mark_block
compile endif
   call pbegin_word()
compile if WORD_MARK_TYPE = 'CHAR'
   mark_char
compile else
   mark_block
compile endif
  'Copy2SharBuff'  -- Copy mark to shared text buffer

defproc pset_mark( firstline, lastline, firstcol, lastcol, mt, fileid)
   mtnum = wordpos( mt, 'LINE CHAR BLOCK CHARG BLOCKG') - 1
   setmark firstline, lastline, firstcol, lastcol, mtnum, fileid

; PSAVE_MARK: save the current marks (cannot be used as a stack) See also
; prestore_pos()
defproc psave_mark( var savemark)
   savemt = marktype()
   if savemt then
      getmark savefirstline, savelastline, savefirstcol, savelastcol, savemkfileid
      unmark
      savemark = savefirstline savelastline savefirstcol savelastcol savemkfileid savemt
   else
      savemark = ''
   endif

; PRESTORE_MARK: restore the current marks (cannot be used as a stack) See also
; psave_mark
defproc prestore_mark( savemark)
   unmark
   parse value savemark with savefirstline savelastline savefirstcol savelastcol savemkfileid savemt
   if savemt <> '' then
      call pset_mark( savefirstline, savelastline, savefirstcol, savelastcol, savemt, savemkfileid)
   endif

; ---------------------------------------------------------------------------
; PSAVE_POS: save the cursor position (cannot be used as a stack) See also
; prestore_pos()
defproc psave_pos( var save_pos)
   universal lastscrollx

   -- For .fontwidth = 8 pixel:
   -- .scollx = 0      means: .col - .cursorx = 0
   -- .scollx = 1...8  means: .col - .cursorx = 1
   -- .scollx = 9...16 means: .col - .cursorx = 2

   -- Correct .cursorx value: count only full cols
   DeltaScrollx = .scrollx//.fontwidth
   if DeltaScrollx > 0 then
      Cursorx = .cursorx - 1
   else
      Cursorx = .cursorx
   endif

   save_pos = .line .col Cursorx .cursory
   lastscrollx = .scrollx

   -- .scrolly doesn't work for EPM 6. .cursoryg was created to replace it.
   -- Querying its value works and returns the amount of pels from the top
   -- of the window to the cursor. Setting it works, but is not usable,
   -- because the window scrolls one page or so up. After that, the
   -- cursor would be off the visible area.

; PRESTORE_POS: restore the cursor position (cannot be used as a stack) See
; also psave_pos()
defproc prestore_pos( save_pos)
   universal loadstate
   universal lastscrollx

   parse value save_pos with svline svcol svcx svcy
   .cursory = svcy                          -- set .cursory
   min( svline, .last)                      -- set .line
   .col = MAXCOL; .col = svcol - svcx + 1   -- set left edge of window
   .col = svcol                             -- set .col

   -- Workaround for avoiding additional .scrollx offset
   -- (see also defload):
   -- Restore .scrollx, if not processed during file loading
   if loadstate = 0 then
      if lastscrollx <> '' then
         .scrollx = lastscrollx   -- set hidden pixels at the left
      endif
      -- .scrolly is always 0
   endif

; ---------------------------------------------------------------------------
;compile if KEEP_CURSOR_ON_SCREEN
-- This should move the cursor at the end of every scroll bar action.  The
-- position to which it is moved should correspond to the location of the
-- cursor (relative to the window) at the time when the scroll began.

; ProcessBeginScroll is called when the scroll bar slider is pressed with
; the pointer.
; The call at other window scroll messages (e.g. by a mouse wheel) is buggy:
; It is also called at the first scroll message in any direction. To make
; it called again for a direction, a scroll message in another direction has
; to come before that. ProcessEndScroll is not called.
defc ProcessBeginScroll
   universal beginscroll_x
   universal beginscroll_y
   universal nepmd_hini
;dprintf( 'ProcessBeginScroll')
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      beginscroll_x = .cursorx
      beginscroll_y = .cursory
   endif

; ProcessEndScroll is called when the scroll bar slider is released with
; the pointer.
defc ProcessEndScroll
   universal beginscroll_x
   universal beginscroll_y
   universal nepmd_hini
;dprintf( 'ProcessEndScroll')
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      .cursorx = beginscroll_x
      .cursory = beginscroll_y
      if not .line & .last then
         .lineg = 1
      endif
   endif
;compile endif  -- KEEP_CURSOR_ON_SCREEN

; ---------------------------------------------------------------------------
; PMARGINS: return the current margins setting. (Uses pcommon_tab_margin)
defproc pmargins
   return .margins

; PTABS: return the current tabs setting. (Uses pcommon_tab_margin)
defproc ptabs
   return .tabs

; This is no longer used by any file in standard E.  Use strip()
; instead.  But left here for compatibility with older procs. -> No.
;defproc remove_trailing_spaces
;   return strip( arg(1), 'T')

; ---------------------------------------------------------------------------
defproc splitlines()
   if .line then
      split
      oldcol = .col
      call pfirst_nonblank()
      blanks = leftstr( textline( .line), .col - 1)
      down
      getsearch savesearch
      .col = 1
      -- Can use Extended GREP
      --'xcom c/^[ \t]*/'blanks'/x'
      'xcom c '\1'^[ \t]*'\1''blanks''\1'x'
      -- GREP would skip a blank line in the first case...
      setsearch savesearch
      up
      .col = oldcol
   endif

defproc swapwords( num)
   return substr( num, 3, 2) || substr( num, 1, 2)

;  A truncate function to maintain compatibility of macros between this
;  version and the OS/2 version which will have floating point.  Two
;  functions in DOSUTIL.E need this.
;
;  If we're passed a floating point number with a decimal point in it,
;  like "4.0", drop the decimal part.
;  If we're passed an exponential-format number like "6E3", fatal error.
defproc trunc( num)
   if not verify( 'E', upcase( num)) then
      sayerror NO_FLOAT__MSG num
      stop
   endif
   parse value num with whole'.'.
   return whole

; ---------------------------------------------------------------------------
; Almost like strip: strip leading/trailing blanks (spaces and tabs).
defproc StripBlanks( next)
   Opt = upcase( substr( arg(2), 1, 1))
   if not wordpos( Opt, 'B L T') then
      Opt = 'B'
   endif
   StripChars = arg(3)
   if StripChars == '' then
      StripChars = ' '\t
   endif
   if Opt = 'L' | Opt = 'B' then
      p = max( 1, verify( next, StripChars, 'N'))  -- find first word
      next = substr( next, p)
   endif
   if Opt = 'T' | Opt = 'B' then
      next = reverse( next)
      p = max( 1, verify( next, StripChars, 'N'))  -- find first word
      next = substr( next, p)
      next = reverse( next)
   endif
   return next

; ---------------------------------------------------------------------------
; Count quotes in LeftLine, e.g. in part of line before the cursor.
; If odd, then char at cursor pos. must belong to a string.
; Syntax: fString = IsString( <LeftLine>[, <Quotes>])
;         fString is 0 | 1.
;         <Quotes> is a space-separated list of quote chars.
;         Default value is " '.
defproc IsString( LeftLine)
   Quotes = arg(2)
   if Quotes = '' then
      Quotes = '"' || " '"
   endif

   fString = 0
   do w = 1 to words( Quotes)
      Quote = word( Quotes, w)
      numQ = 0
      pStartQ = 1
      do forever
         pQ = pos( Quote, LeftLine, pStartQ)
         if pQ = 0 then
            leave
         endif
         numQ = numQ + 1
         pStartQ = pQ + 1
      enddo

      if (numQ // 2 <> 0) then
         fString = 1
         leave
      endif
   enddo

   return fString

; ---------------------------------------------------------------------------
; Tests whether the "filename" is actually a printer
; device, so we'll know whether to test printer readiness first.
; Called by savefile() in SAVELOAD.E.  Returns 0 if not, else printer number.
defproc check_for_printer( name)
   if not name then return 0; endif
   if leftstr( name, 1) = '"' & rightstr( name, 1) = '"' then
      name = substr( name, 2, length( name) - 2)
   endif
   if rightstr( name, 1) = ':' then  -- a device
      name = leftstr( name, length( name) - 1)
   else       -- Might be a full pathspec, C:\EDIT\PRN, and still go to a device!
      indx = lastpos( '\',name)
      if not indx then
         indx = lastpos( ':', name)
      endif
      if indx then
         name = substr( name, indx + 1)
      endif
      indx = pos( '.',name)
      if indx then
         name = substr( name, 1, indx - 1)
      endif
   endif
   if upcase(name) = 'PRN' then
      return 1
   endif
   ports = '.LPT1.LPT2.LPT3.LPT4.LPT5.LPT6.LPT7.LPT8.LPT9.COM1.COM2.COM3.COM4.'
   return (4 + pos( '.'upcase(name)'.', ports))%5

;  Printer_ready( printer_number ) tests whether printer is ready.
;
;  Enter with printer_number = 1 for the first printer (LPT1), 2 for LPT2.
;  No argument at all defaults to LPT1.
;
;  Returns 1 (true)  for printer attached and ready.
;  Returns 0 (false) for printer not attached or not ready.
;
;  Note:  Assumes the standard BIOS responses for an IBM PC.
;  The BIOS responds with AH=90 hex for printer ready.
;  Might not work on clones and other strange machines.
;
;  If we're on OS/2 we don't check because the spooler protects us from
;  a hang if the printer's off-line.  We always return "ready" on OS/2.
defproc printer_ready
   return 1

defproc default_printer
compile if defined( my_printer)
   return MY_PRINTER
compile else
   parse value queryprofile(HINI_PROFILE, 'PM_SPOOLER', 'PRINTER') with printername ';'
   if printername <> '' then
      parse value queryprofile(HINI_PROFILE, 'PM_SPOOLER_PRINTER', printername) with dev ';'
      if dev <> '' then
         return dev
      endif
   endif
compile endif
   return 'LPT1'

defproc fixup_cursor()
   universal cursordimensions
   parse value word( cursordimensions, insert_state() + 1) with cursorw '.' cursorh
   cursor_dimensions cursorw, cursorh

; ---------------------------------------------------------------------------
defproc message
   getfileid fileid
   sayerror arg(1)
   activatefile fileid

; Print message and wait for a key press.
; Preserve active file and activate ring.
; Note:  There is no need to use "call" to invoke this procedure,  since it
; returns the null string.  Execution of a null string does nothing
defproc messageNwait
   getfileid zzfileid
   display -4                    -- Force a messagebox popup from the SAYERROR
   display 32                    -- Force a messagebox popup from the SAYERROR
   sayerror arg(1)
   display -32
   display 4
   activatefile zzfileid

; ---------------------------------------------------------------------------
define
   MSGC = 'color'

; Paste up a message in a box, using SAYAT's.  Useful for "Processing..." msgs.
defproc sayatbox
   universal vMESSAGECOLOR
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif

   color = sayat_color()
compile if WANT_DBCS_SUPPORT
   if ondbcs then
      middle = substr( '', 1, length( arg(1)), \x06)
      sayat '  '\x01\x06||middle||\x06\x02'  ', 1, 2, $MSGC
      sayat '  '\x05' 'arg(1)' '\x05'  ', 2, 2, $MSGC
      sayat '  '\x03\x06||middle\x06\x04'  ', 3, 2, $MSGC
   else
compile endif
      middle = substr( '', 1, length( arg(1)), '�')
      sayat '  ��'middle'ͻ  ', 1, 2, $MSGC
      sayat '  � 'arg(1)' �  ', 2, 2, $MSGC
      sayat '  ��'middle'ͼ  ', 3, 2, $MSGC
compile if WANT_DBCS_SUPPORT
   endif
compile endif

defproc sayat_color =          -- Pick a color for SAYAT that doesn't conflict w/ foreground or background color.
   universal vMESSAGECOLOR
   if vMESSAGECOLOR // 16 <> .textcolor // 16 & vMESSAGECOLOR // 16 <> .textcolor % 16 then
      return vMESSAGECOLOR       -- Preference is the message color.
   endif
   if vMESSAGECOLOR // 16 <> LIGHT_RED then
      return LIGHT_RED           -- Second choice is light red.
   endif
   if .textcolor // 16 <> LIGHT_BLUE & .textcolor % 16 <> LIGHT_BLUE then
      return LIGHT_BLUE          -- If that's used, then how about light blue
   endif
   return GREEN                  -- Final fallback is green.

