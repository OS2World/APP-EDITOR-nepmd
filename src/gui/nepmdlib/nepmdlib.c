/****************************** Module Header *******************************
*
* Module Name: nepmdlib.c
*
* Routines of the NEPMD library DLL.
* Coutnerpart to this DLL is nepmdlib.e/.ex.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.c,v 1.42 2002-09-19 11:31:29 cla Exp $
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
#include "libreg.h"

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
         APIRET         rc = NO_ERROR;
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

   // for EPM modules load version string
   strcpy( szVersionStamp, "");
   if (fEpmModule)
      {
      if (WinLoadString( hab, hmodule, 65535, sizeof( szFilestamp), szFilestamp))
         sprintf( szVersionStamp, "(%s)", szFilestamp);
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

   rc = DosQueryModuleName( hmodule, sizeof( szFullname), szFullname);
   if (rc == ERROR_INVALID_HANDLE)
      {
      // determine fullname from ini
      QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, szFullname, sizeof( szFullname));
      strcat( szFullname, "\\NETLABS\\DLL\\NEPMDLIB.DLL");
      strupr( szFullname);
      rc = NO_ERROR;
      }
   else if (rc != NO_ERROR)
      break;

   rc = DosQueryPathInfo( szFullname, FIL_STANDARD, &fs3, sizeof( fs3));
   if (rc != NO_ERROR)
      break;

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

   // sprintf( szFullname, "%-30s", szFullname);

   // insert result
   _insertMessage( hwndClient, pszFilename, pszMessageName,
                   szModuleName, szFilestamp, szFullname, szVersionStamp);

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

// ------------------------------------------------------------------------------

static APIRET _openConfig( PHCONFIG phconfig)
{
         APIRET         rc = NO_ERROR;
         CHAR           szInifile[ _MAX_PATH];
         HCONFIG        hconfig;

do
   {
   // check parm
   if (!phconfig)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // determine name of INI
   rc = QueryInstValue( NEPMD_INSTVALUE_INIT, szInifile, sizeof( szInifile));
   if (rc = NO_ERROR)
      break;

   // open profile
   rc = OpenConfig( &hconfig, szInifile);
   if (rc != NO_ERROR)
      break;

   // hand over result
   *phconfig = hconfig;

   } while (FALSE);

return rc;
}

// ##############################################################################

BOOL EXPENTRY NepmdAlarm( PSZ pszAlarmStyle)
{
         BOOL           fResult = FALSE;
         ULONG          ulAlarmStyle = WA_NOTE;
         ULONG          i;

// don't modify order of this array
static   PSZ            apszAlarmStyle[] = { NEPMD_ALARMSTYLE_WARNING,
                                             NEPMD_ALARMSTYLE_NOTE
                                             NEPMD_ALARMSTYLE_ERROR};
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

APIRET EXPENTRY NepmdCloseConfig( HCONFIG hconfig)
{
         APIRET         rc = NO_ERROR;

return CloseConfig( hconfig);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdDeleteConfigValue( HCONFIG hconfig, PSZ pszRegPath)
{
         APIRET         rc = NO_ERROR;
         BOOL           fImplicitOpen = FALSE;
do
   {
   // implicit open if handle is zero
   if (!hconfig)
      {
      rc = _openConfig( &hconfig);
      if (rc != NO_ERROR)
         break;
      fImplicitOpen = TRUE;
      }

   // do the job
   rc = DeleteConfigValue( hconfig, pszRegPath);

   } while (FALSE);

// cleanup
if (fImplicitOpen) CloseConfig( hconfig); 
return rc;
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

APIRET EXPENTRY NepmdGetNextClose( HDIR hdir)
{
return DosFindClose( hdir);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetNextConfigKey( HCONFIG hconfig, PSZ pszRegPath, PSZ pszPreviousKey,
                                       PSZ pszOptions, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         BOOL           fImplicitOpen = FALSE;
do
   {
   // implicit open if handle is zero
   if (!hconfig)
      {
      rc = _openConfig( &hconfig);
      if (rc != NO_ERROR)
         break;
      fImplicitOpen = TRUE;
      }

   // do the job
   rc = GetNextConfigKey( hconfig, pszRegPath, pszPreviousKey, pszOptions, pszBuffer, ulBuflen);

   } while (FALSE);

// cleanup
if (fImplicitOpen) CloseConfig( hconfig); 
return _getRexxError( rc, pszBuffer, ulBuflen);
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

APIRET EXPENTRY NepmdOpenConfig( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         HCONFIG        hconfig;

         CHAR           szResult[ 20];

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

   // open config
   rc = _openConfig( &hconfig);
   if (rc != NO_ERROR)
      break;

   // convert handle to string
   sprintf( szResult, "%u", hconfig);
   if (strlen( szResult) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szResult);

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
   rc = QueryInstValue( NEPMD_INSTVALUE_MESSAGE, szMessageFile, sizeof( szMessageFile));
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
   rc = QueryInstValue( NEPMD_INSTVALUE_ROOTDIR, szNepmdRootdir, sizeof( szNepmdRootdir));
   QueryInstValue( NEPMD_INSTVALUE_LANGUAGE, szLanguage, sizeof( szLanguage));
   QueryInstValue( NEPMD_INSTVALUE_INIT, szNepmdInitfile, sizeof( szNepmdInitfile));

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

APIRET EXPENTRY NepmdQueryPathInfo( PSZ pszPathname, PSZ pszInfoTag, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

         ULONG          ulInfoStyle;
         BOOL           fTagFound = FALSE;

         FILESTATUS4     fs4;
         CHAR           szInfo[ _MAX_PATH];
         ULONG          ulAttr;


// don't modify order of this array
static   PSZ            apszInfoTag[] = { NEPMD_PATHINFO_CTIME,  // 0
                                          NEPMD_PATHINFO_MTIME,  // 1
                                          NEPMD_PATHINFO_ATIME,  // 2
                                          NEPMD_PATHINFO_SIZE,   // 3
                                          NEPMD_PATHINFO_EASIZE, // 4
                                          NEPMD_PATHINFO_ATTR,   // 5
                                          ""};
#define  STYLE_COUNTS  (sizeof( apszInfoTag) / sizeof( PSZ))

static   PSZ            pszTimestampMask = "%u/%02u/%02u %2u:%02u:%02u";

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszPathname) ||
       (!pszInfoTag)  ||
       (!*pszInfoTag) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check the tag
   for (i = 0; i < STYLE_COUNTS; i++)
      {
      if (!stricmp( apszInfoTag[ i], pszInfoTag))
         {
         DPRINTF(( "NEPMDLIB:%s: tag %s found index %u\n", __FUNCTION__, apszInfoTag[ i], i));
         ulInfoStyle = i;         
         fTagFound = TRUE;
         break;
         }
      }
   if (!fTagFound)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // query pathinfo, including EA size
   memset( &fs4, 0, sizeof( fs4));
   rc = DosQueryPathInfo( pszPathname, FIL_QUERYEASIZE, &fs4, sizeof( fs4));
   if (rc != NO_ERROR)
      break;

   // determine info to return
   // -- make sure that the array apszInfoTag matches the numbers used here !!! ---
   // FILESTATUS3
   switch (ulInfoStyle)
      {
      case 0: // NEPMD_PATHINFO_CTIME
         sprintf( szInfo, pszTimestampMask,
                  fs4.fdateCreation.year + 1980,
                  fs4.fdateCreation.month,
                  fs4.fdateCreation.day,
                  fs4.ftimeCreation.hours,
                  fs4.ftimeCreation.minutes,
                  fs4.ftimeCreation.twosecs * 2);
         break;

      case 1: // NEPMD_PATHINFO_MTIME
         sprintf( szInfo, pszTimestampMask,
                  fs4.fdateLastWrite.year + 1980,
                  fs4.fdateLastWrite.month,
                  fs4.fdateLastWrite.day,
                  fs4.ftimeLastWrite.hours,
                  fs4.ftimeLastWrite.minutes,
                  fs4.ftimeLastWrite.twosecs * 2);
         break;

      case 2: // NEPMD_PATHINFO_ATIME
         sprintf( szInfo, pszTimestampMask,
                  fs4.fdateLastAccess.year + 1980,
                  fs4.fdateLastAccess.month,
                  fs4.fdateLastAccess.day,
                  fs4.ftimeLastAccess.hours,
                  fs4.ftimeLastAccess.minutes,
                  fs4.ftimeLastAccess.twosecs * 2);
         break;

      case 3: // NEPMD_PATHINFO_SIZE
         sprintf( szInfo, "%u", fs4.cbFile);
         break;

      case 4: // NEPMD_PATHINFO_EASIZE
         sprintf( szInfo, "%u", fs4.cbList);
         break;

      case 5: // NEPMD_PATHINFO_ATTR
         ulAttr = fs4.attrFile;
         sprintf( szInfo, "%s%s%s%s%s",
                  (ulAttr & FILE_ARCHIVED)  ? "A" : "-",
                  (ulAttr & FILE_DIRECTORY) ? "D" : "-",
                  (ulAttr & FILE_SYSTEM)    ? "S" : "-",
                  (ulAttr & FILE_HIDDEN)    ? "H" : "-",
                  (ulAttr & FILE_READONLY)  ? "R" : "-");
         break;

      default:
         rc = ERROR_INVALID_PARAMETER;
         break;
      }
   if (rc != NO_ERROR)
      break;

   // check result buffer
   if (strlen( szInfo) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szInfo);


   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQueryProcessInfo( PSZ pszInfoTag, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;

         ULONG          ulInfoStyle;
         BOOL           fTagFound = FALSE;

         CHAR           szInfo[ _MAX_PATH];
         PSZ            pszInfo = szInfo;

         PPIB           ppib;
         PTIB           ptib;


// don't modify order of this array
static   PSZ            apszInfoTag[] = { NEPMD_PROCESSINFO_PID,      // 0
                                          NEPMD_PROCESSINFO_PPID,     // 1
                                          NEPMD_PROCESSINFO_PROGRAM,  // 2
                                          NEPMD_PROCESSINFO_PARMS,    // 3
                                          ""};
#define  STYLE_COUNTS  (sizeof( apszInfoTag) / sizeof( PSZ))

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszInfoTag)  ||
       (!*pszInfoTag) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check the tag
   for (i = 0; i < STYLE_COUNTS; i++)
      {
      if (!stricmp( apszInfoTag[ i], pszInfoTag))
         {
         DPRINTF(( "NEPMDLIB:%s: tag %s found index %u\n", __FUNCTION__, apszInfoTag[ i], i));
         ulInfoStyle = i;         
         fTagFound = TRUE;
         break;
         }
      }
   if (!fTagFound)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // determine process info
   DosGetInfoBlocks( &ptib,&ppib);

   // determine info to return
   // -- make sure that the array apszInfoTag matches the numbers used here !!! ---
   // PIB
   switch (ulInfoStyle)
      {
      case 0: // NEPMD_PROCESSINFO_PID
         sprintf( szInfo, "%u", ppib->pib_ulpid);
         break;

      case 1: // NEPMD_PROCESSINFO_PPID
         sprintf( szInfo, "%u", ppib->pib_ulppid);
         break;

      case 2: // NEPMD_PROCESSINFO_PROGRAM
         rc = DosQueryModuleName( ppib->pib_hmte, sizeof( szInfo), szInfo);
         break;

      case 3: // NEPMD_PROCESSINFO_NEPMD_PROCESSINFO_PARMS
         // use pointer to parameters directly, so that the size of
         // szInfo does not cause an unnecessary limit
         if (ppib->pib_pchcmd)
            pszInfo = NEXTSTR( ppib->pib_pchcmd);
         break;

      default:
         rc = ERROR_INVALID_PARAMETER;
         break;
      }
   if (rc != NO_ERROR)
      break;

   // check result buffer (use pszInfo here !)
   if (strlen( pszInfo) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, pszInfo);


   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQueryStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

// init return value first
if (pszBuffer)
   memset( pszBuffer, 0, ulBuflen);

rc = QueryStringEa( pszFileName, pszEaName, pszBuffer, &ulBuflen);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQuerySysInfo( PSZ pszInfoTag, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         ULONG          i;
         ULONG          ulValue;
         ULONG          aulValue[ 10];

         ULONG          ulInfoStyle;
         BOOL           fTagFound = FALSE;

         CHAR           szInfo[ _MAX_PATH];

         PPIB           ppib;
         PTIB           ptib;
static   PSZ            pszValueMask = "%u";


// don't modify order of this array
static   PSZ            apszInfoTag[] = { NEPMD_SYSINFO_MAXPATH,       //  0
                                          NEPMD_SYSINFO_BOOTDRIVE,     //  1
                                          NEPMD_SYSINFO_OS2VERSION,    //  2
                                          NEPMD_SYSINFO_MAXCOMPONENT,  //  3
                                          NEPMD_SYSINFO_SWAPBUTTON,    //  4
                                          NEPMD_SYSINFO_ALARM,         //  5
                                          NEPMD_SYSINFO_CXSCREEN,      //  6
                                          NEPMD_SYSINFO_CYSCREEN,      //  7
                                          NEPMD_SYSINFO_CXFULLSCREEN,  //  8
                                          NEPMD_SYSINFO_CYFULLSCREEN,  //  9
                                          NEPMD_SYSINFO_DEBUG,         // 10
                                          NEPMD_SYSINFO_CMOUSEBUTTONS, // 11
                                          NEPMD_SYSINFO_POINTERLEVEL,  // 12
                                          NEPMD_SYSINFO_CURSORLEVEL,   // 13
                                          NEPMD_SYSINFO_MOUSEPRESENT,  // 14
                                          NEPMD_SYSINFO_PRINTSCREEN,   // 15
                                          ""};
#define  STYLE_COUNTS  (sizeof( apszInfoTag) / sizeof( PSZ))

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszInfoTag)  ||
       (!*pszInfoTag) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check the tag
   for (i = 0; i < STYLE_COUNTS; i++)
      {
      if (!stricmp( apszInfoTag[ i], pszInfoTag))
         {
         DPRINTF(( "NEPMDLIB:%s: tag %s found index %u\n", __FUNCTION__, apszInfoTag[ i], i));
         ulInfoStyle = i;         
         fTagFound = TRUE;
         break;
         }
      }
   if (!fTagFound)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // determine info to return
   // -- make sure that the array apszInfoTag matches the numbers used here !!! ---
   // PIB
   switch (ulInfoStyle)
      {
      case 0: // NEPMD_SYSINFO_MAXPATH
         DosQuerySysInfo( QSV_MAX_PATH_LENGTH, QSV_MAX_PATH_LENGTH, &ulValue, sizeof( ulValue));
         sprintf( szInfo, pszValueMask, ulValue);
         break;

      case 1: // NEPMD_SYSINFO_BOOTDRIVE
         DosQuerySysInfo( QSV_BOOT_DRIVE, QSV_BOOT_DRIVE, &ulValue, sizeof( ulValue));
         sprintf( szInfo, "%c:", (CHAR) ulValue + 'A' - 1);
         break;

      case 2: // NEPMD_SYSINFO_OS2VERSION
         DosQuerySysInfo( QSV_VERSION_MAJOR, QSV_VERSION_MINOR, &aulValue, sizeof( ulValue) * 2);
         sprintf( szInfo, "%u.%u", aulValue[ 0], aulValue[ 1]);
         break;

      case 3: // NEPMD_SYSINFO_MAXCOMPONENT
         DosQuerySysInfo( QSV_MAX_COMP_LENGTH, QSV_MAX_COMP_LENGTH, &ulValue, sizeof( ulValue));
         sprintf( szInfo, pszValueMask, ulValue);
         break;

      case 4: // NEPMD_SYSINFO_SWAPBUTTON
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_SWAPBUTTON));
         break;

      case 5: // NEPMD_SYSINFO_ALARM
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_ALARM));
         break;

      case 6: // NEPMD_SYSINFO_CXSCREEN
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CXSCREEN));
         break;

      case 7: // NEPMD_SYSINFO_CYSCREEN
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CYSCREEN));
         break;

      case 8: // NEPMD_SYSINFO_CXFULLSCREEN
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CXFULLSCREEN));
         break;

      case 9: // NEPMD_SYSINFO_CYFULLSCREEN
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CYFULLSCREEN));
         break;

      case 10: // NEPMD_SYSINFO_DEBUG
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_DEBUG));
         break;

      case 11: // NEPMD_SYSINFO_CMOUSEBUTTONS
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CMOUSEBUTTONS));
         break;

      case 12: // NEPMD_SYSINFO_POINTERLEVEL
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_POINTERLEVEL));
         break;

      case 13: // NEPMD_SYSINFO_CURSORLEVEL
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_CURSORLEVEL));
         break;

      case 14: // NEPMD_SYSINFO_MOUSEPRESENT
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_MOUSEPRESENT));
         break;

      case 15: // NEPMD_SYSINFO_PRINTSCREEN
         sprintf( szInfo, pszValueMask, WinQuerySysValue( HWND_DESKTOP, SV_PRINTSCREEN));
         break;

      default:
         rc = ERROR_INVALID_PARAMETER;
         break;
      }
   if (rc != NO_ERROR)
      break;

   // check result buffer (use pszInfo here !)
   if (strlen( szInfo) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szInfo);


   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQueryWindowPos( HWND hwnd,  PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         SWP            swp;
         CHAR           szResult[ 64];

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if (!WinIsWindow( CURRENTHAB, hwnd))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get window pos
   if (!WinQueryWindowPos( hwnd, &swp))
      {
      rc = LASTERROR;
      break;
      }

   // create result of SWP
   sprintf( szResult, "%u %u %u %u", swp.x, swp.y, swp.cx, swp.cy);

   // check result buffer
   if (strlen( szResult) + 1 > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // hand over result
   strcpy( pszBuffer, szResult);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdQueryConfigValue( HCONFIG hconfig, PSZ pszRegPath,
                                       PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         BOOL           fImplicitOpen = FALSE;
do
   {
   // implicit open if handle is zero
   if (!hconfig)
      {
      rc = _openConfig( &hconfig);
      if (rc != NO_ERROR)
         break;
      fImplicitOpen = TRUE;
      }

   // do the job
   rc = QueryConfigValue( hconfig, pszRegPath, pszBuffer, ulBuflen);

   } while (FALSE);

// cleanup
if (fImplicitOpen) CloseConfig( hconfig); 
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

APIRET EXPENTRY NepmdQueryInstValue( PSZ pszFileTag, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

// init return value first
if (pszBuffer)
   memset( pszBuffer, 0, ulBuflen);

rc = QueryInstValue( pszFileTag, pszBuffer, ulBuflen);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdScanEnv( PSZ pszEnvName, PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszResult;

do
   {
   // init return value first
   if (pszBuffer)
      memset( pszBuffer, 0, ulBuflen);

   // check parms
   if ((!pszEnvName)  ||
       (!*pszEnvName) ||
       (!pszBuffer))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // query value
   rc = DosScanEnv( pszEnvName, &pszResult);
   if (rc != NO_ERROR)
      break;

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

APIRET EXPENTRY NepmdSearchPath( PSZ pszFilename, PSZ pszEnvVarName, PSZ pszBuffer, ULONG ulBuflen)
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

   // use default
   if ((!pszEnvVarName) || (!*pszEnvVarName))
      pszEnvVarName = "PATH";

   // search !
   rc = DosSearchPath( SEARCH_IGNORENETERRS |
                       SEARCH_ENVIRONMENT,
                       pszEnvVarName,
                       pszFilename,
                       pszBuffer,
                       ulBuflen);

   } while (FALSE);

return _getRexxError( rc, pszBuffer, ulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdSetFrameWindowPos(  HWND hwndFrame, ULONG x, ULONG y, ULONG cx, ULONG cy, ULONG flags) 
{

         APIRET         rc = NO_ERROR;

do
   {

   // check parms
   if (!WinIsWindow( CURRENTHAB, hwndFrame))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // set window pos
   if (!WinSetWindowPos( hwndFrame, HWND_TOP, x, y, cx, cy, flags))
      rc = LASTERROR;

   } while (FALSE);

return rc;
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdWriteConfigValue( HCONFIG hconfig, PSZ pszRegPath, PSZ pszRegValue)
{
         APIRET         rc = NO_ERROR;
         BOOL           fImplicitOpen = FALSE;
do
   {
   // implicit open if handle is zero
   if (!hconfig)
      {
      rc = _openConfig( &hconfig);
      if (rc != NO_ERROR)
         break;
      fImplicitOpen = TRUE;
      }

   // do the job
   rc = WriteConfigValue( hconfig, pszRegPath, pszRegValue);

   } while (FALSE);

// cleanup
if (fImplicitOpen) CloseConfig( hconfig); 
return rc;
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdWriteStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszEaValue)
{
return WriteStringEa( pszFileName, pszEaName, pszEaValue);
}

