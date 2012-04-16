/****************************** Module Header *******************************
*
* Module Name: stdctrl.e
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
ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
º What's it called: stdctrl.e                                                º
º                                                                            º
º What does it do : contains special PM procedures and commands that enable  º
º                   the following from the EPM editor:                       º
º                                                                            º
º                   listbox support - enables the dynamic creation of PM     º
º                                     list boxes.   A macro can pop up a     º
º                                     list of items and have a the users     º
º                                     selection returned to the macro.       º
º                                                                            º
º                   menu support    - enables the dynamic creation and       º
º                                     maintenance of named menus.            º
º                                     A macro can create several menus that  º
º                                     when shown and selected can execute    º
º                                     editor commands.                       º
º                                                                            º
º                   EPM - E.DLL communication :                              º
º                                     gives a EPM macro the ability to       º
º                                     converse with EPM.EXE controls.        º
º                                     For Example, popping EPM's commandline º
º                                     message dialog, etc.                   º
º                                                                            º
º Who and When    : Gennaro (Jerry) Cuomo                          3 -88     º
º                                                                            º
ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
*/

compile if not defined(EPM)  -- Can be included in the base or separately linked.
   include 'stdconst.e'
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ List Box Functions:                                                        ³
³                                                                            ³
³      listbox()                                                             ³
³      listdemo()                                                            ³
³      listdemo2()                                                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

/************************************************************************
listbox()
    param1 - Listbox title

    param2 - string of items, separated by a common separator.  The common
             separator is the first character in the string.
             example:     /cat/dog/fish/
                          separator='/'        list=cat, dog, fish
             example:     $cat/ground$fish/water$
                          separator='$'        list=cat/ground, fish/water

             If this parameter starts with an x'00', then it will be assumed to
             represent a buffer, in the format:
                x'00' || atoi(length(text)) || address(text) [ || flags ]
             (The atoi() is an atol() for 32-bit EPM.)
             'flags' is an ASCII number representing a bit flag:
                1 - Display the listbox below the specified point
                2 - Map the specified points to the desktop
                4 - Support Details button, as for Workframe.  Data has handles
                    (see below) representing a help panel ID; first button is
                    assumed to be "Details".  Pressing button or double-clicking
                    on an item in the list calls the Help Manager, specifying the
                    help panel of the selected item.
                8 - The listbox should be non-modal.  (Not supported.)
               16 - The listbox contents should be displayed in a monospaced font.
               32 - Each item in the list is preceded by a "handle" - a number in
                    the range 0 - 65535 which is associated with the item (but not
                    visible in the listbox).  When an item is selected, the returned
                    string consists of the handle followed by the item text.  Sample
                    list:  "/1 One/5 Five/42 Answer/".

    param3 - (optional) button names.  A maximum of seven button names can be
             specified to allow multiple buttons.

    param4 - (optional) row of text in which list box will go under.
             If this parameter is not specified or if a parameter of zero (0)
             is specified, the box will be placed centered.
             If the parameter 'C' is used, the box will be placed beneath the
             cursor.

    param5 - (optional) column of text in which list box will go under.
             If this parameter is not specified or if a parameter of zero (0)
             is specified, the box will be placed centered.
             If the parameter 'C' is used, the box will be placed beneath the
             cursor.
             NOTE: If the row parameter is selected, the column parameter
                   must be selected as well.
             NOTE: Previously, "beneath the cursor" was the default behavior.
                   That seems to behave annoying in most cases, therefore
                   that was changed to place the box centered. To place it
                   beneath the cursor, now 'C' has to be specified explicitely
                   for param4 and 5.

    param6 - (optional) height of the listbox in characters
             (NOTE:Since the default PM font is proportional the character
              height and width are approximate values.)

    param7 - (optional) width of listbox in characters.

    param8 - (optional) buffer string (see below)

The following procedure creates a PM list box dialog.  The listbox will
wait for user input and return a value that corresponds to the users input.
If the user presses Enter or double clicks on an entry, that entry will
be returned as the result of the listbox function.  If Cancel is selected
or Esc is pressed, the listbox function will return null.   The listbox
is a modal listbox, therefore user input is required before any thing
else can happen.

Jerry Cuomo   1-89

EPM 5.21 / 5.50 added some new features to the ETOOLKIT interface.  Parameter
8 is used to expose this to the caller of listbox().  If present, it is a string
consisting of (5.51 & below):  item# || button# || help_ID || handle || prompt
or, in 5.60 & above, of:  handle || item# || button# || help_ID || prompt
where item# is the listbox entry to be initially selected, button# is the button
that will be the default, help_ID is a help panel ID (all shorts), handle is the
window handle of the OWNERCLIENT (needed to call help; ignored if help_ID is 0),
and prompt is an ASCIIZ string to be displayed below the title bar.  If help_ID
is non-zero, the rightmost button is assumed to be the help button.  The new
parameters are passed to the toolkit in the return buffer, which is padded with
nulls, so only the minimum needed string need be sent.  The old way only supported
returning a string if button 1 was pressed; button 2 was assumed to be Cancel, and
returned null; anything else returned the button number.  The new way returns one
byte representing the button number (in hex) followed by the selected item.
A button number of 0 means Esc was pressed or the dialog was closed.  If param8
was passed, the listbox() routine returns this entire string; if not, it parses
it and returns what the old callers expected.

Larry Margolis / John Ponzo 6/91

****************************************************************************/

/***************************************************************************
Correction/clarification of FLAGS description of bits 0 and 1:
   bit 0
      0: y = bottom of listbox
      1: y = top of listbox
   bit 1
      0: map x,y to the desktop
      1: map x,y relative to EPM window

When caller does not pass a valid FLAGS an artifical, temporary value is set: -2.
When FLAGS is -2 the code will
   a) determine if there is more space above or below the ROW
   b) Set FLAGS, and Y so that the listbox will appear just above or just
      below ROW depending on where there is more room

****************************************************************************/

