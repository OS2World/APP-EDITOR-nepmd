/****************************** Module Header *******************************
*
* Module Name: wps.e
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

; Commands/procedures to communicate with the WPS

; ---------------------------------------------------------------------------
; Opens the location of the current file as a WPS folder.
; arg(1) = setup string for the folder.
; Notes for the current version:
;    -  Open.erx is needed.
;    -  The setup string will be passed to the REXX function
;       SysSetObjectData.
;    -  If no setup string is specified, the folder will open in it's
;       default view.
defc OpenFolder
   SetupString = strip( arg(1) )
   if SetupString = '' then
      SetupString = 'OPEN=DEFAULT'
   endif
   Dir = ''

   if IsAShell() then
      call psave_pos(save_pos)
      -- search (reverse) in command shell window for the prompt and
      -- retrieve the current directory
      -- goto previous prompt line
      ret = ShellGotoNextPrompt( 'P')
      ShellDir = ''
      Cmd = ''
      if not ret then
         call ShellParsePromptLine( ShellDir, Cmd)
      endif
      Dir = ShellDir
      call prestore_pos(save_pos)
   elseif subword( .filename, 1, 2) = '.DOS dir' then
      Dir = subword( .filename, 3)
   endif

   if Dir = '' then
      Filename = .filename
      -- Get Dir of Filename
      p = lastpos( '\', Filename)
      if p > 1 then
         Dir = substr( Filename, 1, p - 1)
      else
         Dir = Filename'\..'
      endif
   endif

   'rx open 'Dir','SetupString
   return

; ---------------------------------------------------------------------------
; Opens the location of the specified file as a WPS folder.
; arg(1) = filename
; Notes for the current version:
;    -  Open.erx is needed.
;    -  The setup string will be passed to the REXX function
;       SysSetObjectData.
;    -  If no filename is specified, the folder of the current filename
;       will open.
defc OpenFolderOf
   SetupString = 'OPEN=DEFAULT'
   Filename = arg(1)
   if leftstr( Filename, 1) = '"' & rightstr( Filename, 1) = '"' then
      Filename = substr( Filename, 2, length(Filename) - 2)
   endif
   if Filename = '' then
      Filename = .filename
   endif
   -- Get Dir of Filename
   p = lastpos( '\', Filename)
   if p > 1 then
      Dir = substr( Filename, 1, p - 1)
   else
      Dir = Filename'\..'
   endif
   'rx open 'Dir','SetupString
   return

; ---------------------------------------------------------------------------
; Opens the properties dialog of the specified object
; arg(1) = objectname or objectid
; Notes for the current version:
;    -  Open.erx is needed.
;    -  The setup string will be passed to the REXX function
;       SysSetObjectData.
;    -  If no objectname is specified, the properties dialog of the
;       current filename will open.
defc OpenSettings
   SetupString = 'OPEN=SETTINGS'
   Filename = arg(1)
   if leftstr( Filename, 1) = '"' & rightstr( Filename, 1) = '"' then
      Filename = substr( Filename, 2 length(Filename) - 2)
   endif
   if Filename = '' then
      Filename = .filename
   endif
   'rx open 'Filename','SetupString
   return

; ---------------------------------------------------------------------------
defproc GetProgramRSwitch
   Ret = '?'
   Next = RxResult( 'newsamewindow.erx query')
   if next <> '' then
      Ret = Next
   endif
   return Ret

; ---------------------------------------------------------------------------
defproc GetProgramOSwitch
   Ret = '?'
   Next = RxResult( 'fullfiledialog.erx query')
   if next <> '' then
      Ret = Next
   endif
   return Ret

; ---------------------------------------------------------------------------
; Opens a listbox to select an association action. The list of actions is
; parsed by ASSOCS.ERX from OBJECTS.INI. Uses also ASOOCS.ERX and OBJECTS.INI
; to execute an action.
defc SelectAssoc

   NumItems = 0
   ListBoxData = ''
   Next = RxResult( 'assocs.erx query')
   if Next <> '' then
      -- Get number of items
      Sep = leftstr( Next, 1)
      Check = translate( translate( Next, '_', ' '), ' ', Sep)
      NumItems = words( Check)
      ListBoxData = Next
   endif

   DefaultItem   = 1
   DefaultButton = 1
   HelpId = 0
   Title = 'Set or remove WPS associations'
   Text  = 'Select program object(s):'

   refresh
   Result = listbox( Title,
                     ListBoxData,
                     '/~Prepend/~Append/~Remove/Cancel',           -- buttons
                     0, 0,  --5, 5,           -- top, left,
                     min( NumItems, 15), 50,  -- height, width
                     gethwnd(APP_HANDLE) || atoi(DefaultItem) ||
                     atoi(DefaultButton) || atoi(HelpId) ||
                     Text\0 )
   refresh

   -- Check result
   Button = asc( leftstr( Result, 1))
   EOS = pos( \0, Result, 2)        -- CHR(0) signifies End Of String

   ListItem = substr( Result, 2, EOS - 2)

   if wordpos( Button, '1 2 3') > 0 then
      Action = word( 'PREPEND APPEND REMOVE', Button)
   else                    -- Cancel
      return 1
   endif
   'rx assocs.erx' Action ListItem

; ---------------------------------------------------------------------------
defc AssocsMsgBox
   parse arg ListItem'|'Action'|'Objects'|'Types'|'Filters

   Bul = \7
   Text = ''

   if Action = 'PREPEND' then
      verb = 'prepending'
   elseif Action = 'APPEND' then
      verb = 'appending'
   elseif Action = 'REMOVE' then
      verb = 'removing'
   else
      verb = '<unknown action>'
   endif
   Text = Text || 'Result of 'verb' associations for 'ListItem':'\n\n
   Text = Text || 'Changed objects:'\n
   rest = Objects
   do while rest <> ''
      parse value rest with next','rest
      if next = '' then
         iterate
      endif
      Text = Text || '       'Bul\9''next\n
   enddo
   Text = Text || \n

   Text = Text || 'Changed types:'\n
   rest = Types
   do while rest <> ''
      parse value rest with next','rest
      if next = '' then
         iterate
      endif
      Text = Text || '       'Bul\9''next\n
   enddo
   Text = Text || \n
   Text = Text || 'Changed filters:'\n
   rest = Filters
   do while rest <> ''
      parse value rest with next','rest
      if next = '' then
         iterate
      endif
      Text = Text || '       'Bul\9''next\n
   enddo

   Style = MB_OK+MB_INFORMATION+MB_MOVEABLE
   Title = 'Changed WPS associations'
   ret = winmessagebox( Title,
                        Text,
                        Style)

