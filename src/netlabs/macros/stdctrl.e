/****************************** Module Header *******************************
*
* Module Name: stdctrl.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdctrl.e,v 1.21 2004-06-03 22:37:17 aschn Exp $
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
- Merge NEPMD_USE_DIRECTORY_OF_CURRENT_FILE with
  USE_CURRENT_DIRECTORY_FOR_OPEN_DIALOG.
- Differ change to directory and directory for open dialog.
*/

/*
����������������������������������������������������������������������������ͻ
� What's it called: stdctrl.e                                                �
�                                                                            �
� What does it do : contains special PM procedures and commands that enable  �
�                   the following from the EPM editor:                       �
�                                                                            �
�                   listbox support - enables the dynamic creation of PM     �
�                                     list boxes.   A macro can pop up a     �
�                                     list of items and have a the users     �
�                                     selection returned to the macro.       �
�                                                                            �
�                   menu support    - enables the dynamic creation and       �
�                                     maintenance of named menus.            �
�                                     A macro can create several menus that  �
�                                     when shown and selected can execute    �
�                                     editor commands.                       �
�                                                                            �
�                   EPM - E.DLL communication :                              �
�                                     gives a EPM macro the ability to       �
�                                     converse with EPM.EXE controls.        �
�                                     For Example, popping EPM's commandline �
�                                     message dialog, etc.                   �
�                                                                            �
� Who and When    : Gennaro (Jerry) Cuomo                          3 -88     �
�                                                                            �
����������������������������������������������������������������������������ͼ
*/

/*
����������������������������������������������������������������������������Ŀ
� List Box Functions:                                                        �
�                                                                            �
�      listbox()                                                             �
�      listboxdemo()                                                         �
������������������������������������������������������������������������������
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
             is specified, the box will be placed under the cursor.
    param5 - (optional) column of text in which list box will go under.
             If this parameter is not specified or if a parameter of zero (0)
             is specified, the box will be placed under the cursor.
             (NOTE: If the row parameter is selected the column parameter
              must be selected as well.)
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

defproc listbox( title, listbuf)
   universal app_hini
   if leftstr( listbuf, 1) = \0 then
      liststuff = substr( listbuf, 2, 8)
      flags = substr( listbuf, 10)
   else
      listbuf=listbuf \0
      liststuff = atol(length(listbuf) - 1)    ||   /* length of list                */
                  address(listbuf)                  /* list                          */
      flags = ''
   endif
   title = title \0

   if arg(3) <> '' then                      /* button names were specified    */
      parse value arg(3) with delim 2 but1 (delim) but2 (delim) but3 (delim) but4 (delim) but5 (delim) but6 (delim) but7 (delim)
      nb=0
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

   if arg() > 3 then                       /* were row and column specified  */
      row = arg(4); col = arg(5)           /* row and col were passed        */
      if not row then                      /* zero means current cursor pos  */
         row = .cursory - 1
      endif
      if not col then
         col = .cursorx
      endif
   else
      col = .cursorx; row = .cursory - 1   /* default: current cursor pos    */
   endif

   if arg() > 5 then                       /* were height and width specified*/
      height = arg(6)                      /* height was passed   */
   else
      height = 0                           /* default: 0=use listbox default */
   endif

   if arg() > 6 then                       /* were height and width specified*/
      width = arg(7)                       /* width was passed   */
   else
      width = 0                            /* default: 0=use listbox default */
   endif

   x = .fontwidth * col                    /* convert row and column into...*/
   y = .windowy + screenheight() - .fontheight*(row + 1) - 4  /* (Add a fudge factor temporarily */

   if arg() > 7 then                       /* New way!                       */
      selectbuf = leftstr( arg(8), 255, \0)
   else
      selectbuf = copies( \0, 255)  -- Was 85     /* null terminate return buffer  */
   endif

   if flags='' then
      flags=3   -- bit 0=position below pts, bit 1=map to desktop
   endif

   if getpminfo(EPMINFO_EDITFRAME) then
      handle = EPMINFO_EDITFRAME
   else                   -- If frame handle is 0, use edit client instead.
      handle = EPMINFO_EDITCLIENT
   endif
   call dynalink32( ERES_DLL,               /* list box control in EDLL dyna */
                    'LISTBOX',                      /* function name                 */
                    gethwndc(handle)           ||   /* edit frame handle             */
                    atol(flags)                ||
                    atol(x)                    ||   /* coordinates                   */
                    atol(y)                    ||
                    atol(height)               ||
                    atol(width)                ||
                    atol(nb)                   ||
                    address(title)             ||   /* list box dialog title         */
                    address(but1)              ||   /* text to appear in buttons     */
                    address(but2)              ||   /*                               */
                    address(but3)              ||   /*                               */
                    address(but4)              ||   /*                               */
                    address(but5)              ||   /*                               */
                    address(but6)              ||   /*                               */
                    address(but7)              ||   /*                               */
                    liststuff                  ||
                    address(selectbuf)         ||   /* return string buffer          */
                    atol(app_hini))                 /* Handle to INI file            */

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
      return 'error'
   endif
   return substr( selectbuf, 2, EOS - 2)

