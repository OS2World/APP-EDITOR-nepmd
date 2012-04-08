/****************************** Module Header *******************************
*
* Module Name: assist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id$
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
Changed:
-  Moved external procs.
-  Reactivated highlighting of the found string (by using highlight_mark)
-  Return rc for passist proc.

Todo:
-  Speed improvement: Better search for both, the opening and closing
   string. If the found string is the same as the string under cursor, then
   stop, because the string under cursor must be unmatched.
-  Optional: if corresponding string is not on screen, just give a msg
   like in defproc balance. When 'just a msg' is selected, then give the
   user the possibility to go (with a special key combination) to that
   pos although (and back again). So we can get rid of BALANCE.E.
-  Add support for FORTRAN90?
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

;
;    2006 changes: JBS
;
;    A major rework of the code
;       Bugs were fixed
;       More tokens are balanced, including the start and end points of multi-line comments
;       More modes supported (PASCAL, FORTRAN77, JAVA, WARPIN)
;       Added initial stages of support for ADA, CSS, PERL, PHP
;       Code was added to ensure tokens found within comments or literals were not matched
;       Better variable names and code documentation
;

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

define
 compile if not defined(NEPMD_DEBUG)
   NEPMD_DEBUG = 0  -- General debug const
 compile endif

defmain
   call passist()

compile endif  -- not defined(SMALL)

--  NOTE: The logic below relies on GOLD being defined with the left "brackets"
--        in the odd positions and the right "brackets" in the even positions.
const GOLD = '(){}[]<>'  -- Parens, braces, brackets & angle brackets.

PASSIST_RC_MLC_MATCHED                    = -1
PASSIST_RC_NO_ERROR                       = 0
PASSIST_RC_IN_ONELINE_COMMENT             = 1
PASSIST_RC_IN_MULTILINE_COMMENT           = 2
PASSIST_RC_IN_LITERAL                     = 3
PASSIST_RC_NOT_ON_A_TOKEN                 = 4
PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN     = 5
PASSIST_RC_BAD_FORTRAN77_CURSOR           = 6
PASSIST_RC_MODE_NOT_SUPPORTED             = 7

EGREP_METACHARACTERS = '\[]()?+*^$.|'    -- JBSQ: This may need to changed if the grep code
                                         -- ever supports {, } and possibly other egrep metacharacters

-- JBSQ: The following constants 'hard-code' the versions of NMAKE and FORTRAN77 for which
--       passist works. Perhaps there is a better way that would allow this to be
--       selected by the user?
USE_NMAKE32       = 1   -- 0 means do not accept NMAKE32-specific directives
USE_FORTRAN90_SLC = 1   -- 0 means disregard FORTRAN90 SLC: '!'


defc assist, passist
   call passist()

; ---------------------------------------------------------------------------
; id            = found word under cursor (or beneath the cursor in some cases)
; fIntermediate = set to 1 if id is an intermediate conditional token
;                 (e.g. 'else', but not 'if' or 'endif')
; clist         = a space delimited list of substrings to match on. Usually this
;                 is a single substring. An example of multiple substrings in
;                 clist would be that an "end" in REXX mode can match up with
;                 either a "do" or a "select" statement. If fForward = 1 then
;                 these substrings should identify the starting token(s) of the
;                 bracketed code. If fForward = 0 then these substrings should
;                 identify the ending token(s).
; clen          = the length of the substrings in clist
; coffset       = offset from cursor pos to substring to match
; fForward      = a flag to indicate which direction to search
;                 1 = forward, 0 = backward
; search        = string for locate command, without seps and options,
;                 egrep will be used
; ---------------------------------------------------------------------------

defproc passist
   call psave_pos(savepos)                  -- Save the cursor location
   getsearch search_command                 -- Save user's search command.
   call dprintf("passist", "------------------------------------------------------------")
   call dprintf("passist", "Initial cursor: ".line",".col)
   CurMode     = NepmdGetMode()
   passist_rc  = inside_comment2(CurMode, comment_data)
   call dprintf("passist", "comment return:" passist_rc comment_data)
   if passist_rc = PASSIST_RC_IN_MULTILINE_COMMENT then
      parse value comment_data with CommentStartLine CommentStartCol CommentStartLen CommentEndLine CommentEndCol CommentEndLen
      if .line = CommentStartLine and .col - CommentStartCol < CommentStartLen then   -- if cursor on start
         .line = CommentEndLine                                                       -- move to the end
         .col  = CommentEndCol
         passist_rc = PASSIST_RC_MLC_MATCHED
      elseif .line = CommentEndLine and .col >= CommentEndCol then                    -- if cursor on end
         .line = CommentStartLine                                                     -- move to the start
         .col  = CommentStartCol
         passist_rc = PASSIST_RC_MLC_MATCHED
      endif
   endif

   if not passist_rc then
      if inside_literal2(CurMode) then
         passist_rc = PASSIST_RC_IN_LITERAL
      endif
   endif

   if not passist_rc then                   -- if not in a literal or comment, proceed
      -- get c = char at cursor
      c = substr(textline(.line), .col, 1)
      -- JBSQ: Why this code??  It moves the cursor.
      -- if c = space, then try it 1 col left
      if c == ' ' & .col > 1 then
         left
         c = substr(textline(.line),.col,1)
      endif

      case          = 'e'  -- respect case is default
      coffset       = 0
      clen          = 1
      fIntermediate = 0
      fForward      = 1
      n             = 1
      ECompileFlag  = 0

--    id            = ''   -- token under cursor
      startcol      = 1    -- start column of id/token
      endcol        = 1    -- end column of id/token

      if pos(c, '{}') and CurMode = 'RC' then  -- Braces, '{}', can be matched with
         k = 0                                 -- BEGIN and END in RC files.  So they
      else                                     -- need to be handled separately.
         k = pos(c, GOLD)  --  '(){}[]<>'
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
      else              -- if not a bracket char
         getline line
         -- build the separator list for find_token

         if CurMode = 'FORTRAN77' then
            seps = "+-*/=().,':$"
         else
            seps = ' ~`!.%^&*()-+=][{}|\;?<>,''"'\t
         endif
         -- JBSQ: Add '.' to default token_separators & remove ':' for GML markup?

         if CurMode = 'TEX' then
            if substr(line, .col, 1) = '\' then
               right
            endif   -- ...move cursor right if it is on \backslash
         endif

         -- get the word under cursor and return startcol and endcol
         -- stop at separators = arg(3)
         -- stop at double char separators = arg(4)
         if not find_token(startcol, endcol,  seps, '/* */') then  -- JBSQ: Should /* */ be used for ALL modes?
            passist_rc = PASSIST_RC_NOT_ON_A_TOKEN
         else
            call dprintf("passist", "Initial token start,end: "startcol","endcol)
            if startcol > 1 then
               prevchar = substr(line, startcol-1, 1)
               if prevchar = '<' then
                  if CurMode = 'HTML' or CurMode = 'WARPIN' /* or CurMode = 'XML' */ then
                     -- add '<' to found word if it is on the left side of it
                     -- this assumes ALL balanceable tokens for HTML and WARPIN start with '<'
                     startcol = startcol - 1
                  endif
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
                     newstart = verify(line, ' ' || \t, 'N', 2)  -- skip to next non-whitespace
                     if newstart then
                        newend = verify(line || ' ', ' ', 'M', newstart)
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
            call dprintf("passist", "Token after preprocessing : '"id"' Startcol: "startcol" Endcol: "endcol)

            --> IPF tags start with ':' and end with '.'
            -- JBSQ: Since this is for IPF only, should it ne moved to the IPF portion of the code?
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

            -- Mode(s): E                     --------------------------------------------------------------
            elseif CurMode = 'E' then
               if startcol > 1 then
                  if substr(line, startcol - 1, 2) = '*/' then  -- allow */ just before token
                     startcol = startcol + 1
                     id = substr(line, startcol, (endcol - startcol + 1))
                  /* test */endif/* test */               -- Apparently E allow comments as "word" delimiters
               endif;
               if endcol < length(line) then
                  temp = substr(line, endcol, 2)
                  if temp = '/*' then                     -- allow /* after token
                     id = substr(line, startcol, (endcol-startcol))
                     endcol = endcol - 1
                  endif--test
               endif
               --call dprintf("passist", "E Token after : '"id"'")
               case = 'c'                                 -- Case insensitive for all E tokens
               id = lowcase(id)
               line = lowcase(line)
               if 0 then
                  -- another placeholder
               ---- E compiler directives: compile if, compile else, compile elseif, compile endif ---------
               elseif id = 'compile' then
                  ECompileFlag = 1
                  temp = (substr(line, pos(id, line)))
                  call dprintf("passist", "Initial temp: "temp)
                  do while (pos('/*', temp) > 0) and (pos('*/', temp) > 0)
                     temp = substr(temp, pos('*/', temp))
                     call dprintf("passist", "Intermediate temp: "temp)
                  enddo
                  call dprintf("passist", "Final temp: "temp)
                  if (words(temp) = 0) then
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  else
                     lcword2 = word(temp, 2)
                     call dprintf("passist", "lcword2: "lcword2)
                     if wordpos(lcword2, 'if endif else elseif') then
