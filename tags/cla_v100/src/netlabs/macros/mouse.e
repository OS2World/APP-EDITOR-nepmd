/****************************** Module Header *******************************
*
* Module Name: mouse.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mouse.e,v 1.7 2002-10-20 14:18:12 aschn Exp $
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
 compile if not defined(DEFAULT_PASTE)
   DEFAULT_PASTE = 'C'
 compile endif
 compile if not defined(WANT_CUA_MARKING)
   WANT_CUA_MARKING = 0
 compile endif
 compile if not defined(WANT_STREAM_MODE)
   WANT_STREAM_MODE = 0
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
 compile if not defined(WANT_KEYWORD_HELP)
   WANT_KEYWORD_HELP = 0
 compile endif
 compile if not defined(WANT_CHAR_OPS)
   WANT_CHAR_OPS = 1
 compile endif
   include NLS_LANGUAGE'.e'
compile endif  -- not defined(SMALL)

define
compile if not defined(ALTERNATE_PASTE)
 compile if DEFAULT_PASTE = ''
   ALTERNATE_PASTE = 'C'
 compile else
   ALTERNATE_PASTE = ''
 compile endif
compile endif

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
;   DRAG_ALWAYS_MARKS = 0
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
compile if not defined(INCLUDE_STANDARD_CONTEXT_MENU)
   INCLUDE_STANDARD_CONTEXT_MENU = 1
compile endif
compile if not defined(CLICK_ONLY_GIVES_FOCUS)  -- Can be 0, ADVANCED, CUA, or 1
   CLICK_ONLY_GIVES_FOCUS = 'ADVANCED'
compile endif

compile if (EPM_POINTER < 1 | EPM_POINTER > 14) & EPM_POINTER <> 'SWITCH'
 *** Invalid value for EPM_POINTER - must be 1 - 14
compile endif

; Todo:
compile if not defined(WANT_DATETIME_IN_TITLE)
   WANT_DATETIME_IN_TITLE = 1
compile endif

const
  BlankMouseHandler = "BlankMouseHandler"
  TransparentMouseHandler = "TransparentMouseHandler"

define
   CHARG_MARK =  'CHARG'
   BLOCKG_MARK = 'BLOCKG'

defproc prestore_pos2(save_pos)
   parse value save_pos with svline svcol svsx svsy
   .lineg = min(svline, .last);                       -- set .line
   .col = svcol;
   .scrollx = svsx;
   .cursoryg= svsy;

defproc psave_pos2(var save_pos)
   save_pos=.line .col .scrollx .cursoryg

defproc MouseLineColOff(var MouseLine, var MouseCol, var MouseOff, minline)
                        -- MIN = 0 for positioning, 1 for marking.
   xxx = .mousex; mx = xxx
   yyy = .mousey

   -- saying 5.21, below, but not sure if it will work for that.
   --    it will work for 5.50.

   --call messagenwait("xxx1="xxx "yyy1="yyy);
   map_point 5, xxx, yyy, off, comment;  -- map screen to line
   --call messagenwait("doc xxx2="xxx "yyy2="yyy);
   MouseLine = min(max(xxx, minline), .last)
   MouseOff  = off
   -- EVERSION >= 5.50 can go to MAXCOL+1 for GPI-style marking
   if arg(6) then  -- Flag we want character we're on, not nearest intersection.
      lne = xxx
      col = yyy
      map_point 6, lne, col, off, comment;  -- map line/col/offset to screen
      if lne>mx then  -- The intersection selected is to the right of the mouse pointer;
         yyy = yyy - 1  -- the character clicked on is the one to the left.
      endif             -- Note:  could get col. 0 this way, the but following takes care of that.
   endif
   MouseCol  = min(max(yyy, 1), MAXCOL + (rightstr(arg(5),1)='G' and minline))
   return xxx

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

defc processmousedropping
   call psave_pos(savepos)
   'MH_gotoposition'
   'GetSharBuff'     -- See clipbrd.e for details
   call prestore_pos(savepos)

defc processmouse
   universal EPM_utility_array_ID
   universal GMousePrefix
   universal LMousePrefix
   universal WindowHadFocus
   parse arg WindowHadFocus arg1

   -- 'processmouse' is called at every mouse action
   if not WindowHadFocus then
compile if WANT_DATETIME_IN_TITLE
      -- CheckIfUpdated is defined in TITLETEXT.E
      --'postme checkifupdated'
      call CheckIfUpdated()
compile endif
   endif

   if LMousePrefix<>BlankMouseHandler"." then
      OldRc = rc
compile if LOCAL_MOUSE_SUPPORT
      rc = get_array_value(EPM_utility_array_ID, LMousePrefix||arg1, CommandString)
      if not rc then
         -- Found it.
         Rc = oldRC
         if CommandString<>'' then
            CommandString
            return
         endif
      else
         if rc<>-330 then
            sayerror UNKNOWN_MOUSE_ERROR__MSG rc
            rc = OldRc
            return
         endif
         -- rc==-330 (no local handler found), now try to find a global one.
      endif
compile endif
      if GMousePrefix<>BlankMouseHandler"." then
         rc = get_array_value(EPM_utility_array_ID, GMousePrefix||arg1, CommandString)
         if not rc then
            -- Found it.
            Rc = oldRC
            if CommandString<>'' then
               CommandString
            endif
            return
         else
            if rc<>-330 then
               sayerror UNKNOWN_MOUSE_ERROR__MSG rc
            else
               -- nothing assigned to that action
            endif
            rc = OldRc
            return
         endif
      endif
   endif


defproc register_mousehandler(IsGlobal, event, mcommand)
   universal EPM_utility_array_ID
   universal GMousePrefix
   universal LMousePrefix
   if IsGlobal then
      MousePrefix = GMousePrefix
   else
compile if LOCAL_MOUSE_SUPPORT
      if (LMousePrefix=BlankMouseHandler".") or
         (LMousePrefix=TransparentMouseHandler".") then
         -- can't assign to that mouse handler.
compile endif
         return
compile if LOCAL_MOUSE_SUPPORT
      endif
      MousePrefix = LMousePrefix
compile endif
   endif
   do_array 2, EPM_utility_array_ID, MousePrefix||event, mcommand   -- assign

compile if    (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'ADVANCED')
defc MH_gotoposition2
   universal WindowHadFocus
   if WindowHadFocus then
      'MH_gotoposition'
   endif
compile endif

defc MH_gotoposition
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
   -- this procedure moves the cursor to the current mouse location.
;;
;;  Old way
;;
;;   .cursory = .mousey
;;   .cursorx = .mousex
;;
compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
 compile if UNDERLINE_CURSOR
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, stream_mode, '', 1)
 compile else
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, stream_mode)
 compile endif
compile elseif TOP_OF_FILE_VALID
 compile if UNDERLINE_CURSOR
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, 0, '', 1)
 compile else
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, 0)
 compile endif
compile else
 compile if UNDERLINE_CURSOR
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, 1, '', 1)
 compile else
   ml = MouseLineColOff(MouseLine, MouseCol, MouseOff, 1)
 compile endif
compile endif
   oldsx = .scrollx;
   .lineg = MouseLine
compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode & ml > .last then
 compile else
   if ml > .last then      -- If click below "Bottom of File",
 compile endif
      end_line             --   go to end of last line.
   else
compile endif  -- WANT_STREAM_MODE
      .col  = MouseCol
      while MouseOff<0 do
         left
         MouseOff = MouseOff + 1
      endwhile
      while MouseOff>0 do
         right
         MouseOff = MouseOff - 1
      endwhile
compile if WANT_STREAM_MODE
   endif
compile endif  -- WANT_STREAM_MODE
compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode then
 compile endif
   if .col > length(textline(.line)) then
      end_line
   endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   endif
 compile endif
compile endif
   .scrollx = oldsx;

defc MH_begin_mark
   universal BeginningLineOfDrag
   universal BeginningColOfDrag
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\DragAlwaysMarks"
   DragAlwaysMarks = NepmdQueryConfigValue( nepmd_hini, KeyPath )

compile if 0
   mt = upcase(arg(1))
   if marktype() then
      getfileid curfileid
      getmark markfirstline,marklastline,markfirstcol,marklastcol,markfileid
      if marktype() <> mt or markfileid <> curfileid then
         sayerror -279  -- sayerror('Text already marked')
         return
      endif
   endif
;compile elseif WANT_CUA_MARKING = 1 | DRAG_ALWAYS_MARKS
compile elseif WANT_CUA_MARKING = 1
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
compile else
   if DragAlwaysMarks = 1 then
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   endif
 compile endif
   if marktype() then
      sayerror-279  --  sayerror('Text already marked')
      return
   endif
compile endif
   ml = MouseLineColOff(BeginningLineOfDrag, BeginningColOfDrag, MouseOff, 1, arg(1));
compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode & ml > .last then
 compile else
   if ml > .last then      -- If click below "Bottom of File" ...
 compile endif
      BeginningLineOfDrag = .last
      BeginningColOfDrag = length(textline(.last))+1
   endif
compile endif  -- WANT_STREAM_MODE
   call register_mousehandler(1, 'ENDDRAG',    'MH_end_mark '||arg(1))  -- shifted
   call register_mousehandler(1, 'CANCELDRAG', 'MH_cancel_mark')  -- shifted
   if upcase(arg(1))='LINE' then
      .DragStyle = 2
   elseif leftstr(upcase(arg(1)),5)='BLOCK' then
      .DragStyle = 1
   elseif leftstr(upcase(arg(1)),4)='CHAR' then
      .DragStyle = 3
   endif
   mouse_setpointer MARK_POINTER
compile if DRAGCOLOR<>''
   .DragColor = DRAGCOLOR
compile else
   .DragColor = .markcolor
compile endif

defc MH_end_mark
   universal BeginningLineOfDrag
   universal BeginningColOfDrag
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif

; \NEPMD\User\Mouse\Mark\Workaround
   -- Advantage   : With keyword-highlighting on it is nearly impossible
   --               to mark the last char in a line with the mouse.
   --               This workaround fixes it.
   -- Disadvantage: The command 'toggle_parse' scrolls the window
   --               from the end of mark to the cursor after processing
   --               the mark.
   --               This is an unusual behaviour and could confuse
   --               the user.
   --               Therefore: cursor goes to end of mark and cursor is vcentered.
   universal EPM_utility_array_ID
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\Workaround"
   Workaround = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   if Workaround = 1 then
      -- Query keyword highlighting state (windowmessage returns 0 or 2)
      -- from defc qparse (commented out) in STDCTRL.E:
      saved_toggle = windowmessage(1,  getpminfo(EPMINFO_EDITFRAME),
                                   5505,          -- EPM_EDIT_KW_QUERYPARSE
                                   0,
                                   0)

      -- Get current keyword highlighting file if highlighting is on.
      --   (Uses an array var, set before by 'toggle_parse'.)
      --   ('toggle_parse' from STDCTRL.E was altered too:
      --   Now it stores the kwfilename in an array.)
      -- Switch keyword highlighting off it is on.
      if saved_toggle <> 0 then
         --refresh
         --call psave_pos(saved_pos)
         --saved_windowx = .windowx
         --saved_windowy = .windowy
         --saved_cursorx = .cursorx
         saved_cursory = .cursory
         --saved_line = .line
         --saved_col = .col
         --sayerror '.line = '.line', .col = '.col', .cursorx = '.cursorx', .cursory = '.cursory', .windowx = '.windowx', .windowy = '.windowy
         getfileid fid
         -- Get keyword highlighting file for this file
         -- (The array var 'kwfile.'fid is set by defc toggle_parse in STDCTRL.E)
         do_array 3, EPM_utility_array_ID, 'kwfile.'fid, kwfilename  --AS--
         'toggle_parse' 0
      endif

      --sayerror 'Toggle state before is: 'saved_toggle', kwfilename is: ' kwfilename
   endif  -- Workaround = 1

   ml = MouseLineColOff(endingline, endingcol, MouseOff, 1, arg(1));

   if Workaround = 1 then
      -- Switch keyword highlighting on if was on
      if saved_toggle <> 0 then
         -- from defc toggle_parse in STDCTRL.E:
         call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                            5502,               -- EPM_EDIT_TOGGLEPARSE
                            1,
                            put_in_buffer(fid kwfilename))

         --'toggle_parse' 1 kwfilename
      endif
   endif  -- Workaround = 1

compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode & ml > .last then
 compile else
   if ml > .last then      -- If click below "Bottom of File" ...
 compile endif
      endingline = .last
      endingcol = length(textline(.last))+1
   endif
   if not (ml > .last & BeginningLineOfDrag = endingline & BeginningColOfDrag = endingcol) then
compile endif  -- WANT_STREAM_MODE
      unmark
      getfileid CurrentFile
      call pset_mark(BeginningLineOfDrag, endingline,
                     BeginningColOfDrag,  max(endingcol,1),  arg(1), CurrentFile)
      /* Copy the marked area to the clipboard in case we want to copy it */
      /* into a different editor window.                                  */
      'Copy2SharBuff'