/*********** Sample command that uses the old list box function *********
defc listdemo
   select = listbox( 'My List',
                     '/Bryan/Jason/Jerry Cuomo/Ralph/Larry/Richard/');
   if select=='' then
      sayerror 'Nothing Selected'
   else
      sayerror 'list box selection =<' select '>'
   endif
**/
/*********** Sample command that uses the new list box function *********
defc listdemo
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
**/

/*
����������������������������������������������������������������������������Ŀ
�                                                                            �
� What's it called: Listbox_Buffer_From_File                                 �
�                                                                            �
� What does it do : Inserts contents of a temp file into a buffer, ready for �
�                   a call to listbox().  Quits the source file.  Returns '' �
�                   if no problems.                                          �
�                                                                            �
�                   startfid - the starting fileid to which we return        �
�                   bufhndl  - (output) the buffer handle                    �
�                   noflines - (output) number of lines inserted in buffer   �
�                   usedsize - (output) amount of space used in the buffer   �
�                                                                            �
� Who and when    : Larry Margolis               1994/08/29                  �
�                                                                            �
������������������������������������������������������������������������������
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
����������������������������������������������������������������������������Ŀ
�                                                                            �
� What's it called: EntryBox                                                 �
�                                                                            �
� What does it do : Creates a System-Modal Dialog Box.  (A System-Modal box  �
�                   must be processed before the function can continue.)     �
�                   The dialog box contains a entry field and 2 push buttons.�
�                   (Up to 4 as of EPM 5.21 / 5.50.  See below.)             �
�                                                                            �
�                   hwnd    -  handle of owner window                        �
�                   title   -  question to appear on dialog title bar        �
�                   x,y     -  coordinates of lower left of entry box        �
�                              if (0,0) then centered to screen.             �
�                   cols    -  approximate number of cols in entry field     �
�                              in PM font characters                         �
�                   max     -  maximum number of chars                       �
�                   entry   -  entry field string returned                   �
�                                                                            �
� Who and when    : Gennaro (Jerry) Cuomo            4-89                    �
�                                                                            �
������������������������������������������������������������������������������

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
����������������������������������������������������������������������������ͻ
� EPM macro - EPM.EXE communication commands.                                �
�                                                                            �
�      togglefont      - toggle from large to small to large font            �
�      commandline     - show commandline dialog [initialize with text]      �
�      messagebox      - show message dialog box [optionally add to it]      �
�      opendlg         - show open dialog box                                �
�                                                                            �
����������������������������������������������������������������������������ͼ
*/

; Moved toggle defs to MENU.E

defc load_dt_bitmap
   universal bm_filename
   BmpFile = arg(1)
   if pos( ':\', BmpFile) & exist(BmpFile) then  -- if fully qualified and valid
      call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                          5499,            -- EPM_EDIT_SETDTBITMAPFROMFILE
                          put_in_buffer(BmpFile),
                          0)
   else
      bm_filename = ''
      sayerror 'Filename for background bitmap not valid (must be fully qualified and 31 chars max)'
   endif

defc drop_bitmap
   universal bm_filename
   parse arg x y bm_filename
   'load_dt_bitmap' bm_filename

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
����������������������������������������������������������������������������Ŀ
� what's it called: fontlist                                                 �
�                                                                            �
� what does it do : Display a listbox containing the possible font cell sizes�
�                   for the particular display type being used.              �
�                   The font dimensions are extracted from the fontlist str. �
�                                                                            �
� who and when    : Jerry C.  11/04/89                                       �
������������������������������������������������������������������������������
*/

