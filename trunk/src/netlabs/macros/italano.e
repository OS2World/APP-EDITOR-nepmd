/****************************** Module Header *******************************
*
* Module Name: italano.e
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
; This file defines the various text constants as German strings.
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

;     NLS_LANGUAGE = 'ITALANO'

const

; Now uses only 1 additional const for compile-ifs: HOST_SUPPORT
compile if not defined(HOST_SUPPORT)
   HOST_SUPPORT = 0
compile endif

;; Box.e  -- Try to keep P, C, A, E, R & S the same; otherwise requires macro changes
   BOX_ARGS__MSG =        'Arg: 1=³ 2=º 3=| 4=Û 5=Ø 6=× B=Spz /Car P=Pas C=C A=Asm E=Canc R=Formatta S=Scr'
   BOX_MARK_BAD__MSG =    "Area marcata non all'interno di un riquadro"

;; Buff.e
   CREATEBUF_HELP__MSG =  ' CREATEBUF  crea il buffer EBUF; "CREATEBUF 1" per un buffer privato.'
   PUTBUF_HELP__MSG =     ' PUTBUF     inserisce nel buffer il file, dalla riga corrente alla fine.'
   GETBUF_HELP__MSG =     ' GETBUF     inserisce nel file il contenuto del buffer.'
   FREEBUF_HELP__MSG =    ' FREEBUF    libera il buffer.'
   ERROR_NUMBER__MSG =    'numero errore'
   EMPTYBUF_ERROR__MSG =  'Buffer vuoto, nulla da richiamare'
                  --      'Richiamati' number 'byte da un buffer di' number' byte,' number 'righe'
   GOT__MSG =             'Richiamati'
   BYTES_FROM_A__MSG =    'byte da un buffer di'
   PUT__MSG =             'Inseriti'
   BYTES_TO_A__MSG =      'byte in un buffer di'
   BYTE_BUFFER__MSG =     ' byte'
   CREATED__MSG =         'Creato.'
   FREED__MSG =           'Liberato.'
   MISSING_BUFFER__MSG =  'Occorre fornire un nome per il buffer.'
             --      'Eccedenza buffer? Poteva contenere solo' noflines 'righe.'
   ONLY_ACCEPTED__MSG =   'Eccedenza buffer? Poteva contenere solo'
   CAN_NOT_OPEN__MSG =    'Impossibile aprire un buffer denominato'

;; Clipbrd.e
   NO_MARK_NO_BUFF__MSG = 'Nessuna area marcata; buffer condiviso vuoto.'
   CLIPBOARD_EMPTY__MSG = 'Il notes Š vuoto'
   CLIPBOARD_ERROR__MSG = 'Errore di lettura del notes'
   NOTHING_TO_PASTE__MSG ='Nulla da inserire.'
   TRYING_TO_FREE__MSG =  'cercando di liberare il vecchio'
   BUFFER__MSG =          'buffer'
   NO_MARK_DELETED__MSG = 'Nessuna marcatura cancellata da questa finestra.'
   NO_TEST_RECOVERED__MSG='Nessun testo recuperato.'
   ERROR_COPYING__MSG =   'Errore durante la copia di'
   ONLY__MSG =            'Solo'
   LINES_OF__MSG =        "righe dell'originale"
   RECOVERED__MSG =       'sono state recuperate.'
   TOO_MUCH_FOR_CLIPBD__MSG= 'Troppo testo selezionato per il buffer del notes.'
   CLIPBOARD_VIEW_NAME =  '.Notes'  -- file name; initial '.' marks it as a temp file

;; Modify.e
   AUTOSAVING__MSG =      'Salvataggio automatico...'

;; Mouse.e
   UNKNOWN_MOUSE_ERROR__MSG = "Errore sconosciuto durante elaborazione eventi mouse: "

;; Dosutil.e
   TODAY_IS__MSG =        'Oggi Š il'
   THE_TIME_IS__MSG =     'Sono le'
   MONTH_LIST =           'Gennaio  Febbraio Marzo    Aprile   Maggio   '||
                          'Giugno   Luglio   Agosto   SettembreOttobre  '||
                          'Novembre Dicembre '
   MONTH_SIZE = 9     -- Length of the longest month name
   WEEKDAY_LIST =         'Domenica Luned   Marted  Mercoled' ||
                          'Gioved  Venerd  Sabato   Domenica '
   WEEKDAY_SIZE = 9   -- length of the longest weekday name
   AM__MSG = 'am'
   PM__MSG = 'pm'
   ALT_1_LOAD__MSG =      'Portare il cursore sul file desiderato e premere Alt-1 per caricarlo.'
   ENTER_CMD__MSG =       'Immettere il comando OS/2'

;; Draw
   ALREADY_DRAWING__MSG = 'Modo DRAW gi… attivo. Comando ignorato.'
   DRAW_ARGS__MSG =       'Argomenti validi:  1=³  2=º  3=|  4=Û  5=Ø  6=×  B=spazio  o  /Un carattere'
   DRAW_ARGS_DBCS__MSG =  'Argomenti validi:  1='\5'  2=|  3='\11'  4='\14'  5='\20'  6='\26'  B=spazio  o  /Un carattere'
   DRAW_PROMPT__MSG =     'Modo DRAW:  '\27' '\26' '\24' '\25'  per tracciare:'||
                          ' Ins per sollevare la penna; Esc o Invio per annullare.'
   DRAW_ENDED__MSG =      'Fine modo DRAW'

;; Get.e
   NO_FILENAME__MSG =     'Nessun nome specificato per'
   INVALID_OPTION__MSG =  'Opzione non valida'
   FILE_NOT_FOUND__MSG =  'File non trovato'
   FILE_IS_EMPTY__MSG =   'File vuoto'
   NOT_2_COPIES__MSG =    'Memoria insufficiente per due copie di'

;; Main.e
;;   The following name starts with a '.' to indicate that it's a temporary file:
;; UNNAMED_FILE_NAME =    '.Unnamed file'  -- Not any more; now:
   UNNAMED_FILE_NAME =    '.Senza nome'

;; Mathlib.e
   SYNTAX_ERROR__MSG =    'Errore di sintassi'

;; Put.e
   NO_CONSOLE__MSG =      'Impossibile salvare sulla console da una finestra PM.'
   MARK_APPENDED__MSG =   'Testo marcato scritto su'

;; Sort.e
                  --      'Ordinamento' number 'righe'
   SORTING__MSG =         'Ordinamento di'
   LINES__MSG =           'righe'
   NO_SORT_MEM__MSG =     'Memoria insufficiente. Impossibile inserire le righe ordinate. File invariato.'

;; Charops.e
   CHAR_ONE_LINE__MSG =   'La marcatura di caratteri deve iniziare e finire sulla stessa riga.'
   PFILL_ERROR__MSG =     'Errore in PFill_Mark'
   TYPE_A_CHAR__MSG =     'Digitare un carattere'
   ENTER_FILL_CHAR__MSG = 'Immettere un carattere di riempimento'
   FILL__MSG =            'Riempimento'  -- Title
   NO_CHAR_SUPPORT__MSG = "E' stato omesso il supporto per la marcatura dei caratteri."

;; Exit.e
   ABOUT_TO_EXIT__MSG =   'Uscita da E. '

;; Linkcmds.e
   LINK_COMPLETED__MSG =  'Collegamento completato, modulo n.'
   QLINK_PROMPT__MSG =    'Specificare il nome del modulo, come per "qlink draw".'
   NOT_LINKED__MSG =      'non Š collegato'
   CANT_FIND1__MSG =      'Impossibile trovare'  -- sayerror 'Impossibile trovare "module" su disco'
   CANT_FIND2__MSG =      "su disco"
   LINKED_AS__MSG =       'Š collegato come modulo n.' -- sayerror module' Š collegato come modulo # 'result'.'
   UNABLE_TO_LINK__MSG =  'Impossibile collegare:'
   UNABLE_TO_EXECUTE__MSG='Impossibile eseguire il comando:'

;; Math.e
   NO_NUMBER__MSG =       "Nessun numero trovato (dalla posizione del cursore fino alla fine del file)"

;; Stdcnf.e
   STATUS_TEMPLATE__MSG = 'Riga %l di %s   Colonna %c  %i   %m   %f   '
   DIR_OF__MSG =          'Indirizzario di'  -- Must match what DIR cmd outputs!

;; Window.e
   ZOOM_PROMPT__MSG =     'Lo stile attuale della finestra di zoom Š'
   CHOICES_ARE__MSG =     'Le scelte sono'
   DRAG__MSG =            'Usare le frecce per trascinare la finestra. Quindi, premere INVIO o ESC'
                -- 'DRAG' MESSY_ONLY__MSG  or 'SIZE' MESSY_ONLY__MSG
   MESSY_ONLY__MSG =      'Š utilizzabile solo con finestre sovrapposte'

;; Shell.e
   INVALID_ARG__MSG =     'Argomenti non validi'

;; Sort.e       -- 'Ordinare:  Inserendo 'noflines' righe nel buffer, si ottengono 'noflinesback'.'
                -- 'Ordinamento:' PUT__MSG noflines SORT_ERROR1__MSG noflinesback SORT_ERROR2__MSG
   SORT_ERROR1__MSG =    'righe nel buffer, ottenute'
   SORT_ERROR2__MSG =    'righe.'

;; Retrieve.e
   CMD_STACK_CLEAR__MSG= 'Area di stack dei comandi azzerata.'
   CMD_STACK_EMPTY__MSG= 'Area di stack dei comandi vuota.'

;; Help.e
   HELP_BROWSER__MSG =   'Visualizzazione aiuto'  -- Message box title
   HELP_STATUS__MSG =    ' Tasti validi ->  RitPg e AvPg      F3,ESC=Chiude finestra aiuto'
   NO_DROP__MSG =        'Impossibile rilasciare i file in questo punto.'
   SYS_ED__MSG =         "Avvertenza dell'Editor di sistema"
   SYS_ED1__MSG =        'Perch‚ si desidera eseguire'\10'una tale operazione?'
             -- 'Errore' err_no 'assegnando un segmento di memoria; comando interrotto.'
   ALLOC_HALTED__MSG =   'assegnando un segmento di memoria; comando interrotto.'
   QUICK_REF__MSG =      'Riferimento rapido'  -- Window title

;; All.e
   NO_ALL_FILE__MSG =    'File .ALL non presente nel ciclo.'
   BAD_ALL_LINE__MSG =   'Numero di riga mancante o non valido nel file .ALL.'

;; Eos2lex.e
   EOS2LEX_PROMPT1__MSG = 'Spazio=Visualizzare elenco     Esc=Passare a     F3 o F10=Interrompere'
   SPELLED_OK__MSG =      'l''ortografia della parola Š esatta'
                -- Limit the following to 80 characters.
   EOS2LEX_PROMPT2__MSG = 'Esc=Succ.  F4=Agg. diz. pers.  F5=Agg. temp.  F8=Modif. glob.  F3,F10=Annul.'
   MORE__MSG =            'segue'
   NO_MATCH__MSG =        'Nessuna parola corrisponde a'  -- 'Nessuna corrispondenza' spellword
   EXIT_SPELL__MSG =      'Si desidera uscire dal controllo ortografico (S/N)?'
   THINKING__MSG =        'attendere...'
   DONE__MSG =            'Controllo completato.'
   NO_SYN__MSG =          'Non Š stato trovato alcun sinonimo per' -- word
   BAD_DICT__MSG =        'Errore relativo al dizionario.'
   INIT_ERROR__MSG =      'Errore di inizializzazione.'
                     -- 'Errore nel caricamento del dizionario personale' addenda_filename
   BAD_ADDENDA__MSG =     'Errore nel caricamento del dizionario personale'

;; Shell.e           -- 'Errore' rc 'durante la creazione di un oggetto interfaccia comandi.'
   SHELL_ERROR1__MSG =    'durante creazione interfaccia comandi.'
   SHELL_ERROR2__MSG =    'durante creazione file di editazione per interfaccia comandi.'
   NOT_IN_SHELL__MSG =    'Non presente in un file interfaccia comandi.'
   SHELL_ERROR3__MSG =    'durante chiusura interfaccia comandi.'
                     -- 'Immettere il testo da scrivere nella finestra per comandi' shell_number
   SHELL_PROMPT__MSG =    'Immettere il testo da scrivere nell''interfaccia comandi'
                     -- 'oggetto della finestra per comandi' number 'pu• accettare altri dati...'
   SHELL_OBJECT__MSG =    'La finestra comandi'
   SHELL_READY__MSG =     'pu• accettare dati...'

;; Stdprocs.e
   ARE_YOU_SURE_YN__MSG = '  Si Š sicuri (S/N)? '  -- Keep spaces
   ARE_YOU_SURE__MSG =    'Si Š sicuri?'
   YES_CHAR =             'S'  -- First letter of Yes
   NO_CHAR =              'N'  -- First letter of No
   NO_MARK__MSG =         'Nessuna area marcata'
   NO_MARK_HERE__MSG =    'Nessuna area marcata nella finestra corrente'
   ERROR__MSG =           'Errore'
   ERROR_LOADING__MSG =   'Errore durante il caricamento di'  -- filename
   NOT_LOCKED__MSG =      '- file non bloccato.'
   CHAR_INVALID__MSG =    'Marcatura carattere non valida.'
   INVALID_NUMBER__MSG =  'Argomento numero non valido'
   CANT_FIND_PROG__MSG =  "Impossibile trovare il programma"  -- progname
   NO_FLOAT__MSG =        'Numero a virgola mobile non consentito:' -- number
   NEED_BLOCK_MARK__MSG = 'Necessaria marcatura blocco'
               -- Error <nn> editing temp file:  <error_message>
   BAD_TMP_FILE__MSG =    'editing temp file:'

;; Stdctrl.e
   BUTTON_ERROR__MSG =    'errore tasto'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   ENTER__MSG =           '~Invio'
   OK__MSG =              '~OK'
   CANCEL__MSG =          'Annullo'
   SELECT__MSG =          '~Selezionare'
   HELP__MSG =            'Aiuto'
   FONTLIST_PROMPT__MSG = 'Dimensione cella font (larghezza x altezza); corr. ='
   TO_LARGE_FONT__MSG =   'Passare al font pi— ~grande'   -- Tilde must be before a character
   TO_SMALL_FONT__MSG =   'Passare al font pi— ~piccolo'  -- that's the same in both messages
   EXISTS_OVERLAY__MSG =  'Il file esiste gi…. Si desidera ricoprirlo?'
   NO_SLASH__MSG =        'Il testo della cartella era la stringa sopra riportata; "\" non trovato.'
   LISTING__MSG =         'Creazione elenco...'
   ONLY_FILE__MSG =       'Questo Š l''unico file del ciclo.'
   TOO_MANY_FILES__MSG =  "Troppi file"
   NOT_FIT__MSG =         'Il buffer alla massima dimensione non pu• contenere tutti i nomi di file.'
   FILES_IN_RING__MSG =   'File nel ciclo'  -- This is a listbox title
   UNEXPECTED__MSG =      'Errore - risultato inatteso.'
   PROCESS_ERROR__MSG =   'Errore durante l''elaborazione della funzione associata all''id'
   MENU_ERROR__MSG =      'Errore nel menu attivo'
   REFLOW_ALL__MSG =      "Si desidera riformattare l'intero documento con i nuovi margini?"
   SAVE_AS__MSG =         'Salva come:'
   LIST_TOO_BIG__MSG =    'Lista troppo lunga ; non sar… mostrata tutta!.'

; Before 5.21, we didn't have accelerator keys, so we didn't want the Tilde to
; appear on the action bar.
   TILDE_CHAR = '~'

; Lots of fun here.  This is the editor's action bar.  xxx_BAR__MSG means xxx is on the
; action bar.  yyy_MENU__MSG means that yyy is on a pull-down or pull-right.  The tildes
; precede the accelerator letter; those letters must be unique in each group (pulldown
; or pullright).  Followed by a 'P' means it's the dynamic help prompt for that BAR or
; MENU item.  Note that each prompt must start with \1.
   FILE_BAR__MSG =        '~File '
     NEW_MENU__MSG =        '~Nuovo'
     OPEN_MENU__MSG =       '~Aprire...'
     OPEN_NEW_MENU__MSG =   'Aprire .S~enza nome'
     GET_MENU__MSG =        '~Importare file di testo...'
     ADD_MENU__MSG =        'A~ggiungere file...'
     RENAME_MENU__MSG =     '~Rinominare...'
     SAVE_MENU__MSG =       '~Salvare'
     SAVEAS_MENU__MSG =     'Salvare ~come...'
     FILE_MENU__MSG =       'Sa~lvare e uscire'
     SAVECLOSE_MENU__MSG =  'Salvare e ~chiudere'
     QUIT_MENU__MSG =       '~Uscire'
     PRT_FILE_MENU__MSG =   'Stam~pare file'

   FILE_BARP__MSG =        \1'Menu relativi alle operazioni sui file'
     NEW_MENUP__MSG =        \1'Sostituisce il file corrente con un file .Senza nome vuoto'
     OPEN_NEW_MENUP__MSG =   \1'Apre una nuova finestra di editazione vuota'
     OPEN_MENUP__MSG =       \1'Apre un file in una nuova finestra'
     GET_MENUP__MSG =        \1'Copia nel file corrente un file esistente'
     ADD_MENUP__MSG =        \1'Edita un nuovo file in questa finestra'
     RENAME_MENUP__MSG =     \1'Cambia il nome di questo file'
     SAVE_MENUP__MSG =       \1'Salva questo file'
     SAVEAS_MENUP__MSG =     \1'Cambia il nome di questo file, quindi lo salva con il nuovo nome'
     FILE_MENUP__MSG =       \1'Salva questo file, quindi esce'
     QUIT_MENUP__MSG =       \1'Esce da questo file'
     ENHPRT_FILE_MENUP__MSG =\1'Visualizza la finestra di stampa'
     PRT_FILE_MENUP__MSG =   \1'Stampa questo file sulla stampante assunta'

   EDIT_BAR__MSG =        '~Editare '
     UNDO_MENU__MSG =       'Regredire riga'
     UNDO_REDO_MENU__MSG =  'Re~gredire...'
     STYLE_MENU__MSG =      'Stil~e...'
     COPY_MARK_MENU__MSG =  'Copiare ~marcatura'
     MOVE_MARK_MENU__MSG =  '~Spostare marcatura'
     OVERLAY_MARK_MENU__MSG='So~vrapporre marcatura'
     ADJUST_MARK_MENU__MSG= 'Spostare e sovra~pporre marcatura'
     COPY_MRK_MENU__MSG =   '~Copia'
     MOVE_MRK_MENU__MSG =   '~Muovi'
     OVERLAY_MRK_MENU__MSG= 'S~ovrapponi'
     ADJUST_MRK_MENU__MSG=  '~Aggiusta'
     UNMARK_MARK_MENU__MSG= 'Eliminare marcatura'
     DELETE_MARK_MENU__MSG= 'Ca~ncellare marcatura'
     DELETE_MENU__MSG=      'Cance~lla'
     PUSH_MARK_MENU__MSG =  'Memorizzare posizione marcatura'
     POP_MARK_MENU__MSG =   'Ripristinare posizione marcatura'
     SWAP_MARK_MENU__MSG =  'Scambiare posizione marcatura'
     PUSH_MRK_MENU__MSG =   'Salva'
     POP_MRK_MENU__MSG =    'Ripristina'
     SWAP_MRK_MENU__MSG =   'Scambia'
     PUSH_CURSOR_MENU__MSG ='Memorizzare posizione cursore'
     POP_CURSOR_MENU__MSG = 'Ripristinare posizione cursore'
     SWAP_CURSOR_MENU__MSG= 'Scambiare posizione cursore'
     CLIP_COPY_MENU__MSG =  'Co~piare'
     CUT_MENU__MSG =        'Es~trarre'
     PASTE_C_MENU__MSG =    '~Inserire'
     PASTE_L_MENU__MSG =    'Inserire rig~he'
     PASTE_B_MENU__MSG =    'Inserire ~blocco'
     PRT_MARK_MENU__MSG =   'Stampa~re marcatura'
     RECOVER_MARK_MENU__MSG='Ripristinare marcatura cancellata'

   EDIT_BARP__MSG =        \1'Menu relativi a Regredire, marcature e notes'
     UNDO_MENUP__MSG =       \1'Annulla le modifiche apportate alla riga corrente'
     UNDO_REDO_MENUP__MSG =  \1'Attiva la finestra Regredire per visualizzare le modifiche dei file.'
     STYLE_MENUP__MSG =      \1'Cambia lo stile per il testo marcato o registra uno stile'
     COPY_MARK_MENUP__MSG =  \1'Copia il testo marcato in corrispondenza del cursore'
     MOVE_MARK_MENUP__MSG =  \1'Sposta il testo marcato in corrispondenza del cursore'
     OVERLAY_MARK_MENUP__MSG=\1'Sovrappone il testo marcato a quello successivo al cursore'
     ADJUST_MARK_MENUP__MSG= \1'Sovrappone il testo marcato cancellandolo dalla posizione originale'
     UNMARK_MARK_MENUP__MSG= \1'Elimina la marcatura del testo'
     DELETE_MARK_MENUP__MSG= \1'Cancella il testo marcato'
     PUSH_MARK_MENUP__MSG =  \1'Salva in un''area di stack i limiti dell''area marcata'
     POP_MARK_MENUP__MSG =   \1'Ripristina i limiti dell''area marcata salvati in un''area di stack'
     SWAP_MARK_MENUP__MSG =  \1'Scambia i limiti correnti dell''area marcata con quelli ad inizio stack'
     PUSH_CURSOR_MENUP__MSG =\1'Salva in un''area di stack la posizione del cursore nel file'
     POP_CURSOR_MENUP__MSG = \1'Ripristina la posizione del cursore nel file salvata in un''area di stack'
     SWAP_CURSOR_MENUP__MSG= \1'Scambia la posizione corrente del cursore con quella ad inizio stack'
     CLIP_COPY_MENUP__MSG =  \1'Copia nel notes il testo marcato'
     CUT_MENUP__MSG =        \1'Copia nel notes il testo marcato e lo cancella dal file'
     PASTE_C_MENUP__MSG =    \1'Inserisce nel file, come testo marcato, il testo presente nel notes'
     PASTE_L_MENUP__MSG =    \1'Inserisce nel file, come nuove righe, il testo presente nel notes'
     PASTE_B_MENUP__MSG =    \1'Inserisce nel file, come blocco rettangolare, il testo presente nel notes'
     ENHPRT_MARK_MENUP__MSG =\1'Visualizza la finestra per la stampa del testo marcato'
     PRT_MARK_MENUP__MSG =   \1'Stampa il testo marcato sulla stampante assunta'
     RECOVER_MARK_MENUP__MSG=\1'Inserisce dopo il cursore una copia dell''ultimo testo marcato cancellato'

   SEARCH_BAR__MSG =      '~Ricercare '
     SEARCH_MENU__MSG =     '~Ricercare...'
     FIND_NEXT_MENU__MSG =  '~Trovare successivo'
     CHANGE_NEXT_MENU__MSG= '~Modificare successivo'
     BOOKMARKS_MENU__MSG =  '~Segnalibri'     -- Pull-right
       SET_MARK_MENU__MSG =   '~Collocare...'
       LIST_MARK_MENU__MSG =  '~Elencare...'
       NEXT_MARK_MENU__MSG =  '~Successivo'
       PREV_MARK_MENU__MSG =  '~Precedente'
     TAGS_MENU__MSG =       '~Tags'          -- Pull-right
       TAGSDLG_MENU__MSG =    '~dialogo Tags..'
       FIND_TAG_MENU__MSG =   '~Trova procedura attuale'
       FIND_TAG2_MENU__MSG =  'Trova ~procedura...'
       TAGFILE_NAME_MENU__MSG='~nome.Tags file...'
       MAKE_TAGS_MENU__MSG =  '~Crea tags file...'
       SCAN_TAGS_MENU__MSG =  'Cerca il file ~attuale...'

   SEARCH_BARP__MSG =      \1'Menu relativi alla ricerca e modifica del testo ed ai segnalibri'
     SEARCH_MENUP__MSG =     \1'Attiva la finestra per la ricerca e la sostituzione del testo'
     FIND_NEXT_MENUP__MSG =  \1'Ripete il precedente comando di ricerca'
     CHANGE_NEXT_MENUP__MSG= \1'Ripete il precedente comando di modifica'
     BOOKMARKS_MENUP__MSG=   \1'Menu concatenato per la gestione dei segnalibri'
     SET_MARK_MENUP__MSG =   \1'Colloca un segnalibro in corrispondenza del cursore'
     LIST_MARK_MENUP__MSG =  \1'Elenca i segnalibri; si pu• passare ad un segnalibro o cancellarlo'
     NEXT_MARK_MENUP__MSG =  \1'Passa al successivo segnalibro in questo file'
     PREV_MARK_MENUP__MSG =  \1'Passa al precedente segnalibro in questo file'
     TAGS_MENUP__MSG =       \1'Menu a tendina per usare un "tags" file'
     TAGSDLG_MENUP__MSG =    \1'Attiva un dialogo "tags"'
     FIND_TAG_MENUP__MSG =   \1'Trova la definizione per la procedura puntata dal cursore'
     FIND_TAG2_MENUP__MSG =  \1'Trova la definizione per una procedura da immettere'
     TAGFILE_NAME_MENUP__MSG=\1'Controlla o imposta il nome del tags file'
     MAKE_TAGS_MENUP__MSG =  \1'Crea o aggiorna un tags file'
     SCAN_TAGS_MENUP__MSG =  \1'Cerca il file attuale per una procedura & presentala in una lista'

   OPTIONS_BAR__MSG         = '~Opzioni '
     LIST_FILES_MENU__MSG     = '~Elenco file nel ciclo...'
     FILE_LIST_MENU__MSG      = 'lista ~Files...'
     PROOF_MENU__MSG          = '~Controllo ortografico'
     PROOF_WORD_MENU__MSG     = 'Controllo ortografico ~parola'
     DYNASPELL_MENU__MSG      = 'Controllo Ortografico ~Automatico'
     SYNONYM_MENU__MSG        = '~Sinonimo'
     DEFINE_WORD_MENU__MSG    = '~Definire parola'
     PREFERENCES_MENU__MSG    = 'P~referenze'   -- this is a pull-right; next few are separate group.
       CONFIG_MENU__MSG         = '~Impostazioni...'
       SETENTER_MENU__MSG       = 'I~mpostare Invio...'
       ADVANCEDMARK_MENU__MSG   = 'Marcatura modo a~vanzato'
       STREAMMODE_MENU__MSG     = 'Edita~zione continua'
       RINGENABLED_MENU__MSG    = 'Ciclo ~attivato'
       STACKCMDS_MENU__MSG      = 'Comandi area di stac~k'
       CUAACCEL_MENU__MSG       = 'acceleratori ~Menu'
     AUTOSAVE_MENU__MSG       = 'Salvataggio aut~omatico...'
     MESSAGES_MENU__MSG       = '~Messaggi...'
     CHANGE_FONT_MENU__MSG    = 'Cambiare ~font...'
     SMALL_FONT_MENU__MSG     = 'Font p~iccolo'
     LARGE_FONT_MENU__MSG     = 'Font ~grande'
     FRAME_CTRLS_MENU__MSG    = 'Contro~lli cornice'  -- this is a pull-right; next few are separate group.
       STATUS_LINE_MENU__MSG    = '~Riga di stato'
       MSG_LINE_MENU__MSG       = 'Riga dei ~messaggi'
       SCROLL_BARS_MENU__MSG    = '~Barre di scorrimento'
       FILEICON_MENU__MSG       = 'Simbolo file'
       ROTATEBUTTONS_MENU__MSG  = 'P~ulsanti di direzione'
       TOOLBAR_MENU__MSG        = '~Toolbar'
       TOGGLETOOLBAR_MENU__MSG  = '~Toolbar'  -- Era 'Toggle'; gli altri 3 non vengono pi— usati.
       LOADTOOLBAR_MENU__MSG    = '~Carica...'
       DELETETOOLBAR_MENU__MSG  = '~Elimina...'
       TOGGLEBITMAP_MENU__MSG   = 'bitmap di ~Sfondo '
       INFOATTOP_MENU__MSG      = 'Informa~zioni in alto'
       PROMPTING_MENU__MSG      = '~Aiuto dinamico'
     SAVE_OPTS_MENU__MSG      = 'Salvare op~zioni'
     TO_BOOK_MENU__MSG        = '~Icona EPM'

   OPTIONS_BARP__MSG         = \1'Menu relativi al controllo ortografico e alla configurazione dell''editor'
     LIST_FILES_MENUP__MSG     = \1'Elenca i file nel ciclo di editazione'
     PROOF_MENUP__MSG          = \1'Attiva il controllo ortografico del file'
     PROOF_WORD_MENUP__MSG     = \1'Verifica l''ortografia della parola in corrispondenza del cursore'
     SYNONYM_MENUP__MSG        = \1'Suggerisce un sinonimo per la parola in corrispondenza del cursore'
     DYNASPELL_MENUP__MSG      = \1'Scambia il controllo ortografica ON/OFF'
     DEFINE_WORD_MENUP__MSG    = \1'Ricerca nel dizionario la parola sul cursore e ne mostra la definizione'
     PREFERENCES_MENUP__MSG    = \1'Menu concatenato per la personalizzazione dell''editor'
       CONFIG_MENUP__MSG         = \1'Attiva la finestra per la modifica delle impostazioni dell''editor'
       SETENTER_MENUP__MSG       = \1'Configura l''azione del tasto Invio'
       ADVANCEDMARK_MENUP__MSG   = \1'Attiva o disattiva la marcatura in modo avanzato'
       STREAMMODE_MENUP__MSG     = \1'Attiva o disattiva il modo editazione continua'
       RINGENABLED_MENUP__MSG    = \1'Abilita o disabilita pi— file in una finestra'
       STACKCMDS_MENUP__MSG      = \1'Abilita/disabilita i comandi per l''area di stack nel menu Editare'
       CUAACCEL_MENUP__MSG       = \1'Abilita/disbilita il menu degli acceleratori (Alt+lettera va alla barra Azioni)'
     AUTOSAVE_MENUP__MSG       = \1'Visualizza i valori di salvataggio e, opzionalmente, l''indirizzario'
     MESSAGES_MENUP__MSG       = \1'Mostra i messaggi visualizzati precedentemente'
     CHANGE_FONT_MENUP__MSG    = \1'Cambia il font'
     CHANGE_MARKFONT_MENUP__MSG= \1'Cambia il font per il testo marcato'
     SMALL_FONT_MENUP__MSG     = \1'Passa al font pi— piccolo'
     LARGE_FONT_MENUP__MSG     = \1'Passa al font pi— grande'
     FRAME_CTRLS_MENUP__MSG    = \1"Menu concatenato con varie caratteristiche della cornice della finestra"
       STATUS_LINE_MENUP__MSG    = \1'Attiva o disattiva la visualizzazione della riga di stato'
       MSG_LINE_MENUP__MSG       = \1'Attiva o disattiva la visualizzazione della riga dei messaggi'
       SCROLL_BARS_MENUP__MSG    = \1'Attiva/disattiva la visualizzazione delle barre di scorrimento'
       FILEICON_MENUP__MSG       = \1'Attiva o disattiva il simbolo di trascinamento e rilascio file'
       ROTATEBUTTONS_MENUP__MSG  = \1'Attiva/disattiva la visualizzazione dei pulsanti di direzione'
       TOOLBAR_MENUP__MSG        = \1'Men— a tendina per azioni relative alla Toolbar'
         TOGGLETOOLBAR_MENUP__MSG  = \1'Scambia toolbar ON/OFF'
         LOADTOOLBAR_MENUP__MSG    = \1'Carica una toolbar salvata precedentemente'
         SAVETOOLBAR_MENUP__MSG    = \1'Salva una toolbar personalizzata'
         DELETETOOLBAR_MENUP__MSG  = \1'Elimina una data toolbar'
       TOGGLEBITMAP_MENUP__MSG   = \1'Toggle bitmap behind text window on or off'
       INFOATTOP_MENUP__MSG      = \1'Cambia la posizione della riga di stato e dei messaggi'
       PROMPTING_MENUP__MSG      = \1'Attiva o disattiva l''aiuto dinamico per i menu'
     SAVE_OPTS_MENUP__MSG      = \1'Rende assunte le impostazioni correnti dei modi e della cornice'
     TO_BOOK_MENUP__MSG        = \1'Passa all''icona EPM o alla scrivania'

   RING_BAR__MSG =        'C~iclo '

   COMMAND_BAR__MSG =     '~Comando '
     COMMANDLINE_MENU__MSG = 'Finestra co~mandi...'
     HALT_COMMAND_MENU__MSG= '~Arrestare comando'
     CREATE_SHELL_MENU__MSG= 'Creare ~interfaccia comandi'
     WRITE_SHELL_MENU__MSG = 'Scri~vere in interfaccia comandi...'
     KILL_SHELL_MENU__MSG =  '~Eliminare interfaccia comandi'
     SHELL_BREAK_MENU__MSG = 'Manda un ~break alla shell'

   COMMAND_BARP__MSG =     \1'Immette o arresta un comando',
     COMMANDLINE_MENUP__MSG = \1"Attiva la finestra per immettere comandi dell'editor o OS/2"
     HALT_COMMAND_MENUP__MSG= \1'Interrompe l''esecuzione del comando corrente'
     CREATE_SHELL_MENUP__MSG= \1'Crea un''interfaccia comandi'
     WRITE_SHELL_MENUP__MSG = \1"Scrive una stringa sulla riga comandi dell'interfaccia comandi"
     KILL_SHELL_MENUP__MSG =  \1"Elimina l'interfaccia comandi e cancella il file di editazione"
     SHELL_BREAK_MENUP__MSG = \1'Manda un messaggio di Ctrl+Break alla shell'

   HELP_BAR__MSG =        '~Aiuto '
     HELP_HELP_MENU__MSG =   '~Uso dell''aiuto'  -- was '~Aiuto per l''aiuto'
     EXT_HELP_MENU__MSG =    'Aiuto ~generico'  -- was 'Aiuto ~esteso...'
     KEYS_HELP_MENU__MSG =   'Aiuto per ~tasti funzione'
     COMMANDS_HELP_MENU__MSG =   'Aiuto ~Commandi'
     HELP_INDEX_MENU__MSG =  '~Indice analitico dell''aiuto'
     HELP_BROWSER_MENU__MSG= '~Riferimento rapido'
     HELP_PROD_MENU__MSG=    'Informazioni sul ~prodotto'
     USERS_GUIDE_MENU__MSG = "Guida ~Utente "
       VIEW_USERS_MENU__MSG =  "~Visualizza Guida Utente"
       VIEW_IN_USERS_MENU__MSG="~Parola attuale"
       VIEW_USERS_SUMMARY_MENU__MSG="~Sommario"
     TECHREF_MENU__MSG =     "View ~Technical Reference"
       VIEW_TECHREF_MENU__MSG =  "~Visualizza Technical Reference"
       VIEW_IN_TECHREF_MENU__MSG="~Parola attuale"

   HELP_BARP__MSG =         \1'Menu di accesso ai pannelli di aiuto e alle informazioni sul copyright'
     HELP_HELP_MENUP__MSG =   \1'Aiuto sulla gestione dell''aiuto'
     EXT_HELP_MENUP__MSG =    \1'Visualizza il pannello di aiuto principale dell''editor'
     KEYS_HELP_MENUP__MSG =   \1'Aiuto per i tasti definiti dell''editor'
     COMMANDS_HELP_MENUP__MSG=\1'Aiuto per i commandi dell''editor'
     HELP_INDEX_MENUP__MSG =  \1'Visualizza l''indice analitico dell''aiuto'
     HELP_BROWSER_MENUP__MSG= \1'Visualizza un riferimento rapido relativo all''editor (con tabella ASCII)'
     HELP_PROD_MENUP__MSG=    \1'Informazioni sul copyright e sulla versione'
     USERS_GUIDE_MENUP__MSG = \1"Vsualizza Guida Utente, ocerca una parola in essa"
       VIEW_USERS_MENUP__MSG =  \1"Chiama il visualizzatore per leggere la Guida Utente"
       VIEW_IN_USERS_MENUP__MSG=\1"Cerca la parola attuale nella Guida Utente"
       VIEW_USERS_SUMMARY_MENUP__MSG=\1"Visualizza la sezione ""Summary of Configuration Constants"""
     TECHREF_MENUP__MSG =     \1"Visualizza il Technical Reference, o cerca una parola in esso"
       VIEW_TECHREF_MENUP__MSG=   \1"Chiama il visualizzatore per leggere il Technical Reference"
       VIEW_IN_TECHREF_MENUP__MSG=\1"Cerca la parola attuale nel Technical Reference"

   COMPILER_BAR__MSG =           'Co~mpilatore'
     NEXT_COMPILER_MENU__MSG =     'Errore ~successivo'
     PREV_COMPILER_MENU__MSG =     'Errore ~precedente'
     DESCRIBE_COMPILER_MENU__MSG = '~Descrizione errori'
     CLEAR_ERRORS_MENU__MSG =      '~Correzione errori'
     END_DDE_SESSION_MENU__MSG =   '~Fine sessione DDE'
     REMOVE_COMPILER_MENU__MSG =   '~Rimuovi il men— del compilatore'

   COMPILER_BARP__MSG =           \1'Selezioni relative al compilatore'
     NEXT_COMPILER_MENUP__MSG =     \1'Passa al successivo errore del compilatore'
     PREV_COMPILER_MENUP__MSG =     \1'Passa al precedente errore del compilatore'
     DESCRIBE_COMPILER_MENUP__MSG = \1'Elenca gli errori della riga corrente ed opzionalmente richiama l''aiuto.'
     CLEAR_ERRORS_MENUP__MSG =      \1'Rimuove evidenziazione e segnalibro per errori del compilatore'
     END_DDE_SESSION_MENUP__MSG =    \1'Termina la sessione DDE con il Workframe'
     REMOVE_COMPILER_MENUP__MSG =    \1'Rimuovi il men— del compilatoree dalla barra delle Azioni'

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
   SEARCH_ACCEL__L =     'R'  -- Ricercare
   SEARCH_ACCEL__A1 =     82
   SEARCH_ACCEL__A2 =    114
   OPTIONS_ACCEL__L =    'O'
   OPTIONS_ACCEL__A1 =    79
   OPTIONS_ACCEL__A2 =   111
   RING_ACCEL__L =       'I'  -- C~iclo
   RING_ACCEL__A1 =       73
   RING_ACCEL__A2 =      105
   COMMAND_ACCEL__L =    'C'
   COMMAND_ACCEL__A1 =    67
   COMMAND_ACCEL__A2 =    99
   HELP_ACCEL__L =       'A'  -- Aiuto
   HELP_ACCEL__A1 =       65
   HELP_ACCEL__A2 =       97
   COMPILER_ACCEL__L =   'M'  -- Co~mpilatore
   COMPILER_ACCEL__A1 =   77
   COMPILER_ACCEL__A2 =  109

;        New stuff for OVSHMENU.E.
   VIEW_ACCEL__L =       'V'
   VIEW_ACCEL__A1 =       86
   VIEW_ACCEL__A2 =      118
   SELECTED_ACCEL__L =   'S'
   SELECTED_ACCEL__A1 =   83
   SELECTED_ACCEL__A2 =  115

   VIEW_BAR__MSG =        '~Visualizza'
   SELECTED_BAR__MSG =        '~Scegli'

     OPENAS_MENU__MSG  =    '~Apri come:'
     OPENNOAS_MENU__MSG  =  '~Apri'
     NEWWIN_MENU__MSG =     '~Nuova finestra...'
     SAMEWIN_MENU__MSG =    'Stessa ~Finestra...'
     COMMAND_SHELL_MENU__MSG='shell ~Commandi '
     PRINT_MENU__MSG =      'Stam~pa...'
     UNDO__MENU__MSG =      '~Undo'
     SELECT_ALL_MENU__MSG = 'Seleziona ~Tutto'
     DESELECT_ALL_MENU__MSG = 'D~eseleziona tutto'

     OPENAS_MENUP__MSG  =       \1'Apri un file or edit object settings'
     NEWWIN_MENUP__MSG =        \1'Rimpiazza il file attuale con uno vuoto .Untitled file'
     UNDO__MENUP__MSG =         \1'Men— relativi ad Undo, marca, e lavagna'
     SELECT_ALL_MENUP__MSG =    \1'Seleziona tutto il testo nel file (character-mark)'

   VIEW_BARP__MSG =        \1'Men— relativi a ricerca, tags, bookmarks, commandi, etc.'
   SELECTED_BARP__MSG =         \1'Men— relativi al testo selezionato'

; End of additions for OVSH menus.

   NO_PRINTERS__MSG =     '(Nessuna stampante)'
   PRINT__MSG =           'Stampare'  -- Dialog box title
   DRAFT__MSG =           '~Bozza'  -- Button
   WYSIWYG__MSG =         '~Testo formattato'  -- Button  (What You See Is What You Get)
   SELECT_PRINTER__MSG =  'Selezione stampante'
           -- 'Alla stampante' printername 'non Š associato alcun dispositivo.'
   PRINTER__MSG =         'Alla stampante'
   NO_DEVICE__MSG =       'non Š associata alcuna unit….'
   NO_QUEUE__MSG =        'non Š associata alcuna coda.'
   EDITOR__MSG =          "Editor EPM - Informazioni sul prodotto"
   EDITOR_VER__MSG =      "Versione Editor" -- nnn
   MACROS_VER__MSG =      "Versione Macro" -- nnn
   COPYRIGHT__MSG =       "(C) Copyright IBM Corporation 1989, 1992"
   OVERLAPPING_ATTRIBS__MSG = 'Sovrapposizione attributi; nulla cambiato.'       /*NLS*/
                            -- Following is followed by pres. parm. name
   UNKNOWN_PRESPARAM__MSG = "Cambio caratteri di presentazione sconosciuto:"     /*NLS*/
                            -- Following is followed by action name
   UNKNOWN_ACTION__MSG =  'Non posso effettuare quanto chiesto'                  /*NLS*/

