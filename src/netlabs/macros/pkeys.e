/*                    PASCAL keys                       */
/*                                                      */
/* The enter and space bar keys have been defined to do */
/* specific Pascal syntax structures.                   */

const
compile if not defined(P_SYNTAX_INDENT)
   P_SYNTAX_INDENT = SYNTAX_INDENT
compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
   WANT_END_COMMENTED = 1
compile endif

compile if INCLUDING_FILE <> 'EXTRA.E'  -- Following only gets defined in the base
compile if EVERSION >= '4.12'
;  Keyset selection is now done once at file load time, not every time
;  the file is selected.  And because the DEFLOAD procedures don't have to be
;  kept together in the macros (ET will concatenate all the DEFLOADs the
;  same way it does DEFINITs), we can put the DEFLOAD here where it belongs,
;  with the rest of the keyset function.  (what a concept!)
;
defload
   universal load_ext
compile if EPM
   universal load_var
compile endif
   if load_ext='PAS' or load_ext='PASCAL' then
      keys   Pas_keys
 compile if P_TABS <> 0
  compile if EPM
      if not (load_var // 2) then  -- 1 would be on if tabs set from EA EPM.TABS
  compile endif
      'tabs' P_TABS
  compile if EPM
      endif
  compile endif
 compile endif
 compile if P_MARGINS <> 0
  compile if EPM
   compile if EVERSION >= '6.01b'
      if not (load_var bitand 2) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile else
      if not (load_var%2 - 2*(load_var%4)) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile endif
  compile endif
      'ma'   P_MARGINS
  compile if EPM
      endif
  compile endif
 compile endif
   endif
compile endif

compile if WANT_CUA_MARKING & EPM
 defkeys pas_keys clear
compile else
 defkeys pas_keys
compile endif

compile if EVERSION >= 5
def space=
compile else
def ' '=
compile endif
   universal expand_on
   if expand_on then
      if  not pas_first_expansion() then
         keyin ' '
      endif
   else
      keyin ' '
   endif
 compile if EVERSION >= '5.20'
   undoaction 1, junk                -- Create a new state
 compile endif

compile if ASSIST_TRIGGER = 'ENTER'
def enter=
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
   universal enterkey
 compile endif
compile else
def c_enter=
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
   universal c_enterkey
 compile endif
compile endif
   universal expand_on

compile if EVERSION >= 5
   if expand_on then
compile else
   if expand_on & not command_state() then
compile endif
compile if EVERSION >= '4.12'
      if not pas_second_expansion() then
compile else
      if pas_second_expansion() then
         call maybe_autosave()
      else
compile endif
compile if ASSIST_TRIGGER = 'ENTER'
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
         call enter_common(enterkey)
 compile else
         call my_enter()
 compile endif
compile else  -- ASSIST_TRIGGER
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
         call enter_common(c_enterkey)
 compile else
         call my_c_enter()
 compile endif
compile endif -- ASSIST_TRIGGER
      endif
   else
compile if ASSIST_TRIGGER = 'ENTER'
 compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''
      call enter_common(enterkey)
 compile else
      call my_enter()
 compile endif
compile else  -- ASSIST_TRIGGER
 compile if ENHANCED_ENTER_KEYS & c_ENTER_ACTION <> ''
      call enter_common(c_enterkey)
 compile else
      call my_c_enter()
 compile endif
compile endif -- ASSIST_TRIGGER
   endif

/* Taken out, interferes with some people's c_enter. */
;def c_enter=   /* I like Ctrl-Enter to finish the comment field also. */
;   getline line
;   if pos('{',line) then
;      if not pos('}',line) then
;         end_line;keyin' }'
;      endif
;   endif
;   down;begin_line

def c_x=       /* Force expansion if we don't have it turned on automatic */
   if not pas_first_expansion() then
      call pas_second_expansion()
   endif
compile endif  -- EXTRA

compile if not EXTRA_EX or INCLUDING_FILE = 'EXTRA.E'  -- Following gets defined in EXTRA.EX if it's being used
defproc pas_first_expansion
   retc=1
compile if EVERSION >= 5
   if .line then
compile else
   if .line and (not command_state()) then
compile endif
      getline line
      line=strip(line,'T')
      w=line
      wrd=upcase(w)
      if wrd='FOR' then
         replaceline w' :=  to  do begin'
compile if WANT_END_COMMENTED
         insertline substr(wrd,1,length(wrd)-3)'end; {endfor}',.line+1
compile else
         insertline substr(wrd,1,length(wrd)-3)'end;',.line+1
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      elseif wrd='IF' then
         replaceline w' then begin'
         insertline substr(wrd,1,length(wrd)-2)'end else begin',.line+1
compile if WANT_END_COMMENTED
         insertline substr(wrd,1,length(wrd)-2)'end; {endif}',.line+2
compile else
         insertline substr(wrd,1,length(wrd)-2)'end;',.line+2
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
     elseif wrd='WHILE' then
         replaceline w' do begin'
compile if WANT_END_COMMENTED
         insertline substr(wrd,1,length(wrd)-5)'end; {endwhile}',.line+1
compile else
         insertline substr(wrd,1,length(wrd)-5)'end;',.line+1
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      elseif wrd='REPEAT' then
         replaceline w
compile if WANT_END_COMMENTED
         insertline substr(wrd,1,length(wrd)-6)'until  ; {endrepeat}',.line+1
compile else
         insertline substr(wrd,1,length(wrd)-6)'until  ;',.line+1
compile endif
         call einsert_line()
         .col=.col+P_SYNTAX_INDENT
      elseif wrd='CASE' then
         replaceline w' of'
compile if WANT_END_COMMENTED
         insertline substr(wrd,1,length(wrd)-4)'end; {endcase}',.line+1
compile else
         insertline substr(wrd,1,length(wrd)-4)'end;',.line+1
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc pas_second_expansion
   retc=1
   if .line then
      getline line
      parse value upcase(line) with 'BEGIN' +0 a /* get stuff after begin */
      parse value line with wrd rest
      firstword=upcase(wrd)
      if firstword='FOR' then
         /* do tabs to fields of pascal for statement */
         parse value upcase(line) with a ':='
         if length(a)>=.col then
            .col=length(a)+4
         else
            parse value upcase(line) with a 'TO'
            if length(a)>=.col then
               .col=length(a)+4
            else
               call einsert_line()
               .col=.col+P_SYNTAX_INDENT
            endif
         endif
      elseif a='BEGIN' or firstword='BEGIN' or firstword='CASE' or firstword='REPEAT' then  /* firstword or last word begin?*/
;        if firstword='BEGIN' then
;           replaceline  wrd rest
;           insert;.col=P_SYNTAX_INDENT+1
;        else
            call einsert_line()
            .col=.col+P_SYNTAX_INDENT
;        endif
      elseif firstword='VAR' or firstword='CONST' or firstword='TYPE' or firstword='LABEL' then
         if substr(line,1,2)<>'  ' or substr(line,1,3)='   ' then
            getline line2
            replaceline substr('',1,P_SYNTAX_INDENT)||wrd rest  -- <indent> spaces
            call einsert_line();.col=.col+P_SYNTAX_INDENT
         else
            call einsert_line()
         endif
      elseif firstword='PROGRAM' then
         /* make up a nice program block */
         parse value rest with name ';'
         getline bottomline,.last
         parse value bottomline with lastname .
         if  lastname = 'end.' then
            retc= 0     /* no expansion */
         else
;           replaceline  wrd rest
            call einsert_line()
compile if WANT_END_COMMENTED
            insertline 'begin {' name '}',.last+1
            insertline 'end. {' name '}',.last+1
compile else
            insertline 'begin',.last+1
            insertline 'end.',.last+1
compile endif
         endif
      elseif firstword='UNIT' then       -- Added by M. Such
         /* make up a nice unit block */
         parse value rest with name ';'
         getline bottomline,.last
         parse value bottomline with lastname .
         if  lastname = 'end.' then
            retc= 0     /* no expansion */
         else
;           replaceline  wrd rest
            call einsert_line()
            insertline 'interface',.last+1
            insertline 'implementation',.last+1
compile if WANT_END_COMMENTED
            insertline 'end. {' name '}',.last+1
compile else
            insertline 'end.',.last+1
compile endif
         endif
      elseif firstword='PROCEDURE' then
         /* make up a nice program block */
         name= getheading_name(rest)
;        replaceline  wrd rest
         call einsert_line()
compile if WANT_END_COMMENTED
         insertline 'begin {' name '}',.line+1
         insertline 'end; {' name '}',.line+2
compile else
         insertline 'begin',.line+1
         insertline 'end;',.line+2
compile endif
      elseif firstword='FUNCTION' then
         /* make up a nice program block */
         name=getheading_name(rest)
;        replaceline  wrd rest
         call einsert_line()
compile if WANT_END_COMMENTED
         insertline 'begin {' name '}',.line+1
         insertline 'end; {' name '}',.line+2
compile else
         insertline 'begin',.line+1
         insertline 'end;',.line+2
compile endif
compile if TERMINATE_COMMENTS
      elseif pos('{',line) then
         if not pos('}',line) then
            end_line;keyin' }'
         endif
         call einsert_line()
compile endif
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc getheading_name          /*  (heading ) name of heading */
   return substr(arg(1),1,max(0,verify(upcase(arg(1)),
                                'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789')-1))
compile endif  -- EXTRA
