/****************************** Module Header *******************************
*
* Module Name: keys.e
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

; Definitions for the 'edit_keys' keyset. Turned all key defs into defcs
; to make keys configurable.

compile if not defined(SMALL)  -- If being externally compiled...
   define INCLUDING_FILE = 'KEYS.E'

   include 'stdconst.e'

const
   tryinclude 'MYCNF.E'
 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'

   EA_comment 'This defines definitions for keysets.'

; In case someone executes 'keys' by mistake, the module would be unlinked.
; So link it again:
defmain
   sayerror 'Executing defmain of' INCLUDING_FILE
   'postme link keys'
   -- The STOP statement won't avoid unlinking here

compile endif  -- not defined(SMALL)

const
-- Normally, when you shift a mark left or right, text to the right of the
-- marked area moves with it.  Bob Langer supplied code that lets us shift
-- only what's inside the mark.  The default is the old behavior.
compile if not defined(SHIFT_BLOCK_ONLY)
   SHIFT_BLOCK_ONLY = 0
compile endif
;-- Respect the Scroll lock key?  If set to 1, Shift+F1 - Shift+F4 must not be
;-- redefined.  (The cursor keys execute those keys directly, in order to
;-- avoid duplicating code.)  Note that setting this flag turns off the internal
;-- cursor key handling, so if WANT_CUA_MARKING = 'SWITCH',
;-- WANT_STREAM_EDITING = 'SWITCH', and RESPECT_SCROLL_LOCK = 1, cursor movement
;-- might be unacceptably slow.
compile if not defined(RESPECT_SCROLL_LOCK)
   RESPECT_SCROLL_LOCK = 1
compile endif
-- Ver.3.09:  Set this to 1 if you want the FILE key to quit rather than
-- save the file if the file was not modified.  Has the side effect that
-- the Name command sets .modify to 1.
compile if not defined(SMARTFILE)
   SMARTFILE = 1
compile endif
-- For Toolkit developers - set to 0 if you don't want the user to be able
-- to go to line 0.  Affects MH_gotoposition in MOUSE.E and Def Up in STDKEYS.E.
-- Must be set to 1 in order to enable a copy line action to the top. (Copy line
-- copies a line after the current line.)
compile if not defined(TOP_OF_FILE_VALID)
   -- Can be '0', '1', or 'STREAM' (dependant on STREAM_MODE)
   TOP_OF_FILE_VALID = 1
compile endif
-- Determines if DBCS support should be included in the macros.  Note
-- that EPM includes internal DBCS support; other versions of E do not.
compile if not defined(WANT_DBCS_SUPPORT)
   WANT_DBCS_SUPPORT = 1
compile endif
-- Allow pressing tab in insert mode to insert spaces to next tab stop in
-- line mode as well as in stream mode.
compile if not defined(WANT_TAB_INSERTION_TO_SPACE)
   -- for line mode only
   WANT_TAB_INSERTION_TO_SPACE = 0
compile endif

; ---------------------------------------------------------------------------
definit
   universal blockreflowflag

   blockreflowflag = 0
compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   call AddAVar( 'usedmenuaccelerators', 'A')
compile endif
compile if defined(TEX_BAR__MSG)  -- For TFE or EPMTeX support
   call AddAVar( 'usedmenuaccelerators', 'T')
compile endif
compile if defined(ECO_MENU__MSG)  -- For ECO support
   call AddAVar( 'usedmenuaccelerators', 'I')
compile endif

; ---------------------------------------------------------------------------
; Apparently edit_keys must be defined in EPM.E
;
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

/***
; This defines the standard keyset. It's important to use the option 'clear'.
; Otherwise otherkeys won't process the standard letters, numbers and chars.
defkeys edit_keys new clear

def '„'
;   dprintf( 'lastkey() = 'lastkey()', ch = 'ch)
   call SaveKeyCmd( lastkey())
   keyin 'ae'

; These standard key defs are executed by the accel def for these keys to
; to ensure that the execeution won't apply for numpad keys.
; (Because accel keys don't create a WM_CHAR message, they can't be handled
; by lastkey or getkeystate. Executing them as standard keys allows for
; checking e.g. the scancode.)
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

def otherkeys
   'otherkeys'
***/

; ---------------------------------------------------------------------------
; Executes only executekey lastkey() and debugging. Can be used by every
; newly defined keyset.
; This should process all standard letters (lowercase and uppercase), numbers
; and chars with the length = 1. All combinations with Ctrl, Alt, Shift are
; handled by accelerator key definitions to allow for more definable
; combinations and to ease the definition of undo and key recording.
defc otherkeys
   k = lastkey()
   if length( k) = 1 then
      call SaveKeyCmd( k)
   endif
   executekey k

; ---------------------------------------------------------------------------
; Standard key defs don't work for numpad keys, only for keypad keys.
; Therefore numpad keys don't have to be filtered out here.
; Numpad keys can be redefined via accel keys, but then entering chars by
; entering its keycode via Alt+numpad keys won't work anymore.
defc ExecKeyCmd
   -- The array var is internally set by the DefKey proc if Alt+num keys
   -- were defined via DefKey.
   call SaveKeyCmd( arg(1))
   Cmd = GetAVar( 'keydef.'arg(1))
   if Cmd <> '' then
      Cmd
   endif

; ---------------------------------------------------------------------------
; An accelerator key issues a WM_COMMAND message, that is processed by the
; ProcessCommand command defined in menu.e.
; Some other defs where accelerator keys are filtered are:
; def otherkeys, defproc process_key, defc ProcessOtherKeys
; queryaccelstring returns the command connected with the specified menu item
; or accelerator key def.

; ---------------------------------------------------------------------------
; Add or redefine an entry to the active named accelerator key table.
;
; Syntax:  DefKey( KeyString, Cmd[, 'L'])
;
;          KeyString prefixes are separated by '_', '+' or '-'. The following
;          prefixes are defined:
;          'c_' Ctrl
;          's_' Shift
;          'a_' Alt
;          In this definition the order of the prefixes doesn't matter, while
;          on execution, the KeyString prefixes are used in the above order.
;          Cmd must be an E command string, not E code.
;          'L' is the option for defining the key as a lonekey
;              (a lonekey is executed once on releasing the key)
;
; Examples:
;          DefKey( 'c_s_Q', 'sayerror Ctrl+Shift+Q pressed')
;          DefKey( 'c+s+q', 'sayerror Ctrl+Shift+Q pressed')  (equivalent)
;          DefKey( 'C-S-q', 'sayerror Ctrl+Shift+Q pressed')  (equivalent)
;          DefKey( 'altgraf', 'sayerror AltGraf key pressed', 'L')
;          For defining non-ASCII keys that don't match the upcase or lowcase
;          procedure processing, the key has to be defined in the correct
;          case:
;          DefKey( '„', 'sayerror Lowercase „ (a-umlaut) pressed')
;          DefKey( 's_Ž', 'sayerror Uppercase „ (a-umlaut) pressed')
;
; For standard accel table defs, the first def wins. This command changes it,
; so that an accel table can be extended as expected: An already existing
; accel table entry is overridden by a new one. That makes the last def win
; and avoids multiple defs for a key.
;
defproc DefKey( KeyString, Cmd)
   universal activeaccel
   universal lastkeyaccelid
   universal cua_menu_accel
   Flags = 0

   -- Parse lonekey option
   fPadKey = 0
   Options = upcase( arg(3))
   if Options <> '' then
      if pos( Options, 'L') > 0 then
         Flags = Flags + AF_LONEKEY
      endif
   endif

   String = upcase( KeyString)
   call GetAFFlags( Flags, String, KeyString)  -- removes modifier prefixes from String

   -- Handle deactivated 'block Alt+letter keys from jumping to menu bar'
   -- Note: These keys and F10 can't be recorded, they are handled by PM.
   --       There exists no ETK procs to activate the menu.
   if length( String) = 1 then
      if cua_menu_accel then
         if Flags = AF_ALT & wordpos( String, upcase( GetAVar('usedmenuaccelerators'))) then
            return
         endif
      endif
   endif

   -- Remove previous key def in array vars, if any
   PrevCmd = GetAVar('keydef.'KeyString)
   DelAVar( 'keycmd.'PrevCmd, KeyString)

   -- Save key def in array to allow for searching for KeyString and Cmd
   SetAVar( 'keydef.'KeyString, Cmd)
   AddAVar( 'keycmd.'Cmd, KeyString)  -- may have multiple key defs

   if length( String) = 1 then

      -- Ignore Alt+numpad number keys as accel keys here. Just save key in
      -- array to query it by ExecKeyCmd.
      -- That makes the Alt+numpad number keys work for entering a char by its
      -- key code.
      if (pos( String, '1234567890') > 0) and (Flags = AF_ALT or Flags = AF_ALT+AF_LONEKEY) then
         return
      endif

      Flags = Flags + AF_CHAR
      if Flags bitand AF_SHIFT then
         Key = asc( upcase( String))
      else
         Key = asc( lowcase( String))
      endif

   else
      VK = GetVKConst( String)
      if VK > 0 then
         Key = VK
         Flags = Flags + AF_VIRTUALKEY
      else
         sayerror 'Error: Unknown key string 'KeyString' specified.'
         --dprintf( 'KeyString = 'KeyString', Cmd = 'Cmd', Flags = 'Flags', Key = 'Key', last id = 'lastkeyaccelid)
         return
      endif
   endif

   AccelId = GetAVar( 'keyid.'KeyString)
   if AccelId = '' then
      lastkeyaccelid = lastkeyaccelid + 1
      if lastkeyaccelid = 8101 then  -- 8101 is hardcoded as 'configdlg SYS'
         lastkeyaccelid = lastkeyaccelid + 1
      endif
      AccelId = lastkeyaccelid
   endif
   buildacceltable activeaccel, KeyString''\1''Cmd, Flags, Key, AccelId

   -- Save key def in array to allow for searching for KeyString and Cmd
   SetAVar( 'keyid.'KeyString, AccelId)

   --if KeyString = 'alt' then
   --   dprintf( 'KeyString = 'KeyString', Cmd = 'Cmd', Flags = 'Flags', Key = 'Key', id = 'lastkeyaccelid)
   --endif
   --if KeyString = 'c_s' then
   --   dprintf( 'KeyString = 'KeyString', Cmd = 'Cmd', Flags = 'Flags', Key = 'Key', this id = 'AccelId', last id = 'lastkeyaccelid)
   --endif

/*
   -- For non-letter chars: define also the shifted variant automatically
   -- to make the defs more keyboard-independible.
   if Flags bitand AF_CHAR and not Flags bitand AF_SHIFT then
      if upcase( Key) = lowcase( Key) then
         Flags = Flags + AF_SHIFT
         lastkeyaccelid = lastkeyaccelid + 1
         buildacceltable activeaccel, KeyString''\1''Cmd, Flags, Key, lastkeyaccelid
      endif
   endif
*/

   return

; Define a cmd to call the proc in profile.erx or for testing
defc DefKey
   parse arg KeyString Cmd
   if upcase( lastword( Cmd)) = 'L' then
      Options = 'L'
      Cmd = subword( Cmd, 1, words( Cmd) - 1)
   else
      Options = ''
   endif
   call DefKey( KeyString, Cmd, Options)

; ---------------------------------------------------------------------------
; Syntax:  UnDefKey( KeyString)
defproc UnDefKey( KeyString)
   universal activeaccel

   AccelId = GetAVar( 'keyid.'KeyString)
   if AccelId <> '' then
      -- Define Ctrl+Alt (= nothing) for this id
      -- Don't change the array var to allow for redining this id again
      buildacceltable activeaccel, '', AF_CONTROL+AF_VIRTUALKEY, VK_ALT, AccelId
   else
      -- No error message if key was not defined before
   endif

   return

