/****************************** Module Header *******************************
*
* Module Name: fevshmnu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: fevshmnu.e,v 1.10 2004-11-30 21:05:47 aschn Exp $
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
; This is an example of providing an alternate to STDMENU.E.  The name of the
; alternate menu must be defined in MYCNF.E:  STD_MENU_NAME = 'fevshmnu.e'
; The alternate menu must provide the following commands, which are called
; from the other macro files:
;   LoadDefaultMenu - Called to build the default action bar.  Must set universals
;                     Activemenu and Defaultmenu.
;   Readd_help_menu - Called to readd the help menu, after someone deleted it to add their own menu(s).
;   Maybe_show_menu - Called to reshow the menu iff activemenu = defaultmenu.
;   Showmenu_activemenu - Called to reshow the menu.  Updates cascaded menus if necessary.
;   Build_menu_accelerators - Called from Loadaccel() to build the menu-related accelerators.
;   Update_edit_menu_text - Called to update the edit menu text after CUA Accelerators is toggled.
;   Menuinit_nnn - Define once for each pulldown or pullright menu ID <nnn> which
;                  needs to grey, check, etc. its submenu when its menu is activated.


compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'FEVSHMNU.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
; Following consts are copied from STDCNF.E to make it separately compilable
 compile if not defined(DEFAULT_PASTE)
   DEFAULT_PASTE = 'C'
 compile endif
 compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = '1'
 compile endif
 compile if not defined(SUPPORT_USERS_GUIDE)
   SUPPORT_USERS_GUIDE = 1
 compile endif
 compile if not defined(SUPPORT_TECHREF)
   SUPPORT_TECHREF = 1
 compile endif
 compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
 compile endif
 compile if not defined(HOST_SUPPORT)
   HOST_SUPPORT = ''
 compile endif
 compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
 compile endif
 compile if not defined(ALLOW_PROMPTING_AT_TOP)
   ALLOW_PROMPTING_AT_TOP = 1
 compile endif
 compile if not defined(BLOCK_ACTIONBAR_ACCELERATORS)
   BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
 compile endif
 compile if not defined(WANT_STACK_CMDS)
   WANT_STACK_CMDS = 'SWITCH'
 compile endif
 compile if not defined(RING_OPTIONAL)
   RING_OPTIONAL = 1
 compile endif
 compile if not defined(WANT_DM_BUFFER)
   WANT_DM_BUFFER = 1
 compile endif
; Following obsolete consts are copied from STDCNF.E to make it separately compilable
 compile if not defined(WANT_STREAM_MODE)
   WANT_STREAM_MODE = 'SWITCH'
 compile endif
 compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 1
 compile endif
 compile if not defined(WANT_TAGS)
   WANT_TAGS = 'DYNALINK'
 compile endif
 compile if not defined(WANT_EPM_SHELL)
   WANT_EPM_SHELL = 1
 compile endif
 compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 'DYNALINK'
 compile endif
 compile if not defined(ENHANCED_PRINT_SUPPORT)
   ENHANCED_PRINT_SUPPORT = 1
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

compile if not defined(CORE_stuff)
; This determines whether the CORE-specific commands (DEFINE)
; are included in the menus.
   const CORE_STUFF=0
compile endif

; Make that configurable for testing or emergency cases:
compile if not defined(OLD_ACCEL_KEY_DEFS)
const
   OLD_ACCEL_KEY_DEFS = 0
compile endif

/*
�����������������������������������������������������������������������������Ŀ
�What's it called  : loaddefaultmenu                                          �
�                                                                             �
�What does it do   : used by stdcnf.e to setup default EPM action bar         �
�                    (Note: a menu id of 0 halts the interpreter when         �
�                     selected.)                                              �
�                                                                             �
�Who and When      : Larry M.     1994/07/29                                  �
�������������������������������������������������������������������������������
*/
defc loaddefaultmenu
   universal activemenu,defaultmenu

   parse arg menuname .
   if menuname = '' then                  -- Initialization call
      menuname = 'default'
      defaultmenu = menuname              -- default menu name
      activemenu  = defaultmenu
   endif

   call add_file_menu(menuname)
   call add_edit_menu(menuname)
   call add_view_menu(menuname)
   call add_selected_menu(menuname)

   -- Process hook: add a user-defined submenu
   if isadefc('HookExecute') then
      'HookExecute addmenu'
   endif

   call add_help_menu(menuname)

defproc add_file_menu(menuname)
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
   buildsubmenu menuname, 1, FILE_BAR__MSG, FILE_BARP__MSG, 0 , mpfrom2short(HP_FILE, 0)
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 1, 100, OPENNOAS_MENU__MSG,         OPENAS_MENUP__MSG,     17+64, mpfrom2short(HP_FILE_OPENAS, 0)
         buildmenuitem menuname, 1, 101, NEWWIN_MENU__MSG\9 || CTRL_KEY__MSG'+O', 'OPENDLG'OPEN_MENUP__MSG,  0, mpfrom2short(HP_FILE_NEWWIN, 0)
         buildmenuitem menuname, 1, 102, SAMEWIN_MENU__MSG\9'F8', 'OPENDLG EDIT'ADD_MENUP__MSG,     0, mpfrom2short(HP_FILE_SAMEWIN, 0)
         buildmenuitem menuname, 1, 103, COMMAND_SHELL_MENU__MSG,  'shell'CREATE_SHELL_MENUP__MSG,       32769, mpfrom2short(HP_COMMAND_SHELL, 0)
compile if RING_OPTIONAL
   else
      buildmenuitem menuname, 1, 100, NEWWIN_MENU__MSG\9 || CTRL_KEY__MSG'+O', 'OPENDLG'OPEN_MENUP__MSG,  0, mpfrom2short(HP_FILE_NEWWIN, 0)
   endif
compile endif
      buildmenuitem menuname, 1, 105, CONFIG_MENU__MSG,         'configdlg'CONFIG_MENUP__MSG,  0, mpfrom2short(HP_OPTIONS_CONFIG, 0)
      buildmenuitem menuname, 1, 106, 'Select menu...',         'ChangeMenu'\1'Open a listbox and change or refresh the menu', 0, 0
      buildmenuitem menuname, 1, 107, \0,                           '',                 4, 0
      buildmenuitem menuname, 1, 110, SAVE_MENU__MSG\9'F2',     'SAVE'SAVE_MENUP__MSG,             0, mpfrom2short(HP_FILE_SAVE, 0)
      buildmenuitem menuname, 1, 120, SAVEAS_MENU__MSG,         'SAVEAS_DLG'SAVEAS_MENUP__MSG, 0, mpfrom2short(HP_FILE_SAVEAS, 0)
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 1, 130, FILE_MENU__MSG\9'F4',     'FILE'FILE_MENUP__MSG,             0, mpfrom2short(HP_FILE_FILE, 0)
compile if RING_OPTIONAL
   else
      buildmenuitem menuname, 1, 130, SAVECLOSE_MENU__MSG\9'F4',     'FILE'FILE_MENUP__MSG,        0, mpfrom2short(HP_FILE_FILE, 0)
   endif
