/****************************** Module Header *******************************
*
* Module Name: rexxkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: rexxkeys.e,v 1.9 2005-01-09 18:58:48 aschn Exp $
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
/**********************************************************************/
/*                             REXKEYS.E                              */
/*                                                                    */
/* The c_enter and space bar keys have been defined to do specific    */
/* REXX syntax structures.                                            */
/*                                                                    */
/* Based on EKEYS.E (part of the base E3 code)                        */
/* Written by B. Thompson, 22 Sep 1987                                */
/*                                                                    */
/**********************************************************************/
/*  Updated by Larry Margolis for EOS2 and EPM.  To include, set in   */
/*  your MYCNF.E:   REXX_SYNTAX_ASSIST = 1                            */
/*                                                                    */
/**********************************************************************/

const
;compile if not defined(REXX_SYNTAX_INDENT)
;   REXX_SYNTAX_INDENT = SYNTAX_INDENT
;compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
   WANT_END_COMMENTED = 0
compile endif
compile if not defined(REXX_SYNTAX_CASE)
   REXX_SYNTAX_CASE = 'LOWER'  -- 'LOWER' | 'MIXED' | 'UPPER'
compile endif
compile if not defined(REXX_SYNTAX_FORCE_CASE)
   REXX_SYNTAX_FORCE_CASE = 1
compile endif
compile if not defined(REXX_SYNTAX_NO_ELSE)
   REXX_SYNTAX_NO_ELSE = 0
compile endif
compile if not defined(REXX_DO_STYLE)
   REXX_DO_STYLE = 'NO_INDENT_AFTER_IF'  -- 'APPEND' | 'INDENT_AFTER_IF' | 'NO_INDENT_AFTER_IF'
compile endif

-- Moved defload to MODE.E

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

defkeys rexx_keys

def space=
   universal expand_on
   if expand_on then
      if not rex_first_expansion() then
         keyin ' '
      endif
   else
      keyin ' '
   endif
   undoaction 1, junk                -- Create a new state

compile if ASSIST_TRIGGER = 'ENTER'
def enter=
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
   universal enterkey
 compile endif
compile else
def c_enter=
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
   universal c_enterkey
 compile endif
compile endif
   universal expand_on

   if expand_on then
      if not rex_second_expansion() then
compile if ASSIST_TRIGGER = 'ENTER'
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
         call enter_common(enterkey)
 compile else
         call my_enter()
 compile endif
compile else  -- ASSIST_TRIGGER
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
         call enter_common(c_enterkey)
 compile else
         call my_c_enter()
 compile endif
compile endif -- ASSIST_TRIGGER
      endif
   else
compile if ASSIST_TRIGGER = 'ENTER'
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
      call enter_common(enterkey)
 compile else
      call my_enter()
 compile endif
compile else  -- ASSIST_TRIGGER
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
      call enter_common(c_enterkey)
 compile else
      call my_c_enter()
 compile endif
compile endif -- ASSIST_TRIGGER
   endif

def c_x=       -- Force expansion if we don't have it turned on automatic
   if not rex_first_expansion() then
      call rex_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetRexxIndent
   universal indent
compile if defined(REXX_SYNTAX_INDENT)
   ind = REXX_SYNTAX_INDENT  -- this const has priority, it is normally undefined
compile else
   ind = indent  -- will be changed at defselect for every mode, if defined
compile endif
   if ind = '' | ind = 0 then
compile if defined(SYNTAX_INDENT)
      ind = SYNTAX_INDENT
compile endif
   endif
   if ind = '' | ind = 0 then
      ind = 3
   endif
   return ind

; ---------------------------------------------------------------------------
; Convert case of a string, word by word. Keep spaces and Tabs.
defproc RexxSyntaxCase
   in = arg(1)
   --sayerror 'RexxSyntaxCase: in = ['in']'
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
      --sayerror 'RexxSyntaxCase: next = ['next']'
      if upcase( substr( REXX_SYNTAX_CASE, 1, 1)) = 'L' then
         next = lowcase( next)
      elseif upcase( substr( REXX_SYNTAX_CASE, 1, 1)) = 'U' then
         next = upcase( next)
      elseif upcase( substr( REXX_SYNTAX_CASE, 1, 1)) = 'M' then
         next = lowcase( next)
         next = upcase( substr( next, 1, 1))''substr( next, 2)
      endif
      out = overlay( next, out, startp)
      if pb = 0 then
         leave
      endif
      startp = p
   enddo
   --sayerror 'RexxSyntaxCase: out = ['out']'
   return out

; ---------------------------------------------------------------------------
; This is the definition for syntax expansion with <space>.
; If 0 is returned then
;    a normal <space> is processed,
; else
;    the keystroke was aleady processed by this procedure.
defproc rex_first_expansion
   retc = 0                            -- Default: don't expanded, enter a space
   if .line then
      getline line
      sline = StripBlanks( line, 'T')
      wrd = upcase( StripBlanks( sline, 'L'))                      -- wrd = current line, stripped, uppercase
      ind = substr( sline, 1, max( 1, verify( sline, ' '\t)) - 1)  -- ind = blanks before first word
      col = .col

      -- Skip expansion if word before cursor is not a keyword or if some string follows
      if not (length(sline) = .col - 1) then
         -- cursor is not behind the last word: skip expansion
      elseif wrd = '' then
         -- empty line: skip expansion

      elseif wrd = 'IF' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline ind''RexxSyntaxCase( 'if  then')
