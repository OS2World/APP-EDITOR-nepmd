/****************************** Module Header *******************************
*
* Module Name: newmenu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: newmenu.e,v 1.1 2004-06-03 22:25:58 aschn Exp $
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
- Tools menu: more formatting items.
- Options menu: more config items.
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
;   51  newmenu: Tools
;   52  newmenu: Options > Edit/Save/Search
;   53  newmenu: Project
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
; Usually such things are defined at definit. But since the menu is linked,
; definit isn't allowed anymore. Therefore we put it in a defc, executed in
; loaddefaultmenu.
defc initmenu
   universal nepmd_hini
   universal nodismiss
   call SetAVar( 'mids', '')        -- reset list of used mids

   call SetAVar( 'mid_file'   , 2)
   call SetAVar( 'mid_edit'   , 8)
   call SetAVar( 'mid_tools'  , GetUniqueMid())  -- first available mid is 51 (50 is used)
   call SetAVar( 'mid_search' , 3)
   call SetAVar( 'mid_view'   , 5)
   call SetAVar( 'mid_options', 4)
   call SetAVar( 'mid_run'    , 0)  -- i = 101...199 are used for menuitem ids
;  call SetAVar( 'mid_project', 9)  -- submenu replaced by the current selected project's submenu, e.g. 'TeX'
   call SetAVar( 'mid_help'   , 6)  -- 6 should not be changed to not break other packages
   call SetAVar( 'mid_editsavesearchoptions', GetUniqueMid())  -- second available mid is 52, otherwise we would run out of 4xx ids

   -- Define a list of used menu accelerators, that can't be used as standard
   -- accelerator keys combined with Alt anymore, when 'Menu accelerators' is
   -- activated.
   call SetAVar( 'usedmenuaccelerators', 'F E T S V O R H')

   -- Define a list of names for which 'menuinit_'name defcs are defined.
   -- Keep this list in sync with the 'menuinit_'name defcs!
   -- (Otherwise 'processmenuinit' will never execute that defc.)
   call SetAVar( 'definedmenuinits', 'file edit search tools view options run project help' ||
                                     ' fileproperties mark cursor bookmarks' ||
                                     ' mainsettings framecontrols editoptions saveoptions searchoptions' ||
                                     ' recordkeys openfolder treecommands reflowsettings autorestore' ||
                                     ' accelsettings marginsandtabs readonlyandlock menubarsandcolors' ||
                                     ' macros mouseandcursor')

   KeyPath = '\NEPMD\User\Menu\NoDismiss'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   nodismiss = 32*on

; ---------------------------------------------------------------------------
; Called by defmain -> initconfig, STDCTRL.E (formerly by definit, MENUACCEL.E).
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³What's it called  : loaddefaultmenu                                          ³
³                                                                             ³
³What does it do   : used by stdcnf.e to setup default EPM action bar         ³
³                    (Note: a menu id of 0 halts the interpreter when         ³
³                     selected.)                                              ³
³                                                                             ³
³Who and When      : Jerry C.     2/25/89                                     ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

defc loaddefaultmenu
   universal activemenu, defaultmenu
   universal menuloaded                   -- for to check if menu is already built

   parse arg menuname .
   if menuname = '' then                  -- Initialization call
      menuname = 'default'
      defaultmenu = menuname              -- default menu name
      activemenu  = defaultmenu
   endif

   -- Set menu ids and set universal vars 'default_*_options'
   'initmenu'

   call add_file_menu(menuname)      -- id = 2
   call add_edit_menu(menuname)      -- id = 8
   call add_tools_menu(menuname)     -- id = 7
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
   mid = GetAVar('mid_file')
   i = mid'00'
   buildsubmenu  menuname, mid, FILE_BAR__MSG,                                                     -- File ------------
                                FILE_BARP__MSG,
                                0, mpfrom2short(HP_FILE, 0)  -- MIS must be 0 for submenu
   i = i + 1;
   buildmenuitem menuname, mid, i, NEW_MENU__MSG '.Untitled',                                      -- New .Untitled
                                   'NEW' ||
                                   NEW_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_NEW, 0)
   if ring_enabled then
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Add .Untitled',                                                -- Add .Untitled
                                   'xcom e /n' ||
                                   \1'Edit a new, empty file in this window',
                                   MIS_TEXT, mpfrom2short(HP_FILE_EDIT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Add...'\9'F8',                                                 -- Add...
                                   'opendlg EDIT' ||
                                   ADD_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_EDIT, 0)
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, OPEN_NEW_MENU__MSG,                                             -- Open .Untitled
                                   "open ''" ||
                                   OPEN_NEW_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_OPEN_NEW, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, OPEN_MENU__MSG\9 || 'F5 | 'CTRL_KEY__MSG'+O',                   -- Open...
                                   'opendlg' ||
                                   OPEN_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_OPEN, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open bin...',                                                  -- Open bin...
                                   'OpenBinDlg' ||
                                   \1'Select a binary file to edit',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_history', i);
   buildmenuitem menuname, mid, i, 'History',                                                      -- History   >
                                   '' ||
                                   \1'Edit previously loaded files',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save as last ring',                                                  -- Save as last ring
                                   'savering' ||
                                   \1'Save current file list as last edit ring',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Load last ring',                                                     -- Load last ring
                                   'restorering' ||
                                   \1'Restore last saved edit ring',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save group...',                                                      -- Save group
                                   'groups savegroup' ||
                                   \1'Save current file list as group',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Load group...',                                                      -- Load group
                                   'groups loadgroup' ||
                                   \1'Restore a previously saved group',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List edit history...'\9 || CTRL_KEY__MSG'+F9',                       -- List edit history...
                                   'history edit' ||
                                   \1'Open a list box with previous edit cmds',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List loaded files...'\9 || CTRL_KEY__MSG'+F10',                      -- List loaded files...
                                   'history load' ||
                                   \1'Open a list box with previous loaded files',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'List saved files...'\9 || CTRL_KEY__MSG'+F11',                       -- List saved files...
                                   'history save' ||
                                   \1'Open a list box with previous saved files',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'FTP',                                                          -- FTP   >
                                   '' ||
                                   \1'Download or upload file from/to FTP server',
                                   MIS_TEXT, MIA_DISABLED
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_fileproperties', i);
   buildmenuitem menuname, mid, i, '~File properties',                                             -- File properties   >
                                   '' ||
                                   \1'Properties for this buffer/file only',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_mode', i); call SetAVar( 'mtxt_mode', 'Mode []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_mode'),                                                -- Mode...
                                   'mode' ||
                                   \1'Select or show mode for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_tabs', i); call SetAVar( 'mtxt_tabs', 'Tabs []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_tabs'),                                                -- Tabs...
                                   'tabs' ||
                                   \1'Select or show tabs for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_margins', i); call SetAVar( 'mtxt_margins', 'Margins []...')
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_margins'),                                             -- Margins...
                                   'ma' ||
                                   \1'Select or show margins for the current file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_readonly', i);
   buildmenuitem menuname, mid, i, 'Readonly',                                                           -- Readonly
                                   'toggle_readonly' ||
                                   \1'Enable or disable readonly mode',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_locked', i);
   buildmenuitem menuname, mid, i, 'Locked',                                                             -- Locked
                                   'toggle_locked' ||
                                   \1'Enable or disable write access for other apps',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_wpsproperties', i);
   buildmenuitem menuname, mid, i, 'WPS properties...',                                                  -- WPS properties...
                                   'OpenSettings' ||
                                   \1'Open WPS properties dialog for current file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_advancedmarking', i);
   buildmenuitem menuname, mid, i, 'Advanced marking',                                                   -- Advanced marking
                                   'toggle_cua_mark' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_streammode', i);
   buildmenuitem menuname, mid, i, 'Stream mode',                                                        -- Stream mode
                                   'toggle_stream' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_syntaxexpansion', i);
   buildmenuitem menuname, mid, i, 'Syntax expansion',                                                   -- Syntax expansion
                                   'toggle_expand' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_keywordhighlighting', i);
   buildmenuitem menuname, mid, i, 'Keyword highlighting',                                               -- Keyword highlighting
                                   'toggle_highlight' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_tabkey', i);
   buildmenuitem menuname, mid, i, 'Tabkey',                                                             -- Tabkey
                                   'toggle_tabkey' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_matchtab', i);
   buildmenuitem menuname, mid, i, 'Matchtab',                                                           -- Matchtab
                                   'toggle_matchtab' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_autospellcheck', i);
   buildmenuitem menuname, mid, i, DYNASPELL_MENU__MSG,                                                  -- Auto-spellcheck
                                   'toggle_dynaspell' ||
                                   DYNASPELL_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_OPTIONS_DYNASPELL, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_importfile', i);
   buildmenuitem menuname, mid, i, 'Import file...',                                               -- Import file...
                                   'opendlg GET' ||
                                   GET_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_GET, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, RENAME_MENU__MSG\9'F7',                                         -- Rename...
                                   'rename' ||
                                   RENAME_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_NAME, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Reload',                                                       -- Reload
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
   buildmenuitem menuname, mid, i, 'Save all',                                                     -- Save all
                                   'SaveAll' ||
                                   \1'Save all files of the ring',
                                   MIS_TEXT, 0
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, QUIT_MENU__MSG\9'F3',                                           -- Quit file
                                   'quit' ||
                                   QUIT_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_QUIT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, PRT_FILE_MENU__MSG'...',                                        -- Print file...
                                   'printdlg' ||
                                   ENHPRT_FILE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FILE_ENHPRINT, 0)
   return


; -------------------------------------------------------------------------------------- Edit -------------------------

define  -- Prepare for some conditional tests
   maybe_ring_accel = "' ' <"  -- Will be true for any letter
compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   maybe_actions_accel = 'ACTIONS_ACCEL__L <>'
compile else
   maybe_actions_accel = "' ' <"  -- Will be true for any letter
compile endif

/*
Edit
   ---------------------------
     Mark                    >       Chars, Lines, Block, Word, Identifier, Sentence, Paragraph, Function block
   ---------------------------
*/
defproc add_edit_menu(menuname)
   universal CUA_marking_switch

   mid = GetAVar('mid_edit')
   i = mid'00'
   buildsubmenu  menuname, mid, EDIT_BAR__MSG,                                                     -- Edit ------------
                                EDIT_BARP__MSG,
                                0, mpfrom2short(HP_EDIT, 0)  -- MIS must be 0 for submenu
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
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
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
   buildmenuitem menuname, mid, i, PASTE_C_MENU__MSG/*||PASTE_C_KEY*/,                                 -- Paste
                                   'Paste C' ||
                                   PASTE_C_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTEC, 0)
   i = i + 1; call SetAVar( 'mid_pastelines', i);
   buildmenuitem menuname, mid, i, PASTE_L_MENU__MSG/*||PASTE_L_KEY*/,                                 -- Paste lines
                                   'Paste' ||
                                   PASTE_L_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTE, 0)
   i = i + 1; call SetAVar( 'mid_pasteblock', i);
   buildmenuitem menuname, mid, i, PASTE_B_MENU__MSG/*||PASTE_B_KEY*/,                                 -- Paste block
                                   'Paste B' ||
                                   PASTE_B_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_PASTEB, 0)
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
   i = i + 1;
   buildmenuitem menuname, mid, i, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/ | 'CTRL_KEY__MSG'+A',  -- Select all
                                   'select_all' ||
                                   SELECT_ALL_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_EDIT_SELECTALL, 0)
   i = i + 1; call SetAVar( 'mid_unmark', i);
   buildmenuitem menuname, mid, i, UNMARK_MARK_MENU__MSG,                                          -- Unmark
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


