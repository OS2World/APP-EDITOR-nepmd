/****************************** Module Header *******************************
*
* Module Name: modecnf.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: modecnf.e,v 1.1 2004-06-03 23:06:05 aschn Exp $
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

; This is the default configuration file for modes.
;
; You may want to create your own MODECNF.E in you MYEPM\MACROS directory.
; Don't overwrite the file in the NETLABS\MACROS directory. After changing
; it, you have to recompile EPM.E.
;
; As an alternative, you simply may want to specify the here used commands
; in your MYEPM\PROFILE.ERX. The commands from PROFILE.ERX will be executed
; after the ones from this file, so you're able to overwrite the following.

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

/*
Syntax: ModeExecute <mode> <set_cmd> <args>

<set_cmd>:
SetStreamMode
SetCuaMarking
SetInsertMode
SetHighlight
SetTabs
SetTabkey
SetMatchTab
SetMargins
SetExpand
SetIndent
SetTextColor
SetMarkColor
SetTextFont
SetToolbar
SetDynaspell
SetEditOptions
SetSaveOptions
SetSearchOptions
SetKeys

; planned?
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
; Omit definit when you put this in your PROFILE.ERX.
; Note: definit does not work in a separartely compiled .E file.
;       (Then you have to put it to the .E file's defmain.)
definit

'ModeExecute E SetKeys E_keys'
'ModeExecute E SetTabs 3'
'ModeExecute E SetMargins 1 1599 1'
'ModeExecute E SetIndent 3'

'ModeExecute REXX SetKeys REXX_keys'
'ModeExecute REXX SetTabs 3'
'ModeExecute REXX SetMargins 1 1599 1'
'ModeExecute REXX SetIndent 3'

'ModeExecute C SetKeys C_keys'
'ModeExecute C SetTabs 3'
'ModeExecute C SetMargins 1 1599 1'
'ModeExecute C SetIndent 3'

'ModeExecute JAVA SetKeys C_keys'
'ModeExecute JAVA SetTabs 3'
'ModeExecute JAVA SetMargins 1 1599 1'
'ModeExecute JAVA SetIndent 3'

'ModeExecute PASCAL SetKeys Pas_keys'
'ModeExecute PASCAL SetTabs 3'
'ModeExecute PASCAL SetMargins 1 1599 1'
'ModeExecute PASCAL SetIndent 3'

/*
/* Experimental 1 */
'ModeExecute TEXT SetHighlight 0'
'ModeExecute TEXT SetTabKey 1'
'ModeExecute TEXT SetInsertMode 0'
'ModeExecute TEXT SetDynaSpell 1'
'ModeExecute TEXT SetTextColor '112
/*'ModeExecute TEXT SetTextFont 10x6.System VIO.underscore'*/
'ModeExecute TEXT SetTextFont 9.WarpSans'
'ModeExecute TEXT SetStreamMode 0'

/*'ModeExecute BIN SetEditOptions /t /64 /bin'*/
'ModeExecute BIN SetSaveOptions /ne /ns /nt'
'ModeExecute BIN SetTabs 1'
'ModeExecute BIN SetTabKey 1'
'ModeExecute BIN SetMatchTab 0'

'ModeExecute E SetIndent 3'
'ModeExecute REXX SetIndent 4'
'ModeExecute C SetIndent 5'
*/

/*
/* Experimental 2 */
'ModeExecute E SetTabKey 0'
'ModeExecute E SetToolbar BUILDIN'
'ModeExecute E SetHighlight 1'
'ModeExecute E SetTextColor '240
'ModeExecute E SetTextFont 14.System VIO'
*/

; ---------------------------------------------------------------------------
define
   SelectSettingsList = 'SetToolbar SetExpand SetMatchtab SetTabkey' ||
                        ' SetEditOptions SetSaveOptions SetSearchOptions' ||
                        ' SetStreamMode SetCuaMarking SetInsertMode' ||
                        ' SetTextFont SetTextColor SetMarkColor SetIndent'
   LoadSettingsList   = 'SetHighlight SetMargins SetTabs' ||
                        ' SetKeys SetDynaSpell'

