define
compile if EVERSION < 5
   NOT_CMD_STATE = '& not command_state()'
compile else
   NOT_CMD_STATE = ' '
compile endif

definit
   universal blockreflowflag
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
compile endif
compile if EVERSION < 5
   universal inKstring
   inKstring=0
compile endif
   blockreflowflag=0
compile if defined(HIGHLIGHT_COLOR)
   search_len = 5     -- Initialize to anything, to prevent possible "Invalid number argument"
compile endif

compile if WANT_CUA_MARKING & EPM
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
compile if EVERSION >= '5.20'
         undoaction 1, junk                -- Create a new state
compile endif
         call pdelete_mark()
         'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
         return 1
      endif
   endif
compile else  -- WANT_CUA_MARKING & EPM
defkeys edit_keys new
compile endif  -- WANT_CUA_MARKING & EPM

compile if WANT_SHIFT_MARKING
defproc shifted
 compile if EPM
   ks = getkeystate(VK_SHIFT)
   return ks<>3 & ks<>4
 compile else
  compile if E3
   kbflags = asc(peek(64,23,1))  -- 0040:0017 = keyboard flags byte
  compile else
   getshiftstate kbflags         -- New statement in 4.10.  No PCDOS.
  compile endif
   return kbflags - (kbflags%4 * 4)
 compile endif

 compile if EVERSION < 5.50
define CHARG_MARK = 'CHAR'
 compile else                -- New mark type
define CHARG_MARK = 'CHARG'
 compile endif

defproc extend_mark(startline, startcol, forward)
compile if not EPM
   universal shift_flag
compile endif
;compile if WANT_CUA_MARKING = 'SWITCH'
;  universal CUA_marking_switch
;  if not CUA_marking_switch then return; endif
;compile endif
   if marktype()='LINE' | marktype()='BLOCK' then return; endif
   getfileid curfileid
   if not marktype() then
compile if EVERSION < 5.50  -- Forwards and backwards acts differently
      call pset_mark(startline, .line, startcol-(not forward), .col-forward, CHARG_MARK, curfileid)
compile else  -- CHARG handles the differences.
      call pset_mark(startline, .line, startcol, .col, CHARG_MARK, curfileid)
compile endif
      return
   endif
compile if EVERSION < 5.50
   getmark firstline,lastline,firstcol,lastcol,markfileid
compile else
   getmarkg firstline,lastline,firstcol,lastcol,markfileid
compile endif
   if markfileid<>curfileid then  -- If mark was in a different file, treat like no mark was set.
compile if EVERSION < 5.50  -- Forwards and backwards acts differently
      call pset_mark(startline, .line, startcol-(not forward), .col-forward, CHARG_MARK, curfileid)
compile else  -- CHARG handles the differences.
      call pset_mark(startline, .line, startcol, .col, CHARG_MARK, curfileid)
compile endif
      return
   endif
   lk = lastkey(0)
compile if EPM
   if (lk=s_up & .line=firstline-1) | (lk=s_down & .line=firstline+1) then
compile else
   if shift_flag then
    if (lk=up & .line=firstline-1) | (lk=down & .line=firstline+1) then
compile endif
      if length(textline(firstline)) < .col then
         firstcol = .col
      endif
   endif
compile if not EPM
   endif
compile endif
   if startline>firstline | ((startline=firstline) & (startcol > firstcol)) then  -- at end of mark
      if not forward then
         if firstline=.line & firstcol=.col then unmark; return; endif
      endif
compile if EVERSION < '5.50'
      call pset_mark(firstline, .line, firstcol, .col-1, CHARG_MARK, curfileid)
compile else
      call pset_mark(firstline, .line, firstcol, .col, CHARG_MARK, curfileid)
compile endif
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

