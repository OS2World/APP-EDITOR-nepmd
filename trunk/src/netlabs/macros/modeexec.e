/****************************** Module Header *******************************
*
* Module Name: modeexec.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: modeexec.e,v 1.9 2005-11-24 01:23:28 aschn Exp $
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
; Provides Set* commands for mode-specific configuration.
;
; Settings are handled with different priorities:
;
; 1. Default settings (configurable via Options menu, lowest priority)
;
; 2. Mode settings (configurable via MODECNF.E and/or PROFILE.ERX, using
;    'ModeExecute <mode> Set*' commands )
;
; 3. File settings (configurable via File properties menu, highest priority)
;
; The settings of 2. and 3. are saved in array vars. It is determined, if a
; setting has to be executed at defload or defselect using lists. After the
; mode settings are applied (either at defload or at the first defselect),
; they can be overwritten with file specific settings.
;
; Any change of mode will reset the file settings to the mode defaults. The
; file-specific array vars will be deleted in order to have the mode
; settings re-applied after that.

; ---------------------------------------------------------------------------
; Remaining configuration constants:
/*
; Syntax expansion:
   TERMINATE_COMMENTS = 0
   WANT_END_COMMENTED = 1

   REXX_SYNTAX_CASE = 'lower' ('Mixed' | 'UPPER')
   REXX_SYNTAX_FORCE_CASE = 1
   REXX_SYNTAX_NO_ELSE = 1

   I_like_my_cases_under_my_switch = 1
   I_like_a_semicolon_supplied_after_default = 0
   ADD_BREAK_AFTER_DEFAULT = 1
   WANT_BRACE_BELOW_STATEMENT = 0
   WANT_BRACE_BELOW_STATEMENT_INDENTED = 0
   USE_ANSI_C_NOTATION = 1  -- 1 means use shorter ANSI C notation on MAIN.
   JAVA_SYNTAX_ASSIST = 0
   CPP_EXTENSIONS = 'CPP HPP CXX HXX SQX JAV JAVA'

; Others:
   Are there any?
*/
; ---------------------------------------------------------------------------

; Syntax: ModeExecute <mode> <set_cmd> <args>
;
;         <set_cmd>         <args>
;
;         SetStreamMode     0 | 1
;         SetInsertMode     0 | 1
;         SetHighlight      0 | 1
;         SetTabs           <number> | <list of numbers>
;         SetTabkey         0 | 1
;         SetMatchTab       0 | 1
;         SetMargins        <left> <right> <par>
;         SetExpand         0 | 1
;                           (means syntax expansion)
;         SetIndent         <number>
;                           (default = const, if defined, e.g. REXX_INDENT
;                           else first number of tabs)
;         SetTextColor      number | const
;                           (see COLORS.E or defproc GetColorFromName)
;         SetMarkColor      number | const
;                           (see COLORS.E or defproc GetColorFromName)
;                           (Hint: place cursor on COLORS.E and press Alt+1 to
;                                  load the file)
;         SetTextFont       <font_size>.<font_name>[.<font_sel>]
;                           (<font_size> and <font_name> can be exchanged.
;                           Any EPM font specification syntax will be accepted
;                           as well. The args are case-sensitive.)
;         SetToolbar        <toolbar_name> | STANDARD
;                           (case-sensitive, must be defined in EPM.INI)
;         SetDynaspell      0 | 1
;                           (means spell-checking while typing)
;         SetEditOptions    see description of Edit command
;         SetSaveOptions    see description of Save command
;         SetSearchOptions  see description of Locate and Replace commands
;                           (plus undocumented TB options)
;         SetKeys           <keyset_name>
;
; Additional option for <args> : DEFAULT
; That means, that the setting is reset to EPM's current standard values.
/*
; maybe planned sometime
- SetBackupFiles
- SetBackupPath
- autosave?
- SetBracketMatch
- SetHelpNdxFiles
- SetMenu           -- switch Project menu
- SetMenuAttribute  -- toggle MIA_DISABLED
- SetMenuText       -- show current section/function
- SetToolbarItem    -- change bitmap as 'modified' notification
- SetRunAction
- SetLockOnModify
*/

; ---------------------------------------------------------------------------
; This should be executed by definit. Doing this here comes too late. This
; would cause 'ModeExecute: "SetMargins 1 1599 1" is an invalid setting.'...
defc InitFileSettings
   universal SelectSettingsList
   universal LoadSettingsList
;define
   SelectSettingsList = 'SetToolbar SetExpand SetMatchtab SetTabkey' ||
                        ' SetEditOptions SetSaveOptions SetSearchOptions' ||
                        ' SetStreamMode SetInsertMode' ||
                        ' SetTextFont SetTextColor SetMarkColor SetIndent'
   LoadSettingsList   = 'SetHighlight SetMargins SetTabs' ||
                        ' SetKeys SetDynaSpell'

