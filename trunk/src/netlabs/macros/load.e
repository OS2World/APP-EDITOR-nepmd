/****************************** Module Header *******************************
*
* Module Name: load.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: load.e,v 1.14 2004-01-17 22:22:52 aschn Exp $
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
const
compile if not defined(NEPMD_RESTORE_POS_FROM_EA)
   NEPMD_RESTORE_POS_FROM_EA = 1
compile endif

defload
   universal load_ext
   universal defload_profile_name
compile if WANT_EBOOKIE = 'DYNALINK'
   universal bkm_avail
compile endif
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE, load_var
   universal default_font
compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
compile endif
   universal CurEditCmd
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
   universal filestoload

   load_var = 0
   load_ext = filetype()
   keys edit_keys    -- defaults for non-special filetypes

   .tabs     = vDEFAULT_TABS
   .margins  = vDEFAULT_MARGINS
   .autosave = vDEFAULT_AUTOSAVE

   if not .visible then  -- process following only if file is visible
      return             -- to avoid showing i.e. 'actlist' and '.HELPFILE' files
   endif

   Filename = .filename

; --- Set .titletext with name = .LONGNAME ----------------------------------
compile if WANT_LONGNAMES
 compile if WANT_LONGNAMES='SWITCH'
      if SHOW_LONGNAMES then
 compile endif
         longname = get_EAT_ASCII_value('.LONGNAME')
         if longname<>'' then
            filepath = leftstr( Filename, lastpos( '\', Filename))
            .titletext = filepath || longname
         endif
 compile if WANT_LONGNAMES='SWITCH'
      endif
 compile endif
compile endif

; --- Set .font -------------------------------------------------------------
      if .font < 2 then    -- If being called from a NAME, and font was set, don't change it.
         .font = default_font
      endif

; --- Restore tabs from EPM.TABS --------------------------------------------
; --- Restore margins from EPM.MARGINS --------------------------------------
; --- Restore bookmarks and styles from EPM.ATTRIBUTES ----------------------
compile if WANT_BOOKMARKS
      if .levelofattributesupport < 2 then  -- If not already set (e.g., NAME does a DEFLOAD)
         'loadattributes'
      endif
compile endif

; --- Ebookie support: init bkm ---------------------------------------------
;     supports tag languages: BookMaster, GML, FOILS5, APAFOIL, IPF
;     see the files in epmbbs\ebookie
compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
      if bkm_avail <> '' then
 compile endif
         if bkm_defload()<>0 then keys bkm_keys; endif
 compile if WANT_EBOOKIE = 'DYNALINK'
      endif
 compile endif
compile endif  -- WANT_EBOOKIE

; --- Restore cursor position from EPM.POS ----------------------------------
compile if NEPMD_RESTORE_POS_FROM_EA
      RestorePosFlag = 1
      -- Only restore pos if doscmdline/CurEditCmd doesn't position the cursor itself.
      -- CurEditCmd is set by defc e,ed,edit,epm in EDIT.E or defc recomp in RECOMP.E.
      -- 1) PMSEEK uses the <filename> 'L <string_to_search>' syntax.
      -- 2) defc Recompile in src\gui\recompile\recomp.e
      --    If CurEditCmd was set to 'SETPOS', then the pos will not be
      --    restored from EA 'EPM.POS' at defload (LOAD.E).
      --    Usually CurEditCmd is set to doscmdline (MAIN.E), but file
      --    loading with DDE doesn't use the 'edit' cmd.
      -- 3) ACDATASEEKER uses the <filename> '<line_no>' syntax.

                                 -- no pos restore for these cmds
      NoRestorePosWords        = 'L LOCATE / C CHANGE GOTO SETPOS RESTOREPOS TOP BOTTOM'
                                 -- no pos restore if a cmd word starts with these strings
                                 -- (that handles the '/<search_string>' cmd correctly)
      NoRestorePosStartStrings = '/'
      -- Todo:
      -- 1) This doesn't handle mc cmds yet.
      -- 2) Disable the check of CurEditCmd if the filespec contains wildcards.
      --    Otherwise EPM will crash while loading many files (about 130).

      -- check number (positions cursor on line)
      if isnum( CurEditCmd) then
         RestorePosFlag = 0
      endif
      -- check NoRestorePosWords
      if RestorePosFlag = 1 then
         do w = 1 to words( NoRestorePosWords)
            CurWord = word( NoRestorePosWords, w)
            if wordpos( translate(CurWord), translate(CurEditCmd)) > 0 then
               RestorePosFlag = 0
               leave
            endif
         enddo
      endif
      -- check NoRestorePosStartStrings if RestorePosFlag = 1
      if RestorePosFlag = 1 then
         do w = 1 to words( NoRestorePosStartStrings)
            CurWord = word( NoRestorePosStartStrings, w)
            if abbrev( translate(CurEditCmd), translate(CurWord)) > 0 then
               RestorePosFlag = 0
               leave
            endif
         enddo
      endif
      -- restore pos if RestorePosFlag = 1
      if RestorePosFlag = 1 then
         save_pos = get_EAT_ASCII_value('EPM.POS')
         if save_pos <> '' then
            -- the size of the EFrame may have changed since last pos save,
            -- so respect .windowwith/.windowheight as max values for .cursorx/.cursory
            parse value save_pos with col line cursorx cursory .
            save_pos = col min( line, .last) min( cursorx, .windowwidth) min( cursory, .windowheight)
            call prestore_pos( save_pos )
         endif
      endif
compile endif  -- NEPMD_RESTORE_POS_FROM_EA

; --- Set mode --------------------------------------------------------------
   Filemode = NepmdGetMode( Filename )
   CheckFlag = NepmdGetHiliteCheckFlag( Filemode )

; --- Process all mode dependent settings -----------------------------------
;     it's important to process them near the end of defload,
;     otherwise EPM may crash if a huge number of files is loaded
   if Filemode <> '' then
      call NepmdProcessMode( Filemode, CheckFlag)
   endif  -- if Filemode <> ''

; --- Change EPM pointer from standard arrow to text pointer ----------------
;     bug fix (hopefully): even standard EPM doesn't show everytime the
;                          correct pointer after a new edit window was opened
;     defined in defc initconfig, STDCTRL.E
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif

; --- Process hook ----------------------------------------------------------
   if isadefc('HookExecute') then
      -- The 'load' hook is a comfortable way to overwrite some file
      -- properties while a file is loaded. These properties were set by
      -- defload, e.g.: margins, tabs, keyset, mode.
      -- Example: 'HookAdd load tabs 2'  -- no postme required anymore!
      -- Note   : Hooks are only able to process commands, not procedures.
      'HookExecute load'
   endif

; --- CICS BMS (Basic Mapping Services) assembler macros support  -----------
compile if INCLUDE_BMS_SUPPORT
     if isadefproc('BMS_defload_exit') then
        call BMS_defload_exit()
     endif
compile endif

; --- Process REXX defload profile  -----------------------------------------
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

; --- Refresh InfoLines -----------------------------------------------------
   'refreshinfoline FILE'

; --- Call NepmdAfterLoad ---------------------------------------------------
   if filestoload = '' then
      -- This happens, if a new empty file is loaded with 'xcom e'. Then no
      -- 'edit' cmd is called.
      filestoload = 0
   endif
   filestoload = filestoload - 1
   if filestoload < 1 then
      call NepmdAfterLoad()
   endif

;  EPM defload bug:
;  Important: don't call anything by the use of a 2nd defload. Otherwise
;  the 1st loaded file of a wildcard filemask will not get hilited in many
;  cases. Instead of the use of additional defloads introduce new procs
;  and add them here (or use the new hook commands).


; ---------------------------------------------------------------------------
; This proc is introduced to get called once after all files were loaded.
defproc NepmdAfterLoad
   universal CurEditCmd
   universal firstloadedfid
   universal filestoloadmax  -- set in NepmdLoadFile, only used for 'xcom e'.

;compile if NEPMD_DEFLOAD_DEBUG
   call NepmdPmPrintf( 'AFTERLOAD: '.filename', CurEditCmd = 'CurEditCmd', filestoloadmax = 'filestoloadmax)
;compile endif

; --- Write number for all files in the ring to an array var ----------------
   -- see FILELIST.E
   call RingWriteFileNumber()

; --- Write position and name of all files in the ring to NEPMD.INI ---------
   if CurEditCmd <> 'SETPOS' then  -- don't process if files loaded by Recompile
   -- see FILELIST.E
;      call RingWriteFilePosition()  -- Bug: in a ring of 80 files startfid will not be selected afterwards
   endif

; --- Activate first loaded file of the current edit command ----------------
   if (.filename = GetUnnamedFileName() & filestoloadmax = '') then
      -- nop
      -- This happens, if a new empty file is loaded with 'xcom e'. Than no
      -- 'edit' cmd is called.
      call NepmdPmPrintf( "AFTERLOAD: current file is .Unnamed, filestoloadmax = ''")
   else
      -- Activate first loaded file from the current edit cmd.
      -- This works only here properly and only when action is posted.
      -- Disabled activatefile in edit.
      if firstloadedfid <> '' then
      call NepmdPmPrintf( 'AFTERLOAD: activating firstloadedfileid = 'firstloadedfid.filename)
         --activatefile firstloadedfid
         --'activatefile' firstloadedfid
         'postme activatefile' firstloadedfid
         --'HookAdd afterload postme activatefile' firstloadedfid
      endif
   endif

; --- Process hook ----------------------------------------------------------
   if isadefc('HookExecute') then
      'HookExecute afterload'  -- no need for 'postme' here?
   endif

; --- Reset universal vars, set by edit and NepmdLoadFile -------------------
   filestoloadmax = ''
   firstloadedfid = ''
   return


; Todo: move
defc activatefile
   if arg(1) <> '' then
      fid = arg(1)
      activatefile fid  -- fid must be a var or a fid
   endif

