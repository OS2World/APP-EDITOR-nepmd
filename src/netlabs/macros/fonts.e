/****************************** Module Header *******************************
*
* Module Name: fonts.e
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
include 'english.e'

const
   ADD_FONT_ATTRIB_TITLE = 'Add font attribute'
   ATTRIBS_PROMPT = 'Pull-down menu for adding font attributes to marked text.'
   BOLD_PROMPT = 'Add the Bold attribute to marked text.'
   ITALIC_PROMPT = 'Add the Italic attribute to marked text.'
   UNDERLINE_PROMPT = 'Add the Underline attribute to marked text.'
   OUTLINE_PROMPT = 'Add the Outline attribute to marked text.'
   STRIKEOUT_PROMPT = 'Add the Strikeout attribute to marked text.'
   BLOCKMARK_ONE_LINE__MSG =   'Block marks must begin and end on the same line.'
   ATTRIBUTE_ON__MSG = 'Attribute is already on.'

   COLOR_CLASS = 1
   BOOKMARK_CLASS = 13
   STYLE_CLASS =  14
   FONT_CLASS =  16

   Italic_ATTRIB     = 1
   Underscore_ATTRIB = 2
   Outline_ATTRIB    = 8
   Strikeout_ATTRIB  = 16
   Bold_ATTRIB       = 32


defc fonts_actionlist
   universal ActionsList_FileID  -- This is the fileid that gets the line(s)
   insertline '|fonts_bold|'BOLD_PROMPT'|fonts|', ActionsList_FileID.last+1, ActionsList_FileID
   insertline '|fonts_italic|'ITALIC_PROMPT'|fonts|', ActionsList_FileID.last+1, ActionsList_FileID
   insertline '|fonts_underline|'UNDERLINE_PROMPT'|fonts|', ActionsList_FileID.last+1, ActionsList_FileID
   insertline '|fonts_outline|'OUTLINE_PROMPT'|fonts|', ActionsList_FileID.last+1, ActionsList_FileID
   insertline '|fonts_strikeout|'STRIKEOUT_PROMPT'|fonts|', ActionsList_FileID.last+1, ActionsList_FileID

defc fonts_attribs
   fonts_common_action(arg(1), '', ATTRIBS_PROMPT)
defc fonts_bold
   fonts_common_action(arg(1), 'add_font_attrib' Bold_ATTRIB, BOLD_PROMPT)
defc fonts_italic
   fonts_common_action(arg(1), 'add_font_attrib' Italic_ATTRIB, ITALIC_PROMPT)
defc fonts_underline
   fonts_common_action(arg(1), 'add_font_attrib' Underscore_ATTRIB, UNDERLINE_PROMPT)
defc fonts_outline
   fonts_common_action(arg(1), 'add_font_attrib' Outline_ATTRIB, OUTLINE_PROMPT)
defc fonts_strikeout
   fonts_common_action(arg(1), 'add_font_attrib' Strikeout_ATTRIB, STRIKEOUT_PROMPT)


defproc fonts_common_action(arg1, command, prompt)
   parse value arg1 with action_letter parms
   if action_letter = 'I' then       -- button Initialized
      display -8
      sayerror prompt
      display 8
   elseif action_letter = 'S' then   -- button Selected
      sayerror 0
      command
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(add_font_attrib_title, prompt, MB_OK + MB_INFORMATION + MB_MOVEABLE)
;; elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

defc add_font_attrib
   mt = marktype()
   if mt='' then
      sayerror -280  -- Text not marked
      return
   endif
   getmark firstline, lastline, firstcol, lastcol, markfileid
   getfileid fileid
   if fileid<>markfileid then
      sayerror OTHER_FILE_MARKED__MSG
      return
   endif
   if leftstr(mt, 1) = 'B' & firstline<>lastline then
      sayerror BLOCKMARK_ONE_LINE__MSG
      return
   endif
   if leftstr(mt, 1) = 'L' then
      lastcol = length(textline(lastline))
   endif
   parse arg attrib .
   line=firstline; col=firstcol; offst=0
   class = FONT_CLASS
   attribute_action FIND_RULING_ATTR_SUBOP, class, offst, col, line
   if class=0 then
      font = .font
   else
      query_attribute class, font, IsPush, offst, col, line
   endif
   parse value queryfont(font) with fontname '.' fontsize '.' fontattrib
   if fontattrib bitand attrib then
      if class & line=firstline & col=firstcol then
         offst2 = offst
         attribute_action FIND_MATCH_ATTR_SUBOP, class, offst2, col, line
         lc1 = lastcol+1
         if class & line=lastline & col=lc1 then  -- Beginning & end matches; this is a toggle off.
            offst1 = offst + 1
            attribute_action DELETE_ATTR_SUBOP, class, offst, firstcol, firstline
            attribute_action DELETE_ATTR_SUBOP, class, offst2, lc1, lastline
            if fontattrib = attrib then  -- That was the only attribute set:
;                We've deleted the ruling attribute; now find the next outer one.
               line=firstline; col=firstcol; offst=0
               attribute_action FIND_RULING_ATTR_SUBOP, class, offst, col, line
               if class=0 then
                  font = .font
               else
                  query_attribute class, font, IsPush, offst, col, line
               endif
               parse value queryfont(font) with fontname '.' fontsize '.' fontattrib
               if not (fontattrib bitand attrib) then  -- Already off?
                  return                                            -- then all done.
               endif
            endif
;                We have to insert new attributes with the specified bit *off*.
            newfont = registerfont(fontname, fontsize, fontattrib - attrib)
            if not offst1 then
               lastcol = lc1
            endif
            insert_attribute FONT_CLASS, newfont, 1, offst1, firstcol, firstline
            insert_attribute FONT_CLASS, newfont, 0, -offst1, lastcol, lastline
            return
         else
         endif
      endif
      sayerror ATTRIBUTE_ON__MSG
      return
   endif
   newfont = registerfont(fontname, fontsize, fontattrib + attrib)
   Insert_Attribute_Pair(FONT_CLASS, newfont, firstline, lastline, firstcol, lastcol, fileid)
   call attribute_on(4)  -- Mixed fonts flag
   call attribute_on(8)  -- "Save attributes" flag