;; Epmlex.e
   REPLACE__MSG =         'Sos~tituire'
   SYNONYMS__MSG =        'Sinonimi'  -- Listbox Title
            -- "Controllo ortografico dell'area contrassegnata" or "... file"
   CHECKING__MSG =        'Controllo ortografico'
   MARKED_AREA__MSG =     'area marcata'
   FILE__MSG =            'file'
   NEXT__MSG =            '~Successiva'       -- button
   TEMP_ADD__MSG =        'Agg. ~temp.'  -- button, so keep short
   ADD__MSG =             '~Aggiungere'        -- button:  Add to addenda
   EDIT__MSG =            '~Editare'       -- button
   EXIT__MSG =            '~Uscita'       -- button
   LOOKUP_FAILED__MSG =   'Ricerca non riuscita per la parola' -- <word>
   PROOF__MSG =           'Controllo ortografico'  -- Listbox title; "Controllo ortografico <word>"
   REPLACEMENT__MSG =     'Immettere la frase per sostituire'  -- <word>
   PROOF_WORD__MSG =      'Controllo ortografico parola'  -- Listbox title
   NO_DICT__MSG =         'Il dizionario non esiste:'  -- dict_filename
   DICT_PTR__MSG =        'Per cambiare dizionario usa la pagina Path del setting notebook'
   DICTLIST_IS__MSG =     'L''elenco del dizionario Š:'  -- list of file names
             -- 'File "'new_name'" non trovato; il dizionario rimane:' old_name
   DICT_REMAINS__MSG =    'il dizionario rimane:'
             -- "Nothing found for <bad_word>".  Used in a dialog;
   WORD_NOT_FOUND__MSG =  'Non ho trovato niente'     --  try to keep this short.

