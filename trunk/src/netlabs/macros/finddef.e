/****************************** Module Header *******************************
*
* Module Name: finddef.e
*
* Copyright (c) Netlabs EPM Distribution Project 2006
*
* $Id: finddef.e,v 1.3 2006-11-19 22:57:18 jbs Exp $
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

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'FINDDEF.E'

include 'stdconst.e'
EA_comment 'This defines the FindDef command.'

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'

defmain
   'FindDef' arg(1)

compile endif

; ---------------------------------------------------------------------------
; Search for "definitions" within source files for a given mode and keyword.
; Returns a file list with all found files and line numbers, ready to be
; processed by the ListBox proc.
; Syntax: ret = ModeFindDef( <mode>, <keyword>)
;         with ret = <number of found files>','<file list>
defproc ModeFindDef
   Mode = arg(1)
   Keyword = arg(2)

   -- First check, if a grep search string for the given Mode is defined.
   if Mode = 'E' then
      -- Search for "definitions" within NEPMD E macros.
      -- Note: Special strings "init", "main", "keys", "load", "exit",
      -- "select" and "modify" result in all "definit", "defmain", etc. are
      -- found and loaded. Otherwise the string is considered to be the name
      -- of a defc, defproc or def.
      RootDir = NepmdScanEnv( 'NEPMD_ROOTDIR')
      FileMask = RootDir'\myepm\macros\*.e' RootDir'\netlabs\macros\*.e'
      Keyword = lowcase( Keyword)
      SpecialDefList = 'init main keys load exit select modify'
      -- Strip a leading 'def' to make it work with 'defmain' and 'main'
      parse value Keyword with 'def'next
      if length( next) > '' then
         if wordpos( next, SpecialDefList) > 0 then
            Keyword = next
         endif
      endif
      if wordpos( Keyword, SpecialDefList) > 0 then
         GrepArgs = '"^def"'Keyword'"\>" 'FileMask
      elseif isadefproc( Keyword) then
         GrepArgs = '"^defproc[[:alnum:] ,_]*[ ,]"'Keyword'"\>" 'FileMask
      elseif isadefc( Keyword) then
         GrepArgs = '"^defc[[:alnum:] ,_]*[ ,]"'Keyword'"\>" 'FileMask
      else
         GrepArgs = '"^def[[:alnum:] ,_]*[ ,]"'Keyword'"\>" 'FileMask
      endif

   elseif Mode = 'C' then
      -- Add DPATH directories, too?
      -- Add other directories?
      FileMask = directory() || '\*.c'
      -- The following search string works only if the entire parameter list
      -- and the return type is on the same line as the function name.
      search = '"^([ \t]*[[:alpha:]_]+[[:alnum:]_]*)*[* \t]*' || Keyword || '[ \t]*\((\n|.*)\)[ \t]*\{?[ \t]*$"'
      GrepArgs = '-EnH' search FileMask

   --elseif Mode = '...' then

      -- Add more modes here.
      -- Specify GrepArgs determined from the submitted Keyword and from a
      -- mode-specific FileMask.

   else         -- Modes not yet supported by FINDDEF
      return '-1,dummy'
   endif

   fVerbose = 0
   fGnu = 1  -- only GNU grep is supported
   rc = CallGrep( fGnu, GrepArgs, fVerbose)  -- stops on error

   Delim = \1
   Filelist = ''
   nFiles = 0
   fTruncated = 0
   getfileid grepfid
   sayerror 'grepfid.last: 'grepfid.last
   if grepfid.last > 1 then  -- found something?

      -- Create a temp. file
      'xcom e /c /q .tempfile'
      if rc <> -282 then  -- sayerror('New file')
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      getfileid tempfid
      .autosave = 0
      browse_mode = browse()  -- query current state
      if browse_mode then
         call browse(0)
      endif
      -- Listbox_Buffer_From_File requires the first empty line that E always
      -- creates for new files.

      -- Parse grep output
      do i = 2 to grepfid.last  -- first line is 'Current directory = ...'
         activatefile grepfid
         Line = textline( i)
         activatefile tempfid
         p1 = pos( ':', Line, 3)
         p2 = pos( ':', Line, p1 + 1)
         if p1 = 0 | p2 = 0 then
            leave
         endif
         FileName = leftstr( Line, p1 - 1)
         LineNum = substr( Line, p1 + 1, p2 - p1 - 1)
         if not IsNum( LineNum) then
            leave
         endif
         next = FileName '('LineNum')'

         -- Write filelist to a temp. file
         insertline next, .last + 1
         nFiles = nFiles + 1

         -- Return the FileList as var as well, in order to enable 'Open all'
         -- and 'Add all' for loading (maybe a truncated) list of files into
         -- EPM. (Unfortunately one can't activate multiple selection for
         -- EPM's listbox, in order to get rid of those buttons and of the
         -- FileList var. Maybe with patched resources this would get
         -- possible.)
         -- Check for E's max. string length, '+ 1' in the middle for the
         -- comma, last '+ 1' for the ! char
         if not fTruncated then
            if length( nFiles + 1) + 1 + length( next) + 1 > 1599 then
               -- Add ! as truncated mark later
               fTruncated = 1
            else
               FileList = FileList''Delim''next
            endif
         endif
      end
   endif
   if fTruncated then
      -- Add ! as truncated mark
      nFiles = '!'nFiles
   endif

   activatefile grepfid
   'quit'                -- quit the grep window
   if nFiles > 0 then
      activatefile tempfid
   endif

   return nFiles','FileList

; ---------------------------------------------------------------------------
; This should better be replaced by a global available defproc, querying a
; mode's charset from NEPMD.INI, when that will be implemented.
defproc GetCharSet
   Mode = arg(1)
   if 0 then
   --elseif Mode = ... then  -- add Modes here
   else
      CharSet = '_.0123456789abcdefghijklmnopqrstuvwxyz'
   endif
   return CharSet

; ---------------------------------------------------------------------------
; Syntax: FindDef [<keyword> [<mode>]]
; Search source files for the definition of a keyword. If no keyword is
; specified, then the word under the cursor is taken. Calls ModeFindDef to
; perform a mode-specific search.
defc FindDef
   universal nepmd_hini

   parse arg Keyword Mode
   Keyword = strip( Keyword)
   Mode = upcase( strip( Mode))
   if Mode = '' then
      Mode = GetMode()
   endif

   if Keyword = '' then
      StartCol = 0
      EndCol   = 0
      -- get identifier under cursor
      if not find_token( StartCol, EndCol) then  -- only look for keywords if cursor is on a word
         sayerror 'No word under cursor.'
         return
      endif
      Keyword = substr( textline(.line), StartCol, EndCol - StartCol + 1)
      CharSet = GetCharSet( Mode)
      if not verify( lowcase( Keyword), CharSet, 'M') then
         sayerror 'No keyword under cursor.'
         return
      endif
   endif

   rcx = GetGrepVersion( 'INIT')
   if rcx = 2 then
      sayerror 'Error: Grep not found in PATH.'
      return
   elseif rcx = 0 then
      sayerror 'Error: Only Gnu grep is supported.'
      return
   endif

   getfileid startfid
   -- ModeFindDef creates a temp. file, that is read by
   -- Listbox_Buffer_From_File
   next = ModeFindDef( Mode, Keyword)
   sayerror 'next: 'next
   parse value next with nFiles ',' FileList
   fTruncated = 0
   if leftstr( nFiles, 1) = '!' then
      fTruncated = 1
      parse value nFiles with '!'nFiles
   endif

   if nFiles < 1 then
      if nFiles = 0 | length( FileList) < 2 then
         sayerror '"'Keyword'" not found in source files. Used mode: 'Mode'.'
      else
         sayerror 'Mode "'Mode'" is not yet supported by FINDDEF.'
      endif
      return
   endif

   -- Open Listbox
   Delim = leftstr( FileList, 1)
   Title = 'Select a source file'
   Text = nFiles 'definition(s) found for "'Keyword'". Used mode: 'Mode'.'  -- no Linebreak possible
   DefaultItem = 1
   KeyPath = '\NEPMD\User\LastStuff\LastFindDefButton'
   DefaultButton = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if DefaultButton = '' then
      DefaultButton = 1
   endif
   HelpId = 0

   -- Listbox_Buffer_From_File uses the current file for buffer input and
   -- quits that file after processing. It returns '' when the buffer was
   -- created.
   if Listbox_Buffer_From_File( startfid, bufhndl, noflines, usedsize) then
      return
   endif
   refresh
   ret = ListBox( Title,
                  \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                  '/~Add/~Open/A~dd all/O~pen all/Cancel',   -- buttons
                  0, 0,   -- top, left,
                  8, 80,  -- height, width
                  gethwnd(APP_HANDLE) || atoi(DefaultItem) || atoi(DefaultButton) || atoi(HelpId) ||
                  Text\0)
   call buffer( FREEBUF, bufhndl)
   refresh

   -- Check result
   Button = asc(leftstr( ret, 1))
   EOS = pos( \0, ret, 2)        -- CHR(0) signifies End Of String
   Select = substr( ret, 2, EOS - 2)

   if Button < 1 | Button > 4 then  -- Cancel
      return
   endif

   -- Save selected button for next call
   call NepmdWriteConfigValue( nepmd_hini, KeyPath, Button)
   -- Set number and list of files to load
   if Button = 1 | Button = 2 then  -- load one file
      Files = Select
   elseif Button = 3 | Button = 4 then  -- load all files
      -- Move leading Delim to the end for easier parsing
      parse value FileList with (Delim)FileList
      Files = FileList''Delim
   endif

   -- Convert Files from \1file1 (line1)\1file2 (line2) to file1 'line1' file2 'line2'
   -- and maybe enquote filenames
   rest = Files
   Files = ''
   f = 0
   do while rest <> ''
      parse value rest with File '('LineNum')'(Delim) rest
      File = strip( File)
      if pos( ' ', File) then
         File = '"'File'"'
      endif
      next = File "'"LineNum"'"
      -- An EPM cmdline seems to be limited to 512 chars
      if length( Files) + length( next) < 512 - 2 then
         Files = Files next
         f = f + 1
      endif
   enddo
   Files = strip( Files)

   if Button = 1 | Button = 3 then
      Cmd = 'e' Files
   else
      Cmd = 'o' Files
   endif
   -- Execute it
   Cmd

   if f = 1 then
      sayerror f 'file loaded.'
   elseif f < nFiles then
      sayerror f' of 'nFiles' files loaded.'
   else
      sayerror f 'files loaded.'
   endif

