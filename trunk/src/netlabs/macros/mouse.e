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
   include NLS_LANGUAGE'.e'
compile endif  -- not defined(SMALL)

const
compile if not defined(TOP_OF_FILE_VALID)
   TOP_OF_FILE_VALID = 1       -- Can be '0', '1', or 'STREAM' (dependant on STREAM_MODE)
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

; ---------------------------------------------------------------------------
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

; The following 2 procs are not used:
; ---------------------------------------------------------------------------
; .lineg and .cursoryg set the line without scrolling.
defproc prestore_pos2( save_pos)
   parse value save_pos with svline svcol svsx svsy
   .lineg    = min( svline, .last)  -- set .line
   .col      = svcol
   .scrollx  = svsx
   .cursoryg = svsy

; ---------------------------------------------------------------------------
defproc psave_pos2( var save_pos)
   save_pos = .line .col .scrollx .cursoryg

; ---------------------------------------------------------------------------
; Returns cursor pos. for corresponding mouse pointer pos.
defproc MouseLineColOff( var MouseLine, var MouseCol, var MouseOff, minline)
                        -- MIN = 0 for positioning, 1 for marking.
   xxx = max( .mousex - 0, 0); mx = xxx
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
   -- edit window. .cursory is = .windowheight on the bottommost visible line
   -- of the edit window. It can also get < 0 and > .windowheight. That means
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
; Add or redefine an entry to the mouse array vars.
;
; Syntax:  DefMouse( MouseString, Cmd)
;
;          MouseString prefixes are separated by '_', '+' or '-'. The following
;          prefixes are defined:
;          'c_' Ctrl
;          's_' Shift
;          'a_' Alt
;          In this definition the order of the prefixes doesn't matter, while
;          on execution, the MouseString prefixes are used in the above order.
;          Cmd must be an E command string, not E code.
defproc DefMouse( MouseString, Cmd)

   Flags = 0
   String = upcase( MouseString)
   call GetAFFlags( Flags, String, MouseString)  -- normalize MouseString
   --dprintf( 'MouseString = 'MouseString)

   -- Remove previous mouse def in array vars, if any
   PrevCmd = GetAVar('mousedef.'MouseString)
   DelAVar( 'mousecmd.'PrevCmd, MouseString)

   -- Save mouse def in array to allow for searching for MouseString and Cmd
   SetAVar( 'mousedef.'MouseString, Cmd)
   AddAVar( 'mousecmd.'Cmd, MouseString)  -- may have multiple mouse defs

   return

; Define a cmd to call the proc in profile.erx or for testing
defc DefMouse
   parse arg MouseString Cmd
   DefMouse( MouseString, Cmd)

; ---------------------------------------------------------------------------
defproc UnDefMouse( MouseString)
   Flags = 0
   String = upcase( MouseString)
   call GetAFFlags( Flags, String, MouseString)  -- normalize MouseString

   -- Remove previous mouse def in array vars, if any
   PrevCmd = GetAVar( 'mousedef.'MouseString)
   --DropAVar( 'mousedef.'MouseString)  -- Works, but might be slower than setting it to ''
   SetAVar( 'mousedef.'MouseString, '')
   DelAVar( 'mousecmd.'PrevCmd, MouseString)  -- may have multiple mouse defs

   return

; Define a cmd to call the proc in profile.erx or for testing
defc UnDefMouse
   parse arg MouseString
   UnDefMouse( MouseString)

; ---------------------------------------------------------------------------
; Added for compatibility with other add-on packages which redefine mouse
; actions. All mouse defs are now global.
defproc register_mousehandler( fGlobal, Event, Cmd)
   DefMouse( MouseEvent2MouseString( Event), Cmd)
   return

