/****************************** Module Header *******************************
*
* Module Name: textproc.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: textproc.e,v 1.2 2004-07-01 11:09:12 aschn Exp $
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

; The additions are, on the "no mark" pop-up menu, Mark Sentence
; and Mark Paragraph; on the "inside mark" pop-up, Extend Sentence
; Mark and Extend Paragraph Mark; and new mouse click actions:
;   Alt+Double-click button 2 = Mark sentence
;   Ctrl+Alt+Double-click button 2 = Mark paragraph
;   Shift+Alt+Double-click button 2 = Extend mark to end of next sentence
;   Ctrl+Shift+Alt+Double-click button 2 = Extend mark to end of next paragraph
;
; (Not all that memorable, but the best I could do with what was free.
; A 3-button mouse would help here...)
;
; It should be trivial for anyone who's done any EPM macro programming to
; define keys to invoke these functions if they want.
;
; --
; Larry Margolis, margoli@ibm.net
; http://groups.google.com/groups?selm=5957rh%241buc%242%40news-s01.ca.us.ibm.net&rnum=9

; Some subroutines for dealing with textual units (sentences and paragraphs)
; by Larry Margolis, margoli@ibm.net

compile if not defined(CHAR_MARK_REQUIRED__MSG)  -- Should be moved to ENGLISH.E
   const CHAR_MARK_REQUIRED__MSG = 'Character mark required.'
compile endif

; A routine to move to the end a sentence.  Optional argument is a flag
; saying to skip the end-sentence characters, so we move to the next sentence
; if we're at the end of one - used by the mark_through_next_sentence routine.
defproc end_sentence
   universal two_spaces
   getsearch savesearch
   display -2
   if arg(1) then  -- Skip if at end of current sentence
      'xcom l /[^]\)''".?!]/x'
   endif
   if two_spaces then  -- original def
      'xcom l /[.?!][])''"]*([ \t][ \t]|:o$)/x'
   else
      'xcom l /[.?!][])''"]*([ \t]|:o$)/x'
   endif
   if rc then
      .line = .last
      endline
      'xcom l /[^ \t]/-rx'
   endif
   display 2
   setsearch savesearch


; A routine to move to the beginning a sentence.
defproc begin_sentence
   universal two_spaces
   getsearch savesearch
   if pos(substr(textline(.line), .col, 1), '.!?') then
      if .col>1 then
         left
      else
         up; endline
      endif
   endif
   display -2
   if two_spaces then  -- original def
      'xcom l /[.!?][])''"]*([ \t][ \t]|:o$)/x-r'
   else
      'xcom l /[.!?][])''"]*([ \t]|:o$)/x-r'
   endif
   if rc then
      0
   else
      tab_word
   endif
   'xcom l /[^ \t]/x'
   display 2
   setsearch savesearch

; A routine to mark a sentence.  Pretty simple, given the above two routines.
defproc mark_sentence
   call psave_pos(save_pos)
   unmark
   end_sentence()
   mark_char
   begin_sentence()
   mark_char
   call prestore_pos(save_pos)
   match_postsentence_char()

; A routine to extend the current character mark through the end of the
; following sentence.
defproc mark_through_next_sentence
   if leftstr(marktype(), 1)<>'C' then
      sayerror CHAR_MARK_REQUIRED__MSG
      return
   endif
   getmark firstline,lastline,firstcol,lastcol,markfileid
   getfileid fileid
   if fileid<>markfileid then
      sayerror OTHER_FILE_MARKED__MSG
      return
   endif
   call psave_pos(save_pos)
   call pend_mark()
   end_sentence(1)
   mark_char
   call prestore_pos(save_pos)
   match_postsentence_char()

; A routine to move to the end a paragraph.  Optional argument is a flag
; saying to skip the end-paragraph stuff, so we move to the next paragraph
; if we're at the end of one - used by the mark_through_next_paragraph routine.
defproc end_paragraph
   getsearch savesearch
   display -2
   if arg(1) then  -- Skip if at end of current paragraph
      'xcom l /[^ \t]/x'
   endif
   '+1'; beginline
   'xcom l /^(:w|$)/x'
   if rc then
      ''.last; endline
   else
      '-1'
      endline
   endif
   display 2
   setsearch savesearch

; A routine to move to the beginning a paragraph.
defproc begin_paragraph
   getsearch savesearch
   display -2
   'xcom l /^(:w|$)/-rx'
   if rc then
      1; beginline
   elseif textline(.line)='' then
      '+1'; beginline
   endif
   display 2
   setsearch savesearch

; A routine to mark a paragraph.  Pretty simple, given the above two routines.
defproc mark_paragraph
   call psave_pos(save_pos)
   unmark
   end_paragraph()
   left
   mark_char
   begin_paragraph()
   mark_char
   call prestore_pos(save_pos)

; A routine to extend the current character mark through the end of the
; following paragraph.
defproc mark_through_next_paragraph
   if leftstr(marktype(), 1)<>'C' then
      sayerror CHAR_MARK_REQUIRED__MSG
      return
   endif
   getmark firstline,lastline,firstcol,lastcol,markfileid
   getfileid fileid
   if fileid<>markfileid then
      sayerror OTHER_FILE_MARKED__MSG
      return
   endif
   call psave_pos(save_pos)
   call pend_mark()
   right
   end_paragraph(1)
   mark_char
   call prestore_pos(save_pos)

; If the sentence terminator is followed by a close bracket, close paren,
; or quote char, check if the sentence starts with the corresponding char.
; If so, mark the end char as part of the sentence.  So, if we have:
;    (Sentence?)
; marking the sentence will include both parens, while if we have:
;    "This is a quote.  Someone else said it."
; then marking the second sentence won't mark the closing quote, but marking
; the first and then extending the mark through the second will.  Which seems
; to me like the Right Thing To Do.
defproc match_postsentence_char
   if leftstr(marktype(), 1)<>'C' then
      sayerror CHAR_MARK_REQUIRED__MSG
      return
   endif
   getmark firstline,lastline,firstcol,lastcol,markfileid
   getline line, lastline, markfileid
   p = pos(substr(line, lastcol+1, 1), '])''"')
   if p then
      getline line, firstline, markfileid
      if substr(line, firstcol, 1) = substr('[(''"', p, 1) then
         setmark firstline,lastline,firstcol,lastcol+1,1,markfileid
      endif
   endif

/* For testing... */
compile if 0
   defc ms = mark_sentence()
   defc mns = mark_through_next_sentence()
   defc bs = begin_sentence()
   defc es = end_sentence()

   defc mp = mark_paragraph()
   defc mnp = mark_through_next_paragraph()
   defc bp = begin_paragraph()
   defc epar = end_paragraph()
compile endif

