/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.22 2004-02-28 15:32:56 aschn Exp $
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
Todo:
-  Replace NEPMD_RESTORE_LAST_RING with an ini key
*/

-------- Begin debug stuff --------
const
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_DEFMAIN)
   NEPMD_DEBUG_DEFMAIN = 0
compile endif
compile if not defined(NEPMD_DEBUG_DEFMAIN_EMPTY_FILE)
   NEPMD_DEBUG_DEFMAIN_EMPTY_FILE = 0
compile endif
compile if not defined(NEPMD_DEBUG_AFTERLOAD)
   NEPMD_DEBUG_AFTERLOAD = 0
compile endif
-- Standard defmain debugging
define
   DEBUG_MAIN = 0

; Bug: Every sayerror seems to be executed 2 times (according to the
;      MessageBox, but fortunately defmain not.
;      (can be verified with NepmdPmPrintf)
;      Workaround: use the 'refresh' statement before every 'sayerror'.
; ->   Better use NepmdPmPrintf and PmPrintf.exe for fast and save
;      processing of messages.
-------- End debug stuff --------

const
-- Restore last ring if EPM is started without args: Set this to 1.
compile if not defined(NEPMD_RESTORE_LAST_RING)
   NEPMD_RESTORE_LAST_RING = 0  -- todo: make this a ini var
compile endif

; ---------------------------------------------------------------------------
;  -  DEFINIT and DEFMAIN are processed whenever the .ex file is linked.
;     For the main .ex file this is equivalent to 'for every new opened EPM
;     window'. For other linked packages DEFMAIN is only executed, if
;     the package is called by the command/DEFMAIN trick: If a command
;     is executed, also .ex files are searched. If an .ex file with the
;     same basename as the command exists, then DEFMAIN of this package
;     will be executed.
;  -  DEFMAIN is processed after all DEFINITs are completed. That makes it
;     possible to process something in DEFMAIN being ensured that all
;     DEFINIT actions (e.g. set default values) are finished.
;  -  DEFMAIN is not processed, if EPM.EXE is started with option /r.
;     /r opens first a new EPM thread, but if an EPM window is already
;     present, all args will be passed to that window.
;  -  Only 1 DEFMAIN is allowed per .ex file.
;  -  Every .ex file defines it's own DEFINIT, DEFMAIN and DEFEXIT.
;  -  DEFEXIT is not processed for the main .ex file. For other linked
;     .ex files it is processed on unlink (e.g. to switch a keyset back or
;     to remove a submenu).
defmain    /* defmain should be used to parse the command line arguments */
compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
compile endif
   universal should_showwindow
   universal nepmd_hini
   universal app_hini
   universal unnamedfilename
   universal defmainprocessed
   universal defloadprocessed

   should_showwindow = 1  -- Lets cmdline commands inhibit the SHOWWINDOW.

; --- Get args and make it a parameter for the edit cmd ---------------------
   doscmdline = 'e 'arg(1) /* Can do special processing of DOS command line.*/

compile if DEBUG_MAIN
   messageNwait('DEFMAIN: arg(1)="'arg(1)'"')
compile endif

; -------- 1) Process standard EPM.INI settings --------
compile if WANT_APPLICATION_INI_FILE  -- we should remove this

; --- Check EPM.INI -> EPM -> DTBITMAP for a valid entry --------------------
   -- The SLE of the settings dialog truncates the bitmap filename after
   -- 32 chars. Additionally, the truncated string is at pos 32 replaced with
   -- a hex char. As a result, MAIN.E will be processed only up to the point,
   -- where the not existing bitmap should be set.
   bgbitmap = queryprofile( app_hini, 'EPM', 'DTBITMAP')
   bgbitmap = strip( bgbitmap, 'T', \0)
   -- Set to \0 if bitmap doesn't exist
   if not exist(bgbitmap) then
      call setprofile( app_hini, 'EPM', 'DTBITMAP', \0)
   endif

; --- Check if anything of interest is in OS2.INI ---------------------------
; --- and get settings from EPM.INI -----------------------------------------
   'initconfig'

 compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after INITCONFIG')
 compile endif

compile endif  -- WANT_APPLICATION_INI_FILE

; -------- 2) Process NEPMD.INI settings --------
compile if LINK_NEPMDLIB = 'DEFMAIN'
   if not isadefproc('NepmdOpenConfig') then
; --- Link the NEPMD library. Open a MessageBox if .ex file not found. ------
      'linkverify nepmdlib.ex'
   endif
compile endif

; --- Open NEPMD.INI and save the returned handle ---------------------------
; --- to the universal var 'nepmd_hini' -------------------------------------
   nepmd_hini = NepmdOpenConfig()
   parse value nepmd_hini with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be opened, rc='rc;
   endif