; ---------------------------------------------------------------------------
defc ResetFileSettings
   universal SelectSettingsList
   universal LoadSettingsList
   -- Set all <setting>.<fid> array vars to empty
   getfileid fid
   SettingsList = LoadSettingsList SelectSettingsList
   do w = 1 to words(SettingsList)
      wrd = word( SettingsList, w)
      parse value lowcase(wrd) with 'set' rest  -- strip leading 'set'
      call SetAVar( rest'.'fid, '')
   enddo
   call SetAVar('modesettingsapplied.'fid, 0)
   -- Process settings
   'ProcessLoadSettings'
   'ProcessSelectSettings'
   return

; ---------------------------------------------------------------------------
; Processes all mode specific defload settings.
; Executed by defload and defc ResetFileSettings.
; (defc Mode and ResetMode call ResetFileSettings when the mode has changed.)
defc ProcessLoadSettings
   universal nepmd_hini
   universal loadstate
   universal SelectSettingsList
   universal LoadSettingsList

   if not .visible then
      return
   endif

   parse arg Mode calling_fid
   Mode = strip(Mode)
   calling_fid = strip(calling_fid)

   if Mode = '' then
      Mode = NepmdGetMode()  -- Doesn't work properly during file loading, because current file
                             -- has probably changed? Therefore Mode is submitted as arg.
   endif
   if loadstate then
      HiliteCheckFlag = NepmdGetHiliteCheckFlag(Mode)
   else
      HiliteCheckFlag = ''
   endif
   KeyPath = '\NEPMD\User\KeywordHighlighting'
   default_on = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   getfileid fid
   if isnum(calling_fid) then
      if calling_fid <> fid then
         call NepmdPmPrintf( 'No load settings processed. File not on top anymore:' ||
                             ' 'calling_fid.filename', current: 'fid.filename)
         return
      endif
   endif
   -- Execute mode-specific settings
   -- Using standard definition for HookExecute. Calling another defc here is
   -- so slow, that file to be processed is not on top anymore.
   prefix = 'hook.'
   HookName = 'load_'lowcase(Mode)
   imax = GetAVar(prefix''HookName'.0')
   if imax = '' then
      imax = 0
   endif
   do i = 1 to imax
      Cmd = GetAVar(prefix''HookName'.'i)
      parse value Cmd with wrd SettingsValue
      Cmd  -- execute command
   enddo

   if loadstate then
      -- Activate keyword highlighting, if not already done by load_<mode> hook
      next = GetAVar('highlight.'fid)  -- get file setting
      if next = '' | next = 'DEFAULT' then
         -- Bug in NepmdActivateHighlight:
         -- Execution suppresses defselect after defload, if EPM is already
         -- open and a new file is added to the ring.
         call NepmdActivateHighlight( default_on, Mode, HiliteCheckFlag)
      endif
   else
      List = LoadSettingsList
      do w = 1 to words(List)  -- Only LoadSettings need to be reset for default mode
         wrd = word( List, w)
         parse value lowcase(wrd) with 'set' rest
         next = GetAVar(rest'.'fid)  -- get file setting
         if next = '' | next = 'DEFAULT' then
            wrd 'DEFAULT'
         endif
      enddo
   endif

   -- Maybe the load and load_once hook should here be executed as well?

   -- Refresh the mode field on statusline
   if not loadstate then
      -- don't process this on defload, because it's already executed there
      'RefreshInfoLine MODE'
   endif
   return

; ---------------------------------------------------------------------------
; Executed by defc ProcessSelect, using the select hook
; and by defc ResetFileSettings.
; (defc Mode and ResetMode call ResetFileSettings when the mode has changed.)
defc ProcessSelectSettings
   universal SelectSettingsList
   universal LoadSettingsList
   if not .visible then
      return
   endif

   -- Get file-specific setting names
   -- Check if a setting is set as array var (maybe as a file setting)
   getfileid fid
   UsedFileSettings = ''
   -- Check if mode settings already overtaken from the hook to current file's array var
   ModeSettingsApplied = GetAVar('modesettingsapplied.'fid)
   if ModeSettingsApplied then
      do w = 1 to words(SelectSettingsList)
         wrd = word( SelectSettingsList, w)
         parse value lowcase(wrd) with 'set' rest  -- strip leading 'set'
         SettingsValue = GetAVar( rest'.'fid)
         if SettingsValue <> '' & SettingsValue <> 'DEFAULT' then
            UsedFileSettings = UsedFileSettings wrd
         endif
      enddo
      UsedFileSettings = strip(UsedFileSettings)
   endif
;   call NepmdPmPrintf('UsedFileSettings = 'UsedFileSettings)

   -- Execute mode-specific settings
   -- Standard definition for HookExecute, extended with a check, if
   -- config is set by the file instead of the mode.
   Mode = NepmdGetMode()
   prefix = 'hook.'
   HookName = 'select_'lowcase(Mode)
   imax = GetAVar(prefix''HookName'.0')
   if imax = '' then
      imax = 0
   endif
   UsedModeSettings = ''
   do i = 1 to imax
      Cmd = GetAVar(prefix''HookName'.'i)
      parse value Cmd with wrd SettingsValue
      if not wordpos( upcase(wrd), upcase(UsedFileSettings)) then
