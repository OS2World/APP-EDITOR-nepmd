/****************************** Module Header *******************************
*
* Module Name: wrap.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: wrap.e,v 1.6 2005-05-01 22:53:24 aschn Exp $
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

; ---------------------------------------------------------------------------
; Query wrapped state of current file. Returns 1 or 0.
defproc GetWrapped
   universal EPM_utility_array_ID
   -- Save wrapped state in an array var
   getfileid fid
   rc = get_array_value( EPM_utility_array_ID, 'wrapped.'fid, Wrapped)
   if rc = 0 then
      return Wrapped
   else
      return 0
   endif

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
defc softwrap2win, softwrap
   universal EPM_utility_array_ID

   -- Check if already wrapped
   if GetWrapped() then
      -- Unwrap first
      'unwrap'
   endif

   -- Check if monospaced
   parse value queryfont(.font) with fontname '.' fontsize '.'
   if .levelofattributesupport bitand 4 then  -- Mixed fonts?
      monospaced = 0                          -- Can't assume monospaced regardless of font
   else
      monospaced = 1
      MonoStrings = 'COURIER MONO VIO TYPEWRITER'
      Match = 0
      do w = 1 to words(MonoStrings)
         wrd = word( MonoStrings, w)
         if pos( upcase(wrd), upcase(fontname)) then
            Match = 1
            leave
         endif
      enddo
      if Match = 0 then
      --if fontname<>'Courier' & fontname<>'System Monospaced' & then
         if rightstr( fontsize, 2) = 'BB' then  -- Bitmapped font
            parse value fontsize with 'DD' decipoints 'WW' width 'HH' height 'BB'
            if not (width & height) then  -- It's fixed pitch
               monospaced = 0
            endif
         endif
      endif  -- fontname
   endif  -- .levelofattributesupport

   swp1 = copies( \0, 36)
   call dynalink32( 'PMWIN',
                    '#837',  -- Win32QueryWindowPos
                    gethwndc(EPMINFO_EDITCLIENT)  ||
                    address(swp1))
   par_width = ltoa( substr( swp1, 9, 4), 10)

   -- Calculate limit = split col for a monospaced font
   if monospaced then  -- Calculate once, outside of the loop
      x = 1; y = 1
      map_point map_LCOToDoc, x, y  -- Get y position of current line.
      x = par_width
      y = y + 5
      map_point map_DocToLCO, x, y  -- Get column corresponding to pel pos. wM
      limit = y - 2
   endif

   getfileid fid
   client_fid = gethwndc(EPMINFO_EDITCLIENT) || atol(fid)
   -- no additional undo state supression required
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call psave_pos(saved_pos)

   -- Split lines
   -- Start at line 1
   w = 0  -- number of wrapped lines
   l = 1  -- line number
   do while l <= .last
      getline line, l

      -- Calculate limit = split col for a proportional font
      if not monospaced then  -- Have to calculate for each line individually
         x = l; y = 1
         map_point map_LCOToDoc, x, y  -- Get y position of current line.
         x = par_width
         y = y + 5
         map_point map_DocToLCO, x, y  -- Get column corresponding to pel pos. wM
         limit = y - 2
      endif

      if length( strip( line, 'T')) > limit then
         -- Split line
         p = 0
         -- First process special features for some modes
         Mode = NepmdGetMode()

         -- CONFIG.SYS: try to break line at ';' or '+' first
         -- The next line will have that char at col 1 than.
         if Mode = 'CONFIGSYS' then
            p = lastpos( ';', line, limit)
            if p = 0 then
               p = lastpos( '+', line, limit)
            endif
         endif

         -- Split at last space before limit
         if p = 0 then
            p = lastpos( ' ', line, limit)
            first_nonblank_p = max( 1, verify( line, ' '\t))
            --if not p then    -- No spaces in the line?
            -- Fixed: endless loop if a line starts with a space.
            if p < first_nonblank_p then  -- No spaces in the line after indent?
               p = limit
            endif
         endif
         l
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
      Wrapped = 1
      sayerror 'Wrapped 'w' lines reversible. ("Save" won''t add line ends unless you add any.)'
   else
      Wrapped = 0
      sayerror 'No wrap required'
   endif
   do_array 2, EPM_utility_array_ID, 'wrapped.'fid, Wrapped

; ---------------------------------------------------------------------------
; Soft-unwrap lines of current file. Determine line terminators of type
; MaxLnSize_unterminated and join these lines.
;
; For mode = CONFIGSYS: Check if first char in nextline is ';' or '+'.
; If found, then join line with nextline, even if line terminator is not
; unterminated. This enables to unwrap lines, the user has added in wrapped
; status.
defc unwrap
   universal EPM_utility_array_ID

   getfileid fid
   client_fid = gethwndc(EPMINFO_EDITCLIENT) || atol(fid)
   -- no additional undo state supression required
   saved_readonly = .readonly
   if saved_readonly then
      .readonly = 0  -- need to disable .readonly temporarily
   endif
   call psave_pos(saved_pos)

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
         Mode = NepmdGetMode()

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
   -- Save wrapped state in an array var
   Wrapped = 0
   getfileid fid
   do_array 2, EPM_utility_array_ID, 'wrapped.'fid, Wrapped

; ---------------------------------------------------------------------------
; Hard wrap: split lines. Try to split at words first.
;
; Syntax: wrap limit [style]
;         wrap style [limit]
;
;    limit = column after lines will be split | '*'
;            '*' means: open commandline with default value for user input
;            default = 79
;    style = 'KEEPINDENT' | 'SPLIT'
;            default = 'KEEPINDENT'
defc wrap
   universal vEPM_POINTER

   defaultlimit = 79
   defaultstyle = 'KEEPINDENT'

   parse arg arg1 arg2
   if arg2 = '' then
      if (isnum(arg1) | arg1 = '*') then
         limit = arg1
      else
         limit = defaultlimit
      endif
      style = defaultstyle
   else
      if (isnum(arg1) | arg1 = '*') then
         limit = arg1
         style = arg2
      else
         style = arg1
         limit = arg2
      endif
   endif
   style = upcase(style)
   if not wordpos( style, 'KEEPINDENT SPLIT') then
      sayerror 'WRAP: "'style'" is not a valid style.'
      return
   endif
   if not ((isnum(limit) & limit > 0) | limit = '*') then
      sayerror 'WRAP: "'limit'" is not a column number'
      return
   endif
   if limit = '*' then
      'commandline wrap 'style' 'defaultlimit
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

      if length( strip( line, 'T')) > limit then

         if style = 'KEEPINDENT' then
            -- Search last occurence of space or tab, starting at limit
            SpaceP = lastpos( ' ', line, limit)
            TabP   = lastpos( \9,  line, limit)
            p = max( SpaceP, TabP)
            first_nonblank_p = max( 1, verify( line, ' '\t))
            --if not p then    -- No spaces in the line?
            -- Fixed: additional blank line if a line start with a space.
            if p < first_nonblank_p then    -- No spaces in the line after indent?
               p = limit
            endif
            l        -- Set cursor on line l
            .col = p -- Set cursor on col p (before a possible space or tab,
                     -- splitlines() will remove spaces)
            -- Better take def of ENTER.E, defproc nepmd_stream_indented_split_line?
            --   *  keep indent (copy indent area of preceding line)
            --   *  respect comment chars (treat comment chars as indent)
            call splitlines()  -- keeps indent of current line

         else
            p = lastpos( ' ', line, limit)
            first_nonblank_p = max( 1, verify( line, ' '\t))
            --if not p then    -- No spaces in the line?
            -- Fixed: endless loop if a line start with a space.
            if p < first_nonblank_p then    -- No spaces in the line after indent?
               p = limit
            endif
            l         -- Set cursor on line l
            .col = p  -- Set cursor on col p (before a possible space)
            split
            getline splitline, l + 1  -- Strip leading spaces from the new line
            replaceline strip( splitline, 'l'), l + 1
         endif

         m = m + 1
      endif  -- length( strip( line, 'T')) > limit
      l = l + 1
   enddo  -- while l <= .last

   call prestore_pos(saved_pos)
   display 1
   mouse_setpointer vEPM_POINTER

   msg = 'Wrap after 'limit' chars: 'm
   if m = 1 then
      msg = msg' change.'
   else
      msg = msg' changes.'
   endif
   sayerror msg

   return


