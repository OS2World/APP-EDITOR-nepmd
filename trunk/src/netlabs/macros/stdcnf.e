/****************************** Module Header *******************************
*
* Module Name: stdcnf.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdcnf.e,v 1.17 2004-03-19 14:56:19 aschn Exp $
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

/*
; ---------------------------------------------------------------------------
; Commented out obsolete lines by a ';' (rather then deleting them) to enable
; searching for obsolete consts.
; ---------------------------------------------------------------------------
*/

/* New way to configure E. In response to the requests of many users, we have
   changed things so that it is no longer required that you modify this file
   in order to reconfigure E. An optional MYCNF file is included before this
   one.  There are three sections to this file, setting different types of
   defaults, and each can be overridden in the MYCNF.E file.  The first
   section, most of which doesn't apply to EPM, contains SET statements.  The
   second section defines constants, and the third section initializes various
   global variables.  To override the first section, you simply include the
   appropriate SET statement in your MYCNF.  The ones here are commented out,
   and exist just to document the defaults.

   To override the second section, simply define the constants.

   To override the third section, define a MY_variablename set to the
   desired value.  Examples of each follow:


      set insert_state 0           -- I prefer to have insert initially off
    compile if EVERSION < 5   -- Setup customization for E3 and EOS2, not EPM.
      set coms  1 'c:\e3\'
    compile endif

    const         -- Second section.  Predefine preferred constants.
       ENTER_ACTION   = 'ADDATEND'
       C_ENTER_ACTION = 'ADDLINE'

    define        -- Third section.  Override DEFINIT initializations.
       my_messy = 1        -- I'd rather have MESSY set to 1.

    The above is a little more complicated than the old way; the advantage
    is that when a new STDCNF comes out, you don't have to modify it to
    contain your personalized definitions, but you still get anything that
    might have been added to it since the previous release.

    Reminder:  To have these changes take effect, you must recompile your
    main .ex file.  Enter 'ET E', 'ET SMALL', or 'ET EPM', as appropriate.

*/

/* The following are the default settings.  Most don't apply to EPM.

-- Change in EOS2:  We no longer differentiate by color vs. mono display type,
-- but by whether the character cell is low- or high-resolution.
--    LOW -RESOLUTION = a CGA or an EGA/VGA with 43 or more rows.
--    HIGH-RESOLUTION = a monochrome or an EGA/VGA with <43 rows.
-- The minimum top scan line is 0.  (Scan lines are numbered from the top.)
-- The maximum bottom scan line is 7 in low resolution, 13 or more in high.
-- (No effect if using EPM.)
set cursors
  3  7   -- insert -mode cursor size for low -res (EOS2) / color (E3) display
  6  7   -- replace-mode cursor size for low -res (EOS2) / color (E3) display
  6  12  -- insert -mode cursor size for high-res (EOS2) / mono  (E3) display
  11 13  -- replace-mode cursor size for high-res (EOS2) / mono  (E3) display

-- Default insert state at startup, 1=on, 0=off
-- (EPM recognizes this one.)
set insert_state 1


-- If you want your command stack saved between runs,
--   enter 1 and a path.  For example:
--      set coms 1 'C:\EDIT\'
--   Don't forget the trailing backslash on path!
-- (No effect if using EPM.)
set coms  0 ''

; SET EOF 1 means:  When saving a file, append an EOF marker (the end-of-file
; character, x'1A').  When loading a file, treat any CR-LF-EOF sequence as the
; end of the file and stop loading.  This is the normal treatment many older
; programs expect the EOF marker, and some (like REXX) will store uneditable
; data after the final EOF.
;
; SET EOF 0 means:  Do not add an EOF when saving.  Do not stop loading at
; a CR-LF-EOF sequence.  (An EOF as the very last byte of a file will still
; be discarded when loading.)  This treatment is new in version 4.04.
;
-- (EPM supports this, also.)
set eof 1


; Specifies on which row of the screen the initial logo/copyright message
; is displayed.  Default is 1, top of screen.  (EOS2 only.)
-- (No effect if using EPM.)
set logo 1 ''

 . . . . End of sample SET statements. . . .     */
-------------------------------------------------------------------------------

const
; Ver.3.10/4.03:  we no longer need to declare EVERSION here; it's a predefined
; constant.  You can use it as if we'd said:
;    const EVERSION='3.12'   (if E3)
;    const EVERSION='4.13'   (if EOS2)
;    const EVERSION='5.15'   (if EPM)

compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
compile endif

-- Define a TEMP_PATH as well as a TEMP_FILENAME
--   Typically put this on a VDISK, like 'D:\e.tmp'.
compile if not defined(TEMP_FILENAME)
   TEMP_FILENAME= 'e.tmp'
compile endif

-- Some applications (external sorts)
--   need to create more than one temp file.
--   Suggestions:  put on a VDISK.
--   Typical 'D:\'.  Don't forget last backslash.
compile if not defined(TEMP_PATH)
   TEMP_PATH=''
compile endif

-- Allow a separate directory for autosaved files.
--   Don't put this one on a VDISK.
--   Don't forget last backslash.
compile if not defined(AUTOSAVE_PATH)
   AUTOSAVE_PATH=''
compile endif

-- Set this to a nonzero number if you wish autosave to be turned on
-- automatically for all files.  In EPM this is the number of changes to the
-- file, not the number of Enter keys, so we prefer a higher value.
-- You can set this to 0 if you don't want autosave all the time, and turn it
-- on when desired with the 'autosave' command.
compile if not defined(DEFAULT_AUTOSAVE)
   -- Full undo means more frequent changes
   DEFAULT_AUTOSAVE = 100
compile endif

-- jbl 1/89 new feature.  Set this to some non-blank directory name if you want
-- a backup copy of your file upon saving.  E will copy the previous file
-- to this directory before writing the new one.  Typical values are:
--    ''             empty string to disable this feature (as in old E)
--    '.\'           for current directory (don't forget the last backslash)
--    'C:\OLDFILES\' to put them all in one place
compile if not defined(BACKUP_PATH)
   BACKUP_PATH = ''
compile endif

-- Set help filename
compile if not defined(HELPFILENAME)
   HELPFILENAME='epmhelp.qhl'
compile endif

-- Set environment variable name
compile if not defined(EPATH)
   -- EPM uses a different name, for easier coexistance
   EPATH= 'epmpath'
compile endif

-- Set main file for the ET compilation command
compile if not defined(MAINFILE)
   MAINFILE= 'epm.e'
compile endif

-- Ver. 3.09 - Lets user omit ET command.
compile if not defined(WANT_ET_COMMAND)
   WANT_ET_COMMAND = 1
compile endif

-- Ver. 3.09 - Lets user omit macro support for character marks.
compile if not defined(WANT_CHAR_OPS)
   WANT_CHAR_OPS = 1
compile endif

-- 4.10:  We removed the warning about 'constants must be specified in upper
-- case'.  No longer necessary.

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
   LINK_HOST_SUPPORT = 0
compile endif

compile if HOST_SUPPORT = 'PDQ'
-- The PDQ support uses a subset of the DOS procedures found in Bryan
-- Lewis' DOS.E.  If you include DOS.E in MYSTUFF.E, then set the following
-- constant to 1.
 compile if not defined(HAVE_DOS)
; obsolete
   HAVE_DOS = 0
 compile endif

-- The PDQ support will optionally poll the host and see if anyone has sent
-- you a message.  If so, it will pop up a window and display the messages.
-- To enable this, set the following constant to 1.
 compile if not defined(PDQ_MSG)
   PDQ_MSG = 1
 compile endif
compile endif

-- These constants specify what actions should be taken for the
-- Enter and C_Enter keys.  Possible values for ENTER_ACTION are:
--    'ADDLINE'   Insert a line after the current line.
--    'NEXTLINE'  Move to the next line without inserting a line.
--    'ADDATEND'  ADDLINE if on last line, else NEXTLINE.
--    'DEPENDS'   ADDLINE if in insert_mode, else NEXTLINE.
--    'DEPENDS+'  ADDLINE if on last line, else DEPENDS.
--    'STREAM'    Act like stream editors; Enter splits a line.
--    ''          Don't define; user will supply a routine (in MYSTUFF.E).
-- Possible values for C_ENTER_ACTION are the same, except that the action
-- taken for DEPENDS is reversed.  If ENTER_ACTION='STREAM', some other key
-- definitions are modified also - Delete past the end of a line, or Backspace
-- in column 1 will join the two lines as if it had deleted a CR/LF; Left and
-- Right will wrap from line to line.  Setting C_ENTER_ACTION='STREAM' doesn't
-- affect these other keys.
compile if not defined(ENTER_ACTION)
   ENTER_ACTION   = 'ADDLINE'
compile endif
compile if not defined(C_ENTER_ACTION)
   C_ENTER_ACTION = 'NEXTLINE'
compile endif

-- These constants specify which syntax-assist modules to include.

-- Master control for the following 3 and also
-- MYSELECT and MYKEYSET.  If you don't use any of
-- them, it makes SELECT.E much simpler.
compile if not defined(ALTERNATE_KEYSETS)
   ALTERNATE_KEYSETS = 1
compile endif

-- 1 means to include C assist, 0 means omit it.
compile if not defined(C_SYNTAX_ASSIST)
   C_SYNTAX_ASSIST = 1
compile endif

