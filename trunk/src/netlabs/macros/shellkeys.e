/****************************** Module Header *******************************
*
* Module Name: shellkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: shellkeys.e,v 1.2 2005-03-13 14:36:54 aschn Exp $
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


defproc PromptPos
   shellnum = ''
   if leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
   else
      return 0
   endif
   line = arg(1)
   if line = '' then
      getline line
   endif
compile if not (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   return 1
compile endif
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   x = pos( '>',line)
compile else
   x = pos( ']',line)
compile endif
   text = substr( line, x + 1)
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   if leftstr( line, 5)='epm: ' & x & shellnum /*& text<>''*/ then
compile else
   if leftstr( line, 6)='[epm: ' & x & shellnum /*& text<>''*/ then
compile endif
      return x
   else
      return 0
   endif

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
; ###### Todo: Save .line and .col for every shell separately ######
   universal ShellAppWaiting
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum = substr( .filename, 16)
      if PromptPos() then
         getline line
         x = PromptPos()
         text = substr( line, x + 1)
         if .line = .last then
            .col = x + 1
            erase_end_line
         endif
         'shell_write' shellnum text
      elseif words( ShellAppWaiting) = 2 then
         parse value ShellAppWaiting with lastl lastc
         text = ''
         l = lastl
         do while l <= .line
            getline line, l
            if l = lastl then
               startc = lastc
            else
               startc = 1
            endif
            text = text''substr( line, startc)
            if l = .last then
               insertline '', .last + 1
               leave
            else
               l = l + 1
            endif
         enddo
         'shell_write' shellnum text
      else
         call enter_common(xxx_enterkey)
      endif
   else
      call enter_common(xxx_enterkey)
   endif

compile else

def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter
; ###### Todo: Save .line and .col for every shell separately ######
   universal ShellAppWaiting
   if leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
      if PromptPos() then
         getline line
         x = PromptPos()
         text = substr( line, x + 1)
         if .line = .last then
            .col = x + 1
            erase_end_line
         endif
         'shell_write' shellnum text
      elseif words( ShellAppWaiting) = 2 then
         parse value ShellAppWaiting with lastl lastc
         text = ''
         l = lastl
         do while l <= .line
            getline line, l
            if l = lastl then
               startc = lastc
            else
               startc = 1
            endif
            text = text''substr( line, startc)
            if l = .last then
               insertline '', .last + 1
               leave
            else
               l = l + 1
            endif
         enddo
         'shell_write' shellnum text
      else
         call my_enter()
      endif
   endif

compile endif  -- ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''

def esc
   'shell_commandline'

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

   -- Abandon-Key fr fnc
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


