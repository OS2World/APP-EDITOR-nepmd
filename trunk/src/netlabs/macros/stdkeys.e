/****************************** Module Header *******************************
*
* Module Name: stdkeys.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdkeys.e,v 1.8 2002-10-19 12:20:32 aschn Exp $
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

definit
   universal blockreflowflag
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif
   blockreflowflag=0
compile if defined(HIGHLIGHT_COLOR)
   search_len = 5     -- Initialize to anything, to prevent possible "Invalid number argument"
compile endif

compile if    WANT_CUA_MARKING
defkeys edit_keys new clear

def otherkeys =
   k = lastkey()
   call process_key(k)

defproc process_key(k)
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
   if length(k)=1 & k<>\0 then
      i_s = insert_state()
compile if WANT_CUA_MARKING = 'SWITCH'
      if CUA_marking_switch then
compile endif
         had_mark = process_mark_like_cua()
         if not i_s & had_mark then
            insert_toggle  -- Turn on insert mode because the key should replace
         endif             -- the mark, not the character after the mark.
compile if WANT_CUA_MARKING = 'SWITCH'
      else
         had_mark = 0  -- set to 0 so we don't toggle insert state later
      endif
compile endif
      keyin k
      if not i_s & had_mark then
         insert_toggle
      endif
   endif

defproc process_mark_like_cua()
   if marktype() then
      getmark firstline,lastline,firstcol,lastcol,markfileid
      getfileid fileid
      if fileid<>markfileid then
         sayerror MARKED_OTHER__MSG
         unmark
      elseif not check_mark_on_screen() then
         sayerror MARKED_OFFSCREEN__MSG
         unmark
      else
compile if WANT_DM_BUFFER
         'Copy2DMBuff'     -- see clipbrd.e for details
compile endif  -- WANT_DM_BUFFER
         firstline; .col=firstcol
         undoaction 1, junk                -- Create a new state
         call pdelete_mark()
         'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
         return 1
      endif
   endif
compile else  -- WANT_CUA_MARKING
defkeys edit_keys new
compile endif  -- WANT_CUA_MARKING

compile if WANT_SHIFT_MARKING
defproc shifted
   ks = getkeystate(VK_SHIFT)
   return ks<>3 & ks<>4

define CHARG_MARK = 'CHARG'

defproc extend_mark(startline, startcol, forward)
;compile if WANT_CUA_MARKING = 'SWITCH'
;  universal CUA_marking_switch
;  if not CUA_marking_switch then return; endif
;compile endif
   if marktype()='LINE' | marktype()='BLOCK' then return; endif
   getfileid curfileid
   if not marktype() then
      call pset_mark(startline, .line, startcol, .col, CHARG_MARK, curfileid)
      return
   endif
   getmarkg firstline,lastline,firstcol,lastcol,markfileid
   if markfileid<>curfileid then  -- If mark was in a different file, treat like no mark was set.
      call pset_mark(startline, .line, startcol, .col, CHARG_MARK, curfileid)
      return
   endif
   lk = lastkey(0)
   if (lk=s_up & .line=firstline-1) | (lk=s_down & .line=firstline+1) then
      if length(textline(firstline)) < .col then
         firstcol = .col
      endif
   endif
   if startline>firstline | ((startline=firstline) & (startcol > firstcol)) then  -- at end of mark
      if not forward then
         if firstline=.line & firstcol=.col then unmark; return; endif
      endif
      call pset_mark(firstline, .line, firstcol, .col, CHARG_MARK, curfileid)
   else                                                         -- at beginning of mark
      if forward then
         if lastline=.line & lastcol=.col-1 then unmark; return; endif
      endif
      call pset_mark(lastline, .line, lastcol, .col, CHARG_MARK, curfileid)
   endif

; c_home, c_end, c_left & c_right do different things if the shift key is depressed.
; The logic is extracted here mainly due to the complexity of the COMPILE IF's
defproc begin_shift(var startline, var startcol, var shift_flag)
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
   shift_flag = shifted()
 compile if WANT_CUA_MARKING = 'SWITCH'
   if shift_flag or not CUA_marking_switch then
 compile else
   if shift_flag then
 compile endif
      startline = .line; startcol = .col
 compile if WANT_CUA_MARKING
   else
      unmark
 compile endif
   endif

defproc end_shift(startline, startcol, shift_flag, forward_flag)
; Let's let this work regardless of which marking mode is active.
 compile if 0 -- WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if shift_flag & CUA_marking_switch then
 compile else
   if shift_flag then
 compile endif
      call extend_mark(startline, startcol, forward_flag)
   endif
compile endif  -- WANT_SHIFT_MARKING

; Real keys, in alphabetical order.
; See end of this file for a list of keys unused in standard E.

def a_0=    /* same as Alt-Equal, for sake of German keyboards */
   'dolines'

