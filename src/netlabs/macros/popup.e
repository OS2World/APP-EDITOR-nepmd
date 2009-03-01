/****************************** Module Header *******************************
*
* Module Name: popup.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: popup.e,v 1.9 2009-03-01 21:46:14 aschn Exp $
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

; Popup menu defs, moved from MOUSE.E.


compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'POPUP.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(WANT_TEXT_PROCS)
   WANT_TEXT_PROCS   = 1
 compile endif
 compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
 compile endif
 compile if not defined(VANILLA)
   VANILLA = 0
 compile endif
 compile if not defined( WANT_DYNAMIC_PROMPTS)
    WANT_DYNAMIC_PROMPTS = 1  -- required for ENGLISH.E only
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   include 'stdconst.e'
   include 'menuhelp.h'
   EA_comment 'This defines the popup menu.'

compile endif

const
   FILL_MARK_MENU__MSG = '~Fill mark'
   FILL_MARK_MENUP__MSG = \1'Fill marked region with a character, overlaying current contents.'
   HP_POPUP_FILL = 0
   REFLOW_MARK_MENU__MSG = '~Reflow mark'
   REFLOW_MARK_MENUP__MSG = \1'Reflow text in marked region.'
   HP_POPUP_REFLOW = 0
   MARK_WORD_MENU__MSG = 'Mark ~word'
   MARK_WORD_MENUP__MSG = \1'Mark space-delimited word under mouse pointer.'
   HP_POPUP_MARKWORD = 0
   MARK_TOKEN_MENU__MSG = 'Mark ~identifier'
   MARK_TOKEN_MENUP__MSG = \1'Mark the C-language identifier under the mouse pointer.'
   HP_POPUP_MARKTOKEN = 0
   FIND_TOKEN_MENU__MSG = '~Find identifier'
   FIND_TOKEN_MENUP__MSG = \1'Find the next occurrence of the identifier under the mouse pointer.'
   HP_POPUP_FINDTOKEN = 0
compile if WANT_TEXT_PROCS
   MARK_SENTENCE_MENU__MSG = 'Mark s~entence'
   MARK_SENTENCE_MENUP__MSG = \1'Mark sentence around mouse pointer.'
   HP_POPUP_MARKSENTENCE = 0
   MARK_PARAGRAPH_MENU__MSG = 'Mark para~graph'
   MARK_PARAGRAPH_MENUP__MSG = \1'Mark paragraph around mouse pointer.'
   HP_POPUP_MARKPARAGRAPH = 0
   EXTEND_SENTENCE_MENU__MSG = 'E~xtend sentence mark'
   EXTEND_SENTENCE_MENUP__MSG = \1'Extend character mark through end of next sentence.'
   HP_POPUP_EXTENDSENTENCE = 0
   EXTEND_PARAGRAPH_MENU__MSG = 'Extend p~aragraph mark'
   EXTEND_PARAGRAPH_MENUP__MSG = \1'Extend character mark through end of next paragraph.'
   HP_POPUP_EXTENDPARAGRAPH = 0
compile endif -- WANT_TEXT_PROCS
   UPCASE_MARK_MENU__MSG = '~Uppercase selection'
   UPCASE_MARK_MENUP__MSG = \1'Translate selected text to upper case.'
   HP_POPUP_UPCASEMARK = 0
   LOCASE_MARK_MENU__MSG = '~Lowercase selection'
   LOCASE_MARK_MENUP__MSG = \1'Translate selected text to lower case.'
   HP_POPUP_LOCASEMARK = 0
   UPCASE_WORD_MENU__MSG = '~Uppercase word'
   UPCASE_WORD_MENUP__MSG = \1'Translate word under mouse pointer to upper case.'
   HP_POPUP_UPCASEWORD = 0
   LOCASE_WORD_MENU__MSG = '~Lowercase word'
   LOCASE_WORD_MENUP__MSG = \1'Translate word under mouse pointer to lower case.'
   HP_POPUP_LOCASEWORD = 0
   SHIFT_MENU__MSG = '~Shift'
   SHIFT_MENUP__MSG = \1'Shift marked text left or right.'
   HP_POPUP_SHIFT = 0
   SHIFTLEFT_MENU__MSG = 'Shift ~left 1'
   SHIFTLEFT_MENUP__MSG = \1'Shift marked text left 1 character.'
   HP_POPUP_SHIFTLEFT = 0
   SHIFTLEFT3_MENU__MSG = 'Shift l~eft 3'
   SHIFTLEFT3_MENUP__MSG = \1'Shift marked text left 3 characters.'
   HP_POPUP_SHIFTLEFT3 = 0
   SHIFTLEFT8_MENU__MSG = 'Shift le~ft 8'
   SHIFTLEFT8_MENUP__MSG = \1'Shift marked text left 8 characters.'
   HP_POPUP_SHIFTLEFT8 = 0
   SHIFTRIGHT_MENU__MSG = 'Shift right ~1'
   SHIFTRIGHT_MENUP__MSG = \1'Shift marked text right 1 character.'
   HP_POPUP_SHIFTRIGHT = 0
   SHIFTRIGHT3_MENU__MSG = 'Shift right ~3'
   SHIFTRIGHT3_MENUP__MSG = \1'Shift marked text right 3 characters.'
   HP_POPUP_SHIFTRIGHT3 = 0
   SHIFTRIGHT8_MENU__MSG = 'Shift right ~8'
   SHIFTRIGHT8_MENUP__MSG = \1'Shift marked text right 8 characters.'
   HP_POPUP_SHIFTRIGHT8 = 0
   CENTER_LINE_MENU__MSG = 'Cen~ter line'
   CENTER_LINE_MENUP__MSG = \1'Center line under mouse pointer vertically in window.'
   HP_POPUP_CENTERLINE = 0
   CENTER_MARK_MENU__MSG = 'Cen~ter text'
   CENTER_MARK_MENUP__MSG = \1'Center marked text within margins or block mark.'
   HP_POPUP_CENTERMARK = 0
   SORT_MARK_MENU__MSG = 'S~ort'
   SORT_MARK_MENUP__MSG = \1'Sort marked lines, using block mark (if present) as key.'
   HP_POPUP_SORT = 0
   TOP_LINE_MENU__MSG = 'Scro~ll to top'
   TOP_LINE_MENUP__MSG = \1'Scroll so line under mouse pointer is at top of window.'
   HP_POPUP_TOP = 0

;compile if WANT_TREE
   LOAD_FILE_MENU__MSG = '~Load file'
   SORT_ASCENDING_MENU__MSG = '~Sort ascending'
   SORT_DATE_MENU__MSG = 'Sort by ~date'
   SORT_TIME_MENU__MSG = 'Sort by ~time'
   SORT_SIZE_MENU__MSG = 'Sort by ~size'
   SORT_EASIZE_MENU__MSG = 'Sort by ~EA size'
   SORT_FULLNAME_MENU__MSG = 'Sort by ~fully-qualified filename'
   SORT_NAME_MENU__MSG = 'Sort by ~name'
   SORT_EXTENSION_MENU__MSG = 'Sort by ~extension'
   SORT_DESCENDING_MENU__MSG = 'Sort ~descending'

   LOAD_FILE_MENUP__MSG = \1'Load the file or list the directory under the cursor'
   SORT_ASCENDING_MENUP__MSG = \1'Sort the file or marked lines from smallest to largest'
   SORT_XXXX_MENUP__MSG = \1'Sort the file or marked lines by the indicated attribute'
   SORT_DESCENDING_MENUP__MSG = \1'Sort the file or marked lines from largest to smallest'
;compile endif


defc MH_popup
   universal activemenu, previouslyactivemenu
   if previouslyactivemenu = '' then
      previouslyactivemenu = activemenu
   endif
   menuname = 'popup1'
   activemenu = menuname

   call psave_pos( savedpos)
   deletemenu menuname, 0, 0, 0
   'BuildPopupMenu' menuname
   showmenu menuname, 1
   call prestore_pos( savedpos)
   -- Cascade menu now replaced by inline menu items, because it doesnot work:
;    --'add_cascade_popupmenu'       -- without postme: works only for the first menu creation
;                                    -- the square around the arrow of the submenu
;                                    -- is not painted correctly
;    'postme add_cascade_popupmenu'

--defproc BuildPopupMenu
defc BuildPopupMenu
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif
   menuname = arg(1)
   if menuname = '' then
      menuname = 'popup1'
   endif
   mt = leftstr( marktype(), 1)
   in_mark = mouse_in_mark()  -- Save in a variable so user's include file can test.

   buildsubmenu  menuname, 80, '', '', 0 , 0

   if upcase( leftstr( .filename, 5)) = '.TREE' then ----------------------------------------------------------------------------------
      buildmenuitem menuname, 80, 8000, LOAD_FILE_MENU__MSG\9'Alt+1',   'dokey a_1'LOAD_FILE_MENUP__MSG, 0, 0
      buildmenuitem menuname, 80, 8001, SORT_ASCENDING_MENU__MSG,   ''SORT_ASCENDING_MENUP__MSG, 17, 0
      buildmenuitem menuname, 80, 8002, SORT_DATE_MENU__MSG,        'treesort' 'D'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8003, SORT_TIME_MENU__MSG,        'treesort' 'T'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8004, SORT_SIZE_MENU__MSG,        'treesort' 'S'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8005, SORT_EASIZE_MENU__MSG,      'treesort' 'EA'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8006, SORT_FULLNAME_MENU__MSG,    'treesort' 'F'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8007, SORT_NAME_MENU__MSG,        'treesort' 'N'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8008, SORT_EXTENSION_MENU__MSG,   'treesort' 'EX'SORT_XXXX_MENUP__MSG, 32769, 0
      buildmenuitem menuname, 80, 8011, SORT_DESCENDING_MENU__MSG,  ''SORT_DESCENDING_MENUP__MSG, 17, 0
      buildmenuitem menuname, 80, 8012, SORT_DATE_MENU__MSG,        'treesort' '/R' 'D'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8013, SORT_TIME_MENU__MSG,        'treesort' '/R' 'T'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8014, SORT_SIZE_MENU__MSG,        'treesort' '/R' 'S'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8015, SORT_EASIZE_MENU__MSG,      'treesort' '/R' 'EA'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8016, SORT_FULLNAME_MENU__MSG,    'treesort' '/R' 'F'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8017, SORT_NAME_MENU__MSG,        'treesort' '/R' 'N'SORT_XXXX_MENUP__MSG, 1, 0
      buildmenuitem menuname, 80, 8018, SORT_EXTENSION_MENU__MSG,   'treesort' '/R' 'EX'SORT_XXXX_MENUP__MSG, 32769, 0

   elseif in_mark then  -- Build Inside-Mark pop-up -----------------------------------------------------------------------------------
      gray_if_charmark = 16384*( mt = 'C')
      gray_if_notcharmark = 16384 - gray_if_charmark
      buildmenuitem menuname, 80, 8000, UNMARK_MARK_MENU__MSG\9'Alt+U',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)
      buildmenuitem menuname, 80, 8001, DELETE_MARK_MENU__MSG\9'Alt+D',   'DUPMARK D'DELETE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_DELETE, 0)
      buildmenuitem menuname, 80, 8002, FILL_MARK_MENU__MSG\9'Alt+F',     'Fill'FILL_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_FILL, 0)
      buildmenuitem menuname, 80, 8003, REFLOW_MARK_MENU__MSG\9'Alt+P',   'ReflowPar2ReflowMargins'REFLOW_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_REFLOW, gray_if_charmark)
      buildmenuitem menuname, 80, 8004, UPCASE_MARK_MENU__MSG\9'Ctrl+F3', 'UppercaseMark'UPCASE_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_UPCASEMARK, 0)
      buildmenuitem menuname, 80, 8005, LOCASE_MARK_MENU__MSG\9'Ctrl+F4', 'LowercaseMark'LOCASE_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_LOCASEMARK, 0)
      buildmenuitem menuname, 80, 8006, SORT_MARK_MENU__MSG,              'Sort'SORT_MARK_MENUP__MSG' No undo!', 0, mpfrom2short(HP_POPUP_SORT, gray_if_charmark)
      buildmenuitem menuname, 80, 8007, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8008, 'Fi~nd selection',                 'FindMark'\1'Find marked string in text', 0, mpfrom2short( 0, 0)
      buildmenuitem menuname, 80, 8010, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8011, '~Comment'\9'Alt+K',               'Comment'\1'Comment marked lines', 0, mpfrom2short( 0, 0)
      buildmenuitem menuname, 80, 8012, 'Unco~mment'\9'Alt+Sh+K',          'Uncomment'\1'Uncomment marked lines', 0, mpfrom2short( 0, 0)
      buildmenuitem menuname, 80, 8013, \0,                       '',          4, 0
compile if WANT_TEXT_PROCS
      buildmenuitem menuname, 80, 8021, EXTEND_SENTENCE_MENU__MSG\9,      'EXTENDSENTENCE'EXTEND_SENTENCE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_EXTENDSENTENCE, 0)
      buildmenuitem menuname, 80, 8022, EXTEND_PARAGRAPH_MENU__MSG\9,     'EXTENDPARAGRAPH'EXTEND_PARAGRAPH_MENUP__MSG, 0, mpfrom2short(HP_POPUP_EXTENDPARAGRAPH, 0)
      buildmenuitem menuname, 80, 8023, \0,                       '',          4, 0
compile endif -- WANT_TEXT_PROCS
      buildmenuitem menuname, 80, 8030, SHIFT_MENU__MSG,   ''SHIFT_MENUP__MSG, 17, mpfrom2short(HP_POPUP_SHIFT, 0/*gray_if_charmark*/)
      nodismiss_gifc = /*gray_if_charmark +*/ 32  -- 32 = MIA_NODISMISS
      buildmenuitem menuname, 80, 8031, SHIFTLEFT_MENU__MSG\9'Ctrl+F7',   'DoCmd 1 ShiftLeft'SHIFTLEFT_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT, nodismiss_gifc)
      buildmenuitem menuname, 80, 8032, SHIFTLEFT3_MENU__MSG,             'DoCmd 3 ShiftLeft'SHIFTLEFT3_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT3, nodismiss_gifc)
      buildmenuitem menuname, 80, 8033, SHIFTLEFT8_MENU__MSG,             'DoCmd 8 ShiftLeft'SHIFTLEFT8_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTLEFT8, nodismiss_gifc)
      buildmenuitem menuname, 80, 8034, SHIFTRIGHT_MENU__MSG\9'Ctrl+F8',  'DoCmd 1 ShiftRight'SHIFTRIGHT_MENUP__MSG, 2049, mpfrom2short(HP_POPUP_SHIFTRIGHT, nodismiss_gifc)
      buildmenuitem menuname, 80, 8035, SHIFTRIGHT3_MENU__MSG,            'DoCmd 3 ShiftRight'SHIFTRIGHT3_MENUP__MSG, 1, mpfrom2short(HP_POPUP_SHIFTRIGHT3, nodismiss_gifc)
      buildmenuitem menuname, 80, 8036, SHIFTRIGHT8_MENU__MSG,            'DoCmd 8 ShiftRight'SHIFTRIGHT8_MENUP__MSG, 32769, mpfrom2short(HP_POPUP_SHIFTRIGHT8, nodismiss_gifc)
      buildmenuitem menuname, 80, 8037, CENTER_MARK_MENU__MSG\9'Alt+T',   'CenterMark'CENTER_MARK_MENUP__MSG, 0, mpfrom2short(HP_POPUP_CENTERMARK, gray_if_charmark)
      buildmenuitem menuname, 80, 8040, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8041, CLIP_COPY_MENU__MSG\9 || CTRL_KEY__MSG'+'INSERT_KEY__MSG ,  'Copy2Clip'CLIP_COPY_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPY, 0)
      buildmenuitem menuname, 80, 8042, CUT_MENU__MSG\9 || SHIFT_KEY__MSG'+'DELETE_KEY__MSG, 'Cut'CUT_MENUP__MSG,       0, mpfrom2short(HP_EDIT_CUT, 0)
      buildmenuitem menuname, 80, 8043, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8044, STYLE_MENU__MSG\9'Ctrl+Y',        'FontList'STYLE_MENUP__MSG,    0, mpfrom2short(HP_OPTIONS_STYLE, 0)
