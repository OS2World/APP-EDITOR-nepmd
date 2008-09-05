/****************************** Module Header *******************************
*
* Module Name: reflowmail.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: reflowmail.e,v 1.17 2008-09-05 23:08:54 aschn Exp $
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
?  *  par (maybe replace parindent by parskip?)
ok *  verbatim
ok *  lists
-> *  tables (not recognized, must be indented)
ok *  blank lines
ok *  multiple spaces
ok *  trailing spaces
-> *  tabs (currently converted to 1 space in lists, kept in verbatim parts)
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
   spaces in HTML forums.
*/


compile if not defined(SMALL)  -- If being externally compiled...
   include 'STDCONST.E'
compile endif

defmain
   'ReflowMail'

; ---------------------------------------------------------------------------
defproc Mail_GetQuoteLevel( line, var sline, var ThisQuoteLevel, var ThisIndent)
   ThisQuoteLevel = 0
   ThisIndent = 0
   QuoteCharList = '> : %'
   DefaultQuoteChar = '>'  -- for XyZ> quotes
   fLastIsQuoteChar = 0
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
         ThisIndent = ThisIndent + 1
         col = col + 1
         -- Remove 1 possible space after QuoteChar
         if fLastIsQuoteChar then  -- if last char was a QuoteChar
            startp = col
            fLastIsQuoteChar = 0
         endif
      elseif pos( next, QuoteCharList) & (ThisQuoteLevel > 0 | ThisIndent < 3) then
         ThisQuoteLevel  = ThisQuoteLevel + 1
         ThisIndent = 0
         col = col + 1
         startp = col
         fLastIsQuoteChar = 1
      else  -- for WXyZ> quote marks
         next = substr( line, col, 5)  -- 5: max 4 chars for name
         p1 = pos( DefaultQuoteChar, next)
         p2 = verify( '-=', next, 'M')    -- don't count arrows as quote chars
         if p1 & (p2 = 0) then
            ThisQuoteLevel = ThisQuoteLevel + 1
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
; Reflow previous paragraph.
defproc Mail_ReflowMarkedLines( PrevParQuoteLevel, PrevPrevParQuoteLevel, PrevListIndent, PrevBullet, fEnableReflow, fIndentLists)
   QuoteChar = '>'
   SpaceAmount = 1  -- Spaces after QuoteChar
   RightMargin = 72 - length( QuoteChar) - SpaceAmount

   -- Set margins to max to avoid any automatic line break
   .margins = 1 1599 1
   -- Go to begin mark
   getmark FirstLine, LastLine, FirstCol, LastCol, Fid
   .line = FirstLine
   dprintf( 'REFLOWMAIL', 'Starting at line no '.line )

   -- Remove bullet chars
   if PrevBullet <> '' then
      replaceline overlay( copies( ' ', length( PrevBullet)), textline( FirstLine)), FirstLine
   endif

   -- Set margins for reflow, substract indent
   if PrevParQuoteLevel > 0 then
      PrevIndent = PrevParQuoteLevel + SpaceAmount
   else
      PrevIndent = 0
   endif

   if fIndentLists then
      lma = PrevListIndent + 1
      rma = RightMargin - PrevIndent - PrevListIndent
      pma = lma
   else
      lma = 1
      rma = RightMargin - PrevIndent
      -- Indent the bullet line to the length of the bullet chars plus
      -- following spaces. Also the original indent is kept.
      pma = PrevListIndent + 1
   endif

