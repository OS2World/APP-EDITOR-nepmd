/****************************** Module Header *******************************
*
* Module Name: revert.e
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

;   Revert to saved - throw away changes and reload from disk.

; The following command will throw away any changes made to a file since
; the last time it was loaded from disk, and reload the saved copy.  It
; does nothing if the file doesn't exist on disk.

;    by Larry Margolis

; Changed:
;    o  Added restoring position
;    o  Added switching off display updates

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
      if askyesno('Throw away changes to' .filename'?')<>'Y' then
         return -293  -- sayerror("has been modified")
      endif
   endif
   getfileid startfid
   call psave_pos(saved_pos)
   display -8
   'e /d ='            -- /D means load from disk even if in ring.
   getfileid newfid    -- Remember the new fileid.
   if rc = sayerror("new file") then  -- (Host) File not found
      'quit'                        -- Don't throw away what we had.
   elseif newfid<>startfid then     -- If we got something new...
         activatefile startfid
         .modify = 0
         'quit'
         activatefile newfid
         call prestore_pos(saved_pos)
   endif
   display 8

