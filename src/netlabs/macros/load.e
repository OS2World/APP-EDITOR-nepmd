/****************************** Module Header *******************************
*
* Module Name: load.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: load.e,v 1.4 2002-09-11 00:04:10 aschn Exp $
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
compile if not defined(NEPMD_MODE)
   NEPMD_MODE = 0
compile endif
compile if not NEPMD_MODE
 compile if not defined(ADA_KEYWORD_HIGHLIGHTING)
   ADA_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(C_KEYWORD_HIGHLIGHTING)
   C_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(E_KEYWORD_HIGHLIGHTING)
   E_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(FORTRAN_KEYWORD_HIGHLIGHTING)
   FORTRAN_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(HTML_KEYWORD_HIGHLIGHTING)
   HTML_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(IPF_KEYWORD_HIGHLIGHTING)
   IPF_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(JAVA_KEYWORD_HIGHLIGHTING)
   JAVA_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(PERL_KEYWORD_HIGHLIGHTING)
   PERL_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(REXX_KEYWORD_HIGHLIGHTING)
   REXX_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(RC_KEYWORD_HIGHLIGHTING)
   RC_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(SCRIPT_KEYWORD_HIGHLIGHTING)
   SCRIPT_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(TEX_KEYWORD_HIGHLIGHTING)
   TEX_KEYWORD_HIGHLIGHTING = 0
 compile endif
 compile if not defined(MAKE_KEYWORD_HIGHLIGHTING)
   MAKE_KEYWORD_HIGHLIGHTING = 0
 compile endif
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

   .tabs     = vDEFAULT_TABS
   .margins  = vDEFAULT_MARGINS
   .autosave = vDEFAULT_AUTOSAVE
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
   load_ext = filetype()
   keys edit_keys    -- defaults for non-special filetypes
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

compile if NEPMD_MODE
   -- Call mode command with special arg
   'mode DEFLOAD'

compile else
   -- Original keyword highlighting defs
 compile if    ADA_KEYWORD_HIGHLIGHTING
   if wordpos(load_ext, 'ADA ADB ADS') & .visible then
      'toggle_parse 1 epmkwds.Ada'
   endif
 compile endif
 compile if    C_KEYWORD_HIGHLIGHTING AND not (C_SYNTAX_ASSIST AND ALTERNATE_KEYSETS)
   if wordpos(load_ext, 'C H SQC CPP HPP CXX HXX SQX') & .visible then
      'toggle_parse 1 epmkwds.c'
   endif
 compile endif
 compile if    E_KEYWORD_HIGHLIGHTING AND not (E_SYNTAX_ASSIST AND ALTERNATE_KEYSETS)
   if load_ext='E' & .visible then
      'toggle_parse 1 epmkwds.e'
   endif
 compile endif
 compile if    FORTRAN_KEYWORD_HIGHLIGHTING
   if wordpos(load_ext, 'FOR FORTRAN F90') & .visible then
      'toggle_parse 1 epmkwds.F90'
   endif
 compile endif
 compile if    HTML_KEYWORD_HIGHLIGHTING
   if wordpos(load_ext, 'HTM HTML') & .visible then
      'toggle_parse 1 epmkwds.HTM'
   endif
 compile endif
 compile if    IPF_KEYWORD_HIGHLIGHTING
   if load_ext = 'IPF' & .visible then
      'toggle_parse 1 epmkwds.IPF'
   endif
 compile endif
 compile if    JAVA_KEYWORD_HIGHLIGHTING AND not (C_SYNTAX_ASSIST AND ALTERNATE_KEYSETS)
   if wordpos(load_ext, 'JAV JAVA') & .visible then
      'toggle_parse 1 epmkwds.jav'
   endif
 compile endif
 compile if    PERL_KEYWORD_HIGHLIGHTING
   if wordpos(load_ext, 'PL PRL PERL') & .visible then
      'toggle_parse 1 epmkwds.PL'
   elseif load_ext = 'CMD' & .visible then
      if .last then
         line = upcase(textline(1))
      else
         line = ''
      endif
      if word(line,1)='EXTPROC' & pos('PERL', line) then
         'toggle_parse 1 epmkwds.PL'
      endif
   endif
 compile endif
 compile if    REXX_KEYWORD_HIGHLIGHTING AND not (REXX_SYNTAX_ASSIST AND ALTERNATE_KEYSETS)
   if wordpos(load_ext, 'BAT CMD ERX EXC EXEC XEDIT REX REXX VRX') & .visible then
      if load_ext = 'CMD' & .last then
         line = upcase(textline(1))
      else
         line = ''
      endif
      if word(line,1)<>'EXTPROC' then
         'toggle_parse 1 epmkwds.cmd'
      endif
   endif
 compile endif
 compile if    RC_KEYWORD_HIGHLIGHTING
   if load_ext='RC' & .visible then
      'toggle_parse 1 epmkwds.rc'
   endif
 compile endif
 compile if    SCRIPT_KEYWORD_HIGHLIGHTING
  compile if defined(my_SCRIPT_FILE_TYPE)
   if wordpos(load_ext, 'SCR SCT SCRIPT IPF' my_SCRIPT_FILE_TYPE)>0 & .visible then
  compile else
   if wordpos(load_ext, 'SCR SCT SCRIPT IPF')>0 & .visible then
  compile endif
      'toggle_parse 1 epmkwds.scr'
   endif
 compile endif
 compile if    TEX_KEYWORD_HIGHLIGHTING
  compile if defined(TEX_FILETYPES)
   if wordpos(load_ext, TEX_FILETYPES)>0 & .visible then
  compile else
   if wordpos(load_ext, 'TEX LATEX') & .visible then
  compile endif
      'toggle_parse 1 epmkwds.TEX'
   endif
 compile endif
 compile if    MAKE_KEYWORD_HIGHLIGHTING
   if (upcase(rightstr(.filename,8))='MAKEFILE' | load_ext='MAK') & .visible then
      'toggle_parse 1 epmkwds.mak'
   endif
 compile endif
 compile if INCLUDE_BMS_SUPPORT
   if isadefproc('BMS_defload_exit') then
      call BMS_defload_exit()
   endif
 compile endif

compile endif  -- NEPMD_MODE

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
