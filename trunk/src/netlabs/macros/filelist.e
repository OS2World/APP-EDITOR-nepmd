; new
/*
Changed:
-  Important: Enable write of filelist only after (used NepmdAfterLoad
   therefore) all files are loaded by Recompile.

Todo:
?  Make RestoreRing overwrite old hwnd key to not overwrite another ring.
   Disadvantage: the sequence of saved rings will get changed.
-  DelSavedRings sometimes doesn''t work
-  Change MaxSavedRings and RESTORE_RING to ini keys
-  NepmdPmPrintf

; ok Bug:
;
; When first loaded file with the lowest file id (or file number) is active:
;    File -> New      (defc new)
; or
;    File -> Revert   (defc revert)
; Error message: Ungltige Dateikennung
;
; Apparently this occures only if the replaced file has the lowest FileNumber.
;
; ->    universal firstloadedfid
;       must be set to '' on 'quit'?

*/
/****************************** Module Header *******************************
*
* Module Name: filelist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: filelist.e,v 1.1 2004-01-17 22:22:51 aschn Exp $
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

; MAIN.E
; LOAD.E
; STDCMDS.E: defc quit
; STATLINE.E

; FileNumber is saved in an array var 'filenumber.'fid to show 'File # of ##'
; FileList is saved in NEPMD.INI to restore a ring

const
compile if not defined(MaxSavedRings)
   MaxSavedRings = 3
compile endif
compile if not defined(RESTORE_RING)
; switch save/restore of edit ring on/off
   RESTORE_RING = 1
compile endif
; ----- for testing -----
; Todo: delete all entries of SavedRings\r\ properly, even if one of
; the range doesn't exist.
compile if not defined(DefmainPrepareSavedRing)
   DefmainPrepareSavedRing = 1                              --<------------- ???
compile endif
compile if not defined(DefmainRingWriteFileNumber)
   DebugRingWriteFileNumber = 0
compile endif
compile if not defined(DebugRestoreRings)
   DebugRestoreRings = 0
compile endif

; ---------------------------------------------------------------------
; FileListDefmain is called by defmain
; Prepares the next file list by increasing LastNumber by 1 and
; deleting all File and Posn entries for this file list.
defproc FileListDefmain
/**/
compile if DefmainPrepareSavedRing
   universal nepmd_hini

   -- Set LastNumber (increase it by 1) and delete old entries
   --sayerror 'happ = 'getpminfo(APP_HANDLE)          -- unique handle per process
   --sayerror 'hwnd = 'getpminfo(EPMINFO_EDITCLIENT)  -- unique handle per EPM window
   --sayerror 'happ = 'getpminfo(APP_HANDLE)', hwnd = 'getpminfo(EPMINFO_EDITCLIENT)
-- Todo: associate this ring with hwnd to make SetFilePosition at defload choose
-- the correct ring, even if more windows are opened.

   if MaxSavedRings = 0 then
      return
   endif

   KeyPath = '\NEPMD\User\SavedRings\LastNumber'
   LastNumber = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   parse value LastNumber with 'ERROR:'rc
   if rc > '' then
      ThisNumber = 1
   -- Todo: handle MaxSavedRings = 0
   elseif LastNumber = '' or LastNumber = MaxSavedRings then
      ThisNumber = 1
   else
      ThisNumber = LastNumber + 1
   endif
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ThisNumber )

   -- Save frame window handle
   KeyPath = '\NEPMD\User\SavedRings\'ThisNumber'\hwnd'
   hwnd = '0x'ltoa( gethwndc(6), 16)   -- EPMINFO_EDITFRAME
   --sayerror 'defmain: hwnd = 'hwnd
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, hwnd )

   -- Delete old frame window handle, if already in INI
   do r = 1 to MaxSavedRings
      KeyPath = '\NEPMD\User\SavedRings\'r
      next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\hwnd')
      parse value next with 'ERROR:'rc
      if rc > '' then
         iterate
      endif
      if next = hwnd then
         -- delete all keys for this handle, because files for one ring are
         -- added to this Keypath, identified by hwnd only.
         Entries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
         do i = 1 to Entries
            -- Delete all keys
            rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\File'i )
            rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Posn'i )
         enddo
      endif
   enddo

   -- Save last amount of entries
   KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
   Entries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
   do i = 1 to Entries
      -- Delete all keys
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\File'i )
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Posn'i )
   enddo
   -- begin workaround
   rc = setprofile( nepmd_hini, 'RegContainer', KeyPath, '')
   -- end workaround
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', 0 )
compile endif
/**/
   return

