/****************************** Module Header *******************************
*
* Module Name: reflow.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: reflow.e,v 1.1 2002-08-09 16:24:52 aschn Exp $
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
;Source: http://groups.google.com/groups?q=reflow+margolis&hl=en&rnum=3&selm=5ebbc3%24g98%241%40news-s01.ca.us.ibm.net

include 'stdconst.e'
include 'english.e'

const
   reflow2window_prompt = 'Do a WYSIWYG reflow to window width'
   reflow2size_prompt =   'Do a WYSIWYG reflow to a specific width'
   reflow2size_prompt2 =  '(provided as the parameter).  Default unit is pels.'
   reflow_prompt_prompt = 'Do a WYSIWYG reflow, prompting for width'

defc reflow_actionlist
universal ActionsList_FileID

insertline '|reflow2window|'reflow2window_prompt'|reflow|', ActionsList_FileID.last+1, ActionsList_FileID
insertline '|reflow2size|'reflow2size_prompt||reflow2size_prompt2'|reflow|', ActionsList_FileID.last+1, ActionsList_FileID
insertline '|reflow_prompt|'reflow_prompt_prompt'|reflow|', ActionsList_FileID.last+1, ActionsList_FileID

defc reflow2window
   if arg(1) = 'S' then
      sayerror 0
      'reflow'
   elseif arg(1) = 'I' then
      display -8
      sayerror reflow2window_prompt
      display 8
   elseif arg(1) = 'H' then
      'compiler_help_add REFLOW.hlp'
      'helpmenu 32100'
   endif

defc reflow2size
   parse arg arg1 rest
   if arg1 = 'S' then
      'reflow' rest
   elseif arg1 = 'I' then
      display -8
      sayerror reflow2size_prompt
      display 8
   elseif arg1 = 'H' then
      'compiler_help_add REFLOW.hlp'
      'helpmenu 32100'
   endif

defc reflow_prompt
   if arg(1) = 'S' then
      'reflow *'
   elseif arg(1) = 'I' then
      display -8
      sayerror 'Do a WYSIWYG reflow, prompting for width'
      display 8
   elseif arg(1) = 'H' then
      'compiler_help_add REFLOW.hlp'
      'helpmenu 32100'
   endif

defmain
   'reflow' arg(1)

const
   map_WindowToDoc = 1  -- x, y    in; x, y    out
   map_DocToLCO    = 2  -- x, y    in; l, c, o out
   map_LCOToDoc    = 3  -- l, c, o in; x, y    out
   map_Doc2Win     = 4  -- x, y    in; x, y    out
   map_Win2LCO     = 5  -- x, y    in; l, c, o out
   map_LCO2Win     = 6  -- l, c, o in; x, y    out

defc reflow =
   universal last_reflow_width
   par_width = arg(1)
   units_width = ''
   if par_width = '=' then
      par_width = last_reflow_width
   endif
   if par_width='*' then
      'compiler_help_add REFLOW.hlp'  -- Have to make sure help file is loaded, just in case...
      parse value entrybox('Paragraph width','/'OK__MSG'/'Cancel__MSG'/'Help__MSG'/',last_reflow_width,'',200,
             atoi(1) || atoi(32101) || gethwndc(APP_HANDLE) ||
             'Enter a width; leave blank to reflow to window.') with button 2 par_width \0
      if button<>\1 then return; endif
   endif
   save_width = par_width  -- Save original units
   if par_width='' then
compile if EPM32
      swp1 = copies(\0, 36)
      call dynalink32('PMWIN',
                      '#837',
                      gethwndc(EPMINFO_EDITCLIENT)  ||
                      address(swp1) )
      par_width = ltoa(substr(swp1,9,4),10)
compile else
      swp1 = copies(\0,18)
      call dynalink('PMWIN',
                    'WINQUERYWINDOWPOS',
                     gethwnd(EPMINFO_EDITCLIENT)  ||
                     address(swp1) )
      par_width = itoa(substr(swp1,5,2),10)
compile endif
;     sayerror 'width =' par_width 'pels'
   elseif isnum(par_width) then
      -- nop
   else
      units_width = par_width'='
      y = verify(par_width, '0123456789. ')
      x = leftstr(par_width, y-1)
      if not isnum(x) then
         sayerror -263 -- 'Invalid argument'
         return
      endif
      y = upcase(substr(par_width, y))
      out_array = copies(\0, 4)  -- reserve space for 1 long
compile if EPM32
      call dynalink32('PMGPI',
                    '#606', -- Dev32QueryCaps
                     atol(dynalink32('PMWIN', '#835' /*Win32QueryWindowDC*/, gethwndc(EPMINFO_EDITCLIENT), 2)) ||
                     atol(8)          ||  -- start = 8 (horizontal resolution)
                     atol(1)          ||  -- count = 1
                     address(out_array) )
