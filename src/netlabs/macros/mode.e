/****************************** Module Header *******************************
*
* Module Name: mode.e
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

; ---------------------------------------------------------------------------
; Returns the current mode.
; Get mode from array var 'mode.'fid.
; If mode not set: get mode from EA 'EPM.MODE'.
; If mode not set: get default mode.
defproc GetMode
   Filename = arg(1)
   if Filename = '' then
      Filename = .filename
      getfileid fid  -- for current file
   else
      getfileid fid, Filename  -- for first found file ring with name = Filename
   endif

   IsATempFile  = (leftstr( Filename, 1 ) = '.')

   -- Get CurMode for Filename by querying an array var
   CurMode = GetAVar( 'mode.'fid)
   -- Save this value as SavedMode
   SavedMode = CurMode

   if CurMode = '' & not IsATempFile then
      -- Get CurMode from EA EPM.MODE
      CurMode = NepmdQueryStringEa( Filename, 'EPM.MODE')
   endif

   if CurMode = '' then
      -- if it's a temp filename starting with '.'
      -- set DefaultMode here to not have NepmdQueryDefaultMode go through
      -- all ini files in the mode dirs
      CurMode = 'TEXT' -- general default mode
      -- call NepmdQueryDefaultMode only
      --    -  if filename doesn't start with a '.' or
      --    -  if file is a command shell
      if (not IsATempFile) or IsAShellFileName() then
         -- Get default mode
         rc = 0
         DefaultMode = NepmdQueryDefaultMode(Filename)
         if DefaultMode = '' then
            sayerror "Default mode can't be determined. NepmdQueryDefaultMode returned rc = "rc"."
            DefaultMode = 'TEXT'
         endif
         CurMode = DefaultMode
      endif  -- not IsATempFile
   endif

   -- Update array var 'mode.'fid if CurMode has changed
   if CurMode <> SavedMode then
      call SetAVar( 'mode.'fid, CurMode)
   endif

   return CurMode

defproc NepmdGetMode
   parse arg args
   return GetMode( args)

; ---------------------------------------------------------------------------
; Extra procedure for getting the CheckFlag to allow using a universal var
; during the defload event.
; HiliteModeList is reset by defproc ResetHiliteModeList, called by defc edit.
defproc GetHiliteCheckFlag
   universal HiliteModeList
   Mode = arg(1)

   -- make sure each mode is checked for only once
   if (wordpos( Mode, HiliteModelist) = 0) then
      HiliteModeList = HiliteModeList Mode
      CheckFlag = ''
   else
      CheckFlag = 'N'  -- 'N' means: no check for new highlighting definition files
   endif

   return CheckFlag

; ---------------------------------------------------------------------------
; Deletes the HiliteModeList. Not called by defc edit anymore to save disk
; activity and to improve stability. The universal var is automatically
; emptied on start of a new EPM window.
defproc ResetHiliteModeList
   universal HiliteModeList

   HiliteModeList = ''
   return

; ---------------------------------------------------------------------------
; Resets and redetermines current mode.
; Processes settings for current mode only if current mode <> old mode.
; arg(1) = old mode.
; Called by defc s,save.
;
; Use a command for to call it with 'postme' from defc s,save
; Otherwise a MessageBox (defined in ETK) will pop up when
;    -  the window should be closed and
;    -  there is a modified file in the ring and
;    -  the file was saved.
; The file *was* saved but the MessageBox says that there has
; occured an error saving the file.
;
; Another possibility could be to disable every internal switching
; of files in the ring. Especially selecting files from the 'ring_more'
; ListBox temporarily will not update the Statusline. It was
; only updated after the ListBox was closed.
defc ResetMode
   OldMode = arg(1)

   -- Set 'mode.'fid to an empty string to make GetMode redetermine
   -- the current mode
   getfileid fid
   ResetMode = ''
   call SetAVar( 'mode.'fid, ResetMode)

   -- Get current mode
   CurMode = GetMode()

   -- Does it differ from old mode?
   -- If not, skip
   if CurMode <> OldMode then
      -- Process all mode dependent settings
      'ResetFileSettings'
   endif

; ---------------------------------------------------------------------------
; Changes the current mode.
;
; This command uses the NEPMDLIB EA functions to change the EA 'EPM.MODE'
; immediately.
;
; With the E functions only the EA area is changed. The EAs would only be saved
; when the file is saved.
;
; Both are used here: The NEPMDLIB functions to keep the EA after quitting and the
; E functions to get the current EA value quickly from .eaarea.
;
; Additionally, the current mode (from 'EPM.MODE' or the default mode) is saved in
; the array var 'mode.'fid. This is called by commands that have mode dependent
; setting: hili, refreshstatusline
;
; Syntax: mode [arg1 [noea]]
;
;    arg1 = (NewMode|0|OFF|DEFAULT)
;           NewMode can be any valid mode.
;
;    args are caseless. It doesn't matter, which comes first.
;    If no arg specified, then a listbox is opened for selecting a mode.
defc Mode
   universal loadstate

   arg1 = strip( upcase( arg(1)))
   ResetModeArgs = '0 OFF DEFAULT'

   -- Write EA?
   fSetEa = 1  -- default value
   wp = wordpos( 'NOEA', arg1)
   if wp > 0 then
      arg1 = strip( delword( arg1, wp, 1))
      fSetEa = 0
   endif

   -- Write EA later, maybe on save-as?
   fReadonly = 0  -- default value
   if (.readonly | leftstr( .filename, 1) = '.') then
      fReadonly = 1
   elseif GetReadonly( .filename) <> 0 then  -- returns '' if file doesn't exist
      fReadonly = 1
   endif

   NewMode = arg1
   if NewMode <> '' & wordpos( NewMode, ResetModeArgs) = 0 then
      -- Check if mode exists
      ModeList = NepmdQueryModeList()
      if rc then
         sayerror 'List of EPM modes could not be determined, rc = 'rc'.'
         stop
      elseif wordpos( NewMode, ModeList) = 0 then
         sayerror NewMode' is not a valid mode'
         if loadstate = 0 then  -- after AfterLoad was processed
            -- Reset to empty to open the SelectMode dialog
            NewMode = ''
         else
            return 87  -- ERROR_INVALID_PARAMETER
         endif
      endif
   endif

   if NewMode = '' then
      -- Ask user to set a mode
      NewMode = upcase( SelectMode())
   endif

   if NewMode = '' then
      return 87  -- ERROR_INVALID_PARAMETER

   elseif wordpos( NewMode, ResetModeArgs) > 0 then
      -- Get the default mode
      NewMode =  NepmdQueryDefaultMode(.filename)
      if NewMode = '' then
         sayerror "Default mode can't be determined. NepmdQueryDefaultMode returned rc = "rc"."
      endif

      -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value.
      -- This will delete the EA on save-as if the source file was readonly.
      call delete_ea('EPM.MODE')
      if fSetEa then
         if not fReadonly then
            -- Delete the EA 'EPM.MODE' immediately
            NepmdDeleteStringEa( .filename, 'EPM.MODE' )
            if rc then
               sayerror 'EA "EPM.MODE" not deleted, rc = 'rc'.'
            endif
         endif
      endif

   else
      -- Update the EPM EA area to make get_EAT_ASCII_value show the actual value.
      call delete_ea('EPM.MODE')
      if fSetEa then
         -- This will write the EA on save-as if the source file was readonly.
         'add_ea EPM.MODE' NewMode
         if not fReadonly then
            -- Set the EA 'EPM.MODE' immediately
            NepmdWriteStringEa( .filename, 'EPM.MODE', NewMode)
            if rc then
               sayerror 'EA "EPM.MODE" not set, rc = 'rc'.'
            endif
         endif
      endif
   endif

   -- Save mode in an array var for the statusline and for hili
   getfileid fid
   call SetAVar( 'mode.'fid, NewMode)

   -- Process all mode specific settings
   'ResetFileSettings'

; ---------------------------------------------------------------------
; Opens a listbox to select a mode.
; Called by defc mode if no arg specified.
defproc SelectMode()

   -- Determine current mode
   CurMode = get_EAT_ASCII_value('EPM.MODE')
   DefMode = NepmdQueryDefaultMode( .filename)

   if CurMode = '' then
      SelectedMode = DefMode
      Text = 'Default mode:' SelectedMode
   else
      SelectedMode = CurMode
      Text = 'Selected mode:' SelectedMode
   endif

   -- Check mode list and add default entry
   ModeList = NepmdQueryModeList()
   if rc then
      sayerror 'List of EPM modes could not be determined, rc = 'rc'.'
      stop
   endif

   -- Determine default selection
   Selection = wordpos( SelectedMode, ModeList)
   Title = 'Mode selection'

   refresh
   ret = ''
   select = listbox( Title,
                     ModeList,
                     '/~Set/~Reset/Cancel',          -- buttons
                     0, 0,  --5, 5,                  -- top, left,
                     min( words(ModeList), 12), 25,  -- height, width
                     gethwnd(APP_HANDLE) || atoi(Selection) || atoi(1) || atoi(0) ||
                     Text\0 )
   refresh

   -- Check result
   button = asc(leftstr( select, 1))
   EOS = pos( \0, select, 2)        -- CHR(0) signifies End Of String
   if button = 1 then
      ret = substr( select, 2, EOS - 2)
   elseif button = 2 then
      ret = 'DEFAULT'
   elseif button = 3 then
      ret = ''
   endif
   if ((ret = DefMode) | (ret = 'DEFAULT')) then
      ret = 'OFF'
   end

   return ret

; ---------------------------------------------------------------------------
defproc QueryModeKey( Mode, Key)
   universal nepmd_hini

   default_value = arg(3)
   PathPrefix = '\NEPMD\User\Mode'
   KeyPath = PathPrefix'\'Mode'\'Key
   next = strip( NepmdQueryConfigValue( nepmd_hini, KeyPath), 'T', \0)
   if not rc & next <> '' then
      return next
   else
      return default_value
   endif

; ---------------------------------------------------------------------------
; For debugging: remove all mode keys from NEPMD.INI.
defc DelAllModeKeys
   universal nepmd_hini

   ModeList = NepmdQueryModeList()
   KeyList = 'CharSet CaseSensitive' ||
             ' DefExtensions DefNames' ||
             ' LineComment LineCommentPos LineCommentOverrideMulti'||
             ' LineCommentAddSpace LineCommentNeedSpace' ||
             ' PreferredComment' ||
             ' LineCommentPreferred' ||      -- LineCommentPreferred soon to be obsolete
             ' MultiLineCommentStart MultiLineCommentEnd' ||
             ' MultiLineCommentNested'
   if rc then
      sayerror 'List of EPM modes could not be determined, rc = 'rc
      return rc
   endif
   MainPath = '\NEPMD\User\Mode'
   ErrorModes = ''
   rest = ModeList
   do while rest <> ''
      parse value rest with Mode rest
      if Mode <> '' then
         ModePath = MainPath'\'Mode
         do w = 1 to words( KeyList)
            Key = word( KeyList, w)
            KeyPath = ModePath'\'Key
            NepmdDeleteConfigValue( nepmd_hini, KeyPath)
         enddo
      else
         iterate
      endif
   enddo
   sayerror 'Settings for all modes deleted.'

; ---------------------------------------------------------------------------
defc OpenModeDirs
   Mode = strip( arg(1))
   if Mode = '' then
      Mode = GetMode()
   endif
   NetlabsModeDir = Get_Env( 'NEPMD_ROOTDIR')'\netlabs\mode\'Mode
   UserModeDir = Get_Env( 'NEPMD_USERDIR')'\mode\'Mode
   if NepmdDirExists( NetlabsModeDir) then
      'rx open 'NetlabsModeDir
   endif
   if NepmdDirExists( UserModeDir) then
      'rx open 'UserModeDir
   endif

