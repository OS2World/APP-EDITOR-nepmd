/****************************** Module Header *******************************
*
* Module Name: epmshell.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmshell.e,v 1.7 2005-03-13 12:13:58 aschn Exp $
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

; ---------------------------------------------------------------------------
; ShellKram macros added. See SHELLKEYS.E for key definitions.
; SHELLKRAM.E was available from Joerg Tiemann's homepage some years ago:
; http://home.foni.net/~tiemannj/epm/index.html
; See his pages for documentation.

; Todo:
; Filename completion disabled. Finds currently only first occurence with
; NEPMD. NEPMD's procs for file search (NepmdGetNextFile) should be used,
; to make the code more readable.

/* Set the following two configuration constants */
const
compile if not defined(WANT_DIR_BACKSLASH)
   WANT_DIR_BACKSLASH = 1
   -- (0/1) directory names are while being completed:
   --  0 - left as they are
   --       Disadvantage: more typing in most cases
   --  1 - terminated with an backslash
   --       Disadvantage: cd and rd don't work with 'dir\' (jcd.cmd does!)
compile endif
compile if not defined(WANT_EXT_WILDCARD)
   WANT_EXT_WILDCARD = 0
   -- (0/1) a searchmask already provided with an extension
   --  0 - does not get extended with an '*'
   --      Example: *.htm will only find *.htm and not *.html
   --  1 - gets extendes with an '*'
   --       Examples: *.e becomes *.e*, which finds all *.e, *.exe, *.eps, ...
compile endif

/* Display the About dialog */
defc esk_About=
   r = WinMessageBox( 'About EPM Shellkram',
                      'EPM Shellkram v.0.88 beta'\10 ||
                      'Wed, 3 Oct 2001'\10 ||
                      'Copyright (c) 1998-2001 by Joerg Tiemann'\10 ||
                      'Joerg Tiemann <tiemannj@gmx.de>', 16432)

; ---------------------------------------------------------------------------

compile if WANT_EPM_SHELL='HIDDEN' & not defined(HP_COMMAND_SHELL)
   include 'MENUHELP.H'
compile endif

defc sendshell =
   if leftstr( .filename, 15) <> '.command_shell_' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   'shell_write' substr( .filename, 16) substr( textline(.line), .col)

-------------------------------------------------------------Shell-----------------------
; Starts a new shell object.
; Syntax: shell [<command>]
; shell_index is the number of the last created shell, <shellnum>.
; The array var 'Shell_f'<shellnum> holds the fileid, 'Shell_h'<shellnum> the handle.
defc shell
   universal Shell_index, EPM_utility_array_ID
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if WANT_EPM_SHELL='HIDDEN' & not defined(STD_MENU_NAME)
   universal activemenu, defaultmenu
   if not shell_index then
      buildmenuitem defaultmenu, 1, 101, \0,                      '',            4, 0
      buildmenuitem defaultmenu, 1, 102, CREATE_SHELL_MENU__MSG,       'shell'CREATE_SHELL_MENUP__MSG,       0, mpfrom2short(HP_COMMAND_SHELL, 0)
      buildmenuitem defaultmenu, 1, 103, WRITE_SHELL_MENU__MSG,        'shell_write'WRITE_SHELL_MENUP__MSG, 0, mpfrom2short(HP_COMMAND_SHELL, 16384)
;     buildmenuitem defaultmenu, 1, 104, KILL_SHELL_MENU__MSG,         'shell_kill'KILL_SHELL_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_SHELL, 16384)
      buildmenuitem defaultmenu, 1, 104, SHELL_BREAK_MENU__MSG,        'shell_break'SHELL_BREAK_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_SHELL, 16384)
 compile if RING_OPTIONAL  -- if not ring_enabled then ring_toggle will do the showmenu.
      if activemenu = defaultmenu & ring_enabled then
         call showmenu_activemenu()  -- show the updated EPM menu
      endif
 compile else
      call maybe_show_menu()
 compile endif
   endif
