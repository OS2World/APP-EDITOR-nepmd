/****************************** Module Header *******************************
*
* Module Name: epmshell.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmshell.e,v 1.30 2006-07-09 10:03:24 aschn Exp $
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

; Contains defmodify. Therefore it should not be linked, because any
; occurance of defmodify in a linked module would replace all other
; so-far-defined defmodify event defs.

; Todo:
; defc Shell
;    Add an optional param <workdir> before <command>. Workdir must be fully
;    qualified or start with . or .. or \ to get recognized. Enable spaces
;    in workdir.

; ---------------------------------------------------------------------------
; Some ShellKram macros added. See SHELLKEYS.E for key definitions.
; SHELLKRAM.E was available from Joerg Tiemann's homepage some years ago:
; http://home.foni.net/~tiemannj/epm/index.html
; See his pages for documentation.

; ---------------------------------------------------------------------------
; This should always be used in preference to query if current file is a
; shell.
defproc IsAShell
   ret = 0
   Filename = arg(1)
   if Filename = '' then
      Filename = .filename
   endif
   getfileid fid, Filename
   ShellNum = GetAVar( 'ShellNum.'fid)
   if ShellNum > '' then
      ShellHandle = GetAVar( 'Shell_h'ShellNum)
      if ShellHandle > '' then
         ret = 1
      endif
   endif
   return ret

; ---------------------------------------------------------------------------
; Used by defproc GetMode only to determine the default mode for it.
defproc IsAShellFilename
   ret = 0
   Filename = arg(1)
   if Filename = '' then
      Filename = .filename
   endif
   Name = StripPath( Filename)
   if leftstr( Name, 15) = '.command_shell_' then
      ret = 1
   endif
   return ret

; ---------------------------------------------------------------------------
; Reactivate a shell window, if no ShellHandle exists.
; Process that at defselect rather than at defload to save file loading time.
definit
   'HookAdd select MaybeStartShell'

; ---------------------------------------------------------------------------
; Starts a new shell for the current file, if not already done and if Mode =
; SHELL. Can be used to "reactivate" a shell, whose .command_shell_ output
; was saved before and then gets reloaded.
defc MaybeStartShell
   universal shell_index
   Mode = GetMode()
   if Mode = 'SHELL' then
      if not IsAShell() then
         'monofont'
         shell_index = shell_index + 1
         ShellHandle  = '????'
         retval = SUE_new( ShellHandle, shell_index)
         if retval then
            sayerror ERROR__MSG retval SHELL_ERROR1__MSG
         else
            getfileid ShellFid
            --sayerror 'Shell handle with number' shell_index 'created'
            .autosave = 0
            call SetAVar( 'Shell_f'shell_index, ShellFid)
            call SetAVar( 'Shell_h'shell_index, ShellHandle)
            call SetAVar( 'ShellNum.'ShellFid, shell_index)
            InitCmd = ''
compile if EPM_SHELL_PROMPT <> ''
            InitCmd = EPM_SHELL_PROMPT
compile endif
            if InitCmd > '' then
               'shell_write' shell_index InitCmd
            endif

            -- Determine previous work dir
            call psave_pos( save_pos)
            display -3
            .lineg = .last
            endline
            fFound = (ShellGotoNextPrompt( 'P') = 0)
            Dir = ''
            Cmd = ''
            if fFound then
               call ShellParsePromptLine( Dir, Cmd)
            else
               call prestore_pos( save_pos)
            endif
            display 3
            if Dir > '' then
               CdCmd = 'cdd' Dir
               'shell_write' shell_index CdCmd
            endif
         endif
      endif
   endif

-------------------------------------------------------------Shell-----------------------
; Starts a new shell object or re-uses the last shell (default).
; Syntax: shell [new] [<command>]
; shell_index is the number of the last created shell, <shellnum>.
; The array var 'Shell_f'<shellnum> holds the fileid, 'Shell_h'<shellnum> the handle.
;
; ECHO must be ON. That is the default setting in CMD.EXE, but not in 4OS2.EXE.
; Otherwise no prompt is inserted after the command execution and further commands
; won't work (CMD.EXE) or the command is deleted (4OS2.EXE).
; Therefore ECHO ON must be executed _after_ every call of 4OS2.EXE.
defc Shell
   universal shell_index
   universal ring_enabled

   if not ring_enabled then
      'ring_toggle'
   endif

   fCreateNew = 0
   args = arg(1)
   wp = wordpos( 'NEW', upcase( args))
   if wp then
      fCreateNew = 1
      args = delword( args, wp, 1)
   endif
   Cmd = strip( args)

   if fCreateNew = 0 then
      getfileid ShellFid, '.command_shell_'shell_index
      if shell_index < 1 then
         fCreateNew = 1
      elseif not ShellFid then
         fCreateNew = 1
      endif
   endif

   if fCreateNew = 1 then
      shell_index = shell_index + 1
      ShellHandle  = '????'
      retval = SUE_new( ShellHandle, shell_index)
      if retval then
         sayerror ERROR__MSG retval SHELL_ERROR1__MSG
      else
         'xcom e /c .command_shell_'shell_index
         if rc <> sayerror( 'New file') then
            sayerror ERROR__MSG rc SHELL_ERROR2__MSG
            stop
         endif
         getfileid ShellFid
         .filename = '.command_shell_'shell_index
         .autosave = 0
         call SetAVar( 'Shell_f'shell_index, ShellFid)
         call SetAVar( 'Shell_h'shell_index, ShellHandle)
         call SetAVar( 'ShellNum.'ShellFid, shell_index)
         'postme monofont'
compile if EPM_SHELL_PROMPT <> ''
         InitCmd = EPM_SHELL_PROMPT
         'shell_write' shell_index InitCmd
compile endif
      endif
;;    sayerror "shellhandle=0x" || ltoa(ShellHandle, 16) || "  newObject.retval="retval;
   else
      activatefile ShellFid
   endif
   if Cmd then
      'shell_write' shell_index Cmd
   endif

-------------------------------------------------------------Shell_Kill------------------
; Destroys a shell object.
; Syntax: shell_kill [<shellnum>]
defc Shell_Kill
   parse arg ShellNum .
   if ShellNum = '' & IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   ShellFid     = GetAVar( 'Shell_f'ShellNum)
   ShellHandle  = GetAVar( 'Shell_h'ShellNum)
   if ShellHandle <> '' then
      retval = SUE_free( ShellHandle)
      if retval then
         sayerror ERROR__MSG retval SHELL_ERROR3__MSG
      endif
      call SetAVar( 'Shell_h'ShellNum, '')
   endif
   if ShellFid <> '' then
      getfileid curfid
      activatefile ShellFid
      .modify = 0
      'xcom quit'

      call SetAVar( 'Shell_f'ShellNum, '')
      call SetAVar( 'Shell_h'ShellNum, '')
      call SetAVar( 'ShellNum.'ShellFid, '')
      if curfid <> ShellFid then
         activatefile curfid
      endif
   endif

; ---------------------------------------------------------------------------
; Write to current shell the text of current line, starting at cursor
defc sendshell
   if not IsAShell() then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   getfileid ShellFid
   ShellNum = GetAVar( 'ShellNum.'ShellFid)
   'shell_write' ShellNum substr( textline(.line), .col)

-------------------------------------------------------------Shell_Write-----------------
; Syntax: shell_write [<shellnum>] [<text>]
; If first word is not a number, then last opened shell will be used as <shellnum>.
; If <text> is missing, the 'Write to shell' EntryBox opens.
defc Shell_Write
   universal ShellHandle
   universal Shell_lastwrite
   parse arg ShellNum Text
   if not isnum( ShellNum) & IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
      parse arg Text
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   getfileid ShellFid
   ShellAppWaiting = GetAVar( 'ShellAppWaiting.'ShellFid)
   ShellHandle = GetAVar( 'Shell_h'ShellNum)
   if ShellHandle <> '' then
      if Text = '' & words( ShellAppWaiting) < 2 then  -- disable this silly box for Return in a waiting shell
         shell_title = strip( WRITE_SHELL_MENU__MSG, 'T', '.')  -- '~Write to shell...'
         tilde = pos( '~', shell_title)
         if tilde then
            shell_title = delstr( shell_title, tilde, 1)
         endif
         do forever
            parse value entrybox( shell_title,                  -- Title,
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
                                  '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/', -- Buttons
compile else
                                  '/'OK__MSG'/'Cancel__MSG'/',  -- Buttons
compile endif
                                  Shell_lastwrite,              -- entrytext
                                  '', 254,                      -- cols, maxchars
                                  atoi(1) || atoi(0000) || gethwndc(APP_HANDLE) ||
                                  SHELL_PROMPT__MSG ShellNum) with button 2 text \0
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
            if button=\2 then -- User asked for a list
               getfileid shell_fileid
               call psave_pos(save_pos)
               'xcom e /c cmdslist'
               if rc <> -282 then  -- -282 = sayerror("New file")
                  sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
                  return
               endif
               browse_mode = browse()     -- query current state
               if browse_mode then call browse(0); endif
               .autosave = 0
               getfileid lb_fid
               activatefile shell_fileid
               display -2
               getsearch oldsearch
               0
 compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
               'xcom l /^epm\: .*>:o./x'
 compile else  -- else EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
               'xcom l /^\[epm\: .*\]:o./x'
 compile endif -- EPM_SHELL_PROMPT
               do while rc = 0
 compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
                  parse value textline(.line) with '>' cmd
 compile else
                  parse value textline(.line) with ']' cmd
 compile endif -- EPM_SHELL_PROMPT
                  insertline strip( cmd, 'L'), lb_fid.last + 1, lb_fid
                  repeatfind
               enddo
               setsearch oldsearch
               call prestore_pos(save_pos)
               if browse_mode then call browse(1); endif  -- restore browse state
               activatefile lb_fid
               display 2
               if not .modify then  -- Nothing added?
                  'xcom quit'
                  activatefile shell_fileid
                  sayerror -273 -- String not found
                  return
               endif
               if listbox_buffer_from_file( shell_fileid, bufhndl, noflines, usedsize) then return; endif
               parse value listbox( shell_title,
                                    \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                                    '/'OK__MSG'/'EDIT__MSG'/'Cancel__MSG,
                                    1, 35,
                                    min(noflines,12), 0,
                                    gethwndc(APP_HANDLE) || atoi(1) || atoi(1) ||
                                    atoi(0000)) with button 2 Text \0
               call buffer( FREEBUF, bufhndl)
               if button = \2 then -- 'Edit' selected
                  Shell_lastwrite = Text
                  iterate
               endif
            endif
compile endif
            if button <> \1 then return; endif
            leave
         enddo
      endif  -- text = ''
;     if Text = '' then return; endif
      if Text <> '' then Shell_lastwrite = text; endif
      writebuf = text\13\10
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'Shell_Write: rc =' retval', byteswritten =' bytesmoved 'of' length(writebuf)
         'Shell_Break'
      endif
   endif
   --
   -- the above code is not really complete.  It should also deal with situations
   --   where only part of the data to be written is written.  It needs to keep the
   --   unwritten data around and put it out again during the "NowCanWriteShell"
   --   comand processing. (todo)

-------------------------------------------------------------NowCanWriteShell------------
; Shell object sends this command to inform the editor that there is
; room for additional data to be written.
defc NowCanWriteShell
   sayerror SHELL_OBJECT__MSG arg(1) SHELL_READY__MSG -- Use Shell_Write with argumentstring'

-------------------------------------------------------------NowCanReadShell-------------
; Shell object sends this command to inform the editor that there is
; additional data to be read.
; Fixed to handle LF-terminated lines correctly.
; Recognize if an app is waiting for user input (then last line is not the EPM prompt).
; Set ShellAppWaiting to 0 or to line and col.
; Right margin setting of current shell is not respected.
defc NowCanReadShell
   parse arg shellnum .
   if not isnum(shellnum) then
      sayerror 'NowCanReadShell:  'INVALID_ARG__MSG '"'arg(1)'"'
      return
   endif
   call DisableUndoRec()  -- no effect

   lastline = ''
   ShellFid    = GetAVar( 'Shell_f'shellnum)
   ShellHandle = GetAVar( 'Shell_h'shellnum)
   bytesmoved = 1
   while bytesmoved do
      readbuf = copies( ' ', MAXCOL)
      retval = SUE_readln( ShellHandle, readbuf, bytesmoved);
      readbuf = leftstr( readbuf, bytesmoved)
      if readbuf = \13
         then iterate           -- ignore CR
      endif
      -- SUE_readln doesn't handle LF as line end, received from the app.
      -- It won't initiate a NowCanReadShell at Unix line ends.
      -- Therefore it must be parsed here again.
      -- BTW: MORE.COM has the same bug.
      rest = readbuf
      -- "do while rest <> ''" is too slow here. It has caused following issue:
      -- The prompt after executing a start command (maybe "start epm config.sys")
      -- changed to "epm:F:\>" instead of "epm: F:\ >". This should be fixed now.
      -- But the main problem still remains (EPM bug):
      -- After a "start epm" command, SUE_readln sends all data very slowly, sometimes
      -- byte per byte. This can be checked by undoing the output of a "dir" command.
      -- A new undo state is created for every line of the dir output then.
      do forever
         -- Search for further <LF> chars; <LF> at pos 1 is handled
         -- by the original code itself
         p = pos( \10, rest, 2)
         if p > 0 then
            next = leftstr( rest, p - 1)
            rest = substr( rest, p)
         else
            next = rest
            rest = ''
         endif
         if leftstr( next, 1) = \10 then  -- LF is lineend
            insertline substr( next, 2), shellfid.last+1, shellfid
         else
            getline oldline, shellfid.last, shellfid
            if length(oldline) + length(next) > MAXCOL then
               insertline next, shellfid.last+1, shellfid
            else
               replaceline oldline''next, shellfid.last, shellfid
            endif
         endif
         if rest = '' then
            getline lastline, shellfid.last, shellfid
            shellfid.line = shellfid.last
            shellfid.col = min( MAXCOL, length(lastline) + 1)
            -- Following added because "do while rest <> ''" was too slow:
            leave
         endif
      enddo
   endwhile

   -- Check if last written line was the EPM prompt
   -- in order to accept input by a waiting application directly
   -- in the shell window, not only in the Write to shell dialog.
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   p1 = leftstr( lastline, 5) = 'epm: '
   p2 = rightstr( strip( lastline, 't'), 1) = '>'
compile else  -- else EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
   p1 = leftstr( lastline, 6) = '[epm: '
   p2 = rightstr( strip( lastline, 't'), 1) = ']'
compile endif -- EPM_SHELL_PROMPT
   -- set array var
   if p1 > 0 & p2 > 0 then
      -- set to 0
      ShellAppWaiting = 0
;      sayerror 'app terminated'
   else
      -- set to '.line .col' if app is waiting for user input
      ShellAppWaiting = shellfid.line shellfid.col
;      sayerror 'app waiting for input or further output will follow'
   endif
   getfileid fid
   call SetAVar( 'ShellAppWaiting.'fid, ShellAppWaiting)  -- save

   -- This is done automatically after a command has finished, maybe
   -- avoiding it here can help to reduce undo states:
   --call EnableUndoRec()

; ---------------------------------------------------------------------------
; Write user input to the shell if EPM prompt is in current line.
; Enhanced for filename completion. Prepend 'cd ' to input if a directory.
; Remove trailing \ from directories for 'cd'.
; Works with spaces in filenames and surrounding "...".
; This is the defproc called by the Enter key def.
; Returns 0 on success; 1 when not on a EPM prompt line.
; If 1 is returned, then ShellEnterWriteToApp() should be called by the
; Enter key def.
defproc ShellEnterWrite
   ret = 1
   getfileid ShellFid
   ShellNum = GetAVar( 'ShellNum.'ShellFid)
   x = ShellPromptPos()
   if x then
      getline line
      Text = substr( line, x + 1)
      Text = strip( Text, 'L')

      -- Parse Text into CmdWord and CmdArgs
      if leftstr( Text, 1) = '"' then
         parse value Text with '"'CmdWord'"' CmdArgs
      else
         parse value Text with CmdWord CmdArgs
      endif

      CmdName = upcase( StripExt( StripPath( CmdWord)))

      -- Re-surround CmdWord with "..." if spaces
      if pos( ' ', CmdWord) then
         CmdWord = '"'CmdWord'"'
      endif

      -- Prepend "cd" if no CmdName given (true for a trailing '\')
      if CmdName = '' & CmdWord <> '' & CmdArgs = '' then
         CmdArgs = CmdWord
         CmdWord = 'cd'
         CmdName = 'CD'
      endif

      if CmdName = 'CD' then
         -- Strip "..." from CmdArgs
         if leftstr( CmdArgs, 1) = '"' then
            parse value CmdArgs with '"'CmdArgs'"'
         endif
         -- Strip trailing \ from CmdArgs
         if rightstr( CmdArgs, 1) = '\' &
            CmdArgs <> '\' &
            rightstr( CmdArgs, 2) <> ':\' then
            CmdArgs = strip( CmdArgs, 'T', '\')
         endif
         -- Surround with "..." if CmdArgs contains spaces
         if pos( ' ', CmdArgs) then
            CmdArgs = '"'CmdArgs'"'
         endif
      endif

      if CmdName = '4OS2' then
         -- Insert "echo on" when 4os2 is called
         if CmdArgs = '' then
            CmdArgs = 'echo on'
         else
            CmdArgs = 'echo on&'CmdArgs
         endif
      endif

      Text = CmdWord
      if CmdArgs > '' then
         Text = Text CmdArgs
      endif

      if .line = .last then
         --.col = x + 1
         .col = x + 2    -- Prompt || Space
         erase_end_line  -- Delete the rest, because echo is on to avoid
                         -- doubled Cmd.
                         -- Echo off, executed in CMD.EXE, would suppress the
                         -- prompt as well.
      else
          -- The Undo statement doesn't restore the prompt line well (only
          -- last change, depending on .modify). Therefore the line is
          -- restored by an array var, set by the defproc for the Enter key.
         'postme ShellRestoreOrgCmd' .line
      endif
      'shell_write' ShellNum Text
      ret = 0
   endif
   return ret

; ---------------------------------------------------------------------------
; Restore line number = arg(1) to its state saved in ShellOrgCmd.
defc ShellRestoreOrgCmd
   getfileid fid
   ShellOrgCmd = GetAVar( 'ShellOrgCmd.'fid)
   l = arg(1)
   parse value ShellOrgCmd with line cmd
   if line = l then
      saved_line = .line
      .lineg = l
      x = ShellPromptPos()
      replaceline substr( textline( l), 1, x)' 'cmd, l  -- Prompt || Space || Cmd
      .lineg = saved_line
   endif

; ---------------------------------------------------------------------------
; Write user input to a prompting (waiting) app.
; For differing the output that comes from the app from the user input, the
; array var "ShellAppWaiting" is used. It holds line and col from the last
; write of the shell object to the EPM window, set in defc NowCanReadShell.
; In case of a terminated app the EPM prompt was the last output and
; ShellAppWaiting holds the value 0.
; Returns 0 on success; 1 when no app is waiting.
defproc ShellEnterWriteToApp
   ret = 1
   getfileid ShellFid
   ShellNum = GetAVar( 'ShellNum.'ShellFid)
   ShellAppWaiting = GetAVar( 'ShellAppWaiting.'ShellFid)
   if words( ShellAppWaiting) = 2 then
      parse value ShellAppWaiting with lastl lastc
      Text = ''
      l = lastl
      do while l <= .line
         getline line, l
         if l = lastl then
            startc = lastc
         else
            startc = 1
         endif
         Text = Text''substr( line, startc)
         if l = .last then
            insertline '', .last + 1
            leave
         else
            l = l + 1
         endif
      enddo
      'shell_write' ShellNum Text
      ret = 0
   endif
   return ret

-------------------------------------------------------------SUE_new---------------------
; Called from Shell command
defproc SUE_new( var shell_handle, shellnum)
   thandle = '????'
;; sayerror "address=0x" || ltoa(taddr, 16) || "  hwnd=0x"ltoa(hwnd, 16);
   result = dynalink32( ERES_DLL,
                         'SUE_new',
                         address(thandle)             ||
                         gethwndc(EPMINFO_EDITCLIENT) ||
                         atol(shellnum))
   shell_handle = thandle
   return result

-------------------------------------------------------------SUE_free--------------------
; Called from Shell_Kill command
defproc SUE_free( var shell_handle)
   thandle = shell_handle
   result = dynalink32( ERES_DLL,
                        'SUE_free',
                        address(thandle))
   shell_handle = thandle
   return result

-------------------------------------------------------------SUE_readln------------------
; Called from NowCanReadShell cmd
defproc SUE_readln( shell_handle, var buffe, var bytesmoved)
   bufstring = buffe  -- just to insure the same amount of space is available
   bm        = "??"
   result = dynalink32( ERES_DLL,
                        'SUE_readln',
                        shell_handle            ||
                        address(bufstring)      ||
                        atol(length(bufstring)) ||
                        address(bm))
   bytesmoved = itoa( bm, 10)
   buffe      = bufstring
   return result

-------------------------------------------------------------SUE_write-------------------
; Called from Shell_Write command
defproc SUE_write( shell_handle, buffe, var bytesmoved)
   bm     = "??"
   result = dynalink32( ERES_DLL,
                        'SUE_write',
                        shell_handle        ||
                        address(buffe)      ||
                        atol(length(buffe)) ||
                        address(bm))
   bytesmoved = itoa( bm, 10);
   return result;

-------------------------------------------------------------Shell_Break-----------------
; Sends a Break to a shell object
defc shell_break
   parse arg shellnum .
   if ShellNum = '' & IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   ShellHandle = GetAVar( 'Shell_h'ShellNum)
   if ShellHandle = '' then
      return
   endif

   -- Confirm on a prompt line
   if ShellPromptPos() then
      refresh
      if MBID_OK <> winmessagebox( 'Sending a Break signal not required',  -- title
                                   'Apparently you are on a prompt line and there is'\n ||
                                   'no action to send a Break to.'\n\n                  ||
                                   'Do you really want to send a Break signal?',
                                   MB_OKCANCEL + MB_QUERY + MB_DEFBUTTON1 + MB_MOVEABLE)
      then
         return
      endif
   endif

   -- Send a break signal to the shell object
   retval = SUE_break( ShellHandle)
   if retval then
      if retval = 162 then
         sayerror 'A signal is already pending, rc = 'retval' from SUE_break'
      else
         -- rc = 184 here means either: No process to break or Break not possible.
         sayerror ERROR__MSG retval 'sending break to 'SHELL_OBJECT__MSG
      endif

      -- Pop up a MsgBox and ask the user before killing the shell
      -- Sideeffect: the command is paused.
      refresh
      if MBID_OK <> winmessagebox( 'Error sending Break signal',  -- title
                                   'The Break signal, sent to the shell object, was'\n ||
                                   'not successfully, at least not immediately.'\n\n   ||
                                   'Do you want to restart the shell object?'\n        ||
                                   '(The path will be restored, but any special'\n     ||
                                   'environment will be lost.)',
                                   MB_OKCANCEL + MB_QUERY + MB_DEFBUTTON1 + MB_MOVEABLE)
      then
         return
      endif

      -- Kill the shell
      -- Sending the kill signal will force a kill immediately
      retval = SUE_free( ShellHandle)
      if retval then
         if retval = 162 then
            sayerror 'A signal is already pending, rc = 'retval' from SUE_free'
         elseif retval = 184 then
            sayerror 'Shell object is already killed, rc = 'retval' from SUE_free'
         else
            sayerror ERROR__MSG retval SHELL_ERROR3__MSG
         endif
         -- Ignore errors here, most likely the shell object will be killed delayed
      else
         sayerror 'Shell object was killed successfully'
      endif

      -- Create a new shell object, keeping ShellNum
      ShellHandle  = '????'
      retval = SUE_new( ShellHandle, ShellNum)
      if retval then
         sayerror ERROR__MSG retval SHELL_ERROR1__MSG
      else
         call SetAVar( 'Shell_h'ShellNum, ShellHandle)
         InitCmd = ''
compile if EPM_SHELL_PROMPT <> ''
         InitCmd = EPM_SHELL_PROMPT
compile endif
         if InitCmd > '' then
            'shell_write' ShellNum InitCmd
         endif

         -- Determine previous work dir
         call psave_pos( save_pos)
         display -3
         .lineg = .last
         endline
         fFound = (ShellGotoNextPrompt( 'P') = 0)
         Dir = ''
         Cmd = ''
         if fFound then
            call ShellParsePromptLine( Dir, Cmd)
         else
            call prestore_pos( save_pos)
         endif
         display 3
         if Dir > '' then
            CdCmd = 'cdd' Dir
            'shell_write' ShellNum CdCmd
         endif
      endif

   endif

-------------------------------------------------------------SUE_break-------------------
defproc SUE_break(shell_handle)
   return dynalink32( ERES_DLL,
                      'SUE_break',
                      shell_handle)

; ---------------------------------------------------------------------------
; Reset modified state to avoid the dialog on quit.
; Save the original command text, if on a prompt line, and if not already
; saved before. The array var 'ShellOrgCmd.'fid is used later by
; ShellRestoreOrgCmd, called by ShellEnterWrite.
defmodify
   if IsAShell() then
      if .line <> .last then  -- last line has only the prompt, never a Cmd
         getfileid fid
         ShellOrgCmd = GetAVar( 'ShellOrgCmd.'fid)
         parse value ShellOrgCmd with line .
         if line <> .line then
            p = ShellPromptPos()
            if p then
               -- Get OldCmd only if new text was entered
               NewCmd = substr( textline( .line), p + 1)
               if strip( NewCmd) <> '' then
                  undoaction 1, junk
                  undoaction 6, StateRange               -- query range
                  parse value StateRange with oldeststate neweststate
                  prevstate = max( neweststate - 1, oldeststate)
                  undoaction 7, prevstate
                  OldCmd = strip( substr( textline( .line), p + 1), 'l')
                  if OldCmd > '' then
                     ShellOrgCmd = .line OldCmd
                     call SetAVar( 'ShellOrgCmd.'fid, ShellOrgCmd)
                  endif
                  undoaction 7, neweststate
               endif
            endif
         endif
      endif
      -- Avoid the dialog on quitting only for newly created shell windows,
      -- not for reactivated ones
      if leftstr( .filename, 1) = '.' then
         .modify = 0
         'ResetDateTimeModified'
         'refreshinfoline MODIFIED'
      endif
   endif

; ---------------------------------------------------------------------------
; This command can be used as key command, maybe for Esc.
; Syntax: shell_commandline [<shellnum>] [<text>]
defc shell_commandline
   parse arg ShellNum text
   if not isnum( ShellNum) & IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
      parse arg Text
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   'commandline shell_write 'ShellNum' 'Text

; ---------------------------------------------------------------------------
; Returns 0 if not a shell,
; otherwise the .col for the end of the prompt (> or ]).
defproc ShellPromptPos
   if not IsAShell() then
      return 0
   endif
   line = arg(1)
   if line = '' then
      getline line
   endif
compile if not (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   return 1
compile endif
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   p = pos( '>',line)
compile else
   p = pos( ']',line)
compile endif
   text = substr( line, p + 1)
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   if leftstr( line, 5)='epm: ' & p then
compile else
   if leftstr( line, 6)='[epm: ' & p then
compile endif
      return p
   else
      return 0
   endif

; ---------------------------------------------------------------------------
; Move cursor to the start of the next prompt line. The prompt line must
; have a command behind the prompt.
; Optional arg is P (find previous prompt) to search backwards.
defproc ShellGotoNextPrompt
   if upcase( arg(1) = 'P') then
      direction = '-r'
   else
      direction = ''
   endif
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   'xcom l /^epm\: .*>:o/x'direction
compile else  -- else EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
   'xcom l /^\[epm\: .*\]:o/x'direction
compile endif -- EPM_SHELL_PROMPT
   return rc

; ---------------------------------------------------------------------------
; Parse current line and set Dir and Cmd via call by reference
defproc ShellParsePromptLine( var Dir, var Cmd)
compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
   parse value textline(.line) with 'epm:' Dir '>' Cmd
compile else
   parse value textline(.line) with 'epm:' Dir ']' Cmd
compile endif -- EPM_SHELL_PROMPT
   Dir = strip( Dir)
   Cmd = strip( Cmd)
   return

; ---------------------------------------------------------------------------
; Filename completion like in 4os2.
; Difference in sorting order: dirs come first and executables are sorted
; according to their appearance in EXE_MASK_LIST
const
compile if not defined(FNC_EXE_MASK_LIST)
   FNC_EXE_MASK_LIST      = '*.cmd *.exe *.com *.bat'
compile endif
compile if not defined(FNC_DIR_ONLY_CMD_LIST)
   FNC_DIR_ONLY_CMD_LIST  = 'CD'
compile endif
compile if not defined(FNC_FILE_ONLY_CMD_LIST)
   FNC_FILE_ONLY_CMD_LIST = ''
compile endif

defc ShellFncInit
   if IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   else
      return
   endif
   p = ShellPromptPos()
   if not p then
      return
   endif
   getline Line
   Prompt = leftstr( Line, p)
   PromptChar = substr( Prompt, p, 1)
   parse value Prompt with 'epm:' ShellDir (PromptChar)
   ShellDir = strip( ShellDir)
   -- Get the part of the line between prompt and cursor
   Text = substr( Line, p + 1, .col - 1 - p)
   -- Strip leading spaces only, because a trailing space identifies the word before
   -- to have ended:
   --    > dir |   ->   dir *
   --    > dir|    ->   dir*   (this will search for names starting with dir)
   Text = strip( Text, 'L')

   -- Todo:
   -- Find expression starting with ':\' or '\\' (FilePieth may be part of a parameter,
   -- e.g. -dd:\os2\apps or -d:d:\os2\apps)

   CmdPiece  = ''
   CmdWord   = ''
   FilePiece = ''
   -- Parse into CmdPiece and FilePiece
; Todo:
; Make options with filenames, not followed by a space, work
; app.exe -d*  -> CmdPiece = 'app.exe -d', FilePiece = '*'
   if rightstr( Text, 1) == ' ' then
      -- No FilePiece
      if words( Text) > 0 then
         CmdWord   = word( Text, 1)
         CmdPiece  = Text
      endif
   elseif rightstr( Text, 1) = '"' then
      -- FilePiece is last word in "..."
      next = leftstr( Text, length( Text) - 1)  -- strip last "
      lp = lastpos( '"', next)
      --dprintf( 'TabComplete', 'Text = ['Text'], lp = 'lp)
      FilePiece = substr( Text, lp + 1, length( Text) - lp - 1)
      if lp > 1 then
         CmdPiece = leftstr( Text, lp - 1)
         if pos( ' ', CmdPiece) then
            CmdWord = word( Text, 1)
         endif
      endif
   else
      -- FilePiece is last word
      if words( Text) = 1 then
         -- No CmdWord
         FilePiece = Text
      elseif words( Text) > 1 then
         CmdWord   = word( Text, 1)
         FilePiece = lastword( Text)
         lp = wordindex( Text, words( Text))
         CmdPiece  = leftstr( Text, lp - 1)
      endif
   endif
   --dprintf( 'TabComplete', 'CmdWord = ['CmdWord'], CmdPiece = ['CmdPiece'], FilePiece = ['FilePiece']')

   -- Construct fully qualified dirname to avoid change of directories, that
   -- doesn't work for UNC names.
   FileMask = FilePiece
   PrepMask = ''
   if not (substr( FilePiece, 2, 2) = ':\' | leftstr( FilePiece, 2) = '\\') then
      if leftstr( FilePiece, 1) = '\' then
         -- Prepend drive
         if substr( ShellDir, 2, 2) = ':\' then
            PrepMask = leftstr( ShellDir, 2)
            FileMask = PrepMask''FilePiece
;          -- Prepend host
;          elseif leftstr( ShellDir, 2) = '\\' then  -- not possible
;             parse value ShellDir with '\\'Server'\'Resource
;             if pos( '\', Resource) then
;                parse value Resource with Resource'\'rest
;             endif
;             PrepMask = '\\'Server'\'Resource
;             FileMask = PrepMask''FilePiece
         endif
      else
         -- Prepend ShellDir
         PrepMask = strip( ShellDir, 't', '\')'\'
         FileMask = PrepMask''FilePiece
      endif
   endif

   -- Resolve FileMask to valid names for DosFind*
   next = NepmdQueryFullName( FileMask)
   parse value next with 'ERROR:'rc
   if rc = '' then
      FileMask = next
   endif

   -- The here fully qualified filemask must be changed to a relative path later,
   -- if FilePiece was relative before.

   -- Rebuild array
   fAppendExeMask = 0
   fAppendAllMask = 0
   -- Append * to FileMask only, if no * or ? is present in last dir segment.
   UnAppFileMask = FileMask
   lp = lastpos( '\', FileMask)
   LastSegment = substr( FileMask, lp + 1)
   --dprintf( 'TabComplete', 'LastSegment = ['LastSegment']')
   if verify( LastSegment, '?*', 'M') then
      --dprintf( 'TabComplete', '1 (wildcards): FileMask = ['FileMask']')
   elseif CmdWord = '' then
      --dprintf( 'TabComplete', '2 (no CmdWord): AppendExeMask')
      fAppendExeMask = 1
   else
      fAppendAllMask = 1
   endif
   if fAppendExeMask | fAppendAllMask then
      --dprintf( 'TabComplete', '3 (no wildcard): FileMask before = ['FileMask']')
      -- Handling FAT different is not required:
;       FileSys = ''
;       if length( FileMask) > 1 then
;          if substr( FileMask, 2, 1) = ':' then
;             next = QueryFileSys( leftstr( FileMask, 2))
;             parse value next with 'ERROR:'rc0
;             if rc0 = '' then
;                FileSys = next
;             endif
;          endif
;       endif
;       if FileSys = 'FAT' then
;          FileMask = FileMask'*.*'
;       else
         FileMask = FileMask'*'
;       endif
      --dprintf( 'TabComplete', '3 (no wildcard): FileMask after  = ['FileMask']')
   endif

   -- Delete old array
   cTotal = GetAVar( 'FncFound.0')
   if cTotal > '' then
      do i = 1 to cTotal
         call SetAVar( 'FncFound.'i, '')
      enddo
   endif
   call SetAVar( 'FncFound.0', '')
   call SetAVar( 'FncFound.last', '')

   -- Find dirs and files
   rc1 = ''
   rc2 = ''
   handle = 0  -- handle must be reset to 0 before the search
   c = 0  -- number of found names
   m = 0  -- item number of ExeMaskList
   f = 0  -- number of found items per FileMask, only used for debugging
   do forever
      Name = ''
      if rc1 = '' & wordpos( upcase( CmdWord), FNC_FILE_ONLY_CMD_LIST) = 0 then
         if f = 0 then
            --dprintf( 'TabComplete', 'Dir: FileMask = ['FileMask']')
         endif
         -- Find dirs first
         next = NepmdGetNextDir( FileMask, address(handle))
         parse value next with 'ERROR:'rc1
         if rc1 = '' then
            Name = next
            -- Append \ for dirs
            Name = Name'\'
            f = f + 1
         else
            --dprintf( 'TabComplete', 'Dir: FileMask = ['FileMask'], Found 'f' filenames.')
            handle = 0  -- handle must be reset to 0 before the next search
            f = 0
         endif
      endif
      if rc1 > '' then
         if fAppendExeMask then
            -- Append executable masks
            if ((m = 0 | rc2 > '') & words( FNC_EXE_MASK_LIST) > m) then
               m = m + 1
               FileMask = UnAppFileMask''word( FNC_EXE_MASK_LIST, m)
               rc2 = ''
            endif
         endif
         if rc2 = '' & wordpos( upcase( CmdWord), FNC_DIR_ONLY_CMD_LIST) = 0 then
            if f = 0 then
               --dprintf( 'TabComplete', 'File 'm': FileMask = ['FileMask']')
            endif
            -- Find files
            next = NepmdGetNextFile( FileMask, address(handle))
            parse value next with 'ERROR:'rc2
            if rc2 = '' then
               Name = next
               f = f + 1
            else
               --dprintf( 'TabComplete', 'File 'm': FileMask = ['FileMask'], Found 'f' filenames.')
               f = 0
               if fAppendExeMask & words( FNC_EXE_MASK_LIST) > m then
                  -- Initiate a new search with the next ExeMask
                  --handle = 0  -- handle must be reset to 0 before the next search
                  iterate
               endif
            endif
         endif
      endif
      if Name > '' then
         -- Remove maybe previously added PrepMask if FilePiece was relative
         l = length( PrepMask)
         if l > 0 then
            if leftstr( upcase(Name), l) == upcase(PrepMask) then
               Name = substr( Name, l + 1)
            endif
         endif
         -- Add it to array
         c = c + 1
         call SetAVar( 'FncFound.'c, Name)
      else
         leave
      endif
   enddo
   if c > 0 then
      call SetAVar( 'FncFound.0', c)       -- number of found names
      call SetAVar( 'FncFound.last', '0')  -- use 0 as initial number
      sayerror c 'dirs/files found.'
   else
      sayerror 'No match for "'FilePiece'".'
   endif
   call SetAVar( 'FncShellNum', ShellNum)
   call SetAVar( 'FncPrompt', Prompt)
   call SetAVar( 'FncCmdPiece', CmdPiece)

; ---------------------------------------------------------------------------
; Tab must not be defined as accelerator key, because otherwise
; lastkey(2) and lastkey(3) would return wrong values for Tab.
; lastkey() = lastkey(0) and lastkey(1) for Tab doesn't work in EPM!
; When Sh is pressed, lastkey() is set to Sh. While Sh is down and
; Tab is pressed additionally, lastkey is set to Sh+Tab and lastkey(2)
; is set to Sh. Therefore querying lastkey(2) to determine if Tab was
; pressed before doesn't work for any key combination!
;defc TabComplete
defc ShellFncComplete
   fForeward = ( arg(1) <> '-')
   -- Check shell
   ShellNum = ''
   if IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   next = GetAVar( 'FncShellNum')
   if ShellNum = '' | ShellNum <> next then
      return
   endif
   -- Query array
   Prompt   = GetAVar( 'FncPrompt')
   CmdPiece = GetAVar( 'FncCmdPiece')
   Name     = ''
   cLast    = GetAVar( 'FncFound.last')
   if cLast > '' then
      cTotal = GetAVar( 'FncFound.0')
      --sayerror cTotal 'files in array.'
      if fForeward then
         if cLast < cTotal then
            cLast = cLast + 1
         else
            cLast = 1
         endif
      else
         if cLast > 1 then
            cLast = cLast - 1
         else
            cLast = cTotal
         endif
      endif
      Name = GetAVar( 'FncFound.'cLast)
      call SetAVar( 'FncFound.last', cLast)  -- save last used name number
   endif

   if Name > '' then
      if pos( ' ', Name) then
         Name = '"'Name'"'
      endif
; Todo:
; Make -dName possible
      if CmdPiece > '' then
         NewLine = Prompt strip( CmdPiece) Name
      else
         NewLine = Prompt Name
      endif
      replaceline NewLine
      .col = length( NewLine) + 1  -- go to end
   endif

; ---------------------------------------------------------------------------
; Following definitions are copied from Joerg Tiemann's SHELLKRAM.E package:

/***************************************************************************/
/* Shell_History                                                           */
/* The following Shell_History command is a 100% subset of the shell_write */
/* command in epmshell.e.  I have only changed the order of the lines and  */
/* left out some of the "compile if" statements for EPM <5.6, because at   */
/* some point it got too complicated for me. ;-)                           */
/* Oh, what does it do? It is the same as shell_write, except that this    */
/* one starts with the history dialog.                                     */
/***************************************************************************/

