/****************************** Module Header *******************************
*
* Module Name: infoline.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: infoline.e,v 1.5 2004-07-01 11:39:04 aschn Exp $
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

; Contains defmodify. Therefore it should not be linked, because any
; occurance of defmodify in a linked module would replace all other
; so-far-defined defmodify event defs.

/*
Todo:
-  If file was altered by another file, then the old date is shown in title
   if file was selected by ring_more dialog.  -> won't (can't) fix.
-  'file' should not redetermine <datetimemodified> to make 'quit' process
   faster
*/

const
compile if not defined(NEPMD_MODIFIED_STATUSCOLOR)
   NEPMD_MODIFIED_STATUSCOLOR = LIGHT_GREYB + MAGENTA
compile endif
compile if defined(NEPMD_MODIFIED_STATUSCOLOR)
definit
   universal vNEPMD_MODIFIED_STATUSCOLOR
   vNEPMD_MODIFIED_STATUSCOLOR = NEPMD_MODIFIED_STATUSCOLOR
compile endif

; ---------------------------------------------------------------------------
; Compare args with StatusFieldFlags and TitleFieldFlags. If they match,
; RefreshStatusLine and/or RefreshTitleText is executed.
defc RefreshInfoLine
   universal StatusFieldFlags
   universal TitleFieldFlags
   if .visible then
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
; refreshstatusline refreshes the statusline with the current values.
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
; The default value if STATUS_TEMPLATE is not defined is:
; 'Line %l of %s Column %c  %i   %m   %f'
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
; Helper for defproc GetInfoFieldValue.
; Removes the 'ERROR:'rc return value
; arg(1) = Filename, arg(2) = Keyword for NepmdQueryPathInfo.
; May also be called only with keyword as arg(1). Filename is then
; .filename.
defproc QueryPathInfo
   if arg(2) = '' then
      Filename = .filename
      Keyword = arg(1)
   else
      Filename = arg(1)
      if Filename = '' then
         Filename = .filename
      endif
      Keyword = arg(2)
   endif
   ret = NepmdQueryPathInfo( Filename, Keyword)
   parse value ret with 'ERROR:'rc
   if rc > '' then
      return ''
   else
      return ret
   endif

; ---------------------------------------------------------------------------
; Replace info field vars with '%...' or other values
defproc GetInfoFieldValue(FVar, var FFlag)
   universal tab_key
   universal stream_mode
   universal expand_on
   universal matchtab_on
   universal cua_marking_switch

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
   elseif FVar = 'KEYSET'          then FVar = 'KEYS'
   elseif FVar = 'SPELLCHECK'      then FVar = 'DYNASPELL'
   elseif FVar = 'SPELL'           then FVar = 'DYNASPELL'
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
   elseif FVar = 'MODE'             then FValue = NepmdGetMode()
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
   elseif FVar = 'DATETIME'         then FValue = QueryPathInfo('MTIME')                 -- show YYYY/MM/DD HH:MM:SS from file on disk
                                         FFlag  = 'FILE'
   elseif FVar = 'ATTR'             then FValue = QueryPathInfo('ATTR')                  -- show 'ADSHR' or '-----'
                                         FFlag  = 'FILE'
   elseif FVar = 'SIZE'             then FValue = QueryPathInfo('SIZE')                  -- show size in bytes
                                         FFlag  = 'FILE'
   elseif FVar = 'EASIZE'           then FValue = QueryPathInfo('EASIZE')                -- show size of EAs in bytes
                                         FFlag  = 'FILE'
   elseif FVar = 'DATETIMEMODIFIED' then FValue = GetDateTimeModified()                  -- show date - time or modified or other infos
                                         FFlag  = 'MODIFIED'
   elseif FVar = 'STREAMMODE'       then FValue = word( 'L S', (stream_mode = 1) + 1)    -- show 'S' or 'L'
                                         FFlag  = 'STREAMMODE'
   elseif FVar = 'EXPAND'           then FValue = word( '- X', (expand_on = 1) + 1)      -- show '-' or 'X'
                                         FFlag  = 'EXPAND'
   elseif FVar = 'MARKINGMODE'      then FValue = word( 'Adv CUA', (cua_marking_switch = 1) + 1)  -- show 'CUA' or 'Adv'
                                         FFlag  = 'MARKINGMODE'
   elseif FVar = 'KEYS'             then FValue = .keyset                                -- show 'EDIT_KEYS' (default) or 'REXX_KEYS'
                                         FFlag  = 'KEYS'
   elseif FVar = 'DYNASPELL'        then FValue = word( '- Spchk', (.keyset = 'SPELL_KEYS') + 1)  -- show '-' or 'Spchk'
                                         FFlag  = 'KEYS'
