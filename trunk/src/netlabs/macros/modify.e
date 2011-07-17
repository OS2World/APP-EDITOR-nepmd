/****************************** Module Header *******************************
*
* Module Name: modify.e
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
;  MODIFY.E                                              Bryan Lewis 12/31/88
;
;  New in EPM.  This DEFMODIFY event is triggered when a file's number of
;  modifications (.modify):
;  -  goes from zero to nonzero (first modification, so we can change the
;     textcolor or title to indicate that the file needs to be saved;
;  -  goes from nonzero to zero (so we can return to the safe textcolor,
;     usually after a save);
;  -  goes from less than .autosave to greater than or equal to .autosave.
;
;
;  Note:  .modify does not always increase smoothly, one increment at a time.
;  For instance, changing a line and hitting Enter increases .modify by 2,
;  because it registers the change to the previous line as well as the new
;  line.  So we can't expect .modify to be exactly 1; we have to look for
;  a transition from zero to nonzero.
;
;  Note 2:  E will not retrigger this event while the event is in
;  progress, to protect against infinite recursion.  So if you make a lot
;  of changes to a file in the process of autosaving it, it won't get autosaved
;  twice.
;
;  We've provided three methods of showing the modified status.
;  1. The COLOR method changes the window color, for a very obvious indicator.
;  2. The FKTEXTCOLOR method changes the color of the bottom line of the
;     screen, for EOS2 only.
;  3. The TITLE method does one of two things.  For EOS2 it changes the color
;     of the filename.  For EPM it adds the string " (mod)" to the title bar.
;     This isn't as obvious as COLOR, but you can check it even when the file
;     is shrunk to an icon by clicking on the icon.
;
;  You, the macro writer, can add to or replace this behavior.
;  1. You can write defmodify procedures anywhere in your MYSTUFF.E or
;     MYKEYS.E files.  All defmodify procedures will be executed in sequence,
;     just as definit preocedures are.  The pieces can be anywhere.
;  2. Or you can write a DEFMODIFY event in a linked module, and it will
;     replace this one entirely.  For example, create a file NEWMOD.E with
;     your defmodify proc; compile it separately (ETPM NEWMOD); add a link
;     statement (link 'newmod') to your MYKEYS.E or MYSTUFF.E file.

; ---------------------------------------------------------------------------
defc DiscardChanges
   .modify = 0

; ---------------------------------------------------------------------------
; Not used. Was added for a test in INFOLINE.E.
; Can be used to disable defmodify processing. Since defmodify code is used
; at several places, the execution of the defmodify code has also be checked
; for this universal var at all these places to disable them all.
;defc DisableModify
;   universal ModifyDisabled
;   ModifyDisabled = 1
;
; ---------------------------------------------------------------------------
;defc EnableModify
;   universal ModifyDisabled
;   ModifyDisabled = 0
;
; ---------------------------------------------------------------------------
; defmodify is triggered
;    1)  when .modify changes from 0 to > 0
;    2)  when .modify changes from < .autosave to >= .autosave
;    3)  when .modify changes from > 0 to 0
;    4)  when a modified file is selected after a non-modified file
;    5)  when a non-modified file is selected after a modified file
defmodify
;   universal ModifyDisabled
;
;   if ModifyDisabled <> 1 then
      -- Do autosave on case 2)
      if .autosave and .modify >= .autosave then
         rcx = MakeAutoSave()
      endif

      -- Execute user macros
compile if INCLUDE_BMS_SUPPORT
      if isadefproc('BMS_defmodify_exit') then
         call BMS_defmodify_exit()
      endif
compile endif
      'HookExecute modify'
      'HookExecuteOnce modifyonce'

;      -- Reenable defmodify event delayed
;      'postme EnableModify'
;   endif


; Other used defmodifies, so far:
; FILE.E       -  lock on modify
; INFOLINE.E   -  show datetime or 'Modified', change color of statusline text
; EPMSHELL.E   -  reset modify for EPM shells to avoid the internal modified
;                 dialog on quit


