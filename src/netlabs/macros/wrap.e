/****************************** Module Header *******************************
*
* Module Name: wrap.e
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
Todo:
-  tabs are handled as single chars (must be temp. expanded before)
*/
const
   map_WindowToDoc = 1  -- x, y    in; x, y    out
   map_DocToLCO    = 2  -- x, y    in; l, c, o out
   map_LCOToDoc    = 3  -- l, c, o in; x, y    out
   map_Doc2Win     = 4  -- x, y    in; x, y    out
   map_Win2LCO     = 5  -- x, y    in; l, c, o out
   map_LCO2Win     = 6  -- l, c, o in; x, y    out

   MAXLNSIZE_UNTERMINATED = 1

   WRAP_CHARS = ' '\9',;>'

; ---------------------------------------------------------------------------
; Used to set the universal var on defselect.
; Configurable via Newmenu. reflowmargins is used by defc Wrap, defc
; ReflowAll2ReflowMargins and defc ReflowPar2ReflowMargins.
defc ReflowmarginsInit
   universal nepmd_hini
   universal reflowmargins
   KeyPath = '\NEPMD\User\Reflow\MarginsItem'
   i = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if i = 3 then
      reflowmargins = .margins
   else
      KeyPath = '\NEPMD\User\Reflow\Margins'i
      reflowmargins = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif

definit
   -- Respect files' margins if this is selected for use as reflowmargins
   -- This sets the universal var reflowmargins to initial values, queried
   -- from NEPMD.INI.
   -- (Found no better place when to execute the hook.)
;##############################################
   'HookAdd select ReflowMarginsInit'  -------------------------------- Todo
;##############################################

; ---------------------------------------------------------------------------
; Query wrapped state of current or specified file. Returns 1 or 0.
defproc GetWrapped
   Filename = arg(1)
   if Filename = '' then
      getfileid fid
   else
      getfileid fid, Filename
   endif
   return (GetAVar( 'wrapped.'fid) = 1)

; ---------------------------------------------------------------------------
; Wrap or umwrap current file depending on the wrapped state.
defc ToggleWrap
   if GetWrapped() then
      'unwrap'
   else
      'softwrap2win'
   endif

; ---------------------------------------------------------------------------
; Wrap current file to fit its lines into the current window width.
;
; Save won't destroy the file, because the additional line terminators are
; removed internally. That makes it even possible to unwrap the file.
;
; Derived from Flow2Win.E by Larry Margolis.
;
; For mode = CONFIGSYS: Try to wrap at ';' or '+' first. If found, then the
; next line will have a ';' or a '+' at col 1.
defc SoftWrap2Win, SoftWrap
   -- Check if already wrapped
   if GetWrapped() then
      -- Unwrap first
      'unwrap'
   endif

   -- Check if monospaced
   parse value queryfont(.font) with fontname '.' fontsize '.'
   if .levelofattributesupport bitand 4 then  -- Mixed fonts?
      fMonospaced = 0                          -- Can't assume monospaced regardless of font
   else
      fMmonospaced = IsMonoFont()
   endif  -- .levelofattributesupport

   swp1 = copies( \0, 36)
   call dynalink32( 'PMWIN',
                    '#837',  -- Win32QueryWindowPos
                    gethwndc(EPMINFO_EDITCLIENT)  ||
                    address(swp1))
   par_width = ltoa( substr( swp1, 9, 4), 10)

   -- Calculate limit = split col for a monospaced font
   if fMonospaced then  -- Calculate once, outside of the loop
      x = 1; y = 1
      map_point map_LCOToDoc, x, y  -- Get y position of current line.
      x = par_width
      y = y + 5
      map_point map_DocToLCO, x, y  -- Get column corresponding to pel pos. wM
      SplitCol = y - 2
   endif

   getfileid fid
   client_fid = gethwndc(EPMINFO_EDITCLIENT) || atol(fid)
   -- no additional undo state supression required
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call psave_pos(saved_pos)
   call DisableUndoRec()
   saved_modify = .modify

   -- Split lines
   -- Start at line 1
   w = 0  -- number of wrapped lines
   l = 1  -- line number
   do while l <= .last
      getline ThisLine, l

      -- Calculate limit = split col for a proportional font
      if not fMonospaced then  -- Have to calculate for each line individually
         x = l; y = 1
         map_point map_LCOToDoc, x, y  -- Get y position of current line.
         x = par_width
         y = y + 5
         map_point map_DocToLCO, x, y  -- Get column corresponding to pel pos. wM
         SplitCol = y - 2
      endif

      if length( strip( ThisLine, 'T')) > SplitCol then
         -- Split line
         p = 0
         -- First process special features for some modes
         Mode = GetMode()

         -- CONFIG.SYS: try to break line at ';' or '+' first
         -- The next line will have that char at col 1 than.
         if Mode = 'CONFIGSYS' then
            p = lastpos( ';', ThisLine, SplitCol)
            if p = 0 then
               p = lastpos( '+', ThisLine, SplitCol)
            endif
         endif

         -- Split at last space before SplitCol
         if p = 0 then
            first_nonblank_p = max( 1, verify( ThisLine, ' '\9))
            do c = 1 to length( WRAP_CHARS)
               ch = substr( WRAP_CHARS, c, 1)
               -- Split at last char before SplitCol
               p = lastpos( ch, ThisLine, SplitCol)
               if p > 0 then
                  if ch <> ' ' then
                     p = p + 1  -- Go after the WrapChar if not a space
                  endif
                  leave
               endif
            enddo
            -- Fixed: endless loop if a line starts with a space.
            if p < first_nonblank_p then  -- No spaces in the line after indent?
               p = SplitCol
            endif
         endif
         .line = l
         .col = p
         split

         -- Change line terminator id to 1 = unterminated
         call dynalink32( E_DLL,
                         'EtkChangeLineTerminator',
                          client_fid ||
                          atol(l)    ||
                          atol(MAXLNSIZE_UNTERMINATED))
         w = w + 1
      endif

      l = l + 1
   enddo

   call prestore_pos(saved_pos)
   if saved_readonly then
      .readonly = 1
   endif
   -- Save wrapped state in an array var
   if w > 0 then
      fWrapped = 1
      sayerror 'Wrapped 'w' lines (restored on file save)'
      'AvoidSaveOptions /o /l'
   else
      fWrapped = 0
      sayerror 'No wrap required'
   endif
   call EnableUndoRec()
   .modify = saved_modify
   call SetAVar( 'wrapped.'fid, fWrapped)

