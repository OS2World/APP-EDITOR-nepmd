/****************************** Module Header *******************************
*
* Module Name: stdctrl.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdctrl.e,v 1.15 2004-01-13 17:28:01 aschn Exp $
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

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ The following are constant values that are to be used as parameters to     ³
³ the getpminfo internal function or as control id's for control toggle.     ³
³                                                                            ³
³ HAB           0  PARENTFRAME     4  EDITORMSGAREA      8   EDITVIOPS    12 ³
³ OWNERCLIENT   1  EDITCLIENT      5  EDITORVSCROLL      9   EDITTITLEBAR 13 ³
³ OWNERFRAME    2  EDITFRAME       6  EDITORHSCROLL      10  EDITCURSOR   14 ³
³ PARENTCLIENT  3  EDITSTATUSAREA  7  EDITORINTERPRETER  11  PARTIALTEXT  15 ³
³ EDITEXSEARCH  16 EDITMENUHWND    17 HDC                18  HINI         19 ³
³ RINGICONS     20                    FILEICONS          22  EXTRAWNDPOS  23 ³
³ CursorBounce  24 CUA_marking     25 Arrows_Internal    26                  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

const
compile if not defined(NEPMD_SPECIAL_STATUSLINE)
   NEPMD_SPECIAL_STATUSLINE = 0
compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ List Box Functions:                                                        ³
³                                                                            ³
³      listbox()                                                             ³
³      listboxdemo()                                                         ³
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

defproc listbox(title, listbuf)
   universal app_hini
   if leftstr(listbuf,1)=\0 then
      liststuff = substr(listbuf,2,8)
      flags = substr(listbuf,10)
   else
      listbuf=listbuf \0
      liststuff = atol(length(listbuf)-1)    ||   /* length of list                */
                  address(listbuf)                /* list                          */
      flags = ''
   endif
   title  = title \0

   if arg(3)<>'' then                      /* button names were specified    */
      parse value arg(3) with delim 2 but1 (delim) but2 (delim) but3 (delim) but4 (delim) but5 (delim) but6 (delim) but7 (delim)
      nb=0
      if but1<>'' then but1=but1\0; nb=nb+1; else sayerror 'LISTBOX:' BUTTON_ERROR__MSG; return 0; endif
      if but2<>'' then but2=but2\0; nb=nb+1; else but2=\0; endif
      if but3<>'' then but3=but3\0; nb=nb+1; else but3=\0; endif
      if but4<>'' then but4=but4\0; nb=nb+1; else but4=\0; endif
      if but5<>'' then but5=but5\0; nb=nb+1; else but5=\0; endif
      if but6<>'' then but6=but6\0; nb=nb+1; else but6=\0; endif
      if but7<>'' then but7=but7\0; nb=nb+1; else but7=\0; endif
   else
      but1=ENTER__MSG\0; but2=CANCEL__MSG\0; but3=\0; but4=\0; but5=\0 ; but6=\0; but7=\0 -- default buttons
      nb=2
   endif

   if arg()>3 then                         /* were row and column specified  */
      row = arg(4); col = arg(5)            /* row and col were passed        */
      if not row then row=.cursory-1 endif  /* zero means current cursor pos  */
      if not col then col=.cursorx endif
   else
      col=.cursorx; row=.cursory-1          /* default: current cursor pos    */
   endif
   if arg()>5 then                         /* were height and width specified*/
      height = arg(6)                      /* height was passed   */
   else
      height = 0                           /* default: 0=use listbox default */
   endif
   if arg()>6 then                         /* were height and width specified*/
      width = arg(7)                       /* width was passed   */
   else
      width = 0                            /* default: 0=use listbox default */
   endif

   x = .fontwidth * col                    /* convert row and column into...*/
   y = .windowy+screenheight()-.fontheight*(row+1)-4  /* (Add a fudge factor temporarily */

   if arg()>7 then                         /* New way!                       */
      selectbuf = leftstr(arg(8), 255, \0)
   else
      selectbuf = copies(\0,255)  -- Was 85     /* null terminate return buffer  */
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
                   'LISTBOX',                    /* function name                 */
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

   button = asc(leftstr(selectbuf,1))
   if arg()>7 then return selectbuf; endif  -- New way
   if button=0 | button=2 then return ''; endif  -- Old way...
   if button<>1 then return button; endif
   EOS = pos(\0,selectbuf,2)        -- CHR(0) signifies End Of String
   if not EOS then return 'error'; endif
   return substr(selectbuf,2,EOS-2)

/*********** Sample command that uses the old list box function *********
defc listdemo
   select = listbox('My List','/Bryan/Jason/Jerry Cuomo/Ralph/Larry/Richard/');
   if select=='' then
      sayerror 'Nothing Selected'
   else
      sayerror 'list box selection =<' select '>'
   endif
**/
/*********** Sample command that uses the new list box function *********
defc listdemo
   sayerror 'Selected entry 3; default button 2; help panel 9300.'
   selectbuf = listbox('My List','/One/Two/Three',
      '/Go to/Delete/Cancel/Help',0,0,0,0,
      gethwnd(APP_HANDLE) || atoi(3) || atoi(2) || atoi(9300) ||
      'Prompt text'\0);
   button = asc(leftstr(selectbuf,1))
   if button=0 then
      sayerror 'Nothing Selected'
   else
      EOS = pos(\0,selectbuf,2)        -- CHR(0) signifies End Of String
      select= substr(selectbuf,2,EOS-2)
      sayerror 'Button' button 'was pressed; string =' select
   endif
**/

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
defproc listbox_buffer_from_file(startfid, var bufhndl, var noflines, var usedsize)
   buflen = filesize() + .last + 1
   if buflen > MAXBUFSIZE then
      sayerror LIST_TOO_BIG__MSG '(' buflen '>' MAXBUFSIZE ')'
      buflen = MAXBUFSIZE
   endif
   bufhndl = buffer(CREATEBUF, 'LISTBOX', buflen, 1 )  -- create a private buffer
   if not bufhndl then sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC; return rc; endif
   noflines = buffer(PUTBUF, bufhndl, 1, 0, APPENDCR)
   buf_rc = rc
   .modify = 0
   'xcom quit'
   activatefile startfid
   if not noflines then sayerror 'PUTBUF' ERROR_NUMBER__MSG buf_RC; return buf_RC; endif
   usedsize = buffer(USEDSIZEBUF,bufhndl)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³                                                                            ³
³ What's it called: EntryBox                                                 ³
³                                                                            ³
³ What does it do : Creates a System-Modal Dialog Box.  (A System-Modal box  ³
³                   must be processed before the function can continue.)     ³
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
   pw = entrybox('Enter Password',
                 '',  -- Buttons
                 '',  -- Entry text
                 '',  -- Cols
                 '',  -- Max len
                 '',  -- Return buffer
                 140) -- ES_UNREADABLE + ES_AUTOSCROLL + ES_MARGIN
   Sayerror 'Password = "'pw'"'
*/

-- entrybox title [,buttons][,entrytext][,cols][,maxchars][,param6]
defproc entrybox(title)
   columns = arg(4)
;  if columns=0 then columns=length(title); endif  -- Now handled (better) internally

   title = title \0
   nb = 2                                  -- default number of buttons
   if arg(2)<>'' then                      /* button names were specified    */
      parse value arg(2) with delim 2 but1 (delim) but2 (delim) but3 (delim) but4 (delim)
;;    sayerror 'but1=<'but1'> but2=<'but2'> but3=<'but3'> but4=<'but4'>'
      if but1<>'' then but1=but1 \0;  else sayerror 'ENTRYBOX:' BUTTON_ERROR__MSG; return 0; endif
      if but2<>'' then but2=but2 \0;  else but2=''\0; endif
      if but3<>'' then but3=but3 \0;nb=3;  else but3=''\0; endif
      if but4<>'' then but4=but4 \0;nb=4;  else but4=''\0; endif
   else
      but1=\0; but2=\0; but3=\0; but4=\0
   endif

   if arg()>2 then entrytext=arg(3) \0;     else  entrytext = \0;  endif
;; if arg()>3 then columns  =max(arg(4),1); else  columns   = 30;  endif
   if columns<0 then columns = 30; endif
   if arg()>4 then maxchars =max(arg(5),1); else  maxchars  = 254; endif

   /* null terminate return buffer  */
   if arg()>5 then
      selectbuf = leftstr(arg(6), MAXCOL, \0)
   else
      selectbuf = copies(\0, MAXCOL)
   endif
   if arg()>6 then
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
   button = asc(leftstr(selectbuf,1))
   if button=0 | button=2 then  -- Old way...
      return ''
   endif
   if button<>1 then
      return button
   endif
   EOS = pos(\0,selectbuf,2)        -- CHR(0) signifies End Of String
   if not EOS then
      return 'error'
   endif
   return substr(selectbuf,2,EOS-2)

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

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: togglecontrol                                            ³
³                                                                            ³
³ what does it do : The command either toggles a EPM control window on or off³
³                   or forces a EPM control window on or off.                ³
³                   arg1   = EPM control window handle ID.  Control window   ³
³                            ids given above.  The following windows handles ³
³                            are currently supported.                        ³
³                            EDITSTATUS, EDITVSCROLL, EDITHSCROLL, and       ³
³                            EDITMSGLINE.                                    ³
³                   arg2   [optional] = force option.                        ³
³                            a value of 0, forces control window off         ³
³                            a value of 1, forces control window on          ³
³                           IF this argument is not specified the window     ³
³                           in question is toggled.                          ³
³                                                                            ³
³                   This command is possible because of the EPM_EDIT_CONTROL ³
³                   EPM_EDIT_CONTROLSTATUS message.                          ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc togglecontrol
compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
compile endif
   forceon=0
   parse arg controlid fon
   if fon<>'' then
      forceon=(fon+1)*65536
compile if (WANT_NODISMISS_MENUS | WANT_DYNAMIC_PROMPTS) & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   else
      fon = not querycontrol(controlid)  -- Query now, since toggling is asynch.
compile endif  -- WANT_NODISMISS_MENUS
   endif

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5388,               -- EPM_EDIT_CONTROLTOGGLE
                      controlid + forceon,
                      0)
compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   p = wordpos(controlid, '  7   8  10 20  22  23')
   if p then       -->     === === === === === ===
      menuid =       word('413 414 415 417 416 421', p)
      SetMenuAttribute( menuid, 8192, not fon)
   endif
compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS

defc toggleframe
 compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
 compile endif
   forceon=0
   parse arg controlid fon
   if fon<>'' then
      forceon=(fon+1)*65536
compile if (WANT_NODISMISS_MENUS | WANT_DYNAMIC_PROMPTS) & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   else
      fon = not queryframecontrol(controlid)  -- Query now, since toggling is asynch.
compile endif  -- WANT_NODISMISS_MENUS
   endif

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5907,               -- EFRAMEM_TOGGLECONTROL
                      controlid + forceon,
                      0)
 compile if WANT_DYNAMIC_PROMPTS & not ALLOW_PROMPTING_AT_TOP
   if controlid=32 then
      if fon then  -- 1=top; 0=bottom.  If now top, turn off.
         menu_prompt = 0
  compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
         SetMenuAttribute( 422, 8192, 1)
  compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS
      endif
   endif
 compile endif
 compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   p = wordpos(controlid, '  1   2   4  16 32')
   if p then       -->     === === === === ===
      menuid =       word('413 414 417 415 421', p)
      SetMenuAttribute( menuid, 8192, not fon)
   endif
 compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS

defproc queryframecontrol(controlid)
   return windowmessage(1,  getpminfo(EPMINFO_EDITFRAME),   -- Send message to edit client
                        5907,               -- EFRAMEM_TOGGLECONTROL
                        controlid,
                        1)

compile if WANT_DYNAMIC_PROMPTS
defc toggleprompt
   universal menu_prompt
   menu_prompt = not menu_prompt
 compile if not ALLOW_PROMPTING_AT_TOP
   if menu_prompt then
      'toggleframe 32 0'      -- Force Extra window to bottom.
   endif
 compile endif  -- not ALLOW_PROMPTING_AT_TOP
 compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 422, 8192, not menu_prompt)
 compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS
compile endif

defc setscrolls
   'toggleframe 8'
   'toggleframe 16'

defc toggle_bitmap
   universal bitmap_present, bm_filename
   bitmap_present = not bitmap_present
;; bm_filename = ''
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
                      5498 - (44*bitmap_present), 0, 0)
compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 437, 8192, not bitmap_present)
compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS

defc load_dt_bitmap
   universal bm_filename
   BmpFile = arg(1)
   if pos( ':\', BmpFile) & exist(BmpFile) then  -- if fully qualified and valid
      call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
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
   return windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),   -- Send message to edit client
                        5388,               -- EPM_EDIT_CONTROLTOGGLE
                        controlid,
                        1)

defc cursoroff=call cursoroff()    -- Turn cursor off

defproc cursoroff           -- Turn cursor off
    'togglecontrol 14 0'

; Trim window so it's an exact multiple of the font size.
defc trim=call windowsize1(.windowheight,.windowwidth,0,0,1)

defc windowsize1
   parse arg row col x y flag junk
   if x='' | junk<>'' then
      sayerror -263  -- Invalid argument
   else
      call windowsize1(row,col,x,y,flag)
   endif

defproc windowsize1(row,col,x,y)

   if upcase(leftstr(row,1))='P' then  -- Already in pels
      cy = substr(row,2)
   else
      cy = .fontheight *  row          -- convert row into y coordinate in pels
   endif
   if upcase(leftstr(col,1))='P' then  -- Already in pels
      cx = substr(col,2)
   else
      cx = .fontwidth * col            -- convert col into x coordinate in pels
   endif

   if arg(5)<>'' then opts=arg(5); else opts=3; endif  -- Default = SWP_SIZE (1) + SWP_MOVE (2)

   if opts // 2 then                        -- Don't bother calculating unless SWP_SIZE on
      swp1 = copies(\0, 36)
      swp2 = swp1
      call dynalink32('PMWIN',
                      '#837',
                      gethwndc(EPMINFO_EDITCLIENT)  ||
                      address(swp1) )
      call dynalink32('PMWIN',
                      '#837',
                      gethwndc(EPMINFO_EDITFRAME)   ||
                      address(swp2) )
      cx = cx + ltoa(substr(swp2,9,4),10) - ltoa(substr(swp1,9,4),10)
      cy = cy + ltoa(substr(swp2,5,4),10) - ltoa(substr(swp1,5,4),10)
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

   fontid=registerfont(fontname, fontsize, fontsel)

   if setfont & not markedonly then
compile if WANT_APPLICATION_INI_FILE
      call setini( INI_FONT, fontname'.'fontsize'.'fontsel, 1)
