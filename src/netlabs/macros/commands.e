/****************************** Module Header *******************************
*
* Module Name: commands.e
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
include 'stdconst.e'

const
   HELP_TITLE    = 'Actions from "COMMANDS"'
   OS2FS_PROMPT  = 'Start an OS/2 fullscreen command session'
   OS2WIN_PROMPT = 'Start an OS/2 windowed command session'
   DOSFS_PROMPT  = 'Start a DOS fullscreen command session'
   DOSWIN_PROMPT = 'Start a DOS windowed command session'
   WINOS2_PROMPT = 'Start a Win16 fullscreen session'

defc commands_actionlist
universal ActionsList_FileID

insertline '.cmd_os2fs.'OS2FS_PROMPT'.commands.', ActionsList_FileID.last+1, ActionsList_FileID
insertline '.cmd_os2win.'OS2WIN_PROMPT'.commands.', ActionsList_FileID.last+1, ActionsList_FileID
insertline '.cmd_dosfs.'DOSFS_PROMPT'.commands.', ActionsList_FileID.last+1, ActionsList_FileID
insertline '.cmd_doswin.'DOSWIN_PROMPT'.commands.', ActionsList_FileID.last+1, ActionsList_FileID
insertline '.cmd_winos2fs.'WINOS2_PROMPT'.commands.', ActionsList_FileID.last+1, ActionsList_FileID

defc cmd_os2fs
   if arg(1) = 'S' then
      'start /fs'
      --'start /fs %comspec%'  -- That requires 2 exit commands to close it
   elseif arg(1) = 'I' then
     'SayHint' OS2FS_PROMPT
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, OS2FS_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_os2win
   if arg(1) = 'S' then
      'start /win'
      --'start /win %comspec%'  -- That requires 2 exit commands to close it
   elseif arg(1) = 'I' then
     'SayHint' OS2WIN_PROMPT
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, OS2WIN_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_dosfs
   if arg(1) = 'S' then
      'start /dos /fs'
   elseif arg(1) = 'I' then
     'SayHint' DOSFS_PROMPT
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, DOSFS_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_doswin
   if arg(1) = 'S' then
      'start /dos /win'
   elseif arg(1) = 'I' then
     'SayHint' DOSWIN_PROMPT
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, DOSWIN_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_winos2fs
   if arg(1) = 'S' then
      'start /fs /dos /c winos2'
   elseif arg(1) = 'I' then
     'SayHint' WINOS2_PROMPT
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, WINOS2_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

EA_comment 'This is a toolbar "actions" file which defines commands for starting OS/2 or DOS sessions.'
