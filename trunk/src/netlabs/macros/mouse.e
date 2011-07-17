/****************************** Module Header *******************************
*
* Module Name: mouse.e
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
- move DClick on URL code to alt_1.e
- what about 'mailto://' recognized by Mozilla mail (just a bug or valid?)
  ('mailto:' is valid.)
*/

; The additions are, on the "no mark" pop-up menu, Mark Sentence
; and Mark Paragraph; on the "inside mark" pop-up, Extend Sentence
; Mark and Extend Paragraph Mark; and new mouse click actions:
;   Alt+Double-click button 2 = Mark sentence
;   Ctrl+Alt+Double-click button 2 = Mark paragraph
;   Shift+Alt+Double-click button 2 = Extend mark to end of next sentence
;   Ctrl+Shift+Alt+Double-click button 2 = Extend mark to end of next paragraph
;
; (Not all that memorable, but the best I could do with what was free.
; A 3-button mouse would help here...)
;
; It should be trivial for anyone who's done any EPM macro programming to
; define keys to invoke these functions if they want.
;
; Larry Margolis, margoli@ibm.net
; http://groups.google.com/groups?hl=de&lr=&ie=UTF-8&selm=5957rh%241buc%242%40news-s01.ca.us.ibm.net&rnum=9

; Link of MOUSE.E not possible anymore, maybe since v. 6.03.
compile if defined(MOUSE_SUPPORT)
 compile if MOUSE_SUPPORT = 'LINK'
   *** MOUSE.E can not be linked anymore. Set MOUSE_SUPPORT = 1.
 compile endif
compile endif

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
include 'stdconst.e'
include 'colors.e'
define INCLUDING_FILE = 'MOUSE.E'
const
   tryinclude 'MYCNF.E'        -- Include the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(VANILLA)
   VANILLA = 0
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
 compile if not defined(WANT_CHAR_OPS)
   WANT_CHAR_OPS = 1
 compile endif
 compile if not defined(WANT_TEXT_PROCS)
   WANT_TEXT_PROCS = 1
 compile endif
   include NLS_LANGUAGE'.e'
compile endif  -- not defined(SMALL)

const
compile if not defined(EPM_POINTER)
   EPM_POINTER = TEXT_POINTER      -- GPI version gets text pointer
compile endif
compile if not defined(LOCAL_MOUSE_SUPPORT)
   LOCAL_MOUSE_SUPPORT = 0
compile endif
compile if not defined(TOP_OF_FILE_VALID)
   TOP_OF_FILE_VALID = 1       -- Can be '0', '1', or 'STREAM' (dependant on STREAM_MODE)
compile endif
;compile if not defined(DRAG_ALWAYS_MARKS)
;   DRAG_ALWAYS_MARKS = 0  -- replaced in NEPMD
;compile endif
compile if not defined(WANT_MMEDIA)
   WANT_MMEDIA = 0
compile endif
;compile if not defined(WANT_SPEECH)  -- Speech support removed from mouse.e; totally separate now.
;   WANT_SPEECH = 0
;compile endif
compile if not defined(UNDERLINE_CURSOR)
   UNDERLINE_CURSOR = 0
compile endif
compile if not defined(CLICK_ONLY_GIVES_FOCUS)  -- Can be 0, ADVANCED, CUA, or 1
   CLICK_ONLY_GIVES_FOCUS = 'ADVANCED'
compile endif

