/****************************** Module Header *******************************
*
* Module Name: shellkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
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

const
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
;  EPM_SHELL_PROMPT = '@prompt [epm: $p ] '  -- Also supported
compile endif

; ---------------------------------------------------------------------------
defc ShellNewLine
   StdNewLine = arg(1)
   fExecStdNewLine = 0

compile if not (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   fExecStdNewLine = 1
compile endif

   if IsAShell() then
      rc = ShellEnterWrite()
      if rc then
         rc = ShellEnterWriteToApp()
      endif
      if rc then
         fExecStdNewLine = 1
      endif
   else
      fExecStdNewLine = 1
   endif

   if fExecStdNewLine then
      StdNewLine
   endif

; ---------------------------------------------------------------------------
defc ShellTab
   universal nepmd_hini
   universal prevkey
   parse value prevkey with PrevKeyName \1 .
   KeyPath = '\NEPMD\User\Shell\FilenameCompletion'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   if on then
      if wordpos( PrevKeyName, 'tab s_backtab') = 0  then
         'ShellFncInit'
      endif
      'ShellFncComplete'
   else
      'Tab'      -- standard definition, keep in sync with STDKEYS.E or
   endif         -- additional keyset definitions

; ---------------------------------------------------------------------------
defc ShellBackTab
   universal nepmd_hini
   universal prevkey
   parse value prevkey with PrevKeyName \1 .
   KeyPath = '\NEPMD\User\Shell\FilenameCompletion'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) <> 0)
   if on then
      if wordpos( PrevKeyName, 'tab s_backtab') = 0  then
         'ShellFncInit'
      endif
      'ShellFncComplete -'
   else
      'BackTab'  -- standard definition, keep in sync with STDKEYS.E or
   endif         -- additional keyset definitions

; ---------------------------------------------------------------------------
defc ShellGotoPrevPrompt
   executekey up
   'xcom l /^epm\: [^>]*>:o\c/x-'
   refresh

defc ShellGotoNextPrompt
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

; ---------------------------------------------------------------------------
defc ShellKeys

; ---- Tab ----
DefKey( 'tab'      , 'ShellTab'              )
DefKey( 's_backtab', 'ShellBackTab'          )

; ---- Enter ----
DefKey( 'newline'  , 'ShellNewLine StdNewLine')
DefKey( 'enter'    , 'ShellNewLine StdEnter'  )

; From Joerg Tiemann's SHELLKRAM.E:

; Invoke history window
DefKey( 'a_h'      , 'Shell_History'         )

; Write-to-Shell hotkey
DefKey( 'a_i'      , 'Shell_write'           )
                     -- without params it first checks, if the current
                     -- file is a shell window, then opens the
                     -- Write-to-shell box.

; Jump to the prompt
DefKey( 'c_up'     , 'ShellGotoPrevPrompt'   )
DefKey( 'c_down'   , 'ShellGotoNextPrompt'   )