; not implemented yet:
;  elseif FVar = 'SECTION'          then FValue = GetCurSection()                        -- shows current section or function
   endif

   return FValue

; ---------------------------------------------------------------------------
; Moved defc setstatusline from STDCTRL.E to STATLINE.E
; Called with a string to set the statusline text to that string; with no argument
; to just set the statusline color.
defc SetStatusLine
   universal vSTATUSCOLOR, current_status_template
compile if defined(NEPMD_MODIFIED_STATUSCOLOR)
   universal vNEPMD_MODIFIED_STATUSCOLOR
   if .modify = 0 then
      newSTATUSCOLOR = vSTATUSCOLOR
   else
      newSTATUSCOLOR = vNEPMD_MODIFIED_STATUSCOLOR
   endif
compile else
   newSTATUSCOLOR = vSTATUSCOLOR
compile endif
   if arg(1) then
      current_status_template = arg(1)
      template=atoi(length(current_status_template)) || current_status_template
      template_ptr=put_in_buffer(template)
   else
      template_ptr=0
   endif
   call windowmessage( 1,  getpminfo(EPMINFO_EDITCLIENT),
                       5431,      -- EPM_FRAME_STATUSLINE
                       template_ptr,
                       newSTATUSCOLOR )
   return

; ---------------------------------------------------------------------------
defmodify
   -- defmodify is triggered
   -- when .modify changes from 0 to >0
   -- when .modify changes from <.autosave to >=.autosave
   -- when .modify changes from >0 to 0
   -- when a modified file is selected after a non-modified file
   -- when a non-modified file is selected after a modified file
   universal lastselectedfid
   getfileid fid
   if lastselectedfid = '' then
      -- if this is the first selected file
      lastselectedfid = fid
   endif
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

; ---------------------------------------------------------------------------
; Executed by ProcessSelect, using the afterselect hook.
defc ProcessSelectRefreshInfoline
   if not .visible then
      return
   endif
;   call NepmdPmPrintf('PROCESSSELECTREFRESHINFOLINE: executing refreshinfoline -- '.filename)
   'ResetDateTimeModified'  -- required to check file on disk
   Flags = 'TABS TABKEY MATCHTAB MODE MARGINS FILE SECTION MODIFIED' ||
           ' STREAMMODE EXPAND MARKINGMODE KEYS'
   'RefreshInfoLine' Flags

; ---------------------------------------------------------------------------
; Add cmd to the afterselect hook.
definit
   'HookAdd afterselect ProcessSelectRefreshInfoLine'