; For testing:
compile if not defined(MOUSE_MARK_SETS_CURSOR)
-- Move the cursor to the mouse pointer after a mouse mark.
-- This was necessary, because otherwise it will be almost unpossible to
-- get the last char of a line marked if keyword highlighting is on.
-- See defc MH_end_mark.
   MOUSE_MARK_SETS_CURSOR = 3  -- 1|2|3  (don't change this, just for testing)
                               -- 1 = don't move cursor, jump back to cursor if cursor
                               --     is not on screen anymore
                               -- 2 = set cursor everytime to mouse position
                               -- 3 = set cursor only if cursor is not on screen and if
                               --     keyword highlighting is on
compile endif

const
  BlankMouseHandler = "BlankMouseHandler"
  TransparentMouseHandler = "TransparentMouseHandler"

define
   CHARG_MARK =  'CHARG'
   BLOCKG_MARK = 'BLOCKG'

; The following 2 procs are not used:
; ---------------------------------------------------------------------------
; .lineg and .cursoryg set the line without scrolling.
defproc prestore_pos2(save_pos)
   parse value save_pos with svline svcol svsx svsy
   .lineg = min(svline, .last);                       -- set .line
   .col = svcol;
   .scrollx = svsx;
   .cursoryg= svsy;

; ---------------------------------------------------------------------------
defproc psave_pos2(var save_pos)
   save_pos=.line .col .scrollx .cursoryg

; ---------------------------------------------------------------------------
; Returns cursor pos. for corresponding mouse pointer pos.
defproc MouseLineColOff( var MouseLine, var MouseCol, var MouseOff, minline)
                        -- MIN = 0 for positioning, 1 for marking.
   xxx = .mousex; mx = xxx
   yyy = .mousey

   -- saying 5.21, below, but not sure if it will work for that.
   --    it will work for 5.50.

   --call messagenwait("xxx1="xxx "yyy1="yyy);
   -- map_point 5 converts the vars xxx, yyy (mouse pointer) and off (empty)
   -- into .line, .col and offset values
   map_point 5, xxx, yyy, off, comment;  -- map screen to line
   --call messagenwait("doc xxx2="xxx "yyy2="yyy);
   MouseLine = min( max( xxx, minline), .last)
   MouseOff  = off
   -- EVERSION >= 5.50 can go to MAXCOL+1 for GPI-style marking
   if arg(6) then  -- Flag we want character we're on, not nearest intersection.
      lne = xxx
      col = yyy
      map_point 6, lne, col, off, comment;  -- map line/col/offset to screen
      if lne > mx then  -- The intersection selected is to the right of the mouse pointer;
         yyy = yyy - 1  -- the character clicked on is the one to the left.
      endif             -- Note:  could get col. 0 this way, but the following takes care of that.
   endif
   MouseCol  = min( max( yyy, 1), MAXCOL + ( rightstr( arg(5), 1) = 'G' and minline))
   return xxx

; ---------------------------------------------------------------------------
defc ShowCoord
   -- .cursorx is = .col for x-scroll = 0
   -- .cursory is 0 when cursor is on the first (topmost) visible line of the
   -- edit window. .cursory is = .windowheight on the lowest visible line of
   -- the edit window. It can also get < 0 and > .windowheight. That means
   -- that the cursor's column is outside of the visible area.
   dprintf( 'psave_pos:')
   dprintf( '   .line = '.line', .col = '.col', .cursorx = '.cursorx', .cursory = '.cursory)

   -- .scrollx is the amount of scrolled pels to the right.
   -- .cursoryg is .cursory in pels. Unlike other values, it counts from the
   -- top.
   dprintf( 'psave_pos2:')
   dprintf( '   .line = '.line', .col = '.col', .scrollx = '.scrollx', .cursoryg = '.cursoryg)

   -- MouseLineColOff returns line and col for the last mouse click.
   -- MouseOff is always 0.
   MinLine = 0
   call MouseLineColOff( MouseLine, MouseCol, MouseOff, MinLine)
   dprintf( 'MouseLineColOff:')
   dprintf( '   MouseLine = 'MouseLine', MouseCol = 'MouseCol', MouseOff = 'MouseOff', MinLine = 'MinLine)

   -- .scrolly is always 0 (bug).
   -- .windowwidth and .windowheight is the size of the edit window in
   -- lines and columns.
   dprintf( '   .scrolly = '.scrolly', .windowwidth = '.windowwidth', .windowheight = '.windowheight)
   -- .mousex and .mousey are the mouse coordinates from the last mouse click
   -- into the edit window in pels relative to the lower left angle of the
   -- edit window. They can be converted to line and col values with
   -- MousLineColOff.
   -- .cusorcolumn is always = .col, .cusoroffset is always 0
   dprintf( '   .mousex = '.mousex', .mousey = '.mousey', .cursorcolumn = '.cursorcolumn', .cursoroffset = '.cursoroffset)

; ---------------------------------------------------------------------------
defproc SetMouseSet(IsGlobal, NewMSName)
   universal GMousePrefix
   universal LMousePrefix
   universal EPM_utility_array_ID
   if IsGlobal then
      GMousePrefix = NewMSName"."
compile if LOCAL_MOUSE_SUPPORT
   else
      LMousePrefix = NewMSName"."
      -- Remember Local MouseSet
      getfileid ThisFile;
      do_array 2, EPM_utility_array_ID, "LocalMausSet."ThisFile, NewMSName
compile endif
   endif

; ---------------------------------------------------------------------------
compile if 0  -- Now in SELECT.E, only if LOCAL_MOUSE_SUPPORT = 1
defselect
   universal LMousePrefix
   universal EPM_utility_array_ID
   getfileid ThisFile
   OldRC = Rc
   rc = get_array_value(EPM_utility_array_ID, "LocalMausSet."ThisFile, NewMSName)
   if RC then
      if rc=-330 then
         -- no mouseset bound to file yet, assume blank.
         LMousePrefix = TransparentMouseHandler"."
      else
         call messagenwait('RC='RC)
      endif
      RC = OldRC
   else
      LMousePrefix = NewMSName"."
   endif
compile endif

; ---------------------------------------------------------------------------
defc processmousedropping
   call psave_pos(savepos)
   'MH_gotoposition'
   'GetSharBuff'     -- See clipbrd.e for details
   call prestore_pos(savepos)

; ---------------------------------------------------------------------------
defc processmouse
   universal EPM_utility_array_ID
   universal GMousePrefix
   universal LMousePrefix
   universal WindowHadFocus
   parse arg WindowHadFocus arg1

   -- 'processmouse' is called at every mouse action
   if not WindowHadFocus then
      'ResetDateTimeModified'
      'RefreshInfoLine MODIFIED'
   endif

   if LMousePrefix<>BlankMouseHandler"." then
      OldRc = rc
compile if LOCAL_MOUSE_SUPPORT
      rc = get_array_value( EPM_utility_array_ID, LMousePrefix||arg1, CommandString)
      if not rc then
         -- Found it.
         Rc = oldRC
         if CommandString <> '' then
            CommandString
            return
         endif
      else
         if rc <> -330 then
            sayerror UNKNOWN_MOUSE_ERROR__MSG rc
            rc = OldRc
            return
         endif
         -- rc == -330 (no local handler found), now try to find a global one.
      endif
compile endif
      if GMousePrefix <> BlankMouseHandler"." then
         rc = get_array_value( EPM_utility_array_ID, GMousePrefix||arg1, CommandString)
         if not rc then
            -- Found it.
            Rc = oldRC
            if CommandString <> '' then
               CommandString
            endif
            return
         else
            if rc <> -330 then
               sayerror UNKNOWN_MOUSE_ERROR__MSG rc
            else
               -- nothing assigned to that action
            endif
            rc = OldRc
            return
         endif
      endif
   endif

; ---------------------------------------------------------------------------
defproc register_mousehandler( IsGlobal, event, mcommand)
   universal EPM_utility_array_ID
   universal GMousePrefix
   universal LMousePrefix
   if IsGlobal then
      MousePrefix = GMousePrefix
   else
compile if LOCAL_MOUSE_SUPPORT
      if (LMousePrefix = BlankMouseHandler".") or
         (LMousePrefix = TransparentMouseHandler".") then
         -- can't assign to that mouse handler.
compile endif
         return
compile if LOCAL_MOUSE_SUPPORT
      endif
      MousePrefix = LMousePrefix
compile endif
   endif
   do_array 2, EPM_utility_array_ID, MousePrefix||event, mcommand   -- assign

; ---------------------------------------------------------------------------
compile if (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'ADVANCED')
defc MH_gotoposition2
   universal WindowHadFocus
   if WindowHadFocus then
      'MH_gotoposition'
   endif
compile endif

; ---------------------------------------------------------------------------
; Moves the cursor to the location with the last mouse click.
; This doesn't use the current mouse location.
defc MH_gotoposition
   universal stream_mode
   universal cursoreverywhere
;;
;;  Old way
;;
;;   .cursory = .mousey
;;   .cursorx = .mousex
;;
compile if TOP_OF_FILE_VALID = 'STREAM'
   ml = MouseLineColOff( MouseLine, MouseCol, MouseOff, stream_mode)
compile elseif TOP_OF_FILE_VALID
   ml = MouseLineColOff( MouseLine, MouseCol, MouseOff, 0, '', 1)
compile else
   ml = MouseLineColOff( MouseLine, MouseCol, MouseOff, 1)
compile endif
   oldsx = .scrollx;
   .lineg = MouseLine
   if stream_mode & ml > .last then
      end_line             --   go to end of last line.
   else
      .col  = MouseCol
      while MouseOff < 0 do
         left
         MouseOff = MouseOff + 1
      endwhile
      while MouseOff > 0 do
         right
         MouseOff = MouseOff - 1
      endwhile
   endif
   if not cursoreverywhere then
      if .col > length(textline(.line)) then
         end_line
      endif
   endif
   .scrollx = oldsx;

; ---------------------------------------------------------------------------
defc MH_begin_mark
   universal BeginningLineOfDrag
   universal BeginningColOfDrag
   universal CUA_marking_switch
   universal stream_mode
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mark\DragAlwaysMarks"
   DragAlwaysMarks = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   if DragAlwaysMarks = 1 then
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   endif
   if CUA_marking_switch then
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   endif
   if FileIsMarked() then
      sayerror-279  --  sayerror('Text already marked')
      return
   endif
   ml = MouseLineColOff( BeginningLineOfDrag, BeginningColOfDrag, MouseOff, 1, arg(1));
   if stream_mode & ml > .last then  -- If click below "Bottom of File" ...
      BeginningLineOfDrag = .last
      BeginningColOfDrag = length( textline(.last)) + 1
   endif
   call register_mousehandler( 1, 'ENDDRAG',    'MH_end_mark '||arg(1))  -- shifted
   call register_mousehandler( 1, 'CANCELDRAG', 'MH_cancel_mark')  -- shifted
   if upcase(arg(1)) = 'LINE' then
      .DragStyle = 2
   elseif leftstr( upcase(arg(1)), 5) = 'BLOCK' then
      .DragStyle = 1
   elseif leftstr( upcase(arg(1)), 4) = 'CHAR' then
      .DragStyle = 3
   endif
   mouse_setpointer MARK_POINTER
compile if DRAGCOLOR <> ''
   .DragColor = DRAGCOLOR
compile else
   .DragColor = .markcolor
compile endif

; ---------------------------------------------------------------------------
defc MH_end_mark
   universal BeginningLineOfDrag
   universal BeginningColOfDrag
   universal vEPM_POINTER
   universal CUA_marking_switch
   universal stream_mode

; \NEPMD\User\Mouse\Mark\Workaround
   -- Advantage   : With keyword-highlighting on it is nearly impossible
   --               to mark the last char in a line with the mouse.
   --               This workaround fixes it.
   -- Disadvantage: The command 'toggle_parse' scrolls the window
   --               from the end of mark to the cursor after processing
   --               the mark.
   --               This is an unusual behaviour and could confuse
   --               the user.
   --               Therefore: The cursor position after the mouse mark
   --               was processed can be controlled by MOUSE_MARK_SETS_CURSOR.
   universal EPM_utility_array_ID
   universal nepmd_hini

   -- Query keyword highlighting state (windowmessage returns 0 or 2)
   -- from defc qparse (commented out) in STDCTRL.E:
   saved_toggle = windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                                 5505,          -- EPM_EDIT_KW_QUERYPARSE
                                 0,
                                 0)
   saved_cursory = .cursory

   KeyPath = "\NEPMD\User\Mouse\Mark\Workaround"
   Workaround = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Workaround = 1 then
      -- Get current keyword highlighting file if highlighting is on.
      --   (Uses an array var, set before by 'toggle_parse'.)
      --   ('toggle_parse' from STDCTRL.E was altered too:
      --   Now it stores the kwfilename in an array.)
      -- Switch keyword highlighting off it is on.
      if saved_toggle <> 0 then
         getfileid fid
         -- Get keyword highlighting file for this file
         -- (The array var 'kwfile.'fid is set by defc toggle_parse in STDCTRL.E)
         rc = get_array_value( EPM_utility_array_ID, 'kwfile.'fid, kwfilename)
         'toggle_parse' 0
      endif

      --sayerror 'Toggle state before is: 'saved_toggle', kwfilename is: ' kwfilename
   endif  -- Workaround = 1

   ml = MouseLineColOff( endingline, endingcol, MouseOff, 1, arg(1));

   if Workaround = 1 then
      -- Switch keyword highlighting on if was on
      if saved_toggle <> 0 then
         -- from defc toggle_parse in STDCTRL.E:
         call windowmessage( 0,  getpminfo(EPMINFO_EDITFRAME),
                             5502,               -- EPM_EDIT_TOGGLEPARSE
                             1,
                             put_in_buffer(fid kwfilename))

         --'toggle_parse' 1 kwfilename
      endif
   endif  -- Workaround = 1

   if stream_mode & ml > .last then  -- If click below "Bottom of File" ...
      endingline = .last
      endingcol = length(textline(.last)) + 1
   endif
   if not (ml > .last & BeginningLineOfDrag = endingline & BeginningColOfDrag = endingcol) then
      unmark
      getfileid CurrentFile
      call pset_mark(BeginningLineOfDrag, endingline,
                     BeginningColOfDrag, max(endingcol,1), arg(1), CurrentFile)
      /* Copy the marked area to the clipboard in case we want to copy it */
      /* into a different editor window.                                  */
      'Copy2SharBuff'
   else
      refresh  -- Get rid of the drag-mark highlighting
   endif
   mouse_setpointer vEPM_POINTER
   if CUA_marking_switch then
      -- EVERSION >= '5.50': GPI version allows cursor to be off screen
      if (.cursorx > 0) & (.cursorx <= .windowwidth) & (.cursory > 0) & (.cursory <= .windowheight) then
         getmark firstline, lastline, firstcol, lastcol, fileid
         if marktype() <> 'LINE' then
            .col = lastcol
         endif
         if lastline <> .line then
            if lastline > .line then
               '+'(lastline - .line)
            else
               lastline - .line
            endif
         endif
      endif
      'MH_gotoposition'
   endif