;         call NepmdPmPrintf('MODE: 'Cmd' -- '.filename)
         Cmd  -- execute command
         UsedModeSettings = UsedModeSettings wrd
      endif
   enddo
   UsedModeSettings = strip(UsedModeSettings)
   if not ModeSettingsApplied then
      call SetAVar( 'modesettingsapplied.'fid, 1)
   endif

   -- Execute file-specific settings
   do w = 1 to words(UsedFileSettings)
      wrd = word( UsedFileSettings, w)
      parse value lowcase(wrd) with 'set' rest  -- strip leading 'set'
                                                -- To be changed, if commands will miss the 'Set' some time.
                                                -- Currently there are some commands, that require the 'Set' and
                                                -- the standard (without 'Set') versions.
      SettingsValue = GetAVar( rest'.'fid)
      Cmd = wrd SettingsValue
;      call NepmdPmPrintf('FILE: 'Cmd' -- '.filename)
      Cmd  -- execute command
   enddo

   -- Restore settings to defaults for other settings used by previous file.
   -- Tracking every non-default setting in the array var 'lastusedsettings'
   -- increases performance, because only those settings are changed.
   CurSettings = strip(UsedModeSettings' 'UsedFileSettings)
   LastSettings = GetAVar('lastusedsettings')
;   call NepmdPmPrintf('lastsettings = 'LastSettings)
   do w = 1 to words(LastSettings)
      wrd = word( LastSettings, w)
      if wordpos( upcase(wrd), upcase(CurSettings)) = 0 then
         Cmd = wrd 'DEFAULT'  -- execute setting with 'DEFAULT'
;         call NepmdPmPrintf('RESET: 'Cmd' -- '.filename)
         Cmd  -- execute command
      endif
   enddo
   call SetAVar( 'lastusedsettings', CurSettings)

   return

; ---------------------------------------------------------------------------
; Add cmd to the select hook. This hook will be executed by HookExecute, by
; defc ProcessSelect at AfterLoad and/or defselect.
; (The defc ProcessLoadSettings is executed directly, without the HookExecute
; command. This is required to process these settings for the correct file.)
definit
   'HookAdd select ProcessSelectSettings'

; ---------------------------------------------------------------------------
; Determine on which stack the cmd should be put on or delete the stacks.
; /*To change settings of already loaded files, too, use ModeExecuteRefresh.*/
defc ModeExecute, ModeExec
   universal SelectSettingsList
   universal LoadSettingsList
   universal loadstate
   parse value arg(1) with Mode Cmd Args
   Mode = strip(Mode)
   Cmd  = strip(Cmd)
   Args = strip(Args)
   Mode = upcase(Mode)
   if Mode = 'CLEAR' then
      List = GetAVar('usedsettings_modes', Mode)
      do w = 1 to words(List)
         wrd = word( List, w)
         'HookDelAll load_'lowcase(wrd)
         'HookDelAll select_'lowcase(wrd)
      enddo
      return
   endif
   if wordpos( upcase(Cmd), upcase(SelectSettingsList)) then
      -- These settings don't stick with the current file.
      -- Execute them during afterload and at/or defselect.
      'HookChange select_'lowcase(Mode) Cmd Args
      -- Save a list of used defselect settings for every mode
      call AddAVar('usedsettings_'lowcase(Mode), Cmd)
   elseif wordpos( upcase(Cmd), upcase(LoadSettingsList)) then
      -- These settings stick with the current file and don't need additional
      -- handling at defselect.
      -- Execute them at defload only.
      'HookChange load_'lowcase(Mode) Cmd Args
   else
      sayerror 'ModeExecute: "'Cmd Args'" is an invalid setting.'
      return
   endif
   if not loadstate then
      'RingRefreshSetting' arg(1)
   endif
   -- Save a list of used modes to be able to delete all settings
   if not wordpos( Mode, GetAVar('usedsettings_modes', Mode)) then
      call AddAVar('usedsettings_modes', Mode)
   endif

