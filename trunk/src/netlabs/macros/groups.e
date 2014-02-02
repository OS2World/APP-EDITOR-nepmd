/****************************** Module Header *******************************
*
* Module Name: groups.e
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

/*
Todo:
-  Disable Afterload until all files are loaded in loadgroup.
*/

; Groups.e, by Larry Margolis
;
; Defines a SaveGroup command which saves the contents of the edit ring
; as a group, and a LoadGroup command which reloads that group, positioning
; each file as it was when the SaveGroup was executed.  For OS/2 2.x users,
; optionally creates a desktop icon for the group.  EPM 6.0 can do this
; directly; users of other versions must extract the command file at the
; end and save it as a MAKEGRP.CMD in the PATH.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
include 'stdconst.e'            -- (needed for MB_ constants)
define INCLUDING_FILE = 'GROUPS.E'
const
   tryinclude 'MYCNF.E'        -- The user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'

defmain
   ''arg(1)
compile endif  -- not defined(SMALL)

; ---------------------------------------------------------------------------
const
; Ask to create a WPS object on the desktop?
compile if not defined(INCLUDE_DESKTOP_SUPPORT)
   INCLUDE_DESKTOP_SUPPORT = 1
compile endif
   CO_FAILIFEXISTS    = 0
   CO_REPLACEIFEXISTS = 1
   CO_UPDATEIFEXISTS  = 2
   GROUPS__MSG =    'Groups'  -- Messagebox title
   GR_SAVE_PROMPT = 'Save edit ring as a group - optionally to the desktop'
   GR_SAVE_PROMPT2 = 'The names and cursor positions of all files loaded will be saved'
   GR_LOAD_PROMPT = 'Load a previously saved group'
   GR_DELETE_PROMPT = 'OK to delete group:'
   GR_NONE_FOUND = 'No saved groups found'
; ---------------------------------------------------------------------------
; Toolbar actions
; ---------------------------------------------------------------------------
defc groups_actionlist
universal ActionsList_FileID  -- This is the fileid that gets the line(s)

insertline '|group_savegroup|'GR_SAVE_PROMPT'  'GR_SAVE_PROMPT2'|groups|', ActionsList_FileID.last+1, ActionsList_FileID
insertline '|group_loadgroup|'GR_LOAD_PROMPT'|groups|', ActionsList_FileID.last+1, ActionsList_FileID

