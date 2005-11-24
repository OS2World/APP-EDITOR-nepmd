/****************************** Module Header *******************************
*
* Module Name: config.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: config.e,v 1.7 2005-11-24 19:22:31 aschn Exp $
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

; Configuration and ini file definitions. Thats's the 2nd part of
; initialization, concerning with settings queried from EPM.INI.
;
; While some universals are set at definit, defc initconfig is called at
; defmain. It's quite important for performance and stability, at which time
; during the start all the init stuff is processed. This applies not only to
; getting values from the ini, but also to the creation of menu and making
; the window visible.
; Moved from STDCTRL.E.

; Removed consts:
; INCLUDE_MENU_SUPPORT, INCLUDE_STD_MENUS, WANT_DYNAMIC_PROMPTS,
; BLOCK_ACTIONBAR_ACCELERATORS, WANT_STACK_CMDS, RING_OPTIONAL,
; WANT_STREAM_MODE, WANT_TOOLBAR, SPELL_SUPPORT, WANT_APPLICATION_INI_FILE,
; ENHANCED_ENTER_KEYS, WANT_LONGNAMES, WANT_PROFILE TOGGLE_ESCAPE,
; TOGGLE_TAB, DYNAMIC_CURSOR_STYLE
; Remaining consts:
; CHECK_FOR_LEXAM, WPS_SUPPORT, ENTER_ACTION, C_ENTER_ACTION, HOST_SUPPORT
; my_CURSORDIMENSIONS, my_SAVEPATH, WANT_BITMAP_BACKGROUND, INITIAL_TOOLBAR,
; my_STACK_CMDS, my_CUA_MENU_ACCEL, SUPPORT_USER_EXITS

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
defc configdlg
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif

   args = arg(1)
   wp = wordpos( 'SYS', upcase( args))
   if wp then
      args = delword( args, wp, 1)
      msgid = 5147  -- EPM_POPSYSCONFIGDLG
   else
      msgid = 5129  -- EPM_POPCONFIGDLG
   endif

   omit = 0
   if isnum( args) then
      omit = args
   endif
   -- omit: from 0 to 1023
   --    0: all pages
   --    1: without page  1  Margins
   --    2: without page  2  Colors
   --    4: without page  3  Pathes
   --    8: without page  4  Auto-save
   --   16: without page  5  Fonts
   --   32: without page  6  Keys
   --   64: without page  7  Window
   --  128: without page  8  Misc.
   --  256: without page  9  Toolbar style
   --  512: without page 10  Toolbar

   call windowmessage( 0, getpminfo(APP_HANDLE),
                       msgid,
                       omit,           -- 0 = Omit no pages
compile if CHECK_FOR_LEXAM
                       not LEXAM_is_available)
compile else
                       0)
compile endif


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
   universal addenda_filename
   universal dictionary_filename
   universal vAUTOSAVE_PATH, vTEMP_PATH
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal appname, app_hini
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
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
compile if WPS_SUPPORT
   universal wpshell_handle
compile endif
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
compile if WPS_SUPPORT
   if wpshell_handle then
      help_panel = 5350 + page
   else
compile endif
      help_panel = 5300 + page
compile if WPS_SUPPORT
    endif
compile endif

   if page = 1 then  --------------------- Page 1 is tabs -------------
      if fsend_default = 2 then tempstr = .tabs
      else tempstr = checkini( fsend_default, INI_TABS, DEFAULT_TABS)
      endif
      call send_config_data( hndle, tempstr, 3, help_panel)
      tempstr = 0
      if not fsend_default then      -- 0: Use values from .ini file
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if words(newcmd) >= 14 then
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
         tempstr = .textcolor .markcolor vSTATUSCOLOR vMESSAGECOLOR
      else
         if fsend_default then     -- 1: Use default values
            tempstr = ''
         else                      -- 0: Use values from .ini file
            tempstr = queryprofile( app_hini, appname, INI_STUFF)
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
compile if WPS_SUPPORT
      if not wpshell_handle then
compile endif
compile if CHECK_FOR_LEXAM
      if lexam_is_available then
compile endif
         help_panel = 5390  -- Different help panel
compile if CHECK_FOR_LEXAM
      endif
compile endif
compile if WPS_SUPPORT
      endif
compile endif
      call send_config_data( hndle, checkini( fsend_default, INI_TEMPPATH, vTEMP_PATH, TEMP_PATH), 10, help_panel)
compile if CHECK_FOR_LEXAM
      if lexam_is_available then
compile endif
         call send_config_data( hndle, checkini( fsend_default, INI_DICTIONARY, dictionary_filename), 11, help_panel)
         call send_config_data( hndle, checkini( fsend_default, INI_ADDENDA, addenda_filename), 12, help_panel)
compile if CHECK_FOR_LEXAM
      endif
compile endif

   elseif page = 5 then  ----------------- Page 5 is autosave ---------
      if fsend_default = 2 then      -- 2: Use current values
         tempstr = .autosave
      else                           -- 0|1: Use values from .ini file or default values
         tempstr = checkini( fsend_default, INI_AUTOSAVE, DEFAULT_AUTOSAVE)
      endif
      call send_config_data( hndle, tempstr, 2, help_panel)
      call send_config_data( hndle, checkini( fsend_default, INI_AUTOSPATH, vAUTOSAVE_PATH, AUTOSAVE_PATH), 9, help_panel)

   elseif page = 6 then  ----------------- Page 6 is fonts ------------
      fontid = word( default_font 0 .font, fsend_default + 1)
      call send_config_data( hndle, queryfont(fontid)'.'trunc(.textcolor//16)'.'.textcolor%16, 24, help_panel)
      if not fsend_default then    -- 0: Use values from .ini file
         tempstr = checkini( fsend_default, INI_STATUSFONT, '')
         if tempstr then
            parse value tempstr with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      elseif fsend_default = 1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                           -- 2: Use current values
         if statfont then
            parse value statfont with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      endif
      call send_config_data( hndle, tempstr'.'trunc(vSTATUSCOLOR//16)'.'vSTATUSCOLOR%16, 25, help_panel)
      if not fsend_default then      -- 0: Use values from .ini file
         tempstr = checkini( fsend_default, INI_MESSAGEFONT, '')
         if tempstr then
            parse value tempstr with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      elseif fsend_default = 1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                           -- 2: Use current values
         if msgfont then
            parse value msgfont with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      endif
      call send_config_data(hndle, tempstr'.'trunc(vMESSAGECOLOR//16)'.'vMESSAGECOLOR%16, 26, help_panel)

   elseif page = 7 then  ----------------- Page 7 is enter keys -------
      if fsend_default = 1 then      -- 1: Use default values
 compile if ENTER_ACTION = '' | ENTER_ACTION = 'ADDLINE'  -- The default
         ek = \1
 compile elseif ENTER_ACTION = 'NEXTLINE'
         ek = \2
 compile elseif ENTER_ACTION = 'ADDATEND'
         ek = \3
 compile elseif ENTER_ACTION = 'DEPENDS'
         ek = \4
 compile elseif ENTER_ACTION = 'DEPENDS+'
         ek = \5
 compile elseif ENTER_ACTION = 'STREAM'
         ek = \6
 compile endif
 compile if C_ENTER_ACTION = 'ADDLINE'
         c_ek = \1
 compile elseif C_ENTER_ACTION = '' | C_ENTER_ACTION = 'NEXTLINE'  -- The default
         c_ek = \2
 compile elseif C_ENTER_ACTION = 'ADDATEND'
         c_ek = \3
 compile elseif C_ENTER_ACTION = 'DEPENDS'
         c_ek = \4
 compile elseif C_ENTER_ACTION = 'DEPENDS+'
         c_ek = \5
 compile elseif C_ENTER_ACTION = 'STREAM'
         c_ek = \6
 compile endif
         tempstr = ek || ek || c_ek || ek || ek || ek || c_ek || ek
      else                           -- 0|2: Use values from .ini file or current values
         tempstr = chr(enterkey) || chr(a_enterkey) || chr(c_enterkey) || chr(s_enterkey) || chr(padenterkey) || chr(a_padenterkey) || chr(c_padenterkey) || chr(s_padenterkey)
      endif
      call send_config_data(hndle, tempstr, 14, help_panel)

   elseif page = 8 then  ----------------- Page 8 is Frame controls ---
      tempstr = '1111010'  -- StatWnd, MsgWnd, hscroll, vscroll, extrawnd, bgbitmap, drop
      if not fsend_default then      -- 0: Use values from .ini file
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with statflg msgflg vscrollflg hscrollflg . . extraflg . . . . . . . new_bitmap . drop_style .
            tempstr = statflg || msgflg || hscrollflg || vscrollflg || extraflg || new_bitmap || drop_style
         endif
      elseif fsend_default = 2 then  -- 2: Use current values
         tempstr = queryframecontrol(1) || queryframecontrol(2) || queryframecontrol(16) ||
                   queryframecontrol(8) || queryframecontrol(32) || bitmap_present || queryframecontrol(8192)
      endif
      call send_config_data( hndle, tempstr, 15, help_panel)
      call send_config_data( hndle, checkini( fsend_default, INI_BITMAP, bm_filename, ''), 16, help_panel)

   elseif page = 9 then  ----------------- Page 9 is Misc. ------------
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
            parse value newcmd with . . . . . . . markflg . streamflg profile longnames .  -- fixed 1: exchanged show_longnames and rexx_profile
            tempstr = markflg || streamflg || profile || longnames ||                      -- fixed 1: exchanged show_longnames and rexx_profile
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
         tempstr = \1'8'\1'32'\1'32'\1'8.Helv'\1'16777216'\1'16777216'\1
      endif
      call send_config_data( hndle, tempstr, 22, help_panel)

   elseif page = 13 then  ---------------- Page 13 is Toolbar name & on/off
      active_toolbar = toolbar_loaded
      if active_toolbar = \1 then
         active_toolbar = ''
      endif
;      checkini( fsend_default, INI_DEF_TOOLBAR, active_toolbar, '')
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

defproc send_config_data( hndle, strng, i, help_panel)
   strng = strng\0          -- null terminate (asciiz)
   call windowmessage( 1, hndle,
                       32,               -- WM_COMMAND - 0x0020
                       mpfrom2short( help_panel, i),
                       ltoa( offset(strng) || selector(strng), 10))

defc enterkeys =
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal appname, app_hini
   parse arg perm enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey
   if perm then
      call setprofile( app_hini, appname, INI_ENTERKEYS,
                       enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey)
   endif

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
defc SetConfig
   universal addenda_filename
   universal dictionary_filename
   universal vTEMP_FILENAME, vTEMP_PATH
   universal vAUTOSAVE_PATH
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal appname, app_hini
   universal vMESSAGECOLOR, vSTATUSCOLOR
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
   universal vEPM_POINTER, cursordimensions

   ChangeFileSettings = CONFIGDLG_CHANGE_FILE_SETTINGS  -- standard was 1
   AskReflow          = CONFIGDLG_ASK_REFLOW

   parse value arg(1) with configid perm newcmd

   if     configid = 1 then
------------------------------------------------------
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
      vDEFAULT_MARGINS = setini( INI_MARGINS, newcmd, perm)
      'RefreshInfoLine MARGINS'
------------------------------------------------------

   elseif configid = 2 then
      .autosave = setini( INI_AUTOSAVE, newcmd, perm)
      vDEFAULT_AUTOSAVE = newcmd

   elseif configid = 3 then
------------------------------------------------------
      if ChangeFileSettings = 1 then                      -- change current file's setting
         if .tabs <> newcmd then
            .tabs = newcmd
            'postme refreshinfoline TABS'
         endif
      elseif ChangeFileSettings = 'REFRESHDEFAULT' then   -- change setting of all files in
         'RingRefreshSetting DEFAULT SetTabs 'newcmd      -- the ring with default settings
      endif
      vDEFAULT_TABS = setini( INI_TABS, newcmd, perm)
      'RefreshInfoLine TABS'
------------------------------------------------------

   elseif configid = 4 then
      .textcolor = newcmd

   elseif configid = 5 then
      .markcolor = newcmd

   elseif configid = 6 & newcmd <> vSTATUSCOLOR then
      vSTATUSCOLOR = newcmd
      'setstatusline'

   elseif configid = 7 & newcmd <> vMESSAGECOLOR then
      vMESSAGECOLOR = newcmd
      'setmessageline'

   elseif configid = 9 then
      if newcmd <> '' & rightstr( newcmd, 1) <> '\' then
         newcmd = newcmd'\'
      endif
      if rightstr( newcmd, 2) = '\\' then             -- Temp fix for dialog bug
         newcmd = leftstr( newcmd, length(newcmd) - 1)
      endif
      vAUTOSAVE_PATH = setini( INI_AUTOSPATH, newcmd, perm)

   elseif configid = 10 then
      if newcmd <> '' & rightstr( newcmd, 1) <> '\' then
         newcmd = newcmd'\'
      endif
      if rightstr( newcmd, 2) = '\\' then             -- Temp fix for dialog bug
         newcmd = leftstr( newcmd, length(newcmd) - 1)
      endif
      if upcase(leftstr( vTEMP_FILENAME, length(vTEMP_PATH))) = upcase(vTEMP_PATH) then
         vTEMP_FILENAME = newcmd||substr( vTEMP_FILENAME, length(vTEMP_PATH) + 1)
      elseif not verify( vTEMP_FILENAME, ':\', 'M') then   -- if not fully qualified
         vTEMP_FILENAME = newcmd||vTEMP_FILENAME
      endif
      vTEMP_PATH = setini( INI_TEMPPATH, newcmd, perm)

   elseif configid = 11 then
      dictionary_filename = setini( INI_DICTIONARY, newcmd, perm)

   elseif configid = 12 then
      addenda_filename = setini( INI_ADDENDA, newcmd, perm)

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
            call setprofile( app_hini, appname, INI_OPTFLAGS,
               queryframecontrol(1) queryframecontrol(2) queryframecontrol(8) || ' ' ||          -- damned space-separated
               queryframecontrol(16) w1 w2 queryframecontrol(32) w3 w4 w5 w6 w7 w8 w9 || ' ' ||  -- parameter lists!
               bitmap_present w10 queryframecontrol(8192) rest)
               -- man, what's that space shit good for?
         else
            'saveoptions OptOnly'
         endif
      endif

   elseif configid = 16 then
      if bm_filename <> newcmd then
         bm_filename = newcmd
         if bitmap_present then
            if bm_filename = '' then  -- Need to turn off & back on to get default bitmap
               'toggle_bitmap'
               'toggle_bitmap'
            else
               'load_dt_bitmap' bm_filename
            endif
         endif
      endif
      if perm then
         call setprofile( app_hini, appname, INI_BITMAP, bm_filename)
      endif

   elseif configid = 18 then
      parse value newcmd with markflg 2 streamflg 3 profile 4 longnames 5 pointer_style 6 cursor_shape 7 menu_accel 8
      vEPM_POINTER = 1 + pointer_style
      mouse_setpointer vEPM_POINTER
compile if not defined(my_CURSORDIMENSIONS)
      'cursor_style' (cursor_shape + 1)
compile endif
------------------------------------------------------
      if markflg <> cua_marking_switch then
         'CUA_mark_toggle'
         'postme RefreshInfoline MARKINGMODE' -- postme required? CUA_mark_toggle sets infoline already!
      endif
------------------------------------------------------
/*
      if ChangeFileSettings then
         if streamflg <> stream_mode then
            'stream_toggle'
         endif
      endif
*/
-- todo?
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

