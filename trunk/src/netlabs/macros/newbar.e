/****************************** Module Header *******************************
*
* Module Name: newbar.e
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

const
   SAVEORSAVEAS_PROMPT   = 'Save, open Save-as dialog if file was not changed'
   RELOAD_PROMPT         = 'Reload file from disk (revert), ask if file was changed'
   OPENFOLDER_PROMPT     = 'Open folder of file'
   CUT_PROMPT            = 'Cut: copy mark to clipboard and delete it'
   COPY_PROMPT           = 'Copy mark to clipboard'
   PASTECHARS_PROMPT     = 'Paste: insert text from clipboard as chars'
   TOGGLESOFTWRAP_PROMPT = 'Toggle soft wrap: break/concatenate lines without adding lineend chars on save'
   SHELL_PROMPT          = 'Shell: switch to or create an EPM shell'
   RUN_PROMPT            = 'Run: execute an action for the current file, according to defs in RUN.ERX'

; ---------------------------------------------------------------------------
; The defc <exfilebasename>_actionlist is executed by defc load_actions:
; load_actions links every .ex file, that is listed in actions.lst. After
; linking, <exfilebasename>_actionlist is executed in order to add an action
; line to the hidden file .actlist. It is created when a user edits or
; creates a toolbar menu item the first time.
defc newbar_actionlist
   'TB_SaveOrSaveAs ACTIONLIST'
   'TB_Reload ACTIONLIST'
   'TB_OpenFolder ACTIONLIST'
   'TB_Cut ACTIONLIST'
   'TB_Copy ACTIONLIST'
   'TB_PasteChars ACTIONLIST'
   'TB_SoftWrap ACTIONLIST'
   'TB_Shell ACTIONLIST'
   'TB_Run ACTIONLIST'

; ---------------------------------------------------------------------------
; Define current file. This is used for every defc TB_* here.
define
   EXFILE = 'newbar'

; ---------------------------------------------------------------------------
defc TB_SaveOrSaveAs
   Action  = 'TB_SaveOrSaveAs'
   Command = 'SaveOrSaveAs'
   Prompt  = SAVEORSAVEAS_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_Reload
   Action  = 'TB_Reload'
   Command = 'Revert'
   Prompt  = RELOAD_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_OpenFolder
   Action  = 'TB_OpenFolder'
   Command = 'OpenFolder OPEN=DEFAULT'
   Prompt  = OPENFOLDER_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_Cut
   Action  = 'TB_Cut'
   Command = 'Cut'
   Prompt  = CUT_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_Copy
   Action  = 'TB_Copy'
   Command = 'Copy2Clip'
   Prompt  = COPY_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_PasteChars
   Action  = 'TB_PasteChars'
   Command = 'Paste C'
   Prompt  = PASTECHARS_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_SoftWrap
   Action  = 'TB_SoftWrap'
   Command = 'ToggleWrap'
   Prompt  = TOGGLESOFTWRAP_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_Shell
   Action  = 'TB_Shell'
   Command = 'Shell'
   Prompt  = SHELL_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

defc TB_Run
   Action  = 'TB_Run'
   Command = 'rx Run'
   Prompt  = RUN_PROMPT
   Help    = ''  -- Additional prompt or a help panel id
   Title   = ''  -- Title of the help message box (if no help panel id)
   call ToolbarAction( arg(1), EXFILE, Action, Command, Prompt, Help, Title)

