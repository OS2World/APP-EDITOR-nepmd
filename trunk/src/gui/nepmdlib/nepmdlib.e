/****************************** Module Header *******************************
*
* Module Name: nepmdlib.e
*
* .e wrapper routines to access the NEPMD library DLL.
* Coutnerpart to this .e/.ex file is nepmdlib.dll
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.e,v 1.31 2002-09-15 14:58:35 cla Exp $
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

/* ------------------------------------------------------------- */
/*   avoid include of stdconst.e                                 */
/* ------------------------------------------------------------- */

const
 DEBUG                   = 1;
 NEPMD_MAXLEN_ESTRING    = 1600;

 NEPMD_INI_APPNAME       = 'NEPMD';
 NEPMD_INI_KEY_PATH      = 'Path';

 NEPMD_LIBRARY_BASENAME  = 'nepmdlib';
 NEPMD_SUBPATH_BINDLLDIR = 'netlabs\dll';

 ERRMSG_ERROR_TITLE      = 'Netlabs EPM Distribution';
 ERRMSG_CANNOT_LOAD      = 'error: cannot load NEPMD library file NEPMDLIB.DLL !';
 ERRMSG_BOXSTYLE         = 16454; -- CANCEL + ICONHAND + MOVEABLE

 EPMINFO_EDITCLIENT      = 5; /* avoid include of stdconst.e */
 EPMINFO_EDITFRAME       = 6;

 NEPMD_TEST_EANAME       = 'NEPMD._TestStringEa';
 NEPMD_TEST_EAVALUE      = 'This is a test value for the NepmdWriteStringEa API !';

 NEPMD_TEST_CONFIGPATH   = '\NEPMD\Test\Nepmdlib\TestKey';
 NEPMD_TEST_CONFIGVALUE  = 'This is a test value for the Nepmd*Config* APIs !';

/* ------------------------------------------------------------- */
/*   generic routine for library file and string handling        */
/* ------------------------------------------------------------- */

defproc helperNepmdGetlibfile =

universal app_hini;

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
 if (DEBUG) then
    /* use different rc  - don't overwrite rc from dynalink32 call */
    rcx = dynafree( LibFile);
 endif

 return;

/* --------------------------------- */

defproc helperNepmdCreateDumpfile (FunctionName, Parms) =

 TestcaseTitle = FunctionName':' Parms;
 Separator     = copies( '-', length( TestcaseTitle));  

 'xcom e /c .TEST_'translate( FunctionName);
 .autosave = 0;
 insertline '';
 insertline TestcaseTitle;
 insertline Separator;
 insertline '';

 return;

/* --------------------------------- */

defproc makerexxstring( asciizstring)
  return substr( asciizstring, 1, pos( atoi(0), asciizstring) - 1);

/* ------------------------------------------------------------- */
/*   allow to auto-process command on load of routine            */
/* ------------------------------------------------------------- */

defmain 'NepmdVersion';

/* ------------------------------------------------------------- */
/*   include functions                                           */
/* ------------------------------------------------------------- */

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
include 'getnextdir.e'
include 'getnextfile.e'
include 'gettextmessage.e'
include 'info.e'
include 'libversion.e'
include 'openconfig.e'
include 'queryconfigvalue.e'
include 'queryfullname.e'
include 'queryinstvalue.e'
include 'querypathinfo.e'
include 'queryprocessinfo.e'
include 'querysysinfo.e'
include 'querywindowpos.e'
include 'readstringea.e'
include 'scanenv.e'
include 'searchpath.e'
include 'setframewindowpos.e'
include 'writeconfigvalue.e'
include 'writestringea.e'
