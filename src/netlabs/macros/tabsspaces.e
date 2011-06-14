/****************************** Module Header *******************************
*
* Module Name: tabsspaces.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
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
defc Spaces2Tabs, TabsCompress
   parse arg arg1 .
   if arg1 = '' then
      'commandline Spaces2Tabs 'word( .tabs, 1)
      return
   else
      TabWidth = arg1
   endif
   dummy = ''
   fChanged = 0
   call NextCmdAltersText()
   do l = 1 to .last
      Line = textline(l)
      Line = ExpandLine( Line, TabWidth, dummy)
      Line = CompressLine( Line, TabWidth, fChanged)
      if fChanged then
         replaceline Line, l
      endif
   enddo

; ---------------------------------------------------------------------------
defc Tabs2Spaces, TabsExpand
   parse arg arg1 .
   if arg1 = '' then
      'commandline Tabs2Spaces 'word( .tabs, 1)
      return
   else
      TabWidth = arg1
   endif
   fChanged = 0
   do l = 1 to .last
      Line = textline(l)
      Line = ExpandLine( Line, TabWidth, fChanged)
      if fChanged then
         replaceline Line, l
      endif
   enddo

; ---------------------------------------------------------------------------
; Col and NextTabCol start at 0. So it's easier to calculate:
; TabWidth 8 gives stops at 0, 8, 16,...
; Avoid tab chars in quoted strings, if quote starts in this line.
defproc CompressLine( Line, TabWidth, var fChanged)
   fChanged = 0
   TabChar = \9
   rest = Line
   Line = ''
   Col = 0  -- processed chars, means .col - 1
   p = pos( '  ', rest)
   do while p <> 0
      LeftPart  = substr( rest, 1, p - 1)
      RightPart = substr( rest, p)  -- including all spaces
      Line = Line''LeftPart
      Col  = Col + length(LeftPart)
      SpaceLen = max( verify( RightPart, ' ', 'N') - 1, 0)
      if SpaceLen = 0 then
         SpaceLen = length(RightPart)  -- Avoid endless loop if spaces at end of line
      endif
      rest = substr( rest, p + SpaceLen)  -- stripped leading spaces
      if IsInQuotes( Line) then  -- Line is here only left part before current doublespace
         Line = Line''copies( ' ', SpaceLen)
         Col = Col + SpaceLen
      else
         do while SpaceLen > 0
            NextTabCol = Col + TabWidth - (Col//TabWidth)
            if (NextTabCol > Col) & (Col + SpaceLen >= NextTabCol) then
               Line = Line''TabChar
               SpaceLen = SpaceLen - (NextTabCol - Col)
               Col = NextTabCol
               if fChanged = 0 then
                  fChanged = 1
               endif
            else
               Line = Line''copies( ' ', SpaceLen)
               Col = Col + SpaceLen
               SpaceLen = 0
            endif
         enddo
      endif
      p = pos( '  ', rest)
   enddo
   Line = Line''rest
   return Line

; ---------------------------------------------------------------------------
; Col and NextTabCol start at 0. So it's easier to calculate:
; TabWidth 8 gives stops at 0, 8, 16,...
defproc ExpandLine( Line, TabWidth, var fChanged)
   fChanged = 0
   TabChar = \9
   if pos( TabChar, Line) = 0 then
      return Line
   endif
   rest = Line
   Line = ''
   p = pos( TabChar, rest)
   do while p <> 0
      LeftPart  = substr( rest, 1, p - 1)
      Line = Line''LeftPart
      rest = substr( rest, p + 1)
      Col  = length(Line)  -- processed columns before current tab char
      NextTabCol = Col + TabWidth - (Col//TabWidth)
      SpaceLen = NextTabCol - Col
      Line  = Line''copies( ' ', SpaceLen)
      if fChanged = 0 then
         fChanged = 1
      endif
      p = pos( TabChar, rest)
   enddo
   Line = Line''rest
   return Line

; ---------------------------------------------------------------------------
; Check if position p is quoted in Line, '...' or "...".
; Line is at this point only the left part of Line.
; If it contains an odd number of quotes or doublequotes, then 1 is returned.
defproc IsInQuotes( Line)
   ret = 0
   if Line <> '' then
      -- Count " in Line
      cdq = 0
      startp = 1
      pdq = 1
      do while pdq <> 0
         pdq = pos( '"', Line, startp)
         if pdq > 0 then
            cdq = cdq + 1
         endif
         startp = pdq + 1
      enddo
      if cdq//2 = 1 then
         ret = 1
      else
         -- Count ' in Line
         cq = 0
         startp = 1
         pq = 1
         do while pq <> 0
            pq = pos( "'", Line, startp)
            if pq > 0 then
               cq = cq + 1
            endif
            startp = pq + 1
         enddo
         if cq//2 = 1 then
            ret = 1
         endif
      endif
   endif
   return ret


