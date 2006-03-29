/****************************** Module Header *******************************
*
* Module Name: modeexec.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: modeexec.e,v 1.16 2006-03-29 22:30:40 aschn Exp $
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
; You may want to reset all prior used ModeExecute defs with
; 'ModeExecute CLEAR'.
;
; Syntax: ModeExecute <mode> <set_cmd> <args>
;
;         <set_cmd>         <args>
;
;         SetStreamMode     0 | 1
;         SetInsertMode     0 | 1
;         SetHighlight      0 | 1
;         SetTabs           <number> or <list of numbers>
;         SetTabkey         0 | 1
;         SetMatchTab       0 | 1
;         SetMargins        <left> <right> <par>
;         SetTextColor      <number> or <color_name> (see COLORS.E)
;         SetMarkColor      <number> or <color_name> (see COLORS.E)
;                           (Hint: place cursor on COLORS.E and press Alt+1 to
;                                  load the file)
;         SetTextFont       <font_size>.<font_name>[.<font_sel>]
;                              <font_size> and <font_name> can be exchanged.
;                              Any EPM font specification syntax is
;                              accepted as well. The args are case-sensitive.
;         SetToolbar        <toolbar_name> (must be defined in NEPMD.INI)
;         SetDynaspell      0 | 1
;         SetEditOptions    see description of EDIT command
;         SetSaveOptions    see description of SAVE command
;         SetSearchOptions  see description of LOCATE and REPLACE commands
;                           (plus undocumented TB options)
;         SetKeys           <keyset_name>
;
;      Settings for syntax expansion:
;         SetExpand         0 | 1
;         SetIndent         <number> (default = first number of tabs)
;         SetHeaderStyle    1 | 2
;                              HeaderStyle 1 (default):
;                              /********************
;                              * |
;                              ********************/
;                              HeaderStyle 2:
;                              /********************
;                               * |
;                               *******************/
;         SetHeaderLength      <-- header_length --> (default = 77)
;         SetEndCommented   0 | 1
;         SetMatchChars     <space-separated list of pairs> (default = '')
;                              list of possible pairs: '{ } [ ] ( ) < >'
;         SetCommentAutoTerminate
;                           0 | 1 (default = 0)
;         SetFunctionSpacing
;                           'N' | 'C' | 'SC' | 'SCE' (default = 'C')
;                               'N' no spaces
;                               'C' space after a comma in a parameter list
;                               'S' space after start (opening parenthesis) of a parameter list
;                               'E' space before end (closing parenthesis) of a parameter list
;         SetClosingBraceAutoIndent
;                           0 | 1 (default = 0)
;         SetCodingStyle    <coding_style>
;                              Coding styles can be defined with the
;                              AddCodingStyle command, even in PROFILE.ERX
;
;      Settings for keyset C_KEYS:
;         SetCBraceStyle    'BELOW' | 'APPEND' | 'INDENT' | 'HALFINDENT'
;                              (default = 'BELOW')
;         SetCCaseStyle     'INDENT' | 'BELOW' (style of "case" statement,
;                              default = 'INDENT')
;         SetCDefaultStyle  'INDENT' | 'BELOW' (style of "default" statement,
;                              default = 'INDENT')
;         SetCMainStyle     'STANDARD' | 'SHORT' (style of "main" statement,
;                              default = 'SHORT')
;         SetCCommentStyle  'CPP' | 'C' (use either // ... or /* ... */, if
;                              EndCommented = 1, default = 'CPP')

;      Settings for keyset REXX_KEYS:
;         SetRexxDoStyle    'APPEND' | 'INDENT' | 'BELOW' (style of "do"
;                              statement, default = 'BELOW')
;         SetRexxIfStyle    'ADDELSE' | 'NOELSE' (style of "if" statement,
;                              default = 'NOELSE')
;         SetRexxCase       'LOWER' | 'MIXED' | 'UPPER' (default = 'LOWER')
;         SetRexxForceCase  0 | 1 (default = 1)
;                              1 means: change case of typed statements as
;                              well, not only of the added statements
;
; Any <set_cmd> can also be executed in EPM's commandline. Then it will
; affect only the current file.
;
;   SetTextColor 31     (31 = (15 = white) + (16 = blue background))

; Specify DEFAULT as <args>, if you want to reset a setting to NEPMD's
; default value.
;
;   SetTextColor default

