/****************************** Module Header *******************************
*
* Module Name: keys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: keys.e,v 1.28 2009-02-16 21:56:45 aschn Exp $
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
   stop

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
defc ProcessOtherKeys
   pk = lastkey(1)  -- previous key
   k  = lastkey()   -- current key
   call process_key(k)
   if k <> pk then
      call EnableUndoRec()
   endif

; ---------------------------------------------------------------------------
defselect
   call EnableUndoRec()

; ---------------------------------------------------------------------------
; defines can be changed/extended (but iterations aren't possible).
; This should be moved to STDCNF.E or STDCONST.E to make it overwritable
; in user's MYCNF.E.
define
   -- LETTER_LIST = keys, for those no <key> and no Sh+<key> should be
   -- defined, handle Capslock
compile if not defined(LETTER_LIST)
   -- Keep the amount of letters in both lists equal!
   UPPERCASE_LETTER_LIST = 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z'
   LOWERCASE_LETTER_LIST = 'a b c d e f g h i j k l m n o p q r s t u v w x y z'
compile endif

   -- CHAR_LIST = keys, for those no <key> and no Sh+<key> should be defined
compile if not defined(CharList)
   CHAR_LIST  = '0 1 2 3 4 5 6 7 8 9 /     \         =     -     +    *'
   CHAR_NAMES = '0 1 2 3 4 5 6 7 8 9 SLASH BACKSLASH EQUAL MINUS PLUS ASTERISK'
   CHAR_LIST  = CHAR_LIST  || ' <    >'
   CHAR_NAMES = CHAR_NAMES || ' LESS GREATER'
compile endif
   -- NO_DEF_CHAR_LIST = no key defs via def a_<name> and def c_<name> for
   -- Alt+<name> and Ctrl+<name> exist
compile if not defined(NO_DEF_CHAR_LIST)
   NO_DEF_CHAR_LIST = '* + < > ( ) [ ] # , . ! ? " ^ % $ & ï ` ' ' ~ | @'
compile endif

   -- VIRTUAL_LIST = virtual keys, for those every combination should be
   -- defined, see pmwin.h.
   -- ENTER means NEWLINE in PM and PADENTER means ENTER in PM.
compile if not defined(VIRTUAL_LIST)
   VIRTUAL_LIST  = 'BACKSPACE TAB ENTER ESC PAGEUP PAGEDOWN END HOME'
   VIRTUAL_IDS   = '5         6   8     15  17     18       19  20'
   VIRTUAL_NAMES = 'BACKSPACE TAB ENTER ESC PGUP   PGDN     END HOME'
   VIRTUAL_LIST  = VIRTUAL_LIST  || ' LEFT UP RIGHT DOWN INSERT DELETE PADENTER'
   VIRTUAL_IDS   = VIRTUAL_IDS   || ' 21   22 23    24   26     27     30'
   VIRTUAL_NAMES = VIRTUAL_NAMES || ' LEFT UP RIGHT DOWN INS    DEL    PADENTER'
   VIRTUAL_LIST  = VIRTUAL_LIST  || ' F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12'
   VIRTUAL_IDS   = VIRTUAL_IDS   || ' 32 33 34 35 36 37 38 39 40 41  42  43'
   VIRTUAL_NAMES = VIRTUAL_NAMES || ' F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12'
   -- more: SPACE, ENTER, PADENTER
compile endif

   -- PM_LIST    = don't override <key>, because they are standard PM keys
compile if not defined(PM_LIST)
   -- Tab must be excluded, because otherwise lastkey(2) and lastkey(3) would
   -- return wrong values for Tab. lastkey() for Tab doesn't work in EPM!
   -- Remove a key from this list if you want to override that anyway.
   PM_LIST       = 'F1 F10 TAB'
compile endif

   -- PM_ALT_LIST = don't override Alt+<key>, because they are standard PM keys
   -- Alt+Home is also disabled to keep Alt+Numpad7 working.
   -- Same for: Alt+Up, Alt+Down, Alt+Left, Alt+Right, Alt+End, Alt+PgUp,
   -- Alt+PgDown, Alt+Ins
   -- Remove a key from this list if you want to override that anyway.
compile if not defined(PM_ALT_LIST)
   PM_ALT_LIST    = 'SPACE TAB ESC F4 F5 F6 F7 F8 F9 F10 F11'
   PM_ALT_LIST    = PM_ALT_LIST || ' HOME UP DOWN LEFT RIGHT'
   PM_ALT_LIST    = PM_ALT_LIST || ' END PAGEUP PAGEDOWN INSERT'
compile endif

/*
   view pm5.inf "Virtual Key Definitions"
   o f:\dev\toolkt45\h\pmwin.h 'mc ;xcom l /Virtual key values/t ;postme centerline'
*/
/*
-- Test
defc Key_c_a_A = 'sayerror c_a_A'
defc Key_c_a_s_A = 'sayerror c_a_s_A'

defc Key_c_b = 'sayerror c_b'
defc Key_c_s_b = 'sayerror c_s_b'
defc Key_a_b = 'sayerror a_b'
defc Key_a_s_b = 'sayerror a_s_b'
defc Key_c_a_b = 'sayerror c_a_b'
defc Key_c_a_s_b = 'sayerror c_a_s_b'

defc Key_c_plus = 'sayerror c_+'
defc Key_c_s_plus = 'sayerror c_s_+'
defc Key_a_plus = 'sayerror a_+'
defc Key_a_s_plus = 'sayerror a_s_+'
defc Key_c_a_plus = 'sayerror c_a_+'
defc Key_c_a_s_plus = 'sayerror c_a_s_+'

defc Key_c_end = 'sayerror c_end'
defc Key_c_s_end = 'sayerror c_s_end'
defc Key_a_end = 'sayerror a_end'
defc Key_a_s_end = 'sayerror a_s_end'
defc Key_c_a_end = 'sayerror c_a_end'
defc Key_c_a_s_end = 'sayerror c_a_s_end'

defc Key_a_tab = 'sayerror a_tab'  -- not definable
defc Key_a_esc = 'sayerror a_esc'  -- not definable
defc Key_a_f10 = 'sayerror a_f10'
*/

