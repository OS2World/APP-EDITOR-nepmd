/****************************** Module Header *******************************
*
* Module Name: epmcall.c
*
* EPM call utility
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmcall.c,v 1.10 2002-08-13 21:09:27 cla Exp $
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
#include "epmenv.h"

#define QUEUENAMEBASE "\\QUEUES\\EPMCALL\\"

// -----------------------------------------------------------------------------

APIRET SearchEPMExecutable( PSZ pszExecutable, ULONG ulBuflen)
{
         APIRET         rc  = NO_ERROR;
         PPIB           ppib;
         PTIB           ptib;
         ULONG          ulBootDrive;


         BOOL           fFound = FALSE;
         PSZ            pszPath = getenv( "PATH");
         PSZ            pszCopy = NULL;
         PSZ            pszDir;
         CHAR           szExecutable[ _MAX_PATH];

         CHAR           szThisModule[ _MAX_PATH];
         CHAR           szNepmdModule[ _MAX_PATH];
         CHAR           szInstalledModule[ _MAX_PATH];

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

   // get name of EPM.EXE in NEPMD path
   memset( szNepmdModule, 0, sizeof( szNepmdModule));
   PrfQueryProfileString( HINI_USER,
                          NEPMD_INI_APPNAME,
                          NEPMD_INI_KEYNAME_PATH,
                          NULL,
                          szNepmdModule,
                          sizeof( szNepmdModule));
   strcat( szNepmdModule, "\\"NEPMD_SUBPATH_BINBINDIR"\\epm.exe");
   strupr( szNepmdModule);

   // get name of epm.exe in OS/2 directory
   // this is used by installed NEPMD
   DosQuerySysInfo( QSV_BOOT_DRIVE, QSV_BOOT_DRIVE, &ulBootDrive, sizeof( ULONG));
   sprintf( szInstalledModule, "%c:\\OS2\\EPM.EXE", (CHAR) ulBootDrive + 'A' - 1);

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

      // process only modules not being the current one or of NEPMD
      if ((strcmp( szExecutable, szThisModule)) &&
          (strcmp( szExecutable, szNepmdModule)) &&
          (strcmp( szExecutable, szInstalledModule)))
         {
         // does executable exist ?
//       DPRINTF(( "EPMCALL: searching %s\n", szExecutable));
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

   // get extended environment
   rc = GetExtendedEPMEnvironment( envv, &pszEnv);
   if (rc != NO_ERROR)
      break;

   // concatenate parms
   szProgramArgs[ 0] = 0;
   for (i = 1; i < argc; i++)
      {
               PSZ            pszMask;

      // take care for included blanks
      if (strchr( argv[ i], ' '))
         pszMask = "\"%s\" ";
      else
         pszMask = "%s ";

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

