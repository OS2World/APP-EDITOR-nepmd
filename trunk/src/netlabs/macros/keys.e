/****************************** Module Header *******************************
*
* Module Name: keys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: keys.e,v 1.4 2004-09-12 15:49:33 aschn Exp $
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

; Definitions for the 'enter_keys' keyset. Turned all key defs into defcs
; to make keys configurable.

; Make that configurable for testing or emergency cases:
compile if not defined(OLD_ACCEL_KEY_DEFS)
const
   OLD_ACCEL_KEY_DEFS = 0
compile endif

definit
   universal blockreflowflag
   blockreflowflag = 0
compile if defined(ACTIONS_ACCEL__L)  -- For CUSTEPM support
   call AddOnceAVar( 'usedmenuaccelerators', 'A')
compile endif
compile if defined(TEX_BAR__MSG)  -- For TFE or EPMTeX support
   call AddOnceAVar( 'usedmenuaccelerators', 'T')
compile endif
compile if defined(ECO_MENU__MSG)  -- For ECO support
   call AddOnceAVar( 'usedmenuaccelerators', 'I')
compile endif

compile if OLD_ACCEL_KEY_DEFS   -- following is disabled ####################
; ---------------------------------------------------------------------------
defc ProcessOtherKeys
   k = lastkey()

   -- hexch can also be determined with the 'testkeys' keyset. It can be
   -- activated with the 'testkeys' command. Every combination with Ctrl or
   -- Alt will be shown as, e.g. key = x'1622' = """
   hexch = rightstr( itoa( leftstr( k, 1)\0, 16), 2, 0) ||
           rightstr( itoa( substr( k, 2, 1)\0, 16), 2, 0)
   hexch = lowcase(hexch)
   -- Better get flags for Ctrl, Alt, Sh additionally

   if     hexch = '1a22' then  -- Alt+Ins
      'ExecuteKeyCmd a_ins'
   elseif hexch = '1b22' then  -- Alt+Del
      'ExecuteKeyCmd a_del'
   elseif hexch = '1422' then  -- Alt+Home
      'ExecuteKeyCmd a_home'
   elseif hexch = '1322' then  -- Alt+End
      'ExecuteKeyCmd a_end'
   elseif hexch = '1122' then  -- Alt+PgUp
      'ExecuteKeyCmd a_pgup'
   elseif hexch = '1222' then  -- Alt+PgDn
      'ExecuteKeyCmd a_pgdn'
   elseif hexch = '1622' then  -- Alt+Up
      'ExecuteKeyCmd a_up'
   elseif hexch = '1822' then  -- Alt+Down
      'ExecuteKeyCmd a_down'
   elseif hexch = '1522' then  -- Alt+Left
      'ExecuteKeyCmd a_left'
   elseif hexch = '1722' then  -- Alt+Right
      'ExecuteKeyCmd a_right'
;    -- The following Alt key defs don't work, because the non-Alt versions
;    -- have the same hexch. Additionally, the VK_ flags have to be determined
;    -- to make it work (but these combinations are unused).
;    elseif hexch = '2b20' then  -- Alt++
;       'ExecuteKeyCmd a_plus'
;    elseif hexch = '2a20' then  -- Alt+*  (german keyboards: * = Shift++)
;       'ExecuteKeyCmd a_asterisk'
;    elseif hexch = '3d20' then  -- Alt+=  (german keyboards: = = Shift++)
;       'ExecuteKeyCmd a_equal'
;    elseif hexch = '2f20' then  -- Alt+/  (german keyboards: / = Shift+7)
;       'ExecuteKeyCmd a_slash'
;    elseif hexch = '5c20' then  -- Alt+\
;       'ExecuteKeyCmd a_backslash'
;    elseif hexch = '3e20' then  -- Alt+>  (german keyboards: > = Shift+<)
;       'ExecuteKeyCmd a_greater'
;    elseif hexch = '3c20' then  -- Alt+<
;       'ExecuteKeyCmd a_less'

   elseif hexch = '1a12' then  -- Ctrl+Ins
      'ExecuteKeyCmd c_ins'
   elseif hexch = '1b12' then  -- Ctrl+Del
      'ExecuteKeyCmd c_del'
   elseif hexch = '1412' then  -- Ctrl+Home
      'ExecuteKeyCmd c_home'
   elseif hexch = '1312' then  -- Ctrl+End
      'ExecuteKeyCmd c_end'
   elseif hexch = '1612' then  -- Ctrl+Up
      'ExecuteKeyCmd c_up'
   elseif hexch = '1812' then  -- Ctrl+Down
      'ExecuteKeyCmd c_down'
   elseif hexch = '1512' then  -- Ctrl+Left
      'ExecuteKeyCmd c_left'
   elseif hexch = '1712' then  -- Ctrl+Right
      'ExecuteKeyCmd c_right'
   elseif hexch = '2b10' then  -- Ctrl++
      'ExecuteKeyCmd c_plus'
   elseif hexch = '2a10' then  -- Ctrl+*  (german keyboards: * = Shift++)
      'ExecuteKeyCmd c_asterisk'
   elseif hexch = '3d10' then  -- Ctrl+=  (german keyboards: = = Shift++)
      'ExecuteKeyCmd c_equal'
   elseif hexch = '2f10' then  -- Ctrl+/  (german keyboards: / = Shift+7)
      'ExecuteKeyCmd c_slash'
   elseif hexch = '5c10' then  -- Ctrl+\
      'ExecuteKeyCmd c_backslash'
   elseif hexch = '3e10' then  -- Ctrl+>  (german keyboards: > = Shift+<)
      'ExecuteKeyCmd c_greater'
   elseif hexch = '3c10' then  -- Ctrl+<
      'ExecuteKeyCmd c_less'
   -- F-keys not definable this way

   else
      call process_key(k)
   endif

; ---------------------------------------------------------------------------
; Execute a command if defined. Handles Shift and non-Shift key combinations.
; Syntax for these defcs: Key_<my_add_key>. The s_ prefix must occur as last
; prefix. arg(1) must be <my_add_key>, but without the s_ prefix. Example:
; 'ExecuteKeyCmd a_left' will execute the command 'Key_a_left', or
; 'Key_a_s_left', if the Shift key was additionally pressed. If these
; commands are not defined, nothing will be executed.
defc ExecuteKeyCmd
   -- Don't alter .modify if last key is repeated.
   -- BTW: This could be a useful extension for all key defs.
   saved_modify = .modify
   k = lastkey()
   lk = lastkey(1)
   if lk = k then
      AlterModify = 0
   else
      AlterModify = 1
   endif
   Processed = 0

   Key = arg(1)
   lp = lastpos( '_', Key)
   rest = substr( Key, 1, lp)
   last = substr( Key, lp + 1)
   ShiftKey = rest's_'last
   --sayerror 'ShiftKey = 'ShiftKey

   if shifted() then
      if isadefc('Key_'ShiftKey) then
         'Key_'ShiftKey
         Processed = 1
      endif
   else
      if isadefc('Key_'Key) then
         'Key_'Key
         Processed = 1
      endif
   endif

   if AlterModify = 0 and Processed then
      .modify = saved_modify
   else
      if .modify > saved_modify then
         .modify = saved_modify + 1
      endif
   endif

; ---------------------------------------------------------------------------
; Defined menu accels have priority to definitions provided by a keyset
; or by the automatically assigned defs by the PM menu. Therefore they are
; used here to recreate the keyset definition with the dokey command.
; Moved from STDCTRL.E.
defc loadaccel
   universal activeaccel
   universal nepmd_hini
   universal cua_menu_accel

   activeaccel = 'defaccel'  -- name for accelerator table
   i = 1000                 -- let ids start at 1001

   -- Re-enable some (not definable via def) key bindings
   i = i + 1
   buildacceltable activeaccel, 'dokey s+f1',  AF_VIRTUALKEY + AF_SHIFT, VK_F1, i  -- Sh+F1
   i = i + 1
   buildacceltable activeaccel, 'dokey s+f9',  AF_VIRTUALKEY + AF_SHIFT, VK_F9, i  -- Sh+F9
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 1', AF_VIRTUALKEY + AF_ALT, VK_NEWLINE, i    -- Alt+Enter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 2', AF_VIRTUALKEY + AF_ALT, VK_ENTER, i      -- Alt+PadEnter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 3', AF_VIRTUALKEY + AF_SHIFT, VK_NEWLINE, i  -- Shift+Enter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 4', AF_VIRTUALKEY + AF_SHIFT, VK_ENTER, i    -- Shift+PadEnter

   -- Don't want Alt or AltGr switch to menu (PM-defined key F10 does the same)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      i = i + 1
      buildacceltable activeaccel, '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALT, i  -- Alt
   endif
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      i = i + 1
      buildacceltable activeaccel, '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALTGRAF, i  -- AltGr
   endif

   -- Block action bar accelerator keys
   -- The PM menu automatically assigns Alt+<actionbar_key> bindings to
   -- open the main actionbar, if key mnemonics defined. This would
   -- overwrite the definitions, provided by the keyset. Even when these
   -- bindings are blocked, one can add Sh or Ctrl to access the menu
   -- directly (or use F10, followed bey Left or Right).
   if not cua_menu_accel then
      UsedMenuAccelerators = GetAVar('usedmenuaccelerators')
      do w = 1 to words( UsedMenuAccelerators)
         char = word( UsedMenuAccelerators, w)
         do u = 1 to 2
            if u = 1 then
               char = upcase(char)  -- capslocked key, shifted combination isn't affected
            else
               char = lowcase(char)
            endif
            key = asc(char)
            i = i + 1
            buildacceltable activeaccel, 'dokey a+'lowcase(char), AF_CHAR + AF_ALT, key, i
         enddo
      enddo
   endif

   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   --dprintf( 'KEYS', 'lastkeyaccelid = 'i)

   if isadefproc('build_menu_accelerators') then
      call build_menu_accelerators(activeaccel)  -- moved to menu-specific file
   endif

   activateacceltable activeaccel
   return

compile else  -- new accel key defs #########################################
; ---------------------------------------------------------------------------
defc ProcessOtherKeys
   k = lastkey()
   call process_key(k)

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
   -- NO_DEF_CHAR_LIST = no key defs for Alt+<name> and Ctrl+<name> exist
compile if not defined(NO_DEF_CHAR_LIST)
   NO_DEF_CHAR_LIST = '* + < > ( ) [ ] # , . ! ? " ^ % $ & ï ` '' ~ | @'
compile endif

   -- VIRTUAL_LIST = virtual keys, for those every combination should be
   -- defined, see pmwin.h.
compile if not defined(VIRTUAL_LIST)
   VIRTUAL_LIST  = 'BACKSPACE TAB ESC PAGEUP PAGEDOWN END HOME'
   VIRTUAL_IDS   = '5         6   15  17     18       19  20'
   VIRTUAL_NAMES = 'BACKSPACE TAB ESC PGUP   PGDN     END HOME'
   VIRTUAL_LIST  = VIRTUAL_LIST  || ' LEFT UP RIGHT DOWN INSERT DELETE'
   VIRTUAL_IDS   = VIRTUAL_IDS   || ' 21   22 23    24   26     27'
   VIRTUAL_NAMES = VIRTUAL_NAMES || ' LEFT UP RIGHT DOWN INS    DEL'
   VIRTUAL_LIST  = VIRTUAL_LIST  || ' F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12'
   VIRTUAL_IDS   = VIRTUAL_IDS   || ' 32 33 34 35 36 37 38 39 40 41  42  43'
   VIRTUAL_NAMES = VIRTUAL_NAMES || ' F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12'
compile endif
   -- PM_LIST    = don't overwrite <key>, because they are standard PM keys
compile if not defined(PM_LIST)
   PM_LIST       = 'F1'
compile endif
   -- PM_ALT_LIST = don't overwrite Alt+<key>, because they are standard PM keys
compile if not defined(PM_ALT_LIST)
   PM_ALT_LIST    = 'SPACE TAB ESC F4 F5 F6 F7 F8 F9 F10 F11'
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

   activeaccel = 'defaccel'  -- name for accelerator table
   i = 1000                  -- let ids start at 1001

   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 1', AF_VIRTUALKEY + AF_ALT, VK_NEWLINE, i    -- Alt+Enter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 2', AF_VIRTUALKEY + AF_ALT, VK_ENTER, i      -- Alt+PadEnter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 3', AF_VIRTUALKEY + AF_SHIFT, VK_NEWLINE, i  -- Shift+Enter
   i = i + 1
   buildacceltable activeaccel, 'Alt_enter 4', AF_VIRTUALKEY + AF_SHIFT, VK_ENTER, i    -- Shift+PadEnter

   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)

   call DefineLetterAccels()
   call DefineCharAccels()
   call DefineVirtualAccels()

   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')

   -- Don't want Alt or AltGr switch to menu (PM-defined key F10 does the same)
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      i = i + 1
      buildacceltable activeaccel, '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALT, i  -- Alt
   endif
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      i = i + 1
      buildacceltable activeaccel, '', AF_VIRTUALKEY + AF_LONEKEY, VK_ALTGRAF, i  -- AltGr
   endif

   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   --dprintf( 'KEYS', 'lastkeyaccelid = 'i)

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
   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')
   UsedMenuAccelerators = GetAVar('usedmenuaccelerators')
   List = UPPERCASE_LETTER_LIST
   do w = 1 to words( List)
      cmd = ''
      char = word( UPPERCASE_LETTER_LIST, w)
      -- lowercase is not used here, because it would only work for Ascii letters
      ukey = asc(word( UPPERCASE_LETTER_LIST, w))
      lkey = asc(word( LOWERCASE_LETTER_LIST, w))
      name = char
      OmitAltAccel = 0
      if cua_menu_accel then
         if wordpos( char, upcase(UsedMenuAccelerators)) then
            OmitAltAccel = 1
         endif
      endif

      if isadefc('Key_c_'name) then
         cmd = 'Key_c_'name
      else
         cmd = 'dokey c+'name
      endif
      i = i + 1
      buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL, lkey, i  -- Ctrl+<key> (lowercase)
      i = i + 1
      buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL, ukey, i  -- Ctrl+<key> (uppercase)
      if isadefc('Key_c_s_'name) then
         cmd = 'Key_c_s_'name
      endif
;      i = i + 1
;      buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, lkey, i  -- Ctrl+Sh+<key> (lowercase)
      i = i + 1
      buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, ukey, i  -- Ctrl+Sh+<key> (uppercase)

      if isadefc('Key_a_'name) then
         cmd = 'Key_a_'name
      else
         cmd = 'dokey a+'name
      endif
      if not OmitAltAccel then  -- if not (cua_meu_accel and found in UsedMenuAccelerators)
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT, lkey, i  -- Alt+<key> (lowercase)
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT, ukey, i  -- Alt+<key> (uppercase)
      endif
      if isadefc('Key_a_s_'name) then
         cmd = 'Key_a_s_'name
      endif
;      i = i + 1
;      buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT + AF_SHIFT, lkey, i  -- Alt+Sh+<key> (lowercase)
      i = i + 1
      buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT + AF_SHIFT, ukey, i  -- Alt+Sh+<key> (uppercase)

      if isadefc('Key_c_a_'name) then
         cmd = 'Key_c_a_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT, lkey, i  -- Ctrl+Alt+<key> (lowercase)
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT, ukey, i  -- Ctrl+Alt+<key> (uppercase)
      endif
      if isadefc('Key_c_a_s_'name) then
         cmd = 'Key_c_a_s_'name
      endif
      if cmd <> '' then
;         i = i + 1
;         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, lkey, i  -- Ctrl+Alt+Sh+<key> (lowercase)
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, ukey, i  -- Ctrl+Alt+Sh+<key> (uppercase)
      endif


/***
      do u = 1 to 2
         if u = 1 then
            char = upcase(char)  -- capslocked key, shifted combination isn't affected
         else
            char = lowcase(char)
         endif
         key = asc(char)
         name = char

         if isadefc('Key_c_'name) then
            cmd = 'Key_c_'name
         else
            cmd = 'dokey c+'name
         endif
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL, key, i                -- Ctrl+<key>
/*
         if isadefc('Key_c_s_'name) then
            cmd = 'Key_c_s_'name
            i = i + 1
            buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, key, i  -- Ctrl+Sh+<key>
         endif
*/

         if not OmitAltAccel then  -- if not (cua_meu_accel and found in UsedMenuAccelerators)
            if isadefc('Key_a_'name) then
               cmd = 'Key_a_'name
            else
               cmd = 'dokey a+'name
            endif
            i = i + 1
            buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT, key, i             -- Alt+<key>
         endif
