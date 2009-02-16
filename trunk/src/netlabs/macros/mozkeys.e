/****************************** Module Header *******************************
*
* Module Name: mozkeys.e.e
*
* Copyright (c) Netlabs EPM Distribution Project 2008
*
* $Id: mozkeys.e,v 1.2 2009-02-16 20:57:02 aschn Exp $
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

; Mozilla keys for EPM

; How to activate it:
;
; Options -> Keys -> Keyset additions: [...]
;
; These key definitions redefine some defs of STDKEYS.E.
;
; Note: The text of the menu items is not changed. With the current version
; of NEPMD you also have to edit NEWMENU.E in order to achieve that.


; The comment below a definition shows the standard NEPMD definition.


; Clipboard -----------------------------------------------------------------
def c_c        'Copy2Clip'            -- W$
               -- was: Change         -- Change next
def c_v        'DefaultPaste'         -- W$
               -- was: GlobalFind     -- Find next in all files of the ring
;def c_x       'Cut'                  -- W$
               -- was: unused


; Mark ----------------------------------------------------------------------
;def c_a       'Select_All'           -- W$
               -- unchanged


; Delete --------------------------------------------------------------------
def c_del      'DeleteUntilNextWord'  -- Moz
               -- was: 'DeleteUntilEndLine'  -- Delete from cursor until end of line


; Undo ----------------------------------------------------------------------
def c_z        'Undo1'                -- Moz has only 1 undo
               -- was: unused
def c_y        'Redo1'                -- Moz has only 1 redo
               -- was: 'FontList'     -- Open style dialog to add font attributes to mark
defc Key_c_s_z 'Redo1'                -- Moz has only 1 redo


; Search --------------------------------------------------------------------
; Find-next is always forwards, find-previous is always backwards!

def c_f        'SearchDlg'
               -- was: 'FindNext'     -- Find next
def c_g        'mc ;SearchDirection F;FindNext'
               -- was: 'Ring_More'    -- Open a dialog to select a file of the ring
               -- ('Ring_More' is also defined for Sh+Esc)
defc Key_c_s_g 'mc ;SearchDirection B;FindNext'

; Change-next doesnot exist in Moz! (maybe use f4/s_f4?)

def f3         'FindNext'
               -- was: 'Quit'         -- Quit file
def s_f3       'FindPrevious'         -- from ConText editor


; File ----------------------------------------------------------------------
def c_q        'Close'
               -- was: 'All' search: toggle between .ALL and original file (--> changed to a_q)
def c_w        'Quit'
               -- was: 'MarkToken' (standard) -- Mark current word, separators according to C syntax
               -- was: 'FindWord'     -- Find current word, separators according to C syntax

def c_s        'Save'

def c_o        'EditFileDlg'          -- Add a file
               -- was: 'OpenDlg'      -- Open File-open dialog (will open file in a new window)
defc Key_c_s_s 'SaveAs'               -- from ConText editor


; Cursor --------------------------------------------------------------------
def c_pgup     'BeginScreen'          -- Go to first line on screen

def c_pgdn     'EndScreen'            -- Go to last line on screen


; .ALL file -----------------------------------------------------------------
; All should better define its own keyset (todo).
define ALL_KEY = 'a_Q'                -- 'All' search: toggle between .ALL and original file


/*
; Font size -----------------------------------------------------------------
defc Key_c_plus  'FontLarger'         -- not existing
               -- was: unused
defc Key_c_minus 'FontSmaller'        -- not existing
               -- was: 'ToggleSearchDirection'  -- Toggle search direction
*/

