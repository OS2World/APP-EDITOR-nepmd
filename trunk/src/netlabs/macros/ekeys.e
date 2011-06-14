/****************************** Module Header *******************************
*
* Module Name: ekeys.e
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

; ---------------------------------------------------------------------------
defc EForceExpansion
   if e_first_expansion() then
      call e_second_expansion()
   endif

; ---------------------------------------------------------------------------
defproc GetEIndent
   universal indent
   ind = indent  -- will be changed at defselect for every mode, if defined
   if ind = '' | ind = 0 then
      ind = 3
   endif
   return ind

; ---------------------------------------------------------------------------
defc EFirstExpansion
   rc = e_first_expansion()  -- (rc = 0) = processed

defproc e_first_expansion
   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if .line then
      getline line
      line = strip( line, 'T')
      w = line
      wrd = upcase(w)

      -- Skip expansion when cursor is not at line end
      line_l = substr( line, 1, .col - 1) -- split line into two parts at cursor
      lw = strip( line_l, 'T')
      if w <> lw then
         retc = 1

      elseif wrd = 'FOR' then
         call NextCmdAltersText()
         replaceline w' =  to'
         insertline substr( wrd, 1, length(wrd) - 3)'endfor', .line+1
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'IF' then
         call NextCmdAltersText()
         replaceline w' then'
         insertline substr( wrd, 1, length(wrd) - 2)'else', .line + 1
         insertline substr( wrd, 1, length(wrd) - 2)'endif', .line + 2
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'ELSEIF' then
         call NextCmdAltersText()
         replaceline w' then'
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'WHILE' then
         call NextCmdAltersText()
         replaceline w' do'
         insertline substr( wrd, 1, length(wrd) - 5)'endwhile', .line + 1
         if not insert_state() then
            insert_toggle
            call fixup_cursor()
         endif
         keyin ' '

      elseif wrd = 'LOOP' then
         call NextCmdAltersText()
         replaceline w
         insertline substr( wrd, 1, length(wrd) - 4)'endloop', .line + 1
         call einsert_line()
         .col = .col + GetEIndent()

;     elseif wrd = 'DO' then
;        call NextCmdAltersText()
;        replaceline w
;        insertline substr( wrd, 1, length(wrd) - 2)'enddo', .line + 1
;        call einsert_line()
;        .col = .col + GetEIndent()

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

; ---------------------------------------------------------------------------
defc ESecondExpansion
   rc = e_second_expansion()  -- (rc = 0) = processed

defproc e_second_expansion
   universal comment_auto_terminate

   retc = 0  -- 0 = processed, otherwise 1 is returned
             -- (exchanged compared to standard EPM)
   if .line then
      getline line
      -- Set wrd only to text left from the cursor
      line_l = substr( line, 1, .col - 1) -- split line into two parts at cursor
      parse value line_l with wrd rest

      firstword = upcase(wrd)

      if firstword = 'FOR' then
         call NextCmdAltersText()
         parse value upcase(line) with a '='
         if length(a) >= .col then
            .col = length(a) + 3
         else
            parse value upcase(line) with a 'TO'
            if length(a) >= .col then
               .col = length(a) + 4
            else
               call einsert_line()
               .col = .col + GetEIndent()
            endif
         endif

      elseif wordpos(firstword, 'IF ELSEIF ELSE WHILE LOOP DO DEFC DEFPROC DEFLOAD DEF DEFMODIFY DEFSELECT DEFMAIN DEFINIT DEFEXIT') then
         if pos( 'END'firstword, upcase(line)) then
            retc = 1
         else
            call NextCmdAltersText()
            call einsert_line()
            .col = .col + GetEIndent()
            if /* firstword='LOOP' | */ firstword='DO' then
               insertline substr( line, 1, .col - GetEIndent() - 1)'end'lowcase(wrd), .line + 1
            endif
         endif

      elseif pos( '/*', line) & comment_auto_terminate then
         call NextCmdAltersText()
         if not pos( '*/', line) then
            end_line
            keyin ' */'
         endif
         call einsert_line()

      else
         retc = 1
      endif
   else
      retc = 1
   endif
   return retc

