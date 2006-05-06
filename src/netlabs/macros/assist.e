/****************************** Module Header *******************************
*
* Module Name: assist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: assist.e,v 1.13 2006-05-06 11:20:47 aschn Exp $
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
Todo:
-  Fix bug for LaTeX: \begin {...} is not recognized.
-  Optional: if corresponding string is not on screen, just give a msg
   like in defproc balance. When 'just a msg' is selected, then give the
   user the possibility to go (with a special key combination) to that
   pos although (and back again). So we can get rid of BALANCE.E.
*/

/*****************************************************************************/
/*  Assist interface for E3      Ralph Yozzo, Larry Margolis                 */
/*                                                                           */
/*  This macro is intended for use with programming language                 */
/*  which have tokens which must be balanced to compile correctly.           */
/*  We shall call these tokens "balanceable tokens" or BalTok for            */
/*  short.                                                                   */
/*                                                                           */
/*  The functions provided include moving from an opening token              */
/*  (e.g., (, {, [ ) to a closing token (e.g., ), }, ] ) and vice versa.     */
/*                                                                           */
/*  KEYS:                                                                    */
/*  Ctrl-[, Ctrl-], Ctrl-8  -- move to corresponding BalTok)                 */
/*                                                                           */
/*  CONSTANTS:                                                               */
/*  gold -BalTok tokens  are defined in the const gold and additional        */
/*        tokens may be added.                                               */
/*                                                                           */
/*  Example:                                                                 */
/*     if ((c=getch())=='c'                                                  */
/*      &&(d=complicatedisntit(e))){                                         */
/*      lookforbracket();                                                    */
/*     }                                                                     */
/* In the above program segment if one places the cursor on an opening       */
/* parenthesis and presses Ctrl-[ the cursor will move to the corresponding  */
/* closing parenthesis if one exists.  Pressing Ctrl-[ again will reverse    */
/* the process.                                                              */
/*                                                                           */
/* Modified by Larry Margolis to use the GREP option of Locate to search     */
/* for either the opening or closing token, rather than checking a line at   */
/* a time.  I also changed the key from Ctrl-A to Ctrl-[ or -], which are    */
/* newly allowed as definable keys, and deleted the matching of /* and */.   */
/* (The GREP search is much faster than the way Ralph did it, but doesn't    */
/* let you match either of 2 strings.)  Finally, the user's previous search  */
/* arguments are saved and restored, so Ctrl-F (repeatfind) will not be      */
/* affected by this routine.                                                 */
/*                                                                           */
/* Updated by LAM to use EGREP to also handle #if, #endif, etc. and COMPILE  */
/* IF, COMPILE ENDIF, etc.                                                   */
/*                                                                           */
/* 1995/02/21  Updated by LAM to also handle SCRIPT list tags and /* */.     */
/* 1995/02/22  Updated by LAM to also handle SGML tags.                      */
/*                                                                           */
/* 1999/03/15  Updated by Petr Mikulik, http://www.sci.muni.cz/~mikulik/, to */
/*             also handle TeX tokens: \if... \else \fi; \begin... \end...;  */
/*             \if... \else \fi; \begin{ \end{; \left \right                 */
/*             This patch is part of the "pmCSTeX for EPM" package, see      */
/*             http://www.sci.muni.cz/~mikulik/os2/pmCSTeX.html              */
/*****************************************************************************/

; Included TeX extensions for the passist procedure by Petr Mikulik from his
; PMCSTeX package.
; Added c_8 for german keyboards.

compile if not defined(SMALL)  -- If SMALL not defined, then being separately compiled.
   define INCLUDING_FILE = 'ASSIST.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

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

   EA_comment 'Linkable bracket-matching routines.'

defmain
   call passist()

compile endif  -- not defined(SMALL)

--  NOTE: The logic below relies on GOLD being defined with the left "brackets"
--        in the odd positions and the right "brackets" in the even positions.
const GOLD = '(){}[]<>'  -- Parens, braces, brackets & angle brackets.

INCLUDE_NMAKE32 = 1   -- 0 means do not accept NMAKE32-specific directives

defc assist, passist
   call passist()

;
;  a temporary cmd to dynamically set the global variable 'jbsdbglist' which is
;  used by the jbsdprintf proc below
;
defc t8
   universal jbsdbglist
   string = arg(1)
;    if jbsdbglist = '' then
;       if string <> '' then
;          'os2 pmprintf'
;       endif
;    endif
   jbsdbglist = string

