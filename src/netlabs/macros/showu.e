/****************************** Module Header *******************************
*
* Module Name: showu.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: showu.e,v 1.2 2008-09-05 23:10:56 aschn Exp $
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

; http://groups.google.com/groups?hl=de&lr=&ie=UTF-8&selm=5etq66%24tao%241%40news-s01.ca.us.ibm.net

; ShowU.e, by Larry Margolis

; This is a simple routine that will let you dynamically display the value of
; a universal variable.  Since the universal variable name must be compiled
; in to the code that attempts to display it, we have to be a wee bit clever
; in order to do this - we write some code to a temp file, then compile that
; and run the dynamically-generated code.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled.
defmain
   'showu' arg(1)
compile endif

; ---------------------------------------------------------------------------
defc showu =
   if arg(1)='' then
      getline line
      if lowcase(word(line, 1)) <> 'universal' |
         not pos(substr(.line, .col, 1), ' ,')
      then
         sayerror "Specify a univ. var or place cursor over one (on a 'universal' line)."
         return
      endif
      call find_token(startcol, endcol)
      id = substr(line, startcol, (endcol-startcol)+1)
   else
      id = arg(1)
   endif
   'xcom e /c su_temp.tmp'
   replaceline 'defmain', 1
   insertline  '   universal' id, 2
   insertline  '   sayerror '''id' = "'''id'''"''', 3
   'xcom file'
   'etpm su_temp.tmp'
   if rc then return; endif
   unlink 'su_temp'       -- (just in case...)
   'su_temp'
   call erasetemp('su_temp.tmp')
   call erasetemp('su_temp.ex')