; ---------------------------------------------------------------------------
defproc MouseEvent2MouseString
   MouseString = ''
   parse arg Button Action State
      if Action = '' then
      Action = Button
      Button = ''
   endif

   fCtrl = ((State bitand 2) > 0)
   fAlt  = ((State bitand 4) > 0)
   fSh   = ((State bitand 1) > 0)
   if fCtrl then
      MouseString = MouseString'c_'
   endif
   if fAlt then
      MouseString = MouseString'a_'
   endif
   if fSh then
      MouseString = MouseString's_'
   endif

   if Button = 1 then
      MouseString = MouseString'mb1_'
   elseif Button = 2 then
      MouseString = MouseString'mb2_'
   elseif Button = 3 then
      MouseString = MouseString'mb3_'
   endif

   if Action = 'SECONDCLK' then
      MouseString = MouseString'doubleclick'
   else
      MouseString = MouseString''lowcase( Action)
   endif

   return MouseString

; ---------------------------------------------------------------------------
; User commands for adding/modifying mouse defs via PROFILE.ERX.
; A blank Cmd resets the MouseString definition.
defc AddUserMouseDef
   universal UserMouseDefNum
   parse arg MouseString Cmd
   if MouseString <> '' then
      UserMouseDefNum = UserMouseDefNum + 1
      SetAVar( 'usermousedef.'UserMouseDefNum, MouseString Cmd)
   endif

; ---------------------------------------------------------------------------
; This is executed at the end of MH_set_mouse.
defc ExecUserMouseDef
   universal UserMouseDefNum
   do ThisNum = 1 to UserMouseDefNum
      NextDef = GetAVar( 'usermousedef.'ThisNum)
      parse value NextDef with MouseString Cmd
      -- A blank Cmd resets the MouseString definition.
      DefMouse( MouseString, Cmd)
   enddo

; ---------------------------------------------------------------------------
; This should be executed before adding mouse defs in PROFILE.ERX. That
; allows running PROFILE.ERX multiple times without restart.
defc ResetUserMouseDef
   universal UserMouseDefNum
   do ThisNum = 1 to UserMouseDefNum
      SetAVar( 'usermousedef.'ThisNum, '')
   enddo
   UserMouseDefNum = 0

