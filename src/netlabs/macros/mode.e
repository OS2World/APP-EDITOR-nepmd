/****************************** Module Header *******************************
*
* Module Name: mode.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mode.e,v 1.22 2002-10-21 12:05:21 cla Exp $
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

; Todo:
const
compile if not defined(NEPMD_SPECIAL_STATUSLINE)
   NEPMD_SPECIAL_STATUSLINE = 1
compile endif

; ---------------------------------------------------------------------------
; Returns the current mode.
defproc NepmdGetMode()
   universal EPM_utility_array_ID
   parse arg filename
   if filename = '' then
      filename = .filename
   endif
   getfileid save_fid

   -- Get CurMode for filename
   -- The array var 'mode.'fid was initially set by NepmdInitMode
   getfileid fid, filename
   do_array 3, EPM_utility_array_ID, 'mode.'fid, CurMode

   -- CurMode should be set at this point. If not, get mode from EA or default mode:
   if CurMode = '' then
      -- Get CurMode from EA EPM.MODE:
      activatefile fid
      CurMode = get_EAT_ASCII_value('EPM.MODE')
   endif

   if CurMode = '' then
      -- Get default mode:
      CurMode = NepmdQueryDefaultMode(filename)
      parse value CurMode with 'ERROR:'rc
      if rc > '' then
         sayerror "Default mode can't be determined. NepmdQueryDefaultMode returned rc = "rc
         CurMode = ''
      endif
   endif

   -- Update array var 'mode.'fid
   do_array 2, EPM_utility_array_ID, 'mode.'fid, CurMode

   activatefile save_fid

   return CurMode

; ---------------------------------------------------------------------------
; Resets and redetermines current mode.
; Called by defc s,save.
; arg(1) = OldMode
; NepmdProcessMode is called here only if CurMode has changed from OldMode
defproc NepmdResetMode()
   universal EPM_utility_array_ID
   parse arg OldMode
   OldMode = strip(OldMode)

   -- Get current mode
   CurMode = NepmdGetMode()

   if CurMode <> OldMode then

      -- Set 'mode.'fid to an empty string to make NepmdGetMode re-determining
      -- the current mode
      getfileid fid
      ResetMode = ''
      do_array 2, EPM_utility_array_ID, 'mode.'fid, ResetMode

      -- Process all mode dependent settings
      call NepmdProcessMode(CurMode)
   endif

   return

; ---------------------------------------------------------------------------
; Creates the array var 'mode.'fid is created to be queried later.
; NepmdProcessMode is called here.
; This proc is called by defload in LOAD.E
defproc NepmdInitMode
   universal EPM_utility_array_ID
   HiliteCheckFlag = arg( 1)

   -- Get the mode from EA 'EPM.MODE'
   NewMode = get_EAT_ASCII_value('EPM.MODE')
   if NewMode = '' then
      -- Get the default mode
      NewMode =  NepmdQueryDefaultMode(.filename)
      parse value NewMode with 'ERROR:'rc
      if rc > '' then
         sayerror "Default mode can't be determined. NepmdQueryDefaultMode returned rc = "rc
         NewMode = ''
      endif
   endif

   -- Save mode in an array var for the statusline and for hili
   -- Sets 'mode.'fid even if NewMode = '' because an array var must be set
   -- to any value before querying it.
   getfileid fid
   do_array 2, EPM_utility_array_ID, 'mode.'fid, NewMode

   -- Process all mode dependent settings
   if NewMode <> '' then
      call NepmdProcessMode( NewMode, HiliteCheckFlag)
   endif  -- if NewMode <> ''

   return NewMode


; ---------------------------------------------------------------------------
; Changes the current mode.
; NepmdProcessMode is called here.
;
; This command uses the NEPMDLIB EA functions to change the EA 'EPM.MODE'
; immediately if NEPMD_RESTORE_MODE_FROM_EA = 1.
;
; With the E functions only the EA area is changed. The EA's would only be saved
; when the file is saved.
;
; Both are used here: The NEPMDLIB functions to keep the EA after quitting and the
; E functions to get the current EA value quickly from .eaarea.
;
; Additionally, the current mode (from 'EPM.MODE' or the default mode) is saved in
; the array var 'mode.'fid. This is called by commands that have mode dependent
; setting: hili, refreshstatusline
;
; arg1 = (NewMode|0|OFF|RESET|-RESET-|DEFAULT)
;         NewMode can be any mode.
; If no arg specified, then a listbox is opened for selecting a mode.
defc mode
   universal EPM_utility_array_ID
   parse arg NewMode
   NewMode = upcase(NewMode)
   NewMode = strip(NewMode)

   if NewMode = '' then
      -- Ask user to set a mode
      NewMode = upcase( NepmdSelectMode())
   endif

   if wordpos( NewMode, '-RESET- RESET 0 OFF DEFAULT' ) > 0 then

      -- Delete the EA 'EPM.MODE' immediately
      rc = NepmdDeleteStringEa( .filename, 'EPM.MODE' )
      if (rc > 0) then
         sayerror 'EA "EPM.MODE" not deleted, rc='rc
      endif

      -- Update the EPM EA area to have get_EAT_ASCII_value show the actual value
      call delete_ea('EPM.MODE')

      -- Get the default mode
      NewMode =  NepmdQueryDefaultMode(.filename)
      parse value NewMode with 'ERROR:'rc
      if rc > '' then
         sayerror "Default mode can't be determined. NepmdQueryDefaultMode returned rc = "rc
         NewMode = ''
      endif

      -- Process all mode specific settings
      call NepmdProcessMode( NewMode )

   elseif NewMode <> '' then

      -- Save mode in an array var for the statusline and for hili
      getfileid fid
      do_array 2, EPM_utility_array_ID, 'mode.'fid, NewMode

      -- Set the EA 'EPM.MODE' immediately
      rc = NepmdWriteStringEa( .filename, 'EPM.MODE', NewMode )
      if (rc > 0) then
         sayerror 'EA "EPM.MODE" not set, rc='rc
      endif

      -- Update the EPM EA area to have get_EAT_ASCII_value show the actual value
      call delete_ea('EPM.MODE')
      'add_ea EPM.MODE' NewMode

      -- Process all mode specific settings
      call NepmdProcessMode( NewMode )

   endif  -- wordpos( NewMode, '-RESET- RESET 0 OFF DEFAULT' ) > 0

   return


; ---------------------------------------------------------------------------
; Processes all mode specific settings
defproc NepmdProcessMode()
   -- load_var is a marker that stores if tabs or margins were already set
   -- by the EA's EPM.TABS or EPM.MARGINS
   universal load_var

   CurMode = arg(1)
   HiliteCheckFlag = arg( 2)

   if CurMode = '' then
      CurMode = NepmdGetMode()
   endif
   -------- put mode dependent settings here: ------

   -- Statusline
   -- refresh the mode tag on statusline
compile if NEPMD_SPECIAL_STATUSLINE
   'refreshstatusline'
compile endif

   -- Highlighting
   if (CurMode = 'OFF') then
     call NepmdActivateHighlight( 'OFF')
   else
     call NepmdActivateHighlight( 'ON', CurMode, HiliteCheckFlag)
   endif

   -- Key set, tabs, margins
   -- Moved from EKEYS.E, REXXKEYS.E, CKEYS.E, PKEYS.E
   TabsSetFromEa    = (load_var // 2)      -- 1 would be on if tabs set from EA EPM.TABS
   MarginsSetFromEa = (load_var bitand 2)  -- 2 would be on if tabs set from EA EPM.MARGINS
   if CurMode = 'OFF' then

   elseif CurMode = 'E' then          ---- E ----
      keys E_keys
compile if E_TABS <> 0
      if not TabsSetFromEa then
         'tabs' E_TABS
      endif
compile endif
compile if E_MARGINS <> 0
      if not MarginsSetFromEa then
         'ma'   E_MARGINS
      endif
compile endif

   elseif CurMode = 'REXX' then       ---- REXX ----
      keys REXX_keys
compile if REXX_TABS <> 0
      if not TabsSetFromEa then
         'tabs' REXX_TABS
      endif
compile endif
compile if REXX_MARGINS <> 0
      if not MarginsSetFromEa then
         'ma'   REXX_MARGINS
      endif
compile endif

   elseif CurMode = 'C' then          ---- C ----
      keys C_keys
compile if C_TABS <> 0
      if not TabsSetFromEa then
         'tabs' C_TABS
      endif
compile endif
compile if C_MARGINS <> 0
      if not MarginsSetFromEa then
         'ma'   C_MARGINS
      endif
compile endif

   elseif CurMode = 'JAVA' then       ---- JAVA ----
      keys C_keys
compile if C_TABS <> 0
      if not TabsSetFromEa then
         'tabs' C_TABS
      endif
compile endif
compile if C_MARGINS <> 0
      if not MarginsSetFromEa then
         'ma'   C_MARGINS
      endif
compile endif

   elseif CurMode = 'PASCAL' then     ---- PASCAL ----
      keys Pas_keys
compile if P_TABS <> 0
      if not TabsSetFromEa then
         'tabs' P_TABS
      endif
compile endif
compile if P_MARGINS <> 0
      if not MarginsSetFromEa then
         'ma'   P_MARGINS
      endif
compile endif

   endif

   return

; ---------------------------------------------------------------------
; Opens a listbox to select a mode.
; Called by defc mode if no arg specified.
defproc NepmdSelectMode()

   -- determine current mode
   CurMode = get_EAT_ASCII_value('EPM.MODE')
   DefMode = NepmdQueryDefaultMode( .filename);

   if CurMode = '' then
      SelectedMode = DefMode
      Text = 'Default mode:' SelectedMode;
   else
      SelectedMode = CurMode;
      Text = 'Selected mode:' SelectedMode;
   endif

   -- check mode list and add default entry
   ModeList = NepmdQueryModeList();
   parse value ModeList with 'ERROR:'rc;
   if (rc > '') then
      sayerror 'error: list of EPM modes could not be determined, rc='rc;
      stop;
   endif
   ModeList = ModeList '-DEFAULT-'


   -- determine default selection
   Selection = wordpos( SelectedMode, ModeList);
   Title = 'Mode Selection:';

   refresh
   select = listbox( Title,
                     ModeList,
                     '/Set/Cancel',                 -- buttons
                     5, 5,                          -- Top, Left,
                     min( words(ModeList),12), 25,  -- Height, Width
                     gethwnd(APP_HANDLE) || atoi(Selection) || atoi(1) || atoi(0) ||
                     Text\0 )
   refresh

   -- check result
   parse value select with \1 select \0
   select = strip( select, 'B', \1 ) -- sometimes the returned value for cancel is \1
   if ((select = DefMode) | (select = '-DEFAULT-')) then
      select = 'OFF'
   end

   --sayerror 'defproc selectmode(): select = |'select'|'

   return select