compile endif
      buildmenuitem menuname, 1, 135, \0,                           '',                 4, 0
      buildmenuitem menuname, 1, 140, COMMAND_BAR__MSG, COMMAND_BARP__MSG, 17+64, mpfrom2short(HP_COMMAND, 0)
         buildmenuitem menuname, 1, 141, COMMANDLINE_MENU__MSG\9 || CTRL_KEY__MSG'+I', 'commandline'COMMANDLINE_MENUP__MSG,   0, mpfrom2short(HP_COMMAND_CMD, 0)
compile if WANT_EPM_SHELL = 1
         buildmenuitem menuname, 1, 65535, HALT_COMMAND_MENU__MSG, '', 0, mpfrom2short(HP_COMMAND_HALT, 0)
         buildmenuitem menuname, 1, 142, WRITE_SHELL_MENU__MSG,        'shell_write'WRITE_SHELL_MENUP__MSG, 0, mpfrom2short(HP_COMMAND_WRITE, 16384)
         buildmenuitem menuname, 1, 143, SHELL_BREAK_MENU__MSG,        'shell_break'SHELL_BREAK_MENUP__MSG,  32769, mpfrom2short(HP_COMMAND_BREAK, 16384)
compile else
         buildmenuitem menuname, 1, 65535, HALT_COMMAND_MENU__MSG, '', 32769, mpfrom2short(HP_COMMAND_HALT, 0)
compile endif
      buildmenuitem menuname, 1, 150, GET_MENU__MSG,            'OPENDLG GET'GET_MENUP__MSG,      0, mpfrom2short(HP_FILE_GET , 0)
;     buildmenuitem menuname, 1, 155, \0,                           '',                 4, 0
compile if ENHANCED_PRINT_SUPPORT
      buildmenuitem menuname, 1, 160, PRINT_MENU__MSG'...',  'printdlg'ENHPRT_FILE_MENUP__MSG,         0, mpfrom2short(HP_FILE_ENHPRINT, 0)
compile else
      buildmenuitem menuname, 1, 160, PRINT_MENU__MSG,       'xcom save /s /ne' default_printer()PRT_FILE_MENUP__MSG,   0, mpfrom2short(HP_FILE_PRINT, 0)
compile endif
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 1, 165, \0,           '',                       4, 0
      buildmenuitem menuname, 1, 170, QUIT_MENU__MSG\9'F3',     'QUIT'QUIT_MENUP__MSG,             0, mpfrom2short(HP_FILE_QUIT, 0)
compile if RING_OPTIONAL
   endif
compile endif



define
 compile if not defined(ALTERNATE_PASTE)
  compile if DEFAULT_PASTE = ''
   ALTERNATE_PASTE = 'C'
  compile else
   ALTERNATE_PASTE = ''
  compile endif
 compile endif
   PASTE_C_KEY = ''
   PASTE_B_KEY = ''
   PASTE_L_KEY = ''
compile if ALTERNATE_PASTE = ''
   PASTE_L_KEY = \9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile elseif ALTERNATE_PASTE = 'B'
   PASTE_B_KEY = \9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile elseif ALTERNATE_PASTE = 'C'
   PASTE_C_KEY = \9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile else
   * Error:  ALTERNATE_PASTE must be '', 'B', or 'C'
compile endif
compile if DEFAULT_PASTE = ''
   PASTE_L_KEY = \9 || SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile elseif DEFAULT_PASTE = 'B'
   PASTE_B_KEY = \9 || SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile elseif DEFAULT_PASTE = 'C'
   PASTE_C_KEY = \9 || SHIFT_KEY__MSG'+'INSERT_KEY__MSG
compile else
   * Error:  DEFAULT_PASTE must be '', 'B', or 'C'
compile endif

define  -- Prepare for some conditional tests
   maybe_ring_accel = "' ' <"  -- Will be true for any letter
compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   maybe_actions_accel = 'ACTIONS_ACCEL__L <>'
compile else
   maybe_actions_accel = "' ' <"  -- Will be true for any letter
compile endif


defproc add_edit_menu(menuname)
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif
   buildsubmenu  menuname, 2, EDIT_BAR__MSG, ''EDIT_BARP__MSG, 0 , mpfrom2short(HP_EDIT, 0)
      buildmenuitem menuname, 2, 200, UNDO__MENU__MSG,   UNDO__MENUP__MSG,    17+64, mpfrom2short(HP_EDIT_UNDO2, 0)
         buildmenuitem menuname, 2, 201, UNDO_MENU__MSG\9 || ALT_KEY__MSG'+'BACKSPACE_KEY__MSG,   'UNDO 1'UNDO_MENUP__MSG,    0, mpfrom2short(HP_EDIT_UNDO, 0)
compile if WANT_DM_BUFFER
         buildmenuitem menuname, 2, 202, UNDO_REDO_MENU__MSG\9 || CTRL_KEY__MSG'+U', 'undodlg'UNDO_REDO_MENUP__MSG,      0, mpfrom2short(HP_EDIT_UNDOREDO, 0)
         buildmenuitem menuname, 2, 203, RECOVER_MARK_MENU__MSG,        'GetDMBuff'RECOVER_MARK_MENUP__MSG,    32769, mpfrom2short(HP_EDIT_RECOVER, 0)
compile else
         buildmenuitem menuname, 2, 202, UNDO_REDO_MENU__MSG\9 || CTRL_KEY__MSG'+U', 'undodlg'UNDO_REDO_MENUP__MSG,      32769, mpfrom2short(HP_EDIT_UNDOREDO, 0)