compile endif
      getfileid startid
      display -1
      do i=1 to filesinring(1)
         if .font=default_font then
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
      if themarktype='BLOCK' then
         do i = fstline to lstline
            if addfont then
               Insert_Attribute_Pair(16, fontid, i, i, fstcol, lstcol, mkfileid)
            endif
            if bg<>'' then
               Insert_Attribute_Pair(1, fg, i, i, fstcol, lstcol, mkfileid)
            endif
         enddo
      else
         if themarktype='LINE' then
            getline line, lstline, mkfileid
            lstcol=length(line)
         endif
         if addfont then
            Insert_Attribute_Pair(16, fontid, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
         if bg<>'' then
            Insert_Attribute_Pair(1, fg, fstline, lstline, fstcol, lstcol, mkfileid)
         endif
      endif  -- themarktype='BLOCK'
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
   if stylestuff='' then return; endif  -- Shouldn't happen
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
      if marktype()='BLOCK' then
         do i = fstline to lstline
            Insert_Attribute_Pair(1, fg, i, i, fstcol, lstcol, mkfileid)
         enddo
      else
         if marktype()='LINE' then
            getline line, lstline, mkfileid
            lstcol=length(line)
         endif
         Insert_Attribute_Pair(1, fg, fstline, lstline, fstcol, lstcol, mkfileid)
      endif
      call attribute_on(1)  -- Colors flag
   endif
   if fontsel<>'' then
      call attribute_on(4)  -- Mixed fonts flag
      fontid=registerfont(fontname, fontsize, fontsel)
      if marktype()='BLOCK' then
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
   if stylestuff='' then return; endif  -- Shouldn't happen
   parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
   getfileid startid
   fontid=registerfont(fontname, fontsize, fontsel)
   fg = bg*16 + fg
   do i=1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      if .levelofattributesupport bitand 8 then  -- Is attribute 8 on?
                                                                 -- "Save attributes" flag
         line=0; col=1; offst=0
         do forever
            class = 14  -- STYLE_CLASS
            attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
            if class=0 then leave; endif  -- not found
            query_attribute class, val, IsPush, offst, col, line
            if val=styleindex then  -- If it's this style, then...
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class=16 & val<>fontid then  -- Replace the font ID (if changed)
                  insert_attribute class, fontid, IsPush, offst, col, line
                  attribute_action 16, class, offst, col, line -- 16=DELETE_ATTR_SUBOP
               endif
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class=1 & val<>fg then  -- Replace the color attribute (if changed)
                  insert_attribute class, fg, IsPush, offst, col, line
                  attribute_action 16, class, offst, col, line -- 16=DELETE_ATTR_SUBOP
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
   if stylestuff='' then return; endif  -- Shouldn't happen
   if get_array_value(EPM_utility_array_ID, 'sn.'stylename, styleindex) then
      return  -- If not known, then we're not using it, so nothing to do.
   endif
;  parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
   getfileid startid
;  fontid=registerfont(fontname, fontsize, fontsel)
;  fg = bg*16 + fg
   do i=1 to filesinring(1)  -- Provide an upper limit; prevent looping forever
      if .levelofattributesupport bitand 8 then  -- Is attribute 8 on?
                   -- "Save attributes" flag --> using styles in this file
         oldmod = .modify
         line=0; col=1; offst=0
         do forever
            class = 14  -- STYLE_CLASS
            attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
            if class=0 then  -- not found
               if .modify <> oldmod then  -- We've deleted at least one...
                   call delete_ea('EPM.STYLES')
                   call delete_ea('EPM.ATTRIBUTES')
                  .modify = oldmod + 1  -- ...count as a single change.
               endif
               leave
            endif
            query_attribute class, val, IsPush, offst, col, line
            if val=styleindex then  -- If it's this style, then...
               attribute_action 16, class, offst, col, line -- 16=DELETE_ATTR_SUBOP
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class=16 then  -- Delete the font ID
                  attribute_action 16, class, offst, col, line -- 16=DELETE_ATTR_SUBOP
               endif
               offst = offst+1
               query_attribute class, val, IsPush, offst, col, line
               if class=1 then  -- Delete the color attribute
                  attribute_action 16, class, offst, col, line -- 16=DELETE_ATTR_SUBOP
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
   if fontname<>'Courier' & fontname<>'System Monospaced' then
      if rightstr(fontsize,2)='BB' then  -- Bitmapped font
         parse value fontsize with 'DD' decipoints 'WW' width 'HH' height 'BB'
         if width & height then  -- It's fixed pitch
            return
         endif
      endif
      .font = registerfont('System Monospaced', SYS_MONOSPACED_SIZE, 0)
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: Get_Array_Value(array_ID, array_index, value)            ³
³                                                                            ³
³ what does it do : Looks up the index in the array, and if found, puts the  ³
³                   value in VALUE.  The result returned for the function    ³
³                   is the return code from the array lookup - 0 if          ³
³                   successful.  If the index wasn't found, VALUE will       ³
³                   contain the null string.                                 ³
³                                                                            ³
³ who and when    : Larry M.   9/12/91                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc get_array_value(array_ID, array_index, var array_value)
   rc = 0
   array_value = ''
   display -2
   do_array 3, array_ID, array_index, array_value
   display 2
   return rc

defproc Insert_Attribute_Pair(attribute, val, fstline, lstline, fstcol, lstcol, fileid)
   universal EPM_utility_array_ID
;sayerror 'Insert_Attribute_Pair('attribute',' val',' fstline',' lstline',' fstcol',' lstcol',' fileid')'
   class = attribute
   offst1 = -255
   col = fstcol
   line = fstline
   pairoffst = -255
   attribute_action 1, class, offst1, col, line, fileid -- 1=FIND NEXT ATTR
;sayerror 'attribute_action FIND NEXT ATTR,' class',' offst1',' col',' line',' fileid -- 1=FIND NEXT ATTR
   if class & col = fstcol & line = fstline  then  -- Found one!
      offst2 = offst1
      attribute_action 3, class, offst2, col, line, fileid -- 3=FIND MATCH ATTR
;sayerror 'attribute_action FIND MATCH ATTR,' class',' offst2',' col',' line',' fileid -- 1=FIND NEXT ATTR
      if class then
         lc1 = lstcol + 1
         if line=lstline & col=lc1 then  -- beginning and end match, so replace the old attributes
compile if defined(COMPILING_FOR_ULTIMAIL)
            replace_it = 1
            if class=14 then  -- STYLE_CLASS
               query_attribute class, val2, IsPush, offst1, fstcol, fstline, fileid
               --do_array 3, EPM_utility_array_ID, 'si.'val, stylename -- Get the style name
               rc = get_array_value( EPM_utility_array_ID, 'si.'val, stylename )  -- Get the style name
               is_color1 = wordpos(stylename, "black blue red pink green cyan yellow white darkgray darkblue darkred darkpink darkgreen darkcyan brown palegray")
               --do_array 3, EPM_utility_array_ID, 'si.'val2, stylename -- "
               rc = get_array_value( EPM_utility_array_ID, 'si.'val2, stylename )  -- "
               is_color2 = wordpos(stylename, "black blue red pink green cyan yellow white darkgray darkblue darkred darkpink darkgreen darkcyan brown palegray")
               if (is_color1 & not is_color2) | (is_color2 & not is_color1) then
                  replace_it = 0
               endif
            endif
            if replace_it then
compile endif
               attribute_action 16, class, offst1, fstcol, fstline, fileid -- 16=DELETE ATTR
;sayerror 'attribute_action DELETE ATTR,' class',' offst1',' fstcol',' fstline',' fileid -- 1=FIND NEXT ATTR
               attribute_action 16, class, offst2, lc1, lstline, fileid -- 16=DELETE ATTR
;sayerror 'attribute_action DELETE ATTR,' class',' offst2',' lc1',' lstline',' fileid -- 1=FIND NEXT ATTR
               pairoffst = offst1 + 1
               if not pairoffst then
                  lstcol = lc1
               endif
compile if defined(COMPILING_FOR_ULTIMAIL)
            endif
compile endif
         elseif line>lstline | (line=lstline & col>lstcol) then  -- old range larger then new
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
         attribute_action 3, class, offst2, col2, line2, fileid -- 3=FIND MATCH ATTR
;sayerror 'attribute_action FIND MATCH ATTR,' class',' offst2',' col2',' line2',' fileid -- 1=FIND NEXT ATTR
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
         attribute_action 1, class, offst1, col, line, fileid -- 1=FIND NEXT ATTR
;sayerror 'attribute_action FIND NEXT ATTR,' class',' offst1',' col',' line',' fileid -- 1=FIND NEXT ATTR
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
defproc setfont(width, height)
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),   -- Post message to edit client
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
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5124,               -- EPM_POPCMDLINE
                      0,
                      put_in_buffer(arg(1)) )


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
defproc PostCmdToEditWindow(cmd,winhndl)
   if arg(3)<>'' then mp2=arg(3); else mp2=1; endif
   call windowmessage(0,  winhndl,
                      5377,               -- EPM_EDIT_COMMAND
                      put_in_buffer(cmd,arg(4)),
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
   call PostCmdToEditWindow(arg(1),getpminfo(EPMINFO_EDITCLIENT))

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
   call dynalink32('DOSCALLS',          -- Dynamic link library name
            '#304',                    -- Dos32FreeMem
            buffer_long)

defc buff_link
   parse arg buff .
   if not buff then return; endif
   rc = dynalink32('DOSCALLS',
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
³                   An optional string of text can be specified.  If a string³
³                   is specified then it will be inserted into the message bx³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc messagebox  -- The application will free the buffer allocated by this macro !!!
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5125,               -- EPM_POPMSGBOX
                      0,
                      put_in_buffer(arg(1)) )

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: opendlg         syntax:   opendlg [EDIT  |  GET]         ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal message box control.  ³
³                   This is done by posting a EPM_POPOPENDLG message to the  ³
³                   EPM Book window.                                         ³
³                   If a file    is selected, by default, it will be present-³
³                   ed in a new window.  If the 'EDIT' option is specified   ³
³                   the file specified will be opened in the active edit     ³
³                   window.                                                  ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   2/27/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc opendlg
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if WPS_SUPPORT
   universal wpshell_handle
compile endif
compile if USE_CURRENT_DIRECTORY_FOR_OPEN_DIALOG
   universal app_hini
   call setprofile( app_hini, 'ERESDLGS', 'LASTFILESELECTED', '')
compile endif
compile if WPS_SUPPORT
   if wpshell_handle & not arg(1) then
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5160,                   -- EPM_WPS_OPENFILEDLG
                         getpminfo(EPMINFO_EDITCLIENT),
                         0)

   else
compile endif

   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5126,               -- EPM_POPOPENDLG
compile if RING_OPTIONAL
                      ring_enabled,
compile else
                      1,
compile endif
                      pos(upcase(strip(arg(1))),'   EDITGET')%4 * 65536)  -- OPEN=0; EDIT=1; GET=2
compile if WPS_SUPPORT
   endif
compile endif

; Moved defc searchdlg to LOCATE.E

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: configdlg       syntax:   configdlg                      ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its internal configuration dialog. ³
³                   This is done by posting a EPM_POPCONFIGDLG message to the³
³                   EPM Book window.                                         ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Jerry C.   7/20/89                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
compile if WANT_APPLICATION_INI_FILE
defc configdlg
 compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
 compile endif
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5129+(18*(arg(1)='SYS')),  -- EPM_POPCONFIGDLG / EPM_POPSYSCONFIGDLG
 compile if ENHANCED_ENTER_KEYS
                      0,           -- Omit no pages
 compile else
                      32,           -- Bit 6 on means omit page 6
 compile endif
 compile if SPELL_SUPPORT
  compile if CHECK_FOR_LEXAM
                      not LEXAM_is_available)
  compile else
                      0)
  compile endif
 compile else
                      1)           -- Bit 0 on means omit spell stuff from page 4
 compile endif  -- SPELL_SUPPORT


