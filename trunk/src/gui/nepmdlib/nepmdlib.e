/****************************** Module Header *******************************
*
* Module Name: nepmdlib.e
*
* .e wrapper routines to access the NEPMD library DLL.
* Coutnerpart to this .e/.ex file is nepmdlib.dll
*
* Copyright (c) Netlabs EPM Distribution Project 2002
*
* $Id: nepmdlib.e,v 1.1 2002-08-19 18:18:03 cla Exp $
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
 DEBUG                  = 1;

 INI_APPNAME            = 'NEPMD';
 INI_KEY_PATH           = 'Path';

 NEPMD_LIBRARY_BASENAME  = 'nepmdlib';
 NEPMD_SUBPATH_BINDLLDIR = 'netlabs\dll';
 ERRMSG_CANNOT_LOAD      = 'error: cannot load NEPMD library file!';

 EPMINFO_EDITCLIENT      = 5; /* avoid include of stdconst.e */

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
/*   allow editor command to call functions                      */
/* ------------------------------------------------------------- */

defc NepmdVersion =

  sayerror 'NEPMDLIB Version' NepmdLibInfo( 'VERSION');

defc NepmdErrorMsgBox, ErrorMsgBox =

  rcx = NepmdErrorMsgBox( arg( 1), 'Netlabs EPM Distribution');

defc NepmdQueryFullname, QueryFullname =

  sayerror 'fullname of "'arg( 1)'" is:' NepmdQueryFullname( arg( 1));


/* ============================================================= */
/*   procedures to call DLL routine                              */
/* ============================================================= */

/* ------------------------------------------------------------- */
/* procedure: NepmdLibInfo                                       */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    data = NepmdLibInfo( '<token>');                           */
/*                                                               */
/*  Valid tokens are:                                            */
/*     'VERSION'  - returns version number ('1.23')              */
/*     'COMPILED' - returns compiledate ('dd mmm yyyy')          */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdLibInfo( PSZ pszFilename,               */
/*                                PSZ pszBuffer,                 */
/*                                PSZ pszBuflen)                 */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdLibInfo( Token) =

 BufLen   = 260;
 LibInfo  = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Token    = Token''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdLibInfo",
                  address( Token)   ||
                  address( LibInfo) ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return LibInfo;


/* ------------------------------------------------------------- */
/* procedure: NepmdQueryFullname                                 */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    Fullname = QueryFullname( filename);                       */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdQueryFullname( PSZ pszFilename,         */
/*                                      PSZ pszBuffer,           */
/*                                      PSZ pszBuflen)           */
/*                                                               */
/* ------------------------------------------------------------- */

defproc NepmdQueryFullname( Filename) =

 BufLen   = 260;
 FullName = copies( atoi( 0), BufLen);

 /* prepare parameters for C routine */
 Filename   = Filename''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdQueryFullname",
                  address( Filename)            ||
                  address( Fullname)            ||
                  atol( Buflen));

 checkliberror( LibFile, rc);

 return FullName;

/* ------------------------------------------------------------- */
/* procedure: NepmdErrorMsgBox                                   */
/* ------------------------------------------------------------- */
/* .e Syntax:                                                    */
/*    rc = ErrorMsgBox( message, title);                         */
/* ------------------------------------------------------------- */
/* C prototype:                                                  */
/*  APIRET EXPENTRY NepmdErrorMsgBox( HWND hwndClient,           */
/*                                    PSZ pszMessage,            */
/*                                    PSZ pszTitle)              */
/* ------------------------------------------------------------- */

defproc NepmdErrorMsgBox( BoxMessage, Boxtitle) =

 /* prepare parameters for C routine */
 BoxMessage = BoxMessage''atoi( 0);
 BoxTitle   = Boxtitle''atoi( 0);

 /* call C routine */
 LibFile = getlibfile();
 rc = dynalink32( LibFile,
                  "NepmdErrorMsgBox",
                  gethwndc( EPMINFO_EDITCLIENT) ||
                  address( BoxMessage)          ||
                  address( BoxTitle));

 checkliberror( LibFile, rc);

 return rc;