; ---------------------------------------------------------------------------
/*
  The following mouse callback commands are defined internally:

      ProcessMouse
      StatWndMouseCmd
      MsgWndMouseCmd
      ProcessMouseDropping

   ---

   Syntax: ProcessMouse WindowHadFocus MouseEvent

   The ProcessMouse parameter MouseEvent has the following format:

      button action state

   The button refers to the mouse button (either 1 or 2).

   The action must be one of the following:

      BEGINDRAG  activated at the beginning of the drag
      CLICK      activated if a button is single clicked
      SECONDCLK  activated if a button is double clicked

   These actions must be capitalized and have exactly one space between the
   button and the state numbers. The state should be the sum of the following:

      0 = no states active
      1 = shift key active
      2 = control key active
      4 = alternate key active

   MouseEvent can also be of the following format:

      action

   where action must be one of the following:

      ENDDRAG     activated at the end of a drag
      CANCELDRAG  activated if a drag is canceled
      CHORD       activated if both mouse button 1 and mouse button 2 are
                  clicked at the same time.
      CONTEXTMENU activated if the defined context menu (pop-up menu) mouse
                  action is performed. The default is that single-clicking
                  mouse button 2 generates this message, but it can be
                  configured in the OS/2 System Settings.

   These actions must be capitalized and unpadded by spaces.

   ---

   Note:

      o  ProcessMouse is called on releasing a mouse button, not on
         pressing it. The call is bypassed if Esc was pressed before.

   Bugs for ProcessMouse callbacks:

      o  CONTEXTMENU is issued after a CLICK (usually MB2 CLICK, depends on
                     mouse system config)
      o  BEGINDRAG   is issued on begining a text drag or a mouse marking

      o  ENDDRAG     is issued on canceled or uncanceled text drag or
                     uncanceled mouse marking
      o  CANCELDRAG  is issued on canceling mouse marking with the Esc key,
                     not on canceling text drag

      Examples:

         User actions              Mouse events, submitted
                                   to ProcessMouse
         ----------------------    -----------------------

         MB 1 click             -> 1 CLICK 0

         MB 1 doubleclick       -> 1 SECONDCLK 0

         MB 2 click             -> 2 CLICK 0
                                -> CONTEXTMENU

         MB 1 and MB 2 click    -> CHORD

         begin a mouse marking  -> 1 BEGINDRAG 0
         with MB 1

         end a mouse marking    -> ENDDRAG

         cancel a mouse marking -> CANCELDRAG
         with Esc

         begin a text drag      -> 2 BEGINDRAG 0
         with MB 2

         end a text drag        -> ENDDRAG

         cancel a text drag     -> ENDDRAG
         with Esc

      Workarounds:

         o  To make CONTEXTMENU work as expected, the def for the mouse event
            issued before must be undefined. That mouse def is determined
            from a Win32QuerySysValue call with parameter SV_CONTEXTMENU.

         o  To make ENDDRAG work for both mouse marking and text drag, that
            action must be determined at the corresponding BEGINDRAG event.
            Therefore the system mouse config is queried by a
            Win32QuerySysValue call with parameter SV_BEGINDRAG and it is
            checked if the mouse event happened in a marked area.
*/
; ---------------------------------------------------------------------------
; ProcessMouse is called internally at every mouse action.
; It executes the Cmd that is assigned to MouseString.
; curkey and prevkey are not set, because it makes no sense to have key
; recording working with mouse actions other than menu clicks.
defc ProcessMouse
   universal WindowHadFocus

   parse arg WindowHadFocus MouseEvent
   MouseString = MouseEvent2MouseString( MouseEvent)

   if not WindowHadFocus then
      'ResetDateTimeModified'
      'RefreshInfoLine MODIFIED'
   endif

   Cmd = GetAVar( 'mousedef.'MouseString)
   --dprintf( 'ProcessMouse: MouseEvent = 'MouseEvent', MouseString = 'MouseString', Cmd = 'Cmd)

   -- Execute Cmd
   Cmd

; ---------------------------------------------------------------------------
; StatWndMouseCmd and MsgWndMouseCmd are called internally with the
; following argument when the status or message windows receive the
; following event:
; '1 SECONDCLK 0' - double-click MB1 (in any shift combination)
; 'CONTEXTMENU'   - the context menu action (by default, single-click MB2)
; 'CHORD'         - both mouse buttons are pressed together
; Other events are not passed to these commands.

; ---------------------------------------------------------------------------
defc StatWndMouseCmd
   --call NepmdPmPrintf('StatWndMouseCmd: arg(1) = 'arg(1))
   MouseEvent = arg(1)
   MouseString = MouseEvent2MouseString( MouseEvent)
   if MouseEvent = '1 SECONDCLK 0' then
      Cmd = GetAVar( 'mousedef.mb1_doubleclick_statwnd')
   elseif MouseEvent = 'CONTEXTMENU' then
      Cmd = GetAVar( 'mousedef.contextmenu_statwnd')
   elseif MouseEvent = 'CHORD' then
      Cmd = GetAVar( 'mousedef.chord_statwnd')
   endif
   -- Execute Cmd
   Cmd

