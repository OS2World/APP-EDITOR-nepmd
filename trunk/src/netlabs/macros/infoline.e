/****************************** Module Header *******************************
*
* Module Name: infoline.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: infoline.e,v 1.1 2004-01-17 22:22:52 aschn Exp $
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
-----------------------------------------------------------------------
Todo:
-  Make Sep = NEPMD_STATUSLINE_SEP an IniValue
-  Make DefaultField an IniValue (2x)
-  Determine flags from field defs automatically
-  'file' should not redetermine <datetimemodified> to make 'quit' process
   faster
-  Use NLS settings from OS2.INI for DateTime

---- Overview of used InfoLine calls in other files ----
FILELIST.E  defproc GetFileNumber
SECTION.E   defc refreshsection
EDIT.E      defc e,edit,epm: 'ResetDateTimeModified'
                             'RefreshInfoLine MODIFIED'
MOUSE.E     'ResetDateTimeModified'
            'RefreshInfoLine MODIFIED'

STDCMDS.E   defc q,quit: call RingWriteFileNumber()
            defc s,save: 'refreshinfoline FILE'
STDCTRL.E   defc ring_more: call RingWriteFileNumber()
MODE.E      if not QueryDefloadFlag() then
               -- don't process this on defload
              'RefreshInfoLine MODE'
            endif
defmodify
   'ResetDateTimeModified'
   'RefreshInfoLine MODIFIED'

defselect
   'ResetDateTimeModified'
   'RefreshInfoLine TABS TABKEY MODE MARGINS ALTERED FILE SECTION'

defload
   if .visible then
      'RefreshInfoLine FILE'
-----------------------------------------------------------------------
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
const
compile if not defined(NEPMD_STATUSLINE_SEP)
   NEPMD_STATUSLINE_SEP = ' ú '
compile endif

; ---------------------------------------------------------------------
defc RefreshInfoLine
   if .visible then
      Flags = arg(1)
      -- Todo: determine flags from field defs automatically
      StatusLineFlags = GetStatusLineFlags()
      TitleTextFlags  = GetTitleTextFlags()
      do w = 1 to words(Flags)
         Flag = word( Flags, w)
         if wordpos( Flag, StatusLineFlags) > 0 then
            'RefreshStatusLine'
            leave
         endif
      enddo
      do w = 1 to words(Flags)
         Flag = word( Flags, w)
         if wordpos( Flag, TitleTextFlags) > 0 then
            'RefreshTitleText'
            leave
         endif
      enddo
   endif

; ---------------------------------------------------------------------
defproc GetStatusLineFlags
   StatusLineFlags = 'MARGINS TABS TABKEY MODE FILE MODIFIED'
   return StatusLineFlags

; ---------------------------------------------------------------------
defproc GetTitleTextFlags
   TitleTextFlags  = 'FILE FILELIST MODIFIED ALTERED'
   return TitleTextFlags

; ---------------------------------------------------------------------
; refreshstatusline refreshes the statusline with the current values.
;
; This defc is required, if the statusbar template should contain
; non-standard patterns (without a '%'). Then it doesn't suffice to set the
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
;    Against this, the internal defined statusbar patterns (all values with a '%')
;    are refreshed immediately.
;
; Standard EPM statusline patterns:
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

; ---------------------------------------------------------------------
defproc GetStatusFields
   universal StatusFieldFlags

   DefaultFields =  "Line <line> of <lines>"    ||
                    " * Col <col>"              ||
                    " * '<hex>'x/<dec>"         ||
                    " * Ma <ma>"                ||
                    " * Tabs <tabs>, <tabkey>"  ||
;                   " * <ins>"                  ||
                    " * <mode>"                 ||
;                   " * <datetime>"             ||
;                   " * <attr>"                 ||
;                   " * <size> B"               ||
;                   " * File <file> of <files>" ||
                    " * <modified>"             ||
;                   " * <section>"              ||
                    ""
   StatusFieldFlags = 'MARGINS TABS TABKEY MODE MODIFIED SECTION'  -- currently unused

   -- Note: The length for the StatusLine string is limitted.
   KeyPath = ''
   IniValue = ''
   if IniValue <> '' then
      Fields = IniValue
   else
      Fields = DefaultFields
   endif
   return ResolveInfoFields(Fields)

; ---------------------------------------------------------------------
defproc GetTitleFields
   universal TitleFieldFlags

   DefaultFields = "<file>/<files>"        ||
                   " * <filename>"         ||
                   " * <datetimemodified>" ||
                   ""

   Flags = 'FILE ALTERED MODIFIED'  -- currently unused

   KeyPath = ''
   IniValue = ''
   if IniValue <> '' then
      Fields = IniValue
   else
      Fields = DefaultFields
   endif
   return ResolveInfoFields(Fields)

; ---------------------------------------------------------------------
; Standard EPM %... patterns may be used here too for compatibility.
; The string '<InfoFieldVar>' will be replaced by its value.
; Therefore a new escape char pair '<' and '>' is introduced (at the
; start and end of an info field var).
; See defproc GetInfoFieldValue for all new defined info field vars.
; A single '*' is replaced by the definition for the separator.
; To get a '*' char, it must be escaped by another '*': '**' gives '*'
; To get a '<' char, it must be escaped by another '<': '<<' gives '<'
; To get a '>' char, it must be escaped by another '>': '>>' gives '>'
defproc ResolveInfoFields(Fields)

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
            FValue = GetInfoFieldValue( substr( Fields, p1 + 1, p2 - p1 - 1))
            Fields = substr( Fields, 1, p1 - 1) ||
                     FValue ||
                     substr( Fields, p2 + 1)
            startp = p1 + length(FValue) + 1
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

   return Fields

; ---------------------------------------------------------------------
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

; ---------------------------------------------------------------------
; Replace info field vars with '%...' or other values
defproc GetInfoFieldValue(FVar)
   universal tab_key

   -- Get Sep
   KeyPath = ''
   IniValue = ''
   if IniValue <> '' then
      Sep = IniValue
   else
      Sep = NEPMD_STATUSLINE_SEP  --<-------------------------------------------- IniValue
   endif

   FVar = upcase(FVar)
   FValue = ''
   if     FVar = 'SEP'              then FValue = Sep
   elseif FVar = 'LINES'            then FValue = '%S'
   elseif FVar = 'LINE'             then FValue = '%L'
   elseif FVar = 'COL'              then FValue = '%C'
   elseif FVar = 'HEX'              then FValue = '%X'
   elseif FVar = 'DEC'              then FValue = '%Z'
   elseif FVar = 'INS'              then FValue = '%I'
   elseif FVar = 'MODIFIED'         then FValue = '%M'
   elseif FVar = 'AUTOSAVE'         then FValue = '%A'
;  elseif FVar = ''                 then FValue = '%F'  -- better use filesinring() to customize the text part
   elseif FVar = 'FILE'             then FValue = GetFileNumber()
   elseif FVar = 'FILES'            then FValue = filesinring()
   elseif FVar = 'MODE'             then FValue = NepmdGetMode()
   elseif FVar = 'MA'               then FValue = .margins
   elseif FVar = 'TABKEY'           then FValue = word( 'off on', tab_key + 1 )          -- show 'on' or 'off'
   elseif FVar = 'TABS'             then FValue = word( .tabs, 1 )                       -- show only 1st tab
   elseif FVar = 'LOCKED'           then FValue = word( 'L -', (.lockhandle <> 0) + 1 )  -- show 'L' or '-'
   elseif FVar = 'READONLY'         then FValue = word( '- R', .readonly + 1 )           -- show 'R' or '-'
   elseif FVar = 'FILENAME'         then FValue = .filename
   elseif FVar = 'DATETIME'         then FValue = QueryPathInfo('MTIME')                 -- show YYYY/MM/DD HH:MM:SS from file on disk
   elseif FVar = 'ATTR'             then FValue = QueryPathInfo('ATTR')                  -- show 'ADSHR' or '-----'
   elseif FVar = 'SIZE'             then FValue = QueryPathInfo('SIZE')                  -- show size in bytes
   elseif FVar = 'EASIZE'           then FValue = QueryPathInfo('EASIZE')                -- show size of EAs in bytes
   elseif FVar = 'DATETIMEMODIFIED' then FValue = GetDateTimeModified()                  -- shows date - time or modified or other infos
; not implemented yet:
;  elseif FVar = 'SECTION'          then FValue = GetCurSection()                        -- shows current section or function
   endif

   return FValue

; ---------------------------------------------------------------------
; Moved defc setstatusline from STDCTRL.E to STATLINE.E to INFOLINE.E
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

; ---------------------------------------------------------------------
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
   ret = GetDateTimeModified()
   -- no need for a refresh if modified state hasn't changed
   if ((ret <> 'Modified' & .modify > 0) | (ret = 'Modified' & .modify = 0)) then
      ModifiedChanged = 1
   endif
   if ModifiedChanged then
      'ResetDateTimeModified FORCE'
      'RefreshInfoLine MODIFIED'
      'SetStatusLine'  -- update color of statusline
   endif

defselect
   universal lastselectedfid
   -- workaround for defselect->defmodify
   getfileid lastselectedfid
   'ResetDateTimeModified'  -- required to check file on disk
   'RefreshInfoLine TABS TABKEY MODE MARGINS ALTERED FILE SECTION MODIFIED'

; ---------------------------------------------------------------------
; Moved defproc settitletext() from STDCTRL.E to STATLINE.E
; See also: MODIFY.E (SHOW_MODIFY_METHOD),
;                    call show_modify() is obsolete (SELECT.E in epmbbs only)
; See also: STDCMDS.E, defc n,name
; See also: STDCMDS.E, defc s,save
; See also: ENTER.E, def c_enter, c_pad_enter=

; ---------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: settitletext                                             ³
³                                                                            ³
³ what does it do : set the text in the editors active title bar.            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
/*
defproc settitletext()
   text = arg(1)
compile if SHOW_MODIFY_METHOD = 'TITLE'
   if .modify then
      text = text || SHOW_MODIFY_TEXT
   endif
compile endif
   .titletext = text
   return
*/

