/****************************** Module Header *******************************
*
* Module Name: wrap.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: wrap.e,v 1.3 2004-03-13 00:55:26 aschn Exp $
*
* ===========================================================================
*
* This file is part of the Netlabs EPM Distribution package and is free
* software.  You can redistribute it and/or modify it under the terms of the
* GNU General Public License as published by the Free Software
* Foundation, in version 2 as it comes in the "COPYING" file of the
* Netlabs EPM Distribution.  This library is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
****************************************************************************/
; Wrap a file at a column.
;
; o  Lines are split
;    -  at the last blank (first space or tab after the last word)
;       before column (wrap at words only) or
;    -  if none found: at the specified column.
;    column = arg(1), default: 79
;
; o  NEPMD_WRAP_METHOD = 'KEEPINDENT'
;    Indent of the wrapped line is kept. Trailing blanks of the
;    wrapped line and leading spaces of the new line are gobbled.
;
; o  NEPMD_WRAP_METHOD = 'SOFT' (default)
;    Line is split before a possible space. Than the next line starts with
;    a space. The line terminator of the split line is removed. After 'save'
;    the file will be indentical to the file before the 'wrap' cmd. A
;    'revert' will undo the line splitting.
;
; o  Possible Features to add:
;    -  Insert a special char at the end of the splitted and/or the
;       beginning of the next line to be able to join them later (on
;       save?) again.  Handle trailing and leading blanks.
;    -  Wrap programming code and keep it compilable.
;    -  Wrap at right border.

compile if not defined(SMALL)
const
include 'stdconst.e'
tryinclude 'mycnf.e'
compile endif
compile if not defined(NEPMD_WRAP_METHOD)
const
   NEPMD_WRAP_METHOD = 'SOFT'  -- SOFT | KEEPINDENT  <------------------------ Todo
compile endif
defmain
   'wrap' arg(1)

#define MAXLNSIZE_UNTERMINATED 1

-- From EDLL.H:
;    //Line terminator constants
;    #define MAXLNSIZE_UNTERMINATED 1
;    #define CR_TERMINATED          2
;    #define LF_TERMINATED          3
;    #define CRLF_TERMINATED        4
;    #define CRCRLF_TERMINATED      5
;    #define NULL_TERMINATED        6
;    #define CTRLZ_TERMINATED       7
;    #define NOMOREDATA_TERMINATED  8
;    #define INHERITED_TERMINATED   9
;    #define CRLFEOF_TERMINATED    10

defc wrap
   universal vEPM_POINTER

   defaultlimit = 79

   limit = arg(1)
   if limit = '' then
      limit = defaultlimit
   endif

   old_modify   = .modify
   old_autosave = .autosave
   .autosave = 0
   undoaction 1, junk                -- Create a new state
   call psave_pos(save_pos)
   .line = 1
   .col  = 1
   m = 0
   l = 1
   getfileid fid
   client = gethwndc(EPMINFO_EDITCLIENT)
   mouse_setpointer WAIT_POINTER
   display -1  -- disable update of text area
   do while l <= .last
      -- process all lines
      getline line, l

      if length( strip( line, 'T')) > limit then

compile if NEPMD_WRAP_METHOD = 'KEEPINDENT'
         -- Search last occurence of space or tab, starting at limit
         SpaceP = lastpos( ' ', line, limit)
         TabP   = lastpos( \9,  line, limit)
         p = max( SpaceP, TabP)
         first_nonblank_p = max( 1, verify( line, ' '\t))
         --if not p then    -- No spaces in the line?
         -- Fixed: additional blank line if a line start with a space.
         if p < first_nonblank_p then    -- No spaces in the line after indent?
            p = limit
         endif
         l        -- Set cursor on line l
         .col = p -- Set cursor on col p + 1 (after a possible space or tab)
         -- Better take def of ENTER.E, defproc nepmd_stream_indented_split_line?
         --   *  keep indent (copy indent area of preceding line)
         --   *  respect comment chars (treat comment chars as indent)
         call splitlines()  -- keeps indent of current line
         .modify = old_modify + 1

compile else
         p = lastpos(' ', line, limit)
         first_nonblank_p = max( 1, verify( line, ' '\t))
         --if not p then    -- No spaces in the line?
         -- Fixed: endless loop if a line start with a space.
         if p < first_nonblank_p then    -- No spaces in the line after indent?
            p = limit
         endif
         l         -- Set cursor on line l
         .col = p  -- Set cursor on col p (before a possible space)
         split
         termtype = MAXLNSIZE_UNTERMINATED
         ret = dynalink32( E_DLL,
                           'EtkChangeLineTerminator',  -- Not exported until 1995/03/06
                           client          ||
                           atol(fid)       ||
                           atol(l)         ||
                           atol(termtype))
         .modify = old_modify + 1  -- create a new state to enable Undo
compile endif

         m = m + 1
      endif  -- length( strip( line, 'T')) > limit
      l = l + 1
   enddo  -- while l <= .last

   call prestore_pos(save_pos)
   .autosave = old_autosave
   display 1
   mouse_setpointer vEPM_POINTER

   msg = 'Wrap after 'limit' chars: 'm
   if m = 1 then
      msg = msg' change.'
   else
      msg = msg' changes.'
   endif
   sayerror msg

   return