compile if EVERSION < 5
def entry=
compile endif

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
compile if (EVERSION >= '4.12' & EVERSION < 5 & SHELL_USAGE) | WANT_EPM_SHELL
 compile if EOS2
   if .filename = '.SHELL' then
 compile else
   if leftstr(.filename, 15) = ".command_shell_" then
 compile endif
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
 compile if EPM
         display -2
 compile endif
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
 compile if EOS2
         else
            sayerror 1
 compile endif
         endif
 compile if EPM
         display 2
 compile endif
         setsearch oldsearch
         call prestore_pos(save_pos)
         if not dir_rc then
            name=word3 ||                            -- Start with the path.
                 leftstr('\',                        -- Append a '\', but only if path
                         '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
                 filename                            -- Finally, the filename
 compile if not E3  -- DOS (box) doesn't see new-format filenames
;           if pos(' ',name) then  -- enquote
            if verify(name, ' =', 'M') then  -- enquote
               name = '"'name'"'
            endif
 compile endif
            if pos('<DIR>',line) then
               'dir 'name
            else
               'e 'name
            endif
            return
         endif
      endif
   endif
compile endif  -- SHELL_USAGE | WANT_EPM_SHELL
   parse value .filename with word1 word2 word3 .
   if upcase(word1 word2) = '.DOS DIR' then
      call psave_pos(save_pos)
compile if EVERSION >= '4.12'
      getsearch oldsearch
compile endif
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
compile if EVERSION >= '4.12'
      setsearch oldsearch
compile endif
      call prestore_pos(save_pos)
compile if not E3  -- DOS (box) doesn't see new-format DIR listing
      filename=substr(line,41)                 -- Support HPFS.  FAT dir's end at 40
      if substr(line, 39, 1)=' ' & substr(line, 40, 1)<>' ' then  -- OS/2 2.11 is misaligned...
         filename=substr(line,40)
      endif
      if filename='' then                      -- Must be FAT.
compile endif
         filename=strip(substr(line,1,8))
         word2=strip(substr(line,10,3))
         if word2<>'' then filename=filename'.'word2; endif
compile if not E3  -- DOS (box) doesn't see new-format DIR listing
      endif
compile endif
      name=word3 ||                            -- Start with the path.
compile if EVERSION >= '5.17'
           leftstr('\',                        -- Append a '\', but only if path
                   '\'<>rightstr(word3,1)) ||  -- doesn't end with one.
compile else
           substr('\', 1,                      -- Append a '\', but only if path
                  '\'<>substr(word3,length(word3),1)) ||  -- doesn't end with one.
compile endif
           filename                            -- Finally, the filename
compile if not E3  -- DOS (box) doesn't see new-format filenames
;     if pos(' ',name) then  -- enquote
      if verify(name, ' =', 'M') then  -- enquote
         name = '"'name'"'
      endif
compile endif
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
compile if EVERSION >= '5.50'
            'e "'name'"'
compile else
            'e' name
compile endif
         endif
      endif
compile endif  -- WANT_TREE
   else  -- Not a DIR listing
compile if not E3
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
compile endif
         'e 'line
compile if not E3
      endif
compile endif
   endif

compile if WANT_WINDOWS
def a_4=call psplit4()            -- routine defined in WINDOW.E
compile endif

def a_a=
compile if WANT_CHAR_OPS
   call pcommon_adjust_overlay('A')
compile else
   adjustblock
compile endif

def a_b
   markblock
compile if EVERSION >= 5
   'Copy2SharBuff'       /* Copy mark to shared text buffer */
compile endif

def a_c=
compile if EPM
   if marktype() then
compile endif
      call pcopy_mark()
compile if EPM
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff'     /* see clipbrd.e for details                 */
   endif
compile endif

def a_d=
compile if WANT_DM_BUFFER
   'Copy2DMBuff'     -- see clipbrd.e for details
compile endif
   call pdelete_mark()
compile if EVERSION > 5
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
compile endif

def a_e=
   call pend_mark()
   if substr(marktype(),1,1)<>'L' then
      right
   endif

def a_equal=
   'dolines'   -- Code is a separate command in STDCMDS.E.

def a_f= /* Now accepts key from macro. */
   call checkmark()
compile if EVERSION < 5
   k=mgetkey("Type a character, or Esc to cancel.")
   if length(k)>1 then           -- Do something with extended keys.
      if     k=esc      then ;   -- Let user abort w/o Ctrl-break.
      elseif k=padstar  then k='*'
      elseif k=padplus  then k='+'
      elseif k=padminus then k='-'
      else   k=substr(k,2,1)      endif
   endif
   if k<>esc then call pfill_mark(k); endif
compile else
   call pfill_mark()
compile endif

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

compile if EVERSION < 5
 compile if EVERSION < '4.10'          -- Early E doesn't support enh. kbd.
def a_f10,c_P= call pprevfile()       -- routine defined in WINDOW.E
 compile else
def a_f10,F11,c_P= call pprevfile()       -- routine defined in WINDOW.E
 compile endif
compile else
/* We can't use a_f10 for previous file any more, PM uses that key. */
/* I like F11 and F12 to go back and forth.                         */
def a_f10,F11,c_P=  -- a_F10 is usual E default; F11 for enh. kbd, c_P for EPM.
   prevfile
compile endif

compile if EPM32
; def a_F11 = 'prevview'
def a_F12 = 'nextview'
compile endif

def a_j=
   call joinlines()

def a_l=
   mark_line
compile if EVERSION >= 5
   'Copy2SharBuff'       /* Copy mark to shared text buffer */
compile endif

def a_m=call pmove_mark()
compile if UNMARK_AFTER_MOVE
   unmark
 compile if EVERSION > 5
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
 compile endif
compile endif

def a_minus =
 compile if EOS2
   display 0
 compile endif
 compile if EVERSION < '5.50'
   sayat '', .cursory, .cursorx, WHITE + REDB + BLINK, 1
 compile elseif EVERSION >= '5.60'
   circleit 5, .line, .col-1, .col+1, 16777220
 compile else
   circleit 2, .line, .col-1, .col+1, WHITE + REDB + BLINK
 compile endif
 compile if EPM & EVERSION < '5.50'
   call dynalink('DOSCALLS', '#32', atol_swap(1000))  -- 1 second DOSSLEEP
   refresh
 compile endif
 compile if EOS2
   k=getkey()
   display 1
   executekey k
 compile endif

def a_n=  /* Type the full name of the current file. */
  keyin .filename

def a_o=
compile if EPM
   if marktype() then
compile endif
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('O')
compile else
      overlay_block
compile endif
compile if EPM
   else                 /* If no mark, look to in Shared Text buffer */
      'GetSharBuff O'   /* see clipbrd.e for details                 */
   endif
compile endif

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
compile if EVERSION < 5
         do while testkey()/==''; call getkey(); end
         sayerror MARK_OFF_SCRN_YN__MSG
         loop
            ch=upcase(getkey())
            if ch=YES_CHAR then sayerror 0; leave; endif
            if ch=NO_CHAR or ch=esc then sayerror 0; stop; endif
         endloop
compile else
         sayerror MARK_OFF_SCREEN__MSG
         stop
compile endif
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
compile if EPM
   universal alt_R_space
compile endif

   if alt_R_active<>'' then
compile if EPM
      call pblock_reflow(1,alt_R_space,tempofid)     -- Complete the reflow.
 compile if EVERSION < '5.21'
      .messageline=''                        -- Turn off the message.
 compile else
       'setmessageline '\0
 compile endif
 compile if EVERSION >= '5.53'
      'toggleframe 2 'alt_R_active           -- Restore status of messageline.
 compile else
      'togglecontrol 8 'alt_R_active         -- Restore status of messageline.
 compile endif
      alt_R_active = ''
      return
compile else
      activatefile tempofid                  -- Release tempo
      .modify=0
      'xcom q'
compile endif
   endif
   if pblock_reflow(0,alt_R_space,tempofid) then
      sayerror PBLOCK_ERROR__MSG      /* HurleyJ */
      return
   endif
;  if marktype() <> 'BLOCK' then
      unmark
;  endif
compile if EPM
 compile if EVERSION >= '5.53'
   alt_R_active = queryframecontrol(2)         -- Remember if messageline on or off
   'toggleframe 2 1'                    -- Force it on
 compile else
   alt_R_active = querycontrol(8)         -- Remember if messageline on or off
   'togglecontrol 8 1'                    -- Force it on
 compile endif
 compile if EVERSION < '5.21'
   .messageline = BLOCK_REFLOW__MSG
 compile else
   'setmessageline' BLOCK_REFLOW__MSG
 compile endif
compile else
   alt_R_active = 1
   sayerror BLOCK_REFLOW__MSG
   loop
      k=getkey()
      if k==a_r then  /* Alt-R ? */
         call pblock_reflow(1,alt_R_space,tempofid)
         leave
      endif
      if k==esc then  /* Esc ? */
         /* release tempo */
         activatefile tempofid
         .modify=0
         'xcom q'
         unmark
         sayerror NOFLOW__MSG
         leave
      endif
      executekey k
   endloop
   alt_R_active = ''
compile endif

def a_s=
   call splitlines()

def a_t = call pcenter_mark()

def a_u=
   unmark
compile if EVERSION > 5
   'ClearSharBuff'       /* Remove Content in EPM shared text buffer */
compile endif

def a_w = call pmark_word()

;  EPM:  Haven't yet figured out a way to do Alt-X=escape.  It used a getkey().
compile if EVERSION < 5
def a_x=escape
compile endif

def a_y= call pbegin_mark()

compile if WANT_CHAR_OPS
def a_z=mark_char
 compile if EVERSION > 5
   'Copy2SharBuff'       /* Copy mark to shared text buffer */
 compile endif
compile endif

compile if EVERSION < 5
def backspace=
compile else
def backspace, s_backspace =
compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
   if CUA_marking_switch then
 compile endif
 compile if WANT_CUA_MARKING
  compile if EVERSION < 5
   if command_state() then rubout; return; endif
  compile endif
   if process_mark_like_cua() then return; endif
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile if WANT_STREAM_MODE
 compile if WANT_STREAM_MODE = 'SWITCH'
   if .col=1 & .line>1 & stream_mode $NOT_CMD_STATE then
 compile else
   if .col=1 & .line>1 $NOT_CMD_STATE then
 compile endif
      up
      l=length(textline(.line))
      join
      .col=l+1
   else
compile endif
compile if EVERSION >= '5.50'
      old_level = .levelofattributesupport
 compile if EVERSION >= '6.01b'
      if old_level & not (old_level bitand 2) then
 compile else
      if old_level & not (old_level%2 - 2*(old_level%4)) then
 compile endif
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = -300
      endif
compile endif
      rubout
compile if EVERSION >= '5.50'
      .levelofattributesupport = old_level
compile endif
compile if WANT_STREAM_MODE
   endif
compile endif

def c_2 = keyin \0                  -- C_2 enters a null.
def c_6 = keyin \170                -- C_6 enters a "not" sign
compile if EVERSION >= '5.50'
def c_9 = keyin '{'
def c_0 = keyin '}'
def c_4 = keyin '›'                 -- C_4 enters a cents sign
compile endif

compile if WANT_WINDOWS
def c_a= call pnextwindowstyle()  -- routine defined in WINDOW.E
compile else
def c_a= 'newtop'     -- Move current line to top of window.
compile endif

compile if WANT_BOOKMARKS
def c_B = 'listmark'
compile endif

def c_backspace=
compile if EVERSION >= '5.20'
   undoaction 1, junk                -- Create a new state
compile endif
compile if EVERSION >= '5.50'
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
compile endif
   delete
compile if EVERSION >= '5.20'
   undoaction 1, junk                -- Create a new state
compile endif
compile if EVERSION < 5
   if command_state() then
      begin_line
   endif
compile endif

def c_c=
compile if EVERSION < 5
  right
compile else
  'c'    -- EPM c_c is used for change next
compile endif

; Ctrl-D = word delete, thanks to Bill Brantley.
def c_d =  /* delete from cursor until beginning of next word, UNDOable */
compile if EVERSION < 5
   if command_state() then
      getcommand cmdline, begcur, cmdscrPos
      lenCmdLine=length(cmdline)
      if lenCmdLine >= begcur then
         for i = begcur to lenCmdLine /* delete remainder of word */
            if substr(cmdline,i,1)<>' ' then
               deleteChar
            else
               leave
            endif
         endfor
         for j = i to lenCmdLine /* delete delimiters following word */
            if substr(cmdline,j,1)==' ' then
               deleteChar
            else
               leave
            endif
         endfor
      endif
   else
compile endif
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
compile if EVERSION < 5
   endif
compile endif

compile if WANT_STACK_CMDS & not E3
def c_down =
   'pushpos'
compile endif

compile if EVERSION >= '4.10'
def c_e, c_del=erase_end_line  -- Ctrl-Del is the PM way.
compile else
def c_e=erase_end_line
compile endif

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

compile if ENHANCED_ENTER_KEYS & C_ENTER_ACTION <> ''  -- define each key separately
; Nothing - defined below along with ENTER
compile else
 compile if EVERSION >= '4.10'
def c_enter, c_pad_enter=     -- 4.10:  new key for enhanced keyboard
 compile else
def c_enter=
 compile endif
   call my_c_enter()
 compile if E3 and SHOW_MODIFY_METHOD
   call show_modify()
 compile endif
compile endif

def c_f=
compile if defined(HIGHLIGHT_COLOR)
   universal search_len
 compile if EOS2
   universal inKstring
 compile endif
compile endif
compile if EVERSION > 5
   sayerror 0
compile endif
   repeat_find       /* find next */
compile if EVERSION < 5
   if not rc then
      cursor_data
 compile if defined(HIGHLIGHT_COLOR)
      refresh
      sayat '', .windowy+.cursory-1,.windowx+.cursorx-1,
            HIGHLIGHT_COLOR, min(search_len, .windowwidth - .cursorx + 1)
  compile if EOS2
      if inKstring <=0 then
         k=mgetkey()
         executekey k
      endif
  compile endif
 compile endif
   endif
compile elseif defined(HIGHLIGHT_COLOR)
   call highlight_match(search_len)
compile endif

def c_f1=
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   call psave_mark(save_mark)
   call pmark_word()
   call puppercase()
   call prestore_mark(save_mark)
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif

def c_f2=
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   call psave_mark(save_mark)
   call pmark_word()
   call plowercase()
   call prestore_mark(save_mark)
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif

def c_f3= call puppercase()

def c_f4= call plowercase()

def c_f5=
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   call pbegin_word()
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif

def c_f6=
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   call pend_word()
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif

compile if EPM
def c_g='ring_more'
compile endif

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

compile if WANT_WINDOWS
def c_h=call psplith()            -- routine defined in WINDOW.E
compile endif

def c_k=      -- Duplicate a line
  getline line
  insertline line,.line+1

def c_l =
   if .line then
      getline line
compile if EPM
      'commandline 'line
compile else
      if not command_state() then
         cursor_command
         begin_line;erase_end_line
      endif
      keyin line
compile endif
   endif

def c_left=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE
   if not .line then
      begin_line
 compile if WANT_STREAM_MODE = 'SWITCH'
   elseif .line>1 & .col=max(1,verify(textline(.line),' ')) & stream_mode $NOT_CMD_STATE then
 compile else
   elseif .line>1 & .col=max(1,verify(textline(.line),' ')) $NOT_CMD_STATE then
 compile endif
      up; end_line
   endif
compile endif
   backtab_word
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif
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

compile if EVERSION < 5
/************************************************************/
/* Create a string of keys in Kstring variable.             */
/* All control keys have the same character (X'00') as the  */
/* first character of a two-character string.               */
/*                                                          */
/* The number of keys that may be stored is given by:       */
/*           256 > n + 2*e                                  */
/* where:                                                   */
/*       n are normal data keys (one byte from BIOS)        */
/*       e are extended code keys (two bytes from BIOS)     */
/************************************************************/
def c_r=
   universal Kstring,Kins_state,Kcom_state,inKstring

   inKstring=-1      /* Set recording flag; see defproc mgetkey(). */
   sayerror CTRL_R__MSG
   oldKins_state=Kins_state
   oldKstring   =Kstring
   oldKcom_state=Kcom_state
   Kins_state   =insert_state()
   Kstring      =''
   Kcom_state   =command_state()
   Kct=0
   loop
      k=getkey()
      if k==c_r then  /* Ctrl-R ? */
         sayerror REMEMBERED__MSG
         leave
      endif
      if k==c_t then  /* Ctrl-T ? */
         leave
      endif
      if k==c_c then  /* cancel? */
         Kstring   =oldKstring
         Kins_state=oldKins_state
         Kcom_state=oldKcom_state
         sayerror CANCELLED__MSG'  'OLD_KEPT__MSG
         leave
      endif
      Kstring=Kstring||k
      Kct=length(Kstring)
      executekey k         /* execute AFTER adding to string */
      if Kct > MAXCOL then
         sayerror CTRL_R_ABORT__MSG
         Kstring=oldKstring
         Kins_state=oldKins_state
         Kcom_state=oldKcom_state
         loop
            k=getkey()
            if k==esc or k==c_c then leave endif   /* accept either */
         endloop
         sayerror OLD_KEPT__MSG
         leave
      endif
   endloop
   inKstring=0       /* lower state flag */
   if k==c_t then    /* Was it Ctrl-T? */
      sayerror 0     /* refresh the function keys */
      executekey k
   endif
compile endif

compile if EPM
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
compile endif

def c_right=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
compile if WANT_SHIFT_MARKING
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if WANT_STREAM_MODE
   getline line
 compile if WANT_STREAM_MODE = 'SWITCH'
   if not .line | lastpos(' ',line)<.col & .line<.last & stream_mode $NOT_CMD_STATE then
 compile else
   if not .line | lastpos(' ',line)<.col & .line<.last $NOT_CMD_STATE then
 compile endif
      down
      call pfirst_nonblank()
   else
compile endif
      tab_word
compile if WANT_STREAM_MODE
   endif
compile endif
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif
compile if WANT_SHIFT_MARKING
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

-- Pop up Search dialog
compile if EVERSION > 5
def c_s=
   'searchdlg'
compile endif

compile if EVERSION < 5
/************************************************************/
/* Execute the string of keys in Kstring variable.          */
/* All control keys have the same character (X'00') as the  */
/* first character of a two-character string                */
/*                                                          */
/* The number of keys that may be stored is given by:       */
/*           256 > n + 2*e                                  */
/* where:                                                   */
/*       n are normal data keys (one byte from BIOS)        */
/*       c are extended code keys (two bytes from BIOS)     */
/************************************************************/
def c_t=
   universal Kstring,Kins_state,Kcom_state,inKstring

   if Kstring=='' then
      sayerror NO_CTRL_R__MSG              /* HurleyJ */
      return
   endif   /* Has a string been recorded? */
   if Kins_state/==insert_state()   then  insert_toggle endif
   if Kcom_state/==command_state() then command_toggle endif

   inKstring=1    /* Set replaying flag; see defproc mgetkey(). */
   loop
      k=substr(Kstring,inKstring,1)
      ksize=1
      if k==substr(esc,1,1) then       /* extended key ? */
         k=substr(Kstring,inKstring,2) /* Yes, 2 bytes for extended key. */
         ksize=2
      endif
      inKstring=inKstring+ksize        /* bump index AFTER execution */
      executekey k
      if inKstring > length(Kstring) then leave endif
   endloop
   inKstring=0
compile endif

compile if EPM
def c_t
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5392,
                      0,
                      0)
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),
                      5391,
                      0,
                      0)