;; Stdkeys.e
   MARKED_OTHER__MSG =    "You had a marked area in another file; it has been unmarked."
   MARKED_OFFSCREEN__MSG= "You had a marked area not visible in the window; it has been unmarked."
   CANT_REFLOW__MSG =     "Impossibile riformattare il testo"
   OTHER_FILE_MARKED__MSG="Area marcata gi… presente in un altro file."
   MARK_OFF_SCRN_YN__MSG= "Area marcata al di fuori dello schermo. Si desidera continuare?  (S/N)"
   MARK_OFF_SCREEN__MSG = "Impossibile riformattare il testo. Area marcata al di fuori dello schermo."
   WRONG_MARK__MSG =      'E'' necessario marcare un blocco o una riga'
   PBLOCK_ERROR__MSG =    'Errore in pblock_reflow'
   BLOCK_REFLOW__MSG =    "BlockReflow: Marcare il nuovo blocco con Alt-B; premere ancora Alt-R (Esc per annullare)"
   NOFLOW__MSG =          'Blocco marcato non riformattato'
   CTRL_R__MSG =          'Registrazione battute. Ctrl-R per terminare, Ctrl-T per terminare e provare, Ctrl-C per annullare.'
   REMEMBERED__MSG =      'Registrazione effettuata. Premere Ctrl-T per eseguire.'
   CANCELLED__MSG =       'Operazione annullata.'
   CTRL_R_ABORT__MSG =    'Stringa troppo lunga. Premere Ctrl-C per annullare.'
   OLD_KEPT__MSG =        'Macro tasti precedente non sostituita.'
   NO_CTRL_R__MSG =       'Nessuna macro registrata'

