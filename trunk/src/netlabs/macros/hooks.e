/****************************** Module Header *******************************
*
* Module Name: hooks.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: hooks.e,v 1.3 2004-06-03 22:46:01 aschn Exp $
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
; doesn't need to know where it will be executed. Just the hook's name must
; be known.
;
; Hooks are not able to call procedures due to a missing interpret
; statement in E.
;
; Thanks to Martin Lafaix, who implemented this stuff first in his (for
; 5.51 great) package MLEPM.
;
; Following standard hook names currently exist:
; -  init             executed (once) at defmain, after NepmdInitConfig
; -  main             executed (once) at the end of defmain
; -  load             executed at the end of defload
;                     (can be used to change file or mode specific settings,
;                     e.g. margins, tabs, tabkeys, toolbar, font)
; -  loadonce         executed once at the end of defload
;                     (like load, but change settings for next defload
;                     only)
; -  afterload        executed after all defloads are finished
; -  afterloadonce    executed once after all defloads are finished
; -  addmenu          executed by loaddefaultmenu, when the menu is built,
;                     before the help menu.
;                     (can be used for user's submenus)
; -  cascademenu      executed with postme after adding standard cascade
;                     menu items
; The *once types are deleted after being executed, so that they get
; executed 1 time only.
;
; Other events (definit, defselect, defmodify, defexit) are extendable
; properly, so no hooks are required therefore.
;
; Note: Settings executed at defload don't require additional refreshs if
;       field vars for these settings exist. They stick with the file. All
;       other settings must be refreshed at defselect as well. Use array
;       vars with the name <settings_name>.<fileid> to get a file specific
;       array for this setting.
;       Examples: .margins  --> A field var exists. Once set, it will stick
;                               with the file (it was already set at defload).
;                 mode      --> An array var mode.<fileid> exists. Its value
;                               can be queried with the get_array_value
;                               proc together with the fileid or easier with
;                               the NepmdGetMode procedure. Because the mode
;                               causes (sticky) settings changes at defload
;                               usually, there's no need to query the mode
;                               at defselect again, except if it is shown in
;                               e.g. the statusbar.
;                 toolbar   --> No array var exists. Create a new array var
;                               toolbar.<fileid> and use 'HookAdd load' to
;                               prepare the creation of the array var holding
;                               the mode or extension specific name of a
;                               toolbar. The hook will be executed at
;                               defload and this will save the toolbar name.
;                               At every defselect the array var must be
;                               queried and maybe the toolbar has to be
;                               changed.

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
; Executes all entries (FIFO) and deletes them afterwards
; Syntax: HookExecuteOnce <HookName>
defc HookExecuteOnce
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   display -1
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      do i = 1 to imax
         rc = get_array_value( EPM_utility_array_ID, prefix''HookName'.'i, Cmd)
         Cmd
         do_array 4, EPM_utility_array_ID, prefix''HookName'.'i  -- delete entry
      enddo
      do_array 4, EPM_utility_array_ID, prefix''HookName'.0'     -- delete imax
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
defproc HookGetNum
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
; Returns 1 if number of entries > 0, otherwise 0
; Syntax: HookIsDefined <HookName>
defproc HookIsDefined
   universal EPM_utility_array_ID
   prefix = 'hook.'
   parse arg HookName
   HookName = strip( lowcase(HookName))
   num = 0
   if not get_array_value( EPM_utility_array_ID, prefix''HookName'.0', imax) then  -- if imax set
      num = imax
   endif
   return (num > 0)

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

