/****************************** Module Header *******************************
*
* Module Name: filelist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: filelist.e,v 1.2 2004-02-22 20:10:54 aschn Exp $
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

/*
Todo:
-  Change MaxSavedRing and MaxFilesInRing to ini keys
*/

; FileNumber is saved in an array var 'filenumber.'fid to show 'File # of ##'
; FileList is saved in NEPMD.INI to restore a ring

const
; Keep only this amount of rings in NEPMD.INI:
compile if not defined(MaxSavedRings)
   MaxSavedRings = 3          --<---------------------------------------------- Todo
compile endif
; If more files in ring, then ring won't get saved:
compile if not defined(MaxFilesInRing)
   MaxFilesInRing = 30        --<---------------------------------------------- Todo
compile endif
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_RESTORE_RING)
   NEPMD_DEBUG_RESTORE_RING = 0
compile endif
compile if not defined(NEPMD_DEBUG_WRITE_FILE_NUMBER)
   NEPMD_DEBUG_WRITE_FILE_NUMBER = 0
compile endif

; ---------------------------------------------------------------------------
; RingWriteFilePosition is called by 'quit' and NepmdAfterload.
defproc RingWriteFilePosition
   universal nepmd_hini
   universal firstloadedfid
   universal RingWriteFilePositionDisabled

   -- Don't overwite old ring if Disabled flag set (e.g. by RestoreRing)
   if RingWriteFilePositionDisabled = 1 then return; endif

   -- Don't overwite old ring if only .Untitled in ring
   IsUnnamed = (.filename = GetUnnamedFileName())
   if filesinring() = 1 & IsUnnamed then return; endif

   -- Handle MaxSavedRings = 0
   if MaxSavedRings = 0 then return; endif

   -- Handle upper limit for amount of files to save in ini
   if filesinring() > MaxFilesInRing then return; endif

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
   if FoundRing = 0 then  -- if current hwnd not found
      ---- Get ThisNumber ---------------------------------------------------
      KeyPath = '\NEPMD\User\SavedRings\LastNumber'
      LastNumber = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      parse value LastNumber with 'ERROR:'rc
      if rc > '' then  -- if error
         ThisNumber = 1
      elseif LastNumber = '' or LastNumber = MaxSavedRings then  -- if no value or MaxSavedRings reached
         ThisNumber = 1
      else
         -- Check if LastNumber has 0 Entries
         KeyPath = '\NEPMD\User\SavedRings\'LastNumber
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries' )
         if next = 0 then  -- if Entries for LastNumber = 0
            -- Replace LastNumber
            ThisNumber = LastNumber
         else
            -- Iterate number
            ThisNumber = LastNumber + 1
         endif
      endif
      ---- Write LastNumber -------------------------------------------------
      KeyPath = '\NEPMD\User\SavedRings\LastNumber'
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ThisNumber )
      ---- Set KeyPath and write hwnd ---------------------------------------
      KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
      -- begin workaround
      rc = setprofile( nepmd_hini, 'RegContainer', KeyPath, '')
      -- end workaround
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\hwnd', hwnd)
   endif
compile if NEPMD_DEBUG_RESTORE_RING and NEPMD_DEBUG
   call NepmdPmPrintf( 'RWFP: FoundRing = 'FoundRing', ThisNumber = 'ThisNumber )
compile endif

   ---- Delete old 'File'i and 'Posn'i --------------------------------------
   do i = 1 to 1000  -- just an upper limit to prevent looping forever
      rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\File'i )
      rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Posn'i )
      if (rc1 <> 0 & rc2 <> 0) then
         leave
      endif
   enddo

   ---- Write new 'File'i and 'Posn'i ---------------------------------------
   getfileid startfid
compile if 0
   activatefile firstloadedfid
compile else
   next_file  -- Select next file to make current file topmost after restore
compile endif
   getfileid firstfid
   j = 0
   -- Loop through all files in ring
   do i = 1 to filesinring()  -- Provide an upper limit; prevent looping forever
      -- Skip Unnamed files
      IsUnnamed = (.filename = GetUnnamedFileName())
      if not IsUnnamed then
         -- Write 'File'j and 'Posn'j for every file
         j = j + 1
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\File'j, .filename )
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Posn'j, .line .col .cursorx .cursory )
      endif
compile if NEPMD_DEBUG_RESTORE_RING and NEPMD_DEBUG
      call NepmdPmPrintf( 'RWFP: .filename = '.filename', i = 'i'/'MaxFiles', j = 'j', filesinring() = 'MaxFiles', IsUnnamed = 'IsUnnamed)