/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called:  renderconfig                                            ³
³           syntax:  renderconfig reply_window_hwnd page SEND_DEFAULT        ³
³                                                                            ³
³ what does it do : Upon the request of a external window, sent configuration³
³                   information in the form of special WM_COMMAND messages   ³
³                   to the window handle specified in parameter one.         ³
³                                                                            ³
³                   The second parameter is the page number of the config    ³
³                   dialog which is requesting the information; this tells   ³
³                   us the range of information desired.  (Each page only    ³
³                   gets sent the information for that page, when the page   ³
³                   is activated.  Better performance than sending every-    ³
³                   thing when the dialog is initialized.)                   ³
³                                                                            ³
³                   The third parameter is a flag, as follows:               ³
³                      0 -> send value from .ini file                        ³
³                      1 -> send default value (ignoring .ini)               ³
³                      2 -> send current value (5.60 & above, only)          ³
³                                                                            ³
³                   The fuction is used by EPM to fill in the EPM CONFIG     ³
³                   dialog box.                                              ³
³                                                                            ³
³ who and when    : Jerry C. & LAM  7/20/89                                  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc renderconfig
   universal ADDENDA_FILENAME
   universal DICTIONARY_FILENAME
   universal vAUTOSAVE_PATH, vTEMP_PATH
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal appname, app_hini
 compile if ENHANCED_ENTER_KEYS
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
 compile endif
 compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
 compile endif
   universal default_font
   universal vMESSAGECOLOR, vSTATUSCOLOR
   universal statfont, msgfont
   universal bm_filename
   universal bitmap_present
   universal toolbar_loaded
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
 compile endif
 compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if TOGGLE_TAB
   universal TAB_KEY
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
 compile endif
 compile if WPS_SUPPORT
   universal wpshell_handle
 compile endif
   universal vEPM_POINTER, cursordimensions

   parse arg hndle page send_default .

   -- Notebook control ----------------------------------------------
 compile if WPS_SUPPORT
   if wpshell_handle then
      help_panel = 5350 + page
   else
 compile endif
      help_panel = 5300 + page
 compile if WPS_SUPPORT
    endif
 compile endif

   if page=1 then  --------------------- Page 1 is tabs -------------
      if send_default=2 then tempstr=.tabs
      else tempstr = checkini(send_default, INI_TABS, DEFAULT_TABS)
      endif
      call send_config_data(hndle, tempstr, 3, help_panel)
 compile if TOGGLE_TAB
      tempstr = 0
      if not send_default then    -- 0: Use values from .ini file
         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if words(newcmd) >= 14 then
            tempstr = word(newcmd, 14)
         endif
      elseif send_default=2 then  -- 2: Use current values
         tempstr = TAB_KEY
      endif
      call send_config_data(hndle, tempstr, 19, help_panel)
 compile endif

   elseif page=2 then  ----------------- Page 2 is margins ----------
      if send_default=2 then      -- 2: Use current values
         tempstr=.margins
      else                        -- 0|1: Use values from .ini file or default values
         tempstr = checkini(send_default, INI_MARGINS, DEFAULT_MARGINS)
      endif
      call send_config_data(hndle, tempstr, 1, 5301)

   elseif page=3 then  ----------------- Page 3 is colors -----------
      if send_default = 2 then    -- 2: Use current values
         tempstr = .textcolor .markcolor vSTATUSCOLOR vMESSAGECOLOR
      else
         if send_default then     -- 1: Use default values
            tempstr = ''
         else                     -- 0: Use values from .ini file
            tempstr= queryprofile( app_hini, appname, INI_STUFF)
         endif
         if tempstr='' | tempstr=1 then
            tempstr=TEXTCOLOR MARKCOLOR STATUSCOLOR MESSAGECOLOR
         endif
      endif
      parse value tempstr with ttextcolor tmarkcolor tstatuscolor tmessagecolor .
      call send_config_data(hndle, ttextcolor, 4, help_panel)
      call send_config_data(hndle, tmarkcolor, 5, help_panel)
      call send_config_data(hndle, tstatuscolor, 6, help_panel)
      call send_config_data(hndle, tmessagecolor, 7, help_panel)

   elseif page=4 then  ----------------- Page 4 is paths ------------
 compile if SPELL_SUPPORT   -- If dictionary & addenda present, ...
  compile if WPS_SUPPORT
      if not wpshell_handle then
  compile endif
  compile if CHECK_FOR_LEXAM
      if LEXAM_is_available then
  compile endif
         help_panel = 5390  -- Different help panel
  compile if CHECK_FOR_LEXAM
      endif
  compile endif
  compile if WPS_SUPPORT
      endif
  compile endif
 compile endif  -- SPELL_SUPPORT
      call send_config_data(hndle, checkini(send_default, INI_TEMPPATH, vTEMP_PATH, TEMP_PATH), 10, help_panel)
 compile if SPELL_SUPPORT  -- Display spell-checking fields (dictionary & addenda paths)
  compile if CHECK_FOR_LEXAM
      if LEXAM_is_available then
  compile endif
         call send_config_data(hndle, checkini(send_default, INI_DICTIONARY, DICTIONARY_FILENAME), 11, help_panel)
         call send_config_data(hndle, checkini(send_default, INI_ADDENDA, ADDENDA_FILENAME), 12, help_panel)
  compile if CHECK_FOR_LEXAM
      endif
  compile endif
 compile endif  -- SPELL_SUPPORT

   elseif page=5 then  ----------------- Page 5 is autosave ---------
      if send_default=2 then      -- 2: Use current values
         tempstr=.autosave
      else                        -- 0|1: Use values from .ini file or default values
         tempstr = checkini(send_default, INI_AUTOSAVE, DEFAULT_AUTOSAVE)
      endif
      call send_config_data(hndle, tempstr, 2, help_panel)
      call send_config_data(hndle, checkini(send_default, INI_AUTOSPATH, vAUTOSAVE_PATH, AUTOSAVE_PATH), 9, help_panel)

   elseif page=6 then  ----------------- Page 6 is fonts ------------
      call send_config_data(hndle, queryfont(word(default_font 0 .font, send_default+1))'.'trunc(.textcolor//16)'.'.textcolor%16, 24, help_panel)
      if not send_default then    -- 0: Use values from .ini file
         tempstr= checkini(send_default, INI_STATUSFONT, '')
         if tempstr then
            parse value tempstr with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      elseif send_default=1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                        -- 2: Use current values
         if statfont then
            parse value statfont with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      endif
      call send_config_data(hndle, tempstr'.'trunc(vSTATUSCOLOR//16)'.'vSTATUSCOLOR%16, 25, help_panel)
      if not send_default then    -- 0: Use values from .ini file
         tempstr= checkini(send_default, INI_MESSAGEFONT, '')
         if tempstr then
            parse value tempstr with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      elseif send_default=1 then  -- 1: Use default values
         tempstr = queryfont(0)
      else                        -- 2: Use current values
         if msgfont then
            parse value msgfont with ptsize'.'facename'.'attr
            tempstr = facename'.'ptsize'.'attr
         else
            tempstr = queryfont(0)
         endif
      endif
      call send_config_data(hndle, tempstr'.'trunc(vMESSAGECOLOR//16)'.'vMESSAGECOLOR%16, 26, help_panel)

 compile if ENHANCED_ENTER_KEYS  -- Enter key definition for line mode
   elseif page=7 then  ----------------- Page 7 is enter keys -------
      if send_default=1 then      -- 1: Use default values
  compile if ENTER_ACTION='' | ENTER_ACTION='ADDLINE'  -- The default
         ek = \1
  compile elseif ENTER_ACTION='NEXTLINE'
         ek = \2
  compile elseif ENTER_ACTION='ADDATEND'
         ek = \3
  compile elseif ENTER_ACTION='DEPENDS'
         ek = \4
  compile elseif ENTER_ACTION='DEPENDS+'
         ek = \5
  compile elseif ENTER_ACTION='STREAM'
         ek = \6
  compile endif
  compile if C_ENTER_ACTION='ADDLINE'
         c_ek = \1
  compile elseif C_ENTER_ACTION='' | C_ENTER_ACTION='NEXTLINE'  -- The default
         c_ek = \2
  compile elseif C_ENTER_ACTION='ADDATEND'
         c_ek = \3
  compile elseif C_ENTER_ACTION='DEPENDS'
         c_ek = \4
  compile elseif C_ENTER_ACTION='DEPENDS+'
         c_ek = \5
  compile elseif C_ENTER_ACTION='STREAM'
         c_ek = \6
  compile endif
         tempstr = ek || ek || c_ek || ek || ek || ek || c_ek || ek
      else                        -- 0|2: Use values from .ini file or current values
         tempstr = chr(enterkey) || chr(a_enterkey) || chr(c_enterkey) || chr(s_enterkey) || chr(padenterkey) || chr(a_padenterkey) || chr(c_padenterkey) || chr(s_padenterkey)
      endif
      call send_config_data(hndle, tempstr, 14, help_panel)
 compile endif  -- ENHANCED_ENTER_KEYS

   elseif page=8 then  ----------------- Page 8 is Frame controls ---
      tempstr = '1111010'  -- StatWnd, MsgWnd, hscroll, vscroll, extrawnd, bgbitmap, drop
      if not send_default then    -- 0: Use values from .ini file
         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with statflg msgflg vscrollflg hscrollflg . . extraflg . . . . . . . new_bitmap . drop_style .
            tempstr = statflg || msgflg || hscrollflg || vscrollflg || extraflg || new_bitmap || drop_style
         endif
      elseif send_default=2 then  -- 2: Use current values
         tempstr = queryframecontrol(1) || queryframecontrol(2) || queryframecontrol(16) || queryframecontrol(8) || queryframecontrol(32) || bitmap_present || queryframecontrol(8192)
      endif
      call send_config_data(hndle, tempstr, 15, help_panel)
      call send_config_data(hndle, checkini(send_default, INI_BITMAP, bm_filename, ''), 16, help_panel)

   elseif page=9 then  ----------------- Page 9 is Misc. ------------
      tempstr = '0000100'  -- CUA marking, stream mode, Rexx profile, longnames, I-beam pointer, underline cursor, menu accelerators
      if not send_default then    -- 0: Use values from .ini file
         newcmd=queryprofile( app_hini, appname, INI_OPT2FLAGS)
         if newcmd <> '' then
            parse value newcmd with pointer_style cursor_shape .
         else
            pointer_style = (vEPM_POINTER=2)
            cursor_shape = (cursordimensions = '-128.3 -128.-64') -- 1 if underline; 0 if vertical
         endif

         newcmd=queryprofile( app_hini, appname, INI_CUAACCEL)
         if newcmd<>'' then menu_accel = newcmd
                       else menu_accel = 0
         endif

         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with . . . . . . . markflg . streamflg longnames profile .
            tempstr = markflg || streamflg || longnames || profile || pointer_style || cursor_shape || menu_accel
         endif
      elseif send_default=2 then  -- 2: Use current values
 compile if WANT_STREAM_MODE <> 'SWITCH'  -- Set a local variable
         stream_mode = WANT_STREAM_MODE
 compile endif
 compile if WANT_LONGNAMES<>'SWITCH'
         SHOW_LONGNAMES = WANT_LONGNAMES
 compile endif
 compile if WANT_PROFILE<>'SWITCH'
         REXX_PROFILE = WANT_PROFILE
 compile endif
 compile if WANT_CUA_MARKING <> 'SWITCH'
         CUA_marking_switch = WANT_CUA_MARKING
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS <> 'SWITCH'
         CUA_MENU_ACCEL = not BLOCK_ACTIONBAR_ACCELERATORS
 compile endif                                                                                                 -- 1 if underline; 0 otherwise
         tempstr = CUA_marking_switch || stream_mode || REXX_PROFILE || SHOW_LONGNAMES || (vEPM_POINTER=2) || (cursordimensions = '-128.3 -128.-64') || CUA_MENU_ACCEL
      endif
      call send_config_data(hndle, tempstr, 18, help_panel)

   elseif page=12 then  ---------------- Page 12 is Toolbar config --
      if send_default = 1         -- 1: Use default values
         then tempstr = ''
      else                        -- 0|2: Use values from .ini file or current values
         tempstr = queryprofile( app_hini, 'UCMenu', 'ConfigInfo')
      endif
      if tempstr = '' then
         tempstr = \1'8'\1'32'\1'32'\1'8.Helv'\1'16777216'\1'16777216'\1
      endif
      call send_config_data(hndle, tempstr, 22, help_panel)

   elseif page=13 then  ---------------- Page 13 is Toolbar name & on/off
      active_toolbar = toolbar_loaded
      if active_toolbar = \1 then active_toolbar = ''; endif
      call send_config_data(hndle, checkini(send_default, INI_DEF_TOOLBAR, active_toolbar, ''), 20, help_panel)
      call send_config_data(hndle, queryframecontrol(EFRAMEF_TOOLBAR), 21, help_panel)

   endif  -- page = 1

defproc send_config_data(hndle, strng, i, help_panel)
   strng = strng\0          -- null terminate (asciiz)
   call windowmessage(1,  hndle,
                      32,               -- WM_COMMAND - 0x0020
                      mpfrom2short(help_panel, i),
                      ltoa(offset(strng) || selector(strng), 10) )

 compile if ENHANCED_ENTER_KEYS
defc enterkeys =
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
   universal appname, app_hini
   parse arg perm enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey
   if perm then
      call setprofile(app_hini, appname,INI_ENTERKEYS, enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey)
   endif
 compile endif

; send_default is a flag that says we're reverting to the default product options.
; defaultdata is the value to be used as the window default if INIKEY isn't found
; in the EPM.INI; it will also be used as the product default if no fourth parameter
; is given.
defproc checkini(send_default, inikey, defaultdata )
   universal appname, app_hini
   if send_default then
      if send_default=1 & arg()>3 then
         return arg(4)
      endif
      return defaultdata
   endif
   inidata=queryprofile(app_hini, appname,inikey)
   if inidata<>'' then
      return inidata
   endif
   return defaultdata

; 5.21 lets you apply without saving, so we add an optional 3rd parameter.
; If omitted, assume the old way - save.  If present, only save if 1.
defproc setini( inikey, inidata )
   universal appname, app_hini
   if arg()>=3 then
      perm=arg(3)
   else
      perm=1
   endif
   if perm then
      call setprofile(app_hini, appname, inikey, inidata)
   endif
   return inidata

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: setconfig       syntax:   setconfig configid  newvalue   ³
³                                                                            ³
³ what does it do : The function is called by the EPM CONFIG dialog box to   ³
³                   return values set by the user.                           ³
³                                                                            ³
³                                                                            ³
³ who and when    : Jerry C. & LAM  7/20/89                                  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc setconfig
   universal  ADDENDA_FILENAME
   universal  DICTIONARY_FILENAME
   universal  vTEMP_FILENAME, vTEMP_PATH
   universal  vAUTOSAVE_PATH
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal  appname, app_hini
   universal vMESSAGECOLOR, vSTATUSCOLOR
   universal statfont, msgfont
   universal bm_filename
   universal bitmap_present
   universal toolbar_loaded
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
 compile endif
 compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if TOGGLE_TAB
   universal TAB_KEY
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
 compile endif
   universal vEPM_POINTER, cursordimensions

   parse value arg(1) with configid perm newcmd

   if     configid= 1 then
      if .margins<>newcmd then
         'postme maybe_reflow_all'
  compile if NEPMD_SPECIAL_STATUSLINE
         'postme refreshstatusline'  -- refreshstatusline is defined in STATLINE.E
  compile endif
      endif
      .margins=newcmd
      vDEFAULT_MARGINS=setini(INI_MARGINS, .margins, perm)

   elseif configid= 2 then
      .autosave=setini(INI_AUTOSAVE,newcmd, perm)
      vDEFAULT_AUTOSAVE=newcmd

   elseif configid= 3 then
      rc=0
      .tabs=newcmd
  compile if NEPMD_SPECIAL_STATUSLINE
         'postme refreshstatusline'  -- refreshstatusline is defined in STATLINE.E
  compile endif
      if not rc then
         vDEFAULT_TABS=setini(INI_TABS,newcmd, perm)
      endif

   elseif configid= 4 then
      .textcolor=newcmd

   elseif configid= 5 then
      .markcolor=newcmd

   elseif configid= 6 & newcmd<>vSTATUSCOLOR then
      vSTATUSCOLOR=newcmd
      'setstatusline'

   elseif configid= 7 & newcmd<>vMESSAGECOLOR then
      vMESSAGECOLOR=newcmd
      'setmessageline'

   elseif configid= 9 then
      if newcmd<>'' & rightstr(newcmd,1)<>'\' then
         newcmd=newcmd'\'
      endif
      if rightstr(newcmd,2)='\\' then             -- Temp fix for dialog bug
         newcmd=leftstr(newcmd,length(newcmd)-1)
      endif
      vAUTOSAVE_PATH=setini(INI_AUTOSPATH,newcmd, perm)

   elseif configid=10 then
      if newcmd<>'' & rightstr(newcmd,1)<>'\' then
         newcmd=newcmd'\'
      endif
      if rightstr(newcmd,2)='\\' then             -- Temp fix for dialog bug
         newcmd=leftstr(newcmd,length(newcmd)-1)
      endif
      if upcase(leftstr(vTEMP_FILENAME,length(vTEMP_PATH))) = upcase(vTEMP_PATH) then
         vTEMP_FILENAME=newcmd||substr(vTEMP_FILENAME,length(vTEMP_PATH)+1)
      elseif not verify(vTEMP_FILENAME,':\','M') then   -- if not fully qualified
         vTEMP_FILENAME=newcmd||vTEMP_FILENAME
      endif
      vTEMP_PATH=setini(INI_TEMPPATH,newcmd, perm)

   elseif configid=11 then
      DICTIONARY_FILENAME = setini(INI_DICTIONARY,newcmd, perm)

   elseif configid=12 then
      ADDENDA_FILENAME    = setini(INI_ADDENDA,newcmd, perm)

   elseif configid=15 then
      parse value newcmd with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7 drop_style 8
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
      'toggleframe 32' extraflg
      'toggleframe 8192' drop_style
      if bitmap_present <> new_bitmap then
         'toggle_bitmap'
         if bitmap_present then
            bm_filename = ''  -- Will be reset; want to ensure it's reloaded.
         endif
      endif
      if perm then
         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with . . . . w1 w2 . w3 w4 w5 w6 w7 w8 w9 . w10 . rest
            call setprofile(app_hini, appname, INI_OPTFLAGS,
               queryframecontrol(1) queryframecontrol(2) queryframecontrol(8) queryframecontrol(16) w1 w2 queryframecontrol(32) w3 w4 w5 w6 w7 w8 w9 bitmap_present w10 queryframecontrol(8192) rest)
         else
            'saveoptions OptOnly'
         endif
      endif

   elseif configid=16 then
      if bm_filename <> newcmd then
         bm_filename = newcmd
         if bitmap_present then
            if bm_filename = '' then  -- Need to turn off & back on to get default bitmap
               'toggle_bitmap'
               'toggle_bitmap'
            else
               'load_dt_bitmap' bm_filename
            endif
         endif
      endif
      if perm then
         call setprofile(app_hini, appname, INI_BITMAP, bm_filename)
      endif

   elseif configid=18 then
      parse value newcmd with markflg 2 streamflg 3 profile 4 longnames 5 pointer_style 6 cursor_shape 7 menu_accel 8
      vEPM_POINTER = 1 + pointer_style
      mouse_setpointer vEPM_POINTER
 compile if not defined(my_CURSORDIMENSIONS)
  compile if DYNAMIC_CURSOR_STYLE
      'cursor_style' (cursor_shape+1)
    compile else
      if cursor_shape=0 then  -- Vertical bar
         cursordimensions = '-128.-128 2.-128'
      elseif cursor_shape=1 then  -- Underline cursor
         cursordimensions = '-128.3 -128.-64'
      endif
      call fixup_cursor()
  compile endif -- DYNAMIC_CURSOR_STYLE
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
       if markflg<>CUA_marking_switch then
          'CUA_mark_toggle'
       endif
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
      if streamflg<>stream_mode then 'stream_toggle'; endif
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
      if longnames<>'' then
         SHOW_LONGNAMES = longnames
      endif
 compile endif
 compile if WANT_PROFILE='SWITCH'
      if PROFILE<>'' then
         REXX_PROFILE = PROFILE
      endif
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      if CUA_MENU_ACCEL <> menu_accel then
         'accel_toggle'
      endif
 compile endif
      if perm then
         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            parse value newcmd with w1 w2 w3 w4 w5 w6 w7 . w8 . . . rest
            call setprofile(app_hini, appname, INI_OPTFLAGS,
                  w1 w2 w3 w4 w5 w6 w7 markflg w8 streamflg longnames profile rest)
         else
            'saveoptions OptOnly'
         endif
         call setprofile(app_hini, appname, INI_OPT2FLAGS, pointer_style cursor_shape)
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
         call setprofile(app_hini, appname, INI_CUAACCEL, menu_accel)
 compile endif
      endif

 compile if TOGGLE_TAB
   elseif configid=19 then
      TAB_KEY = newcmd
      if perm then
         newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if newcmd <> '' then
            call setprofile(app_hini, appname, INI_OPTFLAGS,
                  subword(newcmd, 1, 13) tab_key subword(newcmd, 15))
         else
            'saveoptions OptOnly'
         endif
      endif
 compile endif

   elseif configid=20 then
      if newcmd = '' then  -- Null string; use compiled-in toolbar
         if toolbar_loaded <> \1 then
            'loaddefaulttoolbar'
         endif
      elseif newcmd <> toolbar_loaded then
         call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5916, app_hini, put_in_buffer(newcmd))
         toolbar_loaded = newcmd
      endif
      if perm then
         call setprofile(app_hini, appname, INI_DEF_TOOLBAR, newcmd)
      endif

   elseif configid=21 then
      if newcmd <> queryframecontrol(EFRAMEF_TOOLBAR) then
         'toggleframe' EFRAMEF_TOOLBAR newcmd
      endif
      if perm then
         temp=queryprofile( app_hini, appname, INI_OPTFLAGS)
         if temp <> '' then
            call setprofile(app_hini, appname, INI_OPTFLAGS,
                  subword(temp, 1, 15) newcmd subword(temp, 17))
         else
            'saveoptions OptOnly'  -- Possible synch problem?
         endif
      endif

   elseif configid=22 then
      call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5921, put_in_buffer(newcmd), 0)
 compile if 0
      parse value newcmd with \1 style \1 cx \1 cy \1 font \1 color \1 itemcolor \1
      if perm then
         call setprofile( app_hini, 'UCMenu', 'Style', style)
         call setprofile( app_hini, 'UCMenu', 'Cx', cx)
         call setprofile( app_hini, 'UCMenu', 'Cy', cy)
         call setprofile( app_hini, 'UCMenu', 'Font', font)
         call setprofile( app_hini, 'UCMenu', 'Color', color)
         call setprofile( app_hini, 'UCMenu', 'ItemColor', itemcolor)
      endif
 compile else
      if perm then
         call setprofile( app_hini, 'UCMenu', 'ConfigInfo', newcmd)
      endif
 compile endif

   elseif configid= 0 then
      call setprofile( app_hini, appname, INI_STUFF, .textcolor .markcolor vstatuscolor vmessagecolor)

   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: initconfig                                               ³
³                                                                            ³
³ what does it do : Set universal variables according to the  values         ³
³                   previously saved in the EPM.INI file.                    ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc initconfig
   universal ADDENDA_FILENAME
   universal DICTIONARY_FILENAME
   universal vTEMP_FILENAME, vTEMP_PATH
   universal vAUTOSAVE_PATH
   universal appname, app_hini, font, bitmap_present, optflag_extrastuff
   universal vDEFAULT_TABS, vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE
   universal statfont, msgfont, bm_filename
   universal default_font
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile endif
 compile if WANT_DYNAMIC_PROMPTS
   universal  menu_prompt
 compile endif
 compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH)
   universal savepath
 compile endif
   universal vMESSAGECOLOR, vSTATUSCOLOR
   universal vDESKTOPColor
 compile if ENHANCED_ENTER_KEYS
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if RING_OPTIONAL
   universal ring_enabled
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
 compile endif
 compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
 compile endif
 compile if TOGGLE_ESCAPE
   universal ESCAPE_KEY
 compile endif
 compile if TOGGLE_TAB
   universal TAB_KEY
 compile endif
   universal vEPM_POINTER, cursordimensions

 compile if WPS_SUPPORT  -- if Epm class is used
   universal wpshell_handle
   useWPS = upcase(arg(1))<>'NOWPS'
   if wpshell_handle & useWPS then  -- read config data from WPS object
      load_wps_config(wpshell_handle)
      newcmd = 1  -- For a later IF
   else                             -- read config data from EPM.INI
 compile endif

      newcmd= queryprofile( app_hini, appname, INI_STUFF)
      if newcmd then
         parse value newcmd with ttextcolor tmarkcolor tstatuscolor tmessagecolor .
         .textcolor=ttextcolor; .markcolor=tmarkcolor
         if tstatuscolor<>'' & tstatuscolor<>vSTATUSCOLOR then
            vSTATUSCOLOR=tstatuscolor
            'setstatusline'
         endif
         if tmessagecolor<>'' & tmessagecolor<>vMESSAGECOLOR then
            vMESSAGECOLOR=tmessagecolor
            'setmessageline'
         endif
         newcmd=queryprofile( app_hini, appname, INI_MARGINS)
         if newcmd then
            .margins=newcmd
            vDEFAULT_MARGINS=newcmd
         endif
         newcmd=queryprofile( app_hini, appname, INI_AUTOSAVE)
         if newcmd<>'' then
            .autosave=newcmd
            vDEFAULT_AUTOSAVE=newcmd
         endif
         newcmd=queryprofile( app_hini, appname, INI_TABS)
         if newcmd then
            .tabs=newcmd; vDEFAULT_TABS=newcmd
         endif
         newcmd=queryprofile( app_hini, appname, INI_TEMPPATH)
         if newcmd then
            vTEMP_PATH=newcmd
            if rightstr(vTemp_Path,1)<>'\' then
               vTemp_Path = vTemp_Path'\'          -- Must end with a backslash.
            endif
            if not verify(vTEMP_FILENAME,':\','M') then   -- if not fully qualified
               vTEMP_FILENAME=vTEMP_PATH||vTEMP_FILENAME
            endif
         endif
         newcmd=queryprofile( app_hini, appname, INI_AUTOSPATH)
         if newcmd then
            vAUTOSAVE_PATH=newcmd
            if rightstr(vAUTOSAVE_Path,1)<>'\' then
               vAUTOSAVE_Path = vAUTOSAVE_Path'\'  -- Must end with a backslash.
            endif
 compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH)
            savepath=vAUTOSAVE_PATH
 compile endif
         endif
         newcmd=queryprofile( app_hini, appname, INI_DICTIONARY)
         if newcmd then
            DICTIONARY_FILENAME=newcmd
         endif
         newcmd=queryprofile( app_hini, appname, INI_ADDENDA)
         if newcmd then
            ADDENDA_FILENAME=newcmd
         endif
      endif  -- newcmd

          -- Options from Option pulldown
      newcmd=queryprofile( app_hini, appname, INI_OPTFLAGS)
 compile if WPS_SUPPORT
   endif  -- wpshell_handle
 compile endif
   if newcmd='' then
      optflag_extrastuff = ''
 compile if not defined(WANT_BITMAP_BACKGROUND)
      new_bitmap = 1
 compile else
      new_bitmap = WANT_BITMAP_BACKGROUND
 compile endif -- not defined(WANT_BITMAP_BACKGROUND)
   drop_style = 0
 compile if WANT_TOOLBAR
  compile if defined(INITIAL_TOOLBAR)
      toolbar_present = INITIAL_TOOLBAR
  compile else
      toolbar_present = 1
  compile endif
 compile endif -- WANT_TOOLBAR
   else
 compile if WPS_SUPPORT
   if  wpshell_handle & useWPS then  -- Keys 15, 18 & 19
      parse value peekz(peek32(wpshell_handle, 60, 4)) with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7 drop_style 8
      parse value peekz(peek32(wpshell_handle, 72, 4)) with markflg 2 streamflg 3 profile 4 longnames 5 pointer_style 6 cursor_shape 7
      parse value peekz(peek32(wpshell_handle, 76, 4)) with tabkey 2
      parse value peekz(peek32(wpshell_handle, 84, 4)) with toolbar_present 2
      rotflg = 1
   else
 compile endif
      parse value newcmd with statflg msgflg vscrollflg hscrollflg fileiconflg rotflg extraflg markflg menu_prompt streamflg longnames profile escapekey tabkey new_bitmap toolbar_present drop_style optflag_extrastuff
 compile if WPS_SUPPORT
   endif  -- wpshell_handle
 compile endif
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
 compile if RING_OPTIONAL
      if ring_enabled then
         'toggleframe 4' rotflg
      endif
 compile else
      'toggleframe 4' rotflg
 compile endif
      'toggleframe 32' extraflg
      if drop_style <> '' then
         'toggleframe 8192' drop_style
      endif
      if new_bitmap='' then
 compile if not defined(WANT_BITMAP_BACKGROUND)
         new_bitmap = 1
 compile else
         new_bitmap = WANT_BITMAP_BACKGROUND
 compile endif -- not defined(WANT_BITMAP_BACKGROUND)
      endif
 compile if WANT_CUA_MARKING = 'SWITCH'
      if markflg<>CUA_marking_switch then
         'CUA_mark_toggle'
      endif
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
      if streamflg<>stream_mode then 'stream_toggle'; endif
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
      if longnames<>'' then
         SHOW_LONGNAMES = longnames
      endif
 compile endif
 compile if WANT_PROFILE='SWITCH'
      if PROFILE<>'' then
         REXX_PROFILE = PROFILE
      endif
 compile endif
 compile if TOGGLE_ESCAPE
      if ESCAPEKEY<>'' then
         ESCAPE_KEY = ESCAPEKEY
      endif
 compile endif
 compile if TOGGLE_TAB
      if TABKEY<>'' then
         TAB_KEY = TABKEY
      endif
 compile endif
   endif  /* INI_OPTFLAGS 1/3 */ -- Settings dlg, not as part of Save Options
 compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
 compile endif
      if bitmap_present <> new_bitmap then
         'toggle_bitmap'
      endif
 compile if WANT_STREAM_MODE <> 1 and ENHANCED_ENTER_KEYS
      newcmd=queryprofile( app_hini, appname, INI_ENTERKEYS)
      if newcmd<>'' then
         parse value newcmd with enterkey a_enterkey c_enterkey s_enterkey padenterkey a_padenterkey c_padenterkey s_padenterkey .
      endif
 compile endif
      newcmd=queryprofile( app_hini, appname, INI_STATUSFONT)
      if newcmd<>'' then
         statfont = newcmd  -- Need to keep?
         parse value newcmd with psize"."facename"."attr
         "setstatface" getpminfo(EPMINFO_EDITSTATUSHWND) facename
         "setstatptsize" getpminfo(EPMINFO_EDITSTATUSHWND) psize
      endif
      newcmd=queryprofile( app_hini, appname, INI_MESSAGEFONT)
      if newcmd<>'' then
         msgfont = newcmd   -- Need to keep?
         parse value newcmd with psize"."facename"."attr
         "setstatface" getpminfo(EPMINFO_EDITMSGHWND) facename
         "setstatptsize" getpminfo(EPMINFO_EDITMSGHWND) psize
      endif
      newcmd=queryprofile( app_hini, appname, INI_BITMAP)
      if newcmd<>'' then
         bm_filename = newcmd  -- Need to keep?
         if bitmap_present then
            'load_dt_bitmap' bm_filename
         endif
      endif
 compile if WPS_SUPPORT
   endif  -- not wpshell_handle
 compile endif

 compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
 compile endif
      parse value queryprofile( app_hini, appname, INI_OPT2FLAGS) with pointer_style cursor_shape .
 compile if WPS_SUPPORT
   endif  -- not wpshell_handle
 compile endif
   if pointer_style <> '' then
      vEPM_POINTER = 1 + pointer_style
      mouse_setpointer vEPM_POINTER
   endif
 compile if not defined(my_CURSORDIMENSIONS)
   if cursor_shape <> '' then
  compile if DYNAMIC_CURSOR_STYLE
      'cursor_style' (cursor_shape+1)
  compile else
      if cursor_shape=0 then  -- Vertical bar
         cursordimensions = '-128.-128 2.-128'
      elseif cursor_shape=1 then  -- Underline cursor
         cursordimensions = '-128.3 -128.-64'
      endif
      call fixup_cursor()
  compile endif -- DYNAMIC_CURSOR_STYLE
   endif
 compile endif -- not defined(my_CURSORDIMENSIONS)

 compile if WPS_SUPPORT
   if not (wpshell_handle & useWPS) then
 compile endif
      newcmd =queryprofile( app_hini, appname, INI_FONT)
      parse value newcmd with fontname '.' fontsize '.' fontsel
      if newcmd<>'' then
         .font=registerfont(fontname, fontsize, fontsel)
         default_font = .font
      endif
 compile if WPS_SUPPORT
   endif  -- not wpshell_handle
 compile endif


 compile if WANT_TOOLBAR
   if toolbar_present then
      'default_toolbar'
;  else
;     'toggleframe' EFRAMEF_TOOLBAR toolbar_present
   endif
 compile endif

   newcmd = queryprofile(app_hini, appname, INI_DTCOLOR)
   if newcmd<>'' then
      vDESKTOPColor = newcmd
      call windowmessage( 0,  getpminfo(EPMINFO_EDITCLIENT),  -- post
                          5497,      -- EPM_EDIT_SETDTCOLOR
                          vDESKTOPColor,
                          0)
   endif

 compile if WPS_SUPPORT
defproc load_wps_config(shared_mem)
   universal vDEFAULT_MARGINS, vDEFAULT_AUTOSAVE, vDEFAULT_TABS, vSTATUSCOLOR,  vMESSAGECOLOR,vAUTOSAVE_PATH
   universal vTEMP_PATH, vTEMP_FILENAME, DICTIONARY_FILENAME, ADDENDA_FILENAME
   universal default_font
  compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL')
   universal savepath
  compile endif
  compile if ENHANCED_ENTER_KEYS
   universal enterkey, a_enterkey, c_enterkey, s_enterkey
   universal padenterkey, a_padenterkey, c_padenterkey, s_padenterkey
  compile endif
   universal bitmap_present, bm_filename
/* shared_memx = "x'"ltoa(atol(shared_mem), 16)"'"                                                                                                                                        */
/*    thisptr = ''                                                                                                                                                                        */
/*    do i=1 to 14                                                                                                                                                                        */
/*         thisptr = thisptr i"=x'"ltoa(peek32(shared_mem, i*4, 4), 16)"'"                                                                                                                */
/*    enddo                                                                                                                                                                               */
/* call winmessagebox('load_wps_config('shared_memx') pointers', thisptr, 16432) -- MB_OK + MB_INFORMATION + MB_MOVEABLE                                                                  */
;  if rc then
;     messageNwait('DosGetSharedMem' ERROR__MSG rc)
;     return
;  endif

; Key 1
   this_ptr = peek32(shared_mem, 4, 4);  -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', "First pointer = x'"ltoa(this_ptr, 16)"'", 16432)*/
/** call winmessagebox('load_wps_config('shared_memx')', 'First pointer -> "'peekz(this_ptr)'"', 16432)*/
   .margins = peekz(this_ptr); vDEFAULT_MARGINS = .margins
/** sayerror '1:  Margins set OK:' peekz(this_ptr)  */
; Key 2
   this_ptr = peek32(shared_mem, 8, 4);  -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', "Second pointer = x'"ltoa(this_ptr, 16)"'", 16432) */
/** call winmessagebox('load_wps_config('shared_memx')', 'Second pointer -> "'peekz(this_ptr)'"', 16432) */
   .autosave = peekz(this_ptr); vDEFAULT_AUTOSAVE = .autosave
/** sayerror '2:  Autosave set OK:' peekz(this_ptr) */
; Key 3
   this_ptr = peek32(shared_mem, 12, 4);  -- if this_ptr = \0\0\0\0 then return; endif
   .tabs = peekz(this_ptr); vDEFAULT_TABS = .tabs
/** sayerror '3:  Tabs set OK:' peekz(this_ptr) */
; Key 4
   this_ptr = peek32(shared_mem, 16, 4); -- if this_ptr = \0\0\0\0 then return; endif
   .textcolor = peekz(this_ptr)
/** sayerror '4:  Textcolor set OK:' peekz(this_ptr) */
; Key 5
   this_ptr = peek32(shared_mem, 20, 4); -- if this_ptr = \0\0\0\0 then return; endif
   .markcolor = peekz(this_ptr)
/** sayerror '5:  Markcolor set OK:' peekz(this_ptr) */
; Key 6
   this_ptr = peek32(shared_mem, 24, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vSTATUSCOLOR = peekz(this_ptr); 'setstatusline'
/** sayerror '6:  Statuscolor set OK:' peekz(this_ptr) */
; Key 7
   this_ptr = peek32(shared_mem, 28, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vMESSAGECOLOR = peekz(this_ptr); 'setmessageline'
/** sayerror '7:  Messagecolor set OK:' peekz(this_ptr) */
; Key 9
   this_ptr = peek32(shared_mem, 36, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vAUTOSAVE_PATH = peekz(this_ptr)
   if vAUTOSAVE_PATH & rightstr(vAUTOSAVE_Path,1)<>'\' then
      vAUTOSAVE_Path = vAUTOSAVE_Path'\'  -- Must end with a backslash.
   endif
  compile if (HOST_SUPPORT='EMUL' | HOST_SUPPORT='E3EMUL') and not defined(my_SAVEPATH)
   savepath=vAUTOSAVE_PATH
  compile endif
/** sayerror '9:  AutosavePath set OK:' peekz(this_ptr) */
; Key 10
   this_ptr = peek32(shared_mem, 40, 4); -- if this_ptr = \0\0\0\0 then return; endif
   vTEMP_PATH = peekz(this_ptr)
   if rightstr(vTemp_Path,1)<>'\' then
      vTemp_Path = vTemp_Path'\'          -- Must end with a backslash.
   endif
   if not verify(vTEMP_FILENAME,':\','M') then   -- if not fully qualified
      vTEMP_FILENAME=vTEMP_PATH||vTEMP_FILENAME
   endif
/** sayerror '10:  TempPath set OK:' peekz(this_ptr) */
; Key 11
   this_ptr = peek32(shared_mem, 44, 4); -- if this_ptr = \0\0\0\0 then return; endif
   DICTIONARY_FILENAME = peekz(this_ptr)
/** sayerror '11:  Dictionary set OK:' peekz(this_ptr) */
; Key 12
   this_ptr = peek32(shared_mem, 48, 4); -- if this_ptr = \0\0\0\0 then return; endif
   ADDENDA_FILENAME = peekz(this_ptr)
/** sayerror '12:  Addenda file set OK:' peekz(this_ptr) */
; Key 15
      parse value peekz(peek32(shared_mem, 60, 4)) with 6 new_bitmap 7
   if bitmap_present <> new_bitmap then
      'toggle_bitmap'
   endif
; Key 16
   if bm_filename<>peekz(peek32(shared_mem, 64, 4)) then
      bm_filename = peekz(peek32(shared_mem, 64, 4))
      if bitmap_present then
         'load_dt_bitmap' bm_filename
      endif
   endif
; Key 24
   this_ptr = peek32(shared_mem, 96, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '13th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize="'fontsize'"; fontsel="'fontsel'"'  */
   .font=registerfont(fontname, fontsize, fontsel); default_font = .font
/*  sayerror '24:  Font set OK:' peekz(this_ptr) '.font =' default_font  */
  compile if ENHANCED_ENTER_KEYS
; Key 14
   this_ptr = peek32(shared_mem, 56, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '14th pointer -> "'peekz(this_ptr)'"', 16432) */
   tempstr = peekz(this_ptr)
   enterkey      = asc(substr(tempstr, 1, 1))
   a_enterkey    = asc(substr(tempstr, 2, 1))
   c_enterkey    = asc(substr(tempstr, 3, 1))
   s_enterkey    = asc(substr(tempstr, 4, 1))
   padenterkey   = asc(substr(tempstr, 5, 1))
   a_padenterkey = asc(substr(tempstr, 6, 1))
   c_padenterkey = asc(substr(tempstr, 7, 1))
   s_padenterkey = asc(substr(tempstr, 8, 1))
/** sayerror '14:  Enter keys set OK:' peekz(this_ptr) */
  compile endif
/** call winmessagebox('load_wps_config('shared_memx')', 'All done!', 16432)  */
; Key 25
   this_ptr = peek32(shared_mem, 100, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '25th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize="'fontsize'"; fontsel="'fontsel'"'  */
   statfont = fontsize'.'fontname'.'fontsel
   "setstatface" getpminfo(EPMINFO_EDITSTATUSHWND) fontname
   "setstatptsize" getpminfo(EPMINFO_EDITSTATUSHWND) fontsize
; Key 26
   this_ptr = peek32(shared_mem, 104, 4); -- if this_ptr = \0\0\0\0 then return; endif
/** call winmessagebox('load_wps_config('shared_memx')', '26th pointer -> "'peekz(this_ptr)'"', 16432) */
   parse value peekz(this_ptr) with fontname '.' fontsize '.' fontsel '.'
/*  sayerror 'data = "'peekz(this_ptr)'"; fontname = "'fontname'"; fontsize="'fontsize'"; fontsel="'fontsel'"'  */
   msgfont = fontsize'.'fontname'.'fontsel
   "setstatface" getpminfo(EPMINFO_EDITMSGHWND) fontname
   "setstatptsize" getpminfo(EPMINFO_EDITMSGHWND) fontsize

;defproc ppeek32(longaddr, offst, len)
;   parse value atol(longaddr+offst) with hex_ofs 3 hex_seg
;   return peek(ltoa(hex_seg\0\0, 10), ltoa(hex_ofs\0\0, 10), len)

defc refresh_config
   universal app_hini
   universal wpshell_handle
   universal toolbar_loaded
  compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
  compile endif
  compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
  compile endif
  compile if RING_OPTIONAL
   universal ring_enabled
  compile endif
  compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
  compile endif
  compile if TOGGLE_ESCAPE
   universal ESCAPE_KEY
  compile endif
  compile if TOGGLE_TAB
   universal TAB_KEY
  compile endif
  compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
  compile endif
  compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
  compile endif
  compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
  compile endif
   universal bitmap_present, bm_filename
   universal cursordimensions
   universal vEPM_POINTER
   if wpshell_handle then
      load_wps_config(wpshell_handle)
; Key 15
      parse value peekz(peek32(wpshell_handle, 60, 4)) with statflg 2 msgflg 3 hscrollflg 4 vscrollflg 5 extraflg 6 new_bitmap 7
      'toggleframe 1' statflg
      'toggleframe 2' msgflg
      'toggleframe 8' vscrollflg
      'toggleframe 16' hscrollflg
      'toggleframe 32' extraflg
;  if bitmap_present <> new_bitmap then
;     'toggle_bitmap'
;  endif
; Key 18
      parse value peekz(peek32(wpshell_handle, 72, 4)) with markflg 2 streamflg 3 rexx_profile 4 longnames 5 pointer_style 6 cursor_shape 7 menu_accel 8
  compile if WANT_CUA_MARKING = 'SWITCH'
      if markflg<>CUA_marking_switch then
         'CUA_mark_toggle'
      endif
  compile endif
  compile if WANT_STREAM_MODE = 'SWITCH'
      if streamflg<>stream_mode then
         'stream_toggle'
      endif
  compile endif
  compile if WANT_LONGNAMES='SWITCH'
      SHOW_LONGNAMES = longnames
  compile endif
;compile if TOGGLE_ESCAPE
;     ESCAPE_KEY = ESCAPEKEY
;compile endif
      vEPM_POINTER = 1 + pointer_style
      mouse_setpointer vEPM_POINTER
  compile if not defined(my_CURSORDIMENSIONS)
   compile if DYNAMIC_CURSOR_STYLE
      'cursor_style' (cursor_shape+1)
   compile else
      if cursor_shape=0 then  -- Vertical bar
         cursordimensions = '-128.-128 2.-128'
      elseif cursor_shape=1 then  -- Underline cursor
         cursordimensions = '-128.3 -128.-64'
      endif
      call fixup_cursor()
   compile endif -- DYNAMIC_CURSOR_STYLE
  compile endif -- not defined(my_CURSORDIMENSIONS)
  compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
      if CUA_MENU_ACCEL <> menu_accel then
         'accel_toggle'
      endif
  compile endif
; Key 19
      parse value peekz(peek32(wpshell_handle, 76, 4)) with TAB_KEY 2
;     parse value peekz(peek32(wpshell_handle, 68, 4)) with rexx_profile 2 menu_prompt 3 new_bitmap 4
;     if new_bitmap <> bitmap_present then
;        'toggle_bitmap'
;     endif
; Key 20
      newcmd = peekz(peek32(wpshell_handle, 80, 4))
      if newcmd = '' then  -- Null string; use compiled-in toolbar
         if toolbar_loaded <> \1 then
            'loaddefaulttoolbar'
         endif
      elseif newcmd <> toolbar_loaded then
         call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5916, app_hini, put_in_buffer(newcmd))
         toolbar_loaded = newcmd
      endif
; Key 21
      parse value peekz(peek32(wpshell_handle, 84, 4)) with toolbar_flg 2
      if toolbar_flg <> queryframecontrol(EFRAMEF_TOOLBAR) then
         'toggleframe' EFRAMEF_TOOLBAR toolbar_flg
      endif
; Key 22
      call windowmessage(0, getpminfo(EPMINFO_EDITFRAME), 5921,
                         put_in_buffer(peekz(peek32(wpshell_handle, 88, 4))), 0)
   endif -- wpshell_handle
 compile endif  -- WPS_SUPPORT

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: saveoptions                                              ³
³                                                                            ³
³ what does it do : save state of items on options pull down in os2ini       ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc saveoptions
   universal appname, app_hini, bitmap_present, optflag_extrastuff, toolbar_present
   universal statfont, msgfont
   universal bm_filename
 compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
 compile endif
 compile if RING_OPTIONAL
   universal ring_enabled
 compile endif
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
 compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
 compile endif
 compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
 compile endif
 compile if WANT_PROFILE='SWITCH'
   universal REXX_PROFILE
 compile endif
 compile if TOGGLE_ESCAPE
   universal ESCAPE_KEY
 compile endif
 compile if TOGGLE_TAB
   universal TAB_KEY
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
 compile endif
 compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
 compile else
   CUA_marking_switch = 0
 compile endif

 compile if not WANT_DYNAMIC_PROMPTS
   menu_prompt = 1
 compile endif
 compile if WANT_STREAM_MODE <> 'SWITCH'
   stream_mode = 0
 compile endif
 compile if WANT_LONGNAMES<>'SWITCH'
   show_longnames = 0
 compile endif
 compile if WANT_PROFILE<>'SWITCH'
   REXX_PROFILE = 0
 compile endif
 compile if not TOGGLE_ESCAPE
   ESCAPE_KEY = 1
 compile endif
 compile if not TOGGLE_TAB
   TAB_KEY = 0
 compile endif

   call setprofile(app_hini, appname, INI_OPTFLAGS,
      queryframecontrol(1) queryframecontrol(2) queryframecontrol(8) queryframecontrol(16) queryframecontrol(64) queryframecontrol(4) queryframecontrol(32) CUA_marking_switch menu_prompt stream_mode show_longnames rexx_profile escape_key tab_key ||
      ' 'bitmap_present queryframecontrol(EFRAMEF_TOOLBAR) queryframecontrol(8192) optflag_extrastuff)
   if arg(1)='OptOnly' then
      return
   endif
 compile if RING_OPTIONAL
   call setprofile(app_hini, appname, INI_RINGENABLED,   ring_enabled)
 compile endif
 compile if WANT_STACK_CMDS = 'SWITCH'
   call setprofile(app_hini, appname, INI_STACKCMDS,     stack_cmds)
 compile endif
 compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   call setprofile(app_hini, appname, INI_CUAACCEL,      CUA_MENU_ACCEL)
 compile endif
   if statfont <> '' then
      call setprofile(app_hini, appname, INI_STATUSFONT, statfont)
   endif
   if msgfont <> '' then
      call setprofile(app_hini, appname, INI_MESSAGEFONT, msgfont)
   endif
;  if bm_filename <> '' then  -- Set even if null, so Toggle_Bitmap can remove dropped background.
      call setprofile(app_hini, appname, INI_BITMAP, bm_filename)
;  endif
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      62, 0, 0)               -- x'003E' = WM_SAVEAPPLICATION
 compile if SUPPORT_USER_EXITS
   if isadefproc('saveoptions_exit') then
      call saveoptions_exit()
   endif
 compile endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savefont                                                 ³
³                                                                            ³
³ what does it do : save fonts in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc savefont
   universal appname, app_hini, bitmap_present, optflag_extrastuff
   universal statfont, msgfont

   parse value upcase(arg(1)) with prefix
   if prefix == 'EDIT' then
      call setini( INI_FONT, queryfont(.font), 1)
   elseif prefix == 'STAT' & statfont <> '' then
      call setprofile(app_hini, appname, INI_STATUSFONT, statfont)
   elseif prefix == 'MSG' & msgfont <> '' then
      call setprofile(app_hini, appname, INI_MESSAGEFONT, msgfont)
   endif

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savecolor                                                ³
³                                                                            ³
³ what does it do : save color in the ini file                               ³
³ who&when : GLS  09/16/93                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc savecolor
   universal appname, app_hini
   universal vstatuscolor, vmessagecolor, vDESKTOPCOLOR

-- for now we save the mark edit status and message color in one block
-- (INI_STUFF topic in the ini file)

   call setprofile( app_hini, appname, INI_DTCOLOR, vDESKTOPColor)
   call setprofile( app_hini, appname, INI_STUFF, .textcolor .markcolor vstatuscolor vmessagecolor)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: savewindowsize                                           ³
³                                                                            ³
³ what does it do : save size of the edit window in the ini file             ³
³ who did it&when : GLS 09/15/93                                             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc savewindowsize
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      62, 0, 0)               -- x'003E' = WM_SAVEAPPLICATION


compile endif  -- WANT_APPLICATION_INI_FILE


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
defc PROCESSDRAGDROP
   parse arg cmdid hwnd
;  hwnd=atol_swap(hwnd)

   if cmdid=10 then
    call windowmessage(0,
                       getpminfo(APP_HANDLE),
                       5144,               -- EPM_PRINTDLG
                       hwnd='M',
                       0)
   elseif cmdid=1 and hwnd<>getpminfo(EPMINFO_EDITFRAME) and leftstr(.filename,1)<>'.' then
      call PostCmdToEditWindow('e '.filename,hwnd,9,2)  -- Get-able
   elseif cmdid=3 then
      if .filename=GetUnnamedFilename() then name=''; else name=.filename; endif
      call windowmessage(0,  getpminfo(APP_HANDLE),
                         5386,                   -- EPM_EDIT_NEWFILE
                         put_in_buffer(name,2),  -- share = GETable
                         9)                      -- EPM does a GET first & a FREE after.
   elseif cmdid=4 then
      call winmessagebox(SYS_ED__MSG,SYS_ED1__MSG\10'   :-)', 16406) -- CANCEL + ICONQUESTION + MB_MOVEABLE
   elseif cmdid=5 then
      str=leftstr('',MAXCOL)
      len= dynalink32( 'PMWIN',
                       '#841',             --   'WINQUERYWINDOWTEXT',
                       atol(hwnd)         ||
                       atol(MAXCOL)       ||
                       address(str), 2)
      p = lastpos('\',leftstr(str,len))
      if p then
         str = leftstr(str,p)'='
         call parse_filename(str, .filename)
         if exist(str) then
            if 1<>winmessagebox(str, EXISTS_OVERLAY__MSG, 16417) then -- OKCANCEL + CUANWARNING + MOVEABLE
               return  -- 1 = MB OK
            endif
         endif
         'save' str
         if not rc then sayerror SAVED_TO__MSG str; endif
      else
         call winmessagebox('"'leftstr(str,len)'"',NO_SLASH__MSG, 16406) -- CANCEL + ICONQUESTION + MB_MOVEABLE
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
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT), 35, 0, 0)   -- WM_PAINT

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: saveas_dlg      syntax:   saveas_dlg                     ³
³                                                                            ³
³ what does it do : ask EPM.EXE to pop up its "Save as" dialog box control.  ³
³                   This is done by posting a EPM_POPOPENDLG message to the  ³
³                   EPM Book window.                                         ³
³                                                                            ³
³                   (All EPM_EDIT_xxx messages are defined in the ETOOLKT    ³
³                    PACKAGE available on PCTOOLS.)                          ³
³                                                                            ³
³ who and when    : Larry M.   6/12/91                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc saveas_dlg
compile if WANT_LONGNAMES='SWITCH'
   universal SHOW_LONGNAMES
compile endif
compile if WANT_LAN_SUPPORT
   if .lockhandle then
      sayerror LOCKED__MSG
      return
   endif
compile endif
   AskIfExists = (arg(1) <> 0)-- new optional arg, 0 => no EXIST_OVERLAY__MSG, used by def f2 if SMARTSAVE
   if not saveas_dlg(name, type, AskIfExists) then
      if leftstr(name,1)='"' & rightstr(name,1)='"' then
         name=substr(name,2,length(name)-2)
      endif
      autosave_name = MakeTempName()
      oldname = .filename
      .filename = name
      if get_EAT_ASCII_value('.LONGNAME')<>'' & upcase(oldname)<>upcase(name) then
         call delete_ea('.LONGNAME')
compile if WANT_LONGNAMES
 compile if WANT_LONGNAMES='SWITCH'
         if SHOW_LONGNAMES then
 compile endif
            .titletext = ''
 compile if WANT_LONGNAMES='SWITCH'
         endif
 compile endif
compile endif  -- WANT_LONGNAMES
      endif
compile if SUPPORT_USER_EXITS
      if isadefproc('rename_exit') then
         call rename_exit(oldname, .filename, 1)
      endif
compile endif
compile if INCLUDE_BMS_SUPPORT
      if isadefproc('BMS_rename_exit') then
         call BMS_rename_exit(oldname, .filename, 1)
      endif
compile endif
      'save'
      if rc then  -- Problem saving?
         call dosmove(autosave_name, MakeTempName())  -- Rename the autosave file
      else
         call erasetemp(autosave_name)
      endif
   endif

defproc saveas_dlg(var name, var type)
   type = copies(\0,255)
   if .filename=GetUnnamedFilename() then
      name = type
   else
      name = leftstr(.filename,255,\0)
   endif
   AskIfExists = (arg(3) = 0)  -- optional 3rd arg, 0: no EXIST_OVERLAY__MSG, used by def f2 if SMARTSAVE

   res= dynalink32( ERES2_DLL,                -- library name
                    'ERESSaveas',              -- function name
                    gethwndc(EPMINFO_EDITCLIENT)  ||
                    gethwndc(APP_HANDLE)          ||
                    address(name)                 ||
                    address(type) )
; Return codes:  0=OK; 1=memory problem; 2=bad string; 3=couldn't load control from DLL
   if res=2 then      -- File dialog didn't like the .filename;
      name = copies(\0,255)  -- try again with no file name
      call dynalink32( ERES2_DLL,                -- library name
                       'ERESSaveas',              -- function name
                       gethwndc(EPMINFO_EDITCLIENT)  ||
                       gethwndc(APP_HANDLE)          ||
                       address(name)                 ||
                       address(type) )
   endif
   parse value name with name \0
   parse value type with type \0
   if name='' then return -275; endif  -- sayerror('Missing filename')
   if exist(name) & AskIfExists then
      if 1<>winmessagebox( SAVE_AS__MSG,
                           name\10\10||EXISTS_OVERLAY__MSG,
                           16417) then -- OKCANCEL + CUANWARNING + MOVEABLE
         return -5  -- sayerror('Access denied')
      endif
   endif
   if type then
      call delete_ea('.TYPE')
      'add_ea .TYPE' type
   endif

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
   call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT),
                      5385,
                      upcase(arg(1))<>'OFF', -- 0 if OFF, else 1
                      0)

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: settitletext                                             ³
³                                                                            ³
³ what does it do : set the text in the editors active title bar.            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc settitletext()
   text = arg(1)

compile if SHOW_MODIFY_METHOD = 'TITLE'
   if .modify then
      text = text || SHOW_MODIFY_TEXT
   endif
compile endif
   .titletext = text

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: WinMessageBox                                            ³
³                                                                            ³
³ what does it do : This routine issues a PM WinMessageBox call, and returns ³
³                   the result.                                              ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defproc winmessagebox(caption, text)

; msgtype = 4096                                        -- must be system modal.
; if arg(3) then
;    msgtype=arg(3) + 4096 * (1 - (arg(3)%4096 - 2 * (arg(3)%8192)))  -- ensure x'1000' on
; endif
  if arg(3) then
     msgtype=arg(3)
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
                     atol(msgtype) )         -- Style

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: Ring_More                                                ³
³                                                                            ³
³ what does it do : This command is called when the More... selection on     ³
³                   the ring menu is selected.  (Or by the Ring action bar   ³
³                   item if MENU_LIMIT = 0.)  It generates a listbox         ³
³                   containing all the filenames, and selects the            ³
³                   appropriate fileid if a filename is selected.            ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc Ring_More
   if filesinring()=1 then
      sayerror ONLY_FILE__MSG
      return
   endif
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5141,               -- EPM_POPRINGDIALOG
                      0,
                      0)

defproc mpfrom2short(mphigh, mplow)
   return ltoa( atoi(mplow) || atoi(mphigh), 10 )

/* Returns the edit window handle, as a 4-digit decimal string. */
defproc gethwnd(w)
;  EditHwnd = getpminfo(w)         /* get edit window handle          */

   /* String handling in E language :                                 */
   /*    EditHwnd = '1235:1234'   <-  address in string form          */
   /*    atol(EditHwnd)= '11GF'   <-  four byte pointer, represented  */
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

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ what's it called: dupmark                                                  ³
³                                                                            ³
³ what does it do : This command is used when a Mark menu item is selected   ³
³                                                                            ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc dupmark
   mt = upcase(arg(1))
   if     mt = 'M' then
;     if marktype() then
         call pmove_mark()
;     else                 -- If no mark, look in Shared Text buffer
;       'GetSharBuff'      -- See clipbrd.e for details
;     endif
   elseif mt = 'C' then
      if marktype() then
         call pcopy_mark()
      else                 -- If no mark, look in Shared Text buffer
         'GetSharBuff'     -- See clipbrd.e for details
      endif
   elseif mt = 'O' then
      if marktype() then
compile if WANT_CHAR_OPS
         call pcommon_adjust_overlay('O')
compile else
         overlay_block
compile endif
      else                 -- If no mark, look in Shared Text buffer
         'GetSharBuff O'   -- See clipbrd.e for details
      endif
   elseif mt = 'A' then
compile if WANT_CHAR_OPS
      call pcommon_adjust_overlay('A')
compile else
      adjustblock
compile endif
   elseif mt = 'U' then
      unmark
      'ClearSharBuff'
   elseif mt = 'U2' then  -- Unmark w/o clearing buffer, for drag/drop
      unmark
   elseif mt = 'D' then  -- Normal delete mark
compile if WANT_DM_BUFFER
      'Copy2DMBuff'        -- See clipbrd.e for details
compile endif  -- WANT_DM_BUFFER
      call pdelete_mark()
      'ClearSharBuff'
   elseif mt = 'D2' then  -- special for drag/drop; only deletes mark w/o touching buffers
      call pdelete_mark()
   elseif mt = 'P' then    -- Print marked area
      call checkmark()     -- verify there is a marked area,
;compile if ENHANCED_PRINT_SUPPORT  -- DUPMARK P is only called if no enhanced print support
;      printer=get_printer()
;      if printer<>'' then 'print' printer; endif
;compile else
      'print'              -- then print it.
;compile endif
   endif

/*
ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
º MENU support.                                                              º
º      EPM's menu support is achieved through the use of the MENU manager.   º
º      This menu manager is located in EUTIL.DLL in versions prior to 5.20;  º
º      in E.DLL for EPM 5.20 and above.  The menu manager contains powerful  º
º      functions that allow an application to create there own named menus.  º
º      Building Menus with the Menu Manager:                                 º
º        The menu manager provides two fuctions which allow the creating     º
º        or replacing of items in a named menu.                              º
º        Note: A menu is first built and then displayed in the window.       º
º        BUILDSUBMENU  - creates or modifies a sub menu                      º
º        BUILDMENUITEM - create  or modifies a menu item under a sub menu    º
º                                                                            º
º      Showing a named Menu                                                  º
º        SHOWMENU      - show the specified named menu in the specified      º
º                        window frame.                                       º
º                                                                            º
º      Deleting a name menu                                                  º
º        DELETEMENU    - remove a named menu from the internal menory        º
º                        manager.                                            º
ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
*/

defexit
   universal defaultmenu

   deletemenu defaultmenu
   defaultmenu=''

/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³What's it called  : processcommand                                           ³
³                                                                             ³
³What does it do   : This command is not called by macros.  It is called by   ³
³                    the internal editor message handler.   When a menu       ³
³                    selected messaged is received by the internal message    ³
³                    handler, (WM_COMMAND) this function is called with       ³
³                    the menu id as a parameter.                              ³
³                                                                             ³
³                                                                             ³
³Who and When      : Jerry C.     3/4/89                                      ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
defc processcommand
   universal activeaccel
   universal activemenu

   menuid = arg(1)
   if menuid='' then
      sayerror PROCESS_ERROR__MSG
      return
   endif

   -- first test if command was generated by the
   -- next/prev buttons on the editor frame.
   if menuid=44 then
      nextfile
   elseif menuid=45 then
      prevfile
   elseif menuid=8101 then  -- Temporarily hardcode this
      'configdlg SYS'
   else
      accelstr=queryaccelstring(activeaccel, menuid)
      if accelstr<>'' then
         accelstr
      else
         if activemenu='' then
;;          sayerror MENU_ERROR__MSG '- ProcessCommand' arg(1)
            return
         endif
         -- execute user string, after stripping off null terminating char
         parse value querymenustring(activemenu,menuid) with command \1 helpstr
         strip(command,'T',\0)
      endif
   endif

compile if    0
defc processaccel
   universal activeaccel
   menuid = arg(1)
   if menuid='' then
      sayerror PROCESS_ERROR__MSG
      return
   endif
   queryaccelstring(activeaccel, menuid)
compile endif

defc processmenuselect  -- Called when a menu item is activated; used for prompting
compile if INCLUDE_MENU_SUPPORT
   universal activemenu
 compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
 compile endif

   universal previouslyactivemenu
   parse arg menutype menuid .
;  if menutype = 'A' & previouslyactivemenu<>'' then
;  if (menuid < 80 | menuid >= 100) & menuid <> '' & previouslyactivemenu<>'' then  -- Temp kludge
   if menuid < 80 & menuid <> '' & previouslyactivemenu<>'' then  -- Temp kludge
      activemenu = previouslyactivemenu
      previouslyactivemenu = ''
   endif
 compile if WANT_DYNAMIC_PROMPTS
   if menuid='' | activemenu='' | not menu_prompt then
      sayerror 0
      return
   endif
   parse value querymenustring(activemenu,menuid) with command \1 helpstr
   if helpstr<>'' then
      display -8
      sayerror helpstr
      display 8
   else
      sayerror 0
   endif
 compile else
   sayerror 0
 compile endif  -- WANT_DYNAMIC_PROMPTS
compile endif  -- INCLUDE_MENU_SUPPORT

; Note:  this routine does *not* get called when Command (menuid 1) is selected.
defc PROCESSMENUINIT  -- Called when a pulldown or pullright is initialized.
compile if INCLUDE_MENU_SUPPORT
   universal activemenu, defaultmenu
   universal EPM_utility_array_ID
compile if WANT_DYNAMIC_PROMPTS
   universal menu_prompt
compile endif
   universal lastchangeargs
compile if WANT_STACK_CMDS
   universal mark_stack, position_stack
 compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
 compile endif
compile endif
compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
compile endif
compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
compile endif
compile if RING_OPTIONAL
   universal ring_enabled
compile endif
compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
compile endif
compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
compile endif

   if activemenu<>defaultmenu then
      return
   endif
   menuid = arg(1)
compile if defined(SITE_MENUINIT) & not VANILLA
 compile if SITE_MENUINIT
   include SITE_MENUINIT
 compile endif
compile endif
   if isadefc('menuinit_'menuid) then
;  -- Bug?  Above doesn't work...
;  tmp = 'menuinit_'menuid
;  if isadefc(tmp) then
      'menuinit_'menuid
      return
   endif
compile if not VANILLA
   tryinclude 'mymnuini.e'  -- For user-supplied additions to this routine.
compile endif

; The following is individual commands on 5.51+; all part of ProcessMenuInit cmd on earlier versions.
compile if not defined(STD_MENU_NAME)
--------------------------------------------- Menu id 8 -- Edit -------------------------
defc menuinit_8
 compile if WANT_STACK_CMDS
   universal mark_stack, position_stack
  compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
  compile endif
 compile endif  -- WANT_STACK_CMDS
      SetMenuAttribute( 816, 16384, isadirtyline())
      undoaction 1, PresentState        -- Do to fix range, not for value.
      undoaction 6, StateRange               -- query range
      parse value staterange with oldeststate neweststate .
      SetMenuAttribute( 818, 16384, oldeststate<>neweststate )  -- Set to 1 if different
      paste = clipcheck(format) & (format=1024) & not (browse() | .readonly)
      SetMenuAttribute( 810, 16384, paste)
      SetMenuAttribute( 811, 16384, paste)
      SetMenuAttribute( 812, 16384, paste)
      on = marktype()<>''
      buf_flag = 0
      if not on then                             -- Only check buffer if no mark
         bufhndl = buffer(OPENBUF, EPMSHAREDBUFFER)
         if bufhndl then                         -- If the buffer exists, check the
            buf_flag=itoa(peek(bufhndl,2,2),10)  -- amount of used space in buffer
            call buffer(FREEBUF, bufhndl)        -- then free it.
         endif
      endif
      SetMenuAttribute( 800, 16384, on | buf_flag)  -- Can copy if mark or buffer has data
      SetMenuAttribute( 801, 16384, on)
      SetMenuAttribute( 802, 16384, on | buf_flag)  -- Ditto for Overlay mark
      SetMenuAttribute( 803, 16384, on)
      SetMenuAttribute( 805, 16384, on)
      SetMenuAttribute( 806, 16384, on)
      SetMenuAttribute( 808, 16384, on)
      SetMenuAttribute( 809, 16384, on)
      SetMenuAttribute( 814, 16384, on)
 compile if WANT_STACK_CMDS
  compile if WANT_STACK_CMDS = 'SWITCH'
   if stack_cmds then
  compile endif
      SetMenuAttribute( 820, 16384, on)
      SetMenuAttribute( 821, 16384, mark_stack<>'')
      SetMenuAttribute( 822, 16384, on & mark_stack<>'')
      SetMenuAttribute( 824, 16384, position_stack<>'')
      SetMenuAttribute( 825, 16384, position_stack<>'')
  compile if WANT_STACK_CMDS = 'SWITCH'
   endif
  compile endif
 compile endif  -- WANT_STACK_COMMANDS

--------------------------------------------- Menu id 4 -- Options ---------------------
defc menuinit_4
 compile if RING_OPTIONAL
   universal ring_enabled
 compile endif
 compile if CHECK_FOR_LEXAM
   universal LEXAM_is_available
 compile endif
 compile if RING_OPTIONAL
      if ring_enabled then
 compile endif
         SetMenuAttribute( 410, 16384, filesinring()>1)
 compile if RING_OPTIONAL
      endif
 compile endif
 compile if SPELL_SUPPORT
  compile if CHECK_FOR_LEXAM
    if LEXAM_is_available then
  compile endif
      SetMenuAttribute( 450, 8192, .keyset <> 'SPELL_KEYS')
  compile if CHECK_FOR_LEXAM
    endif
  compile endif
 compile endif  -- SPELL_SUPPORT

 compile if WANT_CUA_MARKING = 'SWITCH' | WANT_STREAM_MODE = 'SWITCH' | RING_OPTIONAL | WANT_STACK_CMDS = 'SWITCH'
--------------------------------------------- Menu id 400 -- Options / Preferences -------
defc menuinit_400
  compile if WANT_STACK_CMDS = 'SWITCH'
   universal stack_cmds
  compile endif
  compile if WANT_CUA_MARKING = 'SWITCH'
   universal CUA_marking_switch
  compile endif
  compile if WANT_STREAM_MODE = 'SWITCH'
   universal stream_mode
  compile endif
  compile if RING_OPTIONAL
   universal ring_enabled
  compile endif
  compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
   universal CUA_MENU_ACCEL
  compile endif
  compile if WANT_CUA_MARKING = 'SWITCH'
      SetMenuAttribute( 441, 8192, CUA_marking_switch)
  compile endif
  compile if WANT_STREAM_MODE = 'SWITCH'
      SetMenuAttribute( 442, 8192, not stream_mode)
  compile endif
  compile if RING_OPTIONAL
      SetMenuAttribute( 443, 8192, not ring_enabled)
  compile endif
  compile if WANT_STACK_CMDS = 'SWITCH'
      SetMenuAttribute( 445, 8192, not stack_cmds)
  compile endif
  compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH'
    SetMenuAttribute( 446, 8192, not CUA_MENU_ACCEL)
  compile endif
 compile endif  -- WANT_CUA_MARKING, WANT_STREAM_MODE, RING_OPTIONAL, WANT_STACK_CMDS

--------------------------------------------- Menu id 425 -- Options / Frame controls  ---
defc menuinit_425
   universal bitmap_present
 compile if RING_OPTIONAL
      universal ring_enabled
 compile endif
 compile if WANT_DYNAMIC_PROMPTS
      universal menu_prompt
 compile endif
      SetMenuAttribute( 413, 8192, not queryframecontrol(1) )
      SetMenuAttribute( 414, 8192, not queryframecontrol(2) )
      SetMenuAttribute( 415, 8192, not queryframecontrol(16))
 compile if RING_OPTIONAL
      if ring_enabled then
 compile endif
         SetMenuAttribute( 417, 8192, not queryframecontrol(4))
 compile if WANT_TOOLBAR
         SetMenuAttribute( 430, 8192, not queryframecontrol(EFRAMEF_TOOLBAR))
 compile endif
         SetMenuAttribute( 437, 8192, not bitmap_present)
 compile if RING_OPTIONAL
      else
         SetMenuAttribute( 417, 16384, 1)  -- Grey out Rotate Buttons if ring not enabled
      endif
 compile endif
      SetMenuAttribute( 421, 8192, not queryframecontrol(32))
 compile if WANT_DYNAMIC_PROMPTS
      SetMenuAttribute( 422, 8192, not menu_prompt)
 compile endif

--------------------------------------------- Menu id 3 -- Search -----------------------
defc menuinit_3
      universal lastchangeargs
      getsearch strng
      parse value strng with . c .       -- blank, 'c', or 'l'
      SetMenuAttribute( 302, 16384, c<>'')               -- Find next OK if not blank
      SetMenuAttribute( 303, 16384, lastchangeargs<>'')  -- Change next only if 'c'
      SetMenuAttribute( 350, 16384, c<>'')               -- Global find next OK if not blank
      SetMenuAttribute( 351, 16384, lastchangeargs<>'')  -- Global change next only if 'c'
      SetMenuAttribute( 352, 16384, c<>'')               -- Toggle direction OK if not blank

 compile if WANT_BOOKMARKS
--------------------------------------------- Menu id 3 -- Bookmarks --------------------
defc menuinit_305
      universal EPM_utility_array_ID
      --do_array 3, EPM_utility_array_ID, 'bmi.0', bmcount          -- Index says how many bookmarks there are
      rc = get_array_value( EPM_utility_array_ID, 'bmi.0', bmcount )          -- Index says how many bookmarks there are
      SetMenuAttribute( 306, 16384, not (browse() | .readonly))  -- Set
      SetMenuAttribute( 308, 16384, bmcount>0)   -- List
      SetMenuAttribute( 311, 16384, bmcount>0)   -- Next
      SetMenuAttribute( 312, 16384, bmcount>0)   -- Prev
 compile endif  -- WANT_BOOKMARKS

; Also will need to handle 204 (Name) on File menu if 5.60 & LaMail...

compile endif -- not defined(STD_MENU_NAME)

--------------------------------------------- Menu id 0 -- Command ----------------------
; This is not called by entering the Command menu if menu id = 1. Changing the menu id
; to e.g. 0 will make it. Apperently 'processmenuinit' is not executed for menu id = 1.
; The id must be changed in:
;    -  STDMENU.E: defproc add_command_menu
; Since in FEVSHMNU.E the file menu gets the id = 1 and the shell actions are defined
; as submenuitems of File->Command, following is not important:
;    -  EPMSHELL.E: defc shell if WANT_EPM_SHELL='HIDDEN' & not defined(STD_MENU_NAME).
; Unfortunately the command name includes the id. Maybe we'll change this in future.
defc menuinit_0
compile if WANT_EPM_SHELL & INCLUDE_STD_MENUS
   universal shell_index
   if shell_index then
      is_shell = leftstr(.filename, 15) = ".command_shell_"
 compile if not defined(STD_MENU_NAME)
      SetMenuAttribute( 103, 16384, is_shell)  -- 'shell_write'
      SetMenuAttribute( 104, 16384, is_shell)  -- 'shell_break'
 compile elseif STD_MENU_NAME = 'ovshmenu.e'
      SetMenuAttribute( 152, 16384, is_shell)  -- 'shell_write'
      SetMenuAttribute( 153, 16384, is_shell)  -- 'shell_break'
 compile elseif STD_MENU_NAME = 'fevshmnu.e'
      SetMenuAttribute( 142, 16384, is_shell)  -- 'shell_write'
      SetMenuAttribute( 143, 16384, is_shell)  -- 'shell_break'
 compile endif
   endif  -- shell_index
compile endif

; The above is all part of ProcessMenuInit cmd on old versions.  -----------------
compile endif  -- INCLUDE_MENU_SUPPORT, at defc processmenuinit

defproc SetMenuAttribute( menuid, attr, on)
;  universal EditMenuHwnd
;  if not EditMenuHwnd then
;     EditMenuHwnd = getpminfo(EPMINFO_EDITMENUHWND)  -- cache; relatively expensive to obtain.
;  endif
   if not on then
      attr=mpfrom2short(attr, attr)
   endif
   call windowmessage(1,
;                     EditMenuHwnd,  -- Doesn't work; EditMenuHwnd changes.
                      getpminfo(EPMINFO_EDITMENUHWND),
                      402,
                      menuid + 65536,
                      attr)

defc processname =
   newname = arg(1)
   if newname<>'' & newname<>.filename then
compile if defined(PROCESSNAME_CMD)  -- Let the user override this, if desired.
      PROCESSNAME_CMD newname
compile else
      'name' newname
compile endif
   endif

; Moved defc undo to UNDO.E

defc popbook =
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      13,                   -- WM_ACTIVATE
                      1,
                      getpminfo(APP_HANDLE))

defc printdlg
   call windowmessage(0,
                      getpminfo(APP_HANDLE),
                      5144,               -- EPM_PRINTDLG
                      arg(1)='M',
                      0)

defc printfile
   if arg(1)<>'' then
      'xcom save /s /ne' arg(1)  -- Save the file to the printer
   endif

defc process_qprint
compile if EPM_POINTER = 'SWITCH'
   universal vEPM_POINTER
compile endif
   if arg(1)='' then
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
   w = wordpos(upcase(what), 'M M! F F! !')
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
                      put_in_buffer(queue_name) )

