/****************************** Module Header *******************************
*
* Module Name: kwhelp.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: kwhelp.e,v 1.31 2006-03-11 20:47:15 aschn Exp $
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

   top; .col = 1

   -- Search for keyword match
   display -2
   getsearch savesearch
   -- Alter search criteria based on filetype
   if wordpos(ft, FORTRAN_TYPES GENERAL_NOCASE_TYPES) then
      case_aware = 'c'      -- Add 'ignore case' parameter for Fortran
   else
      case_aware = ''
   end
   'xcom /('identifier',/' case_aware  -- search for a match...
   if rc then
      do i = length(identifier) to 1 by -1
         'xcom /('leftstr(identifier, i)'*,/' case_aware
         if not rc then
            leave
         endif
      enddo
   endif
   setsearch savesearch
   display 2

   if rc then
      if (helpindex_id) then
         sayerror 'Unable to find an entry for "'identifier'" in:' helpindex_id.userstring
      else
         sayerror 'No matching indexfile found for "'identifier'"'
      endif
   else
      parse value substr(textline(.line), .col) with ',' line ')'
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
      parse value line with cmd arg1 arg2
      if (upcase(cmd) = 'START') then
         parse value line with . cmd arg1 arg2
      endif

      -- Search the file, if the command is a view
      if (upcase(cmd) = 'VIEW') then

         -- Use NewView, if found in PATH
         KeyPath = '\NEPMD\User\KeywordHelp\NewView\UseIfFound'
         next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
         if next <> 0 then
            next = NepmdSearchPath( 'newview.exe')
            parse value next with 'ERROR:' rc
            if rc = '' then
               cmd = 'newview'
            endif
         endif

         -- Second word is the file.
         -- Convert a possible ViewFileList to CheckedFileList, in order
         -- to continue searching if an .inf file doesn't exist.
         ViewFileList =  arg1
         rest = ViewFileList
         CheckedFileList = ''
         do while rest <> ''

            parse value rest with ViewFile'+'rest section

            -- EnvVars are already resolved at this point!

            -- Check if ViewFile specifies an EnvVar (e.g. PMREF)
            next = Get_Env(ViewFile)
            if next <> '' then
               -- If found, add next to rest and re-parse it
               rest = next'+'rest
               iterate
            endif

            if (pos( '.', ViewFile) = 0) then
               ViewFile = ViewFile'.inf';
            endif

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
         line = cmd CheckedFileList arg2
dprintf( 'KWHELP', 'line = 'line)

      endif

      if (line  <> '') then
         -- For newview: Execute a real search instead of just a lookup in the index.
         if upcase( word( line, 1)) = 'NEWVIEW' then
            parse value line with app inf key
            -- Newview requires "..." for strings with spaces, View strips them.
            if leftstr( key, 1) <> '"' then
               parse value key with wrd rest
               if rest > '' then
                  key = '"'strip( key)'"'
               endif
            endif
            -- Newview bug (still present with 2.16.4): needs doubled closing "
            -- Reproducable with: start newview cmdref /s:"net view"
            if leftstr( key, 1) = '"' then
               key = key'"'
            endif
            -- Use NewView's extended search
            KeyPath = '\NEPMD\User\KeywordHelp\NewView\ExtendedSearch'
            next = NepmdQueryConfigValue( nepmd_hini, KeyPath)
            if next <> 0 then
               line = 'newview 'inf' /s:'key
            endif
         endif
         if wordpos( upcase( word( line, 1)), 'START QS QUIETSHELL DOS OS2') then
            -- Omit the 'dos' or 'start' command if specified in .ndx file or
            -- as an alternative VIEW command.
            cmd = line
         else
            cmd = 'start /f' line
         endif
         sayerror 'Invoking "'cmd'"'
         cmd  -- execute the command
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

   -- search all files on shelf first, put list into ShelfList
   HelpNdxShelf = Get_Env('HELPNDXSHELF')
   HelpNdx      = Get_Env('HELPNDX');
   ShelfList = ''

   if HelpNdxShelf <> '' then

      -- If EnvVar HELPNDXSHELF is set then find *.ndx in all pathes
      SearchShelf = HelpNdxShelf

      do while SearchShelf <> ''

         -- Get single HelpDir from HelpNdxShelf
         parse value SearchShelf with NdxDir';'SearchShelf

         -- search all ndx files in this directory of the Ndx shelf path
         Filemask = NepmdQueryFullname( NdxDir)'\*.ndx'
         Handle = 0  /* always create a new handle ! */
         do forever
            Filename = NepmdGetNextFile(  FileMask, address(Handle) )
            parse value Filename with 'ERROR:'rc
            if (rc > '') then
               leave
            endif

            -- add filename only to HelpList, if not already in
            Filename = substr( Filename, lastpos( '\', Filename) + 1)
            if (pos( translate( Filename), translate( ShelfList'+'HelpNdx)) = 0) then
               ShelfList = ShelfList'+'Filename;
            endif
         enddo

      enddo -- do while SearchShelf <> ''


   endif -- if HelpNdxShelf <> '' then

   -- now prepend given help list to previous searchlist
   HelpList = HelpNdx''ShelfList;
   if HelpList='' then
      compile if defined(KEYWORD_HELP_INDEX_FILE)
                    HelpList = KEYWORD_HELP_INDEX_FILE
      compile else
                    HelpList = 'epmkwhlp.ndx'
      compile endif
   endif

   -- strip off leading plus char
   if (substr( HelpList, 1, 1) = '+') then
      HelpList = substr( HelpList, 2);
   endif

   SaveList = HelpList

   do while HelpList<>''

      /* parse thru all entries within the help list */
      parse value HelpList with HelpIndex'+'HelpList

      /* skip empty entries, they may show up due to a double plus character */
      if (HelpIndex = '') then
         iterate
      endif

      /* look for the help index file in HELPNDXPATH first */
      findfile destfilename, helpindex, 'HELPNDXSHELF'

      if rc then
         /* if that fails, look for the help index file in current */
         /* dir, EPMPATH, DPATH, and EPM.EXE's dir:                */
         findfile destfilename, helpindex, '','D'
      endif

      if rc then
         /* If that fails, try the standard path. */
         findfile destfilename, helpindex, 'PATH'
         if rc then
            sayerror 'Help index 'helpindex' not found'
            rc = 0
            /* return -- changed this so that error is informational, not severe */
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
            line = upcase(textline(last+1))
            -- Sometimes a DESCRIPTION: line comes first.
            -- Quick & dirty:  --<------------------------------------------------------------------ Todo
            if word( line, 1) = 'DESCRIPTION:' then
               line = upcase(textline(last+2))
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
               line = upcase(textline(1))
               -- Sometimes a DESCRIPTION: line comes first.
               -- Quick & dirty:  --<------------------------------------------------------------------ Todo
               if word( line, 1) = 'DESCRIPTION:' then
                  line = upcase(textline(2))
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

   if helpindex_id then            /* If helpfile is already built ... */
      helpindex_id.userstring = SaveList
   endif
   savetype = ft

   return rc

; ---------------------------------------------------------------------------
defc viewword  -- arg(1) is name of .inf file
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