-- 1 means to include C++ assist, 0 means omit it.
compile if not defined(CPP_SYNTAX_ASSIST)
   CPP_SYNTAX_ASSIST = C_SYNTAX_ASSIST
compile endif

compile if not defined(C_TABS)
   C_TABS    = '3'
compile endif
compile if not defined(C_MARGINS)
   C_MARGINS = 1 MAXMARGIN 1
compile endif

-- Similarly for E, Rexx and Pascal support.
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
   --REXX_SYNTAX_ASSIST = 0  -- changed by aschn
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

-- Tab and margin settings for normal (not C/E/PAS) files.
compile if not defined(DEFAULT_TABS)
   DEFAULT_TABS    = '8'
compile endif
compile if not defined(DEFAULT_MARGINS)
   DEFAULT_MARGINS = 1 MAXMARGIN 1
compile endif

-- This constant tells the compiler which key should trigger the
-- syntax-assist second expansion.  Choose either ENTER or C_ENTER.
compile if not defined(ASSIST_TRIGGER)
   ASSIST_TRIGGER = 'ENTER'
compile endif

-- Set this to the desired indentation if using syntax-assist.
-- Normal values are 2, 3, 8.  Has no effect if not using assist.
compile if not defined(SYNTAX_INDENT)
   SYNTAX_INDENT = 3
compile endif

-- Set this to 1 if you like PE2's method of reflowing a paragraph -- moving
-- the cursor to the next paragraph.
compile if not defined(REFLOW_LIKE_PE)
   --REFLOW_LIKE_PE = 0  -- changed by aschn
   REFLOW_LIKE_PE = 1
compile endif

-- Ver.3.09:  Set this to 1 if you want the FILE key to quit rather than
-- save the file if the file was not modified.  Has the side effect that
-- the Name command sets .modify to 1.
compile if not defined(SMARTFILE)
   --SMARTFILE = 0  -- changed by aschn
   SMARTFILE = 1
compile endif

-- Set this to 1 if you want the Save key to prompt you if the file was not
-- modified.  the side effect that
compile if not defined(SMARTSAVE)
   --SMARTSAVE = 0  -- changed by aschn
   SMARTSAVE = 1
compile endif

-- Set this to 1 if you want the QUIT key to let you press the FILE key if the
-- file was modified.  You must also set the FILEKEY to be the key you use.
-- NOTE:  This only affects the key accepted as meaning "File" when the QUIT
-- key is pressed and the file has been modified.  If you want to use a
-- different FILE key than the default, you still have to define it yourself in
-- MYKEYS.E.  Also, SMARTQUIT doesn't apply to EPM.
-- (No effect if using EPM.)
compile if not defined(SMARTQUIT)
; obsolete
   SMARTQUIT = 0
compile endif
compile if not defined(FILEKEY)
   -- Note:  Must be a string (in quotes).
   FILEKEY   = 'F4'
compile endif

-- This is used as the decimal point in MATH.E.  Some users might prefer to
-- use a comma.  Not used in DOS version, which only allows integers.
compile if not defined(DECIMAL)
   DECIMAL = '.'
compile endif

-- 3.12:  Window support can be omitted completely, for those wanting a
--         minimal-sized E.
-- (No effect if using EPM.)
compile if not defined(WANT_WINDOWS)
; obsolete
   -- Don't change.  No window support in EPM
   WANT_WINDOWS = 0
compile endif

-- Ver.3.09:  Set this to 1 for Jim Hurley-style windows - zoomed window
-- in messy mode shows no box and respects window-style.
-- (No effect if using EPM.)
compile if WANT_WINDOWS
 compile if not defined(JHwindow)
; obsolete
   JHwindow = 0
 compile endif
compile endif

-- This determines if DRAW.E will be included.  Set to 'F6'
-- if you want it associated with that key; set to 1 if you want the DRAW
-- command but no key set; set to 0 to have DRAW.E omitted completely.
--
-- Ver 4.02:  In EOS2 the Draw feature is not compiled into the base.  Draw
-- is always available (as an external module) regardless of whether this
-- constant is 0 or 1.  You should still set this to 'F6' if you want the key.
compile if not defined(WANT_DRAW)
   WANT_DRAW = 'F6'
compile endif

-- Ver.4.11:  Pick the name of the sort utility you prefer.  Choices are:
--   ''    for none:  no sort command at all.
--   'E'   for the standard internal (E-language) sort.  Good for small jobs,
--         no external utility, no disk access.  Runs in OS/2 protect mode.
--   'DLL' to use the quicksort dynamic link library.  Good for all jobs.
--         This requires the QISRTMEM.DLL and QISRTSTB.DLL files
--         to be placed in the LIBPATH.  Limited to 64k of data.
--   'EPM' The best method to use, but only for EPM 5.60 or above.
--         Fastest, with no size limits.
-- The rest require E3SORT PACKAGE....
--   'F'   to use the external program FSORT.COM.
--   'G'   to use the external program GSORT.COM.  Best for numeric columns.
--   'GW'  to use the external program GWSORT.COM.  Recommended since it
--         can handle files larger than available memory.
--   'DOS' to use the external program SORT.EXE supplied with DOS or OS/2.
--         Not recommended:  slowest, ignores upper/lower case.  But available
--         in OS/2 protect mode.
compile if not defined(SORT_TYPE)
   -- At long last - an internal sort.
   SORT_TYPE = 'EPM'
compile endif

-- Set this to 0 if you want the marked area left unmarked after the sort.
compile if SORT_TYPE
 compile if not defined(RESTORE_MARK_AFTER_SORT)
   RESTORE_MARK_AFTER_SORT = 1
 compile endif
compile endif

-- Ver.3.10:  Set this to 1 if you use the DOS 3.3 APPEND command.  Without
-- this, if a file is found via APPEND, E3 will load it as if it were found
-- in the current subdirectory.  If the file is then saved, the original file
-- will not be updated, but a new file will be created in the current directory.

-- Ver.3.11:  Can be used even if you don't use the APPEND command; just set
-- the APPEND variable to the path desired.

-- EOS2 4.02:  On OS/2 we'll search the DPATH for text files if this is 1.
compile if not defined(USE_APPEND)
; obsolete
   USE_APPEND = 0
compile endif

-- Ver.3.11:  SETSTAY determines which is to be the current line after a Change
-- command.  If SETSTAY = 0, then the cursor will be positioned on the last
-- occurrence of the string in the file.  If SETSTAY = 1, then the position of
-- the cursor will not be changed.  If SETSTAY = '?', then a new command, STAY,
-- will be added to let the user change this dynamically.  If SETSTAY='?' then
-- STAY will be initialized in the next section.
compile if not defined(SETSTAY)
   --SETSTAY = 0  -- changed by aschn
   SETSTAY = '?'
compile endif

-- EOS2:  This constant enables a small DEFEXIT which keeps you in the editor
-- after you've quit the last file.  See EXIT.E for details.
-- (No effect if using EPM.)
compile if not defined(ASK_BEFORE_LEAVING)
   -- Not supported in EPM: Let this undefined!
   --ASK_BEFORE_LEAVING = 0
compile endif

-- Ver. 3.11d:  This constant lets the E3 user omit the SaveFileWithTabs
-- routine in STDPROCS.E.
compile if not defined(WANT_TABS)
   WANT_TABS = 1
compile endif

;-- Ver. 3.11d:  This constant lets the user specify where the cursor should
;-- be when starting E.  0 means in the file area, 1 means on the command line.
;-- (No effect if using EPM.)
compile if not defined(CURSOR_ON_COMMAND)
; obsolete
   CURSOR_ON_COMMAND = 0
compile endif

/* specifies whether the process window will be used.*/
/* a process window allows the editor to view output */
/* directed to the standard output device (stdout)   */
/* as if it were directed into an editor file        */
-- (No effect if using EPM.)
; obsolete
   SHELL_USAGE = 0

-- Ver. 3.12:  Lets you include the routine that searches a path for a file
-- even if USE_APPEND = 0.  (If USE_APPEND = 1, this routine will be included
-- automatically.)
-- Also enables the 'editpath' command.
compile if not defined(WANT_SEARCH_PATH)
   --WANT_SEARCH_PATH = 0  -- changed by aschn
   WANT_SEARCH_PATH = 1
compile endif

-- Ver. 3.12:  Lets you include the routine that gets the value of an
-- environment variable even if USE_APPEND = 0. (If USE_APPEND = 1, this
-- routine will be included automatically.)
-- Ver. 4.12:  The default is 1 rather than 0; OS/2 users have more room.
compile if not defined(WANT_GET_ENV)
   WANT_GET_ENV = 1
compile endif

-- status line configuration
-- Standard EPM >= 5.21: undefined
-- Now handled as arg(1) of 'setstatuscolor' by sending a windowmessage
;compile if not defined(STATUS_TEMPLATE)
;   STATUS_TEMPLATE=   'Line %l of %s   Column %c  %i   %m   %f   EPM 'EVERSION
;   -- Template for status line.  %l = current line; %s = size of file,
;   -- %c = current column; %i = Insert/Replace; %m = Modified/<blank>
;   -- %z = character above cursor in decimal; %x = character above cursor in hex;
;   -- %f = 1 file/<n> files
;compile endif

