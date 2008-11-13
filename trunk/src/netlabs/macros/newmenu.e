/****************************** Module Header *******************************
*
* Module Name: newmenu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: newmenu.e,v 1.55 2008-11-13 10:54:54 aschn Exp $
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

; This is a replacement for STDMENU.E.

/*
Todo:
(for the next release)
- Use consts instead of array vars, although it works fast and stable.
  The drawback would be: A menuitem can't be simply moved by moving the
  buildmenuitem lines, the const section has to be changed then, too.
- Replace buildsubmenu, buildmenuitem and buildacceltable with easier
  to use defprocs and use text message file (interface is completed).
- Use TMF, update processmenuselect therefore. Maybe we could use
  then a string of 80 chars only for the help message, not for
  item text + help text.
*/

compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'NEWMENU.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
; compile if not defined(DEFAULT_PASTE)
;   DEFAULT_PASTE = 'C'
; compile endif
 compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
 compile endif
 compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
 compile endif
 compile if not defined(SUPPORT_USERS_GUIDE)
   SUPPORT_USERS_GUIDE = 1
 compile endif
 compile if not defined(SUPPORT_TECHREF)
   SUPPORT_TECHREF = 1
 compile endif
 compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 1          -- used for ENGLISH.E only
 compile endif
 compile if not defined(WANT_TOOLBAR)
   WANT_TOOLBAR = 1            -- used for ENGLISH.E only
 compile endif
 compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 'DYNALINK'  -- used for ENGLISH.E only
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   include 'stdconst.e'
   include 'menuhelp.h'
   EA_comment 'This defines the menu.'

compile endif

; ---------------------------------------------------------------------------
; Set menu ids (mid) for submenus.
; The menuitem ids (i) will be numbered automatically as followed:
; I.e. mid = 7, i = 701, 702, 703, ..., 799
; The values for mid together with i and ids for accelerator keys must be
; unique.
; We use mid = 0, (1, )..., 79 and i = 101, ..., 7999(, ..., 65535).
;
; The menu ids 1001, ..., 1599 (maybe 1001, ..., 1999) are used for
; accelerator keys. (Accelerator keys cause the message handler to call
; defc processcommand with the id as arg, as well as menuitems.)
;
; The menu ids 44, 45 and 8101 are hardcoded: nextfile, prevfile and
; 'configdlg SYS'. See defc processcommand. The menuid 50 is used by
; ETK_FID_POPUP in MOUSE.E, while mid 80 is free, because it's defined
; with another menuname then defaultmenu.
;
; Don't use mid = 1 if the menuitem attribute should be changed. This is
; usually done by 'processmenuinit', calling 'executemenuinits' with the
; submenuid or menuitemid as arg. Due to a bug in EPM, 'processmenuinit'
; doesn't get called for menuid = 1. Therefore we use mid = 0 instead,
; while keeping the menu item ids i = 101, ..., 199.
;
; All menu ids are saved as array vars, using the procedures SetAVar and
; GetAVar. E.g. using GetAVar('mid_file') will be replaced by 2. We can't
; use consts anymore, because a const can't be built of two strings, e.g.
; a stem and a iterated number. Fortunately there's no remarkable
; performance loss.
;
; Menuids for packages
;
; default
;    0  stdmenu: Command (new)
;    0  newmenu: Run
;    1  stdmenu: Command (ori)
;    2  stdmenu: File
;    2  newmenu: File
;    3  stdmenu: Search
;    3  newmenu: Search
;    4  stdmenu: Options
;    4  newmenu: Options
;   (5  stdmenu: Ring)
;    5  newmenu: View
;    6  stdmenu: Help
;    6  newmenu: Help
;    7  htmepm99\htmepm.ex: HTML (no src available)
;    7  gcppgp11\gcpgpfe.e: PGP (menu id = 700)
;    8  stdmenu: Edit
;    8  newmenu: Edit
;    9  texfe: TeX/VTeX
;    9  EPMTeX: TeX
;    9  epmsmp\epmprt.e: Printer
;    9  cstepm\epmprt.e: Printer
;   16  bookmark.e: Compile (Workframe)
;   19  epmsmp\errparse.e
;   21  eco: Compile
;   21  epmgcc: GCC
;   21  ebooke\bkeys.e: Ebookie
;   32  epmcomp: Compare!
;   33  epmcomp: Sync!
;   37  cstepm\custepm.e: Actions
;   38  cstepm\gmltags.e: GML
;   39  cstepm\latexmnu.e: LaTeX
;   40  cstepm\sgmltags.e: SGML
;   41  cstepm\htmltags.e: HTML
;   51  newmenu: Mark
;   52  newmenu: Format
;   53  newmenu: View part 2
;   54  newmenu: Options part 2
;   55  newmenu: Options part 3
;   56  newmenu: Project
;   62  khtepm14\kenhtepm.e: kHTML
;   80  eshtml01\eshtml.e: ES-HTML
;  900  htmlks10\htmlkeys.e: HTML
; 1969  pmcstex: cstex.e (item ids = 6941,...)
;     Further used mids:
;   44  nextfile
;   45  prevfile
;   50  ETK_FID_POPUP
; 1001...1599...1999  accelerator keys
; 8101  configdlg SYS
;65535  Halt command

; popup1
;   80  Popup


; ---------------------------------------------------------------------------
; Because the menu is linked at definit, this definit is executed immediately
; after linking, before the rest of definit in STDCNF.E. Therefore the
; EPM_utility_array_id must already exist at this point.
definit
   -- Sometimes the rc for a module's definit overrides the link rc.
   -- Therefore a linkable module with code in definit that changes rc,
   -- should save it at the begin of definit and restore it at the end.
   save_rc = rc

   call SetAVar( 'mids', '')        -- reset list of used mids

   call SetAVar( 'mid_file'   , 2)
   call SetAVar( 'mid_edit'   , 8)
   call SetAVar( 'mid_mark'   , GetUniqueMid())  -- first available mid is 51 (50 is used by popup menu)
   call SetAVar( 'mid_format' , GetUniqueMid())  -- second available mid is 52
   call SetAVar( 'mid_search' , 3)
   call SetAVar( 'mid_view'   , 5)
   call SetAVar( 'mid_options', 4)
   call SetAVar( 'mid_run'    , 0)  -- i = 101...199 are used for menuitem ids
;  call SetAVar( 'mid_project', 9)  -- submenu replaced by the current selected project's submenu, e.g. 'TeX'
   call SetAVar( 'mid_help'   , 6)  -- 6 should not be changed to not break other packages
   call SetAVar( 'mid_view2'  , GetUniqueMid())  -- third available mid is 53
   call SetAVar( 'mid_options2', GetUniqueMid())  -- third available mid is 54, otherwise we would run out of 4xx ids
   call SetAVar( 'mid_options3', GetUniqueMid())  -- forth available mid is 55, otherwise we would run out of 4xx ids

   -- Define a list of used menu accelerators, that can't be used as standard
   -- accelerator keys combined with Alt anymore, when 'Menu accelerators' is
   -- activated.
   call SetAVar( 'usedmenuaccelerators', 'F E M A S V O R H')
   -- Maybe someone has already defined something here at definit,
   -- so add it to the array var if not already.
   call AddAVar( 'usedmenuaccelerators', GetAVar( 'addmenuaccelerators'))

   -- Define a list of names for which 'menuinit_'name defcs are defined.
   -- Keep this list in sync with the 'menuinit_'name defcs!
   -- (Otherwise 'processmenuinit' will never execute that defc.)
   call SetAVar( 'definedsubmenus', 'file edit mark format search view options run project help' ||
                    /* File */      ' openfolder fileproperties' ||
                    /* Edit */      ' recordkeys spellcheck' ||
                    /* Mark */      ' markatcursor' ||
                    /* Format */    ' reflowmargins reflow' ||
                    /* Search */    ' goto markstack cursorstack bookmarks' ||
                    /* View */      ' menu infobars toolbar toolbarstyle backgroundbitmap' ||
                    /* Options */   ' editoptions saveoptions searchoptions' ||
                                    ' modesettings markingsettings' ||
                                    ' marginsandtabs keyssettings' ||
                                    ' readonlyandlock cursorsettings autorestore backup' ||
                                    ' workdir opendlgdir saveasdlgdir prg macros' ||
                    /* Run */       ' configureshell treecommands' ||
                    /* Help */      ' keywordhelp')

   -- Define a list of abbreviations for linked .ex filenames, that add a
   -- large amount of menu items. These .ex files will cause a decrease of
   -- NewMenu items (in Options, View) when they are linked via the Link
   -- command (not the Link statement).
   -- EPM's amount of menu items is limited to about 600. NewMenu uses
   -- already the half of them. Trying to link a menu with more items would
   -- make EPM crash.
-- Todo: replace abbrev with resolving wildcards
   call AddAVar( 'hidemenunames', 'KENHT HTM SGML LATEX GML EPMPRT GETHOST')
   -- Define a list of abbreviations that won't cause a decrease of NewMenu
   -- items, even when their abbreviations match the list above.
   call AddAVar( 'nohidemenunames', 'HTMPOP')

   'InitMenuSettings'
   'CheckRecode'
   'CheckGrep'
   'CheckGfc'
   'CheckWps'

   rc = save_rc  -- don't change rc of the link statement by definit code

; ---------------------------------------------------------------------------
; Better don't use NepmdQueryConfigValue at definit, because this can cause
; stop of the definit processing sometimes. Executing this from a command is
; processed delayed, after definit is completed.
defc InitMenuSettings
   universal nepmd_hini
   universal nodismiss

   KeyPath = '\NEPMD\User\Menu\NoDismiss'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   nodismiss = 32*on

; ---------------------------------------------------------------------------
defc CheckRecode
   universal recodefound
   -- Find recode.exe in path
   findfile File, 'recode.exe', 'PATH', 'P'
   if File = '' then
      recodefound = 0  -- File not found
   else
      recodefound = 1  -- File found
   endif

; ---------------------------------------------------------------------------
defc CheckGrep
   universal grepfound
   -- Find grep.exe in path
   findfile File, 'grep.exe', 'PATH', 'P'
   if File = '' then
      grepfound = 0  -- File not found
   else
      grepfound = 1  -- File found
   endif

; ---------------------------------------------------------------------------
defc CheckGfc
   universal gfcfound
   -- Find gfc.exe in path
   findfile File, 'gfc.exe', 'PATH', 'P'
   if File = '' then
      gfcfound = 0  -- File not found
   else
      gfcfound = 1  -- File found
   endif

; ---------------------------------------------------------------------------
defc CheckWps
   universal wpsstarted
   fIsWps = (Get_Env( 'WORKPLACE_PROCESS') = 'YES')
   if fIsWps then
      wpsstarted = 1
   else
      wpsstarted = (Get_Env( 'WORKPLACE__PROCESS') = 'NO')
   endif

; ---------------------------------------------------------------------------
; Called by defc Link, if defined.
; Hide some NewMenu items before linking several external menu additions.
defproc BeforeLink
   universal MenuItemsHidden
   modulename = arg(1)
   dPrintf( 'BEFORELINK', modulename)
   if not isadefc( 'HideMenuItems') then
      return
   elseif MenuItemsHidden <> 0 then  -- 0 means: not hidden
      return                         -- 1 means: already hidden before
   endif

   -- KenHTepm.ex uses too many menu items, together with Newmenu.
   -- EPM has a limit at about 600 items. KenHTepm uses already 290 of them!
   -- Therefore Newmenu's Options menu is deleted before linking.

   p2 = lastpos( '\', modulename)
   name = upcase( substr( modulename, p2 + 1))       -- strip path

   -- Provide array vars to specify ExFile names with huge menus, in order to
   -- let the user change the list. Match an abbreviation.
   HideList   = upcase( GetAVar( 'hidemenunames'))
   NoHideList = upcase( GetAVar( 'nohidemenunames'))
   fHide = 0
   do w = 1 to words( HideList)
      next = word( HideList, w)
-- Todo: replace abbrev with resolving wildcards
      if abbrev( name, next) then
         fHide = 1
         leave
      endif
   enddo
   if fHide then
      do w = 1 to words( NoHideList)
         next = word( NoHideList, w)
-- Todo: replace abbrev with resolving wildcards
         if abbrev( name, next) then
            fHide = 0
            leave
         endif
      enddo
   endif

   if fHide then
      'HideMenuItems'
      if MenuItemsHidden = 1 then
         MenuItemsHidden = 2         -- 2 means: just hidden
      endif
   endif

; ---------------------------------------------------------------------------
; Called by defc Link, if defined.
; Used to check if the linking was successful. If not, unhide the menu items.
defproc AfterLink
   universal MenuItemsHidden
   linkrc = arg(1)
   -- Restore Options menu if kenHTepm wasn't linked
   if not isadefc( 'HideMenuItems') then
      return
   elseif MenuItemsHidden <> 2 then  -- 2 means: just hidden
      return                         -- 1 means: already hidden before -> ignore
   endif
   -- reset var from 2 to 1
   if MenuItemsHidden = 2 then
      MenuItemsHidden = 1
   endif
   -- unhide if not linked
   if linkrc < 0 then
      'HideMenuItems 0'
   endif

; ---------------------------------------------------------------------------
; KenHTepm.ex uses too many menu items, together with Newmenu. The same
; applies to HTMLTAGS.EX.
; EPM has a limit at about 600 items. KenHTepm uses already 290 of them!
; Therefore Newmenu's Options menu items and some of the View menu items
; can be deleted before linking these .ex files.
defc HideMenuItems
   universal defaultmenu
   universal nepmd_hini
   universal menuloaded                   -- for to check if menu is already built
   universal MenuItemsHidden

   KeyPath = '\NEPMD\User\Menu\HideItems'

   arg1 = upcase( arg(1))
   if arg1 = 'INIT' then
      MenuItemsHidden = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
      return rc
   elseif arg1 = 'TOGGLE' then
      new = not (MenuItemsHidden = 1)
   elseif wordpos( arg1, '0 OFF') then
      new = 0
   else
      new = 1
   endif

   if new = MenuItemsHidden then  -- nothing to do
      return rc
   endif

   MenuItemsHidden = new

   -- Save new value to ini
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, MenuItemsHidden)

   if MenuItemsHidden then
      -- Delete some menu items
      mid = GetAVar( 'mid_view')
      deletemenu defaultmenu, mid, 0, 1
      call add_view_menu( defaultmenu)

      mid = GetAVar( 'mid_options')
      deletemenu defaultmenu, mid, 0, 1
      call add_options_menu( defaultmenu)

   else
      -- Better get rid of all added menus and rebuild the entire menu
      deletemenu defaultmenu
      'loaddefaultmenu'
   endif

   -- Show menu and add cascade menu item styles.
   -- (After processing showmenu, the cascade menu defs must always be reapplied.)
   call showmenu_activemenu()

; ---------------------------------------------------------------------------
; Called by defmain -> initconfig, STDCTRL.E (formerly by definit, MENUACCEL.E).
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³What's it called  : loaddefaultmenu                                          ³
³                                                                             ³
³What does it do   : used by stdcnf.e to setup default EPM menu bar           ³
³                    (Note: a menu id of 0 halts the interpreter when         ³
³                     selected.)                                              ³
³                    Really? The id, that doesn't work, is 1, not 0!          ³
³                                                                             ³
³Who and When      : Jerry C.     2/25/89                                     ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

defc loaddefaultmenu
   universal activemenu, defaultmenu
   universal menuloaded                   -- for to check if menu is already built
   universal MenuItemsHidden
   universal nepmd_hini

   parse arg menuname .
   if menuname = '' then                  -- Initialization call
      menuname = 'default'
      defaultmenu = menuname              -- default menu name
      activemenu  = defaultmenu
   endif

   if MenuItemsHidden = '' then
      'HideMenuItems INIT'
   endif

   call add_file_menu(menuname)      -- id = 2
   call add_edit_menu(menuname)      -- id = 8
   call add_mark_menu(menuname)      -- id = ?
   call add_format_menu(menuname)    -- id = ?
   call add_search_menu(menuname)    -- id = 3
   call add_view_menu(menuname)      -- id = 5
   call add_options_menu(menuname)   -- id = 4
;   call add_command_menu(menuname)  -- replaced with add_run_menu
   call add_run_menu(menuname)       -- id = 0 (menuitem ids = 1xx)
;   call add_project_menu(menuname)   -- id = 9 (= TeX, epmprt)

   -- Process hook: add a user-defined submenu
   if isadefc('HookExecute') then
      'HookExecute addmenu'
   endif

   call add_help_menu(menuname)      -- id = 6 (keep this)
   -- Note: showmenu_activemenu() must be called separately.
   menuloaded = 1

; -------------------------------------------------------------------------------------- File -------------------------
defproc add_file_menu(menuname)
   universal nodismiss
   universal ring_enabled
   universal wpsstarted
   mid = GetAVar('mid_file')
   i = mid'00'
   buildsubmenu  menuname, mid, FILE_BAR__MSG,                                                     -- File ------------
                                FILE_BARP__MSG,
                                0, mpfrom2short(HP_FILE, 0)  -- MIS must be 0 for submenu
   if ring_enabled then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Add ~new',                                                     -- Add new
                                   'xcom e /n' ||
                                   \1'Edit a new, empty file in this window',
                                   MIS_TEXT, mpfrom2short(HP_FILE_EDIT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'A~dd...'\9'F8',                                                -- Add...
                                   'opendlg EDIT' ||
                                   ADD_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_EDIT, 0)
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open n~ew'\9CTRL_KEY__MSG'+N',                                 -- Open new
                                   "open ''" ||
                                   OPEN_NEW_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_OPEN_NEW, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, OPEN_MENU__MSG\9'F5 | 'CTRL_KEY__MSG'+O',                       -- Open...
                                   'opendlg' ||
                                   OPEN_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_OPEN, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open ~bin...',                                                 -- Open bin...
                                   'OpenBinDlg' ||
                                   \1'Select a binary file to edit',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_history', i);
   buildmenuitem menuname, mid, i, '~History',                                                     -- History   >
                                   '' ||
                                   \1'Edit previously loaded files',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save as last ~ring',                                                 -- Save as last ring
                                   'savering' ||
                                   \1'Save current file list as last edit ring',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Load last ring',                                                    -- Load last ring
                                   'restorering' ||
                                   \1'Restore last saved edit ring',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save ~group...',                                                     -- Save group
                                   'groups savegroup' ||
                                   \1'Save current file list as group',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'L~oad group...',                                                     -- Load group
                                   'groups loadgroup' ||
                                   \1'Restore a previously saved group',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List ~edit history...'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+F9',     -- List edit history...
                                   'history edit' ||
                                   \1'Open a list box with previous edit cmds',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List ~loaded files...'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+F10',    -- List loaded files...
                                   'history load' ||
                                   \1'Open a list box with previous loaded files',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List ~saved files...'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+F11',     -- List saved files...
                                   'history save' ||
                                   \1'Open a list box with previous saved files',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
 if WpsStarted then
   i = i + 1; call SetAVar( 'mid_openfolder', i);
   buildmenuitem menuname, mid, i, 'Open ~folder',                                                 -- Open folder   >
                                   '' ||
                                   \1'Open WPS folder where the current file is located',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_openfolder_defaultview', i);
   buildmenuitem menuname, mid, i, 'Default ~view',                                                      -- Default view
                                   'openfolder OPEN=DEFAULT' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Icon view',                                                         -- Icon view
                                   'openfolder ICONVIEW=NORMAL;OPEN=ICON' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Icon ~flowed view',                                                  -- Icon flowed view
                                   'openfolder ICONVIEW=FLOWED,MINI;OPEN=ICON' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Tree view',                                                         -- Tree view
                                   'openfolder TREEVIEW=MINI;SHOWALLINTREEVIEW=YES;OPEN=TREE' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Details view',                                                      -- Details view
                                   'openfolder OPEN=DETAILS' ||
                                   \1,
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   -- Note: Don't specify the OpenFolder arg too long. There exists a restriction to the length of that parameter for buildmenuitem!
   -- ToDo: use XWP's 'Reset to WPS's default view' feature to minimize stored EAs
 endif
/*
   i = i + 1;
   buildmenuitem menuname, mid, i, 'F~TP',                                                         -- FTP   >
                                   '' ||
                                   \1'Download or upload file from/to FTP server',
                                   MIS_TEXT, MIA_DISABLED
*/
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_fileproperties', i);
   buildmenuitem menuname, mid, i, '~File properties',                                             -- File properties   >
                                   '' ||
                                   \1'Properties for this buffer/file only',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_mode', i); call SetAVar( 'mtxt_mode', '~Mode []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_mode'),                                                -- Mode...
                                   'mode' ||
                                   \1'Select or show mode for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_tabs', i); call SetAVar( 'mtxt_tabs', '~Tabs []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_tabs'),                                                -- Tabs...
                                   'tabs' ||
                                   \1'Select or show tabs for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_margins', i); call SetAVar( 'mtxt_margins', 'Mar~gins []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_margins'),                                             -- Margins...
                                   'ma' ||
                                   \1'Select or show margins for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_readonlyattrib', i);
   buildmenuitem menuname, mid, i, 'Read-~only file attribute',                                          -- Read-only file attribute
                                   'toggle_readonly_attrib' ||
                                   \1'Set or reset read-only file attribute',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_readonly', i);
   buildmenuitem menuname, mid, i, '~Read-only mode',                                                    -- Read-only mode
                                   'toggle_readonly' ||
                                   \1'Enable or disable read-only mode',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_locked', i);
   buildmenuitem menuname, mid, i, '~Locked',                                                            -- Locked
                                   'toggle_locked' ||
                                   \1'Enable or disable write access for other apps',
                                   MIS_TEXT, nodismiss
 if WpsStarted then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_wpsproperties', i);
   buildmenuitem menuname, mid, i, '~WPS properties...',                                                 -- WPS properties...
                                   'OpenSettings' ||
                                   \1'Open WPS properties dialog for current file',
                                   MIS_TEXT, 0
 endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_streammode', i);
   buildmenuitem menuname, mid, i, '~Stream mode',                                                       -- Stream mode
                                   'toggle_stream' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_syntaxexpansion', i);
   buildmenuitem menuname, mid, i, 'Syntax e~xpansion',                                                  -- Syntax expansion
                                   'toggle_expand' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_keywordhighlighting', i);
   buildmenuitem menuname, mid, i, 'Keyword ~highlighting',                                              -- Keyword highlighting
                                   'toggle_highlight' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_tabkey', i);
   buildmenuitem menuname, mid, i, 'T~abkey enabled',                                                    -- Tabkey enabled
                                   'toggle_tabkey' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_matchtab', i);
   buildmenuitem menuname, mid, i, 'Matchta~b enabled',                                                  -- Matchtab enabled
                                   'toggle_matchtab' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   if nodismiss > 0 then
      endsubmenu = 0
   else
      endsubmenu = MIS_ENDSUBMENU
   endif  -- nodismiss > 0
   i = i + 1; call SetAVar( 'mid_autospellcheck', i);
   buildmenuitem menuname, mid, i, DYNASPELL_MENU__MSG,                                                  -- Auto-spellcheck
                                   'toggle_dynaspell' ||
                                   DYNASPELL_MENUP__MSG,
                                   MIS_TEXT + endsubmenu, mpfrom2short(HP_OPTIONS_DYNASPELL, nodismiss)
   if nodismiss > 0 then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, ' Use Options for default settings',                                   -- Use Options for default settings
