/****************************** Module Header *******************************
*
* Module Name: kwhelp.e
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
-  Implement MODE to replace filetype() and the EXTENSIONS: keyword in .ndx
   files. But EXTENSIONS has still to be supported, because e.g. .erx files
   use other .inf files than .cmd REXX files.
*/

/********************************************************************/
/* Modified 12/03/93 to include the following changes:              */
/*                                                                  */
/* - check filetype on keyword lookup - Fortran is case insensitive */
/* - when building the help file index, use only indices with       */
/*   EXTENSIONS = '*' or that match the filetype                    */
/* - re-build the helpfile index if filetype has changed since      */
/*   the last time it was built                                     */
/* - do not terminate if one of the help indexes is not found       */
/* - successive tries to match identifier with wildcards is         */
/*   terminated at 1 character + '*' rather than just '*'           */
/*                                                                  */
/********************************************************************/

/* format of index file:
     (Win*, view winhelp.inf ~)
     (printf, view edchelp.inf printf)
*/

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled
define INCLUDING_FILE = 'KWHELP.E'
const
   tryinclude 'MYCNF.E'        -- The user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

 compile if not defined(NLS_LANGUAGE)
  const NLS_LANGUAGE = 'ENGLISH'
 compile endif
include NLS_LANGUAGE'.e'

defmain
   'kwhelp' arg(1)
compile endif  -- not defined(SMALL)

const
compile if not defined(FORTRAN_TYPES)
   FORTRAN_TYPES = 'FXC F F77 F90 FOR FORTRAN'  --<---------------------------------------------------- Todo
compile endif
compile if not defined(GENERAL_NOCASE_TYPES)
;   GENERAL_NOCASE_TYPES = 'CMD SYS BAT'         --<---------------------------------------------------- Todo
   GENERAL_NOCASE_TYPES = 'CMD SYS BAT E'         --<---------------------------------------------------- Todo
compile endif

compile if not defined(GETNEXT_CREATE_NEW_HANDLE)
include 'STDCONST.E'
compile endif

; ---------------------------------------------------------------------------
defc KwhelpSelect
   Title   = 'Keyword help'
   Text    = 'Enter a keyword to perform a helpfile search on:'
   DefaultButton = 1
   -- The following must be posted in some cases, e.g. when a nodismiss
   -- menu item was toggled before:
   parse value entrybox( Title,
                         '/'OK__MSG'/'CANCEL__MSG,  -- max. 4 buttons
                         '',
                         '',
                         260,
                         atoi(DefaultButton)  ||
                         atoi(0000)           ||  -- help id
                         gethwndc(APP_HANDLE) ||
                         Text) with Button 2 NewValue \0
   NewValue = strip(NewValue)
   if Button = \1 & NewValue <> '' then
      Identifier = NewValue
      'kwhelp' Identifier
      return
   else
      return
   endif

; ---------------------------------------------------------------------------
const
compile if not defined( NEWVIEW_VERSION)
   --NEWVIEW_VERSION = '2.18'  -- for eCS 2.0b4 und before
   NEWVIEW_VERSION = 2.19
compile endif

defc Kwhelp
   universal savetype
   universal helpindex_id
   universal nepmd_hini

   ft = filetype()    --<---------------------------------------------------- Todo
