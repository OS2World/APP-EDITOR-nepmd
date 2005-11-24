/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.35 2005-11-24 01:27:35 aschn Exp $
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

; ---------------------------------------------------------------------------
; Put the test stuff into an extra command.
defc TestLinkAtDefmain
   universal nepmd_hini

;  Link NEPMDLIB.EX if not already linked in DEFINIT ------------------------
compile if LINK_NEPMDLIB = 'DEFMAIN'  -- default is to link NepmdLib at DEFINIT
   if not isadefproc('NepmdOpenConfig') then
      -- Link the NEPMD library. Open a MessageBox if .ex file not found.
      'linkverify nepmdlib.ex'
   endif
compile endif

compile if LINK_NEPMDLIB <> 'DEFINIT'  -- default is to link NepmdLib at DEFINIT
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
 compile if LINK_MENU
   if CurMenu = '' then  -- CurMenu is not set if LINK_NEPMDLIB <> 'DEFINIT'
      CurMenu = 'newmenu'
   endif
   'linkverify 'CurMenu'.ex'
 compile endif
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
;  -  Every .ex file defines its own DEFINIT, DEFMAIN and DEFEXIT.
;  -  DEFEXIT is not processed for the main .ex file. For other linked
;     .ex files it is processed on unlink (may be used to switch a keyset
;     back or to remove a submenu).
;  -  DEFMAIN should be used to parse the command line arguments of the
;     current .EX file. For EPM.EX this is handled by MAIN.E.
defmain
   universal rexx_profile
   universal nepmd_hini
   universal unnamedfilename
   universal loadstate
   universal CurEditCmd
   universal firstloadedfid  -- first file for the 'xcom e /n' cmd
   universal firstinringfid  -- first file in the ring
   loadstate = 0

;  Get args and make it a parameter for the edit cmd ------------------------
   doscmdline = 'e 'arg(1) /* Can do special processing of DOS command line.*/

   dprintf( 'DEFMAIN', 'arg(1) = ['arg(1)']')

;  Usually NEPMDLIB and the menu are linked at definit ----------------------
   'TestLinkAtDefmain'

;  Process settings from EPM.INI and load menu ------------------------------
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

;  Automatically link .ex files from <UserDir>\autolink ---------------------
   call NepmdAutoLink()

;  Process 'init' hook ------------------------------------------------------
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

;  Process PROFILE.ERX ------------------------------------------------------
   -- Changed: profile.erx is now processed before any file is loaded. In
   --          order to change file settings, the 'load' or 'loadonce' hook
   --          must be used now.
   -- Note: E.g. switching highlighting on for the original EPM with
   --       'toggle_parse 1 epmkwds.<ext>' from profile.erx didn't work for
   --       every loaded file. Any file stuff didn't work properly there.
   --       Using the new load hooks, one can execute something for every
   --       loaded file -- easily and properly.
   if rexx_profile then
      ProfileName = 'profile.erx'
      -- REXX profile is not searched anymore. It must be placed in
      -- %NEPMD_USERDIR%\bin with the name PROFILE.ERX now.
      Profile = Get_Env('NEPMD_USERDIR')'\bin\'ProfileName
      if exist(Profile) then
;      -- REXX_PROFILE is now searched in .;%PATH%;%EPMPATH% instead of .;%EPMPATH%;%PATH%
;      findfile Profile, ProfileName, 'PATH'
;      if rc then findfile Profile, ProfileName, EPATH; endif
;      if not rc then
         'rx' Profile arg(1)
      endif
   endif

;  Maybe change to previous work dir ----------------------------------------
   KeyPath = '\NEPMD\User\ChangeWorkDir'
   ChangeWorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if ChangeWorkDir = 1 then
      KeyPath = '\NEPMD\User\ChangeWorkDir\Last'
      LastWorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if NepmdDirExists( LastWorkDir) = 1 then
         call directory( '\')
         call directory( LastWorkDir)
      endif
   endif

;  Execute the doscmdline (edit command) ------------------------------------
   dprintf( 'DEFMAIN', 'doscmdline = 'doscmdline)
   -- Restore last edit ring if started without args
   KeyPath = '\NEPMD\User\AutoRestore\Ring\LoadLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if (arg(1) = '' & Enabled) then
      'RestoreRing'
   else
      doscmdline
   endif

;  Quit automatically loaded empty file -------------------------------------
   -- E automatically created an empty file when it started.
   -- If user specified file(s) to edit, get rid of the empty file.
   -- This must be processed at defmain, because this file is the only one,
   -- that won't trigger a defload event.
   -- Get fileid after processing of doscmdline.
   getfileid newfid
   dprintf( 'DEFMAIN_EMPTY_FILE', 'filesinring = 'filesinring()', filename = '.filename)
   if validatefileid(unnamedfid) <> 0 then
      activatefile unnamedfid
      -- Check if other files in ring
      next_file
      getfileid otherfid
      if otherfid = unnamedfid then  -- no other file in ring
         -- For the automatically created empty file no defload event is
         -- triggered.
         -- Load a new empty file, for that the defload event will
         -- process.
         dprintf( 'DEFMAIN_EMPTY_FILE', 'load a new empty file...')
         'xcom e /n'
         getfileid newfid
         -- xcom edit doesn't call defc edit, therefore set the following
         -- universal vars to make afterload happy.
         -- Usually they are set by defc edit.
         firstloadedfid = newfid  -- first file for this edit cmd
         firstinringfid = newfid  -- first file in the ring
         dprintf( 'DEFMAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
      endif
      -- Get rid of the automatically created empty file
      dprintf( 'DEFMAIN_EMPTY_FILE', 'quit internally loaded empty file... unnamedfid = 'unnamedfid)
      activatefile unnamedfid
      'xcom q'
      dprintf( 'DEFMAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
   endif
   dprintf( 'DEFMAIN_EMPTY_FILE', 'activating newfid = 'newfid', filename = 'newfid.filename)
   activatefile newfid

;  Show menu and window -----------------------------------------------------
   call showmenu_activemenu()  -- show the EPM menu (before the window is shown)
   -- see also: STDCNF.E for menu
   call showwindow('ON')

;  Execute just-installed stuff, if any -------------------------------------
   App = 'RegDefaults'
   Key = '\NEPMD\User\JustInstalled'
   JustInstalled = QueryProfile( nepmd_hini, App, Key)
   if JustInstalled = 1 then
      -- Link JustInst.ex if present
      display -2
      link 'justinst'
      display 2
      if rc > 0 then
         -- Execute defc JustInst
         if isadefc('JustInst') then
            'postme JustInst'
         endif
      endif
      -- Reset ini key
      call SetProfile( nepmd_hini, App, Key, 0)
   endif


