/****************************** Module Header *******************************
*
* Module Name: epmcall.c
*
* EPM call utility
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: epmcall.c,v 1.27 2009-02-16 01:25:48 aschn Exp $
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
#include "instval.h"

#define QUEUENAMEBASE "\\QUEUES\\EPMCALL\\"
//#define LOADSTRING(m,t)           GetMessage( NULL, 0, t, sizeof( t), m, &ulMessageLen)

#define INI_APP_EPM "EPM"
#define INI_KEY_EPMINIPATH "EPMIniPath"

// -----------------------------------------------------------------------------

#define EPM_SWITCH_CHARS "/"

APIRET CallEPM( INT argc, PSZ argv[], PSZ envv[])
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         PSZ            pszEnv = NULL;

         PID            pid;
         ULONG          ulSession;
         STARTDATA      startdata;

         CHAR           szExecutable[ _MAX_PATH];
//          CHAR           szProgramArgs[ _MAX_PATH * 4];
         CHAR           szEnv[ _MAX_PATH * 4];

         CHAR           szTermQueueName[ 260 ];
         CHAR           szTimeStamp[ 9];
         DATETIME       datetime;
         HQUEUE         hqTermQueue;
         PRESULTCODES   presc;

         REQUESTDATA    requestdata;
         ULONG          ulDataLength;
         BYTE           bElemPriority;
         BOOL           fAsync = TRUE;  // default is to start EPM asynchronously

         CHAR           szEpmIniFile[ _MAX_PATH];
         CHAR           szIniFile[ _MAX_PATH];
         CHAR           szTmp[ _MAX_PATH];
         ULONG          ulLen = 0;
         BOOL           fEpmStarted = FALSE;
         FILE          *pfile = NULL;
         PPIB           ppibEPM;

         CHAR           szMessage[ 1024];

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

   // get extended environment
   szExecutable[ 0] = 0;
   rc = GetExtendedEPMEnvironment( envv, &pszEnv, szExecutable, sizeof( szExecutable));

   // path errors are already checked by GetExtendedEPMEnvironment
   if (rc != NO_ERROR)
      break;
   else if (!strlen( szExecutable))
      {
      sprintf( szMessage,
               "Fatal error #1: Cannot find the EPM executable.\n\n"
               "Install EPM via Selective Install of your OS!\n\n");

      SHOWFATALERROR( HWND_DESKTOP, szMessage);
      break;
      }

   // Use DosGetInfoBlocks to keep the parm as submitted.
   // Parsing it with argv[i] doesn't always work correct for single quotes.
   // Note: The EPM executable strips every double quote (it's a bug)!
   rc = DosGetInfoBlocks( NULL, &ppibEPM);
   if (rc != NO_ERROR)
      {
      DPRINTF(( "Error: DosGetInfoBlocks returned rc = %u\n", rc));
      // don't break here
      }
   else
      {
      if (ppibEPM->pib_pchcmd)
         {
//         DPRINTF(( "DosGetInfoBlocks parm 0: ###%s###\n", ppibEPM->pib_pchcmd));
//         DPRINTF(( "DosGetInfoBlocks parm 1: ###%s###\n", ppibEPM->pib_pchcmd + strlen( ppibEPM->pib_pchcmd) + 1));
         }
      else
         DPRINTF(( "Error: DosGetInfoBlocks returned no parms\n"));
      }

   // use argv[i] do check for parm /M only
   for (i = 1; i < argc; i++)
      {
          PSZ            pszThisParm;

      // search /M parm for starting EPM synchronously then
      pszThisParm = argv[i];

      if (strchr(EPM_SWITCH_CHARS, *pszThisParm) != NULL)
         {
         pszThisParm++;

         // upcase the parm name
         strupr( pszThisParm);

         // process M
         if (strstr( "M", pszThisParm))
            {
            DPRINTF(( "CallEPM: parm %s specified\n", pszThisParm));
            fAsync = FALSE;
            }
         }
      }

   // Change entry of OS2.INI -> EPM -> EPMIniPath to filename of NEPMD.INI
   // in order to keep the ini file for standard EPM unchanged.
   // NEPMD.INI is used now for all settings, that otherwise would be written
   // to EPM.INI:
   //    o  window positions
   //    o  remaining settings, that are still not replaced by NEPMD settings
   //    o  settings from external packages
   // For the ConfigDlg the entry has to be changed before its startup by E
   // macros separately.
   do
      {

      // Save old entry in NEPMD.INI to restore it after EPM's startup:
      szEpmIniFile[0] = '\0';
      szIniFile[0]    = '\0';
      szTmp[0]        = '\0';

      // EPM adds the default entry automatically if no key/entry, if a null string
      // entry or if file not found.
      // Bug: That value would be not zero-terminated then.

      ulLen = PrfQueryProfileString( HINI_USER, INI_APP_EPM, INI_KEY_EPMINIPATH, NULL,
                                     szEpmIniFile, sizeof( szEpmIniFile));

      // handle also non-zero-terminated strings
      szEpmIniFile[ ulLen] = 0;
      //DPRINTF(( "CallEPM: EpmIniFile = %s\n", szEpmIniFile));

      // determine name of NEPMD.INI
      rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szIniFile, sizeof( szIniFile));
      //DPRINTF(( "CallEPM: IniFile = %s, rc = %u\n", szIniFile, rc));
      if (rc != NO_ERROR)
         {
         sprintf( szMessage,
                  "Fatal error #2: filename for NEPMD.INI"
                  " could not be determined, rc = %u.\n\n"
                  "NEPMD is not properly installed,"
                  " repeat the installation via WarpIN!\n\n"
                  "If that problem still persists, check"
                  " if your UserDir (e.g. \"NEPMD\\myepm\") and"
                  " its subdirectory \"bin\" exist and if they"
                  " are writable.\n\n", rc);
         SHOWFATALERROR( HWND_DESKTOP, szMessage);
         break;
         }

      // check if no other process has already changed it
      if (stricmp( szEpmIniFile, szIniFile) == 0)
         {
         //DPRINTF(( "CallEPM: EPMIniPath already changed\n"));
         break;
         }

      // write filename of NEPMD.INI
      rc = PrfWriteProfileString( HINI_USER, INI_APP_EPM, INI_KEY_EPMINIPATH, szIniFile);
      DPRINTF(( "CallEPM: write new value: EPMIniPath = %s, rc = %u\n", szIniFile, rc));
      if (!(rc == TRUE))  // on error
         break;

      // Bug in ETK:
      // On startup of EPM, when the ini doesnot exist on disk (but in
      // memory, because it was opened and new values are already written),
      // EPM reads values from the default ini file \OS2\EPM.INI (or maybe
      // with the path of EPM.EXE).
      // Even E code returns the wrong value then:
      //    NepmdIni = queryprofile( HINI_USERPROFILE, 'EPM', 'EPMIniPath')
      //    -> The filename of EPM.INI is always returned, if NEPMD.INI
      //       was not already written to disk.
      // Following values, used by C functions only, are effected:
      //    EPM.INI -> EPM -> DEFAULTSWP     (EPM window position)
      //    EPM.INI -> UCMenu -> ConfigInfo  (toolbar style)
      // The 2nd startup is always ok then.

      // check if dir exists
      strcpy( szTmp, szIniFile);
      // isolate path of IniFile
      strcpy( strrchr( szTmp, '\\'), "");
      rc = NO_ERROR;
      if (!DirExists( szTmp))
         {
         rc = ERROR_PATH_NOT_FOUND;
         sprintf( szMessage,
                  "Fatal error #3: the directory"
                  " \"%s\" doesn\'t exist.\n\n"
                  "NEPMD is not properly installed,"
                  " repeat the installation via WarpIN!\n\n"
                  "If that problem still persists, check"
                  " if your UserDir (e.g. \"NEPMD\\myepm\") and"
                  " its subdirectory \"bin\" exist and if they"
                  " are writable.\n\n", szTmp);
         SHOWFATALERROR( HWND_DESKTOP, szMessage);
         break;
         }

      if (FileExists( szIniFile))
         break;

      // create a zero byte file immediately
      pfile = fopen( strupr( szIniFile), "a+b");

      if (pfile)
         {
         fclose( pfile);
         DPRINTF(( "CallEPM: empty ini file created\n"));
         break;
         }
      else
         {
         rc = ERROR_PATH_NOT_FOUND;
         sprintf( szMessage,
                  "Fatal error #4: \"%s\""
                  " could not be created, probably because the"
                  " drive is read-only.\n\n"
                  "NEPMD is not properly installed,"
                  " repeat the installation via WarpIN!\n\n"
                  "If that problem still persists, check"
                  " if your UserDir (e.g. \"NEPMD\\myepm\") and"
                  " its subdirectory \"bin\" exist and if they"
                  " are writable.\n\n", szIniFile);
         SHOWFATALERROR( HWND_DESKTOP, szMessage);
         break;
         }

      } while (FALSE);

   // don't start EPM on error, to avoid hidden and partly initiated window
   if (rc != NO_ERROR)
      break;

   // start program - fill STARTDATA
   memset( &startdata, 0, sizeof( startdata));
   startdata.Length      = sizeof( startdata);
   if (fAsync == FALSE)
      {
      startdata.Related     = SSF_RELATED_CHILD;
      startdata.TermQ       = szTermQueueName;
      }
   else
      {
      startdata.Related     = SSF_RELATED_INDEPENDENT;
      }
   startdata.InheritOpt  = SSF_INHERTOPT_PARENT;
   startdata.SessionType = SSF_TYPE_PM;
   //startdata.FgBg        = SSF_FGBG_FORE;
   startdata.FgBg        = SSF_FGBG_BACK;  // EPM starts hidden and brings itself to the top (see MAIN.E)
   startdata.PgmName     = szExecutable;
   startdata.PgmInputs   = ppibEPM->pib_pchcmd + strlen( ppibEPM->pib_pchcmd) + 1;
   startdata.Environment = pszEnv;

   rc = DosStartSession( &startdata, &ulSession, &pid);
   // rc = 457 = ERROR_SMG_START_IN_BACKGROUND
   DPRINTF(( "CallEPM: call %s\n   params = >>%s<<\n   rc = %u\n", startdata.PgmName, startdata.PgmInputs, rc));
   if ((rc == NO_ERROR) || (rc == ERROR_SMG_START_IN_BACKGROUND))
      fEpmStarted = TRUE;

   if (fEpmStarted != TRUE)
      break;

   if (fAsync == FALSE)
      {
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
      }
   else
      // close unused termination queue
      DosCloseQueue( hqTermQueue);  // ignore errors here

   } while (FALSE);

// cleanup
if (pszEnv) free( pszEnv);
return rc;
}


// -----------------------------------------------------------------------------

INT main ( INT argc, PSZ argv[], PSZ envv[])
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

DPRINTF(( "CallEPM: >>> rc = %u/0x%04x\n", rc, rc));

return rc;

}