; Define a cmd to call the proc in profile.erx or for testing
defc UnDefKey
   parse arg KeyString
   call UnDefKey( KeyString)

; ---------------------------------------------------------------------------
defproc GetAFFlags( var Flags, var String, var KeyString)
   -- Get prefix
   fC_Prefix = 0
   fA_Prefix = 0
   fS_Prefix = 0
   fdone = 0
   do while (fdone = 0 & length( String) > 2)
      p = pos( leftstr( String, 1), 'CAS')
      if p & pos( substr( String, 2, 1), '_-+') then
         String = substr( String, 3)
         if p = 1 then
            fC_Prefix = 1
         elseif p = 2 then
            fA_Prefix = 1
         elseif p = 3 then
            fS_Prefix = 1
         endif
      else
         fdone = 1
      endif
   enddo
   KeyString = ''
   if fC_Prefix = 1 then
      Flags = Flags + AF_CONTROL
      KeyString = KeyString'c_'
   endif
   if fA_Prefix = 1 then
      Flags = Flags + AF_ALT
      KeyString = KeyString'a_'
   endif
   if fS_Prefix = 1 then
      Flags = Flags + AF_SHIFT
      KeyString = KeyString's_'
   endif
   if length( String) > 1 then
      KeyString = KeyString''GetVKName( String)
   elseif length( String) > 0 then
      KeyString = KeyString''lowcase( String)
   endif

; ---------------------------------------------------------------------------
defproc GetVKConst( String)
   VK = 0
   String = upcase( String)
   if     String = 'BREAK'     then VK = VK_BREAK
   elseif String = 'BACKSPACE' then VK = VK_BACKSPACE
   elseif String = 'BKSPC'     then VK = VK_BACKSPACE
   elseif String = 'TAB'       then VK = VK_TAB
   elseif String = 'BACKTAB'   then VK = VK_BACKTAB
   elseif String = 'NEWLINE'   then VK = VK_NEWLINE  -- This is the regular Enter key
   elseif String = 'SHIFT'     then VK = VK_SHIFT
   elseif String = 'CTRL'      then VK = VK_CTRL
   elseif String = 'ALT'       then VK = VK_ALT
   elseif String = 'ALTGRAF'   then VK = VK_ALTGRAF
   elseif String = 'ALTGR'     then VK = VK_ALTGRAF
   elseif String = 'PAUSE'     then VK = VK_PAUSE
   elseif String = 'CAPSLOCK'  then VK = VK_CAPSLOCK
   elseif String = 'ESC'       then VK = VK_ESC
   elseif String = 'SPACE'     then VK = VK_SPACE
   elseif String = 'PAGEUP'    then VK = VK_PAGEUP
   elseif String = 'PGUP'      then VK = VK_PAGEUP
   elseif String = 'PAGEDOWN'  then VK = VK_PAGEDOWN
   elseif String = 'PGDOWN'    then VK = VK_PAGEDOWN
   elseif String = 'PGDN'      then VK = VK_PAGEDOWN
   elseif String = 'END'       then VK = VK_END
   elseif String = 'HOME'      then VK = VK_HOME
   elseif String = 'LEFT'      then VK = VK_LEFT
   elseif String = 'UP'        then VK = VK_UP
   elseif String = 'RIGHT'     then VK = VK_RIGHT
   elseif String = 'DOWN'      then VK = VK_DOWN
   elseif String = 'DN'        then VK = VK_DOWN
   elseif String = 'PRINTSCRN' then VK = VK_PRINTSCRN
   elseif String = 'INSERT'    then VK = VK_INSERT
   elseif String = 'INS'       then VK = VK_INSERT
   elseif String = 'DELETE'    then VK = VK_DELETE
   elseif String = 'DEL'       then VK = VK_DELETE
   elseif String = 'SCRLLOCK'  then VK = VK_SCRLLOCK
   elseif String = 'NUMLOCK'   then VK = VK_NUMLOCK
   elseif String = 'ENTER'     then VK = VK_ENTER  -- This is the numeric keypad Enter key
   elseif String = 'PADENTER'  then VK = VK_ENTER  -- This is the numeric keypad Enter key
   elseif String = 'SYSRQ'     then VK = VK_SYSRQ
   elseif String = 'F1'        then VK = VK_F1
   elseif String = 'F2'        then VK = VK_F2
   elseif String = 'F3'        then VK = VK_F3
   elseif String = 'F4'        then VK = VK_F4
   elseif String = 'F5'        then VK = VK_F5
   elseif String = 'F6'        then VK = VK_F6
   elseif String = 'F7'        then VK = VK_F7
   elseif String = 'F8'        then VK = VK_F8
   elseif String = 'F9'        then VK = VK_F9
   elseif String = 'F10'       then VK = VK_F10
   elseif String = 'F11'       then VK = VK_F11
   elseif String = 'F12'       then VK = VK_F12
   endif
   return VK

; ---------------------------------------------------------------------------
defproc GetVKName( String)
   VK = ''
   String = upcase( String)
   if     String = 'BREAK'     then VK = 'break'
   elseif String = 'BACKSPACE' then VK = 'backspace'
   elseif String = 'BKSPC'     then VK = 'backspace'
   elseif String = 'TAB'       then VK = 'tab'
   elseif String = 'BACKTAB'   then VK = 'backtab'
   elseif String = 'NEWLINE'   then VK = 'newline'  -- This is the regular Enter key
   elseif String = 'SHIFT'     then VK = 'shift'
   elseif String = 'CTRL'      then VK = 'ctrl'
   elseif String = 'ALT'       then VK = 'alt'
   elseif String = 'ALTGRAF'   then VK = 'altgraf'
   elseif String = 'ALTGR'     then VK = 'altgraf'
   elseif String = 'PAUSE'     then VK = 'pause'
   elseif String = 'CAPSLOCK'  then VK = 'capslock'
   elseif String = 'ESC'       then VK = 'esc'
   elseif String = 'SPACE'     then VK = 'space'
   elseif String = 'PAGEUP'    then VK = 'pageup'
   elseif String = 'PGUP'      then VK = 'pageup'
   elseif String = 'PAGEDOWN'  then VK = 'pagedown'
   elseif String = 'PGDOWN'    then VK = 'pagedown'
   elseif String = 'PGDN'      then VK = 'pagedown'
   elseif String = 'END'       then VK = 'end'
   elseif String = 'HOME'      then VK = 'home'
   elseif String = 'LEFT'      then VK = 'left'
   elseif String = 'UP'        then VK = 'up'
   elseif String = 'RIGHT'     then VK = 'right'
   elseif String = 'DOWN'      then VK = 'down'
   elseif String = 'DN'        then VK = 'down'
   elseif String = 'PRINTSCRN' then VK = 'printscrn'
   elseif String = 'INSERT'    then VK = 'insert'
   elseif String = 'INS'       then VK = 'insert'
   elseif String = 'DELETE'    then VK = 'delete'
   elseif String = 'DEL'       then VK = 'delete'
   elseif String = 'SCRLLOCK'  then VK = 'scrllock'
   elseif String = 'NUMLOCK'   then VK = 'numlock'
   elseif String = 'ENTER'     then VK = 'enter'  -- This is the numeric keypad Enter key
   elseif String = 'PADENTER'  then VK = 'enter'  -- This is the numeric keypad Enter key
   elseif String = 'SYSRQ'     then VK = 'sysrq'
   elseif String = 'F1'        then VK = 'f1'
   elseif String = 'F2'        then VK = 'f2'
   elseif String = 'F3'        then VK = 'f3'
   elseif String = 'F4'        then VK = 'f4'
   elseif String = 'F5'        then VK = 'f5'
   elseif String = 'F6'        then VK = 'f6'
   elseif String = 'F7'        then VK = 'f7'
   elseif String = 'F8'        then VK = 'f8'
   elseif String = 'F9'        then VK = 'f9'
   elseif String = 'F10'       then VK = 'f10'
   elseif String = 'F11'       then VK = 'f11'
   elseif String = 'F12'       then VK = 'f12'
   endif
   return VK

; ---------------------------------------------------------------------------
defproc GetVKMenuName( String)
   VK = ''
   String = upcase( String)
   if     String = 'BREAK'     then VK = 'Brk'
   elseif String = 'BACKSPACE' then VK = BACKSPACE_KEY__MSG
   elseif String = 'BKSPC'     then VK = BACKSPACE_KEY__MSG
   elseif String = 'TAB'       then VK = 'Tab'
   elseif String = 'BACKTAB'   then VK = 'BackTab'
   elseif String = 'NEWLINE'   then VK = ENTER_KEY__MSG  -- This is the regular Enter key
   elseif String = 'SHIFT'     then VK = SHIFT_KEY__MSG
   elseif String = 'CTRL'      then VK = CTRL_KEY__MSG
   elseif String = 'ALT'       then VK = ALT_KEY__MSG
   elseif String = 'ALTGRAF'   then VK = 'AltGraf'
   elseif String = 'ALTGR'     then VK = 'AltGraf'
   elseif String = 'PAUSE'     then VK = 'Pause'
   elseif String = 'CAPSLOCK'  then VK = 'Capslock'
   elseif String = 'ESC'       then VK = ESCAPE_KEY__MSG
   elseif String = 'SPACE'     then VK = 'Space'
   elseif String = 'PAGEUP'    then VK = 'PgUp'
   elseif String = 'PGUP'      then VK = 'PgUp'
   elseif String = 'PAGEDOWN'  then VK = 'PgDown'
   elseif String = 'PGDOWN'    then VK = 'PgDown'
   elseif String = 'PGDN'      then VK = 'PgDown'
   elseif String = 'END'       then VK = 'End'
   elseif String = 'HOME'      then VK = 'Home'
   elseif String = 'LEFT'      then VK = 'Left'
   elseif String = 'UP'        then VK = UP_KEY__MSG
   elseif String = 'RIGHT'     then VK = 'Right'
   elseif String = 'DOWN'      then VK = DOWN_KEY__MSG
   elseif String = 'DN'        then VK = DOWN_KEY__MSG
   elseif String = 'PRINTSCRN' then VK = 'PrtScrn'
   elseif String = 'INSERT'    then VK = INSERT_KEY__MSG
   elseif String = 'INS'       then VK = INSERT_KEY__MSG
   elseif String = 'DELETE'    then VK = DELETE_KEY__MSG
   elseif String = 'DEL'       then VK = DELETE_KEY__MSG
   elseif String = 'SCRLLOCK'  then VK = 'ScrlLock'
   elseif String = 'NUMLOCK'   then VK = 'NumLock'
   elseif String = 'ENTER'     then VK = PADENTER_KEY__MSG  -- This is the numeric keypad Enter key
   elseif String = 'PADENTER'  then VK = PADENTER_KEY__MSG  -- This is the numeric keypad Enter key
   elseif String = 'SYSRQ'     then VK = 'SysRq'
   elseif String = 'F1'        then VK = 'F1'
   elseif String = 'F2'        then VK = 'F2'
   elseif String = 'F3'        then VK = 'F3'
   elseif String = 'F4'        then VK = 'F4'
   elseif String = 'F5'        then VK = 'F5'
   elseif String = 'F6'        then VK = 'F6'
   elseif String = 'F7'        then VK = 'F7'
   elseif String = 'F8'        then VK = 'F8'
   elseif String = 'F9'        then VK = 'F9'
   elseif String = 'F10'       then VK = 'F10'
   elseif String = 'F11'       then VK = 'F11'
   elseif String = 'F12'       then VK = 'F12'
   endif
   return VK

