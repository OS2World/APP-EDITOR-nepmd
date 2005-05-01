/****************************** Module Header *******************************
*
* Module Name: reflowmail.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: reflowmail.e,v 1.3 2005-05-01 22:53:23 aschn Exp $
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
Todo:

-  How to determine verbatim text?  Then: Ask the user if current par is
   a verbatim par?
   --> Better process only 1 par at time, starting at cursor!

-  Correct wrong-wrapped lines instead of count them as a change of quote level.

   > This is a long line, that was wrapped by a bad
   mail client.

   >> This is a long line, that was wrapped by a bad
   >mail client and already quoted a 2nd time.

   >> This is a long line, that was wrapped by a bad
   > mail client and already quoted a 2nd time.

   --> Line-mark the 2 lines and do a Alt+P for 'mailreflow'

?  Mode 'MAIL' missing.

?  Redefine Alt+P for mode MAIL

-  Reformat tables:
   2 or more spaces (or a tab) specify a new col.
   Every cell is aligned to the left.
   Optionally: indented by 2 to disable reflow automatically.

-  Replace tabs with spaces in normal text. Remove parindent (by reflow).

-  Handle special text sections:
-> *  par (parindent should be replaced by parskip)
   *  verbatim
-> *  lists (workaround now: every indented line is verbatim.)
-> *  tables
ok *  blank lines
   *  multiple spaces
ok *  trailing spaces
-> *  tabs
   mail-specific:
ok *  quote
ok *  cite
ok *  signature
   *  macro: correct wrong-quoted line (remove linebreak and re-wrap current par)

-  Add for a "ab>" region: "ab wrote:" as a new line before
   with the name from the signature (first 3 words of first non-blank line after '-- ' line)

-  Remove salutation: (Hi|Hallo|Moin|...)[ *](,|!)

-  Add own signature

-  Replace "Re: Re:" with one "Re:"

-  In/decrease QuoteLevel

-  Add 'On ... * wrote:'

-  Remove indent (e.g. parindent, it will be replaced by a blank line).
   How to recognize parindents and distinguish it from verbatim regions,
   where the indent is essential?

-  Replace multiple spaces in verbatim regions with '~' to keep all
   spaces in HTML forms.
*/

const
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_MAILREFLOW)
   NEPMD_DEBUG_MAILREFLOW = 0
compile endif

defmain
   'reflowmail'

; ---------------------------------------------------------------------------
defproc Mail_GetQuoteLevel( line, var sLine, var QuoteLevel, var IndentLevel)
   QuoteLevel  = 0
   IndentLevel = 0
   QuoteCharList = '> : %'
   DefaultQuoteChar = '>'  -- for XyZ> quotes
   LastIsQuoteChar = 0
   startp = 1
   col = 1
   do forever
      if col > length(line) then
         leave
      endif
      next = substr( line, col, 1)
      if next == '' then
         leave           -- Todo: don't change QuoteLevel if in signature
      elseif next == ' ' then  -- empty line or end of line
         IndentLevel = IndentLevel + 1
         col = col + 1
         -- Remove 1 possible space after QuoteChar
         if LastIsQuoteChar then  -- if last char was a QuoteChar
            startp = col
            LastIsQuoteChar = 0
         endif
      elseif pos( next, QuoteCharList) then
         QuoteLevel  = QuoteLevel + 1
         IndentLevel = 0
         col = col + 1
         startp = col
         LastIsQuoteChar = 1
      else  -- for WXyZ> quote marks
         next = substr( line, col, 5)  -- 5: max 4 chars for name
         p1 = pos( DefaultQuoteChar, next)
         p2 = verify( '-=', next, 'M')    -- don't count arrows as quote chars
         if p1 & (p2 = 0) then
            QuoteLevel = QuoteLevel + 1
            col = col + p1 + 1
            startp = col
         else  -- standard text
            leave
         endif
      endif
   enddo
   sline = substr( line, startp)  -- line, stripped-off leading QuoteChars
   return

; ---------------------------------------------------------------------------
defproc Mail_ReflowMarkedLines
   rightMargin = 70
   defaultQuoteChar = '>'
   spaceAmount = 1
   prevParQuoteLevel     = arg(1)
   prevPrevParQuoteLevel = arg(2)  -- required for blank lines
   enableReflow          = arg(3)
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
   call NepmdPmPrintf( 'Starting at line # '.line )
