/****************************** Module Header *******************************
*
* Module Name: revert.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: revert.e,v 1.2 2004-02-29 19:46:27 aschn Exp $
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

;   Revert to saved - throw away changes and reload from disk.

; The following command will throw away any changes made to a file since
; the last time it was loaded from disk, and reload the saved copy.  It
; does nothing if the file doesn't exist on disk.

;    by Larry Margolis

; Changed:
;    o  Added restoring position
;    o  Changed the msg box

; Todo:
;    o  Make reload undo-able

compile if not defined(HOST_SUPPORT)  -- if compiled separately
   tryinclude 'mycnf.e'
 compile if not defined(HOST_SUPPORT)
   const
      HOST_SUPPORT = 'STD'
 compile endif

defmain
   'revert'
compile endif

defc revert =
compile if HOST_SUPPORT
   if not exist(.filename) & not check_for_host_file(.filename) then
compile else
   if not exist(.filename) then
compile endif
      sayerror .filename 'does not exist on disk; nothing to revert to.'
      return sayerror("File not found")
   endif
   if .modify then
      if WinMessageBox( 'Revert - reload file from disk',
                        .filename' was modified.'\13 ||
                        'Throw away changes to file on disk?',
                        MB_OKCANCEL + MB_WARNING + MB_DEFBUTTON1 + MB_MOVEABLE) <> MBID_OK then
         return -293  -- sayerror("has been modified")
      endif
   endif
   getfileid startfid
   call psave_pos(saved_pos)
;   display -8
   'e /d ='            -- /D means load from disk even if in ring.
   getfileid newfid    -- Remember the new fileid.
   if rc = sayerror("new file") then  -- (Host) File not found
      'quit'                        -- Don't throw away what we had.
   elseif newfid<>startfid then     -- If we got something new...
         activatefile startfid
         .modify = 0
         'quit'
         activatefile newfid
         --call prestore_pos(saved_pos)
         'postme restorepos 'saved_pos  -- postme required
   endif
;   display 8