defc fontlist
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5130,               -- EPM_POPFONTDLG
                      put_in_buffer(queryfont(.font)'.'trunc(.textcolor//16)'.'.textcolor%16),
                      0)

defc processfontrequest
   universal default_font
   universal statfont, msgfont
   universal appname, app_hini
   parse value arg(1) with fontname '.' fontsize '.' fontsel '.' setfont '.' markedonly '.' fg '.' bg
   -- sayerror 'Fontname=' fontname ' Fontsize=' fontsize 'Fontsel=' fontsel 'arg(1)="'arg(1)'"'
   if markedonly = 2 then  -- Statusline font
      statfont = fontsize'.'fontname'.'fontsel
      "setstatface" getpminfo(EPMINFO_EDITSTATUSHWND) fontname
      "setstatptsize" getpminfo(EPMINFO_EDITSTATUSHWND) fontsize
      if setfont then
         call setprofile( app_hini, appname, INI_STATUSFONT, statfont)
      endif
      return
   endif  -- markedonly = 2
   if markedonly = 3 then  -- Messageline font
      msgfont = fontsize'.'fontname'.'fontsel
      "setstatface" getpminfo(EPMINFO_EDITMSGHWND) fontname
      "setstatptsize" getpminfo(EPMINFO_EDITMSGHWND) fontsize
      if setfont then
         call setprofile( app_hini, appname, INI_MESSAGEFONT, msgfont)
      endif
      return
   endif  -- markedonly = 3

   fontid = registerfont(fontname, fontsize, fontsel)

   if setfont & not markedonly then
compile if WANT_APPLICATION_INI_FILE
      call setini( INI_FONT, fontname'.'fontsize'.'fontsel, 1)
compile endif
      getfileid startid
      display -1
      do i = 1 to filesinring(1)
         if .font = default_font then
            .font = fontid
         endif
         next_file
         getfileid curfile
         if curfile = startid then leave; endif
      enddo  -- Loop through all files in ring
      activatefile startid  -- Make sure we're back where we started (in case was .HIDDEN)
      display 1
      default_font = fontid
   endif  -- setfont & not markedonly

   if markedonly then
     -- insert font attribute within marked area only!

      themarktype = marktype()
      if not themarktype then             /* check if mark exists              */
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
               Insert_Attribute_Pair(16, fontid, i, i, fstcol, lstcol, mkfileid)
            endif
            if bg<>'' then
               Insert_Attribute_Pair(1, fg, i, i, fstcol, lstcol, mkfileid)
            endif
         enddo
      else
         if themarktype = 'LINE' then
            getline line, lstline, mkfileid
            lstcol = length(line)
         endif
         if addfont then
            Insert_Attribute_Pair(16, fontid, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
         if bg<>'' then
            Insert_Attribute_Pair(1, fg, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
      endif  -- themarktype = 'BLOCK'
      call attribute_on(8)  -- "Save attributes" flag
   else
      .font = fontid
   endif  -- markedonly

defc Process_Style
compile if WANT_APPLICATION_INI_FILE
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
compile else
   sayerror 'WANT_APPLICATION_INI_FILE = 0'
compile endif -- WANT_APPLICATION_INI_FILE

defc ChangeStyle
compile if WANT_APPLICATION_INI_FILE
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
compile else
   sayerror 'WANT_APPLICATION_INI_FILE = 0'
compile endif -- WANT_APPLICATION_INI_FILE

defc Delete_Style
compile if WANT_APPLICATION_INI_FILE
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
compile else
   sayerror 'WANT_APPLICATION_INI_FILE = 0'
compile endif -- WANT_APPLICATION_INI_FILE

defc monofont
   parse value queryfont(.font) with fontname '.' fontsize '.'
   if fontname <> 'Courier' & fontname <> 'System Monospaced' then
      if rightstr(fontsize,2) = 'BB' then  -- Bitmapped font
         parse value fontsize with 'DD' decipoints 'WW' width 'HH' height 'BB'
         if width & height then  -- It's fixed pitch
            return
         endif
      endif
      --.font = registerfont( 'System Monospaced', SYS_MONOSPACED_SIZE, 0)
      .font = registerfont( 'System VIO', 'DD120HH16WW8BB', 0)
   endif

/*
����������������������������������������������������������������������������Ŀ
� what's it called: Get_Array_Value(array_ID, array_index, value)            �
�                                                                            �
� what does it do : Looks up the index in the array, and if found, puts the  �
�                   value in VALUE.  The result returned for the function    �
�                   is the return code from the array lookup - 0 if          �
�                   successful.  If the index wasn't found, VALUE will       �
�                   contain the null string.                                 �
�                                                                            �
� who and when    : Larry M.   9/12/91                                       �
������������������������������������������������������������������������������
*/
defproc get_array_value( array_ID, array_index, var array_value)
   rc = 0
   array_value = ''
   display -2  -- switch off messages
   do_array 3, array_ID, array_index, array_value
   display 2
   return rc

defproc GetAVar( varname)
   universal EPM_utility_array_ID
   varname = lowcase( arg(1))
   varvalue = ''
   rc = get_array_value( EPM_utility_array_ID, varname, varvalue)
   return varvalue

defc getavar
   varname = strip( arg(1))
   sayerror varname' = 'GetAVar(varname)

defproc SetAVar( varname, varvalue)
   universal EPM_utility_array_ID
   varname = lowcase( varname)
   do_array 2, EPM_utility_array_ID, varname, varvalue
   return rc

defc setavar
   args = strip( arg(1))
   parse value args with varname varvalue
   rc = SetAVar( varname, varvalue)
   sayerror 'rc = 'rc

defproc AddAVar( varname, varvalue)
   oldvalue = GetAVar(varname)
   newvalue = oldvalue' 'varvalue
   newvalue = strip(newvalue)
   call SetAVar( varname, newvalue)
   return rc

defc addavar
   args = strip( arg(1))
   parse value args with varname varvalue
   rc = AppendAVar( varname, varvalue)
   sayerror 'rc = 'rc


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
����������������������������������������������������������������������������Ŀ
� what's it called: setfont                                                  �
�                                                                            �
� what does it do : Send change font message to editor.                      �
�                   Arguments are the font cell width and the font cell      �
�                   height.  example:  setfont(7, 15)                        �
�                                                                            �
�                                                                            �
� who and when    : Jerry C.  11/04/89                                       �
������������������������������������������������������������������������������
*/
defproc setfont( width, height)
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),   -- Post message to edit client
                       5381,               -- EPM_EDIT_CHANGEFONT
                       height,
                       width)


----------------------------------------------------------------------------
----  UNDO   JAC 11/90
----------------------------------------------------------------------------
; Moved defc processundo to UNDO.E
; Moved defc restoreundo to UNDO.E
; Moved defc renderundoinfo to UNDO.E
; Moved defc undodlg to UNDO.E

/*
����������������������������������������������������������������������������Ŀ
� what's it called: commandline     syntax:  commandline [optional text]     �
�                                                                            �
� what does it do : ask EPM.EXE to pop up its internal commandline control.  �
�                   This is done by posting a EPM_POPCMDLINE message to the  �
�                   EPM Book window.                                         �
�                   An optional string of text can be specified.  If a string�
�                   is specified then it will be inserted on the command line�
�                                                                            �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Jerry C.   2/27/89                                       �
������������������������������������������������������������������������������
*/
defc commandline  -- The application will free the buffer allocated by this macro !!!
   call windowmessage( 0, getpminfo(APP_HANDLE),
                       5124,               -- EPM_POPCMDLINE
                       0,
                       put_in_buffer(arg(1)))


/*
����������������������������������������������������������������������������Ŀ
� what's it called: PostCmdToEditWindow(cmd, winhandle [, mp2 [, buflg]] )   �
�                                                                            �
� what does it do : ask EPM.EXE to post a command to an edit window.  MP2 is �
�                   optional MP2 for the WinPostMsg.  Default is 1 (EPM      �
�                   should free the command buffer).  4 means process        �
�                   synchronously (not safe), and 8 means that EPM should do �
�                   a DosGetBuf to get the buffer.  Optional 4th argument is �
�                   passed to put_in_buffer (flag for DosAllocSeg; see       �
�                   put_in_buffer routine for details).                      �
�                                                                            �
� who and when    : Larry M.   7/23/90                                       �
������������������������������������������������������������������������������
*/
defproc PostCmdToEditWindow( cmd, winhndl)
   if arg(3)<>'' then
      mp2 = arg(3)
   else
      mp2 = 1
   endif
   call windowmessage( 0,  winhndl,
                       5377,               -- EPM_EDIT_COMMAND
                       put_in_buffer( cmd, arg(4)),
                       mp2)

/*
����������������������������������������������������������������������������Ŀ
� what's it called: PostMe          syntax:   PostMe command                 �
�                                                                            �
� what does it do : Ask EPM.EXE to post a command to the current edit window.�
�                   Useful if you want to send a command on an OPEN but      �
�                   don't want to tie up the main queue while the command is �
�                   executing.  By posting the command back to the window,   �
�                   it will execute from the EI queue, and not keep everyone �
�                   else waiting.                                            �
�                                                                            �
�                   Example of usage:                                        �
�                      "open 'PostMe long_running_command'"                  �
�                                                                            �
� who and when    : Larry M.   89/08/14                                      �
������������������������������������������������������������������������������
*/
defc PostMe
   call PostCmdToEditWindow( arg(1), getpminfo(EPMINFO_EDITCLIENT))

/*
����������������������������������������������������������������������������Ŀ
� what's it called: buffer_command    syntax:   buffer_command buff_address  �
�                                                                            �
� what does it do : Executes the command that's stored in the buffer, then   �
�                   frees the buffer.  Useful if you want to send a command  �
�                   to another window but don't want to worry about length   �
�                   or invalid characters.                                   �
�                                                                            �
�                   Example of usage:                                        �
�                      "open 'buffer_command" put_in_buffer(cmd_string)      �
�                                                                            �
� who and when    : Larry M.   91/09/03                                      �
������������������������������������������������������������������������������
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
����������������������������������������������������������������������������Ŀ
� what's it called: messagebox      syntax:   messagebox [optional string]   �
�                                                                            �
� what does it do : ask EPM.EXE to pop up its internal message box control.  �
�                   This is done by posting a EPM_POPMSGBOX  message to the  �
�                   EPM Book window.                                         �
�                   An optional string of text can be specified.  If a       �
�                   string is specified then it will be inserted into the    �
�                   message box.                                             �
�                                                                            �
�                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    �
�                    PACKAGE available on PCTOOLS.)                          �
�                                                                            �
� who and when    : Jerry C.   2/27/89                                       �
������������������������������������������������������������������������������
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
����������������������������������������������������������������������������Ŀ
� what's it called: processdragdrop                                          �
�                                                                            �
� what does it do : this defc is automatically called by the                 �
�                   toolkit when a drag drop event is successfully made      �
�                                                                            �
� what are the args:    cmdid =  1   - epm edit window                       �
�                                2   - File icon window (self)               �
�                                3   - epm book icon                         �
�                                4   - system editor                         �
�                                5   - File Manager folder                   �
�                                10  - Print manager                         �
�                                                                            �
�                       hwnd  =  handle of target window's frame             �
������������������������������������������������������������������������������
*/
; unused (with WPS anyway)
defc processdragdrop
   parse arg cmdid hwnd
call NepmdPmPrintf('PROCESSDRAGDROP: cmdid = 'cmdid', hwnd = 'hwnd)
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
����������������������������������������������������������������������������Ŀ
� what's it called: repaint_window                                           �
�                                                                            �
� what does it do : send a paint message to the editor.                      �
�                                                                            �
������������������������������������������������������������������������������
*/
defproc repaint_window()
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       35, 0, 0)   -- WM_PAINT

