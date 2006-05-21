/****************************** Module Header *******************************
*
* Module Name: main.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: main.e,v 1.43 2006-05-21 18:56:57 aschn Exp $
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
;  -  DEFINIT and DEFMAIN are processed whenever the .ex file is linked.
;     For the main .ex file this is equivalent to 'for every newly opened EPM
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
   universal unnamedfilename  -- use NLS-dependent string from EPMMRI.DLL or
                              -- ETKE603.DLL, not the one from ENGLISH.E
   universal CurEditCmd       -- used to maybe disable cursor restoring,
                              -- just init it here to ''
   universal DisplayDisabled  -- suppress screen refresh during file loading
   universal loadstate        -- init loadstate here
                  -- This universal var can be used to check if there occured
                  -- a defload event after the last afterload was processed.
                  --    empty: before a file is loaded
                  --    1: defload is running
                  --    2: defload processed
                  --    0: afterload processed

;  Get args and make it a parameter for the edit cmd ------------------------
   EpmArgs = 'e 'arg(1)

   dprintf( 'MAIN', 'arg(1) = ['arg(1)']')

;  Process settings from MODECNF.E --------------------------------------------
   'InitModeCnf'

;  Process settings from EPM.INI and load menu ------------------------------
   -- This should be processed after NepmdInitConfig, because now there are
   -- values from NEPMD.INI queried as well.
   'InitConfig'

;  Get the .Untitled filename, defined in the DLLs, NLS-dependent. ----------
   -- EPM always starts with an .Untitled file.
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
compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH)
   call check_savepath()
compile endif

;  Automatically link .ex files from <UserDir>\autolink ---------------------
   call Autolink()

;  Process 'init' hook ------------------------------------------------------
   -- The 'init' hook is a comfortable way to override or add some
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
      call defmain_exit(EpmArgs)
   endif
compile endif

;  Process PROFILE.ERX ------------------------------------------------------
   -- Changed: profile.erx is now processed before any file is loaded. In
   --          order to change file settings, the 'load' or 'loadonce' hook
   --          must be used now.
   -- Note: E.g. switching highlighting on for the original EPM with
   --       'toggle_parse 1 epmkwds.<ext>' from profile.erx didn't work for
   --       every loaded file. Any file stuff didn't work properly there.
   --       Using the new 'load' hook or the 'AtLoad' command, one can
   --       execute something for every loaded file -- easily and properly.
   if rexx_profile then
      ProfileName = 'profile.erx'
      -- REXX profile is not searched anymore. It must be placed in
      -- %NEPMD_USERDIR%\bin with the name PROFILE.ERX now.
      Profile = Get_Env('NEPMD_USERDIR')'\bin\'ProfileName
      if exist(Profile) then
         'rx' Profile arg(1)
      endif
   endif

;  Show menu and window -----------------------------------------------------
   call showmenu_activemenu()  -- show the EPM menu (before the window is shown)
                               -- showmenu_activemenu is not required anymore,
                               -- omitting it here won't change anything
   -- see also: STDCNF.E for menu
   call showwindow('ON')
   mouse_setpointer WAIT_POINTER
   --refresh     -- force to show the window, with the empty file loaded
   display -1  -- disable screen refresh, re-enabled in defselect
   DisplayDisabled = 1

   'postme main2' unnamedfid','EpmArgs

; ---------------------------------------------------------------------------
; When PROFILE.ERX is processed, it often takes a longer time. In order to
; keep the order of the further steps (e.g. afterload) right, moving the rest
; of defmain to a posted defc should delay it until PROFILE.ERX processing
; is fully completed. Fortunally the single postme doesn't cause much
; overhead here.
defc main2
   universal nepmd_hini
                             -- following universals are initialized to the
                             -- fileid of the file after execution of the
                             -- 'xcom e /n' command:
   universal firstloadedfid  -- first loaded file
   universal firstinringfid  -- first file in the ring

   parse arg unnamedfid ',' EpmArgs

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

;  Execute the EpmArgs (edit command) ---------------------------------------
   dprintf( 'MAIN', 'EpmArgs = 'EpmArgs)
   -- Restore last edit ring if started without args
   KeyPath = '\NEPMD\User\AutoRestore\Ring\LoadLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if (arg(1) = '' & Enabled) then
      'RestoreRing'
   else
      EpmArgs
   endif

;  Quit automatically loaded empty file -------------------------------------
   -- E automatically created an empty file when it started.
   -- If user specified file(s) to edit, get rid of the empty file.
   -- This must be processed at defmain, because this file is the only one,
   -- that won't trigger a defload event.
   -- Get fileid after processing of EpmArgs.
   getfileid newfid
   dprintf( 'MAIN_EMPTY_FILE', 'filesinring = 'filesinring()', filename = '.filename)
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
         dprintf( 'MAIN_EMPTY_FILE', 'load a new empty file...')
         'xcom e /n'
         getfileid newfid
         -- xcom edit doesn't call defc edit, therefore set the following
         -- universal vars to make ProcessAfterload happy.
         -- Usually they are set by defc edit.
         firstloadedfid = newfid  -- first file for this edit cmd
         firstinringfid = newfid  -- first file in the ring
         dprintf( 'MAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
      endif
      -- Get rid of the automatically created empty file
      dprintf( 'MAIN_EMPTY_FILE', 'quit internally loaded empty file... unnamedfid = 'unnamedfid)
      activatefile unnamedfid
      'xcom q'
      dprintf( 'MAIN_EMPTY_FILE', 'now filesinring = 'filesinring())
   endif
   dprintf( 'MAIN_EMPTY_FILE', 'activating newfid = 'newfid', filename = 'newfid.filename)
   activatefile newfid

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
            --'postme JustInst'
            'AtStartup JustInst'
         endif
      endif
      -- Reset ini key
      call SetProfile( nepmd_hini, App, Key, 0)
   endif