compile endif
   -- set margins for reflow, substract indent
   if prevParQuoteLevel > 0 then
      thisIndent = prevParQuoteLevel + spaceAmount
   else
      thisIndent = 0
   endif
   rma = rightMargin - thisIndent
   .margins = 1 rma 1
   -- go to begin mark
   getmark firstLine, lastLine, firstCol, lastCol, fId
   .line = firstLine
   if enableReflow = 1 then
      -- reflow marked lines, starting at cursor
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
      call NepmdPmPrintf( '  Reflowing lines no 'firstLine' to 'lastLine)
compile endif
      reflow
   else
      -- don't reflow marked lines, starting at cursor
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
      call NepmdPmPrintf( '  Not reflowing lines no 'firstLine' to 'lastLine)
compile endif
   endif
   -- insert quote chars in every marked line
   -- set margins to max to avoid any automatic line break
   .margins = 1 1599 1
   getmark firstLine, lastLine, firstCol, lastCol, fId

   -- go back to start - 1 if prev line is a blank line to calc quote level and add quote chars
   if firstLine > 1 then
      .line = firstLine - 1
      getline line
      if strip(line) <> '' then
         .line = firstline
      endif
   endif

   do forever --l = 1 to lastLine - firstLine
      getline line

      if strip(line) = '' then
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
         call NepmdPmPrintf( '* QuoteLevel prevPar/prevPrevPar = 'prevParQuoteLevel'/'prevPrevParQuoteLevel)
compile endif
         blankLineQuoteLevel = min( prevParQuoteLevel, prevPrevParQuoteLevel )
         if blankLineQuoteLevel > 0 then
            replaceline copies( defaultQuoteChar, blankLineQuoteLevel)''copies( ' ', spaceAmount)''line
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
            call NepmdPmPrintf( '* line = |'line'|')
compile endif
         endif
;;        refresh; getline newline; messageNwait( .line': prevQuoteLevel = 'prevQuoteLevel', thisQuoteLevel = 'thisQuoteLevel', newline = |'newline'|' )

      elseif prevParQuoteLevel > 0 then
         -- prepend quote chars and space
         replaceline copies( defaultQuoteChar, prevParQuoteLevel)''copies( ' ', spaceAmount)''line
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
         call NepmdPmPrintf( '* line = |'line'|')
compile endif
      endif

      -- position cursor on line following mark or leave
      if .line = .last then
         leave  -- return
      elseif .line >= lastLine then
         down   -- go back to line after mark
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
         call NepmdPmPrintf( 'Back on line # '.line )
compile endif
         leave  -- return
      else
         down   -- go to next marked line
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
         call NepmdPmPrintf( 'Back on line # '.line )
compile endif
      endif

   enddo
   return

; ---------------------------------------------------------------------------
defproc Mail_IsVerbatim(sline)
   ssline = strip( sline, 'l')
   FirstChar  = substr( ssline, 1, 1)
   SecondChar = substr( ssline, 2, 1)
   ThirdChar  = substr( ssline, 3, 1)
   FourthChar = substr( ssline, 4, 1)
   Option = arg(2)  -- Flag; if 1: recognize every indented line as verbatim
   IsVerbatim = 0

   -- empty line
   if ssline = '' then
      -- not verbatim

   -- signature line
   elseif sline = '-- ' then
      IsVerbatim = 1
      -- todo: don't reformat the rest

   -- external quotes
   elseif FirstChar = '|' then
      IsVerbatim = 1

   -- indented line with indent > 1                                           <--------- Todo
   --elseif substr( sline, 1, 2) = '  ' | substr( sline, 1, 1) = \9  | substr( sline, 1, 2) = ' '\9 then
   elseif (substr( sline, 1, 1) = ' ' | substr( sline, 1, 1) = \9) & Option = 1 then
      IsVerbatim = 1
/*
   -- numbered lists
   elseif isnum( FirstChar) then
      if pos( SecondChar, '.)' ) > 0 & pos( ThirdChar, ' '\13) > 0 then
         IsVerbatim = 1
      elseif isnum( SecondChar) & pos( ThirdChar, '.)') > 0 & pos( FourthChar, ' '\9) > 0 then
         IsVerbatim = 1
      endif
      -- todo: keep indent for the rest of this item, reformat indent of items

   -- bullet lists
   elseif pos( FirstChar, '-o*') > 0 & pos( SecondChar, ' '\9) > 0 then
      IsVerbatim = 1
*/                                                    -- todo: keep indent for the rest of this item, reformat indent of items
   endif
   return IsVerbatim