; ---------------------------------------------------------------------
; WriteFilePosition is called by FileListDefload/defload
; Bug: When position is also restored by Recomp, then WriteFilePosition
;      writes '1 1 1 2' as POSNx.
; Bug: If many files are loaded into the ring with one 'edit' call,
;      then the ini entry is not written properly.
;      Sometimes 'DelSavedRings' can't remove 'RegContainer' ->
;      'NEPMD\User\SavedRings\'i keys than.
; Better: after all file loading is done, loop through the ring and
;         write all at once.
;         => Don't call WriteFilePosition (RingWriteFilePosition is
;            fast enough if no more defloads are to be processed).
;         => FileListDefmain can be dropped.
defproc WriteFilePosition
/**/
   universal nepmd_hini

   if leftstr( .filename, 1 ) = '.' then
      return
   endif

   if MaxSavedRings = 0 then
      return
   endif

   hwnd = '0x'ltoa( gethwndc(6), 16)   -- EPMINFO_EDITFRAME

   do r = 1 to MaxSavedRings
      -- search hwnd in '\NEPMD\User\SavedRings\'r'\hwnd'
      KeyPath = '\NEPMD\User\SavedRings\'r
      next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\hwnd')
      parse value next with 'ERROR:'rc
      if rc > '' then
         iterate
      endif
      if next = hwnd then
         -- Get last amount of entries
         LastEntries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
         i = LastEntries + 1
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\File'i, .filename )
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Posn'i, .line .col .cursorx .cursory )
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', i )
         leave
      endif
   enddo

/**/
/*
;   KeyPath = '\NEPMD\User\SavedRings\LastNumber'
;   ThisNumber = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   -- Todo: handle ThisNumber = ''
   KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
   -- Get last amount of entries
   LastEntries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
   i = LastEntries + 1
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\File'i, .filename )
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Posn'i, .line .col .cursorx .cursory )
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', i )
*/
   return


; ---------------------------------------------------------------------------
; RingWriteFilePosition is called by 'quit' and NepmdAfterload.
defproc RingWriteFilePosition
   universal nepmd_hini

   -- Handle MaxSavedRings = 0
   if MaxSavedRings = 0 then return; endif

   -- Get EPM EFrame window handle
   hwnd = '0x'ltoa( gethwndc(6), 16)   -- EPMINFO_EDITFRAME

   ---- Search hwnd in SavedRings -------------------------------------------
   FoundRing = 0
   do r = 1 to MaxSavedRings
      -- Search hwnd in '\NEPMD\User\SavedRings\'r'\hwnd'
      ThisNumber = r
      KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
      next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\hwnd')
      parse value next with 'ERROR:'rc
      if rc > '' then
         iterate
      endif
      if next = hwnd then
         -- If found: KeyPath is already set
         FoundRing = r
         leave
      endif
   enddo
   if FoundRing = 0 then
      -- If ring not found: get ThisNumber and write as 'LastNumber'
      KeyPath = '\NEPMD\User\SavedRings\LastNumber'
      LastNumber = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      parse value LastNumber with 'ERROR:'rc
      if rc > '' then
         ThisNumber = 1
      elseif LastNumber = '' or LastNumber = MaxSavedRings then
         ThisNumber = 1
      else
         ThisNumber = LastNumber + 1
      endif
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ThisNumber )
      -- If ring not found: set KeyPath and write hwnd
      KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\hwnd', hwnd)
   endif