;  We've provided three methods of showing the modified status.
;  1. The COLOR method changes the window color, for a very obvious indicator.
;  2. The FKTEXTCOLOR method changes the color of the bottom line of the
;     screen, for EOS2 only.
;  3. The TITLE method does one of two things.  For EOS2 it changes the color
;     of the filename.  For EPM it adds the string " (mod)" to the title bar.
;     This isn't as obvious as COLOR, but you can check it even when the file
;     is shrunk to an icon by clicking on the icon.
-- If user didn't define in MYCNF,
compile if not defined(SHOW_MODIFY_METHOD)
; obsolete
   -- if PM, then modified state is on status line
   SHOW_MODIFY_METHOD = ''
compile endif

-- Lets you quit temporary files regardless of the state of the .modify bit.
-- Temporary files are assumed to be any file where the first character of the
-- .filename is a period.  If set to 1, you won't get the "Throw away changes?"
-- prompt when trying to quit one of these files.
compile if not defined(TRASH_TEMP_FILES)
   TRASH_TEMP_FILES = 0
compile endif

-- Adds LOCK and UNLOCK commands.
compile if not defined(WANT_LAN_SUPPORT)
   --WANT_LAN_SUPPORT = 0  -- changed by aschn
   WANT_LAN_SUPPORT = 1
compile endif

-- Include or omit the MATH routines.  Values are '?' meaning do a TRYINCLUDE
-- (this is what we used to do), 1 meaning it's required, so do an INCLUDE, or
-- 0 meaning it's not wanted, so don't try to include it at all.
compile if not defined(WANT_MATH)
   WANT_MATH = '?'
compile endif

-- Include the MATHLIB routines in the base .EX file.  Ignored for E3.  Default
-- is 0 for OS/2 versions, which means that a separate MATHLIB.EX file is linked
-- at runtime if any MATH commands are executed.  May be set to 1 if you have
-- sufficient room in your EPM.EX file and don't want to maintain a MATHLIB.EX.
-- Will be ignored if EXTRA_EX is 1. (In EPM EXTRA_EX is undefined.)
compile if not defined(INCLUDE_MATHLIB)
   INCLUDE_MATHLIB = 0
compile endif

-- Include or omit the DOSUTIL routines.  Values are '?' meaning do a TRYINCLUDE
-- (this is what we used to do), 1 meaning it's required, so do an INCLUDE, or
-- 0 meaning it's not wanted, so don't try to include it at all.
-- Note that Use_Append=1 or Host_Support='EMUL' forces DOSUTIL to be included.
compile if not defined(WANT_DOSUTIL)
   WANT_DOSUTIL = '?'
compile endif

-- This provides a simple way to omit all user includes, for problem resolution.
-- If you set VANILLA to 1 in MYCNF.E, then no MY*.E files will be included.
compile if not defined(VANILLA)
   VANILLA = 0
compile endif

-- Optionally include Larry Margolis' ALL command.
compile if not defined(WANT_ALL)
   --WANT_ALL = 0  -- changed by aschn
   WANT_ALL = 1
compile endif

-- Optionally include Ralph Yozzo's RETRIEVE command.
compile if not defined(WANT_RETRIEVE)
; obsolete
   WANT_RETRIEVE = 0
compile endif

-- This defines the limit on the number of files that will be included in the Ring
-- pulldown.  If more than this many files are in the ring, the (MENU_LIMIT + 1)
-- entry will be "More...".  One exception - if you set this to 0, then the routine
-- UpdateRingMenu will never be called (or defined), there will be no Ring pulldown,
-- and instead a "List files in ring" entry will be added to the Options pulldown.
-- This means that adding files to or removing them from the ring will be faster.
compile if not defined(MENU_LIMIT)
; obsolete
   MENU_LIMIT = 0
compile endif

-- Spelling support can now be optionally included.  Set to 1 to include, 0 to
-- omit, and 'LINK' to link in at runtime.  E3 can't link.  EPMLEX comes with
-- the distributed macros; EOS2LEX and E3SPELL are available separately.
-- New:  set to 'DYNALINK' to only link in if the user needs it.
compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 'DYNALINK'          -- New default
compile endif

-- Enhanced print support for EPM - can display list of printers.
compile if not defined(ENHANCED_PRINT_SUPPORT)
   ENHANCED_PRINT_SUPPORT = 1
compile endif

/* Specifies whether support should be included   */
/* for a shell window.                            */
compile if not defined(WANT_EPM_SHELL)
   --WANT_EPM_SHELL = 0  -- changed by aschn
   WANT_EPM_SHELL = 1
compile endif

-- Specify a string to be written whenever a new EPM command shell window
-- is opened.  Normally a prompt command, but can be anything.  If the
-- string is one of the ones shown below, then the Enter key can be used
-- to do a write-to-shell of the text following the prompt, and a listbox
-- can be generated showing all the commands which were entered in the
-- current shell window.  If a different prompt is used, EPM won't know
-- how to parse the line to distinguish between the prompt and the command
-- that follows, so those features will be omitted.
compile if not defined(EPM_SHELL_PROMPT)
   EPM_SHELL_PROMPT = '@prompt epm: $p $g '
;; EPM_SHELL_PROMPT = '@prompt [epm: $p ] '  -- Also supported
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

-- When the File Manager copies a file from a HPFS drive to a FAT drive,
-- if the file name isn't in 8.3 format, it gets truncated, with the original
-- name being preserved in a .LONGNAME extended attribute.  Setting this to 1
-- will cause the long name to be displayed on the EPM title bar, instead of the
-- real (short) name.
compile if not defined(WANT_LONGNAMES)
   --WANT_LONGNAMES = 0  -- changed by aschn
   WANT_LONGNAMES = 'SWITCH'
   -- 'SWITCH' activates MY_SHOW_LONGNAMES, default is now: 1
compile endif

-- Adds PUSHMARK, POPMARK, PUSHPOS and POPPOS commands.  For EPM, also adds
-- pulldown entries to the action bar.
compile if not defined(WANT_STACK_CMDS)
   --WANT_STACK_CMDS = 0  -- changed by aschn
   WANT_STACK_CMDS = 'SWITCH'
   -- 'SWITCH' activates MY_STACK_CMDS, default is now: 1, defined in MENUACCEL.E
compile endif

-- WANT_CUA_MARKING causes the mouse definitions to be limited to the CUA actions,
-- instead of the more powerful standard EPM actions.  Also causes typing
-- while a mark exists to delete the mark, and Del to delete a mark if one
-- exists, instead of always deleting a text character.  Can be set to 1, to
-- behave this way all the time, or to 'SWITCH' to enable switching it on and
-- off.  The default is 0, meaning that the standard EPM settings are in effect.
compile if not defined(WANT_CUA_MARKING)
   --WANT_CUA_MARKING = 0  -- changed by aschn
   WANT_CUA_MARKING = 'SWITCH'
   -- 'SWITCH' activates MY_CUA_MARKING_SWITCH, default is: 0
compile endif

-- MOUSE_SUPPORT only applies to EPM.  It can should normally be set to 1,
-- to have mouse support compiled into the base .EX file.  It can be set to
-- 'LINK' to have mouse support linked in at run time, or to 0 to omit mouse
-- support completely.
compile if not defined(MOUSE_SUPPORT)
   MOUSE_SUPPORT = 1
;   MOUSE_SUPPORT = 'LINK'  doesn't work
compile endif

-- WANT_DM_BUFFER specifies whether a "deletemark buffer" is used in EPM.
-- If so, any time a mark is deleted, a copy is saved in a buffer.  An entry on
-- the Edit pulldown can be used to paste this buffer back into the editor.
-- Not as useful as it originally was, since full undo has been added.
compile if not defined(WANT_DM_BUFFER)
   --WANT_DM_BUFFER = 0  -- changed by aschn
   WANT_DM_BUFFER = 1
compile endif

-- WANT_STREAM_MODE enables stream mode editing, in which we pretend to be a
-- stream mode editor instead of a line mode editor.  Can be set to 1, to
-- behave this way all the time, or to 'SWITCH' to enable switching it on and
-- off.  The default is 0, meaning forget stream mode entirely.
compile if not defined(WANT_STREAM_MODE)
   --WANT_STREAM_MODE = 0  -- changed by aschn
   WANT_STREAM_MODE = 'SWITCH'
   -- 'SWITCH' activates MY_STREAM_MODE, default is now: 1
compile endif

-- WANT_STREAM_INDENTED lets you specify that if the Enter key splits a line,
-- the new line should be indented the same way the previous line was.
compile if not defined(WANT_STREAM_INDENTED)
   --WANT_STREAM_INDENTED = 0  -- changed by aschn
   WANT_STREAM_INDENTED = 1
compile endif

-- ENHANCED_ENTER_KEYS (EPM_only) specifies that the user can configure each
-- variant of the enter or ctrl-enter key separately, via a dialog.  Great for
-- LAN installations, so people can use a common .EX but still customize the
-- keys.
compile if not defined(ENHANCED_ENTER_KEYS)
   --ENHANCED_ENTER_KEYS = 0  -- changed by aschn
   ENHANCED_ENTER_KEYS = 1
compile endif

-- RING_OPTIONAL makes it so you can enable or disable having more than one
-- file in the ring.  Pretty useless, but the CUA people insisted on it.
-- Most people will want this to be set to 0, so that you always can load as
-- many files as you like.
compile if not defined(RING_OPTIONAL)
   --RING_OPTIONAL = 0  -- changed by aschn
   RING_OPTIONAL = 1
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

