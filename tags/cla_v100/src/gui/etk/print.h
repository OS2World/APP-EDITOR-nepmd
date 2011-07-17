/****************************** Module Header *******************************
*
* Module Name: print.h
*
* Original E Toolkit header file from the EPMBBS package
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

#ifndef PRINT_INCLUDED
#define PRINT_INCLUDED
//----------------------------------------------------------------------
// The PRNINFO and EPMINFO structures are used by the print support in
// both EtkPrint() (\ETK\C\E\PRINT.C) and EIObjectProc()
// (\ETK\C\I\IOBJECT.C).  -LWS
//----------------------------------------------------------------------
#ifdef ACW_PRINT
// CALLBACK commands for PRINT dialog  *************
#define IDC_PR_PROGRESS  100
#define IDC_PR_PRNTDONE  101
#define IDC_PR_PRNTFAIL  102

// CALLBACK commands for PREVIEW dialog  ***********
#define IDC_PP_PAGEDONE  100
#define IDC_PP_FILEDONE  101
#define IDC_PP_FMTERROR  102

// MISC defines for buffer sizes
#define HEADERLEN         39
#define PRQINFO3_SIZE    (32*1024)
#define QUEUENAMELEN     127

//xxx
#define POF_RAW_TEXT        0x00000001
#define POF_JOB_PROPS       0x00000002
#define POF_WYSIWYG         0x00000004
#define POF_COLORTEXT       0x00000008
#define POF_LINEWRAP        0x00000010
#define POF_METRIC          0x00000020
#define POF_FOLIO           0x00000040
#define POF_SAVE_SETTINGS   0x00000080
#define POF_S1_PROMPT       0x00000100
#define POF_FAST_PREVIEW    0x00000200

// ---------------------------------------------------------------------------
// Printing-related STRUCTURES

typedef struct {
           LONG           firstLine;
           LONG           firstCol;
           LONG           lastLine;
           BOOL           fPrintIt;
           HMF            hmfPage;
           PVOID          nextPage;
        }
        EPAGEINFO, * PEPAGEINFO;

typedef struct {
           CHAR     szCurQueue[QUEUENAMELEN+1];              // FULL queue name
           LONG     ulCurPort;                               // index
           ULONG    flags;
           LONG     LineSpace;                               // INDEX
           SHORT    margL, margR, margT, margB;              // margins (TWP)
           SHORT    hdrTC, hdrTR, ftrBC, ftrBR;              // indices
           SHORT    DraftFont;                               // index
           SHORT    DraftFontSize;                           // PT size
           SHORT    HeaderFont;                              // index
           SHORT    HeaderFontSize;                          // PT size
           CHAR     szS1[HEADERLEN+1];                       // hdr/ftr strng
           CHAR     szS2[HEADERLEN+1];                       // ditto
        }
        PRINTOPTS, * PPRINTOPTS;

typedef struct {
           USHORT         size;
           USHORT         reserved1;
           HWND           hwndCallback;                    // prn or prvw dlg
           HWND           hwndEdit;                        // work thread
           HWND           hwndApp;                         // for HELP
           PPRINTOPTS     pOpts;                           // fetch from ini
           BOOL           fMarkedOnly;                     // printed
           BOOL           fPreview;                        // or PRINT
           PVOID          pdriv;                           // DevOpenData
           RECTL          rclPage;                         // full page
           RECTL          rclClip;                         // from FORM data
           RECTL          rclMargins;                      // user spec'd
           PEPAGEINFO     pPgInfo;                         // filled by prvw
           BOOL           fInProgress;
        }
        PRINTJOB, * PPRINTJOB;

#endif

#if 0
#ifdef INCL_ETKTYPEDEFS
typedef struct {
   HAB hab;
   HDC hdc;
   HPS hps;
   #ifndef ACW_PRINT
   RECTL rclPage;
   #endif
   DEVOPENSTRUC dosPrn;
} PRNINFO, *PPRNINFO;

typedef struct {
   PEGLOB pegGlobals;
   PPRNINFO ppiPrn;
   #ifdef ACW_PRINT
   PPRINTJOB pPrnJob;
   #endif
   FIDTYPE ftFile;
   PFILEBUFINFO ffFile;
   ATTRIBSTACKTYPE astColorStk;
   ATTRIBSTACKTYPE astFontStk;
   BYTE bFont;
   ULONG ulColor;
   LONG sLine;
   SHORT sCol;
} EPMINFO, *PEPMINFO;

#endif

#ifdef INCL_ERESTYPEDEFS
typedef struct {
   DEVOPENSTRUC dosPrn;
   HDC hdcPrn;
   HPS hpsPrn;
   SIZEL szlPrn;
   ULONG ulFileId;
   LONG sLine;
   SHORT sCol;
   BYTE bFont;
   ULONG ulColor;
} ERESPRNINFO, *PERESPRNINFO;
#endif
#endif

#endif
