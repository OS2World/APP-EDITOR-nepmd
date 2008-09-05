/****************************** Module Header *******************************
*
* Module Name: config.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: config.e,v 1.21 2008-09-05 22:36:43 aschn Exp $
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

; Configuration and ini file definitions.
;
; The 1st part of initialization is done in STDCNF.E by setting universal
; vars to values of consts and defining definit. definit is called before
; defmain at linking of EPM.EX. initconfig is called by defmain.
;
; Thats's the 2nd part of initialization. It concerns with settings queried
; from EPM.INI and with definitions for the settings dialog. It defines
; following commands (among others):
;
;    initconfig      Read values from ini and change configuration of
;                    current EPM window. This overwrites values previously
;                    initialized to values of consts, if their ini entries
;                    are present. Called by defmain.
;
;    renderconfig    Send values to config dialog, either
;                    -  default values defined by consts or
;                    -  values read from ini or
;                    -  current values.
;                    Called by configdlg at its startup.
;
;    setconfig       Change configuration of current EPM window according
;                    to the changes by the user. Called by configdlg at its
;                    closing.
;
; While some universals are set at definit, defc initconfig is called at
; defmain. It's quite important for performance and stability, at which time
; during startup all the init stuff is processed. This applies not only to
; getting values from the ini, but also to the creation of menu and making
; the window visible.

; Configuration changes, that must be written to the ini, can be made by
;    o  settings dialog
;    o  menu items
;    o  drag and drop from color and font palettes
;    o  additional commands

; Instead of using EPM.INI, only NEPMD.INI is used now.

; In order to always process all those ways equal, it's sometimes tricky to
; move settings to NEPMD.INI. E.g. for the color and font settings special
; commands are called after a color or font change, except for the toolbar.
;
; So every setting can be moved to NEPMD.INI, except the following (so far):
;    o  initial setup of toolbar after its startup (but can be changed
;       afterwards)
;    o  position of EPM window and others
;    o  list of toolbar names used by the standard config dialog
;    o  toolbar setup string (aka toolbar template), saved by the standard
;       config dialog (dialog will be replaced sometime)
;    o  toolbar im- and export, made by the standard config dialog (dialog
;       will be replaced sometime)
;    o  toolbar font changed via font palette
;    o  toolbar color changed via color palette (not important)
; All these issues can be handled by changing the entry for OS2.INI -> EPM
; -> EPMIniPath before EPM's startup or opening the config dialog
; and resetting it after the action, because the path for EPM.INI is read
; only once at EPM's startup, excluding for ConfigDlg!

; The entry for UCMenu -> ConfigInfo changes to some strange values after
; a font is dropped on the toolbar.
; Before:
;    832328.Helv1677721616777216
; After:
;    270401576262612.System VIO1355361413553614
;    27040157626269.WarpSans1355361413553614
; The color values are:
;    16777216 = 0x1000000  (means default color?)
;    13553614 = 0xCECFCE   (CE = 205, CF = 206)
;    light gray = 204-204-204, values above are probably just not precise.
; Maybe the 1st segment is the window handle?

; At startup the font value from UCMenu -> ConfigInfo should be copied
; to NEPMD.INI?

; Removed consts:
; INCLUDE_MENU_SUPPORT, INCLUDE_STD_MENUS, WANT_DYNAMIC_PROMPTS,
; BLOCK_ACTIONBAR_ACCELERATORS, WANT_STACK_CMDS, RING_OPTIONAL,
; WANT_STREAM_MODE, WANT_TOOLBAR, SPELL_SUPPORT, WANT_APPLICATION_INI_FILE,
; ENHANCED_ENTER_KEYS, WANT_LONGNAMES, WANT_PROFILE TOGGLE_ESCAPE,
; TOGGLE_TAB, DYNAMIC_CURSOR_STYLE, WANT_BITMAP_BACKGROUND, INITIAL_TOOLBAR
; WPS_SUPPORT, ENTER_ACTION, C_ENTER_ACTION

; Remaining consts:
; CHECK_FOR_LEXAM, HOST_SUPPORT
; my_CURSORDIMENSIONS, my_SAVEPATH,
; my_STACK_CMDS, my_CUA_MENU_ACCEL, SUPPORT_USER_EXITS

; Remaining standard ini keys (now moved to NEPMD.INI):
; (i) means: internally defined, by non-available C code.
;            Todo: All other keys should be moved to NEPMD's RegContainer.
;    EPM -> AUTOSAVE
;           AUTOSPATH
;           CommandBox (i)
;           CUA_ACCEL
;           DEFAULTSWP (i)
;           MARGINS
;           MsgBox (i)
;           OpenBox (i)
;           OPT2FLAGS
;           OPTFLAGS
;           RING
;           STACK
;           TABS
;    ERESDLGS -> * (i)
;    UCMenu -> ConfigInfo (i)
;    UCMenu_Templates -> * (i)

; ---------------------------------------------------------------------------
; Provide some consts, for the case a user really wants to change this:
const
compile if not defined(CONFIGDLG_START_WITH_CURRENT_FILE_SETTINGS)
   -- 0 => start with settings from EPM.INI
   CONFIGDLG_START_WITH_CURRENT_FILE_SETTINGS = 0     -- previous standard would have been 1
compile endif
compile if not defined(CONFIGDLG_CHANGE_FILE_SETTINGS)
   CONFIGDLG_CHANGE_FILE_SETTINGS = 'REFRESHDEFAULT'  -- previous standard would have been 1
compile endif
compile if not defined(CONFIGDLG_ASK_REFLOW)
   CONFIGDLG_ASK_REFLOW = 0                           -- previous standard would have been 1
compile endif

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: configdlg       syntax:   configdlg                      ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal configuration dialog. ³
³                   This is done by posting a EPM_POPCONFIGDLG message to    ³
³                   the EPM Book window.                                     ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   7/20/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc ConfigDlg
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif

   args = arg(1)
   wp = wordpos( 'SYS', upcase( args))  -- SYS not used by EPM. Used by Epm class?
   if wp then
      args = delword( args, wp, 1)
      msgid = 5147  -- EPM_POPSYSCONFIGDLG
   else
      msgid = 5129  -- EPM_POPCONFIGDLG
   endif

   omit = 0
   omit = omit +   4  -- omit Paths page (outdated)
   omit = omit +   8  -- omit Autosave page (outdated)
   omit = omit +  32  -- omit Keys page (outdated)
   --omit = 512
   if isnum( args) then
      omit = args
   endif
   -- omit: from 0 to 1023
   --    0: show all pages
   --    1: without page  1  Margins
   --    2: without page  2  Colors
   --    4: without page  3  Paths
   --    8: without page  4  Autosave
   --   16: without page  5  Fonts
   --   32: without page  6  Keys
   --   64: without page  7  Window
   --  128: without page  8  Misc.
   --  256: without page  9  Toolbar style
   --  512: without page 10  Toolbar

   'ChangeEpmIniPath'

   call windowmessage( 0, getpminfo(APP_HANDLE),
                       msgid,
                       omit,           -- 0 = Omit no pages
compile if CHECK_FOR_LEXAM
                       not LEXAM_is_available)
compile else
                       0)
compile endif

; ---------------------------------------------------------------------------
; Change entry of OS2.INI -> EPM -> EPMIniPath to filename of NEPMD.INI
; in order to keep the ini file for standard EPM unchanged.
; NEPMD.INI is used now for all settings, that otherwise would be written
; to EPM.INI:
;    o  window positions
;    o  remaining settings, that are still not replaced by NEPMD settings
;    o  settings from external packages
; For the ConfigDlg the entry has to be changed before its startup by E
; macros separately.
defc ChangeEpmIniPath
   universal nepmd_hini
   EpmIniFile = queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath')
   --dprintf( 'ConfigDlg', 'EpmIniFile = 'EpmIniFile)

   next = NepmdQueryInstValue( 'INIT')
   parse value next with 'ERROR:'rc
   if rc = '' then
      if upcase( next) <> upcase( EpmIniFile) then

         -- Write filename of NEPMD.INI to OS2.INI
         call setprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath', next)
         --dprintf( 'ConfigDlg', 'Write new value: EPMIniPath = 'next)

         -- Save old entry of OS2.INI to restore it after ConfigDlg's startup
         -- by SetConfig
         KeyPath = '\NEPMD\System\SavedEPMIniPath'
         -- This always terminates the entry with a zero
         call NepmdWriteConfigValue( nepmd_hini, KeyPath, EpmIniFile)

      endif
   endif

; ---------------------------------------------------------------------------
; Restore previous ini value, temporary changed in defc ConfigDlg.
; This is executed on the first call to SetConfig by the dialog.
; It would be possible to restore it just after the dialog was opened (by
; ConfigDlg, but then the last page of the dialog (toolbar) would read its
; values for the list of toolbar names from EPM.INI, so that the toolbar page
; might be omitted then.
defc RestoreEpmIniPath
   universal nepmd_hini

   next = NepmdQueryInstValue( 'INIT')
   EpmIniFile = queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath')
   -- Process this only once (on first call to SetConfig by the dialog)
   if next <> EpmIniFile then  -- if already reset
      return
   endif

   KeyPath = '\NEPMD\System\SavedEPMIniPath'
   next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   --dprintf( 'RestoreEpmIniPath', 'SavedEPMIniPath = 'next)
   parse value next with 'ERROR:'rc
   if rc = '' then
      EpmIniFile = next
   else
      return rc
   endif

   parse value next with 'ERROR:'rc
   if rc = '' then

      -- Restore previous ini value
      -- This always terminates the entry with a zero
      call setprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath', EpmIniFile)
      --dprintf( 'RestoreEpmIniPath, called by SetConfig', 'Restore old value: EPMIniPath = 'EpmIniFile)

      -- Delete entry
      call NepmdDeleteConfigValue( nepmd_hini, KeyPath)

   endif

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called:  renderconfig                                            ³
³           syntax:  renderconfig reply_window_hwnd page fsend_default       ³
³                                                                            ³
³ what does it do : Upon the request of a external window, sent configuration³
³                   information in the form of special WM_COMMAND messages   ³
³                   to the window handle specified in parameter one.         ³
³                                                                            ³
³                   The second parameter is the page number of the config    ³
³                   dialog which is requesting the information; this tells   ³
³                   us the range of information desired.  (Each page only    ³
³                   gets sent the information for that page, when the page   ³
³                   is activated.  Better performance than sending every-    ³
³                   thing when the dialog is initialized.)                   ³
³                                                                            ³
³                   The third parameter is a flag, as follows:               ³
³                      0 -> send value from .ini file                        ³
³                      1 -> send default value (ignoring .ini)               ³
³                      2 -> send current value (5.60 & above, only)          ³
³                                                                            ³
³                   The fuction is used by EPM to fill in the EPM CONFIG     ³
³                   dialog box.                                              ³
³                                                                            ³
³ who and when    : Jerry C. & LAM  7/20/89                                  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc renderconfig
;   universal addenda_filename
;   universal dictionary_filename
   universal vAUTOSAVE_PATH
;   universal vTEMP_PATH
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal appname, app_hini
   universal nepmd_hini
;   universal enterkey, a_enterkey, c_enterkey, s_enterkey
;   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
   universal default_font
   universal vmessagecolor, vstatuscolor
   universal statfont, msgfont
   universal bm_filename
   universal bitmap_present
   universal toolbar_loaded
   universal stream_mode
   universal show_longnames
   universal rexx_profile
   universal cua_marking_switch
   universal tab_key
   universal cua_menu_accel
   universal vepm_pointer, cursordimensions

   parse arg hndle page fsend_default .  --  Usually fsend_default is = 2 at this point

   --------------------------------------------------------------------------
   -- Overwrite fsend_default to open the settings dialog with standard
   -- settings (from EPM.INI), not with settings of the current file.
   -- In standard EPM defc SetConfig (called when the dialog is closed)
   -- compares these settings with the current file's settings. If different,
   -- the settings for the current file are changed, what is not intended
   -- now.
   -- Therefore in defc SetConfig the update of current file's margins and
   -- tabs is diabled now.
   -- The settings notebook will change only default or global settings now.
compile if CONFIGDLG_START_WITH_CURRENT_FILE_SETTINGS = 0  -- new default
   fsend_default = 0
compile elseif CONFIGDLG_START_WITH_CURRENT_FILE_SETTINGS = 1
   fsend_default = 2
compile endif
   -- else use submitted flag (normally = 2)

   -- Notebook control ----------------------------------------------
      help_panel = 5300 + page

   if page = 1 then  --------------------- Page 1 is tabs -------------
      if fsend_default = 2 then tempstr = .tabs
      else tempstr = checkini( fsend_default, INI_TABS, DEFAULT_TABS)
      endif
      call send_config_data( hndle, tempstr, 3, help_panel)
      tempstr = 0
      if not fsend_default then      -- 0: Use values from .ini file
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if words(newcmd) >= 14 then
            -- OPTFLAGS:   14
            tempstr = word(newcmd, 14)
         endif
      elseif fsend_default = 2 then  -- 2: Use current values
         tempstr = tab_key
      endif
      call send_config_data( hndle, tempstr, 19, help_panel)

   elseif page = 2 then  ----------------- Page 2 is margins ----------
      if fsend_default = 2 then    -- 2: Use current values
         tempstr = .margins
      else                         -- 0|1: Use values from .ini file or default values
         tempstr = checkini( fsend_default, INI_MARGINS, DEFAULT_MARGINS)
      endif
      call send_config_data( hndle, tempstr, 1, 5301)

   elseif page = 3 then  ----------------- Page 3 is colors -----------
      if fsend_default = 2 then    -- 2: Use current values
         tempstr = .textcolor .markcolor vstatuscolor vmessagecolor
      else
         if fsend_default then     -- 1: Use default values
            tempstr = ''
         else                      -- 0: Use values from .ini file
            KeyPath = '\NEPMD\User\Colors'
            textcol    = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Text')
            markcol    = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Mark')
            statuscol  = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Status')
            messagecol = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Message')
            tempstr = textcol markcol statuscol messagecol
         endif
         if tempstr = '' | tempstr = 1 then
            tempstr = TEXTCOLOR MARKCOLOR STATUSCOLOR MESSAGECOLOR
         endif
      endif
      parse value tempstr with ttextcolor tmarkcolor tstatuscolor tmessagecolor .
      call send_config_data( hndle, ttextcolor, 4, help_panel)
      call send_config_data( hndle, tmarkcolor, 5, help_panel)
      call send_config_data( hndle, tstatuscolor, 6, help_panel)
      call send_config_data( hndle, tmessagecolor, 7, help_panel)

   elseif page = 4 then  ----------------- Page 4 is paths ------------
; Page 4 is not compatible with the config via the Options menu.
;compile if CHECK_FOR_LEXAM
;      if lexam_is_available then
;compile endif
;         help_panel = 5390  -- Different help panel
;compile if CHECK_FOR_LEXAM
;      endif
;compile endif
;      call send_config_data( hndle, checkini( fsend_default, INI_TEMPPATH, vTEMP_PATH, TEMP_PATH), 10, help_panel)
;compile if CHECK_FOR_LEXAM
;      if lexam_is_available then
;compile endif
;/***
;         call send_config_data( hndle, checkini( fsend_default, INI_DICTIONARY, dictionary_filename), 11, help_panel)
;         call send_config_data( hndle, checkini( fsend_default, INI_DICTIONARY, addenda_filename), 12, help_panel)
;***/
;         if fsend_default then
;            next = ''
;         else
;            next = dictionary_filename' (entry is read-only)'
;         endif
;         call send_config_data( hndle, next, 11, help_panel)
;         if fsend_default then
;            next = ''
;         else
;            next = addenda_filename' (entry is read-only)'
;         endif
;         call send_config_data( hndle, next, 12, help_panel)
;compile if CHECK_FOR_LEXAM
;      endif
;compile endif

   elseif page = 5 then  ----------------- Page 5 is autosave ---------
      if fsend_default = 2 then      -- 2: Use current values
         tempstr = .autosave
      else                           -- 0|1: Use values from .ini file or default values
         tempstr = checkini( fsend_default, INI_AUTOSAVE, DEFAULT_AUTOSAVE)
      endif
      call send_config_data( hndle, tempstr, 2, help_panel)
      call send_config_data( hndle, checkini( fsend_default, INI_AUTOSPATH, vAUTOSAVE_PATH, AUTOSAVE_PATH), 9, help_panel)

   elseif page = 6 then  ----------------- Page 6 is fonts ------------
                         ----------------- Text
      fontid = word( default_font 0 .font, fsend_default + 1)
      call send_config_data( hndle, queryfont(fontid)'.'trunc(.textcolor//16)'.'.textcolor%16, 24, help_panel)
                         ----------------- Status
      -- All fonts are saved now as psize'.'facename['.'attr], like OS/2 font specs
      if not fsend_default then      -- 0: Use values from .ini file
         KeyPath = '\NEPMD\User\Fonts\Status'
         tempstr = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      elseif fsend_default = 1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                           -- 2: Use current values
         tempstr = statfont
      endif
      tempstr = ConvertToEFont( tempstr)
      call send_config_data( hndle, tempstr'.'trunc(vstatuscolor//16)'.'vstatuscolor%16, 25, help_panel)
                         ----------------- Message
      if not fsend_default then      -- 0: Use values from .ini file
         KeyPath = '\NEPMD\User\Fonts\Message'
         tempstr = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      elseif fsend_default = 1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                           -- 2: Use current values
         tempstr = msgfont
      endif
      tempstr = ConvertToEFont( tempstr)
      call send_config_data( hndle, tempstr'.'trunc(vmessagecolor//16)'.'vmessagecolor%16, 26, help_panel)

   elseif page = 7 then  ----------------- Page 7 is enter keys -------
; Page 7 is not compatible with the configuration via STDKEYS.E or MYKEYS.E.
;      if fsend_default = 1 then      -- 1: Use default values
;compile if ENTER_ACTION = '' | ENTER_ACTION = 'ADDLINE'  -- The default
;         ek = \1
;compile elseif ENTER_ACTION = 'NEXTLINE'
;         ek = \2
;compile elseif ENTER_ACTION = 'ADDATEND'
;         ek = \3
;compile elseif ENTER_ACTION = 'DEPENDS'
;         ek = \4
;compile elseif ENTER_ACTION = 'DEPENDS+'
;         ek = \5
;compile elseif ENTER_ACTION = 'STREAM'
;         ek = \6
;compile endif
;compile if C_ENTER_ACTION = 'ADDLINE'
;         c_ek = \1
;compile elseif C_ENTER_ACTION = '' | C_ENTER_ACTION = 'NEXTLINE'  -- The default
;         c_ek = \2
;compile elseif C_ENTER_ACTION = 'ADDATEND'
;         c_ek = \3
;compile elseif C_ENTER_ACTION = 'DEPENDS'
;         c_ek = \4
;compile elseif C_ENTER_ACTION = 'DEPENDS+'
;         c_ek = \5
;compile elseif C_ENTER_ACTION = 'STREAM'
;         c_ek = \6
;compile endif
;         tempstr = ek || ek || c_ek || ek || ek || ek || c_ek || ek
;      else                           -- 0|2: Use values from .ini file or current values
;         tempstr = chr(enterkey) || chr(a_enterkey) || chr(c_enterkey) || chr(s_enterkey) || chr(padenterkey) || chr(a_padenterkey) || chr(c_padenterkey) || chr(s_padenterkey)
;      endif
;      call send_config_data(hndle, tempstr, 14, help_panel)

   elseif page = 8 then  ----------------- Page 8 is Frame controls ---
      tempstr = '1111010'  -- StatWnd, MsgWnd, hscroll, vscroll, extrawnd, bgbitmap, drop
      if not fsend_default then      -- 0: Use values from .ini file
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with statflg msgflg vscrollflg hscrollflg . . extraflg . . . . . . . new_bitmap . drop_style .
            -- OPTFLAGS:            1       2      3          4              7                      15           17
            tempstr = statflg || msgflg || hscrollflg || vscrollflg || extraflg || new_bitmap || drop_style
         endif
      elseif fsend_default = 2 then  -- 2: Use current values
         tempstr = queryframecontrol(1) || queryframecontrol(2) || queryframecontrol(16) ||
                   queryframecontrol(8) || queryframecontrol(32) || bitmap_present || queryframecontrol(8192)
      endif
      call send_config_data( hndle, tempstr, 15, help_panel)
      call send_config_data( hndle, checkini( fsend_default, INI_BITMAP, bm_filename, ''), 16, help_panel)

   elseif page = 9 then  ----------------- Page 9 is Misc. ------------
      -- dialog has longnames and profile bits exchanged, compared to OPTFLAGS
      tempstr = '0000100'  -- CUA marking, stream mode, Rexx profile, longnames, I-beam pointer, underline cursor, menu accelerators
      if not fsend_default then    -- 0: Use values from .ini file
         newcmd = queryprofile( app_hini, appname, INI_OPT2FLAGS)
         if newcmd <> '' then
            parse value newcmd with pointer_style cursor_shape .
         else
            pointer_style = (vEPM_POINTER = 2)
            cursor_shape = (cursordimensions = '-128.3 -128.-64') -- 1 if underline; 0 if vertical
         endif

         newcmd = queryprofile( app_hini, appname, INI_CUAACCEL)
         if newcmd<>'' then menu_accel = newcmd
                       else menu_accel = 0
         endif

         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with . . . . . . . markflg . streamflg longnames profile .
            -- OPTFLAGS:                          8         10        11        12
            tempstr = markflg || streamflg || profile || longnames ||
                      pointer_style || cursor_shape || menu_accel
         endif
      elseif fsend_default = 2 then  -- 2: Use current values
         tempstr = cua_marking_switch || stream_mode || rexx_profile || show_longnames ||
                   (vEPM_POINTER = 2) || (cursordimensions = '-128.3 -128.-64') || cua_menu_accel
      endif
      call send_config_data( hndle, tempstr, 18, help_panel)

   elseif page = 12 then  ---------------- Page 12 is Toolbar config --
      if fsend_default = 1           -- 1: Use default values
         then tempstr = ''
      else                           -- 0|2: Use values from .ini file or current values
         tempstr = queryprofile( app_hini, 'UCMenu', 'ConfigInfo')
      endif
      if tempstr = '' then
         --tempstr = \1'8'\1'32'\1'32'\1'8.Helv'\1'16777216'\1'16777216'\1  -- internal default if no entry in EPM.INI
         tempstr = \1'120'\1'32'\1'32'\1'9.WarpSans'\1'16777216'\1'16777216'\1  -- internal default if no entry in EPM.INI
      endif
      call send_config_data( hndle, tempstr, 22, help_panel)

   elseif page = 13 then  ---------------- Page 13 is Toolbar name & on/off
      active_toolbar = toolbar_loaded
      if active_toolbar = \1 then
         active_toolbar = ''
      endif
      send_toolbar = active_toolbar  -- current setting
      if fsend_default then
         if fsend_default = 1 then   -- 1: Use default values
            send_toolbar = ''        -- standard setting
         endif
      else
         next = GetDefaultToolbar()
         if next > '' then
            send_toolbar = next      -- default setting from ini
         endif
      endif
      call send_config_data( hndle, send_toolbar, 20, help_panel)
      call send_config_data( hndle, queryframecontrol(EFRAMEF_TOOLBAR), 21, help_panel)
      -- The list of toolbars and all the button actions on this page are not configurable
      -- with E commands.

   endif  -- page = 1

; ---------------------------------------------------------------------------
defproc send_config_data( hndle, strng, i, help_panel)
   strng = strng\0          -- null terminate (asciiz)
   call windowmessage( 1, hndle,
                       32,               -- WM_COMMAND - 0x0020
                       mpfrom2short( help_panel, i),
                       ltoa( offset(strng) || selector(strng), 10))

; ---------------------------------------------------------------------------
;defc enterkeys
;   universal enterkey, a_enterkey, c_enterkey, s_enterkey
;   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
;   universal appname, app_hini
;   parse arg perm enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey
;   if perm then
;      call setprofile( app_hini, appname, INI_ENTERKEYS,
;                       enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey)
;   endif

; ---------------------------------------------------------------------------
; fsend_default is a flag that says we're reverting to the default product options.
; defaultdata is the value to be used as the window default if INIKEY isn't found
; in the EPM.INI; it will also be used as the product default if no fourth parameter
; is given.
defproc CheckIni( fsend_default, inikey, defaultdata)
   universal appname, app_hini
   if fsend_default then
      if fsend_default = 1 & arg() > 3 then
         return arg(4)
      endif
      return defaultdata
   endif
   inidata = queryprofile( app_hini, appname, inikey)
   if inidata <> '' then
      return inidata
   endif
   return defaultdata

; ---------------------------------------------------------------------------
; 5.21 lets you apply without saving, so we add an optional 3rd parameter.
; If omitted, assume the old way - save.  If present, only save if 1.
defproc SetIni( inikey, inidata)
   universal appname, app_hini
   if arg() >= 3 then
      perm = arg(3)
   else
      perm = 1
   endif
   if perm then
      call setprofile( app_hini, appname, inikey, inidata)
   endif
   return inidata

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: setconfig       syntax:   setconfig configid  newvalue   ³
³                                                                            ³
³ what does it do : The function is called by the EPM CONFIG dialog box to   ³
³                   return values set by the user.                           ³
³                                                                            ³
³                                                                            ³
³ who and when    : Jerry C. & LAM  7/20/89                                  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
; This command executes the opposite if its name. It queries settings to
; fill the settings dialog controls.
defc SetConfig
;   universal addenda_filename
;   universal dictionary_filename
;   universal vTEMP_FILENAME, vTEMP_PATH
;   universal vAUTOSAVE_PATH
   universal vdefault_tabs, vdefault_margins, vdefault_autosave
   universal appname, app_hini
   universal vmessagecolor, vstatuscolor
   universal bm_filename
   universal bitmap_present
   universal toolbar_loaded
   universal stream_mode
   universal default_stream_mode
   universal show_longnames
   universal rexx_profile
   universal cua_marking_switch
   universal tab_key
   universal default_tab_key
   universal cua_menu_accel
   universal vepm_pointer, cursordimensions

   ChangeFileSettings = CONFIGDLG_CHANGE_FILE_SETTINGS  -- standard was 1
   AskReflow          = CONFIGDLG_ASK_REFLOW
   --dprintf( 'SETCONFIG', arg(1))

   parse value arg(1) with configid perm newcmd

   'RestoreEpmIniPath'  -- The toolbar notebook page queries the EPMIniPath value itself,
                        -- therefore it cannot be restored by defc ConfigDlg itself.
                        -- SetConfig is *always* called by the config dialog.

   if     configid = 1 then
      if ChangeFileSettings = 1 then                      -- change current file's setting
         if .margins <> newcmd then
            .margins = newcmd
            'postme refreshinfoline MARGINS'
            if AskReflow then
               'postme maybe_reflow_all'
            endif
         endif
      elseif ChangeFileSettings = 'REFRESHDEFAULT' then   -- change setting of all files in
         'RingRefreshSetting DEFAULT SetMargins 'newcmd   -- the ring with default settings
      endif
      vdefault_margins = setini( INI_MARGINS, newcmd, perm)
      'RefreshInfoLine MARGINS'

   elseif configid = 2 then
      .autosave = setini( INI_AUTOSAVE, newcmd, perm)
      vdefault_autosave = newcmd

   elseif configid = 3 then
      if ChangeFileSettings = 1 then                      -- change current file's setting
         if .tabs <> newcmd then
            .tabs = newcmd
            'postme refreshinfoline TABS'
         endif
      elseif ChangeFileSettings = 'REFRESHDEFAULT' then   -- change setting of all files in
         'RingRefreshSetting DEFAULT SetTabs 'newcmd      -- the ring with default settings
      endif
      vdefault_tabs = setini( INI_TABS, newcmd, perm)
      'RefreshInfoLine TABS'

   elseif configid = 4 & newcmd <> .textcolor then
      .textcolor = newcmd

      if perm then
         'SaveColor TEXT'
      endif

   elseif configid = 5 & newcmd <> .markcolor then
      .markcolor = newcmd

      if perm then
         'SaveColor MARK'
      endif

   elseif configid = 6 & newcmd <> vstatuscolor then
      vstatuscolor = newcmd
      'SetStatusline'

      if perm then
         'SaveColor STATUS'
      endif

   elseif configid = 7 & newcmd <> vmessagecolor then
      vmessagecolor = newcmd
      'SetMessageline'

      if perm then
         'SaveColor MESSAGE'
      endif

   elseif configid = 9 then
;      if newcmd <> '' & rightstr( newcmd, 1) <> '\' then
;         newcmd = newcmd'\'
;      endif
;      if rightstr( newcmd, 2) = '\\' then             -- Temp fix for dialog bug
;         newcmd = leftstr( newcmd, length(newcmd) - 1)
;      endif
;      vautosave_path = setini( INI_AUTOSPATH, newcmd, perm)

   elseif configid = 10 then
;      if newcmd <> '' & rightstr( newcmd, 1) <> '\' then
;         newcmd = newcmd'\'
;      endif
;      if rightstr( newcmd, 2) = '\\' then             -- Temp fix for dialog bug
;         newcmd = leftstr( newcmd, length(newcmd) - 1)
;      endif
;      if upcase(leftstr( vtemp_filename, length(vtemp_path))) = upcase(vtemp_path) then
;         vtemp_filename = newcmd||substr( vtemp_filename, length(vtemp_path) + 1)
;      elseif not verify( vtemp_filename, ':\', 'M') then   -- if not fully qualified
;         vtemp_filename = newcmd||vtemp_filename
;      endif
;      vtemp_path = setini( INI_TEMPPATH, newcmd, perm)

   elseif configid = 11 then
;      dictionary_filename = setini( INI_DICTIONARY, newcmd, perm)

   elseif configid = 12 then
;      addenda_filename = setini( INI_ADDENDA, newcmd, perm)

   elseif configid = 15 then
      parse value newcmd with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7 drop_style 8
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
      'toggleframe 32' extraflg
      'toggleframe 8192' drop_style

      if bitmap_present <> new_bitmap then
         'toggle_bitmap'
         if bitmap_present then
            bm_filename = ''  -- Will be reset; want to ensure it's reloaded.
         endif
      endif

      if perm then
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with . . . . w1 w2 . w3 w4 w5 w6 w7 w8 w9 . w10 . rest
            -- OPTFLAGS:                    5  6    8  9  10 11 12 13 14   16
            call setprofile( app_hini, appname, INI_OPTFLAGS,
               queryframecontrol(1)    || ' ' ||
               queryframecontrol(2)    || ' ' ||
               queryframecontrol(8)    || ' ' ||
               queryframecontrol(16)   || ' ' ||
               w1                      || ' ' ||
               w2                      || ' ' ||
               queryframecontrol(32)   || ' ' ||
               w3                      || ' ' ||
               w4                      || ' ' ||
               w5                      || ' ' ||
               w6                      || ' ' ||
               w7                      || ' ' ||
               w8                      || ' ' ||
               w9                      || ' ' ||
               bitmap_present          || ' ' ||
               w10                     || ' ' ||
               queryframecontrol(8192) || ' ' ||
               rest)
         else
            'SaveOptions OptOnly'
         endif
      endif

   elseif configid = 16 then
      if bm_filename <> newcmd then
         if bitmap_present then
            if bm_filename = '' then  -- Need to turn off & back on to get default bitmap
               'toggle_bitmap'
               'toggle_bitmap'
            else
               'load_dt_bitmap' newcmd
            endif
         endif
      endif

      if perm then
         call setprofile( app_hini, appname, INI_BITMAP, bm_filename)
      endif

   elseif configid = 18 then
      parse value newcmd with markflg 2 streamflg 3 profile 4 longnames 5 pointer_style 6 cursor_shape 7 menu_accel 8

      vepm_pointer = 1 + pointer_style
      mouse_setpointer vepm_pointer

compile if not defined(my_CURSORDIMENSIONS)
      'cursor_style' (cursor_shape + 1)
compile endif

      if markflg <> cua_marking_switch then
         'CUA_mark_toggle'
         'postme RefreshInfoline MARKINGMODE' -- postme required? CUA_mark_toggle sets infoline already!
      endif

      if streamflg <> default_stream_mode then
         if ChangeFileSettings = 1 then                      -- change current file's setting
            'stream_toggle'  -- old definition
            stream_mode = streamflg
            'postme RefreshInfoline STREAMMODE'
         elseif ChangeFileSettings = 'REFRESHDEFAULT' then
            next = GetAVar('streammode.'fid)  -- query file setting
            if next = 'DEFAULT' | next = '' then  -- unset if tabkey was not changed by any modeexecute
               'stream_toggle'
               stream_mode = streamflg
               'postme RefreshInfoLine STREAMMODE'
            endif
         endif
         default_stream_mode = streamflg
      endif

      if longnames <> '' then
         show_longnames = longnames
      endif

      if PROFILE <> '' then
         rexx_profile = PROFILE
      endif

      if cua_menu_accel <> menu_accel then
         'accel_toggle'
      endif

      if perm then
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with w1 w2 w3 w4 w5 w6 w7 . w8 . . . rest
            -- OPTFLAGS:            1  2  3  4  5  6  7    9
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             w1        || ' ' ||
                             w2        || ' ' ||
                             w3        || ' ' ||
                             w4        || ' ' ||
                             w5        || ' ' ||
                             w6        || ' ' ||
                             w7        || ' ' ||
                             markflg   || ' ' ||
                             w8        || ' ' ||
                             streamflg || ' ' ||
                             longnames || ' ' ||
                             profile   || ' ' ||
                             rest)
         else
            'SaveOptions OptOnly'
         endif
         call setprofile( app_hini, appname, INI_OPT2FLAGS, pointer_style cursor_shape)
         call setprofile( app_hini, appname, INI_CUAACCEL, menu_accel)
      endif

   elseif configid = 19 then
      on = newcmd
      if on <> default_tab_key then
         if ChangeFileSettings = 1 then                      -- change current file's setting
            tab_key = on -- old definition
            'postme RefreshInfoline TABKEY'
         elseif ChangeFileSettings = 'REFRESHDEFAULT' then
            getfileid fid
            next = GetAVar('tabkey.'fid)  -- query file setting
            if next = 'DEFAULT' | next = '' then  -- unset if tabkey was not changed by any modeexecute
               tab_key = on
               'postme RefreshInfoLine TABKEY'
            endif
         endif
         default_tab_key = on
      endif

      if perm then
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            -- OPTFLAGS:   14
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             subword( newcmd, 1, 13) on subword( newcmd, 15))
         else
            'SaveOptions OptOnly'
         endif
      endif

   elseif configid = 20 then
      if newcmd = '' then  -- Null string; use compiled-in toolbar
         if toolbar_loaded <> \1 then
            --'loaddefaulttoolbar'
            'LoadStandardToolbar'
         endif
      elseif newcmd <> toolbar_loaded then
         call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                             5916,
                             app_hini, put_in_buffer(newcmd))
         toolbar_loaded = newcmd
      endif

      if perm then
         --call setprofile( app_hini, appname, INI_DEF_TOOLBAR, newcmd)
         call SetDefaultToolbar()
      endif

   elseif configid = 21 then
      if newcmd <> queryframecontrol(EFRAMEF_TOOLBAR) then
         'toggleframe' EFRAMEF_TOOLBAR newcmd
      endif

      if perm then
         temp = queryprofile( app_hini, appname, INI_OPTFLAGS)
         -- OPTFLAGS:   16
         if temp <> '' then
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             subword( temp, 1, 15) newcmd subword( temp, 17))
         else
            'SaveOptions OptOnly'  -- Possible synch problem?
         endif
      endif

   elseif configid = 22 then
      call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                          5921,
                          put_in_buffer(newcmd), 0)
compile if 0
      parse value newcmd with \1 style \1 cx \1 cy \1 font \1 color \1 itemcolor \1
      if perm then
         call setprofile( app_hini, 'UCMenu', 'Style', style)
         call setprofile( app_hini, 'UCMenu', 'Cx', cx)
         call setprofile( app_hini, 'UCMenu', 'Cy', cy)
         call setprofile( app_hini, 'UCMenu', 'Font', font)
         call setprofile( app_hini, 'UCMenu', 'Color', color)
         call setprofile( app_hini, 'UCMenu', 'ItemColor', itemcolor)
      endif
compile else
      if perm then
         call setprofile( app_hini, 'UCMenu', 'ConfigInfo', newcmd)
      endif
compile endif

   elseif configid = 0 then
; This doesn't work. "SetConfig 0" is always executed when the dialog is
; closed, after all other SetConfig calls and always just with "0" as
; parameter, without perm.
;      if perm then
;         'SaveColor'
;      endif
      --dprintf('setconfig', 'configid = 0')
; In standard EPM the font was always saved:
;       call setprofile( app_hini, appname, INI_STUFF,
;                        .textcolor .markcolor vstatuscolor vmessagecolor)
      'SaveFont'
   endif

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: initconfig                                               ³
³                                                                            ³
³ what does it do : Set universal variables according to the values          ³
³                   previously saved in the EPM.INI file.                    ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
; The menu defs like togglecontrol, toggleframe, ... must be already defined
; before initconfig is executed.
defc InitConfig
   universal addenda_filename
   universal dictionary_filename
   universal vtemp_filename, vtemp_path
;   universal vautosave_path
   universal appname, app_hini, bitmap_present, optflag_extrastuff
   universal vdefault_tabs, vdefault_margins, vdefault_autosave
   universal statfont, msgfont, bm_filename
   universal default_font
   universal cua_marking_switch
   universal menu_prompt
compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined(my_SAVEPATH)
   universal savepath
compile endif
   universal vmessagecolor, vstatuscolor
   universal vdesktopcolor
;   universal enterkey, a_enterkey, c_enterkey, s_enterkey
;   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal stream_mode
   universal default_stream_mode
   universal ring_enabled
   universal show_longnames
   universal rexx_profile
;   universal escape_key  -- Disabled
   universal tab_key
   universal default_tab_key
   universal vepm_pointer, cursordimensions
   universal appname
   universal stack_cmds
   universal cua_menu_accel
compile if CHECK_FOR_LEXAM
   universal lexam_is_available
compile endif

   next = queryprofile( app_hini, appname, INI_MARGINS)
   if next = '' then
      next = '1' MAXMARGIN '1'
      call setprofile( app_hini, appname, INI_MARGINS, next)
   endif
   .margins = next
   vdefault_margins = next

   next = queryprofile( app_hini, appname, INI_AUTOSAVE)
   if next = '' then
      next = 100
      call setprofile( app_hini, appname, INI_AUTOSAVE, next)
   endif
   .autosave = next
   vdefault_autosave = next

   next = queryprofile( app_hini, appname, INI_TABS)
   if next = '' then
      next = 8
      call setprofile( app_hini, appname, INI_TABS, next)
   endif
   .tabs = next
   vdefault_tabs = next

;   next = queryprofile( app_hini, appname, INI_TEMPPATH)
   -- Always redetermine vtemp_path on startup, don't simply use previous
   -- ini key, because that may have become not valid if TMP was changed.
   next = ''
;   if next = '' then
      do while next = ''
         next = Get_Env( 'TMP')
         if next <> '' then
            leave
         endif
         next = Get_Env( 'TEMP')
         if next <> '' then
            leave
         endif
         next = directory()
         leave
      enddo
      if rightstr( next, 1) <> '\' then
         next = next'\'          -- Must end with a backslash.
      endif
;      call setprofile( app_hini, appname, INI_TEMPPATH, next)
;   endif
   vtemp_path = next
;   if rightstr( vtemp_path, 1) <> '\' then
;      vtemp_path = vtemp_path'\'          -- Must end with a backslash.
;   endif
   if not verify( vtemp_filename, ':\', 'M') then   -- if not fully qualified
      vtemp_filename = vtemp_path||vtemp_filename
   endif

;   next = queryprofile( app_hini, appname, INI_AUTOSPATH)
;   if next = '' then
;      next = vtemp_path'autosave'
;      call MakeTree( next)
;      if rightstr( next, 1) <> '\' then
;         next = next'\'          -- Must end with a backslash.
;      endif
;      call setprofile( app_hini, appname, INI_AUTOSPATH, next)
;   endif
;   vautosave_path = next
;   if rightstr( vautosave_path, 1) <> '\' then
;      vautosave_path = vautosave_path'\'  -- Must end with a backslash.
;   endif
;compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined( my_SAVEPATH)
;   savepath = vautosave_path
;compile endif

;   next = queryprofile( app_hini, appname, INI_DICTIONARY)
;   if next then
;      dictionary_filename = next
;   endif
;
;   next = queryprofile( app_hini, appname, INI_ADDENDA)
;   if next then
;      addenda_filename = next
;   endif

   -- Options from Option pulldown
   next = queryprofile( app_hini, appname, INI_OPTFLAGS)
   if words( next) < 17 then
      next = '1 1 1 1 1 1 0 0 1 1 1 1 1 0 0 1 0 '
      --      1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8
      --  1 Status line
      --  2 Message line
      --  3 Vertical scrollbar
      --  4 Horizontal scrollbar
      --  5 File icon (unused in EPM 6)
      --  6 Rotate buttons
      --  7 Info at top
      --  8 CUA marking
      --  9 Menu item hints
      -- 10 Stream mode
      -- 11 Show .LONGNAME in titletext
      -- 12 REXX profile
      -- 13 Esc opens commandline
      -- 14 Tabkey
      -- 15 Background bitmap
      -- 16 Toolbar
      -- 17 Drop style (0 = edit, 1 = import)
      -- 18 ?
      -- Several commands now change only their specific bit instead of saving
      -- the entire string. Therefore the other bits must exist to change the
      -- correct bit/word.
      call setprofile( app_hini, appname, INI_OPTFLAGS, next)
   endif
   parse value next with statflg msgflg vscrollflg hscrollflg fileiconflg rotflg extraflg markflg menu_prompt streamflg longnames profile escapekey tabkey bm_present toolbar_present drop_style optflag_extrastuff
   'toggleframe 1' statflg
   'toggleframe 2' msgflg
   'toggleframe 8' vscrollflg
   'toggleframe 16' hscrollflg
   if ring_enabled then
      'toggleframe 4' rotflg
   endif
   'toggleframe 32' extraflg
   'toggleframe 8192' drop_style

   cua_marking_switch = 0
   if markflg <> '' then
      if markflg <> cua_marking_switch then
         'CUA_mark_toggle'
      endif
   endif

   default_stream_mode = 1
   if streamflg <> '' then
      if streamflg <> default_stream_mode then
         if isadefc('toggle_default_stream') then
            'toggle_default_stream'  -- requires newmenu
         else
            'stream_toggle'  -- old definition
         endif
      endif
   endif
   stream_mode = default_stream_mode

   show_longnames = 1
   if longnames <> '' then
      show_longnames = longnames
   endif

   rexx_profile = 1
   if profile <> '' then
      rexx_profile = profile
   endif

/*
-- Disabled; should remain on; can still be configured via PROFILE.ERX:
-- 'escapekey 0'
   escape_key = 1
   if escapekey <> '' then
      escape_key = escapekey
   endif
*/

   default_tab_key = 0
   if tabkey <> '' then
      default_tab_key = tabkey
   endif
   tab_key = default_tab_key

   bm_filename = queryprofile( app_hini, appname, INI_BITMAP)
   if next <> '' then
      if bm_present then
         'load_dt_bitmap' bm_filename
      endif
   endif

;   next = queryprofile( app_hini, appname, INI_ENTERKEYS)
;   if next <> '' then
;      parse value next with enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey .
;   endif

   parse value queryprofile( app_hini, appname, INI_OPT2FLAGS) with pointer_style cursor_shape .
--------> todo?
   if pointer_style <> '' then
      -- Just set the universal var here
      vepm_pointer = 1 + pointer_style
      -- The pointer is set now by ProcessAfterLoad2
      --mouse_setpointer vepm_pointer
   endif
compile if not defined(my_CURSORDIMENSIONS)
   if cursor_shape <> '' then
      'cursor_style' (cursor_shape + 1)
   endif
compile endif -- not defined(my_CURSORDIMENSIONS)

   -- Maybe correct ini entry, returned value not used
   Setup = GetToolbarSetup()

   if toolbar_present then
      'ReloadToolbar'
   endif

; Moved from MENUACEL.E (file deleted now, formerly included by definit)
compile if defined(my_STACK_CMDS)
   stack_cmds = my_STACK_CMDS
compile else
   --stack_cmds = 0  -- changed by aschn
   stack_cmds = 1
compile endif
   next = queryprofile( app_hini, appname, INI_STACKCMDS)
--------> todo?
   if next <> '' then
      stack_cmds = next
   endif

compile if defined(my_CUA_MENU_ACCEL)
   cua_menu_accel = my_CUA_MENU_ACCEL
compile else
   cua_menu_accel = 0
compile endif
   next = queryprofile( app_hini, appname, INI_CUAACCEL)
--------> todo?
   if next <> '' then
      cua_menu_accel = next
   endif

compile if CHECK_FOR_LEXAM
   LEXAM_is_available = (lexam(-1) <> '')
compile endif  -- CHECK_FOR_LEXAM

;   KeyPath = '\NEPMD\User\Reflow\TwoSpaces'
;   twospaces = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
; The following makes EPM crash while opening the 3rd ring with 90 files
; (universals were added). Therefore this was put to a separate defc:
;   KeyPath = '\NEPMD\User\Edit\DefaultOptions'
;   default_edit_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)
;   KeyPath = '\NEPMD\User\Save\DefaultOptions'
;   default_save_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)
;   KeyPath = '\NEPMD\User\Search\DefaultOptions'
;   default_search_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   'initconfig2'  -- this doesn't make problems

   'loaddefaultmenu'
   'loadaccel'

; ---------------------------------------------------------------------------
; These settings are not changed by the standard settings dialog.
; They were set to the values of consts previously.
defc initconfig2
   universal nepmd_hini
   universal twospaces
   universal default_edit_options
   universal default_search_options
   universal default_save_options
   universal expand_on
   universal matchtab_on
   universal join_after_wrap
   universal vdesktopcolor
   universal vmessagecolor
   universal vstatuscolor
   universal vmodifiedstatuscolor
   universal default_font  -- a number (= .font), not a font spec
   universal msgfont
   universal statfont
   universal vtemp_path
   universal vautosave_path

   KeyPath = '\NEPMD\User\AutoSave\Directory'
   Dir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Dir = '' then
      Dir = vtemp_path'nepmd\autosave'
   endif
   -- Trailing backslash required
   if rightstr( Dir, 1) <> '\' then
      vautosave_path = Dir'\'
   else
      vautosave_path = Dir
   endif
compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined( my_SAVEPATH)
   savepath = vautosave_path
compile endif
   rcx = MakeTree( Dir)

   KeyPath = '\NEPMD\User\Backup\Directory'
   Dir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Dir <> '=' then
      if Dir = '' then
         Dir = vtemp_path'nepmd\backup'
      endif
      rcx = MakeTree( Dir)
   endif

   KeyPath = '\NEPMD\User\Reflow\TwoSpaces'
   twospaces = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Edit\DefaultOptions'
   default_edit_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Save\DefaultOptions'
   default_save_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Search\DefaultOptions'
   default_search_options = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\SyntaxExpansion'
   expand_on = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Keys\Tab\MatchTab'
   matchtab_on = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Keys\Tab\TabGlyph'
   on =  NepmdQueryConfigValue( nepmd_hini, KeyPath)
   call tabglyph(on)

   KeyPath = '\NEPMD\User\Reflow\JoinAfterWrap'
   join_after_wrap = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   KeyPath = '\NEPMD\User\Colors'
   .textcolor           = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Text')
   .markcolor           = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Mark')
   vdesktopcolor        = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Background')
   vmessagecolor        = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Message')
   vstatuscolor         = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Status')
   vmodifiedstatuscolor = NepmdQueryConfigValue( nepmd_hini, KeyPath'\ModifiedStatus')
   call windowmessage( 0,  getpminfo(EPMINFO_EDITCLIENT),  -- post
                       5497,      -- EPM_EDIT_SETDTCOLOR
                       vdesktopcolor,
                       0)
   'SetMessageline'   -- update the color
   --'SetStatusline'  -- update the color, not required, done by RefreshStatusLine

   KeyPath = '\NEPMD\User\Fonts'
   next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Text')
   next = ConvertToEFont( next)
   parse value next with fontname'.'fontsize'.'fontsel
   .font = registerfont( fontname, fontsize, fontsel)
   default_font = .font

   -- All fonts are saved now as psize'.'facename['.'attr], like OS/2 font specs
   msgfont = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Message')
   parse value ConvertToEFont( msgfont) with fontname'.'fontsize'.'fontsel
   --parse value msgfont with fontname'.'fontsize'.'fontsel
   'SetStatFace' getpminfo( EPMINFO_EDITMSGHWND) fontname
   'SetStatPtsize' getpminfo( EPMINFO_EDITMSGHWND) fontsize

   statfont = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Status')
   parse value ConvertToEFont( statfont)  with fontname'.'fontsize'.'fontsel
   'SetStatFace' getpminfo( EPMINFO_EDITSTATUSHWND) fontname
   'SetStatPtsize' getpminfo( EPMINFO_EDITSTATUSHWND) fontsize

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: saveoptions                                              ³
³                                                                            ³
³ what does it do : save state of items on options pull down in os2ini       ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveOptions
   universal appname, app_hini, bitmap_present, optflag_extrastuff, toolbar_present
   universal statfont, msgfont
   universal bm_filename
   universal menu_prompt
   universal ring_enabled
   universal stack_cmds
   universal stream_mode
   universal show_longnames
   universal rexx_profile
   universal escape_key
   universal tab_key
   universal cua_menu_accel
   universal cua_marking_switch
   --dprintf( 'SaveOptions', 'arg(1) = ['arg(1)']')

  -- Save values in key EPM -> OPTFLAGS
   call setprofile( app_hini, appname, INI_OPTFLAGS,
                    queryframecontrol(1)               || ' ' ||  --  1 Status line
                    queryframecontrol(2)               || ' ' ||  --  2 Message line
                    queryframecontrol(8)               || ' ' ||  --  3 Vertical scrollbar
                    queryframecontrol(16)              || ' ' ||  --  4 Horizontal scrollbar
                    queryframecontrol(64)              || ' ' ||  --  5 File icon (unused in EPM 6)
                    queryframecontrol(4)               || ' ' ||  --  6 Rotate buttons
                    queryframecontrol(32)              || ' ' ||  --  7 Info at top
                    cua_marking_switch                 || ' ' ||  --  8 CUA marking
                    menu_prompt                        || ' ' ||  --  9 Menu item hints
                    stream_mode                        || ' ' ||  -- 10 Stream mode
                    show_longnames                     || ' ' ||  -- 11 Show .LONGNAME in titletext
                    rexx_profile                       || ' ' ||  -- 12 REXX profile
                    escape_key                         || ' ' ||  -- 13 Esc opens commandline
                    tab_key                            || ' ' ||  -- 14 Tabkey
                    bitmap_present                     || ' ' ||  -- 15 Background bitmap
                    queryframecontrol(EFRAMEF_TOOLBAR) || ' ' ||  -- 16 Toolbar
                    queryframecontrol(8192)            || ' ' ||  -- 17 Drop style (0 = edit, 1 = import)
                    optflag_extrastuff)                           -- 18 ?

   if arg(1) = 'OptOnly' then  -- don't process the following
      return
   endif
   call setprofile( app_hini, appname, INI_RINGENABLED, ring_enabled)
   call setprofile( app_hini, appname, INI_STACKCMDS,   stack_cmds)
   call setprofile( app_hini, appname, INI_CUAACCEL,    cua_menu_accel)
   if bm_filename <> '' then
      call setprofile( app_hini, appname, INI_BITMAP,   bm_filename)
   endif
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       62, 0, 0)               -- x'003E' = WM_SAVEAPPLICATION
compile if SUPPORT_USER_EXITS
   if isadefproc('saveoptions_exit') then
      call saveoptions_exit()
   endif