compile if CHECK_FOR_LEXAM
   if LEXAM_is_available then
compile endif
      buildmenuitem menuname, 80, 8050, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8051, PROOF_MENU__MSG,                  'proof'PROOF_MENUP__MSG,     0, mpfrom2short(HP_OPTIONS_PROOF, 16384*(mt<>'L'))
compile if CHECK_FOR_LEXAM
   endif
compile endif
      buildmenuitem menuname, 80, 8052, \0,                               '',          4, 0
      buildmenuitem menuname, 80, 8053, PRT_MARK_MENU__MSG'...',          'PRINTDLG M'ENHPRT_MARK_MENUP__MSG,0, mpfrom2short(HP_EDIT_ENHPRINT, 0)

   elseif mt <> ' ' then  -- Build Outside-Mark pop-up --------------------------------------------------------------------------------
      'MH_gotoposition'
      buildmenuitem menuname, 80, 8000, COPY_MARK_MENU__MSG\9'Alt+C',     'DUPMARK C'COPY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_COPYMARK, 0)
      buildmenuitem menuname, 80, 8001, MOVE_MARK_MENU__MSG\9'Alt+M',     'DUPMARK M'MOVE_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_MOVE, 0)
      buildmenuitem menuname, 80, 8002, OVERLAY_MARK_MENU__MSG\9'Alt+O',  'DUPMARK O'OVERLAY_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_OVERLAY, 0)
      buildmenuitem menuname, 80, 8003, ADJUST_MARK_MENU__MSG\9'Alt+A',   'DUPMARK A'ADJUST_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_ADJUST, 0)
      buildmenuitem menuname, 80, 8004, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8005, UNMARK_MARK_MENU__MSG\9'Alt+U',   'DUPMARK U'UNMARK_MARK_MENUP__MSG, 0, mpfrom2short(HP_EDIT_UNMARK, 0)

   else  -- Build No-mark pop-up ------------------------------------------------------------------------------------------------------
      'MH_gotoposition'
      ch = substr( textline(.line), .col, 1)
      gray_if_space = 16384*( ch = ' ' | not .line)
      buildmenuitem menuname, 80, 8000, MARK_WORD_MENU__MSG\9'Alt+W',      'MARKWORD'MARK_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKWORD, gray_if_space)
      buildmenuitem menuname, 80, 8001, MARK_TOKEN_MENU__MSG\9'Alt+Sh+W',  'MARKTOKEN'MARK_TOKEN_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKTOKEN, gray_if_space)
      buildmenuitem menuname, 80, 8002, FIND_TOKEN_MENU__MSG\9'Ctrl+W',    'FINDWORD'FIND_TOKEN_MENUP__MSG, 0, mpfrom2short(HP_POPUP_FINDTOKEN, gray_if_space)
      buildmenuitem menuname, 80, 8010, \0,                       '',          4, 0