compile if WANT_CUA_MARKING = 'SWITCH'
defc CUA_mark_toggle
   universal CUA_marking_switch
   CUA_marking_switch = not CUA_marking_switch
   'togglecontrol 25' CUA_marking_switch
 compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 441, 8192, CUA_marking_switch)
 compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS
   call MH_set_mouse()
compile endif

compile if WANT_STREAM_MODE = 'SWITCH'
defc stream_toggle
   universal stream_mode
   stream_mode = not stream_mode
   'togglecontrol 24' stream_mode
 compile if WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 442, 8192, not stream_mode)
 compile endif  -- WANT_NODISMISS_MENUS & INCLUDE_STD_MENUS
compile endif

compile if RING_OPTIONAL
defc ring_toggle
   universal ring_enabled
   universal activemenu, defaultmenu
   ring_enabled = not ring_enabled
   'toggleframe 4' ring_enabled
 compile if INCLUDE_STD_MENUS
  compile if not defined(STD_MENU_NAME)
   deletemenu defaultmenu, 2, 0, 1                  -- Delete the file menu
   call add_file_menu(defaultmenu)
   deletemenu defaultmenu, 4, 0, 1                  -- Delete the options menu
   call add_options_menu(defaultmenu, dos_version()>=1020)
   call maybe_show_menu()
  compile elseif STD_MENU_NAME = 'ovshmenu.e'
   deletemenu defaultmenu, 1, 0, 1                  -- Delete the file menu
   call add_file_menu(defaultmenu)
   deletemenu defaultmenu, 2, 0, 1                  -- Delete the view menu
   call add_view_menu(defaultmenu)
   call maybe_show_menu()
  compile endif
 compile endif  -- INCLUDE_STD_MENUS
