/****************************** Module Header *******************************
*
* Module Name: infoline.e
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

; Macros for enhanced title bar and status bar

; The check, if an update is required, is a little bit opaque: Every
; title- or statusline <field> defines a <flag> with it in order to
; determine at several events, if a line must be updated or not.
;
; The advantage of this is, that a (maybe external) defproc or defc
; can simply call RefreshInfoLine <flag>. A line is only refreshed,
; if a <field> with a matching <flag> is defined for that line.
;
; The title- and statusline defs are parsed by defproc
; ResolveInfoFields. There, for every <field>, GetInfoFieldValue is
; called, that returns not only the resolved value, but also the
; defined <flag> for it. This <flag> is compared with the submitted
; arg of RefreshInfoLine.
;
; If any <field> requires an update, the entire line is updated.

; The refresh of additional (compared to standard EPM) statusline and
; titleline fields is done via E macros and therefore not quite good in
; performance. If problems occur during execution of a macro, the refresh
; can be disabled and enabled after the execution with a universal var:
;
;    InfolineRefresh = 0  ==> disabled
;    InfolineRefresh <> 0 ==> enabled (default is empty after startup
;                             for universal vars)
; The refresh is already disabled for hidden files.
;
; To use it in your macros:
; defc MyMacro
;    universal InfolineRefresh
;    saved_modify   = .modify
;    saved_autosave = .autosave
;    .autosave = 0
;    InfolineRefresh = 0
;       <specify some critical code here>
;       <e.g. commands, that act on many files or use many loops like reflow>
;    InfolineRefresh = 1
;    if .modify > saved_modify
;       .modify = saved_modify + 1
;    endif
;    .autosave = saved_autosave

; Bug:
;    o  If file was altered by another file, then the old date is shown in
;       title when file is temporary selected by ring_more dialog. On final
;       selection, when the dialog is closed, the date is updated.
;       -> won't (can't) fix.

definit
   universal vmodifiedstatuscolor
   KeyPath = '\NEPMD\User\DefaultColors'
   Colors = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   vmodifiedstatuscolor = word( Colors, 6)

; ---------------------------------------------------------------------------
; Compare args with StatusFieldFlags and TitleFieldFlags. If they match,
; RefreshStatusLine and/or RefreshTitleText is executed.
defc RefreshInfoLine
   universal StatusFieldFlags
   universal TitleFieldFlags
   universal InfolineRefresh  -- disable refresh of infolines if = 0
   if .visible & not (InfolineRefresh = 0) then
      Flags = arg(1)
      -- Todo: 'FILE' should not redetermine <datetimemodified> to make 'quit'
      --       process faster
      -- Init list of flags
      -- Following is only called if the universal vars were empty:
      if StatusFieldFlags = '' then
         call GetStatusFields()
      endif
      if TitleFieldFlags = '' then
         call GetTitleFields()
      endif
      do w = 1 to words(Flags)
         Flag = word( Flags, w)
         if wordpos( Flag, StatusFieldFlags) > 0 then
            'RefreshStatusLine'
            leave
         endif
      enddo
      do w = 1 to words(Flags)
         Flag = word( Flags, w)
         if wordpos( Flag, TitleFieldFlags) > 0 then
            'RefreshTitleText'
            leave
         endif
      enddo
   endif

; ---------------------------------------------------------------------------
; RefreshStatusLine refreshes the statusline with the current values.
;
; This defc is required, if the statusbar template should contain
; non-standard fields (without a '%'). Then it doesn't suffice to set the
; universal var current_status_template or the const STATUS_TEMPLATE.
;
; Calling refreshstatusline as a defselect theoretically means a little
; overhead, comparing with the internal mechanism of the E toolkit.
;
; Currently it overwrites the setting made by STATUS_TEMPLATE.
;
; Known bug:
;    When selecting a file from the 'Files in Ring' listbox, the statusbar
;    is not refreshed. The refresh is only processed after the listbox
;    is closed.
;    Against this, the internal defined statusbar fields (all values with a '%')
;    are refreshed immediately.
;
; Standard EPM statusline fields:
; %A   Autosave count value (number of changes made to the file since the last
;      autosave)
; %C   current Column number
; %F   number of Files in ring (followed by the word "File" or "Files")
; %I   Insert or replace state (cursor status)
; %L   current Line number
; %M   Modified status (if the file has been modified)
; %S   total number of lines in the current file
; %X   displays the hexadecimal value of the current character
; %Z   displays the ASCII value of the current character
;
; In contrast to the docs, the default value if STATUS_TEMPLATE was
; not defined as: 'Line %l of %s Column %c  %i   %m   %f'
defc RefreshStatusLine
   if .visible then
      'setstatusline 'GetStatusFields()
   endif  -- .visible
   return

; ---------------------------------------------------------------------------
; Determine fields and flags for statusline. Return resolved statusline
; fields containing only '%' fields or strings.
defproc GetStatusFields
   universal nepmd_hini
   universal StatusFieldFlags
   universal StatusFields

   -- Note: The length for the StatusLine string is limitted.
   if StatusFields = '' then
      KeyPath = '\NEPMD\User\InfoLine\StatusFields'
      StatusFields = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   ResolvedFields = ResolveInfoFields( StatusFields, Flags)
   -- Add 'MODIFIED' flag for StatusLine to update color
   if wordpos( 'MODIFIED', Flags) = 0 then
      Flags = Flags' MODIFIED'
   endif
   -- Add 'FILE' flag for StatusLine to update file-specific fields,
   -- that are not refreshed internally (mode, margins, tabs, ...)
   -- 'refreshinfoline FILE' is called by defload, save, defselect).
   if wordpos( 'FILE', Flags) = 0 then
      Flags = Flags' FILE'
   endif
   StatusFieldFlags = Flags
   return ResolvedFields

; ---------------------------------------------------------------------------
; Determine fields and flags for titletext. Return resolved titletext fields.
defproc GetTitleFields
   universal nepmd_hini
   universal TitleFieldFlags
   universal TitleFields

   if TitleFields = '' then
      KeyPath = '\NEPMD\User\InfoLine\TitleFields'
      TitleFields = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   ResolvedFields = ResolveInfoFields( TitleFields, Flags)
   TitleFieldFlags = Flags
   return ResolvedFields

; ---------------------------------------------------------------------------
; Determine separator for statusline and titletext.
defproc GetFieldSep
   universal nepmd_hini
   universal FieldSep

   if FieldSep = '' then
      KeyPath = '\NEPMD\User\InfoLine\Sep'
      FieldSep = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   return FieldSep

; ---------------------------------------------------------------------------
defc ResetStatusFields
   universal StatusFields
   StatusFields = ''
   call GetStatusFields()  -- set universal vars

defc ResetTitleFields
   universal TitleFields
   TitleFields = ''
   call GetTitleFields()  -- set universal vars

defc ResetFieldSep
   universal FieldSep
   FieldSep = ''

; ---------------------------------------------------------------------------
; Standard EPM %... patterns may be used here too for compatibility.
; The string '<InfoFieldVar>' will be replaced by its value.
; Therefore a new escape char pair '<' and '>' is introduced (at the
; start and end of an info field var).
; See defproc GetInfoFieldValue for all new defined info field vars.
; A single '*' is replaced by the definition for the separator.
; To get a '*' char, it must be escaped by another '*': '**' gives '*'
; To get a '<' char, it must be escaped by another '<': '<<' gives '<'
; To get a '>' char, it must be escaped by another '>': '>>' gives '>'
defproc ResolveInfoFields( Fields, var Flags)

   Flags = ''
   -- replace separator chars '*' with '<SEP>'
   startp = 1
   do forever
      p = pos( '*', Fields, startp)
      if not p then
         leave
      endif
      if substr( Fields, p + 1, 1) = '*' then  -- if '*' is escaped by another '*', gobble the 2nd
         Fields = substr( Fields, 1, p) ||
                  substr( Fields, p + 2)
         startp = p + 1
      else  -- if a single '*', then it is a separator
         Fields = substr( Fields, 1, p - 1) ||
                  '<SEP>' ||
                  substr( Fields, p + 1)
         startp = p + length('<SEP>')
      endif
   enddo -- forever

   -- resolve '<...>' for 'setstatustemplate' command
   startp = 1
   do forever
      -- find '<'
      p1 = pos( '<', Fields, startp)
      if not p1 then
         leave
      endif
      -- find '<<' at p1 and replace '<<' with '<'
      if substr( Fields, p1, 2) = '<<' then
         Fields = substr( Fields, 1, p1) ||
                  substr( Fields, p1 + 2)
         startp = p1 + 1
      else
         startp = p1 + 1
         -- find '>'
         p2 = pos( '>', Fields, startp)
         if not p2 then
            leave
         endif
         -- don't replace '>>'
         if substr( Fields, p2, 2) = '>>' then
            startp = p2 + 2
         else
            -- resolve var '<...>'
            FValue = GetInfoFieldValue( substr( Fields, p1 + 1, p2 - p1 - 1), FFlag)
            Fields = substr( Fields, 1, p1 - 1) ||
                     FValue ||
                     substr( Fields, p2 + 1)
            if (FFlag <> '' & wordpos( FFlag, Flags) = 0) then
               Flags  = Flags' 'FFlag
            endif
            startp = p1 + length(FValue)
         endif
      endif
   enddo  -- forever

   -- replace '>>' with '>'
   startp = 1
   do forever
      p = pos( '>>', Fields, startp)
      if p then
         Fields = substr( Fields, 1, p) ||
                  substr( Fields, p + 2)
         startp = p + 1
      else
         leave
      endif
   enddo
   Flags = strip(Flags)

   return Fields

; ---------------------------------------------------------------------------
; Helper for defproc GetInfoFieldValue.
; Return .filename with name = .LONGNAME.
defproc GetFileName
   universal show_longnames
   Filename = .filename
   if leftstr( Filename, 1) <> '.' then  -- if not a temp file
      if show_longnames then
         Longname = get_EAT_ASCII_value('.LONGNAME')
         if Longname <> '' then
            Filepath = leftstr( Filename, lastpos( '\', Filename))
            Filename = Filepath || Longname
         endif
      endif
   endif
   return Filename

; ---------------------------------------------------------------------------
; Replace info field vars with '%...' or other values
defproc GetInfoFieldValue(FVar, var FFlag)
   universal tab_key
   universal stream_mode
   universal expand_on
   universal matchtab_on
   universal cua_marking_switch
   universal activeaccel

   -- Get Sep
   Sep = GetFieldSep()

   FVar = upcase(FVar)
   FValue = ''
   FFlag  = ''

   -- Synonyms:
   if     FVar = 'MARGINS'  then FVar = 'MA'
   elseif FVar = 'MOD'      then FVar = 'MODIFIED'
   elseif FVar = 'LOCK'     then FVar = 'LOCKED'
   elseif FVar = 'NAME'     then FVar = 'FILENAME'
   elseif FVar = 'DTMOD'    then FVar = 'DATETIMEMODIFIED'
   elseif FVar = 'STREAM'   then FVar = 'STREAMMODE'
   elseif FVar = 'LINEMODE' then FVar = 'STREAMMODE'
   elseif FVar = 'SYNTAX'   then FVar = 'EXPAND'
   elseif FVar = 'SYNTAXEXPANSION' then FVar = 'EXPAND'
   elseif FVar = 'ADVANCEDMARKING' then FVar = 'MARKINGMODE'
   elseif FVar = 'CUAMARKING'      then FVar = 'MARKINGMODE'
   elseif FVar = 'KEYS'            then FVar = 'KEYSET'
   elseif FVar = 'SPELLCHECK'      then FVar = 'DYNASPELL'
   elseif FVar = 'SPELL'           then FVar = 'DYNASPELL'
   elseif FVar = 'DICTLANG'        then FVar = 'DICT'
   endif

   if     FVar = 'SEP'              then FValue = Sep
   -- Internal refreshed fields
   elseif FVar = 'LINES'            then FValue = '%S'
   elseif FVar = 'LINE'             then FValue = '%L'
   elseif FVar = 'COL'              then FValue = '%C'
   elseif FVar = 'HEX'              then FValue = '%X'
   elseif FVar = 'DEC'              then FValue = '%Z'
   elseif FVar = 'INS'              then FValue = '%I'
   elseif FVar = 'MODIFIED'         then FValue = '%M'
   elseif FVar = 'AUTOSAVE'         then FValue = '%A'
;  elseif FVar = ''                 then FValue = '%F'  -- better use filesinring() to customize the text part
   -- Additional fields
   elseif FVar = 'FILE'             then FValue = GetFileNumber()
                                         FFlag  = 'FILELIST'
   elseif FVar = 'FILES'            then FValue = filesinring()
                                         FFlag  = 'FILELIST'
   elseif FVar = 'MODE'             then FValue = GetMode()
                                         FFlag  = 'MODE'
   elseif FVar = 'MA'               then FValue = .margins
                                         FFlag  = 'MARGINS'
   elseif FVar = 'TABS'             then FValue = word( .tabs, 1 )                       -- show only 1st tab
                                         FFlag  = 'TABS'
   elseif FVar = 'TABKEY'           then FValue = word( 'off on', (tab_key = 1) + 1)     -- show 'on' or 'off'
                                         FFlag  = 'TABKEY'
   elseif FVar = 'MATCHTAB'         then FValue = word( '- match', (matchtab_on = 1) + 1)  -- show '-' or 'match'
                                         FFlag  = 'MATCHTAB'
   elseif FVar = 'LOCKED'           then FValue = word( 'L -', (.lockhandle = 0) + 1)    -- show 'L' or '-'
                                         FFlag  = 'LOCKED'
   elseif FVar = 'READONLY'         then FValue = word( '- R', (.readonly = 0) + 1)      -- show 'R' or '-'
                                         FFlag  = 'READONLY'
   elseif FVar = 'FILENAME'         then FValue = GetFileName()
                                         FFlag  = 'FILE'
   elseif FVar = 'DATETIME'         then FValue = NepmdQueryPathInfo('MTIME')            -- show YYYY/MM/DD HH:MM:SS from file on disk
                                         FFlag  = 'FILE'
   elseif FVar = 'ATTR'             then FValue = NepmdQueryPathInfo('ATTR')             -- show 'ADSHR' or '-----'
                                         FFlag  = 'FILE'
   elseif FVar = 'SIZE'             then FValue = NepmdQueryPathInfo('SIZE')             -- show size in bytes
                                         FFlag  = 'FILE'
   elseif FVar = 'EASIZE'           then FValue = NepmdQueryPathInfo('EASIZE')           -- show size of EAs in bytes
                                         FFlag  = 'FILE'
   elseif FVar = 'DATETIMEMODIFIED' then FValue = GetDateTimeModified()                  -- show date - time or modified or other infos
                                         FFlag  = 'MODIFIED'
   elseif FVar = 'STREAMMODE'       then FValue = word( 'L S', (stream_mode = 1) + 1)    -- show 'S' or 'L'
                                         FFlag  = 'STREAMMODE'
   elseif FVar = 'EXPAND'           then FValue = word( '- X', (expand_on = 1) + 1)      -- show '-' or 'X'
                                         FFlag  = 'EXPAND'
   elseif FVar = 'MARKINGMODE'      then FValue = word( 'Adv CUA', (cua_marking_switch = 1) + 1)  -- show 'CUA' or 'Adv'
                                         FFlag  = 'MARKINGMODE'
;   elseif FVar = 'KEYSET'           then FValue = activeaccel
   elseif FVar = 'KEYSET'           then FValue = activeaccel' = 'GetAVar( 'keyset.'activeaccel)
                                         FFlag  = 'KEYSET'
   elseif FVar = 'CODINGSTYLE'      then FValue = GetCodingStyle()
                                         FFlag  = 'FILE'
   elseif FVar = 'DYNASPELL'        then FValue = word( '- Spchk', (activeaccel = 'spell') + 1)  -- show '-' or 'Spchk'
                                         FFlag  = 'KEYS'
   elseif FVar = 'DICT'             then FValue = GetDictBaseName()
                                         FFlag  = 'DICT'
; not fully implemented yet, just for testing:
   elseif FVar = 'SECTION' & isadefproc( 'GetCurSection') then FValue = GetCurSection()  -- shows current section or function
   endif

   return FValue

; ---------------------------------------------------------------------------
; Called with a string to set the statusline text to that string; with no
; argument to just set the statusline color.
defc SetStatusLine
   universal vstatuscolor
   universal vmodifiedstatuscolor
   universal current_status_template

   if .modify = 0 then
      newstatuscolor = vstatuscolor
   else
      newstatuscolor = vmodifiedstatuscolor
   endif
   if arg(1) then
      current_status_template = arg(1)
      template = atoi( length( current_status_template)) || current_status_template
      template_ptr = put_in_buffer( template)
   else
      template_ptr=0
   endif
   call windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),
                       5431,      -- EPM_FRAME_STATUSLINE
                       template_ptr,
                       newstatuscolor )

; ---------------------------------------------------------------------------
; Called with a string to set the messageline text to that string. That text
; will be diplayed until the next message text is set. The timer won't apply
; here. Additionally, the message text won't be saved to the message box. So,
; using an arg is not very useful. When called with no argument, the
; messageline color is just set.
defc SetMessageLine
   universal vmessagecolor

   if arg(1) then
      template = atoi( length( arg(1))) || arg(1)
      template_ptr = put_in_buffer( template)
   else
      template_ptr = 0
   endif
   call windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),
                       5432,      -- EPM_FRAME_MESSAGELINE
                       template_ptr,
                       vmessagecolor)

; ---------------------------------------------------------------------------
; Note: It's not possible to reset the color for a following message. Color
;       setting applies always immediately. The behavior of internally
;       created messages can't be redefined. In order to use the correct
;       color for them, the standard color of the message line can't be
;       changed temporarily, without installing a PM hook.
defc SayHint
   display -8  -- disable addition to the message box
   sayerror arg(1)
   display 8   -- enable addition to the message box

; ---------------------------------------------------------------------------
; defmodify is triggered
;    1)  when .modify changes from 0 to > 0
;    2)  when .modify changes from < .autosave to >= .autosave
;    3)  when .modify changes from > 0 to 0
;    4)  when a modified file is selected after a non-modified file
;    5)  when a non-modified file is selected after a modified file
; The universal var ModifyDisabled can be used to disable defmodify
; processing. Since defmodify code is used at several places, the execution
; of the defmodify code has also be checked for this universal var at all
; these places to disable them all.
defmodify
   universal lastselectedfid
   universal InfolineRefresh  -- Disable refresh of infolines if = 0
;   universal ModifyDisabled   -- Disable processing of defmodify code, if
                               -- checked
;   if ModifyDisabled <> 1 then
      getfileid fid
      -- Don't process the following on file switching (cases 4) and 5))
      if fid = lastselectedfid & lastselectedfid <> '' then

         do i = 1 to 1
            -- Init universal var if this is the first selected file
            if lastselectedfid = '' then
               lastselectedfid = fid
            endif

            if not (InfolineRefresh = 0) then
               ModifiedChanged = 0
               ret = GetDateTimeModified()  -- get last saved value of array var
               -- no need for a refresh if modified state hasn't changed
               if ((ret <> 'Modified' & .modify > 0) | (ret = 'Modified' & .modify = 0)) then
                  ModifiedChanged = 1
               endif
               if ModifiedChanged then
                  'ResetDateTimeModified FORCE'
                  'RefreshInfoLine MODIFIED'
                  'SetStatusLine'  -- update color of statusline
               endif
            endif
         enddo

; Commented out, because: The following would disable resetting the modify
; state for tmp files, like .NEPMD_INFO. .modify is reset, but both the
; title bar and the status bar color show the modified state.
;         ModifyDisabled =  1    -- Disable defmodify immediately
;         'postme EnableModify'  -- Reenable defmodify delayed
      endif
;   endif

; ---------------------------------------------------------------------------
; Executed by ProcessSelect, using the afterselect hook.
defc ProcessSelectRefreshInfoline
   if not .visible then
      return
   endif
;   call NepmdPmPrintf('PROCESSSELECTREFRESHINFOLINE: executing refreshinfoline -- '.filename)
   'ResetDateTimeModified'  -- required to check file on disk
   Flags = 'TABS TABKEY MATCHTAB MODE MARGINS FILE SECTION MODIFIED' ||
           ' STREAMMODE EXPAND MARKINGMODE KEYSET'
   'RefreshInfoLine' Flags

; ---------------------------------------------------------------------------
; Add cmd to the afterselect hook.
definit
   'HookAdd afterselect ProcessSelectRefreshInfoLine'

; ---------------------------------------------------------------------------
; Moved defproc settitletext() from STDCTRL.E to INFOLINE.E
; See also: MODIFY.E (SHOW_MODIFY_METHOD),
;                    call show_modify() is obsolete (SELECT.E in epmbbs only)
; See also: STDCMDS.E, defc n,name
; See also: STDCMDS.E, defc s,save
; See also: ENTER.E, def c_enter, c_pad_enter=
/*
旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
� what's it called: settitletext                                             �
�                                                                            �
� what does it do : set the text in the editors active title bar.            �
�                                                                            �
읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
*/
; unused
defproc SetTitleText()
   text = arg(1)
