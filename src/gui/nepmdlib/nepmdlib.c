/****************************** Module Header *******************************
*
* Module Name: nepmdlib.c
*
* Routines of the NEPMD library DLL.
* Coutnerpart to this DLL is nepmdlib.e/.ex.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.c,v 1.22 2002-09-02 20:09:25 cla Exp $
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

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#define INCL_ERRORS
#define INCL_DOS
#define INCL_WIN
#include <os2.h>

#define OS2VERSION 20
#include <EDLL.h>

#include "macros.h"
#include "nepmdlib.h"
#include "file.h"
#include "module.h"
#include "instval.c"
#include "eas.h"
#include "tmf.h"

// some useful macros
#define EPMINSERTTEXT(t)          EtkInsertTextBuffer( hwndClient, 0, strlen( t), t, 0x100);
#define LOADSTRING(m,t)           TmfGetMessage( NULL, 0, t, sizeof( t), m, szMessageFile, &ulMessageLen)
#define STRING_INTERNALERROR      "\n\n>>> INTERNAL ERROR:"
#define EPMMODULEVERSION(m,t)     _queryModuleStamp( m, t, sizeof( t))

#define INSERT_EPM_MODULEVERSION( h, f, m, mod) _insertModuleStamp( TRUE, h, f, m, mod)
#define INSERT_NEPMD_MODULEVERSION( h, f, m, mod) _insertModuleStamp( FALSE, h, f, m, mod)



// ------------------------------------------------------------------------------

static APIRET _executeEPMCommand( HWND hwndClient, PSZ pszCommand, ...)
{
         APIRET         rc = NO_ERROR;
         CHAR           szFullCommand[ 512];
         va_list        arg_ptr;

// send command to EPM
va_start (arg_ptr, pszCommand);
vsprintf( szFullCommand, pszCommand, arg_ptr);
rc = EtkExecuteCommand( hwndClient, szFullCommand);
va_end (arg_ptr);
return rc;
}

// ------------------------------------------------------------------------------

static APIRET _insertMessage( HWND hwndClient, PSZ pszFilename, PSZ pszMessageName, ...)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszMessage = NULL;
         va_list        arg_ptr;

         ULONG          ulBuflen = 8192;
         ULONG          ulMessageLen;

do
   {
   // check parms
   if ((!hwndClient)   ||
       (!pszFilename)  ||
       (!pszMessageName))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get memory
   pszMessage = malloc( ulBuflen);
   if (!pszMessage)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   memset( pszMessage, 0, ulBuflen);

   va_start (arg_ptr, pszMessageName);
   rc = TmfGetMessage( (PSZ*)arg_ptr, 9, pszMessage, ulBuflen,
                       pszMessageName, pszFilename, &ulMessageLen);
   va_end (arg_ptr);
   if (rc != NO_ERROR)
      sprintf( pszMessage, STRING_INTERNALERROR "message %s could not be retrieved, rc=%u\n\n",
               pszMessageName, rc);

   // insert result
   EPMINSERTTEXT( pszMessage);

   } while (FALSE);

// cleanup
if (pszMessage) free( pszMessage);
return rc;
}

// ------------------------------------------------------------------------------

static VOID _insertModuleStamp( BOOL fEpmModule, HWND hwndClient, PSZ pszFilename, PSZ pszMessageName,  PSZ pszModuleName)
{
         HAB            hab = WinQueryAnchorBlock( HWND_DESKTOP);
         HMODULE        hmodule = NULLHANDLE;
         CHAR           szModuleName[ _MAX_PATH];
         CHAR           szVersionStamp[ 32];

         CHAR           szFullname[ _MAX_PATH];
         FILESTATUS3    fs3;
         CHAR           szFilestamp[ 32];

do
   {
   // check parms
   if ((!pszFilename)    ||
       (!pszMessageName) ||
       (!pszModuleName))
      break;

   // query module handles for DLLs only (when a name is specified)
   strupr( pszModuleName);
   if (strstr( pszModuleName, ".DLL"))
      DosQueryModuleHandle( pszModuleName, &hmodule);

   if (fEpmModule)
      {
      // load version string
      if (!WinLoadString( hab, hmodule, 65535, sizeof( szVersionStamp), szVersionStamp))
         break;
      }
   else
      {
      strcpy( szVersionStamp, "");
      }

   // get filestamp from filesystem
   if (!hmodule)
      {
      if (fEpmModule)
         {
                  PPIB           ppib;
                  PTIB           ptib;

         // now get handle also for EPM.EXE
         DosGetInfoBlocks( &ptib,&ppib);
         hmodule = ppib->pib_hmte;
         }
      else
         DosQueryModuleHandle( pszModuleName, &hmodule);
      }

   DosQueryModuleName( hmodule, sizeof( szFullname), szFullname);
   DosQueryPathInfo( szFullname, FIL_STANDARD, &fs3, sizeof( fs3));
   DPRINTF(( "\n%s: handle: %u, fullname: %s\n", pszModuleName, hmodule, szFullname));
   // FILESTATUS3
   sprintf( szFilestamp, "%u/%02u/%02u %2u:%02u:%02u",
            fs3.fdateLastWrite.year + 1980,
            fs3.fdateLastWrite.month,
            fs3.fdateLastWrite.day,
            fs3.ftimeLastWrite.hours,
            fs3.ftimeLastWrite.minutes,
            fs3.ftimeLastWrite.twosecs * 2);


   // cut off name from fullname to obtain directory
   strcpy( strrchr( szFullname, '\\'), "");

   // take left aligned modulename from fullname (works in all cases!)
   sprintf( szModuleName, "%-12s", &szFullname[ strlen( szFullname) + 1]);

   // insert result
   _insertMessage( hwndClient, pszFilename, pszMessageName,
                   szModuleName, szFilestamp, szVersionStamp, szFullname);

   } while (FALSE);

return;
}

// ------------------------------------------------------------------------------

static APIRET _getRexxError( APIRET rc, PSZ pszBuffer, ULONG ulBuflen)
{
static   CHAR           szErrorTag[] = "ERROR:";
         CHAR           szErrorValue[ 20];

// act on error only
if (rc != NO_ERROR)
   {
   // we can act only if buffer is large enough
   if (ulBuflen >= sizeof( szErrorTag))
      {
      // assemble error tag with reason code
      sprintf( szErrorValue, "ERROR:%u", rc);
      if (strlen( szErrorValue) + 1 > ulBuflen)
         // copy only error tag
         strcpy( pszBuffer, szErrorTag);
      else
         strcpy( pszBuffer, szErrorValue);
      }
   }

return rc;
}

// ##############################################################################

BOOL EXPENTRY NepmdAlarm( PSZ pszAlarmStyle)
{
         BOOL           fResult = FALSE;
         ULONG          ulAlarmStyle = WA_NOTE;
         ULONG          i;

static   PSZ            apszAlarmStyle[] = { "WARNING", "NOTE", "ERROR"};
#define  ALARM_COUNTS  (sizeof( apszAlarmStyle) / sizeof( PSZ))

// use default if no style specified
if ((!pszAlarmStyle) || (!*pszAlarmStyle))
   pszAlarmStyle = apszAlarmStyle[ WA_NOTE];

// generate alarm
for (i = 0; i < ALARM_COUNTS; i++)
   {
   if (!stricmp( apszAlarmStyle[ i], pszAlarmStyle))
      {
      fResult = WinAlarm( HWND_DESKTOP, i);
      break;
      }
   }

return fResult;
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdDirExists( PSZ pszDirName)
{
return DirExists( pszDirName);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdFileDelete( PSZ pszFileName)
{
return DosDelete( pszFileName);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdErrorMsgBox( HWND hwndClient, PSZ pszMessage, PSZ pszTitle)
{
         APIRET         rc = NO_ERROR;

do
   {
   // check parms
   if ((!pszMessage) ||
       (!pszTitle))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   if (WinMessageBox( HWND_DESKTOP,
                       hwndClient,
                       pszMessage,
                       pszTitle,
                       0L,
                       MB_CANCEL | MB_MOVEABLE | MB_ERROR) == MBID_ERROR)
      rc = LASTERROR;

   } while (FALSE);

return rc;

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdFileExists( PSZ pszFileName)
{
return FileExists( pszFileName);
}


// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetInstValue( PSZ pszFileTag, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

// init return value first
if (pszBuffer)
   memset( pszBuffer, 0, ulBuflen);

rc = GetInstValue( pszFileTag, pszBuffer, ulBuflen);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetNextClose( HDIR hdir)
{
return DosFindClose( hdir);
}


// ------------------------------------------------------------------------------

#define NEPMD_NEXTTYPE_FILE 0
#define NEPMD_NEXTTYPE_DIR  1

static APIRET _getNextEntry( ULONG ulEntryType,
                             PSZ pszSearchMask, PSZ pszHandle, PSZ pszBuffer, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;
         BOOL           fNewHandle = FALSE;
         HDIR           hdir = 0;

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszSearchMask)  ||
       (!pszHandle)    ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // copy handle if first char not zero
   // then we assume it is an ASCIIZ string
   // returned before by us
   if (*pszHandle != '0')
      hdir = atol( pszHandle);

   // set to HDIR_CREATE if zero
   if (!hdir)
      {
      hdir = HDIR_CREATE;
      fNewHandle = TRUE;
      }

   // get the file or directory
   switch (ulEntryType)
      {
      case NEPMD_NEXTTYPE_FILE:
         rc = GetNextFile( pszSearchMask, &hdir, pszBuffer, ulBuflen);
         break;

      case NEPMD_NEXTTYPE_DIR:
         rc = GetNextDir( pszSearchMask, &hdir, pszBuffer, ulBuflen);
         break;

      default:
         rc = ERROR_INVALID_PARAMETER;
         break;

   }

   // copy back handle and append some blanks - hopefully we don't overwrite memory
   // inside the REXX variable stack...
   if ((!rc) && (fNewHandle))
      sprintf( pszHandle, "%u   ", hdir);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetNextFile( PSZ pszFileMask, PSZ pszHandle, PSZ pszBuffer, ULONG ulBuflen)

{
return _getNextEntry( NEPMD_NEXTTYPE_FILE, pszFileMask, pszHandle, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetNextDir( PSZ pszDirMask, PSZ pszHandle, PSZ pszBuffer, ULONG ulBuflen)

{
return _getNextEntry( NEPMD_NEXTTYPE_DIR, pszDirMask, pszHandle, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

#define SETPARM(i,p) if (p) apszParms[ i] = p; ulParmCount++;

APIRET EXPENTRY NepmdGetTextMessage( PSZ pszFilename, PSZ pszMessageName,
                                     PSZ pszBuffer, ULONG ulBuflen,
                                     PSZ pszParm1, PSZ pszParm2, PSZ pszParm3, PSZ pszParm4,
                                     PSZ pszParm5, PSZ pszParm6, PSZ pszParm7, PSZ pszParm8,
                                     PSZ pszParm9)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         PSZ            apszParms[ 9];
         ULONG          ulParmCount;
         ULONG          ulMessageLen;

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszFilename)    ||
       (!pszMessageName) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // setup parm table with empty strings
   ulParmCount = 0;
   for (i = 0; i < 9; i++)
      {
      apszParms[ i] = "";
      }

   // hand over all parms up but those being NULL
   SETPARM(0, pszParm1);
   SETPARM(1, pszParm2);
   SETPARM(2, pszParm3);
   SETPARM(3, pszParm4);
   SETPARM(4, pszParm5);
   SETPARM(5, pszParm6);
   SETPARM(6, pszParm7);
   SETPARM(7, pszParm8);
   SETPARM(8, pszParm9);

   // get the message
   rc = TmfGetMessage( apszParms, 9, pszBuffer, ulBuflen,
                       pszMessageName, pszFilename, &ulMessageLen);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdLibVersion( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszResult = NEPMDLIB_VERSION;

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if (!pszBuffer)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check result buffer
   if (strlen( pszResult) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, pszResult);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdInfo( HWND hwndClient)
{
         APIRET         rc = NO_ERROR;
         CHAR           szMessageFile[ _MAX_PATH];
         CHAR           szErrorMsg[ 128];


do
   {

   // open new file in ring and disable autosave
   _executeEPMCommand( hwndClient, "xcom e /c %s", NEPMD_FILENAME_LIBINFO);

   // determine messsage file
   rc = GetInstValue( NEPMD_VALUETAG_MESSAGE, szMessageFile, sizeof( szMessageFile));
   if (rc != NO_ERROR)
      {
      sprintf( szErrorMsg,
               STRING_INTERNALERROR "Fatal error: cannot determine NEPMD message file, rc=%u\n\n",
               rc);
      EPMINSERTTEXT( szErrorMsg);
      break;
      }

   // insert message in reverse order !

   // ------------------------------------------------------------------------
   // ---  library information
   {
         PSZ            pszModuleMask = "STR_INFO_NEPMDMODULESTAMP";
         PSZ            pszLoaderExecutable = getenv( ENV_NEPMD_LOADEREXECUTABLE);


   if (pszLoaderExecutable)
      INSERT_NEPMD_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, pszLoaderExecutable);
   INSERT_NEPMD_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, "NEPMDLIB.DLL");
   _insertMessage( hwndClient, szMessageFile, "MSG_INFO_BODY_MODULES_NEPMD");
   }

   // ------------------------------------------------------------------------
   // --- EPM module information
   {
         PSZ            pszModuleMask = "STR_INFO_EPMMODULESTAMP";

   INSERT_EPM_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, "ETKC603.DLL");
   INSERT_EPM_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, "ETKR603.DLL");
   INSERT_EPM_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, "ETKE603.DLL");
   INSERT_EPM_MODULEVERSION( hwndClient, szMessageFile, pszModuleMask, "EPM.EXE");
   _insertMessage( hwndClient, szMessageFile, "MSG_INFO_BODY_MODULES_EPM");
   }



   // ------------------------------------------------------------------------
   // ---  dynamic configuration
   {
         ULONG          ulMessageLen;
         PSZ            p;

         CHAR           szNotFound[ 32];
         CHAR           szNotUsed[ 32];
         CHAR           szNotInstalled[ 32];

         CHAR           szNepmdRootdir[ _MAX_PATH];
         CHAR           szLanguage[ 10];
         CHAR           szNepmdInitfile[ _MAX_PATH];

         CHAR           szEpmExecutable[ _MAX_PATH];

         PSZ            pszEpmExecutable = getenv( ENV_NEPMD_EPMEXECUTABLE);
         PSZ            pszLoaderExecutable = getenv( ENV_NEPMD_LOADEREXECUTABLE);
         PSZ            pszMainEnvFile = getenv( ENV_NEPMD_MAINENVFILE);
         PSZ            pszUserEnvFile = getenv( ENV_NEPMD_USERENVFILE);


   // get some default strings
   LOADSTRING( "STR_INFO_NOTUSED", szNotUsed);
   LOADSTRING( "STR_INFO_NOTFOUND", szNotFound);
   LOADSTRING( "STR_INFO_NOTINSTALLED", szNotInstalled);

   // get main config values
   rc = GetInstValue( NEPMD_VALUETAG_ROOTDIR, szNepmdRootdir, sizeof( szNepmdRootdir));
   GetInstValue( NEPMD_VALUETAG_LANGUAGE, szLanguage, sizeof( szLanguage));
   GetInstValue( NEPMD_VALUETAG_INIT, szNepmdInitfile, sizeof( szNepmdInitfile));

   // select defaults if some values not available
   if (rc != NO_ERROR)
      strcpy( szNepmdRootdir, szNotInstalled);
   if (!pszEpmExecutable)
      {
      DosSearchPath( SEARCH_ENVIRONMENT | SEARCH_IGNORENETERRS,
                     "PATH", "EPM.EXE",
                     szEpmExecutable, sizeof( szEpmExecutable));
      pszEpmExecutable = szEpmExecutable;
      }
   if ((!pszLoaderExecutable) || (!*pszLoaderExecutable)) pszLoaderExecutable = szNotUsed;
   if ((!pszMainEnvFile) || (!*pszMainEnvFile)) pszMainEnvFile = szNotFound;
   if ((!pszUserEnvFile) || (!*pszUserEnvFile)) pszUserEnvFile = szNotFound;

   // insert the result
   _insertMessage( hwndClient, szMessageFile, "MSG_INFO_BODY_DYNCFG",
                   szNepmdRootdir, pszLoaderExecutable, pszEpmExecutable,
                   szLanguage, szNepmdInitfile, szMessageFile,
                   pszMainEnvFile, pszUserEnvFile);
   }

   // ------------------------------------------------------------------------
   // --- header
   _insertMessage( hwndClient, szMessageFile, "MSG_INFO_HEADER");


   } while (FALSE);

return rc;

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQueryFullname( PSZ pszFilename, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszFilename) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // query fullname
   rc = DosQueryPathInfo( pszFilename, FIL_QUERYFULLNAME, pszBuffer, ulBuflen);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdReadStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

// init return value first
if (pszBuffer)
   memset( pszBuffer, 0, ulBuflen);

rc = ReadStringEa( pszFileName, pszEaName, pszBuffer, &ulBuflen);

return _getRexxError( rc, pszBuffer, ulBuflen);

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdWriteStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszEaValue)
{
return WriteStringEa( pszFileName, pszEaName, pszEaValue);
}
  