compile endif

compile if WANT_STACK_CMDS = 'SWITCH'
defc stack_toggle
   universal stack_cmds
   universal activemenu, defaultmenu
   stack_cmds = not stack_cmds
 compile if INCLUDE_STD_MENUS
  compile if not defined(STD_MENU_NAME)
   deletemenu defaultmenu, 8, 0, 1                  -- Delete the edit menu
   call add_edit_menu(defaultmenu)
   call maybe_show_menu()
  compile elseif STD_MENU_NAME = 'ovshmenu.e'
   deletemenu defaultmenu, 2, 0, 1                  -- Delete the view menu
   call add_view_menu(defaultmenu)
   deletemenu defaultmenu, 3, 0, 1                  -- Delete the selected menu
   call add_selected_menu(defaultmenu)
   call maybe_show_menu()
  compile endif
 compile endif  -- INCLUDE_STD_MENUS
compile endif

compile if BLOCK_ACTIONBAR_ACCELERATORS = 'SWITCH' & INCLUDE_STD_MENUS
defc accel_toggle
   universal CUA_MENU_ACCEL
   universal activemenu, defaultmenu
   CUA_MENU_ACCEL = not CUA_MENU_ACCEL
   deleteaccel 'defaccel'
   'loadaccel'
 compile if not defined(STD_MENU_NAME)
   deletemenu defaultmenu, 8, 0, 1                  -- Delete the edit menu
   call add_edit_menu(defaultmenu)
   if activemenu=defaultmenu  then
  compile if 0   -- Don't need to actually show the menu; can just update the affected text.
      showmenu activemenu
  compile else
      call update_edit_menu_text()
  compile endif
   endif
 compile elseif STD_MENU_NAME = 'ovshmenu.e'
   deletemenu defaultmenu, 3, 0, 1                  -- Delete the selected menu
   call add_selected_menu(defaultmenu)
   if activemenu=defaultmenu  then
  compile if 0   -- Don't need to actually show the menu; can just update the affected text.
      showmenu activemenu
  compile else
      call update_edit_menu_text()
  compile endif
   endif
 compile endif
 compile if WANT_NODISMISS_MENUS & not defined(STD_MENU_NAME)
   SetMenuAttribute( 446, 8192, not CUA_MENU_ACCEL)
 compile endif  -- WANT_NODISMISS_MENUS
