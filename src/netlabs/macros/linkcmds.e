/****************************** Module Header *******************************
*
* Module Name: linkcmds.e
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

; ---------------------------------------------------------------------------
; A front end to the link statement. This command should always be used in
; preference to the link statement.
; Without a given modulename, it tries to link the corresponding .ex file
; of the current viewed .e file.
; The QUIET option suppresses messages, when linking was successful or
; module was already linked.
; The Link command is also executed, when an .EX file is dropped onto the
; edit window.
; Syntax: link [QUIET] [<path>][<modulename>][.ex]         Example: link draw
; Sets rc:
;      0  not linked, because already linked or because of another error
;     <0  error, rc = -307|-308 (message is shown, even for QUIET option)
;    >=0  linked successfully, the linked module number is returned, starting
;         with 0 for EPM.EX, followed by 1 etc.
defc link
   universal menuloaded  -- only defined in newmenu yet

   args = arg(1)
   wp = wordpos( 'QUIET', upcase( args))
   fQuiet = (wp > 0) |
            (menuloaded <> 1)  -- quiet if menu not already loaded
   if wp then
      args = delword( args, wp, 1)  -- remove 'QUIET' from args
   endif

   modulename = args
   if modulename = '' then                       -- If no name given,
      p = lastpos( '.', .filename)
      if upcase( substr( .filename, p)) <> '.E' then
         sayerror 'Not an .E file'
         return
      endif
      modulename = substr( .filename, 1, p - 1)  -- current file without extension
      p2 = lastpos( '\', modulename)
      modulename = substr( modulename, p2 + 1)   -- strip path
   endif

   ErrorText = link_common( modulename)  -- sets rc

   if (rc < 0) | (not fQuiet & rc >= 0) then
      sayerror ErrorText
   endif

; ---------------------------------------------------------------------------
; Like defc link, but in case of an error a MessageBox pops up, where the
; user has to press 'OK' in order to continue. Other messages are always
; suppressed. Additionally, the modulename must be given.
defc linkverify
   modulename = arg(1)

   ErrorText = link_common( modulename)  -- sets rc

   if rc < 0 then
      call winmessagebox( UNABLE_TO_LINK__MSG '"'modulename'", rc = 'rc,
                          ErrorText,
                          16416)  -- OK + ICON_EXCLAMATION + MB+MOVEABLE
   endif

; ---------------------------------------------------------------------------
; Returns ErrorText. Sets rc. rc = 0 if already linked. rc >= 0 on success.
defproc link_common( modulename)
   universal nepmd_hini

   if nepmd_hini <> '' then
      -- NEPMDLIB.DLL is used to resolve the bootdrive.
      -- Skip resolving if not already loaded.
      call parse_filename( modulename)
   endif

   waslinkedrc = linked( modulename)
   if waslinkedrc >= 0 then  -- >= 0, then it's the number in the link history
      ErrorText = 'Module "'modulename'" already linked as module #'waslinkedrc
      xrc = 0        -- if already linked

   else
      -- NewMenu uses this to remove some of its menu items, before
      -- an external package with a huge menu is linked.
      -- Note: A dprintf won't work here. EPM won't start then.
      --       In that case, delete your EPM.EX.
      if isadefproc( 'BeforeLink') then
         call BeforeLink( modulename)
      endif

      display -2  -- Turn non-critical messages off, we give our own message.
      link modulename
      linkrc = rc
      -- Maybe rc of the link statement was changed by the module's
      -- definit code before rc is queried after the link line above.
      -- Therefore it's checked again with linked().
      linkedrc = linked( modulename)
      display 2

      -- Link returns rc >= 0 if successful, like linked(). But
      -- sometimes also rc = (null) is returned on success.
      if linkedrc = -307 then
         ErrorText = 'Module "'modulename'" not linked, file not found'
      elseif linkedrc = -308 then
         ErrorText = 'Module "'modulename'" not linked, invalid filename'
      elseif linkedrc < 0 then
         -- Use linkrc, because it's more detailed. linked() returns only
         -- >=0, -1, -307, -308, while link returns some more like -290.
         ErrorText = 'Module "'modulename'" not linked, 'sayerrortext(linkrc)
      else
         ErrorText = LINK_COMPLETED__MSG''linkedrc' "'modulename'"'
      endif

      if linkrc < 0 & linkrc <> '' then
         xrc = linkrc    -- use the more detailed rc from link
      else
         xrc = linkedrc  -- use the linked module # from linked()
      endif

      -- NewMenu uses this to re-add some of its menu items, after
      -- an external package with a huge menu was not linked successfully.
      if isadefproc( 'AfterLink') then
         call AfterLink( xrc)
      endif

   endif  -- waslinkedrc >= 0 else

   rc = xrc
   return ErrorText

; ---------------------------------------------------------------------------
; The following doesn't work. Dropping .ex files is always processed internally.
; defc DragDrop_EX
;    'link' arg(1)  -- better use the defc
;
; defc DrgDrpTyp_EX_FILE
;    'link' arg(1)  -- better use the defc

; ---------------------------------------------------------------------------
; Syntax: unlink [<path>][<modulename>][.ex]        Example:  unlink draw
; A front end to the unlink statement to allow command-line invocation.
; The standard unlink statement doesn't search in EPMPATH and DPATH like the
; link statement does. This is added here. ExFile is searched in
; .;%EPMPATH%;%DPATH% until the linked file is found.
defc unlink
   FullPathName = ''
   ExFile = arg(1)

   call parse_filename( ExFile)

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
   call parse_filename( module)

   if module = '' then
      sayerror QLINK_PROMPT__MSG
   else
      result = linked( module)
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
; Routine to link an .ex file, then execute a command in that file.
defproc link_exec( ex_file, cmd_name)
   'linkverify' ex_file
   if rc >= 0 then
      cmd_name arg(3)  -- execute cmd_name with optional args
   else
      sayerror UNABLE_TO_EXECUTE__MSG cmd_name', module 'ex_file' not linked.'
   endif

; ---------------------------------------------------------------------------
; Like link_exec, but checks first if cmd_name is defined. If not, ex_file
; is linked before. Should be a bit faster than link_exec. cmd_name must be
; be different from the name for the calling command.
defproc link_exec2( ex_file, cmd_name)
   if not isadefc( cmd_name) then
      'LinkVerify' ex_file
      if rc < 0 then
         stop
      endif
   endif
   cmd_name arg(3)  -- execute cmd_name with optional args

; ---------------------------------------------------------------------------
defc linkexec
   parse arg ex_file cmd_name
   call link_exec( ex_file, cmd_name)

