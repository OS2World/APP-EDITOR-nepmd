/****************************** Module Header *******************************
*
* Module Name: select.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: select.e,v 1.5 2004-02-22 20:20:47 aschn Exp $
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
const
compile if not defined(LOCAL_MOUSE_SUPPORT)
   LOCAL_MOUSE_SUPPORT = 0
compile endif
   TransparentMouseHandler = "TransparentMouseHandler"
compile if not defined(NEPMD_USE_DIRECTORY_OF_CURRENT_FILE)
   NEPMD_USE_DIRECTORY_OF_CURRENT_FILE = 0
compile endif
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_SELECT)
   NEPMD_DEBUG_SELECT = 0
compile endif

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
compile if LOCAL_MOUSE_SUPPORT
   universal LMousePrefix
   universal EPM_utility_array_ID
compile endif
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif

compile if NEPMD_DEBUG_SELECT and NEPMD_DEBUG
   call NepmdPmPrintf( 'DEFSELECT: '.filename)
compile endif

   -- moved the SetMenuAttribute stuff for command shell windows to STDCTRL.E, defc menuinit_0

compile if LOCAL_MOUSE_SUPPORT
   -- LOCAL_MOUSE_SUPPORT = 1 enables separate mouse definitions for every file in the ring.
   -- Additional changes per register_mousehandler will then be local (for every file) only.
   -- Because of this feature is not built-in as field var (starting with a '.' and belonging
   -- to each file separately), it must be achieved by the use of an array var and must be
   -- switched on every defselect.
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
compile endif  -- LOCAL_MOUSE_SUPPORT

compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
   if bkm_avail <> '' then
 compile endif
      call bkm_defselect()
 compile if WANT_EBOOKIE = 'DYNALINK'
   endif
 compile endif
compile endif  -- WANT_EBOOKIE

; --- Change to dir of current file -----------------------------------------
Filename = .filename
compile if NEPMD_USE_DIRECTORY_OF_CURRENT_FILE
   if pos( ':\', Filename) then
      call directory('\')
      call directory(Filename'\..')
   endif
compile endif