compile if WANT_TEXT_PROCS
      buildmenuitem menuname, 80, 8021, MARK_SENTENCE_MENU__MSG,           'MARKSENTENCE'MARK_SENTENCE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKSENTENCE, 0)
      buildmenuitem menuname, 80, 8022, MARK_PARAGRAPH_MENU__MSG,          'MARKPARAGRAPH'MARK_PARAGRAPH_MENUP__MSG, 0, mpfrom2short(HP_POPUP_MARKPARAGRAPH, 0)
      buildmenuitem menuname, 80, 8023, \0,                       '',          4, 0
compile endif -- WANT_TEXT_PROCS
      buildmenuitem menuname, 80, 8025, '~Reflow paragraph'\9'Alt+P',      'ReflowPar2ReflowMargins'\1'Reflow text from cursor to next empty line', 0, mpfrom2short(HP_POPUP_REFLOW, 0)
      buildmenuitem menuname, 80, 8026, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8030, 'Toggle ~case of word'\9'Ctrl+F1', 'CaseWord'\1'Rotate case: lower -> mixed -> upper', 0, mpfrom2short(HP_POPUP_UPCASEWORD, gray_if_space)
      buildmenuitem menuname, 80, 8031, UPCASE_WORD_MENU__MSG\9'Ctrl+Sh+F2', 'UppercaseWord'UPCASE_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_UPCASEWORD, gray_if_space)
      buildmenuitem menuname, 80, 8032, LOCASE_WORD_MENU__MSG\9'Ctrl+F2',  'LowercaseWord'LOCASE_WORD_MENUP__MSG, 0, mpfrom2short(HP_POPUP_LOCASEWORD, gray_if_space)
      buildmenuitem menuname, 80, 8033, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8034, CENTER_LINE_MENU__MSG\9'Shift+F5', 'CenterLine'CENTER_LINE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_CENTERLINE, 0)
      buildmenuitem menuname, 80, 8035, TOP_LINE_MENU__MSG,                'newtop'TOP_LINE_MENUP__MSG, 0, mpfrom2short(HP_POPUP_TOP, 0)
      -- Cascade menu now replaced by inline menu items, because it doesnot work:
;       buildmenuitem menuname, 80, 8041, PASTE_C_MENU__MSG,    PASTE_C_MENUP__MSG,   17+64, mpfrom2short(HP_EDIT_PASTEMENU, 0)
;       buildmenuitem menuname, 80, 8042, PASTE_C_MENU__MSG,   'Paste C'PASTE_C_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEC, 0)
;       buildmenuitem menuname, 80, 8043, PASTE_L_MENU__MSG,   'Paste'PASTE_L_MENUP__MSG,     0, mpfrom2short(HP_EDIT_PASTE, 0)
;       buildmenuitem menuname, 80, 8044, PASTE_B_MENU__MSG,   'Paste B'PASTE_B_MENUP__MSG,   32769, mpfrom2short(HP_EDIT_PASTEB, 0)
      buildmenuitem menuname, 80, 8050, \0,                       '',          4, 0
      buildmenuitem menuname, 80, 8051, PASTE_C_MENU__MSG\9'Sh+Ins',       'Paste C'PASTE_C_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEC, 0)
      buildmenuitem menuname, 80, 8052, PASTE_L_MENU__MSG,                 'Paste'PASTE_L_MENUP__MSG,     0, mpfrom2short(HP_EDIT_PASTE, 0)
      buildmenuitem menuname, 80, 8053, PASTE_B_MENU__MSG\9'Ctrl+Sh+Ins',  'Paste B'PASTE_B_MENUP__MSG,   0, mpfrom2short(HP_EDIT_PASTEB, 0)

   endif
