/****************************** Module Header *******************************
*
* Module Name: edll.h
*
* Original E Toolkit header file from the EPMBBS package
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: edll.h,v 1.2 2002-08-19 18:12:44 cla Exp $
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

/*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
บ What's it called : EDLL.H                                                  บ
บ                                                                            บ
บ What does it do  : Defines function prototypes of entry functions to E.DLL บ
บ                    Defines E window information and structures.            บ
บ                                                                            บ
บ Who and when     : Gennaro (Jerry) Cuomo                          9-88     บ
บ                    John Ponzo                                              บ
ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
#ifndef EDLLINCLUDE_INCLUDED
   #define EDLLINCLUDE_INCLUDED
   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Include os2.h from the IBM OS/2 1.3 Programmer's Toolkit.  We do this to   บ
   บ pick up the definitions in os2def.h.  If you don't have this toolkit you   บ
   บ can probably figure out what the definitions are.  Most of them have names บ
   บ that are indicative of their definition. (jlc 92/4/28)                     บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #ifndef OS2_INCLUDED
      #include <os2.h>
   #endif



   #undef MOVE_DTM_OUT_OF_FILEWNDPROC  // Move Direct Text Manipulation func ...
   #define ACW_PRINT

   #include <etktypes.h>
   #include <print.h>

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ EPM version Length String.                                         GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/


   #define MAXFILENAME 260

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ EPM related Window Messages                                        GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #define EPM_EDIT_MSGID          WM_USER        +  0x500   // This evaluates to EPM_EDIT_MSGID = 5376
   #define EPM_EDIT_COMMAND        EPM_EDIT_MSGID +  1       // Submit command to editor
   #define EPM_EDIT_RETCODE        EPM_EDIT_MSGID +  2       // to owner: notify of errors/warnings
   #define EPM_EDIT_SAYERROR       EPM_EDIT_MSGID +  3       //
   #define EPM_EDIT_CURSORMOVE     EPM_EDIT_MSGID +  4       // to owner: cursor may have moved
   #define EPM_EDIT_ACTIVEHWND     EPM_EDIT_MSGID +  6       // to owner: edit window received WM_ACTIVATE
   #define EPM_EDIT_OPTION         EPM_EDIT_MSGID +  7       // query value of xxxx
   #define EPM_EDIT_ID             EPM_EDIT_MSGID +  8       // query application/window id
   #define EPM_EDIT_SHOW           EPM_EDIT_MSGID +  9       // show/repaint window
   #define EPM_EDIT_NEWFILE        EPM_EDIT_MSGID +  10      // eres: ???
   #define EPM_EDIT_DESTROYNOTIFY  EPM_EDIT_MSGID +  11
   #define EPM_EDIT_CONTROLTOGGLE  EPM_EDIT_MSGID +  12
   #define EPM_EDIT_MOUSEMGR       EPM_EDIT_MSGID +  13      // for subclass: mouse event recognized
   #define EPM_EDIT_RECORDKEY      EPM_EDIT_MSGID +  14
   #define EPM_EDIT_PLAYKEY        EPM_EDIT_MSGID +  15
   #define EPM_EDIT_ENDRECORDKEY   EPM_EDIT_MSGID +  16
   #define EPM_EDIT_QUERYRECORDKEY EPM_EDIT_MSGID +  17
   #define EPM_EDIT_CHAR           EPM_EDIT_MSGID +  18      // internal
   #define EPM_EDIT_CLOSE          EPM_EDIT_MSGID +  19
   #define EPM_EDIT_DESTROYRC      EPM_EDIT_MSGID +  20
   #define EPM_EDIT_HELPNOTIFY     EPM_EDIT_MSGID +  21
   #define EPM_EDIT_ASKTOQUIT      EPM_EDIT_MSGID +  22
   #define EPM_EDIT_ASKTOCLOSE     EPM_EDIT_MSGID +  23
   #define EPM_EDIT_ASKTODONE      EPM_EDIT_MSGID +  24
   #define EPM_EDIT_ASKTOFAILED    EPM_EDIT_MSGID +  25

   #define EPM_EDIT_UPDATE_EDITLIST_ITEM EPM_EDIT_MSGID + 26
   #define EPM_EDIT_DOC2WIN              EPM_EDIT_MSGID + 27
   #define EPM_EDIT_WIN2DOC              EPM_EDIT_MSGID + 28
   #define EPM_EDIT_MINMAXFRAME          EPM_EDIT_MSGID + 29
   #define EPM_EDIT_EXEC_PROC            EPM_EDIT_MSGID + 30
   #define EPM_EDIT_EXEC_DYNALINK        EPM_EDIT_MSGID + 31
   #define EPM_EDIT_TURN_OFF_HIGHLIGHT   EPM_EDIT_MSGID + 32
   #define EPM_EDIT_SETTIMER             EPM_EDIT_MSGID + 33
   #define EPM_EDIT_POSTEDMSG1           EPM_EDIT_MSGID + 34
   #define EPM_EDIT_POSTEDMSG2           EPM_EDIT_MSGID + 35
   #define EPM_EDIT_POSTEDMSG3           EPM_EDIT_MSGID + 36  // future use
   #define EPM_EDIT_POSTDONE             EPM_EDIT_MSGID + 37
   #define EPM_EDIT_COMMAND2             EPM_EDIT_MSGID + 38
   #define EPM_EDIT_GETMEM               EPM_EDIT_MSGID + 39
   #define EPM_EDIT_VERSION              EPM_EDIT_MSGID + 40
   #define EPM_EDIT_MEMNOTIFY            EPM_EDIT_MSGID + 41
   #define EPM_EDIT_EXEC_DYNALINK2       EPM_EDIT_MSGID + 42

   #define EPM_EXTRAWINDOW_REFRESH       EPM_EDIT_MSGID + 50
   #define EPM_EDIT_GETPROFILE           EPM_EDIT_MSGID + 51
   #define EPM_EDIT_ACTIVATEFILEID       EPM_EDIT_MSGID + 52
   #define EPM_EDIT_QUERY_HELP_INSTANCE  EPM_EDIT_MSGID + 53
   #define EPM_FRAME_STATUSLINE          EPM_EDIT_MSGID + 55
   #define EPM_FRAME_MESSAGELINE         EPM_EDIT_MSGID + 56
   #define EPM_DRAGDROP_DIRECTTEXTMANIP  EPM_EDIT_MSGID + 58
   #define EPM_EDIT_WINDOWCREATED        EPM_EDIT_MSGID + 59
   #define EPM_CREATE_DDE_LINK           EPM_EDIT_MSGID + 60
   #define EPM_DRAGDROP_DRAGTARGET       EPM_EDIT_MSGID + 61
   #define EPM_PRINT_RENDERPAGE          EPM_EDIT_MSGID + 62
   #define EPM_PRINT_RENDERPAGERC        EPM_EDIT_MSGID + 63
   #define EPM_QHELP_TABLE               EPM_EDIT_MSGID + 64
   #define EPM_EDIT_CLIPBOARDCOPY        EPM_EDIT_MSGID + 65
   #define EPM_EDIT_CLIPBOARDPASTE       EPM_EDIT_MSGID + 66
   #define EPM_BROADCASTHELP             EPM_EDIT_MSGID + 67
   #define EPM_GET_ERROR_MESSAGE         EPM_EDIT_MSGID + 68
   #define EPM_SEND_MACROS_ERRORS        EPM_EDIT_MSGID + 69
   #define EPM_QUERY_GLOBDATA            EPM_EDIT_MSGID + 70
   #define EPM_IS_HELP_LOADED            EPM_EDIT_MSGID + 71
   #define EPM_EDIT_TASKLIST             EPM_EDIT_MSGID + 72
   #define EPM_EDIT_DELETEFILE           EPM_EDIT_MSGID + 73
   #define EPM_DRAGDROP_RENDERCOMPLETE   EPM_EDIT_MSGID + 74
   #define EPM_EDIT_INIT                 EPM_EDIT_MSGID + 75
   #define EPM_HELP_LOADED               EPM_EDIT_MSGID + 76
   #define EFRAME_STYLE_CHANGE           EPM_EDIT_MSGID + 77
   #define EPM_EDIT_DEFAULTDTBITMAP      EPM_EDIT_MSGID + 78
   #define EPM_FRAME_SETMSGLINE          EPM_EDIT_MSGID + 94
   #define EPM_EDIT_EIQMSG               EPM_EDIT_MSGID + 95
   #define EPM_EDIT_QUERYFILEINFO        EPM_EDIT_MSGID + 96
   #define EPM_EDIT_QUERYSTATUSINFO      EPM_EDIT_MSGID + 97
   #define EPM_EDIT_REQUESTDESTROY       EPM_EDIT_MSGID + 101
   #define EPM_EDIT_DDE_POST_MSG         EPM_EDIT_MSGID + 102
   #define EPM_EDIT_ROUNDTRIPMSG         EPM_EDIT_MSGID + 103
   #define EPM_FRAME_UPDATESTATUSWND     EPM_EDIT_MSGID + 104
   #define EPM_FRAME_ENABLERINGBUTTONS   EPM_EDIT_MSGID + 105
   #define EPM_FRAME_TITLETEXTCHANGE     EPM_EDIT_MSGID + 106
   #define EPM_QUERYHINI                 EPM_EDIT_MSGID + 107
   #define EPM_EDIT_SHOWWINDOW           EPM_EDIT_MSGID + 108
   #define EPM_FRAME_DELETEMSGLINE       EPM_EDIT_MSGID + 109
   #define EPM_FREEFILEARRAY             EPM_EDIT_MSGID + 110
   #define EPM_EDIT_NEWFILES             EPM_EDIT_MSGID + 111
   #define EPM_EDIT_WHOLE_REPAINT_NEXT   EPM_EDIT_MSGID + 112
   #define EPM_EDIT_HSBM_SETTHUMBSIZE    EPM_EDIT_MSGID + 113
   #define EPM_EDIT_HSBM_SETPOS          EPM_EDIT_MSGID + 114
   #define EPM_EDIT_HSBM_RESERVED1       EPM_EDIT_MSGID + 115
   #define EPM_EDIT_VSBM_SETTHUMBSIZE    EPM_EDIT_MSGID + 116
   #define EPM_EDIT_VSBM_SETPOS          EPM_EDIT_MSGID + 117
   #define EPM_EDIT_VSBM_RESERVED1       EPM_EDIT_MSGID + 118
   #define EPM_EDIT_LOGERROR             EPM_EDIT_MSGID + 119
   #define EPM_EDIT_LOGAPPEND            EPM_EDIT_MSGID + 120
   #define EPM_EDIT_SETDTCOLOR           EPM_EDIT_MSGID + 121
   #define EPM_EDIT_SETDTBITMAP          EPM_EDIT_MSGID + 122
   #define EPM_EDIT_SETDTBITMAPFROMFILE  EPM_EDIT_MSGID + 123
   #define EPM_EDIT_QUERYHINI            EPM_EDIT_MSGID + 124
   #define EPM_EDIT_ENDWFDDE             EPM_EDIT_MSGID + 125
#define LPCOMMENTS
#ifdef LPCOMMENTS
   #define EPM_EDIT_TOGGLEPARSE          EPM_EDIT_MSGID + 126
   #define EPM_EDIT_LOADKEYWORDS         EPM_EDIT_MSGID + 127
   #define EPM_EDIT_KW_LOADED            EPM_EDIT_MSGID + 128
   #define EPM_EDIT_KW_QUERYPARSE        EPM_EDIT_MSGID + 129
#endif // LPCOMMENTS
   #define EPM_EDIT_SETTOFSTYLE          EPM_EDIT_MSGID + 130
   #define EPM_EDIT_STOREKEYS            EPM_EDIT_MSGID + 131
   #define EPM_EDIT_RELEASEKEYS          EPM_EDIT_MSGID + 132
   #define EPM_EDIT_STOP_STOREKEYS       EPM_EDIT_MSGID + 133
   #define EPM_EDIT_QWPSHANDLE           EPM_EDIT_MSGID + 134
   #define EPM_EDIT_TOTASKLIST           EPM_EDIT_MSGID + 135
   #define EPM_EDIT_FORCE_DEFSELECT      EPM_EDIT_MSGID + 136
   #define EPM_EDIT_MOVED_TO_LINE0       EPM_EDIT_MSGID + 137

   // Return codes sent by the EPM_EDIT_DESTROYRC message
   #define EPM_RC_DESTROYOK       0
   #define EPM_RC_DESTROYTIMEOUT  1
   #define EPM_RC_DESTROYCANCEL   2
   #define EPM_RC_DESTROYNOFREE   3

   // Return codes sent by the EPM_EDIT_ASKTOQUITDONE message
   #define ERES_CANCEL             0
   #define ERES_DISCARD            1
   #define ERES_SAVE               2

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Editor Styles                                                      GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #define EDIT_STYLE_BROWSE               0x00000001L
   #define EDIT_STYLE_ACTIVATEFOCUS        0x00000004L
   #define EDIT_STYLE_MOVECURSORACTIVATE   0x00000080L
   #define EDIT_STYLE_CURSORON             0x00001000L
   #define EDIT_STYLE_STREAMEDIT           0x00100000L
   #define EDIT_STYLE_CUAMARKING           0x00200000L
   #define EDIT_STYLE_USEDEFAULTARROWKEYS  0x00800000L
   #define EDIT_STYLE_COMMANDMSGTOMACROS   0x01000000L
   #define EDIT_STYLE_DISPLAYERRORRETRY    0x02000000L
   #define EDIT_STYLE_ASYNC                0x08000000L

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Editor Command Message Parameter Styles (mp2 of EPM_EDIT_COMMAND)  GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #define COMMAND_FREESEL    0x00000001L
   #define COMMAND_SYNC       0x00000004L
   #define COMMAND_GETABLE    0x00000008L

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Editor Options (Used with EPM_EDIT_OPTION message)                 GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #define OPTIONS_MARGINS          1
   #define OPTIONS_LINE             2
   #define OPTIONS_COLUMN           3
   #define OPTIONS_INSERT           4
   #define OPTIONS_AUTOSAVE         5
   #define OPTIONS_NTABS            6
   #define OPTIONS_NROWS            7
   #define OPTIONS_NCOLS            8
   #define OPTIONS_MODIFY           9
   #define OPTIONS_TAB              10
   #define OPTIONS_SEARCH           11
   #define OPTIONS_GETTEXT          12
   #define OPTIONS_NAME             13
   #define OPTIONS_HWNDEXTRA        14
   #define OPTIONS_HWNDEIOBJECT     15
   #define OPTIONS_TEXTCOLOR        16
   #define OPTIONS_RING             17
   #define OPTIONS_FILEID           18
   #define OPTIONS_QSELECTION       19


   //     In EPM the field variables are:
   //
   #define  AUTOSAVE_FIELD                      0L
   #define  COL_FIELD                           1L
   #define  CURSORX_FIELD                       2L
   #define  CURSORY_FIELD                       3L
   #define  KEYSET_FIELD                        4L
   #define  LAST_FIELD                          5L
   #define  LINE_FIELD                          6L
   #define  MARGINS_FIELD                       7L
   #define  MARKCOLOR_FIELD                     8L
   #define  MODIFY_FIELD                        9L
   //#define  STATUSCOLOR_FIELD                  10L
   #define  TABS_FIELD                         11L
   #define  WINDOWHEIGHT_FIELD                 12L
   #define  WINDOWWIDTH_FIELD                  13L
   #define  WINDOWX_FIELD                      14L
   #define  WINDOWY_FIELD                      15L
   #define  FILENAME_FIELD                     16L
   #define  USERSTRING_FIELD                   17L
   #define  MOUSEX_FIELD                       18L
   #define  MOUSEY_FIELD                       19L
   #define  TEXTCOLOR_FIELD                    20L
   #define  VISIBLE_FIELD                      21L
   //#define  MESSAGECOLOR_FIELD                 22L
   #define  DRAGCOLOR_FIELD                    23L
   #define  DRAGSTYLE_FIELD                    24L
   #define  FONTWIDTH_FIELD                    25L
   #define  FONTHEIGHT_FIELD                   26L
   //#define  MESSAGELINE_FIELD                  27L
   //#define  STATUSLINE_FIELD                   28L
   #define  LOCKHANDLE_FIELD                   29L
   //#define  DRAGTHRESHHOLDX_FIELD              30L
   //#define  DRAGTHRESHHOLDY_FIELD              31L
   #define  EA_AREA_FIELD                      32L
   #define  ATTRIBUTE_SUPPORT_LEVEL            33L
   #define  CURSOR_OFFSET                      34L
   //#define  TABMODE_FIELD                      35L
   #define  AUTOSHELL_FIELD                    35L
   #define  TITLETEXT_FIELD                    36L
   #define  CURSOR_COLUMN                      37L
   #define  FONT_FIELD                         38L
   #define  SCROLLX_FIELD                      39L
   #define  SCROLLY_FIELD                      40L
   #define  CURSORYG_FIELD                     41L
   #define  LINEG_FIELD                        42L
   #define  WINDOWWIDTHG_FIELD                 43L
   #define  WINDOWHEIGHTG_FIELD                44L
   #define  READONLY_FIELD                     45L
   #define  CODEPAGE_FIELD                     46L
   #define  JUMPSCROLLHORZ_FIELD               47L
   #define  JUMPSCROLLVERT_FIELD               48L
   #define  KLUDGE1_FIELD                      49L
   #define  TOFMARKER_FIELD                    50L
   #define  BOFMARKER_FIELD                    51L
   //#define  PRESENTATIONPROC_FIELD             52L
   #define  EOF_FIELD                          53L
   #define  REPKEY_CUTOFF_FIELD                54L
   #define  NEXTVIEW_IN_RING_FIELD             55L
   #define  PREVVIEW_IN_RING_FIELD             56L
   #define  NEXTVIEW_OF_FILE_FIELD             57L
   #define TYPINGCLASS1_FIELD                  58L
   #define TYPINGCLASS2_FIELD                  59L
   #define TYPINGCLASSVAL1_FIELD               60L
   #define TYPINGCLASSVAL2_FIELD               61L
   #define CURRENTVIEW_OF_FILE_FIELD           62L
   #define FILEINFO_FIELD                      63L

   // Constants to be used with EtkProcessEditKey().
   #if 1
     #define  ETK_ADJUST_BLOCK              210
     #define  ETK_BACKTAB                   211
     #define  ETK_BACKTAB_WORD              212
     #define  ETK_BEGIN_LINE                213
     #define  ETK_BOTTOM                    214
     #define  ETK_COPY_MARK                 215
     #define  ETK_DELETE_CHAR               216
     #define  ETK_DELETE_LINE               217
     #define  ETK_DELETE_MARK               218
     #define  ETK_DOWN                      219
     #define  ETK_END_LINE                  220
     #define  ETK_ERASE_END_LINE            221
     #define  ETK_INSERT_LINE               222
     #define  ETK_INSERT_TOGGLE             223
     #define  ETK_JOIN                      224
     #define  ETK_LEFT                      225
     #define  ETK_MARK_BLOCK                226
     #define  ETK_MARK_CHARG                227
     #define  ETK_MARK_CHAR                 228
     #define  ETK_MARK_LINE                 229
     #define  ETK_MOVE_MARK                 230
     #define  ETK_NEXT_FILE                 231
     #define  ETK_OVERLAY_BLOCK             232
     #define  ETK_PAGE_DOWN                 233
     #define  ETK_PAGE_UP                   234
     #define  ETK_PREVFILE                  235
     #define  ETK_REFLOW                    236
     #define  ETK_REPEAT_FIND               237
     #define  ETK_RIGHT                     238
     #define  ETK_RUBOUT                    239
     #define  ETK_SHIFT_LEFT                240
     #define  ETK_SHIFT_RIGHT               241
     #define  ETK_SPLIT                     242
     #define  ETK_TAB                       243
     #define  ETK_TAB_WORD                  244
     #define  ETK_TOP                       245
     #define  ETK_UNDO                      246
     #define  ETK_UNMARK                    247
     #define  ETK_UP                        248
   #endif

   //Line terminator constants
   #define MAXLNSIZE_UNTERMINATED 1
   #define CR_TERMINATED          2
   #define LF_TERMINATED          3
   #define CRLF_TERMINATED        4
   #define CRCRLF_TERMINATED      5
   #define NULL_TERMINATED        6
   #define CTRLZ_TERMINATED       7
   #define NOMOREDATA_TERMINATED  8
   #define INHERITED_TERMINATED   9
   #define CRLFEOF_TERMINATED    10


   #define CR_TERMINATOR_LDFLAG           1  // Use CR as a terminator
   #define LF_TERMINATOR_LDFLAG           2  // Use LF as a terminator
   #define CRLF_TERMINATOR_LDFLAG         4  // Use CR,LF as a terminator
   #define CTRLZ_TERMINATOR_LDFLAG        8  // Use EOF as a terminator
   #define NULL_TERMINATOR_LDFLAG        16  // Use NULL as a terminator
   #define TABEXP_LDFLAG                 32  // Expand tabs when loading
   #define CRLFEOF_TERMINATOR_LDFLAG     64  // Use CR,LF,EOF as a terminator
   #define CRCRLF_TERMINATOR_LDFLAG     128  // Use CR,CR,LF as a terminator
   #define NOHEADER_LDFLAG              256  // Buffer has no header
   #define NEW_BITS_LDFLAG              512  // Format flag is using these bits
   #define STRIP_SPACES_LDFLAG         1024  // Strip trailing spaces when loading
   #define IGNORE_STORED_FORMAT_LDFLAG 2048  // Don't use format flags saved in buffer header
   #define FORCE_TERMINATOR_LDFLAG     4096  // Require a terminator after every line


   #define EWINDOWCLASS      "EtkEditClass"
   #define CLIENTWINDOWCLASS "EtkClientClass"

   //The number of bytes reversed in the EMLE class for window words
   #define EMLEWNDWORDCOUNT 16
   #define EMLECLIENTWNDWORDCOUNT (EMLEWNDWORDCOUNT+8)

   // Assistance for dynamic subclassing
   #define EMLEWNDWORDIDX_DYNAMICSUBCLASS 8

   typedef struct _dysub * PDYSUBSTRUCT;
   typedef struct _dysub {
      LONG  cbSize;
      PFNWP pfnwpNextProc;
      PFNWP pfnwpSelfProc;
      PDYSUBSTRUCT pdssNext;
      LONG  idSelf;          // also base message
   } DYSUBSTRUCT;


   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Application structure passed to editor                             GC 7-88 บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/

   // EWindowCreationErrorCodes
   #define EWCEC_OUTOFRESOURCES1    1
   #define EWCEC_OUTOFRESOURCES2    2
   #define EWCEC_OUTOFRESOURCES3    3
   #define EWCEC_LIF_EXNOTFOUND     103
   #define EWCEC_LIF_EXBADVERSION   104
   #define EWCEC_LIF_OUTOFRESOURCES 105

   typedef struct _EDITORINFO {
      USHORT Size;         // Size of structure field
      USHORT ErrCode;
      PSZ    FileName;     // file to be edited (with wildcard)
      ULONG  EditorStyle;  // internal editor options
      PSZ    ExFile;       // pre-compiled macro code file (EPM.EX)
      PSZ    TopMkr;       // top and bottom of file marker
      PSZ    BotMkr;       //
      PSZ    ExSearchPath; // a set of paths to search for ex's files
      PSZ    ExePath;     // path where the application started
   } EDITORINFO;
   typedef EDITORINFO  *PEDITORINFO;
   typedef EDITORINFO  EDITWNDCTRLDATA;
   typedef PEDITORINFO PEDITWNDCTRLDATA;

#ifdef LPCOMMENTS
   typedef struct _CHARSET {
      char * name;            // string containing all the char..
   } CHARSET;
   typedef CHARSET * PCHARSET;

   typedef struct _SPECIALCHAR {
      char     character;
      BOOL     owncolor;    // True if it is not using bgcolor and fgcolor (for break characters)
      LONG     bgcolor;
      LONG     fgcolor;
   } SPECIALCHAR;
   typedef SPECIALCHAR * PSPECIALCHAR;

   typedef struct _KEYWORD {
      char   * name;
      LONG     bgcolor;
      LONG     fgcolor;
   } KEYWORD;
   typedef KEYWORD * PKEYWORD;

   typedef struct _DELIM {
      char *  start;
      char *  end;
      char    escape;
      LONG    bgcolor;
      LONG    fgcolor;
      ULONG   column;
   } DELIM;
   typedef DELIM * PDELIM;

   typedef struct _KEYWORDSINFO {
      PCHARSET     kwCharSet;    // array[1]:   string containing the characters of the keywords of the "keywords" array
      ULONG        nbCharSet;    // right now array with just 1 element, but we may want to have several char sets, who knows?
      PSPECIALCHAR kwEndChar;    // array[] keyword end characters with their associated colors
      ULONG        nbEndChar;
      char *       pszEndChar;   // string with the end characters only
      PSPECIALCHAR kwBreakChar;  // array[] keyword break characters with their associated colors
      ULONG        nbBreakChar;
      char *       pszBreakChar; // string with the break characters only
      PKEYWORD     keywords;     // array[] case sensitive keywords
      ULONG        nbKeywords;
      PKEYWORD     keywordsi;    // array[] case insensitive keywords
      ULONG        nbKeywordsi;
      PKEYWORD     specialKW;    // array[]
      ULONG        nbSpecialKW;
      PKEYWORD     specialKWi;   // array[]
      ULONG        nbSpecialKWi;
      PDELIM       delim;      // array[]
      ULONG        nbDelim;
      PDELIM       delimi;     // array[]
      ULONG        nbDelimi;
      PCHAR        baseStringAddr; // All the strings referenced are in the same memory bank, this is its base address
      BOOL         keywordsFileLoaded;    // GLS true if the keywords file has been loaded
      BOOL         keywordsFileLoading;   // GLS true if the keywords file is being loaded
      PCHAR        kwFileName;
   } KEYWORDSINFO;
   typedef KEYWORDSINFO * PKEYWORDSINFO;

#endif // LPCOMMENTS

   /*อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
   บ Function Prototypes                                                        บ
   ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ*/
   #if OS2VERSION < 20
      //#define ETKENTRY _loadds
      #define ETKENTRY _loadds _cdecl
   #else
      /* #define ETKENTRY */
      #define ETKENTRY _System
   #endif
   #include <mainx.h>
   #include <attr.h>


   #define pszETKWINDOWCLASS "EtkEditClass"
   #define plsETKWINDOWCLASS CONSTPLSTRING("\14",pszETKWINDOWCLASS)



   #define pszETKCLIENTWINDOWCLASS "EtkClientClass"
   #define plsETKCLIENTWINDOWCLASS CONSTPLSTRING("\16",pszETKCLIENTWINDOWCLASS)



   USHORT ETKENTRY EtkCreate( PEDITORINFO epm_p, PHWND hEwnd_p);
   USHORT ETKENTRY EtkDestroy( HAB hab, HWND hwnd, HWND hwndef);
   VOID   ETKENTRY EtkVersion( PSZ strbuffer );
   #if OS2VERSION >= 20
      typedef VOID   APIENTRY ETKGETPROCADDRS(PFN * fptr);
   #else
      typedef VOID   ETKENTRY ETKGETPROCADDRS(PFN * fptr);
   #endif
   typedef ETKGETPROCADDRS * PETKGETPROCADDRS;
   #define ETKGPA_STRING  "_EtkGetProcAddrs"
   ETKGETPROCADDRS EtkGetProcAddrs;
   #define TERMTYPE BYTE
   typedef BYTE * PTERMTYPE;


   PSZ     ETKENTRY EtkRegisterEMLEClass(HAB hab);
   PSZ     ETKENTRY EtkRegisterEMLEClientClass(HAB hab);


   // Window Procedure
   PVOID  EXPENTRY EtkWndProc(HWND hwnd, USHORT message, MPARAM lParam1, MPARAM lParam2 );

   // Special Access Functions.
   USHORT ETKENTRY EtkRegisterFont( HWND  hwndClient, PLSTRING fontname, USHORT  fontsize, USHORT  fontsel);
   USHORT ETKENTRY EtkRegisterFont2(HWND  hwndClient, PLSTRING fontname, USHORT  fontsize, USHORT  fontheight, USHORT  fontwidth, USHORT  fontsel);
   SHORT  ETKENTRY EtkProcessEditKey( HWND  hwndClient, SHORT  key, USHORT repcount);
   SHORT  ETKENTRY EtkQueryFileID( HWND hwndClient, PULONG  fileid);
   SHORT  ETKENTRY EtkQueryLineTerminator( HWND hwndClient, FIDTYPE getFileid, LINE_INDEX_FR linenum, PTERMTYPE termtype );
   SHORT  ETKENTRY EtkChangeLineTerminator( HWND hwndClient, FIDTYPE getFileid, LINE_INDEX_FR linenum, TERMTYPE termtype );
   SHORT  ETKENTRY EtkDeleteText( HWND  hwndClient, ULONG  thefileid, ULONG  y, ULONG  number_oflines);
   SHORT  ETKENTRY EtkReplaceText( HWND  hwndClient, FIDTYPE  repFileid, LINE_INDEX_FR  repLocLinenum, PPATTRSTRING  repLineString, TERMTYPE terminator);
   SHORT  ETKENTRY EtkInsertText( HWND  hwndClient, FIDTYPE  insFileid, LINE_INDEX  insLocLinenum, PPATTRSTRING  insLineString, TERMTYPE terminator);
   SHORT  ETKENTRY EtkQueryText(HWND hwndClient, ULONG getFileid, ULONG getLocLinenum, PLSTRING *getText, ATTRIBRECTYPE  *  * getAttrs, ATTRIBRECTYPE  *  * getALAttr);
   SHORT  ETKENTRY EtkFindAttribute( HWND hwndClient, FIDTYPE fileid, LINE_INDEX_FR TheLineNm, SHORT TheColm, SHORT TheOfst, PPATTRIBRECTYPE TheAttribute, PBOOL Found);
   SHORT  ETKENTRY EtkSetSelection( HWND  hwndClient, LINE_INDEX_FR  firstline,  LINE_INDEX_FR  lastline, USHORT firstcol, USHORT lastcol, SHORT  firstoff, SHORT  lastoff, USHORT marktype, FIDTYPE fileid);
   SHORT  ETKENTRY EtkQuerySelection(HWND hwndClient, PLINE_INDEX firstline, PLINE_INDEX lastline, PSHORT firstcol, PSHORT lastcol, PFIDTYPE markfileid, USHORT respectattributes, USHORT relative2file);
   SHORT  ETKENTRY EtkQuerySelectionType(HWND hwndClient, PUSHORT marktype);
   SHORT  ETKENTRY EtkQueryInsertState(HWND hwndClient, PUSHORT insertstate);
   SHORT  ETKENTRY EtkSetFileField(HWND hwndClient, ULONG field, VIDTYPE fileid,  PVOID indata);
   SHORT  ETKENTRY EtkQueryFileField( HWND hwndClient, ULONG field, VIDTYPE fileid, PLONG retdata);
   SHORT  ETKENTRY EtkExecuteCommand(HWND hwndClient, PSZ command);
   SHORT  ETKENTRY EtkQueryFileFieldString(HWND hwndClient, ULONG field, ULONG getFileid, PLSTRING getText);
   LONG   ETKENTRY EtkInsertTextBuffer( HWND  hwndClient, LINE_INDEX_FR line, ULONG LenText, PSZ buffer, USHORT BufStyle);
   ULONG  ETKENTRY EtkQueryTextBuffer( HWND  hwndClient, FIDTYPE fileid, LINE_INDEX_FR startline, LINE_INDEX_FR lastline, ULONG TotalLen, PSZ buffer);
   SHORT  ETKENTRY EtkAccessLowLevelData( HWND  hwndClient, FIDTYPE  getFileid, PVOID  *  getSubLineArray);
   SHORT  ETKENTRY EtkGetPMInfo(HWND hwnd, SHORT which, PULONG retval);
   SHORT  ETKENTRY EtkInvalidateText( HWND  hwndClient, LINE_INDEX_FR firstline, LINE_INDEX_FR lastline);

   SHORT  ETKENTRY EtkFindArray(HWND hwnd, PLSTRING ArrayName, FIDTYPE *FoundArrayID);
   SHORT  ETKENTRY EtkCreateArray(HWND hwnd, PLSTRING ArrayName, FIDTYPE *RetFileid);
   VOID   ETKENTRY EtkSetArrayElement(HWND hwnd, FIDTYPE TheViewID, PLSTRING Index, PLSTRING AssignedValue);
   SHORT  ETKENTRY EtkGetArrayElement(HWND hwnd, FIDTYPE TheViewID, PLSTRING Index, PPLSTRING RetString);
   SHORT  ETKENTRY EtkDeleteArrayElement( HWND hwnd, FIDTYPE TheViewID, PLSTRING Index);

   SHORT  ETKENTRY EtkAssignAttributeClass( HWND hwndClient, PLSTRING ClassName, PLSTRING ClassModel, SHORT classid);
   SHORT  ETKENTRY EtkRegisterAttributeClass( HWND hwndClient, PLSTRING ClassName, PLSTRING ClassModel);
   SHORT  ETKENTRY EtkQueryAttributeClassID( HWND hwndClient, SHORT classid, PPLSTRING ClassName, PPLSTRING ClassModel);

   LONG   ETKENTRY EtkMapPointLCO2Window( HWND hwndClient, FIDTYPE  fileid, LONG  Line, SHORT  Col, SHORT  Off, PLONG   yOut,  PLONG xOut);
   LONG   ETKENTRY EtkMapPointWindow2LCO( HWND hwndClient, FIDTYPE  fileid, LONG   yIn,  LONG xIn, PLONG  Line, PSHORT  Col, PSHORT  Off);
   LONG   ETKENTRY EtkMapPointDoc2LCO( HWND hwndClient, FIDTYPE fileid, LONG xIn,   LONG yIn, LINE_INDEX * Line, PSHORT Col, PSHORT Off);
   LONG   ETKENTRY EtkMapPointWindow2Doc( HWND hwndClient, FIDTYPE fileid, LONG xIn,   LONG yIn, PLONG DocX, PLONG DocY);
   LONG   ETKENTRY EtkMapPointDoc2Window( HWND hwndClient, FIDTYPE  fileid, LONG  DocX,    LONG  DocY, PLONG  xIn,    PLONG  yIn);
   LONG   ETKENTRY EtkMapPointLCO2Doc(  HWND hwndClient, FIDTYPE  fileid, LINE_INDEX  Line, SHORT  Col, SHORT  Off, PLONG  xIn,    PLONG  yIn);
   LONG   ETKENTRY EtkSort( HWND  hwndClient, FIDTYPE  fileid, LINE_INDEX_FR  firstline, LINE_INDEX_FR  lastline, SHORT  begin_column, SHORT  end_column, LONG  options );
   ULONG  EXPENTRY EtkBuildNextPage( PVOID pPrnInfo );
   ULONG  EXPENTRY EtkSetupPrint( HWND hwndClient, PVOID PrnInfo,
                                  FIDTYPE ftFile, PPRINTJOB pPJ, HPS hps );