;compile if SHOW_MODIFY_METHOD = 'TITLE'  -- obsolete
;   if .modify then
;      text = text || SHOW_MODIFY_TEXT
;   endif
;compile endif
   .titletext = text
   return

; ---------------------------------------------------------------------------
defc SetTitleText
   --call NepmdPmPrintf( 'SETTITLETEXT called with' arg(1)', hwnd = 0x'ltoa( gethwndc(6), 16))
   .titletext = arg(1)
   --refresh  -- Required when altered file was selected with the 'List ring' dialog.
              -- Otherwise titletext will be updated just on the next (internal) refresh,
              -- while messageline shows the text 'Altered by another application'
              -- correctly.
              -- Disabled, because it slows file loading down.

; ---------------------------------------------------------------------------
defc RefreshTitleText
   'SetTitleText 'GetTitleFields()

; ---------------------------------------------------------------------------
const
compile if not defined( SLOW_DRIVES)
   SLOW_DRIVES = 'A: B:'
compile endif
compile if not defined( SLOW_FILESYSTEMS)
   SLOW_FILESYSTEMS = 'CDFS UDF'
compile endif

defc ResetDateTimeModified
   universal InfolineRefresh  -- Disable refresh of infolines if = 0

   do i = 1 to 1
      ThisDrive = upcase( substr( .filename, 1, 2))
      if InfolineRefresh = 0 then
         leave
      elseif arg(1) = 'FORCE' then
         -- Force reset; no checks; used by defmodify
      -- Don't act on files from slow drives or if file is readonly
      elseif .readonly then
         leave
      elseif browse() then
         leave
      elseif leftstr( .filename, 1) = '.' then
         leave
      elseif wordpos( ThisDrive, SLOW_DRIVES) then
         leave
      elseif wordpos( QueryFileSys( ThisDrive), SLOW_FILESYSTEMS) then
         leave
      else
         /* -- Better avoid additional disk access
         -- If .readonly is deactivated (standard in EPM)
         rcx = qfilemode( .filename, attrib)  -- DosQFileMode
         --dprintf( 'ResetDateTimeModified: qfilemode for '.filename)
         if not rcx then
            readonly = (attrib // 2)
            if readonly then
               leave
            endif
         endif
         */
      endif

      --call NepmdPmPrintf( 'DateTime: RESET 'arg(1)', drive = 'upcase( substr( .filename, 1, 2)))
      -- Call it with a flag to redetermine 'datetimemodified.'fid array var
      call GetDateTimeModified( 'RESET')
   enddo

