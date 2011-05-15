/****************************** Module Header *******************************
*
* Module Name: rexxkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: rexxkeys.e,v 1.16 2006/10/23 16:38:59 aschn Exp $
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

; Todo:
;
; New procs: Tabs2Spaces and Spaces2Tabs for strings for expansion using Tabs
;
; New proc: Get indent of a line
;
; New proc: Find closing expression?
; Better use locate?
; Determine, if 'end' should be added.

; ---------------------------------------------------------------------------
; Set* commands for mode REXX
; ---------------------------------------------------------------------------
definit
   call AddAVar( 'selectsettingslist',
                        'RexxDoStyle RexxIfStyle RexxCase RexxForceCase')

; Expand "do" statement.
defc SetRexxDoStyle
   universal rexx_DO_style
   ValidArgs = 'APPEND INDENT BELOW'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'BELOW'
   endif
   rexx_DO_style = arg1
   call UseSetting( 'RexxDoStyle', arg(1))

; Expand "if" statement.
defc SetRexxIfStyle
   universal rexx_IF_style
   ValidArgs = 'ADDELSE NOELSE'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'NOELSE'
   endif
   rexx_IF_style = arg1
   call UseSetting( 'RexxIfStyle', arg(1))

; Select syntax case.
defc SetRexxCase
   universal rexx_case
   ValidArgs = 'LOWER MIXED UPPER'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'LOWER'
   endif
   rexx_case = arg1
   call UseSetting( 'RexxCase', arg(1))

; Replace or keep case of statements already present.
defc SetRexxForceCase
   universal rexx_force_case
   ValidArgs = '0 1'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = '1'
   endif
   rexx_force_case = arg1
   call UseSetting( 'RexxForceCase', arg(1))

; ---------------------------------------------------------------------------
; Todo: move in order to make that available for other modes as well.
; Almost like strip: strip leading/trailing blanks (spaces and tabs).
defproc StripBlanks( in)
   next = in
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
defproc GetRexxIndent
   universal indent
   ind = indent  -- will be changed at defselect for every mode, if defined
   if ind = '' | ind = 0 then
      ind = 3
   endif
   return ind

; ---------------------------------------------------------------------------
; Convert case of a string, word by word. Keep spaces and Tabs.
defproc RexxSyntaxCase
   universal rexx_case
   in = arg(1)
   out = in
   p = verify( out, ' '\t, 'N')                   -- find first word
   startp = p
   i = 0
   do while p > 0
      pb = verify( out, ' '\t, 'M', startp + 1)   -- find next blank
      p = 0
      if pb > 0 then
         p = verify( out, ' '\t, 'N', pb + 1)     -- find next word
      endif
      if p = 0 then
         next = substr( out, startp)              -- rest
      else
         next = substr( out, startp, p - startp)  -- next word incl. trailing blanks
      endif
      if rexx_case = 'LOWER' then
         next = lowcase( next)
      elseif rexx_case = 'UPPER' then
         next = upcase( next)
      elseif rexx_case = 'MIXED' then
         next = lowcase( next)
         next = upcase( substr( next, 1, 1))''substr( next, 2)
      endif
      out = overlay( next, out, startp)
      if pb = 0 then
         leave
      endif
      startp = p
   enddo
   return out

; ---------------------------------------------------------------------------
defc RexxFirstExpansion
   rc = rex_first_expansion()  -- (rc = 0) = processed

defproc rex_first_expansion
   universal rexx_force_case
   universal rexx_IF_style
   universal END_commented

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if END_commented = 1 then
      END_DO = ' /* do */'
   else
      END_DO = ''
   endif

   if .line then
      getline line
      sline = StripBlanks( line, 'T')
      wrd = upcase( StripBlanks( sline, 'L'))                      -- wrd = current line, stripped, uppercase
      ind = substr( sline, 1, max( 1, verify( sline, ' '\t)) - 1)  -- ind = blanks before first word
      col = .col

      -- Skip expansion if word before cursor is not a keyword or if some string follows
      if not (length(sline) = .col - 1) then
         -- cursor is not behind the last word: skip expansion
         retc = 1
      elseif wrd = '' then
         -- empty line: skip expansion
         retc = 1

      elseif wrd = 'IF' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline ind''RexxSyntaxCase( 'if  then')
         else
            replaceline sline''RexxSyntaxCase( '  then')
         endif
         if rexx_IF_style = 'ADDELSE' then
            insertline ind''RexxSyntaxCase( 'else'), .line + 1
         endif
         .col = col + 1

      elseif wrd = 'WHEN' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline ind''RexxSyntaxCase( 'when  then')
         else
            replaceline sline''RexxSyntaxCase( '  then')
         endif
         .col = col + 1

      elseif wrd = 'DO' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline ind''RexxSyntaxCase( 'do ')
         else
            replaceline sline' '
         endif
         insertline ind''RexxSyntaxCase( 'end'END_DO), .line + 1
         .col = col + 1

      else
         retc = 1
      endif  -- sline <> line_l
   else
      retc = 1
   endif  -- .line
   return retc

