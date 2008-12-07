/****************************** Module Header *******************************
*
* Module Name: toolbar.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: toolbar.e,v 1.22 2008-12-07 21:45:44 aschn Exp $
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

; Used terms:
;    default toolbar  = toolbar name from NEPMD.INI (maybe different from
;                       the active toolbar)
;    standard toolbar = toolbar of standard EPM = built-in toolbar

; ---------------------------------------------------------------------------

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'TOOLBAR.E'

const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
-- This provides a simple way to omit all user includes, for problem resolution.
-- If you set VANILLA to 1 in MYCNF.E, then no MY*.E files will be included.
compile if not defined(VANILLA)
   VANILLA = 0
compile endif

-- Use the normal-sized or the tiny icons for the built-in toolbar?
compile if not defined(WANT_TINY_ICONS)
   WANT_TINY_ICONS = 0
compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   include 'stdconst.e'

   EA_comment 'This defines toolbar macros.'
compile endif

; ---------------------------------------------------------------------------
; This defc is called by the etke*.dll to generate the list of actions for
; UCMENUS in the hidden file called .actlist.
; If called with a pointer parameter a buffer is created in which the list
; of actions are placed (used for toolbar buffet creation).
; If called without any parameter the .actlist file is generated.
; John Ponzo 8/93
; Optimized by LAM
;
; This is only called on creating or modifying a toolbar button.
; A button action itself is saved in the toolbar data together with the
; .ex filename where it is defined. On execution the ExecuteAction command
; is called, that links the .ex file when the action is undefined.
defc load_actions
   universal ActionsList_FileID

   -- Keep track of the active file
   getfileid ActiveFileID

   -- See if the actlist file is already loaded, if not load it
;; getfileid ActionsList_FileID, '.actlist'

   if ActionsList_FileID <> '' then  -- Make sure it's still loaded.
      rc = 0
      display -2
      activatefile ActionsList_FileID
      display 2
      if rc = -260 then ActionsList_FileID = ''; endif
   endif

   if ActionsList_FileID == '' then  -- Must create
      'xcom e /c .actlist'
      if rc <> -282 then  -- sayerror('New file')
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      getfileid ActionsList_FileID
      .visible = 0

      -- Load the actions.lst file which contains the names of all the EX modules
      -- that have UCMENU actions defined.
      getfileid ActionsEXModuleList_FileID, 'actions.lst'

      if ActionsEXModuleList_FileID == '' then
         findfile destfilename, 'actions.lst', '','D'
         if rc = -2 then  -- "File not found"
            'xcom e /c actions.lst'
            deleteline 1
            .modify = 0
         else
            'xcom e' destfilename
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
      -- Load all the EX Modules in actlist.lst, and call EX modules
      -- actionlist defc.
      for i = 1 to ActionsEXModuleList_FileID.last
         getline Line, i, ActionsEXModuleList_FileID
         StrippedLine = strip(Line)
         -- Ignore comments, lines starting with ';' at column 1 are comments
         if substr( Line, 1, 1) = ';' then
            iterate
         -- Ignore empty lines
         elseif StrippedLine = '' then
            iterate
         endif
         ExFile = StrippedLine
         -- Strip extension
         if rightstr( upcase(ExFile), 3) = '.EX' then
            ExFile = substr( ExFile, 1, length(ExFile) - 3)
         endif
         not_linked = linked(ExFile) < 0
         if not_linked then
            link ExFile  -- without msg
            linkrc = rc
            if rc < 0 then
               sayerror 'Load_Actions:  'sayerrortext(rc) '-' ExFile
               not_linked = 0  -- Don't try to unlink it.
            endif
         endif
         ExFile'_actionlist'
         if not_linked then
            -- Standard unlink needs full pathname if .ex file not in current path.
            -- This is fixed now for def unlink, not for the statement.
            'unlink' ExFile
            unlinkrc = rc
         endif
      endfor
      if quit_list then
         activatefile ActionsEXModuleList_FileID
         'xcom quit'
      endif
   endif  -- ActionsList_FileID == ''

   -- If called with a parameter send EFRAME_ACTIONSLIST message to the frame
   -- of the edit window. mp1 is a buffer containing all of the actions loaded
   -- in the hidden file actlist.
   -- Called with an arg when the toolbar buffet shall be created.
   if arg(1) then
      activatefile ActionsList_FileID
      buflen = filesize() + .last + 1
      bufhandle = buffer(CREATEBUF, '', buflen, 1)
      if not bufhandle then
         sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC
         return
      endif
      call buffer( PUTBUF, bufhandle, 1, ActionsList_FileID.last, NOHEADER + FINALNULL + APPENDCR)
      if word( arg(1), 1) <> 'ITEMCHANGED' then
         windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                        5913,
                        bufhandle,
                        arg(1))
      else
         windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                        5918,
                        bufhandle,
                        subword( arg(1), 2))
      endif
   endif

   activatefile ActiveFileID

; ---------------------------------------------------------------------------
; Generic macro for adding toolbar definitions easily. Here is an example
; for its usage:
;    defc TB_Shell
;       ExFile  = 'newbar'      -- Name of the .ex file where this defc is defined.
;       Action  = 'TB_Shell'    -- Name of the defc. Appears in the list of selectable actions.
;       Command = 'Shell'       -- Command to be executed after release of the button.
;       Prompt  = SHELL_PROMPT  -- Prompt, that appears on the messageline, while the button is pressed.
;       Help    = ''            -- Additional prompt or a help panel id for F1 action while the button is pressed.
;       Title   = ''            -- Title of the help message box (if no help panel id).
;       call ToolbarAction( arg(1), Exfile, Action, Command, Prompt, Help, Title)
; Additionally, a line must be added to
;    defc <ExFile>_actionlist
;       'TB_Shell ACTIONLIST'
; to make that definition appear in the listbox, where an action can be
; selected from.
defproc ToolbarAction
   universal ActionsList_FileID
   Exfile  = arg(2)
   Action  = arg(3)
   Command = arg(4)
   Prompt  = arg(5)
   Help    = arg(6)
   Title   = arg(7)
   if Title = '' then
      Title =  Action 'from "'upcase( ExFile)'"'
   endif
   if upcase( arg(1)) = 'ACTIONLIST' then
      insertline \1''Action''\1''Prompt''\1''ExFile''\1,
                 ActionsList_FileID.last + 1, ActionsList_FileID
   else
      if arg(1) = 'S' then
         sayerror 0
         Command
      elseif arg(1) = 'I' then
        'SayHint' Prompt
      elseif arg(1) = 'H' then
         if words( Help) = 1 & isnum( Help) then
            'helpmenu' Help
         else
            call winmessagebox( Title,
                                Prompt''Help,
                                MB_OK + MB_INFORMATION + MB_MOVEABLE)
         endif
      endif
   endif

; ---------------------------------------------------------------------------
; This defc is called to resolve UCMENU actions.
; It is called with the first parameter being the action name, and the
; second parameter being an action sub-op.
; If the action (Which is a Defc) is not defined the actions list is
; generated in order to try resolving the defc.
defc ExecuteAction
   universal ActionsList_FileID
   parse arg DefcModule DefcName DefcParameter
;sayerror 'executeaction: "'arg(1)'"'

   if DefcName = '*' then
      DefcParameter
   else
      if defcmodule <> '*' then
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

; ---------------------------------------------------------------------------
; Save active toolbar name to ini. If arg is specified, use that name.
; Syntax: call SetDefaultToolbar( [<toolbar_name>])
; Use NEPMD.INI now, because Newbar's .bmps are not available for standard
; EPM. In order to make standard EPM open with a valid toolbar, it should
; better keep the old setting alone.
defproc SetDefaultToolbar
   universal nepmd_hini
   universal toolbar_loaded
   BarName = arg(1)
   if BarName = '' then  -- use current name if no name specified
      BarName = toolbar_loaded
   endif
   if wordpos( BarName, \1' STANDARD' ) then
      BarName = ''  -- delete ini key for default toolbar
   endif
   KeyPath = '\NEPMD\User\Toolbar\Name'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, BarName)
   return

; ---------------------------------------------------------------------------
; Query saved toolbar name from ini and set universal var toolbar_loaded.
; Return Barname, but not required, because the universal var is set.
; Syntax: BarName = GetDefaultToolbar() or call GetDefaultToolbar()
; Use NEPMD.INI now, because Newbar's .bmps are not available for standard
; EPM. In order to make standard EPM open with a valid toolbar, it should
; better keep the old setting alone.
; Returns '' if saved toolbar name is the standard toolbar.
defproc GetDefaultToolbar
   universal nepmd_hini
   universal toolbar_loaded
   KeyPath = '\NEPMD\User\Toolbar\Name'
   StandardName = 'STANDARD'
   BarName = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if BarName = '' | BarName = StandardName then
      toolbar_loaded = \1
   else
      toolbar_loaded = BarName
   endif
   return BarName

; ---------------------------------------------------------------------------
; Save current toolbar to EPM.INI.
; Syntax: SaveToolbar [<bar_name>]
; Default <bar_name> is current name.
; This is also used by the toolbar's context menu item "Save as...".
defc save_toolbar, SaveToolbar
   universal app_hini
   universal appname
   universal toolbar_loaded
   BarName = strip( arg(1))
   if BarName = '' then
      tb = toolbar_loaded
      if tb = \1 then  -- \1 is defined to represent the built-in toolbar
         tb = ''
      endif
      parse value entrybox( SAVEBAR__MSG,
                            '/'SAVE__MSG'/'Cancel__MSG'/'Help__MSG'/',
                            tb,
                            '', 200,
                            atoi(1) || atoi(7010) || gethwndc( APP_HANDLE) ||
                            SAVEBAR_PROMPT__MSG) with button 2 BarName \0
      if button <> \1 then
         return
      endif
      if BarName = '' then
         sayerror NOTHING_ENTERED__MSG
         return
      endif
   endif
   call windowmessage( 0, getpminfo( EPMINFO_EDITFRAME),
                       5915,
                       app_hini,
                       put_in_buffer( BarName))
   toolbar_loaded = BarName

; ---------------------------------------------------------------------------
; Delete a toolbar.
defc deletetemplate, DeleteToolbar
   universal app_hini
   universal nepmd_hini
   universal toolbar_loaded
   KeyPath = '\NEPMD\User\Toolbar\Name'
   StandardName = 'STANDARD'

   parse arg BarName
   call windowmessage(0, getpminfo(EPMINFO_EDITFRAME),
                      5919,
                      app_hini,
                      put_in_buffer( BarName))
   if BarName = toolbar_loaded then  -- delete the selected name, too
      call NepmdWriteConfigValue( nepmd_hini, KeyPath, StandardName)
   endif

; ---------------------------------------------------------------------------
; Activate built-in toolbar.
; LoadDefaultToolbar should be avoided (default means from ini)!
defc LoadDefaultToolbar, LoadStandardToolbar
   universal activeucmenu
   universal toolbar_loaded
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
; Activate last saved toolbar from EPM.INI.
defc default_toolbar, ReloadToolbar
   universal app_hini
   universal toolbar_loaded
   inidata = ''
   BarName = GetDefaultToolbar()  -- returns '' for standard toolbar
   if BarName <> '' then
      -- check if present, data is not used
      inidata = queryprofile( app_hini, INI_UCMENU_APP, BarName)
      -- If not found in ini, try to import it from a .bar file
      if inidata = '' then
         barfile = ''
         findfile barfile, BarNAme'.bar', 'EPMBARPATH'
         if barfile > '' then
            'ImportToolbar' barfile','BarName
            if rc = 0 then  -- if data of BarName'.bar' successfully written to ini
               inidata = 1
            endif
         endif
      endif
   endif
   if inidata = '' then
      'LoadStandardToolbar'
   else
      toolbar_loaded = BarName
      call windowmessage( 0, getpminfo( EPMINFO_EDITFRAME),
                          5916,
                          app_hini,
                          put_in_buffer( toolbar_loaded))
   endif

; ---------------------------------------------------------------------------
; Syntax: LoadToolbar [NOSAVE] [<toolbar_name>]
; If <toolbar_name> is not specified, then a ListBox with all previously
; imported toolbar names is opened. "Imported" means: their binary data
; must be written to the ini.
; If NOSAVE is specified, then the name will not be saved in ini as the new
; default toolbar. This is used for mode settings.
; Todo: merge this with defc toggle_toolbar.
; From EPMSMP\LOADTB.E
; Command to load a previously-saved toolbar, by Larry Margolis

const
   NO_TOOLBARS__MSG =     'No saved toolbars from which to select.'
   LOAD_TOOLBAR__MSG =    'Load Toolbar'  -- Dialog box title
   SELECT_TOOLBAR__MSG =  'Select a Toolbar menu set'
   TOOLBAR_UNKNOWN__MSG = 'Toolbar unknown:  '

defc load_toolbar, LoadToolbar
   universal app_hini
   universal toolbar_loaded
   universal nepmd_hini
   universal appname

   KeyPath = '\NEPMD\User\Toolbar\Name'
   StandardName = 'STANDARD'
   LoadedName = toolbar_loaded
   if toolbar_loaded = \1 then
      LoadedName = StandardName
   endif

   BarName = arg(1)
   wp = wordpos( 'NOSAVE', upcase( BarName))
   fSave = 1
   if wp then
      fSave = 0
      BarName = delword( BarName, wp, 1)
   endif

   if BarName = '' then  -- List all toolbars
      inidata = queryprofile( app_hini, INI_UCMENU_APP, '')
      if not length( inidata) then
         sayerror NO_TOOLBARS__MSG
         return
      elseif length( inidata) > 1599 then
         sayerror 'Ini key data longer than 1599 chars. Cannot handle that by an E string'
         return
      endif
      getfileid startfid

      'xcom e /c /q tempfile'
      if rc <> -282 then  -- sayerror('New file')
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      .autosave = 0
      browse_mode = browse()  -- query current state
      if browse_mode then
         call browse(0)
      endif
      -- Write next string to tempfile
      do while inidata <> ''
         parse value inidata with BarName \0 inidata
         insertline BarName, .last + 1
      enddo
      -- Sort
      if .last > 2 then
         getfileid fileid
         call sort( 2, .last, 1, 40, fileid, 'I')
      endif
      -- Append name for standard toolbar as last
      insertline StandardName, .last + 1
      -- Find current name in list to select it in listbox
      Selected = 1
      do l = 2 to .last  -- first line is always empty for a newly created file
         next = strip( textline(l))
         if (next > '') & (next = LoadedName) then
            Selected = l - 1
            leave
         endif
      enddo
      if browse_mode then
         call browse(1)       -- restore browse state
      endif

      if listbox_buffer_from_file( startfid,
                                   bufhndl,
                                   noflines,
                                   usedsize) then
         return
      endif

      --Title = LOAD_TOOLBAR__MSG
      Title = 'Select a toolbar'
      --Text  = SELECT_TOOLBAR__MSG
      Text  = 'Current toolbar: 'LoadedName
      --HelpPanel = 7000
      HelpPanel = 0
      parse value listbox( Title,
                           \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                           '/'OK__MSG'/~Delete/'CANCEL__MSG,  --'/'OK__MSG'/'CANCEL__MSG'/'HELP__MSG,
                           0, 0,
                           min( noflines, 12), 0,
                           gethwndc(APP_HANDLE) || atoi(Selected) || atoi(1) || atoi(HelpPanel) ||
                           Text) with button 2 BarName \0
      call buffer( FREEBUF, bufhndl)

      if button = \2 then  -- Delete
         'DeleteToolbar' BarName
         'postme LoadToolbar'  -- Select a new one or delete another
         return
      endif
      if button <> \1 then  -- Delete or Cancel
         return
      endif

   else
      inidata = queryprofile( app_hini, INI_UCMENU_APP, BarName)
      if inidata = '' then
         sayerror TOOLBAR_UNKNOWN__MSG || BarName
         return
      endif
   endif

   if BarName = StandardName then
      'LoadStandardToolbar'
      toolbar_loaded = \1
   else
      call windowmessage( 0, getpminfo( EPMINFO_EDITFRAME),
                          5916,
                          app_hini,
                          put_in_buffer( BarName))
      toolbar_loaded = BarName
   endif

   if fSave then
      call NepmdWriteConfigValue( nepmd_hini, KeyPath, BarName)
      -- Save toolbar activation bit
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 15)' 1 'subword( old, 17)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
; Return current setup string. Colors are always reset.
defproc GetToolbarSetup
   universal app_hini
   Setup = queryprofile( app_hini, 'UCMenu', 'ConfigInfo')
   -- count \1 values in tempstr
   rest = Setup
   startp = 1
   i = 1
   do forever
      p = pos( \1, rest, startp)
      if p = 0 then
         leave
      endif
      i = i + 1
      startp = startp + 1
   enddo
   fWriteDefaultString = (i < 7)
   if fWriteDefaultString then
      --Setup = \1'8'\1'32'\1'32'\1'8.Helv'\1'16777216'\1'16777216'\1  -- internal default if no entry in EPM.INI
      Setup = \1'56'\1'26'\1'26'\1'9.WarpSans'\1'16777216'\1'16777216'\1  -- new default if no entry in EPM.INI
      call setprofile( app_hini, 'UCMenu', 'ConfigInfo', Setup)
   endif
   -- Always reset background colors, because any other color then PM's
   -- default looks ugly and apparantly the determination of the
   -- resulting color is buggy.
   -- Note: background colors can be changed via the color palette.
   parse value Setup with \1 Style \1 Cx \1 Cy \1 TbFont \1 Color \1 ItemColor \1
   Setup = \1''Style\1''Cx\1''Cy\1''TbFont\1'16777216'\1'16777216'\1  -- always reset colors
   return Setup

; ---------------------------------------------------------------------------
; Write specified setup string to ini.
defproc SetToolbarSetup
   universal app_hini
   Setup = arg(1)
   call setprofile( app_hini, 'UCMenu', 'ConfigInfo', Setup)
   call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                       5921,
                       put_in_buffer( Setup), 0)
   return

; ---------------------------------------------------------------------------
; Toolbar style:
/*
fText     = not (Style bitand 16)
fAutosize = not (Style bitand 4)
fFlat     = not (Style bitand 8)
fScaleDel = (not (Style bitand 32)) and (not (Style bitand 96))
fScaleOr  = Style bitand 96
fScaleAnd = Style bitand 32

Value   Text    Auto    Delete  Or      And
-------------------------------------------

8       1       1       1
40      1       1                       1
104     1       1               1

12      1               1
44      1                               1
108     1                       1

24              1       1
56              1                       1
120             1               1

28                      1
60                                      1
124                             1


0   0x00  0000 0000  Delete
4   0x04  0000 0100  no Auto
8   0x08  0000 1000  Border
16  0x10  0001 0000  no Text
32  0x20  0010 0000  And
64  0x40  0100 0000  (unused)
96  0x60  0110 0000  Or = 32 + 64
*/