/*
         if isadefc('Key_a_s_'name) then
            cmd = 'Key_a_s_'name
            i = i + 1
            buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT + AF_SHIFT, key, i  -- Alt+Sh+<key>
         endif
*/

         if isadefc('Key_c_a_'name) then
            cmd = 'Key_c_a_'name
            i = i + 1
            buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT, key, i             -- Ctrl+Alt+<key>
         endif
/*
         if isadefc('Key_c_a_s_'name) then
            cmd = 'Key_c_a_s_'name
            i = i + 1
            buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, key, i  -- Ctrl+Alt+Sh+<key>
         endif
*/
      enddo
***/

   enddo
   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   return i

; ---------------------------------------------------------------------------
; Chars, for that no upper/lowercase variants exist.
defproc DefineCharAccels
   universal activeaccel
   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')
   List = CHAR_LIST
   do w = 1 to words( List)
      char = word( List, w)
      key  = asc(char)
      name = word( CHAR_NAMES, w)
      DefExists = (wordpos( char, NO_DEF_CHAR_LIST) = 0)

      cmd = ''
      if isadefc('Key_c_'name) then
         cmd = 'Key_c_'name
      elseif DefExists then
         cmd = 'dokey c+'name
      endif
      if cmd <> '' then
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL, key, i             -- Ctrl+<key>
      endif
      if isadefc('Key_c_s_'name) then
         cmd = 'Key_c_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_SHIFT, key, i  -- Ctrl+Sh+<key>
      endif

      cmd = ''
      if isadefc('Key_a_'name) then
         cmd = 'Key_a_'name
      elseif DefExists then
         cmd = 'dokey a+'name
      endif
      if cmd <> '' then
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT, key, i             -- Alt+<key>
      endif
      if isadefc('Key_a_s_'name) then
         cmd = 'Key_a_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_ALT + AF_SHIFT, key, i  -- Alt+Sh+<key>
      endif

      if isadefc('Key_c_a_'name) then
         cmd = 'Key_c_a_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT, key, i             -- Ctrl+Alt+<key>
      endif
      if isadefc('Key_c_a_s_'name) then
         cmd = 'Key_c_a_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_CHAR + AF_CONTROL + AF_ALT + AF_SHIFT, key, i  -- Ctrl+Alt+Sh+<key>
      endif

   enddo
   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   return

