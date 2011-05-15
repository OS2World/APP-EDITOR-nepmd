/****************************** Module Header *******************************
*
* Module Name: load.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
   NEPMD_RESTORE_POS_FROM_EA = 0
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

   load_var = 0
   load_ext = filetype()
   keys edit_keys    -- defaults for non-special filetypes

   .tabs     = vDEFAULT_TABS
   .margins  = vDEFAULT_MARGINS
   .autosave = vDEFAULT_AUTOSAVE

   Filename = .filename
   call NepmdInitMode( Filename )

   if not .visible then  -- process following only if file is visible
      return             -- to avoid showing i.e. 'actlist' and '.HELPFILE' files
   endif

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
      save_pos = get_EAT_ASCII_value('EPM.POS')
      if save_pos <> '' then
         call prestore_pos( save_pos )
      endif
compile endif


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

-- sayerror 'DEFLOAD occurred for file '.filename'.'  -- for testing

