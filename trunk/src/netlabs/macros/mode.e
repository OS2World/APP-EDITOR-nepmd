/****************************** Module Header *******************************
*
* Module Name: mode.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mode.e,v 1.11 2002-10-07 21:00:17 cla Exp $
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

; Todo:
; - Get ModeList from all found EPMKWDS.* files.
; - Use settings from Ini.

const
compile if not defined(NEPMD_RESTORE_MODE_FROM_EA)
   NEPMD_RESTORE_MODE_FROM_EA = 0
compile endif
compile if not defined(NEPMD_SPECIAL_STATUSLINE)
   NEPMD_SPECIAL_STATUSLINE = 1
compile endif


; ---------------------------------------------------------------------------
; Returns the current mode.
defproc NepmdGetMode()
   universal EPM_utility_array_ID
   parse arg filename
   if filename = '' then
      filename = .filename
   endif
   getfileid save_fid
   -- Get CurMode for filename
   -- (The array var 'mode.'fid is set by previous calls to this routine, see below)
   getfileid fid, filename
   do_array 3, EPM_utility_array_ID, 'mode.'fid, CurMode
   -- CurMode should be set at this point. If not, get mode from EA or default mode:
compile if NEPMD_RESTORE_MODE_FROM_EA
   if CurMode = '' then
      -- Get CurMode from EA EPM.MODE:
      activatefile fid
      CurMode = get_EAT_ASCII_value('EPM.MODE')
   endif
compile endif
   if CurMode = '' then
      -- Get default mode:
      CurMode = NepmdGetDefaultMode(filename)
   endif
   activatefile save_fid

;   do_array 2, EPM_utility_array_ID, 'mode.'fid, CurMode

   return CurMode


; ---------------------------------------------------------------------------
; This command uses the NEPMDLIB EA functions to change the EA 'EPM.MODE'
; immediately if NEPMD_RESTORE_MODE_FROM_EA = 1.
;
; With the E functions only the EA area is changed. The EA's would only be saved
; when the file is saved.
;
; Both are used here: The NEPMDLIB functions to keep the EA after quitting and the
; E functions to get the current EA value quickly from .eaarea.
;
; Additionally, the current mode (from 'EPM.MODE' or the default mode) is saved in
; the array var 'mode.'fid. This is called by commands that have mode dependent
; setting: hili, refreshstatusline
;
; arg1 = (NewMode|0|OFF|RESET|-RESET-|DEFLOAD)
;         NewMode can be any mode.
; If no arg specified, then a listbox is opened for selecting a mode.
;
; Todo:
;    o  Replace 'mode DEFLOAD' call with a proc call
;    o  Let 'mode' call this proc.
;    o  Suggestion:
;       LOAD.E:
;          defload                   to get, save and process the mode on every file loading
;                                       calls NepmdInitMode
;                                       calls NepmdProcessMode
;       MODE.E:
;          defproc NepmdInitMode     to get the mode on defload without querying the array var
;                                       calls NepmdSaveMode
;          defproc NepmdSaveMode     to save the mode in an array var 'mode.'fid
;          defproc NepmdWriteModeEa  to save the mode in the EA 'EPM.MODE'
;          defproc NepmdGetMode      to query the mode from EA or array var (done)
;          defc mode                 to change the mode and save it in the EA
;                                       calls NepmdGetMode
;                                       calls NepmdSaveMode
;                                       calls NepmdWriteModeEa
;                                       calls NepmdProcessMode
;          defproc NepmdProcessMode  to process all mode-dependent actions
;
defproc NepmdInitMode
   -- This proc is called by defload in LOAD.E
   --   temporary:
   'mode DEFLOAD'
   CurMode = NepmdGetMode()
   return CurMode

defc mode
   universal EPM_utility_array_ID
   UpdateEA = 1
   parse arg NewMode
   NewMode = upcase(NewMode)
   NewMode = strip(NewMode)

   if NewMode = '' then
      -- Ask user to set a mode
      NewMode = NepmdSelectMode()
      NewMode = upcase(NewMode)

   elseif NewMode = 'DEFLOAD' then
      -- This is called by defload
      NewMode = ''
compile if NEPMD_RESTORE_MODE_FROM_EA
      -- Get the mode from EA 'EPM.MODE'
      NewMode = get_EAT_ASCII_value('EPM.MODE')
compile endif
      if NewMode = '' then
         -- Get the default mode
         NewMode = NepmdGetDefaultMode(.filename)
      endif
      -- The EPM EA area was already set on load, so EA doesn't need to be rewritten
      UpdateEA = 0
   endif

   if wordpos( NewMode, '-RESET- RESET 0 OFF' ) > 0 then
compile if NEPMD_RESTORE_MODE_FROM_EA
      -- Delete the EA 'EPM.MODE' immediately
      rc = NepmdDeleteStringEa( .filename, 'EPM.MODE' )
      if (rc > 0) then
         sayerror 'EA "EPM.MODE" not deleted, rc='rc
      endif
      -- Update the EPM EA area to have get_EAT_ASCII_value show the actual value
      call delete_ea('EPM.MODE')
compile endif
      -- Get the default mode
      NewMode = NepmdGetDefaultMode(.filename)
      -- After resetting the EA it shouldn't be rewritten
      UpdateEA = 0
   endif
   if NewMode <> '' then
      CurMode = NewMode
      -- Save mode in an array var for the statusline and for hili
      getfileid fid
      do_array 2, EPM_utility_array_ID, 'mode.'fid, CurMode
compile if NEPMD_RESTORE_MODE_FROM_EA
      if UpdateEA then
         -- Set the EA 'EPM.MODE' immediately
         rc = NepmdWriteStringEa( .filename, 'EPM.MODE', CurMode )
         if (rc > 0) then
            sayerror 'EA "EPM.MODE" not set, rc='rc
         endif
         -- Update the EPM EA area to have get_EAT_ASCII_value show the actual value
         call delete_ea('EPM.MODE')
         'add_ea EPM.MODE' CurMode
      endif
compile endif
      call NepmdProcessMode( CurMode )
   endif  -- if NewMode <> ''
   return


; ---------------------------------------------------------------------------
defproc NepmdProcessMode()
   CurMode = arg(1)
   if CurMode = '' then
      CurMode = NepmdGetMode()
   endif

   -- put mode dependent settings here:
compile if NEPMD_SPECIAL_STATUSLINE
   'refreshstatusline'
compile endif
   call NepmdActivateHighlight( 'ON', CurMode )

   return


; ---------------------------------------------------------------------------
; Returns the default mode according to the
; - EA '.TYPE'  (Todo)
; - extension
; - first non-empty line .
; Called by 'mode DEFLOAD' if EA 'EPM.MODE' doesn't exist.
; Called by 'mode' after EA 'EPM.MODE' was just reset.
defproc NepmdGetDefaultMode()

   universal tex_file_types  -- defined in tex.e

   parse arg filename
   if filename = '' then
      filename = .filename
   endif

   -- get the extension
   lastbspos = lastpos( '\', filename )
   name = substr( filename, lastbspos +1 )
   lastpointpos = lastpos( '.', name )
   ext = ''
   basename = name
   if lastpointpos = 0 then
   elseif lastpointpos = length(name) then
      ext = ''
      basename = substr( name, 1, lastpointpos - 1 )
   elseif lastpointpos < length(name) then
      ext = substr( name, lastpointpos + 1 )
      ext = translate(ext)
      ---- Begin: added for .e.out files ----
      forelastpointpos = lastpos( '.', leftstr( name, lastpointpos - 1 ) )
      if ext = 'OUT' and forelastpointpos > 1 then
         --sayerror 'name = 'name', ext = 'ext', forelastpointpos = 'forelastpointpos
         ext = substr( name, forelastpointpos + 1, lastpointpos - forelastpointpos - 1 )
         ext = translate(ext)
         --sayerror '    ext = 'ext', lastpointpos = 'lastpointpos
      endif
      ---- End: added for .e.out files ----
      basename = substr( name, 1, lastpointpos - 1 )
   endif
   --sayerror 'basename = |'basename'|, ext = |'ext'|'

; Todo:
   -- get the .TYPE EA

; Todo: place this externally
; Todo: not only for extensions
   -- Read the first line(s) for special extensions
   if wordpos( ext, 'CMD BAT EXC EXEC XEDIT ERX REX REXX VRX RXX R X XH LOG' ) then
      i = 0
      first_line = ''
      first_two_chars = ''
      first_line_nonempty = ''
      tfirst_line_nonempty = ''
      first_char_nonempty = ''
      ExtProc = ''
      RexxComment = ''
      do forever
         if first_line_nonempty <> '' then leave; endif
         if .last <= i then leave; endif
         i = i + 1
         next = textline(i)
         tnext =  strip( translate(next) )
         if i = 1 then
            first_line = textline(i)
            first_two_chars = leftstr( first_line, 2 )
            if first_two_chars = '/'||'*' then
               RexxComment = 1
               leave
            endif
         endif
         w1 = word( tnext, 1 )
         w2 = word( tnext, 2 )
         if tnext = '' then
            iterate
         elseif first_char_nonempty = '' then
            first_char_nonempty = leftstr( w1, 1 )
         endif
         if wordpos( w1, 'REM @REM : ::' ) = 1 then iterate; endif
         if (w1 = '@ECHO' or w1 = 'ECHO') and w2 = 'OFF' then iterate; endif
         first_line_nonempty = next
         tfirst_line_nonempty = tnext
         if w1 = 'EXTPROC' or w1 = '@EXTPROC' then
            ExtProc = w2
         endif
      enddo
   endif

   defaultmode = ''
   if 0 then
   elseif leftstr( translate(name), 8 ) = 'EPMKWDS.' then
      defaultmode = 'EPMKWDS'
   elseif leftstr( translate(filename), 14 ) = '.COMMAND_SHELL' then
      defaultmode = 'SHELL'
   elseif translate(basename) = 'CONFIG' or ext = 'SYS' then
      defaultmode = 'CONFIGSYS'
   elseif wordpos( ext, 'C H SQC CPP HPP CXX HXX' ) then
      defaultmode= 'C'
   elseif wordpos( ext, 'CMD BAT EXC EXEC XEDIT ERX REX REXX VRX RXX R X XH' ) then
      if RexxComment then
         defaultmode = 'REXX'
      elseif wordpos( ext, 'X XH' ) then
         defaultmode = 'REXX'
      elseif pos( 'PERL', ExtProc ) then
         defaultmode = 'PERL'
      else
         defaultmode = 'CMD'
      endif
   elseif ext = 'E' then
      defaultmode = 'E'
   elseif wordpos( ext, 'INI CNF CFG' ) then
      defaultmode = 'INI'
   elseif wordpos( ext, 'HTM HTML' ) then
      defaultmode = 'HTML'
   elseif wordpos( ext, 'FOR FORTRAN F90' ) then
      defaultmode = 'FORTRAN'
   elseif ext = 'IPF' then
      defaultmode = 'IPF'
   elseif wordpos( ext, 'JAVA JAV' ) then
      defaultmode = 'JAVA'
   elseif translate( leftstr( name, 8 ) ) = 'MAKEFILE' or ext = 'MAK' or ext = 'IN' then
      defaultmode = 'MAKE'
   elseif wordpos( ext, 'PAS PASCAL' ) then
      defaultmode = 'PASCAL'
   elseif wordpos( ext, 'PL PRL PERL' ) then
      defaultmode = 'PERL'
   elseif ext='PHP' then
      defaultmode = 'PHP'
   elseif ext='RC' then
      defaultmode = 'RC'
   elseif ext='DEF' then
      defaultmode = 'DEF'
   elseif ext = 'RXP' then
      defaultmode = 'RXP'
   elseif wordpos( translate(basename), 'READ README' ) > 0 or wordpos( ext, 'TXT DOC' ) > 0 then
      defaultmode = 'TXT'
 compile if defined(my_SCRIPT_FILE_TYPE)
   elseif wordpos( ext, 'SCR SCT SCRIPT' my_SCRIPT_FILE_TYPE ) then
 compile else
   elseif wordpos( ext, 'SCR SCT SCRIPT' ) then
 compile endif
      defaultmode = 'SCRIPT'
   elseif ext = 'LOG' then
      if subword( tfirst_line_nonempty, 1, 2 ) = 'THIS IS' and pos( 'TEX', word( tfirst_line_nonempty, 3 ) ) then
         defaultmode = 'TEX'
      elseif subword( first_line_nonempty, 1, 6 ) = "The 'E' Language Translator for OS/2." then
         defaultmode = 'E'
      endif
   elseif wordpos( ext, tex_file_types ) then
      defaultmode = 'TEX'
   endif
   -- other files
   if defaultmode = '' then
      if first_char_nonempty = '#' then
         defaultmode = 'MAKE'
      elseif first_char_nonempty = ';' then
         defaultmode = 'INI'
      else
         defaultmode = 'UNKNOWN'
      endif
   endif
   return defaultmode


; ---------------------------------------------------------------------
; Opens a listbox to select a mode.
; Called by defc mode if no arg specified.
defproc NepmdSelectMode()
   CurMode = get_EAT_ASCII_value('EPM.MODE')
   ModeList = ''
   if CurMode <> '' then
      ModeList = ' -reset-'
   endif
   ModeList = ModeList || ' TXT REXX CMD E C MAKE IPF HTML TEX CONFIGSYS' ||
              ' NETREXX JAVA ADA BASIC PHP RC PASCAL PERL POSTSCRIPT INI' ||
              ' BOOKMASTER PL/I FORTRAN SHELL EPMKWDS'

   --sayerror 'EPM.MODE = 'CurMode
   Title = 'Select an edit mode'
   if CurMode = '' then
      Text = ' EPM.MODE is not set.'
   else
      Text = ' EPM.MODE is 'CurMode
   endif
   Default = 1
   refresh
   select = listbox( Title,
                     ModeList,
                     '/Set/Cancel',    -- Ref.point  - in chars --
                     35, 30, 25, 25,   -- Top, Left, Height, Width
                     gethwnd(APP_HANDLE) || atoi(Default) || atoi(1) || atoi(0) ||
                     Text\0 )
   refresh
   parse value select with \1 select \0
   select = strip( select, 'B', \1 ) -- sometimes the returned value for cancel is \1
   --sayerror 'defproc selectmode(): select = |'select'|'
   return select