; ---------------------------------------------------------------------------
; Get key def as appendix for a menu item text, with a prepended tab char,
; if any text
defproc MenuAccelString
   Cmd = arg(1)
   AccelString = ''
   -- Todo: allow for specifying consecutive Cmds: Cmd1,Cmd2 or Cmd1, Cmd2
   if Cmd <> '' then
      -- Query array var, defined by DefKey
      KeyString = strip( GetAVar( 'keycmd.'Cmd))
      if KeyString <> '' then
         -- A Cmd may have multiple key defs, each appended by a space
         do w = 1 to words( KeyString)
            Rest = word( KeyString, w)
            ThisString = ''
            if pos( 'c_', Rest) = 1 then
               ThisString = ThisString''CTRL_KEY__MSG'+'
               Rest = substr( Rest, 3)
            endif
            if pos( 'a_', Rest) = 1 then
               ThisString = ThisString''ALT_KEY__MSG'+'
               Rest = substr( Rest, 3)
            endif
            if pos( 's_', Rest) = 1 then
               ThisString = ThisString''SHIFT_KEY__MSG'+'
               Rest = substr( Rest, 3)
            endif
            if Rest <> '' then
               VKString = GetVKMenuName( Rest)
               if VKString <> '' then
                  ThisString = ThisString''VKString
               else
                  ThisString = ThisString''upcase( Rest)
               endif
            endif
            if AccelString <> '' then
               AccelString = AccelString' | 'ThisString
            else
               AccelString = ThisString
            endif
         enddo
      endif
   endif
   if AccelString <> '' then
      AccelString = \9''AccelString
   endif
   return AccelString

; For testing:
defc MenuAccelString
   Cmd = strip( arg(1))
   sayerror 'Menu item text appendix for "'Cmd'" is: |'MenuAccelString( Cmd)'|'

; ---------------------------------------------------------------------------
; Called by ProcessCommand in MENU.E
defproc ExecAccelKey
   parse value( arg(1)) with KeyString \1 Cmd
   call SaveKeyCmd( arg(1))
   Cmd
   return

; ---------------------------------------------------------------------------
; Undo states were saved only here, on execution of a command, just before
; text is altered by it. Repeated commands are ignored. Commands that don't
; call NextCmdAltersText() won't create an undo state. That leads to
; following behavior: Every word creates a new undo state. Leading spaces or
; leading empty lines were added to the undo state of the following word.
defproc NextCmdAltersText
   universal curkey
   universal prevkey
   parse value curkey with KeyString \1 Cmd
   --dprintf( 'KeyString = 'KeyString)

   -- Omit new undo record for repeated keys or repeated commands
   if curkey = prevkey then
      -- nop

/*
   -- Omit new undo record for an unmodified file
   -- (This is not useful if, after a redo, a state is reached where
   -- .modify is 0.)
   elseif not .modify then
      -- nop
*/

/*
   -- Activate this if space should not create a new undo state
   elseif (KeyString = 'space' |
           rightstr( KeyString, 6) = '_space') then
      -- nop
*/

/*
   -- The following option is experimental and most likely leads to too
   -- few recorded states, e.g. when formatting or clipboard macros were
   -- used:
   -- Activate this if only return or enter should create a new undo state
   elseif not (rightstr( KeyString, 7) = 'newline' |
               rightstr( KeyString, 5) = 'enter') then
      -- nop
*/

   -- Create a new undo record, if the current state is not already checkpointed
   else
      call NewUndoRec()
   endif

   return

; ---------------------------------------------------------------------------
; SaveKeyCmd is called by OtherKeys, ExecKeyCmd, ProcessCommand and
; ExecAccelKey. It is used for ETK keys and for executing commands of accel
; keys and menu items. It sets prevkey and curkey. In recording state, it
; appends curkey to the recordkeys array var.
defproc SaveKeyCmd
   universal curkey
   universal prevkey

   if arg(1) = '' then
      return
   endif

   prevkey = curkey
   curkey = arg(1)
   --dprintf( 'curkey = 'curkey)

   call AddRecordKeys()

   return

; ---------------------------------------------------------------------------
; Keyset array vars:
;
;    'keysets'            list of defined keysets
;    'keyset.'name        list of used keyset cmds for keyset name
;    'keysetcmd.'cmdname  list of keysets that use cmdname
;                         (this var allows for changing keysets for all
;                         loaded files, not just for newly loaded files)
;
; Examples with cuakeys active:           Examples without cuakeys active:
;    'keysets'         = 'std shell'         'keysets'         = 'std shell'
;    'keyset.std'      = 'std cua'           'keyset.std'      = 'std'
;    'keysetcmd.std'   = 'std shell'         'keysetcmd.std'   = 'std shell'
;    'keyset.shell'    = 'std cua shell'     'keyset.shell'    = 'std shell'
;    'keysetcmd.shell' = 'shell'             'keysetcmd.shell' = 'shell'
;
; ---------------------------------------------------------------------------
; Define a named accel table. It has to be activated with SetKeyset.
;
; Syntax: DefKeyset [<name>] [<keyset_cmd_1> <keyset_cmd_2> ...]
;         DefKeyset [<name>] [<name_3>name] <keyset_cmd_4> ...]
;
; Instead of a keyset cmd, a keyset name can be specified (with 'name'
; appended). Then the specified keyset will be extended.
defc DefAccel, DefKeyset
   universal activeaccel
   universal lastkeyaccelid
   universal nepmd_hini
   -- Default accel table name = 'std' (standard EPM uses 'defaccel')
   StdName = 'std'

   -- Init accel table defs
   StartAccelId = 10000  -- max. = 65534 (65535 is hardcoded as Halt cmd)
   if lastkeyaccelid < StartAccelId then

      activeaccel = StdName
      lastkeyaccelid = StartAccelId
      -- Bug in ETK: first def is ignored, therefore add a dummy def here
      lastkeyaccelid = lastkeyaccelid
      -- This must be a valid def, otherwise the menu is not loaded at startup:
      buildacceltable activeaccel, 'sayerror Ignored!', AF_VIRTUALKEY, VK_ALT, lastkeyaccelid

   endif

   parse arg Name List

   Name = strip( Name)
   if Name = '' | lowcase( Name) = 'edit' | lowcase( Name) = 'default' then
      Name = StdName
   endif
   Name = lowcase( Name)

   List = strip( List)
   List = lowcase( List)
   if List = '' then
      -- Use default keyset defs
      if Name = StdName then
         List = StdName               -- use defc stdkeys
      else
         List = StdName'name' Name    -- extend stdkeys with defc Namekeys
      endif
   endif

   SavedAccel = activeaccel
   Keyset = Name
   activeaccel = Keyset

   -- The BlockAlt key subset needn't to be added to the 'keysets' array var
   'BlockAltKeys'

   -- Parse keyset definition list and get resolved list of KeysetCmds
   -- Keyset command defs have 'Keys' appended. In the following, the
   -- term 'keyset cmd' means the command without 'Keys'. The same applies
   -- for the array vars, were the string without 'Keys' is used, too.
   KeysetCmds = ''
   do w = 1 to words( List)
      ThisKeyset = word( List, w)
      -- Allow for specifying a name instead of a keyset
      -- (e.g. 'stdname' instead of 'std')
      if rightstr( ThisKeyset, 4) = 'name' and length( ThisKeyset) > 4 then
         SubName = leftstr( ThisKeyset, length( ThisKeyset) - 4)
         SubList = GetAVar( 'keyset.'SubName)
         do s = 1 to words( SubList)
            ThisSubKeyset = word( SubList, s)
            -- Check if keyset cmd (with 'Keys' appended) exists
            if isadefc( ThisSubKeyset'Keys') then
               KeysetCmds = KeysetCmds ThisSubKeyset
            endif
         enddo
      -- Check if keyset cmd (with 'Keys' appended) exists
      elseif isadefc( ThisKeyset'Keys') then
         KeysetCmds = KeysetCmds ThisKeyset
      endif
   enddo
   KeysetCmds = strip( KeysetCmds)

   if KeysetCmds <> '' then
       -- Change array vars for this keyset name
       PrevKeysetCmds = GetAVar( 'keyset.'Name)
       if PrevKeysetCmds <> KeysetCmds then
         -- For all keyset commands
         do k = 1 to words( PrevKeysetCmds)
            ThisKeyset = word( PrevKeysetCmds, k)
            -- Remove keyset name from array var for this keyset cmd
            DelAVar( 'keysetcmd.'ThisKeyset, Name)
         enddo
       endif

      -- Set array vars for this keyset name
      AddAVar( 'keysets', Name)
      SetAVar( 'keyset.'Name, KeysetCmds)
      -- For all keyset commands
      do k = 1 to words( KeysetCmds)
         ThisKeyset = word( KeysetCmds, k)
         -- Add keyset name to array var for this keyset cmd
         AddAVar( 'keysetcmd.'ThisKeyset, Name)
         -- Execute keyset cmd (with 'Keys' appended)
         ThisKeyset'Keys'
      enddo
   endif

   activeaccel = SavedAccel

; ---------------------------------------------------------------------------
; Block Alt and/or AltGr from switching to the menu
; PM defines the key F10 to jump to the menu, like Alt and AltGraf.
; It can be used instead, if it's not redefined.
; To block these PM def, Alt and AltGraf have to be defined with the
; AF_LONEKEY flag.
defc BlockAltKeys
   universal nepmd_hini

   -- Block Alt and/or AltGr from switching to the menu
   -- PM defines the key F10 to jump to the menu, like Alt and AltGraf.
   -- It can be used instead, if it's not redefined.
   -- To block these PM def, Alt and AltGraf have to be defined with the
   -- AF_LONEKEY flag.
   -- Redefine every used accel keyset
   KeyPath   = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   fBlocked1 = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   KeyPath   = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   fBlocked2 = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   if fBlocked1 = 1 then
      DefKey( 'alt', '', 'L')
   else
      UnDefKey( 'alt')
   endif

   if fBlocked2 = 1 then
      DefKey( 'altgraf', '', 'L')
   else
      UnDefKey( 'altgraf')
   endif

; ---------------------------------------------------------------------------
; Redefine every used accel keyset. This can be used by the menu commands
; toggle_block_left_alt_key and toggle_block_right_alt_key to activate the
; changed behavior for all loaded keysets.
defc RefreshBlockAlt
   universal nepmd_hini
   universal activeaccel

   KeyPath   = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   fBlocked1 = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   KeyPath   = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   fBlocked2 = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   SavedAccel = activeaccel
   KeySets = strip( GetAVar( 'keysets'))

   do w = 1 to words( KeySets)
      KeySet = word( KeySets, w)
      activeaccel = KeySet

      if fBlocked1 = 1 then
         DefKey( 'alt', '', 'L')
      else
         UnDefKey( 'alt')
      endif

      if fBlocked2 = 1 then
         DefKey( 'altgraf', '', 'L')
      else
         UnDefKey( 'altgraf')
      endif

   enddo
   activeaccel = SavedAccel

   activateacceltable activeaccel

; ---------------------------------------------------------------------------
defc LoadAccel
   parse arg args
   'SetKeyset' args  -- defined in MODEXEC.E

