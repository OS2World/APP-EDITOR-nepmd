/****************************** Module Header *******************************
*
* Module Name: kwhelp.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: kwhelp.e,v 1.3 2002-08-18 20:35:13 aschn Exp $
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

const
   FORTRAN_TYPES = 'FXC F F77 F90 FOR FORTRAN'
   GENERAL_NOCASE_TYPES = 'CMD SYS BAT'

defc kwhelp = call pHelp_C_identifier()

/***********************************************/
/* pHelp_C_identifier()                        */
/***********************************************/
defproc pHelp_C_identifier
   universal savetype, helpindex_id
   ft = filetype()
;  if savetype = '' then              /* initialize file type so we know when it changes */
;     savetype = ft
;  endif

   if not find_token(startcol, endcol) then   /* only look for keywords if cursor is on a word */
      return
   endif

   call pGet_Identifier(identifier, startcol, endcol, ft)        /* locate the keyword in question */
   if identifier = '' then
      sayerror 'Unable to identify help subject from cursor position in source file'
      return
   endif

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
            'quit'
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

   /* search for keyword match */
   display -2
   getsearch savesearch
   /* Alter search criteria based on filetype */
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
      sayerror 'Unable to find an entry for 'identifier' in 'helpindex_id.userstring'.'
   else
      parse value substr(textline(.line), .col) with ',' line ')'
      /* Substitute all occurrances of '~' with the original identifier */
      loop
         i = pos('~', line)
         if not i then
            leave
         endif
         line = leftstr(line, i-1)||identifier||substr(line, i+1)
      endloop

      /* Execute keyword help command */
      if upcase(word(line,1))='VIEW' then
         sayerror 'Invoking View ...'
      endif
      'dos' line  -- execute the command
   endif
   activatefile CurrentFile

/***********************************************/
/* pGet_Identifier()                                                   */
/***********************************************/
defproc pGet_Identifier(var id, startcol, endcol, ft)

   getline line
   if wordpos(ft, FORTRAN_TYPES) then        /* Fortran doesn't need to mess w/ C classes */
      id = substr(line, startcol, (endcol-startcol)+1)
      return
   endif
;; is_class = 0; colon_pos = 0
   if substr(line, endcol+1, 2) = '::' then  -- Class?
      ch = upcase(substr(line, endcol+3, 1))
      if (ch>='A' & ch<='Z') | ch='_' then
         curcol = .col
         .col = endcol+3
         call find_token(junk, endcol)
         .col = curcol
;;       is_class = 1
      endif
   elseif startcol>3 then
      if substr(line, startcol-2, 2) = '::' then  -- Class?
         ch = upcase(substr(line, startcol-3, 1))
         if (ch>='A' & ch<='Z') | (ch>='0' & ch<='9') | ch='_' then
            curcol = .col
            .col = startcol-3
            call find_token(startcol, junk)
            .col = curcol
;;          is_class = 2
         endif
      endif
   endif
   id = substr(line, startcol, (endcol-startcol)+1)

/***********************************************/
/* pBuild_Helpfile()                                                   */
/***********************************************/
defproc pBuild_Helpfile(ft)
   universal helpindex_id, savetype
   rc = 0

   helplist = Get_Env('HELPNDX')
   if helplist='' then
      compile if defined(KEYWORD_HELP_INDEX_FILE)
                    helplist = KEYWORD_HELP_INDEX_FILE
      compile else
                    helplist = 'epmkwhlp.ndx'
      compile endif
   endif
   savelist = helplist

   do while helplist<>''
      parse value helplist with helpindex '+' helplist

      /* look for the help index file in current dir, EPMPATH, DPATH, and EPM.EXE's dir: */
      findfile destfilename, helpindex, '','D'

      if rc then
         /* If that fails, try the standard path. */
         findfile destfilename, helpindex, 'PATH'
         if rc then
            sayerror  'Help index 'helpindex' not found'
            rc = 0
            /* return -- changed this so that error is informational, not severe */
            destfilename = ''
         endif
      endif

      if destfilename <> '' then
         if pos(' ',destfilename) then
            destfilename = '"'destfilename'"'
         endif
         if helpindex_id then
            bottom
            last = .last
            'get' destfilename
            line = upcase(textline(last+1))

            if word(line,1)='EXTENSIONS:' & wordpos(ft, line) then
               /* Give priority to this helpfile by moving it to the top */
               call psave_mark(savemark)
               call pset_mark(last+1, .last, 1, MAXCOL, 'LINE', helpindex_id)
               0
               move_mark
               call prestore_mark(savemark)
            else
               if word(line,1)='EXTENSIONS:' & not wordpos('*', line) then
                  /* This helpfile is not relevant to the file being edited, so remove it */
                  call psave_mark(savemark)
                  call pset_mark(last+1, .last, 1, MAXCOL, 'LINE', helpindex_id)
                  delete_mark
                  call prestore_mark(savemark)
               endif
            endif

         else       /* Need to add first .NDX file to the editor ring */
            'xcom e /d' destfilename
            if rc = 0 then
               line = upcase(textline(1))
               if word(line,1)='EXTENSIONS:' & (wordpos(ft, line) | wordpos('*', line)) then        /* only read in 'relevant' files */
                  getfileid helpindex_id -- read in the file
                  .visible = 0
               else
                  /* This helpfile is not relevant to the file being edited, so remove it */
                  'quit'
               endif
            else
               sayerror 'Error reading helpfile ' destfilename
               rc = 8
            endif
         endif -- helpindex_id
      endif -- destfilename <> ''
   enddo

   if helpindex_id then            /* If helpfile is already built ... */
      helpindex_id.userstring = savelist
   endif
   savetype = ft
   return rc

