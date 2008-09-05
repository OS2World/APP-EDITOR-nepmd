/****************************** Module Header *******************************
*
* Module Name: epm.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epm.e,v 1.39 2008-09-05 22:45:13 aschn Exp $
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
                               -- Set consts if not already set, DEFINIT: set universal vars
                               -- and link separately compiled packages

include        'menuhelp.h'

include        'debug.e'       -- Write to a PmPrintf pipe for several debug cases

compile if WANT_DBCS_SUPPORT
   include     'epmdbcs.e'
compile endif

include        'main.e'        -- This contains the DEFMAIN for the main .ex file
                               -- Parse EPM's args, submit them to the EDIT command,
                               -- read settings from EPM.INI (INITCONFIG command),
                               -- process PROFILE.ERX
compile if not VANILLA
 compile if defined(SITE_MAIN)
  compile if SITE_MAIN
   include     SITE_MAIN
  compile endif
 compile endif
   tryinclude  'mymain.e'      -- Optional user additions to DEFMAIN.
compile endif  -- not VANILLA

include        'load.e'        -- Default defload must come before other defloads.
compile if not VANILLA
   tryinclude  'myload.e'      -- Optional user additions to DEFLOAD. Use your own
                               -- DEFLOADs only here to make them work properly!
                               -- Note: DEFLOAD should not be used in an externally
                               --       linked .ex file, as done by many packages!
                               -- As an alternative you may want to use the new 'load'
                               -- hook, see HOOKS.E.
compile endif  -- not VANILLA

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

include        'modify.e'

include        STDKEYS_NAME'.e'  -- Key bindings

include        'balance.e'     -- Highlight matching identifier while typing

include        'mouse.e'       -- Mouse definition, only for EPM.

include        'stdprocs.e'    -- Standard functions and procedures.

include        'epm_ea.e'      -- Font attributes

include        'markfilt.e'    -- Procedures for filtering a block, line or char. mark.
include        'charops.e'     -- Mark operations for character marks.

include        'textproc.e'

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

include        'edit.e'        -- Edit commands, must come after E3EMUL.E if activated.
include        'mode.e'        -- Mode selection and basic mode defs

include        'stdcmds.e'     -- Standard commands (DEFC's).
                               -- (Edit cmd uses variables defined in host routines.)
include        'hooks.e'       -- Hook cmds

include        'get.e'         -- Insert the contents of another file into current
include        'put.e'         -- Append the contents of current file to another

include        'enter.e'       -- Enter definitions

include        'undo.e'        -- Undo definitions

include        'caseword.e'    -- Change case of word/identifier under cursor

include        'swaptext.e'    -- Swap lines and chars

include        'tabsspaces.e'  -- Tabs2Spaces and Spaces2Tabs (without bugs)

include        'revert.e'      -- Throw away changes and reload file from disk

include        'wps.e'         -- WPS definitions (open folder)

include        'comment.e'     -- Comment and uncomment marked lines

include        'wrap.e'        -- Wrap and unwrap lines

include        'linkcmds.e'

include        'autolink.e'    -- Link all .ex files found in <UserDir>\autolink

include        'stdctrl.e'     -- PM controls for EPM.

include        'config.e'      -- Ini definitions

include        'infoline.e'    -- Statusline and Titletext definitions

include        'filelist.e'    -- Save/restore ring and provide 'File 3 of 28' field

include        'menu.e'        -- Common menu definitions

include        'clipbrd.e'     -- Clipboard interface and mark <--> buffer routines

-- Put all new includes after this line (preferably in MYSTUFF.E). -------------
compile if not VANILLA
 compile if defined(SITE_KEYS)
  compile if SITE_KEYS
   include     SITE_KEYS
  compile endif
 compile endif
/*
   -- This can now be added as an addition via the SelectKeyDefs dialog
   tryinclude  'mykeys.e'      -- User stuff containing key DEFs.
*/
 compile if defined(SITE_STUFF)
  compile if SITE_STUFF
   include     SITE_STUFF
  compile endif
 compile endif
   tryinclude  'mystuff.e'     -- Other user stuff.
compile endif  -- not VANILLA

include        'dosutil.e'     -- DOSUTIL is now required.

include        'math.e'

include        'sortepm.e'     -- SORTEPM, SORTE, SORTG, SORTF, SORTGW, SORTDLL, SORTDOS.E.

include        'callrexx.e'    -- REXX support and defcs that previously existed only as defprocs

-- Put all new includes above this line. --------------------------------------
-- (The following files define additional keysets)

-----------------------> Todo: make the following syntax expansion defs separately compilable
--                             and link them only if required.

include        'shellkeys.e'   -- Syntax-assist for EPM command shells

tryinclude     'ckeys.e'       -- Syntax-assist for C programmers.
tryinclude     'ekeys.e'       -- Syntax-assist for E programmers.
tryinclude     'rexxkeys.e'    -- Syntax-assist for Rexx programmers.
tryinclude     'pkeys.e'       -- Syntax-assist for Pascal programmers.

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

