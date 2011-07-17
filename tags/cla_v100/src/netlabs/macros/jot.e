/****************************** Module Header *******************************
*
* Module Name: jot.e
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
; This is a Toolbar Actions file.  You add a line to your ACTIONS.LST:
;    jot
; to indicate that this should be invoked to build the list of defined
; actions when the user asks for a list (by selecting Create or Edit
; from the toolbar pop-up menu and clicking on the drop-down arrow
; on the Actions page).  EPM loads this .ex file and executes the
; command JOT_ACTIONLIST (it appends "_ACTIONLIST" to the name of the
; .ex file).  This command must be defined by the actions file to add
; a line to a file for each toolbar-definable action defined in the .ex
; file.  (This file only defines a single action.)

; The line consists of the command to be executed, a description of the
; action, and the name of the .ex file, each separated by a delimiter
; (which is the first character on the line, and can be any character
; otherwise unused on that line; below, a period is used throughout).

; The action command (below, "jot_a_note") may be called with a parameter
; of "I" to indicate that the menu has been initialized (the user pressed
; MB1 down over the toolbar item, or pressed MB1 down over another toolbar
; item and dragged the mouse over this item, or pressed F10 to go to the
; action bar and scrolled to this toolbar item), "E" for a menu-end message,
; "H" for Help (user pressed F1), or "S" to indicate that the toolbar item
; has been selected.  The parameter might be followed by command parameters
; if the user entered any in the Parameters field of the Actions page.

; Now, the executable portions of the file.  First, include some files to
; define constants that will be needed:

include 'stdconst.e'
include 'english.e'

; Next, define some additional text constants (defined as separate constants
; instead of using the strings where needed in order to allow for easier NLS
; translation).

const
   JOT__MSG = 'Jot'
   JOT_PROMPT = 'Jot a line of text to a note file.'
   JOT_PROMPT__MSG = 'Enter text to jot, or filename for Change File'
   CHANGE_FILE__MSG = 'Change file'
   EDIT_FILE__MSG = 'Edit file'

; Here is the <file_name>_ACTIONLIST command that adds the action command
; to the list.

defc jot_actionlist
universal ActionsList_FileID  -- This is the fileid that gets the line(s)

insertline '|jot_a_note|'JOT_PROMPT'|jot|', ActionsList_FileID.last+1, ActionsList_FileID

; This is the command that will be called for the above action.  It
; doesn't expect parameters, so the argument is not parsed.

defc jot_a_note
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'jot'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror JOT_PROMPT
      display 8
   elseif arg(1) = 'H' then   -- button Help
;     'compiler_help_add jot.hlp'      -- Sample code; no .hlp file is
;     'helpmenu 32100'                 -- provided for JOT.
                                       -- Instead, we'll just pop a messagebox containing the prompt.
      call winmessagebox(JOT__MSG, JOT_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

; the Jot command is defined separately, but it could have been included
; under the 'S' case in the actions command.

defc jot
   universal appname, app_hini
   jotfile = queryprofile(app_hini, appname, 'JotFile')
   if jotfile='' then
      inifile = queryprofile(0, appname, 'EPMIniPath')
      jotfile = leftstr(inifile, lastpos('\', inifile)) || 'jot.not'
      if leftstr(jotfile,1)='\' then  -- relative to boot drive
         drivenum = 1234
         call dynalink32('DOSCALLS',          -- dynamic link library name
                         '#348',              -- ordinal for DOS32QuerySysInfo
                         atol(5)          ||  -- Start index (QSV_BOOT_DRIVE)
                         atol(5)          ||  -- End index (QSV_BOOT_DRIVE)
                         address(drivenum)||  -- buffer
                         atol(4),2)           -- Buffer length
         jotfile = chr(96+ltoa(drivenum, 10))':'jotfile
      endif
   endif

   parse value entrybox(JOT__MSG '-' jotfile,'/'OK__MSG'/'CHANGE_FILE__MSG'/'EDIT_FILE__MSG'/'Cancel__MSG'/'Help__MSG'/',\0,'',1590,
          atoi(1) || atoi(0) || atol(0) ||
          JOT_PROMPT__MSG) with button 2 rest \0
   if button = \1 then       -- OK; write note to file
      jotfile = jotfile\0
      rest = rest\13\10\0
      call windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                         5495,               -- EPM_EDIT_LOGERROR
                         ltoa(offset(jotfile) || selector(jotfile), 10),
                         ltoa(offset(rest) || selector(rest), 10) )
   elseif button = \2 then   -- Change file
      if rest='' then
         sayerror 'New name not entered, nothing changed.'
      else
         call setprofile(app_hini, appname, 'JotFile', rest)
         sayerror 'Jot file changed to "'rest'"'
      endif
   elseif button = \3 then   -- Edit file
      'e' jotfile
   endif


EA_comment 'This defines the JOT command; it can be linked, or can be executed directly.  This is also a toolbar "actions" file.'
