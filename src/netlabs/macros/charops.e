/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
쿛COMMON_ADJUST_OVERLAY:  provide the adjust mark and overlay mark function    �
쿯or the character and line marks.                                             �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
compile if WANT_CHAR_OPS
defproc pcommon_adjust_overlay(letter)
   call checkmark()
   mt=marktype()
compile if EVERSION >= '5.50'
   if leftstr(mt,1)<>'B' then             -- Change to block mark
compile else
   if mt<>'BLOCK' then             -- Change to block mark
compile endif
      getmark firstline,lastline,firstcol,lastcol,mkfileid
compile if EVERSION >= '5.50'
      if leftstr(mt,1)='C' & firstline<>lastline then
compile else
      if mt='CHAR' & firstline<>lastline then
compile endif
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
compile if EVERSION >= '5.50'  -- We now retain trailing blanks...
      if leftstr(mt, 1)='L' then 'strip' firstline lastline; endif
compile endif
   endif
compile endif

/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
쿛COPY_MARK: this procedure provide the copy mark function for the character   �
쿺arks.                                                                        �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
defproc pcopy_mark
compile if WANT_CHAR_OPS & EVERSION < '5.50'
   if marktype()='CHAR' then
      if not .line then insert; top; .col=1; endif /* Corrected HURLEYJ */

      getmark firstline,lastline,firstcol,lastcol,mkfileid
      getfileid thisfileid
      samefile=(thisfileid=mkfileid)

      /* compute the overlay condition */
      if samefile then         -- Don't bother if different files.
         if (.line=lastline & .line=firstline & firstcol<=.col & .col<=lastcol) |
            (.line=firstline & .line<>lastline & firstcol<=.col ) |
            (.line=lastline & .line<>firstline & .col<=lastcol) |
            (firstline<.line & .line<lastline)
         then
            sayerror -281  -- Source Destination conflict
            stop
         endif
      endif

      /* First case:  lastline=firstline */
      if lastline = firstline then
         pset_mark(firstline, lastline, firstcol, lastcol, 'BLOCK', mkfileid)
         copymark
         len = lastcol+1-firstcol

         /* compute new position of source marked area and destination (for pmove) */
         if samefile and .line=firstline then
            if .col < firstcol then
               firstcol = firstcol+len
               lastcol  = lastcol+len
            endif
         endif
      else
         /* the other cases */
 compile if EVERSION >= '4.2'     -- The new way, handles attribute bytes.
         -- split destination
         destcol =  .col
         destline = .line
         split
         if (firstline>=.line) and samefile then
            if firstline=.line then
               firstcol  = firstcol - .col + 1
               /* last col unchanged */
            endif
            firstline = firstline+1
            lastline  = lastline+1
         endif

         -- split out marked text.
         activatefile mkfileid
;        if not samefile then
           FinalSrcCol = .col
           FinalSrcLine = .line
