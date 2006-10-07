/****************************** Module Header *******************************
*
* Module Name: debug.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: debug.e,v 1.7 2006-10-07 17:54:21 aschn Exp $
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
; general debug const is set = 1 and if msgtype was added to the array var
; "debuglist". One can simply use now
;    dprintf( msgtype, msg)
; instead of that "compile if" stuff, which makes code much more readable.

define
compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
compile endif

; ---------------------------------------------------------------------------
; Syntax: dprintf( [Type,] Msg)
; Pipes Type': 'Msg to PmPrintf. This can be enabled for specific Types by
; adding Type to the array var "debuglist". Example:
;    AddAVar( 'debuglist', 'TESTPROC')
;    dprintf( 'TESTPROC', 'This is my debug output')
; It can be removed from "debuglist" with
;    DelAVar( 'debuglist', 'TESTPROC')
; The array var "debuglist" is also accessable from EPM-REXX via the
; SaveUserstring, AVar2Userstring, RestoreUserstring, SetAVar, AddOnceAVar
; and DelAVar commands.
; The dprintf macro produces only output, when the constant NEPMD_DEBUG
; was set to > 0 in MYCNF.E, with:
;   const
;      NEPMD_DEBUG = 1
defproc dprintf
compile if NEPMD_DEBUG
   Type = arg(1)
   Msg  = arg(2)
   if Msg = '' then
      Msg  = arg(1)
      call NepmdPmPrintf( Msg)
   else
      Type = upcase( Type)
      DebugList = GetAVar( 'debuglist')
      if wordpos( upcase( Type), upcase( DebugList)) then
         call NepmdPmPrintf( Type': 'Msg)
      endif
   endif
compile endif
   return

; ---------------------------------------------------------------------------
; For use from EPM-REXX macros
defc dprintf
compile if NEPMD_DEBUG
   Msg  = arg(1)
   call NepmdPmPrintf( Msg)
compile endif