;  refresh                                          ???
   call register_mousehandler( 1, 'ENDDRAG', ' ')
   call register_mousehandler( 1, 'CANCELDRAG', ' ')

   if Workaround = 1 then
compile if MOUSE_MARK_SETS_CURSOR = 1
      -- nop
compile elseif MOUSE_MARK_SETS_CURSOR = 2
      'MH_gotoposition'
compile elseif MOUSE_MARK_SETS_CURSOR = 3
-- compile if KEEP_CURSOR_ON_SCREEN
      if saved_toggle <> 0 then
         if saved_cursory < 1 or saved_cursory > .windowheight then  -- if cursor not on screen
            'MH_gotoposition'
         endif
      endif
compile endif
   endif  -- Workaround = 1

; ---------------------------------------------------------------------------
defc MH_cancel_mark
   universal vEPM_POINTER
   mouse_setpointer vEPM_POINTER
   call register_mousehandler( 1, 'ENDDRAG', ' ')
   call register_mousehandler( 1, 'CANCELDRAG', ' ')
   refresh

; ---------------------------------------------------------------------------
defc markword
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
      unmark
   endif
   call pmark_word()

; ---------------------------------------------------------------------------
defc marksentence
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
      unmark
   endif
   call mark_sentence()

; ---------------------------------------------------------------------------
defc markparagraph
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
      unmark
   endif
   call mark_paragraph()