; ---------------------------------------------------------------------------
; SetKeyset: defined in MODEEXEC.E, contains mode-specific part, calls:
; SetKeyset2: switches keyset.
defc SetKeyset2
   universal activeaccel
   parse arg Name KeyDefs
   Name = lowcase( strip( Name))
   -- Default accel table name = 'std' (standard EPM uses 'defaccel')
   if Name = '' | Name = 'default' then
      Name = 'std'
   endif
   KeyDefs = lowcase( strip( KeyDefs))

   -- Maybe define keyset, if not already done
   DefinedKeysets = GetAVar( 'keysets')
   fKeysetChanged = 0
   PrevKeyDefs = strip( GetAVar( 'keyset.'Name))
   if KeyDefs = '' then
      if PrevKeyDefs = '' then
         NextKeyDefs = Name
      else
         NextKeyDefs = PrevKeyDefs
      endif
   else
      NextKeyDefs = KeyDefs
   endif

   --dprintf( 'SetKeyset2: DefinedKeysets = "'DefinedKeysets'", PrevKeyDefs = "'PrevKeyDefs'", NextKeyDefs = "'NextKeyDefs'"')
   if wordpos( Name, DefinedKeysets) = 0 then
      fKeysetChanged = 1
   elseif NextKeyDefs <> PrevKeyDefs then
      fKeysetChanged = 1
   endif
   if fKeysetChanged = 1 then
      --dprintf( 'SetKeyset2: "DefKeyset' Name KeyDefs'" called')
      'DefKeyset' Name KeyDefs
   endif

   -- Activate keyset
   activeaccel = Name
   activateacceltable activeaccel

; ---------------------------------------------------------------------------
defc ReloadKeyset
   universal activeaccel

   'DelKeyset'

   KeyDefs = strip( GetAVar( 'keyset.'activeaccel))
   -- Reset list of defined keysets to make SetKeyset2 execute DefKeyset
   call SetAVar( 'keysets', '')
   -- Redef key defs
   'SetKeyset2' activeaccel KeyDefs

   'LinkKeyDefs'

; ---------------------------------------------------------------------------
defc DeleteAccel, DelKeyset
   universal activeaccel
   if arg(1) = '' then
      Name = activeaccel
   else
      Name = arg(1)
   endif
   Name = lowcase( Name)
   deleteaccel Name

   -- Change array vars for this keyset name
   DelAVar( 'keysets', Name)
   KeysetCmds = GetAVar( 'keyset.'Name)
   -- For all keyset commands
   do k = 1 to words( KeysetCmds)
      ThisKeyset = word( KeysetCmds, k)
      -- Remove keyset name from array var for this keyset cmd
      DelAVar( 'keysetcmd.'ThisKeyset, Name)
   enddo
   DropAVar( 'keyset.'Name)

; ---------------------------------------------------------------------------
; executekey can only execute single keys. For strings containing multiple
; keys, keyin can be used.
defc dokey
   --sayerror 'dokey: k = 'arg(1)
   executekey resolve_key(arg(1))

; ---------------------------------------------------------------------------
defc executekey
   executekey arg(1)

; ---------------------------------------------------------------------------
defc keyin
   if arg(1) = '' then
      keyin ' '
   else
      keyin arg(1)
   endif

; ---------------------------------------------------------------------------
; In E3 and EOS2, we can use a_X to enter the value of any key.  In EPM,
; we can't, so the following routine is used by KEY and LOOPKEY to convert
; from an ASCII key name to the internal value.  It handles shift or alt +
; any letter, or a function key (optionally, with any shift prefix).  LAM

; suffix for virtual keys
;    hex dec
;    02  2   without prefix
;    0a  10  Sh
;    12  18  Ctrl
;    22  34  Alt
;
; suffix for letters
;    hex dec
;    10  16  Ctrl
;    20  32  Alt
;
defproc resolve_key( k)
   kl = lowcase( k)
   suffix = \2                            -- For unshifted function keys
   if length( k) >= 3 & pos( substr( k, 2, 1), '_-+') then
      if length( k) > 3 then
         if substr( kl, 3, 1) = 'f' then  -- Shifted function key
            suffix = substr( \10\34\18, pos( leftstr( kl, 1), 'sac'), 1)  -- Set suffix,
            kl = substr( kl, 3)              -- strip shift prefix, and more later...
         elseif wordpos( substr( kl, 3), 'left up right down') then
            suffix = substr( \10\34\18, pos( leftstr( kl, 1), 'sac'), 1)  -- Set suffix,
            kl = substr( kl, 3)              -- strip shift prefix, and more later...
         else                             -- Something we don't handle...
            sayerror 'Resolve_key:' sayerrortext(-328)
            rc = -328
         endif
      else                                -- alt+letter or ctrl+letter
         k = substr( kl, 3, 1) || substr(' ', pos( leftstr( kl, 1), 'ac'), 1)
      endif
   endif
   if leftstr( kl, 1) = 'f' & isnum( substr( kl, 2)) then
      k = chr( substr( kl, 2) + 31) || suffix
   elseif wordpos( kl, 'left up right down') then
      k = chr( wordpos( kl, 'left up right down') + 20) || suffix
   endif
   return k

; ---------------------------------------------------------------------------
defproc process_key(k)
   universal cua_marking_switch
   --sayerror 'process_key: k = 'k
   if length(k) = 1 & k <> \0 then
      i_s = insert_state()
      if cua_marking_switch then
         had_mark = process_mark_like_cua()
         if not i_s & had_mark then
            insert_toggle  -- Turn on insert mode because the key should replace
         endif             -- the mark, not the character after the mark.
      else
         had_mark = 0  -- set to 0 so we don't toggle insert state later
      endif
      keyin k
      if not i_s & had_mark then
         insert_toggle
      endif
   endif

; ---------------------------------------------------------------------------
; Ensure that default entry is present in NEPMD.INI
definit
   universal nepmd_hini
   DefaultNameList = lowcase( 'cuakeys')  -- only basenames

   KeyPath = '\NEPMD\User\Keys\AddKeyDefs\List'
   KeyDefs = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   NewKeyDefs = ''
   do w = 1 to words( DefaultNameList)
      ThisName = word( DefaultNameList, w)
      if not wordpos( ThisName, Keydefs) then
         NewKeyDefs = NewKeyDefs ThisName
      endif
   enddo
   NewKeyDefs = strip( NewKeyDefs)

   if NewKeyDefs <> '' then
      NepmdWriteConfigValue( nepmd_hini, KeyPath, KeyDefs NewKeyDefs)
   endif

; ---------------------------------------------------------------------------
defc LinkKeyDefs
   universal nepmd_hini
   None = '-none-'
   fLinked = 0

   KeyPath = '\NEPMD\User\Keys\AddKeyDefs\Selected'
   Current = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   --dprintf( 'LinkKeyDefs: previous = 'GetAVar( 'keyset.'activeaccel)', current = 'Current)
   if Current <> None & Current <> '' then
      'Link quiet 'Current
      do i = 1 to 1
         -- On success
         if rc >= 0 then
            fLinked = 1
         else
            -- Search .E file and maybe recompile it
            'Relink' Current'.e'
            if rc >= 0 then
               fLinked = 1
            else
               -- Remove from NEPMD.INI on link error
               rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath, None)
               sayerror 'Additional key defs file "'Current'.ex" could not be found.'
            endif
         endif
         if fLinked then
            parse value lowcase( Current) with Name'keys'  -- strip 'keys'
            'SetKeyset std stdname' Name
         endif
      enddo
   endif

definit
   'AtInit LinkKeyDefs'

; ---------------------------------------------------------------------------
defproc GetKeyDef
   universal nepmd_hini
   None = '-none-'
   KeyPath = '\NEPMD\User\Keys\AddKeyDefs\Selected'
   Current = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Current = '' then
      Current = None
   endif
   return Current

; ---------------------------------------------------------------------------
; Open a listbox to select aditional key defs. The additional defs must be
; placed in a separate E file, without using the defkeys statement. When
; simply linking such a file, all special keysets for already loaded files
; would be lost and the keyset EDIT_KEYS is set for all loaded files.
; Therefore EPM will be restarted to make the changes take effect as
; expected. For unlinking a key def file, no restart is required.
defc SelectKeyDefs
   universal nepmd_hini
   None = '-none-'

   parse arg Action Basename
   Action = upcase( Action)
   lp = lastpos( '\', strip( Basename))
   Basename = substr( Basename, lp + 1)
   Basename = lowcase( Basename)
   if Basename = '' then
   elseif rightstr( Basename, 2) = '.e' then
      Basename = leftstr( Basename, length( Basename) - 2)
   elseif rightstr( Basename, 3) = '.ex' then
      Basename = leftstr( Basename, length( Basename) - 3)
   endif

   -- Read available files from NEPMD.INI
   KeyPath1 = '\NEPMD\User\Keys\AddKeyDefs\List'
   KeyPath2 = '\NEPMD\User\Keys\AddKeyDefs\Selected'
   KeyDefs = NepmdQueryConfigValue( nepmd_hini, KeyPath1)  -- space-separated list
   Current = NepmdQueryConfigValue( nepmd_hini, KeyPath2)
   if Current = '' then
      Current = None
   endif

   if Action = 'ADD' & Basename <> '' then

      if not wordpos( Basename, KeyDefs) then
         KeyDefs = strip( KeyDefs Basename)
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath1, KeyDefs)
      endif

      Path = Get_Env('EPMEXPATH')
      ListFiles = ''
      BaseNames = ReadMacroLstFiles( Path, ListFiles)

      if not pos( ';'Basename';', ';'BaseNames) then
         Title = 'Adding additional key definitions'
         Text = 'For the additional key definition macro "'Basename'" no'
         Text = Text || ' entry in a LST file was found. In order to make'
         Text = Text || ' the RecompileNew macro aware of that file, it'
         Text = Text || ' should be added to "myexfiles.lst".'\n\n
         Text = Text || 'Should the entry be added automatically?'
         Style = MB_YESNO+MB_QUERY+MB_DEFBUTTON1+MB_MOVEABLE
         ret = winmessagebox( Title,
                              Text,
                              Style)
         if ret = 6 then  -- Yes
            call AddToMacroLstFile( Basename)
            if rc <> 0 then
               sayerror 'Error: AddToMacroLstFile( 'Basename') returned rc = 'rc
               return
            endif
         elseif ret = 7 then  -- No
         endif
      endif

      Title = 'Adding additional key definitions'
      Text = 'Before the macro file "'Basename'" can be loaded,'
      Text = Text || ' it has to be compiled.'\n\n
      Text = Text || 'Should RecompileNew be called now?'
      Style = MB_YESNO+MB_QUERY+MB_DEFBUTTON1+MB_MOVEABLE
      Style = MB_YESNO+MB_WARNING+MB_DEFBUTTON1+MB_MOVEABLE
      ret = winmessagebox( Title,
                           Text,
                           Style)
      if ret = 6 then  -- Yes
         -- Execute RecompileNew and open this dialog again
         'RecompileNew'
         'postme SelectKeyDefs'
         return
      elseif ret = 7 then  -- No
      endif
   endif

   -- Open listbox
   Rest = KeyDefs
   Sep = '/'
   Entries = Sep''None
   do w = 1 to words( Rest)
      Next = word( Rest, w)
      Entries = Entries''Sep''Next
   enddo

   DefaultItem = 1
   if Current <> '' then
      wp = wordpos( Current, KeyDefs)
      if wp > 0 then
         DefaultItem = wp + 1
      endif
   endif
   DefaultButton = 1
   HelpId = 0
   Title = 'Select additional key definitions'copies( ' ', 20)
   --Text = 'These defs override or extend the standard keyset.'
   --Text = 'Current key def additions for the standard keyset: 'Current
   Text = 'Current key def additions: 'Current

   refresh
   Result = listbox( Title,
                     Entries,
                     '/~Set/~Add.../~Edit/~Remove/Cancel', -- buttons
                     0, 0,  --5, 5,                       -- top, left,
                     min( words( KeyDefs), 15), 50,  -- height, width
                     gethwnd(APP_HANDLE) || atoi(DefaultItem) ||
                     atoi(DefaultButton) || atoi(HelpId) ||
                     Text\0 )
   refresh

   -- Check result
   button = asc( leftstr( Result, 1))
   EOS = pos( \0, Result, 2)        -- CHR(0) signifies End Of String
   Selected = substr( Result, 2, EOS - 2)
   if button = 1 then      -- Set
      -- Unlink current
      if Current <> None then
         if linked( Current) > 0 then
            'unlink 'Current
         endif
      endif
      if Selected = None then
         Msg = 'No keyset additions file active.'
         'SetKeyset std std'
         'postme RefreshMenu'
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath2, None)
         sayerror Msg
      else
         -- Check if .E file exists
         findfile EFile, Selected'.e', 'EPMPATH'
         if rc then
            -- Check if .EX file exists
            findfile EFile, Selected'.ex', 'EPMPATH'
            if rc then
               sayerror 'Key definition file 'upcase( Selected)'.E or 'upcase( Selected)'.EX not found.'
               return 2
            endif
         endif
         -- Write selected value to NEPMD.INI
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath2, Selected)
         Msg = 'Keyset additions file 'upcase( Selected)'.EX activated.'
         'LinkKeyDefs'
         'postme RefreshMenu'
         sayerror Msg
      endif
   elseif button = 2 then  -- Add
      -- Open fileselector to select an e or ex filename
      -- Call this Cmd again, but with args to repaint the list
      'FileDlg Select a file with additional key definitions, SelectKeyDefs ADD, 'Get_Env('NEPMD_USERDIR')'\macros\*.e'
      return 0
   elseif button = 3 & Selected <> None then  -- Edit
      -- Load file
      'ep 'Selected'.e'
      return rc
   elseif button = 4 & Selected <> None then  -- Remove
      if linked( Selected) > 0 then
         'unlink 'Selected
      endif
      'SetKeyset std std'
      'postme RefreshMenu'
      rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath2, None)
      wp = wordpos( Selected, KeyDefs)
      if wp > 0 then
         NewKeyDefs = DelWord( KeyDefs, wp, 1)
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath1, NewKeyDefs)
      endif
      -- Call this Cmd again
      'SelectKeyDefs'
   else                    -- Cancel
   endif


