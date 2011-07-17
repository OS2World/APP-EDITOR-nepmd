/****************************** Module Header *******************************
*
* Module Name: statline.e
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

const
compile if not defined(NEPMD_SPECIAL_STATUSLINE)
   NEPMD_SPECIAL_STATUSLINE = 1
compile endif
compile if not defined(NEPMD_MODIFIED_STATUSCOLOR)
   NEPMD_MODIFIED_STATUSCOLOR = LIGHT_GREYB + MAGENTA
compile endif
compile if defined(NEPMD_MODIFIED_STATUSCOLOR)
definit
   universal vNEPMD_MODIFIED_STATUSCOLOR
   vNEPMD_MODIFIED_STATUSCOLOR = NEPMD_MODIFIED_STATUSCOLOR
compile endif
const
compile if not defined(NEPMD_STATUSLINE_SEP)
   NEPMD_STATUSLINE_SEP = ' ú '
compile endif


; ---------------------------------------------------------------------
; refreshstatusline refreshes the statusline with the current values.
;
; This defc is required, if the statusbar template should contain
; non-standard tags (without a '%'). Then it doesn't suffice to set the
; universal var current_status_template or the const STATUS_TEMPLATE.
;
; Calling refreshstatusline as a defselect theoretically means a little
; overhead, comparing with the internal mechanism of the E toolkit.
;
; Currently it overwrites the setting made by STATUS_TEMPLATE.
;
; Known bug:
;    When selecting a file from the 'Files in Ring' listbox, the statusbar
;    is not refreshed. The refresh is only processed after the listbox
;    is closed.
;    Against this, the internal defined statusbar tags (all values with a '%')
;    are refreshed immediately.
;
; Todo:
;    Make the template configurable by the const STATUS_TEMPLATE by
;    adding some tag templates.
;
; %A   Autosave count value (number of changes made to the file since the last
;      autosave)
; %C   current Column number
; %F   number of Files in ring (followed by the word "File" or "Files")
; %I   Insert or replace state (cursor status)
; %L   current Line number
; %M   Modified status (if the file has been modified)
; %S   total number of lines in the current file
; %X   displays the hexadecimal value of the current character
; %Z   displays the ASCII value of the current character
;
; The default value if STATUS_TEMPLATE is not defined is:
; 'Line %l of %s Column %c  %i   %m   %f'
defc refreshstatusline
   if .visible then
      sep = (NEPMD_STATUSLINE_SEP)
      CurMode = NepmdGetMode()

;      current_status_template =  "Line %l of %s "sep" Col %c "sep" '%x'x = %z "sep" %f "sep" ma ".margins" "sep" " ||
;                                 "tabs "word(.tabs,1)" "sep" "CurMode" "sep" %m"
      current_status_template =  "Line %l of %s "sep" Col %c "sep" '%x'x/%z "sep" ma ".margins" "sep" " ||
                                 "tabs "word(.tabs,1)" "sep" %i "sep" "CurMode" "sep" %f"
;      current_status_template =  " %l of %s "sep" %c "sep" '%x'x = %z "sep" %f "sep" ma ".margins" "sep" " ||
;                                 "tabs "word(.tabs,1)" "sep" "CurMode" "sep" %m"

      'setstatusline 'current_status_template
   endif  -- .visible
   return


; ---------------------------------------------------------------------
; Moved defc setstatusline from STDCTRL.E to STATLINE.E
; Called with a string to set the statusline text to that string; with no argument
; to just set the statusline color.
defc setstatusline
   universal vSTATUSCOLOR, current_status_template
compile if defined(NEPMD_MODIFIED_STATUSCOLOR)
   universal vNEPMD_MODIFIED_STATUSCOLOR
   if .modify = 0 then
      newSTATUSCOLOR = vSTATUSCOLOR
   else
      newSTATUSCOLOR = vNEPMD_MODIFIED_STATUSCOLOR
   endif
compile else
   newSTATUSCOLOR = vSTATUSCOLOR
compile endif
   if arg(1) then
      current_status_template = arg(1)
      template=atoi(length(current_status_template)) || current_status_template
      template_ptr=put_in_buffer(template)
   else
      template_ptr=0
   endif
   call windowmessage( 1,  getpminfo(EPMINFO_EDITCLIENT),
                       5431,      -- EPM_FRAME_STATUSLINE
                       template_ptr,
                       newSTATUSCOLOR )
   return


; ---------------------------------------------------------------------
compile if NEPMD_SPECIAL_STATUSLINE
; on defload: refreshstatusline is called by NepmdProcessMode

defmodify
   'refreshstatusline'                      -- Update status line text and color

defselect
   'refreshstatusline'                             -- Update status line text and color
compile endif

; refreshstatusline is also called from:
; - defproc NepmdProcessMode  MODE.E
; - defc setconfig            STDCTRL.E
; - defc ma,margins           STDCMDS.E
; - defc tabs                 STDCMDS.E