compile endif  -- WANT_DM_BUFFER
      buildmenuitem menuname, 2, 205, \0,                               '',          4, 0
      buildmenuitem menuname, 2, 210, CLIP_COPY_MENU__MSG\9 || CTRL_KEY__MSG'+'INSERT_KEY__MSG ,  'Copy2Clip'CLIP_COPY_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPY, 0)
      buildmenuitem menuname, 2, 220, CUT_MENU__MSG\9 || SHIFT_KEY__MSG'+'DELETE_KEY__MSG, 'Cut'CUT_MENUP__MSG,       0, mpfrom2short(HP_EDIT_CUT, 0)
      buildmenuitem menuname, 2, 230, PASTE_C_MENU__MSG,   PASTE_C_MENUP__MSG,   17+64, mpfrom2short(HP_EDIT_PASTEMENU, 0)
         buildmenuitem menuname, 2, 231, PASTE_C_MENU__MSG||PASTE_C_KEY,   'Paste C'PASTE_C_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEC, 0)
         buildmenuitem menuname, 2, 232, PASTE_L_MENU__MSG||PASTE_L_KEY,   'Paste'PASTE_L_MENUP__MSG,     0, mpfrom2short(HP_EDIT_PASTE, 0)
         buildmenuitem menuname, 2, 233, PASTE_B_MENU__MSG||PASTE_B_KEY,   'Paste B'PASTE_B_MENUP__MSG,   32769, mpfrom2short(HP_EDIT_PASTEB, 0)
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   accel_len = (3+length(ALT_KEY__MSG))*(not CUA_MENU_ACCEL)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'D' & EDIT_ACCEL__L<>'D' & VIEW_ACCEL__L<>'D' & SELECTED_ACCEL__L<>'D' & HELP_ACCEL__L<>'D' & $maybe_ring_accel 'D' & $maybe_actions_accel 'D')
      buildmenuitem menuname, 2, 240, DELETE_MENU__MSG\9 || ALT_KEY__MSG'+D',   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 2, 240, DELETE_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+D', accel_len),   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile else
      buildmenuitem menuname, 2, 240, DELETE_MENU__MSG,   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile endif
      buildmenuitem menuname, 2, 245, \0,                               '',          4, 0
;      buildmenuitem menuname, 2, 250, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/',     'select_all'SELECT_ALL_MENUP__MSG, 0, mpfrom2short(HP_EDIT_SELECTALL, 0)
; added Ctrl+A
      buildmenuitem menuname, 2, 250, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/ | 'CTRL_KEY__MSG'+A',     'select_all'SELECT_ALL_MENUP__MSG, 0, mpfrom2short(HP_EDIT_SELECTALL, 0)
      buildmenuitem menuname, 2, 251, DESELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+\',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DESELECTALL, 0)
compile if SPELL_SUPPORT
 compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
 compile endif
      buildmenuitem menuname, 2, 255, \0,                               '',          4, 0
      buildmenuitem menuname, 2, 260, PROOF_MENU__MSG,           'proof'PROOF_MENUP__MSG,     0, mpfrom2short(HP_OPTIONS_PROOF, 0)
      buildmenuitem menuname, 2, 261, PROOF_WORD_MENU__MSG,      'proofword'PROOF_WORD_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_PROOFW, 0)
      buildmenuitem menuname, 2, 262, SYNONYM_MENU__MSG,         'syn'SYNONYM_MENUP__MSG,       0, mpfrom2short(HP_OPTIONS_SYN, 0)
      buildmenuitem menuname, 2, 263, DYNASPELL_MENU__MSG,        'dynaspell'DYNASPELL_MENUP__MSG,       0, mpfrom2short(HP_OPTIONS_DYNASPELL, 0)
 compile if CORE_STUFF
      buildmenuitem menuname, 2, 264, DEFINE_WORD_MENU__MSG,     'define'DEFINE_WORD_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_DEFINE, 0)
 compile endif  -- CORE_STUFF
 compile if CHECK_FOR_LEXAM
   endif
 compile endif
compile endif

defproc add_view_menu(menuname)
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
compile endif
   buildsubmenu  menuname, 3, VIEW_BAR__MSG, VIEW_BARP__MSG, 0 , mpfrom2short(HP_VIEW, 0)
      buildmenuitem menuname, 3, 300, SEARCH_BAR__MSG, SEARCH_BARP__MSG, 17+64, mpfrom2short(HP_SEARCH, 0)
         buildmenuitem menuname, 3, 301, SEARCH_MENU__MSG\9 || CTRL_KEY__MSG'+S',      'SEARCHDLG'SEARCH_MENUP__MSG,   0, mpfrom2short(HP_SEARCH_SEARCH, 0)
         buildmenuitem menuname, 3, 302, \0,                           '',            4, 0
         buildmenuitem menuname, 3, 303, FIND_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+F',   'SEARCHDLG F'FIND_NEXT_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_FIND, 0)
         buildmenuitem menuname, 3, 304, CHANGE_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+C', 'SEARCHDLG C'CHANGE_NEXT_MENUP__MSG, 32769, mpfrom2short(HP_SEARCH_CHANGE, 0)
compile if WANT_BOOKMARKS
      buildmenuitem menuname, 3, 310, BOOKMARKS_MENU__MSG,   BOOKMARKS_MENUP__MSG, 17 + 64, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 311, SET_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+M',  'setmark'SET_MARK_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 312, LIST_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+B', 'listmark'LIST_MARK_MENUP__MSG,       0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 313, \0,                  '',               4, 0
         buildmenuitem menuname, 3, 314, NEXT_MARK_MENU__MSG\9 || ALT_KEY__MSG'+/',  'nextbookmark'NEXT_MARK_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 315, PREV_MARK_MENU__MSG\9 || ALT_KEY__MSG'+\',  'nextbookmark P'PREV_MARK_MENUP__MSG, 32768+1, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
compile endif
compile if WANT_TAGS
      buildmenuitem menuname, 3, 320, TAGS_MENU__MSG,   TAGS_MENUP__MSG, 17+64, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 321, TAGSDLG_MENU__MSG\9, 'poptagsdlg'TAGSDLG_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 322, \0,                  '',               4, 0
         buildmenuitem menuname, 3, 323, FIND_TAG_MENU__MSG\9 || SHIFT_KEY__MSG'+F6',  'findtag'FIND_TAG_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 324, FIND_TAG2_MENU__MSG\9 || SHIFT_KEY__MSG'+F7', 'findtag *'FIND_TAG2_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 329, \0,                               '',          4, 0
         buildmenuitem menuname, 3, 330, SCAN_TAGS_MENU__MSG,  'tagscan'SCAN_TAGS_MENUP__MSG, 32769, mpfrom2short(HP_SEARCH_TAGS, 0)
compile endif
      buildmenuitem menuname, 3, 335, \0,                               '',          4, 0
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 3, 340, FILE_LIST_MENU__MSG\9 || CTRL_KEY__MSG'+G',     'Ring_More'LIST_FILES_MENUP__MSG,  0 , mpfrom2short(HP_OPTIONS_LIST, 0)
compile if RING_OPTIONAL
   endif