; ---------------------------------------------------------------------------
; Define accel key for current accel table
defproc DefAccelKey( Cmd, Flags, Key)
   universal activeaccel
   universal lastkeyaccelid

   lastkeyaccelid = lastkeyaccelid + 1
   buildacceltable activeaccel, Cmd, Flags, Key, lastkeyaccelid

   return

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E.
; Defined menu accels have priority to definitions provided by a keyset
; or by the automatically assigned defs by the PM menu. Therefore they are
; used here to recreate the keyset definition with the dokey command.
; Now there are all possible key combinations with Ctrl, Alt and Sh
; definable. If a defc Key_* exists, then this definition will be preferred
; to a def *.
; First it should be tried, if a specific key is definable via def. This can
; be checked easily, because allowed defs are highlighted. A def definition
; def <prefix><key> will also define the shifted variant, that can be
; overwritten with a defc Key_<prefix>s_<key> definition.
;
; Syntax for defc Key_* (order for prefixes is c_a_s_):
;    Key_<key>
;    Key_s_<key>
;    Key_c_<key>
;    Key_c_s_<key>
;    Key_a_<key>
;    Key_a_s_<key>
;    Key_c_a_<key>
;    Key_c_a_s_<key>
; <key> may be any letter (see const LETTER_LIST), any char name (see const
; CHAR_NAMES) or any virtual key (see const VIRTUAL_NAMES).