;                                   '' ||
;                                   \1'',
;                                   MIS_TEXT + MIS_STATIC, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Close menu',                                                        -- Close menu
                                   '' ||
                                   \1,
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   endif  -- nodismiss > 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_importfile', i);
   buildmenuitem menuname, mid, i, '~Import file...',                                              -- Import file...
                                   'opendlg GET' ||
                                   GET_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_GET, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Re~name'\9'F7',                                                -- Rename...
                                   'rename' ||
                                   RENAME_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_NAME, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Reload',                                                      -- Reload
                                   'revert' ||
                                   \1'Reload file from disk, ask if modified',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_save', i);
   buildmenuitem menuname, mid, i, SAVE_MENU__MSG\9'F2',                                           -- Save
                                   'save' ||
                                   SAVE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_SAVE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, SAVEAS_MENU__MSG\9ALT_KEY__MSG'+F2',                            -- Save as...
                                   'saveas_dlg' ||
                                   SAVEAS_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_SAVEAS, 0)
   i = i + 1; call SetAVar( 'mid_saveandquit', i);
   buildmenuitem menuname, mid, i, FILE_MENU__MSG\9'F4',                                           -- Save and quit
                                   'file' ||
                                   FILE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_FILE, 0)
   if ring_enabled then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save a~ll',                                                    -- Save all
                                   'SaveAll' ||
                                   \1'Save all files of the ring',
                                   MIS_TEXT, 0
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, PRT_FILE_MENU__MSG'...',                                        -- Print file...
                                   'printdlg' ||
                                   ENHPRT_FILE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_ENHPRINT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, QUIT_MENU__MSG\9'F3',                                           -- Quit file
                                   'quit' ||
                                   QUIT_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_QUIT, 0)
   return


; -------------------------------------------------------------------------------------- Edit -------------------------
defproc add_edit_menu(menuname)
   universal nodismiss
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif

   mid = GetAVar('mid_edit')
   i = mid'00'
   buildsubmenu  menuname, mid, '~Edit',                                                           -- Edit -----------
                                \1'Menus related to edit operations',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1; call SetAVar( 'mid_undoline', i);
   buildmenuitem menuname, mid, i, UNDO_MENU__MSG\9 || ALT_KEY__MSG'+'BACKSPACE_KEY__MSG' | F9',   -- Undo line
                                   'undo 1' ||
                                   UNDO_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_UNDO, 0)
   i = i + 1; call SetAVar( 'mid_undo', i);
   buildmenuitem menuname, mid, i, UNDO_REDO_MENU__MSG\9 || CTRL_KEY__MSG'+U',                     -- Undo...
                                   'undodlg' ||
                                   UNDO_REDO_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_UNDOREDO, 0)
   i = i + 1; call SetAVar( 'mid_recovermarkdelete', i);
   buildmenuitem menuname, mid, i, RECOVER_MARK_MENU__MSG,                                         -- Recover mark delete
                                   'GetDMBuff' ||
                                   RECOVER_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_RECOVER, 0)
   i = i + 1; call SetAVar( 'mid_discardchanges', i);
   buildmenuitem menuname, mid, i, '~Discard changes',                                              -- Discard changes
                                   'DiscardChanges' ||
                                   \1'Reset modified state',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Dupli~cate line'\9CTRL_KEY__MSG'+K',                            -- Duplicate line
                                   'DuplicateLine' ||
                                   \1'Duplicate current line (insert below)',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Insert',                                                       -- Insert   >
                                   \1'Insert text',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~New line after'\9ALT_KEY__MSG'+N',                                  -- New line after
                                   'NewLineAfter' ||
                                   \1'Insert empty line after current',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, 'New ~line before'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+N',                -- New line before
                                   'NewLineBefore' ||
                                   \1'Insert empty line before current',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Char from above'\9ALT_KEY__MSG'+G',                                 -- Char from above
                                   'InsertCharAbove' ||
                                   \1'Copy char above to cursor position',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Char from ~below'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+G',                -- Char from below
                                   'InsertCharBelow' ||
                                   \1'Copy char below to cursor position',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Filename',                                                          -- Filename
                                   'TypeFilename' ||
                                   \1'Insert current filename at cursor position',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Date Time (ISO)',                                                   -- Date Time (ISO)
                                   'TypeDateTime' ||
                                   \1'Insert current date and time at cursor position',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Mo~ve',                                                         -- Move   >
                                   \1'Move current text',
                                   MIS_TEXT + MIS_SUBMENU, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Line ~up'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+'UP_KEY__MSG,              -- Line up
                                   'MoveLineUp' ||
                                   \1'Move current line up',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Line ~down'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+'DOWN_KEY__MSG,          -- Line down
                                   'MoveLineDown' ||
                                   \1'Move current line down',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Char ~left'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+Left',                   -- Char left
                                   'MoveCharLeft' ||
                                   \1'Move current line left',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Char ~right'\9ALT_KEY__MSG'+'SHIFT_KEY__MSG'+Right',                 -- Char right
                                   'MoveCharRight' ||
                                   \1'Move current char right',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'D~elete line'\9CTRL_KEY__MSG'+'BACKSPACE_KEY__MSG,              -- Delete line
                                   'DeleteLine' ||
                                   \1'Delete current line',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Delete rest of li~ne'\9CTRL_KEY__MSG'+'DELETE_KEY__MSG,         -- Delete rest of line
                                   'DeleteUntilEndLine' ||
                                   \1'Delete from cursor until end of line',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Delete up to ne~xt word'\9CTRL_KEY__MSG'+D',                    -- Delete up to next word
                                   'DeleteUntilNextWord' ||
                                   \1'Delete from cursor until begin of next word',
                                   MIS_TEXT, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, \0,                                                             --------------------
;                                   '',
;                                   MIS_SEPARATOR, 0
;
; x      Box   used in: CustEpm
; x      Draw  used in: CustEpm
;        Fill
;        Center
; x      Sort
; x      Sum
;        ?Math
; x      Expand > First
; x      Expand > Second
;        Syntax expansion in header
;
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
compile endif
   i = i + 1; call SetAVar( 'mid_spellcheck', i);
   buildmenuitem menuname, mid, i, 'S~pellcheck',                                                  -- Spellcheck   >
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, PROOF_MENU__MSG,                                                      -- Proof
                                   'proof' ||
                                   PROOF_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_PROOF, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, PROOF_WORD_MENU__MSG,                                                 -- Proof word
                                   'proofword' ||
                                   PROOF_WORD_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_PROOFW, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, SYNONYM_MENU__MSG,                                                    -- Synonym
                                   'syn' ||
                                   SYNONYM_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_SYN, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_dict', i); call SetAVar( 'mtxt_dict', 'Select ~dictionary: []')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_dict'),                                                -- Select dictionary: []...
                                   'switch_dicts' ||
                                   \1'Switch to next defined dictionary language',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Configure dictionaries...',                                         -- Configure dictionaries...
                                   'DictLang' ||
                                   \1'Select a set of Netscape 4.6.1 dictionaries',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0

   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                            --------------------
                                   '',
                                   MIS_SEPARATOR, 0
compile if CHECK_FOR_LEXAM
   endif
compile endif
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Key recorder',                                                -- Key recorder   >
                                   '' ||
                                   \1'Record and playback keys',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_startrecording', i);
   buildmenuitem menuname, mid, i, 'Start/end ~recording'\9 || CTRL_KEY__MSG'+R',                        -- Start recording
                                   'RecordKeys' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_playback', i);
   buildmenuitem menuname, mid, i, '~Playback'\9 || CTRL_KEY__MSG'+T',                                   -- Playback
                                   'PlaybackKeys' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0

   return


; -------------------------------------------------------------------------------------- Mark -------------------------
define  -- Prepare for some conditional tests
   maybe_ring_accel = "' ' <"  -- Will be true for any letter
compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   maybe_actions_accel = 'ACTIONS_ACCEL__L <>'
compile else
   maybe_actions_accel = "' ' <"  -- Will be true for any letter
compile endif

defproc add_mark_menu(menuname)
   universal CUA_marking_switch

   mid = GetAVar('mid_mark')
   i = mid'00'
   buildsubmenu  menuname, mid, '~Mark',                                                           -- Mark -----------
                                \1'Menus related to basic mark operations',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1; call SetAVar( 'mid_copy', i);
   buildmenuitem menuname, mid, i, CLIP_COPY_MENU__MSG\9 || CTRL_KEY__MSG'+'INSERT_KEY__MSG ,      -- Copy
                                   'Copy2Clip' ||
                                   CLIP_COPY_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_COPY, 0)
   i = i + 1; call SetAVar( 'mid_cut', i);
   buildmenuitem menuname, mid, i, CUT_MENU__MSG\9 || SHIFT_KEY__MSG'+'DELETE_KEY__MSG,            -- Cut
                                   'Cut' ||
                                   CUT_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_CUT, 0)
   i = i + 1; call SetAVar( 'mid_paste', i);
   buildmenuitem menuname, mid, i, PASTE_C_MENU__MSG/*||PASTE_C_KEY*/,                             -- Paste
                                   'Paste C' ||
                                   PASTE_C_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTEC, 0)
   i = i + 1; call SetAVar( 'mid_pastelines', i);
   buildmenuitem menuname, mid, i, PASTE_L_MENU__MSG/*||PASTE_L_KEY*/,                             -- Paste lines
                                   'Paste' ||
                                   PASTE_L_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTE, 0)
   i = i + 1; call SetAVar( 'mid_pasteblock', i);
   buildmenuitem menuname, mid, i, PASTE_B_MENU__MSG/*||PASTE_B_KEY*/,                             -- Paste block
                                   'Paste B' ||
                                   PASTE_B_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTEB, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Copy file~name to clip',                                       -- Copy filename to clip
                                   'CopyFilename2Clip' ||
                                   \1'Copy current filename to clipboard',
                                   MIS_TEXT, 0
;   if not CUA_marking_switch then  -- better add it everytime, to make toggling easier (nodismiss menues work then)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_copymark', i);
   buildmenuitem menuname, mid, i, COPY_MARK_MENU__MSG,                                            -- Copy mark
                                   'DUPMARK C' ||
                                   COPY_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_COPYMARK, 0)
   i = i + 1; call SetAVar( 'mid_movemark', i);
   buildmenuitem menuname, mid, i, MOVE_MARK_MENU__MSG,                                            -- Move mark
                                   'DUPMARK M' ||
                                   MOVE_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_MOVE, 0)
   i = i + 1; call SetAVar( 'mid_overlaymark', i);
   buildmenuitem menuname, mid, i, OVERLAY_MARK_MENU__MSG,                                         -- Overlay mark
                                   'DUPMARK O' ||
                                   OVERLAY_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_OVERLAY, 0)
   i = i + 1; call SetAVar( 'mid_adjustmark', i);
   buildmenuitem menuname, mid, i, ADJUST_MARK_MENU__MSG,                                          -- Adjust mark
                                   'DUPMARK A' ||
                                   ADJUST_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_ADJUST, 0)
;   endif

   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_markatcursor', i);
   buildmenuitem menuname, mid, i, 'Mar~k at cursor',                                              -- Mark   >
                                   '' ||
                                   \1'Mark text at cursor position in different ways',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_markchars', i);
   buildmenuitem menuname, mid, i, 'Mark ~chars'\9 || ALT_KEY__MSG'+Z',                                  -- Mark chars
                                   'MarkChar' ||
                                   \1'Create a char mark between two cursor positions',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_markblock', i);
   buildmenuitem menuname, mid, i, 'Mark ~block'\9 || ALT_KEY__MSG'+B',                                  -- Mark block
                                   'MarkBlock' ||
                                   \1'Create a block mark between two cursor positions',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_marklines', i);
   buildmenuitem menuname, mid, i, 'Mark ~lines'\9 || ALT_KEY__MSG'+L',                                  -- Mark lines
                                   'MarkLine' ||
                                   \1'Create a line mark between two cursor positions',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_markword', i);
   buildmenuitem menuname, mid, i, 'Mark ~word'\9 || ALT_KEY__MSG'+W',                                   -- Mark word
                                   'MarkWord' ||
                                   \1'Mark word under cursor',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_marktoken', i);
   buildmenuitem menuname, mid, i, 'Mark ~identifier'\9 || ALT_KEY__MSG'+'SHIFT_KEY__MSG'+W',            -- Mark identifier
                                   'MarkToken' ||
                                   \1'Mark identifier (C-style word) under cursor',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_marksentence', i);
   buildmenuitem menuname, mid, i, 'Mark ~sentence'\9,                                                   -- Mark sentence
                                   'MarkSentence' ||
                                   \1'Mark sentence around mouse pointer',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_extendsentence', i);
   buildmenuitem menuname, mid, i, '~Extend sentence'\9,                                                 -- Extend sentence
                                   'ExtendSentence' ||
                                   \1'Extend character mark through end of next sentence',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_markparagraph', i);
   buildmenuitem menuname, mid, i, 'Mark ~paragraph'\9,                                                  -- Mark paragraph
                                   'MarkParagraph' ||
                                   \1'Mark paragraph around mouse pointer',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_extendparagraph', i);
   buildmenuitem menuname, mid, i, 'E~xtend paragraph'\9,                                                -- Extend paragraph
                                   'ExtendParagraph' ||
                                   \1'Extend character mark through end of next paragraph',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/ | 'CTRL_KEY__MSG'+A',  -- Select all
                                   'select_all' ||
                                   SELECT_ALL_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_SELECTALL, 0)
   i = i + 1; call SetAVar( 'mid_unmark', i);
   buildmenuitem menuname, mid, i, UNMARK_MARK_MENU__MSG\9 || ALT_KEY__MSG'+U | 'CTRL_KEY__MSG'+\ | 'CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+A',  -- Unmark
                                   'DUPMARK U' ||
                                   UNMARK_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_UNMARK, 0)
   i = i + 1; call SetAVar( 'mid_deletemark', i);
   buildmenuitem menuname, mid, i, DELETE_MARK_MENU__MSG,                                          -- Delete mark
                                   'DUPMARK D' ||
                                   DELETE_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_DELETE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_printmark', i);
   buildmenuitem menuname, mid, i, PRT_MARK_MENU__MSG'...',                                        -- Print mark
                                   'PRINTDLG M' ||
                                   ENHPRT_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_ENHPRINT, 0)
   --call update_paste_menu_text()  -- handled by menuinit
   --call update_mark_menu_text()   -- handled by menuinit
   return


; -------------------------------------------------------------------------------------- Format -----------------------
defproc add_format_menu(menuname)
   universal nodismiss
   universal reflowmargins
   universal recodefound

   mid = GetAVar('mid_format')
   i = mid'00'
   buildsubmenu  menuname, mid, 'Form~at',                                                         -- Format ---------
                                \1'Menus related to formatting operations',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1; call SetAVar( 'mid_reflowmargins', i); call SetAVar( 'mtxt_reflowmargins', 'Reflowmargins []');
   buildmenuitem menuname, mid, i, GetAVAr( 'mtxt_reflowmargins'),                                 -- Reflowmargins   >
                                   \1'Margins/rightmargin for wrap and reflow actions',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_reflowmargins1', i); call SetAVar( 'mtxt_reflowmargins1', '~1: reflowmargins []');
   buildmenuitem menuname, mid, i, GetAVAr( 'mtxt_reflowmargins1'),                                      -- 1:
                                   'ReflowmarginsSelect 1' ||
                                   \1'Select specified value(s) as reflowmargins',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_reflowmargins2', i); call SetAVar( 'mtxt_reflowmargins2', '~2: reflowmargins []');
   buildmenuitem menuname, mid, i, GetAVAr( 'mtxt_reflowmargins2'),                                      -- 2:
                                   'ReflowmarginsSelect 2' ||
                                   \1'Select specified value(s) as reflowmargins',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_reflowmargins3', i); call SetAVar( 'mtxt_reflowmargins3', '~3: current margins []');
   buildmenuitem menuname, mid, i, GetAVAr( 'mtxt_reflowmargins3'),                                      -- 3: rightmargin
                                   'ReflowmarginsSelect 3' ||
                                   \1'Select file''s margins as reflowmargins',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_reflowmarginsconfig', i);
   buildmenuitem menuname, mid, i, '~Configure selected...',                                             -- Configure selected...
                                   'set_ReflowMargins' ||
                                   \1'Configure selected reflowmargins item...',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Wrap',                                                        -- Wrap   >
                                   \1'Reformat all: add linebreaks',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'All to reflowmargins, ~keep indent',
                                   'wrap KEEPINDENT' ||                                                  -- All to reflowmargins, keep indent
                                   \1'Wrap lines at reflowmargins, keep indent of line above',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'All to reflowmargins, s~plit',
                                   'wrap SPLIT' ||                                                       -- All to reflowmargins, split
                                   \1'Wrap lines at reflowmargins, split only',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Split line'\9 || ALT_KEY__MSG'+S',                                  -- Split line
                                   'dokey a_s' ||
                                   \1'Split current line at cursor, keep indent',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Join line'\9 || ALT_KEY__MSG'+J',                                   -- Join line
                                   'dokey a_j' ||
                                   \1'Join current line with next line, respect right margin',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_reflow', i);
   buildmenuitem menuname, mid, i, 'Re~flow',                                                      -- Reflow   >
                                   '' ||
                                   \1'Reformat paragraph, mark or all',
                                   MIS_TEXT + MIS_SUBMENU, 0
/*
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to reflowmargins',                                               -- Par to reflowmargins
                                   'flow' reflowmargins ||
                                   \1'Reformat lines from cursor to par end',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to margins...',                                                  -- Par to margins...
                                   'commandline flow' reflowmargins ||
                                   \1'Reformat lines from cursor to par end, enter margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
*/
   i = i + 1; call SetAVar( 'mid_reflowpartoreflowmargins', i); call SetAVar( 'mtxt_reflowpartoreflowmargins', 'Par to reflowmargins'\9 || ALT_KEY__MSG'+P');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_reflowpartoreflowmargins'),                            -- Mark/Par to reflowmargins
                                   'ReflowPar2Reflowmargins' ||
                                   \1'Reformat mark or paragraph to reflowmargins',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_reflowpartomargins', i); call SetAVar( 'mtxt_reflowpartomargins', 'Par to margins'\9 || ALT_KEY__MSG'+'SHIFT_KEY__MSG'+P');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_reflowpartomargins*'),                                 -- Mark/Par to margins
                                   'ReflowPar' ||
                                   \1'Reformat mark or paragraph to fit the current margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'All to ~reflowmargins'\9 || CTRL_KEY__MSG'+P',                       -- All to reflowmargins
                                   'ReflowAll2Reflowmargins' ||
                                   \1'Reformat all to reflowmargins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'All to ~margins'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+P',            -- All to margins
                                   'ReflowAll' ||
                                   \1'Reformat all to fit the current margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_reflowblock', i);
   buildmenuitem menuname, mid, i, '~Block'\9 || ALT_KEY__MSG'+R',                                       -- Block
                                   'ReflowBlock' ||
                                   \1'Mark lines or block first, then mark new block size',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to ~window',                                                     -- Par to window
                                   'Reflow' ||
                                   \1'Reformat paragraph to fit the current window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to si~ze...',                                                    -- Par to size...
                                   'Reflow *' ||
                                   \1'Reformat paragraph, prompt for a size',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to last ~size',                                                  -- Par to last size
                                   'Reflow =' ||
                                   \1'Reformat paragraph, use last specified size',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Mai~l (all)',                                                        -- Mail (all)
                                   'reflowmail' ||
                                   \1'Reformat current email',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Wordpro~c (all)',                                                    -- Wordproc (all)
                                   'wordproc' ||
                                   \1'Rejoin lines to prepare for export to a word processor',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_twospaces', i);
   buildmenuitem menuname, mid, i, '~Two spaces',                                                        -- Two spaces
                                   'Toggle_Two_Spaces' ||
                                   \1'Put 2 spaces after periods etc.',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_mailindentedlines', i);
   buildmenuitem menuname, mid, i, 'Mail: reflow ~indented lines',                                       -- Mail: reflow indented lines
                                   'toggle_mail_indented' ||
                                   \1'Include indented lines',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_mailindentlists', i);
   buildmenuitem menuname, mid, i, 'Mail: indent ~list items',                                           -- Mail: indent list items
                                   'toggle_mail_indent_lists' ||
                                   \1'Indent lines of list items',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_reflownext', i);
   buildmenuitem menuname, mid, i, 'Reflow ne~xt',                                                       -- Reflow next
                                   'Toggle_Reflow_Next' ||
                                   \1'Move cursor to next par after reflow',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_joinafterwrap', i);
   buildmenuitem menuname, mid, i, '~Join after wrap',                                                   -- Join after wrap
                                   'Toggle_Join_After_Wrap' ||
                                   \1'Join next line with wrapped part',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_moreformatting', i);
   buildmenuitem menuname, mid, i, '~More formatting',                                             -- More formatting   >
                                   '' ||
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Expand tabs to spaces...',                                          -- Expand tabs to spaces...
                                   'Tabs2Spaces' ||
                                   \1'Tabwidth is selectable',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Compress spaces to tabs...',                                        -- Compress spaces to tabs...
                                   'Spaces2Tabs' ||
                                   \1'Tabwidth is selectable; use this instead of "Save /t"',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Remove ~HTML',                                                       -- Remove HTML
                                   'unhtml' ||
                                   \1'Remove HTML tags from current file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Singlespace',                                                       -- Singlespace
                                   'singlespace' ||
                                   \1'Remove duplicated line ends',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Validate HTML...',                                                  -- Validate HTML
                                   'ValidateHtml' ||
                                   \1'Check syntax of a HTML file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'V~alidate CSS...',                                                   -- Validate CSS
                                   'ValidateCss' ||
                                   \1'Check syntax of a CSS file',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'S~ort',                                                        -- Sort
                                   'Sort' ||
                                   \1'Sort marked lines (undo not possible)',
                                   MIS_TEXT, 0
if recodefound then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Reco~de...',                                                   -- Recode...
                                   'recode' ||
                                   \1'Change codepage of current file and reload it, keep filedate',
                                   MIS_TEXT, 0
endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'C~ase',                                                        -- Case   >
                                   \1'Change case of text',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Word ~toggle'\9CTRL_KEY__MSG'+F1',                                   -- Word toggle
                                   'CaseWord' ||
                                   \1'Toggle word through mixed, upper and lower cases',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Word ~uppercase'\9CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+F2',               -- Word uppercase
                                   'UppercaseWord' ||
                                   \1'Change word to uppercase',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Word ~lowercase'\9CTRL_KEY__MSG'+F2',                                -- Word lowercase
                                   'LowercaseWord' ||
                                   \1'Change word to uppercase',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Mark u~ppercase'\9CTRL_KEY__MSG'+F3',                                -- Mark uppercase
                                   'UppercaseMark' ||
                                   \1'Change mark to uppercase',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Mark l~owercase'\9CTRL_KEY__MSG'+F4',                                -- Mark lowercase
                                   'LowercaseMark' ||
                                   \1'Change mark to lowercase',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Comment'\9 || ALT_KEY__MSG'+K',                               -- Comment
                                   'comment' ||
                                   \1'Comment marked lines',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Uncomment'\9 || ALT_KEY__MSG'+'SHIFT_KEY__MSG'+K',            -- Uncomment
                                   'uncomment' ||
                                   \1'Remove comment chars for marked lines',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Indent lines/block'\9 || ALT_KEY__MSG'+I',                    -- Indent lines/block
                                   'indentblock' ||
                                   \1'Indent marked lines or block starting at cursor 1 level',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'U~nindent lines/block'\9 || ALT_KEY__MSG'+'SHIFT_KEY__MSG'+I',  -- Unindent lines/block
                                   'indentblock U' ||
                                   \1'Unindent marked lines or block starting at cursor 1 level',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Shift ~left'\9 || CTRL_KEY__MSG'+F7',                          -- Shift left
                                   'key 1 c_f7' ||
                                   \1'Shift marked text left 1 character',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Shift right'\9 || CTRL_KEY__MSG'+F8',                         -- Shift right
                                   'key 1 c_f8' ||
                                   \1'Shift marked text right 1 character',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Font st~yles',                                                 -- Font styles   >
                                   '' ||
                                   \1'Font and color attributes',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'St~yle dialog...'\9 || CTRL_KEY__MSG'+Y',                            -- Style dialog...
                                   'fontlist' ||
                                   STYLE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_STYLE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Apply style...'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+Y',            -- Apply style...
                                   'linkexec stylebut apply_style S' ||
                                   \1'Select font style to apply on mark or all',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Remove attributes around cursor',                                   -- Remove attributes around cursor
                                   'linkexec stylebut remove_style S' ||
                                   \1'Remove color and font attributes',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'R~emove all attributes',                                             -- Remove all attributes
                                   'DelAttribs' ||
                                   \1'Remove all attributes, even bookmarks, from current file',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   return


; -------------------------------------------------------------------------------------- Search -----------------------
defproc add_search_menu(menuname)
   universal nodismiss
   universal grepfound
   universal gfcfound
   mid = GetAVar('mid_search')
   i = mid'00'
   buildsubmenu  menuname, mid, SEARCH_BAR__MSG,                                                   -- Search ----------
                                ''SEARCH_BARP__MSG,
                                0, mpfrom2short(HP_SEARCH, 0)  -- MIS must be 0 for submenu
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Search dialog...'\9 || CTRL_KEY__MSG'+S',                     -- Search dialog...
                                   'searchdlg' ||
                                   SEARCH_MENUP__MSG' (ignores B and T options)',
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_SEARCH, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_findnext', i);
   buildmenuitem menuname, mid, i, FIND_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+F',                     -- Find next
                                   'searchdlg F' ||
                                   FIND_NEXT_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_FIND, 0)
   i = i + 1; call SetAVar( 'mid_changenext', i);
   buildmenuitem menuname, mid, i, CHANGE_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+C',                   -- Change next
                                   'searchdlg C' ||
                                   CHANGE_NEXT_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_CHANGE, 0)
   i = i + 1; call SetAVar( 'mid_globalfindnext', i);
   buildmenuitem menuname, mid, i, '~Ring find next'\9 || CTRL_KEY__MSG'+V',                       -- Ring find next
                                   'ringfind' ||
                                   \1'Repeat previous Locate command for all files in the ring',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_globalchangenext', i);
   buildmenuitem menuname, mid, i, 'Ring c~hange next',                                            -- Ring change next
                                   'ringchange' ||
                                   \1'Repeat previous Change command for all files in the ring',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchbackwards', i);
   buildmenuitem menuname, mid, i, 'Backwar~d'\9 || CTRL_KEY__MSG'+-',                             -- Backward
                                   'toggle_search_backward' ||
                                   \1'Toggle back/forward for next locate/change commands',
                                   MIS_TEXT, nodismiss
if grepfound then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Grep...',                                                     -- Grep...
                                   'GrepDlg' ||
                                   \1'Scan external files using regular expressions',
                                   MIS_TEXT, 0
endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Find ~indentifier'\9 || CTRL_KEY__MSG'+W',                     -- Find identifier
                                   'findword' ||
                                   \1'Find identifier (C-style word) under cursor',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_findmark', i);
   buildmenuitem menuname, mid, i, 'Find ~mark/word',                                              -- Find mark
                                   'findmark' ||
                                   \1'Find marked string else word under cursor',
                                   MIS_TEXT, 0
if grepfound then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Find defi~nition'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+D',     -- Find definition
                                   'finddef' ||
                                   \1'Find def. in source files for identifier under cursor',
                                   MIS_TEXT, 0
endif
/*
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Show search args',                                             -- ShowSearchArgs
                                   'ShowSearch' ||
                                   \1'Show last find/change args',
                                   MIS_TEXT, 0
*/
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Find brac~ket'\9 || CTRL_KEY__MSG'+[ | 'CTRL_KEY__MSG'+8',     -- Find bracket
                                   'passist' ||
                                   \1'Find matching environment expression',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_goto', i);
   buildmenuitem menuname, mid, i, 'G~o to',                                                       -- Go to   >
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Line...'\9,                                                         -- Go to line
                                   'GotoLineDlg' ||
                                   \1'Change line and optionally column',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_gotomark', i);
   buildmenuitem menuname, mid, i, '~Mark'\9 || ALT_KEY__MSG'+Y',                                        -- Go to mark
                                   'BeginMark' ||
                                   \1'Position cursor on begin of marked area',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Show ~cursor'\9 || SHIFT_KEY__MSG'+F5, 'ALT_KEY__MSG'+-',            -- Show cursor
                                   'mc /centerline/highlightcursor' ||
                                   \1'Center line with cursor',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_markstack', i);
   buildmenuitem menuname, mid, i, '~Mark stack',                                                  -- Mark stack   >
                                   \1'Save and restore a marked area',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_savemark', i);
   buildmenuitem menuname, mid, i, PUSH_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'DOWN_KEY__MSG,  -- Save mark
                                   'pushmark' ||
                                   PUSH_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PUSHMARK, 0)
   i = i + 1; call SetAVar( 'mid_restoremark', i);
   buildmenuitem menuname, mid, i, POP_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'UP_KEY__MSG,     -- Restore mark
                                   'popmark' ||
                                   POP_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_POPMARK, MIA_DISABLED)
   i = i + 1; call SetAVar( 'mid_swapmark', i);
   buildmenuitem menuname, mid, i, SWAP_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+= | 'CTRL_KEY__MSG'+'SHIFT_KEY__MSG'++',  -- Swap mark
                                   'swapmark' ||
                                   SWAP_MARK_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_EDIT_SWAPMARK, MIA_DISABLED)
   i = i + 1; call SetAVar( 'mid_cursorstack', i);
   buildmenuitem menuname, mid, i, 'C~ursor stack',                                                -- Cursor stack   >
                                   \1'Save and restore cursor position',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_savecursor', 1);
   buildmenuitem menuname, mid, i, PUSH_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'DOWN_KEY__MSG,             -- Save cursor
                                   'pushpos' ||
                                   PUSH_CURSOR_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PUSHPOS, 0)
   i = i + 1; call SetAVar( 'mid_restorecursor', i);
   buildmenuitem menuname, mid, i, POP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'UP_KEY__MSG,                -- Restore cursor
                                   'poppos' ||
                                   POP_CURSOR_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_POPPOS, MIA_DISABLED)
   i = i + 1; call SetAVar( 'mid_swapcursor', i);
   buildmenuitem menuname, mid, i, SWAP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+= | 'CTRL_KEY__MSG'+0' ,                         -- Swap cursor
                                   'swappos' ||
                                   SWAP_CURSOR_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_EDIT_SWAPPOS, MIA_DISABLED)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_bookmarks', i);
   buildmenuitem menuname, mid, i, BOOKMARKS_MENU__MSG,                                            -- Bookmarks   >
                                   \1'Set and jump to bookmarks',
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
   i = i + 1; call SetAVar( 'mid_bookmarks_set', i);
   buildmenuitem menuname, mid, i, SET_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+M',                            -- Set...
                                   'setmark' ||
                                   SET_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
   i = i + 1; call SetAVar( 'mid_bookmarks_list', i);
   buildmenuitem menuname, mid, i, LIST_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+B',                           -- List...
                                   'listmark' ||
                                   LIST_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_bookmarks_next', i);
   buildmenuitem menuname, mid, i, NEXT_MARK_MENU__MSG\9 || ALT_KEY__MSG'+/',                            -- Next
                                   'nextbookmark' ||
                                   NEXT_MARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
   i = i + 1; call SetAVar( 'mid_bookmarks_previous', i);
   buildmenuitem menuname, mid, i, PREV_MARK_MENU__MSG\9 || ALT_KEY__MSG'+\',                            -- Previous
                                   'nextbookmark P' ||
                                   PREV_MARK_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, TAGS_MENU__MSG,                                                 -- Tags   >
                                   \1'Find function in a tags file',
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, TAGSDLG_MENU__MSG\9,                                                  -- Tags dialog...
                                   'poptagsdlg' ||
                                   TAGSDLG_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'S~elect tags file...'\9 || SHIFT_KEY__MSG'+F8',                       -- Select tags file...
                                   'tagsfile' ||
                                   \1'Select a new tags file',
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Refresh tags file...'\9 || SHIFT_KEY__MSG'+F9',                      -- Refresh tags file...
                                   'maketags *' ||
                                   \1'Enter file masks for current tags file and rebuild it',
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, FIND_TAG_MENU__MSG\9 || SHIFT_KEY__MSG'+F6',                          -- Find current procedure
                                   'findtag' ||
                                   FIND_TAG_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, FIND_TAG2_MENU__MSG\9 || SHIFT_KEY__MSG'+F7',                         -- Find procedure...
                                   'findtag *' ||
                                   FIND_TAG2_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, SCAN_TAGS_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+T',          -- Scan current file...
                                   'tagscan' ||
                                   SCAN_TAGS_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_SEARCH_TAGS, 0)

   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
if gfcfound then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'GFC curr~ent file...',                                         -- GFC current file
                                   'GfcCurrentFile' ||
                                   \1'Compare current file with another',
                                   MIS_TEXT, 0
endif
   i = i + 1;
   buildmenuitem menuname, mid, i, '~All /<string>...',                                            -- All /<string>...
                                   'commandline all /' ||
                                   \1'List all occurances, then use Ctrl+Q to toggle',
                                   MIS_TEXT, 0
   return

; -------------------------------------------------------------------------------------- View -------------------------
defproc add_view_menu(menuname)
   universal nodismiss
   universal ring_enabled
   universal MenuItemsHidden
   mid = GetAVar('mid_view')
   i = mid'00'
   buildsubmenu  menuname, mid, '~View',                                                           -- View ------------
                                \1'Menus related to views, cursor pos and windows',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1; call SetAVar( 'mid_menu', i);
   buildmenuitem menuname, mid, i, 'M~enu',                                                        -- Menu   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Select ~menu...',                                                    -- Select menu
                                   'ChangeMenu' ||
                                   \1'Open a listbox and change or refresh the menu',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_nodismiss', i);
   buildmenuitem menuname, mid, i, '~Nodismiss menus',                                                   -- Nodismiss menus
                                   'toggle_nodismiss' ||
                                   \1'Keep menu open after selecting menu items',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_hidemenuitems', i);
   buildmenuitem menuname, mid, i, 'Hide ~Options and View menu items',                                  -- Hide Options and View menu items
                                   'HideMenuItems TOGGLE' ||
                                   \1'Required to add menus like HTMLTAGS',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
 if not MenuItemsHidden then
   i = i + 1; call SetAVar( 'mid_infobars', i);
   buildmenuitem menuname, mid, i, '~Info bars',                                                   -- Info bars   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_showlongname', i);
   buildmenuitem menuname, mid, i, 'Show .~LONGNAME',                                                    -- Show .LONGNAME
                                   'toggle_longname' ||
                                   \1'Show .LONGNAME EA as filename in titlebar',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_messageline', i);
   buildmenuitem menuname, mid, i, MSG_LINE_MENU__MSG,                                                   -- Message line
                                   'toggleframe 2' ||
                                   MSG_LINE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_MESSAGE, nodismiss)
   i = i + 1; call SetAVar( 'mid_statusbar', i);
   buildmenuitem menuname, mid, i, 'Status ~bar',                                                        -- Status bar
                                   'toggleframe 1' ||
                                   STATUS_LINE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_STATUS, nodismiss)
   i = i + 1; call SetAVar( 'mid_infoattop', i);
   buildmenuitem menuname, mid, i, INFOATTOP_MENU__MSG,                                                  -- Info at top
                                   'toggleframe 32' ||
                                   INFOATTOP_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_EXTRAPOS, nodismiss)
   i = i + 1; call SetAVar( 'mid_prompting', i);
   buildmenuitem menuname, mid, i, PROMPTING_MENU__MSG,                                                  -- Prompting
                                   'toggleprompt' ||
                                   PROMPTING_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_PROMPT, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure ~title bar...',                                            -- Configure title bar...
                                   'ConfigInfoLine TITLE' ||
                                   \1'Change layout of titletext',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure status ~bar...',                                           -- Configure status bar...
                                   'ConfigInfoLine STATUS' ||
                                   \1'Change layout of status bar',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure ~separator...',                                            -- Configure separator...
                                   'ConfigInfoLine SEP' ||
                                   \1'Change layout of separator for title and status bar',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_toolbar', i);
   buildmenuitem menuname, mid, i, '~Toolbar',                                                     -- Toolbar   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_toolbarenabled', i);
   buildmenuitem menuname, mid, i, '~Enabled',                                                           -- Enabled
                                   'toggle_toolbar' ||
                                   TOGGLETOOLBAR_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_TOOLBAR_TOGGLE, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Select...',                                                         -- Select...
                                   'LoadToolbar' ||
                                   \1'Open a listbox and load, reload or delete a toolbar',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_toolbarstyle', i);
   buildmenuitem menuname, mid, i, 'St~yle',                                                             -- Style   >
                                   \1'Configure toolbar style',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_toolbartext', i);
   buildmenuitem menuname, mid, i, '~Text',                                                                    -- Text
                                   'toggle_toolbar_text' ||
                                   \1'Show button text',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                         --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_toolbarautosize', i);
   buildmenuitem menuname, mid, i, '~Automatic size',                                                          -- Automatic size
                                   'toggle_toolbar_autosize' ||
                                   \1'Adjust button sizes to the .bmp sizes',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_toolbarsize', i); call SetAVar( 'mtxt_toolbarsize', '~Size: [x]...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_toolbarsize'),                                               -- Size: [26x26]...
                                   'ToolbarSize' ||
                                   \1'Default = 26x26, add 4x4 to the .bmp size',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_toolbarscaling', i); call SetAVar( 'mtxt_toolbarscaling', 'S~caling: []')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_toolbarscaling'),                                            -- Scaling: [and]
                                   'toggle_toolbar_scaling' ||
                                   \1'In most cases "and" looks best',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save ~as...',                                                        -- Save as...
                                   'SaveToolbar' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Import...',                                                         -- Import...
                                   'ImportToolbar' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'E~xport...',                                                         -- Export...
                                   'ExportToolbar' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_backgroundbitmap', i);
   buildmenuitem menuname, mid, i, 'Bac~kground bitmap',                                           -- Background bitmap   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_backgroundbitmapenabled', i);
   buildmenuitem menuname, mid, i, '~Enabled',                                                           -- Enabled
                                   'toggle_bitmap' ||
                                   TOGGLEBITMAP_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_BITMAP, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Select...',                                                         -- Select...
                                   'SetBackgroundBitmap SELECT' ||
                                   \1'Select a background bitmap',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Color palette',                                               -- Color palette...
                                   '' ||
                                   \1'Modify EPM''s 16-color palette (e.g. used for highlighting)',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Create palette objects...',                                         -- Create palette objects...
                                   'ChgPal 1' ||
                                   \1'Use MyColors for your own colors',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~View palette objects...',                                           -- View palette objects...
                                   'rx Open %NEPMD_USERDIR%\bin' ||
                                   \1'Open folder of palette objects',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Read palette objects...',                                           -- Read palette objects...
                                   'ChgPal2 2' ||
                                   \1'Write colors to EPMColor.ini',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Select color palette...',                                           -- Select color palette...
                                   'CheckChgPal 3' ||
                                   \1'Select from EPMcolor.ini, then patch dll',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
 endif  -- not MenuItemsHidden
   -- With hidden menu items, the separator before Ring enabled is sometimes checked.
   -- Therefore always use a new unique i for the items after the hidden ones:
   i = GetAVar('mid_view2')'00'
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_softwrap', i);
   buildmenuitem menuname, mid, i, 'Soft ~wrap',                                                   -- Soft wrap
                                   'ToggleWrap' ||
                                   \1'Toggle non-destructive wrap at window width',
                                   MIS_TEXT, 0
   -- Check for a cmd of a linked file won't work here, because the menu is already built by 'initconfig'.
   if isadefc('fold') | (FindFileInList( 'fold.ex', Get_Env( 'EPMEXPATH')) > '') then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Fold',                                                        -- Fold
                                   'fold' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Unfold',                                                      -- Unfold
                                   'fold off' ||
                                   \1'',
                                   MIS_TEXT, 0
   endif  -- isadefc('fold')
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_ringenabled', i);
   buildmenuitem menuname, mid, i, RINGENABLED_MENU__MSG,                                          -- Ring enabled
                                   'ring_toggle' ||
                                   RINGENABLED_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_RINGENABLE, 0)
;   if ring_enabled then
   i = i + 1; call SetAVar( 'mid_listring', i);
   buildmenuitem menuname, mid, i, LIST_FILES_MENU__MSG\9 || CTRL_KEY__MSG'+G',                    -- List ring...
                                   'Ring_More' ||
                                   LIST_FILES_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_LIST, 0)
;   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, MESSAGES_MENU__MSG,                                             -- Messages...
                                   'messagebox' ||
                                   MESSAGES_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_MESSAGES, 0)
   if ring_enabled then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Add new ~view',                                                -- Add new view
                                   'e /v =' ||
                                   \1'Create another synchronized view of the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_nextview', i);
   buildmenuitem menuname, mid, i, 'Switch to ne~xt view',                                         -- Switch to next view
                                   'nextview' ||
                                   \1'Activate the next view of the current file',
                                   MIS_TEXT, 0
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open in ~new window',                                          -- Open in new window
                                   'newwindow' ||
                                   \1'Move current file to a new window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open in ~bin mode',                                            -- Open in bin mode
                                   "open 'binedit ='" ||
                                   \1'Open current file in a new window in binedit mode',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Switch to next window'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+F12',   -- Switch to next window
                                   'next_win' ||
                                   \1'Activate the next EPM window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Load file'\9 || ALT_KEY__MSG'+1',                             -- Load file
                                   'alt_1' ||
                                   \1'Load file under cursor',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_keywordhelp', i);
   buildmenuitem menuname, mid, i, 'Key~word help',                                                -- Keyword help
                                   '' ||
                                   \1'View documentation for a keyword (defined via .ndx files)',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_keywordhelpcurrentword', i);
   buildmenuitem menuname, mid, i, '~Current word'\9CTRL_KEY__MSG'+H',                                   -- Current word
                                   'kwhelp' ||
                                   \1'View documentation for keyword under cursor',
                                   0, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Word...',                                                           -- Word...
                                   'kwhelp ?' ||
                                   \1'Prompt for a keyword, then view documentation for it',
                                   0, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_usenewview', i);
   buildmenuitem menuname, mid, i, 'Use ~NewView if found',                                              -- Use NewView if found
                                   'toggle_use_newview' ||
                                   \1'NiewView.exe is searched in PATH and used if found',
                                   0, nodismiss
   i = i + 1; call SetAVar( 'mid_usenewviewxsearch', i);
   buildmenuitem menuname, mid, i, 'Use NewView''s ~extended search',                                    -- Use NewView's extended search
                                   'toggle_newview_xsearch' ||
                                   \1'Search in text instead of just a topic search',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   return

