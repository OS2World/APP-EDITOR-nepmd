
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

#include "tmf.h"
#include "eas.h"

// ------------------------------------------------------------------------------

#define EA_TIMESTAMP "TMF.FILEINFO"
#define EA_MSGTABLE  "TMF.MSGTABLE"

#define NEWLINE "\n"

#define MSG_NAME_START   "\r\n<--"
#define MSG_NAME_END     "-->:"

#define MSG_COMMENT_LINE "\r\n;"

// internal prototypes
APIRET _TmfCompileMsgTable( PSZ pszMessageFile, PBYTE * ppbTableData);
APIRET _TmfGetTimeStamp( PFILESTATUS3 pfs3, PSZ pszBuffer, ULONG ulBufferlen);

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
         PSZ            pszEntry;
         PSZ            pszEndOfEntry;
         ULONG          ulMessagePos;
         ULONG          ulMessageLen;

         HFILE          hfile = NULLHANDLE;
         ULONG          ulFilePtr;
         ULONG          ulAction;
         ULONG          ulBytesToRead;
         ULONG          ulBytesRead;

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
   pszEntry = strstr( pbTableData, pszMessageName);
   if (!pszEntry)
      {
      rc = ERROR_MR_MID_NOT_FOUND;
      break;
      }
   else
      pszEntry += strlen( pszMessageName) + 1;

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

   // report "buffer too small" here
   *pcbMsg = ulBytesRead;
   if (ulBytesToRead < ulMessageLen)
      rc = ERROR_BUFFER_OVERFLOW;


   } while (FALSE);

// cleanup
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
   rc = ReadStringEa( pszMessageFile, EA_TIMESTAMP, szFileStampOld, &ulStampLength);

   // compare timestamps
   if ((rc == NO_ERROR)                                     && 
       (ulStampLength == (strlen( szFileStampCurrent) + 1)) &&
       (!strcmp( szFileStampCurrent, szFileStampOld)))
      {

      // read table out of EAs
      do
         {
         // get ea length of table
         rc = ReadStringEa( pszMessageFile, EA_MSGTABLE, NULL, &ulTableDataLength);
         if (rc != ERROR_BUFFER_OVERFLOW)
            break;

         // get memory
         if ((pbTableData = malloc( ulTableDataLength)) == NULL)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }

         // read table
         rc = ReadStringEa( pszMessageFile, EA_MSGTABLE, pbTableData, &ulTableDataLength);

         } while (FALSE);

      // if no error occurred, we are finished
      if (rc == NO_ERROR)
         {
         // printf( "tmf: using precompiled table" NEWLINE, 0);
         break;
         }
      }

   // printf( "tmf: recompile table" NEWLINE, 0);

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
   *(pbTableData + ulTableDataLength) = 0;

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
      pszNextNameStart = strstr( pszCurrentNameEnd, MSG_NAME_START);
      if (!pszNextNameStart)
         pszNextNameStart = pszCurrentNameStart + strlen( pszCurrentNameStart);
      else
         pszNextNameStart += strlen( MSG_NAME_START);

      // calculate table entry data
      *pszCurrentNameEnd  = 0;
      ulCurrentMessagePos = pszCurrentNameEnd + strlen( MSG_NAME_END) - pbFileData;
      ulCurrentMessageLen = pszNextNameStart - pbFileData - ulCurrentMessagePos - 1;

      // determine entry
      sprintf( szEntry, "%s %u %u" NEWLINE, pszCurrentNameStart, ulCurrentMessagePos, ulCurrentMessageLen);

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

   // write new timestamp and table
   // ### handle 64 kb limit here !!!
   rc = WriteStringEa( pszMessageFile, EA_TIMESTAMP, szFileStampCurrent);
   rc = WriteStringEa( pszMessageFile, EA_MSGTABLE,  pbTableData);


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
