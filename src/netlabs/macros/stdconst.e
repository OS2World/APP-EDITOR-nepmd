/****************************** Module Header *******************************
*
* Module Name: stdconst.e
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: stdconst.e,v 1.13 2009-05-14 21:45:40 aschn Exp $
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

; ---------------------------------------------------------------------------
; Commented out obsolete lines by a ';' (rather then deleting them) to enable
; searching for obsolete consts.
; ---------------------------------------------------------------------------

const
   TRUE  = 1
   FALSE = 0

   E3      = EVERSION < 4
   EOS2    = EVERSION >= 4 & EVERSION < 5
   EOS2FAM = EVERSION >= 4 & EVERSION < '4.10'
   EPM     = EVERSION >= 5
   EPM32   = EVERSION >= 6
   POWERPC = EVERSION >= 7

   NEPMD   = 1.14

;compile if EPM & EVERSION < '5.20'
;*** The current macros don't support your extremely backlevel version of EPM.
;compile endif

;compile if EVERSION < '4.10'    -- for E3 or OS/2 family version
;   DOS_INT  = 33        /* 21 hex */
;   GET_DATE = 42*256    /* The AX values for specific functions. */
;   GET_TIME = 44*256    /* High byte AH = 2A and 2C hex.         */
;   DOS_GET_VERSION = 48*256  /* high byte = 30 hex */
;   DOS_UNLINK = 65*256  /* High byte = 41 hex */
;compile endif

   MAXINT = 32767            /* Don't change */

compile if not defined(MAXCOL)  -- Predefined constant starting in 5.60
; compile if EVERSION < '5.53'
;   MAXCOL = 255
; compile else
   MAXCOL = 1600  -- saveas_dlg
; compile endif
compile endif

   MAXMARGIN = MAXCOL - 1

;compile if EVERSION > 5

   SYSTEM_POINTER    =  1    /* default mouse pointer  (arrow)  */
   TEXT_POINTER      =  2    /* text entry pointer              */
   WAIT_POINTER      =  3    /* hour glass                      */
   SIZE_POINTER      =  4    /*                                 */
   MOVE_POINTER      =  5    /* four direction arrow            */
   SIZE_NWSE_POINTER =  6    /* arrow northwest southeast       */
   SIZE_NESW_POINTER =  7    /* arrow northeast southwest       */
   SIZE_WE_POINTER   =  8    /* arrow west east                 */
   SIZE_NS_POINTER   =  9    /* arrow north south               */
   APPICON_POINTER   =  10   /* applications icon.              */
   HAND_POINTER      =  11   /* stop pointer                    */
   QUESTION_POINTER  =  12   /* question icon.                  */
   BANG_POINTER      =  13   /* !                               */
   NOTE_POINTER      =  14   /* star                            */
   MARK_POINTER      =  15   /* default mouse pointer  (arrow)  */

   EPMSHAREDBUFFER   = 'EPMCLIPB'   /* shared buffer name see clipbrd.e */
   EPMDMBUFFER       = 'EPMDMBUF'   /* shared buffer name see clipbrd.e */

   INI_STUFF         = 'STUFF'
   INI_MARGINS       = 'MARGINS'
   INI_AUTOSAVE      = 'AUTOSAVE'
   INI_TABS          = 'TABS'
   INI_TEXTCOLOR     = 'TEXTCOLOR'
   INI_MARKCOLOR     = 'MARKCOLOR'
   INI_STATUSCOLOR   = 'STATUSCOLOR'
   INI_MESSAGECOLOR  = 'MESSAGECOLOR'
   INI_DTCOLOR       = 'DTCOLOR'
   INI_TEMPPATH      = 'TEMPPATH'
   INI_DICTIONARY    = 'DICTIONARY'
   INI_ADDENDA       = 'ADDENDA'
   INI_AUTOSPATH     = 'AUTOSPATH'
   INI_RETRIEVEPATH  = 'RETRIEVEPATH'
   INI_OPTFLAGS      = 'OPTFLAGS'  -- Supercedes a number of the following
   INI_OSTATUS       = 'OSTATUS'
   INI_OMSG          = 'OMSG'
   INI_OVSCROLL      = 'OVSCROLL'
   INI_OHSCROLL      = 'OHSCROLL'