defc loadaccel
   universal activeaccel
   universal nepmd_hini
   universal cua_menu_accel
   universal lastkeyaccelid

   activeaccel = 'defaccel'  -- name for accelerator table
   lastkeyaccelid = 1000     -- let ids start at 1001

   call DefineLetterAccels()
   call DefineCharAccels()
   call DefineVirtualAccels()

   -- Don't want Alt or AltGr switch to menu (PM-defined key F10 does the same)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   fBlocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if fBlocked = 1 then
      DefAccelKey( '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALT)      -- Alt
   endif
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   fBlocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if fBlocked = 1 then
      DefAccelKey( '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALTGRAF)  -- AltGr
   endif

   activateacceltable activeaccel
   return

; ---------------------------------------------------------------------------
; Letters. Upper- and lowercase codes must be defined to make a keybinding
; work, even when Capslock is active.
; The uppercase variant is defined the same as the lowercase, if no
; defc Key_*s_<key> exists. The uppercase unshifted variant is required for
; the case when capsloack is active. The lowercase shifted variant is not
; required, because Sh will deactivate capslock.
defproc DefineLetterAccels
   universal activeaccel
   universal cua_menu_accel

   UsedMenuAccelerators = GetAVar('usedmenuaccelerators')
   List = UPPERCASE_LETTER_LIST
   do w = 1 to words( List)
      char = word( UPPERCASE_LETTER_LIST, w)
      -- lowercase is not used here, because it would only work for Ascii letters
      ukey = asc(word( UPPERCASE_LETTER_LIST, w))
      lkey = asc(word( LOWERCASE_LETTER_LIST, w))
      name = char
      fOmitAltAccel = 0
      if cua_menu_accel then
         if wordpos( char, upcase(UsedMenuAccelerators)) then
            fOmitAltAccel = 1
         endif
      endif

      if isadefc('Key_c_'name) then
         Cmd = 'Key_c_'name
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL, lkey)  -- Ctrl+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL, ukey)  -- Ctrl+<key> (uppercase)
      endif

      if isadefc('Key_c_s_'name) then
         Cmd = 'Key_c_s_'name
         --DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, lkey)  -- Ctrl+Sh+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, ukey)  -- Ctrl+Sh+<key> (uppercase)
      endif

      Cmd = ''
      if isadefc('Key_a_'name) then
         Cmd = 'Key_a_'name
      elseif not fOmitAltAccel then  -- if not (cua_meu_accel and found in UsedMenuAccelerators)
         -- This overrides the standard PM def to open the menu
         Cmd = 'dokey a+'name
      endif
      if Cmd <> '' then
         DefAccelKey( Cmd, AF_CHAR + AF_ALT, lkey)  -- Alt+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_ALT, ukey)  -- Alt+<key> (uppercase)
      endif

      if isadefc('Key_a_s_'name) then
         Cmd = 'Key_a_s_'name
         --DefAccelKey( Cmd, AF_CHAR + AF_ALT + AF_SHIFT, lkey)  -- Alt+Sh+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_ALT + AF_SHIFT, ukey)  -- Alt+Sh+<key> (uppercase)
      endif

      if isadefc('Key_c_a_'name) then
         Cmd = 'Key_c_a_'name
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT, lkey)  -- Ctrl+Alt+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT, ukey)  -- Ctrl+Alt+<key> (uppercase)
      endif

      if isadefc('Key_c_a_s_'name) then
         Cmd = 'Key_c_a_s_'name
         --DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, lkey)  -- Ctrl+Alt+Sh+<key> (lowercase)
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, ukey)  -- Ctrl+Alt+Sh+<key> (uppercase)
      endif

   enddo

   return

