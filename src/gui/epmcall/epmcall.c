/****************************** Module Header *******************************
*
* Module Name: epmcall.c
*
* EPM call utility
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmcall.c,v 1.4 2002-08-10 13:04:49 cla Exp $
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
#define INCL_WIN
#define INCL_ERRORS
#include <os2.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "common.h"
#include "macros.h"
#include "file.h"

#define QUEUENAMEBASE "\\QUEUES\\EPMCALL\\"

// -----------------------------------------------------------------------------
PSZ ExpandEnvVar( PSZ pszStr)
{
         PSZ      pszResult = NULL;

         PSZ      pszNewValue;

         PSZ      pszStartPos;
         PSZ      pszEndPos;

         CHAR     szVarName[ 128];
         ULONG    ulNameLen;
         PSZ      pszVarValue;

         PSZ      pszNewResult;
         ULONG    ulNewResultLen;

static   CHAR     chDelimiter = '%';

do
   {
   // check parms
   if (!pszStr)
      break;

   // create a copy
   pszResult = strdup( pszStr);
   if (!pszResult)
      break;

   // maintain the copy
   pszStartPos = strchr( pszResult, chDelimiter);
   while (pszStartPos)
      {
      // find end
      pszEndPos = strchr( pszStartPos + 1, chDelimiter);

      // no end found, cut of to end of string
      if (!pszEndPos)
         {
         *pszStartPos = 0;
         break;
         }
      else
         {
         // isolate name
         ulNameLen = pszEndPos - pszStartPos - 1;
         memcpy( szVarName, pszStartPos + 1, ulNameLen);
         szVarName[ ulNameLen] = 0;


         // first of all, elimintate the variable
         strcpy( pszStartPos, pszEndPos + 1);

         // get value
         pszVarValue = getenv( szVarName);
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
            }

         }

      // next var please
      pszStartPos = strchr( pszResult, chDelimiter);
      }


   } while (FALSE);

return pszResult;
}

// -----------------------------------------------------------------------------
APIRET GetExtendedEnvironment( PSZ envv[], PSZ pszEnvFile, PSZ *ppszNewEnv)
{
         APIRET         rc  = NO_ERROR;

         PSZ           *ppszEnv;
         PSZ            pszVar;

         ULONG          ulEnvSize;
         PSZ            pszEnv = NULL;

         FILESTATUS3    fs3;
         ULONG          ulFileSize;
         PSZ            pszData = NULL;
         HFILE          hfile = NULLHANDLE;
         ULONG          ulAction;
         ULONG          ulBytesRead;

         PSZ            pszLine;
         PSZ            pszNewLine;
static   PSZ            pszDelimiters = "\r\n";

do
   {
   // check parms
   if ((!pszEnvFile) ||
       (!envv))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check file
   if (FileExists( pszEnvFile))
      {
      // get memory
      rc = DosQueryPathInfo( pszEnvFile, FIL_STANDARD, &fs3, sizeof( fs3));
      if (rc != NO_ERROR)
         break;
      ulFileSize = fs3.cbFile;
      pszData = malloc( ulFileSize + 1);
      if (!pszData)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }
      memset( pszData, 0, ulFileSize + 1);


      // read file
      rc = DosOpen( pszEnvFile, &hfile, &ulAction, 0, 0,
                    OPEN_ACTION_FAIL_IF_NEW | OPEN_ACTION_OPEN_IF_EXISTS,
                    OPEN_ACCESS_READONLY | OPEN_SHARE_DENYWRITE,
                    NULL);
      if (rc != NO_ERROR)
         break;

      rc = DosRead( hfile, pszData, ulFileSize, &ulBytesRead);
      if (rc != NO_ERROR)
         break;
      if (ulFileSize != ulBytesRead)
         {
         rc = ERROR_READ_FAULT;
         break;
         }

      // go through all lines
      pszLine = strtok( pszData, pszDelimiters);
      while (pszLine)
         {
         do
            {
            // skip line without equal sign: no env set here
            if (!strchr( pszLine, '='))
               break;

            // skip comment lines
            if (*pszLine == ':')
               break;

            // add line to env
            pszNewLine = ExpandEnvVar( pszLine);
            if (pszNewLine)
               {
               putenv( pszNewLine);
               DPRINTF(( "addenv: \"%s\"\n", pszNewLine));
               }
            else
               DPRINTF(( "ERROR: cannot expand \"%s\"\n", pszLine));

            } while (FALSE);


         // next please
         pszLine = strtok( NULL, pszDelimiters);
         }

      }

   // get size of env provided
   ppszEnv = envv;
   ulEnvSize = 0;
   while (*ppszEnv)
      {
      ulEnvSize += strlen( *ppszEnv) + 1;
      ppszEnv++;
      }
   ulEnvSize += 1;

   // get memory
   pszEnv = malloc( ulEnvSize);
   if (!pszEnv)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszEnv, 0x0, ulEnvSize);

   // read env into memory block
   pszVar = pszEnv;
   ppszEnv = envv;
   while (*ppszEnv)
      {
      // copy var
      // DPRINTF(( "env: %s\n", *ppszEnv));
      strcpy( pszVar, *ppszEnv);

      // copy next var
      pszVar = NEXTSTR( pszVar);
      ppszEnv++;

      }
   *pszVar = 0;

   // hand over result
   *ppszNewEnv = pszEnv;

   } while (FALSE);


// cleanup on error
if (rc)
   if (pszEnv) free( pszEnv);

// cleanup
if (hfile) DosClose( hfile);
if (pszData) free( pszData);
return rc;
}

// -----------------------------------------------------------------------------

APIRET SearchEPMExecutable( PSZ pszExecutable, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         PPIB           ppib;
         PTIB           ptib;


         BOOL           fFound = FALSE;
         PSZ            pszPath = getenv( "PATH");
         PSZ            pszCopy = NULL;
         PSZ            pszDir;
         CHAR           szExecutable[ _MAX_PATH];
         CHAR           szThisModule[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszExecutable) ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check env
   if (!pszPath)
      {
      rc = ERROR_ENVVAR_NOT_FOUND;
      break;
      }

   // get name of own module
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szThisModule), szThisModule);

   // create copy to allow modification
   pszCopy = strdup( pszPath);
   if (!pszCopy)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }

   pszDir = strtok( pszCopy, ";");
   while (pszDir)
      {
      // create fullname for entry to check
      strcpy( szExecutable, pszDir);
      if (*(pszDir + strlen( pszDir) - 1) != '\\')
         strcat( szExecutable, "\\");
      strcat( szExecutable, "epm.exe");
      strupr( szExecutable);

      // process only modules not being the current one
      if (strcmp( szExecutable, szThisModule))
         {
         // does executable exist ?
         // DRINTF(( "EPMCALL: searching %s\n", szExecutable));
         if (FileExists( szExecutable))
            {
            fFound = TRUE;
            break;
            }
         }

      // next please
      pszDir = strtok( NULL, ";");
      }
   if (!fFound)
      {
      rc = ERROR_FILE_NOT_FOUND;
      break;
      }

   // hand over result
   if (strlen( szExecutable) + 1 > ulBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszExecutable, szExecutable);

   } while (FALSE);

// cleanup
if (pszCopy) free( pszCopy);
return rc;
}

// -----------------------------------------------------------------------------

APIRET SearchEnvironmentFile( PSZ pszEnvfile, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         BOOL           fFound = FALSE;
         PPIB           ppib;
         PTIB           ptib;

         CHAR           szExecutable[ _MAX_PATH];
         CHAR           szBasename[ _MAX_PATH];

         CHAR           szFilePath[ _MAX_PATH];
         ULONG          ulDataLen;

         CHAR           szEnvfile[ _MAX_PATH];

do
   {
   // check parms
   if ((!pszEnvfile) ||
       (!ulBuflen))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }


   // get own filename to isolate exe name
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, sizeof( szExecutable), szExecutable);
   strcpy( szBasename, strrchr( szExecutable, '\\')  + 1);
   strcpy( strrchr( szBasename, '.'), ".env");

   // isolate path of executabe
   strcpy( strrchr( szExecutable, '\\'), "");

   // get NEPMD install directory
   ulDataLen = PrfQueryProfileString( HINI_USER,
                                      NEPMD_INI_APPNAME,
                                      NEPMD_INI_KEYNAME_PATH,
                                      NULL,
                                      szFilePath,
                                      sizeof( szFilePath));

   if (ulDataLen)
      {
      // handle also non-zero-terminated strings
      szFilePath[ ulDataLen] = 0;

      // determine complete filename
      sprintf( szEnvfile, "%s\\"NEPMD_SUBPATH_BINBINDIR"\\%s", szFilePath, szBasename);
      fFound = (FileExists( szEnvfile));
      }

   if (!fFound)
      {
      // nothing stored or no config found in install tree - use path of executable
      sprintf( szEnvfile, "%s\\%s", szExecutable, szBasename);
      }


   // hand over result
   if (strlen( szEnvfile) + 1 > ulBuflen)
      {
      rc= ERROR_BUFFER_OVERFLOW;
      break;
      }
   strcpy( pszEnvfile, szEnvfile);
   DPRINTF(( "EPMCALL: envfile is %s\n", szEnvfile));

   } while (FALSE);

return rc;
}

// -----------------------------------------------------------------------------

APIRET CallEPM(  INT argc, PSZ  argv[], PSZ  envv[])
{
         APIRET         rc  = NO_ERROR;
         ULONG          i;
         PSZ            pszEnv = NULL;

         PID            pid;
         ULONG          ulSession;
         STARTDATA      startdata;


         CHAR           szProgramName[ _MAX_PATH];
         CHAR           szProgramArgs[ _MAX_PATH * 4];
         CHAR           szEnvName[ _MAX_PATH];
         CHAR           szEnv[ _MAX_PATH * 4];

         CHAR           szTermQueueName[ 260 ];
         CHAR           szTimeStamp[ 9];
         DATETIME       datetime;
         HQUEUE         hqTermQueue;
         PRESULTCODES   presc;

         REQUESTDATA    requestdata;
         ULONG          ulDataLength;
         BYTE           bElemPriority;

do
   {

   // create unique termination queue name
   DosSleep( 0L);
   DosGetDateTime( &datetime);
   sprintf( szTimeStamp, "%02u%02u%02u%02u",
            datetime.hours, datetime.minutes, datetime.seconds, datetime.hundredths);
   strcpy( szTermQueueName, QUEUENAMEBASE);
   strcat( szTermQueueName, szTimeStamp);

   // create termination queue
   rc = DosCreateQueue( &hqTermQueue,
                        QUE_FIFO,
                        szTermQueueName);
   if (rc != NO_ERROR)
     break;


   // search true EPM along the path
   rc = SearchEPMExecutable( szProgramName, sizeof( szProgramName));
   if (rc != NO_ERROR)
      break;

   // search environment file
   rc = SearchEnvironmentFile( szEnvName, sizeof( szEnvName));

   // get extended environment
   rc = GetExtendedEnvironment(  envv, szEnvName,&pszEnv);
   if (rc != NO_ERROR)
      break;

   // concatenate parms
   szProgramArgs[ 0] = 0;
   for (i = 1; i < argc; i++)
      {
               PSZ            pszMask;

      // take care for included blanks
      if (strchr( argv[ i], ' '))
         pszMask = "\"%s\"";
      else
         pszMask = "%s";

      sprintf( _EOS( szProgramArgs), pszMask, argv[ i]);
      }

   // start program - fill STARTDATA
   memset( &startdata, 0, sizeof( startdata));
   startdata.Length      = sizeof( startdata);
   startdata.Related     = SSF_RELATED_CHILD;
   startdata.InheritOpt  = SSF_INHERTOPT_PARENT;
   startdata.SessionType = SSF_TYPE_PM;
   startdata.FgBg        = SSF_FGBG_FORE;
   startdata.PgmName     = szProgramName;
   startdata.PgmInputs   = szProgramArgs;
   startdata.TermQ       = szTermQueueName;
   startdata.Environment = pszEnv;

   rc = DosStartSession( &startdata, &ulSession, &pid);
   DPRINTF(( "call: %s\n   %s\nrc=%u\n", startdata.PgmName, startdata.PgmInputs, rc));
   if ((rc != NO_ERROR) && (rc != ERROR_SMG_START_IN_BACKGROUND))
      break;

   // wait for the program to terminate
   rc = DosReadQueue( hqTermQueue,
                      &requestdata,
                      &ulDataLength,
                      (PPVOID) &presc,
                      0,
                      DCWW_WAIT,
                      &bElemPriority,
                      0L);

   DosCloseQueue( hqTermQueue);
   if (rc != NO_ERROR)
      break;

   // return rc from child
   // BUG: seems to be always NO_ERROR (rc=0)
   rc = presc->codeResult;
   DPRINTF(( "session result: %u\n", rc));

   } while (FALSE);

// cleanup
if (pszEnv) free( pszEnv);
return rc;
}


// -----------------------------------------------------------------------------

INT main ( INT argc, PSZ  argv[], PSZ  envv[])
{

         APIRET         rc  = NO_ERROR;
         ULONG          i;
         HAB            hab = NULLHANDLE;
         HMQ            hmq = NULLHANDLE;


do
   {

   // get PM resources
   if ((hab = WinInitialize( 0)) == NULLHANDLE)
      {
      rc = ERROR_INVALID_FUNCTION;
      break;
      }

   if ((hmq = WinCreateMsgQueue( hab, 0)) == NULLHANDLE)
      {
      rc = LASTERROR;
      break;
      }

   // call EPM
   rc = CallEPM( argc, argv, envv);


   } while (FALSE);


if (hmq) WinDestroyMsgQueue( hmq);
if (hab) WinTerminate( hab);

DPRINTF(( ">>> rc=%u/0x%04x\n", rc, rc));

return rc;

}