compile endif
      next_file
      getfileid fid
      if fid = firstfid then leave; endif
   enddo

   ---- Write 'Entries' (ammount of 'File'j and 'Posn'j) --------------------
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', j )

   activatefile startfid
   return

; ---------------------------------------------------------------------------
defc RestoreRing
   universal nepmd_hini
   universal CurEditCmd
   universal RestorePosDisabled
   universal RingWriteFilePositionDisabled

   RestorePosDisabled = 1
   RingWriteFilePositionDisabled = 1
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

   IsUnnamed = (.filename = GetUnnamedFileName())
   do j = 1 to LastEntries
      -- Delete all keys
      filename = NepmdQueryConfigValue( nepmd_hini, KeyPath'\File'j )
      savedpos = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Posn'j )
      OpenNewWindow = 0
      if j = 1 then
         OpenNewWindow = 1
         if (filesinring() = 1) & IsUnnamed then
            OpenNewWindow = 0
         endif
      endif
      if OpenNewWindow = 1 then
compile if NEPMD_DEBUG_RESTORE_RING and NEPMD_DEBUG
         call NepmdPmPrintf(  "RESTORERING: j = "j", o 'restorering "LastNumber"'")
compile endif
-- Problems here:
         "o 'restorering "LastNumber"'"
      else
-- CurEditCmd doesn't work?
         CurEditCmd = 'RESTOREPOS'
compile if NEPMD_DEBUG_RESTORE_RING and NEPMD_DEBUG
         call NepmdPmPrintf( 'RESTORERING: j = 'j', e "'filename'"'||" 'restorepos "savedpos"'")
compile endif
         'e "'filename'"'
         'restorepos 'savedpos
      endif
   enddo

   RingWriteFilePositionDisabled = ''
   RestorePosDisabled = ''
   CurEditCmd = ''

; ---------------------------------------------------------------------------
; Delete all 'SavedRings' entries in NEPMD.INI
; Used to clean NEPMD.INI for testing only.
defc DelSavedRings
   universal nepmd_hini

   KeyPath = '\NEPMD\User\SavedRings'
   next = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\LastNumber' )

   do r = 1 to 100  -- just an upper limit to prevent looping forever
      rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\Entries' )
      rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\hwnd' )
      if (rc1 <> 0) & (rc2 <> 0) then
         leave
      endif
      do i = 1 to 1000  -- just an upper limit to prevent looping forever
         rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\File'i )
         rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\Posn'i )
         if (rc1 <> 0 & rc2 <> 0) then
            leave
         endif
      enddo  -- i

      -- begin workaround
      rc = setprofile( nepmd_hini, 'RegContainer', KeyPath'\'r, '')
      -- end workaround
   enddo  -- r

   -- begin workaround
   rc = setprofile( nepmd_hini, 'RegContainer', KeyPath, '')
   -- end workaround

; ---------------------------------------------------------------------------
; WriteFileNumber is called by LOAD.E: defload.
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
compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
      call NepmdPmPrintf( '### WriteFNumber: firstinringfid not valid, set to: '.filename)
compile endif
      firstinringfid = startfid
   endif

   do i = 1 to filesinring()
      getfileid fid
      -- arg(2) and arg(4) of do_array must be vars!
      FileNumber = i
      do_array 2, EPM_utility_array_ID, 'filenumber.'fid, FileNumber
compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
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
compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
   call NepmdPmPrintf( '*** RingWFNumber: startfile = 'startfid.filename)
compile endif

   display -2  -- turn off messages
   activatefile firstinringfid
   display 2   -- turn on messages

   if rc = -260 then  -- Invalid fileid
      -- if firstinringfid is not in ring anymore
compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
      call NepmdPmPrintf( '### RingWFNumber: startfid not found in ring, redetermining lowest file number.')
compile endif
      -- redetermine first loaded file (file with lowest FileNumber)
      LowestFileNumber = filesinring()
      getfileid lowestnumfid  -- initialize
      do i = 1 to filesinring()
         getfileid fid
         numrc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, next )
         --next = GetFileNumber()  -- doesn't work if firstinringfid not set
compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
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

compile if NEPMD_DEBUG_WRITE_FILE_NUMBER and NEPMD_DEBUG
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

; ---------------------------------------------------------------------------
; called by defproc GetInfoRuleValue('FILE')
defproc GetFileNumber
   universal EPM_utility_array_ID
   FileNumber = ''

   -- Get FileNumber for Filename by querying an array var
   getfileid fid
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

