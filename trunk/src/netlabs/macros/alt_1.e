/****************************** Module Header *******************************
*
* Module Name: alt_1.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: alt_1.e,v 1.3 2004-02-22 18:58:05 aschn Exp $
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
-  compile if ...
-  replace (not redefine) the standard a_1
-  use find_token
      StartCol = 0
      EndCol   = 0
      SeparatorList = '''"(){}[]<>,;! '\9;
      call find_token( StartCol, EndCol, SeparatorList, '')
-  check filename for grep
*/

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
-------------------------------------------------------------------------------

const                             -- These are Alt-1.e -specific constants.
  compile if not defined(AltOnePathVar)
   AltOnePathVar= 'ESEARCH'    -- the name of the environment variable
  compile endif
  compile if not defined(C_INCLUDE)
   C_INCLUDE    = 1            -- 1 means search <filename> along INCLUDE path
  compile endif

define
   QUOTED_DIR_STRING ='"'DIRECTORYOF_STRING'"'


def a_1=
   universal host_LT                    -- Used with LAMPDQ.E
compile if HOST_SUPPORT='EMUL' or HOST_SUPPORT='SRPI'
   universal hostdrive
compile endif
   /* edit filename on current text line */
   getline line
   orig_line = line

; ----------------------------------------------------------------------------- shell
   if leftstr(.filename, 15) = ".command_shell_" then

      if substr(line, 13, 1) = ' ' then  -- old (i.e. FAT) format DIR, or not a DIR line
         if substr(line, 27, 1) = ' ' then  -- /V in effect
            flag = substr(line, 1, 1) <> ' ' &
               (isnum(translate(substr(line, 14, 13), '0', ',')) | substr(line, 14, 13)='<DIR>') &
               length(line) < 40 &
               isnum(substr(line, 28, 2) || substr(line, 31, 2) || substr(line, 34, 2)) &
               substr(line, 30, 1) = substr(line, 33, 1) &
               pos(substr(line, 30, 1), '/x.-')
         else
            flag = substr(line, 1, 1) <> ' ' &
               (isnum(substr(line, 14, 8)) | substr(line, 14, 8)='<DIR>') &
               length(line) < 40 &
               isnum(substr(line, 24, 2) || substr(line, 27, 2) || substr(line, 30, 2)) &
               substr(line, 26, 1) = substr(line, 29, 1) &
               pos(substr(line, 26, 1), '/x.-')
         endif
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif

      else                                      -- new (i.e. HPFS or JFS) format DIR, or not a DIR line
         if substr(line, 16, 1) = ' ' then      -- /V in effect
            flag = substr(line, 44, 1) <> ' ' &
               (isnum(translate(substr(line, 17, 13), '0', ',')) | substr(line, 17, 13)='<DIR>') &
               isnum(substr(line, 1, 2) || substr(line, 4, 2) || substr(line, 7, 2)) &
               substr(line, 3, 1) = substr(line, 6, 1) &
               pos(substr(line, 3, 1), '/x.-')
            filename=substr(line,44)
         else
            flag = substr(line, 41, 1) <> ' ' &
                (isnum(substr(line, 18, 9)) | substr(line, 18, 9)='<DIR>') &
                isnum(substr(line, 1, 2) || substr(line, 4, 2) || substr(line, 7, 2)) &
                substr(line, 3, 1) = substr(line, 6, 1) &
                pos(substr(line, 3, 1), '/x.-')
            filename=substr(line,41)
         endif
      endif

      if flag then
         call psave_pos(save_pos)
         getsearch oldsearch
         display -2
         'xcom l /'DIRECTORYOF_STRING'/c-'
         dir_rc = rc
         if not rc then
            getline word3
            parse value word3 with $QUOTED_DIR_STRING word3 .