; ---------------------------------------------------------------------------
; Virtual keys like F1, Insert, Up.
defproc DefineVirtualAccels
   universal activeaccel
   -- Get the last used id from an array var
   i = GetAVar( 'lastkeyaccelid')
   List = VIRTUAL_LIST
   do w = 1 to words( List)
      char = word( List, w)
      id   = word( VIRTUAL_IDS, w)
      name = word( VIRTUAL_NAMES, w)

      if not wordpos( char, PM_LIST) then
         if isadefc('Key_'name) then
            cmd = 'Key_'name
         else
            cmd = 'dokey 'name
         endif
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY, id, i          -- <key>
      endif
      if isadefc('Key_s_'name) then
         cmd = 'Key_s_'name
      else
         cmd = 'dokey s+'name
      endif
      i = i + 1
      buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_SHIFT, id, i  -- Sh+<key>

      if isadefc('Key_c_'name) then
         cmd = 'Key_c_'name
      else
         cmd = 'dokey c+'name
      endif
      i = i + 1
      buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_CONTROL, id, i                -- Ctrl+<key>
      if isadefc('Key_c_s_'name) then
         cmd = 'Key_c_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_CONTROL + AF_SHIFT, id, i  -- Ctrl+Sh+<key>
      endif

      if not wordpos( char, PM_ALT_LIST) then
         if isadefc('Key_a_'name) then
            cmd = 'Key_a_'name
         else
            cmd = 'dokey a+'name
         endif
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_ALT, id, i             -- Alt+<key>
      endif
      if isadefc('Key_a_s_'name) then
         cmd = 'Key_a_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_ALT + AF_SHIFT, id, i  -- Alt+Sh+<key>
      endif

      if isadefc('Key_c_a_'name) then
         cmd = 'Key_c_a_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_CONTROL + AF_ALT, id, i             -- Ctrl+Alt+<key>
      endif
      if isadefc('Key_c_a_s_'name) then
         cmd = 'Key_c_a_s_'name
         i = i + 1
         buildacceltable activeaccel, cmd, AF_VIRTUALKEY + AF_CONTROL + AF_ALT + AF_SHIFT, id, i  -- Ctrl+Alt+Sh+<key>
      endif

   enddo
   -- Save the last used id in an array var
   call SetAVar( 'lastkeyaccelid', i)
   return