--                      compile if/... code (when cursor is on compile
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
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
                  endif
               ---- E conditions: (compile) if, (compile) else, (compile) elseif, (compile) endif --------
               elseif wordpos( id, 'if endif else elseif') then
                  pcompile = pos('compile', line)
                  if pcompile & pcompile <= startcol then
                     -- compile if|endif|else|elseif
                     parse value line with part1 'compile' part2 (id) part3
                     call dprintf('passist', 'E if parse: "'part1'"compile"'part2'"'id'"'part3'"')
                     part1 = strip(part1)
                     part2 = strip(part2)
                     if (part1 = '' or ((length(part1) >= 4) and (leftstr(part1, 2) = '/*') and (rightstr(part1, 2) = '*/'))) and
                        (part2 = '' or ((length(part2) >= 4) and (leftstr(part2, 2) = '/*') and (rightstr(part2, 2) = '*/'))) then
                        ECompileFlag = 1
--                      compile if/... code (when cursor is on if/...
                        search = '^[ \t]*compile[ \t]*(/\*.*\*/)*[ \t]*\c(end)?if([; \t]|(--)|(/\*)|$)'
                        clist = leftstr(id, 1)
                        fForward = (clist <> 'e')
                        if fForward then  -- move to beginning
                           .col = length(part1) + 1
                        else       -- move to end, so first Locate will hit this instance.
                           end_line
                        endif
                        fIntermediate = (substr(lcword2, 2, 1) = 'l')
                     else
--                      /* compile */ if/... code
                        search = '(^|[ \t]|(\*/))\c(end)?if([; \t]|(--)|(/\*)|$)'
                        clist = leftstr(id, 1)
                        fForward = (clist <> 'e')
                        if fForward then  -- move to beginning
                           .col = startcol
                        else       -- move to end, so first Locate will hit this instance.
                           .col = endcol
                        endif
                        fIntermediate = (substr(id, 2, 1) = 'l')
                     endif
                  else
                     -- if|endif (without compile)
                     -- The found line is checked by a 2nd search for a preceding 'compile',
                     -- otherwise the re would have two many parentheses.
                   --search = '((\*/:o)|(^:o)|(^:o(~compile:w)))\c(end)?if([; \t]|(--)|(/\*)|$)'
                   --search = '((\*/:o)|(;:o)|(^:o)|(^:o(~compile:w)))\c(end)?if([; \t]|(--)|(/\*)|$)'
                     search = '(^|[ \t]|(\*/))\c(end)?if([; \t]|(--)|(/\*)|$)'
                     clist = leftstr(id, 1)
                     fForward = (clist <> 'e')
                     if fForward then  -- move to beginning
                        .col = startcol
                     else       -- move to end, so first Locate will hit this instance.
                        .col = endcol
                     endif
                     fIntermediate = (substr(id, 2, 1) = 'l')
                  endif
               ---- E loop keywords 1: loop, endloop     --------------------------------------------------
               elseif wordpos( id, 'loop endloop') then
                  search = '(^|[ \t]|(\*/))\c(end)?loop([; \t]|(--)|(/\*)|$)'
                  clist = leftstr( id, 1)
                  fForward = (clist <> 'e')
                  if fForward then  -- move to beginning
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol
                  endif
               ---- E loop keywords 2: for, endfor       --------------------------------------------------
               elseif wordpos( id, 'for endfor') then
                  search = '(^|[ \t]|(\*/))\c(end)?for([; \t]|(--)|(/\*)|$)'
                  clist = leftstr( id, 1)
                  fForward = (clist <> 'e')
                  if fForward then  -- move to beginning
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol
                  endif
               ---- E loop keywords 3: do, while, end, enddo, endwhile  -----------------------------------
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
                     call dprintf("passist", "Whilepos: "whilepos "Dopos: "dopos "Search: "search)
                  endif
                  clist = leftstr( id, 1)
                  call dprintf("passist", "clist: "clist)
                  fForward = (clist <> 'e')
                  if fForward then  -- move to beginning
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol
                  endif
               ---- E loop keywords 4: leave, iterate    --------------------------------------------------
               elseif wordpos( id, 'leave iterate') then
                  search = '(^|[ \t]|(\*/))\c(do|end|enddo|loop|endloop|for|endfor|endwhile)([; \t]|(--)|(/\*)|$)'
                  fForward = 0
                  clist = 'e'
                  clen = 1
                  .col = endcol
                  fIntermediate = 1
               else -- not a known balanceable E token
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): C, JAVA JAVASCRIPT and RC    -------------------------------------------
            elseif wordpos(Curmode, 'C JAVA RC JAVASCRIPT') > 0 then
               -- JBSQ: Was this "if" left out on purpose?
               if CurMode = 'C' then
                  if wordpos(id, 'if ifdef ifndef endif else elif') > 0 then -- Check for "#   if", etc.
                     .col = startcol
                     if next_nonblank_noncomment_nonliteral(mode, '-R') = '#' then
                        id = '#' || id
                        startcol = .col
                     endif
                     call prestore_pos(savepos)
                  endif
               endif
               if 0 then
                  --placeholder
               ---- Directive(s): #if #ifdef #ifndef #endif #else #elif    ---------------------
               elseif wordpos(id, '#if #ifdef #ifndef #endif #else #elif') then
                  if CurMode <> 'JAVA' and CurMode <> 'JAVASCRIPT' then
                     search = '\#[ \t]*\c((if((n?def)?))|endif)([ \t]|$)'
                     if CurMode = 'C' then
                        search = '^[ \t]*\c' || search
                     elseif startcol = 1 then  -- RC directives must start in column one
                        search = '^' || search
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
                     clist = substr(id, 2, 1)
                     fForward = (clist = 'i')
                     if fForward then  -- move to beginning
                        .col = startcol
                     else       -- move to end, so first Locate will hit this instance.
                        .col = endcol
                     endif
                     fIntermediate = (substr(id, 3, 1) = 'l')
                  else
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               ---- Keyword(s): do, try    ----------------------------------------------------
               elseif wordpos(id, 'do try') then
                  --  this code might be expanded to <anytoken> { .... }
                  if CurMode <> 'RC' then
                     setsearch 'xcom l /[{;]/xe+F'   -- does following a '{' precede a ';'?
                     passist_rc = passist_search(CurMode, '{ ;', 'e', 0, 1, /* stop on first 'hit' */ -1)
                     if passist_rc then
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     else
                        call dprintf("passist", "token {} '{;' search found: "substr(textline(.line), .col, 1))
                        if substr(textline(.line), .col, 1) = '{' then -- found the braces
                           search  = '[{}]'
                           fForward = 1
                           clist = '{'
                        else
                           passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN   -- token without braces
                        endif
                     endif
                  else
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               ---- Keyword(s): while      ----------------------------------------------------
               elseif id = 'while' then
                  if CurMode <> 'RC' then
                     setsearch 'xcom l /[()]/xe+F'     -- find the end of the conditional
                     passist_rc = passist_search(CurMode, '(', 'e', 0, 1, 0)
                     if passist_rc then                -- no conditional??
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     else
                        nextchar = next_nonblank_noncomment_nonliteral(CurMode)
                        if not nextchar then
                           passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                        else
                           call dprintf("passist", "while {; search found: "nextchar)
                           if nextchar = '{' then      -- must be while loop (i.e. NOT do/while) with braces
                              search  = '[{}]'
                              fForward = 1
                              clist   = '{'
                           elseif nextchar = ';'  then -- cursor is on the 'while' of a do/while loop
                              -- search  = '\{|\}|((^|[ \t])\cdo([ \t]|$))'
                              search  = '[{}]|((^|[ \t])\cdo([ \t]|$))'
                              fForward = 0
                              clist   = '}'
                              n = 2
                           else                        -- cursor is on a one-statement while loop
                              passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN   -- no braces follow, so JBSQ: unbalanceable?
                           endif
                        endif
                     endif
                  endif
/*
   JBSQ: The following code should work for break/continue statements within nested do and for loops
   which have braces.  Problems arise if there are do's or for's without braces between the
   break/continue and the enclosing loop.  Also problems arise if the enclosing loop is a
   while loop.

   The solution, if it is worth it, is to code the entire search here so that these different
   variations of loops can be handled correctly.

               ---- Keyword(s): break continue                                      ---------------------
               elseif wordpos(id, 'break continue' then
                  if CurMode <> 'RC' then
                     search       = '([{}])|((^|[ \t])\c(do|for)([ \t]|$))'
                     fForward      = 0
                     clist        = '}'
                     fIntermediate = 1
                  else
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
*/
               elseif CurMode = 'RC' then
                  -- All remaining RC tokens here
                  case = 'c'   -- RC files are case insensitive, except for direcives (#if, #define, etc.)
                  id = lowcase(id)
                  if wordpos(id, '{ } begin end') then
                     search = '[{}]|((^|[ \t])\c(begin|end)([ \t;]|$))'
                     fForward = (wordpos(id, '{ begin') > 0)
                     if fForward then  -- move to beginning          begin
                        .col = startcol
                        clist = '{ b'
                     else       -- move to end, so first Locate will hit this instance.
                        .col = endcol
                        clist = '} e'
                     endif
                  else
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               else
                  -- All remaining C/JAVA/JAVASCRIPT tokens here
                  idlist = 'case default default:'
                  if CurMode <> 'C' then
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

                     -- JBSQ: Check for next_nonblank_noncomemnt_nonliteral(CurMode) = '(' first?
                     -- (This would force the cursor to actually be on the function name.
                     -- The current code allows the cursor on any nonblank, noncomment,
                     -- nonliteral character preceding the parameter list.)
                     setsearch 'xcom l /[()]/xe+F'     -- find the ending ')' or ;
                     passist_rc = passist_search(CurMode, '(', 'e', 0, 1, 0)
                     call dprintf('passist', 'last chance c,... srch_rc line col' passist_rc .line .col)
                     if not passist_rc and substr(textline(.line), .col, 1) = ')' then -- no conditional??
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                        nextchar = next_nonblank_noncomment_nonliteral(CurMode)
                        if nextchar then
                           call dprintf("passist", "Generic token () {; search found: "nextchar)
                           if nextchar = '{' then      -- structure is: token (    ) { ... }
                              search = '[{}]'
                              fForward = 1
                              clist = '{'
                              passist_rc = PASSIST_RC_NO_ERROR
                           endif
                        endif
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
                  endif
               endif

            -- Mode(s): REXX
            elseif CurMode = 'REXX' then
            ---- REXX conditions: if, else --------------------------------------------------------------
               case = 'c'                      -- Case insensitive for all REXX tokens
               id = lowcase(id)
               if 0 then
                  -- another placeholder
               elseif wordpos( id, 'do end select when otherwise') then
                  search = '(^|[ \t])\c(do|end|select)([; \t]|$)'
                  fForward = (wordpos(id, 'do select') > 0)
                  if fForward then  -- move to beginning
                     clist = 'do se'
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     clist = 'en'
                     .col = endcol
                  endif
                  clen  = 2
                  fIntermediate = ((id = 'when') or (id = 'otherwise'))
               elseif id = 'else' then
                  .col = startcol
                  pchar = next_nonblank_noncomment_nonliteral(CurMode, '-R')
                  call dprintf("passist", 'Previous char:' pchar)
                  if lowcase(pchar) = 'd' then
                     if .col > 2 then
                        .col = .col - 2
                        pword = lowcase(substr(textline(.line), .col, 3))
                        if .col > 1 and substr(textline(.line), .col - 1, 1) <> ' ' then
                           --
                        else
                           call dprintf("passist", 'Previous word:' pword)
                           if pword = 'end' then
                              display -1
                              call passist()
                              display 1
                              endcol = .col
                           endif
                        endif
                     endif
                  endif
                  search = '(^|[ \t])\cif([ \t]|$)'
                  clist = 'i'
                  fForward = 0
                  fIntermediate = 1
                  .col = endcol
                  n = -1
compile if 0
               elseif wordpos( id, 'if else') then
                  -- JBSQ: How is this supposed to work?  If's don't always have else's
                  search = '(^|[ \t])(if|else)([ \t]|$)'
                  clist = leftstr( id, 1)
                  fForward = (clist <> 'e')
                  if fForward then  -- move to beginning
                     .col = startcol
                  else       -- move to end, so first Locate will hit this instance.
                     .col = endcol
                  endif
compile endif
               else -- not a known balanceable REXX token
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): IPF
            elseif CurMode = 'IPF' then
;                if wordpos(lowcase(id), ':ol :eol :ul :eul :sl :esl :dl :edl :parml :eparml') &
;                    pos(substr(line, endcol+1, 1), '. ') then
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
                     call dprintf("passist", "IPF ID wordpos: "wordpos(id, IPFTags))
                     call dprintf("passist", "IPF Tags: "IPFTags)
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
                        fIntermediate = (id = ':li' or id = ':lp')
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
                        fIntermediate = (id = ':row' or id = ':c')
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
                        fIntermediate = (id = ':pt' or id = ':pd')
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
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
                  else  -- not a known balanceable IPF token
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               else  -- not a known balanceable IPF token
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): HTML, WARPIN
            elseif (CurMode = 'HTML' or CurMode = 'WARPIN') then
               case = 'c'                      -- Case insensitive for all HTML tokens  (JBSQ: WARPIN, too?)
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
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): MAKE
            elseif CurMode = 'MAKE' then
               case = 'c'                      -- Case insensitive for all MAKE tokens
               id = lowcase(id)
               -- Currently ALL balanceable MAKE tokens must be on a line with '!' in column 1
               -- and if there are any characters between the '!' and the token they must
               -- be whitespace.
               if leftstr(line, 1) = '!' then
                  if startcol > 2 then         -- Are there characters between '!' and token?
                     if verify(substr(line, 2, startcol - 2), ' ' || \t) then
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                        id = ''                -- Disable further processing
                     endif
                  endif
                  if 0 then
                     -- placeholder