compile if WANT_STREAM_MODE
   else
      refresh  -- Get rid of the drag-mark highlighting
   endif
compile endif  -- WANT_STREAM_MODE
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then
 compile endif
      -- EVERSION >= '5.50': GPI version allows cursor to be off screen
      if .cursorx > 0 & .cursorx <= .windowwidth & .cursory > 0 & .cursory <= .windowheight then
         getmark  firstline,lastline,firstcol,lastcol,fileid
         if marktype()<>'LINE' then
            .col=lastcol
         endif
         if lastline<>.line then
            if lastline>.line then '+'lastline-.line; else lastline-.line; endif
         endif
      endif
      'MH_gotoposition'
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
;  refresh                                          ???
   call register_mousehandler(1, 'ENDDRAG', ' ')
   call register_mousehandler(1, 'CANCELDRAG', ' ')

   if Workaround = 1 then
 compile if KEEP_CURSOR_ON_SCREEN
      if saved_toggle <> 0 then
         if saved_cursory < 1 or saved_cursory > .windowheight then
            --call prestore_pos(saved_pos)
            --.windowx = saved_windowx
            --.windowy = saved_windowy
            -- go to end of mark and vcenter cursor
            call pend_mark()
            --.lineg = saved_line-- - saved_cursory
            --.col = saved_col
            --refresh
            --.cursorx = saved_cursorx
            --.cursory = saved_cursory
            right
            oldline=.line
            .cursory=.windowheight%2
            oldline
         endif
      endif
 compile endif
   endif  -- Workaround = 1


