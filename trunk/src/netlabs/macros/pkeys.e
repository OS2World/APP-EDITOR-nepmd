/****************************** Module Header *******************************
*
* Module Name: pkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: pkeys.e,v 1.8 2006-01-14 17:47:26 aschn Exp $
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
/*                    PASCAL keys                       */
/*                                                      */
/* The enter and space bar keys have been defined to do */
/* specific Pascal syntax structures.                   */

const
;compile if not defined(P_SYNTAX_INDENT)
;   P_SYNTAX_INDENT = SYNTAX_INDENT
;compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
   WANT_END_COMMENTED = 1
compile endif

;  Keyset selection is now done once at file load time, not every time
;  the file is selected.  And because the DEFLOAD procedures don't have to be
;  kept together in the macros (ET will concatenate all the DEFLOADs the
;  same way it does DEFINITs), we can put the DEFLOAD here where it belongs,
;  with the rest of the keyset function.  (what a concept!)
-- Moved defload to MODE.E

; ---------------------------------------------------------------------------
defkeys pas_keys

/* Taken out, interferes with some people's c_enter. */
;def c_enter=   /* I like Ctrl-Enter to finish the comment field also. */
;   getline line
;   if pos('{',line) then
;      if not pos('}',line) then
;         end_line;keyin' }'
;      endif
;   endif
;   down;begin_line

def c_x=       /* Force expansion if we don't have it turned on automatic */
   if not pas_first_expansion() then
      call pas_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetPIndent
   universal indent
compile if defined(P_SYNTAX_INDENT)
   ind = P_SYNTAX_INDENT  -- this const has priority, it is normally undefined
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
defc PasFirstExpansion
   rc = (pas_first_expansion() = 0)

defproc pas_first_expansion
   retc=1
   if .line then
      getline line
      line = strip( line, 'T')
      w = line
      wrd = upcase(w)

      -- Skip expansion when cursor is not at line end
      line_l = substr( line, 1, .col - 1) -- split line into two parts at cursor
      lw = strip( line_l, 'T')
      if w <> lw then
         retc = 0

      elseif wrd = 'FOR' then
         replaceline w' :=  to  do begin'
compile if WANT_END_COMMENTED
         insertline substr( wrd, 1, length(wrd) - 3)'end; {endfor}', .line + 1
compile else
         insertline substr( wrd, 1, length(wrd) - 3)'end;', .line + 1
compile endif
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '
      elseif wrd = 'IF' then
         replaceline w' then begin'
         insertline substr( wrd, 1, length(wrd) - 2)'end else begin', .line + 1
compile if WANT_END_COMMENTED
         insertline substr( wrd, 1, length(wrd) - 2)'end; {endif}', .line + 2
compile else
         insertline substr( wrd, 1, length(wrd) - 2)'end;', .line + 2
compile endif
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '
     elseif wrd = 'WHILE' then
         replaceline w' do begin'
compile if WANT_END_COMMENTED
         insertline substr( wrd, 1, length(wrd) - 5)'end; {endwhile}', .line + 1
compile else
         insertline substr( wrd, 1, length(wrd) - 5)'end;', .line + 1
compile endif
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '
      elseif wrd = 'REPEAT' then
         replaceline w
compile if WANT_END_COMMENTED
         insertline substr( wrd, 1, length(wrd) - 6)'until  ; {endrepeat}', .line + 1
compile else
         insertline substr( wrd, 1, length(wrd) - 6)'until  ;', .line + 1
compile endif
         call einsert_line()
         .col = .col + GetPIndent()
      elseif wrd = 'CASE' then
         replaceline w' of'
compile if WANT_END_COMMENTED
         insertline substr( wrd, 1, length(wrd) - 4)'end; {endcase}', .line + 1
compile else
         insertline substr( wrd, 1, length(wrd) - 4)'end;', .line + 1
compile endif
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

; ---------------------------------------------------------------------------
defc PasSecondExpansion
   rc = (pas_second_expansion() = 0)

