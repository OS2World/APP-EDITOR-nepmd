/****************************** Module Header *******************************
*
* Module Name: epmlex.e
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
ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ What's it called: EPMLEX.E                                                 บ
บ                                                                            บ
บ What does it do : Spell checking and Synonym support for the EPM editor.   บ
บ                                                                            บ
บ                   There are two major components to spell and synonym      บ
บ                   checking in EPM.  The first and most important is the    บ
บ                   actual word verification and word/dictionary lookup.     บ
บ                   This is done by the internal EPM opcode, "lexam".        บ
บ                   This opcode can take on the variations indicated by      บ
บ                   the LXF constants defined below.                         บ
บ                                                                            บ
บ                   The second most important part to word checking is the   บ
บ                   presentation of the results.  This is neatly done in     บ
บ                   EPM using a PM list box.  E has an internal list dialog  บ
บ                   accessible through the 'listbox' function.  See          บ
บ                   STDCTRL.E for details on the 'listbox' function.         บ
บ                                                                            บ
บ Who and When    : Larry Margolis, 11/91                                    บ
บ Updated from the original                                                  บ
บ EPMLEX.E done by: C.Maurer,  R.Yozzo,  Gennaro Cuomo, and Larry Margolis   บ
บ                   1/89 - 10/90                                             บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
*/
; Customizing information:  Any of the following customizing constants can
; be overridden by including the appropriate definition after a CONST statement
; in your MYCNF.E.
;
; Example of customizing:  include the following lines in your MYCNF.E
; (with the ';' deleted from the beginning of each line).
;
;    const                               -- Customizations for EPMLEX:
;       RESPECT_case_for_addenda = 0     -- Ignore case of addenda words.
;       my_ADDENDA_FILENAME= 'd:\doc\margoli.adf'     -- I keep these in my
;       my_DICTIONARY_FILENAME= 'd:\doc\us.dct'       -- d:\doc directory.
; Can also have multiple dictionaries, separated by spaces - all will be loaded:
;       my_DICTIONARY_FILENAME= 'd:\doc\us.dct d:\doc\medical.dct d:\doc\legal.dct'

compile if not defined( SMALL)  -- If SMALL not defined, then being separately compiled
   include 'stdconst.e'
   define INCLUDING_FILE = 'EPMLEX.E'
   tryinclude 'MYCNF.E'        -- Include the user's configuration customizations.
 compile if not defined( SITE_CONFIG)
   const SITE_CONFIG = 'SITECNF.E'
 compile endif
 compile if SITE_CONFIG
   tryinclude SITE_CONFIG
 compile endif
const
 compile if not defined( SPELL_SUPPORT)  -- Must set here, since set to 0 in ENGLISH.E
   SPELL_SUPPORT = 'DYNALINK'          -- New default
 compile endif
 compile if not defined( NLS_LANGUAGE)
   NLS_LANGUAGE = 'ENGLISH'
 compile endif
   include NLS_LANGUAGE'.e'
   EA_comment 'This contains the spell-checking code.  It can be linked explicitly, or will be linked automatically if the base .ex file is configured for it.'
compile endif

const
compile if not defined( PROOF_DIALOG_FIXED)
   PROOF_DIALOG_FIXED = 0               -- 1 if dialog should stay in one spot
compile endif

-- Always use addenda.
--compile if not defined(ADDENDASUPPORT)
--   ADDENDASUPPORT =  1                  -- 1 if addenda support
--compile endif

--compile if ADDENDASUPPORT
 compile if not defined( RESPECT_case_for_addenda)
   RESPECT_case_for_addenda  = 1        /* If addenda entries are to be     */
 compile endif                          /* placed in the addenda without    */
                                        /* modifying their case, then       */
                                        /* this variable should be 1        */
                                        /* Otherwise, it should be 0        */
--compile endif -- ADDENDASUPPORT

compile if not defined( PROOF_CIRCLE_STYLE)
   --PROOF_CIRCLE_STYLE = 2
   PROOF_CIRCLE_STYLE = 4          --         Select a wide sloppy circle
compile endif
compile if not defined( PROOF_CIRCLE_COLOR1)
   --PROOF_CIRCLE_COLOR1 = 16777220
   --PROOF_CIRCLE_COLOR1 = 14      --         gives bright yellow circles
   PROOF_CIRCLE_COLOR1 = 13        --         gives magenta circles, see COLORS.E
compile endif
compile if not defined( PROOF_CIRCLE_COLOR2)
   --PROOF_CIRCLE_COLOR2 = 16777218
   --PROOF_CIRCLE_COLOR2 = 14      --         gives bright yellow circles
   PROOF_CIRCLE_COLOR2 = 13        --         gives magenta circles, see COLORS.E
compile endif
compile if not defined( DYNASPELL_BEEP)
   DYNASPELL_BEEP = 'ALARM'
compile endif
compile if not defined( PROOF_NEXT_DEFAULT)
   PROOF_NEXT_DEFAULT = 0
compile endif