defproc listbox( title, listbuf)
   universal app_hini
   if leftstr( listbuf, 1) = \0 then
      liststuff = substr( listbuf, 2, 8)
      flags = substr( listbuf, 10)
      if not isnum(flags) then
         flags = -2                 -- artificial value indicating "don't care"
      endif
   else
      listbuf = listbuf\0
      liststuff = atol( length( listbuf) - 1)    ||   -- length of list
                  address( listbuf)                   -- list
      flags = -2                    -- artificial value indicating "don't care"
   endif
   title = title\0

   if arg(3) <> '' then                      -- button names were specified
      parse value arg(3) with delim 2 but1 (delim) but2 (delim) but3 (delim) but4 (delim) but5 (delim) but6 (delim) but7 (delim)
      nb = 0
      if but1 <> '' then but1 = but1\0; nb = nb + 1; else sayerror 'LISTBOX:' BUTTON_ERROR__MSG; return 0; endif
      if but2 <> '' then but2 = but2\0; nb = nb + 1; else but2 = \0; endif
      if but3 <> '' then but3 = but3\0; nb = nb + 1; else but3 = \0; endif
      if but4 <> '' then but4 = but4\0; nb = nb + 1; else but4 = \0; endif
      if but5 <> '' then but5 = but5\0; nb = nb + 1; else but5 = \0; endif
      if but6 <> '' then but6 = but6\0; nb = nb + 1; else but6 = \0; endif
      if but7 <> '' then but7 = but7\0; nb = nb + 1; else but7 = \0; endif
   else  -- default buttons
      but1 = ENTER__MSG\0
      but2 = CANCEL__MSG\0
      but3 = \0; but4 = \0
      but5 = \0
      but6 = \0
      but7 = \0
      nb=2
   endif

   if arg() > 5 then                       -- were height and width specified
      height = arg(6)                      -- height was passed
   else
      height = 0                           -- default: 0 = use listbox default
   endif
   if height < 4 then
      height = 4                           -- internal default is to show 4 lines
   endif

   if arg() > 6 then                       -- were height and width specified
      width = arg(7)                       -- width was passed
   else
      width = 0                            -- default: 0=use listbox default
   endif

   -- Row and col count from the lower left corner of the edit window
   row = 0
   col = 0
   fAtCursor = 0
   if arg() > 3 then                     -- row and col were passed
      row = arg(4)
      col = arg(5)
   endif
   if row = 0 then
      row = (.windowheight - (height + 4)) % 2  -- centered
   elseif leftstr( translate( row), 1) = 'C' then
      row = .cursory                      -- beneath the cursor
      fAtCursor = 1
   endif
   if col = 0 then
      col = (.windowwidth  - max( width, 30)) % 2  -- centered
   elseif leftstr( translate( col), 1) = 'C' then
      col = .cursorx                      -- beneath the cursor
      fAtCursor = 1
   endif
   --dprintf( 'row = 'row', col = 'col', height = 'height', width = 'width', .windowheight = '.windowheight', .windowwidth = '.windowwidth)

   if arg() > 7 then                       /* New way!                       */
      selectbuf = leftstr( arg(8), 255, \0)
   else
      selectbuf = copies( \0, 255)  -- Was 85     /* null terminate return buffer  */
   endif

   --parse value entrybox('Enter row col addl heightadjust') with row col jbsu hadj
   --parse value entrybox('Enter row col adj') with row col jbsu
   call dprintf('listbox', 'curx cury: '.cursorx .cursory)
   call dprintf('listbox', 'col row: 'col row)
   --call listbox2(title, listbuf, arg(3), row, col, arg(6), arg(7))
   --parse value entrybox('Enter comment') with msg
   --call dprintf('listbox', 'Comment: 'msg)
   -- o  .windowy and .windowx are always 0 in EPM
   -- o  screenheight() and screenwidth() return the window dimensions in
   --    pixels
   -- o  .fontheight and .fontwidth are values in pixel, e.g. for 12.System
   --    VIO: 16x8
   -- o  Of course the dialog font differs from the edit window font and
   --    .fontheight and .fontwidth return the size of the edit window font
   -- o  .cursory is 1 when cursor is on top and .windowheight when cursor is
   --    on bottom, values in lines
   -- o  .cursorx is 1 when cursor is at the left and .windowwidth when cursor
   --    is at the right edge, values in cols

   -- JBSQ: "flags" does not seem to work as documented.
   --       Bits 0 and 1 seem to work as follows:
   --       00:   x,y mapped to desktop, listbox kept on screen
   --       01:   x mapped to desktop, y = ?, listbox can go off top of screen
   --       10:   x,y mapped relative to EPM window, listbox stays on screen
   --       11:   x,y mapped relative to EPM window, y measured down from bottom of EPM window?
   --    Conclusion: only 00 and 10 (0 and 2 in decimal) seem to work predictably

   if fAtCursor then

      -- Determining the x coordinate works very well using the standard method:
      x = .fontwidth * col                    -- convert row and column into...

      -- The y coordinate depends on the height of the dialog font. The old
      -- method gives bad results:
      -- y = .windowy + screenheight() - .fontheight * (row + 1) - 4  /* (Add a fudge factor temporarily */

      -- Correct row for 9.WarpSans (standard was either 10.System Proportional
      -- or 10.System Monospaced). row and .cursory are counted in number of
      -- lines from the top.
      desktop_cy = NepmdQuerySysInfo('CYSCREEN')
      parse value desktop_cy with 'ERROR:'errcode
      if errcode <> '' then
         sayerror 'Error query system screen resolution: 'errcode
         return   'Error query system screen resolution: 'errcode
      endif
      call dprintf('listbox', 'Desktop height /2 = 'desktop_cy (desktop_cy/2))
      win_data = NepmdQueryWindowPos(EPMINFO_EDITFRAME)
      parse value win_data with 'ERROR:'errcode
      if errcode <> '' then
         sayerror 'Error query frame position: 'errcode
         return   'Error query frame position: 'errcode
      endif
      parse value win_data with fwindowx fwindowy fwindowcx fwindowcy
      call dprintf("listbox", 'SWP F: 'fwindowx fwindowy fwindowcx fwindowcy)
      win_data = NepmdQueryWindowPos(EPMINFO_EDITCLIENT)
      parse value win_data with 'ERROR:'errcode
      if errcode <> '' then
         sayerror 'Error query client position: 'errcode
         return   'Error query client position: 'errcode
      endif
      parse value win_data with cwindowx cwindowy cwindowcx cwindowcy  -- the x and y are relative to the frame
      windowx = cwindowx + fwindowx     -- so add in the frame x to get absolute client x
      windowy = cwindowy + fwindowy     -- so add in the frame y to get absolute client y
      call dprintf('listbox', 'SWP C: 'cwindowx cwindowy cwindowcx cwindowcy)

      -- Estimate the height of the entire listbox dialog
      -- The height of additional dialog controls takes about 7 lines of
      -- 9.WarpSans (same height as 12.System VIO, which has 16x8).
      --addpixels = 102 + (50 * (nb > 4))
      addpixels = 122 + (40 * (nb > 4))  -- 40 per row of buttons + 122 for other "overhead" pixels
      boxfontheight = 16  -- value in pels = pixels
      boxcy = height * ( boxfontheight ) + addpixels
      call dprintf('listbox', 'wdwhgt hgt boxcy addl: '.windowheight height boxcy addpixels)

      row_y = .fontheight * (.windowheight - (row - 1))
      SpaceBelowCursor = windowy + row_y
      call dprintf('listbox', 'row_y Spcbelow: 'row_y SpaceBelowCursor)
      if flags < 0 then
         if SpaceBelowCursor < (desktop_cy / 2) then
            -- Position listbox window above row, col
            wanty =  row_y
            topofwin = 0
            too_much = 0
            if flags < 0 then
               topofwin = wanty + boxcy + windowy
               too_much = topofwin - desktop_cy
               if too_much > 0 then
                  height = height - (too_much + boxfontheight - 1) % boxfontheight
               endif
               flags = 0
            endif
            call dprintf('listbox', 'Above cursor::wanty top too adjh: 'wanty topofwin too_much height)
         else
            -- Position listbox window below row, col
            wanty = row_y - .fontheight
            if flags < 0 then
               too_much = wanty + windowy - boxcy -- - 10 -- fudge factor
               if too_much < 0 then
                  height = (boxcy + too_much - addpixels) % boxfontheight
               endif
               flags = 1
            endif
            call dprintf('listbox', 'Below cursor::wanty adjh too_much: 'wanty height too_much)
         endif
      endif
      call dprintf('listbox', 'flags bit1 winy: 'flags ((flags % 2) // 2) windowy)
      if ((flags % 2) // 2) then
         y = wanty
      else
         x = x + windowx
         y = wanty + windowy
      endif
      -- Prevent corrupted window diplays because the cursor is offscreen
      if (flags < 2) and (x <= -windowx) then
         x = 1 - windowx
      endif

      -- With this coordinate determination, the listbox window may be placed
      -- outside of the frame window. That is intended, since we don't have a
      -- MDI window. Limiting the listbox window to screen values is done
      -- automatically by the LISTBOX function.

   else  -- not at cursor

      y = .fontheight * row
      x = .fontwidth  * col
      flags = 2  -- gives best results for centering in the edit window

   endif

   if getpminfo(EPMINFO_EDITFRAME) then
      handle = EPMINFO_EDITFRAME
   else                   -- If frame handle is 0, use edit client instead.
      handle = EPMINFO_EDITCLIENT
   endif
;do forever
   call dprintf('listbox', 'final::flags col row x y: 'flags col row x y)
   call dynalink32( ERES_DLL,               -- list box control in EDLL dyna
                    'LISTBOX',                      -- function name
                    gethwndc(handle)           ||   -- edit frame handle
                    atol(flags)                ||
                    atol(x)                    ||   -- coordinates
                    atol(y)                    ||
                    atol(height)               ||
                    atol(width)                ||
                    atol(nb)                   ||
                    address(title)             ||   -- list box dialog title
                    address(but1)              ||   -- text to appear in buttons
                    address(but2)              ||
                    address(but3)              ||
                    address(but4)              ||
                    address(but5)              ||
                    address(but6)              ||
                    address(but7)              ||
                    liststuff                  ||
                    address(selectbuf)         ||   -- return string buffer
                    atol(app_hini))                 -- handle to INI file

;    parse value entrybox('Enter comment') with y flags msg
;    call dprintf('listbox', 'Comment: 'msg)
; if y = -1000  then
;    leave
; endif
; enddo
   button = asc(leftstr( selectbuf, 1))
   if arg() > 7 then              -- New way
      return selectbuf
   endif
   if button = 0 | button=2 then  -- Old way...
      return ''
   endif
   if button <> 1 then
      return button
   endif
   EOS = pos( \0, selectbuf, 2)        -- CHR(0) signifies End Of String
   if not EOS then
      return 'Error'
   endif
   return substr( selectbuf, 2, EOS - 2)

/*********** Sample command that uses the old list box function *********
**/
defc listdemo
   select = listbox( 'My List',
                     '/Bryan/Jason/Jerry Cuomo/Ralph/Larry/Richard/');
   if select=='' then
      sayerror 'Nothing Selected'
   else
      sayerror 'list box selection =<' select '>'
   endif
/*********** Sample command that uses the new list box function *********
**/
defc listdemo2
   sayerror 'Selected entry 3; default button 2; help panel 9300.'
   selectbuf = listbox( 'My List',
                        '/One/Two/Three',
                        '/Go to/Delete/Cancel/Help',
                        0,0,0,0,
                        gethwnd(APP_HANDLE) || atoi(3) || atoi(2) || atoi(9300) ||
                        'Prompt text'\0);
   button = asc(leftstr( selectbuf, 1))
   if button=0 then
      sayerror 'Nothing Selected'
   else
      EOS = pos( \0, selectbuf, 2)        -- CHR(0) signifies End Of String
      select= substr( selectbuf, 2, EOS - 2)
      sayerror 'Button' button 'was pressed; string =' select
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                            ³
³ What's it called: Listbox_Buffer_From_File                                 ³
³                                                                            ³
³ What does it do : Inserts contents of a temp file into a buffer, ready for ³
³                   a call to listbox().  Quits the source file.  Returns '' ³
³                   if no problems.                                          ³
³                                                                            ³
³                   startfid - the starting fileid to which we return        ³
³                   bufhndl  - (output) the buffer handle                    ³
³                   noflines - (output) number of lines inserted in buffer   ³
³                   usedsize - (output) amount of space used in the buffer   ³
³                                                                            ³
³ Who and when    : Larry Margolis               1994/08/29                  ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Larry Margolis
*/
defproc listbox_buffer_from_file( startfid, var bufhndl, var noflines, var usedsize)
   buflen = filesize() + .last + 1
   if buflen > MAXBUFSIZE then
      sayerror LIST_TOO_BIG__MSG '(' buflen '>' MAXBUFSIZE ')'
      buflen = MAXBUFSIZE
   endif
   bufhndl = buffer( CREATEBUF, 'LISTBOX', buflen, 1)  -- create a private buffer
   if not bufhndl then
      sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC
      return rc
   endif
   noflines = buffer( PUTBUF, bufhndl, 1, 0, APPENDCR)
   buf_rc = rc
   .modify = 0
   'xcom quit'
   activatefile startfid
   if not noflines then
      sayerror 'PUTBUF' ERROR_NUMBER__MSG buf_RC
      return buf_RC
   endif
   usedsize = buffer( USEDSIZEBUF, bufhndl)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                            ³
³ What's it called: EntryBox                                                 ³
³                                                                            ³
³ What does it do : Creates an application-modal dialog box.                 ³
³                   The dialog box contains a entry field and 2 push buttons.³
³                   (Up to 4 as of EPM 5.21 / 5.50.  See below.)             ³
³                                                                            ³
³                   hwnd    -  handle of owner window                        ³
³                   title   -  question to appear on dialog title bar        ³
³                   x,y     -  coordinates of lower left of entry box        ³
³                              if (0,0) then centered to screen.             ³
³                   cols    -  approximate number of cols in entry field     ³
³                              in PM font characters                         ³
³                   max     -  maximum number of chars                       ³
³                   entry   -  entry field string returned                   ³
³                                                                            ³
³ Who and when    : Gennaro (Jerry) Cuomo            4-89                    ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

EPM 5.21 / 5.50 added some new features to the ETOOLKIT interface.  Parameter
6 is used to expose this to the caller of entrybox().  If present, it is a string
consisting of:  button# || help_ID || handle || prompt

See the listbox() comments to see what these represent, and what is returned.

Larry Margolis / John Ponzo 6/91

LAM:  New feature for EPM 6.01a:  Can pass entryfield flags as a 7th parameter.
      Primarily of interest for getting passwords:
defc pw =
   pw = entrybox( 'Enter Password',
                  '',  -- Buttons
                  '',  -- Entry text
                  '',  -- Cols
                  '',  -- Max len
                  '',  -- Return buffer
                  140) -- ES_UNREADABLE + ES_AUTOSCROLL + ES_MARGIN
   Sayerror 'Password = "'pw'"'
*/

; Syntax: entrybox title [,buttons][,entrytext][,cols][,maxchars][,param6][,flags]
defproc entrybox(title)

   title = title \0

   nb = 2                                  -- default number of buttons
   if arg(2) <> '' then                      /* button names were specified    */
      parse value arg(2) with delim 2 but1 (delim) but2 (delim) but3 (delim) but4 (delim)
;;    sayerror 'but1=<'but1'> but2=<'but2'> but3=<'but3'> but4=<'but4'>'
      if but1 <> '' then
         but1 = but1 \0
      else
         sayerror 'ENTRYBOX:' BUTTON_ERROR__MSG
         return 0
      endif
      if but2 <> '' then
         but2 = but2 \0
      else
         but2 = ''\0
      endif
      if but3 <> '' then
         but3 = but3 \0
         nb=3
      else
         but3 = ''\0
      endif
      if but4 <> '' then
         but4 = but4 \0
         nb=4
      else
         but4 = ''\0
      endif
   else
      but1 = \0
      but2 = \0
      but3 = \0
      but4 = \0
   endif

   if arg() > 2 then
      entrytext = arg(3) \0
   else
      entrytext = \0
   endif

   columns = arg(4)
   if columns < 0 then
      columns = 30
   endif

   if arg() > 4 then
      maxchars = max( arg(5), 1)
   else
      maxchars = 254
   endif

   /* null terminate return buffer  */
   if arg() > 5 then
      selectbuf = leftstr( arg(6), MAXCOL, \0)
   else
      selectbuf = copies( \0, MAXCOL)
   endif

   if arg() > 6 then
      flags = arg(7)
   else
      flags = 0
   endif

   call dynalink32( ERES_DLL,                      /* entry box control in EDLL dyna */
                    'ENTRYBOX',                     /* function name                 */
                    gethwndc(EPMINFO_EDITFRAME)||   /* edit frame handle             */
                    address(title)             ||   /*                               */
                    atol(0)                    ||   /* x coordinate                  */
                    atol(0)                    ||   /* y coordinate (0,0) = center   */
                    atol(columns)              ||
                    atol(maxchars)             ||
                    address(entrytext)         ||   /* (optional text in entry field)*/
                    atoi(nb)                   ||   /* Number of buttons, and        */
                    atoi(flags)                ||   /* flags:  mpfrom2short(flags, nb)*/
                    address(but1)              ||   /* (optional button 1 text )     */
                    address(but2)              ||   /* (optional button 2 text )     */
                    address(but3)              ||   /* (optional button 3 text )     */
                    address(but4)              ||   /* (optional button 4 text )     */
                    address(selectbuf))             /* return string buffer          */

   if arg(6) then  -- New way
      return selectbuf
   endif
   button = asc(leftstr( selectbuf, 1))
   if button=0 | button=2 then  -- Old way...
      return ''
   endif
   if button <> 1 then
      return button
   endif
   EOS = pos( \0, selectbuf, 2)        -- CHR(0) signifies End Of String
   if not EOS then
      return 'error'
   endif
   return substr( selectbuf, 2, EOS - 2)

/*
ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
º EPM macro - EPM.EXE communication commands.                                º
º                                                                            º
º      togglefont      - toggle from large to small to large font            º
º      commandline     - show commandline dialog [initialize with text]      º
º      messagebox      - show message dialog box [optionally add to it]      º
º      opendlg         - show open dialog box                                º
º                                                                            º
ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
*/

; Moved toggle defs to MENU.E

; ---------------------------------------------------------------------------
; This loads or activates a background bitmap. Checks for valid filename
; added, because otherwise initialization on EPM's startup would stop on a
; non-valid OS/2 file.
defc load_dt_bitmap
   universal bm_filename
   universal bitmap_present
   BmpFile = arg(1)
   if BmpFile = '' then
      -- load default file
   elseif substr( BmpFile, 2, 2) = ':\' & IsOs2Bmp( BmpFile) then  -- if fully qualified and valid
      -- load specified file
   else
      sayerror 'Filename for background bitmap not valid'
      BmpFile = ''
      -- load default file
   endif

   if BmpFile = '' then
      -- load the default bitmap
      call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                          5454, 0, 0)
   else
      -- load an external bitmap
      call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                          5499,            -- EPM_EDIT_SETDTBITMAPFROMFILE
                          put_in_buffer(BmpFile),
                          0)
   endif
   bm_filename = BmpFile
   bitmap_present = 1

; ---------------------------------------------------------------------------
; Doesn't work with eCS, ...?
/*
defc drop_bitmap, drgdrptyp_Bitmap, dragdrop_bmp
   universal bm_filename
   parse arg x y bm_filename
   'load_dt_bitmap' bm_filename
*/

; ---------------------------------------------------------------------------
defc SetBackgroundBitmap
   universal bitmap_present
   universal bm_filename
   universal app_hini
   universal appname
   arg1 = strip( arg(1))
   fSetBmp = 0
   fNewBmp = 0
   if upcase( arg1) = 'SELECT' then
      BitmapDir = ''
      if bm_filename > '' then
         lp = lastpos( '\', bm_filename)
         BitmapDir = substr( bm_filename, 1, lp - 1)
      endif
      if NepmdDirExists( BitmapDir) <> 1 then
         BootDrive = NepmdQuerySysInfo( 'BOOTDRIVE')
         BitmapDir = BootDrive'\os2\bitmap'
      endif
      'FileDlg Select a background bitmap file, SetBackgroundBitmap, 'BitmapDir'\*.bmp'
      return
   elseif wordpos( upcase( arg1), '0 OFF') then
      bitmap_present = 0
      fSetBmp = 1
   elseif wordpos( upcase( arg1), '1 ON') then
      bitmap_present = 1
      fSetBmp = 1
   elseif wordpos( upcase( arg1), 'TOGGLE') then
      bitmap_present = not bitmap_present
      fSetBmp = 1
   else
      fNewBmp = 1
   endif

   if fSetBmp then
      if bitmap_present then
         -- activate it
         'load_dt_bitmap' bm_filename
      else
         -- deactivate it
         call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                             5498, 0, 0)
      endif
   endif

   if fNewBmp then
      'load_dt_bitmap' arg(1)
      if bitmap_present then
         call setprofile( app_hini, appname, INI_BITMAP, bm_filename)
      endif
   endif

   if fSetBmp | fNewBmp then
      old = queryprofile( app_hini, appname, INI_OPTFLAGS)
      new = subword( old, 1, 14)' 'bitmap_present' 'subword( old, 16)
      call setprofile( app_hini, appname, INI_OPTFLAGS, new)
   endif

; ---------------------------------------------------------------------------
defproc IsOs2Bmp
   SigList = 'BMP BM BA'
   arg1 = strip( arg(1))
   ret = 0
   if rightstr( upcase( arg1), 4) = '.BMP' then
      Result = CheckSig( arg(1), SigList)
      if Result = 1 then
         ret = 1
      elseif rc <> 0 then
         --sayerror 'CheckSig returned rc = 'rc
      endif
   endif
   return ret

defproc querycontrol(controlid)
   return windowmessage( 1, getpminfo(EPMINFO_EDITCLIENT),   -- Send message to edit client
                         5388,               -- EPM_EDIT_CONTROLTOGGLE
                         controlid,
                         1)

defc cursoroff=
   call cursoroff()    -- Turn cursor off

defproc cursoroff           -- Turn cursor off
   'togglecontrol 14 0'     -- doesn't work in current EPM

; Trim window so it's an exact multiple of the font size.
defc trim=
   call windowsize1( .windowheight, .windowwidth, 0, 0, 1)

defc windowsize1
   parse arg row col x y flag junk
   if x='' | junk<>'' then
      sayerror -263  -- Invalid argument
   else
      call windowsize1( row, col, x, y, flag)
   endif

defproc windowsize1( row, col, x, y)

   if upcase(leftstr( row, 1)) = 'P' then  -- Already in pels
      cy = substr( row, 2)
   else
      cy = .fontheight *  row          -- convert row into y coordinate in pels
   endif
   if upcase(leftstr( col, 1)) = 'P' then  -- Already in pels
      cx = substr(col,2)
   else
      cx = .fontwidth * col            -- convert col into x coordinate in pels
   endif

   if arg(5) <> '' then
      opts = arg(5)
   else
      opts = 3  -- Default = SWP_SIZE (1) + SWP_MOVE (2)
   endif

   if opts // 2 then                   -- Don't bother calculating unless SWP_SIZE on
      swp1 = copies( \0, 36)
      swp2 = swp1
      call dynalink32( 'PMWIN',
                       '#837',
                       gethwndc(EPMINFO_EDITCLIENT)  ||
                       address(swp1))
      call dynalink32( 'PMWIN',
                       '#837',
                       gethwndc(EPMINFO_EDITFRAME)   ||
                       address(swp2))
      cx = cx + ltoa( substr( swp2, 9, 4), 10) - ltoa( substr( swp1, 9, 4), 10)
      cy = cy + ltoa( substr( swp2, 5, 4), 10) - ltoa( substr( swp1, 5, 4), 10)
   endif

   call dynalink32( 'PMWIN',
                    '#875',
                    gethwndc(EPMINFO_EDITFRAME) ||
                    atol(3)                    ||      /* HWND_TOP   */
                    atol(x)                    ||
                    atol(y)                    ||
                    atol(cx)                   ||
                    atol(cy)                   ||
                    atol(opts))                        /* SWP_MOVE | SWP_SIZE */

compile if 0  -- Unused, so don't waste space.  LAM
defc qcontrol
   if querycontrol(arg(1))  then
      sayerror 'control on'
   else
      sayerror 'control off'
   endif
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: fontlist                                                 ³
³                                                                            ³
³ what does it do : Display a listbox containing the possible font cell sizes³
³                   for the particular display type being used.              ³
³                   The font dimensions are extracted from the fontlist str. ³
³                                                                            ³
³ who and when    : Jerry C.  11/04/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

defc fontlist
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5130,               -- EPM_POPFONTDLG
                      put_in_buffer(queryfont(.font)'.'trunc(.textcolor//16)'.'.textcolor%16),
                      0)

; ---------------------------------------------------------------------------
; Called internally by the config dialog, when a font was changed.
; Called internally by the style dialog.
defc ProcessFontRequest
   universal default_font
   universal statfont, msgfont
   --universal appname, app_hini
   --dprintf( 'ProcessFontRequest', 'arg(1) = ['arg(1)']')
   parse value arg(1) with fontname '.' fontsize '.' fontsel '.' fsetfont '.' markedonly '.' fg '.' bg
   -- sayerror 'Fontname=' fontname ' Fontsize=' fontsize 'Fontsel=' fontsel 'arg(1)="'arg(1)'"'
   if markedonly = 2 then  -- Statusline font
      --statfont = fontsize'.'fontname'.'fontsel
      statfont = ConvertToOs2Font( fontsize'.'fontname'.'fontsel)
      "setstatface" getpminfo( EPMINFO_EDITSTATUSHWND) fontname
      "setstatptsize" getpminfo( EPMINFO_EDITSTATUSHWND) fontsize
      if fsetfont then
      --   call setprofile( app_hini, appname, INI_STATUSFONT, statfont)
         'SaveFont STATUS'
      endif
      return
   endif  -- markedonly = 2
   if markedonly = 3 then  -- Messageline font
      --msgfont = fontsize'.'fontname'.'fontsel
      msgfont = ConvertToOs2Font( fontsize'.'fontname'.'fontsel)
      "setstatface" getpminfo( EPMINFO_EDITMSGHWND) fontname
      "setstatptsize" getpminfo( EPMINFO_EDITMSGHWND) fontsize
      if fsetfont then
      --   call setprofile( app_hini, appname, INI_MESSAGEFONT, msgfont)
         'SaveFont MESSAGE'
      endif
      return
   endif  -- markedonly = 3

   fontid = registerfont( fontname, fontsize, fontsel)

   if fsetfont & not markedonly then
      -- Apply font to all files in the ring that have the default font
      getfileid startfid
      display -1
      dprintf( 'RINGCMD', 'ProcessFontRequest')
      do i = 1 to filesinring(1)
         if .font = default_font then
            .font = fontid
         endif
         next_file
         getfileid curfid
         if curfid = startfid then
            leave
         endif
      enddo  -- Loop through all files in ring
      activatefile startfid  -- Make sure we're back where we started (in case was .HIDDEN)
      display 1
      default_font = fontid
      -- Save font to ini
      --call setini( INI_FONT, fontname'.'fontsize'.'fontsel, 1)
      'SaveFont TEXT'
   endif  -- fsetfont & not markedonly

   if markedonly then
     -- insert font attribute within marked area only!

      themarktype = marktype()
      if not FileIsMarked() then          /* check if mark exists              */
         sayerror NO_MARK__MSG
         return                           /* if mark doesn't exist, return     */
      endif
      getmark fstline,                    /* returned:  first line of mark     */
              lstline,                    /* returned:  last  line of mark     */
              fstcol,                     /* returned:  first column of mark   */
              lstcol,                     /* returned:  last  column of mark   */
              mkfileid                    /* returned:  file id of marked file */
      if fontid <> .font then
         call attribute_on(4)  -- Mixed fonts flag
         addfont = 1
      else
         addfont = .levelofattributesupport bitand 4
      endif
      if bg<>'' then
         fg = bg*16+fg
         call attribute_on(1)  -- Colors flag
      endif
      if themarktype = 'BLOCK' then
         do i = fstline to lstline
            if addfont then
               Insert_Attribute_Pair( 16, fontid, i, i, fstcol, lstcol, mkfileid)
            endif
            if bg<>'' then
               Insert_Attribute_Pair( 1, fg, i, i, fstcol, lstcol, mkfileid)
            endif
         enddo
      else
         if themarktype = 'LINE' then
            getline line, lstline, mkfileid
            lstcol = length( line)
         endif
         if addfont then
            Insert_Attribute_Pair( 16, fontid, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
         if bg<>'' then
            Insert_Attribute_Pair( 1, fg, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
      endif  -- themarktype = 'BLOCK'
      call attribute_on(8)  -- "Save attributes" flag
   else
      .font = fontid
   endif  -- markedonly

defc Process_Style
   universal app_hini
   universal EPM_utility_array_ID
   call checkmark()     -- verify there is a marked area,
   parse arg stylename   -- can include spaces
   stylestuff = queryprofile(app_hini, 'Style', stylename)
   if stylestuff = '' then return; endif  -- Shouldn't happen
   parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
   getmark fstline, lstline, fstcol, lstcol, mkfileid
   if get_array_value(EPM_utility_array_ID, 'sn.'stylename, styleindex) then  -- See if we have an index
      --do_array 3, EPM_utility_array_ID, 'si.0', styleindex          -- Get the
      rc = get_array_value( EPM_utility_array_ID, 'si.0', styleindex )          -- Get the
      styleindex = styleindex + 1                                 --   next index
      do_array 2, EPM_utility_array_ID, 'si.0', styleindex          -- Save next index
      do_array 2, EPM_utility_array_ID, 'si.'styleindex, stylename  -- Save index.name
      do_array 2, EPM_utility_array_ID, 'sn.'stylename, styleindex  -- Save name.index
   endif
   oldmod = .modify
   if bg<>'' then
;;    fg = 256 + bg*16 + fg
      fg = bg*16 + fg
      if marktype() = 'BLOCK' then
         do i = fstline to lstline
            Insert_Attribute_Pair(1, fg, i, i, fstcol, lstcol, mkfileid)
         enddo
      else
         if marktype() = 'LINE' then
            getline line, lstline, mkfileid
            lstcol = length(line)
         endif
         Insert_Attribute_Pair(1, fg, fstline, lstline, fstcol, lstcol, mkfileid)
      endif
      call attribute_on(1)  -- Colors flag
   endif
   if fontsel<>'' then
      call attribute_on(4)  -- Mixed fonts flag
      fontid = registerfont(fontname, fontsize, fontsel)
      if marktype() = 'BLOCK' then
         do i = fstline to lstline
            Insert_Attribute_Pair(16, fontid, i, i, fstcol, lstcol, mkfileid)
         enddo
      else
         Insert_Attribute_Pair(16, fontid, fstline, lstline, fstcol, lstcol, mkfileid)
      endif
   endif
   Insert_Attribute_Pair(14, styleindex, fstline, lstline, fstcol, lstcol, mkfileid)
   call attribute_on(8)  -- "Save attributes" flag
   .modify = oldmod + 1

defc ChangeStyle
   universal app_hini
   universal EPM_utility_array_ID
   parse arg stylename  -- Can include spaces
   if get_array_value(EPM_utility_array_ID, 'sn.'stylename, styleindex) then
      return  -- If not known, then we're not using it, so nothing to do.
   endif
   stylestuff = queryprofile(app_hini, 'Style', stylename)
   if stylestuff = '' then return; endif  -- Shouldn't happen
   parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
   getfileid startid
   fontid = registerfont(fontname, fontsize, fontsel)
   fg = bg*16 + fg
   dprintf( 'RINGCMD', 'ChangeStyle')
   do i = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      if .levelofattributesupport bitand 8 then  -- Is attribute 8 on?
                                                                 -- "Save attributes" flag
         line = 0; col = 1; offst = 0
         do forever
            class = 14  -- STYLE_CLASS
            attribute_action 1, class, offst, col, line -- 1 = FIND NEXT ATTR
            if class = 0 then leave; endif  -- not found
            query_attribute class, val, IsPush, offst, col, line
            if val = styleindex then  -- If it's this style, then...
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class = 16 & val<>fontid then  -- Replace the font ID (if changed)
                  insert_attribute class, fontid, IsPush, offst, col, line
                  attribute_action 16, class, offst, col, line -- 16 = DELETE_ATTR_SUBOP
               endif
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class = 1 & val<>fg then  -- Replace the color attribute (if changed)
                  insert_attribute class, fg, IsPush, offst, col, line
                  attribute_action 16, class, offst, col, line -- 16 = DELETE_ATTR_SUBOP
               endif
            endif
         enddo  -- Loop looking for STYLE_CLASS in current file
      endif  -- "Save attributes" flag
      next_file
      getfileid curfile
      if curfile = startid then leave; endif
   enddo  -- Loop through all files in ring
   activatefile startid  -- Make sure we're back where we started (in case was .HIDDEN)

defc Delete_Style
   universal app_hini
   universal EPM_utility_array_ID
   stylename = arg(1)
   stylestuff = queryprofile(app_hini, 'Style', stylename)
   call setprofile(app_hini, 'Style', stylename, '')
   if stylestuff = '' then return; endif  -- Shouldn't happen
   if get_array_value(EPM_utility_array_ID, 'sn.'stylename, styleindex) then
      return  -- If not known, then we're not using it, so nothing to do.
   endif
;  parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
   getfileid startid
;  fontid = registerfont(fontname, fontsize, fontsel)
;  fg = bg*16 + fg
   dprintf( 'RINGCMD', 'DeleteStyle')
   do i = 1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      if .levelofattributesupport bitand 8 then  -- Is attribute 8 on?
                   -- "Save attributes" flag --> using styles in this file
         oldmod = .modify
         line = 0; col = 1; offst = 0
         do forever
            class = 14  -- STYLE_CLASS
            attribute_action 1, class, offst, col, line -- 1 = FIND NEXT ATTR
            if class = 0 then  -- not found
               if .modify <> oldmod then  -- We've deleted at least one...
                   call delete_ea('EPM.STYLES')
                   call delete_ea('EPM.ATTRIBUTES')
                  .modify = oldmod + 1  -- ...count as a single change.
               endif
               leave
            endif
            query_attribute class, val, IsPush, offst, col, line
            if val = styleindex then  -- If it's this style, then...
               attribute_action 16, class, offst, col, line -- 16 = DELETE_ATTR_SUBOP
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class = 16 then  -- Delete the font ID
                  attribute_action 16, class, offst, col, line -- 16 = DELETE_ATTR_SUBOP
               endif
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class = 1 then  -- Delete the color attribute
                  attribute_action 16, class, offst, col, line -- 16 = DELETE_ATTR_SUBOP
               endif
            endif
         enddo  -- Loop looking for STYLE_CLASS in current file
      endif  -- "Save attributes" flag
      next_file
      getfileid curfile
      if curfile = startid then leave; endif
   enddo  -- Loop through all files in ring
   activatefile startid  -- Make sure we're back where we started (in case was .HIDDEN)

; Delete all attributes of current file.
; Taken from Martin Lafaix' MLEPM package (defc munhighlightfile).
defc DeleteAllAttributes, DelAttribs
   call psave_mark(savemark)
   class = 0  -- 0 means: find all attributes
   line = 0; col = 0; off = -255
   attribute_action 1, class, off, col, line      -- find next attribute
   while class do
      attribute_action 16, class, off, col, line  -- delete attribute
      class = 0; off = -255
      attribute_action 1, class, off, col, line   -- find next attribute
   endwhile
   call prestore_mark(savemark)

const
compile if not defined( MONOFONT_STRINGS)
   MONOFONT_STRINGS = 'MONO VIO FIX COURIER LETTER MINCHO TYPEWRITER'
compile endif

defproc IsMonoFont
   parse value queryfont(.font) with fontname '.' fontsize '.'

   fMonoFont = 0

   StringList = upcase( MONOFONT_STRINGS)
   Name       = upcase( fontname)
   -- Ignore MONOTYPE, because it's a brand name
   wp = wordpos( 'MONOTYPE', Name)
   if wp > 0 then
      Name = delword( Name, wp, 1)
   endif
   do w = 1 to words( StringList)
      String = word( StringList, w)
      if pos( String, Name) > 0 then
         fMonoFont = 1
         leave
      endif
   enddo

   if fMonoFont = 0 then
      if rightstr( fontsize, 2) = 'BB' then  -- Bitmapped font
         parse value fontsize with 'DD' decipoints 'WW' width 'HH' height 'BB'
         if width & height then  -- It's fixed pitch
            fMonoFont = 1
         endif
      endif
   endif

   return fMonoFont

const
compile if not defined( STD_MONOFONT)
;  STD_MONOFONT = SYS_MONOSPACED_SIZE'.System Monospaced'
   STD_MONOFONT = '12.System VIO' -- 'DD120HH16WW8BB'
compile endif

defc Monofont
   universal app_hini
   NewFont = ''
   getfileid fid
   call SetAVar( 'monofont.'fid, 1)
   -- Query Monofont from font styles and always use it, if defined
   MonoFontList = 'MonoFont Monofont MONOFONT monofont'
   do w = 1 to words( MonoFontList)
      Wrd = word( MonoFontList, w)
      next = queryprofile( app_hini, 'Style', Wrd)  -- case-sensitive
      if next > '' then
         -- Strip color attributes
         parse value next with name'.'size'.'attrib'.'fgcol'.'bgcol
         NewFont = name'.'size'.'attrib
         leave
      endif
   enddo
   -- If Monofont style is not defined, take default Monofont, but only
   -- if current font is not already a monospaced font.
   if NewFont = '' then
      if not IsMonofont() then
         NewFont = STD_MONOFONT
      endif
   endif
   if NewFont > '' then
      'SetTextFont' NewFont  -- SetTextFont is defined in MODEEXEC.E
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: Get_Array_Value(array_ID, array_index, value)            ³
³                                                                            ³
³ what does it do : Looks up the index in the array, and if found, puts the  ³
³                   value in VALUE.  The result returned for the function    ³
³                   is the return code from the array lookup - 0 if          ³
³                   successful.  If the index wasn't found, VALUE will       ³
³                   contain the null string and rc = -330 will be returned.  ³
³                                                                            ³
³ who and when    : Larry M.   9/12/91                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
; This should be used instead of any 'do_array 3' to avoid the error msg if
; it doesn't exist.
defproc get_array_value( array_ID, array_index, var array_value)
   rc = 0
   array_value = ''
   display -2  -- switch off messages
   do_array 3, array_ID, array_index, array_value
   display 2
   return rc

; ---------------------------------------------------------------------------
; Some useful procedures to use array vars easily. They can be used like
; universal vars, but 'universal' must not be specified. Maybe array vars
; are slower than universal vars, but on a 2Mhz CPU there's no noticable
; difference.
; ---------------------------------------------------------------------------
; Only the proc GetAVar returns a value. Therefore these procs can be used
; without 'call'. rc will be set by do_array, so it can be checked, if the
; operation was successful.
; Varnames are converted to lowercase, so every case can be used.
defproc GetAVar( varname)
   universal EPM_utility_array_ID
   varname = lowcase( arg(1))
   varvalue = ''
   rc = get_array_value( EPM_utility_array_ID, varname, varvalue)  -- sets rc
   if rc = -330 then  -- rc = -330: "Invalid third parameter"
      -- Return no error, if var doesn't exist already
      rc = 0
   endif
   return varvalue

defc getavar, showavar
   varname = strip( arg(1))
   -- a cmd can't return anything, therefore just give a msg
   sayerror varname' = 'GetAVar(varname)

; ---------------------------------------------------------------------------
; Set varname to varvalue
defproc SetAVar( varname, varvalue)
   universal EPM_utility_array_ID
   varname = lowcase( varname)
   do_array 2, EPM_utility_array_ID, varname, varvalue  -- sets rc
   return

defc setavar
   args = strip( arg(1))
   parse value args with varname varvalue
   call SetAVar( varname, varvalue)

; ---------------------------------------------------------------------------
; Check for every word of varvalue if already present in varname; add if not
; present; else nothing.
defproc AddAVar( varname, varvalue)
   oldvalue = GetAVar(varname)
   newvalue = oldvalue
   do w = 1 to words( varvalue)
      wrd = word( varvalue, w)
      if not wordpos( upcase( wrd), upcase( oldvalue)) then
         newvalue = strip( newvalue' 'wrd)  -- verify, there's a space between
      endif
   enddo
   call SetAVar( varname, newvalue)
   return

defc addavar
   args = strip( arg(1))
   parse value args with varname varvalue
   call AddAVar( varname, varvalue)

; ---------------------------------------------------------------------------
; Remove every word of varvalue from varname
defproc DelAVar( varname, varvalue)
   oldvalue = GetAVar(varname)
   if oldvalue = '' then
      return
   endif
   newvalue = oldvalue
   do w = 1 to words( varvalue)
      wrd = word( varvalue, w)
      do forever
         wp = wordpos( upcase( wrd), upcase( newvalue))
         if wp = 0 then
            leave
         endif
         newvalue = delword( newvalue, wp, 1)
      enddo
   enddo
   call SetAVar( varname, newvalue)
   return

defc DelAVar
   args = strip( arg(1))
   parse value args with varname varvalue
   call DelAVar( varname, varvalue)

; ---------------------------------------------------------------------------
; Remove varname from array
defproc DropAVar( varname)
   universal EPM_utility_array_ID
   varname = lowcase( varname)
   do_array 4, EPM_utility_array_ID, varname  -- delete entry
   return

defc DropAVar
   varname = strip( arg(1))
   call DropAVar( varname)

; ---------------------------------------------------------------------------
defproc Insert_Attribute_Pair( attribute, val, fstline, lstline, fstcol, lstcol, fileid)
   universal EPM_utility_array_ID
;sayerror 'Insert_Attribute_Pair('attribute',' val',' fstline',' lstline',' fstcol',' lstcol',' fileid')'
   class = attribute
   offst1 = -255
   col = fstcol
   line = fstline
   pairoffst = -255
   attribute_action 1, class, offst1, col, line, fileid -- 1 = FIND NEXT ATTR
;sayerror 'attribute_action FIND NEXT ATTR,' class',' offst1',' col',' line',' fileid -- 1 = FIND NEXT ATTR
   if class & col = fstcol & line = fstline  then  -- Found one!
      offst2 = offst1
      attribute_action 3, class, offst2, col, line, fileid -- 3 = FIND MATCH ATTR
;sayerror 'attribute_action FIND MATCH ATTR,' class',' offst2',' col',' line',' fileid -- 1 = FIND NEXT ATTR
      if class then
         lc1 = lstcol + 1
         if line = lstline & col = lc1 then  -- beginning and end match, so replace the old attributes
compile if defined(COMPILING_FOR_ULTIMAIL)
            replace_it = 1
            if class = 14 then  -- STYLE_CLASS
               query_attribute class, val2, IsPush, offst1, fstcol, fstline, fileid
               --do_array 3, EPM_utility_array_ID, 'si.'val, stylename -- Get the style name
               rc = get_array_value( EPM_utility_array_ID, 'si.'val, stylename)  -- Get the style name
               is_color1 = wordpos(stylename, "black blue red pink green cyan yellow white darkgray darkblue darkred darkpink darkgreen darkcyan brown palegray")
               --do_array 3, EPM_utility_array_ID, 'si.'val2, stylename -- "
               rc = get_array_value( EPM_utility_array_ID, 'si.'val2, stylename)  -- "
               is_color2 = wordpos(stylename, "black blue red pink green cyan yellow white darkgray darkblue darkred darkpink darkgreen darkcyan brown palegray")
               if (is_color1 & not is_color2) | (is_color2 & not is_color1) then
                  replace_it = 0
               endif
            endif
            if replace_it then
compile endif
               attribute_action 16, class, offst1, fstcol, fstline, fileid -- 16 = DELETE ATTR
;sayerror 'attribute_action DELETE ATTR,' class',' offst1',' fstcol',' fstline',' fileid -- 1 = FIND NEXT ATTR
               attribute_action 16, class, offst2, lc1, lstline, fileid -- 16 = DELETE ATTR
;sayerror 'attribute_action DELETE ATTR,' class',' offst2',' lc1',' lstline',' fileid -- 1 = FIND NEXT ATTR
               pairoffst = offst1 + 1
               if not pairoffst then
                  lstcol = lc1
               endif
compile if defined(COMPILING_FOR_ULTIMAIL)
            endif
compile endif
         elseif line>lstline | (line = lstline & col>lstcol) then  -- old range larger then new
;sayerror 'pair offset set to 0'
            pairoffst = 0  -- so add attributes on the inside.
            lstcol = lc1
         endif
      endif
compile if 1  -- Disallow overlapping attributes.
   else  -- While we have an attribute that's before the desired endpoint, ...
      do while class & (line < lstline | (line = lstline & col < lstcol))  -- Found one; check for overlap
         query_attribute class, val2, IsPush, offst1, col, line, fileid
         if not IsPush then  -- Found a pop before a push!
            sayerror OVERLAPPING_ATTRIBS__MSG
            return
         endif
         offst2 = offst1
         col2 = col
         line2 = line
         attribute_action 3, class, offst2, col2, line2, fileid -- 3 = FIND MATCH ATTR
;sayerror 'attribute_action FIND MATCH ATTR,' class',' offst2',' col2',' line2',' fileid -- 1 = FIND NEXT ATTR
         if not class then  -- No match?  Most curious...
            leave
         endif
         if line2 > lstline | (line2 = lstline & col2 > lstcol) then
            sayerror OVERLAPPING_ATTRIBS__MSG
            return
         endif
         offst1 = offst2 + 1
         col = col2
         line = line2
         attribute_action 1, class, offst1, col, line, fileid -- 1 = FIND NEXT ATTR
;sayerror 'attribute_action FIND NEXT ATTR,' class',' offst1',' col',' line',' fileid -- 1 = FIND NEXT ATTR
      enddo
compile endif
   endif
   insert_attribute attribute, val, 1, pairoffst, fstcol, fstline, fileid
   insert_attribute attribute, val, 0, -pairoffst, lstcol, lstline, fileid

; Turns on the specified bit (1, 2, 4, etc.) and returns 0 or 1 depending
; on whether it was originally off or on.
defproc attribute_on(bit)
   flag = (.levelofattributesupport bitand bit) <> 0
   if not flag then  -- Is that bit off?
      .levelofattributesupport = .levelofattributesupport + bit  -- Turn it on!
   endif
   return flag

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: setfont                                                  ³
³                                                                            ³
³ what does it do : Send change font message to editor.                      ³
³                   Arguments are the font cell width and the font cell      ³
³                   height.  example:  setfont(7, 15)                        ³
³                                                                            ³
³                                                                            ³
³ who and when    : Jerry C.  11/04/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc setfont( width, height)
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),   -- Post message to edit client
                       5381,               -- EPM_EDIT_CHANGEFONT
                       height,
                       width)


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: commandline     syntax:  commandline [optional text]     ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal commandline control.  ³
³                   This is done by posting a EPM_POPCMDLINE message to the  ³
³                   EPM Book window.                                         ³
³                   An optional string of text can be specified.  If a string³
³                   is specified then it will be inserted on the command line³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc commandline  -- The application will free the buffer allocated by this macro !!!
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       5124,               -- EPM_POPCMDLINE
                       0,
                       put_in_buffer(arg(1)))


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: PostCmdToEditWindow(cmd, winhandle [, mp2 [, buflg]] )   ³
³                                                                            ³
³ what does it do : ask EPM.EXE to post a command to an edit window.  MP2 is ³
³                   optional MP2 for the WinPostMsg.  Default is 1 (EPM      ³
³                   should free the command buffer).  4 means process        ³
³                   synchronously (not safe), and 8 means that EPM should do ³
³                   a DosGetBuf to get the buffer.  Optional 4th argument is ³
³                   passed to put_in_buffer (flag for DosAllocSeg; see       ³
³                   put_in_buffer routine for details).                      ³
³                                                                            ³
³ who and when    : Larry M.   7/23/90                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc PostCmdToEditWindow( cmd, winhndl)
   if arg(3) <> '' then
      mp2 = arg(3)
   else
      mp2 = 1
   endif
   call windowmessage( 0, winhndl,
                       5377,               -- EPM_EDIT_COMMAND
                       put_in_buffer( cmd, arg(4)),
                       mp2)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: PostMe          syntax:   PostMe command                 ³
³                                                                            ³
³ what does it do : Ask EPM.EXE to post a command to the current edit window.³
³                   Useful if you want to send a command on an OPEN but      ³
³                   don't want to tie up the main queue while the command is ³
³                   executing.  By posting the command back to the window,   ³
³                   it will execute from the EI queue, and not keep everyone ³
³                   else waiting.                                            ³
³                                                                            ³
³                   Example of usage:                                        ³
³                      "open 'PostMe long_running_command'"                  ³
³                                                                            ³
³ who and when    : Larry M.   89/08/14                                      ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc PostMe
   -- Workaround for posted '*defload*' commands: Execute 'AtNextLoad'
   -- instead of 'postme', because 'postme' causes a defload action being
   -- executed at the following defselect only. Applies to e.g. TeX Front
   -- End's defload.
   if pos( 'DEFLOAD', upcase( arg(1))) then
      'AtNextLoad' arg(1)
   else
      call PostCmdToEditWindow( arg(1), getpminfo(EPMINFO_EDITCLIENT))
      dprintf( 'POSTME', arg(1))
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: buffer_command    syntax:   buffer_command buff_address  ³
³                                                                            ³
³ what does it do : Executes the command that's stored in the buffer, then   ³
³                   frees the buffer.  Useful if you want to send a command  ³
³                   to another window but don't want to worry about length   ³
³                   or invalid characters.                                   ³
³                                                                            ³
³                   Example of usage:                                        ³
³                      "open 'buffer_command" put_in_buffer(cmd_string)      ³
³                                                                            ³
³ who and when    : Larry M.   91/09/03                                      ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc buffer_command
   parse arg buff .
   if not buff then return; endif  -- Null pointer = no command
   buffer_long = atol(buff)
   peekz(buffer_long)              -- Get the command from the buffer, & execute it
   call dynalink32( 'DOSCALLS',          -- Dynamic link library name
                    '#304',              -- Dos32FreeMem
                    buffer_long)

defc buff_link
   parse arg buff .
   if not buff then return; endif
   rc = dynalink32( 'DOSCALLS',
                    '#302',  -- Dos32GetSharedMem
                    atol(buff)      ||  -- Base address
                    atol(1))             -- PAG_READ
   if rc then
      messageNwait('DosGetSharedMem' ERROR__MSG rc)
   endif
   buff_ofs = 4
   buff_len = ltoa(peek32(buff, 0, 4), 10)
   do while buff_len > buff_ofs
      link_file = peekz32(buff, buff_ofs)
      if upcase(link_file)<>'EPM.EX' then
         if linked(link_file) < 0 then  -- Not already linked
            'linkverify' link_file
         endif
      endif
      buff_ofs = buff_ofs + length(link_file) + 1  -- +1 for ASCIIZ null
   enddo

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: messagebox      syntax:   messagebox [optional string]   ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal message box control.  ³
³                   This is done by posting a EPM_POPMSGBOX  message to the  ³
³                   EPM Book window.                                         ³
³                   An optional string of text can be specified.  If a       ³
³                   string is specified then it will be inserted into the    ³
³                   message box.                                             ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc messagebox  -- The application will free the buffer allocated by this macro !!!
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       5125,               -- EPM_POPMSGBOX
                       0,
                       put_in_buffer(arg(1)))

