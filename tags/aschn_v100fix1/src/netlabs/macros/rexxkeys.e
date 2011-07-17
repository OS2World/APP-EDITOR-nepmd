/****************************** Module Header *******************************
*
* Module Name: rexxkeys.e
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
compile if not defined(REXX_SYNTAX_INDENT)
   REXX_SYNTAX_INDENT = SYNTAX_INDENT
compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
   WANT_END_COMMENTED = 1
compile endif
compile if not defined(REXX_SYNTAX_CASE)
   REXX_SYNTAX_CASE = 'lower'
compile endif
compile if not defined(REXX_SYNTAX_FORCE_CASE)
   REXX_SYNTAX_FORCE_CASE = 0
compile endif
compile if not defined(REXX_SYNTAX_NO_ELSE)
   REXX_SYNTAX_NO_ELSE = 0
compile endif

compile if REXX_SYNTAX_CASE <> 'lower' & REXX_SYNTAX_CASE <> 'Mixed'
   *** Error: REXX_SYNTAX_CASE must be "Lower" or "Mixed"
compile endif

-- Moved defload to MODE.E

compile if    WANT_CUA_MARKING
defkeys rexx_keys clear
compile else
defkeys rexx_keys
compile endif

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
; This is the definition for syntax expansion with <space>.
; If 0 is returned then
;    a normal <space> is processed,
; else
;    the keystroke was aleady processed by this procedure.
defproc rex_first_expansion
   retc = 0                            -- Default: don't expanded, enter a space
   if .line then
      getline line
      line = strip( line, 'T' )
      w = line
      wrd = upcase(w)

compile if REXX_SYNTAX_FORCE_CASE
      lb=copies(' ', max(1,verify(w,' '))-1)  -- Number of blanks before first word.
compile endif

      -- Skip expansion when cursor is not at line end (spaces not respected)
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      lw = strip( line_l, 'T' )
      if w <> lw then

      elseif wrd = 'IF' then
compile if REXX_SYNTAX_CASE = 'lower'
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'if then'
 compile else
         replaceline w' then'
 compile endif
 compile if not REXX_SYNTAX_NO_ELSE
         insertline substr(wrd,1,length(wrd)-2)'else',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'If Then'
 compile else
         replaceline w' Then'
 compile endif
 compile if not REXX_SYNTAX_NO_ELSE
         insertline substr(wrd,1,length(wrd)-2)'Else',.line+1
 compile endif
compile endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
         retc = 1

      elseif wrd='WHEN' Then
compile if REXX_SYNTAX_CASE = 'lower'
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'when then'
 compile else
         replaceline w' then'
 compile endif
compile else
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'When Then'
 compile else
         replaceline w' Then'
 compile endif
compile endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
         retc = 1

      elseif wrd='DO' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         replaceline lb'do'
 compile else
         replaceline lb'Do'
 compile endif
compile endif
compile if WANT_END_COMMENTED
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr(wrd,1,length(wrd)-2)'end /'||'* do *'||'/',.line+1
 compile else
         insertline substr(wrd,1,length(wrd)-2)'End /'||'* Do *'||'/',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr(wrd,1,length(wrd)-2)'end',.line+1
 compile else
         insertline substr(wrd,1,length(wrd)-2)'End',.line+1
 compile endif
compile endif
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
         retc = 1

      endif  -- w <> lw
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
compile if REXX_SYNTAX_FORCE_CASE
      parse value line with origword .
compile endif
      line = upcase(line)
      --parse value line with firstword .
      -- Set firstword only to text left from the cursor
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      parse value line_l with firstword rest

      c=max(1,verify(line,' '))-1  -- Number of blanks before first word.

      if firstword = 'SELECT' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         if origword<>'select' then
            replaceline overlay('select', textline(.line), c+1)
         endif
 compile else
         if origword<>'Select' then
            replaceline overlay('Select', textline(.line), c+1)
         endif
 compile endif
compile endif
compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c+REXX_SYNTAX_INDENT)'when',.line+1
         insertline substr('',1,c /*+REXX_SYNTAX_INDENT*/)'otherwise',.line+2
 compile if WANT_END_COMMENTED
         insertline substr('',1,c)'end  /'||'* select *'||'/',.line+3
 compile else
         insertline substr('',1,c)'end',.line+3
 compile endif
compile else
         insertline substr('',1,c+REXX_SYNTAX_INDENT)'When',.line+1
         insertline substr('',1,c /*+REXX_SYNTAX_INDENT*/)'Otherwise',.line+2
 compile if WANT_END_COMMENTED
         insertline substr('',1,c)'End  /'||'* Select *'||'/',.line+3
 compile else
         insertline substr('',1,c)'End',.line+3
 compile endif
compile endif
         '+1'                             -- Move to When clause
         .col = c+REXX_SYNTAX_INDENT+5         -- Position the cursor
         retc = 1

      elseif firstword = 'DO' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         if origword<>'do' then replaceline overlay('do', textline(.line), c+1); endif
 compile else
         if origword<>'Do' then replaceline overlay('Do', textline(.line), c+1); endif
 compile endif
compile endif
         call einsert_line()
         .col=.col+REXX_SYNTAX_INDENT
         retc = 1

      elseif firstword = 'IF' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         if origword<>'if' then replaceline overlay('if', textline(.line), c+1); endif
 compile else
         if origword<>'If' then replaceline overlay('If', textline(.line), c+1); endif
 compile endif
compile endif
         call einsert_line()
         .col=.col+REXX_SYNTAX_INDENT
         retc = 1

      elseif pos('THEN DO',line) > 0 or pos('ELSE DO',line) > 0 then
         p = pos('ELSE DO',line)  -- Don't be faked out by 'else doc = 5'
         if not p then
            p = pos('THEN DO',line)
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
            s1 = 'then do'
         else
            s1 = 'else do'
 compile else
            s1 = 'Then Do'
         else
            s1 = 'Else Do'
 compile endif
compile endif
         endif
         if p & not pos(substr(line, p+7, 1), ' ;') then
            return 0
         endif
compile if REXX_SYNTAX_FORCE_CASE
         if substr(textline(.line), p, 7)<>s1 then
            replaceline overlay(s1, textline(.line), p)
         endif
compile endif
         call einsert_line()
         .col=.col+REXX_SYNTAX_INDENT
compile if WANT_END_COMMENTED
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c)'end /'||'* do *'||'/',.line+1
 compile else
         insertline substr('',1,c)'End /'||'* Do *'||'/',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c)'end',.line+1
 compile else
         insertline substr('',1,c)'End',.line+1
 compile endif
compile endif
         retc = 1

compile if TERMINATE_COMMENTS
      elseif pos('/'||'*',line) then        -- Annoying to me, as I don't always
         if not pos('*'||'/',line) then     -- want a comment closed on that line
            end_line                        -- Enable if you wish by uncommenting
            keyin ' *''/'
         endif
         call einsert_line()
         retc = 1
compile endif

      endif  -- firstword =
   endif  -- .line
   return retc

