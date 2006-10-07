/****************************** Module Header *******************************
*
* Module Name: tmf.c
*
* Source for text message file functions
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: tmf.c,v 1.7 2006-10-07 19:53:40 aschn Exp $
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
 todo:
  - handle comments in messages
  - reset write date !

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INCL_DOS
#define INCL_ERRORS
#include "os2.h"

// disable debug messages for this module
#undef DEBUG

#include "macros.h"
#include "tmf.h"
#include "eas.h"

// ------------------------------------------------------------------------------

#define EA_TIMESTAMP "TMF.FILEINFO"
#define EA_MSGTABLE  "TMF.MSGTABLE"

#define MSG_NAME_START   "\r\n<--"
#define MSG_NAME_END     "-->:"

#define MSG_COMMENT_LINE "\r\n;"

// internal prototypes
APIRET _TmfCompileMsgTable( PSZ pszMessageFile, PBYTE * ppbTableData);
APIRET _TmfGetTimeStamp( PFILESTATUS3 pfs3, PSZ pszBuffer, ULONG ulBufferlen);
static PSZ _TmfExpandParms( PSZ pszStr, PSZ *apszParms, ULONG ulParmCount);

// ------------------------------------------------------------------------------

APIRET TmfGetMessage
         (
         PCHAR     *pTable,
         ULONG      cTable,
         PBYTE      pbBuffer,
         ULONG      cbBuffer,
         PSZ        pszMessageName,
         PSZ        pszFile,
         PULONG     pcbMsg
         )
{
         APIRET         rc = NO_ERROR;
         CHAR           szMessageFile[ _MAX_PATH];
         PBYTE          pbTableData = NULL;
         BOOL           fFound = FALSE;
         PSZ            pszEntry;
         PSZ            pszEndOfEntry;
         ULONG          ulMessagePos;
         ULONG          ulMessageLen;

         HFILE          hfile = NULLHANDLE;
         ULONG          ulFilePtr;
         ULONG          ulAction;
         ULONG          ulBytesToRead;
         ULONG          ulBytesRead;

         PSZ            pszExpanded = NULL;

do
   {

   // check parms
   if ((!pbBuffer)        ||
       (!cbBuffer)        ||
       (!pszMessageName)  ||
       (!*pszMessageName) ||
       (!*pszFile)        ||
       (!pcbMsg))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   if (cbBuffer < 2)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // reset target vars
   *pcbMsg = 0;

   // search file
   if ((strchr( pszFile, ':'))  ||
       (strchr( pszFile, '\\')) ||
       (strchr( pszFile, '/')))
      // drive and/or path given: no search in path
      strcpy( szMessageFile, pszFile);
   else
      {
      // onlfy filename, search in current dir and DPATH
      rc = DosSearchPath( SEARCH_IGNORENETERRS |
                          SEARCH_ENVIRONMENT   |
                          SEARCH_CUR_DIRECTORY,
                          "DPATH",
                          pszFile,
                          szMessageFile,
                          sizeof( szMessageFile));
      if (rc != NO_ERROR)
         break;
      }

   // compile table if neccessary
   rc = _TmfCompileMsgTable( szMessageFile, &pbTableData);
   if (rc != NO_ERROR)
      break;

   // search the name
   pszEntry = pbTableData;
   while (!fFound)
      {
      // search string
      pszEntry = strstr( pszEntry, pszMessageName);
      if (!pszEntry)
         {
         rc = ERROR_MR_MID_NOT_FOUND;
         break;
         }

      // check that it really is the name
      if (((pszEntry == pbTableData) ||
           (*(pszEntry - 1) == '\n'))   &&
           (*(pszEntry + strlen( pszMessageName)) == ' '))
         fFound = TRUE;

      // proceed to the entry data
      pszEntry += strlen( pszMessageName) + 1;
      }

   if (rc != NO_ERROR)
      break;

   // isolate entry
   pszEndOfEntry = strchr( pszEntry, '\n');
   if (pszEndOfEntry)
      *pszEndOfEntry = 0;

   // get numbers
   ulMessagePos = atol( pszEntry);
   if (ulMessagePos == 0)
   if (!pszEntry)
      {
      rc = ERROR_MR_INV_MSGF_FORMAT;
      break;
      }

   pszEntry = strchr( pszEntry, ' ');
   if (!pszEntry)
      {
      rc = ERROR_MR_INV_MSGF_FORMAT;
      break;
      }
   ulMessageLen = atol( pszEntry);


   // report "buffer too small" here, if not at least a zero byte can be appended
   if (ulMessageLen >= cbBuffer)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // determine maximum read len
   ulBytesToRead = min( ulMessageLen, cbBuffer);

   // open file and read message
   rc = DosOpen( pszFile,
                 &hfile,
                 &ulAction,
                 0, 0,
                 OPEN_ACTION_FAIL_IF_NEW |
                    OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_FLAGS_FAIL_ON_ERROR |
                    OPEN_SHARE_DENYWRITE  |
                    OPEN_ACCESS_READONLY,
                 NULL);
   if (rc != NO_ERROR)
      break;
   rc = DosSetFilePtr( hfile, ulMessagePos, FILE_BEGIN, &ulFilePtr);
   if ((rc != NO_ERROR) || (ulFilePtr != ulMessagePos))
      break;
   rc = DosRead( hfile,
                 pbBuffer,
                 ulBytesToRead,
                 &ulBytesRead);
   if (rc != NO_ERROR)
      break;

   // make message an ASCCIIZ string and report len without zerobyte
   *pcbMsg = ulBytesRead;
   *(pbBuffer + ulBytesRead) = 0;

   // expand parms
   pszExpanded = _TmfExpandParms( pbBuffer, pTable, cTable);
   if (pszExpanded)
      {
      if (strlen( pszExpanded) + 1 > cbBuffer)
         {
         rc = ERROR_BUFFER_OVERFLOW;
         break;
         }
      else
         strcpy( pbBuffer, pszExpanded);
      }

   } while (FALSE);

// cleanup
if (pszExpanded) free( pszExpanded);
if (hfile) DosClose( hfile);
if (pbTableData) free( pbTableData);
return rc;

}

// ==============================================================================

static APIRET _TmfCompileMsgTable
         (
         PSZ            pszMessageFile,
         PBYTE         *ppbTableData
         )

{
         APIRET         rc = NO_ERROR;
         CHAR           szMessageFile[ _MAX_PATH];

         FILESTATUS3    fs3;
         ULONG          ulStampLength;
         PBYTE          pbFileData = NULL;
         ULONG          ulFileDataLength;

         CHAR           szFileStampOld[ 18];     // yyyymmddhhmmssms.
         CHAR           szFileStampCurrent[ 18];

         PBYTE          pbTableData = NULL;
         ULONG          ulTableDataLength;
         ULONG          ulTableDataContentsLength = 0;
         CHAR           szEntry[ _MAX_PATH];

         HFILE          hfileMessageFile = NULLHANDLE;
         ULONG          ulAction;
         ULONG          ulBytesRead;

         COUNTRYCODE    cc = {0,0};

         PSZ            pszCommentLine;
         PSZ            pszCurrentNameStart;
         PSZ            pszCurrentNameEnd;
         PSZ            pszCurrentMessageStart;
         PSZ            pszCurrentMessageEnd;
         ULONG          ulCurrentMessagePos;
         ULONG          ulCurrentMessageLen;
         PSZ            pszNextNameStart;
         PSZ            pszEntry;

do
   {
   // check parms
   if ((!pszMessageFile)  ||
       (!ppbTableData))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get length and timestamp of file
   rc = DosQueryPathInfo( pszMessageFile,
                          FIL_STANDARD,
                          &fs3,
                          sizeof( fs3));
   if (rc != NO_ERROR)
      break;
   ulFileDataLength = fs3.cbFile;

   // determine current timestamp
   _TmfGetTimeStamp( &fs3, szFileStampCurrent, sizeof( szFileStampCurrent));


   // determine saved timestamp
   ulStampLength = sizeof( szFileStampOld);
   rc = QueryStringEa( pszMessageFile, EA_TIMESTAMP, szFileStampOld, &ulStampLength);

   // compare timestamps
   if ((rc == NO_ERROR)                                     &&
       (ulStampLength == (strlen( szFileStampCurrent) + 1)) &&
       (!strcmp( szFileStampCurrent, szFileStampOld)))
      {

      // read table out of EAs
      do
         {
         // get ea length of table
         ulTableDataLength = 0;
         rc = QueryStringEa( pszMessageFile, EA_MSGTABLE, NULL, &ulTableDataLength);
         if (rc != ERROR_BUFFER_OVERFLOW)
            break;

         // get memory
         if ((pbTableData = malloc( ulTableDataLength)) == NULL)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }

         // read table
         rc = QueryStringEa( pszMessageFile, EA_MSGTABLE, pbTableData, &ulTableDataLength);

         } while (FALSE);

      // if no error occurred, we are finished
      if (rc == NO_ERROR)
         {
         DPRINTF(( "TMF: using precompiled table of %s\n", pszMessageFile));
         break;
         }
      }

   DPRINTF(( "TMF: (re)compile table for %s\n", pszMessageFile));

   // recompilation needed
   // get memory for file data
   if ((pbFileData = malloc( ulFileDataLength + 1)) == NULL)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   *(pbFileData + ulFileDataLength) = 0;

   // get memory for table data
   ulTableDataLength = ulFileDataLength / 2;
   if ((pbTableData = malloc( ulTableDataLength)) == NULL)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pbTableData, 0, ulTableDataLength);

   // open file and read it
   rc = DosOpen( pszMessageFile,
                 &hfileMessageFile,
                 &ulAction,
                 0, 0,
                 OPEN_ACTION_FAIL_IF_NEW |
                    OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_FLAGS_FAIL_ON_ERROR |
                    OPEN_SHARE_DENYWRITE  |
                    OPEN_ACCESS_READWRITE,        // needed for EA attachement
                 NULL);
   if (rc != NO_ERROR)
      break;

   rc = DosRead( hfileMessageFile,
                 pbFileData,
                 ulFileDataLength,
                 &ulBytesRead);
   if (rc != NO_ERROR)
      break;
   if (ulBytesRead != ulFileDataLength)
      {
      rc = ERROR_READ_FAULT;
      break;
      }


   // skip comment lines at beginning of file
   pszCurrentNameStart = pbFileData;
   if (*pbFileData == ';')
      {
      pszCommentLine = pbFileData;
      while (pszCommentLine)
         {
         // save current ptr
         pszCurrentNameStart = pszCommentLine;

         // search next comment line
         pszCommentLine = strstr( pszCommentLine + 1, MSG_COMMENT_LINE);
         }
      }
   else
      pszCurrentNameStart = pbFileData;

   // ------------------------------------------------------------------


   // search first message name
   if (*pszCurrentNameStart != '<')
      {
         pszCurrentNameStart = strstr( pszCurrentNameStart, MSG_NAME_START);

      if (!pszCurrentNameStart)
         {
         rc = ERROR_INVALID_DATA;
         break;
         }
      else
         pszCurrentNameStart += strlen( MSG_NAME_START);
      }
   else
      pszCurrentNameStart++;

   // is first name complete ?
   pszCurrentNameEnd = strstr( pszCurrentNameStart, MSG_NAME_END);
   if (!pszCurrentNameEnd)
      {
      rc = ERROR_INVALID_DATA;
      break;
      }

   // scan through all names
   while ((pszCurrentNameStart) && (*pszCurrentNameStart))
      {
      // search end of name, if not exist, skip end of file
      pszCurrentNameEnd = strstr( pszCurrentNameStart, MSG_NAME_END);
      if (!pszCurrentNameEnd)
         break;

      // search next name, if none, use end of string
      pszCurrentMessageEnd = strstr( pszCurrentNameEnd, MSG_NAME_START);
      if (!pszCurrentMessageEnd)
         {
         pszCurrentMessageEnd = pszCurrentNameStart + strlen( pszCurrentNameStart);
         pszNextNameStart = NULL;

         // cut off last CRLF
         if (*(PUSHORT) (pszCurrentMessageEnd - 2) == 0x0a0d)
            pszCurrentMessageEnd -=2;
         }
      else
         pszNextNameStart = pszCurrentMessageEnd + strlen( MSG_NAME_START);

      // calculate table entry data
      *pszCurrentNameEnd  = 0;
      ulCurrentMessagePos = pszCurrentNameEnd + strlen( MSG_NAME_END) - pbFileData;
      ulCurrentMessageLen = pszCurrentMessageEnd - pbFileData - ulCurrentMessagePos;

      // determine entry
      sprintf( szEntry, "%s %u %u\n", pszCurrentNameStart, ulCurrentMessagePos, ulCurrentMessageLen);

      // need more space ?
      if ((ulTableDataContentsLength + strlen( szEntry) + 1) > ulTableDataLength)
         {
                   PBYTE          pbTmp;

         ulTableDataLength += ulFileDataLength / 2;
         pbTmp = realloc( pbTableData, ulTableDataLength);
         if (!pbTmp)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         else
            pbTableData = pbTmp;
         }

      // add entry
      strcat( pbTableData, szEntry);
      ulTableDataContentsLength += strlen( szEntry);

      // adress next entry
      pszCurrentNameStart = pszNextNameStart;

      } // while (pszCurrentNameStart)

   // close file, so that we can use DosSetPathInfo to write Eas -
   // this avoids reset of lastwritestamp when using DosSetFileInfo instead
   DosClose( hfileMessageFile);
   hfileMessageFile = NULL;

   // write EAs
   // ### handle 64 kb limit here !!!
   rc = WriteStringEa( pszMessageFile, EA_TIMESTAMP, szFileStampCurrent);
   if (rc != NO_ERROR)
      break;
   rc = WriteStringEa( pszMessageFile, EA_MSGTABLE,  pbTableData);
   if (rc != NO_ERROR)
      break;


   // ------------------------------------------------------------------

   } while (FALSE);


if (rc == NO_ERROR)
   {
   // hand over result
   *ppbTableData = pbTableData;

   // make text uppercase
   rc = DosMapCase( ulTableDataLength, &cc, pbTableData);
   }

// cleanup
if (pbFileData)       free( pbFileData);
if (hfileMessageFile) DosClose( hfileMessageFile);

if (rc != NO_ERROR)
   if (pbTableData)      free( pbTableData);

return rc;
}

// ==============================================================================

APIRET _TmfGetTimeStamp
         (
         PFILESTATUS3   pfs3,
         PSZ            pszBuffer,
         ULONG          ulBufferlen
         )
{

         APIRET         rc = NO_ERROR;
         CHAR           szTimeStamp[ 15];
static   PSZ            pszFormatTimestamp = "%4u%02u%02u%02u%02u%02u%";

do
   {
   // check parms
   if ((!pfs3)||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // create stamp
   sprintf( szTimeStamp,
            pszFormatTimestamp,
            pfs3->fdateLastWrite.year + 1980,
            pfs3->fdateLastWrite.month,
            pfs3->fdateLastWrite.day,
            pfs3->ftimeLastWrite.hours,
            pfs3->ftimeLastWrite.minutes,
            pfs3->ftimeLastWrite.twosecs * 2);

   // check bufferlen
   if (strlen( szTimeStamp) + 1 > ulBufferlen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szTimeStamp);

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

static PSZ _TmfExpandParms( PSZ pszStr, PSZ *apszParms, ULONG ulParmCount)
{
         PSZ      pszResult = NULL;

         PSZ      pszNewValue;

         PSZ      pszStartPos;
         PSZ      pszVarNum;

         ULONG    ulNameLen = 1;
         PSZ      pszVarValue;
         CHAR     szVarName[] = "?";
         ULONG    ulParmIndex;

         PSZ      pszNewResult;
         ULONG    ulNewResultLen;

static   CHAR     chDelimiter = '%';

         ULONG    ulSkipValue = 0;

do
   {
   // check parms
   if (!pszStr)
      break;

   // create a copy
   pszResult = strdup( pszStr);
   if (!pszResult)
      break;

   // if no parms to replace, don't expand
   if (!ulParmCount)
      break;

   // maintain the copy
   pszStartPos = strchr( pszResult + ulSkipValue, chDelimiter);
   while (pszStartPos)
      {
      // find index
      pszVarNum = pszStartPos + 1;

      // check which parm is meant
      szVarName[ 0] = *pszVarNum;
      ulParmIndex = atol( szVarName);
      if ((ulParmIndex) && (ulParmIndex <= ulParmCount))
         {

         // first of all, elimintate the variable
         strcpy( pszStartPos, pszVarNum + 1);

         // get value
         pszVarValue = apszParms[ ulParmIndex - 1];
         if (pszVarValue)
            {
            // embedd new value
            pszNewResult = malloc( strlen( pszResult) + 1 + strlen( pszVarValue));
            if (pszNewResult)
               {
               strcpy( pszNewResult, pszResult);
               strcpy( pszNewResult + (pszStartPos - pszResult), pszVarValue);
               strcat( pszNewResult, pszStartPos);
               free( pszResult);
               pszResult = pszNewResult;
               }
            else
               {
               // kick any result, as we are out of memory
               free( pszResult);
               pszResult = NULL;
               break;
               }
            }
         }
      else
         // skip this percent sign, as it is not replaced
         ulSkipValue = pszStartPos - pszResult + 1;

      // next var please
      pszStartPos = strchr( pszResult + ulSkipValue, chDelimiter);
      }


   } while (FALSE);


// no cleanup - caller must free memory !
return pszResult;
}