compile endif  -- OLD_ACCEL_KEY_DEFS ########################################

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
defc alt_enter =
compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
   universal a_enterkey, a_padenterkey, s_enterkey, s_padenterkey
   call enter_common( substr( a_enterkey||a_padenterkey||s_enterkey||s_padenterkey, arg(1), 1))
compile else
   executekey enter
compile endif

; ---------------------------------------------------------------------------
defc dokey
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
   C_Prefix = 0
   A_Prefix = 0
   S_Prefix = 0
   done = 0
   rest = ku
   do while (done = 0 & length(ku) > 2)
      p = pos( leftstr( ku, 1), 'CAS')
      if p & pos( substr( ku, 2, 1), '_-+') then
         ku = substr( ku, 3)
         if p = 1 then
            C_Prefix = 1
         elseif p = 2 then
            A_Prefix = 1
         elseif p = 3 then
            S_Prefix = 1
         endif
      else
         done = 1
      endif
   enddo
   suffix = ''

   wv = wordpos( ku, VIRTUAL_NAMES)
   wc = wordpos( ku, CHAR_NAMES)
   --dprintf( 'resolve_key', 'k = 'k', ku = 'ku', Ctrl = 'C_Prefix', Alt = 'A_Prefix', Sh = 'S_Prefix', Virtual = 'wv', Char = 'wc)
   if wv then
      if C_Prefix then
         suffix = \18
      elseif A_Prefix then
         suffix = \34
      elseif S_Prefix then
         suffix = \10
      else
         suffix = \2
      endif
      k = chr(word( VIRTUAL_IDS, wv))''suffix
   elseif wc then
      if C_Prefix then
         suffix = \16
         k = word( CHAR_LIST, wc)''suffix
      elseif A_Prefix then
         suffix = \32
         k = word( CHAR_LIST, wc)''suffix
      endif
   else
      if C_Prefix then
         suffix = \16
         k = lowcase(ku)''suffix  -- letters must be lowercase for executekey
      elseif A_Prefix then
         suffix = \32
         k = lowcase(ku)''suffix  -- letters must be lowercase for executekey
      endif
   endif

   return k

; ---------------------------------------------------------------------------
defproc process_key(k)
   universal CUA_marking_switch
   if length(k) = 1 & k <> \0 then
      i_s = insert_state()
      if CUA_marking_switch then
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
         firstline; .col = firstcol
         undoaction 1, junk                -- Create a new state
         call pdelete_mark()
         'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
         return 1
      endif
   endif

defproc shifted
   ks = getkeystate(VK_SHIFT)
   return ks<>3 & ks<>4

defproc updownkey(down_flag)
   universal save_cursor_column
   universal stream_mode
   if stream_mode then
      lk = lastkey(1)
      updn = pos(leftstr(lk,1),\x18\x16) & pos(substr(lk,2,1),\x02\x0A\x12)   -- VK_DOWN or VK_UP, plain or Shift or Ctrl
      if not updn then save_cursor_column = .col; endif
   endif

   if down_flag then down; else up; endif

   if .line & stream_mode then
      l = length(textline(.line))
      if updn & l>=save_cursor_column then
         .col = save_cursor_column
      elseif updn | l<.col then
         end_line
      endif
   endif

define CHARG_MARK = 'CHARG'

defproc extend_mark( startline, startcol, forward)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  universal CUA_marking_switch
;  if not CUA_marking_switch then return; endif
;compile endif
   getfileid curfileid
   getmarkg firstline, lastline, firstcol, lastcol, markfileid
   if markfileid <> curfileid then
      unmark
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

; c_home, c_end, c_left & c_right do different things if the shift key is depressed.
; The logic is extracted here mainly due to the complexity of the COMPILE IF's
defproc begin_shift( var startline, var startcol, var shift_flag)
   universal CUA_marking_switch
   shift_flag = shifted()
   if shift_flag or not CUA_marking_switch then
      startline = .line; startcol = .col
   else
      unmark
   endif

defproc end_shift(startline, startcol, shift_flag, forward_flag)
; Let's let this work regardless of which marking mode is active.
compile if 0 -- WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if shift_flag & CUA_marking_switch then
compile else
   if shift_flag then