; We now distribute a standard front end for the DIR command, which redirects
; the output to a file named ".dos dir <dirspec>".  The third line should be
; "Directory of <dirname>".  If so, we use it.  If not, we use DIRSPEC from the
; .filename instead, but note that the latter might contain wildcards.
define
   QUOTED_DIR_STRING ='"'DIRECTORYOF_STRING'"'

def a_1= /* edit filename on current text line */
   getline line
compile if WANT_EPM_SHELL
   if leftstr(.filename, 15) = ".command_shell_" then
      if substr(line, 13, 1) = ' ' then  -- old format DIR, or not a DIR line
         flag = substr(line, 1, 1) <> ' ' &
                (isnum(substr(line, 14, 8)) | substr(line, 14, 8)='<DIR>') &
                length(line) < 40 &
                isnum(substr(line, 24, 2) || substr(line, 27, 2) || substr(line, 30, 2)) &
                substr(line, 26, 1) = substr(line, 29, 1) &
                pos(substr(line, 26, 1), '/x.-')
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif
      else                               -- new format DIR, or not a DIR line
         flag = substr(line, 41, 1) <> ' ' &
                (isnum(substr(line, 18, 9)) | substr(line, 18, 9)='<DIR>') &
                isnum(substr(line, 1, 2) || substr(line, 4, 2) || substr(line, 7, 2)) &
                substr(line, 3, 1) = substr(line, 6, 1) &
                pos(substr(line, 3, 1), '/x.-')
         filename=substr(line,41)
         if substr(line, 39, 1)=' ' & substr(line, 40, 1)<>' ' then  -- OS/2 2.11 is misaligned...
            filename=substr(line,40)
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
            parse value word3 with $QUOTED_DIR_STRING word3