;  if savetype = '' then              /* initialize file type so we know when it changes */
;     savetype = ft
;  endif

   Identifier = arg(1)
   if Identifier = '?' then
      -- Open entrybox
      -- 1) Executing the contents of KwhelpSelect here directly would lead to
      --    "Invalid argument".
      -- 2) The following works. Apparently after linking an .ex file, an
      --    entrybox must be opened from a separate command.
      'KwhelpSelect'
      -- 3) Postme here would lead to "Unknown command "KwhelpSelect"".
      --'postme KwhelpSelect'
      return
   elseif Identifier = '' then
      -- get identifier under cursor
      if not find_token( startcol, endcol) then   /* only look for keywords if cursor is on a word */
         return
      endif
      call pGet_Identifier( Identifier, startcol, endcol, ft)        /* locate the keyword in question */
      if Identifier = '' then
         sayerror 'Unable to identify help subject from cursor position in source file'
         return
      endif
   endif

   call psave_pos(savedpos)
   getfileid CurrentFile           /* save the id of the current file */
   if helpindex_id then            /* If helpfile is already built ... */
      display -2                      /* then make sure it is still available */
      rc = 0
      activatefile helpindex_id
      display 2
      if rc then  -- File's gone?
         helpindex_id = 0
      else                            /* If helpfile index is already built ... */
         if (ft <> savetype) then     /* then make sure the file extension has not changed */
            savetype = ft                 /* if it has ... reset the file type */
            --'quit'
            'xcom quit'
            activatefile CurrentFile
            helpindex_id = 0              /* and mark the helpfile index as unbuilt */
         endif
      endif
   endif
   if not helpindex_id then -- if the helpfile index is not built then build it
      call pBuild_Helpfile(ft)
      if rc then
         sayerror 'Unable to build help file'
         return
      endif
   endif

   -- Search for keyword match
   display -2
   getsearch savesearch

   -- Alter search criteria based on filetype
   if wordpos(ft, FORTRAN_TYPES GENERAL_NOCASE_TYPES) then
      case_aware = 'c'      -- Add 'ignore case' parameter for Fortran
   else
      case_aware = ''
   end

   s = 0
   l = length( identifier)
   do forever
      s = s + 1
      if s = 1 then
         search = '('identifier','
      else
         if l = 1 then
            leave
         endif
         l = l - 1
         search = '('leftstr( identifier, l)'*,'
      endif
      top
      .col = 1
      dprintf( 'kwhelp', 'search = 'search' ---------------------------------------')

      fFound = 0
      do while not fFound
         dprintf( 'kwhelp', 'xcom /'search'/'case_aware', .line before = '.line)
         'xcom /'search'/'case_aware  -- search for a match...
         if rc then
            leave
         endif

         parse value substr(textline(.line), .col) with ',' line ')'
         line = strip( line)
         dprintf( 'kwhelp', 'rc = 'rc', Found line '.line' = |'line'|')
         -- Substitute all occurrances of '~' with the original identifier
         loop
            i = pos( '~', line)
            if not i then
               leave
            endif
            line = leftstr( line, i - 1)''identifier''substr( line, i + 1)
         endloop

         -- Resolve environment vars in line
         line = ResolveEnvVars( line )  -- defined in EDIT.E

         -- Parse line
         dprintf( 'kwhelp', 'Parsing help line: 'line)
         parse value line with cmd arg1 arg2
         if (upcase(cmd) = 'START') then
            parse value line with . cmd arg1 arg2
         endif

         -- Search the file, if the command is a view
         dprintf( 'kwhelp', 'Building CheckedFileList')
         if (upcase(cmd) = 'VIEW') then

            -- Second word is the file.
            -- Convert a possible ViewFileList to CheckedFileList, in order
            -- to continue searching if an .inf file doesn't exist.
            ViewFileList =  arg1
            rest = ViewFileList
            CheckedFileList = ''
            ExpandedEnvVarList = ';'
            do while rest <> ''

               parse value rest with ViewFile'+'rest section

               -- EnvVars are already resolved at this point!

               -- Check if ViewFile specifies an EnvVar (e.g. PMREF)
               -- Expand each env var only once to omit an infinite loop (ticket #17)
               if pos( ';'upcase( ViewFile)';', ExpandedEnvVarList) = 0 then
                  next = Get_Env( ViewFile)
                  if next <> '' then
                     -- If found, add next to rest and re-parse it
                     ExpandedEnvVarList = ExpandedEnvVarList''upcase( ViewFile)';'
                     rest = next'+'rest
                     iterate
                  endif
               endif

               if (pos( '.', ViewFile) = 0) then
                  ViewFile = ViewFile'.inf'
               endif
               dprintf( 'kwhelp', 'ViewFile = 'ViewFile)
               -- Search the file
               findfile fullname, ViewFile, 'BOOKSHELF'
               if rc then
                  sayerror 'INF file' ViewFile 'could not be found'
               else
                  CheckedFileList = CheckedFileList''ViewFile'+'
               endif

            enddo  -- while rest <> ''

            -- Re-build the line with a file list containing only found files.
            CheckedFileList = strip( CheckedFileList, 'B', '+' )
            if CheckedFileList = '' then
               line = ''  -- Don't try to execute a line but execute
                          -- "activatefile" at the end. .HELPFILE is currently
                          -- active and would become visible on a "return" here.
            else
               line = cmd CheckedFileList arg2
            endif

         endif

         dprintf( 'kwhelp', 'line = |'line'|')
         if (line  = '') then
            rc = 1
         else
            rc = 0
            -- For newview: Maybe execute a real search instead of just a lookup
            -- in the index.
            -- Unfortunately their is no reliable way to check the install state
            -- nor the version of NewView, to handle its buggy command line
            -- parsing.
            if upcase( cmd) = 'VIEW' then

               parse value line with app inf key
               key = strip( key)

               -- Use NewView, if found in PATH
               fUseNewView = 0
               KeyPath = '\NEPMD\User\KeywordHelp\NewView\UseIfFound'
               next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
               if next <> 0 then
                  -- If NewView was installed as View replacement, then
                  -- IBMVIEW.EXE exists
                  next = NepmdSearchPath( 'ibmview.exe')
                  if next <> '' then
                     -- Better don't change 'VIEW', because NewView can re-use a file,
                     -- that is already loaded, when its stub (renamed to VIEW.EXE)
                     -- is used. Otherwise a new window is opened on every KwHelp.
                     --cmd = 'newview'
                     fUseNewView = 1
                  else
                     -- If NewView was not installed as View replacement, then
                     -- search for NEWVIEW.EXE in PATH
                     next = NepmdSearchPath( 'newview.exe')
                     if next <> '' then
                        fUseNewView = 1
                        cmd = 'newview'
                     endif
                  endif
               endif
               -- Use NewView's extended search?
               fNewViewExtendedSearch = 0
               if fUseNewView then
                  KeyPath = '\NEPMD\User\KeywordHelp\NewView\ExtendedSearch'
                  next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
                  if next <> 0 then
                     fNewViewExtendedSearch = 1
                  endif
               endif

               -- Testcases, press Alt+0 on a following line:
               /*
               start ibmview cmdref net view
               start ibmview cmdref "net view"
               start newview cmdref net view
               start newview cmdref "net view"
               start newview cmdref /s:net view
               start newview cmdref /s:"net view"
               start newview cmdref /s:"net view""
               start newview cmdref /s:"""net view"""
               start newview cmdref /s"""net view"""
               start newview cmdref /s net view
               start newview cmdref /s "net view"
               start newview cmdref /s "net view""
               start newview cmdref /s """net view""
               start newview cmdref /s """net view"""
               */
               if fUseNewView & leftstr( key, 1) <> '"' & pos( ' ', key) then
                  -- NewView before 2.19.b2 requires "..." for strings with spaces,
                  -- View strips them. Newer NewView versions can handle both, with
                  -- or without double quotes. So always add them.
                  key = '"'key'"'
                  -- NewView 2.19.b2 and up requires the doublequotes only for the
;                  -- extended search with /s:key.
                  -- extended search with /s key.
               endif
               if fNewViewExtendedSearch & leftstr( key, 1) = '"' then
compile if NEWVIEW_VERSION < 2.19
                  -- Newview before 2.19.b2 needs a doubled closing double quote
                  key = key'"'
;compile elseif NEWVIEW_VERSION >= 2.19
;                  -- NewView 2.19.b2 and up needs tripled double quotes
;                  key = '""'key'""'
compile endif
               endif
               if fNewViewExtendedSearch then
;                  line = 'view 'inf' /s:'key
                  line = 'newview 'inf' /s 'key
               endif

            endif  -- upcase( cmd) = 'VIEW'

            if wordpos( upcase( word( line, 1)), 'START QS QUIETSHELL DOS OS2') then
               -- Omit the 'dos' or 'start' command if specified in .ndx file or
               -- as an alternative VIEW command.
               cmd = line
            else
               cmd = 'start /f' line
            endif

            sayerror 'Invoking "'cmd'"'
            cmd  -- execute the command
            dprintf( 'kwhelp', 'rc = 'rc' from cmd = 'cmd)

         endif  -- (line = '')

         if rc then
            fFound = 0
            .line = .line + 1
         else
            fFound = 1
         endif

      enddo  -- while fFound

      if fFound then
         leave
      endif

   enddo

   setsearch savesearch
   display 2

   if rc then
      if (helpindex_id) then
         sayerror 'Unable to find an entry for "'identifier'" in:' helpindex_id.userstring
      else
         sayerror 'No matching indexfile found for "'identifier'"'
      endif
   endif

   activatefile CurrentFile
   call prestore_pos(savedpos)

; ---------------------------------------------------------------------------
defproc pGet_Identifier(var id, startcol, endcol, ft)

   getline line
                                --<--------------------------------------- probably Todo
   if wordpos(ft, FORTRAN_TYPES) then        /* Fortran doesn't need to mess w/ C classes */
      id = substr(line, startcol, (endcol-startcol)+1)
      return
   endif

   if (startcol >= 3) then
      if substr(line, startcol-2, 2) = '::' then
         startcol = startcol-2
      endif
   endif
   if substr(line, startcol, 2) = '::' then
      if (startcol = 1)  then
         endcol = startcol + 1
      else  -- startcol > 1
         if verify(substr(line, startcol-1, 1), ' '\t, 'M') then
            endcol = startcol + 1
         else  -- startcol > 1
            ch = upcase(substr(line, startcol-1, 1))
            if (ch>='A' & ch<='Z') | (ch>='0' & ch<='9') | ch='_' then
               curcol = .col
               .col = startcol-3
               call find_token(startcol, endcol)
               .col = curcol
            endif
         endif
      endif
   endif
   id = substr(line, startcol, (endcol-startcol)+1)
   if id = '::' then -- This is to support Object REXX ::class, ::requires, etc.
      if ft = 'CMD' then
         getline line
         if verify(substr(line, endcol + 1, 1), ' '\t) then
            curcol = .col
            .col = endcol + 1
            call find_token(junk, endcol)
            .col = curcol
            id = substr(line, startcol, endcol-startcol+1)
         endif
      endif
   endif

; ---------------------------------------------------------------------------
defproc pBuild_Helpfile(ft)
   universal helpindex_id, savetype
   rc = 0

   sayerror 'Building help index for' ft '...'
   dprintf( 'kwhelp', 'Building help index for' ft '...')

   -- Search all files on shelf first, put list into ShelfList
   BookShelf = Get_Env('BOOKSHELF')
   HelpNdx   = Get_Env('HELPNDX');
   ShelfList = ''

   -- If EnvVar HELPNDXSHELF is set then find *.ndx in all pathes
   Rest = BookShelf
   do while Rest <> ''

      -- Get single HelpDir from HelpNdxShelf
      parse value Rest with NdxDir';'Rest

      -- Search all ndx files in this directory of the Ndx shelf path
      Filemask = NepmdQueryFullname( NdxDir'\*.ndx')
      Handle   = ''  -- Always create a new handle!
      Filename = ''
      do while NepmdGetNextFile( FileMask, Handle, Filename)
         dprintf( 'kwhelp', 'Found .ndx file = 'Filename)

         -- Add filename only to HelpList, if not already in
         Filename = substr( Filename, lastpos( '\', Filename) + 1)
         if (pos( translate( Filename), translate( ShelfList'+'HelpNdx)) = 0) then
            ShelfList = ShelfList'+'Filename;
         endif
      enddo

   enddo

   -- Now prepend given help list to previous searchlist
   HelpList = HelpNdx''ShelfList;
   if HelpList='' then
compile if defined(KEYWORD_HELP_INDEX_FILE)
      HelpList = KEYWORD_HELP_INDEX_FILE
compile else
      HelpList = 'epmkwhlp.ndx'
compile endif
   endif

   -- Strip off leading plus char
   if (substr( HelpList, 1, 1) = '+') then
      HelpList = substr( HelpList, 2);
   endif
   dprintf( 'kwhelp', 'HelpList = 'HelpList)

   SaveList = HelpList

   do while HelpList <> ''

      -- Parse thru all entries within the help list
      parse value HelpList with HelpIndex'+'HelpList

      -- Skip empty entries, they may show up due to a double plus character
      if (HelpIndex = '') then
         iterate
      endif

      -- Look for the help index file in HELPNDXPATH first
      findfile destfilename, helpindex, 'BOOKSHELF'

      if rc then
         -- If that fails, look for the help index file in current
         -- dir, EPMPATH, DPATH, and EPM.EXE's dir:
         findfile destfilename, helpindex, '','D'
      endif

      if rc then
         -- If that fails, try the standard path.
         findfile destfilename, helpindex, 'PATH'
         if rc then
            sayerror 'Help index 'helpindex' not found'
            rc = 0
            -- return -- Changed this so that error is informational, not severe
            destfilename = ''
         endif
      endif

      if destfilename <> '' then
         if helpindex_id then
            bottom
            last = .last
            -- If 'get' uses 'e' and 'q' instead of 'xcom e' and 'xcom q':
            -- For certain .ndx files 'get' returns rc = 4868.
            'get "'destfilename'"'
            .modify = 0
            line = upcase( textline( last + 1))
            -- Sometimes a DESCRIPTION: line comes first.
            -- Quick & dirty:  --<------------------------------------------------------------------ Todo
            if word( line, 1) = 'DESCRIPTION:' then
               line = upcase( textline( last + 2))
            endif

            if word(line,1)='EXTENSIONS:' & wordpos(ft, line) then  --<--------------------------------- Todo
               /* Give priority to this helpfile by moving it to the top */
               call psave_mark(savemark)
               call pset_mark(last+1, .last, 1, MAXCOL, 'LINE', helpindex_id)
               0
               move_mark
               call prestore_mark(savemark)
            else
               if word(line,1)='EXTENSIONS:' & not wordpos('*', line) then  --<--------------------------------- Todo
                  /* This helpfile is not relevant to the file being edited, so remove it */
                  call psave_mark(savemark)
                  call pset_mark(last+1, .last, 1, MAXCOL, 'LINE', helpindex_id)
                  delete_mark
                  call prestore_mark(savemark)
               endif
            endif

         else       /* Need to add first .NDX file to the editor ring */
            'xcom e /d' destfilename
            .modify = 0
            .autosave = 0
            if rc = 0 then
               --'n .HELPFILE' -- make sure we don't use the name of the first file
               -- 'n' or 'xcom n' will give <path>\.HELPFILE, better use .filename:
               .filename = '.HELPFILE'
               line = upcase( textline( 1))
               -- Sometimes a DESCRIPTION: line comes first.
               -- Quick & dirty:  --<------------------------------------------------------------------ Todo
               if word( line, 1) = 'DESCRIPTION:' then
                  line = upcase( textline( 2))
               endif
               if word(line,1)='EXTENSIONS:' & (wordpos(ft, line) | wordpos('*', line)) then  --<--------------------------------- Todo
                  /* only read in 'relevant' files */
                  getfileid helpindex_id -- read in the file
                  .visible = 0
               else
                  /* This helpfile is not relevant to the file being edited, so remove it */
                  .modify = 0
                  --'quit'
                  'xcom quit'
               endif
            else
               sayerror 'Error reading helpfile ' destfilename
               rc = 8
            endif
         endif -- helpindex_id
      endif -- destfilename <> ''
   enddo

   if helpindex_id then  -- If helpfile is already built ...
      helpindex_id.userstring = SaveList
   endif
   savetype = ft

   return rc

; ---------------------------------------------------------------------------
defc ViewWord  -- arg(1) is name of .inf file
   if find_token( startcol, endcol) then
      InfFile = arg(1)
      -- resolve OS/2 environment vars
      InfFile = ResolveEnvVars( InfFile)
      --sayerror 'InfFile = 'arg(1)', InfFile with EnvVars resolved = 'InfFile
      -- specifying the extension is optional
      if upcase( rightstr( InfFile, 4)) <> '.INF' then
         InfFile = InfFile'.inf'
      endif
      findfile fully_qualified, InfFile, 'BOOKSHELF'
      if rc then
         sayerror FILE_NOT_FOUND__MSG '"'InfFile'"'
         return
      endif
      'view' InfFile substr(textline(.line), startcol, (endcol-startcol)+1)
   endif