compile if DebugRestoreRings
   call NepmdPmPrintf( 'FoundRing = 'FoundRing', ThisNumber = 'ThisNumber )
compile endif

   ---- Delete old 'File'i and 'Posn'i --------------------------------------
   i = 0
   do forever
      i = i + 1
      rc1 = NepmdQueryConfigValue( nepmd_hini, KeyPath'\File'i )
compile if DebugRestoreRings
      if i = 1 then
         LastEntries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
         call NepmdPmPrintf( 'Delete ring: LastEntries = 'LastEntries' ------------------' )
      endif
compile endif
      if rc1 > '' then  -- if entry or error
         parse value rc1 with 'ERROR:'rc
         if rc > '' then  -- if error
            rc1 = ''
         else
            rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\File'i )
         endif
      endif
      rc2 = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Posn'i )
      if rc2 > '' then  -- if entry or error
         parse value rc1 with 'ERROR:'rc
         if rc > '' then  -- if error
            rc2 = ''
         else
            rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Posn'i )
         endif
      endif
compile if DebugRestoreRings
      call NepmdPmPrintf( 'Delete ring: i = 'i', rc1 = 'rc1', rc2 = 'rc2 )
compile endif
      if (rc1 = '' and rc2 = '') then
         leave
      endif
      if i = 100 then  -- upper limit
         leave
      endif
   enddo

   ---- Delete old 'Entries' ------------------------------------------------
   rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Entries' )
   -- begin workaround
   KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
   rc = setprofile( nepmd_hini, 'RegContainer', KeyPath, '')
   -- end workaround
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', 0 )

   ---- Write new 'File'i and 'Posn'i ---------------------------------------
   getfileid startfid
   j = 0
   -- Loop through all files in ring
   MaxFiles = filesinring()
   --do i = 1 to filesinring()  -- Provide an upper limit; prevent looping forever
   do i = 1 to MaxFiles  -- Provide an upper limit; prevent looping forever
      -- Skip Unnamed files
      --    the following gives forever false because it gets expanded too late:
      --if not .filename = GetUnnamedFileName() then
      --    make an assignment first:
      IsUnnamed = (.filename = GetUnnamedFileName())
      if not IsUnnamed then
         -- Write 'File'j and 'Posn'j for every file
         j = j + 1
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\File'j, .filename )
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Posn'j, .line .col .cursorx .cursory )
      endif
compile if DebugRestoreRings
      call NepmdPmPrintf( 'i = 'i', j = 'j', filesinring() = 'MaxFiles', IsUnnamed = 'IsUnnamed)
compile endif
      next_file
      getfileid curfid
      if curfid = startfid then leave; endif
   enddo
   activatefile startfid

   ---- Write 'Entries' (ammount of 'File'j and 'Posn'j) --------------------
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', j )

   return

; ---------------------------------------------------------------------------
defc RestoreRing
   universal nepmd_hini
   universal CurEditCmd
   LastNumber = arg(1)
   if LastNumber = '' then
      KeyPath = '\NEPMD\User\SavedRings\LastNumber'
      LastNumber = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   endif
   hwnd = '0x'ltoa( gethwndc(6), 16)   -- EPMINFO_EDITFRAME
   KeyPath = '\NEPMD\User\SavedRings\'LastNumber
   LastNumberHwnd = NepmdQueryConfigValue( nepmd_hini, KeyPath'\hwnd')
   if hwnd = LastNumberhwnd then
      LastNumber = LastNumber - 1
      if LastNumber = 0 then
         do r = MaxSavedRings to 1 by -1
            KeyPath = '\NEPMD\User\SavedRings\'r
            Entries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
            parse value Entries with 'ERROR:'rc
            if rc > '' then
               iterate
            else
               LastNumber = r
            endif
         enddo
      endif
   endif
   -- Get last amount of entries
   KeyPath = '\NEPMD\User\SavedRings\'LastNumber
   LastEntries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
   do j = 1 to LastEntries
      -- Delete all keys
      filename = NepmdQueryConfigValue( nepmd_hini, KeyPath'\File'j )
      savedpos = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Posn'j )
      OpenNewWindow = 0
      if j = 1 then
         OpenNewWindow = 1
         if filesinring() = 1 then
            if .filename = '.Untitled' or '.Ohne Namen' then
               OpenNewWindow = 0
            endif
         endif
      endif
      if OpenNewWindow = 1 then
         call NepmdPmPrintf(  "j = "j", o 'restorering "LastNumber"'")
