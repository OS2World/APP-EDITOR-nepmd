/****************************** Module Header *******************************
*
* Module Name: clipbrd.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: clipbrd.e,v 1.4 2003-08-31 22:58:10 aschn Exp $
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
ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
º What's it called: clipbrd.e                                                º
º                                                                            º
º What does it do:  contains procedures and commands that all:               º
º                  -Allow one to pass lines of text between edit windows     º
º                  -Allow text to be placed in the PM clipboard              º
º                                                                            º
º                Text Manipulation between Edit Windows                      º
º                ======================================                      º
º                Copy2SharBuff  -  Copy Marked area to EPM shared buffer     º
º                GetSharBuff    -  Get text from EPM shared buffer           º
º                ClearSharBuf   -  Flush out Stuff in shared buffer          º
º                Copy2DMBuff    -  Copy Marked area to "Delete Mark" buffer  º
º                GetDMBuff    -  Get text from "Delete Mark" buffer          º
º                                                                            º
º                Text Manipulation between an Edit Window and PM clipboard   º
º                ========================================================    º
º                                                                            º
º                copy2clip - copy marked text to the PM clipboard.           º
º                                                                            º
º                cut - like copy2clip, but deletes the marked text.          º
º                                                                            º
º                paste - retrieve text from PM clipboard to edit window.     º
º                                                                            º
º                                                                            º
º Who and When: Ralph Yozzo, Gennaro (Jerry) Cuomo, & Larry Margolis 3-88    º
º                                                                    6/89    º
ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
*/
   #define CR_TERMINATOR_LDFLAG           1  -- Use CR as a terminator
   #define LF_TERMINATOR_LDFLAG           2  -- Use LF as a terminator
   #define CRLF_TERMINATOR_LDFLAG         4  -- Use CR,LF as a terminator
   #define CTRLZ_TERMINATOR_LDFLAG        8  -- Use EOF as a terminator
   #define NULL_TERMINATOR_LDFLAG        16  -- Use NULL as a terminator
   #define TABEXP_LDFLAG                 32  -- Expand tabs when loading
   #define CRLFEOF_TERMINATOR_LDFLAG     64  -- Use CR,LF,EOF as a terminator
   #define CRCRLF_TERMINATOR_LDFLAG     128  -- Use CR,CR,LF as a terminator
   #define NOHEADER_LDFLAG              256  -- Buffer has no header
   #define NEW_BITS_LDFLAG              512  -- Format flag is using these bits
   #define STRIP_SPACES_LDFLAG         1024  -- Strip trailing spaces when loading
   #define IGNORE_STORED_FORMAT_LDFLAG 2048  -- Don't use format flags saved in buffer header
   #define FORCE_TERMINATOR_LDFLAG     4096  -- Require a terminator after every line
