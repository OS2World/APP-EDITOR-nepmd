/****************************** Module Header *******************************
*
* Module Name: caseword.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: caseword.e,v 1.5 2004-06-29 20:47:23 aschn Exp $
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
/*             lower, Mixed and UPPER.                                */
/*                                                                    */
/* Words that are all lowercase  -> Cap1                              */
/* Words that are all uppercase  -> Lower                             */
/* Words that are all mixed case -> Upper                             */
/*                                                                    */
/* Thus, repeated invocations will give a rotation from               */
/*   upper -> lower -> cap1 -> upper -> etc.                          */
/*                                                                    */
/* Original written by B. Thompson 6 Aug 1987                         */
/*                                                                    */
/**********************************************************************/

; Changed:
;    o  use Ctrl+F1 instead of Ctrl+F10
;    o  use find_token instead of pmark_word
;    o  support for german umlauts
;    o  changed toggle order
;    o  restore position afterwards
;    o  made UPPERCHARS and LOWERCHARS definable in MYCNF.E

define
compile if not defined(UPPERCHARS)
   UPPERCHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZŽ™š'
compile endif
compile if not defined(LOWERCHARS)
   LOWERCHARS = 'abcdefghijklmnopqrstuvwxyz„”'
compile endif

defc CaseWord
   call psave_pos(save_pos)
   -- find_token may return nothing, so we have to init the vars first
   startcol = 0
   endcol   = 0
   -- find_token won't take '.' and '_' as word boundaries
   call find_token( startcol, endcol)
   -- If nothing found by find_token, then nothing is returned
   if startcol = 0 & .col > 1 then
      -- Inspect tokens left from cursor
      .col = .col - 1
      call find_token( startcol, endcol)
   endif
   if startcol = 0 then
      call prestore_pos(save_pos)
      return
   endif

   getline line, .line
   lline = substr( line, 1, startcol - 1)
   wrd   = substr( line, startcol, endcol - startcol + 1)
   rline = substr( line, endcol + 1)

   if verify( wrd, LOWERCHARS, 'M') = 0 then      -- no lowercase  -> lowercase
-- XXXX -> xxxx
      newwrd = translate( wrd, LOWERCHARS, UPPERCHARS)

   elseif verify( wrd, UPPERCHARS, 'M') = 0  &           -- no uppercase and
      verify( substr( wrd, 1, 1), LOWERCHARS, 'M') then  -- first char lowercase -> Capitalize
-- xxxx -> Xxxx
      newwrd = translate( substr( wrd, 1, 1), UPPERCHARS, LOWERCHARS)          -- first letter
      if length(wrd) > 1 then
         newwrd = newwrd''translate( substr( wrd, 2), LOWERCHARS, UPPERCHARS)  -- append rest
      endif

   else                                           -- mixed case    -> UPPERCASE
-- xxXx -> XXXX
      newwrd = translate( wrd, UPPERCHARS, LOWERCHARS)
   endif

   -- Replace line only if anything has changed to not increase .modify otherwise
   if newwrd <> wrd then
      replaceline lline''newwrd''rline
   endif

   call prestore_pos(save_pos)
   return