; Moved file and WinFileDlg defs to FILE.E

; Moved defc searchdlg to LOCATE.E

; Moved all ini defs to CONFIG.E

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: processdragdrop                                          ³
³                                                                            ³
³ what does it do : this defc is automatically called by the                 ³
³                   toolkit when a drag drop event is successfully made      ³
³                                                                            ³
³ what are the args:    cmdid =  1   - epm edit window                       ³
³                                2   - File icon window (self)               ³
³                                3   - epm book icon                         ³
³                                4   - system editor                         ³
³                                5   - File Manager folder                   ³
³                                10  - Print manager                         ³
³                                                                            ³
³                       hwnd  =  handle of target window's frame             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
; unused (with WPS anyway)
defc ProcessDragDrop
   parse arg cmdid hwnd
   --dprintf( 'ProcessDragDrop', 'cmdid = 'cmdid', hwnd = 'hwnd)
;  hwnd = atol_swap(hwnd)

   if cmdid = 10 then
    call windowmessage( 0,
                        getpminfo(APP_HANDLE),
                        5144,               -- EPM_PRINTDLG
                        hwnd = 'M',
                        0)
   elseif cmdid = 1 and hwnd <> getpminfo(EPMINFO_EDITFRAME) and leftstr( .filename, 1) <> '.' then
      call PostCmdToEditWindow( 'e '.filename, hwnd, 9, 2)  -- Get-able
   elseif cmdid = 3 then
      if .filename = GetUnnamedFilename() then name = ''; else name = .filename; endif
      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5386,                     -- EPM_EDIT_NEWFILE
                          put_in_buffer( name, 2),  -- share = GETable
                          9)                        -- EPM does a GET first & a FREE after.
   elseif cmdid = 4 then
      call winmessagebox( SYS_ED__MSG,
                          SYS_ED1__MSG\10  ||
                          '   :-)',
                          16406)  -- CANCEL + ICONQUESTION + MB_MOVEABLE
   elseif cmdid = 5 then
      str = leftstr( '', MAXCOL)
      len = dynalink32( 'PMWIN',
                        '#841',             --   'WINQUERYWINDOWTEXT',
                        atol(hwnd)         ||
                        atol(MAXCOL)       ||
                        address(str), 2)
      p = lastpos( '\',leftstr( str, len))
      if p then
         str = leftstr( str, p)' = '
         call parse_filename( str, .filename)
         if exist(str) then
            if 1 <> winmessagebox( str,
                                   EXISTS_OVERLAY__MSG,
                                   16417) then -- OKCANCEL + CUANWARNING + MOVEABLE
               return  -- 1 = MB OK
            endif
         endif
         'save' str
         if not rc then sayerror SAVED_TO__MSG str; endif
      else
         call winmessagebox( '"'leftstr( str, len)'"',
                             NO_SLASH__MSG,
                             16406) -- CANCEL + ICONQUESTION + MB_MOVEABLE
      endif
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: repaint_window                                           ³
³                                                                            ³
³ what does it do : send a paint message to the editor.                      ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc repaint_window()
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       35, 0, 0)   -- WM_PAINT

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: showwindow                                               ³
³                                                                            ³
³ what does it do : allows the edit window to become invisible or visible    ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc showwindow
   -- post the EPM_EDIT_SHOW message
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       5385,
                       upcase(arg(1)) <> 'OFF', -- 0 if OFF, else 1
                       0)

