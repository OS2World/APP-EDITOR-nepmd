/****************************** Module Header *******************************
*
* Module Name: epmcomp.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmcomp.e,v 1.3 2002-08-09 19:47:03 aschn Exp $
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
/****************************************************************************

                        ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        ³  E P M C O M P . E    ³
                        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

                           By Larry Margolis
                           Modelled after E3COMP (by Dave Burton & Bryan Lewis)

  This is  a very useful  file-compare  utility  written  in the E language.
  Searches two files for differences, centers  the lines  so you  can easily
  flicker back and forth to see what's different.  Fast!

  Enhancements over E3COMP are:  the comparison is done via an internal opcode,
  for greatly increased speed.  The comparands are kept track of by fileid, so
  no need to modify the prevfile / nextfile keys.  In fact, once a comparison
  is started, other files can be added to the ring between the two being
  compared and EPMCOMP will continue to work.  Can handle case insensitive
  comparisons as well as ones ignoring leading / trailing spaces.

  The remainder of the comments are from E3COMP.E:

  Special features are: ability to get back in  sync after  being thrown off
  by an added or deleted line; and a LOOSEMATCH  command to  tell it  not to
  consider leading / trailing spaces in the comparison.


  Defines functions:

  COMPARE.  Will scan through a pair  of files  looking for  the first point
      where the two files differ.  If they differ on the current lines (that
      is, after you've found a difference), pressing COMPARE repeatedly will
      "flicker"   between the   two files   (do alternating   next-file  and
      previous-file operations).  The current line in the two  files will
  be centered in mid-screen so differences will be readily apparent.

  SYNC.  Will attempt to resynchronize the two files, by looking ahead up to
      11 lines in each file for a place where  the two  files are identical.
      Repeatedly pressing SYNC will "flicker" between the two files.

  FLICKER.  Alternate between the compared files

  The two files to be  compared should  be the  Current file  and the "next"
  file in the ring (the "next" file is the one made active  by a  single F10
  keypress).  Put the cursor on identical lines in the two files, then press
  the COMPARE key to skip to the first difference in each file.

  Press COMPARE a few times more to see the differences.  You  can then move
  the two cursors down to  identical lines  again "re-synchronize"  with the
  SYNC key, and repeat the process.

  Note that COMPARE "remembers" which  of the  two files  is currently being
  displayed; after you re-synchronize and compare again,  you will  again be
  looking at the  "first" of  the two  files, no  matter which  one you were
  looking at when you started the compare.  However, using  the  "NEXT-FILE"
  (F10) or  the "LAST-FILE" (Alt-F10)  key  causes this  recollection  to be
  "forgotten".

  A faster way to re-synchronize (if you are  within 11  lines of  a pair of
  matching lines) is to simply press the SYNC key.  Then  press it  again to
  see the other file (flicker).

  Defines:
     Ctrl-C
        As the COMPARE key
     Ctrl-S
        As the SYNC key

      LOOSEMATCH - Causes EPMCOMP to  consider lines  to be  matching even if
          indented differently, or if one of them has trailing blanks.

      EXACTMATCH - Causes EPMCOMP to  consider lines  to be  matching only if
          the lines are identical.

     Modifies the NEXT-FILE (F10) definition        (adjust to suit)
     Modifies the LAST-FILE (Alt-F10) definition    (adjust to suit)

*****************************************************************************/

; Updated to optionally add Compare and Sync to the action bar, and not use keys.


compile if not defined(EPM)
   include 'stdconst.e'
   tryinclude 'mycnf.e'
compile endif

compile if not defined(USE_MENU_FOR_EPMCOMP)
 compile if defined(USE_MENU_FOR_E3COMP)
const USE_MENU_FOR_EPMCOMP = USE_MENU_FOR_E3COMP
 compile else
const USE_MENU_FOR_EPMCOMP = 1
 compile endif
compile endif

#define IGNORE_SPACES 1
#define IGNORE_CASE   2
#define SINGLE_LINE   4

#define STATUS_INIT      0
#define STATUS_DIFFERENT 1
#define STATUS_SYNCHED   2
#define STATUS_NOMATCH   3
#define STATUS_DONE      4

   define MENUADD_ID = 0