; ---------------------------------------------------------------------------
; Chars, for that no upper/lowercase variants exist.
defproc DefineCharAccels
   universal activeaccel

   List = CHAR_LIST
   do w = 1 to words( List)
      char = word( List, w)
      key  = asc(char)
      name = word( CHAR_NAMES, w)
      fDefExists = (wordpos( char, NO_DEF_CHAR_LIST) = 0)

      Cmd = ''
      if isadefc('Key_c_'name) then
         Cmd = 'Key_c_'name
      elseif fDefExists then
         if not IsNum( name) then  -- Exclude Ctrl+0 ... Ctrl+9 to make Ctrl+<keypad-num> work properly.
                                   -- These keys are definable via def c_0 ... def c_9.
                                   -- To override a standard PM def, e.g. Ctrl+Pad-0 = copy to clip,
                                   -- one can use defc Key_c_0 instead of def c_0.
            Cmd = 'dokey c+'name
         endif
      endif
      if Cmd <> '' then
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL, key)                      -- Ctrl+<key>
      endif

      if isadefc('Key_c_s_'name) then
         Cmd = 'Key_c_s_'name
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, key)           -- Ctrl+Sh+<key>
      endif

      Cmd = ''
      if isadefc('Key_a_'name) then
         Cmd = 'Key_a_'name
      elseif fDefExists then
         if not IsNum( name) then  -- Exclude Ctrl+0 ... Ctrl+9 to make Ctrl+<keypad-num> work properly.
                                   -- These keys are definable via def c_0 ... def c_9.
                                   -- To override a standard PM def, e.g. Ctrl+Pad-0 = copy to clip,
                                   -- one can use defc Key_c_0 instead of def c_0.
            Cmd = 'dokey a+'name
         endif
      endif
      if Cmd <> '' then
         DefAccelKey( Cmd, AF_CHAR + AF_ALT, key)                          -- Alt+<key>
      endif

      if isadefc('Key_a_s_'name) then
         Cmd = 'Key_a_s_'name
         DefAccelKey( Cmd, AF_CHAR + AF_ALT + AF_SHIFT, key)               -- Alt+Sh+<key>
      endif

      if isadefc('Key_c_a_'name) then
         Cmd = 'Key_c_a_'name
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT, key)             -- Ctrl+Alt+<key>
      endif

      if isadefc('Key_c_a_s_'name) then
         Cmd = 'Key_c_a_s_'name
         DefAccelKey( Cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, key)  -- Ctrl+Alt+Sh+<key>
      endif

   enddo

   return

; ---------------------------------------------------------------------------
; Virtual keys like F1, Insert, Up.
defproc DefineVirtualAccels
   universal activeaccel

   List = VIRTUAL_LIST
   do w = 1 to words( List)
      char = word( List, w)
      id   = word( VIRTUAL_IDS, w)
      name = word( VIRTUAL_NAMES, w)

      if not wordpos( char, PM_LIST) then
         if isadefc('Key_'name) then
            Cmd = 'Key_'name
            DefAccelKey( Cmd, AF_VIRTUALKEY, id)                                -- <key>
         endif
      endif

      if isadefc('Key_s_'name) then
         Cmd = 'Key_s_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_SHIFT, id)                        -- Sh+<key>
      endif

      if isadefc('Key_c_'name) then
         Cmd = 'Key_c_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_CONTROL, id)                      -- Ctrl+<key>
      endif

      if isadefc('Key_c_s_'name) then
         Cmd = 'Key_c_s_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_CONTROL + AF_SHIFT, id)           -- Ctrl+Sh+<key>
      endif

      if not wordpos( char, PM_ALT_LIST) then
         if isadefc('Key_a_'name) then
            Cmd = 'Key_a_'name
            DefAccelKey( Cmd, AF_VIRTUALKEY + AF_ALT, id)                       -- Alt+<key>
         endif
      endif

      if isadefc('Key_a_s_'name) then
         Cmd = 'Key_a_s_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_ALT + AF_SHIFT, id)               -- Alt+Sh+<key>
      endif

      if isadefc('Key_c_a_'name) then
         Cmd = 'Key_c_a_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_CONTROL + AF_ALT, id)             -- Ctrl+Alt+<key>
      endif

      if isadefc('Key_c_a_s_'name) then
         CMD = 'Key_c_a_s_'name
         DefAccelKey( Cmd, AF_VIRTUALKEY + AF_CONTROL + AF_ALT + AF_SHIFT, id)  -- Ctrl+Alt+Sh+<key>
      endif

   enddo

   return

; ---------------------------------------------------------------------------
defc deleteaccel
   universal activeaccel
   if arg(1) = '' then
      curaccel = activeaccel
   else
      curaccel = arg(1)
   endif
   deleteaccel curaccel

; ---------------------------------------------------------------------------
defc dokey
   --sayerror 'dokey: k = 'arg(1)
   executekey resolve_key(arg(1))

; ---------------------------------------------------------------------------
defc executekey
   executekey arg(1)

