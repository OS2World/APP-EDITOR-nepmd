/****************************** Module Header *******************************
*
* Module Name: sampactn.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: sampactn.e,v 1.12 2008-09-14 15:32:42 aschn Exp $
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
; This is a Toolbar Actions file.  You add a line to your ACTIONS.LST:
;    sampactn
; to indicate that this should be invoked to build the list of defined
; actions when the user asks for a list (by selecting Create or Edit
; from the toolbar pop-up menu and clicking on the drop-down arrow
; on the Actions page).  EPM loads this .ex file and executes the
; command SAMPACTN_ACTIONLIST (it appends "_ACTIONLIST" to the name of the
; .ex file).  This command must be defined by the actions file to add
; a line to a file for each toolbar-definable action defined in the .ex
; file.

; The line consists of the command to be executed, a description of the
; action, and the name of the .ex file, each separated by a delimiter
; (which is the first character on the line, and can be any character
; otherwise unused on that line; below, an ASCII 1 is used throughout).
; The description is used in the action page description field when
; you edit or create an item of the toolbar. It should explain both what
; the action does, and which parameters it expects.
; No space is wasted because the descriptions below
; are constants which are also used as button selection prompts.

; The action commands (below, "a_messages", etc.) may be called with a
; parameter of "I" to indicate that the menu has been initialized (the user
; pressed MB1 down over this toolbar item, or pressed MB1 down over another
; toolbar item and dragged the mouse over this item, or pressed F10 to go to
; the action bar and scrolled to this toolbar item), "E" for a menu-end message,
; "H" for Help (user pressed F1), or "S" to indicate that the toolbar item
; has been selected.  The parameter might be followed by command parameters
; if the user entered any in the Parameters field of the Actions page.

; Now, the executable portions of the file.  First, include some files to
; define constants that will be needed in this file (yours might not need them):

const
   WANT_DYNAMIC_PROMPTS = 1  -- Force definition of menu prompts in ENGLISH.E.
include 'stdconst.e'
include 'english.e'
include 'menuhelp.h'

; Next, define some additional text constants (defined as separate constants
; instead of using the strings where needed in order to allow for easier NLS
; translation).

const
;  a_Messages_PROMPT = MESSAGES_MENUP__MSG  -- Defined in ENGLISH.E.  Starts with ASCII 1
   a_Add_New__MSG = 'Add New'
   a_Add_New_PROMPT = 'Add a new, .Untitled file to the ring'
   a_Open_empty_PROMPT = \1'Open a new edit window containing .Untitled'
   a_NewWindow_PROMPT = \1'Move current file to new edit window (saving changes, if any)'
;  a_Settings_PROMPT = CONFIG_MENUP__MSG
   a_Time_PROMPT = \1'Display or type the time'
   a_Time_PROMPT2= '.  Parameter = "?" to display, or "I" to insert into file.'
   a_Date_PROMPT = \1'Display or type the date'
   a_Date_PROMPT2= '.  Parameter = "?" to display, or "USA", "European", "Ordered" or "Normal" to insert into file.'
   a_MonoFont_PROMPT = 'Change to a monospaced font, or back to the default font'
;  a_Shell_PROMPT = CREATE_SHELL_MENUP__MSG
   a_Shell_PROMPT2 = '.  Optional parameter is command to be written to new shell window.'
;  a_List_Ring_PROMPT = LIST_FILES_MENUP__MSG
   a_Toggle_Hilight__MSG = 'Keyword highlighting'
   a_Toggle_Hilight_PROMPT = 'Toggle keyword highlighting on or off'
   a_Print__MSG = 'Print'
   a_Match_Brackets_PROMPT = 'Move cursor to matching bracket, #if / #endif, :ol / :eol, /* */, or SGML tag.'
   a_Match_Brackets_PROMPT2 = '(bracket is one of ()[]{}<> )'
   Generic_toolbar_help_title = 'Help for Toolbar selection'
   EXECUTES_COMMAND = 'Executes command:'
   NO_HILIGHT_KNOWN__MSG = "Don't know what keyword highlighting file to use."
   a_Timestamp_PROMPT = \1'Type a timestamp into the file'

EA_comment 'This is a toolbar "actions" file which defines a number of simple commands.'

----------------------- End of MRI for translation ---------------------------------

; Here is the <file_name>_ACTIONLIST command that adds the action commands
; to the list.

