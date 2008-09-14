/****************************** Module Header *******************************
*
* Module Name: tree.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: tree.e,v 1.6 2008-09-14 15:32:44 aschn Exp $
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
compile if not defined(ERROR__MSG)
   include 'english.e'
const
   EPM     = EVERSION >= 5
   EPM32   = EVERSION >= 6

defmain
   'tree' arg(1)
compile endif


compile if not defined(MB_OK)
   include 'stdconst.e'
compile endif

const
   TREE__MSG = 'Tree'           -- Dialog title; also the name of the command
   TREE_PROMPT = 'Display files in a given subdirectory or below'
   TREE2_PROMPT = '.  Arguments may be given as a parameter, or will be prompted for otherwise.'
   TREE_PROMPT__MSG = 'Enter arguments for Tree'
   TREE_DIR__MSG = 'Tree_Dir'   -- Dialog title; also the name of the command
   TREE_DIR_PROMPT = 'Like DIR, but output in TREE format'
   TREE_DIR_PROMPT__MSG = 'Enter arguments for Tree_Dir'
; Note:  Translations of the following line must stay aligned with the sample
; separator line below it.  "Full name" can get as wide as necessary.  Stuff in
; parens must be unchanged, but can be shifted left or right.
   TREES_HEADER = '  Date        Time     FileSize    EA-size  Attr.  Full name... (% = %d%p%f ; %f = %n.%e)'
;                 'ออออออออออ  ออออออออ  อออออออออ  อออออออออ  อออออ  ออออออออออออ'

EA_comment 'This defines the TREE and TREE_DIR commands; it can be linked, or TREE can be executed directly.  This is also a toolbar "actions" file.'

--------------------- End of text to be translated ----------------------------

; Here is the <file_name>_ACTIONLIST command that adds the action command
; to the list.

defc TREE_actionlist
   universal ActionsList_FileID  -- This is the fileid that gets the line(s)

   insertline '~tree_action~'TREE_PROMPT || TREE2_PROMPT'~TREE~', ActionsList_FileID.last+1, ActionsList_FileID
   insertline '~tree_dir_action~'TREE_DIR_PROMPT || TREE2_PROMPT'~TREE~', ActionsList_FileID.last+1, ActionsList_FileID

; This is the command that will be called for the above action.

defc tree_action
   parse arg action_letter parms
   if action_letter = 'S' then       -- button Selected
      sayerror 0
      if parms='' then
         'compiler_help_add tree.hlp'     -- Make sure the help file is loaded
         parse value entrybox(TREE__MSG,'/'OK__MSG'/'Cancel__MSG'/'Help__MSG'/',checkini(0, 'TREE_ARG', ''),'',1590,
                atoi(1) || atoi(32115) || gethwndc(APP_HANDLE) ||
                TREE_PROMPT__MSG) with button 2 parms \0
         if button <> \1 then
            return
         endif
         call setini('TREE_ARG', parms)
      endif
      'tree' parms
   elseif action_letter = 'I' then   -- button Initialized
      'SayHint' TREE_PROMPT
   elseif action_letter = 'H' then   -- button Help
      'compiler_help_add tree.hlp'     -- Make sure the help file is loaded
      'helpmenu 32111'                 -- & invoke it.
   elseif action_letter = 'E' then   -- button End
;;    sayerror 0
   endif

defc tree_dir_action
   parse arg action_letter parms
   if arg(1) = 'S' then       -- button Selected
      sayerror 0
      if parms='' then
         'compiler_help_add tree.hlp'     -- Make sure the help file is loaded
         parse value entrybox(TREE_DIR__MSG,'/'OK__MSG'/'Cancel__MSG'/'Help__MSG'/',checkini(0, 'TREE_DIR_ARG', ''),'',1590,
                atoi(1) || atoi(32115) || gethwndc(APP_HANDLE) ||
                TREE_DIR_PROMPT__MSG) with button 2 parms \0
         if button <> \1 then
            return
         endif
         call setini('TREE_DIR_ARG', parms)
      endif
      'tree_dir' parms
   elseif arg(1) = 'I' then   -- button Initialized
      'SayHint' TREE_DIR_PROMPT
   elseif arg(1) = 'H' then   -- button Help
      'compiler_help_add tree.hlp'     -- Make sure the help file is loaded
      'helpmenu 32112'                 -- & invoke it.
   elseif arg(1) = 'E' then   -- button End
;;    sayerror 0
   endif

const
   DEBUG_TREE = 0

defc tree =
   parse arg filename
   call parse_filename(filename, .filename)
   if substr(filename, 1, 1)='"' then
      parse value filename with '"' filename '"'
   endif
   if filename='' then
      filename = '*.*'
   elseif pos(rightstr(filename,1), ':\') then
      filename = filename'*.*'
   endif
   colon = pos(':', filename)
   if not pos('\', filename) & not colon then
      filename = directory()'\'filename
   endif
   if not verify(filename,'?*','M') then  -- If no wildcards
      if not qfilemode(filename, attrib) then  -- File exists
         if attrib bitand 16 then  -- If x'10' is on then it's a directory
            lp = lastpos('\', filename)
            if not lp then lp=colon; endif
            result = winmessagebox('Tree:  Directory exists:  'filename, 'Select Yes to search' filename'\*'\10'Select No to search' leftstr(filename, lp) 'for files named "'substr(filename, lp+1)'"', MB_YESNOCANCEL + MB_QUERY + MB_MOVEABLE)
            if result=MBID_CANCEL then
               return
            endif
            if result=MBID_YES then
               filename = filename'\*'
            endif
         endif
      endif
   endif
   getfileid startid
   'xcom e /c .tree'
   if rc & rc<>sayerror('New file') then
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return rc
   endif
   getfileid tree_id
   'xcom e /c .dirs'
   if rc & rc<>sayerror('New file') then
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return rc
   endif
   getfileid dirs_fid
   .visible = 0                                  -- Make hidden
   file_count = 0
   total_size = 0
   attribute = 55        -- Want to see all files
   files_truncated = 0
   if colon then
      parse value filename with drives ':' filepart
      filename = 'x:'filepart  -- make lp be loop invariant
   else
      drives = ' '         -- Want loop to be executed at least once.
   endif
   lp=lastpos('\', filename)
   if not lp & colon then lp=2; endif
   deleteline 1
   do i=1 to length(drives)
      if colon then
         filename = substr(drives, i, 1)':'filepart
      else
         drives = ' '         -- Want loop to be executed at least once.
      endif

      insertline leftstr(filename,lp), 1
      filename = substr(filename, lp+1)
      do while dirs_fid.last
         getline file_path, 1, dirs_fid
         if file_path<>'' & not pos(rightstr(file_path,1), ':\') then
            file_path = file_path'\'
         endif
compile if DEBUG_TREE
         debug_message( 'dirs last =' dirs_fid.last 'file_path = "'file_path'"')
compile endif
         deleteline 1, dirs_fid
         call tree_searchdir(file_path || filename, attribute, file_count, total_size, 0, tree_id)
         call tree_searchdir(file_path'*.*', 4151, junk, junk, 1, dirs_fid)
      enddo      -- dirs_fid.last
   enddo       -- drives
   activatefile dirs_fid
   .modify = 0
   .autosave = 0
   'xcom quit'
   activatefile tree_id
   call tree_common_finish(tree_id, file_count, total_size, 'Tree:' arg(1), files_truncated)

defc tree_dir =
   parse arg filename
   call parse_filename(filename, .filename)
   if substr(filename, 1, 1)='"' then
      parse value filename with '"' filename '"'
   endif
   if filename='' then
      filename = '*.*'
   elseif pos(rightstr(filename,1), ':\') then
      filename = filename'*.*'
   endif
   if not pos('\', filename) & substr(filename,2,1)<>':' then
      filename = directory()'\'filename
   endif
   if not verify(filename,'?*','M') then  -- If no wildcards
      if not qfilemode(filename, attrib) then  -- File exists
         if attrib bitand 16 then  -- If x'10' is on then it's a directory
            filename = filename'\*.*'
         endif
      endif
   endif
   'xcom e /c .tree'
   if rc & rc<>sayerror('New file') then
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return rc
   endif
   getfileid tree_id
   file_count = 0
   total_size = 0
   attribute = 55        -- Want to see all files
   res= tree_searchdir(filename, attribute, file_count, total_size, 0, tree_id)
   call tree_common_finish(tree_id, file_count, total_size, 'Tree_Dir:' arg(1), res)


defproc tree_common_finish(tree_id, file_count, total_size, title)
   if tree_id.modify then
      replaceline TREES_HEADER, 1
      insertline 'ออออออออออ  ออออออออ  อออออออออ  อออออออออ  อออออ  ออออออออออออ', 2
      insertline '          'file_count 'file(s)   'total_size 'bytes used', .last+1
      .lineg = 3
      .col = 52
      .titletext = title
      'postme monofont'
      'postme tabs 1 13 23 34 45 52'
      sayerror ALT_1_LOAD__MSG
      .modify = 0
   else
      'xcom q'
      sayerror 'No hits.'
   endif


; The arguments to Tree_SearchDir are as follows:
;
; filename:  The fully-qualified name we're searching for.
; attribute:  The file attributes we pass to DosFindFirst
; file_count:  Incremented for each "hit".
; total_size:  Incremented by the filesize for each "hit".
; dir_only:  A flag to say if we're looking for directories only (for sweeping the tree).
; out_fid:  The fileid where the output is to be appended.
;
defproc tree_searchdir(filename, attribute, var file_count, var total_size, dir_only, out_fid)
compile if DEBUG_TREE
   debug_message( 'tree_searchdir('filename', 'attribute', ..., 'dir_only', 'out_fid '=' out_fid.filename)
compile endif
   wild_prefix=substr(filename,1,lastpos('\', filename))
   if wild_prefix='' & substr(filename, 2, 1)=':' then wild_prefix = leftstr(filename, 2); endif
   parse value filename with filename ',' masks
   truncated = 0  -- Initialize
   do forever  -- Until masks run out
      namez    = filename\0    -- ASCIIZ
      resultbuf = copies(\0, 300)  -- Might need to allocate a buffer if < EPM 5.60
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

compile if not DEBUG_TREE
      if result & result <> 18 & result <> 3 then  -- unexpected error, skip remaining masks.
sayerror 'result' result 'from DosFindFirst' filename
         return result
      endif
compile else  -- debug
      if result then
         if     result = 2   then msg = 'FILE NOT FOUND'
         elseif result = 3   then msg = 'PATH NOT FOUND'
         elseif result = 6   then msg = 'INVALID HANDLE'
         elseif result = 18  then msg = 'NO MORE FILES'
         elseif result = 26  then msg = 'NOT DOS DISK'
         elseif result = 87  then msg = 'INVALID PARAMETER'
         elseif result = 108 then msg = 'DRIVE LOCKED'
         elseif result = 111 then msg = 'BUFFER OVERFLOW'
         elseif result = 113 then msg = 'NO MORE SEARCH HANDLES'
         elseif result = 206 then msg = 'FILENAME EXCED RANGE'
         endif
         debug_message( 'Error' result '('msg') for "'filename'"')
         if result <> 2 & result <> 18 & result <> 3 then return result; endif
      endif
compile endif
      if not result then
         loop
            filename = substr(resultbuf, 34, asc(substr(resultbuf, 33, 1)))
            fileattrib = ltoa(substr(resultbuf,25,4),10)
            skip = filename='.' | filename='..' -- Not a directory we want!
            filename = wild_prefix || filename
            if dir_only then
               if not (fileattrib//32%16) then  -- Not a directory?
                  skip = 1  -- Check, because apparently LAN drives don't respect "Must have" attributes...
               endif
               if not skip then
                  insertline filename, out_fid.last + 1, out_fid
               endif
            else
compile if DEBUG_TREE
               debug_message('Hit on "'filename'" - out_fid.last =' out_fid.last)
compile endif
               filedate = substr(resultbuf, 13, 4)
               file_size = ltoa(substr(resultbuf,17,4),10)
;        filealloc = ltoa(substr(resultbuf,21,4),10)
               ea_size = ltoa(substr(resultbuf,29,4),10)
               file_count = file_count + 1
               total_size = total_size + file_size
               date = ltoa(substr(filedate,1,2)\0\0,10); time = ltoa(substr(filedate,3,2)\0\0,10)
               year = date % 512; date = date // 512
               month = date % 32; day = date // 32 % 1     -- %1 to drop fraction.
               date = year+1980'-'rightstr(month,2,0)'-'rightstr(day,2,0)
               hour = time % 2048; time = time // 2048
               min = time % 32; sec = time // 32 * 2 % 1
               time = rightstr(hour,2)':'rightstr(min,2,0)':'rightstr(sec,2,0)
               if ea_size=4 then
                  ea_size=0
               else
                  ea_size=ea_size%2
               endif
               attr_string = '     '
               if fileattrib bitand 32 then
                  attr_string = overlay('A', attr_string, 1)
               endif
               if fileattrib bitand 16 then
                  attr_string = overlay('D', attr_string, 2)
                  file_size = '<dir>'
               endif
               if fileattrib bitand 4 then
                  attr_string = overlay('S', attr_string, 3)
               endif
               if fileattrib bitand 2 then
                  attr_string = overlay('H', attr_string, 4)
               endif
               if fileattrib bitand 1 then
                  attr_string = overlay('R', attr_string, 5)
               endif
               file_size = rightstr(file_size, 10)
               out_line = date'  'time file_size rightstr(ea_size,10)'  'attr_string'  'filename
               if not skip then
                  insertline out_line, out_fid.last + 1, out_fid
               endif
            endif  -- dir_only
            result=dynalink32('DOSCALLS',             -- dynamic link library name
                              '#265',                 -- ordinal value for DOS32FINDNEXT
                              dirhandle           ||  -- Directory handle, returned by DosFindFirst(2)
                              address(resultbuf)  ||  -- address of result buffer
                              atol(length(resultbuf)) ||
                              address(searchcnt), 2)  -- Pointer to the count; system updates
            if result then
               call dynalink32('DOSCALLS',             -- dynamic link library name
                               '#263',                 -- ordinal value for DOS32FINDCLOSE
                               dirhandle)              -- Directory handle, returned by DosFindFirst(2)
               if result<>18 then
                  sayerror UNEXPECTED__MSG 'DosFindNext' result
               endif
               leave
            endif
         endloop
      endif  -- result from DosFindFirst
      if masks='' then
         leave
      endif
      parse value masks with mask ',' masks
      filename = wild_prefix || strip(mask)
   enddo

compile if DEBUG_TREE
defproc debug_message(msgstring) =
   sayerror msgstring
compile endif

defc treesort =
   revrse = ''
   startmod = .modify
   arglist = upcase(arg(1))
   getfileid thisfid
   call psave_mark(savemark)
   mt = marktype()
   firstline = 3; lastline = .last-1
   if mt then
      getmark firstl, lastl, firstcol, lastcol, markfileid
      if markfileid=thisfid & firstline<>lastline then
         firstline = firstl; lastline = lastl
      endif
   endif
   do while arglist<>''
      result = 0
      parse value arglist with thisarg arglist
      if     abbrev('/REVERSE', thisarg, 2) then
         revrse = 'R'
      elseif abbrev('/FORWARD', thisarg, 2) then
         revrse = ''
      elseif abbrev('DATE', thisarg, 1) then
         result = sort(firstline, lastline, 1, 20, thisfid, revrse)
      elseif abbrev('TIME', thisarg, 1) then
         result = sort(firstline, lastline, 13, 20, thisfid, revrse)
      elseif abbrev('SIZE', thisarg, 1) then
         result = sort(firstline, lastline, 21, 31, thisfid, revrse)
      elseif abbrev('EASIZE', thisarg, 2) then
         result = sort(firstline, lastline, 32, 42, thisfid, revrse)
      elseif abbrev('FILENAME', thisarg, 1) |
             abbrev('FULLNAME', thisarg, 2) then
         result = sort(firstline, lastline, 52, 260, thisfid, 'CI'revrse)
      elseif abbrev('NAME', thisarg, 1) |
             abbrev('EXTENSION', thisarg, 2) then
         ext = leftstr(thisarg, 1) = 'E'
         do l = firstline to lastline
            line = textline(l)
            p = lastpos('\', line)
            if ext then
               p1 = lastpos('.', line)
               if p1>p then p = p1; endif
            endif
            replaceline substr(line, p+1) || \0 || leftstr(line, p), l
         enddo
         result = sort(firstline, lastline, 1, 260, thisfid, 'CI'revrse)
         do l = firstline to lastline
            parse value textline(l) with p2 \0 p1
            replaceline p1 || p2, l
         enddo
      else
         sayerror sayerrortext(-263) '-' thisarg
      endif
      if result then
         sayerror 'SORT' ERROR_NUMBER__MSG result
      endif
   enddo
   .modify = startmod
   call prestore_mark(savemark)