; -------------------------------------------------------------------------------------- Tools ------------------------
/*
Tools
   ---------------------------
     Spell check            >
   ---------------------------
     Style...
     Remove all attributes
     Insert pagebreak
   ---------------------------
     Record keys            >
   ---------------------------
     Draw lines
     Sort
   ---------------------------
     Case word/mark        [>]     o Toggle | Upper | Lower
   ---------------------------
     Recode                 >
   ---------------------------
     Reflow                 >    (could also be called 'Format')
   ---------------------------
     Comment
     Uncomment
   ---------------------------
     Indent lines/block
     Undent lines/block
     Shift left
     Shift right
   ---------------------------
     Insert module header
     Insert function header
     Insert comment block
   ---------------------------
*/
defproc add_tools_menu(menuname)
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
   mid = GetAVar('mid_tools')
   i = mid'00'
   buildsubmenu  menuname, mid, '~Tools',                                                          -- Tools -----------
                                \1'Menus related to views, cursor pos and windows',
                                0, 0  -- MIS must be 0 for submenu
compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
compile endif
   i = i + 1; call SetAVar( 'mid_spellcheck', i);
   buildmenuitem menuname, mid, i, 'Spellcheck',                                                   -- Spellcheck   >
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
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_OPTIONS_SYN, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                            --------------------
                                   '',
                                   MIS_SEPARATOR, 0
compile if CHECK_FOR_LEXAM
   endif
compile endif
   i = i + 1;
   buildmenuitem menuname, mid, i, 'St~yle...'\9 || CTRL_KEY__MSG'+Y',                             -- Style...
                                   'fontlist' ||
                                   STYLE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_STYLE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Remove all attributes',                                        -- Remove all attributes
                                   '' ||
                                   'Remove all color and font attributes of current file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_recordkeys', i);
   buildmenuitem menuname, mid, i, 'Record keys',                                                  -- Record keys   >
                                   '' ||
                                   \1'Record and playback keys',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_startrecording', i);
   buildmenuitem menuname, mid, i, 'Start/end recording'\9 || CTRL_KEY__MSG'+R',                         -- Start recording
                                   'dokey c_r' ||
                                   \1'',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_playback', i);
   buildmenuitem menuname, mid, i, 'Playback'\9 || CTRL_KEY__MSG'+T',                                    -- Playback
                                   'dokey c_t' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Wrap',                                                       -- Wrap   >
                                   '' ||
                                   \1'Reformat all: add linebreaks',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Keepindent 79',                                                      -- Keepindent 79
                                   'wrap KEEPINDENT 79' ||
                                   \1'Split lines while keeping indent of line above, column = 79',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Keepindent...',                                                      -- Keepindent...
                                   'wrap KEEPINDENT *' ||
                                   \1'Split lines while keeping indent of line above, enter colum',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Split 79',                                                           -- Split 79
                                   'wrap SPLIT 79' ||
                                   \1'Split lines, colum = 79',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Split...',                                                           -- Split...
                                   'wrap SPLIT *' ||
                                   \1'Split lines, enter colum',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Split line'\9 || ALT_KEY__MSG'+S',                                   -- Split...
                                   'dokey a_s' ||
                                   \1'Split current line at cursor, keep indent',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Join line'\9 || ALT_KEY__MSG'+J',                                   -- Split...
                                   'dokey a_j' ||
                                   \1'Join current line with next line, respect right margin',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Wordproc',                                                           -- Wordproc
                                   'wordproc' ||
                                   \1'Rejoin lines to prepare for export to a word processor',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_reflow', i);
   buildmenuitem menuname, mid, i, 'Re~flow',                                                       -- Reflow   >
                                   '' ||
                                   \1'Reformat paragraph, mark or all',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_reflowpartomargins', i);
   buildmenuitem menuname, mid, i, 'Par to margins'\9 || ALT_KEY__MSG'+P',                               -- Par to margins
                                   'dokey a_p' ||
                                   \1'Reformat mark or paragraph to fit the current margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Lines to margins...',                                                -- Par to margins
                                   'commandline flow 1 73 1' ||
                                   \1'Reformat lines from cursor to par end, enter margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Par to window',                                                      -- Par to window
                                   'reflow' ||
                                   \1'Reformat paragraph to fit the current window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Block'\9 || ALT_KEY__MSG'+R',                                        -- Block
                                   'dokey a_r' ||
                                   \1'Mark lines or block first, then mark new block size',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'All to margins',                                                     -- All to margins
                                   'reflow_all' ||
                                   \1'Reformat all to fit the current margins',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Mail (all)',                                                         -- Mail (all)
                                   'reflowmail' ||
                                   \1'Reformat current mail (beta, correct indents by hand)',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Remove HTML (all)',                                                  -- Remove HTML (all)
                                   'rx unhtml' ||
                                   \1'Remove HTML tags from current file',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Comment',                                                      -- Comment
                                   'comment' ||
                                   \1'Comment marked lines',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Uncomment',                                                    -- Uncomment
                                   'uncomment' ||
                                   \1'Remove comment chars for marked lines',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Indent lines/block'\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+<',   -- Indent lines/block
                                   'indentblock' ||
                                   \1'Indent marked lines or block starting at cursor 1 level',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Unindent lines/block'\9 || CTRL_KEY__MSG'+<',                  -- Unindent lines/block
                                   'indentblock U' ||
                                   \1'Unindent marked lines or block starting at cursor 1 level',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Shift left'\9 || CTRL_KEY__MSG'+F7',                           -- Shift left
                                   'key 1 c_f7' ||
                                   'Shift marked text left 1 character',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Shift right'\9 || CTRL_KEY__MSG'+F8',                          -- Shift right
                                   'key 1 c_f8' ||
                                   'Shift marked text right 1 character',
                                   MIS_TEXT, 0
   return

; -------------------------------------------------------------------------------------- Search -----------------------
defproc add_search_menu(menuname)
   mid = GetAVar('mid_search')
   i = mid'00'
   buildsubmenu  menuname, mid, SEARCH_BAR__MSG,                                                   -- Search ----------
                                ''SEARCH_BARP__MSG,
                                0, mpfrom2short(HP_SEARCH, 0)  -- MIS must be 0 for submenu
   i = i + 1;
   buildmenuitem menuname, mid, i, SEARCH_MENU__MSG\9 || CTRL_KEY__MSG'+S',                        -- Search...
                                   'searchdlg' ||
                                   SEARCH_MENUP__MSG,
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
   buildmenuitem menuname, mid, i, '~Global find next'\9 || CTRL_KEY__MSG'+V',                     -- Global find next
                                   'globalfind' ||
                                   \1'Repeat previous Locate command for all files in the ring',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_globalchangenext', i);
   buildmenuitem menuname, mid, i, 'Global c~hange next',                                          -- Global change next
                                   'globalchange' ||
                                   \1'Repeat previous Change command for all files in the ring',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_toggledirection', i);
   buildmenuitem menuname, mid, i, 'Toggle ~direction'\9 || CTRL_KEY__MSG'+-',                     -- Toggle direction
                                   'ToggleSearchDirection' ||
                                   \1'Toggle back/forward for current locate/change command',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Find ~indentifier',                                            -- Find identifier
                                   'findword' ||
                                   \1'Find identifier (C-style word) under cursor',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_findmark', i);
   buildmenuitem menuname, mid, i, 'Find ~mark',                                                   -- Find mark
                                   'findmark' ||
                                   \1'Find marked string',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Find b~racket'\9 || CTRL_KEY__MSG'+[ | 'CTRL_KEY__MSG'+8',     -- Find bracket
                                   'passist' ||
                                   \1'Find matching environment expression',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_mark', i);
   buildmenuitem menuname, mid, i, 'Mar~k',                                                        -- Mark   >
                                   \1'Save and restore a marked area',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_gotomark', i);
   buildmenuitem menuname, mid, i, '~Go to mark'\9 || ALT_KEY__MSG'+Y',                                  -- Go to mark
                                   'dokey a+y' ||
                                   \1'Position cursor on begin of marked area',
                                   MIS_TEXT, 0
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
   buildmenuitem menuname, mid, i, SWAP_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+=',          -- Swap mark
                                   'swapmark' ||
                                   SWAP_MARK_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_EDIT_SWAPMARK, MIA_DISABLED)
   i = i + 1; call SetAVar( 'mid_cursor', i);
   buildmenuitem menuname, mid, i, 'C~ursor',                                                      -- Cursor   >
                                   \1'Save and restore cursor position',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Sho~w cursor'\9 || SHIFT_KEY__MSG'+F5, 'ALT_KEY__MSG'+-',            -- Highlight cursor
                                   'mc /centerline/highlightcursor' ||
                                   \1'Center line with cursor',
                                   MIS_TEXT, 0
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
   buildmenuitem menuname, mid, i, SWAP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+=',                         -- Swap cursor
                                   'swappos' ||
                                   SWAP_CURSOR_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_EDIT_SWAPPOS, MIA_DISABLED)
   i = i + 1; call SetAVar( 'mid_bookmarks', i);
   buildmenuitem menuname, mid, i, BOOKMARKS_MENU__MSG,                                            -- Bookmarks   >
                                   BOOKMARKS_MENUP__MSG,
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
                                   TAGS_MENUP__MSG,
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_SEARCH_TAGS, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, TAGSDLG_MENU__MSG\9,                                                  -- Tags dialog...
                                   'poptagsdlg' ||
                                   TAGSDLG_MENUP__MSG,
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
   buildmenuitem menuname, mid, i, SCAN_TAGS_MENU__MSG,                                                  -- Scan current file...
                                   'tagscan' ||
                                   SCAN_TAGS_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_SEARCH_TAGS, 0)

   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'GFC curr~ent file...',                                         -- GFC current file
                                   'GfcCurrentFile' ||
                                   \1'Compare current file with another',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~All /<string>...',                                            -- All /<string>...
                                   'commandline all /' ||
                                   \1'List all occurances, than use Ctrl+Q to toggle',
                                   MIS_TEXT, 0
   return

