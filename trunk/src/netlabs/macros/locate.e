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
definit
   universal search_len
   universal nepmd_hini
   universal lastchangeargs
   universal lastsearchargs
   if lastchangeargs = '' then  -- after an EPM window opened, all universal vars were set to empty
      -- Query args for the case, when a 'changenext' is executed
      -- before a 'change'. So, it's possible to open a new EPM window and
      -- repeat the last change action there.
      KeyPath = '\NEPMD\User\Search\LastChangeArgs'  -- get it from NEPMD.INI
      lastchangeargs = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   if lastsearchargs = '' then  -- after an EPM window opened, all universal vars were set to empty
      KeyPath = '\NEPMD\User\Search\LastSearchArgs'  -- get it from NEPMD.INI
      lastsearchargs = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   search_len = 5     -- Initialize to anything, to prevent possible "Invalid number argument"

defmodify             -- This stops the modification dialog for grep output "files"  -- JBS
   if leftstr(.filename, 17) = '.Output from grep' then
      .modify = 0
      .autosave = 0
   endif

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
   universal search_len
   universal lastsearchargs
   universal lastchangeargs
   universal lastsearchpos
   universal nepmd_hini

   fFindNext = 0  -- differ an initial find command from a (repeated)
                  -- FindNext command.
   PreviousSearchArgs = lastsearchargs  -- save old value to determine later
                                        -- if it has to be rewritten to ini.
   parse arg args
   args = strip( args, 'L')
   if args = '' then  -- If no args, query args
      fFindNext = 1  -- then it must be a FindNext
      args = lastsearchargs
      -- Process the parsing of args again to recognize a possible change of
      -- default_search_options in the meantime.
   endif

   delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (delim)search_string(delim)user_options
   user_options = strip( user_options, 'T', delim)

   -- Set default_options to uppercase
   default_options = upcase(default_search_options)

   -- Switch to All if Mark is default and no text marked, but don't disable
   -- 'M' from user_options to make it work as expected.
   if not FileIsMarked() then
      -- Remove 'M' from default_options
      do forever
         pv = verify( default_options, 'M', 'M')  -- 2nd arg is charlist to find
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Remove 'T' and 'B' from default_options, because searchdlg won't
   -- set these checkboxes. Other options are recognized. This is useful
   -- to avoid confusion, because searchdlg will call either defc locate
   -- or defc change. These commands will add default_search_options,
   -- even T or B, while the user would think, he hasn't selected them.
   if pos( 'D', upcase(user_options)) then  -- if called from SearchDlg
      do forever
         pv = verify( upcase(default_options), 'TB', 'M')
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Remove 'T', 'B' and 'U' from default_options if the new option 'U' is
   -- used. This new option can be added to tell the locate command to remove
   -- 'T' and 'B'. E.g. the 'All' cmd doesn't work with B' or 'T'.
   if pos( 'U', upcase(user_options)) then  -- if 'U' is used
      -- Remove 'U' from user_options
      do forever
         pv = verify( upcase(user_options), 'U', 'M')
         if pv then
            user_options = delstr( user_options, pv, 1)
         else
            leave
         endif
      enddo
      -- Remove 'T' and 'B' from default_options
      do forever
         pv = verify( default_options, 'TB', 'M')
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Build search_options. The last option wins.
   -- Insert default_search_options just before supplied options (if any)
   -- so the supplied options will take precedence.
   search_options = upcase(default_options''user_options)

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

   -- Build list of search args with options, last option wins.
   SearchArgs = delim''search_string''delim''search_options

   if fFindNext = 0 then
      -- Save these args for the case, when a 'findnext' is executed
      -- before a 'locate'. So, it's possible to open a new EPM window and
      -- repeat the last locate action there.
      -- Omit default_search_options from the saved string and let a findnext
      -- re-determine default_search_options. User may have changed it in the
      -- meantime.
      lastsearchargs = delim''search_string''delim''user_options  -- save it in a universal var
      if lastsearchargs = PreviousSearchArgs then
         fFindNext = 1
      else
         KeyPath = '\NEPMD\User\Search\LastSearchArgs'  -- save it in NEPMD.INI
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, lastsearchargs)

         -- Reset also lastchangeargs
         lastchangeargs = ''
         KeyPath = '\NEPMD\User\Search\LastChangeArgs'  -- save it in NEPMD.INI
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, lastchangeargs)
      endif
   endif

   getfileid fid
   -- Remove 'T' and 'B' temporarily if this is a FindNext in the same file
   -- as for the last find and if only next string should be found
   parse value (lastsearchpos) with SearchLine SearchCol SearchLen SearchFid SearchMode
   if fid = SearchFid then
      if (fFindNext = 1) then

         -- Remove 'T' and 'B'
         do forever
            pv = verify( search_options, 'TB', 'M')
            if pv then
               search_options = delstr( search_options, pv, 1)
            else
               leave
            endif
         enddo

         -- Build new SearchArgs
         SearchArgs = delim''search_string''delim''search_options

         if SearchLine SearchCol = .line .col then
            if PreviousSearchArgs = lastsearchargs then
               -- Move cursor to not find the just changed string again
               Foreward = lastpos( 'F', search_options) > lastpos( 'R', search_options)
               Downward = lastpos( '+', search_options) > lastpos( '-', search_options)
               if Foreward then
                  next = .col + SearchLen
                  if next > length( textline(.line)) then
                     if Downward & .line < .last then
                        down
                     elseif not Downward & .line > 1 then
                        up
                     endif
                     .col = 1
                  else
                     .col = next
                  endif
               else
                  next = .col - SearchLen
                  if next < 0 then
                     if Downward & .line < .last then
                        down
                     elseif not Downward & .line > 1 then
                        up
                     endif
                     .col = length( textline(.line))
                  else
                     .col = next
                  endif
               endif
            endif
         endif
      endif
   endif

   -- Set universal var for hilite.
   -- It will be recalled internally by getpminfo(EPMINFO_LSLENGTH).
   search_len = length(search_string)
   prevpos = .line .col

   display -8  -- suppress writing to MsgBox
   'xcom l 'SearchArgs
   lrc = rc
   display 8

   if rc = 0 then  -- if found
      -- Save last searched pos, file and search mode
      lastsearchpos = .line .col length( search_string) fid 'l'
      call highlight_match()
   endif

   rc = lrc  -- does hightlight_match change rc?