-- Problems here:
         "o 'restorering "LastNumber"'"
         --"xcom e /n 'restorering "LastNumber"'"
      else
-- CurEditCmd doesn't work?
         CurEditCmd = 'RESTOREPOS'
         call NepmdPmPrintf( 'j = 'j', e "'filename'"'||" 'restorepos "savedpos"'")
         'e "'filename'"'
         'restorepos 'savedpos
      endif
   enddo
   CurEditCmd = ''

; ---------------------------------------------------------------------------
; Delete all 'SavedRings' entries in NEPMD.INI
; Used to clean NEPMD.INI, sometimes must be interrupted by Ctrl+Break
defc DelSavedRings
/**/
   KeyPath = '\NEPMD\User\SavedRings'
   keyword = 'LastNumber'
   next = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'keyword )
   --sayerror 'Delete: 'KeyPath'\'keyword', rc = 'next
   KeyList1 = 'hwnd Entries'
   KeyList2 = 'File Posn'
   --r = 0
   --do r = 1 to MaxSavedRings
   --do forever
   do r = 1 to 1000
      --r = r + 1
      KeyPath = '\NEPMD\User\SavedRings\'r
      Entries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
      parse value Entries with 'ERROR:'rc
      if rc > '' then
         leave
      endif
      --do i = 1 to Entries
      --i = 0
      --do forever
      do i = 1 to 1000
         --i = i + 1
         rcf = 0
         do w = 1 to words( KeyList2)
            keyword = word( KeyList2, w)
            next = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'keyword''i )
            parse value next with 'ERROR:'rc
            if rc > '' then
               rcf = rcf + 1
            endif
            --sayerror 'Delete: 'KeyPath'\'keyword', rc = 'next
         enddo
         if rcf = words( KeyList2) then
            leave
         endif
      enddo
      do w = 1 to words( KeyList1)
         keyword = word( KeyList1, w)
         next = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'keyword )
         --sayerror 'Delete: 'KeyPath'\'keyword', rc = 'next
      enddo
   enddo
/**/
   return

