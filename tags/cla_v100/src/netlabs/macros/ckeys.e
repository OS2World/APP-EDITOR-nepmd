/****************************** Module Header *******************************
*
* Module Name: ckeys.e
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
/*                    C keys                            */
/*                                                      */
/* The enter and space bar keys have been defined to do */
/* specific C editing features.                         */

CONST
compile if not defined(I_like_my_cases_under_my_switch)
   I_like_my_cases_under_my_switch = 1
compile endif
compile if not defined(I_like_a_semicolon_supplied_after_default)
   I_like_a_semicolon_supplied_after_default = 0
compile endif
compile if not defined(ADD_BREAK_AFTER_DEFAULT)
   ADD_BREAK_AFTER_DEFAULT = 1
compile endif
compile if not defined(WANT_BRACE_BELOW_STATEMENT)
   WANT_BRACE_BELOW_STATEMENT = 0
compile endif
compile if not defined(WANT_BRACE_BELOW_STATEMENT_INDENTED)
   WANT_BRACE_BELOW_STATEMENT_INDENTED = 0
compile endif
compile if not defined(USE_ANSI_C_NOTATION)
   USE_ANSI_C_NOTATION = 1  -- 1 means use shorter ANSI C notation on MAIN.
compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
 compile if defined(WANT_END_BRACE_COMMENTED)
   WANT_END_COMMENTED = WANT_END_BRACE_COMMENTED
 compile else
   WANT_END_COMMENTED = 1
 compile endif
compile endif
compile if not defined(JAVA_SYNTAX_ASSIST)
   JAVA_SYNTAX_ASSIST = 0
compile endif

compile if not defined(C_SYNTAX_INDENT)
   C_SYNTAX_INDENT = SYNTAX_INDENT
compile endif

;compile if not defined(C_EXTENSIONS)  -- Keep in sync with TAGS.E
;   C_EXTENSIONS = 'C H SQC'
;compile endif

compile if not defined(CPP_EXTENSIONS)  -- Keep in sync with TAGS.E
   CPP_EXTENSIONS = 'CPP HPP CXX HXX SQX JAV JAVA'
compile endif


;  Keyset selection is now done once at file load time, not every time
;  the file is selected.  And because the DEFLOAD procedures don't have to be
;  kept together in the macros (ET will concatenate all the DEFLOADs the
;  same way it does DEFINITs), we can put the DEFLOAD here where it belongs,
;  with the rest of the keyset function.  (what a concept!)
-- Moved defload to MODE.E

compile if    WANT_CUA_MARKING
defkeys c_keys clear
compile else
defkeys c_keys
compile endif

def space=
   universal expand_on
   if expand_on then
      if  not c_first_expansion() then
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
      if not c_second_expansion() then
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

/* Taken out, interferes with some people's c_enter. */
;def c_enter=   /* I like Ctrl-Enter to finish the comment field also. */
;   getline line
;   if pos('/*',line) then
;      if not pos('*/',line) then
;         end_line;keyin' */'
;      endif
;   endif
;   down;begin_line

def c_x=       /* Force expansion if we don't have it turned on automatic */
   if not c_first_expansion() then
      call c_second_expansion()
   endif

define
compile if WANT_END_COMMENTED = '//'
   END_CATCH  = ' // endcatch'
   END_DO     = ' // enddo'
   END_FOR    = ' // endfor'
   END_IF     = ' // endif'
   END_SWITCH = ' // endswitch'
   END_TRY    = ' // endtry'
   END_WHILE  = ' // endwhile'
compile elseif WANT_END_COMMENTED
   END_CATCH  = ' /* endcatch */'
   END_DO     = ' /* enddo */'
   END_FOR    = ' /* endfor */'
   END_IF     = ' /* endif */'
   END_SWITCH = ' /* endswitch */'
   END_TRY    = ' /* endtry */'
   END_WHILE  = ' /* endwhile */'