compile endif
compile if RING_OPTIONAL
   if not ring_enabled then
      'ring_toggle'
   endif
compile endif
   shell_index = shell_index + 1
   ShellHandle  = '????'
   retval = SUE_new(ShellHandle, shell_index)
   if retval then
      sayerror ERROR__MSG retval SHELL_ERROR1__MSG
   else
      'xcom e /c .command_shell_'shell_index
      if rc<>sayerror('New file') then
         sayerror ERROR__MSG rc SHELL_ERROR2__MSG
         stop
      endif
      getfileid shellfid
      .filename = '.command_shell_'shell_index
      .autosave = 0
      do_array 2, EPM_utility_array_ID, 'Shell_f'shell_index, shellfid
      do_array 2, EPM_utility_array_ID, 'Shell_h'shell_index, shellHandle
      'postme monofont'
   endif
;; sayerror "shellhandle=0x" || ltoa(ShellHandle, 16) || "  newObject.retval="retval;
compile if EPM_SHELL_PROMPT <> ''
   'shell_write' shell_index EPM_SHELL_PROMPT
compile endif
   if arg(1) then
      'shell_write' shell_index arg(1)
   endif

-------------------------------------------------------------Shell_Kill------------------
; Destroys a shell object.
; Syntax: shell_kill [<shellnum>]
defc shell_kill
   universal EPM_utility_array_ID
   parse arg shellnum .
   if shellnum = '' & leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
   endif
   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   rc = get_array_value( EPM_utility_array_ID, 'Shell_f'shellnum, shellfid )
   rc = get_array_value( EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle )
   null=''
   if shellhandle <> '' then
      retval = SUE_free(ShellHandle);
      if retval then sayerror ERROR__MSG retval SHELL_ERROR3__MSG; endif
      do_array 2, EPM_utility_array_ID, 'Shell_h'shellnum, null
   endif
   if shellfid <> '' then
      getfileid curfid
      activatefile shellfid
      .modify=0
      'xcom quit'
      do_array 2, EPM_utility_array_ID, 'Shell_f'shellnum, null
      if curfid <> shellfid then
         activatefile curfid
      endif
   endif

-------------------------------------------------------------Shell_Write-----------------
; Syntax: shell_write [<shellnum>] [<text>]
; If first word is not a number, then last opened shell will be used as <shellnum>.
; If <text> is missing, the 'Write to shell' EntryBox opens.
defc Shell_Write
   universal ShellHandle
   universal EPM_utility_array_ID
   universal Shell_lastwrite
   parse arg shellnum text
   if not isnum(shellnum) & leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
      parse arg text
   endif
   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   rc = get_array_value( EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle)
   if shellhandle <> '' then
      if text = '' then
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
                                  SHELL_PROMPT__MSG shellnum) with button 2 text \0
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
                                    atoi(0000)) with button 2 text \0
               call buffer( FREEBUF, bufhndl)
               if button = \2 then -- 'Edit' selected
                  Shell_lastwrite = text
                  iterate
               endif
            endif
 compile endif
            if button <> \1 then return; endif
            leave
         enddo
      endif  -- text = ''
;     if text = '' then return; endif
      if text <> '' then Shell_lastwrite = text; endif
      writebuf = text\13\10
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'Shell_Write: write.retval='retval'  byteswritten=' bytesmoved 'of' length(writebuf)
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
; Right margin setting of current shell is not respected.
defc NowCanReadShell
   universal EPM_utility_array_ID
   parse arg shellnum .
   if not isnum(shellnum) then
      sayerror 'NowCanReadShell:  'INVALID_ARG__MSG '"'arg(1)'"'
      return
   endif
   rc = get_array_value( EPM_utility_array_ID, 'Shell_f'shellnum, shellfid)
   rc = get_array_value( EPM_utility_array_ID, 'Shell_h'shellnum, shellhandle)
   bytesmoved = 1;
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
      do while rest <> ''
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
         getline lastline, shellfid.last, shellfid
         shellfid.line = shellfid.last
         shellfid.col = min( MAXCOL,length(lastline) + 1)
      enddo

   endwhile
