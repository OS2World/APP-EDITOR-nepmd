compile if EVERSION >= '6.00c' & not defined(INCLUDING_FILE)
   compiler_msg E.E is not being included by EPM.E, which is unusual.
   compiler_msg Don't forget that EPM uses EPM.EX, not E.EX, as the default .EX file.
compile endif

const SMALL = 0            -- SMALL says to assume no host support.
include    'stdconst.e'

include    'colors.e'      -- Mnemonic color names & default colors defined here.

define INCLUDING_FILE = 'E.E'  -- Specify, in case any MY*.E or SITE file cares

const                      -- (added because many users omit from MYCNF.)
tryinclude 'mycnf.e'       -- User configuration goes here.

compile if not defined(SITE_CONFIG)  -- Did user's MYCNF.E set a SITE_CONFIG file?
   const SITE_CONFIG = 'SITECNF.E'   -- If not, use the default
compile endif
compile if SITE_CONFIG               -- If SITE_CONFIG file was not set to null,
   tryinclude SITE_CONFIG            -- include the site configuration file.
compile endif

include    'stdcnf.e'      -- Standard configuration; shouldn't be modified.

compile if EVERSION >= '6.00c'
 compile if MENU_LIMIT & defined(STD_MENU_NAME)
  compile if STD_MENU_NAME<>'FEVSHMNU.E' & STD_MENU_NAME<>'OVSHMENU.E'
   *** Error:  MENU_LIMIT not supported for other than the standard menus.  Omit MENU_LIMIT or STD_MENU_NAME from MYCNF.E.
  compile endif
 compile endif
compile endif

compile if EPM
include 'menuhelp.H'
compile endif

compile if WANT_DBCS_SUPPORT
include    'epmdbcs.e'
compile endif

include    'main.e'        -- This contains the DEFMAIN for the main .ex file
compile if not VANILLA
 compile if defined(SITE_MAIN)
  compile if SITE_MAIN
   include SITE_MAIN
  compile endif
 compile endif
tryinclude 'mymain.e'      -- Optional user additions to DEFMAIN.
compile endif

compile if EVERSION >= '4.12'
include    'load.e'        -- Default defload must come before other defloads.
compile endif

include    'select.e'
compile if EVERSION >= '4.12'
 compile if not VANILLA
  compile if defined(SITE_SELECT)
   compile if SITE_SELECT
   include SITE_SELECT
   compile endif
  compile endif
tryinclude 'myselect.e'    -- For user's defselects.  This doesn't have to come
                           -- immediately after select.e now.
 compile endif
include    'modify.e'      -- New defmodify event processor.
compile else
   compile if ALTERNATE_KEYSETS
      compile if C_SYNTAX_ASSIST
         tryinclude 'ckeysel.e'  -- All of these must follow SELECT.E.
      compile endif
      compile if E_SYNTAX_ASSIST
         tryinclude 'ekeysel.e'
      compile endif
      compile if REXX_SYNTAX_ASSIST
         tryinclude 'rkeysel.e'
      compile endif
      compile if P_SYNTAX_ASSIST
         tryinclude 'pkeysel.e'
      compile endif

 compile if not VANILLA
  compile if defined(SITE_SELECT)
   compile if SITE_SELECT
      include SITE_SELECT
   compile endif
  compile endif
      tryinclude 'myselect.e' -- For other user mods to select_edit_keys.
 compile endif
   compile endif
compile endif

include    'stdkeys.e'     -- Standard key definitions.
compile if not E3 and WANT_BRACKET_MATCHING & not EXTRA_EX
include 'assist.e'
compile endif

compile if EVERSION < 5
include    'window.e'      -- Windowing for non-PM versions of E.
compile elseif MOUSE_SUPPORT = 1 & not EXTRA_EX
include    'mouse.e'       -- Mouse definition, only for EPM.
compile else
defc processmouse = sayerror 'Mouse support missing.'
compile endif

include    'stdprocs.e'    -- Standard functions and procedures.
compile if not EXTRA_EX
include    'markfilt.e'    -- Procedures for filtering a block, line or char. mark.
include    'charops.e'     -- Mark operations for character marks.
compile endif

compile if not LINK_HOST_SUPPORT
 compile if HOST_SUPPORT = 'STD'
include    'saveload.e'    -- Save/load routines with host support
 compile elseif HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
include    'E3emul.e'      -- ... with extended host support
 compile elseif HOST_SUPPORT = 'PDQ'
include    'slPDQ.e'       -- ... with host support via PDQ.e
include    'pdq.e'
include    'PDQdos.e'      -- pdq.e uses some DOS functions
 compile elseif HOST_SUPPORT = 'SRPI'
include    'slSRPI.e'      -- ... with host support via SRPI interface
 compile else
include    'slnohost.e'    -- ... without host support
 compile endif
compile endif

include    'stdcmds.e'     -- Standard commands (DEFC's).
                           -- (Edit cmd uses variables defined in host routines.)
compile if EVERSION >= '6.00c'
include 'get.e'
compile endif

compile if WANT_DRAW
 compile if EVERSION < '4.02' -- With linking, DRAW is an external module.
   include 'draw.e'
 compile else
  compile if (WANT_DRAW='F6' | WANT_DRAW=F6)
   include 'drawkey.e'        -- If you still want F6=Draw in linking version.
  compile endif
 compile endif
compile endif

compile if WANT_ALL & not EXTRA_EX
   include 'ALL.E'         -- Shows all occurrences of a string.
compile endif

compile if WANT_RETRIEVE & EVERSION < 5
   include 'RETRIEVE.E'    -- Provides a window for selecting previously-entered cmds.
compile endif

compile if WANT_TREE = 1 & not EXTRA_EX
  include 'tree.e'
compile endif

compile if EVERSION >='4.02'
   tryinclude 'linkcmds.e' -- Useful new commands for the linking version.
compile endif
compile if EVERSION >=5
include    'stdctrl.e'     -- PM controls for EPM.
 compile if not EXTRA_EX
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
tryinclude 'clipbrd.e'     -- Clipboard interface and mark <--> buffer routines
 compile endif  -- not EXTRA_EX
 compile if WANT_BOOKMARKS = 1 & not EXTRA_EX
   include 'BOOKMARK.E'
 compile endif
 compile if WANT_TAGS = 1 & not EXTRA_EX
   include 'TAGS.E'
 compile endif
compile endif

-- Put all new includes after this line (preferably in MYSTUFF.E). -------------
compile if not VANILLA
 compile if defined(SITE_KEYS)
  compile if SITE_KEYS
   include SITE_KEYS
  compile endif
 compile endif
tryinclude 'mykeys.e'      -- User stuff containing key DEFs.
 compile if defined(SITE_STUFF)
  compile if SITE_STUFF
   include SITE_STUFF
  compile endif
 compile endif
tryinclude 'mystuff.e'     -- Other user stuff.
compile endif

 compile if (USE_APPEND | Host_Support='EMUL' | Host_Support='E3EMUL' | WANT_DOSUTIL=1) & not EXTRA_EX
   include  'dosutil.e'    -- DOSUTIL is required for the above (EMUL uses Exist() )
 compile elseif WANT_DOSUTIL = '?' & not EXTRA_EX
   tryinclude 'dosutil.e'  -- otherwise, optional.
 compile endif

compile if WANT_MATH = '?' & not EXTRA_EX      -- Try to include it.
   tryinclude 'math.e'
compile elseif WANT_MATH = 1 & not EXTRA_EX    -- Definitely include it.
   include 'math.e'
compile endif

compile if SORT_TYPE & not EXTRA_EX
include 'sort'SORT_TYPE'.e' -- SORTE, SORTG, SORTF, SORTGW, SORTDLL, SORTDOS.E.
compile endif

compile if EVERSION >= '4.11' and EVERSION < 5  -- 4.11 added SHELL command
 compile if SHELL_USAGE
  include 'shell.e'
 compile endif
compile endif

compile if WANT_EPM_SHELL & not EXTRA_EX
  include 'epmshell.e'
compile endif

compile if WANT_KEYWORD_HELP & not EXTRA_EX
  include 'KWhelp.e'
compile endif

compile if EVERSION >= '5.50' & not EXTRA_EX & WANT_REXX
  include 'callrexx.e'
compile endif

-- Put all new includes above this line. --------------------------------------

compile if SPELL_SUPPORT = 1
 compile if EPM
  include 'EPMLEX.e'
 compile elseif EOS2
  include 'EOS2LEX.e'
 compile else
  include 'E3SPELL.e'
 compile endif
compile endif

-- Put the programming keys last.  Any keys redefined above will stay in
-- effect regardless of filetype.  These redefine only space and enter.
compile if WANT_EBOOKIE = 1 & not EXTRA_EX
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

 compile if not VANILLA
  compile if defined(SITE_KEYSET)
   compile if SITE_KEYSET
   include SITE_KEYSET
   compile endif
  compile endif
   tryinclude 'mykeyset.e' -- For entirely new keysets defined by power users.
 compile endif
compile endif

compile if EPM32
   EA_comment 'This is the base .ex file for EPM, compiled with ETPM version' EVERSION
compile endif
