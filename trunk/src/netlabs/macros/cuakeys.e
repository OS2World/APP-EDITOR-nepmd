/****************************** Module Header *******************************
*
* Module Name: cuakeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2008
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

; CUA keys for EPM

; How to activate it:
;
;    Options -> Keys -> Keyset additions: [...]
;
;    Advanced marking is defined separately. For complete CUA behavior,
;    that has to be set to basic marking:
;
;    Options -> Marking -> [ ] Advanced marking
;
; The key definitions in this file redefine some definitions of STDKEYS.E.
;
; Note: The text of the menu items is not changed automatically.
; NEWMENU.E is prepared to respect the defs in this file, but not any
; other changes. To achieve that, NEWMENU.E has to be edited.

defc CuaKeys

; Clipboard -----------------------------------------------------------------
DefKey( 'c_c'          , 'Copy2Clip'       )    -- was: Change
DefKey( 'c_v'          , 'DefaultPaste'    )    -- was: GlobalFind
DefKey( 'c_x'          , 'Cut'             )    -- was: unused

; Mark ----------------------------------------------------------------------
;DefKey( 'c_a'          ,'Select_All'       )   -- unchanged

; Delete --------------------------------------------------------------------
;DefKey( 'c_delete'     , 'DeleteUntilNextWord') -- unchanged
;DefKey( 'c_s_delete'   , 'DeleteUntilEndLine')  -- unchanged

; Undo ----------------------------------------------------------------------
DefKey( 'c_z'          , 'Undo1'           )    -- was: unused
DefKey( 'c_y'          , 'Redo1'           )    -- was: 'FontList'
DefKey( 'c_s_z'        , 'Redo1'           )    -- was: unused

; Undo ----------------------------------------------------------------------
DefKey( 'c_s_f3'       , 'UppercaseMark'   )
DefKey( 'c_f3'         , 'LowercaseMark'   )

; Search --------------------------------------------------------------------
; Find-next is always forwards, find-previous is always backwards!
DefKey( 'c_f'          , 'SearchDlg'       )    -- was: 'FindNext'
DefKey( 'c_g'          , 'mc ;SearchDirection F;FindNext')  -- was: 'Ring_More'
                                                            -- ('Ring_More' is also defined for Sh+Esc)
DefKey( 'c_s_g'        , 'mc ;SearchDirection B;FindNext')
DefKey( 'f3'           , 'FindNext'        )    -- was: 'Quit'
DefKey( 's_f3'         , 'FindPrevious'    )

; File ----------------------------------------------------------------------
; Alt+F4 suffices
;DefKey( 'c_q'          , 'Close'           )
; Ctrl+F4 is more common
;DefKey( 'c_w'          , 'Quit'            )    -- was: 'FindWord'
DefKey( 'c_f4'          , 'Quit'           )    -- close file, not quit editor
DefKey( 'c_s'           , 'Save'           )    -- was: 'SearchDlg'
DefKey( 'c_a_s'         , 'SaveAs'         )
DefKey( 'c_s_s'         , 'SaveAll'        )