;dprintf( 'margins = 'lma rma pma' on formatting par before line '.line)
   .margins = lma rma pma

   if fEnableReflow then
      -- Reflow marked lines, starting at cursored line
      dprintf( 'REFLOWMAIL', '  Reflowing lines no 'FirstLine' to 'LastLine', Indent = 'PrevIndent', ListIndent = 'PrevListIndent', Bullet = ['PrevBullet']')
      reflow
   else
      -- Don't reflow marked lines, starting at cursored line
      dprintf( 'REFLOWMAIL', '  Not reflowing lines no 'FirstLine' to 'LastLine)
   endif

   -- Set margins to max to avoid any automatic line break
   .margins = 1 1599 1

   getmark FirstLine, LastLine, FirstCol, LastCol, Fid

   -- Re-add bullet chars
   if PrevBullet <> '' then
      replaceline overlay( PrevBullet, textline( FirstLine)), FirstLine
   endif

   -- Insert quote chars in every marked line
   -- Go back to start - 1 if prev line is a blank line to calc quote level and add quote chars
   if FirstLine > 1 then
      .line = FirstLine - 1
      getline line
      if strip(line) <> '' then
         .line = Firstline
      endif
   endif

   do forever --l = 1 to LastLine - FirstLine
      getline line

      if strip(line) = '' then
         dprintf( 'REFLOWMAIL', '* QuoteLevel PrevPar/PrevPrevPar = 'PrevParQuoteLevel'/'PrevPrevParQuoteLevel)
         BlankLineQuoteLevel = min( PrevParQuoteLevel, PrevPrevParQuoteLevel )
         if BlankLineQuoteLevel > 0 then
            replaceline copies( QuoteChar, BlankLineQuoteLevel)''copies( ' ', SpaceAmount)''line
            dprintf( 'REFLOWMAIL', '* line = ['line']')
         endif

      elseif PrevParQuoteLevel > 0 then
         -- Prepend quote chars and space
         replaceline copies( QuoteChar, PrevParQuoteLevel)''copies( ' ', SpaceAmount)''line
         dprintf( 'REFLOWMAIL', '* line = ['line']')
      endif

      -- Position cursor on line following the mark or leave
      if .line = .last then
         leave  -- return
      elseif .line >= LastLine then
         down   -- go back to line after mark
         dprintf( 'REFLOWMAIL', ' Back on next unmarked line no '.line': ['textline( .line)']')
         leave  -- return
      else
         down   -- go to next marked line
         dprintf( 'REFLOWMAIL', '  Going to next marked line no '.line': ['textline( .line)']')
      endif

   enddo
   return

; ---------------------------------------------------------------------------
; Check if current line is verbatim.
defproc Mail_IsVerbatim( sline)
   ssline = strip( sline, 'l')
   FirstChar  = substr( ssline, 1, 1)
   fIndentedIsVerbatim = (arg(2) = 1)  -- Flag; if 1: recognize every indented line as verbatim
   fIsVerbatim = 0

   -- Empty line
   if ssline = '' then
      -- not verbatim

   -- External quotes
   elseif FirstChar = '|' then
      fIsVerbatim = 1

   -- Indented line with indent >= 1
   elseif (substr( sline, 1, 1) = ' ' | substr( sline, 1, 1) = \9) & fIndentedIsVerbatim then
      fIsVerbatim = 1
   endif
   return fIsVerbatim