; Moved defproc settitletext from STDCTRL.E to STATLINE.E to INFOLINE.E

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: WinMessageBox                                            ³
³                                                                            ³
³ what does it do : This routine issues a PM WinMessageBox call, and returns ³
³                   the result.                                              ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc winmessagebox( caption, text)

; msgtype = 4096                                        -- must be system modal.
; if arg(3) then
;    msgtype = arg(3) + 4096 * (1 - (arg(3)%4096 - 2 * (arg(3)%8192)))  -- ensure x'1000' on
; endif
  if arg(3) then
     msgtype = arg(3)
  else
     msgtype = 0
  endif
  caption = caption\0
  text    = text\0
  return dynalink32( 'PMWIN',
                     "#789",      -- WinMessageBox
                     atol(1) ||   -- Parent
                     gethwndc(EPMINFO_EDITFRAME) ||   /* edit frame handle             */
                     address(text)      ||   -- Text
                     address(caption)   ||   -- Title
                     atol(0)            ||   -- Window
                     atol(msgtype))          -- Style


defproc mpfrom2short( mphigh, mplow)
   return ltoa( atoi(mplow) || atoi(mphigh), 10)

/* Returns the edit window handle, as a 4-digit decimal string. */
defproc gethwnd(w)
;  EditHwnd = getpminfo(w)         /* get edit window handle          */

   /* String handling in E language :                                 */
   /*    EditHwnd = '1235:1234'   <-  address in string form          */
   /*    atol(EditHwnd) = '11GF'  <-  four byte pointer, represented  */
   /*                                 as its ascii character          */
   /*                                 equivalent.                     */
   /*    Flipping (substr(...) ) <-  places 4 bytes in correct order. */
   /*    Note:    2byte vars are converted with atoi   ie.  USHORT    */
   /*    Note:    4byte vars are converted with atol   ie.  HWND,HAB  */

                                  /* get edit window handle           */
                                  /* convert string to string pointer */
                                  /* interchange upper two bytes with */
                                  /* lower two bytes. (flip words)    */
   return atol_swap(getpminfo(w))