; ---------------------------------------------------------------------------
defc group_savegroup
   parse arg action_letter parms
   if action_letter = 'S' then       -- button Selected
      sayerror 0
      'savegroup' parms
   elseif action_letter = 'I' then   -- button Initialized
      'SayHint' GR_SAVE_PROMPT
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(GROUPS__MSG, GR_SAVE_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

; ---------------------------------------------------------------------------
defc group_loadgroup
   parse arg action_letter parms
   if action_letter = 'S' then       -- button Selected
      sayerror 0
      'loadgroup' parms
   elseif action_letter = 'I' then   -- button Initialized
      'SayHint' GR_LOAD_PROMPT
   elseif action_letter = 'H' then   -- button Help
      call winmessagebox(GROUPS__MSG, GR_LOAD_PROMPT, MB_OK + MB_INFORMATION + MB_MOVEABLE)
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

; ---------------------------------------------------------------------------
compile if not defined(SMALL)  -- If being separately compiled separately, LOADGROUP command
                               -- might not be known - execute via our DEFMAIN.
   define loadgroup_cmd = 'groups loadgroup'
compile else
   define loadgroup_cmd = 'loadgroup'
compile endif

; ---------------------------------------------------------------------------
defc SaveGroup
   universal app_hini
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Groups'

   getfileid startfid
   dprintf( 'RINGCMD', 'SaveGroup 1')
   do i = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      if .filename = GetUnnamedFilename() then
         if .last <> 1 or textline(1) <> '' then
            activatefile startfid
            sayerror 'An unnamed file exists in the ring;' ||
                     ' it must have a name to save the ring.'
            return
         endif
      endif
      next_file
      getfileid curfid
      if curfid = startfid then
         leave
      endif
   enddo  -- Loop through all files in ring

   group_name = arg(1)
   if group_name = '' then
      group_name = entrybox('Group name')
   endif
   if group_name = '' then
      return
   endif
   tempstr = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'group_name'\Entries')
   if tempstr <> '' then
      if MBID_OK <> winmessagebox( 'Save Group',
                                   'Group already exists.  OK to replace it?',
                                   MB_OKCANCEL + MB_ICONEXCLAMATION + MB_MOVEABLE) then
         return
      endif
   endif

   -- Select next file, so that previous selected file will be the last one reloaded
   next_file
   getfileid firstfid
   -- Write all FILEi and POSNi to EPM.INI
   n = 0
   dprintf( 'RINGCMD', 'SaveGroup 2')
   do i = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      Ignore = ((leftstr( .filename, 1) = '.') | (not .visible))
      if not Ignore then
         n = n + 1
         NepmdWriteConfigValue( nepmd_hini, KeyPath'\'group_name'\File'n, .filename)
         NepmdWriteConfigValue( nepmd_hini, KeyPath'\'group_name'\Posn'n, .line .col .cursorx .cursory)
      endif
      next_file
      getfileid curfid
      if curfid = firstfid then
         leave
      endif
   enddo  -- Loop through all files in ring
   NepmdWriteConfigValue( nepmd_hini, KeyPath'\'group_name'\Entries', n)
   activatefile startfid

   -- Remove the rest
   if (tempstr <> '') & (tempstr > i) then
      do j = n + 1 to tempstr
         NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'group_name'\File'j)
         NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'group_name'\Posn'j)
      enddo
   endif

compile if INCLUDE_DESKTOP_SUPPORT -- Ask whether to include on Desktop?
   if MBID_YES = winmessagebox( 'Save Group',
                                'Add a program object to the OS/2 desktop' ||
                                ' for this group?',
                                16404) then  -- MB_YESNO + MB_ICONQUESTION + MB_MOVEABLE
/*
      tib_ptr = 1234                -- 4-byte place to put a far pointer
      pib_ptr = 1234
      call dynalink32( 'DOSCALLS',  -- dynamic link library name
                       '#312',      -- ordinal value for DOS32GETINFOBLOCKS
                    address(tib_ptr) ||
                    address(pib_ptr) )
;     sayerror 'tib_ptr =' c2x(tib_ptr) 'pib_ptr =' c2x(pib_ptr)
      pib = peek( itoa( rightstr( pib_ptr, 2), 10),
                  itoa( leftstr( pib_ptr, 2), 10), 28)
      epm_exe = peekz( substr( pib, 13, 4))  -- that's the EPM executable, but we need the loader
*/
      epm_exe = 'EPM.EXE'  -- No path required
      class_name = "WPProgram"\0
                      -- ^ = ASCII 94 = 'hat'
      title = "EPM Group:^"group_name\0
      setup_string = "EXENAME="epm_exe";"        ||
                     "PROGTYPE=PM;"              ||
                     "STARTUPDIR="directory()";" ||
                     "PARAMETERS='"loadgroup_cmd group_name"';"\0
      location = "<WP_DESKTOP>"\0
      rc = 0
      hobj = dynalink32( 'PMWP',      -- dynamic link library name
                         '#281',      -- 'WinCreateObject'
                         address(class_name)   ||
                         address(title)        ||
                         address(setup_string) ||
                         address(location)     ||
                         atol(CO_REPLACEIFEXISTS), 2)
;     if rc then hobj = hobj'; rc = 'rc '-' sayerrortext(rc); endif
;     sayerror 'hobject =' hobj
      if not hobj then
         sayerror 'Unable to create the program object on the Desktop'
      endif
   endif
compile endif  -- INCLUDE_DESKTOP_SUPPORT

; ---------------------------------------------------------------------------
defc LoadGroup
   universal app_hini
   universal nepmd_hini
   universal CurEditCmd
   KeyPath = '\NEPMD\User\Groups'

   getfileid startfid
   group_name = arg(1)

   if (group_name = '') | (group_name = '?') then
/*
      -- Entry box disabled. Always start with the list box now.
      if group_name = '' then
         parse value entrybox( 'Specify a group name    ',
                               '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/',
                               '', '', 64,   -- Entrytext, cols, maxchars
                               atoi(1) ||
                               atoi(0000) ||
                               gethwndc(APP_HANDLE)) with button 2 group_name \0
      else
*/
         button = \2
/*
      endif
*/

      if button = \2 then -- User asked for a list
         bufhndl = buffer( CREATEBUF, 'groups', MAXBUFSIZE, 1)  -- Create a private buffer

         -- Get first saved group name for testing only
         next = ''
         if not NepmdGetNextConfigKey( nepmd_hini, KeyPath, 'C', next) then
            sayerror GR_NONE_FOUND
            return
         endif

         -- Create a tmp file
         'xcom e /c /q tempfile'
         if rc <> -282 then  -- sayerror('New file')
            sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
            call buffer( FREEBUF, bufhndl)
            return
         endif
         .autosave = 0
         browse_mode = browse()     -- query current state
         if browse_mode then
            call browse(0)
         endif

         -- Get all saved group names and write them to the tmp file
         do forever
            insertline next, .last + 1
            if not NepmdGetNextConfigKey( nepmd_hini, KeyPath, 'C', next) then
               leave
            endif
         enddo

         if .last > 2 then  -- E always creates a file with an empty line
            getfileid fileid
            call sort( 2, .last, 1, 40, fileid, 'I')
         endif
         if browse_mode then
            call browse(1)
         endif  -- restore browse state

         if .last = 1 then
            'xcom quit'
            call winmessagebox( GROUPS__MSG,
                                GR_NONE_FOUND,
                                MB_CANCEL + MB_ICONEXCLAMATION + MB_MOVEABLE)
            return
         endif

         -- Fill buffer with and quit tmp file
         if listbox_buffer_from_file( startfid, bufhndl, noflines, usedsize) then
            return
         endif
         parse value listbox( 'Select group name',
                              \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                              '/~Load/~Delete.../'Cancel__MSG,  -- buttons
                              0, 0,  -- 1, 35,               -- row, col,
                              min( noflines, 12), 0,         -- height, width
                              gethwndc(APP_HANDLE) || atoi(1) || atoi(1) ||
                              atoi(0000)) with button 2 group_name \0
         call buffer( FREEBUF, bufhndl)

         if button = \2 then -- 'Delete' selected
            if MBID_OK <> winmessagebox( GROUPS__MSG,
                                         GR_DELETE_PROMPT\10 group_name,
                                         MB_OKCANCEL + MB_QUERY + MB_MOVEABLE) then
               return
            endif
            -- Delete KeyPath'\'group_name from nepmd_hini
            -- Query all subpaths and delete them first
            do forever
               next2 = ''  -- always restart the query, since list was changed by the deletion
               if NepmdGetNextConfigKey( nepmd_hini, KeyPath'\'group_name, 'K', next2) then
                  NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'group_name'\'next2)
               else
                  leave
               endif
            enddo
            -- Open list box again
            'postme groups loadgroup ?'
            return
         endif  -- button = \2 (Delete)
      endif  -- button = \2 (List)

      if button <> \1 then
         return
      endif
   endif

   if group_name = '' then
      return
   endif

   howmany = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'group_name'\Entries')
   if rc then
      sayerror 'Group unknown'
      return
   endif
   if howmany = '' then
      sayerror 'Group unknown'
      return
   endif
   do i = 1 to howmany
      'SayHint Loading file' i 'of' howmany
      this_file = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'group_name'\File'i)

      if leftstr( this_file, 5) = '.DOS ' then
         subword( this_file, 2)  -- execute the command
      elseif this_file = GetUnnamedFilename() then
         'xcom e /n'
      else
         'e "'this_file'"'
         CurEditCmd = 'LOADGROUP'  -- must follow the 'edit' cmd
      endif
      if not rc | rc = sayerror('Lines truncated') then
         this_posn = NepmdQueryConfigValue( nepmd_hini, KeyPath'\'group_name'\Posn'i)
         call prestore_pos(this_posn)
      endif
   enddo

; ---------------------------------------------------------------------------
defc ListGroups
   universal nepmd_hini

   KeyPath = '\NEPMD\User\Groups'
   next   = ''
   Groups = ''
   do while NepmdGetNextConfigKey( nepmd_hini, KeyPath, 'C', next)
      if Groups = '' then
         Groups = next
      else
         Groups = Groups next
      endif
   enddo
   sayerror 'List of groups is:' groups

; ---------------------------------------------------------------------------
defc KillGroup
   universal nepmd_hini

   do i = 1 to 1

      Group = arg(1)
      if Group = '' then
         sayerror "Error: no group name specified."
         leave
      endif

      KeyPath = '\NEPMD\User\Groups'
      next   = ''
      if not NepmdGetNextConfigKey( nepmd_hini, KeyPath, 'C', next) then
         sayerror "Error: group "Group" doesn't exist."
         leave
      endif

      -- Delete KeyPath'\'group_name from nepmd_hini
      -- Query all subpaths and delete them first
      do forever
         next2 = ''  -- always restart the query, since list was changed by the deletion
         if NepmdGetNextConfigKey( nepmd_hini, KeyPath'\'Group, 'K', next2) then
            NepmdDeleteConfigValue( nepmd_hini, KeyPath'\'Group'\'next2)
         else
            leave
         endif
      enddo

   enddo