/*
����������������������������������������������������������������������������Ŀ
� what's it called: showwindow                                               �
�                                                                            �
� what does it do : allows the edit window to become invisible or visible    �
�                                                                            �
������������������������������������������������������������������������������
*/
defproc showwindow
   -- post the EPM_EDIT_SHOW message
   call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                       5385,
                       upcase(arg(1)) <> 'OFF', -- 0 if OFF, else 1
                       0)

; Moved defproc settitletext from STDCTRL.E to STATLINE.E to INFOLINE.E

/*
����������������������������������������������������������������������������Ŀ
� what's it called: WinMessageBox                                            �
�                                                                            �
� what does it do : This routine issues a PM WinMessageBox call, and returns �
�                   the result.                                              �
�                                                                            �
������������������������������������������������������������������������������
*/
defproc winmessagebox(caption, text)

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
      flags =           word('1 3  0 2  2', w)
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
   LoadVersionString(buff, modname, 'EPMMRI')
   insertline 'EPMMRI.DLL' buff '('modname')', .last+1
   */
   .modify = 0
   if browse_mode then call browse(1); endif

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


defc loadaccel
   universal activeaccel
   universal nepmd_hini
   activeaccel = 'defaccel'
                       -- Help key
;; buildacceltable activeaccel, 'helpmenu 4000', AF_VIRTUALKEY, VK_F1, 1000
   buildacceltable activeaccel, 'dokey s+F1', AF_VIRTUALKEY+AF_SHIFT, VK_F1, 1000

   call build_menu_accelerators(activeaccel)  -- Moved to menu-specific file

   buildacceltable activeaccel, 'Alt_enter 1', AF_VIRTUALKEY+AF_ALT,  VK_NEWLINE, 1080  -- Alt+Enter
   buildacceltable activeaccel, 'Alt_enter 2', AF_VIRTUALKEY+AF_ALT,    VK_ENTER, 1081  -- Alt+PadEnter
   buildacceltable activeaccel, 'Alt_enter 3', AF_VIRTUALKEY+AF_SHIFT,VK_NEWLINE, 1082  -- Shift+Enter
   buildacceltable activeaccel, 'Alt_enter 4', AF_VIRTUALKEY+AF_SHIFT,  VK_ENTER, 1083  -- Shift+PadEnter

   -- don't want Alt or AltGr switch to menu (PM-defined key F10 does the same)