;compile if USE_MENU_FOR_EPMCOMP
 compile if defined(STD_MENU_NAME)
  compile if STD_MENU_NAME = 'OVSHMENU.E'  -- This is one we know about...
   define MENUADD_ID = 2      -- Under View
  compile endif
  compile if STD_MENU_NAME = 'FEVSHMNU.E'  -- This is the only other one we know about...
   define MENUADD_ID = 3      -- Under View
  compile endif
 compile else  -- STD_MENU_NAME not defined; we're using STDMENU.E:
   define MENUADD_ID = 3      -- Under Search
 compile endif  -- defined(STD_MENU_NAME)
;compile endif  -- USE_MENU_FOR_EPMCOMP

definit                     /* 1=LOOSE matching as default. 0 for EXACT  */
   universal epmcomp_flags, epmcomp_status
   universal defaultmenu, activemenu

compile if defined(my_EPMCOMP_FLAGS)
   epmcomp_flags = my_EPMCOMP_FLAGS
compile else
   epmcomp_flags = IGNORE_SPACES
compile endif
   epmcomp_status = STATUS_INIT
compile if USE_MENU_FOR_EPMCOMP
   deletemenu defaultmenu, 6, 0, 0  -- delete the existing Help menu (we want it to stay at the right)
   buildsubmenu defaultmenu, 32, 'Compare!', 'epmcomp',  0, 0
   buildsubmenu defaultmenu, 33, 'Sync!',    'sync',     0, 0
compile endif

compile if MENUADD_ID
   buildmenuitem defaultmenu, MENUADD_ID, 3100, 'EPMcomp',     \1 || 'EPMCOMP options', 17, 0
   buildmenuitem defaultmenu, MENUADD_ID, 3101, '~Strip spaces', 'epmcompflags ts' || \1 || 'Toggle loose or exact comparison for EPMCOMP.', 0, 0
   buildmenuitem defaultmenu, MENUADD_ID, 3102, '~Ignore case', 'epmcompflags tc' || \1 || 'Toggle respect or ignore case for EPMCOMP.', 0, 0
   buildmenuitem defaultmenu, MENUADD_ID, 3103, \0, '', 4, 0
   buildmenuitem defaultmenu, MENUADD_ID, 3104, '~Reset comparands', 'epmcompflags reset' || \1 || 'Tell EPMCOMP to forget the files being compared.', 32769, 0
compile endif

compile if USE_MENU_FOR_EPMCOMP
   call readd_help_menu()
compile elseif MENUADD_ID
   call maybe_show_menu()
compile endif

compile if not USE_MENU_FOR_EPMCOMP
def c_c='epmcomp'        /*     define C-C to be the "compare" key   */
compile endif

defc epmcomp
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2

;  getfileid start_fid
   start_fid = .currentview_of_file
   call ppini_comp()
   if wordpos(epmcomp_status, STATUS_DIFFERENT STATUS_NOMATCH STATUS_DONE) then
;     getfileid this_fid
      this_fid = .currentview_of_file
      if this_fid = start_fid then
         call ppflicker()  /* switch to other file */
      endif
   else
      sayerror 'Comparing...'
      res = filecompare(epmcomp_fid1, epmcomp_fid2, epmcomp_flags)
      if res = 0 then
         sayerror 'No differences.'
         epmcomp_status = STATUS_DONE
      elseif res = 2 then
         sayerror 'Reached end of only one file.'
         epmcomp_status = STATUS_DIFFERENT
      else
         sayerror 0
         epmcomp_status = STATUS_DIFFERENT
      endif
      call ppend_comp()
   endif
/* end of compare key definition */



/****************************************************************************
We have 7 private variables in this def, four of which have double uses:
     c_count1 & c_count2  =  saved positions after a "no match" compare,
                             line counter while scanning
     c_limit1 & c_limit2  =  saved file sizes after a "no match" compare,
                             limit to line counter while scanning
     c_got1 & c_got2      =  "got a match" positions while scanning
     c_success               "got one" flag while scanning
****************************************************************************/
compile if not defined(SYNC_LIMIT)
   const SYNC_LIMIT = 21
compile endif

compile if not USE_MENU_FOR_EPMCOMP
def c_s='sync'               /*  Define C-S to be the sync key     */
compile endif

defc sync
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2

;  getfileid start_fid
   start_fid = .currentview_of_file
   call ppini_comp()
   if wordpos(epmcomp_status, STATUS_NOMATCH STATUS_SYNCHED STATUS_DONE) then