; ---------------------------------------------------------------------------
defc keyin
   keyin arg(1)

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
defproc resolve_key(k)
   ku = upcase(k)

   -- Get prefix
   fC_Prefix = 0
   fA_Prefix = 0
   fS_Prefix = 0
   done = 0
   rest = ku
   do while (done = 0 & length(ku) > 2)
      p = pos( leftstr( ku, 1), 'CAS')
      if p & pos( substr( ku, 2, 1), '_-+') then
         ku = substr( ku, 3)
         if p = 1 then
            fC_Prefix = 1
         elseif p = 2 then
            fA_Prefix = 1
         elseif p = 3 then
            fS_Prefix = 1
         endif
      else
         done = 1
      endif
   enddo
   suffix = ''

   wv = wordpos( ku, VIRTUAL_NAMES)
   wc = wordpos( ku, CHAR_NAMES)
   --dprintf( 'resolve_key', 'k = 'k', ku = 'ku', Ctrl = 'fC_Prefix', Alt = 'fA_Prefix', Sh = 'fS_Prefix', Virtual = 'wv', Char = 'wc)
   if wv then
      if fC_Prefix then
         suffix = \18
      elseif fA_Prefix then
         suffix = \34
      elseif fS_Prefix then
         suffix = \10
      else
         suffix = \2
      endif
      k = chr(word( VIRTUAL_IDS, wv))''suffix
   elseif wc then
      if fC_Prefix then
         suffix = \16
         k = word( CHAR_LIST, wc)''suffix
      elseif fA_Prefix then
         suffix = \32
         k = word( CHAR_LIST, wc)''suffix
      endif
   else
      if fC_Prefix then
         suffix = \16
         k = lowcase(ku)''suffix  -- letters must be lowercase for executekey
      elseif fA_Prefix then
         suffix = \32
         k = lowcase(ku)''suffix  -- letters must be lowercase for executekey
      endif
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
   DefaultNameList = lowcase( 'mozkeys')  -- only basenames

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

   KeyPath = '\NEPMD\User\Keys\AddKeyDefs\Selected'
   Current = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Current <> None & Current <> '' then
      'Link quiet 'Current
      do i = 1 to 1
         -- On success
         if rc >= 0 then
            leave
         endif
         -- Search .E file and maybe recompile it
         'Relink' Current'.e'
         if rc >= 0 then
            leave
         endif
         -- Remove from NEPMD.INI on link error
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath, None)
         sayerror 'Additional key defs file "'Current'.ex" could not be found.'
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
         'mc ;RecompileNew;postme SelectKeyDefs'
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
            rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath2, None)
         endif
      endif
      if Selected = None then
         Msg = 'No keyset additions file active.'
         sayerror Msg
         -- nop
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
         -- Restart
         Msg = 'Keyset additions file 'upcase( Selected)'.EX activated.'
         'Restart sayerror' Msg
      endif
   elseif button = 2 then  -- Add
      -- Open fileselector to select an e or ex filename
      -- Call this Cmd again, but with args to repaint the list
      'FileDlg Select a file with additional key definitions, SelectKeyDefs ADD, 'Get_Env('NEPMD_USERDIR')'\macros\*.e'
      -- Call this Cmd again
;      'SelectKeyDefs'
      return 0
   elseif button = 3 & Selected <> None then  -- Edit
      -- Load file
      'ep 'Selected'.e'
      return rc
   elseif button = 4 & Selected <> None then  -- Remove
      if linked( Selected) > 0 then
         'unlink 'Selected
         rcx = NepmdWriteConfigValue( nepmd_hini, KeyPath2, None)
      endif
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
;compile if WANT_DM_BUFFER
         'Copy2DMBuff'     -- see clipbrd.e for details
;compile endif  -- WANT_DM_BUFFER
         firstline
         .col = firstcol
         call NewUndoRec()
         call pdelete_mark()
         'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
         return 1
      endif
   endif

; ---------------------------------------------------------------------------
defproc shifted
   ks = getkeystate(VK_SHIFT)
   return ks <> 3 & ks <> 4