/*
defc testbitand
   Style = arg(1)

   fText     = not (Style bitand 16)
   fAutosize = not (Style bitand 4)
   fFlat     = not (Style bitand 8)
   fScaleDel = (not (Style bitand 32)) and (not (Style bitand 64))
   fScaleOr  = (Style bitand 32) and (Style bitand 64)
   fScaleAnd = (Style bitand 32) and (not (Style bitand 64))

   next = 16*(not fText) + 4*(not fAutosize) + 8*(not fFlat) +
          32*(fScaleAnd) + 96*(fScaleOr)

   sayerror Style'['next']: 'fText fAutosize fScaleDel fScaleOr fScaleAnd
*/

; ---------------------------------------------------------------------------
; Syntax: ToolbarSize [cx cy]
defc ToolbarSize
   parse value GetToolbarSetup() with \1 Style \1 Cx \1 Cy \1 SetupRest
   -- if executed with an arg
   arg1 = upcase( arg(1))
   if arg1 <> '' then
      parse value arg1 with newx newy
      if IsNum( newx) & IsNum( newy) then
         call SetToolbarSetup( \1''Style\1''newx\1''newy\1''SetupRest)
         return
      endif
   endif
   -- else open entrybox
   Title   = 'Configure toolbar button size'
   Text    = 'Enter x-size y-size (default: 26 26).'
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/'CANCEL__MSG,  -- max. 4 buttons
                         Cx Cy,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 then
      'ToolbarSize' NewValue
      return
   elseif Button = \2 then
      'ToolbarSize 26 26'
      return
   elseif Button = \3 then
      return
   endif

