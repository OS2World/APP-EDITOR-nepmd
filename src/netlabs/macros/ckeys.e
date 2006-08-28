/****************************** Module Header *******************************
*
* Module Name: ckeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ckeys.e,v 1.17 2006-08-28 16:40:35 aschn Exp $
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
/*
Todo:

-- Expand <Enter> -----------------------------------------------------------

ok xxxxx (xxx) {xxx}|   -->   xxxxx (xxx) {xxx}
                        -->   |

ok xxxxx (xxx) {|xxx}   -->   xxxxx (xxx) {     for WANT_BRACE_BELOW_STATEMENT = 0
                        -->      |xxx
                        -->   }

ok xxxxx (xxx) {|xxx}   -->   xxxxx (xxx)       for WANT_BRACE_BELOW_STATEMENT = 1
                        -->   {
                        -->      |xxx
                        -->   }

ok xxxx {|              -->   xxxxx {
                        -->      |


ok {|                   -->   {
                        -->      |

ok {|}                  -->   {
                        -->      |
                        -->   }

ok {|xxxx               -->   {
                        -->      |xxxxx

ok while (xxx) {|xxxx   -->   while (xxx) {
                        -->      |xxxxx

\  while (xxx) {xx|xx   -->   while (xxx) {xxxx
                        -->      |

ok while (xxx) {xx|xx   -->   while (xxx) {xx
                        -->      |xx

ok while (xxx) {|}      -->   while (xxx) {
                        -->      |
                        -->   }
\  xxxxx (xxx)| {xxx}   -->   xxxxx (xxx)
                        -->   {
                        -->      xxx
                        -->      |
                        -->   }

ok } else {|            -->   } else {
                        -->      |

-- <Enter> on line with non-closed paren ------------------------------------
   -- this will not respect current indent
-  xxxxx( xxxxx |       -->   xxxxx( xxxxx
                        -->          |

-  xxxxx ( xxxxx |      -->   xxxxx ( xxxxx
                        -->           |

-  xxxxx (xxxxx |       -->   xxxxx (xxxxx
                        -->          |

   -- stream mode only (break line at current pos)
-  xxxxx( xx|xxx        -->   xxxxx( xx
                        -->          |xxx

-  xxxxx( |)            -->   xxxxx(
                        -->          |)

-  xxxxx( |xxx)         -->   xxxxx(
                        -->          |xxx)

-  xxxxx( xxx)|         -->   xxxxx( xxx)
                        -->   |

-- Expand } -----------------------------------------------------------------
ok xxxx {               -->   xxxx {    <-- opening brace is highlighted
      xxxx              -->      xxxx
             |          -->   }|        <-- unindent, compared to non-blank line above

ok xxxx {               -->   xxxx {    <-- opening brace is highlighted
             |          -->   }|        <-- same indent, compared to non-blank line
                                        <-- with opening brace above

?  maybe unindent lines starting with }, dependent from the opening paren or
   the opening statement (e.g. if, else)  --> not required anymore

-- To be fixed --------------------------------------------------------------
ok expand 'int main' as well as 'main'

ok don't expand main twice

ok do
      {
      } while ();  <-- cursor on this line should not split line

ok do
   {
   } while ();  <-- cursor on this line should not split line

ok do| + <Space>        -->   do {
                        -->     |
                        -->   } while ();   <-- 1 space before ); too much

ok for + <Space>                        -->   for (|; ; ) {
                                        -->   }

ok fo|r ( xxx; xxx; xxx) { + <Enter>    -->   for ( xxx|; xxx; xxx) {
ok for ( xxx; x|xx; xxx) { + <Enter>    -->   for ( xxx; xxx|; xxx) {
ok for ( xxx; xxx|; xxx) { + <Enter>    -->   for ( xxx; xxx; xxx|) {
ok for ( xxx; xxx; xxx|) { + <Enter>    -->   for ( xxx; xxx; xxx) {
                                        -->      |

-  don't split line in line mode

!  don't add a new line after current -> examples?

; /*| <Enter>             -->   /*
;  *                      -->    * |
;  */                     -->    */      <-- bug: additional closing comment added
;                                *
; (/*)                           */

!  unindent "public:" and "private:" in CPP files to the level of the opening brace

-- <Return> on line with keyword --------------------------------------------
   -- before opening paren in stream and line mode
?  } whi|le (); + <Return>       -->   } while (|);
?  } whi|le (xxx); + <Return>    -->   } while (xxx|);
   -- after opening paren