;  buildacceltable activeaccel, 'beep 2000 50', AF_VIRTUALKEY+AF_LONEKEY, VK_ALT, 1020
;  buildacceltable activeaccel, 'beep 2000 50', AF_VIRTUALKEY+AF_LONEKEY, VK_ALTGRAF, 1021
   -- who wants beeps instead?
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockLeftAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      buildacceltable activeaccel, '', AF_VIRTUALKEY+AF_LONEKEY, VK_ALT, 1020
   endif
   KeyPath = '\NEPMD\User\Keys\AccelKeys\BlockRightAltKey'
   Blocked = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Blocked = 1 then
      buildacceltable activeaccel, '', AF_VIRTUALKEY+AF_LONEKEY, VK_ALTGRAF, 1021
   endif

   activateacceltable activeaccel

;compile if defined(BLOCK_ALT_KEY)
defc beep =
   a = arg(1)
   do while a <> ''
      parse value a with pitch duration a
      call beep(pitch, duration)
   enddo
;compile endif

defc alt_enter =
compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
   universal a_enterkey, a_padenterkey, s_enterkey, s_padenterkey
   call enter_common( substr( a_enterkey||a_padenterkey||s_enterkey||s_padenterkey, arg(1), 1))
compile else
   executekey enter
compile endif

