/****************************** Module Header *******************************
*
* Module Name: comment.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: comment.e,v 1.11 2006-11-16 21:00:21 jbs Exp $
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
;    -  Preferres single line comments (if defined).
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
   universal nepmd_hini
   psave_pos(saved_pos)
   getmark firstline, lastline, firstcol, lastcol, fid
   getfileid curfid
   mt = marktype()
;   sayerror 'firstline = 'firstline', lastline = 'lastline', firstcol = 'firstcol', lastcol = 'lastcol', l_last = 'length(textline(lastline))

   first = firstline  -- use these for further processing
   last  = lastline   -- and *line and *col for mark restore
;  if curfid <> fid | mt = '' then  -- check if current file is marked
   if mt = '' then
      first = .line
      last = .line
   elseif curfid <> fid then
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

   -- SLC?         : single line comment char(s), ? = 1...3
   -- SLC?Col      : column for the SLC, 0 means: allowed at every column, not used here
   -- SLC?AddSpace : (0|1) shall a space be added/removed after the SLC
   -- SLCPreferred : (1|2|3) used SLC?, only for action = 'COMMENT'
   -- MLC?Start    : multi line comment char(s), ? = 1...2, start string
   -- MLC?End      : multi line comment char(s), ? = 1...2, end string
   -- MLCPreferred : (1|2) used MLC?, only for action = 'COMMENT'
   -- Case         : (0|1) for uncomment only: respect case when locating SLC string in line

   KeyPrefix      = '\NEPMD\User\Mode\'mode'\'
   Case           = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'CaseSensitive')
   if Case == '' then
      Case        = 1  -- default is case-sensitive
   endif

   if arg(1) > '' then  -- if a single line comment char was submitted as arg(1)
      SLC1         = strip( arg(1))
      SLC1AddSpace = (rightstr( arg(1), 1) == ' ')  -- add a space if none was specified
   else
      PreferredComment = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'PreferredComment')
      if PreferredComment = '' then
         /* Handle no def here */
         SLC = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineComment'), 1)
         if SLC = '' then
            MLCStart = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentStart'), 1)
            MLCEnd   = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentEnd'  ), 1)
         else
            SLCAddSpace = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineCommentAddSpace'), 1)
         endif
      else
         PreferredCommentType = upcase( leftstr( PreferredComment, 1))
         PreferredCommentNum  = substr( PreferredComment, 2)
         if PreferredCommentType = 'S' then
            SLC = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineComment'), PreferredCommentNum)
            SLCAddSpace = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineCommentAddSpace'), PreferredCommentNum)
         else
            MLCStart = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentStart'), PreferredCommentNum)
            MLCEnd   = word( NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentEnd'  ), PreferredCommentNum)
         endif
      endif
   endif

   if action = 'COMMENT' then

      -- Single line comments are preferred to multi line comments
      if SLC <> '' then  -- if a single line comment is defined

         -- Add a single line comment
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
         -- overwrite the mode-specific settings
         SCLAddSpace = COMMENT_ADD_SPACE
         -- SLCAddSpace = 1  -- add a space after SLC too per default, not regarding
                             -- how SLC?AddSpace is defined
         -- SLCAddSpace = 0  -- never add a space after SLC too per default, not regarding
                             -- how SLC?AddSpace is defined
compile endif
         if SLCAddSpace then SLC = SLC' '; endif
         do l = first to last
            .line = l
            Oldline = textline(.line)
            Newline = SLC''Oldline
            replaceline Newline
         enddo

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
         call pset_mark( firstline + 1, lastline + 1, firstcol, lastcol, mt, fid)

      endif

   else  -- UNCOMMENT

      -- Remove single line comments
      SLCprocessed = 0
      SLCList = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineComment')
      SLCAddSpaceList = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'LineCommentAddSpace')
      do i = 1 to words(SLCList)  -- try every possible single line comment
         iterate_i = 0
         SLC         = word( SLCList, i)
         SLCAddSpace = word( SLCAddSpaceList, i)
         SLCSpace    = SLC' '
         len         = length(SLC)
         lenSpace    = length(SLCSpace)

         -- First run: check if all lines are commented and if there's a space after every SLC
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
         SCLAddSpace = COMMENT_ADD_SPACE
         -- SLCAddSpace = 1  -- remove a space after SLC too per default, not reagarding
                             -- how SLC?AddSpace is defined
         -- SLCAddSpace = 0  -- never remove a space after SLC too per default, not reagarding
                             -- how SLC?AddSpace is defined