compile else
   END_CATCH  = ''
   END_DO     = ''
   END_FOR    = ''
   END_IF     = ''
   END_SWITCH = ''
   END_TRY    = ''
   END_WHILE  = ''
compile endif

defproc c_first_expansion
   retc = 1
   if .line then
      getline line
      line=strip(line,'T')
      w=line
      wrd=upcase(w)
      ws = substr(line, 1, max(verify(line, ' '\9)-1,0))
compile if JAVA_SYNTAX_ASSIST
      java = (NepmdGetMode() = 'JAVA')
compile endif -- JAVA_SYNTAX_ASSIST
compile if CPP_SYNTAX_ASSIST
      cpp = (NepmdGetMode() = 'C') and (wordpos(filetype(), CPP_EXTENSIONS))
compile endif -- CPP_SYNTAX_ASSIST
compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
      ws2 = ws || substr('', 1, C_SYNTAX_INDENT)
compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED

      -- Skip expansion when cursor is not at line end
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      lw = strip( line_l, 'T' )
      if w <> lw then
         retc = 0

      elseif wrd='FOR' then
compile if WANT_BRACE_BELOW_STATEMENT
         replaceline w' (; ; )'
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}'END_FOR, .line+2
 compile else
         insertline ws'{', .line+1
         insertline ws'}'END_FOR, .line+2
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
compile else
         replaceline w' (; ; ) {'
         insertline ws'}'END_FOR, .line+1
compile endif -- WANT_BRACE_BELOW_STATEMENT
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         .col=.col+2
      elseif wrd='IF' then
compile if WANT_BRACE_BELOW_STATEMENT
         replaceline w' ()'
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}', .line+2
 compile else
         insertline ws'{', .line+1
         insertline ws'}', .line+2
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws'else', .line+3
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+4
         insertline ws2'}'END_IF, .line+5
 compile else
         insertline ws'{', .line+4
         insertline ws'}'END_IF, .line+5
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
compile else
         replaceline w' () {'
         insertline ws'} else {', .line+1
         insertline ws'}'END_IF, .line+2
compile endif -- WANT_BRACE_BELOW_STATEMENT
         if not insert_state() then insert_toggle
         call fixup_cursor()
         endif
         .col=.col+2
      elseif wrd='WHILE' then
compile if WANT_BRACE_BELOW_STATEMENT
         replaceline w' ()'
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}'END_WHILE, .line+2
 compile else
         insertline ws'{', .line+1
         insertline ws'}'END_WHILE, .line+2
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
compile else
         replaceline w' () {'
         insertline ws'}'END_WHILE, .line+1
compile endif -- WANT_BRACE_BELOW_STATEMENT
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         .col=.col+2
      elseif wrd='DO' then
compile if WANT_BRACE_BELOW_STATEMENT
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'} while (  );'END_DO, .line+2
 compile else
         insertline ws'{', .line+1
         insertline ws'} while (  );'END_DO, .line+2
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
         down
compile else
         replaceline w' {'
         insertline ws'} while (  );'END_DO, .line+1
compile endif -- WANT_BRACE_BELOW_STATEMENT
         call einsert_line()
         .col=.col+C_SYNTAX_INDENT    /* indent for new line */
      elseif wrd='SWITCH' then
compile if WANT_BRACE_BELOW_STATEMENT
         replaceline w' ()'
 compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}'END_SWITCH, .line+2
 compile else
         insertline ws'{', .line+1
         insertline ws'}'END_SWITCH, .line+2
 compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
compile else
         replaceline w' () {'
         insertline ws'}'END_SWITCH, .line+1
compile endif -- WANT_BRACE_BELOW_STATEMENT
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         .col=.col+2    /* move cursor between parentheses of switch ()*/
      elseif wrd='MAIN' then
         call enter_main_heading()