compile endif
      buildmenuitem menuname, 3, 341, MESSAGES_MENU__MSG,       'messagebox'MESSAGES_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_MESSAGES, 0)
compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
      buildmenuitem menuname, 3, 342, \0,                               '',          4, 0
      buildmenuitem menuname, 3, 343, PUSH_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'DOWN_KEY__MSG, 'PUSHPOS'PUSH_CURSOR_MENUP__MSG,  0, mpfrom2short(HP_EDIT_PUSHPOS, 0)
      buildmenuitem menuname, 3, 344, POP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'UP_KEY__MSG, 'POPPOS'POP_CURSOR_MENUP__MSG,   0, mpfrom2short(HP_EDIT_POPPOS, 16384)
      buildmenuitem menuname, 3, 345, SWAP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+=', 'SWAPPOS'SWAP_CURSOR_MENUP__MSG,   0, mpfrom2short(HP_EDIT_SWAPPOS, 16384)
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
compile endif

defproc add_selected_menu(menuname)
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
 compile endif
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   accel_len = (3+length(ALT_KEY__MSG))*(not CUA_MENU_ACCEL)
compile endif
   buildsubmenu  menuname, 4, SELECTED_BAR__MSG, SELECTED_BARP__MSG, 0 , mpfrom2short(HP_SELECTED, 0)
      buildmenuitem menuname, 4, 400, STYLE_MENU__MSG\9 || CTRL_KEY__MSG'+Y',        'fontlist'STYLE_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_STYLE, 0)
      buildmenuitem menuname, 4, 405, \0,                       '',          4, 0
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'C' & EDIT_ACCEL__L<>'C' & VIEW_ACCEL__L<>'C' & SELECTED_ACCEL__L<>'C' & HELP_ACCEL__L<>'C' & $maybe_ring_accel 'C' & $maybe_actions_accel 'C')
      buildmenuitem menuname, 4, 410, COPY_MRK_MENU__MSG\9 || ALT_KEY__MSG'+C',     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 4, 410, COPY_MRK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+C', accel_len),     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile else
      buildmenuitem menuname, 4, 410, COPY_MRK_MENU__MSG,              'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'M' & EDIT_ACCEL__L<>'M' & VIEW_ACCEL__L<>'M' & SELECTED_ACCEL__L<>'M' & HELP_ACCEL__L<>'M' & $maybe_ring_accel 'M' & $maybe_actions_accel 'M')
      buildmenuitem menuname, 4, 415, MOVE_MRK_MENU__MSG\9 || ALT_KEY__MSG'+M',     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 4, 415, MOVE_MRK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+M', accel_len),     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile else
      buildmenuitem menuname, 4, 415, MOVE_MRK_MENU__MSG,     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'O' & EDIT_ACCEL__L<>'O' & VIEW_ACCEL__L<>'O' & SELECTED_ACCEL__L<>'O' & HELP_ACCEL__L<>'O' & $maybe_ring_accel 'O' & $maybe_actions_accel 'O')
      buildmenuitem menuname, 4, 420, OVERLAY_MRK_MENU__MSG\9 || ALT_KEY__MSG'+O',  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 4, 420, OVERLAY_MRK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+O', accel_len),  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile else
      buildmenuitem menuname, 4, 420, OVERLAY_MRK_MENU__MSG,  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'A' & EDIT_ACCEL__L<>'A' & VIEW_ACCEL__L<>'A' & SELECTED_ACCEL__L<>'A' & HELP_ACCEL__L<>'A' & $maybe_ring_accel 'A' & $maybe_actions_accel 'A')
      buildmenuitem menuname, 4, 425, ADJUST_MRK_MENU__MSG\9 || ALT_KEY__MSG'+A',   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 4, 425, ADJUST_MRK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+A', accel_len),   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile else
      buildmenuitem menuname, 4, 425, ADJUST_MRK_MENU__MSG,   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile endif
compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
      buildmenuitem menuname, 4, 430, \0,                       '',          4, 0
      buildmenuitem menuname, 4, 431, PUSH_MRK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'DOWN_KEY__MSG, 'PUSHMARK'PUSH_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_PUSHMARK, 0)
      buildmenuitem menuname, 4, 432, POP_MRK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'UP_KEY__MSG, 'POPMARK'POP_MARK_MENUP__MSG,  0, mpfrom2short(HP_EDIT_POPMARK, 16384)
      buildmenuitem menuname, 4, 433, SWAP_MRK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+=', 'SWAPMARK'SWAP_MARK_MENUP__MSG,  0, mpfrom2short(HP_EDIT_SWAPMARK, 16384)
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
compile endif
      buildmenuitem menuname, 4, 440, \0,                       '',          4, 0
compile if ENHANCED_PRINT_SUPPORT
      buildmenuitem menuname, 4, 450, PRINT_MENU__MSG'...',          'PRINTDLG M'ENHPRT_MARK_MENUP__MSG,0, mpfrom2short(HP_EDIT_ENHPRINT, 0)
compile else
      buildmenuitem menuname, 4, 450, PRINT_MENU__MSG,               'DUPMARK P'PRT_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_PRINT, 0)
compile endif


defproc add_help_menu(menuname)
   buildsubmenu menuname, HELP_MENU_ID, HELP_BAR__MSG, 'help'HELP_BARP__MSG, /* 512 */  0, mpfrom2short(HP_HELP, 0)
      buildmenuitem menuname, HELP_MENU_ID, 600, HELP_INDEX_MENU__MSG,   'helpmenu 10'/*64044*/HELP_INDEX_MENUP__MSG,   0, mpfrom2short(HP_HELP_INDEX, 0)
      buildmenuitem menuname, HELP_MENU_ID, 601, EXT_HELP_MENU__MSG,     'helpmenu 4000'EXT_HELP_MENUP__MSG, 0, mpfrom2short(HP_HELP_EXTENDED, 0)
      buildmenuitem menuname, HELP_MENU_ID, 602, HELP_HELP_MENU__MSG,    'helpmenu 64027'HELP_HELP_MENUP__MSG,    0, mpfrom2short(HP_HELP_HELP, 0)
      buildmenuitem menuname, HELP_MENU_ID, 603, KEYS_HELP_MENU__MSG,    'helpmenu 1000'KEYS_HELP_MENUP__MSG, 0, mpfrom2short(HP_HELP_KEYS, 0)
      buildmenuitem menuname, HELP_MENU_ID, 604, COMMANDS_HELP_MENU__MSG,'helpmenu 2000'COMMANDS_HELP_MENUP__MSG, 0, mpfrom2short(HP_HELP_COMMANDS, 0)
      buildmenuitem menuname, HELP_MENU_ID, 605, \0,           '',                        4, 0
      buildmenuitem menuname, HELP_MENU_ID, 606, HELP_BROWSER_MENU__MSG, 'help'HELP_BROWSER_MENUP__MSG,    0, mpfrom2short(HP_HELP_BROWSE, 0)
      buildmenuitem menuname, HELP_MENU_ID, 607, \0,           '',                        4, 0
