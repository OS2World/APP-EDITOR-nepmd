/*
- Cosmetic changes.
*/
/****************************** Module Header *******************************
*
* Module Name: nepmdlib.e
*
* .e wrapper routines to access the NEPMD library DLL.
* Counterpart to this .e/.ex file is nepmdlib.dll
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.e,v 1.40 2005-07-17 15:41:52 aschn Exp $
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

; This file may be included in epm.e (e.g. for testing) as well. But it's
; intended to be compiled separately and linked later on to save space
; in epm.ex.

/* ------------------------------------------------------------- */
/*   avoid include of stdconst.e if compiled separately          */
/* ------------------------------------------------------------- */
compile if not defined(SMALL)  -- SMALL is undefined if an .e file is compiled separately without EPM.E
const                          -- (added because many users omit from MYCNF.)
tryinclude     'mycnf.e'       -- User configuration goes here.

 compile if not defined(SITE_CONFIG)  -- Did user's MYCNF.E set a SITE_CONFIG file?
   const SITE_CONFIG = 'sitecnf.e'    -- If not, use the default
 compile endif
 compile if SITE_CONFIG               -- If SITE_CONFIG file was not set to null,
   tryinclude  SITE_CONFIG            -- include the site configuration file.
 compile endif
compile endif

const
-------- Start of configuration constants for MYCNF.E --------
compile if not defined(NEPMD_LIB_TEST)
   NEPMD_LIB_TEST = 1   -- Include test and demo commands?
compile endif
compile if not defined(NEPMD_LIB_DEBUG)
   NEPMD_LIB_DEBUG = 0  -- Activate debug for this package?
compile endif
-------- End of configuration constants for MYCNF.E ----------

   NEPMD_MAXLEN_ESTRING    = 1600;

   NEPMD_INI_APPNAME       = 'NEPMD';
   NEPMD_INI_KEY_PATH      = 'Path';

   NEPMD_LIBRARY_BASENAME  = 'nepmdlib';
   NEPMD_SUBPATH_BINDLLDIR = 'netlabs\dll';

   ERRMSG_ERROR_TITLE      = 'Netlabs EPM Distribution';
   ERRMSG_CANNOT_LOAD      = 'Error: cannot load NEPMD library file NEPMDLIB.DLL!';
   ERRMSG_BOXSTYLE         = 16454; -- CANCEL + ICONHAND + MOVEABLE

compile if not defined(EPMINFO_EDITCLIENT)
   EPMINFO_EDITCLIENT      = 5; /* avoid include of stdconst.e */
compile endif
compile if not defined(EPMINFO_EDITFRAME)
   EPMINFO_EDITFRAME       = 6;
compile endif

compile if NEPMD_LIB_TEST
   NEPMD_TEST_EANAME       = 'NEPMD._TestStringEa';
   NEPMD_TEST_EAVALUE      = 'This is a test value for the NepmdWriteStringEa API!';

   NEPMD_TEST_CONFIGPATH   = '\NEPMD\Test\Nepmdlib\TestKey';
   NEPMD_TEST_CONFIGVALUE  = 'This is a test value for the Nepmd*Config* APIs!';
compile endif

/* ------------------------------------------------------------- */
/*   generic routine for library file and string handling        */
/* ------------------------------------------------------------- */

defproc helperNepmdGetlibfile =

   /* use default */
   LibFile =  NEPMD_LIBRARY_BASENAME;

   /* check if DLL is available in NEPMD subdirectory */
   InstallPath = queryprofile( , NEPMD_INI_APPNAME, NEPMD_INI_KEY_PATH);
   if (InstallPath <> '') then
      CheckFile = InstallPath'\'NEPMD_SUBPATH_BINDLLDIR'\'NEPMD_LIBRARY_BASENAME'.dll';
      if exist( CheckFile) then
         LibFile = CheckFile;
      endif
   endif

   return LibFile;

/* --------------------------------- */

defproc helperNepmdCheckliberror (LibFile, rc) =

   /* complain if library not available */
   if (rc > 2147483647) then
      /* call  winmessagebox( ERRMSG_ERROR_TITLE, ERRMSG_CANNOT_LOAD, ERRMSG_BOXSTYLE); */
      sayerror ERRMSG_CANNOT_LOAD;
      stop;
   endif

   /* allow easy debugging - release DLL instantly */
   if (NEPMD_LIB_DEBUG) then
      /* use different rc  - don't overwrite rc from dynalink32 call */
      rcx = dynafree( LibFile);
   endif

   return;

/* --------------------------------- */
compile if NEPMD_LIB_TEST

defproc helperNepmdCreateDumpfile (FunctionName, Parms) =

   TestcaseTitle = strip( FunctionName Parms);
   Separator     = copies( '-', length(TestcaseTitle));

   'xcom e /c .TEST_'translate( FunctionName);
   .autosave = 0;
   insertline '';
   insertline TestcaseTitle;
   insertline Separator;
   insertline '';

   return;

compile endif
/* --------------------------------- */

defproc makerexxstring( asciizstring)
   return substr( asciizstring, 1, pos( atoi(0), asciizstring) - 1);

/* ------------------------------------------------------------- */
/*   include functions                                           */
/* ------------------------------------------------------------- */

include 'activatehighlight.e'
include 'alarm.e'
include 'closeconfig.e'
include 'deleteconfigvalue.e'
include 'deleterexxea.e'
include 'deletestringea.e'
include 'direxists.e'
include 'errormsgbox.e'
include 'filedelete.e'
include 'fileexists.e'
include 'getnextclose.e'
include 'getnextconfigkey.e'
include 'getnextdir.e'
include 'getnextfile.e'
include 'gettextmessage.e'
include 'info.e'
include 'initconfig.e'
include 'libversion.e'
include 'openconfig.e'
include 'pmprintf.e'
include 'queryconfigvalue.e'
include 'querydefaultmode.e'
include 'queryfullname.e'
include 'queryinstvalue.e'
include 'querymodelist.e'
include 'querypathinfo.e'
include 'queryprocessinfo.e'
include 'querystringea.e'
include 'querysysinfo.e'
include 'querywindowpos.e'
include 'scanenv.e'
include 'searchpath.e'
include 'setframewindowpos.e'
include 'writeconfigvalue.e'
include 'writestringea.e'