; If you want to reset all settings of the current file to the default
; settings for a mode, then use the mode command:
;
;   Mode 0        (redetermine mode and apply mode-specific settings)
;   Mode rexx     (change mode to REXX and apply all REXX-specific settings)

/*
; maybe planned some time
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
; Every defined setting name must be added to either the 'loadsettingslist'
; or the 'selectsettingslist' array var to make the setting take effect on
; defload or defselect.
; In order to make these list extendible easily by additional macro files,
; array vars are used.
; The lists must be built before 'InitModeCnf', defined in MODECNF.E is
; executed at defmain. Therefore definit is a good choice for that.
; At all places here settings have the prefix 'Set' stripped before being
; added to lists. But when a setting is saved with a value, it's always
; saved with the prefix to make the string executable directly.
definit
   call AddAVar( 'loadsettingslist',
                        'Highlight Margins Tabs Keys DynaSpell')
   call AddAVar( 'selectsettingslist',
                        'Toolbar Expand Matchtab Tabkey' ||
                        ' EditOptions SaveOptions SearchOptions' ||
                        ' StreamMode InsertMode' ||
                        ' TextFont TextColor MarkColor Indent' ||
                        ' HeaderStyle HeaderLength EndCommented' ||
                        ' MatchChars CommentAutoTerminate' ||
                        ' FunctionSpacing ClosingBraceAutoIndent')

; ---------------------------------------------------------------------------
defc ResetFileSettings
   fProcessLoad   = 0
   fProcessSelect = 0
   args = arg(1)
   if args = '' then
      fProcessLoad   = 1
      fProcessSelect = 1
   else
      wp = wordpos( 'LOAD', upcase( args))
      if wp then
         fProcessLoad = 1
         args = delword( args, wp, 1)
      endif
      wp = wordpos( 'SELECT', upcase( args))
      if wp then
         fProcessSelect = 1
         args = delword( args, wp, 1)
      endif
   endif
   LoadSettingsList   = GetAVar( 'loadsettingslist')
   SelectSettingsList = GetAVar( 'selectsettingslist')
   -- Set all <setting>.<fid> array vars to empty
   getfileid fid
   SettingsList = LoadSettingsList SelectSettingsList
   do w = 1 to words(SettingsList)
      wrd = word( SettingsList, w)
      call SetAVar( lowcase(wrd)'.'fid, '')
   enddo
   call SetAVar( 'modesettingsapplied.'fid, 0)
   -- Process settings
   if fProcessLoad then
      'ProcessLoadSettings'
   endif
   if fProcessSelect then
      'ProcessSelectSettings'
   endif

; ---------------------------------------------------------------------------
; Processes all mode specific defload settings.
; Executed by defload and defc ResetFileSettings.
; (defc Mode and ResetMode call ResetFileSettings when the mode has changed.)
defc ProcessLoadSettings
   universal nepmd_hini
   universal loadstate  -- 1: defload is running
                        -- 2: defload processed
                        -- 0: afterload processed

   if not .visible then
      return
   endif
   LoadSettingsList   = GetAVar( 'loadsettingslist')

   parse arg Mode calling_fid
   Mode = strip(Mode)
   calling_fid = strip(calling_fid)

   if Mode = '' then
      Mode = GetMode()  -- Doesn't work properly during file loading, because current file
                        -- has probably changed? Therefore Mode is submitted as arg.
   endif

   KeyPath = '\NEPMD\User\KeywordHighlighting\AutoRefresh'
   refresh_on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if refresh_on then
      if loadstate then
         HiliteCheckFlag = GetHiliteCheckFlag(Mode)
      else
         HiliteCheckFlag = ''
      endif
   else
      HiliteCheckFlag = 'N'
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
   imax = GetAVar( prefix''HookName'.0')
   if imax = '' then
      imax = 0
   endif
   do i = 1 to imax
      Cmd = GetAVar( prefix''HookName'.'i)
      Cmd  -- execute command
   enddo

   if loadstate then  -- during defload processing
      -- Activate keyword highlighting, if not already done by load_<mode> hook
      next = GetAVar( 'highlight.'fid)  -- get file setting
      if next = '' | next = 'DEFAULT' then
         call NepmdActivateHighlight( default_on, Mode, HiliteCheckFlag)
      endif

   else               -- when changing a mode
      List = LoadSettingsList
      do w = 1 to words( List)  -- Only LoadSettings need to be reset for default mode
         wrd = word( List, w)
         next = GetAVar( lowcase(wrd)'.'fid)  -- get file setting
         if next = '' | next = 'DEFAULT' then
            'Set'wrd 'DEFAULT'  -- execute load setting with 'DEFAULT'
         endif
      enddo
      -- Refresh the mode field on statusline.
      -- Don't process this on defload, because it's already executed there.
      'RefreshInfoLine MODE'
      -- Maybe the load and load_once hook should here be executed as well?

   endif

; ---------------------------------------------------------------------------
; Executed by defc ProcessSelect, using the select hook
; and by defc ResetFileSettings.
; (defc Mode and ResetMode call ResetFileSettings when the mode has changed.)
defc ProcessSelectSettings
   if not .visible then
      return
   endif
   SelectSettingsList = GetAVar('selectsettingslist')

   -- Get file-specific setting names
   -- Check if a setting is set as array var (maybe as a file setting)
   getfileid fid
   UsedFileSettings = ''
   -- Check if mode settings already overtaken from the hook to current file's array var
   fModeSettingsApplied = GetAVar('modesettingsapplied.'fid)
   if fModeSettingsApplied then
      do w = 1 to words(SelectSettingsList)
         wrd = word( SelectSettingsList, w)
         wrd = lowcase( wrd)
         SettingsValue = GetAVar(wrd'.'fid)
         if SettingsValue <> '' & SettingsValue <> 'DEFAULT' then
            UsedFileSettings = UsedFileSettings wrd
         endif
      enddo
      UsedFileSettings = strip(UsedFileSettings)
   endif
;   call NepmdPmPrintf('UsedFileSettings = 'UsedFileSettings)

   -- Execute mode-specific settings
   -- Using the standard definition for HookExecute, extended with a check, if
   -- config is set by the file instead of the mode.
   Mode = GetMode()
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
      if leftstr( upcase(wrd), 3) = 'SET' then
         wrd = substr( wrd, 4)  -- strip 'Set'
      endif
      if not wordpos( upcase(wrd), upcase(UsedFileSettings)) then
;         call NepmdPmPrintf('MODE: 'Cmd' -- '.filename)
         Cmd  -- execute command
         UsedModeSettings = UsedModeSettings wrd
      endif
   enddo
   UsedModeSettings = strip(UsedModeSettings)
   if not fModeSettingsApplied then
      call SetAVar( 'modesettingsapplied.'fid, 1)
   endif

   -- Execute file-specific settings
   do w = 1 to words(UsedFileSettings)
      wrd = word( UsedFileSettings, w)
      SettingsValue = GetAVar(lowcase( wrd)'.'fid)
      Cmd = 'Set'wrd SettingsValue
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
         Cmd = 'Set'wrd 'DEFAULT'  -- execute select setting with 'DEFAULT'
;         call NepmdPmPrintf('RESET: 'Cmd' -- '.filename)
         Cmd  -- execute command
      endif
   enddo
   call SetAVar( 'lastusedsettings', CurSettings)

; ---------------------------------------------------------------------------
; Add cmd to the select hook. This hook will be executed by HookExecute, by
; defc ProcessSelect at ProcessAfterLoad and/or defselect.
; (The defc ProcessLoadSettings is executed directly, without the HookExecute
; command. This is required to process these settings for the correct file.)
definit
   'HookAdd select ProcessSelectSettings'

; ---------------------------------------------------------------------------
; Determine on which stack the cmd should be put on or delete the stacks.
; Syntax:
;    ModeExecute <mode> <set_cmd> <value>   to define a <value> for
;                                           <set_cmd>, that is used for files
;                                           with mode <mode>
;    ModeExecute DEFAULT <set_cmd> <value>  to define the default <value>
;                                           for <set_cmd> (only possible for
;                                           some syntax expansion settings)
;    ModeExecute CLEAR                      to clear all existing settings,
;                                           but default <values> are not
;                                           effected
; /*To change settings of already loaded files, too, use ModeExecuteRefresh.*/
defc ModeExecute, ModeExec
   universal loadstate  -- 1: defload is running
                        -- 2: defload processed
                        -- 0: afterload processed
   LoadSettingsList   = GetAVar( 'loadsettingslist')
   SelectSettingsList = GetAVar( 'selectsettingslist')
   parse value arg(1) with Mode Cmd Args
   Mode = strip(Mode)
   Cmd  = strip(Cmd)
   Args = strip(Args)
   Mode = upcase(Mode)

   if Mode = 'CLEAR' then
      -- Clear existing load_<mode> and select_<mode> hooks
      List = GetAVar('usedsettings_modes')
      do w = 1 to words(List)
         wrd = word( List, w)
         'HookDelAll load_'lowcase(wrd)
         'HookDelAll select_'lowcase(wrd)
      enddo
      return 0
   elseif Mode = 'DEFAULT' then
      Cmd 'DEFINEDEFAULT' Args
      return 0
   endif

   -- Execute the SetCodingStyle <set_cmd> immediately
   if upcase( Cmd) = 'SETCODINGSTYLE' then
      call ExecuteCodingStyle( Mode, Args)
      return 0
   endif

   wrd = Cmd
   if leftstr( upcase( wrd), 3) = 'SET' then
      wrd = substr( wrd, 4)  -- strip 'Set'
   endif

   if wordpos( upcase(wrd), upcase(SelectSettingsList)) then
      -- These settings don't stick with the current file.
      -- Execute them during ProcessAfterload and at/or defselect.
      'HookChange select_'lowcase(Mode) Cmd Args
      -- Save a list of used defselect settings for every mode
      call AddAVar('usedsettings_'lowcase(Mode), wrd)
   elseif wordpos( upcase(wrd), upcase(LoadSettingsList)) then
      -- These settings stick with the current file and don't need additional
      -- handling at defselect.
      -- Execute them at defload only.
      'HookChange load_'lowcase(Mode) Cmd Args
   else
      sayerror 'ModeExecute: "'Cmd Args'" is an invalid setting. Add "'wrd ||
               '" to the select/loadsettingslist array var.'
      return 1
   endif
   if not loadstate then
      'RingRefreshSetting' arg(1)
   endif
   -- Save a list of used modes to be able to delete all settings
   if not wordpos( Mode, GetAVar('usedsettings_modes', Mode)) then
      call AddAVar('usedsettings_modes', Mode)
   endif