; ---------------------------------------------------------------------------
;  Definitions used for key commands
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; This command allows to define 2 commands, separated by a bar char. The
; first command applies in stream mode and the second in line mode.
defc StreamLine
   universal stream_mode
   parse arg cmd1'|'cmd2
   cmd1 = strip( cmd1)
   cmd2 = strip( cmd2)
   if stream_mode then
      cmd1
   else
      cmd2
   endif

; ---------------------------------------------------------------------------
defproc process_mark_like_cua()
   if marktype() then
      getmark firstline, lastline, firstcol, lastcol, markfileid
      getfileid fileid
      if fileid <> markfileid then
         sayerror MARKED_OTHER__MSG
         unmark
      elseif not check_mark_on_screen() then
         sayerror MARKED_OFFSCREEN__MSG
         unmark
      else
         'Copy2DMBuff'    -- see clipbrd.e for details
         firstline
         .col = firstcol
         call NextCmdAltersText()
         call pdelete_mark()
         'ClearSharBuff'  -- remove Content in EPM shared text buffer
         return 1
      endif
   endif

; ---------------------------------------------------------------------------
defproc shifted
   universal curkey

   -- Works for WM_CHAR messages:
   ks = getkeystate(VK_SHIFT)
   fshifted1 = (ks <> 3 & ks <> 4)

   -- Works for accelerator keys:
   parse value (curkey) with CurKeyName \1 .
   fshifted2 = (pos( 's_', CurKeyName) > 0)

   return (fshifted1 | fshifted2)

; ---------------------------------------------------------------------------
defproc updownkey( down_flag)
   universal save_cursor_column
   universal cursoreverywhere
   universal prevkey
   parse value (prevkey) with PrevKeyName \1 .
   fupdown = (wordpos( PrevKeyName, 'up down s_up s_down') > 0)
   if not cursoreverywhere then
      if not fupdown then
         save_cursor_column = .col
      endif
   endif

   if down_flag then
      down
   else
      up
   endif

   if .line & not cursoreverywhere then
      l = length( textline(.line))
      if fupdown & l >= save_cursor_column then
         .col = save_cursor_column
      elseif fupdown | l < .col then
         end_line
      endif
   endif

; ---------------------------------------------------------------------------
define CHARG_MARK = 'CHARG'

defproc extend_mark( startline, startcol, forward)
   universal cua_marking_switch
   universal nepmd_hini
   universal cursoreverywhere
   universal curkey

   KeyPath = '\NEPMD\User\Mark\ShiftMarkExtends'
   fAlwaysExtend = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   getfileid curfileid
   getmarkg firstline, lastline, firstcol, lastcol, markfileid
   parse value (curkey) with CurKeyName \1 .
   fs_up   = (CurKeyName = 's_up')
   fs_down = (CurKeyName = 's_down')

   funmark = 1
   if markfileid <> curfileid then
      funmark = 1
   elseif cua_marking_switch then
      -- keep mark and extend it (any unshifted key caused unmark before)
      funmark = 0
   elseif fAlwaysExtend then
      -- keep mark and extend it
      funmark = 0

   -- The following was added for the feature "Shift-Mark extends at mark
   -- boundaries only" (== "Shift-mark extends always" = deactivated):
   elseif not cursoreverywhere then
      if     startline = firstline & startcol = firstcol then
         funmark = 0
      elseif startline = lastline & startcol = lastcol then
         funmark = 0
      endif
   elseif cursoreverywhere then
      l = length( textline( startline))
      if     startline = firstline & startcol = firstcol then
         funmark = 0
      elseif startline = firstline & startcol > firstcol & startcol > l + 1 then
         funmark = 0
      elseif startline = firstline + 1 & firstcol = 0 then
         -- apparently never reached
         funmark = 0
      elseif startline = lastline & startcol = lastcol then
         funmark = 0
      elseif startline = lastline & startcol > lastcol & startcol > l + 1 then
         funmark = 0
      elseif startline = lastline - 1 & lastcol = 0 then
         funmark = 0
      endif
   endif

   if funmark then
      unmark
   endif

   if not marktype() then
      call pset_mark( startline, .line, startcol, .col, CHARG_MARK, curfileid)
      return
   endif

   if (fs_up & .line = firstline - 1) | (fs_down & .line = firstline + 1) then
      if length(textline(firstline)) < .col then
         firstcol = .col
      endif
   endif

   if startline > firstline | ((startline = firstline) & (startcol > firstcol)) then  -- at end of mark
      if not forward then
         if firstline = .line & firstcol = .col then
            unmark
            return
         endif
      endif
      call pset_mark( firstline, .line, firstcol, .col, CHARG_MARK, curfileid)
   else                                                         -- at beginning of mark
      if forward then
         if lastline = .line & lastcol = .col - 1 then
            unmark
            return
         endif
      endif
      call pset_mark( lastline, .line, lastcol, .col, CHARG_MARK, curfileid)
   endif

; ---------------------------------------------------------------------------
; c_home, c_end, c_left & c_right do different things if the shift key is depressed.
; The logic is extracted here mainly due to the complexity of the COMPILE IF's
defproc begin_shift( var startline, var startcol, var shift_flag)
   universal cua_marking_switch
   universal curkey
   shift_flag = shifted()
   if shift_flag or not cua_marking_switch then
      startline = .line; startcol = .col
   else
      unmark
   endif

; ---------------------------------------------------------------------------
defproc end_shift( startline, startcol, shift_flag, forward_flag)
; Make this work regardless of which marking mode is active:
compile if 0 -- WANT_CUA_MARKING = 'SWITCH'
   universal cua_marking_switch
   if shift_flag & cua_marking_switch then
compile else
   if shift_flag then
compile endif
      call extend_mark( startline, startcol, forward_flag)
   endif

; ---------------------------------------------------------------------------
; Example: def space 'ExpandFirst Space'
defc ExpandFirst
   call ExpandFirstSecond( 0, arg(1))

; ---------------------------------------------------------------------------
; Example: def c_newline 'ExpandSecond StdEnter'
defc ExpandSecond
   call ExpandFirstSecond( 1, arg(1))

; ---------------------------------------------------------------------------
; Process syntax expansion, if defined and if success, otherwise execute
; StdDef.
defproc ExpandFirstSecond( fSecond, StdDef)
   universal expand_on
   fExpanded = 0
   getfileid fid
   ExpandMode = GetAVar( 'expand.'fid)
   if expand_on & ExpandMode <> '' & wordpos( upcase( ExpandMode), '0 OFF') = 0 then
      if fSecond then
         ExpandCmd = ExpandMode'SecondExpansion'
      else
         ExpandCmd = ExpandMode'FirstExpansion'
      endif
      if isadefc( ExpandCmd) then
         ExpandCmd
         fExpanded = (rc = 0)
      endif
   endif
   if not fExpanded then
      StdDef
   endif
   return

; ---------------------------------------------------------------------------
defc ForceExpansion
   universal expand_on
   getfileid fid
   ExpandMode = GetAVar( 'expand.'fid)
   if expand_on & ExpandMode <> '' & wordpos( upcase( ExpandMode), '0 OFF') = 0 then
      if isadefc( ExpandMode'ForceExpansion') then
         ExpandMode'ForceExpansion'
      endif
   endif

; ---------------------------------------------------------------------------
defc Space
   universal cua_marking_switch
   call NextCmdAltersText()
   if cua_marking_switch then
      call process_mark_like_cua()
   endif
   keyin ' '

; ---------------------------------------------------------------------------
defproc MatchCharsEnabled
   universal nepmd_hini
   KeyPath = '\NEPMD\User\MatchChars'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   return (on = 1)

; ---------------------------------------------------------------------------
;def '{'
defc OpeningBrace
   universal match_chars
   keyin '{'
   if MatchCharsEnabled() then
      wp = wordpos( '{', match_chars)
      if wp then
         match = word( match_chars, wp + 1)
         keyin match
         do l = 1 to length( match)
            left
         enddo
      endif
   endif

;def '('
defc OpeningParen
   universal match_chars
   keyin '('
   if MatchCharsEnabled() then
      wp = wordpos( '(', match_chars)
      if wp then
         match = word( match_chars, wp + 1)
         keyin match
         do l = 1 to length( match)
            left
         enddo
      endif
   endif

;def '['
defc OpeningBracket
   universal match_chars
   keyin '['
   if MatchCharsEnabled() then
      wp = wordpos( '[', match_chars)
      if wp then
         match = word( match_chars, wp + 1)
         keyin match
         do l = 1 to length( match)
            left
         enddo
      endif
   endif

;def '<'
defc OpeningAngle
   universal match_chars
   keyin '<'
   if MatchCharsEnabled() then
      wp = wordpos( '<', match_chars)
      if wp then
         match = word( match_chars, wp + 1)
         keyin match
         do l = 1 to length( match)
            left
         enddo
      endif
   endif