;;          parse value word3 with . . word3 .
            if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
               word3 = strip(substr(word3, 1, lastpos(word3, '\')-1))
            endif
         endif
         display 2
         setsearch oldsearch
         call prestore_pos(save_pos)
         if not dir_rc then
            name=word3 ||                            -- Start with the path.
                 leftstr('\',                        -- Append a '\', but only if path
                         '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
                 filename                            -- Finally, the filename
;           if pos(' ',name) then  -- enquote
            if verify(name, ' =', 'M') then  -- enquote
               name = '"'name'"'
            endif
            if pos('<DIR>',line) then
               'dir 'name
            else
               'e 'name
            endif
            return
         endif
      endif

   endif  -- leftstr(.filename, 15) = ".command_shell_"

; ----------------------------------------------------------------------------- .DOS DIR
   -- jbl 2/14/89:  we now distribute a standard front end for the DIR
   -- command, which redirects the output to a file named ".dos dir <dirname>".
   -- lam 3/15/89:  added code to handle trailing blanks and wildcards.
   -- Previously, after a 'DIR \path\*.E ', would do:  E \path\*.E \fname.ext
   parse value .filename with word1 word2 word3 .
   if upcase(word1 word2) = '.DOS DIR' then
      call psave_pos(save_pos)
      getsearch oldsearch
      'xcom l /'DIRECTORYOF_STRING'/c-'
      if not rc then
         getline word3
         parse value word3 with . . word3 .
         if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
            word3 = strip(substr(word3, 1, lastpos(word3, '\')-1))
         endif
      endif
      setsearch oldsearch
      call prestore_pos(save_pos)
      filename=substr(line,41)                 -- Support HPFS.  FAT dir's end at 40
      if filename='' then                      -- Must be FAT.
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif
      endif
      name=word3 ||                            -- Start with the path.
           leftstr('\',                        -- Append a '\', but only if path
                   '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
           filename                            -- Finally, the filename
;     if pos(' ',name) then  -- enquote
      if verify(name, ' =', 'M') then  -- enquote
         name = '"'name'"'
      endif
      if pos('<DIR>',line) then
         'dir 'name
      else
;        call a1load(name,AltOnePathVar,0)
         'e' name
      endif
      return
   endif

; ----------------------------------------------------------------------------- .tree
   if .filename = '.tree' then
      if substr(line,5,1)substr(line,8,1)substr(line,15,1)substr(line,18,1) = '--::' then
         name = substr(line, 52)
         if substr(line,31,1)='>' then
            if isadefc('tree_dir') then
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

; ----------------------------------------------------------------------------- Host: abbrev(LISTFILE) OUTPUT
/******************************************************************************/
/***       LAMPDQ support for LISTFILE output                               ***/
/******************************************************************************/
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
   if ext='OUTPUT' & file=substr('LISTFILE',1,length(file)) then
      parse value line with fn ft fm .
      parse value .userstring with '[lt:'lt']'
      if lt='' then lt=host_lt; endif
      'e 'substr(hostdrive,1,1) || lt':'fn ft fm
      return
   endif
compile endif  -- HOST_SUPPORT

; ----------------------------------------------------------------------------- LaMail .ndx
/******************************************************************************/
/***       LaMail index support                                             ***/
/******************************************************************************/
   if upcase(rightstr(.filename, 4))='.NDX' then
      parse value orig_line with 28 fn ft . 84 ext
      if pos(\1, ext) then
         'e' substr(.filename, 1, length(.filename)-4)'\'fn'.'ft
         return
      endif
   endif

; ----------------------------------------------------------------------------- *.use *.xrf
/******************************************************************************/
/***       C-USED support                                                   ***/
/******************************************************************************/

   -- If the filetype is USE or XRF, do C-USED feature.
   ext=substr(upcase(.filename),lastpos('.',upcase(.filename))+1)
   if ext='USE' or ext='XRF' then
      if substr(line,1,1)=' ' then  -- child line
         parse value line with . infunc linenum file
         for i = .line-1 to 1 by -1   -- search upward for parent line
            getline line,i
            if substr(line,1,1) <> ' ' then
               parse value line with func .
               leave
            endif
         endfor
         call a1load(file,AltOnePathVar,1)
         top
         'L /'infunc; if rc then return; endif
         'L /'func;   if rc then return; endif
         sayerror 'Found 'func' in 'infunc' in 'file'.'
      else                          -- parent line
         parse value line with func linenum file
         if linenum='#' then        -- might have a '#' in 2nd column
            parse value file with linenum file
         endif
         call a1load(file,AltOnePathVar,1)
         top
         'L /'func; if rc then return; endif
         sayerror 'Found 'func' in 'file'.'
      endif
      return
   endif    -- C-USED feature

; ----------------------------------------------------------------------------- Host: procs*.index
/******************************************************************************/
/***       E3PROCS index support                                            ***/
/******************************************************************************/

   -- 11/10/88: Load Files Directly From The INDEX File.  By TJR
   --           Now loads files from the E3PROCS INDEX hostfile.  It is
   --           assumed that someday there will be an EOS2PROCS INDEX of
   --           the same format, therefore this macro was written to
   --           look for any H:*PROCS INDEX file.  A sincere attempt is
   --           made to open the file and move to the macro of interest.
compile if HOST_SUPPORT
   fn = .filename
   parse value .filename with filename filetyp fmode .  -- Not as crude, TJR
   if ('INDEX'=filetyp & 'PROCS'=rightstr(filename, 5) &
        vmfile(fn,ft)) then
      parse value line with proc fn ft uid node date .
      if ('PROCS'<>ft) then                   -- Is the current line an entry?
         getline line, .line-1                -- Go back one line and try again.
         parse value line with proc fn ft uid node date .
         if ('PROCS'<>ft) then                -- One more time. . . .
            sayerror'Sorry, cursor is not at a PROCS index entry!  No file loaded!'
            return
         endif
      endif                                   -- If we're here, must be an entry!
 compile if HOST_SUPPORT='EMUL' or HOST_SUPPORT='SRPI'
      if substr(.filename, 3, 1)=':' then
         lt = substr(.filename, 2, 1)
      else
         lt = host_lt
      endif
      'e' hostdrive || lt':'fn ft fmode
 compile else
      'e' HOSTDRIVE || fn ft fmode
 compile endif
      top                                     -- Goto top of file.
      do forever
         getsearch oldsearch
         'xcom l ž'date'ž'                    -- Try to get the procedure.
         setsearch oldsearch
         if rc then
            sayerror proc' macro added by 'uid' on 'date' was not found!'
            TOP                               -- Go back to the top.
            BEGINLINE                         -- Move to beginning.
            return
         else
            getline line
            if (uid = substr(line, lastpos('by ', line)+3, length(uid))) then
               sayerror proc' macro added by 'uid' on 'date
               BEGINLINE                      -- Move to beginning.
               return
            else
               '+1'
            endif
         endif
      enddo
   endif
   -- End of TJR's INDEX file modifications.
compile endif  -- HOST_SUPPORT

; ----------------------------------------------------------------------------- .Output from GNU grep
/******************************************************************************/
/***       GREP support                                                     ***/
/******************************************************************************/

/*
   -- 8/10/88:  Handle GREP output like "File #0==> CKEYSEL.E <==".
   parse value line with "==>" filename "<=="
   if filename then
      call a1load(filename,AltOnePathVar,1)
      return
   endif
*/
   -- Handle Gnu GREP output like  full_specified_filename:lineno:text
   if substr( .filename, 1, 17) = '.Output from grep' then            -- GNU grep
      FileName = ''
      parse value line with DriveLetter':'Rest
      if length(DriveLetter) = 1 then
         parse value Rest with FileName':'LineNumber':'Rest
         FileName = DriveLetter':'FileName
      endif
      if FileName then
         "e "FileName" '"LineNumber"'"
         return
      endif
   endif

; The rest is not used anymore:
/*
   -- 11/03/88: Open file specified by GREP and move to current line!  TJR
   -- Use the name ".grep" as the signature, so I can load multiple grep lists.
   -- See GREP.E.  jbl.
   if substr(.filename,1,5)=".grep" |                            -- TJR's GREP
      substr(.filename,1,17)=".Output from grep" then            -- LAM's GREP
         getsearch oldsearch
       call psave_pos(save_pos)
       'xcom l .   File #. -'          /* Find previous file           */
         setsearch oldsearch
       if rc then
          sayerror 'No files found!'
          return
       else
          getline newline
          call prestore_pos(save_pos)
          parse value newline with "==> " filename " <=="
          call a1load(filename,AltOnePathVar,1)
;;compile if 1                                                -- LAM:  I use /L
;  Now supports both; if line starts with a number, assume /L; if not, do search.
          parse value orig_line with num ')'
          if pos('(', num) & not pos(' ', num) then
             parse value num with . '(' num
          endif
          parse value num with num ':' col
          if isnum(num) then
             .cursory=.windowheight%2
             num
             if isnum(col) then .col = col; endif
             return
          endif
;;compile else                                                -- TJR doesn't
          parse value orig_line with "==>" tempstr
          if  tempstr = ''  then
             'l ž'orig_line'žeaf+'          /* ALT-158 is the search delim */
             if rc then
                 sayerror substr(line, 1, 60)'. . . Not Found!'
             endif
          endif
          return
;;compile endif
       endif
   endif
   -- End of TJRs 11/03/88 Modifications!
*/

; ----------------------------------------------------------------------------- .Output from gsee
   if substr(.filename,1,17)=".Output from gsee" then            -- LAM's GSEE
      parse value line with name '.' ext 13 52 path
      if substr(line,9,1)='.' & substr(line,53,1)=':' then
         if length(path) > 3 then path = path'\'; endif
         call a1load(path || strip(name)'.'ext,AltOnePathVar,0)
         return
      endif
   endif

; ----------------------------------------------------------------------------- icc
   -- jbl 11/15/88:  The C compiler error line can have a line number in
   -- parentheses, like "/epm/i/iproto.h(196)".  Get the number.

   linenum = ''; col = ''

   p = pos( '(', line)
   if p > 0 then
      parse value line with next '(' num ')' .
      if verify( num, '0123456789:') = 0 then  -- if number or colon
         line    = next
         linenum = num
         parse value linenum with linenum ':' col  -- LAM: CSet/2 includes column
      endif
   endif

; ----------------------------------------------------------------------------- word under cursor
   StartCol = 0
   EndCol   = 0
                                                         -- todo: support spaces in filenames and pathes
   SeparatorList = '"'||"'"||'(){}[]<>,;|+ '\9'#'
   call find_token( StartCol, EndCol, SeparatorList, '')

   WordFound = (StartCol <> 0 & EndCol >= StartCol)
   if WordFound then  -- if word found
      Spec = substr( line, StartCol, EndCol - StartCol + 1)
                                                         -- todo: handle URLs here, start browser
      -- convert slashes to backslashes
      Spec = translate( Spec, '\', '/')
      -- strip trailing periods
      Spec = strip( Spec, 'T', '.')

      CurMode = NepmdGetMode()

      SpecExt = ''
      lp = lastpos( '.', Spec)
      if lp > 1 & lp < length(Spec) then
         SpecExt = substr( Spec, lp + 1)
         SpecExt = upcase(SpecExt)
      endif

      PathVar = 'PATH'
      if CurMode = 'E' | wordpos( SpecExt, 'E') > 0 then
         PathVar = 'EPMPATH'
      elseif CurMode = 'TEX' | wordpos( SpecExt, 'TEX') > 0 then
         PathVar = 'TEXINPUT'
      endif

      TryCurFirst = 1  -- 1 ==> search in current dir first

      call a1load( Spec, PathVar, TryCurFirst)

compile if C_INCLUDE
      -- If that fails, try INCLUDE path.
      if rc = sayerror('New file') or rc = sayerror('Path not found') then
         'q'
         PathVar = 'INCLUDE'
         TryCurFirst = 0
         call a1load( word2, SearchVar, TryCurFirst)
      endif
compile endif

      if rc = sayerror('New file') or rc = sayerror('Path not found') then
         --'q'
      else
         linenum  -- jbl 11/15/88, go to specified linenum if any.
         if col <> '' then
            .col = col
         endif
      endif
   endif


defproc a1load( filename, PathVar, TryCurFirst)
   if pos( '*', filename) then
      if YES_CHAR <> askyesno( WILDCARD_WARNING__MSG, '', filename) then
         return
      endif
   endif
   if TryCurFirst then
      if exist(filename) then
         'e' filename
         return
      endif
   endif
   'e' search_path( Get_Env(PathVar), filename)filename