;; Stdcmds.e
   ON__MSG =              'ON'  -- Must be upper case for comparisons
   OFF__MSG =             'OFF'
          -- Following is missing close paren on purpose.  sometimes ends ')', others '/?)'
   ON_OFF__MSG =          '(On/Off/1/0'  -- Used in prompts: 'Argomenti non validi (On/Off/1/0)'
   PRINTING__MSG =        'Stampa di'  -- 'Stampa' .filename
   CURRENT_AUTOSAVE__MSG= 'Valore corrente salvataggio automatico='
   NAME_IS__MSG =         'Nome='
   LIST_DIR__MSG =        "Elenco indirizzario salvataggio automatico?"
   NO_LIST_DIR__MSG =     '[Ciclo disattivato; impossibile visualizzare indirizzario.]'
   AUTOSAVE__MSG =        'Salvataggio automatico'  -- messagebox title
   AUTOSAVE_PROMPT__MSG = 'Immettere AUTOSAVE <numero> per impostare il numero di modifiche tra i salvataggi. 0 = off.'
   BROWSE_IS__MSG =       'Il modo visualizzazione Š' -- on/off
   READONLY_IS__MSG =     'il flag di Read-only Š' -- on/off
   NO_REP__MSG =          'Non Š stata specificata alcuna stringa di sostituzione'
   CUR_DIR_IS__MSG =      'L''indirizzario corrente Š'
   EX_ALL__MSG =          'Eseguire tutte le righe marcate?'
   EX_ALL_YN__MSG =       'Eseguire tutte le stringhe marcate (S,N) ?'
   NEW_FILE__MSG =        'Nuovo file'
   BAD_PATH__MSG =        'Percorso non trovato'
   LINES_TRUNCATED__MSG = 'Righe troncate'
   ACCESS_DENIED__MSG =   'Accesso negato'
   INVALID_DRIVE__MSG =   'Unit… non valida'
   ERROR_OPENING__MSG =   'Errore apertura'
   ERROR_READING__MSG =   'Errore lettura'
   ECHO_IS__MSG =         'ECHO Š impostato a'  -- ON or OFF
   MULTIPLE_ERRORS__MSG = 'Errori durante il caricamento file. Vedere i messaggi riportati di seguito:'
   COMPILING__MSG =       'Compilazione di'  -- filename
              -- 'ETPM.EXE non ha potuto aprire il file temporaneo "'tempfile'"'
   CANT_OPEN_TEMP__MSG =  'non ha potuto aprire il file temporaneo'
   COMP_COMPLETED__MSG =  'Compilazione completata regolarmente'
   EXIT_PROMPT__MSG =     "Uscita senza salvataggio! "
   KEY_PROMPT1__MSG =     'Premere un tasto da ripetere. Premere Esc per annullare.'
                --  'Specificare il tasto da ripetere, come nel caso di "key 'number' =".'
   KEY_PROMPT2__MSG =     'Specificare il tasto da ripetere, come in'
   LOCKED__MSG =          'Il file Š bloccato. Usare il comando UNLOCK prima di cambiare nome al file.'
   ERROR_SAVING_HALT__MSG="Errore durante salvataggio file. Comando interrotto."
   HELP_TOP__MSG =        ' ----- Inizio schermo di aiuto -----'
   HELP_BOT__MSG =        ' ----- Fine schermo di aiuto -----'
   PRINTER_NOT_READY__MSG='La stampante non Š pronta'
   BAD_PRINT_ARG__MSG =   'Argomento non valido per PRINT.'
                  -- "Vi Š un'area contrassegnata in un altro file. Eliminare il contrassegno oppure editare" filename
   UNMARK_OR_EDIT__MSG =  'Eliminare marcatura oppure editare'
   PRINTING_MARK__MSG =   'Stampa del testo marcato'
   MACRO_HALTED__MSG =    'Macro interrotta dall''utente'
                -- filename 'non esiste'
   DOES_NOT_EXIST__MSG =  'non esiste'
   SAVED_TO__MSG =        'Salvato come'  -- filename
   IS_A_SUBDIR__MSG =     'Il nome richiesto Š quello di un sottoindirizzario.'
   READ_ONLY__MSG =       'Il file Š di solo lettura.'
   IS_SYSTEM__MSG =       'Il file ha l''attributo "sistema".'
   IS_HIDDEN__MSG =       'Il file ha l''attributo "nascosto".'
   MAYBE_LOCKED__MSG =    'Il file potrebbe essere bloccato da un''altra applicazione.'
   ONLY_VIEW__MSG =       'Questa Š la sola vista di questo file'