; ---------------------------------------------------------------------------
defproc GetDateTimeModified
   Flag = arg(1)
   getfileid fid
   msg = ''
   DateTime = ''
   ArrayVal = ''
   filename = .filename
   next = ''

   next = GetAVar( 'datetimemodified.'fid)
   if next = '' | Flag = 'RESET' then

      -- if modified
      if .modify > 0 then
         -- display text instead of DateTime
         DateTime = 'Modified'
      else
         -- if not modified and filename is a temp file (starts with '.')
         if leftstr( filename, 1 ) = '.' then

         -- if not modified and filename is not a temp file
         else

            next = GetFileDateHex( filename)
            --next = NepmdQueryPathInfo( .filename, 'MTIME')
            --DateTime = NlsDateTime(next)
            if not rc then
               new_filedatehex = next
               cur_filedatehex = ltoa( substr( .fileinfo, 9, 4), 16)
               if new_filedatehex <> cur_filedatehex then
                  -- if file was altered by another application
                  msg = 'Altered by another application'
               else
                  --DateTime = NlsDateTime(next)
                  DateTime = FileDateHex2DateTime( new_filedatehex)
               endif
            elseif rc = 2   then msg = 'New file'  --'File not found'
            elseif rc = 3   then msg = 'Path not found'
            elseif rc = 6   then msg = 'Invalid handle'
            elseif rc = 15  then msg = 'Drive not valid'
            elseif rc = 18  then msg = 'No more files'
            elseif rc = 21  then msg = 'Drive not ready'
            elseif rc = 26  then msg = 'Unknown media type'
            elseif rc = 87  then msg = 'Invalid parameter'
            elseif rc = 108 then msg = 'Drive locked'
            elseif rc = 111 then msg = 'Buffer overflow'
            elseif rc = 113 then msg = 'No more search handles'
            elseif rc = 206 then msg = 'Filename exceeds range'
            else                 msg = 'DosQueryPathInfo: rc = 'rc
            endif
            -- display text instead of DateTime
            if DateTime = '' then
               DateTime = msg
            endif

         endif
      endif

      -- Output on messageline
      if msg <> '' then
         sayerror filename': 'msg
      endif

      -- Save DateTime or msg as array var
      if msg <> '' then
         ArrayVal = msg
      elseif DateTime <> '' then
         ArrayVal = DateTime
      else
         ArrayVal = 'New'
      endif
      call SetAVar( 'datetimemodified.'fid, ArrayVal)

   elseif next = 'New' then
      DateTime = ''

   else
      DateTime = next

   endif

   return DateTime

