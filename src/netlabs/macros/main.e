/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.2 2002-07-22 19:00:52 cla Exp $
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
define DEBUG_MAIN = 0

defmain    /* defmain should be used to parse the command line arguments */
compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
compile endif
compile if EVERSION < 5
   universal comsfileid, messy
compile else
   universal should_showwindow
   should_showwindow = 1  -- Lets cmdline commands inhibit the SHOWWINDOW.
compile endif

   doscmdline = 'e 'arg(1) /* Can do special processing of DOS command line.*/
; sayerror 'DosCmdLine = "'arg(1)'"'
   unnamed_name=UNNAMED_FILE_NAME  -- Define the name once to save a few bytes.
   .filename = unnamed_name      -- Ver. 3.11:  Don't rely on fileid.

compile if DEBUG_MAIN
   messageNwait('DEFMAIN: arg(1)="'arg(1)'"')
compile endif

compile if EVERSION < 5
   if messy then .windowoverlap=1; endif    -- messy-desk style?
compile endif

compile if EPM
 compile if WANT_APPLICATION_INI_FILE
   'initconfig'                  -- Check if anything of interest is in OS2.INI
  compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after INITCONFIG')
  compile endif
 compile endif
compile endif

compile if (EPM and (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH)) or DELAY_SAVEPATH_CHECK
   call check_savepath()
compile endif

compile if SUPPORT_USER_EXITS
   if isadefproc('defmain_exit') then
      call defmain_exit(doscmdline)
   endif
compile endif

   doscmdline                    -- Execute the doscmdline.

compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after DOSCMDLINE')
compile endif

   getfileid newfileid
compile if EVERSION < 5
   if 'e'<>doscmdline then  /* Put doscmdline into coms stack if nontrivial.*/
      getline line,comsfileid.last,comsfileid
      if line<>doscmdline then  -- Don't duplicate last line
         if comsfileid.last > 30 then deleteline 1,comsfileid endif  -- trim if too big
         insertline doscmdline,comsfileid.last+1,comsfileid
      endif
   endif
compile endif

   /* E automatically created an empty file when it started.              */
   /* If user specified file(s) to edit, get rid of the empty file.       */
do i=1 to 1
   getfileid emptyfileid, UNNAMED_FILE_NAME
   if emptyfileid='' then             -- User deleted it?
      leave
   endif
   if emptyfileid.modify then         -- User changed it?
      leave
   endif
   if newfileid=emptyfileid then      -- Check if others in ring.
compile if EVERSION < 5
      if messy then nextwindow else nextfile endif
      getfileid newfileid
      if messy then prevwindow else prevfile endif
compile else
      nextfile
      getfileid newfileid
      prevfile
compile endif
   endif
   if newfileid<>emptyfileid then
      activatefile emptyfileid
      'xcom q'
compile if EPM and MENU_LIMIT
      call updateringmenu()
compile endif
      activatefile newfileid
      call select_edit_keys()
   endif
end

compile if CURSOR_ON_COMMAND and not EPM
   cursor_command
compile endif

compile if EPM
 compile if INCLUDE_MENU_SUPPORT & not DELAY_MENU_CREATION
   call showmenu_activemenu()  -- show the EPM menu (before the window is shown)
  compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after SHOWMENU')
  compile endif
 compile endif
   if should_showwindow then
 compile if DELAY_MENU_CREATION
  compile if defined(STD_MENU_NAME)
   compile if STD_MENU_NAME = 'OVSHMENU.E'  -- This is one we know about...
      showmenu 1002, 5
   compile endif
   compile if STD_MENU_NAME = 'FEVSHMNU.E'  -- This is the only other one we know about...
      showmenu 1003, 5
   compile endif
  compile else  -- STD_MENU_NAME not defined; we're using STDMENU.E:
      showmenu 1001, 5
  compile endif
 compile endif -- DELAY_MENU_CREATION
      call showwindow('ON')
 compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after SHOWWINDOW')
 compile endif
   endif
compile endif

compile if EPM
 compile if DELAY_MENU_CREATION
  compile if 1  -- Ready for when ability to load from RC is in...
   'postme main2'
  compile else
   'main2' arg(1)
  compile endif

defc main2  -- Everything after the SHOWWINDOW is a separate command, posted so as not to slow down initial display of window.
   universal appname, app_hini
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
 compile if WPS_SUPPORT
   universal wpshell_handle
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
 compile endif
 compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
 compile endif
   include 'menuacel.e'
 compile if INCLUDE_MENU_SUPPORT
   call showmenu_activemenu()  -- show the EPM menu (after the window is shown)
  compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after SHOWMENU')
  compile endif
 compile endif
compile endif -- DELAY_MENU_CREATION
compile endif -- EPM

compile if WANT_PROFILE
 compile if WANT_PROFILE='SWITCH'
   if REXX_PROFILE then
 compile endif
      profile = 'profile.erx'
      findfile profile1, profile, EPATH
      if rc then findfile profile1, profile, 'PATH'; endif
      if not rc then
compile if 0 -- debug for LaMail
         if isadefproc('write_debug_file') then
            write_debug_file(getpminfo(EPMINFO_EDITCLIENT)':  calling rexx profile' profile1 'w/ arg "'arg(1)'"'\13\10, 0)
         endif
compile endif
         'rx' profile1 arg(1)
      endif
 compile if WANT_PROFILE='SWITCH'
   endif
 compile endif
compile endif
