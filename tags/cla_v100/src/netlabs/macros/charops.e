/****************************** Module Header *******************************
*
* Module Name: charops.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: charops.e,v 1.3 2002-08-09 19:44:05 aschn Exp $
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
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PCOMMON_ADJUST_OVERLAY:  provide the adjust mark and overlay mark function    ³
³for the character and line marks.                                             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
compile if WANT_CHAR_OPS
defproc pcommon_adjust_overlay(letter)
   call checkmark()
   mt=marktype()
   if leftstr(mt,1)<>'B' then             -- Change to block mark
      getmark firstline,lastline,firstcol,lastcol,mkfileid
      if leftstr(mt,1)='C' & firstline<>lastline then
         sayerror CHAR_ONE_LINE__MSG
         stop
      endif
      call pset_mark(firstline,lastline,firstcol,lastcol,'BLOCK',mkfileid)
   endif
   if letter='A' then adjustblock
   elseif letter='O' then overlay_block
   endif
   if mt<>'BLOCK' then             -- Restore mark type
      getmark firstline,lastline,firstcol,lastcol,mkfileid
      call pset_mark(firstline,lastline,firstcol,lastcol,mt,mkfileid)
      if leftstr(mt, 1)='L' then 'strip' firstline lastline; endif
   endif
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PCOPY_MARK: this procedure provide the copy mark function for the character   ³
³marks.                                                                        ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc pcopy_mark
   rc=0    /* Watch for memory-full, return its rc. */
   copy_mark
   return rc

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PDELETE_MARK: provide delete mark function for character mark                 ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc pdelete_mark
   delete_mark

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PFILL_MARK: provide fill mark function for character mark                     ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc pfill_mark
   if arg(1)=='' then
      parse value entrybox(FILL__MSG, '', '', 0, 1,
             atoi(1) || atoi(0) || gethwndc(APP_HANDLE) ||
             ENTER_FILL_CHAR__MSG) with button 2 k \0
      if button<>\1 | k=='' then return; endif
   else
       k=substr(arg(1),1,1)
   endif
compile if WANT_CHAR_OPS
   if marktype() = 'CHAR' then
      call psave_pos(save_pos)
      call pinit_extract()
      do forever
         code = pextract_string(string)
         if code = 1 then leave endif
         if code = 0 then
            string = substr('',1,length(string),k)
            call pput_string_back(string)
         endif
      end
      call prestore_pos(save_pos)
      sayerror 0
   else
compile else
   call no_char_mark()
compile endif
      fill_mark k
compile if WANT_CHAR_OPS
   endif
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PMOVE_MARK: provide move mark function for the character marks.               ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc pmove_mark
   move_mark

compile if WANT_CHAR_OPS = 0
defproc no_char_mark
   if marktype()='CHAR' then
      sayerror NO_CHAR_SUPPORT__MSG
      stop
   endif
compile endif

defproc FastMoveATTRtoBeg(theclass, thevalue, thepush, DestinationCol, DestinationLine, scol, slin, soff)
   if thepush<>1 then      -- an end attribute cannot cancel any attribute
                           -- when placed at the beginning (most negative) so it must be
                           -- inserted...
      insert_attribute theclass, thevalue, thepush, -300, DestinationCol, DestinationLine
      Attribute_action DELETE_ATTR_SUBOP, theclass, soff, scol, slin
   else                    -- this begin attribute must be checked for cancellation
      findclass=theclass
      findoffset=soff
      findcolumn=scol
      findline=slin
      Attribute_Action FIND_MATCH_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
      if ((findcolumn==DestinationCol) and (findline==DestinationLine)) then
         /* then the attribute is canceled out */
         Attribute_action DELETE_ATTR_SUBOP, theclass, soff, scol, slin
         Attribute_action DELETE_ATTR_SUBOP, theclass, findoffset, findcolumn, findline
      else
         insert_attribute theclass, thevalue, thepush, -300, DestinationCol, DestinationLine
         Attribute_action DELETE_ATTR_SUBOP, theclass, soff, scol, slin
      endif
   endif