;        endif
         firstline
         .col  = firstcol
         split
         firstline = firstline+1
         lastline  = lastline+1
         if samefile and (destline>=firstline) then
           destline = destline+1
         endif
         .col  = lastcol+1
         src_at_eof = lastline>.last
         if src_at_eof then
            insertline "", .last+1
         else
            lastline
            split
         endif
         if samefile and (destline>=lastline) then
           -- the following lines are commented out because they
           -- cause trouble if dest is just behind end of source.
           --if destline=lastline then
           --  destcol = destcol - .col + 1
           --endif
           destline = destline+1
         endif

         -- copy marked region
         numlines = lastline - firstline + 1
         pset_mark(firstline, lastline,  1, 1, 'LINE', mkfileid)
         activatefile thisfileid
         destline
         copymark

         -- adjust source region.
         if samefile and (destline<firstline) then
           firstline = firstline + numlines - 2
           lastline  = lastline  + numlines - 2
         endif

         -- close up destination
           -- ??? need this ???? .col  = destcol
         join
          -- may need to remove a space character here.
         .line + numlines - 1
          -- ??? need this ???   .col  = .lastcol+1
         join
          -- may need to remove a space character here.

         -- close up source
         activatefile mkfileid
         firstline - 1
         endline; firstcol = .col
         --endline; we may not need this line. Try it.
         join
          -- may need to remove a space character here.
         .line + numlines - 1
         -- may not need this line .col = lastcol+1

         if src_at_eof then
            deleteline .last
         else
            join
         endif

         -- adjust source
         firstline = firstline-1
         lastline  = lastline -1
         if not samefile then
            FinalSrcLine
            .col  = FinalSrcCol
         endif

         -- adjust destination
         if samefile and destline>firstline then
           destline = destline - 2
         endif

         -- return to origin
         activatefile thisfileid
         destline
         .col  = destcol

 compile else                        -- The old way is 170 bytes shorter
         split
         if (firstline>=.line) and samefile then
            if firstline=.line then
               firstcol  = firstcol - .col + 1
               /* last col unchanged */
            endif
            firstline = firstline+1
            lastline  = lastline+1
         endif

         getline firstmarkedline,firstline,mkfileid

         pset_mark(firstline, firstline,  firstcol, length(firstmarkedline), 'BLOCK', mkfileid)
         copymark

         pset_mark(lastline, lastline, 1, lastcol, 'BLOCK', mkfileid)
         '+1'; oldcolumn = .col; beginline  -- go to beginning of next (split) line
         copymark
         '-1'; .col = oldcolumn

         if lastline - firstline > 1 then
            pset_mark(firstline+1, lastline-1, 1,1, 'LINE', mkfileid)
            copymark
         endif

         if samefile and (firstline>.line)  then
           if firstline=.line+1 then
             /* if the marked text was on the line in which it was to be
              *  inserted, then shift the final position of the mark.
              */
             firstcol = lastcol + firstcol
           endif
           numlines = lastline - firstline-1
           firstline = firstline+numlines
           lastline  = lastline +numlines
         endif
 compile endif
      endif
      pset_mark(firstline, lastline, firstcol, lastcol, 'CHAR', mkfileid)
      rc=0
   else
compile elseif EVERSION < '5.50'
   call no_char_mark()
compile endif
      rc=0    /* Watch for memory-full, return its rc. */
      copy_mark
compile if WANT_CHAR_OPS & EVERSION < '5.50'
   endif
compile endif
   return rc

/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
쿛DELETE_MARK: provide delete mark function for character mark                 �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
defproc pdelete_mark
compile if EVERSION < '5.50'
/* this procedure must also keep track of the cursor position. */
compile if EVERSION >= '5.50'
   if .levelofattributesupport then
      themarktype=marktype()
      if themarktype then  -- If not, later DELETEMARK will give an error message
         getmark firstline, lastline, firstcol, lastcol, mkfileid
         DestinationCol=lastcol+1
         findoffset=0
         findline=lastline
         findcolumn=lastcol

         do forever
            FINDCLASS=0
            Attribute_action FIND_PREV_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass then leave; endif
            if themarktype=="LINE" then
               if (findline<firstline) then
                  leave
               endif
               DestinationLine=lastLine+1   /* error if lastline=.last */
               DestinationCol=1
            elseif (themarktype=="CHAR") then
               if findline<firstline or findcolumn<firstcol then
                  leave
               endif
               DestinationLine=lastLine
            elseif (themarktype=="BLOCK") then
               if findline>firstline and findcolumn<firstcol then
                  iterate                   /* case 1:  to the left of the block */
               elseif findline>=firstline and findcolumn>lastcol then
                  iterate                   /* case 2:  to the right of the block */
               elseif findline>=firstline and findcolumn>=firstcol and findcolumn<=lastcol then
                  DestinationLine=findline  /* case 3:  in the block */
               else
                  leave                     /* case 4:  before the block (or to the left on firstline) */
               endif    /* end case like if stmt */
            endif     /* marktype if stmt */

             /* Move Attribute */
            query_attribute theclass, thevalue, thepush, findoffset, findcolumn, findline
            -- only move push/pop type attributes (tags are just deleted)
            if thepush==0 or thepush==1 then
               -- move attribute to destination, if cancellation delete both attributes
               FastMoveAttrToBeg(theclass, thevalue,thepush, DestinationCol, DestinationLine,findcolumn,findline,findoffset)
               findoffset=findoffset+1  -- since the attr rec was deleted and all attr rec were shifted to fill the vacancy
            endif
         enddo
      endif      -- marks required if stmt
   endif  -- .levelofattributesupport set