compile if 0
      buildmenuitem menuname, HELP_MENU_ID, 608, '#211'||(3-(screenxysize('X')>1000)), 'IBMmsg'HELP_PROD_MENUP__MSG, 2, mpfrom2short(HP_HELP_IBM, 0)
                         -- Resource # 2112 or 2113 in ERES.DLL
compile else
      buildmenuitem menuname, HELP_MENU_ID, 608, HELP_PROD_MENU__MSG, 'IBMmsg'HELP_PROD_MENUP__MSG, 0, mpfrom2short(HP_HELP_PROD, 0)
compile endif
compile if SUPPORT_USERS_GUIDE | SUPPORT_TECHREF
      buildmenuitem menuname, HELP_MENU_ID, 610, \0,           '',                        4, 0
 compile if SUPPORT_USERS_GUIDE
      buildmenuitem menuname, HELP_MENU_ID, 620, USERS_GUIDE_MENU__MSG,   USERS_GUIDE_MENUP__MSG, 17+64, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
         buildmenuitem menuname, HELP_MENU_ID, 621, VIEW_USERS_MENU__MSG,  'view epmusers'VIEW_USERS_MENUP__MSG, 0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
         buildmenuitem menuname, HELP_MENU_ID, 622, VIEW_IN_USERS_MENU__MSG,  'viewword epmusers'VIEW_IN_USERS_MENUP__MSG, 0, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
         buildmenuitem menuname, HELP_MENU_ID, 623, VIEW_USERS_SUMMARY_MENU__MSG,  'view epmusers Summary'VIEW_USERS_SUMMARY_MENUP__MSG, 32768+1, mpfrom2short(HP_HELP_USERS_GUIDE, 0)
 compile endif
 compile if SUPPORT_TECHREF
      buildmenuitem menuname, HELP_MENU_ID, 630, TECHREF_MENU__MSG,   TECHREF_MENUP__MSG, 17+64, mpfrom2short(HP_HELP_TECHREF, 0)
         buildmenuitem menuname, HELP_MENU_ID, 631, VIEW_TECHREF_MENU__MSG,  'view epmtech'VIEW_TECHREF_MENUP__MSG, 0, mpfrom2short(HP_HELP_TECHREF, 0)
         buildmenuitem menuname, HELP_MENU_ID, 632, VIEW_IN_TECHREF_MENU__MSG,  'viewword epmtech'VIEW_IN_TECHREF_MENUP__MSG, 32768+1, mpfrom2short(HP_HELP_TECHREF, 0)
 compile endif
compile endif


; Moved readd_help_menu, maybe_show_menu and showmenu_activemenu to MENU.E.

; ---------------------------------------------------------------------------
defc add_cascade_menus
   -- This command is called by defproc showmmenu_activemenu with 'postme'.
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      'cascade_menu 100 102' -- If ring is enabled, the default is Open as Same Window
compile if RING_OPTIONAL
   else
      'cascade_menu 100 101' -- If ring is not enabled, the default is Open as New Window
   endif
compile endif
   'cascade_menu 140 141'  -- Command cascade; default is Command Dialog
   'cascade_menu 200 202'  -- Undo cascade; default is Undo Dialog
   'cascade_menu 230 231'  -- Paste cascade; default is Paste (character mark)
   'cascade_menu 300 301'  -- Search cascade; default is Search Dialog
compile if WANT_BOOKMARKS
   'cascade_menu 310 314'  -- Bookmarks cascade; default is Next Bookmark
compile endif
compile if WANT_TAGS
   'cascade_menu 320 321'  -- Tags cascade; default is Tags Dialog
compile endif
compile if SUPPORT_USERS_GUIDE
   'cascade_menu 620'
compile endif
compile if SUPPORT_TECHREF
   'cascade_menu 630'
compile endif
compile if defined(CUSTEPM_DEFAULT_SCREEN)
   'cascade_menu' 3700 (CUSTEPM_DEFAULT_SCREEN + 3700)
compile elseif defined(HAVE_CUSTEPM)
   'cascade_menu' 3700
compile endif

; ---------------------------------------------------------------------------
definit
   -- Define a list of used menu accelerators, that can't be used as standard
   -- accelerator keys combined with Alt anymore, when 'Menu accelerators' is
   -- activated.
   -- Maybe someone has already defined something here at definit,
   -- so better add it to the array var if not already.
   call AddOnceAVar( 'usedmenuaccelerators', 'F E V S H')


compile if OLD_ACCEL_KEY_DEFS  -- following is disabled #####################
defproc build_menu_accelerators(activeaccel)
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif
compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
compile endif
   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')

                       -- Build keys on File menu
   i = i + 1
   buildacceltable activeaccel, 'dokey F8',  AF_VIRTUALKEY,                VK_F8, i  -- F8
   i = i + 1
   buildacceltable activeaccel, 'dokey c+O', AF_CHAR+AF_CONTROL,              79, i  -- c+O
   i = i + 1
   buildacceltable activeaccel, 'dokey c+O', AF_CHAR+AF_CONTROL,             111, i  -- c+o
   i = i + 1
   buildacceltable activeaccel, 'dokey F7',  AF_VIRTUALKEY,                VK_F7, i  -- F7
   i = i + 1
   buildacceltable activeaccel, 'dokey F2',  AF_VIRTUALKEY,                VK_F2, i  -- F2
   i = i + 1
   buildacceltable activeaccel, 'dokey F3',  AF_VIRTUALKEY,                VK_F3, i  -- F3
   i = i + 1
   buildacceltable activeaccel, 'dokey F4',  AF_VIRTUALKEY,                VK_F4, i  -- F4

                       -- Build keys on Edit menu  ('C' & 'O' appear under Action bar keys for English)
