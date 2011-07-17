/****************************** Module Header *******************************
*
* Module Name: job.h
*
* Header for job state machine for recomp GUI
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

#ifndef JOB_H
#define JOB_H

// private PM messages
#define WM_USER_UPDATE_JOBMACHINE    (WM_USER + 0x2000)
#define UPDATE_JOB_STATUS            WinPostMsg( hwnd, WM_USER_UPDATE_JOBMACHINE, 0, 0)
#define UPDATE_JOB_STATUS_DATA(h, p) WinPostMsg( hwnd, WM_USER_UPDATE_JOBMACHINE, MPFROMLONG(h), MPFROMP(p))
#define ABORT_JOB                    { pwd->ulJobStatus = JOB_ACTION_LOADLOG; UPDATE_JOB_STATUS;}


// job status
#define JOB_ACTION_INITIALIZE                0
#define JOB_ACTION_LINK_MACRO                1
#define JOB_ACTION_SAVE_FILELIST             2
#define JOB_ACTION_RECOMPILE_EPM             3
#define JOB_ACTION_CLOSE_EPMWINDOWS          4
#define JOB_ACTION_RELOAD_FILES              5
#define JOB_ACTION_LOADLOG                   6
#define JOB_ACTION_FINISH                    7

#define JOB_STATUS_INITIALIZING            100
#define JOB_STATUS_LINKING_MACRO           101
#define JOB_STATUS_SAVING_FILELIST         102
#define JOB_STATUS_RECOMPILING_EPM         103
#define JOB_STATUS_CLOSING_EPMWINDOWS      104
#define JOB_STATUS_RELOADING_FILES         105
#define JOB_STATUS_LOADINGLOG              106
#define JOB_STATUS_DONE                    107


#define RESET_STATUS                (pwd->ulJobStatus = JOB_ACTION_INITIALIZE)
#define JOB_RUNNING                 (pwd->ulJobStatus != JOB_ACTION_INITIALIZE)

// prototypes
MRESULT EXPENTRY JobWindowProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);

#endif // JOB_H