; -------------------------------------------------------------------------------------- View -------------------------
defproc add_view_menu(menuname)
   universal ring_enabled
   mid = GetAVar('mid_view')
   i = mid'00'
   buildsubmenu  menuname, mid, '~View',                                                           -- View ------------
                                \1'Menus related to views, cursor pos and windows',
                                0, 0  -- MIS must be 0 for submenu
   i = i + 1; call SetAVar( 'mid_softwrap', i);
   buildmenuitem menuname, mid, i, 'Soft ~wrap',                                                   -- Soft wrap
                                   'ToggleWrap' ||
                                   \1'Toggle non-destructive wrap at window width',
                                   MIS_TEXT, 0
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
   if ring_enabled then
   i = i + 1; call SetAVar( 'mid_listring', i);
   buildmenuitem menuname, mid, i, LIST_FILES_MENU__MSG\9 || CTRL_KEY__MSG'+G',                    -- List ring...
                                   'Ring_More' ||
                                   LIST_FILES_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_LIST, 0)
   endif
   i = i + 1;
   buildmenuitem menuname, mid, i, AUTOSAVE_MENU__MSG,                                             -- Autosave...
                                   'autosave ?' ||
                                   AUTOSAVE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_AUTOSAVE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, MESSAGES_MENU__MSG,                                             -- Messages...
                                   'messagebox' ||
                                   MESSAGES_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_MESSAGES, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Switch to next window'\9 || CTRL_KEY__MSG'+F12',              -- Switch to next window
                                   'next_win' ||
                                   \1'Activate the next EPM window',
                                   MIS_TEXT, 0
   return

; -------------------------------------------------------------------------------------- Options ----------------------
defproc add_options_menu(menuname)
   universal ring_enabled
   universal font
   universal nodismiss
   mid = GetAVar('mid_options')
   i = mid'00'
   buildsubmenu  menuname, mid, OPTIONS_BAR__MSG,                                                  -- Options ---------
                                OPTIONS_BARP__MSG,
                                0, mpfrom2short(HP_OPTIONS, 0)  -- MIS must be 0 for submenu
   -- Since we have more than 99 menu items here, we use a separate id for the edit/save/search options
   saved_i = i
   i = GetAVar('mid_editsavesearchoptions')'00'
   i = i + 1; call SetAVar( 'mid_editoptions', i); call SetAVar( 'mtxt_editoptions', 'Edit   []');
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
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_editoptions_u', i)
   buildmenuitem menuname, mid, i, '/~u'\9'Unix line end (LF)',
                                   'seteditoptions /u',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_editoptions_l', i)
   buildmenuitem menuname, mid, i, '/~l'\9'DOS line end (CRLF)*',
                                   'seteditoptions /l',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Reset to initial ~default (*)',
                                   'seteditoptions RESET',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, ''\9'Sa~ve as default',
                                   'seteditoptions SAVE',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1; call SetAVar( 'mid_saveoptions', i); call SetAVar( 'mtxt_saveoptions', 'Save   []');
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
   buildmenuitem menuname, mid, i, ''\9'~auto-line-end*',
                                   'setsaveoptions /a',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_saveoptions_o', i)
   buildmenuitem menuname, mid, i, '/~o'\9'force DOS line end (CRLF)',
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
   i = i + 1; call SetAVar( 'mid_searchoptions', i); call SetAVar( 'mtxt_searchoptions', 'Search   []');
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
   buildmenuitem menuname, mid, i, '~^'\9'excluding search',  -- options ~ and ^ are the same
                                   'setsearchoptions ^',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_searchoptions_h', i)
   buildmenuitem menuname, mid, i, ''\9'c~hars*',
                                   'setsearchoptions h',
                                   MIS_TEXT, nodismiss
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
   -- Returning to the standard menu id:
   i = saved_i
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Default settings dialog...',                                           -- Default settings dialog...
                                   'configdlg' ||
                                   CONFIG_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CONFIG, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
;   i = i + 1; call SetAVar( 'mid_preferences', i);
;   buildmenuitem menuname, mid, i, PREFERENCES_MENU__MSG,                                          -- Preferences   >
;                                   PREFERENCES_MENUP__MSG,
;                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_OPTIONS_PREFERENCES, 0)
   i = i + 1; call SetAVar( 'mid_mainsettings', i);
   buildmenuitem menuname, mid, i, 'Main settings',                                                -- Main settings  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_OPTIONS_PREFERENCES, 0)
;   i = i + 1;
;   buildmenuitem menuname, mid, i, CONFIG_MENU__MSG,                                                     -- Settings...
;                                   'configdlg' ||
;                                   CONFIG_MENUP__MSG,
;                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CONFIG, 0)
   i = i + 1; call SetAVar( 'mid_defaultadvancedmarking', i);
   buildmenuitem menuname, mid, i, 'Default advanced marking (i)',                                       -- Default advanced marking (i)
                                   'toggle_default_cua_mark' ||
                                   ADVANCEDMARK_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CUATOGGLE, nodismiss)
   i = i + 1; call SetAVar( 'mid_defaultstreammode', i);
   buildmenuitem menuname, mid, i, 'Default stream mode (i)',                                            -- Default stream mode (i)
                                   'toggle_default_stream' ||
                                   STREAMMODE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_STREAM, nodismiss)
   i = i + 1; call SetAVar( 'mid_defaultsyntaxexpansion', i);
   buildmenuitem menuname, mid, i, 'Default syntax expansion',                                           -- Default syntax expansion
                                   'toggle_default_expand' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_defaultkeywordhighlighting', i);
   buildmenuitem menuname, mid, i, 'Default keyword highlighting',                                       -- Default keyword highlighting
                                   'toggle_default_highlight' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_ringenabled', i);
   buildmenuitem menuname, mid, i, RINGENABLED_MENU__MSG'! (i)',                                         -- Ring enabled! (i)
                                   'ring_toggle' ||
                                   RINGENABLED_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_OPTIONS_RINGENABLE, 0)
   i = i + 1; call SetAVar( 'mid_marginsandtabs', i);
   buildmenuitem menuname, mid, i, 'Margins and tabs settings',                                    -- Margins and tabs settings  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_defaultmargins', i); call SetAVar( 'mtxt_defaultmargins', 'Default margins []...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_defaultmargins'),                                      -- Default margins...
                                   'DefaultMargins' ||
                                   \1'Change default margins for next loaded files',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_defaulttabs', i); call SetAVar( 'mtxt_defaulttabs', 'Default tabs []...');
   buildmenuitem menuname, mid, i, GetAVar( 'mtxt_defaulttabs'),                                         -- Default tabs...
                                   'DefaultTabs' ||
                                   \1'Change default tabs for next loaded files',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_defaulttabkey', i);
   buildmenuitem menuname, mid, i, 'Default tabkey (i)',                                                 -- Default Tabkey
                                   'toggle_default_tabkey' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_defaultmatchtab', i);
   buildmenuitem menuname, mid, i, 'Default matchtab',                                                   -- Default Matchtab
                                   'toggle_default_matchtab' ||
                                   \1'',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_showtabs', i);
   buildmenuitem menuname, mid, i, 'Show tabs',                                                          -- Show tabs
                                   'toggle_tabglyph' ||
                                   \1'',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss

   i = i + 1; call SetAVar( 'mid_accelsettings', i);
   buildmenuitem menuname, mid, i, 'Accelerator keys settings',                                    -- Accelerator keys settings  >
                                   \1'Configure Alt key combinations to execute menu items',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_menuaccelerators', i);
   buildmenuitem menuname, mid, i, CUAACCEL_MENU__MSG' (i)',                                             -- Menu accelerators (i)
                                   'accel_toggle' ||
                                   \1'Enable Alt+<key>s for menu (disables many mark actions)',
                                   MIS_TEXT, mpfrom2short(HP_OPTIONS_CUAACCEL, nodismiss)
   i = i + 1; call SetAVar( 'mid_blockleftaltkey', i);
   buildmenuitem menuname, mid, i, 'Block left Alt key',                                                 -- Block left Alt key
                                   'toggle_block_left_alt_key' ||
                                   \1'Prevent left Alt from going to menu (use F10)',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_blockrightaltkey', i);
   buildmenuitem menuname, mid, i, 'Block right Alt key',                                                -- Block right Alt key
                                   'toggle_block_right_alt_key' ||
                                   \1'Prevent right Alt from going to menu (use F10)',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss

   i = i + 1; call SetAVar( 'mid_mouseandcursor', i);
   buildmenuitem menuname, mid, i, 'Mouse and cursor settings',                                    -- Mouse and cursor settings  >
                                   \1'',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_mousestyle', i); call SetAVar( 'mtxt_mousestyle', 'Default mouse mark: []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_mousestyle'),                                           -- Default mouse mark: [char]
                                   'toggle_mousestyle' ||
                                   \1'Mark style for MB1, use Ctrl+MB1 or MB3 for alt. mark',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_defaultpaste', i); call SetAVar( 'mtxt_defaultpaste', 'Default paste: []');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_defaultpaste'),                                         -- Default paste: [char]
                                   'toggle_default_paste' ||
                                   \1'Paste style for Sh+Ins or Alt+MB1, add Sh for alt. paste',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_dragalwaysmarks', i);
   buildmenuitem menuname, mid, i, 'Drag always marks',                                                  -- Drag always marks
                                   'toggle_drag_always_marks' ||
                                   \1'Every drag starts a new mark (avoid the ''Text already marked'' msg)',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_keepcursoronscreen', i);
   buildmenuitem menuname, mid, i, 'Keep cursor on screen',                                              -- Keep cursor on screen
                                   'toggle_keep_cursor_on_screen' ||
                                   \1'Synchronize cursor''s vertical pos. with screen',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_scrollafterlocate', i); call SetAVar( 'mtxt_scrollafterlocate', 'Scroll after locate []...');
   buildmenuitem menuname, mid, i, GetAVar('mtxt_scrollafterloacate'),                                   -- Scroll after locate []...
                                   'ScrollAfterLocate' ||
                                   \1'View found string at a special v-pos.',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0