compile endif
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
         leave

      enddo  -- i = 1 to 3

      -- Remove multi line comments
      if SLCprocessed = 0 then

         -- possible extension here: remove multi line comments if they are found in every line

         MLCStartList   = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentStart')
         MLCEndList     = NepmdQueryConfigValue( nepmd_hini, KeyPrefix'MultiLineCommentEnd')
         do i = 1 to words(MLCStartList)
            MLCStart = word( MLCStartList, i)
            MLCEnd   = word( MLCEnd, i)
            FoundStart = 0
            FoundEnd = 0
            .line = first
            line = textline(.line)
            if strip( line, 't' ) = MLCStart then
               FoundStart = 1
            else
               .line = .line - 1
               line = textline(.line)
               if strip( line, 't' ) = MLCStart then
                  FoundStart = 1
                  firstline = firstline - 1  -- for mark restore
               endif
            endif
            if FoundStart = 0 then
               --sayerror 'Comment start "'MLCStart'" not found in mark or at the line before'
            else
               deleteline  --<------------------------------------------------ todo: better do it only if also FoundEnd = 1
               .line = last - 1
               line = textline(.line)
               if strip( line, 't' ) = MLCEnd then
                  FoundEnd = 1
                  lastline = lastline - 1  -- for mark restore
                  lastcol = 0              -- for mark restore
               else
                  .line = .line + 1
                  line = textline(.line)
                  if strip( line, 't' ) = MLCEnd then
                     FoundEnd = 1
                     lastline = lastline - 1 -- for mark restore
                  endif
               endif
               if FoundEnd = 0 then
                  --sayerror 'Comment end "'MLCEnd'" not found in mark or at the line after'
               else
                  deleteline
               endif
            endif
            if FoundStart = 1 and FoundEnd = 1 then
               call pset_mark( firstline, lastline, firstcol, lastcol, mt, fid)
               leave
            endif
         enddo  -- i = 1 to 2

      endif  -- SLCprocessed = 0

   endif  -- action = 'COMMENT'

   prestore_pos(saved_pos)

   return

compile if 0
   -- default values:
      SLC1         = ''
;     SLC1Col      = 0  -- not used here
      SLC1AddSpace = 1

      SLC2         = ''
;     SLC2Col      = 0  -- not used here
      SLC2AddSpace = 1

      SLC3         = ''
;     SLC3Col      = 0  -- not used here
      SLC3AddSpace = 1

      SLCPreferred = 1

      MLC1Start    = ''
      MLC1End      = ''

      MLC2Start    = ''
      MLC2End      = ''

      MLCPreferred = 1

      Case         = 1  -- default is case-sensitive

   -- SLC?         : single line comment char(s), ? = 1...3
   -- SLC?Col      : column for the SLC, 0 means: allowed at every column, not used here
   -- SLC?AddSpace : (0|1) shall a space be added/removed after the SLC
   -- SLCPreferred : (1|2|3) used SLC?, only for action = 'COMMENT'
   -- MLC?Start    : multi line comment char(s), ? = 1...2, start string
   -- MLC?End      : multi line comment char(s), ? = 1...2, end string
   -- MLCPreferred : (1|2) used MLC?, only for action = 'COMMENT'
   -- Case         : (0|1) for uncomment only: respect case when locating SLC string in line

   if arg(1) > '' then  -- if a single line comment char was submitted as arg(1)
      SLC1         = strip( arg(1))
      SLC1AddSpace = (rightstr( arg(1), 1) == ' ')  -- add a space if none was specified

   elseif     mode = 'C' | mode = 'JAVA' | mode = 'RC' then ----------- C JAVA RC
      SLC1         = '//'
      MLC1Start    = '/*'
      MLC1End      = '*/'

   elseif     mode = 'DEF' then --------------------------------------- DEF
      SLC1         = ';'

   elseif     mode = 'MAKE' then -------------------------------------- MAKE
      SLC1         = '#'

   elseif     mode = 'E' then ----------------------------------------- E
      SLC1         = ';'