;; SLnohost.e
   INVALID_FILENAME__MSG= 'Nome file non valido.'
   QUIT_PROMPT1__MSG =    'Eliminare modifiche? Premere S, N oppure il tasto File'
   QUIT_PROMPT2__MSG =    'Eliminare modifiche? Premere S o N'
   PRESS_A_KEY__MSG =     'Premere un tasto...'
   LONGNAMES_IS__MSG =    'Il modo LONGNAMES Š'

compile if HOST_SUPPORT <> ''
;; SaveLoad.e
   BAD_FILENAME_CHARS__MSG = 'Caratteri nel nome file non previsti'
   LOADING_PROMPT__MSG =    'Caricamento di'  -- filename
   SAVING_PROMPT__MSG =     'Salvataggio di'  -- filename
   HOST_NOT_FOUND__MSG =    'File del sistema centrale non trovato.'
      --  'Errore 'rc' di sistema centrale; il salvataggio su sistema centrale Š stato annullato. Il file Š stato salvato in 'vTEMP_PATH'eeeeeeee.'hostfileid
   HOST_ERROR__MSG =        'Errore sistema centrale'
   HOST_CANCEL__MSG =       'salvataggio su sistema centrale annullato. File salvato in'
compile endif

compile if HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
;; E3Emul.e
   OVERLAY_TEMP1__MSG =     'Eseguendo il caricamento, il file temporaneo su PC verr… ricoperto - Si desidera continuare? (S,N)'
         -- Loading <filename> with <options>
   WITH__MSG =              'con'
   FILE_TRANSFER_ERROR__MSG ='Errore trasferimento file'  -- RC
   SAVED_LOCALLY_AS__MSG =  'Salvato su PC come'  -- filename
   SAVE_LOCALLY__MSG =      'Si desidera salvare questo file su PC? (S,N)'
   OVERLAY_TEMP2__MSG =     'esiste gi…. Premere S per ricoprire, N per interrompere.'
   OVERLAY_TEMP3__MSG =     'esiste gi…. Selezionare OK per ricoprire, Annullo per interrompere.'
   ALREADY_EDITING__MSG =   'E'' gi… in corso l''editazione di un file con questo nome - modifica negata'
   NO_SPACES__MSG =         'Non Š possibile usare spazi in un nome di file'
   LOOKS_VM__MSG =          'potrebbe essere un file VM, ma'  -- <filename> 'looked like VM, but' <one of the following:>
     NO_HOST_DRIVE__MSG =   'manca l''unit… del sistema centrale'
     HOST_DRIVELETTER__MSG = 'l''identificativo unit… di sistema centrale'  -- host drive specifier <X> <problem>
       IS_TOO_LONG__MSG =   'Š troppo lungo'
       INVALID__MSG =       'non Š valido'
     HOST_LT__MSG =         'l''identificativo terminale logico'  -- host logical terminal <X> invalid
     NO_LT__MSG =           'manca il terminale logico'
     FM__MSG =              'l''identificativo del disco' -- <X> is too long
     FM1_BAD__MSG =         'il primo carattere dell''identificativo del disco non Š alfabetico'
     FM2_BAD__MSG =         'il secondo carattere dell''identificativo del disco non Š numerico'
     NO_FT__MSG =           'manca l''identificativo del disco'
     FT__MSG =              'il tipo file' -- <X> is too long
     BAD_FT__MSG =          'il tipo file contiene caratteri non validi'  -- <filetype>
     FN__MSG =              'il nome file' -- <X> is too long
     BAD_FN__MSG =          'il nome file contiene caratteri non validi'  -- <filename>
   MVS_ERROR__MSG =         '(Errore MVS)'  -- followed by <one of the following:>
     DSN_TOO_LONG__MSG =    'Nome del data set pi— lungo di 44 caratteri'
                   --  'qualifier #' 1 '('XXXXXXXXX')' <problem>
     QUAL_NUM__MSG =        'il qualificatore n.'
       QUAL_TOO_LONG__MSG = 'Š pi— lungo di 8 caratteri'
       QUAL_INVALID__MSG =  'contiene un carattere non consentito'
     GENERATION_NAME__MSG = 'Il nome generazione'
     MEMBER__MSG =          'il membro'
     INVALID_MEMBER__MSG =  'il membro contiene caratteri non validi'
     DSN_PARENS__MSG =      'il DSN contiene parentesi ma non membro/generazione'
   LOOKS_PC__MSG =          'potrebbe essere un file PC, ma'  -- <filename> 'looked like PC, but' <one of the following:>
     PC_DRIVESPEC__MSG =    'l''identificativo di unit… PC'  -- PC drive specifier <X> <problem>
       LONGER_THAN_ONE__MSG = 'Š pi— lungo di 1 carattere'
       IS_NOT_ALPHA__MSG =  'non Š alfabetico'
     INVALID_PATH__MSG =    'non Š valido il percorso'  -- followed by <filename>
     INVALID_FNAME__MSG =   'non Š valido il nome file PC'  -- followed by <filename>
     INVALID_EXT__MSG =     'non Š valida l''estensione PC'  -- followed by <extension>
   SAVEPATH_NULL__MSG =     'SAVEPATH nullo - verr… usato l''indirizzario corrente.'
