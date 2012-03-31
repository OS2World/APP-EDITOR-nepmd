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

; File ----------------------------------------------------------------------
DefKey( 'c_s'          , 'Save'            )    -- was: 'SearchDlg'
DefKey( 'c_a_s'        , 'SaveAs'          )
DefKey( 'c_s_s'        , 'SaveAll'         )
DefKey( 'c_f4'         , 'Quit'            )    -- (close file, not quit editor) was: 'LowercaseMark'
; Alt+F4 suffices
;DefKey( 'c_q'         , 'Close'           )
; Ctrl+F4 is more common
;DefKey( 'c_w'         , 'Quit'            )    -- was: 'FindWord'

; Undo ----------------------------------------------------------------------
DefKey( 'c_z'          , 'Undo1'           )
DefKey( 'c_y'          , 'Redo1'           )    -- was: 'FontList'
DefKey( 'c_s_z'        , 'Redo1'           )

; Clipboard -----------------------------------------------------------------
DefKey( 'c_c'          , 'Copy2Clip'       )    -- was: 'RepeatChange'
DefKey( 'c_v'          , 'DefaultPaste'    )    -- was: 'RepeatFindAllFiles'
DefKey( 'c_x'          , 'Cut'             )    -- was: 'ForceExpansion'

; Case ----------------------------------------------------------------------
DefKey( 's_f1'         , 'CaseWord'        )
DefKey( 'c_f1'         , 'LowercaseWord'   )
DefKey( 'c_s_f1'       , 'UppercaseWord'   )
DefKey( 'a_f1'         , 'LowercaseMark'   )    -- was: 'TypeFrameChars'
DefKey( 'a_s_f1'       , 'UppercaseMark'   )

; Search --------------------------------------------------------------------
DefKey( 'c_f'          , 'SearchDlg'       )    -- was: 'RepeatFind'
DefKey( 'f3'           , 'FindNext'        )    -- was: 'Quit'
DefKey( 's_f3'         , 'FindPrev'        )    -- was: 'ScrollDown'
DefKey( 'c_g'          , 'ChangeFindNext'  )    -- was: 'Ring_More', also defined as Sh+Esc
DefKey( 'c_s_g'        , 'ChangeFindPrev'  )
DefKey( 'a_f3'         , 'FindNextAllFiles')
DefKey( 'a_s_f3'       , 'FindPrevAllFiles')

; Scroll --------------------------------------------------------------------
DefKey( 'c_f2'         , 'ScrollDown'      )
DefKey( 'c_s_f2'       , 'ScrollUp'        )
DefKey( 'a_f2'         , 'ScrollRight'     )
DefKey( 'a_s_f2'       , 'ScrollLeft'      )

; Syntax expansion ----------------------------------------------------------
DefKey( 'a_x'          , 'ForceExpansion'  )

; Undefined -----------------------------------------------------------------
UnDefKey( 's_f2')
UnDefKey( 'c_f3')
UnDefKey( 'c_s_f3')
UnDefKey( 's_f4')
UnDefKey( 'c_s_f4')
UnDefKey( 'a_s_f4')
UnDefKey( 'c_-')