const
   -- Functions
   LXFINIT     =   0  -- Initialize
   LXFTERM     =   1  -- Terminate
   LXFGDIC     =   2  -- Pickup Dictionary
   LXFFDIC     =   3  -- Drop Dictionary
   LXFSETADD   =   4  -- Set Addenda Language Type
   LXFAD2TRS   =   5  -- Add to Transient Addenda
   LXFREDTRS   =   6  -- Read from Transient Addenda
   LXFSAVTRS   =   7  -- Save Transient Addenda
   LXFVERFY    =   8  -- Verification
   LXFSPAID    =   9  -- Spelling Aid
   LXFHYPH     =  10  -- Hyphenation
   LXFDHYPH    =  11  -- Dehyphenation
   LXFSYN      =  12  -- Synonym
   LXFAMUGDIC  = 255  -- Addenda Pickup Dictionary (Pseudo-op; calls LXFGDIC internally)
   LXFQLIB     =  -1  -- Query Lexam library (๛)
   LXFFINIS    =  -2  -- Drop all dicts & terminate (๛)
   LXFPRFLINE  =  -3  -- Proof an entire line in file
   LXFSETPUNCT =  -4  -- Set punctuation for ProofLine

   -- Return codes
   LXRFGOOD = 0000    -- Function Successful:  Good Return Code
   LXRFUPDC = 0005    -- Function Successful:  Updateable dictionary created
   LXRFNFND = 0100    -- Function Unsuccessful: Word Not Found
   LXRFDUPD = 0107    -- Function Unsuccessful: Duplicate Dictionary
   LXRFINIT = 0200    -- PC LEXAM Not Initialized: Control Block/Parameter Err
   LXRFIFCN = 0201    -- Invalid Function

   DEFAULT_LEXAM_PUNCTUATION = '~!@#$%^&*()_+|`1234567890-=\{}[]:";''<>?,./ชฤอษปศผฺฟภูบหฬนสฮยรดมลณ'

   -- Code for USE_CUSTOM_PROOF_DIALOG <> 1 was removed in the following
   --USE_CUSTOM_PROOF_DIALOG = 1

definit
   universal addenda_has_been_modified
   universal addenda_filename
   universal dictionary_filename
   universal Dictionary_loaded
   universal lexam_punctuation

   lexam_punctuation = DEFAULT_LEXAM_PUNCTUATION
compile if defined( MY_LEXAM_PUNCTUATION)
   'proof_punctuation' MY_LEXAM_PUNCTUATION
compile endif

; Note:  don't initialize the universals here for EPM if SPELL_SUPPORT =
; 'DYNALINK'; it will be done in STDCNF so that this won't override the
; config info read from the .INI file.
compile if SPELL_SUPPORT <> 'DYNALINK'
 compile if defined( MY_ADDENDA_FILENAME)
   addenda_filename = MY_ADDENDA_FILENAME
 compile else
   addenda_filename = 'c:\lexam\lexam.adl'
 compile endif

 compile if defined( MY_DICTIONARY_FILENAME)
   dictionary_filename = MY_DICTIONARY_FILENAME
 compile else
   dictionary_filename = 'us.dct'
 compile endif
compile endif

   addenda_has_been_modified = 0
   Dictionary_loaded = 0

/*
ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ Synonym Support                                                            บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
*/
/*
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ What's it called: syn                                                      ณ
ณ                                                                            ณ
ณ What does it do : The syn command uses E's lexam support to retrieve       ณ
ณ                   possible synonyms for a specified word.                  ณ
ณ                   If synonyms are found a                                  ณ
ณ                   PM list box is shown containing the possible new words.  ณ
ณ                                                                            ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
*/
defc syn
   if load_lexam() then
     return
   endif
   call pbegin_word()
   call synonym()
   call drop_dictionary()


/*
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ What's it called: synonym()                                                ณ
ณ                                                                            ณ
ณ What does it do : checks the next word on a line for its possible synonyms.ณ
ณ                   possible synonyms for a specified word.                  ณ
ณ                   If synonyms are found a                                  ณ
ณ                   PM list box is shown containing the possible new words.  ณ
ณ                                                                            ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
*/
defproc synonym()
   getline line                              -- get the current line
   line = translate( line, ' ', \9)  -- Convert tabs to spaces
   if line <> '' then                        -- if it is NOT blank
      i = .col                               -- get the current column number
      l = pos( ' ', line, .col)              -- get possible word
      if l = 0 then                          -- could this be a word?
         l = length( line) + 1
         if l < i then
            l = i
         endif
      endif
      wrd = strip( substr( line, i, l - i))  -- extract word candidate
      oldwordlen = length( wrd)              -- save the length of the word   */
      result = lexam( LXFVERFY, wrd)         -- authenticate word using lexam */
      if result and wrd <> '' then           -- was it a success?
         call strippunct( wrd, l, i)
        .col = .col + i - 1
         result = lexam( LXFVERFY, wrd)
      endif
      if (result <> LXRFGOOD) then           -- was it a success?
         sayerror NO_MATCH__MSG '<'wrd'>'    -- no
         return ''                           -- exit function
      endif
      -- It's a word!
      -- Get list of synonyms using lex
      parse value lexam(LXFSYN,wrd) with 2 '/' result
      if result='' then
         sayerror NO_SYN__MSG '<'wrd'>'
         return ''
      endif

      parse value listbox(SYNONYMS__MSG,'/'result,'/'REPLACE__MSG'/'CANCEL__MSG'/'HELP__MSG'/',0,0,0,0,
                          gethwndc(APP_HANDLE) || atoi(1) || atoi(1) || atoi(14002) || \26 wrd) with button 2 newword \0
      if button<>\1 then
         newword = ''
      endif
      if newword<>'' then
         getsearch oldsearch
         'xcom c '\1 || wrd || \1 || newword || \1
         setsearch oldsearch
         return length(newword)-oldwordlen
      endif
   endif