; ---------------------------------------------------------------------------
defc ConfigInfoLine
   universal nepmd_hini
   Type = arg(1)
   if Type = 'TITLE' then
      KeyPath  = '\NEPMD\User\InfoLine\TitleFields'
      Title    = 'Enter new string for titletext fields'
      Text     = 'Put the field names in <...> chars.' ||
                  ' Specify * as separator.'
      Cmd      = 'mc /ResetTitleFields/RefreshTitleText'
      -- The following uses only internally defined fields and
      -- therefore avoids the overhead for additional refreshs
      Standard = '<filename>'
   elseif Type = 'STATUS' then
      KeyPath  = '\NEPMD\User\InfoLine\StatusFields'
      Title    = 'Enter new string for statusline fields'
      Text     = 'Put the field names in <...> chars.' ||
                 ' Specify * as separator.'
      Cmd      = 'mc /ResetStatusFields/RefreshStatusLine'
      -- The following uses only internally defined fields and
      -- therefore avoids the overhead for additional refreshs
      --Standard = "Line <line> of <lines> * Col <col> * '<hex>'x/<dec> * <ins> * <modified>"
      Standard = "Line <line> of <lines> * Col <col> * '<hex>'x/<dec> * Ma <ma> * Tabs <tabs>, <tabkey> * <mode> * <keyset> * <section> * <modified>"
   elseif Type = 'SEP' then
      KeyPath  = '\NEPMD\User\InfoLine\Sep'
      Title    = 'Enter new string as separator between fields'
      Text     = 'Default char is \250.' ||
                 ' Surround it with spaces for a poportional font.'
      Cmd      = 'mc /ResetFieldSep/RefreshTitleText/RefreshStatusLine'
      Standard = ' '
   else
      sayerror 'ConfigInfoLine: Error: Unknown parameter "'Type'".'
      return
   endif
   IniValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value entrybox( Title,
                         '/~Set/~Reset/Standard ~EPM/Cancel',
                         IniValue,
                         400,
                         260,
                         atoi(1)              ||
                         atoi(0)              ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   if Button = \1 then
      NepmdWriteConfigValue( nepmd_hini, KeyPath, NewValue)
   elseif Button = \2 then
      NepmdDeleteConfigValue( nepmd_hini, KeyPath)
   elseif Button = \3 then
      NepmdWriteConfigValue( nepmd_hini, KeyPath, Standard)
   elseif Button = \4 then
      return
   endif
   if not rc then
      Cmd
   endif