defproc jbsdprintf(routine, msg)
; ---------------------------------------------------------------------------
;  This routine will call dprintf only for "routines" (i.e. first param being
;  sent to dprintf.  This means that calls to dprintf turned on and off by
;  simply adding or deleting the "routine" from the list below (instead of
;  adding or removing/commenting the various calls.  The calls to jbsdprintf
;  can be left in until all debugging is complete.
; ---------------------------------------------------------------------------
   universal jbsdbglist
   --jbsdbglist = 'comm lit2 1line passist array'
   --jbsdbglist = '1line'
   --jbsdbglist = 'passist'
   if wordpos(routine, jbsdbglist) then
      call dprintf(routine, msg)
   endif

; ---------------------------------------------------------------------------
; id            = found word under cursor (or beneath the cursor in some cases)
; fIntermediate = set to 1 if id is an intermediate conditional token
;                 (e.g. 'else', but not 'if' or 'endif')
; clist         = a space delimited list of substrings to match on
; clen          = the length of the substrings in clist
; coffset       = offset from cursor pos to substring to match
; fForward      = a flag to indicate which direction to search
;                 1 = forward, 0 = backward
; search        = string for locate command, without seps and options,
;                 egrep will be used
defproc passist
   call psave_pos(savepos)
   getsearch search_command -- Save user's search command.
   call jbsdprintf("passist", "Initial cursor: ".line",".col)

   passist_rc = inside_comment2(comment_data)
   call jbsdprintf("passist", "comment return:" passist_rc comment_data)
   if passist_rc = 2 then
      parse value comment_data with CommentStartLine CommentStartCol CommentStartLen CommentEndLine CommentEndCol CommentEndLen
      if .line = CommentStartLine and .col - CommentStartCol < CommentStartLen then   -- if cursor on start
         .line = CommentEndLine                                                       -- move to the end
         .col  = CommentEndCol
         passist_rc = -1                    -- rc = -1 means cursor on the endpint of an MLC
      elseif .line = CommentEndLine and .col >= CommentEndCol then                    -- if cursor on end
         .line = CommentStartLine                                                     -- move to the start
         .col  = CommentStartCol
         passist_rc = -1                    -- rc = -1 means cursor on the endpint of an MLC
      endif
   endif

   if not passist_rc then
      if inside_literal2() then
         passist_rc = 3
      endif
   endif

   if not passist_rc then
      -- get c = char at cursor
      c = substr(textline(.line), .col, 1)
      -- JBSQ: Why this code??  It moves the cursor.
      -- if c = space, then try it 1 col left
      if c == ' ' & .col > 1 then
         left
         c = substr(textline(.line),.col,1)
      endif

--    id           = ''
      n             = 1
      fCase         = 1                                          -- respect case is default
      coffset       = 0                                          -- default
      clen          = 1                                          -- default
      fIntermediate = 0                                          -- default

      clist    = ''
      id       = ''
      fForward = 1
      search   = ''
      startcol = 1
      endcol   = 1


      CurMode      = GetMode()

      if pos(c, '{}') and CurMode = 'RC' then  -- Braces, '{}', can be matched with
         k = 0                                 -- BEGIN and END in RC files.  So they
      else                                     -- need to be handled separately.
         k = pos(c, GOLD)            --  '(){}[]<>'
      endif
      if k then
      -- if c = bracket defined in GOLD, then set search to the corresponding char out of GOLD
         leftbracket = substr(GOLD,(k+1)%2*2-1,1)
         if leftbracket = '[' then
--          search = '[' || leftbracket || '\' || substr(GOLD,(k+1)%2*2,1) || ']'
            search = '[[\]]'
         else
            search = '[' || leftbracket || substr(GOLD, (k+1)%2*2, 1) || ']'
         endif
         clist = c
         fForward = k // 2
      else
         NumArgs = fForward fCase fIntermediate StartCol EndCol cLen cOffset n
         passist_rc = Assist2( NumArgs, id, cList, search)
         parse value NumArgs with fForward fCase fIntermediate StartCol EndCol cLen cOffset n
      endif -- if GOLD/not gold

      if not passist_rc then
         if fCase then
            case = 'e'  -- case-sensitive
         else
            case = 'c'  -- not case-sensitive
         endif
         if fForward then
            direction = '+F'
         else
            direction = '-R'
         endif
         call jbsdprintf("passist", "id clist fForward fIntermediate:" id "'"clist"'" fForward fIntermediate)
         call jbsdprintf("passist", 'search: xcom l /'search'/x'case||direction)

         if fIntermediate then
            -- search begin of condition
            setsearch 'xcom l '\1 || search || \1 || 'x' || case || direction
            'postme circleit' .line startcol endcol
         else
            --'L '\1 || search\1'x'case||direction
            'xcom l '\1 || search || \1 || 'x' || case || direction
            --'postme circleit' .line startcol endcol  -- this one should not be highlighted
            -- designed for function_name(...)  <-- function_name is highlighted, not the ( and ).
         endif

         passist_rc = passist_search( clist, case, coffset, clen, n)
      endif                                 -- if OK to search
   endif

   if passist_rc > 0 then
      call prestore_pos(savepos)
      if passist_rc = 1 then
         sayerror "Invalid: One-line comment starts in column "comment_data
      elseif passist_rc = 2 then
         sayerror "Invalid: Multi-line comment starting at "CommentStartLine","CommentStartCol" and ending at "CommentEndLIne","CommentEndCol
      elseif passist_rc = 3 then
         sayerror "Invalid: Cursor located within a literal."
      elseif passist_rc = 4 then
         sayerror "Invalid: Cursor located on an unknown token."
      elseif passist_rc = 5 then
         sayerror UNBALANCED_TOKEN__MSG
      else
         sayerror "Unknown rc: "passist_rc
      endif
   else
      sayerror 1
      newline = .line; newcol = .col
      call prestore_pos(savepos)
      .col = newcol
      .lineg = newline  -- go to line newline without scrolling
      .line  = newline  -- scroll when outside of window
      --right; left                      -- scroll_to_cursor
   endif
   call prune_assist_array()
   setsearch search_command           -- Restores user's command so Ctrl-F works.
   return

; ---------------------------------------------------------------------------
; id            = found word under cursor (or beneath the cursor in some cases)
; fIntermediate = set to 1 if id is an intermediate conditional token
;                 (e.g. 'else', but not 'if' or 'endif')
; clist         = a space delimited list of substrings to match on
; clen          = the length of the substrings in clist
; coffset       = offset from cursor pos to substring to match
; fForward      = a flag to indicate which direction to search
;                 1 = forward, 0 = backward
; search        = string for locate command, without seps and options,
;                 egrep will be used
defproc Assist2( var NumArgs, var id, var cList, var search)

   passist_rc = 0
   parse value NumArgs with fForward fCase fIntermediate StartCol EndCol cLen cOffset n
   CurMode = GetMode()

   getline line
   -- if not a bracket char
                  -- Add '.' to default token_separators & remove ':' for GML markup.
   -- build the separator list for find_token

;     The following 4 of 5 lines are commented out because, with the new comment-handling
;     code above, they should no longer be relevant
;  if pos(c, '*/') then
;     seps = '/*'
;  else
      seps = ' ~`!.%^&*()-+=][{}|\;?<>,''"'\t
;  endif

-- begin addition for TeX
   if CurMode = 'TEX' then
      if substr(line, .col, 1) = '\' then right endif   -- ...move cursor right if it is on \backslash
   endif
-- end addition for TeX

   -- get the word under cursor and return startcol and endcol
   -- stop at separators = arg(3)
   -- stop at double char separators = arg(4)
   if not find_token(startcol, endcol,  seps, '/* */') then
      passist_rc = 4
   else
      call jbsdprintf("passist", "Initial token start,end: "startcol","endcol)
      if startcol > 1 then
         prevchar = substr(line, startcol-1, 1)
         if prevchar = '<' then
            -- add '<' to found word if it is on the left side of it
            -- JBSQ: Why?  Is this for HTML tags like <SCRIPT and </SCRIPT>, <TD and </TD>, etc.?
            startcol = startcol - 1
         elseif prevchar = '\' then
            if CurMode = 'TEX' then
               --//PM TeX macros are preceded by \backslash which is also separator
               -- add '\' to found word if it is on the left side of it
               startcol = startcol - 1
            endif
         endif
      elseif startcol = 1 then            -- if cursor is on the first column of a MAKE directive
         if leftstr(line, 1) = '!' then   -- "shift" the id to the following token
            if CurMode = 'MAKE' then
               newstart = verify(line, ' ' || \t, 'N', 2)
               if newstart then
                  newend = verify(line || ' ', seps, 'M', newstart)  -- JBSQ: Should find_token be called again here instead?
                  if newend then
                     startcol = newstart
                     endcol   = newend - 1
                  endif
               endif
            endif
         endif
      endif
      -- id = found word
      id = substr(line, startcol, (endcol-startcol)+1)
      --call jbsdprintf("passist", "'Processed' token start,end: "startcol","endcol)
      call jbsdprintf("passist", "Initial token : '"id"'")

      -- JBSQ: What is this for?
      -- if id = '.', then go 1 col left and search again
      if id='.' & .col > 1 then
         sayerror "id = '.'"
         left
         if find_token(startcol, endcol) then
            id = substr(line, startcol, (endcol-startcol)+1)
         endif --test
      endif

      if 0 then
         -- just a placeholder so the following elseif's can be freely reordered

      ---------------------------------------------------------------------------------------------
      elseif CurMode = 'E' then
         if startcol > 1 then
            if substr(line, startcol - 1, 2) = '*/' then  -- allow */ just before token
               startcol = startcol + 1
               id = substr(line, startcol, (endcol - startcol + 1))
            /* test */endif/* test */           -- JBSQ: Apparently E allow comments as "word" delimiters
         endif
         if rightstr(id, 1) = ';' then              -- allow ; just after token
            id = substr(line, startcol, (endcol-startcol))
         elseif endcol < length(line) then
            temp = substr(line, endcol, 2)
            if temp = '/*' or temp = '--' then      -- allow /* or -- just after token
               id = substr(line, startcol, (endcol-startcol))
               endcol = endcol - 1
            endif
         endif
         --call jbsdprintf("passist", "E Token after : '"id"'")
         fCase = 0                                 -- Case insensitive for all E tokens
         id = lowcase(id)
         line = lowcase(line)
         if 0 then
            -- another placeholder

         ---- E conditions: if, else, elseif, endif --------------------------------------------------
         elseif wordpos( id, 'if endif else elseif') then
            search = '(^|[ \t]|(\*/))\c(end)?if([; \t]|(--)|(/\*)|$)'
            clist= leftstr(id, 1)
            fForward = (clist <> 'e')
             if fForward then  -- move to beginning
                .col = startcol
             else       -- move to end, so first Locate will hit this instance.
                .col = endcol
             endif
            fIntermediate = (substr(id, 2, 1) = 'l')

         elseif wordpos( id, 'loop endloop') then
            search = '(^|[ \t]|(\*/))\c(end)?loop([; \t]|(--)|(/\*)|$)'
            clist = leftstr( id, 1)
            fForward = (clist <> 'e')
            if fForward then  -- move to beginning
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               .col = endcol
            endif

         elseif wordpos( id, 'for endfor') then
            search = '(^|[ \t]|(\*/))\c(end)?for([; \t]|(--)|(/\*)|$)'
            clist = leftstr( id, 1)
            fForward = (clist <> 'e')
            if fForward then  -- move to beginning
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               .col = endcol
            endif

         ---- E compiler directives: compile if, compile else, compile elseif, compile endif ---------
         elseif id = 'compile' then
            temp = (substr(line, pos(id, line)))
            call jbsdprintf("passist", "Initial temp: "temp)
            do while (pos('/*', temp) > 0) and (pos('*/', temp) > 0)
               temp = substr(temp, pos('*/', temp))
               call jbsdprintf("passist", "Intermediate temp: "temp)
            enddo
            call jbsdprintf("passist", "Final temp: "temp)
            if (words(temp) = 0) then
               passist_rc = 5
            else
               lcword2 = word(temp, 2)
               call jbsdprintf("passist", "lcword2: "lcword2)
               if wordpos(lcword2, 'if endif else elseif') then
                  search = '^[ \t]*compile[ \t]*(/\*.*\*/)*[ \t]*\c(end)?if([; \t]|(--)|(/\*)|$)'
                  clist = leftstr(lcword2, 1)
                  fForward = (clist <> 'e')
                  if fForward then  -- move to beginning
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     end_line
                  endif
                  fIntermediate = (substr(lcword2, 2, 1) = 'l')
               else
                  passist_rc = 5
               endif
            endif

         elseif wordpos( id, 'do while end enddo endwhile') then
            if     (id = 'end') then
               search = '(^|[ \t]|(\*/))\c(do|end|enddo)([; \t]|(--)|(/\*)|$)'
            elseif (id = 'enddo') then
               search = '(^|[ \t]|(\*/))\c(do|end|enddo)([; \t]|(--)|(/\*)|$)'
            elseif (id = 'endwhile') then
               search = '(^|[ \t]|(\*/))\c(end)?while([; \t]|(--)|(/\*)|$)'
            else                                    -- check for do and/or while
               whilepos = wordpos('while', line)
               dopos    = wordpos('do', line)
               if (not dopos) or (whilepos and (whilepos < dopos)) then -- while or while ... do?
                  search = '(^|[ \t]|(\*/))\c(end)?while([; \t]|(--)|(/\*)|$)'
                  startcol = whilepos
                  endcol = whilepos + 4
               else                                      --    do or do ... while
                  search = '(^|[ \t]|(\*/))\c(do|end|enddo)([; \t]|(--)|(/\*)|$)'
                  startcol = dopos
                  endcol   = dopos + 1
               endif