defc sampactn_actionlist
   universal ActionsList_FileID  -- This is the fileid that gets the line(s)

   insertline "a_Messages"MESSAGES_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Add_New"a_Add_New_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Add_File"ADD_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Open_empty"a_Open_empty_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_NewWindow"a_NewWindow_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Settings"CONFIG_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Time"a_Time_PROMPT||a_Time_PROMPT2"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Date"a_Date_PROMPT||a_Date_PROMPT2"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_TimeStamp"a_Timestamp_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_MonoFont"a_MonoFont_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Shell"CREATE_SHELL_MENUP__MSG || a_Shell_PROMPT2"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_List_Ring"LIST_FILES_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Compiler_Help"DESCRIBE_COMPILER_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Compiler_Next"NEXT_COMPILER_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Compiler_Prev"PREV_COMPILER_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Proof"PROOF_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Synonym"SYNONYM_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Togl_Hilit"a_Toggle_Hilight_PROMPT"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Print"ENHPRT_FILE_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Save"SAVE_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_SearchDlg"SEARCH_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_UndoDlg"UNDO_REDO_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_Quit"QUIT_MENUP__MSG"sampactn", ActionsList_FileID.last+1, ActionsList_FileID
   insertline "a_match_brackets"a_MATCH_BRACKETS_PROMPT a_MATCH_BRACKETS_PROMPT2"sampactn", ActionsList_FileID.last+1, ActionsList_FileID

; These are the command that will be called for the above actions.  Since all
; actions defined herein resolve to standard commands, the Help doesn't need
; to load an additional help file; it can refer to panels in the standard
; EPM.HLP.

defc a_Messages
   a_common_action( arg(1), 'messagebox', MESSAGES_MENUP__MSG, HP_OPTIONS_MESSAGES)

