/****************************** Module Header *******************************
*
* Module Name: small.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
const SMALL = 1                -- SMALL says to assume no host support.
include        'stdconst.e'

include        'colors.e'      -- Mnemonic color names & default colors defined here.

const                          -- (added because many users omit from MYCNF.)
tryinclude     'mycnf.e'       -- User configuration goes here.
include        'stdcnf.e'      -- Standard configuration; shouldn't be modified.

compile if WANT_DBCS_SUPPORT
   include     'epmdbcs.e'
compile endif

include        'main.e'        -- This contains the DEFMAIN for the main .ex file
compile if not VANILLA
   tryinclude  'mymain.e'      -- Optional user additions to DEFMAIN.
compile endif

include        'select.e'
compile if ALTERNATE_KEYSETS & not VANILLA
   tryinclude  'myselect.e'    -- For other user mods to select_edit_keys.
compile endif

include        'stdkeys.e'     -- Standard key definitions.
compile if MOUSE_SUPPORT = 1
   include     'mouse.e'       -- Mouse definition, only for EPM.
compile else
   defc processmouse = sayerror 'Mouse support missing.'
compile endif
include        'stdprocs.e'    -- Standard functions and procedures.
include        'markfilt.e'    -- Procedures for filtering a block, line or char. mark.
include        'charops.e'     -- Mark operations for character marks.

include        'slnohost.e'    -- without host support

include        'stdcmds.e'     -- Standard commands (DEFC's).
                               -- (Edit cmd uses variables defined in host routines.)

-- Put all new includes after this line (preferably in MYKEYS.E). -------------
compile if not VANILLA
   tryinclude  'mykeys.e'      -- User stuff containing key DEFs.
   tryinclude  'mystuff.e'     -- Other user stuff.
compile endif

compile if USE_APPEND
   include     'dosutil.e'     -- DOSUTIL is required for APPEND support.
compile endif

compile if ALTERNATE_KEYSETS & not VANILLA
   tryinclude  'mykeyset.e'    -- For entirely new keysets defined by power users.
compile endif