defc Shell_History
   universal Shell_lastwrite

   parse arg ShellNum Text
   if ShellNum = '' & IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif

   ShellHandle = GetAVar( 'Shell_h'ShellNum)

   if ShellHandle <> '' then
      if Text <> '' then Shell_lastwrite = Text; endif

      shell_title = strip( WRITE_SHELL_MENU__MSG, 'T', '.')  -- '~Write to shell...'
      tilde = pos( '~', shell_title)
      if tilde then
         shell_title = delstr( shell_title, tilde, 1)
      endif
      do forever

         getfileid shell_fileid
         call psave_pos(save_pos)
         'xcom e /c cmdslist'
         if rc <> -282 then  -- -282 = sayerror("New file")
            sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
            return
         endif
         browse_mode = browse()     -- query current state
         if browse_mode then call browse(0); endif
         .autosave = 0
         getfileid lb_fid
         activatefile shell_fileid
         display -2
         getsearch oldsearch
         0

  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
         'xcom l /^epm\: .*>:o./x'
  compile else  -- else EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
         'xcom l /^\[epm\: .*\]:o./x'
  compile endif -- EPM_SHELL_PROMPT
         do while rc = 0
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
            parse value textline(.line) with '>' cmd
  compile else
            parse value textline(.line) with ']' cmd
  compile endif -- EPM_SHELL_PROMPT
           insertline strip( cmd, 'L'), lb_fid.last+1, lb_fid
           repeatfind
         enddo
         setsearch oldsearch
         call prestore_pos(save_pos)
         if browse_mode then call browse(1); endif
         activatefile lb_fid
         display 2
         if not .modify then  -- Nothing added?
            'xcom quit'
            activatefile shell_fileid
            sayerror -273 -- String not found - 4OS2???
            return
         endif

         if listbox_buffer_from_file( shell_fileid, bufhndl, noflines, usedsize) then return; endif
         parse value listbox( shell_title,
                              \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                              '/'OK__MSG'/'EDIT__MSG'/'Cancel__MSG,
                              1, 35,
                              min(12,18), 0,
                              gethwndc(APP_HANDLE) ||
                              atoi(1) || atoi(1) || atoi(0000)) with Button 2 Text \0
         call buffer( FREEBUF, bufhndl)
         if Button = \2 then -- 'Edit' selected
            Shell_lastwrite = Text
            parse value entrybox( shell_title,                  -- Title,
       compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
                                  '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/',  -- Buttons
       compile else
                                  '/'OK__MSG'/'Cancel__MSG'/',  -- Buttons
       compile endif
                                  Shell_lastwrite,              -- Entrytext
                                  '', 254,                      -- cols, maxchars
                                  atoi(1) || atoi(0000) || gethwndc(APP_HANDLE) ||
                                  SHELL_PROMPT__MSG ShellNum) with Button 2 Text \0
            if Button = \2 then -- User asked for a list
               iterate -- do forever
            endif -- button 2 - 'List' in Edit Menu

         endif -- button 2 - 'Edit' in List menu
         if Button <> \1 then return; endif

         leave -- do forever
      enddo -- do forever

      writebuf = Text\13\10
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'write.retval='retval'  byteswritten=' bytesmoved 'of' length(writebuf)
      endif
   endif

