/****************************** Module Header *******************************
*
* Module Name: epmshell.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmshell.e,v 1.2 2002-07-22 19:00:14 cla Exp $
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
compile if WANT_EPM_SHELL='HIDDEN' & not defined(HP_COMMAND_SHELL)
   include 'MENUHELP.H'
compile endif

defc sendshell =
   if leftstr(.filename, 15) <> ".command_shell_" then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   'shell_write' substr(.filename,16) substr(textline(.line), .col)

-------------------------------------------------------------Shell-----------------------
defc shell   -- starts a shell object
   universal Shell_index, EPM_utility_array_ID
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if WANT_EPM_SHELL='HIDDEN' & not defined(STD_MENU_NAME)
   universal activemenu,defaultmenu
   if not shell_index then
      buildmenuitem defaultmenu, 1, 101, \0,                      '',            4, 0
      buildmenuitem defaultmenu, 1, 102, CREATE_SHELL_MENU__MSG,       'shell'CREATE_SHELL_MENUP__MSG,       0, mpfrom2short(HP_COMMAND_SHELL, 0)
      buildmenuitem defaultmenu, 1, 103, WRITE_SHELL_MENU__MSG,        'shell_write'WRITE_SHELL_MENUP__MSG, 0, mpfrom2short(HP_COMMAND_SHELL, 16384)
;     buildmenuitem defaultmenu, 1, 104, KILL_SHELL_MENU__MSG,         'shell_kill'KILL_SHELL_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_SHELL, 16384)
 compile if EPM32
      buildmenuitem defaultmenu, 1, 104, SHELL_BREAK_MENU__MSG,        'shell_break'SHELL_BREAK_MENUP__MSG,  0, mpfrom2short(HP_COMMAND_SHELL, 16384)
 compile endif
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
compile if EPM_SHELL_PROMPT<>''
   'shell_write' shell_index EPM_SHELL_PROMPT
compile endif
   if arg(1) then
      'shell_write' shell_index arg(1)
   endif

-------------------------------------------------------------Shell_Kill------------------
defc shell_kill   -- destroys a shell object
   universal EPM_utility_array_ID
   parse arg shellnum .
   if shellnum='' & leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
   endif
   if shellnum='' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   do_array 3, EPM_utility_array_ID, 'Shell_f'shellnum, shellfid
   do_array 3, EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle
   null=''
   if shellhandle<>'' then
      retval = SUE_free(ShellHandle);
      if retval then sayerror ERROR__MSG retval SHELL_ERROR3__MSG; endif
      do_array 2, EPM_utility_array_ID, 'Shell_h'shellnum, null
   endif
   if shellfid<>'' then
      getfileid curfid
      activatefile shellfid
      .modify=0
compile if INCLUDING_FILE = 'E.E'
      'xcom quit'
compile else   -- Force activation of main .ex file, in case is last file in ring
      'xcom_quit'
compile endif -- INCLUDING_FILE = 'E.E'
      do_array 2, EPM_utility_array_ID, 'Shell_f'shellnum, null
      if curfid<>shellfid then
         activatefile curfid
      endif
   endif

-------------------------------------------------------------Shell_Write-----------------
defc Shell_Write
   universal ShellHandle
   universal EPM_utility_array_ID
   universal Shell_lastwrite
   parse arg shellnum text
   if shellnum='' & leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
   endif
   if shellnum='' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   do_array 3, EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle
   if shellhandle<>'' then
      if text='' then
compile if EVERSION < 5.21
         text=entrybox(SHELL_PROMPT__MSG shellnum)
compile else
         shell_title = strip(WRITE_SHELL_MENU__MSG, 'T', '.')  -- '~Write to shell...'
         tilde = pos('~', shell_title)
         if tilde then
            shell_title = delstr(shell_title, tilde, 1)
         endif
         do forever
            parse value entrybox(shell_title,               -- Title,
 compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
                   '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/', -- Buttons
 compile else
                   '/'OK__MSG'/'Cancel__MSG'/', -- Buttons
 compile endif
                   Shell_lastwrite, '', 254,                -- Entrytext, cols, maxchars
                   atoi(1) || atoi(0000) || gethwndc(APP_HANDLE) ||
                   SHELL_PROMPT__MSG shellnum) with button 2 text \0
 compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
            if button=\2 then -- User asked for a list
               getfileid shell_fileid
               call psave_pos(save_pos)
               'xcom e /c cmdslist'
               if rc<>-282 then  -- -282 = sayerror("New file")
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
   compile if EPM32
               'xcom l /^epm\: .*>:o./x'
   compile else
               'xcom l /^epm: .*> *[^ ]/g'
   compile endif -- EPM32
  compile else  -- else EPM_SHELL_PROMPT = '@prompt [epm: $p ]'
   compile if EPM32
               'xcom l /^\[epm\: .*\]:o./x'
   compile else
               'xcom l /^\[epm: .*\] *[^ ]/g'
   compile endif -- EPM32
  compile endif -- EPM_SHELL_PROMPT
               do while rc = 0
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
                  parse value textline(.line) with '>' cmd
  compile else
                  parse value textline(.line) with ']' cmd
  compile endif -- EPM_SHELL_PROMPT
                  insertline strip(cmd, 'L'), lb_fid.last+1, lb_fid
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
               if listbox_buffer_from_file(shell_fileid, bufhndl, noflines, usedsize) then return; endif
               parse value listbox(shell_title,
  compile if 0 --POWERPC
                                   \0 || atol(usedsize) || atol(bufhndl+32),
  compile elseif EPM32
                                   \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
  compile else
                                   \0 || atoi(usedsize) || atoi(bufhndl) || atoi(32),
  compile endif -- EPM32
                                   '/'OK__MSG'/'EDIT__MSG'/'Cancel__MSG, 1, 35, min(noflines,12), 0,
  compile if EVERSION >= 5.60
                                   gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(0000)) with button 2 text \0
  compile else
                                   atoi(1) || atoi(1) || atoi(0000) || gethwndc(APP_HANDLE)) with button 2 text \0
  compile endif
               call buffer(FREEBUF, bufhndl)
               if button=\2 then -- 'Edit' selected
                  Shell_lastwrite = text
                  iterate
               endif
            endif
 compile endif
            if button<>\1 then return; endif
            leave
         enddo
compile endif  -- EVERSION < 5.21
      endif  -- text = ''
;     if text='' then return; endif
      if text<>'' then Shell_lastwrite = text; endif
      writebuf = text\13\10
      retval   = SUE_write(ShellHandle, writebuf, bytesmoved);
      if retval or bytesmoved<>length(writebuf) then
         sayerror "write.retval="retval || "  byteswritten=" bytesmoved "of" length(writebuf)
      endif
   endif
   --
   -- the above code is not really complete.  It should also deal with situations
   --   where only part of the data to be written is written.  It needs to keep the
   --   unwritten data around and put it out again during the "NowCanWriteShell"
   --   comand processing. (todo)

-------------------------------------------------------------NowCanWriteShell------------
defc NowCanWriteShell
   -- Shell object sends this command to inform the editor that there is
   --    room for additional data to be written.
   sayerror SHELL_OBJECT__MSG arg(1) SHELL_READY__MSG -- Use Shell_Write with argumentstring'

-------------------------------------------------------------NowCanReadShell-------------
defc NowCanReadShell
   -- Shell object sends this command to inform the editor that there is
   --    additional data to be read.
   universal EPM_utility_array_ID
   parse arg shellnum .
   if not isnum(shellnum) then
      sayerror 'NowCanReadShell:  'INVALID_ARG__MSG '"'arg(1)'"'
      return
   endif
   do_array 3, EPM_utility_array_ID, 'Shell_f'shellnum, shellfid
   do_array 3, EPM_utility_array_ID, 'Shell_h'shellnum, shellhandle
   bytesmoved = 1;
   while bytesmoved do
      readbuf = copies(' ',MAXCOL)
      retval = SUE_readln(ShellHandle, readbuf, bytesmoved);
      readbuf = leftstr(readbuf, bytesmoved)
      if readbuf=\13 then iterate
      elseif leftstr(readbuf,1)=\10 then
         insertline substr(readbuf,2), shellfid.last+1, shellfid
      else
         getline oldline, shellfid.last, shellfid
         if length(oldline)+length(readbuf)>MAXCOL then
            insertline readbuf, shellfid.last+1, shellfid
         else
            replaceline oldline || readbuf, shellfid.last, shellfid
         endif
      endif
      getline lastline, shellfid.last, shellfid
      shellfid.line = shellfid.last
      shellfid.col = min(MAXCOL,length(lastline)+1)
   endwhile

-------------------------------------------------------------SUE_new---------------------
defproc SUE_new(var shell_handle, shellnum)     -- Called from Shell command
   thandle = '????';
;; sayerror "address=0x" || ltoa(taddr, 16) || "  hwnd=0x"ltoa(hwnd, 16);
compile if EPM32
   result  = dynalink32(ERES_DLL,
                       'SUE_new',
                       address(thandle)             ||
                       gethwndc(EPMINFO_EDITCLIENT) ||
                       atol(shellnum) );
compile else
   result  = dynalink(ERES_DLL,
                      'SUE_NEW',
                      address(thandle) ||
                      gethwnd(EPMINFO_EDITCLIENT) ||
                      atol_swap(shellnum) );
compile endif
   shell_handle = thandle;
   return result;

-------------------------------------------------------------SUE_free--------------------
defproc SUE_free(var shell_handle)     -- Called from Shell_Kill command
   thandle = shell_handle;
compile if EPM32
   result  = dynalink32(ERES_DLL,
                       'SUE_free',
                       address(thandle) )
compile else
   result  = dynalink(ERES_DLL,
                      'SUE_FREE',
                      address(thandle) )
compile endif
   shell_handle = thandle;
   return result;

-------------------------------------------------------------SUE_readln------------------
defproc SUE_readln(shell_handle, var buffe, var bytesmoved)  -- Called from NowCanReadShell cmd
   bufstring = buffe;  -- just to insure the same amount of space is available
   bm        = "??"
compile if EPM32
   result  = dynalink32(ERES_DLL,
                        'SUE_readln',
                        shell_handle               ||
                        address(bufstring)         ||
                        atol(length(bufstring))    ||
                        address(bm))
compile else
   result  = dynalink(ERES_DLL,
                      'SUE_READLN',
                      substr(shell_handle, 3, 2) ||
                      substr(shell_handle, 1, 2) ||
                      address(bufstring)         ||
                      atoi(length(bufstring))    ||
                      address(bm) );
compile endif
   bytesmoved = itoa(bm,10);
   buffe     = bufstring;
   return result;

-------------------------------------------------------------SUE_write-------------------
defproc SUE_write(shell_handle, buffe, var bytesmoved)   -- Called from Shell_Write command
   bm        = "??"
compile if EPM32
   result  = dynalink32(ERES_DLL,
                        'SUE_write',
                        shell_handle                     ||
                        address(buffe)                   ||
                        atol(length(buffe))              ||
                        address(bm))
compile else
   result  = dynalink(ERES_DLL,
                      'SUE_WRITE',
                      substr(shell_handle, 3, 2) || substr(shell_handle, 1, 2) ||
                      address(buffe) ||
                      atoi(length(buffe)) ||
                      address(bm) );
compile endif
   bytesmoved = itoa(bm, 10);
   return result;

compile if EPM32 & not POWERPC
-------------------------------------------------------------Shell_Break-----------------
defc shell_break  -- Sends a Break to a shell object
   universal EPM_utility_array_ID
   parse arg shellnum .
   if shellnum='' & leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
   endif
   if shellnum='' then
      sayerror NOT_IN_SHELL__MSG
      return
   endif
   do_array 3, EPM_utility_array_ID, 'Shell_f'shellnum, shellfid
   do_array 3, EPM_utility_array_ID, 'Shell_h'shellnum, shellHandle
   if shellhandle<>'' then
      retval = SUE_break(ShellHandle);
      if retval then sayerror ERROR_NUMBER__MSG retval; endif
   endif

-------------------------------------------------------------SUE_break-------------------
defproc SUE_break(shell_handle)
   return dynalink32(ERES_DLL,
                     'SUE_break',
                     shell_handle )
compile endif