/*
ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ Spell Checking Support                                                     บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
*/

compile if PROOF_DIALOG_FIXED
   define DIALOG_POSN = ', -2, .windowwidth'
compile else
   define DIALOG_POSN = ', 0, 0 '
compile endif


/*
ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ Addenda Support                                                            บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
*/
/*
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ What's it called: maybe_save_addenda                                       ณ
ณ                                                                            ณ
ณ What does it do :                                                          ณ
ณ                                                                            ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
*/
; Addenda support commands

defproc AddendaCase
   if RESPECT_case_for_addenda then
      return lowcase( arg(1))
   else
      return arg(1)
   endif

defproc maybe_save_addenda
   universal addenda_has_been_modified
   universal AMU_addenda_file_identification
   universal addenda_filename
   universal Dictionary_loaded

   if Dictionary_loaded < 2 then
;   if addenda_has_been_modified then
     -- sayatbox 'saving addenda 'addenda_filename
      if AMU_addenda_file_identification <> ''  then
       getfileid AMU_current_file_identification
       rc = 0
       activatefile AMU_addenda_file_identification
       if not rc then
          if .modify then
             'xcom save'
          endif
;;        'xcom quit'
       endif
       -- sayerror 'addenda file filed'
       activatefile AMU_current_file_identification
      endif
      addenda_has_been_modified=0
      -- sayerror 0
   endif

;defc AMU_addenda_pickup
;   universal addenda_filename
;
;   call lexam( LXFAMUGDIC, addenda_filename)

;defc AMU_addenda_addition
;   call lexam( LXFAD2TRS, arg(1))

defproc AMU_addenda_processing
   universal AMU_addenda_file_identification
   universal addenda_filename

   getfileid AMU_current_file_identification
   'xcom e' addenda_filename
   -- sayerror 'addenda file loaded'
   if not rc or rc = sayerror('New file') then
      getfileid AMU_addenda_file_identification
   else
      AMU_addenda_file_identification = ''
      sayerror BAD_ADDENDA__MSG addenda_filename 'rc =' rc
      return rc  -- was STOP; made non-fatal
   endif
   .visible = 0 -- hidden file
   activatefile AMU_current_file_identification
   if AMU_addenda_file_identification <>'' then
      for i = 1 to AMU_addenda_file_identification.last
         getline line, i, AMU_addenda_file_identification
         if upcase( leftstr( line, 8)) = '.DU ADD ' then
            line = substr( line, 9)
         endif
         do while line <> ''
            parse value line with wrd line
            call lexam( LXFAD2TRS, AddendaCase( wrd))
         enddo
      endfor
   endif

defproc AMU_addenda_addition_processing( AMU_addenda_entry)
   universal addenda_has_been_modified
   universal AMU_addenda_file_identification
   universal addenda_filename

   addenda_has_been_modified = 1
   call lexam( LXFAD2TRS, AddendaCase( AMU_addenda_entry))
   if addenda_filename <> '' & AMU_addenda_file_identification <> '' then
      insertline AMU_addenda_entry, AMU_addenda_file_identification.last + 1,
         AMU_addenda_file_identification
   endif

/*
ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ General Lexam Support                                                      บ
ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ
*/
defproc load_lexam
   universal dictionary_filename
   universal addenda_filename
   universal Dictionary_loaded

   -- Quickly check if already configured
   if dictionary_filename = '' then
      'AskDictConfig'
      return 1
   endif

   if not dictionary_loaded then
      rc = 0
      result = lexam( LXFINIT)
      if (result <> LXRFGOOD and result <> LXRFIFCN) or rc = -322 then
         if result = 'febe' or rc = -322 then  -- x'febe' = -322 = sayerror('Dynalink: unrecognized library name')
         else
            sayerror INIT_ERROR__MSG '('rc')'
         endif
         return 1
      endif
      dictlist = dictionary_filename
      do while dictlist <> ''
         parse value dictlist with dictionary dictlist
         if not(verify(dictionary,'\:','M')) then
            if not exist(dictionary) then
               findfile destfilename, dictionary, '','D'
               if not rc then
                  dictionary = destfilename
               endif
            endif
         endif
         result=lexam( LXFGDIC, dictionary)
         if result>=LXRFNFND & result<>LXRFDUPD then  -- Duplicate Dictionary; didn't unload?
            if exist(dictionary) then
               sayerror BAD_DICT__MSG '"'dictionary'";' ERROR__MSG result
            else
               'AskDictConfig' dictionary
