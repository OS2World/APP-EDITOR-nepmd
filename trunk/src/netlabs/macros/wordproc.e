/****************************** Module Header *******************************
*
* Module Name: wordproc.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: wordproc.e,v 1.1 2004-02-22 21:21:52 aschn Exp $
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

; This routine converts a file into a format suitable for input into a
; word processor.  It is assumed that the current file contains a number
; of paragraphs separated by blank lines.  Each paragraph is reflowed,
; and the line terminators are for each line but the last one in each
; paragraph gets changed so that the lines will be "glued" together
; when the file is saved, making each paragraph into one long line.
;                                  Larry Margolis

compile if not defined(E_DLL)  -- Being separately compiled?
   include 'stdconst.e'

defmain
   'wordproc'

compile endif -- not defined(E_DLL)

#define MAXLNSIZE_UNTERMINATED 1

; ---------------------------------------------------------------------------
defc wordproc
   getfileid fid
   call psave_mark(savemark)
   call psave_pos(savepos)
   oldmargins = .margins
   oldmodify = .modify
   oldautosave = .autosave
   .autosave = 0        -- Don't want to go crazy autosaving...
   .margins = '2 72 1'  -- This should make it look nice...
   stopit = 0
   top
   do forever
      getline line
      do while line=''                                -- Skip over blank lines
         if .line=.last then stopit=1; leave; endif
         down
         getline line
      enddo
      if stopit then leave; endif
      startline = .line      -- Startline is first line of paragraph
      unmark; mark_line
      call pfind_blank_line()
      if .line<>startline then
         up
      else
         bottom
      endif
      mark_line
      reflow
      getmark firstline, lastline    -- New first and last lines of marked region.
      do i = firstline to lastline-1
         call setterm(fid, i, MAXLNSIZE_UNTERMINATED)
      enddo
      if lastline=.last then leave; endif
      lastline+1
   enddo
   .margins  = oldmargins
   .modify   = oldmodify + 1
   .autosave = oldautosave
   call prestore_mark(savemark)
   call prestore_pos(savepos)


; ---------------------------------------------------------------------------
; Todo: move
defproc setterm(fid, line, termtype)
   return dynalink32( E_DLL,
                      'EtkChangeLineTerminator',  -- Not exported until 1995/03/06
                      gethwndc(EPMINFO_EDITCLIENT) ||
                      atol(fid)                    ||
                      atol(line)                   ||
                      atol(termtype))