compile if CPP_SYNTAX_ASSIST
      elseif wrd='TRY' & cpp then
 compile if WANT_BRACE_BELOW_STATEMENT
  compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}'END_TRY, .line+2
  compile else
         insertline ws'{', .line+1
         insertline ws'}'END_TRY, .line+2
  compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws'catch (  )', .line+3
  compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+4
         insertline ws2'}'END_CATCH, .line+5
  compile else
         insertline ws'{', .line+4
         insertline ws'}'END_CATCH, .line+5
  compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
         down
 compile else
         replaceline w' {'
         insertline ws'}'END_TRY, .line+1
         insertline ws'catch (  ) {', .line+2
         insertline ws'}'END_CATCH, .line+3
 compile endif -- WANT_BRACE_BELOW_STATEMENT
      elseif cpp & wrd='CATCH' then
 compile if WANT_BRACE_BELOW_STATEMENT
         replaceline w' (  )'
  compile if WANT_BRACE_BELOW_STATEMENT_INDENTED
         insertline ws2'{', .line+1
         insertline ws2'}'END_CATCH, .line+2
  compile else
         insertline ws'{', .line+1
         insertline ws'}'END_CATCH, .line+2
  compile endif -- WANT_BRACE_BELOW_STATEMENT_INDENTED
 compile else
         replaceline w' (  ) {'
         insertline ws'}'END_CATCH, .line+1
 compile endif -- WANT_BRACE_BELOW_STATEMENT
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         .col=.col+3
compile endif -- CPP_SYNTAX_ASSIST
compile if JAVA_SYNTAX_ASSIST
      elseif wrd='PRINTLN(' & java then
         replaceline ws'System.out.println( );'
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         tab_word
compile endif -- JAVA_SYNTAX_ASSIST
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc c_second_expansion
   retc=1
   if .line then
      getline line
      parse value upcase(line) with '{' +0 a
      brace = pos('{', line)
      if .line < .last then
         next_is_brace = textline(.line+1)='{'
      else
         next_is_brace = 0
      endif
      --parse value line with wrd rest
      -- Set wrd only to text left from the cursor
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      parse value line_l with wrd rest

      i=verify(wrd,'({:;','M',1)-1
      if i<=0 then i=length(wrd) endif
      firstword=upcase(substr(wrd,1,i))
compile if CPP_SYNTAX_ASSIST
      cpp = (NepmdGetMode() = 'C') and (wordpos(filetype(), CPP_EXTENSIONS))
compile endif -- CPP_SYNTAX_ASSIST
      if firstword='FOR' then
         /* do tabs to fields of C for statement */
         cp=pos(';',line,.col)
         if cp and cp>=.col then
             .col=cp+2
         else
           cpn=pos(';',line,cp+1)
           if cpn and (cpn>=.col) then
             .col=cpn+2
           else
              if not brace and next_is_brace then down; endif
             call einsert_line()
             .col=.col+C_SYNTAX_INDENT
           endif
         endif
      elseif firstword='CASE' or firstword='DEFAULT' then
         call einsert_line()
         if .line>2 then  /* take a look at the previous line */
            getline prevline, .line-2
            prevline=upcase(prevline)
            parse value prevline with w .
            if pos('(', w) then
               parse value w with w '('
            endif
            if w='CASE' then  /* align case statements */
               i=pos('C',prevline)
               replaceline substr('',1,i-1)||wrd rest, .line-1
               .col=i
            elseif w<>'CASE' and w<>'SWITCH' and w<>'{' and prevline<>'' then  /* shift current line over */
               i=verify(prevline,' ')
               if i then .col=i endif
               if i>C_SYNTAX_INDENT then i=i-C_SYNTAX_INDENT else i=1 endif
               .col=i
               replaceline substr('',1,i-1)||wrd rest, .line-1
            endif
            /* get rid of line containing just a ; */
            if firstword='DEFAULT' and .line <.last then
               getline line, .line+1
               if line=';' then
                  deleteline .line+1
               endif
            endif
         endif
         .col=.col+C_SYNTAX_INDENT
      elseif firstword='BREAK' then
         call einsert_line()
         c=.col
         if .col>C_SYNTAX_INDENT then
            .col=.col-C_SYNTAX_INDENT
         endif
         keyin 'case :';left
         insertline substr('',1,c-1)'break;', .line+1
      elseif firstword='SWITCH' then
         if not brace and next_is_brace then down; endif
         call einsert_line()
         c=.col