;; INI_OPTEXT        = 'OPTEXT'  -- No longer used
   INI_OPFILEICON    = 'OPFILEICON'
   INI_OPROTATEBUTTONS = 'OPROTATEBUTTONS'
   INI_CUAMARKING    = 'CUAMARK'
   INI_FONTFACE      = 'FONTFACE'
   INI_FONTCX        = 'FONTCX'
   INI_FONTCY        = 'FONTCY'
   INI_FONT          = 'FONT'
   INI_EXTRAPOSITION = 'EXTRAPOS'
   INI_MENUPROMPTS   = 'MPROMPT'
   INI_RINGENABLED   = 'RING'
   INI_STREAMMODE    = 'STREAM'
   INI_ENTERKEYS     = 'ENTERKEYS'
   INI_ENTERKEY      = 'ENTER'
   INI_A_ENTERKEY    = 'A+ENTER'
   INI_C_ENTERKEY    = 'C+ENTER'
   INI_S_ENTERKEY    = 'S+ENTER'
   INI_PADENTERKEY   = 'PADENTER'
   INI_A_PADENTERKEY = 'A+PADENTER'
   INI_C_PADENTERKEY = 'C+PADENTER'
   INI_S_PADENTERKEY = 'S+PADENTER'
   INI_STACKCMDS     = 'STACK'
   INI_CUAACCEL      = 'CUA_ACCEL'
; compile if EVERSION >= 5.60
   INI_STATUSFONT    = 'STATFONT'
   INI_MESSAGEFONT   = 'MSGFONT'
   INI_BITMAP        = 'DTBITMAP'
; compile endif
; compile if EVERSION >= 6
   INI_UCMENU_APP    = 'UCMenu_Templates'
   INI_TAGSFILES     = 'TagsFiles'
   INI_DEF_TOOLBAR   = 'DEFTOOLBAR'
   INI_OPT2FLAGS     = 'OPT2FLAGS'  -- Addenda to OPTFLAGS for new 32-bit version's config
; compile endif

   VK_BUTTON1   =  1
   VK_BUTTON2   =  2
   VK_BUTTON3   =  3
   VK_BACKSPACE =  5
   VK_NEWLINE   =  8  -- Note:  this is the regular Enter key.
   VK_SHIFT     =  9
   VK_CTRL      = 10
   VK_ALT       = 11
   VK_ALTGRAF   = 12
   VK_CAPSLOCK  = 14
   VK_UP        = 22
   VK_DOWN      = 24
   VK_INSERT    = 26
   VK_DELETE    = 27
   VK_SCRLLOCK  = 28
   VK_NUMLOCK   = 29
   VK_ENTER     = 30  -- Note:  this is the numeric keypad Enter key.
   VK_F1        = 32
   VK_F2        = 33
   VK_F3        = 34
   VK_F4        = 35
   VK_F5        = 36
   VK_F6        = 37
   VK_F7        = 38
   VK_F8        = 39
   VK_F9        = 40
   VK_F10       = 41
   VK_F11       = 42
   VK_F12       = 43

   AF_CHAR        =   1   -- key style constants
   AF_VIRTUALKEY  =   2
   AF_SCANCODE    =   4
   AF_SHIFT       =   8
   AF_CONTROL     =  16
   AF_ALT         =  32
   AF_LONEKEY     =  64
   AF_SYSCOMMAND  = 256
   AF_HELP        = 512

   KS_DOWN        = 1    /* The four possible results of getkeystate(). */
   KS_DOWNTOGGLE  = 2
   KS_UP          = 3
   KS_UPTOGGLE    = 4
                        -- Constants for WinMessageBox
   MB_OK                =        0  -- Pick one of the following for the
   MB_OKCANCEL          =        1  -- buttons you want on the message box
   MB_RETRYCANCEL       =        2
   MB_ABORTRETRYIGNORE  =        3
   MB_YESNO             =        4
   MB_YESNOCANCEL       =        5
   MB_CANCEL            =        6
   MB_ENTER             =        7
   MB_ENTERCANCEL       =        8

   MB_NOICON            =        0  -- Add one of the following for the
   MB_CUANOTIFICATION   =        0  -- icon you want in the message box
   MB_ICONQUESTION      =       16
   MB_ICONEXCLAMATION   =       32
   MB_CUAWARNING        =       32
   MB_ICONASTERISK      =       48
   MB_ICONHAND          =       64
   MB_CUACRITICAL       =       64
   MB_QUERY             =     MB_ICONQUESTION
   MB_WARNING           =     MB_CUAWARNING
   MB_INFORMATION       =     MB_ICONASTERISK
   MB_CRITICAL          =     MB_CUACRITICAL
   MB_ERROR             =     MB_CRITICAL

   MB_DEFBUTTON1        =          0  -- This specifies which button is the
   MB_DEFBUTTON2        =        256  -- default if Enter is pressed.
   MB_DEFBUTTON3        =        512

   MB_APPLMODAL         =       0000  -- Application modal
   MB_SYSTEMMODAL       =       4096  -- System modal
   MB_HELP              =       8192
   MB_MOVEABLE          =      16384  -- The message box can be moved.

   MBID_OK              =     1  -- Message box return codes
   MBID_CANCEL          =     2  -- (correspond with the button pressed)
   MBID_ABORT           =     3
   MBID_RETRY           =     4
   MBID_IGNORE          =     5
   MBID_YES             =     6
   MBID_NO              =     7
   MBID_HELP            =     8
   MBID_ENTER           =     9
   MBID_ERROR           =     65535

   PAINT_OFF  =  0
   PAINT_BLOCK=  1
   PAINT_LINE =  2

   EPMINFO_HAB               =  0  -- The following are constant values that are
   EPMINFO_OWNERCLIENT       =  1  -- to be used as parameters to the getpminfo
   EPMINFO_OWNERFRAME        =  2  -- internal function or as control id's for
   EPMINFO_PARENTCLIENT      =  3  -- control toggle.
   EPMINFO_PARENTFRAME       =  4
   EPMINFO_EDITCLIENT        =  5
   EPMINFO_EDITFRAME         =  6
   EPMINFO_EDITSTATUSAREA    =  7  -- EFRAMEF_STATUSWND = 1
   EPMINFO_EDITORMSGAREA     =  8  -- EFRAMEF_MESSAGEWND = 2
   EPMINFO_EDITORVSCROLL     =  9  -- EFRAMEF_VSCROLLBAR = 8
   EPMINFO_EDITORHSCROLL     = 10  -- EFRAMEF_HSCROLLBAR = 16
   EPMINFO_EDITORINTERPRETER = 11
   EPMINFO_EDITVIOPS         = 12
   EPMINFO_EDITTITLEBAR      = 13
   EPMINFO_EDITCURSOR        = 14
   EPMINFO_PARTIALTEXT       = 15  -- No longer used
   EPMINFO_EDITEXSEARCH      = 16
   EPMINFO_EDITMENUHWND      = 17
   EPMINFO_HDC               = 18
   EPMINFO_HINI              = 19
   EPMINFO_RINGICONS         = 20  -- EFRAMEF_RINGBUTTONS = 4
   EPMINFO_FILEICON          = 22  -- EFRAMEF_FILEWND = 64
   EPMINFO_EXTRAWINDOWPOS    = 23  -- EFRAMEF_INFOONTOP = 32
; compile if EVERSION >= '5.60'
   EPMINFO_EDITSTATUSHWND    = 27
   EPMINFO_EDITMSGHWND       = 28
; compile endif
   EPMINFO_LSLENGTH          = 29
   EPMINFO_SEARCHPOS         = 30

; compile if EVERSION >= '5.53'
   EFRAMEF_STATUSWND      = 1    -- EPMINFO_EDITSTATUSAREA = 7
   EFRAMEF_MESSAGEWND     = 2    -- EPMINFO_EDITORMSGAREA = 8
   EFRAMEF_RINGBUTTONS    = 4    -- EPMINFO_RINGICONS = 20
   EFRAMEF_VSCROLLBAR     = 8    -- EPMINFO_EDITORVSCROLL = 9
   EFRAMEF_HSCROLLBAR     = 16   -- EPMINFO_EDITORHSCROLL = 10
   EFRAMEF_INFOONTOP      = 32   -- EPMINFO_EXTRAWINDOWPOS = 23
   EFRAMEF_FILEWND        = 64   -- EPMINFO_FILEICON = 22
   EFRAMEF_DMTBWND        = 128
   EFRAMEF_TASKLISTENTRY  = 256
   EFRAMEF_TOOLBAR        = 2048

  compile if not defined(APP_HANDLE)
   APP_HANDLE = EPMINFO_OWNERFRAME  -- 5.53 sends application messages to owner frame
  compile endif
; compile else
;   APP_HANDLE = EPMINFO_OWNERCLIENT -- earlier versions sent them to owner client.
; compile endif  -- EVERSION >= '5.53'

; compile if EVERSION < '5.20'
;   E_DLL     = 'E'
;   ERES_DLL  = 'ERES'
;   EUTIL_DLL = 'EUTIL'
;   LEXAM_DLL = 'PCLEXAM'
; compile elseif EVERSION='5.20'   -- As of 5.20, we have version-specific DLLs
;   E_DLL     = 'ETKE520'
;   ERES_DLL  = 'ETKR520'
;;  EUTIL_DLL = 'ETKE520'          -- Also, no more EUTIL.
;   LEXAM_DLL = 'ETKL1'
; compile elseif EVERSION='5.21'
;   E_DLL     = 'ETKE521'
;   ERES_DLL  = 'ETKR521'
;   LEXAM_DLL = 'ETKL1'
; compile elseif EVERSION='5.50'
;   E_DLL     = 'ETKE550'
;   ERES_DLL  = 'ETKR550'
; compile elseif EVERSION='5.51' | EVERSION='5.51a'
;  compile if not defined(E_DLL)
;   E_DLL     = 'ETKE551'
;  compile endif
;  compile if not defined(ERES_DLL)
;   ERES_DLL  = 'ETKR551'
;  compile endif
; compile elseif EVERSION='5.52'
;  compile if not defined(E_DLL)
;   E_DLL     = 'ETKE552'
;  compile endif
;  compile if not defined(ERES_DLL)
;   ERES_DLL  = 'ETKR552'
;  compile endif
; compile elseif EVERSION='5.60' | EVERSION='5.60a' | EVERSION='5.60c'
;   E_DLL     = 'ETKE560'
;   ERES_DLL  = 'ETKR560'
; compile elseif EVERSION='6.00' | EVERSION='6.00a' | EVERSION='6.00b' | EVERSION='6.00c'
;  compile if not defined(E_DLL)
;   E_DLL     = 'ETKE600'
;  compile endif
;  compile if not defined(ERES_DLL)
;   ERES_DLL  = 'ETKR600'
;  compile endif
; compile elseif EVERSION='6.01' | EVERSION = '6.01a' | EVERSION = '6.01b' | EVERSION = '6.01c'
;  compile if not defined(E_DLL)
;   E_DLL     = 'ETKE601'
;  compile endif
;  compile if not defined(ERES_DLL)
;   ERES_DLL  = 'ETKC601'
;  compile endif
;  compile if not defined(ERES2_DLL)
;   ERES2_DLL  = 'ETKR601'
;  compile endif
; compile elseif EVERSION='6.02'
;  compile if not defined(E_DLL)
;   E_DLL     = 'ETKE602'
;  compile endif
;  compile if not defined(ERES_DLL)
;   ERES_DLL  = 'ETKC602'
;  compile endif
;  compile if not defined(ERES2_DLL)
;   ERES2_DLL  = 'ETKR602'
;  compile endif
; compile elseif EVERSION='6.03' or EVERSION='6.03a' or EVERSION='6.03b'
  compile if not defined(E_DLL)
   E_DLL     = 'ETKE603'
  compile endif
  compile if not defined(ERES_DLL)
   ERES_DLL  = 'ETKC603'
  compile endif
  compile if not defined(ERES2_DLL)
   ERES2_DLL  = 'ETKR603'
  compile endif
; compile else
;*** Error:  unrecognized EPM version; don't know what level of DLLs to use.
; compile endif  -- EVERSION < '5.20'

 compile if not defined(EUTIL_DLL)  -- Not used by any current E_MACROS;
   EUTIL_DLL = E_DLL                -- define in case any user macros refer to it.
 compile endif
 compile if not defined(LEXAM_DLL)
   -- EPM 6.03b uses oslexam.dll. Apparently it doesn't matter what is defined here.
   LEXAM_DLL = 'LEXAM'
 compile endif
 compile if not defined(ERES2_DLL)  -- ERES2 is the real ETKRnnn.DLL;
   ERES2_DLL  = ERES_DLL             -- ERES is where listbox, etc. are (now ETKCnnn for EPM 6.01)
 compile endif

   HINI_PROFILE        =  0  -- Searches both user and system profile
   HINI_USERPROFILE    = -1
   HINI_SYSTEMPROFILE  = -2

   FIND_NEXT_ATTR_SUBOP =   1
   FIND_PREV_ATTR_SUBOP =   2
   FIND_MATCH_ATTR_SUBOP =  3
   FIND_RULING_ATTR_SUBOP = 4
   DELETE_ATTR_SUBOP =     16

   HELP_MENU_ID = 6  -- To avoid hardcoding it, but the value shouldn't be changed,
                     -- to avoid breaking code written before the constant was added.
;compile endif  -- EVERSION > 5

;compile if EVERSION >= '4.10'    -- Following are for BUFFER opcode.
   CREATEBUF   =0
   OPENBUF     =1
   FREEBUF     =2
   GETBUF      =3
   PUTBUF      =4
   MAXSIZEBUF  =5
   USEDSIZEBUF =6
; compile if EVERSION > 5
   PUTMARKBUF  =7
   GETMARKBUF  =8             -- Currently not implemented
   MARKTYPEBUF =9
   STARTCOLBUF =10
   ENDCOLBUF   =11
   CLEARBUF    =12
;  compile if EVERSION >= '5.50'
   GETBUF2     =13            -- Like GETBUF, but handles CRLF differently (for PASTE)
;  compile endif  -- EVERSION >= '5.50'
; compile endif  -- EVERSION > 5

   MAXBUFSIZE  = 65535-32     -- don't really need this, will default to max

   APPENDCR      =   1
   APPENDLF      =   2
   APPENDNULL    =   4
   TABCOMPRESS   =   8
   STRIPSPACES   =  16
   FINALNULL     =  32
   LF_IS_NEWLINE =  64
   NOHEADER      = 256
;compile endif  -- EVERSION >= '4.10'

   HEXCHARS = '0123456789ABCDEFabcdef'

compile if not defined(IBM_IUO)
   IBM_IUO = 0  -- Omit stuff that uses IBM Internal Use Only routines.
compile endif


; PM menu stuff

; Menu item styles (see PM2.INF and PMWIN.H)
   MIS_TEXT            =     1  -- 0x0001   -- only required if MIS <> 0
   MIS_BITMAP          =     2  -- 0x0002
   MIS_SEPARATOR       =     4  -- 0x0004
   MIS_OWNERDRAW       =     8  -- 0x0008
   MIS_SUBMENU         =    16  -- 0x0010
   MIS_MULTMENU        =    32  -- 0x0020   <-- multiple choice
   MIS_SYSCOMMAND      =    64  -- 0x0040
   MIS_HELP            =   128  -- 0x0080
   MIS_STATIC          =   256  -- 0x0100
   MIS_BUTTONSEPARATOR =   512  -- 0x0200
   MIS_BREAK           =  1024  -- 0x0400
   MIS_BREAKSEPARATOR  =  2048  -- 0x0800
   MIS_GROUP           =  4096  -- 0x1000
   MIS_SINGLE          =  8192  -- 0x2000   <-- no multiple choice
   --                    16384  -- 0x4000   -- unused
   MIS_ENDSUBMENU      = 32768  -- 0x8000   <-- ENDSUBMENU is only required for buildmenuitem, not a PM MIS

; Menu item attributes (see PM2.INF and PMWIN.H)
   MIA_NODISMISS       =    32  -- 0x0020
   MIA_FRAMED          =  4096  -- 0x1000
   MIA_CHECKED         =  8192  -- 0x2000
   MIA_DISABLED        = 16384  -- 0x4000
   MIA_HILITED         = 32768  -- 0x8000

   -- NepmdGetNextFile and NepmdGetNextDir write the created handle back to the E handle
   -- variable. The handle passed to NepmdGetNextFile/Dir must start with '0' and be
   -- at least 14 bytes long.
   GETNEXT_CREATE_NEW_HANDLE = '00000000000000'