;              sayerror NO_DICT__MSG '"'dictionary'"'  DICT_PTR__MSG
            endif
            return 1
         endif
      enddo
      if addenda_filename<> '' then
         result = lexam( LXFAMUGDIC, addenda_filename)
         if result & result <> LXRFUPDC then
            sayerror BAD_ADDENDA__MSG '"'addenda_filename'";' ERROR__MSG result
         else
            call AMU_addenda_processing()
         endif
      endif
   endif
   dictionary_loaded = dictionary_loaded + 1
   return 0

defc AskDictConfig
   parse arg dictionary
   Text = 'Use Edit -> Spellcheck -> Select dictionaries... to change dictionary.'
   Text = 'Configure dictionaries now?'
   if MBID_YES = winmessagebox( PROOF__MSG, NO_DICT__MSG\10'"'dictionary'"'\10\10 ||
                                /*DICT_PTR__MSG*/Text,
                                MB_YESNO + MB_QUERY + MB_MOVEABLE) then
      'DictLang'
   endif

defproc drop_dictionary
   universal dictionary_filename
   universal addenda_filename
   universal Dictionary_loaded

   if dictionary_loaded then
      dictionary_loaded = dictionary_loaded - 1
   endif
   if not dictionary_loaded then  -- Only unload if use-count now 0.
      dictlist = dictionary_filename
      do while dictlist <> ''
         parse value dictlist with dictionary dictlist
         call lexam( LXFFDIC, dictionary)
      enddo
      if addenda_filename <> '' then
         call lexam( LXFFDIC, addenda_filename)
      endif
      call lexam( LXFTERM)
   endif

defproc strippunct( var wrd, var l, var i)
   universal lexam_punctuation

   -- strip leading and trailing punctuation and try again
   i = verify( wrd, lexam_punctuation)
   if i then
      j = length( wrd)
      do while pos( substr( wrd, j, 1), '.?!,:;')  -- Extra check, to accept "didn't."
         j = j - 1
      enddo
      if j < length( wrd) then
         if not lexam( LXFVERFY, leftstr( wrd, j)) then  -- If result is 0, word is good.
            i = 1
;;          l = l - length(wrd) + j
            wrd = leftstr( wrd, j)
            return
         endif
      endif
      l = l - length( wrd)
      wrd = substr( wrd, i)
      j = verify( wrd, lexam_punctuation, 'm')
      if j then
         wrd = leftstr( wrd, j - 1)
      else
         j = length( wrd) + 1
      endif
      l = l + j + i - 2
   else
      i = length( wrd) + 1
   endif

defc dict
   universal dictionary_filename

   dictlist = arg(1)
   if dictlist='' then
      sayerror DICTLIST_IS__MSG dictionary_filename
      return
   endif
   do while dictlist <> ''
      parse value dictlist with dictionary dictlist
      if not exist(dictionary) then
         sayerror FILE_NOT_FOUND__MSG '"'dictionary'"; 'DICT_REMAINS__MSG dictionary_filename
         return
      endif
   enddo
   dictionary_filename = arg(1)

defc proof_punctuation
   universal lexam_punctuation

   if arg(1) <> '' then
      newpunct = DEFAULT_LEXAM_PUNCTUATION
   else
      newpunct = arg(1)
   endif
   result = lexam( LXFSETPUNCT, newpunct)        -- Set punctuation
   if result then
      sayerror result
   else
      lexam_punctuation = newpunct
   endif

; Commands for use with custom Proof dialog

; Proof - proofs the document or marked area.
;    It uses the new Lexam subop that proofs lines and doesn't stop
;    until it hits an error or finishes the last line.
; ProofWord - proofs the current word.

; Both set up state information, then call SpellWordD (like SpellWord) to check
; an individual word.  If SpellWordD decides the word is bad, then if the dialog
; has been started, it tells it to display the word, otherwise it starts the
; dialog and relies on the Init message coming from the dialog to tell the dialog
; to show the word.

; State information:
;  proofdlg_hwnd      Proof Dialog's window handle
;  proofdlg_whatflag  What we're proofing - 1 = file, 2 = mark, 3 = word in file, 4 = word as PROOF argument
;  proof_curline      Current line we're checking
;  proof_lastline     Last line to be checked
;  proof_lexresult    Result from Lexam(proofline)
;  proof_resultofs    Current offset in proof_lexresult we're checking
;  proof_offst        offset from the columns in proof_lexresult we should use
;                     (changes from 0 if we replace an earlier word in that line
;                     with one of a different length)
;  proof_prev_col     Saves the previous column (to be used after replacing
;                     a word with a user-entered word; we need to use the old offset,
;                     not the new one).

