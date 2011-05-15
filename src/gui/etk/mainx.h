/****************************** Module Header *******************************
*
* Module Name: mainx.h
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

#ifndef MAINX_INCLUDED
   #define MAINX_INCLUDED

   typedef long LINE_INDEX_FR;  // file relative
   typedef long LINE_INDEX_G;   // global
   typedef long LINE_INDEX;     // arbitrary, or not yet categorized
   typedef LINE_INDEX * PLINE_INDEX;     // arbitrary, or not yet categorized
   #define  FIDXTYPE       SHORT
   #define  FIDTYPE        LONG
   #define  VIDXTYPE       SHORT
   #define  VIDTYPE        LONG
   #define  WIDXTYPE       SHORT
   #define  WIDTYPE        LONG
   typedef FIDTYPE *       PFIDTYPE;
   typedef VIDTYPE *       PVIDTYPE;
   typedef WIDTYPE *       PWIDTYPE;

   /* 4.103 for new buffer() opcode.  See BUFFER.C, PORTSVLD.C and SAVELINE.ASM.*/
   #define NOFORMAT        0     /* buffer is used for some unplanned purpose */
   #define APPENDCR        1     /* append ASCII 13 */
   #define APPENDLF        2     /* append ASCII 10 after the CR if any */
   #define APPENDNULL      4     /* append ASCII  0 after the CR-LF if any */
   #define TABCOMPRESS     8     /* tab-compress the line */
   #define STRIPSPACES    16     /* remove trailing spaces as usual in a save */
   #define FINALNULL      32     /* 4.112:  append final null at end of buffer*/

   #define LF_IS_NEWLINE  64     /* jbl 1/6/89:  when loading a disk file (not */
                                 /* a buffer), do we take a LF not after a CR  */
                                 /* as a newline, a la UNIX?                   */
//         <reserved>    128

// LAM:  Note that the format flag(s) is passed as a byte to init_subbuffer_loads,
// which keeps it in a byte field in a structure; NOHEADER (or any higher flags)
// will not be preserved.  Assert:  This doesn't matter for NOHEADER, since that
// structure is only used by routines that are explicitly given the start and end
// of the buffer.

   #define NOHEADER      256     /* LAM 92/11/30:  Buffer has no 32-byte hdr  */

   /* MARK TYPE CONSTANTS  */
   #define EMT_LINEMARK    0
   #define EMT_CHARMARK    1
   #define EMT_BLOCKMARK   2
   #define EMT_CHARMARKG   3
   #define EMT_BLOCKMARKG  4
   #define EMT_NOMARK     -1

#endif