defproc pas_second_expansion
   retc = 1
   if .line then
      getline line
      parse value upcase(line) with 'BEGIN' +0 a /* get stuff after begin */
      parse value line with wrd rest
      firstword=upcase(wrd)
      if firstword='FOR' then
         /* do tabs to fields of pascal for statement */
         parse value upcase(line) with a ':='
         if length(a) >= .col then
            .col = length(a) + 4
         else
            parse value upcase(line) with a 'TO'
            if length(a) >= .col then
               .col = length(a) + 4
            else
               call einsert_line()
               .col = .col + GetPIndent()
            endif
         endif
      elseif a = 'BEGIN' or firstword = 'BEGIN' or firstword = 'CASE' or firstword = 'REPEAT' then  /* firstword or last word begin?*/
;        if firstword='BEGIN' then
;           replaceline  wrd rest
;           insert;.col=GetPIndent()+1
;        else
            call einsert_line()
            .col = .col + GetPIndent()
;        endif
      elseif firstword = 'VAR' or firstword = 'CONST' or firstword = 'TYPE' or firstword = 'LABEL' then
         if substr( line, 1, 2) <> '  ' or substr( line, 1, 3) = '   ' then
            getline line2
            replaceline substr( '', 1, GetPIndent())||wrd rest  -- <indent> spaces
            call einsert_line()
            .col = .col + GetPIndent()
         else
            call einsert_line()
         endif
      elseif firstword = 'PROGRAM' then
         /* make up a nice program block */
         parse value rest with name ';'
         getline bottomline, .last
         parse value bottomline with lastname .
         if lastname = 'end.' then
            retc= 0     /* no expansion */
         else
;           replaceline  wrd rest
            call einsert_line()
compile if WANT_END_COMMENTED
            insertline 'begin {' name '}', .last + 1
            insertline 'end. {' name '}', .last + 1
compile else
            insertline 'begin', .last + 1
            insertline 'end.', .last + 1
compile endif
         endif
      elseif firstword = 'UNIT' then       -- Added by M. Such
         /* make up a nice unit block */
         parse value rest with name ';'
         getline bottomline, .last
         parse value bottomline with lastname .
         if  lastname = 'end.' then
            retc = 0     /* no expansion */
         else
;           replaceline  wrd rest
            call einsert_line()
            insertline 'interface', .last + 1
            insertline 'implementation', .last + 1
compile if WANT_END_COMMENTED
            insertline 'end. {' name '}', .last + 1
compile else
            insertline 'end.', .last + 1
compile endif
         endif
      elseif firstword = 'PROCEDURE' then
         /* make up a nice program block */
         name = getheading_name(rest)
;        replaceline  wrd rest
         call einsert_line()
compile if WANT_END_COMMENTED
         insertline 'begin {' name '}', .line + 1
         insertline 'end; {' name '}', .line + 2
compile else
         insertline 'begin', .line + 1
         insertline 'end;', .line + 2
compile endif
      elseif firstword = 'FUNCTION' then
         /* make up a nice program block */
         name = getheading_name(rest)
;        replaceline  wrd rest
         call einsert_line()
compile if WANT_END_COMMENTED
         insertline 'begin {' name '}', .line + 1
         insertline 'end; {' name '}', .line + 2
compile else
         insertline 'begin', .line + 1
         insertline 'end;', .line + 2
compile endif
compile if TERMINATE_COMMENTS
      elseif pos( '{', line) then
         if not pos( '}', line) then
            end_line
            keyin ' }'
         endif
         call einsert_line()
compile endif
      else
         retc = 0
      endif
   else
      retc = 0
   endif
   return retc

; ---------------------------------------------------------------------------
defproc getheading_name          /*  (heading ) name of heading */
   afterheadingp = verify( upcase(arg(1)), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789')
   len = max( 0, afterheadingp - 1)
   return substr( arg(1), 1, len)