; ---------------------------------------------------------------------------
defproc updownkey( down_flag)
   universal save_cursor_column
   universal cursoreverywhere
   if not cursoreverywhere then
      lk = lastkey(1)
      updn = pos( leftstr( lk, 1), \x18\x16) & pos( substr( lk, 2, 1), \x02\x0A\x12)   -- VK_DOWN or VK_UP, plain or Shift or Ctrl
      if not updn then
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
      if updn & l >= save_cursor_column then
         .col = save_cursor_column
      elseif updn | l < .col then
         end_line
      endif
   endif

; ---------------------------------------------------------------------------
define CHARG_MARK = 'CHARG'

defproc extend_mark( startline, startcol, forward)
   universal cua_marking_switch
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Mark\ShiftMarkExtends'
   on = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   getfileid curfileid
   getmarkg firstline, lastline, firstcol, lastcol, markfileid
   if markfileid <> curfileid then
      unmark
   elseif cua_marking_switch then
      -- keep mark and extend it (any unshifted key caused unmark before)
   elseif on then
      -- keep mark and extend it
   else
      if (startline = firstline & startcol = firstcol) |
         (startline = lastline & startcol = lastcol) then
         -- keep mark if cursor was at start or end of mark
      else
         unmark
      endif
   endif

   if not marktype() then
      call pset_mark( startline, .line, startcol, .col, CHARG_MARK, curfileid)
      return
   endif
   lk = lastkey(0)
   if (lk = s_up & .line = firstline - 1) | (lk = s_down & .line = firstline + 1) then
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
   shift_flag = shifted()
   if shift_flag or not cua_marking_switch then
      startline = .line; startcol = .col
   else
      unmark
   endif

; ---------------------------------------------------------------------------
defproc end_shift( startline, startcol, shift_flag, forward_flag)
; Let's let this work regardless of which marking mode is active.
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
; Example: def c_enter 'ExpandSecond C_Enter'
defc ExpandSecond
   call ExpandFirstSecond( 1, arg(1))

; ---------------------------------------------------------------------------
; Process syntax expansion, if defined and if success, otherwise execute
; StdDef.
defproc ExpandFirstSecond( fSecond, StdDef)
   universal expand_on
   fExpanded = 0
   if expand_on then
      Keyset = .keyset
      parse value upcase( Keyset) with Keyset'_KEYS'  -- strip "_KEYS" from keyset name
      if fSecond then
         ExpandCmd = Keyset'SecondExpansion'
      else
         ExpandCmd = Keyset'FirstExpansion'
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
defc space
   universal cua_marking_switch
   if cua_marking_switch then
      call process_mark_like_cua()
   endif
   pk = lastkey(1)
   if pk = ' ' then
      call DisableUndoRec()
   endif
   keyin ' '
   if pk <> ' ' then
      call NewUndoRec()
   endif

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
   call NewUndoRec()
   call pcommon_adjust_overlay('A')
   call NewUndoRec()

defc OverlayMark
   call NewUndoRec()
   if marktype() then
      call pcommon_adjust_overlay('O')
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff O'   /* see clipbrd.e for details                 */
   endif
   call NewUndoRec()

defc CopyMark
   call NewUndoRec()
   if marktype() then
      call pcopy_mark()
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff'     /* see clipbrd.e for details                 */
   endif
   call NewUndoRec()

defc MoveMark
   universal nepmd_hini
   call NewUndoRec()
   call pmove_mark()
   KeyPath = '\NEPMD\User\Mark\UnmarkAfterMove'
   UnmarkAfterMove = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if UnmarkAfterMove = 1 then
      unmark
      'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   endif
   call NewUndoRec()

defc DeleteMark
   call NewUndoRec()
;compile if WANT_DM_BUFFER
   'Copy2DMBuff'     -- see clipbrd.e for details
;compile endif
   call pdelete_mark()
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
   call NewUndoRec()

defc unmark
   call EnableUndoRec()
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */

defc BeginMark
   call EnableUndoRec()
   call pbegin_mark()

defc EndMark
   call EnableUndoRec()
   call pend_mark()
   if substr( marktype(), 1, 1) <> 'L' then
      right
   endif

