/****************************** Module Header *******************************
*
* Module Name: stdmenu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdmenu.e,v 1.7 2002-09-21 20:20:18 aschn Exp $
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
compile if not defined(CORE_stuff)
; This determines whether the CORE-specific commands (DEFINE)
; are included in the menus.
const CORE_STUFF=0
compile endif

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
   universal activemenu,defaultmenu

   parse arg menuname .
   if menuname = '' then                  -- Initialization call
      menuname = 'default'
      defaultmenu = menuname              -- default menu name
      activemenu  = defaultmenu
   endif

   call add_file_menu(menuname)
   call add_edit_menu(menuname)
   call add_search_menu(menuname)
   call add_options_menu(menuname)
   call add_command_menu(menuname)
   call add_help_menu(menuname)

defproc add_file_menu(menuname)
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
   buildsubmenu menuname, 2, FILE_BAR__MSG, FILE_BARP__MSG, 0 , mpfrom2short(HP_FILE, 0)
      buildmenuitem menuname, 2, 198, NEW_MENU__MSG,            'NEW'NEW_MENUP__MSG,     0, mpfrom2short(HP_FILE_NEW, 0)
      buildmenuitem menuname, 2, 199, OPEN_NEW_MENU__MSG,       'OPEN'OPEN_NEW_MENUP__MSG,     0, mpfrom2short(HP_FILE_OPEN_NEW, 0)
      buildmenuitem menuname, 2, 200, OPEN_MENU__MSG\9 || CTRL_KEY__MSG'+O', 'OPENDLG'OPEN_MENUP__MSG,          0, mpfrom2short(HP_FILE_OPEN, 0)
      buildmenuitem menuname, 2, 201, GET_MENU__MSG,            'OPENDLG GET'GET_MENUP__MSG,      0, mpfrom2short(HP_FILE_GET , 0)
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 2, 202, ADD_MENU__MSG\9'F8', 'OPENDLG EDIT'ADD_MENUP__MSG,     0, mpfrom2short(HP_FILE_EDIT, 0)
compile if RING_OPTIONAL
   endif
compile endif
      buildmenuitem menuname, 2, 203, \0,                          '',                 4, 0
      buildmenuitem menuname, 2, 204, RENAME_MENU__MSG\9'F7',   'rename'RENAME_MENUP__MSG,0, mpfrom2short(HP_FILE_NAME, 0)
      buildmenuitem menuname, 2, 205, \0,                          '',                 4, 0
      buildmenuitem menuname, 2, 206, SAVE_MENU__MSG\9'F2',     'SAVE'SAVE_MENUP__MSG,             0, mpfrom2short(HP_FILE_SAVE, 0)
      buildmenuitem menuname, 2, 208, SAVEAS_MENU__MSG,         'SAVEAS_DLG'SAVEAS_MENUP__MSG, 0, mpfrom2short(HP_FILE_SAVEAS, 0)
compile if RING_OPTIONAL
   if ring_enabled then
compile endif         -- Note:  207 used in LaMail; keep ID the same.
      buildmenuitem menuname, 2, 207, FILE_MENU__MSG\9'F4',     'FILE'FILE_MENUP__MSG,             0, mpfrom2short(HP_FILE_FILE, 0)
compile if RING_OPTIONAL
   else
      buildmenuitem menuname, 2, 207, SAVECLOSE_MENU__MSG\9'F4',     'FILE'FILE_MENUP__MSG,        0, mpfrom2short(HP_FILE_FILE, 0)
   endif
compile endif
      buildmenuitem menuname, 2, 209, QUIT_MENU__MSG\9'F3',     'QUIT'QUIT_MENUP__MSG,             0, mpfrom2short(HP_FILE_QUIT, 0)
      buildmenuitem menuname, 2, 210, \0,                           '',                 4, 0
compile if ENHANCED_PRINT_SUPPORT
      buildmenuitem menuname, 2, 211, PRT_FILE_MENU__MSG'...',  'printdlg'ENHPRT_FILE_MENUP__MSG,         0, mpfrom2short(HP_FILE_ENHPRINT, 0)
compile else
      buildmenuitem menuname, 2, 211, PRT_FILE_MENU__MSG,       'xcom save /s /ne' default_printer()PRT_FILE_MENUP__MSG,   0, mpfrom2short(HP_FILE_PRINT, 0)
compile endif
   return

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
compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif

compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   accel_len = (3+length(ALT_KEY__MSG))*(not CUA_MENU_ACCEL)
compile endif

   buildsubmenu  menuname, 8, EDIT_BAR__MSG, ''EDIT_BARP__MSG, 0 , mpfrom2short(HP_EDIT, 0)
      buildmenuitem menuname, 8, 816, UNDO_MENU__MSG\9 || ALT_KEY__MSG'+'BACKSPACE_KEY__MSG,   'UNDO 1'UNDO_MENUP__MSG,    0, mpfrom2short(HP_EDIT_UNDO, 0)
      buildmenuitem menuname, 8, 818, UNDO_REDO_MENU__MSG\9 || CTRL_KEY__MSG'+U', 'undodlg'UNDO_REDO_MENUP__MSG,      0, mpfrom2short(HP_EDIT_UNDOREDO, 0)
compile if WANT_DM_BUFFER
      buildmenuitem menuname, 8, 817, RECOVER_MARK_MENU__MSG,        'GetDMBuff'RECOVER_MARK_MENUP__MSG,    0, mpfrom2short(HP_EDIT_RECOVER, 0)
compile endif  -- WANT_DM_BUFFER
      buildmenuitem menuname, 8, 807, \0,                               '',          4, 0
      buildmenuitem menuname, 8, 808, CLIP_COPY_MENU__MSG\9 || CTRL_KEY__MSG'+'INSERT_KEY__MSG ,  'Copy2Clip'CLIP_COPY_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPY, 0)
      buildmenuitem menuname, 8, 809, CUT_MENU__MSG\9 || SHIFT_KEY__MSG'+'DELETE_KEY__MSG, 'Cut'CUT_MENUP__MSG,       0, mpfrom2short(HP_EDIT_CUT, 0)
      buildmenuitem menuname, 8, 810, PASTE_C_MENU__MSG||PASTE_C_KEY,   'Paste C'PASTE_C_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEC, 0)
      buildmenuitem menuname, 8, 811, PASTE_L_MENU__MSG||PASTE_L_KEY,   'Paste'PASTE_L_MENUP__MSG,     0, mpfrom2short(HP_EDIT_PASTE, 0)
      buildmenuitem menuname, 8, 812, PASTE_B_MENU__MSG||PASTE_B_KEY,   'Paste B'PASTE_B_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEB, 0)
      buildmenuitem menuname, 8, 826, \0,                               '',          4, 0
      buildmenuitem menuname, 8, 827, STYLE_MENU__MSG\9 || CTRL_KEY__MSG'+Y',        'fontlist'STYLE_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_STYLE, 0)
      buildmenuitem menuname, 8, 815, \0,                               '',          4, 0

compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'C' & EDIT_ACCEL__L<>'C' & SEARCH_ACCEL__L<>'C' & OPTIONS_ACCEL__L<>'C' & COMMAND_ACCEL__L<>'C' & HELP_ACCEL__L<>'C' & $maybe_ring_accel 'C' & $maybe_actions_accel 'C')
      buildmenuitem menuname, 8, 800, COPY_MARK_MENU__MSG\9 || ALT_KEY__MSG'+C',     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 800, COPY_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+C', accel_len),     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile else
      buildmenuitem menuname, 8, 800, COPY_MARK_MENU__MSG,              'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'M' & EDIT_ACCEL__L<>'M' & SEARCH_ACCEL__L<>'M' & OPTIONS_ACCEL__L<>'M' & COMMAND_ACCEL__L<>'M' & HELP_ACCEL__L<>'M' & $maybe_ring_accel 'M' & $maybe_actions_accel 'M')
      buildmenuitem menuname, 8, 801, MOVE_MARK_MENU__MSG\9 || ALT_KEY__MSG'+M',     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 801, MOVE_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+M', accel_len),     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile else
      buildmenuitem menuname, 8, 801, MOVE_MARK_MENU__MSG,     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'O' & EDIT_ACCEL__L<>'O' & SEARCH_ACCEL__L<>'O' & OPTIONS_ACCEL__L<>'O' & COMMAND_ACCEL__L<>'O' & HELP_ACCEL__L<>'O' & $maybe_ring_accel 'O' & $maybe_actions_accel 'O')
      buildmenuitem menuname, 8, 802, OVERLAY_MARK_MENU__MSG\9 || ALT_KEY__MSG'+O',  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 802, OVERLAY_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+O', accel_len),  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile else
      buildmenuitem menuname, 8, 802, OVERLAY_MARK_MENU__MSG,  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'A' & EDIT_ACCEL__L<>'A' & SEARCH_ACCEL__L<>'A' & OPTIONS_ACCEL__L<>'A' & COMMAND_ACCEL__L<>'A' & HELP_ACCEL__L<>'A' & $maybe_ring_accel 'A' & $maybe_actions_accel 'A')
      buildmenuitem menuname, 8, 803, ADJUST_MARK_MENU__MSG\9 || ALT_KEY__MSG'+A',   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 803, ADJUST_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+A', accel_len),   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile else
      buildmenuitem menuname, 8, 803, ADJUST_MARK_MENU__MSG,   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
compile endif
      buildmenuitem menuname, 8, 804, \0,                       '',          4, 0
;      buildmenuitem menuname, 8, 828, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/',     'select_all'SELECT_ALL_MENUP__MSG, 0, mpfrom2short(HP_EDIT_SELECTALL, 0)
; added Ctrl+A
      buildmenuitem menuname, 8, 828, SELECT_ALL_MENU__MSG\9 || CTRL_KEY__MSG'+/ | 'CTRL_KEY__MSG'+A',     'select_all'SELECT_ALL_MENUP__MSG, 0, mpfrom2short(HP_EDIT_SELECTALL, 0)
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'U' & EDIT_ACCEL__L<>'U' & SEARCH_ACCEL__L<>'U' & OPTIONS_ACCEL__L<>'U' & COMMAND_ACCEL__L<>'U' & HELP_ACCEL__L<>'U' & $maybe_ring_accel 'U' & $maybe_actions_accel 'U')
      buildmenuitem menuname, 8, 805, UNMARK_MARK_MENU__MSG\9 || ALT_KEY__MSG'+U',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 805, UNMARK_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+U', accel_len),   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
compile else
      buildmenuitem menuname, 8, 805, UNMARK_MARK_MENU__MSG,   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS=1 | (FILE_ACCEL__L<>'D' & EDIT_ACCEL__L<>'D' & SEARCH_ACCEL__L<>'D' & OPTIONS_ACCEL__L<>'D' & COMMAND_ACCEL__L<>'D' & HELP_ACCEL__L<>'D' & $maybe_ring_accel 'D' & $maybe_actions_accel 'D')
      buildmenuitem menuname, 8, 806, DELETE_MARK_MENU__MSG\9 || ALT_KEY__MSG'+D',   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile elseif BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      buildmenuitem menuname, 8, 806, DELETE_MARK_MENU__MSG||leftstr(\9 || ALT_KEY__MSG'+D', accel_len),   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile else
      buildmenuitem menuname, 8, 806, DELETE_MARK_MENU__MSG,   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
compile endif

compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
      buildmenuitem menuname, 8, 819, \0,                               '',          4, 0
      buildmenuitem menuname, 8, 820, PUSH_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'DOWN_KEY__MSG, 'PUSHMARK'PUSH_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_PUSHMARK, 0)
      buildmenuitem menuname, 8, 821, POP_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+'UP_KEY__MSG, 'POPMARK'POP_MARK_MENUP__MSG,  0, mpfrom2short(HP_EDIT_POPMARK, 16384)
      buildmenuitem menuname, 8, 822, SWAP_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+'SHIFT_KEY__MSG'+=', 'SWAPMARK'SWAP_MARK_MENUP__MSG,  0, mpfrom2short(HP_EDIT_SWAPMARK, 16384)
      buildmenuitem menuname, 8, 823, PUSH_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'DOWN_KEY__MSG, 'PUSHPOS'PUSH_CURSOR_MENUP__MSG,  0, mpfrom2short(HP_EDIT_PUSHPOS, 0)
      buildmenuitem menuname, 8, 824, POP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+'UP_KEY__MSG, 'POPPOS'POP_CURSOR_MENUP__MSG,   0, mpfrom2short(HP_EDIT_POPPOS, 16384)
      buildmenuitem menuname, 8, 825, SWAP_CURSOR_MENU__MSG\9 || CTRL_KEY__MSG'+=', 'SWAPPOS'SWAP_CURSOR_MENUP__MSG,   0, mpfrom2short(HP_EDIT_SWAPPOS, 16384)
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
compile endif  -- WANT_STACK_CMDS
      buildmenuitem menuname, 8, 813, \0,                               '',          4, 0
compile if ENHANCED_PRINT_SUPPORT
      buildmenuitem menuname, 8, 814, PRT_MARK_MENU__MSG'...',          'PRINTDLG M'ENHPRT_MARK_MENUP__MSG,0, mpfrom2short(HP_EDIT_ENHPRINT, 0)
compile else
      buildmenuitem menuname, 8, 814, PRT_MARK_MENU__MSG,               'DUPMARK P'PRT_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_PRINT, 0)
compile endif
   return

defproc add_search_menu(menuname)
   buildsubmenu menuname, 3, SEARCH_BAR__MSG, ''SEARCH_BARP__MSG, 0 , mpfrom2short(HP_SEARCH, 0)
      buildmenuitem menuname, 3, 300, SEARCH_MENU__MSG\9 || CTRL_KEY__MSG'+S',      'SEARCHDLG'SEARCH_MENUP__MSG,   0, mpfrom2short(HP_SEARCH_SEARCH, 0)
      buildmenuitem menuname, 3, 301, \0,                           '',            4, 0
      buildmenuitem menuname, 3, 302, FIND_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+F',   'SEARCHDLG F'FIND_NEXT_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_FIND, 0)
      buildmenuitem menuname, 3, 303, CHANGE_NEXT_MENU__MSG\9 || CTRL_KEY__MSG'+C', 'SEARCHDLG C'CHANGE_NEXT_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_CHANGE, 0)
compile if WANT_BOOKMARKS
      buildmenuitem menuname, 3, 304, \0,                           '',            4, 0
      buildmenuitem menuname, 3, 305, BOOKMARKS_MENU__MSG,   BOOKMARKS_MENUP__MSG, 17, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 306, SET_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+M',  'setmark'SET_MARK_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 308, LIST_MARK_MENU__MSG\9 || CTRL_KEY__MSG'+B', 'listmark'LIST_MARK_MENUP__MSG,       0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 310, \0,                  '',               4, 0
         buildmenuitem menuname, 3, 311, NEXT_MARK_MENU__MSG\9 || ALT_KEY__MSG'+/',  'nextbookmark'NEXT_MARK_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
         buildmenuitem menuname, 3, 312, PREV_MARK_MENU__MSG\9 || ALT_KEY__MSG'+\',  'nextbookmark P'PREV_MARK_MENUP__MSG, 32768+1, mpfrom2short(HP_SEARCH_BOOKMARKS, 0)
compile endif
compile if WANT_TAGS
      buildmenuitem menuname, 3, 320, \0,                           '',            4, 0
      buildmenuitem menuname, 3, 330, TAGS_MENU__MSG,   TAGS_MENUP__MSG, 17, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 331, TAGSDLG_MENU__MSG\9, 'poptagsdlg'TAGSDLG_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 332, \0,                  '',               4, 0
         buildmenuitem menuname, 3, 333, FIND_TAG_MENU__MSG\9 || SHIFT_KEY__MSG'+F6',  'findtag'FIND_TAG_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 334, FIND_TAG2_MENU__MSG\9 || SHIFT_KEY__MSG'+F7', 'findtag *'FIND_TAG2_MENUP__MSG, 0, mpfrom2short(HP_SEARCH_TAGS, 0)
         buildmenuitem menuname, 3, 339, \0,                               '',          4, 0
         buildmenuitem menuname, 3, 340, SCAN_TAGS_MENU__MSG,  'tagscan'SCAN_TAGS_MENUP__MSG, 32769, mpfrom2short(HP_SEARCH_TAGS, 0)
compile endif
   return

; Preferences pull-right can get Set enter, Advanced mark, Stream mode, and
; Ring enabled, in addition to Configure.  Here we calculate which menu item
; gets the "end pullright" attribute.
define
   NEED_PREFERENCES = 1  -- Start out assuming this
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   ENTER__ATTRIB  = 0
   MARK__ATTRIB   = 0
   STREAM__ATTRIB = 0
   RING__ATTRIB   = 0
   STACK__ATTRIB  = 0
   ACCEL__ATTRIB  = 32769
compile elseif WANT_STACK_CMDS = 'SWITCH'
   ENTER__ATTRIB  = 0
   MARK__ATTRIB   = 0
   STREAM__ATTRIB = 0
   RING__ATTRIB   = 0
   STACK__ATTRIB  = 32769
compile elseif RING_OPTIONAL
   ENTER__ATTRIB  = 0
   MARK__ATTRIB   = 0
   STREAM__ATTRIB = 0
   RING__ATTRIB   = 32769
compile elseif WANT_STREAM_MODE = 'SWITCH'
   ENTER__ATTRIB  = 0
   MARK__ATTRIB   = 0
   STREAM__ATTRIB = 32769
compile elseif WANT_CUA_MARKING = 'SWITCH'
   ENTER__ATTRIB  = 0
   MARK__ATTRIB   = 32769
compile else
   NEED_PREFERENCES = 0  -- If none of the above, we don't need this after all
compile endif
   TOGGLEINFO = 'toggleframe 32'

compile if WANT_NODISMISS_MENUS
define
   NODISMISS = 32
compile else
define
   NODISMISS = 0
compile endif -- WANT_NODISMISS_MENUS

defproc add_options_menu(menuname)
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
   universal font
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif

   buildsubmenu menuname, 4, OPTIONS_BAR__MSG, OPTIONS_BARP__MSG, 0 , mpfrom2short(HP_OPTIONS, 0)
compile if RING_OPTIONAL
   if ring_enabled then
compile endif
      buildmenuitem menuname, 4, 410, LIST_FILES_MENU__MSG\9 || CTRL_KEY__MSG'+G',     'Ring_More'LIST_FILES_MENUP__MSG,  0 , mpfrom2short(HP_OPTIONS_LIST, 0)
      buildmenuitem menuname, 4, 411, \0,                       '',           4, 0
compile if RING_OPTIONAL
   endif
compile endif
compile if SPELL_SUPPORT
 compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
 compile endif
      buildmenuitem menuname, 4, 404, PROOF_MENU__MSG,           'proof'PROOF_MENUP__MSG,     0, mpfrom2short(HP_OPTIONS_PROOF, 0)
      buildmenuitem menuname, 4, 405, PROOF_WORD_MENU__MSG,      'proofword'PROOF_WORD_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_PROOFW, 0)
      buildmenuitem menuname, 4, 406, SYNONYM_MENU__MSG,         'syn'SYNONYM_MENUP__MSG,       0, mpfrom2short(HP_OPTIONS_SYN, 0)
      buildmenuitem menuname, 4, 450, DYNASPELL_MENU__MSG,        'dynaspell'DYNASPELL_MENUP__MSG,       0, mpfrom2short(HP_OPTIONS_DYNASPELL, 0)
 compile if CORE_STUFF
      buildmenuitem menuname, 4, 426, DEFINE_WORD_MENU__MSG,     'define'DEFINE_WORD_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_DEFINE, 0)
 compile endif  -- CORE_STUFF
      buildmenuitem menuname, 4, 407, \0,           '',                       4, 0
 compile if CHECK_FOR_LEXAM
   endif
 compile endif
compile endif  -- SPELL_SUPPORT
; If no "Toggle stream mode" or "Toggle advanced marking" or "Enable ring", then
; place "Configure..." on main Options menu.  Otherwise, put it on a Preferences
; pull-right with the other stuff.
compile if NEED_PREFERENCES
      buildmenuitem menuname, 4, 400, PREFERENCES_MENU__MSG,    PREFERENCES_MENUP__MSG,  17, mpfrom2short(HP_OPTIONS_PREFERENCES, 0)
compile endif
compile if WANT_APPLICATION_INI_FILE
         buildmenuitem menuname, 4, 440, CONFIG_MENU__MSG,         'configdlg'CONFIG_MENUP__MSG,  0, mpfrom2short(HP_OPTIONS_CONFIG, 0)
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
         buildmenuitem menuname, 4, 441, ADVANCEDMARK_MENU__MSG,     'CUA_MARK_toggle'ADVANCEDMARK_MENUP__MSG, MARK__ATTRIB, mpfrom2short(HP_OPTIONS_CUATOGGLE, NODISMISS)
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
         buildmenuitem menuname, 4, 442, STREAMMODE_MENU__MSG,  'stream_toggle'STREAMMODE_MENUP__MSG,  STREAM__ATTRIB, mpfrom2short(HP_OPTIONS_STREAM, NODISMISS)
compile endif
compile if RING_OPTIONAL
         buildmenuitem menuname, 4, 443, RINGENABLED_MENU__MSG,    'ring_toggle'RINGENABLED_MENUP__MSG,  RING__ATTRIB, mpfrom2short(HP_OPTIONS_RINGENABLE, 0)
compile endif
compile if WANT_STACK_CMDS = 'SWITCH'
         buildmenuitem menuname, 4, 445, STACKCMDS_MENU__MSG,      'stack_toggle'STACKCMDS_MENUP__MSG,  STACK__ATTRIB, mpfrom2short(HP_OPTIONS_STACKCMDS, 0)
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
         buildmenuitem menuname, 4, 446, CUAACCEL_MENU__MSG,       'accel_toggle'CUAACCEL_MENUP__MSG,  ACCEL__ATTRIB, mpfrom2short(HP_OPTIONS_CUAACCEL, NODISMISS)
compile endif
      buildmenuitem menuname, 4, 401, \0,                       '',           4, 0
      buildmenuitem menuname, 4, 402, AUTOSAVE_MENU__MSG,       'autosave ?'AUTOSAVE_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_AUTOSAVE, 0)
      buildmenuitem menuname, 4, 403, \0,                       '',           4, 0
      buildmenuitem menuname, 4, 412, MESSAGES_MENU__MSG,       'messagebox'MESSAGES_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_MESSAGES, 0)
      buildmenuitem menuname, 4, 409, \0,           '',                       4, 0
;  Note:  408 is referenced by TOGGLEFONT.  If the number changes, update TOGGLEFONT.

      buildmenuitem menuname, 4, 425, FRAME_CTRLS_MENU__MSG, FRAME_CTRLS_MENUP__MSG, 17, mpfrom2short(HP_OPTIONS_FRAME, 0)
         buildmenuitem menuname, 4, 413, STATUS_LINE_MENU__MSG, 'toggleframe 1'STATUS_LINE_MENUP__MSG, 0, mpfrom2short(HP_FRAME_STATUS, NODISMISS)
         buildmenuitem menuname, 4, 414, MSG_LINE_MENU__MSG,    'toggleframe 2'MSG_LINE_MENUP__MSG, 0, mpfrom2short(HP_FRAME_MESSAGE, NODISMISS)
         buildmenuitem menuname, 4, 415, SCROLL_BARS_MENU__MSG, 'setscrolls'SCROLL_BARS_MENUP__MSG,      0, mpfrom2short(HP_FRAME_SCROLL, NODISMISS)
;;       buildmenuitem menuname, 4, 416, 'Partial te~xt',       'togglecontrol 15', 32768+1, 0, 0
         buildmenuitem menuname, 4, 417, ROTATEBUTTONS_MENU__MSG,'toggleframe 4'ROTATEBUTTONS_MENUP__MSG, 0, mpfrom2short(HP_FRAME_ROTATE, NODISMISS)
compile if WANT_TOOLBAR
; compile if WANT_NODISMISS_MENUS
         buildmenuitem menuname, 4, 430, TOGGLETOOLBAR_MENU__MSG, 'toggle_toolbar'TOGGLETOOLBAR_MENUP__MSG, 1, mpfrom2short(HP_TOOLBAR_TOGGLE, NODISMISS)
; compile else
;        buildmenuitem menuname, 4, 430, TOGGLETOOLBAR_MENU__MSG, 'toggleframe' EFRAMEF_TOOLBAR||TOGGLETOOLBAR_MENUP__MSG, 1, mpfrom2short(HP_TOOLBAR_TOGGLE, NODISMISS)
; compile endif -- if WANT_NODISMISS_MENUS
compile endif -- WANT_TOOLBAR
         buildmenuitem menuname, 4, 437, TOGGLEBITMAP_MENU__MSG,'toggle_bitmap'TOGGLEBITMAP_MENUP__MSG, 0, mpfrom2short(HP_FRAME_BITMAP, NODISMISS)
         buildmenuitem menuname, 4, 439, \0,                       '',           4, 0
compile if WANT_DYNAMIC_PROMPTS
         buildmenuitem menuname, 4, 421, INFOATTOP_MENU__MSG,   TOGGLEINFO || INFOATTOP_MENUP__MSG,     0, mpfrom2short(HP_FRAME_EXTRAPOS, NODISMISS)
         buildmenuitem menuname, 4, 422, PROMPTING_MENU__MSG,   'toggleprompt'PROMPTING_MENUP__MSG,     32768+1, mpfrom2short(HP_FRAME_PROMPT, NODISMISS)
compile else
         buildmenuitem menuname, 4, 421, INFOATTOP_MENU__MSG,   TOGGLEINFO || INFOATTOP_MENUP__MSG,     32768+1, mpfrom2short(HP_FRAME_EXTRAPOS, NODISMISS)
compile endif
compile if WANT_APPLICATION_INI_FILE
      buildmenuitem menuname, 4, 418, SAVE_OPTS_MENU__MSG,      'saveoptions'SAVE_OPTS_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_SAVE, 0)
compile endif
compile if SUPPORT_BOOK_ICON
      buildmenuitem menuname, 4, 419, \0,                       '',           4, 0
      buildmenuitem menuname, 4, 420, TO_BOOK_MENU__MSG,        'popbook'TO_BOOK_MENUP__MSG, 0, mpfrom2short(HP_OPTIONS_BOOK, 0)
compile endif
   return

defproc add_command_menu(menuname)
   buildsubmenu menuname, 1, COMMAND_BAR__MSG, COMMAND_BARP__MSG, 0 , mpfrom2short(HP_COMMAND, 0)
      buildmenuitem menuname, 1, 100, COMMANDLINE_MENU__MSG\9 || CTRL_KEY__MSG'+I', 'commandline'COMMANDLINE_MENUP__MSG,   0, mpfrom2short(HP_COMMAND_CMD, 0)
      buildmenuitem menuname, 1, 65535, HALT_COMMAND_MENU__MSG, '', 0, mpfrom2short(HP_COMMAND_HALT, 0)
compile if WANT_EPM_SHELL = 1
      buildmenuitem menuname, 1, 101, \0,                      '',            4, 0
      buildmenuitem menuname, 1, 102, CREATE_SHELL_MENU__MSG,       'shell'CREATE_SHELL_MENUP__MSG,       0, mpfrom2short(HP_COMMAND_SHELL, 0)
      buildmenuitem menuname, 1, 103, WRITE_SHELL_MENU__MSG,        'shell_write'WRITE_SHELL_MENUP__MSG, 0, mpfrom2short(HP_COMMAND_WRITE, 16384)
;     buildmenuitem menuname, 1, 104, KILL_SHELL_MENU__MSG,         'shell_kill'KILL_SHELL_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_KILL, 16384)
      buildmenuitem menuname, 1, 104, SHELL_BREAK_MENU__MSG,        'shell_break'SHELL_BREAK_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_BREAK, 16384)
compile endif
   return

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
-- Todo: replace all strings and add consts for menu styles ------------------------------------------------------
      buildmenuitem menuname, HELP_MENU_ID, 609, 'NEPMD runtime information', 'nepmdinfo', 0, 0
      buildmenuitem menuname, HELP_MENU_ID, 610, \0,           '',                        4, 0
      buildmenuitem menuname, HELP_MENU_ID, 640, 'View NEPMD Online Help', ''\1, 17+64, 0
         buildmenuitem menuname, HELP_MENU_ID, 641, 'View NEPMD Online Help', 'view nepmd'\1, 0, 0
         buildmenuitem menuname, HELP_MENU_ID, 642, 'Current word', 'viewword nepmd'\1, 32768+1, 0
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

defproc readd_help_menu
   universal defaultmenu, activemenu
   call add_help_menu(defaultmenu)
   call maybe_show_menu()

defproc maybe_show_menu
   universal defaultmenu, activemenu
   if activemenu=defaultmenu then
      call showmenu_activemenu()  -- show the updated EPM menu
   endif

defproc showmenu_activemenu()
   universal activemenu
   showmenu activemenu  -- show the updated EPM menu
   'postme cascade_menu 640'  -- NEPMD Online Help
compile if SUPPORT_USERS_GUIDE
   'postme cascade_menu 620'
compile endif
compile if SUPPORT_TECHREF
   'postme cascade_menu 630'
compile endif
compile if defined(CUSTEPM_DEFAULT_SCREEN)
   'postme cascade_menu' 3700 (CUSTEPM_DEFAULT_SCREEN + 3700)
compile elseif defined(HAVE_CUSTEPM)
   'postme cascade_menu' 3700
compile endif

defproc build_menu_accelerators(activeaccel)
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif
compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
compile endif
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
   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  67, 1201  -- a+C
   buildacceltable activeaccel, 'dokey a+C', AF_CHAR+AF_ALT,                  99, 1202  -- a+c
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
   buildacceltable activeaccel, 'copy2clip', AF_VIRTUALKEY+AF_CONTROL, VK_INSERT, 1213  -- c+Insert
   buildacceltable activeaccel, 'cut',       AF_VIRTUALKEY+AF_SHIFT,   VK_DELETE, 1214  -- s+Delete
   buildacceltable activeaccel, 'paste' DEFAULT_PASTE, AF_VIRTUALKEY+AF_SHIFT,   VK_INSERT, 1215  -- s+Insert
   buildacceltable activeaccel, 'paste' ALTERNATE_PASTE, AF_VIRTUALKEY+AF_SHIFT+AF_CONTROL,   VK_INSERT, 1221  -- c+s+Insert
   buildacceltable activeaccel, 'dokey F9',  AF_VIRTUALKEY,                VK_F9, 1216  -- F9
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,              89, 1217  -- c+Y
   buildacceltable activeaccel, 'dokey c+Y', AF_CHAR+AF_CONTROL,             121, 1218  -- c+y
   buildacceltable activeaccel, 'select_all',AF_CHAR+AF_CONTROL,              47, 1219  -- c+/
   buildacceltable activeaccel, 'DUPMARK U', AF_CHAR+AF_CONTROL,              92, 1220  -- c+\

compile if WANT_STACK_CMDS
 compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
 compile endif
   buildacceltable activeaccel, 'dokey c+down', AF_VIRTUALKEY+AF_CONTROL,   VK_DOWN, 1222  -- c+Down
   buildacceltable activeaccel, 'dokey c+Up',   AF_VIRTUALKEY+AF_CONTROL,     VK_UP, 1223  -- c+Up
 compile if WANT_STACK_CMDS = 'SWITCH'
   endif
 compile endif
   buildacceltable activeaccel, 'swappos',  AF_CHAR+AF_CONTROL,                     61, 1224  -- c+=
   buildacceltable activeaccel, 'pushmark', AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT, VK_DOWN, 1225  -- c+s+Down
   buildacceltable activeaccel, 'popmark',  AF_VIRTUALKEY+AF_CONTROL+AF_SHIFT,   VK_UP, 1226  -- c+s+Up
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            61, 1227  -- c+s+=
   buildacceltable activeaccel, 'swapmark', AF_CHAR+AF_CONTROL+AF_SHIFT,            43, 1228  -- c+s++
compile endif

                       -- Build keys on Search menu
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,              83, 1301  -- c+S
   buildacceltable activeaccel, 'dokey c+S', AF_CHAR+AF_CONTROL,             115, 1302  -- c+s
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,              70, 1303  -- c+F
   buildacceltable activeaccel, 'dokey c+F', AF_CHAR+AF_CONTROL,             102, 1304  -- c+f
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              67, 1305  -- c+C
   buildacceltable activeaccel, 'dokey c+C', AF_CHAR+AF_CONTROL,              99, 1306  -- c+c
                       -- Build keys on Bookmark submenu
compile if WANT_BOOKMARKS
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              66, 1331  -- c+B
   buildacceltable activeaccel, 'dokey c+B', AF_CHAR+AF_CONTROL,              98, 1332  -- c+b
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,              77, 1333  -- c+M
   buildacceltable activeaccel, 'dokey c+M', AF_CHAR+AF_CONTROL,             109, 1334  -- c+m
   buildacceltable activeaccel, 'nextbookmark',  AF_CHAR+AF_ALT,              47, 1335  -- a+/
   buildacceltable activeaccel, 'nextbookmark P',AF_CHAR+AF_ALT,              92, 1336  -- a+\
compile endif
                       -- Build keys on Tags submenu
compile if WANT_TAGS
   buildacceltable activeaccel, 'dokey s+F6', AF_VIRTUALKEY+AF_SHIFT,      VK_F6, 1361  -- s+F6
   buildacceltable activeaccel, 'dokey s+F7', AF_VIRTUALKEY+AF_SHIFT,      VK_F7, 1362  -- s+F7
   buildacceltable activeaccel, 'dokey s+F8', AF_VIRTUALKEY+AF_SHIFT,      VK_F8, 1363  -- s+F8
   buildacceltable activeaccel, 'dokey s+F9', AF_VIRTUALKEY+AF_SHIFT,      VK_F9, 1364  -- s+F9
compile endif

                       -- Build keys on Options menu
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,              71, 1401  -- c+G
   buildacceltable activeaccel, 'dokey c+G', AF_CHAR+AF_CONTROL,             103, 1402  -- c+g

                       -- Build keys on Command menu
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,              73, 1501  -- c+I
   buildacceltable activeaccel, 'dokey c+I', AF_CHAR+AF_CONTROL,             105, 1502  -- c+i

                       -- Block action bar accelerator keys (English)
compile if BLOCK_ACTIONBAR_ACCELERATORS
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   if not CUA_MENU_ACCEL then
 compile endif
      buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A1   , 1001  -- a+F
      buildacceltable activeaccel, 'dokey a+'FILE_ACCEL__L,    AF_CHAR+AF_ALT, FILE_ACCEL__A2   , 1002  -- a+f
      buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A1   , 1003  -- a+E
      buildacceltable activeaccel, 'dokey a+'EDIT_ACCEL__L,    AF_CHAR+AF_ALT, EDIT_ACCEL__A2   , 1004  -- a+e
      buildacceltable activeaccel, 'dokey a+'SEARCH_ACCEL__L,  AF_CHAR+AF_ALT, SEARCH_ACCEL__A1 , 1005  -- a+S
      buildacceltable activeaccel, 'dokey a+'SEARCH_ACCEL__L,  AF_CHAR+AF_ALT, SEARCH_ACCEL__A2 , 1006  -- a+s
      buildacceltable activeaccel, 'dokey a+'OPTIONS_ACCEL__L, AF_CHAR+AF_ALT, OPTIONS_ACCEL__A1, 1007  -- a+O
      buildacceltable activeaccel, 'dokey a+'OPTIONS_ACCEL__L, AF_CHAR+AF_ALT, OPTIONS_ACCEL__A2, 1008  -- a+o
      buildacceltable activeaccel, 'dokey a+'COMMAND_ACCEL__L, AF_CHAR+AF_ALT, COMMAND_ACCEL__A1, 1009  -- a+C
      buildacceltable activeaccel, 'dokey a+'COMMAND_ACCEL__L, AF_CHAR+AF_ALT, COMMAND_ACCEL__A2, 1010  -- a+c
      buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A1   , 1011  -- a+H
      buildacceltable activeaccel, 'dokey a+'HELP_ACCEL__L,    AF_CHAR+AF_ALT, HELP_ACCEL__A2   , 1012  -- a+h
 compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
      buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A1, 1017  -- a+A
      buildacceltable activeaccel, 'dokey a+'ACTIONS_ACCEL__L, AF_CHAR+AF_ALT, ACTIONS_ACCEL__A2, 1018  -- a+a
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   endif -- CUA_MENU_ACCEL
 compile endif
compile endif -- BLOCK_ACTIONBAR_ACCELERATORS

compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
define  -- Prepare for some conditional tests
   maybe_ring_accel = "' ' ="  -- Will be false for any letter
 compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   maybe_actions_accel = 'ACTIONS_ACCEL__L ='
 compile else
   maybe_actions_accel = "' ' ="  -- Will be false for any letter
 compile endif

defproc update_edit_menu_text =
   universal CUA_MENU_ACCEL
   accel_len = (3+length(ALT_KEY__MSG))*(not CUA_MENU_ACCEL)

 compile if FILE_ACCEL__L = 'C' | EDIT_ACCEL__L = 'C' | SEARCH_ACCEL__L = 'C' | OPTIONS_ACCEL__L = 'C' | COMMAND_ACCEL__L = 'C' | HELP_ACCEL__L = 'C' | $maybe_ring_accel 'C' | $maybe_actions_accel 'C'
   menutext = COPY_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+C', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      800 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'M' | EDIT_ACCEL__L = 'M' | SEARCH_ACCEL__L = 'M' | OPTIONS_ACCEL__L = 'M' | COMMAND_ACCEL__L = 'M' | HELP_ACCEL__L = 'M' | $maybe_ring_accel 'M' | $maybe_actions_accel 'M'
   menutext = MOVE_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+M', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      801 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'O' | EDIT_ACCEL__L = 'O' | SEARCH_ACCEL__L = 'O' | OPTIONS_ACCEL__L = 'O' | COMMAND_ACCEL__L = 'O' | HELP_ACCEL__L = 'O' | $maybe_ring_accel 'O' | $maybe_actions_accel 'O'
   menutext = OVERLAY_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+O', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      802 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'A' | EDIT_ACCEL__L = 'A' | SEARCH_ACCEL__L = 'A' | OPTIONS_ACCEL__L = 'A' | COMMAND_ACCEL__L = 'A' | HELP_ACCEL__L = 'A' | $maybe_ring_accel 'A' | $maybe_actions_accel 'A'
   menutext = ADJUST_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+A', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      803 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'U' | EDIT_ACCEL__L = 'U' | SEARCH_ACCEL__L = 'U' | OPTIONS_ACCEL__L = 'U' | COMMAND_ACCEL__L = 'U' | HELP_ACCEL__L = 'U' | $maybe_ring_accel 'U' | $maybe_actions_accel 'U'
   menutext = UNMARK_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+U', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      805 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

 compile if FILE_ACCEL__L = 'D' | EDIT_ACCEL__L = 'D' | SEARCH_ACCEL__L = 'D' | OPTIONS_ACCEL__L = 'D' | COMMAND_ACCEL__L = 'D' | HELP_ACCEL__L = 'D' | $maybe_ring_accel 'D' | $maybe_actions_accel 'D'
   menutext = DELETE_MARK_MENU__MSG || leftstr(\9 || ALT_KEY__MSG'+D', accel_len)\0
   call windowmessage(1, getpminfo(EPMINFO_EDITMENUHWND),
                      398,                  -- x18e, MM_SetItemText
                      806 + 65536,
                      ltoa(offset(menutext) || selector(menutext), 10) )
 compile endif

compile endif  -- BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