defc dokey
   executekey resolve_key(arg(1))

defc keyin
   keyin arg(1)

defc maybe_reflow_ALL
   do i = 1 to .last
      if textline(i) <> '' then  -- Ask only if there's text in the file.
         if askyesno( REFLOW_ALL__MSG, 1) = YES_CHAR then
            'reflow_all'
         endif
         leave
      endif
   enddo

; Moved defc setstusline to INFOLINE.E

; Called with a string to set the messageline text to that string; with no argument
; to just set the messageline color.
defc setmessageline
   universal vMESSAGECOLOR
   if arg(1) then
      template = atoi(length(arg(1))) || arg(1)
      template_ptr = put_in_buffer(template)
   else
      template_ptr = 0
   endif
   call windowmessage( 1,  getpminfo(EPMINFO_EDITCLIENT),
                       5432,      -- EPM_FRAME_MESSAGELINE
                       template_ptr,
                       vMESSAGECOLOR)

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

defc processendscroll
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

defc processbeginscroll
   universal beginscroll_x, beginscroll_y;
   universal nepmd_hini
   KeyPath = '\NEPMD\User\Scroll\KeepCursorOnScreen'
   Enabled = NepmdQueryConfigValue( nepmd_hini, KeyPath)
   if Enabled = 1 then
      beginscroll_x = .cursorx;
      beginscroll_y = .cursory;
   endif
;compile endif  -- KEEP_CURSOR_ON_SCREEN

