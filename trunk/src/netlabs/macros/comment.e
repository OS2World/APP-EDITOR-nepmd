/****************************** Module Header *******************************
*
* Module Name: comment.e
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

; Configuration:
;    Comment: Want a space after a single line comment string?
;    Uncomment: Want a space after a single line comment string removed,
;    if present in all lines?
;    This doesn't apply to modes, where the space is required, e.g. 'REM '.
;    0: no, 1: yes,
;    any other string: respect the SLC?AddSpace variable, defined below.
const
compile if not defined(COMMENT_ADD_SPACE)
   COMMENT_ADD_SPACE = 'MODE'  -- (0|1|<anything else>)
compile endif

compile if not defined(COMMENT_UNMARKED_LINE_ALLOWED)
   COMMENT_UNMARKED_LINE_ALLOWED = 1
compile endif

defc com, comment
   call CommentMarkedLines( arg(1), 'C')

defc ucom, uncomment
   call CommentMarkedLines( arg(1), 'U')

; Hint for inserting a line:
;
;    -- Prepend a new line
;    top
;    insertline '--- New line added at top ---'  -- insertline adds a line before the current
;
;    -- Append a new line
;    bottom
;    end_line; split      -- this inserts a new line after the current
;    .line = .line + 1    -- go to new line
;    replaceline '--- New line added at bottom ---'

; ---------------------------------------------------------------------------
; arg(1) = single line comment char(s)
; arg(2) = ('U'|'C')  U: uncomment, C: comment (default)
; Comment:
;    -  Every marked line or line with marked chars will be commented-out.
;    -  The mark type doesn't matter.
;    -  Restores marked area.
;    -  Prefers single line comments (if defined).
;    -  Multi line comments are added as new lines above and below the mark.
;    -  Configurable.
; Uncomment:
;    -  Every marked line or line with marked chars will be uncommented.
;    -  The mark type doesn't matter.
;    -  Doesn't uncomment if the mark contains any uncommented line.
;    -  Determines if a space was added behind the comment char.
;    -  Tries every comment char, starts with single line comments.
;    -  Every single line comment must be at line start.
;    -  Every multi line comment must be on a separate line.
;    -  Restores marked area.
;    -  Doesn't remove multi line comments, that appear on every line.
defproc CommentMarkedLines
   psave_pos(saved_pos)
   getmark firstline, lastline, firstcol, lastcol, fid
   getfileid curfid
   mt = marktype()
;   sayerror 'firstline = 'firstline', lastline = 'lastline', firstcol = 'firstcol', lastcol = 'lastcol', l_last = 'length(textline(lastline))

   first = firstline  -- use these for further processing
   last  = lastline   -- and *line and *col for mark restore
compile if defined(COMMENT_UNMARKED_LINE_ALLOWED)
   allow_unmarked_comment = 1
compile else
   allow_unmarked_comment = 0
compile endif
   if mt = '' and allow_unmarked_comment = 1 then
      first       = .line
      firstline   = first
      last        = .line
      lastline    = last
      firstcol    = .col
      lastcol     = .col
   elseif curfid <> fid | mt = '' then  -- check if current file is marked
      sayerror 'No area marked in current file'
      return
   elseif firstline = lastline & lastcol = 0 then  -- a mark action was started, but no char is marked
      sayerror 'No area marked'
      unmark
      return
   elseif lastcol = 0 then  -- lastcol = 0 means, that the line end of the line above is marked
      last = last - 1
   endif

   -- no additional undo state supression required

   mode = GetMode()

   if abbrev( 'U', upcase(arg(2))) then
      action = 'UNCOMMENT'
   else
      action = 'COMMENT'
   endif

   -- SLC          : single line comment char(s), ? = 1...3
   -- SLCCol       : column for the SLC, 0 means: allowed at every column, not used here
   -- SLCAddSpace  : (0|1) shall a space be added/removed after the SLC
   -- MLCStart     : multi line comment char(s), ? = 1...2, start string
   -- MLCEnd       : multi line comment char(s), ? = 1...2, end string
   -- Case         : (0|1) for uncomment only: respect case when locating SLC string in line
   SLC            = ''
   Case           = QueryModeKey( mode, 'CaseSensitive', '1')  -- default is case-sensitive
   AdjLine        = 0
   AdjCol         = 0
   AdjCursorx     = 0
   AdjCursory     = 0

   if arg(1) > '' then  -- if a single line comment char was submitted as arg(1)
      SLC         = strip( arg(1))
      SLCAddSpace = (rightstr( arg(1), 1) == ' ')  -- add a space if none was specified
   else
      PreferredComment = QueryModeKey( mode, 'PreferredComment')
      call dprintf('comment', 'Preferred: 'PreferredComment)
      if PreferredComment = '' then
         /* Handle no def here */
         SLC = word( QueryModeKey( mode, 'LineComment'), 1)
         if SLC = '' then
            MLCStart = word( QueryModeKey( mode, 'MultiLineCommentStart'), 1)
            MLCEnd   = word( QueryModeKey( mode, 'MultiLineCommentEnd'  ), 1)
         else
            SLCAddSpace = word( QueryModeKey( mode, 'LineCommentAddSpace'), 1)
         endif
      else
         PreferredCommentType = upcase( leftstr( PreferredComment, 1))
         PreferredCommentNum  = substr( PreferredComment, 2)
         call dprintf('comment', 'Type num: 'PreferredCommentType PreferredCommentNum)
         if PreferredCommentType = 'S' then
            SLC = word( QueryModeKey( mode, 'LineComment'), PreferredCommentNum)
            SLCAddSpace = word( QueryModeKey( mode, 'LineCommentAddSpace'), PreferredCommentNum)
            call dprintf('comment', 'SLC Add: 'SLC SLCAddSpace)
         else
            MLCStart = word( QueryModeKey( mode, 'MultiLineCommentStart'), PreferredCommentNum)
            MLCEnd   = word( QueryModeKey( mode, 'MultiLineCommentEnd'  ), PreferredCommentNum)
            call dprintf('comment', 'MLCS MLCE: 'MLCStart MLCEnd)
         endif
      endif
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
      -- overwrite the mode-specific settings
      SLCAddSpace = COMMENT_ADD_SPACE
