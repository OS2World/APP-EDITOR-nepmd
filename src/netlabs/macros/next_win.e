/****************************** Module Header *******************************
*
* Module Name: next_win.e
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

; http://groups.google.com/groups?hl=de&lr=&ie=UTF-8&selm=5d98t6%242afs%241%40news-s01.ca.us.ibm.net

; Next_Win.e, by Larry Margolis.  Defines a command which jumps to the next
; edit window owned by the current EPM process.  Also defines a command which
; puts up a list of all such edit windows.  Note that edit windows started
; with the EPM /M option will belong to a separate process.

; This is probably most useful if defined on a key.  Since Alt+F6 is defined by
; CUA to jump between associated windows, and EPM already uses that to toggle
; between the active edit window and the search dialog, I decided to put this
; on Ctrl+Alt+F6, by adding to my MYSTUFF.E the following code:
;
; definit
;    universal activeaccel
;    buildacceltable activeaccel, 'next_win', AF_VIRTUALKEY+AF_ALT+AF_CONTROL, VK_F6, 61002
;    activateacceltable  activeaccel

;  Some PMWIN.H constants:
#define QW_PARENT       5

#define HWND_TOP        3

#define QWL_STYLE       (-2)

#define SWP_ZORDER      0x0004
#define SWP_ACTIVATE    0x0080
#define SWP_RESTORE     0x1000

#define WS_MINIMIZED    0x01000000

compile if not defined(EPM)  -- Can be included in the base or separately linked.
include 'stdconst.e'

defmain                 -- If compiling standalone, make the .ex file executable.
   'next_win' arg(1)
compile endif

; ---------------------------------------------------------------------------
defc next_win
   ptr= dynalink32('PMWIN',
                   '#839',  -- Win32QueryWindowPtr
                   gethwndc(EPMINFO_OWNERFRAME)  ||
                   atol(0), 2)
   listptr = ltoa(peek32(ptr, 1856, 4), 10)
   hwndx = peek32(listptr, 0, 4)
   next = ltoa(peek32(listptr, 8, 4), 10)
   if not next then
      sayerror 'This is the only edit window.'
      return
   endif
   first_hwndx = hwndx
   my_hwndx = gethwndc(EPMINFO_EDITCLIENT)
   do while hwndx /== my_hwndx
      listptr = next
      hwndx = peek32(listptr, 0, 4)
      next = ltoa(peek32(listptr, 8, 4), 10)
   enddo
   if next then
      hwndx = peek32(next, 0, 4)
   else
      hwndx = first_hwndx
   endif
   EFrame_hwnd=dynalink32('PMWIN',
                          '#834',  -- Win32QueryWindow
                          hwndx                ||
                          atol(QW_PARENT), 2)
   EFrameStyle=dynalink32('PMWIN',
                          '#843',        -- Win32QueryWindowULong
                           atol(EFrame_hwnd)  ||
                           atol(QWL_STYLE), 2)

   if EFrameStyle bitand WS_MINIMIZED then
      opts = SWP_ZORDER bitor SWP_ACTIVATE bitor SWP_RESTORE
   else
      opts = SWP_ZORDER bitor SWP_ACTIVATE
   endif

   call dynalink32( 'PMWIN',
                    '#875',  -- Win32SetWindowPos
                    atol(EFrame_hwnd) ||
                    atol(HWND_TOP)    ||
                    atol(0)           ||
                    atol(0)           ||
                    atol(0)           ||
                    atol(0)           ||
                    atol(opts))

/*
; ---------------------------------------------------------------------------
; Not really part of next_win, but throw it in anyway...
defc ewin =  -- List edit windows
   call windowmessage(0,  getpminfo(APP_HANDLE),   -- Send message to owner client
                      32,              -- WM_COMMAND - 0x0020
                      203,             -- IDM_EDITWNDS
                      0)
*/


/*
; ---------------------------------------------------------------------------
; Following PMWIN calls switch to the next *topmost* EPM window, not to that
; one with the next hwnd.
; Bug: hidden windows are not restored.

; I am not aware of any EPM commands or procs to help switch the
; focus between files in separate edit rings, like godoc in LPEX.
; So I wrote this little utility to toggle between EPM windows.
; It works by checking all top level frame windows for a client
; belonging to the same class as the current EPM window.

/*------------------------------------------------+
 | EPM macro code to jump to the other edit ring  |
 | Author: Michael Golding, IBM (STL), 8-543-3569 |
 +------------------------------------------------*/
; def c_F12 = 'KWIKJMP'

include 'stdconst.e'

defc kwikjmp =
  buf      = leftstr('',128,\0)
  desktop  = atol(1)   -- (1==HWND_DESKTOP)
  hndFrame = gethwndc(EPMINFO_EDITFRAME)

  len = dynalink32( 'PMWIN',
                    '#805',  -- WinQueryClassName
                    gethwndc(EPMINFO_EDITCLIENT) ||
                    atol(128) ||
                    address(buf), 2)

  henum = atol( dynalink32( 'PMWIN',
                            '#702',  -- WinBeginEnumWindows
                            desktop, 2))

  clsname = leftstr(buf, len)
  found   = 0
  cnt     = 0
                 --- examine desktop windows for client of same edit class
  do while cnt<250
     cnt = cnt + 1

     hnd = dynalink32( 'PMWIN',
                       '#756',  -- WinGetNextWindow
                       henum, 2)

     hndF = atol(hnd)

     if not hnd then
        leave        -- no more top-level windows
     elseif hndF = hndFrame then
        iterate      -- just me, never mind
     endif

     hnd = dynalink32( 'PMWIN',
                       '#899',  -- WinWindowFromId
                       hndF ||
                       atol(32776), 2)  -- get client

     len = dynalink32( 'PMWIN',
                       '#805',  -- WinQueryClassName
                       atol(hnd) ||
                       atol(128) ||
                       address(buf), 2)

     if clsname = leftstr( buf, len) then   -- same class as me?
        found = 1  -- YES!!
        leave
     endif
  enddo

  call dynalink32( 'PMWIN',
                   '#737',  -- WinEndEnumWindows
                   henum, 2)

  if found then
     call dynalink32( 'PMWIN',
                      '#851',  -- WinSetActiveWindow
                      desktop ||
                      atol(hnd) ,2)

  elseif cnt < 250 then
     sayerror '*** window not found: cnt='cnt

  else
     sayerror '*** bailed out: cnt='cnt
  endif
*/