; ---------------------------------------------------------------------------
; Moved from STDCMDS.E
defc RepeatChange, C, Change
   universal default_search_options
   universal search_len
   universal lastchangeargs
   universal lastsearchargs
   universal lastsearchpos
   universal nepmd_hini
   universal stay  -- if 1, then restore pos even after a successful change

   call psave_pos(savepos)

   fChangeNext = 0  -- differ an initial change command from a (repeated)
                    -- ChangeNext command.
   PreviousChangeArgs = lastchangeargs  -- save old value to determine later
   PreviousSearchArgs = lastsearchargs  -- if it has to be rewritten to ini.
   args = strip( arg(1), 'L')

   if args = '' then   -- If no args, query lastchangeargs
      fChangeNext = 1  -- then it must be a ChangeNext
      args = lastchangeargs
      -- Process the parsing of args again to recognize a possible change of
      -- default_search_options in the meantime.
   endif

   delim = substr( args, 1, 1)  -- get 1st delimiter
   p2 = pos( delim, args, 2)    -- check 2nd delimiter of 2 or 3
   if not p2 then
      sayerror NO_REP__MSG
      return
   endif
   parse value args with (delim)search_string(delim)replace_string(delim)user_options
   user_options = strip( user_options, 'T', delim)

   -- Set default_options to uppercase
   default_options = upcase(default_search_options)

   -- Switch to All if Mark is default and no text marked, but don't disable
   -- 'M' from user_options to make it work as expected.
   if not FileIsMarked() then  -- if current file is not marked
      -- Remove 'M' from default_options
      do forever
         pv = verify( default_options, 'M', 'M')  -- 2nd arg is charlist to find
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Remove 'T' and 'B' from default_options, because searchdlg won't
   -- set these checkboxes. Other options are recognized. This is useful
   -- to avoid confusion, because searchdlg will call either defc locate
   -- or defc change. These commands will add default_search_options,
   -- even T or B, while the user would think, he hasn't selected them.
   if pos( 'D', upcase(user_options)) then  -- if called from SearchDlg
      do forever
         pv = verify( upcase(default_options), 'TB', 'M')
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Remove 'T', 'B' and 'U' from default_options if the new option 'U' is
   -- used. This new option can be added to tell the locate command to remove
   -- 'T' and 'B'. E.g. the 'All' cmd doesn't work with B' or 'T'.
   if pos( 'U', upcase(user_options)) then  -- if 'U' is used
      -- Remove 'U' from user_options
      do forever
         pv = verify( upcase(user_options), 'U', 'M')
         if pv then
            user_options = delstr( user_options, pv, 1)
         else
            leave
         endif
      enddo
      -- Remove 'T' and 'B' from default_options
      do forever
         pv = verify( default_options, 'TB', 'M')
         if pv then
            default_options = delstr( default_options, pv, 1)
         else
            leave
         endif
      enddo
   endif

   -- Build search_options. The last option wins.
   -- Insert default_search_options just before supplied options (if any)
   -- so the supplied options will take precedence.
   search_options = upcase(default_options''user_options)

   -- Append 'N' to give a message how many changes, if 'Q' not specified
   -- and if all should be changed.
   if pos( '*', search_options) &  -- if called from SearchDlg
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

   ChangeArgs = delim''search_string''delim''replace_string''delim''search_options

   if fChangeNext = 0 then
      -- Save search args without default_search_options to respect a possible
      -- change in the meantime, maybe by the user
      lastchangeargs = delim''search_string''delim''replace_string''delim''user_options
      -- Save these args for the case, when a 'changenext' is executed
      -- before a 'change'. So, it's possible to open a new EPM window and
      -- repeat the last change action there.
      if lastchangeargs <> PreviousChangeArgs then
         KeyPath = '\NEPMD\User\Search\LastChangeArgs'  -- save it in NEPMD.INI
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, lastchangeargs)
      endif
   endif

   -- Set lastsearchargs as well, to use first Ctrl+F and then Ctrl+C for to
   -- operate on the same search_string. Even a ChangeNext should synchronize it.
   lastsearchargs = delim''search_string''delim''user_options
   if lastsearchargs <> PreviousSearchArgs then
      KeyPath = '\NEPMD\User\Search\LastSearchArgs'  -- save it in NEPMD.INI
      call NepmdWriteConfigValue( nepmd_hini, KeyPath, lastsearchargs)
   endif

   getfileid fid
   -- Remove 'T' and 'B' temporarily if this is a ChangeNext in the same file
   -- as for the last change and if only next found string should be changed
   parse value (lastsearchpos) with SearchLine SearchCol SearchLen SearchFid SearchMode
   if fid = SearchFid then
      if (fChangeNext = 1 & not pos( '*', search_options)) |
         (lastsearchargs = previoussearchargs) then

         -- Remove 'T' and 'B'
         do forever
            pv = verify( search_options, 'TB', 'M')
            if pv then
               search_options = delstr( search_options, pv, 1)
            else
               leave
            endif
         enddo

         -- Build new ChangeArgs
         ChangeArgs = delim''search_string''delim''replace_string''delim''search_options
      endif
   endif

   -- Set universal var for hilite, maybe for findnext.
   -- It will be recalled internally by getpminfo(EPMINFO_LSLENGTH).
   search_len = length( replace_string)

