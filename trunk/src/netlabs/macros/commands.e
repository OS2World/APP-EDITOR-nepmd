include 'stdconst.e'

const
   HELP_TITLE    = 'Actions from "COMMANDS"'
   OS2FS_PROMPT  = 'Start an OS/2 fullscreen command session'
   OS2WIN_PROMPT = 'Start an OS/2 windowed command session'
   DOSFS_PROMPT  = 'Start a DOS fullscreen command session'
   DOSWIN_PROMPT = 'Start a DOS windowed command session'
   WINOS2_PROMPT = 'Start an OS/2 fullscreen command session'

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
   elseif arg(1) = 'I' then
     display -8
     sayerror OS2FS_PROMPT
     display 8
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, OS2FS_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_os2win
   if arg(1) = 'S' then
      'start /win'
   elseif arg(1) = 'I' then
     display -8
     sayerror OS2WIN_PROMPT
     display 8
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, OS2WIN_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_dosfs
   if arg(1) = 'S' then
      'start /dos /fs'
   elseif arg(1) = 'I' then
     display -8
     sayerror DOSFS_PROMPT
     display 8
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, DOSFS_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_doswin
   if arg(1) = 'S' then
      'start /dos /win'
   elseif arg(1) = 'I' then
     display -8
     sayerror DOSWIN_PROMPT
     display 8
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, DOSWIN_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

defc cmd_winos2fs
   if arg(1) = 'S' then
      'start /fs /dos /c winos2'
   elseif arg(1) = 'I' then
     display -8
     sayerror WINOS2_PROMPT
     display 8
   elseif arg(1) = 'H' then
;    'helpmenu 5390'
      call winmessagebox(HELP_TITLE, WINOS2_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   endif

EA_comment 'This is a toolbar "actions" file which defines commands for starting OS/2 or DOS sessions.'
