/****************************** Module Header *******************************
*
* Module Name: select.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: select.e,v 1.2 2002-07-22 19:01:48 cla Exp $
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

compile if eversion >= '4.12'
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
  compile if EPM32
      SetMenuAttribute( 104, 16384, is_shell)
  compile endif
 compile elseif STD_MENU_NAME = 'ovshmenu.e'
      SetMenuAttribute( 152, 16384, is_shell)
  compile if EPM32
      SetMenuAttribute( 153, 16384, is_shell)
  compile endif
 compile elseif STD_MENU_NAME = 'fevshmnu.e'
      SetMenuAttribute( 142, 16384, is_shell)
  compile if EPM32
      SetMenuAttribute( 143, 16384, is_shell)
  compile endif
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

compile else          -- This is for the old way of doing SELECT.

 compile if SHOW_MODIFY_METHOD
defproc show_modify
 compile endif
 compile if SHOW_MODIFY_METHOD = 'COLOR'
   if .modify then
      .markcolor= MODIFIED_MARKCOLOR
      .windowcolor= MODIFIED_WINDOWCOLOR
   else
      .markcolor= MARKCOLOR
      .windowcolor= WINDOWCOLOR
   endif
 compile endif

 compile if SHOW_MODIFY_METHOD = 'FKTEXTCOLOR'
   if .modify then
      .functionkeytextcolor= MODIFIED_FKTEXTCOLOR
   else
      .functionkeytextcolor= FUNCTIONKEYTEXTCOLOR
   endif
 compile endif

 compile if SHOW_MODIFY_METHOD = 'TITLE'
   if .modify then
      .filenamecolor= MODIFIED_FILENAMECOLOR
      .monofilenamecolor= MODIFIED_MONOFILENAMECOLOR
   else
      .filenamecolor= FILENAMECOLOR
      .monofilenamecolor= MONOFILENAMECOLOR
   endif
 compile endif

defproc select_edit_keys    /* Selection keys for particular file extension */
 compile if ALTERNATE_KEYSETS
   universal expand_on
   universal messy

   ext=filetype()
 compile endif

   keys edit_keys          /* default keyset */

 compile if SHOW_MODIFY_METHOD
   call show_modify()
 compile endif

compile endif