compile if 0
               if whilepos and dopos then           -- if both
                  if whilepos < dopos then          --    while ... do ?
                     search = '(^|[ \t]|(\*/))\c(end)?while([; \t]|(--)|(/\*)|$)'
                     startcol = whilepos
                     endcol = whilepos + 4
                  else                              --    do ... while
                     search = '(^|[ \t]|(\*/))\c(do|end|enddo)([; \t]|(--)|(/\*)|$)'
                     startcol = dopos
                     endcol   = dopos + 1
                  endif
               else
                  if dopos then                     -- do
                     search = '(^|[ \t]|(\*/))\c(do|end|enddo)([; \t]|(--)|(/\*)|$)'
                  else                              -- while
                     search = '(^|[ \t]|(\*/))\c(end)?while([; \t]|(--)||(/\*)$)'
                  endif
               endif
compile endif
               call jbsdprintf("passist", "Whilepos: "whilepos "Dopos: "dopos "Search: "search)
            endif
            clist = leftstr( id, 1)
            call jbsdprintf("passist", "clist: "clist)
            fForward = (clist <> 'e')
            if fForward then  -- move to beginning
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               .col = endcol
            endif

         elseif wordpos( id, 'leave iterate') then
            search = '(^|[ \t]|(\*/))\c(do|end|enddo|loop|endloop|for|endfor|endwhile)([; \t]|(--)|(/\*)|$)'
            fForward = 0
            clist = 'e'
            clen = 1
            .col = endcol
            fIntermediate = 1
         else -- not a known balanceable E token
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      elseif Curmode = 'C' or CurMode = 'JAVA' or CurMode = 'RC' then
         if 0 then
            --placeholder

         elseif wordpos(id, 'do try') then
            --  this code might be expanded to <anytoken> { .... }
            if CurMode <> 'RC' then
               setsearch 'xcom l /[{;]/xe+F'   -- does following a '{' precede a ';'?
               passist_rc = passist_search('{ ;', 'e', 0, 1, /* stop on first 'hit' */ -1)
               if passist_rc then
                  passist_rc = 5
               else
                  call jbsdprintf("passist", "token {} '{;' search found: "substr(textline(.line), .col, 1))
                  if substr(textline(.line), .col, 1) = '{' then -- found the braces
                     search  = '[{}]'
                     fForward = 1
                     clist = '{'
                  else
                     passist_rc = 5           -- token without braces
                  endif
               endif
            else
               passist_rc = 4
            endif

         elseif id = 'while' then
            if CurMode <> 'RC' then
               setsearch 'xcom l /[()]/xe+F'     -- find the end of the conditional
               passist_rc = passist_search('(', 'e', 0, 1, 0)
               if passist_rc then                -- no conditional??
                  passist_rc = 5
               else
                  nextchar = next_nonblank_noncomment_nonliteral()
                  if not nextchar then
                     passist_rc = 5
                  else
                     call jbsdprintf("passist", "while {; search found: "nextchar)
                     if nextchar = '{' then      -- must be while loop (i.e. NOT do/while) with braces
                        search  = '[{}]'
                        fForward = 1
                        clist   = '{'
                     elseif nextchar = ';'  then -- cursor is on the 'while' of a do/while loop
                        search  = '\{|\}|(($|[ \t])\cdo([ \t]|$))'
                        fForward = 0
                        clist   = '}'
                        n = 2
                     else                        -- cursor is on a one-statement while loop
                        passist_rc = 5           -- no braces follow, so JBSQ: unbalanceable?
                     endif
                  endif
               endif
            endif

         elseif wordpos(id, '#if #ifdef #ifndef #endif #else #elif') then
            if CurMode <> 'JAVA' then
               search = '\#((if((n?def)?))|endif)([ \t]|$)'
               if CurMode = 'C' then
                  search = '^[ \t]*\c' || search
               elseif startcol = 1 then  -- RC directives must start in column one
                  search = '^' || search
               else
                  passist_rc = 5
               endif
               clist = substr(id, 2, 1)
               fForward = (clist <> 'e')
               if fForward then  -- move to beginning
                  .col = startcol
               else       -- move to end, so first Locate will hit this instance.
                  .col = endcol
               endif
               coffset = 1
               fIntermediate = (substr(id, 3, 1) = 'l')
            else
               passist_rc = 5
            endif
/*
   The following code should work for break/continue statements within nested do and for loops
   which have braces.  Problems arise if there are do's or for's without braces between the
   break/continue and the enclosing loop.  Also problems arise if the enclosing loop is a
   while loop.

   The solution, if it is worth it, is to code the entire search here so that these different
   variations of loops can be handled correctly.

         elseif wordpos(id, 'break continue' then
            if CurMode <> 'RC' then
               search       = '([{}])|((^|[ \t])\c(do|for)([ \t]|$))'
               fForward      = 0
               clist        = '}'
               fIntermediate = 1
            else
               passist_rc = 4
            endif
*/
         elseif CurMode = 'RC' then
            -- All remaining RC tokens here
            fCase = 0   -- RC files are case insensitive, except for direcives (#if, #define, etc.)
            id = lowcase(id)
            if wordpos(id, '{ } begin end') then
               search = '(\{|\}|((^|[ \t])(begin|end)([ \t;]|$))'
               fForward = (wordpos(id, '{ begin') > 0)
               if fForward then  -- move to beginning
                  .col = startcol
                  clist = '{ b'
               else       -- move to end, so first Locate will hit this instance.
                  .col = endcol
                  clist = '} e'
               endif
            else
               passist_rc = 5
            endif

         else
            -- All remaining C/JAVA tokens here
            idlist = 'case default default:'
            if CurMode = 'JAVA' then
               idlist = idlist 'finally'
            endif
            if wordpos(id, idlist) then
               search = '[{}]'
               fForward = 0
               clist = '}'
               fIntermediate = 1
            else
               -- This code seems to handle matching the beginning and end of
               --    a) functions when the cursor is on a token preceding the parameter list
               --    b) 'if' when the 'if' has following braces
               --    c) 'for' when the 'for' has following braces
               --    d) 'switch' statements
               --    e) anything of the structure: token (    )  { ... }
               --        e.g. catch (    ) { ... }

               -- Check for next_nonblank_noncomemnt_nonliteral() = '(' first?
               -- (This would force the cursor to actually be on the function name.
               -- The current code allows the cursor on any nonblank, noncomment,
               -- nonliteral character preceding the parameter list.)
               setsearch 'xcom l /[();]/xe+F'     -- find the ending ')' or ;
               passist_rc = passist_search('(', 'e', 0, 1, 0)
               if not passist_rc and substr(textline(.line), .col, 1) = ')' then -- no conditional??
                  passist_rc = 4
                  nextchar = next_nonblank_noncomment_nonliteral()
                  if nextchar then
                     call jbsdprintf("passist", "Generic token () {; search found: "nextchar)
                     if nextchar = '{' then      -- structure is: token (    ) { ... }
                        search = '[{}]'
                        fForward = 1
                        clist = '{'
                        passist_rc = 0
                     endif
                  endif
               else
                  passist_rc = 4
               endif
            endif
         endif

      ---------------------------------------------------------------------------------------------
      elseif CurMode = 'MAKE' then
         fCase = 0                      -- Case insensitive for all MAKE tokens
         id = lowcase(id)
         -- Currently ALL balanceable MAKE must be on a line with '!' in column 1
         -- and if there are any characters between the '!' and the token that they
         -- be whitespace.
         if leftstr(line, 1) = '!' then
            if startcol > 2 then         -- Are there characters between '!' and token?
               if verify(substr(line, 2, startcol - 2), ' ' || \t) then
                  passist_rc = 4
                  id = ''                -- Disable further processing
               endif
            endif
            if 0 then
               -- placeholder
