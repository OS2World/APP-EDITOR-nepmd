/****************************** Module Header *******************************
*
* Module Name: bookmark.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: bookmark.e,v 1.6 2003-05-14 16:21:33 aschn Exp $
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
; This file adds bookmark support to EPM.  It can be linked in or included
; in the base .ex file.  WANT_ATTRIBUTE_SUPPORT must have been set when compiling
; the base if this is to be linked in, because DEFLOAD and DEFC SAVE have hooks
; to call routines defined herein.

compile if not defined(SMALL)  -- Being compiled separately
include 'stdconst.e'
 define INCLUDING_FILE = 'BOOKMARK.E'
tryinclude 'MYCNF.E'
 compile if not defined(SITE_CONFIG)
    const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
    tryinclude SITE_CONFIG
 compile endif
 compile if not defined(INCLUDE_WORKFRAME_SUPPORT)
   const INCLUDE_WORKFRAME_SUPPORT = 1
 compile endif
 compile if not defined(INCLUDE_STD_MENUS)
   const INCLUDE_STD_MENUS = 1
 compile endif
 compile if not defined(WANT_APPLICATION_INI_FILE)
   const WANT_APPLICATION_INI_FILE = 1
 compile endif
 compile if not defined(NLS_LANGUAGE)
  const NLS_LANGUAGE = 'ENGLISH'
 compile endif
include NLS_LANGUAGE'.e'
compile endif

const
   COLOR_CLASS      =  1
   PAGEBREAK_CLASS =  6
   BOOKMARK_CLASS  = 13
   STYLE_CLASS      = 14
   FONT_CLASS       = 16
   EAT_ASCII    = \253\255    -- FFFD
   EAT_MVST     = \222\255    -- FFDE
compile if not defined(COMPILER_ERROR_COLOR)
   COMPILER_ERROR_COLOR = 244  -- red + whiteb = 4 + 240
compile endif
compile if not defined(NO_DUPLICATE_BOOKMARKS)
   NO_DUPLICATE_BOOKMARKS = 0
compile endif
compile if not defined(SORT_BOOKMARKS)
   SORT_BOOKMARKS = 0
compile endif

compile if 0  -- Menu now added in STDCTRL.E
definit
   universal defaultmenu, activemenu
   buildsubmenu defaultmenu, 29, 'Bookmarks',             '',               0, 0
     buildmenuitem defaultmenu, 29, 2901, '~Set...',           'setmark',        0, 0
     buildmenuitem defaultmenu, 29, 2902, 'Set ~permanent...', 'setmarkp',       0, 0
     buildmenuitem defaultmenu, 29, 2903, '~List...',          'listmark',       0, 0
     buildmenuitem defaultmenu, 29, 2904, '~Delete...',        'listdeletebm',   0, 0
     buildmenuitem defaultmenu, 29, 2905, \0,                  '',               4, 0
     buildmenuitem defaultmenu, 29, 2906, 'Sa~ve BM as EA',    'saveattributes', 0, 0
     buildmenuitem defaultmenu, 29, 2907, 'L~oad BM from EA',  'loadattributes', 0, 0
   if activemenu=defaultmenu  then
      showmenu activemenu
   endif
compile endif

defc bm, setmark
   universal EPM_utility_array_ID
   if .readonly then
      sayerror READ_ONLY__MSG
      return
   endif
   if browse() then
      sayerror BROWSE_IS__MSG ON__MSG
      return
   endif
   parse arg markname perm line col .
   if not line then line=.line; endif
   if not col then col=.col; endif
   if not markname then  -- Following uses a new dialog, so no NLS xlation
      parse value entrybox(SETMARK__MSG,'/'Set__MSG'/'Setp__MSG'/'Cancel__MSG'/'Help__MSG'/',\0,'',200,
             atoi(1) || atoi(6020) || gethwndc(APP_HANDLE) ||
             SETMARK_PROMPT__MSG) with button 2 markname \0
      if button=\0 | button=\3 then return; endif  -- Esc or Cancel
      perm = asc(button)+2  --> temp is 3; perm is 4
      if not markname then
         sayerror NOTHING_ENTERED__MSG
         return
      endif
   endif
compile if NO_DUPLICATE_BOOKMARKS
   rc = get_array_value(EPM_utility_array_ID, 'bmn.'markname, bmindex)  -- Find that bookmark name
   parse value bmindex with bmindex fid .
   if not (rc | fid='') then  -- FID='' means previously deleted.
      empty = ''
      getfileid startid
      display -2
      activatefile fid
      display 2
      if rc then
         do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
      else
         line=0; col=1; offst=0
         do forever
            class = BOOKMARK_CLASS
            attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
            if class=0 then leave; endif
            query_attribute class, val, IsPush, offst, col, line
            if val=bmindex then  -- Found!
               leave
            endif
         enddo
         if class then  -- Was found
            sayerror BM_ALREADY_EXISTS__MSG
            return
         endif
         do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
      endif
   endif
compile endif -- NO_DUPLICATE_BOOKMARKS
   do_array 3, EPM_utility_array_ID, 'bmi.0', bmcount          -- Index says how many bookmarks there are
   bmcount = bmcount + 1
   do_array 2, EPM_utility_array_ID, 'bmi.0', bmcount          -- Store back the new number
   do_array 2, EPM_utility_array_ID, 'bmi.'bmcount, markname -- Store the new name at this index position
   oldmod = .modify
   if not isnum(perm) then perm=3; endif
   insert_attribute BOOKMARK_CLASS, bmcount, perm, 0, col, line
   if perm=4 then
      call attribute_on(8)  -- "Save attributes" flag
   else
      .modify = oldmod
   endif
   getfileid fid
   bmcount = bmcount fid perm
   do_array 2, EPM_utility_array_ID, 'bmn.'markname, bmcount -- Store the index & fileid under this name

compile if    INCLUDE_WORKFRAME_SUPPORT
defc compiler_error
   universal EPM_utility_array_ID
   universal defaultmenu, activemenu
   parse arg markname perm line col .
   if not line then line=.line; endif
   'bm' markname perm line col
   color = COMPILER_ERROR_COLOR
   oldmod = .modify
   getfileid fid
   Insert_Attribute_Pair(COLOR_CLASS, color, line, line, 1, length(textline(line)), fid)
   .modify = oldmod
   call attribute_on(1)  -- Colors flag
   if perm=16 then
      if not attribute_on(16) then  -- Was attribute 16 off?
 compile if    defined(C_KEYWORD_HIGHLIGHTING)
  compile if C_KEYWORD_HIGHLIGHTING
         'toggle_parse 0'
  compile endif
 compile endif
 compile if INCLUDE_STD_MENUS
         deletemenu defaultmenu, 6, 0, 0                -- Delete the Help menu
 compile endif
         buildsubmenu defaultmenu, 16, COMPILER_BAR__MSG, COMPILER_BARP__MSG, 0, 0
             buildmenuitem defaultmenu, 16, 1601, NEXT_COMPILER_MENU__MSG, 'nextbookmark N 16'NEXT_COMPILER_MENUP__MSG, 1, 0
             buildmenuitem defaultmenu, 16, 1602, PREV_COMPILER_MENU__MSG, 'nextbookmark P 16'PREV_COMPILER_MENUP__MSG, 1, 0
             buildmenuitem defaultmenu, 16, 1603, \0,                '',                  4, 0
             buildmenuitem defaultmenu, 16, 1604, DESCRIBE_COMPILER_MENU__MSG, 'compiler_help'DESCRIBE_COMPILER_MENUP__MSG,     1, 0
             buildmenuitem defaultmenu, 16, 1605, \0,                '',                  4, 0
             buildmenuitem defaultmenu, 16, 1606, CLEAR_ERRORS_MENU__MSG, 'compiler_clear'CLEAR_ERRORS_MENUP__MSG,     1, 0
             buildmenuitem defaultmenu, 16, 1607, END_DDE_SESSION_MENU__MSG, 'end_dde'END_DDE_SESSION_MENUP__MSG,     1, 0
             buildmenuitem defaultmenu, 16, 1608, REMOVE_COMPILER_MENU__MSG, 'compiler_dropmenu'REMOVE_COMPILER_MENUP__MSG,     1, 0
 compile if INCLUDE_STD_MENUS
         call add_help_menu(defaultmenu, 1)
 compile endif
         call maybe_show_menu()
      endif  -- "Added Compiler" flag
   endif

defc compiler_help
   universal EPM_utility_array_ID
   line = .line; col = 1; offst = -300
   do forever
      class = BOOKMARK_CLASS
      attribute_action 1, class, offst, col, line  -- 1=FIND NEXT ATTR
      if class=0 | line<>.line then
         sayerror NO_COMPILER_ERROR__MSG
         return
      endif
      query_attribute class, val, IsPush, offst, col, line
      if IsPush<>16 then iterate; endif  -- If not a compiler error class, skip
      call get_array_value(EPM_utility_array_ID, 'bmi.'val, markname)  -- Get name for mark
      if leftstr(markname,9)<>'WB_ERROR_' then iterate; endif  -- ?  Curious...
      leave
   enddo
   parse value substr(markname,10) with linenum '_' errornum
   bufhndl = buffer(CREATEBUF, 'COMPILER', MAXBUFSIZE, 1 )  -- create a private buffer
   if not bufhndl then sayerror 'CREATEBUF' ERROR_NUMBER__MSG RC; return; endif
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),   -- Post message to edit client
                      5444,               -- get compiler error messages for this line
                      linenum,
                      mpfrom2short(bufhndl,0) )

defc compiler_message
   parse arg numlines bufsize emsgbuffer .
   emsgbufptr = atol(emsgbuffer)
   emsgbufseg = itoa(substr(emsgbufptr,3),10)
   call listbox(DESCRIBE_ERROR__MSG,
                \0 || atol(bufsize) || emsgbufptr || 7,
                '/'DETAILS__MSG'/'Cancel__MSG'/'Help__MSG,0,1,min(numlines,12),0,
                gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6090) ||
                SELECT_ERROR__MSG)
   call buffer(FREEBUF, emsgbufseg)

defc compiler_help_add
   universal CurrentHLPFiles
   hlpfile = upcase(word(arg(1),1))
   if not wordpos(hlpfile, upcase(CurrentHLPFiles)) then
      hwndHelpInst = windowmessage(1,  getpminfo(APP_HANDLE),
                         5429,      -- EPM_Edit_Query_Help_Instance
                         0,
                         0)
      if hwndHelpInst==0 then
         -- there isn't a help instance deal with.
         Sayerror NO_HELP_INSTANCE__MSG
         return
      endif

      newlist2 = CurrentHLPFiles hlpfile \0
      retval = windowmessage(1,  hwndHelpInst,
                          557,    -- HM_SET_HELP_LIBRARY_NAME
                          ltoa(offset(newlist2) || selector(newlist2), 10),
                          0)
      if retval then
         sayerror ERROR__MSG retval ERROR_ADDING_HELP__MSG hlpfile
            -- revert to the previous version of the HLP list.
         newlist2 = CurrentHLPFiles\0
         retval2 = windowmessage(1,  hwndHelpInst,
                             557,    -- HM_SET_HELP_LIBRARY_NAME
                             ltoa(offset(newlist2) || selector(newlist2), 10),
                             0)
         if retval2 then
            sayerror ERROR__MSG retval ERROR_REVERTING__MSG CurrentHLPFiles
         endif
         return
      else
         CurrentHLPFiles = CurrentHLPFiles hlpfile
      endif
   endif

defc compiler_clear
   universal EPM_utility_array_ID
   line=0; col=1; offst=0; empty = ''
   oldmod = .modify
   do forever
      class = BOOKMARK_CLASS
      attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
      if class=0 then leave; endif  -- No more of that class
      query_attribute class, val, IsPush, offst, col, line
      if IsPush=16 then
         attribute_action 16, class, offst, col, line -- 16=Delete attribute
         if not get_array_value(EPM_utility_array_ID, 'bmi.'val, markname) then  -- Found that bookmark's name
            display -2
            do_array 2, EPM_utility_array_ID, 'bmi.'val, empty  -- Delete the name
            do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
            display 2
         endif
         class = COLOR_CLASS
         offst=-300
         col = 1
         line2 = line
         attribute_action 1, class, offst, col, line2 -- 1=FIND NEXT ATTR
         if class=0 | line2<>line then iterate; endif  -- No color class
         query_attribute class, val, IsPush, offst, col, line
         if val<>COMPILER_ERROR_COLOR then iterate; endif  -- Not the right color
         offst2 = offst; col2 = col
         attribute_action 3, class, offst2, col2, line2 -- 3=FIND MATCH ATTR
         if class then
            attribute_action 16, class, offst2, col2, line2 -- 16=Delete attribute
         endif
         class = COLOR_CLASS
         attribute_action 16, class, offst, col, line -- 16=Delete attribute
      endif
   enddo
   .modify = oldmod

defc compiler_dropmenu
   universal defaultmenu, activemenu
   deletemenu defaultmenu, 16, 0, 0
   call maybe_show_menu()

defc end_dde =
   call windowmessage(0,  getpminfo(EPMINFO_EDITCLIENT),   -- Post message to edit client
                      5501,                                -- EPM_EDIT_ENDWFDDE
                      0,
                      0)
compile endif  -- INCLUDE_WORKFRAME_SUPPORT

defc setmarkp  -- Following uses a new dialog, so no NLS xlation
   markname = entrybox(SETMARK_PROMPT__MSG, '/'Setp__MSG'/'Cancel__MSG,\0,'',200)
   if markname then
      'setmark' markname 4
   endif

defc go, gomark
   universal EPM_utility_array_ID
   parse arg markname
   if not markname then
      sayerror NEED_BM_NAME__MSG; return
   endif
   rc = get_array_value(EPM_utility_array_ID, 'bmn.'markname, bmindex)  -- Find that bookmark name
   parse value bmindex with bmindex fid .
   if rc | fid='' then  -- FID='' means previously deleted.
      sayerror UNKNOWN_BOOKMARK__MSG
      return
   endif
   empty = ''
   display -2
   activatefile fid
   display 2
   if rc then
      do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
      do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
      sayerror FILE_GONE__MSG BM_DELETED__MSG
      return
   endif
;  call psave_pos(savepos)
   line=0; col=1; offst=0
   do forever
      class = BOOKMARK_CLASS
      attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
      if class=0 then leave; endif
      query_attribute class, val, IsPush, offst, col, line
      if val=bmindex then
         .cursory=.windowheight%2
         line; .col=col
         return
      endif
   enddo
;  call prestore_pos(savepos)
   do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
   do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
   sayerror BM_NOT_FOUND__MSG ITS_DELETED__MSG

defc listmark
   universal EPM_utility_array_ID
   do_array 3, EPM_utility_array_ID, 'bmi.0', bmcount          -- Index says how many bookmarks there are
   if bmcount = 0 then sayerror NO_BOOKMARKS__MSG; return; endif
   getfileid startfid
   'xcom e /c bookmark'
   if rc<>-282 then  -- -282 = sayerror("New file")
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   .autosave = 0
   getfileid bmfid
   empty = ''
   display -2
   do i=1 to bmcount
      do_array 3, EPM_utility_array_ID, 'bmi.'i, markname   -- Get name number i
      if markname='' then iterate; endif  -- has been deleted
       -- Find that bookmark name
      if get_array_value(EPM_utility_array_ID, 'bmn.'markname, bmindex) then  -- Unexpected; ignore it & continue
         iterate
      endif
      parse value bmindex with bmindex fid .
      rc = 0
      activatefile fid
      if rc then  -- The file's gone; don't show the bookmark.
         do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
         do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
         iterate
      endif
      insertline markname, bmfid.last+1, bmfid
   enddo
   activatefile bmfid
compile if SORT_BOOKMARKS
   if .last>2 then
      call sort(2, .last, 1, 40, bmfid, 'I')
   endif
compile endif -- SORT_BOOKMARKS
   if browse_mode then call browse(1); endif  -- restore browse state
   display 2
   if not .modify then  -- Nothing added?
      sayerror NO_BOOKMARKS__MSG
      'xcom quit'
      return
   endif
   if listbox_buffer_from_file(startfid, bufhndl, noflines, usedsize) then return; endif
   parse value listbox(LIST_BOOKMARKS__MSG,
                       \0 || atol(usedsize) || atoi(32) || atoi(bufhndl),
                       '/'GOMARK__MSG'/'DELETEMARK__MSG'/'Cancel__MSG'/'Help__MSG,1,5,min(noflines,12),0,
                       gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(6030)) with button 2 markname \0
   call buffer(FREEBUF, bufhndl)
   if button=\1 then  -- Go to
      'gomark' markname
   elseif button=\2 then
      'deletebm' markname
   endif

defc deletebm
   universal EPM_utility_array_ID
   parse arg markname
   if not markname then
      sayerror NEED_BM_NAME__MSG; return
   endif
   if get_array_value(EPM_utility_array_ID, 'bmn.'markname, bmindex) then
      sayerror UNKNOWN_BOOKMARK__MSG
      return
   endif
   empty = ''
   parse value bmindex with bmindex fid perm .
   do_array 2, EPM_utility_array_ID, 'bmi.'bmindex, empty  -- Delete the name
   do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
;; call psave_pos(savepos)
   sayerror BM_DELETED__MSG
   getfileid startid
   display -2
   activatefile fid
   display 2
   if rc then  -- File no longer in ring - all done.
      return
   endif
   line=0; col=1; offst=0
   do forever
      class = BOOKMARK_CLASS
      attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
      if class=0 then leave; endif
      query_attribute class, val, IsPush, offst, col, line
      if val=bmindex then
         oldmod = .modify
         attribute_action 16, class, offst, col, line -- 16=Delete attribute
         if perm<>4 then .modify=oldmod; endif
         leave
      endif
   enddo
   activatefile startid

defc deletebmclass
   universal EPM_utility_array_ID
   parse arg BMtype .
   if BMtype='' then
      sayerror NEED_BM_CLASS__MSG; return
   endif
   if BMtype=4 then
      if askyesno(DELETE_PERM_BM__MSG) <> YES_CHAR then return; endif
   endif
   line=0; col=1; offst=0; empty = ''
   oldmod = .modify
   do forever
      class = BOOKMARK_CLASS
      attribute_action 1, class, offst, col, line -- 1=FIND NEXT ATTR
      if class=0 then leave; endif  -- No more of that class
      query_attribute class, val, IsPush, offst, col, line
      if IsPush=BMtype then
         attribute_action 16, class, offst, col, line -- 16=Delete attribute
         if not get_array_value(EPM_utility_array_ID, 'bmi.'val, markname) then  -- Found that bookmark's name
            display -2
            do_array 2, EPM_utility_array_ID, 'bmi.'val, empty  -- Delete the name
            do_array 2, EPM_utility_array_ID, 'bmn.'markname, empty -- Delete the index
            display 2
         endif
      endif
   enddo
   if BMtype<>4 then .modify=oldmod; endif

; Dependencies:  put_file_as_MVST()
defc saveattributes
   universal EPM_utility_array_ID
   universal app_hini
   universal default_font

   getfileid start_fid
   compiler_errors_on = (.levelofattributesupport bitand 16) <> 0
;; call psave_pos(savepos)
   'xcom e /c attrib'
   if rc<>-282 then  -- -282 = sayerror("New file")
      sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
      return
   endif
   browse_mode = browse()     -- query current state
   if browse_mode then call browse(0); endif
   .autosave = 0
   getfileid attrib_fid
   deleteline  -- Delete the empty line
;; activatefile start_fid
   line=0; col=1; offst=0; found_font = 0
   style_line=0; style_col=0; style_offst=0; style_list=''
   do forever
      class = 0  -- Find any class
      attribute_action 1, class, offst, col, line, start_fid -- 1=FIND NEXT ATTR
      if class=0 then leave; endif
      query_attribute class, val, IsPush, offst, col, line, start_fid
      l = line
      if class=BOOKMARK_CLASS then  -- get name
         if IsPush<>4 then iterate; endif    -- If not permanent, don't keep it.
         do_array 3, EPM_utility_array_ID, 'bmi.'val, bmname  -- Get the name
         l = l bmname
      elseif class=COLOR_CLASS then  -- don't save if out of range
;;       if val>255 then iterate; endif
compile if not defined(COMPILING_FOR_ULTIMAIL)
         if line=style_line & col=style_col & (offst=style_offst+1 | offst=style_offst+2) then iterate; endif
 compile if    INCLUDE_WORKFRAME_SUPPORT
         if compiler_errors_on & val=COMPILER_ERROR_COLOR then iterate; endif
 compile endif
compile endif -- not defined(COMPILING_FOR_ULTIMAIL)
;;       if line=style_line & col=style_col & offst=style_offst+2 then iterate; endif
      elseif class=FONT_CLASS then  -- get font info
;;       if val>255 then iterate; endif
compile if not defined(COMPILING_FOR_ULTIMAIL)
         if line=style_line & col=style_col & offst=style_offst+1 then iterate; endif
compile endif -- not defined(COMPILING_FOR_ULTIMAIL)
         l = l queryfont(val)
         found_font = 1
      elseif class=STYLE_CLASS then  -- get style info
         do_array 3, EPM_utility_array_ID, 'si.'val, stylename -- Get the style name
         style_line=line; style_col=col; style_offst=offst
         l = l stylename
         if val<256 & not pos(chr(val), style_list) then  -- a style we haven't seen yet
            if style_list='' then
               'xcom e /c style'
               if rc<>-282 then  -- -282 = sayerror("New file")
                  sayerror ERROR__MSG rc BAD_TMP_FILE__MSG sayerrortext(rc)
                  if browse_mode then call browse(1); endif  -- restore browse state
                  return
               endif
               .autosave = 0
               getfileid style_fid
               deleteline  -- Delete the empty line
            endif
            style_list = style_list || chr(val)
compile if WANT_APPLICATION_INI_FILE
            insertline stylename || \0 || queryprofile(app_hini, 'Style', stylename), style_fid.last+1, style_fid
compile else
            insertline stylename || \0 , style_fid.last+1, style_fid
compile endif
         endif  -- new style
      endif  -- class=STYLE_CLASS
      insertline class val ispush offst col l, attrib_fid.last+1, attrib_fid
   enddo
   if found_font & .font <> default_font then
      insertline FONT_CLASS .font 0 0 0 (-1) queryfont(start_fid.font), 1, attrib_fid  -- Insert at beginning.
   endif
   put_result = put_file_as_MVST(attrib_fid, start_fid, 'EPM.ATTRIBUTES')
   if style_list <> '' then
      if not put_result then
         call put_file_as_MVST(style_fid, start_fid, 'EPM.STYLES')
      endif
      style_fid.modify = 0
      'xcom quit'
   endif
   attrib_fid.modify = 0
   'xcom quit'
   if browse_mode then call browse(1); endif  -- restore browse state
   if put_result then
      stop
   endif

; Dependencies:  find_ea() from EA.E
defc loadattributes
   universal EPM_utility_array_ID, app_hini, load_var
   getfileid fid
   oldmod = .modify
   val = get_EAT_ASCII_value('EPM.TABS')
   if val<>'' then
      .tabs = val
      load_var = load_var + 1  -- Flag that Tabs were set via EA
   endif
   val = get_EAT_ASCII_value('EPM.MARGINS')
   if val<>'' then
      .margins = val
      load_var = load_var + 2  -- Flag that Tabs were set via EA
   endif
   if find_ea('EPM.STYLES', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen) then
      val = peek(ea_seg, ea_ptr2,min(ea_valuelen,8))
      if leftstr(val,2)=EAT_MVST & substr(val,7,2)=EAT_ASCII then
         num = itoa(substr(val,5,2),10)
         ea_ptr2 = ea_ptr2 + 8
         do i=1 to num
            len = itoa(peek(ea_seg, ea_ptr2, 2), 10)
            parse value peek(ea_seg, ea_ptr2 + 2, len) with stylename \0 stylestuff
compile if WANT_APPLICATION_INI_FILE
            if queryprofile(app_hini, 'Style', stylename)='' then  -- Don't have as a local style?
               call setprofile(app_hini, 'Style', stylename, stylestuff)  -- Add it.
            endif
compile endif
            ea_ptr2 = ea_ptr2 + len + 2
         enddo
      endif
   endif
   need_colors=0; need_fonts=0
   if find_ea('EPM.ATTRIBUTES', ea_seg, ea_ofs, ea_ptr1, ea_ptr2, ea_len, ea_entrylen, ea_valuelen) then
      browse_mode = browse()     -- Query current state
      if browse_mode then call browse(0); endif  -- Turn off, so we can insert attributes.
      read_only = .readonly
      .readonly = 0                              -- ditto
      val = peek(ea_seg, ea_ptr2,min(ea_valuelen,8))
      if leftstr(val,2)=EAT_MVST & substr(val,7,2)=EAT_ASCII then
         num = itoa(substr(val,5,2),10)
         ea_ptr2 = ea_ptr2 + 8
         do_array 3, EPM_utility_array_ID, 'bmi.0', bmcount          -- Index says how many bookmarks there are
         do_array 3, EPM_utility_array_ID, 'si.0', stylecount
         fontsel=''; bg=''  -- Initialize to simplify later test
         do i=1 to num
            len = itoa(peek(ea_seg, ea_ptr2, 2), 10)
            parse value peek(ea_seg, ea_ptr2 + 2, len) with class val ispush offst col line rest
            ea_ptr2 = ea_ptr2 + len + 2
            if class=BOOKMARK_CLASS then  -- get name
               if not get_array_value(EPM_utility_array_ID, 'bmn.'rest, stuff) then  -- See if we already had it
                  parse value stuff with oldindex oldfid .
                  if oldfid = fid then
                     'deletebm' rest
                  endif
               endif
               bmcount = bmcount + 1
               do_array 2, EPM_utility_array_ID, 'bmi.'bmcount, rest -- Store the name at this index position
               if IsPush<2 then IsPush=4; endif  -- Update old-style bookmarks
               stuff = bmcount fid IsPush  -- flag as permanent
               do_array 2, EPM_utility_array_ID, 'bmn.'rest, stuff -- Store the index & fileid under this name
               val = bmcount  -- Don't care what the old index was.
            elseif class=COLOR_CLASS then
               need_colors = 1
            elseif class=FONT_CLASS then
               parse value rest with fontname '.' fontsize '.' fontsel
               if fontsel='' then iterate; endif  -- Bad value; discard it
               val=registerfont(fontname, fontsize, fontsel)  -- Throw away old value
               if line=-1 then
                  .font = val
                  iterate
               endif
               need_fonts = 1
            elseif class=STYLE_CLASS then  -- Set style info
compile if WANT_APPLICATION_INI_FILE
               parse value rest with stylename .
               stylestuff = queryprofile(app_hini, 'Style', stylename)
compile if not defined(COMPILING_FOR_ULTIMAIL)
               if stylestuff='' then iterate; endif  -- Shouldn't happen
compile endif -- not defined(COMPILING_FOR_ULTIMAIL)
               parse value stylestuff with fontname '.' fontsize '.' fontsel '.' fg '.' bg
               if get_array_value(EPM_utility_array_ID, 'sn.'stylename, val) then  -- Don't have it; add:
                  stylecount = stylecount + 1                                 -- Increment index
                  do_array 2, EPM_utility_array_ID, 'si.'stylecount, stylename  -- Save index.name
                  do_array 2, EPM_utility_array_ID, 'sn.'stylename, stylecount  -- Save name.index
                  val = stylecount
               endif
compile else
               iterate
compile endif
            endif
            insert_attribute class, val, ispush, 0, col, line
compile if WANT_APPLICATION_INI_FILE
            if class=STYLE_CLASS then  -- Set style info
               if fontsel<>'' then
                  fontid=registerfont(fontname, fontsize, fontsel)
                  if fontid<>.font then  -- Only insert font change for style if different from base font.
                     insert_attribute FONT_CLASS, fontid, ispush, 0, col, line
                     need_fonts = 1
                  endif
               endif
               if bg<>'' then
                  insert_attribute COLOR_CLASS, bg*16 + fg, ispush, 0, col, line
                  need_colors = 1
               endif
            endif  -- class=STYLE_CLASS
compile endif  -- WANT_APPLICATION_INI_FILE
         enddo
         do_array 2, EPM_utility_array_ID, 'bmi.0', bmcount          -- Store back the new number
         do_array 2, EPM_utility_array_ID, 'si.0', stylecount
         if need_colors then
            call attribute_on(1)  -- Colors flag
         endif
         if need_fonts then
            call attribute_on(4)  -- Mixed fonts flag
         endif
         call attribute_on(8)  -- "Save attributes" flag
      else
         sayerror UNEXPECTED_ATTRIB__MSG
      endif
      if browse_mode then call browse(1); endif  -- Restore browse state
      .readonly = read_only
   endif  -- 'EPM.ATTRIBUTES'
   .modify = oldmod

defc nextbookmark
   parse arg next bmclass .
   class = BOOKMARK_CLASS
   col = .col; line=.line; offst=0
   if next='P' then col=col-1; endif
   do forever
      attribute_action 1+(next='P'), class, offst, col, line -- 1=FIND NEXT ATTR; 2=FIND PREV ATTR
      if class=0 then
         sayerror BM_NOT_FOUND__MSG
         return
      endif
      query_attribute class, val, IsPush, offst, col, line
      if IsPush=bmclass | bmclass='' then
         .cursory=.windowheight%2
         line; .col=col
         return
      endif
   enddo

; The following routine will put the contents of the current file into the
; .EAarea of another file as an MVST EAT_ASCII attribute.  If the given
; attribute name already exists, it will be replaced (not extended).
; Dependencies:  delete_ea()
defproc put_file_as_MVST(source_fid, target_fid, ea_name)
   getfileid start_fid
   activatefile target_fid
   call delete_ea(ea_name)
   if not source_fid.last then  -- If nothing to add,
      activatefile start_fid
      return                    -- we're all done.
   endif
   activatefile source_fid  -- So filesize() will work
   name_len = length(ea_name)
   value_len = filesize() + 2 * .last + 8  -- Overhead: 2 bytes/rec length, + 2 bytes each EAT_MVST, codepage, numentries, EAT_ASCII
   ea_len_incr = 5 + name_len + value_len  -- Overhead: 1 flags, 1 len(name), 2 len(value), 1 null ASCIIZ terminator
   -- +7 rather than +3 because previous calc didn't consider the length
   --    of the length field.
   ea_len_incr = ((ea_len_incr + 7)%4)*4;  -- round up for long word multiples
   if ea_len_incr>65535 then
      call winmessagebox(LONG_EA_TITLE__MSG, LONG_EA__MSG, 16454) -- MB_CANCEL + MB_MOVEABLE + MB_CUACRITICAL
      return 1
   endif
   if target_fid.eaarea then
      ea_long = atol(target_fid.eaarea)
      ea_seg = itoa(rightstr(ea_long,2),10)
      ea_ofs = itoa(leftstr(ea_long,2),10)
      ea_old_len  = ltoa(peek(ea_seg, ea_ofs, 4),10)
      if ea_old_len+ea_len_incr>65535 then
         call winmessagebox(LONG_EA_TITLE__MSG, LONG_EA__MSG, 16454) -- MB_CANCEL + MB_MOVEABLE + MB_CUACRITICAL
         return 1
      endif
      call dynalink32(E_DLL,
                      'myrealloc',
                      ea_long ||
                      atol(ea_old_len+ea_len_incr) ||
                      atol(0),
                      2)

      r = 0

      ea_ptr = ea_seg
   else
/*
      ea_ptr = atol(dynalink32(E_DLL,
                               'mymalloc',
                               atol(ea_len_incr+4), 2))
*/
      ea_ptr = ltoa(substr(ea_ptr,3,2)\0\0,10)
      r = -270 * (ea_ptr = 0)

      ea_ofs = 0
      ea_old_len  = 4           -- Point past length field
   endif

   if r then sayerror ERROR__MSG r ALLOC_HALTED__MSG; stop; endif
   activatefile target_fid
   poke ea_ptr, ea_ofs, atol(ea_old_len+ea_len_incr)
   ea_ofs = ea_ofs + ea_old_len
   poke ea_ptr, ea_ofs  , atol(ea_len_incr) -- Start of EA:  flag byte
   ea_ofs = ea_ofs + 4;
   poke ea_ptr, ea_ofs  , \0              -- Start of EA:  flag byte
   poke ea_ptr, ea_ofs+1, chr(name_len)
   poke ea_ptr, ea_ofs+2, atoi(value_len)
   poke ea_ptr, ea_ofs+4, ea_name
   poke ea_ptr, ea_ofs+4+name_len, \0     -- Null byte after name
   poke ea_ptr, ea_ofs+5+name_len, EAT_MVST
   poke ea_ptr, ea_ofs+7+name_len, atoi(0)  -- Code page
   poke ea_ptr, ea_ofs+9+name_len, atoi(source_fid.last)  -- NumEntries
   poke ea_ptr, ea_ofs+11+name_len, EAT_ASCII  -- Each entry is of type ASCII
   ea_ofs = ea_ofs + 13 + name_len
   do i=1 to source_fid.last
      getline line, i, source_fid
      poke ea_ptr, ea_ofs, atoi(length(line))
      poke ea_ptr, ea_ofs+2, line
      ea_ofs = ea_ofs + length(line) + 2
   enddo
   .eaarea = mpfrom2short(ea_ptr,0)
   activatefile start_fid

