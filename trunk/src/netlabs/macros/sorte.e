/***************************************************************/
/* SORTE.E            Sorts internally, in E3 language.        */
/* Bryan Lewis        Jan 87.  Updated Oct 87                  */
/*                                                             */
/* This is faster than calling any of the external sort        */
/* utilities, up to about 100 lines.  Gets slow after that.    */
/* Avoids the worries about disk space and file handles.       */
/***************************************************************/

;defc ESORT=   /* alternative name */
 defc SORT =
   TypeMark=marktype()
   if TypeMark='' then  /* if no mark, default to entire file */
      getfileid fileid
      firstline=1 ; lastline=.last ; firstcol=1; lastcol = 40
   else
      getmark firstline,lastline,firstcol,lastcol,fileid
   endif

   /* If it was a line mark, the LastCol value can be 255.  Can't */
   /* imagine anyone needing a key longer than 40.                */
   if TypeMark='LINE' then lastcol=40 endif

compile if EVERSION < 5
   sayerror SORTING__MSG lastline-firstline+1 LINES__MSG '...'
compile endif

   /* Pass the sort switches "rc", if any, as a sixth argument to sort().    */
   call sort(firstline,lastline,firstcol,lastcol,fileid, arg(1) )

   sayerror 0



defproc sort(firstline,lastline,firstcol,lastcol,fileid)
        /* optional sixth arg = reverse/case switches: "rc" */
   Revers=0
   IgnoreCase=0
compile if EVERSION >= '5.20'
   undotime = 1            -- 1 = when starting each command
   undoaction 4, undotime  -- Disable state recording at specified time
compile endif
   if arg() > 5 then  /* if sixth argument was passed ... */
      if not verify('R',upcase(arg(6))) then  /* R anywhere */
         Revers=1
      endif
      if not verify('C',upcase(arg(6))) then  /* C anywhere */
         IgnoreCase=1
      endif
   endif

compile if RESTORE_MARK_AFTER_SORT
   call psave_mark(savemark)
   call prestore_mark(savemark)
compile endif
   call psave_pos(save_pos)

   X = lastline-firstline+1         /* X = number of lines. */

   /* An optimal set of increments for successive passes is:
   ** 1, 4, 13, 40, 121, 364, 1093, ....   See Knuth ACP vol.2 p.95.
   ** Pick the starting increment, then each successive one can be
   ** obtained by dividing the previous one by 3 (integer division).
   */
   M=1
   while (9*M+4) < X do
      M = M*3+1
   endwhile

   /* Copy the lines to a hidden file, for safety's sake and also for speed;
   ** we won't have to calculate line offsets.
   ** We want to copy complete lines, not a piece.  Change to line mark.
   */
   call pset_mark(firstline,lastline,firstcol,lastcol,'LINE',fileid)

compile if EVERSION < 4
   'xcom e /n'             /*  Create a temporary no-name file. */
compile else
   'xcom e /c temp'        /*  Create a temporary file. */
compile endif
   getfileid tempofid
   rc = 0
   copy_mark
   if rc then stop endif
   unmark
;; activatefile tempofid     -- Shouldn't be necessary??
   top; deleteline         /* Delete extra blank line at top. */

   /* Insert a column of an arbitrary alpha character before the key field
   ** to prevent leading spaces and numbers from affecting the comparison.
   ** (E ignores leading spaces in the test:  string1 <= string2. )
   ** Any non-digit non-space character will do; use '!'.
   */
   top; .col=firstcol
   mark_block; bottom; mark_block   /* mark a single column */
   shift_right; fill_mark '!'       /* insert column of '!' */
   unmark

   /* Insert a field of sequence numbers after the key field to insure the
   ** sort is stable.  If two records have equal keys then the comparison
   ** will be determined by the sequence numbers, thus preserving their
   ** original order.
   ** The sequence-number field will be 5 characters long.  The full key will
   ** look like "!datakey10001".  So key length = length(datakey) + 6.
   */
   keylength = (lastcol-firstcol+1) + 6

   /* Optimize for speed (saving about 20%) by using two separate sort loops,
   ** one for each Reverse case.  Removes extra IF clauses from the loop.
   */
   if not Revers then
      /* The fast way to create fixed-length numbers is to add 10000. */
      for i=1 to .last
         seq = 10000 + i   /* fixed-length numeric field */