compile endif

compile if not E3
def c_tab = keyin \9
compile endif

compile if EVERSION >= '5.20'
def c_u = 'undodlg'
compile endif

compile if WANT_STACK_CMDS & not E3
def c_up =
   'poppos'
compile endif

compile if WANT_WINDOWS
def c_v= call psplitv()           -- routine defined in WINDOW.E
def c_w= call pnextwindow()       -- routine defined in WINDOW.E
def c_z= call pzoom()             -- routine defined in WINDOW.E
compile endif

compile if EPM
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
compile endif

compile if EVERSION >= '5.50'
def c_Y = 'fontlist'
compile endif

def del=
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_CUA_MARKING & EPM
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
   if .col>l & stream_mode $NOT_CMD_STATE then
 compile else
   if .col>l $NOT_CMD_STATE then
 compile endif
      join
      .col=l+1
   else
compile endif  -- WANT_STREAM_MODE
compile if EVERSION >= '5.50'
      old_level = .levelofattributesupport
 compile if EVERSION >= '6.01b'
      if old_level & not (old_level bitand 2) then
 compile else
      if old_level & not (old_level%2 - 2*(old_level%4)) then
 compile endif
         .levelofattributesupport = .levelofattributesupport + 2
         .cursoroffset = 0
      endif
compile endif
      delete_char