compile else
         replaceline sline''RexxSyntaxCase( '  then')
compile endif
compile if not REXX_SYNTAX_NO_ELSE
         insertline ind''RexxSyntaxCase( 'else'), .line + 1
compile endif
         .col = col + 1
         retc = 1

      elseif wrd = 'WHEN' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline ind''RexxSyntaxCase( 'when  then')
compile else
         replaceline sline''RexxSyntaxCase( '  then')
compile endif
         .col = col + 1
         retc = 1

      elseif wrd = 'DO' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline ind''RexxSyntaxCase( 'do ')
compile else
         replaceline sline' '
compile endif
compile if WANT_END_COMMENTED
         insertline ind''RexxSyntaxCase( 'end /* do */'),.line+1
compile else
         insertline ind''RexxSyntaxCase( 'end'),.line+1
compile endif
         .col = col + 1
         retc = 1

      endif  -- sline <> line_l
   endif  -- .line
   return retc

; ---------------------------------------------------------------------------
; This is the definition for syntax expansion with <enter>.
; If 0 is returned then
;    a normal <enter> is processed,
; else
;    the keystroke was aleady processed by this procedure.
defproc rex_second_expansion
   retc = 0                               -- Default:, don't expanded, insert a line
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
compile if REXX_SYNTAX_FORCE_CASE
            s1 = 'then do'
         else
            s1 = 'else do'
compile endif
         endif
         -- Skip expansion, if THEN DO or ELSE DO is not followed by a semicolon or space.
         -- Lineend is handled as space in EPM's edit window.
         if p & not pos( substr( tline, p + 7, 1), ' ;') then
            return 0
         endif
-- Todo: skip expansion, if matching END found.
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( s1), line, p)
compile endif
         insertline ind1'', .line + 1
compile if WANT_END_COMMENTED
         insertline ind''RexxSyntaxCase( 'end /* do */'), .line + 2
compile else
         insertline ind''RexxSyntaxCase( 'end'), .line + 2
compile endif
         '+1'
         endline
         retc = 1

      elseif firstword = 'SELECT' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( 'select'), line, firstp)
compile endif
         insertline ind1''RexxSyntaxCase( 'when  then'), .line + 1
         insertline ind''RexxSyntaxCase( 'otherwise'), .line + 2
compile if WANT_END_COMMENTED
         insertline ind''RexxSyntaxCase( 'end /* select */'), .line + 3
compile else
         insertline ind''RexxSyntaxCase( 'end'), .line + 3
compile endif
         '+1'                             -- Move to When clause
         endline
         .col = .col - 5
         retc = 1

      elseif firstword = 'DO' then
         lastind = ind
         nextind = ind1
         endl = 0
         endp = 0
         appendl = 0
         if wordpos( upcase(REXX_DO_STYLE), 'APPEND NO_INDENT_AFTER_IF') then
            -- Check for previous line with a trailing 'THEN' and get its indent
            if .line > 1 then
               -- Inspect previous line
               -- Don't ignore blank lines here
               getline linel, .line - 1
               if lastword( translate( upcase(linel), ' ', \t)) = 'THEN' then
                  -- Get indent of line before with IF|WHEN|OTHERWISE
                  -- Re-indent DO line: take indent of line before
                  -- or append DO and the rest to THEN line
                  if upcase(REXX_DO_STYLE) = 'APPEND' then
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
                  if upcase(REXX_DO_STYLE) = 'APPEND' then
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
                  -- Search for first word
                  if wordpos( word( next, 1), 'END END;') then
                     endl = l
                     endp = pos( 'END', translate(linel))
                     --sayerror 'end line = 'endl' ['linel']'
                     leave
                  endif
            enddo
         endif
         -- Re-indent END line
         -- must come first
         if endp > 0 then
compile if REXX_SYNTAX_FORCE_CASE
            next = overlay( RexxSyntaxCase( 'end'), textline(endl), endp)
            replaceline lastind''substr( next, endp), endl  -- re-indent END line
compile else
            replaceline lastind''substr( textline(endl), endp), endl  -- re-indent END line
compile endif
         endif
compile if REXX_SYNTAX_FORCE_CASE
         next = overlay( RexxSyntaxCase( 'do'), line, firstp)
compile else
         next = line
compile endif
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
         retc = 1

      elseif firstword = 'IF' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( 'if'), line, firstp)
compile endif
         insertline ind1'', .line + 1
         '+1'
         endline
         retc = 1

      elseif firstword = 'WHEN' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( 'when'), line, firstp)
compile endif
         insertline ind1, .line + 1
         '+1'
         endline
         retc = 1

      elseif firstword = 'OTHERWISE' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( 'otherwise'), line, firstp)
compile endif
         insertline ind1, .line + 1
         '+1'
         endline
         retc = 1

      elseif firstword = 'ELSE' then
compile if REXX_SYNTAX_FORCE_CASE
         replaceline overlay( RexxSyntaxCase( 'else'), line, firstp)
compile endif
         insertline ind1, .line + 1
         '+1'
         endline
         retc = 1

compile if TERMINATE_COMMENTS
      elseif pos('/*',line) then        -- Annoying to me, as I don't always
         if not pos('*/',line) then     -- want a comment closed on that line
            end_line                    -- Enable if you wish by uncommenting
            keyin ' */'
         endif
         call einsert_line()
         retc = 1
compile endif

      endif  -- firstword =
   endif  -- .line
   return retc