compile if FILE_ACCEL__L <> 'C' & EDIT_ACCEL__L <> 'C' & SELECTED_ACCEL__L <> 'C' & HELP_ACCEL__L <> 'C' & $maybe_ring_accel 'C' & $maybe_actions_accel 'C'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  67, i  -- a+C
   i = i + 1
   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  99, i  -- a+c
compile endif
compile if FILE_ACCEL__L <> 'M' & EDIT_ACCEL__L <> 'M' & SELECTED_ACCEL__L <> 'M' & HELP_ACCEL__L <> 'M' & $maybe_ring_accel 'M' & $maybe_actions_accel 'M'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+M', AF_CHAR+AF_ALT,                  77, i  -- a+M
   i = i + 1
   buildacceltable activeaccel, 'dokey a+M', AF_CHAR+AF_ALT,                 109, i  -- a+m
compile endif
compile if FILE_ACCEL__L <> 'O' & EDIT_ACCEL__L <> 'O' & SELECTED_ACCEL__L <> 'O' & HELP_ACCEL__L <> 'O' & $maybe_ring_accel 'O' & $maybe_actions_accel 'O'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+O', AF_CHAR+AF_ALT,                  79, i  -- a+O
   i = i + 1
   buildacceltable activeaccel, 'dokey a+O', AF_CHAR+AF_ALT,                 111, i  -- a+o
compile endif
compile if FILE_ACCEL__L <> 'A' & EDIT_ACCEL__L <> 'A' & SELECTED_ACCEL__L <> 'A' & HELP_ACCEL__L <> 'A' & $maybe_ring_accel 'A' & $maybe_actions_accel 'A'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+A', AF_CHAR+AF_ALT,                  65, i  -- a+A
   i = i + 1
   buildacceltable activeaccel, 'dokey a+A', AF_CHAR+AF_ALT,                  97, i  -- a+a
compile endif
compile if FILE_ACCEL__L <> 'U' & EDIT_ACCEL__L <> 'U' & SELECTED_ACCEL__L <> 'U' & HELP_ACCEL__L <> 'U' & $maybe_ring_accel 'U' & $maybe_actions_accel 'U'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+U', AF_CHAR+AF_ALT,                  85, i  -- a+U
   i = i + 1
   buildacceltable activeaccel, 'dokey a+U', AF_CHAR+AF_ALT,                 117, i  -- a+u
compile endif
compile if FILE_ACCEL__L <> 'D' & EDIT_ACCEL__L <> 'D' & SELECTED_ACCEL__L <> 'D' & HELP_ACCEL__L <> 'D' & $maybe_ring_accel 'D' & $maybe_actions_accel 'D'
   i = i + 1
   buildacceltable activeaccel, 'dokey a+D', AF_CHAR+AF_ALT,                  68, i  -- a+D
   i = i + 1
   buildacceltable activeaccel, 'dokey a+D', AF_CHAR+AF_ALT,                 100, i  -- a+d
compile endif
   i = i + 1
   buildacceltable activeaccel, 'copy2clip', AF_VIRTUALKEY+AF_CONTROL, VK_INSERT, i  -- c+Insert
   i = i + 1
   buildacceltable activeaccel, 'cut',       AF_VIRTUALKEY+AF_SHIFT,   VK_DELETE, i  -- s+Delete
   i = i + 1
   buildacceltable activeaccel, 'paste' DEFAULT_PASTE, AF_VIRTUALKEY+AF_SHIFT,   VK_INSERT, i  -- s+Insert
   i = i + 1
   buildacceltable activeaccel, 'paste' ALTERNATE_PASTE, AF_VIRTUALKEY+AF_SHIFT+AF_CONTROL,   VK_INSERT, i  -- c+s+Insert
   i = i + 1
   buildacceltable activeaccel, 'dokey F9',  AF_VIRTUALKEY,                VK_F9, i  -- F9
   i = i + 1
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,              89, i  -- c+Y
   i = i + 1
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,             121, i  -- c+y
   i = i + 1
   buildacceltable activeaccel, 'select_all',AF_CHAR+AF_CONTROL,              47, i  -- c+/
   i = i + 1
   buildacceltable activeaccel, 'DUPMARK U', AF_CHAR+AF_CONTROL,              92, i  -- c+\

compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
   i = i + 1
   buildacceltable activeaccel, 'dokey c+down', AF_VIRTUALKEY+AF_CONTROL,   VK_DOWN, i  -- c+Down
   i = i + 1
   buildacceltable activeaccel, 'dokey c+Up',   AF_VIRTUALKEY+AF_CONTROL,     VK_UP, i  -- c+Up
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
   i = i + 1
   buildacceltable activeaccel, 'swappos',  AF_CHAR+AF_CONTROL,                     61, i  -- c+=
   i = i + 1
   buildacceltable activeaccel, 'pushmark', AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT, VK_DOWN, i  -- c+s+Down
   i = i + 1
   buildacceltable activeaccel, 'popmark',  AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT,   VK_UP, i  -- c+s+Up
   i = i + 1
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            61, i  -- c+s+=
   i = i + 1
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            43, i  -- c+s++
compile endif

                       -- Build keys on Search menu
   i = i + 1
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,              83, i  -- c+S
   i = i + 1
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,             115, i  -- c+s
   i = i + 1
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,              70, i  -- c+F
   i = i + 1
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,             102, i  -- c+f
   i = i + 1
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              67, i  -- c+C
   i = i + 1
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              99, i  -- c+c
                       -- Build keys on Bookmark submenu
compile if WANT_BOOKMARKS
   i = i + 1
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              66, i  -- c+B
   i = i + 1
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              98, i  -- c+b
   i = i + 1
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,              77, i  -- c+M
   i = i + 1
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,             109, i  -- c+m
   i = i + 1
   buildacceltable activeaccel, 'nextbookmark',  AF_CHAR+AF_ALT,              47, i  -- a+/
   i = i + 1
   buildacceltable activeaccel, 'nextbookmark P',AF_CHAR+AF_ALT,              92, i  -- a+\
compile endif
                       -- Build keys on Tags submenu
compile if WANT_TAGS
   i = i + 1
   buildacceltable activeaccel, 'dokey s+F6', AF_VIRTUALKEY+AF_SHIFT,      VK_F6, i  -- s+F6
   i = i + 1
   buildacceltable activeaccel, 'dokey s+F7', AF_VIRTUALKEY+AF_SHIFT,      VK_F7, i  -- s+F7
   i = i + 1
   buildacceltable activeaccel, 'dokey s+F8', AF_VIRTUALKEY+AF_SHIFT,      VK_F8, i  -- s+F8
   i = i + 1
   buildacceltable activeaccel, 'dokey s+F9', AF_VIRTUALKEY+AF_SHIFT,      VK_F9, i  -- s+F9