compile else
      call dynalink('PMGPI',
                    'DEVQUERYCAPS',
                     atol_swap(dynalink('PMWIN', 'WINQUERYWINDOWDC', gethwnd(EPMINFO_EDITCLIENT), 2)) ||
                     atol_swap(8)          ||  -- start = 8 (horizontal resolution)
                     atol_swap(1)          ||  -- count = 1
                     address(out_array) )
compile endif
      h = ltoa(out_array, 10)  -- Horizontal res. in pels / meter
      if abbrev('INCHES', y, 1) then
         par_width = x * h * .0254
      elseif abbrev('FOOT', y, 1) | abbrev('FEET', y, 1) then
         par_width = x * h * .3048
      elseif abbrev('METERS', y, 1) then
         par_width = x * h
      elseif y='CM' | abbrev('CENTIMETERS', y, 1) then
         par_width = x * h / 100
      elseif y='MM' | abbrev('MILLIMETERS', y, 2) then
         par_width = x * h / 1000
      else
         sayerror 'Unrecognized unit:  'y
         return
      endif
      sayerror arg(1) '=' par_width 'pels (there are' h 'pels / meter)'
      parse value (par_width + 0.5) with par_width '.'  -- round
   endif
   oldmargins = .margins
   .margins = "1 1599 1"
   x = .line; y = MAXMARGIN
   map_point map_LCOToDoc, x, y                -- Get y position of current line.
   if par_width > x then
      sayerror 'Reflow:  'units_width || par_width 'pels is too wide!  Max is' x 'pels = column' MAXMARGIN
      return
   endif
   if arg(1)<>'' then  -- If not using windowwidth, save width for next time.
      last_reflow_width = save_width
   endif
   display -1
   start_col = .col
   do forever
      x = .line; y = 1
;sayerror 'line' .line':  Before map 1, line='x'; col='y
      map_point map_LCOToDoc, x, y                -- Get y position of current line.
;sayerror 'line' .line':  After map 1, x='x'; y='y
      x = par_width
      y = y + 5
;sayerror 'line' .line':  Before map 2, x='x'; y='y
      map_point map_DocToLCO, x, y              -- Get column corresponding to pel pos.
;sayerror 'line' .line':  After map 2, line='x'; col='y
      getline line
      if substr(line, y)='' then  -- Nothing past the given column.
         if .line=.last then
            next_blank = 1
         else
            next_blank = textline(.line+1)=''
         endif
         if next_blank then
            display 1
            leave
         endif
;;       rc = 0
         x = .last
         display -2
         call joinlines()
         display 2
         if x = .last then  --  rc=-276 == Line too long to join, or
                    -- Must have hit MAXMARGIN, and JOIN split the line for us.
            '+1'
            if leftstr(textline(.line),1)=' ' then -- joinlines() added a blank
               getsearch savesearch
               .col = 1
               'xcom c/ //'  -- Change first blank to null
               setsearch savesearch
            endif
            getline line
            x = wordindex(line, 2)
            if x then  -- More than one word
               .col = x
               split
               '-1'
            endif
         endif
         iterate
      else
         .col = y
         if substr(line, y, 1) <> ' ' then
            backtab_word
            if .col = 1 then .col = y; endif
         endif
         call splitlines()
         '+1'
      endif
   enddo
   .margins = oldmargins
   .col = start_col

compile if EPM32
EA_comment 'This defines the REFLOW command; it can be linked or executed directly.  This is also a toolbar "actions" file.'
compile endif