;;          parse value word3 with . . word3 .
            if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
               word3 = substr(word3, 1, lastpos(word3, '\')-1)
            endif
            word3 = strip(word3)
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
compile endif  -- WANT_EPM_SHELL
   parse value .filename with word1 word2 word3 .
   if upcase(word1 word2) = '.DOS DIR' then
      call psave_pos(save_pos)
      getsearch oldsearch
      'xcom l /'DIRECTORYOF_STRING'/c-'
      if not rc then
         getline word3
         parse value word3 with $QUOTED_DIR_STRING word3
;        parse value word3 with . . word3 .
         if verify(word3,'?*','M') then  -- If wildcards - must be 4OS2 or similar shell
            word3 = substr(word3, 1, lastpos(word3, '\')-1)
         endif
         word3 = strip(word3)
      endif
      setsearch oldsearch
      call prestore_pos(save_pos)
      filename=substr(line,41)                 -- Support HPFS.  FAT dir's end at 40
      if substr(line, 39, 1)=' ' & substr(line, 40, 1)<>' ' then  -- OS/2 2.11 is misaligned...
         filename=substr(line,40)
      endif
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
         'e 'name
      endif
compile if WANT_TREE
   elseif .filename = '.tree' then
      if substr(line,5,1)substr(line,8,1)substr(line,15,1)substr(line,18,1) = '--::' then
         name = substr(line, 52)
         if substr(line,31,1)='>' then
;           if isadefc('tree_dir') then
               'tree_dir "'name'\*.*"'
;           else
;              'dir' name
;           endif
         else
            'e "'name'"'
         endif
      endif
compile endif  -- WANT_TREE
   else  -- Not a DIR or TREE listing
      parse value line with w1 rest
      p=lastpos('(', w1)
 compile if HOST_SUPPORT = 'EMUL' & defined(MVS)
  compile if MVS
      if p & rightstr(w1, 1)<>"'" then
  compile else
      if p then
  compile endif
 compile else
      if p then
 compile endif
         filename = substr(w1, 1, p-1)
         parse value substr(w1, p+1) with line ')'
         parse value line with line ':' col
         if pos('*', filename) then
            if YES_CHAR<>askyesno(WILDCARD_WARNING__MSG, '', filename) then
               return
            endif
         endif
         'e 'filename
         line
         if col<>'' then .col = col; endif
      else
         if pos('*', line) then
            if YES_CHAR<>askyesno(WILDCARD_WARNING__MSG, '', line) then
               return
            endif
         endif
         'e 'line
      endif  -- p
   endif  -- upcase(word1 word2) = '.DOS DIR'

def a_a=
compile if WANT_CHAR_OPS
   call pcommon_adjust_overlay('A')
compile else
   adjustblock
compile endif

def a_b
   markblock
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

def a_c=
   if marktype() then
      call pcopy_mark()
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff'     /* see clipbrd.e for details                 */
   endif

def a_d=
compile if WANT_DM_BUFFER
   'Copy2DMBuff'     -- see clipbrd.e for details
compile endif
   call pdelete_mark()
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */

def a_e=
   call pend_mark()
   if substr(marktype(),1,1)<>'L' then
      right
   endif

def a_equal=
   'dolines'   -- Code is a separate command in STDCMDS.E.

def a_f= /* Now accepts key from macro. */
   call checkmark()
   call pfill_mark()

def a_f1= keyin 'º Ì É È Ê Í Ë ¼ » ¹ Î ³ Ã Ú À Á Ä Â Ù ¿ ´ Å Û ² ± °'

def a_f7,c_F7=   -- Can't use the old A_F7 in EPM.  PM uses it as an accelerator key.
   shift_left
compile if SHIFT_BLOCK_ONLY
   if marktype()='BLOCK' then  -- code by Bob Langer
      getmark fl,ll,fc,lc,fid
      call pset_mark(fl,ll,lc,MAXCOL,'BLOCK',fid)
      shift_right
      call pset_mark(fl,ll,fc,lc,'BLOCK',fid)
   endif
compile endif

def a_f8,c_F8=   -- Can't use the old A_F8 in EPM.  PM uses it as an accelerator key.
compile if SHIFT_BLOCK_ONLY
   if marktype()='BLOCK' then  -- code by Bob Langer
      getmark fl,ll,fc,lc,fid
      call pset_mark(fl,ll,lc,MAXCOL,'BLOCK',fid)
      shift_left
      call pset_mark(fl,ll,fc,lc,'BLOCK',fid)
   endif
compile endif
   shift_right

/* We can't use a_f10 for previous file any more, PM uses that key. */
/* I like F11 and F12 to go back and forth.                         */
def a_f10,F11,c_P=  -- a_F10 is usual E default; F11 for enh. kbd, c_P for EPM.
   prevfile

; def a_F11 = 'prevview'
def a_F12 = 'nextview'

def a_j=
   call joinlines()

def a_l=
   mark_line
   'Copy2SharBuff'       /* Copy mark to shared text buffer */

def a_m=call pmove_mark()
compile if UNMARK_AFTER_MOVE
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
compile endif

def a_minus =
   circleit 5, .line, .col-1, .col+1, 16777220

def a_n=  /* Type the full name of the current file. */
  keyin .filename

def a_o=
   if marktype() then
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('O')
compile else
      overlay_block
compile endif
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff O'   /* see clipbrd.e for details                 */
   endif

def a_p=
   /* Protect the user from accidentally reflowing a marked  */
   /* area not in the current file, and give a good message. */
   mt = substr(marktype(), 1, 1)
   if mt='B' or mt='L' then
      getmark firstline,lastline,firstcol,lastcol,markfileid
      getfileid fileid
      if fileid<>markfileid then
         sayerror CANT_REFLOW__MSG'  'OTHER_FILE_MARKED__MSG
         return
      endif
   endif

   if mt<>' ' then
      if not check_mark_on_screen() then
         sayerror MARK_OFF_SCREEN__MSG
         stop
      endif
   endif

   if mt='B' then
      'box r'
   elseif mt='C' then
      sayerror WRONG_MARK__MSG
   elseif mt='L' then
      reflow
   else  -- Standard text reflow split into a separate routine.
      call text_reflow()
   endif

definit                         -- Variable is null if alt_R is not active.
   universal alt_R_active       -- For E3/EOS2, it's 1 if alt_R is active.
   alt_R_active = ''            -- For EPM, it's set to querycontrol(messageline).

def a_r=
   universal alt_R_active,tempofid
   universal alt_R_space

   if alt_R_active<>'' then
      call pblock_reflow(1,alt_R_space,tempofid)     -- Complete the reflow.
      'setmessageline '\0
      'toggleframe 2 'alt_R_active           -- Restore status of messageline.
      alt_R_active = ''
      return
   endif
   if pblock_reflow(0,alt_R_space,tempofid) then
      sayerror PBLOCK_ERROR__MSG      /* HurleyJ */
      return
   endif
;  if marktype() <> 'BLOCK' then
      unmark
;  endif
   alt_R_active = queryframecontrol(2)         -- Remember if messageline on or off
   'toggleframe 2 1'                    -- Force it on
   'setmessageline' BLOCK_REFLOW__MSG

def a_s=
   call splitlines()

def a_t = call pcenter_mark()

def a_u=
   unmark
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */

def a_w = call pmark_word()

;  EPM:  Haven't yet figured out a way to do Alt-X=escape.  It used a getkey().

def a_y= call pbegin_mark()

compile if WANT_CHAR_OPS
def a_z=mark_char
   'Copy2SharBuff'       /* Copy mark to shared text buffer */
compile endif

def backspace, s_backspace =
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
compile endif
compile if WANT_CUA_MARKING
   if process_mark_like_cua() then return; endif
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   endif
compile endif
compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if .col=1 & .line>1 & stream_mode then
 compile else
   if .col=1 & .line>1 then
 compile endif
      up
      l=length(textline(.line))
      join
      .col=l+1
   else
compile endif
      old_level = .levelofattributesupport
      if old_level & not (old_level bitand 2) then
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = -300
      endif
      rubout
      .levelofattributesupport = old_level
compile if WANT_STREAM_MODE
   endif
compile endif

def c_2 = keyin \0                  -- C_2 enters a null.
def c_6 = keyin \170                -- C_6 enters a "not" sign
def c_9 = keyin '{'
def c_0 = keyin '}'
def c_4 = keyin '›'                 -- C_4 enters a cents sign

;def c_a= 'newtop'     -- Move current line to top of window.
def c_a= 'select_all'  -- new

compile if WANT_BOOKMARKS
def c_B = 'listmark'
compile endif

def c_backspace=
   undoaction 1, junk                -- Create a new state
   if .levelofattributesupport then
      if (.line==.last and .line<>1) then       -- this is the last line
         destinationLine=.line-1                -- and there is a previous line to store attributes on
         getline prevline,DestinationLine
         DestinationCol=length(prevline)+1      -- start search parameters
                                                -- destination of attributes
         findoffset=-300                        -- start at the begin of the attr list
         findline=.line                         -- of the first char on this line
         findcolumn=1

         do forever        -- search until no more attr's (since this is last line)
            FINDCLASS=0          -- 0 is anyclass
            Attribute_action FIND_NEXT_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline<>.line) then  -- No attribute, or not on this line
               leave
            endif
            query_attribute theclass,thevalue, thepush, findoffset, findcolumn, findline   -- push or pop?
            if not thePush then       -- ..if its a pop attr and ..
               matchClass=theClass
               MatchOffset=FindOffset
               MatchLine=FindLine
               MatchColumn=FindColumn  -- ..and if its match is not on this line or at the destination
               Attribute_Action FIND_MATCH_ATTR_SUBOP, MatchClass, MatchOffset, Matchcolumn, MatchLine
               if ((Matchline==DestinationLine) and (Matchcolumn==destinationcol)) then
                  -- then there is a cancellation of attributes
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
                  Attribute_action Delete_ATTR_SUBOP, Matchclass, Matchoffset, Matchcolumn, Matchline
               elseif (MatchLine<>.line)  then
                  -- .. then move attribute to destination (before attributes which have been scanned so its OK.)
                  -- insert attr at the end of the attr list (offset=0)
                  Insert_Attribute theclass, thevalue, 0, 0, DestinationCol, DestinationLine
                  Attribute_action Delete_ATTR_SUBOP, theclass, Findoffset, Findcolumn, Findline
               endif -- end if attr is on line or at destination
            endif -- end if found attr is a pop
         enddo  -- end search for attr's
      elseif .line < .last then  -- put the attributes after the line since there may not
                                 -- be a line before this line (as when .line==1)
         DestinationCol=1
         DestinationLine=.line+1         -- error point since this puts attr's after last line if .line=.last
         findoffset=0                    -- cant make it .line-1 cause then present attributes there become
         findline=.line                  -- after these attributes which is wrong
         findcolumn=MAXCOL

         do forever
            FINDCLASS=0
            Attribute_action FIND_PREV_ATTR_SUBOP, findclass, findoffset, findcolumn, findline
            if not findclass or (findline<>.line) then  -- No attribute, or not on this line
               leave
            endif
             /* Move Attribute */
            query_attribute theclass,thevalue, thepush, findoffset, findcolumn, findline
            -- only move push/pop model attributes (tags are just deleted)
            if ((thepush==0) or (thepush==1)) then
               -- move attribute to destination, if cancellation delete both attributes
               FastMoveAttrToBeg(theclass, thevalue, thepush, DestinationCol, DestinationLine, findcolumn, findline, findoffset)
               findoffset=findoffset+1  -- since the attr rec was deleted and all attr rec's were shifted to fill the vacancy
                                        -- and search is exclusive
            endif
         enddo
      endif -- endif .line=.last and .line=1
   endif -- .levelofattributesupport
   delete
   undoaction 1, junk                -- Create a new state

def c_c=
  'c'    -- EPM c_c is used for change next

; Ctrl-D = word delete, thanks to Bill Brantley.
def c_d =  /* delete from cursor until beginning of next word, UNDOable */
   getline line
   begcur=.col
   lenLine=length(line)
   if lenLine >= begcur then
      for i = begcur to lenLine /* delete remainder of word */
         if substr(Line,i,1)<>' ' then
            deleteChar
         else
            leave
         endif
      endfor
      for j = i to lenLine /* delete delimiters following word */
         if substr(Line,j,1)==' ' then
            deleteChar
         else
            leave
         endif
      endfor
   endif

compile if    WANT_STACK_CMDS
def c_down =
   'pushpos'
compile endif

def c_e, c_del=erase_end_line  -- Ctrl-Del is the PM way.

compile if WANT_KEYWORD_HELP
def c_h = 'kwhelp'
compile endif

def c_end=
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode then
compile endif
compile if WANT_STREAM_MODE
      bottom; endline
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   else
compile endif
compile if WANT_STREAM_MODE <> 1
      if .line=.last and .line then endline; endif
      bottom
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   endif
compile endif
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

; Moved to ENTER.E
;def c_enter, c_pad_enter=

def c_f=
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif
   sayerror 0
   repeat_find       /* find next */
compile if defined(HIGHLIGHT_COLOR)
   call highlight_match(search_len)
compile endif

def c_f1=
   call psave_mark(save_mark)
   call pmark_word()
   call puppercase()
   call prestore_mark(save_mark)

def c_f2=
   call psave_mark(save_mark)
   call pmark_word()
   call plowercase()
   call prestore_mark(save_mark)

def c_f3= call puppercase()

def c_f4= call plowercase()

def c_f5=
   call pbegin_word()

def c_f6=
   call pend_word()

def c_g='ring_more'

def c_home=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   if stream_mode then
compile endif
compile if WANT_STREAM_MODE
      top; begin_line
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   else
compile endif
compile if WANT_STREAM_MODE <> 1
      if .line=1 then begin_line endif
      top
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   endif
compile endif
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

def c_k=      -- Duplicate a line
  getline line
  insertline line,.line+1

def c_l =
   if .line then
      getline line
      'commandline 'line
   endif

def c_left=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE
   if not .line then
      begin_line
 compile if WANT_STREAM_MODE = 'SWITCH'
   elseif .line>1 & .col=max(1,verify(textline(.line),' ')) & stream_mode then
 compile else
   elseif .line>1 & .col=max(1,verify(textline(.line),' ')) then
 compile endif
      up; end_line
   endif
compile endif
   backtab_word
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

compile if WANT_BOOKMARKS
def c_m = 'setmark'
compile else  -- [The following doesn't apply to EPM.]
; This C-M definition allows external cut-and-paste utilities to
; feed text into E via the keyboard stream.  Most such utilities end each line
; of text with ASCII character 13.  This definition is needed because E
; distinguishes that as a different key (Ctrl-M) than Enter.
def c_m =
   insert
compile endif

def c_pgup=
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
   .cursory=1
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

def c_pgdn=
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
   .cursory=.windowheight
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

def c_r
   -- Query to see if we are already in recording
   if windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                    5393,
                    0,
                    0)
   then
      call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                         5392,
                         0,
                         0)
      sayerror REMEMBERED__MSG
   else
      sayerror CTRL_R__MSG
      call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                         5390,
                         0,
                         0)
   endif

def c_right=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE
   getline line
 compile if WANT_STREAM_MODE = 'SWITCH'
   if not .line | lastpos(' ',line)<.col & .line<.last & stream_mode then
 compile else
   if not .line | lastpos(' ',line)<.col & .line<.last then
 compile endif
      down
      call pfirst_nonblank()
   else
compile endif
      tab_word
compile if WANT_STREAM_MODE
   endif
compile endif
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

-- Pop up Search dialog
def c_s=
   'searchdlg'


def c_t
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5392,
                      0,
                      0)
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5391,
                      0,
                      0)