; ---------------------------------------------------------------------------
;def '}'
defc ClosingBrace
   universal closing_brace_auto_indent
   if closing_brace_auto_indent then
      -- check if line is blank, before typing }
      LineIsBlank = (verify( textline(.line), ' '\t) = 0)
      if LineIsBlank then
         l = 0
         PrevIndent = 0
         do l = 1 to 100 -- upper limit
            getline line0, .line - l             -- line0 = line before }
            p0 = max( 1, verify( line0, ' '\t))  -- p0     = pos of first non-blank in line 0
            if length(line0) > p0 - 1 then  -- if not a blank line
               PrevIndent = p0 - 1
               -- check if last non-empty line is a {
               if rightstr( strip( line0), 1) = '{' then
                  NewIndent = PrevIndent
               else
                  NewIndent = PrevIndent - GetCIndent()
               endif
               leave
            endif
         enddo
         .col = max( 1, NewIndent + 1)  -- unindent
      endif
   endif
   -- type } and highlight matching {
   'balance }'

; ---------------------------------------------------------------------------

defc AdjustMark
   call NextCmdAltersText()
   call pcommon_adjust_overlay('A')

defc OverlayMark
   call NextCmdAltersText()
   if marktype() then
      call pcommon_adjust_overlay('O')
   else                -- if no mark, look to in Shared Text buffer
      'GetSharBuff O'  -- see clipbrd.e for details
   endif

defc CopyMark
   call NextCmdAltersText()
   if marktype() then
      call pcopy_mark()
   else                -- if no mark, look to in Shared Text buffer
      'GetSharBuff'    -- see clipbrd.e for details
   endif

defc MoveMark
   universal nepmd_hini
   call NextCmdAltersText()
   call pmove_mark()
   KeyPath = '\NEPMD\User\Mark\UnmarkAfterMove'
   UnmarkAfterMove = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if UnmarkAfterMove = 1 then
      unmark
      'ClearSharBuff'  -- remove Content in EPM shared text buffer */
   endif

defc DeleteMark
   call NextCmdAltersText()
   'Copy2DMBuff'       -- see clipbrd.e for details
   call pdelete_mark()
   'ClearSharBuff'     -- remove Content in EPM shared text buffer

defc unmark
   unmark
   'ClearSharBuff'     -- remove Content in EPM shared text buffer

defc BeginMark
   call pbegin_mark()

defc EndMark
   call pend_mark()
   if substr( marktype(), 1, 1) <> 'L' then
      right
   endif

defc FillMark  -- accepts key from macro
   key = arg(1)
   call NextCmdAltersText()
   call checkmark()
   call pfill_mark( key)

defc TypeFrameChars
   call NextCmdAltersText()
   keyin 'º Ì É È Ê Í Ë ¼ » ¹ Î ³ Ã Ú À Á Ä Â Ù ¿ ´ Å Û ² ± °'

defc ShiftLeft   -- Can't use the old A_F7 in EPM.  PM uses it as an accelerator key.
   mt = marktype()
   if not mt then
      return
   endif
   getmark firstline, lastline, firstcol, lastcol, fid
   getfileid curfid
   if curfid <> fid then
      unmark
      sayerror MARKED_OTHER__MSG
      return
   endif
   call NextCmdAltersText()
   if mt = 'CHAR' then
      -- Change to line mark
      if lastCol = 0 then
         lastLine = lastLine - 1
      endif
      firstcol = 1
      lastcol = MAXCOL
      unmark
      call pset_mark( firstline, lastline, firstcol, lastcol, 'LINE', fid)
   endif
   shift_left
compile if SHIFT_BLOCK_ONLY
   if marktype() = 'BLOCK' then  -- code by Bob Langer
      getmark fl, ll, fc, lc, fid
      call pset_mark( fl, ll, lc, MAXCOL, 'BLOCK', fid)
      shift_right
      call pset_mark( fl, ll, fc, lc, 'BLOCK', fid)
   endif
compile endif

defc ShiftRight   -- Can't use the old A_F8 in EPM.  PM uses it as an accelerator key.
   mt = marktype()
   if not mt then
      return
   endif
   getmark firstline, lastline, firstcol, lastcol, fid
   getfileid curfid
   if curfid <> fid then
      unmark
      sayerror MARKED_OTHER__MSG
      return
   endif
   call NextCmdAltersText()
   if mt = 'CHAR' then
      -- Change to line mark
      if lastCol = 0 then
         lastLine = lastLine - 1
      endif
      firstcol = 1
      lastcol = MAXCOL
      unmark
      call pset_mark( firstline, lastline, firstcol, lastcol, 'LINE', fid)
   endif
compile if SHIFT_BLOCK_ONLY
   if marktype() = 'BLOCK' then  -- code by Bob Langer
      getmark fl, ll, fc, lc, fid
      call pset_mark( fl, ll, lc, MAXCOL, 'BLOCK', fid)
      shift_left
      call pset_mark( fl, ll, fc, lc, 'BLOCK', fid)
   endif
compile endif
   shift_right

/* We can't use a_f10 for previous file any more, PM uses that key. */
/* I like F11 and F12 to go back and forth.                         */
defc prevfile  -- a_F10 is usual E default; F11 for enh. kbd, c_P for EPM.
   prevfile

defc JoinLines
   call NextCmdAltersText()
   call joinlines()

defc MarkBlock
   getmark firstline, lastline, firstcol, lastcol, markfileid
   getfileid fileid
   if fileid <> markfileid then
      unmark
   endif
   if wordpos( marktype(), 'LINE CHAR') then
      --call pset_mark( firstline, lastline, firstcol, lastcol, BLOCKGMARK, fileid)
      unmark
   endif
   markblock
   'Copy2SharBuff'     -- copy mark to shared text buffer

defc MarkLine
   getmark firstline, lastline, firstcol, lastcol, markfileid
   getfileid fileid
   if fileid <> markfileid then
      unmark
   endif
   if wordpos( marktype(), 'BLOCK CHAR') then
      --call pset_mark( firstline, lastline, firstcol, lastcol, LINEMARK, fileid)
      unmark
   endif
   mark_line
   'Copy2SharBuff'     -- copy mark to shared text buffer

defc MarkChar
   getmark firstline, lastline, firstcol, lastcol, markfileid
   getfileid fileid
   if fileid <> markfileid then
      unmark
   endif
   if wordpos( marktype(), 'BLOCK LINE') then
      --call pset_mark( firstline, lastline, firstcol, lastcol, CHARGMARK, fileid)
      unmark
   endif
   mark_char
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

defc HighlightCursor
   circleit 5, .line, .col - 1, .col + 1, 16777220

defc TypeFileName  -- Type the full name of the current file
   call NextCmdAltersText()
   keyin .filename

defc TypeDateTime  -- Type the current date and time
   call NextCmdAltersText()
   keyin DateTime()

defc select_all =
   getfileid fid
   call pset_mark(1, .last, 1, length(textline(.last)), 'CHAR' , fid)
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

defc ReflowAll2ReflowMargins
   universal reflowmargins
   'ReflowAll' reflowmargins

; Syntax: reflow_all [<margins>]
defc reflow_all, ReflowAll
   call NextCmdAltersText()
   saved_margins = .margins
   if arg(1) > '' then
      .margins = arg(1)
   endif
   call psave_mark(savemark)
   call psave_pos(savepos)
   display -1
   stopit = 0
   top
   do forever
      getline line
      do while line='' |                              -- Skip over blank lines or
               (lastpos(':',line)=1 & pos('.',line)=length(line)) |  -- lines containing only a GML tag or
               substr(line,1,1)='.'                                  -- SCRIPT commands
         if .line=.last then stopit=1; leave; endif
         down
         getline line
      enddo
      if stopit then leave; endif
      startline = .line
      unmark; mark_line
      call pfind_blank_line()
      if .line<>startline then
         up
      else
         bottom
      endif
      mark_line
      reflow
      getmark firstline,lastline
      if lastline=.last then leave; endif
      lastline+1
   enddo
   display 1
   call prestore_mark(savemark)
   call prestore_pos(savepos)
   if arg(1) > '' then
      .margins = saved_margins
   endif

defc ReflowPar2ReflowMargins
   universal reflowmargins
   'ReflowPar' reflowmargins

; Syntax: ReflowPar [<margins>]
defc ReflowPar
   /* Protect the user from accidentally reflowing a marked  */
   /* area not in the current file, and give a good message. */
   mt = substr( marktype(), 1, 1)
;  if mt = 'B' or mt = 'L' then
   if mt > '' then
      getmark firstline, lastline, firstcol, lastcol, markfileid
      getfileid fileid
      if fileid <> markfileid then
;        sayerror CANT_REFLOW__MSG'  'OTHER_FILE_MARKED__MSG
;        return
         unmark
         sayerror MARKED_OTHER__MSG
         mt = ''
      endif
   endif

   if mt <> ' ' then
      if not check_mark_on_screen() then
         sayerror MARK_OFF_SCREEN__MSG
         stop
      endif
   endif

   saved_margins = .margins
   if arg(1) > '' then
      .margins = arg(1)
   endif
   call NextCmdAltersText()
   display -1

   if mt = 'B' then
      'box r'
   elseif mt = 'C' then
      sayerror WRONG_MARK__MSG
   elseif mt = 'L' then
      reflow
   else  -- Standard text reflow split into a separate routine.
      call text_reflow()
   endif

   display 1
   if arg(1) > '' then
      .margins = saved_margins
   endif

; Standard text reflow, moved from Alt+P definition in STDKEYS.E.
; Only called from Alt+P if no mark exists; users wishing to call
; this from their own code must save & restore the mark themselves
; if that's desired.
defproc text_reflow
   universal nepmd_hini
   call NextCmdAltersText()
   KeyPath = '\NEPMD\User\Reflow\Next'
   ReflowNext = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if .line then
      getline line
      if line <> '' then  -- If currently on a blank line, don't reflow.
         oldcursory = .cursory
         oldcursorx = .cursorx
         oldline = .line
         oldcol  = .col
         unmark
         mark_line
         call pfind_blank_line()
         -- Ver 3.11:  slightly revised test works better with GML sensitivity.
         if .line <> oldline then
            up
         else
            bottom
         endif
         mark_line
         reflow
         if ReflowNext then   -- position on next paragraph (like PE)
            call pfind_blank_line()
            for i = .line + 1 to .last
               getline line, i
               if line <> '' then
                  .lineg = i
                  .col = 1
                  .cursory = oldcursory
                  .line = i
                  leave
               endif
            endfor
         else
            -- or like old E
            getmark firstline, lastline
            firstline
            .cursory = oldcursory
            .cursorx = oldcursorx
            oldline
            .col = oldcol
         endif
         unmark
      endif
   endif

definit                         -- Variable is null if alt_R is not active.
   universal alt_R_active       -- For E3/EOS2, it's 1 if alt_R is active.
   alt_R_active = ''            -- For EPM, it's set to querycontrol(messageline).

defc ReflowBlock
   universal alt_R_active,tempofid
   universal alt_R_space

   call NextCmdAltersText()
   if alt_R_active <> '' then
      call pblock_reflow( 1, alt_R_space, tempofid)     -- Complete the reflow.
      'setmessageline '\0
      'toggleframe 2 'alt_R_active           -- Restore status of messageline.
      alt_R_active = ''
      return
   endif
   if pblock_reflow( 0, alt_R_space, tempofid) then
      sayerror PBLOCK_ERROR__MSG      /* HurleyJ */
      return
   endif
;  if marktype() <> 'BLOCK' then
      unmark
;  endif
   alt_R_active = queryframecontrol(2)         -- Remember if messageline on or off
   'toggleframe 2 1'                    -- Force it on
   'setmessageline' BLOCK_REFLOW__MSG

defc Split
   call NextCmdAltersText()
   split

defc SplitLines
   call NextCmdAltersText()
   call splitlines()

defc CenterMark
   call NextCmdAltersText()
   call pcenter_mark()

defc BackSpace
   universal stream_mode
   universal cua_marking_switch
   universal curkey
   universal prevkey
   if cua_marking_switch then
      if process_mark_like_cua() then
         return
      endif
   endif
   call NextCmdAltersText()
   if .col = 1 & .line > 1 & stream_mode then
      up
      l = length( textline(.line))
      join
      .col = l + 1
   else
      old_level = .levelofattributesupport
      if old_level & not (old_level bitand 2) then
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = -300
      endif
      -- begin workaround for cursor just behind or at begin of a mark
      -- For char mark: Move mark left if cursor is on mark begin or end
      old_col  = .col
      old_line = .line
      CorrectMarkBegin = 0
      CorrectMarkEnd   = 0
      mt = marktype()
      if mt = 'CHAR' then
         getmark first_line, last_line, first_col, last_col, fid
         if ((old_col > 1) & (first_line = old_line) & (first_line = last_line) & (first_col = old_col)) then
            -- Cursor is on mark begin and first_line = last_line
            CorrectMarkBegin = 1
            CorrectMarkEnd   = 1
         elseif ((old_col > 1) & (first_line = old_line) & (first_col = old_col)) then
            -- Cursor is on mark begin
            CorrectMarkBegin = 1
         elseif ((old_col > 0) & (last_line = old_line) & (last_col = old_col - 1)) then
            -- Cursor is 1 col behind mark end
            CorrectMarkEnd   = 1
         endif
         --sayerror first_line', 'last_line', 'first_col', 'last_col', Marktype = 'mt ||
         --         ', CorrectMarkEnd/Begin = 'CorrectMarkEnd CorrectMarkBegin
      endif
      -- end workaround for cursor just behind or at begin of a mark
      rubout
      -- begin workaround for cursor just behind or at begin of a mark
      --mt = wordpos(mt,'LINE CHAR BLOCK CHARG BLOCKG')-1
      if CorrectMarkBegin then
         first_col = first_col - 1   -- move first_col left
      endif
      if CorrectMarkEnd then
         last_col  = last_col - 1    -- move last_col left
      endif
      if CorrectMarkBegin | CorrectMarkEnd then
         pset_mark( first_line, last_line, first_col, last_col, mt, fid)
      endif
      -- end workaround for cursor just behind or at begin of a mark
      .levelofattributesupport = old_level
   endif

defc TypeNull
   call NextCmdAltersText()
   keyin \0                  -- C_2 enters a null.
defc TypeNot
   call NextCmdAltersText()
   keyin \170                -- C_6 enters a "not" sign
defc TypeOpeningBrace
   call NextCmdAltersText()
   keyin '{'
defc TypeClosingBrace
   call NextCmdAltersText()
   keyin '}'
defc TypeCent
   call NextCmdAltersText()
   keyin '›'                 -- C_4 enters a cents sign

defc DeleteLine
   call NextCmdAltersText()
   if .levelofattributesupport then
      if (.line == .last and .line <> 1) then   -- this is the last line
         destinationLine = .line - 1            -- and there is a previous line to store attributes on
         getline prevline, DestinationLine
         DestinationCol = length(prevline) + 1  -- start search parameters
                                                -- destination of attributes
         findoffset = -300                      -- start at the begin of the attr list
         findline = .line                       -- of the first char on this line
         findcolumn = 1

         do forever        -- search until no more attr's (since this is last line)
            findclass = 0          -- 0 is anyclass
            Attribute_action FIND_NEXT_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline <> .line) then  -- No attribute, or not on this line
               leave
            endif
            query_attribute theclass, thevalue, thepush, findoffset, findcolumn, findline   -- push or pop?
            if not thePush then       -- ..if its a pop attr and ..
               matchClass = theClass
               MatchOffset = FindOffset
               MatchLine = FindLine
               MatchColumn = FindColumn  -- ..and if its match is not on this line or at the destination
               Attribute_Action FIND_MATCH_ATTR_SUBOP, MatchClass, MatchOffset, Matchcolumn, MatchLine
               if ((Matchline == DestinationLine) and (Matchcolumn == destinationcol)) then
                  -- then there is a cancellation of attributes
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
                  Attribute_action Delete_ATTR_SUBOP, Matchclass, Matchoffset, Matchcolumn, Matchline
               elseif (MatchLine <> .line)  then
                  -- .. then move attribute to destination (before attributes which have been scanned so its OK.)
                  -- insert attr at the end of the attr list (offset=0)
                  Insert_Attribute theclass, thevalue, 0, 0, DestinationCol, DestinationLine
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
               endif -- end if attr is on line or at destination
            endif -- end if found attr is a pop
         enddo  -- end search for attr's
      elseif .line < .last then  -- put the attributes after the line since there may not
                                 -- be a line before this line (as when .line==1)
         DestinationCol = 1
         DestinationLine = .line + 1     -- error point since this puts attr's after last line if .line=.last
         findoffset = 0                  -- cant make it .line-1 cause then present attributes there become
         findline = .line                -- after these attributes which is wrong
         findcolumn = MAXCOL

         do forever
            findclass = 0
            Attribute_action FIND_PREV_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline <> .line) then  -- No attribute, or not on this line
               leave
            endif
             /* Move Attribute */
            query_attribute theclass, thevalue, thepush, findoffset, findcolumn, findline
            -- only move push/pop model attributes (tags are just deleted)
            if ((thepush == 0) or (thepush == 1)) then
               -- move attribute to destination, if cancellation delete both attributes
               FastMoveAttrToBeg( theclass, thevalue, thepush, DestinationCol, DestinationLine, findcolumn, findline, findoffset)
               findoffset = findoffset + 1  -- since the attr rec was deleted and all attr rec's were shifted to fill the vacancy
                                            -- and search is exclusive
            endif
         enddo
      endif -- endif .line=.last and .line=1
   endif -- .levelofattributesupport
   deleteline

