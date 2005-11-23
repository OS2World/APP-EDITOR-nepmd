/****************************** Module Header *******************************
*
* Module Name: filelist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: filelist.e,v 1.10 2005-11-23 23:49:49 aschn Exp $
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
- defproc RingAddToHistory doesn't work for wildcards in filespec; why?
*/

; -  Numbering files in the ring to provide the 'File # of ##' or '#/##' field
;    for the titletext or statusbar
; -  Save and restore a ring to/from NEPMD.INI
; -  History definitions to track commands or files from EDIT, LOAD and SAVE

; ---------------------------------------------------------------------------
; RingAutoWriteFilePosition is called by 'quit' and 'Afterload'.
defproc RingAutoWriteFilePosition
   universal nepmd_hini
   universal RingWriteFilePositionDisabled
   universal RingWriteFilePositionMaxFilesReached  -- used only here

   -- Don't overwite old ring if Disabled flag set (e.g. by RestoreRing)
   if RingWriteFilePositionDisabled = 1 then return; endif

   -- Don't overwite old ring if only .Untitled in ring
   IsUnnamed = (.filename = GetUnnamedFileName())
   if filesinring() = 1 & IsUnnamed then return; endif

   -- Check if Enabled
   KeyPath = '\NEPMD\User\AutoRestore\Ring\SaveLast'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled <> 1 then return; endif

   -- Handle upper limit for amount of files to save in ini
   KeyPath = '\NEPMD\User\AutoRestore\Ring\MaxFiles'
   MaxFiles = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if not isnum(MaxFiles) then
      MaxFiles = 30
   endif
   if filesinring() > MaxFiles then
      -- Check if MaxFiles was already reached before for this edit window
      -- to suppress the msg for following files
      if RingWriteFilePositionMaxFilesReached <> 1 then
         -- Give that msg only once
         sayerror 'Number of files in ring exceeds max = 'MaxFiles'.' ||
                  ' Ring not saved.'
         RingWriteFilePositionMaxFilesReached = 1
      endif
      return
   else
      RingWriteFilePositionMaxFilesReached = 0
   endif

   call RingWriteFilePosition()
   return

; ---------------------------------------------------------------------------
; RingWriteFilePosition is called by RingAutoWiteFilePosition and by defc
; RingWriteFilePosition, used by the menuitem 'Save as last ring'.
defproc RingWriteFilePosition
   universal nepmd_hini

   KeyPath = '\NEPMD\User\AutoRestore\Ring\MaxRings'
   MaxRings = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if not isnum(MaxRings) then
      MaxRings = 1
   endif
   -- Handle MaxRings = 0
   if MaxRings = 0 then return; endif

   -- Get EPM EFrame window handle
   hwnd = '0x'ltoa( gethwndc(6), 16)   -- EPMINFO_EDITFRAME

   ---- Search hwnd in SavedRings -------------------------------------------
   FoundRing = 0
   do r = 1 to MaxRings
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
      elseif LastNumber = '' or LastNumber >= MaxRings then  -- if no value or MaxRings reached
         ThisNumber = 1
      else
         -- Check if LastNumber has 0 Entries
         KeyPath = '\NEPMD\User\SavedRings\'LastNumber
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries')
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
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, ThisNumber)
      ---- Set KeyPath and write hwnd ---------------------------------------
      KeyPath = '\NEPMD\User\SavedRings\'ThisNumber
      -- begin workaround
      rc = setprofile( nepmd_hini, 'RegContainer', KeyPath, '')
      -- end workaround
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\hwnd', hwnd)
   endif

   ---- Delete old 'File'i and 'Posn'i --------------------------------------
   do i = 1 to 1000  -- just an upper limit to prevent looping forever
      rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\File'i)
      rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Posn'i)
      if (rc1 <> 0 & rc2 <> 0) then
         leave
      endif
   enddo

   ---- Write new 'File'i and 'Posn'i ---------------------------------------
   getfileid startfid
   -- Select next file to make current file topmost after restore
   next_file
   getfileid firstfid
   j = 0
   -- Loop through all files in ring
   do i = 1 to filesinring()  -- Provide an upper limit; prevent looping forever
      -- Skip temp. files
      Ignore = ((leftstr( .filename, 1) = '.') | (not .visible))
      if not Ignore then
         -- Write 'File'j and 'Posn'j for every file
         j = j + 1
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\File'j, .filename )
         rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Posn'j, .line .col .cursorx .cursory )
      endif
      next_file
      getfileid fid
      if fid = firstfid then leave; endif
   enddo

   ---- Write 'Entries' (ammount of 'File'j and 'Posn'j) --------------------
   rc = NepmdWriteConfigValue( nepmd_hini, KeyPath'\Entries', j )

   -- Check if file to be activated is still in ring
   if wordpos( ValidateFileid(startfid), '1 2') then
      activatefile startfid
   endif
   return

