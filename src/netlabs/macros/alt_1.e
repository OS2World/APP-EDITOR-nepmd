/****************************** Module Header *******************************
*
* Module Name: alt_1.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: alt_1.e,v 1.18 2006-03-11 19:57:57 aschn Exp $
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

--          (Alt-1.e should be renamed alt_1.e for CD-ROM...)
-- Alt-One.E   Bells & whistles for the Alt-1 key.   Bryan Lewis  03/08/87
--
-- I use the Alt-1 key a lot, to edit the file named in the current text line.
-- Very handy along with the commands LIST and SCAN, and with source code.
-- I've jazzed it up so I can hit it when working with:
--
--   1. Lists output by SCAN.COM (see SCAN.E), in the form:
--        --- c:\e3\mykeys.e    3/4/87 1:04p  21136 ---
--   2. E3 source which contains lines like:
--        include 'colors.e'
--   3. C source which contains lines like:
--        #include <dos.h>
--   4. Any old list of filenames to which I've added comments.
--      All text after the filename is ignored.
--   5. Cross-reference lists output by C-USED.
--   6. File lists from the host.
--   7. Lists output by GREP with filenames like "File #0==> CKEYSEL.E <==".
--
--- History, latest change first ----------------------------------------------
--
-- Modified 11/10/88 by TJR:  ALT-ONE may be used to load a file
-- specified by H:*PROCS INDEX (currently only E3PROCS INDEX).  The
-- file will be loaded, and the cursor moved to the line containing
-- the macro of interest.  This is lightning fast once the files
-- are in the ring, and is the perfect tool for anyone who looks through
-- E3PROCS.  When is EOS2PROCS INDEX coming out?  You guys in aisle
-- 32 better keep the same format :-).
--
-- Modified 11/09/88 by TJR:  ALT-ONE will now work even better with
-- the output of GREP.E by TJR.  If the current line of the .grep
-- file is a file listing (see number 7 above), then pressing ALT-1
-- will open the specfied file for editing.  If the current line is
-- not a file specification, then it must be a line within the previous
-- file specified.  If this is the case, then that file will be opened,
-- and the cursor moved to the line specified in the file.  The current
-- line of the new file will be highlighted for quick recognition.
-- Many thanks to Bryan Lewis for all his help.
--
-- Modified 8/9/88 by jbl:  Alt-One will search along a user-specified path.
-- You need this if you usually store your include files somewhere other than
-- the current directory.  I borrowed code from the USE_APPEND feature of
-- standard E (by Ken Kahn, Larry Margolis, and me).
--
-- This is good for editing C or E programs when the include files lie in a
-- different directory, for example:
--
--    #include "foo.e"
--
-- Alt-One will look first in the current directory and then along the path
-- specified by the ESEARCH environmewnt variable.  For instance, you might do:
--
--    C> set esearch=c:\current\et;d:\old\include
--
-- A special feature for C programmers:  If you turn on the constant C_INCLUDE,
-- filenames enclosed in angle brackets will not be looked for in the current
-- directory but along the path specified by the INCLUDE environment variable.
--
-- The ESEARCH feature works for any list of filenames, not just source code.
--
-------------------------------------------------------------------------------
-- Modified 10/19/87 by Chris Codella to handle tryincludes and includes not
-- starting in column 1, and includes with imbedded blanks.  10/19/87
-------------------------------------------------------------------------------
-- Modified by Bryan Lewis to handle lines in a cross-reference listing
-- produced by C-USED, resembling:
--
--   statement                               36 STAT.C
--     1 stat                                31 MAIN.C
--
-- If I press Alt-1 on the first line I want to edit STAT.C and search for the
-- word "statement".  For the second line I want to edit MAIN.C and search for
-- "stat" (the containing function) and then "statement".  I don't trust the
-- line numbers to stay constant.
-- I turn on this feature if the filetype is "USE" or "XRF".

; ---------------------------------------------------------------------------
compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'ALT_1.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

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
   include 'stdconst.e'
   EA_comment 'This defines the Alt_1 command.'

 compile if not defined(HOST_SUPPORT)
   HOST_SUPPORT = ''
 compile endif

defmain
   'alt_1'

compile endif

; ---------------------------------------------------------------------------
const                          -- These are ALT_1.E-specific constants.
compile if not defined(AltOnePathVar)
   AltOnePathVar= 'ESEARCH'    -- the name of the environment variable
compile endif

; consts for parsing dir listings
compile if not defined(DIR_DATETIME_CHARS)
   DIR_DATETIME_CHARS = '0123456789.-:'  -- better use '0123456789._-/:' ?
compile endif
compile if not defined(DIR_SIZE_CHARS)
   DIR_SIZE_CHARS     = '0123456789.,'   -- 4os2 uses '.' as thousands separator
compile endif
compile if not defined(DIR_ATTRIB_CHARS)
   DIR_ATTRIB_CHARS   = 'ashr-'
compile endif
; Not used anymore
;define
;   QUOTED_DIR_STRING ='"'DIRECTORYOF_STRING'"'

; ---------------------------------------------------------------------------
defc alt_1, a_1
   universal host_LT                    -- Used with LAMPDQ.E
compile if HOST_SUPPORT
   universal hostdrive
compile endif
   -- edit filename on current text line
   getline line
   orig_line = line

   -------------------------------------------------------------------------- shell or .DOS DIR
   -- todo: enable saved .command_shells as well  <-- also for mode = SHELL, to re-use them
   call psave_pos(save_pos)
   getsearch oldsearch
   cmd = ''
   if leftstr( .filename, 15) = '.command_shell_' then
      -- search (reverse) in command shell window for the prompt and retrieve the current directory and
      --    the cmd and its parameters
      -- goto previous prompt line
      ret = ShellGotoNextPrompt( 'P')
      curdir = ''
      cmd = ''
      Params = ''
      if not ret then
         call ShellParsePromptLine( curdir, cmd)
         parse value cmd with cmd Params
      endif
      setsearch oldsearch
      call prestore_pos(save_pos)
   elseif upcase( leftstr( .filename, 8)) = '.DOS DIR' then
      -- if a .DOS DIR window,
      parse value upcase(.filename) with '.DOS DIR' Params  -- retrieve params from the title
      cmd = 'DIR'
      curdir = directory() -- set current directory
   endif

   if upcase(cmd) = 'DIR' then  -- if "dir" executed as last cmd in .command_shell_ or if .DOS DIR
      Flags    = ''
      Mask     = ''
      Dir      = ''
      FullName = ''
      call Alt1ParseDirParams( Params, Flags, Mask)  -- parse Params and DIRCMD env var, set Flags and Mask

      if pos( 'B', Flags) then  -- if DIR /B, lines are filenames only and there is no "Directory of" line
         Name = line
         wildcardpos = verify( Mask, '*?', 'M')
         if wildcardpos then                               -- if a wildcard is used
            bslashpos = lastpos( '\', Mask, wildcardpos)   --   find the last '\' preceding the wildcard
            if bslashpos then                              --   if found, set dir to mask up to but not
               if pos( ':', Mask) = bslashpos - 1 then     --     if root dir
                  dirname = leftstr( Mask, bslashpos)      --       including the found '\'
               else                                        --     else
                  dirname = leftstr( Mask, bslashpos - 1)  --       excluding the found '\'
               endif
            else
               dirname = ''                                --   else there is no dir in the mask
            endif
         else
            dirname = Mask                                 -- else (no wildcards) the mask is the dir
         endif

         -- Check if dirname is fully qualified
         if substr( dirname, 1, 2) = '\\' then  -- UNC names must be fully qualified, because CD is not allowed
            Dir = dirname

         elseif substr( dirname, 2, 2) = ':\' then
            Dir = dirname

         elseif substr( dirname, 2, 1) = ':' then  -- drive with relative path
            curdrive = upcase( substr( curdir, 1, 2))   -- drive of prompt dir
            drive    = upcase( substr( dirname, 1, 2))  -- specified drive
            if upcase( leftstr( .filename, 8)) = '.DOS DIR' then  -- .DOS DIR cannot change current dir so use it
               Dir = dirname
            elseif curdrive = drive then
               Dir = strip( curdir, 'T', '\')'\'substr( dirname, 3)
            else  -- if shell session, find current dir of specified drive in previous CD commands
               prevdir  = ''
               cddir    = ''
               do while (prevdir = '')
                  repeatfind  -- find the previous prompt
                  if rc <> 0 then  -- if prompt not found
                     leave
                  endif
                  next = ''
                  rest = ''
                  call ShellParsePromptLine( next, rest)
                  parse value upcase( strip( rest)) with 'CD'cdparam
                  if strip( cdparam) > '' then
                     parse value strip( rest) with 3 cdparam  -- get case back
                  endif
                  cdparam = strip( cdparam)
                  if upcase( leftstr( cdparam, 2)) = drive then
                     if substr( cdparam, 3, 1) = '\' then  -- cd full_path found
                        prevdir = cdparam
                     else                                  -- cd relative_path found
                        thiscddir = substr( cdparam, 3)
                        if cddir = '' then
                           cddir = thiscddir
                        elseif thiscddir > '' then
                           cddir = strip( thiscddir, 'T', '\')'\'cddir
                        endif
                        sayerror 'cddir = 'cddir
                     endif
                  elseif upcase( leftstr( next, 2)) = drive then  -- drive found in prompt
                     prevdir = next
                  endif
               enddo
               setsearch oldsearch
               call prestore_pos(save_pos)

               --sayerror 'drive = 'drive', prevdir = 'prevdir', cddir = 'cddir', dirname = 'dirname
               if prevdir = '' then
                  if cddir > '' then
                     Dir = drive''strip( cddir, 'T', '\')'\'substr( dirname, 3)
                  else
                     Dir = dirname
                  endif
               else
                  if cddir > '' then
                     prevdir = strip( prevdir, 'T', '\')'\'cddir
                  endif
                  --sayerror 'prevdir = 'prevdir
                  -- use found dir and append specified path without drive
                  Dir = strip( prevdir, 'T', '\')'\'substr( dirname, 3)
               endif
            endif

         else                                        -- relative path without drive
            -- use curdir
            if leftstr( dirname, 1) == '\' then          -- if path starts with '\'
               Dir = leftstr( curdir, 2)''dirname        --   prepend the current drive
            else
               Dir = strip( curdir, 'T', '\')'\'dirname  -- else prepend entire current dir
            endif

         endif

         -- Build FullName from Dir and Name
         if rightstr( Dir, 1) = ':' then  -- if drive without a path
            FullName = Dir''Name
         else
            FullName = strip( Dir, 'T', '\')'\'Name
         endif
         -- Resolve FullName according to OS/2 syntax, esp. '..' and '.'
         -- Doesn't check if file or dir exists.
         -- Note: DosQueryPathInfo can't handle trailing '\' if not a root dir.
         next = NepmdQueryFullName( FullName)
         parse value next with 'ERROR:'ret
         if ret = '' then
            FullName = next
         else
            sayerror 'defc a_1: QueryFullName: rc = 'ret
         endif

      elseif pos( 'F', flags) then  -- if DIR /F, then the line is the fully-qualified filename
                                    -- Note: DIR /F /B is resolved to DIR /B.
         FullName = line

      else  -- if not DIR /F or DIR /B, then parse the dir listing
         Name = ''

         -- Check if word under cursor is fully qualified
         p1 = pos( ':\', line)
         p2 = pos( '\\', line)
         if p1 > 0 then
            FullName = strip( substr( line, p1 - 1))
         elseif p2 > 0 then
            FullName = strip( substr( line, p2))
         endif

         if FullName = '' then
            if verify( word( line, 1), DIR_DATETIME_CHARS) = 0 &            -- date
               Alt1VerifyTime( word( line, 2), DIR_DATETIME_CHARS) then     -- time
               -- probably a dir listing, not FAT
               NameIsDir = (word( line, 3) = '<DIR>')
               if verify( word( line, 3), DIR_SIZE_CHARS) = 0 |             -- size
                  NameIsDir then
                  if verify( word( line, 4), DIR_SIZE_CHARS) = 0 then       -- EAsize
                     if verify( word( line, 5), DIR_ATTRIB_CHARS) = 0 &     -- attribs if /v specified
                        length( word( line, 5)) = 4 &
                        word( line, 6) <> '' then
                        Name = subword( line, 6)
                     else
                        Name = subword( line, 5)
                     endif
                  else
                     --sayerror 'non-FAT EA size is invalid'
                  endif
               else
                  --sayerror 'non-FAT size is invalid'
               endif
            elseif verify( word( line, words(line) - 1), DIR_DATETIME_CHARS) = 0 &  -- date
               Alt1VerifyTime( word( line, words(line)), DIR_DATETIME_CHARS) then   -- time
               -- probably a dir listing, FAT
               --sayerror 'passed FAT code date/time verify'
               NameIsDir = (word( line, words(line) - 2) = '<DIR>')
               if verify( word( line, words(line) - 2), DIR_SIZE_CHARS) = 0 |       -- size
                  NameIsDir then
                  p = wordindex( line, words(line) - 2)  -- col of 3rdlast word
                  Name = strip( substr( line, 1, p - 1))
                  HasExtCol = ((substr( Name, 9, 1) = ' ') & (pos( Name, '.') = 0))  -- listing with separated extension column
                  if HasExtCol then
                     Name = strip( substr( Name, 1, 9 - 1))'.'substr( Name, 9 + 1)
                  endif
               endif
            else -- both FAT and non-FAT date/time edits failed
               --sayerror 'Unable to identify format (FAT/non-FAT)'
            endif
            --sayerror 'Name = 'Name', NameIsDir = 'NameIsDir
            if Name > '' then
               -- Determine listed dir language-independently
               fFoundDir  = 0
               fCheckNext = 0
               l = .line
               do while fFoundDir = 0
               -- search upwards
                  l = l - 1
                  if l < 1 then
                     leave
                  endif
                  getline curdirline, l
                  -- Find the next empty line
                  if curdirline = '' then
                     fCheckNext = 1  -- Next line contains the current dir (Directory of ...)
                  elseif fCheckNext then
                     p1 = lastpos( ':\', curdirline)
                     p2 = lastpos( '\\', curdirline)
                     if p1 > 0 then
                        Dir = strip( substr( curdirline, p1 - 1))
                        fFoundDir = 1
                        leave
                     elseif p2 > 0 then
                        Dir = strip( substr( curdirline, p2))
                        fFoundDir = 1
                        leave
                     else  -- Maybe user added an empty line to dir listing
                        fCheckNext = 0
                     endif
                  endif
               enddo
               if fFoundDir then
                  -- Handle 4os2 output, that lists not only the name of the dir, but
                  -- appends the wildcard segment, if specified:
                  lp = lastpos( '\', Dir)
                  lastseg = substr( Dir, lp)
                  if verify( lastseg, '*?', 'M') then
                     -- Strip last segment
                     Dir = substr( Dir, 1, lp - 1)
                  endif
                  -- Build FullName
                  FullName = strip( Dir, 'T', '\')'\'Name
               endif
            else
               sayerror 'Unable to parse file name from directory listing'
            endif
         endif -- if FullName = ''

      endif -- if DIR /B

      if FullName = '' then
         FullName = Name
      endif
      attrib = ''
      -- qfilemode: Check if file or dir exists and query attribs
      if (qfilemode(FullName, attrib) = 0) & (FullName > '') then
         if verify( FullName, ' =', 'M') then  -- enquote
            FullName = '"'FullName'"'
         endif
         if (attrib bitand 16) <> 0 then    -- if directory bit is set
            'dir 'FullName
         else                               -- if NOT a directory
            'e 'FullName
         endif
         return
      else
         sayerror 'No such file/dir: 'FullName
      endif

   endif -- if DIR command

   -------------------------------------------------------------------------- .tree
   if .filename = '.tree' then
      if substr( line, 5, 1)''substr( line, 8, 1)''substr( line, 15, 1) ||
         substr( line, 18, 1) = '--::' then
         name = substr( line, 52)
         if substr( line, 31, 1) = '>' then
            if isadefc( 'tree_dir') then
               'tree_dir "'name'\*.*"'
            else
               'dir' name
            endif
         else
            'e "'name'"'
         endif
      endif
      return
   endif

   -------------------------------------------------------------------------- Host: abbrev(LISTFILE) OUTPUT
   -- LAMPDQ support for LISTFILE output
compile if HOST_SUPPORT
   -- 5/11/88:  make Alt-1 work on lists of host files. */
   -- This works best with Larry Margolis's PDQ support (SLPDQ), and only
   -- when the name of the list file is "LIST OUTPUT", as is true when
   -- I'm using LaMail.  I have to have some way of knowing it's a list
   -- of host files.