compile if EVERSION >= '5.50'
      .levelofattributesupport = old_level
compile endif
compile if WANT_STREAM_MODE
   endif
compile endif

def down=
compile if WANT_SHIFT_MARKING & not EPM
   universal shift_flag
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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if RESPECT_SCROLL_LOCK
  if scroll_lock() then
     executekey s_F4  -- Scroll down
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
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

compile if WANT_SHIFT_MARKING & EPM
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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
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
   end_line
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

compile if WANT_SHIFT_MARKING & EPM
def s_end =
   startline = .line; startcol = .col
   end_line
   call extend_mark(startline, startcol, 1)
compile endif

compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
def enter =
   universal enterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(enterkey)
 compile else
   call enter_common(enterkey)
 compile endif
def a_enter =
   universal a_enterkey
   call enter_common(a_enterkey)
def c_enter =
   universal c_enterkey
   call enter_common(c_enterkey)
def s_enter =
   universal s_enterkey
   call enter_common(s_enterkey)
def padenter =
   universal padenterkey
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   call shell_enter_routine(padenterkey)
 compile else
   call enter_common(padenterkey)
 compile endif
def a_padenter =
   universal a_padenterkey
   call enter_common(a_padenterkey)
def c_padenter =
   universal c_padenterkey
   call enter_common(c_padenterkey)
