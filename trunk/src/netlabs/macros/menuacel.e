/****************************** Module Header *******************************
*
* Module Name: menuacel.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: menuacel.e,v 1.2 2002-07-22 19:01:11 cla Exp $
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
; This file is for EPM only.  It is common code that is related to
; building the menu and accelerator table.
; It is included by STDCNF.E for EPM 5.xx, and by MAIN.E (after the
; SHOWWINDOW) for EPM 6.xx.  The difference is that EPM 6.xx includes
; a dummy menu as a resource, allowing the building of the real menu
; to be deferred until after the window is shown - this lets the initial
; window be shown about 10% faster.

 compile if WANT_STACK_CMDS = 'SWITCH'
  compile if defined(my_STACK_CMDS)
   stack_cmds = my_STACK_CMDS
  compile else
   stack_cmds = 0
  compile endif
  compile if WANT_APPLICATION_INI_FILE
   compile if WPS_SUPPORT
   if wpshell_handle then
; Key 16
;     this_ptr = peek32(shared_mem+64, 4); -- if this_ptr = \0\0\0\0 then return; endif
;     parse value peekz(this_ptr) with ? stack_cmds ?
      stack_cmds = substr(peekz(peek32(wpshell_handle, 64, 4)), 6, 1)
   else
   compile endif
   newcmd=queryprofile( app_hini, appname, INI_STACKCMDS)
   if newcmd<>'' then stack_cmds = newcmd; endif
   compile if WPS_SUPPORT
   endif  -- wpshell_handle
   compile endif
  compile endif  -- WANT_APPLICATION_INI_FILE
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
  compile if defined(my_CUA_MENU_ACCEL)
   CUA_MENU_ACCEL = my_CUA_MENU_ACCEL
  compile else
   CUA_MENU_ACCEL = 0
  compile endif
  compile if WANT_APPLICATION_INI_FILE
   compile if WPS_SUPPORT
   if wpshell_handle then
      CUA_MENU_ACCEL = substr(peekz(peek32(wpshell_handle, 72, 4)), 7, 1)
   else
   compile endif
   newcmd=queryprofile( app_hini, appname, INI_CUAACCEL)
   if newcmd<>'' then CUA_MENU_ACCEL = newcmd; endif
   compile if WPS_SUPPORT
   endif  -- wpshell_handle
   compile endif
  compile endif -- WANT_APPLICATION_INI_FILE
 compile endif
 compile if CHECK_FOR_LEXAM
  compile if EVERSION >= '5.51'
    LEXAM_is_available = (lexam(-1) <> '')
  compile else
   compile if EVERSION >= '5.21'
    display -10
   compile else
    display -2
   compile endif
    LEXAM_is_available = (-326=dynalink(LEXAM_DLL, 'LAM@Watson', 0))
    if LEXAM_is_available then -- "Unrecognized procedure name" - i.e., library was found.
       call dynafree(LEXAM_DLL); call dynafree(LEXAM_DLL)
    endif
   compile if EVERSION >= '5.21'
    display 10
   compile else
    display 2
   compile endif
  compile endif  -- EVERSION >= 5.60
 compile endif  -- CHECK_FOR_LEXAM
 compile if INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS
'loaddefaultmenu'
 compile endif
 compile if EVERSION > '5.20'
'loadaccel'
 compile endif