compile endif

                       -- Build keys on Options menu
   i = i + 1
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,              71, i  -- c+G
   i = i + 1
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,             103, i  -- c+g

                       -- Build keys on Command menu
   i = i + 1
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,              73, i  -- c+I
   i = i + 1
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,             105, i  -- c+i

                       -- Block action bar accelerator keys (English)
compile if BLOCK_ACTIONBAR_ACCELERATORS
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   if not CUA_MENU_ACCEL then
 compile endif
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A1   , i  -- a+F
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A2   , i  -- a+f
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A1   , i  -- a+E
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A2   , i  -- a+e
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'SELECTED_ACCEL__L,AF_CHAR+AF_ALT, SELECTED_ACCEL__A1,i  -- a+S
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'SELECTED_ACCEL__L,AF_CHAR+AF_ALT, SELECTED_ACCEL__A2,i  -- a+s
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'VIEW_ACCEL__L,    AF_CHAR+AF_ALT, VIEW_ACCEL__A1,    i  -- a+V
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'VIEW_ACCEL__L,    AF_CHAR+AF_ALT, VIEW_ACCEL__A2,    i  -- a+v
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A1   , i  -- a+H
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A2   , i  -- a+h
 compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A1, i  -- a+A
   i = i + 1
   buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A2, i  -- a+a
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   endif -- CUA_MENU_ACCEL
 compile endif
compile endif -- BLOCK_ACTIONBAR_ACCELERATORS

   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   return
compile endif -- OLD_ACCEL_KEY_DEFS  ########################################


compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
define  -- Prepare for some conditional tests
   maybe_ring_accel = 'RING_ACCEL__L ='
 compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   maybe_actions_accel = 'ACTIONS_ACCEL__L ='
 compile else
   maybe_actions_accel = "' ' ="  -- Will be false for any letter
 compile endif

defproc update_edit_menu_text =  -- Actually, Selected menu, but we'll keep the name...
   universal CUA_MENU_ACCEL
   accel_len = (3+length(ALT_KEY__MSG))*(not CUA_MENU_ACCEL)

 compile if FILE_ACCEL__L = 'C' | EDIT_ACCEL__L = 'C' | VIEW_ACCEL__L = 'C' | SELECTED_ACCEL__L = 'C' | HELP_ACCEL__L = 'C' | $maybe_ring_accel 'C' | $maybe_actions_accel 'C'
   menutext = COPY_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+C', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      350 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'M' | EDIT_ACCEL__L = 'M' | VIEW_ACCEL__L = 'M' | SELECTED_ACCEL__L = 'M' | HELP_ACCEL__L = 'M' | $maybe_ring_accel 'M' | $maybe_actions_accel 'M'
   menutext = MOVE_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+M', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      360 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'O' | EDIT_ACCEL__L = 'O' | VIEW_ACCEL__L = 'O' | SELECTED_ACCEL__L = 'O' | HELP_ACCEL__L = 'O' | $maybe_ring_accel 'O' | $maybe_actions_accel 'O'
   menutext = OVERLAY_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+O', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      370 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'A' | EDIT_ACCEL__L = 'A' | VIEW_ACCEL__L = 'A' | SELECTED_ACCEL__L = 'A' | HELP_ACCEL__L = 'A' | $maybe_ring_accel 'A' | $maybe_actions_accel 'A'
   menutext = ADJUST_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+A', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      380 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'U' | EDIT_ACCEL__L = 'U' | VIEW_ACCEL__L = 'U' | SELECTED_ACCEL__L = 'U' | HELP_ACCEL__L = 'U' | $maybe_ring_accel 'U' | $maybe_actions_accel 'U'
   menutext = UNMARK_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+U', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      334 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'D' | EDIT_ACCEL__L = 'D' | VIEW_ACCEL__L = 'D' | SELECTED_ACCEL__L = 'D' | HELP_ACCEL__L = 'D' | $maybe_ring_accel 'D' | $maybe_actions_accel 'D'
   menutext = DELETE_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+D', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      340 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

compile endif  -- BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'



defc menuinit_2                  ------------- Menu id 2 -- Edit -------------------------
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
   undoaction 1, PresentState        -- Do to fix range, not for value.
   undoaction 6, StateRange               -- query range
   parse value staterange with oldeststate neweststate .
   SetMenuAttribute( 200, 16384, oldeststate<>neweststate )  -- Set to 1 if different
   on = marktype()<>''
   buf_flag = 0
   if not on then                             -- Only check buffer if no mark
      bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
      if bufhndl then                         -- If the buffer exists, check the
         buf_flag=itoa(peek(bufhndl,2,2),10)  -- amount of used space in buffer
         call buffer(FREEBUF, bufhndl)        -- then free it.
      endif
   endif
   SetMenuAttribute( 210, 16384, on)      -- Copy to clipboard
   SetMenuAttribute( 220, 16384, on)      -- Cut
   paste = clipcheck(format) & (format=1024) & not (browse() | .readonly)
   SetMenuAttribute( 230, 16384, paste)
   SetMenuAttribute( 240, 16384, on)      -- Delete mark
   SetMenuAttribute( 251, 16384, on)      -- Unmark (Deselect all)
compile if SPELL_SUPPORT
 compile if CHECK_FOR_LEXAM
    if LEXAM_is_available then
 compile endif
      SetMenuAttribute( 263, 8192, .keyset <> 'SPELL_KEYS')
 compile if CHECK_FOR_LEXAM
    endif
 compile endif
compile endif  -- SPELL_SUPPORT

defc menuinit_200                ------------- Menu id 200 -- Undo ---------------------
   SetMenuAttribute( 201, 16384, isadirtyline())
   undoaction 1, PresentState        -- Do to fix range, not for value.
   undoaction 6, StateRange               -- query range
   parse value staterange with oldeststate neweststate .
   SetMenuAttribute( 202, 16384, oldeststate<>neweststate )  -- Set to 1 if different



defc menuinit_230                ------------- Menu id 230 -- Paste ---------------------
   paste = clipcheck(format) & (format=1024) & not (browse() | .readonly)
   SetMenuAttribute( 231, 16384, paste)
   SetMenuAttribute( 232, 16384, paste)
   SetMenuAttribute( 233, 16384, paste)


defc menuinit_3                  ------------- Menu id 3 -- View -------------------------
compile if WANT_STACK_CMDS
   universal position_stack
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
compile endif
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      SetMenuAttribute( 340, 16384, filesinring()>1)  -- List ring
compile if RING_OPTIONAL
   endif