def s_padenter =
   universal s_padenterkey
   call enter_common(s_padenterkey)
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
defproc shell_enter_routine(xxx_enterkey)
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call enter_common(xxx_enterkey)
      endif
   else
      call enter_common(xxx_enterkey)
   endif
 compile endif  -- EPM_SHELL

compile else
 compile if EVERSION >= '4.10'
  compile if EVERSION < 5
def enter, pad_enter, a_enter, a_pad_enter=  --4.10: new enhanced keyboard keys
  compile else
def enter, pad_enter, a_enter, a_pad_enter, s_enter, s_padenter=
  compile endif
 compile else
def enter=
 compile endif
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
   if leftstr(.filename, 15) = ".command_shell_" then
      shellnum=substr(.filename,16)
      getline line
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      x = pos('>',line)
  compile else
      x = pos(']',line)
  compile endif
      text = substr(line,x+1)
  compile if EPM_SHELL_PROMPT = '@prompt epm: $p $g'
      if leftstr(line,5)='epm: ' & x & shellnum /*& text<>''*/ then
  compile else
      if leftstr(line,6)='[epm: ' & x & shellnum /*& text<>''*/ then
  compile endif
         if .line=.last then .col=x+1; erase_end_line; endif
         'shell_write' shellnum text
      else
         call my_enter()
      endif
   else
 compile endif
   call my_enter()
 compile if E3 and SHOW_MODIFY_METHOD
   call show_modify()
 compile endif
 compile if WANT_EPM_SHELL & (EPM_SHELL_PROMPT = '@prompt epm: $p $g' | EPM_SHELL_PROMPT = '@prompt [epm: $p ]')
  endif
 compile endif
