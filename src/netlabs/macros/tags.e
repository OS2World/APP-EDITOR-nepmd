/****************************** Module Header *******************************
*
* Module Name: tags.e
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

; def s_f6 'FindTag'     -- Find procedure under cursor via tags file
; def s_f7 'FindTag *'   -- Open entrybox to enter a procedure to find via tags file
; def s_f8 'TagsFile'    -- Open entrybox to select a tags file
; def s_f9 'MakeTags *'  -- Open entrybox to enter list of files to scan for to create a tags file
; 'TagScan'    is executed by menuitem 'Scan current file...'
; 'maketags =' is executed by the Tags dialog, when the Refresh button is pressed.

; This module is a general purpose engine for providing searching and
; completion for tagged function names.
;
; To add support for another language, update tag_case() if it's a case-sensitive
; language, update tags_supported to indicate what file modes are supported
; and update proc_search to call the procedure search routine for that language.
;           tag_case()        Returns 'e' for case sensitive languages and
;                            'c' for case insensitive languages.
;
;     xxxxx_proc_search( var ProcName, fFindFirst)
;                             if ProcName is null, this function searches
;                             for a valid procedure in the current buffer. If
;                             successful, ProcName is set to the procedure
;                             name and 0 is returned.  The fFindFirst parameter
;                             when non-zero indicates that the first search
;                             is being performed.
;
;                             if ProcName is NOT null, this function searches
;                             for the definition of the procedure ProcName in
;                             the current buffer.  If successful, cursor is
;                             placed on procedure definition and 0 is returned.
;                             See one of the procedures C_PROC_SEARCH,
;                             PAS_PROC_SEARCH, or ASM_PROC_SEARCH for an
;                             example.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'TAGS.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

include 'stdconst.e'

const
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
compile endif

define
compile if not defined(CPP_EXTENSIONS)  -- Keep in sync with CKEYS.E
   CPP_EXTENSIONS = 'CC CPP HPP CXX HXX SQX'
compile endif

const
compile if not defined(TAGS_ANYWHERE)
   TAGS_ANYWHERE = 1          -- Set to 0 if all your procedure definitions start in col. 1
compile endif
compile if not defined(C_TAGS_ANYWHERE)
   C_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(E_TAGS_ANYWHERE)
   E_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(ASM_TAGS_ANYWHERE)
   ASM_TAGS_ANYWHERE = TAGS_ANYWHERE
compile endif
compile if not defined(KEEP_TAGS_FILE_LOADED)
   KEEP_TAGS_FILE_LOADED = 1  -- If you do a lot with tags, you might want to keep the file loaded.
compile endif
   IDENTIFIER_STARTER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_$'

/****  The following needs to be modified for adding other languages. *****/
/****  Additionally, defproc <mode>_proc_search has to be added.      *****/
; ---------------------------------------------------------------------------
defproc tag_case( filename)
   universal nepmd_hini

   Mode = GetMode()
   KeyPath = '\NEPMD\User\Mode\'Mode'\CaseSensitive'
   on = (NepmdQueryConfigValue( nepmd_hini, KeyPath) = 1)
   if on then
      searchopt = 'e'  -- case-sensitive
   else
      searchopt = 'c'  -- case-insensitive
   endif
   return searchopt

; ---------------------------------------------------------------------------
defproc tags_supported( Mode)
   return wordpos( Mode, 'C JAVA E ASM REXX PASCAL MODULA REXX CMD HTEXT IPF TEX JAVASCRIPT')

; ---------------------------------------------------------------------------
defproc proc_search( var ProcName, fFindFirst, Mode, Ext)
   if Mode = 'C' then
      ret = c_proc_search( ProcName, fFindFirst, Ext)
   elseif Mode = 'JAVA' then
      ret = c_proc_search( ProcName, fFindFirst, Ext)
   elseif Mode = 'ASM' then
      ret = asm_proc_search( ProcName, fFindFirst)
   elseif Mode = 'PASCAL' then
      ret = pas_proc_search( ProcName, fFindFirst)
   elseif Mode = 'MODULA' then
      ret = pas_proc_search( ProcName, fFindFirst, 'e')
   elseif Mode = 'E' then
      ret = e_proc_search( ProcName, fFindFirst)
   elseif Mode = 'REXX' then
      ret = rexx_proc_search( ProcName, fFindFirst)
   elseif Mode = 'CMD' then
      ret = cmd_proc_search( ProcName, fFindFirst)
   elseif Mode = 'HTEXT' then
      ret = htext_proc_search( ProcName, fFindFirst)
   elseif Mode = 'IPF' then
      ret = ipf_proc_search( ProcName, fFindFirst)
   elseif Mode = 'TEX' then
      ret = tex_proc_search( ProcName, fFindFirst)
   elseif Mode = 'JAVASCRIPT' then
      ret = javascript_proc_search( ProcName, fFindFirst)
   else
      ret = 1
   endif
   if ret = 0 then
      dprintf( 'TAG', 'Found ProcName = "'ProcName'" in line' .line '= "'textline(.line)'"')
   endif
   rc = ret
   return rc

; ---------------------------------------------------------------------------
/****   The above needs to be modified for adding other languages. *****/