;     /* Put this lines back in if you want the M choice to force */
;     /* the cursor to the start of the mark.                    */
;    if verify( upcase(user_options), 'M', 'M' ) then
;       call checkmark()  -- ??? returns (0|1)
;       call pbegin_mark()  /* mark specified - make sure at top of mark */
;    endif

   display -8
   -- Execute the change command with args from arg(1); if empty, with args from
   -- the last change command. default_search_options are added.
   'xcom c 'ChangeArgs
   display 8

   if rc = 0 then  -- if found
      -- Save last searched pos, file and search mode
      lastsearchpos = .line .col length( replace_string) fid 'c'
      --call highlight_match()  -- gives wrong col
      call highlight_match( .line .col search_len)
      -- Restore pos after change command if stay = 1
      if stay then
         call prestore_pos( savepos)
      endif
   else            -- if not found
      call prestore_pos( savepos)  -- required for 'B' or 'T'
   endif

; ---------------------------------------------------------------------------
; Moved from STDPROCS.E
; Highlight a "hit" after a Locate command or Repeat_find operation.
; Never used its previous arg(1) = search_len in 6.03b.
; New: optional arg(1) = <line> <col> <len>
defproc highlight_match

   if rc then  -- if not found; rc was set from last 'c'|'l'|repeat_find
      return
   endif

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
����������������������������������������������������������������������������Ŀ
� what's it called: searchdlg       syntax:   searchdlg [next]               �
�                                                                            �
� what does it do : ask EPM.EXE to pop up its internal search & replace dlg. �
�                   This is done by posting a EPM_POPCHANGEDLG message to the�
�                   EPM Book window.                                         �
�                   if the [next] param = 'F'  a find next will take place   �
�                   if the [next] param = 'C'  a change next will take place �
�                                                                            �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Jerry C.   2/27/89                                       �
������������������������������������������������������������������������������
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
   universal lastsearchargs
   universal default_search_options
   ret = '+'

   args = lastsearchargs
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
defc ToggleSearchDirection
   universal lastsearchargs
   universal default_search_options

   args = lastsearchargs
   s_delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (s_delim)s_search_string(s_delim)s_user_options
   s_user_options = strip( s_user_options, 'T', s_delim)

   -- Analyze only last search options, not last change options
   Minuspos = lastpos( '-', default_search_options''s_user_options)
   Pluspos  = lastpos( '+', default_search_options''s_user_options)

   -- Append +F or -R
   if Minuspos > Pluspos then  -- in searchoptions: the last option wins
      'SearchDirection F'
      sayerror 'Changed search direction to: forward.'
   else
      'SearchDirection R'
      sayerror 'Changed search direction to: backward.'
   endif

