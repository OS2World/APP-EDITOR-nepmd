/**********************************************************************/
/*                             REXKEYS.E                              */
/*                                                                    */
/* The c_enter and space bar keys have been defined to do specific    */
/* REXX syntax structures.                                            */
/*                                                                    */
/* Based on EKEYS.E (part of the base E3 code)                        */
/* Written by B. Thompson, 22 Sep 1987                                */
/*                                                                    */
/**********************************************************************/
/*  Updated by Larry Margolis for EOS2 and EPM.  To include, set in   */
/*  your MYCNF.E:   REXX_SYNTAX_ASSIST = 1                            */
/*                                                                    */
/**********************************************************************/

const
compile if not defined(REXX_SYNTAX_INDENT)
   REXX_SYNTAX_INDENT = SYNTAX_INDENT
compile endif
compile if not defined(TERMINATE_COMMENTS)
   TERMINATE_COMMENTS = 0
compile endif
compile if not defined(REXX_KEYWORD_HIGHLIGHTING)
   REXX_KEYWORD_HIGHLIGHTING = 0
compile endif
compile if not defined(WANT_END_COMMENTED)
   WANT_END_COMMENTED = 1
compile endif
compile if not defined(REXX_EXTENSIONS)  -- Keep in sync with TAGS.E
   REXX_EXTENSIONS = 'BAT CMD ERX EXC EXEC XEDIT REX REXX VRX'
compile endif
compile if not defined(REXX_SYNTAX_CASE)
   REXX_SYNTAX_CASE = 'lower'
compile endif
compile if not defined(REXX_SYNTAX_FORCE_CASE)
   REXX_SYNTAX_FORCE_CASE = 0
compile endif
compile if not defined(REXX_SYNTAX_NO_ELSE)
   REXX_SYNTAX_NO_ELSE = 0
compile endif

compile if REXX_SYNTAX_CASE <> 'lower' & REXX_SYNTAX_CASE <> 'Mixed'
   *** Error: REXX_SYNTAX_CASE must be "Lower" or "Mixed"
compile endif

compile if INCLUDING_FILE <> 'EXTRA.E'  -- Following only gets defined in the base
compile if EVERSION >= '4.12'
defload
   universal load_ext
compile if EPM
   universal load_var
compile endif
compile if EVERSION >= '5.50'
   if wordpos(load_ext, REXX_EXTENSIONS) then
compile else
   if load_ext='BAT' | load_ext='CMD' | load_ext='EXC' | load_ext='EXEC' | load_ext='XEDIT' | load_ext='ERX' then
compile endif
      getline line,1
      if substr(line,1,2)='/*' or (line='' & .last = 1) then
         keys   rexx_keys
 compile if REXX_TABS <> 0
  compile if EPM
         if not (load_var // 2) then  -- 1 would be on if tabs set from EA EPM.TABS
  compile endif
         'tabs' REXX_TABS
  compile if EPM
         endif
  compile endif
 compile endif
 compile if REXX_MARGINS <> 0
  compile if EPM
   compile if EVERSION >= '6.01b'
         if not (load_var bitand 2) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile else
         if not (load_var%2 - 2*(load_var%4)) then  -- 2 would be on if tabs set from EA EPM.MARGINS
   compile endif
  compile endif
         'ma'   REXX_MARGINS
  compile if EPM
         endif
  compile endif
 compile endif
      endif
 compile if REXX_KEYWORD_HIGHLIGHTING and EPM32
      if .visible then
         'toggle_parse 1 epmkwds.cmd'
      endif
 compile endif
   endif
compile endif

compile if WANT_CUA_MARKING & EPM
 defkeys rexx_keys clear
compile else
 defkeys rexx_keys
compile endif

compile if EVERSION >= 5
def space=
compile else
def ' '=
compile endif
   universal expand_on
   if expand_on then
      if not rex_first_expansion() then
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
      if not rex_second_expansion() then
compile else
      if rex_second_expansion() then
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

def c_x=       -- Force expansion if we don't have it turned on automatic
   if not rex_first_expansion() then
      call rex_second_expansion()
   endif
compile endif  -- EXTRA

compile if not EXTRA_EX or INCLUDING_FILE = 'EXTRA.E'  -- Following gets defined in EXTRA.EX if it's being used
defproc rex_first_expansion            -- Called by space bar
   retc = 0                            -- Default, enter a space
compile if EVERSION >= 5
   if .line then
compile else
   if .line and (not command_state()) then
compile endif
      w=strip(textline(.line),'T')
      wrd=upcase(w)
compile if REXX_SYNTAX_FORCE_CASE
      lb=copies(' ', max(1,verify(w,' '))-1)  -- Number of blanks before first word.
compile endif
      If wrd='IF' Then
compile if REXX_SYNTAX_CASE = 'lower'
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'if then'
 compile else
         replaceline w' then'
 compile endif
 compile if not REXX_SYNTAX_NO_ELSE
         insertline substr(wrd,1,length(wrd)-2)'else',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'If Then'
 compile else
         replaceline w' Then'
 compile endif
 compile if not REXX_SYNTAX_NO_ELSE
         insertline substr(wrd,1,length(wrd)-2)'Else',.line+1
 compile endif
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
      elseif wrd='WHEN' Then
compile if REXX_SYNTAX_CASE = 'lower'
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'when then'
 compile else
         replaceline w' then'
 compile endif
compile else
 compile if REXX_SYNTAX_FORCE_CASE
         replaceline lb'When Then'
 compile else
         replaceline w' Then'
 compile endif
compile endif
         if not insert_state() then insert_toggle
compile if EVERSION >= '5.50'
             call fixup_cursor()
compile endif
         endif
      elseif wrd='DO' Then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         replaceline lb'do'
 compile else
         replaceline lb'Do'
 compile endif
compile endif
compile if WANT_END_COMMENTED
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr(wrd,1,length(wrd)-2)'end /* do */',.line+1
 compile else
         insertline substr(wrd,1,length(wrd)-2)'End /* Do */',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr(wrd,1,length(wrd)-2)'end',.line+1
 compile else
         insertline substr(wrd,1,length(wrd)-2)'End',.line+1
 compile endif
compile endif
;        if not insert_state() then insert_toggle endif
      endif
   endif
   return retc

defproc rex_second_expansion
   retc=1                               -- Default, don't insert a line
   if .line then
      getline line
compile if REXX_SYNTAX_FORCE_CASE
      parse value line with origword .
compile endif
      line = upcase(line)
      parse value line with firstword .
      c=max(1,verify(line,' '))-1  -- Number of blanks before first word.

      If firstword='SELECT' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         if origword<>'select' then replaceline overlay('select', textline(.line), c+1); endif
 compile else
         if origword<>'Select' then replaceline overlay('Select', textline(.line), c+1); endif
 compile endif
compile endif
compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c+REXX_SYNTAX_INDENT)'when',.line+1
         insertline substr('',1,c /*+REXX_SYNTAX_INDENT*/)'otherwise',.line+2
 compile if WANT_END_COMMENTED
         insertline substr('',1,c)'end  /* select */',.line+3
 compile else
         insertline substr('',1,c)'end',.line+3
 compile endif
