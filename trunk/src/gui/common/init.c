/****************************** Module Header *******************************
*
* Module Name: init.c
*
* Generic routines for accessing text ini files
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: init.c,v 1.3 2006-08-28 16:52:50 aschn Exp $
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

#define INCL_DOS
#define INCL_ERRORS
#include <os2.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "init.h"

// define max line size (+ LF + ZEROBYTE)
#define MAX_LINESIZE         (512 + 2)
#define CHARS_COMMENT        ";"
#define CHARS_DELIMITER      "="

#define STR_COMMENT          "//"
#define CHAR_SECTION_START   '['
#define CHAR_SECTION_END     ']'

// ---- init file data entities
//      all PSZs point to malloced memory (strdup)
//      same applies to "first" and "next" fields

typedef struct _KEY
   {
         PSZ            pszKeyName;
         PSZ            pszKeyValue;
         PSZ            pszComment;
         PSZ            pszValueComment;
         PSZ            pszTailComment;
         CHAR           chDelimiter;
         ULONG          ulKeyIndent;
         ULONG          ulKeyNameLen;
         ULONG          ulValueIndent;
         ULONG          ulValueCommentIndent;
  struct _KEY          *pkeyNext;
   } KEY, *PKEY;

typedef struct _SECTION
   {
         PSZ            pszSectionName;
         PSZ            pszComment;
         PSZ            pszTailComment;
         PKEY           pkeyFirst;
  struct _SECTION      *psectionNext;
   } SECTION, *PSECTION;

// ---- global init file description structure
//      pointer mapped to HINIT

typedef struct _INIT
   {
         FILE           *pfile;
         CHAR           szFilename[ _MAX_PATH];
         ULONG          ulOpenMode;
         ULONG          ulUpdateMode;
         BOOL           fModified;
         CHAR           chDelimiter;
         CHAR           chComment;
         PSECTION       psectionFirst;
         KEY            keyLast;
   } INIT, *PINIT;

// ######################################################################

static PSZ _stripblanks( PSZ string)
{
 PSZ p = string;
 if (p != NULL)
    {
    while ((*p != 0) && (*p <= 32))
       { p++;}
    strcpy( string, p);

    p = string;
    if (*p != 0)
       {
       p += strlen(p) - 1;
       while ((*p <= 32) && (p >= string))
          {
          *p = 0;
          p--;
          }
       }
    }

return string;
}

// ----------------------------------------------------------------------

static PSZ _skipblanks( PSZ string)
{
 PSZ p = string;
 if (p != NULL)
    {
    while ((*p != 0) && (*p <= 32))
       { p++;}
    }

return p;
}

// ######################################################################

static VOID _freeKEY( PKEY pkey)
{
if (pkey)
   {
   if (pkey->pszKeyName)      free( pkey->pszKeyName);
   if (pkey->pszKeyValue)     free( pkey->pszKeyValue);
   if (pkey->pszComment)      free( pkey->pszComment);
   if (pkey->pszValueComment) free( pkey->pszValueComment);
   if (pkey->pszTailComment)  free( pkey->pszTailComment);

   _freeKEY( pkey->pkeyNext);
   memset( pkey, 0, sizeof( KEY));
   free( pkey);
   }
}

static VOID _freeSECTION( PSECTION psec)
{
if (psec)
   {
   if (psec->pszSectionName)  free( psec->pszSectionName);
   if (psec->pszComment)      free( psec->pszComment);
   if (psec->pszTailComment)  free( psec->pszTailComment);

   _freeKEY( psec->pkeyFirst);
   _freeSECTION( psec->psectionNext);
   memset( psec, 0, sizeof( SECTION));
   free( psec);
   }
}

static VOID _freeINIT( PINIT pinit)
{
if (pinit)
   {
   if (pinit->pfile)          fclose( pinit->pfile);

   _freeSECTION( pinit->psectionFirst);
   memset( pinit, 0, sizeof( INIT));
   free( pinit);
   }
}

// ----------------------------------------------------------------------

static APIRET _writeKEY( FILE *pfile, PKEY pkey, ULONG ulUpdateMode)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

if (pkey)
   {
   if (!(ulUpdateMode & INIT_UPDATE_DISCARDCOMMENTS))
      fprintf( pfile, "%s", pkey->pszComment);

   for (i = 0; i < pkey->ulKeyIndent; i++)
      {
      fprintf( pfile, " ");
      }

   fprintf( pfile, "%-*s%c",
            pkey->ulKeyNameLen,
            pkey->pszKeyName,
            pkey->chDelimiter);

   for (i = 0; i < pkey->ulValueIndent; i++)
      {
      fprintf( pfile, " ");
      }
   fprintf( pfile, "%s", pkey->pszKeyValue);

   if (pkey->pszValueComment)
      {
      for (i = 0; i < pkey->ulValueCommentIndent; i++)
         {
         fprintf( pfile, " ");
         }
      fprintf( pfile, "%s", pkey->pszValueComment);
      }

   fprintf( pfile, "\n");

   if (pkey->pszTailComment)
      fprintf( pfile, "%s", pkey->pszTailComment);

   _writeKEY( pfile, pkey->pkeyNext, ulUpdateMode);
   }

return rc;
}


static APIRET _writeSECTION( FILE *pfile, PSECTION psec, ULONG ulUpdateMode)
{
         APIRET         rc = NO_ERROR;

if (psec)
   {
   if (!(ulUpdateMode & INIT_UPDATE_DISCARDCOMMENTS))
      fprintf( pfile, "%s", psec->pszComment);
   fprintf( pfile, "[%s]\n", psec->pszSectionName);

   if (psec->pszTailComment)
      fprintf( pfile, "%s", psec->pszTailComment);

   _writeKEY( pfile,      psec->pkeyFirst,    ulUpdateMode);
   _writeSECTION( pfile,  psec->psectionNext, ulUpdateMode);
   }

return rc;
}

// ----------------------------------------------------------------------

static PKEY _findKEY( PSECTION psec, PSZ pszKeyName)
{
         PKEY           pkey = NULL;

if ((psec) && (pszKeyName))
   {
   pkey = psec->pkeyFirst;
   while (pkey)
      {
      if (!stricmp( pkey->pszKeyName, pszKeyName))
         break;
      pkey = pkey->pkeyNext;
      }
   }
return pkey;
}

static PSECTION _findSECTION( PINIT pinit, PSZ pszSectionName)
{
         PSECTION       psec = NULL;

if ((pinit) && (pszSectionName))
   {
   psec = pinit->psectionFirst;
   while (psec)
      {
      if (!stricmp( psec->pszSectionName, pszSectionName))
         break;
      psec = psec->psectionNext;
      }
   }
return psec;
}

// ----------------------------------------------------------------------

static APIRET _collectKEY( PSECTION psec, PSZ pszBuffer, ULONG ulBuflen, PULONG pulProfileSize)
{
         APIRET         rc = NO_ERROR;
         PKEY           pkey;

         PSZ            pszThisValue     = pszBuffer;
         ULONG          ulValueLen;
         ULONG          ulRemainingSpace = ulBuflen;

if (psec)
   {
   pkey = psec->pkeyFirst;
   *pulProfileSize = 0;
   while (pkey)
      {
      ulValueLen = strlen( pkey->pszKeyName) + 1;
      *pulProfileSize += ulValueLen;

      if (pszBuffer)
         {
         if (ulRemainingSpace < ulValueLen + 1)
            {
            rc = ERROR_BUFFER_OVERFLOW;
            break;
            }

         // store value
         strcpy( pszThisValue, pkey->pszKeyName);
         ulRemainingSpace -= ulValueLen;
         pszThisValue += ulValueLen;
         }

      // next section
      pkey = pkey->pkeyNext;

      }

   // do NOT count double zero byte - like PrfQueryProfileString
   // (*pulProfileSize)++;

   }

return rc;
}

static APIRET _collectSECTION( PINIT pinit, PSZ pszBuffer, ULONG ulBuflen, PULONG pulProfileSize)
{
         APIRET         rc = NO_ERROR;
         PSECTION       psec;

         PSZ            pszThisValue     = pszBuffer;
         ULONG          ulValueLen;
         ULONG          ulRemainingSpace = ulBuflen;

if (pinit)
   {
   psec = pinit->psectionFirst;
   *pulProfileSize = 0;
   while (psec)
      {
      ulValueLen = strlen( psec->pszSectionName) + 1;
      *pulProfileSize += ulValueLen;

      if (pszBuffer)
         {
         if (ulRemainingSpace < ulValueLen + 1)
            {
            rc = ERROR_BUFFER_OVERFLOW;
            break;
            }

         // store value
         strcpy( pszThisValue, psec->pszSectionName);
         ulRemainingSpace -= ulValueLen;
         pszThisValue += ulValueLen;
         }


      // next section
      psec = psec->psectionNext;
      }

   // do NOT count double zero byte - like PrfQueryProfileString
   // (*pulProfileSize)++;

   }

return rc;
}

// ----------------------------------------------------------------------

static PKEY _createKEY( PINIT pinit, PSECTION psec, PSZ pszKeyName, PSZ pszNewValue)
{
         PKEY           pkey = NULL;
         PKEY           pkeyLast;
         PKEY          *pkeyParent;

if (psec)
   {
   pkeyLast   = psec->pkeyFirst;
   pkeyParent = &psec->pkeyFirst;
   while (*pkeyParent)
      {
      if (pkeyLast->pkeyNext)
         pkeyLast   = pkeyLast->pkeyNext;
      pkeyParent = &((*pkeyParent)->pkeyNext);
      }

   // create new key
   pkey = malloc( sizeof( KEY));
   if (pkey)
      {
      *pkeyParent = pkey;
      memset( pkey, 0, sizeof( KEY));
      pkey->chDelimiter   = pinit->chDelimiter;
      pkey->pszComment    = strdup( "");
      pkey->pszKeyName    = strdup( pszKeyName);
      pkey->pszKeyValue = strdup( pszNewValue);
      if ((!pkey->pszKeyName) || (!pkey->pszKeyValue))
         {
         free( pkey);
         *pkeyParent = NULL;
         }

      // use ident vars either from last key of
      // this section or from last saved key of this file
      if (!pkeyLast)
         pkeyLast = &pinit->keyLast;
      pkey->ulKeyIndent   = pkeyLast->ulKeyIndent;
      pkey->ulKeyNameLen  = pkeyLast->ulKeyNameLen;
      pkey->ulValueIndent = pkeyLast->ulValueIndent;
      }
   }

return pkey;
}

static PSECTION _createSECTION( PINIT pinit, PSZ pszSectionName)
{
         PSECTION       psec = NULL;
         PSECTION      *psecParent;

if (pinit)
   {
   psecParent = &pinit->psectionFirst;
   while (*psecParent)
      {
      psecParent = &((*psecParent)->psectionNext);
      }

   // create new section
   psec = malloc( sizeof( SECTION));
   if (psec)
      {
      *psecParent = psec;
      memset( psec, 0, sizeof( SECTION));
      psec->pszComment     = strdup( "\n");
      psec->pszSectionName = strdup( pszSectionName);
      if (!psec->pszSectionName)
         {
         free( psec);
         *psecParent = NULL;
         }
      }

   }
return psec;
}

// ----------------------------------------------------------------------

static BOOL _removeKEY( PINIT pinit, PSECTION psec, PSZ pszKeyName)
{
         BOOL           fRemoved = FALSE;
         PKEY           pkey;
         PKEY          *pkeyParent;
         PSZ           *ppszLastTailComment;

         ULONG          i;
         ULONG          ulDeleteCommentLen = 0;
         ULONG          ulCommentCharsLen;
         PSZ            pszNewTailComment;

if (psec)
   {
   pkeyParent          = &psec->pkeyFirst;
   ppszLastTailComment = &psec->pszTailComment;
   pkey                = psec->pkeyFirst;
   while (pkey)
      {
      if (!stricmp( pkey->pszKeyName, pszKeyName))
         break;
      pkeyParent          = &pkey->pkeyNext;
      ppszLastTailComment = &pkey->pszTailComment;
      pkey                = pkey->pkeyNext;
      }

   if (pkey)
      {
      if (pinit->ulUpdateMode & INIT_UPDATE_SOFTDELETEKEYS)
         {
         // softdelete: add line to tail comment of key before
         // - determine len and get memory for new tail comment
         if (pkey->pszComment)
            ulDeleteCommentLen += strlen( pkey->pszComment)    + 1;

         ulDeleteCommentLen += pkey->ulKeyIndent               +
                               pkey->ulKeyNameLen              +
                               strlen(  pkey->pszKeyName)      + 1 +
                                                                 1 +  // delimter char
                               pkey->ulValueIndent             +
                               strlen(  pkey->pszKeyValue)     + 1;

         if (pkey->pszValueComment)
            ulDeleteCommentLen += strlen( pkey->pszValueComment) + 1;
         if (*ppszLastTailComment)
            ulDeleteCommentLen += strlen( *ppszLastTailComment) + 1;

         pszNewTailComment = malloc( ulDeleteCommentLen);
         if (!pszNewTailComment)
            return FALSE;

         // assemble new comment
         if (*ppszLastTailComment)
            strcpy( pszNewTailComment, *ppszLastTailComment);
         else
            *pszNewTailComment = 0;

         if (pkey->pszComment)
            strcat( pszNewTailComment, pkey->pszComment);

         if (pinit->chComment == '/')
            {
            strcat( pszNewTailComment, "//");
            ulCommentCharsLen = 2;
            }
         else
            {
            sprintf( pszNewTailComment + strlen( pszNewTailComment), "%c", pinit->chComment);
            ulCommentCharsLen = 1;
            }

         if (pkey->ulKeyIndent > ulCommentCharsLen)
            {
            for (i = 0; i < pkey->ulKeyIndent - ulCommentCharsLen; i++)
               {
               strcat( pszNewTailComment, " ");
               }
            }

         sprintf( pszNewTailComment + strlen( pszNewTailComment),
                  "%-*s%c",
                  pkey->ulKeyNameLen,
                  pkey->pszKeyName,
                  pkey->chDelimiter);

         for (i = 0; i < pkey->ulValueIndent; i++)
            {
            strcat( pszNewTailComment, " ");
            }
         sprintf( pszNewTailComment + strlen( pszNewTailComment), "%s\n", pkey->pszKeyValue);

         // replace/add new tail comment
         if (*ppszLastTailComment)
            free( *ppszLastTailComment);
         *ppszLastTailComment = pszNewTailComment;

         }

      // now delete key entry
      *pkeyParent = pkey->pkeyNext;
      memset( pkey, 0, sizeof( KEY));
      free( pkey);
      fRemoved = TRUE;

      } // if (pkey)
   }

return fRemoved;
}

static BOOL _removeSECTION( PINIT pinit, PSZ pszSectionName)
{
         BOOL           fRemoved = FALSE;
         PSECTION       psec;
         PSECTION      *psecParent;

if (pinit)
   {
   psecParent = &pinit->psectionFirst;
   psec       = pinit->psectionFirst;
   while (psec)
      {
      if (!stricmp( psec->pszSectionName, pszSectionName))
         break;
      psecParent = &psec->psectionNext;
      psec       = psec->psectionNext;
      }

   if (psec)
      {
      *psecParent = psec->psectionNext;
      memset( psec, 0, sizeof( SECTION));
      free( psec);
      fRemoved = TRUE;
      }
   }

return fRemoved;
}

// ======================================================================

APIRET InitOpenProfile( PSZ pszFilename, PHINIT phinit,
                        ULONG ulOpenMode, ULONG ulUpdateMode, PINITPARMS pip)
{
         APIRET         rc = NO_ERROR;
         PINIT          pinit = NULL;
         INITPARMS      ip;
         PSZ            p;

         PSZ            pszOpenMode;
         BOOL           fInMemory = FALSE;
         BOOL           fAllowErrors = FALSE;

static   PSZ            pszLineComment = STR_COMMENT;
static   PSZ            pszNewline     = "\n";

         PSECTION      *ppsecParentPtr = NULL;
         PSECTION       psec           = NULL;

         PKEY          *ppkeyParentPtr = NULL;
         PKEY           pkey           = NULL;

         PSZ            pszLine    = NULL;
         PSZ            pszComment = NULL;
         PSZ            pszValue;

         PSZ            pszThisDelimiter;
         PSZ            pszCheckLine;
         PSZ            pszValueComment;

do
   {
   // check parms
   if (!phinit)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check special bits of open mode
   if (ulOpenMode != INIT_OPEN_INMEMORY)
      {
      if (ulOpenMode & INIT_OPEN_ALLOWERRORS)
         {
         fAllowErrors = TRUE;
         ulOpenMode &= ~INIT_OPEN_ALLOWERRORS;
         }
      }

   // check open modes
   switch (ulOpenMode)
      {
      case INIT_OPEN_READONLY:  pszOpenMode = "r";            break;
      case INIT_OPEN_READWRITE: pszOpenMode = "r+";           break;
      case INIT_OPEN_INMEMORY:  fInMemory = TRUE;             break;
      default:                  rc = ERROR_INVALID_PARAMETER; break;
      }
   if (rc != NO_ERROR)
      break;

   // filename required, if it is not an in-memory init only
   // for in-memory operatin, filename must be NULL
   if (((!fInMemory) && (!pszFilename)) ||
       ((fInMemory) && (pszFilename)))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }



   // use defaults
   if (!pip)
      {
      memset( &ip, 0, sizeof( ip));
      pip = &ip;
      }

   if (!pip->pszCommentChars)
      pip->pszCommentChars = CHARS_COMMENT;
   if (!pip->pszDelimiterChars)
      pip->pszDelimiterChars = CHARS_DELIMITER;

   // check memory for temporary fields
   pszLine    = malloc( MAX_LINESIZE);
//   pszComment = malloc( 2 * MAX_LINESIZE);     <--- Bug: pszComment is concatenated and is set to an entire header
   pszComment = malloc( 20 * MAX_LINESIZE);  // quick and dirty
   if ((!pszLine) || (!pszComment))
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   *pszLine = 0;
   *pszComment = 0;

   // get memory for data struct
   pinit = malloc( sizeof( INIT));
   if (!pinit)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pinit, 0, sizeof( INIT));
   if (!fInMemory)
      strcpy( pinit->szFilename, pszFilename);
   pinit->ulOpenMode            = ulOpenMode;
   pinit->ulUpdateMode          = ulUpdateMode;
   pinit->chComment             = *(pip->pszCommentChars);
   pinit->chDelimiter           = *(pip->pszDelimiterChars);
   pinit->keyLast.ulKeyIndent   = pip->ulKeyIndent;
   pinit->keyLast.ulKeyNameLen  = pip->ulKeyNameLen;
   pinit->keyLast.ulValueIndent = pip->ulValueIndent;


   // --------------------------------------------------------

   // do not read a file, if it is an in-memory init
   if (fInMemory)
      {
      // report pointer as handle
      *phinit = (HINIT) pinit;
      break;
      }

   // --------------------------------------------------------

   // store address for ptr to first section
   ppsecParentPtr = &pinit->psectionFirst;

   // open the file
   pinit->pfile = fopen( pszFilename, pszOpenMode);

   // second try in write mode
   if ((!pinit->pfile) && (ulOpenMode == INIT_OPEN_READWRITE))
      pinit->pfile = fopen( pszFilename, "w+");

   if (!pinit->pfile)
      {
      rc = ERROR_OPEN_FAILED;
      break;
      }

   while (!feof( pinit->pfile))
      {
      // read line
      if (!fgets( pszLine, MAX_LINESIZE, pinit->pfile))
         break;

      // - - - - - - - - - - - - - - - - - - - -

      // handle comments and empty lines
      pszCheckLine = _skipblanks( pszLine);

      if (strchr( pip->pszCommentChars, * pszCheckLine))
         {

         // extra check for C++ comments
         if ((*pszCheckLine != '/') || (*(pszCheckLine + 1) == '/'))
            {
            strcat( pszComment, pszLine);
            continue;
            }
         }
      if (!strncmp( pszCheckLine, pszNewline, strlen( pszNewline)))
         {
         strcat( pszComment, pszLine);
         continue;
         }

      // cut off NEWLINE
      *(pszLine + strlen( pszLine) - 1) = 0;

      // handle new section
      if (*pszLine == CHAR_SECTION_START)
         {
         strcpy( pszLine, pszLine + 1);
         p = strchr( pszLine, CHAR_SECTION_END);
         if (!p)
            {
            if (fAllowErrors)
               continue;
            else
               {
               rc = ERROR_INVALID_DATA;
               break;
               }
            }
         *p = 0;

         // open a new section
         psec = malloc( sizeof( SECTION));
         if (!psec)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         memset( psec, 0, sizeof( SECTION));
         *ppsecParentPtr = psec;
         ppsecParentPtr = &psec->psectionNext;

         psec->pszSectionName = strdup( pszLine);
         psec->pszComment     = strdup( pszComment);
         if ((!psec->pszSectionName) ||
             (!psec->pszComment))
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         *pszComment = 0;

         // store address for ptr to first key
         ppkeyParentPtr = &psec->pkeyFirst;

         // we are done so far
         continue;

         }

      // - - - - - - - - - - - - - - - - - - - -

      // handle new key
      if (!ppkeyParentPtr)
         {
         rc = ERROR_INVALID_DATA;
         break;
         }

      // open a new key
      pkey = malloc( sizeof( KEY));
      if (!pkey)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      memset( pkey, 0, sizeof( KEY));
      *ppkeyParentPtr = pkey;
      ppkeyParentPtr = &pkey->pkeyNext;

      // handle all specified delimter characters like ':' and '='
      pszThisDelimiter = pip->pszDelimiterChars;
      pszValue         = NULL;
      while ((*pszThisDelimiter) && (!pszValue))
         {
         pszValue = strchr( pszLine, *pszThisDelimiter);
         pkey->chDelimiter = *pszThisDelimiter;
         pszThisDelimiter++;
         }
      if (!pszValue)
         {
         if (fAllowErrors)
            continue;
         else
            {
            rc = ERROR_INVALID_DATA;
            break;
            }
         }

      // store key data
      pkey->pszComment    = strdup( pszComment);

      pkey->ulKeyIndent   = _skipblanks( pszLine) - pszLine;

      pkey->pszKeyValue   = strdup(  pszValue + 1);
      pkey->ulValueIndent = _skipblanks( pkey->pszKeyValue)- pkey->pszKeyValue;
      strcpy( pkey->pszKeyValue, pkey->pszKeyValue + pkey->ulValueIndent);

      *pszValue = 0;
      pkey->ulKeyNameLen  = strlen( pszLine) -  pkey->ulKeyIndent;
      pkey->pszKeyName    = strdup( _stripblanks( pszLine));

      if ((!pkey->pszKeyName)  ||
          (!pkey->pszKeyValue) ||
          (!pkey->pszComment))
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      *pszComment = 0;

      // take care for c++ comments at the end of a key value
      // create a copy and detach it from the key value
      if (strchr( pip->pszCommentChars, '/'))
         {
         pszValueComment = strstr( pkey->pszKeyValue, "//");
         if (pszValueComment)
            {
               pkey->pszValueComment = strdup( pszValueComment);
            p = pszValueComment - 1;
            while (*p <= 32)
               {
               p--;
               }
            pkey->ulValueCommentIndent = pszValueComment - p - 1;
            *(p + 1) = 0;
            }
         }

      // take care for multiline values, being enclosed in double quotes
      if (*pkey->pszKeyValue == '"')
         while (*(pkey->pszKeyValue + strlen( pkey->pszKeyValue) - 1) != '"')
            {
            // read next line
            if (!fgets( pszLine, MAX_LINESIZE, pinit->pfile))
               break;
            _stripblanks( pszLine);

            pkey->pszKeyValue = realloc( pkey->pszKeyValue, strlen( pkey->pszKeyValue) + strlen( pszLine) + 1);
            strcat( pkey->pszKeyValue, pszLine);
            }

      // save key data for appending new sections and keys
      memcpy( &pinit->keyLast, pkey, sizeof( KEY));

      } // while (!feof( pinit->pfile))

   // take care for errors
   if (rc != NO_ERROR)
      break;

   // --------------------------------------------------------

   // report pointer as handle
   *phinit = (HINIT) pinit;

   } while (FALSE);

// cleanup
if (rc != NO_ERROR)
   _freeINIT( pinit);
if (pszLine)    free( pszLine);
if (pszComment) free( pszComment);
return rc;
}

// ----------------------------------------------------------------------

APIRET InitCloseProfile( HINIT hinit, BOOL fUpdate)
{
         APIRET         rc = NO_ERROR;
         PINIT          pinit = (PINIT) hinit;

do
   {
   // check parms
   if (!hinit)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // update not required ?
   if ((!pinit->fModified) ||
       (!fUpdate)          ||
       (pinit->ulOpenMode != INIT_OPEN_READWRITE) ||
       (!pinit->pfile))
      break;

   // goto start of file
   rewind( pinit->pfile);
   DosSetFileSize( fileno( pinit->pfile), 0);
   _writeSECTION( pinit->pfile, pinit->psectionFirst, pinit->ulUpdateMode);
   fprintf( pinit->pfile, "\n");

   } while (FALSE);

// cleanup
if (rc == NO_ERROR)
   _freeINIT( pinit);
return rc;
}

// ----------------------------------------------------------------------

APIRET InitCloseProfileBackup( HINIT hinit, BOOL fUpdateOriginal, PSZ pszBackupFile)
{
         APIRET         rc = NO_ERROR;
         PINIT          pinit = (PINIT) hinit;
         FILE          *pfile = NULL;

do
   {
   // check parms
   if (!hinit)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // in-memory init cannot be written to file
   if (!pinit->pfile)
      {
      rc = ERROR_INVALID_FUNCTION;
      break;
      }

   // backup wanted ? So we need a backup filename
   if ((!fUpdateOriginal) && (!pszBackupFile))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }


   // update not required ?
   if ((!pinit->fModified) ||
       (pinit->ulOpenMode != INIT_OPEN_READWRITE))
      break;

   // close original file anyway
   fclose( pinit->pfile);
   pinit->pfile  = NULL;

   // create backup, if original shall be rewritten
   if (fUpdateOriginal)
      {
      rc = DosCopy( pinit->szFilename, pszBackupFile, DCPY_EXISTING);
      if (rc != NO_ERROR)
         break;
      }

   // (re)open original/backup file for write
   pfile = fopen( (fUpdateOriginal) ? pinit->szFilename : pszBackupFile, "w");
   if (!pfile)
      {
      rc = ERROR_OPEN_FAILED;
      break;
      }

   // write file
   _writeSECTION( pfile, pinit->psectionFirst, pinit->ulUpdateMode);
   fprintf( pfile, "\n");

   } while (FALSE);

// cleanup
if ((!fUpdateOriginal) && (pfile))
   fclose( pfile);
if (rc == NO_ERROR)
   _freeINIT( pinit);
return rc;
}

// ----------------------------------------------------------------------

BOOL InitModified( HINIT hinit)
{
         BOOL           fResult = FALSE;
         PINIT          pinit = (PINIT) hinit;

do
   {
   // check parms
   if (!hinit)
      break;

   fResult = pinit->fModified;
   } while (FALSE);

return fResult;
}

// ----------------------------------------------------------------------

ULONG InitQueryProfileString( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName,
                                PSZ pszDefault, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          ulValueLen = 0;
         PINIT          pinit = (PINIT) hinit;

         PSECTION       psec;
         PKEY           pkey;
         PSZ            pszResult;

do
   {
   // check parms
   if ((!hinit)       ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }
   memset( pszBuffer, 0, ulBuflen);

   // find section and/or key
   if (pszSectionName)
      psec = _findSECTION( pinit, pszSectionName);
   else
      {
      rc = _collectSECTION( pinit, pszBuffer, ulBuflen, &ulValueLen);
      break;
      }

   if (pszKeyName)
      pkey = _findKEY( psec, pszKeyName);
   else
      {
      rc = _collectKEY( psec, pszBuffer, ulBuflen, &ulValueLen);
      break;
      }

   // key not found ?
   if (pkey)
      pszResult = pkey->pszKeyValue;
   else
      pszResult = pszDefault;

   // report result
   if (pszResult)
      {
      memcpy( pszBuffer, pszResult, ulBuflen);
      ulValueLen = strlen( pszBuffer) + 1;
      }

   } while (FALSE);

// cleanup
return ulValueLen;

}

// ----------------------------------------------------------------------

BOOL InitQueryProfileSize( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName, PULONG pulDatalen)
{
         APIRET         rc = NO_ERROR;
         PINIT          pinit = (PINIT) hinit;

         PSECTION       psec;
         PKEY           pkey;

do
   {
   // check parms
   if ((!hinit)        ||
       (!pulDatalen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // find section and/or key
   if (pszSectionName)
      psec = _findSECTION( pinit, pszSectionName);
   else
      {
      rc = _collectSECTION( pinit, NULL, 0, pulDatalen);
      break;
      }

   if (pszKeyName)
      pkey = _findKEY( psec, pszKeyName);
   else
      {
      rc = _collectKEY( psec, NULL, 0, pulDatalen);
      break;
      }

   if (pkey)
      *pulDatalen = strlen( pkey->pszKeyValue) + 1;
   else
      rc = ERROR_FILE_NOT_FOUND;


   } while (FALSE);

// cleanup
return (rc == NO_ERROR);

}

// ----------------------------------------------------------------------

APIRET InitWriteProfileString( HINIT hinit, PSZ pszSectionName, PSZ pszKeyName, PSZ pszNewValue)
{
         APIRET         rc = NO_ERROR;
         PINIT          pinit = (PINIT) hinit;
         PSECTION       psec;
         PKEY           pkey;

         BOOL           fNotChanged = FALSE;
         PSZ            pszOldValue;
         BOOL           fRemoved = FALSE;

do
   {
   // check parms
   if ((!hinit)           ||
       (!pszSectionName))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // find section and key
   psec = _findSECTION( pinit, pszSectionName);
   pkey = _findKEY( psec, pszKeyName);

   // key was found (thus section was found)
   // handle following situations here
   // section   keyname  keyvalue    action
   //  given     given    given      update key
   //  given     given    NULL       delete key

   // handle keys first
   if (pkey)
      {
      // create/update key
      if (pszNewValue)
         {
         if (!strcmp( pkey->pszKeyValue, pszNewValue))
            fNotChanged = TRUE;
         else
            {
            // just replace value
            pszOldValue = pkey->pszKeyValue;
            pkey->pszKeyValue = strdup( pszNewValue);
            if (!pkey->pszKeyValue)
               {
               pkey->pszKeyValue = pszOldValue;
               rc = ERROR_NOT_ENOUGH_MEMORY;
               break;
               }
            else
               free( pszOldValue);
            }
         }
      else
         {
         // remove key
         fRemoved = _removeKEY( pinit, psec, pszKeyName);
         rc = (fRemoved) ? NO_ERROR : ERROR_FILE_NOT_FOUND;
         }

      } // if (pkey)

   // key was not found
   // handle following situations here
   // section   keyname  keyvalue    action
   //  given     given    given      create section and/or key

   // shall a new section and/or key be created ?

   else if (pszNewValue)
      {
      if (!psec)
         {
         // add new section if required
         psec = _createSECTION( pinit, pszSectionName);
         if (!psec)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         }

      // add new key
      pkey = _createKEY( pinit, psec, pszKeyName, pszNewValue);
      if (!pkey)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      }

   // handle following situations here
   // section   keyname  keyvalue    action
   //  given     NULL     NULL       delete section

   else if (!pszKeyName)
      {
      // keyName not given, delete section
      fRemoved = _removeSECTION( pinit, pszSectionName);
      rc = (fRemoved) ? NO_ERROR : ERROR_FILE_NOT_FOUND;
      }

   else
      // this occurs, when a key should be deleted,
      // that does not exist
      rc = ERROR_FILE_NOT_FOUND;

   } while (FALSE);

// check if something has been modified
if ((pinit) && (rc == NO_ERROR) && (!fNotChanged))
   pinit->fModified = TRUE;

return rc;

}