; ---------------------------------------------------------------------------
; Refresh specified setting for those files in the ring, whose setting were
; not changed with a Set* command of MODEEXEC.E. Should be executed by
;    -  any command, that changes default defload settings
;       currently, these are: SetHighlight, SetMargins, SetTabs
;       not effected: SetKeys SetDynaSpell (only saved as field var)
;    -  a modeexecuterefresh command, if executed by hand, after file is loaded.
; The command must have the name of the array var plus 'Set' prepended.
defc RingRefreshSetting
   universal StatusFieldFlags
   universal TitleFieldFlags
   parse value arg(1) with Mode Cmd Args
   Mode = upcase(Mode)
   parse value lowcase(Cmd) with 'set' SettingName  -- Strip leading 'set'
   getfileid startfid
   display -3
   fid = startfid
   do i = 1 to filesinring()  -- omit hidden files and prevent looping forever
      Execute = 0
      if Mode = 'DEFAULT' then
         next = GetAVar( SettingName'.'fid)  -- query file setting
         if next = 'DEFAULT' | next = '' then  -- unset if setting was not changed by any modeexecute
            Cmd 'REFRESHDEFAULT' Args  -- execute arg(1) with 'REFRESHDEFAULT' parameter prepended
         endif
      elseif Mode = NepmdGetMode() then
         'ResetFileSettings'  -- all settings (reset of a single setting is not implemented)
         --Cmd 'REFRESH' Args  -- execute arg(1) with 'REFRESH' parameter prepended
      endif
      nextfile
      getfileid fid
      if fid = startfid then  -- maybe startfid is not valid anymore at this time
         leave
      endif
   enddo
   'postme activatefile' startfid  -- postme required for some Cmds, e.g. SetHighlight
   'postme RefreshInfoLine' StatusFieldFlags TitleFieldFlags  --refresh all
   -- Little bug: InsertMode is not refreshed here.
   'postme display' 3
   return

; ---------------------------------------------------------------------------
/*
; Use this command instead of ModeExecute after files are loaded.
defc ModeExecuteRefresh, ModeExecRefresh
   'ModeExecute' arg(1)
   'RingRefreshSetting' arg(1)
*/

; ---------------------------------------------------------------------------
; Refresh specified setting for those files in the ring, whose setting were
; not changed with a Set* command of MODEEXEC.E.
; The command must be
defc RingDumpSettings
   universal SelectSettingsList
   universal LoadSettingsList
   SettingsList = LoadSettingsList SelectSettingsList
   SettingsList = SettingsList' setmodesettingsapplied'  -- append system var
   TmpFileName = '.FILE_SETTINGS'
   getfileid startfid
   display -3
   if pfile_exists(TmpFileName) then
      'xcom e /n' TmpFileName   -- activate tmp file
   else
      'xcom e /c' TmpFileName   -- create tmp file
      deleteline                -- delete first line (EPM automatically creates line 1)
   endif
   getfileid tmpfid
   savedlast = .last
   .autosave = 0
   parse value getdatetime() with Hour24 Minutes Seconds . Day MonthNum Year0 Year1 .
   Date = rightstr(Year0 + 256*Year1, 4, 0)'-'rightstr(monthnum, 2, 0)'-'rightstr(Day, 2, 0)
   Time = rightstr(hour24, 2)':'rightstr(Minutes,2,'0')':'rightstr(Seconds,2,'0')
   insertline copies('-', 78), .last + 1
   insertline 'File settings - created on 'Date' 'Time, .last + 1
   varname =  '   Defload settings             ='
   line = varname
   do w = 1 to words(LoadSettingsList)
      wrd = word( LoadSettingsList, w)
      if length(line) + length(wrd) > 77 then
         insertline line, .last + 1
         line = copies( ' ', length(varname)) wrd
      else
         line = line wrd
      endif
   enddo
   varname =  '   Defselect settings           ='
   line = varname
   do w = 1 to words(SelectSettingsList)
      wrd = word( SelectSettingsList, w)
      if length(line) + 1 + length(wrd) > 78 then
         insertline line, .last + 1
         line = copies( ' ', length(varname)) wrd
      else
         line = line wrd
      endif
   enddo
   insertline '   Defselect usedsettings_modes = 'GetAVar( 'usedsettings_modes'), .last + 1
   insertline '   Defselect lastusedsettings   = 'GetAVar( 'lastusedsettings'), .last + 1
   activatefile startfid
   fid = startfid
   do i = 1 to filesinring()  -- omit hidden files
      --if fid = tmpfid then    -- omit tmp file
      --   iterate  -- iterate doesn't work - why?
      --endif
      insertline .filename, tmpfid.last + 1, tmpfid
      -- Add mode
      insertline '   'leftstr( 'mode', max( length('mode'), 20))' = 'NepmdGetMode(), tmpfid.last + 1, tmpfid
      do w = 1 to words(SettingsList)
         wrd = word( SettingsList, w)
         next = lowcase(wrd)
         parse value next with 'set' SettingName  -- strip leading 'set'
         SettingValue = GetAVar( SettingName'.'fid)  -- query file setting
         insertline '   'leftstr( SettingName, max( length(SettingName), 20))' = 'SettingValue, tmpfid.last + 1, tmpfid
      enddo
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo
   insertline '', tmpfid.last + 1, tmpfid
   tmpfid.modify = 0
   activatefile tmpfid
   .line = savedlast + 1
   display 3
   return