; -------------------------------------------------------------------------------------- Options ----------------------
defproc add_options_menu(menuname)
   universal ring_enabled
   universal font
   universal nodismiss
   universal MenuItemsHidden
   universal WpsStarted
   universal vautosave_path
   UserDir = Get_Env( 'NEPMD_USERDIR')
   UserDirName = substr( UserDir, lastpos( '\', UserDir) + 1)

   mid = GetAVar('mid_options')
   i = mid'00'
   buildsubmenu  menuname, mid, OPTIONS_BAR__MSG,                                                  -- Options ---------
                                \1'Menus related to global and default editor settings',
                                0, mpfrom2short(HP_OPTIONS, 0)  -- MIS must be 0 for submenu
 if not MenuItemsHidden then
   i = i + 1; call SetAVar( 'mid_editoptions', i); call SetAVar( 'mtxt_editoptions', '~Edit   []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_editoptions'),                                    -- Edit   >
                                   ''\1'View/change default edit options',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_editoptions_b', i)
   buildmenuitem menuname, mid, i, '/~b'\9'search both: ring and disk*',
                                   'seteditoptions /b',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_editoptions_c', i)
   buildmenuitem menuname, mid, i, '/~c'\9'create a new file',
                                   'seteditoptions /c',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_editoptions_d', i)
   buildmenuitem menuname, mid, i, '/~d'\9'create new if on disk',
                                   'seteditoptions /d',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_editoptions_nt', i)
   buildmenuitem menuname, mid, i, '/~nt'\9'expand tabs (tabs = 8)',
                                   'seteditoptions /nt',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_editoptions_t', i)
   buildmenuitem menuname, mid, i, '/~t'\9'don''t expand tabs*',
                                   'seteditoptions /t',
                                   MIS_TEXT, nodismiss
; In EPM 6 there's no difference between /u and /l anymore.
; EPM breaks lines at CRCRLF, CRLF, CR and LF, not dependent on /u or /l.
; EPM adds CRLF when Enter is pressed. That can't be changed with an option.
; /u and /l are senseless now.
; Per default all line ends are kept as on file loading. Even 'unterminated'
; is possible for the last line. (But it's not visible, if the last line is
; terminated or not. EPM won't add a blank line, if the last line is terminated.)
; Line ends can be forced to CRLF or CR on save. That applies also to the last line.
;    i = i + 1;
;    buildmenuitem menuname, mid, i, \0,                                                                   --------------------
;                                    '',
;                                    MIS_SEPARATOR, 0
;    i = i + 1; call SetAVar( 'mid_editoptions_u', i)
;    buildmenuitem menuname, mid, i, '/~u'\9'Unix line end (LF)',
;                                    'seteditoptions /u',
;                                    MIS_TEXT, nodismiss
;    i = i + 1; call SetAVar( 'mid_editoptions_l', i)
;    buildmenuitem menuname, mid, i, '/~l'\9'DOS line end (CRLF)*',
;                                    'seteditoptions /l',
;                                    MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'~Reset to initial default (*)',
                                   'seteditoptions RESET',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Sa~ve as default',
                                   'seteditoptions SAVE',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_saveoptions', i); call SetAVar( 'mtxt_saveoptions', 'Sa~ve   []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_saveoptions'),                                    -- Save   >
                                   ''\1'View/change default save options',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_saveoptions_ns', i)
   buildmenuitem menuname, mid, i, '/ns'\9'~don''t strip spaces',
                                   'setsaveoptions /ns',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_s', i)
   buildmenuitem menuname, mid, i, '/~s'\9'strip trailing spaces*',
                                   'setsaveoptions /s',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_saveoptions_nt', i)
   buildmenuitem menuname, mid, i, '/nt'\9'don''t compress s~paces*',
                                   'setsaveoptions /nt',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_t', i)
   buildmenuitem menuname, mid, i, '/~t'\9'compress spaces to tabs (tabs = 8, buggy!)',
                                   'setsaveoptions /t',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_saveoptions_ne', i)
   buildmenuitem menuname, mid, i, '/~ne'\9'no file end char*',
                                   'setsaveoptions /ne',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_e', i)
   buildmenuitem menuname, mid, i, '/~e'\9'append a file end char',
                                   'setsaveoptions /e',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_saveoptions_a', i)
   buildmenuitem menuname, mid, i, ''\9'~auto-line-end (maybe mixed)',
                                   'setsaveoptions /a',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_o', i)
   buildmenuitem menuname, mid, i, '/~o'\9'force DOS line end (CRLF)*',
                                   'setsaveoptions /o',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_l', i)
   buildmenuitem menuname, mid, i, '/~l'\9'force Unix line end (LF)',
                                   'setsaveoptions /l',
                                   MIS_TEXT, nodismiss
                              -- /u is the same as /l /ne
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                    --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Reset to initial ~default (*)',
                                   'setsaveoptions RESET',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Sa~ve as default',
                                   'setsaveoptions SAVE',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_searchoptions', i); call SetAVar( 'mtxt_searchoptions', '~Search   []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_searchoptions'),                                  -- Search   >
                                   ''\1'View/change default search options',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_+', i)
   buildmenuitem menuname, mid, i, '~+'\9'down: top to bottom*',
                                   'setsearchoptions +',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_-', i)
   buildmenuitem menuname, mid, i, '~-'\9'up: bottom to top',
                                   'setsearchoptions -',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_f', i)
   buildmenuitem menuname, mid, i, '~f'\9'foreward: left to right*',
                                   'setsearchoptions f',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_r', i)
   buildmenuitem menuname, mid, i, '~r'\9'reverse: right to left',
                                   'setsearchoptions r',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_u', i)
   buildmenuitem menuname, mid, i, ''\9'start at c~ursor*',
                                   'setsearchoptions u',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_t', i)
   buildmenuitem menuname, mid, i, '~t'\9'start at top of file',
                                   'setsearchoptions t',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_b', i)
   buildmenuitem menuname, mid, i, '~b'\9'start at bottom of file',
                                   'setsearchoptions b',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_a', i)
   buildmenuitem menuname, mid, i, '~a'\9'all: in the whole file*',
                                   'setsearchoptions a',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_m', i)
   buildmenuitem menuname, mid, i, '~m'\9'mark: in mark only',
                                   'setsearchoptions m',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_e', i)
   buildmenuitem menuname, mid, i, '~e'\9'case-sensitive',
                                   'setsearchoptions e',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_c', i)
   buildmenuitem menuname, mid, i, '~c'\9'ignore case*',
                                   'setsearchoptions c',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_i', i)
   buildmenuitem menuname, mid, i, ''\9'~including search*',
                                   'setsearchoptions i',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_^', i)
   buildmenuitem menuname, mid, i, '~^'\9'excluding search',  -- options ~ and ^ are equivalent
                                   'setsearchoptions ^',
                                   MIS_TEXT, nodismiss
                                                                                                   --------------------------
   i = i + 1; call SetAVar( 'mid_searchoptions_h', i)
   buildmenuitem menuname, mid, i, ''\9'c~hars*',
                                   'setsearchoptions h',
                                   MIS_TEXT + MIS_BREAKSEPARATOR, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_g', i)
   buildmenuitem menuname, mid, i, '~g'\9'grep',
                                   'setsearchoptions g',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_x', i)
   buildmenuitem menuname, mid, i, '~x'\9'egrep',
                                   'setsearchoptions x',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_w', i)
   buildmenuitem menuname, mid, i, '~w'\9'words',
                                   'setsearchoptions w',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_p', i)
   buildmenuitem menuname, mid, i, ''\9'change: re~place sets case*',
                                   'setsearchoptions p',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_k', i)
   buildmenuitem menuname, mid, i, '~k'\9'change: keep case of search',
                                   'setsearchoptions k',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_1', i)
   buildmenuitem menuname, mid, i, ''\9'change ~1 only*',
                                   'setsearchoptions 1',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_*', i)
   buildmenuitem menuname, mid, i, '~*'\9'change all',
                                   'setsearchoptions *',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_q', i)
   buildmenuitem menuname, mid, i, ''\9'change: ~quiet*',
                                   'setsearchoptions q',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_searchoptions_n', i)
   buildmenuitem menuname, mid, i, '~n'\9'change: msg how many changes',
                                   'setsearchoptions n',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Reset to initial ~default (*)',
                                   'setsearchoptions RESET',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Sa~ve as default',
                                   'setsearchoptions SAVE',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
 endif  -- not MenuItemsHidden
   -- With hidden menu items, the following menu item has the text of the Edit menu item.
   -- Always use the first available i for it to make it unique:
   i = GetAVar('mid_options2')'00'
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Default settings dialog...',                                  -- Default settings dialog...
                                   'configdlg' ||
                                   CONFIG_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CONFIG, 0)
 if not MenuItemsHidden then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0

   i = i + 1; call SetAVar( 'mid_modesettings', i);
   buildmenuitem menuname, mid, i, 'M~odes',                                                       -- Modes  >
                                   'Configure general mode settings',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_defaultkeywordhighlighting', i);
   buildmenuitem menuname, mid, i, 'Default keyword ~highlighting enabled',                              -- Default keyword highlighting enabled
                                   'toggle_default_highlight' ||
                                   \1'Switch keyword highlighting on',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_autorefreshmodefiles', i);
   buildmenuitem menuname, mid, i, '~Auto-check mode files',                                             -- Auto-check mode files
                                   'toggle_modefiles_autorefresh' ||
                                   \1'Check for altered .hil/.ini files on file loading',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_checkmodefilesnow', i); call SetAVar( 'mtxt_checkmodefilesnow', 'Check mode files ~now for mode #CURMODE#');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_checkmodefilesnow'),                                   -- Check mode files now for mode CURMODE
                                   'ActivateHighlighting' ||
                                   \1'Check for altered .hil/.ini files for current mode now',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_openmodedirs', i); call SetAVar( 'mtxt_openmodedirs', 'Open mode files ~directories for mode #CURMODE#');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_openmodedirs'),                                        -- Open mode files directories for mode CURMODE
                                   'OpenModeDirs' ||
                                   \1'Open dir(s) with .hil/.ini files',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_defaultsyntaxexpansion', i);
   buildmenuitem menuname, mid, i, 'Default ~syntax expansion enabled',                                  -- Default syntax expansion enabled
                                   'toggle_default_expand' ||
                                   \1'Let space and enter do syntax expansion',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_selectcodingstyle', i); call SetAVar( 'mtxt_selectcodingstyle', 'Select ~coding style [] for mode #CURMODE#...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_selectcodingstyle'),                                   -- Select coding style [] for mode CURMODE...
                                   'SelectCodingStyle' ||
                                   \1'Select a previously defined coding style for current mode',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_editprofile2', i);
   buildmenuitem menuname, mid, i, 'Edit ~PROFILE.ERX',                                                  -- Edit PROFILE.ERX
                                   'e %NEPMD_USERDIR%\bin\profile.erx' ||
                                   \1'Edit REXX configuration file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Edit ~MODECNF.E',                                                    -- Edit MODECNF.E
                                   'EditCreateUserMacro modecnf.e' ||
                                   \1'Edit modes configuration incl. syntax expansion',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
;                                   '',
;                                   MIS_SEPARATOR, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, ' See also: File properties',                                          -- See also: File properties
;                                   '' ||
;                                   \1'',
;                                   MIS_TEXT + MIS_STATIC + MIS_ENDSUBMENU, 0

; Add Home key etc. here?
   i = i + 1; call SetAVar( 'mid_keyssettings', i);
   buildmenuitem menuname, mid, i, '~Keys',                                                        -- Keys  >
                                   \1'Configure key bindings',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_defaultstreammode', i);
   buildmenuitem menuname, mid, i, 'Default ~stream mode enabled',                                       -- Default stream mode enabled
                                   'toggle_default_stream' ||
                                   STREAMMODE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_STREAM, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_keydefs', i); call SetAVar( 'mtxt_keydefs', 'Keyset ~additions: []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_keydefs'),                                             -- Additional key defs []...
                                   'SelectKeyDefs' ||
                                   \1'Configure key def additions to the standard keyset',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Edit STDKEYS.E',                                                    -- Edit STDKEYS.E
                                   'EditCreateUserMacro stdkeys.e' ||
                                   \1'Edit entire set of key definitions',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_blockactionbaraccelerators', i);
   buildmenuitem menuname, mid, i, 'Block ~menu bar accels',                                             -- Block menu bar accels
                                   'accel_toggle' ||
                                   \1'Keep Alt+<key>s for mark operations (Ctrl+Alt works for menu)',
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CUAACCEL, nodismiss)
   i = i + 1; call SetAVar( 'mid_blockleftaltkey', i);
   buildmenuitem menuname, mid, i, 'Block ~left Alt key',                                                -- Block left Alt key
                                   'toggle_block_left_alt_key' ||
                                   \1'Prevent left Alt from entering menu (use F10)',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_blockrightaltkey', i);
   buildmenuitem menuname, mid, i, 'Block ~right Alt key',                                               -- Block right Alt key
                                   'toggle_block_right_alt_key' ||
                                   \1'Prevent right Alt from entering menu (use F10)',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
;   i = i + 1;
;   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
;                                   '',
;                                   MIS_SEPARATOR, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, ' See also: File properties',                                          -- See also: File properties
;                                   '' ||
;                                   \1'',
;                                   MIS_TEXT + MIS_STATIC + MIS_ENDSUBMENU, 0

   i = i + 1; call SetAVar( 'mid_markingsettings', i);
   buildmenuitem menuname, mid, i, 'Markin~g',                                                     -- Marking  >
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_advancedmarking', i);
   buildmenuitem menuname, mid, i, '~Advanced marking enabled',                                          -- Default advanced marking enabled
                                   'toggle_cua_mark' ||
                                   ADVANCEDMARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CUATOGGLE, nodismiss)
   i = i + 1; call SetAVar( 'mid_defaultpaste', i); call SetAVar( 'mtxt_defaultpaste', 'Default paste: []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_defaultpaste'),                                         -- Default paste: [char]
                                   'toggle_default_paste' ||
                                   \1'Style for Sh+Ins/Alt+MB1, add Ctrl/Sh for alt. paste',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_shiftmarkextends', i);
   buildmenuitem menuname, mid, i, '~Sh-mark always extends mark',                                       -- Sh-mark always extends mark
                                   'toggle_shift_mark_extends' ||
                                   \1'Extend mark always or just at boundaries',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_mousestyle', i); call SetAVar( 'mtxt_mousestyle', 'Default mouse mark: []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_mousestyle'),                                           -- Default mouse mark: [char]
                                   'toggle_mousestyle' ||
                                   \1'Mark style for MB1, use Ctrl+MB1 or MB3 for alt. mark',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_dragalwaysmarks', i);
   buildmenuitem menuname, mid, i, '~Drag always marks',                                                 -- Drag always marks
                                   'toggle_drag_always_marks' ||
                                   \1'Every drag starts a new mark (avoid the ''Text already marked'' msg)',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_unmarkaftermove', i);
   buildmenuitem menuname, mid, i, '~Unmark after move',                                                 -- Unmark after move
                                   'toggle_unmark_after_move' ||
                                   \1'Unmark after doing a move mark',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss

   i = i + 1; call SetAVar( 'mid_marginsandtabs', i);
   buildmenuitem menuname, mid, i, 'Margins and ~tabs',                                            -- Margins and tabs  >
                                   'Default margins and tabs',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_defaultmargins', i); call SetAVar( 'mtxt_defaultmargins', 'Default margins []...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_defaultmargins'),                                      -- Default margins...
                                   'DefaultMargins' ||
                                   \1'Change default margins',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_defaulttabs', i); call SetAVar( 'mtxt_defaulttabs', 'Default tabs []...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_defaulttabs'),                                         -- Default tabs...
                                   'DefaultTabs' ||
                                   \1'Change default tabs',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_defaulttabkey', i);
   buildmenuitem menuname, mid, i, 'Default ~tabkey enabled',                                            -- Default Tabkey enabled
                                   'toggle_default_tabkey' ||
                                   \1'Tabkey enters a tab char instead of spaces',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_defaultmatchtab', i);
   buildmenuitem menuname, mid, i, 'Default ~matchtab enabled',                                          -- Default Matchtab enabled
                                   'toggle_default_matchtab' ||
                                   \1'Tabkey goes to word boundaries of prev. line',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_showtabs', i);
   buildmenuitem menuname, mid, i, '~Show tabs',                                                         -- Show tabs
                                   'toggle_tabglyph' ||
                                   \1'Show a circle for every tab char',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
;   i = i + 1;
;   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
;                                   '',
;                                   MIS_SEPARATOR, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, ' See also: File properties',                                          -- See also: File properties
;                                   '' ||
;                                   \1'',
;                                   MIS_TEXT + MIS_STATIC + MIS_ENDSUBMENU, 0

   i = i + 1; call SetAVar( 'mid_readonlyandlock', i);
   buildmenuitem menuname, mid, i, '~Read-only and lock',                                          -- Read-only and lock   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_respectreadonly', i);
   buildmenuitem menuname, mid, i, '~Respect read-only',                                                 -- Respect read-only
                                   'toggle_respect_readonly' ||
                                   \1'Toggle read-only file attribute disables edit mode',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_lockonmodify', i);
   buildmenuitem menuname, mid, i, '~Lock on modify',                                                    -- Lock on modify
                                   'toggle_lock_on_modify' ||
                                   \1'Toggle deny write access if file was modified',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
;   i = i + 1;
;   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
;                                   '',
;                                   MIS_SEPARATOR, 0
;   i = i + 1;
;   buildmenuitem menuname, mid, i, ' See also: File properties',                                          -- See also: File properties
;                                   '' ||
;                                   \1'',
;                                   MIS_TEXT + MIS_STATIC + MIS_ENDSUBMENU, 0

   i = i + 1; call SetAVar( 'mid_cursorsettings', i);
   buildmenuitem menuname, mid, i, 'C~ursor',                                                      -- Cursor  >
                                   'Cursor and scroll settings',
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_OPTIONS_PREFERENCES, 0)
   i = i + 1; call SetAVar( 'mid_keepcursoronscreen', i);
   buildmenuitem menuname, mid, i, '~Keep cursor on screen',                                             -- Keep cursor on screen
                                   'toggle_keep_cursor_on_screen' ||
                                   \1'Synchronize cursor''s vertical pos. with screen',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_scrollafterlocate', i); call SetAVar( 'mtxt_scrollafterlocate', 'Scroll after locate []...');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_scrollafterloacate'),                                   -- Scroll after locate []...
                                   'SetScrollAfterLocate' ||
                                   \1'View found string at a special v-pos.',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0

   i = i + 1; call SetAVar( 'mid_autorestore', i);
   buildmenuitem menuname, mid, i, '~Auto-restore',                                                -- Auto-restore  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_restorecursorpos', i);
   buildmenuitem menuname, mid, i, '~Restore cursor position',                                           -- Restore cursor position
                                   'toggle_restore_pos' ||
                                   \1'Toggle restore of cursor pos. from file''s last save',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_trackhistorylists', i);
   buildmenuitem menuname, mid, i, '~Track additional history lists',                                    -- Track additional history lists
                                   'Toggle_History' ||
                                   \1'Enable edit, load and save history',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_autosavelastring', i);
   buildmenuitem menuname, mid, i, 'Auto-~save last ring',                                               -- Auto-save last ring
                                   'Toggle_Save_Ring' ||
                                   \1'Toggle save of ring on load and quit',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_maxfilessavering', i); call SetAVar( 'mtxt_maxfilessavering', 'Max. [] files for save ring...');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_maxfilessavering'),                                     -- Max. [] files for save ring...
                                   'RingMaxFiles' ||
                                   \1'Set limit of files to enable auto-save',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_autoloadlastring', i);
   buildmenuitem menuname, mid, i, 'Auto-~load last ring',                                               -- Auto-load last ring
                                   'Toggle_Restore_Ring' ||
                                   \1'Toggle restore of ring if EPM is started without args',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss

   i = i + 1; call SetAVar( 'mid_backup', i);
   buildmenuitem menuname, mid, i, '~Backup',                                                      -- Backup  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_autosaveenabled', i);
   buildmenuitem menuname, mid, i, '~Autosave enabled',                                                  -- Autosave enabled
                                   'toggle_autosave' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_autosavenumdialog', i); call SetAVar( 'mtxt_autosavenumdialog', 'After [] ~changes...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_autosavenumdialog'),                                   -- After [] changes...
                                   'AutosaveNum' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_backupenabled', i);
   buildmenuitem menuname, mid, i, '~Backup enabled',                                                    -- Backup enabled
                                   'toggle_backup' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_backupnumdialog', i); call SetAVar( 'mtxt_backupnumdialog', '~Keep [] backups...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_backupnumdialog'),                                     -- Keep [] backups...
                                   'BackupNum' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_backupdirdialog', i); call SetAVar( 'mtxt_backupdirdialog', '~Directory: []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_backupdirdialog'),                                     -- Directory: []...
                                   'BackupDir' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_backuplistdir', i);
   buildmenuitem menuname, mid, i, '~List directory',                                                    -- List directory
                                   'ListBackupDir' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0

   i = i + 1; call SetAVar( 'mid_directories', i);
   buildmenuitem menuname, mid, i, 'Director~ies',                                                 -- Directories  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_workdir', i);
   buildmenuitem menuname, mid, i, 'Set ~work dir',                                                      -- Set work dir  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_workdirprogram', i);
   buildmenuitem menuname, mid, i, '~By program object',                                                       -- By program object
                                   'Set_ChangeWorkDir 0' ||
                                   \1'This is EPM''s default',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_workdirprev', i);
   buildmenuitem menuname, mid, i, '~Use previous work dir',                                                   -- Use previous work dir
                                   'Set_ChangeWorkDir 1' ||
                                   \1'Keep work dir across EPM sessions',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_workdirfile', i);
   buildmenuitem menuname, mid, i, 'To dir of ~selected file',                                                 -- To dir of selected file
                                   'Set_ChangeWorkDir 2' ||
                                   \1'Change to dir of current file',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                         --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~To...',                                                                   -- To...
                                   'CDDlg' ||
                                   \1'Show/change current work dir now',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_opendlgdir', i);
   buildmenuitem menuname, mid, i, '~Start Edit/Add file dialog at',                                     -- Start Edit/Add file dialog at  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_opendlgdirprev', i);
   buildmenuitem menuname, mid, i, '~Previous dir',                                                            -- Previous dir
                                   'set_OpenDlgDir 0' ||
                                   \1'Start at dir from last Open dialog',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_opendlgdirwork', i);
   buildmenuitem menuname, mid, i, '~Work dir',                                                                -- Work dir
                                   'set_OpenDlgDir 1' ||
                                   \1'Start at work dir',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_opendlgdirfile', i);
   buildmenuitem menuname, mid, i, '~Dir of current file',                                                     -- Dir of current file
                                   'set_OpenDlgDir 2' ||
                                   \1'Start at dir of current file',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1; call SetAVar( 'mid_saveasdlgdir', i);
   buildmenuitem menuname, mid, i, 'Start Save-~as dialog for .Untitled at',                             -- Start Save as dialog for .Untitled at  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_saveasdlgdirprev', i);
   buildmenuitem menuname, mid, i, '~Previous dir',                                                            -- Previous dir
                                   'set_SaveasDlgDir 0' ||
                                   \1'Start at dir from last saved file',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveasdlgdirwork', i);
   buildmenuitem menuname, mid, i, '~Work dir',                                                                -- Work dir
                                   'set_SaveasDlgDir 1' ||
                                   \1'Start at work dir',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Edit ~EPM.ENV',                                                      -- Edit EPM.ENV
                                   'EditCreateUserFile bin\epm.env' ||
                                   \1'Edit environment file',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
 if WpsStarted then
   i = i + 1; call SetAVar( 'mid_prg', i);
   buildmenuitem menuname, mid, i, '~Program objects',                                             -- Program objects  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_prgnewwindow', i);
   buildmenuitem menuname, mid, i, '~Open in same window (/r)',                                          -- Open in same window
                                   'toggle_new_same_window' ||
                                   \1'Open files in separate EPM windows',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_prgfullfiledialog', i);
   buildmenuitem menuname, mid, i, 'Use full ~file dialog (/o)',                                         -- Use full file dialog
                                   'toggle_full_file_dialog' ||
                                   \1'Show file dialog instead of history lists',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Set ~startup dir...',                                                -- Set startup dir...
                                   'StartupDirDlg' ||
                                   \1'Select startup dir for several EPM objects',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Set ~associations...',                                               -- Set associations...
                                   'SelectAssoc' ||
                                   \1'Configure WPS associations for EPM objects',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Edit ~list of objects',                                              -- Edit list of objects
                                   'EditCreateUserFile bin\objects.ini' ||
                                   \1'Edit list with configurable program objects',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
 endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   m = GetAVar('mid_options2')'00'
   --sayerror 'Options menu: last item # = 'i', max = 'mid'99.'
   if (i - m) > 99 then
      messageNwait('Error: menuid 'mid' ran out of unique menu item ids. You used 'mid'01 to 'i' out of 'mid'99. Change your menu definition!')
   endif
   i = GetAVar('mid_options3')'00'
   i = i + 1; call SetAVar( 'mid_macros', i);
   buildmenuitem menuname, mid, i, '~Macros',                                                      -- Macros   >
                                   \1'Compile EPM macro files',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Recompile new user macros',                                         -- Recompile new user macros
                                   'RecompileNew' ||
                                   \1'Recompile all new user macros and maybe restart EPM',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Chec~k user macros',                                                 -- Check user macros
                                   'RecompileNew CHECKONLY' ||
                                   \1'Check your EPM macros for outdated/changed files',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Re~start EPM',                                                       -- Restart EPM
                                   'Restart' ||
                                   \1'Restart current EPM window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Compile current .E file',                                           -- Compile current .E file
                                   'etpm =' ||
                                   \1'Compile current macro file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Re~link current .E file',                                            -- Relink current .E file
                                   'relink' ||
                                   \1'Compile current macro file, unlink and link it',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_editprofile', i);
   buildmenuitem menuname, mid, i, 'Edit ~PROFILE.ERX',                                                  -- Edit PROFILE.ERX
                                   'e %NEPMD_USERDIR%\bin\profile.erx' ||
                                   \1'Edit or create REXX configuration file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_activateprofile', i);
   buildmenuitem menuname, mid, i, '~Activate PROFILE.ERX',                                              -- Activate PROFILE.ERX
                                   'toggle_profile' ||
                                   \1'Activate REXX configuration file',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_editmycnf', i);
   buildmenuitem menuname, mid, i, 'Edit MYC~NF.E',                                                      -- Edit MYCNF.E
                                   'e %NEPMD_USERDIR%\macros\mycnf.e' ||
                                   \1'Edit or create E const configuration file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_editmystuff', i);
   buildmenuitem menuname, mid, i, 'Edit MY~STUFF.E',                                                    -- Edit MYSTUFF.E
                                   'e %NEPMD_USERDIR%\macros\mystuff.e' ||
                                   \1'Edit or create E macro additions',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open ~NETLABS\MACROS\*.E',
                                   'o %NEPMD_ROOTDIR%\netlabs\macros\*.e' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open 'upcase(UserDirName)'\MACROS\*.~E',
                                   'o %NEPMD_USERDIR%\macros\*.e' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