; ---------------------------------------------------------------------------
defc ResetFileSettings
   -- Set all <setting>.<fid> array vars to empty
   getfileid fid
   SettingsList = LoadSettingsList SelectSettingsList
   do w = 1 to words(SettingsList)
      wrd = word( SettingsList, w)
      next = lowcase(wrd)
      parse value next with 'set' rest  -- strip leading 'set'
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
   universal defloadactive

   if not .visible then
      return
   endif

   parse arg Mode calling_fid
   Mode = strip(Mode)
   calling_fid = strip(calling_fid)

   if Mode = '' then
      Mode = NepmdGetMode()  -- doesn't work while file loading, because mode has probably changed
   endif
   if defloadactive then
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
;         call NepmdPmPrintf('MODE: 'Cmd' -- '.filename)
      Cmd  -- execute command
   enddo

   -- Activate keyword highlighting, if not already done by load_<mode> hook
   next = GetAVar('highlight.'fid)  -- get file setting
   if next = '' | next = 'DEFAULT' then
      call NepmdActivateHighlight( default_on, Mode, HiliteCheckFlag)
   endif

   -- Maybe the load and load_once hook should here be executed as well?

   -- Refresh the mode field on statusline
   if not defloadactive then
      -- don't process this on defload, because it's already executed there
      'RefreshInfoLine MODE'
   endif
   return