compile endif
      call extend_mark(startline, startcol, forward_flag)
   endif

; We now distribute a standard front end for the DIR command, which redirects
; the output to a file named ".dos dir <dirspec>".  The third line should be
; "Directory of <dirname>".  If so, we use it.  If not, we use DIRSPEC from the
; .filename instead, but note that the latter might contain wildcards.
define
   QUOTED_DIR_STRING ='"'DIRECTORYOF_STRING'"'

/*
; Unused, we include ALT_1.E
def a_1= /* edit filename on current text line */
   getline line
   if leftstr(.filename, 15) = ".command_shell_" then
      if substr(line, 13, 1) = ' ' then  -- old format DIR, or not a DIR line
         flag = substr(line, 1, 1) <> ' ' &
                (isnum(substr(line, 14, 8)) | substr(line, 14, 8)='<DIR>') &
                length(line) < 40 &
                isnum(substr(line, 24, 2) || substr(line, 27, 2) || substr(line, 30, 2)) &
                substr(line, 26, 1) = substr(line, 29, 1) &
                pos(substr(line, 26, 1), '/x.-')
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif
      else                               -- new format DIR, or not a DIR line
         flag = substr(line, 41, 1) <> ' ' &
                (isnum(substr(line, 18, 9)) | substr(line, 18, 9)='<DIR>') &
                isnum(substr(line, 1, 2) || substr(line, 4, 2) || substr(line, 7, 2)) &
                substr(line, 3, 1) = substr(line, 6, 1) &
                pos(substr(line, 3, 1), '/x.-')
         filename=substr(line,41)
         if substr(line, 39, 1)=' ' & substr(line, 40, 1)<>' ' then  -- OS/2 2.11 is misaligned...
            filename=substr(line,40)
         endif
      endif
      if flag then
         call psave_pos(save_pos)
         getsearch oldsearch
         display -2
         'xcom l /'DIRECTORYOF_STRING'/c-'
         dir_rc = rc
         if not rc then
            getline word3
            parse value word3 with $QUOTED_DIR_STRING word3