; ---------------------------------------------------------------------------
defc extendsentence
   call mark_through_next_sentence()

; ---------------------------------------------------------------------------
defc extendparagraph
   call mark_through_next_paragraph()

; ---------------------------------------------------------------------------
defc marktoken
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
   endif
;   if marktype() <> '' then
;      sayerror -279  -- 'Text already marked'
;      return
;   endif
   if find_token( startcol, endcol) then
      getfileid fid
compile if WORD_MARK_TYPE = 'CHAR'
      call pset_mark(.line, .line, startcol, endcol, 'CHAR', fid)
compile else
      call pset_mark(.line, .line, startcol, endcol, 'BLOCK', fid)
compile endif
      'Copy2SharBuff'       /* Copy mark to shared text buffer */
   endif

; Moved defc findword to LOCATE.E

; ---------------------------------------------------------------------------
defc MH_singleclick
compile if    (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'CUA')
   universal WindowHadFocus
   if WindowHadFocus then
compile endif
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
      'MH_gotoposition'
compile if    (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'CUA')
   endif
compile endif

; ---------------------------------------------------------------------------
defc StartBrowser
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Url\Browser"
   BrowserExecutable = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   UrlStrings = 'http:// ftp:// www. ftp. https:// mailto:'
   arg1 = arg(1)
   Url = ''
   browser_rc = 1  -- default rc; 1: browser not started or no Url

   if arg1 <> '' then  -- if Url submitted as arg(1)
      Url = strip( arg1, 'B', '"')
   else  -- if no Url submitted as arg(1) then take word under pointer

      -- go to mouse position to ensure getting URL at mouse pointer and not at cursor
      call psave_pos(saved_pos)
      call psave_mark(saved_mark)
      'MH_gotoposition'

      -- get word under cursor, separated by any char of SeparatorList
      StartCol = 0
      EndCol   = 0
      SeparatorList = '"'||"'"||'(){}[]<>,! '\9;
      call find_token( StartCol, EndCol, SeparatorList, '')
      getline line

      call prestore_pos(saved_pos)
      call prestore_mark(saved_mark)

      WordFound = (StartCol <> 0 & EndCol >= StartCol)
      if WordFound then  -- if word found
         Spec = substr( line, StartCol, EndCol - StartCol + 1)

         -- strip trailing punctuation chars and '-'
         if wordpos( rightstr( Spec, 1), ', ; . ! ? -') then
            Spec = substr( Spec, 1, length(Spec) - 1)
         endif

         -- locate URL in double-clicked word
         do u = 1 to words( UrlStrings )
            UrlString = word( UrlStrings, u )
            p1 = pos( UrlString, Spec )
            if p1 > 0 then

               -- get URL
               Url = substr( Spec, p1)

               -- add default protocol identifier
               if (pos( ':', Url) = 0) then
                  if substr( Url, 1, 4) = 'ftp.' then
                     Url = 'ftp://'Url
                  else
                     Url = 'http://'Url
                  endif
               endif

               leave
            endif
         enddo