;     getfileid this_fid
      this_fid = .currentview_of_file
      if this_fid = start_fid then
         call ppflicker()  /* switch to other file */
      endif
   else  -- status = STATUS_DIFFERENT or STATUS_INIT
      startline1 = epmcomp_fid1.line
      startline2 = epmcomp_fid2.line
      c_limit1 = min(.last-.line, SYNC_LIMIT) /* we look ahead only a few lines (lest, it be too slow) */
      c_got1=0
      c_got2=0
      c_success=0
      flags = epmcomp_flags + SINGLE_LINE
      for c_count1 = 0 to c_limit1
         epmcomp_fid1.lineg = startline1 + c_count1
         if c_success then
            c_limit2 = min((c_got1+c_got2)-c_count1-1, min(epmcomp_fid2.last-startline2, SYNC_LIMIT))
         else
            c_limit2 = min(epmcomp_fid2.last-startline2, SYNC_LIMIT)
         endif
         /* we've carefully calculated the limits so that we'll only find */
         /* "better" matches than those we've already found.  A "better"  */
         /* match is one which is nearer to the current lines (not as     */
         /* far down).  More precisely, the best match is the one with a  */
         /* minimum sum of the two lines numbers.                         */
         for c_count2 = 0 to c_limit2
            epmcomp_fid2.lineg = startline2 + c_count2
            if not filecompare(epmcomp_fid1, epmcomp_fid2, flags) then
               if length(textline(.line)) then
                   c_got1=c_count1
                   c_got2=c_count2
                   c_success=1
                   leave  /* break out of the inner for loop */
               endif
            endif
         endfor
      endfor
      if c_success then
         epmcomp_fid1.lineg = startline1 + c_got1
         epmcomp_fid2.lineg = startline2 + c_got2
         epmcomp_status = STATUS_SYNCHED
      else
         epmcomp_fid1.lineg = startline1
         epmcomp_fid2.lineg = startline2
         epmcomp_status = STATUS_NOMATCH
         sayerror 'No match within' SYNC_LIMIT 'lines'
      endif
      call ppend_comp()
   endif
/* end of synchronize key definition */


;def c_f10=            /*     define Ctrl-F10 to be the "flicker" key  */
;def a_f10=            /*     define Alt-F10 to be the "flicker" key   */
;def c_w=             /*     define Ctrl-W to be the "flicker" key    */
;   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2
;   call ppflicker()


     /* Common stuff for compare and synchronize keys */

defproc ppini_comp
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2
   universal epmcomp_line1, epmcomp_line2, epmcomp_linetext1, epmcomp_linetext2

    /* If in second file, switch to 1st file */

   if epmcomp_status <> STATUS_INIT then  -- check if we're on one of the files of interest.
;     getfileid fileid
      fileid = .currentview_of_file
      if fileid = epmcomp_fid2 then
         rc = 0
         activatefile epmcomp_fid1
         if rc = -260 then  -- Invalid fileid
            epmcomp_status = STATUS_INIT
         endif
      elseif fileid<>epmcomp_fid1 then  -- Neither of the original files; reset.
         epmcomp_status = STATUS_INIT
      else  -- We're on first file, just verify that second is still valid.
         if not validatefileid(epmcomp_fid2) then
            epmcomp_status = STATUS_INIT
         endif
      endif
   endif

     /* get initial line numbers & file ids to compare */

   if epmcomp_status = STATUS_INIT then
;     getfileid epmcomp_fid1
      epmcomp_fid1 = .currentview_of_file
      nextfile
;     getfileid epmcomp_fid2
      epmcomp_fid2 = .currentview_of_file
      prevfile
   endif
   if (not epmcomp_fid1.line) and epmcomp_fid1.last then epmcomp_fid1.lineg=1; endif
   if (not epmcomp_fid2.line) and epmcomp_fid2.last then epmcomp_fid2.lineg=1; endif

   if epmcomp_status <> STATUS_INIT then
      status_has_changed = 0
      if epmcomp_fid1.line <> epmcomp_line1 then  -- If user manually moved around,
         status_has_changed = 1                   -- we don't know the current state
      elseif epmcomp_fid2.line <> epmcomp_line2 then
         status_has_changed = 1
      elseif textline(.line) /== epmcomp_linetext1 then  -- If user modified the current
         status_has_changed = 1                          -- line, we also have to recheck.
      else
         getline line, epmcomp_line2, epmcomp_fid2
         if line /== epmcomp_linetext2 then
            status_has_changed = 1
         endif
      endif
      if status_has_changed then
         if filecompare(epmcomp_fid1, epmcomp_fid2, epmcomp_flags+SINGLE_LINE) then
            epmcomp_status = STATUS_DIFFERENT
         else
            epmcomp_status = STATUS_SYNCHED  -- or STATUS_DONE; do we need to differentiate?
         endif
         -- Note:  epmcomp_line1 and/or epmcomp_line2 are wrong now, but we don't care.
      endif
   endif