/*
   i = i + 1;
   -- this cmd is too long
   buildmenuitem menuname, mid, i, 'Open macro source dirs',
                                   'mc /rx open %NEPMD_USERDIR%\macros /rx open %NEPMD_ROOTDIR%\netlabs\macros' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open compiled macro dirs',
                                   'mc /rx open %NEPMD_USERDIR%\ex /rx open %NEPMD_USERDIR%\autolink' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open EPM.INI',
                                   'rx open ?:\os2\epm.ini' ||
                                   \1,
                                   MIS_TEXT, 0 -- <-------- Todo: get EPM.INI from OS2.INI
*/
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open NEPMD.~INI',
                                   'rx open %NEPMD_USERDIR%\bin\nepmd.ini' ||
                                   \1,
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   if nodismiss > 0 then
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Close menu',                                                  -- Close menu
                                   '' ||
                                   \1,
                                   MIS_TEXT, 0
   endif  -- nodismiss > 0
   m = GetAVar('mid_options3')'00'
   --sayerror 'Options menu: last item # = 'i', max = 'mid'99.'
   if (i - m) > 99 then
      messageNwait('Error: menuid 'mid' ran out of unique menu item ids. You used 'mid'01 to 'i' out of 'mid'99. Change your menu definition!')
   endif
 endif
   return

; -------------------------------------------------------------------------------------- Run --------------------------
; processmenuinit is not executed for mid = 1, but 0 works. Changed menu id
; from 1 to 0 to make processmenuinit work. That hopefully doesn't interfere
; with any external package.
; In SELECT.E the code for the command menu is removed and now added here,
; in menuinit_run.
; The menu ids and the item ids must be unique. There 100 is added if mid = 0
; in order to not overwrite other mids.
defproc add_run_menu(menuname)
   universal nodismiss
   mid = GetAVar('mid_run')
   if mid = 0 then
      i = 100
   else
      i = mid'00'
   endif
   buildsubmenu  menuname, mid, '~Run',                                                            -- Run -------------
                                \1'Menus to execute commands',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1
   buildmenuitem menuname, mid, i, COMMANDLINE_MENU__MSG\9 || CTRL_KEY__MSG'+I | 'ESCAPE_KEY__MSG,  -- Command dialog...
                                   'commandline' ||
                                   COMMANDLINE_MENUP__MSG,
                                   0, mpfrom2short(HP_COMMAND_CMD, 0)
   -- i must be 65535, no key info possible (Ctrl+Brk), executes 'processbreak'
   -- Executing 'processbreak' via command call won't work while another command is
   -- being processed.
   buildmenuitem menuname, mid, 65535, HALT_COMMAND_MENU__MSG,                                     -- Halt command
                                   '',
                                   0, mpfrom2short(HP_COMMAND_HALT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, CREATE_SHELL_MENU__MSG,                                         -- Create command shell
                                   'shell new' ||
                                   \1'Create a command shell buffer',
                                   0, mpfrom2short(HP_COMMAND_SHELL, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Sw~itch command shells',                                       -- Create command shell
                                   'shell' ||
                                   \1'Loop through shell or starting non-shell buffers',
                                   0, mpfrom2short(HP_COMMAND_SHELL, 0)
   i = i + 1; call SetAVar( 'mid_writetoshell', i);                                                -- Write to shell...
   buildmenuitem menuname, mid, i, WRITE_SHELL_MENU__MSG,
                                   'shell_write' ||
                                   WRITE_SHELL_MENUP__MSG,
                                   0, mpfrom2short(HP_COMMAND_WRITE, 0)
   i = i + 1; call SetAVar( 'mid_sendbreaktoshell', i);                                            -- Send break to shell
   buildmenuitem menuname, mid, i, SHELL_BREAK_MENU__MSG,
                                   'shell_break' ||
                                   SHELL_BREAK_MENUP__MSG,
                                   0, mpfrom2short(HP_COMMAND_BREAK, 0)
   i = i + 1; call SetAVar( 'mid_configureshell', i);
   buildmenuitem menuname, mid, i, 'Con~figure command shells',                                    -- Configure command shells  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Set ~init command...',                                               -- Set init command...
                                   'ShellInitCmdDlg' ||
                                   \1'OS/2 command to be executed on start of a shell',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_filenamecompletion', i);
   buildmenuitem menuname, mid, i, 'Activate ~filename completion',                                      -- Activate filename completion
                                   'toggle_filename_completion' ||
                                   \1'Use Tab and Sh+Tab to insert matching filenames',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_alias', i);
   buildmenuitem menuname, mid, i, 'Activate ~aliases',                                                  -- Activate aliases
                                   'toggle_alias' ||
                                   \1'Put an asterisk before a command to temp. disable it',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Edit ALIAS.INI',                                                    -- Edit ALIAS.INI
                                   'EditCreateUserFile bin\alias.ini' ||
                                   \1'Edit alias file for alias configuration',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~OS/2 window',                                                 -- OS/2 window
                                   'start /f /k %comspec%' ||
                                   \1'Open an OS/2 window with NEPMD''s environment',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_treecommands', i);
   buildmenuitem menuname, mid, i, '~Tree commands',                                               -- ~Tree commands   >
                                   '' ||
                                   \1'List a tree and specify a cmd to get executed on every file',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Tree <filemask>...',                                                -- ~Tree <filemask>...
                                   'commandline tree ' ||
                                   \1'List matched files recoursively',
                                   MIS_TEXT, mpfrom2short( 32111 , 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Tree_~dir <filemask>...',                                            -- Tree_~dir <filemask>...
                                   'commandline tree_dir ' ||
                                   \1'List matched files',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_treesort', i);
   buildmenuitem menuname, mid, i, 'Tree~sort <columnname>...',                                          -- Tree~sort <columnname>...
                                   'commandline treesort ' ||
                                   \1'Sort tree listing (use MouseButton 2 alternatively)',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_treeit', i);
   buildmenuitem menuname, mid, i, 'Tree~it <cmd>...',                                                   -- Tree~it <cmd>...
                                   'commandline treeit ' ||
                                   \1'Execute a command on all listed files',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'E~xecute current line'\9 || ALT_KEY__MSG'+= | 'ALT_KEY__MSG'+0',   -- Execute current line
                                   'dokey a_0' ||
                                   \1'Execute line under cursor',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Commandline current ~line'\9 || CTRL_KEY__MSG'+L',             -- Commandline current line
                                   'dokey c_l' ||
                                   \1'Open line under cursor in commandline window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Run current file',                                            -- Run current file
                                   'rx run' ||
                                   \1'Execute current file according to what is def''d in RUN.ERX',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Edit RUN.ERX',                                                -- Edit RUN.ERX
                                   'EditCreateUserFile bin\run.erx' ||
                                   \1'Edit REXX file for Run configuration',
                                   MIS_TEXT, 0
/*
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Run main project file',                                        -- Run main project file
                                   'rx runmain' ||
                                   \1'Execute main project file according to what is def''d in RUN.ERX',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Compile main project file',                                    -- Compile main project file
                                   '' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Select project',                                               -- Select project
                                   '' ||
                                   \1'',
                                   MIS_TEXT, 0
*/
   return

; -------------------------------------------------------------------------------------- Help -------------------------
defproc add_help_menu(menuname)
   universal nodismiss
   mid = GetAVar('mid_help')
   i = mid'00'
   buildsubmenu  menuname, mid, HELP_BAR__MSG,                                                     -- Help ------------
                                HELP_BARP__MSG,
                                0, mpfrom2short(HP_HELP, 0)  -- MIS must be 0 for submenu
   i = i + 1;
   buildmenuitem menuname, mid, i, HELP_INDEX_MENU__MSG,                                           -- Help index
                                   'helpmenu 10'/*64044*/ ||
                                   HELP_INDEX_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_INDEX, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, EXT_HELP_MENU__MSG,                                             -- General help
                                   'helpmenu 4000' ||
                                   EXT_HELP_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_EXTENDED, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, HELP_HELP_MENU__MSG,                                            -- Using help
                                   'helpmenu 64027' ||
                                   HELP_HELP_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_HELP, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, KEYS_HELP_MENU__MSG,                                            -- Keys help
                                   'helpmenu 1000' ||
                                   KEYS_HELP_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_KEYS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, COMMANDS_HELP_MENU__MSG,                                        -- Commands help
                                   'helpmenu 2000' ||
                                   COMMANDS_HELP_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_COMMANDS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, HELP_BROWSER_MENU__MSG,                                         -- Quick reference
                                   'help' ||
                                   HELP_BROWSER_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_BROWSE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
/*
   i = i + 1;
   buildmenuitem menuname, mid, i, HELP_PROD_MENU__MSG,
                                   'IBMmsg' ||                                                     -- Product information
                                   HELP_PROD_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_PROD, 0)
*/
   i = i + 1;
   buildmenuitem menuname, mid, i, 'NEPMD ~runtime information',                                   -- NEPMD runtime information
                                   'nepmdinfo' ||
                                   \1'Lists used DLLs and NEPMD''s dynamic configuration',
                                   0, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
compile if SUPPORT_USERS_GUIDE
   i = i + 1; call SetAVar( 'mid_viewusersguide', i);
   buildmenuitem menuname, mid, i, USERS_GUIDE_MENU__MSG,                                          -- View User's Guide   >
                                   '' ||
                                   USERS_GUIDE_MENUP__MSG,
                                   MIS_TEXT + MIS_SUBMENU /*+ MIS_SYSCOMMAND*/, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
   i = i + 1; call SetAVar( 'mid_usersguide', i);
   buildmenuitem menuname, mid, i, VIEW_USERS_MENU__MSG,                                                 -- View User's Guide
                                   'start view epmusers' ||
                                   VIEW_USERS_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, VIEW_IN_USERS_MENU__MSG,                                              -- Current word
                                   'viewword epmusers' ||
                                   VIEW_IN_USERS_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, VIEW_USERS_SUMMARY_MENU__MSG,                                         -- Summary
                                   'start view epmusers Summary' ||
                                   VIEW_USERS_SUMMARY_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
compile endif
compile if SUPPORT_TECHREF
   i = i + 1; call SetAVar( 'mid_viewtechnicalreference', i);
   buildmenuitem menuname, mid, i, TECHREF_MENU__MSG,                                              -- View Technical Reference   >
                                   '' ||
                                   TECHREF_MENUP__MSG,
                                   MIS_TEXT + MIS_SUBMENU /*+ MIS_SYSCOMMAND*/, mpfrom2short(HP_HELP_TECHREF, 0)
   i = i + 1; call SetAVar( 'mid_technicalreference', i);
   buildmenuitem menuname, mid, i, VIEW_TECHREF_MENU__MSG,                                              -- View Technical Reference
                                   'start view epmtech' ||
                                   VIEW_TECHREF_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_TECHREF, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, VIEW_IN_TECHREF_MENU__MSG,                                            -- Current word
                                   'viewword epmtech' ||
                                   VIEW_IN_TECHREF_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_HELP_TECHREF, 0)
compile endif
   i = i + 1; call SetAVar( 'mid_viewnepmdusersguide', i);
   buildmenuitem menuname, mid, i, 'View ~NEPMD User''s Guide',                                    -- View NEPMD User's Guide   >
                                   '' ||
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU /*+ MIS_SYSCOMMAND*/, 0
   i = i + 1; call SetAVar( 'mid_nepmdusersguide', i);
   buildmenuitem menuname, mid, i, '~View NEPMD User''s Guide',                                          -- View NEPMD User's Guide
                                   'start view neusr%NEPMD_LANGUAGE% netlabs' ||  -- start is used here to resolve environment var
                                   \1'',
                                   0, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Current word',                                                      -- Current word
                                   'viewword neusr%NEPMD_LANGUAGE%' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_viewnepmdprogrammingguide', i);
   buildmenuitem menuname, mid, i, 'View N~EPMD Programming Guide',                                -- View NEPMD Programming Guide   >
                                   '' ||
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU /*+ MIS_SYSCOMMAND*/, 0
   i = i + 1; call SetAVar( 'mid_nepmdprogrammingguide', i);
   buildmenuitem menuname, mid, i, '~View NEPMD Programming Guide',                                      -- View NEPMD Programming Guide
                                   'start view neprg%NEPMD_LANGUAGE% netlabs' ||  -- start is used here to resolve environment var
                                   \1'',
                                   0, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Current word',                                                      -- Current word
                                   'viewword neprg%NEPMD_LANGUAGE%' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   return

; ---------------------------------------------------------------------------
; Syntax for adding menu itens:
;    'cascade_menu' <submenu_mid> [<default menuitem_mid>]
; Better use the optional executed-as-default submenu id here, to have that
; submenu item checked automatically.
; Otherwise the 1st submenu item is executed, but MIA_CHECKED is missing.
defc add_cascade_menus
   'cascade_menu' GetAVar('mid_openfolder') GetAVar('mid_openfolder_defaultview')                -- File -> Open folder
compile if SUPPORT_USERS_GUIDE
   'cascade_menu' GetAVar('mid_viewusersguide') GetAVar('mid_usersguide')                        -- Help -> View User's Guide
compile endif
compile if SUPPORT_TECHREF
   'cascade_menu' GetAVar('mid_viewtechnicalreference') GetAVar('mid_technicalreference')        -- Help -> View Technical Reference
compile endif
   'cascade_menu' GetAVar('mid_viewnepmdusersguide') GetAVar('mid_nepmdusersguide')              -- Help -> NEPMD User Guide
   'cascade_menu' GetAVar('mid_viewnepmdprogrammingguide') GetAVar('mid_nepmdprogrammingguide')  -- Help -> NEPMD Programming Guide
   'cascade_menu' GetAVar('mid_keywordhelp') GetAVar('mid_keywordhelpcurrentword')               -- Help -> Keyword help
   -- CUSTEPM package
compile if defined(CUSTEPM_DEFAULT_SCREEN)
   'cascade_menu' 3700 (CUSTEPM_DEFAULT_SCREEN + 3700)                                           -- Host screen -> Screen ?
compile elseif defined(HAVE_CUSTEPM)
   'cascade_menu' 3700 3701  -- ensure, that the MIA_CHECKED is painted; 1st item is default automatically
compile endif
   -- Execute hook for external packages
   'HookExecute cascademenu'

; ---------------------------------------------------------------------------------------
; The following is individual commands on 5.51+; all part of ProcessMenuInit cmd on earlier versions.
; ---------------------------------------------------------------------------------------
; The menuinit_<mid_name> is called by defc ProcessMenuInit, when the menu id <mid_name>
; is selected. The defc must exist and must be added to the 'definedsubmenus' array var,
; see the SetAVar('definedsubmenus', <list of names>) definition at the top.

; ------------------------------------ File ---------------------------------
defc menuinit_file
   SetMenuAttribute( GetAVar('mid_importfile'),  MIA_DISABLED, .readonly = 0)
   SetMenuAttribute( GetAVar('mid_save'),        MIA_DISABLED, .readonly = 0)
   SetMenuAttribute( GetAVar('mid_saveandquit'), MIA_DISABLED, .readonly = 0)

defc menuinit_fileproperties
   universal stream_mode
   universal expand_on
   universal tab_key
   universal matchtab_on
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
compile endif
   SetMenuAttribute( GetAVar('mid_autospellcheck'),      MIA_CHECKED, .keyset <> 'SPELL_KEYS')
compile if CHECK_FOR_LEXAM
   endif
compile endif
   SetMenuAttribute( GetAVar('mid_readonly'),            MIA_CHECKED, not .readonly)
   SetMenuAttribute( GetAVar('mid_readonlyattrib'),      MIA_CHECKED, not GetReadonly())
   SetMenuAttribute( GetAVar('mid_locked'),              MIA_CHECKED, not .lockhandle)
   SetMenuAttribute( GetAVar('mid_streammode'),          MIA_CHECKED, not stream_mode)
   SetMenuAttribute( GetAVar('mid_syntaxexpansion'),     MIA_CHECKED, not expand_on)
   SetMenuAttribute( GetAVar('mid_keywordhighlighting'), MIA_CHECKED, not GetHighlight())
   SetMenuAttribute( GetAVar('mid_tabkey'),              MIA_CHECKED, not tab_key)
   SetMenuAttribute( GetAVar('mid_matchtab'),            MIA_CHECKED, not matchtab_on)

   new = Exist(.filename)
   SetMenuAttribute( GetAVar('mid_readonly'),            MIA_DISABLED, new)
   SetMenuAttribute( GetAVar('mid_readonlyattrib'),      MIA_DISABLED, new)
   SetMenuAttribute( GetAVar('mid_locked'),              MIA_DISABLED, new)
   SetMenuAttribute( GetAVar('mid_wpsproperties'),       MIA_DISABLED, new)

   new = GetMode()
   parse value GetAVar('mtxt_mode') with next'['x']'rest
   SetMenuText( GetAVar('mid_mode'), next'['new']'rest)
   new = .tabs
   parse value GetAVar('mtxt_tabs') with next'['x']'rest
   SetMenuText( GetAVar('mid_tabs'), next'['new']'rest)
   new = .margins
   parse value GetAVar('mtxt_margins') with next'['x']'rest
   SetMenuText( GetAVar('mid_margins'), next'['new']'rest)

; ------------------------------------ Edit ---------------------------------
defc menuinit_edit
   universal DMbuf_handle
   SetMenuAttribute( GetAVar('mid_recovermarkdelete'), MIA_DISABLED, DMbuf_handle)
   SetMenuAttribute( GetAVar('mid_undoline'),    MIA_DISABLED, isadirtyline())
   undoaction 1, presentstate         -- Do to fix range, not for value.
   undoaction 6, staterange           -- query range
   parse value staterange with oldeststate neweststate .
   SetMenuAttribute( GetAVar('mid_undo'),        MIA_DISABLED, oldeststate <> neweststate)  -- Set to 1 if different
   SetMenuAttribute( GetAVar('mid_discardchanges'), MIA_DISABLED, .modify > 0)

defc menuinit_spellcheck
   new = GetDictBaseName()
   if new = '' then
      new = '-none-'
   endif
   parse value GetAVar('mtxt_dict') with next'['x']'rest
   SetMenuText( GetAVar('mid_dict'), next'['new']'rest)

; ------------------------------------ Mark ---------------------------------
defc menuinit_mark
   universal DMbuf_handle
   universal CUA_marking_switch
   paste = clipcheck(format) & (format = 1024) & not (browse() | .readonly)
   SetMenuAttribute( GetAVar('mid_paste'),       MIA_DISABLED, paste)
   SetMenuAttribute( GetAVar('mid_pastelines'),  MIA_DISABLED, paste)
   SetMenuAttribute( GetAVar('mid_pasteblock'),  MIA_DISABLED, paste)
   on = (marktype() <> '')
   buf_flag = 0
   if not on then                                     -- Only check buffer if no mark
      bufhndl = buffer( OPENBUF, EPMSHAREDBUFFER)
      if bufhndl then                                -- If the buffer exists, check the
         buf_flag = itoa( peek( bufhndl, 2, 2), 10)  -- amount of used space in buffer
         call buffer( FREEBUF, bufhndl)              -- then free it.
      endif
   endif
   SetMenuAttribute( GetAVar('mid_copy'),        MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_cut'),         MIA_DISABLED, on)
   if CUA_marking_switch then
      cua_on = 0
      buf_flg = 0
   else
      cua_on = on
   endif
   SetMenuAttribute( GetAVar('mid_copymark'),    MIA_DISABLED, cua_on | buf_flag)  -- Can copy if mark or buffer has data
   SetMenuAttribute( GetAVar('mid_movemark'),    MIA_DISABLED, cua_on)
   SetMenuAttribute( GetAVar('mid_overlaymark'), MIA_DISABLED, cua_on | buf_flag)  -- Ditto for Overlay mark
   SetMenuAttribute( GetAVar('mid_adjustmark'),  MIA_DISABLED, cua_on)
   SetMenuAttribute( GetAVar('mid_unmark'),      MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_deletemark'),  MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_printmark'),   MIA_DISABLED, on)
   call update_paste_menu_text()
   call update_mark_menu_text()

defc menuinit_markatcursor
   universal CUA_marking_switch
   on = (FileIsMarked() & marktype() = 'CHAR' & not CUA_marking_switch)
   SetMenuAttribute( GetAVar('mid_extendsentence'),  MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_extendparagraph'), MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_markchars'),       MIA_DISABLED, not CUA_marking_switch)
   SetMenuAttribute( GetAVar('mid_markblock'),       MIA_DISABLED, not CUA_marking_switch)
   SetMenuAttribute( GetAVar('mid_marklines'),       MIA_DISABLED, not CUA_marking_switch)

; ------------------------------------ Format -------------------------------
defc menuinit_format
   universal nepmd_hini
   universal reflowmargins
   KeyPath = '\NEPMD\User\Reflow\MarginsItem'
   i   = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if i = 3 then
      reflowmargins = .margins
   else
      KeyPath = '\NEPMD\User\Reflow\Margins'i
      new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      reflowmargins = new
   endif
   parse value GetAVar('mtxt_reflowmargins') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins'), next'['reflowmargins']'rest)

defc menuinit_reflowmargins
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Reflow\Margins1'
   new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value GetAVar('mtxt_reflowmargins1') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins1'), next'['new']'rest)

   KeyPath = '\NEPMD\User\Reflow\Margins2'
   new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value GetAVar('mtxt_reflowmargins2') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins2'), next'['new']'rest)

   parse value GetAVar('mtxt_reflowmargins3') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins3'), next'['.margins']'rest)

   KeyPath = '\NEPMD\User\Reflow\MarginsItem'
   i   = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_reflowmargins1'), MIA_CHECKED, not (i = 1))
   SetMenuAttribute( GetAVar('mid_reflowmargins2'), MIA_CHECKED, not (i = 2))
   SetMenuAttribute( GetAVar('mid_reflowmargins3'), MIA_CHECKED, not (i = 3))

defc menuinit_reflow
   universal twospaces
   universal join_after_wrap
   universal nepmd_hini

   SetMenuAttribute( GetAVar('mid_twospaces'),         MIA_CHECKED, not twospaces)
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedLines'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_mailindentedlines'), MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentLists'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_mailindentlists'),   MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Reflow\Next'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_reflownext'),        MIA_CHECKED, not on)
   SetMenuAttribute( GetAVar('mid_joinafterwrap'),     MIA_CHECKED, not join_after_wrap)

   if FileIsMarked() then
      text = 'Mark'
   else
      text = 'Par'
   endif
   parse value GetAVar('mtxt_reflowpartoreflowmargins') with next rest
   SetMenuText( GetAVar('mid_reflowpartoreflowmargins'), text rest)
   parse value GetAVar('mtxt_reflowpartomargins*') with next rest
   SetMenuText( GetAVar('mid_reflowpartomargins*'), text rest)
   parse value GetAVar('mtxt_reflowpartomargins') with next rest
   SetMenuText( GetAVar('mid_reflowpartomargins'), text rest)

   SetMenuAttribute( GetAVar('mid_reflowblock'), MIA_DISABLED, FileIsMarked())