; ---------------------------------------------------------------------------
defc MsgWndMouseCmd
   --call NepmdPmPrintf('StatWndMouseCmd: arg(1) = 'arg(1))
   MouseEvent = arg(1)
   MouseString = MouseEvent2MouseString( MouseEvent)
   if MouseEvent = '1 SECONDCLK 0' then
      Cmd = GetAVar( 'mousedef.mb1_doubleclick_msgwnd')
   elseif MouseEvent = 'CONTEXTMENU' then
      Cmd = GetAVar( 'mousedef.contextmenu_msgwnd')
   elseif MouseEvent = 'CHORD' then
      Cmd = GetAVar( 'mousedef.chord_msgwnd')
   endif
   -- Execute Cmd
   Cmd

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
      end_line  -- go to end of last line
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
   universal MouseMarkingStarted
   universal CUA_marking_switch
   universal stream_mode
   universal nepmd_hini

   parse arg MType  -- mouse mark type, depending on MouseStyle

   KeyPath = "\NEPMD\User\Mark\DragAlwaysMarks"
   DragAlwaysMarks = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   if DragAlwaysMarks = 1 then
      unmark
      'ClearSharBuff' -- remove content in EPM shared text buffer
   endif
   if CUA_marking_switch then
      unmark
      'ClearSharBuff' -- remove content in EPM shared text buffer
   endif
   if FileIsMarked() then
      sayerror-279  --  sayerror('Text already marked')
      return
   endif

   ml = MouseLineColOff( BeginningLineOfDrag, BeginningColOfDrag, MouseOff, 1, MType);
   if stream_mode & ml > .last then  -- if click below "Bottom of File"
      BeginningLineOfDrag = .last
      BeginningColOfDrag = length( textline(.last)) + 1
   endif

   if upcase( MType) = 'LINE' then
      .DragStyle = 2
   elseif leftstr( upcase( MType), 5) = 'BLOCK' then
      .DragStyle = 1
   elseif leftstr( upcase( MType), 4) = 'CHAR' then
      .DragStyle = 3
   endif
   mouse_setpointer MARK_POINTER
compile if DRAGCOLOR <> ''
   .DragColor = DRAGCOLOR
compile else
   .DragColor = .markcolor
compile endif

   -- Set var to mouse marking type to let MH_begin_mark and MH_cancel_mark
   -- know that MH_begin_mark was processed before. This is required, because
   -- mouse events were not correctly passed to ProcessMouse to distinguish
   -- mouse mark from text drag.
   MouseMarkingStarted = MType

; ---------------------------------------------------------------------------
defc MH_end_mark
   universal BeginningLineOfDrag
   universal BeginningColOfDrag
   universal MouseMarkingStarted
   universal vEPM_POINTER
   universal CUA_marking_switch
   universal stream_mode
   universal nepmd_hini

   -- Don't process this for ending a text drag
   if MouseMarkingStarted <> '' then

      MType = MouseMarkingStarted  -- mouse mark type, depending on MouseStyle
      --dprintf( 'MType = 'MType)

      -- \NEPMD\User\Mouse\Mark\Workaround
      -- Advantage   : With keyword highlighting on it is nearly impossible
      --               to mark the last char in a line with the mouse.
      --               This workaround fixes it.
      -- Disadvantage: The command 'toggle_parse' scrolls the window
      --               from the end of mark to the cursor after processing
      --               the mark.
      --               This is an unusual behaviour and could confuse
      --               the user.
      --               Therefore: The cursor position after the mouse mark
      --               was processed can be controlled by MOUSE_MARK_SETS_CURSOR.

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
            kwfilename = GetAVar( 'kwfile.'fid)
            'toggle_parse' 0
         endif

         --dprintf( 'Toggle state before is: 'saved_toggle', kwfilename is: ' kwfilename)
      endif  -- Workaround = 1

      ml = MouseLineColOff( endingline, endingcol, MouseOff, 1, MType);

      if Workaround = 1 then
         -- Switch keyword highlighting on if it was on before
         if saved_toggle <> 0 then
            -- from defc toggle_parse in STDCTRL.E:
            call windowmessage( 0,  getpminfo( EPMINFO_EDITFRAME),
                                5502,               -- EPM_EDIT_TOGGLEPARSE
                                1,
                                put_in_buffer( fid kwfilename))

            --'toggle_parse' 1 kwfilename
         endif
      endif  -- Workaround = 1

      if stream_mode & ml > .last then  -- if click below "Bottom of File"
         endingline = .last
         endingcol = length(textline(.last)) + 1
      endif
      if not (ml > .last & BeginningLineOfDrag = endingline & BeginningColOfDrag = endingcol) then
         unmark
         getfileid CurrentFile
         call pset_mark( BeginningLineOfDrag, endingline,
                         BeginningColOfDrag, max( endingcol, 1), MType, CurrentFile)
         -- Copy the marked area to the clipboard in case we want to copy it
         -- into a different editor window
         'Copy2SharBuff'
      else
         refresh  -- get rid of the drag-mark highlighting
      endif

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

      if Workaround = 1 then
