/****************************** Module Header *******************************
*
* Module Name: nepmdlib.e
*
* .e wrapper routines to access the NEPMD library DLL.
* Coutnerpart to this .e/.ex file is nepmdlib.dll
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.e,v 1.3 2002-08-20 12:34:04 cla Exp $
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

 INI_APPNAME             = 'NEPMD';
 INI_KEY_PATH            = 'Path';

 NEPMD_LIBRARY_BASENAME  = 'nepmdlib';
 NEPMD_SUBPATH_BINDLLDIR = 'netlabs\dll';
 ERRMSG_CANNOT_LOAD      = 'error: cannot load NEPMD library file!';

 EPMINFO_EDITCLIENT      = 5; /* avoid include of stdconst.e */


 NEPMD_TEST_EANAME       = 'NEPMD._TestStringEa';
 NEPMD_TEST_EAVALUE      = 'This is a test value for the NepmdWriteStringEa API !';


/* ------------------------------------------------------------- */
/*   generic routine for library file handling                   */
/* ------------------------------------------------------------- */

defproc getlibfile =

universal app_hini;

 /* use default */
 LibFile =  NEPMD_LIBRARY_BASENAME;

 /* check if DLL is available in NEPMD subdirectory */
 InstallPath = queryprofile( , INI_APPNAME, INI_KEY_PATH);
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
    sayerror ERRMSG_CANNOT_LOAD;
 endif

 /* allow easy debugging - release DLL instantly */
 if (DEBUG) then
    /* use different rc  - don't overwrite rc from dynalink32 call */
    rcx = dynafree( LibFile);
 endif

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
include 'libinfo.e'
include 'queryfullname.e'
include 'writestringea.e'