compile if not defined(REFLOW_AFTER_PASTE)
   const REFLOW_AFTER_PASTE = 0
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Copy2SharBuff -                                                            ³
³                 Copy Marked area to EPM shared buffer                      ³
³                                                                            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc Copy2SharBuff                     /* former name = CLIPBRD_pt          */
   if not marktype() then              /* check if mark exists              */
      return                           /* if mark doesn't exist, return     */
   endif
                                       /* save the dimensions of the mark   */
   getmarkg fstline,                   /* returned:  first line of mark     */
           lstline,                    /* returned:  last  line of mark     */
           fstcol,                     /* returned:  first column of mark   */
           lstcol,                     /* returned:  last  column of mark   */
           mkfileid                    /* returned:  file id of marked file */

   getfileid fileid                    /* save file id of visible file      */
   activatefile mkfileid               /* switch to file with mark          */
   /* Try to open the buffer.  If it doesn't exist, create it.              */
   bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
   if bufhndl then
      opened = 1
   else
      -- Make a 64K buffer... memory's plentiful.  Easily changed.
      bufsize = MAXBUFSIZE
      bufhndl = buffer(CREATEBUF, EPMSHAREDBUFFER, bufsize)
      opened = 0
   endif
   if not bufhndl then
      sayerror CAN_NOT_OPEN__MSG EPMSHAREDBUFFER '-' ERROR_NUMBER__MSG RC
      stop
   endif

   /* Copy the current marked lines (up to 64k worth of data ) into EPM's */
   /* shared memory buffer.                                               */
   call buffer(PUTMARKBUF, bufhndl, fstline, lstline, APPENDCR+APPENDLF)  -- Was +FINALNULL+STRIPSPACES

   poke bufhndl, 28, atol(lstline-fstline+1-(lstline>.last))  -- Remember how many lines are *supposed* to be there.

   activatefile fileid
   if opened then
      call buffer(FREEBUF, bufhndl)
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ GetSharBuff -                                                              ³
³                 Get text from EPM shared buffer.                           ³
³                 'O' means Overlay instead of copy.                         ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc GetSharBuff            /* former name = CLIPBRD_gt                 */
   /* EPMSHAREDBUFFER= buffer name known between edit windows           */
   -- Try to open the buffer.  If it doesn't exist, nothing to get.
   bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
   if not bufhndl then
      sayerror CAN_NOT_OPEN__MSG EPMSHAREDBUFFER '-' ERROR_NUMBER__MSG RC
      stop
   endif
   call psave_pos(save_pos)
   call GetBuffCommon(bufhndl, NO_MARK_NO_BUFF__MSG, arg(1))
   call buffer(FREEBUF, bufhndl)
   call prestore_pos(save_pos)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ ClearSharBuff -                                                            ³
³                 Flush out stuff in  EPM shared buffer                      ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc ClearSharBuff
   bufhndl=buffer(OPENBUF, EPMSHAREDBUFFER)
   if bufhndl then
      call buffer(CLEARBUF, bufhndl)
      call buffer(FREEBUF, bufhndl)
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ copy2clip                                                                  ³
³       copy marked text into the PM clipboard.                              ³
³                                                                            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc copy2clip
   call checkmark()                          /* Make sure there's a mark. */

   'Copy2SharBuff'   -- Recopy the marked area to the shared buffer,
                     -- in case the user has modified the mark contents.

   /* Try to open the buffer.  If it doesn't exist, then we can't copy   */
   bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
   if not bufhndl then
      return 1                              /* buffer does not exist     */
   endif
   if peek(bufhndl,6,2) /== peek(bufhndl,28,2) then
      sayerror TOO_MUCH_FOR_CLIPBD__MSG
      return 1
   endif

--  Copying to the Clipboard using the EToolkit message:
--  EPM_EDIT_CLIPBOARDCOPY -  mp1 = pointer to memory buffer containing
--                                  contents to copy to the clipboard.
--                            mp2 = flag that describes what type of buffer
--                                  was passed in mp1.
--                                  0=CF_TEXT type buffer, terminated by nul
--                                  1=EPM shared memory buffer (32byte head)
--  When the contents of mp1 is copied to the clipboard a EPM defc event is
--  called by the name of PROCESSCLIPBOARDCOPY.  Arg(1) of this function is
--  the original buffer passed in as mp1.  The caller may choose to free
--  the buffer during this command.    if zero is passed as arg(1), an error
--  was encountered.  An error message should be displayed at this point.

   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5441,               -- EPM_EDIT_CLIPBOARDCOPY
                      mpfrom2short( bufhndl, 0),
                      1)