; ---------------------------------------------------------------------------
; Check if current line starts a list item and set vars for it.
defproc Mail_IsListItem( sline, var ThisListIndent, var ThisBullet)
   ssline = strip( sline, 'l')
   FirstChar  = substr( ssline, 1, 1)
   SecondChar = substr( ssline, 2, 1)
   ThirdChar  = substr( ssline, 3, 1)
   FourthChar = substr( ssline, 4, 1)
   fIsListItem = 0
   ThisBullet = ''
   SavedListIndent = ThisListIndent

   -- Numbered lists
   if isnum( FirstChar) then
      if pos( SecondChar, '.)') > 0 & pos( ThirdChar, ' '\13) > 0 then
         fIsListItem = 1
         ThisBullet = FirstChar''SecondChar
      elseif isnum( SecondChar) & pos( ThirdChar, '.)') > 0 & pos( FourthChar, ' '\9) > 0 then
         ThisBullet = FirstChar''SecondChar''ThirdChar
         fIsListItem = 1
      endif

   -- Alphabetically numbered lists
   elseif pos( FirstChar, 'abcdefghijklmnopqrstuvw') then
      if pos( SecondChar, '.)') > 0 & pos( ThirdChar, ' '\13) > 0 then
         fIsListItem = 1
         ThisBullet = FirstChar''SecondChar
      endif

   -- Bullet lists
   elseif pos( FirstChar, '-o*' ) > 0 & pos( SecondChar, ' '\9) > 0 then
      ThisBullet = FirstChar
      fIsListItem = 1
   elseif pos( FirstChar, '-') > 0 & pos( SecondChar, '-') > 0 & pos( ThirdChar, ' '\9) > 0 then
      ThisBullet = FirstChar''SecondChar
      fIsListItem = 1
   endif


   if fIsListItem then
      SpacesBeforeBullet = max( verify( sline, ' '\9) - 1, 0)
      SpacesAfterBullet = max( verify( substr( ssline, length(ThisBullet) + 1), ' '\9) - 1, 0)

      -- Indent bullet with spaces to the indent of the current line
      ThisBullet = copies( ' ', SpacesBeforeBullet)''ThisBullet

      ThisListIndent = length( ThisBullet) + SpacesAfterBullet
   else
      ThisListIndent = SavedListIndent
   endif

   return fIsListItem

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
defc ReflowMail
   universal nepmd_hini
   universal vTemp_Path
   universal InfolineRefresh
   universal vepm_pointer

   mouse_setpointer WAIT_POINTER
   saved_autosave = .autosave
   .autosave = 0
   saved_modify = .modify
   call NewUndoRec()
   call DisableUndoRec()
   InfolineRefresh = 0
   display -1

   fPrevLineIsBlank    = 0
   fPrevLineIsVerbatim = 0
   PrevQuoteLevel     = 0
   PrevPrevQuoteLevel = 0
   PrevParQuoteLevel     = 0
   PrevPrevParQuoteLevel = 0
   fNoReflow = 0
   fNewPar   = 0
   SigQuoteLevel = 0
   ThisIndent = 0
   PrevIndent = 0
   ThisQuoteLevel  = 0
   fReflow = 0
   fSig = 0
   ThisBullet = ''
   PrevBullet = ''
   ThisListIndent = 0
   PrevListIndent = 0

   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedLines'
   -- Default is to not reflow indented lines
   fIndentedIsVerbatim = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 1)

   KeyPath = '\NEPMD\User\Reflow\Mail\IndentLists'
   -- Default is to indent lists
   fIndentLists = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)

   .line = 1
   .col  = 1
   unmark

   -- Add a blank line after last to make reflow of the last par easy
   insertline '', .last + 1
   i = 0
   --do forever
   do while i < 10000
      i = i + 1  -- Added only as emergency stop, for nothing else.
                 -- Maybe this will help to find the bug in it?
      fThisLineIsBlank    = 0
      fThisLineIsVerbatim = 0
      getline line

      -- GetQuoteLevel() and strip quote chars from line
      call Mail_GetQuoteLevel( line, sline, ThisQuoteLevel, ThisIndent)

      -- Strip off trailing spaces, except from signature mark
      -- Remove quoted signatures
      if (ThisQuoteLevel = SigQuoteLevel) & (SigQuoteLevel > 0) then
         deleteline
         iterate
      endif
      if substr( sline, 1, 2) = '--' & length( sline) = 2 /*pos( substr( sline, 3, 1), '>-') = 0*/ then
         -- Correct stripped space if none
         sline = '-- '
      endif
      if fSig then
         fNoReflow = 1
      --elseif substr( sline, 1, 3) = '-- ' then
      elseif sline == '-- ' then
         fNewPar = 1
         fSig = 1
         SigQuoteLevel = ThisQuoteLevel
         if SigQuoteLevel > 0 then
            deleteline
            iterate
         endif
      else
         fNoReflow = 0
         sline = strip( sline, 'T', ' ')
         SigQuoteLevel = 0
      endif

      -- Temp. write the line without the stripped quote chars
      replaceline sline
      dprintf( 'REFLOWMAIL', 'Line no '.line':  #  fPrevLineIsBlank = 'fPrevLineIsBlank', QuoteLevel = 'ThisQuoteLevel', line = ['line']')

      -- If a blank line
      if sline = '' then

         -- If previous line is blank
         if fPrevLineIsBlank then

            deleteline
            if .line = .last then
               leave
            else
               iterate
            endif

            fThisLineIsBlank = 1
            fNewPar = 0

         -- If previous line is not blank
         else
            fThisLineIsBlank = 1
            fNewPar = 1  -- reflow prev par
            -- Keep previous list indent level to enable pars in list items
            --ThisListIndent = 0
         endif

      -- If not a blank line
      else

         -- Reflow prev par if QuoteLevel has changed
         if ThisQuoteLevel <> PrevQuoteLevel then
            if fPrevLineIsBlank then
               fNewPar = 0
            else
               replaceline line  -- change back from sline to line
               insertline '', .line
               dprintf( 'REFLOWMAIL', 'Line no '.line':  blank line inserted before current line')
               up
               iterate
            endif
         -- If QuoteLevel hasn't changed
         else
            fNewPar = 0
         endif

         -- Check if this line is a list item or if verbatim
         SavedBullet = ThisBullet
         fIsNewListItem = Mail_IsListItem( sline, ThisListIndent, ThisBullet)
         fIsContinuedListItem = (ThisListIndent > 0 &
                                 -- indent for current line is last list indent
                                 ((ThisIndent = ThisListIndent) |
                                  -- allow 1 optional space after the quote chars
                                  (ThisIndent = ThisListIndent + 1 & ThisQuoteLevel > 0)))
         fIsVerbatim = Mail_IsVerbatim( sline, fIndentedIsVerbatim)

         if fNoReflow then
            -- ignore
         elseif fIsNewListItem then
            fNewPar = 1
            dprintf( 'REFLOWMAIL', 'Line no '.line':  New list item: ThisListIndent = 'ThisListIndent)
         elseif fIsContinuedListItem then
            -- Continuing list item
            -- The bullet from the new item line must be restored, because the
            -- check for it has just reset it. The bullet char will be handled
            -- specially for the first marked line only and if it's not empty.
            ThisBullet = SavedBullet
            dprintf( 'REFLOWMAIL', 'Line no '.line':  Continued list item: ThisListIndent = 'ThisListIndent)
         elseif fIsVerbatim then
            fThisLineIsVerbatim = 1
            ThisListIndent = 0
            dprintf( 'REFLOWMAIL', 'Line no '.line':  Verbatim line: fThisLineIsVerbatim = 'fThisLineIsVerbatim)
         elseif ThisIndent <> PrevIndent | (ThisIndent <> PrevListIndent & PrevListIndent > 0) then
            -- Different indent ends list item and starts new par
            ThisListIndent = 0
            fNewPar = 1
            dprintf( 'REFLOWMAIL', 'Line no '.line':  Different indent: This/Prev/PrevList = 'ThisIndent'/'PrevIndent'/'PrevListIndent)
         endif

         if fPrevLineIsBlank = 0 then
            -- Reflow last par if this or prev line is a verbatim line
            if fThisLineIsVerbatim | fPrevLineIsVerbatim then
               fNewPar = 1
            endif
         endif

      endif
      dprintf( 'REFLOWMAIL', 'Line no '.line':  QuoteLevel this/prev/prevprev = 'ThisQuoteLevel'/'PrevQuoteLevel'/'PrevPrevQuoteLevel', fNewPar = 'fNewPar)

      -- Reflow previous par
      if fNewPar then
         PrevPrevParQuoteLevel = PrevParQuoteLevel  -- quote level for prevprev par
         PrevParQuoteLevel     = PrevQuoteLevel     -- quote level for prev par
