/****************************** Module Header *******************************
*
* Module Name: epm.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epm.e,v 1.13 2002-10-16 18:27:45 aschn Exp $
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

define INCLUDING_FILE = 'EPM.E'  -- Specify, in case any MY*.E or SITE file cares

const SMALL = 0                -- SMALL says to assume no host support i.e.
                               -- SMALL is undefined if an .e file is compiled separately
                               -- without epm.e
include        'stdconst.e'

include        'colors.e'      -- Mnemonic color names & default colors defined here.

const                          -- (added because many users omit from MYCNF.)
tryinclude     'mycnf.e'       -- User configuration goes here.

compile if not defined(SITE_CONFIG)  -- Did user's MYCNF.E set a SITE_CONFIG file?
   const SITE_CONFIG = 'sitecnf.e'   -- If not, use the default
compile endif
compile if SITE_CONFIG               -- If SITE_CONFIG file was not set to null,
   tryinclude  SITE_CONFIG           -- include the site configuration file.
compile endif

include        'stdcnf.e'      -- Standard configuration; shouldn't be modified.

include        'menuhelp.h'


compile if WANT_DBCS_SUPPORT
   include     'epmdbcs.e'
compile endif

include        'main.e'        -- This contains the DEFMAIN for the main .ex file
compile if not VANILLA
 compile if defined(SITE_MAIN)
  compile if SITE_MAIN
   include     SITE_MAIN
  compile endif
 compile endif
   tryinclude  'mymain.e'      -- Optional user additions to DEFMAIN.
compile endif  -- not VANILLA

include        'load.e'        -- Default defload must come before other defloads.

include        'mode.e'        -- New mode definitions

include        'select.e'
compile if not VANILLA
 compile if defined(SITE_SELECT)
  compile if SITE_SELECT
   include     SITE_SELECT
  compile endif
 compile endif
   tryinclude  'myselect.e'    -- For user's defselects.  This doesn't have to come
                               -- immediately after select.e now.
compile endif  -- not VANILLA
include        'modify.e'      -- New defmodify event processor.

include        'stdkeys.e'     -- Standard key definitions.

compile if    WANT_BRACKET_MATCHING
   include     'assist.e'
compile endif

compile if MOUSE_SUPPORT = 1
   include     'mouse.e'       -- Mouse definition, only for EPM.
compile else
   defc processmouse = sayerror 'Mouse support missing.'
compile endif

include        'stdprocs.e'    -- Standard functions and procedures.

include        'epm_ea.e'
include        'locate.e'
include        'toolbar.e'

include        'markfilt.e'    -- Procedures for filtering a block, line or char. mark.
include        'charops.e'     -- Mark operations for character marks.

include        'edit.e'        -- Edit commands and procedures, moved from STDCMDS.E and STDPROCS.E

compile if HOST_SUPPORT = 'STD'
   include     'saveload.e'    -- Save/load routines with host support
compile elseif HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
   include     'e3emul.e'      -- ... with extended host support
compile elseif HOST_SUPPORT = 'PDQ'
   include     'slpdq.e'       -- ... with host support via PDQ.e
   include     'pdq.e'
   include     'pdqdos.e'      -- pdq.e uses some DOS functions
compile elseif HOST_SUPPORT = 'SRPI'
   include     'slsrpi.e'      -- ... with host support via SRPI interface
compile else
   include     'slnohost.e'    -- ... without host support
compile endif

include        'stdcmds.e'     -- Standard commands (DEFC's).
                               -- (Edit cmd uses variables defined in host routines.)
include        'get.e'

include        'enter.e'       -- New enter defs, moved from STDPROCS.E and STDKEYS.E

include        'undo.e'

include        'alt_1.e'

include        'caseword.e'

include        'xchgline.e'

include        'setconfig.e'

include        'revert.e'

include        'wps.e'

;include        'comment.e'

compile if WANT_DRAW
  compile if (WANT_DRAW='F6' | WANT_DRAW=F6)
   include     'drawkey.e'     -- If you still want F6=Draw in linking version.
  compile endif
compile endif

compile if WANT_ALL
   include     'all.e'         -- Shows all occurrences of a string.
compile endif

compile if WANT_TREE = 1
   include     'tree.e'
compile endif

tryinclude     'linkcmds.e'    -- Useful new commands for the linking version.

include        'stdctrl.e'     -- PM controls for EPM.

include        'statline.e'    -- New statusline defs, defc setstatusline moved from STDCTRL.E
include        'titletext.e'

compile if INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS
 compile if defined(STD_MENU_NAME)
  compile if STD_MENU_NAME = 'STDMENU.E'
   *** Error:  Leave STD_MENU_NAME undefined to use the original menu layout (STDMENU.E).
  compile endif
   include     STD_MENU_NAME   -- Action bar menus for EPM.
 compile else
   include     'stdmenu.e'     -- Action bar menus for EPM.
 compile endif
compile endif  -- INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS
tryinclude     'clipbrd.e'     -- Clipboard interface and mark <--> buffer routines
compile if WANT_BOOKMARKS = 1
   include     'bookmark.e'
compile endif
compile if WANT_TAGS = 1
   include     'tags.e'
compile endif

-- Put all new includes after this line (preferably in MYSTUFF.E). -------------
compile if not VANILLA
 compile if defined(SITE_KEYS)
  compile if SITE_KEYS
   include     SITE_KEYS
  compile endif
 compile endif
   tryinclude  'mykeys.e'      -- User stuff containing key DEFs.
 compile if defined(SITE_STUFF)
  compile if SITE_STUFF
   include     SITE_STUFF
  compile endif
 compile endif
   tryinclude  'mystuff.e'     -- Other user stuff.
compile endif  -- not VANILLA

compile if USE_APPEND | Host_Support='EMUL' | Host_Support='E3EMUL' | WANT_DOSUTIL=1
   include     'dosutil.e'     -- DOSUTIL is required for the above (EMUL uses Exist() )
compile elseif WANT_DOSUTIL = '?'
   tryinclude  'dosutil.e'     -- otherwise, optional.
compile endif

compile if WANT_MATH = '?'     -- Try to include it.
   tryinclude  'math.e'
compile elseif WANT_MATH = 1   -- Definitely include it.
   include     'math.e'
compile endif

compile if SORT_TYPE
   include     'sort'SORT_TYPE'.e' -- SORTE, SORTG, SORTF, SORTGW, SORTDLL, SORTDOS.E.
compile endif

compile if WANT_EPM_SHELL
   include     'epmshell.e'
compile endif

compile if WANT_KEYWORD_HELP
   include     'kwhelp.e'
compile endif

compile if WANT_REXX
   include     'callrexx.e'
compile endif

-- Put all new includes above this line. --------------------------------------

compile if SPELL_SUPPORT = 1
   include     'epmlex.e'
compile endif

-- Put the programming keys last.  Any keys redefined above will stay in
-- effect regardless of filetype.  These redefine only space and enter.
compile if WANT_EBOOKIE = 1
   include     'bkeys.e'
compile endif

compile if ALTERNATE_KEYSETS
 compile if C_SYNTAX_ASSIST
   tryinclude  'ckeys.e'       -- Syntax-assist for C programmers.
 compile endif
 compile if E_SYNTAX_ASSIST
   tryinclude  'ekeys.e'       -- Syntax-assist for E programmers.
 compile endif
 compile if REXX_SYNTAX_ASSIST
   tryinclude  'rexxkeys.e'    -- Syntax-assist for Rexx programmers.
 compile endif
 compile if P_SYNTAX_ASSIST
   tryinclude  'pkeys.e'       -- Syntax-assist for Pascal programmers.
 compile endif

 compile if not VANILLA
  compile if defined(SITE_KEYSET)
   compile if SITE_KEYSET
   include     SITE_KEYSET
   compile endif
  compile endif
   tryinclude  'mykeyset.e'    -- For entirely new keysets defined by power users.
 compile endif  --  not VANILLA
compile endif  -- ALTERNATE_KEYSETS

EA_comment 'This is the base .ex file for EPM, compiled with ETPM version' EVERSION

compile if EXTRA_EX
   compiler_msg EXTRA_EX is set; not needed for EPM 6.00.  You might want to modify
   compiler_msg your MYCNF.E.  Don't forget to recompile EXTRA if appropriate.
compile endif
compile if LINK_HOST_SUPPORT
   compiler_msg LINK_HOST_SUPPORT is set; not needed for EPM 6.00.  You might want to
   compiler_msg modify your MYCNF.E.
 compile if HOST_SUPPORT = 'EMUL'
   compiler_msg Don't forget to recompile E3EMUL if appropriate.
 compile elseif HOST_SUPPORT = 'SRPI'
   compiler_msg Don't forget to recompile SLSRPI if appropriate.
 compile else
   compiler_msg Don't forget to recompile your host support if appropriate.
 compile endif
compile endif