defc menuinit_recordkeys
   recordmode = windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),
                               5393,
                               0,
                               0)
   if recordmode then
      SetMenuText( GetAVar('mid_startrecording'), 'End ~recording'\9 || CTRL_KEY__MSG'+R')
      SetMenuText( GetAVar('mid_playback'),       'End recording & ~playback'\9 || CTRL_KEY__MSG'+T')
   else
      SetMenuText( GetAVar('mid_startrecording'), 'Start ~recording'\9 || CTRL_KEY__MSG'+R')
      SetMenuText( GetAVar('mid_playback'),       '~Playback'\9 || CTRL_KEY__MSG'+T')
   endif

; ------------------------------------ Search -------------------------------
defc menuinit_search
   universal lastchangeargs
   getsearch strng
   parse value strng with . c .       -- blank, 'c', or 'l'
;   SetMenuAttribute( GetAVar('mid_findnext'),         MIA_DISABLED, c <> '')               -- Find next OK if not blank
;   SetMenuAttribute( GetAVar('mid_changenext'),       MIA_DISABLED, lastchangeargs <> '')  -- Change next only if 'c'
;   SetMenuAttribute( GetAVar('mid_globalfindnext'),   MIA_DISABLED, c <> '')               -- Global find next OK if not blank
;   SetMenuAttribute( GetAVar('mid_globalchangenext'), MIA_DISABLED, lastchangeargs <> '')  -- Global change next only if 'c'
;   SetMenuAttribute( GetAVar('mid_toggledirection'),  MIA_DISABLED, c <> '')               -- Toggle direction OK if not blank
   on = FileIsMarked()
   if on then
      SetMenuText( GetAVar('mid_findmark'), 'Find ~mark')
   else
      SetMenuText( GetAVar('mid_findmark'), 'Find ~word')
   endif
   KeyPath = '\NEPMD\User\SyntaxExpansion'
   on = (GetSearchDirection() = '-')
   SetMenuAttribute( GetAVar('mid_searchbackwards'), MIA_CHECKED, not on)

defc menuinit_goto
   on = FileIsMarked()
   SetMenuAttribute( GetAVar('mid_gotomark'),      MIA_DISABLED, on)

defc menuinit_markstack
   universal mark_stack
   on = FileIsMarked()
   SetMenuAttribute( GetAVar('mid_savemark'),      MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_restoremark'),   MIA_DISABLED, mark_stack <> '')
   SetMenuAttribute( GetAVar('mid_swapmark'),      MIA_DISABLED, on & mark_stack <> '')

defc menuinit_cursorstack
   universal position_stack
   SetMenuAttribute( GetAVar('mid_restorecursor'), MIA_DISABLED, position_stack <> '')
   SetMenuAttribute( GetAVar('mid_swapcursor'),    MIA_DISABLED, position_stack <> '')

defc menuinit_bookmarks
   universal EPM_utility_array_ID
   rc = get_array_value( EPM_utility_array_ID, 'bmi.0', bmcount)  -- Index says how many bookmarks there are
   SetMenuAttribute( GetAVar('mid_bookmarks_set'),      MIA_DISABLED, not (browse() | .readonly))  -- Set
   SetMenuAttribute( GetAVar('mid_bookmarks_list'),     MIA_DISABLED, bmcount > 0)   -- List
   SetMenuAttribute( GetAVar('mid_bookmarks_next'),     MIA_DISABLED, bmcount > 0)   -- Next
   SetMenuAttribute( GetAVar('mid_bookmarks_previous'), MIA_DISABLED, bmcount > 0)   -- Previous

; ------------------------------------ View ---------------------------------
defc menuinit_view
   universal ring_enabled
   SetMenuAttribute( GetAVar('mid_softwrap'), MIA_CHECKED, GetWrapped() = 0)
   SetMenuAttribute( GetAVar('mid_nextview'), MIA_DISABLED, .currentview_of_file <> .nextview_of_file)
   SetMenuAttribute( GetAVar('mid_listring'), MIA_DISABLED, (ring_enabled & filesinring() > 1))
   SetMenuAttribute( GetAVar('mid_ringenabled'), MIA_CHECKED, not ring_enabled)

defc menuinit_menu
   universal nodismiss
   universal MenuItemsHidden
   SetMenuAttribute( GetAVar('mid_nodismiss'), MIA_CHECKED, not (nodismiss = 32))
   SetMenuAttribute( GetAVar('mid_hidemenuitems'), MIA_CHECKED, not MenuItemsHidden)

defc menuinit_infobars
   universal show_longnames
   universal menu_prompt
   SetMenuAttribute( GetAVar('mid_showlongname'), MIA_CHECKED, not show_longnames)
   SetMenuAttribute( GetAVar('mid_messageline'),  MIA_CHECKED, not queryframecontrol(2))
   SetMenuAttribute( GetAVar('mid_statusbar'),    MIA_CHECKED, not queryframecontrol(1))
   SetMenuAttribute( GetAVar('mid_infoattop'),    MIA_CHECKED, not queryframecontrol(32))
   SetMenuAttribute( GetAVar('mid_prompting'),    MIA_CHECKED, not menu_prompt)

defc menuinit_toolbar
   SetMenuAttribute( GetAVar('mid_toolbarenabled'), MIA_CHECKED, not queryframecontrol(EFRAMEF_TOOLBAR))

defc menuinit_toolbarstyle
   parse value GetToolbarSetup() with \1 Style \1 Cx \1 Cy \1 .
   fText     = not (Style bitand 16)
   fAutosize = not (Style bitand 4)
   fFlat     = not (Style bitand 8)
   fScaleDel = (not (Style bitand 32)) and (not (Style bitand 64))
   fScaleOr  = (Style bitand 32) and (Style bitand 64)
   fScaleAnd = (Style bitand 32) and (not (Style bitand 64))

   SetMenuAttribute( GetAVar('mid_toolbartext'),     MIA_CHECKED, not fText)
   SetMenuAttribute( GetAVar('mid_toolbarautosize'), MIA_CHECKED, not fAutosize)
   SetMenuAttribute( GetAVar('mid_toolbarsize'),     MIA_DISABLED, not fAutosize)
   SetMenuAttribute( GetAVar('mid_toolbarscaling'),  MIA_DISABLED, not fAutosize)
   new = Cx'x'Cy
   parse value GetAVar('mtxt_toolbarsize') with next'['x']'rest
   SetMenuText( GetAVar('mid_toolbarsize'), next'['new']'rest)
   if fScaleDel then
      new = 'delete'
   elseif fScaleOr then
      new = 'or'
   else
      new = 'and'
   endif
   parse value GetAVar('mtxt_toolbarscaling') with next'['x']'rest
   SetMenuText( GetAVar('mid_toolbarscaling'), next'['new']'rest)

defc menuinit_backgroundbitmap
   universal bitmap_present
   SetMenuAttribute( GetAVar('mid_backgroundbitmapenabled'), MIA_CHECKED, not bitmap_present)

; ------------------------------------ Options ------------------------------
defc menuinit_options
   universal default_edit_options
   universal default_save_options
   universal default_search_options
   new = default_edit_options
   parse value GetAVar('mtxt_editoptions') with next'['x']'rest
   SetMenuText( GetAVar('mid_editoptions'), next'['new']'rest)
   new = default_save_options
   parse value GetAVar('mtxt_saveoptions') with next'['x']'rest
   SetMenuText( GetAVar('mid_saveoptions'), next'['new']'rest)
   new = default_search_options
   parse value GetAVar('mtxt_searchoptions') with next'['x']'rest
   SetMenuText( GetAVar('mid_searchoptions'), next'['new']'rest)

defc menuinit_editoptions
   'seteditoptions MENUINIT'

defc menuinit_saveoptions
   'setsaveoptions MENUINIT'

defc menuinit_searchoptions
   'setsearchoptions MENUINIT'

defc menuinit_modesettings
   universal nepmd_hini
   CurMode = GetMode()

   KeyPath = '\NEPMD\User\KeywordHighlighting'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_defaultkeywordhighlighting'), MIA_CHECKED, not on)

   KeyPath = '\NEPMD\User\KeywordHighlighting\AutoRefresh'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_autorefreshmodefiles'),       MIA_CHECKED, not on)

   KeyPath = '\NEPMD\User\SyntaxExpansion'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_defaultsyntaxexpansion'),     MIA_CHECKED, not on)

   parse value GetAVar( 'mtxt_checkmodefilesnow') with next'#'x'#'rest
   SetMenuText( GetAVar('mid_checkmodefilesnow'), next''CurMode''rest)

   parse value GetAVar( 'mtxt_openmodedirs') with next'#'x'#'rest
   SetMenuText( GetAVar('mid_openmodedirs'), next''CurMode''rest)

   new = GetCodingStyle()
   if new = '' then
      new = '-none-'
   endif
   parse value GetAVar('mtxt_selectcodingstyle') with next'['x']'rest
   NewText = next'['new']'rest
   parse value NewText with next'#'x'#'rest
   SetMenuText( GetAVar('mid_selectcodingstyle'), next''CurMode''rest)

   file = ResolveEnvVars('%NEPMD_USERDIR%\bin\profile.erx')
   file_exist = exist(file)
   SetMenuAttribute( GetAVar('mid_editprofile2'),  MIA_DISABLED, file_exist)

defc menuinit_keyssettings
   universal cua_menu_accel
   universal nepmd_hini
   universal default_stream_mode

   SetMenuAttribute( GetAVar('mid_defaultstreammode'),          MIA_CHECKED, not default_stream_mode)

   new = GetKeyDef()
   parse value GetAVar('mtxt_keydefs') with next'['x']'rest
   SetMenuText( GetAVar('mid_keydefs'), next'['new']'rest)

   SetMenuAttribute( GetAVar('mid_blockactionbaraccelerators'), MIA_CHECKED, cua_menu_accel)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_blockleftaltkey'),            MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_blockrightaltkey'),           MIA_CHECKED, not on)

defc menuinit_markingsettings
   universal nepmd_hini
   universal cua_marking_switch

   SetMenuAttribute( GetAVar('mid_advancedmarking'),    MIA_CHECKED, cua_marking_switch)

   KeyPath = '\NEPMD\User\Mark\ShiftMarkExtends'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_shiftmarkextends'),   MIA_CHECKED, not (on & not cua_marking_switch))
   SetMenuAttribute( GetAVar('mid_shiftmarkextends'),   MIA_DISABLED, not cua_marking_switch)

   KeyPath = '\NEPMD\User\Mark\UnmarkAfterMove'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_unmarkaftermove'),    MIA_CHECKED, not (on & not cua_marking_switch))
   SetMenuAttribute( GetAVar('mid_unmarkaftermove'),    MIA_DISABLED, not cua_marking_switch)

   KeyPath = '\NEPMD\User\Mark\MouseStyle'
   style = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if (style <> 1 | cua_marking_switch) then
      style = 2
   endif
   new = word( 'block char', style)
   parse value GetAVar('mtxt_mousestyle') with next'['x']'rest
   SetMenuText( GetAVar('mid_mousestyle'), next'['new']'rest)
   SetMenuAttribute( GetAVar('mid_mousestyle'),         MIA_DISABLED, not cua_marking_switch)

   KeyPath = '\NEPMD\User\Mark\DefaultPaste'
   next = substr( upcase(NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then
      new = 'line'
   elseif next = 'B' then
      new = 'block'
   else
      new = 'char'
   endif
   parse value GetAVar('mtxt_defaultpaste') with next'['x']'rest
   SetMenuText( GetAVar('mid_defaultpaste'), next'['new']'rest)

   KeyPath = '\NEPMD\User\Mark\DragAlwaysMarks'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'),    MIA_CHECKED, not (on | cua_marking_switch))
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'),    MIA_DISABLED, not cua_marking_switch)

defc menuinit_marginsandtabs
   universal app_hini
   universal appname
   universal nepmd_hini
   universal matchtab_on
   universal default_tab_key
/*
   optflags = queryprofile( app_hini, 'EPM', INI_OPTFLAGS)
   on = 0
   if optflags <> '' then
      on = subword( optflags, 14, 1)
   endif
*/
   SetMenuAttribute( GetAVar('mid_defaulttabkey'),       MIA_CHECKED, not default_tab_key)
   KeyPath = '\NEPMD\User\Keys\Tab\MatchTab'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_defaultmatchtab'),     MIA_CHECKED, not on)
   on = tabglyph()
   SetMenuAttribute( GetAVar('mid_showtabs'),            MIA_CHECKED, not on)
   new = queryprofile( app_hini, 'EPM', INI_MARGINS)
   new = strip(new)
   parse value GetAVar('mtxt_defaultmargins') with next'['x']'rest
   SetMenuText( GetAVar('mid_defaultmargins'), next'['new']'rest)
   new = queryprofile( app_hini, 'EPM', INI_TABS)
   new = strip(new)
   parse value GetAVar('mtxt_defaulttabs') with next'['x']'rest
   SetMenuText( GetAVar('mid_defaulttabs'), next'['new']'rest)

defc menuinit_readonlyandlock
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Readonly'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_respectreadonly'), MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Lock\OnModify'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_lockonmodify'),    MIA_CHECKED, not on)

defc menuinit_cursorsettings
   universal nepmd_hini

   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_keepcursoronscreen'),         MIA_CHECKED, not on)

   KeyPath = '\NEPMD\User\Scroll\AfterLocate'
   new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value GetAVar('mtxt_scrollafterlocate') with next'['x']'rest
   SetMenuText( GetAVar('mid_scrollafterlocate'), next'['new']'rest)

defc menuinit_autorestore
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoRestore\CursorPos'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   Unchecked = (Enabled <> 1)
   SetMenuAttribute( GetAVar('mid_restorecursorpos'),  MIA_CHECKED, Unchecked)
   KeyPath = '\NEPMD\User\History'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   Unchecked = (Enabled <> 1)
   SetMenuAttribute( GetAVar('mid_trackhistorylists'), MIA_CHECKED, Unchecked)
   KeyPath = '\NEPMD\User\AutoRestore\Ring\SaveLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   Unchecked = (Enabled <> 1)
   SetMenuAttribute( GetAVar('mid_autosavelastring'),  MIA_CHECKED, Unchecked)
   KeyPath = '\NEPMD\User\AutoRestore\Ring\LoadLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   Unchecked = (Enabled <> 1)
   SetMenuAttribute( GetAVar('mid_autoloadlastring'),  MIA_CHECKED, Unchecked)
   KeyPath = '\NEPMD\User\AutoRestore\Ring\MaxFiles'
   new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value GetAVar('mtxt_maxfilessavering') with next'['x']'rest
   SetMenuText( GetAVar('mid_maxfilessavering'), next'['new']'rest)

defc menuinit_backup
   universal nepmd_hini

   KeyPath = '\NEPMD\User\AutoSave'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_autosaveenabled'),  MIA_CHECKED, not on)
   new = GetAutoSaveNum()
   parse value GetAVar('mtxt_autosavenumdialog') with next'['x']'rest
   SetMenuText( GetAVar('mid_autosavenumdialog'), next'['new']'rest)
   SetMenuAttribute( GetAVar('mid_autosavenumdialog'), MIA_DISABLED, on)

   KeyPath = '\NEPMD\User\Backup'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_backupenabled'),  MIA_CHECKED, not on)
   new = GetBackupNum()
   parse value GetAVar('mtxt_backupnumdialog') with next'['x']'rest
   SetMenuText( GetAVar('mid_backupnumdialog'), next'['new']'rest)
   SetMenuAttribute( GetAVar('mid_backupnumdialog'), MIA_DISABLED, on)

   new = GetBackupDir()
   parse value GetAVar('mtxt_backupdirdialog') with next'['x']'rest
   SetMenuText( GetAVar('mid_backupdirdialog'), next'['new']'rest)


defc menuinit_workdir
   universal nepmd_hini
   KeyPath = '\NEPMD\User\StartDir\WorkDir\Type'
   opt = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_workdirprogram'), MIA_CHECKED, (opt = 1 | opt = 2))
   SetMenuAttribute( GetAVar('mid_workdirprev'),    MIA_CHECKED, not (opt = 1))
   SetMenuAttribute( GetAVar('mid_workdirfile'),    MIA_CHECKED, not (opt = 2))

defc menuinit_opendlgdir
   universal nepmd_hini
   KeyPath = '\NEPMD\User\StartDir\OpenDlg\Type'
   opt = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_opendlgdirprev'), MIA_CHECKED, (opt = 1 | opt = 2))
   SetMenuAttribute( GetAVar('mid_opendlgdirwork'), MIA_CHECKED, not (opt = 1))
   SetMenuAttribute( GetAVar('mid_opendlgdirfile'), MIA_CHECKED, not (opt = 2))

defc menuinit_saveasdlgdir
   universal nepmd_hini
   KeyPath = '\NEPMD\User\StartDir\SaveasDlg\Type'
   opt = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_saveasdlgdirprev'), MIA_CHECKED, (opt = 1))
   SetMenuAttribute( GetAVar('mid_saveasdlgdirwork'), MIA_CHECKED, not (opt = 1))

defc menuinit_prg
   universal nepmd_hini
   opt = RxResult( 'newsamewindow.erx query')
   SetMenuAttribute( GetAVar('mid_prgnewwindow'),      MIA_CHECKED, not (opt = 1))
   opt = RxResult( 'fullfiledialog.erx query')
   SetMenuAttribute( GetAVar('mid_prgfullfiledialog'), MIA_CHECKED, not (opt = 1))

defc menuinit_macros
   universal rexx_profile

   SetMenuAttribute( GetAVar('mid_activateprofile'),  MIA_CHECKED, not rexx_profile)

   file = ResolveEnvVars('%NEPMD_USERDIR%\bin\profile.erx')
   file_exist = exist(file)
   SetMenuAttribute( GetAVar('mid_activateprofile'),  MIA_DISABLED, file_exist)
   if file_exist then
      SetMenuText( GetAVar('mid_editprofile'), 'Edit ~PROFILE.ERX')
   else
      SetMenuText( GetAVar('mid_editprofile'), 'Create ~PROFILE.ERX')
   endif

   file = ResolveEnvVars('%NEPMD_USERDIR%\macros\mycnf.e')
   file_exist = exist(file)
   if file_exist then
      SetMenuText( GetAVar('mid_editmycnf'), 'Edit MY~CNF.E')
   else
      SetMenuText( GetAVar('mid_editmycnf'), 'Create MY~CNF.E')
   endif

   file = ResolveEnvVars('%NEPMD_USERDIR%\macros\mystuff.e')
   file_exist = exist(file)
   if file_exist then
      SetMenuText( GetAVar('mid_editmystuff'), 'Edit MY~STUFF.E')
   else
      SetMenuText( GetAVar('mid_editmystuff'), 'Create MY~STUFF.E')
   endif

; ------------------------------------ Run ----------------------------------
defc menuinit_run
   is_shell = leftstr( .filename, 15) = '.command_shell_'
   SetMenuAttribute( GetAVar('mid_writetoshell'),     MIA_DISABLED, is_shell)
   SetMenuAttribute( GetAVar('mid_sendbreaktoshell'), MIA_DISABLED, is_shell)

defc menuinit_configureshell
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Shell\FilenameCompletion'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   SetMenuAttribute( GetAVar('mid_filenamecompletion'), MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Shell\Alias'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   SetMenuAttribute( GetAVar('mid_alias'), MIA_CHECKED, not on)

defc menuinit_treecommands
   is_tree = upcase( leftstr( .filename, 5)) = '.TREE'
   SetMenuAttribute( GetAVar('mid_treesort'), MIA_DISABLED, is_tree)
   SetMenuAttribute( GetAVar('mid_treeit')  , MIA_DISABLED, is_tree)

; ------------------------------------ Keyword help -------------------------
defc menuinit_keywordhelp
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHelp\NewView\UseIfFound'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   SetMenuAttribute( GetAVar('mid_usenewview'),        MIA_CHECKED, not on)
   SetMenuAttribute( GetAVar('mid_usenewviewxsearch'), MIA_DISABLED, on)
   KeyPath = '\NEPMD\User\KeywordHelp\NewView\ExtendedSearch'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   SetMenuAttribute( GetAVar('mid_usenewviewxsearch'), MIA_CHECKED, not on)