; ---------------------------------------------------------------------------
defc SaveRing, RingWriteFilePosition
   call RingWriteFilePosition()

; ---------------------------------------------------------------------------
defc RestoreRing
   universal nepmd_hini
   universal CurEditCmd
   universal RestorePosDisabled
   universal RingWriteFilePositionDisabled

   KeyPath = '\NEPMD\User\AutoRestore\Ring\MaxRings'
   MaxRings = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if not isnum(MaxRings) then
      MaxRings = 1
   endif
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
         do r = MaxRings to 1 by -1
            KeyPath = '\NEPMD\User\SavedRings\'r
            Entries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries')
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
   LastEntries = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Entries')

   IsEmptyFileOnly = (.filename = GetUnnamedFileName() & filesinring() = 1 & .modify = 0)
   emptyfid = ''
   if IsEmptyFileOnly then
      getfileid emptyfid
   endif
   do j = 1 to LastEntries
      filename = NepmdQueryConfigValue( nepmd_hini, KeyPath'\File'j)
      savedpos = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Posn'j)
      OpenNewWindow = 0
      --OpenNewWindow = 1
/*
      if j = 1 then
         OpenNewWindow = 1
         if IsEmptyFileOnly then
            OpenNewWindow = 0
         endif
      endif
*/
      if OpenNewWindow = 1 then
         dprintf( 'RESTORE_RING', "j = "j", o 'restorering "LastNumber"'")