; unused
defc setpresparam
   universal statfont, msgfont
   universal vSTATUSCOLOR, vMESSAGECOLOR, vDESKTOPColor
   parse value arg(1) with whichctrl " hwnd="hwnd " x="x "y="y rest
   if (whichctrl == "STATFONTSIZENAME") or (whichctrl == "MSGFONTSIZENAME") then
      parse value rest with "string="psize"."facename"."attr
      -- psize is pointsize, facename is facename, attr is "Bold" etc
      "setstatface" hwnd facename
      "setstatptsize" hwnd psize
      if leftstr( whichctrl, 1) = 'S' then  -- "STATFONTSIZENAME"
         statfont = substr(rest,8)
      else                                  -- "MSGFONTSIZENAME"
         msgfont = substr(rest,8)
         sayerror MESSAGELINE_FONT__MSG
      endif
   elseif (whichctrl == "STATFGCOLOR") or (whichctrl == "MSGFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage(0,  hwnd,
                         4099,      -- STATWNDM_SETCOLOR
                         clrattr,
                         oldbgattr)
      if leftstr( whichctrl, 1) = 'M' then
         sayerror MESSAGELINE_FGCOLOR__MSG
         vMESSAGECOLOR = clrattr + 16 * oldbgattr
      else
         vSTATUSCOLOR = clrattr  + 16 * oldbgattr
      endif
   elseif (whichctrl == "STATBGCOLOR") or (whichctrl == "MSGBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage( 0,  hwnd,
                          4099,      -- STATWNDM_SETCOLOR
                          oldfgattr,
                          clrattr)
      if leftstr( whichctrl, 1) = 'M' then
         sayerror MESSAGELINE_BGCOLOR__MSG
         vMESSAGECOLOR = clrattr * 16 + oldfgattr
      else
         vSTATUSCOLOR = clrattr  * 16 + oldfgattr
      endif
   elseif (whichctrl == "EDITBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      map_point 5, x, y, off, comment;  -- map screen to line
      if x < 1 | x > .last then
         vDESKTOPColor = clrattr
         call windowmessage( 0, getpminfo(EPMINFO_EDITCLIENT),
                             5497,
                             clrattr,
                             0)
      else
         .textcolor = (.textcolor // 16) + 16 * clrattr;
      endif
   elseif (whichctrl == "EDITFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      .textcolor = .textcolor - (.textcolor // 16) + clrattr;
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
      .font = registerfont( facename ,psize, fontsel)
   else
      sayerror UNKNOWN_PRESPARAM__MSG  whichctrl
      return;
   endif
;   sayerror "set presparm with" hwnd " as the window" arg(1);

; unused
defc setstatface
   parse value arg(1) with hwnd face
   return windowmessage( 0,  hwnd /*getpminfo(EPMINFO_EDITFRAME)*/,   -- Post message to edit client
                         4104,        -- STATWNDM_PREFFONTFACE
                         put_in_buffer(face),
                         1);  -- COMMAND_FREESEL

; unused
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


defproc Thunk(pointer)
   return atol_swap( dynalink32( E_DLL,
                                 'FlatToSel',
                                 pointer, 2))

; EPM_EA.E in now included in EPM.E

defc echoback
   parse arg postorsend hwnd messageid mp1 mp2 .
   call windowmessage( postorsend,
                       hwnd,
                       messageid,
                       mp1,
                       mp2)

; Moved all toolbar definitions to TOOLBAR.E

defc toggle_parse
   universal EPM_utility_array_ID
   parse arg parseon kwfilename
   if parseon & .levelofattributesupport//2 = 0  then  -- the first bit of .levelofattributesupport is for color attributes
      call attribute_on(1) -- toggles color attributes mode
   endif
   if kwfilename = '' then
      kwfilename = 'epmkwds.c'
   endif
   if parseon then
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
      do_array 2, EPM_utility_array_ID, 'kwfile.'fid, kwfilename
   endif

   call windowmessage( 0,  getpminfo(EPMINFO_EDITFRAME),
                       5502,               -- EPM_EDIT_TOGGLEPARSE
                       parseon,
                       put_in_buffer(fid kwfilename))

compile if 0
defc qparse =
   c = windowmessage( 1,  getpminfo(EPMINFO_EDITFRAME),
                      5505,               -- EPM_EDIT_KW_QUERYPARSE
                      0,
                      0)
   sayerror 'Keyword parsing is' word( OFF__MSG ON__MSG, 2 - (not c))  -- Use as boolean
compile endif

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

defc dynafree =
   res = dynafree(arg(1))
   if res then
      sayerror ERROR__MSG res
   endif