;     SLC1Col      = 1
      SLC2         = '--'
      SLCPreferred = 1
      MLC1Start    = '/*'
      MLC1End      = '*/'
      Case         = 0  -- not required

   elseif     mode = 'REXX' | mode = 'CSS' then ----------------------- REXX CSS
      MLC1Start    = '/*'
      MLC1End      = '*/'
      Case         = 0  -- not required

   elseif     mode = 'CMD' then --------------------------------------- CMD
      SLC1         = ': '
;     SLC1Col      = 1
      SLC1AddSpace = 0
      SLC2         = '::'
;     SLC2Col      = 1
      SLC2AddSpace = 1
      SLC3         = 'REM '
;     SLC3Col      = 1
      SLC3AddSpace = 0
      SLCPreferred = 1
      Case         = 0

   elseif     mode = 'CONFIGSYS' then --------------------------------- CONFIGSYS
      SLC1         = 'REM '
;     SLC1Col      = 1
      SLC1AddSpace = 0
      Case         = 0

   elseif     mode = 'INI' | mode = 'OBJGEN' then --------------------- INI OBJGEN
      SLC1         = ';'
;     SLC1Col      = 1
      Case         = 0

   elseif     mode = 'IPF' | mode = 'SCRIPT' then --------------------- IPF SCRIPT
      SLC1         = '.*'
;     SLC1Col      = 1
      Case         = 0  -- not required

   elseif     mode = 'PASCAL' then ------------------------------------ PASCAL
      SLC1         = '//'
      MLC1Start    = '(*'
      MLC1End      = '*)'
      MLC2Start    = '{'
      MLC2End      = '}'
      MLCPreferred = 1
      Case         = 0  -- not required

   elseif     mode = 'PERL' then -------------------------------------- PERL
      SLC1         = '# '
      MLC1Start    = '/*'
      MLC1End      = '*/'
      Case         = 0  -- not required

   elseif     mode = 'ADA' then --------------------------------------- ADA
      SLC1         = '--'

   elseif     mode = 'FORTRAN' then ----------------------------------- FORTRAN
      SLC1         = 'c '
;     SLC1Col      = 1
      SLC1AddSpace = 0
      SLC2         = '*'
;     SLC2Col      = 1
      SLC3         = '!'
      SLCPreferred = 3

   elseif     mode = 'TEX' then --------------------------------------- TEX
      SLC1         = '%'
      MLC1Start    = '\iffalse'
      MLC1End      = '\fi'

   elseif     mode = 'HTML' | mode = 'WARPIN' then -------------------- HTML WARPIN
      MLC1Start    = '<!--'
      MLC1End      = '-->'
      Case         = 0  -- not required

   elseif     mode = 'PHP' then --------------------------------------- PHP
      SLC1         = '//'
      SLC2         = '#'
      SLCPreferred = 1
      MLC1Start    = '<!--'
      MLC1End      = '-->'
      MLC2Start    = '/*'
      MLC2End      = '*/'
      MLCPreferred = 2

   elseif     mode = 'BASIC' then ------------------------------------- BASIC
      SLC1         = "'"
;     SLC1Col      = 1
      SLC2         = 'REM '
;     SLC2Col      = 1
      SLC2AddSpace = 0
      SLCPreferred = 1
      Case         = 0

   elseif     mode = 'HTEXT' then ------------------------------------- HTEXT
      SLC1         = ".."
      SLC1Col      = 1
      SLC1AddSpace = 1
      SLCPreferred = 1
      Case         = 0

   endif

   if action = 'COMMENT' then

      if     SLCPreferred = 1 then
         SLC          = SLC1
         SLCAddSpace  = SLC1AddSpace
      elseif SLCPreferred = 2 then
         SLC          = SLC2
         SLCAddSpace  = SLC2AddSpace
      elseif SLCPreferred = 3 then
         SLC          = SLC3
         SLCAddSpace  = SLC3AddSpace
      endif

      if     MLCPreferred = 1 then
         MLCStart     = MLC1Start
         MLCEnd       = MLC1End
      elseif MLCPreferred = 2 then
         MLCStart     = MLC2Start
         MLCEnd       = MLC2End
      endif

   if action = 'COMMENT' then

      -- Single line comments are preferred to multi line comments
      if SLC <> '' then  -- if a single line comment is defined

         -- Add a single line comment
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
         -- overwrite the mode-specific settings
         SCLAddSpace = COMMENT_ADD_SPACE
         -- SLCAddSpace = 1  -- add a space after SLC too per default, not regarding
                             -- how SLC?AddSpace is defined
         -- SLCAddSpace = 0  -- never add a space after SLC too per default, not regarding
                             -- how SLC?AddSpace is defined