; ---------------------------------------------------------------------------
; Execute this only at defload or -- when file has default setting -- after
; changing the default value. In that case use the parameter
; REFRESHDEFAULT <new_default_value>.
defc SetHighlight
   universal nepmd_hini
   universal loadstate
   SettingName  = 'highlight'
   KeyPath = '\NEPMD\User\KeywordHighlighting' -- for default value if arg1 = 'DEFAULT' or empty

   getfileid fid
   SettingValue = GetAVar( SettingName'.'fid)
   arg1 = upcase(arg(1))
   wp = wordpos( 'REFRESHDEFAULT', arg1)
   RefreshDefault = (wp > 0)
   if RefreshDefault then
      arg1 = delword( arg1, wp, 1)  -- remove 'REFRESHDEFAULT' from arg1
   endif
   CheckFlag = ''
   wp = wordpos( 'N', arg1)
   if wp > 0 then
      CheckFlag = 'N'
      arg1 = delword( arg1, wp, 1)  -- remove 'REFRESHDEFAULT' from arg1
   endif

   if arg1 = 'DEFAULT' then
      on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   elseif arg1 = 0 then
      on = 0
   else
      on = 1
   endif

   -- Process the following at RefreshDefault only if setting has default value
   if RefreshDefault & not (SettingValue = '' | SettingValue = 'DEFAULT') then
      return
   endif

   -- Process setting
   Mode = NepmdGetMode()
   if (CheckFlag = '') & loadstate then
      CheckFlag = NepmdGetHiliteCheckFlag(Mode)
   endif
   call NepmdActivateHighlight( on, Mode, CheckFlag)

   -- Save the value in an array var, to determine 'DEFAULT' state later
   -- Process the following not at RefreshDefault
   if SettingValue <> arg1 & not RefreshDefault then
      call SetAVar( SettingName'.'fid, arg1)
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload or -- when file has default setting -- after
; changing the default value. In that case use the parameter
; REFRESHDEFAULT <new_default_value>.
defc SetMargins  -- defc margins exist
   -- loadstate stores if tabs or margins were already set by the EA's
   -- EPM.TABS or EPM.MARGINS. Every loaded file reuses it, therefore it can
   -- only be used at defload.
   universal loadstate
   -- 'modesettingsapplied.'fid is reset to 0 by 'ResetFileSettings'
   getfileid fid
   ModeSettingsApplied = GetAVar('modesettingsapplied.'fid)
   SettingName  = 'margins'
   InfolineName = 'MARGINS'

   getfileid fid
   SettingValue = GetAVar( SettingName'.'fid)
   arg1 = upcase(arg(1))
   wp = wordpos( 'REFRESHDEFAULT', arg1)
   RefreshDefault = (wp > 0)
   if RefreshDefault then
      arg1 = delword( arg1, wp, 1)  -- remove 'REFRESHDEFAULT' from arg1
   endif

   SetFromEa    = 0
   -- Search EPM.TABS in .eaarea
   Found = find_ea( 'EPM.MARGINS', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen)
   if Found & ea_valuelen <> 0 then
      SetFromEa = 1
   endif

   -- Process the following at RefreshDefault only if setting has default value
   if RefreshDefault & not (SettingValue = '' | SettingValue = 'DEFAULT') then
      return
   endif

   if arg1 = 'DEFAULT' | arg1 = 0 then
      if loadstate & SetFromEa then
         arg1 = .margins
      else
         'margins' 0  -- reset, maybe delete EPM.MARGINS
         arg1 = 'DEFAULT'
      endif
   elseif SetFromEa = 0 then  -- Overwrite only if not already set from EA
      if loadstate | RefreshDefault | (ModeSettingsApplied <> 1) then
         .margins = arg1
      else  -- User has executed this command
         'margins' arg1  -- set EPM.MARGINS
      endif
   else
      --call NepmdPmPrintf( 'Margins not set: '.filename)
   endif

   -- Save the value in an array var, to determine 'DEFAULT' state later
   -- Process the following not at RefreshDefault
   if SettingValue <> arg1 & not RefreshDefault then
      call SetAVar( SettingName'.'fid, arg1)
   endif
   -- Refresh titletext or statusline
   if (not loadstate) & (not RefreshDefault) then  -- not at afterload and not for RefreshDefault
      'refreshinfoline' InfolineName
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload or -- when file has default setting -- after
; changing the default value. In that case use the parameter
; REFRESHDEFAULT <new_default_value>.
defc SetTabs  -- defc tabs exist
   -- loadstate stores if tabs or margins were already set by the EA's
   -- EPM.TABS or EPM.MARGINS. Every loaded file reuses it, therefore it can
   -- only be used at defload.
   universal loadstate
   -- 'modesettingsapplied.'fid is reset to 0 by 'ResetFileSettings'
   getfileid fid
   ModeSettingsApplied = GetAVar('modesettingsapplied.'fid)
   SettingName  = 'tabs'
   InfolineName = 'TABS'

   getfileid fid
   SettingValue = GetAVar( SettingName'.'fid)
   arg1 = upcase(arg(1))
   wp = wordpos( 'REFRESHDEFAULT', arg1)
   RefreshDefault = (wp > 0)
   if RefreshDefault then
      arg1 = delword( arg1, wp, 1)  -- remove 'REFRESHDEFAULT' from arg1
   endif

   SetFromEa    = 0
   -- Search EPM.TABS in .eaarea
   Found = find_ea( 'EPM.TABS', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen)
   if Found & ea_valuelen <> 0 then
      SetFromEa = 1
   endif

   -- Process the following at RefreshDefault only if setting has default value
   if RefreshDefault & not (SettingValue = '' | SettingValue = 'DEFAULT') then
      return
   endif

   if arg1 = 'DEFAULT' | arg1 = 0 then
      if loadstate & SetFromEa then
         arg1 = .tabs
      else
         'tabs' 0  -- reset, maybe delete EPM.TABS
         arg1 = 'DEFAULT'
      endif
   elseif not SetFromEa then  -- Overwrite only if not already set from EA
      if loadstate | RefreshDefault | (ModeSettingsApplied <> 1) then
         .tabs = arg1
      else  -- User has executed this command
         'tabs' arg1  -- set EPM.TABS
      endif
   else
      --call NepmdPmPrintf( 'Tabs not set: '.filename)
   endif

   -- Save the value in an array var, to determine 'DEFAULT' state later
   -- Process the following not at RefreshDefault
   if SettingValue <> arg1 & not RefreshDefault then
      call SetAVar( SettingName'.'fid, arg1)
   endif
   -- Refresh titletext or statusline
   if (not loadstate) & (not RefreshDefault) then  -- not at afterload and not for RefreshDefault
      'refreshinfoline' InfolineName
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
; Therefore we don't need to handle dynaspell here.
; Separately compiled packages can define a 'Set<mode>Keys' command, that
; will be executed if it exists.
defc SetKeys
   universal loadstate
   arg1 = upcase(arg(1))
   if upcase(arg(1)) = 'DEFAULT' then
      .keyset = 'EDIT_KEYS'
      arg1 = 'DEFAULT'
   else
      .keyset = arg1
      -- if rc = -321 then  -- CANNOT_FIND_KEYSET
   endif
   -- Bug in EPM's keyset handling:
   -- .keyset = '<new_keyset>' works only, if <new_keyset> was defined in
   -- the same .EX file, from where the keyset should be changed.
   -- Therefore (as a workaround) switch temporarily to the externally
   -- defined keyset in order to make it known for 'SetKeys':
   --
   -- definit  -- required for a separately compiled package
   --    saved_keys = .keyset
   --    .keyset = '<new_keyset>'
   --    .keyset = saved_keys
   --
   -- Note: An .EX file, that defines a keyset, can't be unlinked, when this
   -- keyset is in use.

   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   call SetAVar( 'keys.'fid, arg1)
   if not loadstate then
      'refreshinfoline KEYS'
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
defc SetDynaSpell  -- defc dynaspell exists and is used here
   universal loadstate
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      on = 0
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   old = (.keyset = 'SPELL_KEYS')
   if on <> old then
      'dynaspell'  -- toggle
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   call SetAVar( 'dynaspell.'fid, arg(1))
   if not loadstate then
      'refreshinfoline KEYS'
   endif