; ---------------------------------------------------------------------------
; Wrap current file to wrap its lines according to the current reflowmargins.
;
; Save won't destroy the file, because the additional line terminators are
; removed internally. That makes it even possible to unwrap the file.
;
; For mode = CONFIGSYS: Try to wrap at ';' or '+' first. If found, then the
; next line will have a ';' or a '+' at col 1.
defc SoftWrap2Reflowmargins
   universal reflowmargins

   -- Check if already wrapped
   if GetWrapped() then
      -- Unwrap first
      'unwrap'
   endif

   getfileid fid
   client_fid = gethwndc(EPMINFO_EDITCLIENT) || atol(fid)
   -- no additional undo state supression required
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call psave_pos(saved_pos)
   call DisableUndoRec()
   saved_modify = .modify

   -- Split lines
   -- Start at line 1
   w = 0  -- number of wrapped lines
   l = 1  -- line number
   do while l <= .last
      getline ThisLine, l

      SplitCol = word( reflowmargins, 2)

      if length( strip( ThisLine, 'T')) > SplitCol then
         -- Split line
         p = 0
         -- First process special features for some modes
         Mode = GetMode()

         -- CONFIG.SYS: try to break line at ';' or '+' first
         -- The next line will have that char at col 1 than.
         if Mode = 'CONFIGSYS' then
            p = lastpos( ';', ThisLine, SplitCol)
            if p = 0 then
               p = lastpos( '+', ThisLine, SplitCol)
            endif
         endif

         -- Split at last space before SplitCol
         if p = 0 then
            first_nonblank_p = max( 1, verify( ThisLine, ' '\9))
            do c = 1 to length( WRAP_CHARS)
               ch = substr( WRAP_CHARS, c, 1)
               -- Split at last char before SplitCol
               p = lastpos( ch, ThisLine, SplitCol)
               if p > 0 then
                  if ch <> ' ' then
                     p = p + 1  -- Go after the WrapChar if not a space
                  endif
                  leave
               endif
            enddo
            -- Fixed: endless loop if a line starts with a space.
            if p < first_nonblank_p then  -- No spaces in the line after indent?
               p = SplitCol
            endif
         endif
         .line = l
         .col = p
         split

         -- Change line terminator id to 1 = unterminated
         call dynalink32( E_DLL,
                         'EtkChangeLineTerminator',
                          client_fid ||
                          atol(l)    ||
                          atol(MAXLNSIZE_UNTERMINATED))
         w = w + 1
      endif

      l = l + 1
   enddo

   call prestore_pos(saved_pos)
   if saved_readonly then
      .readonly = 1
   endif
   -- Save wrapped state in an array var
   if w > 0 then
      fWrapped = 1
      sayerror 'Wrapped 'w' lines (restored on file save)'
      'AvoidSaveOptions /o /l'
   else
      fWrapped = 0
      sayerror 'No wrap required'
   endif
   call EnableUndoRec()
   .modify = saved_modify
   call SetAVar( 'wrapped.'fid, fWrapped)

