/****************************** Module Header *******************************
*
* Module Name: dict.e
*
* Copyright (c) Netlabs EPM Distribution Project 2004
*
* $Id: dict.e,v 1.4 2005-09-12 14:22:01 aschn Exp $
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

; Select dictionaries


compile if not defined(SMALL)  -- If SMALL not defined, then being separately
define INCLUDING_FILE = 'DICT.E'
const
   tryinclude 'MYCNF.E'        -- the user's configuration customizations.

 compile if not defined(SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif

   include 'stdconst.e'
   EA_comment 'Select languade for dictionaries.'

compile endif

; ---------------------------------------------------------------------------
; Syntax: DictLang <new_lang>
; The first found abbreviation matches.
; Accepts also 'delete' as arg to delete all entries.
defc DictLang
   universal nepmd_hini  -- often forgotten
   universal dictionary_filename
   universal addenda_filename
   universal app_hini
   universal appname

   KeyPath = '\NEPMD\User\Spellcheck'

   parse arg opt
   opt = strip(opt)
   if opt = '' then
      'SelectDictLang'
      return
   endif

   Select       = ''
   SearchOption = 'C'
   Container    = ''
   do forever
      Container = NepmdGetNextConfigKey( nepmd_hini, KeyPath'\Language', Container, SearchOption)
      parse value Container with 'ERROR:'ret
      if (ret > '') then
         leave
      endif
      if upcase(opt) = 'DELETE' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Language\'Container'\Dictionary')
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Language\'Container'\Addenda')
         Select = 'DELETE'
         --iterate
      else
         if abbrev( upcase(Container), upcase(opt)) then
            Select = Container
            leave
         endif
      endif
   enddo

   if Select = 'DELETE' then
   elseif Select = '' then
      sayerror 'Language "'opt'" not found.'
   else
      call NepmdWriteConfigValue( nepmd_hini, KeyPath'\SelectedLanguage', Select)
      dictionary_filename = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Language\'Select'\Dictionary')
      addenda_filename    = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Language\'Select'\Addenda')
      -- Change entry in EPM.INI, too (temp.)
      call SetProfile( app_hini, appname, INI_DICTIONARY, dictionary_filename)
      call SetProfile( app_hini, appname, INI_ADDENDA, addenda_filename)
      -- Toggle dynaspell off and on to overtake the new dicts
      if .keyset = 'SPELL_KEYS' then
         'dynaspell'
         'dynaspell'
      endif
      sayerror 'Switched to language "'Select'"'
   endif
   return

; ---------------------------------------------------------------------------
; Accepts also 'delete' as arg.
defc SelectDictLang
   universal nepmd_hini  -- often forgotten

   KeyPath = '\NEPMD\User\Spellcheck'
   NoEntry = '-no entry-'

   parse arg opt

   CurLang  = NepmdQueryConfigValue( nepmd_hini, KeyPath'\SelectedLanguage')
   Selection    = 1
   LangList     = ''
   Container    = ''
   SearchOption = 'C'
   i = 0
   Delim = \1
   do forever
      i = i + 1
      Container = NepmdGetNextConfigKey( nepmd_hini, KeyPath'\Language', Container, SearchOption)
      parse value Container with 'ERROR:'ret
      if (ret > '') then
         leave
      endif
      LangList = LangList''Delim''Container
      if upcase(Container) = upcase(CurLang) then
         Selection = i
      endif
   enddo
   if LangList = '' then
      LangList = Delim''NoEntry  -- without an entry, listbox would return Button = 0 forever
   endif

   -- Open Listbox
   -- No Linebreak allowed in Text
   Title = 'Select a dictionary language'
   Text = 'Current language: 'CurLang
   if CurLang = '' then
      DefButton = 2  -- New
   else
      DefButton = 1  -- Set
   endif
   HelpId = 0

   refresh
   ret = listbox( Title,
                  LangList,
                  '/~Set/~New/C~onfigure/~Delete/~Cancel',   -- Buttons
                  '5', '5',  -- Top, Left,
                  4, 50,     -- Height, Width
                  gethwnd(APP_HANDLE) || atoi(Selection) || atoi(DefButton) || atoi(HelpId) ||
                  Text\0)
   refresh

   -- Check result
   Button = asc(leftstr( ret, 1))
   EOS = pos( \0, ret, 2)        -- CHR(0) signifies End Of String
   Select = substr( ret, 2, EOS - 2)

   if Select = NoEntry then
      Select = ''
      if Button = 1 | Button = 3 then
         Button = 2  -- switch to New
      endif
   endif
   if Button = 1 then      -- Set
      'DictLang' Select
      return
   elseif Button = 2 then  -- New
      Config = 'NEW'
      'ConfigDictLang' Config CurLang
      return
   elseif Button = 3 then  -- Configure
      Config = 'CONFIG'
      'ConfigDictLang' Config Select
      return
   elseif Button = 4 then  -- Delete
      --sayerror 'Delete 'Select
      if Select <> '' then
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Language\'Select'\Dictionary')
         call NepmdDeleteConfigValue( nepmd_hini, KeyPath'\Language\'Select'\Addenda')
         if Select = CurLang then
            call NepmdDeleteConfigValue( nepmd_hini, KeyPath'\SelectedLanguage')
         endif
      endif
      'SelectDictLang'  -- restart
      return
   elseif Button = 5 then  -- Cancel
      return
   endif
   return

; ---------------------------------------------------------------------------
defc ConfigDictLang
   universal nepmd_hini  -- often forgotten
   universal dictionary_filename
   universal addenda_filename
   universal app_hini
   universal appname

   RightArrow = \16
   LeftArrow  = \17
   i = 1
   KeyPath = '\NEPMD\User\Spellcheck'
   NoName = '-untitled-'

   parse arg Config DefLang
;sayerror 'ConfigDictLang: ['Config'] ['DefLang']'
   DefLang = strip(DefLang)
   Dict = ''
   Add  = ''
   Name = ''
   if DefLang = '' then
      -- Get entry from EPM.INI as start values
      OldDict = QueryProfile( app_hini, appname, INI_DICTIONARY)
      OldAdd  = QueryProfile( app_hini, appname, INI_ADDENDA)
      -- Check if file or file lists exist
      rest = OldDict
      do while rest <> ''
         parse value rest with next rest
         if exist(next) then
            Dict = OldDict
            leave
         endif
      enddo
      rest = OldAdd
      do while rest <> ''
         parse value rest with next rest
         if exist(next) then
            Add = OldAdd
            leave
         endif
      enddo
   else
      Dict = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Language\'DefLang'\Dictionary')
      Add  = NepmdQueryConfigValue( nepmd_hini, KeyPath'\Language\'DefLang'\Addenda')
   endif
   if Config = 'NEW' then
      Name = ''
   else
      Name = DefLang
   endif
   Again = 1
   do while Again
      Again = 0
      -- Open EntryBox
      -- No Linebreak allowed in Text
      if Config = 'CONFIG' then
         maxi = 2
      else
         maxi = 3
      endif
      if Config = 'NEW' then
         Title = 'Add new language - page 'i'/'maxi
      else
         Title = 'Configure language "'DefLang'" - page 'i'/'maxi
      endif

      if i = 1 then
         Text  = 'Enter a filename for a dictionary or a space-separated list:'
         Buttons = '/~Next 'RightArrow'/~File dialog/~Cancel'
         Back = 0; Next = 1; FileDlg = 2; Cancel = 3; Ok = 0
         OldEntry = Dict
         DefButton = Next
      elseif i = 2 then
         Text  = 'Enter a filename for an addendum or a space-separated list:'
         OldEntry = Add
         if Config = 'CONFIG' then
            Buttons = '/'LeftArrow' ~Back/~Ok/~File dialog/~Cancel'
            Back = 1; Next = 0; Ok = 2; FileDlg = 3; Cancel = 4
            DefButton = Ok
         else
            Buttons = '/'LeftArrow' ~Back/~Next 'RightArrow'/~File dialog/~Cancel'
            Back = 1; Next = 2; FileDlg = 3; Cancel = 4; Ok = 0
            DefButton = Next
         endif
      else
         Text  = 'Enter a name for the language:'
         Buttons = '/'LeftArrow' ~Back/~Ok/~Cancel'
         Back = 1; Next = 0; Ok = 2; FileDlg = 0; Cancel = 3
         if Name = '' then
            -- get DictBasename
            if Dict <> '' then
               parse value Dict with first rest
               lp = lastpos( '\', first)
               DictName = substr( first, lp + 1)
               parse value DictName with DictBasename'.'ext
               if DictBasename <> '' then
                  Name = GetDefaultDictLangName( DictBasename)
               endif
            endif
         endif
         OldEntry = Name
         DefButton = Ok
      endif
      Title = leftstr( Title, 100)'.'  -- Add spaces to fit the text in titlebar
      HelpId = 0
      ret = entrybox( Title,
                      Buttons,
                      OldEntry,
                      '',
                      255,     -- Length
                      atoi(DefButton) || atoi(HelpId) || gethwndc(APP_HANDLE) ||
                      Text\0)

      -- Check result
      EntryButton = asc(leftstr( ret, 1))
      EOS = pos( \0, ret, 2)        -- CHR(0) signifies End Of String
      NewEntry = substr( ret, 2, EOS - 2)
      if EntryButton = Cancel | EntryButton = 0 then  -- Check if 0 for Esc key must come first
         'SelectDictLang'
         return
      elseif EntryButton = Next then
         if i = 1 then
            Dict = NewEntry
         elseif i = 2 then
            Add = NewEntry
         elseif i = 3 then
            Name = NewEntry
         endif
         Again = 1
         i = i + 1
      elseif EntryButton = Back then
         if i = 1 then
            Dict = NewEntry
         elseif i = 2 then
            Add = NewEntry
         elseif i = 3 then
            Name = NewEntry
         endif
         Again = 1
         i = i - 1
      elseif EntryButton = Ok then
         -- todo: check if valid
         if i = 1 then
            Dict = NewEntry
         elseif i = 2 then
            Add = NewEntry
         elseif i = 3 then
            Name = NewEntry
         endif
         --sayerror 'Name = 'Name', Dict = 'Dict', Add = 'Add
         if Name = '' then
            Name = NoName
         endif
         call NepmdWriteConfigValue( nepmd_hini, KeyPath'\Language\'Name'\Dictionary', Dict)
         call NepmdWriteConfigValue( nepmd_hini, KeyPath'\Language\'Name'\Addenda', Add)
         'SelectDictLang'
         return

      elseif EntryButton = FileDlg then
         Again = 1
         if i = 1 then
            FileDlgTitle = 'Select a dictionary'
            FileMask = '*.dic;*.dct'
            lp = lastpos( '\', Dict)
            if lp then
               FileMask = substr( Dict, 1, lp)''FileMask
            endif
         else
            FileDlgTitle = 'Select an addendum'
            FileMask = '*.add;*.adl'
            lp = lastpos( '\', Add)
            if lp then
               FileMask = substr( Add, 1, lp)''FileMask
            endif
         endif
         if getpminfo(EPMINFO_EDITFRAME) then
            handle = EPMINFO_EDITFRAME
         else                   -- If frame handle is 0, use edit client instead
            handle = EPMINFO_EDITCLIENT
         endif
         size  = 328       -- size of FILEDLG struct
         flags = 257
         filename = ''
         FileDlgTitle = FileDlgTitle\0
         fileDlg = atol(size) || atol(flags) || copies( \0, 12) ||
                   address(FileDlgTitle) || copies( \0, size - 24)
         fileDlg = overlay( FileMask, fileDlg, 53)  -- Provide a starting path
                                                    -- and a filetype filter.
         -- if owner should be Desktop: replace gethwndc(handle) with atol(1)
         result = dynalink32( 'PMCTLS', 'WINFILEDLG',
                              atol(1) ||
                              gethwndc(handle) /*atol(1)*/ ||  -- Owner
                              address(fileDlg))
         if result then
            parse value substr( filedlg, 53) with filename \0
            --sayerror 'Button =' ltoa( substr( fileDlg, 13, 4), 10)'; file = "'filename'"'
            Button = ltoa( substr( fileDlg, 13, 4), 10)
            if Button = 1 & filename <> '' then
               if i = 1 then
                  Dict = filename
               elseif i = 2 then
                  Add = filename
               endif
            endif
         endif
      endif

   enddo
   return