compile endif

defc helpmenu   -- send EPM icon window a help message.
   call windowmessage(0,  getpminfo(APP_HANDLE),
                      5133,      -- EPM_HelpMgrPanel
                      arg(1),    -- mp1 = 0=Help for help, 1=index; 2=TOC; 256... =panel #
                      0)         -- mp2 = NULL

defc ibmmsg
   ever = EVERSION
   if \0 = rightstr(EVERSION,1) then
      ever=leftstr(EVERSION,length(eversion)-1)
   endif
   call WinMessageBox( EDITOR__MSG,
                       EDITOR_VER__MSG ver(0)\13 ||
                       MACROS_VER__MSG ever\13\13 ||
                       COPYRIGHT__MSG,
                       16384 )

defproc LoadVersionString(var buff, var modname)
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

   buff = copies(\0, 255)
   res= dynalink32('PMWIN',
                   '#781',  -- Win32LoadString
                   gethwndc(EPMINFO_HAB)  ||
                   hmodule                ||  -- NULLHANDLE
                   atol(65535)            ||  -- IDD_BUILDDATE
                   atol(length(buff))     ||
                   address(buff), 2 )
   buff = leftstr(buff, res)

   if arg(3) then
      modname = copies(\0, 260)
      call dynalink32('DOSCALLS',         -- dynamic link library name
                      '#320',                    -- DosQueryModuleName
                      hmodule               ||   -- module handle
                      atol(length(modname)) ||   -- Buffer length
                      address(modname) )         -- Module we've loading
      call dynalink32('DOSCALLS',
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
   call WinMessageBox("EPM Build", EDITOR_VER__MSG ver(0)\13MACROS_VER__MSG EVERSION\13'('wheredefc('versioncheck')')'\13\13'EPM.EXE' buff\13E_DLL'.DLL' buffe\13ERES2_DLL'.DLL' buffr\13ERES_DLL'.DLL' buffc\13\13COPYRIGHT__MSG, 16384)

defc versioncheck_file =
   'xcom e /c /q tempfile'
   if rc<>-282 then  -- sayerror('New file')
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   .autosave = 0
   .filename = "EPM Build"
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
   if string='' then                   -- Was a string given?
      return 0                         -- If not, return a null pointer.
   endif
   if arg(2)='' then
      share=83  -- PAG_READ | PAG_WRITE | PAG_COMMIT | OBJ_TILE
   else
      share=arg(2)
   endif
   strbuffer = "????"                  -- Initialize string pointer.
   r =  dynalink32( 'DOSCALLS',          -- Dynamic link library name
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
   activeaccel='defaccel'
compile if INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS
                       -- Help key
;; buildacceltable activeaccel, 'helpmenu 4000', AF_VIRTUALKEY, VK_F1, 1000
   buildacceltable activeaccel, 'dokey s+F1', AF_VIRTUALKEY+AF_SHIFT, VK_F1, 1000

   call build_menu_accelerators(activeaccel)  -- Moved to menu-specific file
compile endif -- INCLUDE_MENU_SUPPORT & INCLUDE_STD_MENUS

   buildacceltable activeaccel, 'Alt_enter 1', AF_VIRTUALKEY+AF_ALT,  VK_NEWLINE, 1080  -- Alt+Enter
   buildacceltable activeaccel, 'Alt_enter 2', AF_VIRTUALKEY+AF_ALT,    VK_ENTER, 1081  -- Alt+PadEnter
   buildacceltable activeaccel, 'Alt_enter 3', AF_VIRTUALKEY+AF_SHIFT,VK_NEWLINE, 1082  -- Shift+Enter
   buildacceltable activeaccel, 'Alt_enter 4', AF_VIRTUALKEY+AF_SHIFT,  VK_ENTER, 1083  -- Shift+PadEnter

compile if defined(BLOCK_ALT_KEY)
   -- don't want Alt or AltGr switch to menu (PM-defined key F10 does the same)
;  buildacceltable activeaccel, 'beep 2000 50', AF_VIRTUALKEY+AF_LONEKEY, VK_ALT, 1020
;  buildacceltable activeaccel, 'beep 2000 50', AF_VIRTUALKEY+AF_LONEKEY, VK_ALTGRAF, 1021
   -- who wants beeps instead?
   buildacceltable activeaccel, '', AF_VIRTUALKEY+AF_LONEKEY, VK_ALT, 1020
   buildacceltable activeaccel, '', AF_VIRTUALKEY+AF_LONEKEY, VK_ALTGRAF, 1021
compile endif

   activateacceltable activeaccel

compile if defined(BLOCK_ALT_KEY)
defc beep = a=arg(1); do while a<>''; parse value a with pitch duration a; call beep(pitch, duration); enddo
compile endif

defc alt_enter =
compile if ENHANCED_ENTER_KEYS & ENTER_ACTION <> ''  -- define each key separately
   universal a_enterkey, a_padenterkey, s_enterkey, s_padenterkey
   call enter_common(substr(a_enterkey||a_padenterkey||s_enterkey||s_padenterkey,arg(1),1))
compile else
   executekey enter
compile endif

defc dokey
   executekey resolve_key(arg(1))

defc keyin
   keyin arg(1)


defc rename
   name = .filename
   if name=GetUnnamedFilename() then name=''; endif
   parse value entrybox( RENAME__MSG,
                         '',
                         name,
                         0,
                         240,
                         -- atoi(1) || atoi(0) || gethwndc(APP_HANDLE) ||
                         atoi(1) || atoi(0) || atol(0) ||
                         RENAME_PROMPT__MSG '<' directory() '>') with button 2 name \0
   if button=\1 & name<>'' then 'name' name; endif

defc maybe_reflow_ALL
   do i = 1 to .last
      if textline(i)<>'' then  -- Only ask if there's text in the file.
         if askyesno(REFLOW_ALL__MSG,1) = YES_CHAR then
            'reflow_all'
         endif
         leave
      endif
   enddo

defc edit_list =
   getfileid startfid
   firstloaded = startfid
   parse arg list_sel list_ofs .
   orig_ofs = list_ofs
   do forever
      list_ptr = peek(list_sel, list_ofs, 4)
      if list_ptr == \0\0\0\0 then leave; endif
      fn = peekz(list_ptr)
      if pos(' ', fn) then
         fn = '"'fn'"'
      endif
      'e' fn
      list_ofs = list_ofs + 4
      if startfid = firstloaded then
         getfileid firstloaded
      endif
   enddo
compile if 1  -- Now, the macros free the buffer.
   call buffer(FREEBUF, list_sel)
compile else
   call windowmessage(1,  getpminfo(EPMINFO_OWNERCLIENT),   -- Send message to owner client
                      5486,               -- Tell it to free the buffer.
                      mpfrom2short(list_sel, orig_ofs),
                      0)
compile endif
   activatefile firstloaded

; Moved defc setstusline to STATLINE.E

; Called with a string to set the messageline text to that string; with no argument
; to just set the messageline color.
defc setmessageline
   universal vMESSAGECOLOR
   if arg(1) then
      template=atoi(length(arg(1))) || arg(1)
      template_ptr=put_in_buffer(template)
   else
      template_ptr=0
   endif
   call windowmessage(1,  getpminfo(EPMINFO_EDITCLIENT),
                      5432,      -- EPM_FRAME_MESSAGELINE
                      template_ptr,
                      vMESSAGECOLOR)

defc new
   getfileid startfid
   'xcom e /n'
   if rc<>-282 then return; endif  -- sayerror 'New file'
   getfileid newfid
   activatefile startfid
   temp = startfid  -- temp fix for some bug
   'quit'
   getfileid curfid
   activatefile newfid
   if curfid=startfid then  -- Wasn't quit; user must have said Cancel to Quit dlg
      'xcom quit'
   endif

;compile if SUPPORT_USERS_GUIDE | SUPPORT_TECHREF
defc viewword  -- arg(1) is name of .inf file
   if find_token(startcol, endcol) then
      InfFile = arg(1)
      -- resolve OS/2 environment vars
      InfFile = NepmdResolveEnvVars(InfFile)
      --sayerror 'InfFile = 'arg(1)', InfFile with EnvVars resolved = 'InfFile
      -- specifying the extension is optional
      if upcase( rightstr( InfFile, 4 ) ) <> '.INF' then
         InfFile = InfFile'.inf'
      endif
      findfile fully_qualified, InfFile, 'BOOKSHELF'
      if rc then
         sayerror FILE_NOT_FOUND__MSG '"'InfFile'"'
         return
      endif
      'view' InfFile substr(textline(.line), startcol, (endcol-startcol)+1)
   endif
;compile endif

defc cascade_menu
   parse arg menuid defmenuid .
   menuitem = copies(\0, 16)  -- 2 bytes ea. pos'n, style, attribute, identity; 4 bytes submenu hwnd, long item
   if not windowmessage(1,
                        getpminfo(EPMINFO_EDITMENUHWND),
                        386,                  -- x182, MM_QueryItem
                        menuid + 65536,
                        ltoa(offset(menuitem) || selector(menuitem), 10) )
   then return; endif
   hwnd = substr(menuitem, 9, 4)
   call dynalink32('PMWIN',
                   '#874',     -- Win32SetWindowBits
                    hwnd          ||
                    atol(-2)      ||  -- QWL_STYLE
                    atol(64)      ||  -- MS_CONDITIONALCASCADE
                    atol(64) )        -- MS_CONDITIONALCASCADE
   if defmenuid<>'' then  -- Default menu item
      call windowmessage(1,
                         ltoa(hwnd,10),
                         1074,                  -- x432, MM_SETDEFAULTITEMID
                         defmenuid, 0)  -- Make arg(2) the default menu item
   endif

compile if 0
defc QueryHLP = sayerror '"'QueryCurrentHLPFiles()'"'
defproc QueryCurrentHLPFiles()
   universal CurrentHLPFiles;
   return CurrentHLPFiles;

defc setHLP = sayerror '"'SetCurrentHLPFiles(arg(1))'"'
defproc SetCurrentHLPFiles(newlist)
   universal CurrentHLPFiles;
   hwndHelpInst = windowmessage(1,  getpminfo(APP_HANDLE),
                      5429,      -- EPM_Edit_Query_Help_Instance
                      0,
                      0)
   if hwndHelpInst==0 then
      -- there isn't a help instance deal with.
      return "No Help Instance";
   endif

   newlist2 = newlist || chr(0);
   retval = windowmessage(1,  hwndHelpInst,
                       557,    -- HM_SET_HELP_LIBRARY_NAME
                       ltoa(offset(newlist2) || selector(newlist2), 10),
                       0)
   if retval==0 then
      -- it worked, now remember what you told it.
      CurrentHLPFiles = newlist;
   else
      -- failed for some reason, anyway, we had better revert to
      --   the previous version of the HLP list.
      if CurrentHLPFiles=="" then
         CurrentHLPFiles = " ";
      endif
      newlist2 = CurrentHLPFiles || chr(0);
      retval2 = windowmessage(1,  hwndHelpInst,
                          557,    -- HM_SET_HELP_LIBRARY_NAME
                          ltoa(offset(newlist2) || selector(newlist2), 10),
                          0)
      if retval2==0 then
         -- whew, we were able to revert to the old list
         return retval;
      else
         return "two errors" retval retval2;
      endif
   endif

compile endif

compile if    KEEP_CURSOR_ON_SCREEN
-- This should move the cursor at the end of every scroll bar action.  The
-- position to which it is moved should correspond to the location of the
-- cursor (relative to the window) at the time when the scroll began.

defc processendscroll
   universal beginscroll_x, beginscroll_y;
   .cursorx = beginscroll_x;
   .cursory = beginscroll_y;
   if not .line & .last then .lineg=1; endif

defc processbeginscroll
   universal beginscroll_x, beginscroll_y;
   beginscroll_x = .cursorx;
   beginscroll_y = .cursory;
compile endif  -- KEEP_CURSOR_ON_SCREEN

defc setpresparam
   universal statfont, msgfont
   universal vSTATUSCOLOR, vMESSAGECOLOR, vDESKTOPColor
   parse value arg(1) with whichctrl " hwnd="hwnd " x="x "y="y rest
   if (whichctrl=="STATFONTSIZENAME") or (whichctrl=="MSGFONTSIZENAME") then
      parse value rest with "string="psize"."facename"."attr
      -- psize is pointsize, facename is facename, attr is "Bold" etc
      "setstatface" hwnd facename
      "setstatptsize" hwnd psize
      if leftstr(whichctrl,1)='S' then  -- "STATFONTSIZENAME"
         statfont = substr(rest,8)
      else                              -- "MSGFONTSIZENAME"
         msgfont = substr(rest,8)
         sayerror MESSAGELINE_FONT__MSG
      endif
   elseif (whichctrl=="STATFGCOLOR") or (whichctrl=="MSGFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage(0,  hwnd,
                         4099,      -- STATWNDM_SETCOLOR
                         clrattr,
                         oldbgattr)
      if leftstr(whichctrl,1)='M' then
         sayerror MESSAGELINE_FGCOLOR__MSG
         vMESSAGECOLOR = clrattr + 16 * oldbgattr
      else
         vSTATUSCOLOR = clrattr  + 16 * oldbgattr
      endif
   elseif (whichctrl=="STATBGCOLOR") or (whichctrl=="MSGBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      call windowmessage(0,  hwnd,
                         4099,      -- STATWNDM_SETCOLOR
                         oldfgattr,
                         clrattr)
      if leftstr(whichctrl,1)='M' then
         sayerror MESSAGELINE_BGCOLOR__MSG
         vMESSAGECOLOR = clrattr * 16 + oldfgattr
      else
         vSTATUSCOLOR = clrattr  * 16 + oldfgattr
      endif
   elseif (whichctrl=="EDITBGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      map_point 5, x, y, off, comment;  -- map screen to line
      if x<1 | x>.last then
         vDESKTOPColor = clrattr
         call windowmessage(0, getpminfo(EPMINFO_EDITCLIENT), 5497, clrattr, 0)
      else
         .textcolor = (.textcolor // 16) + 16 * clrattr;
      endif
   elseif (whichctrl=="EDITFGCOLOR") then
      parse value rest with "rgb="rgb "clrattr="clrattr "oldfgattr="oldfgattr "oldbgattr="oldbgattr
      .textcolor = .textcolor - (.textcolor // 16) + clrattr;
   elseif whichctrl=="EDITFONTSIZENAME" then
      parse value rest with "string="psize"."facename"."attr
      -- psize is pointsize, facename is facename, attr is "Bold" etc
      fontsel = 0
      do while attr<>''
         parse value attr with thisattr '.' attr
         if     thisattr='Italic'     then fontsel = fontsel + 1
         elseif thisattr='Underscore' then fontsel = fontsel + 2
         elseif thisattr='Outline'    then fontsel = fontsel + 8
         elseif thisattr='Strikeout'  then fontsel = fontsel + 16
         elseif thisattr='Bold'       then fontsel = fontsel + 32
         endif
      enddo
      .font = registerfont(facename ,psize, fontsel)
   else
      sayerror UNKNOWN_PRESPARAM__MSG  whichctrl
      return;
   endif
;   sayerror "set presparm with" hwnd " as the window" arg(1);

defc setstatface
   parse value arg(1) with hwnd face
   return windowmessage(0,  hwnd /*getpminfo(EPMINFO_EDITFRAME)*/,   -- Post message to edit client
                        4104,        -- STATWNDM_PREFFONTFACE
                        put_in_buffer(face),
                        1);  -- COMMAND_FREESEL

defc setstatptsize
   parse value arg(1) with hwnd ptsize
   if leftstr(ptsize, 1) = 'D' then  -- Decipoints
      parse value ptsize with 'DD' ptsize 'HH'
      parse value ptsize with ptsize 'WW'
      ptsize = ptsize % 10   -- convert decipoints to points
   endif
   return windowmessage(0,  hwnd /*getpminfo(EPMINFO_EDITFRAME)*/,   -- Post message to edit client
                        4106,        -- STATWNDM_PREFFONTPTSIZE
                        ptsize,
                        0);


defproc Thunk(pointer)
  return atol_swap(dynalink32(E_DLL,
                              'FlatToSel',
                              pointer, 2) )

; EPM_EA.E in now included in EPM.E

defc echoback
   parse arg postorsend hwnd messageid mp1 mp2 .
   call windowmessage(postorsend,
                      hwnd,
                      messageid,
                      mp1,
                      mp2)

; all toolbar definitions moved to TOOLBAR.E

defc toggle_parse
   universal EPM_utility_array_ID
   parse arg parseon kwfilename
   if parseon & .levelofattributesupport//2=0  then  -- the first bit of .levelofattributesupport is for color attributes
      call attribute_on(1) -- toggles color attributes mode
   endif
   if kwfilename='' then
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

   call windowmessage(0,  getpminfo(EPMINFO_EDITFRAME),
                      5502,               -- EPM_EDIT_TOGGLEPARSE
                      parseon,
                      put_in_buffer(fid kwfilename))
compile if 0
defc qparse =
   c =  windowmessage(1,  getpminfo(EPMINFO_EDITFRAME),
                      5505,               -- EPM_EDIT_KW_QUERYPARSE
                      0,
                      0)
   sayerror 'Keyword parsing is' word(OFF__MSG ON__MSG, 2 - (not c))  -- Use as boolean
compile endif

defc dyna_cmd =
   parse arg library entrypoint cmdargs
   if entrypoint='' then
      sayerror -257  -- "Invalid number of parameters"
      return
   endif
   rc = 0
   cmdargs = cmdargs\0
   dynarc = dynalink32(library,
                       entrypoint,
                       gethwndc(EPMINFO_EDITCLIENT) ||
                       address(cmdargs),
                       2)

defc dynafree =
   res = dynafree(arg(1))
   if res then
      sayerror ERROR__MSG res
   endif
