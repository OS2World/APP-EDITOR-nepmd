/****************************** Module Header *******************************
*
* Module Name: stylebut.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stylebut.e,v 1.3 2002-08-21 11:54:18 aschn Exp $
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
;    stylebut
; to indicate that this should be invoked to build the list of defined
; actions when the user asks for a list.

include 'stdconst.e'
include 'english.e'

; Next, define some additional text constants (defined as separate constants
; instead of using the strings where needed in order to allow for easier NLS
; translation).

const
   STYLEBUT__MSG        = 'Apply_style'
   STYLEBUT_PROMPT      = 'Apply a style to marked text, or entire file.'
   STYLEBUT2_PROMPT     = 'A style may be passed as a parameter, or will be prompted for otherwise.'
   STYLEBUT_PROMPT__MSG = 'Select a style to apply.'
   UNKNOWN_STYLE__MSG   = 'Unknown style'
   NO_STYLES__MSG       = 'No styles saved.'
   APPLY__MSG           = '~Apply'
   UNSTYLE__MSG    = 'Remove style'  -- Messagebox Title
   UNSTYLE_PROMPT  = 'Remove a style from text pointed at by cursor'
   NO_STYLE__MSG   = 'No font set around cursor position'

; Here is the <file_name>_ACTIONLIST command that adds the action command
; to the list.

defc stylebut_actionlist
   universal ActionsList_FileID    -- This is the fileid that gets the line(s)
   insertline 'apply_style'STYLEBUT_PROMPT'  'STYLEBUT2_PROMPT'stylebut', ActionsList_FileID.last+1, ActionsList_FileID
   insertline 'remove_style'UNSTYLE_PROMPT'stylebut', ActionsList_FileID.last+1, ActionsList_FileID

; These are the command that will be called for the above actions.

defc apply_style
   universal appname, app_hini
   parse arg arg1 stylename
   if arg1 = 'S' then       -- button Selected
      sayerror 0
      getfileid fid
      mt = marktype()
      if mt then
         getmark l1, l2, c1, c2, markfid
         if fid<>markfid then
            sayerror OTHER_FILE_MARKED__MSG
            return
         endif
      endif
      if stylename = '' then          -- Provide list of styles
         App = 'Style'\0
         inidata = copies(' ', MAXCOL)
         retlen = \0\0\0\0
         l = dynalink32('PMSHAPI',
                        '#115', -- 'PRF32QUERYPROFILESTRING',
                        atol(app_hini)    ||  -- HINI_PROFILE
                        address(App)      ||  -- pointer to application name
                        atol(0)           ||  -- Key name is NULL; returns all keys
                        atol(0)           ||  -- Default return string is NULL
                        address(inidata)  ||  -- pointer to returned string buffer
                        atol(MAXCOL)      ||       -- max length of returned string
                        address(retlen), 2)         -- length of returned string

         if not l then
            sayerror NO_STYLES__MSG
            'fontlist'
            return
         endif
         inidata = strip(inidata, 'T')
         if rightstr(inidata, 2) = \0\0 then
            inidata = leftstr(inidata, length(inidata)-1)
         else  -- Was too long; just show whole strings
            inidata = leftstr(inidata, lastpos(\0, inidata))
         endif
         inidata = \1 || translate(strip(inidata, 'T'), \1, \0)  -- Change nulls to ASCII 1's for listbox delimiter.
         parse value listbox(STYLEBUT__MSG,
                             inidata,
                             '/'APPLY__MSG'/'Cancel__MSG,1,5,min(count(\1, inidata)-1,12),0,
                             gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(0) ||
                             STYLEBUT_PROMPT__MSG) with button 2 stylename \0
         if button <> \1 then
            return
         endif
      else
         stylestuff = queryprofile(app_hini, 'Style', stylename)
         if stylestuff='' then
            sayerror UNKNOWN_STYLE__MSG '"'stylename'"'
            return
         endif
      endif  /* stylename passed as arg */
      if not mt then
         call pset_mark(1, .last, 1, length(textline(.last)), 'CHAR' , fid)
      endif
      'process_style' stylename
      if not mt then
         unmark
      endif
   elseif arg1 = 'I' then   -- button Initialized
      display -8
      sayerror STYLEBUT_PROMPT
      display 8
   elseif arg1 = 'H' then   -- button Help
;     'compiler_help_add stylebut.hlp' -- Sample code; no .hlp file is
;     'helpmenu 32100'                 -- provided for STYLEBUT.
                                       -- Instead, we'll just pop a messagebox containing the prompt.
      call winmessagebox(STYLEBUT__MSG, STYLEBUT_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif arg1 = 'E' then   -- button End
;;    sayerror 0
   endif

const
   COLOR_CLASS = 1
   BOOKMARK_CLASS = 13
   STYLE_CLASS =  14
   FONT_CLASS =  16

defc remove_style  -- Based on code from Toby Thurston
                   -- Enhanced to remove Color & Style attributes as well as Font.
   parse arg arg1 .
   if arg1 = 'S' then       -- button Selected
     class = FONT_CLASS
     offst1 = 0
     col1 = .col
     line1 = .line
     attribute_action FIND_PREV_ATTR_SUBOP, class, offst1, col1, line1
     if not class then      -- No font, maybe color?
        class = COLOR_CLASS
        attribute_action FIND_PREV_ATTR_SUBOP, class, offst1, col1, line1
     endif
     if class then          -- Found one...
        offst2 = offst1
        col2 = col1
        line2 = line1
        saveclass = class
        attribute_action FIND_MATCH_ATTR_SUBOP, class, offst2, col2, line2
        ll = 256            -- arbitary large line length factor
        if class &          -- if found a font and...
          (line1 * ll + col1) <= (.line * ll + .col) & -- 1st attr before cursor
          (line2 * ll + col2) >= (.line * ll + .col)   -- 2nd attr after cursor
        then                -- Found a match around cursor so delete them
          attribute_action DELETE_ATTR_SUBOP, class, offst1, col1, line1
          attribute_action DELETE_ATTR_SUBOP, class, offst2, col2, line2
          if offst1 = -2 & offst2 = -2 then
             offst1 = -1; offst2 = -1
          endif
          if saveclass=FONT_CLASS then  -- See if there's a color around it.
             removestyle_delete(COLOR_CLASS, offst1, col1, line1, offst2, col2, line2)
          endif
          removestyle_delete(STYLE_CLASS, offst1, col1, line1, offst2, col2, line2)
        else
           sayerror NO_STYLE__MSG
        endif
     else
        sayerror NO_STYLE__MSG
     endif
   elseif arg1 = 'I' then   -- button Initialized
      display -8
      sayerror UNSTYLE_PROMPT
      display 8
   elseif arg1 = 'H' then   -- button Help
      call winmessagebox(UNSTYLE__MSG, UNSTYLE_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
;  elseif arg1 = 'E' then   -- button End
;;    sayerror 0
   endif

defproc removestyle_delete(x_CLASS, offst1, col1, line1, offst2, col2, line2)
   query_attribute class, val, IsPush, offst1, col1, line1
   if class=x_CLASS & IsPush then
      offst3 = offst1
      col3 = col1
      line3 = line1
      attribute_action FIND_MATCH_ATTR_SUBOP, class, offst3, col3, line3
      if class & offst3=offst2 & col3=col2 & line3=line2 then
         attribute_action DELETE_ATTR_SUBOP, class, offst1, col1, line1
         attribute_action DELETE_ATTR_SUBOP, class, offst2, col2, line2
      endif
   endif

EA_comment 'This is a toolbar "actions" file which defines a command for a Style button.'