defc MH_cancel_mark
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif
   call register_mousehandler(1, 'ENDDRAG', ' ')
   call register_mousehandler(1, 'CANCELDRAG', ' ')
   refresh

defc markword
   if arg(1) then
      'MH_gotoposition'
      unmark
   endif
   call pmark_word()

defc marktoken
   if arg(1) then
      'MH_gotoposition'
   endif
   if find_token(startcol, endcol) then
      getfileid fid
compile if WANT_CHAR_OPS
      call pset_mark(.line, .line, startcol, endcol, 'CHAR', fid)
compile else
      call pset_mark(.line, .line, startcol, endcol, 'BLOCK', fid)
compile endif
      'Copy2SharBuff'       /* Copy mark to shared text buffer */
   endif

defc findword
   if arg(1) then
      'MH_gotoposition'
   endif
   if find_token(startcol, endcol) then
      .col = endcol
      'l '\1 || substr(textline(.line), startcol, (endcol-startcol)+1)
   endif

compile if WANT_CUA_MARKING
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

defc MH_dblclick
   unmark
   if .line then
;;    call pmark_word()  -- pmark_word doesn't include white space; the following does:
      call pbegin_word()
      mark_char
      startcol = .col
      tab_word
;     if .col<>length(textline(.line)) then .col = .col - 1; endif
      .col = .col - 1
      mark_char
      .col = startcol
   endif
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

compile endif  -- WANT_CUA_MARKING

defc MH_double -- take care for doubleclicks on URLs
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Url\MB1_DClick"
   MB1DClickStartsBrowser = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   KeyPath = "\NEPMD\User\Mouse\Url\Browser"
   BrowserExecutable = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   UrlStrings = 'http:// ftp:// www. https:// mailto:'
   Url = ''
compile if WANT_TREE
   if upcase(subword(.filename,1,2)) = '.DOS DIR' | .filename = '.tree' then
compile else
   if upcase(subword(.filename,1,2)) = '.DOS DIR' then
compile endif
      executekey a_1  -- For simplicity, assume user hasn't redefined this key:
   else
      if MB1DClickStartsBrowser = 1 then
         -- if word under cursor contains an url then start netscape
         call psave_pos(saved_pos)
         call psave_mark(saved_mark)

         -- go to mouse position to ensure getting URL at mouse pointer and not at cursor
         'MH_gotoposition'
         cursorcol = .col
         call pmark_word()
         getmark firstline, lastline, firstcol, lastcol, fileid
         Spec = substr( textline( firstline ), firstcol, lastcol - firstcol + 1 )
         call prestore_mark(saved_mark)
         call prestore_pos(saved_pos)
         if cursorcol >= firstcol and cursorcol <= lastcol then -- if cursor in mark

            -- locate URL in double-clicked word
            do u = 1 to words( UrlStrings )
               UrlString = word( UrlStrings, u )
               p1 = pos( UrlString, Spec )
               if p1 > 0 then

                  -- get URL
                  Url = substr( Spec, p1)

                  -- add default protocol identifier
                  if (pos( ':', Url) = 0) then
                     Url = 'http://'Url
                  endif

                  leave
               endif
            enddo


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
            endif

            -- if URL found until here, process it
            if Url <> '' then
               -- cut off special separators from URL
               SeparatorList = '"'||"'"||')]]>,;!';
               ReplaceList   =  copies( ' ', length( SeparatorList))
               Url = word( translate( Url, ReplaceList, SeparatorList),  1)

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

               sayerror 'Invoking' BrowserName 'with:' Url
               'os2 /min /c start /f' BrowserExecutable' "'Url'"'

               -- Teststrings here:
               -- http://www.os2.org
               -- ftp://ftp.netlabs.org,www.netlabs.org,ftp://ftp.os2.org
               -- (ftp://ftp.netlabs.org)
               -- ####ftp://ftp.netlabs.org)###)
               -- ftp://ftp.netlabs.org
               -- www.netlabs.org
               -- mailto:C.Langanke@Teamos2.de

               -- restore current directory
               if Browserpath <> '' then
                  call directory( CurrentDirectory)
               endif
            endif  -- Url <> ''

         endif  -- cursorcol > firstcol and cursorcol < lastcol

      endif  -- MB1DClickStartsBrowser = 1

      -- if no URL found, process the normal definition
      if MB1DClickStartsBrowser <> 1 or Url = '' then
         unmark
         'ClearSharBuff'
      endif

   endif  -- filename = (.DOS DIR | .tree)

defc MH_shiftclick
   if marktype() then
      getmark markfirstline,marklastline,markfirstcol,marklastcol,markfileid
   else
      markfileid=''
   endif
   unmark
   getfileid CurrentFile
   if CurrentFile<>markfileid then
      markfirstline=.line; markfirstcol=.col
   elseif markfirstline=.line & markfirstcol=.col then
      markfirstline=marklastline; markfirstcol=marklastcol
   endif
   call MouseLineColOff(MouseLine, MouseCol, MouseOff, 1, arg(1))
   call pset_mark(markfirstline, MouseLine, markfirstcol, MouseCol, 'CHAR', CurrentFile)
   'MH_gotoposition'
   'Copy2SharBuff'

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

definit
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
compile if EPM_POINTER = 'SWITCH'
 compile if defined(MY_MOUSE_POINTER)  -- User has a preference for the default pointer
   vEPM_POINTER = MY_MOUSE_POINTER
 compile else
   vEPM_POINTER = TEXT_POINTER      -- GPI version gets text pointer
 compile endif
compile endif
   'postme mouse_init'

defc mouse_init
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif  -- EPM_POINTER = 'SWITCH'
;   universal EPM_utility_array_ID, MouseStyle
   universal EPM_utility_array_ID
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\MouseStyle"
   MouseStyle = NepmdQueryConfigValue( nepmd_hini, KeyPath )

compile if WANT_MMEDIA
   universal mmedia_font
   mmedia_font = registerfont('Multimedia Icons', 0, 0)
compile endif  -- WANT_MMEDIA
compile if EPM_POINTER = 'SWITCH'
 compile if defined(MY_MOUSE_POINTER)  -- User has a preference for the default pointer
  compile if MY_MOUSE_POINTER<>TEXT_POINTER
   mouse_setpointer vEPM_POINTER
  compile endif
 compile else
  -- EPM32: Do nothing; initialized in DEFINIT so INIT_CONFIG can override.
 compile endif
compile elseif EPM_POINTER<>TEXT_POINTER
   mouse_setpointer EPM_POINTER
compile endif  -- EPM_POINTER = 'SWITCH'
   -- set initial mousesets
   SetMouseSet(1, "BaseMouseHandlers") -- default global mouseset
compile if LOCAL_MOUSE_SUPPORT
   SetMouseSet(0, TransparentMouseHandler)  -- default local mouseset is blank.
compile endif
compile if SUPPORT_DRAGDROP_FOR_BOTH
   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(75),        -- SV_BEGINDRAG
                            2))
