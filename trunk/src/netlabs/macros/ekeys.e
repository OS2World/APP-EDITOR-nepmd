/*                    E      keys                       */
/*                                                      */
/* The enter and space bar keys have been defined to do */
/* specific E3 syntax structures.                       */

const
compile if not defined(E_SYNTAX_INDENT)
   E_SYNTAX_INDENT = SYNTAX_INDENT
compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(E_KEYWORD_HIGHLIGHTING)
   E_KEYWORD_HIGHLIGHTING = 0
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
   if load_ext='E' then
      keys   E_keys
 compile if E_TABS <> 0
  compile if EPM
      if not (load_var // 2) then  -- 1 would be on if tabs set from EA EPM.TABS
  compile endif
      'tabs' E_TABS
  compile if EPM
      endif
  compile endif
 compile endif
 compile if E_MARGINS <> 0
  compile if EPM
   compile if EVERSION >= '6.01b'
      if not (load_var bitand 2) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile else
      if not (load_var%2 - 2*(load_var%4)) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile endif
  compile endif
      'ma'   E_MARGINS
  compile if EPM
      endif
  compile endif
 compile endif
 compile if E_KEYWORD_HIGHLIGHTING and EPM32
    if .visible then
      'toggle_parse 1 epmkwds.e'
    endif
 compile endif
   endif
compile endif

compile if WANT_CUA_MARKING & EPM
 defkeys e_keys clear
compile else
 defkeys e_keys
compile endif

compile if EVERSION >= 5
def space=
compile else
def ' '=
compile endif
   universal expand_on
   if expand_on then
      if  not e_first_expansion() then
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
      if not e_second_expansion() then
compile else
      if e_second_expansion() then
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
;   if pos('/*',line) then
;      if not pos('*/',line) then
;         end_line;keyin' */'
;      endif
;   endif
;   down;begin_line

def c_x=       /* Force expansion if we don't have it turned on automatic */
   if not e_first_expansion() then
      call e_second_expansion()
   endif
compile endif  -- EXTRA

compile if not EXTRA_EX or INCLUDING_FILE = 'EXTRA.E'  -- Following gets defined in EXTRA.EX if it's being used
defproc e_first_expansion
   /*  up;down */
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
         replaceline w' =  to'
         insertline substr(wrd,1,length(wrd)-3)'endfor',.line+1
         if not insert_state() then insert_toggle
         endif
         keyin ' '
      elseif wrd='IF' then
         replaceline w' then'
         insertline substr(wrd,1,length(wrd)-2)'else',.line+1
         insertline substr(wrd,1,length(wrd)-2)'endif',.line+2
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      elseif wrd='ELSEIF' then
         replaceline w' then'
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      elseif wrd='WHILE' then
         replaceline w' do'
         insertline substr(wrd,1,length(wrd)-5)'endwhile',.line+1
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
         keyin ' '
      elseif wrd='LOOP' then
         replaceline w
         insertline substr(wrd,1,length(wrd)-4)'endloop',.line+1
         call einsert_line()
         .col=.col+E_SYNTAX_INDENT
;     elseif wrd='DO' then
;        replaceline w
;        insertline substr(wrd,1,length(wrd)-2)'enddo',.line+1
;        call einsert_line()
;        .col=.col+E_SYNTAX_INDENT
      else
         retc=0
      endif
   else
      retc=0
   endif
   return retc

defproc e_second_expansion
   retc=1
   if .line then
      getline line
      parse value line with wrd rest
      firstword=upcase(wrd)
      if firstword='FOR' then
         /* do tabs to fields of pascal for statement */
         parse value upcase(line) with a '='
         if length(a)>=.col then
            .col=length(a)+3
         else
            parse value upcase(line) with a 'TO'
            if length(a)>=.col then
               .col=length(a)+4
            else
               call einsert_line()
               .col=.col+E_SYNTAX_INDENT
            endif
         endif
compile if EVERSION >= '5.50'
      elseif wordpos(firstword, 'IF ELSEIF ELSE WHILE LOOP DO DEFC DEFPROC DEFLOAD DEF DEFMODIFY DEFSELECT DEFMAIN DEFINIT DEFEXIT') then
compile else
      elseif firstword='IF' or firstword='ELSEIF' or firstword='WHILE' or firstword='LOOP' or firstword='DO' or firstword='ELSE' then
compile endif
         if pos('END'firstword, upcase(line)) then
            retc = 0
         else
            call einsert_line()
            .col=.col+E_SYNTAX_INDENT
            if /* firstword='LOOP' | */ firstword='DO' then
               insertline substr(line,1,.col-E_SYNTAX_INDENT-1)'end'lowcase(wrd), .line+1
            endif
         endif
compile if TERMINATE_COMMENTS
      elseif pos('/*',line) then
;     elseif substr(firstword,1,2)='/*' then  /* see speed requirements */
         if not pos('*/',line) then
            end_line;keyin' */'
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

compile endif  -- EXTRA
