/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.14 2003-06-29 20:23:05 aschn Exp $
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

/*
; Better close NEPMD.INI by the EPM loader or let every Nepmd*Config function
; automatically open the NEPMD.INI explicitely if not already done?
;
; defexit is executed on unlinking the .EX file, where it is defined.
; Here it is included in EPM.EX, so it is executed on closing any EPM
; edit window.
; Closing the NEPMD.INI is not intended, if another EPM edit window is
; remaining.
;
; If NEPMD.INI is not closed, then every later action on NEPMD.INI will
; not proceed and return with rc = 105 (Previous semaphore owner ended
; without freeing the semaphore). This has happened, if one EPM instance
; with parameter /i is started.
;
; So activate defexit here again?
;
defexit
   universal nepmd_hini
   rc = NepmdCloseConfig( nepmd_hini );
   -- sayerror doesn't work on defexit most of the time
   if (rc > 0) then
      sayerror 'Configuration repository could not be closed, rc='rc;
   --else
   --   sayerror 'Configuration repository closed successfully';
   endif
*/

compile if not defined(NEPMD_OPTFLAGS_WORKAROUND)
const
   NEPMD_OPTFLAGS_WORKAROUND = 1
compile endif

; ------------------------------------------------------------------
define DEBUG_MAIN = 0

defmain    /* defmain should be used to parse the command line arguments */
compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
compile endif
compile if NEPMD_OPTFLAGS_WORKAROUND
   universal app_hini
compile endif
   universal should_showwindow
   universal nepmd_hini
   universal default_search_options, default_edit_options, default_save_options
   should_showwindow = 1  -- Lets cmdline commands inhibit the SHOWWINDOW.

   doscmdline = 'e 'arg(1) /* Can do special processing of DOS command line.*/
; sayerror 'DosCmdLine = "'arg(1)'"'
   unnamed_name=UNNAMED_FILE_NAME  -- Define the name once to save a few bytes.
   .filename = unnamed_name      -- Ver. 3.11:  Don't rely on fileid.

compile if DEBUG_MAIN
   messageNwait('DEFMAIN: arg(1)="'arg(1)'"')
compile endif

;   sayerror 'DEFMAIN!, arg(1) = ['arg(1)']'

compile if WANT_APPLICATION_INI_FILE

 compile if NEPMD_OPTFLAGS_WORKAROUND
   -- With certain settings in EPM.INI the defmain procedure will stop.
   -- Then EPM remains in the background and all settings are reset to
   -- their internal defaults.
   -- As a workaround for trapping EPM windows...
   -- (
   --    if the filespec contains wildcards
   -- and
   --    if the REXX profile bit in EPM.INI is 0
   -- and
   --    if the Toolbar is set to the built-in Toolbar (not stored in EPM.INI)
   --       while the Toolbar is activated.
   -- )
   -- or
   --    if the CUA marking bit in EPM.INI is 1
   --
   -- This switches the REXX profile support on and the CUA marking
   -- off temporarily.
   -- Before doing so, the current settings from EPM.INI are queried and
   -- saved as SavedCUAMarking and SavedRexxProfile to reset these
   -- settings to their values from before applying the workaround later.
/*
see also: STDCTRL.E: defc initconfig
   Bit              Setting
        for value = 1      for value = 0
   ---  ----------------   -------------------
    1   statusline on      statusline off
    2   msgline on         msgline off
    3   vscrollbar on      vscrollbar off
    4   hscrollbar on      hscrollbar off
    5   fileicon on        fileicon off
    6   rotbuttons on      rotbuttons off
    7   ?extra on          ?extra off
    8   CUA marking        advanced marking
    9   menuprompt on      menuprompt off
   10   stream mode        line mode
   11   longnames on       longnames off
   12   REXX profile on    REXX profile off
   13   escapekey on       escapekey off
   14   tabkey on          tabkey off
   15   bgbitmap on        bgbitmap off
   16   toolbar on         toolbar off
   17   dropstyle modif    dropstyle unmodif
   18   ?extra stuff on    ?extra stuff off
*/
   appname = 'EPM'
   inikey  = 'OPTFLAGS'
   inidata = queryprofile( app_hini, appname, inikey )
   SavedCuaMarking  = strip( word( inidata, 8 ) )
   SavedRexxProfile = strip( word( inidata, 12 ) )

   -- reset to a valid entry if none found
   if inidata = '' then
      inidata = '1 1 1 1 1 1 0 0 1 1 1 1 1 0 1 1 0 '\0
      --   Bit:  1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7
   endif

   -- switch CUA marking off
   Bit      = 8
   newvalue = 0
   inidata  = overlay( newvalue, inidata, 2*Bit - 1 )

   -- set REXX profile on
   Bit      = 12
   newvalue = 1
   inidata  = overlay( newvalue, inidata, 2*Bit - 1 )

   call setprofile( app_hini, appname, inikey, inidata )
 compile endif  -- NEPMD_OPTFLAGS_WORKAROUND

   'initconfig'                  -- Check if anything of interest is in OS2.INI and get settings from EPM.INI

 compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after INITCONFIG')
 compile endif

