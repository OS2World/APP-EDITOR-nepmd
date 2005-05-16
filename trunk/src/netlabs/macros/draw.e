/****************************** Module Header *******************************
*
* Module Name: draw.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: draw.e,v 1.5 2005-05-16 20:53:02 aschn Exp $
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
/******************************************************************************

DRAW.E         revised from SLIMDRAW.E                   Bryan Lewis 3/23/88

Two small changes have made this a separately-compilable and
linkable-at-runtime module.  In EOS2 it makes more sense to
"connect up" the DRAW feature only when needed, rather than compile it
into the always-present base.  Any stand-alone command (not called as a
subroutine by others) that's used only occasionally is a good candidate for
linking.

(1) The conditional compilation test (WANT_DRAW) has been removed to
make this separately compilable, since WANT_DRAW is defined in
STDCNF.E, not available when this is compiled alone.

(2) A DEFMAIN has been added which merely invokes the original DRAW command.

When the user issues "draw" on the command line, DRAW.EX will be linked
from disk and entered at DEFMAIN.  The effect seen by the user will be the same
as before, except for the slight delay of searching the DPATH for DRAW.EX.
When DEFMAIN finishes, DRAW.EX will be automatically unlinked to free up
memory.


(SlimDraw was revised from Davis Foulger's DRAW.E by Bryan Lewis 10/87.)
(Insert-toggle feature suggested by John McAssey.)

******************************************************************************/

compile if not defined(SMALL)  -- If being externally compiled...
   define INCLUDING_FILE = 'DRAW.E'
const
   tryinclude 'MYCNF.E'
 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif
const
 compile if not defined(WANT_DBCS_SUPPORT)
   WANT_DBCS_SUPPORT = 0
 compile endif
 compile if not defined(NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
;include 'stdconst.e'     -- Don't waste time including just to define MAXCOL...
   EA_comment 'This defines the DRAW command; it can be linked or executed directly.'
compile endif  -- not defined(SMALL)

compile if not defined(MAXCOL)  -- Predefined constant starting in 5.60
   const MAXCOL = 255           -- If it's *not* predefined, we know it's 255.
compile endif


defmain     --  We want to start executing as soon as we're linked.
   'draw' arg(1)


defc draw
   universal boxtab1,boxtab2,boxtab3,boxtab4
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb
compile if WANT_DBCS_SUPPORT
   universal ondbcs
compile endif
   universal draw_starting_keyset
   universal cursor_mode
   if .keyset = 'DRAW_KEYS' then
      sayerror ALREADY_DRAWING__MSG
      return
   endif

   style=upcase(substr(arg(1),1,1))
   if not length(style) or verify(style,"123456B/") then
compile if WANT_DBCS_SUPPORT
      if ondbcs then
         sayerror DRAW_ARGS_DBCS__MSG
      else
compile endif
         sayerror DRAW_ARGS__MSG
compile if WANT_DBCS_SUPPORT
      endif
compile endif
      return
   endif

   /* Pick characters from a packed string rather than if's, to save space. */
compile if WANT_DBCS_SUPPORT
   if ondbcs then
      all6=\23\5\2\4\3\1\21\22\25\6\16'+|+++++++-+'\11\11\11\11\11\11\11\11\11\11\11\14\14\14\14\14\14\14\14\14\14\14\20\20\20\20\20\20\20\20\20\20\20\26\26\26\26\26\26\26\26\26\26\26
   else
compile endif
   all6='¥≥øŸ¿⁄¡¬√ƒ≈π∫ªº»… ÀÃÕŒ+|+++++++-+€€€ﬂﬂ€ﬂ€€ﬂ€µ≥∏æ‘’œ—∆Õÿ∂∫∑Ω”÷–“«ƒ◊'
compile if WANT_DBCS_SUPPORT
   endif
compile endif
   if style='/' then
      drawchars=copies(substr(arg(1),2,1),11)
   elseif style='B' then
      drawchars=substr('',1,11)
   else
      drawchars=substr(all6,11*style-10,11)
   endif
;  LAM - changed assignments to a parse statement.  Saved 140 bytes of .ex file.
   parse value drawchars with g1 +1 g2 +1 g3 +1 g4 +1 g5 +1 g6 +1 g7 +1 g8 +1 g9 +1 ga +1 gb
   boxtab1=g1||g2||g4||g5||g7||g9||gb
   boxtab2=g1||g2||g3||g6||g8||g9||gb
   boxtab3=g1||ga||g4||g3||g7||g8||gb
   boxtab4=g9||ga||g5||g6||g7||g8||gb

   undotime = 2            -- 2 = when moving the cursor from a modified line
   undoaction 4, undotime  -- Disable state recording at specified time

   -- EPM:  The old DRAW used a getkey() loop.  We don't have getkey() in EPM.
   -- The new way:  define a clear keyset of only the active keys.
   draw_starting_keyset = upcase(.keyset)
   keys draw_keys

   istate=insert_state();
   if istate then
      insert_toggle
      call fixup_cursor()
   endif
   internalkeys = querycontrol(26)
   cursor_mode = internalkeys istate
   'togglecontrol 26 0'  -- don't use internal key definitions

-- Make it a BASE CLEAR keyset so the only keys that do anything are
-- the ones we explicitly define.  Without the CLEAR, the standard ASCII keys
-- like 'a'-'z' would be automatically included.
defkeys draw_keys base clear
def left    =
   if insert_state() then
      left
   else
      draw_left()
   endif
def right   =
   if insert_state() then
      right
   else
      draw_right()
   endif
def up      =
   if insert_state() then
      up
   else
      draw_up()
   endif
def down    =
   if insert_state() then
      down
   else
      draw_down()
   endif
def backspace  =
   rubout
def ins        =
   insert_toggle
   call fixup_cursor()
def space      =
   keyin ' '
def home       =
   begin_line
def end        =
   end_line
def del        =
   delete_char

-- New in EPM.  This event (pseudo-key) is triggered whenever an otherwise
-- undefined key is pressed.  We let any other key exit draw mode.
-- (Any other key but mouse_move, that is.  It's not considered an "other key"
-- because the mouse movement is too sensitive.
-- This new wrinkle isn't really required.  We could define only one or two
-- keys (like Esc) as exits and simply ignore all others.
def otherkeys, F3, Esc =
   universal draw_starting_keyset
   universal cursor_mode
   -- Whatever other key the user pressed, remember it so we can execute it.
   k = lastkey()
   -- Just in case the user doesn't have a select_edit_keys(), return to
   -- the standard keyset to make sure we don't get stuck in draw_keys.
   keys edit_keys
   .keyset = draw_starting_keyset -- Return to whatever keyset had been there.

   parse value cursor_mode with internalkeys istate
   if istate <> insertstate() then
      inserttoggle
      call fixup_cursor()
   endif
   'togglecontrol 26' internalkeys

   undotime = 2            -- 2 = when moving the cursor from a modified line
   undoaction 5, undotime  -- Enable state recording at specified time
   undoaction 1, junk      -- create a new state
   -- Execute the key the user pressed when he quit drawing.
   sayerror DRAW_ENDED__MSG

   if k <> esc & k <> c_I & k <> F3 then executekey k; endif   -- But assume Esc was just to stop DRAW.

-- End of EPM mods. ----------------------------------------------------------

defproc get_char
   universal linepos,colpos,target
   colpos=.col
   linepos=.line
   getline target
   return substr(target,.col,1)

defproc draw_up      /* draw logic for the up key */
   universal last,l,r,u,d,boxtab1,linepos,colpos
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   if last='d' then up
   else c=get_char()
      if last=='u' and c==' ' then keyin g2;left;up
         elseif not verify(c,boxtab1) then up
         elseif c==g3 then keyin g1;left;up
         elseif c==g6 then keyin g9;left;up
         elseif c==g8 then keyin gb;left;up
         elseif c==ga then
            call left_right()
            if l=1 and r=1 then keyin g7 elseif l=1 then keyin g4 else keyin g5 endif
            left;up
         else call left_right()
              if last='r' and l=1 then keyin g4
                 elseif last='l' and r=1 then keyin g5
                 else keyin g2
                 endif
              left;up
         endif
      if linepos=1 then insert; .col=colpos
      else
         c=get_char()
         if c==g4 then keyin g1;left
            elseif c==g5 then keyin g9;left
            elseif c==g7 then keyin gb;left
            elseif c==ga then
                call left_right()
                if l=1 and r=1 then keyin g8
                   elseif l=1 then keyin g3
                   else keyin g6
                   endif
                left
            endif
         endif
      endif
   last='u'


defproc draw_down /* Draw logic for the Down key */
   universal last,l,r,u,d,boxtab2,linepos,colpos
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   if last='u' then down
   else c=get_char()
      if last=='d' and c==' ' then keyin g2;left;down
         elseif not verify(c,boxtab2) then down
         elseif c==g4 then keyin g1;left;down
         elseif c==g5 then keyin g9;left;down
         elseif c==g7 then keyin gb;left;down
         elseif c==ga then
            call left_right()
            if l=1 and r=1 then keyin g8 elseif l=1 then keyin g3 else keyin g6 endif
            left;down
         else call left_right()
              if last='r' and l=1 then keyin g3
                 elseif last='l' and r=1 then keyin g6
                 else keyin g2
                 endif
              left;down
         endif
      if linepos=.last then insert;.col=colpos
      else
         c=get_char()
         if c==g3 then keyin g1;left
            elseif c==g6 then keyin g9;left
            elseif c==g8 then keyin gb;left
            elseif c==ga then
                call left_right()
                if l=1 and r=1 then keyin g7
                   elseif l=1 then keyin g4
                   else keyin g5
                   endif
                left
            endif
         endif
      endif
   last='d'


defproc left_right   /* Check character left and right of cursor position */
   universal last,l,r,boxtab3,boxtab4,lpos,rpos,target,colpos
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   lpos=colpos-1
   if lpos > 0 then l = substr(target,lpos,1) else l = ' ' endif
   rpos=colpos+1
   if rpos < MAXCOL then r = substr(target,rpos,1) else r = ' ' endif
   l=not verify(l,boxtab4) /*if verify(l,boxtab4)==0 then l=1 else l=0 endif*/
   r=not verify(r,boxtab3) /*if verify(r,boxtab3)==0 then r=1 else r=0 endif*/


defproc draw_left    /* Draw logic for the Left key */
   universal last,u,d,boxtab3
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   if last=='r' then left
   else
      c=get_char()
compile if WANT_DBCS_SUPPORT
      if last=='l' and isdbcs(c) then keyin ga;keyin ga;left;left;left
         elseif last=='l' and c==' ' then keyin ga;left;left
compile else
      if last=='l' and c==' ' then keyin ga;left;left
compile endif
         elseif not verify(c,boxtab3) then left
         elseif c==g5 then keyin g7;left;left
         elseif c==g6 then keyin g8;left;left
         elseif c==g9 then keyin gb;left;left
         elseif c==g2 then
            call up_down()
            if u=1 and d=1 then keyin g1 elseif u=1 then keyin g4 else keyin g3 endif
            left;left
         else call up_down()
              if last='u' and d=1 then keyin g3
                 elseif last='d' and u=1 then keyin g4
                 else keyin ga
                 endif
              left;left
      endif
      c=get_char()
compile if WANT_DBCS_SUPPORT
      if isdbcs(c) then keyin ' ';c=get_char();endif
compile endif
      if c==g4 then keyin g7;left
         elseif c==g2 then
             call up_down()
             if u=1 and d=1 then keyin g9
                elseif d=1 then keyin g6
                else keyin g5
                endif
             left
         elseif c==g3 then keyin g8;left
         elseif c==g1 then keyin gb;left
      endif
   endif
   last='l'


defproc draw_right   /* Draw logic for the Right key */
   universal last,u,d,boxtab4,colpos
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   if last=='l' then right
   else c=get_char()
      if last=='r' and c==' ' then
        keyin ga
      else
         if not verify(c,boxtab4) then right
         elseif c==g4 then keyin g7
         elseif c==g3 then keyin g8
         elseif c==g1 then keyin gb
         elseif c==g2 then
            call up_down()
            if u=1 and d=1 then keyin g9 elseif d=1 then keyin g6 else keyin g5 endif
         else call up_down()
              if last='u' and d=1 then keyin g6
                 elseif last='d' and u=1 then keyin g5
                 else keyin ga
                 endif
         endif
         call left_right()
      endif
      c=get_char()
      if c==g5 then keyin g7;left
         elseif c==g2 then
             call up_down()
             if u=1 and d=1 then keyin g1
                elseif u=1 then keyin g4
                else keyin g3
                endif
             left
         elseif c==g6 then keyin g8;left
         elseif c==g9 then keyin gb;left
      endif
   endif
   last='r'
   if colpos = MAXCOL then left endif


defproc up_down   /* Check character above and below cursor position */
   universal u,d,boxtab1,boxtab2,linepos,colpos,dpos,upos,target
   universal g1,g2,g3,g4,g5,g6,g7,g8,g9,ga,gb

   if linepos=1 then u=0
      else
         upos=linepos-1
         getline target,upos
         u = substr(target,colpos,1)
         u=not verify(u,boxtab2)
   endif
   dpos=linepos+1
   if dpos > .last then d=' '
     else getline target,dpos
          d = substr(target,colpos,1)
     endif
   d=not verify(d,boxtab1)
   getline target,linepos