compile endif
   endif

   if action = 'COMMENT' then

      -- Single line comments are preferred to multi line comments
      if SLC <> '' then  -- if a single line comment is defined

         -- Add a single line comment
         if SLCAddSpace then SLC = SLC' '; endif
         do l = first to last
            .line = l
            Oldline = textline(.line)
            Newline = SLC''Oldline
            replaceline Newline
         enddo
         AdjCol   = length(SLC)

      elseif MLCStart <> '' & MLCEnd <> '' then  -- if a multi line comment is defined

         -- Add a new line and the comment start
         .line = first        -- go to first marked line
         insertline MLCStart  -- insertline adds a line before the current

         -- Add a new line and the comment end
         .line = last + 1     -- go to last marked line (respect that a line was added before)
         end_line; split      -- this inserts a new line after the current
         .line = .line + 1    -- go to new line
         replaceline MLCEnd

         -- Restore mark
         if mt <> '' then
            call pset_mark( firstline + 1, lastline + 1, firstcol, lastcol, mt, fid)
         endif

      endif

   else  -- UNCOMMENT

      -- Remove single line comments
      SLCprocessed      = 0
      SLCList           = QueryModeKey( mode, 'LineComment')
      SLCAddSpaceList   = QueryModeKey( mode, 'LineCommentAddSpace')
      do i = 1 to words(SLCList)  -- try every possible single line comment
         iterate_i   = 0
         SLC         = word( SLCList, i)
         SLCAddSpace = word( SLCAddSpaceList, i)
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
         SLCAddSpace = COMMENT_ADD_SPACE