; --- Process NEPMD.INI initialisation --------------------------------------
   -- Write default values from nepmd\netlabs\bin\defaults.dat to NEPMD.INI,
   -- application 'RegDefaults', if 'RegDefaults' was not found
   rc = NepmdInitConfig( nepmd_hini )
   parse value rc with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be initialized, rc='rc;
   endif

; --- Get the .Untitled filename, defined in the DLLs, NLS-dependent. -------
;     For the language-specific versions of the EPM binaries (W4+) all
;     resources moved to epmmri.dll. The .Untitled name is stringtable item
;     54.
;     For the Larry Margolis version epmmri.dll doesn't exist. The .Untitled
;     name is located in etke603.dll as resource, stringtable item 54.
;     This filename is NLS-dependent and hard-coded in the E Toolkit DLLs,
;     while the filename coming from the 'edit' command queries the constant.
;     To keep both names in synch, we take the name from the DLL and replace
;     all occurences of the UNNAMED_FILE_NAME const with a query of the
;     universal var or of the proc GetUnnamedFilename().
   unnamedfilename = .filename
   getfileid unnamedfid

; --- Host support ----------------------------------------------------------
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH) or DELAY_SAVEPATH_CHECK
   call check_savepath()
compile endif

; --- Execute a user procedure if defined -----------------------------------
compile if SUPPORT_USER_EXITS
   if isadefproc('defmain_exit') then
      call defmain_exit(doscmdline)
   endif
compile endif

; --- Execute the doscmdline (edit command) ---------------------------------
compile if NEPMD_DEBUG_DEFMAIN and NEPMD_DEBUG
   call NepmdPmPrintf( 'DEFMAIN: doscmdline = 'doscmdline )
compile endif
compile if NEPMD_RESTORE_LAST_RING
   if arg(1) = '' then
      'restorering'
   else
      doscmdline
   endif
compile else
   doscmdline
compile endif
compile if DEBUG_MAIN
   messageNwait('DEFMAIN: after DOSCMDLINE')
compile endif

; --- E automatically created an empty file when it started. ----------------
;     If user specified file(s) to edit, get rid of the empty file.
   -- Get fileid after processing of doscmdline.
   getfileid newfid

   do f = 1 to filesinring()  -- exclude hidden files
compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFMAIN: file 'f' of 'filesinring()' in ring: '.filename)
compile endif
      getfileid fid
      if fid = unnamedfid then
         -- Check if other files in ring
         next_file
         getfileid otherfid
         if otherfid = unnamedfid then  -- no other file in ring
            -- For the automatically created empty file no defload event is triggered.
            -- Load a new empty file, for that the defload event will process.
compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE and NEPMD_DEBUG
            call NepmdPmPrintf( 'DEFMAIN: load a new empty file...')
compile endif
            'xcom e /n'
            getfileid newfid
compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE and NEPMD_DEBUG
            call NepmdPmPrintf( 'DEFMAIN: now filesinring = 'filesinring())
compile endif
         endif
         -- Get rid of the automatically created empty file
compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE and NEPMD_DEBUG
         call NepmdPmPrintf( 'DEFMAIN: quit internally loaded empty file...')
compile endif
         activatefile unnamedfid
         'xcom q'
compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE and NEPMD_DEBUG
         call NepmdPmPrintf( 'DEFMAIN: now filesinring = 'filesinring())
compile endif
         leave
      endif
      next_file
   enddo

   activatefile newfid

; --- Automatically link .ex files from myepm\autolink ----------------------
   call NepmdAutoLink()

; --- Process Hook ----------------------------------------------------------
   if isadefc('HookExecute') then
      -- The 'main' hook is a comfortable way to overwrite or add some
      -- general settings, set by definit or defmain. It enables
      -- configurations by other linked .ex files without the use of
      -- PROFILE.ERX.
      -- Example: 'HookAdd main default_save_options /ns /ne /nt'
      -- Example: 'HookAdd main default_search_options +faet'
      -- Note   : Hooks are only able to process commands, not procedures.
      'HookExecute main'
      'HookExecuteOnce mainonce'
   endif

; --- Process PROFILE.ERX ---------------------------------------------------
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

; --- Call AfterLoad ---------------------------------------------------
   -- Sometimes DEFLOAD is triggered before all DEFMAIN stuff is processed.
   defmainprocessed = 1
   if defloadprocessed = 1 then -- if all DEFLOADs are already processed
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFMAIN: Calling AfterLoad...')
compile endif
      'postme AfterLoad'
   else
compile if NEPMD_DEBUG_AFTERLOAD and NEPMD_DEBUG
      call NepmdPmPrintf( 'DEFMAIN: AfterLoad not called, because defloadprocessed <> 1.')
compile endif
   endif

; --- Show menu and window --------------------------------------------------
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