;dprintf( 'FileIsMarked() called on line '.line)
         if FileIsMarked() then  -- if marked
            dprintf( 'REFLOWMAIL', 'Line no '.line':  fPrevLineIsVerbatim = 'fPrevLineIsVerbatim', fNoReflow = 'fNoReflow)
            fReflow = (fPrevLineIsVerbatim = 0) bitand (fNoReflow = 0)
            call Mail_ReflowMarkedLines( PrevParQuoteLevel, PrevPrevParQuoteLevel, PrevListIndent, PrevBullet, fReflow, fIndentLists)
            unmark
         endif
      endif

      if fThisLineIsBlank = 0 then
         mark_line
      endif

      if .line = .last then
         leave
      else
         down
         .col = 1
      endif

      -- Save vars for current line. In case of a reflow if a new par was
      -- indented, these values are submitted to Mail_ReflowMarkedLines.
      fPrevLineIsBlank    = fThisLineIsBlank
      fPrevLineIsVerbatim = fThisLineIsVerbatim
      PrevIndent          = ThisIndent
      PrevListIndent      = ThisListIndent
      PrevBullet          = ThisBullet

      if fThisLineIsBlank = 0 then
         PrevPrevQuoteLevel = PrevQuoteLevel
         PrevQuoteLevel     = ThisQuoteLevel
      endif

   enddo  -- forever

   -- Remove last blank lines
   do while textline(.last) = ''
      deleteline .last
   enddo

   display 1
   InfolineRefresh = 1
   .autosave = saved_autosave
   if .modify > saved_modify then
      .modify = saved_modify + 1
   endif
   call NewUndoRec()
   mouse_setpointer vepm_pointer
   return