?  } while (|); + <Return>       -->   } while ();
                                 -->   |

-- Options ------------------------------------------------------------------
-  omit { and } while expanding  <-- not much useful

   -- general options, selectable for every mode:
-  Change 1st expansion from <Space> to <Ctrl>+<Space>
-  Change 2nd expansion from <Enter> to <Ctrl>+<Enter>
   This would keep the rest of defined syntax expansion defs
-  Enable/disable add matching brace/bracket/parenthesis on typing opening one

-  Ignore blank lines when determining indent of last line
-  Ignore comments when determining indent of last line

-- Expand ; -----------------------------------------------------------------
-  add ; and a new, maybe unindented line

*/

; ---------------------------------------------------------------------------
; Set* commands for mode C
; ---------------------------------------------------------------------------

definit
   call AddAVar( 'selectsettingslist',
                        'CBraceStyle CCaseStyle CDefaultStyle CMainStyle' ||
                        ' CCommentStyle')

defc SetCBraceStyle
   universal c_brace_style
   ValidArgs = 'BELOW APPEND INDENT HALFINDENT'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'BELOW'
   endif
   c_brace_style = arg1
   call UseSetting( 'CBraceStyle', arg(1))

; Expand "case" statement. Place "case" statements below "switch" statement
; or indented.
defc SetCCaseStyle
   universal c_CASE_style
   ValidArgs = 'INDENT BELOW'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'INDENT'
   endif
   c_CASE_style = arg1
   call UseSetting( 'CCaseStyle', arg(1))

; Expand "default" statement. Add a semicolon or a "break" statement.
defc SetCDefaultStyle
   universal c_DEFAULT_style
   ValidArgs = 'ADDSEMICOLON ADDBREAK'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'ADDSEMICOLON'
   endif
   c_DEFAULT_style = arg1
   call UseSetting( 'CDefaultStyle', arg(1))

; Expand "main" statement.
defc SetCMainStyle
   universal c_MAIN_style
   ValidArgs = 'STANDARD SHORT'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'SHORT'
   endif
   c_MAIN_style = arg1
   call UseSetting( 'CMainStyle', arg(1))

; Used if END_commented = 1. Append either "// ..." or "/* ... */".
defc SetCCommentStyle
   universal c_comment_style
   ValidArgs = 'CPP C'
   arg1 = strip( upcase( arg(1)))
   if not wordpos( arg1, ValidArgs) then
      arg1 = 'CPP'
   endif
   c_comment_style = arg1
   call UseSetting( 'CCommentStyle', arg(1))

; ---------------------------------------------------------------------------
; const
; ; Now used only to distinguish between C and C++:
; compile if not defined(CPP_EXTENSIONS)  -- Keep in sync with TAGS.E
;    CPP_EXTENSIONS = 'CPP HPP CXX HXX SQX JAV JAVA'
; compile endif

; ---------------------------------------------------------------------------
defkeys c_keys

/* Taken out, interferes with some people's c_enter. */
; I like Ctrl-Enter to finish the comment field also.
;def c_enter
;   getline line
;   if pos( '/*', line) then
;      if not pos( '*/', line) then
;         end_line
;         keyin ' */'
;      endif
;   endif
;   down
;   begin_line

; Force expansion if we don't have it turned on automatic
def c_x
   if c_first_expansion() then
      call c_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetCIndent
   universal indent
   ind = indent  -- will be changed at defselect for every mode, if defined
   if ind = '' | ind = 0 then
      ind = 3
   endif
   return ind