defproc gethwndc(w)
   return atol(getpminfo(w))

; Moved menu defs to MENU.E

; Moved defc undo to UNDO.E

defc popbook =
   call windowmessage( 0,  getpminfo(APP_HANDLE),
                       13,                 -- WM_ACTIVATE
                       1,
                       getpminfo(APP_HANDLE))

defc printdlg
   call windowmessage( 0,
                       getpminfo(APP_HANDLE),
                       5144,               -- EPM_PRINTDLG
                       arg(1) = 'M',
                       0)

defc printfile
   if arg(1)<>'' then
      'xcom save /s /ne' arg(1)  -- Save the file to the printer
   endif

defc process_qprint
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
   if arg(1) = '' then
      sayerror PRINTER__MSG /*printername*/ NO_QUEUE__MSG
   else
      mouse_setpointer WAIT_POINTER
      qprint arg(1)
compile if EPM_POINTER = 'SWITCH'
      mouse_setpointer vEPM_POINTER
compile else
      mouse_setpointer EPM_POINTER
compile endif
   endif

; Flags
;  F    = File
;  M  1 = marked area (default = entire file)
;  !  2 = print immediately; don't wait for print dialog's OK
;     4 = queue name given
;     8 = PRINTOPTS structure given (binary structure; can't be done via this cmd)
;         (6.03a or above, only)
defc qprint
   parse arg what queue_name
   w = wordpos( upcase(what), 'M M! F F! !')
   if w then
      flags =           word( '1 3  0 2  2', w)
   else                   -- Not a flag;
      queue_name = arg(1)  -- assume part of the queue name
      flags = 0            -- and use default options.
   endif
   if queue_name <> '' then flags = flags + 4; endif
   call windowmessage(0,
                      getpminfo(APP_HANDLE),
                      5144,               -- EPM_PRINTDLG
                      flags,
                      put_in_buffer(queue_name))

defc ibmmsg
   ever = EVERSION
   if \0 = rightstr( EVERSION, 1) then
      ever = leftstr( EVERSION, length(eversion) - 1)
   endif
   call WinMessageBox( EDITOR__MSG,
                       EDITOR_VER__MSG ver(0)\13  ||
                       MACROS_VER__MSG ever\13\13 ||
                       COPYRIGHT__MSG,
                       16384)

defproc LoadVersionString( var buff, var modname)
   hmodule = \0\0\0\0

   if arg(3) then
      modname = arg(3)\0
      rc = dynalink32('DOSCALLS',
                      '#318',  -- Dos32LoadModule
                      atol(0) ||  -- Buffer address
                      atol(0) ||  -- Buffer length
                      address(modname) ||
                      address(hmodule))
   endif

   buff = copies( \0, 255)
   res = dynalink32( 'PMWIN',
                     '#781',  -- Win32LoadString
                     gethwndc(EPMINFO_HAB)  ||
                     hmodule                ||  -- NULLHANDLE
                     atol(65535)            ||  -- IDD_BUILDDATE
                     atol(length(buff))     ||
                     address(buff), 2)
   buff = leftstr( buff, res)

   if arg(3) then
      modname = copies( \0, 260)
      call dynalink32( 'DOSCALLS',         -- dynamic link library name
                       '#320',                    -- DosQueryModuleName
                       hmodule               ||   -- module handle
                       atol(length(modname)) ||   -- Buffer length
                       address(modname))          -- Module we've loading
      call dynalink32( 'DOSCALLS',
                       '#322',  -- Dos32FreeModule
                       hmodule)
      parse value modname with modname \0
   endif


defc versioncheck =
                 -- Get EPM.EXE build date
   LoadVersionString(buff, modname)
                 -- Get ETKEnnn.DLL build date
   LoadVersionString(buffe, modname, E_DLL)
                 -- Get ETKRnnn.DLL build date
   LoadVersionString(buffr, modname, ERES2_DLL)
                 -- Get ETKRnnn.DLL build date
   LoadVersionString(buffc, modname, ERES_DLL)
   /*
                 -- Get EPMMRI.DLL build date
   LoadVersionString(buffm, modname, 'EPMMRI')
   */
   call WinMessageBox( "EPM Build",
                       EDITOR_VER__MSG ver(0)\13             ||
                       MACROS_VER__MSG EVERSION\13           ||
                       '('wheredefc('versioncheck')')'\13\13 ||
                       'EPM.EXE' buff\13                     ||
                       E_DLL'.DLL' buffe\13                  ||
                       ERES2_DLL'.DLL' buffr\13              ||
                       ERES_DLL'.DLL' buffc\13               ||
                       /*'EPMMRI.DLL' buffm\13*/\13              ||
                       COPYRIGHT__MSG,
                       16384)

defc versioncheck_file =
   'xcom e /c /q tempfile'
   if rc<>-282 then  -- sayerror('New file')
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   .autosave = 0
   .filename = ".EPM Build"
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   insertline EDITOR_VER__MSG ver(0), 1
   insertline MACROS_VER__MSG EVERSION, 2
   insertline '('wheredefc('versioncheck')')', 3
   LoadVersionString(buff, modname)
   insertline 'EPM.EXE    ' buff '('find_epm_exec()')', .last+1
   LoadVersionString(buff, modname, E_DLL)
   insertline E_DLL'.DLL' buff '('modname')', .last+1
   LoadVersionString(buff, modname, ERES2_DLL)
   insertline ERES2_DLL'.DLL' buff '('modname')', .last+1
   LoadVersionString(buff, modname, ERES_DLL)
   insertline ERES_DLL'.DLL' buff '('modname')', .last+1
   /*
   LoadVersionString(buff, modname, 'ETKUCMS')
   insertline 'ETKUCMS.DLL' buff '('modname')', .last+1
   LoadVersionString(buff, modname, 'EPMMRI')
   insertline 'EPMMRI.DLL' buff '('modname')', .last+1
   */
   .modify = 0
   if browse_mode then call browse(1); endif

; Allow other (maybe linked) packages to query the macro version of EPM.E.
; Used by NepmdInfo.
defproc GetEVersion
   return EVERSION

; Allow other (maybe linked) packages to query the version of NEPMD.
; Used by NepmdInfo.
defproc GetNepmdVersion
   return NEPMD

defproc find_epm_exec =
   pib = 1234
   tid = 1234

   call dynalink32('DOSCALLS',      -- dynamic link library name
                   '#312',          -- ordinal value for DOS32GETINFOBLOCKS
                   address(tid) ||
                   address(pib), 2)
   return peekz(peek32(ltoa(pib, 10), 12, 4))

defproc put_in_buffer(string)
   if string = '' then                   -- Was a string given?
      return 0                         -- If not, return a null pointer.
   endif
   if arg(2) = '' then
      share = 83  -- PAG_READ | PAG_WRITE | PAG_COMMIT | OBJ_TILE
   else
      share = arg(2)
   endif
   strbuffer = "????"                  -- Initialize string pointer.
   r = dynalink32( 'DOSCALLS',          -- Dynamic link library name
                   '#299',                    -- Dos32AllocMem
                   address(strbuffer)     ||
                   atol(length(string)+1) ||  -- Number of bytes requested
                   atol(share))               -- Share information

   if r then sayerror ERROR__MSG r ALLOC_HALTED__MSG; stop; endif
   strbuffer = itoa(substr(strbuffer,3,2),10)
   poke strbuffer,0,string    -- Copy string to new allocated buf
   poke strbuffer,length(string),\0  -- Add a null at the end
   return mpfrom2short(strbuffer,0)    -- Return a long pointer to buffer


; Moved defc loadaccel, alt_enter, dokey, keyin to KEYS.E.

;compile if defined(BLOCK_ALT_KEY)
defc beep =
   a = arg(1)
   do while a <> ''
      parse value a with pitch duration a
      call beep( pitch, duration)
   enddo
;compile endif

defc maybe_reflow_ALL
   do i = 1 to .last
      if textline(i) <> '' then  -- Ask only if there's text in the file.
         if askyesno( REFLOW_ALL__MSG, 1) = YES_CHAR then
            'reflow_all'
         endif
         leave
      endif
   enddo

; Moved defc setstatusline and setinfoline to INFOLINE.E
; Moved defc new to EDIT.E
; Moved defc viewword to KWHELP.E

compile if 0
defc QueryHLP = sayerror '"'QueryCurrentHLPFiles()'"'
defproc QueryCurrentHLPFiles()
   universal CurrentHLPFiles;
   return CurrentHLPFiles;

defc setHLP = sayerror '"'SetCurrentHLPFiles(arg(1))'"'
defproc SetCurrentHLPFiles(newlist)
   universal CurrentHLPFiles;
   hwndHelpInst = windowmessage( 1, getpminfo(APP_HANDLE),
                                 5429,      -- EPM_Edit_Query_Help_Instance
                                 0,
                                 0)
   if hwndHelpInst == 0 then
      -- there isn't a help instance deal with.
      return "No Help Instance";
   endif

   newlist2 = newlist || chr(0);
   retval = windowmessage( 1, hwndHelpInst,
                           557,    -- HM_SET_HELP_LIBRARY_NAME
                           ltoa( offset(newlist2) || selector(newlist2), 10),
                           0)
   if retval == 0 then
      -- it worked, now remember what you told it.
      CurrentHLPFiles = newlist;
   else
      -- failed for some reason, anyway, we had better revert to
      --   the previous version of the HLP list.
      if CurrentHLPFiles == "" then
         CurrentHLPFiles = " ";
      endif
      newlist2 = CurrentHLPFiles || chr(0);
      retval2 = windowmessage( 1, hwndHelpInst,
                               557,    -- HM_SET_HELP_LIBRARY_NAME
                               ltoa( offset(newlist2) || selector(newlist2), 10),
                               0)
      if retval2 == 0 then
         -- whew, we were able to revert to the old list
         return retval;
      else
         return "two errors" retval retval2;
      endif
   endif

compile endif

;compile if KEEP_CURSOR_ON_SCREEN
-- This should move the cursor at the end of every scroll bar action.  The
-- position to which it is moved should correspond to the location of the
-- cursor (relative to the window) at the time when the scroll began.

defc ProcessEndScroll
   universal beginscroll_x, beginscroll_y;
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      .cursorx = beginscroll_x;
      .cursory = beginscroll_y;
      if not .line & .last then
         .lineg = 1
      endif
   endif

defc ProcessBeginScroll
   universal beginscroll_x, beginscroll_y;
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      beginscroll_x = .cursorx;
      beginscroll_y = .cursory;
   endif
;compile endif  -- KEEP_CURSOR_ON_SCREEN

; ---------------------------------------------------------------------------
; Internally called when a color or a font is dropped on a window.
; This is always followed by a SaveFont or SaveColor command. The internally
; defined SaveColor command will be ignored, because its standard args EDIT,
; MSG or STAT are not precise enough. Therefore SaveColor is executed from
; here additionally.
defc SetPresParam
   universal msgfont
   universal statfont
   universal vmessagecolor
   universal vstatuscolor
   universal vmodifiedstatuscolor
   universal vdesktopcolor
   fModified = (.modify > 0)
   --dprintf( 'SETPRESPARAM', 'arg(1) = ['arg(1)']')
   -- SETPRESPARAM: arg(1) = [MSGBGCOLOR hwnd=-2147483054 x=175 y=12 rgb=16777215 clrattr=15 oldfgattr=3 oldbgattr=7]
   -- SETPRESPARAM: arg(1) = [MSGFONTSIZENAME hwnd=-2147483054 x=41 y=8 string=10.Helv]
   -- SETPRESPARAM: arg(1) = [STATFONTSIZENAME hwnd=-2147483058 x=636 y=9 string=10.System Proportional Non-ISO]
   -- SETPRESPARAM: arg(1) = [EDITFONTSIZENAME hwnd=-2147483047 x=676 y=179 string=12.System VIO]
   parse value arg(1) with whichctrl " hwnd="hwnd " x="x "y="y rest

   -- Font: statusbar, messagebar
   if (whichctrl == "STATFONTSIZENAME") or (whichctrl == "MSGFONTSIZENAME") then
      parse value rest with "string="psize"."facename"."attr
      -- psize is pointsize, facename is facename, attr is "Bold" etc
      "setstatface" hwnd facename
      "setstatptsize" hwnd psize
      newfont = substr( rest, 8)
      if leftstr( whichctrl, 1) = 'S' then  -- "STATFONTSIZENAME"
         statfont = newfont
      else                                  -- "MSGFONTSIZENAME"
         msgfont = newfont
         sayerror MESSAGELINE_FONT__MSG
      endif

   -- Foreground color: statusbar, messagebar
   elseif (whichctrl == "STATFGCOLOR") or (whichctrl == "MSGFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage( 0, hwnd,
                          4099,      -- STATWNDM_SETCOLOR
                          clrattr,
                          oldbgattr)
      newcolor = clrattr + 16 * oldbgattr
      if leftstr( whichctrl, 1) = 'M' then
         sayerror MESSAGELINE_FGCOLOR__MSG
         --dprintf( 'SETPRESPARAM', 'MsgFgColor')
         vmessagecolor = newcolor
         'SaveColor MESSAGE'
      elseif not fModified then
         --dprintf( 'SETPRESPARAM', 'StatFgColor, not modified')
         vstatuscolor = newcolor
         'SaveColor STATUS'
      else
         --dprintf( 'SETPRESPARAM', 'StatFgColor, modified')
         vmodifiedstatuscolor = newcolor
         'SaveColor MODIFIEDSTATUS'
      endif

   -- Background color: statusbar, messagebar
   elseif (whichctrl == "STATBGCOLOR") or (whichctrl == "MSGBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage( 0, hwnd,
                          4099,      -- STATWNDM_SETCOLOR
                          oldfgattr,
                          clrattr)
      newcolor = oldfgattr + clrattr * 16
      if leftstr( whichctrl, 1) = 'M' then
         sayerror MESSAGELINE_BGCOLOR__MSG
         --dprintf( 'SETPRESPARAM', 'MsgBgColor')
         vmessagecolor = newcolor
         'SaveColor MESSAGE'
      elseif not fModified then
         --dprintf( 'SETPRESPARAM', 'StatBgColor, not modified')
         vstatuscolor = newcolor
         'SaveColor STATUS'
      else
         --dprintf( 'SETPRESPARAM', 'StatBgColor, modified')
         vmodifiedstatuscolor = newcolor
         'SaveColor MODIFIEDSTATUS'
      endif

   -- Background color: editwindow
   elseif (whichctrl == "EDITBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      map_point 5, x, y, off, comment;  -- map screen to line
      if x < 1 | x > .last then
         --dprintf( 'SETPRESPARAM', 'EditBgColor, background')
         vdesktopcolor = clrattr
         call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                             5497,
                             clrattr,
                             0)
         'SaveColor BACKGROUND'
      else
         if InMark( x, y) then
            --dprintf( 'SETPRESPARAM', 'EditBgColor, text, in mark')
            .markcolor = (.markcolor // 16) + 16 * clrattr
            'SaveColor MARK'
         else
            --dprintf( 'SETPRESPARAM', 'EditBgColor, text, not in mark')
            .textcolor = (.textcolor // 16) + 16 * clrattr
            'SaveColor TEXT'
         endif
      endif

   -- Foreground color: editwindow
   elseif (whichctrl == "EDITFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      map_point 5, x, y, off, comment;  -- map screen to line
      if InMark( x, y) then
         --dprintf( 'SETPRESPARAM', 'EditFgColor, text, in mark')
         .markcolor = .markcolor - (.markcolor // 16) + clrattr;
         'SaveColor MARK'
      else
         --dprintf( 'SETPRESPARAM', 'EditFgColor, text, not in mark')
         .textcolor = .textcolor - (.textcolor // 16) + clrattr;
         'SaveColor TEXT'
      endif

   -- Font: editwindow
   elseif whichctrl == "EDITFONTSIZENAME" then
      parse value rest with "string="psize"."facename"."attr
      -- psize is pointsize, facename is facename, attr is "Bold" etc
      fontsel = 0
      do while attr <> ''
         parse value attr with thisattr '.' attr
         if     thisattr = 'Italic'     then fontsel = fontsel + 1
         elseif thisattr = 'Underscore' then fontsel = fontsel + 2
         elseif thisattr = 'Outline'    then fontsel = fontsel + 8
         elseif thisattr = 'Strikeout'  then fontsel = fontsel + 16
         elseif thisattr = 'Bold'       then fontsel = fontsel + 32
         endif
      enddo
      .font = registerfont( facename, psize, fontsel)

   else
      sayerror UNKNOWN_PRESPARAM__MSG whichctrl
      return
   endif
;   sayerror "set presparm with" hwnd " as the window" arg(1);

; ---------------------------------------------------------------------------
; Called by SetPresParam for message- or statusbar fontname.
defc setstatface
   parse value arg(1) with hwnd face
   return windowmessage( 0,  hwnd /*getpminfo(EPMINFO_EDITFRAME)*/,   -- Post message to edit client
                         4104,        -- STATWNDM_PREFFONTFACE
                         put_in_buffer(face),
                         1);  -- COMMAND_FREESEL

; ---------------------------------------------------------------------------
; Called by SetPresParam for message- or statusbar fontsize.
defc setstatptsize
   parse value arg(1) with hwnd ptsize
   if leftstr( ptsize, 1) = 'D' then  -- Decipoints
      parse value ptsize with 'DD' ptsize 'HH'
      parse value ptsize with ptsize 'WW'
      ptsize = ptsize % 10   -- convert decipoints to points
   endif
   return windowmessage( 0,  hwnd /*getpminfo(EPMINFO_EDITFRAME)*/,   -- Post message to edit client
                         4106,        -- STATWNDM_PREFFONTPTSIZE
                         ptsize,
                         0);

; ---------------------------------------------------------------------------
; Syntax:
; Font = Convert2EFont( <size>.<name>[[[.<attrib1>[ <attrib2>]].fgcolor].bgcolor])
;          or
; Font = Convert2EFont( <name>.<size>[[[.<attrib[ <attrib2>]].fgcolor].bgcolor])
; Both font specs are valid: '12.System VIO' or 'System VIO.DD120HH16WW8BB'
; + or <space> are allowed as separator for <attribs>. <attribs> can be
; specified as number or as name.
; Different from SetTextColor and SetMarkColor, the appended values for
; colors must be separated by a period and go both from 0 to 15.
; The returned syntax is used as arg for ProcessFontRequest and could be used
; for style settings.
; Notes: registerfont uses a different syntax: <name>.<DDsize>.<attrib_num>
;        fgcol'.'bgcol for e.g. .textcolor can be converted with
;        trunc(.textcolor//16)'.'.textcolor%16
defproc ConvertToEFont
   --dprintf( 'CONVERTTOEFONT', 'arg(1) = 'arg(1))
   parse arg name '.' size '.' rest

   next = upcase(size)
   next = translate( next, '', 'XDHWB', '0')
   if not isnum(next) then
      --sayerror 'size = "'size'" is num, arg(1) = 'arg(1)
      -- toggle name and size
      parse arg size '.' name '.'
   endif
   --sayerror 'name = "'name'", size = "'size'", next = "'next'", arg(1) = 'arg(1)
   parse value upcase(size) with h 'X' w
   if h <> '' & w <> '' then
      size = 'HH'h'WW'w
   endif

   attrib = 0
   fIsColor = 0
   fgcol = 0
   bgcol = 0
   do while rest > ''

      if fIsColor then
         --dprintf( 'CONVERTTOEFONT', 'colors = 'rest)
         parse value rest with fgcol '.' bgcol

         if fgcol = '' then
         elseif not isnum( fgcol) then
            fgcol = ConvertColor( fgcol)
            if rc then
               fgcol = ''
            endif
         endif

         if bgcol = '' then
         elseif not isnum( bgcol) then
            bgcol = ConvertColor( bgcol)
            if rc then
               bgcol = ''
            endif
         endif

         if (not isnum( fgcol)) | (not isnum( bgcol)) then
            fIsColor = 0  -- don't append font segments on error
         endif
         leave

      else
         parse value rest with segment '.' rest
         attriblist = translate( segment, ' ', '+')  -- allow '+' as separator
         --dprintf( 'CONVERTTOEFONT', 'attriblist = 'attriblist)

         do a = 1 to words( attriblist)
            next = word( attriblist, a)
            if isnum( next) then
               attrib = attrib + next
            elseif next = 'Normal' then
               -- attrib = attrib + 0
            elseif next = 'Italic' then
               attrib = attrib + 1
            elseif next = 'Underscore' then
               attrib = attrib + 2
            elseif next = 'Outline' then
               attrib = attrib + 8
            elseif next = 'Strikeout' then
               attrib = attrib + 16
            elseif next = 'Bold' then
               attrib = attrib + 32
            endif
         enddo

         -- Check following segment for another attribut name
         parse value rest with test '.' junk
         if test = '' then
            leave
         elseif wordpos( test, 'Normal Italic Underscore Strikeout Bold') then
         else
            fIsColor = 1  -- try to resolve the following segments as colors
            --dprintf( 'CONVERTTOEFONT', 'test = 'test', fIsColor = 'fIsColor)
         endif
         iterate

      endif
   enddo

   if fIsColor then
      EFont = name'.'size'.'attrib'.'fgcol'.'bgcol
   else
      EFont = name'.'size'.'attrib
   endif
   --dprintf( 'CONVERTTOEFONT', 'EFont = 'EFont)
   return EFont

; ---------------------------------------------------------------------------
defproc ConvertToOs2Font
   --dprintf( 'CONVERTTOOS2FONT', 'arg(1) = 'arg(1))
   parse arg name'.'size'.'attriblist

   next = upcase(size)
   next = translate( next, '', 'XDHWB', '0')
   if not isnum(next) then
      -- toggle name and size
      parse arg size'.'name'.'
   endif
   if leftstr( size, 1) = 'D' then  -- Decipoints
      parse value size with 'DD' size 'HH'
      parse value size with size 'WW'
      size = size % 10   -- convert decipoints to points
   endif

   if attriblist = 0 then
      attriblist = ''
   endif
   if attriblist > '' then
      attriblist = upcase(attriblist)
      attriblist = translate( attriblist, '  ', '+.')  -- allow '+' or '.' as separator
      attrib = 0
      do a = 1 to words(attriblist)
         next = word( attriblist, a)
         if isnum(next) then
            attrib = attrib + next
         else
            if next = 'NORMAL' then
               -- attrib = attrib + 0
            elseif wordpos( next, 'ITALIC OBLIQUE SLANTED') then
               attrib = attrib + 1
            elseif next = 'UNDERSCORE' then
               attrib = attrib + 2
            elseif next = 'OUTLINE' then
               attrib = attrib + 8
            elseif next = 'STRIKEOUT' then
               attrib = attrib + 16
            elseif next = 'BOLD' then
               attrib = attrib + 32
            endif
         endif
      enddo

      attriblist = ''
      rest = attrib
      next = rest - 32
      if next >= 0 then
         attriblist = attriblist'.Bold'
         rest = next
      endif
      next = rest - 16
      if next >= 0 then
         attriblist = attriblist'.Strikeout'
         rest = next
      endif
      next = rest - 8
      if next >= 0 then
         attriblist = attriblist'.Outline'
         rest = next
      endif
      next = rest - 2
      if next >= 0 then
         attriblist = attriblist'.Underscore'
         rest = next
      endif
      next = rest - 1
      if next >= 0 then
         attriblist = attriblist'.Italic'
         rest = next
      endif

   endif
   Os2Font = size'.'name''attriblist
   --dprintf( 'CONVERTTOOS2FONT', 'Os2Font = 'Os2Font)
   return Os2Font

; ---------------------------------------------------------------------------
; Syntax: Color = ConvertColor( <color1> [+ <color2>])
; <colors> are color names or numbers. The resulting Color is the summed
; value of all.
; Sets rc = 0 if color was resolved, else rc = 1.
defproc ConvertColor( args)
   rc = 0
   -- These are the standard EPM color names (note GREY instead of GRAY)
   List = '' ||
      'BLACK'          || '/' ||   '0' || '/' ||
      'BLUE'           || '/' ||   '1' || '/' ||
      'GREEN'          || '/' ||   '2' || '/' ||
      'CYAN'           || '/' ||   '3' || '/' ||
      'RED'            || '/' ||   '4' || '/' ||
      'MAGENTA'        || '/' ||   '5' || '/' ||
      'BROWN'          || '/' ||   '6' || '/' ||
      'GREY'           || '/' ||   '7' || '/' ||
      'DARK_GREY'      || '/' ||   '8' || '/' ||
      'LIGHT_BLUE'     || '/' ||   '9' || '/' ||
      'LIGHT_GREEN'    || '/' ||  '10' || '/' ||
      'LIGHT_CYAN'     || '/' ||  '11' || '/' ||
      'LIGHT_RED'      || '/' ||  '12' || '/' ||
      'LIGHT_MAGENTA'  || '/' ||  '13' || '/' ||
      'YELLOW'         || '/' ||  '14' || '/' ||
      'WHITE'          || '/' ||  '15' || '/'

   -- Some synonyms
   List = List ||
      'DARK_BLUE'      || '/' ||   '1' || '/' ||
      'DARK_GREEN'     || '/' ||   '2' || '/' ||
      'DARK_CYAN'      || '/' ||   '3' || '/' ||
      'DARK_RED'       || '/' ||   '4' || '/' ||
      'DARK_MAGENTA'   || '/' ||   '5' || '/' ||
      'LIGHT_GREY'     || '/' ||   '7' || '/' ||
      'GRAY'           || '/' ||   '7' || '/' ||
      'DARK_GRAY'      || '/' ||   '8' || '/' ||
      'LIGHT_GRAY'     || '/' ||   '7' || '/'

   Color = 0
   if isnum(args) then
      color = args
   else
      names = upcase(args)
      do while names <> ''
         -- Parse every arg at '+' boundaries
         parse value names with name '+' names
         fFound = 0
         -- Add underscore after 'LIGHT' or 'DARK', if missing
         parse value name with 'LIGHT'col
         if col <> '' & leftstr( col, 1) <> '_' then
            name = 'LIGHT_'col
         else
            parse value name with 'DARK'col
            if col <> '' & leftstr( col, 1) <> '_' then
               name = 'DARK_'col
            endif
         endif
         if isnum( name) then
            Color = Color + name  -- add
            fFound = 1
            iterate
         endif
         -- Parse list
         rest = List
         do while rest <> ''
            parse value rest with next1'/'next2'/'rest
            -- Compare: name or number
            if name = next1 then
               Color = Color + next2  -- add foreground color
               fFound = 1
               leave
            elseif name = next1'B' then
               Color = Color + 16 * next2  -- add background color
               fFound = 1
               leave
            endif
         enddo
         if fFound = 0 then
            --sayerror 'Unknown color specification "'name'"'
            --dprintf( 'Unknown color specification "'name'"')
            rc = 1
         endif
      enddo
   endif

   return color

; ---------------------------------------------------------------------------
defproc Thunk(pointer)
   return atol_swap( dynalink32( E_DLL,
                                 'FlatToSel',
                                 pointer, 2))

; ---------------------------------------------------------------------------
defc echoback
   parse arg postorsend hwnd messageid mp1 mp2 .
   call windowmessage( postorsend,
                       hwnd,
                       messageid,
                       mp1,
                       mp2)

; ---------------------------------------------------------------------------
defc toggle_parse
   parse arg parseon kwfilename
   if parseon & .levelofattributesupport//2 = 0  then  -- the first bit of .levelofattributesupport is for color attributes
      call attribute_on(1) -- toggles color attributes mode
   endif
   if kwfilename = '' then
      kwfilename = 'epmkwds.c'
   endif
   if parseon then  -- if 1 or 2
      findfile destfilename, kwfilename, 'EPMPATH'
      if rc then
         sayerror FILE_NOT_FOUND__MSG '-' kwfilename
         return
      endif
   endif
   getfileid fid

   -- Save keyword file in an array var
   -- (needed for a workaround for marking keyword-highlighted text in mouse.e)
   if parseon then
      call SetAVar( 'kwfile.'fid, kwfilename)
   endif
   --DPRINTF( '### HILITE', GetMode()': options: 'parseon kwfilename' filename: '.filename)

   call windowmessage( 0,  getpminfo(EPMINFO_EDITFRAME),
                       5502,               -- EPM_EDIT_TOGGLEPARSE
                       parseon,
                       put_in_buffer(fid kwfilename))

compile if 0
; ---------------------------------------------------------------------------
defc qparse =
   c = windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                      5505,               -- EPM_EDIT_KW_QUERYPARSE
                      0,
                      0)
   sayerror 'Keyword parsing is' word( OFF__MSG ON__MSG, 2 - (not c))  -- Use as boolean
compile endif

; ---------------------------------------------------------------------------
defc dyna_cmd =
   parse arg library entrypoint cmdargs
   if entrypoint = '' then
      sayerror -257  -- "Invalid number of parameters"
      return
   endif
   rc = 0
   cmdargs = cmdargs\0
   dynarc = dynalink32( library,
                        entrypoint,
                        gethwndc(EPMINFO_EDITCLIENT) ||
                        address(cmdargs),
                        2)

; ---------------------------------------------------------------------------
defc dynafree =
   res = dynafree(arg(1))
   if res then
      sayerror ERROR__MSG res
   endif

; ---------------------------------------------------------------------------
; Stops if current window is not the only EPM window, so this can be used as
; command.
defc CheckOnlyEpmWindow
   if not IsOnlyEpmWindow() then
      refresh
      Title = 'Multiple EPM windows'
      Text = 'The current command can''t be executed when multiple'      ||
             'EPM windows are open.'\n\n                                 ||
             'Close all other EPM windows and then repeat that command!'
      rcx = winmessagebox( Title, Text,
                           MB_OK + MB_WARNING + MB_MOVEABLE)
      stop
   endif

; ---------------------------------------------------------------------------
; Returns 0 or 1.
defproc IsOnlyEpmWindow
   ptr = dynalink32( 'PMWIN',
                     '#839',  -- Win32QueryWindowPtr
                     gethwndc(EPMINFO_OWNERFRAME) ||
                     atol(0), 2)
   listptr = ltoa( peek32( ptr, 1856, 4), 10)
   hwndx = peek32( listptr, 0, 4)
   next = ltoa( peek32( listptr, 8, 4), 10)
   if not next then
      return 1
   else
      return 0
   endif

; ---------------------------------------------------------------------------
; When a non-temporary file (except .Untitled) in ring is modified, then
; -  make this file topmost
; -  give a message
; -  set rc = 1 (but not required, because stop is used)
; -  stop processing of calling command or procedure.
; Otherwise set rc = 0.
defc RingCheckModify
   rc = 0
   getfileid fid
   startfid = fid
   dprintf( 'RINGCMD', 'RingCheckModify')
   do i = 1 to filesinring(1)  -- just as an upper limit
      fIgnore = (not .visible) | ((substr( .filename, 1, 1) = '.') & (.filename <> GetUnnamedFilename()))
      if fIgnore then
         .modify = 0
      else
         rcx = CheckModify()
         if rcx then
            activatefile startfid
            stop
         endif
      endif
      nextfile
      getfileid fid
      if fid = startfid then
         leave
      endif
   enddo

; ---------------------------------------------------------------------------
defc CheckModify
   rcx = CheckModify()
   if rcx then
      stop
   endif

; ---------------------------------------------------------------------------
; Resets .modify for Yes or No button. Yes: Save, No: Discard.
defproc CheckModify
   rc = 0
   if .modify then

      refresh
      Title = 'Save modified file'
      Text = .filename\n\n                                         ||
             'The above file is modified. Press "Yes" to save it,' ||
             ' "No" to discard it or "Cancel" to abort.'\n\n       ||
             'Do you want to save it?'
      rcx = winmessagebox( Title, Text,
                           MB_YESNOCANCEL + MB_QUERY + MB_DEFBUTTON1 + MB_MOVEABLE)

      if rcx = MBID_YES then
         'Save'
      elseif rcx = MBID_NO then
         .modify = 0
      else
         rc = -5
      endif
   endif
   return rc

; ---------------------------------------------------------------------------
;  Some PMWIN.H constants:
#define QW_PARENT       5

#define FID_CLIENT      0x8008

#define HWND_TOP        3

#define QWL_STYLE       (-2)

#define SWP_ZORDER      0x0004
#define SWP_ACTIVATE    0x0080
#define SWP_RESTORE     0x1000

#define WS_MINIMIZED    0x01000000

; ---------------------------------------------------------------------------
defc next_win, NextWin
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

; ---------------------------------------------------------------------------
defc CloseOtherWin
   buf     = leftstr( '', 128, \0)
   desktop = atol( 1)   -- (1 == HWND_DESKTOP)
   my_hwndx = gethwndc( EPMINFO_EDITFRAME)

   -- Get ClsName (NewEditWndClass) of current edit client window
   len = dynalink32( 'PMWIN',
                     '#805',  -- WinQueryClassName
                     gethwndc( EPMINFO_EDITCLIENT) ||
                     atol( 128) ||
                     address( buf), 2)
   ClsName = leftstr( buf, len)

   -- Examine desktop windows for client of same edit class
   henum = atol( dynalink32( 'PMWIN',
                             '#702',  -- WinBeginEnumWindows
                             desktop, 2))
   cnt = 0
   do while cnt < 250
      cnt = cnt + 1

      hwnd = dynalink32( 'PMWIN',
                         '#756',  -- WinGetNextWindow
                         henum, 2)

      if not hwnd then
         -- No more top-level windows
         leave
      elseif atol( hwnd) == my_hwndx then
         -- Just me, never mind
         iterate
      endif

      hwndClient = dynalink32( 'PMWIN',
                               '#899',  -- WinWindowFromId
                               atol( hwnd)   ||
                               atol( FID_CLIENT), 2)  -- get client

      len = dynalink32( 'PMWIN',
                        '#805',   -- WinQueryClassName
                        atol( hwndClient)    ||
                        atol( 128)           ||
                        address( buf), 2)

      -- Same class as me?
      if ClsName = leftstr( buf, len) then
;dprintf( 'ClsName = 'ClsName)
         -- Make minimized windows topmost first. This is useful if the
         -- 'Ask to quit on modified' dialog opens on posting a WM_CLOSE msg.
         Style = dynalink32( 'PMWIN',
                             '#843',        -- Win32QueryWindowULong
                             atol( hwnd)     ||
                             atol( QWL_STYLE), 2)
         if Style bitand WS_MINIMIZED then
            opts = SWP_ZORDER bitor SWP_ACTIVATE bitor SWP_RESTORE
            call dynalink32( 'PMWIN',
                             '#875',  -- Win32SetWindowPos
                             atol( hwnd)     ||
                             atol( HWND_TOP) ||
                             atol( 0)        ||
                             atol( 0)        ||
                             atol( 0)        ||
                             atol( 0)        ||
                             atol( opts))
         endif

         -- Close window
         call windowmessage( 0, hwnd,
                             41,  -- WM_CLOSE
                             0,
                             0)
      endif
   enddo
   call dynalink32( 'PMWIN',
                    '#737',  -- WinEndEnumWindows
                    henum, 2)

; ---------------------------------------------------------------------------
; Check for a modified file in ring. If not, restart current EPM window.
; Keep current directory.
defc Restart
   if arg(1) = '' then
      cmd = 'RestoreRing'
   else
      cmd = 'mc ;Restorering;AtPostStartup' arg(1)
   endif
   'RingCheckModify'
   'SaveRing'
   EpmArgs = "'"cmd"'"
compile if 0
   -- Doesn't work really reliable everytime (but even though useful):
   -- o  Sometimes EPM.EX is not reloaded.
   -- o  Sometimes EPM crashes on 'SaveRing' or on executing arg(1).
   'postme Open' EpmArgs
compile else
   -- Using external .cmd now:
   EpmExe = Get_Env( 'NEPMD_LOADEREXECUTABLE')
   'postme start /c /min epmlast' EpmExe EpmArgs
   'postme Close'
compile endif

; ---------------------------------------------------------------------------
; Abbreviation for use for menu items etc.
defc CheckChgPal
   parse arg args
   'CheckOnlyEpmWindow'
   'ChgPal' args

; ---------------------------------------------------------------------------
; Abbreviation for use for menu items etc.
defc ChgPal
   parse arg args
   'start /c /f epmchgpal.cmd' args

