/****************************** Module Header *******************************
*
* Module Name: load.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: load.e,v 1.13 2003-08-31 23:22:31 aschn Exp $
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
;  This is also a good place to do other one-time processing like returning to
;  a saved bookmark.
;
;  No argument is passed.  Check .filename if you want the name of the file.
;  Use the function filetype() for the filetype.
;  1993/01/07:  put the result of filetype() in a universal so others needn't call it.
const
compile if not defined(NEPMD_RESTORE_POS_FROM_EA)
   NEPMD_RESTORE_POS_FROM_EA = 1
compile endif
compile if not defined(NO_RESTORE_POS_WORDS)
   NO_RESTORE_POS_WORDS = 'L LOCATE / C CHANGE GOTO SETPOS RESTOREPOS'  -- no pos restore for these cmds
compile endif
compile if not defined(NO_RESTORE_POS_START_STRINGS)
   NO_RESTORE_POS_START_STRINGS = '/'                                   -- no pos restore if a cmd word starts with these strings
                                                                        -- (that handles the '/<search_string>' cmd correctly)
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

   Filemode = NepmdGetMode( Filename )
   CheckFlag = NepmdGetHiliteCheckFlag( Filemode )

   -- Process all mode dependent settings
   if Filemode <> '' then
      call NepmdProcessMode( Filemode, CheckFlag)
   endif  -- if Filemode <> ''

compile if WANT_LONGNAMES
 compile if WANT_LONGNAMES='SWITCH'
      if SHOW_LONGNAMES then
 compile endif
         longname = get_EAT_ASCII_value('.LONGNAME')
         if longname<>'' then
            filepath = leftstr(.filename, lastpos('\',.filename))
            .titletext = filepath || longname
         endif
 compile if WANT_LONGNAMES='SWITCH'
      endif
 compile endif
compile endif

      if .font < 2 then    -- If being called from a NAME, and font was set, don't change it.
         .font = default_font
      endif
compile if WANT_BOOKMARKS
      if .levelofattributesupport < 2 then  -- If not already set (e.g., NAME does a DEFLOAD)
         'loadattributes'
      endif
compile endif
compile if WANT_EBOOKIE
 compile if WANT_EBOOKIE = 'DYNALINK'
      if bkm_avail <> '' then
 compile endif
         if bkm_defload()<>0 then keys bkm_keys; endif
 compile if WANT_EBOOKIE = 'DYNALINK'
      endif
 compile endif
compile endif  -- WANT_EBOOKIE

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
      -- This doesn't handle mc cmds yet.

      -- check number (positions cursor on line)
      if isnum( CurEditCmd ) then
         RestorePosFlag = 0
      endif
      -- check NoRestorePosWords
      if RestorePosFlag = 1 then
         do w = 1 to words( NO_RESTORE_POS_WORDS)
            CurWord = word( NO_RESTORE_POS_WORDS, w)
            if wordpos( translate(CurWord), translate(CurEditCmd)) > 0 then
               RestorePosFlag = 0
               leave
            endif
         enddo
      endif
      -- check NoRestorePosStartStrings if RestorePosFlag = 1
      if RestorePosFlag = 1 then
         do w = 1 to words( NO_RESTORE_POS_START_STRINGS)
            CurWord = word( NO_RESTORE_POS_START_STRINGS, w)
            if abbrev( translate(CurEditCmd), translate(CurWord) ) > 0 then
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

   -- set EPM pointer from standard arrow to text pointer
   -- bug fix (hopefully): even standard EPM doesn't show everytime the correct
   --                      pointer after a new edit window was opened
   -- defined in defc initconfig, STDCTRL.E
compile if EPM_POINTER = 'SWITCH'
   mouse_setpointer vEPM_POINTER
compile else
   mouse_setpointer EPM_POINTER
compile endif


; --- Process Hook ----------------------------------------------------------
if isadefproc('HookExecute') then
   call HookExecute('LOAD')
endif

compile if INCLUDE_BMS_SUPPORT
     if isadefproc('BMS_defload_exit') then
        call BMS_defload_exit()
     endif
compile endif

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