; ---------------------------------------------------------------------------
; Syntax: RingRefreshSetting <mode> <cmd> <args>
; Refresh specified setting for those files in the ring, whose settings were
; not changed with a Set* command of MODEEXEC.E before. Should be executed
; by
;    -  any command, that changes default defload settings
;       currently, these are: SetHighlight, SetMargins, SetTabs
;       not effected: SetKeys SetDynaSpell (only saved as field var)
;    -  a modeexecuterefresh command, if executed by hand, after file is loaded.
; <cmd> must have the name of the array var plus 'Set' prepended.
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
      elseif Mode = GetMode() then
         if i = 1 then
            'ResetFileSettings'  -- all settings (reset of a single setting is not implemented)
         else
            'ResetFileSettings LOAD'  -- all load settings (reset of a single setting is not implemented)
         endif
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

; ---------------------------------------------------------------------------
/*
; Use this command instead of ModeExecute after files are loaded.
defc ModeExecuteRefresh, ModeExecRefresh
   'ModeExecute' arg(1)
   'RingRefreshSetting' arg(1)
*/

; ---------------------------------------------------------------------------
; Add file-specific setting name and its value to the array.
; Add setting name to list of lastusedsettings.
; This is used by several select setting defs.
defproc UseSetting
   SettingName = arg(1)
   SettingValue = arg(2)
   getfileid fid
   if GetAVar( lowcase( SettingName)'.'fid) <> SettingValue then
      call SetAVar( lowcase( SettingName)'.'fid, SettingValue)
      if not wordpos( upcase(SettingName), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', SettingName)
      endif
   endif

; ---------------------------------------------------------------------------
; Refresh specified setting for those files in the ring, whose setting were
; not changed with a Set* command of MODEEXEC.E.
; The command must be
defc RingDumpSettings
   LoadSettingsList   = GetAVar( 'loadsettingslist')
   SelectSettingsList = GetAVar( 'selectsettingslist')
   SettingsList = LoadSettingsList SelectSettingsList
   SettingsList = SettingsList' modesettingsapplied'  -- append system var
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
   if line > '' then
      insertline line, .last + 1
   endif
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
   if line > '' then
      insertline line, .last + 1
   endif
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
      insertline '   'leftstr( 'mode', max( length('mode'), 22))' = 'GetMode(), tmpfid.last + 1, tmpfid
      do w = 1 to words(SettingsList)
         wrd = word( SettingsList, w)
         SettingName = lowcase(wrd)
         SettingValue = GetAVar( SettingName'.'fid)  -- query file setting
         insertline '   'leftstr( SettingName, max( length(SettingName), 22))' = 'SettingValue, tmpfid.last + 1, tmpfid
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

; ---------------------------------------------------------------------------
; Set* commands
; These commands can be used with the ModeExecute command. Then they set the
; value for all files of a mode. If a <set_cmd> is used alone, only the
; current activated file is effected.
; Syntax:
;    <set_cmd> <value>
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
      arg1 = delword( arg1, wp, 1)  -- remove 'N' from arg1
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
   Mode = GetMode()
   KeyPath = '\NEPMD\User\KeywordHighlighting\AutoRefresh'
   refresh_on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if refresh_on then
      if (CheckFlag = '') & loadstate then
         CheckFlag = GetHiliteCheckFlag(Mode)
      endif
   else
      CheckFlag = 'N'
   endif
   -- Todo: Add option to force reload of temp epmkwds file (call
   --       toggle_parse with parameter 2 instead of 1).
   --       Currently it is always reloaded, what is a huge waste.
   --       Note: When an entire ring should be refreshed, the epmkwds
   --             file needs to be reloaded only once per mode.
   --       Related: defc toggle_parse in STDCTRL.E.
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
   arg1 = upcase(arg(1))
   if current_toolbar = '' then
      current_toolbar = toolbar_loaded
   endif
   if upcase(current_toolbar) <> arg1 then
      if arg1 = '' | arg1 = 'DEFAULT' then
         --def_toolbar = queryprofile( app_hini, appname, INI_DEF_TOOLBAR)
         def_toolbar = GetDefaultToolbar()
         if def_toolbar <> '' then
            'postme LoadToolbar NOSAVE' def_toolbar
            current_toolbar = def_toolbar
         endif
      elseif arg1 = \1 | wordpos( arg1, 'BUILTIN STANDARD') then
         'postme LoadStandardToolbar'  -- built-in toolbar, NOSAVE not required
         current_toolbar = 'STANDARD'
      else
         'postme LoadToolbar NOSAVE' arg(1)
         current_toolbar = arg(1)
      endif
   endif
   -- Save the value in an array var, because no field var exists
   call UseSetting( 'ToolBar', arg(1))

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
   call UseSetting( 'Expand', arg(1))
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
   call UseSetting( 'Indent', arg(1))

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
   call UseSetting( 'MatchTab', arg(1))
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
   call UseSetting( 'EditOptions', arg(1))

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
   call UseSetting( 'SaveOptions', arg(1))

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
   call UseSetting( 'SearchOptions', arg(1))

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
   call UseSetting( 'TabKey', arg(1))
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
   call UseSetting( 'StreamMode', arg(1))
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
   call UseSetting( 'InsertMode', arg(1))
   -- Update of infoline field is handled internally

; ---------------------------------------------------------------------------
; Syntax: SetTextFont <size>[.<name>[.<attrib1>[ <attrib2>]]]  or
;         SetTextFont <name>.<size>[.<attrib[ <attrib2>]]
; Any following specifications, separated by a period are ignored.
defc SetTextFont
   universal nepmd_hini
   universal lastfont
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      --new = queryprofile( app_hini, appname, 'FONT')
      --if new = '' then
      --   new = '12.System VIO'
      --endif
      KeyPath = '\NEPMD\User\Fonts\Text'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = arg(1)
      parse value new with size '.' rest
      if not isnum( size) then
         sayerror 'Unknown font specification "'arg1'"'
         return
      endif
      if rest = '' then
         parse value queryfont(.font) with fontname '.' fontsize '.' fontsel
         new = size'.'fontname
         if fontsel > 0 then
            new = size'.'fontname'.'fontsel
         endif
      endif
   endif
   if new <> lastfont then
      lastfont = new  -- save it in a universal var, because .font holds only an id
                      -- It would be much better to avoid the processfontrequest
                      -- and execute simply: .font = <font_id>. Therefore the
                      -- font_id would have been saved, after it was registered:
                      -- .font = registerfont(fontname, fontsize, fontsel)
      new = ConvertToEFont( new)
      'processfontrequest' new
      --'postme processfontrequest' new  -- must be posted (why?) -- apparently not!
   endif
   -- Save the value in an array var, because no field var exists
   call UseSetting( 'TextFont', arg(1))

; ---------------------------------------------------------------------------
defc SetTextColor
   --universal appname
   --universal app_hini
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      --colors = queryprofile( app_hini, appname, 'STUFF')
      --if colors = '' then
      --   new = 120
      --else
      --   new = subword( colors, 1, 1)
      --endif
      KeyPath = '\NEPMD\User\Colors\Text'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = ConvertColor( arg(1))
      if rc <> 0 then
         return rc
      endif
   endif
   if new = '' then
      return
   elseif new <> .textcolor then  -- the color is set but needs activation
      .textcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   call UseSetting( 'TextColor', arg(1))

; ---------------------------------------------------------------------------
defc SetMarkColor
   --universal appname
   --universal app_hini
   universal nepmd_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      --colors = queryprofile( app_hini, appname, 'STUFF')
      --if colors = '' then
      --   new = 113
      --else
      --   new = subword( colors, 2, 1)
      --endif
      KeyPath = '\NEPMD\User\Colors\Mark'
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   else
      new = ConvertColor(arg(1))
      if rc <> 0 then
         return
      endif
   endif
   if new = '' then
      return
   elseif new <> .markcolor then  -- the color is set but needs activation
      .markcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   call UseSetting( 'MarkColor', arg(1))

; ---------------------------------------------------------------------------
; Common Set* commands for syntax expansion
; For these commands a DEFINEDEFAULT parameter exists, as long as the
; default value is not configurable via the menu or a settings dialog.
; DEFINEDEFAULT is added by ModeExecute, when it is called with the DEFAULT
; pseudo mode.
; Syntax:
;    <set_cmd> <value>                to set a <value> for <set_cmd>
;    <set_cmd> DEFINEDEFAULT <value>  to set the default <value>, that is
;                                     used if no <set_cmd> exists for a mode
;                                     or a file
; ---------------------------------------------------------------------------
; Used in: CKEYS.E, REXXKEYS.E
defc SetHeaderStyle
   universal header_style
   universal default_header_style
   ValidArgs = '1 2'
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if header_style = default_header_style then
         header_style = rest  -- init
      endif
      default_header_style = rest
   else
      if not wordpos( arg1, ValidArgs) then
         if default_header_style = '' then
            default_header_style = 1
         endif
         arg1 = default_header_style
      endif
      header_style = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'HeaderStyle', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: CKEYS.E, REXXKEYS.E
defc SetHeaderLength
   universal header_length
   universal default_header_length
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if header_length = default_header_length then
         header_length = rest  -- init
      endif
      default_header_length = rest
   else
      if not IsNum( arg1) then
         if default_header_length = '' then
            default_header_length = 77
         endif
         arg1 = default_header_length
      endif
      header_length = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'HeaderLength', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: CKEYS.E, REXXKEYS.E
; Auto-comment an 'end' statement
defc SetEndCommented
   universal END_commented
   universal default_END_commented
   ValidArgs = '0 1'
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if END_commented = default_END_commented then
         END_commented = rest  -- init
      endif
      default_END_commented = rest
   else
      if not wordpos( arg1, ValidArgs) then
         if default_END_commented = '' then
            default_END_commented = 0
         endif
         arg1 = default_END_commented
      endif
      END_commented = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'EndCommented', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: STDKEYS.E/KEYS.E
; Define pairs of matching chars. The closing char is added while typing the
; opening char.
defc SetMatchChars
   universal match_chars
   universal default_match_chars
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if match_chars = default_match_chars then
         match_chars = rest  -- init
      endif
      default_match_chars = rest
   else
      if arg1 = '' | arg1 = 'DEFAULT' then
         if default_match_chars = '' then
            default_match_chars = ''
         endif
         arg1 = default_match_chars
      endif
      match_chars = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'MatchChars', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: CKEYS.E, REXXKEYS.E
; Append "*/" automatically if comment was opened on current line
defc SetCommentAutoTerminate
   universal comment_auto_terminate
   universal default_comment_auto_terminate
   ValidArgs = '0 1'
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if comment_auto_terminate = default_comment_auto_terminate then
         comment_auto_terminate = rest  -- init
      endif
      default_comment_auto_terminate = rest
   else
      if not wordpos( arg1, ValidArgs) then
         if default_comment_auto_terminate = '' then
            default_comment_auto_terminate = 0
         endif
         arg1 = default_comment_auto_terminate
      endif
      comment_auto_terminate = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'CommentAutoTerminate', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: CKEYS.E
; Spaces at Start/Comma/End of parameter list
defc SetFunctionSpacing
   universal function_spacing
   universal default_function_spacing
   ValidArgs = 'N C SC SCE'  -- No spaces, space at Start/Comma/End of parameter list
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if function_spacing = default_function_spacing then
         function_spacing = rest  -- init
      endif
      default_function_spacing = rest
   else
      if not wordpos( arg1, ValidArgs) then
         if default_function_spacing = '' then
            default_function_spacing = 'C'
         endif
         arg1 = default_function_spacing
      endif
      function_spacing = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'FunctionSpacing', arg(1))
   endif