; ---------------------------------------------------------------------------
; Want a space after starting parenthesis '(' of a function?
; Returns a space or nothing
defproc GetSSpc
   universal function_spacing
   if pos( 'S', function_spacing) then
      ret = ' '
   else
      ret = ''
   endif
   return ret

; Want a space between parameters, after a comma of a function?
; Returns a space or nothing
defproc GetCSpc
   universal function_spacing
   if pos( 'C', function_spacing) then
      ret = ' '
   else
      ret = ''
   endif
   return ret

; Want a space before ending parenthesis ')' of a function?
; Returns a space or nothing
defproc GetESpc
   universal function_spacing
   if pos( 'E', function_spacing) then
      ret = ' '
   else
      ret = ''
   endif
   return ret

; ---------------------------------------------------------------------------
defproc ExpandJava
   fjava = (GetMode() = 'JAVA')
   return fjava

; ---------------------------------------------------------------------------
; defproc ExpandCpp
;    fcpp = (GetMode() = 'C') & (wordpos( filetype(), CPP_EXTENSIONS))
;    return fcpp

; ---------------------------------------------------------------------------
defc CFirstExpansion
   rc = c_first_expansion()  -- (rc = 0) = processed

defproc c_first_expansion
   universal c_brace_style
   universal END_commented
   universal c_comment_style

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if END_commented = 1 then
      if c_comment_style = 'CPP' then
         END_CATCH  = ' // endcatch'
         END_DO     = ' // enddo'
         END_FOR    = ' // endfor'
         END_IF     = ' // endif'
         END_SWITCH = ' // endswitch'
         END_TRY    = ' // endtry'
         END_WHILE  = ' // endwhile'
      else
         END_CATCH  = ' /* endcatch */'
         END_DO     = ' /* enddo */'
         END_FOR    = ' /* endfor */'
         END_IF     = ' /* endif */'
         END_SWITCH = ' /* endswitch */'
         END_TRY    = ' /* endtry */'
         END_WHILE  = ' /* endwhile */'
      endif
   else
      END_CATCH  = ''
      END_DO     = ''
      END_FOR    = ''
      END_IF     = ''
      END_SWITCH = ''
      END_TRY    = ''
      END_WHILE  = ''
   endif

   if .line then
      getline line
      line = strip( line, 'T')
      w = line                                                   -- w   = current line, stripped trailing spaces
      wrd = upcase(w)                                            -- wrd = current line, stripped blanks, upcase
      wrd = strip(wrd)
      wrd = strip(wrd, 'b', \9)
      wrd = strip(wrd)
      ws  = substr( line, 1, max( verify( line, ' '\9) - 1, 0))  -- ws  = indent of current line
      ws1 = ws''substr( '', 1, GetCIndent())                     -- ws1 = indent of current line plus syntax indent
      wsh = ws''substr( '', 1, GetCIndent()%2)                   -- wsh = indent of current line plus half syntax indent
      p   = pos( wrd, upcase( line))                             -- p   = startpos of wrd in line

      -- Skip expansion when cursor is not at line end
      line_l = substr( line, 1, .col - 1) -- split line into two parts at cursor
      lw = strip( line_l, 'T')
      if w <> lw then
         retc = 1
         return retc

      elseif wrd = 'FOR' then
         if c_brace_style = 'INDENT' then
            replaceline w' (; ; )'
            insertline ws1'{', .line + 1
            insertline ws1'}'END_FOR, .line + 2
         elseif c_brace_style = 'HALFINDENT' then
            replaceline w' (; ; )'
            insertline wsh'{', .line + 1
            insertline wsh'}'END_FOR, .line + 2
         elseif c_brace_style = 'BELOW' then
            replaceline w' (; ; )'
            insertline ws'{', .line + 1
            insertline ws'}'END_FOR, .line + 2
         else
            replaceline w' (; ; ) {'
            insertline ws'}'END_FOR, .line + 1
         endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         .col = .col + 2

      elseif wrd = 'IF' then
         if c_brace_style = 'INDENT' then
            replaceline w' ()'
            insertline ws1'{', .line + 1
            insertline ws1'}', .line + 2
            insertline ws'else', .line + 3
            insertline ws1'{', .line + 4
            insertline ws1'}'END_IF, .line + 5
         elseif c_brace_style = 'HALFINDENT' then
            replaceline w' ()'
            insertline wsh'{', .line + 1
            insertline wsh'}', .line + 2
            insertline ws'else', .line + 3
            insertline wsh'{', .line + 4
            insertline wsh'}'END_IF, .line + 5
         elseif c_brace_style = 'BELOW' then
            replaceline w' ()'
            insertline ws'{', .line + 1
            insertline ws'}', .line + 2
            insertline ws'else', .line + 3
            insertline ws'{', .line + 4
            insertline ws'}'END_IF, .line + 5
         else
            replaceline w' () {'
            insertline ws'} else {', .line + 1
            insertline ws'}'END_IF, .line + 2
         endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         .col = .col + 2

      elseif wrd = 'WHILE' then
         if c_brace_style = 'INDENT' then
            replaceline w' ()'
            insertline ws1'{', .line + 1
            insertline ws1'}'END_WHILE, .line + 2
         elseif c_brace_style = 'HALFINDENT' then
            replaceline w' ()'
            insertline wsh'{', .line + 1
            insertline wsh'}'END_WHILE, .line + 2
         elseif c_brace_style = 'BELOW' then
            replaceline w' ()'
            insertline ws'{', .line + 1
            insertline ws'}'END_WHILE, .line + 2
         else
            replaceline w' () {'
            insertline ws'}'END_WHILE, .line + 1
         endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         .col = .col + 2

      elseif wrd = 'DO' then
         if c_brace_style = 'INDENT' then
            insertline ws1'{', .line + 1
            insertline ws1'} while ();'END_DO, .line + 2
            down
         elseif c_brace_style = 'HALFINDENT' then
            insertline wsh'{', .line + 1
            insertline wsh'} while ();'END_DO, .line + 2
            down
         elseif c_brace_style = 'BELOW' then
            insertline ws'{', .line + 1
            insertline ws'} while ();'END_DO, .line + 2
            down
         else
            replaceline w' {'
            insertline ws'} while ();'END_DO, .line + 1
         endif
         insertline ws1, .line + 1; down; endline

      elseif wrd = 'SWITCH' then
         if c_brace_style = 'INDENT' then
            replaceline w' ()'
            insertline ws1'{', .line + 1
            insertline ws1'}'END_SWITCH, .line + 2
         elseif c_brace_style = 'HALFINDENT' then
            replaceline w' ()'
            insertline wsh'{', .line + 1
            insertline wsh'}'END_SWITCH, .line + 2
         elseif c_brace_style = 'BELOW' then
            replaceline w' ()'
            insertline ws'{', .line + 1
            insertline ws'}'END_SWITCH, .line + 2
         else
            replaceline w' () {'
            insertline ws'}'END_SWITCH, .line + 1
         endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         .col = .col + 2    -- move cursor between parentheses of switch ()

      elseif wrd = 'MAIN' | (subword( wrd, 1, 1) = 'INT' & subword( wrd, 2, 1) = 'MAIN') then
         call enter_main_heading()

      elseif wrd = 'TRY' /*& ExpandCpp()*/ then
         if c_brace_style = 'INDENT' then
            insertline ws1'{', .line + 1
            insertline ws1'}'END_TRY, .line + 2
            insertline ws'catch ()', .line + 3
            insertline ws1'{', .line + 4
            insertline ws1'}'END_CATCH, .line + 5
            down
         elseif c_brace_style = 'HALFINDENT' then
            insertline wsh'{', .line + 1
            insertline wsh'}'END_TRY, .line + 2
            insertline ws'catch ()', .line + 3
            insertline wsh'{', .line + 4
            insertline wsh'}'END_CATCH, .line + 5
            down
         elseif c_brace_style = 'BELOW' then
            insertline ws'{', .line + 1
            insertline ws'}'END_TRY, .line + 2
            insertline ws'catch ()', .line + 3
            insertline ws'{', .line + 4
            insertline ws'}'END_CATCH, .line + 5
            down
         else
            replaceline w' {'
            insertline ws'}'END_TRY, .line + 1
            insertline ws'catch () {', .line + 2
            insertline ws'}'END_CATCH, .line + 3
         endif
         insertline ws1, .line + 1; down; endline

      elseif wrd = 'CATCH' /*& ExpandCpp()*/ then
         if c_brace_style = 'INDENT' then
            replaceline w' ('GetSSpc()''GetESpc()')'
            insertline ws1'{', .line + 1
            insertline ws1'}'END_CATCH, .line + 2
         elseif c_brace_style = 'HALFINDENT' then
            replaceline w' ('GetSSpc()''GetESpc()')'
            insertline wsh'{', .line + 1
            insertline wsh'}'END_CATCH, .line + 2
         elseif c_brace_style = 'BELOW' then
            replaceline w' ('GetSSpc()''GetESpc()')'
            insertline ws'{', .line + 1
            insertline ws'}'END_CATCH, .line + 2
         else
            replaceline w' () {'
            insertline ws'}'END_CATCH, .line + 1
         endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         .col = .col + 2 + length( GetSSpc())

      elseif wrd = 'PRINTLN(' & ExpandJava() then
         replaceline ws'System.out.println('GetSSpc()''GetESpc()');'
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         end_line
         .col = .col - 2 - length( GetESpc())

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