; ---------------------------------------------------------------------------
; Set SearchDirection to foreward (arg = 'F' or '+') or backward (arg = 'R'
; or '-').
defc SearchDirection
   universal lastsearchargs
   universal lastchangeargs
   universal default_search_options

   if arg(1) = '' then
      return
   endif
   if arg(1) = '+' then
      Direction = 'F'
   elseif arg(1) = '-' then
      Direction = 'R'
   else
      Direction = upcase( arg(1))
   endif

   args = lastsearchargs
   s_delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (s_delim)s_search_string(s_delim)s_user_options
   s_user_options = strip( s_user_options, 'T', s_delim)

   args = lastchangeargs
   c_delim = substr( args, 1, 1)  -- get 1st delimiter
   parse value args with (c_delim)c_search_string(c_delim)c_replace_string(c_delim)c_user_options
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
   if Direction = 'F' then
      s_user_options = s_user_options'+F'
      c_user_options = c_user_options'+F'
   elseif Direction = 'R' then
      s_user_options = s_user_options'-R'
      c_user_options = c_user_options'-R'
   endif
   lastsearchargs = s_delim''s_search_string''s_delim''s_user_options
   lastchangeargs = c_delim''c_search_string''c_delim''c_replace_string''c_delim''c_user_options

; ---------------------------------------------------------------------------
defc FindNext
   'SearchDirection F'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc FindPrev
   'SearchDirection R'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc ChangeFindNext
   'SearchDirection F'
   'RepeatChange'
   'RepeatFind'

; ---------------------------------------------------------------------------
defc ChangeFindPrev
   'SearchDirection R'
   'RepeatChange'
   'RepeatFind'