compile else
         insertline substr('',1,c+REXX_SYNTAX_INDENT)'When',.line+1
         insertline substr('',1,c /*+REXX_SYNTAX_INDENT*/)'Otherwise',.line+2
 compile if WANT_END_COMMENTED
         insertline substr('',1,c)'End  /* Select */',.line+3
 compile else
         insertline substr('',1,c)'End',.line+3
 compile endif
compile endif
         '+1'                             -- Move to When clause
         .col = c+REXX_SYNTAX_INDENT+5         -- Position the cursor
      Elseif firstword = 'DO' then
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
         if origword<>'do' then replaceline overlay('do', textline(.line), c+1); endif
 compile else
         if origword<>'Do' then replaceline overlay('Do', textline(.line), c+1); endif
 compile endif
compile endif
         call einsert_line()
         .col=.col+REXX_SYNTAX_INDENT
      Elseif Pos('THEN DO',line) > 0 or Pos('ELSE DO',line) > 0 Then
         p = Pos('ELSE DO',line)  -- Don't be faked out by 'else doc = 5'
         if not p then
            p = Pos('THEN DO',line)
compile if REXX_SYNTAX_FORCE_CASE
 compile if REXX_SYNTAX_CASE = 'lower'
            s1 = 'then do'
         else
            s1 = 'else do'
 compile else
            s1 = 'Then Do'
         else
            s1 = 'Else Do'
 compile endif
compile endif
         endif
         if p & not pos(substr(line, p+7, 1), ' ;') then return 0; endif
compile if REXX_SYNTAX_FORCE_CASE
         if substr(textline(.line), p, 7)<>s1 then replaceline overlay(s1, textline(.line), p); endif
compile endif
         call einsert_line()
         .col=.col+REXX_SYNTAX_INDENT
compile if WANT_END_COMMENTED
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c)'end /* do */',.line+1
 compile else
         insertline substr('',1,c)'End /* Do */',.line+1
 compile endif
compile else
 compile if REXX_SYNTAX_CASE = 'lower'
         insertline substr('',1,c)'end',.line+1
 compile else
         insertline substr('',1,c)'End',.line+1
 compile endif
compile endif
compile if TERMINATE_COMMENTS
      Elseif pos('/*',line) then          -- Annoying to me, as I don't always
         if not pos('*/',line) then       -- want a comment closed on that line
            end_line; keyin' */'          -- Enable if you wish by uncommenting
         endif
         call einsert_line()
compile endif
      Else
         retc = 0                         -- Insert a blank line
      Endif
   Else
      retc=0
   Endif
   Return(retc)

compile endif  -- EXTRA
