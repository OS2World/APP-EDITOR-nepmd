/****************************** Module Header *******************************
*
* Module Name: hooks.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: hooks.e,v 1.1 2004-02-22 15:15:31 aschn Exp $
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

; Hook definitions
;
; A hook can hold a stack of EPM commands (and their args), that can be
; extended e.g. by user definitions. They can be executed at a specific
; event. Don't forget to add the postme command, if your command doesn't
; work properly, but try to avoid it, because it slows processing down.
;
; One advantage is, that the definition, that adds a command to the hook,
; need not to know where it will be executed. Just the hook's name must
; be known.
;
; Hooks are not able to call procedures due to a missing interpret
; statement in E.
;
; Following standard hook names currently exist:
; -  load             executed at the end of defload
; -  main             executed at the end of defmain
; -  afterload        executed once after all defloads are finished
;
; Other events (definit, defselect, defmodify, defexit) are extendable
; properly, so no hooks are required therefore.

; ---------------------------------------------------------------------------
; Adds an entry
; Syntax: HookAdd <HookName> <Cmd>
; Todo:
;    If a Cmd already exists in the hook array, then it should be deleted first and
;    afterwards appended to ensure that the command is executed last.
defc HookAdd
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName Cmd
   HookName = strip( lowcase(HookName))
   Cmd      = strip( Cmd)
   if Cmd <> '' then  -- don't increase imax if no Cmd
      if get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax not set
         imax = 0
      endif
      imax = imax + 1
      do_array 2, EPM_utility_array_ID, prefix''HookName'.'imax, Cmd   -- add entry
      do_array 2, EPM_utility_array_ID, prefix''HookName'.0', imax     -- update imax
   endif
   return

; ---------------------------------------------------------------------------
; Replaces all entries with an entry
; Syntax: HookSet <HookName> <Cmd>
defc HookSet
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName Cmd
   HookName = strip( lowcase(HookName))
   Cmd      = strip( Cmd)
   if Cmd <> '' then  -- don't increase imax if no Cmd
      -- delete all old Cmds first
      if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
         do i = 1 to imax
            if not get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd) then  -- if Cmd set
               do_array 4, EPM_utility_array_ID, prefix''HookName'.'i  -- delete entry
            endif
         enddo
      endif
      -- set new Cmd
      imax = 1
      do_array 2, EPM_utility_array_ID, prefix''HookName'.'imax, Cmd   -- add entry
      do_array 2, EPM_utility_array_ID, prefix''HookName'.0', imax     -- update imax
   endif
   return

; ---------------------------------------------------------------------------
; Deletes all entries
; Syntax: HookDelAll <HookName>
defc HookDelAll
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      do i = 1 to imax
         if not get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd) then  -- if Cmd set
            do_array 4, EPM_utility_array_ID, prefix''HookName'.'i  -- delete entry
         endif
      enddo
      do_array 4, EPM_utility_array_ID, prefix''HookName'.0'        -- delete imax
   endif
   return

; ---------------------------------------------------------------------------
; Deletes a Cmd from hook array
; Syntax: HookDel <HookName> <Cmd>
defc HookDel
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName Cmd
   HookName = strip( lowcase(HookName))
   Cmd      = strip( Cmd)
   if Cmd <> '' then  -- don't try to process if no Cmd
      if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
         do i = 1 to imax
            rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, next)
            if upcase(next) = upcase(Cmd) then
               --------------------------------------- todo -----------------------------------
            endif
         enddo
      endif
   endif
   return

; ---------------------------------------------------------------------------
; Executes all entries (FIFO)
; Syntax: HookExecute <HookName>
defc HookExecute
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   display -1
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      do i = 1 to imax
         rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd)
         Cmd
      enddo
   endif
   display 1
   return

; ---------------------------------------------------------------------------
; Executes last entry
; Syntax: HookExecuteLast <HookName>
defc HookExecuteLast
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   display -1
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      i = imax
      rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd)
      Cmd
   endif
   display 1
   return

; ---------------------------------------------------------------------------
; Executes first entry
; Syntax: HookExecuteFirst <HookName>
defc HookExecuteFirst
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   display -1
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      i = 1
      rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd)
      Cmd
   endif
   display 1
   return

; ---------------------------------------------------------------------------
; Returns number of entries
; Syntax: HookGetNum <HookName>
defc HookGetNum
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   num = 0
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      num = imax
   endif
   return num

; ---------------------------------------------------------------------------
; Shows all entries
; Syntax: HookShow <HookName>
defc HookShow
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      next = '|'
      do i = 1 to imax
         rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd)
         next = next''Cmd'|'
      enddo
   endif
   sayerror HookName' = 'next
   return