compile if USE_NMAKE32
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
                     fIntermediate = (substr(id, 2, 1) = 'l')
compile if USE_NMAKE32
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
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               else
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): Pascal
            elseif Curmode = 'PASCAL' then
               case = 'c'               -- case insensitive for PASCAL
               id = lowcase(id)
               --PascalStartBlockTokens = 'begin record try asm object class interface'
               PascalStartBlockTokens = 'begin record try asm'    -- object?, class, interface?
;   JBSQ: use case?  Case is used both for a switch-like statements and in variant records
;              PascalStartBlockTokens = PascalStartTokens 'case'
               if wordpos(id, PascalStartBlockTokens 'end except finally') then
                  search = '(^|[^a-zA_Z0-9_])\c(' || translate(PascalStartBlockTokens, '|', ' ') || '|end)([;. \t]|$)'
                  fForward = (wordpos(id, PascalStartBlockTokens) > 0)
                  clen = 3
                  if fForward then
                     .col = startcol
                     clist = ''
                     do i = 1 to words(PascalStartBlockTokens)
                        clist = clist leftstr(word(PascalStartBlockTokens, i), 3)
                     enddo
                  else
                     .col = endcol
                     clist = 'end'
                  endif
                  fIntermediate = (id = 'except' or id = 'finally')
               elseif wordpos(id, 'repeat until') then
                  search = '(^|[ \t])\c(repeat|until)([ \t]|$)'
                  fForward = (id = 'repeat')
                  if fForward then
                     .col = startcol
                     clist = 'r'
                  else
                     .col = endcol
                     clist = 'u'
                  endif
               elseif wordpos(id, 'while for') then
                  -- check for begin before ';' (i.e a block loop instead of a single statement loop)
                  setsearch 'xcom l /[ \t]\cdo([ \t]|$)/x' || case || 'c+F'  -- find the end of following 'do'
                  passist_rc = passist_search(CurMode, 'd', case, 0, 1, -1)
                  if passist_rc then                -- no 'do'??
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  else
                     .col = .col + 2
                     nextchar = next_nonblank_noncomment_nonliteral(CurMode)
                     if not nextchar then
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     else
                        call dprintf("passist", "while/for 'do' search found: "nextchar)
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN     -- assume bad
                        if lowcase(nextchar) = 'b' then
                           tmpline = textline(.line)
                           tmpline_len = length(tmpline)
                           call dprintf("passist", "col: ".col "len: "tmpline_len "line: "tmpline)
                           if tmpline_len >= .col + 4 then
                              if lowcase(substr(tmpline, .col, 5)) = 'begin' then
                                 if (tmpline_len > .col + 4) then
                                    nextchar = substr(tmpline, .col + 5, 1)
                                    call dprintf("passist", "charafter: '"nextchar"'")
                                    if nextchar = ' ' or nextchar = \9 then
                                       passist_rc = PASSIST_RC_NO_ERROR
                                    endif
                                 else
                                    passist_rc = PASSIST_RC_NO_ERROR
                                 endif
                                 if not passist_rc then
                                    search = '(^|[ \t])\cbegin|end([;. \t]|$)'
                                    fForward = 1
                                    clist = 'b'
                                 endif
                              endif
                           endif
                        endif
                     endif
                  endif
               else
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): (La)TEX
            elseif Curmode = 'TEX' then
            -- begin addition for TeX
            -- NOTE: There is some special code for \begin and \end which depends on 'clist'
            --       being set to 'be' or 'en'. If it becomes necessary to use these values
            --       for 'clist' for other TEX tokens, then the special code for \begin and
            --       end will break.
               coffset = 1                -- most TEX tokens use this offset
               tex_env = ''               -- default
            -- //PM additions: balanceable tokens for (La)TeX

            ---- TeX conditions: \if, \else, \fi --------------------------------------------------------
               if substr(id,1,3) = '\if' or wordpos(id, '\else \fi') then --// \if.. \else \fi
                  search = '\\(if|fi)'
                  clist = substr(id, 2, 1)
                  fForward = (clist = 'i') -- fForward=1: forward, fForward=0 backward search
                  if fForward then   -- move cursor so that the first Locate will hit this instance
                     .col = startcol -- \if: move to beginning
                  else
                     .col = endcol   -- \else,\fi: move to end
                  endif
                  fIntermediate = (id = '\else')

               ---- TeX environment: \begin..., \end... ----------------------------------------------------
               elseif id = '\begin' or id = '\end' then --// \begin.. \end..
                  search = '\\(begin|end)[ \t]*'
                  ---- LaTeX environment: \begin{...}, \end{...} -------------------------------------------
                  .col = endcol
                  if next_nonblank_noncomment_nonliteral(CurMode) == '{' then
                     call dprintf('passist', 'TEX: found } at '.line .col)
                     temp = substr(textline(.line), .col)
                     p = pos('}', temp)
                     if p > 0 then
                        tex_env = leftstr(temp, p)
                     endif
                  endif
                  call prestore_pos(savepos)
                  clist    = substr(id, 2, 2)
                  clen     = 2
                  fForward = (clist = 'be')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif

               elseif id = '\bgroup' or id = '\egroup' then
                  search = '\\(bgroup|egroup)'
                  clist = substr(id, 2, 1)
                  fForward = (clist = 'b')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif

               elseif id = '\begingroup' or id = '\endgroup' then
                  search = '\\(begingroup|endgroup)'
                  clist = substr(id, 2, 1)
                  fForward = (clist = 'b')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif

               elseif id = '\makeatletter' or id = '\makeatother' then
                  search = '\\makeat(letter|other)'
                  clist = substr(id, 8, 1)
                  fForward = (clist = 'l')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif
                  coffset = 7

               elseif id = '\[' or id = '\]' then
                  search = '\\(\[|\])'
                  clist = substr(id, 2, 1)
                  fForward = (clist = '[')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif

               elseif id = '\(' or id = '\)' then
                  search = '\\(\(|\))'
                  clist = substr(id, 2, 1)
                  fForward = (clist = '(')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif

               ---- TeX math -------------------------------------------------------------------------------
               elseif wordpos(id,'\left \right') then
                  search = '\\(left|right)'
                  clist = substr(id, 2, 1)
                  fForward = (clist = 'l')
                  if fForward then
                     .col = startcol
                  else
                     .col = endcol
                  endif
               else -- not a known balanceable 'TEX' token
                  passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
               endif

            -- Mode(s): FORTRAN77
            elseif (CurMode = 'FORTRAN77') then
               -- This code disregards the "token" and allows the cursor anywhere within
               -- columns 7-72
               if .col > 6 and .col < 73 then
                  statement = fortran77_extract_text(.line)
                  do i = .line + 1 to .last
                     temp = textline(i)
                     if pos(substr(temp, 6, 1), ' 0') then
                        leave
                     elseif not pos(leftstr(temp, 1), 'C*') then
                        statement = statement || fortran77_extract_text(i)
                     endif
                  enddo
                  statement = fortran77_remove_spaces(statement)
                  if leftstr(statement, 2) = 'DO' then
                     equalpos = pos('=', statement, 4)
                     commapos = pos(',', statement, 6)
                     if equalpos and commapos then    -- DO loop of some kind?
                        fForward = 1
                        clist = 'D'
                        .col = pos('D', line, 7)
                        p = verify(statement, '0123456789', 'N', 3)
                        if p > 3 then   -- DO <labelnum>,...      loop
                           label = substr(statement, 3, p - 3)
                           call dprintf('passist', 'label as string: 'label)
                           label = label + 0
                           call dprintf('passist', 'label as number: 'label)
                           temp = ''
                           do i = length(label) to 4
                              temp = temp || '[ 0]?'
                           enddo
                           search = '^('temp || label'[ 0]?[ ]*\c[^0])'
                           call dprintf("passist", "DO <label> search: "search)
                           'xcom l /'search'/x'
                           if rc = 0 then
                              passist_rc = -1
                           else
                              passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                           endif
                           call dprintf('passist', 'F77 search rc: 'rc)