;        'Savepath attempting to use invalid' bad '- will use current directory.'
   SAVEPATH_INVALID1__MSG = 'Tentativo di Savepath di usare'
   SAVEPATH_INVALID2__MSG = '- verr… usato l''indirizzario corrente.'
   BACKUP_PATH_INVALID_NO_BACKSLASH__MSG= "BACKUP_PATH invalido manca '\' alla fine."
   NO_BACKUPS__MSG=         "le copie di Backup NON saranno salvate."
   BACKUP_PATH_INVALID1__MSG = 'il BACKUP_PATH che si sta cercando di usare Š invalido'
   DRIVE__MSG =             'un''unit… non valida'
   PATH__MSG =              'un percorso non valido'
   EMULATOR_SET_TO__MSG =   'Emulazione impostata a'
   LT_NOW__MSG =            '; (finestra 3270 attualmente = '
   EMULATOR__MSG =          'Emulazione'
   HOSTDRIVE_NOW__MSG =     'Unit… sistema centrale impostata a'
   IS_INVALID_OPTS_ARE__MSG = 'non valida. Le opzioni sono:'
   TRY_AGAIN__MSG =         'Riprovare'
   LT_SET_TO__MSG =         'Terminale logico impostato a'  -- set to A, to B, etc.
   LT_SET_NULL__MSG =       'Terminale logico impostato a NULL'
   LT_INVALID__MSG =        'non valida. Le opzioni sono: A-H,No_LT,NULL,NONE'  -- (bad) is...
   FTO_WARN__MSG =          'La correttezza delle opzioni per il trasferimento file NON viene verificata!'
   BIN_WARN__MSG =          'La correttezza delle opzioni per il trasferimento file in binario NON viene verificata!'
   FROM_HLLAPI__MSG =       'restituito da chiamata collegamento dinamico HLLAPI.'  -- Error nnn from...
   FILE_TRANSFER_CMD_UNKNOWN = 'comando di File transfer sconosciuto:'