compile if MOUSE_MARK_SETS_CURSOR = 1
         -- nop
compile elseif MOUSE_MARK_SETS_CURSOR = 2
         'MH_gotoposition'
compile elseif MOUSE_MARK_SETS_CURSOR = 3
         if saved_toggle <> 0 then
            if saved_cursory < 1 or saved_cursory > .windowheight then  -- if cursor not on screen
               'MH_gotoposition'
            endif
         endif
compile endif
      endif  -- Workaround = 1

   endif  -- MouseMarkingStarted <> ''

   -- Reset var to ignore the part above for text drag
   MouseMarkingStarted = ''
   mouse_setpointer vEPM_POINTER

; ---------------------------------------------------------------------------
defc MH_cancel_mark
   universal MouseMarkingStarted
   universal vEPM_POINTER

   -- Reset var to ignore the first part of MH_end_drag for text drag
   MouseMarkingStarted = ''
   mouse_setpointer vEPM_POINTER

   refresh

; ---------------------------------------------------------------------------
defc MH_singleclick
   universal CUA_marking_switch
   universal WindowHadFocus

   fIgnore = 0
   if WindowHadFocus = 0 then
      if CUA_marking_switch then
         fIgnore = (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'CUA')
      else
         fIgnore = (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'ADVANCED')
      endif
   endif

   if fIgnore = 0 then
      if CUA_marking_switch then
         unmark
         'ClearSharBuff'  -- remove content in EPM shared text buffer
         'MH_gotoposition'
      else
         'MH_gotoposition'
      endif
   endif

; ---------------------------------------------------------------------------
; Take care for doubleclicks on URLs and on filenames in file listings.
defc MH_doubleclick
   universal nepmd_hini
   universal stream_mode
   universal CUA_marking_switch

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
   fProcessed = 0
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
      if CUA_marking_switch then
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
      'Copy2SharBuff'  -- copy mark to shared text buffer
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
defc ifinmark
   if mouse_in_mark() then
      ''arg(1)
   endif

; ---------------------------------------------------------------------------
defc MH_begin_drag  -- Determine if a click is within the selected area
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
; ProcessMouseDropping is called internally at the end of text drag.
defc ProcessMouseDropping
   call psave_pos(savepos)
   'MH_gotoposition'
   'GetSharBuff'     -- See clipbrd.e for details
   call prestore_pos(savepos)

; ---------------------------------------------------------------------------
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
; http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&selm=5957rh%241buc%242%40news-s01.ca.us.ibm.net&rnum=9
; https://groups.google.com/forum/?hl=en#!msg/comp.os.os2.apps/fuIftbHwocs/qEIptPJIaCoJ

; ---------------------------------------------------------------------------
definit
   universal vEPM_POINTER
   universal UserMouseDefNum

   UserMouseDefNum = 0  -- reset counter

   vEPM_POINTER = TEXT_POINTER
   mouse_setpointer vEPM_POINTER

   'postme mouse_init'

; ---------------------------------------------------------------------------
; Also called in NEWMENU.E.
defc mouse_init
   call MH_set_Mouse()

