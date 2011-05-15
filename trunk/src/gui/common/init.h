/****************************** Module Header *******************************
*
* Module Name: init.h
*
* Header for generic routines for accessing text ini files
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

#ifndef INIT_H
#define INIT_H

/*
 * // this api handles Win16 text ini files
 * // maximum supported line size is 512 chars
 * //
 * // When specifiying INIT_OPEN_READONLY as open mode,
 * // the fUpdate is ignored on InitCloseProfile.
 * // When specifiying INIT_OPEN_READWRTIE as open mode,
 * // the inifile is opened exclusively (DENYREADWRITE)
 * //
 * // Default comment char is ';'. You can specify more than
 * // one in pszCommentChars. Comments are valid when starting
 * // with onbe of the given comment characters at first
 * // position on the line where there is no (white)space,
 * // If '/' is specified, instead "//" as c++ style
 * // comment is checked. This one is also valid
 * // at the end of a key value.
 * // It is recommended to use ';' as the only comment
 * // character to maintain compatibility with Win16 INI files.
 * //
 * //
 * // Default delimiter between keyname and keyvalue is
 * // '='. You may want to specify any alternative.
 * // More than one delimiter can be specified, the first
 * // is used for keys in new sections. If new keys are
 * // appended to an existing section, the delimiter
 * // the last key of that section is being used.
 * // It is recommended to use '=' as the only delimiter
 * // character to maintain compatibility with Win16 INI files.
 */

typedef LHANDLE HINIT, *PHINIT;

/* define open modes */
#define INIT_OPEN_READONLY           0x0000
#define INIT_OPEN_READWRITE          0x0001

#define INIT_OPEN_ALLOWERRORS        0x8000
#define INIT_OPEN_INMEMORY           0xFFFF

/* define update modes */
#define INIT_UPDATE_DISCARDCOMMENTS  0x0001
#define INIT_UPDATE_SOFTDELETEKEYS   0x0002

// structure to override some default behaviour
typedef struct _INITPARMS
   {
         // specify all valid comment characters
         // - specify NULL to use ';' as the default and only comment character
         // - when '/' is specified, "//" will be used instead (c++ style comments)
         PSZ            pszCommentChars;

         // specify all valid delimiter characters
         // - specify NULL to use '=' as the default and only delimiter character
         // - when multiple characters are specified, the first will be used for
         //   new entries
         PSZ            pszDelimiterChars;

         // LAYOUT DEFINITION FOR NEW KEYS IN NEW SECTIONS
         //
         // [SECTION]
         //
         //      newkeyname1   =   keyvalue1
         // |   |  -> ulKeyIndent
         //
         //      newkeyname2   =   keyvalue2
         //      |            | ->  ulKeyNameLen
         //
         //      newkeyname3   =   keyvalue3
         //                     | | -> ulValueIndent

         ULONG          ulKeyIndent;
         ULONG          ulKeyNameLen;
         ULONG          ulValueIndent;
   } INITPARMS, *PINITPARMS;

/* --- prototypes --- */

/* open and close file */
APIRET InitOpenProfile( PSZ pszFilename, PHINIT phinit, ULONG ulOpenMode,
                          ULONG ulUpdateMode, PINITPARMS pip);
APIRET InitCloseProfile( HINIT hinit, BOOL fUpdate);
APIRET InitCloseProfileBackup( HINIT hinit, BOOL fUpdateOriginal, PSZ pszBackupFile);
BOOL InitModified( HINIT hinit);

/* query values */
ULONG InitQueryProfileString( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName, PSZ pszDefault, PSZ pszBuffer, ULONG ulBuflen);
BOOL InitQueryProfileSize( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName, PULONG pulDatalen);

/* update or delete keys and/or sections */
APIRET InitWriteProfileString( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName, PSZ pszNewValue);

#endif /* INIT_H */