defc processclipboardcopy
   result=arg(1)
   if result then      -- If non-zero, free the buffer.
      call buffer(FREEBUF, itoa(substr(atol(result),3,2),10))  -- pass just the selector
   endif


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ cut                                                                        ³
³       copy marked text into the PM clipboard, then delete the mark.        ³
³                                                                            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc cut
   'copy2clip'
   if not RC then
      getmark firstline,lastline,firstcol,lastcol,markfileid
      markfileid.line = firstline
      if leftstr(marktype(), 1)<>'L' then
         markfileid.col = firstcol
      endif
      call pdelete_mark()
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ paste                                                                   ³
³                                                                         ³
³    retrieve text from PM clipboard to edit window                       ³
³                                                                         ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc paste
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
   arg1 = upcase(arg(1))
   if .readonly then
      sayerror READ_ONLY__MSG
      return
   endif
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   if not .line & (arg1='C' | arg1='B') then
      if .last then  -- Can't paste into line 0
         sayerror -281  -- "Source destination conflict"
         return
      endif
      insert         -- If file is empty, insert a blank line & paste there.
      begin_line
   endif
--  Pasting from the PM Clipboard using the EToolkit message:
--  EPM_EDIT_CLIPBOARDPASTE-  mp1 = flag that describes the type of paste
--                                  that is desired.  A paste could be of
--                            the following types; 'C' for Character, 'B' for
--                            block and 'L' for line.
--  During the processing of this message the text in the PM clipboard is
--  queried.  Once this is done an EPM defc event is
--  called by the name of PROCESSCLIPBOARDPASTE.  Arg(1) of this function
--  contains a pointer to a buffer containing a copy of the text found in
--  the PM clipboard.   Arg(2) of this function is
--  the original flag passed in as mp1.  The caller may choose to free
--  the buffer during this command.    if zero is passed as arg(1), an error
--  was encountered.  An error message should be displayed at this point.
   mark=upcase(arg(1))
   if mark<>'C' and  mark<>'B' then
      mark='L'
   endif
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5442,               -- EPM_EDIT_CLIPBOARDPASTE
                      asc(mark), 0)

defc processclipboardpaste
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif

   parse arg result mark .
   if not result then
      sayerror CLIPBOARD_ERROR__MSG
      return
   endif

   if mark=67 | mark=66 then  -- asc('C') | asc('B')
 compile if REFLOW_AFTER_PASTE
   start_line = .line
   start_linetext = textline(.line)
   start_col = .col + 1
 compile endif
      poke result, 8, chr(68-mark)              -- 'C'->1; 'B'->2; mark as a character or block buffer
 compile if WANT_CUA_MARKING
      if mark=67 &
  compile if WANT_CUA_MARKING = 'SWITCH'
         CUA_marking_switch &
  compile endif
         marktype()
      then
         getmark x, x, x, x, mark_fid
         getfileid cur_fid
         if mark_fid=cur_fid then
            call pbegin_mark()
            call pdelete_mark()
         else
            unmark
            sayerror MARKED_OTHER__MSG
         endif
         'ClearSharBuff'       /* Remove content in EPM shared text buffer */
      endif
 compile endif
      call psave_mark(savemark)                        -- Save the user's mark
      call GetBuffCommon(result, NOTHING_TO_PASTE__MSG, chr(mark))
      -- Two cases join here, in the middle of this IF statement.
      call prestore_mark(savemark)                     -- Restore the user's mark
   else
      oldsize = .last
 compile if REFLOW_AFTER_PASTE
      start_line = .line + 1
      start_linetext = textline(.line)
      start_col = 1
 compile endif
      call buffer(GETBUF2, result, 1, 0,
                  CR_TERMINATOR_LDFLAG + LF_TERMINATOR_LDFLAG + CRLF_TERMINATOR_LDFLAG +
                  CRCRLF_TERMINATOR_LDFLAG + NEW_BITS_LDFLAG + FORCE_TERMINATOR_LDFLAG)
      if textline(.line+.last-oldsize)=='' then
         deleteline .line+.last-oldsize
      endif
      '+'(.last-oldsize)
   endif