;;          parse value word3 with . . word3 .
            if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
               word3 = substr(word3, 1, lastpos(word3, '\')-1)
            endif
            word3 = strip(word3)
         endif
         display 2
         setsearch oldsearch
         call prestore_pos(save_pos)
         if not dir_rc then
            name=word3 ||                            -- Start with the path.
                 leftstr('\',                        -- Append a '\', but only if path
                         '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
                 filename                            -- Finally, the filename
;           if pos(' ',name) then  -- enquote
            if verify(name, ' =', 'M') then  -- enquote
               name = '"'name'"'
            endif
            if pos('<DIR>',line) then
               'dir 'name
            else
               'e 'name
            endif
            return
         endif
      endif
   endif  -- leftstr(.filename, 15) = ".command_shell_"
   parse value .filename with word1 word2 word3 .
   if upcase(word1 word2) = '.DOS DIR' then
      call psave_pos(save_pos)
      getsearch oldsearch
      'xcom l /'DIRECTORYOF_STRING'/c-'
      if not rc then
         getline word3
         parse value word3 with $QUOTED_DIR_STRING word3
;        parse value word3 with . . word3 .
         if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
            word3 = substr(word3, 1, lastpos(word3, '\')-1)
         endif
         word3 = strip(word3)
      endif
      setsearch oldsearch
      call prestore_pos(save_pos)
      filename=substr(line,41)                 -- Support HPFS.  FAT dir's end at 40
      if substr(line, 39, 1)=' ' & substr(line, 40, 1)<>' ' then  -- OS/2 2.11 is misaligned...
         filename=substr(line,40)
      endif
      if filename='' then                      -- Must be FAT.
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif
      endif
      name=word3 ||                            -- Start with the path.
           leftstr('\',                        -- Append a '\', but only if path
                   '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
           filename                            -- Finally, the filename
;     if pos(' ',name) then  -- enquote
      if verify(name, ' =', 'M') then  -- enquote
         name = '"'name'"'
      endif
      if pos('<DIR>',line) then
         'dir 'name
      else
         'e 'name
      endif
;compile if WANT_TREE
   elseif .filename = '.tree' then
      if substr(line,5,1)substr(line,8,1)substr(line,15,1)substr(line,18,1) = '--::' then
         name = substr(line, 52)
         if substr(line,31,1)='>' then
;           if isadefc('tree_dir') then
               'tree_dir "'name'\*.*"'
;           else
;              'dir' name
;           endif
         else
            'e "'name'"'
         endif
      endif
;compile endif  -- WANT_TREE
   else  -- Not a DIR or TREE listing
      parse value line with w1 rest
      p=lastpos('(', w1)
 compile if HOST_SUPPORT = 'EMUL' & defined(MVS)
  compile if MVS
      if p & rightstr(w1, 1)<>"'" then
  compile else
      if p then
  compile endif
 compile else
      if p then
 compile endif
         filename = substr(w1, 1, p-1)
         parse value substr(w1, p+1) with line ')'
         parse value line with line ':' col
         if pos('*', filename) then
            if YES_CHAR<>askyesno(WILDCARD_WARNING__MSG, '', filename) then
               return
            endif
         endif
         'e 'filename
         line
         if col<>'' then .col = col; endif
      else
         if pos('*', line) then
            if YES_CHAR<>askyesno(WILDCARD_WARNING__MSG, '', line) then
               return
            endif
         endif
         'e 'line
      endif  -- p
   endif  -- upcase(word1 word2) = '.DOS DIR'
*/

defc AdjustMark
compile if WANT_CHAR_OPS
   call pcommon_adjust_overlay('A')
compile else
   adjustblock
compile endif

defc OverlayMark
   if marktype() then
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('O')
compile else
      overlay_block
compile endif
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff O'   /* see clipbrd.e for details                 */
   endif

defc CopyMark
   if marktype() then
      call pcopy_mark()
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff'     /* see clipbrd.e for details                 */
   endif

defc MoveMark
   call pmove_mark()
compile if UNMARK_AFTER_MOVE
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
compile endif

defc DeleteMark
;compile if WANT_DM_BUFFER
   'Copy2DMBuff'     -- see clipbrd.e for details
;compile endif
   call pdelete_mark()
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */

defc unmark
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */

defc BeginMark
   call pbegin_mark()

defc EndMark
   call pend_mark()
   if substr(marktype(),1,1)<>'L' then
      right
   endif

defc FillMark /* Now accepts key from macro. */
   call checkmark()
   call pfill_mark()

defc TypeFrameChars
   keyin 'º Ì É È Ê Í Ë ¼ » ¹ Î ³ Ã Ú À Á Ä Â Ù ¿ ´ Å Û ² ± °'

defc ShiftLeft   -- Can't use the old A_F7 in EPM.  PM uses it as an accelerator key.
   shift_left
compile if SHIFT_BLOCK_ONLY
   if marktype()='BLOCK' then  -- code by Bob Langer
      getmark fl,ll,fc,lc,fid
      call pset_mark(fl,ll,lc,MAXCOL,'BLOCK',fid)
      shift_right
      call pset_mark(fl,ll,fc,lc,'BLOCK',fid)
   endif
compile endif

defc ShiftRight   -- Can't use the old A_F8 in EPM.  PM uses it as an accelerator key.
compile if SHIFT_BLOCK_ONLY
   if marktype()='BLOCK' then  -- code by Bob Langer
      getmark fl,ll,fc,lc,fid
      call pset_mark(fl,ll,lc,MAXCOL,'BLOCK',fid)
      shift_left
      call pset_mark(fl,ll,fc,lc,'BLOCK',fid)
   endif
compile endif
   shift_right

/* We can't use a_f10 for previous file any more, PM uses that key. */
/* I like F11 and F12 to go back and forth.                         */
defc prevfile  -- a_F10 is usual E default; F11 for enh. kbd, c_P for EPM.
   prevfile

defc JoinLines
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
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

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
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

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
   circleit 5, .line, .col-1, .col+1, 16777220

defc TypeFileName  /* Type the full name of the current file. */
  keyin .filename

defc ReflowPar
   /* Protect the user from accidentally reflowing a marked  */
   /* area not in the current file, and give a good message. */
   mt = substr(marktype(), 1, 1)
   if mt='B' or mt='L' then
      getmark firstline,lastline,firstcol,lastcol,markfileid
      getfileid fileid
      if fileid<>markfileid then
         sayerror CANT_REFLOW__MSG'  'OTHER_FILE_MARKED__MSG
         return
      endif
   endif

   if mt<>' ' then
      if not check_mark_on_screen() then
         sayerror MARK_OFF_SCREEN__MSG
         stop
      endif
   endif

   if mt='B' then
      'box r'
   elseif mt='C' then
      sayerror WRONG_MARK__MSG
   elseif mt='L' then
      reflow
   else  -- Standard text reflow split into a separate routine.
      call text_reflow()
   endif

definit                         -- Variable is null if alt_R is not active.
   universal alt_R_active       -- For E3/EOS2, it's 1 if alt_R is active.
   alt_R_active = ''            -- For EPM, it's set to querycontrol(messageline).

defc ReflowBlock
   universal alt_R_active,tempofid
   universal alt_R_space

   if alt_R_active<>'' then
      call pblock_reflow(1,alt_R_space,tempofid)     -- Complete the reflow.
      'setmessageline '\0
      'toggleframe 2 'alt_R_active           -- Restore status of messageline.
      alt_R_active = ''
      return
   endif
   if pblock_reflow(0,alt_R_space,tempofid) then
      sayerror PBLOCK_ERROR__MSG      /* HurleyJ */
      return
   endif
;  if marktype() <> 'BLOCK' then
      unmark
;  endif
   alt_R_active = queryframecontrol(2)         -- Remember if messageline on or off
   'toggleframe 2 1'                    -- Force it on
   'setmessageline' BLOCK_REFLOW__MSG

defc SplitLines
   call splitlines()

defc CenterMark
   call pcenter_mark()

defc BackSpace
   universal stream_mode
   universal CUA_marking_switch
   if CUA_marking_switch then
      if process_mark_like_cua() then return; endif
   endif
   if .col=1 & .line>1 & stream_mode then
      up
      l=length(textline(.line))
      join
      .col=l+1
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
   undoaction 1, junk                -- Create a new state
   if .levelofattributesupport then
      if (.line==.last and .line<>1) then       -- this is the last line
         destinationLine=.line-1                -- and there is a previous line to store attributes on
         getline prevline,DestinationLine
         DestinationCol=length(prevline)+1      -- start search parameters
                                                -- destination of attributes
         findoffset=-300                        -- start at the begin of the attr list
         findline=.line                         -- of the first char on this line
         findcolumn=1

         do forever        -- search until no more attr's (since this is last line)
            FINDCLASS=0          -- 0 is anyclass
            Attribute_action FIND_NEXT_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline<>.line) then  -- No attribute, or not on this line
               leave
            endif
            query_attribute theclass,thevalue, thepush, findoffset, findcolumn, findline   -- push or pop?
            if not thePush then       -- ..if its a pop attr and ..
               matchClass=theClass
               MatchOffset=FindOffset
               MatchLine=FindLine
               MatchColumn=FindColumn  -- ..and if its match is not on this line or at the destination
               Attribute_Action FIND_MATCH_ATTR_SUBOP, MatchClass, MatchOffset, Matchcolumn, MatchLine
               if ((Matchline==DestinationLine) and (Matchcolumn==destinationcol)) then
                  -- then there is a cancellation of attributes
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
                  Attribute_action Delete_ATTR_SUBOP, Matchclass, Matchoffset, Matchcolumn, Matchline
               elseif (MatchLine<>.line)  then
                  -- .. then move attribute to destination (before attributes which have been scanned so its OK.)
                  -- insert attr at the end of the attr list (offset=0)
                  Insert_Attribute theclass, thevalue, 0, 0, DestinationCol, DestinationLine
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
               endif -- end if attr is on line or at destination
            endif -- end if found attr is a pop
         enddo  -- end search for attr's
      elseif .line < .last then  -- put the attributes after the line since there may not
                                 -- be a line before this line (as when .line==1)
         DestinationCol=1
         DestinationLine=.line+1         -- error point since this puts attr's after last line if .line=.last
         findoffset=0                    -- cant make it .line-1 cause then present attributes there become
         findline=.line                  -- after these attributes which is wrong
         findcolumn=MAXCOL

         do forever
            FINDCLASS=0
            Attribute_action FIND_PREV_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline<>.line) then  -- No attribute, or not on this line
               leave
            endif
             /* Move Attribute */
            query_attribute theclass,thevalue, thepush, findoffset, findcolumn, findline
            -- only move push/pop model attributes (tags are just deleted)
            if ((thepush==0) or (thepush==1)) then
               -- move attribute to destination, if cancellation delete both attributes
               FastMoveAttrToBeg(theclass, thevalue, thepush, DestinationCol, DestinationLine, findcolumn, findline, findoffset)
               findoffset=findoffset+1  -- since the attr rec was deleted and all attr rec's were shifted to fill the vacancy
                                        -- and search is exclusive
            endif
         enddo
      endif -- endif .line=.last and .line=1
   endif -- .levelofattributesupport
   deleteline
   undoaction 1, junk                -- Create a new state

; Ctrl-D = word delete, thanks to Bill Brantley.
defc DeleteUntilNextword /* delete from cursor until beginning of next word, UNDOable */
   getline line
   begcur=.col
   lenLine=length(line)
   if lenLine >= begcur then
      for i = begcur to lenLine /* delete remainder of word */
         if substr(Line,i,1)<>' ' then
            deleteChar
         else
            leave
         endif
      endfor
      for j = i to lenLine /* delete delimiters following word */
         if substr(Line,j,1)==' ' then
            deleteChar
         else
            leave
         endif
      endfor
   endif

defc DeleteUntilEndLine
   erase_end_line  -- Ctrl-Del is the PM way.

defc EndFile
   universal stream_mode
   call begin_shift(startline, startcol, shift_flag)
   if stream_mode then
      bottom; endline
   else
      if .line=.last and .line then endline; endif
      bottom
   endif
   call end_shift(startline, startcol, shift_flag, 1)

; Moved def c_enter, c_pad_enter= to ENTER.E
; Moved def c_f to LOCATE.E

; c_f1 is not definable in EPM.
defc UppercaseWord
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call puppercase()
   call prestore_mark(save_mark)

defc LowercaseWord
   call psave_pos(save_pos)
   call psave_mark(save_mark)
   call pmark_word()
   call plowercase()
   call prestore_mark(save_mark)
   call prestore_pos(save_pos)

defc UppercaseMark
   call puppercase()

defc LowercaseMark
   call plowercase()

defc BeginWord
   call pbegin_word()

defc EndWord
   call pend_word()

; def c_f7  -- is defined as shift left
; def c_f8  -- is defined as shift right

defc BeginFile
   universal stream_mode
   call begin_shift(startline, startcol, shift_flag)
   if stream_mode then
      top; begin_line
   else
      if .line=1 then begin_line endif
      top
   endif
   call end_shift(startline, startcol, shift_flag, 0)

defc DuplicateLine      -- Duplicate a line
  getline line
  insertline line,.line+1

defc CommandDlgLine
   if .line then
      getline line
      'commandline 'line
   endif

defc PrevWord
   universal stream_mode
   call begin_shift(startline, startcol, shift_flag)
   if not .line then
      begin_line
   elseif .line>1 & .col=max(1,verify(textline(.line),' ')) & stream_mode then
      up; end_line
   endif
   backtab_word
   call end_shift(startline, startcol, shift_flag, 0)

defc BeginScreen
   call begin_shift(startline, startcol, shift_flag)
   .cursory=1
   call end_shift(startline, startcol, shift_flag, 0)

defc EndScreen
   call begin_shift(startline, startcol, shift_flag)
   .cursory=.windowheight
   call end_shift(startline, startcol, shift_flag, 1)

defc RecordKeys
   -- Query to see if we are already in recording
   if windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                    5393,
                    0,
                    0)
   then
      call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                         5392,
                         0,
                         0)
      sayerror REMEMBERED__MSG
   else
      sayerror CTRL_R__MSG
      call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                         5390,
                         0,
                         0)
   endif

defc NextWord
   universal stream_mode
   call begin_shift(startline, startcol, shift_flag)
   getline line
   if not .line | lastpos(' ',line)<.col & .line<.last & stream_mode then
      down
      call pfirst_nonblank()
   else
      tab_word
   endif
   call end_shift(startline, startcol, shift_flag, 1)


defc PlaybackKeys
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5392,
                      0,
                      0)
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5391,
                      0,
                      0)