defc FillMark /* Now accepts key from macro. */
   call NewUndoRec()
   call checkmark()
   call pfill_mark()
   call NewUndoRec()

defc TypeFrameChars
   call NewUndoRec()
   keyin 'º Ì É È Ê Í Ë ¼ » ¹ Î ³ Ã Ú À Á Ä Â Ù ¿ ´ Å Û ² ± °'
   call NewUndoRec()

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
   call DisableUndoRec()
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
   call DisableUndoRec()
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
   call NewUndoRec()
   call joinlines()
   call NewUndoRec()

defc MarkBlock
   call EnableUndoRec()
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
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

defc MarkLine
   call EnableUndoRec()
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
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

defc MarkChar
   call EnableUndoRec()
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
  keyin .filename

defc TypeDateTime  -- Type the current date and time
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
   saved_margins = .margins
   if arg(1) > '' then
      .margins = arg(1)
   endif
   call psave_mark(savemark)
   call psave_pos(savepos)
   call DisableUndoRec()
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
   call NewUndoRec()
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
   call DisableUndoRec()
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
   call NewUndoRec()
   if arg(1) > '' then
      .margins = saved_margins
   endif

; Standard text reflow, moved from Alt+P definition in STDKEYS.E.
; Only called from Alt+P if no mark exists; users wishing to call
; this from their own code must save & restore the mark themselves
; if that's desired.
defproc text_reflow
   universal nepmd_hini
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
   split

defc SplitLines
   call splitlines()

defc CenterMark
   call pcenter_mark()

defc BackSpace
   universal stream_mode
   universal cua_marking_switch
   if cua_marking_switch then
      if process_mark_like_cua() then
         return
      endif
   endif
   k  = lastkey()
   pk = lastkey(1)
   if pk <> k then
      call NewUndoRec()
   endif
   call DisableUndoRec()
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
   keyin \0                  -- C_2 enters a null.
defc TypeNot
   keyin \170                -- C_6 enters a "not" sign
defc TypeOpeningBrace
   keyin '{'
defc TypeClosingBrace
   keyin '}'
defc TypeCent
   keyin '›'                 -- C_4 enters a cents sign

defc DeleteLine
   call NewUndoRec()
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
   call NewUndoRec()

; Ctrl-D = word delete, thanks to Bill Brantley.
defc DeleteUntilNextword /* delete from cursor until beginning of next word, UNDOable */
   call EnableUndoRec()
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
   call NewUndoRec()
   erase_end_line  -- Ctrl-Del is the PM way.
   call NewUndoRec()

defc EndFile
   universal stream_mode
   call EnableUndoRec()
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

; Moved def c_enter, c_pad_enter= to ENTER.E
; Moved def c_f to LOCATE.E

; c_f1 is not definable in EPM.
defc UppercaseWord
   call EnableUndoRec()
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call puppercase()
   call prestore_mark(save_mark)

defc LowercaseWord
   call EnableUndoRec()
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call plowercase()
   call prestore_mark(save_mark)
   call prestore_pos(save_pos)

defc UppercaseMark
   call NewUndoRec()
   call puppercase()
   call NewUndoRec()

defc LowercaseMark
   call NewUndoRec()
   call plowercase()
   call NewUndoRec()

defc BeginWord
   call EnableUndoRec()
   call pbegin_word()

defc EndWord
   call EnableUndoRec()
   call pend_word()

defc BeginFile
   universal stream_mode
   call EnableUndoRec()
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
   call NewUndoRec()
   getline line
   insertline line,.line+1
   call NewUndoRec()

defc CommandDlgLine
   if .line then
      getline line
      'commandline 'line
   endif

defc PrevWord
   universal stream_mode
   call EnableUndoRec()
   call begin_shift( startline, startcol, shift_flag)
   if not .line then
      begin_line
   elseif (.line > 1) & (.col = max( 1,verify(textline(.line),' '))) & stream_mode then
      up
      end_line
   endif
   backtab_word
   call end_shift( startline, startcol, shift_flag, 0)