-- Problems here:
         "o 'restorering "LastNumber"'"
         return
      else
         dprintf( 'RESTORE_RING', 'j = 'j', e "'filename'"'||" 'restorepos "savedpos"'")
         if pos( ' ', filename) then
            filename = '"'filename'"'
         endif
         CurEditCmd = 'RESTORERING'
         'e 'filename
         if rc = 0 then
            getfileid lastfid
            'restorepos 'savedpos
         endif
      endif
   enddo
   WorkDir = NepmdQueryConfigValue( nepmd_hini, KeyPath'\WorkDir')
   if NepmdDirExists( LastWorkDir) = 1 then
      call directory( '\')
      call directory( WorkDir)
   endif

   RingWriteFilePositionDisabled = ''
   RestorePosDisabled = ''

; ---------------------------------------------------------------------------
; Delete all 'SavedRings' entries in NEPMD.INI
; Used to clean NEPMD.INI for testing only.
defc DelSavedRings
   universal nepmd_hini

   KeyPath = '\NEPMD\User\SavedRings'
   next = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\LastNumber')

   do r = 1 to 1000  -- just an upper limit to prevent looping forever
      rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\Entries')
      rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\hwnd')
      if (rc1 <> 0) & (rc2 <> 0) then
         iterate
      endif
      do i = 1 to 1000  -- just an upper limit to prevent looping forever
         rc1 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\File'i)
         rc2 = NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'r'\Posn'i)
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
defc RingMaxFiles
   universal nepmd_hini
   KeyPath = '\NEPMD\User\AutoRestore\Ring\MaxFiles'
   -- if executed with a num as arg
   if arg(1) <> '' & isnum(arg(1)) then
      rc = NepmdWriteConfigValue( nepmd_hini, KeyPath, arg(1))
      return
   endif
   -- else open entrybox
   Title   = 'Set limit for Auto-save last ring        '  -- add. spaces to fit the title into width
   Text    = 'Enter max. number of files'
   IniValue = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   DefaultButton = 1
   parse value entrybox( Title,
                         '/~Set/~Reset/~Cancel',  -- max. 4 buttons
                         IniValue,
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   -- strip + or -
   if Button = \1 then
      'RingMaxFiles' NewValue
      return
   elseif Button = \2 then
      rc = NepmdDeleteConfigValue( nepmd_hini, KeyPath)
      return
   elseif Button = \3 then
      return
   endif

; ---------------------------------------------------------------------------
; Called by afterload if filestoloadmax less than a limit.
defproc RingAddToHistory
   universal nepmd_hini  -- often forgotten

   KeyPath = '\NEPMD\User\History'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled <> 1 then
      return
   endif

   --MaxLength = 65536
   MaxLength = 1599  -- apparently
   MaxItems  = 200
   Delim = \1  -- \0 doesn't work for NepmdWriteConfigValue

   ListName = upcase( arg(1))
   if ListName = '' then
      ListName = 'LOAD'
   endif
   if ListName = 'LOAD' then
      KeyPath = '\NEPMD\User\History\Load'
   else
      return
   endif
   History = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   getfileid startfid
   -- Select next file to make current file the first in list
   next_file
   getfileid firstfid
   -- Loop through all files in ring
   do f = 1 to filesinring()  -- Provide an upper limit; prevent looping forever
      NewItem = .filename
      rest = History
      -- Skip temp files
      fIgnore = ((leftstr( NewItem, 1) = '.') | (not .visible))
      if not fIgnore then
         -- Add NewItem
         i = 1
         History = NewItem''Delim
         StopList = 0
         do while (rest <> '' & StopList = 0)
            parse value rest with next (Delim) rest
            -- Check length of string first
            NewHistory = History''next''Delim
            len = length(NewHistory) + 1
            if i >= MaxItems then
               StopList = 1
            elseif len > MaxLength then
               StopList = 1
            elseif upcase(NewItem) <> upcase(next) then
               -- Add next
               i = i + 1
               History = NewHistory
            endif
         enddo  -- while
      endif  -- not fIgnore
      next_file
      getfileid fid
      if fid = firstfid then leave; endif
   enddo  -- f = 1 to filesinring()
   activatefile startfid  -- required

   call NepmdWriteConfigValue( nepmd_hini, KeyPath, History)
   return

; ---------------------------------------------------------------------------
; Called by edit and save.
defproc AddToHistory( Listname, NewItem)
   universal nepmd_hini  -- often forgotten

   KeyPath = '\NEPMD\User\History'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled <> 1 then
      return
   endif

   --MaxLength = 65536
   MaxLength = 1599
   MaxItems  = 200
   Delim = \1

   ListName = upcase( Listname)

   if ListName = 'LOAD' then
      KeyPath = '\NEPMD\User\History\Load'
      Ignore = (leftstr( NewItem, 1) = '.')
   elseif ListName = 'SAVE' then
      KeyPath = '\NEPMD\User\History\Save'
      Ignore = (leftstr( NewItem, 1) = '.')
   elseif ListName = 'EDIT' then
      KeyPath = '\NEPMD\User\History\Edit'
      Ignore = 0
   else
      return
   endif

   History = NepmdQueryConfigValue( nepmd_hini, KeyPath)

   rest = History
   if not Ignore then
      -- Add NewItem
      f = 1
      History = NewItem''Delim
      StopList = 0
      do while (rest <> '' & StopList = 0)
         parse value rest with next (Delim) rest
         -- Check length of string first
         NewHistory = History''next''Delim
         len = length(NewHistory) + 1
         if f >= MaxItems then
            StopList = 1
         elseif len > MaxLength then
            StopList = 1
         elseif upcase(NewItem) <> upcase(next) then
            -- Add next
            f = f + 1
            History = NewHistory
         endif
      enddo  -- while

      call NepmdWriteConfigValue( nepmd_hini, KeyPath, History)
   endif  -- not Ignore
   return

; ---------------------------------------------------------------------------
; For use with postme.
defc AddToHistory
   parse arg ListName NewItem
   call AddToHistory( ListName, NewItem)

; ---------------------------------------------------------------------------
defc History
   universal nepmd_hini  -- often forgotten

   Delim = \1

   ListName = strip( upcase( arg(1)))
   if ListName = '' then
      ListName = 'LOAD'
   endif
   if ListName = 'LOAD' then
      KeyPath = '\NEPMD\User\History\Load'
      Title = 'Select a file from LOAD history'
   elseif ListName = 'SAVE' then
      KeyPath = '\NEPMD\User\History\Save'
      Title = 'Select a file from SAVE history'
   elseif ListName = 'EDIT' then
      KeyPath = '\NEPMD\User\History\Edit'
      Title = 'Select a file from EDIT history'
   else
      sayerror '"'ListName'" is not a valid arg for HISTORY. Specify one of LOAD, SAVE or EDIT.'
      return
   endif
   History = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   HistoryList = Delim''History
   HistoryList = strip( HistoryList, 'T', Delim)

   -- Open Listbox
   -- No Linebreak allowed in Text
   Text = 'Press "Add" to edit it in the current window,' ||
          ' press "Open" to edit it in a new window.'
   -- Default selected item
   Selection = 1
   -- Window coordinates in lines and columns (0 or '' are default values)
   top_lines    = 0 --5
                  -- doc says: default is under cursor, but that is wrong
   left_cols    = 0 --5
                  -- default is at cursor
   -- top_lines = 0 and left_cols = 0 defaults to:
                  -- Try to open the window at cursor, within the edit window.
                  -- This gives the best result for larger windows, even for
                  -- 10.System Proportional as dialog font.
   height_lines = min( 20, .windowheight)
                  -- default is 4 visible entries in listbox
   width_cols   = min( 80, .windowwidth)
                  -- default depends on max. width of Title, Text, buttons
   refresh
   select = listbox( Title,
                     HistoryList,
                     '/~Add/~Open/A~dd.../O~pen.../Open ~folder of/~Cancel',   -- buttons
                     top_lines, left_cols,
                     height_lines, width_cols,
                     gethwnd(APP_HANDLE) || atoi(Selection) || atoi(1) || atoi(0) ||
                     Text\0)
   refresh

   -- Check result
   button = asc(leftstr( select, 1))
   EOS = pos( \0, select, 2)        -- CHR(0) signifies End Of String
   select= substr( select, 2, EOS - 2)
   -- Edit or open filename
   if ListName = 'LOAD' | ListName = 'SAVE' then
      -- Add doublequotes for filenames with spaces and if not already added
      if pos( ' ', select) then
         if not (leftstr( select, 1) = '"' & rightstr( select, 1) = '"') then
            select = '"'select'"'
         endif
      endif
   endif
   if button = 1 then
      'e 'select
   elseif button = 2 then
      'o 'select
   elseif button = 3 then
      'opendlg EDIT'
   elseif button = 4 then
      'opendlg OPEN'
   elseif button = 5 then
      'openfolderof 'select
   endif

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
   universal nepmd_hini

   -- Process only, when a <file> field is present
   KeyPath = '\NEPMD\User\InfoLine\TitleFields'
   TitleFields = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if pos( '<file>', TitleFields) = 0 then
      KeyPath = '\NEPMD\User\InfoLine\TitleFields'
      StatusFields = NepmdQueryConfigValue( nepmd_hini, KeyPath)
      if pos( '<file>', StatusFields) = 0 then
         return
      endif
   endif

   getfileid startfid
   dprintf( 'WRITE_FILE_NUMBER', 'startfile = 'startfid.filename)

   display -2  -- turn off messages
   activatefile firstinringfid
   display 2   -- turn on messages

   if rc = -260 then  -- Invalid fileid
      -- if firstinringfid is not in ring anymore
      dprintf( 'WRITE_FILE_NUMBER', 'startfid not found in ring, redetermining lowest file number.')
      -- redetermine first loaded file (file with lowest FileNumber)
      LowestFileNumber = filesinring()
      getfileid lowestnumfid  -- initialize
      do i = 1 to filesinring()
         getfileid fid
         numrc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, next )
         --next = GetFileNumber()  -- doesn't work if firstinringfid not set
         dprintf( 'WRITE_FILE_NUMBER', 'i = 'i', FileNumber = 'next', FileName = '.filename)
         if next <= LowestFileNumber & next <> '' then
            LowestFileNumber = next
            lowestnumfid = fid
         endif
         nextfile
      enddo
      -- set firstinringfid
      firstinringfid = lowestnumfid
   endif

   dprintf( 'WRITE_FILE_NUMBER', 'firstinringfid = 'firstinringfid.filename)

   -- Set FileNumbers for all files in the ring, start with LowestFId
   FileNumber = 0
   activatefile firstinringfid
   do i = 1 to filesinring()
      getfileid fid
      FileNumber = FileNumber + 1
      -- arg(2) and arg(4) of do_array must be vars!
      do_array 2, EPM_utility_array_ID, 'filenumber.'fid, FileNumber
      'RefreshInfoLine FILELIST'  -- Critical? If this would be processed only on defselect, the field for
                                  -- a file, selected by the internal ask-before-quit-if-modified routine
                                  -- is not updated, when it gets selected.
                                  -- (But the ring can be updated before the ring_more dialog is opened.)
                                  -- Maybe refreshing the ring should be processed on the next defselect.
      nextfile
   enddo
   activatefile startfid
   return

; ---------------------------------------------------------------------------
defc RingWriteFileNumber
   call RingWriteFileNumber()

; ---------------------------------------------------------------------------
; Called by defproc GetInfoFieldValue('FILE').
defproc GetFileNumber
   universal EPM_utility_array_ID
   -- Get FileNumber for Filename by querying an array var
   getfileid fid
   rc = get_array_value( EPM_utility_array_ID, 'filenumber.'fid, FileNumber )
   return FileNumber

; ---------------------------------------------------------------------------
; Moved from STDCTRL.E
/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: Ring_More                                                ³
³                                                                            ³
³ what does it do : This command is called when the More... selection on     ³
³                   the ring menu is selected.  (Or by the Ring action bar   ³
³                   item if MENU_LIMIT = 0.)  It generates a listbox         ³
³                   containing all the filenames, and selects the            ³
³                   appropriate fileid if a filename is selected.            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc Ring_More
   if filesinring() = 1 then
      sayerror ONLY_FILE__MSG
      return
   endif
   call windowmessage( 0,  getpminfo(APP_HANDLE),
                       5141,               -- EPM_POPRINGDIALOG
                       0,
                       0)

; ---------------------------------------------------------------------------
; Syntax: Ring <cmd>
; Executes a cmd on all files of the ring.
defc Ring
   if arg(1) = '' then
      sayerror 'Specify a command to be executed on all files in the ring.'
      return
   endif
   display -3
   getfileid startfid
   do i = 1 to filesinring()  -- omit hidden files
      arg(1)  -- execute arg(1)
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo
   'postme activatefile' startfid
   'postme display' 3
   return