/*
   i = i + 1; call SetAVar( 'mid_modesettings', i);
   buildmenuitem menuname, mid, i, 'Mode settings...',                                             -- Mode settings...
                                   '',
                                   MIS_TEXT, MIA_DISABLED
*/

   i = i + 1; call SetAVar( 'mid_readonlyandlock', i);
   buildmenuitem menuname, mid, i, 'Readonly and lock settings',                                   -- Readonly and lock   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_respectreadonly', i);
   buildmenuitem menuname, mid, i, 'Respect readonly',                                                   -- Respect readonly
                                   'toggle_respect_readonly' ||
                                   \1'Toggle readonly file attribute disables edit mode',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_lockonmodify', i);
   buildmenuitem menuname, mid, i, 'Lock on modify',                                                     -- Lock on modify
                                   'toggle_lock_on_modify' ||
                                   \1'Toggle deny write access if file was modified',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1; call SetAVar( 'mid_reflowsettings', i);
   buildmenuitem menuname, mid, i, 'Reflow settings',                                              -- Reflow settings   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_twospaces', i);
   buildmenuitem menuname, mid, i, 'Two spaces',                                                         -- Two spaces
                                   'Toggle_Two_Spaces' ||
                                   \1'Toggle put 2 spaces after periods etc.',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_mailindentedisverbatim', i);
   buildmenuitem menuname, mid, i, 'Mail: indented is verbatim',                                         -- Mail: indented is verbatim
                                   'toggle_mail_indented_verb' ||
                                   \1'Toggle every indented line will not be reflowed',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_reflownext', i);
   buildmenuitem menuname, mid, i, 'Reflow next',                                                        -- Reflow next
                                   'Toggle_Reflow_Next' ||
                                   \1'Toggle move cursor to next par after reflow',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_joinafterwrap', i);
   buildmenuitem menuname, mid, i, 'Join after wrap',                                                    -- Join after wrap
                                   'Toggle_Join_After_Wrap' ||
                                   \1'Toggle join next line with wrapped part',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1; call SetAVar( 'mid_autorestore', i);
   buildmenuitem menuname, mid, i, 'Auto-restore settings',                                        -- Auto-restore settings  >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1; call SetAVar( 'mid_restorecursorpos', i);
   buildmenuitem menuname, mid, i, 'Restore cursor position',                                            -- Restore cursor position
                                   'toggle_restore_pos' ||
                                   \1'Toggle restore of cursor pos. from file''s last save',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_trackhistorylists', i);
   buildmenuitem menuname, mid, i, 'Track additional history lists',                                     -- Track additional history lists
                                   'Toggle_History' ||
                                   \1'Enable edit, load and save history',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_autosavelastring', i);
   buildmenuitem menuname, mid, i, 'Auto-save last ring',                                                -- Auto-save last ring
                                   'Toggle_Save_Ring' ||
                                   \1'Toggle save of ring on load and quit',
                                   MIS_TEXT, nodismiss
   i = i + 1; call SetAVar( 'mid_maxfilessavering', i); call SetAVar( 'mtxt_maxfilessavering', 'Max. [] files for save ring...')
   buildmenuitem menuname, mid, i, GetAVar('mtxt_maxfilessavering'),                                     -- Max. [] files for save ring...
                                   'RingMaxFiles' ||
                                   \1'Set limit of files to enable auto-save',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_autoloadlastring', i);
   buildmenuitem menuname, mid, i, 'Auto-load last ring',                                                -- Auto-load last ring
                                   'Toggle_Restore_Ring' ||
                                   \1'Toggle restore of ring if EPM is started without args',
                                   MIS_TEXT + MIS_ENDSUBMENU, nodismiss
   i = i + 1; call SetAVar( 'mid_selectdictionaries', i);
   buildmenuitem menuname, mid, i, 'Select dictionaries... $',                                       -- Select dictionaries...
                                   '',
                                   MIS_TEXT, MIA_DISABLED

   -- Auto-spellcheck

   i = i + 1; call SetAVar( 'mid_framecontrols', i);
   buildmenuitem menuname, mid, i, FRAME_CTRLS_MENU__MSG,                                          -- Frame controls   >
                                   FRAME_CTRLS_MENUP__MSG,
                                   MIS_TEXT + MIS_SUBMENU, mpfrom2short(HP_OPTIONS_FRAME, 0)
   i = i + 1; call SetAVar( 'mid_statusline', i);
   buildmenuitem menuname, mid, i, STATUS_LINE_MENU__MSG' (i)',                                          -- Status line (i)
                                   'toggleframe 1' ||
                                   STATUS_LINE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_STATUS, nodismiss)
   i = i + 1; call SetAVar( 'mid_messageline', i);
   buildmenuitem menuname, mid, i, MSG_LINE_MENU__MSG' (i)',                                             -- Message line (i)
                                   'toggleframe 2' ||
                                   MSG_LINE_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_MESSAGE, nodismiss)
   i = i + 1; call SetAVar( 'mid_scrollbars', i);
   buildmenuitem menuname, mid, i, SCROLL_BARS_MENU__MSG' (i)',                                          -- Scroll bars (i)
                                   'setscrolls' ||
                                   SCROLL_BARS_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_SCROLL, nodismiss)
   i = i + 1; call SetAVar( 'mid_rotatebuttons', i);
   buildmenuitem menuname, mid, i, ROTATEBUTTONS_MENU__MSG' (i)',                                        -- Rotate buttons (i)
                                   'toggleframe 4' ||
                                   ROTATEBUTTONS_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_ROTATE, nodismiss)
   i = i + 1; call SetAVar( 'mid_toolbar', i);
   buildmenuitem menuname, mid, i, TOGGLETOOLBAR_MENU__MSG' (i)',                                        -- Toolbar (i)
                                   'toggle_toolbar' ||
                                   TOGGLETOOLBAR_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_TOOLBAR_TOGGLE, nodismiss)
   i = i + 1; call SetAVar( 'mid_backgroundbitmap', i);
   buildmenuitem menuname, mid, i, TOGGLEBITMAP_MENU__MSG' (i)',                                         -- Background bitmap (i)
                                   'toggle_bitmap' ||
                                   TOGGLEBITMAP_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_BITMAP, nodismiss)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_infoattop', i);
   buildmenuitem menuname, mid, i, INFOATTOP_MENU__MSG' (i)',                                            -- Info at top (i)
                                   'toggleframe 32' ||
                                   INFOATTOP_MENUP__MSG,
                                   MIS_TEXT, mpfrom2short(HP_FRAME_EXTRAPOS, nodismiss)
   i = i + 1; call SetAVar( 'mid_prompting', i);
   buildmenuitem menuname, mid, i, PROMPTING_MENU__MSG' (i)',                                            -- Prompting (i)
                                   'toggleprompt' ||
                                   PROMPTING_MENUP__MSG,
                                   MIS_TEXT + MIS_ENDSUBMENU, mpfrom2short(HP_FRAME_PROMPT, nodismiss)
   i = i + 1; call SetAVar( 'mid_menubarsandcolors', i);
   buildmenuitem menuname, mid, i, 'Menu, bars and colors',                                        -- Menu, bars and colors   >
                                   '',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Select menu...',                                                     -- Select menu
                                   'ChangeMenu' ||
                                   \1'Open a listbox and change or refresh the menu',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_nodismiss', i);
   buildmenuitem menuname, mid, i, 'Nodismiss menus',                                                    -- Nodismiss menus
                                   'toggle_nodismiss' ||
                                   \1'Keep menu open after selecting menu items',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure titlebar...',                                              -- Configure titlebar...
                                   'ConfigFrame TITLE' ||
                                   \1'Change layout of titletext',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_showlongname', i);
   buildmenuitem menuname, mid, i, 'Show .LONGNAME (i)',                                                 -- Show .LONGNAME
                                   'toggle_longname' ||
                                   \1'Show .LONGNAME EA as filename in titlebar',
                                   MIS_TEXT, nodismiss
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure statusbar...',                                             -- Configure statusbar...
                                   'ConfigFrame STATUS' ||
                                   \1'Change layout of statusline',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure separator...',                                             -- Configure separator...
                                   'ConfigFrame SEP' ||
                                   \1'Change layout of separator for titletext and statusline',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Configure highlighting colors...',                                   -- Configure highlighting colors...
                                   'os2 epmchgpal.cmd' ||
                                   \1'Use OS/2 palette objects to specify highlighting colors',
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Save impermanent ~options (i)',                                 -- Save impermanent options (i)
                                   'saveoptions' ||
                                   SAVE_OPTS_MENUP__MSG,
                                   0, mpfrom2short(HP_OPTIONS_SAVE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_macros', i)
   buildmenuitem menuname, mid, i, 'Macros',                                                       -- Macros   >
                                   ''\1'Compile EPM macro files',
                                   MIS_TEXT + MIS_SUBMENU, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Recompile EPM.E...',                                                 -- Recompile EPM.E...
                                   'StartRecompile' ||
                                   \1'Compile main macro file and restart EPM',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Compile current .E file',                                            -- Compile current .E file
                                   'etpm =' ||
                                   \1'Compile current macro file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Relink current .E file',                                             -- Relink current .E file
                                   'relink' ||
                                   \1'Compile current macro file and unlink/link if linked before',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Compile all',                                                        -- Compile all
                                   'CompileAll' ||
                                   \1'Compile all and Restart EPM',
                                   MIS_TEXT, MIA_DISABLED
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1; call SetAVar( 'mid_editprofile', i)
   buildmenuitem menuname, mid, i, 'Edit PROFILE.ERX',                                                   -- Edit PROFILE.ERX
                                   'e %NEPMD_ROOTDIR%\myepm\bin\profile.erx' ||
                                   \1'Edit or create REXX configuration file',
                                   MIS_TEXT, 0
   i = i + 1; call SetAVar( 'mid_activateprofile', i);
   buildmenuitem menuname, mid, i, 'Activate PROFILE.ERX (i)',                                           -- Activate PROFILE.ERX
                                   'toggle_profile' ||
                                   \1'Activate REXX configuration file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Edit MYCNF.E',                                                       -- Edit MYCNF.E
                                   'e %NEPMD_ROOTDIR%\myepm\macros\mycnf.e' ||
                                   \1'Edit or create E configuration file',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Edit MYSTUFF.E',                                                     -- Edit MYSTUFF.E
                                   'e %NEPMD_ROOTDIR%\myepm\macros\mystuff.e' ||
                                   \1'Edit or create E additions',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                                   --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open NETLABS\MACROS\*.E',
                                   'o %NEPMD_ROOTDIR%\netlabs\macros\*.e' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open MYEPM\MACROS\*.E',
                                   'o %NEPMD_ROOTDIR%\myepm\macros\*.e' ||
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
                                   'mc /rx open %NEPMD_ROOTDIR%\myepm\macros /rx open %NEPMD_ROOTDIR%\netlabs\macros' ||
                                   \1,
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open compiled macro dirs',
                                   'mc /rx open %NEPMD_ROOTDIR%\myepm\ex /rx open %NEPMD_ROOTDIR%\myepm\autolink' ||
                                   \1,
                                   MIS_TEXT, 0
*/
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open EPM.INI',
                                   'rx open ?:\os2\epm.ini' ||
                                   \1,
                                   MIS_TEXT, 0 -- <-------- Todo: get EPM.INI from OS2.INI
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Open NEPMD.INI',
                                   'rx open %NEPMD_ROOTDIR%\myepm\bin\nepmd.ini' ||
                                   \1,
                                   MIS_TEXT + MIS_ENDSUBMENU, 0
   m = mid'00'
   --sayerror 'Options menu: last item # = 'i', max = 'mid'99.'
   if (i - m) > 99 then
      messageNwait('Error: menuid 'mid' ran out of unique menu item ids. You used 'mid'01 to 'i' out of 'mid'99. Change your menu definition!')
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
   buildmenuitem menuname, mid, i, COMMANDLINE_MENU__MSG\9 || CTRL_KEY__MSG'+I',                   -- Command dialog...
                                   'commandline' ||
                                   COMMANDLINE_MENUP__MSG,
                                   0, mpfrom2short(HP_COMMAND_CMD, 0)
   -- 65535
   buildmenuitem menuname, mid, 65535, HALT_COMMAND_MENU__MSG,                                     -- Halt command
                                   '',
                                   0, mpfrom2short(HP_COMMAND_HALT, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, CREATE_SHELL_MENU__MSG,                                         -- Create command shell
                                   'shell' ||
                                   CREATE_SHELL_MENUP__MSG,
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
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~OS/2 window',                                                 -- OS/2 window
                                   'start /f cmd /k' ||
                                   \1'Open an OS/2 window with NEPMD''s environment',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, \0,                                                             --------------------
                                   '',
                                   MIS_SEPARATOR, 0
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
   buildmenuitem menuname, mid, i, 'Execute current ~line'\9 || ALT_KEY__MSG'+= | 'ALT_KEY__MSG'+0',   -- Execute current line
                                   'dokey a_0' ||
                                   \1'Execute line under cursor',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, 'Commanline current ~line'\9 || CTRL_KEY__MSG'+L',              -- Execute current line
                                   'dokey c_l' ||
                                   \1'Open line under cursor in commandline window',
                                   MIS_TEXT, 0
   i = i + 1;
   buildmenuitem menuname, mid, i, '~Run current file',                                            -- Run current file
                                   'rx run' ||
                                   \1'Execute current file according to what is def''d in RUN.ERX',
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
   i = i + 1;
   buildmenuitem menuname, mid, i, HELP_PROD_MENU__MSG,
                                   'IBMmsg' ||                                                     -- Product information
                                   HELP_PROD_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_PROD, 0)
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
                                   'view epmusers' ||
                                   VIEW_USERS_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, VIEW_IN_USERS_MENU__MSG,                                              -- Current word
                                   'viewword epmusers' ||
                                   VIEW_IN_USERS_MENUP__MSG,
                                   0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
   i = i + 1;
   buildmenuitem menuname, mid, i, VIEW_USERS_SUMMARY_MENU__MSG,                                         -- Summary
                                   'view epmusers Summary' ||
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
                                   'view epmtech' ||
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
   buildmenuitem menuname, mid, i, 'View NEPMD ~Programming Guide',                                -- View NEPMD Programming Guide   >
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
defc add_cascade_menus
   -- Better use the optional executed-as-default submenu id here,
   -- to have that submenu item checked automatically.
   -- Otherwise the 1st submenu item is executed, but MIA_CHECKED
   -- is missing.
   'cascade_menu' GetAVar('mid_openfolder') GetAVar('mid_openfolder_defaultview')          -- Open folder
compile if SUPPORT_USERS_GUIDE
   'cascade_menu' GetAVar('mid_viewusersguide') GetAVar('mid_usersguide')                  -- Help -> View User's Guide
compile endif
compile if SUPPORT_TECHREF
   'cascade_menu' GetAVar('mid_viewtechnicalreference') GetAVar('mid_technicalreference')  -- Help -> View Technical Reference
compile endif
   'cascade_menu' GetAVar('mid_viewnepmdusersguide') GetAVar('mid_nepmdusersguide')              -- Help -> NEPMD User Guide
   'cascade_menu' GetAVar('mid_viewnepmdprogrammingguide') GetAVar('mid_nepmdprogrammingguide')  -- Help -> NEPMD Programming Guide
   -- CUSTEPM package
compile if defined(CUSTEPM_DEFAULT_SCREEN)
   'cascade_menu' 3700 (CUSTEPM_DEFAULT_SCREEN + 3700)
compile elseif defined(HAVE_CUSTEPM)
   'cascade_menu' 3700
compile endif

; ---------------------------------------------------------------------------------------
; The following is individual commands on 5.51+; all part of ProcessMenuInit cmd on earlier versions.
; ---------------------------------------------------------------------------------------
; The menuinit_<mid_name> is called by defc ProcessMenuInit, when the menu id <mid_name>
; is selected. The defc must exist and must be added to the 'definedmenuinits' array var,
; see the SetAVar('definedmenuinits', <list of names>) definition at the top.

--------------------------------------------- Menu id 2 -- File -------------------------
defc menuinit_file
   SetMenuAttribute( GetAVar('mid_importfile'),  MIA_DISABLED, .readonly = 0)
   SetMenuAttribute( GetAVar('mid_save'),        MIA_DISABLED, .readonly = 0)
   SetMenuAttribute( GetAVar('mid_saveandquit'), MIA_DISABLED, .readonly = 0)

--------------------------------------------- Menu id x -- File properties --------------
defc menuinit_fileproperties
   universal cua_marking_switch
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
   SetMenuAttribute( GetAVar('mid_locked'),              MIA_CHECKED, not .lockhandle)
   SetMenuAttribute( GetAVar('mid_advancedmarking'),     MIA_CHECKED, cua_marking_switch)
   SetMenuAttribute( GetAVar('mid_streammode'),          MIA_CHECKED, not stream_mode)
   SetMenuAttribute( GetAVar('mid_syntaxexpansion'),     MIA_CHECKED, not expand_on)
   SetMenuAttribute( GetAVar('mid_keywordhighlighting'), MIA_CHECKED, not GetHighlight())
   SetMenuAttribute( GetAVar('mid_tabkey'),              MIA_CHECKED, not tab_key)
   SetMenuAttribute( GetAVar('mid_matchtab'),            MIA_CHECKED, not matchtab_on)

   SetMenuAttribute( GetAVar('mid_readonly'),            MIA_DISABLED, Exist(.filename))
   SetMenuAttribute( GetAVar('mid_locked'),              MIA_DISABLED, Exist(.filename))
   SetMenuAttribute( GetAVar('mid_wpsproperties'),       MIA_DISABLED, Exist(.filename))

   new = NepmdGetMode()
   parse value GetAVar('mtxt_mode') with next'['x']'rest
   SetMenuText( GetAVar('mid_mode'), next'['new']'rest)
   new = .tabs
   parse value GetAVar('mtxt_tabs') with next'['x']'rest
   SetMenuText( GetAVar('mid_tabs'), next'['new']'rest)
   new = .margins
   parse value GetAVar('mtxt_margins') with next'['x']'rest
   SetMenuText( GetAVar('mid_margins'), next'['new']'rest)

--------------------------------------------- Menu id 8 -- Edit -------------------------
defc menuinit_edit
   universal DMbuf_handle
   universal CUA_marking_switch
   SetMenuAttribute( GetAVar('mid_recovermarkdelete'), MIA_DISABLED, DMbuf_handle)
   SetMenuAttribute( GetAVar('mid_undoline'),    MIA_DISABLED, isadirtyline())
   undoaction 1, presentstate         -- Do to fix range, not for value.
   undoaction 6, staterange           -- query range
   parse value staterange with oldeststate neweststate .
   SetMenuAttribute( GetAVar('mid_undo'),        MIA_DISABLED, oldeststate <> neweststate )  -- Set to 1 if different
   paste = clipcheck(format) & (format = 1024) & not (browse() | .readonly)
   SetMenuAttribute( GetAVar('mid_paste'),       MIA_DISABLED, paste)
   SetMenuAttribute( GetAVar('mid_pastelines'),  MIA_DISABLED, paste)
   SetMenuAttribute( GetAVar('mid_pasteblock'),  MIA_DISABLED, paste)
   on = marktype() <> ''
   buf_flag = 0
   if not on then                                     -- Only check buffer if no mark
      bufhndl = buffer( OPENBUF, EPMSHAREDBUFFER)
      if bufhndl then                                 -- If the buffer exists, check the
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

--------------------------------------------- Menu id 5 -- View -------------------------
defc menuinit_view
   SetMenuAttribute( GetAVar('mid_softwrap'), MIA_CHECKED, GetWrapped() = 0)
   SetMenuAttribute( GetAVar('mid_nextview'), MIA_DISABLED, .currentview_of_file <> .nextview_of_file)
   SetMenuAttribute( GetAVar('mid_listring'), MIA_DISABLED, filesinring() > 1)

--------------------------------------------- Menu id 7 -- Tools -----------------------
defc menuinit_tools
   if marktype() <> '' then
      SetMenuText( GetAVar('mid_reflowpartomargins'), 'Mark to margins'\9 || ALT_KEY__MSG'+P')
   else
      SetMenuText( GetAVar('mid_reflowpartomargins'), 'Par to margins'\9 || ALT_KEY__MSG'+P')
   endif

--------------------------------------------- Menu id x -- Record keys -----------------
defc menuinit_recordkeys
   recordmode = windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),
                               5393,
                               0,
                               0)
   if recordmode then
      SetMenuText( GetAVar('mid_startrecording'), 'End recording'\9 || CTRL_KEY__MSG'+R')
      SetMenuText( GetAVar('mid_playback'),       'End recording & playback'\9 || CTRL_KEY__MSG'+T')
   else
      SetMenuText( GetAVar('mid_startrecording'), 'Start recording'\9 || CTRL_KEY__MSG'+R')
      SetMenuText( GetAVar('mid_playback'),       'Playback'\9 || CTRL_KEY__MSG'+T')
   endif