; ---------------------------------------------------------------------------
defproc Mail_IsListItem( sline, var ListIndentLevel)
   ssline = strip( sline, 'l')
   FirstChar  = substr( ssline, 1, 1)
   SecondChar = substr( ssline, 2, 1)
   ThirdChar  = substr( ssline, 3, 1)
   FourthChar = substr( ssline, 4, 1)
   IsListItem = 0

   -- numbered lists
   if isnum( FirstChar) then
      if pos( SecondChar, '.)') > 0 & pos( ThirdChar, ' '\13) > 0 then
         IsListItem = 1
         ListIndentLevel = max( verify( substr( ssline, 3), ' '\9) - 1, 0) + 2
      elseif isnum( SecondChar) & pos( ThirdChar, '.)') > 0 & pos( FourthChar, ' '\9) > 0 then
         IsListItem = 1
         ListIndentLevel = max( verify( substr( ssline, 3), ' '\9) - 1, 0) + 3
      endif
      -- todo: keep indent for the rest of this item, reformat indent of items

   -- bullet lists
   elseif pos( FirstChar, '-o*' ) > 0 & pos( SecondChar, ' '\9) > 0 then
      IsListItem = 1
      ListIndentLevel = max( verify( substr( ssline, 2), ' '\9) - 1, 0) + 2
   elseif pos( FirstChar, '-') > 0 & pos( SecondChar, '-') > 0 & pos( ThirdChar, ' '\9) > 0 then
      IsListItem = 1
      ListIndentLevel = max( verify( substr( ssline, 2), ' '\9) - 1, 0) + 3
                       -- todo: keep indent for the rest of this item, reformat indent of items
   endif
   return IsListItem

; ---------------------------------------------------------------------------
; Get quote level for current line, ignore all spaces in between.
; Get quote level for next line...
; Stop at a line with a different quote level. Don't count blank lines. Get new level.
; Set margins to 1 1599 1.
; Go back to prev section and remove all quote chars for that section.
; Reformat that section.
; Add quote chars in every line of this section.
; Insert a new line.
; Strip blank lines.
; Handle parindents: add a blank line if one line has a different indent
;                    or just keep the indent (and remove only 1 optional space after the prev '>')
defc reflowmail
   universal nepmd_hini
   prevLineIsBlank    = 0
   prevLineIsVerbatim = 0
   prevQuoteLevel     = 0
   prevPrevQuoteLevel = 0
   prevParQuoteLevel     = 0
   prevPrevParQuoteLevel = 0
   noReflow = 0
   sigQuoteLevel = 0
   thisListIndentLevel = 0
   thisIndentLevel = 0
   prevIndentLevel = 0
   ListStart = 0

   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedIsVerbatim'
   IndentedIsVerbatim = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   -- no additional undo state supression required
   if marktype() then
      unmark
   endif

   .line = 1
   .col = 1

   -- add a blank line after last to make reflow of the last par easy
   insertline '', .last + 1
   do forever
      thisLineIsBlank    = 0
      thisLineIsVerbatim = 0
      getline line
      -------------------------------------------------------------------------
      -- GetQuoteLevel() and strip quote chars from line
      call Mail_GetQuoteLevel( line, sLine, thisQuoteLevel, thisIndentLevel)
      -------------------------------------------------------------------------
      -- strip off trailing spaces, except from signature mark
      -- remove quoted signatures
      if (thisQuoteLevel = sigQuoteLevel) & (sigQuoteLevel > 0) then
         deleteline
         iterate
      endif
      if substr( sline, 1, 2) = '--' & length( sline) = 2 /*pos( substr( sline, 3, 1), '>-') = 0*/ then
         sline = '-- '  -- correct stripped space if none
      endif
      if substr( sline, 1, 3) = '-- ' then
         noReflow = 1
         sigQuoteLevel = thisQuoteLevel
         if sigQuoteLevel > 0 then
            deleteline
            iterate
         endif
      else
         noReflow = 0
         sline = strip( sline, 'T', ' ')
         sigQuoteLevel = 0
      endif
      -------------------------------------------------------------------------
      replaceline sLine
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
      call NepmdPmPrintf( 'Line no '.line':  #  prevLineIsBlank = 'prevLineIsBlank', QuoteLevel = 'thisQuoteLevel', line = |'line'|, sline = |'sline'|')