; ---------------------------------------------------------------------------
; Executed by defc ProcessSelect, using the select hook
; and by defc ResetFileSettings.
; (defc Mode and ResetMode call ResetFileSettings when the mode has changed.)
defc ProcessSelectSettings
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
         next = lowcase(wrd)
         parse value next with 'set' rest  -- strip leading 'set'
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
      next = lowcase(wrd)
      parse value next with 'set' rest  -- strip leading 'set'
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
defc ModeExecute
   parse value arg(1) with Mode Cmd
   parse value Cmd with CmdWrd .
   Mode    = strip(Mode)
   Cmd     = strip(Cmd)
   CmdWrd  = strip(CmdWrd)
   if wordpos( upcase(CmdWrd), upcase(SelectSettingsList)) then
      -- These settings don't stick with the current file.
      -- Execute them during afterload and at/or defselect.
      'HookAdd select_'lowcase(Mode) Cmd
      -- Save a list of used settings for every mode
      call AddAVar('usedsettings_'lowcase(Mode), CmdWrd)
   elseif wordpos( upcase(CmdWrd), upcase(LoadSettingsList)) then
      -- These settings stick with the current file and don't need additional
      -- handling at defselect.
      -- Execute them at defload only.
      'HookAdd load_'lowcase(Mode) Cmd
   else
      sayerror 'ModeExecute: "'Cmd'" is an invalid setting.'
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
defc SetHighlight
   universal nepmd_hini
   universal defloadactive
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      KeyPath = '\NEPMD\User\KeywordHighlighting'
      on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   Mode = NepmdGetMode()
   if defloadactive then
      CheckFlag = NepmdGetHiliteCheckFlag(Mode)
   else
      CheckFlag = ''
   endif
   call NepmdActivateHighlight( on, Mode, CheckFlag)
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   if GetAVar( 'highlight.'fid) <> arg(1) then
      call SetAVar( 'highlight.'fid, arg(1))
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
defc SetMargins  -- defc margins exist
   universal defloadactive
   universal load_var
   -- load_var is a marker that stores if tabs or margins were already set
   -- by the EA's EPM.TABS or EPM.MARGINS
   arg1 = upcase(arg(1))
   SetFromEa    = 0
   if isnum(load_var) then
      SetFromEa = (load_var bitand 2)  -- 2 would be on if tabs set from EA EPM.MARGINS
   endif
   if arg1 = '' | arg1 = 'DEFAULT' | arg1 = 0 then
      if defloadactive & SetFromEa then
         arg1 = .margins
      else
         'margins' 0  -- reset, maybe delete EPM.MARGINS
         arg1 = 'DEFAULT'
      endif
   else
      if defloadactive then
         .margins = arg1
      else
         'margins' arg1  -- set EPM.TABS
      endif
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   call SetAVar( 'margins.'fid, arg(1))
   if not defloadactive then
      'refreshinfoline MARGINS'
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
defc SetTabs  -- defc tabs exist
   universal defloadactive
   universal load_var
   -- load_var is a marker that stores if tabs or margins were already set
   -- by the EAs EPM.TABS or EPM.MARGINS
   arg1 = upcase(arg(1))
   SetFromEa    = 0
   if isnum(load_var) then
      SetFromEa = (load_var // 2)      -- 1 would be on if tabs set from EA EPM.TABS
   endif
   if arg1 = '' | arg1 = 'DEFAULT' | arg1 = 0 then
      if defloadactive & SetFromEa then
         arg1 = .tabs
      else
         'tabs' 0  -- reset, maybe delete EPM.TABS
         arg1 = 'DEFAULT'
      endif
   else
      if defloadactive then
         .tabs = arg1
      else
         'tabs' arg1  -- set EPM.TABS
      endif
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   call SetAVar( 'tabs.'fid, arg1)
   if not defloadactive then
      'refreshinfoline TABS'
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
; Therefore we don't need to handle dynaspell here.
defc SetKeys
   universal defloadactive
   arg1 = upcase(arg(1))
   if upcase(arg(1)) = 'DEFAULT' then
      .keyset = 'EDIT_KEYS'
      arg1 = 'DEFAULT'
   else
      .keyset = arg1
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   call SetAVar( 'keys.'fid, arg1)
   if not defloadactive then
      'refreshinfoline KEYS'
   endif

; ---------------------------------------------------------------------------
; Execute this only at defload.
defc SetDynaSpell  -- defc dynaspell exists and is used here
   universal defloadactive
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
   if not defloadactive then
      'refreshinfoline KEYS'
   endif

; ---------------------------------------------------------------------------
defc SetToolbar
   universal toolbar_loaded
   universal current_toolbar
   universal appname
   universal app_hini
   arg1 = upcase(arg(1))
   if current_toolbar = '' then
      current_toolbar = toolbar_loaded
   endif
   if upcase(current_toolbar) <> arg1 then
      if arg1 = '' | arg(1) = 'DEFAULT' then
         def_toolbar = queryprofile( app_hini, appname, INI_DEF_TOOLBAR)
         if def_toolbar <> '' then
            'postme load_toolbar 'def_toolbar
            current_toolbar = def_toolbar
         endif
      elseif arg1 = \1 | pos( 'BUILDIN', arg1) then
         'postme loaddefaulttoolbar'  -- built-in toolbar
         current_toolbar = 'BUILDIN'
      else
         'postme load_toolbar 'arg1
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
   universal defloadactive
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
   if not defloadactive then
      'refreshinfoline EXPAND'
   endif

; ---------------------------------------------------------------------------
defc SetIndent
   universal indent
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      new = leftstr( .tabs, 1)
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
   universal defloadactive
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
   if not defloadactive then
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
   universal defloadactive
   universal tab_key
   universal default_tab_key
   universal appname
   universal app_hini
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
   if not defloadactive then
      'refreshinfoline TABKEY'
   endif

; ---------------------------------------------------------------------------
defc SetStreamMode
   universal defloadactive
   universal stream_mode
   universal default_stream_mode
   universal appname
   universal app_hini
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
   if not defloadactive then
      'refreshinfoline STREAMMODE'
   endif

; ---------------------------------------------------------------------------
defc SetCuaMarking
   universal defloadactive
   universal cua_marking_switch
   universal default_cua_marking_switch
   universal appname
   universal app_hini
   arg1 = upcase(arg(1))
   if arg1 = '' | arg1 = 'DEFAULT' then
      on = default_cua_marking_switch
   elseif wordpos( arg1, '0 OFF') then
      on = 0
   else
      on = 1
   endif
   -- Set universal var and process setting
   cua_marking_switch = on
   'togglecontrol 25' cua_marking_switch
   call MH_set_mouse()
/*
   -- Update Edit menu (better disable menu items, done by menuinit)
   deletemenu defaultmenu, GetAVar('mid_edit'), 0, 1           -- Delete the edit menu
   call add_edit_menu(defaultmenu)
   -- maybe_show_menu() does a refresh and closes the menu, so that the
   -- MIA_NODISMISS attribute has no effect anymore.
   call maybe_show_menu()
*/
   -- Save the value in an array var, because no field var exists
   getfileid fid
   if GetAVar( 'cuamarking.'fid) <> arg(1) then
      call SetAVar( 'cuamarking.'fid, arg(1))
      if not wordpos( upcase('SetCuaMarking'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetCuaMarking')
      endif
   endif
   if not defloadactive then
      'refreshinfoline MARKINGMODE'
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
                      -- font_id must be saved, after it was registered:
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
   else
      new = arg(1)
   endif
   if new <> .textcolor then  -- the color is set but needs activation
      .textcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   if GetAVar( 'textcolor.'fid) <> arg(1) then
      call SetAVar( 'textcolor.'fid, arg(1))
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
      new = arg(1)
   endif
   if new <> .markcolor then  -- the color is set but needs activation
      .markcolor = new
   endif
   -- Save the value in an array var, to determine 'DEFAULT' state later
   getfileid fid
   if GetAVar( 'markcolor.'fid) <> arg(1) then
      call SetAVar( 'markcolor.'fid, arg(1))
      if not wordpos( upcase('SetMarkColor'), upcase(GetAVar('lastusedsettings'))) then
         call AddAVar( 'lastusedsettings', ' SetMarkColor')
      endif
   endif