compile endif  -- ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''

compile if not defined(NO_ESCAPE)
   const NO_ESCAPE = 0
compile endif

compile if EVERSION < 5
def esc=
   command_toggle
 compile if E3 and SHOW_MODIFY_METHOD
   call show_modify()
 compile endif
compile else  -- else EPM
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
 compile if EVERSION < '5.21'
      .messageline=''                        -- Turn off the message.
 compile else
       'setmessageline '\0
 compile endif
 compile if EVERSION >= '5.53'
      'toggleframe 2 'alt_R_active         -- Restore status of messageline.
 compile else
      'togglecontrol 8 'alt_R_active         -- Restore status of messageline.
 compile endif
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
compile endif  -- EPM

def f1= 'help'

def f2=
compile if SMARTSAVE
   if .modify then           -- Modified since last Save?
      'Save'                 --   Yes - save it
   else
 compile if EPM
      'commandline Save '
 compile else
      if not command_state() then
         cursor_command
      endif
      begin_line;erase_end_line
      keyin 'Save '
 compile endif
      sayerror 'No changes.  Press Enter to Save anyway.'
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

compile if EVERSION < 5
def f7=cursor_command; delete; begin_line; keyin 'Name '
def f8=cursor_command; delete; begin_line; keyin 'Edit '
compile else
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
compile endif

