/****************************** Module Header *******************************
*
* Module Name: all.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: all.e,v 1.2 2002-07-22 18:58:46 cla Exp $
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
/* This command will create a new file showing all occurrances of the */
/* search string given.  Syntax:  ALL /find_string[/[c]]              */
/* where / can be any delimiter, and c means ignore case.             */
/*                                                                    */
/* The key c_Q is set up so that if you press it while in the .ALL    */
/* file, it will position you on the corresponding line in the        */
/* original file.  If you are not in .ALL, you will be placed there   */
/* and the cursor will be moved down one line.  This enables you to   */
/* rapidly switch from .ALL to succeeding lines of the original.      */
/*                                                                    */
/* Set ALL_HIGHLIGHT_COLOR in your MYCNF.E to have the "hits"         */
/* highlighted in the .all file.  E.g.,                               */
/*    compile if defined(BLACK)                                       */
/*    define                                                          */
/*       ALL_HIGHLIGHT_COLOR = Magenta + Yellowb                      */
/*    compile endif                                                   */
/*                                                                    */
/* Author:  Larry Margolis, MARGOLI at YORKTOWN                       */

compile if not defined(SMALL)  -- If being externally compiled...
 define INCLUDING_FILE = 'ALL.E'
const
   tryinclude 'MYCNF.E'
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

defmain
   'all' arg(1)
compile endif

define
 compile if defined(HIGHLIGHT_COLOR)
   XCOM_L = 'L'            -- Do a DEFC L, so that the string gets highlighted.
 compile else
   XCOM_L = 'XCOM L'       -- Otherwise, use the faster internal locate command
 compile endif

defc all=   /* ALL macro */
   universal allorig,allsrch,default_search_options
   call psave_pos(save_pos)
compile if EVERSION < 5
   cursor_data
compile endif
   if .filename = '.ALL' & arg(1) then
      .filename = '.prev_ALL'
   endif
   getfileid allorig
   'e /q /n .ALL'    /* Don't use XCOM so can handle either windowing style */
   .filename = '.ALL'
   getfileid allfile
   allsrch=strip(arg(1),'L')
   if allsrch='' then
      .modify=0
      'q'
      if allorig<>allfile then activatefile allorig; endif
      sayerror 1
      return
   endif
   for i=1 to .last
      deleteline 1
   endfor
   activatefile allorig

    /* Copied from DEFC L - we only will use E or C (case) and A or M (mark)  */
    DSO=''   /* subset of default_search_options */
    do i=1 to length(default_search_options)
       ch=substr(default_search_options,i,1)
       if pos(ch,'EeCcAaMm')>0 then DSO=DSO || ch endif
    end
    /* Insert default_search_options just before supplied options (if any)    */
    /* so the supplied options will take precedence.                          */
;   if DSO then
       ch=substr(allsrch,1,1)
       p=pos(ch,allsrch,2)
       user_options=''
       if p>0 then
          user_options=substr(allsrch,p+1)
          allsrch=substr(allsrch,1,p-1)
       endif
       allsrch=allsrch||ch||DSO||user_options
;   endif
   last_line = .last
   if pos('M', upcase(DSO || user_options)) > pos('A', upcase(DSO || user_options)) then
      getmark line, last_line  -- /x/m will move to start of mark if past end!
   endif

   0
compile if EVERSION >= 5
   display -3
compile endif
   do forever
      .col=1
      'xcom l' allsrch
      if rc=-273 then leave; endif  -- sayerror("String not found")
      getline line
compile if EVERSION >= '5.17'
      line=rightstr(.line,5) line
compile else
      line=substr('    '.line,length(.line)) line
compile endif
      insertline line,allfile.last+1,allfile
compile if defined(ALL_HIGHLIGHT_COLOR)
 compile if EVERSION >= '6.02'
      col = getpminfo(EPMINFO_SEARCHPOS) + 6
      len = getpminfo(EPMINFO_LSLENGTH)
 compile else
      col = .col
      len = getpminfo(EPMINFO_LSLENGTH)
 compile endif
      Insert_Attribute_Pair(1, ALL_HIGHLIGHT_COLOR, allfile.last, allfile.last, col, col+len-1, allfile)
compile endif
      if .line=last_line then leave; endif
      '+1'
   end
compile if EVERSION >= 5
   display 3
compile endif
   call prestore_pos(save_pos)
   if allfile.last=0 then
      activatefile allfile
      .modify=0
      'q'
      activatefile allorig
      sayerror -273 -- sayerror("String not found")
      return
   endif
   sayerror 0
   activatefile allfile
compile if EVERSION < 4
   call select_edit_keys()
compile endif
compile if defined(ALL_HIGHLIGHT_COLOR)
   call attribute_on(1)
compile endif
   sayerror 0
   .modify=0; top; .col=7
compile if EVERSION < 5
   cursor_data
   XCOM_L allsrch'A'  -- Position cursor under first hit.
compile else  -- Use PostMe to delay execution until after DEFLOAD sets font
   'postme' XCOM_L allsrch'A'  -- Position cursor under first hit.
compile endif

compile if not defined(ALL_KEY)
define ALL_KEY = 'c_Q'
compile endif

def $ALL_KEY =      -- Shows the .ALL file's current line in the original file
   universal allorig,allsrch
compile if EVERSION < 5
   universal messy
compile endif
   if .filename <> '.ALL' then
      getfileid allfile,'.ALL'
      if allfile='' then
         sayerror NO_ALL_FILE__MSG
      else
compile if EVERSION < 5
         if messy then .box = 1; endif
compile endif
         activatefile allfile
compile if EVERSION < 5
         if messy then .box = 2; endif
compile if EVERSION < 4
         call select_edit_keys()
compile endif
compile endif
                /* Scroll the .ALL file a la FILEMAN. */
         if .line=.last then
            top
         elseif .last <= .windowheight-2 then     /* no need to scroll */
            .cursory=.cursory+1
         elseif .line < .windowheight%2 then      /* no need to scroll - yet */
            .cursory=.cursory+1
         elseif .last-.line < .windowheight%2 then  /* === Bot === on screen */
            .cursory=.cursory+1
         else                                     /* Scroll ! */
            '+1'
            oldline=.line
            .cursory=(.windowheight+1)%2     /* Center vertically */
            oldline
         endif
         .col=6  /* Skip line number for search */
         XCOM_L allsrch'A'
      endif
      return
   endif  /* .filename <> '.ALL' */
   getline line
   parse value line with line .
   if not isnum(line) then
      sayerror BAD_ALL_LINE__MSG
      return
   endif
compile if EVERSION < 5
   if messy then .box = 1; endif
compile endif
   activatefile allorig
compile if EVERSION < 5
   if messy then .box = 2; endif
 compile if EVERSION < 4
   call select_edit_keys()
 compile endif
compile endif
   .cursory=.windowheight%2     /* Center vertically */
   line
   .col=1
   XCOM_L allsrch'A'
