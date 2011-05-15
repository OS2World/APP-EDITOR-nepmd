/****************************** Module Header *******************************
*
* Module Name: caseword.e
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

;I just wrote the following proc to rotate the  case of a word.  I find it
;handier to  use than  the default  C-F1 and  C-F2 keys.   I  have defined
;C-F10, but  any key will do.   I recommend  a Ctrl key since  the tabword
;functions are usually on Ctrl keys.
;
;Blair Thompson             Information Systems            IBM Canada Ltd.

/**********************************************************************/
/* CASEWRD.E - Rotate Case of word pointed at by cursor between       */
/*             UPPER, Mixed, and lower.                               */
/*                                                                    */
/* Words that are all uppercase  -> Cap1                              */
/* Words that are all lowercase  -> Upper                             */
/* Words that are all mixed case -> Lower                             */
/*                                                                    */
/* Thus, repeated invocations will give a rotation from               */
/*   upper -> cap1 -> lower -> upper -> etc.                          */
/*                                                                    */
/* Note that only the first alphabetic string in the word is tested   */
/* for case, although the case of the entire word is changed.         */
/*                                                                    */
/* Written by B. Thompson 6 Aug 1987                                  */
/*                                                                    */
/**********************************************************************/

; Changed:
;    o  use Ctrl+F1 instead of Ctrl+F10
;    o  use find_token instead of pmark_word
;    o  support for german umlauts
;    o  changed toggle order
;    o  restore position afterwards


--def c_f10=
def c_f1 = 'caseword'

defc caseword
   call psave_mark(save_mark)
   call psave_pos(save_pos)

   call find_token(startcol, endcol)
   --sayerror '1: startcol = 'startcol', endcol = 'endcol
   -- If nothing found by find_token, then startcol = 0 and endcol = 4 is returned.
   if startcol = 0 and .col > 1 then
      -- Inspect tokens left from cursor
      .col = .col - 1
      call find_token(startcol, endcol)
      --sayerror '2: startcol = 'startcol', endcol = 'endcol
   endif
   if startcol = 0 then
      return
   endif

   getfileid fid
   call pset_mark( .line, .line, startcol, endcol, 'BLOCK', fid )

   /* Get word pointed to by cursor*/
   getline line, .line
   getmark first_line, last_line, first_col, last_col
   word_len = last_col - first_col + 1
   wrd = substr(line,first_col,word_len)
   upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZéôö'
   lower = 'abcdefghijklmnopqrstuvwxyzÑîÅ'
   first = verify(wrd,upper||lower,'M')  /* First alphabetic            */
   if first < 1 then
      first = 1
   endif
   wrd = substr(wrd,first)
   last  = verify(wrd,upper||lower) - 1  /* Last alphabetic             */
   if last < 1 then
      last = word_len - first + 1
--    last = 1
   endif
   wrd = substr(wrd,1,last)              /* Alphabetic word             */

-- xxXx -> xxxx
-- xxxx -> XXXX
-- XXXX -> Xxxx
   if verify(wrd,lower, 'M') = 0 then    /* Any uppercase               */
      call plowercase()                  /* -> lowercase                */
      --sayerror '-> Lower'
   elseif verify(wrd,lower) = 0 then     /* All uppercase               */
      call plowercase()                  /* -> Capitalise               */
      .cursorx = first_col + first - 1
      mark_block
      call puppercase()
      --sayerror '-> Mixed'
   else                                  /* All lowercase               */
      call puppercase()                  /* -> uppercase                */
      --sayerror '-> Upper'
   endif

   call prestore_pos(save_pos)
   call prestore_mark(save_mark)
   return