; Ctrl-D = word delete, thanks to Bill Brantley.
defc DeleteUntilNextword /* delete from cursor until beginning of next word, UNDOable */
   call NextCmdAltersText()
   getline line
   begcur = .col
   lenLine = length(line)
   if lenLine >= begcur then
      for i = begcur to lenLine /* delete remainder of word */
         if substr( Line, i, 1) <> ' ' then
            deletechar
         else
            leave
         endif
      endfor
      for j = i to lenLine /* delete delimiters following word */
         if substr( Line, j, 1) == ' ' then
            deletechar
         else
            leave
         endif
      endfor
   endif

defc DeleteUntilEndLine
   call NextCmdAltersText()
   erase_end_line  -- Ctrl-Del is the PM way.

defc EndFile
   universal stream_mode
   call begin_shift( startline, startcol, shift_flag)
   if stream_mode then
      bottom
      endline
   else
      if .line = .last and .line then
         endline
      endif
      bottom
   endif
   call end_shift( startline, startcol, shift_flag, 1)

; Moved def c_f to LOCATE.E

; c_f1 is not definable in EPM.
defc UppercaseWord
   call NextCmdAltersText()
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call puppercase()
   call prestore_mark(save_mark)

defc LowercaseWord
   call NextCmdAltersText()
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call plowercase()
   call prestore_mark(save_mark)
   call prestore_pos(save_pos)

defc UppercaseMark
   call NextCmdAltersText()
   call puppercase()

defc LowercaseMark
   call NextCmdAltersText()
   call plowercase()

defc BeginWord
   call pbegin_word()

defc EndWord
   call pend_word()

defc BeginFile
   universal stream_mode
   call begin_shift( startline, startcol, shift_flag)
   if stream_mode then
      top
      begin_line
   else
      if .line = 1 then
         begin_line
      endif
      top
   endif
   call end_shift( startline, startcol, shift_flag, 0)

defc DuplicateLine      -- Duplicate a line
   call NextCmdAltersText()
   getline line
   insertline line,.line+1

defc CommandDlgLine
   if .line then
      getline line
      'commandline 'line
   endif

defc PrevWord
   universal stream_mode
   call begin_shift( startline, startcol, shift_flag)
   if not .line then
      begin_line
   elseif (.line > 1) & (.col = max( 1,verify(textline(.line),' '))) & stream_mode then
      up
      end_line
   endif
   backtab_word
   call end_shift( startline, startcol, shift_flag, 0)

defc NextWord
   universal stream_mode
   call begin_shift( startline, startcol, shift_flag)
   getline line
   if not .line | (lastpos( ' ',line) < .col) & (.line < .last) & stream_mode then
      down
      call pfirst_nonblank()
   else
      tab_word
   endif
   call end_shift(startline, startcol, shift_flag, 1)

defc BeginScreen
   call begin_shift( startline, startcol, shift_flag)
   .cursory = 1
   call end_shift( startline, startcol, shift_flag, 0)

defc EndScreen
   call begin_shift( startline, startcol, shift_flag)
   .cursory = .windowheight
   call end_shift( startline, startcol, shift_flag, 1)

; ---------------------------------------------------------------------------
; Record and playback key and menu commands
; The array var 'recordkeys' holds the list of \0-separated Key\1Cmd pairs.
; It is set by SaveKeyCmd, that is called by OtherKeys, ExecKeyCmd and
; ExecAccelKey.

defproc AddRecordKeys
   universal recordingstate
   universal curkey
   parse value( curkey) with KeyString \1 Cmd
   Cmd = strip( Cmd)
   -- If key recording is active, add curkey to recordkeys array var
   if wordpos( upcase( Cmd), 'RECORDKEYS PLAYBACKKEYS') = 0 then
      if recordingstate = 'R' then
         Rest = GetAVar( 'recordkeys')
         SetAVar( 'recordkeys', Rest''\0''curkey)
      endif
   endif

defc RecordKeys
   universal recordingstate
   if recordingstate = 'R' then
      recordingstate = 'P'
      'SayHint' REMEMBERED__MSG
   else
      recordingstate = 'R'
      SetAVar( 'recordkeys', '')
      --'SayHint' CTRL_R__MSG
      RecordKeysKeyString = strip( MenuAccelString( 'RecordKeys'), 'L', \9)
      PlaybackKeysKeyString = strip( MenuAccelString( 'PlaybackKeys'), 'L', \9)
      'SayHint Remembering keys.  'RecordKeysKeyString' to finish, 'PlaybackKeysKeyString' to finish and try, Esc to cancel.'
   endif

defc CancelRecordKeys
   universal recordingstate
   recordingstate = ''
   'SayHint Key recording canceled.'

defc PlaybackKeys
   universal recordingstate
   Rest = GetAVar( 'recordkeys')
   if recordingstate = 'R' then
      recordingstate = 'P'
      'SayHint' REMEMBERED__MSG
   endif
   if recordingstate <> 'P' or Rest = '' then
      return
   endif

   call NextCmdAltersText()
   Rest = Rest''\0
   do while Rest <> ''
      parse value( Rest) with \0 KeyDef \0 Rest
      parse value( KeyDef) with Key \1 Cmd
      Rest = \0''Rest
      -- Execute either accel or standard (other) key
      if Cmd <> '' then
         ''Cmd
      else
         keyin Key
      endif
      if Rest = \0 then
         leave
      endif
   enddo

; ---------------------------------------------------------------------------
defc TypeTab
   keyin \9

defc DeleteChar
   universal stream_mode
   universal cua_marking_switch
   if marktype() & cua_marking_switch then    -- If there's a mark, then
      if process_mark_like_cua() then
         return
      endif
   endif
   call NextCmdAltersText()
   if .line then
      l = length( textline( .line))
   else
      l = .col    -- make the following IF fail
   endif
   if .col > l & stream_mode then
      join
      .col = l + 1
   else
      old_level = .levelofattributesupport
      if old_level & not (old_level bitand 2) then
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = 0
      endif
      delete_char
      .levelofattributesupport = old_level
   endif

defc Down
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
;      'CenterLine'
      'ScrollDown'
   else
compile endif
      call updownkey(1)
compile if RESPECT_SCROLL_LOCK
   endif
compile endif

defc MarkDown
   universal cua_marking_switch
   startline = .line; startcol = .col
   call updownkey(1)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if cua_marking_switch then
;compile endif
   if startline then
      call extend_mark( startline, startcol, 1)
   endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif

defc EndLine
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   end_line
   --call pEnd_Line()  -- like end_line, but ignore trailing blanks