; The above is all part of ProcessMenuInit cmd on old versions.  ------------

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: togglecontrol                                            ³
³                                                                            ³
³ what does it do : The command either toggles a EPM control window on or off³
³                   or forces a EPM control window on or off.                ³
³                   arg1   = EPM control window handle ID.  Control window   ³
³                            ids given above.  The following windows handles ³
³                            are currently supported.                        ³
³                            EDITSTATUS, EDITVSCROLL, EDITHSCROLL, and       ³
³                            EDITMSGLINE.                                    ³
³                   arg2   [optional] = force option.                        ³
³                            a value of 0, forces control window off         ³
³                            a value of 1, forces control window on          ³
³                           IF this argument is not specified the window     ³
³                           in question is toggled.                          ³
³                                                                            ³
³                   This command is possible because of the EPM_EDIT_CONTROL ³
³                   EPM_EDIT_CONTROLSTATUS message.                          ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
/*
; Some control ids are replaced by EFRAMEF_ constants. See toggleframe.
;   EPMINFO_EDITSTATUSAREA    =  7  -- EFRAMEF_STATUSWND = 1
;   EPMINFO_EDITORMSGAREA     =  8  -- EFRAMEF_MESSAGEWND = 2
;   EPMINFO_EDITORVSCROLL     =  9  -- EFRAMEF_VSCROLLBAR = 8
;   EPMINFO_EDITORHSCROLL     = 10  -- EFRAMEF_HSCROLLBAR = 16
   EPMINFO_EDITORINTERPRETER = 11
   EPMINFO_EDITVIOPS         = 12
   EPMINFO_EDITTITLEBAR      = 13
   EPMINFO_EDITCURSOR        = 14  -- No effect in current EPM version
;   EPMINFO_PARTIALTEXT       = 15  -- No longer used
   EPMINFO_EDITEXSEARCH      = 16
   EPMINFO_EDITMENUHWND      = 17
   EPMINFO_HDC               = 18
   EPMINFO_HINI              = 19
;   EPMINFO_RINGICONS         = 20  -- EFRAMEF_RINGBUTTONS = 4
;   EPMINFO_FILEICON          = 22  -- EFRAMEF_FILEWND = 64
;   EPMINFO_EXTRAWINDOWPOS    = 23  -- EFRAMEF_INFOONTOP = 32
*/
defc togglecontrol
   universal menuloaded
   forceon = 0
   parse arg controlid fon
   if fon <> '' then
      forceon = (fon + 1)*65536
   else
      fon = not queryframecontrol(controlid)  -- Query now, since toggling is asynch.
   endif

   call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                       5388,               -- EPM_EDIT_CONTROLTOGGLE
                       controlid + forceon,
                       0)

   if menuloaded then
      -- Set MIA_CHECKED attributes for the case MIA_NODISMISS attribute is on
      ControlIdList = ''     ||
        24 'streammode'      || ' ' ||  -- stream_mode
        25 'advancedmarking' || ' ' ||  -- not cua_marking_switch
        26 'internalkeys'    || ' ' ||  -- should be off
        ''
      p = wordpos( controlid, ControlIdList)
      if p then
         midtext = word( ControlIdList, p + 1)
         mid = GetAVar('mid_'midtext)
         -- Check if mid exists, because 'initconfig' sets some controls before the menu
         if mid > '' then
            SetMenuAttribute( mid, MIA_CHECKED, not fon)
         endif
      endif
   endif

; ---------------------------------------------------------------------------
/*                                -- old:
   EFRAMEF_STATUSWND       = 1    -- EPMINFO_EDITSTATUSAREA = 7
   EFRAMEF_MESSAGEWND      = 2    -- EPMINFO_EDITORMSGAREA = 8
   EFRAMEF_RINGBUTTONS     = 4    -- EPMINFO_RINGICONS = 20
   EFRAMEF_VSCROLLBAR      = 8    -- EPMINFO_EDITORVSCROLL = 9
   EFRAMEF_HSCROLLBAR      = 16   -- EPMINFO_EDITORHSCROLL = 10
   EFRAMEF_INFOONTOP       = 32   -- EPMINFO_EXTRAWINDOWPOS = 23
   EFRAMEF_FILEWND         = 64   -- = 8  EPMINFO_FILEICON = 22
   EFRAMEF_DMTBWND         = 128  -- = 16
   EFRAMEF_TASKLISTENTRY   = 256  -- doesn't work?
   EFRAMEF_TOOLBAR         = 2048
   drop style                8192
*/
defc toggleframe
   universal menu_prompt
   universal menuloaded
   forceon = 0
   parse arg controlid fon
   if fon <> '' then
      forceon = (fon + 1)*65536
   else
      fon = not queryframecontrol(controlid)  -- Query now, since toggling is asynch.
   endif

   call windowmessage( 0, getpminfo(EPMINFO_EDITFRAME),
                       5907,               -- EFRAMEM_TOGGLECONTROL
                       controlid + forceon,
                       0)

   -- If 'Info at top' gets activated, deactivate 'Prompting'
   if controlid = 32 then
      if fon then  -- 1=top; 0=bottom.  If now top, turn off.
         menu_prompt = 0
         if menuloaded then
            -- Set MIA_CHECKED attributes for the case MIA_NODISMISS attribute is on
            mid = GetAVar('mid_prompting')
            -- Check if mid exists, because 'initconfig' sets some controls before the menu
            if mid > '' then
               SetMenuAttribute( mid, MIA_CHECKED, 1)
            endif
         endif
      endif
   endif

   if menuloaded then
      -- Set MIA_CHECKED attributes for the case MIA_NODISMISS attribute is on
      ControlIdList = ''    ||
         1 'statusbar'      || ' ' ||
         2 'messageline'    || ' ' ||
         4 'rotatebuttons'  || ' ' ||
        16 'scrollbars'     || ' ' ||  -- acts on hscrollbar change only, menuitem for h and vscrollbars
        32 'infoattop'      || ' ' ||
      2048 'toolbarenabled'

      p = wordpos( controlid, ControlIdList)
      if p then
         midtext = word( ControlIdList, p + 1)
         mid = GetAVar('mid_'midtext)
         -- Check if mid exists, because 'initconfig' sets some controls before the menu
         if mid > '' then
            SetMenuAttribute( mid, MIA_CHECKED, not fon)
         endif
      endif

      'SaveOptions OptOnly'
   endif

; ---------------------------------------------------------------------------
; Move to MENU.E?
defproc queryframecontrol(controlid)
   return windowmessage( 1, getpminfo(EPMINFO_EDITFRAME),   -- Send message to edit client
                         5907,               -- EFRAMEM_TOGGLECONTROL
                         controlid,
                         1)

; ---------------------------------------------------------------------------
defc toggle_profile
   universal rexx_profile
   universal menuloaded
   universal app_hini
   universal appname
   rexx_profile = not rexx_profile
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_activateprofile'), MIA_CHECKED, not rexx_profile)
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 11)' 'rexx_profile' 'subword( old, 13)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
defc toggleprompt, toggle_prompt
   universal menu_prompt
   universal menuloaded
   universal app_hini
   universal appname
   menu_prompt = not menu_prompt
   if menu_prompt then
      'toggleframe 32 0'      -- Force Extra window to bottom.
   endif
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_prompting'), MIA_CHECKED, not menu_prompt)
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 8)' 'menu_prompt' 'subword( old, 10)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
; Todo: merge this with defc LoadToolbar.
defc toggle_toolbar
   universal toolbar_loaded
   universal menuloaded
   universal app_hini
   universal appname
   --fon = queryframecontrol(EFRAMEF_TOOLBAR)  -- Query now, since toggling is asynch.
   'toggleframe' EFRAMEF_TOOLBAR
   if not toolbar_loaded then
      'default_toolbar'
   endif
   on = queryframecontrol(EFRAMEF_TOOLBAR)
   if menuloaded then
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 15)' 'on' 'subword( old, 17)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
defc toggle_toolbar_text
   universal menuloaded
   parse value GetToolbarSetup() with \1 Style \1 SetupRest
   fText     = not (Style bitand 16)
   fAutosize = not (Style bitand 4)
   fFlat     = not (Style bitand 8)
   fScaleDel = (not (Style bitand 32)) and (not (Style bitand 64))
   fScaleOr  = (Style bitand 32) and (Style bitand 64)
   fScaleAnd = (Style bitand 32) and (not (Style bitand 64))

   fText = not fText

   Style = 16*(not fText) + 4*(not fAutosize) + 8*(not fFlat) +
           32*(fScaleAnd) + 96*(fScaleOr)
   call SetToolbarSetup( \1''Style\1''SetupRest)

   if menuloaded then
      SetMenuAttribute( GetAVar('mid_toolbartext'), MIA_CHECKED, not fText)
   endif

; ---------------------------------------------------------------------------
defc toggle_toolbar_autosize
   universal menuloaded
   parse value GetToolbarSetup() with \1 Style \1 SetupRest
   fText     = not (Style bitand 16)
   fAutosize = not (Style bitand 4)
   fFlat     = not (Style bitand 8)
   fScaleDel = (not (Style bitand 32)) and (not (Style bitand 64))
   fScaleOr  = (Style bitand 32) and (Style bitand 64)
   fScaleAnd = (Style bitand 32) and (not (Style bitand 64))

   fAutosize = not fAutosize

   Style = 16*(not fText) + 4*(not fAutosize) + 8*(not fFlat) +
           32*(fScaleAnd) + 96*(fScaleOr)
   call SetToolbarSetup( \1''Style\1''SetupRest)

   if menuloaded then
      SetMenuAttribute( GetAVar('mid_toolbarautosize'), MIA_CHECKED, not fAutosize)
      SetMenuAttribute( GetAVar('mid_toolbarsize'),     MIA_DISABLED, not fAutosize)
      SetMenuAttribute( GetAVar('mid_toolbarscaling'),  MIA_DISABLED, not fAutosize)
   endif

; ---------------------------------------------------------------------------
defc toggle_toolbar_scaling
   universal menuloaded
   parse value GetToolbarSetup() with \1 Style \1 SetupRest
   fText     = not (Style bitand 16)
   fAutosize = not (Style bitand 4)
   fFlat     = not (Style bitand 8)
   fScaleDel = (not (Style bitand 32)) and (not (Style bitand 64))
   fScaleOr  = (Style bitand 32) and (Style bitand 64)
   fScaleAnd = (Style bitand 32) and (not (Style bitand 64))

   if fScaleAnd then
      fScaleDel = 1
      fScaleOr  = 0
      fScaleAnd = 0
   elseif fScaleDel then
      fScaleDel = 0
      fScaleOr  = 1
      fScaleAnd = 0
   else
      fScaleDel = 0
      fScaleOr  = 0
      fScaleAnd = 1
   endif

   Style = 16*(not fText) + 4*(not fAutosize) + 8*(not fFlat) +
           32*(fScaleAnd) + 96*(fScaleOr)
   call SetToolbarSetup( \1''Style\1''SetupRest)

   if menuloaded then
      if fScaleDel then
         new = 'delete'
      elseif fScaleOr then
         new = 'or'
      else
         new = 'and'
      endif
      parse value GetAVar('mtxt_toolbarscaling') with next'['x']'rest
      SetMenuText( GetAVar('mid_toolbarscaling'), next'['new']'rest)
   endif

; ---------------------------------------------------------------------------
defc setscrolls
   on = arg(1)
   'toggleframe 8' on
   'toggleframe 16' on

; ---------------------------------------------------------------------------
defc toggle_bitmap
   universal bitmap_present
   universal menuloaded
   'SetBackgroundBitmap TOGGLE'
   on = bitmap_present
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_backgroundbitmapenabled'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_readonly
   on = not .readonly
   .readonly = on  -- update the edit/browse mode
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_readonly'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_readonly_attrib
   universal nepmd_hini
   on = GetReadonly()
   on = not on
   'ReadonlyAttrib' on  -- update the file attribute
   KeyPath = '\NEPMD\User\Readonly'
   RespectReadonly = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if RespectReadonly then
      .readonly = on  -- update the edit/browse mode
   endif
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_readonlyattrib'), MIA_CHECKED, not on)
   if RespectReadonly then
      SetMenuAttribute( GetAVar('mid_readonly'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_locked
   if .lockhandle then
      'unlock'
   else
      'lock'
   endif
   on = (.lockhandle > 0)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_locked'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_restore_pos
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoRestore\CursorPos'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_restorecursorpos'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_history
   universal nepmd_hini
   KeyPath = '\NEPMD\User\History'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_trackhistorylists'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_save_ring
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoRestore\Ring\SaveLast'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_autosavelastring'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_restore_ring
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoRestore\Ring\LoadLast'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_autoloadlastring'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_two_spaces
   universal nepmd_hini
   universal twospaces
   KeyPath = '\NEPMD\User\Reflow\TwoSpaces'
   twospaces = not twospaces
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, twospaces)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_twospaces'), MIA_CHECKED, not twospaces)

; ---------------------------------------------------------------------------
defc toggle_search_backward
   'ToggleSearchDirection'
   on = (GetSearchDirection() = '-')
   SetMenuAttribute( GetAVar('mid_searchbackwards'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_highlight
   on = GetHighlight()
   on = not on
   'SetHighlight' on
   --call NepmdActivateHighlight(on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_keywordhighlighting'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_default_highlight
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHighlighting'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_defaultkeywordhighlighting'), MIA_CHECKED, not on)
   opt = 'N'  -- 'N' = don't check for changed .hil and .ini files to make it more stable for a huge ring
   -- Change highlight for every file with default setting
   'RingRefreshSetting DEFAULT SetHighlight 'on opt
   -- Todo: Define a new command, that processes the ring.
   --       Note: When an entire ring should be refreshed, the epmkwds
   --             file needs to be reloaded only once per mode (used by
   --             defc toggle_default_highlight in NEWMENU.E).

; ---------------------------------------------------------------------------
defc toggle_modefiles_autorefresh
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHighlighting\AutoRefresh'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_autorefreshmodefiles'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_expand
   universal menuloaded
   universal expand_on
   -- Change expand for current file
   expand_on = not expand_on
   'SetExpand' expand_on  -- refresh file setting
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_syntaxexpansion'), MIA_CHECKED, not expand_on)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_expand
   universal menuloaded
   universal nepmd_hini
   universal expand_on
   KeyPath = '\NEPMD\User\SyntaxExpansion'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Change expand for current file if it has default expand setting
   getfileid fid
   next = GetAVar('expand.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if expand was not changed by any modeexecute
      expand_on = on
      'RefreshInfoLine EXPAND'
   endif
   if menuloaded then  -- check not required
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_defaultsyntaxexpansion'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_cua_mark, cua_mark_toggle
   universal cua_marking_switch
   universal menuloaded
   universal defaultmenu
   universal app_hini
   universal appname

   cua_marking_switch = not cua_marking_switch
   'togglecontrol 25' cua_marking_switch
   call MH_set_mouse()
   'RefreshInfoLine MARKINGMODE'
   if menuloaded then
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 7)' 'cua_marking_switch' 'subword( old, 9)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
      -- Set nmenu attributes and text for the case MIA_NODISMISS attribute is on
      'menuinit_markingsettings'
   endif

; ---------------------------------------------------------------------------
defc toggle_mousestyle
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\MouseStyle'
   style = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if style = 1 then  -- toggle
      style = 2
   else
      style = 1
   endif
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, style)
   new = word( 'block char', style)
   parse value GetAVar('mtxt_mousestyle') with next'['x']'rest
   SetMenuText( GetAVar('mid_mousestyle'), next'['new']'rest)
   --call MH_set_mouse()
  'mouse_init'  -- refresh the register_mousehandler defs

; ---------------------------------------------------------------------------
defc toggle_default_paste
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\DefaultPaste'
   next = substr( upcase(NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then      -- toggle L -> C
      style = 'C'
      new = 'char'
   elseif next = 'B' then  -- toggle B -> L
      style = 'L'
      new = 'line'
   else                    -- toggle B -> L
      style = 'B'
      new = 'block'
   endif
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, style)
   parse value GetAVar('mtxt_defaultpaste') with next'['x']'rest
   SetMenuText( GetAVar('mid_defaultpaste'), next'['new']'rest)
   --call update_paste_menu_text()  -- append Sh+Ins, Ctrl+Sh+Ins or nothing  -- handled by menuinit
  'mouse_init'                    -- refresh the register_mousehandler defs
   deleteaccel 'defaccel'         -- refresh the buildacceltable defs
   'loadaccel'

; ---------------------------------------------------------------------------
defc toggle_shift_mark_extends
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\ShiftMarkExtends'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_shiftmarkextends'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_unmark_after_move
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\UnmarkAfterMove'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_unmarkaftermove'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_drag_always_marks
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\DragAlwaysMarks'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'), MIA_CHECKED, not on)
  'mouse_init'  -- refresh the register_mousehandler defs

; ---------------------------------------------------------------------------
defc toggle_keep_cursor_on_screen
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_keepcursoronscreen'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_block_left_alt_key
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_blockleftaltkey'), MIA_CHECKED, not on)
   deleteaccel 'defaccel'  -- refresh the buildacceltable defs
   'loadaccel'

; ---------------------------------------------------------------------------
defc toggle_block_right_alt_key
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_blockrightaltkey'), MIA_CHECKED, not on)
   deleteaccel 'defaccel'  -- refresh the buildacceltable defs
   'loadaccel'

; ---------------------------------------------------------------------------
defc toggle_tabkey
   universal tab_key
   universal menuloaded
   -- Change tab_key for current file
   tab_key = not tab_key
   'SetTabKey' tab_key
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_tabkey'), MIA_CHECKED, not tab_key)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_tabkey
   universal default_tab_key
   universal tab_key
   universal menuloaded
   universal app_hini
   universal appname

   default_tab_key = not default_tab_key
   -- Change tab_key for current file if it has default tabkey setting
   getfileid fid
   next = GetAVar('tabkey.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if tabkey was not changed by any modeexecute
      tab_key = default_tab_key
      'RefreshInfoLine TABKEY'
   endif
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_defaulttabkey'), MIA_CHECKED, not default_tab_key)
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 13)' 'default_tab_key' 'subword( old, 15)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif
/*
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Keys\Tab\TabKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
*/

; ---------------------------------------------------------------------------
defc toggle_matchtab
   universal menuloaded
   universal nepmd_hini
   universal matchtab_on
   -- Change matchtab for current file
   matchtab_on = not matchtab_on
   'SetMatchTab' matchtab_on  -- refresh file settings
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_matchtab'), MIA_CHECKED, not matchtab_on)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_matchtab
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Keys\Tab\MatchTab'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Change match_tab for current file if it's default
   getfileid fid
   next = GetAVar('matchtab.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if tabkey was not changed by any modeexecute
      matchtab_on = on
      'RefreshInfoLine MATCHTAB'
   endif
   if menuloaded then  -- check not required
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_defaultmatchtab'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_tabglyph
   universal nepmd_hini
   on = tabglyph()
   on = not on
   call tabglyph(on)
   KeyPath = '\NEPMD\User\Keys\Tab\TabGlyph'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_showtabs'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_dynaspell
   on = (.keyset = 'SPELL_KEYS')
   on = not on
   'SetDynaspell' on
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_autospellcheck'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_join_after_wrap
   universal nepmd_hini
   universal join_after_wrap
   join_after_wrap = not join_after_wrap
   KeyPath = '\NEPMD\User\Reflow\JoinAfterWrap'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, join_after_wrap)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_joinafterwrap'), MIA_CHECKED, not join_after_wrap)

; ---------------------------------------------------------------------------
defc toggle_mail_indented
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedLines'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_mailindentedlines'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_mail_indent_lists
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentLists'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_mailindentlists'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_reflow_next
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Reflow\Next'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_reflownext'), MIA_CHECKED, not on)

; ---------------------------------------------------------------------------
defc toggle_respect_readonly
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Readonly'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_respectreadonly'), MIA_CHECKED, not on)
   'ring enable_readonly 'on

; ---------------------------------------------------------------------------
defc toggle_lock_on_modify
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Lock\OnModify'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_lockonmodify'), MIA_CHECKED, not on)
   'ring lock_on_modify 'on

; ---------------------------------------------------------------------------
defc toggle_nodismiss
   universal nepmd_hini
   universal nodismiss
   universal defaultmenu
   KeyPath = '\NEPMD\User\Menu\NoDismiss'
   on = not (nodismiss = 32)
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   nodismiss = on*32
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_nodismiss'), MIA_CHECKED, not on)
   deletemenu defaultmenu
   'loaddefaultmenu'
   call showmenu_activemenu()

/*
see also: STDCTRL.E: defc initconfig

OPTFLAGS:
   Bit              Setting
        for value = 1      for value = 0
   ---  ----------------   -------------------
    1   status bar on      status bar off
    2   msgline on         msgline off
    3   vscrollbar on      vscrollbar off
    4   hscrollbar on      hscrollbar off
    5   fileicon on        fileicon off        unused in EPM 6 (icon beside system menu icon)
    6   rotbuttons on      rotbuttons off
    7   info at top        info at bottom      pos of status + msg lines
    8   CUA marking        advanced marking
    9   menuprompt on      menuprompt off      menu hints on msg line
   10   stream mode        line mode
   11   longnames on       longnames off       show .LONGNAME EA instead of file name in titletext
   12   REXX profile on    REXX profile off
   13   escapekey on       escapekey off       ESC opens cmdbox
   14   tabkey on          tabkey off          1 = TAB inserts tab char
   15   bgbitmap on        bgbitmap off
   16   toolbar on         toolbar off
   17   dropstyle import   dropstyle edit      action for dropped file icon
   18   ?extra stuff on    ?extra stuff off    ?

OPT2FLAGS:
   Bit              Setting
        for value = 1      for value = 0
   ---  ----------------   -------------------
    1   I-beam pointer     arrow pointer       1 = (vEPM_POINTER=2)
    2   underline cursor   bar cursor          1 = (cursordimensions = '-128.3 -128.-64')
*/

; ---------------------------------------------------------------------------
defc toggle_stream, stream_toggle
   universal stream_mode
   universal menuloaded
   stream_mode = not stream_mode
;   'togglecontrol 24' stream_mode
;   'RefreshInfoLine STREAMMODE'
   'SetStreamMode' stream_mode
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_streammode'), MIA_CHECKED, not stream_mode)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_stream
   universal default_stream_mode
   universal stream_mode
   universal menuloaded
   universal app_hini
   universal appname
   default_stream_mode = not default_stream_mode
   -- Change stream_mode for current file if it's default
   getfileid fid
   next = GetAVar('streammode.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if streammode was not changed by any modeexecute
      stream_mode = default_stream_mode
      'togglecontrol 24' stream_mode
      'RefreshInfoLine STREAMMODE'
   endif
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_defaultstreammode'), MIA_CHECKED, not default_stream_mode)
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 9)' 'default_stream_mode' 'subword( old, 11)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
; unused
defc toggle_ring, ring_toggle
   universal ring_enabled
   universal activemenu, defaultmenu
   universal menuloaded
   universal app_hini
   universal appname

   ring_enabled = not ring_enabled
   'toggleframe 4' ring_enabled
   deletemenu defaultmenu, GetAVar('mid_file'), 0, 1           -- Delete the file menu
   call add_file_menu(defaultmenu)
   deletemenu defaultmenu, GetAVar('mid_view'), 0, 1           -- Delete the view menu
   call add_view_menu(defaultmenu)
   deletemenu defaultmenu, GetAVar('mid_options'), 0, 1        -- Delete the options menu
   call add_options_menu(defaultmenu)
   -- maybe_show_menu() does a refresh and closes the menu, so that the
   -- MIA_NODISMISS attribute has no effect anymore.
   call maybe_show_menu()
   if menuloaded then
      call setprofile( app_hini, appname, INI_RINGENABLED, ring_enabled)
   endif
