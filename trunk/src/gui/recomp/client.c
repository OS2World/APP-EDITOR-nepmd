/****************************** Module Header *******************************
*
* Module Name: client.c
*
* PM client related routines and structures.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: client.c,v 1.1 2002-06-03 22:27:04 cla Exp $
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

#include <process.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// disable debug messages for this module
#undef DEBUG

#include "common.h"
#include "macros.h"
#include "recomp.rch"

#include "client.h"
#include "job.h"
#include "dde.h"
#include "frame.h"

// ---------------------------------------------------------------------

static   PSZ            pszNormalFont = NORMAL_ITEM_FONT;
static   PSZ            pszBoldFont   = BOLD_ITEM_FONT;

#define SETFONT(i,f) WinSetPresParam(WinWindowFromID(hwnd,i),PP_FONTNAMESIZE,strlen(f),f)

// ---------------------------------------------------------------------

static VOID _Optlink WatchThread( PVOID pvParm)
{
         APIRET         rc = NO_ERROR;
         HEV            hev = NULLHANDLE;
         ULONG          ulPostCount;
         PHWND          phwndNotify;

do
   {
   // check parm
   if (!pvParm)
      break;

   phwndNotify = (PHWND)pvParm;
   if (!WinIsWindow( CURRENTHAB, *phwndNotify))
      break;

   // get event sem handle
   rc = DosOpenEventSem( SEMNAME, &hev);
   if (rc != NO_ERROR)
      break;

   do
      {
      // wait for semaphore
      rc = DosWaitEventSem( hev, SEM_INDEFINITE_WAIT);
      if (rc != NO_ERROR)
         break;

      // completely reset semaphore
      do
         {
         rc = DosResetEventSem( hev, &ulPostCount);
         } while (!rc);
      if (rc != ERROR_ALREADY_RESET)
         break;

      // activate our window
      WinPostMsg( *phwndNotify, WM_USER_ACTIVATE, 0, 0);

      } while (TRUE);

   } while (FALSE);

// cleanup
if (phwndNotify) free( phwndNotify);
_endthread();
}

static VOID _startWatchThread( HWND hwnd)
{
         PHWND          phwnd;

phwnd = malloc( sizeof( hwnd));
if (phwnd)
   {
   *phwnd = hwnd;
   _beginthread( &WatchThread, NULL, 16384, phwnd);
   }
}

// ---------------------------------------------------------------------

MRESULT EXPENTRY ClientWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)

{

         APIRET         rc = NO_ERROR;
         BOOL           fResult = FALSE;
         PWINDOWDATA    pwd = (PWINDOWDATA) WinQueryWindowULong( hwnd, QWL_USER);

static   HPOINTER       hptrIcon = NULLHANDLE;
static   HWND           hwndMenu = NULLHANDLE;
static   BOOL           fDump = 0; // for debug purposes only

switch (msg)
   {

   // ---------------------------------------------------------------

   case WM_INITDLG:
      {
               MENUITEM       mi;

      // store parameter and initialize
      WinSetWindowULong( hwnd, QWL_USER, (ULONG) mp2);
      pwd = (PWINDOWDATA) mp2;

      // load icon and menu
      hptrIcon = WinLoadPointer( HWND_DESKTOP, pwd->hmodResource, IDRES_FRAME);
      WinSendMsg( hwnd, WM_SETICON, (MPARAM) hptrIcon, 0L);
      hwndMenu = WinLoadMenu( hwnd, pwd->hmodResource, IDRES_FRAME);
      WinSendMsg( hwnd, WM_UPDATEFRAME, (MPARAM) FCF_MENU, 0L);

      // init controls
      ENABLEWINDOW( hwnd, IDPBS_CANCEL, FALSE);

      // init
      pwd->ulLastStatus = -1;
      UPDATE_STATS;

      // set window position
      WinSetWindowPos( hwnd,
                       HWND_TOP,
                       pwd->cd.swp.x,
                       pwd->cd.swp.y,
                       pwd->cd.swp.cx,
                       pwd->cd.swp.cy,
                       SWP_RESTORE | SWP_MOVE | SWP_SHOW | SWP_ACTIVATE);

      // start watch thread
      _startWatchThread( hwnd);

      // autostart here
      if (pwd->fAutoStart)
         WinPostMsg( hwnd, WM_COMMAND, MPFROMLONG( IDPBS_START), MPFROM2SHORT( CMDSRC_PUSHBUTTON, FALSE));

      return (MRESULT) FALSE;
      }
      break;

   // ---------------------------------------------------------------

   case WM_COMMAND:
      switch (SHORT1FROMMP( mp1))
         {

         case IDPBS_START:
            // connect
            ConnectToEPM( hwnd);
            pwd->fLastConnected = ConnectedToEPM( hwnd);
            UPDATE_STATS;

            // proceed anyway
            ENABLEWINDOW( hwnd, IDPBS_START,  FALSE);
            ENABLEWINDOW( hwnd, IDPBS_CANCEL, TRUE);
            ENABLEWINDOW( hwnd, IDPBS_EXIT,   FALSE);

            // proceed with first step
            UPDATE_JOB_STATUS;
            break;

         case IDPBS_CANCEL:
            WinPostMsg( hwnd, WM_USER_JOBDONE, 0, 0);
            break;

         case IDMEN_FILE_EXIT:
         case IDPBS_EXIT:
            WinPostMsg( hwnd, WM_CLOSE, 0, 0);
            break;

         case IDMEN_HELP_INFO:
            WinDlgBox( HWND_DESKTOP, hwnd, WinDefDlgProc, pwd->hmodResource, IDDLG_INFO, NULL);
            break;

         case IDMEN_HELP_PARMS:
            ShowHelp( hwnd, pwd->hmodResource);
            break;

         case IDMEN_SETTINGS_DISCARD_UNSAVED:
            pwd->cd.fDiscardUnsaved = !pwd->cd.fDiscardUnsaved;
            UPDATE_STATS;
            break;

         case IDMEN_SETTINGS_RELOAD_FILES:
            pwd->cd.fReloadFiles = !pwd->cd.fReloadFiles;
            UPDATE_STATS;
            break;

         case IDMEN_SETTINGS_SHOW_COMPILELOG:
            pwd->cd.fShowCompileLog = !pwd->cd.fShowCompileLog;
            break;

         }
      return (MRESULT) 0;
      break;

   // ---------------------------------------------------------------

   case WM_WINDOWPOSCHANGED:
      {
               SWP            swp;

      // store window data if not minimized of maximized
      WinQueryWindowPos( hwnd, &swp);
      if ((pwd) &&
          (!(swp.fl & (SWP_MINIMIZE | SWP_MAXIMIZE))) &&
          (WinIsWindowVisible( hwnd)))
         memcpy( &pwd->cd.swp, &swp, sizeof( SWP));
      }
      break;

   // ---------------------------------------------------------------

   case WM_INITMENU:
      if (pwd->fAutoStart)
         {
         ENABLEMENUITEM( hwndMenu, IDMEN_SETTINGS_DISCARD_UNSAVED, FALSE);
         ENABLEMENUITEM( hwndMenu, IDMEN_SETTINGS_RELOAD_FILES,    FALSE);
         ENABLEMENUITEM( hwndMenu, IDMEN_SETTINGS_SHOW_COMPILELOG, FALSE);
         }
      else
         {
         SETMENUCHECKVALUE( hwndMenu, IDMEN_SETTINGS_DISCARD_UNSAVED, pwd->cd.fDiscardUnsaved);
         SETMENUCHECKVALUE( hwndMenu, IDMEN_SETTINGS_RELOAD_FILES,    pwd->cd.fReloadFiles);
         SETMENUCHECKVALUE( hwndMenu, IDMEN_SETTINGS_SHOW_COMPILELOG, pwd->cd.fShowCompileLog);
         }
      break;

   // ---------------------------------------------------------------

   case WM_DESTROY:

      // free resources
      if (hptrIcon) WinDestroyPointer( hptrIcon);
      if (hwndMenu) WinDestroyWindow( hwndMenu);
      break;

   // ---------------------------------------------------------------

   case WM_USER_ACTIVATE:
      WinSetFocus( HWND_DESKTOP, hwnd);
      break;

   // ---------------------------------------------------------------

   case WM_USER_UPDATE_STATS:
      {
         ULONG          ulBulletId = IDCTL_UNUSED;
         ULONG          ulActiveId = IDCTL_UNUSED;

      // do not update for JOB_STATUS_SAVING_FILELIST, if status did not change
      if (pwd->ulJobStatus == JOB_STATUS_SAVING_FILELIST)
         if (pwd->ulLastStatus == pwd->ulJobStatus)
            break;
      pwd->ulLastStatus = pwd->ulJobStatus;

      // update now
      ENABLEWINDOW( hwnd, IDTXT_CLOSE_EPMWINDOWS, pwd->fLastConnected);
      ENABLEWINDOW( hwnd, IDTXT_SAVE_FILELISTS,   pwd->fLastConnected);
      ENABLEWINDOW( hwnd, IDTXT_RELOAD_FILES,     (pwd->cd.fReloadFiles && pwd->fLastConnected));

      DPRINTF(( "CLIENT: update stats with %u\n", (pwd->ulJobStatus)));

      switch (pwd->ulJobStatus)
         {

         case JOB_STATUS_INITIALIZING:
            ulBulletId = IDBLT_PREPARE;
            ulActiveId = IDTXT_PREPARE;
            break;

         case JOB_STATUS_SAVING_FILELIST:
            ulBulletId = IDBLT_SAVE_FILELISTS;
            ulActiveId = IDTXT_SAVE_FILELISTS;
            break;

         case JOB_STATUS_RECOMPILING_EPM:
            ulBulletId = IDBLT_RECOMPILE_EPM;
            ulActiveId = IDTXT_RECOMPILE_EPM;
            break;

         case JOB_STATUS_CLOSING_EPMWINDOWS:
            ulBulletId = IDBLT_CLOSE_EPMWINDOWS;
            ulActiveId = IDTXT_CLOSE_EPMWINDOWS;
            break;

         case JOB_STATUS_RELOADING_FILES:
            ulBulletId = IDBLT_RELOAD_FILES;
            ulActiveId = IDTXT_RELOAD_FILES;
            break;

         }

       // turn all bullets off first
      SHOWWINDOW( hwnd, IDBLT_PREPARE,          FALSE);
      SHOWWINDOW( hwnd, IDBLT_SAVE_FILELISTS,   FALSE);
      SHOWWINDOW( hwnd, IDBLT_RECOMPILE_EPM,    FALSE);
      SHOWWINDOW( hwnd, IDBLT_CLOSE_EPMWINDOWS, FALSE);
      SHOWWINDOW( hwnd, IDBLT_RELOAD_FILES,     FALSE);

      if (pwd->ulJobStatus > JOB_ACTION_INITIALIZE)
         {
         // turn one bullet on
         SHOWWINDOW( hwnd, ulBulletId, TRUE);

         // boldprint current item
         // -  reset font of items twice, some 
         //    items did not change  otherwise
         SETFONT( ulActiveId, pszBoldFont);
         SETFONT( ulActiveId, pszBoldFont);
         }

      }
      break;

   // ---------------------------------------------------------------

   case WM_USER_JOBDONE:
      // close connections if open
      DisconnectFromEPM( hwnd);

      // reset buttons
      ENABLEWINDOW( hwnd, IDPBS_START,  TRUE);
      ENABLEWINDOW( hwnd, IDPBS_CANCEL, FALSE);
      ENABLEWINDOW( hwnd, IDPBS_EXIT,   TRUE);

      RESET_STATUS;  // reset status of job machine
      UPDATE_STATS;  // update GUI controls

      // reset font of items separately
      // -  reset font of items twice, some 
      //    items did not change  otherwise
      WinPostMsg( hwnd, WM_USER_RESETITEMFONT, 0, 0);
      WinPostMsg( hwnd, WM_USER_RESETITEMFONT, 0, 0);

      // quit here if program was autostarted
      if (pwd->fAutoStart)
         WinPostMsg( hwnd, WM_QUIT, 0, 0);

      break;

   // ---------------------------------------------------------------
   case WM_USER_RESETITEMFONT:
      SETFONT( IDTXT_PREPARE,          pszNormalFont);
      SETFONT( IDTXT_SAVE_FILELISTS,   pszNormalFont);
      SETFONT( IDTXT_RECOMPILE_EPM,    pszNormalFont);
      SETFONT( IDTXT_CLOSE_EPMWINDOWS, pszNormalFont);
      SETFONT( IDTXT_RELOAD_FILES,     pszNormalFont);
      break;

   } // end switch (msg)

// perform DDE actions
DdeWindowProc( hwnd, msg, mp1, mp2);

// perform job machine actions
JobWindowProc( hwnd, msg, mp1, mp2);

return WinDefDlgProc( hwnd, msg, mp1, mp2);
}

