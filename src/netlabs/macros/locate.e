/****************************** Module Header *******************************
*
* Module Name: locate.e
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

; Undocumented:
; display -8 ==> messages go only to the msg line, not to the msg box.
; display 8  ==> reenables messages from a previous display -8
; The rest is documented in epmtech.inf.

; xcom l has some bugs:
; -  It doesn't move the cursor.
; -  With option 'r', it also finds the search string at the cursor.
; -  In replace mode, it moves the cursor, but by the length on the search
;    string, not by the replace string.

; ---------------------------------------------------------------------------

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'LOCATE.E'

const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
compile if not defined(LOCATE_CIRCLE_STYLE)
   --LOCATE_CIRCLE_STYLE = 1  -- changed by aschn
   LOCATE_CIRCLE_STYLE = 5         -- (1)     filled oval
compile endif
compile if not defined(LOCATE_CIRCLE_COLOR1)
   --LOCATE_CIRCLE_COLOR1 = 16777220  -- changed by aschn
   LOCATE_CIRCLE_COLOR1 = 16777231 -- (16777220) complementary
compile endif
compile if not defined(LOCATE_CIRCLE_COLOR2)
   -- for styles 2 and 4 only
   --LOCATE_CIRCLE_COLOR2 = 16777218  -- changed by aschn
   LOCATE_CIRCLE_COLOR2 = 16777216 -- (16777218) complementary
compile endif
compile if not defined(HIGHLIGHT_COLOR)
   HIGHLIGHT_COLOR = 14            --         This must be set to enable circle colors
compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   include 'stdconst.e'

   EA_comment 'This defines macros for saerch operations.'
compile endif

; ---------------------------------------------------------------------------
defmodify             -- This stops the modification dialog for grep output "files"  -- JBS
   if leftstr( .filename, 17) = '.Output from grep' then
      .modify = 0
      .autosave = 0
   endif

; ---------------------------------------------------------------------------
defproc ProcessSearchOptions( user_options)
   universal default_search_options

   -- Set default_options to uppercase
   default_options = upcase( default_search_options)

   -- Switch to All if Mark is default and no text marked, but don't disable
   -- 'M' from user_options to make it work as expected.
   if not FileIsMarked() then
      -- Remove 'M' from default_options
      do forever
         pv = verify( default_options, 'M', 'M')  -- 2nd arg is charlist to find
         if pv = 0 then
            leave
         endif
         default_options = delstr( default_options, pv, 1)
      enddo
   endif

   -- Remove 'T' and 'B' from default_options, because searchdlg won't
   -- set these checkboxes. Other options are recognized. This is useful
   -- to avoid confusion, because searchdlg will call either defc locate
   -- or defc change. These commands will add default_search_options,
   -- even T or B, while the user would think, he hasn't selected them.
   -- TODO: Better set checkboxes when opening the dialog or when changing
   --       default options.
   if pos( 'D', upcase( user_options)) then  -- if called from SearchDlg
      do forever
         pv = verify( upcase(default_options), 'TB', 'M')
         if pv = 0 then
            leave
         endif
         default_options = delstr( default_options, pv, 1)
      enddo
   endif

   -- Remove 'T', 'B' and 'U' from default_options if the new option 'U' is
   -- used. This new option can be added to tell the locate command to remove
   -- 'T' and 'B'. E.g. the 'All' cmd doesn't work with B' or 'T'.
   if pos( 'U', upcase(user_options)) then  -- if 'U' is used
      -- Remove 'U' from user_options
      do forever
         pv = verify( upcase(user_options), 'U', 'M')
         if pv = 0 then
            leave
         endif
         user_options = delstr( user_options, pv, 1)
      enddo
      -- Remove 'T' and 'B' from default_options
      do forever
         pv = verify( default_options, 'TB', 'M')
         if pv = 0 then
            leave
         endif
         default_options = delstr( default_options, pv, 1)
      enddo
   endif

   -- Build search_options. The last option wins.
   -- Insert default_search_options just before supplied options (if any)
   -- so the supplied options will take precedence.
   search_options = upcase(default_options''user_options)

   -- Append 'N' to give a message how many changes, if 'Q' not specified
   -- and if all should be changed.
   if pos( '*', search_options) &  -- if e.g. called from SearchDlg
      not pos( 'Q', search_options) then
      search_options = search_options'N'
   endif

   -- Remove multiple and excluding options and spaces (not required)
   ExcludeList = '+- FR BT AM EC GXW'    -- for every word in this list: every char excludes each other
   -- Other options: '* K ^ N D'
   rest = search_options
   search_options = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char of rest
      -- Remove all spaces
      if next = ' ' then
         iterate
      elseif pos( next, rest) = 0 then   -- if not found in rest
         -- Find excluding options
         ExcludeWrd = ''
         do w = 1 to words(ExcludeList)
            wrd = word( ExcludeList, w)
            if pos( next, wrd) then
               ExcludeWrd = wrd          -- ExcludeWrd = word of ExcludeList where next belongs to
               leave
            endif
         enddo
         if not verify( rest, ExcludeWrd, 'M') then    -- if rest doesn't contain chars of ExcludeWrd
            search_options = search_options''next      -- append next
         endif
      endif
   enddo

   return search_options

; ---------------------------------------------------------------------------
defproc ProsessSearchPos( search_options, PreviousSearchOptions,
                          search_string, PreviousSearchString,
                          fid, SearchMode)
   universal lastsearchpos

   parse value lastsearchpos with LastLine LastCol LastFid LastSearchLen LastSearchMode
   fForeward = lastpos( 'F', search_options) > lastpos( 'R', search_options)
   fDownward = lastpos( '+', search_options) > lastpos( '-', search_options)

   -- Determine a FindNext if only the search direction was changed
   fFindNext = 0
   do i = 1 to 1
      -- Remove FR+- from previous and next search options
      PrevOpts = PreviousSearchOptions
      do forever
         pv = verify( PrevOpts, 'FR+-', 'M')
         if pv = 0 then
            leave
         endif
         PrevOpts = delstr( PrevOpts, pv, 1)
      enddo
      NextOpts = search_options
      do forever
         pv = verify( NextOpts, 'FR+-', 'M')
         if pv = 0 then
            leave
         endif
         NextOpts = delstr( NextOpts, pv, 1)
      enddo

      if fid <> LastFid then
         leave
      endif
      if LastLine LastCol <> .line .col then
         leave
      endif
      if PreviousSearchString <> search_string then
         leave
      endif
      if PrevOpts <> NextOpts then
         leave
      endif

      fFindNext = 1
   enddo

   fMoveCursor = 0

   -- Handle FindNext specially
   if fFindNext then

      -- Remove 'T' and 'B' for the search execution (not from LastSearchArgs)
      do forever
         pv = verify( search_options, 'TB', 'M')
         if pv = 0 then
            leave
         endif
         search_options = delstr( search_options, pv, 1)
      enddo

      -- Move cursor to not find the just found string again
      fMoveCursor = 1
   endif

   -- Bug in xcom l: reverse search finds also string right of cursor
   if not fForeward then
      fMoveCursor = 1
   endif

   -- Change should process the string at cursor. The cursor pos may result
   -- from a previous locate.
   -- If there is no string to change at the cursor, it processes the next
   -- string. For that no cursor move is required.
   if SearchMode = 'c' then
      fMoveCursor = 0
   endif

   --dprintf( 'fMoveCursor = 'fMoveCursor', fFindNext = 'fFindNext)

   fSearch = 1
   -- Move cursor to not find the string at cursor (again)
   if fMoveCursor then
      if LastSearchLen = '' then
         LastSearchLen = 0
      endif
      if fForeward then  -- must be a FindNext
         -- Foreward: move amount of LastSearchLen right
         next = .col + LastSearchLen
         if next > length( textline(.line)) + 1 then
            if fDownward then
               if .line < .last then
                  down
                  .col = 1
               else
                  fSearch = 0  -- can't move down at the bottom
               endif
            else
               if .line > 1 then
                  up
                  .col = 1
               else
                  fSearch = 0  -- can't move up at the top
               endif
            endif
         else
            .col = next
         endif
      else
         -- Backward: move 1 left
         next = .col - 1
         if next < 1 then
            if fDownward then
               if .line < .last then
                  down
                  .col = min( length( textline(.line)) + 1, MAXCOL)
               else
                  fSearch = 0  -- can't move down at the bottom
               endif
            else
               if .line > 1 then
                  up
                  .col = min( length( textline(.line)) + 1, MAXCOL)
               else
                  fSearch = 0  -- can't move up at the top
               endif
            endif
         else
            .col = next
         endif
      endif
   endif

   if not fSearch then
      return -1
   else
      return search_options
   endif

; ---------------------------------------------------------------------------
; LastSearchArgs and LastChangeArgs are no longer universals. To make them
; global across all EPM windows, they are saved in NEPMD.INI only.
; ---------------------------------------------------------------------------
defproc GetLastSearchArgs
   universal nepmd_hini
   KeyPathSearch = '\NEPMD\User\Search\LastSearchArgs'
   LastSearchArgs = NepmdQueryConfigValue( nepmd_hini, KeyPathSearch)
   return LastSearchArgs

; ---------------------------------------------------------------------------
defproc GetLastChangeArgs
   universal nepmd_hini
   KeyPathChange = '\NEPMD\User\Search\LastChangeArgs'
   LastChangeArgs = NepmdQueryConfigValue( nepmd_hini, KeyPathChange)
   return LastChangeArgs

; ---------------------------------------------------------------------------
defproc SetLastSearchArgs
   universal nepmd_hini
   KeyPathSearch = '\NEPMD\User\Search\LastSearchArgs'
   LastSearchArgs = arg(1)
   rcx = NepmdWriteConfigValue( nepmd_hini, KeyPathSearch, LastSearchArgs)
   return

; ---------------------------------------------------------------------------
defproc SetLastChangeArgs
   universal nepmd_hini
   KeyPathChange = '\NEPMD\User\Search\LastChangeArgs'
   LastChangeArgs = arg(1)
   rcx = NepmdWriteConfigValue( nepmd_hini, KeyPathChange, LastChangeArgs)
   return

; ---------------------------------------------------------------------------
; Syntax: locate !<search_string>[!<user_options>]
;         The first char will be taken as delimitter, in this case '!'.
;
; New: Without args, a FindNext will be executed.
;
; Added a new search option: 'U'. This will replace any occurance of
; 'T' and 'B' in default_search_options for this locate command.
;
; Moved from STDCMDS.E
; Note:  this DEFC also gets executed by the slash ('/') command and by the
; search dialog. The search dialog adds option 'D'.
defc RepeatFind, L, Locate
   universal default_search_options
   universal lastsearchpos

   sayerror 0  -- delete previous message from messageline
   LastSearchArgs = GetLastSearchArgs()

   args = strip( arg(1), 'L')
   if args = '' then  -- If no args, query args
      args = LastSearchArgs
      -- Process the parsing of args again to recognize a possible change of
      -- default_search_options in the meantime.
   endif

   delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (delim)search_string(delim)user_options
   user_options = strip( user_options, 'T', delim)

   PreviousSearchArgs = LastSearchArgs  -- save old value to determine later
                                        -- if it has to be rewritten to ini.
   pdelim = substr( PreviousSearchArgs, 1, 1)  -- get 1st delimiter
   parse value PreviousSearchArgs with (pdelim)PreviousSearchString(pdelim)PreviousSearchOptions

   LastChangeArgs = GetLastChangeArgs()
   cdelim = substr( LastChangeArgs, 1, 1)  -- get 1st delimiter
   parse value LastChangeArgs with (cdelim)cSearchString(cdelim)cReplaceString(cdelim)cSearchOptions

   getfileid fid

   -- Prepend default options and normalize search options
   search_options = ProcessSearchOptions( user_options)

   -- Build list of search args with options, last option wins.
   -- Save the universal var here. Later ProsessSearchPos changes
   -- search_options if required.
   SearchArgs = delim''search_string''delim''search_options
   --dprintf( '--- SearchArgs = 'SearchArgs', arg(1) = 'arg(1))
   --dprintf( 'PreviousSearchArgs = 'PreviousSearchArgs)

   -- Save last args
   call SetLastSearchArgs( SearchArgs)
   if search_string <> cSearchString then
      -- Reset LastChangeArgs if search has changed
      --dprintf( 'Reset LastChangeArgs')
      call SetLastChangeArgs( '')
   endif

   -- The rest is similar for both 'locate' and 'change'

   -- Pos from before the search and maybe move
   startline = .line
   startcol  = .col
   call psave_pos( savedpos)
   SearchMode = 'l'

   -- Maybe move cursor and remove T and B search options for a FindNext
   search_options = ProsessSearchPos( search_options, PreviousSearchOptions,
                                      search_string, PreviousSearchString,
                                      fid, SearchMode)
   fSearch = 1
   if search_options = -1 then
      -- Omit search at the top or at the bottom
      fSearch = 0
   else
      -- search_options may be changed by ProsessSearchPos
      SearchArgs = delim''search_string''delim''search_options
   endif

   if fSearch then
      display -8  -- suppress writing to MsgBox
      'xcom l 'SearchArgs
      lrc = rc
      display 8

      -- Restore pos if not found (required?)
      if lrc <> 0 then
         -- Go to pos before the search, e.g. stop at previous found string
         call prestore_pos( savedpos)
      endif
   endif

   -- Give error message if search was omited
   if not fSearch then
      lrc = -273  -- String not found
      display -8  -- suppress writing to MsgBox
      sayerror sayerrortext( lrc)  -- The same as: 'SayError -273'
      display 8
   endif

   -- Highlight it and maybe scroll to cursor pos
   if lrc = 0 then
      -- SearchLen will be queried by getpminfo( EPMINFO_LSLENGTH)
      call highlight_match()  -- scrolls always
   else
      .line = .line           -- maybe scroll to ensure that cursor is visible
   endif

   -- Save last searched pos, file and search mode
   thissearchpos = .line .col fid length( search_string) 'l'
   --dprintf( 'thissearchpos = 'thissearchpos', lastsearchpos = 'lastsearchpos)
   lastsearchpos = thissearchpos

   rc = lrc  -- does hightlight_match change rc?

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc RepeatChange, C, Change
   universal default_search_options
;   universal search_len
   universal lastsearchpos
   universal stay  -- if 1, then restore pos even after a successful change

   sayerror 0  -- delete previous message from messageline
   LastChangeArgs = GetLastChangeArgs()
   LastSearchArgs = GetLastSearchArgs()

   args = strip( arg(1), 'L')
   if args = '' then   -- If no args, query lastchangeargs
      args = LastChangeArgs
      -- Process the parsing of args again to recognize a possible change of
      -- default_search_options in the meantime.
   endif

   delim = substr( args, 1, 1)  -- get 1st delimiter
   p2 = pos( delim, args, 2)    -- check 2nd delimiter of 2 or 3
   if not p2 then
      sayerror NO_REP__MSG  -- 'No replacement string specified'
      return
   endif
   parse value args with (delim)search_string(delim)replace_string(delim)user_options
   user_options = strip( user_options, 'T', delim)

   PreviousChangeArgs = LastChangeArgs  -- save old value to determine later
   PreviousSearchArgs = LastSearchArgs  -- if it has to be rewritten to ini.
   pdelim = substr( PreviousChangeArgs, 1, 1)  -- get 1st delimiter
   parse value PreviousChangeArgs with (pdelim)PreviousSearchString(pdelim)PreviousReplaceString(pdelim)PreviousSearchOptions

   getfileid fid

   -- Prepend default options and normalize search options
   search_options = ProcessSearchOptions( user_options)

   -- Build list of change args with options, last option wins.
   -- Save the universal var here. Later ProsessSearchPos changes
   -- search_options if required.
   ChangeArgs = delim''search_string''delim''replace_string''delim''search_options
   -- Set LastSearchArgs as well, to use first Ctrl+F and then Ctrl+C for to
   -- operate on the same search_string. Even a ChangeNext should synchronize it.
   SearchArgs = delim''search_string''delim''search_options
   --dprintf( '--- ChangeArgs = 'ChangeArgs', arg(1) = 'arg(1))
   --dprintf( 'PreviousChangeArgs = 'PreviousChangeArgs', PreviousSearchArgs = 'PreviousSearchArgs)

   -- Save last args
   call SetLastChangeArgs( ChangeArgs)
   call SetLastSearchArgs( SearchArgs)

   -- Pos from before the search and maybe move
   startline = .line
   startcol  = .col
   call psave_pos( savedpos)
   SearchMode = 'c'

   -- Remove T and B search options for a FindNext
   search_options = ProsessSearchPos( search_options, PreviousSearchOptions,
                                      search_string, PreviousSearchString,
                                      fid, SearchMode)

   fSearch = 1
   if search_options = -1 then  -- never true for 'change'
      -- Omit search at the top or at the bottom
      fSearch = 0
   else
      -- search_options may be changed by ProsessSearchPos
      ChangeArgs = delim''search_string''delim''replace_string''delim''search_options
   endif


   if fSearch then
      display -8
      'xcom c 'ChangeArgs
      lrc = rc
      display 8

      -- Restore pos if not found (required?)
      if lrc <> 0 then
         -- Go to pos before the search, e.g. stop at previous found string
         call prestore_pos( savedpos)
      endif
   endif

   -- Give error message if search was omitted
   if not fSearch then  -- fSearch is always 1 for 'change'
      lrc = -273  -- String not found
      display -8  -- suppress writing to MsgBox
      sayerror sayerrortext( lrc)  -- The same as: 'SayError -273'
      display 8
   endif

   -- Highlight it and maybe scroll to cursor pos
   if lrc = 0 then
      --call highlight_match()  -- gives wrong value
      -- SearchLen can be queried for a Search action by getpminfo( EPMINFO_LSLENGTH).
      -- But getpminfo( EPMINFO_LSLENGTH) gives the value for the search string,
      -- not for the change string.
      -- Therefore estimate its value here to submit it as arg to highlight_match().
      -- This likely gives a wrong result for a grep search.
      SearchLen = length( replace_string)
      call highlight_match( .line .col SearchLen)

      -- Restore pos after change command if stay = 1
      if stay then
         call prestore_pos( savedpos)
      endif
   else
      .line = .line           -- maybe scroll to ensure that cursor is visible
      'HighlightCursor'
   endif

   -- Save last searched pos, file and search mode
   thissearchpos = .line .col fid length( replace_string) 'c'
   --dprintf( 'thissearchpos = 'thissearchpos', lastsearchpos = 'lastsearchpos)
   lastsearchpos = thissearchpos

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E
; Highlight a "hit" after a Locate command or Repeat_find operation.
; Never used its previous arg(1) = search_len in 6.03b.
; New: optional arg(1) = <line> <col> <len>
defproc highlight_match

   if rc then  -- if not found; rc was set from last 'c'|'l'|repeat_find
      return
   endif
   savedrc = rc

   -- Optionally try to scroll to a fixed position on screen.
   -- This must come before drawing the circle.
   'ScrollAfterLocate'

   parse arg args
   if args <> '' then
      parse arg line col len
      if col = '' then
         -- This must be the previously used syntax: arg(1) = search_len
         args = ''
      endif
   endif
   if args = '' then
      line = .line
      col  = GetPmInfo( EPMINFO_SEARCHPOS)
      len  = GetPmInfo( EPMINFO_LSLENGTH)
   endif

   -- Draw a circle around the found string
   CircleIt LOCATE_CIRCLE_STYLE,
      line,
      col,
      col + len - 1,
      LOCATE_CIRCLE_COLOR1,
      LOCATE_CIRCLE_COLOR2

   rc = savedrc
   return

; ---------------------------------------------------------------------------
; Callable with 'postme'. Required for GlobalFind.
defc HighlightMatch
   call highlight_match(arg(1))

; ---------------------------------------------------------------------------
defc CircleIt
   parse arg line startcol endcol
   CircleIt LOCATE_CIRCLE_STYLE, line, startcol, endcol,
            LOCATE_CIRCLE_COLOR1, LOCATE_CIRCLE_COLOR2

; ---------------------------------------------------------------------------
; Try to scroll to a fixed position on screen.
defc ScrollAfterLocate
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\AfterLocate'
   IniValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   AmountOfLines = 0
   if IsNum( IniValue) then
      AmountOfLines = IniValue
   endif
   if AmountOfLines <> 0 then
      oldline = .line
      if AmountOfLines > 0 then
         .cursory = Min( AmountOfLines, .windowheight)          -- AmountOfLines from top
      elseif AmountOfLines < 0 then
         .cursory = Max( 1, .windowheight + AmountOfLines + 1)  -- AmountOfLines from bottom
      endif
      .line = oldline
   endif

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
; Can also be called with C or F as arg to repeat last change or find.
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: searchdlg       syntax:   searchdlg [next]               ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal search & replace dlg. ³
³                   This is done by posting a EPM_POPCHANGEDLG message to the³
³                   EPM Book window.                                         ³
³                   if the [next] param = 'F'  a find next will take place   ³
³                   if the [next] param = 'C'  a change next will take place ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SearchDlg
   universal default_search_options

   parse value upcase(arg(1)) with uparg .

   if uparg = 'C' then
      'RepeatChange'
   elseif uparg = 'F' then
      'RepeatFind'

   else
      -- The application will free the buffer allocated by this macro
      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5128,               -- EPM_POPCHANGEDLG
                          0,
                          put_in_buffer(default_search_options))
   endif

; ---------------------------------------------------------------------------
; Returns '+' or '-'.
defproc GetSearchDirection
   universal default_search_options
   ret = '+'

   args = GetLastSearchArgs()
   s_delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (s_delim)s_search_string(s_delim)s_user_options
   s_user_options = strip( s_user_options, 'T', s_delim)

   -- Analyze only last search options, not last change options
   Minuspos = lastpos( '-', default_search_options''s_user_options)
   Pluspos  = lastpos( '+', default_search_options''s_user_options)

   if MinusPos > PlusPos then
      ret = '-'
   endif
   return ret

; ---------------------------------------------------------------------------
; From EPMSMP\REVERSE.E
; Search options for specifying the direction:
;    F  start searching from the start of line
;    R  start searching from the end of line
;    +  start searching from the start of text
;    -  start searching from the end of text
; The relevant options are + and -, F or R is set automatically.
;
; Original by Larry Margolis:
;    Repeat the previous Locate, but in the reverse direction.
;    E.g., if you search for a string that you know exists, but
;    it's not found before the end of the file, press Ctrl+minus
;    to repeat the search for the same string looking from the
;    cursor position to the beginning of the file.
; Changed:
;    Toggles the search direction (options +F or -R) without any
;    following locate action.
;    Doesn't produce an error msg anymore if oldsearch = empty.
; This has no effect on the settings of the Search dialog.
defc ToggleSearchDirection
   universal default_search_options

   args = GetLastSearchArgs()
   s_delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (s_delim)s_search_string(s_delim)s_user_options
   s_user_options = strip( s_user_options, 'T', s_delim)

   -- Analyze only last search options, not last change options
   Minuspos = lastpos( '-', default_search_options''s_user_options)
   Pluspos  = lastpos( '+', default_search_options''s_user_options)

   -- Append +F or -R
   if Minuspos > Pluspos then  -- in searchoptions: the last option wins
      'SearchDirection +'
      'SayHint Changed search direction to: forward.'
   else
      'SearchDirection -'
      'SayHint Changed search direction to: backward.'
   endif

; ---------------------------------------------------------------------------
; Set SearchDirection to foreward (arg = 'F' or '+') or backward (arg = 'R'
; or '-').
defc SearchDirection
   universal default_search_options

   Direction = upcase( arg(1))
   if Direction = '' then
      return
   elseif Direction = 'F' then
      Direction = '+'
   elseif Direction = 'R' then
      Direction = '-'
   endif

   LastSearchArgs = GetLastSearchArgs()
   s_delim = substr( LastSearchArgs, 1, 1)  -- get 1st delimiter
   parse value LastSearchArgs with (s_delim)s_search_string(s_delim)s_user_options
   s_user_options = strip( s_user_options, 'T', s_delim)

   LastChangeArgs = GetLastChangeArgs()
   c_delim = substr( LastChangeArgs, 1, 1)  -- get 1st delimiter
   parse value LastChangeArgs with (c_delim)c_search_string(c_delim)c_replace_string(c_delim)c_user_options
   c_user_options = strip( c_user_options, 'T', c_delim)

   -- Remove every ( |+|-|F|R) from user_options
   --    Note: translate doesn't allow '' as 4th parameter (pad).
   rest = s_user_options
   s_user_options = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char
      if verify( upcase(next), ' +-FR', 'N') then  -- if no match
         s_user_options = s_user_options''next
      endif
   enddo
   rest = c_user_options
   c_user_options = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char
      if verify( upcase(next), ' +-FR', 'N') then  -- if no match
         c_user_options = c_user_options''next
      endif
   enddo

   -- Append +F or -R
   if Direction = '+' then
      s_user_options = s_user_options'+F'
      c_user_options = c_user_options'+F'
   elseif Direction = '-' then
      s_user_options = s_user_options'-R'
      c_user_options = c_user_options'-R'
   endif

   SearchArgs = s_delim''s_search_string''s_delim''s_user_options
   ChangeArgs = c_delim''c_search_string''c_delim''c_replace_string''c_delim''c_user_options
   -- Write new value only if old value was set
   if LastSearchArgs <> '' & s_delim <> '' then
      parse value LastSearchArgs with (s_delim)SearchString(s_delim)SearchOptions
      if SearchOptions <> '' then
         call SetLastSearchArgs( SearchArgs)
      endif
   endif
   if LastChangeArgs <> '' & c_delim <> '' then
      parse value LastChangeArgs with (c_delim)SearchString(c_delim)ReplaceString(c_delim)SearchOptions
      if SearchOptions <> '' then
         call SetLastChangeArgs( ChangeArgs)
      endif
   endif

; ---------------------------------------------------------------------------
defc FindNext
   'SearchDirection +'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc FindPrev
   'SearchDirection -'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc ChangeFindNext
   'SearchDirection +'
   'RepeatChange'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc ChangeFindPrev
   'SearchDirection -'
   'RepeatChange'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc RepeatFindAllFiles, RingFind

   LastSearchArgs = GetLastSearchArgs()
   delim = substr( LastSearchArgs, 1, 1)  -- get 1st delimiter
   parse value LastSearchArgs with (delim)search_string(delim)user_options
   user_options = strip( user_options, 'T', delim)

   -- Get current search direction
   Minuspos = lastpos( '-', user_options)
   Pluspos  = lastpos( '+', user_options)
   if Minuspos > Pluspos then
      fForward = 0
   else
      fForward = 1
   endif

   -- Always search in entire files, not in mark
   if pos( 'M', user_options) > 0 | pos( 'A', user_options) = 0 then
      -- Remove 'M' from user_options
      do forever
         pv = verify( upcase( user_options), 'M', 'M')
         if pv = 0 then
            leave
         endif
         s_user_options = delstr( user_options, pv, 1)
      enddo
      -- Append 'A'
      user_options = user_options'A'
      call SetLastSearchArgs( delim''search_string''delim''user_options)
   endif

   -- Get LastSearchArgs from ini, remove 'T' and 'B' options
   'RepeatFind'

   if rc = 0 then
      -- Next occurrence found in current file
      return
   endif

   -- Not found in current file: search in other files
   getfileid fid
   startfid = fid
   do forever

      -- Next file
      if fForward = 1 then
         nextfile
      else
         prevfile
      endif
      getfileid fid
      activatefile fid

      call psave_pos( savedpos)
      -- Start from top of file
      if fForward = 1 then
         top
         .col = 1
      else
         bottom
         endline
      endif

      -- Get LastSearchArgs from ini, remove 'T' and 'B' options
      'RepeatFind'

      if rc = 0 then
         -- Found
         'HookAdd selectonce postme postme HighlightMatch'  -- additionally required to highlight after file switching
         if fid = startfid then
            'SayHint String only found in this file.'
         else
            sayerror 0  -- flush the message
         endif
         leave
      else
         -- Not found
         call prestore_pos( savedpos)
         if fid = startfid then
            'SayError String not found in any file of the ring.'
            leave
         else
            -- Search next file
         endif
      endif

   enddo
   activatefile fid

; ---------------------------------------------------------------------------
defc RepeatChangeAllFiles, RingChange
   universal stay

   LastChangeArgs = GetLastChangeArgs()
   delim = substr( LastChangeArgs, 1, 1)  -- get 1st delimiter
   parse value LastChangeArgs with (delim)search_string(delim)replace_string(delim)user_options
   user_options = strip( user_options, 'T', delim)
   SavedOptions = user_options

   -- Get current search direction
   Minuspos = lastpos( '-', user_options)
   Pluspos  = lastpos( '+', user_options)
   if Minuspos > Pluspos then
      fForward = 0
   else
      fForward = 1
   endif

   -- Always search in entire files, not in mark
   if pos( 'M', user_options) > 0 | pos( 'A', user_options) = 0 then
      -- Remove 'M' from user_options
      do forever
         pv = verify( upcase( user_options), 'M', 'M')
         if pv = 0 then
            leave
         endif
         user_options = delstr( user_options, pv, 1)
      enddo
      -- Append 'A'
      user_options = user_options'A'
   endif

   -- Replace all occurrences, not only next
   if pos( '*', user_options) = 0 then
      -- Append '*'
      user_options = user_options'*'
   endif

   -- Write LastChangeArgs to ini
   if user_options <> SavedOptions then
      call SetLastChangeArgs( delim''search_string''delim''replace_string''delim''user_options)
   endif

   getfileid fid
   startfid = fid
   ChangeCount = 0
   do forever

      call psave_pos( savedpos)
      -- Start from top of file
      if fForward = 1 then
         top
         .col = 1
      else
         bottom
         endline
      endif

      -- Get LastChangeArgs from ini, remove 'T' and 'B' options
      'RepeatChange'

      if rc = 0 then
         -- Found
         ChangeCount = ChangeCount + 1
         if stay then
            call prestore_pos( savedpos)
         endif
      else
         -- Not found
         call prestore_pos( savedpos)
      endif

      -- Next file
      if fForward = 1 then
         nextfile
      else
         prevfile
      endif

      getfileid fid
      if fid = startfid then
         leave
      endif

   enddo

   if ChangeCount = 1 then
      files = 'file.'
   else
      files = 'files.'
   endif
   'SayHint String changed in' ChangeCount files

; ---------------------------------------------------------------------------
defc FindNextAllFiles
   'SearchDirection F'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
defc FindPrevAllFiles
   'SearchDirection R'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
defc FindMark
   if FileIsMarked() then
      -- Get active mark coordinates and fileid
      getmark first_line, last_line, first_col, last_col, mark_fileid
      if last_line <> first_line then
         -- Take up to one line
         last_line = first_line
         endline
         last_col = .col
      endif
      searchstring = substr( textline( first_line ), first_col, last_col - first_col + 1)
      if searchstring <> '' then
         'l '\1''searchstring
      endif
   else
      sayerror -280  -- Text not marked
   endif

; ---------------------------------------------------------------------------
; Find word under cursor -- if arg(1) > 0: -- under pointer.
defc FindWord
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
   endif
   lrc = 1
   startline = .line
   startcol  = .col
   call pend_word()
   lastcol = .col
   call pbegin_word()
   firstcol = .col
   -- Start search after current word
   .col = lastcol + 1
   searchstring = substr( textline( startline), firstcol, lastcol - firstcol + 1)
   if searchstring <> '' then
      'l '\1''searchstring
      lrc = rc
   endif
   if lrc <> 0 then
      .col = startcol
   endif

; ---------------------------------------------------------------------------
; Moved from MOUSE.E
; Find identifier under cursor -- if arg(1) > 0: -- under pointer.
defc FindToken
   -- If arg(1) specified and > 0: Set cursor to pos of pointer.
   if arg(1) then
      'MH_gotoposition'
   endif
   lrc = 1
   call psave_pos( savedpos)
   if find_token( startcol, endcol) then
      -- find_token returns first and last col of the found string. Therefore
      -- search shall start from 1 col behind.
      .col = endcol + 1
      -- The standard cmd 'locate' won't set standard rc. The standard 'locate'
      -- always returns rc = ''.
      -- Standard commands that don't change rc (are there more?):
      --    'locate', 'edit'
      -- This is fixed in NEPMD.
      -- The standard commands 'quit', 'save', 'name',... do change rc.
      -- Therefore 'locate' now calls the proc locate, that sets rc correctly.
      -- rc is the rc from 'xcom locate'.
      -- (rc is a universal var, that doesn't need the universal definition.)
      'l '\1''substr( textline( .line), startcol, (endcol - startcol) + 1)
      lrc = rc
   endif
   --sayerror 'defc findword: lrc = 'lrc
   if lrc <> 0 then  -- if not found
      call prestore_pos( savedpos)
   endif

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E
defproc find_token( var startcol, var endcol)  -- find a token around the cursor.
   if arg(3)='' then
      token_separators = ' ~`!%^&*()-+=][{}|\:;?/><,''"'\t
   else
      token_separators = arg(3)
   endif
   if arg(4)='' then
      diads = '-> ++ -- << >> <= >= && || += -= *= /= %= ª= &= |= :: /* */'
   else
      diads = arg(4)
   endif
   getline line
   len = length( line)
   if .col > len | pos( substr( line, .col, 1), ' '\t) then
      return  -- Past end of line, or over whitespace
   endif
   endcol = verify( line, token_separators, 'M', .col)
   if endcol = .col then  -- On an operator.
      startcol = endcol
      if wordpos( substr( line, startcol, 2), diads) then
         endcol = endcol + 1  -- On first character
      elseif .col > 1 then
         if wordpos( substr( line, endcol-1, 2), diads) then
            startcol = startcol - 1  -- -- On last character
         endif
      endif
      return 2
   endif
   if endcol then
      endcol = endcol - 1
   else
      endcol = len
   endif
   startcol = verify( reverse( line), token_separators, 'M', len - .col + 1)
   if startcol then
      startcol = len - startcol + 2
   else
      startcol = 1
   endif
   return 1