def c_tab = keyin \9

def c_u = 'undodlg'

compile if    WANT_STACK_CMDS
def c_up =
   'poppos'
compile endif

def c_W=
   if marktype()<>'' then
      sayerror -279  -- 'Text already marked'
      return
   endif
   if find_token(startcol, endcol) then
      getfileid fid
 compile if WORD_MARK_TYPE = 'CHAR'
      call pset_mark(.line, .line, startcol, endcol, 'CHAR', fid)
 compile else
      call pset_mark(.line, .line, startcol, endcol, 'BLOCK', fid)
 compile endif
      'Copy2SharBuff'       /* Copy mark to shared text buffer */
   endif

def c_Y = 'fontlist'

def del=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if    WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if marktype() & CUA_marking_switch then    -- If there's a mark, then
 compile else
   if marktype() then    -- If there's a mark, then
 compile endif
      if process_mark_like_cua() then return; endif
   endif
compile endif
compile if WANT_STREAM_MODE
   if .line then
      l=length(textline(.line))
   else
      l=.col    -- make the following IF fail
   endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   if .col>l & stream_mode then
 compile else
   if .col>l then
 compile endif
      join
      .col=l+1
   else
compile endif  -- WANT_STREAM_MODE
      old_level = .levelofattributesupport
      if old_level & not (old_level bitand 2) then
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = 0
      endif
      delete_char
      .levelofattributesupport = old_level