compile if REFLOW_AFTER_PASTE
   parse value .margins with . rm .
   if rm < MAXMARGIN then
 compile if REFLOW_AFTER_PASTE = 'WIDER' | REFLOW_AFTER_PASTE = 'PROMPT_IF_WIDE'
    must_reflow = FALSE
    do i=start_line to .line
      if length(textline(i))>rm then
         must_reflow = TRUE
         leave
      endif
    enddo
    if must_reflow then
  compile if REFLOW_AFTER_PASTE = 'PROMPT_IF_WIDE'
     refresh
   compile if defined(ULTIMAIL_DLG_TITLE)
     if MBID_YES=winmessagebox(ULTIMAIL_DLG_TITLE,
   compile else
     if MBID_YES=winmessagebox('',
   compile endif
                               WIDE_PASTE__MSG,
                               MB_YESNO + MB_QUERY + MB_DEFBUTTON2 + MB_MOVEABLE)
     then
  compile endif
 compile endif
      call psave_mark(savemark)        -- Save the user's mark
;     call psave_pos(savepos)          -- We should now be at the end of the insertion.
      to_end = .last - .line           -- Remember how far from end, because # lines
                                       -- from start will change as we reflow.
      insert_attribute 13, 0, 2, 0, start_col, start_line  -- Place a bookmark on the char. after the pasted text
      cur_line = start_line
      stopit = 0
      do forever
         unmark
         cur_line                      -- Go to first pasted line
         do while textline(.line)=''   -- Skip blank lines
            if .line=.last then stopit=1; leave; endif
            down
         enddo
         if stopit then leave; endif   -- If no non-blank, nothing to do.
         mark_line
         cur_line = .line
         call pfind_blank_line()
         if .line<>cur_line then       -- Stop at line before next blank line
            up
         else                          -- No blank lines?  Go to bottom.
            bottom
         endif
         if start_linetext='' then  -- Pasted onto a blank line?
            if .last-.line < to_end then
               if .last - to_end < cur_line then
                  leave
               endif
               .line = .last - to_end
            endif
         endif
         mark_line
         reflow
         getmark firstmarkline, lastmarkline
         if lastmarkline = .last | .last - lastmarkline <= to_end then
            leave
         else
            cur_line = lastmarkline + 1
         endif
      enddo
      class = 13  -- BOOKMARK_CLASS
      col=start_col; line=start_line; offst=0
      attribute_action 1, class, offst, col, line  -- 1=FIND NEXT ATTR
      if class=13 then
         query_attribute class, val, IsPush, offst, col, line
         line; .col=col
         attribute_action 16, class, offst, col, line -- 16=Delete attribute
      endif
      call prestore_mark(savemark)                     -- Restore the user's mark
 compile if REFLOW_AFTER_PASTE = 'WIDER' | REFLOW_AFTER_PASTE = 'PROMPT_IF_WIDE'
  compile if REFLOW_AFTER_PASTE = 'PROMPT_IF_WIDE'
     endif -- MBID_YES
  compile endif
    endif  -- must_reflow
 compile endif
   endif  -- rm < MAXMARGIN
compile endif  -- REFLOW_AFTER_PASTE

   call dynalink32('DOSCALLS',        /* dynamic link library name         */
                   '#304',             /* DosFreeSeg                        */
                   ltoa(atoi(0) || atoi(result), 10))

compile if WANT_DM_BUFFER
definit
   universal DMbuf_handle
   DMbuf_handle = 0

defexit
   universal DMbuf_handle
   if DMbuf_handle then
      call buffer(FREEBUF, DMbuf_handle)              -- Free the OPEN
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Copy2DMBuff -                                                              ³
³                 Copy Marked area to "Delete Mark" buffer                   ³
³                                                                            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc Copy2DMBuff
   universal DMbuf_handle
   themarktype = marktype()
   if not themarktype then             /* check if mark exists              */
      return                           /* if mark doesn't exist, return     */
   endif
                                       /* save the dimensions of the mark   */
   getmark fstline,                    /* returned:  first line of mark     */
           lstline,                    /* returned:  last  line of mark     */
           fstcol,                     /* returned:  first column of mark   */
           lstcol,                     /* returned:  last  column of mark   */
           mkfileid                    /* returned:  file id of marked file */

   if themarktype='BLOCK' then  -- Size of block, + 2 per line for CR, LF
      size=(lstcol-fstcol+3) * (lstline-fstline+1) + 3
   else                       -- Probably much larger than we need, but must assume:
      size=(MAXCOL+2) * (lstline-fstline+1) +3  -- 255 chars/line + CR, LF
   endif
   /* Try to open the buffer.  If it doesn't exist or is too small, create it. */
   if not DMbuf_handle then
      DMbuf_handle = buffer(OPENBUF, EPMDMBUFFER)
      if DMbuf_handle then
         call buffer(FREEBUF, DMbuf_handle)              -- Free the OPEN
      endif
   endif
   if DMbuf_handle then
      maxsize  = buffer(MAXSIZEBUF,DMbuf_handle)
      if size > maxsize & maxsize < MAXBUFSIZE then
         success=buffer(FREEBUF, DMbuf_handle)        -- Free the original CREATE
         if not success then
            sayerror ERROR__MSG rc TRYING_TO_FREE__MSG EPMDMBUFFER BUFFER__MSG
         endif
         DMbuf_handle = ''
      endif
   endif
   if not DMbuf_handle then
      DMbuf_handle = buffer(CREATEBUF, EPMDMBUFFER, min(size,MAXBUFSIZE), 1)
   endif
   if not DMbuf_handle then
      messageNwait(CAN_NOT_OPEN__MSG EPMDMBUFFER '-' ERROR_NUMBER__MSG RC)
      return
   endif

   getfileid fileid                    /* save file id of visible file      */
   activatefile mkfileid               /* switch to file with mark          */
   /* Copy the current marked lines (up to 64k worth of data ) into EPM's */
   /* shared memory buffer.                                               */
   call buffer(PUTMARKBUF, DMbuf_handle, fstline, lstline, APPENDCR+APPENDLF)

   poke DMbuf_handle, 28, atol(lstline-fstline+1)  -- Remember how many lines are *supposed* to be there.

   activatefile fileid


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ GetDMBuff -                                                                ³
³                 Get text from "Delete Mark" buffer.                        ³
³                                                                            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc GetDMBuff
   universal DMbuf_handle
   -- Try to open the buffer.  If it doesn't exist, nothing to get.
;; DMbuf_handle = buffer(OPENBUF, EPMDMBUFFER)
;; -- (If it doesn't exist in this window, the lines were deleted from some other window.)
   if not DMbuf_handle then
;;    sayerror 'Unable to open a buffer named' EPMDMBUFFER'.  Error number 'RC
      sayerror NO_MARK_DELETED__MSG
      return
   endif
   call psave_mark(savemark)                              -- Save the user's mark
   call GetBuffCommon(DMbuf_handle, NO_TEXT_RECOVERED__MSG)  -- (This marks what's recovered)
   call prestore_mark(savemark)                           -- Restore the user's mark
compile endif  -- WANT_DM_BUFFER


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ GetBuffCommon                                                              ³
³                 Common code called by GetSharBuff, Paste and GetDMBuff     ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc GetBuffCommon(bufhndl, errormsg)
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
   markt = buffer(MARKTYPEBUF, bufhndl)
   getfileid activefid                  -- get current files file id
   if not markt & arg(3)<>'O' then      -- MARKT=0 ==> line mark (simple case)
      noflines = buffer(GETBUF, bufhndl)   -- Retrieve data from shared EPM buf
      if noflines then
         call pset_mark(.line+1,.line+noflines,1,MAXCOL,'LINE',activefid)
         '+'noflines
         call verify_buffer_size(bufhndl, noflines)
      else
         sayerror errormsg
      endif
      return                            -- ... and that's all.
   endif

   cur_line_len = length(textline(.line))
   'xcom e /q /c epmbuff.cpy'           -- edit a temp hidden file
   .visible=0                           -- (hide file)
   getfileid tmpfileid                  -- get hidden file's id

   noflines = buffer(GETBUF2, bufhndl, 1, 0,
                     CR_TERMINATOR_LDFLAG + LF_TERMINATOR_LDFLAG + CRLF_TERMINATOR_LDFLAG +
                     CRCRLF_TERMINATOR_LDFLAG + NEW_BITS_LDFLAG + FORCE_TERMINATOR_LDFLAG)
   if not noflines then
      'xcom quit'
      sayerror errormsg
      return
   endif

   orig_lines = ltoa(peek(bufhndl,28,4),10)
;  sayerror 'orig_lines='orig_lines 'noflines='noflines 'markt='markt '.last='.last 'textline(.last)="'textline(.last)'"'
   if (not orig_lines | orig_lines = noflines-1) & markt = 2 & textline(.last)=='' then  -- Block mark?  Get rid of extra blank line
      noflines = noflines-1
      deleteline .last
   endif
   length_last = length(textline(.last))
   split_start = 0; split_end = 0
   '+1'                              -- advance to next line in hidden
   if markt=2 | markt=4 then            -- Mark type is BLOCK(G)
      markblock                         -- block mark first character
      noflines+1                        -- advance down to last line
      if arg(3)='B' then                -- Block-marking from clipboard;
         .col=longestline()             -- move cursor to end of longest line
      else                              -- Was originally a block; width is OK.
         .col=length_last               -- move to last character
      endif
      markblock                         -- complete block mark
   elseif markt=1 | markt=3 then        -- Mark type is Character(G)
      split_start = activefid.col + length(textline(2)) > MAXCOL
      split_end = cur_line_len - activefid.col + length_last > MAXCOL
      setmark 2, .last, 1, length_last+1, 3, tmpfileid  -- 3 = CHARG mark
   else
      mark_line                         -- line mark first line
      noflines+1                        -- advance down to last
      mark_line                         -- complete line mark
   endif

   activatefile activefid               -- activate destination file
   rc=0                                 -- clear return code before copy
   if arg(3)='O' then
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('O')  -- copy mark
compile else
      overlay_block
compile endif
   else
      if split_end then split; endif
      if split_start then split; '+1'; begin_line; endif
      call pcopy_mark()                 -- copy mark
   endif
   if rc then                           -- Test for memory too full for copy_mark.
      display -4
      sayerror ERROR_COPYING__MSG
      display 4
   endif

   activatefile tmpfileid               -- activate temp file
   'xcom q'                             -- quit it
   activatefile activefid               -- activate destination file
   call pend_mark()
;  sayerror 'length_last='length_last'; .col='.col'; cl1, cl2 =' cl1 cl2
   if length_last then  -- Move right by 'executekey right', to handle stream mode.
 compile if WANT_CUA_MARKING = 'SWITCH'
      save_CUA = CUA_marking_switch
      CUA_marking_switch = 0
 compile endif
 compile if WANT_CUA_MARKING  -- Turn off CUA marking, so moving right won't unmark.
      'togglecontrol 25 0'
 compile endif
      executekey right           -- This is all we really want to do...
 compile if WANT_CUA_MARKING = 'SWITCH'
      CUA_marking_switch = save_CUA
      'togglecontrol 25' CUA_marking_switch
 compile elseif WANT_CUA_MARKING
      'togglecontrol 25 1'
 compile endif
   endif
   call verify_buffer_size(bufhndl, noflines)

defproc verify_buffer_size(bufhndl, noflines)
   orig_lines = ltoa(peek(bufhndl,28,4),10)
   if orig_lines <> noflines & orig_lines then  -- If 0, assume never set.
      display -4
      sayerror ONLY__MSG noflines LINES_OF__MSG orig_lines RECOVERED__MSG
      display 4
   endif

defc clipview =
   if not clipcheck(format) then
      sayerror CLIPBOARD_ERROR__MSG
      return
   endif
   --if format<>256 then                 -- no text in clipboard
   if format<>1024 then                 -- no text in clipboard
      sayerror CLIPBOARD_EMPTY__MSG
      return
   endif
   "open 'paste C' 'postme clipview2'"

defc clipview2 =
   if .filename=UNNAMED_FILE_NAME then
      .filename=CLIPBOARD_VIEW_NAME
      .autosave = 0
      .modify = 0
      .readonly = 1
   endif

defproc clipcheck(var format)  -- Returns error code; if OK, sets FORMAT
   hab=gethwndc(0)                         -- get EPM's anchorblock
   format = \0\0\0\0                       -- (reserve four bytes)
   rc=dynalink32('PMWIN',                   -- call PM function to
                 '#807',   -- look at the data in the cb
                 hab              ||         -- anchor block
                 atol(1)          ||         -- data format ( TEXT )
                 address(format), 4)
--   format = ltoa(format,10)                -- Convert format to ASCII
   format = 1024
   return rc

defc insert_text_file
   universal default_edit_options
   get_file = strip(arg(1))
   if get_file='' then sayerror NO_FILENAME__MSG 'GET'; return; endif
   if pos(argsep,get_file) then
      sayerror INVALID_OPTION__MSG
      return
   endif
   getfileid fileid
   s_last=.last
   display -1
   'e /q /d' get_file
   editrc=rc
   getfileid gfileid
   if editrc = -282 | not .last then  -- -282 = sayerror('New file')
      'q'
      display 1
      if editrc= -282 then
         sayerror FILE_NOT_FOUND__MSG':  'get_file
      else
         sayerror FILE_IS_EMPTY__MSG':  'get_file
      endif
      return
   endif
   if editrc & editrc<>-278 then  -- -278  sayerror('Lines truncated') then
      display 1
      sayerror editrc
      stop
   endif
   call psave_mark(save_mark)
 compile if WANT_BOOKMARKS
   if not .levelofattributesupport then
      'loadattributes'
   endif
 compile endif
   get_file_attrib = .levelofattributesupport
   if rightstr(textline(.last), 1) = \26 then  -- Ends with EOF?
      incr = 0
   else
      incr = 1
   endif
   setmark 1, .last, 1, length(textline(.last))+incr, 3, gfileid  -- 3 = CHARG mark
   activatefile fileid
   if not .last then
      insert
      .col = 1
   elseif .line = .last then
      xxx = .mousex
      yyy = .mousey
      map_point 5, xxx, yyy, off, comment;  -- map screen to line
      if xxx > .last then  -- Dropped below bottom of file; append to end.
         insert
         .col = 1
      endif
   endif
   rc=0
   copy_mark
   copy_rc=rc           -- Test for memory too full for copy_mark.
   activatefile gfileid
   'q'
   parse value save_mark with s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt
   if fileid=s_mkfileid then           -- May have to move the mark.
      diff=fileid.last-s_last          -- (Adjustment for difference in size)
      if fileid.line<s_firstline then s_firstline=s_firstline+diff; endif
      if fileid.line<s_lastline then s_lastline=s_lastline+diff; endif
   endif
   call prestore_mark(s_firstline s_lastline s_firstcol s_lastcol s_mkfileid s_mt)
   activatefile fileid
   if get_file_attrib // 2 then
      call attribute_on(1)  -- Colors flag
   endif
   if get_file_attrib bitand 4 then
      call attribute_on(4)  -- Mixed fonts flag
   endif
   if get_file_attrib bitand 8 then
      call attribute_on(8)  -- "Save attributes" flag
   endif
   display 1
   if copy_rc & copy_rc<>-281 then
      sayerror NOT_2_COPIES__MSG get_file
   endif