;  kc_flags = itoa(substr(res,3,2), 10)
   msgid = itoa(substr(res, 1, 2), 10)
   if MouseStyle = 1 then but_1 = BLOCKG_MARK; c_but_1 = CHARG_MARK
                     else but_1 = CHARG_MARK;  c_but_1 = BLOCKG_MARK
   endif
   if msgid = WM_BUTTON1MOTIONSTART then
      call register_mousehandler(1, '1 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON1UP but_1 CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON1UP c_but_1 CHARG_MARK)
   elseif msgid = WM_BUTTON2MOTIONSTART then
      call register_mousehandler(1, '2 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON2UP 'LINE')
      call register_mousehandler(1, '2 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON2UP 'LINE')
   elseif msgid = WM_BUTTON3MOTIONSTART then
      call register_mousehandler(1, '3 BEGINDRAG 0', 'MH_begin_drag_2 0' WM_BUTTON3UP  c_but_1)
      call register_mousehandler(1, '3 BEGINDRAG 2', 'MH_begin_drag_2 1' WM_BUTTON3UP  but_1)
   else
      -- Huh?
   endif
compile endif  -- SUPPORT_DRAGDROP_FOR_BOTH
compile if WANT_MMEDIA
   call register_mousehandler(1, '1 SECONDCLK 0', 'MH_MM_dblclick')
;compile elseif WANT_SPEECH
;   call register_mousehandler(1, '1 SECONDCLK 0', 'SPPopUp')
compile endif  -- WANT_MMEDIA
;compile if WANT_SPEECH
;   call register_mousehandler(1, '1 SECONDCLK 2', 'SPPlay')
;compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   call MH_set_Mouse(msgid)

defproc MH_set_mouse
;   universal CUA_marking_switch, MouseStyle
   universal CUA_marking_switch
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mouse\Mark\MouseStyle"
   MouseStyle = NepmdQueryConfigValue( nepmd_hini, KeyPath )

   msgid = arg(1)
   if msgid='' then
      res =  atol(dynalink32( 'PMWIN',
                              '#829',           -- Win32QuerySysValue
                               atol(1) ||       -- HWND_DESKTOP
                               atol(75),        -- SV_BEGINDRAG
                               2))
;     kc_flags = itoa(substr(res,3,2), 10)
      msgid = itoa(substr(res, 1, 2), 10)
   endif

   if CUA_marking_switch then  ----------------------------------------
compile endif  -- WANT_CUA_MARKING = 'SWITCH'

      -- 1 == shift, 2 = control, 4 = alt.
compile if WANT_CUA_MARKING
      call register_mousehandler(1, '1 CLICK 0',     'MH_singleclick')
      call register_mousehandler(1, '1 CLICK 1',     'MH_shiftclick')
      call register_mousehandler(1, '1 CLICK 2',     'MH_singleclick')
      call register_mousehandler(1, '1 CLICK 3',     'MH_shiftclick')
      call register_mousehandler(1, '1 CLICK 4',     'MH_singleclick')
      call register_mousehandler(1, '1 CLICK 5',     'MH_shiftclick')
      call register_mousehandler(1, '1 CLICK 6',     'MH_singleclick')
      call register_mousehandler(1, '1 CLICK 7',     'MH_shiftclick')
 compile if not WANT_MMEDIA -- and not WANT_SPEECH
      call register_mousehandler(1, '1 SECONDCLK 0', 'MH_dblclick')
 compile endif
;compile if not WANT_SPEECH
      call register_mousehandler(1, '1 SECONDCLK 2', 'MH_dblclick')
;compile endif
      call register_mousehandler(1, '1 SECONDCLK 4', 'MH_dblclick')
      call register_mousehandler(1, '1 SECONDCLK 6', 'MH_dblclick')
      if msgid <> WM_BUTTON1MOTIONSTART then
         call register_mousehandler(1, '1 BEGINDRAG 0', 'MH_begin_mark' CHARG_MARK)
         call register_mousehandler(1, '1 BEGINDRAG 2', 'MH_begin_mark' CHARG_MARK)
      endif -- msgid <> WM_BUTTON1MOTIONSTART
      call register_mousehandler(1, '1 BEGINDRAG 1', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 3', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 4', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 5', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 6', 'MH_begin_mark' CHARG_MARK)
      call register_mousehandler(1, '1 BEGINDRAG 7', 'MH_begin_mark' CHARG_MARK)
compile endif  -- WANT_CUA_MARKING

compile if WANT_CUA_MARKING = 'SWITCH'
      if msgid <> WM_BUTTON2MOTIONSTART then
         call register_mousehandler(1, '2 BEGINDRAG 0', '')  -- Delete the defs
         call register_mousehandler(1, '2 BEGINDRAG 2', '')
      endif
      if msgid <> WM_BUTTON3MOTIONSTART then
         call register_mousehandler(1, '3 BEGINDRAG 0', '')  -- Delete the defs
      endif
         call register_mousehandler(1, '2 SECONDCLK 0', '')
         call register_mousehandler(1, '2 SECONDCLK 2', '')
         call register_mousehandler(1, '2 SECONDCLK 1', '')
   else  -- CUA_marking_switch ----------------------------------------
      call register_mousehandler(1, '1 CLICK 6',     '')
;compile if not WANT_SPEECH
         call register_mousehandler(1, '1 SECONDCLK 2', '')
;compile endif
      call register_mousehandler(1, '1 SECONDCLK 4', '')
      call register_mousehandler(1, '1 SECONDCLK 6', '')
      call register_mousehandler(1, '1 BEGINDRAG 1', '')
      call register_mousehandler(1, '1 BEGINDRAG 3', '')
      call register_mousehandler(1, '1 BEGINDRAG 4', '')
      call register_mousehandler(1, '1 BEGINDRAG 5', '')
      call register_mousehandler(1, '1 BEGINDRAG 6', '')
      call register_mousehandler(1, '1 BEGINDRAG 7', '')
compile endif  -- WANT_CUA_MARKING = 'SWITCH'

compile if WANT_CUA_MARKING = 'SWITCH' or WANT_CUA_MARKING = 0
 compile if    (CLICK_ONLY_GIVES_FOCUS = 1 | CLICK_ONLY_GIVES_FOCUS = 'ADVANCED')
      call register_mousehandler(1, '1 CLICK 0',     'MH_gotoposition2')
 compile else
      call register_mousehandler(1, '1 CLICK 0',     'MH_gotoposition')
 compile endif
      call register_mousehandler(1, '1 CLICK 1',     'MH_shiftclick')
      if MouseStyle = 1 then but_1 = BLOCKG_MARK; c_but_1 = CHARG_MARK
                        else but_1 = CHARG_MARK;  c_but_1 = BLOCKG_MARK
      endif
      if msgid <> WM_BUTTON1MOTIONSTART then
         call register_mousehandler(1, '1 BEGINDRAG 0', 'MH_begin_mark 'but_1)
         call register_mousehandler(1, '1 BEGINDRAG 2', 'MH_begin_mark 'c_but_1)
      endif
      if msgid <> WM_BUTTON2MOTIONSTART then
         call register_mousehandler(1, '2 BEGINDRAG 0', 'MH_begin_mark LINE')
      endif
      call register_mousehandler(1, '1 CLICK 2',     'ifinmark copy2clip')
      call register_mousehandler(1, '1 CLICK 3',     'ifinmark cut')
      call register_mousehandler(1, '1 CLICK 4',     'mc /MH_gotoposition/paste' DEFAULT_PASTE)
      call register_mousehandler(1, '1 CLICK 5',     'mc /MH_gotoposition/paste' ALTERNATE_PASTE)
      if msgid <> WM_BUTTON3MOTIONSTART then
         call register_mousehandler(1, '3 BEGINDRAG 0', 'MH_begin_mark 'c_but_1)
      endif
 compile if not WANT_MMEDIA -- and not WANT_SPEECH
      call register_mousehandler(1, '1 SECONDCLK 0', 'MH_double')
 compile endif
      call register_mousehandler(1, '2 SECONDCLK 0', 'markword 1')
      call register_mousehandler(1, '2 SECONDCLK 2', 'marktoken 1')
      call register_mousehandler(1, '2 SECONDCLK 1', 'findword 1')
 compile if WANT_KEYWORD_HELP -- and not WANT_SPEECH
      call register_mousehandler(1, '1 SECONDCLK 2', 'kwhelp')
 compile endif
compile endif  -- WANT_CUA_MARKING = 'SWITCH' or WANT_CUA_MARKING = 0

compile if WANT_CUA_MARKING = 'SWITCH'
   endif  -- CUA_marking_switch ---------------------------------------
compile endif

   call register_mousehandler(1, 'CHORD',     'Ring_More')

   -- NOP out the default action associated with user's context button
   res =  atol(dynalink32( 'PMWIN',
                           '#829',           -- Win32QuerySysValue
                            atol(1) ||       -- HWND_DESKTOP
                            atol(79),        -- SV_CONTEXTMENU
                            2))
   kc_flags = itoa(substr(res,3,2), 10)
   msgid = itoa(substr(res, 1, 2), 10)
   if msgid = WM_CHORD then
      event = 'CHORD'
      call register_mousehandler(1, 'CHORD', '')
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
      call register_mousehandler(1, button event (kc_flags / 8), '')
   endif

   call register_mousehandler(1, 'CONTEXTMENU',   'MH_popup')

defc MH_begin_drag_2  -- Determine if a click is within the selected area
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
   parse arg copy_flag buttonup_msg advanced_marking_marktype CUA_marking_marktype
   if mouse_in_mark() then
      call WindowMessage(0,  getpminfo(EPMINFO_EDITCLIENT),
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
compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then  -- If 'SWITCH', we do advanced mark action if CUA switch is off
compile endif  -- WANT_CUA_MARKING = 'SWITCH'
compile if WANT_CUA_MARKING
      if CUA_marking_marktype<>'' then   -- This can be blank
         'MH_begin_mark' CUA_marking_marktype
      endif
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   else       -- else, not CUA marking switch - do the standard EPM ('advanced marking') action
compile endif  -- WANT_CUA_MARKING = 'SWITCH'
compile if WANT_CUA_MARKING <> 1
      'MH_begin_mark' advanced_marking_marktype
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   endif
compile endif  -- WANT_CUA_MARKING = 'SWITCH'

defproc mouse_in_mark()
   -- First we query the position of the mouse
   call MouseLineColOff(MouseLine, MouseCol, MouseOff, 0)
   -- Now determine if the mouse is in the selected text area.
   mt=leftstr(marktype(),1)
   if mt then
      getfileid curfileid
      getmark markfirstline,marklastline,markfirstcol,marklastcol,markfileid
      if (markfileid == curfileid) and
         (MouseLine >= markfirstline) and (MouseLine <= marklastline) then

         -- assert:  at this point the only case where the text is outside
         --          the selected area is on a single line char mark and a
         --          block mark.  Any place else is a valid selection
         if not ((mt=='C' & (markfirstline=MouseLine & MouseCol < markfirstcol) or (marklastline=MouseLine & MouseCol > marklastcol)) or
                 (mt=='B' & (MouseCol < markfirstcol or MouseCol > marklastcol)) ) then
            return 1
         endif
      endif
   endif

defc ifinmark =
   if mouse_in_mark() then
      ''arg(1)
   endif

compile if WANT_MMEDIA
defc MH_MM_dblclick
   universal mmedia_font
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
   -- First we query the position of the mouse
   call MouseLineColOff(MouseLine, MouseCol, MouseOff, 0, '', 1)
   class = 0; offst = -2
   query_attribute class, val, IsPush, offst, MouseCol, MouseLine
   if class=32 /* | (class=16 & val=mmedia_font & IsPush) */ then
;;    if class=16 then  -- If we got the font class, go for the mmedia class.
;;       offst = -2
;;       query_attribute class, val, IsPush, offst, MouseCol, MouseLine
;;    endif
      .col = MouseCol
      ch = asc(substr(textline(MouseLine), MouseCol, 1))
;;    sayerror 'selected MMedia type' ch 'with value' val
      circleit 1, MouseLine, MouseCol-1, MouseCol+1, 16777220
      -- Send a message to the owner of the EMLE: OBJEPM_LINKOBJ = 0x15A4 = 5540
      call windowmessage(0,  getpminfo(EPMINFO_PARENTFRAME), 5540, val, ch)
;compile if WANT_SPEECH
;   else  -- not mmedia, so do the standard action
;      'SPPopUp'  -- Speech support always does this
;compile else
  compile if WANT_CUA_MARKING = 'SWITCH'
   elseif CUA_marking_switch then
  compile else
   else  -- class=32
  compile endif
  compile if WANT_CUA_MARKING
      'MH_dblclick'  -- This is the CUA-marking-mode action
  compile endif
  compile if WANT_CUA_MARKING = 'SWITCH'
   else  -- class=32
  compile endif
  compile if WANT_CUA_MARKING <> 1
      'MH_Double'    -- This is the normal EPM marking mode action
  compile endif
;compile endif  -- WANT_SPEECH
   endif  -- class=32
compile endif

const
   FILL_MARK_MENU__MSG = 'Fill mark'
   FILL_MARK_MENUP__MSG = \1'Fill marked region with a character, overlaying current contents.'
   HP_POPUP_FILL = 0
   REFLOW_MARK_MENU__MSG = 'Reflow mark'
   REFLOW_MARK_MENUP__MSG = \1'Reflow text in marked region.'
   HP_POPUP_REFLOW = 0
   MARK_WORD_MENU__MSG = 'Mark word'
   MARK_WORD_MENUP__MSG = \1'Mark space-delimited word under mouse pointer.'
   HP_POPUP_MARKWORD = 0
   MARK_TOKEN_MENU__MSG = 'Mark identifier'
   MARK_TOKEN_MENUP__MSG = \1'Mark the C-language identifier under the mouse pointer.'
   HP_POPUP_MARKTOKEN = 0
   FIND_TOKEN_MENU__MSG = 'Find identifier'
   FIND_TOKEN_MENUP__MSG = \1'Find the next occurrence of the identifier under the mouse pointer.'
   HP_POPUP_FINDTOKEN = 0
   UPCASE_MARK_MENU__MSG = 'Uppercase selection'
   UPCASE_MARK_MENUP__MSG = \1'Translate selected text to upper case.'
   HP_POPUP_UPCASEMARK = 0
   LOCASE_MARK_MENU__MSG = 'Lowercase selection'
   LOCASE_MARK_MENUP__MSG = \1'Translate selected text to lower case.'
   HP_POPUP_LOCASEMARK = 0
   UPCASE_WORD_MENU__MSG = 'Uppercase word'
   UPCASE_WORD_MENUP__MSG = \1'Translate word under mouse pointer to upper case.'
   HP_POPUP_UPCASEWORD = 0
   LOCASE_WORD_MENU__MSG = 'Lowercase word'
   LOCASE_WORD_MENUP__MSG = \1'Translate word under mouse pointer to lower case.'
   HP_POPUP_LOCASEWORD = 0
   SHIFT_MENU__MSG = 'Shift'
   SHIFT_MENUP__MSG = \1'Shift marked text left or right.'
   HP_POPUP_SHIFT = 0
   SHIFTLEFT_MENU__MSG = 'Shift left 1'
   SHIFTLEFT_MENUP__MSG = \1'Shift marked text left 1 character.'
   HP_POPUP_SHIFTLEFT = 0
   SHIFTLEFT3_MENU__MSG = 'Shift left 3'
   SHIFTLEFT3_MENUP__MSG = \1'Shift marked text left 3 characters.'
   HP_POPUP_SHIFTLEFT3 = 0
   SHIFTLEFT8_MENU__MSG = 'Shift left 8'
   SHIFTLEFT8_MENUP__MSG = \1'Shift marked text left 8 characters.'
   HP_POPUP_SHIFTLEFT8 = 0
   SHIFTRIGHT_MENU__MSG = 'Shift right 1'
   SHIFTRIGHT_MENUP__MSG = \1'Shift marked text right 1 character.'
   HP_POPUP_SHIFTRIGHT = 0
   SHIFTRIGHT3_MENU__MSG = 'Shift right 3'
   SHIFTRIGHT3_MENUP__MSG = \1'Shift marked text right 3 characters.'
   HP_POPUP_SHIFTRIGHT3 = 0
   SHIFTRIGHT8_MENU__MSG = 'Shift right 8'
   SHIFTRIGHT8_MENUP__MSG = \1'Shift marked text right 8 characters.'
   HP_POPUP_SHIFTRIGHT8 = 0
   CENTER_LINE_MENU__MSG = 'Center line'
   CENTER_LINE_MENUP__MSG = \1'Center line under mouse pointer vertically in window.'
   HP_POPUP_CENTERLINE = 0
   CENTER_MARK_MENU__MSG = 'Center text'
   CENTER_MARK_MENUP__MSG = \1'Center marked text within margins or block mark.'
   HP_POPUP_CENTERMARK = 0
   SORT_MARK_MENU__MSG = 'Sort'
   SORT_MARK_MENUP__MSG = \1'Sort marked lines, using block mark (if present) as key.'
   HP_POPUP_SORT = 0
   TOP_LINE_MENU__MSG = 'Scroll to top'
   TOP_LINE_MENUP__MSG = \1'Scroll so line under mouse pointer is at top of window.'
   HP_POPUP_TOP = 0

compile if WANT_TREE
   LOAD_FILE_MENU__MSG = '~Load file'
   SORT_ASCENDING_MENU__MSG = '~Sort ascending'
   SORT_DATE_MENU__MSG = 'Sort by ~date'
   SORT_TIME_MENU__MSG = 'Sort by ~time'
   SORT_SIZE_MENU__MSG = 'Sort by ~size'
   SORT_EASIZE_MENU__MSG = 'Sort by ~EA size'
   SORT_FULLNAME_MENU__MSG = 'Sort by ~fully-qualified filename'
   SORT_NAME_MENU__MSG = 'Sort by ~name'
   SORT_EXTENSION_MENU__MSG = 'Sort by ~extension'
   SORT_DESCENDING_MENU__MSG = 'Sort ~descending'

   LOAD_FILE_MENUP__MSG = \1'Load the file or list the directory under the cursor'
   SORT_ASCENDING_MENUP__MSG = \1'Sort the file or marked lines from smallest to largest'
   SORT_XXXX_MENUP__MSG = \1'Sort the file or marked lines by the indicated attribute'
   SORT_DESCENDING_MENUP__MSG = \1'Sort the file or marked lines from largest to smallest'
compile endif


defc MH_popup
   universal activemenu, previouslyactivemenu
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
   if previouslyactivemenu = '' then
      previouslyactivemenu = activemenu
   endif
   menuname = 'popup1'
   activemenu = menuname

   deletemenu menuname, 0, 0, 0
   buildsubmenu  menuname, 80, '', '', 0 , 0
   mt = leftstr(marktype(),1)
   in_mark = mouse_in_mark()  -- Save in a variable so user's include file can test.

compile if INCLUDE_STANDARD_CONTEXT_MENU
 compile if WANT_TREE
   if .filename = '.tree' then
      buildmenuitem menuname, 80, 8000, LOAD_FILE_MENU__MSG\9'Alt+1',   'dokey a_1'LOAD_FILE_MENUP__MSG, 0, 0
      buildmenuitem menuname, 80, 8001, SORT_ASCENDING_MENU__MSG,   ''SORT_ASCENDING_MENUP__MSG, 17, 0
      buildmenuitem menuname, 80, 8002, SORT_DATE_MENU__MSG,        'treesort' 'D'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8003, SORT_TIME_MENU__MSG,        'treesort' 'T'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8004, SORT_SIZE_MENU__MSG,        'treesort' 'S'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8005, SORT_EASIZE_MENU__MSG,      'treesort' 'EA'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8006, SORT_FULLNAME_MENU__MSG,    'treesort' 'F'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8007, SORT_NAME_MENU__MSG,        'treesort' 'N'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8008, SORT_EXTENSION_MENU__MSG,   'treesort' 'EX'SORT_XXXX_MENUP__MSG, 32769, 0
      buildmenuitem menuname, 80, 8011, SORT_DESCENDING_MENU__MSG,  ''SORT_DESCENDING_MENUP__MSG, 17, 0
      buildmenuitem menuname, 80, 8012, SORT_DATE_MENU__MSG,        'treesort' '/R' 'D'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8013, SORT_TIME_MENU__MSG,        'treesort' '/R' 'T'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8014, SORT_SIZE_MENU__MSG,        'treesort' '/R' 'S'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8015, SORT_EASIZE_MENU__MSG,      'treesort' '/R' 'EA'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8016, SORT_FULLNAME_MENU__MSG,    'treesort' '/R' 'F'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8017, SORT_NAME_MENU__MSG,        'treesort' '/R' 'N'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8018, SORT_EXTENSION_MENU__MSG,   'treesort' '/R' 'EX'SORT_XXXX_MENUP__MSG, 32769, 0
   elseif in_mark then  -- Build Inside-Mark pop-up
 compile else
   if in_mark then  -- Build Inside-Mark pop-up
 compile endif
      gray_if_charmark = 16384*(MT='C')
      buildmenuitem menuname, 80, 8000, UNMARK_MARK_MENU__MSG\9'Alt+U',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
      buildmenuitem menuname, 80, 8001, DELETE_MARK_MENU__MSG\9'Alt+D',   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
      buildmenuitem menuname, 80, 8002, FILL_MARK_MENU__MSG\9'Alt+F',     'Fill'FILL_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_FILL, 0)
      buildmenuitem menuname, 80, 8003, REFLOW_MARK_MENU__MSG\9'Alt+P',   'key 1 a+P'REFLOW_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_REFLOW, gray_if_charmark)
      buildmenuitem menuname, 80, 8004, UPCASE_MARK_MENU__MSG\9'Ctrl+F3', 'key 1 c+f3'UPCASE_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_UPCASEMARK, 0)
      buildmenuitem menuname, 80, 8005, LOCASE_MARK_MENU__MSG\9'Ctrl+F4', 'key 1 c+f4'LOCASE_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_LOCASEMARK, 0)
      buildmenuitem menuname, 80, 8006, SORT_MARK_MENU__MSG,              'Sort'SORT_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_SORT, gray_if_charmark)
      buildmenuitem menuname, 80, 8007, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8008, SHIFT_MENU__MSG,   ''SHIFT_MENUP__MSG, 17, mpfrom2short(HP_POPUP_SHIFT, gray_if_charmark)
      nodismiss_gifc = gray_if_charmark + 32  -- 32 = MIA_NODISMISS
      buildmenuitem menuname, 80, 8009, SHIFTLEFT_MENU__MSG\9'Ctrl+F7',   'key 1 a+F7'SHIFTLEFT_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT, nodismiss_gifc)
      buildmenuitem menuname, 80, 8010, SHIFTLEFT3_MENU__MSG,             'key 3 a+F7'SHIFTLEFT3_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT3, nodismiss_gifc)
      buildmenuitem menuname, 80, 8011, SHIFTLEFT8_MENU__MSG,             'key 8 a+F7'SHIFTLEFT8_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT8, nodismiss_gifc)
      buildmenuitem menuname, 80, 8013, SHIFTRIGHT_MENU__MSG\9'Ctrl+F8',  'key 1 a+F8'SHIFTRIGHT_MENUP__MSG, 2049, mpfrom2short(HP_POPUP_SHIFTRIGHT, nodismiss_gifc)
      buildmenuitem menuname, 80, 8014, SHIFTRIGHT3_MENU__MSG,            'key 3 a+F8'SHIFTRIGHT3_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTRIGHT3, nodismiss_gifc)
      buildmenuitem menuname, 80, 8015, SHIFTRIGHT8_MENU__MSG,            'key 8 a+F8'SHIFTRIGHT8_MENUP__MSG, 32769, mpfrom2short(HP_POPUP_SHIFTRIGHT8, nodismiss_gifc)
      buildmenuitem menuname, 80, 8016, CENTER_MARK_MENU__MSG\9'Alt+T',   'key 1 a+t'CENTER_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_CENTERMARK, gray_if_charmark)
      buildmenuitem menuname, 80, 8017, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8018, CLIP_COPY_MENU__MSG\9 || CTRL_KEY__MSG'+'INSERT_KEY__MSG ,  'Copy2Clip'CLIP_COPY_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPY, 0)
      buildmenuitem menuname, 80, 8019, CUT_MENU__MSG\9 || SHIFT_KEY__MSG'+'DELETE_KEY__MSG, 'Cut'CUT_MENUP__MSG,       0, mpfrom2short(HP_EDIT_CUT, 0)
      buildmenuitem menuname, 80, 8020, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8021, STYLE_MENU__MSG\9'Ctrl+Y',        'fontlist'STYLE_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_STYLE, 0)
 compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
 compile endif
      buildmenuitem menuname, 80, 8022, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8023, PROOF_MENU__MSG,           'proof'PROOF_MENUP__MSG,     0, mpfrom2short(HP_OPTIONS_PROOF, 16384*(mt<>'L'))
 compile if CHECK_FOR_LEXAM
   endif
 compile endif
      buildmenuitem menuname, 80, 8024, \0,                               '',          4, 0
 compile if ENHANCED_PRINT_SUPPORT
      buildmenuitem menuname, 80, 8025, PRT_MARK_MENU__MSG'...',          'PRINTDLG M'ENHPRT_MARK_MENUP__MSG,0, mpfrom2short(HP_EDIT_ENHPRINT, 0)
 compile else
      buildmenuitem menuname, 80, 8025, PRT_MARK_MENU__MSG,               'DUPMARK P'PRT_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_PRINT, 0)
 compile endif
   elseif mt<>' ' then  -- Build Outside-Mark pop-up
      'MH_gotoposition'
      buildmenuitem menuname, 80, 8000, COPY_MARK_MENU__MSG\9'Alt+C',     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
      buildmenuitem menuname, 80, 8001, MOVE_MARK_MENU__MSG\9'Alt+M',     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
      buildmenuitem menuname, 80, 8002, OVERLAY_MARK_MENU__MSG\9'Alt+O',  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
      buildmenuitem menuname, 80, 8003, ADJUST_MARK_MENU__MSG\9'Alt+A',   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
      buildmenuitem menuname, 80, 8004, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8005, UNMARK_MARK_MENU__MSG\9'Alt+U',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
   else  -- Build No-mark pop-up
      'MH_gotoposition'
      ch = substr(textline(.line), .col, 1)
      gray_if_space = 16384*(ch=' ' | not .line)
      buildmenuitem menuname, 80, 8000, MARK_WORD_MENU__MSG\9'Alt+W',      'MARKWORD'MARK_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKWORD, gray_if_space)
      buildmenuitem menuname, 80, 8001, MARK_TOKEN_MENU__MSG\9'CtrL+W',    'MARKTOKEN'MARK_TOKEN_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKTOKEN, gray_if_space)
      buildmenuitem menuname, 80, 8002, FIND_TOKEN_MENU__MSG,              'FINDWORD'FIND_TOKEN_MENUP__MSG, 0, mpfrom2short(HP_POPUP_FINDTOKEN, gray_if_space)
      buildmenuitem menuname, 80, 8003, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8004, UPCASE_WORD_MENU__MSG\9'Ctrl+F1',  'key 1 c+f1'UPCASE_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_UPCASEWORD, gray_if_space)
      buildmenuitem menuname, 80, 8005, LOCASE_WORD_MENU__MSG\9'Ctrl+F2',  'key 1 c+f2'LOCASE_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_LOCASEWORD, gray_if_space)
      buildmenuitem menuname, 80, 8006, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8007, CENTER_LINE_MENU__MSG\9'Shift+F5', 'key 1 s+f5'CENTER_LINE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_CENTERLINE, 0)
      buildmenuitem menuname, 80, 8008, TOP_LINE_MENU__MSG,                'newtop'TOP_LINE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_TOP, 0)
      buildmenuitem menuname, 80, 8009, PASTE_C_MENU__MSG,    PASTE_C_MENUP__MSG,   17+64, mpfrom2short(HP_EDIT_PASTEMENU, 0)
      buildmenuitem menuname, 80, 8010, PASTE_C_MENU__MSG,   'Paste C'PASTE_C_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEC, 0)
      buildmenuitem menuname, 80, 8011, PASTE_L_MENU__MSG,   'Paste'PASTE_L_MENUP__MSG,     0, mpfrom2short(HP_EDIT_PASTE, 0)
      buildmenuitem menuname, 80, 8012, PASTE_B_MENU__MSG,   'Paste B'PASTE_B_MENUP__MSG,   32769, mpfrom2short(HP_EDIT_PASTEB, 0)
   endif