compile if EPM
         replaceline insertstr(seq,textline(i),lastcol+1), i
compile else
         getline line,i
         replaceline substr(line,1,lastcol+1)||seq||substr(line,lastcol+2),i
compile endif
      endfor

      while M > 0 do    /* finally the actual sorting */
         K=X-M
         for J=1 to K
            I=J
            while I > 0 do
               L=I+M
               getline lineI,I; getline lineL,L /* Compare line I to line L. */
               keyI = substr(lineI,firstcol,keylength)
               keyL = substr(lineL,firstcol,keylength)
               if IgnoreCase=1 then
                  keyI=upcase(keyI)
                  keyL=upcase(keyL)
               endif
               if keyI<=keyL then leave endif
               replaceline lineL,I  /* swap */
               replaceline lineI,L
               I=I-M
            endwhile
         endfor
         M=M%3    /* generate next increment -- INTEGER division! */
      endwhile
   else
      /* For reverse the sequence field must be descending, sub from 20000. */
      for i=1 to .last
         seq = 20000 - i   /* fixed-length numeric field */
         getline line,i
compile if EPM
         replaceline insertstr(seq,textline(i),lastcol+1), i
compile else
         getline line,i
         replaceline substr(line,1,lastcol+1)||seq||substr(line,lastcol+2),i
compile endif
      endfor
      while M > 0 do
         K=X-M
         for J=1 to K
            I=J
            while I > 0 do
               L=I+M
               getline lineI,I; getline lineL,L
               keyI =substr(lineI,firstcol,keylength)
               keyL =substr(lineL,firstcol,keylength)
               if IgnoreCase=1 then
                  keyI=upcase(keyI)
                  keyL=upcase(keyL)
               endif
               if keyL<=keyI then leave endif
               replaceline lineL,I
               replaceline lineI,L
               I=I-M
            endwhile
         endfor
         M=M%3    /* Integer division */
      endwhile
   endif

   /* Remove the extra columns we inserted. */
   top; .col=firstcol; mark_block
   bottom; mark_block; delete_mark
   top; .col=lastcol+1; mark_block
   bottom; .col=lastcol+5; mark_block; delete_mark

   /* Fix rare bug.  If you just barely run out of memory at            */
   /* the end, E3 might not allow the copying of the sorted lines.      */
   /* The old way did a delete_mark first, could ruin the original text.*/
   /* Now we try to copy_mark first (so we temporarily have two copies  */
   /* of the lines in the same file) and then, if that goes well, delete*/
   /* the old lines.  This approach means we can't sort quite as big a  */
   /* block as before, but the file never gets trashed.                 */
   top; mark_line          /* Copy the new lines.  */
   bottom; mark_line
   activatefile fileid
   lastline
   rc=0
   copy_mark
   if rc then
      sayerror NO_SORT_MEM__MSG
      stop
   endif
;  unmark         -- Unnecessary; pset_mark starts with UNMARK.
   activatefile tempofid   /* Release temporary file. */
   .modify=0; 'xcom q'

   /* NOW we can delete the original! */
   activatefile fileid
   call pset_mark(firstline,lastline,firstcol,lastcol,'LINE',fileid)
   delete_mark

compile if RESTORE_MARK_AFTER_SORT
   call prestore_mark(savemark)
compile endif
   call prestore_pos(save_pos)
compile if EVERSION >= '5.20'
   undoaction 5, undotime  -- Enable state recording at specified time
compile endif
   return 0


/* Sample call of sort as a procedure, for testing.
defc testsort
   getfileid fileid
   call sort(1,2,1,20,fileid)
   sayerror 0
*/

