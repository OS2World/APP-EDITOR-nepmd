/****************************** Module Header *******************************
*
* Module Name: pkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: pkeys.e,v 1.10 2006-03-04 16:05:43 aschn Exp $
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

; ---------------------------------------------------------------------------
defkeys pas_keys

/* Taken out, interferes with some people's c_enter. */
;def c_enter  -- I like Ctrl-Enter to finish the comment field also.
;   getline line
;   if pos( '{', line) then
;      if not pos( '}', line) then
;         end_line;
;         keyin ' }'
;      endif
;   endif
;   down;
;   begin_line

def c_x=       -- Force expansion if we don't have it turned on automatic
   if pas_first_expansion() then
      call pas_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetPIndent
   universal indent
   ind = indent  -- will be changed at defselect for every mode, if defined
   if ind = '' | ind = 0 then
      ind = 3
   endif
   return ind

; ---------------------------------------------------------------------------
defc PasFirstExpansion
   rc = pas_first_expansion()  -- (rc = 0) = processed

defproc pas_first_expansion
   universal END_commented

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if END_commented = 1 then
      END_FOR     = ' {endfor}'
      END_IF      = ' {endif}'
      END_WHILE   = ' {endwhile}'
      END_REPEAT  = ' {endrepeat}'
      END_CASE    = ' {endcase}'
   else
      END_FOR     = ''
      END_IF      = ''
      END_WHILE   = ''
      END_REPEAT  = ''
      END_CASE    = ''
   endif

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
         insertline substr( wrd, 1, length(wrd) - 3)'end;'END_FOR, .line + 1
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'IF' then
         replaceline w' then begin'
         insertline substr( wrd, 1, length(wrd) - 2)'end else begin', .line + 1
         insertline substr( wrd, 1, length(wrd) - 2)'end;'END_IF, .line + 2
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '

     elseif wrd = 'WHILE' then
         replaceline w' do begin'
         insertline substr( wrd, 1, length(wrd) - 5)'end;'END_WHILE, .line + 1
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'REPEAT' then
         replaceline w
         insertline substr( wrd, 1, length(wrd) - 6)'until  ;'END_REPEAT, .line + 1
         call einsert_line()
         .col = .col + GetPIndent()

      elseif wrd = 'CASE' then
         replaceline w' of'
         insertline substr( wrd, 1, length(wrd) - 4)'end;'END_CASE, .line + 1
         if not insert_state() then insert_toggle
             call fixup_cursor()
         endif
         keyin ' '

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

; ---------------------------------------------------------------------------
defc PasSecondExpansion
   rc = pas_second_expansion()  -- (rc = 0) = processed

defproc pas_second_expansion
   universal comment_auto_terminate
   universal END_commented

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)

   if .line then
      getline line
      parse value upcase(line) with 'BEGIN' +0 a  -- get stuff after begin
      parse value line with wrd rest
      firstword=upcase(wrd)

      if firstword='FOR' then
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

      elseif a = 'BEGIN' or firstword = 'BEGIN' or firstword = 'CASE' or firstword = 'REPEAT' then  -- firstword or last word begin?
;        if firstword='BEGIN' then
;           replaceline wrd rest
;           insert
;           .col = GetPIndent() + 1
;        else
            call einsert_line()
            .col = .col + GetPIndent()
;        endif

      elseif firstword = 'VAR' or firstword = 'CONST' or firstword = 'TYPE' or firstword = 'LABEL' then
         if substr( line, 1, 2) <> '  ' or substr( line, 1, 3) = '   ' then
            getline line2
            replaceline substr( '', 1, GetPIndent())''wrd rest  -- <indent> spaces
            call einsert_line()
            .col = .col + GetPIndent()
         else
            call einsert_line()
         endif

      elseif firstword = 'PROGRAM' then
         parse value rest with name ';'
         if END_commented = 1 then
            END_NAME = ' { 'name' }'
         else
            END_NAME = ''
         endif
         getline bottomline, .last
         parse value bottomline with lastname .
         if lastname = 'end.' then
            retc= 1
            return retc
         else
            call einsert_line()
            insertline 'begin'END_NAME, .last + 1
            insertline 'end.'END_NAME, .last + 1
         endif

      elseif firstword = 'UNIT' then       -- Added by M. Such
         parse value rest with name ';'
         if END_commented = 1 then
            END_NAME = ' { 'name' }'
         else
            END_NAME = ''
         endif
         getline bottomline, .last
         parse value bottomline with lastname .
         if  lastname = 'end.' then
            retc = 1
            return retc
         else
            call einsert_line()
            insertline 'interface', .last + 1
            insertline 'implementation', .last + 1
            insertline 'end.'END_NAME, .last + 1
         endif

      elseif firstword = 'PROCEDURE' then
         name = getheading_name(rest)
         if END_commented = 1 then
            END_NAME = ' { 'name' }'
         else
            END_NAME = ''
         endif
         call einsert_line()
         insertline 'begin'END_NAME, .line + 1
         insertline 'end;'END_NAME, .line + 2

      elseif firstword = 'FUNCTION' then
         name = getheading_name(rest)
         if END_commented = 1 then
            END_NAME = ' { 'name' }'
         else
            END_NAME = ''
         endif
         call einsert_line()
         insertline 'begin'END_NAME, .line + 1
         insertline 'end;'END_NAME, .line + 2

      elseif pos( '(*', line) & comment_auto_terminate then
         if not pos( '*)', line) then
            end_line
            keyin ' *)'
         endif
         call einsert_line()

      elseif pos( '{', line) & comment_auto_terminate then
         if not pos( '}', line) then
            end_line
            keyin ' }'
         endif
         call einsert_line()

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

; ---------------------------------------------------------------------------
; name of heading
defproc getheading_name
   afterheadingp = verify( upcase(arg(1)), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789')
   len = max( 0, afterheadingp - 1)
   return substr( arg(1), 1, len)

