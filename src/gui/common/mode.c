/****************************** Module Header *******************************
*
* Module Name: mode.c
*
* Generic routines to support extended syntax hilighting
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: mode.c,v 1.8 2006-10-09 00:12:41 aschn Exp $
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
#include <stdarg.h>
#include <search.h>

#include "macros.h"
#include "nepmd.h"
#include "mode.h"
#include "init.h"
#include "file.h"

// global string vars
static   PSZ            pszEnvnameEpmModepath = "EPMMODEPATH";
static   PSZ            pszGlobalSection      = "GLOBAL";

// defines for strings used only once
#define SEARCHMASK_MODEDIR     "%s\\*"
#define SEARCHMASK_DEFAULTINI  "%s\\default.ini"
#define SEARCHMASK_CUSTOMINI   "%s\\custom.ini"

// defs for glob search
#define GLOBSEARCH_WILDCARD    '*'

// some useful macros
#define QUERYOPTINITVALUE(h,s,k,t,d) \
InitQueryProfileString( h, s, k, d, t, sizeof( t));

// #############################################################################

static char * strwrd( const char * string, const char * word)
{
         char * result = NULL;
         char * p;

         char * eow;
         BOOL  fStartWord;
         BOOL  fEndWord;
do
   {
   // check parm
   if ((!string) || (!word))
      break;

   p = strstr( string, word);
   while (p)
      {
      // search end of word
      eow = p;
      while (*eow > 32)
         { eow++; }
      fEndWord = (eow - p == strlen( word));

      // check start of word
      fStartWord = ((p == string) || (*(p - 1) == ' '));

      // if word, found
      if ((fStartWord) && (fEndWord))
         {
         result = p;
         break;
         }

      // search again
      p = strstr( p + 1, word);
      }

   } while (FALSE);

return result;
}

// -----------------------------------------------------------------------------

static char * _globMatch( const char * namelist, const char * name)
{
         char * result = NULL;
         char * copy   = NULL;
         char * p;
         char * w;

static   char * delimiter = " \t";

do
   {
   // check parm
   if ((!namelist) || (!name))
      break;

   // if no wildcard in list, exit
   if (!strchr( namelist, GLOBSEARCH_WILDCARD))
      break;

   // create a copy
   copy = strdup( namelist);
   if (!copy)
      break;

   // get through all names - don't use strtok here
   p = copy;
   while ((*p) && !(result))
      {
      do
         {
         // skip blanks
         while (*p == ' ') {  p++; }

         // does name contain the wildcard char?
         w = strchr( p, GLOBSEARCH_WILDCARD);
         if (!w)
            break;

         // check the filename
         if (!strnicmp( p, name, w - p))
            {
            result = p;
            break;
            }

         } while (FALSE);

      // skip all nonblanks
      while (*p > ' ') {  p++; }

      } // while (*p)

   } while (FALSE);

// cleanup
if (copy) free( copy);
return result;
}

// -----------------------------------------------------------------------------

static PSZ _stripblanks( PSZ string)
{
 PSZ p = string;
 if (p != NULL)
    {
    while ((*p != 0) && (*p <= 32))
       { p++;}
    strcpy( string, p);

    p = string;
    if (*p != 0)
       {
       p += strlen(p) - 1;
       while ((*p <= 32) && (p >= string))
          {
          *p = 0;
          p--;
          }
       }
    }

return string;
}

// #############################################################################

static APIRET _searchFile( PSZ pszSearchPathName, PSZ pszBuffer, ULONG ulBuflen, PSZ pszSearchMask, ...)
{
         APIRET         rc = NO_ERROR;
         CHAR           szSourceName[ _MAX_PATH];
         va_list        arg_ptr;

va_start (arg_ptr, pszSearchMask);
vsprintf( szSourceName, pszSearchMask, arg_ptr);
rc = DosSearchPath( SEARCH_IGNORENETERRS  |
                       SEARCH_ENVIRONMENT |
                       SEARCH_CUR_DIRECTORY,
                   pszSearchPathName,
                   szSourceName,
                   pszBuffer,
                   ulBuflen);
return rc;

}

// -----------------------------------------------------------------------------

static BOOL _checkSpecialFile( PSZ pszFilename, PBYTE pbSig, ULONG ulSigLen)
{
         BOOL           fIsSpecialFile = FALSE;
         APIRET         rc = NO_ERROR;

         ULONG          ulAction;
         ULONG          ulBytesRead;
         HFILE          hfile = NULLHANDLE;
         PBYTE          pbData = NULL;

do
   {
   // check parm
   if ((!pszFilename) ||
       (!pbSig))
      break;

   // open and write file
   rc = DosOpen( pszFilename,
                 &hfile,
                 &ulAction,
                 0,
                 0,
                 OPEN_ACTION_FAIL_IF_NEW | OPEN_ACTION_OPEN_IF_EXISTS,
                 OPEN_SHARE_DENYWRITE | OPEN_ACCESS_READONLY,
                 NULL);
   if (rc != NO_ERROR)
      break;

   // get memory for file contents
   pbData = malloc( ulSigLen);
   if (!pbData)
      break;

   // read header
   rc = DosRead( hfile, pbData, ulSigLen, &ulBytesRead);
   if ((rc != NO_ERROR) || (ulSigLen != ulBytesRead))
      break;

   // compare header
   fIsSpecialFile = (!memcmp( pbSig, pbData, ulSigLen));

   } while (FALSE);

// cleanup
if (pbData) free( pbData);
if (hfile) DosClose( hfile);
return fIsSpecialFile;
}

// -----------------------------------------------------------------------------

static BOOL _checkExtprocScript( PSZ pszFilename, PSZ pszBuffer, ULONG ulBuflen)
{
         BOOL           fIsSpecialFile = FALSE;
         APIRET         rc = NO_ERROR;
         FILE          *pfile = NULL;
         CHAR           szLine[ 128];

         PSZ            p;
         PSZ            pszExtproc;

do
   {
   // check parm
   if ((!pszFilename) ||
       (!pszBuffer))
      break;

   // init var
   memset( pszBuffer, 0, ulBuflen);

   // open file
   pfile = fopen( pszFilename, "r");
   if (!pfile)
      break;

   while (TRUE)
      {
      // read a line
      if (!fgets( szLine, sizeof( szLine),pfile))
         break;

      // skip empty lines
      _stripblanks( szLine);
      if (szLine[ 0] == 0)
         continue;
      strupr( szLine);

      // check first word - it must be EXTPROC!
      p = strtok( szLine, " ");
      if (strcmp( p, "EXTPROC"))
         break;

      // second word must be given - this the external processor
      p = strtok( NULL, " ");
      if (!p)
         break;

      // strip off path and extension
      pszExtproc = Filespec( p, FILESPEC_NAME);
      p = Filespec( p, FILESPEC_EXTENSION);
      if (p)
         *(p - 1) = 0;
      fIsSpecialFile = TRUE;
      break;
      }
   if (!fIsSpecialFile)
      break;

   // hand over result
   if (strlen( pszExtproc) + 1 > ulBuflen)
      break;
   strcpy( pszBuffer, pszExtproc);

   } while (FALSE);

// cleanup
if (pfile) fclose( pfile);
return fIsSpecialFile;
}


// -----------------------------------------------------------------------------

static APIRET _getModeSettings( PSZ pszMode, PMODEINFO pmi, ULONG ulBuflen)
{

         APIRET         rc = NO_ERROR;
         PSZ            p;
         HINIT          hinit = NULLHANDLE;
         CHAR           szIniFile[ _MAX_PATH];

         CHAR           szDefExtensions[ _MAX_PATH];
         CHAR           szDefNames[ _MAX_PATH];

         CHAR           szCustomDefExtensions[ _MAX_PATH];
         CHAR           szCustomDefNames[ _MAX_PATH];
         CHAR           szCustomAddDefExtensions[ _MAX_PATH];
         CHAR           szCustomAddDefNames[ _MAX_PATH];

         CHAR           szCaseSensitive[ 5];
         CHAR           szCustomCaseSensitive[ 5];
         ULONG          ulCaseSensitive;
         ULONG          ulInfoSize;

do
   {
   // init buffer
   memset( pmi, 0, ulBuflen);

   // search default.ini
   rc = _searchFile( pszEnvnameEpmModepath, szIniFile, sizeof( szIniFile),
                     SEARCHMASK_DEFAULTINI, pszMode);
   if (rc != NO_ERROR)
      break;

   // read the values from it
   rc = InitOpenProfile( szIniFile, &hinit, INIT_OPEN_READONLY, 0, NULL);
   if (rc != NO_ERROR)
      break;
   QUERYOPTINITVALUE( hinit, pszGlobalSection, "DEFEXTENSIONS",  szDefExtensions, "");
   QUERYOPTINITVALUE( hinit, pszGlobalSection, "DEFNAMES",       szDefNames, "");
   QUERYOPTINITVALUE( hinit, pszGlobalSection, "CASESENSITIVE",  szCaseSensitive, "");
   InitCloseProfile( hinit, FALSE);

   // now read custom details - ignore all errors, since that all is optional
   if (_searchFile( pszEnvnameEpmModepath, szIniFile,
                    sizeof( szIniFile), SEARCHMASK_CUSTOMINI,  pszMode) == NO_ERROR)
      {
      if (InitOpenProfile( szIniFile, &hinit, INIT_OPEN_READONLY, 0, NULL) == NO_ERROR)
         {
         // read values here
         QUERYOPTINITVALUE( hinit, pszGlobalSection, "DEFEXTENSIONS",     szCustomDefExtensions, "");
         QUERYOPTINITVALUE( hinit, pszGlobalSection, "ADD_DEFEXTENSIONS", szCustomAddDefExtensions, "");
         QUERYOPTINITVALUE( hinit, pszGlobalSection, "DEFNAMES",          szCustomDefNames, "");
         QUERYOPTINITVALUE( hinit, pszGlobalSection, "ADD_DEFNAMES",      szCustomAddDefNames, "");
         // next is only for _MODEINFO struct here
         QUERYOPTINITVALUE( hinit, pszGlobalSection, "CASESENSITIVE",     szCustomCaseSensitive, "");
         // see also: HILITE.C
         InitCloseProfile( hinit, FALSE);

         // replace settings from DEFAULT.INI, if present
         if (strlen( szCustomDefExtensions))
            {
            strcpy( szDefExtensions, szCustomDefExtensions);
            }

         if (strlen( szCustomDefNames))
            {
            strcpy( szDefNames, szCustomDefNames);
            }

         if (strlen( szCustomCaseSensitive))
            {
            strcpy( szCaseSensitive, szCustomCaseSensitive);
            }

         // append "ADD_" settings to settings from DEFAULT.INI, if present
         if (strlen( szCustomAddDefExtensions))
            {
            strcat( szDefExtensions, " ");
            strcat( szDefExtensions, szCustomAddDefExtensions);
            }

         if (strlen( szCustomAddDefNames))
            {
            strcat( szDefNames, " ");
            strcat( szDefNames, szCustomAddDefNames);
            }
         }
      }

   // make all values uppercase
   strupr( szDefExtensions);
   strupr( szDefNames);

   // check detail size
   ulInfoSize = sizeof( MODEINFO) +
                strlen( pszMode) + 1 +
                strlen( szDefExtensions) + 1 +
                strlen( szDefNames) + 1;
   if (ulInfoSize > ulBuflen)
      {
      rc = ERROR_BUFFER_OVERFLOW;
      break;
      }

   // set data
   p = (PBYTE) pmi + sizeof( MODEINFO);
   pmi->pszModeName = p;
   strcpy( p, pszMode);
   p = NEXTSTR( p);

   if (strlen( szDefExtensions))
      {
      pmi->pszDefExtensions = p;
      strcpy( p, szDefExtensions);
      p = NEXTSTR( p);
      pmi->ulModeFlags |= MODEINFO_EXTENSIONS;
      }

   if (strlen( szDefNames))
      {
      pmi->pszDefNames = p;
      strcpy( p, szDefNames);
      p = NEXTSTR( p);
      pmi->ulModeFlags |= MODEINFO_NAMES;
      }

   ulCaseSensitive = atol( szCaseSensitive);
   if (ulCaseSensitive)
      pmi->ulModeFlags |= MODEINFO_CASESENSITIVE;


   } while (FALSE);

// cleanup
return rc;
}

// -----------------------------------------------------------------------------

#define SCANMODE_MODEINFO 0
#define SCANMODE_MODELIST 1

#define _getModeInfo(fn,bn,ex,b,s)   _scanModes( SCANMODE_MODEINFO, fn, bn, ex, (PSZ)b, s)
#define _getModeList(b,s)            _scanModes( SCANMODE_MODELIST, NULL, NULL, NULL, b, s)

static APIRET _scanModes( ULONG ulReturnType,
                          PSZ pszFilename, PSZ pszBasename, PSZ pszExtension,
                          PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;

         PMODEINFO      pmi;
         BOOL           fTmpDataAllocated = FALSE;

         PSZ            pszMode;
         PSZ            pszModeFile;

         HDIR           hdir = NULLHANDLE;

         PSZ            pszRexxSig = "/*";
         PSZ            pszIniSig = "\xFF\xFF\xFF\xFF\x14\x00";

         PSZ            pszNameMode = NULL;
         PSZ            pszExtMode = NULL;

         PSZ            pszKeywordPath = NULL;
         PSZ            pszKeywordDir;

         CHAR           szSearchMask[ _MAX_PATH];
         CHAR           szDir[ _MAX_PATH];
         CHAR           szIniFile[ _MAX_PATH];
         PSZ            pszDirName;

         CHAR           szModeList[ _MAX_PATH];
         CHAR           szModeTag[ 64];

do
   {

   // init vars
   szModeList[ 0] = 0;

   // check parms
   if (!pszBuffer)
       {
       rc = ERROR_INVALID_PARAMETER;
       break;
       }

   // check which return value is requested
   switch (ulReturnType)
      {
      case SCANMODE_MODEINFO:
         if ((!pszFilename) ||
              ((!pszBasename) && (!pszExtension)))
            {
            rc = ERROR_INVALID_PARAMETER;
            break;
            }
         pmi = (PMODEINFO) pszBuffer;
         break;

      case SCANMODE_MODELIST:
         // allocate temporary PMI buffer
         ulBuflen = 512;
         pmi = malloc( ulBuflen);
         if (!pmi)
            {
            rc = ERROR_NOT_ENOUGH_MEMORY;
            break;
            }
         memset( pmi, 0, ulBuflen);
         fTmpDataAllocated = TRUE;
         break;

      } // switch (ulReturnType)

   // -----------------------------------------------------

   if ((ulReturnType == SCANMODE_MODEINFO) &&
       (pszExtension) && (pszFilename))
      {
      // check for .CMD files
      if (!strcmp( pszExtension, "CMD"))
         {
         if (_checkSpecialFile( pszFilename, pszRexxSig, strlen( pszRexxSig)))
            pszExtMode = strdup( "REXX");
         else if (_checkExtprocScript( pszFilename, szDir, sizeof( szDir)))
            pszExtMode = strdup( szDir);
         }

      // check for .INI files
      if (!strcmp( pszExtension, "INI"))
         {
         // dont act on true OS/2 INI Files!
         //if (_checkSpecialFile( pszFilename, (PBYTE)&ulIniSig, sizeof( ulIniSig)))
         if (_checkSpecialFile( pszFilename, pszIniSig, strlen( pszIniSig)))
            //rc = ERROR_PATH_NOT_FOUND;  // this would cause mode = INI as well
            pszExtMode = strdup( "BIN");
         else
            pszExtMode = strdup( "INI");
         }

      // search default file just to make sure that mode definition exists!
      if (pszExtMode)
         {
         rc = _searchFile( pszEnvnameEpmModepath, szIniFile,
                          sizeof( szIniFile), SEARCHMASK_DEFAULTINI,
                          pszExtMode);
         if (rc != NO_ERROR)
            {
            rc = NO_ERROR;
            free( pszExtMode);
            pszExtMode = NULL;
            }

         }

      } // if (pszExtension)

   // -----------------------------------------------------

   if (!pszExtMode)
      {
      // create a strdup of the path, so that we can tokenize it
      pszKeywordPath = getenv( pszEnvnameEpmModepath);
      if (!pszKeywordPath)
         {
         rc = ERROR_ENVVAR_NOT_FOUND;
         break;
         }

      pszKeywordPath = strdup( pszKeywordPath);
      if (!pszKeywordPath)
         {
         rc = ERROR_NOT_ENOUGH_MEMORY;
         break;
         }

      // go through all keyword directories
      pszKeywordDir = strtok( pszKeywordPath, ";");
      while (pszKeywordDir)
         {
         // search all directories in that directory
         sprintf( szSearchMask, SEARCHMASK_MODEDIR, pszKeywordDir);

         // store a filenames
         hdir = HDIR_CREATE;

         while (rc == NO_ERROR)
            {
            // search it
            rc = GetNextDir( szSearchMask, &hdir,
                              szDir, sizeof( szDir));
            if (rc != NO_ERROR)
               break;

            // did we use that mode already?
            pszDirName = Filespec( szDir, FILESPEC_NAME);
            strupr( pszDirName);
            if (!strwrd( szModeList, pszDirName))
               {
               // new mode found, read settings
               rc = _getModeSettings( pszDirName, pmi, ulBuflen);
               if (rc == NO_ERROR)
                  {
                  // new mode found, first of all add to the list
                  strcat( szModeList, " ");
                  strcat( szModeList, pszDirName);

                  // check extension and name
                  if ((!pszExtMode) &&
                      (pszExtension) &&
                      (*pszExtension) &&
                      (pmi->pszDefExtensions) &&
                      (*pmi->pszDefExtensions) &&
                      ((_globMatch( pmi->pszDefExtensions, pszExtension) ||
                       (strwrd( pmi->pszDefExtensions, pszExtension)))))
                     pszExtMode = strdup( pszDirName);

                  if ((!pszNameMode) &&
                      (pszBasename) &&
                      (*pszBasename) &&
                      (pmi->pszDefNames) &&
                      (*pmi->pszDefNames) &&
                      ((_globMatch( pmi->pszDefNames, pszBasename) ||
                       (strwrd( pmi->pszDefNames, pszBasename)))))
                     pszNameMode = strdup( pszDirName);

                  }
               else
                  rc = NO_ERROR;

               }  // if (!strstr( szModeList, szModeTag))

           // extension mode found? then break here
           if (pszExtMode)
              break;


            } // while (rc == NO_ERROR)

         DosFindClose( hdir);

         // handle special errors
         if (rc = ERROR_NO_MORE_FILES)
            rc = NO_ERROR;

         // next please
         pszKeywordDir = strtok( NULL, ";");
         }

      } // if (!pszExtMode)

   // -----------------------------------------------------

   // if mode list was requested, quit here
   if (ulReturnType == SCANMODE_MODELIST)
      {
      if (strlen( szModeList) + 1 > ulBuflen)
         {
         rc = ERROR_BUFFER_OVERFLOW;
         break;
         }

      // hand over result
      strcpy( pszBuffer, szModeList);
      break;
      }

   // prefer extmode over
   pszMode = NULL;
   if (pszNameMode)
      pszMode = pszNameMode;
   if (pszExtMode)
      pszMode = pszExtMode;

   // break if no mode found
   if (!pszMode)
      {
      rc = ERROR_PATH_NOT_FOUND;
      break;
      }

   // reread mode details
   rc = _getModeSettings( pszMode, pmi, ulBuflen);


   } while (FALSE);

// cleanup
if ((pmi) && (fTmpDataAllocated)) free( pmi);
if (pszKeywordPath) free( pszKeywordPath);
if (pszNameMode)    free( pszNameMode);
if (pszExtMode)     free( pszExtMode);
return rc;
}

// #############################################################################


APIRET QueryFileModeInfo( PSZ pszFilename, PMODEINFO pmi, ULONG ulBuflen)

{
         APIRET         rc = NO_ERROR;
         PSZ            p;

         PSZ            pszBasename = NULL;
         PSZ            pszExtension;
         CHAR           szMode[ 64];

do
   {
   // init return value first
   if (pmi)
      memset( pmi, 0, ulBuflen);

   // check parms
   if ((!pszFilename)   ||
       (!pmi))
      {
      rc = ERROR_INVALID_PARAMETER;
      break;
      }

   // get basename and extension of file
   pszBasename  = Filespec( pszFilename, FILESPEC_NAME);
   if (!pszBasename)
      {
      // don't call free() here
      pszBasename  = NULL;
      rc = ERROR_INVALID_PARAMETER;
      break;
      }
   pszBasename = strdup( pszBasename);
   if (!pszBasename)
      {
      rc = ERROR_NOT_ENOUGH_MEMORY;
      break;
      }
   pszExtension = Filespec( pszBasename, FILESPEC_EXTENSION);
   if (pszExtension)
      // cut off extension from basename
      *(pszExtension - 1) = 0;
   else
      pszExtension = "";

   // upercase names
   strupr( pszBasename);
   strupr( pszExtension);

   // search mode
   rc = _getModeInfo( pszFilename, pszBasename, pszExtension,
                      pmi, ulBuflen);

   } while (FALSE);

// cleanup
if (pszBasename)  free( pszBasename);

return rc;
}

// -----------------------------------------------------------------------------

APIRET QueryFileModeList( PSZ pszBuffer, ULONG ulBuflen)
{
         APIRET         rc = NO_ERROR;
         PSZ            p;

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

   // get mode list
   rc = _getModeList( pszBuffer, ulBuflen);

   } while (FALSE);


return rc;
}