;; if .filename ="LIST OUTPUT" then
   -- 10/21/88 (LAM): Make work for any abbreviation of LISTFILE, not just
   -- LIST, and ignore extra spaces on left and info on right [e.g., output
   -- from LISTFILE (ALLOC ].
   parse value .filename with file ext .
   if ext = 'OUTPUT' & file = substr( 'LISTFILE', 1, length( file)) then
      parse value line with fn ft fm .
      parse value .userstring with '[lt:'lt']'
      if lt = '' then
         lt = host_lt
      endif
      'e 'substr( hostdrive, 1, 1)''lt':'fn ft fm
      return
   endif
compile endif  -- HOST_SUPPORT

   -------------------------------------------------------------------------- LaMail .ndx
   -- LaMail index support
   if upcase( rightstr( .filename, 4)) = '.NDX' then
      parse value orig_line with 28 fn ft . 84 ext
      if pos(\1, ext) then
         'e' substr( .filename, 1, length( .filename) - 4)'\'fn'.'ft
         return
      endif
   endif

   -------------------------------------------------------------------------- include
   -- include support
   -- should work with any preprocesor, filetype, past  to future
   -- set 'ESEARCH' to search other directories
   CurMode = GetMode()
   parse value lowcase( line) with word1 word2 .
   if rightstr( word1, 7) = 'include' then  -- if first word ends in "include"
      delim = leftstr( word2, 1)
      fTryCurFirst = 1
      if pos( delim, "'" || '"') > 0 then   -- file has quote delimiters?
         parse value line with . (delim) filename (delim) .
      elseif delim = '<' then
         parse value line with . '<' filename '>' .
         if CurMode = 'C' then
            fTryCurFirst = 0
         endif
      else
         filename = word2   -- file has no delimiters, eg. MAK !include  file
      endif
      if CurMode = 'E' then
         path = 'EPMPATH'   -- for E macros
      elseif CurMode = 'MAKE' then
         path = 'PATH'      -- for make files
/*
; This TeX support is not very useful:
;   o  emTeX pathes may have "!" for recusive search appended.
;   o  VTeX has become the standard OS/2 TeX system in the meantime.
;   o  VTeX uses an ini, not env vars.
      elseif CurMode = 'TEX' then
         path = 'TEXINPUT'  -- for TEX files
*/
      else
         path = 'INCLUDE'   -- for C RC DLG MAK etc, all others PPWIZARD etc.
      endif
      call a1load( filename, path, fTryCurFirst)
      if rc = 0 then
         return
      endif
   endif

   -------------------------------------------------------------------------- *.use *.xrf
   -- C-USED support
   -- If the filetype is USE or XRF, do C-USED feature.
   ext = substr( upcase( .filename), lastpos( '.', upcase( .filename)) + 1)
   if ext = 'USE' or ext = 'XRF' then
      if substr( line, 1, 1) = ' ' then  -- child line
         parse value line with . infunc linenum file
         for i = .line - 1 to 1 by -1    -- search upward for parent line
            getline line, i
            if substr( line, 1, 1) <> ' ' then
               parse value line with func .
               leave
            endif
         endfor
         call a1load( file, AltOnePathVar, 1)
         top
         'L /'infunc; if rc then return; endif
         'L /'func;   if rc then return; endif
         sayerror 'Found 'func' in 'infunc' in 'file'.'
      else                               -- parent line
         parse value line with func linenum file
         if linenum = '#' then           -- might have a '#' in 2nd column
            parse value file with linenum file
         endif
         call a1load( file, AltOnePathVar, 1)
         top
         'L /'func; if rc then return; endif
         sayerror 'Found 'func' in 'file'.'
      endif
      return
   endif

   -------------------------------------------------------------------------- Host: procs*.index
   -- E3PROCS index support
   -- 11/10/88: Load Files Directly From The INDEX File.  By TJR
   --           Now loads files from the E3PROCS INDEX hostfile.  It is
   --           assumed that someday there will be an EOS2PROCS INDEX of
   --           the same format, therefore this macro was written to
   --           look for any H:*PROCS INDEX file.  A sincere attempt is
   --           made to open the file and move to the macro of interest.
compile if HOST_SUPPORT
   fn = .filename
   parse value .filename with filename filetyp fmode .  -- Not as crude, TJR
   if ('INDEX' = filetyp & 'PROCS' = rightstr( filename, 5)) then
      if vmfile( fn, ft) then
         parse value line with proc fn ft uid node date .
         if ('PROCS' <> ft) then                 -- Is the current line an entry?
            getline line, .line - 1              -- Go back one line and try again.
            parse value line with proc fn ft uid node date .
            if ('PROCS' <> ft) then              -- One more time. . . .
               sayerror'Sorry, cursor is not at a PROCS index entry!  No file loaded!'
               return
            endif
         endif                                   -- If we're here, must be an entry!
 compile if HOST_SUPPORT = 'EMUL' or HOST_SUPPORT = 'SRPI'
         if substr( .filename, 3, 1) = ':' then
            lt = substr( .filename, 2, 1)
         else
            lt = host_lt
         endif
         'e' hostdrive''lt':'fn ft fmode
 compile else
         'e' hostdrive''fn ft fmode
 compile endif
         top                                     -- Goto top of file.
         do forever
            getsearch oldsearch
            'xcom l ž'date'ž'                    -- Try to get the procedure.
            setsearch oldsearch
            if rc then
               sayerror proc' macro added by 'uid' on 'date' was not found!'
               top                               -- Go back to the top.
               beginline                         -- Move to beginning.
               return
            else
               getline line
               if (uid = substr( line, lastpos( 'by ', line) + 3,
                                 length(uid))) then
                  sayerror proc' macro added by 'uid' on 'date
                  beginline                      -- Move to beginning.
                  return
               else
                  '+1'
               endif
            endif
         enddo
      endif
   endif
   -- End of TJR's INDEX file modifications.
compile endif  -- HOST_SUPPORT

   --------------------------------------------------------------------------
   -- GREP support
   -- Determine grep version: Gnu or Ralph Yozzo's grep
   fGnuGrep = ''
   -- Support reloaded grep outputs: <path>.Output from grep ...
   lp = lastpos( '\', word( .filename, 1))
   if substr( .filename, lp + 1, 17) = '.Output from grep' then
      parse value textline(1) with 'SEARCH:'next
      if next > '' then
         fGnuGrep = 0
      else
         parse value textline(1) with 'Current directory = 'next
         if next > '' then
            fGnuGrep = 1
         else
            fGnuGrep = GetGrepVersion( 'INIT')
         endif
      endif
   endif

   -------------------------------------------------------------------------- .Output from grep (Gnu)
   -- Handle Gnu GREP output like  full_specified_filename:lineno:text
   if fGnuGrep = 1 then
      -- New: get current dir from line 1 to handle relative pathes.
      parse value textline(1) with 'Current directory = 'CurDir

      if substr( line, 1, 2) = '\\' | substr( line, 2, 2) = ':\' then  -- full qualified
         parse value substr( line, 3) with next':'LineNumber':'rest
         FileName = substr( line, 1, 2 + length(next))
         FileName = translate( FileName, '\', '/')
      else
         parse value line with FileMask':'LineNumber':'rest
         if LineNumber then
            FileMask = translate( FileMask, '\', '/')
            FileName = GetFullName( FileMask, CurDir)
         else
            FileName = ''
         endif
      endif

      if FileName then
         if rest & isnum( LineNumber) then
            'e "'FileName'"' "'"LineNumber"'"
         else
            'e "'FileName'"'
         endif
         return
      endif
   endif

   -------------------------------------------------------------------------- .Output from grep (RY)
   -- 11/03/88: Open file specified by GREP and move to current line!  TJR
   -- Use the name ".grep" as the signature, so I can load multiple grep lists.
   -- See GREP.E.  jbl.
   if substr( .filename, 1, 5) = ".grep" |                            -- TJR's GREP
      fGnuGrep = 0 then                                               -- LAM's GREP
      getsearch oldsearch
      call psave_pos(save_pos)
      'xcom l .   File #. -'          -- Find previous file
         setsearch oldsearch
      if rc then
         sayerror 'No files found!'
         return
      else
         getline newline
         call prestore_pos(save_pos)
         parse value newline with "==> " filename " <=="
         call a1load( filename, AltOnePathVar, 1)
;;compile if 1                                                -- LAM:  I use /L
;  Now supports both; if line starts with a number, assume /L; if not, do search.
         parse value orig_line with num ')'
         if pos('(', num) & not pos(' ', num) then
            parse value num with . '(' num
         endif
         parse value num with num ':' col
         if isnum(num) then
            y = num
            x = 1
            .cursory = .windowheight%2
            if isnum(col) then x = col; endif
            'postme goto' y x
            return
         endif
;;compile else                                                -- TJR doesn't
         parse value orig_line with "==>" tempstr
         if tempstr = ''  then
            -- Let it be hilighted by the built-in stuff...
            'postme l '\158''orig_line\158'eaf+'          /* ALT-158 is the search delim */
            if rc then
               sayerror substr( line, 1, 60)'. . . Not Found!'
            endif
         endif
         return
;;compile endif
      endif
   endif
   -- End of TJRs 11/03/88 Modifications!

   ---------------------------------------------------------------------------- .Output from gsee
   if substr(.filename,1,17)=".Output from gsee" then            -- LAM's GSEE
      parse value line with name '.' ext 13 52 path
      if substr(line,9,1)='.' & substr(line,53,1)=':' then
         if length(path) > 3 then path = path'\'; endif
         call a1load(path || strip(name)'.'ext,AltOnePathVar,0)
         return
      endif
   endif

   -------------------------------------------------------------------------- icc
   -- jbl 11/15/88:  The C compiler error line can have a line number in
   -- parentheses, like "/epm/i/iproto.h(196)".  Get the number.

   linenum = ''; col = ''

   p = pos( '(', line)
   if p > 0 then
      parse value line with next '(' num ')' .
      if verify( num, '0123456789:') = 0 then  -- if number or colon
         p2 = pos( strip( strip(next), 'b', \9), line)
         if p2 > 0 then
            .col = p2
         endif
         line    = next
         linenum = num
         parse value linenum with linenum ':' col  -- LAM: CSet/2 includes column
      endif
   endif

   -------------------------------------------------------------------------- word under cursor
   -- todo: support spaces in filenames and pathes

   CurMode = GetMode()
   StartCol = 0
   EndCol   = 0
   SeparatorList = '"'||"'"||'(){}[]<>,;|+ '\9'#='
-- call find_token( StartCol, EndCol, SeparatorList, '')
-- fWordFound = (StartCol <> 0 & EndCol >= StartCol)
-- Checking the return code is better in the case the cursor is
-- on a 'diad'.  JBS
   rcx = find_token( StartCol, EndCol, SeparatorList, '')
   fWordFound = (rcx == 1)
   if fWordFound then  -- if word found
      Spec = substr( line, StartCol, EndCol - StartCol + 1)
      -- strip trailing periods
      -- This has been moved ahead of where it was in order to handle
      -- the case where the 'token' is all '.'s and is therefore
      -- stripped to nothing in this code.  JBS
      Spec = strip( Spec, 'T', '.')
      if Spec == "" then              -- was token all '.'s?
         fWordFound = 0               -- if yes, abort "normal" search
      endif
   endif
   if fWordFound then  -- if word still exists after truncating trailing '.'s
                       -- todo: handle URLs here, start browser
      -- convert slashes to backslashes
      Spec = translate( Spec, '\', '/')

      -- parse at trailing ':' and maybe appended linenum
--> Todo: interpret ':' always as separator, unless it is followed by a '\' (done!)
-->       and use the part under the cursor (todo!)
      startp = 1
      do forever
         p1 = pos( ':', Spec, startp)
         if p1 = 0 then
            leave
         elseif substr( Spec, p1, 2) = ':\' then
            startp = p1 + 1
            iterate
         else
            parse value substr( Spec, p1) with ':' next ':'
            if next = '' then
               parse value substr( Spec, p1) with ':' next
            endif
            if isnum( next) then
               linenum = next
            endif
            Spec = substr( Spec, 1, p1 - 1)
            leave
         endif
      enddo

      SpecExt = ''
      lp = lastpos( '.', Spec)
--    if lp > 1 & lp < length(Spec) then
--                lp < length(Spec) this could never be false after trailing '.'s have been stripped JBS
      if lp > 1 then
         SpecExt = substr( Spec, lp + 1)
         SpecExt = upcase(SpecExt)
      endif

      PathVar = 'PATH'
      if CurMode = 'E' | wordpos( SpecExt, 'E') > 0 then
         PathVar = 'EPMPATH'
      elseif CurMode = 'TEX' | wordpos( SpecExt, 'TEX') > 0 then
         PathVar = 'TEXINPUT'
      endif

      fTryCurFirst = 1  -- 1 ==> search in current dir first
      call a1load( Spec, PathVar, fTryCurFirst)
   endif
/**
   if fWordFound = 0 or rc <> 0 then
      -- Try special case of an include/tryinclude line in an E or C/C++ file JBS
      if CurMode = 'E' or CurMode = 'C' or CurMode = 'RC' then
         fTryCurFirst = 1                       -- true for E and C/C++ #include "..."
         getline includeline
         parse value lowcase(includeline) with word1 word2.
         delim = substr( word2, 1, 1)
         if CurMode = 'E' and (word1 = 'include' or word1 = 'tryinclude') and
            (delim = "'" or delim = '"') then
            Spec = strip(word2, 'B', delim)
            fWordFound = 1
            call a1load(Spec, 'EPMPATH', fTryCurFirst)    -- For E files
         else
            if (CurMode = 'C' or CurMode = 'RC') and word1 = '#include' and
               (delim = '"' or delim = "'" or delim = '<') then
               Spec = strip(word2, 'B', delim)
               fWordFound = 1
               if delim = '<' then
                  parse value word2 with '<'Spec'>'
                  fTryCurFirst = 0                 -- reset on C/C++ #include <...>
               endif
               call a1load(Spec, 'INCLUDE', fTryCurFirst)    -- For C/C++ file
            endif
         endif
      endif
   endif
**/
   if fWordFound = 0 then
      sayerror 'No filename under cursor'
   elseif rc <> 0 then
      -- Todo: give a better msg using a standard OS/2 rc.
      sayerror 'File "'Spec'" cannot be found or loaded.'
      -- Todo: search in tree and remove maybe relative path
      -- from Spec or concatenate every path of the tree with
      -- Spec (should be resolved by NepmdQueryFullname).
   else
      if linenum > '' & col > '' then
         'postme goto' linenum col
      elseif linenum > '' then
         'postme goto' linenum
      endif
   endif

; ---------------------------------------------------------------------------
; Sets rc > 0 for a standard error code, rc < 0 for an ETK error code, set
; by defc edit, or rc = 0 on success.
; FileName can be a name, including wildcards.
; PathVar must be a name for a path, e.g. 'PATH'.
; fTryCurFirst as optional 3rd arg specifies, if current directory shall be
;    searched first (fTryCurFirst = 1). Default is to omit the search in
;    current dir.
defproc a1load( FileName, PathVar)
   fTryCurFirst = (arg(3) = 1)
   WildcardPos = verify( FileName, '*?', 'M')

   if WildcardPos then
      if YES_CHAR <> askyesno( WILDCARD_WARNING__MSG, '', filename) then
         return
      endif
      'edit "'FileName'"'

   else
      -- Every check for existing names returns always 0 for wildcards in name.
      -- Currently NepmdFileExists, NepmdDirExists and Exist suppress a following
      -- sayerror going to the MsgLine, but it's written to the MsgBox. Any
      -- execution of display won't help. With NepmdPmPrintf it can be prooved,
      -- that the correct values 0 or 1 are returned. This can be workarounded
      -- by assigning the returned 0 or 1 to any (maybe dummy) var first. After
      -- that, the 0 or 1 can be used for sayerror output.
      LoadName = ''
      do i = 1 to 1
         if fTryCurFirst then
            if NepmdFileExists( FileName) then
               LoadName = FileName
               leave
            endif
         endif

         next = FindFileInList( FileName, Get_Env( PathVar))
         if next > '' then
            LoadName = next
            leave
         endif

         if not fTryCurFirst then
            if NepmdFileExists( FileName) then
               LoadName = FileName
               leave
            endif
         endif
      enddo

      rc = -2
      if LoadName > '' then
         -- LoadName must exist
         FullName = NepmdQueryFullname( LoadName)
         parse value FullName with 'ERROR:'rc
         if rc = '' then
            'edit "'FullName'"'
         endif
      endif
   endif

; ---------------------------------------------------------------------------
defproc Alt1ParseDirParams( Params, var Flags, var Mask)
   -- parse DIRCMD into Flags
   DirCmd = Get_Env( 'DIRCMD')
   temp = DirCmd
   do while temp <> ''
      parse value temp with arg1 temp
      if leftstr( arg1, 1) = '/' then
         ch = substr( arg1, 2, 1)
         if ch = '-' then
            flagpos = pos( substr( arg1, 3, 1), Flags)
            if flagpos then
               Flags = delstr( Flags, flagpos, 1)
            endif
         else
            if pos( ch, flags) = 0 then
               Flags = Flags''ch
            endif
         endif
      endif
   enddo
   -- parse Params into Mask and Flags
   temp = Params
   do while temp <> ''
      -- parse leading options
      parse value temp with arg1 temp
      if leftstr( arg1, 1) = '/' then
         ch = upcase( substr( arg1, 2, 1))
         if ch = '-' then
            flagpos = pos( substr( arg1, 3, 1), Flags)
            if flagpos then
               Flags = delstr( Flags, flagpos, 1)
            endif
         else
            if pos( ch, Flags) = 0 then
               Flags = Flags''ch
            endif
         endif
      else
         temp = arg1 temp
         -- parse trailing options
         parse value temp with Mask '/'temp
         Mask = strip( Mask)
         if temp <> '' then
            temp = '/'temp
         endif
      endif
   enddo
   return

; ---------------------------------------------------------------------------
defproc Alt1VerifyTime
   TimeWord = arg(1)
   DateTimeChars = arg(2)
   BadTimeCharPos = verify( TimeWord, DateTimeChars)
   return (BadTimeCharPos = 0) | (BadTimeCharPos = length( TimeWord) &
                                  (verify( rightstr( TimeWord, 1), 'ap')) = 0)