; ---------------------------------------------------------------------------
; Set line terminator of type MaxLnSize_unterminated. Acts on current line
; or, when an arg was specified, a line relative to current line. 'NoWrap -1'
; removes the line end from previous line, 'NoWrap' from current line.
defc NoWrap
   if arg(1) = '' then
      LineNum = .line
   else
      LineNum = min( max( .line + arg(1), 1), .last)
   endif
   call NoWrapLine( LineNum)

defproc NoWrapLine
   if arg(1) = '' then
      LineNum = .line
   else
      LineNum = arg(1)
   endif
   getfileid fid
   client_fid = gethwndc( EPMINFO_EDITCLIENT)''atol(fid)
   call dynalink32( E_DLL,
                    'EtkChangeLineTerminator',
                    client_fid     ||
                    atol( LineNum) ||
                    atol( MAXLNSIZE_UNTERMINATED))
   call SetAVar( 'wrapped.'fid, 1)
   return

; ---------------------------------------------------------------------------
; Joins current or specified line number with next line. Must wrap at 1599.
; Todo:
;    Restore line end for LineNum + 1 if it was MAXLNSIZE_UNTERMINATED.
;    Join more lines, if cursor col not reached. Therefore specify
;    a vol num as required arg.
defc UnWrapLine
   SavedLine = .line
   SavedCol  = .col
   parse arg Col LineNum
   Col     = strip( Col)
   LineNum = strip( LineNum)

   if LineNum = '' then
      LineNum = .line
   else
      .line = LineNum
   endif
   if Col = '' then
      Col = .col
   else
      .col = Col
   endif

   do forever

      if LineNum = .last then
         return
      endif

      getline ThisLine, LineNum
      getline NextLine, LineNum + 1
      LenThisLine = length( ThisLine)
      LenNextLine = length( NextLine)

      if LenThisLine >= Col then
         return
      endif

      getfileid fid
      ClientFid = gethwndc( EPMINFO_EDITCLIENT)''atol(fid)

      TermType = '?'
      res = dynalink32( E_DLL,
                        'EtkQueryLineTerminator',
                        ClientFid           ||
                        atol( LineNum)      ||
                        address( TermType))
      TermId = 0
      if not res then
         TermId = asc( leftstr( TermType, 1))
      endif

      NextTermType = '?'
      res = dynalink32( E_DLL,
                        'EtkQueryLineTerminator',
                        ClientFid               ||
                        atol( LineNum + 1)      ||
                        address( NextTermType))
      NextTermId = 0
      if not res then
         NextTermId = asc( leftstr( NextTermType, 1))
      endif

      if TermId = MAXLNSIZE_UNTERMINATED then  -- 1 = MaxLnSize_unterminated
         getline ThisLine, LineNum
         getline NextLine, LineNum + 1
         LenThisLine = length( ThisLine)
         LenNextLine = length( NextLine)
         if LenThisLine + LenNextLine > 1599 then
            Next = leftstr( NextLine, 1599 - LenThisLine)
            Rest = substr( NextLine, 1599 - LenThisLine + 1)
            replaceline ThisLine''Next, LineNum
            replaceline Rest, LineNum + 1
         else
            replaceline ThisLine''NextLine, LineNum
            -- Set line terminator id to the id of the next line.
            -- This is required, because the line terminator id doesn't
            -- change automatically after a line join to the id of the
            -- next line.
            call dynalink32( E_DLL,
                             'EtkChangeLineTerminator',
                             ClientFid         ||
                             atol( LineNum)    ||
                             atol( NextTermId))
            deleteline LineNum + 1
         endif
      else
         leave
      endif

   enddo

   .line = SavedLine
   .col  = SavedCol