defc proof
   universal proofdlg_hwnd
   universal proofdlg_whatflag
   universal proof_curline
   universal proof_lastline
   universal proof_lexresult
   universal proof_word

   if load_lexam() then
      return
   endif

   if arg(1) <> '' then  -- A word to be proofed was given as an argument.
      proofdlg_whatflag = 4
      result = lexam( LXFVERFY, arg(1))           -- verify word
      if not result then    -- was it a success
         call drop_dictionary()
         sayerror SPELLED_OK__MSG
         return
      endif
      proof_word = arg(1)
      if proofdlg_hwnd then  -- Dialog started
         'proofdlg' proofdlg_hwnd 'newword'
      else
         sayerror 0        -- (Clear a "Spell checking..." message, if one was up.)
         'proofdlg pop'    -- Start the dialog; it will do the rest
      endif
      return
   endif

   -- If there's a line-marked area in the current file, proof only in there.
   proof_curline = max( .line, 1)
   proof_lastline = .last
   proofdlg_whatflag = 1
   if marktype() then  -- if no mark, default to entire file
      getfileid curfileid
      getmark fl, ll, fc, lc, markfileid
      if markfileid = curfileid then
         proof_curline = fl
         proof_lastline = ll
         proofdlg_whatflag = 2
      endif
   endif

   proof_lexresult = ''
   'keep_on_prufin'

defc keep_on_prufin
   universal addenda_filename
   universal proofdlg_hwnd
   universal proofdlg_whatflag
   universal proof_curline
   universal proof_lastline
   universal proof_lexresult
   universal proof_resultofs
   universal proof_offst
   universal proof_prev_col

   Mode = GetMode()
   proofdlg_filetypeflags = wordpos( Mode, 'IPF SCRIPT' > 0) +
                            2 * (Mode = 'TEX') +
                            4 * (Mode = 'HTML')

   while proof_curline <= proof_lastline do
      if not proofdlg_hwnd then
;;       sayerror 'Spell Checking 'subword('file marked area', proofdlg_whatflag, proofdlg_whatflag)'...'
         if proofdlg_whatflag=1 then
            'SayHint' CHECKING__MSG FILE__MSG
         elseif proofdlg_whatflag=1 then
            'SayHint' CHECKING__MSG MARKED_AREA__MSG
         endif
;;    else
;;       msg = 'Checking spelling...'\0
;;       call windowmessage(1,  proofdlg_hwnd,   -- send message back to dialog
;;                          32,               -- WM_COMMAND - 0x0020
;;                          9190,             -- Set dialog prompt
;;                          ltoa(offset(msg) || selector(msg), 10) )
      endif
      if proof_lexresult = '' then
         .col = 1
         -- All args of lexam must be numbers
         proof_lexresult = lexam( LXFPRFLINE, proof_curline, proof_lastline, proofdlg_filetypeflags)
;sayerror 'proof_lexresult('proof_curline',' proof_lastline') =' c2x(leftstr(proof_lexresult,4)) c2x(substr(proof_lexresult, 5))
         proof_resultofs = 5
         proof_offst = 0
         proof_prev_col = ''
      endif
      if length( proof_lexresult) then
;sayerror 'rc=' rc'; proof_lexresult =' c2x(proof_lexresult)
         proof_curline = ltoa( leftstr( proof_lexresult, 4), 10)
         if length( proof_lexresult) = 4 then
            sayerror PROOF_ERROR1__MSG proof_curline PROOF_ERROR2__MSG
            proof_curline = proof_curline + 1
            proof_lexresult = ''
            iterate
         endif
         proof_curline
         oldlen = length( textline( proof_curline))
         do i = proof_resultofs to length( proof_lexresult) by 2
            if proof_prev_col then
               .col = proof_prev_col
            else
               .col = itoa( substr( proof_lexresult, i, 2), 10) + proof_offst
            endif
            t = spellwordd( '')    -- spell check the word
;sayerror 'i='i'; .col =' .col '=' itoa(substr(proof_lexresult, i, 2), 10) + proof_offst'; proof_offst='proof_offst 't='t
            if t = -3 then  -- Dialog will continue
               proof_resultofs = i + 2
               return
            endif
            proof_prev_col = ''
            if not t then                         -- error occured
               leave
            endif
         enddo
         proof_curline = proof_curline + 1
         proof_lexresult = ''
      else  -- proofed the entire block successfully
         leave
      endif
   endwhile

   if addenda_filename <> '' then
      call maybe_save_addenda()
   endif
   call drop_dictionary()
   if proofdlg_hwnd then
      call windowmessage( 0, proofdlg_hwnd,  -- send message to dialog
                          41,                -- WM_CLOSE - 0x0029
                          0,
                          0)
   endif
   if arg(1) = '' then
      sayerror DONE__MSG
   endif

defc proofword, verify
   universal proofdlg_whatflag

   if load_lexam() then
     return
   endif
   orig_col = .col
   call pbegin_word()
   if substr( textline( .line), orig_col, 1) = ' ' & .col < orig_col then
      tmp = .col
      call pend_word()
      orig_col = .col
      .col = tmp
   endif
   proofdlg_whatflag = 3
   spellrc = spellwordd( '', orig_col, arg(1))
   if -2 = spellrc then
      sayerror SPELLED_OK__MSG
      call drop_dictionary()
              -- Otherwise, closing the dialog will unload lexam.
   endif

