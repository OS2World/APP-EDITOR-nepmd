/****************************** Module Header *******************************
*
* Module Name: tagsactn.e
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
   WANT_DYNAMIC_PROMPTS = 1
   WANT_TAGS = 1  -- Force definition of menu prompts in ENGLISH.E.
include 'stdconst.e'
include 'english.e'
include 'menuhelp.h'


; Here is the <file_name>_ACTIONLIST command that adds the action command
; to the list.

defc tagsactn_actionlist
   universal ActionsList_FileID  -- This is the fileid that gets the line(s)

   insertline 'tags_dialog'TAGSDLG_MENUP__MSG'tagsactn', ActionsList_FileID.last+1, ActionsList_FileID
   insertline 'find_cur_proc'FIND_TAG_MENUP__MSG'tagsactn', ActionsList_FileID.last+1, ActionsList_FileID
   insertline 'find_proc'FIND_TAG2_MENUP__MSG'tagsactn', ActionsList_FileID.last+1, ActionsList_FileID
   insertline 'tags_filename'TAGFILE_NAME_MENUP__MSG'tagsactn', ActionsList_FileID.last+1, ActionsList_FileID
   insertline 'make_tags_file'MAKE_TAGS_MENUP__MSG'tagsactn', ActionsList_FileID.last+1, ActionsList_FileID

defc tags_dialog
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'poptagsdlg'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror substr(TAGSDLG_MENUP__MSG,2)
      display 8
   elseif arg(1) = 'H' then   -- button Help
      'helpmenu' HP_SEARCH_TAGS
;; elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc find_cur_proc
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'findtag'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror substr(FIND_TAG_MENUP__MSG,2)
      display 8
   elseif arg(1) = 'H' then   -- button Help
      'helpmenu' HP_SEARCH_TAGS
;; elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc find_proc
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'findtag *'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror substr(FIND_TAG2_MENUP__MSG,2)
      display 8
   elseif arg(1) = 'H' then   -- button Help
      'helpmenu' HP_SEARCH_TAGS
;; elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc tags_filename
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'tagsfile'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror substr(TAGFILE_NAME_MENUP__MSG,2)
      display 8
   elseif arg(1) = 'H' then   -- button Help
      'helpmenu' HP_SEARCH_TAGS
   elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

defc make_tags_file
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      'maketags *'
   elseif arg(1) = 'I' then   -- button Initialized
      display -8
      sayerror substr(MAKE_TAGS_MENUP__MSG,2)
      display 8
   elseif arg(1) = 'H' then   -- button Help
      'helpmenu' HP_SEARCH_TAGS
;; elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

EA_comment 'This is a toolbar "actions" file which lets you set buttons for the TAGS-file commands.'