/*
         -- if no URL found, automatically process special URLs
         if Url = '' then
            filename = .filename
            p1 = lastpos( '\', filename )
            fname = substr( filename, p1 + 1 )
            if translate( leftstr( fname, 6 ) ) = 'FILES.' then
               Url = 'ftp://ftp.dante.de/tex-archive/'Spec
               p2 = lastpos( '/', Url )
               Parent = substr( Url, 1, p2 )
               Url = Parent
            endif
            if translate( leftstr( Spec, 6 ) ) = 'DANTE:' or
               translate( leftstr( Spec, 5 ) ) = 'CTAN:' then
               Url = substr( Spec, 7 )  -- <--- ToDo
               Url = strip( Url, 'L' )
               Url = strip( Url, 'L', '/' )
               Url = 'ftp://ftp.dante.de/tex-archive/'Url
               p2 = lastpos( '/', Url )
               Parent = substr( Url, 1, p2 )
               Url = Parent
            endif
         endif  -- Url = ''
*/
      endif  -- WordFound
   endif  -- arg1 <> ''

   -- if URL found until here, process it
   if Url <> '' then
      -- select default browser or use netscape as default
      if upcase(BrowserExecutable) = 'DEFAULT' then
         BrowserExecutable = queryprofile( HINI_USERPROFILE, 'WPURLDEFAULTSETTINGS', 'DefaultBrowserExe')
         NamePos           = lastpos( '\', BrowserExecutable) + 1
         ExtPos            = pos( '.', BrowserExecutable, NamePos)
         PathPos           = pos( '\', BrowserExecutable)

         BrowserName       = substr( BrowserExecutable, NamePos, ExtPos - NamePos)
         BrowserPath       = substr( BrowserExecutable, 1, NamePos - 2)

      elseif BrowserExecutable = '' then
         BrowserExecutable = 'netscape'
         BrowserName       = 'Netscape'
         BrowserPath       = ''
      endif

      -- save current directory
      if BrowserPath <> '' then
         CurrentDirectory  = directory()
         call directory( BrowserPath)
      endif

      --'os2 /min /c start /f' BrowserExecutable' "'Url'"'
      CmdPre  = 'start /f' BrowserExecutable' "'
      CmdPost = '"'
      CmdLen = length(CmdPre) + length(CmdPost)

      -- truncate URL if too long to avoid EPM crashing
      -- max length for a command executed by cmd.exe is 300
      MaxLen = 239 - CmdLen  -- why 239?
      IsTruncated = 0
      if length( Url) > MaxLen then
         Url = leftstr( Url, MaxLen )
         IsTruncated = 1
         -- try to truncate before a % char, otherwise the URL gets unvalid sometimes,
         -- but only in the last 20 chars
         lp = lastpos( '%', Url )
         if lp > MaxLen - 20 then
            Url = leftstr( Url, lp - 1 )
         endif
      endif

      if IsTruncated then
         sayerror 'Invoking' BrowserName 'with (truncated):' Url
      else
         sayerror 'Invoking' BrowserName 'with:' Url
      endif

      -- execute the command and set rc
      CmdPre''Url''CmdPost
      browser_rc = rc

      -- Teststrings here:
      -- http://www.os2.org
      -- ftp://ftp.netlabs.org,www.netlabs.org,ftp://ftp.os2.org
      -- (ftp://ftp.netlabs.org)
      -- ####ftp://ftp.netlabs.org)###)
      -- ftp://ftp.netlabs.org
      -- www.netlabs.org
      -- mailto:C.Langanke@Teamos2.de
      -- <head><title>Index of ftp://ftp.netlabs.org/</title><base href="ftp://ftp.netlabs.org/"/>
      -- http://groups.google.com/groups?num=20&hl=de&scoring=d&as_drrb=b&q=epm+group%3Ade.comp.os.*+OR+group%3Acomp.os.*&btnG=Google-Suche&as_miny=2001&as_minm=1&as_mind=1
         -- next is much too long:
      -- http://groups.google.com/groups?hl=de&lr=&ie=UTF-8&threadm=4ebg22%24jod%40watnews2.watson.ibm.com&rnum=3&prev=/groups%3Fq%3Dautosave%2Bgroup:comp.os.os2.apps%26hl%3Dde%26lr%3D%26ie%3DUTF-8%26group%3Dcomp.os.os2.apps%26selm%3D4ebg22%2524jod%2540watnews2.watson.ibm.com%26rnum%3D3

      -- restore current directory
      if Browserpath <> '' then
         call directory( CurrentDirectory)
      endif
   endif  -- Url <> ''
   rc = browser_rc

; ---------------------------------------------------------------------------
const
compile if not defined( VALIDATE_HTML_UPLOAD)
   VALIDATE_HTML_UPLOAD='http://validator.w3.org/file-upload.html'
compile endif
;compile if not defined( VALIDATE_HTML_CHECK)
;   -- file uris aren't accepted:
;   VALIDATE_HTML_CHECK='http://validator.w3.org/check?uri=file:///'
;compile endif
compile if not defined( VALIDATE_CSS_UPLOAD)
   VALIDATE_CSS_UPLOAD='http://jigsaw.w3.org/css-validator/validator-upload'
compile endif

; ---------------------------------------------------------------------------
defc ValidateHtml
   'CheckModify'
   'StartBrowser' VALIDATE_HTML_UPLOAD
;   'StartBrowser' VALIDATE_HTML_CHECK''translate( .filename, '/', '\')

; ---------------------------------------------------------------------------
defc ValidateCss
   'CheckModify'
   'StartBrowser' VALIDATE_CSS_UPLOAD

; ---------------------------------------------------------------------------
; CUA marking
defc MH_dblclick
   'MH_double' 1

; ---------------------------------------------------------------------------
; Advanced marking, with arg(1) for CUA marking
defc MH_double -- take care for doubleclicks on URLs
   universal nepmd_hini
   universal stream_mode

   fCUA = 0
   if arg(1) <> '' then
      fCUA = 1
   endif

   browser_rc = 1
   KeyPath = "\NEPMD\User\Mouse\Url\MB1_DClick"
   MB1DClickStartsBrowser = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   -- Go to mouse position to ensure pointer is not after a line
   fMouseAfterLine = 0
   call psave_pos(saved_pos)
   call psave_mark(saved_mark)
   saved_stream_mode = stream_mode
   if stream_mode then
      stream_mode = 0
   endif
   'MH_gotoposition'  -- Won't position cursor after line end in stream mode
   MouseCol = .col
   endline
   if .col <= MouseCol then
      fMouseAfterLine = 1
   endif
   --dprintf( 'EndlineCol = '.col', MouseCol = 'MouseCol', fMouseAfterLine = 'fMouseAFterLine)
   if saved_stream_mode <> stream_mode then
      stream_mode = saved_stream_mode
   endif
   call prestore_pos(saved_pos)
   call prestore_mark(saved_mark)

   -- Process special files and tokens under the cursor
   if not fMouseAfterLine then
      if upcase( subword( .filename, 1, 2)) = '.DOS DIR' |
         upcase( leftstr( .filename, 5)) = '.TREE' then
            'alt_1'
            fProcessed = 1
      else
         if MB1DClickStartsBrowser = 1 then
            'StartBrowser'
            browser_rc = rc
         endif
         -- if browser not started, process the normal definition
         if not browser_rc then
            fProcessed = 1
         endif
      endif
   endif

   -- Process the normal double click behavior
   if not fProcessed then
      unmark
      if fCUA then
         if .line then
;;          call pmark_word()  -- pmark_word doesn't include white space; the following does:
            call pbegin_word()
            mark_char
            startcol = .col
            tab_word
;           if .col <> length(textline(.line)) then .col = .col - 1; endif
            .col = .col - 1
            mark_char
            .col = startcol
         endif
      endif
      'Copy2SharBuff'       /* Copy mark to shared text buffer */
   endif

; ---------------------------------------------------------------------------
defc MH_shiftclick
   if marktype() then
      getmark markfirstline, marklastline, markfirstcol, marklastcol, markfileid
   else
      markfileid = ''
   endif
   unmark
   getfileid CurrentFile
   if CurrentFile <> markfileid then
      markfirstline = .line; markfirstcol = .col
   elseif markfirstline = .line & markfirstcol = .col then
      markfirstline = marklastline; markfirstcol = marklastcol
   endif
   call MouseLineColOff( MouseLine, MouseCol, MouseOff, 1, arg(1))
   call pset_mark( markfirstline, MouseLine, markfirstcol, MouseCol, 'CHAR', CurrentFile)
   'MH_gotoposition'
   'Copy2SharBuff'

; ---------------------------------------------------------------------------
define
   SUPPORT_DRAGDROP_FOR_BOTH = 1  -- Let's see if this works; make it easy to remove if not.

#define WM_BUTTON1UP            114 -- 0x0072
#define WM_BUTTON1DBLCLK        115 -- 0x0073
#define WM_BUTTON2UP            117 -- 0x0075
#define WM_BUTTON2DBLCLK        118 -- 0x0076
#define WM_BUTTON3UP            120 -- 0x0078
#define WM_CHORD               1040 -- 0x0410
#define WM_BUTTON1MOTIONSTART  1041 -- 0x0411
#define WM_BUTTON1MOTIONEND    1042 -- 0x0412
#define WM_BUTTON1CLICK        1043 -- 0x0413
#define WM_BUTTON2MOTIONSTART  1044 -- 0x0414
#define WM_BUTTON2MOTIONEND    1045 -- 0x0415
#define WM_BUTTON2CLICK        1046 -- 0x0416
#define WM_BUTTON3MOTIONSTART  1047 -- 0x0417

; ---------------------------------------------------------------------------
; Init pointer var to pointer const
definit
   universal vEPM_POINTER
compile if defined(MY_MOUSE_POINTER)  -- User has a preference for the default pointer
   vEPM_POINTER = MY_MOUSE_POINTER
compile else
   vEPM_POINTER = TEXT_POINTER      -- GPI version gets text pointer
compile endif
   'postme mouse_init'

; ---------------------------------------------------------------------------
defc mouse_init
   universal vEPM_POINTER
;   universal EPM_utility_array_ID, MouseStyle
   universal EPM_utility_array_ID
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mark\MouseStyle"
   MouseStyle = NepmdQueryConfigValue( nepmd_hini, KeyPath )

compile if WANT_MMEDIA
   universal mmedia_font
   mmedia_font = registerfont( 'Multimedia Icons', 0, 0)
compile endif  -- WANT_MMEDIA
compile if defined(MY_MOUSE_POINTER)  -- User has a preference for the default pointer
 compile if MY_MOUSE_POINTER <> TEXT_POINTER
   mouse_setpointer vEPM_POINTER
 compile endif
compile else
  -- EPM32: Do nothing; initialized in DEFINIT so INIT_CONFIG can override.
compile endif
   -- set initial mousesets
   SetMouseSet( 1, "BaseMouseHandlers") -- default global mouseset
compile if LOCAL_MOUSE_SUPPORT
   SetMouseSet( 0, TransparentMouseHandler)  -- default local mouseset is blank.
compile endif
compile if SUPPORT_DRAGDROP_FOR_BOTH
   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(75),        -- SV_BEGINDRAG
                            2))
;  kc_flags = itoa( substr( res, 3, 2), 10)
   msgid = itoa( substr( res, 1, 2), 10)
   if MouseStyle = 1 then but_1 = BLOCKG_MARK; c_but_1 = CHARG_MARK
                     else but_1 = CHARG_MARK;  c_but_1 = BLOCKG_MARK
   endif
   if msgid = WM_BUTTON1MOTIONSTART then
      call register_mousehandler( 1, '1 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON1UP but_1 CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON1UP c_but_1 CHARG_MARK)
   elseif msgid = WM_BUTTON2MOTIONSTART then
      call register_mousehandler( 1, '2 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON2UP 'LINE')
      call register_mousehandler( 1, '2 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON2UP 'LINE')
   elseif msgid = WM_BUTTON3MOTIONSTART then
      call register_mousehandler( 1, '3 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON3UP  c_but_1)
      call register_mousehandler( 1, '3 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON3UP  but_1)
   else
      -- Huh?
   endif
compile endif  -- SUPPORT_DRAGDROP_FOR_BOTH
compile if WANT_MMEDIA
   call register_mousehandler( 1, '1 SECONDCLK 0', 'MH_MM_dblclick')
;compile elseif WANT_SPEECH
;   call register_mousehandler( 1, '1 SECONDCLK 0', 'SPPopUp')
compile endif  -- WANT_MMEDIA
;compile if WANT_SPEECH
;   call register_mousehandler( 1, '1 SECONDCLK 2', 'SPPlay')
;compile endif
   call MH_set_Mouse(msgid)

; ---------------------------------------------------------------------------
defproc MH_set_mouse
   universal nepmd_hini
   universal CUA_marking_switch
   KeyPath = "\NEPMD\User\Mark\MouseStyle"
   MouseStyle = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   KeyPath = "\NEPMD\User\Mark\DefaultPaste"
   DefaultPaste = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DefaultPaste = 'C' then
      AlternatePaste = 'L'
   else
      AlternatePaste = 'C'
   endif
   if DefaultPaste = 'L' then    -- arg for defc paste maybe 'C', 'B' or ''
      DefaultPaste = ''
   endif
   if AlternatePaste = 'L' then  -- arg for defc paste maybe 'C', 'B' or ''
      AlternatePaste = ''
   endif

   msgid = arg(1)
   if msgid='' then
      res =  atol(dynalink32( 'PMWIN',
                              '#829',           -- Win32QuerySysValue
                               atol(1) ||       -- HWND_DESKTOP
                               atol(75),        -- SV_BEGINDRAG
                               2))
;     kc_flags = itoa(substr(res,3,2), 10)
      msgid = itoa( substr( res, 1, 2), 10)
   endif

   if CUA_marking_switch then  ----------------------------------------

      -- 1 == shift, 2 = control, 4 = alt.
      call register_mousehandler( 1, '1 CLICK 0',     'MH_singleclick')
      call register_mousehandler( 1, '1 CLICK 1',     'MH_shiftclick')
      call register_mousehandler( 1, '1 CLICK 2',     'MH_singleclick')
      call register_mousehandler( 1, '1 CLICK 3',     'MH_shiftclick')
      call register_mousehandler( 1, '1 CLICK 4',     'MH_singleclick')
      call register_mousehandler( 1, '1 CLICK 5',     'MH_shiftclick')
      call register_mousehandler( 1, '1 CLICK 6',     'MH_singleclick')
      call register_mousehandler( 1, '1 CLICK 7',     'MH_shiftclick')
compile if not WANT_MMEDIA -- and not WANT_SPEECH
      call register_mousehandler( 1, '1 SECONDCLK 0', 'MH_dblclick')
compile endif
;compile if not WANT_SPEECH
      call register_mousehandler( 1, '1 SECONDCLK 2', 'MH_dblclick')
;compile endif
      call register_mousehandler( 1, '1 SECONDCLK 4', 'MH_dblclick')
      call register_mousehandler( 1, '1 SECONDCLK 6', 'MH_dblclick')
      if msgid <> WM_BUTTON1MOTIONSTART then
         call register_mousehandler( 1, '1 BEGINDRAG 0', 'MH_begin_mark' CHARG_MARK)
         call register_mousehandler( 1, '1 BEGINDRAG 2', 'MH_begin_mark' CHARG_MARK)
      endif -- msgid <> WM_BUTTON1MOTIONSTART
      call register_mousehandler( 1, '1 BEGINDRAG 1', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 3', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 4', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 5', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 6', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler( 1, '1 BEGINDRAG 7', 'MH_begin_mark' CHARG_MARK)

      if msgid <> WM_BUTTON2MOTIONSTART then
         call register_mousehandler( 1, '2 BEGINDRAG 0', '')  -- Delete the defs
         call register_mousehandler( 1, '2 BEGINDRAG 2', '')
      endif
      if msgid <> WM_BUTTON3MOTIONSTART then
         call register_mousehandler( 1, '3 BEGINDRAG 0', '')  -- Delete the defs
      endif
         call register_mousehandler( 1, '2 SECONDCLK 0', '')
         call register_mousehandler( 1, '2 SECONDCLK 2', '')
         call register_mousehandler( 1, '2 SECONDCLK 1', '')
   else  -- CUA_marking_switch ----------------------------------------
      call register_mousehandler( 1, '1 CLICK 6',     '')
;compile if not WANT_SPEECH
         call register_mousehandler( 1, '1 SECONDCLK 2', '')
;compile endif
      call register_mousehandler( 1, '1 SECONDCLK 4', '')
      call register_mousehandler( 1, '1 SECONDCLK 6', '')
      call register_mousehandler( 1, '1 BEGINDRAG 1', '')
      call register_mousehandler( 1, '1 BEGINDRAG 3', '')
      call register_mousehandler( 1, '1 BEGINDRAG 4', '')
      call register_mousehandler( 1, '1 BEGINDRAG 5', '')
      call register_mousehandler( 1, '1 BEGINDRAG 6', '')
      call register_mousehandler( 1, '1 BEGINDRAG 7', '')

compile if    (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'ADVANCED')
      call register_mousehandler( 1, '1 CLICK 0',     'MH_gotoposition2')
compile else
      call register_mousehandler( 1, '1 CLICK 0',     'MH_gotoposition')
compile endif
      call register_mousehandler( 1, '1 CLICK 1',     'MH_shiftclick')
      if MouseStyle = 1 then but_1 = BLOCKG_MARK; c_but_1 = CHARG_MARK
                        else but_1 = CHARG_MARK;  c_but_1 = BLOCKG_MARK
      endif
      if msgid <> WM_BUTTON1MOTIONSTART then
         call register_mousehandler( 1, '1 BEGINDRAG 0', 'MH_begin_mark 'but_1)
         call register_mousehandler( 1, '1 BEGINDRAG 2', 'MH_begin_mark 'c_but_1)
      endif
      if msgid <> WM_BUTTON2MOTIONSTART then
         call register_mousehandler( 1, '2 BEGINDRAG 0', 'MH_begin_mark LINE')
      endif
      call register_mousehandler( 1, '1 CLICK 2',     'ifinmark copy2clip')                        -- Ctrl+MB1click
      call register_mousehandler( 1, '1 CLICK 3',     'ifinmark cut')                              -- Ctrl+Sh+NB1click
      call register_mousehandler( 1, '1 CLICK 4',     'mc /MH_gotoposition/paste' DefaultPaste)    -- Alt+MB1click
      call register_mousehandler( 1, '1 CLICK 5',     'mc /MH_gotoposition/paste' AlternatePaste)  -- Alt+Sh+MB1click
      if msgid <> WM_BUTTON3MOTIONSTART then
         call register_mousehandler( 1, '3 BEGINDRAG 0', 'MH_begin_mark 'c_but_1)
      endif
compile if not WANT_MMEDIA -- and not WANT_SPEECH
      call register_mousehandler( 1, '1 SECONDCLK 0', 'MH_double')
compile endif
      call register_mousehandler( 1, '2 SECONDCLK 0', 'markword 1')
      call register_mousehandler( 1, '2 SECONDCLK 2', 'marktoken 1')     -- Ctrl
      call register_mousehandler( 1, '2 SECONDCLK 1', 'findword 1')      -- Shift
      call register_mousehandler( 1, '2 SECONDCLK 4', 'marksentence 1')  -- Alt
      call register_mousehandler( 1, '2 SECONDCLK 6', 'markparagraph 1') -- Ctrl+Alt
      call register_mousehandler( 1, '2 SECONDCLK 5', 'extendsentence')  -- Alt+Shift
      call register_mousehandler( 1, '2 SECONDCLK 7', 'extendparagraph') -- Ctrl+Alt+shift
      call register_mousehandler( 1, '1 SECONDCLK 2', 'kwhelp')

   endif  --  ---------------------------------------

   call register_mousehandler( 1, 'CHORD',     'Ring_More')

/*
; ################################################################################################ Test for Ctrl+MB3
   call register_mousehandler( 1, '3 CLICK 2', 'sayerror MB3 click')
   call register_mousehandler( 1, '3 SECONDCLK 2', 'sayerror MB3 double click')
   call register_mousehandler( 1, '3 BEGINDRAG 2', 'sayerror MB3 begin drag')
; ################################################################################################ Test for Ctrl+MB3
*/

   -- NOP out the default action associated with user's context button
   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(79),        -- SV_CONTEXTMENU
                            2))
   kc_flags = itoa( substr( res, 3, 2), 10)
   msgid = itoa( substr( res, 1, 2), 10)
   if msgid = WM_CHORD then
      event = 'CHORD'
      call register_mousehandler( 1, 'CHORD', '')
   else
      if msgid = WM_BUTTON1DBLCLK or msgid = WM_BUTTON2DBLCLK then
         event = 'SECONDCLK'
      elseif msgid = WM_BUTTON1CLICK or msgid = WM_BUTTON2CLICK then
         event = 'CLICK'
      else
         return  -- Unexpected!
      endif
      if msgid = WM_BUTTON1CLICK or msgid = WM_BUTTON1DBLCLK then
         button = 1
      else  -- must be WM_BUTTON2CLICK or WM_BUTTON2DBLCLK
         button = 2
      endif
      call register_mousehandler( 1, button event (kc_flags/8), '')
   endif

   call register_mousehandler( 1, 'CONTEXTMENU',   'MH_popup')

; ---------------------------------------------------------------------------
defc MH_begin_drag_2  -- Determine if a click is within the selected area
   universal CUA_marking_switch
   parse arg copy_flag buttonup_msg advanced_marking_marktype CUA_marking_marktype
   if mouse_in_mark() then
      call WindowMessage( 0,  getpminfo(EPMINFO_EDITCLIENT),
                          5434,               -- EPM_DRAGDROP_DIRECTTEXTMANIP
                          copy_flag,
                          buttonup_msg)
      return
   endif
   -- EPM32 doesn't give focus on a MB2 drag, in case it's direct text manipulation.
   -- Here, we know it's not, so let's activate the window:
   if buttonup_msg = WM_BUTTON2UP then
      call dynalink32( 'PMWIN',
                       '#851',                -- ordinal for Win32SetActiveWindow
                       atol(1)     ||         -- HWND_DESKTOP
                       gethwndc(EPMINFO_PARENTCLIENT), 2)
   endif
   if CUA_marking_switch then  -- If 'SWITCH', we do advanced mark action if CUA switch is off
      if CUA_marking_marktype <> '' then   -- This can be blank
         'MH_begin_mark' CUA_marking_marktype
      endif
   else       -- else, not CUA marking switch - do the standard EPM ('advanced marking') action
      'MH_begin_mark' advanced_marking_marktype
   endif

; ---------------------------------------------------------------------------
defproc mouse_in_mark()
   -- First we query the position of the mouse
   call MouseLineColOff( MouseLine, MouseCol, MouseOff, 0)
   -- Now determine if the mouse is in the selected text area.
   mt = leftstr( marktype(), 1)
   if mt then
      getfileid curfileid
      getmark markfirstline, marklastline, markfirstcol, marklastcol, markfileid
      if (markfileid == curfileid) and
         (MouseLine >= markfirstline) and (MouseLine <= marklastline) then

         -- assert:  at this point the only case where the text is outside
         --          the selected area is on a single line char mark and a
         --          block mark.  Any place else is a valid selection
         if not ((mt == 'C' & (markfirstline = MouseLine & MouseCol < markfirstcol) or
                              (marklastline = MouseLine & MouseCol > marklastcol)) or
                 (mt == 'B' & (MouseCol < markfirstcol or MouseCol > marklastcol)) ) then
            return 1
         endif
      endif
   endif

; ---------------------------------------------------------------------------
defc ifinmark =
   if mouse_in_mark() then
      ''arg(1)
   endif

; ---------------------------------------------------------------------------
compile if WANT_MMEDIA
defc MH_MM_dblclick
   universal mmedia_font
   universal CUA_marking_switch
   -- First we query the position of the mouse
   call MouseLineColOff( MouseLine, MouseCol, MouseOff, 0, '', 1)
   class = 0; offst = -2
   query_attribute class, val, IsPush, offst, MouseCol, MouseLine
   if class=32 /* | (class=16 & val=mmedia_font & IsPush) */ then
;;    if class=16 then  -- If we got the font class, go for the mmedia class.
;;       offst = -2
;;       query_attribute class, val, IsPush, offst, MouseCol, MouseLine
;;    endif
      .col = MouseCol
      ch = asc(substr( textline(MouseLine), MouseCol, 1))
;;    sayerror 'selected MMedia type' ch 'with value' val
      circleit 1, MouseLine, MouseCol - 1, MouseCol + 1, 16777220
      -- Send a message to the owner of the EMLE: OBJEPM_LINKOBJ = 0x15A4 = 5540
      call windowmessage( 0, getpminfo(EPMINFO_PARENTFRAME), 5540, val, ch)
;compile if WANT_SPEECH
;   else  -- not mmedia, so do the standard action
;      'SPPopUp'  -- Speech support always does this
;compile else
   elseif CUA_marking_switch then
      'MH_dblclick'  -- This is the CUA-marking-mode action
   else  -- class=32
      'MH_Double'    -- This is the normal EPM marking mode action
;compile endif  -- WANT_SPEECH
   endif  -- class=32
compile endif

; Moved popup menu to POPUP.E

; ---------------------------------------------------------------------------
; The StatWndMouseCmd and MsgWndMouseCmd are invoked with the following argument
; when the status or message windows receive the following event:
; '1 SECONDCLK 0' - Double-click MB1 (in any shift combination).
; 'CONTEXTMENU'   - The context menu action (by default, single-click MB2) is executed .
; 'CHORD'         - Both mouse buttons are pressed together.
defc StatWndMouseCmd
   -- 1 CLICK 0 is not defined.
   --call NepmdPmPrintf('StatWndMouseCmd: arg(1) = 'arg(1))
   if arg(1) = '1 SECONDCLK 0' then
      --'versioncheck'
      'ConfigInfoLine STATUS'
   elseif arg(1) = 'CONTEXTMENU' then
      'configdlg'
   endif

; ---------------------------------------------------------------------------
defc MsgWndMouseCmd
   -- 1 CLICK 0 is not defined.
   --call NepmdPmPrintf('MsgWndMouseCmd: arg(1) = 'arg(1))
   if arg(1) = '1 SECONDCLK 0' then
      'messagebox'
   elseif arg(1) = 'CONTEXTMENU' then
      'tagscan'
   endif

; ---------------------------------------------------------------------------
defc SetMousePointer
   universal vEPM_POINTER
   if verify( arg(1), '0123456789') then  -- contained a non-numeric character
      sayerror INVALID_NUMBER__MSG
   else
      vEPM_POINTER = arg(1)
      mouse_setpointer vEPM_POINTER
   endif