defc TypeTab
   keyin \9

defc DeleteChar
   universal stream_mode
   universal CUA_marking_switch
   if marktype() & CUA_marking_switch then    -- If there's a mark, then
      if process_mark_like_cua() then return; endif
   endif
   if .line then
      l=length(textline(.line))
   else
      l=.col    -- make the following IF fail
   endif
   if .col>l & stream_mode then
      join
      .col=l+1
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
   universal CUA_marking_switch
   if CUA_marking_switch then
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
   universal CUA_marking_switch
   startline = .line; startcol = .col
   call updownkey(1)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if CUA_marking_switch then
;compile endif
   if startline then call extend_mark(startline, startcol, 1); endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif

defc EndLine
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   end_line

defc MarkEndLine
   startline = .line; startcol = .col
   end_line
   call extend_mark(startline, startcol, 1)

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
compile if SMARTSAVE
   if .modify then           -- Modified since last Save?
      'Save'                 --   Yes - save it
   else
;      'commandline Save '
      sayerror 'No changes.  Press Enter to Save anyway.'
      'saveas_dlg 0'  -- better show file selector
                      -- new optional arg, 0 => no EXIST_OVERLAY__MSG
   endif
compile else
   'Save'
compile endif

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

defc BeginLineOrText  -- Home
   universal nepmd_hini
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   KeyPath = '\NEPMD\User\Keys\Home\ToggleBeginLineText'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      -- Go to begin of text.
      -- If in area before or at begin of text, go to column 1.
      startline = .line; startcol = .col
      call pfirst_nonblank()
      if .line = startline and .col = startcol then
         begin_line
      endif
   else
      begin_line
   endif

defc MarkBeginLineOrText  -- Sh+Home
   universal nepmd_hini
   startline = .line; startcol = .col
   KeyPath = '\NEPMD\User\Keys\Home\ToggleBeginLineText'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      -- Go to begin of text.
      -- If in area before or at begin of text, go to column 1.
      startline = .line; startcol = .col
      call pfirst_nonblank()
      if .line = startline and .col = startcol then
         begin_line
      endif
   else
      begin_line
   endif
   call extend_mark(startline, startcol, 0)


defc InsertToggle
   insert_toggle
   call fixup_cursor()