; return codes:  0 = unexpected error (line blank)
;       X       >0 = 100 + length(newword)-length(oldword)
;       X       -1 = Lookup failed or user selected Next or (Temp)Add; go on to next word.
;               -2 = Word was spelled correctly
;               -3 = Dialog invoked
;       X       -4 = User selected Edit; recheck line.
;      (X means not returned by this version of the routine.)
defproc spellwordd
   universal lexam_punctuation
   universal proofdlg_hwnd
   universal proof_word

   Mode = GetMode()
   getline line
   line = translate( line, ' ', \9)  -- Convert tabs to spaces
   if line='' then                        -- if the line is empty...
      return 0
   endif
   i = .col                               -- save the cursor column
   l = pos( ' ', line, .col)              -- get next word after cursor
   if l = 0 then                          -- is it a word?
      l = max( length( line) + 1, i)
   endif
   wrd = strip( substr( line, i, l - i))  -- extract word from line
   if wrd = '' then
      return -2
   endif
   if not verify( wrd, lexam_punctuation) then  -- No letters in "word"; skip it.
      return -2
   endif
   result = 1
   if wordpos( Mode, 'IPF SCRIPT') > 0 then  -- Do just the cheap test first.
      tmp = substr( line, max( .col - 1, 1), 1)
      if (pos( leftstr( wrd, 1), ':&.') or pos( tmp, ':&')) then
         result = 0
         if leftstr( wrd, 1) = ':' | tmp = ':' then
            tmp = pos( '.', line, .col)
            if tmp then
               result = 1
               .col = tmp + 1
               wrd = substr( wrd, .col)