compile if 0
DO/ENDDO is not FORTRAN77 but the code (esp. the regex search string) for future use
                        else            -- DO var = xx,limit      loop
                           search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*\c((D[ ]*O[ ]*[A-Z][A-Z0-9]*[ ]*=.+,)|(E[ ]*N[ ]*D[ ]*D[ ]*O))'
compile else
                        else
                           passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
compile endif
                        endif
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
compile if 0
DO/ENDDO is not FORTRAN77 but the code (esp. the regex search string) for future use
                  elseif statement = 'ENDDO' then
                     search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*\c((D[ ]*O[ ]*[A-Z][A-Z0-9]*[ ]*=.+,)|(E[ ]*N[ ]*D[ ]*D[ ]*O))'
                     fForward = 0
                     clist = 'E'
                     .col = pos('E', line, 7)
compile endif
compile if 0
; - FORTRAN77 support (beyond the generic ()[]{} matching and do <label> ...) is disabled.
; - The code below tries to match "Block" IF's (i.e. IF(<condiiton>)THEN ... ENDIF)
; - But FORTRAN allows statements to be contiued. This means that for "IF (confition) THEN"
; the IF and the THEN might be on different lines.
; - For long conditions the use of continuations can make stylistic sense. For example:
;           IF( CARDS(I)(2:2) .EQ. 'J'
;      1   .OR. CARDS(I)(2:2) .EQ. 'Q'
;      2   .OR. CARDS(I)(2:2) .EQ. 'K' )THEN
; - Unless grep searches start supporting searches across multiple lines, the only way to
; implement matching with this kind of code is
; 1) Create a temporary file
; 2) Rewrite the original file in to the temp file, "merging" the continuation lines in the process
; 3) Somehow keep track of which columns of the merged lines came from which lines and columns of the original file
; 4) Perform a search on the temp file
; 5) Use the data from #3 to map the location of the "found" string back into the original file
; 6) Discard the temp file
; - At this time the effort need to make this work was deemed not worth the "value" of matching
; "Block" IF's in FORTRAN.
                  elseif leftstr(statement, 3) = 'IF(' then
                     if pos(')THEN', statement) then       -- Assume ')THEN' is NOT in a literal?
                        search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*\c((I[ ]*F[ ]*(.*)[ ]*T[ ]*H[ ]*E[ ]*N)|(E[ ]*N[ ]*D[ ]*I[ ]*F))'
                        fForward = 1
                        clist = 'I'
                        .col = pos('I', line, 7)
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN  -- IF without THEN is unbalanceable
                     endif
                  elseif leftstr(statement, 7) = 'ELSEIF(' then
                     if pos(')THEN', statement) then       -- Assume ')THEN' is NOT in a literal?
                        search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*\c((I[ ]*F[ ]*(.*)[ ]*T[ ]*H[ ]*E[ ]*N)|(E[ ]*N[ ]*D[ ]*I[ ]*F))'
                        fForward = 0
                        fIntermediate = 1
                        clist = 'E'
                        .col = pos('E', line, 7)
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN  -- ELSEIF without THEN is unbalanceable
                     endif
                  elseif statement = 'ENDIF' then