defc a_Add_New
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_Add_New_PROMPT
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'xcom e /n'                       -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox( a_Add_New__MSG,
                          a_Add_New_PROMPT,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Add_File
   a_common_action( arg(1), 'opendlg EDIT', ADD_MENUP__MSG, HP_FILE_EDIT)

defc a_Open_empty
   -- Changed 'open' to 'open ""' in order to avoid RestoreRing, if activated
   a_common_action( arg(1), 'open ""', a_Open_empty_PROMPT, HP_FILE_OPEN_NEW)

defc a_NewWindow
   a_common_action( arg(1), 'newwindow', a_NewWindow_PROMPT, 1990)

defc a_Settings
   a_common_action( arg(1), 'configdlg', CONFIG_MENUP__MSG, HP_OPTIONS_CONFIG)

defc a_Time
;compile if WANT_DBCS_SUPPORT
   universal countryinfo
;compile endif
;;  a_common_action(arg(1), 'qt', a_Time_PROMPT, 2250)
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_Time_PROMPT
   elseif action_letter = 'S' then   -- button Selected -  execute action
      sayerror 0                        -- Clear prompt
      if abbrev('?', parms, 0) then
         'qt'
      else
;compile if WANT_DBCS_SUPPORT  -- We're not including MYCNF.E...
        if countryinfo then    -- Instead, see if countryinfo has been set.
         time_sep = substr( countryinfo, 24, 1)
        else
         time_sep = ':'
        endif
         parse value gettime(0) with ':' mm ':' ss . ';' h24 ':'
         keyin h24 || time_sep || mm || time_sep || ss' '
;compile else
;         parse value gettime(0) with ':' mmss . ';' h24 ':'
;         keyin h24':'mmss
;compile endif
      endif
   elseif action_letter = 'H' then   -- button Help
      'helpmenu 2250'
;  elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Date
;  a_common_action(arg(1), 'qd', a_Date_PROMPT, 2240)
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_Date_PROMPT
   elseif action_letter = 'S' then   -- button Selected -  execute action
      sayerror 0                        -- Clear prompt
      if abbrev('?', parms, 0) then
         'qd'
      else
         parse value getdate(0) with WeekDay Month Day ', ' Year';'MonthNum
         parms = upcase(parms)
         if abbrev('USA', parms, 1) then
            keyin monthnum'/'rightstr(day, 2, 0)'/'rightstr(year, 2)' '
         elseif abbrev('EUROPEAN', parms, 1) then
            keyin day'/'rightstr(monthnum, 2, 0)'/'rightstr(year, 2)' '
         elseif abbrev('ORDERED', parms, 1) then
            keyin rightstr(year, 2)'/'rightstr(monthnum, 2, 0)'/'rightstr(day, 2, 0)' '
         else
            keyin day leftstr(month, 3) year' '   -- 7 March 1995
         endif
      endif
   elseif action_letter = 'H' then   -- button Help
      'helpmenu 2240'
;  elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_TimeStamp
   a_common_action( arg(1), 'TimeStamp', a_TimeStamp_PROMPT, 0)

defc a_Quit
   a_common_action( arg(1), 'quit', QUIT_MENUP__MSG, HP_FILE_QUIT)

defc a_MonoFont
   universal default_font
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_MonoFont_PROMPT
   elseif action_letter = 'S' then   -- button Selected -  execute action
      sayerror 0                        -- Clear prompt
      parse value queryfont(.font) with fontname '.'
      if fontname='System Monospaced' then
         .font = default_font
      else
         'monofont'
      endif
   elseif action_letter = 'H' then   -- button Help
      'helpmenu 1991'
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Shell
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' substr( CREATE_SHELL_MENUP__MSG, 2)
   elseif action_letter = 'S' then   -- button Selected
      if isadefc('shell') then
         sayerror 0                        -- Clear prompt
         'shell new' parms                 -- execute action
      else
         sayerror 'EPM was compiled without WANT_EPM_SHELL = 1; SHELL command not available.'
      endif
   elseif action_letter = 'H' then   -- button Help
      'helpmenu' HP_COMMAND_SHELL
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_List_Ring
   a_common_action( arg(1), 'ring_more', LIST_FILES_MENUP__MSG, HP_OPTIONS_LIST)

defc a_Compiler_Help
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' substr(DESCRIBE_COMPILER_MENUP__MSG, 2)
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'compiler_help'                   -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox( DESCRIBE_COMPILER_MENU__MSG,
                          DESCRIBE_COMPILER_MENUP__MSG,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Compiler_Next
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' substr( NEXT_COMPILER_MENUP__MSG, 2)
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'nextbookmark N 16'               -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox( NEXT_COMPILER_MENU__MSG,
                          NEXT_COMPILER_MENUP__MSG,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Compiler_Prev
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' substr( PREV_COMPILER_MENUP__MSG, 2)
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'nextbookmark P 16'               -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox( PREV_COMPILER_MENU__MSG,
                          PREV_COMPILER_MENUP__MSG,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Proof
   a_common_action( arg(1), 'proof', PROOF_MENUP__MSG, HP_OPTIONS_PROOF)

defc a_Synonym
   a_common_action( arg(1), 'syn', SYNONYM_MENUP__MSG, HP_OPTIONS_SYN)

defc a_togl_hilit
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      -- Query keyword highlighting state (windowmessage returns 0, 1 or 2)
      -- from defc qparse (commented out) in STDCTRL.E:
      current_hili = windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                                    5505,          -- EPM_EDIT_KW_QUERYPARSE
                                    0,
                                    0)
      new_hili = (current_hili = 0)
      -- Toggle keyword highlighting
      --    The following makes EPM crash during repeated toggeling for about
      --    100 .e files in the ring:
      --call NepmdActivateHighlight( new_hili, GetMode())
      --    A command is probably executed somehow delayed, compared to a
      --    proc, so that the following fixes it in more cases:
      --'ActivateHighlighting' new_hili
      --    Postme is required, when highlighting is toggled repeatedly for a
      --    huge ring:
      'postme ActivateHighlighting' new_hili
   elseif arg(1) = 'I' then   -- button Initialized
      'SayHint' a_Toggle_Hilight_PROMPT
   elseif arg(1) = 'H' then   -- button Help
      call winmessagebox( a_Toggle_Hilight__MSG,
                          a_Toggle_Hilight_PROMPT,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc a_print
   a_common_action( arg(1), 'printdlg', ENHPRT_FILE_MENUP__MSG, HP_FILE_ENHPRINT)

defc a_save
   a_common_action( arg(1), 'save', SAVE_MENUP__MSG, HP_FILE_SAVE)

defc a_searchdlg
   a_common_action( arg(1), 'searchdlg', SEARCH_MENUP__MSG, HP_SEARCH_SEARCH)

defc a_undodlg
   a_common_action( arg(1), 'undodlg', UNDO_REDO_MENUP__MSG, HP_EDIT_UNDOREDO)

defc a_match_brackets
   parse value arg(1) with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' a_Match_Brackets_PROMPT
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      'assist'
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox( Generic_toolbar_help_title,
                          a_Match_Brackets_PROMPT a_Match_Brackets_PROMPT2,
                          MB_OK + MB_INFORMATION + MB_MOVEABLE)
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

defproc a_common_action( arg1, command, prompt, panel)
   parse value arg1 with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      'SayHint' substr( prompt, 2)    -- All the prompts in ENGLISH.E start with an ASCII 1.
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      command parms
   elseif action_letter = 'H' then   -- button Help
      if panel then
         'helpmenu' panel
      else
         call winmessagebox( Generic_toolbar_help_title,
                             substr( prompt, 2)\n\n || EXECUTES_COMMAND\ncommand,
                             MB_OK + MB_INFORMATION + MB_MOVEABLE)
      endif
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

