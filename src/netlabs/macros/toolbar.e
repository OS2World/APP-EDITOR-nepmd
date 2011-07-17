/****************************** Module Header *******************************
*
* Module Name: toolbar.e
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

; Moved from STDCTRL.E

; ---------------------------------------------------------------------------
;  load_actions
;     This defc is called by the etke*.dll to generate the list of actions
;     for UCMENUS in the hidden file called actlist.
;     If called with a pointer parameter a buffer is create in which
;     the list of actions are placed. If called without any parameter
;     the actlist file is generated.
;     John Ponzo 8/93
;     Optimized by LAM

defc load_actions
   universal ActionsList_FileID

;Keep track of the active file
   getfileid ActiveFileID

;See if the actlist file is already loaded, if not load it
;; getfileid ActionsList_FileID, 'actlist'

   if ActionsList_FileID <> '' then  -- Make sure it's still loaded.
      rc = 0
      display -2
      activatefile ActionsList_FileID
      display 2
      if rc=-260 then ActionsList_FileID = ''; endif
   endif

   if ActionsList_FileID == '' then  -- Must create
      'xcom e /c actlist'
      if rc<>-282 then  -- sayerror('New file')
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      getfileid ActionsList_FileID
      .visible = 0

;load the actions.lst file which contain the names of all the EX modules
;that have UCMENU actions defined.
      getfileid ActionsEXModuleList_FileID, 'actions.lst'

      if ActionsEXModuleList_FileID == '' then
         findfile destfilename, 'actions.lst', '','D'
         if rc=-2 then  -- "File not found"
            'xcom e /c actions.lst'
            deleteline 1
            .modify = 0
         else
            'e' destfilename
            if rc then
               sayerror ERROR__MSG rc '"'destfilename'"' sayerrortext(rc)
               return
            endif
         endif
         getfileid ActionsEXModuleList_FileID
;;       ActionsEXModuleList_FileID.visible = 0
         quit_list = 1
      else
         quit_list = 0
      endif
;load all the EX Modules in actlist.lst, and call EX modules
;actionlist defc.
      for i = 1 to ActionsEXModuleList_FileID.last
         getline  exmodule, i, ActionsEXModuleList_FileID
         not_linked = linked(exmodule) < 0
         if not_linked then
            link exmodule
            if rc<0 then
               sayerror 'Load_Actions:  'sayerrortext(rc) '-' exmodule
               not_linked = 0  -- Don't try to unlink it.
            endif
         endif
         exmodule'_actionlist'
         if not_linked then
            'unlink' exmodule
         endif
      endfor
      if quit_list then
         activatefile ActionsEXModuleList_FileID
         'quit'
      endif
   endif  -- ActionsList_FileID == ''

;if called with a parameter send EFRAME_ACTIONSLIST message to the frame
;of the edit window. mp1 is a buffer containing all of the actions loaded
;in the hidden file actlist.
   if arg(1)  then
      activatefile ActionsList_FileID
      buflen = filesize() + .last + 1
      bufhandle = buffer(CREATEBUF, '', buflen, 1)
      if not bufhandle then sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC; return; endif
      call buffer(PUTBUF, bufhandle, 1, ActionsList_FileID.last, NOHEADER+FINALNULL+APPENDCR)
      if word(arg(1),1) <> 'ITEMCHANGED' then
         windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5913, bufhandle, arg(1))
      else
         windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5918, bufhandle, subword(arg(1),2))
      endif
   endif
   activatefile ActiveFileID

; ---------------------------------------------------------------------------
;  ExecuteAction
;     This defc is called to resolve UCMENU actions.
;     It is called with the first parameter being the action name,
;     and the second parameter being an action sub-op.
;     If the action (Which is a Defc) is not defined the actions list
;     is generated in order to try resolving the defc.

defc ExecuteAction
   universal ActionsList_FileID
   parse arg DefcModule DefcName DefcParameter
;sayerror 'executeaction: "'arg(1)'"'

   if DefcName='*' then
      DefcParameter
   else
      if defcmodule<>'*' then
         if linked(defcmodule) < 0 then
            link defcmodule
         endif
      endif
      if isadefc(DefcName) then
;sayerror 'executeaction: executing cmd "'DefcName'" with parm "'DefcParameter'"'
         DefcName DefcParameter
      else
        sayerror UNKNOWN_ACTION__MSG DefcName
      endif
   endif

compile if 0 -- No longer used ----------------------------------------------

defc load_toolbar
   call list_toolbars(LOAD_TOOLBAR__MSG, SELECT_TOOLBAR__MSG, 7000, 5916)

defproc list_toolbars(list_title, list_prompt, help_panel, msgid)
   universal app_hini, toolbar_loaded
;  l = dynalink32('PMSHAPI',
;                 '#115',               -- PRF32QUERYPROFILESTRING
;                 atol(app_hini)    ||  -- HINI_PROFILE
;                 address(App)      ||  -- pointer to application name
;                 atol(0)           ||  -- Key name is NULL; returns all keys
;                 atol(0)           ||  -- Default return string is NULL
;                 address(inidata)  ||  -- pointer to returned string buffer
;                 atol(1600), 2)        -- max length of returned string
   inidata = queryprofile(app_hini, INI_UCMENU_APP, '')
   l = length(inidata)

   if not l then sayerror NO_TOOLBARS__MSG; return; endif
   getfileid startfid
   'xcom e /c /q tempfile'
   if rc<>-282 then  -- sayerror('New file')
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   .autosave = 0
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   do while inidata<>''
      parse value inidata with menuname \0 inidata
      insertline menuname, .last+1
   enddo
   if browse_mode then call browse(1); endif  -- restore browse state
   if listbox_buffer_from_file(startfid, bufhndl, noflines, usedsize) then return; endif
   parse value listbox( list_title,
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                        '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                        1,
                        5,
                        min(noflines,12),
                        0,
                        gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(help_panel) ||
                        list_prompt) with button 2 menuname \0
   call buffer(FREEBUF, bufhndl)
   if button<>\1 then return; endif
   call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), msgid, app_hini, put_in_buffer(menuname))
   if msgid = 5916 then
      toolbar_loaded = menuname
   endif

defc delete_toolbar
   call list_toolbars(DELETE_TOOLBAR__MSG, SELECT_TOOLBAR__MSG, 7001, 5919)

compile endif  -- 0 ---------------------------------------------------------

; ---------------------------------------------------------------------------
defc save_toolbar
   universal app_hini, appname
   universal toolbar_loaded
   tb = toolbar_loaded
   if tb=\1 then
      tb=''
   endif
   parse value entrybox(SAVEBAR__MSG,'/'SAVE__MSG'/'Cancel__MSG'/'Help__MSG'/',tb,'',200,
          atoi(1) || atoi(7010) || gethwndc(APP_HANDLE) ||
          SAVEBAR_PROMPT__MSG) with button 2 menuname \0
   if button <> \1 then return; endif
   if menuname='' then
      sayerror NOTHING_ENTERED__MSG
      return
;     menuname = 'Default'
;     call setprofile(app_hini, appname, INI_DEF_TOOLBAR, '')
   endif
   call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5915, app_hini, put_in_buffer(menuname))
   toolbar_loaded = menuname

; ---------------------------------------------------------------------------
defc loaddefaulttoolbar
   universal activeucmenu, toolbar_loaded
   if activeucmenu = 'Toolbar' then  -- Already used, delete it to be safe.
      deletemenu activeucmenu
   else
      activeucmenu = 'Toolbar'
   endif
 compile if defined(MY_DEFAULT_TOOLBAR_FILE) & not VANILLA -- Primarily for NLS support...
   include MY_DEFAULT_TOOLBAR_FILE  -- Should contain only lines like the following:
 compile elseif WANT_TINY_ICONS
;                             # Button text # Button bitmap # command # parameters # .ex file
   buildsubmenu activeucmenu,  1, "#Add File#1131#a_Add_File##sampactn", '', 0, 0  -- EPM.bmp
   buildsubmenu activeucmenu,  2, "#Save#1130#a_save##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  3, "#Print#1133#a_print##sampactn", '', 0, 0  -- print.bmp
   buildsubmenu activeucmenu,  4, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu,  5, "#MonoFont#1151#a_MonoFont##sampactn", '', 0, 0  -- monofont.bmp
   buildsubmenu activeucmenu,  6, "#Style#1147#apply_style##stylebut", '', 0, 0  -- style.bmp
   buildsubmenu activeucmenu,  7, "#UnStyle#1148#remove_style##stylebut", '', 0, 0  -- style.bmp
   buildsubmenu activeucmenu,  8, "#Attribs#1152#fonts_attribs##fonts", '', 0, 0  -- attribs.bmp
   buildmenuitem activeucmenu,  8, 80, "#Bold#1124#fonts_bold##fonts", '', 0, 0  -- bold.bmp
   buildmenuitem activeucmenu,  8, 81, "#Italic#1123#fonts_italic##fonts", '', 0, 0  -- italic.bmp
   buildmenuitem activeucmenu,  8, 82, "#Under#1122#fonts_underline##fonts", '', 0, 0  -- undrline.bmp
   buildmenuitem activeucmenu,  8, 83, "#Strike#1121#fonts_strikeout##fonts", '', 0, 0  -- strikout.bmp
   buildmenuitem activeucmenu,  8, 84, "#Outline#1120#fonts_outline##fonts", '', 0, 0  -- outline.bmp
   buildsubmenu activeucmenu,  9, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu, 10, "#Search#1138#a_SearchDlg##sampactn", '', 0, 0  -- search.bmp
   buildsubmenu activeucmenu, 11, "#Undo#1134#a_UndoDlg##sampactn", '', 0, 0  -- undo.bmp
   buildsubmenu activeucmenu, 12, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu, 13, "#Shell#1153#a_Shell##sampactn", '', 0, 0  -- epmshell.bmp
 compile else
;                             # Button text # Button bitmap # command # parameters # .ex file
   buildsubmenu activeucmenu,  1, "#Add File#1116#a_Add_File##sampactn", '', 0, 0  -- EPM.bmp
   buildsubmenu activeucmenu,  2, "#Save#1117#a_save##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  3, "#Print#1113#a_print##sampactn", '', 0, 0  -- print.bmp
   buildsubmenu activeucmenu,  4, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu,  5, "#MonoFont#1106#a_MonoFont##sampactn", '', 0, 0  -- monofont.bmp
   buildsubmenu activeucmenu,  6, "#Style#1112#apply_style##stylebut", '', 0, 0  -- style.bmp
   buildsubmenu activeucmenu,  7, "#UnStyle#1128#remove_style##stylebut", '', 0, 0  -- style.bmp
   buildsubmenu activeucmenu,  8, "#Attribs#1119#fonts_attribs##fonts", '', 0, 0  -- attribs.bmp
   buildmenuitem activeucmenu,  8, 80, "#Bold#1124#fonts_bold##fonts", '', 0, 0  -- bold.bmp
   buildmenuitem activeucmenu,  8, 81, "#Italic#1123#fonts_italic##fonts", '', 0, 0  -- italic.bmp
   buildmenuitem activeucmenu,  8, 82, "#Under#1122#fonts_underline##fonts", '', 0, 0  -- undrline.bmp
   buildmenuitem activeucmenu,  8, 83, "#Strike#1121#fonts_strikeout##fonts", '', 0, 0  -- strikout.bmp
   buildmenuitem activeucmenu,  8, 84, "#Outline#1120#fonts_outline##fonts", '', 0, 0  -- outline.bmp
   buildsubmenu activeucmenu,  9, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu, 10, "#Search#1115#a_SearchDlg##sampactn", '', 0, 0  -- search.bmp
   buildsubmenu activeucmenu, 11, "#Undo#1114#a_UndoDlg##sampactn", '', 0, 0  -- undo.bmp
   buildsubmenu activeucmenu, 12, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu, 13, "#Shell#1118#a_Shell##sampactn", '', 0, 0  -- epmshell.bmp
 compile endif -- WANT_TINY_ICONS

;  buildsubmenu activeucmenu,  1, "#Open#1102#a_Add_File##sampactn", '', 0, 0  -- EPM.bmp
;  buildsubmenu activeucmenu,  2, "#Print#1113#a_print##sampactn", '', 0, 0
;  buildsubmenu activeucmenu,  3, "#Shell#1109#a_Shell##sampactn", '', 0, 0  -- epmshell.bmp
;  buildsubmenu activeucmenu,  4, '', '', 16401, 0  -- MIS_SPACER
;  buildsubmenu activeucmenu,  5, "#Style#1112#apply_style##stylebut", '', 0, 0  -- style.bmp
;  buildsubmenu activeucmenu,  6, "#MonoFont#1106#a_MonoFont##sampactn", '', 0, 0  -- monofont.bmp
;  buildsubmenu activeucmenu,  7, "#Reflow#1107#reflow_prompt##reflow", '', 0, 0  -- reflow.bmp
;  buildsubmenu activeucmenu,  8, '', '', 16401, 0  -- MIS_SPACER
;  buildsubmenu activeucmenu,  9, "#Msgs#1100#a_Messages##sampactn", '', 0, 0  -- info.bmp
;  buildsubmenu activeucmenu, 10, "#List Ring#1110#a_List_Ring##sampactn", '', 0, 0  -- ringlist.bmp

;; buildsubmenu activeucmenu, 11, "#Add New#1101#a_Add_New##sampactn", '', 0, 0  -- EPMadd.bmp
;; buildsubmenu activeucmenu, 12, "#NewWind#1103#a_NewWindow##sampactn", '', 0, 0  -- newwindw.bmp
;; buildsubmenu activeucmenu, 13, "#Settings#1104#a_Settings##sampactn", '', 0, 0  -- settings.bmp
;; buildsubmenu activeucmenu, 14, "#Time#1105#a_Time##sampactn", '', 0, 0  -- clock.bmp
;; buildsubmenu activeucmenu, 15, "#Jot#1108#jot_a_note##jot", '', 0, 0  -- idea.bmp
;; buildsubmenu activeucmenu, 16, "#Tree#1111#tree_action##tree", '', 0, 0  -- tree.bmp
;; buildsubmenu activeucmenu, 17, "#KwdHilit#kwdhilit.bmp#a_togl_hilit##sampactn", '', 0, 0

   showmenu activeucmenu, 3
   toolbar_loaded = \1

; ---------------------------------------------------------------------------
; What is this command for? It is not called by anything.
defc deletetemplate
   universal app_hini
   parse arg template_name
;  if template_name='' then
;     template_name = 'Default'
;  endif
   call windowmessage(0, getpminfo(EPMINFO_EDITFRAME),
                      5919,
                      app_hini,
                      put_in_buffer(template_name))

; ---------------------------------------------------------------------------
compile if INCLUDE_STD_MENUS
defc toggle_toolbar
   universal toolbar_loaded
  compile if WANT_NODISMISS_MENUS & not defined(STD_MENU_NAME)
   fon = queryframecontrol(EFRAMEF_TOOLBAR)  -- Query now, since toggling is asynch.
  compile endif  -- WANT_NODISMISS_MENUS
   'toggleframe' EFRAMEF_TOOLBAR
  compile if WANT_NODISMISS_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 430, 8192, fon)
  compile endif  -- WANT_NODISMISS_MENUS
   if not toolbar_loaded then
      'default_toolbar'
   endif
compile endif  -- INCLUDE_STD_MENUS

; ---------------------------------------------------------------------------
defc default_toolbar
   universal app_hini, appname, toolbar_loaded
compile if WPS_SUPPORT
   universal wpshell_handle
   if wpshell_handle then
      newtoolbar = peekz(peek32(wpshell_handle, 80, 4))
      if newtoolbar='' then
         newtoolbar = \1
      endif
      if toolbar_loaded <> newtoolbar then
         toolbar_loaded = newtoolbar
         if toolbar_loaded = \1 then
            'loaddefaulttoolbar'
         else
            call windowmessage(0, getpminfo(EPMINFO_EDITFRAME),
                               5916,
                               app_hini,
                               put_in_buffer(toolbar_loaded))
         endif
      else  -- Else we're already set up; make sure toolbar is turned on
         'toggleframe' EFRAMEF_TOOLBAR 1
      endif
   else
compile endif
      def_tb = queryprofile(app_hini, appname, INI_DEF_TOOLBAR)
;     if def_tb = '' then def_tb = 'Default'; endif
      if def_tb <> '' then
         newcmd= queryprofile(app_hini, INI_UCMENU_APP, def_tb)
      else
         newcmd = ''
      endif
      if newcmd<>'' then
         toolbar_loaded = def_tb
         call windowmessage(0, getpminfo(EPMINFO_EDITFRAME),
                            5916,
                            app_hini,
                            put_in_buffer(toolbar_loaded))
      else
         'loaddefaulttoolbar'
      endif
compile if WPS_SUPPORT
   endif
compile endif

; ---------------------------------------------------------------------------
; From EPMSMP\LOADTB.E
; Command to load a previously-saved toolbar, by Larry Margolis

const
   NO_TOOLBARS__MSG =     'No saved toolbars from which to select.'
   LOAD_TOOLBAR__MSG =    'Load Toolbar'  -- Dialog box title
   SELECT_TOOLBAR__MSG =  'Select a Toolbar menu set'
   TOOLBAR_UNKNOWN__MSG = 'Toolbar unknown:  '

defc load_toolbar
   universal app_hini, toolbar_loaded
   TB_name = arg(1)
   if TB_name='' then  -- List all toolbars
      inidata = queryprofile(app_hini, INI_UCMENU_APP, '')
      if not length(inidata) then sayerror NO_TOOLBARS__MSG; return; endif
      getfileid startfid
      'xcom e /c /q tempfile'
      if rc<>-282 then  -- sayerror('New file')
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      .autosave = 0
      browse_mode = browse()     -- query current state
      if browse_mode then call browse(0); endif
      do while inidata<>''
         parse value inidata with menuname \0 inidata
         insertline menuname, .last+1
      enddo
      if browse_mode then call browse(1); endif  -- restore browse state
      if listbox_buffer_from_file(startfid, bufhndl, noflines, usedsize) then return; endif
      parse value listbox(LOAD_TOOLBAR__MSG, \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                          '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,1,5,min(noflines,12),0,
                          gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(7000) ||
                          SELECT_TOOLBAR__MSG) with button 2 TB_name \0
      call buffer(FREEBUF, bufhndl)
      if button<>\1 then return; endif
   else
      inidata = queryprofile(app_hini, INI_UCMENU_APP, TB_name)
      if inidata = '' then
         sayerror TOOLBAR_UNKNOWN__MSG || TB_name
         return
      endif
   endif
   call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5916, app_hini, put_in_buffer(TB_name))
   toolbar_loaded = menuname

; ---------------------------------------------------------------------------
; From: Larry Margolis (margoli@ibm.net)
; Subject: Re: change EPM toolbar dynamically
; Newsgroups:comp.os.os2.programmer.tools
;
; Well, here's some sample code if you want to create the toolbar
; completely from the macros:
compile if 0

defc loadtb    -- I don't like the built-in default; here's mine:
   universal activeucmenu, toolbar_loaded
   if activeucmenu = 'Toolbar' then  -- Already used, delete it to be safe.
      deletemenu activeucmenu
   else
      activeucmenu = 'Toolbar'
   endif
   buildsubmenu activeucmenu,  1, "#Msgs#1100#a_Messages##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  2, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu,  3, "#Add New#1101#a_Add_New##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  4, "#Open#1102#a_Open_empty##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  5, "#NewWind#1103#a_NewWindow##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  6, "#Settings#1104#a_Settings##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  7, "#Shell#1109#a_Shell##sampactn", '', 0, 0
   buildsubmenu activeucmenu,  8, '', '', 16401, 0  -- MIS_SPACER
   buildsubmenu activeucmenu,  9, "#KwdHilit#1126#a_togl_hilit##sampactn", '', 0, 0
   buildsubmenu activeucmenu, 10, "#MonoFont#1106#a_MonoFont##sampactn", '', 0, 0
   showmenu activeucmenu, 3
   toolbar_loaded = \1  -- "Built-in"

defc addtb  -- Sample command to add a button to the toolbar defined above
   universal activeucmenu, toolbar_loaded
   activeucmenu = 'Toolbar'
   buildsubmenu activeucmenu, 11, "#OS/2 win#os2win.bmp#cmd_os2win##commands", '', 0, 0
   showmenu activeucmenu, 3

defc deltb  -- Sample command to delete the Settings button from the toolbar defined above
   universal activeucmenu, toolbar_loaded
   activeucmenu = 'Toolbar'
   deletemenu activeucmenu, 7, 0, 0
   showmenu activeucmenu, 3

compile endif  -- 0