; ---------------------------------------------------------------------------
defc CSecondExpansion
   rc = c_second_expansion()  -- (rc = 0) = processed

defproc c_second_expansion
   universal c_CASE_style
   universal c_DEFAULT_style
   universal c_brace_style
   universal header_length
   universal header_style
   universal comment_auto_terminate

   retc = 0  -- 0 = processed, otherwise 1 is returned
   if .line then
      getline line                                               -- line = current line

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
      ind1 =  ind''copies( ' ', GetCIndent())                          -- ind1 = ind plus 1 level indented
-- Todo: Tabs2Spaces for line
-- doesn't handle Tabs near the end correctly:
      ind0 =  substr( ind, 1, max( length(ind) - GetCIndent(), 0))     -- ind0 = ind minus 1 level indented

      pobrace = pos( '{', line)
      sline = strip( strip( strip( textline( .line)), 'b', \t))
      this_is_obrace = (sline = '{')
      if .line < .last then
         snextline = strip( strip( strip( textline( .line + 1)), 'b', \t))
         next_is_obrace = (snextline = '{')
      else
         snextline = ''
         next_is_obrace = 0
      endif
      parse value line with w rest                               -- w  = first word
      parse value rest with w2 .                                 -- w2 = second word
      wrd = upcase(w)                                            -- wrd = first word, stripped blanks, upcase
      wrd = strip(wrd)
      wrd = strip(wrd, 'b', \9)
      wrd = strip(wrd)
      ws  = substr( line, 1, max( verify( line, ' '\9) - 1, 0))  -- ws  = indent of current line
      ws1 = ws''substr( '', 1, GetCIndent())                     -- ws1 = indent of current line plus syntax indent
      ws2 = ws1''substr( '', 1, GetCIndent())                    -- ws2 = indent of current line plus 2x syntax indent
      -- problem if tab at the end instead of spaces:
      ws0 = substr( line, 1, max( verify( line, ' '\9) - 1 - GetCIndent(), 0))
                                                                 -- ws0  = indent of current line minus syntax indent
      p = pos( wrd, upcase(line))                                -- p   = startpos of wrd in line

      i = verify( wrd, '({:;', 'M', 1) - 1                       -- i   = position before (|{|:|;
      if i <= 0 then i = length(wrd) endif                       -- if i = 0 then i = position of last char in wrd
      firstword = substr( wrd, 1, i)                             -- firstword = first word in line left from cursor, upcase

      wrd2 = upcase(w2)                                          -- wrd2 = second word, stripped trailing spaces, upcase

      j = verify( wrd2, '({:;', 'M', 1) - 1                      -- j   = position before (|{|:|;
      if j <= 0 then j = length(wrd2) endif                      -- if j = 0 then j = position of last char in wrd2
      secondword = substr( wrd2, 1, j)                           -- secondword = second word in line left from cursor, upcase

      line_l = substr( line, 1, .col - 1)                        -- line_l = line left from cursor pos
      line_r = substr( line, .col)                               -- line_r = line right from cursor pos
      cobrace = 0                                                -- cobrace = number of opening braces in left part of line
      ccbrace = 0                                                -- ccbrace = number of closing braces in left part of line
      n       = 0                                                -- n = number of open brace blocks in left part of line,
      rest = line_l                                              --     starting at first opening brace
      do forever
         p1 = pos( '{', rest)
         p2 = pos( '}', rest)
         if p1 > 0 /*& (p1 < p2 | p2 = 0)*/ then
            cobrace = cobrace + 1
            n = n + 1
            rest = substr( rest, p1 + 1)
         elseif p2 > p1 then
            ccbrace = ccbrace + 1
            if cobrace > 0 then
               n = n - 1
            endif
            rest = substr( rest, p2 + 1)
         else
            leave
         endif
      enddo

      if firstword = 'FOR' then
         cp = pos( ';', line, .col + 1)
         if cp and cp >= .col then
            .col = cp
         else
            cp = pos( ';', line, .col)
            if cp and (cp >= .col) then
               .col = cp + 2
               bp = pos( ')', line, .col)
               if bp then
                  .col = bp
               endif
            else
               if not pobrace and next_is_obrace then down; endif
               insertline ws1, .line + 1; down; endline
           endif
         endif

      elseif firstword = 'CASE' or firstword = 'DEFAULT' then
         insertline ws1, .line + 1; down; endline
         -- Get rid of line containing just a ;
         if firstword = 'DEFAULT' and .line < .last then
            getline line1, .line + 1
            line1 = strip( line1, 'b')
            line1 = strip( line1, 'b', \9)
            line1 = strip( line1, 'b')
            if line1 = ';' then
               deleteline .line + 1
            endif
         endif

      elseif firstword = 'BREAK' then
         insertline ws0'case :', .line + 1; down; endline; left
         insertline ws'break;', .line + 1

      elseif firstword = 'SWITCH' then
         if not pobrace and next_is_obrace then down; endif
         if c_CASE_style = 'BELOW' then
            insertline ws'case :', .line + 1; down; endline; left
            insertline ws1'break;', .line + 1
         else
            insertline ws1'case :', .line + 1; down; endline; left
            insertline ws2'break;', .line + 1
         endif

         -- Look at the next line to see if this is the first time
         -- the user typed enter on this switch statement
         if .line <= (.last - 2) then
            getline line2, .line + 2
            line2 = strip( line2, 't')
            line2 = strip( line2, 't', \9)
            line2 = strip( line2, 't')
            if substr( line2, length(line2), 1) = '}' then
               if c_CASE_style = 'BELOW' then
                  insertline ws'default:', .line + 2
                  if c_DEFAULT_style = 'ADDBREAK' then
                     insertline ws1'break;', .line + 3
                  elseif c_DEFAULT_style = 'ADDSEMICOLON' then
                     insertline ws';', .line + 3
                  endif
               else
                  insertline ws1'default:', .line + 2
                  if c_DEFAULT_style = 'ADDBREAK' then
                     insertline ws2'break;', .line + 3
                  elseif c_DEFAULT_style = 'ADDSEMICOLON' then
                     insertline ws1';', .line + 3
                  endif
               endif
            endif
         endif

      elseif firstword = 'CATCH' /*& ExpandCpp()*/ then
         cp = pos( '('GetSSpc()''GetESpc()')', line, .col)
         if cp then
            .col = cp + 2
            if not insert_state() then insert_toggle
                call fixup_cursor()
            endif
         else
            if not pobrace and next_is_obrace then down; endif
            insertline ws1, .line + 1; down; endline
         endif

      elseif n > 0 then
         -- Todo: don't split in line mode
         -- Todo: support c_brace_style = 'INDENT' (not for functions)
         -- Split line at cursor: replace current line with left part
         stline_l =  strip( strip( strip( line_l, 't'), 't', \t), 't')  -- strip trailing spaces and tabs
         replaceline stline_l, .line
         if rightstr( stline_l, 1) = '{' and not this_is_obrace and
            (c_brace_style = 'INDENT' or c_brace_style = 'BELOW' or ws = 0) then  -- ws = indent of current line; braces for
                                                         -- functions should be put on a separate line
            LeftPart = leftstr( stline_l, length(stline_l) - 1)
            if strip( translate( LeftPart, '', \9)) = '' then  -- if no string before {
               -- Let '{' on this line
               replaceline ws'{', .line; endline
            else
               -- Put '{' on next line
               replaceline LeftPart, .line
               insertline ws'{', .line + 1; down; endline
            endif
         endif
         sline_r =  strip( strip( strip( line_r), 'b', \t))  -- strip spaces and tabs
         if rightstr( sline_r, 1) = '}' then
            sline_r = leftstr( sline_r, length( sline_r) - 1)
            insertline ws'}', .line + 1;
         endif
         insertline ws1''sline_r, .line + 1; down; .col = length( ws1) + 1

      elseif firstword = 'MAIN' | (firstword = 'INT' & secondword = 'MAIN') then
         if not pos( '(', line) then
            call enter_main_heading()
         else
            if not pobrace and next_is_obrace then down; endif
            insertline ws1, .line + 1; down; endline
         endif

      elseif (wordpos( firstword, 'DO IF ELSE WHILE') |
              (wordpos( firstword, 'TRY') /*& ExpandCpp()*/)) then
         if not pobrace and next_is_obrace then down; endif
         insertline ws1, .line + 1; down; endline

      elseif firstword = '}' & secondword = 'WHILE' then
         insertline ws, .line + 1; down; endline

      elseif next_is_obrace then  -- add a blank, indented line after line with single opening brace
         down
         insertline ws1, .line + 1; down; endline

      elseif (firstword = '/*' | firstword = '/**') & words( tline) = 1 then
         insertline ind' * ', .line + 1
         -- Search for closing comment */
         fFound = 0
         startl = .line + 1
         do l = startl to .last
            if l > startl + 100 then  -- search only 100 next lines
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
         if not pos( '*/', line) then
            end_line; keyin ' */'
         endif
         call einsert_line()  -- respect user's style

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

; ---------------------------------------------------------------------------
defproc enter_main_heading
   universal c_MAIN_style
   getline w
   w = strip( w, 't')
   if c_MAIN_style = 'STANDARD' then  -- Use standard notation
      ind = substr( '', 1, GetCIndent())    -- indent spaces
      replaceline w'('GetSSpc()'argc,'GetCSpc()'argv,'GetCSpc()'envp'GetESpc()')'
      insertline ind'int argc;', .line + 1  -- double indent
      insertline ind'char *argv[];', .line + 2
      insertline ind'char *envp[];', .line + 3
      insertline '{', .line + 4
      insertline '', .line + 5
      mainline = .line
      if .cursory < 7 then
         .cursory = 7
      endif
      mainline + 5
      .col = GetCIndent() + 1
      insertline '}', .line + 1
   else                               -- Use shorter ANSII notation
      replaceline w'('GetSSpc()'int argc,'GetCSpc()'char *argv[],'GetCSpc()'char *envp[]'GetESpc()')'
      insertline '{', .line + 1
      insertline '', .line + 2
      .col = GetCIndent() + 1
      insertline '}', .line + 3
      mainline = .line
      if .cursory < 4 then
         .cursory = 4
      endif
      mainline + 2
   endif

