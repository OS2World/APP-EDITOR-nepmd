/****************************** Module Header *******************************
*
* Module Name: select.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: select.e,v 1.3 2002-08-21 11:52:53 aschn Exp $
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
compile if not defined(LOCAL_MOUSE_SUPPORT)
   const LOCAL_MOUSE_SUPPORT = 0
compile endif
const
   TransparentMouseHandler = "TransparentMouseHandler"

;  SELECT.E                                                 Bryan Lewis 1/2/89
;
;  This replaces the clumsy old select_edit_keys() procedure, which had to
;  be explicitly called after any action that might change the current file.
;  This DEFSELECT event is automatically triggered whenever the current file
;  after an action is different from the one before the action.  It never
;  needs to be (and can't be) explicitly called.
;
;  This is triggered after all command processing is done, if the then-current
;  file is different from the one before the command.  If a command switches
;  to a temporary file but switches back to the original file before ending,
;  this event will not be triggered.
;
;  Because of other improvements -- keyset, tabs and margins are bound to
;  the file now, and are selected at load time in a DEFLOAD event -- there's
;  not much work to be done here.
;
defproc select_edit_keys()
   /* Dummy proc for compatibility.  Select_edit_keys() isn't used any more.*/

defselect
   universal messy
compile if LOCAL_MOUSE_SUPPORT
   universal LMousePrefix
   universal EPM_utility_array_ID
compile endif
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif
compile if WANT_EPM_SHELL & INCLUDE_STD_MENUS
   universal shell_index
   if shell_index then
      is_shell = leftstr(.filename, 15) = ".command_shell_"
 compile if not defined(STD_MENU_NAME)
      SetMenuAttribute( 103, 16384, is_shell)
      SetMenuAttribute( 104, 16384, is_shell)
 compile elseif STD_MENU_NAME = 'ovshmenu.e'
      SetMenuAttribute( 152, 16384, is_shell)
      SetMenuAttribute( 153, 16384, is_shell)
 compile elseif STD_MENU_NAME = 'fevshmnu.e'
      SetMenuAttribute( 142, 16384, is_shell)
      SetMenuAttribute( 143, 16384, is_shell)
 compile endif
   endif  -- shell_index
compile endif
compile if LOCAL_MOUSE_SUPPORT
   getfileid ThisFile
   OldRC = Rc
   rc = get_array_value(EPM_utility_array_ID, "LocalMausSet."ThisFile, NewMSName)
   if RC then
      if rc=-330 then
         -- no mouseset bound to file yet, assume blank.
         LMousePrefix = TransparentMouseHandler"."
      else
         call messagenwait('RC='RC)
      endif
      RC = OldRC
   else
      LMousePrefix = NewMSName"."
   endif
compile endif

compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
   if bkm_avail <> '' then
 compile endif
      call bkm_defselect()
 compile if WANT_EBOOKIE = 'DYNALINK'
   endif
 compile endif
compile endif  -- WANT_EBOOKIE

   -- sayerror 'DEFSELECT occurred for file '.filename'.'