compile if I_like_my_cases_under_my_switch
         keyin 'case :';left
compile else
         keyin substr(' ',1,C_SYNTAX_INDENT)'case :';left
         c=c+C_SYNTAX_INDENT
compile endif
         insertline substr(' ',1,c+C_SYNTAX_INDENT-1)'break;', .line+1
         /* look at the next line to see if this is the first time */
         /* the user typed enter on this switch statement */
         if .line<=.last-2 then
            getline line, .line+2
            i=verify(line,' ')
            if i then
               if substr(line,i,1)='}' then
compile if I_like_my_cases_under_my_switch
                  if i>1 then
                     i=i-1
                     insertline substr(' ',1,i)'default:', .line+2
                  else
                     insertline 'default:', .line+2
                  endif
compile else
                  i=i+C_SYNTAX_INDENT-1
                  insertline substr(' ',1,i)'default:', .line+2
compile endif
compile if ADD_BREAK_AFTER_DEFAULT
                  insertline substr(' ',1,i+C_SYNTAX_INDENT-1)'break;', .line+3
compile elseif I_like_a_semicolon_supplied_after_default then
                  insertline substr(' ',1,i+C_SYNTAX_INDENT)';', .line+3
compile endif
               endif
            endif
         endif
compile if CPP_SYNTAX_ASSIST
      elseif cpp & firstword='CATCH' then
         cp=pos('(  )', line, .col)
         if cp then
            .col=cp+2
            if not insert_state() then insert_toggle
                call fixup_cursor()
            endif
         else
            if not brace and next_is_brace then down; endif
            call einsert_line()
            .col=.col+C_SYNTAX_INDENT
         endif
compile endif -- CPP_SYNTAX_ASSIST
      elseif a='{' or firstword='{' then  /* firstword or last word {?*/
;        if firstword='{' then
;           replaceline  wrd rest      -- This shifts the { to col 1.  Why???
;           call einsert_line();.col=C_SYNTAX_INDENT+1
;        else
            call einsert_line()
            .col=.col+C_SYNTAX_INDENT
;        endif
      elseif firstword='MAIN' then
         call enter_main_heading()
compile if CPP_SYNTAX_ASSIST
      elseif (wordpos(firstword, 'DO IF ELSE WHILE') |
              (cpp & wordpos(firstword, 'TRY'))) then
compile else
      elseif wordpos(firstword, 'DO IF ELSE WHILE') then
compile endif -- CPP_SYNTAX_ASSIST
         if not brace and next_is_brace then down; endif
         call einsert_line()
         .col=.col+C_SYNTAX_INDENT
;        insert
;        .col=length(a)+2
compile if TERMINATE_COMMENTS
      elseif pos('/*',line) then
         if not pos('*/',line) then
            end_line;keyin' */'
         endif
         call einsert_line()
compile endif
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc enter_main_heading
compile if not USE_ANSI_C_NOTATION     -- Use standard notation
   temp=substr('',1,C_SYNTAX_INDENT)  /* indent spaces */
   replaceline 'main(argc, argv, envp)'
   insertline temp'int argc;', .line+1         /* double indent */
   insertline temp'char *argv[];', .line+2
   insertline temp'char *envp[];', .line+3
   insertline '{', .line+4
   insertline '', .line+5
   mainline = .line
   if .cursory<7 then
      .cursory=7
   endif
   mainline+5
   .col=C_SYNTAX_INDENT+1
   insertline '}', .line+1
compile else                           -- Use shorter ANSII notation
   replaceline 'main(int argc, char *argv[], char *envp[])'
   insertline '{', .line+1
   insertline '', .line+2
   .col=C_SYNTAX_INDENT+1
   insertline '}', .line+3
   mainline = .line
   if .cursory<4 then
      .cursory=4
   endif
   mainline+2
compile endif