; ---------------------------------------------------------------------------
; Splits line at column under cursor, if required. After that, move to the
; next line that is longer than the cursor column. Tries to split at last
; space before the cursor.
; Todo: Unwrap before wrap, split at more chars
defc SoftWrapAtCursor
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call DisableUndoRec()
   saved_modify = .modify

   SplitCol = .col

;   -- Unwrap first
;   'UnwrapLine 'splitcol

   endline
   getline ThisLine
   if .col > SplitCol then
      first_nonblank_p = max( 1, verify( ThisLine, ' '\9))
      c = 0
      do c = 1 to length( WRAP_CHARS)
         ch = substr( WRAP_CHARS, c, 1)
         -- Split at last char before SplitCol
         p = lastpos( ch, ThisLine, SplitCol)
         if p > 0 then
            if ch <> ' ' then
               p = p + 1  -- Go after the WrapChar if not a space
            endif
            leave
         endif
      enddo
      if p < first_nonblank_p then  -- No spaces in the line after indent?
         p = SplitCol
      endif
      .col = p
      split  -- splits and keeps leading spaces
      if not GetWrapped() then
         'AvoidSaveOptions /o /l'
      endif
      call NoWrapLine()
   endif
   PrevLine = .line
   do forever
      if .line < .last then
         down
      endif
      if .line = PrevLine then
         leave
      endif
      PrevLine = .line
      endline
      if .col > SplitCol then
         leave
      endif
   enddo
   .col = SplitCol

   if saved_readonly then
      .readonly = 1
   endif
   .modify = saved_modify

; ---------------------------------------------------------------------------
; Soft-unwrap lines of current file. Determine line terminators of type
; MaxLnSize_unterminated and join these lines.
;
; For mode = CONFIGSYS: Check if first char in nextline is ';' or '+'.
; If found, then join line with nextline, even if line terminator is not
; unterminated. This enables to unwrap lines, the user has added in wrapped
; status.
defc UnWrap
   getfileid fid
   client_fid = gethwndc(EPMINFO_EDITCLIENT) || atol(fid)
   -- no additional undo state supression required
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call psave_pos(saved_pos)
   call DisableUndoRec()
   saved_modify = .modify

   -- Try to re-join lines
   -- Start at last line - 1
   l = .last - 1
   do while l > 0

      -- Try to join previously splitted lines first
      termtype = '?'
      res = dynalink32( E_DLL,
                        'EtkQueryLineTerminator',
                        client_fid ||
                        atol(l)    ||
                        address(termtype))
      termid = 0
      if not res then
         termid = asc( leftstr( termtype, 1))
      endif

      if termid = MAXLNSIZE_UNTERMINATED then  -- 1 = MaxLnSize_unterminated
         --sayerror 'Line 'line' is terminated with 'i
         if l > 0 then

            -- Get line terminator id of next line
            termtype = '?'
            res = dynalink32( E_DLL,
                              'EtkQueryLineTerminator',
                              client_fid  ||
                              atol(l + 1) ||
                              address(termtype))
            nexttermid = 4  -- default is CRLF
            if not res then
               nexttermid = asc( leftstr( termtype, 1))
            endif

            -- Join current and next line
            getline line, l
            getline nextline, l + 1
            joinedline = line''nextline
            replaceline joinedline, l
            deleteline l + 1

            -- Set line terminator id to the id of the next line.
            -- This is required, because the line terminator id doesn't
            -- change automatically after a line join to the id of the
            -- next line.
            call dynalink32( E_DLL,
                             'EtkChangeLineTerminator',
                             client_fid ||
                             atol(l)    ||
                             atol(nexttermid))
         endif

      else  -- termid = 1
         -- Process special features for some modes
         Mode = GetMode()

         if Mode = 'CONFIGSYS' then
            -- Check for ';' or '+' in col 1. Maybe the user has added a line
            -- and the line terminator isn't correct anymore.
            -- If such a string is found in nextline, nextline will be appended
            -- to line, even if the line terminator type is not 'unterminated'.
            getline nextline, l + 1
            first = leftstr( nextline, 1)
            if first = ';' or first = '+' then
               -- Join current and next line
               getline line, l
               joinedline = line''nextline
               replaceline joinedline, l
               deleteline l + 1
            endif
         endif

      endif

      l = l - 1
   enddo

   call prestore_pos(saved_pos)
   if saved_readonly then
      .readonly = 1
   endif
   call EnableUndoRec()
   .modify = saved_modify
   -- Save wrapped state in an array var
   fWrapped = 0
   call SetAVar( 'wrapped.'fid, Wrapped)