compile endif
compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
      SetMenuAttribute( 344, 16384, position_stack<>'')  -- Pop cursor
      SetMenuAttribute( 345, 16384, position_stack<>'')  -- Swap cursor
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
compile endif



defc menuinit_300               ------------- Menu id 300 -- Search -----------------------
   universal lastchangeargs
   getsearch strng
   parse value strng with . c .       -- blank, 'c', or 'l'
   SetMenuAttribute( 303, 16384, c<>'')  -- Find Next OK if not blank
   SetMenuAttribute( 304, 16384, lastchangeargs<>'')  -- Change Next only if 'c'



compile if WANT_BOOKMARKS
defc menuinit_310                ------------- Menu id 310 -- Bookmarks --------------------
   universal EPM_utility_array_ID
   --do_array 3, EPM_utility_array_ID, 'bmi.0', bmcount          -- Index says how many bookmarks there are
   rc = get_array_value( EPM_utility_array_ID, 'bmi.0', bmcount )          -- Index says how many bookmarks there are
   SetMenuAttribute( 311, 16384, not(browse() | .readonly))  -- Set
   SetMenuAttribute( 312, 16384, bmcount>0)   -- List
   SetMenuAttribute( 314, 16384, bmcount>0)   -- Next
   SetMenuAttribute( 315, 16384, bmcount>0)   -- Prev
compile endif  -- WANT_BOOKMARKS


defc menuinit_4                  ------------- Menu id 4 -- Selected ---------------------
compile if WANT_STACK_CMDS
   universal mark_stack
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
compile endif
   SetMenuAttribute( 400, 16384, on)      -- Style dialog
   on = marktype()<>''
   buf_flag = 0
   if not on then                             -- Only check buffer if no mark
      bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
      if bufhndl then                         -- If the buffer exists, check the
         buf_flag=itoa(peek(bufhndl,2,2),10)  -- amount of used space in buffer
         call buffer(FREEBUF, bufhndl)        -- then free it.
      endif
   endif
   SetMenuAttribute( 410, 16384, on | buf_flag)  -- Can Copy if mark or buffer has data
   SetMenuAttribute( 415, 16384, on)      -- Move mark
   SetMenuAttribute( 420, 16384, on | buf_flag)  -- Ditto for Overlay mark
   SetMenuAttribute( 425, 16384, on)      -- Adjust mark
compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
      SetMenuAttribute( 431, 16384, on)                  -- Push mark
      SetMenuAttribute( 432, 16384, mark_stack<>'')      -- Pop mark
      SetMenuAttribute( 433, 16384, on & mark_stack<>'') -- Swap mark
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
compile endif
   SetMenuAttribute( 450, 16384, on)      -- Print marked text


/*
����������������������������������������������������������������������������Ŀ
� what's it called: togglecontrol                                            �
�                                                                            �
� what does it do : The command either toggles a EPM control window on or off�
�                   or forces a EPM control window on or off.                �
�                   arg1   = EPM control window handle ID.  Control window   �
�                            ids given above.  The following windows handles �
�                            are currently supported.                        �
�                            EDITSTATUS, EDITVSCROLL, EDITHSCROLL, and       �
�                            EDITMSGLINE.                                    �
�                   arg2   [optional] = force option.                        �
�                            a value of 0, forces control window off         �
�                            a value of 1, forces control window on          �
�                           IF this argument is not specified the window     �
�                           in question is toggled.                          �
�                                                                            �
�                   This command is possible because of the EPM_EDIT_CONTROL �
�                   EPM_EDIT_CONTROLSTATUS message.                          �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Jerry C.   2/27/89                                       �
������������������������������������������������������������������������������
*/
defc togglecontrol
compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
compile endif
   forceon=0
   parse arg controlid fon
   if fon<>'' then
      forceon=(fon+1)*65536
   endif

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5388,               -- EPM_EDIT_CONTROLTOGGLE
                      controlid + forceon,
                      0)

defc toggleframe
 compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
 compile endif
   forceon=0
   parse arg controlid fon
   if fon<>'' then
      forceon=(fon+1)*65536
   endif

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5907,               -- EFRAMEM_TOGGLECONTROL
                      controlid + forceon,
                      0)
 compile if WANT_DYNAMIC_PROMPTS & not ALLOW_PROMPTING_AT_TOP
   if controlid=32 then
      if fon then  -- 1=top; 0=bottom.  If now top, turn off.
         menu_prompt = 0
      endif
   endif
 compile endif

defproc queryframecontrol(controlid)
   return windowmessage(1,  getpminfo(EPMINFO_EDITFRAME),   -- Send message to edit client
                        5907,               -- EFRAMEM_TOGGLECONTROL
                        controlid,
                        1)

compile if WANT_DYNAMIC_PROMPTS
defc toggleprompt
   universal menu_prompt
   menu_prompt = not menu_prompt
 compile if not ALLOW_PROMPTING_AT_TOP
   if menu_prompt then
      'toggleframe 32 0'      -- Force Extra window to bottom.
   endif
 compile endif  -- not ALLOW_PROMPTING_AT_TOP
compile endif

defc setscrolls
   'toggleframe 8'
   'toggleframe 16'

defc toggle_bitmap
   universal bitmap_present, bm_filename
   bitmap_present = not bitmap_present
;; bm_filename = ''
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
                      5498 - (44*bitmap_present), 0, 0)


defc CUA_mark_toggle
   universal CUA_marking_switch
   CUA_marking_switch = not CUA_marking_switch
   'togglecontrol 25' CUA_marking_switch
   call MH_set_mouse()

compile if WANT_STREAM_MODE = 'SWITCH'
defc stream_toggle
   universal stream_mode
   stream_mode = not stream_mode
   'togglecontrol 24' stream_mode
   'RefreshInfoLine STREAMMODE'
compile endif

compile if RING_OPTIONAL
defc ring_toggle
   universal ring_enabled
   universal activemenu, defaultmenu
   ring_enabled = not ring_enabled
   'toggleframe 4' ring_enabled
compile endif

compile if WANT_STACK_CMDS = 'SWITCH'
defc stack_toggle
   universal stack_cmds
   universal activemenu, defaultmenu
   stack_cmds = not stack_cmds
compile endif

compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
defc accel_toggle
   universal CUA_MENU_ACCEL
   universal activemenu, defaultmenu
   CUA_MENU_ACCEL = not CUA_MENU_ACCEL
   deleteaccel 'defaccel'
   'loadaccel'
compile endif

