/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.24 2004-06-03 22:32:35 aschn Exp $
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

defproc debugmain
compile if NEPMD_DEBUG then
   type = upcase(arg(1))
 compile if NEPMD_DEBUG_DEFMAIN then
   if type = 'DEFMAIN' then
      call NepmdPmPrintf( type': 'arg(2))
   endif
 compile endif
 compile if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE then
   if type = 'DEFMAIN_EMPTY_FILE' then
      call NepmdPmPrintf( type': 'arg(2))
   endif
 compile endif
 compile if NEPMD_DEBUG_AFTERLOAD then
   if type = 'AFTERLOAD' then
      call NepmdPmPrintf( type': 'arg(2))
   endif
 compile endif
compile endif  -- NEPMD_DEBUG
   return

; Bug: Every sayerror seems to be executed 2 times (according to the
;      MessageBox), but fortunately defmain is not (can be verified with
;      NepmdPmPrintf).
;      Workaround: use the 'refresh' statement before every 'sayerror'.
; ->   Better use NepmdPmPrintf and PmPrintf.exe for fast and save
;      processing of messages.
-------- End debug stuff --------

const
; Added for testing:
compile if not defined(NEPMD_WANT_AFTERLOAD)
   NEPMD_WANT_AFTERLOAD = 1
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
;     .ex files it is processed on unlink (may be used to switch a keyset
;     back or to remove a submenu).
;  -  DEFMAIN should be used to parse the command line arguments of the
;     current .EX file. For EPM.EX this is handled by MAIN.E.
defmain
   universal rexx_profile
   universal should_showwindow
   universal nepmd_hini
   universal app_hini
   universal unnamedfilename
   universal defmainprocessed
   universal defloadprocessed
   universal firstloadedfid  -- first file for the 'xcom e /n' cmd
   universal firstinringfid  -- first file in the ring



;  Get args and make it a parameter for the edit cmd ------------------------
   doscmdline = 'e 'arg(1) /* Can do special processing of DOS command line.*/

   debugmain('DEFMAIN' 'arg(1) = "'arg(1)'"')

;  Link NEPMDLIB.EX if not already linked in DEFINIT ------------------------
compile if LINK_NEPMDLIB = 'DEFMAIN'  -- default is to link NepmdLib at DEFINIT
   if not isadefproc('NepmdOpenConfig') then
      -- Link the NEPMD library. Open a MessageBox if .ex file not found.
      'linkverify nepmdlib.ex'
   endif
compile endif

compile if LINK_NEPMDLIB <> 'DEFINIT'  -- default is to link NepmdLib at DEFINIT
   if isadefproc('NepmdQueryConfigValue') then
      KeyPath = '\NEPMD\User\Menu\Name'
      CurMenu = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
;  Open NEPMD.INI and save the returned handle ------------------------------
   nepmd_hini = NepmdOpenConfig()
   parse value nepmd_hini with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be opened, rc='rc;
   endif

;  Process NEPMD.INI initialization -----------------------------------------
   -- Write default values from nepmd\netlabs\bin\defaults.dat to NEPMD.INI,
   -- application 'RegDefaults', if 'RegDefaults' was not found
   rc = NepmdInitConfig(nepmd_hini)
   parse value rc with 'ERROR:'rc;
   if (rc > 0) then
      sayerror 'Configuration repository could not be initialized, rc='rc;
   endif

;  Link the menu ------------------------------------------------------------
   if isadefproc('NepmdQueryConfigValue') then
      KeyPath = '\NEPMD\User\Menu\Name'
      CurMenu = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
compile endif

;  Process settings from EPM.INI --------------------------------------------
   -- This should be processed after NepmdInitConfig, because now there are
   -- values from NEPMD.INI queried as well.
   'initconfig'

;  Get the .Untitled filename, defined in the DLLs, NLS-dependent. ----------
   -- For the language-specific versions of the EPM binaries (W4+) all
   -- resources moved to epmmri.dll. The .Untitled name is stringtable item
   -- 54.
   -- For the Larry Margolis version epmmri.dll doesn't exist. The .Untitled
   -- name is located in etke603.dll as resource, stringtable item 54.
   -- This filename is NLS-dependent and hard-coded in the E Toolkit DLLs,
   -- while the filename coming from the 'edit' command queries the constant.
   -- To keep both names in synch, we take the name from the DLL and replace
   -- all occurences of the UNNAMED_FILE_NAME const with a query of the
   -- universal var or of the proc GetUnnamedFilename().
   unnamedfilename = .filename
   getfileid unnamedfid

;  Host support -------------------------------------------------------------
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH) or DELAY_SAVEPATH_CHECK
   call check_savepath()
compile endif