; ---------------------------------------------------------------------------
; Used in: CKEYS.E
; (Un)indent line with "}" to the indent of "{"
defc SetClosingBraceAutoIndent
   universal closing_brace_auto_indent
   universal default_closing_brace_auto_indent
   ValidArgs = '0 1'
   arg1 = strip( upcase( arg(1)))
   parse value arg1 with next rest
   if next = 'DEFINEDEFAULT' then
      if closing_brace_auto_indent = default_closing_brace_auto_indent then
         closing_brace_auto_indent = rest  -- init
      endif
      default_closing_brace_auto_indent = rest
   else
      if not wordpos( arg1, ValidArgs) then
         if default_closing_brace_auto_indent = '' then
            default_closing_brace_auto_indent = 0
         endif
         arg1 = default_closing_brace_auto_indent
      endif
      closing_brace_auto_indent = arg1
      -- Save the value in an array var, because no field var exists
      call UseSetting( 'ClosingBraceAutoIndent', arg(1))
   endif

; ---------------------------------------------------------------------------
; Commands for coding styles
; ---------------------------------------------------------------------------
; Delete the hook (to be executed before overwriting an entire hook instead
; of changing the values).
; Syntax: DelCodingStyle <name>
defc DelCodingStyle
   parse arg name
   name = lowcase( name)
   'HookDelAll codingstyle.'name