defc SetTitleText
   .titletext = arg(1)

; ---------------------------------------------------------------------
defc RefreshTitleText
   call NepmdPmPrintf( 'INFOLINE.E - RefreshTitleText called. Remove?')
   'SetTitleText 'GetTitleFields()

; ---------------------------------------------------------------------
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

      -- if modified
      if .modify > 0 then
         -- display text instead of DateTime
         DateTime = 'Modified'
      else
         -- if not modified and filename is a temp file (starts with '.')
         if leftstr( filename, 1 ) = '.' then

         -- if not modified and filename is not a temp file
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
                  msg = 'File was altered by another application'
               else
                  --DateTime = NlsDateTime(next)
                  DateTime = filedatehex2datetime(next)
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
defproc get_filedatehex(filename)
   pathname = filename\0
   resultbuf = copies(\0,30)
   result = dynalink32('DOSCALLS',      /* dynamic link library name       */
                       '#223',           /* ordinal value for DOS32QueryPathInfo  */
                       address(pathname)         ||  -- pathname to be queried
                       atol(1)                   ||  -- PathInfoLevel
                       address(resultbuf)        ||  -- buffer where info is to be returned
                       atol(length(resultbuf)) )     -- size of buffer
   filedatehex = ltoa(substr(resultbuf, 9, 4), 16)
   if result = 0 then
      -- the return value can be compared with ltoa(substr(.fileinfo, 9, 4), 16)
      ret = filedatehex
   else
      ret = 'ERROR:'result
   endif
   return ret

; ---------------------------------------------------------------------------
; Todo: use NLS settings from OS2.INI
defproc filedatehex2datetime(hexstr)
   -- add leading zero if length < 8
   hexstr = rightstr( hexstr, 8, 0 )

   date = hex2dec( substr( hexstr, 5, 4 ) )
   year = date % 512; date = date // 512
   month = date % 32; day = date // 32 % 1     -- %1 to drop fraction.
;   date = year+1980'/'rightstr(month,2,0)'/'rightstr(day,2,0)  -- english date  yyyy/mm/dd
;   date = rightstr(day,2,0)'.'rightstr(month,2,0)'.'year+1980  -- german date   dd.mm.yyyy
   date = year+1980'-'rightstr(month,2,0)'-'rightstr(day,2,0)  -- ISO date   yyyy-mm-dd

   time = hex2dec( substr( hexstr, 1, 4 ) )
   hour = time % 2048; time = time // 2048
   min = time % 32; sec = time // 32 * 2 % 1
   time = hour':'rightstr(min,2,0)':'rightstr(sec,2,0)  -- german time hh:mm:ss

   return date time