#ifdef  LPCOMMENTS
   VOID   ETKENTRY EtkFreeKeywordsInfo( PKEYWORDSINFO kwInfo );
#endif // LPCOMMENTS


 /* - Id numbers used by macros to idenify certian handles in the EPM editor */
#define ANCHORBLOCK      0
#define OWNERCLIENT      1
#define OWNERFRAME       2
#define PARENTCLIENT     3
#define PARENTFRAME      4
#define EDITCLIENT       5
#define EDITFRAME        6
#define EDITSTATUSAREA   7
#define EDITMSGAREA      8
#define EDITVSCROLL      9
#define EDITHSCROLL      10
#define EDITINTERPRETER  11
#define EDITVIOPS        12
#define EDITTITLEBAR     13
#define EDITCURSOR       14
#define PARTIALTEXT      15
#define EDITEXSEARCHPATH 16
#define EDITMENU         17
#define EDITHDC          18
#define EDITINIHANDLE    19
#define ROTATEBUTTONS    20
#define DMTITLEBAR       21
#define FILEICON         22
#define STATUSONTOP      23
#define STREAMEDIT       24
#define CUAMARKING       25
#define ARROWKEYS        26
#define EDITSTATUSHWND   27
#define EDITMSGHWND      28
#define LSLENGTH         29
#define SEARCHPOS        30