compile endif  -- EVERSION >= '5.50'
compile if WANT_CHAR_OPS
   if marktype()='CHAR' then
      getmark firstline,lastline,firstcol,lastcol,mkfileid
 compile if EPM
      if not lastcol then
         lastline=lastline-1
         getline lastlineText, lastline, mkfileid
         lastcol=length(lastlineText)
      endif
 compile endif
      getline lastlineText, lastline, mkfileid
      unmark
      getfileid Oldfileid
      activatefile mkfileid
      OldLine = .line; OldCol = .col

      if firstline == lastline then
         pset_mark(firstline, firstline, firstcol, lastcol, "BLOCK", mkfileid)
         deletemark
         if (OldLine=firstline) and (OldCol>firstcol) then
            if OldCol>lastcol  then
               .col = OldCol - (lastcol-firstcol+1)
            else  -- the mark enclosed the cursor
               .col = firstcol
            endif
         endif
      else
         firstline; .col = firstcol
         eraseendline
         if length(lastlineText)>lastcol then
            pset_mark(lastline, lastline, lastcol+1, length(lastlineText), "BLOCK", mkfileid)
            copy_mark
            unmark
         endif
         pset_mark(firstline+1, lastline, 1, 1, "LINE", mkfileid)
         deletemark
         if (OldLine>firstline) then
            if (OldLine>lastline) then
               OldLine - (lastline-firstline)
               .col  = OldCol
            else
               if (OldLine<lastline) then
                  .col = firstcol
                  firstline
               else  -- Oldline == lastline
                  if OldCol>lastcol then
                     .col = firstcol + (OldCol-lastcol-1)
                  else
                     .col = firstcol
                  endif
                  firstline
               endif
            endif
         else
            if (OldLine=firstline) and (OldCol>.col) then
               .col = firstcol
            else
               .col = OldCol; OldLine
            endif
         endif
      endif
      activatefile Oldfileid
   else
compile else  -- WANT_CHAR_OPS
   call no_char_mark()
compile endif  -- WANT_CHAR_OPS
compile endif  -- EVERSION < '5.50'
      delete_mark
compile if WANT_CHAR_OPS & EVERSION < '5.50'
   endif
compile endif

/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
쿛FILL_MARK: provide fill mark function for character mark                     �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
defproc pfill_mark
compile if EVERSION >= 5  -- EPM doesn't have GETKEY()
   if arg(1)=='' then
 compile if EVERSION >= 5.21
      parse value entrybox(FILL__MSG, '', '', 0, 1,
             atoi(1) || atoi(0) || gethwndc(APP_HANDLE) ||
             ENTER_FILL_CHAR__MSG) with button 2 k \0
      if button<>\1 | k=='' then return; endif
 compile else
      k=entrybox(ENTER_FILL_CHAR__MSG, '', '', 0, 1)
      if k=='' then return; endif
 compile endif
   else
       k=substr(arg(1),1,1)
   endif
compile endif
compile if WANT_CHAR_OPS
   if marktype() = 'CHAR' then
 compile if EVERSION < 5
      if not arg() then
         sayerror TYPE_A_CHAR__MSG; k = getkey()
         /* Display error message - HURLEYJ */
         if length(k) > 1 then sayerror PFILL_ERROR__MSG; stop endif
      else
         k=substr(arg(1),1,1)
      endif
 compile endif
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
compile if EVERSION < 5
      if arg() then
         fill_mark arg(1)
      else
         fill_mark
      endif
compile else
      fill_mark k
compile endif
compile if WANT_CHAR_OPS
   endif
compile endif

/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
쿛MOVE_MARK: provide move mark function for the character marks.               �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
defproc pmove_mark
compile if WANT_CHAR_OPS & EVERSION < '5.50'
   if marktype()='CHAR' then
       getfileid thisfileid
       getmark firstline,lastline,firstcol,lastcol,mkfileid
       call pcopy_mark()
       call pdelete_mark()
       /* now calculate where the (dest) mark is. */
       if firstline=lastline then
          call pset_mark(.line, .line, .col, .col + lastcol - firstcol,'CHAR',thisfileid)
       else
          call pset_mark(.line, .line+lastline-firstline,.col,lastcol ,'CHAR',thisfileid)
       endif
   else
compile elseif EVERSION < '5.50'
   call no_char_mark()
compile endif
      move_mark
compile if WANT_CHAR_OPS & EVERSION < '5.50'
   endif
compile endif

compile if WANT_CHAR_OPS = 0
defproc no_char_mark
   if marktype()='CHAR' then
      sayerror NO_CHAR_SUPPORT__MSG
      stop
   endif
compile endif

compile if EVERSION >= '5.50'
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
compile endif