compile endif
         if SLCAddSpace then SLC = SLC' '; endif
         do l = first to last
            .line = l
            Oldline = textline(.line)
            Newline = SLC''Oldline
            replaceline Newline
         enddo

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
         call pset_mark( firstline + 1, lastline + 1, firstcol, lastcol, mt, fid)

      endif

   else  -- UNCOMMENT

      -- Remove single line comments
      SLCprocessed = 0
      do i = 1 to 3  -- try every possible single line comment
         iterate_i = 0
         if i = 1 then
            SLC          = SLC1
            SLCAddSpace  = SLC1AddSpace
         elseif i = 2 then
            SLC          = SLC2
            SLCAddSpace  = SLC2AddSpace
         elseif i = 3 then
            SLC          = SLC3
            SLCAddSpace  = SLC3AddSpace
         endif
         if SLC = '' then iterate; endif
         SLCSpace = SLC' '
         len      = length(SLC)
         lenSpace = length(SLCSpace)

         -- First run: check if all lines are commented and if there's a space after every SLC
compile if COMMENT_ADD_SPACE = 1 or COMMENT_ADD_SPACE = 0
         SCLAddSpace = COMMENT_ADD_SPACE
         -- SLCAddSpace = 1  -- remove a space after SLC too per default, not reagarding
                             -- how SLC?AddSpace is defined
         -- SLCAddSpace = 0  -- never remove a space after SLC too per default, not reagarding
                             -- how SLC?AddSpace is defined
compile endif
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
         leave

      enddo  -- i = 1 to 3

      -- Remove multi line comments
      if SLCprocessed = 0 then

         -- possible extension here: remove multi line comments if they are found in every line

         do i = 1 to 2
            if i = 1 then
               MLCStart = MLC1Start
               MLCEnd = MLC1End
            elseif i = 2 then
               MLCStart = MLC2Start
               MLCEnd = MLC2End
            endif
            if MLCStart = '' | MLCStart = '' then iterate; endif
            FoundStart = 0
            FoundEnd = 0
            .line = first
            line = textline(.line)
            if strip( line, 't' ) = MLCStart then
               FoundStart = 1
            else
               .line = .line - 1
               line = textline(.line)
               if strip( line, 't' ) = MLCStart then
                  FoundStart = 1
                  firstline = firstline - 1  -- for mark restore
               endif
            endif
            if FoundStart = 0 then
               --sayerror 'Comment start "'MLCStart'" not found in mark or at the line before'
            else
               deleteline  --<------------------------------------------------ todo: better do it only if also FoundEnd = 1
               .line = last - 1
               line = textline(.line)
               if strip( line, 't' ) = MLCEnd then
                  FoundEnd = 1
                  lastline = lastline - 1  -- for mark restore
                  lastcol = 0              -- for mark restore
               else
                  .line = .line + 1
                  line = textline(.line)
                  if strip( line, 't' ) = MLCEnd then
                     FoundEnd = 1
                     lastline = lastline - 1 -- for mark restore
                  endif
               endif
               if FoundEnd = 0 then
                  --sayerror 'Comment end "'MLCEnd'" not found in mark or at the line after'
               else
                  deleteline
               endif
            endif
            if FoundStart = 1 and FoundEnd = 1 then
               call pset_mark( firstline, lastline, firstcol, lastcol, mt, fid)
               leave
            endif
         enddo  -- i = 1 to 2

      endif  -- SLCprocessed = 0

   endif  -- action = 'COMMENT'

compile endif