; ---------------------------------------------------------------------------
; WriteFileNumber is called by
;    LOAD.E: defload (EPM bug, like every defload definition:
;                     must be called here to work everytime,
;                     a standard defload won't work)
;                     -> better call it in SLNOHOST.E: defproc loadfile?
;                        No, loadfile may load multiple files!
-- WriteFileNumber is called by FileListDefload/defload  <-- No, not anymore,
-- maybe get called by building the titletext at every defload?
defproc WriteFileNumber
   universal firstinringfid  -- first file in ring, set by edit
   universal EPM_utility_array_ID

   getfileid startfid  -- current file

   display -2  -- turn off messages
   activatefile firstinringfid
   display 2   -- turn on messages
   -- This fid is not valid, if RingWriteFileNumber was not called,
   -- e.g. if EPM starts with an unnamed file.
   if rc = -260 then  -- Invalid fileid
compile if DebugRingWriteFileNumber = 1
      call NepmdPmPrintf( '### WriteFNumber: firstinringfid not valid, set to: '.filename)
compile endif
      firstinringfid = startfid
   endif

   do i = 1 to filesinring()
      getfileid fid
      -- arg(2) and arg(4) of do_array must be vars!
      FileNumber = i
      do_array 2, EPM_utility_array_ID, 'filenumber.'fid, FileNumber
compile if DebugRingWriteFileNumber = 1
      call NepmdPmPrintf( '*** WriteFNumber: i = 'i', FileNumber = 'i', FileName = 'fid.filename)
compile endif
      nextfile
   enddo

   activatefile startfid
   return

; ---------------------------------------------------------------------------
; RingWriteFileNumber is called by 'quit' and NepmdAfterLoad.
; The firstinringfid is checked. If not valid anymore (e.g. if file was
; quit), then it is set to the lowest FileNumber of all files in the ring.
; At the end all FileNumbers are rewritten, starting with firstinringfid.
;
; Note: FileNumbers are assigned according to the order in the ring, while
; fileids are assigned unsorted (but it looks like it's influenced by the
; file size). The use of firstinringfid, set by the first edit command
; together with redertermining it if not valid anymore by
; RingWriteFileNumber ensures, that the first file in the ring gets the
; FileNumber 1 assigned. The 'ring_more' dialog is filled internally, its
; files are ordered according to their fileids.
defproc RingWriteFileNumber
   universal firstinringfid
   universal EPM_utility_array_ID

   getfileid startfid
compile if DebugRingWriteFileNumber = 1
   call NepmdPmPrintf( '*** RingWFNumber: startfile = 'startfid.filename)
compile endif

   display -2  -- turn off messages
   activatefile firstinringfid
   display 2   -- turn on messages

   if rc = -260 then  -- Invalid fileid
      -- if firstinringfid is not in ring anymore
compile if DebugRingWriteFileNumber = 1
      call NepmdPmPrintf( '### RingWFNumber: startfid not found in ring, redetermining lowest file number.')
compile endif
      -- redetermine first loaded file (file with lowest FileNumber)
      LowestFileNumber = filesinring()
      getfileid lowestnumfid  -- initialize
      do i = 1 to filesinring()
         getfileid fid
         numrc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, next )
         --next = GetFileNumber()  -- doesn't work if firstinringfid not set
compile if DebugRingWriteFileNumber = 1
         call NepmdPmPrintf( '*** RingWFNumber: i = 'i', FileNumber = 'next', FileName = '.filename)
compile endif
         if next <= LowestFileNumber & next <> '' then
            LowestFileNumber = next
            lowestnumfid = fid
         endif
         nextfile
      enddo
      -- set firstinringfid
      firstinringfid = lowestnumfid
   endif

compile if DebugRingWriteFileNumber = 1
   call NepmdPmPrintf( '*** RingWFNumber: firstinringfid = 'firstinringfid.filename)
compile endif

   -- Set FileNumbers for all files in the ring, start with LowestFId
   FileNumber = 0
   activatefile firstinringfid
   do i = 1 to filesinring()
      getfileid fid
      FileNumber = FileNumber + 1
      -- arg(2) and arg(4) of do_array must be vars!
      do_array 2, EPM_utility_array_ID, 'filenumber.'fid, FileNumber
      'RefreshInfoLine FILELIST'
      nextfile
   enddo
   activatefile startfid
   return

/*
; ---------------------------------------------------------------------------
defc RingWriteFileNumber
   call RingWriteFileNumber()
*/

; ---------------------------------------------------------------------------
; called by defproc GetInfoRuleValue('FILE')
defproc GetFileNumber
   universal EPM_utility_array_ID
   FileNumber = ''

   -- Get FileNumber for Filename by querying an array var
   --getfileid fid, Filename
   getfileid fid
   -- arg(2) and arg(4) of do_array must be vars!
   --do_array 3, EPM_utility_array_ID, 'filenumber.'fid, FileNumber
   rc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, FileNumber )
   if FileNumber = '' then
;      sayerror .filename': No FileNumber set.'
      call WriteFileNumber()
      rc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, FileNumber )
      if FileNumber = '' then
         -- This should not occur!
         sayerror .filename': 2nd try -- no FileNumber set.'
      endif
   endif

   return FileNumber