compile endif  -- WANT_APPLICATION_INI_FILE

   -- Link the NEPMD library. Open a MessageBox if .ex file not found.
   --    o  Any linking can not be processed before 'initconfig' in MAIN.E.
   --       Otherwise the EPM.INI or parts of it will not be processed
   --       (i.e. the toolbar will get lost and the fonts will change
   --       to their default values).
   --    o  Sometimes defmain is triggered 2 times, so 'linkverify nepmdlib.ex'
   --       may cause timing(?) problems then:
   --       When the buit-in Toolbar is activated and REXX profile is switched
   --       off in EPM.INI, EPM has trapped after some seconds when the files are
   --       loaded. This could be duplicated well, when the calling command contains
   --       wildcards in the filename.
   --    o  Therefore it is now checked if the contained function
   --       'NepmdOpenConfig' is already defined.
   --    o  That doesn't seem to suffice, so the REXX profile is activated
   --       constantly.
   if not isadefproc( 'NepmdOpenConfig' ) then  -- if proc not defined
      'linkverify  nepmdlib.ex'
   endif

   -- Open NEPMD.INI and set the returned handle as the universal var 'nepmd_hini'
   --sayerror 'Open NEPMD.INI'
   nepmd_hini = NepmdOpenConfig()
   parse value nepmd_hini with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be opened, rc='rc;
   endif

   -- Process NEPMD.INI initialisation:
   --    o  write default values from nepmd\netlabs\bin\defaults.dat to NEPMD.INI,
   --       application 'RegDefaults', if 'RegDefaults' was not found
   --sayerror 'Init NEPMD.INI'
   rc = NepmdInitConfig( nepmd_hini )
   parse value rc with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be initialized, rc='rc;
   endif

   -- sayerror 'DEFMAIN: nepmd_hini = 'nepmd_hini

compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH) or DELAY_SAVEPATH_CHECK
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

   /* E automatically created an empty file when it started.              */
   /* If user specified file(s) to edit, get rid of the empty file.       */

do i=1 to 1  -- use a loop here to make 'leave' omit the rest
   getfileid emptyfileid, UNNAMED_FILE_NAME
   if emptyfileid='' then             -- User deleted it?
      leave
   endif
   if emptyfileid.modify then         -- User changed it?
      leave
   endif
   if newfileid=emptyfileid then      -- Check if others in ring.
      nextfile
      getfileid newfileid
      prevfile
   endif
   if newfileid<>emptyfileid then
      activatefile emptyfileid
      'xcom q'
      activatefile newfileid
      call select_edit_keys()
   endif
end

compile if WANT_APPLICATION_INI_FILE
 compile if NEPMD_OPTFLAGS_WORKAROUND
   EpmIniChanged = 0
   if SavedRexxProfile = 0 then
      --sayerror 'Switching profile support off as defined in EPM.INI before'
      'profile off'
      EpmIniChanged = 1
   endif
   if SavedCUAMarking = 1 then
      --sayerror 'Switching CUA marking on as defined in EPM.INI before'
      'CUA_mark_toggle'
      EpmIniChanged = 1
   endif
   if EpmIniChanged = 1 then
      'saveoptions'
   endif
 compile endif  -- NEPMD_OPTFLAGS_WORKAROUND
compile endif  -- WANT_APPLICATION_INI_FILE

   -- process PROFILE.ERX
compile if WANT_PROFILE
 compile if WANT_PROFILE='SWITCH'
   if REXX_PROFILE then
 compile endif
      profile = 'profile.erx'
      -- REXX_PROFILE is now searched in .;%PATH%;%EPMPATH% instead of .;%EPMPATH%;%PATH%
      findfile profile1, profile, 'PATH'
      if rc then findfile profile1, profile, EPATH; endif
      if not rc then
         'rx' profile1 arg(1)
      endif
 compile if WANT_PROFILE='SWITCH'
   endif
 compile endif
compile endif

   -- automatically link .ex files from myepm\autolink
   call NepmdAutoLink()

   -- show menu and window
   -- this moved to the end of defmain
compile if INCLUDE_MENU_SUPPORT /*& not DELAY_MENU_CREATION*/
   call showmenu_activemenu()  -- show the EPM menu (before the window is shown)
 compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after SHOWMENU')
 compile endif
compile endif
   if should_showwindow then  -- should_showwindow = 1
   -- see also: STDCNF.E for menu
      call showwindow('ON')
compile if DEBUG_MAIN
      messageNwait('DEFMAIN: after SHOWWINDOW')
compile endif
   endif

   'postme post_main'

; This command is called with 'postme' at the very end of defmain.
defc post_main

compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif

   -- set EPM pointer from standard arrow to text pointer
   -- bug fix: even standard EPM doesn't show the correct pointer after
   --          a new edit window was opened
   -- defined in defc initconfig, STDCTRL.E
   -- must be delayed with 'postme' to work properly
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif

