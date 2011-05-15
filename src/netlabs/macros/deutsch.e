/****************************** Module Header *******************************
*
* Module Name: deutsch.e
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

;     NLS_LANGUAGE = 'DEUTSCH'

const

; Now uses only 1 additional const for compile-ifs: HOST_SUPPORT
compile if not defined(HOST_SUPPORT)
   HOST_SUPPORT = 0
compile endif

;; Box.e  -- Try to keep P, C, A, E, R & S the same; otherwise requires macro changes
   BOX_ARGS__MSG =        'Argm.: 1=� 2=� 3=| 4=� 5=� 6=� B=Leer /Alle P=Pas C=C A=Asm E=Entf R=Ausrichten S=Scr'
   BOX_MARK_BAD__MSG =    'Markierter Bereich ist nicht in einem Rahmen'

;; Buff.e
   CREATEBUF_HELP__MSG =  ' CREATEBUF  erstellt EBUF Puffer; "CREATEBUF 1" f�r pers�nlichen Puffer.'
   PUTBUF_HELP__MSG =     ' PUTBUF     stellt Datei, von akt. Zeile bis Ende, in den Puffer.'
   GETBUF_HELP__MSG =     ' GETBUF     f�gt den Inhalt des Puffers in Datei ein.'
   FREEBUF_HELP__MSG =    ' FREEBUF    gibt den Puffer frei.'
   ERROR_NUMBER__MSG =    'Fehlernummer'
   EMPTYBUF_ERROR__MSG =  'Puffer ist leer, keine Daten verf�gbar.'
                  --      'Got' number 'bytes from a' number'-byte buffer'  number 'lines'
   GOT__MSG =             'Erhalten wurden'
   BYTES_FROM_A__MSG =    'Byte aus einem'
   PUT__MSG =             'Gestellt wurden'
   BYTES_TO_A__MSG =      'Byte in einen'
   BYTE_BUFFER__MSG =     '-Byte-Puffer'
   CREATED__MSG =         'Ist erstellt.'
   FREED__MSG =           'Ist freigegeben.'
   MISSING_BUFFER__MSG =  'Es mu� ein Puffername angegeben werden.'
             --      'Buffer overflow?  It accepted only' noflines 'lines.'
   ONLY_ACCEPTED__MSG =   'Puffer�berlauf? Aufgenommen wurden nur'
   CAN_NOT_OPEN__MSG =    'Folgender Puffer konnte nicht ge�ffnet werden:'

;; Clipbrd.e
   NO_MARK_NO_BUFF__MSG = 'Kein markierter Bereich vorhanden, gemeinsamer Puffer ist leer.'
   CLIPBOARD_EMPTY__MSG = 'Die Zwischenablage ist leer'
   CLIPBOARD_ERROR__MSG = 'Fehler beim Lesen der Zwischenablage'
   NOTHING_TO_PASTE__MSG ='Kein Text zum Einf�gen vorhanden.'
   TRYING_TO_FREE__MSG =  'versucht, folgenden Puffer freizugeben: alten'
   BUFFER__MSG =          'Puffer'
   NO_MARK_DELETED__MSG = 'Keine Markierung wurde aus diesem Fenster gel�scht.'
   NO_TEST_RECOVERED__MSG='Kein Text wurde wiederhergestellt.'
   ERROR_COPYING__MSG =   'Fehler beim Kopieren von'
   ONLY__MSG =            'Nur'
   LINES_OF__MSG =        'Zeile(n) des Originals'
   RECOVERED__MSG =       'wurde(n) wiederhergestellt.'
   TOO_MUCH_FOR_CLIPBD__MSG= 'Markierung zu gro� f�r den Puffer der Zwischenablage.'
   CLIPBOARD_VIEW_NAME =  '.Clipboard'  -- file name; initial '.' marks it as a temp file

;; Modify.e
   AUTOSAVING__MSG =      'Es wird automatisch gesichert ...'

;; Mouse.e
   UNKNOWN_MOUSE_ERROR__MSG = "Unbekannter Verarbeitungsfehler f�r Maus: "

;; Dosutil.e
   TODAY_IS__MSG =        'Systemdatum ist:'
   THE_TIME_IS__MSG =     'Systemzeit ist'
   MONTH_LIST =           'Januar   Februar  M�rz     April    Mai      '||
                          'Juni     Juli     August   SeptemberOktober  '||
                          'November Dezember '
   MONTH_SIZE = 9     -- Length of the longest month name
   WEEKDAY_LIST =         'So.Mo.Di.Mi.' ||
                          'Do.Fr.Sa.So.'
   WEEKDAY_SIZE = 3   -- length of the longest weekday name
   AM__MSG = 'am'
   PM__MSG = 'pm'
   ALT_1_LOAD__MSG =      'Cursor zur gew�nschten Datei bewegen u. Alt-1 dr�cken, um Datei zu laden.'
   ENTER_CMD__MSG =       'OS/2-Befehl eingeben'

;; Draw
   ALREADY_DRAWING__MSG = 'Zeichenmodus bereits aktiv. Befehl wird ignoriert.'
   DRAW_ARGS__MSG =       'G�ltige Argm.:  1=�  2=�  3=|  4=�  5=�  6=�  B=Leer od.  /gew. Zeichen'
   DRAW_ARGS_DBCS__MSG =  'G�ltige Argm.:  1='\5'  2=|  3='\11'  4='\14'  5='\20'  6='\26'  B=Leer od.  /gew. Zeichen'
   DRAW_PROMPT__MSG =     'Zeichenmodus:  '\27' '\26' '\24' '\25'  zum Zeichnen;'||
                          ' Einfg zum Heben des Stifts; Esc oder Eingabe zum Beenden.'
   DRAW_ENDED__MSG =      'Zeichenmodus beendet'

;; Get.e
   NO_FILENAME__MSG =     'Es wurde kein Dateiname angegeben f�r'
   INVALID_OPTION__MSG =  'Ung�ltige Option'
   FILE_NOT_FOUND__MSG =  'Datei nicht gefunden'
   FILE_IS_EMPTY__MSG =   'Datei ist leer'
   NOT_2_COPIES__MSG =    'Nicht gen�gend Arbeitsspeicher f�r zwei Kopien von'

;; Main.e
;;   The following name starts with a '.' to indicate that it's a temporary file:
;; UNNAMED_FILE_NAME =    '.Unnamed file'  -- Not any more; now:
   UNNAMED_FILE_NAME =    '.Ohne Namen'

;; Mathlib.e
   SYNTAX_ERROR__MSG =    'Syntaxfehler'

;; Put.e
   NO_CONSOLE__MSG =      'Sichern von einem PM-Fenster aus zur Konsole nicht m�glich.'
   MARK_APPENDED__MSG =   'Markierter Text geschrieben in'

;; Sort.e
                  --      'Sorting' number 'lines'
   SORTING__MSG =         'Sortiert werden'
   LINES__MSG =           'Zeilen'
   NO_SORT_MEM__MSG =     'Nicht gen�gend Arbeitsspeicher! Sortierte Zeilen konnten nicht eingef�gt werden; Datei wurde nicht ge�ndert.'

;; Charops.e
   CHAR_ONE_LINE__MSG =   'Zeichenmarkierungen m�ssen in derselben Zeile beginnen und enden.'
   PFILL_ERROR__MSG =     'Fehler in PFill_Mark'
   TYPE_A_CHAR__MSG =     'Zeichen eingeben'
   ENTER_FILL_CHAR__MSG = 'F�llzeichen eingeben:'
   FILL__MSG =            'Fill'  -- Title
   NO_CHAR_SUPPORT__MSG = 'Unterst�tzung f�r Zeichenmarkierungen wurde �bergangen.'

;; Exit.e
   ABOUT_TO_EXIT__MSG =   'E wird verlassen. '

;; Linkcmds.e
   LINK_COMPLETED__MSG =  'Link abgeschlossen, Modul Nr.'
   QLINK_PROMPT__MSG =    'Geben Sie einen Modulnamen an wie in "qlink name".'
   NOT_LINKED__MSG =      'ist nicht durch Link geladen'
   CANT_FIND1__MSG =      "Modul"  -- sayerror "Can't find "module" on disk!"
   CANT_FIND2__MSG =      "auf Datentr�ger nicht auffindbar!"
   LINKED_AS__MSG =       'ist durch Link geladen als Modul Nr.' -- sayerror module' is linked as module # 'result'.'
   UNABLE_TO_LINK__MSG =  'Folgender Link kann nicht hergestellt werden:'
   UNABLE_TO_EXECUTE__MSG='Folgender Befehl kann nicht ausgef�hrt werden:'

;; Math.e
   NO_NUMBER__MSG =       "Keine Zahl gefunden (von Cursorposition bis Dateiende)"

;; Stdcnf.e
   STATUS_TEMPLATE__MSG = 'Zeile %l von %s   Spalte %c  %i   %m   %f   '
   DIR_OF__MSG =          'Verzeichnis von'  -- Must match what DIR cmd outputs!

;; Window.e
   ZOOM_PROMPT__MSG =     'Der aktuelle Zoom-Fensterstand ist'
   CHOICES_ARE__MSG =     'Die Auswahlm�glichkeiten sind'
   DRAG__MSG =            'Mit den Pfeiltasten das Fenster ziehen. Danach EINGABE oder ESC dr�cken'
                -- 'DRAG' MESSY_ONLY__MSG  or 'SIZE' MESSY_ONLY__MSG
   MESSY_ONLY__MSG =      'kann nur bei �berlappenden Fenstern verwendet werden'

;; Shell.e
   INVALID_ARG__MSG =     'Ung�ltige Argumente'

;; Sort.e       -- 'Sort:  Put 'noflines' lines in buffer, got 'noflinesback' lines back.'
                -- 'Sort:' PUT__MSG noflines SORT_ERROR1__MSG noflinesback SORT_ERROR2__MSG
   SORT_ERROR1__MSG =    'Zeilen in den Puffer, zur�ckgeholt wurden'
   SORT_ERROR2__MSG =    'Zeilen.'

;; Retrieve.e
   CMD_STACK_CLEAR__MSG= 'Befehlspuffer gel�scht.'
   CMD_STACK_EMPTY__MSG= 'Befehlspuffer ist leer.'

;; Help.e
   HELP_BROWSER__MSG =   'Anzeigeprogramm - Hilfe'
   HELP_STATUS__MSG =    ' G�ltige Tasten -> Bild,Bild       F3,ESC=Hilfefenster schlie�en'
   NO_DROP__MSG =        'Dateien k�nnen hier nicht �bergeben werden.'
   SYS_ED__MSG =         'Systemeditor - Warnung!'
   SYS_ED1__MSG =        'Also wirklich, warum sollten Sie'\10'so etwas tun wollen?'
             -- 'Error' err_no 'allocating memory segment; command halted.'
   ALLOC_HALTED__MSG =   'bei Zuordnung von Speichersegment; Befehl beendet.'
   QUICK_REF__MSG =      'Info-�berblick'  -- Window title

;; All.e
   NO_ALL_FILE__MSG =    '.ALL-Datei nicht in der Umlaufliste.'
   BAD_ALL_LINE__MSG =   'Fehlende oder ung�ltige Zeilennummer in der .ALL-Datei.'

;; Eos2lex.e
   EOS2LEX_PROMPT1__MSG = 'Leertaste=Anzeigen der Liste     Esc=Weiter     F3 oder F10=Stop'
   SPELLED_OK__MSG =      'Wort ist korrekt geschrieben'
                -- Limit the following to 80 characters.
   EOS2LEX_PROMPT2__MSG = 'Esc=Weiter   F4=Hinzuf�gen   F5=Temp hzfg.    F8=globale �nderung   F3, F10=Abbruch'
   MORE__MSG =            'weiter'
   NO_MATCH__MSG =        'Kein Wort entspricht'  -- 'No words match' spellword
   EXIT_SPELL__MSG =      'Rechtschreibpr�fung beenden (J/N)?'
   THINKING__MSG =        'denke nach ...'
   DONE__MSG =            'Pr�fung abgeschlossen.'
   NO_SYN__MSG =          'Keine bekannten Synonyme f�r' -- word
   BAD_DICT__MSG =        'W�rterverzeichnis enth�lt einen Fehler.'
   INIT_ERROR__MSG =      'Initialisierungsfehler.'
                     -- 'Error loading addenda' addenda_filename
   BAD_ADDENDA__MSG =     'Fehler beim Laden der Addendadatei'

;; Shell.e           -- 'Fehler' rc 'beim Erstellen des Shellobjekts.'
   SHELL_ERROR1__MSG =    'erstellt Shellobjekt.'
   SHELL_ERROR2__MSG =    'erstellt Editierdatei f�r die Shell.'
   NOT_IN_SHELL__MSG =    'Befindet sich nicht in einer Befehlsshelldatei.'
   SHELL_ERROR3__MSG =    'schlie�t die Shell.'
                     -- 'Enter text to be written to shell' shell_number
   SHELL_PROMPT__MSG =    'Geben Sie den Text ein f�r Shell'
                     -- 'shell object' number 'is willing to accept more data...'
   SHELL_OBJECT__MSG =    'Shellobjekt'
   SHELL_READY__MSG =     'ist zur Aufnahme weiterer Daten bereit ...'

;; Stdprocs.e
   ARE_YOU_SURE_YN__MSG = '  Sind Sie sicher (J/N)? '  -- Keep spaces
   ARE_YOU_SURE__MSG =    'Sind Sie sicher?'
   YES_CHAR =             'J'  -- First letter of Yes
   NO_CHAR =              'N'  -- First letter of No
   NO_MARK__MSG =         'Kein Bereich markiert'
   NO_MARK_HERE__MSG =    'Kein markierter Bereich im aktuellen Fenster'
   ERROR__MSG =           'Fehler'
   ERROR_LOADING__MSG =   'Fehler beim Laden von'  -- filename
   NOT_LOCKED__MSG =      '- Datei nicht gesperrt.'
   CHAR_INVALID__MSG =    'Zeichenmarkierung ung�ltig.'
   INVALID_NUMBER__MSG =  'Ung�ltiges Zahlenargument'
   CANT_FIND_PROG__MSG =  "Folgendes Programm kann nicht gefunden werden:"  -- progname
   NO_FLOAT__MSG =        'Gleitkommazahl unzul�ssig:' -- number
   NEED_BLOCK_MARK__MSG = 'Blockmarkierung erforderlich'  -- (New 1991/10/08)  -- NLS-TODO
               -- Error <nn> editing temp file:  <error_message>
   BAD_TMP_FILE__MSG =    'beim Bearbeiten der tempor�ren Datei:'

;; Stdctrl.e
   BUTTON_ERROR__MSG =    'Fehler - Druckknopf'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   ENTER__MSG =           '~Eingabe'
   OK__MSG =              '~OK'
   CANCEL__MSG =          'Abbruch'
   SELECT__MSG =          '~Ausw�hlen'
   HELP__MSG =            'Hilfe'
   FONTLIST_PROMPT__MSG = 'Schriftartgr��e (Breite x H�he); akt. ='
   TO_LARGE_FONT__MSG =   'Wechseln zur gro�en ~Schriftart'  -- Tilde must be before a character
   TO_SMALL_FONT__MSG =   'Wechseln zur kleinen ~Schriftart'  -- that's the same in both messages
   EXISTS_OVERLAY__MSG =  'Die angegebene Datei existiert bereits. �berschreiben?'
   NO_SLASH__MSG =        'Der Fenstertext des Ordners war die obige Zeichenfolge; ein "\" wurde nicht gefunden.'
   LISTING__MSG =         'Liste wird erstellt ...'
   ONLY_FILE__MSG =       'Dies ist die einzige Datei in der Umlaufliste.'
   TOO_MANY_FILES__MSG =  "Zu viele Dateien"
   NOT_FIT__MSG =         'Es w�rden nicht alle Dateinamen in den Puffer mit der maximalen Gr��e passen.'
   FILES_IN_RING__MSG =   'Dateien in der Umlaufliste'  -- This is a listbox title
   UNEXPECTED__MSG =      'Fehler - unvorhergesehenes Ergebnis.'
   PROCESS_ERROR__MSG =   'Fehler bei der Ausf�hrung der Funktion mit ID'
   MENU_ERROR__MSG =      'Fehler im aktiven Men�'
   REFLOW_ALL__MSG =      'Soll der gesamte Text nach den neuen R�ndern ausgerichtet werden?'
   SAVE_AS__MSG =         'Sichern unter'
   LIST_TOO_BIG__MSG =    'Liste zu gro�; nicht alle Eintr�ge werden angezeigt.'

; Before 5.21, we didn't have accelerator keys, so we didn't want the Tilde to
; appear on the action bar.
   TILDE_CHAR = '~'

; Lots of fun here.  This is the editor's action bar.  xxx_BAR__MSG means xxx is on the
; action bar.  yyy_MENU__MSG means that yyy is on a pull-down or pull-right.  The tildes
; precede the accelerator letter; those letters must be unique in each group (pulldown
; or pullright).  Followed by a 'P' means it's the dynamic help prompt for that BAR or
; MENU item.  Note that each prompt must start with \1.
   FILE_BAR__MSG =        '~Datei '
     NEW_MENU__MSG =        '~Neu'
     OPEN_MENU__MSG =       '~�ffnen ...'
     OPEN_NEW_MENU__MSG =   '.~Ohne Namen �ffnen'
     GET_MENU__MSG =        '~Textdatei einf�gen ...'
     ADD_MENU__MSG =        'D~atei hinzuf�gen ...'
     RENAME_MENU__MSG =     '~Umbenennen ...'
     SAVE_MENU__MSG =       '~Sichern'
     SAVEAS_MENU__MSG =     'Si~chern unter ...'
     FILE_MENU__MSG =       'S~ichern und verlassen'
     SAVECLOSE_MENU__MSG =  'S~ichern und schlie�en'
     QUIT_MENU__MSG =       '~Verlassen'
     PRT_FILE_MENU__MSG =   'Datei d~rucken'

   FILE_BARP__MSG =        \1'Men�s f�r Operationen mit Dateien'
     NEW_MENUP__MSG =        \1'Aktuelle Datei mit einer leeren Datei ohne Namen ersetzen'
     OPEN_NEW_MENUP__MSG =   \1'�ffnen eines neuen, leeren Editierfensters'
     OPEN_MENUP__MSG =       \1'�ffnen einer Datei in einem neuen Fenster'
     GET_MENUP__MSG =        \1'Kopieren einer bestehenden Datei in aktuelle Datei'
     ADD_MENUP__MSG =        \1'Laden einer neuen Datei in dieses Fenster'
     RENAME_MENUP__MSG =     \1'�ndern des Namens dieser Datei'
     SAVE_MENUP__MSG =       \1'Sichern dieser Datei'
     SAVEAS_MENUP__MSG =     \1'�ndern des Dateinamens und Sichern der Datei unter neuem Namen'
     FILE_MENUP__MSG =       \1'Sichern der Datei und anschlie�end verlassen'
     QUIT_MENUP__MSG =       \1'Verlassen der Datei'
     ENHPRT_FILE_MENUP__MSG =\1'Anzeigen des Fensters "Drucken"'
     PRT_FILE_MENUP__MSG =   \1'Drucken der Datei auf dem Standarddrucker'

   EDIT_BAR__MSG =        '~Editieren '
     UNDO_MENU__MSG =       '~Zeile widerrufen'
     UNDO_REDO_MENU__MSG =  '~Widerrufen ...'
     STYLE_MENU__MSG =      'S~til ...'
     COPY_MARK_MENU__MSG =  '~Kopieren'
     MOVE_MARK_MENU__MSG =  '~Verschieben'
     OVERLAY_MARK_MENU__MSG='~�berlagern'
     ADJUST_MARK_MENU__MSG= 'Ver~setzen'
     COPY_MRK_MENU__MSG =   '~Kopieren'
     MOVE_MRK_MENU__MSG =   '~Verschieben'
     OVERLAY_MRK_MENU__MSG= '~�berlagern'
     ADJUST_MRK_MENU__MSG=  'Ver~setzen'
     UNMARK_MARK_MENU__MSG= '~Markierung aufheben'
     DELETE_MARK_MENU__MSG= '~L�schen'
     DELETE_MENU__MSG=      '~L�schen'
     PUSH_MARK_MENU__MSG =  'Markierung speichern'
     POP_MARK_MENU__MSG =   'Markierung zur�ckholen'
     SWAP_MARK_MENU__MSG =  'Markierung tauschen'
     PUSH_MRK_MENU__MSG =   'Speichern'
     POP_MRK_MENU__MSG =    'Zur�ckholen'
     SWAP_MRK_MENU__MSG =   'Tauschen'
     PUSH_CURSOR_MENU__MSG ='Cursorposition speichern'
     POP_CURSOR_MENU__MSG = 'Cursorposition aufsuchen'
     SWAP_CURSOR_MENU__MSG= 'Cursor tauschen'
     CLIP_COPY_MENU__MSG =  '~In Zwischenablage kopieren'
     CUT_MENU__MSG =        '~Ausschneiden'
     PASTE_C_MENU__MSG =    '~Einf�gen'
     PASTE_L_MENU__MSG =    'Zeilen ein~f�gen'
     PASTE_B_MENU__MSG =    '~Block einf�gen'
     PRT_MARK_MENU__MSG =   'Markierten Te~xt drucken'
     RECOVER_MARK_MENU__MSG='~Gel�schten Text wiederherstellen'

   EDIT_BARP__MSG =        \1'Men�s f�r Widerrufen, Markierungen und Operationen mit Zwischenablage'
     UNDO_MENUP__MSG =       \1'Widerrufen von �nderungen in der aktuellen Zeile'
     UNDO_REDO_MENUP__MSG =  \1'Schrittweises Widerrufen von �nderungen'
     STYLE_MENUP__MSG =      \1'�ndern des Stils f�r markierten Text oder Registrieren eines Stils'
     COPY_MARK_MENUP__MSG =  \1'Kopieren des markierten Texts an die Cursorposition'
     MOVE_MARK_MENUP__MSG =  \1'Verschieben des markierten Texts an die Cursorposition'
     OVERLAY_MARK_MENUP__MSG=\1'�berlagern von Text an der Cursorposition mit dem markierten Text'
     ADJUST_MARK_MENUP__MSG= \1'�berlagern mit markiertem Text und Markierung mit Leerzeichen f�llen'
     UNMARK_MARK_MENUP__MSG= \1'Aufheben der Markierung'
     DELETE_MARK_MENUP__MSG= \1'L�schen des markierten Bereichs'
     PUSH_MARK_MENUP__MSG =  \1'Sichern der Markierungsbegrenzungen im Stapelspeicher'
     POP_MARK_MENUP__MSG =   \1'Wiederherstellen der gespeicherten Markierung'
     SWAP_MARK_MENUP__MSG =  \1'Tauschen der aktuellen Markierung gegen Stapelspeicherangabe'
     PUSH_CURSOR_MENUP__MSG =\1'Sichern der Cursorposition in einer Datei im Stapelspeicher'
     POP_CURSOR_MENUP__MSG = \1'Bewegen des Cursors an die gespeicherte Position in der Datei'
     SWAP_CURSOR_MENUP__MSG= \1'Tauschen der aktuellen Cursorposition gegen Stapelspeicherangabe'
     CLIP_COPY_MENUP__MSG =  \1'Kopieren von markiertem Text in die Zwischenablage'
     CUT_MENUP__MSG =        \1'Kopieren von markiertem Text in Zwischenablage und L�schen aus Datei'
     PASTE_C_MENUP__MSG =    \1'Einf�gen des Textes in der Zwischenablage als Zeichenmarkierung'
     PASTE_L_MENUP__MSG =    \1'Einf�gen des Textes in der Zwischenablage als Zeilenmarkierung'
     PASTE_B_MENUP__MSG =    \1'Einf�gen des Textes in der Zwischenablage als Blockmarkierung'
     ENHPRT_MARK_MENUP__MSG =\1'Anzeigen des Fensters "Drucken", um den markierten Text zu drucken'
     PRT_MARK_MENUP__MSG =   \1'Drucken von markiertem Text auf dem Standarddrucker'
     RECOVER_MARK_MENUP__MSG=\1'Einf�gen von Kopie des zuletzt gel�schten markierten Textes nach Cursor'

   SEARCH_BAR__MSG =      '~Suchen '
     SEARCH_MENU__MSG =     '~Suchen ...'
     FIND_NEXT_MENU__MSG =  'N�chste Stelle s~uchen'
     CHANGE_NEXT_MENU__MSG= 'N�chste Stelle ~�ndern'
     BOOKMARKS_MENU__MSG =  '~Lesezeichen'     -- Pull-right
       SET_MARK_MENU__MSG =   '~Einf�gen ...'
       LIST_MARK_MENU__MSG =  '~Auflisten ...'
       NEXT_MARK_MENU__MSG =  '~N�chstes'
       PREV_MARK_MENU__MSG =  '~Voriges'
     TAGS_MENU__MSG =       '~Tags'          -- Pull-right
       TAGSDLG_MENU__MSG =    '~Tags-Dialogfenster ...'
       FIND_TAG_MENU__MSG =   '~Aktuelle Prozedur suchen'
       FIND_TAG2_MENU__MSG =  '~Prozedur suchen ...'
       TAGFILE_NAME_MENU__MSG='Tags-Datei-~Name ...'
       MAKE_TAGS_MENU__MSG =  '~Erstelle Tags-Datei ...'
       SCAN_TAGS_MENU__MSG =  'Aktuelle Datei ~durchsuchen ...'

   SEARCH_BARP__MSG =      \1'Men�s f�r das Suchen und �ndern von Text und die Verwendung von Lesezeichen'
     SEARCH_MENUP__MSG =     \1'Anzeigen des Fensters "Suchen"'
     FIND_NEXT_MENUP__MSG =  \1'Wiederholen des vorigen Suchbefehls'
     CHANGE_NEXT_MENUP__MSG= \1'Wiederholen des vorigen �nderungsbefehls'
     BOOKMARKS_MENUP__MSG=   \1'Untermen�fenster f�r die Verwendung von Lesezeichen'
     SET_MARK_MENUP__MSG =   \1'Einf�gen eines Lesezeichen an der Cursorposition'
     LIST_MARK_MENUP__MSG =  \1'Auflisten d. Lesezeichen, um sie aufzusuchen o. aus Liste zu l�schen'
     NEXT_MARK_MENUP__MSG =  \1'Aufsuchen des n�chsten Lesezeichens in der Datei'
     PREV_MARK_MENUP__MSG =  \1'Aufsuchen des vorigen Lesezeichens in der Datei'
     TAGS_MENUP__MSG =       \1'Untermen� f�r die Verwendung einer "Tags-"Datei'
     TAGSDLG_MENUP__MSG =    \1'Aktivieren des Tags-Dialogfensters'
     FIND_TAG_MENUP__MSG =   \1'Aufsuchen der Definition des Prozedurnamens unter dem Cursor'
     FIND_TAG2_MENUP__MSG =  \1'Aufsuchen der Definition f�r einen anzugebenden Prozedurnamen'
     TAGFILE_NAME_MENUP__MSG=\1'�berp�fen oder �ndern des Namens einer Tags-Datei'
     MAKE_TAGS_MENUP__MSG =  \1'Erstellen oder Erneuern eine Tags-Datei'
     SCAN_TAGS_MENUP__MSG =  \1'Durchsuchen der aktuellen Datei nach Prozeduren & Anzeigen einer Ergebnisliste'

   OPTIONS_BAR__MSG         = '~Optionen '
     LIST_FILES_MENU__MSG     = '~Umlaufliste ...'
     FILE_LIST_MENU__MSG      = '~Dateiliste ...'
     PROOF_MENU__MSG          = '~Pr�fen'
     PROOF_WORD_MENU__MSG     = '~Wort pr�fen'
     DYNASPELL_MENU__MSG      = '~Automatische Rechtschreibpr�fung'
     SYNONYM_MENU__MSG        = '~Synonym'
     DEFINE_WORD_MENU__MSG    = 'Wort ~definieren'
     PREFERENCES_MENU__MSG    = '~Anpassung'   -- this is a pull-right; next few are separate group.
       CONFIG_MENU__MSG         = 'Einstellun~gen ...'
       SETENTER_MENU__MSG       = 'Eingabetaste ~belegen ...'
       ADVANCEDMARK_MENU__MSG   = '~Erweiterter Markierungsmodus'
       STREAMMODE_MENU__MSG     = '~Datenstrommodus'
       RINGENABLED_MENU__MSG    = '~Umlauffunktion'
       STACKCMDS_MENU__MSG      = 'Sta~pelspeicherbefehle'
       CUAACCEL_MENU__MSG       = '~CUA Direktaufruf'
     AUTOSAVE_MENU__MSG       = 'Auto~matisches Sichern ...'
     MESSAGES_MENU__MSG       = '~Nachrichten ...'
     CHANGE_FONT_MENU__MSG    = 'Schriftart ~�ndern ...'
     SMALL_FONT_MENU__MSG     = 'Kleine ~Schriftart'
     LARGE_FONT_MENU__MSG     = 'Gro�e ~Schriftart'
     FRAME_CTRLS_MENU__MSG    = '~Fenstereinstellung'  -- this is a pull-right; next few are separate group.
       STATUS_LINE_MENU__MSG    = '~Statuszeile'
       MSG_LINE_MENU__MSG       = '~Nachrichtenzeile'
       SCROLL_BARS_MENU__MSG    = 'Schiebe~leisten'
       FILEICON_MENU__MSG       = '~Dateisymbol'
       ROTATEBUTTONS_MENU__MSG  = '~Umlaufkn�pfe'
       TOOLBAR_MENU__MSG        = '~Funktionsleiste'
       TOGGLETOOLBAR_MENU__MSG  = '~Funktionsleiste'  -- Was 'Toggle'; the other 3 not used any more.
       LOADTOOLBAR_MENU__MSG    = '~Laden ...'
       DELETETOOLBAR_MENU__MSG  = 'L~�schen ...'
       TOGGLEBITMAP_MENU__MSG   = '~Hintergrund-Bitmap'
       INFOATTOP_MENU__MSG      = '~Infozeile(n) oben'
       PROMPTING_MENU__MSG      = '~Men�kurzinfo'
     SAVE_OPTS_MENU__MSG      = '~Optionen sichern'
     TO_BOOK_MENU__MSG        = '~Buchsymbol'

   OPTIONS_BARP__MSG         = \1'Men�s f�r Rechtschreibpr�fung und Editorkonfiguration'
     LIST_FILES_MENUP__MSG     = \1'Anzeigen der Dateien in der Umlaufliste'
     PROOF_MENUP__MSG          = \1'Aufrufen der Rechtschreibpr�fung f�r die Datei'
     PROOF_WORD_MENUP__MSG     = \1'Pr�fen der Rechtschreibung des Wortes am Cursor'
     SYNONYM_MENUP__MSG        = \1'Anzeigen eines Synonymvorschlags f�r das Wort am Cursor'
     DYNASPELL_MENUP__MSG      = \1'Ein- und Ausschalten der automatischen Rechtschreibpr�fung'
     DEFINE_WORD_MENUP__MSG    = \1'Anzeigen der Definition des Wortes am Cursor im Standardw�rterverzeichnis'
     PREFERENCES_MENUP__MSG    = \1'Anzeigen eines Untermen�s zur Anpassung des Editors'
       CONFIG_MENUP__MSG         = \1'Anzeigen der Editoreinstellungen f�r eventuelle �nderungen'
       SETENTER_MENUP__MSG       = \1'Konfigurieren der Eingabetaste und ihrer Kombinationen'
       ADVANCEDMARK_MENUP__MSG   = \1'Umschalten zw. Basismarkierungsmodus u. erw. Markierungsmodus'
       STREAMMODE_MENUP__MSG     = \1'Umschalten zwischen Datenstrommodus und Zeilenmodus'
       RINGENABLED_MENUP__MSG    = \1'(In)Aktivieren d. Umlauffkt.; Aktiv: mehrere Dateien in Fenster'
       STACKCMDS_MENUP__MSG      = \1'Aktivieren/Inaktivieren der Befehle zum Speichern oder Wiederholen'
       CUAACCEL_MENUP__MSG       = \1'CUA Direktaufruf aktiv/inaktive (Alt+Buchstabe = Wechsel zur Men�leiste)'
     AUTOSAVE_MENUP__MSG       = \1'Abfragen d. Werte/Anzeigen d. Verzeichnisses f. automat. Sichern'
     MESSAGES_MENUP__MSG       = \1'Anzeigen fr�herer Nachrichten'
     CHANGE_FONT_MENUP__MSG    = \1'�ndern der Schriftart'
     CHANGE_MARKFONT_MENUP__MSG= \1'�ndern des Schriftstils f�r markierten Text'
     SMALL_FONT_MENUP__MSG     = \1'�ndern in die kleine Schriftart'
     LARGE_FONT_MENUP__MSG     = \1'�ndern in die gro�e Schriftart'
     FRAME_CTRLS_MENUP__MSG    = \1"Anzeigen eines Untermen�s zur Anpassung von Einrichtungen des Editierfensters"
       STATUS_LINE_MENUP__MSG    = \1'Ein- und Ausschalten der Statuszeilenanzeige'
       MSG_LINE_MENUP__MSG       = \1'Ein- und Ausschalten der Nachrichtenzeilenanzeige'
       SCROLL_BARS_MENUP__MSG    = \1'Ein- und Ausschalten der Schiebeleistenfunktion'
       FILEICON_MENUP__MSG       = \1'Ein- und Ausschalten des Dateisymbols zum Ziehen und �bergeben'
       ROTATEBUTTONS_MENUP__MSG  = \1'Ein- und Ausblenden der Umlaufkn�pfe'
       TOOLBAR_MENUP__MSG        = \1'Anzeigen eines Untermen�s zur Anpassung der Funktionsleiste'
         TOGGLETOOLBAR_MENUP__MSG  = \1'Ein- und Ausblenden der Funktionsleiste'
         LOADTOOLBAR_MENUP__MSG    = \1'Laden einer vorher gesicherten Funktionsleiste'
         SAVETOOLBAR_MENUP__MSG    = \1'Sichern der benutzerdefinierten Funktionsleiste'
         DELETETOOLBAR_MENUP__MSG  = \1'L�schen einer Funktionsleiste'
       TOGGLEBITMAP_MENUP__MSG   = \1'Ein- und Ausschalten des Bitmaps hinter dem Textfenster'
       INFOATTOP_MENUP__MSG      = \1'Umschalten zw. Kopf-/Fu�anzeige d. Status- u. Nachrichtenzeile'
       PROMPTING_MENUP__MSG      = \1'Ein- und Ausschalten der Kurzhilfetexte f�r die Men�auswahlm�glichkeiten'
     SAVE_OPTS_MENUP__MSG      = \1'Speichern der aktuellen Fenstereinstellungen als Standardwerte'
     TO_BOOK_MENUP__MSG        = \1'Umschalten zum EPM-Buchsymbol oder zur Arbeitsoberfl�che'

   RING_BAR__MSG =        '~Umlaufliste '

   COMMAND_BAR__MSG =     '~Befehl '
     COMMANDLINE_MENU__MSG = '~Befehlszeile ...'
     HALT_COMMAND_MENU__MSG= 'B~efehl beenden'
     CREATE_SHELL_MENU__MSG= 'Befehls~shell erstellen'
     WRITE_SHELL_MENU__MSG = '~In Shell schreiben ...'
     KILL_SHELL_MENU__MSG =  'Shell been~den'
     SHELL_BREAK_MENU__MSG = '~Unterbrechung an Shell senden'

   COMMAND_BARP__MSG =     \1'Eingabe oder Beenden eines Befehls',
     COMMANDLINE_MENUP__MSG = \1'Anzeigen des Fensters "Befehlszeile" zur Eingabe von Befehlen'
     HALT_COMMAND_MENUP__MSG= \1'Beenden der Ausf�hrung des aktuellen Befehls'
     CREATE_SHELL_MENUP__MSG= \1'Erstellen einer OS/2-Befehlszeile auf der Oberfl�che'
     WRITE_SHELL_MENUP__MSG = \1"Schreiben einer Zeichenkette in die Standardeingabe der Oberfl�che"
     KILL_SHELL_MENUP__MSG =  \1'Beenden der Verarbeitung auf Oberfl�che u. L�schen der zugeh�rigen Datei'
     SHELL_BREAK_MENUP__MSG = \1'Senden einer Strg+Untbr-Nachricht an den Shell-Proze�'

   HELP_BAR__MSG =        '~Hilfe '
     HELP_HELP_MENU__MSG =   'Hilfe f�r ~Hilfefunktion'  -- was '~Help for help'
     EXT_HELP_MENU__MSG =    '~Erweiterte Hilfe'  -- was '~Extended help...'
     KEYS_HELP_MENU__MSG =   'Hilfe f�r ~Tasten'
     COMMANDS_HELP_MENU__MSG =   'Hilfe f�r ~Befehle'
     HELP_INDEX_MENU__MSG =  'Hilfe~index'
     HELP_BROWSER_MENU__MSG= 'Info-~�berblick'
     HELP_PROD_MENU__MSG=    '~Produktinformation'
     USERS_GUIDE_MENU__MSG = "~Benutzerhandbuch"
       VIEW_USERS_MENU__MSG =  "~Benutzerhandbuch anzeigen"
       VIEW_IN_USERS_MENU__MSG="~Aktuelles Wort suchen"
       VIEW_USERS_SUMMARY_MENU__MSG="~Zusammenfassung anzeigen"
     TECHREF_MENU__MSG =     "~Referenzhandbuch"
       VIEW_TECHREF_MENU__MSG =  "~Referenzhandbuch anzeigen"
       VIEW_IN_TECHREF_MENU__MSG="~Aktuelles Wort suchen"

   HELP_BARP__MSG =         \1'Men�s f�r den Zugriff auf Hilfetexte und Copyrightinformationen'
     HELP_HELP_MENUP__MSG =   \1'Hilfetexte f�r die einzelnen Hilfefunktionen'
     EXT_HELP_MENUP__MSG =    \1'Anzeigen von allgemeinem Hilfetext zur Einf�hrung in den Editor'
     KEYS_HELP_MENUP__MSG =   \1'Hilfe f�r die im Editor definierten Tasten'
     COMMANDS_HELP_MENUP__MSG=\1'Hilfe f�r die im Editor definierten Befehle'
     HELP_INDEX_MENUP__MSG =  \1'Anzeigen des Hilfeindexes'
     HELP_BROWSER_MENUP__MSG= \1'Anzeigen der Datei "Info-�berblick" �ber den Editor (mit ASCII-Tabelle)'
     HELP_PROD_MENUP__MSG=    \1'Anzeigen von Copyright und Versionsnummer'
     USERS_GUIDE_MENUP__MSG = \1"Anzeigen des EPM User's Guide, oder Suchen eines Worts darin"
       VIEW_USERS_MENUP__MSG =  \1"Anzeigen des EPM User's Guide"
       VIEW_IN_USERS_MENUP__MSG=\1"Suchen des aktuellen Worts in EPM User's Guide"
       VIEW_USERS_SUMMARY_MENUP__MSG=\1"Anzeigen des Abschnitts ""Summary of Configuration Constants"""
     TECHREF_MENUP__MSG =     \1"Anzeigen der EPM Technical Reference, oder Suchen eines Worts darin"
       VIEW_TECHREF_MENUP__MSG=   \1"Anzeigen der EPM Technical Reference"
       VIEW_IN_TECHREF_MENUP__MSG=\1"Suchen des aktuellen Worts in EPM Technical Reference"

   COMPILER_BAR__MSG =           'Co~mpiler'
     NEXT_COMPILER_MENU__MSG =     '~N�chster Fehler'
     PREV_COMPILER_MENU__MSG =     '~Voriger Fehler'
     DESCRIBE_COMPILER_MENU__MSG = 'Fehler ~beschreiben'
     CLEAR_ERRORS_MENU__MSG =      'Fehler ~l�schen'
     END_DDE_SESSION_MENU__MSG =   '~Beenden der DDE-Session'
     REMOVE_COMPILER_MENU__MSG =   '~Entfernen des Men�s "Compiler"'

   COMPILER_BARP__MSG =           \1'Compilerspezifische Auswahlm�glichkeiten'
     NEXT_COMPILER_MENUP__MSG =     \1'Anzeigen des n�chsten Compilerfehlers'
     PREV_COMPILER_MENUP__MSG =     \1'Anzeigen des vorigen Compilerfehlers'
     DESCRIBE_COMPILER_MENUP__MSG = \1'Auflisten der Fehler f�r aktuelle Zeile und wahlfreie Hilfe'
     CLEAR_ERRORS_MENUP__MSG =      \1'Aufheben der Hervorhebung und der Lesezeichen f�r Compilerfehler'
     END_DDE_SESSION_MENUP__MSG =    \1'Ende der DDE-Session mit der Workframe'
     REMOVE_COMPILER_MENUP__MSG =    \1'Entfernen des Men�s "Compiler"'

;  (End of pull-downs)
; Now, define the lower and upper case accelerators for the above
; action bar entries.  For each letter (_L), we need an upper (_A1)
; and lower (_A2) case ASCII value.  Example:  '~File'
; letter = 'F'; ASCII('F') = 70; ASCII('f') = 102
   FILE_ACCEL__L =       'D'  -- Datei
   FILE_ACCEL__A1 =       68
   FILE_ACCEL__A2 =      100
   EDIT_ACCEL__L =       'E'
   EDIT_ACCEL__A1 =       69
   EDIT_ACCEL__A2 =      101
   SEARCH_ACCEL__L =     'S'
   SEARCH_ACCEL__A1 =     83
   SEARCH_ACCEL__A2 =    115
   OPTIONS_ACCEL__L =    'O'
   OPTIONS_ACCEL__A1 =    79
   OPTIONS_ACCEL__A2 =   111
   RING_ACCEL__L =       'U'  -- Umlaufliste
   RING_ACCEL__A1 =       85
   RING_ACCEL__A2 =      117
   COMMAND_ACCEL__L =    'B'  -- Befehl
   COMMAND_ACCEL__A1 =    66
   COMMAND_ACCEL__A2 =    98
   HELP_ACCEL__L =       'H'
   HELP_ACCEL__A1 =       72
   HELP_ACCEL__A2 =      104
   COMPILER_ACCEL__L =   'M'  -- Co~mpiler error
   COMPILER_ACCEL__A1 =   77
   COMPILER_ACCEL__A2 =  113

;        New stuff for OVSHMENU.E.
   VIEW_ACCEL__L =       'A'  -- Anzeigen
   VIEW_ACCEL__A1 =       86
   VIEW_ACCEL__A2 =      118
   SELECTED_ACCEL__L =   'S'  -- Au~sgew�hlt
   SELECTED_ACCEL__A1 =   83
   SELECTED_ACCEL__A2 =  115

   VIEW_BAR__MSG =        '~Anzeigen'
   SELECTED_BAR__MSG =        'Au~sgew�hlt'

     OPENAS_MENU__MSG  =    '�~ffnen als'
     OPENNOAS_MENU__MSG  =  '~�ffnen'
     NEWWIN_MENU__MSG =     '~Neues Fenster ...'
     SAMEWIN_MENU__MSG =    'Dieses ~Fenster ...'
     COMMAND_SHELL_MENU__MSG='~Befehlsshell'
     PRINT_MENU__MSG =      '~Drucken ...'
     UNDO__MENU__MSG =      '~�nderungen widerrufen'
     SELECT_ALL_MENU__MSG = '~Alles ausw�hlen'
     DESELECT_ALL_MENU__MSG = 'N~ichts ausw�hlen'

     OPENAS_MENUP__MSG  =       \1'�ffnen einer Datei oder �ndern von Objekteinstellungen'
     NEWWIN_MENUP__MSG =        \1'Ersetzen der aktuelle Datei durch eine leere Datei "'UNNAMED_FILE_NAME'"'
     UNDO__MENUP__MSG =         \1'Men�s f�r das Widerrufen, Markieren und f�r die Zwischenablage'
     SELECT_ALL_MENUP__MSG =    \1'Markiert den gesamten Text der Datei (Zeichenmarkierung)'

   VIEW_BARP__MSG =        \1'Men�s f�r das Suchen und �ndern von Text, Lesezeichen, Befehle usw.'
   SELECTED_BARP__MSG =         \1'Men�s f�r das Bearbeiten des ausgew�hlten Textes'

; End of additions for OVSH menus.

   NO_PRINTERS__MSG =     '(Keine Drucker)'
   PRINT__MSG =           'Drucken'  -- Dialog box title
   DRAFT__MSG =           '~Entwurf'  -- Button
   WYSIWYG__MSG =         '~WYSIWYG'  -- Button  (What You See Is What You Get)
   SELECT_PRINTER__MSG =  'W�hlen Sie einen Drucker aus'
           -- 'Printer' printername 'has no device associated with it.'
   PRINTER__MSG =         'Drucker'
   NO_DEVICE__MSG =       'ist kein Anschlu� zugeordnet.'
   NO_QUEUE__MSG =        'ist keine Warteschlange zugeordnet.'
   EDITOR__MSG =          "EPM-Editor - Produktinformation"
   EDITOR_VER__MSG =      "Editorversion" -- nnn
   MACROS_VER__MSG =      "Makroversion" -- nnn
   COPYRIGHT__MSG =       "(C) Copyright IBM Corporation 1989, 1993, 1994, 1995, 1996"
   OVERLAPPING_ATTRIBS__MSG = '�berlagerte Attribute; nichts ge�ndert.' /*NLS*/
                            -- Following is followed by pres. parm. name
   UNKNOWN_PRESPARAM__MSG = "Unbekannter Parameter:"     /*NLS*/
                            -- Following is followed by action name
   UNKNOWN_ACTION__MSG =  'Kann Aktion nicht aufl�sen'                       /*NLS*/

;; Epmlex.e
   REPLACE__MSG =         '~Ersetzen'
   SYNONYMS__MSG =        'Synonyme'  -- Listbox Title
            -- "Spell checking marked area" or "... file"
   CHECKING__MSG =        'Rechtschreibpr�fung in'
   MARKED_AREA__MSG =     'markiertem Bereich'
   FILE__MSG =            'Datei'
   NEXT__MSG =            '~Weiter'     -- button
   TEMP_ADD__MSG =        '~Temp. hzfg.' -- button, so keep short
   ADD__MSG =             '~Hinzuf�gen' -- button:  Add to addenda
   EDIT__MSG =            '~Editieren'  -- button
   EXIT__MSG =            '~Abbruch'    -- button
   LOOKUP_FAILED__MSG =   'Pr�fen des folgenden Wortes nicht m�glich:' --<word>
   PROOF__MSG =           'Pr�fen von'  -- Listbox title; "Proof <word>"
   REPLACEMENT__MSG =     'Geben Sie einen Ersatzbegriff ein f�r'  -- <word>
   PROOF_WORD__MSG =      'Wort pr�fen'  -- Listbox title
   NO_DICT__MSG =         'W�rterverzeichnis existiert nicht:'  -- dict_filename
   DICT_PTR__MSG =        'Wechseln der W�rterverzeichnisse mit der Seite "Pfade" des Einstellung-Notizbuchs.'
   DICTLIST_IS__MSG =     'W�rterverzeichnisliste ist:'  -- list of file names
             -- 'File not found "'new_name'"; dictionary remains:' old_name
   DICT_REMAINS__MSG =    'W�rterverzeichnis bleibt:'
             -- "Nothing found for <bad_word>".  Used in a dialog;
   WORD_NOT_FOUND__MSG =  'Nicht gefunden f�r'     --  try to keep this short.

;; Stdkeys.e
   MARKED_OTHER__MSG =    "Markierung in einer anderen Datei wurde entfernt."
   MARKED_OFFSCREEN__MSG= "Markierung ausserhalb des Fensters wurde entfernt."
   CANT_REFLOW__MSG =     "Neuausrichten nicht m�glich!"
   OTHER_FILE_MARKED__MSG="Es gibt einen markierten Bereich in einer anderen Datei."
   MARK_OFF_SCRN_YN__MSG= "Ein markierter Bereich wird nicht auf dem Bildschirm angezeigt. Fortfahren? (J/N)"
   MARK_OFF_SCREEN__MSG = "Neuausrichten nicht m�glich! Es gibt einen markierten Bereich au�erhalb des Bildschirms."
   WRONG_MARK__MSG =      'Zeilen- oder Blockmarkierung erforderlich'
   PBLOCK_ERROR__MSG =    'Fehler bei pblock_reflow'
   BLOCK_REFLOW__MSG =    "Blockausrichtung: neue Blockgr��e mit Alt-B markieren; Alt-R erneut dr�cken (Esc f�r Abbruch)"
   NOFLOW__MSG =          'Blockmarkierung wurde nicht neu ausgerichtet'
   CTRL_R__MSG =          'Speichern von Tasten. Strg-R zum Beenden, Strg-T zum Beenden und Versuchen, Strg-C zum Abbrechen.'
   REMEMBERED__MSG =      'Tasten gespeichert. Zur Ausf�hrung Strg-T dr�cken.'
   CANCELLED__MSG =       'Abgebrochen.'
   CTRL_R_ABORT__MSG =    'Zeichenkette zu lang! Mit Strg-C abbrechen.'
   OLD_KEPT__MSG =        'Voriger Tastenmakro nicht ersetzt'
   NO_CTRL_R__MSG =       'Nichts gespeichert'

;; Stdcmds.e
   ON__MSG =              'ON'  -- Must be upper case for comparisons
   OFF__MSG =             'OFF'
          -- Following is missing close paren on purpose.  sometimes ends ')', others '/?)'
   ON_OFF__MSG =          '(ON/OFF/1/0'  -- Used in prompts: 'Invalid arguments (On/Off/1/0)'
   PRINTING__MSG =        'Gedruckt wird:'  -- 'Printing' .filename
   CURRENT_AUTOSAVE__MSG= 'Aktueller Wert f�r automatisches Sichern='
   NAME_IS__MSG =         'Name='
   LIST_DIR__MSG =        'Verzeichnis f�r automatisches Sichern anzeigen?'
   NO_LIST_DIR__MSG =     '[Umlaufliste inaktiviert; Verzeichnis kann nicht aufgelistet werden.]'
   AUTOSAVE__MSG =        'Automatisches Sichern'  -- messagebox title
   AUTOSAVE_PROMPT__MSG = 'AUTOSAVE <number>  , um die Anzahl der �nderungen zwischen dem Sichern festzulegen. 0 = aus.'
   BROWSE_IS__MSG =       'Anzeigemodus ist' -- on/off
   READONLY_IS__MSG =     'Nur-Lesen-Attribut ist' -- on/off
   NO_REP__MSG =          'Es wurde kein Ersatzbegriff angegeben'
   CUR_DIR_IS__MSG =      'Aktuelles Verzeichnis:'
   EX_ALL__MSG =          'Alle markierten Zeilen ausf�hren?'
   EX_ALL_YN__MSG =       'Alle markierten Zeilen ausf�hren (J,N) ?'
   NEW_FILE__MSG =        'Neue Datei'
   BAD_PATH__MSG =        'Pfad nicht gefunden'
   LINES_TRUNCATED__MSG = 'Zeilen abgeschnitten'
   ACCESS_DENIED__MSG =   'Zugriff verweigert'
   INVALID_DRIVE__MSG =   'Ung�ltiges Laufwerk'
   ERROR_OPENING__MSG =   'Fehler beim �ffnen'
   ERROR_READING__MSG =   'Fehler beim Lesen'
   ECHO_IS__MSG =         'Befehlsanzeige ist'  -- ON or OFF
   MULTIPLE_ERRORS__MSG = 'Mehrere Fehler beim Laden von Dateien. Siehe Nachrichten unten:'
   COMPILING__MSG =       'Kompiliert wird'  -- filename
              -- 'ETPM.EXE could not open temp file "'tempfile'"'
   CANT_OPEN_TEMP__MSG =  'konnte die temp. Datei nicht �ffnen'
   COMP_COMPLETED__MSG =  'Kompilierung erfolgreich abgeschlossen'
   EXIT_PROMPT__MSG =     "Sie sind dabei zu beenden, ohne zu sichern! "
   KEY_PROMPT1__MSG =     'Geben Sie eine Taste zum Wiederholen ein.  Esc zum Abbrechen.'
                --  'Please specify the key to repeat, as in "key 'number' =".'
   KEY_PROMPT2__MSG =     'Geben Sie eine Taste zum Wiederholen an wie in'
   LOCKED__MSG =          'Datei ist gesperrt. Vor der Namens�nderung mit UNLOCK entsperren.'
   ERROR_SAVING_HALT__MSG='Fehler beim Sichern der Datei. Befehl beendet.'
   HELP_TOP__MSG =        ' ------ Anfang - Hilfetext -------'
   HELP_BOT__MSG =        ' ------ Ende - Hilfetext -------'
   PRINTER_NOT_READY__MSG='Drucker nicht bereit'
   BAD_PRINT_ARG__MSG =   'Ung�ltiges Argument f�r PRINT.'
                  -- "You have a marked area in another file.  Unmark or edit" filename
   UNMARK_OR_EDIT__MSG =  'Markierung aufheben oder folgende Datei editieren:'
   PRINTING_MARK__MSG =   'Markierter Text wird gedruckt'
   MACRO_HALTED__MSG =    'Macro wurde vom Benutzer beendet'
                -- filename 'does not exist'
   DOES_NOT_EXIST__MSG =  'existiert nicht'
   SAVED_TO__MSG =        'Gesichert unter'  -- filename
   IS_A_SUBDIR__MSG =     'Angeforderter Dateiname besteht als Unterverzeichnis'
   READ_ONLY__MSG =       'Datei hat das Attribut "Nur Lesen".'
   IS_SYSTEM__MSG =       'Datei hat das Attribut "System".'
   IS_HIDDEN__MSG =       'Datei hat das Attribut "Verdeckt".'
   MAYBE_LOCKED__MSG =    'Datei u. U. von einer Anwendung gesperrt.'
   ONLY_VIEW__MSG =       'Dies ist die einzige Ansicht dieser Datei.'

;; SLnohost.e
   INVALID_FILENAME__MSG= 'Ung�ltiger Dateiname.'
   QUIT_PROMPT1__MSG =    '�nderungen l�schen? J, N oder die Taste "Sichern und verlassen" dr�cken'
   QUIT_PROMPT2__MSG =    '�nderungen l�schen? J oder N dr�cken'
   PRESS_A_KEY__MSG =     'Eine Taste dr�cken ...'
   LONGNAMES_IS__MSG =    'LONGNAMES-Modus ist'

compile if HOST_SUPPORT <> ''
;; SaveLoad.e
   BAD_FILENAME_CHARS__MSG = 'Zeichen im Dateinamen werden nicht unterst�tzt'
   LOADING_PROMPT__MSG =    'Geladen wird'  -- filename
   SAVING_PROMPT__MSG =     'Gesichert wird'  -- filename
   HOST_NOT_FOUND__MSG =    'Wahrscheinlich Host-Datei nicht gefunden.'
      --  'Host error 'rc'; host save cancelled.  File saved in 'vTEMP_PATH'eeeeeeee.'hostfileid
   HOST_ERROR__MSG =        'Host-Fehler'
   HOST_CANCEL__MSG =       'Host-Sichern abgebrochen. Datei gesichert unter'
compile endif

compile if HOST_SUPPORT = 'EMUL' | HOST_SUPPORT = 'E3EMUL'
;; E3Emul.e
   OVERLAY_TEMP1__MSG =     'Durch Laden wird bestehende PCtempdatei �berschrieben - fortsetzen?  (J,N)'
         -- Loading <filename> with <options>
   WITH__MSG =              'mit Option(en)'
   FILE_TRANSFER_ERROR__MSG='Datei�bertragungsfehler'  -- RC
   SAVED_LOCALLY_AS__MSG =  'Gesichert auf dem PC unter'  -- filename
   SAVE_LOCALLY__MSG =      'Soll diese Datei auf dem PC gesichert werden?  (J,N)'
   OVERLAY_TEMP2__MSG =     'existiert bereits. J dr�cken zum �berschreiben, N zum Abbrechen.'
   OVERLAY_TEMP3__MSG =     'existiert bereits. OK ausw�hlen zum �berschreiben, Abbruch zum Abbrechen.'
   ALREADY_EDITING__MSG =   'Eine Datei dieses Namens wird bereits editiert - �nderung verweigert'
   NO_SPACES__MSG =         'Leerzeichen nicht in Dateinamen unterst�tzt'
   LOOKS_VM__MSG =          'f�r VM angegeben, aber'  -- <filename> 'looked like VM, but' <one of the following:>
     NO_HOST_DRIVE__MSG =   'kein Host-Laufwerk vorhanden'
     HOST_DRIVELETTER__MSG = 'Host-Laufwerkbuchstabe'  -- host drive specifier <X> <problem>
       IS_TOO_LONG__MSG =   'ist zu lang'
       INVALID__MSG =       'ung�ltig'
     HOST_LT__MSG =         'Logische Host-Datenstation'  -- host logical terminal <X> invalid
     NO_LT__MSG =           'Fehlende logische Datenstation'
     FM__MSG =              'Dateimodus' -- <X> is too long
     FM1_BAD__MSG =         'Erstes Zeichen f�r Dateimodus kein Buchstabe'
     FM2_BAD__MSG =         'Zweites Zeichen f�r Dateimodus nicht numerisch'
     NO_FT__MSG =           'Dateityp fehlt'
     FT__MSG =              'Dateityp' -- <X> is too long
     BAD_FT__MSG =          'Ung�ltige Zeichen in Dateityp'  -- <filetype>
     FN__MSG =              'Dateiname' -- <X> is too long
     BAD_FN__MSG =          'Ung�ltige Zeichen in Dateiname'  -- <filename>
   MVS_ERROR__MSG =         '(MVS-Fehler)'  -- followed by <one of the following:>
     DSN_TOO_LONG__MSG =    'Datensatzname l�nger als 44 Zeichen'
                   --  'qualifier #' 1 '('XXXXXXXXX')' <problem>
     QUAL_NUM__MSG =        'Qualifikationsmerkmal #'
       QUAL_TOO_LONG__MSG = 'l�nger als 8 Zeichen'
       QUAL_INVALID__MSG =  'enth�lt ein ung�ltiges Zeichen'
     GENERATION_NAME__MSG = 'Generierungsname'
     MEMBER__MSG =          'Member'
     INVALID_MEMBER__MSG =  'Ung�ltige Zeichen in Member'
     DSN_PARENS__MSG =      'DSN has parens but no member/generation'
   LOOKS_PC__MSG =          'f�r PC angegeben, aber'  -- <filename> 'looked like PC, but' <one of the following:>
     PC_DRIVESPEC__MSG =    'PC-Laufwerksangabe'  -- PC drive specifier <X> <problem>
       LONGER_THAN_ONE__MSG =   'l�nger als 1 Zeichen'
       IS_NOT_ALPHA__MSG =  'kein Buchstabe'
     INVALID_PATH__MSG =    'Ung�ltiger Pfad'  -- followed by <filename>
     INVALID_FNAME__MSG =   'Ung�ltiger PC-Dateiname'  -- followed by <filename>
     INVALID_EXT__MSG =     'Ung�ltige PC-Erweiterung'  -- followed by <extension>
   SAVEPATH_NULL__MSG =     'SAVEPATH ist null - aktuelles Verzeichnis wird verwendet.'
;        'Savepath attempting to use invalid' bad '- will use current directory.'
   SAVEPATH_INVALID1__MSG = 'SAVEPATH ung�ltig:'
   SAVEPATH_INVALID2__MSG = '- aktuelles Verzeichnis wird verwendet.'
   BACKUP_PATH_INVALID_NO_BACKSLASH__MSG= "BACKUP_PATH ung�ltig: '\' am Ende fehlt."
   NO_BACKUPS__MSG=         "Backup-Dateien werden nicht erstellt."
   BACKUP_PATH_INVALID1__MSG = 'BACKUP_PATH ung�ltig:'
   DRIVE__MSG =             'Laufwerk'
   PATH__MSG =              'Pfad'
   EMULATOR_SET_TO__MSG =   'Emulator'
   LT_NOW__MSG =            '; (3270-Fenster = '
   EMULATOR__MSG =          'Emulator'
   HOSTDRIVE_NOW__MSG =     'Host-Laufwerk'
   IS_INVALID_OPTS_ARE__MSG='ung�ltig. Optionen sind:'
   TRY_AGAIN__MSG =         'Erneut versuchen'
   LT_SET_TO__MSG =         'Logische Datenstation gleich'  -- set to A, to B, etc.
   LT_SET_NULL__MSG =       'Logische Datenstation gleich null'
   LT_INVALID__MSG =        'ung�ltig. Optionen sind: A-H,No_LT,NULL,NONE'  -- (bad) is...
   FTO_WARN__MSG =          'Datei�bertragungsoptionen werden NICHT auf Richtigkeit �berpr�ft!'
   BIN_WARN__MSG =          'Bin�re Datei�bertragungsoptionen werden NICHT auf Richtigkeit �berpr�ft!'
   FROM_HLLAPI__MSG =       'von HLLAPI-Aufruf'  -- Error nnn from...
   FILE_TRANSFER_CMD_UNKNOWN ='Befehl zur Datei�bertragung unbekannt:'
compile endif

;; EPM_EA.e
   TYPE_TITLE__MSG =        'Typ'  -- Title of a messagebox or listbox for file type
   NO_FILE_TYPE__MSG =      'Die Datei besitzt keinen Typ. Soll ein Typ festgelegt werden?'
   ONE_FILE_TYPE__MSG =     'Die Datei besitzt den folgenden Typ:'
   MANY_FILE_TYPES__MSG =   'Die Datei besitzt die Typen:'
   CHANGE_QUERY__MSG =      'Soll er ge�ndert werden?'
   NON_ASCII_TYPE__MSG =    'Die Datei besitzt nicht-ASCII-Daten als Dateityp.'
   NON_ASCII__MSG =         '<nicht-ASCII>'  -- Comment in a list of otherwise ASCII strings
   SELECT_TYPE__MSG =       'Typ ausw�hlen'
   SUBJ_TITLE__MSG =        'Kommentar'  -- Title of a messagebox or listbox for file subject
   NO_SUBJECT__MSG =        'Die Datei hat keinen Kommentar. Soll ein Kommentar festgelegt werden?'
   SUBJECT_IS__MSG =        'Die Datei hat folgenden Kommentar:'
   NON_ASCII_SUBJECT__MSG = 'Die Datei hat nicht-ASCII-Daten im Kommentar.'
   SELECT_SUBJECT__MSG =    'Kommentar eingeben'
; Following is a list of standard values for .TYPE extended attribute, per OS/2 programming guide.
; Only translate if the .TYPE EA is NLS-specific.  First character is the delimiter between
; types; can be any otherwise-unused character.  (It's a '-' here.)
   TYPE_LIST__MSG =         '-Plain Text-OS/2 Command File-DOS Command File-C Code-Pascal Code-BASIC Code-COBOL Code-FORTRAN Code-Assembler Code-'

;; BOOKMARK.E
   NEED_BM_NAME__MSG =      'Name f�r Lesezeichen fehlt.'
   NEED_BM_CLASS__MSG =     'Klasse f�r Lesezeichen fehlt.'
   UNKNOWN_BOOKMARK__MSG =  'Lesezeichen unbekannt.'
   BM_NOT_FOUND__MSG =      'Lesezeichen nicht gefunden.'
   ITS_DELETED__MSG =       'Es wurde gel�scht.'  -- "Bookmark not found. It has been deleted."
   BM_DELETED__MSG =        'Lesezeichen gel�scht.'
   NO_BOOKMARKS__MSG =      'Keine Lesezeichen eingef�gt.'
   LIST_BOOKMARKS__MSG =    'Lesezeichen - Liste'  -- Listbox title
   DELETE_PERM_BM__MSG =    'Alle gespeicherten Lesezeichen l�schen?'  -- Are you sure?
   UNEXPECTED_ATTRIB__MSG = 'Unvorhergesehener Wert im erweiterten Attribut EPM.ATTRIBUTES'
                    -- Button names.  ~ precedes accelerator char; Cancel doesn't get one.
   SET__MSG =               '~Einf�gen'
   SETP__MSG =              '~Speichern'
   GOMARK__MSG =            'Lesezeichen ~aufsuchen'
   DELETEMARK__MSG =        'Lesezeichen ~l�schen'
   SETMARK__MSG =           'Lesezeichen einf�gen'  -- Title
   SETMARK_PROMPT__MSG =    'Geben Sie einen Namen f�r die aktuelle Cursorposition ein.'
   RENAME__MSG =            'Umbenennen'  -- Title
   NOTHING_ENTERED__MSG =   'Keine Eingabe; Funktion abgebrochen.'
   NO_COMPILER_ERROR__MSG = 'Kein Fehler in der aktuellen Zeile gefunden.'
   DESCRIBE_ERROR__MSG =    'Fehler beschreiben'  -- Listbox title
   DETAILS__MSG =           '~Details'  -- Button
   SELECT_ERROR__MSG =      'Fehler ausw�hlen; dann Details ausw�hlen, um weitere Informationen anzuzeigen.'
   NO_HELP_INSTANCE__MSG =  "Unvorhergesehener Fehler: Keine Hilfe verf�gbar"
   ERROR_ADDING_HELP__MSG = 'beim Versuch, folgende Hilfedatei hinzuzuf�gen:'  -- 'Error' nn 'attempting to add help file' x.hlp
   ERROR_REVERTING__MSG =   'beim Versuch, zu folgender Hilfedatei zur�ckzukehren:'  -- 'Error' nn 'attempting to revert to help file' x.hlp
   BM_ALREADY_EXISTS__MSG = 'Ein Lesezeichen mit diesem Namen existiert bereits.'
   LONG_EA_TITLE__MSG =     "EAs zu gro�"  -- Messagebox title
   LONG_EA__MSG =           "Erw. Attrib. w�rden 64k �berschreiten; Datei kann nicht gesichert werden. Vorher einige Styles entfernen!"

;;;;;;;;;;;;;;;;;;;;;;;;;;  stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   FILE_GONE__MSG =         'Die Datei befindet sich nicht mehr in der Umlaufliste.'
   NO_RING__MSG =           'Umlauffunktion nicht aktiv; es kann keine andere Datei der Umlaufliste hinzugef�gt werden.'
   NO_RING_CMD__MSG =       'Folgender Befehl ist ung�ltig, wenn die Umlauffunktion nicht aktiv ist:'  -- followed by command name
   RENAME_PROMPT__MSG =     'Neuen Namen f�r aktuelle Datei eingeben.'
   RX_PROMPT__MSG =         'Makroname mu� als Parameter �bergeben werden (z. B. EPMREXX ERXMACRO).'
   RX_SUBCOM_FAIL__MSG =    'REXX-Unterbefehlsregistrierung fehlgeschlagen mit RC'
   RX_FUNC_FAIL__MSG =      'REXX-Funktionsregistrierung fehlgeschlagen mit RC'
   MODIFIED_PROMPT__MSG =   'Aktuelle Datei wurde ge�ndert. Sichern?'
   NOT_ON_DISK__MSG =       'existiert nicht auf dem Datentr�ger - Vorgang beendet.'   -- Preceded by:  '"'filename'"'


; The following are used in key names, like 'Ctrl+O', 'Alt+Bkspc', etc.
; Note that some are abbreviated to take up less room on the menus.

   ALT_KEY__MSG =       'Alt'
   CTRL_KEY__MSG =      'Strg'
   SHIFT_KEY__MSG =     'Ums'
   INSERT_KEY__MSG =    'Einfg'
   DELETE_KEY__MSG =    'Entf'
   BACKSPACE_KEY__MSG = 'R�ck'
   ENTER_KEY__MSG =     'Eingabe'
   PADENTER_KEY__MSG =  'Eingb (num)'
   ESCAPE_KEY__MSG =    'Esc'
   UP_KEY__MSG =        'Auf'
   DOWN_KEY__MSG =      'Ab'

;;;;;;;;;;;;;;;;;;;;;;;;;;  New stuff ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   MARK_OFF_SCREEN2__MSG =  "Markierter Bereich liegt au�erhalb des Bildschirms."
   LINES_TRUNCATED_WNG__MSG = 'Eine oder mehrere Zeilen wurde an Spalte 255 umgebrochen; beim Sichern wird die Datei evtl. unbrauchbar.'
   DYNASPEL_NORECALL__MSG = 'Kein falsch geschriebenes Wort vorhanden.'
;                         The following two combine to form one message.
   DYNASPEL_PROMPT1__MSG =  'Unbekanntes Wort war '
   DYNASPEL_PROMPT2__MSG =  ' - Strg+A f�r Alternativen.'
;                         The following two combine to form one message.
   PROOF_ERROR1__MSG =      'Unerwarteter Fehler in Zeile'
   PROOF_ERROR2__MSG =      '- springe in n�chste Zeile.'

   STACK_FULL__MSG =        'Stapelspeicher ist voll.'
   STACK_EMPTY__MSG =       'Stapelspeicher ist leer.'
   TAGSNAME__MSG =          'Name f�r Tags-Datei'     -- Entry box title
   TAGSNAME_PROMPT__MSG =   'Geben Sie den Dateinamen f�r die Tags-Datei ein:'
   FINDTAG__MSG =           'Suchen einer Prozedur'      -- Entry box title
   FINDTAG_PROMPT__MSG =    'Geben Sie den Namen der Prozedur ein.'
   NO_TAGS__MSG =           'Keine Tags in Tags-Datei gefunden.'
   LIST_TAGS__MSG =         'Tags-Liste'         -- Listbox title
   BUILDING_LIST__MSG =     'Erstelle Liste ...'  -- Processing message
   LIST__MSG =              'Auf~listen ...'               -- Button
   MAKETAGS__MSG =          'Erstellen der Tags-Datei'
   MAKETAGS_PROMPT__MSG =   'Geben Sie einen oder mehrere Dateinamen ein (Wildcards OK) oder @Listen.'
   MAKETAGS_PROCESSING__MSG = 'MAKETAGS in Arbeit - untersuche Quelldateien.'
   MESSAGELINE_FONT__MSG =  'Zeichensatz der Nachrichtenzeile ge�ndert.'
   MESSAGELINE_FGCOLOR__MSG = 'Vordergrundfarbe der Nachrichtenzeile ge�ndert.'
   MESSAGELINE_BGCOLOR__MSG = 'Hintergrundfarbe der Nachrichtenzeile ge�ndert.'
   TABGLYPH_IS__MSG =       'TABGLYPH ist' -- on/off

;  NO_TOOLBARS__MSG =       'No saved toolbars to select from.'
;  LOAD_TOOLBAR__MSG =      'Load Toolbar'  -- Dialog box title
;  DELETE_TOOLBAR__MSG =    'Delete Toolbar'  -- Dialog box title
;  SELECT_TOOLBAR__MSG =    'Select a Toolbar menu set'
   SAVEBAR__MSG =           'Sichern der Funktionsleiste'  -- Dialog box title
;  SAVEBAR_PROMPT__MSG =    'Enter a name, or leave blank to save as default.'
   SAVEBAR_PROMPT__MSG =    'Name f�r die Funktionsleiste:'
   SAVE__MSG =              'Sichern'          -- Dialog button
   WILDCARD_WARNING__MSG =  'Dateiname enth�lt Wildcards.'  -- followed by ARE_YOU_SURE__MSG

;; ASSSIST.E
   NOT_BALANCEABLE__MSG =   'Kein abgleichbares Zeichen.'
   UNBALANCED_TOKEN__MSG =  'Nicht abgeglichenes Zeichen.'

   WIDE_PASTE__MSG =        'Eingef�gter Text ist breiter als der Rand. Neu ausrichten?'

