/****************************** Module Header *******************************
*
* Module Name: menu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: menu.e,v 1.4 2004-07-12 19:51:55 aschn Exp $
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

; Common procedures and commands for menus.
; Most defs moved from STDCTRL.E.

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: dupmark                                                  ³
³                                                                            ³
³ what does it do : This command is used when a Mark menu item is selected   ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc dupmark
   mt = upcase(arg(1))
   if     mt = 'M' then
;     if marktype() then
         call pmove_mark()
;     else                 -- If no mark, look in Shared Text buffer
;       'GetSharBuff'      -- See clipbrd.e for details
;     endif
   elseif mt = 'C' then
      if marktype() then
         call pcopy_mark()
      else                 -- If no mark, look in Shared Text buffer
         'GetSharBuff'     -- See clipbrd.e for details
      endif
   elseif mt = 'O' then
      if marktype() then
compile if WANT_CHAR_OPS
         call pcommon_adjust_overlay('O')
compile else
         overlay_block
compile endif
      else                 -- If no mark, look in Shared Text buffer
         'GetSharBuff O'   -- See clipbrd.e for details
      endif
   elseif mt = 'A' then
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('A')
compile else
      adjustblock
compile endif
   elseif mt = 'U' then
      unmark
      'ClearSharBuff'
   elseif mt = 'U2' then  -- Unmark w/o clearing buffer, for drag/drop
      unmark
   elseif mt = 'D' then  -- Normal delete mark
compile if WANT_DM_BUFFER
      'Copy2DMBuff'        -- See clipbrd.e for details
compile endif  -- WANT_DM_BUFFER
      call pdelete_mark()
      'ClearSharBuff'
   elseif mt = 'D2' then  -- special for drag/drop; only deletes mark w/o touching buffers
      call pdelete_mark()
   elseif mt = 'P' then    -- Print marked area
      call checkmark()     -- verify there is a marked area in the current file, else stop,
;compile if ENHANCED_PRINT_SUPPORT  -- DUPMARK P is only called if no enhanced print support
;      printer = get_printer()
;      if printer<>'' then 'print' printer; endif
;compile else
      'print'              -- then print it.
;compile endif
   endif

/*
ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
º MENU support.                                                              º
º      EPM's menu support is achieved through the use of the MENU manager.   º
º      This menu manager is located in EUTIL.DLL in versions prior to 5.20;  º
º      in E.DLL for EPM 5.20 and above.  The menu manager contains powerful  º
º      functions that allow an application to create there own named menus.  º
º      Building Menus with the Menu Manager:                                 º
º        The menu manager provides two fuctions which allow the creating     º
º        or replacing of items in a named menu.                              º
º        Note: A menu is first built and then displayed in the window.       º
º        BUILDSUBMENU  - creates or modifies a sub menu                      º
º        BUILDMENUITEM - create  or modifies a menu item under a sub menu    º
º                                                                            º
º      Showing a named Menu                                                  º
º        SHOWMENU      - show the specified named menu in the specified      º
º                        window frame.                                       º
º                                                                            º
º      Deleting a name menu                                                  º
º        DELETEMENU    - remove a named menu from the internal menory        º
º                        manager.                                            º
ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
*/

; ---------------------------------------------------------------------------
defexit
   universal defaultmenu
   deletemenu defaultmenu
   defaultmenu = ''

; ---------------------------------------------------------------------------
; List of available menus. Can be extended with
;    call AddAVar( 'menulist', 'mymenu')
; or
;    'AddAVar menulist mymenu'
definit
   call SetAVar( 'menulist', 'newmenu stdmenu fevshmnu ovshmenu')

