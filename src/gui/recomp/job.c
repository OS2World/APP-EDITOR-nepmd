/****************************** Module Header *******************************
*
* Module Name: job.c
*
* Job state machine for recomp GUI and thread starting functions for
* background tasks.
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
#define INCL_WIN
#define INCL_ERRORS
#include <os2.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// disable debug messages for this module
// #undef DEBUG

#include "common.h"
#include "macros.h"
#include "recomp.rch"

#include "job.h"
#include "dde.h"
#include "ddereload.h"
#include "ddelog.h"
#include "client.h"
#include "pmres.h"
#include "file.h"
#include "eas.h"
#include "process.h"

// ---------------------------------------------------------------------

static   PSZ            pszAppName       = __APPNAME__;
static   PSZ            pszBackExtension = ".bak";

static   PSZ            pszCompileEaName = "RECOMP.COMPILEFLAG";

static   PSZ            pszExenameMacroCompiler = EXENAME_MACROCOMPILER;

static   PSZ            pszTokenMaxCountFileList = TOKEN_MAXCOUNT_FILELIST;
static   PSZ            pszTokenFileinfo         = TOKEN_FILEINFO;


// define type of our thread functions
typedef void(_Optlink TFN)(void*);
typedef TFN *PTFN;

// ---------------------------------------------------------------------

static VOID _waitForThread( PTID ptid, PSZ pszType)
{
         APIRET         rc = NO_ERROR;

if ((ptid) && (*ptid))
   {
   rc = DosWaitThread( ptid, DCWW_WAIT);
   if ((rc == NO_ERROR) || (rc == ERROR_INVALID_THREADID))
      DPRINTF(( "JOB: %s thread has ended\n", pszType));
   else
      DPRINTF(( "JOB: waiting for %s thread failed, rc=%u\n", pszType, rc));
   }

}

// ---------------------------------------------------------------------

static VOID _waitForThreads( PWINDOWDATA pwd)
{
do
   {
   // check parms
   if (!pwd)
      break;

   DPRINTF(( "JOB: waiting for threads to end\n", pwd->tidCompile));
   _waitForThread( &pwd->tidCompile, "compile");
   _waitForThread( &pwd->tidReload,  "reload");
   _waitForThread( &pwd->tidLog,     "log");
   } while (FALSE);

return;
}

// ---------------------------------------------------------------------

static APIRET _discardFilelists( PWINDOWDATA pwd)
{
         APIRET         rc = NO_ERROR;
         ULONG          i,j;
         PSZ            *ppszFileList;

do
   {
   // check parms
   if (!pwd)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   for (i = 0; i < pwd->ulFileListIndex; i++)
      {


      if (pwd->appszFiles[ i])
         {
         // free this filelist
         for (ppszFileList = pwd->appszFiles[ i], j = 0;
                 j < pwd->aulFileCount[ i];
                 ppszFileList++, j++)
            {
            if (*ppszFileList)
               {
               free( *ppszFileList);
               *ppszFileList = NULL;
               }
            }
         pwd->aulFileCount[ i] = 0;
         free( pwd->appszFiles[ i]);
         pwd->appszFiles[ i] = NULL;
         }
      }

   // reset file index
   pwd->ulFileListIndex = 0;

   } while (FALSE);

// cleanup
return rc;
}

// ---------------------------------------------------------------------

static VOID _Optlink ReloadThread( PVOID pvParm)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

         HAB            hab = NULLHANDLE;
         HMQ            hmq = NULLHANDLE;

         PHWND          phwndNotify;
         HWND           hwnd;

         PWINDOWDATA    pwd;
         BOOL           fRequestTermination;
         ULONG          ulFilesLoaded;

do
   {

   DPRINTF(( "JOB: RELOAD: thread starts\n"));
   // check parm
   if (!pvParm)
      break;

   // get PM resources for this thread
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

   phwndNotify = (PHWND)pvParm;
   hwnd = *phwndNotify;          // keep macros compiling
   if (!WinIsWindow( CURRENTHAB, hwnd))
      break;

   // make all subsequent calls and macros happy with hwnd
   pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

   // first of all wait for EPM to properly close
   // this may interfere if reloading takes place to quick
   DosSleep( RELOAD_WAITBEFORERELOAD);

   // now go through the file list
   for (i = 0; i < pwd->ulFileListIndex; i++)
      {
      if (pwd->appszFiles[ i])
         {
         fRequestTermination = (i  + 1 == pwd->ulFileListIndex);

         DPRINTF(( "JOB: RELOAD: starting EPM with filelist %u\n", i + 1));

         ulFilesLoaded = 0;
         ReloadFilelist( hwnd, i, pwd->appszFiles[ i], pwd->aulFileCount[ i],
                         pwd->szMacroFile, fRequestTermination, &ulFilesLoaded );

         DPRINTF(( "JOB: RELOAD: %u files loaded for filelist %u\n", ulFilesLoaded, i + 1));
         }
      }

   // reset file index
   pwd->ulFileListIndex = 0;

   // wait for all EPM instances to process the RX macro command
   // this helps for properly loading the logfile if required
   DosSleep( RELOAD_WAITBEFORERELOAD);


   } while (FALSE);

// tell that we are done
UPDATE_JOB_STATUS;

DPRINTF(( "JOB: RELOAD: thread ends\n"));

// cleanup
if (hmq) WinDestroyMsgQueue( hmq);
if (hab) WinTerminate( hab);
if (phwndNotify) free( phwndNotify);
_endthread();
}

// ---------------------------------------------------------------------

static VOID _Optlink CompileThread( PVOID pvParm)
{
         APIRET         rc = NO_ERROR;
         PSZ            p;

         HAB            hab = NULLHANDLE;
         HMQ            hmq = NULLHANDLE;

         PHWND          phwndNotify;
         HWND           hwnd;

         PWINDOWDATA    pwd;

         CHAR           szCommand[ 4 * _MAX_PATH + 40];

         CHAR           szCompileFlag[ 10];
         ULONG          ulFlagLen;

do
   {

   DPRINTF(( "JOB: COMPILE: thread starts\n"));
   // check parm
   if (!pvParm)
      break;

   // get PM resources for this thread
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

   phwndNotify = (PHWND)pvParm;
   hwnd = *phwndNotify;          // keep macros compiling
   if (!WinIsWindow( CURRENTHAB, hwnd))
      break;

   // make all subsequent calls and macros happy with hwnd
   pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

   // attach EA to file in order to know, if it is
   // replaced by the EPM macro compiler
   // ignore error here, as the file may not exist
   WriteStringEa( pwd->szTargetFile, pszCompileEaName, "1");


   // execute program
   sprintf( szCommand, "%s /V %s %s > %s 2>&1",
                       pwd->szCompilerExecutable,
                       pwd->szSourceFile,
                       pwd->szTargetFile,
                       pwd->szLogFile);

   DPRINTF(( "JOB: COMPILE: with: %s\n", szCommand));

   ExecVioCommandSession( pwd->pszEpmEnv, __APPNAME__, szCommand, FALSE);

   DPRINTF(( "JOB: COMPILE: rc is %u\n", rc));

   // check if EA is there
   // if yes, the old file has not been touched -> compile error
   ulFlagLen = sizeof( szCompileFlag);
   rc = QueryStringEa( pwd->szTargetFile, pszCompileEaName, szCompileFlag, &ulFlagLen);
   pwd->fCompileSuccessful = (rc == ERROR_INVALID_EA_NAME);

   } while (FALSE);


// tell that we are done
UPDATE_JOB_STATUS;

DPRINTF(( "JOB: COMPILE: thread ends\n"));

// cleanup
if (hmq) WinDestroyMsgQueue( hmq);
if (hab) WinTerminate( hab);
if (phwndNotify) free( phwndNotify);
_endthread();
}

// ---------------------------------------------------------------------

static VOID _Optlink LogThread( PVOID pvParm)
{
         APIRET         rc = NO_ERROR;
         PSZ            p;

         HAB            hab = NULLHANDLE;
         HMQ            hmq = NULLHANDLE;

         PHWND          phwndNotify;
         HWND           hwnd;

         PWINDOWDATA    pwd;

do
   {

   DPRINTF(( "JOB: LOG: thread starts\n"));
   // check parm
   if (!pvParm)
      break;

   // get PM resources for this thread
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

   phwndNotify = (PHWND)pvParm;
   hwnd = *phwndNotify;          // keep macros compiling
   if (!WinIsWindow( CURRENTHAB, hwnd))
      break;

   // make all subsequent calls and macros happy with hwnd
   pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

   DPRINTF(( "JOB: LOG: start loading\n"));

   rc = LoadErrantFileFromLog( hwnd, pwd->hmodResource, pwd->szLogFile, pwd->szMacroFile);

   DPRINTF(( "JOB: LOG: end loading, rc=%u\n", rc));


   } while (FALSE);

// tell that we are done
UPDATE_JOB_STATUS;

DPRINTF(( "JOB: LOG: thread ends\n"));

// cleanup
if (hmq) WinDestroyMsgQueue( hmq);
if (hab) WinTerminate( hab);
if (phwndNotify) free( phwndNotify);
_endthread();
}

// ---------------------------------------------------------------------

static VOID _startThread( HWND hwnd, PTFN ptfn, PTID ptid)
{
         PHWND          phwnd;
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

phwnd = malloc( sizeof( hwnd));
if ((phwnd) && (ptid))
   {
   *phwnd = hwnd;
   *ptid = _beginthread( ptfn, NULL, 16384, phwnd);
   }
}

// ---------------------------------------------------------------------

MRESULT EXPENTRY JobWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
         MRESULT        mr = 0;

if (msg == WM_USER_UPDATE_JOBMACHINE)
   {
            PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);
            APIRET         rc = NO_ERROR;
            ULONG          i;
            PSZ            p;
            CHAR           szCommand[ _MAX_PATH * 2];

            // following values are non-zero when UPDATE_JOB_STATUS_DATA is used
            HWND           hwndServer = LONGFROMMP( mp1);
            PSZ            pszData    = PVOIDFROMMP( mp2);
            ULONG          ulServerIndex;


   switch (pwd->ulJobStatus)
      {
      case JOB_ACTION_INITIALIZE:
         DPRINTF(( "JOB: INITIALIZE\n"));
         pwd->fCompileSuccessful = FALSE;
         pwd->ulJobStatus        = JOB_STATUS_INITIALIZING;
         UPDATE_JOB_STATUS;
         break;

      case JOB_STATUS_INITIALIZING:
         {
                  CHAR           szMessage[ _MAX_PATH];
                  CHAR           szSourcePath[ _MAX_PATH];
                  BOOL           fExit = FALSE;

         DPRINTF(( "JOB: INITIALIZED: start job\n"));

         // prepare macro - needed for handling open files, reloading and loading of logfile
         rc = WriteResourceToTmpFile( pwd->hmodResource, RT_USER_DATAFILE, IDRES_MACROFILE_RECOMP_COMPILED,
                                      pwd->szMacroFile, sizeof( pwd->szMacroFile));
         if (rc != NO_ERROR)
            {
            ShowNlsError( hwnd, pwd->hmodResource, pszAppName, IDSTR_CANNOT_WRITE_MACRO);
            WinPostMsg( hwnd, WM_CLOSE, 0,0);
            break;
            }

         // determine sourcename
         strcpy( pwd->szSourceFile,
                 (pwd->fTestUseErrorSource) ?
                    TEST_ALTSOURCENAME : EPM_SOURCENAME);

         // check for EPM compiler
         if (FileInPath( NULL, pszExenameMacroCompiler,
                         pwd->szCompilerExecutable,
                         sizeof( pwd->szCompilerExecutable)) != NO_ERROR)
            {
            ShowNlsError( hwnd, pwd->hmodResource, pszAppName,
                          IDSTR_CANNOT_FIND_COMPILER, pszExenameMacroCompiler);
            fExit = TRUE;
            }

         // check for source file
         // - use fullname of sourcefile to determine target directory
         else if (FileInPath( "EPMPATH", pwd->szSourceFile,
                  szSourcePath, sizeof( szSourcePath)) != NO_ERROR)
            {
            ShowNlsError( hwnd, pwd->hmodResource, pszAppName,
                          IDSTR_CANNOT_FIND_SOURCEFILE, pwd->szSourceFile);
            fExit = TRUE;
            }

         if (fExit)
            {
            // don't show compile log
            pwd->fSkipLog = TRUE;

            // cancel operation
            ABORT_JOB;
            break;
            }

         // show some more details in debug log
         DPRINTF(( "JOB: macro compiler is: %s\n", pwd->szCompilerExecutable));
         DPRINTF(( "JOB: sourcefile is: %s\n", szSourcePath));
         DPRINTF(( "JOB: EPMPATH is: %s\n", getenv( "EPMPATH")));

         // determine target directory from source path if not given
         if (!strlen( pwd->szTargetDir))
            {
            p = strrchr( szSourcePath, '\\');
            *p = 0;
            strcpy( pwd->szTargetDir, szSourcePath);
            }

         // determine target and logname
         DPRINTF(( "JOB: target directory is: %s\n", pwd->szTargetDir));
         sprintf( pwd->szTargetFile, "%s\\"EPM_TARGETNAME, pwd->szTargetDir);
         sprintf( pwd->szLogFile,    "%s\\"EPM_COMPILELOG, pwd->szTargetDir);



         _discardFilelists( pwd);
         pwd->fExitProcessing = FALSE;
         pwd->fCompiled       = FALSE;

         pwd->ulJobStatus     = JOB_ACTION_LINK_MACRO;
         UPDATE_JOB_STATUS;
         }
         break;

      case JOB_ACTION_LINK_MACRO:
         DPRINTF(( "JOB: LINK_MACRO\n"));
         pwd->ulStatusCount = 0;
         if (pwd->ulConnectCount)
            {

            // next step: post link command
            pwd->ulJobStatus = JOB_STATUS_LINKING_MACRO;
            sprintf( szCommand, "link %s", pwd->szMacroFile);
            ExecuteEPMCommand( hwnd, szCommand);
            }
         else
            {
            // we go to recompile directly
            DPRINTF(( "JOB: skip: not linked\n"));
            pwd->ulJobStatus = JOB_ACTION_RECOMPILE_EPM;
            UPDATE_JOB_STATUS;
            }
         break;

      // ------------------------------------------------

      case JOB_STATUS_LINKING_MACRO:
         DPRINTF(( "JOB: LINKING_MACRO\n"));
         pwd->ulStatusCount++;
         if (pwd->ulStatusCount == pwd->ulConnectCount)
            {
            DPRINTF(( "JOB: all macros linked\n"));
            pwd->ulJobStatus = JOB_ACTION_SAVE_FILELIST;
            UPDATE_JOB_STATUS;
            }
         break;

      // ------------------------------------------------

      case JOB_ACTION_SAVE_FILELIST:
         {
                  PSZ            pszType;

         DPRINTF(( "JOB: SAVE_FILELIST\n"));
         pwd->ulStatusCount = 0;

         pwd->ulJobStatus = JOB_STATUS_SAVING_FILELIST;
         pszType = (pwd->cd.fDiscardUnsaved) ? "DISCARDUNSAVED" : "FAILONUNSAVED";
         DPRINTF(( "JOB: type is: %s\n", pszType));
         sprintf( szCommand, "recomp GETFILELIST %s" , pszType);
         ExecuteEPMCommand( hwnd, szCommand);
         }
         break;

      // ------------------------------------------------

      case JOB_STATUS_SAVING_FILELIST:
         {
                  ULONG          ulServerIndex = GetEPMServerIndex( hwnd, hwndServer);


         // is it data sent ? then save file list
         if (!pszData)
            {
            // count acknowledge
            DPRINTF(( "JOB: SAVING_FILELIST ack received\n"));
            pwd->ulStatusCount++;
            }
         else if (ulServerIndex == -1)
            {
            // when data received whe requite to have a valid server handle
            // in order to associate it with the correct file list
            break;
            }
         else
            {
            // allocate memory
            if (!strncmp( pszData, pszTokenMaxCountFileList, strlen( pszTokenMaxCountFileList)))
               {
                        ULONG          ulMaxFiles = atol( pszData + strlen( pszTokenMaxCountFileList));
                        ULONG          ulBufSize = ulMaxFiles * sizeof( PVOID);

               DPRINTF(( "JOB: allocating filelist %u for maximum of %u files, data is: %s\n", ulServerIndex + 1, ulMaxFiles, pszData));
               pwd->appszFiles[ ulServerIndex] = malloc( ulBufSize);
               pwd->aulFileCount[ ulServerIndex] = 0;
               if (!pwd->appszFiles[ ulServerIndex])
                  {
                  pwd->fExitProcessing = TRUE;
                  pwd->hwndFailedServer = hwndServer;
                  }
               pwd->ulFileListIndex = MAX( pwd->ulFileListIndex, ulServerIndex + 1);
               }

            // create a copy of the fileinfo
            else if (!strncmp( pszData, pszTokenFileinfo, strlen( pszTokenFileinfo)))
               {
                        PSZ            pszFileInfo = pszData + strlen( pszTokenFileinfo);
                        PSZ           *ppszTarget;
                        ULONG          ulFileIndex;


               // determine target address for the fileinfo
               ulFileIndex = pwd->aulFileCount[ ulServerIndex];
               ppszTarget = &pwd->appszFiles[ ulServerIndex][ulFileIndex];

               DPRINTF(( "JOB: saving fileinfo list %u file %u, data is: %s\n",
                         ulServerIndex + 1,
                         ulFileIndex + 1,
                         pszData));

               // check info and copy of it
               *ppszTarget = strdup( pszFileInfo);
               if ((!*pszData) || (!*ppszTarget))
                  {
                  pwd->fExitProcessing = TRUE;
                  pwd->hwndFailedServer = hwndServer;
                  }

               // count file index
               pwd->aulFileCount[ ulServerIndex]++;
               }

            // handle end of list
            else if (!strcmp( pszData, TOKEN_END_OF_FILELIST))
               {
               DPRINTF(( "JOB: saving filelist %u complete, data is: %s\n", ulServerIndex + 1, pszData));

               // count one acknowledge for all data received
               pwd->ulStatusCount++;
               }

            // bail out on error
            else if (!strcmp( pszData, TOKEN_UNSAVED))
               {
               // count one acknowledge for all data received
               pwd->ulStatusCount++;
               DPRINTF(( "JOB: unsaved flag found, exit flag set, data is: %s\n", pszData));
               pwd->fExitProcessing = TRUE;
               pwd->hwndFailedServer = hwndServer;
               pwd->fSkipLog = TRUE;
               }
            else
               {
               DPRINTF(( "JOB: unexpected data received, exit flag set, data is: %s\n", pszData));
               pwd->fSkipLog = TRUE;
               ABORT_JOB;
               }
            }

                                   // count one ACK and one DATA per filelist !
         if (pwd->ulStatusCount == (pwd->ulConnectCount * 2))
            {
            if (pwd->fExitProcessing)
               {

                        SWP            swp;
                        HWND           hwndFrame;

               // bring up the EPM window in question
               hwndFrame = WinQueryWindow( pwd->hwndFailedServer, QW_PARENT);
               WinQueryWindowPos( hwndFrame, &swp);
               WinSetWindowPos( hwndFrame, HWND_TOP, 0, 0, 0, 0,
                                SWP_ZORDER | ((swp.fl & SWP_MINIMIZE) ? SWP_RESTORE : 0));

               // show our error message
               ShowNlsError( hwnd, pwd->hmodResource, pszAppName, IDSTR_UNSAVED_FILES);

               // activate the EPM window
               WinSetFocus( HWND_DESKTOP, pwd->hwndFailedServer);

               // cancel operation
               ABORT_JOB;
               break;
               }

            DPRINTF(( "JOB: all filelists received\n"));
            pwd->ulJobStatus = JOB_ACTION_RECOMPILE_EPM;
            UPDATE_JOB_STATUS;
            }
         }
         break;

      // ------------------------------------------------

      case JOB_ACTION_RECOMPILE_EPM:
         DPRINTF(( "JOB: RECOMPILE_EPM\n"));
         pwd->ulJobStatus = JOB_STATUS_RECOMPILING_EPM;
         _startThread( hwnd, &CompileThread, &pwd->tidCompile);
         break;

      // ------------------------------------------------

      case JOB_STATUS_RECOMPILING_EPM:
         DPRINTF(( "JOB: RECOMPILING_EPM\n"));
         pwd->fCompiled = TRUE;

         if (!pwd->fCompileSuccessful)
            {
            ShowNlsError( hwnd, pwd->hmodResource, pszAppName, IDSTR_COMPILE_ERROR);
            ABORT_JOB;
            }
         else
            {
            pwd->ulJobStatus = JOB_ACTION_CLOSE_EPMWINDOWS;
            UPDATE_JOB_STATUS;
            }
         break;


      // ------------------------------------------------

      case JOB_ACTION_CLOSE_EPMWINDOWS:
         DPRINTF(( "JOB: CLOSE_EPMWINDOWS\n"));
         if (pwd->ulFileListIndex)
            {
            pwd->ulStatusCount = 0;
            pwd->ulJobStatus = JOB_STATUS_CLOSING_EPMWINDOWS;
            ExecuteEPMCommand( hwnd, "recomp CLOSEWINDOW");
            }
         else
            ABORT_JOB;
         break;

      // ------------------------------------------------

      case JOB_STATUS_CLOSING_EPMWINDOWS:
         DPRINTF(( "JOB: CLOSING_EPMWINDOWS\n"));
         pwd->ulStatusCount++;
                                   // count ACK
         if (pwd->ulStatusCount == pwd->ulConnectCount)
            {
            DPRINTF(( "JOB: all unsaved files closed\n"));
            pwd->ulJobStatus = JOB_ACTION_RELOAD_FILES;
            UPDATE_JOB_STATUS;
            }
         break;

      // ------------------------------------------------

      case JOB_ACTION_RELOAD_FILES:

         DPRINTF(( "JOB: RELOAD_FILES\n"));
         if (pwd->cd.fReloadFiles && pwd->ulFileListIndex)
            {
            pwd->ulJobStatus =  JOB_STATUS_RELOADING_FILES;
            _startThread( hwnd, &ReloadThread, &pwd->tidReload);
            }
         else
            {
            DPRINTF(( "JOB: skip: no filelists saved or reload files not selected\n"));
            ABORT_JOB;
            }
         break;

      // ------------------------------------------------

      case JOB_STATUS_RELOADING_FILES:
         DPRINTF(( "JOB: RELOADING_FILES\n"));
         DPRINTF(( "JOB: all files reloaded\n"));
         ABORT_JOB;
         break;

      // ------------------------------------------------

      case JOB_ACTION_LOADLOG:
         DPRINTF(( "JOB: LOADLOG"));
         pwd->ulJobStatus = JOB_STATUS_LOADINGLOG;

         // show log if desired or if an error occurred
         if (!pwd->fSkipLog)
            {
            if (pwd->fCompileSuccessful)
               {
               if ((pwd->fCompiled) && (pwd->cd.fShowCompileLog))
                  _startThread( hwnd, &LogThread, &pwd->tidLog);
               else
                  UPDATE_JOB_STATUS;
               }
            else
               _startThread( hwnd, &LogThread, &pwd->tidLog);

            // let thread update job status
            break;
            }
         else
            UPDATE_JOB_STATUS;

         break;

      // ------------------------------------------------

      case JOB_STATUS_LOADINGLOG:
         DPRINTF(( "JOB: LOADINGLOG\n"));

         // we are done
         pwd->ulJobStatus = JOB_ACTION_FINISH;
         UPDATE_JOB_STATUS;

         break;

      // ------------------------------------------------

      case JOB_ACTION_FINISH:
         DPRINTF(( "JOB: FINISH\n"));

#ifdef DEBUG_EX
         {
                  CHAR           szBackupCopy[ _MAX_PATH];
         sprintf( szBackupCopy, "%s\\recomp.ex", getenv( "TMP"));
         DosCopy( pwd->szMacroFile, szBackupCopy, DCPY_EXISTING);
         }
#endif

         pwd->ulJobStatus = JOB_STATUS_DONE;
         UPDATE_JOB_STATUS;

         break;

      // ------------------------------------------------

      case JOB_STATUS_DONE:
         DPRINTF(( "JOB: DONE\n"));


         // wait for threads to finish
         // warning: all threads not terminated until here
         // block the recomp GUI thread here, so the PM !!!
         _waitForThreads( pwd);

         // cleanup
         DosDelete( pwd->szMacroFile);

         // close job - this resets job machine and GUI
         WinPostMsg( hwnd, WM_USER_JOBDONE, 0, 0);

         DPRINTF(( "JOB: ENDED\n"));
         break;

      } // end switch (msg)

   // update status in GUI window
   UPDATE_STATS;
   }

return mr;
}

