/****************************** Module Header *******************************
*
* Module Name: titletext.e
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
compile if not defined(WANT_DATETIME_IN_TITLE)
   WANT_DATETIME_IN_TITLE = 1
compile endif
   NEPMD_FLAG_ALTERED_BY_ANOTHER = 'NEPMD1'
   NEPMD_FLAG_NO_DATETIME        = 'NEPMD2'
   NEPMD_FLAG_MODIFIED           = 'NEPMD3'

; ---------------------------------------------------------------------------
; Called on defload and defmodify
defproc MakeTitletext
   -- don't act on invisible files
   if .visible = 0 then
      return
   endif

   filename = .filename
   if .modify = 0 then
      ---- if not modified and filename is a temp file (starts with '.') ----
      if leftstr( filename, 1 ) = '.' then

         --.titletext = filename
         next = 'ERROR:'NEPMD_FLAG_NO_DATETIME
      ---- if not modified and filename is not a temp file ----
      else
         next = get_filedatehex( filename )
      endif
   ---- if modified ----
   else
      --.titletext = filename'   (Modified)'
      next = 'ERROR:'NEPMD_FLAG_MODIFIED
   endif
   call RefreshTitletext(next)
   return

; ---------------------------------------------------------------------------
; Called by defproc MakeTitletext and defc RefreshTitletext
; Sets the titletext according to it's arg.
; arg is either a datetime string or a rc value in the form 'ERROR:'rc
;
; Todo:
;    use templates for the .titletext definitions
defproc RefreshTitletext(next)

   -- don't act on invisible files
   if .visible = 0 then
      return
   endif

   filename = .filename
   parse value next with 'ERROR:'rc
   if rc > '' then                   -- if DosQueryPathInfo returned error code
      msg       = ''
      statusmsg = ''
      if rc then
         if     rc = 2   then msg = 'File not found'
         elseif rc = 3   then msg = 'Path not found'
         elseif rc = 6   then msg = 'Invalid handle'
         elseif rc = 18  then msg = 'No more files'
         elseif rc = 26  then msg = 'Not DOS disk'
         elseif rc = 87  then msg = 'Invalid parameter'
         elseif rc = 108 then msg = 'Drive locked'
         elseif rc = 111 then msg = 'Buffer overflow'
         elseif rc = 113 then msg = 'No more search handles'
         elseif rc = 206 then msg = 'Filename exced range'
         -- following rc's don't come from DosQueryPathInfo
         elseif rc = NEPMD_FLAG_ALTERED_BY_ANOTHER then
                              msg = 'File was altered by another application'
         elseif rc = NEPMD_FLAG_NO_DATETIME then
                              msg = 0
                              statusmsg = 0
         elseif rc = NEPMD_FLAG_MODIFIED then
                              msg = 'Modified'
                              statusmsg = 0
         else
                              msg = 'rc = 'rc
         endif
      endif

      if statusmsg = '' then
         statusmsg = msg
      endif
      if statusmsg <> 0 then
         sayerror filename': 'statusmsg
      endif

      if msg = 0 then
         .titletext = filename
      else
         .titletext = filename'   ('msg')'
      endif

   else                      -- if DosQueryPathInfo returned a datetime string
      filedatehex = next
      datetime = filedatehex2datetime( filedatehex )
      parse value datetime with date time
      .titletext = filename'   ('date' - 'time')'

   endif  -- rc > ''
   return

; ---------------------------------------------------------------------------
compile if WANT_DATETIME_IN_TITLE
defload
   call MakeTitletext() -- Better without postme, to let the ring list show datetime
                        -- strings even if no defselect has occurred for every file before.

defmodify
   call MakeTitletext()

defselect
   --'postme checkifupdated'
   call CheckIfUpdated()

; CheckIfUpdated is also called by defc processmouse; if not WindowHadFocus
compile endif

; ---------------------------------------------------------------------------
; Compares .fileinfo with current return string from DosQueryFileInfo
; .fileinfo = string from DosQueryFileInfo, set at every file loading.
; Calls RefreshTitletext with following arg:
;    if modified or if filename starts with '.':
;       a special flag
;    if not modified:
;       the error code or the hex string returned from
;       DosQueryFileInfo/get_filedatehex.
; Called by defselect and defc processmouse; if not WindowHadFocus
defproc CheckIfUpdated

   -- don't act on invisible files
   if .visible = 0 then
      return
   endif

   filename = .filename
   if leftstr( filename, 1 ) = '.' then
      ---- if temp file and not modified ----
      if .modify = 0 then
         ret = 'ERROR:'NEPMD_FLAG_NO_DATETIME              -- titletext = filename
      ---- if temp file and modified ----
      else
         ret = 'ERROR:'NEPMD_FLAG_MODIFIED                 -- titletext = filename'   (Modified)'
      endif

   ---- if not a temp file ----
   else
      cur_filedatehex = ltoa(substr(.fileinfo, 9, 4), 16)
      next = get_filedatehex(filename)
      parse value next with 'ERROR:'rc

      if rc > '' then                   -- if DosQueryPathInfo returned error code
         ret = next        -- update titletext with error msg

      else                              -- if DosQueryPathInfo returned data string
         new_filedatehex = next
         if new_filedatehex <> cur_filedatehex then
            -- if file was altered by another application
            ret = 'ERROR:'NEPMD_FLAG_ALTERED_BY_ANOTHER    -- update titletext with msg
         else
            -- if file on disk has the same datetime as file when loaded
            if .modify = 0 then
               ret = next  -- update titletext with new datetime (why?) --> .modify could be changed!
            else
               ret = 'ERROR:'NEPMD_FLAG_MODIFIED           -- .titletext = filename'   (Modified)'
            endif
         endif

      endif

   endif

   call RefreshTitletext(ret)

   return

; ---------------------------------------------------------------------------
defproc get_filedatehex(filename)
   pathname = filename\0
   resultbuf = copies(\0,30)
   result = dynalink32('DOSCALLS',      /* dynamic link library name       */
                       '#223',           /* ordinal value for DOS32QueryPathInfo  */
                       address(pathname)         ||  -- pathname to be queried
                       atol(1)                   ||  -- PathInfoLevel
                       address(resultbuf)        ||  -- buffer where info is to be returned
                       atol(length(resultbuf)) )     -- size of buffer
   --return ltoa(substr(resultbuf, 9, 4), 16)
   filedatehex = ltoa(substr(resultbuf, 9, 4), 16)
   if result = 0 then
      -- the return value can be compared with ltoa(substr(.fileinfo, 9, 4), 16)
      ret = filedatehex
   else
      ret = 'ERROR:'result
   endif
   --sayerror 'get_filedatehex: ret = 'ret
   return ret

; ---------------------------------------------------------------------------
; Todo: use NLS settings from OS2.INI
defproc filedatehex2datetime(hexstr)
   -- add leading zero if length < 8
   hexstr = rightstr( hexstr, 8, 0 )

   date = hex2dec( substr( hexstr, 5, 4 ) )
   year = date % 512; date = date // 512
   month = date % 32; day = date // 32 % 1     -- %1 to drop fraction.
;   date = year+1980'/'rightstr(month,2,0)'/'rightstr(day,2,0)  -- english date  yyyy/mm/dd
   date = rightstr(day,2,0)'.'rightstr(month,2,0)'.'year+1980  -- german date   dd.mm.yyyy

   time = hex2dec( substr( hexstr, 1, 4 ) )
   hour = time % 2048; time = time // 2048
   min = time % 32; sec = time // 32 * 2 % 1
   time = hour':'rightstr(min,2,0)':'rightstr(sec,2,0)  -- german time hh:mm:ss

   return date time