compile if INCLUDE_NMAKE32
            elseif wordpos(id, 'if ifdef ifndef endif else elif elseif') then
compile else
            elseif wordpos(id, 'if ifdef ifndef endif else') then
compile endif
               search = '^![ \t]*\c(if((n?def)?)|endif)([ \t]|$)'
               clist = leftstr(id, 1)
               fForward = (clist = 'i')
               if fForward then  -- move to beginning
                  .col = 1
               else       -- move to end, so first Locate will hit this instance.
                  .col = endcol
               endif
compile if INCLUDE_NMAKE32
               fIntermediate = (wordpos(id, 'else elif elseif') > 0)
compile else
               fIntermediate = (id = 'else')
compile endif
compile if INCLUDE_NMAKE32
            elseif wordpos(id, 'foreach endfor') then               -- NMAKE32
               search = '^![ \t]*\c(foreach|endfor)([ \t]|$)'
               clist = leftstr(id, 1)
               fForward = (clist = 'f')
               if fForward then  -- move to beginning
                  .col = 1
               else       -- move to end, so first Locate will hit this instance.
                  .col = endcol
               endif
               fIntermediate = (wordpos(id, 'else elif elseif') > 0)
compile endif
            else
               passist_rc = 4
            endif
         else
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      elseif CurMode = 'REXX' then
      ---- REXX conditions: if, else --------------------------------------------------------------
         fCase = 0                      -- Case insensitive for all REXX tokens
         id = lowcase(id)
         if 0 then
            -- another placeholder
         elseif wordpos( id, 'do end select when otherwise') then
            search = '(^|[ \t])\c(do|end|select)([ \t]|$)'
            fForward = (wordpos(id, 'do select') > 0)
            if fForward then  -- move to beginning
               clist = 'do se'
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               clist = 'en'
               .col = endcol
            endif
            clen  = 2
            fIntermediate = (wordpos(id, 'when otherwise') > 0)
         elseif wordpos( id, 'if else') then
            -- JBSQ: How is this supposed to work?  If's don't always have else's
            search = '(^|[ \t])(if|else)([ \t)|$)'
            clist = leftstr( id, 1)
            fForward = (clist <> 'e')
            if fForward then  -- move to beginning
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               .col = endcol
            endif
         else -- not a known balanceable REXX token
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      elseif CurMode = 'IPF' then
;          if wordpos(lowcase(id), ':ol :eol :ul :eul :sl :esl :dl :edl :parml :eparml') &
;              pos(substr(line, endcol+1, 1), '. ') then
         if pos(':', id) > 1 then  -- <text>:tag, separate the :tag
            id = substr(id, pos(':', id))
         endif
         if length(line) > endcol then
            if (pos(substr(line, endcol+1, 1), '. ')) then
               IPFBeginTags = ':artlink :caution :cgraphic :ctrldef :fn :hide'
               IPFBeginTags = IPFBegintags ':hp1 :hp2 :hp3 :hp4 :hp5 :hp6 :hp7 :hp8 :hp9'
               IPFBeginTags = IPFBegintags ':lines :link :nt :userdoc :warning :xmp'
               IPFEndTags   = ':eartlink :ecaution :ecgraphic :ectrldef :efn :ehide'
               IPFEndTags   = IPFEndTags ':ehp1 :ehp2 :ehp3 :ehp4 :ehp5 :ehp6 :ehp7 :ehp8 :ehp9'
               IPFEndTags   = IPFEndTags ':elines :elink :ent :euserdoc :ewarning :exmp'
               IPFTags      = IPFBeginTags IPFEndTags
               call jbsdprintf("passist", "IPF ID wordpos: "wordpos(id, IPFTags))
               call jbsdprintf("passist", "IPF Tags: "IPFTags)
               if wordpos(id, IPFTags) then
                  clist = substr(id, 2, 1)  -- Character to check to see if it's an end tag
                  fForward = (clist <> 'e')          -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     id = substr(id, 2)
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     id = substr(id, 3)
                  endif
                  search = '\:\ce?'id'(\.| )'
               elseif wordpos(id, ':ol :ul :sl :eol :eul :esl :li :lp') then
                  fIntermediate = (wordpos(id, ':li :lp') > 0)
                  fForward = (wordpos(id, ':ol :ul :sl') > 0)    -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     id = substr(id, 2)
                     clist = 'ol ul sl'
                     clen = 2
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     id = substr(id, 3)
                     clist = 'eol eul esl'
                     clen  = 3
                  endif
                  search = '\:\ce?(o|u|s)l(\.| )'
               elseif wordpos(id, ':table :etable :row :c') then
                  fIntermediate = (wordpos(id, ':row :c') > 0)
                  fForward = (id = ':table')         -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     clist = 'table'
                     clen = 5
                     id = substr(id, 2)
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     clist = 'etable'
                     clen = 6
                     id = substr(id, 3)
                  endif
                  search = '\:\ce?table(\.| )'
               elseif wordpos(id, ':parml :eparml :pt :pd') then
                  fIntermediate = (wordpos(id, ':pt :pd') > 0)
                  fForward = (id = ':parml')          -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     id = substr(id, 2)
                     clist = 'parml'
                     clen  = 5
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     id = substr(id, 3)
                     clist = 'eparml'
                     clen = 6
                  endif
                  search = '\:\ce?parml(\.| )'
               elseif wordpos(id, ':dl :dthd :ddhd :dt :dd :edl') then
                  fIntermediate = (wordpos(id, ':dthd :ddhd :dt :dd') > 0)
                  fForward = (id = ':dl')            -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     id = substr(id, 2)
                     clist = 'dl'
                     clen = 2
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     id = substr(id, 3)
                     clist = 'edl'
                     clen = 3
                  endif
                  search = '\:\ce?dl(\.| )'
               elseif wordpos(id, ':fig :efig :figcap') then
                  fIntermediate = (id = ':figcap')
                  fForward = (id = ':fig')          -- fForward = 1 if searching forward; 0 if backwards
                  if fForward then  -- move to beginning
                     .col = startcol
                     id = substr(id, 2)
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol+1
                     id = substr(id, 3)
                  endif
                  search = '\:\ce?fig(\.| )'
               else  -- not a known balanceable IPF token
                  passist_rc = 4
               endif
            else  -- not a known balanceable IPF token
               passist_rc = 4
            endif
         else  -- not a known balanceable IPF token
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      elseif CurMode = 'HTML' then
         fCase = 0                      -- Case insensitive for all HTML tokens
         if 0 then
            -- placeholder
         ---- HTML tags: <...,</...> -----------------------------------------------------------------
         elseif leftstr(id, 1) = '<' then
            clist = substr(id, 2, 1)     -- Character to check to see if it's the same or the other
            fForward = (clist <> '/')           -- fForward = 1 if searching forward; 0 if backwards
            if fForward then  -- move to beginning
               id = substr(id, 2)  -- Strip off the '<'
               clist = id
               .col = startcol
            else       -- move to end, so first Locate will hit this instance.
               id = substr(id, 3)  -- Strip off the '</'
               clist = '/' || id
               .col = endcol + 1   -- +1 for the '>' after the tag
            endif
            search = '<\c/?'id'(>| )'  -- Use \c to not put cursor on angle bracket.
            clen   = length(clist)
         else  -- not a known balanceable HTML token
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      elseif Curmode = 'TEX' then
      -- begin addition for TeX
      -- //PM additions: balanceable tokens for (La)TeX

      ---- TeX conditions: \if, \else, \fi --------------------------------------------------------
         if substr(id,1,3) = '\if' or wordpos(id, '\else \fi') then --// \if.. \else \fi
            search = '\\(if|fi)'
            clist = substr(id, 2, 1)
            fForward = (clist = 'i') -- fForward=1: forward, fForward=0 backward search
            if fForward then -- move cursor so that the first Locate will hit this instance
               .col = startcol -- \if: move to beginning
            else
               .col = endcol -- \else,\if: move to end
            endif
            coffset = 1
            fIntermediate = substr(id, 3, 1) = 'l' -- fIntermediate=1 for \else

         ---- TeX environment: \begin..., \end... ----------------------------------------------------
         elseif substr(id,1,6)='\begin' or substr(id,1,4)='\end' then --// \begin.. \end..
            search = '\\(begin|end)'
            ---- LaTeX environment: \begin{...}, \end{...} -------------------------------------------
         ----> bug   \begin {...} is not recognized!
            if substr(line,endcol+1,1) = '{' then -- isn't it LaTeX's \begin{sth} ?