compile if not VANILLA
tryinclude 'mymsemnu.e'  -- For user-added configuration
compile endif
   return

  -- Cascade menu now replaced by inline menu items, because it doesnot work:
; defc add_cascade_popupmenu
;    universal nepmd_hini
;
;    KeyPath = "\NEPMD\User\Mouse\Mark\DefaultPaste"
;    DefaultPaste = NepmdQueryConfigValue( nepmd_hini, KeyPath)
;    if DefaultPaste = 'C' then
;       AlternatePaste = 'L'
;    else
;       AlternatePaste = 'C'
;    endif
;    if DefaultPaste = 'L' then    -- arg for defc paste maybe 'C', 'B' or ''
;       DefaultPaste = ''
;    endif
;    if AlternatePaste = 'L' then  -- arg for defc paste maybe 'C', 'B' or ''
;       AlternatePaste = ''
;    endif
;
;    if DefaultPaste = 'C' then
;       'cascade_popupmenu 8041 8042'  -- Paste cascade; default is Paste (character mark)
;    elseif DefaultPaste = 'B' then
;       'cascade_popupmenu 8041 8044'  -- Paste cascade; default is Paste Block
;    else
;       'cascade_popupmenu 8041 8043'  -- Paste cascade; default is Paste Lines
;    endif
;
; #define ETK_FID_POPUP          50
;
; ; similar to defc cascade_menu in MENU.E, but another hwndp
; defc cascade_popupmenu
;    parse arg menuid defmenuid .
;    menuitem = copies( \0, 16)  -- 2 bytes ea. pos'n, style, attribute, identity; 4 bytes submenu hwnd, long item
;    hwndp= dynalink32( 'PMWIN',
;                       '#899',                -- ordinal for Win32WindowFromID
;                       gethwndc(EPMINFO_EDITCLIENT) ||
;                       atol(ETK_FID_POPUP) )
;    if not windowmessage( 1,
;                          hwndp,
;                          386,                  -- x182, MM_QueryItem
;                          menuid + 65536,
;                          ltoa(offset(menuitem) || selector(menuitem), 10))
;    then
;       return
;    endif
;    hwnd = substr( menuitem, 9, 4)
;
;    call dynalink32( 'PMWIN',
;                     '#874',     -- Win32SetWindowBits
;                      hwnd         ||
;                      atol(-2)     ||  -- QWL_STYLE
;                      atol(64)     ||  -- MS_CONDITIONALCASCADE
;                      atol(64))        -- MS_CONDITIONALCASCADE
;    if defmenuid <> '' then  -- Default menu item
;       call windowmessage( 1,
;                           ltoa( hwnd,10),
;                           1074,                  -- x432, MM_SETDEFAULTITEMID
;                           defmenuid, 0)  -- Make arg(2) the default menu item
;    endif

