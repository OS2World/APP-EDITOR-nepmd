/****************************** Module Header *******************************
*
* Module Name: obsolete.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: obsolete.e,v 1.3 2008-11-13 13:46:49 aschn Exp $
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

; Obsolete consts, that were deleted from NEPMD files. They are redefined
; here for compatibility: That saves a user from editing his E source, if
; he still uses them in his own code or in an additional package.
; Additionally, it's a good place to lookup for all consts that can be
; removed, if he wants that.

const
compile if not defined(WANT_NODISMISS_MENUS)
   WANT_NODISMISS_MENUS = 1
compile endif
compile if not defined(DEFAULT_PASTE)
   DEFAULT_PASTE = 'C'
compile endif
compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
compile endif
compile if not defined(ALLOW_PROMPTING_AT_TOP)
   ALLOW_PROMPTING_AT_TOP = 1
compile endif
compile if not defined(WANT_TINY_ICONS)
   WANT_TINY_ICONS = 0
compile endif
compile if not defined(RESPECT_SCROLL_LOCK)
   RESPECT_SCROLL_LOCK = 1
compile endif
compile if not defined(BLOCK_ACTIONBAR_ACCELERATORS)
   BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
compile endif
compile if not defined(WANT_STACK_CMDS)
   WANT_STACK_CMDS = 'SWITCH'
compile endif
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
compile if not defined(WANT_TOOLBAR)
   WANT_TOOLBAR = 1
compile endif
compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 'DYNALINK'
compile endif
compile if not defined(ENHANCED_PRINT_SUPPORT)
   ENHANCED_PRINT_SUPPORT = 1
compile endif
compile if not defined(WANT_DM_BUFFER)
   WANT_DM_BUFFER = 1
compile endif
compile if not defined(WANT_APPLICATION_INI_FILE)
   WANT_APPLICATION_INI_FILE = 1
compile endif
compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
compile endif
compile if not defined(TEMP_FILENAME)
   TEMP_FILENAME= 'e.tmp'
compile endif
compile if not defined(TEMP_PATH)
   TEMP_PATH=''
compile endif
compile if not defined(BACKUP_PATH)
   BACKUP_PATH = ''
compile endif
compile if not defined(AUTOSAVE_PATH)
   AUTOSAVE_PATH=''
compile endif
compile if not defined(DEFAULT_AUTOSAVE)
   DEFAULT_AUTOSAVE = 100
compile endif
compile if not defined(EPATH)
   EPATH= 'epmpath'
compile endif
compile if not defined(MAINFILE)
   MAINFILE= 'epm.e'
compile endif
compile if not defined(WANT_ET_COMMAND)
   WANT_ET_COMMAND = 1
compile endif
compile if not defined(WANT_CHAR_OPS)
   WANT_CHAR_OPS = 1
compile endif
compile if not defined(ALTERNATE_KEYSETS)
   ALTERNATE_KEYSETS = 1
compile endif
compile if not defined(C_SYNTAX_ASSIST)
   C_SYNTAX_ASSIST = 1
compile endif
compile if not defined(CPP_SYNTAX_ASSIST)
   CPP_SYNTAX_ASSIST = C_SYNTAX_ASSIST
compile endif
compile if not defined(C_TABS)
   C_TABS    = '3'
compile endif
compile if not defined(C_MARGINS)
   C_MARGINS = 1 MAXMARGIN 1
compile endif
compile if not defined(E_SYNTAX_ASSIST)
   E_SYNTAX_ASSIST = 1
compile endif
compile if not defined(E_TABS)
   E_TABS    = '3'
compile endif
compile if not defined(E_MARGINS)
   E_MARGINS = 1 MAXMARGIN 1
compile endif
compile if not defined(REXX_SYNTAX_ASSIST)
   REXX_SYNTAX_ASSIST = 1
compile endif
compile if not defined(REXX_TABS)
   REXX_TABS    = '3'
compile endif
compile if not defined(REXX_MARGINS)
   REXX_MARGINS = 1 MAXMARGIN 1
compile endif
compile if not defined(P_SYNTAX_ASSIST)
   P_SYNTAX_ASSIST = 1
compile endif
compile if not defined(P_TABS)
   P_TABS    = '3'
compile endif
compile if not defined(P_MARGINS)
   P_MARGINS = 1 MAXMARGIN 1
compile endif
compile if not defined(DEFAULT_TABS)
   DEFAULT_TABS    = '8'
compile endif
compile if not defined(DEFAULT_MARGINS)
   DEFAULT_MARGINS = 1 MAXMARGIN 1
compile endif
compile if not defined(ASSIST_TRIGGER)
   ASSIST_TRIGGER = 'ENTER'
compile endif
compile if not defined(SYNTAX_INDENT)
   SYNTAX_INDENT = 3
compile endif
compile if not defined(WANT_BRACKET_MATCHING)
   WANT_BRACKET_MATCHING = 1
compile endif
compile if not defined(REFLOW_LIKE_PE)
   REFLOW_LIKE_PE = 1
compile endif
compile if not defined(WANT_DRAW)
   WANT_DRAW = 'F6'
compile endif
compile if not defined(SORT_TYPE)
   SORT_TYPE = 'EPM'
compile endif
compile if not defined(USE_APPEND)
   USE_APPEND = 0
compile endif
compile if not defined(SETSTAY)
   SETSTAY = '?'
compile endif
compile if not defined(WANT_TABS)
   WANT_TABS = 1
compile endif
compile if not defined(WANT_SEARCH_PATH)
   WANT_SEARCH_PATH = 1
compile endif
compile if not defined(WANT_GET_ENV)
   WANT_GET_ENV = 1
compile endif
compile if not defined(WANT_LAN_SUPPORT)
   WANT_LAN_SUPPORT = 1
compile endif
compile if not defined(WANT_MATH)
   WANT_MATH = '?'
compile endif
compile if not defined(INCLUDE_MATHLIB)
   INCLUDE_MATHLIB = 0
compile endif
compile if not defined(WANT_DOSUTIL)
   WANT_DOSUTIL = '?'
compile endif
compile if not defined(WANT_ALL)
   WANT_ALL = 1
compile endif
compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 'DYNALINK'
compile endif
compile if not defined(ENHANCED_PRINT_SUPPORT)
   ENHANCED_PRINT_SUPPORT = 1
compile endif
compile if not defined(WANT_EPM_SHELL)
   WANT_EPM_SHELL = 1
compile endif
compile if not defined(WANT_LONGNAMES)
   WANT_LONGNAMES = 'SWITCH'
compile endif
compile if not defined(WANT_CUA_MARKING)
   WANT_CUA_MARKING = 'SWITCH'
compile endif
compile if not defined(MOUSE_SUPPORT)
   MOUSE_SUPPORT = 1
compile endif
compile if not defined(ENHANCED_ENTER_KEYS)
   ENHANCED_ENTER_KEYS = 1
compile endif
compile if not defined(WANT_STREAM_INDENTED)
   WANT_STREAM_INDENTED = 1
compile endif
compile if not defined(TRASH_TEMP_FILES)
   TRASH_TEMP_FILES = 1
compile endif
compile if not defined(RING_OPTIONAL)
   RING_OPTIONAL = 1
compile endif
compile if not defined(UNDERLINE_CURSOR)
   UNDERLINE_CURSOR = 0
compile endif
compile if not defined(EPM_POINTER)
   EPM_POINTER = 'SWITCH'
compile endif
compile if not defined(EXTRA_EX)
   EXTRA_EX = 0
compile endif
compile if not defined(WANT_KEYWORD_HELP)
   WANT_KEYWORD_HELP = 'DYNALINK'
compile endif
compile if not defined(WANT_REXX)
   WANT_REXX = 1
compile endif
compile if not defined(WANT_PROFILE)
   WANT_PROFILE = 'SWITCH'
compile endif
compile if not defined(TOGGLE_ESCAPE)
   TOGGLE_ESCAPE = 1
compile endif
compile if not defined(TOGGLE_TAB)
   TOGGLE_TAB = 1
compile endif
compile if not defined(INCLUDE_MENU_SUPPORT)
   INCLUDE_MENU_SUPPORT = 1
compile endif
compile if not defined(INCLUDE_STD_MENUS)
   INCLUDE_STD_MENUS = 1
compile endif
compile if not defined(KEEP_CURSOR_ON_SCREEN)
   KEEP_CURSOR_ON_SCREEN = 1
compile endif
compile if not defined(UNMARK_AFTER_MOVE)
   UNMARK_AFTER_MOVE = 0
compile endif
compile if not defined(WANT_SYS_MONOSPACED)
   WANT_SYS_MONOSPACED = 1
compile endif
compile if not defined(SYS_MONOSPACED_SIZE)
   SYS_MONOSPACED_SIZE = 10
compile endif
compile if not defined(WANT_TREE)
   WANT_TREE = 'DYNALINK'
compile endif
compile if not defined(DYNAMIC_CURSOR_STYLE)
   DYNAMIC_CURSOR_STYLE = 1
compile endif
compile if not defined(WANT_SHIFT_MARKING)
   WANT_SHIFT_MARKING = EPM
compile endif
   WPS_SUPPORT = 0

; No effect in standard EPM
compile if not defined(DELAY_SAVEPATH_CHECK)
   DELAY_SAVEPATH_CHECK = 0
compile endif
compile if not defined(WANT_RETRIEVE)
   WANT_RETRIEVE = 0
compile endif
compile if not defined(SMARTQUIT)
   SMARTQUIT = 0
compile endif
compile if not defined(FILEKEY)
   FILEKEY   = 'F4'
compile endif
compile if not defined(WANT_WINDOWS)
   WANT_WINDOWS = 0
compile endif
compile if not defined(DELAY_MENU_CREATION)
   DELAY_MENU_CREATION = 0
compile endif
compile if not defined(CURSOR_ON_COMMAND)
   CURSOR_ON_COMMAND = 0
compile endif
compile if not defined(ASK_BEFORE_LEAVING)
   --ASK_BEFORE_LEAVING = 0  -- let this undefined
compile endif
compile if not defined(SHELL_USAGE)
   SHELL_USAGE = 0
compile endif

; Unused (replaced) in standard EPM, but working
compile if not defined(MENU_LIMIT)
   MENU_LIMIT = 0
compile endif
compile if not defined(SHOW_MODIFY_METHOD)
   SHOW_MODIFY_METHOD = ''
compile endif
compile if not defined(SUPPORT_BOOK_ICON)
   SUPPORT_BOOK_ICON = 0
compile endif