; ---------------------------------------------------------------------------
; Moved defproc settitletext() from STDCTRL.E to STATLINE.E
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
defproc settitletext()
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
defc ResetDateTimeModified
   do i = 1 to 1
      if arg(1) = 'FORCE' then
         -- force reset; no checks; used by defmodify
      -- Don't act on files from slow drives or if file is readonly
      elseif .readonly then
         leave
      elseif browse() then
         leave
      elseif wordpos( upcase( substr( .filename, 1, 2)), 'A: B:') then
         leave
      elseif QueryFileSys( substr( .filename, 2)) = 'CDFS' then
         leave
      else
         -- if .readonly is deactivated (standard in EPM)
         rc = qfilemode( .filename, attrib)  -- DosQFileMode
         if not rc then
            readonly = (attrib // 2)
            if readonly then
               leave
            endif
         endif
      endif
      --call NepmdPmPrintf( 'DateTime: RESET 'arg(1)', drive = 'upcase( substr( .filename, 1, 2)))
      -- Call it with a flag to redetermine 'datetimemodified.'fid array var
      call GetDateTimeModified( 'RESET')
   enddo

; ---------------------------------------------------------------------------
defproc GetDateTimeModified
   universal EPM_utility_array_ID

   Flag = arg(1)
   getfileid fid
   msg = ''
   DateTime = ''
   ArrayVar = ''
   filename = .filename

   rc = get_array_value( EPM_utility_array_ID, 'datetimemodified.'fid, next)
   if next = '' | Flag = 'RESET' then

      ---- if modified ----
      if .modify > 0 then
         -- display text instead of DateTime
         DateTime = 'Modified'
      else
         ---- if not modified and filename is a temp file (starts with '.') ----
         if leftstr( filename, 1 ) = '.' then

         ---- if not modified and filename is not a temp file ----
         else

            next = get_filedatehex( filename )
            --next = NepmdQueryPathInfo( .filename, 'MTIME')
            --DateTime = NlsDateTime(next)
            parse value(next) with 'ERROR:'rc
            if rc = '' then
               new_filedatehex = next
               cur_filedatehex = ltoa(substr(.fileinfo, 9, 4), 16)
               if new_filedatehex <> cur_filedatehex then
                  -- if file was altered by another application
                  msg = 'Altered by another application'
               else
                  --DateTime = NlsDateTime(next)
                  DateTime = filedatehex2datetime(new_filedatehex)
               endif
            elseif rc = 2   then msg = 'File not found'
            elseif rc = 3   then msg = 'Path not found'
            elseif rc = 6   then msg = 'Invalid handle'
            elseif rc = 18  then msg = 'No more files'
            elseif rc = 26  then msg = 'Unknown media type'
            elseif rc = 87  then msg = 'Invalid parameter'
            elseif rc = 108 then msg = 'Drive locked'
            elseif rc = 111 then msg = 'Buffer overflow'
            elseif rc = 113 then msg = 'No more search handles'
            elseif rc = 206 then msg = 'Filename exceeds range'
            else                 msg = 'DosQueryPathInfo: RC = 'rc
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
         ArrayVar = msg
      elseif DateTime <> '' then
         ArrayVar = DateTime
      else
         ArrayVar = 'New'
      endif
      do_array 2, EPM_utility_array_ID, 'datetimemodified.'fid, ArrayVar


   elseif next = 'New' then
      DateTime = ''

   else
      DateTime = next

   endif  -- if ret = ''

   return DateTime

; ---------------------------------------------------------------------------
defc ConfigFrame
   universal nepmd_hini
   Type = arg(1)
   if Type = 'TITLE' then
      KeyPath = '\NEPMD\User\InfoLine\TitleFields'
      Title   = 'Enter new string for titletext fields'
      Text    = 'Put the field names in <...> chars.' ||
                 ' Specify * as separator.'
      Cmd     = 'mc /ResetTitleFields/RefreshTitleText'
   elseif Type = 'STATUS' then
      KeyPath = '\NEPMD\User\InfoLine\StatusFields'
      Title = 'Enter new string for statusline fields'
      Text    = 'Put the field names in <...> chars.' ||
                 ' Specify * as separator.'
      Cmd     = 'mc /ResetStatusFields/RefreshStatusLine'
   elseif Type = 'SEP' then
      KeyPath = '\NEPMD\User\InfoLine\Sep'
      Title   = 'Enter new string as separator between fields'
      Text    = 'Default char is \250.' ||
                ' Surround it with spaces for a poportional font.'
      Cmd     = 'mc /ResetFieldSep/RefreshTitleText/RefreshStatusLine'
   else
      sayerror 'Unknown arg'
      return
   endif
   IniValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value entrybox( Title,
                         '/~Set/~Reset/~Cancel/~Help',
                         IniValue,
                         400,
                         260,
                         atoi(1)              ||
                         atoi(0)              ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   if Button = \1 then
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, NewValue)
   elseif Button = \2 then
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath)
   elseif Button = \3 then
      return
   endif
   if not rc then
      Cmd
   endif