/*
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_ringenabled'), MIA_CHECKED, not ring_enabled)
      SetMenuAttribute( GetAVar('mid_rotatebuttons'), MIA_DISABLED, ring_enabled)
   endif
*/

; ---------------------------------------------------------------------------
; unused
defc stack_toggle
/*
   universal stack_cmds
   universal activemenu, defaultmenu
   stack_cmds = not stack_cmds
   deletemenu defaultmenu, GetAVar('mid_view'), 0, 1           -- Delete the view menu
   call add_view_menu(defaultmenu)
   call maybe_show_menu()
*/

; ---------------------------------------------------------------------------
defc toggle_accel, accel_toggle
   universal cua_menu_accel
   universal activemenu, defaultmenu
   universal menuloaded
   universal app_hini
   universal appname

   cua_menu_accel = not cua_menu_accel
   deleteaccel 'defaccel'
   'loadaccel'
/*
   deletemenu defaultmenu, GetAVar('mid_edit'), 0, 1           -- Delete the edit menu
   call add_edit_menu(defaultmenu)
   if activemenu = defaultmenu  then
compile if 0    -- Don't need to actually show the menu; can just update the affected text.
      showmenu activemenu
compile else
      call update_mark_menu_text()  -- handled now by menuinit
compile endif
   endif
*/
   if menuloaded then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_blockactionbaraccelerators'), MIA_CHECKED, cua_menu_accel)
      call setprofile( app_hini, appname, INI_CUAACCEL, cua_menu_accel)
   endif

; ---------------------------------------------------------------------------
defc toggle_longname
   universal show_longnames
   universal menuloaded
   universal app_hini
   universal appname
   show_longnames = not show_longnames

   if menuloaded then  -- check not required
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_showlongname'), MIA_CHECKED, not show_longnames)
      'RefreshInfoLine FILE'
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 10)' 'show_longnames' 'subword( old, 12)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
defc toggle_use_newview
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHelp\NewView\UseIfFound'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_usenewview'),        MIA_CHECKED, not on)
      SetMenuAttribute( GetAVar('mid_usenewviewxsearch'), MIA_DISABLED, on)
   endif

; ---------------------------------------------------------------------------
defc toggle_newview_xsearch
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHelp\NewView\ExtendedSearch'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_usenewviewxsearch'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_new_same_window
   'rx newsamewindow.erx toggle'
   opt = RxResult( 'newsamewindow.erx query')
   SetMenuAttribute( GetAVar('mid_prgnewwindow'),      MIA_CHECKED, not (opt = 1))

; ---------------------------------------------------------------------------
defc toggle_full_file_dialog
   'rx fullfiledialog.erx toggle'
   opt = RxResult( 'fullfiledialog.erx query')
   SetMenuAttribute( GetAVar('mid_prgfullfiledialog'), MIA_CHECKED, not (opt = 1))

; ---------------------------------------------------------------------------
defc toggle_autosave
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoSave'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_autosaveenabled'),   MIA_CHECKED, not on)
      SetMenuAttribute( GetAVar('mid_autosavenumdialog'), MIA_DISABLED, on)
      SetMenuAttribute( GetAVar('mid_autosavedirdialog'), MIA_DISABLED, on)
      SetMenuAttribute( GetAVar('mid_autosavelistdir'),   MIA_DISABLED, on)
   endif

; ---------------------------------------------------------------------------
defc toggle_backup
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Backup'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_backupenabled'),   MIA_CHECKED, not on)
      SetMenuAttribute( GetAVar('mid_backupnumdialog'), MIA_DISABLED, on)
      SetMenuAttribute( GetAVar('mid_backupdirdialog'), MIA_DISABLED, on)
      SetMenuAttribute( GetAVar('mid_backuplistdir'),   MIA_DISABLED, on)
   endif

; ---------------------------------------------------------------------------
defc toggle_filename_completion
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Shell\FilenameCompletion'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_filenamecompletion'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_alias
   universal menuloaded
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Shell\Alias'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_alias'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc switch_dicts
   'DictLang SWITCH'
   new = GetDictBaseName()
   if new = '' then
      new = '-none-'
   endif
   parse value GetAVar('mtxt_dict') with next'['x']'rest
   SetMenuText( GetAVar('mid_dict'), next'['new']'rest)

; ---------------------------------------------------------------------------
defc set_ChangeWorkDir
   universal nepmd_hini
   opt = arg(1)
   if wordpos( opt, '0 1 2') = 0 then
      return
   endif
   KeyPath = '\NEPMD\User\StartDir\WorkDir\Type'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, opt)
   Filename = .filename
   if opt = 2 & pos( ':\', Filename) then
      call directory( '\')
      call directory( Filename'\..')
   elseif opt = 1 then
      KeyPath = '\NEPMD\User\StartDir\WorkDir\Last'
      LastWorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if NepmdDirExists( LastWorkDir) = 1 then
         call directory( '\')
         call directory( LastWorkDir)
      endif
   endif
   SetMenuAttribute( GetAVar('mid_workdirprogram'), MIA_CHECKED, (opt = 1 | opt = 2))
   SetMenuAttribute( GetAVar('mid_workdirprev'),    MIA_CHECKED, not (opt = 1))
   SetMenuAttribute( GetAVar('mid_workdirfile'),    MIA_CHECKED, not (opt = 2))

; ---------------------------------------------------------------------------
defc set_OpenDlgDir
   universal app_hini
   universal nepmd_hini
   opt = arg(1)
   if wordpos( opt, '0 1 2') = 0 then
      return
   endif
   KeyPath = '\NEPMD\User\StartDir\OpenDlg\Type'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, opt)
   new = -1
   Filename = .filename
   if opt = 1 then  -- use workdir
      new = ''
   elseif opt = 2 & pos( ':\', Filename) then  -- use dir of current file
      new = Filename
   endif
   -- Keep, delete or change last selected file.
   -- The Open dialog will start with its dir.
   if new <> -1 then
      call setprofile( app_hini, 'ERESDLGS', 'LASTFILESELECTED', new)
   endif
   SetMenuAttribute( GetAVar('mid_opendlgdirprev'), MIA_CHECKED, (opt = 1 | opt = 2))
   SetMenuAttribute( GetAVar('mid_opendlgdirwork'), MIA_CHECKED, not (opt = 1))
   SetMenuAttribute( GetAVar('mid_opendlgdirfile'), MIA_CHECKED, not (opt = 2))

; ---------------------------------------------------------------------------
defc set_SaveasDlgDir
   universal nepmd_hini
   opt = arg(1)
   if wordpos( opt, '0 1') = 0 then
      return
   endif
   KeyPath = '\NEPMD\User\StartDir\SaveasDlg\Type'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, opt)
   SetMenuAttribute( GetAVar('mid_saveasdlgdirprev'), MIA_CHECKED, (opt = 1))
   SetMenuAttribute( GetAVar('mid_saveasdlgdirwork'), MIA_CHECKED, not (opt = 1))

; ---------------------------------------------------------------------------
defc set_ReflowMargins
   universal nepmd_hini
   universal reflowmargins
   args = strip( arg(1))
   parse value args with lma rma parma
   if lma > '' then
      if rma = '' then
         args = 1 args  -- default value for lma is 1
      endif
      if parma = '' then
         args = args 1  -- default value for parma is 1
      endif
   endif

   KeyPath = '\NEPMD\User\Reflow\MarginsItem'
   i   = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if i = 3 then
      new = args
      if new = '' then
         'ma'  -- Open commandline with current .margins value
         return
      endif
      reflowmargins = .margins
   else
      KeyPath = '\NEPMD\User\Reflow\Margins'i
      new = args
      if new = '' then
         old = NepmdQueryConfigValue( nepmd_hini, KeyPath)
         'commandline set_ReflowMargins' old  -- Open commandline with current value
         return
      endif
      call NepmdWriteConfigValue( nepmd_hini, KeyPath, new)
      reflowmargins = new
   endif
   parse value GetAVar('mtxt_reflowmargins'i) with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins'i), next'['reflowmargins']'rest)

   parse value GetAVar('mtxt_reflowmargins') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins'), next'['reflowmargins']'rest)

; ---------------------------------------------------------------------------
defc ReflowmarginsSelect
   universal nepmd_hini
   universal reflowmargins
   i = strip( arg(1))
   KeyPath = '\NEPMD\User\Reflow\MarginsItem'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, i)
   if i = 3 then
      reflowmargins = .margins
   else
      KeyPath = '\NEPMD\User\Reflow\Margins'i
      reflowmargins = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   SetMenuAttribute( GetAVar('mid_reflowmargins1'), MIA_CHECKED, not (i = 1))
   SetMenuAttribute( GetAVar('mid_reflowmargins2'), MIA_CHECKED, not (i = 2))
   SetMenuAttribute( GetAVar('mid_reflowmargins3'), MIA_CHECKED, not (i = 3))
   parse value GetAVar('mtxt_reflowmargins') with next'['x']'rest
   SetMenuText( GetAVar('mid_reflowmargins'), next'['reflowmargins']'rest)

; ---------------------------------------------------------------------------
; Change edit options and set menu attributes.
; Some options exclude each other, see ExcludeList. The last option wins.
; Flags: universal, nepmd.ini
defc seteditoptions
   universal nepmd_hini
   universal default_edit_options
   opt = arg(1)
   KeyPath = '\NEPMD\User\Edit\DefaultOptions'
   if opt = 'SAVE' then
      ConfigValue = default_edit_options
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue)
      if rc = 0 then
         sayerror 'default_edit_options = 'default_edit_options' saved.'
      endif
      return
   elseif opt = 'RESET' then
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath)
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      default_edit_options = ConfigValue
      if rc = 0 then
         sayerror 'default_edit_options = 'default_edit_options' saved.'
      endif
      return
   elseif opt = 'MENUINIT' then
;      opt = '/b /t /u 'default_edit_options  -- internal default + default_edit_options
      opt = '/b /t 'default_edit_options  -- internal default + default_edit_options
   endif
   opt = lowcase(opt)
   -- Remove multiple and excluding options and spaces
;   ExcludeList = '/b/c/d /t/nt /l/u'    -- for every word in this list: every expression excludes each other
   ExcludeList = '/b/c/d /t/nt'    -- for every word in this list: every expression excludes each other
   rest = lowcase(default_edit_options' 'opt)
   rest = translate( rest, ' ', '/')  -- replace all slashes with spaces to use the word* procs
   newopt = ''
   do while rest <> ''
      parse value rest with next rest
      next = strip(next)
      --call NepmdPmPrintf('*** next = |'next'|')
      if wordpos( next, rest) = 0 then   -- if not found in rest
         -- Find excluding options
         ExcludeWrd = ''
         do w = 1 to words(ExcludeList)
            wrd = word( ExcludeList, w)
            wrd = translate( wrd, ' ', '/')  -- replace all slashes with spaces to use the word* procs
            if wordpos( next, wrd) then
               ExcludeWrd = wrd          -- ExcludeWrd = word of ExcludeList where next belongs to, slashes are replaced
               leave
            endif
         enddo
         --call NepmdPmPrintf('*** ExcludeWrd = |'ExcludeWrd'|')
         -- Check if rest contains options of ExcludeWrd
         Found = 0
         do x = 1 to words( ExcludeWrd)
            xopt = word( ExcludeWrd, x)
            if wordpos( xopt, rest) then
               Found = 1
               leave
            endif
         enddo
         if not Found then  -- if rest doesn't contain options of ExcludeWrd
            newopt = newopt' /'next      -- append '/'next
            -- Set MIA_CHECKED attribute for all options listed in ExcludeWrd
            do x = 1 to words(ExcludeWrd)
               xopt = word( ExcludeWrd, x)  -- single option of ExcludeWrd without the slash
               name = lowcase(xopt)
               --call NepmdPmPrintf('opt = 'arg(1)',name = |'name'|, mid = 'GetAVar('mid_editoptions_'name))
               SetMenuAttribute( GetAVar('mid_editoptions_'name), MIA_CHECKED, next <> xopt)
            enddo
         endif
      endif
   enddo
   newopt = strip(newopt)
   default_edit_options = newopt
   --call NepmdPmPrintf('opt = 'arg(1)', default_edit_options = 'default_edit_options)
   --sayerror 'default_edit_options = 'default_edit_options

; ---------------------------------------------------------------------------
; Change save options and set menu attributes.
; Some options exclude each other, see ExcludeList. The last option wins.
defc setsaveoptions
   universal nepmd_hini
   universal default_save_options
   opt = arg(1)
   KeyPath = '\NEPMD\User\Save\DefaultOptions'
   if opt = 'SAVE' then
      ConfigValue = default_save_options
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue)
      if rc = 0 then
         sayerror 'default_save_options = 'default_save_options' saved.'
      endif
      return
   elseif opt = 'RESET' then
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath)
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      default_save_options = ConfigValue
      if rc = 0 then
         sayerror 'default_save_options = 'default_save_options' saved.'
      endif
      return
   elseif opt = 'MENUINIT' then
      opt = '/a /ns /ne /nt 'default_save_options  -- internal default + default_save_options
   endif
   opt = lowcase(opt)
   -- Replace option /u with /l /ne
   wp = ''
   do while wp <> 0
      wp = wordpos( '/u', opt)
      if wp > 0 then
         opt = subword( opt, 1, wp - 1)' /l /ne 'subword( opt, wp + 1)
      endif
   enddo
   -- Remove multiple and excluding options and spaces
   ExcludeList = '/s/ns /e/ne /t/nt /o/l/a'    -- for every word in this list: every expression excludes each other
   rest = lowcase(default_save_options' 'opt)
   rest = translate( rest, ' ', '/')  -- replace all slashes with spaces to use the word* procs
   newopt = ''
   do while rest <> ''
      parse value rest with next rest
      next = strip(next)
      --call NepmdPmPrintf('*** next = |'next'|')
      if wordpos( next, rest) = 0 then   -- if not found in rest
         -- Find excluding options
         ExcludeWrd = ''
         do w = 1 to words(ExcludeList)
            wrd = word( ExcludeList, w)
            wrd = translate( wrd, ' ', '/')  -- replace all slashes with spaces to use the word* procs
            if wordpos( next, wrd) then
               ExcludeWrd = wrd          -- ExcludeWrd = word of ExcludeList where next belongs to, slashes are replaced
               leave
            endif
         enddo
         --call NepmdPmPrintf('*** ExcludeWrd = |'ExcludeWrd'|')
         -- Check if rest contains options of ExcludeWrd
         Found = 0
         do x = 1 to words( ExcludeWrd)
            xopt = word( ExcludeWrd, x)
            if wordpos( xopt, rest) then
               Found = 1
               leave
            endif
         enddo
         if not Found then  -- if rest doesn't contain options of ExcludeWrd
            newopt = newopt' /'next      -- append '/'next
            -- Set MIA_CHECKED attribute for all options listed in ExcludeWrd
            do x = 1 to words(ExcludeWrd)
               xopt = word( ExcludeWrd, x)  -- single option of ExcludeWrd without the slash
               name = lowcase(xopt)
               --call NepmdPmPrintf('opt = 'arg(1)',name = |'name'|, mid = 'GetAVar('mid_saveoptions_'name))
               SetMenuAttribute( GetAVar('mid_saveoptions_'name), MIA_CHECKED, next <> xopt)
            enddo
         endif
      endif
   enddo
   newopt = strip(newopt)
   -- Remove non-standard options
   --call NepmdPmPrintf('opt = 'arg(1)', newopt = 'newopt)
   rest = newopt
   newopt = ''
   do w = 1 to words(rest)
      wrd = word( rest, w)
      if wrd <> '/a' then
         newopt = newopt' 'wrd
      endif
   enddo
   newopt = strip(newopt)
   default_save_options = newopt
   --call NepmdPmPrintf('opt = 'arg(1)', default_save_options = 'default_save_options)
   --sayerror 'default_save_options = 'default_save_options

; ---------------------------------------------------------------------------
; Change search options and set menu attributes.
; Some options exclude each other, see ExcludeList. The last option wins.
defc setsearchoptions
   universal nepmd_hini
   universal default_search_options
   opt = arg(1)
   KeyPath = '\NEPMD\User\Search\DefaultOptions'
   if opt = 'SAVE' then
      ConfigValue = default_search_options
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ConfigValue)
      if rc = 0 then
          sayerror 'default_search_options = 'default_search_options' saved.'
      endif
      return
   elseif opt = 'RESET' then
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath)
      ConfigValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      default_search_options = ConfigValue
      if rc = 0 then
          sayerror 'default_search_options = 'default_search_options' saved.'
      endif
      return
   elseif opt = 'MENUINIT' then
      opt = '+faeuihp1q'default_search_options  -- internal default + default_search_options
   endif
   opt = lowcase(opt)
   -- Remove multiple and excluding options and spaces
   ExcludeList = '+- fr ubt am ec i^ hgxw pk 1* nq'    -- for every word in this list: every char excludes each other
   rest = lowcase(default_search_options''opt)
   newopt = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char of rest
      -- Remove all spaces
      if next = ' ' then
         iterate
      elseif pos( next, rest) = 0 then   -- if not found in rest
         -- Find excluding options
         ExcludeWrd = ''
         do w = 1 to words(ExcludeList)
            wrd = word( ExcludeList, w)
            if pos( next, wrd) then
               ExcludeWrd = wrd          -- ExcludeWrd = word of ExcludeList where next belongs to
               leave
            endif
         enddo
         if not verify( rest, ExcludeWrd, 'M') then  -- if rest doesn't contain chars of ExcludeWrd
            newopt = newopt''next      -- append next
            -- Set MIA_CHECKED attribute for all options listed in ExcludeWrd
            do x = 1 to length(ExcludeWrd)
               xopt = substr( ExcludeWrd, x, 1)  -- single option of ExcludeWrd
               name = lowcase(xopt)
               --call NepmdPmPrintf('opt = 'arg(1)',name = 'name)
               SetMenuAttribute( GetAVar('mid_searchoptions_'name), MIA_CHECKED, next <> xopt)
            enddo
         endif
      endif
   enddo
   -- Remove non-standard options
   rest = newopt
   newopt = ''
   do while rest <> ''
      parse value rest with next 2 rest  -- parse 1 char of rest
      if pos( next, 'uihp1q') = 0 then
         newopt = newopt''next
      endif
   enddo
   default_search_options = newopt
   --call NepmdPmPrintf('opt = 'arg(1)', default_search_options = 'default_search_options)
   --sayerror 'default_search_options = 'default_search_options

; ---------------------------------------------------------------------------
; Nothing defined here.
defproc build_menu_accelerators(activeaccel)
   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')

   --i = i + 1
   --buildacceltable activeaccel, 'dokey ...',  AF_... + AF_..., VK_..., i

   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   return

; ---------------------------------------------------------------------------
; Update the menu text for items affected by CUA_menu_Accel = 0|1.
; Todo: provide a generic macro, that removes the Alt+<key> string only,
; instead of repeating the whole accel key string. The Alt+<key> binding
; should be the first string after \9 and maybe before ' | ', when added.
defproc update_mark_menu_text
   universal cua_marking_switch
   universal cua_menu_accel
   if cua_menu_accel then
      UsedMenuAccelerators = GetAVar('usedmenuaccelerators')
   else
      UsedMenuAccelerators = ''
   endif

   MenuText = COPY_MARK_MENU__MSG
   Key      = 'C'
   if cua_marking_switch = 0 & wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   midname  = 'mid_copymark'
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = MOVE_MARK_MENU__MSG
   Key      = 'M'
   midname  = 'mid_movemark'
   if cua_marking_switch = 0 & wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = OVERLAY_MARK_MENU__MSG
   Key      = 'O'
   midname  = 'mid_overlaymark'
   if cua_marking_switch = 0 & wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = ADJUST_MARK_MENU__MSG
   Key      = 'A'
   midname  = 'mid_adjustmark'
   if cua_marking_switch = 0 & wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = UNMARK_MARK_MENU__MSG
   Key      = 'U'
   midname  = 'mid_unmark'
   if wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key' | 'CTRL_KEY__MSG'+\ | 'CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+A'
   else
      MenuText = MenuText\9 || CTRL_KEY__MSG'+\ | 'CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+A'
   endif
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = DELETE_MARK_MENU__MSG
   Key      = 'D'
   midname  = 'mid_deletemark'
   if wordpos( Key, UsedMenuAccelerators) = 0 then
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   SetMenuText( GetAVar(midname), MenuText)

   return

; ---------------------------------------------------------------------------
; Update the menu text for items affected by default paste = C|B|L
defproc update_paste_menu_text
   universal nepmd_hini
   KeyPath = "\NEPMD\User\Mark\DefaultPaste"
   DefaultPaste = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DefaultPaste = 'C' then
      AlternatePaste = 'L'
   else
      AlternatePaste = 'C'
   endif

   DefaultPasteKey   = SHIFT_KEY__MSG'+'INSERT_KEY__MSG
   AlternatePasteKey = CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'INSERT_KEY__MSG

   midname  = 'mid_paste'
   if DefaultPaste = 'C' then
      Key   = DefaultPasteKey
   elseif AlternatePaste = 'C' then
      Key   = AlternatePasteKey
   else
      Key   = ''
   endif
   MenuText = PASTE_C_MENU__MSG\9 || Key
   SetMenuText( GetAVar(midname), MenuText)

   midname  = 'mid_pastelines'
   if DefaultPaste = 'L' then
      Key   = DefaultPasteKey
   elseif AlternatePaste = 'L' then
      Key   = AlternatePasteKey
   else
      Key   = ''
   endif
   MenuText = PASTE_L_MENU__MSG\9 || Key
   SetMenuText( GetAVar(midname), MenuText)

   midname  = 'mid_pasteblock'
   if DefaultPaste = 'B' then
      Key   = DefaultPasteKey
   elseif AlternatePaste = 'B' then
      Key   = AlternatePasteKey
   else
      Key   = ''
   endif
   MenuText = PASTE_B_MENU__MSG\9 || Key
   SetMenuText( GetAVar(midname), MenuText)

   return