; Todo: Save last written pos or add an attribute
;       in order to accept input by a waiting application directly
;       in the shell window, not only in the Write to shell dialog.
;       Determine therefore, if an application is terminated or waiting.

-------------------------------------------------------------SUE_new---------------------
; Called from Shell command
defproc SUE_new( var shell_handle, shellnum)
   thandle = '????';
;; sayerror "address=0x" || ltoa(taddr, 16) || "  hwnd=0x"ltoa(hwnd, 16);
   result  = dynalink32( ERES_DLL,
                         'SUE_new',
                         address(thandle)             ||
                         gethwndc(EPMINFO_EDITCLIENT) ||
                         atol(shellnum) );
   shell_handle = thandle;
   return result;

-------------------------------------------------------------SUE_free--------------------
; Called from Shell_Kill command
defproc SUE_free( var shell_handle)
   thandle = shell_handle;
   result  = dynalink32( ERES_DLL,
                         'SUE_free',
                         address(thandle) )
   shell_handle = thandle;
   return result;

-------------------------------------------------------------SUE_readln------------------
; Called from NowCanReadShell cmd
defproc SUE_readln( shell_handle, var buffe, var bytesmoved)
   bufstring = buffe;  -- just to insure the same amount of space is available
   bm        = "??"
   result  = dynalink32( ERES_DLL,
                         'SUE_readln',
                         shell_handle               ||
                         address(bufstring)         ||
                         atol(length(bufstring))    ||
                         address(bm))
   bytesmoved = itoa( bm,10);
   buffe      = bufstring;
   return result;

-------------------------------------------------------------SUE_write-------------------
; Called from Shell_Write command
defproc SUE_write( shell_handle, buffe, var bytesmoved)
   bm        = "??"
   result  = dynalink32( ERES_DLL,
                         'SUE_write',
                         shell_handle                     ||
                         address(buffe)                   ||
                         atol(length(buffe))              ||
                         address(bm))
   bytesmoved = itoa( bm, 10);
   return result;

-------------------------------------------------------------Shell_Break-----------------
; Sends a Break to a shell object
defc shell_break
   universal EPM_utility_array_ID
   parse arg shellnum .
   if shellnum = '' & leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr(.filename,16)
   endif
   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   rc = get_array_value( EPM_utility_array_ID, 'Shell_f'shellnum, shellfid)
   rc = get_array_value( EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle)
   if shellhandle <> '' then
      retval = SUE_break(ShellHandle);
      if retval then sayerror ERROR_NUMBER__MSG retval; endif
   endif

-------------------------------------------------------------SUE_break-------------------
defproc SUE_break(shell_handle)
   return dynalink32( ERES_DLL,
                      'SUE_break',
                      shell_handle)

; ---------------------------------------------------------------------------
; Reset modified state to avoid the dialog on quit.
defmodify
   Mode = NepmdGetMode()
   if Mode = 'SHELL' then
      .modify = 0
      .autosave = 0
      'ResetDateTimeModified'
      'refreshinfoline MODIFIED'
   endif