--------------------------------------------- Menu id 3 -- Search -----------------------
defc menuinit_search
   universal lastchangeargs
   getsearch strng
   parse value strng with . c .       -- blank, 'c', or 'l'
   SetMenuAttribute( GetAVar('mid_findnext'),         MIA_DISABLED, c <> '')               -- Find next OK if not blank
   SetMenuAttribute( GetAVar('mid_changenext'),       MIA_DISABLED, lastchangeargs <> '')  -- Change next only if 'c'
   SetMenuAttribute( GetAVar('mid_globalfindnext'),   MIA_DISABLED, c <> '')               -- Global find next OK if not blank
   SetMenuAttribute( GetAVar('mid_globalchangenext'), MIA_DISABLED, lastchangeargs <> '')  -- Global change next only if 'c'
   SetMenuAttribute( GetAVar('mid_toggledirection'),  MIA_DISABLED, c <> '')               -- Toggle direction OK if not blank
   on = (marktype() <> '')
   SetMenuAttribute( GetAVar('mid_findmark'),         MIA_DISABLED, on)

--------------------------------------------- Item id 309 -- Mark -----------------------
defc menuinit_mark
   universal mark_stack
   on = (marktype() <> '')
   SetMenuAttribute( GetAVar('mid_gotomark'),      MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_savemark'),      MIA_DISABLED, on)
   SetMenuAttribute( GetAVar('mid_restoremark'),   MIA_DISABLED, mark_stack <> '')
   SetMenuAttribute( GetAVar('mid_swapmark'),      MIA_DISABLED, on & mark_stack <> '')

--------------------------------------------- Item id 314 -- Cursor ---------------------
defc menuinit_cursor
   universal position_stack
   SetMenuAttribute( GetAVar('mid_restorecursor'), MIA_DISABLED, position_stack <> '')
   SetMenuAttribute( GetAVar('mid_swapcursor'),    MIA_DISABLED, position_stack <> '')

--------------------------------------------- Item id 319 -- Bookmarks ------------------
defc menuinit_bookmarks
   universal EPM_utility_array_ID
   rc = get_array_value( EPM_utility_array_ID, 'bmi.0', bmcount)  -- Index says how many bookmarks there are
   SetMenuAttribute( GetAVar('mid_bookmarks_set'),      MIA_DISABLED, not (browse() | .readonly))  -- Set
   SetMenuAttribute( GetAVar('mid_bookmarks_list'),     MIA_DISABLED, bmcount > 0)   -- List
   SetMenuAttribute( GetAVar('mid_bookmarks_next'),     MIA_DISABLED, bmcount > 0)   -- Next
   SetMenuAttribute( GetAVar('mid_bookmarks_previous'), MIA_DISABLED, bmcount > 0)   -- Previous

--------------------------------------------- Menu id x -- Options ----------------------
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

--------------------------------------------- Menu id x -- Options / Main settings ------
defc menuinit_mainsettings
   universal ring_enabled
   universal nepmd_hini
   universal default_stream_mode
   universal default_cua_marking_switch

   SetMenuAttribute( GetAVar('mid_defaultadvancedmarking'),     MIA_CHECKED, default_cua_marking_switch)

   SetMenuAttribute( GetAVar('mid_defaultstreammode'),          MIA_CHECKED, not default_stream_mode)
   KeyPath = '\NEPMD\User\SyntaxExpansion'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_defaultsyntaxexpansion'),     MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\KeywordHighlighting'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_defaultkeywordhighlighting'), MIA_CHECKED, not on)
   SetMenuAttribute( GetAVar('mid_ringenabled'),                MIA_CHECKED, not ring_enabled)

--------------------------------------------- Menu id x -- Options / Margins and tabs settings
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

--------------------------------------------- Menu id x -- Options / Accelerator key settings
defc menuinit_accelsettings
   universal cua_menu_accel
   universal nepmd_hini
   SetMenuAttribute( GetAVar('mid_menuaccelerators'),     MIA_CHECKED, not cua_menu_accel)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_blockleftaltkey'),      MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_blockrightaltkey'),     MIA_CHECKED, not on)

