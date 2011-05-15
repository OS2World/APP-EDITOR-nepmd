/****************************** Module Header *******************************
*
* Module Name: testkeys.e
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

; A blank keyset which lets you see what the internal values for keys are.
; Note that if EPM control 26 is on, then arrows are handled internally,
; and won't be seen by this routine.  TOGGLECONTROL 26 0 to turn that off.

; By Larry Margolis

; Switch to the 'testkeys' keyset, when the 'testkeys' command is executed.
; TESTKEYS.E must be separately compiled.
defmain
   'testkeys'

defc testkeys
   universal test_starting_keyset
   if .keyset = 'TEST_KEYS' then
      sayerror 'Already in testkeys mode.  Command ignored.'
      return
   endif
   'deleteaccel'
   test_starting_keyset = upcase(.keyset)
   keys testkeys
   sayerror 'Press Esc or End key twice to exit.'

defkeys testkeys new clear

def otherkeys =
   universal test_starting_keyset
   k = lastkey()
   msg = ''
   if length(k)=1 then
      ch = 'chr('asc(k)')'
   else
      ch = "x'"rightstr(itoa(leftstr(k,1)\0,16),2,0) || rightstr(itoa(substr(k,2,1)\0,16),2,0)"'"
      if k=space then
         ch = ch '(Space)'
      elseif k=s_space then
         ch = ch '(Shift+Space)'
      elseif k = \10\18 then
         ch = ch '(Ctrl)'
      elseif k = \09\10 then
         ch = ch '(Shift)'
      elseif k = \11\34 then
         ch = ch '(Alt)'
      endif
      if k=\x13\x02 | k=\x0f\x02 then    -- Esc or End
         if lastkey(1) = k then
            .keyset = test_starting_keyset
            call beep(900,100)
            sayerror 'Back to keyset' .keyset
            'loadaccel'
            return
         endif
         msg = 'Press again to exit testkeys.'
      endif
   endif
   parse value lastkey(2) with flags 3 repeat 4 scancode 5 charcode 7 vk_code 9
   ch = ch '['c2x(lastkey(2))']'
   msg = msg 'flg('itoa(flags,16)') rep('c2x(repeat)') scan('c2x(scancode)') chr('itoa(charcode, 16)') vk('itoa(vk_code, 16)')'
compile if 1         -- 1 if you want to
   keys edit_keys    -- switch to the starting keyset,
   executekey k      -- execute the pressed key,
   keys testkeys     -- then switch back.
compile endif
   sayerror 'key =' ch '= "'k'"' msg


/*
LASTKEY( [0 | 1 | 2 | 3] )

Returns the user's last keystroke, whether typed manually or executed by a
KEYIN or EXECUTEKEY statement. The only values that are valid for the
parameter key_number are 0 to3. The LASTKEY(0) call has the same effect as a
LASTKEY() call, which has the same behavior as it always has, namely, to
return the most recent keystroke. This procedure call is not useful for
checking for prefix keys. (See the example.) LASTKEY(1) returns the
next-to-last keystroke. LASTKEY(2) returns an 8-byte string representing the
last WM_CHAR message received (see the example), and LASTKEY(3) returns the
next-to-last WM_CHAR.

Note: The WM_CHAR data can be used to check scan codes and differentiate
between the numeric keypad and other keys (for example). If a character is
being processed from a KEYIN or EXECUTEKEY statement, then the WM_CHAR data
will consist of 8 bytes of ASCII zeros.



You might expect that the following example would check for the two-key
sequence Esc followed by F5:

   def f6=
      if lastkey()=esc then
         /* do the new code for Esc-F6 */
      else
         /* do the normal F5 (in this case the draw command) */
         'draw'
      endif

However, this is not the case. This definition is executed only if F5 is
pressed, and once F5 has been pressed, it becomes the value of LASTKEY().
Therefore the if condition in the example never holds true.

The procedure could be useful in the following case:

def f5, a_f5, esc =
    if lastkey() = f5 then
        /* do something for F5 case */
    elseif lastkey() = a_f5 then
        /* do something for A_F5 case */
    else
        /* do something for Esc case */
    endif
    /* do something for all of the keys */

In this case, one DEF is defined for multiple keys. By using the LASTKEY()
procedure, you can determine which of these keys was pressed.

The procedure call LASTKEY(1) returns the key before last, and will handle the
problem discussed in the first example. By substituting LASTKEY(1) calls for
the LASTKEY() calls in the first example, this piece of code will work as
expected: trapping the Esc followed by F5 key sequence.

Example of WM_CHAR usage:

def left = -- Note:  the following are all binary:
   parse value lastkey(2) with flags 3 repeat 4 scancode 5 charcode 7 vk_code 9
   left
   if scancode = \75 then  -- x'4b'; keyboard-specific
      sayerror 'Pad left'
   else
      sayerror 'Cursor key left'
   endif
*/

