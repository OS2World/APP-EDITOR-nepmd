/****************************** Module Header *******************************
*
* Module Name: charops.e
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
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PCOMMON_ADJUST_OVERLAY:  provide the adjust mark and overlay mark function    ³
³for the character and line marks.                                             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
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
   if cursor_in_mark() then
      getmark first_line, last_line, first_col, last_col, mark_fid
      mark_type = marktype()
      if mark_type = 'LINE' then
         --.line = first_line  -- go to begin of mark and keep .col (done automatically)
      elseif mark_type = 'CHAR' then
         .line = first_line    -- go to begin of mark
         .col  = first_col
      elseif mark_type = 'BLOCK' then
         .col = first_col      -- go to begin of mark and keep .line
      endif
   endif
   delete_mark
   return

defproc cursor_in_mark
   rc = 0
   getmark first_line, last_line, first_col, last_col, mark_fid
   getfileid cur_fid
   mark_type = marktype()
   cur_line = .line
   cur_col  = .col
   if mark_fid = cur_fid then
      if mark_type = 'LINE' then
         if cur_line >= first_line and cur_line <= last_line then
            rc = 1
         endif
      elseif mark_type = 'CHAR' then
         if cur_line > first_line and cur_line < last_line then
            rc = 1
         elseif cur_line = first_line and cur_col >= first_col then
            rc = 1
         elseif cur_line = last_line and cur_col <= first_col then
            rc = 1
         endif
      elseif mark_type = 'BLOCK' then
         if cur_line >= first_line and cur_line <= last_line then
            if cur_col >= first_col and cur_col <= last_col then
               rc = 1
            endif
         endif
      endif
   endif
   --sayerror 'Cursor in mark: 'rc
   return rc

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
      fill_mark k
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³PMOVE_MARK: provide move mark function for the character marks.               ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc pmove_mark
   move_mark

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