; ---------------------------------------------------------------------------
; Syntax: ChangeMenu [<newmenuname>[.e]]
; If no arg specified, a listbox for menu selection containing all items from
; MenuList is opened.
defc ChangeMenu
   universal defaultmenu
   universal nepmd_hini
   MenuList = ' 'strip(GetAVar('menulist'))  -- ensure that list starts with a space as separator
   KeyPath = '\NEPMD\User\Menu\Name'
   CurMenu = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if CurMenu = '' then
      CurMenuFile = STD_MENU_NAME
      if CurMenuFile = '' then  -- for STDMENU.E
         CurMenuFile = 'STDMENU.E'
      endif
      if rightstr( upcase(CurMenuFile), 2) = '.E' then
         CurMenu = substr( CurMenuFile, 1, length(CurMenuFile) - 2)
      else
         CurMenu = CurMenuFile
      endif
   endif
   NewMenu = arg(1)
   if NewMenu = '' then
      Selection = wordpos( upcase(CurMenu), upcase(MenuList))
      Text = 'Current menu: 'CurMenu
      Title = 'Menu selection'

      refresh
      select = listbox( Title,
                        MenuList,
                        '/~Set/~Cancel',                -- buttons
                        5, 5,                           -- Top, Left,
                        min( words(MenuList), 12), 25,  -- Height, Width
                        gethwnd(APP_HANDLE) || atoi(Selection) || atoi(1) || atoi(0) ||
                        Text\0 )
      refresh

      -- check result
      button = asc(leftstr( select, 1))
      EOS = pos( \0, select, 2)        -- CHR(0) signifies End Of String
      select= substr( select, 2, EOS - 2)
      if button <> 1 then
         select = ''
      endif

      if select <> '' then
         'ChangeMenu 'select  -- execute this command again
      endif
      return
   endif
   p1 = pos( '\', NewMenu)
   p2 = pos( '.', NewMenu)
   if p2 > p1 + 1 then
      NewMenu = substr( NewMenu, p1 + 1, p2 - p1 - 1)
   endif

  'unlink 'CurMenu'.ex'
   link NewMenu'.ex'

   deletemenu defaultmenu
   'loaddefaultmenu'
   call showmenu_activemenu()

   deleteaccel 'defaccel'
   'loadaccel'

   call NepmdWriteConfigValue( nepmd_hini, KeyPath, NewMenu)

; ---------------------------------------------------------------------------
; Called by external packs, that add a menu before the help menu.
; Common way is to
;    -  delete the help menu with deletemenu HELP_MENU_ID, 0, 0
;    -  add a menu with buildsubmenu and buildmenuitem (or define a proc
;       and call it)
;    -  add the help menu and show the updated menu with readd_help_menu
defproc readd_help_menu
   universal defaultmenu, activemenu
   call add_help_menu(defaultmenu)
   call maybe_show_menu()
   return

; ---------------------------------------------------------------------------
; Add Help menu.
defc AddHelpMenu
   universal defaultmenu
   if arg(1) = '' then
      curmenu = defaultmenu
   else
      curmenu = arg(1)
   endif
   call add_help_menu( curmenu)

; ---------------------------------------------------------------------------
defproc delete_help_menu
   universal defaultmenu
   deletemenu defaultmenu 6, 0, 0
   return

; ---------------------------------------------------------------------------
defc DeleteHelpMenu
   universal defaultmenu
   deletemenu defaultmenu, 6, 0, 0

; ---------------------------------------------------------------------------
; Shows menu if activemenu = defaultmenu.
defproc maybe_show_menu
   universal defaultmenu, activemenu
   if activemenu=defaultmenu then
      call showmenu_activemenu()  -- show the updated EPM menu
   endif
   return

; ---------------------------------------------------------------------------
; Show menu if activemenu = defaultmenu.
defc MaybeShowMenu
   call maybe_show_menu()

; ---------------------------------------------------------------------------
; Called by defmain.
defproc showmenu_activemenu()
   universal activemenu
   showmenu activemenu  -- show the updated EPM menu
   if isadefc('add_cascade_menus') then
      'postme add_cascade_menus'
      -- Process hook: add user-defined cascade menus
      if isadefc('HookExecute') then
         'postme HookExecute cascademenu'
      endif
   endif
   return

; ---------------------------------------------------------------------------
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³What's it called  : processcommand                                           ³
³                                                                             ³
³What does it do   : This command is not called by macros.  It is called by   ³
³                    the internal editor message handler.   When a menu       ³
³                    selected messaged is received by the internal message    ³
³                    handler, (WM_COMMAND) this function is called with       ³
³                    the menu id as a parameter.                              ³
³                                                                             ³
³                                                                             ³
³Who and When      : Jerry C.     3/4/89                                      ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc processcommand
   universal activeaccel
   universal activemenu

   menuid = arg(1)
   if menuid = '' then
      sayerror PROCESS_ERROR__MSG
      return
   endif

   -- first test if command was generated by the
   -- next/prev buttons on the editor frame.
   if menuid = 44 then
      nextfile
   elseif menuid = 45 then
      prevfile
   elseif menuid = 8101 then  -- Temporarily hardcode this
      'configdlg SYS'
   else
      accelstr = queryaccelstring( activeaccel, menuid)
      if accelstr <> '' then
         accelstr
      else
         if activemenu = '' then
;;          sayerror MENU_ERROR__MSG '- ProcessCommand' arg(1)
            return
         endif
         -- execute user string, after stripping off null terminating char
         parse value querymenustring( activemenu, menuid) with command \1 helpstr
         strip( command, 'T', \0)
      endif
   endif

; ---------------------------------------------------------------------------
compile if 0  -- Not used
defc processaccel
   universal activeaccel
   menuid = arg(1)
   if menuid = '' then
      sayerror PROCESS_ERROR__MSG
      return
   endif
   queryaccelstring( activeaccel, menuid)
compile endif

; ---------------------------------------------------------------------------
; Called when a menu item is activated; used for prompting
defc processmenuselect
   universal activemenu
   universal menu_prompt
   universal previouslyactivemenu

   parse arg menutype menuid .
;  if menutype = 'A' & previouslyactivemenu <> '' then
;  if (menuid < 80 | menuid >= 100) & menuid <> '' & previouslyactivemenu <> '' then  -- Temp kludge
   if menuid < 80 & menuid <> '' & previouslyactivemenu <> '' then  -- Temp kludge
      activemenu = previouslyactivemenu
      previouslyactivemenu = ''
   endif
   if menuid = '' | activemenu = '' | not menu_prompt then
      sayerror 0
      return
   endif
   -- Query menu text and parse it into command and helpstr
   parse value querymenustring( activemenu, menuid) with command \1 helpstr
   if helpstr <> '' then
      -- disable writing msg to the messagebox
      display -8
      -- show helpstr
      sayerror helpstr
      display 8
   else  -- if no helpstr defined
      -- delete the previous msg
      sayerror 0
   endif

; ---------------------------------------------------------------------------
; Called when a pulldown or pullright is initialized.
; Note: this routine is *not* executed when Command (menuid 1) is
; selected. Therefore we use menuid = 0 instead.
defc processmenuinit
   universal activemenu, defaultmenu
   if activemenu <> defaultmenu then
      return
   endif
   menuid = arg(1)

   -- Add possible exensions for defc 'menuinit_'name first
compile if not VANILLA

 compile if defined(SITE_MENUINIT)
  compile if SITE_MENUINIT
   include SITE_MENUINIT
  compile endif
 compile endif
   tryinclude 'mymnuini.e'  -- For user-supplied additions to this routine.

   -- Process hook: add user-defined menuinits
   -- Not really required. The user can add his hooks to a list and it will
   -- then be called automatically:
   -- call AddAVar( 'definedsubmenus', <mysubmenuid_name>).
   -- This will execute: 'menuinit_'<mysubmenuid>, if defined.
   if isadefc('HookExecute') then
      'HookExecute menuinit'
   endif

compile endif

   -- Try to find a defc 'menuinit_'name
   if isadefproc('ExecuteMenuInits') then
      ret = ExecuteMenuInits(menuid)
      if ret = 0 then  -- if 'menuinit_'name exists
         return
      endif
   endif

   -- Try to find a defc 'menuinit_'menuid
   if isadefc('menuinit_'menuid) then
;  tmp = 'menuinit_'menuid
;  if isadefc(tmp) then
;  -- Bug?  Above doesn't work...
      'menuinit_'menuid
      return
   endif

; ---------------------------------------------------------------------------
; Called by defc ProcessMenuInit.
; Get the associated cmd for a menuid and execute it.
; Return 0 if a defc 'menuinit_'name exists.
defproc ExecuteMenuInits( menuid)
   -- Query the list of all used names to build the 'menuinit_'name commands.
   -- This list must be extended for every 'menuinit_'name defc.
   items = GetAVar('definedsubmenus')
   ret = 1
   do w = 1 to words(items)
      wrd = word( items, w)
      midname = 'mid_'wrd
      cmdname = 'menuinit_'wrd
      -- Here comes one advantage of GetAVar compared to universal vars:
      -- The arg of GetAVar must be a string, while the name of a universal
      -- var can't be built from a string. Therefore we can use here a loop.
      -- Another advantage: one needn't to specify the universal line,
      -- which is a frequently made error.
      if menuid = GetAVar(midname) then
         if isadefc(cmdname) then
            cmdname  -- execute the cmd
            ret = 0
         endif
         leave
      endif
   enddo
   return ret

; ---------------------------------------------------------------------------
; Change the menu item attribute
; attr = MIA_CHECKED:  on = 1 means 'unchecked'!
; attr = MIA_DISABLED: on = 1 means 'disabled'
defproc SetMenuAttribute( menuid, attr, on)
   -- Check for a non-empty menuid first, because SetMenuAttribute is called
   -- by some toggle commands before the menu is built and the menuids were
   -- set.
   if menuid = '' then
      sayerror 'Warning: defproc SetMenuAttribute: menuid = 'menuid', attr = 'attr', on = 'on
      return
   endif
   if not on then
      attr = mpfrom2short(attr, attr)
   endif
   call windowmessage( 1,
;                      EditMenuHwnd,  -- Doesn't work; EditMenuHwnd changes.
                       getpminfo(EPMINFO_EDITMENUHWND),
                       402,
                       menuid + 65536,
                       attr)
   return

; ---------------------------------------------------------------------------
; Change the menu item text
defproc SetMenuText( mid, menutext)
   if mid = '' then
      return
   endif
   menutext = menutext\0
   call windowmessage( 1, getpminfo(EPMINFO_EDITMENUHWND),
                       398,                  -- x18e, MM_SetItemText
                       mid + 65536,
                       ltoa(offset(menutext) || selector(menutext), 10) )
   return

; ---------------------------------------------------------------------------
; Set the conditional cascade style
; Syntax: cascade_menu submenuid [defaultmenuitemid]
defc cascade_menu
   parse arg menuid defmenuid .
   if menuid = '' then
      return
   endif
   menuitem = copies( \0, 16)  -- 2 bytes ea. pos'n, style, attribute, identity; 4 bytes submenu hwnd, long item
   if not windowmessage( 1,
                         getpminfo(EPMINFO_EDITMENUHWND),
                         386,                  -- x182, MM_QueryItem
                         menuid + 65536,
                         ltoa( offset(menuitem) || selector(menuitem), 10))
   then
      return
   endif
   hwnd = substr( menuitem, 9, 4)
   call dynalink32( 'PMWIN',
                    '#874',     -- Win32SetWindowBits
                    hwnd          ||
                    atol(-2)      ||  -- QWL_STYLE
                    atol(64)      ||  -- MS_CONDITIONALCASCADE
                    atol(64))         -- MS_CONDITIONALCASCADE
   if defmenuid <> '' then  -- Default menu item
      call windowmessage( 1,
                          ltoa( hwnd, 10),
                          1074,                  -- x432, MM_SETDEFAULTITEMID
                          defmenuid, 0)  -- Make arg(2) the default menu item
   endif

; ---------------------------------------------------------------------------
; Return a unique menuid for main menu items.
; Menuids from 51 to 79 are normally unused (mid = 50 is used by
; ETK_FID_POPUP in MOUSE.E).
; If this proc would be used to get a menuid by all extension packages, that
; add menus, it will be garanteed, that the returned mid is unique.
defproc GetUniqueMid
   List = GetAVar('mids')
   mid = ''
   do i = 51 to 79
      if pos( i, List) = 0 then
         mid = i
         List = strip(List' 'i)
         call SetAVar( 'mids', List)
         leave
      endif
   enddo
   --call NepmdPmPrintf( 'GetUniqueMid: Next unique mid = 'mid)
   return mid

; ---------------------------------------------------------------------------
; Send EPM icon window a help message.
;   10 = Help index
; 4000 = General help
;    0 = Using help
; 1000 = Keys help
; 2000 = Commands help
;   *  = TOC
; or: help panel #, 9100,... (see MENUHELP.H)
;
; Note:
; buildsubmenu and buildmenuitem allow for its last arg (MIA) to specify
; not only the MIA, but also the help panel #.
; Apparently this doesn't work with 6.03b. Selecting an menu item and
; pressing F1 won't open the help file viewer. NewView would even make EPM
; crash.
defc helpmenu
   call windowmessage( 0,  getpminfo(APP_HANDLE),
                       5133,      -- EPM_HelpMgrPanel
                       arg(1),    -- mp1
                       0)         -- mp2 = NULL