; ---------------------------------------------------------------------------
defc ShowSearch
   getsearch cursearch

   Next = 'Last search = ['cursearch'], last search args = ['GetLastSearchArgs()']' ||
          ', last change args = ['GetLastChangeArgs()']'
   'SayHint' Next
   dprintf( Next)

; ---------------------------------------------------------------------------
defc SetScrollAfterLocate
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\AfterLocate'
   -- if executed with a num as arg
   if arg(1) <> '' & isnum(arg(1)) then
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, arg(1))
      return
   endif
   -- else open entrybox
   Title   = 'Configure line position on screen after locate'
   Text    = 'Enter number of lines from top or bottom.'
   IniValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   If IniValue = 0 | IniValue = '' then
      DefaultButton = 3
   elseif IniValue < 0 then
      DefaultButton = 2
   else
      DefaultButton = 1
   endif
   -- strip + or -
   IniValue = translate( IniValue, '  ', '+-')
   IniValue = strip(IniValue)
   parse value entrybox( Title,
                         '/# from ~top/# from ~bottom/~Center/Cancel',  -- max. 4 buttons
                         IniValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   -- strip + or -
   NewValue = translate( NewValue, '  ', '+-')
   NewValue = strip(NewValue)
   parse value NewValue with NewValue .
   if Button = \1 then
      'SetScrollAfterLocate' NewValue
      return
   elseif Button = \2 then
      'SetScrollAfterLocate -'NewValue
      return
   elseif Button = \3 then
      'SetScrollAfterLocate 0'
      return
   elseif Button = \4 then
      return
   endif

; ---------------------------------------------------------------------------
defc GotoLineDlg
   Title = 'Go to line'
   Text  = 'Enter line number and optionally a column number:'
   --Text  = Text''copies( ' ', max( 100 - length(Text), 0))
   Entry = ''
   parse value entrybox( Title,
                         '',
                         Entry,
                         0,
                         240,
                         atoi(1) || atoi(0) || atol(0) ||
                         Text) with button 2 NewLine \0
   NewLine = strip( NewLine)
   if button = \1 & NewLine <> '' then
      'goto' NewLine
   endif

; ---------------------------------------------------------------------------
; Syntax: Balance [OpenStr] CloseStr
; Types CloseStr and highlights the matching OpenStr.
defc Balance
   parse arg arg1 arg2
   arg1 = strip( arg1)
   arg2 = strip( arg2)
   if arg2 = '' then
      OpenStr  = ''
      CloseStr = arg1
   else
      OpenStr  = arg1
      CloseStr = arg2
   endif

   -- Default values for OpenStr
   if OpenStr = '' then
      if CloseStr = ')' then
         OpenStr = '('
      elseif CloseStr = ']' then
         OpenStr = '['
      elseif CloseStr = '}' then
         OpenStr = '{'
      elseif CloseStr = '>' then
         OpenStr = '<'
      elseif CloseStr = '' then
         sayerror 'Balance: Error: OpenStr must be specified for non-default CloseStr' CloseStr
      endif
   endif

   call Balance( OpenStr, CloseStr)

; ---------------------------------------------------------------------------
const
compile if not defined( BALANCE_MAX_LINES)
   BALANCE_MAX_LINES = 200
compile endif
compile if not defined( BALANCE_MAX_LOOPS)
   BALANCE_MAX_LOOPS = 50
compile endif

defproc Balance( OpenStr, CloseStr)
   universal CurKey
   universal PrevKey
   universal PrevBalanceData
   universal nepmd_hini

   StartLine = .line
   StartCol  = .col
   ThisLine = ''
   OpenLine = 0
   OpenCol  = 0
   lrc = 1
   call NextCmdAltersText()
   -- Type the char
   call Process_Keys( CloseStr)

   fSearch = 1
   -- Omit search for repeated keys after an unsuccessful search
   getfileid Fid
   parse value PrevBalanceData with PrefFid PrevLine PrevRc
   if PrevRc <> 0 then
      if PrefFid PrevLine = Fid StartLine then
         if CurKey = PrevKey then
            fSearch = 0
            lrc = PrevRc
            --dprintf( 'Omit search, prev. rc = 'PrevRc)
         endif
      endif
   endif

   if fSearch then
      KeyPath = '\NEPMD\User\Balance'
      fBalance = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if not fBalance then
         fSearch = 0
      endif
   endif

   if fSearch then
      display -3  -- turn off non-critical error messages and screen updates
                  -- Note: SayHint uses temp. 'display -8' to disable message box saving.
                  --       That results in 'display -11'.
      call psave_pos( ScreenPos)

      lrc = passist( BALANCE_MAX_LINES, BALANCE_MAX_LOOPS)
      if not lrc then
         getline ThisLine
         OpenLine = .line
         OpenCol  = .col
      endif

      call prestore_pos( ScreenPos)
      display 3  -- turn on non-critical error messages and screen updates
      PrevBalanceData = Fid StartLine lrc

      if lrc then
         -- Let passist do the error msg
      elseif OnScreen( OpenLine, OpenCol) then
         -- Highlight it
         EndCol = OpenCol + length( OpenStr) - 1
         'PostMe CircleIt' OpenLine OpenCol EndCol
      else
         -- Opening character not on screen, so tell user in message area where it is
         ReportLine = leftstr( ThisLine, OpenCol + length( OpenStr) - 1)
         if (length( ReportLine) > 20) then
            ReportLine = leftstr( ReportLine, 20) "..."
         endif
         'SayHint Line' OpenLine', column' OpenCol':' ReportLine
      endif
   endif

   return lrc

