/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: linkcmds.e,v 1.37 2006-03-26 12:17:57 aschn Exp $
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

----------> Todo: option QUIET or better:
----------        suppress all normal output until the EPM window is shown
----------        or the menu is created (where a universal already exists
----------        for) or better:
--                Suppress all non-critical msgs at definit and activate it
--                in defmain, after the menu is shown.

; ---------------------------------------------------------------------------
; A front end to the link statement. This command should always be used in
; preference to the link statement.
; The QUIET option suppresses messages, when linking was successful or
; module was already linked.
; Unfortunately no E command is processed, when an .EX file is dropped onto
; the edit window. That file is processed by the internally defined link
; statement only.
; Syntax: link [QUIET] [<path>][<modulename>][.ex]         Example: link draw
; Returns:
;     -1  not linked, because already linked
;    <-1  error (message is shown, even for QUIET option)
;    >=0  linked successfully, the linked module number is returned, starting
;         with 0 for EPM.EX, followed by 1 etc.
defc link
   universal nepmd_hini
   universal menuloaded  -- only defined in newmenu yet

   args = arg(1)
   wp = wordpos( 'QUIET', upcase( args))
   fQuiet = (wp > 0) |
            (menuloaded <> 1)  -- quiet if menu not already loaded
   if wp then
      args = delword( args, wp, 1)  -- remove 'QUIET' from args
   endif

   modulename = args
   if modulename = '' then                           -- If no name given,
      p = lastpos( '.', .filename)
      if upcase( substr( .filename, p)) <> '.E' then
         sayerror 'Not an .E file'
         return
      endif
      modulename = substr( .filename, 1, p - 1)      -- current file without extension
      p2 = lastpos( '\', modulename)
      modulename = substr( modulename, p2 + 1)       -- strip path
   endif

   waslinkedrc = linked( modulename)
   if waslinkedrc >= 0 then  -- >= 0, then it's the number in the link history
      if not fQuiet then
         sayerror 'Module "'modulename'" already linked as module #'waslinkedrc'.'
      endif

   else
      if isadefproc( 'BeforeLink') then
         call BeforeLink( modulename)
      endif

      display -2  -- Turn non-critical messages off, we give our own message.
      link modulename
      linkrc = rc    -- save value
      linkedrc = rc  -- initialize only
      display 2

      -- Link always returns rc = 0 if successful, different to linked()
      if linkrc = -307 then
         sayerror 'Module "'modulename'" not linked, file not found'
      elseif linkrc = -308 then
         sayerror 'Module "'modulename'" not linked, invalid filename'
      else
         -- Bug of Link: Sometimes linkrc = empty, therefore check it again with linked()
         linkedrc = linked( modulename)
         if linkedrc < 0 then  -- any other rc values than -307 or -308?
            sayerror 'Module "'modulename'" not linked, rc = 'linkrc', linkedrc = 'linkedrc
         else
            if not fQuiet then
               sayerror LINK_COMPLETED__MSG''linkedrc' "'modulename'"'
            endif
         endif
      endif
   endif  -- waslinkedrc >= 0 else

   if waslinkedrc >= 0 then
      savedrc = -1        -- if already linked
   else
      if linkrc = '' | linkrc = 0 then
         savedrc = linkedrc  -- on success: return the link number (0, 1, ...)
      else
         savedrc = linkrc    -- E error code (< 0)
      endif

      if isadefproc( 'AfterLink') then
         call AfterLink( savedrc)
      endif
   endif

   rc = savedrc

; ---------------------------------------------------------------------------
; The following doesn't work. Dropping .ex files is always processed internally.
; defc DragDrop_EX
;    'link' arg(1)  -- better use the defc
;
; defc DrgDrpTyp_EX_FILE
;    'link' arg(1)  -- better use the defc

; ---------------------------------------------------------------------------
; Syntax: unlink [<path>][<modulename>][.ex]        Example:  unlink draw
; A simple front end to the unlink statement to allow command-line invocation.
; The standard unlink statement doesn't search in EPMPATH and DPATH like the
; link statement does. This is added here. ExFile is searched in
; .;%EPMPATH%;%DPATH% until the linked file is found.
defc unlink
   FullPathName = ''
   ExFile = arg(1)

   if substr( ExFile, 2, 2) =  ':\' or substr( ExFile, 1, 2) =  '\\' then
      FullPathName = ExFile
   endif

   if FullPathName = '' then

      -- If no name given, use current file with '.ex' extension
      if ExFile = '' then
         p2 = lastpos( '.', .filename)
         if upcase( substr( .filename, p2)) <> '.E' then
            sayerror '"'.filename'" is not an .E file'
            return
         endif
         ExFile = substr( .filename, 1, p2 - 1)'.ex'
      endif

      -- Strip path and append '.ex' if no extension
      p1 = lastpos( '\', ExFile)
      ExFileName = substr( ExFile, p1 + 1)
      p2 = lastpos( '.', ExFileName)
      if p2 = 0 then
         ExFileName = ExFileName'.ex'
      endif

      -- Search ExFile in whole PathList, until linkedrc >= 0
      PathList = '.;'Get_Env('EPMPATH')';'Get_Env('DPATH')';'  -- standard EPM
      --PathList = Get_Env('EPMEXPATH')';'                       -- NEPMD
      rest = PathList
      do while rest <> ''
         parse value rest with Path';'rest
         if Path = '' then
            iterate
         endif
         next = strip( Path, 'T', '\')'\'ExFileName
         if Exist( next) then
            linkedrc = linked( next)
            if linkedrc >= 0 then
               FullPathName = next
               leave
            endif
         endif
      enddo

   endif

   if FullPathName = '' then
      FullPathName = arg(1)  -- try to unlink arg(1) if not found until here
   endif

   display -2  -- Turn non-critical messages off, we give our own message.
   unlink FullPathName
   unlinkrc = rc
   display 2
   if unlinkrc then
      if unlinkrc = -310 then
         sayerror 'Module "'FullPathName'" not unlinked, unknown module'
      elseif unlinkrc = -301 then
         sayerror 'Module "'FullPathName'" not unlinked, module in use (better restart EPM)'
      elseif unlinkrc = -302 then
         sayerror 'Module "'FullPathName'" not unlinked, defined keyset in use (better restart EPM)'
      else
         sayerror 'Module "'FullPathName'" not unlinked, rc = 'unlinkrc
      endif
   endif

; ---------------------------------------------------------------------------
; New command to query whether a module is linked.  Of course if
; you're not sure whether a module is linked, you can always just repeat the
; link command.  E won't reload the file from disk if it's already linked, but
; it will rerun the module's DEFINIT which might not be desirable.
;
; This also serves to document the new linked() function.  Linked() returns:
;    module number        (a small integer, >= 0) if linked.
;    -1                   if found on disk but not currently linked.
;    -307                 if module can't be found on disk.  This RC value
;                         is the same as sayerror("Link: file not found").
;    -308                 if bad module name, can't be expanded.  Same as
;                         sayerror("Link: invalid filename").
defc qlink, qlinked, ql
   module = arg(1)
   if module = '' then
      sayerror QLINK_PROMPT__MSG
   else
      result = linked(arg(1))
      if result = -307 or    -- sayerror("Link: file not found")
         result = -308 then  -- sayerror("Link: invalid filename")
         sayerror CANT_FIND1__MSG module CANT_FIND2__MSG
      elseif result < 0 then    -- return of -1 means file exists but not linked
         sayerror module NOT_LINKED__MSG
      else
         sayerror module LINKED_AS__MSG result'.'
      endif
   endif

; ---------------------------------------------------------------------------
defc linkverify
   module = arg(1)
   link module
   -- Sometimes the rc for a module's definit overwrites the link rc.
   -- Therefore a linkable module with code in definit, that changes rc,
   -- should save it at the begin of definit and restore it at the end.
   if rc < 0 then
      if rc = -290 then  -- sayerror('Invalid EX file or incorrect version')
         -- Get full pathname for a better error msg
         if filetype(module) <> '.EX' then
            module = module'.ex'              -- link does this by itself
         endif
         findfile module1, module, EPATH      -- link does this by itself
         if rc then
            findfile module1, module, 'PATH'  -- why search in PATH?
         endif
         if not rc then
            module = module1
         endif
         rc = -290
      endif
      call winmessagebox( UNABLE_TO_LINK__MSG module,
                          sayerrortext(rc),
                          16416)  -- OK + ICON_EXCLAMATION + MB+MOVEABLE
   endif

; ---------------------------------------------------------------------------
; Routine to link an .ex file, then execute a command in that file.
defproc link_exec( ex_file, cmd_name)
   'linkverify' ex_file
   if RC >= 0 then
      cmd_name arg(3)
   else
      sayerror UNABLE_TO_EXECUTE__MSG cmd_name
   endif

; ---------------------------------------------------------------------------
defc linkexec
   parse arg ex_file cmd_name
   call link_exec( ex_file, cmd_name)

