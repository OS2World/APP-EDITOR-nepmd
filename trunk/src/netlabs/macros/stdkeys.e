/****************************** Module Header *******************************
*
* Module Name: stdkeys.e
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

defc StdKeys

; ---- Cursor ----
DefKey( 'c_home'       , 'BeginFile'       )    -- Go to begin of file
DefKey( 'c_end'        , 'EndFile'         )    -- Go to end of file
DefKey( 'c_f5'         , 'BeginWord'       )    -- Go to first char in current word
DefKey( 'c_f6'         , 'EndWord'         )    -- Go to last char in current word
DefKey( 'c_left'       , 'PrevWord'        )    -- Go to previous word
DefKey( 'c_right'      , 'NextWord'        )    -- Go to next word
DefKey( 'left'         , 'PrevChar'        )    -- Go to previous char
DefKey( 'right'        , 'NextChar'        )    -- Go to next char
DefKey( 'up'           , 'Up'              )    -- Go to previous line
DefKey( 'down'         , 'Down'            )    -- Go to next line
;DefKey( 'home'         , 'BeginLine'       )    -- Go to begin of line
DefKey( 'home'         , 'BeginLineOrText' )    -- Go to begin of line or text
;DefKey( 'end'          , 'EndLine'         )    -- Go to end of line
DefKey( 'end'          , 'EndLineOrAfter'  )    -- Go to end of line or to the starting col after it
DefKey( 'pageup'       , 'PageUp'          )    -- Go to previous page
DefKey( 'pagedown'     , 'PageDown'        )    -- Go to next page
DefKey( 'c_pageup'     , 'BeginScreen'     )    -- Go to first line on screen
DefKey( 'c_pagedown'   , 'EndScreen'       )    -- Go to last line on screen
DefKey( 'c_up'         , 'PopPos'          )    -- Go to last pos. of cursor stack
DefKey( 'c_down'       , 'PushPos'         )    -- Add current cursor pos. to cursor stack
DefKey( 'c_='          , 'SwapPos'         )    -- Exchange current cursor pos. with last pos. of stack
DefKey( 'c_s_='        , 'SwapPos'         )    -- Exchange current cursor pos. with last pos. of stack
DefKey( 'c_0'          , 'SwapPos'         )    -- Exchange current cursor pos. with last pos. of stack
DefKey( 'a_-'          , 'HighlightCursor' )    -- Draw a circle around cursor
DefKey( 'a_e'          , 'EndMark'         )    -- Go to end of mark
DefKey( 'a_y'          , 'BeginMark'       )    -- Go to begin of mark

; ---- Scroll ----
DefKey( 's_f1'         , 'ScrollLeft'      )    -- Scroll text left
DefKey( 's_f2'         , 'ScrollRight'     )    -- Scroll text right
DefKey( 's_f3'         , 'ScrollUp'        )    -- Scroll text up
DefKey( 's_f4'         , 'ScrollDown'      )    -- Scroll text down
DefKey( 's_f5'         , 'CenterLine'      )    -- V-center current line
;DefKey( 'c_a'          , 'NewTop'          )    -- Make current line topmost

; ---- Mark ----
DefKey( 'a_b'          , 'MarkBlock'       )    -- Start/end block mark
DefKey( 'a_l'          , 'MarkLine'        )    -- Start/end line mark
DefKey( 'a_z'          , 'MarkChar'        )    -- Start/end char mark
DefKey( 'a_w'          , 'MarkToken'       )    -- Mark current word, separators according to C syntax
DefKey( 'a_s_w'        , 'MarkWord'        )    -- Mark current word
DefKey( 'a_u'          , 'UnMark'          )    -- Unmark all
DefKey( 'c_\'          , 'UnMark'          )    -- Unmark all
DefKey( 'c_s_a'        , 'UnMark'          )    -- Unmark all
DefKey( 'c_a'          , 'Select_All'      )    -- Mark all
DefKey( 'c_/'          , 'Select_All'      )    -- Mark all
DefKey( 's_left'       , 'MarkPrevChar'    )    -- Mark from cursor to previous char
DefKey( 's_right'      , 'MarkNextChar'    )    -- Mark from cursor to next char
DefKey( 's_up'         , 'MarkUp'          )    -- Mark from cursor line up
DefKey( 's_down'       , 'MarkDown'        )    -- Mark from cursor line down
DefKey( 's_home'       , 'MarkBeginLineOrText') -- Mark from cursor to begin of line or text
DefKey( 's_end'        , 'MarkEndLineOrAfter' ) -- Mark from cursor to end of line
;DefKey( 's_home'       , 'MarkBeginLine'   )    -- Mark from cursor to begin of line
DefKey( 'c_s_home'     , 'MarkBeginFile'   )    -- Mark from cursor to begin of file
DefKey( 'c_s_end'      , 'MarkEndFile'     )    -- Mark from cursor to end of file
DefKey( 's_pageup'     , 'MarkPageUp'      )    -- Mark from cursor page up
DefKey( 's_pagedown'   , 'MarkPageDown'    )    -- Mark from cursor page down
DefKey( 'c_s_pageup'   , 'MarkBeginScreen' )    -- Mark from cursor to first line on screen
DefKey( 'c_s_pagedown' , 'MarkEndScreen'   )    -- Mark from cursor to last line on screen
DefKey( 'c_s_up'       , 'PopMark'         )    -- Restore last mark from stack (and remove it from stack)
DefKey( 'c_s_down'     , 'PushMark'        )    -- Save current mark to mark stack
DefKey( 'c_s_-'        , 'SwapMark'        )    -- Exchange current mark with last mark from stack
DefKey( 'c_s_+'        , 'SwapMark'        )    -- Exchange current mark with last mark from stack

; ---- Mark operations ----
DefKey( 'a_c'          , 'CopyMark'        )    -- Copy mark
DefKey( 'a_d'          , 'DeleteMark'      )    -- Delete mark
DefKey( 'a_m'          , 'MoveMark'        )    -- Move mark
DefKey( 'a_o'          , 'OverlayMark'     )    -- Copy block
DefKey( 'a_a'          , 'AdjustMark'      )    -- Move block
DefKey( 'a_t'          , 'CenterMark'      )    -- Center text in mark
DefKey( 'a_f'          , 'FillMark'        )    -- Open dialog to specify a char as fill char
DefKey( 'c_f7'         , 'ShiftLeft'       )    -- Move text in mark 1 col left
DefKey( 'c_f8'         , 'ShiftRight'      )    -- Move text in mark 1 col right
DefKey( 'c_y'          , 'FontList'        )    -- Open style dialog to add font attributes to mark
DefKey( 'c_s_y'        , 'linkexec stylebut apply_style S')  -- Open list box for selecting a style

; ---- Delete ----
DefKey( 'delete'       , 'DeleteChar'      )    -- Delete current char
DefKey( 'backspace'    , 'BackSpace'       )    -- Delete previous char (Shift marks)
DefKey( 's_backspace'  , 'BackSpace'       )    -- Delete previous char (Shift marks)
DefKey( 'c_backspace'  , 'DeleteLine'      )    -- Delete current line
DefKey( 'c_delete'     , 'DeleteUntilNextWord') -- Delete from cursor until beginning of next word
DefKey( 'c_d'          , 'DeleteUntilNextWord') -- Delete from cursor until beginning of next word
DefKey( 'c_s_delete'   , 'DeleteUntilEndLine')  -- Delete from cursor until end of line
DefKey( 'c_e'          , 'DeleteUntilEndLine')  -- Delete from cursor until end of line

; ---- Search ----
DefKey( 'c_s'          , 'SearchDlg'       )    -- Open search dialog
DefKey( 'c_f'          , 'RepeatFind'      )    -- Repeat find
DefKey( 'c_c'          , 'RepeatChange'    )    -- Repeat change
DefKey( 'c_v'          , 'RepeatFindAllFiles'   )  -- Repeat find in all files of the ring
DefKey( 'c_-'          , 'ToggleSearchDirection')  -- Toggle search direction
DefKey( 'c_w'          , 'FindToken'       )    -- Find current word, separators according to C syntax
DefKey( 'c_s_w'        , 'FindWord'        )    -- Find current word
DefKey( 'c_s_m'        , 'FindMark'        )    -- Find mark
DefKey( 'c_s_d'        , 'FindDef'         )    -- Find definition for current word

; ---- Clipboard ----
DefKey( 's_delete'     , 'Cut'             )    -- Copy mark to clipboard and delete
DefKey( 's_insert'     , 'DefaultPaste'    )    -- Default paste (paste as chars, selectable)
DefKey( 'c_insert'     , 'Copy2Clip'       )    -- Copy mark to clipboard
DefKey( 'c_s_insert'   , 'AlternatePaste'  )    -- Alternate paste (paste as lines, depends on default paste)

; ---- Execute ----
DefKey( 'c_i'          , 'CommandLine'     )    -- Open Command dialog
DefKey( 'esc'          , 'ProcessEscape'   )    -- Open Command dialog or stop block reflow
DefKey( 'a_0'          , 'dolines'         )    -- Execute line under cursor
DefKey( 'a_='          , 'dolines'         )    -- Execute line under cursor
DefKey( 'a_s_='        , 'dolines'         )    -- Execute line under cursor
DefKey( 'c_l'          , 'CommandDlgLine'  )    -- Open current line in Command dialog
DefKey( 'c_break'      , 'ProcessBreak'    )    -- This is already internally defined and added here to make MenuAccelString() work

; ---- File operations ----
DefKey( 'a_f2'         , 'SaveAs_Dlg'      )    -- Open the Save-as dialog
DefKey( 'f2'           , 'Save'            )    -- Save
;DefKey( 'f2'           , 'SmartSave'       )    -- Save; if unchanged: give message
DefKey( 'f3'           , 'Quit'            )    -- Quit file
DefKey( 'f4'           , 'File'            )    -- Save and quit file
;DefKey( 'f4'           , 'FileOrQuit'      )    -- Save and quit file; if unchanged: just quit
DefKey( 'f5'           , 'OpenDlg'         )    -- Open File-open dialog (will open file in a new window)
DefKey( 'c_o'          , 'EditFileDlg'     )    -- Open File-edit dialog (will open file in the same window)
DefKey( 'f7'           , 'Rename'          )    -- Open Rename entrybox
DefKey( 'f8'           , 'EditFileDlg'     )    -- Open File-edit dialog (will open file in the same window)
DefKey( 'c_s_f9'       , 'History edit'    )    -- Open Edit history listbox
DefKey( 'c_s_f10'      , 'History load'    )    -- Open Load history listbox
DefKey( 'c_s_f11'      , 'History save'    )    -- Open Save history listbox

; ---- Special chars ----
DefKey( 'a_f1'         , 'TypeFrameChars'  )    -- Type a list of IBM frame chars (help for the draw and box commands)
;DefKey( 'a_n'          , 'TypeFileName'    )    -- Type the full filename
DefKey( 'c_2'          , 'TypeAscChars \0' )    -- Type a null char (\0)
DefKey( 'c_6'          , 'TypeAscChars \170')   -- Type a not char � (\170)
DefKey( 'c_9'          , 'TypeChars {'     )    -- Type a {
;DefKey( 'c_0'          , 'TypeChars }'     )    -- Type a }
DefKey( 'c_4'          , 'TypeAscChars \155')   -- Type a cent char � (\155)
DefKey( 'c_tab'        , 'TypeAscChars \9' )    -- Type a tab char (\9)

; ---- Window and File switching ----
DefKey( 'f11'          , 'PrevFile'        )    -- Switch to previous file
;DefKey( 'c_p'          , 'PrevFile'        )    -- Switch to previous file
DefKey( 'f12'          , 'NextFile'        )    -- Switch to next file
;DefKey( 'c_n'          , 'NextFile'        )    -- Switch to next file
DefKey( 'a_f12'        , 'NextView'        )    -- Switch to next view of current file
DefKey( 'c_n'          , 'Open'            )    -- Open new EPM window
DefKey( 'c_s_f12'      , 'Next_Win'        )    -- Switch to next EPM window
DefKey( 'c_g'          , 'Ring_More'       )    -- Open a dialog to select a file of the ring
; Sh+Esc is usually defined by PM (open system menu, like Alt+Spc).
DefKey( 's_esc'        , 'Ring_More'       )    -- Open a dialog to select a file of the ring

; ---- Reflow ----
DefKey( 'a_j'          , 'JoinLines'       )    -- Join current with next line
DefKey( 'a_s'          , 'SplitLines'      )    -- Split line at cursor pos., keeping the indent
DefKey( 'a_p'          , 'ReflowPar2ReflowMargins')   -- Reflow current paragraph, starting at cursor, using reflowmargins
DefKey( 'a_s_p'        , 'ReflowMark2ReflowMargins')  -- Reflow current mark, using reflowmargins
DefKey( 'c_p'          , 'ReflowAll2ReflowMargins')   -- Reflow all, starting at cursor, using  reflowmargins
DefKey( 'a_r'          , 'ReflowBlock'     )    -- Reflow marked block to a new block size

; ---- Case ----
;DefKey( 'c_f1'         , 'UppercaseWord'       -- Change word to uppercase
DefKey( 'c_s_f2'       , 'UppercaseWord'   )    -- Change word to uppercase
DefKey( 'c_f1'         , 'CaseWord'        )    -- Toggle word through mixed, upper and lower cases
DefKey( 'c_f2'         , 'LowercaseWord'   )    -- Change word to lowercase
DefKey( 'c_f3'         , 'UppercaseMark'   )    -- Change mark to uppercase
DefKey( 'c_f4'         , 'LowercaseMark'   )    -- Change mark to lowercase

; ---- Key recording ----
DefKey( 'c_r'          , 'RecordKeys'      )    -- Start/stop recording keys
DefKey( 'c_t'          , 'PlaybackKeys'    )    -- Stop recording and execute recorded keys

; ---- Bookmarks ----
DefKey( 'c_b'          , 'ListMark'        )    -- Open a dialog to select a bookmark
DefKey( 'c_m'          , 'SetMark'         )    -- Open a dialog to save position as bookmark
DefKey( 'a_/'          , 'NextBookmark'    )    -- Go to next bookmark (German keyboard: Alt+Sh+7)
DefKey( 'a_7'          , 'NextBookmark'    )    -- Go to next bookmark
DefKey( 'a_\'          , 'NextBookmark P'  )    -- Go to previous bookmark (German keyboard: Alt+AltGr+Beta)
DefKey( 'a_�'          , 'NextBookmark P'  )    -- Go to previous bookmark
DefKey( 'a_s_/'        , 'NextBookmark P'  )    -- Go to previous bookmark

; ---- Help ----
DefKey( 'c_h'          , 'KwHelp'          )    -- Lookup current word in a help file

; ---- Syntax Assistant ----
DefKey( 'a_h'          , 'MyAssist'        )    -- ASSIST.E: insert code for abbreviations left from cursor

; ---- Bracket matching or expansion ----
DefKey( 'c_['          , 'Assist'          )    -- Move cursor on matching bracket or statement
DefKey( 'c_]'          , 'Assist'          )    -- Move cursor on matching bracket or statement
DefKey( 'c_8'          , 'Assist'          )    -- Move cursor on matching bracket or statement
; Opening brackets (note that the shifted variant applies, depending on your keyboard):
DefKey( '('            , 'OpeningParen'    )    -- Add ) while typing ( if defined as match_chars
DefKey( 's_('          , 'OpeningParen'    )    -- Add ) while typing ( if defined as match_chars
DefKey( '['            , 'OpeningBracket'  )    -- Add ] while typing [ if defined as match_chars
DefKey( '{'            , 'OpeningBrace'    )    -- Add } while typing { if defined as match_chars
DefKey( '<'            , 'OpeningAngle'    )    -- Add > while typing < if defined as match_chars
; Closing brackets with balance enabled (note that the shifted variant applies, depending on your keyboard):
DefKey( ')'            , 'Balance )'       )    -- Mark matching ( while typing )
DefKey( 's_)'          , 'Balance )'       )    -- Mark matching ( while typing )
DefKey( ']'            , 'Balance ]'       )    -- Mark matching [ while typing ]
DefKey( '}'            , 'ClosingBrace'    )    -- Auto-indent } to indent of { if activated. Mark matching { while typing }

; ---- Draw ----
DefKey( 'f6'           , 'Draw'            )    -- Message about available draw chars and Commandline to typein a char, then use cursor chars

; ---- Tags ----
DefKey( 's_f6'         , 'FindTag'         )    -- Find procedure under cursor via tags file
DefKey( 'c_s_f6'       , 'mc ;MakeTags =;FindTag')  -- Refresh current tags file, then find procedure under cursor via tags file
DefKey( 's_f7'         , 'FindTag *'       )    -- Open entrybox to enter a procedure to find via tags file
DefKey( 's_f8'         , 'TagsFile'        )    -- Open entrybox to select a tags file
DefKey( 's_f9'         , 'MakeTags *'      )    -- Open entrybox to enter list of files to scan for to create a tags file
DefKey( 'c_s_t'        , 'TagScan'         )    -- Open a list box with tags of the current file

; ---- Undo ----
DefKey( 'c_u'          , 'UndoDlg'         )    -- Open Undo dialog
DefKey( 'f9'           , 'UndoLine'        )    -- Undo current line
DefKey( 'a_backspace'  , 'UndoLine'        )    -- Undo current line
; Sync with the Cursor section:
;DefKey( 'c_pgup'       , 'Undo1'           )    -- Scroll through previous undo states (keep Ctrl pressed to scroll)
;DefKey( 'c_pgdn'       , 'Redo1'           )    -- Scroll through next undo states (keep Ctrl pressed to scroll)
DefKey( 's_f11'        , 'Undo1'           )    -- Scroll through previous undo states (keep Ctrl pressed to scroll)
DefKey( 's_f12'        , 'Redo1'           )    -- Scroll through next undo states (keep Ctrl pressed to scroll)

; ---- Syntax expansion ----
DefKey( 'c_x'          , 'ForceExpansion'  )    -- Force expansion if defined for a mode

; ---- Space ----
; ExpandFirst <alternate_cmd>
;    This command tries to execute the 1st syntax expansion first. If the
;    command was not successful, then the <alternate_cmd> is executed.

;   1)  Expansion with Space, no expansion with Ctrl+Space:
DefKey( 'space'        , 'ExpandFirst Space')    -- Try 1st syntax expansion if activated. If not successful execute Space
DefKey( 'c_space'      , 'Space'           )

;   2)  Expansion with Ctrl+Space, no expansion with Space:
;DefKey( 'space'        , 'Space'           )
;DefKey( 'c_space'      , 'ExpandFirst Space')   -- Try 1st syntax expansion if activated. If not successful execute Space

DefKey( 's_space'      , 'Space'           )

; ---- Newline and Enter ----
; ExpandSecond <alternate_cmd>
;    This command tries to execute the 2nd syntax expansion first. If the
;    command was not successful, then the <alternate_cmd> is executed.
;
; StreamLine <stream_mode_cmd>|<line_mode_cmd>
;    This command allows for definitions to behave different in stream mode
;    (CUA, default) and line mode. In stream mode <stream_mode_cmd> is
;    executed, and in line mode <line_mode_cmd>. Both commands are separated
;    with a bar char.
;
; Newline [<num>]
;    This command executes an Enter action. For stream mode, no <num> options
;    exist. For line mode, following options are available:
;    1  (ADDLINE)   Add a new line after cursor, preserving indentation (default)
;    2  (NEXTLINE)  Move to beginning of next line (standard for c_enter and c_padenter)
;    3  (ADDATEND)  Like (2), but add a line if at end of file
;    4  (DEPENDS)   Add a line if in insert mode, else move to next
;    5  (DEPENDS+)  Like (4), but always add a line if on last line
;    6  (STREAM)    Split line at cursor
;    7              Add a new line, move to left or paragraph margin
;    8              Add a new line, move to paragraph margin
;    9              Add a new line, move to column 1

; Use a command here to make the standard def available for other keysets
DefKey( 'newline'      , 'StdNewline'      )

; 1)  Expansion with Enter, no expansion with Ctrl+Enter:
;     Try 2nd syntax expansion if activated. If not successful execute Enter
;defc StdNewline     'ExpandSecond StreamLine Enter|Enter 1'  -- def moved below, outside of StdKeys
DefKey( 'c_newline'    , 'StreamLine Enter|Enter 2')

; 2)  Expansion with Ctrl+Enter, no expansion with Enter:
;     Try 2nd syntax expansion if activated. If not successful execute Enter
;defc StdNewline     'StreamLine Enter|Enter 1'  -- def moved below, outside of StdKeys
;DefKey( 'c_newline     , 'ExpandSecond StreamLine Enter|Enter 2')

; More newline and enter keys
DefKey( 'a_newline'    , 'StreamLine SoftWrapAtCursor|Enter 1')
DefKey( 's_newline'    , 'StreamLine Enter|Enter 1')

; Use a command here to make the standard def available for other keysets
DefKey( 'enter'        , 'StdPadEnter'     )
;defc StdPadEnter  'StreamLine Enter|Enter 1'  -- def moved below, outside of StdKeys
DefKey( 'c_enter'      , 'StreamLine Enter|Enter 2')
DefKey( 'a_enter'      , 'StreamLine Enter|Enter 1')
DefKey( 's_enter'      , 'StreamLine Enter|Enter 1')

DefKey( 'a_n'          , 'NewLineAfter'    )    -- Add a new line after the current, move to it, keep col
DefKey( 'a_s_n'        , 'NewLineBefore'   )    -- Add a new line before the current, move to it, keep col
;DefKey( 'c_a_enter'    , 'NewLineAfter'    )    -- Add a new line after the current, move to it, keep col
;DefKey( 'c_a_s_enter'  , 'NewLineBefore'   )    -- Add a new line before the current, move to it, keep col

; ---- Duplicate ----
DefKey( 'c_k'          , 'DuplicateLine'   )    -- Duplicate a line
DefKey( 'a_g'          , 'InsertCharAbove' )    -- Insert char from line above at cursor
DefKey( 'a_s_g'        , 'InsertCharBelow' )    -- Insert char from line below at cursor

; ---- Insert ----
DefKey( 'ins'          , 'InsertToggle'    )    -- Toggle between insert and overwrite mode

; ---- Tab ----
DefKey( 'tab'          , 'Tab'             )    -- Insert tab char or spaces
DefKey( 's_backtab'    , 'BackTab'         )    -- Go back one tabstop

; ---- Load file ----
DefKey( 'a_1'          , 'alt_1'           )    -- Load file under cursor

; ---- Indent ----
DefKey( 'a_i'          , 'IndentBlock'     )    -- Indent current mark or block 1 indent level
DefKey( 'a_s_i'        , 'IndentBlock U'   )    -- Unindent current mark or block 1 indent level

; ---- Comment ----
DefKey( 'a_k'          , 'comment'         )    -- Comment marked lines
DefKey( 'a_s_k'        , 'uncomment'       )    -- Uncomment marked lines

; ---- Move chars and lines ----
DefKey( 'a_s_left'     , 'MoveCharLeft'    )    -- Move char left
DefKey( 'a_s_right'    , 'MoveCharRight'   )    -- Move char right
DefKey( 'a_s_up'       , 'MoveLineUp'      )    -- Exchange previous and current line
DefKey( 'a_s_down'     , 'MoveLineDown'    )    -- Exchange next and previous line

; ---- Popup menu (redefinition of PM key not required) ----
;DefKey( 's_f10         , 'MH_popup'        )    -- Show the popup menu

; ---- end of defc StdKeys ----


; ---------------------------------------------------------------------------
; 1)  Expansion with Newline, no expansion with Ctrl+Newline:
defc StdNewline
   -- Try 2nd syntax expansion if activated.
   -- If not successful, execute Newline
   'ExpandSecond StreamLine Enter|Enter 1'
; 2)  Expansion with Ctrl+Newline, no expansion with Newline:
;defc StdNewline
;   'StreamLine Enter|Enter 1'

; ---------------------------------------------------------------------------
defc StdPadEnter, StdEnter
   'StreamLine Enter|Enter 1'

; ---------------------------------------------------------------------------
; ---- Auto-spellcheck (dynaspell) ----
defc SpellKeys
DefKey( 'space'        , 'SpellProofDyn ExpandFirst Space')
DefKey( 'newline'      , 'SpellProofDyn StdNewline')
DefKey( 'enter'        , 'SpellProofDyn StdEnter')
DefKey( 'c_a'          , 'SpellProofDynDlg')  -- Unknown word was ... - press Ctrl+A for alternates.

; ---------------------------------------------------------------------------
; ---- All command: key for all/source file switching ----
defc AllKeys
DefKey( 'c_q'          , 'AllSwitchFiles'   )
DefKey( 'c_s_q'        , 'AllEndSwitchFiles')

