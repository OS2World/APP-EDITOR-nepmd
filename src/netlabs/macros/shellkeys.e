/****************************** Module Header *******************************
*
* Module Name: shellkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: shellkeys.e,v 1.3 2005-03-29 20:49:06 aschn Exp $
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

; Extend this keyset with e.g.
;    'ModeExecute SHELL SetKeys shell_keys'           <-- standard, already present
;    'ModeExecute SHELL SetKeys myadd_shell_keys'     <-- additions
;
; Therefore your myaddshellkeys keyset should be defined with 'overlay'
; (default if 'new' or 'clear' not present):
;    defkeys myadd_shell_keys overlay
;    def ...
;    def ...

; Consts concerning with shell:
; EPM_SHELL_PROMPT = '@prompt epm: $p $g'
; WANT_EPM_SHELL = 1

; ---------------------------------------------------------------------------
; Tab must not be defined as accelerator key, because otherwise
; lastkey(2) and lastkey(3) would return wrong values for Tab.
; lastkey() = lastkey(0) and lastkey(1) for Tab doesn't work in EPM!
; When Sh is pressed, lastkey() is set to Sh. While Sh is down and
; Tab is pressed additionally, lastkey is set to Sh+Tab and lastkey(2)
; is set to Sh. Therefore querying lastkey(2) to determine if Tab was
; pressed before doesn't work for any key combination!
defc TabComplete
   universal shellfnc_starting_keyset
   if .keyset <> 'SHELLFNC_KEYS' then
      shellfnc_starting_keyset = upcase(.keyset)
      'SetKeys shellfnc_keys'
      'deleteaccel'  -- required to reset really all keys
      -- Block actionbar accelerators and alt keys doesn't work now!
      'ShellFncInit'
   endif
   'ShellFncComplete'

; ---------------------------------------------------------------------------
defc ShTabComplete
   universal shellfnc_starting_keyset
   if .keyset <> 'SHELLFNC_KEYS' then
      shellfnc_starting_keyset = upcase(.keyset)
      'SetKeys shellfnc_keys'
      'deleteaccel'  -- required to reset really all keys
      -- Block actionbar accelerators and alt keys doesn't work now!
      'ShellFncInit'
   endif
   'ShellFncComplete -'

; ---------------------------------------------------------------------------
; Define an own keyset for filename completion:
defkeys shellfnc_keys new clear  -- start with an empty keyset

def tab
   'TabComplete'

def s_tab
   'ShTabComplete'

-- Any other key will leave the SHELLFNC_KEYS keyset
def otherkeys
   universal shellfnc_starting_keyset
   k = lastkey()
;    if length(k) = 1 then
;       ch = 'chr('asc(k)')'
;    else
;       ch = "x'"rightstr( itoa( leftstr( k, 1)\0,   16), 2, 0) ||
;                rightstr( itoa( substr( k, 2, 1)\0, 16), 2, 0)"'"
;    endif
;    sayerror ch
   -- Ignore the following keys
   if     k = \10\18 then  -- Ctrl
   elseif k = \09\10 then  -- Shift
   elseif k = \11\34 then  -- Alt
   elseif k = \12\02 then  -- AltGr (right Alt)
   else
      'SetKeys' shellfnc_starting_keyset
      'loadaccel'
      --sayerror 'Back to keyset' .keyset
      executekey k
   endif

; ---------------------------------------------------------------------------
defkeys shell_keys overlay  -- we want to keep old key defs

; Moved from ENTER.E:

compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately

def enter =
   universal enterkey
 compile if (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(enterkey)
 compile endif

def padenter =
   universal padenterkey
 compile if (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(padenterkey)
 compile endif

defproc shell_enter_routine(xxx_enterkey)
   if leftstr(.filename, 15) = ".command_shell_" then
      rc = ShellEnterWrite()
      if rc then
         rc = ShellEnterWriteToApp()
      endif
      if rc then
         call enter_common(xxx_enterkey)
      endif
   else
      call enter_common(xxx_enterkey)
   endif

compile else

def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter
   if leftstr( .filename, 15) = '.command_shell_' then
      rc = ShellEnterWrite()
      if rc then
         rc = ShellEnterWriteToApp()
      endif
      if rc then
         call my_enter()
      endif
   endif

compile endif  -- ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''

; Not used anymore, since we can always write directly into the shell window:
;def esc
;   'shell_commandline'

def tab
   'TabComplete'

def s_tab
   'ShTabComplete'

; From Joerg Tiemann's SHELLKRAM.E:

   -- Send 'y' for yes to cmd.exe
   def a_y =
      'Shell_SendKey Y'

   -- Send 'n' for no to cmd.exe
   def a_n =
      'Shell_SendKey N'

/*
   -- Filename Completion
   def tab, s_tab =
      'Filename_Completion'

   -- Abandon-Key f�r fnc
   def a_a =  -- s_pad5 doesn't work
      'Abandon_fnc'
*/

   -- invoke history window
   def a_h =
      'Shell_History'

   -- Write to Shell Hotkey
   def a_i =
      'Shell_write' -- without params it first checks, if the current
                    -- file is a shell window, then opens the
                    -- Write-to-shell box.

   -- jump to the previous prompt
   def c_up =
       executekey up
       'xcom l /^epm\: [^>]*>:o\c/x-'
       refresh

   -- jump to the next prompt
   def c_down =
       executekey down
       'xcom l /^epm\: [^>]*>:o\c/x+'
       refresh

;    and now step for step explained
;    /^epm\: [^>]*>:o\c/x+
;
;    /      begin of pattern
;    ^      begin of line
;    epm    epm
;    \:     colon
;    [^>]   any key except ">"
;    *      none - many of the previous
;    >      >
;    :o     optional whitespace
;    \c     places cursor behind whitespace
;    /      end of pattern
;    x      extended grep
;    +      search forward
;    -      search backward