defc EndLineOrAfter
   universal cua_marking_switch
   universal endkeystartpos
   if cua_marking_switch then
      unmark
   endif
   parse value( endkeystartpos) with savedline savedcol
   startline = .line
   startcol  = .col
   end_line
   --call pEnd_Line()  -- like end_line, but ignore trailing blanks
   if savedline <> startline or startcol > .col then
      endkeystartpos = startline startcol
   else
      if startcol = .col and savedcol > .col then
         .col = savedcol
      endif
   endif

defc MarkEndLine
   startline = .line
   startcol  = .col
   end_line
   --call pEnd_Line()  -- like end_line, but ignore trailing blanks
   call extend_mark( startline, startcol, 1)

defc MarkEndLineOrAfter
   universal endkeystartpos
   parse value( endkeystartpos) with savedline savedcol
   startline = .line
   startcol  = .col
   end_line
   --call pEnd_Line()  -- like end_line, but ignore trailing blanks
   if savedline <> startline or startcol > .col then
      endkeystartpos = startline startcol
   else
      if startcol = .col and savedcol > .col then
         .col = savedcol
      endif
   endif
   call extend_mark( startline, startcol, 1)

defc ProcessEscape
   universal ESCAPE_KEY
   universal alt_R_active
   universal recordingstate
   sayerror 0
   if recordingstate = 'R' then
      'CancelRecordKeys'
   elseif alt_R_active <> '' then
       'setmessageline '\0
      'toggleframe 2 'alt_R_active         -- Restore status of messageline.
      alt_R_active = ''
   elseif ESCAPE_KEY then
      'commandline'
   endif

defc SaveOrSaveAs
   if .modify then           -- Modified since last Save?
      'Save'                 --   Yes - save it
   else
;      'commandline Save '
      sayerror 'No changes.  Press Enter to Save anyway.'
      'saveas_dlg 0'  -- better show file selector
                      -- new optional arg, 0 => no EXIST_OVERLAY__MSG
   endif

defc SmartSave
   if .modify then           -- Modified since last Save?
      'Save'                 --   Yes - save it
   else
      sayerror 'No changes.'
   endif

defc FileOrQuit
compile if SMARTFILE
   if .modify then           -- Modified since last Save?
      'File'                 --   Yes - save it and quit.
   else
      'Quit'                 --   No - just quit.
   endif
compile else
   'File'
compile endif

defc EditFileDlg
   universal ring_enabled
   if not ring_enabled then
      sayerror NO_RING__MSG
      return
   endif
   'OpenDlg EDIT'

defc UndoLine
   call NextCmdAltersText()
   undo

defc NextFile
   nextfile

defc BeginLine  -- standard Home
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   begin_line

defc BeginLineOrText  -- Home
   universal nepmd_hini
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   -- Go to begin of text.
   -- If in area before or at begin of text, go to column 1.
   startline = .line; startcol = .col
   call pfirst_nonblank()
   if .line = startline and .col = startcol then
      begin_line
   endif

defc MarkBeginLine  -- standard Sh+Home
   startline = .line
   startcol  = .col
   begin_line
   call extend_mark( startline, startcol, 0)

defc MarkBeginLineOrText  -- Sh+Home
   universal nepmd_hini
   startline = .line
   startcol  = .col
   -- Go to begin of text.
   -- If in area before or at begin of text, go to column 1.
   startline = .line; startcol = .col
   call pfirst_nonblank()
   if .line = startline and .col = startcol then
      begin_line
   endif
   call extend_mark( startline, startcol, 0)

defc InsertToggle
   insert_toggle
   call fixup_cursor()

defc PrevChar, Left
   universal cua_marking_switch
   universal cursoreverywhere
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      'ScrollLeft'
   else
compile endif
*/
      if .line > 1 & .col = 1 then
         up
         end_line
      else
         left
      endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
*/
   if cua_marking_switch then
      unmark
   endif

defc MarkPrevChar, MarkLeft
   startline = .line; startcol = .col
   if .line > 1 & .col = 1 then
      up
      end_line
   else
      left
   endif
   call extend_mark( startline, startcol, 0)

defc PrevPage, PageUp
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   page_up

defc NextPage, PageDown
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   page_down

defc MarkPageUp
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   startline = .line; startcol = .col
   page_up
   if .line then
      call extend_mark( startline, startcol, 0)
   endif
compile if TOP_OF_FILE_VALID = 'STREAM'
   if not .line & stream_mode then
      '+1'
   endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then
      '+1'
   endif
compile endif

defc MarkPageDown
   startline = .line; startcol = .col
   page_down
   if startline then
      call extend_mark( startline, startcol, 1)
   endif

defc NextChar, Right
   universal cursoreverywhere
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      'ScrollRight'
   else
compile endif
*/
      if .line then
         l = length( textline(.line))
      else
         l = .col
      endif
      if (.line < .last) & (.col > l) & not cursoreverywhere then
         down
         begin_line
      elseif (.line = .last) & (.col > l) & not cursoreverywhere then
         -- nop
      else
         right
      endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
*/

defc MarkNextChar, MarkRight
   startline = .line; startcol = .col
   if .line then
      l = length( textline(.line))
   else
      l = .col
   endif
   if .line < .last & .col > l then
      down
      begin_line
   elseif .line <> .last | .col <= l then
      right
   endif
   call extend_mark( startline, startcol, 1)

defc ScrollLeft
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   oldcursorx = .cursorx
   if .col - .cursorx then
      .col = .col - .cursorx
      .cursorx = oldcursorx
   elseif .cursorx > 1 then
      left
   endif

defc ScrollRight
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   oldcursorx=.cursorx
   a = .col + .windowwidth - .cursorx + 1
   if a <= MAXCOL then
      .col = a
      .cursorx = oldcursorx
   elseif .col < MAXCOL then
      right
   endif

defc ScrollUp
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   oldcursory = .cursory
   if .line - .cursory > -1 then
      .cursory = 1
      up
      .cursory = oldcursory
   elseif .line then
      up
   endif

defc ScrollDown
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   oldcursory = .cursory
   if .line - .cursory + .windowheight < .last then
      .cursory = .windowheight
      down
      .cursory = oldcursory
   elseif .line < .last then
      down
   endif

defc CenterLine
   universal cua_marking_switch
   call NextCmdAltersText()
   if cua_marking_switch then
      unmark
   endif
   oldline = .line
   .cursory = .windowheight%2
   oldline

defc BackTab
   universal matchtab_on
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
   if matchtab_on & .line > 1 then
      up
      backtab_word
      down
   else
      backtab
   endif

defc Tab
   universal stream_mode
   universal matchtab_on
   universal tab_key
   universal cua_marking_switch
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
                  -------Start of logic:
   call NextCmdAltersText()
   if tab_key then
      if cua_marking_switch then
          process_key(\9)
      else
         keyin \9
      endif  -- cua_marking_switch
   else  -- tab_key
      if cua_marking_switch then
         unmark
      endif  -- cua_marking_switch
      oldcol=.col
      if matchtab_on and .line>1 then
         up
;;       c=.col  -- Unused ???
         tab_word
         if oldcol >= .col then
            .col = oldcol
            tab
         endif
         down
      else
         tab
      endif
compile if not WANT_TAB_INSERTION_TO_SPACE
      if insertstate() & stream_mode then
compile else
      if insertstate() then
compile endif
         numspc = .col - oldcol
compile if WANT_DBCS_SUPPORT
         if ondbcs then                                       -- If we're on DBCS,
            if not (matchtab_on and .line > 1) then           -- and didn't do a matchtab,
               if words( .tabs) > 1 then
                  if not wordpos( .col, .tabs) then           -- check if on a tab col.
                     do i = 1 to words( .tabs)                -- If we got shifted due to being inside a DBC,
                        if word( .tabs, i) > oldcol then      -- find the col we *should* be in, and
                           numspc = word( .tabs, i) - oldcol  -- set numspc according to that.
                           leave
                        endif
                     enddo
                  endif
               elseif (.col // .tabs) <> 1 then
                  numspc = .tabs - (oldcol + .tabs - 1) // .tabs
               endif
            endif
         endif  -- ondbcs
compile endif  -- WANT_DBCS_SUPPORT
         if numspc > 0 then
            .col = oldcol
            keyin substr( '', 1, numspc)
         endif
      endif  -- insertstate()
   endif  -- tab_key

defc PrevLine, Up
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   universal cua_marking_switch
   if cua_marking_switch then
      unmark
   endif
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
;      'CenterLine'
      'ScrollUp'
   else
compile endif
      call updownkey(0)
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
compile if TOP_OF_FILE_VALID = 'STREAM'
   if not .line & stream_mode then
      '+1'
   endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then
      '+1'
   endif
compile endif

defc MarkUp
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   universal cua_marking_switch
   startline = .line; startcol = .col
   call updownkey(0)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if cua_marking_switch then
;compile endif
   if .line then
      call extend_mark( startline, startcol, 0)
   endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif
compile if TOP_OF_FILE_VALID = 'STREAM'
   if not .line & stream_mode then
      '+1'
   endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then
      '+1'
   endif
compile endif

defc DefaultPaste
   universal nepmd_hini
   universal cua_marking_switch
   call NextCmdAltersText()
   KeyPath = '\NEPMD\User\Mark\DefaultPaste'
   next = substr( upcase( NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then
      style = 'L'
   elseif next = 'B' then
      style = 'B'
   else
      style = 'C'
   endif
   if cua_marking_switch then
      call process_mark_like_cua()
   endif
   'paste' style

defc AlternatePaste
   universal nepmd_hini
   universal cua_marking_switch
   call NextCmdAltersText()
   KeyPath = '\NEPMD\User\Mark\DefaultPaste'
   next = substr( upcase( NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then
      altstyle = 'C'
   elseif next = 'B' then
      altstyle = 'C'
   else
      altstyle = 'L'
   endif
   if cua_marking_switch then
      call process_mark_like_cua()
   endif
   'paste' altstyle

; Insert the char from the line above at cursor position.
; May get executed repeatedly to copy an entire expression without
; cluttering the undo list at every single execution.
; From Luc van Bogaert.
defc InsertCharAbove
   if .line > 1 then
      -- suppress autosave and undo (for during repeated use)
      saved_autosave = .autosave
      .autosave = 0
      call NextCmdAltersText()

      -- force overwrite mode
      i_s = insert_state()
      if i_s then
         insert_toggle  -- Turn off insert mode
      endif

      line = textline( .line - 1)  -- line above
      char = substr( line, .col, 1)
      keyin char

      if i_s then
         insert_toggle
      endif

      .autosave = saved_autosave
   endif

; Insert the char from the line below at cursor position.
; May get executed repeatedly to copy an entire expression without
; cluttering the undo list at every single execution.
; From Luc van Bogaert.
defc InsertCharBelow
   if .line < .last then
      -- suppress autosave and undo (for during repeated use)
      saved_autosave = .autosave
      .autosave = 0
      call NextCmdAltersText()

      -- force overwrite mode
      i_s = insert_state()
      if i_s then
         insert_toggle  -- Turn off insert mode
      endif

      line = textline( .line + 1)  -- line below
      char = substr( line, .col, 1)
      keyin char

      if i_s then
         insert_toggle
      endif

      .autosave = saved_autosave
   endif

; Add a new line before the current, move to it, keep col.
defc NewLineBefore
   call NextCmdAltersText()
   insertline ''
   up

; Add a new line after the current, move to it, keep col.
defc NewLineAfter
   call NextCmdAltersText()
   insertline '', .line + 1
   down

; Define a_1, because alt_1 is only defined since ALT_1.E is redefined.
defc a_1
   'alt_1'