compile endif

; ---------------------------------------------------------------------------
; Internally called when a font is dropped on a window, after SetPresParam.
; Then the standard args are 'EDIT' | 'MSG' | 'STAT'. They are replaced
; with words of KeyList. If no word of KeyList is specified as arg, then all
; fonts are saved.
; Called as well by the config dialog on close, if the "Save settings"
; checkbox was checked.
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savefont                                                 ³
³                                                                            ³
³ what does it do : save fonts in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveFont
   --universal appname, app_hini, bitmap_present, optflag_extrastuff
   universal nepmd_hini
   universal msgfont
   universal statfont
   universal default_font
   --dprintf( 'SaveFont', 'arg(1) = ['arg(1)']')
   -- arg(1) = 'EDIT' | 'MSG' | 'STAT'

   KeyList = 'Text Message Status'
   -- Font specs have spaces. Therefore they are separated with \1
   ValList = ConvertToOs2Font( queryfont(.font))''\1''msgfont''\1''statfont''\1
   args = upcase( arg(1))

   -- Replace EDIT, MSG, STAT
   new = ''
   do w = 1 to words( args)
      next = word( args, w)
      if next = 'EDIT' then
         new = new 'TEXT'
      elseif next = 'MSG' then
         new = new 'MESSAGE'
      elseif next = 'STAT' then
         new = new 'STATUS'
      else
         wp2 = wordpos( next, upcase( KeyList))
         if wp2 then
            new = new next
         endif
      endif
   enddo
   args = strip( new)

   if args = '' then
      args = upcase( KeyList)
   endif

   KeyPath = '\NEPMD\User\Fonts'
   rest = args
   do w = 1 to words( args)
      next = word( args, w)
      wp = wordpos( next, upcase( KeyList))
      if wp then
         Key = word( KeyList, wp)
         rest = ValList
         do i = 1 to wp
            parse value rest with Val \1 rest
         enddo
         call NepmdWriteConfigValue( nepmd_hini, KeyPath'\'Key, Val)
         --dprintf( 'SAVEFONT', KeyPath'\'word( KeyList, wp)' = 'Val)
         -- Set default_font to take change immediately for the next loaded files
         if Key = 'Text' then
            default_font = .font
         endif
      endif
   enddo

; ---------------------------------------------------------------------------
; Internally called when a color is dropped on a window, after SetPresParam.
; Then the standard args are 'EDIT' | 'MSG' | 'STAT'. They are not precise
; enough and any occurence of it causes now ignoration of that call.
; They are replaced by calls of SaveColor from SetPresParam. If no word of
; KeyList is specified as arg, then all colors are saved.
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savecolor                                                ³
³                                                                            ³
³ what does it do : save color in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveColor
   --universal appname, app_hini
   universal nepmd_hini
   universal vdesktopcolor
   universal vmessagecolor
   universal vstatuscolor
   universal vmodifiedstatuscolor
   --dprintf( 'SAVECOLOR', 'arg(1) = ['arg(1)']')

   IgnoreList = 'EDIT MSG STAT'
   KeyList = 'Text Mark Background Message Status ModifiedStatus'
   ValList = .textcolor .markcolor vdesktopcolor vmessagecolor vstatuscolor vmodifiedstatuscolor
   args = upcase( arg(1))

   -- Ignore EDIT, MSG, STAT (and unknown words), since they are not precise enough
   new = ''
   do w = 1 to words( args)
      next = word( args, w)
      wp1 = wordpos( next, IgnoreList)
      if wp1 then
         return  -- don't process this, since SetPresParam calls SaveColor itself
      endif
      wp2 = wordpos( next, upcase( KeyList))
      if wp2 then
         new = new next
      endif
   enddo
   args = strip( new)

   -- Default args if no words of KeyList specified
   if args = '' then
      args = upcase( KeyList)
   endif

   KeyPath = '\NEPMD\User\Colors'
   rest = args
   do w = 1 to words( args)
      next = word( args, w)
      wp = wordpos( next, upcase( KeyList))
      if wp then
         call NepmdWriteConfigValue( nepmd_hini, KeyPath'\'word( KeyList, wp),
                                     word( ValList, wp))
         --dprintf( 'SAVECOLOR', KeyPath'\'word( KeyList, wp)' = 'word( ValList, wp))
      endif
   enddo

; ---------------------------------------------------------------------------
; Never executed?
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savewindowsize                                           ³
³                                                                            ³
³ what does it do : save size of the edit window in the ini file             ³
³ who did it&when : GLS 09/15/93                                             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveWindowSize
   --dprintf( 'SaveWindowSize', 'arg(1) = ['arg(1)']')
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       62,                     -- x'003E' = WM_SAVEAPPLICATION
                       0, 0)

; ---------------------------------------------------------------------------
defc DefaultMargins
   universal app_hini
   universal vDEFAULT_MARGINS
   -- if executed with an arg
   arg1 = arg(1)
   if arg1 <> '' then
      parse value arg1 with leftm rightm parm
      if rightm = '' then  -- if only 1 arg specified
         rightm = arg1
         leftm  = 1
      endif
      if parm = '' then    -- if parmargin not specified
         parm = leftm
      endif
      NewMargins = leftm rightm parm
      -- change setting of all files in the ring with default settings
      'RingRefreshSetting DEFAULT SetMargins 'NewMargins
      vDEFAULT_MARGINS = NewMargins
      call setprofile( app_hini, 'EPM', INI_MARGINS, NewMargins)
      'RefreshInfoLine MARGINS'
      return
   endif
   -- else open entrybox
   Title   = 'Configure default margins'
   Text    = 'Enter leftma rightma parma (default: 1 1599 1):'
   IniValue = queryprofile( app_hini, 'EPM', INI_MARGINS)
   IniValue = strip(IniValue)
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/'CANCEL__MSG,  -- max. 4 buttons
                         IniValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 then
      'DefaultMargins' NewValue
      return
   elseif Button = \2 then
      'DefaultMargins 1 1599 1'
      return
   elseif Button = \3 then
      return
   endif

; ---------------------------------------------------------------------------
defc DefaultTabs
   universal app_hini
   universal vDEFAULT_TABS
   -- if executed with a num as arg
   arg1 = arg(1)
   if arg1 <> '' & isnum(arg1) then
      NewTabs = arg1
      -- change setting of all files in the ring with default settings
      'RingRefreshSetting DEFAULT SetTabs 'NewTabs
      vDEFAULT_TABS = NewTabs
      call setprofile( app_hini, 'EPM', INI_TABS, NewTabs)
      'RefreshInfoLine TABS'
      return
   endif
   -- else open entrybox
   Title   = 'Configure default tabs'
   Text    = 'Enter a single number for a fixed tab interval, or a list of explicit tab positions (default: 8):'
   IniValue = queryprofile( app_hini, 'EPM', INI_TABS)
   IniValue = strip(IniValue)
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/'CANCEL__MSG,  -- max. 4 buttons
                         IniValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 then
      'DefaultTabs' NewValue
      return
   elseif Button = \2 then
      'DefaultTabs 8'
      return
   elseif Button = \3 then
      return
   endif

; Used by File properties menu:
; ---------------------------------------------------------------------------
defproc GetHighlight
   on = ( windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                         5505,          -- EPM_EDIT_KW_QUERYPARSE
                         0,
                         0) <> 0)
   return on

; ---------------------------------------------------------------------------
defproc GetCuaMark
   getfileid fid
   on = (GetAVar( 'cuamark.'fid) = 1)
   return on

; ---------------------------------------------------------------------------
defproc GetStreamMode
   getfileid fid
   on = (GetAVar( 'streammode.'fid) = 1)
   return on

; ---------------------------------------------------------------------------
defproc GetExpand
   getfileid fid
   on = (GetAVar( 'expand.'fid) = 1)
   return on

; ---------------------------------------------------------------------------
defproc GetTabkey
   universal tab_key
   getfileid fid
   on = (GetAVar( 'tabkey.'fid) = 1)
/*
   if on = '' then
      on = tab_key
      call SetAVar( 'tabkey.'fid, on)
   endif
*/
   return on

; ---------------------------------------------------------------------------
defproc GetMatchtab
   getfileid fid
   on = (GetAVar( 'matchtab.'fid) = 1)
   return on

; ---------------------------------------------------------------------------
; This command is exectued once after install if JustInstalled = 1.
defc DelOldRegKeys
   universal nepmd_hini
   KeyPath = '\NEPMD\User\LastStuff\LastFindDefButton'
   call NepmdDeleteConfigValue( nepmd_hini, KeyPath)
   KeyPath = '\NEPMD\User\LastStuff\LastSearchArgs'
   call NepmdDeleteConfigValue( nepmd_hini, KeyPath)
   KeyPath = '\NEPMD\User\LastStuff\LastChangeArgs'
   call NepmdDeleteConfigValue( nepmd_hini, KeyPath)