; ---------------------------------------------------------------------------
; Hard wrap: split lines. Try to split at words first.
;
; Syntax: Wrap SplitCol [Style]
;         Wrap Style [SplitCol]
;
;    SplitCol = column after lines will be split | '*'
;               '*' means: open commandline with default value for user input
;               default = 79
;    Style    = 'KEEPINDENT' | 'SPLIT'
;               default = 'KEEPINDENT'
defc Wrap
   universal vEPM_POINTER
   universal reflowmargins

   parse value reflowmargins with . DefaultSplitCol .
   Style = 'KEEPINDENT'

   args = strip( upcase( arg(1)))

   wp = wordpos( 'KEEPINDENT', args)
   if wp > 0 then
      args = delword( args, wp)
      Style = 'KEEPINDENT'
   endif
   wp = wordpos( 'SPLIT', args)
   if wp > 0 then
      args = delword( args, wp)
      Style = 'SPLIT'
   endif

   wp = wordpos( '*', args)
   if wp > 0 then
      args = delword( args, wp)
      'commandline' strip( 'wrap 'style) DefaultSplitCol
      return
   endif

   if args = '' then
      args = DefaultSplitCol
   endif

   -- Allow to specify a margin parameter as SplitCol
   parse value args with lma rma parma
   if rma > '' then
      SplitCol = rma
   elseif lma > '' then
      SplitCol = lma
   endif

   if not isnum( SplitCol) then
      sayerror 'WRAP: "'SplitCol'" is not a column number'
      return
   endif

   -- no additional undo state supression required
   if .readonly then
      sayerror 'File has .readonly field set. Edit is diabled, toggle .readonly first.'
      return
   endif
   call psave_pos(saved_pos)
   .line = 1
   .col  = 1
   m = 0
   l = 1
   getfileid fid
   client = gethwndc(EPMINFO_EDITCLIENT)
   mouse_setpointer WAIT_POINTER
   display -1  -- disable update of text area
   do while l <= .last
      -- process all lines
      getline line, l

      if length( strip( line, 'T')) > SplitCol then

         if style = 'KEEPINDENT' then
            -- Search last occurence of space or tab, starting at SplitCol
            SpaceP = lastpos( ' ', line, SplitCol)
            TabP   = lastpos( \9,  line, SplitCol)
            p = max( SpaceP, TabP)
            first_nonblank_p = max( 1, verify( line, ' '\9))
            --if not p then    -- No spaces in the line?
            -- Fixed: additional blank line if a line start with a space.
            if p < first_nonblank_p then    -- No spaces in the line after indent?
               p = SplitCol
            endif
            l        -- Set cursor on line l
            .col = p -- Set cursor on col p (before a possible space or tab,
                     -- splitlines() will remove spaces)
            -- Better take def of ENTER.E, defproc nepmd_stream_indented_split_line?
            --   *  keep indent (copy indent area of preceding line)
            --   *  respect comment chars (treat comment chars as indent)
            call splitlines()  -- keeps indent of current line

         else
            p = lastpos( ' ', line, SplitCol)
            first_nonblank_p = max( 1, verify( line, ' '\9))
            --if not p then    -- No spaces in the line?
            -- Fixed: endless loop if a line start with a space.
            if p < first_nonblank_p then    -- No spaces in the line after indent?
               p = SplitCol
            endif
            l         -- Set cursor on line l
            .col = p  -- Set cursor on col p (before a possible space)
            split
            getline SplitLine, l + 1  -- Strip leading spaces from the new line
            replaceline strip( SplitLine, 'l'), l + 1
         endif

         m = m + 1
      endif  -- length( strip( line, 'T')) > SplitCol
      l = l + 1
   enddo  -- while l <= .last

   call prestore_pos(saved_pos)
   display 1
   mouse_setpointer vEPM_POINTER

   Msg = 'Wrap after 'SplitCol' chars: 'm
   if m = 1 then
      Msg = Msg' change.'
   else
      Msg = Msg' changes.'
   endif
   sayerror Msg

   return