; ---------------------------------------------------------------------------
defc DragDrop_BAR
   'ImportToolbar' arg(1)
   if rc = 13 then  -- ERROR_INVALID_DATA
      'edit' arg(1)
   endif

; ---------------------------------------------------------------------------
; Used by ImportToolbar to select a .bar file.
defc ImportToolbarSelect
   BarFile = ''
   getfileid startfid
   'xcom e /c .barlist'
   if rc <> -282 then  -- -282 = sayerror("New file")
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   getfileid listfid
   browse_mode = browse()     -- query current state
   if browse_mode then
      call browse(0)
   endif
   .autosave = 0
   .visible = 0
   display -2

   RootDir = strip( Get_Env( 'NEPMD_ROOTDIR'), 't', '\')
   UserDir = strip( Get_Env( 'NEPMD_USERDIR'), 't', '\')
   do i = 1 to 3
      handle = GETNEXT_CREATE_NEW_HANDLE    -- handle must be reset before the search
      if i = 1 then
         UserFileMask = UserDir'\bar\*.bar'
         FileMask = UserFileMask
      elseif i = 2 then
         FileMask = RootDir'\netlabs\bar\*.bar'
      elseif i = 3 then
         FileMask = RootDir'\epmbbs\bar\*.bar'
      endif
      do forever
         next = NepmdGetNextFile( FileMask, address(handle))
         parse value next with 'ERROR:'rc1
         if rc1 = '' then
            insertline next, .last + 1
         else
            leave
         endif
      enddo
   enddo

   if browse_mode then
      call browse(1)  -- restore browse state
   endif
   display 2
   if not .modify then  -- Nothing added?
      'xcom quit'
      activatefile startfid
      sayerror 'No .bar files found'
      return
   endif

   if listbox_buffer_from_file( startfid, bufhndl, noflines, usedsize) then
      return
   endif
   HelpPanel = 0
   Title = 'Select a toolbar filename to import'
   parse value listbox( Title''copies( ' ', 20),
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                        '/~Import/~File dialog.../'Cancel__MSG,
                        0, 0,
                        min( noflines, 12), 0,
                        gethwndc(APP_HANDLE) || atoi(1) || atoi(1) ||
                        atoi(HelpPanel)) with Button 2 BarFile \0
   call buffer( FREEBUF, bufhndl)

   if Button = \1 then
      if BarFile > '' then
         'ImportToolbar' BarFile
      endif
   elseif Button = \2 then
      -- Syntax: filedlg title[, cmd[, filemask[, flags]]]
      'FileDlg' Title',ImportToolbar,'UserFileMask
      return
   endif

; ---------------------------------------------------------------------------
const
   TOOLBAR_SIG = \x9B\xA0\xC1\x53

; This command can be used for dragdrop processing of .bar files:
; If rc = 13, then the file should be loaded normally.
; Syntax: ImportToolbar <full_filename> [, <barname>]
defc ImportToolbar
   universal app_hini
   universal toolbar_loaded

   -- Get .bar file
   parse arg BarFile ',' BarName
   BarFile = strip( BarFile)
   BarName = strip( BarName)
   if BarFile = '' then
      'ImportToolbarSelect'
      return
   endif
   -- Append extension, if not specified
   if (BarFile > '' & upcase( rightstr( BarFile, 4)) <> '.BAR') then
      BarFile = BarFile'.bar'
   endif
   if NepmdFileExists( BarFile) then
      -- Since a REXX macro is used, no check for size is required anymore.
/*
      next = NepmdQueryPathInfo( BarFile, 'SIZE')
      parse value next with 'ERROR:'rc
      if rc = '' then
         Size = next
         if Size > 1599 then
            sayerror 'File longer than 1599 chars. Cannot import toolbar with this defc. Use the settings dialog instead.'
            return 24  -- ERROR_BAD_LENGTH
         endif
      endif
*/
   else
      return 2  -- ERROR_FILE_NOT_FOUND
   endif

   -- Read .bar file (to check for signature only)
   'xcom e /t /64 /bin /d' BarFile
   if rc = 0 then
      .visible = 0
      Bar = ''
      do l = 1 to .last
         Bar = Bar''textline(l)
         -- Check for signature
         if l = 1 then
            if not leftstr( Bar, length( TOOLBAR_SIG)) = TOOLBAR_SIG then
               'xcom quit'
               return 13  -- ERROR_INVALID_DATA
            endif
         else
         endif
      end
      'xcom quit'
   else
      return 5  -- ERROR_ACCESS_DENIED
   endif

   if BarName = '' then
      -- Get default name from file
      lp = lastpos( '\', BarFile)
      BarName = upcase( substr( BarFile, lp + 1, 1))lowcase( substr( BarFile, lp + 2))
      parse value BarName with BarName '.' rest

      -- Ask user for name
      Title = 'Import toolbar'
      Text  = 'Enter new toolbar name.'
      Text  = Text''copies( ' ', max( 50 - length(Text), 0))
      Entry = BarName
      parse value entrybox( Title,
                            '',
                            Entry,
                            0,
                            240,
                            atoi(1) || atoi(0) || atol(0) ||
                            Text) with button 2 next \0
      next = strip( next)
      if button = \1 & next <> '' then
         BarName = next
      else
         return 31  -- ERROR_GEN_FAILURE
      endif
   endif

;   IniFile = queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath')
   IniFile = NepmdQueryInstValue( 'INIT')
   IniAppl = 'UCMenu_Templates'

   -- Write toolbar data from BarFile to IniFile -> IniAppl -> BarName
   'rx toolbar IMPORT' IniFile IniAppl BarName BarFile

   if rc = 0 then
      toolbar_loaded = BarName
      -- Make it default
      --call setprofile( app_hini, 'EPM', 'DEFTOOLBAR', BarName)
      call SetDefaultToolbar()
      -- Activate
      'postme load_toolbar' BarName
      if rc = 0 then
         sayerror 'Toolbar "'BarName'" imported and activated'
      else
         sayerror 'Error. Toolbar "'BarName'" not activated. rc = 'rc
      endif
   else
      'Error. Toolbar "'BarName'" not imported. rc = 'rc
   endif

/*
   -- Save to ini
   call setprofile( app_hini, 'UCMenu_Templates', BarName, Bar)
   -- Make it default
   call setprofile( app_hini, 'EPM', 'DEFTOOLBAR', BarName)
   -- Activate
   'load_toolbar' BarName
   rc = 0
*/

; ---------------------------------------------------------------------------
defc ExportToolbar
   universal app_hini

   -- Save current toolbar to a tmp name first
   TmpBarName = '.TmpBar'
   call windowmessage( 0, getpminfo( EPMINFO_EDITFRAME),
                       5915,
                       app_hini,
                       put_in_buffer( TmpBarName))

   -- Execute the rest after ini key was saved
   'postme ExportToolbar2' TmpBarName

defc ExportToolbar2
   universal app_hini
   universal toolbar_loaded
   TmpBarName = arg(1)

   -- Get name of active toolbar from ini
   BarName = toolbar_loaded  -- query current toolbar name
   if BarName = \1 then      -- \1 means: default toolbar is active
      --BarName = queryprofile( app_hini, 'EPM', 'DEFTOOLBAR')  -- query last saved toolbar name
      BarName = GetDefaultToolbar()  -- query last saved toolbar name
   endif

;   IniFile = queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath')
   IniFile = NepmdQueryInstValue( 'INIT')
   IniAppl = 'UCMenu_Templates'

   'rx Toolbar EXPORT' IniFile IniAppl BarName TmpBarName
   if rc = 0 then
      -- sayerror 'Success. rc = 'rc
   elseif rc = 1 then
      -- sayerror 'Export canceled by user. rc = 'rc
   else
      sayerror 'Error. Toolbar not exported. rc = 'rc
   endif

   -- Delete temporarily saved toolbar
   call setprofile( app_hini, 'UCMenu_Templates', TmpBarName, '')

/*
   -- Get toolbar saved in ini
   fStop = 0
   Bar = queryprofile( app_hini, 'UCMenu_Templates', TmpBarName)  -- Strings are limited to 1599 chars!
   if length( Bar) > 1599 then
      sayerror 'Ini entry longer than 1599 chars. Cannot export toolbar with this defc. Use the settings dialog instead.'
      fStop = 1
   endif

   -- Delete temporarily saved toolbar
   call setprofile( app_hini, 'UCMenu_Templates', TmpBarName, '')
   if fStop = 1 then
      return 24  -- ERROR_BAD_LENGTH
   endif

   -- Get filename from BarName
   UserDir = strip( Get_Env( 'NEPMD_USERDIR'), 't', '\')
   BarFile = arg(1)
   if BarFile = '' then
      BarFile = UserDir'\bar\'BarName'.bar'
   endif
   'xcom e /q /t /bin /c' BarFile
   .autosave = 0
   insertline Bar
   .line = .last
   deleteline    -- delete automatically created line
   -- Ask user for filename and save as .bar file
   'SaveAs_Dlg'  -- open SaveAs dialog
   .modify = 0
   'xcom quit'
*/


                  ---- The rest is commented out ----

; ---------------------------------------------------------------------------
compile if 0 -- No longer used ----------------------------------------------

defc load_toolbar
   call list_toolbars( LOAD_TOOLBAR__MSG, SELECT_TOOLBAR__MSG, 7000, 5916)

defproc list_toolbars( list_title, list_prompt, help_panel, msgid)
   universal app_hini
   universal toolbar_loaded
;  l = dynalink32('PMSHAPI',
;                 '#115',               -- PRF32QUERYPROFILESTRING
;                 atol(app_hini)    ||  -- HINI_PROFILE
;                 address(App)      ||  -- pointer to application name
;                 atol(0)           ||  -- Key name is NULL; returns all keys
;                 atol(0)           ||  -- Default return string is NULL
;                 address(inidata)  ||  -- pointer to returned string buffer
;                 atol(1600), 2)        -- max length of returned string
   inidata = queryprofile( app_hini, INI_UCMENU_APP, '')
   l = length( inidata)

   if not l then sayerror NO_TOOLBARS__MSG; return; endif
   getfileid startfid
   'xcom e /c /q tempfile'
   if rc <> -282 then  -- sayerror('New file')
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   .autosave = 0
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   do while inidata <> ''
      parse value inidata with BarName \0 inidata
      insertline BarName, .last+1
   enddo
   if browse_mode then call browse(1); endif  -- restore browse state
   if listbox_buffer_from_file( startfid, bufhndl, noflines, usedsize) then
      return
   endif
   parse value listbox( list_title,
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                        '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                        0, 0,
                        min( noflines,12), 0,
                        gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(help_panel) ||
                        list_prompt) with button 2 BarName \0
   call buffer( FREEBUF, bufhndl)
   if button <> \1 then
      return
   endif
   call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                       msgid,
                       app_hini,
                       put_in_buffer( BarName))
   if msgid = 5916 then
      toolbar_loaded = BarName
   endif

defc delete_toolbar
   call list_toolbars( DELETE_TOOLBAR__MSG, SELECT_TOOLBAR__MSG, 7001, 5919)

; ---------------------------------------------------------------------------
; Unused, already handled by LoadToolbar without args.
; This is left in here as an example for reading all ini applications into
; a buffer instead into a string (like LoadToolbar does it).
; This is able to handle entire data > 1599 byte (but the limit of 1599
; per a single string cannot be circumvented).
defc SelectToolbar
   universal app_hini
   universal toolbar_loaded
   getfileid startfid

   Appl = 'UCMenu_Templates'
   bufhndl = buffer( CREATEBUF, Appl, MAXBUFSIZE, 1)  -- Create a private buffer
   retlen = \0\0\0\0
   l = dynalink32( 'PMSHAPI',
                   '#115',               -- PRF32QUERYPROFILESTRING
                   atol(app_hini)    ||  -- HINI_PROFILE
                   atol(0)           ||  -- Application name is NULL; returns all apps
                   atol(0)           ||  -- Key name
                   atol(0)           ||  -- Default return string is NULL
                   atoi(0) || atoi(bufhndl)  ||  -- pointer to returned string buffer
                   atol(65535)       ||          -- max length of returned string
                   address(retlen), 2)           -- length of returned string
   poke bufhndl, 65535, \0
   if not l then
      sayerror 'The application "'Appl'" contains no keys'
      call buffer( FREEBUF, bufhndl)
      return
   endif

   'xcom e /c /q tempfile'
   if rc <> -282 then  -- sayerror('New file')
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      call buffer( FREEBUF, bufhndl)
      return
   endif
   .autosave = 0
   browse_mode = browse()     -- query current state
   if browse_mode then
      call browse(0)
   endif

   buf_ofs = 0
   do while buf_ofs < l
      next = peekz( bufhndl, buf_ofs)
      insertline next, .last + 1
      buf_ofs = buf_ofs + length(next) + 1
   enddo
   call buffer( FREEBUF, bufhndl)

   if listbox_buffer_from_file( startfid, bufhndl, noflines, usedsize) then
      return
   endif
   HelpPanel = 0
   Title = 'Select a toolbar'
   Text = 'Current toolbar: 'toolbar_loaded
   parse value listbox( Title''copies( ' ', 20),
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                        '/'OK__MSG'/'Cancel__MSG,
                        0, 0,
                        min( noflines, 12), 0,
                        gethwndc(APP_HANDLE) || atoi(1) || atoi(1) ||
                        atoi(HelpPanel) || Text) with Button 2 BarName \0
   call buffer( FREEBUF, bufhndl)

   if Button = \1 then
      if BarName > '' then
         'LoadToolbar' BarName
      endif
   endif

compile endif  -- 0 ---------------------------------------------------------

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
   --                              # button text # button bitmap # command # parameters # .ex file
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
            -- This can be used to overwrite a button as well.
   universal activeucmenu, toolbar_loaded
   activeucmenu = 'Toolbar'
   buildsubmenu activeucmenu, 11, "#OS/2 win#os2win.bmp#cmd_os2win##commands", '', 0, 0
   showmenu activeucmenu, 3

defc deltb  -- Sample command to delete the Settings button from the toolbar defined above
   universal activeucmenu, toolbar_loaded
   activeucmenu = 'Toolbar'
   deletemenu activeucmenu, 6, 0, 0
   showmenu activeucmenu, 3

compile endif  -- 0