; ---------------------------------------------------------------------------
; From EPMSMP\GLOBFIND.E
defc RepeatFindAllFiles, RingFind
   -- Remember our current file so we don't search forever.
   -- (Sometimes doesn't work.)
   getfileid StartFileID

   -- get current search direction
   getsearch cursearch
   parse value cursearch with . c_or_l search
   delim = leftstr( search, 1 )
   parse value cursearch with searchcmd (delim)searchstring(delim)searchoptions(delim)
   if searchoptions = '' then
      parse value cursearch with searchcmd (delim)searchstring(delim)searchoptions
   endif
   Minuspos = lastpos( '-', searchoptions )
   Pluspos  = lastpos( '+', searchoptions )
   if Minuspos > Pluspos then
      Forward = 0
   else
      Forward = 1
   endif

   -- First repeat-find in current file in case we don't have to move.
   'RepeatFind'  -- if first search since start, get lastsearchargs from ini
   if rc = 0 then  -- if found
      return rc
   endif
   fileid = StartFileID
   loop
      if Forward = 1 then
         nextfile
      else
         prevfile
      endif
      getfileid fileid
      activatefile fileid
      -- Include this refresh if you like to see each file as it's
      -- searched.  Causes too much screen flashing for my taste,
      --refresh

      -- Start from top of file, save current posn in case no match.
      call psave_pos(save_pos)
      if Forward = 1 then
         top
         .col=1
      else
         bottom
         endline
      endif
      -- 'postme FindNext'  -- doesn't work
;      display -8
;      repeat_find  -- would start from top again if T is in default_search_options
;      display 8
      'RepeatFind'
      if rc = 0 then  -- if found
         refresh
         --'postme highlightmatch'  -- postme required
         'HighlightMatch'  -- postme not required, command instead of proc makes it
         if fileid = StartFileID then
            'SayHint String only found in this file.'
         else
            sayerror 0  -- flush the message
         endif
         leave
      else
         -- no match in file - restore file location
         call prestore_pos(save_pos)
      endif
      if fileid = StartFileID then
         'SayHint String not found in any file of the ring.'
         leave
      endif
   endloop
   activatefile fileid

; ---------------------------------------------------------------------------
; From EPMSMP\GLOBCHNG.E
defc RepeatChangeAllFiles, RingChange
;                                --<-------------------------------  todo: rewrite
   universal lastchangeargs
   universal default_search_options
   universal stay

   args = strip( arg(1), 'L')
   if args = '' then  -- If no args, query lastchangeargs
      args = lastchangeargs
      -- Process the parsing of args again to recognize a possible change of
      -- default_search_options in the meantime.
   endif

   /* Insert default_search_options just before supplied options (if any)    */
   /* so the supplied options will take precedence.                          */
   user_options = ''
   delim = substr( args, 1, 1 )
   p = pos( delim, args, 2 )   /* find last delimiter of 2 or 3 */
   if p then
      p = pos( delim, args, p + 1 )   /* find last delimiter of 2 or 3 */
      if p > 0 then
         user_options = substr( args, p + 1 )
         args = substr(args, 1, p - 1 )
      endif
----
      search_len = p - 2
----
   else
----      sayerror '--test-- delim = |'delim'|, args = |'args'|, p = |'p'|'; stop
      sayerror NO_REP__MSG
      return
   endif
   if verify( upcase(default_search_options), 'M', 'M' ) then
      user_options = 'A'user_options
   endif
   args = args''delim''default_search_options''user_options
   backwards = 0
   p1 = lastpos( '-', default_search_options''user_options )
   if p1 then
      if p1 > lastpos( '+', default_search_options''user_options ) then
         backwards = 1
      endif
   endif
   rev = 0  -- changed to rev, because reverse is a statement
   p1 = lastpos( 'R', upcase(default_search_options''user_options) )
   if p1 then
      if p1 > lastpos( 'F', upcase(default_search_options''user_options) ) then
         rev = 1
      endif
   endif
----
   p1 = pos('*', default_search_options''user_options)
   if p1 = 0 then
      args = args'*'
   endif
----


   /* Remember our current file so we don't search forever.  */
   getfileid StartFileID
   change_count = 0

   loop
      /* Include this refresh if you like to see each file as it's */
      /* searched.  Causes too much screen flashing for my taste,  */
;;       refresh

      /* Start from top of file, save current posn in case no match. */
      call psave_pos(save_pos)
      if backwards then
         bottom
         if rev then
            end_line
         else
            begin_line
         endif
      else
         0
      endif
      display -8
      'xcom c' args
      display 8
      if rc = 0 then
         change_count = change_count + 1
         'ResetDateTimeModified'  -- required?
         'RefreshInfoLine MODIFIED'
         if stay then
            call prestore_pos(save_pos)
         endif
      else
         /* no match in file - restore file location */
         call prestore_pos(save_pos)
      endif
      nextfile
      getfileid fileid
      if fileid = StartFileID then
         leave
      endif
   endloop
   if change_count = 1 then
      files = 'file.'
   else
      files = 'files.'
   endif
   'SayHint String changed in' change_count files

; ---------------------------------------------------------------------------
defc FindNextAllFiles
   'SearchDirection F'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
defc FindPrevAllFiles
   'SearchDirection R'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
defc ChangeFindNextAllFiles
   'SearchDirection F'
   'RepeatChangeAllFiles'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
defc ChangeFindPrevAllFiles
   'SearchDirection R'
   'RepeatChangeAllFiles'
   'RepeatFindAllFiles'

; ---------------------------------------------------------------------------
const
compile if not defined( GREP_EXE)
   GREP_EXE = 'grep.exe'
compile endif
compile if not defined( GNU_GREP_OPTIONS)
   -- -E  extended grep
   -- -i  case insensitive
   -- -n  show line numbers
   -- -H  force print filename (path is missing, if file is located in current directory)
   GNU_GREP_OPTIONS = '-EinH'
compile endif
compile if not defined( RY_GREP_OPTIONS)
   -- /y  case insensitive
   -- /q  quiet, disable stderr
   -- /l  show line numbers
   RY_GREP_OPTIONS = '/y /q /l'
compile endif

; ---------------------------------------------------------------------------
; Determine version of grep.exe. Returns:
; 0   Ralph Yozzo's version of grep (can be found in CSTEPM package)
; 1   Gnu grep or any other version if Gnu grep version number n could not
;     be determined
; n   if Gnu grep version number n could be determined, something like 2.5a
; -1  error: file not found
defproc GetGrepVersion
   universal nepmd_hini
   fInit = upcase( arg(1)) = 'INIT'

   -- Get GrepVersion, Size, Time from ini
   KeyPath = '\NEPMD\User\GrepVersion'
   next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value next with LastGrepVersion \1 LastSize \1 LastTime \1

   -- Default values
   Size = ''
   Time = ''
   File = ''
   if (LastGrepVersion = 0 | LastGrepVersion > 1) then  -- old format only returned 0 or 1
      GrepVersion = LastGrepVersion
   else
      fInit = 1
      GrepVersion = ''
   endif

   do i = 1 to 1
      if not fInit then
         leave
      endif

      if substr( GREP_EXE, 2, 2) = ':\' | substr( GREP_EXE, 1, 2) = '\\' then
         File = GREP_EXE
         if Exist( File) then
            return -1  -- File not found
         endif
      else
         -- Find grep.exe in path
         findfile File, GREP_EXE, 'PATH', 'P'
         if File = '' then
            return -1  -- File not found
         endif
      endif

      -- Query size, time
      Size = NepmdQueryPathInfo( File, 'SIZE')
      parse value Size with 'ERROR:'rcx
      if rcx <> '' then
         return -1  -- File not found
      endif
      Time = NepmdQueryPathInfo( File, 'MTIME')  -- YYYY/MM/DD HH:MM:SS
      parse value Time with 'ERROR:'rcx
      if rcx <> '' then
         return -1  -- File not found
      endif
      --sayerror '1: 'fInit'-"'File'"-'LastGrepVersion'-'Size'-'Time

      -- Compare Size and Time
      if Size = LastSize & Time = LastTime then
         -- Force to rewrite the ini string if GrepVersion = 1, because the old
         -- format knew only 0 or 1
         if LastGrepVersion <> 1 & isnum( leftstr( LastGrepVersion, 1)) then
            leave
         endif
      endif

      -- Different. Determine GnuFlag
      TmpFile = Get_Env( 'TMP')'\gnu-ver.out'
      Cmd = GREP_EXE' -V'
      RyString = "unrecognized option: '-V'"
      quietshell Cmd arg(2) '>'TmpFile '2>&1'
      -- [H:\CSTEPM]grep -V           -- Ralph Yozzo's grep of CSTEPM
      -- unrecognized option: '-V'
      --
      -- [F:\bin]grep -V              -- Gnu grep
      -- grep (GNU grep) 2.5a
      -- grep.exe (GNU grep) 2.10
      --
      -- Copyright 1988, 1992-1999, 2000 Free Software Foundation, Inc.
      -- This is free software; see the source for copying conditions. There is NO
      -- warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
      'xcom edit' TmpFile
      e_rc = rc
      if e_rc then    -- Unexpected error.
         sayerror ERROR_LOADING__MSG TmpFile
         if e_rc = -282 then 'xcom quit'; endif  -- sayerror('New file')
         sayerror 'GetGrepVersion: rc from xcom edit = 'e_rc
         rc = e_rc
         leave
      endif
      line = textline(1)
      if line = RyString then
         GrepVersion = 0
      else
         parse value strip( lowcase( line)) with next rest
         rest = strip( rest)
         if leftstr( rest, 1) = '(' then
            parse value rest with '(' next ')' rest
         endif
         GrepVersion = word( rest, 1)
         if GrepVersion = '' then
            GrepVersion = 1
         endif
      endif
      'xcom quit'
      call EraseTemp( TmpFile)
      -- Write GrepVersion, Size, Time to ini
      KeyValue = GrepVersion\1''Size\1''Time\1
      next = NepmdWriteConfigValue( nepmd_hini, KeyPath, KeyValue)
      --sayerror '2: 'fInit'-"'File'"-'GrepVersion'-'Size'-'Time
   enddo
   --sayerror fInit'-'GrepVersion
   return GrepVersion

; ---------------------------------------------------------------------------
; From EPMSMP\GREP.E
; Call an external GREP utility and display the results in an EPM file.
; The modified Alt+1 definition in ALT_1.E will let you place the
; cursor on a line in the results file and press Alt+1 to load the
; corresponding source file.
;
; Syntax: grep [grepoptions] pattern filemask
;
; If no grepoptions where specified, the defaultgrepopt are submitted to grep.
; Works with Gnu grep or Ralph Yozzo's grep (contained e.g. in CSTEPM).
defc Grep
   GrepVersion = GetGrepVersion( 'INIT')
   if GrepVersion = -1 then
      sayerror 'Error: 'GREP_EXE' not found in PATH.'
      rc = 2
   else
      rc = CallGrep( GrepVersion, arg(1))
   endif
;   sayerror 'rc from defc Grep = 'rc

; ---------------------------------------------------------------------------
; For use as menu item.
defc GrepDlg
   next = arg(1)
   if next > '' then
      GrepVersion = next
   else
      GrepVersion = GetGrepVersion( 'INIT')
      if GrepVersion = -1 then
         sayerror 'Error: 'GREP_EXE' not found in PATH.'
         return 2
      endif
   endif
   -- Options:
   if GrepVersion > 0 then
      DefaultGrepOpt = GNU_GREP_OPTIONS
   else
      DefaultGrepOpt = RY_GREP_OPTIONS
   endif
   Title = 'Scan for text in files'
   Text  = 'Enter string (in quotes if it contains spaces) and file spec:'
   DefaultValue  = DefaultGrepOpt' '
   DefaultButton = 1

   parse value entrybox( Title,
                         '/~OK/Cancel/Grep ~Help',  -- max. 4 buttons
                         DefaultValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 then
      rc = CallGrep( GrepVersion, NewValue)
      return 2
   elseif Button = \2 then
      return
   elseif Button = \3 then
      -- Show help
      if GrepVersion > 0 then
         GrepArgs = '--help'
      else
         GrepArgs = ''
      endif
      --call CallGrep( GrepVersion, GrepArgs)  -- opens too late
      "Open 'Grep "GrepArgs"'"  -- use an extra window to show Grep's help
      'postme GrepDlg' GrepVersion
   endif

; ---------------------------------------------------------------------------
; Syntax: callgrep( GrepVersion[, GrepArgs[, fVerbose]])
; If GrepArgs doesnot contain options, the default options, either
; GNU_GREP_OPTIONS or RY_GREP_OPTIONS, depending on GrepVersion are prepended
; to GrepArgs.
defproc CallGrep
   universal vepm_pointer

   GrepVersion = arg(1)
   if arg(3) = '' then
      fVerbose = 1
   else
      fVerbose = (arg(3) = 1)
   endif

   -- Options:
   if GrepVersion > 0 then
      defaultgrepopt = GNU_GREP_OPTIONS
   else
      defaultgrepopt = RY_GREP_OPTIONS
   endif
   --display -8

   grepargs = arg(2)
   -- Parse options, if user specified any
   grepopt  = ''
   if GrepVersion > 0 then
      optdelim = '-'
   else
      optdelim = '-/'
   endif
   do i = 1 to words( grepargs)
      next = word( grepargs, i)
      --if substr( next, 1, 1) = '-' then
      if verify( substr( next, 1, 1), optdelim, 'M') then
         grepopt = grepopt' 'next
      endif
   enddo
   grepopt = strip(grepopt)
   -- Prepend default options, if user specified none
   if grepopt = '' then
      grepargs = defaultgrepopt grepargs
   endif

   mouse_setpointer WAIT_POINTER
   if words( grepargs) > 1 then
      if fVerbose then
         sayerror 'Scanning files...'
      endif
   elseif GrepVersion > 0 then
      -- Show Gnu help
      grepargs = '--help'
   else
      -- Show RY help
      grepargs = ''
   endif

   greprc = redirect_grep( GrepVersion, GREP_EXE, grepargs, directory())
   if words( grepargs) < 2 then
      sayerror 'Syntax: grep [options] pattern filemask  (default options = 'defaultgrepopt')'
   elseif greprc <> 0 then

   elseif fVerbose then
      'SayHint' ALT_1_LOAD__MSG
   endif
   mouse_setpointer vepm_pointer
   rc = greprc
   return rc
   --display 8

; ---------------------------------------------------------------------------
; Added directory line in Gnu grep's output for ALt_1.
defproc redirect_grep( GrepVersion, Cmd)
   universal vTEMP_PATH
   outfile = vTEMP_PATH'grep____.out'

   quietshell Cmd arg(3) '>'outfile '2>&1'
   cmdrc = rc
   -- sets rc >= 1 on application error, rc < 0 on E error, otherwise rc = 0

   if cmdrc = sayerror( 'Insufficient memory') or
      cmdrc = sayerror( 'File Not found') then
      stop
   endif

   CurDir = arg(4)
   if arg(4) = '' then
      CurDir = directory()
   endif

   'edit' outfile
   if rc = -282 then
      'xcom quit'  -- sayerror('New file')
   endif
   if rc <> 0 then
      return rc
   endif

   rc = cmdrc
   .autosave = 0
   .filename = '.Output from grep' arg(3)

   if .last > 0 then
      next = textline(1)
   else
      next = ''
   endif
   if leftstr( next, 3) = 'SYS' then
      -- Check for DLL not found errors
      -- SYS1804: Datei REGEX kann nicht gefunden werden.
      parse value next with 'SYS'rc':' .
      sayerror next
   endif

   -- If current path is searched only, Gnu grep won't output the files' pathes.
   -- Additionally, the string "Current directory = " works now as markup for
   -- the following Alt+1 command to determine the grep version easily.
   if GrepVersion > 0 then
      insertline 'Current directory = 'CurDir, 1
   endif

   .modify = 0
   call erasetemp( outfile)
   return rc

; ---------------------------------------------------------------------------
; Search all NEPMD E macros for a string
; input:  a string to search for
; output: a grep window showing all matches suitable for use with ALT+1
defc MacGrep
   RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
   UserDir = NepmdScanEnv( 'NEPMD_USERDIR')
   FileMask = UserDir'\macros\*.e' RootDir'\netlabs\macros\*.e'
   'grep' GNU_GREP_OPTIONS arg(1) FileMask
   if rc <> 0 then
      sayerror 'rc from grep = 'rc
   else
      'SayHint' ALT_1_LOAD__MSG
   endif

; ---------------------------------------------------------------------------
; Support for Graphical File Comparison
; Compares current file with another. File open dialog of GFC will open.
; If current file is located in any tree of %NEPMD_ROOTDIR%\netlabs or
; %NEPMD_USERDIR%, then the current file is compared with the
; corresponding file of the other tree.
defc GfcCurrentFile
   fn = .filename
   GfcParams = '"'fn'"'

   RootDir = NepmdScanEnv('NEPMD_ROOTDIR')
   parse value RootDir with 'ERROR:'rc1
   if rc1 > '' then
      sayerror 'Environment var NEPMD_ROOTDIR not set.'
   endif
   NetlabsDir = RootDir'\netlabs'

   UserDir = NepmdScanEnv('NEPMD_USERDIR')
   parse value UserDir with 'ERROR:'rc2
   if rc2 > '' then
      sayerror 'Environment var NEPMD_USERPATH not set.'
   endif

   NetlabsDir = strip( NetlabsDir, 't', '\')
   UserDir    = strip( UserDir   , 't', '\')
   if rc1 = '' & rc2 = '' then
      if abbrev( upcase(fn), upcase(NetlabsDir)'\') then
         rest = substr( fn, length( NetlabsDir) + 1)  -- including leading \
         fn2 = UserDir''rest
         if NepmdFileExists(fn2) then
            GfcParams = GfcParams' "'fn2'"'
         endif
      elseif abbrev( upcase(fn), upcase(UserDir)'\') then
         rest = substr( fn, length( UserDir) + 1)  -- including leading \
         fn2 = NetlabsDir''rest
         if NepmdFileExists(fn2) then
            GfcParams = GfcParams' "'fn2'"'
         endif
      endif
   endif

   'start /f gfc 'GfcParams

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
   if rc <> 0 then
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
      diads = '-> ++ -- << >> <= >= && || += -= *= /= %= �= &= |= :: /* */'
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
   universal lastsearchargs
   universal lastchangeargs
   getsearch cursearch
   sayerror 'Last search = ['cursearch'], last search args = ['lastsearchargs']' ||
            ', last change args = ['lastchangeargs']'

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