--------------------------------------------- Menu id x -- Options / Mouse and cursor settings
defc menuinit_mouseandcursor
   universal nepmd_hini
   universal cua_marking_switch

   KeyPath = '\NEPMD\User\Mouse\Mark\MouseStyle'
   style = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if style <> 1 | cua_marking_switch then
      style = 2
   endif
   new = word( 'block char', style)
   parse value GetAVar('mtxt_mousestyle') with next'['x']'rest
   SetMenuText( GetAVar('mid_mousestyle'), next'['new']'rest)
   SetMenuAttribute( GetAVar('mid_mousestyle'),         MIA_DISABLED, not cua_marking_switch)

   KeyPath = '\NEPMD\User\Mouse\Mark\DefaultPaste'
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

   KeyPath = '\NEPMD\User\Mouse\Mark\DragAlwaysMarks'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'),    MIA_CHECKED, not (on | cua_marking_switch))
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'),    MIA_DISABLED, not cua_marking_switch)

   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_keepcursoronscreen'), MIA_CHECKED, not on)

   KeyPath = '\NEPMD\User\Scroll\AfterLocate'
   new = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value GetAVar('mtxt_scrollafterlocate') with next'['x']'rest
   SetMenuText( GetAVar('mid_scrollafterlocate'), next'['new']'rest)

--------------------------------------------- Menu id x -- Options / Readonly and lock settings
defc menuinit_readonlyandlock
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Readonly'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_respectreadonly'), MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Lock\OnModify'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_lockonmodify'),    MIA_CHECKED, not on)

 --------------------------------------------- Menu id x -- Options / Reflow settings ----
defc menuinit_reflowsettings
   universal twospaces
   universal join_after_wrap
   universal nepmd_hini
   SetMenuAttribute( GetAVar('mid_twospaces'),              MIA_CHECKED, not twospaces)
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedIsVerbatim'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_mailindentedisverbatim'), MIA_CHECKED, not on)
   KeyPath = '\NEPMD\User\Reflow\Next'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   SetMenuAttribute( GetAVar('mid_reflownext'),             MIA_CHECKED, not on)
   SetMenuAttribute( GetAVar('mid_joinafterwrap'),          MIA_CHECKED, not join_after_wrap)

--------------------------------------------- Menu id x -- Options / Restore ring settings
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

--------------------------------------------- Menu id x -- Options / Frame controls -----
defc menuinit_framecontrols
   universal bitmap_present
   universal ring_enabled
   universal menu_prompt
   SetMenuAttribute( GetAVar('mid_statusline'),       MIA_CHECKED, not queryframecontrol(1))
   SetMenuAttribute( GetAVar('mid_messageline'),      MIA_CHECKED, not queryframecontrol(2))
   SetMenuAttribute( GetAVar('mid_scrollbars'),       MIA_CHECKED, not queryframecontrol(16))
   if ring_enabled then
   SetMenuAttribute( GetAVar('mid_rotatebuttons'),    MIA_CHECKED, not queryframecontrol(4))
   else
   SetMenuAttribute( GetAVar('mid_rotatebuttons'),    MIA_DISABLED, 0)  -- Grey out Rotate Buttons if ring not enabled
   endif
   SetMenuAttribute( GetAVar('mid_toolbar'),          MIA_CHECKED, not queryframecontrol(EFRAMEF_TOOLBAR))
   SetMenuAttribute( GetAVar('mid_backgroundbitmap'), MIA_CHECKED, not bitmap_present)
   SetMenuAttribute( GetAVar('mid_infoattop'),        MIA_CHECKED, not queryframecontrol(32))
   SetMenuAttribute( GetAVar('mid_prompting'),        MIA_CHECKED, not menu_prompt)

--------------------------------------------- Menu id x -- Options / Edit options -------
defc menuinit_editoptions
   'seteditoptions MENUINIT'

--------------------------------------------- Menu id x -- Options / Save options -------
defc menuinit_saveoptions
   'setsaveoptions MENUINIT'

--------------------------------------------- Menu id x -- Options / Search options -----
defc menuinit_searchoptions
   'setsearchoptions MENUINIT'

--------------------------------------------- Menu id x -- Options / Menu bars and colors
defc menuinit_menubarsandcolors
   universal show_longnames
   universal nodismiss
   SetMenuAttribute( GetAVar('mid_showlongname'), MIA_CHECKED, not show_longnames)
   SetMenuAttribute( GetAVar('mid_nodismiss')   , MIA_CHECKED, not (nodismiss = 32))

--------------------------------------------- Menu id 0 -- Run --------------------------
defc menuinit_run
   is_shell = leftstr(.filename, 15) = ".command_shell_"
   SetMenuAttribute( GetAVar('mid_writetoshell'),     MIA_DISABLED, is_shell)
   SetMenuAttribute( GetAVar('mid_sendbreaktoshell'), MIA_DISABLED, is_shell)

--------------------------------------------- Menu id x -- Run / Macros -----------------
defc menuinit_macros
   universal rexx_profile
   SetMenuAttribute( GetAVar('mid_activateprofile'),  MIA_CHECKED, not rexx_profile)
   file = NepmdResolveEnvVars('%NEPMD_ROOTDIR%\myepm\bin\profile.erx')
   file_exist = exist(file)
   SetMenuAttribute( GetAVar('mid_activateprofile'),  MIA_DISABLED, file_exist)
   if file_exist then
      SetMenuText( GetAVar('mid_editprofile'), 'Edit PROFILE.ERX')
   else
      SetMenuText( GetAVar('mid_editprofile'), 'Create PROFILE.ERX')
   endif

--------------------------------------------- Menu id x -- Tree commands ----------------
defc menuinit_treecommands
   is_tree = leftstr(.filename, 5) = ".tree"
   SetMenuAttribute( GetAVar('mid_treesort'), MIA_DISABLED, is_tree)
   SetMenuAttribute( GetAVar('mid_treeit')  , MIA_DISABLED, is_tree)

; The above is all part of ProcessMenuInit cmd on old versions.  -----------------

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

; ---------------------------------------------------------------------------
/*
   EFRAMEF_STATUSWND       = 1    -- EPMINFO_EDITSTATUSAREA = 7
   EFRAMEF_MESSAGEWND      = 2    -- EPMINFO_EDITORMSGAREA = 8
   EFRAMEF_RINGBUTTONS     = 4    -- EPMINFO_RINGICONS = 20
   EFRAMEF_VSCROLLBAR      = 8    -- EPMINFO_EDITORVSCROLL = 9
   EFRAMEF_HSCROLLBAR      = 16   -- EPMINFO_EDITORHSCROLL = 10
   EFRAMEF_INFOONTOP       = 32   -- EPMINFO_EXTRAWINDOWPOS = 23
   EFRAMEF_FILEWND         = 64   -- EPMINFO_FILEICON = 22
   EFRAMEF_DMTBWND         = 128
   EFRAMEF_TASKLISTENTRY   = 256
   EFRAMEF_TOOLBAR         = 2048
   drop style                8192
*/
defc toggleframe
   universal menu_prompt
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
         -- Set MIA_CHECKED attributes for the case MIA_NODISMISS attribute is on
         mid = GetAVar('mid_prompting')
         -- Check if mid exists, because 'initconfig' sets some controls before the menu
         if mid > '' then
            SetMenuAttribute( mid, MIA_CHECKED, 1)
         endif
      endif
   endif

   -- Set MIA_CHECKED attributes for the case MIA_NODISMISS attribute is on
   ControlIdList = ''   ||
      1 'statusline'    || ' ' ||
      2 'messageline'   || ' ' ||
      4 'rotatebuttons' || ' ' ||
     16 'scrollbars'    || ' ' ||
     32 'infoattop'     || ' ' ||
   2048 'toolbar'

   p = wordpos( controlid, ControlIdList)
   if p then
      midtext = word( ControlIdList, p + 1)
      mid = GetAVar('mid_'midtext)
      -- Check if mid exists, because 'initconfig' sets some controls before the menu
      if mid > '' then
         SetMenuAttribute( mid, MIA_CHECKED, not fon)
      endif
   endif

; ---------------------------------------------------------------------------
defproc queryframecontrol(controlid)
   return windowmessage( 1, getpminfo(EPMINFO_EDITFRAME),   -- Send message to edit client
                         5907,               -- EFRAMEM_TOGGLECONTROL
                         controlid,
                         1)

; ---------------------------------------------------------------------------
defc toggle_profile
   universal rexx_profile
   universal menuloaded
   rexx_profile = not rexx_profile
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_activateprofile'), MIA_CHECKED, not rexx_profile)
   endif

