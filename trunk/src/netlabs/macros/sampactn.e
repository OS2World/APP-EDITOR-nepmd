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
   a_common_action(arg(1), 'messagebox', MESSAGES_MENUP__MSG, HP_OPTIONS_MESSAGES)

defc a_Add_New
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror a_Add_New_PROMPT
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'xcom e /n'                       -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox(a_Add_New__MSG, a_Add_New_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Add_File
   a_common_action(arg(1), 'opendlg EDIT', ADD_MENUP__MSG, HP_FILE_EDIT)

defc a_Open_empty
   a_common_action(arg(1), 'open', a_Open_empty_PROMPT, HP_FILE_OPEN_NEW)

defc a_NewWindow
   a_common_action(arg(1), 'newwindow', a_NewWindow_PROMPT, 1990)

defc a_Settings
   a_common_action(arg(1), 'configdlg', CONFIG_MENUP__MSG, HP_OPTIONS_CONFIG)

defc a_Time
;compile if WANT_DBCS_SUPPORT
   universal countryinfo
;compile endif
;;  a_common_action(arg(1), 'qt', a_Time_PROMPT, 2250)
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror a_Time_PROMPT
      display 8
   elseif action_letter = 'S' then   -- button Selected -  execute action
      sayerror 0                        -- Clear prompt
      if abbrev('?', parms, 0) then
         'qt'
      else
;compile if WANT_DBCS_SUPPORT  -- We're not including MYCNF.E...
        if countryinfo then    -- Instead, see if countryinfo has been set.
 compile if EPM32
         time_sep = substr(countryinfo,24,1)
 compile else
         time_sep = substr(countryinfo,18,1)
 compile endif
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
      display -8
      sayerror a_Date_PROMPT
      display 8
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
   a_common_action(arg(1), 'TimeStamp', a_TimeStamp_PROMPT, 0)

defc a_Quit
   a_common_action(arg(1), 'quit', QUIT_MENUP__MSG, HP_FILE_QUIT)

defc a_MonoFont
   universal default_font
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror a_MonoFont_PROMPT
      display 8
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
      display -8
      sayerror substr(CREATE_SHELL_MENUP__MSG, 2)
      display 8
   elseif action_letter = 'S' then   -- button Selected
      if isadefc('shell') then
         sayerror 0                        -- Clear prompt
         'shell' parms                     -- execute action
      else
         sayerror 'EPM was compiled without WANT_EPM_SHELL = 1; SHELL command not available.'
      endif
   elseif action_letter = 'H' then   -- button Help
      'helpmenu' HP_COMMAND_SHELL
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_List_Ring
   a_common_action(arg(1), 'ring_more', LIST_FILES_MENUP__MSG, HP_OPTIONS_LIST)

defc a_Compiler_Help
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror substr(DESCRIBE_COMPILER_MENUP__MSG, 2)
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'compiler_help'                   -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox(DESCRIBE_COMPILER_MENU__MSG, DESCRIBE_COMPILER_MENUP__MSG, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Compiler_Next
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror substr(NEXT_COMPILER_MENUP__MSG, 2)
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'nextbookmark N 16'               -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox(NEXT_COMPILER_MENU__MSG, NEXT_COMPILER_MENUP__MSG, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Compiler_Prev
   parse arg action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror substr(PREV_COMPILER_MENUP__MSG, 2)
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0                        -- Clear prompt
      'nextbookmark P 16'               -- execute action
   elseif action_letter = 'H' then   -- button Help
;;    'helpmenu' ???                     -- No help panel for this; use a messagebox
      call winmessagebox(PREV_COMPILER_MENU__MSG, PREV_COMPILER_MENUP__MSG, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0                        -- (We don't do anything for this one; get lots of them.)
   endif

defc a_Proof
   a_common_action(arg(1), 'proof', PROOF_MENUP__MSG, HP_OPTIONS_PROOF)

defc a_Synonym
   a_common_action(arg(1), 'syn', SYNONYM_MENUP__MSG, HP_OPTIONS_SYN)

defc a_togl_hilit
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      color_file=''
      ext=filetype()
      if wordpos(ext, 'ADA ADB ADS') then
         color_file= 'EPMKWDS.ADA'
      elseif wordpos(ext, 'C H SQC CPP HPP CXX HXX') then
         color_file= 'EPMKWDS.C'
      elseif wordpos(ext, 'CMD BAT EXC EXEC XEDIT ERX REX REXX VRX') then
         if .last then
            line = upcase(textline(1))
         else
            line = ''
         endif
         if word(line,1)='EXTPROC' & pos('PERL', line) then
            color_file='EPMKWDS.PL'
         else
            color_file='EPMKWDS.CMD'
         endif
      elseif ext='E' then
         color_file= 'EPMKWDS.E'
      elseif wordpos(ext, 'HTM HTML') then
         color_file= 'EPMKWDS.HTM'
      elseif wordpos(ext, 'FOR FORTRAN F90') then
         color_file= 'EPMKWDS.F90'
      elseif ext='IPF' then
         color_file= 'EPMKWDS.IPF'
      elseif ext='JAVA' then
         color_file= 'EPMKWDS.JAV'
      elseif (upcase(rightstr(.filename,8))='MAKEFILE' | ext='MAK') then
         color_file='EPMKWDS.MAK'
      elseif wordpos(ext, 'PL PRL PERL') then
         color_file='EPMKWDS.PL'
      elseif ext='RC' then
         color_file= 'EPMKWDS.RC'
      elseif ext='RXP' then
         color_file= 'EPMKWDS.RXP'
 compile if defined(my_SCRIPT_FILE_TYPE)
      elseif wordpos(ext, 'SCR SCT SCRIPT' my_SCRIPT_FILE_TYPE) then
 compile else
      elseif wordpos(ext, 'SCR SCT SCRIPT') then
 compile endif
         color_file='EPMKWDS.SCR'
 compile if defined(TEX_FILETYPES)
      elseif wordpos(ext, TEX_FILETYPES) then
 compile else
      elseif wordpos(ext, 'TEX LATEX STY CLS DTX') then  -- Include TeX styles and LaTeX classes
 compile endif
         color_file= 'EPMKWDS.TEX'
      else
         findfile color_file, 'EPMKWDS.'ext, '', 'D'
         if rc then
            sayerror NO_HILIGHT_KNOWN__MSG
            return
         endif
      endif
      current_toggle = windowmessage(1,  getpminfo(EPMINFO_EDITFRAME),
                                     5505,          -- EPM_EDIT_KW_QUERYPARSE
                                     0,
                                     0)
      'toggle_parse' (not current_toggle) color_file
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror a_Toggle_Hilight_PROMPT
      display 8
   elseif arg(1) = 'H' then   -- button Help
      call winmessagebox(a_Toggle_Hilight__MSG, a_Toggle_Hilight_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc a_print
   a_common_action(arg(1), 'printdlg', ENHPRT_FILE_MENUP__MSG, HP_FILE_ENHPRINT)

defc a_save
   a_common_action(arg(1), 'save', SAVE_MENUP__MSG, HP_FILE_SAVE)

defc a_searchdlg
   a_common_action(arg(1), 'searchdlg', SEARCH_MENUP__MSG, HP_SEARCH_SEARCH)

defc a_undodlg
   a_common_action(arg(1), 'undodlg', UNDO_REDO_MENUP__MSG, HP_EDIT_UNDOREDO)

defc a_match_brackets
   parse value arg(1) with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror a_Match_Brackets_PROMPT
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      call passist()
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(Generic_toolbar_help_title, a_Match_Brackets_PROMPT a_Match_Brackets_PROMPT2, MB_OK + MB_INFORMATION + MB_MOVEABLE)
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

defproc a_common_action(arg1, command, prompt, panel)
   parse value arg1 with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror substr(prompt, 2)  -- All the prompts in ENGLISH.E start with an ASCII 1.
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      command parms
   elseif action_letter = 'H' then   -- button Help
      if panel then
         'helpmenu' panel
      else
         call winmessagebox(Generic_toolbar_help_title, substr(prompt, 2)\n\n || EXECUTES_COMMAND\ncommand, MB_OK + MB_INFORMATION + MB_MOVEABLE)
      endif
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