compile if EVERSION < 5
def f9=undo
compile else
def f9, a_backspace = undo
compile endif


compile if EVERSION < 5
 compile if EVERSION < '4.10'          -- Early E doesn't support enh. kbd.
def f10,c_N= call pnextfile()             -- routine defined in WINDOW.E
 compile else
def f10,f12,c_N= call pnextfile()         -- routine defined in WINDOW.E
 compile endif
compile else
def f10,f12,c_N=   -- F10 is usual E default; F12 for enhanced kbd, c_N for EPM.
   nextfile
compile endif


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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
   begin_line
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

compile if WANT_SHIFT_MARKING & EPM
def s_home =
   startline = .line; startcol = .col
   begin_line
   call extend_mark(startline, startcol, 0)
compile endif

def ins=insert_toggle
compile if EVERSION >='5.50'
   call fixup_cursor()
compile endif

def left=
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if RESPECT_SCROLL_LOCK
  if scroll_lock() then
     executekey s_F1  -- Scroll left
  else
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   if .line>1 & .col=1 & stream_mode $NOT_CMD_STATE then up; end_line; else left; endif
compile elseif WANT_STREAM_MODE
   if .line>1 & .col=1 $NOT_CMD_STATE then up; end_line; else left; endif
compile else
   left
compile endif
compile if RESPECT_SCROLL_LOCK
  endif
compile endif
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

compile if WANT_SHIFT_MARKING & EPM
def s_left =
   startline = .line; startcol = .col
   if .line>1 & .col=1 then up; end_line; else left; endif
   call extend_mark(startline, startcol, 0)
compile endif

compile if EVERSION < 5
def padminus=keyin '-'
def padplus=keyin '+'
 compile if EVERSION >= '4.10'
def padslash, c_padslash =keyin '/'     -- 4.10 for enhanced keyboard
 compile endif
def padstar=keyin '*'
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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
   page_up
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
   page_down
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

compile if WANT_SHIFT_MARKING & EPM
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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if RESPECT_SCROLL_LOCK
  if scroll_lock() then
     executekey s_F2  -- Scroll right
  else