compile endif

;; EPM_EA.e
   TYPE_TITLE__MSG =        'Tipo'  -- Title of a messagebox or listbox for file type
   NO_FILE_TYPE__MSG =      'Al file non corrisponde alcun tipo. Si desidera impostarne uno?'
   ONE_FILE_TYPE__MSG =     'Al file corrisponde il tipo seguente:'
   MANY_FILE_TYPES__MSG =   'Al file corrispondono i seguenti tipi:'
   CHANGE_QUERY__MSG =      'Si desidera modificarlo?'
   NON_ASCII_TYPE__MSG =    'Il tipo del file non Š costituito da dati ASCII.'
   NON_ASCII__MSG =         '<non ASCII>'  -- Comment in a list of otherwise ASCII strings
   SELECT_TYPE__MSG =       'Selezionare il tipo'
   SUBJ_TITLE__MSG =        'Oggetto'  -- Title of a messagebox or listbox for file subject
   NO_SUBJECT__MSG =        'Il file non ha alcun oggetto. Si desidera impostarne uno?'
   SUBJECT_IS__MSG =        'Il file ha l''oggetto seguente:'
   NON_ASCII_SUBJECT__MSG = "L'oggetto del file non Š costituito da dati ASCII."
   SELECT_SUBJECT__MSG =    'Immettere un oggetto.'
