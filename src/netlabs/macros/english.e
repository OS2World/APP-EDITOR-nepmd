; This file defines the various text constants as English strings.
; The comments (after the '--' are examples of how the string is used, and need not
; be translated.  For example,
           --      'Got' number 'bytes from a' number'-byte buffer'  number 'lines'
; means that the strings GOT__MSG, BYTES_FROM_A__MSG, BYTE_BUFFER__MSG, and LINES__MSG
; should make sense when put together as indicated.  In some cases, this is abbreviated
;  ERROR_LOADING__MSG =   'Error trying to load'  -- filename
; which means the message will say "Error trying to load <filename>" (for some file).
;
; Anything that has a Yes/No prompt should include YES_CHAR and NO_CHAR (defined below);
; if the words for YES and NO start with the same letter in some language, a synonym for
; one or both should be consistently used so that the initial letters are unique.

;  This file should be named:  (8 characters or less, please!)
;                              (and *not* the 2-character DK, FR, GR, etc.)
;  (This is what this file would be called if we were to release a package
;  containing all the translated versions of ENGLISH.E.  Instead of 20 copies
;  of "ENGLISH.E", the French one would be "FRANCAIS.E", the Spanish one
;  "ESPANOL.E", etc.)

;     NLS_LANGUAGE = 'ENGLISH'

const
; The following constants are defined in STDCNF.E; if they're not set by the
; time we get here, then we're being included by some external file, so their
; value isn't important.

compile if not defined(WANT_DYNAMIC_PROMPTS)
   WANT_DYNAMIC_PROMPTS = 0
compile endif
compile if not defined(WANT_BOOKMARKS)
   WANT_BOOKMARKS = 0
compile endif
compile if not defined(WANT_TAGS)
   WANT_TAGS = 0
compile endif
compile if not defined(SPELL_SUPPORT)
   SPELL_SUPPORT = 0
compile endif
compile if not defined(CHECK_FOR_LEXAM)
   CHECK_FOR_LEXAM = 0
compile endif
compile if not defined(HOST_SUPPORT)
   HOST_SUPPORT = 'STD'
compile endif
compile if not defined(WANT_STACK_CMDS)
   WANT_STACK_CMDS = 0
compile endif
compile if not defined(WANT_TOOLBAR)  -- Different logic than is in STDCNF.E, but
   WANT_TOOLBAR = 0                   -- if not set by STDCNF or EXTRA, NLS stuff not needed.
compile endif

;; Box.e  -- Try to keep P, C, A, E, R & S the same; otherwise requires macro changes
   BOX_ARGS__MSG =        'Args: 1=³ 2=º 3=| 4=Û 5=Ø 6=× B=Spc /Any  P=Pas C=C A=Asm E=Erase R=Reflow S=Scr'
   BOX_MARK_BAD__MSG =    'Marked area is not inside a box'

compile if EVERSION >=4
;; Buff.e
   CREATEBUF_HELP__MSG =  ' CREATEBUF  creates EBUF buffer; "CREATEBUF 1" for a private buffer.'
   PUTBUF_HELP__MSG =     ' PUTBUF     puts file, cur. line to end, in buffer.'
   GETBUF_HELP__MSG =     ' GETBUF     gets contents of buffer into file.'
   FREEBUF_HELP__MSG =    ' FREEBUF    frees the buffer.'
   ERROR_NUMBER__MSG =    'error number'
   EMPTYBUF_ERROR__MSG =  'Buffer empty, nothing to get'
                  --      'Got' number 'bytes from a' number'-byte buffer'  number 'lines'
   GOT__MSG =             'Got'
   BYTES_FROM_A__MSG =    'bytes from a'
   PUT__MSG =             'Put'
   BYTES_TO_A__MSG =      'bytes to a'
   BYTE_BUFFER__MSG =     '-byte buffer'
   CREATED__MSG =         'Created.'
   FREED__MSG =           'Freed.'
   MISSING_BUFFER__MSG =  'You must supply a buffer name.'
             --      'Buffer overflow?  It accepted only' noflines 'lines.'
   ONLY_ACCEPTED__MSG =   'Buffer overflow?  It accepted only'
   CAN_NOT_OPEN__MSG =    'Unable to open a buffer named'
compile endif

compile if EVERSION >= 5
;; Clipbrd.e
   NO_MARK_NO_BUFF__MSG = 'No marked area, and shared buffer is empty.'
   CLIPBOARD_EMPTY__MSG = 'The clipboard is empty'
   CLIPBOARD_ERROR__MSG = 'Error reading clipboard'
   NOTHING_TO_PASTE__MSG ='Nothing to paste.'
   TRYING_TO_FREE__MSG =  'trying to free old'
   BUFFER__MSG =          'buffer'
   NO_MARK_DELETED__MSG = 'No mark was deleted from this window.'
   NO_TEST_RECOVERED__MSG='No text recovered.'
   ERROR_COPYING__MSG =   'Error occurred while copying'
   ONLY__MSG =            'Only'
   LINES_OF__MSG =        'lines of the original'
   RECOVERED__MSG =       'were recovered.'
   TOO_MUCH_FOR_CLIPBD__MSG= 'Too much selected text for clipboard buffer.'
   CLIPBOARD_VIEW_NAME =  '.Clipboard'  -- file name; initial '.' marks it as a temp file
compile endif

;; Modify.e
   AUTOSAVING__MSG =      'Autosaving...'

compile if EVERSION >= 5
;; Mouse.e
   UNKNOWN_MOUSE_ERROR__MSG = "Unknown error processing mouse event: "
compile endif

;; Dosutil.e
   TODAY_IS__MSG =        'Today is'
   THE_TIME_IS__MSG =     'The time is'
   MONTH_LIST =           'January  February March    April    May      '||
                          'June     July     August   SeptemberOctober  '||
                          'November December '
   MONTH_SIZE = 9     -- Length of the longest month name
   WEEKDAY_LIST =         'Sunday   Monday   Tuesday  Wednesday' ||
                          'Thursday Friday   Saturday Sunday   '
   WEEKDAY_SIZE = 9   -- length of the longest weekday name
   AM__MSG = 'am'
   PM__MSG = 'pm'
   ALT_1_LOAD__MSG =      'Move cursor to desired file and press Alt-1 to load it.'
   ENTER_CMD__MSG =       'Enter OS/2 command'

;; Draw
   ALREADY_DRAWING__MSG = 'Already in DRAW mode.  Command ignored.'
   DRAW_ARGS__MSG =       'Valid args are:  1=³  2=º  3=|  4=Û  5=Ø  6=×  B=blank  or  /Any character'
   DRAW_ARGS_DBCS__MSG =  'Valid args are:  1='\5'  2=|  3='\11'  4='\14'  5='\20'  6='\26'  B=blank  or  /Any character'
   DRAW_PROMPT__MSG =     'Draw mode:  '\27' '\26' '\24' '\25'  to draw;'||
                          '  Insert to raise the pen;  Esc or Enter to cancel.'
   DRAW_ENDED__MSG =      'Draw mode ended'

;; Get.e
   NO_FILENAME__MSG =     'No filename specified for'
   INVALID_OPTION__MSG =  'Invalid option'
   FILE_NOT_FOUND__MSG =  'File not found'
   FILE_IS_EMPTY__MSG =   'File is empty'
   NOT_2_COPIES__MSG =    'Not enough memory for two copies of'

;; Main.e
;;   The following name starts with a '.' to indicate that it's a temporary file:
;; UNNAMED_FILE_NAME =    '.Unnamed file'  -- Not any more; now:
   UNNAMED_FILE_NAME =    '.Untitled'

;; Mathlib.e
   SYNTAX_ERROR__MSG =    'Syntax error'

;; Put.e
   NO_CONSOLE__MSG =      'Can not save to console from a PM window.'
   MARK_APPENDED__MSG =   'Marked text written to'

;; Sort.e
                  --      'Sorting' number 'lines'
   SORTING__MSG =         'Sorting'
   LINES__MSG =           'lines'
   NO_SORT_MEM__MSG =     'Out of memory!  Unable to insert the sorted lines, file left as it was.'

;; Charops.e
   CHAR_ONE_LINE__MSG =   'Character marks must begin and end on the same line.'
   PFILL_ERROR__MSG =     'Error in PFill_Mark'
   TYPE_A_CHAR__MSG =     'Type a character'
   ENTER_FILL_CHAR__MSG = 'Enter fill character'
   FILL__MSG =            'Fill'  -- Title
   NO_CHAR_SUPPORT__MSG = 'Support for character marks was omitted.'

compile if EVERSION >= 4
;; Exit.e
   ABOUT_TO_EXIT__MSG =   'About to exit from E. '

;; Linkcmds.e
   LINK_COMPLETED__MSG =  'Link completed, module #'
   QLINK_PROMPT__MSG =    'Please specify the module name, as in  "qlink draw".'
   NOT_LINKED__MSG =      'is not linked'
   CANT_FIND1__MSG =      "Can't find"  -- sayerror "Can't find "module" on disk!"
   CANT_FIND2__MSG =      "on disk!"
   LINKED_AS__MSG =       'is linked as module #' -- sayerror module' is linked as module # 'result'.'
   UNABLE_TO_LINK__MSG =  'Unable to link:'
   UNABLE_TO_EXECUTE__MSG='Unable to execute command:'
compile endif

;; Math.e
   NO_NUMBER__MSG =       "Can't find a number (from cursor position to end of file)"

;; Stdcnf.e
   STATUS_TEMPLATE__MSG = 'Line %l of %s   Column %c  %i   %m   %f   '
   DIR_OF__MSG =          'Directory of'  -- Must match what DIR cmd outputs!

;; Window.e
   ZOOM_PROMPT__MSG =     'Your current Zoom window style is'
   CHOICES_ARE__MSG =     'Choices are'
   DRAG__MSG =            'Use arrows to drag window.  Press ENTER or ESC when done'
                -- 'DRAG' MESSY_ONLY__MSG  or 'SIZE' MESSY_ONLY__MSG
   MESSY_ONLY__MSG =      'may only be used with overlapping (messy-desk) windows'

;; Shell.e
   INVALID_ARG__MSG =     'Invalid arguments'

;; Sort.e       -- 'Sort:  Put 'noflines' lines in buffer, got 'noflinesback' lines back.'
                -- 'Sort:' PUT__MSG noflines SORT_ERROR1__MSG noflinesback SORT_ERROR2__MSG
   SORT_ERROR1__MSG =    'lines in buffer, got'
   SORT_ERROR2__MSG =    'lines back.'

;; Retrieve.e
   CMD_STACK_CLEAR__MSG= 'Command stack cleared.'
   CMD_STACK_EMPTY__MSG= 'Command stack is empty.'

compile if EVERSION >= 5
;; Help.e
   HELP_BROWSER__MSG =   'Help Browser'  -- Message box title
   HELP_STATUS__MSG =    ' Valid Keys -> Page Up,Page Down       F3,ESC=Close Help Window'
   NO_DROP__MSG =        'Can not drop files here.'
   SYS_ED__MSG =         'System Editor Warning!'
   SYS_ED1__MSG =        'Now, Why would you want to'\10'go and do a thing like that?'
             -- 'Error' err_no 'allocating memory segment; command halted.'
   ALLOC_HALTED__MSG =   'allocating memory segment; command halted.'
   QUICK_REF__MSG =      'Quick Reference'  -- Window title
compile endif

;; All.e
   NO_ALL_FILE__MSG =    '.ALL file not in ring.'
   BAD_ALL_LINE__MSG =   'Missing or invalid line number in .ALL file.'

compile if EVERSION >= 4
;; Eos2lex.e
   EOS2LEX_PROMPT1__MSG = 'Space=Display the list     Esc=Go on     F3 or F10=Stop'
   SPELLED_OK__MSG =      'word is spelled correctly'
                -- Limit the following to 80 characters.
   EOS2LEX_PROMPT2__MSG = 'Esc=Next   F4=Add to addenda   F5=Temp add    F8=global change    F3, F10=Cancel'
   MORE__MSG =            'more'
   NO_MATCH__MSG =        'No words match'  -- 'No words match' spellword
   EXIT_SPELL__MSG =      'Exit spell checking (Y/N)?'
   THINKING__MSG =        'thinking...'
   DONE__MSG =            'Proof complete.'
   NO_SYN__MSG =          'No known synonyms for' -- word
   BAD_DICT__MSG =        'Dictionary is in error.'
   INIT_ERROR__MSG =      'Initialization error.'
                     -- 'Error loading addenda' addenda_filename
   BAD_ADDENDA__MSG =     'Error loading addenda'
compile endif

compile if EVERSION >= 5
;; Shell.e           -- 'Error' rc 'creating shell object.'
   SHELL_ERROR1__MSG =    'creating shell object.'
   SHELL_ERROR2__MSG =    'creating edit file for shell.'
   NOT_IN_SHELL__MSG =    'Not in a command shell file.'
   SHELL_ERROR3__MSG =    'killing shell.'
                     -- 'Enter text to be written to shell' shell_number
   SHELL_PROMPT__MSG =    'Enter text to be written to shell'
                     -- 'shell object' number 'is willing to accept more data...'
   SHELL_OBJECT__MSG =    'shell object'
   SHELL_READY__MSG =     'is willing to accept more data...'
compile endif

;; Stdprocs.e
   ARE_YOU_SURE_YN__MSG = '  Are you sure (Y/N)? '  -- Keep spaces
   ARE_YOU_SURE__MSG =    'Are you sure?'
   YES_CHAR =             'Y'  -- First letter of Yes
   NO_CHAR =              'N'  -- First letter of No
   NO_MARK__MSG =         'No marked area'
   NO_MARK_HERE__MSG =    'No marked area in current window'
   ERROR__MSG =           'Error'
   ERROR_LOADING__MSG =   'Error trying to load'  -- filename
   NOT_LOCKED__MSG =      '- file not locked.'
   CHAR_INVALID__MSG =    'Character mark invalid.'
   INVALID_NUMBER__MSG =  'Invalid number argument'
   CANT_FIND_PROG__MSG =  "Can't find the program"  -- progname
   NO_FLOAT__MSG =        'Floating point number not allowed:' -- number
   NEED_BLOCK_MARK__MSG = 'Block mark required'  -- (New 1991/10/08)
               -- Error <nn> editing temp file:  <error_message>
   BAD_TMP_FILE__MSG =    'editing temp file:'

compile if EVERSION > 5
;; Stdctrl.e
   BUTTON_ERROR__MSG =    'button error'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   ENTER__MSG =           '~Enter'
   OK__MSG =              '~OK'
   CANCEL__MSG =          'Cancel'
   SELECT__MSG =          '~Select'
   HELP__MSG =            'Help'
   FONTLIST_PROMPT__MSG = 'Font Cell Size (width x height); curr. ='
   TO_LARGE_FONT__MSG =   'Change to large ~font'  -- Tilde must be before a character
   TO_SMALL_FONT__MSG =   'Change to small ~font'  -- that's the same in both messages
   EXISTS_OVERLAY__MSG =  'Above file already exists.  Overlay?'
   NO_SLASH__MSG =        'Window text of folder was the above string; didn''t find a "\".'
   LISTING__MSG =         'Generating list...'
   ONLY_FILE__MSG =       'This is the only file in the ring.'
   TOO_MANY_FILES__MSG =  "Too many files"
   NOT_FIT__MSG =         'Not all the filenames would fit into the maximum-sized buffer.'
   FILES_IN_RING__MSG =   'Files in Ring'  -- This is a listbox title
   UNEXPECTED__MSG =      'Error - unexpected result.'
   PROCESS_ERROR__MSG =   'Error processing function associated with id'
   MENU_ERROR__MSG =      'Error in active menu'
   REFLOW_ALL__MSG =      'Would you like to reflow the entire document to the new margins?'
   SAVE_AS__MSG =         'Save As'
   LIST_TOO_BIG__MSG =    'List too big; not all entries will be seen.'

; Before 5.21, we didn't have accelerator keys, so we didn't want the Tilde to
; appear on the action bar.
compile if EVERSION < '5.21'
   TILDE_CHAR = ''
compile else
   TILDE_CHAR = '~'
compile endif

; Lots of fun here.  This is the editor's action bar.  xxx_BAR__MSG means xxx is on the
; action bar.  yyy_MENU__MSG means that yyy is on a pull-down or pull-right.  The tildes
; precede the accelerator letter; those letters must be unique in each group (pulldown
; or pullright).  Followed by a 'P' means it's the dynamic help prompt for that BAR or
; MENU item.  Note that each prompt must start with \1.
   FILE_BAR__MSG =        TILDE_CHAR'File '
     NEW_MENU__MSG =        '~New'
     OPEN_MENU__MSG =       '~Open...'
     OPEN_NEW_MENU__MSG =   'Open .~Untitled'
     GET_MENU__MSG =        '~Import text file...'
     ADD_MENU__MSG =        'A~dd file...'
     RENAME_MENU__MSG =     '~Rename...'
     SAVE_MENU__MSG =       '~Save'
     SAVEAS_MENU__MSG =     'Save ~as...'
     FILE_MENU__MSG =       'Sa~ve and quit'
     SAVECLOSE_MENU__MSG =  'Sa~ve and close'
     QUIT_MENU__MSG =       '~Quit file'
     PRT_FILE_MENU__MSG =   '~Print file'

compile if WANT_DYNAMIC_PROMPTS
   FILE_BARP__MSG =        \1'Menus related to operations on files'
     NEW_MENUP__MSG =        \1'Replace current file with an empty .Untitled file'
     OPEN_NEW_MENUP__MSG =   \1'Open a new, empty, edit window'
     OPEN_MENUP__MSG =       \1'Open a file in a new window'
     GET_MENUP__MSG =        \1'Copy an existing file into the current file'
     ADD_MENUP__MSG =        \1'Edit a new file in this window'
     RENAME_MENUP__MSG =     \1'Change the name of this file'
     SAVE_MENUP__MSG =       \1'Save this file'
     SAVEAS_MENUP__MSG =     \1'Change this file''s name, then save under the new name'
     FILE_MENUP__MSG =       \1'Save this file, then Quit'
     QUIT_MENUP__MSG =       \1'Quit this file'
     ENHPRT_FILE_MENUP__MSG =\1'Bring up print dialog'
     PRT_FILE_MENUP__MSG =   \1'Print this file on default printer'
compile else
   FILE_BARP__MSG =        ''
     NEW_MENUP__MSG =        ''
     OPEN_NEW_MENUP__MSG =   ''
     OPEN_MENUP__MSG =       ''
     GET_MENUP__MSG =        ''
     ADD_MENUP__MSG =        ''
     RENAME_MENUP__MSG =     ''
     SAVE_MENUP__MSG =       ''
     SAVEAS_MENUP__MSG =     ''
     FILE_MENUP__MSG =       ''
     QUIT_MENUP__MSG =       ''
     ENHPRT_FILE_MENUP__MSG =''
     PRT_FILE_MENUP__MSG =   ''
compile endif  -- WANT_DYNAMIC_PROMPTS

   EDIT_BAR__MSG =        TILDE_CHAR'Edit '
     UNDO_MENU__MSG =       'Undo ~line'
     UNDO_REDO_MENU__MSG =  '~Undo...'
     STYLE_MENU__MSG =      'Styl~e...'
     COPY_MARK_MENU__MSG =  '~Copy mark'
     MOVE_MARK_MENU__MSG =  '~Move mark'
     OVERLAY_MARK_MENU__MSG='~Overlay mark'
     ADJUST_MARK_MENU__MSG= '~Adjust mark'
     COPY_MRK_MENU__MSG =   '~Copy'
     MOVE_MRK_MENU__MSG =   '~Move'
     OVERLAY_MRK_MENU__MSG= '~Overlay'
     ADJUST_MRK_MENU__MSG=  '~Adjust'
     UNMARK_MARK_MENU__MSG= 'U~nmark'
     DELETE_MARK_MENU__MSG= '~Delete mark'
     DELETE_MENU__MSG=      '~Delete'
     PUSH_MARK_MENU__MSG =  'Save mark'
     POP_MARK_MENU__MSG =   'Restore mark'
     SWAP_MARK_MENU__MSG =  'Swap mark'
     PUSH_MRK_MENU__MSG =  'Save'
     POP_MRK_MENU__MSG =   'Restore'
     SWAP_MRK_MENU__MSG =  'Swap'
     PUSH_CURSOR_MENU__MSG ='Save cursor'
     POP_CURSOR_MENU__MSG = 'Restore cursor'
     SWAP_CURSOR_MENU__MSG= 'Swap cursor'
     CLIP_COPY_MENU__MSG =  'Cop~y'
     CUT_MENU__MSG =        'Cu~t'
     PASTE_C_MENU__MSG =    'Pa~ste'
     PASTE_L_MENU__MSG =    '~Paste lines'
     PASTE_B_MENU__MSG =    'Paste ~block'
     PRT_MARK_MENU__MSG =   'Pr~int mark'
     RECOVER_MARK_MENU__MSG='~Recover mark delete'

compile if WANT_DYNAMIC_PROMPTS
   EDIT_BARP__MSG =        \1'Menus related to Undo, marks, and the clipboard'
     UNDO_MENUP__MSG =       \1'Undo changes to current line'
     UNDO_REDO_MENUP__MSG =  \1'Activate Undo/Redo dialog, to step through changes to file.'
     STYLE_MENUP__MSG =      \1'Change the style for the marked text, or register a style'
     COPY_MARK_MENUP__MSG =  \1'Copy marked text to cursor'
     MOVE_MARK_MENUP__MSG =  \1'Move marked text to cursor'
     OVERLAY_MARK_MENUP__MSG=\1'Overlay marked text onto text following cursor'
     ADJUST_MARK_MENUP__MSG= \1'Overlay mark, then blank source'
     UNMARK_MARK_MENUP__MSG= \1'Unmark marked text'
     DELETE_MARK_MENUP__MSG= \1'Delete marked text'
     PUSH_MARK_MENUP__MSG =  \1'Save mark boundaries on a stack'
     POP_MARK_MENUP__MSG =   \1'Restore saved mark boundaries from a stack'
     SWAP_MARK_MENUP__MSG =  \1'Exchange current mark boundaries with top of stack'
     PUSH_CURSOR_MENUP__MSG =\1'Save position of cursor in file on a stack'
     POP_CURSOR_MENUP__MSG = \1'Restore position of cursor in file from stack'
     SWAP_CURSOR_MENUP__MSG= \1'Exchange current cursor position with top of stack'
     CLIP_COPY_MENUP__MSG =  \1'Copy marked text to clipboard'
     CUT_MENUP__MSG =        \1'Copy marked text to clipboard, then delete from file'
     PASTE_C_MENUP__MSG =    \1'Paste text from clipboard as a character mark'
     PASTE_L_MENUP__MSG =    \1'Paste text from clipboard as new lines'
     PASTE_B_MENUP__MSG =    \1'Paste text from clipboard as a rectangular block'
     ENHPRT_MARK_MENUP__MSG =\1'Bring up print dialog to print the marked text'
     PRT_MARK_MENUP__MSG =   \1'Print the marked text on the default printer'
     RECOVER_MARK_MENUP__MSG=\1'Paste a copy of the most recently deleted mark after the cursor'
compile else
   EDIT_BARP__MSG =        ''
     UNDO_MENUP__MSG =       ''
     UNDO_REDO_MENUP__MSG =  ''
     STYLE_MENUP__MSG =      ''
     COPY_MARK_MENUP__MSG =  ''
     MOVE_MARK_MENUP__MSG =  ''
     OVERLAY_MARK_MENUP__MSG=''
     ADJUST_MARK_MENUP__MSG= ''
     UNMARK_MARK_MENUP__MSG= ''
     DELETE_MARK_MENUP__MSG= ''
     PUSH_MARK_MENUP__MSG =  ''
     POP_MARK_MENUP__MSG =   ''
     SWAP_MARK_MENUP__MSG =  ''
     PUSH_CURSOR_MENUP__MSG =''
     POP_CURSOR_MENUP__MSG = ''
     SWAP_CURSOR_MENUP__MSG= ''
     CLIP_COPY_MENUP__MSG =  ''
     CUT_MENUP__MSG =        ''
     PASTE_C_MENUP__MSG =    ''
     PASTE_L_MENUP__MSG =    ''
     PASTE_B_MENUP__MSG =    ''
     ENHPRT_MARK_MENUP__MSG =''
     PRT_MARK_MENUP__MSG =   ''
     RECOVER_MARK_MENUP__MSG=''
compile endif  -- WANT_DYNAMIC_PROMPTS

   SEARCH_BAR__MSG =      TILDE_CHAR'Search '
     SEARCH_MENU__MSG =     '~Search...'
     FIND_NEXT_MENU__MSG =  '~Find next'
     CHANGE_NEXT_MENU__MSG= '~Change next'
compile if WANT_BOOKMARKS
     BOOKMARKS_MENU__MSG =  '~Bookmarks'     -- Pull-right
       SET_MARK_MENU__MSG =   '~Set...'
       LIST_MARK_MENU__MSG =  '~List...'
       NEXT_MARK_MENU__MSG =  '~Next'
       PREV_MARK_MENU__MSG =  '~Previous'
compile endif -- WANT_BOOKMARKS
compile if WANT_TAGS
     TAGS_MENU__MSG =       '~Tags'          -- Pull-right
       TAGSDLG_MENU__MSG =    '~Tags dialog...'
       FIND_TAG_MENU__MSG =   '~Find current procedure'
       FIND_TAG2_MENU__MSG =  'F~ind procedure...'
       TAGFILE_NAME_MENU__MSG='Tags file ~name...'
       MAKE_TAGS_MENU__MSG =  '~Make tags file...'
       SCAN_TAGS_MENU__MSG =  '~Scan current file...'
compile endif -- WANT_TAGS

compile if WANT_DYNAMIC_PROMPTS
 compile if WANT_BOOKMARKS & not defined(STD_MENU_NAME)
   SEARCH_BARP__MSG =      \1'Menus related to searching and changing text, and to bookmarks'
 compile else
   SEARCH_BARP__MSG =      \1'Menus related to searching and changing text'
 compile endif
     SEARCH_MENUP__MSG =     \1'Activate search/replace dialog'
     FIND_NEXT_MENUP__MSG =  \1'Repeat previous Locate command'
     CHANGE_NEXT_MENUP__MSG= \1'Repeat previous Change command'
 compile if WANT_BOOKMARKS
     BOOKMARKS_MENUP__MSG=   \1'Cascaded menu for manipulating bookmarks'
     SET_MARK_MENUP__MSG =   \1'Place a bookmark at the cursor position'
     LIST_MARK_MENUP__MSG =  \1'List bookmarks; can go to or delete a bookmark from the list'
     NEXT_MARK_MENUP__MSG =  \1'Go to next bookmark in this file'
     PREV_MARK_MENUP__MSG =  \1'Go to previous bookmark in this file'
 compile endif -- WANT_BOOKMARKS
 compile if WANT_TAGS
     TAGS_MENUP__MSG =       \1'Cascaded menu for using a "tags" file'
     TAGSDLG_MENUP__MSG =    \1'Activate tags dialog'
     FIND_TAG_MENUP__MSG =   \1'Find the definition for the procedure name under the cursor'
     FIND_TAG2_MENUP__MSG =  \1'Find the definition for a procedure name to be entered'
     TAGFILE_NAME_MENUP__MSG=\1'Check or set the name of the tags file'
     MAKE_TAGS_MENUP__MSG =  \1'Create or update a tags file'
     SCAN_TAGS_MENUP__MSG =  \1'Search current file for procedures & present them in a list'
 compile endif -- WANT_TAGS
compile else
   SEARCH_BARP__MSG =      ''
     SEARCH_MENUP__MSG =     ''
     FIND_NEXT_MENUP__MSG =  ''
     CHANGE_NEXT_MENUP__MSG= ''
 compile if WANT_BOOKMARKS
     BOOKMARKS_MENUP__MSG =  ''
     SET_MARK_MENUP__MSG =   ''
     LIST_MARK_MENUP__MSG =  ''
     NEXT_MARK_MENUP__MSG =  ''
     PREV_MARK_MENUP__MSG =  ''
 compile endif -- WANT_BOOKMARKS
 compile if WANT_TAGS
     TAGS_MENUP__MSG =       ''
     TAGSDLG_MENUP__MSG =    ''
     FIND_TAG_MENUP__MSG =   ''
     FIND_TAG2_MENUP__MSG =  ''
     TAGFILE_NAME_MENUP__MSG=''
     MAKE_TAGS_MENUP__MSG =  ''
     SCAN_TAGS_MENUP__MSG =  ''
 compile endif -- WANT_TAGS
compile endif  -- WANT_DYNAMIC_PROMPTS

   OPTIONS_BAR__MSG         = TILDE_CHAR'Options '
     LIST_FILES_MENU__MSG     = '~List ring...'
     FILE_LIST_MENU__MSG      = '~File list...'
     PROOF_MENU__MSG          = '~Proof'
     PROOF_WORD_MENU__MSG     = 'Proof ~word'
     DYNASPELL_MENU__MSG      = '~Auto-spellcheck'
     SYNONYM_MENU__MSG        = '~Synonym'
     DEFINE_WORD_MENU__MSG    = 'D~efine word'
     PREFERENCES_MENU__MSG    = 'P~references'   -- this is a pull-right; next few are separate group.
       CONFIG_MENU__MSG         = '~Settings...'
       SETENTER_MENU__MSG       = 'Set ~enter...'
       ADVANCEDMARK_MENU__MSG   = '~Advanced marking'
       STREAMMODE_MENU__MSG     = 'S~tream editing'
       RINGENABLED_MENU__MSG    = '~Ring enabled'
       STACKCMDS_MENU__MSG      = 'Stac~k commands'
       CUAACCEL_MENU__MSG       = '~Menu accelerators'
     AUTOSAVE_MENU__MSG       = '~Autosave...'
     MESSAGES_MENU__MSG       = '~Messages...'
     CHANGE_FONT_MENU__MSG    = 'Change ~font...'
     SMALL_FONT_MENU__MSG     = 'Small ~font'
     LARGE_FONT_MENU__MSG     = 'Large ~font'
     FRAME_CTRLS_MENU__MSG    = 'Frame co~ntrols'  -- this is a pull-right; next few are separate group.
       STATUS_LINE_MENU__MSG    = '~Status line'
       MSG_LINE_MENU__MSG       = '~Message line'
       SCROLL_BARS_MENU__MSG    = 'Scroll~bars'
       FILEICON_MENU__MSG       = '~File symbol'
       ROTATEBUTTONS_MENU__MSG  = '~Rotate buttons'
compile if WANT_TOOLBAR
       TOOLBAR_MENU__MSG        = '~Toolbar'
       TOGGLETOOLBAR_MENU__MSG  = '~Toolbar'  -- Was 'Toggle'; the other 3 not used any more.
       LOADTOOLBAR_MENU__MSG    = '~Load...'
       DELETETOOLBAR_MENU__MSG  = '~Delete...'
compile endif -- WANT_TOOLBAR
       TOGGLEBITMAP_MENU__MSG   = 'B~ackground bitmap'
       INFOATTOP_MENU__MSG      = '~Info at top'
       PROMPTING_MENU__MSG      = '~Prompting'
     SAVE_OPTS_MENU__MSG      = 'Save ~options'
     TO_BOOK_MENU__MSG        = '~Book icon'
     TO_DESKTOP_MENU__MSG     = 'LaMa~il desktop'

compile if WANT_DYNAMIC_PROMPTS
 compile if SPELL_SUPPORT & not CHECK_FOR_LEXAM
   OPTIONS_BARP__MSG         = \1'Menus related to spell checking, and configuring the editor'
 compile else
   OPTIONS_BARP__MSG         = \1'Menus related to configuring the editor'
 compile endif
     LIST_FILES_MENUP__MSG     = \1'List files in the edit ring'
     PROOF_MENUP__MSG          = \1'Initiate a spell-check of the file'
     PROOF_WORD_MENUP__MSG     = \1'Verify the spelling of the word at the cursor'
     SYNONYM_MENUP__MSG        = \1'Suggest a synonym for the word at the cursor'
     DYNASPELL_MENUP__MSG      = \1'Toggle dynamic spell-checking on and off'
     DEFINE_WORD_MENUP__MSG    = \1'Look up the word at the cursor in the default dictionary, and show the definition'
     PREFERENCES_MENUP__MSG    = \1'Cascaded menu for customizing editor'
       CONFIG_MENUP__MSG         = \1'Activate the settings dialog to change editor configuration'
       SETENTER_MENUP__MSG       = \1'Configure the action of the enter keys'
       ADVANCEDMARK_MENUP__MSG   = \1'Toggle between basic and advanced marking modes'
       STREAMMODE_MENUP__MSG     = \1'Toggle stream editing mode'
       RINGENABLED_MENUP__MSG    = \1'Enable or disable multiple files in a window'
       STACKCMDS_MENUP__MSG      = \1'Enable or disable Push and Pop commands on Edit menu'
       CUAACCEL_MENUP__MSG       = \1'Enable or disable menu accelerators (Alt+letter goes to action bar)'
     AUTOSAVE_MENUP__MSG       = \1'Query autosave values, and optionally list autosave directory'
     MESSAGES_MENUP__MSG       = \1'Review previously displayed messages'
     CHANGE_FONT_MENUP__MSG    = \1'Change the font'
     CHANGE_MARKFONT_MENUP__MSG= \1'Change the font for the marked text'
     SMALL_FONT_MENUP__MSG     = \1'Change to the small font'
     LARGE_FONT_MENUP__MSG     = \1'Change to the large font'
     FRAME_CTRLS_MENUP__MSG    = \1"Cascaded menu for customizing various features of the edit window's frame"
       STATUS_LINE_MENUP__MSG    = \1'Toggle display of status line on and off'
       MSG_LINE_MENUP__MSG       = \1'Toggle display of message line on and off'
       SCROLL_BARS_MENUP__MSG    = \1'Toggle display of scroll bars on and off'
;;;;   PARTIALTEXT_MENUP__MSG    = \1'Toggle display of partial text on and off'  -- Unused
       FILEICON_MENUP__MSG       = \1'Toggle display of drag/drop file symbol on and off'
       ROTATEBUTTONS_MENUP__MSG  = \1'Toggle display of rotate buttons on and off'
 compile if WANT_TOOLBAR
       TOOLBAR_MENUP__MSG        = \1'Cascaded menu for actions related to the Toolbar'
         TOGGLETOOLBAR_MENUP__MSG  = \1'Toggle toolbar on or off'
         LOADTOOLBAR_MENUP__MSG    = \1'Load a previously saved toolbar'
         SAVETOOLBAR_MENUP__MSG    = \1'Save a customized toolbar'
         DELETETOOLBAR_MENUP__MSG  = \1'Delete a named toolbar'
 compile endif -- WANT_TOOLBAR
       TOGGLEBITMAP_MENUP__MSG   = \1'Toggle bitmap behind text window on or off'
       INFOATTOP_MENUP__MSG      = \1'Toggle status & message lines between top & bottom of window'
       PROMPTING_MENUP__MSG      = \1'Toggle dynamic menu help on and off'
     SAVE_OPTS_MENUP__MSG      = \1'Makes current modes and frame settings the default'
     TO_BOOK_MENUP__MSG        = \1'Switch to the EPM book icon or desktop'
     TO_DESKTOP_MENUP__MSG     = \1'Switch to the LaMail desktop window'
compile else
   OPTIONS_BARP__MSG         = ''
     LIST_FILES_MENUP__MSG     = ''
     PROOF_MENUP__MSG          = ''
     PROOF_WORD_MENUP__MSG     = ''
     SYNONYM_MENUP__MSG        = ''
     DYNASPELL_MENUP__MSG      = ''
     DEFINE_WORD_MENUP__MSG    = ''
     PREFERENCES_MENUP__MSG    = ''
       CONFIG_MENUP__MSG         = ''
       SETENTER_MENUP__MSG       = ''
       ADVANCEDMARK_MENUP__MSG   = ''
       STREAMMODE_MENUP__MSG     = ''
       RINGENABLED_MENUP__MSG    = ''
       STACKCMDS_MENUP__MSG      = ''
       CUAACCEL_MENUP__MSG       = ''
     AUTOSAVE_MENUP__MSG       = ''
     MESSAGES_MENUP__MSG       = ''
     CHANGE_FONT_MENUP__MSG    = ''
     SMALL_FONT_MENUP__MSG     = ''
     LARGE_FONT_MENUP__MSG     = ''
     FRAME_CTRLS_MENUP__MSG    = ''
       STATUS_LINE_MENUP__MSG    = ''
       MSG_LINE_MENUP__MSG       = ''
       SCROLL_BARS_MENUP__MSG    = ''
;;;;   PARTIALTEXT_MENUP__MSG    = ''  -- Unused
       FILEICON_MENUP__MSG       = ''
       ROTATEBUTTONS_MENUP__MSG  = ''
 compile if WANT_TOOLBAR
       TOOLBAR_MENUP__MSG        = ''
         TOGGLETOOLBAR_MENUP__MSG  = ''
         LOADTOOLBAR_MENUP__MSG    = ''
         SAVETOOLBAR_MENUP__MSG    = ''
         DELETETOOLBAR_MENUP__MSG  = ''
 compile endif -- WANT_TOOLBAR
       TOGGLEBITMAP_MENUP__MSG   = ''
       INFOATTOP_MENUP__MSG      = ''
       PROMPTING_MENUP__MSG      = ''
     SAVE_OPTS_MENUP__MSG      = ''
     TO_BOOK_MENUP__MSG        = ''
     TO_DESKTOP_MENUP__MSG     = ''
compile endif  -- WANT_DYNAMIC_PROMPTS

   RING_BAR__MSG =        TILDE_CHAR'Ring '

   COMMAND_BAR__MSG =     TILDE_CHAR'Command '
     COMMANDLINE_MENU__MSG = '~Command dialog...'
     HALT_COMMAND_MENU__MSG= '~Halt command'
     CREATE_SHELL_MENU__MSG= 'Create command ~shell'
     WRITE_SHELL_MENU__MSG = '~Write to shell...'
     KILL_SHELL_MENU__MSG =  '~Destroy shell'
     SHELL_BREAK_MENU__MSG = 'Send ~break to shell'

compile if WANT_DYNAMIC_PROMPTS
   COMMAND_BARP__MSG =     \1'Enter or halt a command',
     COMMANDLINE_MENUP__MSG = \1'Activate command line dialog to enter editor or OS/2 commands'
     HALT_COMMAND_MENUP__MSG= \1'Stop execution of the current command'
     CREATE_SHELL_MENUP__MSG= \1'Create a command shell window'
     WRITE_SHELL_MENUP__MSG = \1"Write a string to the shell's standard input"
     KILL_SHELL_MENUP__MSG =  \1'Kill the shell process and delete the edit file'
     SHELL_BREAK_MENUP__MSG = \1'Send a Ctrl+Break message to the shell process'
compile else
   COMMAND_BARP__MSG =     '',
     COMMANDLINE_MENUP__MSG = ''
     HALT_COMMAND_MENUP__MSG= ''
     CREATE_SHELL_MENUP__MSG= ''
     WRITE_SHELL_MENUP__MSG = ''
     KILL_SHELL_MENUP__MSG =  ''
     SHELL_BREAK_MENUP__MSG = ''
compile endif  -- WANT_DYNAMIC_PROMPTS

   HELP_BAR__MSG =        TILDE_CHAR'Help '
     HELP_HELP_MENU__MSG =   '~Using help'  -- was '~Help for help'
     EXT_HELP_MENU__MSG =    '~General help'  -- was '~Extended help...'
     KEYS_HELP_MENU__MSG =   '~Keys help'
     COMMANDS_HELP_MENU__MSG =   '~Commands help'
     HELP_INDEX_MENU__MSG =  'Help ~index'
     HELP_BROWSER_MENU__MSG= '~Quick reference'
     HELP_PROD_MENU__MSG =   '~Product information'
     USERS_GUIDE_MENU__MSG = "~View User's Guide"
       VIEW_USERS_MENU__MSG =  "~View User's Guide"
       VIEW_IN_USERS_MENU__MSG="~Current word"
       VIEW_USERS_SUMMARY_MENU__MSG="~Summary"
     TECHREF_MENU__MSG =     "View ~Technical Reference"
       VIEW_TECHREF_MENU__MSG =  "~View Technical Reference"
       VIEW_IN_TECHREF_MENU__MSG="~Current word"

compile if WANT_DYNAMIC_PROMPTS
   HELP_BARP__MSG =         \1'Menus to access Help panels and copyright information'
     HELP_HELP_MENUP__MSG =   \1'Help about the help manager'
     EXT_HELP_MENUP__MSG =    \1'Bring up main editor help panel'
     KEYS_HELP_MENUP__MSG =   \1'Help for defined editor keys'
     COMMANDS_HELP_MENUP__MSG=\1'Help for editor commands'
     HELP_INDEX_MENUP__MSG =  \1'Bring up the help index'
     HELP_BROWSER_MENUP__MSG= \1'Bring up a "quick reference" overview of the editor (with ASCII chart)'
     HELP_PROD_MENUP__MSG=    \1'Copyright and version info'
     USERS_GUIDE_MENUP__MSG = \1"View EPM User's Guide, or look up a word in it"
       VIEW_USERS_MENUP__MSG =  \1"Call View to read EPM User's Guide"
       VIEW_IN_USERS_MENUP__MSG=\1"Look up current word in EPM User's Guide"
       VIEW_USERS_SUMMARY_MENUP__MSG=\1"View the section ""Summary of Configuration Constants"""
     TECHREF_MENUP__MSG =     \1"View EPM Technical Reference, or look up a word in it"
       VIEW_TECHREF_MENUP__MSG=   \1"Call View to read EPM Technical Reference"
       VIEW_IN_TECHREF_MENUP__MSG=\1"Look up current word in EPM Technical Reference"
compile else
   HELP_BARP__MSG =         ''
     HELP_HELP_MENUP__MSG =   ''
     EXT_HELP_MENUP__MSG =    ''
     KEYS_HELP_MENUP__MSG =   ''
     COMMANDS_HELP_MENUP__MSG=''
     HELP_INDEX_MENUP__MSG =  ''
     HELP_BROWSER_MENUP__MSG= ''
     HELP_PROD_MENUP__MSG=    ''
     USERS_GUIDE_MENUP__MSG = ''
       VIEW_USERS_MENUP__MSG =  ''
       VIEW_IN_USERS_MENUP__MSG=''
       VIEW_USERS_SUMMARY_MENUP__MSG=''
     TECHREF_MENUP__MSG =     ''
       VIEW_TECHREF_MENUP__MSG=   ''
       VIEW_IN_TECHREF_MENUP__MSG=''
compile endif  -- WANT_DYNAMIC_PROMPTS

   COMPILER_BAR__MSG =           'Co'TILDE_CHAR'mpiler'
     NEXT_COMPILER_MENU__MSG =     '~Next error'
     PREV_COMPILER_MENU__MSG =     '~Previous error'
     DESCRIBE_COMPILER_MENU__MSG = '~Describe error'
     CLEAR_ERRORS_MENU__MSG =      '~Clear errors'
     END_DDE_SESSION_MENU__MSG =   '~End DDE session'
     REMOVE_COMPILER_MENU__MSG =   '~Remove compiler menu'

compile if WANT_DYNAMIC_PROMPTS
   COMPILER_BARP__MSG =           \1'Compiler-related selections'
     NEXT_COMPILER_MENUP__MSG =     \1'Move to next compiler error'
     PREV_COMPILER_MENUP__MSG =     \1'Move to previous compiler error'
     DESCRIBE_COMPILER_MENUP__MSG = \1'List errors for current line and optionally get help'
     CLEAR_ERRORS_MENUP__MSG =      \1'Remove highlighting and bookmarks for compiler errors'
     END_DDE_SESSION_MENUP__MSG =    \1'End the DDE session with the Workframe'
     REMOVE_COMPILER_MENUP__MSG =    \1'Remove the compiler menu from the action bar'
compile else
   COMPILER_BARP__MSG =          ''
     NEXT_COMPILER_MENUP__MSG =    ''
     PREV_COMPILER_MENUP__MSG =    ''
     DESCRIBE_COMPILER_MENUP__MSG = ''
     CLEAR_ERRORS_MENUP__MSG =     ''
     END_DDE_SESSION_MENUP__MSG =  ''
     REMOVE_COMPILER_MENUP__MSG =  ''
compile endif  -- WANT_DYNAMIC_PROMPTS

;  (End of pull-downs)
; Now, define the lower and upper case accelerators for the above
; action bar entries.  For each letter (_L), we need an upper (_A1)
; and lower (_A2) case ASCII value.  Example:  '~File'
; letter = 'F'; ASCII('F') = 70; ASCII('f') = 102
   FILE_ACCEL__L =       'F'  -- File
   FILE_ACCEL__A1 =       70
   FILE_ACCEL__A2 =      102
   EDIT_ACCEL__L =       'E'
   EDIT_ACCEL__A1 =       69
   EDIT_ACCEL__A2 =      101
   SEARCH_ACCEL__L =     'S'
   SEARCH_ACCEL__A1 =     83
   SEARCH_ACCEL__A2 =    115
   OPTIONS_ACCEL__L =    'O'
   OPTIONS_ACCEL__A1 =    79
   OPTIONS_ACCEL__A2 =   111
   RING_ACCEL__L =       'R'
   RING_ACCEL__A1 =       82
   RING_ACCEL__A2 =      114
   COMMAND_ACCEL__L =    'C'
   COMMAND_ACCEL__A1 =    67
   COMMAND_ACCEL__A2 =    99
   HELP_ACCEL__L =       'H'
   HELP_ACCEL__A1 =       72
   HELP_ACCEL__A2 =      104
   COMPILER_ACCEL__L =   'M'  -- Co~mpiler error
   COMPILER_ACCEL__A1 =   77
   COMPILER_ACCEL__A2 =  113

;        New stuff for OVSHMENU.E.
   VIEW_ACCEL__L =       'V'
   VIEW_ACCEL__A1 =       86
   VIEW_ACCEL__A2 =      118
   SELECTED_ACCEL__L =   'S'
   SELECTED_ACCEL__A1 =   83
   SELECTED_ACCEL__A2 =  115

   VIEW_BAR__MSG =        '~View'
   SELECTED_BAR__MSG =        '~Selected'

     OPENAS_MENU__MSG  =    '~Open as'
     OPENNOAS_MENU__MSG  =  '~Open'
     NEWWIN_MENU__MSG =     '~New window...'
     SAMEWIN_MENU__MSG =    'Same ~window...'
     COMMAND_SHELL_MENU__MSG='~Command shell'
     PRINT_MENU__MSG =      '~Print...'
     UNDO__MENU__MSG =      '~Undo'
     SELECT_ALL_MENU__MSG = 'Select ~all'
     DESELECT_ALL_MENU__MSG = 'D~eselect all'

compile if WANT_DYNAMIC_PROMPTS
     OPENAS_MENUP__MSG  =       \1'Open a file or edit object settings'
     NEWWIN_MENUP__MSG =        \1'Replace current file with an empty .Untitled file'
     UNDO__MENUP__MSG =         \1'Menus related to Undo, marks, and the clipboard'
     SELECT_ALL_MENUP__MSG =    \1'Select all text in the file (character-mark)'

   VIEW_BARP__MSG =        \1'Menus related to searching, tags, bookmarks, commands, etc.'
   SELECTED_BARP__MSG =         \1'Menus related to selected text'
compile else
     OPENAS_MENUP__MSG  =       ''
     NEWWIN_MENUP__MSG =        ''
     UNDO__MENUP__MSG =         ''
     SELECT_ALL_MENUP__MSG =    ''

   VIEW_BARP__MSG =        ''
   SELECTED_BARP__MSG =    ''
compile endif  -- WANT_DYNAMIC_PROMPTS

; End of additions for OVSH menus.

   NO_PRINTERS__MSG =     '(No printers)'
   PRINT__MSG =           'Print'  -- Dialog box title
   DRAFT__MSG =           '~Draft'  -- Button
   WYSIWYG__MSG =         '~WYSIWYG'  -- Button  (What You See Is What You Get)
   SELECT_PRINTER__MSG =  'Select a printer'
           -- 'Printer' printername 'has no device associated with it.'
   PRINTER__MSG =         'Printer'
   NO_DEVICE__MSG =       'has no device associated with it.'
   NO_QUEUE__MSG =        'has no queue associated with it.'
   EDITOR__MSG =          "EPM Editor - Product Information"
   EDITOR_VER__MSG =      "Editor version" -- nnn
   LAMAIL_VER__MSG =      "LaMail version" -- nnn
   MACROS_VER__MSG =      "Macros version" -- nnn
   COPYRIGHT__MSG =       "(C) Copyright IBM Corporation 1989, 1993, 1994, 1995, 1996"
   OVERLAPPING_ATTRIBS__MSG = 'Overlapping attributes; nothing changed.' /*NLS*/
                            -- Following is followed by pres. parm. name
   UNKNOWN_PRESPARAM__MSG = "Unknown presentation parameter change:"     /*NLS*/
                            -- Following is followed by action name
   UNKNOWN_ACTION__MSG =  'Can not resolve action'                       /*NLS*/

;; Epmlex.e
   REPLACE__MSG =         '~Replace'
   SYNONYMS__MSG =        'Synonyms'  -- Listbox Title
            -- "Spell checking marked area" or "... file"
   CHECKING__MSG =        'Spell checking'
   MARKED_AREA__MSG =     'marked area'
   FILE__MSG =            'file'
   NEXT__MSG =            '~Next'       -- button
   TEMP_ADD__MSG =        '~Temp. Add'  -- button, so keep short
   ADD__MSG =             '~Add'        -- button:  Add to addenda
   EDIT__MSG =            '~Edit'       -- button
   EXIT__MSG =            '~Exit'       -- button
   LOOKUP_FAILED__MSG =   'Word lookup failed for' -- <word>
   PROOF__MSG =           'Proof'  -- Listbox title; "Proof <word>"
   REPLACEMENT__MSG =     'Enter phrase to replace'  -- <word>
   PROOF_WORD__MSG =      'Proof Word'  -- Listbox title
   NO_DICT__MSG =         'Dictionary does not exist:'  -- dict_filename
   DICT_PTR__MSG =        'Use Paths page of Settings notebook to change dictionary.'
   DICTLIST_IS__MSG =     'Dictionary list is:'  -- list of file names
             -- 'File not found "'new_name'"; dictionary remains:' old_name
   DICT_REMAINS__MSG =    'dictionary remains:'
             -- "Nothing found for <bad_word>".  Used in a dialog;
   WORD_NOT_FOUND__MSG =  'Nothing found for'     --  try to keep this short.
compile endif  -- EVERSION > 5

;; Stdkeys.e
   MARKED_OTHER__MSG =    "You had a marked area in another file; it has been unmarked."
   MARKED_OFFSCREEN__MSG= "You had a marked area not visible in the window; it has been unmarked."
   CANT_REFLOW__MSG =     "Can't reflow!"
   OTHER_FILE_MARKED__MSG="You have a marked area in another file."
   MARK_OFF_SCRN_YN__MSG= "You have a marked area off screen.  Continue?  (Y/N)"
   MARK_OFF_SCREEN__MSG = "Can't reflow!  You have a marked area off screen."
   WRONG_MARK__MSG =      'Line or block mark required'
   PBLOCK_ERROR__MSG =    'Error in pblock_reflow'
   BLOCK_REFLOW__MSG =    "BlockReflow: Mark the new block size with Alt-B; press Alt-R again (Esc cancels)"
   NOFLOW__MSG =          'Block mark not reflowed'
   CTRL_R__MSG =          'Remembering keys.  Ctrl-R to finish, Ctrl-T to finish and try, Ctrl-C to cancel.'
   REMEMBERED__MSG =      'Remembered.  Press Ctrl-T to execute.'
   CANCELLED__MSG =       'Cancelled.'
   CTRL_R_ABORT__MSG =    'String too long!  Please press Ctrl-C to cancel.'
   OLD_KEPT__MSG =        'Previous key macro not replaced'
   NO_CTRL_R__MSG =       'Nothing remembered'

;; Stdcmds.e
   ON__MSG =              'ON'  -- Must be upper case for comparisons
   OFF__MSG =             'OFF'
          -- Following is missing close paren on purpose.  sometimes ends ')', others '/?)'
   ON_OFF__MSG =          '(On/Off/1/0'  -- Used in prompts: 'Invalid arguments (On/Off/1/0)'
   PRINTING__MSG =        'Printing'  -- 'Printing' .filename
   CURRENT_AUTOSAVE__MSG= 'Current autosave value='
   NAME_IS__MSG =         'name='
   LIST_DIR__MSG =        'List autosave directory?'
   NO_LIST_DIR__MSG =     '[Ring disabled; can not list directory.]'
   AUTOSAVE__MSG =        'Autosave'  -- messagebox title
   AUTOSAVE_PROMPT__MSG = 'AUTOSAVE <number>  to set number of changes between saves.  0 = off.'
   BROWSE_IS__MSG =       'Browse mode is' -- on/off
compile if EVERSION >= '6.03'
   READONLY_IS__MSG =     'Read-only flag is' -- on/off
compile endif
   NO_REP__MSG =          'No replacement string specified'
   CUR_DIR_IS__MSG =      'Current directory is'
   EX_ALL__MSG =          'Execute all marked lines?'
   EX_ALL_YN__MSG =       'Execute all marked lines (Y,N) ?'
   NEW_FILE__MSG =        'New file'
   BAD_PATH__MSG =        'Path not found'
   LINES_TRUNCATED__MSG = 'Lines truncated'
   ACCESS_DENIED__MSG =   'Access denied'
   INVALID_DRIVE__MSG =   'Invalid drive'
   ERROR_OPENING__MSG =   'Error opening'
   ERROR_READING__MSG =   'Error reading'
   ECHO_IS__MSG =         'Echo is'  -- ON or OFF
   MULTIPLE_ERRORS__MSG = 'Multiple errors loading files.  See messages below:'
   COMPILING__MSG =       'Compiling'  -- filename
              -- 'ETPM.EXE could not open temp file "'tempfile'"'
   CANT_OPEN_TEMP__MSG =  'could not open temp file'
   COMP_COMPLETED__MSG =  'Compilation completed successfully'
   EXIT_PROMPT__MSG =     "About to exit without saving! "
   KEY_PROMPT1__MSG =     'Type key to repeat.  Esc to cancel.'
                --  'Please specify the key to repeat, as in "key 'number' =".'
   KEY_PROMPT2__MSG =     'Please specify the key to repeat, as in'
   LOCKED__MSG =          'File is locked.  UNLOCK it before changing the name.'
   ERROR_SAVING_HALT__MSG='Error saving file.  Command halted.'
   HELP_TOP__MSG =        ' ------ Top of Help Screen -------'
   HELP_BOT__MSG =        ' ------ Bottom of Help Screen -------'
   PRINTER_NOT_READY__MSG='Printer not ready'
   BAD_PRINT_ARG__MSG =   'Invalid argument to PRINT.'
                  -- "You have a marked area in another file.  Unmark, or edit" filename
   UNMARK_OR_EDIT__MSG =  'Unmark, or edit'
   PRINTING_MARK__MSG =   'Printing marked text'
   MACRO_HALTED__MSG =    'Macro halted by user'
                -- filename 'does not exist'
   DOES_NOT_EXIST__MSG =  'does not exist'
   SAVED_TO__MSG =        'Saved to'  -- filename
   IS_A_SUBDIR__MSG =     'Requested file name exists as a subdirectory.'
   READ_ONLY__MSG =       'File is read-only.'
   IS_SYSTEM__MSG =       'File has "system" attribute set.'
   IS_HIDDEN__MSG =       'File has "hidden" attribute set.'
   MAYBE_LOCKED__MSG =    'File may be locked by another application.'
compile if EVERSION >= 6
   ONLY_VIEW__MSG =       'This is the only view of the file.'
compile endif

;; SLnohost.e
   INVALID_FILENAME__MSG= 'Invalid filename.'
   QUIT_PROMPT1__MSG =    'Throw away changes?  Press Y, N or File key'
   QUIT_PROMPT2__MSG =    'Throw away changes?  Press Y or N'
   PRESS_A_KEY__MSG =     'Press a key...'
   LONGNAMES_IS__MSG =    'LONGNAMES mode is' -- on/off

compile if HOST_SUPPORT <> ''
;; SaveLoad.e
   BAD_FILENAME_CHARS__MSG='Characters in filename not supported'
   LOADING_PROMPT__MSG =   'Loading'  -- filename
   SAVING_PROMPT__MSG =    'Saving'  -- filename
   HOST_NOT_FOUND__MSG =   'Assuming host file not found.'
      --  'Host error 'rc'; host save cancelled.  File saved in 'vTEMP_PATH'eeeeeeee.'hostfileid
   HOST_ERROR__MSG =        'Host error'
   HOST_CANCEL__MSG =       'host save cancelled.  File saved in'
compile endif

compile if HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
;; E3Emul.e
   OVERLAY_TEMP1__MSG =     'Load will overwrite extant PC temporary file - continue?  (Y,N)'
         -- Loading <filename> with <options>
   WITH__MSG =              'with'
   FILE_TRANSFER_ERROR__MSG='File transfer error'  -- RC
   SAVED_LOCALLY_AS__MSG =  'Saved on PC as'  -- filename
   SAVE_LOCALLY__MSG =      'Do you want to save this file on PC?  (Y,N)'
   OVERLAY_TEMP2__MSG =     'already exists.  Press Y to overlay, N to abort.'
   OVERLAY_TEMP3__MSG =     'already exists.  Select OK to overlay, Cancel to abort.'
   ALREADY_EDITING__MSG =   'Already editing a file of this name - change denied'
   NO_SPACES__MSG =         'Spaces not supported in file names'
   LOOKS_VM__MSG =          'looked like VM, but'  -- <filename> 'looked like VM, but' <one of the following:>
     NO_HOST_DRIVE__MSG =     'missing host drive'
     HOST_DRIVELETTER__MSG =    'host drive letter'  -- host drive specifier <X> <problem>
       IS_TOO_LONG__MSG =       'is too long'
       INVALID__MSG =           'invalid'
     HOST_LT__MSG =         'host LT'  -- host logical terminal <X> invalid
     NO_LT__MSG =           'missing logical terminal'
     FM__MSG =              'file mode' -- <X> is too long
     FM1_BAD__MSG =         'file mode first char not alpha'
     FM2_BAD__MSG =         'file mode second char not numeric'
     NO_FT__MSG =           'filetype missing'
     FT__MSG =              'file type' -- <X> is too long
     BAD_FT__MSG =          'invalid chars in filetype'  -- <filetype>
     FN__MSG =              'file name' -- <X> is too long
     BAD_FN__MSG =          'invalid chars in filename'  -- <filename>
   MVS_ERROR__MSG =         '(MVS Error)'  -- followed by <one of the following:>
     DSN_TOO_LONG__MSG =      'Data Set name is greater than 44 characters'
                   --  'qualifier #' 1 '('XXXXXXXXX')' <problem>
     QUAL_NUM__MSG =          'qualifier #'
       QUAL_TOO_LONG__MSG =     'is longer than 8 characters'
       QUAL_INVALID__MSG =      'contains an illegal character'
     GENERATION_NAME__MSG =   'Generation name'
     MEMBER__MSG =            'member'
     INVALID_MEMBER__MSG =    'invalid chars in member'
     DSN_PARENS__MSG =        'DSN has parens but no member/generation'
   LOOKS_PC__MSG =          'looked like PC, but'  -- <filename> 'looked like PC, but' <one of the following:>
     PC_DRIVESPEC__MSG =      'PC drive specifier'  -- PC drive specifier <X> <problem>
       LONGER_THAN_ONE__MSG =   'is longer than 1 char'
       IS_NOT_ALPHA__MSG =      'is not alpha'
     INVALID_PATH__MSG =      'invalid path'  -- followed by <filename>
     INVALID_FNAME__MSG =     'invalid PC filename'  -- followed by <filename>
     INVALID_EXT__MSG =       'invalid PC extension'  -- followed by <extension>
   SAVEPATH_NULL__MSG =     'SAVEPATH is null - will use current directory.'
;        'Savepath attempting to use invalid' bad '- will use current directory.'
   SAVEPATH_INVALID1__MSG = 'Savepath attempting to use invalid'
   SAVEPATH_INVALID2__MSG = '- will use current directory.'
   BACKUP_PATH_INVALID_NO_BACKSLASH__MSG= "BACKUP_PATH invalid; missing '\' at end."
   NO_BACKUPS__MSG= "Backup copies will not be saved."
   BACKUP_PATH_INVALID1__MSG = 'BACKUP_PATH attempting to use invalid'
   DRIVE__MSG =             'drive'
   PATH__MSG =              'path'
   EMULATOR_SET_TO__MSG =   'Emulator set to'
   LT_NOW__MSG =            '; (3270 Window presently = '
   EMULATOR__MSG =          'Emulator'
   HOSTDRIVE_NOW__MSG =     'HostDrive set to'
   IS_INVALID_OPTS_ARE__MSG='is invalid.  Options are:'
   TRY_AGAIN__MSG =         'Try again'
   LT_SET_TO__MSG =         'Logical Terminal set to'  -- set to A, to B, etc.
   LT_SET_NULL__MSG =       'Logical Terminal set to null'
   LT_INVALID__MSG =        'is invalid.  Options are: A-H,No_LT,NULL,NONE'  -- (bad) is...
   FTO_WARN__MSG =          'File transfer options are NOT checked for correctness!'
   BIN_WARN__MSG =          'Binary file transfer options are NOT checked for correctness!'
   FROM_HLLAPI__MSG =       'from HLLAPI dynalink call.'  -- Error nnn from...
   FILE_TRANSFER_CMD_UNKNOWN='File transfer command unknown:'
compile endif

compile if EVERSION >=5
;; EPM_EA.e
   TYPE_TITLE__MSG =        'Type'  -- Title of a messagebox or listbox for file type
   NO_FILE_TYPE__MSG =      'File has no type.  Would you like to set one?'
   ONE_FILE_TYPE__MSG =     'File has the following type:'
   MANY_FILE_TYPES__MSG =   'File has types:'
   CHANGE_QUERY__MSG =      'Would you like to change it?'
   NON_ASCII_TYPE__MSG =    'File has non-ASCII data for the type.'
   NON_ASCII__MSG =         '<non-ASCII>'  -- Comment in a list of otherwise ASCII strings
   SELECT_TYPE__MSG =       'Select type'
   SUBJ_TITLE__MSG =        'Subject'  -- Title of a messagebox or listbox for file subject
   NO_SUBJECT__MSG =        'File has no subject.  Would you like to set one?'
   SUBJECT_IS__MSG =        'File has the following subject:'
   NON_ASCII_SUBJECT__MSG = 'File has non-ASCII data for the subject.'
   SELECT_SUBJECT__MSG =    'Enter subject'
; Following is a list of standard values for .TYPE extended attribute, per OS/2 programming guide.
; Only translate if the .TYPE EA is NLS-specific.  First character is the delimiter between
; types; can be any otherwise-unused character.  (It's a '-' here.)
   TYPE_LIST__MSG =         '-Plain Text-OS/2 Command File-DOS Command File-C Code-Pascal Code-BASIC Code-COBOL Code-FORTRAN Code-Assembler Code-'
compile endif  -- EVERSION >=5

compile if EVERSION >=5
;; BOOKMARK.E
   NEED_BM_NAME__MSG =      'Missing bookmark name.'
   NEED_BM_CLASS__MSG =     'Missing bookmark class.'
   UNKNOWN_BOOKMARK__MSG =  'Bookmark not known.'
   BM_NOT_FOUND__MSG =      'Bookmark not found.'
   ITS_DELETED__MSG =       'It has been deleted.'  -- "Bookmark not found. It has been deleted."
   BM_DELETED__MSG =        'Bookmark deleted.'
   NO_BOOKMARKS__MSG =      'No bookmarks set.'
   LIST_BOOKMARKS__MSG =    'List bookmarks'  -- Listbox title
   DELETE_PERM_BM__MSG =    'Delete all permanent bookmarks?'  -- Are you sure?
   UNEXPECTED_ATTRIB__MSG = 'Unexpected value in extended attribute EPM.ATTRIBUTES'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   SET__MSG =               '~Set'
   SETP__MSG =              'Set ~permanent'
   GOMARK__MSG =            '~Go to mark'
   DELETEMARK__MSG =        '~Delete mark'
   SETMARK__MSG =           'Set bookmark'  -- Title
   SETMARK_PROMPT__MSG =    'Enter a name for the current cursor position'
   RENAME__MSG =            'Rename'  -- Title
   NOTHING_ENTERED__MSG =   'Nothing entered; function cancelled.'
   NO_COMPILER_ERROR__MSG = 'No error found on current line.'
   DESCRIBE_ERROR__MSG =    'Describe error'  -- Listbox title
   DETAILS__MSG =           '~Details'  -- Button
   SELECT_ERROR__MSG =      'Select error then select Details for additional information.'
   NO_HELP_INSTANCE__MSG =  "Unexpected error:  No help instance"
   ERROR_ADDING_HELP__MSG = 'attempting to add help file'  -- 'Error' nn 'attempting to add help file' x.hlp
   ERROR_REVERTING__MSG =   'attempting to revert to help file'  -- 'Error' nn 'attempting to revert to help file' x.hlp
   BM_ALREADY_EXISTS__MSG = 'A bookmark with that name already exists.'
   LONG_EA_TITLE__MSG =     "EA's too long"  -- Messagebox title
   LONG_EA__MSG =           "Extended Attributes would be more than 64k; file can not be saved.  Remove some styles and retry."

;;;;;;;;;;;;;;;;;;;;;;;;;;  stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   FILE_GONE__MSG =         'File is no longer in ring.'
   NO_RING__MSG =           'Ring disabled; can not add another file to edit ring.'
   NO_RING_CMD__MSG =       'Command not valid when ring disabled:'  -- followed by command name
   RENAME_PROMPT__MSG =     'Enter new name for current file'
   RX_PROMPT__MSG =         'A macro name must be passed as a parameter (e.g,, EPMREXX ERXMACRO)'
   RX_SUBCOM_FAIL__MSG =    'Rexx subcommand registration failed with rc'
   RX_FUNC_FAIL__MSG =      'Rexx function registration failed with rc'
   MODIFIED_PROMPT__MSG =   'Current file has been modified.  Save changes?'
   NOT_ON_DISK__MSG =       'does not exist on disk - can not proceed.'   -- Preceded by:  '"'filename'"'


; The following are used in key names, like 'Ctrl+O', 'Alt+Bkspc', etc.
; Note that some are abbreviated to take up less room on the menus.

   ALT_KEY__MSG =       'Alt'
   CTRL_KEY__MSG =      'Ctrl'
   SHIFT_KEY__MSG =     'Sh'
   INSERT_KEY__MSG =    'Ins'
   DELETE_KEY__MSG =    'Del'
   BACKSPACE_KEY__MSG = 'Bkspc'
   ENTER_KEY__MSG =     'Enter'
   PADENTER_KEY__MSG =  'PadEnter'
   ESCAPE_KEY__MSG =    'Esc'
   UP_KEY__MSG =        'Up'
   DOWN_KEY__MSG =      'Down'
compile endif  -- EVERSION >=5

;;;;;;;;;;;;;;;;;;;;;;;;;;  New stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   MARK_OFF_SCREEN2__MSG =  "You have a marked area off screen."
   LINES_TRUNCATED_WNG__MSG = 'One or more lines were split at column 255; file may be damaged if saved.'
   DYNASPEL_NORECALL__MSG = 'No misspelled word remembered.'
;                         The following two combine to form one message.
   DYNASPEL_PROMPT1__MSG = 'Unknown word was '
   DYNASPEL_PROMPT2__MSG = ' - press Ctrl+A for alternates.'
;                         The following two combine to form one message.
   PROOF_ERROR1__MSG =     'Unexpected error on line'
   PROOF_ERROR2__MSG =     '- skipping to next line.'

compile if WANT_STACK_CMDS
   STACK_FULL__MSG =        'No room in stack.'
   STACK_EMPTY__MSG =       'Stack is empty.'
compile endif
compile if WANT_TAGS
   TAGSNAME__MSG = 'Tags file name'     -- Entry box title
   TAGSNAME_PROMPT__MSG = 'Enter the file name for the tags file'
   FINDTAG__MSG = 'Find Procedure'      -- Entry box title
   FINDTAG_PROMPT__MSG = 'Enter the name of the procedure to be found.'
   NO_TAGS__MSG = 'No tags found in tags file.'
   LIST_TAGS__MSG = 'List tags'         -- Listbox title
   BUILDING_LIST__MSG = 'Building list...'  -- Processing message
compile endif
   LIST__MSG = '~List...'               -- Button
compile if EVERSION >= '5.60'
   MAKETAGS__MSG = 'Make tags file'
   MAKETAGS_PROMPT__MSG = 'Enter one or more filenames (wildcards OK) or @lists.'
   MAKETAGS_PROCESSING__MSG = 'MAKETAGS in process - parsing source files.'
   MESSAGELINE_FONT__MSG = 'Messageline font changed.'
   MESSAGELINE_FGCOLOR__MSG = 'Messageline foreground color changed.'
   MESSAGELINE_BGCOLOR__MSG = 'Messageline background color changed.'
   TABGLYPH_IS__MSG = 'TABGLYPH is' -- on/off
compile endif

compile if WANT_TOOLBAR
;  NO_TOOLBARS__MSG =     'No saved toolbars to select from.'
;  LOAD_TOOLBAR__MSG =    'Load Toolbar'  -- Dialog box title
;  DELETE_TOOLBAR__MSG =  'Delete Toolbar'  -- Dialog box title
;  SELECT_TOOLBAR__MSG =  'Select a Toolbar menu set'
   SAVEBAR__MSG =         'Save Toolbar'  -- Dialog box title
;  SAVEBAR_PROMPT__MSG =  'Enter a name, or leave blank to save as default.'
   SAVEBAR_PROMPT__MSG =  'Enter a name for the toolbar.'
   SAVE__MSG =            'Save'          -- Dialog button
compile endif -- WANT_TOOLBAR
   WILDCARD_WARNING__MSG = 'Filename contains wildcards.'  -- followed by ARE_YOU_SURE__MSG

;; ASSSIST.E
   NOT_BALANCEABLE__MSG =  'Not a balanceable character.'
   UNBALANCED_TOKEN__MSG = 'Unbalanced token.'

   WIDE_PASTE__MSG =       'Pasted text is wider than margins.  Reflow?'