;  if epmcomp_status = STATUS_INIT then
;     epmcomp_line1 = epmcomp_fid1.line
;     epmcomp_line2 = epmcomp_fid2.line
;  endif
;  call ppcenter_screen()


/* called after a Compare or Sync, to center the 2 files on the screen */

defproc ppend_comp
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2
   universal epmcomp_line1, epmcomp_line2, epmcomp_linetext1, epmcomp_linetext2

   activatefile epmcomp_fid2
   call ppcenter_screen()
   activatefile epmcomp_fid1
   call ppcenter_screen()

   epmcomp_line1 = epmcomp_fid1.line
   epmcomp_line2 = epmcomp_fid2.line
   getline epmcomp_linetext1, epmcomp_line1, epmcomp_fid1
   getline epmcomp_linetext2, epmcomp_line2, epmcomp_fid2


/* flicker procedure -- call to switch to other file */

defproc ppflicker
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2

;  getfileid fid
   fid = .currentview_of_file
   if fid = epmcomp_fid2 then
      activatefile epmcomp_fid1
   else
      activatefile epmcomp_fid2
   endif
   call ppcenter_screen()
/* end of flicker procedure definition */


/***********************************************************************
Procedure to center current line on screen, except that if either
   file is currently "at" a line number less than 1/2 of a screen,
   then the current position is set at that line (so they'll line up
   properly when you "flicker" with ctrl-F10).  Note that I haven't
   been able to make this work for small files.  Sigh.

************************************************************************/
defproc ppcenter_screen
   universal epmcomp_status, epmcomp_flags, epmcomp_fid1, epmcomp_fid2

   temp=.line
   .cursory=.windowheight%2   /* % for integer division */
   if (epmcomp_fid1.line<.cursory) then
      .cursory=epmcomp_fid1.line+1
   endif
   if (epmcomp_fid2.line<.cursory) then
      .cursory=epmcomp_fid2.line+1
   endif
   if (.cursory <= 1) then
      .cursory=2
   endif
   .cursorx=1
   temp


defc loose, loosematch=
   universal epmcomp_flags
   if not (epmcomp_flags//2) then
      epmcomp_flags = epmcomp_flags + IGNORE_SPACES
   endif
   sayerror 'COMPARE will use loose matching now.'

defc exact, exactmatch=
   universal epmcomp_flags
   if epmcomp_flags//2 then
      epmcomp_flags = epmcomp_flags - IGNORE_SPACES
   endif
   sayerror 'COMPARE will use exact matching now.'


compile if MENUADD_ID
defc epmcompflags
   universal epmcomp_status, epmcomp_flags
   if arg(1) = 'ts' then  -- toggle Strip Spaces
      flag = epmcomp_flags // 2
      if flag then
         epmcomp_flags = epmcomp_flags - IGNORE_SPACES
      else
         epmcomp_flags = epmcomp_flags + IGNORE_SPACES
      endif
   elseif arg(1) = 'tc' then  -- toggle Strip Spaces
      flag = epmcomp_flags % 2 // 2
      if flag then
         epmcomp_flags = epmcomp_flags - IGNORE_CASE
      else
         epmcomp_flags = epmcomp_flags + IGNORE_CASE
      endif
   elseif arg(1) = 'reset' then
      epmcomp_status = STATUS_INIT
   endif

defc menuinit_3100
   universal epmcomp_status, epmcomp_flags
   flag = epmcomp_flags // 2
   SetMenuAttribute( 3101, 8192, not flag)
   flag = epmcomp_flags % 2 // 2
   SetMenuAttribute( 3102, 8192, not flag)
   SetMenuAttribute( 3104, 16384, epmcomp_status<>STATUS_INIT)
compile endif
