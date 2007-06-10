/****************************** Module Header *******************************
*
* Module Name: revert.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: revert.e,v 1.6 2007-06-10 19:58:29 aschn Exp $
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

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
   include 'stdconst.e'
define INCLUDING_FILE = 'REVERT.E'
const
   tryinclude 'MYCNF.E'        -- The user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'

defmain
   'revert'
compile endif  -- not defined(SMALL)


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
   'DisableLoad'
   'DisableSelect'
   getfileid startfid
   call psave_pos(saved_pos)
   if .lockhandle then
      'unlock'
   endif
;   display -8
   Mode = GetMode()
   if Mode = 'BIN' then
      Filename = .filename
      --sayerror 'o ''be "'Filename'"'''
      --'o ''be "'Filename'"'''
      'o ''mc /be 'Filename' /postme restorepos 'saved_pos''
      if rc = 0 then
         activatefile startfid
         .modify = 0
         'quit'
         return
      endif
   else
      'e /d ='            -- /D means load from disk even if in ring.
   endif
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
   'EnableLoad'
   'EnableSelect'
;   display 8