; ---------------------------------------------------------------------------
; Searches for { in column 1.
; Checks if char before is ).
; Goes to matching (.
; Takes identifier before as proc.
; Recognizes comments, but handling of multi-line comments is still not
; perfect. inside_comment for mode C would be too slow for large files.
defproc c_proc_search( var ProcName, fFindFirst, Ext)
   universal OpenBracePos

   if wordpos( Ext, CPP_EXTENSIONS) then  -- Presumably C++,
      colon = ':'                         -- allow colons.
      cpp_decl = '&'                      -- Can have a reference in a declarator
   else                       -- Plain old C, colons are illegal in procedure names.
      colon = ''
      cpp_decl = ''
   endif

   -- Define this as var to keep the E parser happy
   OpenCom  = '/'||'*'
   CloseCom = '*'||'/'

   fFindProcName = (ProcName <> '')
   ProcLen = length( ProcName)
   display -2

   if fFindFirst then
      OpenBracePos = ''
   endif
   do forever

      if fFindProcName then

         'xcom l 'ProcName':ox'
         if rc then
            leave
         endif

         getline line
         line = translate( line, ' ', \t)

         -- Determine if match is a substring of something else
         if .col > 1 then
            if pos( upcase( substr( line, .col - 1, 1)), IDENTIFIER_STARTER'0123456789') then
               end_line
               iterate
            endif
         endif
         .col = .col + ProcLen
         if pos( upcase( substr( line, .col, 1)), IDENTIFIER_STARTER'0123456789') then
            end_line
            iterate
         endif
         dprintf( 'TAG', 'Found line' .line '= "'line'"')

      else

         if OpenBracePos <> '' then
            parse value OpenBracePos with OpenBraceLine OpenBraceCol
            .lineg = OpenBraceLine
            .col   = OpenBraceCol + 1
            -- Find } in col 1 to position cursor for next search
            'xcom l ^}g'
            -- Ignore rc from here
         endif

         -- Find { in col 1
         'xcom l ^{g'
         if rc then
            leave
         endif
         -- Avoid endless loop
         if .line .col = OpenBracePos then
            rc = 1
            leave
         endif
         OpenBracePos  = .line .col
         --dprintf( 'OpenBrace: line =' .line', col = '.col': 'textline( .line))

         -- Check if in comment
         -- Search opening comment backward, start at OpenBracePos
         OpenComLine = 0
         OpenComCol  = 0
         'xcom l 'OpenCom'r-'
         if not rc then
            -- Check for multi-line comment as string
            if IsString( leftstr( textline( .line), .col - 1), '"') then
               --dprintf( 'OpenCom  : line =' .line', col = '.col': 'textline( .line))
               repeat_find
               --dprintf( 'OpenCom  : This is a string')
            else
               OpenComLine = .line
               OpenComCol  = .col
            endif
         endif
         parse value OpenBracePos with OpenBraceLine OpenBraceCol
         .lineg = OpenBraceLine
         .col   = OpenBraceCol

         -- Search closing comment backward, start at OpenBracePos
         CloseComLine = 0
         CloseComCol  = 0
         'xcom l 'CloseCom'-r'
         if not rc then
            -- Check for multi-line comment as string
            if IsString( leftstr( textline( .line), .col - 1), '"') then
               --dprintf( 'CloseCom : line =' .line', col = '.col': 'textline( .line))
               repeat_find
               --dprintf( 'CloseCom : This is a string')
            else
               CloseComLine = .line
               CloseComCol  = .col
            endif
         endif
         parse value OpenBracePos with OpenBraceLine OpenBraceCol
         .lineg = OpenBraceLine
         .col   = OpenBraceCol

         fInComment = 0
         if OpenComLine = 0 and CloseComLine = 0 then
            --dprintf( 'OpenBrace: No comment chars found, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         elseif OpenComLine = 0 then
            -- Comment may be closed after { char in col 1
            fInComment = 1
            --dprintf( 'OpenBrace: This is an unbalanced open comment, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         elseif CloseComLine = 0 then
            --dprintf( 'OpenBrace: This is an unbalanced close comment, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         elseif CloseComLine > OpenComLine then
            -- Comment closed before { char in col 1
            --dprintf( 'OpenBrace: This is no comment, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         elseif CloseComLine < OpenComLine then
            -- Comment opened before { char in col 1
            fInComment = 1
            --dprintf( 'OpenBrace: This is a comment, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         else
            -- Same line: can't enclose the { char in col 1
            --dprintf( 'OpenBrace: This is no comment, OpenComLine = 'OpenComLine', CloseComLine = 'CloseComLine)
         endif
         if fInComment then
            -- Ignore this, find next opning brace
            iterate
         endif

         -- Find ) before
         ch1 = ''
         ch2 = ''
         do forever
            -- Go to end of previous line
            if .line = 1 then
               leave
            endif
            up
            end_line
            ThisLine = textline( .line)

            -- Go to single-line comment, if not within a multi-line comment
            p1 = pos( '//', ThisLine)
            pc = pos( CloseCom, ThisLine)
            -- This is not really correct, but quick and dirty
            -- Both comment types in a line occur not often, so it works in many cases
            if p1 > 0 and pc < p1 then
               .col = p1
            endif

            -- Get non-blank and non-commented char before
            fCharFound = 0
            do forever
               if .col = 1 then
                  leave
               endif
               .col = .col - 1
               -- Get char at cursor
               ch1 = substr( ThisLine, .col, 1)
               if .col > 1 then
                  -- Get 2 chars at and before cursor
                  ch2 = substr( ThisLine, .col - 1, 2)
               endif
               if ch1 == \9 then
                  iterate
               elseif ch1 == ' ' then
                  iterate
               elseif ch2 == CloseCom then
                  -- Go to opening comment
                  'xcom l 'OpenCom'r-'
                  if rc then
                     leave
                  else
                     iterate
                  endif
               else
                  fCharFound = 1
                  leave
               endif
            enddo
            if fCharFound then
               leave
            endif
         enddo
         if ch1 <> ')' then
            iterate
         endif

         -- Todo: handle multi-line comments
         -- Find ( before
         'xcom l (r-'
         if rc then
            iterate
         endif

         -- Todo: handle multi-line comments
         -- Find ProcName before
         --'xcom l ^:o[A-Za-z_$].*exr-'
         'xcom l :o[A-Za-z_$].*exr-'
         if rc then
            iterate
         endif

         getline line
         line = translate( line, ' ', \t)
         dprintf( 'TAG', 'Found line' .line '= "'line'"')

         parse value strip( line) with line '('
         -- Get rightmost word
         ProcName = word( line, words( line))
         rc = 0

      endif

      if rc then
         leave
      endif
/*
      -- This is slow for large files
      if inside_comment( 'C') then
         end_line
         iterate
      endif
*/
      rc = 0
      leave
   enddo
   --dprintf( 'rc = 'rc' for ProcName = 'ProcName)

   display 2
   return rc

; ---------------------------------------------------------------------------
defproc pas_proc_search( var ProcName, fFindFirst)
   case = arg(3)
   if case = '' then  -- pascal search?
      case = 'c'      -- ignore case
   endif

   if case = 'e' then  -- Respect case: must be modula search
      Keywords = '(PROCEDURE)'  -- for 'x' search (extended Grep)
   else
      Keywords = '(overlay:w|)(pro(cedure|gram)|function)'
   endif
   Identifier = '[a-zA-Z_$][a-zA-Z0-9_$.]*'

   fFindProcName = (ProcName <> '')
   ProcLen = length( ProcName)
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l 'ProcName':o[\(;\:]x'case
      else
         'xcom l ^:o'Keywords':w'Identifier':o[\(;\:]x'case
      endif
   else
      repeat_find
   endif

   do forever

      if rc then
         display 2
         return rc
      endif

      getline line
      line = translate( line, ' ', \t)

      if fFindProcName then
         -- Determine if match is a substring of something else
         if .col > 1 then
            c = upcase( substr( line, .col - 1, 1))
            if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_' then
               end_line
               repeat_find
               iterate
            endif
         endif
         .col = .col + ProcLen
         c = upcase( substr( line, .col, 1))
         if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
            end_line
            repeat_find
            iterate
         endif
      else
         .col = pos( '(', line)
      endif

      -- pos function does not support allow c or e option
      if case = 'c' then
         p = pos( ' 'upcase( Keywords)'[ \t]', ' 'upcase( line), 1, 'x')
      else
         p = pos( ' 'Keywords'[ \t]', ' 'line, 1, 'x')
      endif
      if not p then
         end_line
         repeat_find
         iterate
      endif

      p = pos( '[\(;\:]', line, 1, 'x')
      if p then
         if substr( line, p, 1) == '(' then
            .col = p
            call psave_pos( save_pos)
            if find_matching_paren() then
               end_line
               repeat_find
               iterate
            endif
            call prestore_pos( save_pos)
         endif

         if pos( 'forward;', textline( .line)) then
            end_line
            repeat_find
            iterate
         endif

         if inside_comment( 'PASCAL') then
            repeat_find
            iterate
         endif

         line = substr( line, 1, p - 1)
         sline = strip( line)
         i = lastpos( ' ', sline)
         ProcName = strip( substr( sline, i + 1))
         display 2
         return 0
      endif

      end_line
      repeat_find

   enddo

; ---------------------------------------------------------------------------
defproc asm_proc_search( var ProcName, fFindFirst)
compile if ASM_TAGS_ANYWHERE
   LeadingSpace = ':o'
compile else
   LeadingSpace = ''
compile endif
   Identifier = ':c'

   fFindProcName = (ProcName <> '')
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^'LeadingSpace''ProcName':wproc(:w|$)xc'
      else
         'xcom l ^'LeadingSpace''Identifier':wproc(:w|$)xc'
      endif
   else
      repeat_find
   endif

   display 2
   parse value translate( textline( .line), ' ', \t) with ProcName .
   return rc

; ---------------------------------------------------------------------------
defproc cmd_proc_search( var ProcName, fFindFirst)
   LeadingSpace = ':o'
   Identifier = '[A-Z_][A-Z0-9_]*'

   fFindProcName = (ProcName <> '')
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^'LeadingSpace'\:'ProcName'cx'
      else
         'xcom l ^'LeadingSpace'\:'Identifier'cx'
      endif
   else
      repeat_find
   endif

   display 2
   parse value translate( textline( .line), ' ', \t) with ':'ProcName .
   return rc

; ---------------------------------------------------------------------------
defproc htext_proc_search( var ProcName, fFindFirst)
   Identifier = '[1-6]'

   fFindProcName = (ProcName <> '')
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^\.'Identifier':o'ProcName'cx'
      else
         'xcom l ^\.'Identifier':o.*cx'
      endif
   else
      repeat_find
   endif

   display 2

   -- Indent line according to the section type in order to give a better
   -- overview of the structure.
   ProcName = strip( textline(.line))
   parse value word( ProcName, 1) with '.'sectiontype
   if isnum( sectiontype) then
      -- Omit section type itself
      ProcName = subword( ProcName, 2)
      -- Indent line according to the section type
      ind = copies( ' ', 8)
      ProcName = copies( ind, sectiontype - 1)''ProcName
   endif

   return rc

; ---------------------------------------------------------------------------
defproc ipf_proc_search( var ProcName, fFindFirst)
   Identifier = '[1-6]'

   fFindProcName = (ProcName <> '')
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^\:h'identifier':o'ProcName'\.cx'
      else
         'xcom l ^\:h'identifier':o.*\.cx'
      endif
   else
      repeat_find
   endif

   display 2

   -- Indent line according to the section type in order to give a better
   -- overview of the structure.
   line = strip( textline(.line))
   parse value word( line, 1) with ':h'sectiontype rest
   parse value sectiontype with sectiontype'.'
   if isnum( sectiontype) then
      ProcName = ''
      -- find trailing dot
      startl = .line
      stopl  = startl + 2
      do l = startl to stopl
         p = pos( '.', line)
         if p > 0 then
            if IsString( leftstr( line, p - 1), "'") then
               -- reset p
               p = 0
            else
               -- this dot must end a tag
               ProcName = substr( line, p + 1)
            endif
         endif
         if p = 0 then
            -- append next line
            line = line textline( l + 1)
            iterate
         endif
      enddo
      if p = 0 then
         return 1
      endif
      -- Indent line according to the section type
      ind = copies( ' ', 8)
      ProcName = copies( ind, sectiontype - 1)''ProcName
   endif

   return rc

; ---------------------------------------------------------------------------
defproc javascript_proc_search( var ProcName, fFindFirst)
   LeadingSpace = ':o'
   Identifier = ':c'

   fFindProcName = (ProcName <> '')
   ProcLen = length( ProcName)
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^'LeadingSpace'function:w'ProcName'ex'
      else
         'xcom l ^'LeadingSpace'function:w'Identifier'ex'
      endif
   else
      repeat_find
   endif

   do forever
      if rc then
         display 2
         return rc
      endif

      if fFindProcName then
         if length( ProcName) <> ProcLen then  -- a substring of something else
            end_line
            repeat_find
            iterate
         endif
      endif

      parse value translate( textline( .line), ' ', \t) with . ProcName .
      if inside_comment( 'JAVASCRIPT') then
         repeat_find
         iterate
      endif

      leave
   enddo

   display 2
   return rc

; ---------------------------------------------------------------------------
defproc e_proc_search( var ProcName, fFindFirst)

compile if E_TAGS_ANYWHERE
   LeadingSpace = ':o'
compile else
   LeadingSpace = ''
compile endif
   Identifier = '[A-Z_][A-Z0-9_]*'

   fFindProcName = (ProcName <> '')

   -- Process previously stored defc command names first, if any.
   -- This handles defc cmd1, cmd2, ...
   getfileid fid
   if fFindProcName then
      NextProcs = GetAVar( 'e_tag_next_procs.'fid)
      if NextProcs <> '' then
         ProcName = word( NextProcs, 1)
         call SetAVar( 'e_tag_next_procs.'fid, subword( NextProcs, 2))
         return 0
      endif
   else
      call DropAVar( 'e_tag_next_procs.'fid)
   endif

   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l ^'LeadingSpace'DEF(((PROC|KEYS):w)|(C:w(|.*,:o)))\c'ProcName'~:rcx'
      else
         'xcom l ^'LeadingSpace'DEF(PROC|KEYS|C):w\c'Identifier'cx'
      endif
   else
      repeat_find
   endif

   do forever
      lrc = rc
      if lrc then
         display 2
         return lrc
      endif

      Col = GetPmInfo( EPMINFO_SEARCHPOS)
      Len = GetPmInfo( EPMINFO_LSLENGTH)
      ThisLine  = translate( textline(.line), ' ', \t)
      FoundProc = substr( ThisLine, .col, Len - .col + 1)
      RestLine  = substr( ThisLine, Len - Col + 2)
      ProcName = FoundProc

      -- dprintf( ThisLine)
      if inside_comment( 'E') then
         --dprintf( 'inside_comment')
         repeat_find
         iterate
      endif

      -- Strip trailing comment
      p = pos( '--', RestLine)
      if p then
         RestLine = leftstr( RestLine, p - 1)
      endif

      -- Replace multi-line comments (on current line only)
      do forever
         p = pos( '/*', RestLine)
         if not p then
            leave
         endif
         q = pos( '*/', RestLine, p + 2)
         if q then
            RestLine = overlay( '', RestLine, p, q - p + 2)  -- keep column alignment
         else
            RestLine = leftstr( RestLine, p - 1)
         endif
      enddo

      leave
   enddo  -- forever

   display 2

   --dprintf( 'rc from xcom l 'search'cx =' lrc', len = 'len', col = 'col', .col = '.col', FoundProc = ['FoundProc']')
   --call highlight_match()
   dprintf( 'TAG', 'Found ProcName = "'ProcName'" in line' .line '= "'textline(.line)'"')

   -- Store multiply defined command names in an array var.
   -- This handles defc cmd1, cmd2, ...
   NextProcs = ''
   if not fFindProcName then
      if upcase( word( ThisLine, 1)) = 'DEFC' then

         parse value RestLine with RestLine '='
         RestLine = strip( RestLine)
         --dprintf( 'RestLine = ['RestLine']')

         do while leftstr( RestLine, 1) = ','
            parse value RestLine with ',' Rest
            Rest = strip( Rest)

            if pos( ',', Rest) then
               parse value Rest with Next ',' Rest
               RestLine = ','strip( Rest)
            else
               parse value Rest with Next Rest
               RestLine = ''
            endif

            Next = strip( Next)
            --dprintf( 'FoundProc = ['Next']')

            NextProcs = strip( NextProcs Next)
         enddo
         call SetAVar( 'e_tag_next_procs.'fid, NextProcs)
      endif
   endif

   return lrc

; ---------------------------------------------------------------------------
; TAG_REXX_EXACT_SEARCH = 1 would use inside_comment. This is much too slow
; for mode REXX. Therefore comments are currently not recognized.
compile if not defined( TAG_REXX_EXACT_SEARCH)
const
   -- TAG_REXX_EXACT_SEARCH = 1 uses the defs from ASSIST.E to find comments
   -- and strings. It's slow for large REXX files.
   TAG_REXX_EXACT_SEARCH = 0
compile endif

defproc rexx_proc_search( var ProcName, fFindFirst)
   Identifier = ':r'  -- matches a Rexx language identifier; equivalent to [a-zA-Z!?_][a-zA-Z0-9!?_]*

   fFindProcName = (ProcName <> '')
   ProcLen = length( ProcName)
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l 'ProcName'\:c'  -- Must do case-insensitive search.
      else
         'xcom l ^:o'Identifier'\:xe'  -- Exact case is faster, the :r doesn't care about case.
      endif
   else
      repeat_find
   endif

   do forever

      if rc then
         display 2
         return rc
      endif

      getline line
--    line = translate( line, ' ', \t)
      dprintf( 'TAG', 'Found line' .line '= "'line'"')

      pColon = pos( ':', line, .col)
      if fFindProcName then
         -- Determine if match is a substring of something else
         if .col > 1 then
            c = upcase( substr( line, .col-1, 1))
            if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '!' | c = '?' | c = '_'  then
               .col = pColon + 1
               repeat_find
               iterate
            endif
         endif
      endif

      -- Remove single-line comments & quotes
      i = 1
      do forever
         c = pos( '/*', line, i)
         a = pos( "'", line, i)
         q = pos( '"', line, i)
         if not c & not a & not q then
            leave
         endif
         if c & (not a | a > c) & (not q | q > c) then  -- Open Comment appears first
            j = pos( '*/', line, i + 2)
            if j then
               line = overlay( '', line, c, j - c + 2)  -- Keep column alignment
            else
               line = leftstr( line, c - 1)
            endif
         else                           -- Single or double quote appears first
            if not q then               -- Figure out which it is...
               q = a
            elseif a then
               q = min( q, a)
            endif
            j = pos( substr( line, q, 1), line, q + 1)
            if j then
               line = overlay( '', line, q, j - q + 1)  -- Keep column alignment
            else
               line = leftstr( line, q - 1)
            endif
         endif
      enddo

      if substr( line, pColon, 1) <> ':' then  -- Was in a comment or quoted string
         dprintf( 'TAG', "...skipping; ':' inside a comment or string.")
         .col = pColon + 1
         repeat_find
         iterate
      endif

compile if TAG_REXX_EXACT_SEARCH
      if inside_comment( 'REXX') then
         --.col = pColon + 1
         end_line
         repeat_find
         iterate
      endif
/**/
      if inside_literal( 'REXX') then
         --.col = pColon + 1
         repeat_find
         iterate
      endif
/**/
compile endif
      if IsString( substr( line, 1, pColon)) then
         end_line
         repeat_find
         iterate
      endif

      display 2
      parse value substr( textline( .line), .col) with ProcName ':'
      return 0

   enddo

; ---------------------------------------------------------------------------
defproc tex_proc_search( var ProcName, fFindFirst)
   case = ''
   Keywords = '\\(part|chapter|(|sub|subsub)section|(|sub)paragraph|label|caption)(|\*):o({|\[)'

   fFindProcName = (ProcName <> '')
   ProcLen = length( ProcName)
   display -2

   if fFindFirst then
      if fFindProcName then
         'xcom l 'ProcName''case
      else
         'xcom l 'Keywords'xc'
      endif
   else
      repeat_find
   endif

   do forever
      if rc then
         display 2
         return rc
      endif
      getline line

      if fFindProcName then
         -- Determine if match is a substring of something else
         if .col > 1 then
            c = upcase( substr( line, .col - 1, 1))
            if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
               end_line
               repeat_find
               iterate
            endif
         endif
         .col = .col + ProcLen
         c = upcase( substr( line, .col, 1))
         if (c >= 'A' & c <= 'Z') | (c >= '0' & c <= '9') | c = '$' | c = '_'  then
            end_line
            repeat_find
            iterate
         endif
      else
         .col = pos( Keywords, line, 1, 'x')
      endif

      line = translate( line, ' ', \t)
      col = .col
      if not pos( Keywords, line, 1, 'x') then
         end_line
         repeat_find
         iterate
      endif

      p = pos( '{', line, col)
      if p then
         if substr( line, p, 1) == '{' then
            .col = p
         endif
         line = substr( line, col)
         i = lastpos( '}', strip( translate( line, ' ' ,\t)))
         if i then
           ProcName = substr( line, 1, i + 1)
         else
           ProcName = line
         endif
         test = substr( ProcName, 2, 5)
         if test == 'subse' then
            ProcName = '   'ProcName
         elseif test == 'subsu' then
            ProcName = '      'ProcName
         elseif (test == 'parag') | (test == 'subpa') then
            ProcName = '       'ProcName
         elseif test == 'capti' then
            ProcName = '       'ProcName
         elseif test == 'label' then
            ProcName = '         'ProcName
         endif
         display 2
         return 0
      endif

      end_line
      repeat_find
   enddo

; ---------------------------------------------------------------------------
; Used for PASCAL.
defproc find_matching_paren
   n = 1
   getsearch search_command -- Save user's search command.
   display -2
   'xcom l /[\(\)]/ex+F'
   do forever
      repeatfind
      if rc then
         leave
      endif
      if substr( textline(.line), .col, 1) = '(' then
         n = n + 1
      else
         n = n - 1
      endif
      if n = 0 then
         leave
      endif
   enddo
   display 2
   setsearch search_command -- Restores user's command so Ctrl-F works.
   return rc  /* 0 if found, else sayerror('String not found') */

; ---------------------------------------------------------------------------
defproc QuitTagsFile( startfid)
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif

   startfid = arg(1)
compile if KEEP_TAGS_FILE_LOADED
   activatefile startfid
compile else
   'xcom quit'
compile endif

; ---------------------------------------------------------------------------
defc tagsfile
   universal tags_file
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'TAGSFILE: arg(1) = 'arg(1))

   orig_name = tags_file
   if arg(1) = '' then
      parse value entrybox( TAGSNAME__MSG,
                            '/'SET__MSG'/'SETP__MSG'/'Cancel__MSG'/'Help__MSG'/',
                            tags_filename(),
                            '',
                            200,
                            atoi(1) || atoi(6070) || gethwndc(APP_HANDLE) ||
                            TAGSNAME_PROMPT__MSG) with button 2 newname \0
      if button = \1 | button = \2 then
         tags_file = newname
         if button = \2 & tags_file <> '' then
            call setini( 'TAGSFILE', tags_file)
         endif
      endif
   else
      tags_file = arg(1)
   endif
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid <> '' & orig_name <> tags_file then  -- New name; drop tags file
      getfileid startfid
      rc = 0
      activatefile tags_fileid
      if rc = 0 then
         'xcom quit'
      endif
      activatefile startfid
   endif
compile endif

; ---------------------------------------------------------------------------
defc tagsfile_perm
   universal tags_file
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'TAGSFILE_PERM')
   orig_name = tags_file
   if arg(1) <> '' then
      tags_file = arg(1)
      call setini( 'TAGSFILE', tags_file)
   endif
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid <> '' & orig_name <> tags_file then  -- New name; drop tags file
      getfileid startfid
      rc = 0
      activatefile tags_fileid
      if rc = 0 then
         'xcom quit'
      endif
      activatefile startfid
   endif
compile endif

; ---------------------------------------------------------------------------
defproc tags_filename()
   universal tags_file
   dprintf( 'TAGS', 'TAGS_FILENAME')
   if tags_file = '' then
      tags_file = checkini( 0, 'TAGSFILE', '')
   endif
   if tags_file = '' then
      tags_file = get_env('TAGS.EPM')
   endif
   if tags_file = '' then
      tags_file = 'tags.epm'
   endif
   return(tags_file)

; ---------------------------------------------------------------------------
defc find_tag, findtag
   universal CurEditCmd
compile if KEEP_TAGS_FILE_LOADED
   universal tags_fileid
compile endif
   dprintf( 'TAGS', 'FIND_TAG: arg(1) = 'arg(1))
   button = ''
   Ext = filetype()
   Mode = GetMode()

   if arg(1) = '' then
      -- Try to find the procedure at the cursor
      if substr(textline(.line), .col, 1)='(' then left; endif  -- If on paren, shift

      if Mode = "REXX" then
         token_separators = ' ~`$%^&*()-+=][{}|\:;/><,''"'\t  -- Rexx accepts '!' & '?' as part of the proc name.
      else
         token_separators = ''  -- Use the default defined in find_token()
      endif
      if not find_token(startcol, endcol, token_separators) then
         return 1
      endif

      -- We cannot avoid to use file extensions in the case of C++, since we do not have a seperate mode for it.
      if (wordpos( Ext, CPP_EXTENSIONS) > 0) | (Mode = "JAVA" ) then
         if substr( textline( .line), endcol + 1, 2)='::' &
            pos( upcase( substr( textline( .line), endcol + 3, 1)), IDENTIFIER_STARTER) then
            savecol = .col
            .col = endcol+3
            if find_token( startcol2, endcol2) then
               endcol = endcol2
            endif
            .col = savecol
         elseif .col > 3 then
            if substr( textline( .line), startcol - 2, 2)='::' &
               pos( upcase( substr( textline( .line), startcol - 3, 1)), IDENTIFIER_STARTER) then
               savecol = .col
               .col = startcol - 3
               if find_token( startcol2, endcol2) then
                  startcol = startcol2
               endif
               .col = savecol
            endif
         endif
      endif

      ProcName = substr( textline( .line), startcol, (endcol - startcol) + 1)
      if pos( '.', ProcName) then
         ProcName = substr( ProcName, lastpos( '.', ProcName) + 1)
      endif
   elseif arg(1) = '*' then
      parse value entrybox( FINDTAG__MSG,
                            '/'OK__MSG'/'LIST__MSG'/'Cancel__MSG'/'Help__MSG'/',
                            checkini(0, 'FINDTAG_ARG', ''),
                            '',
                            200,
                            atoi(1) || atoi(6010) || gethwndc(APP_HANDLE) ||
                            FINDTAG_PROMPT__MSG) with button 2 ProcName \0
      if button <> \1 & button <> \2 then
         return
      endif
      if button = \1 then
         call setini( 'FINDTAG_ARG', ProcName)
      endif
   else
      ProcName = arg(1)
   endif

   getfileid startfid
compile if KEEP_TAGS_FILE_LOADED
   if tags_fileid <> '' then
      rc = 0
      display -2
      activatefile tags_fileid
      display 2
      if rc then
         tags_fileid = ''
      else
         0              -- Go to top of file
      endif
   endif
   if tags_fileid = '' then
compile endif
      'xcom e /d ' tags_filename()
      if rc then
         if rc=-282 then  -- -282 = sayerror("New file")
            'xcom quit'
            sayerror "Tag file '"tags_filename()"' not found"
         else
            sayerror "Error loading tag file '"tags_filename()"' -" sayerrortext(rc)
         endif
         return 1
      endif
      getfileid tags_fileid
      .visible = 0  -- made it unvisible even if not KEEP_TAGS_FILE_LOADED
compile if KEEP_TAGS_FILE_LOADED
   endif
compile endif

   if button = \2 then  -- List (delayed until tags_file was loaded)
      sayerror BUILDING_LIST__MSG
      'xcom e /c .tagslist'
      if rc <> -282 then  -- -282 = sayerror("New file")
         sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
         return
      endif
      getfileid lb_fid
      browse_mode = browse()     -- query current state
      if browse_mode then
         call browse(0)
      endif
      .autosave = 0
      .visible = 0
      display -2
      do i = 1 to tags_fileid.last
         getline line, i, tags_fileid
         parse value line with tag .
         if tag <> '' & tag <> '*' then
            insertline tag, .last + 1
         endif
      enddo
      if browse_mode then
         call browse(1)  -- restore browse state
      endif
      display 2
      if not .modify then  -- Nothing added?
         'xcom quit'
         call QuitTagsFile( startfid)
         sayerror NO_TAGS__MSG
         return
      endif
      if listbox_buffer_from_file( tags_fileid, bufhndl, noflines, usedsize) then
         return
      endif
      parse value listbox( LIST_TAGS__MSG,
                           \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                           '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                           0, 0,  --1, 5,
                           min( noflines, 12), 0,
                           gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6012)) with button 2 ProcName \0
      call buffer( FREEBUF, bufhndl)

      if button <> \1 then
         call QuitTagsFile( startfid)
         return
      endif

   endif

   name = ProcName  -- Preserve original name.
compile if 1
   if pos( ':', ProcName) then
      grep = 'g'  -- Use the older one, because extended GREP treats colons specially
   else
      grep = 'x'  -- Use the faster one!
   endif
compile else
   tc = pos( ':', ProcName)
   if tc then
      temp = ''
      do while tc
         temp = temp || leftstr( ProcName, tc - 1) || '\:'
         ProcName = substr( ProcName, tc + 1)
         tc = pos( ':', ProcName)
      enddo
      ProcName = temp || ProcName
   endif
   grep = 'x'  -- Always use the faster one!
compile endif
   display -2
   tc = tag_case( startfid.filename)
   do i = 1 to 2
      'xcom l ^'ProcName' 'grep || tc
      if not rc then
         leave
      endif
      ProcName = '_'ProcName  -- Handle case where C call to assembler function needs '_'
   enddo
   display 2
   long_msg = '.  You may want to rebuild the tag file.'
   if rc then
      call QuitTagsFile( startfid)
      sayerror 'Tag for function "'name'" not found in 'tags_filename()long_msg
      return 1
   endif

   parse_tagline( name, filename, fileline, filedate)

   -- Check if there is more than one
   if .line < .last then
      found_line = .line
      '+1'
      parse_tagline( next_name, next_filename, next_fileline, next_filedate)
      if upcase( name) = upcase( next_name) then
         getfileid tags_fid
         'xcom e /c .temp'
         if rc <> -282 then  -- -282 = sayerror("New file")
            'xcom quit'
            return 1
         endif
         getfileid temp_fid
         browse_mode = browse()     -- query current state
         if browse_mode then
            call browse(0)
         endif
         .autosave = 0
         .visible = 0
         insertline '1. 'filename, 2
         activatefile tags_fid
         i = 2
         do forever
            if upcase( next_filename) <> upcase( filename) then
               insertline i'. 'next_filename, temp_fid.last + 1, temp_fid
               i = i + 1
            endif
            if .line = .last then
               leave
            endif
            '+1'
            parse_tagline( next_name, next_filename, next_fileline, next_filedate)
            if upcase( name) /== upcase( next_name) then
               leave
            endif
         enddo
         activatefile temp_fid
         .modify = 0
         if browse_mode then
            call browse(1)  -- restore browse state
         endif
         if .last > 2 then
            if listbox_buffer_from_file( tags_fid, bufhndl, noflines, usedsize) then
               return
            endif
            parse value listbox( 'Select a file',
                                 \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                                 '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,
                                 0, 0,
                                 min( noflines, 12), 60,
                                 gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6015) ||
;;                               "'"name"' appears in multiple files.") with button 2 filename \0
                                 "'"name"' appears in multiple files.") with button 2 i '.' \0
            call buffer( FREEBUF, bufhndl)
            if button <> \1 then  -- Didn't select OK
               filename = ''
            else
               --fileline = ''; filedate = ''  -- For now, don't try to keep track.
               found_line + i - 1     -- Go to the corresponding line, & parse the correct info.
               parse_tagline( name, filename, fileline, filedate)
            endif
         else
            'xcom quit'
         endif
         if filename = '' then
            call QuitTagsFile( startfid)
            return 1
         endif
      endif  -- duplicate names
   endif  -- not on last line

   call QuitTagsFile( startfid)

   -- Get fileid if filename is already in ring  (filename = filename with proc definition)
   getfileid already_loaded, filename
   -- Load file; load new view if already in ring
   CurEditCmd = 'SETPOS'  -- disable RestorePosFromEa
   'e /v' filename
   if rc then
      if rc=-282 then  -- -282 = sayerror("New file")
         'q'
         sayerror "'"filename"' not found"long_msg
      else
         sayerror "Error loading '"filename"' -" sayerrortext(rc)
      endif
      return 1
   endif
   if already_loaded <> '' then
      new_view = .currentview_of_file
   endif
   if tc = 'e' then  -- case-sensitive
      p = pos( ProcName, textline( fileline))
      lp = lastpos( ProcName, textline( fileline))
   else            -- not case-sensitive
      p = pos( upcase( ProcName), upcase( textline( fileline)))
      lp = lastpos( upcase( ProcName), upcase( textline( fileline)))
   endif
   -- dprintf( 'TAGS', 'FINDTAG: .filename = '.filename', already_loaded = 'already_loaded', p = 'p', lp = 'lp', fileline = 'fileline)
   if fileline & p & (p = lp) then
      -- If found once in fileline
      if already_loaded <> '' then
         sayerror 'File already loaded, starting new view.'
      endif
      .cursory = .windowheight%2  -- vcenter line
      'postme goto 'fileline p
      --fileline
      --.col = p
      if already_loaded <> '' then
         'postme postme activatefile' new_view  -- added; 2x postme required in most cases
      endif
      return
   endif
compile if 0  -- We already checked if the line # was good; the date no longer matters here.
   if filedate <> ''  then  -- Line number and file write date preserved
      if filedate = GetFileDateHex( filename) then  -- Same date means file has not been changed,
         'SayHint Jumping straight to line.'
         fileline                               -- so we can jump right to the line.
         .col = 1
         call proc_search( ProcName, 1, Mode, Ext)
         call prune_assist_array()
         return
      endif
   endif
compile endif
   -- If not found in fileline (file may have been changed) or found multiple times in fileline
   0
   'SayHint Searching for routine.'
   searchrc = proc_search( ProcName, 1, Mode, FType)
   call prune_assist_array()
   --sayerror 'Using proc_search for 'ProcName', filename = '.filename
   if searchrc then
      if already_loaded = '' then 'quit' endif
      sayerror ProcName" not found in '"filename"'"long_msg
      return 1
   endif
   if already_loaded <> '' then
      sayerror 'File already loaded, starting new view.'
      'postme postme activatefile' new_view  -- added; 2x postme required in most cases
   endif

; ---------------------------------------------------------------------------
defproc parse_tagline( var name, var filename, var fileline, var filedate)
   parse value textline( .line) with name filename fileline filedate .
   if leftstr( filename ,1) = '"' &
      (rightstr( filename, 1) <> '"' | length( filename) = 1) then
      parse value textline( .line) with name ' "'filename'"' fileline filedate .
      filename = '"'filename'"'
   endif

; ---------------------------------------------------------------------------
defc make_tags
   'MakeTags' arg(1)

; ---------------------------------------------------------------------------
defc QueryTagsFiles
   universal app_hini
   parse arg hwnd .
   App = INI_TAGSFILES\0
   IniData = copies( ' ', MAXCOL)
   l = dynalink32( 'PMSHAPI',
                   '#115',                -- PRF32QUERYPROFILESTRING
                   atol( app_hini)    ||  -- HINI_PROFILE
                   address( App)      ||  -- pointer to application name
                   atol( 0)           ||  -- Key name is NULL; returns all keys
                   atol( 0)           ||  -- Default return string is NULL
                   address( IniData)  ||  -- pointer to returned string buffer
                   atol(MAXCOL), 2)       -- max length of returned string

   if not l then  -- No tagsfiles saved
      if tags_filename() <> '' then
         MakeTags_Parm = checkini( 0, 'MAKETAGS_PARM', '')
         if MakeTags_Parm <> '' then
            call windowmessage( 0, hwnd,
                                32,               -- WM_COMMAND - 0x0020
                                mpfrom2short( 1, 4),  -- This is the default (and only one)
                                put_in_buffer( tags_filename()))
;           'querytagsfilelist' hwnd tags_filename()
         endif
      endif
      return
   endif
   IniData = leftstr( IniData, l)

   TagsFileU = upcase( tags_filename())
   do while IniData <> ''
      parse value IniData with TagsName \0 IniData
      call windowmessage( 0, hwnd,
                          32,               -- WM_COMMAND - 0x0020
                          mpfrom2short( (upcase( TagsName) = TagsFileU), 4),
                          put_in_buffer( TagsName))
      'querytagsfilelist' hwnd TagsName
   enddo

; ---------------------------------------------------------------------------
defc QueryTagsFileList
   parse arg hwnd TagsName
   call windowmessage( 0, hwnd,
                       32,               -- WM_COMMAND - 0x0020
                       5,
                       put_in_buffer( TagsFileList( TagsName)))

; ---------------------------------------------------------------------------
defproc TagsFileList( TagsName)
   universal app_hini
   App = INI_TAGSFILES\0
   TagsNameZ = upcase( TagsName)\0
   IniFileList = copies( ' ', MAXCOL)
   l = dynalink32( 'PMSHAPI',
                   '#115',                   -- PRF32QUERYPROFILESTRING
                   atol( app_hini)       ||  -- HINI_PROFILE
                   address( App)         ||  -- pointer to application name
                   address( TagsNameZ)   ||  -- Return value for this key
                   atol( 0)              ||  -- Default return string is NULL
                   address( IniFileList) ||  -- pointer to returned string buffer
                   atol( MAXCOL), 2)         -- max length of returned string
   if not l then  -- Not found in .INI file; try the TAGS file's EA
      getfileid startfid
      getfileid fid, TagsName
      fcontinue = 1
      if not fid then
         'xcom e' TagsName
         if rc then
            fcontinue = 0
            if rc = sayerror( 'New file') then
               'xcom quit'
            endif
         endif
      else
         activatefile fid
      endif
      if fcontinue then
         IniFileList = get_EAT_ASCII_value( 'EPM.TAGSARGS')
         l = length( IniFileList)
         if not fid then
            'xcom quit'
         endif
      endif
      activatefile startfid
   endif
   List = leftstr( IniFileList, l)
   List = strip( List, 'B', \0)  -- required
   return List

; ---------------------------------------------------------------------------
defc PopTagsDlg
   dprintf( 'TAGS', 'POPTAGSDLG')
   call windowmessage(0,  getpminfo( APP_HANDLE),
                      5158,               -- EPM_POPCTAGSDLG
                      0,
                      0)

; ---------------------------------------------------------------------------
defc TagsDlg_Make
   universal appname
   universal app_hini
   dprintf( 'TAGS', 'TAGSDLG_MAKE: arg(1) (tagsfilename maketagsargs) = 'arg(1))
   parse arg TagsFilename MakeTagsArgs
   if MakeTagsArgs = '' then
      sayerror -263  -- "Invalid argument"
      return
   endif
   call setprofile( app_hini, INI_TAGSFILES, upcase( TagsFilename), MakeTagsArgs)
   'TagsFile' TagsFilename
   'MakeTags' MakeTagsArgs

; ---------------------------------------------------------------------------
defc add_tags_info
   universal appname
   universal app_hini
   parse arg TagsFilename MakeTagsArgs
   if MakeTagsArgs = '' then
      sayerror -263  -- "Invalid argument"
      return
   endif
   call setprofile( app_hini, INI_TAGSFILES, upcase( TagsFilename), MakeTagsArgs)

; ---------------------------------------------------------------------------
defc delete_tags_info
   universal appname
   universal app_hini
   if arg(1) = '' then
      sayerror -263  -- "Invalid argument"
      return
   endif
   call setprofile( app_hini, INI_TAGSFILES, upcase( arg(1)), '')

; ---------------------------------------------------------------------------
defc TagScan
   universal vepm_pointer
   FType = filetype()
   Mode = NepmdGetMode()
   if not tags_supported( Mode) then
      sayerror "Don't know how to do tags for file of mode '"Mode"'"
      return 1
   endif

   call psave_pos( savepos)
   0
   getfileid sourcefid
   'xcom e /c .tagslist'
   if rc <> -282 then  -- -282 = sayerror("New file")
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   getfileid lb_fid
   browse_mode = browse()     -- query current state
   if browse_mode then
      call browse(0)
   endif
   .autosave = 0
   .visible = 0
   activatefile sourcefid
   ProcName = ''
   mouse_setpointer WAIT_POINTER
   'SayHint Searching for procedures...'
   rc = proc_search( ProcName, 1, Mode, FType)
   while not rc do
      insertline ProcName '('.line')', lb_fid.last + 1, lb_fid
      ProcName=''
      end_line
      rc = proc_search( ProcName, 0, Mode, FType)
   endwhile
   call prune_assist_array()
   call prestore_pos( savepos)
   if browse_mode then
      call browse(1)  -- restore browse state
   endif
   activatefile lb_fid
   sayerror 0
   mouse_setpointer vepm_pointer

   if not .modify then  -- Nothing added?
      'xcom quit'
      activatefile sourcefid
      sayerror NO_TAGS__MSG
      return
   endif

   if listbox_buffer_from_file( sourcefid, bufhndl, noflines, usedsize) then
      return
   endif
   parse value listbox( LIST_TAGS__MSG,         -- title
                        \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),  -- buffer
                        '/'OK__MSG'/'Cancel__MSG'/'Help__MSG,               -- buttons
                        0, 0,  -- 25, 15        -- top (0 = at cursor), left (0 = at cursor)
                        min( noflines, 20), 0,  -- height, width (0 = auto)
                        gethwndc(APP_HANDLE) ||
                        atoi(1) ||              -- default item
                        atoi(1) ||              -- default button
                        atoi(6012)) with button 2 ProcName \0  -- help panel id
   call buffer( FREEBUF, bufhndl)
   if button <> \1 then
      return
   endif
   -- Determine procname from list item, strip indent and linenum
   parse value strip( ProcName) with ProcName ' (' linenum ')'
   linenum
   .col = 1
   -- Locate procname in line, don't use the user's search options and suppress msgs
   display -2
   'xcom l '\1''ProcName
   lrc = rc
   display 2