; ---------------------------------------------------------------------------
defc SetToolbar
   universal toolbar_loaded
   universal current_toolbar
   --universal appname
   --universal app_hini
   arg1 = upcase(arg(1))
   if current_toolbar = '' then
      current_toolbar = toolbar_loaded
   endif
   if upcase(current_toolbar) <> arg1 then
      if arg1 = '' | arg1 = 'DEFAULT' then
         --def_toolbar = queryprofile( app_hini, appname, INI_DEF_TOOLBAR)
         def_toolbar = GetDefaultToolbar()
         if def_toolbar <> '' then
            'postme LoadToolbar 'def_toolbar
            current_toolbar = def_toolbar
         endif
      elseif arg1 = \1 | wordpos( arg1, 'BUILTIN STANDARD') then
         'postme LoadStandardToolbar'  -- built-in toolbar
         current_toolbar = 'STANDARD'
      else
         'postme LoadToolbar 'arg(1)
         current_toolbar = arg(1)
      endif
   endif
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'toolbar.'fid) <> arg(1) then
      call SetAVar( 'toolbar.'fid, arg(1))
      if not wordpos( upcase('SetToolbar'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetToolbar')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetExpand  -- defc expand exists
   universal loadstate
   universal expand_on
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\SyntaxExpansion'
      on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   -- Set universal var
   expand_on = on
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'expand.'fid) <> arg(1) then
      call SetAVar( 'expand.'fid, arg(1))
      if not wordpos( upcase('SetExpand'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetExpand')
      endif
   endif
   if not loadstate then
      'refreshinfoline EXPAND'
   endif

; ---------------------------------------------------------------------------
defc SetIndent
   universal indent
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      new = word( .tabs, 1)
   else
      new = arg(1)
   endif
   -- Set universal var
   indent = new
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'indent.'fid) <> arg(1) then
      call SetAVar( 'indent.'fid, arg(1))
      if not wordpos( upcase('SetIndent'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetIndent')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetMatchTab  -- defc matchtab exists
   universal loadstate
   universal matchtab_on
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\Keys\Tab\MatchTab'
      on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   -- Set universal var
   matchtab_on = on
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'matchtab.'fid) <> arg(1) then
      call SetAVar( 'matchtab.'fid, arg(1))
      if not wordpos( upcase('SetMatchTab'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetMatchTab')
      endif
   endif
   if not loadstate then
      'refreshinfoline MATCHTAB'
   endif

; ---------------------------------------------------------------------------
;    doesn't work  (because just executed at defload, not at edit)
; Must be executed at defmain, before executing doscommand.
; Problem: Mode is not determined at this time. That will be done at
; defload, to assure that a fileid exists. It's required for the
; array var, used to save the mode of the current file.
defc SetEditOptions
   universal default_edit_options
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\Edit\DefaultOptions'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = arg(1)
   endif
   -- Set universal var
   default_edit_options = new
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'editoptions.'fid) <> arg(1) then
      call SetAVar( 'editoptions.'fid, arg(1))
      if not wordpos( upcase('SetEditOptions'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetEditOptions')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetSaveOptions
   universal default_save_options
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\Save\DefaultOptions'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = arg(1)
   endif
   -- Set universal var
   default_save_options = new
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'saveoptions.'fid) <> arg(1) then
      call SetAVar( 'saveoptions.'fid, arg(1))
      if not wordpos( upcase('SetSaveOptions'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetSaveOptions')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetSearchOptions
   universal default_search_options
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\Search\DefaultOptions'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = arg(1)
   endif
   -- Set universal var
   default_search_options = new
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'searchoptions.'fid) <> arg(1) then
      call SetAVar( 'searchoptions.'fid, arg(1))
      if not wordpos( upcase('SetSearchOptions'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetSearchOptions')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetTabKey  -- defc tabkey exists
   universal loadstate
   universal tab_key
   universal default_tab_key
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      on = default_tab_key
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   -- Set universal var
   tab_key = on
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'tabkey.'fid) <> arg(1) then
      call SetAVar( 'tabkey.'fid, arg(1))
      if not wordpos( upcase('SetTabKey'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetTabKey')
      endif
   endif
   if not loadstate then
      'refreshinfoline TABKEY'
   endif

; ---------------------------------------------------------------------------
defc SetStreamMode
   universal loadstate
   universal stream_mode
   universal default_stream_mode
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      on = default_stream_mode
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   -- Set universal var and process setting
   stream_mode = on
   'togglecontrol 24' stream_mode
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'streammode.'fid) <> arg(1) then
      call SetAVar( 'streammode.'fid, arg(1))
      if not wordpos( upcase('SetStreamMode'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetStreamMode')
      endif
   endif
   if not loadstate then
      'refreshinfoline STREAMMODE'
   endif

; ---------------------------------------------------------------------------
defc SetInsertMode
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      on = 1
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   --sayerror 'arg1 = 'arg1', new = 'new', old = 'old', .filename = '.filename
   if on <> insertstate() then
      inserttoggle
      --'postme inserttoggle'
   endif
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'insertmode.'fid) <> arg(1) then
      call SetAVar( 'insertmode.'fid, arg(1))
      if not wordpos( upcase('SetInsertMode'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetInsertMode')
      endif
   endif
   -- Update of infoline field is handled internally

; ---------------------------------------------------------------------------
; Syntax:  <size>.<name>[.<attrib1>[ <attrib2>]]  or  <name>.<size>[.<attrib[ <attrib2>]]
;          Any following specifications, separated by a period are ignored.
defc SetTextFont
   universal appname
   universal app_hini
   universal lastfont
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      new = queryprofile( app_hini, appname, 'FONT')
      if new = '' then
         new = '12.System VIO'
      endif
   else
      new = arg(1)
   endif
   parse value new with name'.'size'.'attriblist'.'
   next = upcase(size)
   next = translate( next, '', 'XDHWB', '0')
   if not isnum(next) then
      --sayerror 'size = "'size'" is num, arg(1) = 'arg(1)
      -- toggle name and size
      parse value new with size'.'name'.'
   endif
   --sayerror 'name = "'name'", size = "'size'", next = "'next'", arg(1) = 'arg(1)
   parse value upcase(size) with h'X'w
   if h <> '' & w <> '' then
      size = 'HH'h'WW'w
   endif
   attriblist = upcase(attriblist)
   attriblist = translate( attriblist, ' ', '+')  -- allow '+' as separator
   attrib = 0
   do a = 1 to words(attriblist)
      next = word( attriblist, a)
      if isnum(next) then
         attrib = attrib + next
      else
         if next = 'NORMAL' then
            -- attrib = attrib + 0
         elseif wordpos( next, 'ITALIC OBLIQUE SLANTED') then
            attrib = attrib + 1
         elseif next = 'UNDERSCORE' then
            attrib = attrib + 2
         elseif next = 'OUTLINE' then
            attrib = attrib + 8
         elseif next = 'STRIKEOUT' then
            attrib = attrib + 16
         elseif next = 'BOLD' then
            attrib = attrib + 32
         endif
      endif
   enddo
   if new <> lastfont then
      new = name'.'size'.'attrib'.0.0'
   --sayerror 'newfont = 'new
   --'processfontrequest' new
      'postme processfontrequest' new
      lastfont = new  -- save it in a universal var, because .font holds only an id
                      -- It would be much better to avoid the processfontrequest
                      -- and execute simply: .font = <font_id>. Therefore the
                      -- font_id would have been saved, after it was registered:
                      -- .font = registerfont(fontname, fontsize, fontsel)
   endif
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'textfont.'fid) <> arg(1) then
      call SetAVar( 'textfont.'fid, arg(1))
      if not wordpos( upcase('SetTextFont'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetTextFont')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetTextColor
   universal appname
   universal app_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      colors = queryprofile( app_hini, appname, 'STUFF')
      if colors = '' then
         new = 120
      else
         new = subword( colors, 1, 1)
      endif
      color = arg(1)
   else
      new = GetColorFromName(arg(1))
      color = new
   endif
   if new <> .textcolor then  -- the color is set but needs activation
      .textcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   if GetAVar( 'textcolor.'fid) <> color then
      call SetAVar( 'textcolor.'fid, color)
      if not wordpos( upcase('SetTextColor'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetTextColor')
      endif
   endif

; ---------------------------------------------------------------------------
defc SetMarkColor
   universal appname
   universal app_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      colors = queryprofile( app_hini, appname, 'STUFF')
      if colors = '' then
         new = 113
      else
         new = subword( colors, 2, 1)
      endif
   else
      new = GetColorFromName(arg(1))
   endif
   if new <> .markcolor then  -- the color is set but needs activation
      .markcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   if GetAVar( 'markcolor.'fid) <> new then
      call SetAVar( 'markcolor.'fid, new)
      if not wordpos( upcase('SetMarkColor'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetMarkColor')
      endif
   endif

; ---------------------------------------------------------------------------
defproc GetColorFromName(args)
   List = '' ||
      '/BLACK'          || '/0'   ||
      '/BLUE'           || '/1'   ||
      '/GREEN'          || '/2'   ||
      '/CYAN'           || '/3'   ||
      '/RED'            || '/4'   ||
      '/MAGENTA'        || '/5'   ||
      '/BROWN'          || '/6'   ||
      '/LIGHT_GREY'     || '/7'   ||
      '/DARK_GREY'      || '/8'   ||
      '/LIGHT_BLUE'     || '/9'   ||
      '/LIGHT_GREEN'    || '/10'  ||
      '/LIGHT_CYAN'     || '/11'  ||
      '/LIGHT_RED'      || '/12'  ||
      '/LIGHT_MAGENTA'  || '/13'  ||
      '/YELLOW'         || '/14'  ||
      '/WHITE'          || '/15'  ||
      '/BLACKB'         || '/0'   ||
      '/BLUEB'          || '/16'  ||
      '/GREENB'         || '/32'  ||
      '/CYANB'          || '/48'  ||
      '/REDB'           || '/64'  ||
      '/MAGENTAB'       || '/80'  ||
      '/BROWNB'         || '/96'  ||
      '/GREYB'          || '/112' ||
      '/LIGHT_GREYB'    || '/112' ||
      '/DARK_GREYB'     || '/128' ||
      '/LIGHT_BLUEB'    || '/144' ||
      '/LIGHT_GREENB'   || '/160' ||
      '/LIGHT_CYANB'    || '/176' ||
      '/LIGHT_REDB'     || '/192' ||
      '/LIGHT_MAGENTAB' || '/208' ||
      '/YELLOWB'        || '/224' ||
      '/WHITEB'         || '/240'

   if isnum(args) then
      color = args
   else
      Color = 0
      names = upcase(args)
      do while names <> ''
         -- Parse every arg at '+' boundaries
         parse value names with name '+' names
         -- Add underscore after 'LIGHT' or 'DARK', if missing
         parse value name with 'LIGHT'col
         if col <> '' & leftstr( col, 1) <> '_' then
            name = 'LIGHT_'col
         else
            parse value name with 'DARK'col
            if col <> '' & leftstr( col, 1) <> '_' then
               name = 'DARK_'col
            endif
         endif
         -- Parse list
         rest = List
         do while rest <> ''
            parse value rest with '/'next1'/'next2'/' -1 rest
            if next2 = '' then  -- required: the last rest is '/'
               leave
            endif
            -- Compare: name or number
            if name = next1 | name = next2 then
               Color = Color + next2  -- add
               leave
            endif
         enddo
      enddo
   endif

   return color


