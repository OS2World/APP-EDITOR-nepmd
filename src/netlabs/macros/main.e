/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.8 2002-10-16 05:18:26 aschn Exp $
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

/**/
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
; So defexit is activated here again.
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
/**/

define DEBUG_MAIN = 0

defmain    /* defmain should be used to parse the command line arguments */
compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
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
   'initconfig'                  -- Check if anything of interest is in OS2.INI
 compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after INITCONFIG')
 compile endif
compile endif

   -- Link the NEPMD library. Open a MessageBox if .ex not found.
   --    o  Any linking can not be processed before 'initconfig' in MAIN.E.
   --       Otherwise the EPM.INI or parts of it will not be processed
   --       (i.e. the toolbar will get lost and the fonts will change
   --       to their default values).
   'linkverify  nepmdlib.ex'

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

;   sayerror 'DEFMAIN: nepmd_hini = 'nepmd_hini

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
do i=1 to 1                                                   --<-----------------------------------------
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

compile if    CURSOR_ON_COMMAND
   cursor_command   --<------------------------------------------------------------------- ???
compile endif

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

   -- Set default options here to avoid loading of PROFILE.ERX
   -- Note: They can be overwritten with the 'universal' commands in PROFILE.ERX.

   -- default_search_options
   --    internal default: '+ef'
   --       +  from top to bottom      e  respect case
   --       -  from bottom to top      c  don't respect case
   --       f  from left to right      g  grep
   --       r  from right to left      x  extended grep
   --       a  in the whole file       w  search for words
   --       m  in the marked area      ~  negative search
   default_search_options = '+fac'

   -- default_edit_options
   --    internal default: '/b /nt /u'
   --       /b    don't load file from disk if already in ring
   --       /c    create a new file
   --       /d    load it from disk, even if already in ring
   --       /t    don't convert Tab's
   --       /nt   no tab chars: convert it into spaces
   --       /u    Unix line end: LF is line end and CR is ignored
   --       /l    DOS line end: CRLF is line end, CR's and LF's are text
   --       /64   wrap every line after 64 chars, on saving there will
   --             be no line end added at the wrap points if none of the
   --             following *save* options is set: /o /u /l
   --       /bin  binary mode: all chars are editable, note the difference
   --             between '/64 /bin' and '/bin /64'
   --    How to edit binary files?
   --       'e /t /l /64 /bin mybinary.file'
   --    Further options:
   --       /k0 /k /k1 /k2 /v /r /s /n*
   default_edit_options = '/b /t /l'

   -- default_save_options
   --    internal default: '/ns /nt /ne'?
   --       /s    strip trailing spaces
   --       /ns   don't strip spaces
   --       /e    append a file end char
   --       /ne   no file end char
   --       /t    convert spaces to tab chars
   --       /nt   don't convert spaces
   --       /q    quiet
   --       /o    insert CRLF as line end char
   --       /l    insert LF as line end char
   --       /u    Unix line end: insert LF as line end char and don't append a file end char
   --    How to save binary files?
   --       's /nt /ns /ne mybinary.file'
   --       This will only work, if none of /o /l /u is specified.
   default_save_options = '/s /ne /nt'

   -- tabglyph: show a circle for the tab char
   call tabglyph(1)  -- or: 'tabglyph 1'

   -- matchtab: tab places the cursor below the start of the next word from the upper line
   'matchtab off'

   -- expand: syntax expansion
;   'expand on'  -- default

   -- escapekey: open EPM commandline with Esc and Ctrl+I
;   'escapekey on'  -- default now

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


