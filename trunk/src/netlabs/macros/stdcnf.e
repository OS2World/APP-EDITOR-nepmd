/****************************** Module Header *******************************
*
* Module Name: stdcnf.e
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

; ===========================================================================
; Part 1: configuration constants
; ===========================================================================

const

compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
compile endif

-- Set filename for defc Help = Help -> Quick reference
compile if not defined(HELPFILENAME)
   HELPFILENAME='epmhelp.qhl'
compile endif

; Host support --------------------------------------------------------------
-- This constant tells the compiler which host-support method
-- to include.  Only modify the first copy.  Typical values are:
--   'STD'  uses the original E3 method (mytecopy, etc.).
--   'EMUL' uses Brian Tucker's E3EMUL package.  Download it separately.
--   'PDQ'  uses the E3PDQ package.  Download it separately.
--   'SRPI' uses SLSRPI.E, part of the LaMail package.
--   ''     loads no host-file support at all.
compile if not defined(HOST_SUPPORT)
 compile if defined(SMALL)
  compile if not SMALL
   --HOST_SUPPORT = 'STD'  -- changed by aschn
   -- Changed HOST_SUPPORT to W4's and eCS's default, because otherwise files from
   -- drive H: are not loaded properly and can't be saved.
   -- Note: if you want to activate it in your MYCNF.E, then also specify HOSTDRIVE!
   -- The default value is: HOSTDRIVE = H:
   HOST_SUPPORT = ''
  compile else
   -- Do not change this!!  Only the previous one.
   HOST_SUPPORT = ''
  compile endif
 compile else
   -- Do not change this!!  Only the previous one.
   HOST_SUPPORT = ''
 compile endif
compile endif
-- If you're tight on space in the .ex file, you can now have the host support
-- routines linked in at run time.  Currently only supported for E3EMUL and
-- SLSRPI.  Set HOST_SUPPORT='EMUL' (or 'SRPI'), LINK_HOST_SUPPORT=1, compile
-- your base macros (E or EPM) and also compile E3EMUL (or SLSRPI).  Warning:
-- you'll have to remember to recompile the host support .ex file whenever you
-- make a change to your MYCNF.E that affects it, and whenever a new version of
-- the editor comes out that doesn't accept your current level of .ex file.
compile if not defined(LINK_HOST_SUPPORT)
; #### Todo: ? ##############################################################
   LINK_HOST_SUPPORT = 0
compile endif
compile if HOST_SUPPORT = 'PDQ'
-- The PDQ support will optionally poll the host and see if anyone has sent
-- you a message.  If so, it will pop up a window and display the messages.
-- To enable this, set the following constant to 1.
 compile if not defined(PDQ_MSG)
   PDQ_MSG = 1
 compile endif
compile endif


; #### Todo: replace ########################################################
EPATH = 'EPMPATH'

-- This is used as the decimal point in MATH.E.  Some users might prefer to
-- use a comma.  Not used in DOS version, which only allows integers.
compile if not defined(DECIMAL)
; #### Todo: use os2.ini or Locale settings #################################
   DECIMAL = '.'
compile endif

-- Set this to 0 if you want the marked area left unmarked after the sort.
 compile if not defined(RESTORE_MARK_AFTER_SORT)
   RESTORE_MARK_AFTER_SORT = 1
 compile endif

-- This provides a simple way to omit all user includes, for problem resolution.
-- If you set VANILLA to 1 in MYCNF.E, then no MY*.E files will be included.
compile if not defined(VANILLA)
   VANILLA = 0
compile endif

-- Normally, when you shift a mark left or right, text to the right of the
-- marked area moves with it.  Bob Langer supplied code that lets us shift
-- only what's inside the mark.  The default is the old behavior.
compile if not defined(SHIFT_BLOCK_ONLY)
   SHIFT_BLOCK_ONLY = 0
compile endif

-- Determines if DBCS support should be included in the macros.  Note
-- that EPM includes internal DBCS support; other versions of E do not.
compile if not defined(WANT_DBCS_SUPPORT)
   --WANT_DBCS_SUPPORT = 0  -- changed by aschn
   WANT_DBCS_SUPPORT = 1
compile endif

-- SUPPORT_BOOK_ICON specifies whether or not the "Book icon" entry is on
-- the Options pulldown.  Another useless one for internals.
-- EPM preload object:
-- If EPM is started with option /i (icon), then
--    MINWIN=VIEWER  ==> a hidden EPM is opened and can be found in the Minimized Windows Viewer
--    MINWIN=HIDE    ==> a hidden EPM is opened.
--    MINWIN=DESKTOP ==> a hidden EPM is opened and an icon is placed on the desktop.
-- (obsolete pre-WPS function)
compile if not defined(SUPPORT_BOOK_ICON)
;compile if EVERSION < '5.50'
   -- Only useful if an EPM object is started with option /i and has the setup string MINWIN=DESKTOP
   --SUPPORT_BOOK_ICON = 1  -- changed by aschn
   SUPPORT_BOOK_ICON = 0
compile endif

-- CHECK_FOR_LEXAM specifies whether or not EPM will check for Lexam, and only include
-- PROOF on the menus if it's available.  Useful for product, if we're not shipping Lexam
-- and don't want to advertise spell checking; a waste of space internally.
compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
compile endif

compile if not defined(STD_MENU_NAME)
   --STD_MENU_NAME = ''  -- changed by aschn
   STD_MENU_NAME = 'newmenu.e'
compile endif

-- The compiler support is only included if the bookmark support is; this lets
-- you omit the former while including the latter.
compile if not defined(INCLUDE_WORKFRAME_SUPPORT)
   INCLUDE_WORKFRAME_SUPPORT = 1
compile endif

-- For Toolkit developers - set to 0 if you don't want the user to be able
-- to go to line 0.  Affects MH_gotoposition in MOUSE.E and Def Up in STDKEYS.E.
-- Must be set to 1 in order to enable a copy line action to the top. (Copy line
-- copies a line after the current line.)
compile if not defined(TOP_OF_FILE_VALID)
   -- Can be '0', '1', or 'STREAM' (dependant on STREAM_MODE)
   TOP_OF_FILE_VALID = 1
compile endif

-- EBOOKIE support desired?  0=no; 1=include bkeys.e; 'LINK'=always link BKEYS
-- at startup; 'DYNALINK'=support for dynamically linking it in.
compile if not defined(WANT_EBOOKIE)
; #### Todo: ? ##############################################################
   WANT_EBOOKIE = 'DYNALINK'
compile endif


-- Include support for viewing the EPM User's guide in the Help menu.
compile if not defined(SUPPORT_USERS_GUIDE)
   --SUPPORT_USERS_GUIDE = 0  -- changed by aschn
   SUPPORT_USERS_GUIDE = 1
compile endif

-- Include support for viewing the EPM Technical Reference in the Help menu.
compile if not defined(SUPPORT_TECHREF)
   --SUPPORT_TECHREF = 0  -- changed by aschn
   SUPPORT_TECHREF = 1
compile endif

-- Include support for calling user exits in DEFMAIN, SAVE, NAME, and QUIT.
-- (EPM 5.51+ only; requires isadefproc() ).
compile if not defined(SUPPORT_USER_EXITS)
   --SUPPORT_USER_EXITS = 0  -- changed by aschn
; #### Todo: obsolete since hooks exist #####################################
   SUPPORT_USER_EXITS = 1
compile endif

compile if not defined(INCLUDE_BMS_SUPPORT)
   INCLUDE_BMS_SUPPORT = 0
compile endif

-- Allow pressing tab in insert mode to insert spaces to next tab stop in
-- line mode as well as in stream mode.
compile if not defined(WANT_TAB_INSERTION_TO_SPACE)
   -- for line mode only
   WANT_TAB_INSERTION_TO_SPACE = 0
compile endif

compile if not defined(WORD_MARK_TYPE)
   -- Bug using 'BLOCK':
   -- If a block is copied to the clipboard, a CRLF is appended.
   -- Sh+Ins will insert this CRLF instead of ignoring it.
   --WORD_MARK_TYPE = 'BLOCK'  -- changed by aschn
   WORD_MARK_TYPE = 'CHAR'
compile endif

compile if not defined(EPM_POINTER)
   EPM_POINTER = TEXT_POINTER      -- GPI version gets text pointer
compile endif

;include 'obsolete.e' -- define obsolete consts for compatibility

include NLS_LANGUAGE'.e'

; ===========================================================================
; Part 2: Default keyset via ETK definitions
;         Keys are usually defined via PM accelerator key definitions.
; ===========================================================================

; Bug in EPM's keyset handling:
; .keyset = '<new_keyset>' works only, if <new_keyset> was defined in
; the same .EX file, from where the keyset should be changed.
; Therefore (as a workaround) switch temporarily to the externally
; defined keyset in order to make it known for 'SetKeys':
;
; definit  -- required for a separately compiled package
;    saved_keys = .keyset
;    .keyset = '<new_keyset>'
;    .keyset = saved_keys
;
; Note: An .EX file, that defines a keyset, can't be unlinked, when this
; keyset is in use.

; ---------------------------------------------------------------------------
; This defines the standard keyset. It's important to use the option 'clear'.
; Otherwise otherkeys won't process the standard letters, numbers and chars.
;
; The keyset 'edit_keys' must be defined before all other key sets.
; Therefore this file is actually included early in EPM.E. It's possible to
; link these defs, but then other key defs must be linked after defining
; 'edit_keys'.
; (To do: test if defs from 'edit_keys' are overtaken by other keysets then.)
defkeys edit_keys new clear

; For testing:
;def '�'
;   dprintf( 'lastkey() = 'lastkey()', ch = 'ch)
;   call SaveKeyCmd( lastkey())
;   call Process_Keys( 'ae')

; Alt+0 ... Alt+9 keys:
; These standard key defs are not executed as accel keys in order to keep
; entering a char via Alt+numpad key working.
; Because accel keys don't create a WM_CHAR message, they can't be handled
; by lastkey or getkeystate.
; To assign code to these keys, they have to be additionally defined via the
; DefKey proc (that is used for defining accel keys). DefKey handles them
; specially: It sets just an array var, that is queried and executed by
; ExecKeyCmd.
def a_1 'ExecKeyCmd a_1'
def a_2 'ExecKeyCmd a_2'
def a_3 'ExecKeyCmd a_3'
def a_4 'ExecKeyCmd a_4'
def a_5 'ExecKeyCmd a_5'
def a_6 'ExecKeyCmd a_6'
def a_7 'ExecKeyCmd a_7'
def a_8 'ExecKeyCmd a_8'
def a_9 'ExecKeyCmd a_9'
def a_0 'ExecKeyCmd a_0'

; Space key:
; In order to type the single accent key '^' which is created by
; <hat_key>+<space>, space must not be defined as accel key. Therefore
; Space is defined with ExecKeyCmd. That means that it executes the
; command that is stored by DefKey( Space, cmd) as an array var.
def space 'ExecKeyCmd space'

; Cursor keys:
; When processed as accel keys, cursor key messages send by another app
; are ignored. This happens if AMouse is configured to send keyboard
; messages instead of scroll window messages.
def down  'ExecKeyCmd down'
def up    'ExecKeyCmd up'
def left  'ExecKeyCmd left'
def right 'ExecKeyCmd right'

; Processing the keys above in the 'otherkeys' command would work, but
; their scancode may vary with different keyboard layouts. The E toolkit
; key names (used after 'def') handle that.

; Add more keys here that have to be processed as standard E toolkit keys
; or can't be processed as accelerator keys. The cursor keys above are
; defined as both. When being processed, the accel def wins. To ignore
; the accel def, a key must be added to the 'etkkeys' array var above.

def otherkeys
   'otherkeys'


; ===========================================================================
; Part 3: Set universal vars and init misc, depending on consts
; ===========================================================================
; (Initialization based on ini file values is made by InitConfig, defined
; in CONFIG.E. InitConfig is executed by defmain, when all definits are
; processed.)

definit
   universal expand_on, matchtab_on
   universal vtemp_filename, vtemp_path, vautosave_path
   universal edithwnd, MouseStyle, appname
   universal app_hini
   universal nepmd_hini
   universal CurrentHLPFiles
   universal vstatuscolor, vmessagecolor
   universal vdesktopcolor
   universal menu_prompt
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal ring_enabled
   universal EPM_utility_array_ID, defaultmenu
   universal vdefault_tabs, vdefault_margins, vdefault_autosave
   universal addenda_filename
   universal dictionary_filename
   universal shell_index
   universal CUA_marking_switch
compile if HOST_SUPPORT
   universal hostcopy
compile endif
   universal stay
   universal stream_mode
   universal default_font
   universal cursordimensions
   universal bitmap_present
   universal show_longnames
   universal rexx_profile
   universal escape_key
   universal tab_key

   CurMenu = ''
   nepmd_hini = ''
;  -- Link the NEPMD library. Open a MessageBox if .ex file not found. ------
   'linkverify nepmdlib.ex'

;  Open NEPMD.INI and save the returned handle ------------------------------
   NepmdOpenConfig( nepmd_hini)
   if rc then
      sayerror 'Configuration repository could not be opened, rc = 'rc'.'
   else
      dprintf( 'DEFINIT', 'Current ini entry: 'queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath'))
      IniFile = NepmdQueryInstValue( 'INIT')
      --if not Exist( IniFile) then
      if not NepmdFileExists( IniFile) then
         dprintf( 'DEFINIT', 'NEPMD.INI doesnot exist')
         --fEpmIniRenamed = 1
      endif
   endif

; All settings are saved to NEPMD.INI now. EPM.INI is not touched anymore.
; Therefore OS2.INI -> EPM -> EPMIniPath is changed temporarily to the
; filename of NEPMD.INI during EPM's startup by the EPM loader. That is
; required for several internal routines, that use the ini handle provided
; by ETKR603.DLL.
; Moreover, the temporary change of EPMIniPath is also required when the
; standard settings dialog is started to make the internal toolbar routines
; access the correct settings.
; That hack works reliable, so far -- and better than expected, even when
; EPMIniPath was removed from OS2.INI:
;    -  Standard EPM automatically creates a new entry if that ini
;       application doesn't exist or if it points to a non-valid filename.
;       But it doesn't terminate the entry with a null.
;    -  NEPMD's loader reads the entry and restores it after a second
;       null-terminated.
;    -  If NEPMD's loader is started first, it creates a null entry. Even
;       that one is overwritten by the next startup of the standard EPM.
;
; Both options should set app_hini to the same value:
compile if 0
;  Open EPM.INI and save the returned handle --------------------------------
   app_hini = dynalink32( ERES2_DLL,
                          'ERESQueryHini',
                          gethwndc(EPMINFO_EDITCLIENT), 2)
      -- That should return the value of nepmd_hini, since the ini handle
      -- is saved by C code on opening the EPM window, while the OS2.INI
      -- entry was changed temporary.
   if not app_hini then
      call WinMessageBox( 'Bogus Ini File Handle', '.ini file handle =' app_hini, 16416)
   endif
compile else
;  Use NEPMD.INI for all settings controlled by E macros --------------------
   app_hini = nepmd_hini
compile endif

;  Process NEPMD.INI initialization -----------------------------------------
   -- Write default values from nepmd\netlabs\bin\defaults.dat to NEPMD.INI,
   -- application 'RegDefaults', if 'RegDefaults' was not found
   NepmdInitConfig( nepmd_hini)
   if rc then
      sayerror 'Configuration repository could not be initialized, rc = 'rc'.'
   endif

   if isadefproc('NepmdQueryConfigValue') then
      KeyPath = '\NEPMD\User\Menu\Name'
      CurMenu = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif

;  Create array -------------------------------------------------------------
;  Before this, array vars can't be used. (Therefore: moved this some lines
;  up.)
;
; What was the ring_menu_array_id is now the EPM_utility_array_id, to reflect
; that it's a general-purpose array.  An array is a file, so it's cheaper to
; use the same one whenever possible, rather than creating new ones.  We use a
; prefix to keep indices unique.  Current indices are:
;   menu.     -- Menu index; commented out
;   bmi.      -- Bookmark index
;   bmn.      -- Bookmark name
;   dspl.     -- Dynamic spellchecking starting keyset
;   shell_f.  -- Shell fileid
;   shell_h.  -- Shell handle
;   si.       -- Style index
;   sn.       -- Style name
;   F         -- File id for Ring_more command; not used as of EPM 5.20
   do_array 1, EPM_utility_array_ID, 'array.EPM'   -- Create this array.
;compile if 0  -- LAM: Delete this feature; nobody used it, and it slowed things down.
;   one = 1                                          -- (Value is a VAR, so have to kludge it.)
;   do_array 2, EPM_utility_array_ID, 'menu.0', one           -- Item 0 says there is one item.
;   do_array 2, EPM_utility_array_ID, 'menu.1', defaultmenu   -- Item 1 is the default menu name.
;compile endif  -- 0
   zero = 0                                         -- (Value is a VAR, so have to kludge it.)
   do_array 2, EPM_utility_array_ID, 'bmi.0', zero    -- Index of 0 says there are no bookmarks
   do_array 2, EPM_utility_array_ID, 'si.0', zero     -- Set Style Index 0 to "no entries."

;  Mode config defs ---------------------------------------------------------
;  (Can only be linked after the array "array.EPM" was created.)
   'linkverify modeexec.ex'  -- must be either included (in EPM.E) or linked before the menu
   'linkverify modecnf.ex'   -- may be linked anywhere, but before processing defmain

;  Link the mouse defs ------------------------------------------------------
   'linkverify mouse'

;  Link the menu ------------------------------------------------------------
;  toggleframe and togglecontrol must be defined early in definit or before.
;  Therefore NEWMENU.EX is now linked early in definit. Array vars must
;  already be usable to make the menu's definit work, which is executed
;  directly after linking.
   if CurMenu = '' then  -- CurMenu is only defined if NEPMDLIB is already linked
      CurMenu = 'newmenu'
   endif
   'linkverify 'CurMenu'.ex'

;-- set automatic syntax expansion 0/1
; will be overridden later
   expand_on        = 1

;-- set default matchtab to 0 or 1
; will be overridden later
   matchtab_on      = 0

-- This option JOIN_AFTER_WRAP specifies whether to join the
-- next line after a word-wrap.  To see its effect:  set margins to 1 79 1;
-- go into insert mode; type a few characters into this line to cause a wrap.
-- (sample next line)
-- If join_after_wrap = 1, you'll get:
--    wrap. -- (sample next line)
-- If join_after_wrap = 0, you'll get:
--    wrap.
--    -- (sample next line)
; will be overridden later
   join_after_wrap = 1

-- This option CENTER_SEARCH specifies how the cursor moves
--   during a search or replace operation.
-- 0 :  Hold the cursor fixed; move the word to the cursor.  Like old E.
-- 1 :  Move the cursor to the word if it's visible on the current screen,
--      to minimize text motion.  Else center the word in mid-screen.
; EPM does this everytime
; obsolete
   center_search = 1

compile if HOST_SUPPORT
 compile if defined(my_hostcopy)
   hostcopy= my_hostcopy
 compile else
   hostcopy='almcopy'     -- Default for OS/2 is the OS/2 version of ALMCOPY.
 compile endif
                        -- Could be mytecopy, e78copy, bondcopy, cp78copy, almcopy, etc.
                        -- Add options if necessary (e.g., 'mytecopy /nowsf')
compile endif

; Init universal vars if the corresponding consts are defined to use variables
; will be overridden later
   show_longnames = 1

; will be overridden later
   rexx_profile = 1

; Now always enabled
   escape_key = 1

; will be overridden later
   tab_key = 0

; stay = 0: After a change, move the cursor to the last changed string
 compile if defined(my_stay)
   stay = my_stay
 compile else
   stay = 0
 compile endif

; We now save the constants in universal variables.  This way, they can be
; over-ridden at execution time by a definit (e.g., the user might check an
; environment variable to see if a VDISK has been defined, and if so, set the
; temp_path to point to it).  The constants are used as default initialization,
; and for compatability with older macros.
   vtemp_filename = 'e.tmp'
   do i = 1 to 1
      vtemp_path = get_env( 'TMP')
      if vtemp_path <> '' then
         leave
      endif
      vtemp_path =  get_env( 'TEMP')
      if vtemp_path <> '' then
         leave
      endif
   enddo
   vtemp_path = strip( vtemp_path, 'T', '\')'\'  -- append a backslash
   vautosave_path = vtemp_path

; In EPM you can choose one of several (well, only 2 for now) prefabricated
; styles of mouse behavior.  You can change styles on the fly with the command
; MOUSESTYLE or MS.  See MOUSE.E for style descriptions; brief summaries are:
;  1: Block and line marks for programmers.
;     Button 1 drag = block mark, button 2 drag = line.
;     Button 1 double-click = unmark.  Button 2 double-click = word-mark.
;  2: Character and line marks.
;     Same as style 1, but button 1 drag = character mark rather than block.
;  3: A marking style of point-the-corners instead of drag-paint.
;     (Not done yet.)
; will be overridden later
   MouseStyle = 1

   KeyPath = '\NEPMD\User\Spellcheck\SelectedLanguage'
   DictLang = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DictLang <> '' then
      KeyPath = '\NEPMD\User\Spellcheck\Language'
      Dict = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'DictLang'\Dictionary')
      Add  = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'DictLang'\Addenda')
   endif
   dictionary_filename = Dict
   addenda_filename    = Add

   shell_index = 0

   cua_marking_switch = 0           -- Default is off, for standard EPM behavior.

   bitmap_present = 0

; We need this e.g. for to use otherkeys.
; This should probably be moved to KEYS.E.
   'togglecontrol 26 0'  -- Turn off internal support for cursor keys.

------------ Rest of this file isn't normally changed. ------------------------

   vdefault_tabs     = 8
   vdefault_margins  = '1 1599 1'
   vdefault_autosave = 100

; replace?
compile if defined( my_APPNAME)
   appname = my_APPNAME
compile else
   appname = leftstr( getpminfo(EPMINFO_EDITEXSEARCH), 3)  -- Get the .ex search path
                                 -- name (this should be a reliable way to get a
                                 -- unique application under which to to store
                                 -- data in os2.ini.  I.e. EPM (EPMPATH) would be
compile endif                    -- 'EPM', LaMail (LAMPATH) would be 'LAM'

   CurrentHLPFiles = 'epm.hlp'

   ring_enabled = 1
; #### Todo: move ###########################################################
   newcmd = queryprofile( app_hini, appname, INI_RINGENABLED)
   if newcmd <> '' then
      ring_enabled = newcmd
   endif
   if not ring_enabled then
      'toggleframe 4 0'
   endif

   menu_prompt = 1

; Initialize the colors and paint the window.  (Done in WINDOW.E for non-EPM versions.)
   .textcolor  = TEXTCOLOR
   .markcolor  = MARKCOLOR

   vstatuscolor  = STATUSCOLOR
   vmessagecolor = MESSAGECOLOR
   vdesktopcolor = DESKTOPCOLOR

   stream_mode = 1
   'togglecontrol 24 1'

; #### Todo: replace ########################################################
compile if defined(STD_MONOFONT)
   parse value STD_MONOFONT with ptsize'.'name
compile else
   parse value '12.System VIO' with ptsize'.'name
compile endif
   default_font = registerfont( name, 'DD'ptsize'0WW0HH0BB', 0)

; compile if defined(my_CURSORDIMENSIONS)
;   cursordimensions = my_CURSORDIMENSIONS
; compile elseif UNDERLINE_CURSOR
;   cursordimensions = '-128.3 -128.-64'
; compile else
   cursordimensions = '-128.-128 2.-128'
; compile endif

   call fixup_cursor()

; -------- Link separately compilable modules -------------------------------
;  Most of them were previously included in EPM.E. Linking instead of
;  including reduces EPM.EX' String Area Size. That size has the limit of
;  64k per EX file. At least NEPMDLIB, NEWMENU and a few others have to be
;  linked to fall below that limit. See the output of "etpm /v epm".

   -- NEWMENU.EX must be linked earlier, because the commands togglecontrol
   -- and toggleframe are used above.

   'linkverify keys'
   'link stdkeys'          -- accelerator key defs

   'linkverify file'
   'linkverify backup'
   'linkverify locate'
   'linkverify toolbar'
   'linkverify tools'
   'linkverify recompile'  -- several recompile/relink/restart commands
   'linkverify assist'     -- provides instring and inliteral defprocs as well
   'linkverify bookmark'
   'linkverify popup'      -- saves 4.2 KIB in stringtable area
   'linkverify all'        -- doesn't work reliable when being implicitely linked, so always link it
   'linkverify epmshell'
   'linkverify dict'       -- select language for dictionaries

;compile if MOUSE_SUPPORT = 'LINK'
;   'linkverify MOUSE'  -- doesn't work
;compile endif

   -- The rest of initialization is done in InitConfig, called in MAIN.E.

-----------------  End of DEFINIT  ------------------------------------------


; ===========================================================================
; Part 4: Define commands here for the dynalink feature
; ===========================================================================
; That avoids a link or even an include.
; In contrast to the implicite linking, the linked EX file remains linked
; after the command execution.

defc syn       = link_exec( 'epmlex', 'syn', arg(1))
defc proof     = link_exec( 'epmlex', 'proof', arg(1))
defc proofword, verify = link_exec( 'epmlex', 'verify', arg(1))
defc dict      = link_exec( 'epmlex', 'dict', arg(1))
defc dynaspell = link_exec( 'epmlex', 'dynaspell', arg(1))

defc bookie = link_exec( 'bkeys', 'bookie', arg(1))

defc tree_dir = link_exec( 'tree', 'tree_dir', arg(1))
defc treesort = link_exec( 'tree', 'treesort', arg(1))

defc findtag     = link_exec( 'tags', 'findtag',  arg(1))
defc tagsfile    = link_exec( 'tags', 'tagsfile', arg(1))
defc tagscan     = link_exec( 'tags', 'tagscan',  arg(1))
defc poptagsdlg  = link_exec( 'tags', 'poptagsdlg',  arg(1))
defc maketags    = link_exec( 'maketags', 'maketags',  arg(1))

defc viewword = link_exec( 'kwhelp', 'viewword', arg(1))

defc draw = link_exec( 'draw', 'draw_init', arg(1))

;if isadefc( 'InitModeCnf') then
;   'InitModeCnf'
;endif