compile if WANT_STREAM_MODE
   endif
compile endif

def down=
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      executekey s_f5  -- vcenter cursor
      executekey s_f4  -- act like scroll up
   else
compile endif
compile if WANT_STREAM_MODE
      call updownkey(1)
compile else
      down
compile endif
compile if RESPECT_SCROLL_LOCK
   endif
compile endif

compile if    WANT_SHIFT_MARKING
def s_down=
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
   startline = .line; startcol = .col
 compile if WANT_STREAM_MODE
   call updownkey(1)
 compile else
   down
 compile endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if CUA_marking_switch then
;compile endif
   if startline then call extend_mark(startline, startcol, 1); endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif
compile endif

def end=
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   end_line

compile if    WANT_SHIFT_MARKING
def s_end =
   startline = .line; startcol = .col
   end_line
   call extend_mark(startline, startcol, 1)
compile endif

; Moved to ENTER.E
;def enter =
;def a_enter =
;def c_enter =
;def s_enter =
;def padenter =
;def a_padenter =
;def c_padenter =
;def s_padenter =
;defproc shell_enter_routine(xxx_enterkey)
;def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter=

compile if not defined(NO_ESCAPE)
   const NO_ESCAPE = 0
compile endif

compile if NO_ESCAPE  -- Blame CUA  :-(
def esc=
 compile if TOGGLE_ESCAPE
   universal ESCAPE_KEY
 compile endif
compile else
def esc, C_I=
compile endif
   universal alt_R_active

   sayerror 0
   if alt_R_active<>'' then
       'setmessageline '\0
      'toggleframe 2 'alt_R_active         -- Restore status of messageline.
      alt_R_active = ''
compile if NO_ESCAPE
 compile if TOGGLE_ESCAPE
   elseif ESCAPE_KEY then
      'commandline'
 compile endif
   endif
def c_I='commandline'
compile else
   else
      'commandline'
   endif
compile endif  -- no Escape

def f1= 'help'

def f2=
compile if SMARTSAVE
   if .modify then           -- Modified since last Save?
      'Save'                 --   Yes - save it
   else
;      'commandline Save '
      sayerror 'No changes.  Press Enter to Save anyway.'
      'saveas_dlg'  -- better show file selector
   endif
compile else
   'Save'
compile endif

def f3= 'quit'

def f4=
compile if SMARTFILE
   if .modify then           -- Modified since last Save?
      'File'                 --   Yes - save it and quit.
   else
      'Quit'                 --   No - just quit.
   endif
compile else
   'File'
compile endif

                    /* keys by EPM */
def f5, c_O='OPENDLG'
def f7='rename'
def f8=
compile if RING_OPTIONAL
   universal ring_enabled
   if not ring_enabled then
      sayerror NO_RING__MSG
      return
   endif
compile endif
   'OPENDLG EDIT'

def f9, a_backspace = undo


def f10,f12,c_N=   -- F10 is usual E default; F12 for enhanced kbd, c_N for EPM.
   nextfile

/*
def home =
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   begin_line

compile if    WANT_SHIFT_MARKING
def s_home =
   startline = .line; startcol = .col
   begin_line
   call extend_mark(startline, startcol, 0)
compile endif
*/

def home =
   universal nepmd_hini
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   KeyPath = "\NEPMD\User\Indent\Home\RespectIndent"
   RespectIndent = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   if RespectIndent = 1 then
      startline = .line; startcol = .col
      call pfirst_nonblank()
      if .line = startline and .col = startcol then
         begin_line
      endif
   else
      begin_line
   endif

compile if WANT_SHIFT_MARKING
def s_home =
   universal nepmd_hini
   startline = .line; startcol = .col
   KeyPath = "\NEPMD\User\Indent\Home\RespectIndent"
   RespectIndent = NepmdQueryConfigValue( nepmd_hini, KeyPath )
   if RespectIndent = 1 then
      call pfirst_nonblank()
      if .line = startline and .col = startcol then
         begin_line
      endif
   else
      begin_line
   endif
   call extend_mark(startline, startcol, 0)
compile endif


def ins=
   insert_toggle
   call fixup_cursor()

def left=
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      executekey s_F1  -- Scroll left
   else
compile endif
*/
compile if WANT_STREAM_MODE = 'SWITCH'
      if .line>1 & .col=1 & stream_mode then up; end_line; else left; endif
compile elseif WANT_STREAM_MODE
      if .line>1 & .col=1 then up; end_line; else left; endif
compile else
      left
compile endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
*/
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif

compile if    WANT_SHIFT_MARKING
def s_left =
   startline = .line; startcol = .col
   if .line>1 & .col=1 then up; end_line; else left; endif
   call extend_mark(startline, startcol, 0)
compile endif


def pgup =
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   page_up

def pgdn =
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   page_down

compile if    WANT_SHIFT_MARKING
def s_pgup=
 compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
   startline = .line; startcol = .col
   page_up
   if .line then call extend_mark(startline, startcol, 0); endif
 compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   if not .line & stream_mode then '+1'; endif
 compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
 compile endif

def s_pgdn=
   startline = .line; startcol = .col
   page_down
   if startline then call extend_mark(startline, startcol, 1); endif
compile endif

def right=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      executekey s_F2  -- Scroll right
   else
compile endif
*/
compile if WANT_STREAM_MODE
      if .line then l=length(textline(.line)); else l=.col; endif
 compile if WANT_STREAM_MODE = 'SWITCH'
      if .line<.last & .col>l & stream_mode then
 compile else
      if .line<.last & .col>l then
 compile endif
         down; begin_line
 compile if WANT_STREAM_MODE = 'SWITCH'
      elseif .line=.last & .col>l & stream_mode then   -- nop
 compile else
      elseif .line=.last & .col>l then  -- nop
 compile endif
      else
         right
      endif
compile else
      right
compile endif
/*
-- Don't like hscroll
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
*/

compile if    WANT_SHIFT_MARKING
def s_right =
   startline = .line; startcol = .col
   if .line then l=length(textline(.line)); else l=.col; endif
   if .line<.last & .col>l then
      down; begin_line
   elseif .line<>.last | .col<=l then
      right
   endif
   call extend_mark(startline, startcol, 1)
compile endif


def s_f1= /* scroll left */
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   oldcursorx=.cursorx
   if .col-.cursorx then
      .col=.col-.cursorx
      .cursorx=oldcursorx
   elseif .cursorx>1 then
      left
   endif

def s_f2= /* scroll right */
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   oldcursorx=.cursorx
   a=.col+.windowwidth-.cursorx+1
   if a<=MAXCOL then
      .col=a
      .cursorx=oldcursorx
   elseif .col<MAXCOL then
      right
   endif

def s_f3= /* scroll up */
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   oldcursory=.cursory
   if .line-.cursory>-1 then
      .cursory=1
      up
      .cursory=oldcursory
   elseif .line then
      up
   endif

def s_f4= /* scroll down */
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   oldcursory=.cursory
   if .line -.cursory+.windowheight<.last then
      .cursory=.windowheight
      down
      .cursory=oldcursory
   elseif .line<.last then
      down
   endif

def s_f5= /* center current line */
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   oldline=.line
   .cursory=.windowheight%2
   oldline

compile if WANT_TAGS
def s_f6 = 'findtag'
def s_f7 = 'findtag *'
def s_f8 = 'tagsfile'
def s_f9 = 'maketags *'
compile endif -- WANT_TAGS

def s_tab=
   universal matchtab_on
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   if matchtab_on & .line>1 then
      up
      backtab_word
      down
   else
      backtab
   endif

def space, s_space, c_space  /* New in EPM.  Space is a virtual key under PM.*/
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      call process_mark_like_cua()
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
   k=lastkey(1)
   keyin ' '
   if k<>' ' then
      undoaction 1, junk                -- Create a new state
   endif

def tab=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
   universal matchtab_on
compile if TOGGLE_TAB
   universal TAB_KEY
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
                  -------Start of logic:
compile if TOGGLE_TAB
   if TAB_KEY then
 compile if WANT_CUA_MARKING
  compile if WANT_CUA_MARKING = 'SWITCH'
      if CUA_marking_switch then
  compile endif
          process_key(\9)
  compile if WANT_CUA_MARKING = 'SWITCH'
      else
  compile endif
 compile endif  -- WANT_CUA_MARKING
         keyin \9
 compile if WANT_CUA_MARKING = 'SWITCH'
      endif  -- CUA_marking_switch
 compile endif
   else  -- TAB_KEY
compile endif  -- TOGGLE_TAB
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
      if CUA_marking_switch then
 compile endif
         unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
      endif  -- CUA_marking_switch
 compile endif
compile endif  -- WANT_CUA_MARKING
      oldcol=.col
      if matchtab_on and .line>1 then
         up
;;       c=.col  -- Unused ???
         tab_word
         if oldcol>=.col then
            .col=oldcol
            tab
         endif
         down
      else
         tab
      endif
compile if WANT_STREAM_MODE | WANT_TAB_INSERTION_TO_SPACE
 compile if WANT_STREAM_MODE = 'SWITCH' and not WANT_TAB_INSERTION_TO_SPACE
      if insertstate() & stream_mode then
 compile else
      if insertstate() then
 compile endif
         numspc=.col-oldcol
 compile if WANT_DBCS_SUPPORT
         if ondbcs then                                           -- If we're on DBCS,
            if not (matchtab_on and .line>1) then  -- and didn't do a matchtab,
               if words(.tabs) > 1 then
                  if not wordpos(.col, .tabs) then                   -- check if on a tab col.
                     do i=1 to words(.tabs)              -- If we got shifted due to being inside a DBC,
                        if word(.tabs, i) > oldcol then  -- find the col we *should* be in, and
                           numspc = word(.tabs, i) - oldcol  -- set numspc according to that.
                           leave
                        endif
                     enddo
                  endif
               elseif (.col // .tabs) <> 1 then
                  numspc = .tabs - (oldcol+.tabs-1) // .tabs
               endif  -- words(.tabs) > 1
            endif
         endif  -- ondbcs
 compile endif  -- WANT_DBCS_SUPPORT
         if numspc>0 then
            .col=oldcol
            keyin substr('',1,numspc)
         endif
      endif  -- insertstate()
compile endif  -- WANT_STREAM_MODE | WANT_TAB_INSERTION_TO_SPACE
compile if TOGGLE_TAB
   endif  -- TAB_KEY
compile endif  -- TOGGLE_TAB


def up=
compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
compile if RESPECT_SCROLL_LOCK
   if scroll_lock() then
      executekey s_f5  -- vcenter cursor
      executekey s_f3  -- act like scroll down
   else
compile endif
compile if WANT_STREAM_MODE
      call updownkey(0)
compile else
      up
compile endif
compile if RESPECT_SCROLL_LOCK
   endif
compile endif
compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   if not .line & stream_mode then '+1'; endif
compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
compile endif

compile if    WANT_SHIFT_MARKING
def s_up=
 compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
   startline = .line; startcol = .col
 compile if WANT_STREAM_MODE
   call updownkey(0)
 compile else
   up
 compile endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  if CUA_marking_switch then
;compile endif
   if .line then call extend_mark(startline, startcol, 0); endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  endif
;compile endif
 compile if TOP_OF_FILE_VALID = 'STREAM' & WANT_STREAM_MODE = 'SWITCH'
   if not .line & stream_mode then '+1'; endif
 compile elseif not TOP_OF_FILE_VALID
   if not .line then '+1'; endif
 compile endif
compile endif

-- Standard PM clipboard functions.
def s_del = 'cut'

def s_ins =
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
 compile if WANT_CUA_MARKING
      call process_mark_like_cua()
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
   'paste' DEFAULT_PASTE

def c_ins = 'copy2clip'

compile if WANT_STREAM_MODE
defproc updownkey(down_flag)
   universal save_cursor_column
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
   if stream_mode then
 compile endif
      lk = lastkey(1)
      updn = pos(leftstr(lk,1),\x18\x16) & pos(substr(lk,2,1),\x02\x0A\x12)   -- VK_DOWN or VK_UP, plain or Shift or Ctrl
      if not updn then save_cursor_column = .col; endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   endif
 compile endif

   if down_flag then down; else up; endif

 compile if WANT_STREAM_MODE = 'SWITCH'
   if .line & stream_mode then
 compile else
   if .line then
 compile endif
      l = length(textline(.line))
      if updn & l>=save_cursor_column then
         .col = save_cursor_column
      elseif updn | l<.col then
         end_line
      endif
   endif
compile endif  -- WANT_STREAM_MODE

/* ------ Keys unused in standard E ------------------------------------------

a_2, a_3, a_5, a_6, a_7, a_8, a_9

a_f2, a_f3, a_f4, a_f5, a_f6, a_f9

a_g, a_h, a_i, a_k, a_q, a_v

c_6, c_minus, c_backslash

c_leftbracket, c_rightbracket, (EOS2 only:) a_leftbracket, a_rightbracket

c_f9, c_f10

c_g, c_i, c_j, c_prtsc, c_q, c_u

f5

s_f6, s_f7, s_f8, s_f9, s_f10

-----  The following is for EOS2 4.10 or above only.  -----

New keys that work on even older unenhanced AT keyboards:
   c_up, c_down
   pad5, c_pad5
   c_padminus, c_padplus, c_padstar
   c_ins, c_del
   c_tab, a_tab
   a_leftbracket, a_rightbracket

On an enhanced keyboard only:
   f11, f12, and c_,s_,a_
   pad_enter               is defined the same as enter
   a_enter and a_padenter are defined the same as enter
   c_pad_enter             is defined the same as c_enter
   pad_slash               is defined the same as '/'
   c_padslash              is defined the same as '/'

-----  The following is for EPM only.  -----
  * Since we are using only keys defined by PM (and not looking at
    scan codes), we no longer have the keys:
      padplus, c_padplus, c_padstar
      pad_slash, c_padslash
      pad5, c_pad5
   * We gained the new keys:
    - space, s_space, c_space, and a_space
         (The space bar is a virtual key to PM, not a character key.  If you
         want to bind an action to the space key, write  def space=  instead of
         the old  def ' '= .  The good news is that you get all the shift
         states of the space bar, although alt_space is preempted by PM.)
    - c_1 through c_0
         (So now we have a complete set of alt- and ctrl-digits.)
---------------------------------------------------------------------------- */