; ---------------------------------------------------------------------------
defc RexxSecondExpansion
   rc = rex_second_expansion()  -- (rc = 0) = processed

defproc rex_second_expansion
   universal rexx_force_case
   universal comment_auto_terminate
   universal END_commented
   universal rexx_DO_style
   universal header_length
   universal header_style

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if END_commented = 1 then
      END_DO     = ' /* do */'
      END_SELECT = ' /* select */'
   else
      END_DO     = ''
      END_SELECT = ''
   endif

   if .line then
      getline line
      -- *word functions and parse don't recognize tab chars as word boundaries.
      -- tline = uppercase line, with converted tabs
      tline = translate( upcase(line) ' ', \t)

      -- Set firstword only to text left from the cursor
      tline_l = substr( tline, 1, .col - 1) -- split tline into two parts at cursor
      parse value tline_l with firstword rest
      -- firstword is uppercase, because line is already upcased.
      if firstword > ' ' then
         firstp = pos( firstword, tline_l)
      else
         firstp = 1
      endif

      ind = substr( line, 1, max( 1, verify( line, ' '\t)) - 1)        -- ind  = blanks before first word
      ind1 =  ind''copies( ' ', GetRexxIndent())                       -- ind1 = ind plus 1 level indented
-- Todo: Tabs2Spaces for line
-- doesn't handle Tabs near the end correctly:
      ind0 =  substr( ind, 1, max( length(ind) - GetRexxIndent(), 0))  -- ind0 = ind minus 1 level indented

-- Todo: rewrite THEN DO, ELSE DO expansion
      if pos( 'THEN DO', tline) > 0 or pos( 'ELSE DO', tline) > 0 then
         p = pos( 'ELSE DO', tline)  -- Don't be faked out by 'else doc = 5'
         if not p then
            p = pos( 'THEN DO', tline)
            if rexx_force_case then
               s1 = 'then do'
            endif
         else
            if rexx_force_case then
               s1 = 'else do'
            endif
         endif
         -- Skip expansion, if THEN DO or ELSE DO is not followed by a semicolon or space.
         -- Lineend is handled as space in EPM's edit window.
         if p & not pos( substr( tline, p + 7, 1), ' ;') then
            retc = 1
            return retc
         endif