#define EPM_DM_COLOR  1
#define EPM_DM_EDIT   2
                         // 1 attributes (color supported),
                         // 2 attributes (editing supported)
#define EPM_DM_FONT   4
                         // 0 treat characters as all one font
                         //   force that font to have fixed block
                         //   align text into a single column
                         //   + formatting calculations for
                         //     complex display may continue in
                         //     background so that when user
                         //     switches to complex mode, the
                         //     formatting is already done.
                         // 1 don't make/force the above assumptions
                         //     when displaying text.
                         //
#define GETPROC_ETKVERSION              0
#define GETPROC_ETKREGEMLECLASS         1
#define GETPROC_ETKREGEFRAMECLASS       2
#define GETPROC_ETKREGEMLECLIENTCLASS   3

#define DOSCOLOR_BLACK                    0
#define DOSCOLOR_BLUE                     1
#define DOSCOLOR_GREEN                    2
#define DOSCOLOR_CYAN                     3
#define DOSCOLOR_RED                      4
#define DOSCOLOR_MAGENTA                  5
#define DOSCOLOR_BROWN                    6
#define DOSCOLOR_LIGHT_GREY               7
#define DOSCOLOR_DARK_GREY                8
#define DOSCOLOR_LIGHT_BLUE               9
#define DOSCOLOR_LIGHT_GREEN             10
#define DOSCOLOR_LIGHT_CYAN              11
#define DOSCOLOR_LIGHT_RED               12
#define DOSCOLOR_LIGHT_MAGENTA           13
#define DOSCOLOR_YELLOW                  14
#define DOSCOLOR_WHITE                   15

#endif

