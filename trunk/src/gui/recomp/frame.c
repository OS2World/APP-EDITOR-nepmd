/****************************** Module Header *******************************
*
* Module Name: frame.c
*
* PM frame related routines.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: frame.c,v 1.4 2002-06-10 11:54:18 cla Exp $
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
#undef DEBUG

#include "common.h"
#include "macros.h"
#include "recomp.rch"

#include "frame.h"
#include "client.h"
#include "pmres.h"

// ---------------------------------------------------------------------

static   BOOL           fOptionGiven        = FALSE;
static   PSZ            pszLastOption       = NULL;

static   BOOL           fAutostart          = FALSE;
static   BOOL           fDiscardUnsaved     = FALSE;
static   BOOL           fNoReloadFiles      = FALSE;
static   BOOL           fNoCompileLog       = FALSE;
static   BOOL           fHelp               = FALSE;
static   PSZ            pszTargetDirectory  = NULL;

// data for reading/writing init dta
static   PSZ            pszAppName = __PROGSTEM__;
static   PSZ            pszKeyName = "CONFIGDATA";
static   ULONG          ulSig = 'NE';
static   ULONG          ulVersion = 0x1002;

// ---------------------------------------------------------------------

static BOOL _setErrorInfo( APIRET rc)
{

do
   {
   // do nothing if no error occurred
   if (rc == NO_ERROR)
      break;

   // set the info, which can be retrieved by WinGetLastError/WinGetErrorInfo
   if (rc > PMERR_INVALID_HWND)
      WinSetErrorInfo( MAKEERRORID( SEVERITY_ERROR, rc), 0);
   else
      WinSetErrorInfo( MAKEERRORID( SEVERITY_ERROR, PMERR_DOS_ERROR), SEI_DOSERROR, (USHORT) rc);

   } while (FALSE);

return (rc == NO_ERROR);

}

// ---------------------------------------------------------------------

static BOOL _readInitData( PCONFIGDATA pcd)
{
         BOOL           fResult = FALSE;
         APIRET         rc = NO_ERROR;
         ULONG          ulSize;
do
   {
   // check parms
   if (!pcd)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // check size of data
   fResult = PrfQueryProfileSize( HINI_USER, pszAppName, pszKeyName, &ulSize);
   if (!fResult)
      {
      DPRINTF(( "FRAME: profile \"%s\" - \"%s\" not found\n", pszAppName, pszKeyName));
      break;
      }

   if (ulSize != sizeof( CONFIGDATA))
      {
      DPRINTF(( "FRAME: profile size \"%s\" - \"%s\" does not match\n", pszAppName, pszKeyName));
      rc = ERROR_INVALID_DATA;
      break;
      }

   // read data and check sig and version
   fResult = PrfQueryProfileData( HINI_USER, pszAppName, pszKeyName, pcd, &ulSize);
   if (!fResult)
      {
      DPRINTF(( "FRAME: profile \"%s\" - \"%s\" could not be read\n", pszAppName, pszKeyName));
      break;
      }

   if ((pcd->ulSig != ulSig) || (pcd->ulVersion != ulVersion))
      {
      DPRINTF(( "FRAME: sig or version of profile \"%s\" - \"%s\" does not match\n", pszAppName, pszKeyName));
      rc = ERROR_INVALID_DATA;
      break;
      }

   DPRINTF(( "FRAME: reading profile \"%s\" - \"%s\" successful\n", pszAppName, pszKeyName));

   } while (FALSE);

if (rc)
   {
   _setErrorInfo( rc);
   fResult = FALSE;
   }
return fResult;

}

// ---------------------------------------------------------------------

static BOOL _writeInitData( PCONFIGDATA pcd)
{
         BOOL           fResult = FALSE;
         APIRET         rc = NO_ERROR;
do
   {
   // check parms
   if (!pcd)
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // set sig and version
   pcd->ulSig     = ulSig;
   pcd->ulVersion = ulVersion;

   // write init data
   fResult = PrfWriteProfileData( HINI_USER, pszAppName, pszKeyName, pcd, sizeof( CONFIGDATA));
   if (!fResult)
      {
      DPRINTF(( "FRAME: error writing profile \"%s\" - \"%s\"\n", pszAppName, pszKeyName));
      break;
      }
   DPRINTF(( "FRAME: writing profile \"%s\" - \"%s\" successful\n", pszAppName, pszKeyName));

   } while (FALSE);

if (rc)
   {
   _setErrorInfo( rc);
   fResult = FALSE;
   }
return fResult;

}

// ---------------------------------------------------------------------

VOID ShowHelp( HWND hwndOwner, HMODULE hmodResource)
{
         CHAR           szMessage[ 4 * _MAX_PATH];


// load complete message
szMessage[ 0] = 0;
WinLoadString( CURRENTHAB, hmodResource,  IDSTR_HELP_HEAD, _EOSSIZE( szMessage), _EOS( szMessage));
WinLoadString( CURRENTHAB, hmodResource,  IDSTR_HELP_1,    _EOSSIZE( szMessage), _EOS( szMessage));
WinLoadString( CURRENTHAB, hmodResource,  IDSTR_HELP_2,    _EOSSIZE( szMessage), _EOS( szMessage));
WinLoadString( CURRENTHAB, hmodResource,  IDSTR_HELP_TAIL, _EOSSIZE( szMessage), _EOS( szMessage));

WinMessageBox( HWND_DESKTOP, hwndOwner, szMessage, __APPNAME__, -1, MB_OK | MB_INFORMATION | MB_MOVEABLE);

}

// ---------------------------------------------------------------------

#define SWITCH_CHARS     "/-"
#define SWITCH_DELIMITER ':'

static APIRET _getCommandlineParms( HMODULE hmodResource, INT argc, PSZ argv[])
{
         APIRET         rc = NO_ERROR;
         PSZ            p;
         ULONG          i;

         PSZ            pszThisParm;
         PSZ            pszThisValue;

static   PSZ            pszInvalidParm  = "Invalid parameter %s" NEWLINE;

static   PSZ            pszParmStart,
                        pszParmDiscardUnsaved,
                        pszParmNoReloadFiles,
                        pszParmNoLog,
                        pszParmHelp,
                        pszParmHelp2;

// upcase parameters
pszParmStart           = strupr( PARM_START);
pszParmDiscardUnsaved  = strupr( PARM_DISCARDUNSAVED);
pszParmNoReloadFiles   = strupr( PARM_NORELOADFILES);
pszParmNoLog           = strupr( PARM_NOLOG);
pszParmHelp            = strupr( PARM_HELP);
pszParmHelp2           = strupr( PARM_HELP2);

// get commandline parms
for (i = 1; i < argc; i++)
   {
   pszThisParm = argv[i];

   if (strchr(SWITCH_CHARS, *pszThisParm) != NULL)
      {
      pszThisParm++;

      // search for delimiter and separate name and value
      pszThisValue = strchr( pszThisParm, SWITCH_DELIMITER);
      if (pszThisValue == NULL)
         pszThisValue = "";
      else
         {
         *pszThisValue = 0;
         *pszThisValue++;
         }

      // upcase the parm name
      strupr( pszThisParm);

      // process /START
      if ((strstr( pszParmStart, pszThisParm) == pszParmStart))
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmStart));
         fAutostart      = TRUE;
         }
      // process /DISCARDUNSAVED
      else if ((strstr( pszParmDiscardUnsaved, pszThisParm) == pszParmDiscardUnsaved))
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmDiscardUnsaved));
         fDiscardUnsaved = TRUE;

         fOptionGiven    = TRUE;
         pszLastOption   = pszThisParm;
         }
      // process /PARM_RELOADFILES
      else if ((strstr( pszParmNoReloadFiles, pszThisParm) == pszParmNoReloadFiles))
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmNoReloadFiles));
         fNoReloadFiles = TRUE;

         fOptionGiven   = TRUE;
         pszLastOption   = pszThisParm;
         }
      // process /PARM_NOLOG
      else if ((strstr( pszParmNoLog, pszThisParm) == pszParmNoLog))
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmNoLog));
         fNoCompileLog = TRUE;

         fOptionGiven  = TRUE;
         pszLastOption   = pszThisParm;
         }
      // process /?
      else if (strstr( pszParmHelp, pszThisParm) == pszParmHelp)
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmHelp));
         fHelp = TRUE;
         }
      // process /HELP
      else if (strstr( pszParmHelp2, pszThisParm) == pszParmHelp2)
         {
         DPRINTF(( "FRAME: parm %s selected\n", pszParmHelp2));
         fHelp = TRUE;
         }
      else
         {
         pszThisParm--;
         ShowNlsError( HWND_DESKTOP, hmodResource, __APPNAME__, IDSTR_INVALID_PARM, pszThisParm);
         rc = ERROR_INVALID_PARAMETER;
         break;
         }
      }
   else
      {
      // save free parameters here
      if (!pszTargetDirectory)
         {
         pszTargetDirectory = pszThisParm;

         //  cut off trailing slash !
         p = pszTargetDirectory + strlen( pszTargetDirectory) - 1;
         if (*p == '\\') *p = 0;
         }
      else
         {
         ShowNlsError( HWND_DESKTOP, hmodResource, __APPNAME__, IDSTR_INVALID_PARM, pszThisParm);
         rc = ERROR_INVALID_PARAMETER;
         break;
         }
      }

   } // for all argv[]


// more checks
if ((fOptionGiven) && (!fAutostart))
   {
   // /START also needs to be specified for certain options
   ShowNlsError( HWND_DESKTOP, hmodResource, __APPNAME__, IDSTR_START_NOT_SPECIFIED,
                 pszParmStart, pszLastOption);
   rc = ERROR_INVALID_PARAMETER;
   }

return rc;

}

// ---------------------------------------------------------------------

static HMODULE _loadNlsModule( VOID)
{
         HMODULE        hmodResource = NULLHANDLE;
         APIRET         rc = NO_ERROR;
         PSZ            p;

         ULONG          ulDataLen;
         CHAR           szLanguageId[ 16];

         PPIB           ppib;
         PTIB           ptib;
         CHAR           szModuleName[ _MAX_PATH];
         CHAR           szError[ 10];

do
   {
   // read language id
   ulDataLen = PrfQueryProfileString( HINI_USER,
                                      NEPMD_INI_APPNAME,
                                      NEPMD_INI_KEYNAME_LANGUAGE,
                                      NULL,
                                      szLanguageId,
                                      sizeof( szLanguageId));

   if (ulDataLen)
      {
      // handle also non-zero-terminated strings
      szLanguageId[ ulDataLen] = 0;

      DPRINTF(( "FRAME: language id is: %s\n", szLanguageId));

      // get name of this executable and replace filename with module name
      DosGetInfoBlocks( &ptib,&ppib);
      DosQueryModuleName( ppib->pib_hmte, sizeof( szModuleName), szModuleName);
      p = strrchr( szModuleName, '\\');
      sprintf( p + 1, NLSMODULE_LANGUAGEMASK, szLanguageId);

      // load dll
      // ignore error as the module will stay NULLHANDLE then
      // and thus default to the english NLS bound to the executable
      rc = DosLoadModule( szError, sizeof( szError), szModuleName, &hmodResource);

      DPRINTF(( "FRAME: load module: %s rc: %u\n", szModuleName, rc));
      }

   } while ( FALSE);

return hmodResource;
}


// ---------------------------------------------------------------------

APIRET ExecuteFrame( HAB hab, INT argc, PSZ  argv[])
{
         APIRET         rc = NO_ERROR;

         WINDOWDATA     wd;

         PSZ            pszSemName = SEMNAME;
         HEV            hevProgramActive = NULLHANDLE;

do
   {


   // init data
   memset( &wd, 0, sizeof( WINDOWDATA));
   if (!_readInitData( &wd.cd))
      {
      // set default window position
      wd.cd.swp.x  = 100;
      wd.cd.swp.y  = 100;
      wd.cd.swp.cx = 0;
      wd.cd.swp.cy = 0;
      wd.cd.swp.fl = SWP_RESTORE;

      // defaults
      wd.cd.fReloadFiles = TRUE;
      wd.cd.fShowCompileLog = TRUE;
      }

   // load language specific DLL
   wd.hmodResource = _loadNlsModule();

   // get commandline parms for autostart feature
   rc = _getCommandlineParms( wd.hmodResource, argc, argv);
   if (rc != NO_ERROR)
      break;

   // show help ?
   if (fHelp)
      {
      ShowHelp( HWND_DESKTOP, wd.hmodResource);
      break;
      }

   // process autostart features
   if (fAutostart)
      {
      wd.fAutoStart         = TRUE;
      wd.cd.fDiscardUnsaved = fDiscardUnsaved;
      wd.cd.fReloadFiles    = !fNoReloadFiles;
      wd.cd.fShowCompileLog = !fNoCompileLog;
      }

   // check if we are already loaded
   rc = DosCreateEventSem( pszSemName, &hevProgramActive, DC_SEM_SHARED, FALSE);
   if (rc != NO_ERROR)
      {
      if (fAutostart)
         {
         // show error first, then activate running instance
         ShowNlsError( HWND_DESKTOP, wd.hmodResource, __APPNAME__, IDSTR_ALREADY_RUNNING);
         rc = DosOpenEventSem( pszSemName, &hevProgramActive);
         if (rc == NO_ERROR)
            rc = DosPostEventSem( hevProgramActive);
         }
      else
         {
         // activate window of current instance
         rc = DosOpenEventSem( pszSemName, &hevProgramActive);
         if (rc == NO_ERROR)
            rc = DosPostEventSem( hevProgramActive);
         else
            // show error only of that is not possible
            ShowNlsError( HWND_DESKTOP, wd.hmodResource, __APPNAME__, IDSTR_ALREADY_RUNNING);
         }

      // stop here anyway
      break;
      }

   // determine some values for EPM compilation
   strcpy( wd.szTargetDir, (pszTargetDirectory) ? pszTargetDirectory : "");

   // process dialog
   WinDlgBox( HWND_DESKTOP, HWND_DESKTOP, &ClientWindowProc, wd.hmodResource, IDRES_FRAME, &wd);

   // save settings
   if (!wd.fAutoStart)
      _writeInitData( &wd.cd);

   } while ( FALSE);

// cleanup
if (hevProgramActive) DosCloseEventSem( hevProgramActive);
if (wd.hmodResource) DosFreeModule( wd.hmodResource);
return rc;
}

