/****************************** Module Header *******************************
*
* Module Name: ekeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: ekeys.e,v 1.8 2005-11-15 16:29:35 aschn Exp $
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
/*                    E      keys                       */
/*                                                      */
/* The enter and space bar keys have been defined to do */
/* specific E3 syntax structures.                       */

const
;compile if not defined(E_SYNTAX_INDENT)
;   E_SYNTAX_INDENT = SYNTAX_INDENT
;compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif


;  Keyset selection is now done once at file load time, not every time
;  the file is selected.  And because the DEFLOAD procedures don't have to be
;  kept together in the macros (ET will concatenate all the DEFLOADs the
;  same way it does DEFINITs), we can put the DEFLOAD here where it belongs,
;  with the rest of the keyset function.  (what a concept!)
-- Moved defload to MODE.E

defkeys e_keys

def space
   universal expand_on
   if expand_on then
      if not e_first_expansion() then
         'Space'
      endif
   else
      'Space'
   endif

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
      if not e_second_expansion() then
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
   if not e_first_expansion() then
      call e_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetEIndent
   universal indent
compile if defined(E_SYNTAX_INDENT)
   ind = E_SYNTAX_INDENT  -- this const has priority, it is normally undefined
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


defproc e_first_expansion
   /*  up;down */
   retc = 1
   if .line then
      getline line
      line = strip( line, 'T' )
      w = line
      wrd = upcase(w)

      -- Skip expansion when cursor is not at line end
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      lw = strip( line_l, 'T' )
      if w <> lw then
         retc = 0

      elseif wrd='FOR' then
         replaceline w' =  to'
         insertline substr(wrd,1,length(wrd)-3)'endfor',.line+1
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
      elseif wrd='IF' then
         replaceline w' then'
         insertline substr(wrd,1,length(wrd)-2)'else',.line+1
         insertline substr(wrd,1,length(wrd)-2)'endif',.line+2
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
      elseif wrd='ELSEIF' then
         replaceline w' then'
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
      elseif wrd='WHILE' then
         replaceline w' do'
         insertline substr(wrd,1,length(wrd)-5)'endwhile',.line+1
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '
      elseif wrd='LOOP' then
         replaceline w
         insertline substr(wrd,1,length(wrd)-4)'endloop',.line+1
         call einsert_line()
         .col=.col+GetEIndent()
;     elseif wrd='DO' then
;        replaceline w
;        insertline substr(wrd,1,length(wrd)-2)'enddo',.line+1
;        call einsert_line()
;        .col=.col+GetEIndent()
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc e_second_expansion
   retc=1
   if .line then
      getline line
      --parse value line with wrd rest
      -- Set wrd only to text left from the cursor
      line_l = substr( line, 1, .col - 1 ) -- split line into two parts at cursor
      parse value line_l with wrd rest

      firstword=upcase(wrd)
      if firstword='FOR' then
         /* do tabs to fields of pascal for statement */
         parse value upcase(line) with a '='
         if length(a)>=.col then
            .col=length(a)+3
         else
            parse value upcase(line) with a 'TO'
            if length(a)>=.col then
               .col=length(a)+4
            else
               call einsert_line()
               .col=.col+GetEIndent()
            endif
         endif
      elseif wordpos(firstword, 'IF ELSEIF ELSE WHILE LOOP DO DEFC DEFPROC DEFLOAD DEF DEFMODIFY DEFSELECT DEFMAIN DEFINIT DEFEXIT') then
         if pos('END'firstword, upcase(line)) then
            retc = 0
         else
            call einsert_line()
            .col=.col+GetEIndent()
            if /* firstword='LOOP' | */ firstword='DO' then
               insertline substr(line,1,.col-GetEIndent()-1)'end'lowcase(wrd), .line+1
            endif
         endif
compile if TERMINATE_COMMENTS
      elseif pos('/*',line) then
;     elseif substr(firstword,1,2)='/*' then  /* see speed requirements */
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