compile if 1
               -- first version: searches pairs \begin{theenvironment} .. \end{theenvironment}
               i = pos( '}', substr(line,startcol) )
               if i > 0 then
                  search = substr(line,endcol+1, (i-endcol))
                  search = '\\(begin'search'|end'search')'
                  endcol = i+startcol-1
               endif
compile else
               -- second version: searches pairs \begin{ .. \end{   thus can find also
               -- unbalanced environments
               search = search'{'
               endcol = endcol+1
compile endif
            endif
            clist = substr(id, 2, 1)
            fForward = (clist = 'b')
            if fForward then
               .col = startcol
            else
               .col = endcol
            endif
            coffset = 1

         ---- TeX math -------------------------------------------------------------------------------
         elseif wordpos(id,'\left \right') then --// \left \right
            search = '\\(left|right)'
            clist = substr(id, 2, 1)
            fForward = (clist = 'l')
            if fForward then
               .col = startcol
            else
               .col = endcol
            endif
            coffset = 1
   -- end addition for TeX
         else -- not a known balanceable 'TEX' token
            passist_rc = 4
         endif

      ---------------------------------------------------------------------------------------------
      else -- not a known balanceable token
         passist_rc = 4
      endif--test
   endif -- if find_token/not find_token

   NumArgs = fForward fCase fIntermediate StartCol EndCol cLen cOffset n
   return passist_rc


; ---------------------------------------------------------------------------
defproc passist_search( clist, case, coffset, clen, n)
   loop
      call jbsdprintf("passist", "before search pos: ".line",".col "n = "n)
      repeatfind
      if rc then leave; endif
      call jbsdprintf("passist", "Match at ".line",".col)
      if inside_comment() then
         iterate
      endif
      if inside_literal2() then
         iterate
      endif
      call jbsdprintf("passist", "line# ".line" col: ".col" text: "textline(.line))
      cword  = substr(textline(.line), .col + coffset, clen)
      if case = 'c' then
         cword = lowcase(cword)
      endif
      call jbsdprintf("passist", "Cword: "cword "Coffset: "coffset "CLen: "clen)
      if wordpos(cword, clist) then
         n = n + 1;
      else
         n = n - 1;
      endif

      call jbsdprintf("passist", 'after n = 'n)
      if n=0 then
         leave
      endif
   endloop
   return 5 * (rc = sayerror('String not found'))

; ---------------------------------------------------------------------------
; Commented out: currently the def's from balance.e work better
/*
; Balance:
; While typing an opening or closing expression the corresponding expression
; is seached and highlighted.
;
; Compared to EPMSMP\BALANCE.E the existing function passist is used. passist
; can be expanded to find matching expressions for other languages then C.
; I.e. finding \begin {mygroup} and \end {mygroup} for LaTeX is planned and
; will be added here, when the passist function was extended.

defproc NepmdDefineBalanceChar(char)
   keyin char
   call psave_pos(saved_pos)
   left
   sayerror 0  -- reset messageline
   display -8  -- disable saving messages for the messagebox
   call passist()
   call passist()
   display 8   -- enable saving messages for the messagebox
   right
   call prestore_pos(saved_pos)
   return

def '('=
   NepmdDefineBalanceChar('(')

def ')'=
   NepmdDefineBalanceChar(')')

def '['=
   NepmdDefineBalanceChar('[')

def ']'=
   NepmdDefineBalanceChar(']')

def '{'=
   NepmdDefineBalanceChar('{')

def '}'=
   NepmdDefineBalanceChar('}')

def '<'=
   NepmdDefineBalanceChar('<')

def '>'=
   NepmdDefineBalanceChar('>')
*/
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
defproc inside_literal()
   if inside_comment() then
      retval = 0
   else
      retval = inside_literal2()
   endif
   return retval

; ---------------------------------------------------------------------------
defproc inside_literal2()
   call jbsdprintf("lit2", "Entry: ".line .col)
   call psave_pos(savepos2)
   getsearch search_command2  -- Save caller's search command.
   mode = NepmdGetMode()      -- JBSQ: should this be a parameter instead?
   curline  = .line
   curcol  = .col
   line = textline( .line )
   retval = 0
   parse value GetLitChars(mode) with StartLitChars EndLitChars EscapeChars
   if StartLitChars then
      endpos = 0
      loop
         startpos = verify(line, StartLitChars, 'M', endpos + 1)
         call jbsdprintf("lit2", "startpos curcol line: "startpos curcol line)
         if not startpos then
            leave
         elseif startpos >= curcol then
            leave
         endif
         startq     = substr(line, startpos, 1)
         qpos       = pos(startq, StartLitChars)
         escapechar = substr(EscapeChars, qpos, 1)
         endq       = substr(EndLitChars, qpos, 1)
         endpos     = startpos
         loop
            endpos     = verify(line, endq, 'M', endpos + 1)
            call jbsdprintf("lit2", "startq startpos endq endpos escapechar: "startq startpos endq endpos escapechar)
            if endpos >= curcol then         -- JBSQ: Disregard escape and assume a valid close "quote"?
               retval = 1
               leave
            elseif not endpos then           -- No end "qupte"??
               sayerror "Unmatched start-of-literal character: "startq "at "curline","startpos
               call jbsdprintf("lit2", "Unmatched start-of-literal character: "startq "at "curline","startpos)
               retval = 1                    -- JBSQ: Return true on unmatched "quote"?
               leave
            elseif endq = escapechar then    -- escaped "quote" case 1: doubled-"quote"s
               if length(line) > endpos then
                  if substr(line, endpos + 1, 1) = endq then      -- doubled-"quote" escape sequence?
                     endpos = endpos + 1
                     call jbsdprintf("lit2", "Doubled-quote")
                     iterate
                  else                       -- not escaped and endpos < curcol
                     leave                   --     literal starts and ends before cursor col
                  endif
               else
                  retval = 1                 -- this shouldn't happen after initial if endpos >= curcol
                  call jbsdprintf("lit2", 'Reached "unreachable" code.')
                  leave
               endif
            elseif substr(line, endpos - 1, 1) = escapechar then  -- escaped "quote" case 2, preceding escape char
               call jbsdprintf("lit2", "Escaped quote")
               iterate
            else  -- endpos > 0 and endpos < curcol, i.e. literal starts and ends before curcol
               leave
            endif
         endloop
         if retval then
            leave
         endif
      endloop
   endif
compile if 0
   if 1 /* or mode = 'REXX' or mode = 'E' or mode = 'C' */ then
      dq = '"'
      sq = "'"
      startliterals = '"'''   -- get these from mode def, instead of hard-coding?
      endliterals   = '"'''   -- get these from mode def, instead of hard-coding?
      call jbsdprintf( "lit2", "line# ".line": "line)
      p2 = 0
      loop
         pdq = pos(dq, line, p2 + 1)
         psq = pos(sq, line, p2 + 1)
         call jbsdprintf( "lit2", "psq pdq" psq pdq)
         if psq = 0 and pdq = 0 then
            leave
         elseif psq = 0 then
            p = pdq
         elseif pdq = 0 then
            p = psq
         elseif psq < pdq then
            p = psq
         else
            p = pdq
         endif
         if p > curcol then
            leave
         endif
         endquotechar = substr(line, p, 1)
         startcol = p + 1
         loop
            p2 = pos(endquotechar, line, startcol)
            if p2 > 0 then
               call jbsdprintf( "lit2", "endquotechar pos "endquotechar p2)
               --
               -- Handle "escaped" quotes here
               --
               if mode = 'C' then
                  if substr(line, p2 - 1, 1) = '\' then
                     startcol = startcol + 1
                     iterate
                  endif
               elseif mode = 'E' then
                  if (p2 < (length(line) - 1)) then -- quote found before end-of-line?
                     if substr(line, p2 + 1, 1) = endquotechar then -- double quoted?, skip to next
                        startcol = p2 + 2
                        iterate
                     endif
                  endif
               else
                  -- assume no escape chars??
               endif
            endif
            leave
         endloop
         if p2 = 0 then
            if p < curcol then
               sayerror "Unpaired quote found at ".line","p     -- JBSQ: after beginning quote which has no end?
            endif
            leave
         elseif p < curcol and (p2 >= curcol) then
            retval = 1
            leave
         endif
      endloop
   else
      call jbsdprintf("lit2", "Error: unknown mode: "mode)
   endif
compile endif
   setsearch search_command2 -- Restores user's command so Ctrl-F works.
   call prestore_pos(savepos2)
   call jbsdprintf("lit2", "Exit: "retval .line .col)
   return retval

; ---------------------------------------------------------------------------
defproc getLitChars(mode)
   SingleQuote = "'"
   DoubleQuote = '"'
   StartLitChars = DoubleQuote || SingleQuote
   EndLitChars   = StartLitChars
   EscapeChars   = '\\'
   if 0 then
      -- placeholder
   elseif mode = 'E' then
      EscapeChars = StartLitChars
   elseif mode = 'REXX' then
      EscapeChars = StartLitChars
   elseif mode = 'MAKE' or mode = 'RC' then
      StartLitChars = DoubleQuote
      EndLitChars   = StartLitChars
      if mode = 'RC'then
         EscapeChars = '\'
      else
         EscapeChars   = \0                 -- JBSQ: No escape chars for MAKE?
      endif
   elseif mode = 'PERL' then
      StartLitChars = StartLitChars || '`'
      EndLitChars   = StartLitChars
      EscapeChars   = '\\\'
   elseif mode = 'ADA' then
      StartLitChars = DoubleQuote || '%'
      EndLitChars   = StartLitChars
      EscapeChars   = \0\0
   elseif mode = 'DEF' then
      StartLitChars = SingleQuote
      EndLitChars   = StartLitChars
      EscapeChars   = \0                 -- JBSQ: No escape chars for DEF?
      -- other modes here
   endif
   return StartLitChars EndLitChars EscapeChars

; ---------------------------------------------------------------------------
defproc inside_comment()          -- JBSQ: Do we need a parameterless version?
   return inside_comment2(dummy)

; ---------------------------------------------------------------------------
;  inside_comment2
;     return value 0 => cursor is NOT within a comment
;        and comment_data is meaningless
;     return value 1 => cursor IS within a one-line comment
;        and comment_data is set to the column of the one-line comment
;     return value 2 => cursor IS within a multi-line comment
;        and comment_data is set to 6 blank-separated words:
;           The line, col and length of the starting token and
;           the line, col and length of the ending token.
defproc inside_comment2(var comment_data)
   display -2
   call jbsdprintf("comm", "Entry: ".line .col)
   call psave_pos(savepos2)
   getsearch search_command2  -- Save caller's search command.
   retval = 0
   comment_data = ""
   mode = NepmdGetMode()      -- JBSQ: should this be a parameter instead?
   curline  = .line
   curcol  = .col
   line = textline(.line)
   MLCCase = 'c'              -- JBSQ: Ignore case for ALL MLC's?
   MLCData =  locateMLC(mode, curline, curcol)
   parse value MLCData with BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
   if BestMLCStartLine > 0 then
      retval = 2
   endif
   call jbsdprintf("comm", "Retval on exit of outer MLC loop: "retval "cursor: ".line",".col)
   if retval = 0 then
      SLCPosition = inside_oneline_comment(line, mode)
      comment_data = SLCPosition
      retval = (SLCPosition > 0)
   else
      comment_data = BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
   endif
   setsearch search_command2 -- Restores user's command so Ctrl-F works.
   display 2
   call jbsdprintf( "comm", "MLC rc: "retval comment_data)
   return retval

; ---------------------------------------------------------------------------
defproc locateMLC(mode, line, col)
   MLCCount = buildMLCArray(mode)
   call jbsdprintf("array", "locateMLC mode: "mode line","col "MLCCount: "MLCCount)
   getfileid fid
   listindexbase = 'assist.'fid'.'
   BestMLCStartLine = 0
   BestMLCStartCol  = 0
   BestMLCStartLen  = 0
   BestMLCEndLine   = 0
   BestMLCEndCol    = 0
   BestMLCEndLen    = 0
   do i = 1 to MLCCount
      MLCListcount = GetAVar(listindexbase || i'.List.0')
      call jbsdprintf("array", "Listcount #"i": "MLCListCount)
      do j = 1 to MLCListCount
         MLCEntry = GetAVar(listindexbase || i'.List.'j)
         call jbsdprintf("array", "MLCEntry: "MLCEntry)
         parse value MLCEntry with MLCStartLine MLCStartCol MLCStartLen MLCEndLine MLCEndCol MLCEndLen
         call jbsdprintf("array", "test1: "((MLCEndLine > line) or (MLCEndLine = line and (MLCEndCol + MLCEndLen) > col)))
         call jbsdprintf("array", "test2: "((MLCStartLine < line) or (MLCStartLine = line and MLCStartCol <= col)))
         call jbsdprintf("array", "test3: "((MLCStartLine > BestMLCStartLine)  or (MLCStartLine = BestMLCStartLine and MLCStartCol > BestMLCStartCol)))
         if (MLCEndLine > line) or (MLCEndLine = line and (MLCEndCol + MLCEndLen) > col) then
            if (MLCStartLine < line) or (MLCStartLine = line and MLCStartCol <= col) then
               if (MLCStartLine > BestMLCStartLine)  or (MLCStartLine = BestMLCStartLine and MLCStartCol > BestMLCStartCol) then
                  parse value MLCEntry with BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
                  call jbsdprintf("array", "   Best, so far" MLCEntry)
                  leave   -- LISTCOMM: with current buildMLC logic, first should be "best"
               endif
            endif
         endif
      enddo
   enddo
   return BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen

; ---------------------------------------------------------------------------
defproc buildMLCArray(mode)
   call psave_pos(savepos)
   getfileid fid
   MLCCase = 'c'
   modeindexbase = 'assist.mode.'mode'.'
   listindexbase = 'assist.'fid'.'
   modeMLCCount = GetAVar(modeindexbase'0')
   if modeMLCCount = '' then
      call GetMLCChars(mode, MLCStartChars, MLCEndChars, MLCNestList)
      modeMLCCount = words(MLCStartChars)
      call SetAVar(modindexbase'0', modeMLCCount)
      do i = 1 to modeMLCCount
         call SetAVar(modeindexbase || i || '.MLCStart', word(MLCStartChars, i ))
         call SetAVar(modeindexbase || i || '.MLCEnd'  , word(MLCEndChars, i ))
         call SetAVar(modeindexbase || i || '.MLCNest' , word(MLCNestList, i ))
      enddo
   endif
   call jbsdprintf("array", "Build mode: "mode "MLCCount: "modeMLCCount)
   if modeMLCCount > 0 then
      call jbsdprintf("array", "Extracted Starts: "MLCStartChars "Ends: "MLCEndChars "Nests: "MLCNestList "Count: "modeMLCCount)
      Rebuild = GetAVar(listindexbase'Rebuild')
      call jbsdprintf("array", "Rebuild: '"rebuild"'")
      if Rebuild = 1 then
         /* delete the old data here? */
         -- MLCListCount = GetAVar(listindexbase
      endif
      if Rebuild = '' or Rebuild = 1 then
         curline      = .line
         curcol       = .col
         found_count  = 0
         do i = 1 to modeMLCCount
            MLCStart = GetAVar(modeindexbase || i || '.MLCStart')
            MLCEnd   = GetAVar(modeindexbase || i || '.MLCEnd'  )
            MLCNest  = GetAVar(modeindexbase || i || '.MLCNest' )
            call jbsdprintf("comm", "MLC data: "MLCStart MLCEnd MLCNest)
            MLCStartSearch   = escape_search_chars(MLCStart)
            MLCEndSearch     = escape_search_chars(MLCEnd)
            call jbsdprintf("comm", ""MLCStart "search = "MLCStartSearch)
            call jbsdprintf("comm", ""MLCEnd "search = "MLCEndSearch)
            MLCStartLine = curline
            MLCStartCol  = curcol   + 1
            MLCStartLen  = length(MLCStart)
            MLCEndLine   = curline
            MLCEndCol    = curcol
            MLCEndLen    = length(MLCEnd)
/*
   */
            .line        = 1
            .col         = 1
            array_index  = 0   -- LISTCOMM: assumes a separate list for each MLC string-pair is built
            NestedStartsList = ''
            MLCFindRC    = 0
            do while (MLCFindRC = 0)
               'xcom l ' || \1 || MLCStartSearch || \1 || 'x' || MLCCase || '+F'
               MLCFindRC = rc
               if MLCFindRC = 0 then
                  if inside_oneline_comment(textline(.line), mode) then
                     right
                     iterate
                  endif
                  if inside_literal2() then
                     right
                     iterate
                  endif
                  MLCStartLine = .line
                  MLCStartCol  = .col
                  call jbsdprintf("comm", MLCStart "found at" MLCStartLine MLCStartCol)
                  NestedStartsList = MLCStartLine MLCStartCol NestedStartsList
                  if MLCNest then
                     setsearch 'xcom l ' || \1 || '(' || MLCStartSearch || '|' || MLCEndSearch || ')' || \1 || 'x' || MLCCase || '+F'
                  else
                     setsearch 'xcom l ' || \1 || MLCEndSearch || \1 || 'x' || MLCCase || '+F'
                  endif
                  right
                  do while ((MLCFindRC = 0) and (NestedStartsList <> ''))
                     call jbsdprintf("comm", "MLCEnd, presearch loc: ".line",".col)
                     repeatfind
                     MLCFindRC = rc
                     if MLCFindRC then leave; endif
                     call jbsdprintf("comm", "MLCEnd, postsearch loc: ".line",".col)
                     SLCPosition = inside_oneline_comment(leftstr(textline(.line), .col), mode, 1)
                     if SLCPosition then
                        right
                        iterate
                     endif
--                   MLC's "in-progress" can't be in literals?
--                   if inside_literal2() then
--                      iterate
--                   endif
                     call jbsdprintf("comm", "line# ".line" col: ".col" text: "textline(.line))
                     if substr(textline(.line), .col, MLCEndLen) = MLCEnd then
                        parse value NestedStartsList with MLCStartLine MLCStartCol NestedStartsList
                        array_index  = array_index + 1
                        array_value  = MLCStartLine MLCStartCol MLCStartLen .line .col MLCEndLen
                        call SetAvar(listindexbase || i || '.List.' || array_index, array_value)
                     else
                        -- this code should only be reached if MLCNest = 1 and MLCStart was matched
                        NestedStartsList = .line .col NestedStartsList
                     endif
                     call jbsdprintf("comm", 'after Nestlist: 'NestedStartsList)
                  enddo
                  if MLCFindRC then
                     sayerror "Unmatched MLC's: "NestedStartsList
                     leave
                  endif
               endif          /* End of if unnested comment was found  */
               call SetAvar(listindexbase || i || '.List.0', array_index)
            enddo             /* End of loop for each unnested comment */
         enddo                /* End of loop for each MLC string-pairs */
         call SetAvar(listindexbase || 'Rebuild', 0)
      endif                   /* End of If rebuild                     */
   endif                      /* End of if any MLC's                   */
   call prestore_pos(savepos)
   return modeMLCCount

; ---------------------------------------------------------------------------
defproc GetMLCChars(mode, var MLCStartChars, var MLCEndChars, var MLCNestFLags)
   MLCStartChars = ''         -- return indicating NO MLC's
   if mode = 'REXX' or mode = 'E' or mode = 'C' | mode = 'JAVA' | mode = 'RC' | mode= 'CSS' /* | mode = 'PERL' JBSQ: NOT Perl?? */ then
      MLCStartChars = '/*'    -- get these from mode def, instead of hard-coding
      MLCEndChars   = '*/'
      if mode = 'C' or mode = 'RC' then
         MLCNestFLags = '0'
      else
         MLCNestFlags = '1'
      endif
   elseif mode = 'PASCAL' then
      MLCStartChars = '(* {'
      MLCEndChars   = '*) }'
      MLCNestFlags  = '1 1'        -- JBSQ: ??
   elseif mode = 'TEX' then --------------------------------------- TEX
      MLCStartChars = '\iffalse'
      MLCEndChars   = '\fi'
      MLCNestFlags  = '1'
   elseif mode = 'HTML' | mode = 'WARPIN' then -------------------- HTML WARPIN
      MLCStartChars = '<!--'
      MLCEndChars   = '-->'
      MLCNestFlags  = '1'
   elseif mode = 'PHP' then --------------------------------------- PHP
      MLCStartChars = '<!-- /*'
      MLCEndChars   = '--> */'
      MLCNestFlags  = '1'
   endif
   return

; ---------------------------------------------------------------------------
;  The following routine assumes that the search string parameter is simply the string which
;  is desired, i.e. no metacharacters like ^ for start-of-line, [] for sets, etc.
defproc escape_search_chars(search_string)
   --chars_to_escape = '\[]()?+*^$.-'
   chars_to_escape = '\[]()?+*^$.|{}'    -- pulled from perl docs
   p = -1
   loop
      p = verify(search_string, chars_to_escape, 'M', p + 2)
      if not p then
         leave
      else
         search_string = leftstr(search_string, p - 1) || '\' || substr(search_string, p)
      endif
   endloop
   return search_string


; ---------------------------------------------------------------------------
;  inside_oneline_comment
;     returns the column of the start of the comment (0 if no one-line comment)
defproc inside_oneline_comment(line, mode)
   call jbsdprintf("1line", "Entry: ".line .col "Mode = "mode)
   if arg(3) == '' then
      MLCInProgress = 0
   else
      MLCInProgress = arg(3)
   endif
   retval = 0
   indexbase = 'assist.mode.'mode'.'
   SLCCount = GetAVar(indexbase || 'SLC.0')
   if SLCCount = '' then
      call GetSLCChars(mode, SLCCharList, SLCPosList, SLCAddList, SLCOverrideMLCList)
      SLCCount = words(SLCCharList)
      call jbsdprintf("1line", "SLCCount: "SLCCount)
      call SetAVar(indexbase || 'SLC.0', SLCCount)
      do i = 1 to SLCCount
         call SetAVar(indexbase || 'SLC.'            || i, word(SLCCharList, i))
         call SetAVar(indexbase || 'SLCPos.'         || i, word(SLCPosList, i))
         call SetAVar(indexbase || 'SLCAdd.'         || i, word(SLCAddList, i))
         call SetAVar(indexbase || 'SLCOverrideMLC.' || i, word(SLCOverrideMLCList, i))
      enddo
   endif

   do SLCIndex = 1 to SLCCount
      if MLCInProgress then
         if not GetAVar(indexbase || 'SLCOverrideMLC.' || SLCIndex) then
            iterate
         endif
      endif
      SLC    = GetAVar(indexbase || 'SLC.'    || SLCIndex)
      SLCPos = GetAVar(indexbase || 'SLCPos.' || SLCIndex)
      SLCAdd = GetAVar(indexbase || 'SLCAdd.' || SLCIndex)
      call jbsdprintf("1line", "SLC/Pos/Add: "SLC"/"SLCPos"/"SLCAdd)
      if SLCAdd <> '0' then
         SLC = SLC || ' '
      endif
      if SLCPos = '0' then
         savecol = .col
         len = length(SLC)
         p = 1 - len
         loop
            p = pos(SLC, line, p + len)
            if (p = 0) then                           -- if not found
               leave
            elseif (p >= savecol) then                -- if found on or after cursor column
               leave
            elseif (retval > 0 and p >= retval) then  -- if later than a previously found comment
               leave
            endif
            .col = p
            if not inside_literal2() then
               leave
            endif
         endloop
         .col = savecol
         if (p and p <= .col) then                     -- if found before cursor location
            if (retval = 0 or (retval > 0 and p < retval)) then
               retval = p
               call jbsdprintf("1line", "Found "SLC" comment")
            endif
         endif
      elseif SLCPos = 'F' then
         call jbsdprintf("1line", "PosF "leftstr(word(line, 1), length(SLC)))
         if leftstr(word(line, 1), length(SLC)) = SLC then
            call jbsdprintf("1line", "Found '"SLC"' comm")
            p = pos(SLC, line)
            if (retval = 0) or (p < retval) then
               retval = p
            endif
         endif
      elseif SLCPos = '1' then
         call jbsdprintf("1line", "Pos1 "leftstr(line, length(SLC)))
         if leftstr(line, length(SLC)) = SLC then
            call jbsdprintf("1line", "Found '"SLC"' comm")
            retval = 1
            leave
         endif
      endif
   enddo
   call jbsdprintf("1line", "Exit: "retval .line .col)
   return retval

; ---------------------------------------------------------------------------
defproc GetSLCChars(mode, var SLCCharList, var SLCPosList, var SLCAddList, var SLCOverrideMLCList)
   SLCCharList        = ''      -- return value for "no SLC's"
   SLCPosList         = '0'     -- default
   SLCAddList         = '0'     -- default
   SLCOverrideMLCList = '0'     -- default
   if mode = 'E' then
      SLCCharList  = '; --'
      SLCPosList   = '1 0'
      SLCAddList   = '0 0'
      SLCOverrideMLCList = '1 0'
   elseif mode = 'C' | mode = 'JAVA' | mode = 'RC' | mode = 'PASCAL' then
      SLCCharList  = '//'
      SLCOverrideMLCList = '1'
   elseif mode = 'DEF' then
      SLCCharList  = ';'
   elseif mode = 'MAKE' then
      SLCCharList  = '#'
      SLCPosList         = '1'
      SLCOverrideMLCList = '1'
   elseif mode = 'CMD' then
      SLCCharList  = ': :: REM'
      SLCPosList   = 'F F F'
      SLCAddList   = '1 0 1'
      SLCOverrideMLCList = '0 0 0'
   elseif mode = 'CONFIGSYS' then
      SLCCharList  = 'REM'
      SLCPosList   = 'F'
      SLCAddList   = '1'
   elseif mode = 'INI' | mode = 'OBJGEN' then
      SLCCharList  = ';'
      SLCPosList   = 'F'
   elseif mode = 'IPF' | mode = 'SCRIPT' then --------------------- IPF SCRIPT
      SLCCharList  = '.*'
      SLCPosList   = 'F'
   elseif     mode = 'PERL' then -------------------------------------- PERL
      SLCCharList  = '#'
      SLCAddList   = '1'
   elseif     mode = 'ADA' then --------------------------------------- ADA
      SLCCharList  = '--'
   elseif     mode = 'FORTRAN' then ----------------------------------- FORTRAN
      SLCCharList  = 'c * !'
      SLCPosList   = '1 1 0'
      SLCAddList   = '1 0 0'
      SLCOverrideMLCList = '0 0 0'
   elseif     mode = 'TEX' then --------------------------------------- TEX
      SLCCharList  = '%'
   elseif     mode = 'PHP' then --------------------------------------- PHP
      SLCCharList  = '// #'
      SLCPosList   = '0 0'
      SLCOverrideMLCList = '0 0'
   elseif     mode = 'BASIC' then ------------------------------------- BASIC
      SLCCharList  = "' REM"
      SLCPosList   = '1 1'
      SLCAddList   = '0 1'
      SLCOverrideMLCList = '0 0'
   endif
   return

; ---------------------------------------------------------------------------
defproc prune_assist_array()
   getfileid fid
   call SetAVar("assist."fid".Rebuild", 1)
   return




defc t5
   sayerror 'in t5'
   mode = 'E'
   MLCCount = buildMLCArray(mode)
   getfileid fid
   listindexbase = 'assist.'fid'.'
   modeindexbase = 'assist.mode.'mode'.'
   call jbsdprintf("array", "Dump MLC array.  Count = "MLCCount)
   do i = 1 to MLCCount
      MLCStart = GetAVar(modeindexbase || i'.MLCStart')
      MLCEnd = GetAVar(modeindexbase || i'.MLCEnd' )
      MLCNest = GetAVar(modeindexbase || i'.MLCNest')
      MLCListCount = GetAVar(listindexbase || i'.List.0')
      call jbsdprintf("array", "MLC #"i": Start: '"MLCStart"' End: '"MLCEnd"' Nest: "MLCNest "MLCListCount: "MLCListCount)
      do j = 1 to MLCListCount
         MLCEntry = GetAVar(listindexbase || i'.List.'j)
         call jbsdprintf("array", "   Comment  "rightstr(j, 2, '0')':' MLCEntry)
      enddo
   enddo

defc t6
   position = arg(1)
   parse value position with tline tcol
   getfileid fid
   comment = locateMLC('E', tline, tcol)
   parse value comment with sl .
   if sl = 0 then
      sayerror tline","tcol" is NOT in a comment."
   else
      sayerror tline","tcol "is in comment: "comment
   endif


def a_backslash
   'nextbookmark P'
def a_slash
   'nextbookmark'

defc t1
   sayerror "1line result: "inside_oneline_comment(textline(.line), NepmdGetMode())

defc t2
   if inside_comment() then
      sayerror "Comment"
   elseif inside_literal2() then
      sayerror "Literal"
   else
      sayerror "Neither"
   endif


defc t4
   -- Andreas just try CTRL+]/CTRL+8 below to see the problem I mentioned in my email
   'e d:\utils\editors\medo126e\med.syn'
   .line = 1
   parse arg ext
   'l /^[ \t]*files\:[ \t]+.*\.'ext'/x'
   if rc then
      sayerror "Unable to find E section of med.syn"
   else
      call dprintf("t4", '"Mode": 'substr(textline(.line), wordindex(textline(.line), 2)))
      SLC = ''
      SLCPos = -1
      SLCColor = 'Dummy'
      MLCStart = ''
      MLCEnd   = ''
      do l = .line + 1 to .last
         down
         line = strip(textline(.line))
         if line <> "" then
            word1 = word(line, 1)
            if leftstr(word1, 1) <> '#' then
               if word1 = 'color:' then
                  parse value line with . (word1) color
               elseif word1 = 'eolCom:' then
                  if SLC <> '' then
                     call dprintf("t4", "SLC: "SLC  "SLCPos: "SLCPos  "SLCColor: "SLCColor)
                  endif
                  SLC = word(line, 2)
                  SLCColor = color
                  if SLCPos < 0 then
                     SLCPos = 0
                  endif
               elseif word1 = 'comCol:' then
                  SLCPos = word(line, 2)
               elseif word1 = 'openCom:' then
                  MLCStart = word(line, 2)
               elseif word1 = 'closeCom:' then
                  MLCEnd = word(line, 2)
                  call dprintf("t4", "MLCStart: "MLCStart  "MLCEnd: "MLCEnd  "Color: "color)
               elseif word1 = 'string:' then
                  call dprintf("t4", "String delimiter: "word(line, 2)  "Color:" color)
               elseif word1 = 'char:' then
                  call dprintf("t4", "Char delimiter: "word(line, 2)  "Color:" color)
               elseif word1 = 'token:' then
                  do w = 2 to words(line)
                     call dprintf("t4", "Token: "word(line, w)  "Color:" color)
                  enddo
               elseif word1 = 'files:' then
                  l = .last
               endif
            endif
         endif
      enddo
      if SLC <> '' then
         call dprintf("t4", "SLC: "SLC  "SLCPos: "SLCPos  "SLCColor: "SLCColor)
      endif
   endif
   'quit'

defc macgrep
   rootdir = NepmdScanEnv('NEPMD_ROOTDIR')
   filemask = rootdir || '\netlabs\macros\*.e' rootdir || '\myepm\macros\*.e'
   'grep -EinH ' arg(1) filemask

compile if 0
;
; Notes on mixed MLC and SLC in E code
;
   /*  test              */
--  /*        OK
-- */         OK
;     /*      OK, alone, together and in either order
;     */
/*  --  */    OK
-- /*      */ OK
/*            NOT OK
--  *^/
*/

/*            NOT OK
;    *^/
*/

/*            NOT OK, nested comments require matching /* */, THIS /* is unmatched  */
--    /^*
*/
--  Even though in compile if, the incomplete nest above comments out the compile endif

               -- handle /*   <cursor>    /*   */               */???
               /*           test
               -- handle      <cursor>    /*   */
                  ??? */

         compile if 0
                  if/* test */c <> 'zxc' then
                     sayerror "ytrdy"
                  endif
                  /*

         */ compixle /* test */ ixf 0
            test = b123
            compixle /* test2 */ exndif;
            compixle     ixf 0
            test = b123
            compilxe            endxif

         compile else
            dummyloop = 2
         compile endif
compile endif


defproc next_nonblank_noncomment_nonliteral()
   direction = arg(1)
   if direction = '' or not wordpos(direction, '+F -R') then
      direction = '+F'
   endif
   getsearch savesearch
   setsearch 'xcom l /[^ \t]+/x'direction    -- find the next non-blank
   loop
      repeatfind
      if not rc then
         comment_rc = inside_comment2(comment_data)
         --call jbsdprintf("passist", "next pos: ".line",".col "Char: '"substr(textline(.line), .col, 1)'"' "comment_rc: "comment_rc)
         if not comment_rc then
            return (substr(textline(.line), .col, 1))
         elseif comment_rc = 1 then
            if direction = '+F' then
               endline
            else
               .col  = word(comment_data, 1)
            endif
         else
            parse value comment_data with MLCStartLine MLCStartCol . MLCEndLine MLCEndCol MLCEndLen
            --call jbsdprintf("passist", "next comment data: "MLCEndLine MLCEndCol MLCEndLen)
            if direction = '+F' then
               .line = MLCEndLine
               .col  = MLCEndCol + MLCEndLen - 1
            else
               .line = MLCStartLine
               .col  = MLCStartCol
            endif
         endif
      else
         return ''
      /*          */endif
   endloop

defc t7
   dir = arg(1)
   if dir = '' then
      dir = '+F'
   endif
   sayerror "next... returned: '"next_nonblank_noncomment_nonliteral(dir)"'"

defc t9
   't8 lit2'
   curline  = .line
   curcol  = .col
   line = textline( .line )
   retval = 0
   parse value GetLitChars(mode) with StartLitChars EndLitChars EscapeChars
   call jbsdprintf("lit2", "GetLitchars return: "StartLitChars EndLitChars EscapeChars)
   if StartLitChars then
      endpos = 0
         startpos = verify(line, StartLitChars, 'M', endpos + 1)
         call jbsdprintf("lit2", "startpos: "startpos)
   endif