; Following is a list of standard values for .TYPE extended attribute, per OS/2 programming guide.
; Only translate if the .TYPE EA is NLS-specific.  First character is the delimiter between
; types; can be any otherwise-unused character.  (It's a '-' here.)
   TYPE_LIST__MSG =         '-Plain Text-OS/2 Command File-DOS Command File-C Code-Pascal Code-BASIC Code-COBOL Code-FORTRAN Code-Assembler Code-'

;; BOOKMARK.E
   NEED_BM_NAME__MSG =      'Nome segnalibro mancante.'
   NEED_BM_CLASS__MSG =     'Classe segnalibro mancante.'
   UNKNOWN_BOOKMARK__MSG =  'Segnalibro sconosciuto.'
   BM_NOT_FOUND__MSG =      'Segnalibro non trovato.'
   ITS_DELETED__MSG =       'E'' stato cancellato.'  -- 'Il segnalibro non Š stato trovato. E'' stato cancellato.'
   BM_DELETED__MSG =        'Segnalibro cancellato.'
   NO_BOOKMARKS__MSG =      'Nessun segnalibro collocato.'
   LIST_BOOKMARKS__MSG =    'Elenco segnalibri'  -- Listbox title
   DELETE_PERM_BM__MSG =    'Si desidera cancellare tutti i segnalibri permanenti?'  -- Are you sure?
   UNEXPECTED_ATTRIB__MSG = 'Valore non previsto nell''attributo esteso EPM.ATTRIBUTES'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   SET__MSG =               '~Collocare'
   SETP__MSG =              '~Permanente'
   GOMARK__MSG =            '~Andare al segnalibro'
   DELETEMARK__MSG =        '~Eliminare segnalibro'
   SETMARK__MSG =           'Collocare segnalibro'  -- Title
   SETMARK_PROMPT__MSG =    'Immettere un nome per la posizione corrente del cursore'
   RENAME__MSG =            'Rinominare'  -- Title
   NOTHING_ENTERED__MSG =   'Nessun dato immesso; funzione annullata.'
   NO_COMPILER_ERROR__MSG = 'Nessun errore trovato sulla riga corrente.'
   DESCRIBE_ERROR__MSG =    'Descrizione errore'  -- Listbox title
   DETAILS__MSG =           '~Dettagli'  -- Button
   SELECT_ERROR__MSG =      'Selezionare l''errore quindi Dettagli per maggiori informazioni.'
   NO_HELP_INSTANCE__MSG =  "Errore non previsto: nessun aiuto"
   ERROR_ADDING_HELP__MSG = 'cercando di aggiungere il file di aiuto'  -- 'Error' nn 'attempting to add help file' x.hlp
   ERROR_REVERTING__MSG =   'cercando di ritornare al file di aiuto'  -- 'Error' nn 'attempting to revert to help file' x.hlp
   BM_ALREADY_EXISTS__MSG = 'Esiste gi… un bookmark con quel nome.'
   LONG_EA_TITLE__MSG =     "EA's troppo lungo"  -- Messagebox title
   LONG_EA__MSG =           "Extended Attributes dovrebbero essere pi— di 64k; il file non pu• essere salvato. Remuovi alcuni stili e riprova."

;;;;;;;;;;;;;;;;;;;;;;;;;; stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   FILE_GONE__MSG =         'Il file non si trova pi— nel ciclo.'
   NO_RING__MSG =           'Ciclo disabilitato; impossibile aggiungere un altro file al ciclo di editazione.'
   NO_RING_CMD__MSG =       'Quando il ciclo Š disattivato non Š possibile usare il comando'  -- followed by command name
   RENAME_PROMPT__MSG =     'Immettere il nuovo nome per il file corrente'
   RX_PROMPT__MSG =         'Un nome di macro deve essere specificato come un parametro (e.g,, EPMREXX ERXMACRO)'
   RX_SUBCOM_FAIL__MSG =    'Registrazione sottocomando Rexx non riuscita -- RC'
   RX_FUNC_FAIL__MSG =      'Registrazione funzione Rexx non riuscita -- RC'
   MODIFIED_PROMPT__MSG =   'Current file has been modified. Save changes?'    ------------------------------------- to be translated ---------------------------------
   NOT_ON_DISK__MSG =       'does not exist on disk - can not proceed.'   -- Preceded by:  '"'filename'"'

; The following are used in key names, like 'Ctrl+O', 'Alt+Bkspc', etc.
; Note that some are abbreviated to take up less room on the menus.

   ALT_KEY__MSG =       'Alt'
   CTRL_KEY__MSG =      'Ctrl'
   SHIFT_KEY__MSG =     'Maius'
   INSERT_KEY__MSG =    'Ins'
   DELETE_KEY__MSG =    'Canc'
   BACKSPACE_KEY__MSG = 'Ritorno'
   ENTER_KEY__MSG =     'Invio'
   PADENTER_KEY__MSG =  'Invio (Tastierina numerica)'
   ESCAPE_KEY__MSG =    'Esc'
   UP_KEY__MSG =        'S—'
   DOWN_KEY__MSG =      'Gi—'

;;;;;;;;;;;;;;;;;;;;;;;;;;  New stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   MARK_OFF_SCREEN2__MSG =  "Hai un area marcata fuori dallo schermo."
   LINES_TRUNCATED_WNG__MSG = 'Una o pi— linee sono state spezzate alla colonna 255; il file pu• essere danneggiato se salvato.'
   DYNASPEL_NORECALL__MSG = 'Nessuna parola misspelled .'
;                         The following two combine to form one message.
   DYNASPEL_PROMPT1__MSG =  'La parola sconosciuta era was '
   DYNASPEL_PROMPT2__MSG =  ' - premi Ctrl+A per alternative.'
;                         The following two combine to form one message.
   PROOF_ERROR1__MSG =      'errore inaspettatoalla linea'
   PROOF_ERROR2__MSG =      '- salto alla prossima linea'

   STACK_FULL__MSG =        'Area di stack piena.'
   STACK_EMPTY__MSG =       'Area di Stack vuota.'
   TAGSNAME__MSG =          'nome file di Tags'     -- Entry box title
   TAGSNAME_PROMPT__MSG =   'Immetti il nome file per il tags file'
   FINDTAG__MSG =           'Trova la procedura'      -- Entry box title
   FINDTAG_PROMPT__MSG =    'Immetti il nome della procedura da trovare.'
   NO_TAGS__MSG =           'Non ho trovato Tags nel file tags.'
   LIST_TAGS__MSG =         'Lista delle tags'         -- Listbox title
   BUILDING_LIST__MSG =     'Sto creando la lista...'  -- Processing message
   LIST__MSG =              '~List...'               -- Button
   MAKETAGS__MSG =          'Crea tags file'
   MAKETAGS_PROMPT__MSG =   'Immetti uno o pi— nomi di file (wildcards OK) o @lists.'
   MAKETAGS_PROCESSING__MSG = 'MAKETAGS in elaborazione - controllo source files.'
   MESSAGELINE_FONT__MSG =  'font di Messageline cambiati'
   MESSAGELINE_FGCOLOR__MSG = 'colori di foreground Messageline cambiati.'
   MESSAGELINE_BGCOLOR__MSG = 'colori di background Messageline cambiati.'
   TABGLYPH_IS__MSG =       'TABGLYPH Š' -- on/off

;  NO_TOOLBARS__MSG =       'Non ci sono toolbars salvate da selezionare.'
;  LOAD_TOOLBAR__MSG =      'Carica Toolbar'  -- Dialog box title
;  DELETE_TOOLBAR__MSG =    'Rimuovi Toolbar'  -- Dialog box title
;  SELECT_TOOLBAR__MSG =    'Seleziona un set di men— Toolbar'
   SAVEBAR__MSG =           'Salva Toolbar'  -- Dialog box title
;  SAVEBAR_PROMPT__MSG =    'Immetti un nome, o lascia blank per salvare come default.'
   SAVEBAR_PROMPT__MSG =    'Immetti un nome per la toolbar.'
   SAVE__MSG =              'Salva'          -- Dialog button
   WILDCARD_WARNING__MSG =  'il Filename contiene dei caratteri wildcards.'  -- followed by ARE_YOU_SURE__MSG

;; ASSSIST.E
   NOT_BALANCEABLE__MSG =   'Non Š un carattere bilanciabile.'
   UNBALANCED_TOKEN__MSG =  'Unbalanced token.'

   WIDE_PASTE__MSG =        'Pasted text is wider than margins. Reflow?'