compile endif
compile if WANT_STREAM_MODE
   if .line then l=length(textline(.line)); else l=.col; endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   if .line<.last & .col>l & stream_mode $NOT_CMD_STATE then
 compile else
   if .line<.last & .col>l $NOT_CMD_STATE then
 compile endif
      down; begin_line
 compile if WANT_STREAM_MODE = 'SWITCH'
   elseif .line=.last & .col>l & stream_mode $NOT_CMD_STATE then   -- nop
 compile else
   elseif .line=.last & .col>l $NOT_CMD_STATE then  -- nop
 compile endif
   else
      right
   endif
compile else
   right
compile endif
compile if RESPECT_SCROLL_LOCK
  endif
compile endif
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 1)
compile endif

compile if WANT_SHIFT_MARKING & EPM
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

compile if EVERSION < 5
def s_pad5=keyin '5'
compile endif

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
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   if matchtab_on & .line>1 $NOT_CMD_STATE then
      up
      backtab_word
      down
   else
      backtab
   endif
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif

compile if EPM
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
 compile if EVERSION >= '5.20'
   k=lastkey(1)
 compile endif
   keyin ' '
 compile if EVERSION >= '5.20'
   if k<>' ' then
      undoaction 1, junk                -- Create a new state
   endif
 compile endif
compile endif

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
      endif
 compile endif
   else
compile endif  -- TOGGLE_TAB
compile if WANT_CUA_MARKING
 compile if WANT_CUA_MARKING = 'SWITCH'
   if CUA_marking_switch then
 compile endif
      unmark
 compile if WANT_CUA_MARKING = 'SWITCH'
   endif
 compile endif
compile endif
compile if EVERSION < 5
   call init_operation_on_commandline()
compile endif
   oldcol=.col
   if matchtab_on and .line>1 $NOT_CMD_STATE then
      up
;;    c=.col  -- Unused ???
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
   if insertstate() & stream_mode $NOT_CMD_STATE then
 compile else
   if insertstate() $NOT_CMD_STATE then
 compile endif
      numspc=.col-oldcol
 compile if WANT_DBCS_SUPPORT
      if ondbcs then                                           -- If we're on DBCS,
         if not (matchtab_on and .line>1 $NOT_CMD_STATE) then  -- and didn't do a matchtab,
  compile if EPM32
            if words(.tabs) > 1 then
  compile endif
               if not wordpos(.col, .tabs) then                   -- check if on a tab col.
                  do i=1 to words(.tabs)              -- If we got shifted due to being inside a DBC,
                     if word(.tabs, i) > oldcol then  -- find the col we *should* be in, and
                        numspc = word(.tabs, i) - oldcol  -- set numspc according to that.
                        leave
                     endif
                  enddo
               endif
  compile if EPM32
            elseif (.col // .tabs) <> 1 then
               numspc = .tabs - (oldcol+.tabs-1) // .tabs
            endif
  compile endif
         endif
      endif
 compile endif
      if numspc>0 then
         .col=oldcol
         keyin substr('',1,numspc)
      endif
   endif
compile endif
compile if EVERSION < 5
   call move_results_to_commandline()
compile endif
compile if TOGGLE_TAB
   endif
compile endif  -- TOGGLE_TAB


def up=
compile if WANT_SHIFT_MARKING & not EPM
   universal shift_flag
compile endif
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
compile if WANT_SHIFT_MARKING & not EPM
   call begin_shift(startline, startcol, shift_flag)
compile endif
compile if RESPECT_SCROLL_LOCK
  if scroll_lock() then
     executekey s_F3  -- Scroll up
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
compile if WANT_SHIFT_MARKING & not EPM
   call end_shift(startline, startcol, shift_flag, 0)
compile endif

compile if WANT_SHIFT_MARKING & EPM
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

compile if EPM  -- Standard PM clipboard functions.
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
compile endif

compile if WANT_STREAM_MODE
defproc updownkey(down_flag)
   universal save_cursor_column
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
   if stream_mode then
 compile endif
      lk = lastkey(1)
 compile if EPM
      updn = pos(leftstr(lk,1),\x18\x16) & pos(substr(lk,2,1),\x02\x0A\x12)   -- VK_DOWN or VK_UP, plain or Shift or Ctrl
 compile else
      updn = substr(lk,1,1)=\0 & pos(substr(lk,2,1),\x48\x50\x98\xA0\x8d\x91) -- Up, down, a_up, a_down, c_up, c_down
 compile endif
      if not updn then save_cursor_column = .col; endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   endif
 compile endif

   if down_flag then down else up endif

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