/********************************************************************************/
/* Shell_Input                                                                  */
/* This is a cut off Shell_Write.  Initially the idea was to use it to be able  */
/* to use 4OS2 as the command line interpreter.  But that did not work.  In the */
/* meantime I've come to the conclusion that it is a nice command for use in    */
/* the toolbar "* Shell_Input somecommand parameters".                          */
/********************************************************************************/

defc Shell_Input
   universal Shell_lastwrite
   parse arg Text
   ShellNum = ''
   if IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif

   ShellHandle = GetAVar( 'Shell_h'ShellNum)

   if ShellHandle <> '' then
      if Text <> '' then Shell_lastwrite = Text; endif
      writebuf = Text\13\10  -- input text + CRLF
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'Shell_Input: write.retval='retval', byteswritten=' bytesmoved 'of' length(writebuf)
      endif
   endif

/******************************************************************/
/* Shell_SendKey                                                  */
/* Now yet another variation. This time to send single keystrokes */
/* to the command line interpreter, for example the often needed  */
/* 'y' and 'n'.                                                   */
/******************************************************************/

defc Shell_SendKey
   parse arg Text
   ShellNum = ''
   if IsAShell() then
      getfileid ShellFid
      ShellNum = GetAVar( 'ShellNum.'ShellFid)
   endif
   if ShellNum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   if Text = '' then
      sayerror 'Shell_SendKey: no key to send to shell specified'
      return
   endif

   ShellHandle = GetAVar( 'Shell_h'ShellNum)

   if ShellHandle <> '' then
      writebuf = Text  -- just the pure text w/o CRLF
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'Shell_SendKey: write.retval='retval'  byteswritten=' bytesmoved 'of' length(writebuf)
      endif
   endif

/*
defc esk_About=
   r = WinMessageBox( 'About EPM Shellkram',
                      'EPM Shellkram v.0.88 beta'\10 ||
                      'Wed, 3 Oct 2001'\10 ||
                      'Copyright (c) 1998-2001 by Joerg Tiemann'\10 ||
                      'Joerg Tiemann <tiemannj@gmx.de>', 16432)
*/
