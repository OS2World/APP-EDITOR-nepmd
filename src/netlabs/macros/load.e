/****************************** Module Header *******************************
*
* Module Name: load.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: load.e,v 1.22 2005-11-24 19:40:04 aschn Exp $
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
;  LOAD.E                                                Bryan Lewis 1/2/89
;
;  This event is triggered immediately after a file is loaded.  It will be
;  invoked after loading an existing file from disk, or opening a new file,
;  but not after an error such as "Not enough memory".
;  In other words, a new file must be entered into the ring.
;
;  This is the place to select a keyset (like c_keys for .C files) since
;  keysets now stay bound to a file once assigned.
;  This is also a good place to do other one-time processing like returning
;  to a saved bookmark.
;
;  No argument is passed.  Check .filename if you want the name of the file.
;  Use the function filetype() for the filetype.
;  1993/01/07:  put the result of filetype() in a universal so others needn't
;               call it.
;
;  defload is triggered for every file that gets loaded, not mattering if
;  'xcom e' or 'e' is used. The only exception is the automatically created
;  empty file, if EPM was started without a filename. But that is already
;  fixed, since in MAIN.E that file is replaced by a 'xcom e /n' loaded file,
;  for that the defload event is triggered.
;  Additionally, every 'Name' command, e.g. executed by 'SaveAs', processes
;  defload again.
;
;  IMPORTANT:
;  defload should not be used by externally compiled packages, because it
;  will not be processed reliable. Use the defload hook instead! Many package
;  writers use to workaround this problem with calling the defload stuff at
;  every defselect again. This will work in most cases, but the performance
;  and stability will decrease enourmously.
;  (Much work's waiting to fix all that packages...)
;
;  Often used (huge overhead and nevertheless not working properly):
;     defload
;        <external stuff>
;     defselect  -- required if linked
;        <same external stuff>
;
;  NEPMD:
;     defc <external_cmd>
;        <external stuff>
;     definit
;        'HookAdd load <external_cmd>'
;
;  Additionally, even this it probably not really required anymore, because
;  the ModeExecute command provides a useful interface.
;
;  Many other hooks exist, e.g. for adding a submenu beside the helpmenu.

defload
   universal load_ext
   universal defload_profile_name
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE, load_var
   universal default_font
   universal loadstate

   load_var = 0
   load_ext = filetype()  -- Extension for the current file. To be used only
                          -- until the next file gets loaded. Probably not used
                          -- anymore, because replaced by GetMode().
   keys edit_keys    -- defaults for non-special filetypes

   .tabs     = vDEFAULT_TABS
   .margins  = vDEFAULT_MARGINS
   .autosave = vDEFAULT_AUTOSAVE

   if not .visible then  -- process following only if file is visible
      return             -- to avoid showing i.e. 'actlist' and '.HELPFILE' files
   endif

   loadstate = 1  -- This universal var can be used to check if there occured
                  -- a defload event after the last afterload was processed.
                  --    1: defload is running
                  --    2: defload processed
                  --    0: afterload processed
   Filename = .filename
   getfileid fid

;  Set .readonly from file attributes ---------------------------------------
   'ReadonlyFromAttrib'

;  Set .font ----------------------------------------------------------------
   if .font < 2 then    -- If being called from a NAME, and font was set, don't change it.
      .font = default_font
   endif

;  Restore tabs from EPM.TABS -----------------------------------------------
;  Restore margins from EPM.MARGINS -----------------------------------------
;  Restore bookmarks and styles from EPM.ATTRIBUTES -------------------------
compile if WANT_BOOKMARKS
   if .levelofattributesupport < 2 then  -- If not already set (e.g., NAME does a DEFLOAD)
      'loadattributes'
   endif
compile endif

;  Ebookie support: init bkm ------------------------------------------------
;     supports tag languages: BookMaster, GML, FOILS5, APAFOIL, IPF
;     see the files in epmbbs\ebookie
compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
   if bkm_avail <> '' then
 compile endif
      if bkm_defload() <> 0 then keys bkm_keys; endif
 compile if WANT_EBOOKIE = 'DYNALINK'
   endif
 compile endif
compile endif  -- WANT_EBOOKIE

;  Restore cursor position from EPM.POS -------------------------------------
   'RestorePosFromEa'

;  Set mode -----------------------------------------------------------------
   Mode = GetMode(Filename)

;  Process all mode dependent settings for defload --------------------------
   -- It's important to process them near the end of defload, otherwise EPM
   -- may crash if a huge number of files is loaded (still valid?).
   -- The load_<mode> hook is executed here.
   -- Args not required anymore since the code of HookExecute load_<mode>
   -- was copied into ProcessLoadSettings instead executing the command.
   'ProcessLoadSettings' Mode fid

;  Process hooks ------------------------------------------------------------
   -- The 'load' and 'loadonce' hook is a comfortable way to overwrite
   -- some file properties while a file is loaded. These properties were
   -- set by defload, e.g.: margins, tabs, keyset, mode.
   -- Example: 'HookAdd loadonce tabs 2'  -- no postme required anymore!
   -- Note   : Hooks are only able to process commands, not procedures.
   'HookExecute load'
   'HookExecuteOnce loadonce'

;  CICS BMS (Basic Mapping Services) assembler macros support  --------------
compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_defload_exit') then
      call BMS_defload_exit()
   endif
compile endif

;  Process REXX defload profile  --------------------------------------------
;  -- Better avoid this.
   if defload_profile_name then
      if not verify(defload_profile_name, ':\', 'M') then  -- Not fully qualified?  Search for it...
         findfile profile1, defload_profile_name, EPATH
         if rc then findfile profile1, defload_profile_name, 'PATH'; endif
         if not rc then
            defload_profile_name = profile1  -- Remember where it was found.
            'rx' defload_profile_name arg(1)
         endif
      else  -- Fully qualified
         'rx' defload_profile_name arg(1)
      endif
   endif

;  Refresh InfoLines --------------------------------------------------------
   'refreshinfoline FILE'

