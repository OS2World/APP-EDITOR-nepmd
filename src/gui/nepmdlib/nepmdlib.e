/****************************** Module Header *******************************
*
* Module Name: nepmdlib.e
*
* .e wrapper routines to access the NEPMD library DLL.
* Coutnerpart to this .e/.ex file is nepmdlib.dll
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.e,v 1.13 2002-08-25 14:35:14 cla Exp $
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


 NEPMD_TEST_EANAME       = 'NEPMD._TestStringEa';
 NEPMD_TEST_EAVALUE      = 'This is a test value for the NepmdWriteStringEa API !';


/* ------------------------------------------------------------- */
/*   generic routine for library file and string handling        */
/* ------------------------------------------------------------- */

defproc getlibfile =

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


defproc checkliberror (LibFile, rc) =

 /* complain if library not available */
 if (rc > 2147483647) then
    call winmessagebox( ERRMSG_ERROR_TITLE, ERRMSG_CANNOT_LOAD, ERRMSG_BOXSTYLE);
    return -1;
 endif

 /* allow easy debugging - release DLL instantly */
 if (DEBUG) then
    /* use different rc  - don't overwrite rc from dynalink32 call */
    rcx = dynafree( LibFile);
 endif


defproc makerexxstring( asciizstring)
  return substr( asciizstring, 1, pos( atoi(0), asciizstring) - 1);

/* ------------------------------------------------------------- */
/*   allow to auto-process command on load of routine            */
/* ------------------------------------------------------------- */

defmain 'NepmdVersion';

/* ------------------------------------------------------------- */
/*   include functions                                           */
/* ------------------------------------------------------------- */

include 'deleterexxea.e'
include 'deletestringea.e'
include 'errormsgbox.e'
include 'getinstvalue.e'
include 'getnextdir.e'
include 'getnextfile.e'
include 'gettextmessage.e'
include 'info.e'
include 'libversion.e'
include 'queryfullname.e'
include 'readstringea.e'
include 'writestringea.e'