compile endif
      -------------------------------------------------------------------------
      -- if a blank line
      if sLine = '' then
         if 0 /*.line = .last*/ then
            deleteline
            leave
         ----------------------------------------------------------------------
         -- if previous line is blank
         elseif prevLineIsBlank then

            deleteline
            if .line = .last then
               leave
            else
               iterate
            endif

            thisLineIsBlank = 1
            newPar = 0

         ----------------------------------------------------------------------
         -- if previous line is not blank
         else
            thisLineIsBlank = 1
            newPar = 1  -- reflow prev par
            -- blank line ends list item
            thisListIndentLevel = 0
            ListStart = 0
         endif
      -------------------------------------------------------------------------
      -- if not a blank line
      else

         ----------------------------------------------------------------------
         -- reflow prev par if QuoteLevel has changed
         if thisQuoteLevel <> prevQuoteLevel then
            if prevLineIsBlank then
               newPar = 0
            else
               replaceline line  -- change back from sline to line
               insertline '', .line
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
               call NepmdPmPrintf( 'Line no '.line':  blank line inserted before current line')
compile endif
               up
               iterate
            endif
         ----------------------------------------------------------------------
         -- if QuoteLevel hasn't changed
         else
            newPar = 0
         endif

         ----------------------------------------------------------------------
         -- check if this line is verbatim or list
         if Mail_IsVerbatim( sline, IndentedIsVerbatim) then  -- checks temp. also if indented     <--------- Todo
            thisLineIsVerbatim = 1
         elseif Mail_IsListItem( sline, thisListIndentLevel) then
            ListStart = .line
            newPar = 1
            thisLineIsVerbatim = 1  -- temp. activated                        <--------- Todo
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
            call NepmdPmPrintf( 'Line no '.line':  New list item: thisLineIsVerbatim = 'thisLineIsVerbatim)
compile endif
         elseif (thisIndentLevel = thisListIndentLevel) & thisListIndentLevel > 0 then
            -- continuing list item
            thisLineIsVerbatim = 1  -- temp. activated                        <--------- Todo
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
            call NepmdPmPrintf( 'Line no '.line':  Continued list item: thisLineIsVerbatim = 'thisLineIsVerbatim)
compile endif
         elseif thisIndentLevel <> prevIndentLevel then
            -- different indent ends list item and starts new par
            thisListIndentLevel = 0
            ListStart = 0
            newPar = 1
         endif

         if prevLineIsBlank = 0 then
            -------------------------------------------------------------------
            -- reflow last par if this or prev line is a verbatim line
            if thisLineIsVerbatim | prevLineIsVerbatim then
               newPar = 1
            --elseif  then
            endif
            -- reflow last par if prev lines is a par of a list item or indented         <------ Missing
            -- Save bullet chars. Mark lines. Set margins with indent = thisIndentLevel. Reformat par.
            -- Overlay bullet chars. Unmark.

            -------------------------------------------------------------------
         endif

      endif
      -------------------------------------------------------------------------
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
      call NepmdPmPrintf( 'Line no '.line':  QuoteLevel this/prev/prevprev = 'thisQuoteLevel'/'prevQuoteLevel'/'prevPrevQuoteLevel', newPar = 'newPar', sline = |'sline'|')
compile endif

      if newPar then
         -- begin reflow prev par
         -- reset only if a new par, not if a verbatim line
         prevPrevParQuoteLevel = prevParQuoteLevel  -- quote level for prevprev par
         prevParQuoteLevel     = prevQuoteLevel     -- quote level for prev par
         if FileIsMarked() then  -- if marked
compile if NEPMD_DEBUG_MAILREFLOW and NEPMD_DEBUG
            call NepmdPmPrintf( 'Line no '.line':  prevLineIsVerbatim = 'prevLineIsVerbatim', noReflow = 'noReflow)
compile endif
            reflowFlag = (prevLineIsVerbatim = 0) bitand (noReflow = 0)
            call Mail_ReflowMarkedLines( prevParQuoteLevel, prevPrevParQuoteLevel, reflowFlag)
            unmark
         endif
      endif

      if thisLineIsBlank = 0 then
         mark_line
      endif

      if .line = .last then
         leave
      else
         down
         .col = 1
      endif

      prevLineIsBlank    = thisLineIsBlank
      prevLineIsVerbatim = thisLineIsVerbatim
      prevIndentLevel    = thisIndentLevel

      if thisLineIsBlank = 0 then
         prevPrevQuoteLevel = prevQuoteLevel
         prevQuoteLevel     = thisQuoteLevel
      endif

   enddo  -- forever

   -- remove last blank lines
   do while textline(.last) = ''
      deleteline .last
   enddo

