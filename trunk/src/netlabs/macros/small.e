const SMALL = 1            -- SMALL says to assume no host support.
include    'stdconst.e'

include    'colors.e'      -- Mnemonic color names & default colors defined here.

const                      -- (added because many users omit from MYCNF.)
tryinclude 'mycnf.e'       -- User configuration goes here.
include    'stdcnf.e'      -- Standard configuration; shouldn't be modified.

compile if WANT_DBCS_SUPPORT
include    'epmdbcs.e'
compile endif

include    'main.e'        -- This contains the DEFMAIN for the main .ex file
compile if not VANILLA
tryinclude 'mymain.e'      -- Optional user additions to DEFMAIN.
compile endif

include    'select.e'
compile if ALTERNATE_KEYSETS & not VANILLA
tryinclude 'myselect.e' -- For other user mods to select_edit_keys.
compile endif

include    'stdkeys.e'     -- Standard key definitions.
compile if EVERSION < 5
include    'window.e'      -- Windowing for non-PM versions of E.
compile elseif MOUSE_SUPPORT = 1
include    'mouse.e'       -- Mouse definition, only for EPM.
compile else
defc processmouse = sayerror 'Mouse support missing.'
compile endif
include    'stdprocs.e'    -- Standard functions and procedures.
include    'markfilt.e'    -- Procedures for filtering a block, line or char. mark.
include    'charops.e'     -- Mark operations for character marks.

include    'slnohost.e'    -- without host support

include    'stdcmds.e'     -- Standard commands (DEFC's).
                           -- (Edit cmd uses variables defined in host routines.)

-- Put all new includes after this line (preferably in MYKEYS.E). -------------
compile if not VANILLA
tryinclude 'mykeys.e'      -- User stuff containing key DEFs.
tryinclude 'mystuff.e'     -- Other user stuff.
compile endif

compile if USE_APPEND
   include  'dosutil.e'    -- DOSUTIL is required for APPEND support.
compile endif

compile if ALTERNATE_KEYSETS & not VANILLA
tryinclude 'mykeyset.e' -- For entirely new keysets defined by power users.
compile endif