-- WANT_DYNAMIC_PROMPTS specifies whether support for dynamic prompting is
-- included or not.  (EPM only.)  If support is included, the actual prompts
-- can be enabled or disabled from a menu pulldown.  Keeping this costs about
-- 3k in terms of .EX space.
-- (Dynamic prompts = hints for menu items on the message line)
compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 1
compile endif

-- WANT_BOOKMARKS specifies whether support for bookmarks is included or not.
-- (EPM only.)  Can be set to 0, 1, or 'LINK'.
compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 1
;   WANT_BOOKMARKS = 'LINK'
compile endif

-- CHECK_FOR_LEXAM specifies whether or not EPM will check for Lexam, and only include
-- PROOF on the menus if it's available.  Useful for product, if we're not shipping Lexam
-- and don't want to advertise spell checking; a waste of space internally.
compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
compile endif

-- Set this to 1 to include bracket-matching (Ctrl+[)
compile if not defined(WANT_BRACKET_MATCHING)
   --WANT_BRACKET_MATCHING = 0  -- changed by aschn
   WANT_BRACKET_MATCHING = 1
compile endif

-- For GPI version of EPM, this lets you select an AVIO-style underline cursor instead
-- of the GPI-style vertical bar.
compile if not defined(UNDERLINE_CURSOR)
   UNDERLINE_CURSOR = 0
compile endif

-- Select which style pointer you prefer.
compile if EPM & not defined(EPM_POINTER)
   --EPM_POINTER = TEXT_POINTER      -- GPI version gets text pointer  -- changed by aschn
   EPM_POINTER = 'SWITCH'
compile endif

-- Obsolete const for older EPM versions:
-- We're getting too big to fit all the standard stuff into EPM.EX, even without
-- user additions, so this new option says to include a separate .EX file for
-- MOUSE, MARKFILT, BOOKMARK, CLIPBRD, CHAROPS, DOSUTIL, ALL, MATH and SORT.
compile if not defined(EXTRA_EX)
; obsolete
   -- Don't change this!
   EXTRA_EX = 0
compile endif

-- Add support for looking up keywords in an index file and getting help.
-- See KWHELP.E for details.  EPM only.
compile if not defined(WANT_KEYWORD_HELP)
   --WANT_KEYWORD_HELP = 0  -- changed by aschn
   WANT_KEYWORD_HELP = 1
compile endif

-- By default, in EPM we block the action of action bar mnemonics being
-- automatic accelerators.  Some users might not want this.  Can be 'SWITCH'.
compile if not defined(BLOCK_ACTIONBAR_ACCELERATORS)
   --BLOCK_ACTIONBAR_ACCELERATORS = 1  -- changed by aschn
   BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
compile endif

-- Define the default PASTE action for Shift+Ins.  Can be '' (for Paste Lines),
-- 'B' (for Paste Block), or 'C' (for standard PM character mark).
compile if not defined(DEFAULT_PASTE)
   DEFAULT_PASTE = 'C'
compile endif

-- Include Rexx support?  (EPM 5.50 or above only.)
compile if not defined(WANT_REXX)
   WANT_REXX = 1
compile endif

-- Search for a Rexx profile?  (EPM 5.50 or above only.)
compile if not defined(WANT_PROFILE)
   --WANT_PROFILE = 0  -- changed by aschn
   WANT_PROFILE = 'SWITCH'
compile endif

compile if WANT_PROFILE & not WANT_REXX
   *** Error:  Can not have WANT_PROFILE set if WANT_REXX is 0.
compile endif

-- Toggle Escape key?  Default EPM for Boca doesn't use Esc to bring up command
-- dialog, but all "real" EPM users want it.
compile if not defined(TOGGLE_ESCAPE)
   --TOGGLE_ESCAPE = 0  -- changed by aschn
   TOGGLE_ESCAPE = 1
compile endif

-- Toggle Tab key?  Some people want the Tab key to insert a tab, rather than
-- inserting spaces to the next tab stop.
compile if not defined(TOGGLE_TAB)
   -- TOGGLE_TAB = 1 means: define the 'tabkey' command
   --TOGGLE_TAB = 0  -- changed by aschn
   TOGGLE_TAB = 1
compile endif

-- Make menu support optional for people using the E Toolkit who want to
-- use most of the standard macros.  *Not* for most users.
compile if not defined(INCLUDE_MENU_SUPPORT)
   INCLUDE_MENU_SUPPORT = 1
compile endif

-- For people using the E Toolkit who want to include the base menu support,
-- but supply their own menus.  *Not* for most users.  Omits STDMENU.E,
-- loaddefaultmenu cmd,
compile if not defined(INCLUDE_STD_MENUS)
   INCLUDE_STD_MENUS = 1
compile endif

-- The compiler support is only included if the bookmark support is; this lets
-- you omit the former while including the latter.
compile if not defined(INCLUDE_WORKFRAME_SUPPORT)
   INCLUDE_WORKFRAME_SUPPORT = 1
compile endif

-- For Toolkit developers - set to 0 if you don't want the user to be able
-- to go to line 0.  Affects MH_gotoposition in MOUSE.E and Def Up in STDKEYS.E.
compile if not defined(TOP_OF_FILE_VALID)
   -- Can be '0', '1', or 'STREAM' (dependant on STREAM_MODE)
   --TOP_OF_FILE_VALID = 1  -- changed by aschn
   TOP_OF_FILE_VALID = 0
compile endif

-- EBOOKIE support desired?  0=no; 1=include bkeys.e; 'LINK'=always link BKEYS
-- at startup; 'DYNALINK'=support for dynamically linking it in.
compile if not defined(WANT_EBOOKIE)
   WANT_EBOOKIE = 'DYNALINK'
compile endif

-- Starting in EPM 5.50, EPM was modified so that when scrolling with the
-- scroll bars, the cursor would stay in the same text-relative location, and
-- could move off the window; pressing a key that moved the cursor would then
-- cause the displayed text to jump back so that the cursor was visible.
-- We were told to make this change in order to comply with CUA, but most
-- users found it horribly confusing and annoying.  Starting with 5.60, we
-- can work either way; the default is now that we do what people prefer.
compile if not defined(KEEP_CURSOR_ON_SCREEN)
   KEEP_CURSOR_ON_SCREEN = 1
compile endif

-- E Toolkit users might want to omit support for accessing the application
-- .INI file (e.g., EPM.INI).
compile if not defined(WANT_APPLICATION_INI_FILE)
   WANT_APPLICATION_INI_FILE = 1
compile endif

-- Support for a TAGS file (EPM 5.60 or above, only).
compile if not defined(WANT_TAGS)
   --WANT_TAGS = 0  -- changed by aschn
   WANT_TAGS = 'DYNALINK'
compile endif

-- Unmark after doing a move mark?
compile if not defined(UNMARK_AFTER_MOVE)
   UNMARK_AFTER_MOVE = 0
compile endif

-- Keep EPM's Preferences and Frame menus up after a selection?
compile if not defined(WANT_NODISMISS_MENUS)
   WANT_NODISMISS_MENUS = 1
compile endif

-- Allow menu prompting even if status line is at top of edit window
-- (and so menus would overlay prompts)?
compile if not defined(ALLOW_PROMPTING_AT_TOP)
   ALLOW_PROMPTING_AT_TOP = 1
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
   SUPPORT_USER_EXITS = 1
compile endif
compile if not defined(INCLUDE_BMS_SUPPORT)
   INCLUDE_BMS_SUPPORT = 0
compile endif

-- Lets EOS2 users delay the SAVEPATH check the way that EPM does, so that a
-- DEFINIT can modify the value before E3EMUL checks it.
compile if not defined(DELAY_SAVEPATH_CHECK)
; obsolete
   DELAY_SAVEPATH_CHECK = 0
compile endif

compile if not defined(LOCATE_CIRCLE_STYLE)
   --LOCATE_CIRCLE_STYLE = 1  -- changed by aschn
   LOCATE_CIRCLE_STYLE = 5         -- (1)     filled oval
compile endif
compile if not defined(LOCATE_CIRCLE_COLOR1)
   --LOCATE_CIRCLE_COLOR1 = 16777220  -- changed by aschn
   LOCATE_CIRCLE_COLOR1 = 16777231 -- (16777220) complementary
compile endif
compile if not defined(LOCATE_CIRCLE_COLOR2)
   -- for styles 2 and 4 only
   --LOCATE_CIRCLE_COLOR2 = 16777218  -- changed by aschn
   LOCATE_CIRCLE_COLOR2 = 16777216 -- (16777218) complementary
compile endif
compile if not defined(HIGHLIGHT_COLOR)
   HIGHLIGHT_COLOR = 14            --         This must be set to enable circle colors
compile endif

-- Include support for toolbar (EPM 6.00+ only)
compile if not defined(WANT_TOOLBAR)
   WANT_TOOLBAR = 1
compile endif

-- Use System Monospaced as default font, rather than the PM default.
compile if not defined(WANT_SYS_MONOSPACED)
   --WANT_SYS_MONOSPACED = 0  -- changed by aschn
   WANT_SYS_MONOSPACED = 1
compile endif

-- Specify the size of the System Monospaced font to use.  Default is 0, which
-- means system picks it.  (Generally, 20x9)  Could set 'WW8HH16' for 16x8, etc.
-- Applies to MONOFONT cmd as well as (if WANT_SYS_MONOSPACED set) to default font.
-- 1995/05/30  Changed default size to 10.  A 10 point size looks good on most
-- displays, while specifying 0 gave too large a font on VGA.
compile if not defined(SYS_MONOSPACED_SIZE)
   SYS_MONOSPACED_SIZE = 10
compile endif

-- Allow pressing tab in insert mode to insert spaces to next tab stop in
-- line mode as well as in stream mode.
compile if not defined(WANT_TAB_INSERTION_TO_SPACE)
   -- for line mode only
   WANT_TAB_INSERTION_TO_SPACE = 0
compile endif

-- Tree support - TREE command & related stuff.  Works best in EPM 5.60 &
-- above due to long line support, but will work in earlier EPM and even
-- EOS2.
compile if not defined(WANT_TREE)
   WANT_TREE = 'DYNALINK'
compile endif

-- For GPI, we manage the cursor ourself.  This provides an alternate to
-- UNDERLINE_CURSOR, to allow changing the shape at runtime.
compile if not defined(DYNAMIC_CURSOR_STYLE)
   --DYNAMIC_CURSOR_STYLE = 0  -- changed by aschn
   DYNAMIC_CURSOR_STYLE = 1
compile endif

-- For EPM 6.00, we have the ability to be a Workplace Shell object.  If we
-- are, the configuration information comes from the object and not the .INI
-- file.  This saves a good amount of startup time.
compile if not defined(WPS_SUPPORT)
   --WPS_SUPPORT = EPM32  -- changed by aschn
   WPS_SUPPORT = 0
compile endif

-- Delay the building of the menus?  Gives faster startup for EPM 6.01, where
-- we can load a dummy menu from a resource as a placeholder.  For earlier
-- versions, the extra redrawing of the windows makes this not worthwhile.
-- People who use external add-ons that update the menus might prefer to
-- turn this off, to simplify the addition of those packages.
compile if not defined(DELAY_MENU_CREATION)
;; DELAY_MENU_CREATION = EVERSION >= '6.01'
; obsolete
   DELAY_MENU_CREATION = 0  -- Traps in PMWIN.DLL; leave off for now.
compile endif

-- Use the normal-sized or the tiny icons for the built-in toolbar?
compile if not defined(WANT_TINY_ICONS)
   WANT_TINY_ICONS = 0
compile endif

-- Support the Shift+cursor movement for marking?
compile if not defined(WANT_SHIFT_MARKING)
   WANT_SHIFT_MARKING = EPM
compile endif

-- Respect the Scroll lock key?  If set to 1, Shift+F1 - Shift+F4 must not be
-- redefined.  (The cursor keys execute those keys directly, in order to
-- avoid duplicating code.)  Note that setting this flag turns off the internal
-- cursor key handling, so if WANT_CUA_MARKING = 'SWITCH',
-- WANT_STREAM_EDITING = 'SWITCH', and RESPECT_SCROLL_LOCK = 1, cursor movement
-- might be unacceptably slow.
compile if not defined(RESPECT_SCROLL_LOCK)
   --RESPECT_SCROLL_LOCK = 0  -- changed by aschn
   RESPECT_SCROLL_LOCK = 1
compile endif

-- Should word-marking use a character or block mark?
compile if not defined(WORD_MARK_TYPE)
;compile if WANT_CHAR_OPS
;  WORD_MARK_TYPE = 'CHAR'
;compile else
   -- Bug using 'BLOCK':
   -- If a block is copied to the clipboard, a CRLF is appended.
   -- Sh+Ins will insert this CRLF instead of ignoring it.
   --WORD_MARK_TYPE = 'BLOCK'  -- changed by aschn
   WORD_MARK_TYPE = 'CHAR'
;compile endif
compile endif

-- EPM 6 by default remembers the last-loaded file from the open dialog, and
-- starts the full file dialog in that directory instead of in the current
-- directory.  Set this if you prefer the current directory.
compile if not defined(USE_CURRENT_DIRECTORY_FOR_OPEN_DIALOG)
   USE_CURRENT_DIRECTORY_FOR_OPEN_DIALOG = 0
compile endif

-- EPM 6-only; uses EGREP searches.
-- Include procedures for dealing with sentences and paragraphs?
;compile if EVERSION < 6
;   WANT_TEXT_PROCS = 0
;compile elseif not defined(WANT_TEXT_PROCS)
compile if not defined(WANT_TEXT_PROCS)
   WANT_TEXT_PROCS = 1
compile endif

include NLS_LANGUAGE'.e'

-- This defines the "Directory of" string searched for by Alt-1 in DIR output.
-- (User-definable for NLS requirements.)
compile if not defined(DIRECTORYOF_STRING)
   DIRECTORYOF_STRING = DIR_OF__MSG
compile endif

compile if not defined(LINK_NEPMDLIB)
   LINK_NEPMDLIB = 'DEFINIT'
compile endif
-------------------------------------------------------------------------------

; -------- Set universal vars and init misc --------

definit
universal expand_on, matchtab_on, default_search_options
universal vTEMP_FILENAME, vTEMP_PATH, vAUTOSAVE_PATH
;compile if EVERSION < 5
;   universal ZoomWindowStyle, comsfileid, messy
;compile else
   universal edithwnd, MouseStyle, appname
; compile if EVERSION >= '5.20'
   universal app_hini
   universal nepmd_hini
   universal CurrentHLPFiles
; compile endif
; compile if EVERSION >= '5.21'
   universal vSTATUSCOLOR, vMESSAGECOLOR
;  compile if EVERSION >= '5.60'
   universal vDESKTOPCOLOR
;  compile endif
; compile endif
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
compile endif
compile if ENHANCED_ENTER_KEYS
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
compile endif
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
   universal EPM_utility_array_ID, defaultmenu, font
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal  ADDENDA_FILENAME
   universal  DICTIONARY_FILENAME
compile if WANT_EPM_SHELL
   universal shell_index
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
;compile endif
;compile if EVERSION < '4.12'
;   universal autosave
;compile endif
compile if HOST_SUPPORT
   universal hostcopy
compile endif
compile if SETSTAY='?'
   universal stay
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
compile endif
;compile if EVERSION >= '5.50'
   universal default_font
compile if DYNAMIC_CURSOR_STYLE
   universal cursordimensions
compile endif
;compile endif
   universal bitmap_present
compile if WANT_LONGNAMES = 'SWITCH'
   universal SHOW_LONGNAMES
compile endif
compile if WANT_PROFILE = 'SWITCH'
   universal REXX_PROFILE
compile endif
compile if TOGGLE_ESCAPE
   universal ESCAPE_KEY
compile endif
compile if TOGGLE_TAB
   universal TAB_KEY
compile endif
   universal save_with_tabs, default_edit_options, default_save_options
   universal last_append_file
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif
;compile if EPM
compile if WPS_SUPPORT
   universal wpshell_handle
   wpshell_handle = windowmessage(1,  getpminfo(EPMINFO_OWNERFRAME),
                                5152,    -- EPM_QUERY_CONFIG
                                getpminfo(EPMINFO_EDITCLIENT),
                                0)
   if wpshell_handle then
      call dynalink32('DOSCALLS',
                      '#302',  -- Dos32GetSharedMem
                      atol(wpshell_handle) ||  -- Base address
                      atol(1))             -- PAG_READ
   endif
compile endif
;compile endif

-- set automatic syntax expansion 0/1
compile if defined(my_expand_on)
   expand_on        = my_expand_on
compile else
   expand_on        = 1
compile endif

-- set default matchtab to 0 or 1
compile if defined(my_matchtab_on)
   matchtab_on      = my_matchtab_on
compile else
   matchtab_on      = 0
compile endif

-- tabglyph: show a circle for the tab char
   call tabglyph(1)

;compile if EVERSION < 5
;
;-- set default zoom window style
;compile if defined(my_ZoomWindowStyle)
;   ZoomWindowStyle  = my_ZoomWindowStyle
;compile else
;   ZoomWindowStyle  = 1
;compile endif
;
;-- set autosave initial value
; compile if EVERSION < '4.12'
;  compile if defined(my_autosave)
;   autosave         = my_AUTOSAVE
;  compile else
;   autosave         = DEFAULT_AUTOSAVE
;  compile endif
; compile endif    -- EVERSION < 4.12
;
;-- set to 1 for messy-desk windowing
; compile if WANT_WINDOWS
;  compile if defined(my_messy)
;   messy            = my_messy
;  compile else
;   messy            = 0
;  compile endif
; compile else        -- No windowing ==> no choice of windowing style.
;   messy            = 0    -- Do not change this copy!!!
; compile endif
;
;compile endif  -- EVERSION < 5


-- This option JOIN_AFTER_WRAP specifies whether to join the
-- next line after a word-wrap.  To see its effect:  set margins to 1 79 1;
-- go into insert mode; type a few characters into this line to cause a wrap.
-- (sample next line)
-- If join_after_wrap = 1, you'll get:
--    wrap. -- (sample next line)
-- If join_after_wrap = 0, you'll get:
--    wrap.
--    -- (sample next line)
compile if defined(my_join_after_wrap)
   join_after_wrap = my_join_after_wrap
compile else
   join_after_wrap = 1
compile endif


-- This option CENTER_SEARCH specifies how the cursor moves
--   during a search or replace operation.
-- 0 :  Hold the cursor fixed; move the word to the cursor.  Like old E.
-- 1 :  Move the cursor to the word if it's visible on the current screen,
--      to minimize text motion.  Else center the word in mid-screen.
compile if defined(my_center_search)
   center_search = my_center_search
compile else
   center_search = 1
compile endif

;compile if not EPM
;-- This option TOP_OF_FILE_FIXED specifies whether the
;--   "Top of File" line is allowed to move down from the top of the window.
;-- 0 :  Allow the line to move down, so that cursor operations act the same
;--      regardless of proximity to top of file.  For example, the key Shift-F5
;--      (center the current line) will move the top-of-file line down if that's
;--      what's needed to center the current line in a small file.
;-- 1 :  Hold the line fixed; some cursor operations will change their behavior
;--      as the cursor approaches the top of file.  Shift-F5 will not center the
;--      current line in a small file.
; compile if defined(my_top_of_file_fixed)
;   top_of_file_fixed = my_top_of_file_fixed
; compile else
;   top_of_file_fixed = 1
; compile endif
;compile endif

-- Ver. 4.12:  Some users want only one space after a period or colon when
-- they reflow a paragraph.  This is a predefined universal variable similar to
-- top_of_file_fixed, so a macro can switch it on and off when desired for
-- special purposes.
--    1 (TRUE)  ==>  supply two spaces after a sentence or colon.
--    0 (FALSE) ==>  supply only one space.
;compile if EVERSION >= 4    -- not in E3
compile if defined(my_two_spaces)
   two_spaces = my_two_spaces
compile else
   -- Default is as before, two spaces after sentence.
   two_spaces = TRUE
compile endif
;compile endif

-- Default options for locate and change commands.  Pick from:
--
--   E  Exact match (case sensitive)    C  Case-insensitive (ignore case)
--   A  All text (ignore marks)         M  Marked area only
--   +  Advance thru file, top->bott    -  Backward, bottom -> top
--   F  Forward in line, left->right    R  Reverse in line, right->left
--
-- The standard is 'EA+F' to be compatible with previous releases; that's
-- what you get if you leave this blank.  Many users will prefer 'C'.
   -- default_search_options
   --    internal default: '+ef'
   --       +  from top to bottom      e  respect case
   --       -  from bottom to top      c  don't respect case
   --       f  from left to right      g  grep
   --       r  from right to left      x  extended grep
   --       a  in the whole file       w  search for words
   --       m  in the marked area      ~  negative search
compile if defined(my_default_search_options)
   default_search_options= my_default_search_options
compile else
   --default_search_options=''  -- changed by aschn
   default_search_options='+fac'
compile endif

compile if HOST_SUPPORT
 compile if defined(my_hostcopy)
   hostcopy= my_hostcopy
 compile else
;  compile if E3
;   hostcopy='mytecopy'    -- Default for DOS is MYTECOPY.
;  compile else
   hostcopy='almcopy'     -- Default for OS/2 is the OS/2 version of ALMCOPY.
;  compile endif
 compile endif
                        -- Could be mytecopy, e78copy, bondcopy, cp78copy, almcopy, etc.
                        -- Add options if necessary (e.g., 'mytecopy /nowsf')
compile endif


-- EOS2 ver 4.10:  E can now save files with tab compression.  You can choose
-- to save an individual file with tabs by issuing 'save /t' or 'file /t'.
-- If you want ALL files saved with tab compression, without specifying
-- the '/t', set this to 1.
compile if defined(my_save_with_tabs)
   save_with_tabs = my_save_with_tabs
compile else
   save_with_tabs = 0
compile endif

;compile if EVERSION < 5
;-- Four function_key_text strings now for four shift states.
;-- 80 characters (one line) max.  Broken into two strings here,
;-- with arrow graphics replaced with ASCII codes for printability.
;
; compile if defined(my_function_key_text)
;   function_key_text  = my_function_key_text
; compile else
;   compile if (WANT_DRAW=F6 | WANT_DRAW='F6') & not SMALL
;   function_key_text  = "F1=Help  2=Save  3=Quit  4=File         "||
;                        " 6=Draw  7=Name  8=Edit  9=Undo  10=Next"
;   compile else
;   function_key_text  = "F1=Help  2=Save  3=Quit  4=File         "||
;                        "         7=Name  8=Edit  9=Undo  10=Next"
;   compile endif
; compile endif
;
; compile if defined(my_a_function_key_text)
;   a_function_key_text= my_a_function_key_text
; compile else
;   a_function_key_text= "F1=LineChars                            "||
;                        "       7="\27"Shift  8=Shift"\26"        10=Prev"
; compile endif
;
; compile if defined(my_c_function_key_text)
;   c_function_key_text= my_c_function_key_text
; compile else
;   c_function_key_text= "F1=UpperWord  2=LowerWord  3=UpperMark  "||
;                        "4=LowerMark  5=BeginWord  6=EndWord     "
; compile endif
;
; compile if defined(my_s_function_key_text)
;   s_function_key_text= my_s_function_key_text
; compile else
;   s_function_key_text= "F1="\27"Scrl  2=Scrl"\26"  3=Scrl"\24"  4=Scrl"||
;                        \25"  5=CenterLine                               "
; compile endif
;
;-- This specifies how long you must hold down a shift/ctrl/alt key before
;-- the function_key_text changes.
;-- It's an arbitrary value:  2000 gives about 3/4 second delay on an AT.
;-- Set this to zero if you don't want the function_key_text to shift.
; compile if defined(my_function_key_text_delay)
;   function_key_text_delay = my_function_key_text_delay
; compile else
;   function_key_text_delay = 2000
;
;   -- On OS/2 real mode use about 1/10th of that.
;   if machine()='OS2REAL' or dos_version() >= 1000 then
;      -- for OS/2 real or DOS 3
;      function_key_text_delay = function_key_text_delay % 10
;   endif
;  compile if EVERSION >= '4.00'  -- Save a few bytes in DOS version
;-- In protect mode use machine-independent units, milliseconds!
;   if machine()='OS2PROTECT' then
;      -- OS/2 protect
;      function_key_text_delay = 800
;   endif
;  compile endif
; compile endif
;
;-- Note:  You'll want to change the f.k.texts if you define new keysets with
;-- different function keys.  The preferred method is:
;--    define your new keyset in a separate file (like CKEYS.E);
;--    write a small condition-check to select your keyset (like CKEYSEL.E);
;--    assign the new function_key_texts in the select file.
;compile endif  -- EVERSION < 5

; Init universal vars if the corresponding consts are defined to use variables
compile if WANT_LONGNAMES = 'SWITCH'
 compile if defined(my_SHOW_LONGNAMES)
   SHOW_LONGNAMES = my_SHOW_LONGNAMES
 compile else
   --SHOW_LONGNAMES = 0  -- changed by aschn
   SHOW_LONGNAMES = 1
 compile endif
compile endif

compile if WANT_PROFILE = 'SWITCH'
 compile if defined(my_REXX_PROFILE)
   REXX_PROFILE = my_REXX_PROFILE
 compile else
   --REXX_PROFILE = 0  -- changed by aschn
   REXX_PROFILE = 1
 compile endif
compile endif

compile if TOGGLE_ESCAPE
   --ESCAPE_KEY = 0  -- changed by aschn
   ESCAPE_KEY = 1
compile endif
compile if TOGGLE_TAB
   TAB_KEY = 0
compile endif

compile if SETSTAY='?'
 compile if defined(my_stay)
   stay = my_stay
 compile else
   stay = 0
 compile endif
compile endif

; We now save the constants in universal variables.  This way, they can be
; over-ridden at execution time by a definit (e.g., the user might check an
; environment variable to see if a VDISK has been defined, and if so, set the
; temp_path to point to it).  The constants are used as default initialization,
; and for compatability with older macros.
   vTEMP_FILENAME = TEMP_FILENAME
   vTEMP_PATH = TEMP_PATH
   vAUTOSAVE_PATH = AUTOSAVE_PATH

; Default options to be added to the EDIT command.  Normally null, some users
; might prefer to make it '/L'.
;  /L means to use the DOS convention that any line feed character (x'0A')
;     not paired with a carriage return (x'0D') should be left alone;
;     this is useful if you wish to use the line feed as a printer control.
;  /U means to use the Unix convention that a line feed alone is sufficient
;     to start a new line, whether or not it's paired with a CR.
; The default (if no options are given) is /U, the traditional E treatment.
; If you make /L the default, it can still be overridden on any specific
; EDIT command as by "EDIT /U filename".
; This choice makes no difference for normal text files with CR-LF for newline.
   -- default_edit_options
   --    internal default: '/b /nt /u'
   --       /b    don't load file from disk if already in ring
   --       /c    create a new file
   --       /d    load it from disk, even if already in ring
   --       /t    don't convert Tab's
   --       /nt   no tab chars: convert it into spaces
   --       /u    Unix line end: LF is line end and CR is ignored
   --       /l    DOS line end: CRLF is line end, CR's and LF's are text
   --       /64   wrap every line after 64 chars, on saving there will
   --             be no line end added at the wrap points if none of the
   --             following *save* options is set: /o /u /l
   --       /bin  binary mode: all chars are editable, note the difference
   --             between '/64 /bin' and '/bin /64'
   --    How to edit binary files?
   --       'e /t /l /64 /bin mybinary.file'
   --    Further options:
   --       /k0 /k /k1 /k2 /v /r /s /n*
compile if defined(my_default_edit_options)
   default_edit_options= my_default_edit_options
compile else
   --default_edit_options=''  -- changed by aschn
   default_edit_options='/b /t /l'
compile endif

; Default options to be added to the SAVE command.  Normally null, some users
; might prefer to make it '/S' (EPM 5.51 or above).
   -- default_save_options
   --    internal default: '/ns /nt /ne'?
   --       /s    strip trailing spaces
   --       /ns   don't strip spaces
   --       /e    append a file end char
   --       /ne   no file end char
   --       /t    convert spaces to tab chars
   --       /nt   don't convert spaces
   --       /q    quiet
   --       /o    insert CRLF as line end char
   --       /l    insert LF as line end char
   --       /u    Unix line end: insert LF as line end char and don't append a file end char
   --    How to save binary files?
   --       's /nt /ns /ne mybinary.file'
   --       This will only work, if none of /o /l /u is specified.
compile if defined(my_default_save_options)
   default_save_options= my_default_save_options
compile else
   --default_save_options=''  -- changed by aschn
   default_save_options='/s /ne /nt'
compile endif

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
;compile if EPM
compile if defined(my_MouseStyle)
   MouseStyle = my_MouseStyle
compile else
   MouseStyle = 1
compile endif

compile if SPELL_SUPPORT = 'DYNALINK'  -- For EPM, initialize here if DYNALINK,
 compile if defined(my_ADDENDA_FILENAME)  -- so can be overridden by CONFIG info.
   ADDENDA_FILENAME= my_ADDENDA_FILENAME
 compile else
   ADDENDA_FILENAME= 'c:\lexam\lexam.adl'
 compile endif

 compile if defined(my_DICTIONARY_FILENAME)
   DICTIONARY_FILENAME= my_DICTIONARY_FILENAME
 compile else
   DICTIONARY_FILENAME= 'c:\lexam\us.dct'
 compile endif
compile endif  -- SPELL_SUPPORT

compile if WANT_EPM_SHELL
   shell_index = 0
compile endif

compile if WANT_CUA_MARKING = 'SWITCH'
 compile if defined(my_CUA_marking_switch)
   CUA_marking_switch = my_CUA_marking_switch
  compile if my_CUA_marking_switch
   'togglecontrol 25 1'
  compile endif
 compile else
   CUA_marking_switch = 0           -- Default is off, for standard EPM behavior.
 compile endif
compile elseif WANT_CUA_MARKING = 1
   'togglecontrol 25 1'
compile endif

   bitmap_present = 0

compile if RESPECT_SCROLL_LOCK
   'togglecontrol 26 0'  -- Turn off internal support for cursor keys.
compile endif
;compile endif  -- EPM

------------ Rest of this file isn't normally changed. ------------------------

;compile if EVERSION < '4.12'
;-- Ver. 4.11B:  It's important that the base keyset, edit_keys, be
;-- initialized early in the start-up process, before any modules are linked.
;-- Linked modules can now contain key definitions that overlay the base keyset,
;-- and they need a base to overlay onto.  Don't delete this line!
;   keys edit_keys
;
;-- Set some defaults.  In EOS2 4.12 and later, this is done in a DEFLOAD.
;   'xcom tabs'    DEFAULT_TABS
;   'xcom margins' DEFAULT_MARGINS
;compile endif

;compile if EVERSION >= 5
   vDEFAULT_TABS    = DEFAULT_TABS
   vDEFAULT_MARGINS = DEFAULT_MARGINS
   vDEFAULT_AUTOSAVE= DEFAULT_AUTOSAVE

compile if defined(my_APPNAME)
   appname=my_APPNAME
compile else
   appname=leftstr(getpminfo(EPMINFO_EDITEXSEARCH),3)  -- Get the .ex search path
                                 -- name (this should be a reliable way to get a
                                 -- unique application under which to to store
                                 -- data in os2.ini.  I.e. EPM (EPMPATH) would be
compile endif                    -- 'EPM', LaMail (LAMPATH) would be 'LAM'

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
   do_array 1, EPM_utility_array_ID, "array.EPM"   -- Create this array.
compile if 0  -- LAM: Delete this feature; nobody used it, and it slowed things down.
   one = 1                                          -- (Value is a VAR, so have to kludge it.)
   do_array 2, EPM_utility_array_ID, 'menu.0', one           -- Item 0 says there is one item.
   do_array 2, EPM_utility_array_ID, 'menu.1', defaultmenu   -- Item 1 is the default menu name.
compile endif  -- 0
   zero = 0                                         -- (Value is a VAR, so have to kludge it.)
   do_array 2, EPM_utility_array_ID, 'bmi.0', zero    -- Index of 0 says there are no bookmarks
   do_array 2, EPM_utility_array_ID, 'si.0', zero     -- Set Style Index 0 to "no entries."
;compile endif  -- EVERSION >= 5

;compile if EXTRA_EX
; compile if defined(my_EXTRA_EX_NAME)
;   'linkverify' my_EXTRA_EX_NAME
; compile else
;   'linkverify EXTRA'
; compile endif
;compile endif

;compile if EVERSION >= 5
; compile if EVERSION >= '5.20'
compile if WANT_APPLICATION_INI_FILE
;   compile if EVERSION >= '6.00'
   app_hini=dynalink32(ERES2_DLL, 'ERESQueryHini', gethwndc(EPMINFO_EDITCLIENT) ,2)
;   compile elseif EVERSION >= '5.53'
;   app_hini=dynalink(ERES2_DLL, 'ERESQUERYHINI', gethwnd(EPMINFO_EDITCLIENT) ,2)
;   compile else
;   app_hini=getpminfo(EPMINFO_HINI)
;   compile endif  -- 6.00 / 5.53
   if not app_hini then
      call WinMessageBox('Bogus Ini File Handle', '.ini file handle =' app_hini, 16416)
;;    'postme inifileupdate 1'  -- Don't think this is a problem any more.
   endif
compile endif  -- WANT_APPLICATION_INI_FILE
   CurrentHLPFiles = 'epm.hlp'
; compile endif  -- 5.20
;compile if defined(my_TILDE)
;   tilde = my_TILDE
;compile elseif EVERSION > '5.20'
;   tilde = '~'
;compile else
;   if dos_version() >= 1020 then
;      tilde = ''
;   else
;      tilde = '~'
;   endif
;compile endif
compile if defined(my_FONT)
   font = my_FONT
;  compile if EVERSION < 5.21
;   if not my_FONT then call setfont(0, 0); endif  -- If FALSE then Togglefont
;  compile endif
compile else
   font = TRUE                         -- default font is large
compile endif
compile if RING_OPTIONAL
 compile if defined(my_RING_ENABLED)
    ring_enabled = my_RING_ENABLED
 compile else
    ring_enabled = 1
 compile endif
 compile if WANT_APPLICATION_INI_FILE
  compile if WPS_SUPPORT
   if wpshell_handle then
; Key 18
;     this_ptr = peek32(shared_mem+72, 4); -- if this_ptr = \0\0\0\0 then return; endif
;     parse value peekz(this_ptr) with ? ring_enabled ?
;compile if 0  -- LAM/JP
;      ring_enabled = substr(peekz(peek32(wpshell_handle+64, 4)), 8, 1)
;compile else
      ring_enabled = 1
;compile endif
   else
  compile endif
      newcmd=queryprofile( app_hini, appname, INI_RINGENABLED)
      if newcmd<>'' then ring_enabled = newcmd; endif
  compile if WPS_SUPPORT
   endif  -- wpshell_handle
  compile endif
 compile endif  -- WANT_APPLICATION_INI_FILE
   if not ring_enabled then
;  compile if EVERSION < '5.53'
;      'togglecontrol 20 0'
;  compile else
      'toggleframe 4 0'
;  compile endif
   endif
compile endif  -- RING_OPTIONAL
;compile if not DELAY_MENU_CREATION
   include 'menuacel.e'
;compile endif
compile if WANT_DYNAMIC_PROMPTS
 compile if defined(my_MENU_PROMPT)
   menu_prompt = my_MENU_PROMPT
 compile else
;  menu_prompt = 0       -- Default is to not have it (at least, internally).
   menu_prompt = 1       -- (Start with it on for now, to get it beta tested.)
 compile endif
compile endif  -- DYNAMIC_PROMPTS
;compile endif  -- EVERSION >= 5

   last_append_file = ''   -- Initialize for DEFC APPEND.

;compile if not EPM
;
; compile if E3
;   'xcom e /n /h coms.e'
;   getfileid comsfileid    -- initialize comsfileid for other macros
;
;-- Make sure the top ring is active.  This E command (any old file
;-- would do) activates the top ring.
;   'xcom e /n coms.e'; 'xcom q'
;; compile else
;; 4.12:  We no longer need to load the COMS.E file here, it's done
;; automatically.  And no need to query comsfileid, it's always 0.
;; And no need to activate the top ring after loading COMS.E.  Now it's simply:
;   comsfileid=0
;; compile endif  -- E3
;
;-- Ver 3.11:  move color initializations to init_window() in WINDOW.E.
;-- Much of it was repeated there anyway.
;;call start_screen()
;
;compile else       -- EPM

; Initialize the colors and paint the window.  (Done in WINDOW.E for non-EPM versions.)
   .textcolor  = TEXTCOLOR
   .markcolor  = MARKCOLOR

;compile if EVERSION < '5.21'
;   .statuscolor  = STATUSCOLOR
;   .messagecolor = MESSAGECOLOR

;compile else
   vSTATUSCOLOR  = STATUSCOLOR
   vMESSAGECOLOR = MESSAGECOLOR
; compile if EVERSION >= '5.60'
   vDESKTOPCOLOR = DESKTOPCOLOR
; compile endif
compile if defined(STATUS_TEMPLATE)
;  compile if 0 -- EVERSION >= 6
;   'postme setstatusline' STATUS_TEMPLATE
;  compile else
   'setstatusline' STATUS_TEMPLATE
;  compile endif
compile elseif STATUSCOLOR <> 240  -- If different than the default...
   'setstatusline'    -- Just set the color
compile endif

compile if MESSAGECOLOR <> 252  -- If different than the default...
   'setmessageline'   -- Set the messageline color
compile endif
;compile endif  -- 5.21

compile if ENHANCED_ENTER_KEYS
 compile if ENTER_ACTION='' | ENTER_ACTION='ADDLINE'  -- The default
   enterkey=1; a_enterkey=1; s_enterkey=1; padenterkey=1; a_padenterkey=1; s_padenterkey=1
 compile elseif ENTER_ACTION='NEXTLINE'
   enterkey=2; a_enterkey=2; s_enterkey=2; padenterkey=2; a_padenterkey=2; s_padenterkey=2
 compile elseif ENTER_ACTION='ADDATEND'
   enterkey=3; a_enterkey=3; s_enterkey=3; padenterkey=3; a_padenterkey=3; s_padenterkey=3
 compile elseif ENTER_ACTION='DEPENDS'
   enterkey=4; a_enterkey=4; s_enterkey=4; padenterkey=4; a_padenterkey=4; s_padenterkey=4
 compile elseif ENTER_ACTION='DEPENDS+'
   enterkey=5; a_enterkey=5; s_enterkey=5; padenterkey=5; a_padenterkey=5; s_padenterkey=5
 compile elseif ENTER_ACTION='STREAM'
   enterkey=6; a_enterkey=6; s_enterkey=6; padenterkey=6; a_padenterkey=6; s_padenterkey=6
 compile endif
 compile if C_ENTER_ACTION='ADDLINE'
   c_enterkey=1; c_padenterkey=1;
 compile elseif C_ENTER_ACTION='' | C_ENTER_ACTION='NEXTLINE'  -- The default
   c_enterkey=2; c_padenterkey=2;
 compile elseif C_ENTER_ACTION='ADDATEND'
   c_enterkey=3; c_padenterkey=3;
 compile elseif C_ENTER_ACTION='DEPENDS'
   c_enterkey=4; c_padenterkey=4;
 compile elseif C_ENTER_ACTION='DEPENDS+'
   c_enterkey=5; c_padenterkey=5;
 compile elseif C_ENTER_ACTION='STREAM'
   c_enterkey=6; c_padenterkey=6;
 compile endif
compile endif -- ENHANCED_ENTER_KEYS

compile if WANT_STREAM_MODE = 'SWITCH'
 compile if defined(my_STREAM_MODE)
   stream_mode = my_STREAM_MODE
  compile if my_STREAM_MODE
   'togglecontrol 24 1'
  compile endif
 compile elseif ENTER_ACTION='STREAM'
   stream_mode = 1
   'togglecontrol 24 1'
 compile else
   stream_mode = 0
 compile endif
compile elseif WANT_STREAM_MODE = 1
   'togglecontrol 24 1'
compile endif

;compile if EVERSION >= '5.50'
  -- default editor font
  -- .font=registerfont('Courier', 12, 0)
compile if WANT_SYS_MONOSPACED
   default_font = registerfont('System Monospaced', SYS_MONOSPACED_SIZE, 0)
compile else
   default_font = 1
compile endif

compile if DYNAMIC_CURSOR_STYLE
 compile if defined(my_CURSORDIMENSIONS)
   cursordimensions = my_CURSORDIMENSIONS
 compile elseif UNDERLINE_CURSOR
   cursordimensions = '-128.3 -128.-64'
 compile else
   cursordimensions = '-128.-128 2.-128'
 compile endif
compile endif

   call fixup_cursor()
;compile endif

; repaint_window()
;compile endif  -- not EPM


; -------- Link separately compiled macros if consts = 'LINK' --------
; If the String Area Size gets too large (limited to 64 KB),
; it could be useful to link some packages instead to include them in
; EPM.E. To see the String Area Size in ETPM's log file, ETPM must be
; called with /v.

;compile if LINK_HOST_SUPPORT
; compile if HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
;   'linkverify E3EMUL'
; compile elseif HOST_SUPPORT = 'SRPI'
;   'linkverify SLSRPI'
; compile else
;   *** Error - LINK_HOST_SUPPORT not supported for your HOST_SUPPORT method.
; compile endif
;compile endif

;compile if MOUSE_SUPPORT = 'LINK'
;   'linkverify MOUSE'  -- doesn't work
;compile endif

compile if WANT_BOOKMARKS = 'LINK'
   'linkverify BOOKMARK'
compile endif       -- Bookmarks

compile if WANT_TAGS = 'LINK' /* & not EXTRA_EX */
   'linkverify TAGS'
   'linkverify MAKETAGS'
compile endif       -- TAGs

compile if WANT_EBOOKIE = 'LINK'
   'linkverify BKEYS'
compile endif

compile if WANT_TREE = 'LINK'
   'linkverify TREE'
compile endif

compile if SPELL_SUPPORT = 'LINK'
; compile if EPM
   'linkverify EPMLEX'
; compile elseif EOS2
;  'linkverify EOS2LEX'
; compile else
;   *** Error - SPELL_SUPPORT = 'LINK' not valid for E3.
; compile endif
compile endif

compile if LINK_NEPMDLIB = 'DEFINIT'
   if not isadefproc('NepmdOpenConfig') then
; --- Link the NEPMD library. Open a MessageBox if .ex file not found. ------
      'linkverify nepmdlib.ex'
   endif
compile endif

-----------------  End of DEFINIT  ------------------------------------------

; -------- Define commands here for the dynalink/defmain feature --------
; That avoids a link or even an include.

compile if SPELL_SUPPORT = 'DYNALINK'
define
; compile if EPM
   LEX_EX = 'EPMLEX'
; compile elseif EOS2
;   LEX_EX = 'EOS2LEX'
; compile else
;   *** Error - SPELL_SUPPORT = 'DYNALINK' not valid for E3.
; compile endif

defc syn = link_exec(LEX_EX, 'SYN', arg(1))

defc proof = link_exec(LEX_EX, 'PROOF', arg(1))

defc proofword, verify = link_exec(LEX_EX, 'VERIFY', arg(1))

; compile if EPM
defc dict = link_exec(LEX_EX, 'DICT', arg(1))
defc dynaspell = link_exec(LEX_EX, 'DYNASPELL', arg(1))
; compile endif
compile endif       -- Spell_Support

compile if WANT_EBOOKIE = 'DYNALINK'
defc bookie = link_exec('bkeys', 'bookie', arg(1))
compile endif

compile if WANT_TREE = 'DYNALINK'
defc tree_dir = link_exec('tree', 'tree_dir', arg(1))
defc treesort = link_exec('tree', 'treesort', arg(1))
compile endif

compile if WANT_TAGS = 'DYNALINK'
defc findtag  = link_exec('tags', 'findtag',  arg(1))
defc tagsfile = link_exec('tags', 'tagsfile', arg(1))
defc tagscan  = link_exec('tags', 'tagscan',  arg(1))
defc poptagsdlg  = link_exec('tags', 'poptagsdlg',  arg(1))
defc maketags  = link_exec('maketags', 'maketags',  arg(1))
compile endif       -- TAGs

-- 4.10A:  Move the compile-if here from above, simpler.
;compile if EVERSION >= '4.0' & EVERSION < 5
; compile if ASK_BEFORE_LEAVING
;  include 'exit.e'
; compile endif
;compile endif

;compile if 0 -- EPM & WANT_APPLICATION_INI_FILE
;defc inifileupdate
;   universal app_hini
;   parse arg iteration .
; compile if EVERSION >= '6.00'
;   app_hini=dynalink32(ERES2_DLL, 'ERESQueryHini', gethwndc(EPMINFO_EDITCLIENT) ,2)
; compile elseif EVERSION >= '5.53'
;   app_hini=dynalink(ERES2_DLL, 'ERESQUERYHINI', gethwnd(EPMINFO_EDITCLIENT) ,2)
; compile else
;   app_hini=getpminfo(EPMINFO_HINI)
; compile endif  -- 6.00 / 5.53
;   if app_hini then
;      if iteration=1 then s=''; else s='s'; endif
;      sayerror 'ini file handle received as' app_hini 'after' iteration 'attempt's
;   elseif iteration>10 then
;      call WinMessageBox('Bogus Ini File Handle', 'Giving up after' iteration 'attempts.', 16416)
;   else
;      'postme inifileupdate' (iteration+1)
;   endif
;compile endif  -- WANT_APPLICATION_INI_FILE