compile endif -- INCLUDE_STANDARD_CONTEXT_MENU
compile if not VANILLA
tryinclude 'mymsemnu.e'  -- For user-added configuration
compile endif
   showmenu menuname,1
compile if DEFAULT_PASTE = 'C'
   'cascade_popupmenu 8009 8010'  -- Paste cascade; default is Paste (character mark)
compile elseif DEFAULT_PASTE = 'B'
   'cascade_popupmenu 8009 8012'  -- Paste cascade; default is Paste Block
compile else
   'cascade_popupmenu 8009 8011'  -- Paste cascade; default is Paste Lines
compile endif

#define ETK_FID_POPUP          50

defc cascade_popupmenu
   parse arg menuid defmenuid .
   menuitem = copies(\0, 16)  -- 2 bytes ea. pos'n, style, attribute, identity; 4 bytes submenu hwnd, long item
   hwndp= dynalink32( 'PMWIN',
                      '#899',                -- ordinal for Win32WindowFromID
                      gethwndc(EPMINFO_EDITCLIENT) ||
                      atol(ETK_FID_POPUP) )
   if not windowmessage(1,
                        hwndp,
                        386,                  -- x182, MM_QueryItem
                        menuid + 65536,
                        ltoa(offset(menuitem) || selector(menuitem), 10) )
   then return; endif
   hwnd = substr(menuitem, 9, 4)

   call dynalink32('PMWIN',
                   '#874',     -- Win32SetWindowBits
                    hwnd          ||
                    atol(-2)      ||  -- QWL_STYLE
                    atol(64)      ||  -- MS_CONDITIONALCASCADE
                    atol(64) )        -- MS_CONDITIONALCASCADE
   if defmenuid<>'' then  -- Default menu item
      call windowmessage(1,
                         ltoa(hwnd,10),
                         1074,                  -- x432, MM_SETDEFAULTITEMID
                         defmenuid, 0)  -- Make arg(2) the default menu item
   endif

; The StatWndMouseCmd and MsgWndMouseCmd are invoked with the following argument
; when the status or message windows receive the following event:
; '1 SECONDCLK 0' - Double-click MB1 (in any shift combination).
; 'CONTEXTMENU'   - The context menu action (by default, single-click MB2) is executed .
; 'CHORD'         - Both mouse buttons are pressed together.

defc StatWndMouseCmd
   if arg(1)='1 SECONDCLK 0' then
      'versioncheck'
   elseif arg(1)='CONTEXTMENU' then
      'configdlg'
   endif

defc MsgWndMouseCmd
   if arg(1)='1 SECONDCLK 0' then
      'messagebox'
   elseif arg(1)='CONTEXTMENU' then
      'tagscan'
   endif

compile if EPM_POINTER = 'SWITCH'
defc SetMousePointer
   universal vEPM_POINTER
   if verify(arg(1), '0123456789') then  -- contained a non-numeric character
      sayerror INVALID_NUMBER__MSG
   else
      vEPM_POINTER = arg(1)
      mouse_setpointer vEPM_POINTER
   endif
compile endif