defc PrevChar
   universal CUA_marking_switch
   universal stream_mode
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      'ScrollLeft'
   else
compile endif
*/
      if .line>1 & .col=1 & stream_mode then up; end_line; else left; endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
*/
   if CUA_marking_switch then
      unmark
   endif


defc MarkPrevChar
   startline = .line; startcol = .col
   if .line>1 & .col=1 then up; end_line; else left; endif
   call extend_mark(startline, startcol, 0)


defc PrevPage, PageUp
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   page_up

defc NextPage, PageDown
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   page_down

defc MarkPageUp
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   startline = .line; startcol = .col
   page_up
   if .line then call extend_mark(startline, startcol, 0); endif
compile if TOP_OF_FILE_VALID = 'STREAM'
   if not .line & stream_mode then '+1'; endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
compile endif

defc MarkPageDown
   startline = .line; startcol = .col
   page_down
   if startline then call extend_mark(startline, startcol, 1); endif

defc NextChar
   universal stream_mode
   universal CUA_marking_switch
   if CUA_marking_switch then
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
      if .line then l=length(textline(.line)); else l=.col; endif
      if .line<.last & .col>l & stream_mode then
         down; begin_line
      elseif .line=.last & .col>l & stream_mode then   -- nop
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
   startline = .line; startcol = .col
   if .line then l=length(textline(.line)); else l=.col; endif
   if .line<.last & .col>l then
      down; begin_line
   elseif .line<>.last | .col<=l then
      right
   endif
   call extend_mark(startline, startcol, 1)


defc ScrollLeft
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   oldcursorx=.cursorx
   if .col-.cursorx then
      .col=.col-.cursorx
      .cursorx=oldcursorx
   elseif .cursorx>1 then
      left
   endif

defc ScrollRight
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   oldcursorx=.cursorx
   a=.col+.windowwidth-.cursorx+1
   if a<=MAXCOL then
      .col=a
      .cursorx=oldcursorx
   elseif .col<MAXCOL then
      right
   endif

defc ScrollUp
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   oldcursory=.cursory
   if .line-.cursory>-1 then
      .cursory=1
      up
      .cursory=oldcursory
   elseif .line then
      up
   endif

defc ScrollDown
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   oldcursory=.cursory
   if .line -.cursory+.windowheight<.last then
      .cursory=.windowheight
      down
      .cursory=oldcursory
   elseif .line<.last then
      down
   endif

defc CenterLine
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   oldline=.line
   .cursory=.windowheight%2
   oldline

defc BackTab
   universal matchtab_on
   universal CUA_marking_switch
   if CUA_marking_switch then
      unmark
   endif
   if matchtab_on & .line>1 then
      up
      backtab_word
      down
   else
      backtab
   endif

defc space
   universal CUA_marking_switch
   if CUA_marking_switch then
      call process_mark_like_cua()
   endif
   k=lastkey(1)
   keyin ' '
   if k<>' ' then
      undoaction 1, junk                -- Create a new state
   endif

defc tab
   universal stream_mode
   universal matchtab_on
   universal TAB_KEY
   universal CUA_marking_switch
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
                  -------Start of logic:
   if TAB_KEY then
      if CUA_marking_switch then
          process_key(\9)
      else
         keyin \9
      endif  -- CUA_marking_switch
   else  -- TAB_KEY
      if CUA_marking_switch then
         unmark
      endif  -- CUA_marking_switch
      oldcol=.col
      if matchtab_on and .line>1 then
         up
;;       c=.col  -- Unused ???
         tab_word
         if oldcol>=.col then
            .col=oldcol
            tab
         endif
         down
      else
         tab
      endif
compile if not WANT_TAB_INSERTION_TO_SPACE
      if insertstate() & stream_mode then
         numspc=.col-oldcol
 compile if WANT_DBCS_SUPPORT
         if ondbcs then                                           -- If we're on DBCS,
            if not (matchtab_on and .line>1) then  -- and didn't do a matchtab,
               if words(.tabs) > 1 then
                  if not wordpos(.col, .tabs) then                   -- check if on a tab col.
                     do i=1 to words(.tabs)              -- If we got shifted due to being inside a DBC,
                        if word(.tabs, i) > oldcol then  -- find the col we *should* be in, and
                           numspc = word(.tabs, i) - oldcol  -- set numspc according to that.
                           leave
                        endif
                     enddo
                  endif
               elseif (.col // .tabs) <> 1 then
                  numspc = .tabs - (oldcol+.tabs-1) // .tabs
               endif  -- words(.tabs) > 1
            endif
         endif  -- ondbcs
 compile endif  -- WANT_DBCS_SUPPORT
         if numspc>0 then
            .col=oldcol
            keyin substr('',1,numspc)
         endif
      endif  -- insertstate()
compile endif  -- WANT_TAB_INSERTION_TO_SPACE
   endif  -- TAB_KEY


defc PrevLine, Up
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   universal CUA_marking_switch
   if CUA_marking_switch then
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
   if not .line & stream_mode then '+1'; endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
compile endif

defc MarkUp
compile if TOP_OF_FILE_VALID = 'STREAM'
   universal stream_mode
compile endif
   universal CUA_marking_switch
   startline = .line; startcol = .col
   call updownkey(0)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if CUA_marking_switch then
;compile endif
   if .line then call extend_mark(startline, startcol, 0); endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif
compile if TOP_OF_FILE_VALID = 'STREAM'
   if not .line & stream_mode then '+1'; endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
compile endif

defc DefaultPaste
   universal nepmd_hini
   universal CUA_marking_switch
   KeyPath = '\NEPMD\User\Mouse\Mark\DefaultPaste'
   next = substr( upcase(NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then
      style = 'L'
   elseif next = 'B' then
      style = 'B'
   else
      style = 'C'
   endif
   if CUA_marking_switch then
      call process_mark_like_cua()
   endif
   'paste' style

defc AlternatePaste
   universal nepmd_hini
   universal CUA_marking_switch
   KeyPath = '\NEPMD\User\Mouse\Mark\DefaultPaste'
   next = substr( upcase(NepmdQueryConfigValue( nepmd_hini, KeyPath)), 1, 1)
   if next = 'L' then
      altstyle = 'C'
   elseif next = 'B' then
      altstyle = 'C'
   else
      altstyle = 'L'
   endif
   if CUA_marking_switch then
      call process_mark_like_cua()
   endif
   'paste' altstyle