defc BeginScreen
   call EnableUndoRec()
   call begin_shift( startline, startcol, shift_flag)
   .cursory = 1
   call end_shift( startline, startcol, shift_flag, 0)

defc EndScreen
   call EnableUndoRec()
   call begin_shift( startline, startcol, shift_flag)
   .cursory = .windowheight
   call end_shift( startline, startcol, shift_flag, 1)

defc RecordKeys
   call NewUndoRec()
   -- Query to see if we are already in recording
   if windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),
                     5393,
                     0,
                     0)
   then
      call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                          5392,
                          0,
                          0)
      sayerror REMEMBERED__MSG
   else
      sayerror CTRL_R__MSG
      call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                          5390,
                          0,
                          0)
   endif

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


defc PlaybackKeys
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       5392,
                       0,
                       0)
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       5391,
                       0,
                       0)

defc TypeTab
   call DisableUndoRec()
   keyin \9

defc DeleteChar
   universal stream_mode
   universal cua_marking_switch
   if marktype() & cua_marking_switch then    -- If there's a mark, then
      if process_mark_like_cua() then
         return
      endif
   endif
   call DisableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
   if cua_marking_switch then
      unmark
   endif
   end_line

defc MarkEndLine
   call EnableUndoRec()
   startline = .line; startcol = .col
   end_line
   call extend_mark( startline, startcol, 1)

defc ProcessEscape
   universal ESCAPE_KEY
   universal alt_R_active
   sayerror 0
   if alt_R_active <> '' then
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
   'OPENDLG EDIT'

defc UndoLine
   undo

defc NextFile
   nextfile

defc BeginLine  -- standard Home
   universal cua_marking_switch
   call EnableUndoRec()
   if cua_marking_switch then
      unmark
   endif
   begin_line

defc BeginLineOrText  -- Home
   universal nepmd_hini
   universal cua_marking_switch
   call EnableUndoRec()
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
   call EnableUndoRec()
   startline = .line
   startcol  = .col
   begin_line
   call extend_mark( startline, startcol, 0)

defc MarkBeginLineOrText  -- Sh+Home
   universal nepmd_hini
   call EnableUndoRec()
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

defc PrevChar
   universal cua_marking_switch
   universal cursoreverywhere
   call EnableUndoRec()
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      'ScrollLeft'
   else
compile endif
*/
      if .line > 1 & .col = 1 & not cursoreverywhere then
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

defc MarkPrevChar
   call EnableUndoRec()
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
   call EnableUndoRec()
   if cua_marking_switch then
      unmark
   endif
   page_up

defc NextPage, PageDown
   universal cua_marking_switch
   call EnableUndoRec()
   if cua_marking_switch then
      unmark
   endif
   page_down

defc MarkPageUp
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   call EnableUndoRec()
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
   call EnableUndoRec()
   startline = .line; startcol = .col
   page_down
   if startline then
      call extend_mark( startline, startcol, 1)
   endif

defc NextChar
   universal cursoreverywhere
   universal cua_marking_switch
   call EnableUndoRec()
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

defc MarkNextChar
   call EnableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
   if cua_marking_switch then
      unmark
   endif
   oldline = .line
   .cursory = .windowheight%2
   oldline

defc BackTab
   universal matchtab_on
   universal cua_marking_switch
   call EnableUndoRec()
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
   call DisableUndoRec()
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
   call EnableUndoRec()
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
   call EnableUndoRec()
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
   call NewUndoRec()
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
   call NewUndoRec()

defc AlternatePaste
   universal nepmd_hini
   universal cua_marking_switch
   call NewUndoRec()
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
   call NewUndoRec()

; Insert the char from the line above at cursor position.
; May get executed repeatedly to copy an entire expression without
; cluttering the undo list at every single execution.
; From Luc van Bogaert.
defc InsertCharAbove
   if .line > 1 then
      -- suppress autosave and undo (for during repeated use)
      saved_autosave = .autosave
      .autosave = 0
      call DisableUndoRec()

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
      call DisableUndoRec()

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
   insertline ''
   up

; Add a new line after the current, move to it, keep col.
defc NewLineAfter
   insertline '', .line + 1
   down

