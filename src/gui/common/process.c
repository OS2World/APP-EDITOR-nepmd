/****************************** Module Header *******************************
*
* Module Name: process.c
*
* Generic routines to start routines (a)synchronously
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

#define INCL_DOS
#define INCL_ERRORS
#include <os2.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// disable debug messages for this module
#undef DEBUG

#include "process.h"
#include "epmenv.h"
#include "macros.h"

// ---------------------------------------------------------------------

#define TIMESTAMP     "%02u%02u%02u%02u"
#define QUEUENAMEBASE "\\QUEUES\\%s\\"


APIRET ExecVioCommandSession(  PSZ pszEnv, PSZ pszAppName, PSZ pszCommand, BOOL fVisible)
{
         APIRET         rc;

         PSZ            pszComspec = getenv( "COMSPEC");

         STARTDATA      startdata;
         PID            pid;
         ULONG          ulSession;

         CHAR           szTermQueueName[ 260 ];
         CHAR           szTimeStamp[ 9];
         DATETIME       datetime;
         HQUEUE         hqTermQueue;

         REQUESTDATA    requestdata;
         ULONG          ulDataLength;
         BYTE           bElemPriority;

         CHAR           szFailName [ 20 ];
         CHAR           szCommand[ 2 * _MAX_PATH];
         PRESULTCODES   presc;


do
   {
   // check parameters
   if (pszCommand == NULL)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // concatenate command
   sprintf( szCommand, "/C %s", pszCommand);

   // create unique termination queue name
   DosSleep( 0L);
   DosGetDateTime( &datetime);
   sprintf( szTimeStamp, TIMESTAMP,
            datetime.hours, datetime.minutes, datetime.seconds, datetime.hundredths);
   sprintf( szTermQueueName, QUEUENAMEBASE, pszAppName);
   strcat( szTermQueueName, szTimeStamp);

   // create termination queue
   rc = DosCreateQueue( &hqTermQueue,
                        QUE_FIFO,
                        szTermQueueName);
   if (rc != NO_ERROR)
     break;

   // start the session
   // all other fields are defaults by zeroes
   memset( &startdata, 0, sizeof( startdata));
   startdata.Length      = sizeof( startdata);
   startdata.PgmTitle    = "";
   startdata.PgmName     = pszComspec;
   startdata.PgmInputs   = szCommand;
   startdata.FgBg        = (fVisible) ? SSF_FGBG_FORE : SSF_FGBG_BACK;
   startdata.InheritOpt  = SSF_INHERTOPT_PARENT;
   startdata.SessionType = (fVisible) ? SSF_TYPE_WINDOWABLEVIO : SSF_TYPE_PM;
   startdata.Related     = SSF_RELATED_CHILD;
   startdata.TermQ       = szTermQueueName;
   startdata.Environment = pszEnv;
   rc = DosStartSession( &startdata, &ulSession, &pid);

   // wait for the program to terminate
   DPRINTF(( "PROCESS: waiting for pid %u to terminate\n", pid));
   rc = DosReadQueue( hqTermQueue,
                      &requestdata,
                      &ulDataLength,
                      (PPVOID) &presc,
                      0,
                      DCWW_WAIT,
                      &bElemPriority,
                      0L);

   DPRINTF(( "PROCESS: termination queue read with rc %u, data len %u, \n",
                ulDataLength, sizeof( RESULTCODES), rc));

   DosCloseQueue( hqTermQueue);
   if (rc != NO_ERROR)
      break;

   // return rc from child
   // BUG: seems to be always NO_ERROR (rc=0)
   rc = presc->codeResult;
   DPRINTF(( "PROCESS: child termination code: %u reason code %u\n",
             presc->codeTerminate,
             presc->codeResult));

   } while (FALSE);

return rc;

}

// ---------------------------------------------------------------------

APIRET StartPmSession( PSZ pszProgram, PSZ pszParms, PSZ pszTitle, PSZ pszEnv, BOOL fForeground, ULONG ulControlStyle)
{
         APIRET         rc;

         STARTDATA      startdata;
         PID            pid;
         ULONG          ulSession;

do
   {
   // check parameters
   if ((!pszProgram) ||
       (!pszParms))

      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // start the session
   // all other fields are defaults by zeroes
   memset( &startdata, 0, sizeof( startdata));
   startdata.Length      = sizeof( startdata);
   startdata.PgmTitle    = pszTitle;
   startdata.PgmName     = pszProgram;
   startdata.PgmInputs   = pszParms;
   startdata.FgBg        = (fForeground) ? SSF_FGBG_FORE : SSF_FGBG_BACK;
   startdata.InheritOpt  = SSF_INHERTOPT_PARENT;
   startdata.SessionType = SSF_TYPE_PM;
   startdata.Related     = SSF_RELATED_INDEPENDENT;
   startdata.PgmControl  = ulControlStyle;
   startdata.Environment = pszEnv;
   rc = DosStartSession( &startdata, &ulSession, &pid);

   } while (FALSE);

return rc;

}


// ############ unused code starts ####################################

#if THIS_CODE_NOT_USED

// ---------------------------------------------------------------------

APIRET ExecPipedCommand( PSZ pszCommand, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         HFILE          hfRead  = NULLHANDLE;
         HFILE          hfWrite = NULLHANDLE;
         PSZ            pszComspec;

         CHAR           szError[ 20];
         CHAR           szArg[ 1024];
         CHAR           szEnv[ 2];
         RESULTCODES    resultcodes;
         PID            pidChild;
         PID            pidTerminated;
         ULONG          ulBytesRead;
         PSZ            p;

do
   {
   // check parms
   if ((!pszCommand)   ||
       (!*pszCommand)  ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // open pipe
   rc = DosCreatePipe( &hfRead, &hfWrite, ulBuflen);
   if (rc != NO_ERROR)
      break;

   // get command proc
   rc = DosScanEnv( "COMSPEC", &pszComspec);
   if (rc != NO_ERROR)
      break;

   // setup parms
   sprintf( szArg, "%s%c /c %s>&%u 2>&%u%c",
            pszComspec,
            0,
            pszCommand,
            hfWrite,
            hfWrite,
            0);

   // setup empty additional environment
   memset( szEnv, 0, sizeof( szEnv));

   // execute program asyncronously
   rc = DosExecPgm( szError,
                    sizeof( szError),
                    EXEC_ASYNCRESULT,
                    szArg,
                    NULL,
                    &resultcodes,
                    pszComspec);
   if (rc != NO_ERROR)
      break;
   pidChild = resultcodes.codeTerminate;

   // wait for the child and get resultcode
   rc = DosWaitChild( DCWA_PROCESS,
                      DCWW_WAIT,
                      &resultcodes,
                      &pidTerminated,
                      pidChild);

   if ((rc != NO_ERROR) && (rc != ERROR_WAIT_NO_CHILDREN))
      break;

   memset( pszBuffer, 0, ulBuflen);
   rc = DosRead( hfRead, pszBuffer, ulBuflen - 1, &ulBytesRead);
   if (rc != NO_ERROR)
      break;

   // cut off tailing whitespace (CRLF), but no blanks !
   p = pszBuffer + strlen( pszBuffer) + 1;;
   while ((p > pszBuffer) && (*p < 0x20))
      {
      *p = 0;
      p--;
      }

   } while (FALSE);

// cleanup
if (hfRead)  DosClose( hfRead);
if (hfWrite) DosClose( hfWrite);
return rc;
}

#endif

// ############ unused code ends ######################################