;                    search =  ^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*\c((I[ ]*F[ ]*(.*)[ ]*T[ ]*H[ ]*E[ ]*N)|(E[ ]*N[ ]*D[ ]*I[ ]*F))'
                     search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9][ 0]+\c((I[ ]*F[ ]*\(.*\)T[ ]*H[ ]*E[ ]*N)|(E[ ]*N[ ]*D[ ]*I[ ]*F))'
                     fForward = 0
                     clist = 'E'
                     .col = pos('E', line, 7)
compile endif
compile if 0
FORTRAN77 does not require END (of program/subroutine/function statements, nor is a PROGRAM statement require
                  elseif not pos('=', statement) then  -- remaining matchable tokens require this
                     function_pos = pos('FUNCTION', statement)
                     punc_pos     = verify(statement, "+-*/=().,':$!", 'M')
                     function_statement = (function_pos > 0 and (punc_pos = 0 or function_pos < punc_pos))
                     if leftstr(statement, 7)  = 'PROGRAM'    or
                        leftstr(statement, 10) = 'SUBROUTINE' or
                        leftstr(statement, 9)  = 'BLOCKDATA'  or
                        function_statement                    or
                        strip(statement)       = 'END'        then
                        search = '^[ 0-9][ 0-9][ 0-9][ 0-9][ 0-9].[ ]*((('
                        search = search || '(\cP[ ]*R[ ]*O[ ]*G[ ]*R[ ]*A[ ]*M)|'
                        search = search || '(\cS[ ]*U[ ]*B[ ]*R[ ]*O[ ]*U[ ]*T[ ]*I[ ]*N[ ]*E)|'
                        search = search || '(\cB[ ]*L[ ]*O[ ]*C[ ]*K[ ]*D[ ]*A[ ]*T[ ]*A)|'
                        search = search || '([A-Z][A-Z0-9]*[ ]*\cF[ ]*U[ ]*N[ ]*C[ ]*T[ ]*I[ ]*O[ ]*N))'
                        search = search || '[ ]*(~[=])*)|(\cE[ ]*N[ ]*D[ ]*$))'
                        fForward = (strip(statement) <> 'END')
                        if function_statement then
                           .col = pos('FUNCTION', line, 7)
                        else
                           .col = verify(line, ' ', 'N', 7)
                        endif
                        if fForward then
                           clist = 'P S B F'
                        else
                           clist = 'E'
                        endif
                     else
                        passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                     endif
compile endif
                  else
                     passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
                  endif
               else
                  passist_rc = PASSIST_RC_BAD_FORTRAN77_CURSOR -- Cursor before col 7 or after col 72
               endif
            else -- not a known balanceable token or a mode that is not yet supported
               passist_rc = PASSIST_RC_MODE_NOT_SUPPORTED
            endif
         endif -- if find_token/not find_token
      endif -- if GOLD/not gold

      if not passist_rc then
         if fForward then direction='+F'; else direction='-R'; endif
         call dprintf("passist", "id clist fForward fIntermediate:" id "'"clist"'" fForward fIntermediate)
         call dprintf("passist", 'search: xcom l %'search'%x'case||direction)

         if fIntermediate then
            -- search begin of condition
            setsearch 'xcom l '\1''search\1'x'case''direction
            --'postme circleit' .line startcol endcol
         else
            'xcom l '\1''search\1'x'case''direction
            if rc = 0 then  -- if found
               call highlight_match()
            endif
            --'postme circleit' .line startcol endcol  -- this one should not be highlighted
            -- designed for function_name(...)  <-- function_name is highlighted, not the ( and ).
         endif

         passist_rc = passist_search( CurMode, clist, case, coffset, clen, n, tex_env, ECompileFlag)
      endif                                 -- if OK to search
   endif

   if passist_rc > 0 then
      call prestore_pos(savepos)
      if passist_rc = PASSIST_RC_IN_ONELINE_COMMENT then
         sayerror "Invalid: One-line comment starts in column "comment_data
      elseif passist_rc = PASSIST_RC_IN_MULTILINE_COMMENT then
         sayerror "Invalid: Multi-line comment starting at "CommentStartLine","CommentStartCol" and ending at "CommentEndLIne","CommentEndCol
      elseif passist_rc = PASSIST_RC_IN_LITERAL then
         sayerror "Invalid: Cursor located within a literal."
      elseif passist_rc = PASSIST_RC_NOT_ON_A_TOKEN then
         sayerror "Invalid: Cursor is not located on a token."
      elseif passist_rc = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN then
         sayerror UNBALANCED_TOKEN__MSG
      elseif passist_rc = PASSIST_RC_MODE_NOT_SUPPORTED then
         sayerror "Token balancing not yet supported for mode: "CurMode
      else
         sayerror "Unknown rc: "passist_rc
      endif
   else
      sayerror 1
      newline = .line; newcol = .col
      call prestore_pos(savepos)
      .col = newcol
      .lineg = newline
      right; left                      -- scroll_to_cursor
   endif
   call prune_assist_array()
   setsearch search_command           -- Restores user's command so Ctrl-F works.
   return passist_rc

; ---------------------------------------------------------------------------
;  passist_search: perform the actual search for the matching token (which is
;     NOT located within a comment or literal).
; ---------------------------------------------------------------------------
defproc passist_search(mode, clist, case, coffset, clen, n)
   tex_env      = arg(7)
   ECompileFlag = arg(8)
   retval = 0
   loop
      call dprintf("passist", "before search pos: ".line",".col "n = "n)
      repeatfind
      if rc then leave; endif
      call dprintf("passist", "Match at ".line",".col)
      if inside_comment(mode) then
         iterate
      endif
      if inside_literal2(mode) then
         iterate
      endif

      if mode = 'E' & ECompileFlag <> 1 then
         -- if|endif (without compile)
         line     = textline( .line)
         leftline = lowcase( leftstr( line, .col - 1))
         pcompile = pos( 'compile:w', leftline, 1, 'x')
         if pcompile & pcompile <= .col then
            iterate
         endif
      endif

      call dprintf("passist", "line# ".line" col: ".col" text: "textline(.line))
      cword  = substr(textline(.line), .col + coffset, clen)
      if case = 'c' then
         cword = lowcase(cword)
      endif
      call dprintf("passist", "CList: "clist "Cword: "cword "Coffset: "coffset "CLen: "clen)
      if wordpos(cword, clist) then
         n = n + 1;
      else
         n = n - 1
      endif

      call dprintf("passist", 'after n = 'n)
      retval = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN * (rc = sayerror('String not found'))
      if n=0 then
         leave
      endif
   endloop
   if retval = 0 and mode == 'TEX' and (clist = 'be' or clist = 'en') then
      call psave_pos(texsavepos)
      if clist = 'be' then
         .col = .col + 3
      else
         .col = .col + 5
      endif
      nextchar = next_nonblank_noncomment_nonliteral(mode)
      call dprintf("passist", "TEX env: "tex_env" NextChar: "nextchar)
      if tex_env <> '' then
         if nextchar == '{' then
            call dprintf("passist", "TEX env found { at ".line .col)
            if substr(textline(.line), .col, length(tex_env)) == tex_env then
               call dprintf("passist", "TEX env matched")
            else
               retval = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
            endif
         else
            retval = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
         endif
      else
         if nextchar = '{' then
            retval = PASSIST_RC_NOT_ON_A_BALANCEABLE_TOKEN
         endif
      endif
      call prestore_pos(texsavepos)
   endif
   return retval

; ---------------------------------------------------------------------------
;  inside_literal: determine if the cursor is within a literal. This routine
;     first determines if the cursor is within a comment (since literals
;     within comments are not "real" literals). Return values:
;        0:     the cursor is NOT within a literal.
;        other: the cursor IS within a literal.
; ---------------------------------------------------------------------------
defproc inside_literal(mode)
   if inside_comment(mode) then
      retval = 0
   else
      retval = inside_literal2(mode)
   endif
   return retval

; ---------------------------------------------------------------------------
;  inside_literal2: determine if the cursor is within a literal. Unlike
;     inside_literal, this routine does not first determine if the cursor
;     is within a comment. This is called by inside_literal and can be
;     called directly if the test for the presence of a comment is unneeded.
;     Return values:
;        0:     the cursor is NOT within a literal.
;        other: the cursor IS within a literal.
; ---------------------------------------------------------------------------
defproc inside_literal2(mode)
   call dprintf("lit2", "Entry: ".line .col)
   call psave_pos(savepos2)
   getsearch search_command2  -- Save caller's search command.
   curline  = .line
   curcol  = .col
   line = textline( .line )
   retval = 0
   parse value GetLitChars(mode) with StartLitChars EndLitChars EscapeChars
   if StartLitChars then
      endpos = 0
      loop
         startpos = verify(line, StartLitChars, 'M', endpos + 1)  -- find first start-of-literal
         call dprintf("lit2", "startpos curcol line: "startpos curcol line)
         if not startpos then                                     -- if none, exit
            leave
         elseif startpos >= curcol then                           -- if past cursor position, exit
            leave
         endif
         startq     = substr(line, startpos, 1)     -- extract start-of-literal char
         qpos       = pos(startq, StartLitChars)    -- determine which start-of-literal char
         escapechar = substr(EscapeChars, qpos, 1)  -- select matching escape char
         endq       = substr(EndLitChars, qpos, 1)  -- select matching end-of-literal char
         endpos     = startpos
         loop
            endpos  = verify(line, endq || escapechar, 'M', endpos + 1)  -- find next end-of-literal or escape char
            call dprintf("lit2", "startq startpos endq endpos escapechar: "startq startpos endq endpos escapechar)
            if endpos >= curcol then         -- JBSQ: Don't care if literal is properly closed?
               retval = 1
               leave
            elseif not endpos then           -- No end "quote"??
               sayerror "Unmatched start-of-literal character: "startq "at "curline","startpos
               call dprintf("lit2", "Unmatched start-of-literal character: "startq "at "curline","startpos)
               retval = 1                    -- JBSQ: Return true on unmatched "quote"?
               leave
            elseif endq = escapechar then    -- escape "quote"s case 1: doubled "quotes"
               if length(line) > endpos then
                  if substr(line, endpos + 1, 1) = endq then  -- doubled-"quote" escape sequence?
                     endpos = endpos + 1                      -- "jump" past doubled "quote"
                     call dprintf("lit2", "Doubled-quote")
                     iterate
                  else                       -- not escaped and endpos < curcol
                     leave                   --     literal starts and ends before cursor col
                  endif
               else                          -- end-of-literal at end-of-line
                  retval = 1
                  leave
               endif
            elseif substr(line, endpos, 1) = escapechar then  -- escaped char
               -- JBSQ: Don't care which char and assume not at end of line?
               endpos = endpos + 1
               call dprintf("lit2", "Escaped char")
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
   setsearch search_command2 -- Restores user's command so Ctrl-F works.
   call prestore_pos(savepos2)
   call dprintf("lit2", "Exit: "retval .line .col)
   return retval

; ---------------------------------------------------------------------------
;  GetLitChars: a routine which, given a mode, returns the start-of-literal,
;     end-of-literal and escape characters for that mode. The return value
;     is three "words". Each character of the first "word" is a start-of-literal
;     character. The corresponding character in the second "word" is the
;     corresponding end-of-literal character. The third "word is a list of the
;     escape characters, if any, which allow a literal to include a start-of-literal,
;     end-of-literal or itself in a literal.
; ---------------------------------------------------------------------------
defproc GetLitChars(mode)
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
   elseif mode = 'MAKE' or mode = 'RC' or mode = 'WARPIN' then
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
;    elseif mode = 'ADA' then               -- JBSQ: ADA strings and chars are default: (" " and ' ')?
;       StartLitChars = DoubleQuote || '%'
;       EndLitChars   = StartLitChars
;       EscapeChars   = \0\0                -- JBSQ: Escape Chars?
   elseif wordpos(mode, 'DEF PASCAL FORTRAN77') > 0 then
      StartLitChars = SingleQuote
      EndLitChars   = SingleQuote
      if mode = 'DEF' then
         EscapeChars   = \0
      else
         EscapeChars   = SingleQuote
      endif
   -- other modes here
   endif
   return StartLitChars EndLitChars EscapeChars

; ---------------------------------------------------------------------------
;  InsideComment: a front-end call to InsideComment2. This is used when the
;     location of the comment, returned by inside_comment2, is not needed.
; ---------------------------------------------------------------------------
defproc inside_comment(mode)
   return inside_comment2(mode, dummy)

; ---------------------------------------------------------------------------
;  InsideComment2: determines if the cursor is located within a comment,
;     multi-line or single-line. The input is the mode and a "var" variable
;     (named "comment_data") in which the location of the comment is returned
;     to the caller.
;
;     return value 0 => cursor is NOT within a comment
;        and comment_data is meaningless
;     return value 1 => cursor IS within a one-line comment
;        and comment_data is set to the column of the start of one-line comment
;     return value 2 => cursor IS within a multi-line comment
;        and comment_data is set to 6 blank-separated words:
;           The line, col and length of the starting MLC token and
;           the line, col and length of the ending MLC token.
; ---------------------------------------------------------------------------
defproc inside_comment2(mode, var comment_data)
   display -2
   call dprintf("comm", "Entry: ".line .col)
   call psave_pos(savepos2)
   getsearch search_command2  -- Save caller's search command.
   retval = 0
   comment_data = ""
   curline  = .line
   curcol  = .col
   line = textline(.line)
   MLCCase = 'c'              -- JBSQ: Ignore case for ALL MLC's?
   MLCData =  locateMLC(mode, curline, curcol)
   parse value MLCData with BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
   if BestMLCStartLine > 0 then
      retval = 2
   endif
   call dprintf("comm", "Retval on exit of outer MLC loop: "retval "cursor: ".line",".col)
   if retval = 0 then
      SLCPosition = inside_oneline_comment(mode)
      comment_data = SLCPosition
      retval = (SLCPosition > 0)
   else
      comment_data = BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
   endif
   setsearch search_command2 -- Restores user's command so Ctrl-F works.
   display 2
   call dprintf( "comm", "MLC rc: "retval comment_data)
   return retval

; ---------------------------------------------------------------------------
;  locateMLC: Determine if provided location (line, col) is within a multi-line
;     comment (MLC) for the provided mode. The return value is six space-separated
;     numbers representing:
;        Start line of MLC
;        Start col of MLC
;        Length of the Start MLC token
;        End line of MLC
;        End col of MLC
;        Length of the End MLC token
;     All zeroes indicate that the given line, col is NOT within an MLC.
; ---------------------------------------------------------------------------
defproc locateMLC(mode, line, col)
   MLCCount = buildMLCArray(mode)
   call dprintf("array", "locateMLC mode: "mode line","col "MLCCount: "MLCCount)
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
      call dprintf("array", "Listcount #"i": "MLCListCount)
      do j = 1 to MLCListCount
         MLCEntry = GetAVar(listindexbase || i'.List.'j)
         call dprintf("array", "MLCEntry: "MLCEntry)
         parse value MLCEntry with MLCStartLine MLCStartCol MLCStartLen MLCEndLine MLCEndCol MLCEndLen
         call dprintf("array", "test1: "((MLCEndLine > line) or (MLCEndLine = line and (MLCEndCol + MLCEndLen) > col)))
         call dprintf("array", "test2: "((MLCStartLine < line) or (MLCStartLine = line and MLCStartCol <= col)))
         call dprintf("array", "test3: "((MLCStartLine > BestMLCStartLine)  or (MLCStartLine = BestMLCStartLine and MLCStartCol > BestMLCStartCol)))
         if (MLCEndLine > line) or (MLCEndLine = line and (MLCEndCol + MLCEndLen) > col) then
            if (MLCStartLine < line) or (MLCStartLine = line and MLCStartCol <= col) then
               if (MLCStartLine > BestMLCStartLine)  or (MLCStartLine = BestMLCStartLine and MLCStartCol > BestMLCStartCol) then
                  parse value MLCEntry with BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen
                  call dprintf("array", "   Best, so far" MLCEntry)
                  leave   -- LISTCOMM: with current buildMLC logic, first should be "best"
               endif
            endif
         endif
      enddo
   enddo
   return BestMLCStartLine BestMLCStartCol BestMLCStartLen BestMLCEndLine BestMLCEndCol BestMLCEndLen

; ---------------------------------------------------------------------------
;  buildMLC: Build an array containing the start and end points of all multi-line
;     comments in the current file.
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
   call dprintf("array", "Build mode: "mode "MLCCount: "modeMLCCount)
   if modeMLCCount > 0 then
      call dprintf("array", "Extracted Starts: "MLCStartChars "Ends: "MLCEndChars "Nests: "MLCNestList "Count: "modeMLCCount)
      Rebuild = GetAVar(listindexbase'Rebuild')
      call dprintf("array", "Rebuild: '"rebuild"'")
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
            call dprintf("array", "MLC data: "MLCStart MLCEnd MLCNest)
            MLCStartSearch   = escape_search_chars(MLCStart)
            MLCEndSearch     = escape_search_chars(MLCEnd)
            call dprintf("array", ""MLCStart "search = "MLCStartSearch)
            call dprintf("array", ""MLCEnd "search = "MLCEndSearch)
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
                  if inside_oneline_comment(mode) then
                     right
                     iterate
                  endif
                  if inside_literal2(mode) then
                     right
                     iterate
                  endif
                  MLCStartLine = .line
                  MLCStartCol  = .col
                  call dprintf("comm", MLCStart "found at" MLCStartLine MLCStartCol)
                  NestedStartsList = MLCStartLine MLCStartCol NestedStartsList
                  if MLCNest then
                     setsearch 'xcom l ' || \1 || '(' || MLCStartSearch || '|' || MLCEndSearch || ')' || \1 || 'x' || MLCCase || '+F'
                  else
                     setsearch 'xcom l ' || \1 || MLCEndSearch || \1 || 'x' || MLCCase || '+F'
                  endif
--                right          the repeatfind does the "right"
                  do while ((MLCFindRC = 0) and (NestedStartsList <> ''))
                     call dprintf("comm", "MLCEnd, presearch loc: ".line",".col)
                     repeatfind
                     MLCFindRC = rc
                     if MLCFindRC then leave; endif
                     call dprintf("comm", "MLCEnd, postsearch loc: ".line",".col)
                     SLCPosition = inside_oneline_comment(mode, 1)
                     if SLCPosition then
                        right
                        iterate
                     endif
--                   JBSQ: MLC's "in-progress" can't be in literals?
--                   if inside_literal2(mode) then
--                      iterate
--                   endif
                     call dprintf("comm", "line# ".line" col: ".col" text: "textline(.line))
                     if substr(textline(.line), .col, MLCEndLen) = MLCEnd then
                        parse value NestedStartsList with MLCStartLine MLCStartCol NestedStartsList
                        array_index  = array_index + 1
                        array_value  = MLCStartLine MLCStartCol MLCStartLen .line .col MLCEndLen
                        call SetAvar(listindexbase || i || '.List.' || array_index, array_value)
                     else
                        -- this code should only be reached if MLCNest = 1 and MLCStart was matched
                        NestedStartsList = .line .col NestedStartsList
                     endif
                     call dprintf("comm", 'after Nestlist: 'NestedStartsList)
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
;  GetMLCCHars: Return the tokens which start and end multi-line comments
;     for the given mode. Also returned is whether the MLC can be nested
;     within another MLC. These values are returned through three "var"
;     parameters. Each "word" of each these parameters represents the
;     start token, the end token and a flag indicating if theat MLC can
;     be nested within another.
; ---------------------------------------------------------------------------
defproc GetMLCChars(mode, var MLCStartChars, var MLCEndChars, var MLCNestFLags)
   MLCStartChars = QueryModeKey(mode, 'MultiLineCommentStart')
   if MLCStartChars <> '' then
      MLCEndChars = QueryModeKey(mode, 'MultiLineCommentEnd')
      MLCNestFlags = QueryModeKey(mode, 'MultiLineCommentNested', '0')
   endif
   return

; ---------------------------------------------------------------------------
;  escape_search_chars: this routine takes a "search-for-this" search string
;     and it inserts escape characters in front of any extended grep
;     metacharacters. For example if the search string is "(abc)" (i.e.
;     find "(abc)" the this routine returns "\(abc\)" because "(" and ")"
;     are extended grep metacharacters and so they must be "escaped" with "\"
; ---------------------------------------------------------------------------
defproc escape_search_chars(search_string)
   p = -1
   loop
      p = verify(search_string, EGREP_METACHARACTERS, 'M', p + 2)
      if not p then
         leave
      else
         search_string = leftstr(search_string, p - 1) || '\' || substr(search_string, p)
      endif
   endloop
   return search_string

; ---------------------------------------------------------------------------
;  inside_oneline_comment: determines if the cursor is located within a
;     single line comment. Returns the column of the start of the comment.
;     A value of 0 is returned if no one-line comment is found. An optional
;     second parameter is used to indicate that a MLC is "in-progress".
; ---------------------------------------------------------------------------
defproc inside_oneline_comment(mode)
   line = textline(.line)
   call dprintf("1line", "Entry: ".line .col "Mode = "mode)
   if arg(2) == '' then
      MLCInProgress = 0
   else
      MLCInProgress = arg(2)
   endif
   retval = 0
   indexbase = 'assist.mode.'mode'.'
   SLCCount = GetAVar(indexbase || 'SLC.0')
   if SLCCount = '' then
      call GetSLCChars(mode, SLCCharList, SLCPosList, SLCNeedList, SLCOverrideMLCList)
      SLCCount = words(SLCCharList)
      call dprintf("1line", "SLCCount: "SLCCount)
      call SetAVar(indexbase || 'SLC.0', SLCCount)
      do i = 1 to SLCCount
         call SetAVar(indexbase || 'SLC.'            || i, word(SLCCharList, i))
         call SetAVar(indexbase || 'SLCPos.'         || i, word(SLCPosList, i))
         call SetAVar(indexbase || 'SLCNeed.'        || i, word(SLCNeedList, i))
         call SetAVar(indexbase || 'SLCOverrideMLC.' || i, word(SLCOverrideMLCList, i))
      enddo
   endif

   do SLCIndex = 1 to SLCCount
      if MLCInProgress then
         if not GetAVar(indexbase || 'SLCOverrideMLC.' || SLCIndex) then
            iterate
         endif
      endif
      SLC      = GetAVar(indexbase || 'SLC.'     || SLCIndex)
      SLCPos   = GetAVar(indexbase || 'SLCPos.'  || SLCIndex)
      SLCNeed  = GetAVar(indexbase || 'SLCNeed.' || SLCIndex)
      call dprintf("1line", "SLC/Pos/Need: "SLC"/"SLCPos"/"SLCNeed)
      if SLCNeed = 1 then
         SLC = SLC || ' '
      endif
      if SLCPos < 0 then
         if .col = -SLCPos then
            return 0
         else
            SLCPos = '0'           -- SLC is in an acceptable column so treat it as any other '0'-type
         endif
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
            if not inside_literal2(mode) then
               leave
            endif
         endloop
         .col = savecol
         if (p and p <= .col) then                     -- if found before cursor location
            if (retval = 0 or (retval > 0 and p < retval)) then
               retval = p
               call dprintf("1line", "Found "SLC" comment")
            endif
         endif
      elseif SLCPos = 'F' then
         call dprintf("1line", "PosF "leftstr(word(line, 1), length(SLC)))
         if leftstr(word(line, 1), length(SLC)) = SLC then
            call dprintf("1line", "Found '"SLC"' comm")
            p = pos(SLC, line)
            if (retval = 0) or (p < retval) then
               retval = p
            endif
         endif
      elseif SLCPos = '1' then
         call dprintf("1line", "Pos1 "leftstr(line, length(SLC)))
         if leftstr(line, length(SLC)) = SLC then
            call dprintf("1line", "Found '"SLC"' comm")
            retval = 1
            leave
         endif
      endif
   enddo
   call dprintf("1line", "Exit: "retval .line .col)
   return retval

; ---------------------------------------------------------------------------
;  GetSLCChars: Returns the single-line comment data for the given mode
;     For each possible SLC the following is returned:
;        The token which initiates the SLC (SLCCharlist)
;        A flag indicating any positional requirements (SLCPosList)
;           0: SLC can start anywhere on a line
;           1: SLC MUST start in column 1
;           F: SLC must be the first non-blank on the line
;           <negative_number> : SLC must NOT start in this column (-6 mean SLC must NOT
;              start in column 6)
;        A flag indicating if the token must be followed by a blank (SLCNeedList)
;           0: No (i.e. ANY character may follow the start token
;           1: A blank must follow the token
;        A flag indicating if the SLC will "comment out" a closing MLC token (SLCOverrideMLCList)
;           0: No
;           1: Yes
; ---------------------------------------------------------------------------
defproc GetSLCChars(mode, var SLCCharList, var SLCPosList, var SLCNeedList, var SLCOverrideMLCList)
   SLCCharList = QueryModeKey(mode, 'LineComment', '')
   if SLCCharList <> '' then
      SLCNeedList = QueryModeKey(mode, 'LineCommentNeedSpace', '0')
      SLCPosList = QueryModeKey(mode, 'LineCommentPos', '0')
      SLCOverrideMLCList = QueryModeKey(mode, 'LineCommentOverrideMulti', '0')
   endif
   return

; ---------------------------------------------------------------------------
;  prune_assist_array: Clear the comment array
; ---------------------------------------------------------------------------
defproc prune_assist_array()
   getfileid fid
   call SetAVar("assist."fid".Rebuild", 1)
   return

; ---------------------------------------------------------------------------
;  next_nonblank_noncomment_nonliteral: repositions the cursor as the name
;     of the routine describes.
; ---------------------------------------------------------------------------
defproc next_nonblank_noncomment_nonliteral(mode)
   direction = arg(2)
   if direction = '' or not wordpos(direction, '+F -R') then
      direction = '+F'
   endif
   getsearch savesearch
   setsearch 'xcom l /[^ \t]+/x'direction    -- find the next non-blank
   loop
      repeatfind
      if not rc then
         comment_rc = inside_comment2(mode, comment_data)
         --call dprintf("passist", "next pos: ".line",".col "Char: '"substr(textline(.line), .col, 1)'"' "comment_rc: "comment_rc)
         if not comment_rc then
            retval = (substr(textline(.line), .col, 1))
            leave
         elseif comment_rc = 1 then
            if direction = '+F' then
               endline
            else
               .col  = word(comment_data, 1)
            endif
         else
            parse value comment_data with MLCStartLine MLCStartCol . MLCEndLine MLCEndCol MLCEndLen
            --call dprintf("passist", "next comment data: "MLCEndLine MLCEndCol MLCEndLen)
            if direction = '+F' then
               .line = MLCEndLine
               .col  = MLCEndCol + MLCEndLen - 1
            else
               .line = MLCStartLine
               .col  = MLCStartCol
            endif
         endif
      else
         retval = ''
         leave
      endif
   endloop
   setsearch savesearch
   return retval

; ---------------------------------------------------------------------------
;  fortran77_extract_text: In FORTRAN the text of interest to passist is
;     located only in columns 6-72.  (An exception is when FORTRAN90-style
;     SLC's are supported.) This routine extracts and returns the text of
;     interest to the passist routine.
; ---------------------------------------------------------------------------
defproc fortran77_extract_text(linenum)
   text = substr(textline(linenum), 7, 66)     -- columns 7 -72
compile if 0 /* USE_FORTRAN90_SLC = 1 */
   if pos("!", text) then
      call psave_pos(savepos3)
      .line = linenum
      .col  = 7
      setsearch 'xcom l /!/xe+F'
      fortran90_rc = passist_search('FORTRAN90', '!', 'e', 0, 1, -1)
      if not rc then
         if .line = linenum and .col > 6 then
            if .col = 7 then
               text = ''
            else
               text = substr(linenum, 7, .col - 6)
            endif
         endif
      endif
      call prestore_pos(savepos3)
   endif
compile endif
   return text

; ---------------------------------------------------------------------------
;  fortran77_remove_spaces: In FORTRAN spaces which are not located within a
;     literal are irrelevant. This routine removes these insignificant spaces,
;     if any.
; ---------------------------------------------------------------------------
defproc fortran77_remove_spaces(text)
   if pos(' ', text) then
      getfileid fid
      'e .temp_fortran'
      insertline text
      p = 0
      .col = 1
      .line = 1
      loop
         p = pos(' ', textline(1), p + 1)
         if p then
            .col = p
            if not inside_literal2('FORTRAN77') then
               delete_char
               p = 0
               .col = 1
            endif
         else
            leave
         endif
      endloop
      getline text
      .modify = 0
      'quit'
      activatefile fid
   endif
   return text


; ---------------------------------------------------------------------------
;  t8: Dynamically set the array variable 'debuglist' which is used by
;  the dprintf proc.
; ---------------------------------------------------------------------------
compile if NEPMD_DEBUG
defc t8
-- AddAVar( 'debuglist', str)
   SetAVar( 'debuglist', arg(1))
compile endif

; defproc dprintf(routine, msg)
;    'dprintf 'routine msg

compile if NEPMD_DEBUG
defc t10
   list = GetAVar( 'debuglist')
   sayerror 'debuglist (b4): 'list
compile endif