; ---------------------------------------------------------------------------
; MH_set_mouse defines all mouse configurations. To change it, either
; -  change this file (recompile doesn't require a restart anymore) or
; -  use the following commands in PROFILE.ERX to override some defs.
;
;  Example for PROFILE.ERX:
;     'ResetUserMouseDef'
;     'AddUserMouseDef contextmenu       sayerror Context menu event'
;     'AddUserMouseDef c_mb1_doubleclick sayerror Ctrl+MB1 doubleclick event'
;     'postme mouse_init'  /* this avoids a restart and can be removed after testing */
;
defproc MH_set_mouse
   universal nepmd_hini
   universal CUA_marking_switch

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

   KeyPath = "\NEPMD\User\Mark\MouseStyle"
   MouseStyle = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if MouseStyle = 1 then but_1 = 'BLOCKG'; c_but_1 = 'CHARG'
                     else but_1 = 'CHARG';  c_but_1 = 'BLOCKG'
   endif

   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(75),        -- SV_BEGINDRAG
                            2))
   BeginDragMsgId = itoa( substr( res, 1, 2), 10)
   --kc_flags = itoa( substr( res, 3, 2), 10)

   -- CUA and advanced marking: MB 1 + MB 2 single click
   DefMouse( 'chord', 'Ring_More')

   -- CUA and advanced marking: context menu, default: MB 2 single click
   DefMouse( 'contextmenu', 'MH_popup')
   -- ProcessMouse is called for MB 2 single click with '2 CLICK 0', followed by
   -- 'CONTEXTMENU'.
   -- If MB 1 is defined as context menu button, then ProcessMouse is called with
   -- '1 CLICK 0', followed by 'CONTEXTMENU'.
   -- Therefore undefine the default action associated with user's context button.
   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(79),        -- SV_CONTEXTMENU
                            2))
   ContextMenuMsgId = itoa( substr( res, 1, 2), 10)
   --kc_flags       = itoa( substr( res, 3, 2), 10)
   ContextMenuFlags = itoa( substr( res, 3, 2), 10) / 8  -- 1 = Sh, 2 = Ctrl, 4 = Alt
   --dprintf( 'msgid = 'msgid', ContextMenuFlags = 'ContextMenuFlags)
   if ContextMenuMsgId = WM_CHORD then
      event = 'CHORD'
      UndefMouse( MouseEvent2MouseString( event))
   else
      if ContextMenuMsgId = WM_BUTTON1DBLCLK or ContextMenuMsgId = WM_BUTTON2DBLCLK then
         event = 'SECONDCLK'
      elseif ContextMenuMsgId = WM_BUTTON1CLICK or ContextMenuMsgId = WM_BUTTON2CLICK then
         event = 'CLICK'
      endif
      if ContextMenuMsgId = WM_BUTTON1CLICK or ContextMenuMsgId = WM_BUTTON1DBLCLK then
         button = 1
      else  -- must be WM_BUTTON2CLICK or WM_BUTTON2DBLCLK
         button = 2
      endif
      UndefMouse( MouseEvent2MouseString( button event ContextMenuFlags))
   endif

   -- CUA and advanced marking: enddrag and canceldrag events
   DefMouse( 'enddrag',    'MH_end_mark')     -- shifted
   DefMouse( 'canceldrag', 'MH_cancel_mark')  -- shifted

   -- CUA and advanced marking: status bar and message line window events
   -- Other events don't work.
   DefMouse( 'mb1_doubleclick_statwnd', 'ConfigInfoLine STATUS')
   DefMouse( 'contextmenu_statwnd',     'ConfigDlg')
   DefMouse( 'chord_statwnd',           '')
   DefMouse( 'mb1_doubleclick_msgwnd',  'MessageBox')
   DefMouse( 'contextmenu_msgwnd',      'TagScan')
   DefMouse( 'chord_msgwnd',            '')

   if CUA_marking_switch then

      -- CUA marking: MB 1 single click
      DefMouse( 'mb1_click',             'MH_singleclick')
      DefMouse( 'c_mb1_click',           'MH_singleclick')
      DefMouse( 'a_mb1_click',           'MH_singleclick')
      DefMouse( 's_mb1_click',           'MH_shiftclick')
      DefMouse( 'c_s_mb1_click',         'MH_shiftclick')
      DefMouse( 'c_a_s_mb1_click',       'MH_shiftclick')

      -- CUA marking: MB 1 double click
      -- Note: MB 1 double click should be undefined if MB 1 single click is
      --       already defined with the same modifier keys.
      --       Exception: when the defined single click action doesn't
      --       interfere with it.
      DefMouse( 'mb1_doubleclick',       'MH_doubleclick')
      DefMouse( 'c_mb1_doubleclick',     'kwhelp')
      DefMouse( 'a_mb1_doubleclick',     'MH_doubleclick')
      DefMouse( 'c_a_mb1_doubleclick',   'MH_doubleclick')

      -- CUA marking: MB 2 double click
      -- Note: MB 2 double click (without modifier key) is undefined
      --       if MB 2 is configured as context menu button
      -- Note: MB 2 double click should be undefined if MB 2 single click is
      --       already defined with the same modifier keys.
      --       Exception: when the defined single click action doesn't
      --       interfere with it.
      UnDefMouse( 'mb2_doubleclick')
      UnDefMouse( 'c_mb2_doubleclick')
      UnDefMouse( 's_mb2_doubleclick')
      DefMouse( 'a_mb2_doubleclick',     'marksentence 1')
      DefMouse( 'c_a_mb2_doubleclick',   'markparagraph 1')
      DefMouse( 'a_s_mb2_doubleclick',   'extendsentence')
      DefMouse( 'c_a_s_mb2_doubleclick', 'extendparagraph')

      -- CUA marking: MB 1 begin drag
      if BeginDragMsgId = WM_BUTTON1MOTIONSTART then  -- if MB 1 is drag object button
         DefMouse( 'mb1_begindrag',      'MH_begin_drag 0' WM_BUTTON1UP but_1 'CHARG')
         DefMouse( 'c_mb1_begindrag',    'MH_begin_drag 1' WM_BUTTON1UP c_but_1 'CHARG')
      else
         DefMouse( 'mb1_begindrag',      'MH_begin_mark CHARG')
         DefMouse( 'c_mb1_begindrag',    'MH_begin_mark CHARG')
      endif
      DefMouse( 'a_mb1_begindrag',       'MH_begin_mark CHARG')
      DefMouse( 's_mb1_begindrag',       'MH_begin_mark CHARG')
      DefMouse( 'c_a_mb1_begindrag',     'MH_begin_mark CHARG')
      DefMouse( 'c_s_mb1_begindrag',     'MH_begin_mark CHARG')
      DefMouse( 'c_a_s_mb1_begindrag',   'MH_begin_mark CHARG')

      -- CUA marking: MB 2 begin drag
      if BeginDragMsgId = WM_BUTTON2MOTIONSTART then  -- if MB 2 is drag object button
         DefMouse( 'mb2_begindrag',      'MH_begin_drag 0' WM_BUTTON2UP 'LINE')
         DefMouse( 'c_mb2_begindrag',    'MH_begin_drag 1' WM_BUTTON2UP 'LINE')
      else
         UnDefMouse( 'mb2_begindrag')
         UnDefMouse( 'c_mb2_begindrag')
      endif

      -- CUA marking: MB 3 begin drag
      if BeginDragMsgId = WM_BUTTON3MOTIONSTART then  -- if MB 3 is drag object button
         DefMouse( 'mb3_begindrag',      'MH_begin_drag 0' WM_BUTTON3UP c_but_1)
         DefMouse( 'c_mb3_begindrag',    'MH_begin_drag 1' WM_BUTTON3UP but_1)
      else
         UnDefMouse( 'mb3_begindrag')
         UnDefMouse( 'c_mb3_begindrag')
      endif

   else

      -- Advanced marking: MB 1 single click
      DefMouse( 'mb1_click',             'MH_singleclick')
      DefMouse( 's_mb1_click',           'MH_shiftclick')
      DefMouse( 'c_mb1_click',           'ifinmark copy2clip')
      DefMouse( 'c_s_mb1_click',         'ifinmark cut')
      DefMouse( 'a_mb1_click',           'mc /MH_gotoposition/paste' DefaultPaste)
      DefMouse( 'a_s_mb1_click',         'mc /MH_gotoposition/paste' AlternatePaste)

      -- Advanced marking: MB 1 double click
      -- Note: MB 1 double click should be undefined if MB 1 single click is
      --       already defined with the same modifier keys.
      --       Exception: when the defined single click action doesn't
      --       interfere with it.
      DefMouse( 'mb1_doubleclick',       'MH_doubleclick')
      DefMouse( 'c_mb1_doubleclick',     'kwhelp')
      DefMouse( 'a_mb1_doubleclick',     '')
      DefMouse( 'c_a_mb1_doubleclick',   '')

      -- Advanced marking: MB 2 double click
      -- Note: MB 2 double click (without modifier key) is undefined
      --       if MB 2 is configured as context menu button
      -- Note: MB 2 double click should be undefined if MB 2 single click is
      --       already defined with the same modifier keys.
      --       Exception: when the defined single click action doesn't
      --       interfere with it.
      DefMouse( 'mb2_doubleclick',       'markword 1')
      DefMouse( 'c_mb2_doubleclick',     'marktoken 1')
      DefMouse( 's_mb2_doubleclick',     'findword 1')
      DefMouse( 'a_mb2_doubleclick',     'marksentence 1')
      DefMouse( 'c_a_mb2_doubleclick',   'markparagraph 1')
      DefMouse( 'a_s_mb2_doubleclick',   'extendsentence')
      DefMouse( 'c_a_s_mb2_doubleclick', 'extendparagraph')

      -- Advanced marking: MB 1 begin drag
      if BeginDragMsgId = WM_BUTTON1MOTIONSTART then  -- if MB 1 is drag object button
         DefMouse( 'mb1_begindrag',      'MH_begin_drag 0' WM_BUTTON1UP but_1 'CHARG')
         DefMouse( 'c_mb1_begindrag',    'MH_begin_drag 1' WM_BUTTON1UP c_but_1 'CHARG')
      else
         DefMouse( 'mb1_begindrag',      'MH_begin_mark' but_1)
         DefMouse( 'c_mb1_begindrag',    'MH_begin_mark' c_but_1)
      endif

      -- Advanced marking: MB 2 begin drag
      if BeginDragMsgId = WM_BUTTON2MOTIONSTART then  -- if MB 2 is drag object button
         DefMouse( 'mb2_begindrag',      'MH_begin_drag 0' WM_BUTTON2UP 'LINE')
         DefMouse( 'c_mb2_begindrag',    'MH_begin_drag 1' WM_BUTTON2UP 'LINE')
      else
         DefMouse( 'mb2_begindrag',      'MH_begin_mark LINE')
      endif

      -- Advanced marking: MB 3 begin drag
      if BeginDragMsgId = WM_BUTTON3MOTIONSTART then  -- if MB 3 is drag object button
         DefMouse( 'mb3_begindrag',      'MH_begin_drag 0' WM_BUTTON3UP c_but_1)
         DefMouse( 'c_mb3_begindrag',    'MH_begin_drag 1' WM_BUTTON3UP but_1)
      else
         DefMouse( 'mb3_begindrag',      'MH_begin_mark' c_but_1)
      endif

   endif

   -- Execute extra user definitions and modifications if defined
   'ExecUserMouseDef'

; Moved popup menu to POPUP.E
; ---------------------------------------------------------------------------
defc SetMousePointer
   universal vEPM_POINTER
   if verify( arg(1), '0123456789') then  -- contained a non-numeric character
      sayerror INVALID_NUMBER__MSG
   else
      vEPM_POINTER = arg(1)
      mouse_setpointer vEPM_POINTER
   endif