-- Todo: skip expansion, if matching END found.
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( s1), line, p)
         endif
         insertline ind1'', .line + 1
         insertline ind''RexxSyntaxCase( 'end'END_DO), .line + 2
         '+1'
         endline

      elseif firstword = 'SELECT' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( 'select'), line, firstp)
         endif
         insertline ind1''RexxSyntaxCase( 'when  then'), .line + 1
         insertline ind''RexxSyntaxCase( 'otherwise'), .line + 2
         insertline ind''RexxSyntaxCase( 'end'END_SELECT), .line + 3
         '+1'                             -- Move to When clause
         endline
         .col = .col - 5

      elseif firstword = 'DO' then
         lastind = ind
         nextind = ind1
         endl = 0
         endp = 0
         appendl = 0
         if wordpos( rexx_DO_style, 'APPEND BELOW') then
            -- Check for previous line with a trailing 'THEN' and get its indent
            if .line > 1 then
               -- Inspect previous line
               -- Don't ignore blank lines here
               getline linel, .line - 1
               if lastword( translate( upcase(linel), ' ', \t)) = 'THEN' then
                  -- Get indent of line before with IF|WHEN|OTHERWISE
                  -- Re-indent DO line: take indent of line before
                  -- or append DO and the rest to THEN line
                  if rexx_DO_style = 'APPEND' then
                     appendl = .line - 1
                  endif
                  startl = .line - 1
                  do l = startl to 1 by -1
                     if l < startl - 10 then  -- search only 10 last lines
                        leave
                     endif
                     getline linel, l
                     next = word( translate( upcase(linel), ' ', \t), 1)
                     if wordpos( next, 'IF WHEN') then
                        --sayerror 'IF WHEN OTHERWISE: ['line0']'
                        -- Get indent of linel
                        lastind = substr( linel, 1, max( 1, verify( linel, ' '\t)) - 1)
                        nextind = lastind''copies( ' ', GetRexxIndent())
                        leave
                     endif
                  enddo
               elseif wordpos( lastword( translate( upcase(linel), ' ', \t)), 'ELSE OTHERWISE') then
                  -- Get indent of line before with ELSE or OTHERWISE
                  -- Re-indent DO line: take indent of line before
                  -- or append DO and the rest to ELSE line
                  l = .line - 1
                  if rexx_DO_style = 'APPEND' then
                     appendl = l
                  endif
                  getline linel, l
                  -- Get indent of linel
                  lastind = substr( linel, 1, max( 1, verify( linel, ' '\t)) - 1)
                  nextind = lastind''copies( ' ', GetRexxIndent())
                  --sayerror 'append line: 'appendl' ['linel']'
               endif
            endif
            -- Find matching END and re-indent END too
            -- Make END; match too
            startl = .line + 1
            do l = startl to .last
               if l > startl + 50 then  -- search only 50 next lines
                  leave
               endif
               getline linel, l
               next = word( translate( upcase(linel), ' ', \t), 1)
               -- Ignore empty lines
               if next = '' then
                  iterate
               -- Search for first word
               elseif wordpos( word( next, 1), 'END END;') then
                  endl = l
                  endp = pos( 'END', translate(linel))
                  --sayerror 'end line = 'endl' ['linel']'
                  leave
               -- Break if next found word is not END (then it can't come
               -- from DO's first expansion, which adds an END just after DO).
               else
                  leave
               endif
            enddo
         endif
         call NewUndoRec()
         -- Re-indent END line
         -- must come first
         if endp > 0 then
            if rexx_force_case then
               next = overlay( RexxSyntaxCase( 'end'), textline(endl), endp)
               replaceline lastind''substr( next, endp), endl  -- re-indent END line
            else
               replaceline lastind''substr( textline(endl), endp), endl  -- re-indent END line
            endif
         endif
         if rexx_force_case then
            next = overlay( RexxSyntaxCase( 'do'), line, firstp)
         else
            next = line
         endif
         --sayerror 'next = '.line' ['next']'
         if appendl > 0 then
            -- Append DO line
            replaceline StripBlanks( textline(appendl), 'T')' 'StripBlanks( next), appendl
            deleteline
            '-1'
         else
            -- Re-indent DO line
            replaceline lastind''substr( next, firstp)
         endif
         -- Add empty, indented line
         insertline nextind, .line + 1
         '+1'
         endline

      elseif firstword = 'IF' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( 'if'), line, firstp)
         endif
         insertline ind1'', .line + 1
         '+1'
         endline

      elseif firstword = 'WHEN' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( 'when'), line, firstp)
         endif
         insertline ind1, .line + 1
         '+1'
         endline

      elseif firstword = 'OTHERWISE' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( 'otherwise'), line, firstp)
         endif
         insertline ind1, .line + 1
         '+1'
         endline

      elseif firstword = 'ELSE' then
         call NewUndoRec()
         if rexx_force_case then
            replaceline overlay( RexxSyntaxCase( 'else'), line, firstp)
         endif
         insertline ind1, .line + 1
         '+1'
         endline

      elseif (firstword = '/*' | firstword = '/**') & words( tline) = 1 then
         call NewUndoRec()
         insertline ind' * ', .line + 1
         -- Search for closing comment */
         fFound = 0
         startl = .line + 1
         do l = startl to .last
            if l > startl + 200 then  -- search only 200 next lines
               leave
            endif
            getline linel, l
            next = word( linel, 1)
            -- Search for first word
            if next = '*' then
               iterate
            elseif substr( next, 1, 2) = '*/' then
               fFound = 1
               leave
            else
               leave
            endif
         enddo
         if fFound = 0 then
            insertline ind' */', .line + 2
         endif
         '+1'
         endline

      elseif firstword = '/*H' then
         if words( tline) = 1 then
            call NewUndoRec()
            -- Style 1:
            -- /***************
            -- * |
            -- ***************/
            -- Style 2:
            -- /***************
            --  * |
            --  **************/
            replaceline '/'copies( '*', header_length - 1)
            if header_style = 1 then
               insertline '* ', .line + 1
               insertline copies( '*', header_length - 1)'/', .line + 2
            else
               insertline ' * ', .line + 1
               insertline ' 'copies( '*', header_length - 2)'/', .line + 2
            endif
            '+1'
            endline
         endif

      elseif firstword = '*' then
         -- Search for opening comment /*
         fFound = 0
         startl = .line - 1
         do l = startl to 1 by -1
            if l < startl - 100 then  -- search only 100 next lines
               leave
            endif
            getline linel, l
            next = word( linel, 1)
            -- Search for first word
            if next = '*' then
               iterate
            elseif substr( next, 1, 2) = '/*' then
               fFound = 1
               leave
            else
               leave
            endif
         enddo
         if fFound = 1 then
            call NewUndoRec()
            RestLine = strip( substr( line, .col), 'L')
            erase_end_line
            if firstp = 1 then
               insertline '* 'RestLine, .line + 1
            else
               insertline ind'* 'RestLine, .line + 1
            endif
            '+1'
            endline
         else
            retc = 1
         endif

      elseif pos( '/*', line) & comment_auto_terminate then
         call NewUndoRec()
         if not pos( '*/', line) then
            end_line
            keyin ' */'
         endif
         call einsert_line()

      else
         retc = 1
      endif  -- firstword =
   else
      retc = 1
   endif  -- .line
   return retc

