/****************************** Module Header *******************************
*
* Module Name: assist.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: assist.e,v 1.3 2002-08-09 19:45:51 aschn Exp $
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
/*  Ctrl-[, Ctrl-]  -- move to corresponding BalTok                          */
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
/*****************************************************************************/

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
compile endif  -- not defined(SMALL)

const GOLD = '(){}[]<>'  -- Parens, braces, brackets & angle brackets.
compile if    not defined(LOCATE_CIRCLE_STYLE)
   LOCATE_CIRCLE_STYLE = 1
compile endif
 compile if not defined(LOCATE_CIRCLE_COLOR1)
   LOCATE_CIRCLE_COLOR1 = 16777220
 compile endif
 compile if not defined(LOCATE_CIRCLE_COLOR2)
   LOCATE_CIRCLE_COLOR2 = 16777218
 compile endif

def c_leftbracket, c_rightbracket = call passist()

defproc passist
   call psave_pos(savepos)
   case = 'e'
   id = ''
   force_search = 0
   n=1
   c=substr(textline(.line),.col,1)
   if c==' ' & .col > 1 then
      left
      c=substr(textline(.line),.col,1)
   endif
   GETSEARCH search_command -- Save user's search command.
   k=pos(c,GOLD)            --  '(){}[]<>'
   if k then
      search = substr(GOLD,(k+1)%2*2-1,2)
      incr = 0
   else
                     -- Add '.' to default token_separators & remove ':' for GML markup.
      if pos(c, '*/') then
         seps = '/*'
      else
         seps = ' ~`!.%^&*()-+=][{}|\;?<>,''"'\t
      endif
      if find_token(startcol, endcol,  seps, '/* */') then
         getline line
         if startcol>1 then
            if substr(line, startcol-1, 1)='<' then
               startcol = startcol - 1
            endif
         endif
         id = substr(line, startcol, (endcol-startcol)+1)
         if id='.' & .col > 1 then
            left
            if find_token(startcol, endcol) then
               id = substr(line, startcol, (endcol-startcol)+1)
            endif
         endif
      endif
      if wordpos(id, '#if #ifdef #ifndef #endif #else #elif') then
         search = '\#(if((n?def)|):w|endif)'
         c = substr(id, 2, 1)
         k = (c<>'e')
         if k then  -- move to beginning
            .col = startcol
         else       -- move to end, so first Locate will hit this instance.
            .col = endcol
         endif
         incr = 1
         force_search = substr(id, 3, 1)='l'
      elseif lowcase(id)='compile' &
             wordpos(lowcase(word(substr(line, endcol+1), 1)), 'if endif else elseif') then
         search = 'compile:w(end|)if'
         case = 'c'  -- Case insensitive
         c = lowcase(leftstr(word(substr(line, endcol+1), 1), 1))
         k = (c<>'e')
         if k then  -- move to beginning
            .col = startcol
         else       -- move to end, so first Locate will hit this instance.
            end_line
         endif
         id=lowcase(id)
         incr = 0
         force_search = lowcase(substr(word(substr(line, endcol+1), 1), 2, 1))='l'
      elseif wordpos(lowcase(id), ':ol :eol :ul :eul :sl :esl :dl :edl :parml :eparml') &
             pos(substr(line, endcol+1, 1), '. ') then
         c = substr(id, 2, 1)  -- Character to check to see if it's an end tag
         k = (c<>'e')          -- k = 1 if searching forward; 0 if backwards
         if k then  -- move to beginning
            .col = startcol
            id = substr(id, 2)
         else       -- move to end, so first Locate will hit this instance.
            .col = endcol+1
            id = substr(id, 3)
         endif
         search = '\:e?'id'(\.| )'
         incr = 1              -- offset from match of the char. to compare with 'c' value
         force_search = 0      -- force a search if on an intermediate (like #else).
      elseif wordpos(id, '/* */') then
         c = leftstr(id, 1)    -- Character to check to see if it's the same or the other
         k = (c='/')           -- k = 1 if searching forward; 0 if backwards
         if k then  -- move to beginning
            .col = startcol
         else       -- move to end, so first Locate will hit this instance.
            .col = endcol
         endif
         search = '/\*|\*/'
         incr = 0              -- offset from match of the char. to compare with 'c' value
         force_search = 0      -- force a search if on an intermediate (like #else).
      elseif leftstr(id, 1)='<' then
         c = substr(id, 2, 1)  -- Character to check to see if it's the same or the other
         k = (c<>'/')           -- k = 1 if searching forward; 0 if backwards
         if k then  -- move to beginning
            id = substr(id, 2)  -- Strip off the '<'
            .col = startcol
         else       -- move to end, so first Locate will hit this instance.
            id = substr(id, 3)  -- Strip off the '</'
            .col = endcol+1   -- +1 for the '>' after the tag
         endif
;        sayerror 'k='k'; c="'c'"; id="'id'"'
         search = '</?\c'id'(>| )'  -- Use \c to not put cursor on angle bracket.
         incr = -1             -- offset from match of the char. to compare with 'c' value
         force_search = 0      -- force a search if on an intermediate (like #else).
      else
         sayerror NOT_BALANCEABLE__MSG
         return
      endif
   endif
   if k//2 then direction='+F'; else direction='-R'; endif
   if search='[]' then search='\[\]'; endif
;  if search='()' then search='\(\)'; endif  -- Don't need to escape it if inside brackets...
   if id='' then search='['search']'; endif
   if force_search then
      setsearch 'xcom l /'search'/x'case||direction
 compile if defined(HIGHLIGHT_COLOR)
      circleit LOCATE_CIRCLE_STYLE, .line, startcol, endcol, LOCATE_CIRCLE_COLOR1, LOCATE_CIRCLE_COLOR2
 compile endif
   else
      'L '\1 || search\1'x'case||direction
   endif
   loop
      repeatfind
      if rc then leave; endif
      if id='compile' then
         tab_word
         if lowcase(substr(textline(.line), .col+incr, 1)) = c then n=n+1; else n=n-1; endif
         backtab_word
      else
         if substr(textline(.line), .col+incr, 1) = c then n=n+1; else n=n-1; endif
      endif
      if n=0 then leave; endif
   endloop
   SETSEARCH search_command -- Restores user's command so Ctrl-F works.
   if rc=sayerror('String not found') then
      sayerror UNBALANCED_TOKEN__MSG
      call prestore_pos(savepos)
      return
   else
      sayerror 1
   endif
   newline = .line; newcol = .col
   call prestore_pos(savepos)
   .col = newcol
   .lineg = newline
   right; left        -- scroll_to_cursor