;              l = tmp
            endif
         endif
      endif
   elseif Mode = 'TEX' & pos( '\', wrd) then
      result = 0
   endif
   if result then  -- If not set to 0 by SCRIPT or TeX
      result = lexam( LXFVERFY,wrd)          -- verify word
   endif
   start_l = l
   if result then                         -- was it a success?
      do forever
         call strippunct( wrd, l, i)         -- strip punctuation and try again
         .col = .col + i - 1                 -- move to next column
         if wrd = '' then
            return -2
         endif
         if l >= arg(2) then  -- Will always be true if arg(2) omitted.
            leave
         endif
         .col = l
         l = start_l
         wrd = strip( substr( line, .col, l - .col))  -- extract word from line
      enddo
      result = lexam( LXFVERFY,wrd)       -- try word verification again
   endif
   if not (result or abbrev( 'FORCE', upcase( arg(3)), 1)) then  -- was it a success?
      --.messageline = 'word is spelled correctly'
      if l < start_l & arg(2) = '' then
         .col = l
         return spellwordd( arg(1))
      endif
      return -2
   endif
   proof_word = wrd
   if proofdlg_hwnd then  -- Dialog started
      'proofdlg' proofdlg_hwnd 'newword'
   else
      sayerror 0        -- (Clear a "Spell checking..." message, if one was up.)
      'proofdlg pop'    -- Start the dialog; it will do the rest
   endif
   return -3

#define PRFDLG_REPLACE     9103    -- Proof dialog buttons
#define PRFDLG_NEXT        9105
#define PRFDLG_TEMPADD     9106
#define PRFDLG_ADD         9107
#define PRFDLG_HELP        9108
#define PRFDLG_EDIT        9111
#define DID_CANCEL            2

defc proofdlg
   universal addenda_filename
   universal proofdlg_hwnd
   universal proof_word
   universal proofdlg_whatflag
   universal proof_offst
   universal proof_resultofs
   universal proof_prev_col
   universal dynaspel_closecmd
;; universal proof_nextcol  -- temp

   parse arg hndle opt rest
   continue = 0

   if arg(1) = 'pop' then

compile if E_DLL = 'UTKE600'
      call windowmessage( 0,  getpminfo(EPMINFO_OWNERCLIENT),
                          5549,    --WM_USER + 0x0500 + 0x00AD = OBJEPM_PROOFDLG
                          0,
                          0)
compile else
      call windowmessage( 0,  getpminfo(APP_HANDLE),
                          5150,               -- EPM_POPPROOFDLG
                          0,
                          0)
compile endif -- E_DLL = 'UTKE600'

   elseif opt = 'init' then

      if proofdlg_whatflag = 1 then
         msg = CHECKING__MSG FILE__MSG\0
      elseif proofdlg_whatflag = 2 then
         msg = CHECKING__MSG MARKED_AREA__MSG\0
      elseif proofdlg_whatflag = 3 | proofdlg_whatflag = 4 then
         msg = PROOF_WORD__MSG\0
      else
         return
      endif
      call windowmessage( 1, hndle,   -- send message back to dialog
                          32,               -- WM_COMMAND - 0x0020
                          9193,             -- Set dialog title
                          ltoa(offset(msg) || selector(msg), 10))
      proofdlg_hwnd = hndle
      if proof_word <> '' then
         'proofdlg' proofdlg_hwnd 'newword'
      endif

   elseif opt = 'newword' then

      if proof_word <> '' then
         oldwordlen = length( proof_word)
         oldcol = .col
         .col = .col + oldwordlen
         .col = oldcol
         circleit PROOF_CIRCLE_STYLE, .line, .col, .col + oldwordlen - 1,
            PROOF_CIRCLE_COLOR1, PROOF_CIRCLE_COLOR2
;;       refresh  -- Refresh required to display circle, because control isn't being returned to the user
         msg = \26 proof_word\0  -- \26 is right arrow (also, EOF character!)
         call windowmessage( 1, proofdlg_hwnd,   -- send message back to dialog
                             32,               -- WM_COMMAND - 0x0020
                             9191,             -- Set current word being proofed
                             ltoa(offset(msg) || selector(msg), 10))
      endif
      -- The following must be here, because 9191 re-enables the buttons.
      if proofdlg_whatflag = 3 | proofdlg_whatflag = 4 then
         call windowmessage( 1, proofdlg_hwnd,   -- send message back to dialog
                             32,               -- WM_COMMAND - 0x0020
                             9195,             -- Disable buttons
                             2 + 8 + (64 + 1)*(proofdlg_whatflag = 4) )  -- Temp. Add, Next, and for whatflg=4, Edit & Replace
compile if PROOF_NEXT_DEFAULT
      else
         call windowmessage( 1, proofdlg_hwnd,   -- send message back to dialog
                             32,               -- WM_COMMAND - 0x0020
                             9196,             -- Set default button
                             PRFDLG_NEXT)
compile endif
      endif

   elseif opt = 'suggest' then

       oldwordlen = length( proof_word)
       circleit PROOF_CIRCLE_STYLE, .line, .col, .col + oldwordlen - 1,
          PROOF_CIRCLE_COLOR1, PROOF_CIRCLE_COLOR2
       parse value lexam( LXFSPAID, proof_word) with 2 '/' result
       if rc >= LXRFINIT then
          msg = LOOKUP_FAILED__MSG '<' proof_word '> RC='rc\0
          call windowmessage( 1, hndle,   -- send message back to dialog
                              32,               -- WM_COMMAND - 0x0020
                              9190,             -- Set dialog prompt
                              ltoa(offset(msg) || selector(msg), 10))
       elseif result = '' then
          msg = WORD_NOT_FOUND__MSG '<' proof_word '>'\0
          call windowmessage( 1, hndle,   -- send message back to dialog
                              32,               -- WM_COMMAND - 0x0020
                              9190,             -- Set dialog prompt
                              ltoa(offset(msg) || selector(msg), 10))
       else
          msg = result\0
compile if PROOF_NEXT_DEFAULT
          call windowmessage( 1, proofdlg_hwnd,   -- send message back to dialog
                              32,               -- WM_COMMAND - 0x0020
                              9196,             -- Set default button
                              PRFDLG_REPLACE)
compile endif
          call windowmessage( 1, hndle,   -- send message back to dialog
                              32,               -- WM_COMMAND - 0x0020
                              9192,             -- Fill listbox
                              ltoa(offset(msg) || selector(msg), 10))
       endif

   elseif opt = 'edit' then

      msg = proof_word\0
      call windowmessage(1,  hndle,   -- send message back to dialog
                         32,               -- WM_COMMAND - 0x0020
                         9197,             -- Set entry field
                         ltoa(offset(msg) || selector(msg), 10) )

   elseif opt = 'rep_l' | opt = 'rep_n' then  -- Replace from list / Replace with new word

      if proofdlg_whatflag <> 4 then  -- Shouldn't be, since we disable the button...
compile if 0  -- The following loses attributes.
         getline line
         replaceline leftstr( line, .col - 1) || rest || substr( line, .col + length( proof_word))
compile else  -- A Change command will preserve them.
         getsearch oldsearch
         'xcom c '\1 || proof_word || \1 || rest || \1
         setsearch oldsearch
compile endif
      endif
      continue = 1
      if proofdlg_whatflag < 3 then
         proof_offst = proof_offst + length( rest) - length( proof_word)
         if opt = 'rep_n' then  -- Replace from list / Replace with new word
            proof_resultofs = proof_resultofs - 2  -- back up one word (recheck replaced word)
            proof_prev_col = .col
;;            proof_nextcol = .col
         endif
      endif

   elseif opt = 'add' then

      call AMU_addenda_addition_processing( proof_word)
      continue = 1

   elseif opt = 'tempadd' then

      call lexam( LXFAD2TRS, AddendaCase( proof_word))
      continue = 1

   elseif opt = 'next' then

      continue = 1

   elseif opt = 'close' then

      if addenda_filename <> '' then
         call maybe_save_addenda()
      endif
      call drop_dictionary()
      proofdlg_hwnd = ''
      if dynaspel_closecmd then
         dynaspel_closecmd
         dynaspel_closecmd = ''
      endif

   else

      sayerror 'ProofDlg' arg(1)

   endif

;sayerror 'proofdlg "'arg(1)'", continue =' continue
   if continue then  -- Continue to next word
;;      .col = proof_nextcol
      if proofdlg_whatflag >= 3 then  -- We were proofing a single word; all done!
         call windowmessage( 0, hndle,          -- send message to dialog
                             41,                -- WM_CLOSE - 0x0029
                             0,
                             0)
      else  -- really have to keep going
         call windowmessage( 1, hndle,   -- send message back to dialog
                             32,               -- WM_COMMAND - 0x0020
                             9194,             -- Disable everything
                             0)
         if opt <> 'rep_n' then
            proof_prev_col = ''
         endif
         'keep_on_prufin'
      endif
   endif

defc SpellProofNext
   universal lexam_punctuation
   universal EPM_utility_array_ID
   universal dynaspel_line
   universal dynaspel_col

   Mode = GetMode()
   saveline = .line
   savecol = .col - 1
   getfileid fid
   getline line, saveline
   if not savecol or line = '' then
      dprintf( 'SPELL', '[Line was blank]')
      return
   endif
   if substr( line, savecol, 1) = ' ' then
      dprintf( 'SPELL', '[Prev. char was blank]')
      return
   endif
;  newcol = .col
   start = lastpos( ' ', line, savecol)
;  wrd = substr( line, start + 1, savecol - start)
   parse value substr( line, start + 1) with wrd .
   if not verify( wrd, lexam_punctuation) then  -- No letters in "word"; skip it.
      dprintf( 'SPELL', '[Only punctuation in word 'wrd']')
      return
   endif
   firstchar = leftstr( wrd, 1)
   if firstchar = '\' then             -- Do the cheap test first
      if Mode = 'TEX' then
         dprintf( 'SPELL', '[TEX token: 'wrd']')
         return
      endif
   elseif pos( firstchar, ':&') then  -- (Do the cheap test first)  Script markup or variable?
      if wordpos( Mode, 'IPF SCRIPT') > 0 then
         p = pos( '.', wrd)
         if p & p < length( wrd) then
            wrd = substr( wrd, p + 1)
         else
            if firstchar='&' then
               dprintf( 'SPELL', '[SCRIPT variable: 'wrd']')
            else
               dprintf( 'SPELL', '[SCRIPT markup: 'wrd']')
            endif
            return
         endif
      endif
   elseif firstchar='.' & not start then  -- (Do the cheap test first)  SCRIPT control word?
      if wordpos( Mode, 'IPF SCRIPT') > 0 then
         dprintf( 'SPELL', '[SCRIPT control word: 'wrd']')
         return
      endif
   endif
   result = lexam( LXFVERFY, wrd)      -- authenticate word using lexam
   if result then
      call strippunct( wrd, savecol, tmp)
      result = lexam( LXFVERFY, wrd)
   endif
   if (result <> LXRFGOOD) then         -- was it a success?
compile if DYNASPELL_BEEP = 'ALARM'
      call dynalink32( 'PMWIN',
                       '#701',     -- ORD_WIN32ALARM
                       atol(1) ||  -- HWND_DESKTOP
                       atol(0))    -- WA_WARNING
compile elseif DYNASPELL_BEEP
      call beep( 1000, 100)
compile endif
      dynaspel_line = saveline
      dynaspel_col = savecol
      sayerror DYNASPEL_PROMPT1__MSG || wrd || DYNASPEL_PROMPT2__MSG
   else
      dprintf( 'SPELL', '[Word was 'wrd' - OK]')
   endif

defc SpellProofCurWord
   universal dynaspel_line
   universal dynaspel_col
   universal dynaspel_closecmd

   if not dynaspel_line then
      sayerror DYNASPEL_NORECALL__MSG
      return
   endif
   if .line = dynaspel_line then
      oldlen = length( textline( dynaspel_line))
   endif
   call psave_pos( save_pos)
   dynaspel_line
   .col = dynaspel_col
   dynaspel_closecmd = 'dynaspell_restorepos' oldlen save_pos
   'ProofWord'

defc dynaspell_restorepos
   universal dynaspel_line
   universal dynaspel_col

   parse arg oldlen save_pos
   call prestore_pos( save_pos)
   if .line = dynaspel_line then
      diff = length( textline( dynaspel_line)) - oldlen
      if diff > 0 then
         right diff
      elseif diff < 0 then
         left -diff
      endif
   endif

; Takes no arguments, just toggles setting.
defc dynaspell
   universal EPM_utility_array_ID
   universal addenda_filename
   universal activeaccel

   getfileid fid
   if activeaccel <> 'spell' then  -- Dynamic spell-checking off for this file
      if load_lexam() then
         return
      endif
      call SetAVar( 'prevkeyset.'fid, activeaccel)
      -- Extend keyset
      'SetKeyset spell' activeaccel'value' 'spell'
   else  -- Dynamic spell-checking is on; now being turned off.
      if addenda_filename <> '' then
         call maybe_save_addenda()
      endif
      call drop_dictionary()
      -- Restore keyset
      PrevKeyset = GetAVar( 'prevkeyset.'fid)
      'SetKeyset' PrevKeyset
   endif

