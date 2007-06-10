/****************************** Module Header *******************************
*
* Module Name: stdkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdkeys.e,v 1.35 2007-06-10 20:01:01 aschn Exp $
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

; Note: Alt+<num> definitions via defc Key_a_<num> are disabled, in order
;       to make Alt+<num-pad> keys insert ASCII code chars.
;
;       This does not affect def a_<num> definitions. They can be used as
;       usual, because PM definitions always overwrite EPM def definitions,
;       unless EPM defines them as PM accelerator keys, which is the case
;       for all defc Key_* definitions.
;
;       Order of key definitions:
;          1. (highest) PM accelerator keys, e.g. via defc Key_*
;          2.           Standard PM-defined keys, like Alt+F4
;          3. (lowest)  EPM's keyset definitions via def
;
;       Usually every def definition is defined automatically as PM
;       acceleator key as well. That ensures, that only the def definition
;       has to specified, if it exists. This does not apply to def a_<num>
;       definitions, because of the above described behaviour.

; ---------------------------------------------------------------------------
compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'STDKEYS.E'

EA_comment 'This defines the standard keyset.'

; When being linked, the "defkeys edit_keys new clear" line must be added to
; STDCNF.E, in order to include it in EPM.EX.

compile endif

; ---------------------------------------------------------------------------
; Define the keyset "EDIT_KEYS". All following key defs will belong to this
; keyset, until the next occurance of defkeys.
; "EDIT_KEYS" is the standard keyset.
defkeys edit_keys new clear

; ---- Cursor ----
def c_home        'BeginFile'           -- Go to begin of file (Shift marks)
def c_end         'EndFile'             -- Go to end of file (Shift marks)
def c_f5          'BeginWord'           -- Go to first char in current word
def c_f6          'EndWord'             -- Go to last char in current word
def c_left        'PrevWord'            -- Go to previous word (Shift marks)
def c_right       'NextWord'            -- Go to next word (Shift marks)

def left          'PrevChar'            -- Go to previous char (Shift marks)
def right         'NextChar'            -- Go to next char (Shift marks)
def up            'Up'                  -- Go to previous line (Shift marks)
def down          'Down'                -- Go to next line (Shift marks)
def home          'BeginLineOrText'     -- Go to begin of line or text (Shift marks)
;defc Key_a_home   'BeginLine'           -- Go to begin of line
defc Key_a_s_home 'MarkBeginLine'       -- Mark to begin of line
def end           'EndLine'             -- Go to end of line (Shift marks)
def pgup          'PageUp'              -- Go to previous page (Shift marks)
def pgdn          'PageDown'            -- Go to next page (Shift marks)
;def c_pgup       'BeginScreen'         -- Go to first line on screen
;def c_pgdn       'EndScreen'           -- Go to last line on screen
def c_down        'PushPos'             -- Add current cursor pos. to cursor stack
def c_up          'PopPos'              -- Go to last pos. of cursor stack
def c_equal       'SwapPos'             -- Exchange current cursor pos. with last pos. of stack
def c_0           'SwapPos'             -- Exchange current cursor pos. with last pos. of stack
def a_minus       'HighlightCursor'     -- Draw a circle around cursor
def a_e           'EndMark'             -- Go to end of mark
def a_y           'BeginMark'           -- Go to begin of mark

; ---- Scroll ----
def s_f1          'ScrollLeft'          -- Scroll text left
def s_f2          'ScrollRight'         -- Scroll text right
def s_f3          'ScrollUp'            -- Scroll text up
def s_f4          'ScrollDown'          -- Scroll text down
def s_f5          'CenterLine'          -- V-center current line
;def c_a          'NewTop'              -- Make current line topmost

; ---- Mark ----
def a_b           'MarkBlock'           -- Start/end block mark
def a_l           'MarkLine'            -- Start/end line mark
def a_z           'MarkChar'            -- Start/end char mark
def a_w           'MarkWord'            -- Mark current word
;def c_w          'MarkToken'           -- Mark current word, separators according to C syntax
defc Key_a_s_w    'MarkToken'           -- Mark current word, separators according to C syntax
def a_u           'UnMark'              -- Unmark all
def c_backslash   'UnMark'              -- Unmark all
defc Key_c_s_a    'UnMark'              -- Unmark all
def c_a           'Select_All'          -- Mark all
def c_slash       'Select_All'          -- Mark all
def s_left        'MarkPrevChar'        -- Mark from cursor to previous char
def s_right       'MarkNextChar'        -- Mark from cursor to next char
def s_up          'MarkUp'              -- Mark from cursor line up
def s_down        'MarkDown'            -- Mark from cursor line down
def s_end         'MarkEndLine'         -- Mark from cursor to end of line
def s_home        'MarkBeginLineOrText' -- Mark from cursor to begin of line or text
def s_pgup        'MarkPageUp'          -- Mark from cursor page up
def s_pgdn        'MarkPageDown'        -- Mark from cursor page down
defc Key_c_s_down 'PushMark'            -- Save current mark to mark stack
defc Key_c_s_up   'PopMark'             -- Restore last mark from stack (and remove it from stack)
defc Key_c_s_equal 'SwapMark'           -- Exchange current mark with last mark from stack
defc Key_c_s_plus 'SwapMark'            -- Exchange current mark with last mark from stack

; ---- Mark operations ----
def a_c           'CopyMark'            -- Copy mark
def a_d           'DeleteMark'          -- Delete mark
def a_m           'MoveMark'            -- Move mark
def a_o           'OverlayMark'         -- Copy block
def a_a           'AdjustMark'          -- Move block
def a_t           'CenterMark'          -- Center text in mark
def a_f           'FillMark'            -- Open dialog to specify a char as fill char
def c_f7          'ShiftLeft'           -- Move text in mark 1 col left
def c_f8          'ShiftRight'          -- Move text in mark 1 col right
def c_y           'FontList'            -- Open style dialog to add font attributes to mark
defc Key_c_s_y    'linkexec stylebut apply_style S'  -- Open list box for selecting a style

; ---- Delete ----
def del           'DeleteChar'          -- Delete current char
def backspace     'BackSpace'           -- Delete previous char (Shift marks)
def s_backspace   'BackSpace'           -- Delete previous char (Shift marks)
def c_backspace   'DeleteLine'          -- Delete current line
def c_d           'DeleteUntilNextWord' -- Delete from cursor until beginning of next word
def c_del         'DeleteUntilEndLine'  -- Delete from cursor until end of line
def c_e           'DeleteUntilEndLine'  -- Delete from cursor until end of line

; ---- Search ----
def c_s           'SearchDlg'           -- Open search dialog
def c_f           'FindNext'            -- Find next
def c_c           'Change'              -- Change next
def c_v           'GlobalFind'          -- Find next in all files of the ring
def c_minus       'ToggleSearchDirection'  -- Toggle search direction
def c_w           'FindWord'            -- Find current word, separators according to C syntax
defc Key_c_s_d    'FindDef'             -- Find definition for current word

; ---- Clipboard ----
def s_del         'Cut'                 -- Copy mark to clipboard and delete
def s_ins         'DefaultPaste'        -- Default paste (paste as chars, selectable)
def c_ins         'Copy2Clip'           -- Copy mark to clipboard
defc Key_c_s_ins  'AlternatePaste'      -- Alternate paste (paste as lines, depends on default paste)

; ---- Execute ----
def c_i           'CommandLine'         -- Open Command dialog
def esc           'ProcessEscape'       -- Open Command dialog or stop block reflow
def a_0           'dolines'             -- Execute line under cursor
def a_equal       'dolines'             -- Execute line under cursor
def c_l           'CommandDlgLine'      -- Open current line in Command dialog

; ---- File operations ----
def a_f2          'SaveAs_Dlg'          -- Open the Save-as dialog
def f2            'SaveOrSaveAs'        -- Save; if unchanged: open Save-as dialog
def f3            'Quit'                -- Quit file
def f4            'FileOrQuit'          -- Save and quit file; if unchanged: just quit
def f5            'OpenDlg'             -- Open File-open dialog (will open file in a new window)
def c_O           'OpenDlg'             -- Open File-open dialog (will open file in a new window)
def f7            'Rename'              -- Open Rename entrybox
def f8            'EditFileDlg'         -- Open File-edit dialog (will open file in the same window)
defc Key_c_s_f9   'History edit'        -- Open Edit history listbox
defc Key_c_s_f10  'History load'        -- Open Load history listbox
defc Key_c_s_f11  'History save'        -- Open Save history listbox

; ---- Special chars ----
def a_f1          'TypeFrameChars'      -- Type a list of IBM frame chars (help for the draw and box commands)
;def a_n          'TypeFileName'        -- Type the full filename
def c_2           'TypeNull'            -- Type a null char (\0)
def c_6           'TypeNot'             -- Type a not char ª (\170)
def c_9           'TypeOpeningBrace'    -- Type a {
;def c_0          'TypeClosingBrace'    -- Type a }
def c_4           'TypeCent'            -- Type a cent char › (\155)
def c_tab         'TypeTab'             -- Type a tab char (\9)

; ---- Window and File switching ----
def f11           'PrevFile'            -- Switch to previous file
;def c_p          'PrevFile'            -- Switch to previous file
def f12           'NextFile'            -- Switch to next file
;def c_n          'NextFile'            -- Switch to next file
def a_f12         'NextView'            -- Switch to next view of current file
def c_n           'Open'                -- Open new EPM window
defc Key_c_s_f12  'Next_Win'            -- Switch to next EPM window
def c_g           'Ring_More'           -- Open a dialog to select a file of the ring
def s_esc         'Ring_More'           -- Open a dialog to select a file of the ring

; ---- Reflow ----
def a_j           'JoinLines'           -- Join current with next line
def a_s           'SplitLines'          -- Split line at cursor pos., keeping the indent
def a_p           'ReflowPar2ReflowMargins'   -- Reflow current mark or paragraph, starting at cursor, using reflowmargins
defc Key_a_s_p    'ReflowPar'                 -- Reflow current mark or paragraph, starting at cursor, using current margins
def c_p           'ReflowAll2ReflowMargins'   -- Reflow all, starting at cursor, using  reflowmargins
defc Key_c_s_p    'ReflowAll'                 -- Reflow all, starting at cursor, using current margins
def a_r           'ReflowBlock'         -- Reflow marked block to a new block size

; ---- Case ----
;def c_f1         'UppercaseWord'       -- Change word to uppercase
defc Key_c_s_f2   'UppercaseWord'       -- Change word to uppercase
def c_f1          'CaseWord'            -- Toggle word through mixed, upper and lower cases
def c_f2          'LowercaseWord'       -- Change word to lowercase
def c_f3          'UppercaseMark'       -- Change mark to uppercase
def c_f4          'LowercaseMark'       -- Change mark to lowercase

; ---- Key recording ----
def c_r           'RecordKeys'          -- Start/stop recording keys
def c_t           'PlaybackKeys'        -- Stop recording and execute recorded keys

; ---- Bookmarks ----
def c_b           'ListMark'            -- Open a dialog to select a bookmark
def c_m           'SetMark'             -- Open a dialog to save position as bookmark
def a_slash       'NextBookmark'        -- Go to next bookmark (german keyboard: Alt+Sh+7)
defc Key_c_7      'NextBookmark'        -- Go to next bookmark
def a_backslash   'NextBookmark P'      -- Go to previous bookmark (german keyboard: Alt+AltGr+Beta)
defc Key_c_a_7    'NextBookmark P'      -- Go to previous bookmark

; ---- Help ----
def c_h           'kwhelp'              -- Lookup current word in a help file

; ---- Syntax Assistant ----
def a_h           'MyAssist'            -- ASSIST.E: insert code for abbreviations left from cursor

; ---- Bracket matching or expansion ----
def c_leftbracket 'Assist'              -- Move cursor on matching bracket or statement
def c_rightbracket 'Assist'             -- Move cursor on matching bracket or statement
def c_8           'Assist'              -- Move cursor on matching bracket or statement
def '('           'OpeningParen'        -- Add ) while typing ( if defined as match_chars
def '['           'OpeningBracket'      -- Add ] while typing [ if defined as match_chars
def '{'           'OpeningBrace'        -- Add } while typing { if defined as match_chars
def '<'           'OpeningAngle'        -- Add > while typing < if defined as match_chars
def ')'           'balance )'           -- Mark matching ( while typing )
def ']'           'balance ]'           -- Mark matching [ while typing ]
def '}'           'ClosingBrace'        -- Auto-indent } to indent of { if activated. Mark matching { while typing }

; ---- Draw ----
def f6            'Draw'                -- Message about available draw chars and Commandline to typein a char, then use cursor chars

; ---- Tags ----
def s_f6          'FindTag'             -- Find procedure under cursor via tags file
defc Key_c_s_f6   'mc ;MakeTags =;FindTag'  -- Refresh current tags file, then find procedure under cursor via tags file
def s_f7          'FindTag *'           -- Open entrybox to enter a procedure to find via tags file
def s_f8          'TagsFile'            -- Open entrybox to select a tags file
def s_f9          'MakeTags *'          -- Open entrybox to enter list of files to scan for to create a tags file
defc Key_c_s_t    'TagScan'             -- Open a list box with tags of the current file

; ---- Undo ----
def c_u           'UndoDlg'             -- Open Undo dialog
def f9            'UndoLine'            -- Undo current line
def a_backspace   'UndoLine'            -- Undo current line
def c_pgup        'Undo1'               -- Scroll through previous undo states (keep Ctrl pressed to scroll)
def c_pgdn        'Redo1'               -- Scroll through next undo states (keep Ctrl pressed to scroll)

; ---- Enter ----
; For Line mode, these keys are configurable via the settings dialog.
; In Stream mode, all enter defcs behave the same.

;   1)  Expansion with Enter, no expansion with Ctrl+Enter:
def enter         'ExpandSecond enter'  -- Try 2nd syntax expansion if activated. If not successful execute Enter
def c_enter       'c_enter'

;   2)  Expansion with Ctrl+Enter, no expansion with Enter:
;def c_enter      'ExpandSecond enter'  -- Try 2nd syntax expansion if activated. If not successful execute Enter
;def enter        'enter'

def a_enter       'a_enter'             -- Alt+Enter and Alt+Sh+Enter not definable in EPM?
def s_enter       's_enter'
def padenter      'padenter'
def a_padenter    'a_padenter'
def c_padenter    'c_padenter'
def s_padenter    's_padenter'
def a_n           'NewLineAfter'        -- Add a new line after the current, move to it, keep col
defc key_a_s_n    'NewLineBefore'       -- Add a new line below the current, move to it, keep col
; doesnot work:
;defc key_c_a_enter   'NewLineAfter'    -- Add a new line after the current, move to it, keep col
;defc key_c_s_a_enter 'NewLineBefore'   -- Add a new line below the current, move to it, keep col

; ---- Duplicate ----
def c_k           'DuplicateLine'       -- Duplicate a line
def a_g           'InsertCharAbove'     -- Insert char from line above at cursor
defc Key_a_s_g    'InsertCharBelow'     -- Insert char from line below at cursor

; ---- Insert ----
def ins           'InsertToggle'        -- Toggle between insert and overwrite mode

; ---- Tab ----
def tab           'Tab'                 -- Insert tab char or spaces
def s_tab         'BackTab'             -- Go back one tabstop

; ---- Space ----

;   1)  Expansion with Space, no expansion with Ctrl+Space:
def space        'ExpandFirst Space'   -- Try 1st syntax expansion if activated. If not successful execute Space
def c_space      'Space'

;   2)  Expansion with Ctrl+Space, no expansion with Space:
;def c_space      'ExpandFirst Space'   -- Try 1st syntax expansion if activated. If not successful execute Space
;def space        'Space'

def s_space       'Space'

; ---- Load file ----
def a_1           'alt_1'               -- Load file under cursor

; ---- Indent ----
def a_i           'IndentBlock'         -- Indent current mark or block 1 indent level
defc Key_a_s_i    'IndentBlock U'       -- Unindent current mark or block 1 indent level

; ---- Comment ----
def a_k           'comment'             -- Comment marked lines
defc Key_a_s_k    'uncomment'           -- Uncomment marked lines

; ---- Move chars and lines ----
defc Key_a_s_left 'MoveCharLeft'        -- Move char left
defc Key_a_s_right 'MoveCharRight'      -- Move char right
defc Key_a_s_up   'MoveLineUp'          -- Exchange previous and current line
defc Key_a_s_down 'MoveLineDown'        -- Exchange next and previous line

; ---- Popup menu (redefinition of PM key) ----
def s_f10         'MH_popup'            -- Show the popup menu

; ---- Auto-spellcheck ----
; This key belongs to "SPELL_KEYS". Therefore it is defined here with define.
define DYNASPELL_KEY = 'c_A'            -- Open Proof Word dialog for alternatives

; ---- .ALL file ----
; All should better define its own keyset (todo).
define ALL_KEY = 'c_Q'                  -- 'All' search: toggle between .ALL and original file

; ---- OtherKeys ----
def otherkeys 'ProcessOtherKeys'


                        -- The rest is documentation --

; ---------------------------------------------------------------------------
; Unused key defs
;    s_f11
;    s_f12
;    a_f3
;    a_f6
;    a_q
;    a_x
;    a_2
;    a_3
;    a_4
;    a_5
;    a_6
;    a_7
;    a_8
;    a_9
;    c_j
;    c_q  allkey  (only used for .ALL file)
;    c_z
;    c_1
;    c_3
;    c_5
;    c_8
;    c_backslash
;    a_leftbracket
;    c_leftbracket
;    a_rightbracket
;    c_rightbracket

; Note: All char-producing keys can be redefined with a def statement:
;       def '{'
; Note: Many via standard key defs not definable multi-alternated key
;       definitions (like Ctrl+Shift+Z) are unused as well. They are
;       definable via "defc Key_*" commands, e.g. "defc Key_c_s_z".

; ---------------------------------------------------------------------------
; PM keys. These keys are not definable in EPM. But they could be defined
; as accelerator keys, using buildacceltable.
/*
   view epmtech "key definitions"
   view epmtech keysets
   view epmtech "e-definable keys"
   view epmtech buildacceltable
*/
;    f1           Help
;    f10          Menu
;    s_f10        Popup menu (redefinable in EPM)
;    padplus      not definable as key def in EPM
;    c_padplus    not definable as key def in EPM
;    c_padstar    not definable as key def in EPM
;    pad_slash    not definable as key def in EPM
;    c_padslash   not definable as key def in EPM
;    pad5         not definable as key def in EPM
;    c_pad5       not definable as key def in EPM
;    a_space      System menu
;    a_f4         Close
;    a_f5         Restore
;    a_f6         Toggle focus between main and child window
;    a_f7         Move
;    a_f8         Size
;    a_f9         Minimize
;    a_f10        Maximize
;    a_f11        Hide
;    c_esc        Window list
;    a_esc        Switch to next window
;    a_tab        Select next window

; ---------------------------------------------------------------------------
; s_f1 must be enabled via accelerator key definition.
; s_f9 must be enabled via accelerator key definition.
; This is made in KEYS.E. (Every key definition is now additionally defined
; as accelerator key.)
;
; Note: If a standard EPM key def exists, then it is highlighted. If not,
;       then a "defc Key_*" command must be used.
;
; Every Sh combination is now definable via a Key_* command. The order of
; the prefixes must be respected: c_ a_ s_.
; Example: defc Key_c_a_s_p 'mycommand'  defines Ctrl+Alt+Sh+P as
; 'mycommand'.
;
; After changing a Keyset via the keys statement, one has to execute in
; cases, where a Key_* command has changed (or was added) the following
; commands to update the accelerator table: 'deleteaccel' and 'loadaccel'.
;
; Non-existing accelerator defs for additional letters can be added by
; extending UPPERCASE_LETTER_LIST and LOWERCASE_LETTER_LIST.
; Non-existing accelerator defs for additional chars can be added by
; extending CHAR_LIST, CHAR_NAMES and NO_DEF_CHAR_LIST.

