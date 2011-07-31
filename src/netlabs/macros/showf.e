/****************************** Module Header *******************************
*
* Module Name: showf.e
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

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled.
defmain
   'showf' arg(1)
compile endif

; ---------------------------------------------------------------------------
defc showf
   if arg(1)='' then
      getline line
      call find_token(startcol, endcol)
      id = substr(line, startcol, (endcol-startcol)+1)
      if leftstr( id, 1) <> '.' then
         sayerror "Specify a field var or place cursor over one."
         return
      endif
   else
      id = arg(1)
   endif
   getfileid fid
   'xcom e /c sf_temp.tmp'
   replaceline 'defmain', 1
   insertline  '   fid = 'fid, 2
   insertline  '   sayerror '''id' = "''fid'id'''"''', 3
   'xcom file'
   'etpm sf_temp.tmp'
   if rc then return; endif
   unlink 'sf_temp'       -- (just in case...)
   'sf_temp'
   call erasetemp('sf_temp.tmp')
   call erasetemp('sf_temp.ex')