; ---------------------------------------------------------------------------
defc toggleprompt, toggle_prompt
   universal menu_prompt
   universal menuloaded
   menu_prompt = not menu_prompt
   if menu_prompt then
      'toggleframe 32 0'      -- Force Extra window to bottom.
   endif
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   mid = GetAVar('mid_prompting')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( mid, MIA_CHECKED, not menu_prompt)
   endif

; ---------------------------------------------------------------------------
defc toggle_toolbar
   universal toolbar_loaded
   --fon = queryframecontrol(EFRAMEF_TOOLBAR)  -- Query now, since toggling is asynch.
   'toggleframe' EFRAMEF_TOOLBAR
   if not toolbar_loaded then
      'default_toolbar'
   endif

; ---------------------------------------------------------------------------
defc setscrolls
   'toggleframe 8'
   'toggleframe 16'

; ---------------------------------------------------------------------------
defc toggle_bitmap
   universal bitmap_present, bm_filename
   universal menuloaded
   bitmap_present = not bitmap_present
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
                       5498 - (44*bitmap_present), 0, 0)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   mid = GetAVar('mid_backgroundbitmap')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( mid, MIA_CHECKED, not bitmap_present)
   endif

; ---------------------------------------------------------------------------
defc toggle_readonly
   on = GetReadonly()
   on = not on
   .readonly = on
   'readonly' on  -- update the file attribute
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_readonly'), MIA_CHECKED, not on)

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
defc toggle_highlight
/*
   -- Query keyword highlighting state (windowmessage returns 0 or 2)
   -- from defc qparse (commented out) in STDCTRL.E:
   ret = windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                        5505,          -- EPM_EDIT_KW_QUERYPARSE
                        0,
                        0)
   on = (ret <> 0)
*/
   on = GetHighlight()
   on = not on
   'SetHighlight' on
   --call NepmdActivateHighlight(on)
   if not wordpos( 'NOMENU', upcase(arg(1))) then
      -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
      SetMenuAttribute( GetAVar('mid_keywordhighlighting'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_highlight
   universal nepmd_hini
   KeyPath = '\NEPMD\User\KeywordHighlighting'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_defaultkeywordhighlighting'), MIA_CHECKED, not on)
   -- Change highlight for every file with default setting
   'ring refresh_default_highlight' on

defc refresh_default_highlight
   on = arg(1)
   getfileid fid
   next = GetAVar('highlight.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if highlight was not changed by any modeexecute
      call NepmdActivateHighlight(on)
   endif

; ---------------------------------------------------------------------------
defc toggle_expand
   universal menuloaded
   universal expand_on
   -- Change expand for current file
   expand_on = not expand_on
   'SetExpand' expand_on  -- refresh file setting
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
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
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_defaultsyntaxexpansion'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_mousestyle
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mouse\Mark\MouseStyle'
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
   KeyPath = '\NEPMD\User\Mouse\Mark\DefaultPaste'
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
defc toggle_drag_always_marks
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mouse\Mark\DragAlwaysMarks'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   SetMenuAttribute( GetAVar('mid_dragalwaysmarks'),      MIA_CHECKED, not on)
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
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_tabkey'), MIA_CHECKED, not tab_key)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_tabkey
   universal default_tab_key
   universal tab_key
   universal menuloaded
   default_tab_key = not default_tab_key
   -- Change tab_key for current file if has default tabkey setting
   getfileid fid
   next = GetAVar('tabkey.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if tabkey was not changed by any modeexecute
      tab_key = default_tab_key
      'RefreshInfoLine TABKEY'
   endif
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_defaulttabkey'), MIA_CHECKED, not default_tab_key)
   endif
/*
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Keys\Tab\TabKey'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
*/
/*
   universal app_hini
   universal appname
   optflags = queryprofile( app_hini, 'EPM', INI_OPTFLAGS)
   if optflags = '' then
      return
   endif
   bit = 14
   on = subword( optflags, bit, 1)
   on = not on
   call setprofile( app_hini, appname, INI_OPTFLAGS,
                    overlay( on, optflags, 2*bit - 1))
                    --subword( optflags, 1, 13) on subword( optflags, 15))
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_defaulttabkey'), MIA_CHECKED, not on)
*/
; ---------------------------------------------------------------------------
defc toggle_matchtab
   universal menuloaded
   universal nepmd_hini
   universal matchtab_on
   -- Change matchtab for current file
   matchtab_on = not matchtab_on
   'SetMatchTab' matchtab_on  -- refresh file settings
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
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
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_defaultmatchtab'), MIA_CHECKED, not on)
   endif

; ---------------------------------------------------------------------------
defc toggle_tabglyph
   universal nepmd_hini
   curstate = tabglyph()
   newstate = not curstate
   call tabglyph(newstate)
   KeyPath = '\NEPMD\User\Keys\Tab\TabGlyph'
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, newstate)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_showtabs'), MIA_CHECKED, not newstate)

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
defc toggle_mail_indented_verb
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Reflow\Mail\IndentedIsVerbatim'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   on = not on
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, on)
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_mailindentedisverbatim'), MIA_CHECKED, not on)

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

; ---------------------------------------------------------------------------
defc toggle_default_cua_mark
   universal default_cua_marking_switch
   universal cua_marking_switch
   universal menuloaded
   universal defaultmenu
   default_cua_marking_switch = not default_cua_marking_switch
   -- Change stream_mode for current file if it's default
   getfileid fid
   next = GetAVar('cuamarking.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if streammode was not changed by any modeexecute
      cua_marking_switch = default_cua_marking_switch
      'togglecontrol 25' cua_marking_switch
      call MH_set_mouse()
/*
      -- Update Edit menu (better disable menu items)
      deletemenu defaultmenu, GetAVar('mid_edit'), 0, 1           -- Delete the edit menu
      call add_edit_menu(defaultmenu)
      -- maybe_show_menu() does a refresh and closes the menu, so that the
      -- MIA_NODISMISS attribute has no effect anymore.
      call maybe_show_menu()
*/
      'RefreshInfoLine MARKINGMODE'
   endif
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_defaultadvancedmarking'), MIA_CHECKED, default_cua_marking_switch)
   endif

; ---------------------------------------------------------------------------
defc toggle_cua_mark, cua_mark_toggle
   universal cua_marking_switch
   universal defaultmenu
   universal menuloaded
   cua_marking_switch = not cua_marking_switch
   'SetCuaMarking' cua_marking_switch
;   'togglecontrol 25' cua_marking_switch
;   call MH_set_mouse()
/*
   -- Update Edit menu (better disable menu items)
   deletemenu defaultmenu, GetAVar('mid_edit'), 0, 1           -- Delete the edit menu
   call add_edit_menu(defaultmenu)
   -- maybe_show_menu() does a refresh and closes the menu, so that the
   -- MIA_NODISMISS attribute has no effect anymore.
   call maybe_show_menu()
*/
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   --mid = GetAVar('mid_advancedmarking')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_advancedmarking'), MIA_CHECKED, CUA_marking_switch)
   endif

; ---------------------------------------------------------------------------
defc toggle_stream, stream_toggle
   universal stream_mode
   universal menuloaded
   stream_mode = not stream_mode
;   'togglecontrol 24' stream_mode
;   'RefreshInfoLine STREAMMODE'
   'SetStreamMode' stream_mode
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   --mid = GetAVar('mid_streammode')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_streammode'), MIA_CHECKED, not stream_mode)
   endif

; ---------------------------------------------------------------------------
defc toggle_default_stream
   universal default_stream_mode
   universal stream_mode
   universal menuloaded
   default_stream_mode = not default_stream_mode
   -- Change stream_mode for current file if it's default
   getfileid fid
   next = GetAVar('streammode.'fid)  -- query file setting
   if next = 'DEFAULT' | next = '' then  -- unset if streammode was not changed by any modeexecute
      stream_mode = default_stream_mode
      'togglecontrol 24' stream_mode
      'RefreshInfoLine STREAMMODE'
   endif
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   if menuloaded then
      SetMenuAttribute( GetAVar('mid_defaultstreammode'), MIA_CHECKED, not default_stream_mode)
   endif

; ---------------------------------------------------------------------------
defc toggle_ring, ring_toggle
   universal ring_enabled
   universal activemenu, defaultmenu
   universal menuloaded
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
/*
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   mid = GetAVar('mid_ringenabled')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( mid, MIA_CHECKED, not ring_enabled)
   endif
   mid = GetAVar('mid_rotatebuttons')
   --if mid > '' then
   if menuloaded then
      SetMenuAttribute( mid, MIA_DISABLED, ring_enabled)
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
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_menuaccelerators'), MIA_CHECKED, not cua_menu_accel)

; ---------------------------------------------------------------------------
defc toggle_longname
   universal show_longnames
   show_longnames = not show_longnames
   -- Set MIA_CHECKED attribute for the case MIA_NODISMISS attribute is on
   SetMenuAttribute( GetAVar('mid_showlongname'), MIA_CHECKED, not show_longnames)
   'RefreshInfoLine FILE'

; ---------------------------------------------------------------------------
; Change edit options and set menu attributes.
; Some options exclude each other, see ExcludeList. The last option wins.
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
      opt = '/b /t /u 'default_edit_options  -- internal default + default_search_options
   endif
   opt = lowcase(opt)
   -- Remove multiple and excluding options and spaces
   ExcludeList = '/b/c/d /t/nt /l/u'    -- for every word in this list: every expression excludes each other
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
      opt = '/a /ns /ne /nt 'default_save_options  -- internal default + default_search_options
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
defproc build_menu_accelerators(activeaccel)
   universal cua_menu_accel
;   universal stack_cmds
   universal nepmd_hini

   KeyPath = "\NEPMD\User\Mouse\Mark\DefaultPaste"
   DefaultPaste = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DefaultPaste = 'C' then
      AlternatePaste = 'L'
   else
      AlternatePaste = 'C'
   endif
   if DefaultPaste = 'L' then    -- arg for defc paste maybe 'C', 'B' or ''
      DefaultPaste = ''
   endif
   if AlternatePaste = 'L' then  -- arg for defc paste maybe 'C', 'B' or ''
      AlternatePaste = ''
   endif

                        -- Build keys on File menu
   buildacceltable activeaccel, 'dokey F8',  AF_VIRTUALKEY,                VK_F8, 1101  -- F8
   buildacceltable activeaccel, 'dokey c+O', AF_CHAR+AF_CONTROL,              79, 1102  -- c+O
   buildacceltable activeaccel, 'dokey c+O', AF_CHAR+AF_CONTROL,             111, 1103  -- c+o
   buildacceltable activeaccel, 'dokey F7',  AF_VIRTUALKEY,                VK_F7, 1104  -- F7
   buildacceltable activeaccel, 'dokey F2',  AF_VIRTUALKEY,                VK_F2, 1105  -- F2
   buildacceltable activeaccel, 'dokey F3',  AF_VIRTUALKEY,                VK_F3, 1106  -- F3
   buildacceltable activeaccel, 'dokey F4',  AF_VIRTUALKEY,                VK_F4, 1107  -- F4

                        -- Build keys on Edit menu  ('C' & 'O' appear under Action bar keys for English)
compile if FILE_ACCEL__L <> 'C' & EDIT_ACCEL__L <> 'C' & SEARCH_ACCEL__L <> 'C' & OPTIONS_ACCEL__L <> 'C' & COMMAND_ACCEL__L <> 'C' & HELP_ACCEL__L <> 'C' & $maybe_ring_accel 'C' & $maybe_actions_accel 'C'
;   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  67, 1201  -- a+C
;   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  99, 1202  -- a+c
compile endif
compile if FILE_ACCEL__L <> 'M' & EDIT_ACCEL__L <> 'M' & SEARCH_ACCEL__L <> 'M' & OPTIONS_ACCEL__L <> 'M' & COMMAND_ACCEL__L <> 'M' & HELP_ACCEL__L <> 'M' & $maybe_ring_accel 'M' & $maybe_actions_accel 'M'
   buildacceltable activeaccel, 'dokey a+M', AF_CHAR+AF_ALT,                  77, 1203  -- a+M
   buildacceltable activeaccel, 'dokey a+M', AF_CHAR+AF_ALT,                 109, 1204  -- a+m
compile endif
compile if FILE_ACCEL__L <> 'O' & EDIT_ACCEL__L <> 'O' & SEARCH_ACCEL__L <> 'O' & OPTIONS_ACCEL__L <> 'O' & COMMAND_ACCEL__L <> 'O' & HELP_ACCEL__L <> 'O' & $maybe_ring_accel 'O' & $maybe_actions_accel 'O'
   buildacceltable activeaccel, 'dokey a+O', AF_CHAR+AF_ALT,                  79, 1205  -- a+O
   buildacceltable activeaccel, 'dokey a+O', AF_CHAR+AF_ALT,                 111, 1206  -- a+o
compile endif
compile if FILE_ACCEL__L <> 'A' & EDIT_ACCEL__L <> 'A' & SEARCH_ACCEL__L <> 'A' & OPTIONS_ACCEL__L <> 'A' & COMMAND_ACCEL__L <> 'A' & HELP_ACCEL__L <> 'A' & $maybe_ring_accel 'A' & $maybe_actions_accel 'A'
   buildacceltable activeaccel, 'dokey a+A', AF_CHAR+AF_ALT,                  65, 1207  -- a+A
   buildacceltable activeaccel, 'dokey a+A', AF_CHAR+AF_ALT,                  97, 1208  -- a+a
compile endif
compile if FILE_ACCEL__L <> 'U' & EDIT_ACCEL__L <> 'U' & SEARCH_ACCEL__L <> 'U' & OPTIONS_ACCEL__L <> 'U' & COMMAND_ACCEL__L <> 'U' & HELP_ACCEL__L <> 'U' & $maybe_ring_accel 'U' & $maybe_actions_accel 'U'
   buildacceltable activeaccel, 'dokey a+U', AF_CHAR+AF_ALT,                  85, 1209  -- a+U
   buildacceltable activeaccel, 'dokey a+U', AF_CHAR+AF_ALT,                 117, 1210  -- a+u
compile endif
compile if FILE_ACCEL__L <> 'D' & EDIT_ACCEL__L <> 'D' & SEARCH_ACCEL__L <> 'D' & OPTIONS_ACCEL__L <> 'D' & COMMAND_ACCEL__L <> 'D' & HELP_ACCEL__L <> 'D' & $maybe_ring_accel 'D' & $maybe_actions_accel 'D'
   buildacceltable activeaccel, 'dokey a+D', AF_CHAR+AF_ALT,                  68, 1211  -- a+D
   buildacceltable activeaccel, 'dokey a+D', AF_CHAR+AF_ALT,                 100, 1212  -- a+d
compile endif

   buildacceltable activeaccel, 'dokey a+V', AF_CHAR+AF_ALT,                  86, 1233  -- a+V
   buildacceltable activeaccel, 'dokey a+V', AF_CHAR+AF_ALT,                 118, 1234  -- a+v

   buildacceltable activeaccel, 'dokey a+R', AF_CHAR+AF_ALT,                  82, 1231  -- a+R
   buildacceltable activeaccel, 'dokey a+R', AF_CHAR+AF_ALT,                 114, 1232  -- a+r

   buildacceltable activeaccel, 'copy2clip', AF_VIRTUALKEY+AF_CONTROL, VK_INSERT, 1213  -- c+Insert
   buildacceltable activeaccel, 'cut',       AF_VIRTUALKEY+AF_SHIFT,   VK_DELETE, 1214  -- s+Delete
   buildacceltable activeaccel, 'paste' DefaultPaste, AF_VIRTUALKEY+AF_SHIFT,   VK_INSERT, 1215  -- s+Insert
   buildacceltable activeaccel, 'paste' AlternatePaste, AF_VIRTUALKEY+AF_SHIFT+AF_CONTROL,   VK_INSERT, 1221  -- c+s+Insert
   buildacceltable activeaccel, 'dokey F9',  AF_VIRTUALKEY,                VK_F9, 1216  -- F9
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,              89, 1217  -- c+Y
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,             121, 1218  -- c+y
   buildacceltable activeaccel, 'select_all',AF_CHAR+AF_CONTROL,              47, 1219  -- c+/
   buildacceltable activeaccel, 'DUPMARK U', AF_CHAR+AF_CONTROL,              92, 1220  -- c+\

;if stack_cmds then
   buildacceltable activeaccel, 'dokey c+down', AF_VIRTUALKEY+AF_CONTROL,   VK_DOWN, 1222  -- c+Down
   buildacceltable activeaccel, 'dokey c+Up',   AF_VIRTUALKEY+AF_CONTROL,     VK_UP, 1223  -- c+Up
;endif
   buildacceltable activeaccel, 'swappos',  AF_CHAR+AF_CONTROL,                     61, 1224  -- c+=
   buildacceltable activeaccel, 'pushmark', AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT, VK_DOWN, 1225  -- c+s+Down
   buildacceltable activeaccel, 'popmark',  AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT,   VK_UP, 1226  -- c+s+Up
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            61, 1227  -- c+s+=
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            43, 1228  -- c+s++

                        -- Build keys on Search menu
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,              83, 1301  -- c+S
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,             115, 1302  -- c+s
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,              70, 1303  -- c+F
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,             102, 1304  -- c+f
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              67, 1305  -- c+C
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              99, 1306  -- c+c
                        -- Build keys on Bookmark submenu
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              66, 1331  -- c+B
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              98, 1332  -- c+b
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,              77, 1333  -- c+M
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,             109, 1334  -- c+m
   buildacceltable activeaccel, 'nextbookmark',  AF_CHAR+AF_ALT,              47, 1335  -- a+/
   buildacceltable activeaccel, 'nextbookmark P',AF_CHAR+AF_ALT,              92, 1336  -- a+\
                        -- Build keys on Tags submenu
   buildacceltable activeaccel, 'dokey s+F6', AF_VIRTUALKEY+AF_SHIFT,      VK_F6, 1361  -- s+F6
   buildacceltable activeaccel, 'dokey s+F7', AF_VIRTUALKEY+AF_SHIFT,      VK_F7, 1362  -- s+F7
   buildacceltable activeaccel, 'dokey s+F8', AF_VIRTUALKEY+AF_SHIFT,      VK_F8, 1363  -- s+F8
   buildacceltable activeaccel, 'dokey s+F9', AF_VIRTUALKEY+AF_SHIFT,      VK_F9, 1364  -- s+F9

                        -- Build keys on Options menu
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,              71, 1401  -- c+G
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,             103, 1402  -- c+g

                        -- Build keys on Command menu
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,              73, 1501  -- c+I
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,             105, 1502  -- c+i

                        -- Block action bar accelerator keys (English)
   if not cua_menu_accel then
      buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A1   , 1001  -- a+F
      buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A2   , 1002  -- a+f
      buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A1   , 1003  -- a+E
      buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A2   , 1004  -- a+e
      buildacceltable activeaccel, 'dokey a+'SEARCH_ACCEL__L,  AF_CHAR+AF_ALT, SEARCH_ACCEL__A1 , 1005  -- a+S
      buildacceltable activeaccel, 'dokey a+'SEARCH_ACCEL__L,  AF_CHAR+AF_ALT, SEARCH_ACCEL__A2 , 1006  -- a+s
      buildacceltable activeaccel, 'dokey a+'OPTIONS_ACCEL__L, AF_CHAR+AF_ALT, OPTIONS_ACCEL__A1, 1007  -- a+O
      buildacceltable activeaccel, 'dokey a+'OPTIONS_ACCEL__L, AF_CHAR+AF_ALT, OPTIONS_ACCEL__A2, 1008  -- a+o
;      buildacceltable activeaccel, 'dokey a+'COMMAND_ACCEL__L, AF_CHAR+AF_ALT, COMMAND_ACCEL__A1, 1009  -- a+C
;      buildacceltable activeaccel, 'dokey a+'COMMAND_ACCEL__L, AF_CHAR+AF_ALT, COMMAND_ACCEL__A2, 1010  -- a+c
      buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A1   , 1011  -- a+H
      buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A2   , 1012  -- a+h

      buildacceltable activeaccel, 'dokey a+V', AF_CHAR+AF_ALT,                  86, 1233  -- a+V
      buildacceltable activeaccel, 'dokey a+V', AF_CHAR+AF_ALT,                 118, 1234  -- a+v

      buildacceltable activeaccel, 'dokey a+R', AF_CHAR+AF_ALT,                  82, 1231  -- a+R
      buildacceltable activeaccel, 'dokey a+R', AF_CHAR+AF_ALT,                 114, 1232  -- a+r

 compile if defined(ACTIONS_ACCEL__L)   -- For CUSTEPM support
      buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A1, 1017  -- a+A
      buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A2, 1018  -- a+a
 compile endif
   endif -- CUA_MENU_ACCEL

; ---------------------------------------------------------------------------
; Update the menu text for items affected by CUA_menu_Accel = 0|1.
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
      MenuText = MenuText\9 || ALT_KEY__MSG'+'Key
   endif
   SetMenuText( GetAVar(midname), MenuText)

   MenuText = DELETE_MARK_MENU__MSG
   Key      = ALT_KEY__MSG'+D'
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
   KeyPath = "\NEPMD\User\Mouse\Mark\DefaultPaste"
   DefaultPaste = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DefaultPaste = 'C' then
      AlternatePaste = 'L'
   else
      AlternatePaste = 'C'
   endif
   if DefaultPaste = 'L' then    -- arg for defc paste maybe 'C', 'B' or ''
      DefaultPaste = ''
   endif
   if AlternatePaste = 'L' then  -- arg for defc paste maybe 'C', 'B' or ''
      AlternatePaste = ''
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
   if DefaultPaste = '' then
      Key   = DefaultPasteKey
   elseif AlternatePaste = '' then
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


