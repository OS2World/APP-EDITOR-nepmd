/****************************** Module Header *******************************
*
* Module Name: extra.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: extra.e,v 1.2 2002-07-22 19:00:20 cla Exp $
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
const SMALL = 0            -- SMALL says to assume no host support.
include    'stdconst.e'

include    'colors.e'      -- Mnemonic color names & default colors defined here.

define INCLUDING_FILE = 'EXTRA.E'
const                      -- (added because many users omit from MYCNF.)
tryinclude 'mycnf.e'       -- User configuration goes here.
 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif

const
compile if not defined(EPATH)
  compile if EPM    -- EPM uses a different name, for easier coexistance
   EPATH= 'epmpath'
  compile else
   EPATH= 'epath'
  compile endif
compile endif
compile if EPM
 compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
 compile endif
compile else
   WANT_DYNAMIC_PROMPTS = 0  -- Must be 0 for earlier EPM
compile endif
compile if EPM
 compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 'LINK'
 compile endif
compile if EPM
 compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
 compile endif
compile else
   CHECK_FOR_LEXAM = 0
compile endif
 compile if not defined(MOUSE_SUPPORT)
   MOUSE_SUPPORT = 1
 compile endif
compile else
   WANT_BOOKMARKS = 0
   MOUSE_SUPPORT = 0
compile endif
compile if not defined(VANILLA)
   VANILLA = 0
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
compile if not defined(E_SYNTAX_ASSIST)
   E_SYNTAX_ASSIST = 1
compile endif
compile if not defined(REXX_SYNTAX_ASSIST)
   REXX_SYNTAX_ASSIST = 0
compile endif
compile if not defined(P_SYNTAX_ASSIST)
   P_SYNTAX_ASSIST = 1
compile endif
compile if not defined(SYNTAX_INDENT)
   SYNTAX_INDENT = 3
compile endif

compile if not defined(DECIMAL)
   DECIMAL = '.'
compile endif
compile if not defined(SORT_TYPE)
 compile if EVERSION >= '5.60'       -- At long last - an internal sort.
  SORT_TYPE = 'EPM'
 compile else
  SORT_TYPE = 'DLL'
 compile endif
compile endif
compile if not defined(WANT_CHAR_OPS)
   WANT_CHAR_OPS = 1
compile endif
compile if not defined(USE_APPEND)
   USE_APPEND = 0
compile endif
compile if not defined(WANT_SEARCH_PATH)
   WANT_SEARCH_PATH = 1                  -- Different from STDCNF; assuming more room free.
compile endif
compile if not defined(WANT_GET_ENV)
   WANT_GET_ENV = 1
compile endif
compile if not defined(INCLUDE_MATHLIB)
   INCLUDE_MATHLIB = 0                   -- Included anyway when EXTRA_EX is true.
compile endif
compile if not defined(RESTORE_MARK_AFTER_SORT)
   RESTORE_MARK_AFTER_SORT = 1
compile endif
compile if not defined(WANT_DM_BUFFER)
   WANT_DM_BUFFER = 0
compile endif
compile if not defined(WANT_STREAM_MODE)
   WANT_STREAM_MODE = 0
compile endif
compile if not defined(ENHANCED_ENTER_KEYS)
   ENHANCED_ENTER_KEYS = 0
compile endif
compile if not defined(WANT_STACK_CMDS)
   WANT_STACK_CMDS = 0
compile endif
compile if not defined(WANT_CUA_MARKING)
   WANT_CUA_MARKING = 0
compile endif
compile if not defined(WANT_DBCS_SUPPORT)
   WANT_DBCS_SUPPORT = 0
compile endif
compile if not defined(RING_OPTIONAL)
   RING_OPTIONAL = 0
compile endif
compile if not defined(BLOCK_ACTIONBAR_ACCELERATORS)
   BLOCK_ACTIONBAR_ACCELERATORS = 1
compile endif
compile if not defined(SUPPORT_BOOK_ICON)
;compile if EVERSION < '5.50'
   SUPPORT_BOOK_ICON = 1
;compile else
;  SUPPORT_BOOK_ICON = 0  -- EPM/G has no book (yet)
;compile endif
compile endif
compile if not defined(WANT_ALL)
   WANT_ALL = 0
compile endif
compile if not defined(EXTRA_EX)
   EXTRA_EX = 1                    -- Different than STDCNF.E; but since this *is* EXTRA.E, ...
compile endif
compile if not defined(WANT_KEYWORD_HELP)
   WANT_KEYWORD_HELP = 0
compile endif
compile if not defined(WANT_REXX)
   WANT_REXX = 1
compile endif
compile if not defined(MENU_LIMIT)
   MENU_LIMIT = 0
compile endif
compile if not defined(SPELL_SUPPORT)
 compile if EPM
   SPELL_SUPPORT = 'DYNALINK'          -- New default
 compile else
   SPELL_SUPPORT = 0
 compile endif
compile endif
compile if not defined(ENHANCED_PRINT_SUPPORT)
   ENHANCED_PRINT_SUPPORT = 0
compile endif
compile if not defined(WANT_EPM_SHELL) or EVERSION < '5.20'
   WANT_EPM_SHELL = 0
compile endif
compile if not defined(EPM_SHELL_PROMPT)
   EPM_SHELL_PROMPT = '@prompt epm: $p $g'
compile endif
compile if not defined(WANT_BRACKET_MATCHING)
   WANT_BRACKET_MATCHING = 0
compile endif
compile if not defined(DEFAULT_PASTE) & EPM
   DEFAULT_PASTE = 'C'
compile endif
compile if not defined(INCLUDE_MENU_SUPPORT)
   INCLUDE_MENU_SUPPORT = 1
compile endif
compile if not defined(INCLUDE_STD_MENUS)
   INCLUDE_STD_MENUS = 1
compile endif
compile if not defined(INCLUDE_WORKFRAME_SUPPORT)
   INCLUDE_WORKFRAME_SUPPORT = 1
compile endif
compile if not defined(WANT_EBOOKIE)
   WANT_EBOOKIE = 'DYNALINK'
compile endif
compile if not defined(WANT_TREE)
   WANT_TREE = 'DYNALINK'
compile endif
compile if not defined(WANT_APPLICATION_INI_FILE)
   WANT_APPLICATION_INI_FILE = 1
compile endif
compile if EVERSION < '5.60' | not defined(WANT_TAGS)
   WANT_TAGS = 0
compile endif
compile if not defined(WANT_NODISMISS_MENUS)
   WANT_NODISMISS_MENUS = 1
compile endif
compile if not defined(SUPPORT_USERS_GUIDE)
   SUPPORT_USERS_GUIDE = 0
compile endif
compile if not defined(SUPPORT_TECHREF)
   SUPPORT_TECHREF = 0
compile endif
compile if EVERSION >= 6 and not defined(WANT_TOOLBAR)
   WANT_TOOLBAR = 1
compile elseif EVERSION < 6
   WANT_TOOLBAR = 0  -- Toolbar only supported for EPM 6.00 & above.
compile endif
compile if not defined(NLS_LANGUAGE)
  const NLS_LANGUAGE = 'ENGLISH'
compile endif
   include NLS_LANGUAGE'.e'

compile if EVERSION > 5
   include 'menuhelp.H'
 compile if INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS
  compile if defined(STD_MENU_NAME)
   compile if STD_MENU_NAME = 'STDMENU.E'
   *** Error:  Leave STD_MENU_NAME undefined to use the original menu layout (STDMENU.E).
   compile endif
   include    STD_MENU_NAME   -- Action bar menus for EPM.
  compile else
   include    'stdmenu.e'     -- Action bar menus for EPM.
  compile endif
 compile endif
 compile if WANT_BOOKMARKS
   include 'bookmark.e'
 compile endif
 compile if WANT_TAGS = 1
   include 'tags.e'
 compile endif
 compile if MOUSE_SUPPORT
   include 'mouse.e'
 compile endif
   include 'clipbrd.e'     -- Clipboard interface and mark <--> buffer routines
   include 'EPM_EA.E'
compile endif
   include  'markfilt.e'
   include  'charops.e'     -- Mark operations for character marks.
   include  'dosutil.e'
   include  'math.e'
compile if SORT_TYPE
   include 'sort'SORT_TYPE'.e' -- SORTE, SORTG, SORTF, SORTGW, SORTDLL, SORTDOS.E.
compile endif
compile if WANT_ALL
   include 'ALL.E'         -- Shows all occurrences of a string.
compile endif
compile if WANT_TREE = 1
  include 'tree.e'
compile endif
compile if WANT_KEYWORD_HELP
  include 'KWhelp.e'
compile endif
compile if WANT_EPM_SHELL
  include 'epmshell.e'
compile endif
compile if EVERSION >= '5.50' & WANT_REXX
  include 'callrexx.e'
compile endif
compile if WANT_BRACKET_MATCHING
  include 'assist.e'
compile endif
compile if WANT_EBOOKIE = 1
  include 'bkeys.e'
compile endif
compile if ALTERNATE_KEYSETS
 compile if C_SYNTAX_ASSIST
   tryinclude 'ckeys.e' -- Syntax-assist for C programmers.
 compile endif
 compile if E_SYNTAX_ASSIST
   tryinclude 'ekeys.e' -- Syntax-assist for E programmers.
 compile endif
 compile if REXX_SYNTAX_ASSIST
   tryinclude 'rexxkeys.e' -- Syntax-assist for Rexx programmers.
 compile endif
 compile if P_SYNTAX_ASSIST
   tryinclude 'pkeys.e' -- Syntax-assist for Pascal programmers.
 compile endif
compile endif

compile if not VANILLA
 compile if defined(SITE_EXTRA)
    compile if SITE_EXTRA
       include SITE_EXTRA
    compile endif
 compile endif
tryinclude 'myextra.e'
compile endif