; ---------------------------------------------------------------------------
defproc GetDefaultDictLangName(DictBasename)

   -- Available Netscape dictionaries
   -- http://service.boulder.ibm.com/asd-bin/doc/en_us/nsdicts/f-server.htm
   List = '/catala'   || '/Catalan'                       ||
          '/czech'    || '/Czech'                         ||
          '/dansk'    || '/Danish'                        ||
          '/nedplus'  || '/Dutch (Permissive spelling)'   ||
          '/nederlnd' || '/Dutch (Restrictive spelling)'  ||
          '/afrikaan' || '/Dutch (South Africa Afrikaan)' ||
          '/aus'      || '/English (Australian)'          ||
          '/uk'       || '/English (United Kingdom)'      ||
          '/us'       || '/English (United States)'       ||
          '/suomi'    || '/Finnish'                       ||
          '/canadien' || '/French (Canadian)'             ||
          '/francais' || '/French (National)'             ||
          '/deutsch'  || '/German (Before reform)'        ||
          '/deutsch2' || '/German (National reform)'      ||
          '/dschweiz' || '/German (Swiss)'                ||
          '/hellas'   || '/Greek'                         ||
          '/magyar'   || '/Hungarian'                     ||
          '/islensk'  || '/Icelandic'                     ||
          '/italiano' || '/Italian'                       ||
          '/norbok'   || '/Norwegian (Bokmal)'            ||
          '/nornyn'   || '/Norwegian (Nynorsk)'           ||
          '/polska'   || '/Polish'                        ||
          '/brasil'   || '/Portuguese (Brazilian)'        ||
          '/portugal' || '/Portuguese (National)'         ||
          '/russian'  || '/Russian'                       ||
          '/espana'   || '/Spanish'                       ||
          '/svensk'   || '/Swedish'                       ||
          '/turkiye'  || '/Turkish'

   Name = ''
   rest = List
   do while rest <> ''
      parse value rest with '/'next1'/'next2'/' -1 rest
      if next2 = '' then
         leave
      endif
      if upcase(DictBasename) = upcase(next1) then
         Name = next2
         leave
      endif
   enddo
   return Name