; ---------------------------------------------------------------------------
; This command can be used as key command, maybe for Esc.
; Syntax: shell_commandline [<shellnum>] [<text>]
defc shell_commandline
   universal EPM_utility_array_ID
   parse arg shellnum text
   if not isnum(shellnum) & leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
      parse arg text
   endif
   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   'commandline shell_write 'shellnum' 'text


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
   universal ShellHandle
   universal EPM_utility_array_ID
   universal Shell_lastwrite

   parse arg shellnum text
   if shellnum = '' & leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
   endif

   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif

   do_array 3, EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle

   if shellhandle <> '' then
   if text <> '' then Shell_lastwrite = text; endif

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
                              atoi(1) || atoi(1) || atoi(0000)) with button 2 text \0
         call buffer(FREEBUF, bufhndl)
         if button = \2 then -- 'Edit' selected
            Shell_lastwrite = text
            parse value entrybox( shell_title,                  -- Title,
       compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
                                  '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/',  -- Buttons
       compile else
                                  '/'OK__MSG'/'Cancel__MSG'/',  -- Buttons
       compile endif
                                  Shell_lastwrite,              -- Entrytext
                                  '', 254,                      -- cols, maxchars
                                  atoi(1) || atoi(0000) || gethwndc(APP_HANDLE) ||
                                  SHELL_PROMPT__MSG shellnum) with button 2 text \0
            if button = \2 then -- User asked for a list
               iterate -- do forever
            endif -- button 2 - 'List' in Edit Menu

         endif --button 2 - 'Edit' in List menu
         if button <> \1 then return; endif

         leave -- do forever
      enddo -- do forever

      writebuf = text\13\10
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
   universal ShellHandle
   universal Shell_lastwrite
   parse arg text
   if leftstr( .filename, 15) = '.command_shell_' then
      shellnum = substr( .filename, 16)
   endif
   if shellnum = '' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   if shellhandle <> '' then
      if text <> '' then Shell_lastwrite = text; endif
      writebuf = text\13\10  -- input text + CRLF
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
   universal ShellHandle
   parse arg text
   if text = '' then
      sayerror 'Shell_SendKey: no key to send to shell specified'
      return
   endif
   shellnum = substr( .filename, 16)
   if shellnum='' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   if shellhandle <> '' then
      writebuf = text  -- just the pure text w/o CRLF
      retval   = SUE_write( ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved <> length(writebuf) then
         sayerror 'Shell_SendKey: write.retval='retval'  byteswritten=' bytesmoved 'of' length(writebuf)
      endif
   endif


; Following definitions provide the filename completition feature of SHELLKRAM.E:
/*
/* Abandon current fnc command */
defc Abandon_fnc
   universal OutCmdLine
   universal OutCurPos
   universal fnc_id
   OutCmdLine = ''
   OutCurPos = ''
   if fnc_id <> '' then                -- if an old fnc_array exists
      killres = fnc_killarray(fnc_id)  -- kill it!
      if not killres then
         sayerror "killed old fnc_array"
      else
         sayerror "error: couldn't kill old fnc_array!"
         stop  -- didn't come here, but don't want to either
      endif
   endif

/* Here we go! */
defc Filename_Completion
   universal ShellHandle
   universal max_count
   universal zaehler
   universal fnc_id
   universal last_search
   universal search_type
   universal OutCmdLine
   universal OutCurPos

; Check if command_shell, Shell_num, shell_handle...
   parse arg shellnum text
   if shellnum='' & leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
   endif

   if shellnum='' then
      sayerror "error: not an EPM Shell!"
      return
   endif

; Look for an fnc-array
; This routine does not work as described in epmtech.inf => see comments
   array_name = "fnc_array"
   do_array 6, array_index, array_name    -- "Invalid second parameter" if array doesn't exist!
   if array_index=-1 then fnc_id='';endif -- because d_a 6 does not return array_id but array_id-1
                                          -- this means rc=-1 => rc=0 => no array => fnc_id-Variable erased

; New search or continue browsing through last search?
   if last_search <> "Fehler!" then -- if the last search was successful
      InCmdLine = textline(.line)
      InCurPos = .col
      LineComp = InCmdLine = OutCmdLine  -- current line content and
      CurPosComp = InCurPos = OutCurPos  -- cursor position match those after last completion
      neuesuche = not LineComp & not CurPosComp
   else                              -- if the last search was not sucessful
      neuesuche = 1                  -- start new search anyway
      sayerror 'notify: New Search!' -- can happen: 0 matches found, but user hits repeadly TAB or Shift-TAB
   endif

; determine last key
   parse value lastkey(2) with flags 3 repeat 4 fnc_key 5 charcode 7 vk_code 9
   tab_key  = c2x(fnc_key) = '0f' & c2x(vk_code) = '0600'
   stab_key = c2x(fnc_key) = '0f' & c2X(vk_code) = '0700'

; New search
   if neuesuche then
      last_search = ''               -- set back my little error flag
      if fnc_id <> '' then                -- if an old fnc_array exists
         killres = fnc_killarray(fnc_id)  -- kill it!
         if not killres then
            sayerror "killed old fnc_array"
         else
            sayerror "error: couldn't kill old fnc_array!"
            stop  -- didn't come here, but don't want to either
         endif
      endif
      ns_res = fnc_neuesuche()
      parse value ns_res with dir_count exe_count file_count -- getting array_id and number of matches found
      ges_count = dir_count + exe_count + file_count
      sayerror ges_count "hit(s)! Use <tab> and <shift-tab> to browse!" -- "Found:" dir_count "dir(s)," exe_count "exe(s) and" file_count "other."
      zaehler = 1
      if search_type = 'N' & tab_key then
         if file_count then array_section = 'file'; endif -- start with file 1
         if not file_count then
            array_section = 'dir'; zaehler = dir_count    -- no files, start with last dir
         endif
      elseif search_type = 'N' & stab_key then
         if dir_count then array_section = 'dir'; endif  -- start with dir 1
         if not dir_count then
            array_section = 'file'; zaehler = file_count -- no dirs, start with last file
         endif
      elseif search_type = 'C' & tab_key then
         if exe_count then array_section = 'exe'; endif -- start with exe 1
         if not exe_count then
            array_section = 'dir'; zaehler = dir_count  -- no exes, start with last dir
         endif
      elseif search_type = 'C' & stab_key then
         if dir_count then array_section = 'dir'; endif  -- start with dir 1
         if not dir_count then
            array_section = 'exe'; zaehler = exe_count   -- no dirs, start with last exe
         endif
      endif
--      sayerror "e5: array_sec =" array_section
      get_res = fnc_getcompletion(fnc_id, array_section, zaehler)
      parse value get_res with filename    -- getting 1 matching filename
      out_res = fnc_output(filename, array_section) -- calling defproc out_res to do the output
   endif

; No new search -> get next matches out of the fnc_array
   if not neuesuche then
      if search_type = 'N' & tab_key then
         if array_section = 'file' & zaehler < file_count then zaehler = zaehler + 1
         elseif array_section = 'dir' & zaehler < dir_count then zaehler = zaehler + 1
         elseif array_section = 'file' & zaehler = file_count then
            if dir_count then
               array_section = 'dir'; zaehler = 1
            else
               zaehler = 1
            endif
         elseif array_section = 'dir' & zaehler = dir_count then
            if file_count then
               array_section = 'file'; zaehler = 1
            else
               zaehler = 1
            endif
         endif
      elseif search_type = 'N' & stab_key then
         if array_section = 'file' & zaehler > 1 then zaehler = zaehler - 1
         elseif array_section = 'dir' & zaehler > 1 then zaehler = zaehler - 1
         elseif array_section = 'file' & zaehler = 1 then
            if dir_count then
               array_section = 'dir'; zaehler = dir_count
            else
               zaehler = file_count
            endif
         elseif array_section = 'dir' & zaehler = 1 then
            if file_count then
               array_section = 'file'; zaehler = file_count
            else
               zaehler = dir_count
            endif
         endif
      elseif search_type = 'C' & tab_key then
         if array_section = 'exe' & zaehler < exe_count then zaehler = zaehler + 1
         elseif array_section = 'dir' & zaehler < dir_count then zaehler = zaehler + 1
         elseif array_section = 'exe' & zaehler = exe_count then
            if dir_count then
               array_section = 'dir'; zaehler = 1
            else
               zaehler = 1
            endif
         elseif array_section = 'dir' & zaehler = dir_count then
            if exe_count then
               array_section = 'exe'; zaehler = 1
            else
               zaehler = 1
            endif
         endif
      elseif search_type = 'C' & stab_key then
         if array_section = 'exe' & zaehler > 1 then zaehler = zaehler - 1
         elseif array_section = 'dir' & zaehler > 1 then zaehler = zaehler - 1
         elseif array_section = 'exe' & zaehler = 1 then
            if dir_count then
               array_section = 'dir'; zaehler = dir_count
            else
               zaehler = exe_count
            endif
         elseif array_section = 'dir' & zaehler = 1 then
            if exe_count then
               array_section = 'exe'; zaehler = exe_count
            else
               zaehler = dir_count
            endif
         endif
      endif
      get_res = fnc_getcompletion(fnc_id, array_section, zaehler)
      parse value get_res with filename    -- getting 1 matching filename
      out_res = fnc_output(filename, array_section) -- calling defproc out_res to do the output
   endif

/********************************************************************/
/* fnc_neuesuche (new search)                                       */
/* First the part of a filename to be completed or wildcard to be   */
/* interpreted is read from the command line; if necessary the      */
/* fully qualified path is constructed and wildcards are added. The */
/* result is fed to Dos32FindFirst/Next and the results of this     */
/* search are returned to the calling procedure.                    */
/*                                                                  */
/* This second part of this defproc is more or less inspired by,    */
/* if not even based on, Tree_SearchDir (treecomp.e) by, of course, */
/* Larry Margolis. Thanks to him for that great piece of code!      */
/********************************************************************/

defproc fnc_neuesuche
   universal last_search
   universal target
   universal Vorspiel
   universal fnc_id
   universal Nachspiel
   universal search_type
   universal begincol

   target ='' -- initialize
   call psave_pos(save_pos) -- store cursor pos
   markline
   beginline
   'xcom l /^epm\: .*>:o./mx' -- search line mark for prompt
   unmark
   call prestore_pos(save_pos) -- restore cursor pos
   CmdZeile = textline(.line)
   insertcol = .col-1  -- store column
   tmpcol = .col-1
   do while not pos(substr(CmdZeile,tmpcol,1),'<>| ')  -- find begin of current word/command
      tmpcol = tmpcol-1
      left
   enddo
   begincol = .col     -- store this column, too
   tcols = insertcol-begincol+1  -- length of word till cursor
   Vorspiel = substr(CmdZeile,1,begincol-1) -- line up to current word
   target = substr(CmdZeile,begincol,tcols) -- current word till cursor
   Nachspiel = substr(Cmdzeile,insertcol+1) -- line after current word
   filename = target -- target is needed later - umtampered with

/* get the current path from the last prompt line of the shell */
   bottom
   'xcom l /^epm\: .*>:o./rx'
   LastLine = textline(.line)
   parse value LastLine with 'epm: ' curdir ' >' Rest
   curdir = strip(curdir,'t','\') -- if it is root dir
   call prestore_pos(save_pos) -- restore cursor pos

/* look for search mode */
   pipe = pos('|',substr(CmdZeile,begincol-2,2)) -- '|target' or '| target'
   prompt = pos('>', CmdZeile) = begincol-1 | pos('>', CmdZeile) = begincol-2 -- first '>' in command line
   if pipe | prompt then
      search_type = 'C' -- command completion, only dirs and commands
   else
      search_type = 'N' -- filename completion, all files
   endif

   bslash = pos('\',filename)
   updir = pos('..\',filename)
   colon = pos(':', filename)
   if bslash = 1 then                         -- target starts with backslash
      filename = substr(curdir,1,2)||filename -- -> root of current drive is base
   elseif not bslash | (bslash & not colon) then  -- in current dir or already specified subdir
      filename = curdir'\'filename            -- add path from epm prompt
   endif
   if updir = 1 & pos('\',curdir) then -- ..\xyz.xx or ..\..\..\..\xyz.* etc.
      do while pos('..\',filename) & lastpos('\',curdir)
         updir = pos('..\', filename)
         filename = substr(filename,updir+3)
         curupdir = lastpos('\',curdir)
         curdir = substr(curdir,1,curupdir-1)
      enddo
      if pos('..\',filename) then -- can happen: user couldn't stop typing '..\'
         sayerror "You don't really wanna go that far up, do you?" -- fatherly advice given
         stop -- unconditionally exiting the macros
      else
         filename = curdir'\'filename
      endif
   endif


; now we're gonna add some nice wildcards for some of the files
   wea = lastpos('*',filename) = tcols -- wea = with end ateriks
   ast = pos('*',filename)             -- ast = with asteriks
   pnt = pos('.',substr(filename,(lastpos('\',filename))))
   -- pnt = with period (in filename part after last backslash)
   wap = ast | pnt                     -- wap = with asterix and period
   if not wap then
      filename = filename'*.*'    -- xyz -> xyz*.*
   else
      if wea & pnt then
         filename = filename      -- xyz.* -> xyz.* or xy.z* -> xy.z*
      elseif wea then
         filename = filename'.*'  -- xyz* -> xyz*.*
      elseif pnt & WANT_EXT_WILDCARD = 1 then -- for WANT_EXT_WILDCARD see begin of this file
         filename = filename'*'   -- xy.z -> xy.z* or *.htm -> *.htm* or *.e -> *.e*
      elseif ast then
         filename = filename'*'   -- *xy -> *xy* or B*s -> B*s*
      endif
   endif

   attribute = 55 -- Want to see all files
   namez    = filename\0    -- ASCIIZ
   resultbuf = substr('', 1, 300, \0)
   dirhandle = \xff\xff\xff\xff  -- Ask system to assign us a handle
   searchcnt = atol(1)   -- Search count; we're only asking for 1 file at a time here.

   result=dynalink32('DOSCALLS',             -- dynamic link library name
                     '#264',                 -- ordinal value for DOS32FINDFIRST
                     address(namez)      ||  -- Filename we're looking for
                     address(dirhandle)  ||  -- Pointer to the handle
                     atol(attribute)     ||  -- Attribute value describing desired files
                     address(resultbuf)  ||  -- string address
                     atol(length(resultbuf)) ||
                     address(searchcnt)  ||  -- Pointer to the count; system updates
                     atol(2), 2)             -- File info level 2 requested

   if result & result<>18 then  -- unexpected error
      sayerror 'result' result 'from DosFindFirst' filename
      stop                      -- unconditionally exit macro!
   endif

   if result = 18 then call fnc_error(); endif -- no completions found at all

   if not result then
      fnc_id = ''; array_name = 'fnc_array'
      do_array 1, fnc_id, array_name  -- make an array
      fnc_id.userstring = '[not set]' -- Set default value
      dir_count = 0; exe_count = 0; file_count = 0
      loop
         filename = substr(resultbuf, 34, asc(substr(resultbuf, 33, 1)))
         fileattrib = ltoa(substr(resultbuf,25,4),10)
         ext = filetype(filename)
         skip = filename='.' | filename='..' -- aren't of any use here
         if not skip then
            type = fnc_filetype(fileattrib, ext)
            if type = 'D' then -- Directory-Teil des arrays
               dir_count = dir_count+1
               do_array 2, fnc_id, 'dir.'dir_count, filename
            elseif type = 'E' & search_type = 'C' then -- executables are dealt with in a separate of array
               exe_count = exe_count+1                 -- in a command completion
               do_array 2, fnc_id, 'exe.'exe_count, filename
            elseif type = 'N' & search_type <> 'C' then -- "normal" files are junked if command completion
               file_count = file_count+1
               do_array 2, fnc_id, 'file.'file_count, filename
            elseif type = 'E' & search_type <> 'C' then -- executables are regarded normal files in
               file_count = file_count+1                -- filename completion
               do_array 2, fnc_id, 'file.'file_count, filename
            endif /* if type ... */
         endif /* if not skip */

         result=dynalink32('DOSCALLS',            -- dynamic link library name
                          '#265',                 -- ordinal value for DOS32FINDNEXT
                          dirhandle           ||  -- Directory handle, returned by DosFindFirst(2)
                          address(resultbuf)  ||  -- address of result buffer
                          atol(length(resultbuf)) ||
                          address(searchcnt), 2)  -- Pointer to the count; system updates

         if result then
            call dynalink32('DOSCALLS',           -- dynamic link library name
                            '#263',               -- ordinal value for DOS32FINDCLOSE
                            dirhandle)            -- Directory handle, returned by DosFindFirst(2)

            if result<>18 then
               sayerror 'Unexpected error' result 'from DosFindNext'
            endif
            leave
         endif
      endloop
      if search_type='C' & dir_count + exe_count = 0 then call fnc_error(); endif
      -- command name completion but neither dirs nor executables found
   endif  -- result from DosFindFirst
   nsres = dir_count' 'exe_count' 'file_count
   return(nsres)

/********************************************************************/
/* fnc_filetype                                                     */
/* Tells us if found file is a directory or not                     */
/********************************************************************/

defproc fnc_filetype(fileattrib, ext)
         fileattrib = fileattrib // 64
         if fileattrib % 32 then -- Archiv-Bit gesetzt
            fileattrib = fileattrib // 32
         endif
         if fileattrib % 16 then
            attr_string = 'D' -- Directory
         elseif ext = 'EXE' | ext = 'COM' | ext = 'CMD' then
            attr_string = 'E' -- Executable
         else attr_string = 'N'
         endif
         return attr_string

/********************************************************************/
/* fnc_getcompletion                                                */
/* gets value for filename from index position zaehler of array     */
/* with id fnc_id and returns it to caller                          */
/********************************************************************/

defproc fnc_getcompletion(fnc_id, array_section, zaehler)
   do_array 7, fnc_id, array_section'.'zaehler, filename
   return filename

/********************************************************************/
/* fnc_killarray                                                    */
/* Kills old fnc_array because the old search is over and gone.     */
/********************************************************************/

defproc fnc_killarray(fnc_id)
   getfileid curr_file     -- Save the current file
   activatefile fnc_id     -- Activate the fnc_array pseudo-file
   'xcom quit'             -- Quit the array
   activatefile curr_file  -- Restore the previously-active file
   return

/********************************************************************/
/* fnc_output                                                       */
/* Combines the fully qualified result from Dos32FindFirst/Next     */
/* with our initial searchstring to the output string. If wanted    */
/* a backslash is appended to directory names -- set configuration  */
/* constant WANT_DIR_BACKSLASH accordingly (see begin of this file) */
/********************************************************************/

defproc fnc_output(filename, type)
   universal target
   universal Vorspiel
   universal Nachspiel
   universal OutCmdLine
   universal OutCurPos
   tlb = lastpos('\', target)  --target's last backslash
   if not tlb then
      ausgabestring = filename
   else
      ausgabestring = substr(target,1,tlb)||filename
   endif
   if WANT_DIR_BACKSLASH = 1 then
      if type= 'dir' then ausgabestring = ausgabestring||'\';endif
   endif
   tarlen = length(target)
   backtabword
   for i = 1 to tarlen
      deletechar
   endfor
   OutCmdLine = Vorspiel||ausgabestring||Nachspiel
   replaceline OutCmdLine
   OutCurPos = length(Vorspiel)+length(ausgabestring)+1
   .col = OutCurPos
return

/********************************************************************/
/* fnc_error                                                        */
/* gets called when DOS32FindFirst/Next could not find a completion */
/* for the asked for type of file or no completion at all. All this */
/* procedure does is to set the last_search-Error-Flag and exit the */
/* filename completion.                                             */
/********************************************************************/

defproc fnc_error()
   universal last_search
   universal begincol
   universal target
   sayerror "No file matches! Have another try!"
   .col = max(begincol, lastpos('\',target)+begincol)
   last_search = "Fehler!" -- set error-flag and
   stop                    -- unconditionally exit macro!

*/