compile endif
         SLCSpace    = SLC' '
         len         = length(SLC)
         lenSpace    = length(SLCSpace)

         -- First run: check if all lines are commented and if there's a space after every SLC
         do l = first to last
            .line = l
            Oldline = textline(.line)
            if Case = 0 then
               CaseOldline  = upcase(Oldline)
               CaseSLCSpace = upcase(SLCSpace)
               CaseSLC      = upcase(SLC)
            else
               CaseOldline  = Oldline
               CaseSLCSpace = SLCSpace
               CaseSLC      = SLC
            endif
            if leftstr( CaseOldline, lenSpace) <> CaseSLCSpace then
               -- Try SLC without space.
               if leftstr( CaseOldline, len) = CaseSLC then
                  if CaseOldline <> CaseSLC then
                     -- Reset it only if this is not a blank commented line
                     SLCAddSpace = 0
                  endif
               else
                  -- Uncommented line in mark, try next comment char
                  iterate_i = 1
                  leave
               endif
            endif
         enddo  -- l
         if iterate_i = 1 then iterate; endif
         if SLCAddSpace = 1 then
            len = lenSpace  -- add 1 to amount of chars removed
         endif

         -- Second run: remove comments
         -- At this point we are sure, that every line is commented.
         do l = first to last
            .line = l
            Oldline = textline(.line)
            if Case = 0 then
               CaseOldline  = upcase(Oldline)
               CaseSLC      = upcase(SLC)
            else
               CaseOldline  = Oldline
               CaseSLC      = SLC
            endif
            if CaseOldline = CaseSLC then  -- for commented blank lines missing the space
               Newline = ''
            elseif length(Oldline) > len then
               Newline = substr( Oldline, len + 1)
            else
               Newline = ''
            endif
            replaceline Newline
         enddo  -- l
         SLCProcessed = 1
         AdjCol   = -len
         leave

      enddo  -- i = 1 to words(SLCList)

      -- Remove multi line comments
      if SLCprocessed = 0 then
         prestore_pos(saved_pos)

         -- possible extension here: remove multi line comments if they are found in every line

         MLCStartList   = QueryModeKey( mode, 'MultiLineCommentStart')
         MLCEndList     = QueryModeKey( mode, 'MultiLineCommentEnd')
         do i = 1 to words(MLCStartList)
            MLCStart = word( MLCStartList, i)
            MLCEnd   = word( MLCEndList, i)
            MLCStartLine   = -1
            MLCEndLine     = -1
            line = textline( first)
            if strip( line, 't' ) = MLCStart then
               MLCStartLine  = first
               if mt = '' then         -- If no mark, handle special case of:
                                       -- MLCStart (cursor on this line, i.e 'last'
                                       -- (commented line)
                                       -- MLCEnd   (last + 2)
                  line = textline( last + 2)
                  if strip( line, 't' ) = MLCEnd then
                     MLCEndLine = last + 2
                  endif
               endif
            else
               line = textline( first - 1)
               if strip( line, 't' ) = MLCStart then
                  MLCStartLine   = first - 1
                  firstline      = firstline - 1  -- for mark restore
               endif
            endif
            if MLCStartLine < 0 then
               sayerror 'Comment start "'MLCStart'" not found in mark or at the line before'
            elseif MLCEndLine < 0 then
               line = textline( last)
               if strip( line, 't' ) = MLCEnd then
                  MLCEndLine = last
                  lastline = lastline - 1  -- for mark restore
                  lastcol = 0              -- for mark restore
               else
                  line = textline( last + 1)
                  if strip( line, 't' ) = MLCEnd then
                     MLCEndLine = last + 1
                     lastline = lastline - 1 -- for mark restore
                  endif
               endif
               if MLCEndLine < 0 then
                  sayerror 'Comment end "'MLCEnd'" not found in mark or at the line after'
               endif
            endif
            if MLCStartLine >= 0 and MLCEndLine >= 0 then
               if .line >= MLCEndLine then
                  AdjLine = -2
               elseif .line = MLCEndLine - 1 then
                  AdjLine = -1
               endif
               .line = MLCEndLine
               deleteline
               .line = MLCStartLine
               deleteline
               if mt <> '' then
                  call pset_mark( firstline, lastline, firstcol, lastcol, mt, fid)
               endif
               leave
            endif
         enddo  -- i = 1 to words(MLCStartList)

      endif  -- SLCprocessed = 0

   endif  -- action = 'COMMENT'

   prestore_pos(saved_pos)
   .line    = .line + AdjLine
   .col     = .col  + AdjCol
;  .cursorx = .cursorx + AdjCol     -- JBSQ: Does this need adjustment? Is it the adj the same as for col?
;  .cursory = .cursory + AdjLine    -- JBSQ: Does this need adjustment? Is it the adj the same as for line?

   return

