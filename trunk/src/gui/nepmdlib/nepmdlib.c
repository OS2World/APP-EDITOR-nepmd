/****************************** Module Header *******************************
*
* Module Name: nepmdlib.c
*
* Routines of the NEPMD library DLL.
* Coutnerpart to this DLL is nepmdlib.e/.ex.
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.c,v 1.10 2002-08-22 15:51:36 cla Exp $
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

   rc = WinMessageBox( HWND_DESKTOP,
                       hwndClient,
                       pszMessage,
                       pszTitle,
                       0L,
                       MB_CANCEL | MB_MOVEABLE | MB_ERROR);

   } while (FALSE);

return rc;

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdGetInstValue( PSZ pszFileTag, PSZ pszBuffer, ULONG ulBuflen) 
{
return GetInstValue( pszFileTag, pszBuffer, ulBuflen);
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

   // copy back handle - hopefully we don't overwrite memory
   // inside the REXX variable stack...
   if ((!rc) && (fNewHandle))
      _ltoa( hdir, pszHandle, 10);

   } while (FALSE);

return rc;

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

return rc;

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdLibVersion( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         PSZ            pszResult = NEPMDLIB_VERSION;

do
   {
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

return rc;
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdLibInfo( HWND hwndClient)
{
         APIRET         rc = NO_ERROR;

         PPIB           ppib;
         PTIB           ptib;

         CHAR           szModuleName[ _MAX_PATH];
         PSZ            pszBaseName;

         CHAR           szMessage[ 512];

do
   {

   // get path and name of this DLL
   rc = GetModuleName( szModuleName, sizeof( szModuleName));
   if (rc != NO_ERROR)
      break;
   pszBaseName = strrchr( szModuleName, '\\');
   *pszBaseName++ = 0;

   // append name of this DLL
   sprintf(       szMessage,  NEPMDLIB_STR_FILENAME   "%s\n", pszBaseName);
   sprintf( _EOS( szMessage), NEPMDLIB_STR_LOADEDFROM "%s\n", szModuleName);

   // details
   strcat( szMessage, NEPMDLIB_STR_VERSION NEPMDLIB_VERSION "  of " __DATE__"\n");

   // append modulename
   strcat( szMessage, NEPMDLIB_STR_LOADEDBY);
   DosGetInfoBlocks( &ptib,&ppib);
   DosQueryModuleName( ppib->pib_hmte, _EOSSIZE( szMessage), _EOS( szMessage));
   strcat( szMessage, "\n");

   // show box
   rc = WinMessageBox( HWND_DESKTOP,
                       hwndClient,
                       szMessage,
                       NEPMDLIB_STR_TITLE,
                       0L,
                       MB_OK | MB_MOVEABLE | MB_INFORMATION);

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

return rc;

}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdReadStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszBuffer, PULONG pulBuflen)
{
// init return value first
if ((pszBuffer) && (pulBuflen))
   memset( pszBuffer, 0, *pulBuflen);

return ReadStringEa( pszFileName, pszEaName, pszBuffer, pulBuflen);
}

// ------------------------------------------------------------------------------

APIRET EXPENTRY NepmdWriteStringEa( PSZ pszFileName, PSZ pszEaName, PSZ pszEaValue)
{
return WriteStringEa( pszFileName, pszEaName, pszEaValue);
}