; ---------------------------------------------------------------------------
; Add a command to the hook. Command should be a Set* command, defined in
; this file. If command was already added to the hook, it is removed first,
; so that a command is present only once.
; Syntax: AddCodingStyle <name> <command>
defc AddCodingStyle
   parse arg name command
   name = lowcase( name)
   'HookChange codingstyle.'name command

; ---------------------------------------------------------------------------
; Syntax: ModeExecute <mode> SetCodingStyle <name>
;     or: SetCodingStyle <name>  (for file specific settings)
; This defc is only executed when used as a file setting. When used by
; a ModeExecute command, it is resolved directly by ModeExecute.
defc SetCodingStyle
   call ExecuteCodingStyle( 0, arg(1))

; ---------------------------------------------------------------------------
; Apply the coding style by executing the hook.
; Syntax:
;    ExecuteCodingStyle( <mode>, <name>)
; If called with <mode> = 0, then it is handled as a file setting, otherwise
; as a mode setting.
; Because the SetCodingStyle command is executed/resolved immediately, it
; doesn't need to be added to the loadsettingslist, selectsettingslist or
; lastusedsettings.
defproc ExecuteCodingStyle
   Mode = arg(1)
   Name = arg(2)
   Name = lowcase( Name)
   Prefix = 'hook.'
   HookName = 'codingstyle.'Name
   -- Execute the hook, maybe with "'ModeExecute' Mode" prepended
   imax = GetAVar( prefix''HookName'.0')
   if IsNum( imax) then
      do i = 1 to imax
         Cmd = GetAVar( prefix''HookName'.'i)
         if Mode = 0 then
            -- Execute the file setting
            Cmd
         else
            -- Execute the mode setting
            'ModeExecute' Mode Cmd
         endif
      enddo
   endif
   return