------------------------------------------------------
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
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             w1 w2 w3 w4 w5 w6 w7 markflg w8 streamflg profile longnames rest)  -- fixed 1: exchanged show_longname and rexx_profile
         else
            'saveoptions OptOnly'
         endif
         call setprofile( app_hini, appname, INI_OPT2FLAGS, pointer_style cursor_shape)
         call setprofile( app_hini, appname, INI_CUAACCEL, menu_accel)
      endif

   elseif configid = 19 then
      on = newcmd
------------------------------------------------------
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
------------------------------------------------------

      if perm then
         newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             subword( newcmd, 1, 13) on subword( newcmd, 15))
         else
            'saveoptions OptOnly'
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
         if temp <> '' then
            call setprofile( app_hini, appname, INI_OPTFLAGS,
                             subword( temp, 1, 15) newcmd subword( temp, 17))
         else
            'saveoptions OptOnly'  -- Possible synch problem?
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
      call setprofile( app_hini, appname, INI_STUFF,
                       .textcolor .markcolor vstatuscolor vmessagecolor)

   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: initconfig                                               ³
³                                                                            ³
³ what does it do : Set universal variables according to the  values         ³
³                   previously saved in the EPM.INI file.                    ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
; The menu defs like togglecontrol, toggleframe, ... must be already defined
; before initconfig is executed.
defc InitConfig
   universal addenda_filename
   universal dictionary_filename
   universal vTEMP_FILENAME, vTEMP_PATH
   universal vAUTOSAVE_PATH
   universal appname, app_hini, bitmap_present, optflag_extrastuff
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal statfont, msgfont, bm_filename
   universal default_font
   universal cua_marking_switch
   universal menu_prompt
compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined(my_SAVEPATH)
   universal savepath
compile endif
   universal vMESSAGECOLOR, vSTATUSCOLOR
   universal vDESKTOPColor
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal stream_mode
   universal default_stream_mode
   universal ring_enabled
   universal show_longnames
   universal rexx_profile
;   universal escape_key  -- Disabled
   universal tab_key
   universal default_tab_key
   universal vEPM_POINTER, cursordimensions
   universal appname
   universal stack_cmds
   universal cua_menu_accel
compile if CHECK_FOR_LEXAM
   universal lexam_is_available
compile endif
compile if WPS_SUPPORT  -- if Epm class is used
   universal wpshell_handle
compile endif

compile if WPS_SUPPORT  -- if Epm class is used
   useWPS = upcase(arg(1)) <> 'NOWPS'
   if wpshell_handle & useWPS then  -- read config data from WPS object
      load_wps_config(wpshell_handle)
      newcmd = 1  -- For a later IF
   else                             -- read config data from EPM.INI
compile endif

      newcmd = queryprofile( app_hini, appname, INI_STUFF)
      if newcmd then
         parse value newcmd with ttextcolor tmarkcolor tstatuscolor tmessagecolor .
         .textcolor = ttextcolor; .markcolor = tmarkcolor
         if tstatuscolor <> '' & tstatuscolor <> vstatuscolor then
            vstatuscolor = tstatuscolor
            'setstatusline'
         endif
         if tmessagecolor <> '' & tmessagecolor <> vmessagecolor then
            vmessagecolor = tmessagecolor
            'setmessageline'
         endif
         newcmd = queryprofile( app_hini, appname, INI_MARGINS)
         if newcmd then
            .margins = newcmd
            vdefault_margins = newcmd
         endif
         newcmd = queryprofile( app_hini, appname, INI_AUTOSAVE)
         if newcmd <> '' then
            .autosave = newcmd
            vDEFAULT_AUTOSAVE = newcmd
         endif
         newcmd = queryprofile( app_hini, appname, INI_TABS)
         if newcmd then
            .tabs = newcmd; vdefault_tabs = newcmd
         endif
         newcmd = queryprofile( app_hini, appname, INI_TEMPPATH)
         if newcmd then
            vTEMP_PATH = newcmd
            if rightstr( vTemp_Path, 1) <> '\' then
               vTemp_Path = vTemp_Path'\'          -- Must end with a backslash.
            endif
            if not verify( vTEMP_FILENAME, ':\', 'M') then   -- if not fully qualified
               vTEMP_FILENAME = vTEMP_PATH||vTEMP_FILENAME
            endif
         endif
         newcmd = queryprofile( app_hini, appname, INI_AUTOSPATH)
         if newcmd then
            vAUTOSAVE_PATH = newcmd
            if rightstr( vAUTOSAVE_Path, 1) <> '\' then
               vAUTOSAVE_Path = vAUTOSAVE_Path'\'  -- Must end with a backslash.
            endif
compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined(my_SAVEPATH)
            savepath = vAUTOSAVE_PATH
compile endif
         endif
         newcmd = queryprofile( app_hini, appname, INI_DICTIONARY)
         if newcmd then
            dictionary_filename = newcmd
         endif
         newcmd = queryprofile( app_hini, appname, INI_ADDENDA)
         if newcmd then
            addenda_filename = newcmd
         endif
      endif  -- newcmd

          -- Options from Option pulldown
      newcmd = queryprofile( app_hini, appname, INI_OPTFLAGS)
compile if WPS_SUPPORT
   endif  -- wpshell_handle
compile endif
   if newcmd = '' then
      optflag_extrastuff = ''
compile if not defined(WANT_BITMAP_BACKGROUND)
      new_bitmap = 1
compile else
      new_bitmap = WANT_BITMAP_BACKGROUND
compile endif -- not defined(WANT_BITMAP_BACKGROUND)
      drop_style = 0
compile if defined(INITIAL_TOOLBAR)
      toolbar_present = INITIAL_TOOLBAR
compile else
      toolbar_present = 1
compile endif
   else
compile if WPS_SUPPORT
   if wpshell_handle & useWPS then  -- Keys 15, 18 & 19
      parse value peekz( peek32( wpshell_handle, 60, 4)) with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7 drop_style 8
      parse value peekz( peek32( wpshell_handle, 72, 4)) with markflg 2 streamflg 3 profile 4 longnames 5 pointer_style 6 cursor_shape 7
      parse value peekz( peek32( wpshell_handle, 76, 4)) with tabkey 2
      parse value peekz( peek32( wpshell_handle, 84, 4)) with toolbar_present 2
      rotflg = 1
   else
compile endif
      parse value newcmd with statflg msgflg vscrollflg hscrollflg fileiconflg rotflg extraflg markflg menu_prompt streamflg profile longnames escapekey tabkey new_bitmap toolbar_present drop_style optflag_extrastuff  -- fixed 3: exchanged show_longname and rexx_profile
compile if WPS_SUPPORT
   endif  -- wpshell_handle
compile endif
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
      if ring_enabled then
         'toggleframe 4' rotflg
      endif
      'toggleframe 32' extraflg
      if drop_style <> '' then
         'toggleframe 8192' drop_style
      endif
      if new_bitmap = '' then
compile if not defined(WANT_BITMAP_BACKGROUND)
         new_bitmap = 1
compile else
         new_bitmap = WANT_BITMAP_BACKGROUND
compile endif -- not defined(WANT_BITMAP_BACKGROUND)
      endif
------------------------------------------------------------------
      cua_marking_switch = 0
      if markflg <> '' then
         if markflg <> cua_marking_switch then
            'CUA_mark_toggle'
         endif
      endif
------------------------------------------------------------------
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
------------------------------------------------------------------
      show_longnames = 1
      if longnames <> '' then
         show_longnames = longnames
      endif
------------------------------------------------------------------
      rexx_profile = 1
      if profile <> '' then
         rexx_profile = profile
      endif
------------------------------------------------------------------
/*
-- Disabled; should remain on; can still be configured via PROFILE.ERX:
-- 'escapekey 0'
      escape_key = 1
      if escapekey <> '' then
         escape_key = escapekey
      endif
*/
------------------------------------------------------------------
      default_tab_key = 0
      if tabkey <> '' then
         default_tab_key = tabkey
      endif
      tab_key = default_tab_key
------------------------------------------------------------------
   endif  /* INI_OPTFLAGS 1/3 */ -- Settings dlg, not as part of Save Options

compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
compile endif
      if bitmap_present <> new_bitmap then
         'toggle_bitmap'
      endif
      newcmd = queryprofile( app_hini, appname, INI_ENTERKEYS)
      if newcmd<>'' then
         parse value newcmd with enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey .
      endif
      newcmd = queryprofile( app_hini, appname, INI_STATUSFONT)
      if newcmd<>'' then
         statfont = newcmd  -- Need to keep?
         parse value newcmd with psize"."facename"."attr
         "setstatface" getpminfo(EPMINFO_EDITSTATUSHWND) facename
         "setstatptsize" getpminfo(EPMINFO_EDITSTATUSHWND) psize
      endif
      newcmd = queryprofile( app_hini, appname, INI_MESSAGEFONT)
      if newcmd<>'' then
         msgfont = newcmd   -- Need to keep?
         parse value newcmd with psize"."facename"."attr
         "setstatface" getpminfo(EPMINFO_EDITMSGHWND) facename
         "setstatptsize" getpminfo(EPMINFO_EDITMSGHWND) psize
      endif
      newcmd = queryprofile( app_hini, appname, INI_BITMAP)
      if newcmd<>'' then
         bm_filename = newcmd  -- Need to keep?
         if bitmap_present then
            'load_dt_bitmap' bm_filename
         endif
      endif
compile if WPS_SUPPORT
   endif  -- not wpshell_handle
compile endif

compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
compile endif
      parse value queryprofile( app_hini, appname, INI_OPT2FLAGS) with pointer_style cursor_shape .
compile if WPS_SUPPORT
   endif  -- not wpshell_handle
compile endif
   if pointer_style <> '' then
      vepm_pointer = 1 + pointer_style
      mouse_setpointer vepm_pointer
   endif
compile if not defined(my_CURSORDIMENSIONS)
   if cursor_shape <> '' then
      'cursor_style' (cursor_shape + 1)
   endif
compile endif -- not defined(my_CURSORDIMENSIONS)

compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
compile endif
      newcmd = queryprofile( app_hini, appname, INI_FONT)
      parse value newcmd with fontname '.' fontsize '.' fontsel
      if newcmd <> '' then
         .font = registerfont( fontname, fontsize, fontsel)
         default_font = .font
      endif
compile if WPS_SUPPORT
   endif  -- not wpshell_handle
compile endif

   if toolbar_present then
      --'default_toolbar'
      'ReloadToolbar'
;  else
;     'toggleframe' EFRAMEF_TOOLBAR toolbar_present
   endif

   newcmd = queryprofile( app_hini, appname, INI_DTCOLOR)
   if newcmd <> '' then
      vdesktopcolor = newcmd
      call windowmessage( 0,  getpminfo(EPMINFO_EDITCLIENT),  -- post
                          5497,      -- EPM_EDIT_SETDTCOLOR
                          vdesktopcolor,
                          0)
   endif

; Moved from MENUACEL.E (file deleted now, formerly included by definit)
compile if defined(my_STACK_CMDS)
   stack_cmds = my_STACK_CMDS
compile else
   --stack_cmds = 0  -- changed by aschn
   stack_cmds = 1
compile endif
compile if WPS_SUPPORT
   if wpshell_handle then
; Key 16
;     this_ptr = peek32(shared_mem+64, 4); -- if this_ptr = \0\0\0\0 then return; endif
;     parse value peekz(this_ptr) with ? stack_cmds ?
      stack_cmds = substr( peekz( peek32( wpshell_handle, 64, 4)), 6, 1)
   else
compile endif
   newcmd = queryprofile( app_hini, appname, INI_STACKCMDS)
   if newcmd <> '' then
      stack_cmds = newcmd
   endif
compile if WPS_SUPPORT
   endif  -- wpshell_handle
compile endif
compile if defined(my_CUA_MENU_ACCEL)
   cua_menu_accel = my_CUA_MENU_ACCEL
compile else
   cua_menu_accel = 0
compile endif
compile if WPS_SUPPORT
   if wpshell_handle then
      cua_menu_accel = substr( peekz( peek32( wpshell_handle, 72, 4)), 7, 1)
   else
compile endif
      newcmd = queryprofile( app_hini, appname, INI_CUAACCEL)
      if newcmd <> '' then
         cua_menu_accel = newcmd
      endif
compile if WPS_SUPPORT
   endif  -- wpshell_handle
compile endif
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

compile if WPS_SUPPORT
defproc load_wps_config(shared_mem)
   universal vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE, vDEFAULT_TABS, vSTATUSCOLOR, vMESSAGECOLOR, vAUTOSAVE_PATH
   universal vTEMP_PATH, vTEMP_FILENAME, DICTIONARY_FILENAME, ADDENDA_FILENAME
   universal default_font
 compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL')
   universal savepath
 compile endif
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal bitmap_present, bm_filename
/* shared_memx = "x'"ltoa(atol(shared_mem), 16)"'"                                                                                                                                        */
/*    thisptr = ''                                                                                                                                                                        */
/*    do i = 1 to 14                                                                                                                                                                        */
/*         thisptr = thisptr i" = x'"ltoa(peek32(shared_mem, i*4, 4), 16)"'"                                                                                                                */
/*    enddo                                                                                                                                                                               */
/* call winmessagebox('load_wps_config('shared_memx') pointers', thisptr, 16432) -- MB_OK + MB_INFORMATION + MB_MOVEABLE                                                                  */
;  if rc then
;     messageNwait('DosGetSharedMem' ERROR__MSG rc)
;     return
;  endif

; Key 1
   this_ptr = peek32( shared_mem, 4, 4);  -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', "First pointer = x'"ltoa(this_ptr, 16)"'", 16432)*/
/** call winmessagebox('load_wps_config('shared_memx')', 'First pointer -> "'peekz(this_ptr)'"', 16432)*/
   .margins = peekz(this_ptr); vDEFAULT_MARGINS = .margins
/** sayerror '1:  Margins set OK:' peekz(this_ptr)  */
; Key 2
   this_ptr = peek32( shared_mem, 8, 4);  -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', "Second pointer = x'"ltoa(this_ptr, 16)"'", 16432) */
/** call winmessagebox('load_wps_config('shared_memx')', 'Second pointer -> "'peekz(this_ptr)'"', 16432) */
   .autosave = peekz(this_ptr); vDEFAULT_AUTOSAVE = .autosave
/** sayerror '2:  Autosave set OK:' peekz(this_ptr) */
; Key 3
   this_ptr = peek32( shared_mem, 12, 4);  -- if this_ptr = \0\0\0\0 then return; endif
   .tabs = peekz(this_ptr); vDEFAULT_TABS = .tabs
/** sayerror '3:  Tabs set OK:' peekz(this_ptr) */
; Key 4
   this_ptr = peek32( shared_mem, 16, 4); -- if this_ptr = \0\0\0\0 then return; endif
   .textcolor = peekz(this_ptr)
/** sayerror '4:  Textcolor set OK:' peekz(this_ptr) */
; Key 5
   this_ptr = peek32( shared_mem, 20, 4); -- if this_ptr = \0\0\0\0 then return; endif
   .markcolor = peekz(this_ptr)
/** sayerror '5:  Markcolor set OK:' peekz(this_ptr) */
; Key 6
   this_ptr = peek32( shared_mem, 24, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vSTATUSCOLOR = peekz(this_ptr); 'setstatusline'
/** sayerror '6:  Statuscolor set OK:' peekz(this_ptr) */
; Key 7
   this_ptr = peek32( shared_mem, 28, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vMESSAGECOLOR = peekz(this_ptr); 'setmessageline'
/** sayerror '7:  Messagecolor set OK:' peekz(this_ptr) */
; Key 9
   this_ptr = peek32( shared_mem, 36, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vAUTOSAVE_PATH = peekz(this_ptr)
   if vAUTOSAVE_PATH & rightstr( vAUTOSAVE_Path, 1) <> '\' then
      vAUTOSAVE_Path = vAUTOSAVE_Path'\'  -- Must end with a backslash.
   endif
  compile if (HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL') and not defined(my_SAVEPATH)
   savepath = vAUTOSAVE_PATH
  compile endif
/** sayerror '9:  AutosavePath set OK:' peekz(this_ptr) */
; Key 10
   this_ptr = peek32( shared_mem, 40, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vTEMP_PATH = peekz(this_ptr)
   if rightstr(vTemp_Path,1)<>'\' then
      vTemp_Path = vTemp_Path'\'          -- Must end with a backslash.
   endif
   if not verify(vTEMP_FILENAME,':\','M') then   -- if not fully qualified
      vTEMP_FILENAME = vTEMP_PATH||vTEMP_FILENAME
   endif
/** sayerror '10:  TempPath set OK:' peekz(this_ptr) */
; Key 11
   this_ptr = peek32( shared_mem, 44, 4); -- if this_ptr = \0\0\0\0 then return; endif
   dictionary_filename = peekz(this_ptr)
/** sayerror '11:  Dictionary set OK:' peekz(this_ptr) */
; Key 12
   this_ptr = peek32( shared_mem, 48, 4); -- if this_ptr = \0\0\0\0 then return; endif
   addenda_filename = peekz(this_ptr)
/** sayerror '12:  Addenda file set OK:' peekz(this_ptr) */
; Key 15
      parse value peekz( peek32( shared_mem, 60, 4)) with 6 new_bitmap 7
   if bitmap_present <> new_bitmap then
      'toggle_bitmap'
   endif
; Key 16
   if bm_filename <> peekz( peek32( shared_mem, 64, 4)) then
      bm_filename = peekz( peek32( shared_mem, 64, 4))
      if bitmap_present then
         'load_dt_bitmap' bm_filename
      endif
   endif
; Key 24
   this_ptr = peek32( shared_mem, 96, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '13th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize = "'fontsize'"; fontsel = "'fontsel'"'  */
   .font = registerfont( fontname, fontsize, fontsel); default_font = .font
/*  sayerror '24:  Font set OK:' peekz(this_ptr) '.font = ' default_font  */
; Key 14
   this_ptr = peek32( shared_mem, 56, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '14th pointer -> "'peekz(this_ptr)'"', 16432) */
   tempstr = peekz(this_ptr)
   enterkey      = asc( substr( tempstr, 1, 1))
   a_enterkey    = asc( substr( tempstr, 2, 1))
   c_enterkey    = asc( substr( tempstr, 3, 1))
   s_enterkey    = asc( substr( tempstr, 4, 1))
   padenterkey   = asc( substr( tempstr, 5, 1))
   a_padenterkey = asc( substr( tempstr, 6, 1))
   c_padenterkey = asc( substr( tempstr, 7, 1))
   s_padenterkey = asc( substr( tempstr, 8, 1))
/** sayerror '14:  Enter keys set OK:' peekz(this_ptr) */
/** call winmessagebox('load_wps_config('shared_memx')', 'All done!', 16432)  */
; Key 25
   this_ptr = peek32( shared_mem, 100, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '25th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize = "'fontsize'"; fontsel = "'fontsel'"'  */
   statfont = fontsize'.'fontname'.'fontsel
   "setstatface" getpminfo(EPMINFO_EDITSTATUSHWND) fontname
   "setstatptsize" getpminfo(EPMINFO_EDITSTATUSHWND) fontsize
; Key 26
   this_ptr = peek32( shared_mem, 104, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '26th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize = "'fontsize'"; fontsel = "'fontsel'"'  */
   msgfont = fontsize'.'fontname'.'fontsel
   "setstatface" getpminfo(EPMINFO_EDITMSGHWND) fontname
   "setstatptsize" getpminfo(EPMINFO_EDITMSGHWND) fontsize

;defproc ppeek32(longaddr, offst, len)
;   parse value atol(longaddr+offst) with hex_ofs 3 hex_seg
;   return peek(ltoa(hex_seg\0\0, 10), ltoa(hex_ofs\0\0, 10), len)

defc refresh_config  -- for WPS_SUPPORT only
   universal app_hini
   universal wpshell_handle
   universal toolbar_loaded
   universal cua_marking_switch
   universal stream_mode
   universal ring_enabled
   universal show_longnames
   universal escape_key
   universal tab_key
   universal rexx_profile
   universal menu_prompt
   universal cua_menu_accel
   universal bitmap_present, bm_filename
   universal cursordimensions
   universal vEPM_POINTER
   if wpshell_handle then
      load_wps_config(wpshell_handle)
; Key 15
      parse value peekz( peek32( wpshell_handle, 60, 4)) with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
      'toggleframe 32' extraflg
;  if bitmap_present <> new_bitmap then
;     'toggle_bitmap'
;  endif
; Key 18
      parse value peekz( peek32( wpshell_handle, 72, 4)) with markflg 2 streamflg 3 rexx_profile 4 longnames 5 pointer_style 6 cursor_shape 7 menu_accel 8
      if markflg <> cua_marking_switch then
         'CUA_mark_toggle'
      endif
      if streamflg <> stream_mode then
         'stream_toggle'
      endif
      show_longnames = longnames
      vEPM_POINTER = 1 + pointer_style
      mouse_setpointer vEPM_POINTER
 compile if not defined(my_CURSORDIMENSIONS)
      'cursor_style' (cursor_shape + 1)
 compile endif -- not defined(my_CURSORDIMENSIONS)
      if cua_menu_accel <> menu_accel then
         'accel_toggle'
      endif
; Key 19
      parse value peekz( peek32( wpshell_handle, 76, 4)) with TAB_KEY 2
;     parse value peekz(peek32(wpshell_handle, 68, 4)) with rexx_profile 2 menu_prompt 3 new_bitmap 4
;     if new_bitmap <> bitmap_present then
;        'toggle_bitmap'
;     endif
; Key 20
      newcmd = peekz( peek32( wpshell_handle, 80, 4))
      if newcmd = '' then  -- Null string; use compiled-in toolbar
         if toolbar_loaded <> \1 then
            --'loaddefaulttoolbar'
            'LoadStandardToolbar'
         endif
      elseif newcmd <> toolbar_loaded then
         call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                             5916,
                             app_hini,
                             put_in_buffer(newcmd))
         toolbar_loaded = newcmd
      endif
; Key 21
      parse value peekz( peek32( wpshell_handle, 84, 4)) with toolbar_flg 2
      if toolbar_flg <> queryframecontrol(EFRAMEF_TOOLBAR) then
         'toggleframe' EFRAMEF_TOOLBAR toolbar_flg
      endif
; Key 22
      call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                          5921,
                          put_in_buffer( peekz( peek32( wpshell_handle, 88, 4))),
                          0)
   endif -- wpshell_handle
compile endif  -- WPS_SUPPORT

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: saveoptions                                              ³
³                                                                            ³
³ what does it do : save state of items on options pull down in os2ini       ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc saveoptions
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
                    rexx_profile                       || ' ' ||  -- 11 REXX profile                fixed 2: exchanged show_longname and rexx_profile
                    show_longnames                     || ' ' ||  -- 12 Show .LONGNAME in titletext
                    escape_key                         || ' ' ||  -- 13 Esc opens commandline
                    tab_key                            || ' ' ||  -- 14 Tabkey
                    bitmap_present                     || ' ' ||  -- 15 Background bitmap
                    queryframecontrol(EFRAMEF_TOOLBAR) || ' ' ||  -- 16 Toolbar
                    queryframecontrol(8192)            || ' ' ||  -- 17 Drop style (0 = edit, 1 = import)
                    optflag_extrastuff)                           -- 18 ?

   if arg(1) = 'OptOnly' then  -- don't process the following
      return
   endif
   call setprofile( app_hini, appname, INI_RINGENABLED,    ring_enabled)
   call setprofile( app_hini, appname, INI_STACKCMDS,      stack_cmds)
   call setprofile( app_hini, appname, INI_CUAACCEL,       cua_menu_accel)
   if statfont <> '' then
      call setprofile( app_hini, appname, INI_STATUSFONT,  statfont)
   endif
   if msgfont <> '' then
      call setprofile( app_hini, appname, INI_MESSAGEFONT, msgfont)
   endif
;  if bm_filename <> '' then  -- Set even if null, so Toggle_Bitmap can remove dropped background.
      call setprofile( app_hini, appname, INI_BITMAP,      bm_filename)
;  endif
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       62, 0, 0)               -- x'003E' = WM_SAVEAPPLICATION
compile if SUPPORT_USER_EXITS
   if isadefproc('saveoptions_exit') then
      call saveoptions_exit()
   endif
compile endif

; ---------------------------------------------------------------------------
; Called when a font is dropped on a window, after SetPresParam.
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savefont                                                 ³
³                                                                            ³
³ what does it do : save fonts in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveFont
   universal appname, app_hini, bitmap_present, optflag_extrastuff
   universal statfont, msgfont
   --dprintf( 'SaveFont', 'arg(1) = ['arg(1)']')
   -- arg(1) = 'EDIT' | 'MSG' | 'STAT'
   parse value upcase(arg(1)) with prefix
   if prefix == 'EDIT' then
      call setini( INI_FONT, queryfont(.font), 1)
   elseif prefix == 'STAT' & statfont <> '' then
      call setprofile(app_hini, appname, INI_STATUSFONT, statfont)
   elseif prefix == 'MSG' & msgfont <> '' then
      call setprofile(app_hini, appname, INI_MESSAGEFONT, msgfont)
   endif

; ---------------------------------------------------------------------------
; Called when a color is dropped on a window, after SetPresParam.
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savecolor                                                ³
³                                                                            ³
³ what does it do : save color in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc SaveColor
   universal appname, app_hini
   universal vstatuscolor, vmessagecolor, vDESKTOPCOLOR
   --dprintf( 'SaveColor', 'arg(1) = ['arg(1)']')
   -- arg(1) = 'EDIT' | 'MSG' | 'STAT'

-- for now we save the mark edit status and message color in one block
-- (INI_STUFF topic in the ini file)

   call setprofile( app_hini, appname, INI_DTCOLOR, vDESKTOPColor)
   call setprofile( app_hini, appname, INI_STUFF, .textcolor .markcolor vstatuscolor vmessagecolor)
   -- Note: vmodifiedstatuscolor is still missing.

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
   dprintf( 'SaveWindowSize', 'arg(1) = ['arg(1)']')
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
   Text    = 'Enter leftma rightma parma (default: 1 1599 1)'
   IniValue = queryprofile( app_hini, 'EPM', INI_MARGINS)
   IniValue = strip(IniValue)
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/~Cancel',  -- max. 4 buttons
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
   Text    = 'Enter a single number for a fixed tab interval, or a list of explicit tab positions. (default: 8)'
   IniValue = queryprofile( app_hini, 'EPM', INI_TABS)
   IniValue = strip(IniValue)
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/~Cancel',  -- max. 4 buttons
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



