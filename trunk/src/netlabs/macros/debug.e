/****************************** Module Header *******************************
*
* Module Name: debug.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: debug.e,v 1.3 2004-09-12 15:10:25 aschn Exp $
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

; Define the dprintf proc, that pipes a message to PmPrintf, if the
; corresponding const is set = 1. One can simply use now
;    dprintf( msgtype, msg)
; instead of that "compile if" stuff, which makes code much more readable.
; The consts are to be extended.
; All PmPrintf messages can be disabled by setting NEPMD_DEBUG to 0, which
; is the default.

define
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif
compile if not defined(NEPMD_DEBUG_DEFMAIN)
   NEPMD_DEBUG_DEFMAIN = 0
compile endif
compile if not defined(NEPMD_DEBUG_DEFMAIN_EMPTY_FILE)
   NEPMD_DEBUG_DEFMAIN_EMPTY_FILE = 0
compile endif
compile if not defined(NEPMD_DEBUG_EDIT)
   NEPMD_DEBUG_EDIT = 0
compile endif
compile if not defined(NEPMD_DEBUG_AFTERLOAD)
   NEPMD_DEBUG_AFTERLOAD = 0
compile endif
compile if not defined(NEPMD_DEBUG_SELECT)
   NEPMD_DEBUG_SELECT = 0
compile endif
compile if not defined(NEPMD_DEBUG_RESTORE_POS)
   NEPMD_DEBUG_RESTORE_POS = 0
compile endif
compile if not defined(NEPMD_DEBUG_TAGS)
   NEPMD_DEBUG_TAGS = 0
compile endif

; ---------------------------------------------------------------------------
; Syntax: dprintf( <type>, <message>)
; Pipes <type>': '<message> to PmPrintf.
; This can be disabled for specific <type>s with corresponding
; configuration consts. The main config const NEPMD_DEBUG must be
; set to 1 to enable output generally.
defproc dprintf
compile if NEPMD_DEBUG
   type   = arg(1)
   uptype = upcase(type)
   msg    = arg(2)
   WriteMsg = 0

   if type = 'DEFMAIN' then
      if NEPMD_DEBUG_DEFMAIN then
         WriteMsg = 1
      endif
   elseif type = 'DEFMAIN_EMPTY_FILE' then
      if NEPMD_DEBUG_DEFMAIN_EMPTY_FILE then
         WriteMsg = 1
      endif
   elseif type = 'EDIT' then
      if NEPMD_DEBUG_EDIT then
         WriteMsg = 1
      endif
   elseif type = 'AFTERLOAD' then
      if NEPMD_DEBUG_AFTERLOAD then
         WriteMsg = 1
      endif
   elseif type = 'AFTERLOAD_ACTIVATE' then
      if NEPMD_DEBUG_AFTERLOAD_ACTIVATE then
         WriteMsg = 1
      endif
   elseif type = 'SELECT' then
      if NEPMD_DEBUG_SELECT then
         WriteMsg = 1
      endif
   elseif type = 'RESTORE_POS' then
      if NEPMD_DEBUG_RESTORE_POS then
         WriteMsg = 1
      endif
   elseif type = 'TAGS' then
      if NEPMD_DEBUG_TAGS then
         WriteMsg = 1
      endif
   else  -- type is undefined
      WriteMsg = 1
   endif

   if WriteMsg = 1 then
      call NepmdPmPrintf( type': 'msg)
   endif
compile endif  -- NEPMD_DEBUG
   return

