/****************************** Module Header *******************************
*
* Module Name: box.e
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
;  For linking version, BOX can be an external command.
;  Script style suggested by Larry Salomon, Jr.

compile if not defined(SMALL)
 define INCLUDING_FILE = 'BOX.E'
tryinclude 'MYCNF.E'
 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif
 compile if not defined(NLS_LANGUAGE)
  const NLS_LANGUAGE = 'ENGLISH'
 compile endif
include NLS_LANGUAGE'.e'
   EA_comment 'This defines the BOX command; it can be linked or executed directly.'
compile endif

defmain     -- External modules always start execution at DEFMAIN.
   'box' arg(1)

; Syntax: Box <arg>
; <arg> =
; 1 thin, single line
; 2 thin, double line
; 3 dotted line
; 4 thick line
; 5 double, thin line horizontally; single, thin line vertically
; 6 double, thin line vertically; single, thin line horizontally
; C creates a box comment using the C language syntax
; P creates a box comment using the Pascal language syntax
; A creates a box comment using Assembler syntax
; E erases the box around the marked area
; R reflows text in marked area
; B places spaces on all sides of the marked area, i.e. creates a box of blank spaces
; /character Any character which follows the slash ( / ) will be used to form a box.
defc box
   universal tempofid

   uparg = upcase( arg(1))
   msg = BOX_ARGS__MSG
   if not length( uparg) then
      sayerror msg
      stop
   endif
   if marktype() <> 'BLOCK' then
      sayerror -288  -- 'Block mark required'
      stop
   endif
   fSlash = 0
   call NextCmdAltersText()
   for ptr = 1 to length( uparg)
      if fSlash then
         style = substr( arg(1), ptr, 1)
      else
         style = substr( uparg, ptr, 1)
      endif
      if style = '/' then
         fSlash = 1
         iterate
      endif
      if not fSlash and verify( uparg, '123456BCPAERS') then
         sayerror msg
         stop
      endif
      call psave_pos( save_pos)
      getmark firstline, lastline, firstcol, lastcol, fileid

      fReplaceDone = 0
      if style = 'E' then      -- Erase box
         getline tline, firstline, fileid
         getline bline, lastline, fileid
         msg = BOX_MARK_BAD__MSG
         if firstcol = 1 or firstline = 1 or lastline = fileid.last then
            sayerror msg
            stop
         endif

         brc = substr( bline, lastcol + 1, 1)
         lside = substr( tline, firstcol - 1, 1)
         if pos( lside, 'º³;|Û') > 0  then
            sl = 1
         elseif lside = '*' and firstcol > 2 and  -- MAX prevents error if firstcol <= 2
                                pos( substr( tline, max( firstcol - 2, 1), 1), '{/.') then
            sl = 2
         elseif brc = lside then
            sl = 1
         else
            sayerror msg
            stop
         endif
         for i = firstline to lastline
            getline line, i, fileid
            replaceline substr( line, 1, firstcol - sl - 1)||
                        substr( line, firstcol, lastcol + 1 - firstcol)||
                        substr( line, lastcol + sl + 1), i, fileid
         endfor
         deleteline lastline + 1, fileid
         deleteline firstline - 1, fileid
         fReplaceDone = 1
         call prestore_pos( save_pos)
         call pset_mark( firstline - 1, lastline - 1, firstcol - sl, lastcol - sl, marktype(), fileid)

      elseif style = 'R' then  -- Reflow
         if not pblock_reflow( 0, spc, tempofid) then
            call pblock_reflow( 1, spc, tempofid)
         endif
         fReplaceDone = 1
         call prestore_pos( save_pos)

      elseif fSlash then       -- \<char>
         lside = style
         rside = style
         tside = style
         tlc   = style
         trc   = style
         blc   = style
         brc   = style

      elseif style = 'P' then  -- Pascal
         lside = '{*'
         rside = '*}'
         tside = '*'
         tlc   = '{*'
         trc   = '*}'
         blc   = '{*'
         brc   = '*}'

      elseif style = 'A' then  -- Assembler
         lside = ';'
         rside = ' '
         tside = '*'
         tlc   = ';'
         trc   = ' '
         blc   = ';'
         brc   = ' '

      elseif style = 'C' then  -- C
         lside = '/*'
         rside = '*/'
         tside = '*'
         tlc   = '/*'
         trc   = '*/'
         blc   = '/*'
         brc   = '*/'

      elseif style = 1 then
         lside = '³'
         rside = '³'
         tside = 'Ä'
         tlc   = 'Ú'
         trc   = '¿'
         blc   = 'À'
         brc   = 'Ù'

      elseif style = 2 then
         lside = 'º'
         rside = 'º'
         tside = 'Í'
         tlc   = 'É'
         trc   = '»'
         blc   = 'È'
         brc   = '¼'

      elseif style = 3 then
         lside = '|'
         rside = '|'
         tside = '-'
         tlc   = '+'
         trc   = '+'
         blc   = '+'
         brc   = '+'

      elseif style = 4 then
         lside = 'Û'
         rside = 'Û'
         tside = 'ß'
         tlc   = 'Û'
         trc   = 'Û'
         blc   = 'ß'
         brc   = 'ß'

      elseif style = 5 then
         lside = '³'
         rside = '³'
         tside = 'Í'
         tlc   = 'Õ'
         trc   = '¸'
         blc   = 'Ô'
         brc   = '¾'

      elseif style = 6 then
         lside = 'º'
         rside = 'º'
         tside = 'Ä'
         tlc   = 'Ö'
         trc   = '·'
         blc   = 'Ó'
         brc   = '½'

      elseif style = 'S' then  -- Script
         lside = '.*'
         rside = '**'
         tside = '*'
         tlc   = '.*'
         trc   = '**'
         blc   = '.*'
         brc   = '**'

      else
         style = 'B'           -- Blank
         lside = ' '
         rside = ' '
         tside = ' '
         tlc   = ' '
         trc   = ' '
         blc   = ' '
         brc   = ' '
      endif

      if fReplaceDone = 0 then
         sl = length( lside)
         width = 1 + lastcol - firstcol  -- width of inside of box
         side  = substr( '', 1, width, tside)
         next  = substr( '', 1, firstcol - 1) ||
                 blc  ||
                 side ||
                 brc
         insertline next, lastline + 1, fileid
         next  = substr( '', 1, firstcol - 1) ||
                 tlc  ||
                 side ||
                 trc
         insertline next, firstline, fileid
         for i = firstline + 1 to lastline + 1
            getline line, i, fileid
            next = substr( line, 1, firstcol - 1) ||
                   lside ||
                   substr( line, firstcol, width) ||
                   rside ||
                   substr( line, lastcol + 1)
            replaceline next, i, fileid
         endfor
         call prestore_pos( save_pos)
         call pset_mark( firstline + 1, lastline + 1, firstcol + sl, lastcol + sl, marktype(), fileid)
      endif
      fSlash = 0
   endfor