;  Process 'init' Hook ------------------------------------------------------
   -- The 'init' hook is a comfortable way to overwrite or add some
   -- general settings as an extension to NepmdInitConfig or initconfig.
   -- It can be used for configurations by other linked .ex files without
   -- the use of PROFILE.ERX.
   -- Example: 'HookAdd init default_save_options /ns /ne /nt'
   -- Example: 'HookAdd init default_search_options +faet'
   -- Note   : Hooks are only able to process commands, not procedures.
   'HookExecute init'

;  Execute a user procedure if defined --------------------------------------
compile if SUPPORT_USER_EXITS
   if isadefproc('defmain_exit') then
      call defmain_exit(doscmdline)
   endif
compile endif

;  Execute the doscmdline (edit command) ------------------------------------
   debugmain( 'DEFMAIN', 'doscmdline = 'doscmdline)
   -- Restore last edit ring if started without args
   KeyPath = '\NEPMD\User\AutoRestore\Ring\LoadLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if (arg(1) = '' & Enabled) then
      'restorering'
   else
      doscmdline
   endif

;  Quit automatically loaded empty file -------------------------------------
   -- E automatically created an empty file when it started.
   -- If user specified file(s) to edit, get rid of the empty file.
   -- Get fileid after processing of doscmdline.
   getfileid newfid
   do f = 1 to filesinring()  -- exclude hidden files
      debugmain( 'DEFMAIN_EMPTY_FILE', 'file 'f' of 'filesinring()' in ring: '.filename)
      getfileid fid
      if fid = unnamedfid then
         -- Check if other files in ring
         next_file
         getfileid otherfid
         if otherfid = unnamedfid then  -- no other file in ring
            -- For the automatically created empty file no defload event is
            -- triggered.
            -- Load a new empty file, for that the defload event will
            -- process.
            debugmain( 'DEFMAIN_EMPTY_FILE', 'load a new empty file...')
            'xcom e /n'
            getfileid newfid
            -- Set the universal vars to make afterload happy.
            -- At this point they are initialized to unnamedfid.
            firstloadedfid = newfid
            firstinringfid = newfid  -- first file in the ring
            debugmain( 'DEFMAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
         endif
         -- Get rid of the automatically created empty file
         debugmain( 'DEFMAIN_EMPTY_FILE', 'quit internally loaded empty file... unnamedfid = 'unnamedfid)
         activatefile unnamedfid
         'xcom q'
         debugmain( 'DEFMAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
         leave
      endif
      next_file
   enddo
   debugmain( 'DEFMAIN_EMPTY_FILE', 'activating newfid = 'newfid', filename = 'newfid.filename)
   activatefile newfid

;  Automatically link .ex files from myepm\autolink -------------------------
   call NepmdAutoLink()

;  Process 'main' Hook ------------------------------------------------------
   -- The 'main' hook is a comfortable way to overwrite or add some
   -- general settings, set by definit or defmain. It enables
   -- configurations by other linked .ex files without the use of
   -- PROFILE.ERX.
   -- Example: 'HookAdd main default_save_options /ns /ne /nt'
   -- Example: 'HookAdd main default_search_options +faet'
   -- Note   : Hooks are only able to process commands, not procedures.
   'HookExecute main'

;  Process PROFILE.ERX ------------------------------------------------------
   if rexx_profile then
      profile = 'profile.erx'
      -- REXX profile is not searched anymore. It must be placed in
      -- NEPMD\myepm\bin with the name PROFILE.ERX now.
      profile1 = Get_Env('NEPMD_ROOTDIR')'\myepm\bin\'profile
      if exist(profile1) then
;      -- REXX_PROFILE is now searched in .;%PATH%;%EPMPATH% instead of .;%EPMPATH%;%PATH%
;      findfile profile1, profile, 'PATH'
;      if rc then findfile profile1, profile, EPATH; endif
;      if not rc then
         'rx' profile1 arg(1)
      endif
   endif

;  Show menu and window -----------------------------------------------------
   call showmenu_activemenu()  -- show the EPM menu (before the window is shown)
   -- see also: STDCNF.E for menu
   call showwindow('ON')

;  Call AfterLoad -----------------------------------------------------------
   -- Sometimes DEFLOAD is triggered before all DEFMAIN stuff is processed.
   defmainprocessed = 1
compile if NEPMD_WANT_AFTERLOAD
   if defloadprocessed = 1 then -- if all DEFLOADs from first edit command already processed
      debugmain( 'AFTERLOAD', 'Calling AfterLoad from DEFMAIN...')
      'postme AfterLoad'
   else
      debugmain( 'AFTERLOAD', 'AfterLoad not called from DEFMAIN, because defloadprocessed <> 1.')
   endif
compile endif


